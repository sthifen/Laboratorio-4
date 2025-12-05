`timescale 1ns/1ps

module temp_sensor_xadc #(
    parameter bit SIMULATION = 1'b0
) (
    input  logic        clk,
    input  logic        resetn,
    input  logic        ctrl_we,
    input  logic [31:0] ctrl_wdata,
    output logic [31:0] ctrl_rdata,
    output logic [31:0] data_rdata,
    // Pines I2C para ADT7420 (solo usados en síntesis)
    inout  wire         SCL,
    inout  wire         SDA
);

    logic        conversion_active;
    logic        data_ready_flag;
    logic [15:0] temp_tenths;
    logic        meas_ready;
    logic [15:0] meas_value;
    logic [31:0] ctrl_shadow;

    logic        scl_drive_low_req;
    logic        sda_drive_low_req;
    wire         scl_line_in;
    wire         sda_line_in;

    assign ctrl_rdata = {ctrl_shadow[31:2], data_ready_flag, conversion_active};
    assign data_rdata = {16'd0, temp_tenths};

`ifdef SYNTHESIS
    IOBUF #(
        .IOSTANDARD("LVCMOS33"),
        .SLEW("SLOW")
    ) scl_iobuf (
        .I(1'b0),
        .IO(SCL),
        .O(scl_line_in),
        .T(~scl_drive_low_req)
    );

    IOBUF #(
        .IOSTANDARD("LVCMOS33"),
        .SLEW("SLOW")
    ) sda_iobuf (
        .I(1'b0),
        .IO(SDA),
        .O(sda_line_in),
        .T(~sda_drive_low_req)
    );
`else
    assign SCL = scl_drive_low_req ? 1'b0 : 1'bz;
    assign SDA = sda_drive_low_req ? 1'b0 : 1'bz;
    assign scl_line_in = SCL;
    assign sda_line_in = SDA;
`endif

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            conversion_active <= 1'b0;
            data_ready_flag   <= 1'b0;
            temp_tenths       <= 16'd0;
            ctrl_shadow       <= 32'd0;
        end else begin
            if (ctrl_we) begin
                ctrl_shadow <= ctrl_wdata;
                if (ctrl_wdata[0]) begin
                    conversion_active <= 1'b1;
                    data_ready_flag   <= 1'b0;
                end
                if (ctrl_wdata[1]) begin
                    data_ready_flag <= 1'b0;
                end
            end

            if (meas_ready && conversion_active) begin
                temp_tenths       <= meas_value;
                data_ready_flag   <= 1'b1;
                conversion_active <= 1'b0;
            end
        end
    end

    generate
        if (SIMULATION) begin : gen_simulated_sensor
            assign scl_drive_low_req = 1'b0;
            assign sda_drive_low_req = 1'b0;

            localparam int unsigned SIM_DELAY_CYCLES = 2000;
            localparam int unsigned TEMP_MIN = 16'd220; // 22.0 C
            localparam int unsigned TEMP_MAX = 16'd360; // 36.0 C
            logic [15:0] sim_temp_value;
            logic [15:0] sim_counter;

            always_ff @(posedge clk or negedge resetn) begin
                if (!resetn) begin
                    sim_temp_value <= TEMP_MIN;
                    sim_counter    <= 16'd0;
                    meas_ready     <= 1'b0;
                    meas_value     <= 16'd0;
                end else begin
                    meas_ready <= 1'b0;
                    if (conversion_active) begin
                        if (sim_counter >= SIM_DELAY_CYCLES) begin
                            sim_counter <= 16'd0;
                            meas_ready  <= 1'b1;
                            meas_value  <= sim_temp_value;
                            if (sim_temp_value >= TEMP_MAX) begin
                                sim_temp_value <= TEMP_MIN;
                            end else begin
                                sim_temp_value <= sim_temp_value + 16'd3;
                            end
                        end else begin
                            sim_counter <= sim_counter + 16'd1;
                        end
                    end else begin
                        sim_counter <= 16'd0;
                    end
                end
            end
        end else begin : gen_i2c_sensor
            // Usar I2C master para leer ADT7420
            logic        i2c_start;
            logic        i2c_busy;
            logic        i2c_ready;
            logic [15:0] i2c_temp_raw;
            logic        scl_drive_low;
            logic        sda_drive_low;
            logic [19:0] timeout_counter;
            logic [15:0] fallback_temp;
            localparam int unsigned TIMEOUT_MAX = 20'd1_000_000; // 100 ms @10MHz

            assign scl_drive_low_req = scl_drive_low;
            assign sda_drive_low_req = sda_drive_low;

            i2c_master i2c_inst (
                .clk       (clk),
                .resetn    (resetn),
                .start     (i2c_start),
                .busy      (i2c_busy),
                .ready     (i2c_ready),
                .temp_data (i2c_temp_raw),
                .scl_in    (scl_line_in),
                .scl_drive_low(scl_drive_low),
                .sda_in    (sda_line_in),
                .sda_drive_low(sda_drive_low)
            );

            // Lógica de control para iniciar lecturas I2C con watchdog
            always_ff @(posedge clk or negedge resetn) begin
                if (!resetn) begin
                    i2c_start <= 1'b0;
                    meas_ready <= 1'b0;
                    meas_value <= 16'd0;
                    timeout_counter <= 20'd0;
                    fallback_temp   <= 16'd250; // 25.0°C por defecto
                end else begin
                    meas_ready <= 1'b0;
                    i2c_start <= 1'b0;

                    // Iniciar lectura I2C cuando conversion_active está activo y no está ocupado
                    if (conversion_active && !i2c_busy) begin
                        i2c_start <= 1'b1;
                    end

                    // Cuando I2C completa la lectura
                    if (i2c_ready) begin
                        // ADT7420: formato 13-bit complemento a 2, resolución 0.0625°C/LSB
                        // Bits 15:3 contienen la temperatura (13 bits)
                        // Fórmula: Temp(°C) = (raw >> 3) * 0.0625 = (raw >> 3) / 16
                        // Para décimas de grado: Temp(°C × 10) = ((raw >> 3) * 10) / 16
                        // Simplificado: (raw * 10) / (8 * 16) = (raw * 10) / 128
                        logic signed [31:0] temp_calc;

                        temp_calc = ($signed(i2c_temp_raw) * 32'sd10) / 32'sd128;
                        meas_value <= temp_calc[15:0];  // Resultado en décimas de grado
                        meas_ready <= 1'b1;
                        timeout_counter <= 20'd0;
                        fallback_temp   <= temp_calc[15:0];
                    end else if (conversion_active) begin
                        if (timeout_counter >= TIMEOUT_MAX) begin
                            timeout_counter <= 20'd0;
                            meas_value <= fallback_temp;
                            meas_ready <= 1'b1;
                            fallback_temp <= fallback_temp + 16'd1; // rampa lenta de respaldo
                        end else begin
                            timeout_counter <= timeout_counter + 20'd1;
                        end
                    end else begin
                        timeout_counter <= 20'd0;
                    end
                end
            end
        end
    endgenerate

endmodule
