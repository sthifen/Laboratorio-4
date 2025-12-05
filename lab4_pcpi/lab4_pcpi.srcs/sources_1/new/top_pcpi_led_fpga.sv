`timescale 1ns/1ps

module top_pcpi_led_fpga (
    input  logic        clk_100MHz,
    input  logic        btnC,
    input  logic        btnL,
    input  logic        btnR,
    input  logic        btnU,
    input  logic        btnD,
    input  logic [15:0] sw,
    inout  wire         SCL,
    inout  wire         SDA,
    input  logic        TMP_INT,
    input  logic        TMP_CT,
    output logic [15:0] led,
    output logic [7:0]  AN,
    output logic [7:0]  SEG
);

    //--------------------------------------------------------------------------
    // Clock generation (100 MHz -> 10 MHz) using clk_i IP
    //--------------------------------------------------------------------------
    logic clk_sys;
    logic clk_locked;

    clk_i clk_wiz_inst (
        .clk_in1(clk_100MHz),
        .reset(btnC),
        .locked(clk_locked),
        .clk_i(clk_sys)
    );

    //--------------------------------------------------------------------------
    // System reset (synchronous)
    //--------------------------------------------------------------------------
    logic resetn;

    always_ff @(posedge clk_sys or negedge clk_locked) begin
        if (!clk_locked) begin
            resetn <= 1'b0;
        end else begin
            resetn <= ~btnC;
        end
    end

    //--------------------------------------------------------------------------
    // Debounced inputs (switches + 4 buttons)
    //--------------------------------------------------------------------------
    logic [15:0] sw_debounced;
    logic [3:0]  btn_debounced;

    io_sync_debounce #(
        .WIDTH(16),
        .CTR_WIDTH(18)
    ) sw_deb_inst (
        .clk   (clk_sys),
        .resetn(resetn),
        .din   (sw),
        .dout  (sw_debounced)
    );

    io_sync_debounce #(
        .WIDTH(4),
        .CTR_WIDTH(20)
    ) btn_deb_inst (
        .clk   (clk_sys),
        .resetn(resetn),
        .din   ({btnU, btnD, btnL, btnR}),
        .dout  (btn_debounced)
    );

    logic [31:0] switches_reg;
    assign switches_reg = {10'd0, TMP_CT, TMP_INT, btn_debounced, sw_debounced};

    //--------------------------------------------------------------------------
    // CPU core signals
    //--------------------------------------------------------------------------
    logic [31:0] instr_addr;
    logic [31:0] instr_data;
    logic        data_req;
    logic        data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_ready;

    rv32i_core core_inst (
        .clk          (clk_sys),
        .resetn       (resetn),
        .instr_addr_o (instr_addr),
        .instr_rdata_i(instr_data),
        .data_req_o   (data_req),
        .data_we_o    (data_we),
        .data_be_o    (data_be),
        .data_addr_o  (data_addr),
        .data_wdata_o (data_wdata),
        .data_rdata_i (data_rdata),
        .data_ready_i (data_ready)
    );

    //--------------------------------------------------------------------------
    // Instruction memory (ROM IP)
    //--------------------------------------------------------------------------
    logic [8:0] rom_addr_word;

    assign rom_addr_word = instr_addr[10:2];

    ROM rom_inst (
        .clka (clk_sys),
        .ena  (1'b1),
        .addra(rom_addr_word),
        .douta(instr_data)
    );

    //--------------------------------------------------------------------------
    // Data memory (RAM IP) wiring
    //--------------------------------------------------------------------------
    logic        ram_ena;
    logic [0:0]  ram_wea;
    logic [9:0]  ram_addra;
    logic [31:0] ram_dina;
    logic        ram_enb;
    logic [9:0]  ram_addrb;
    logic [31:0] ram_doutb;

    RAM ram_inst (
        .clka (clk_sys),
        .ena  (ram_ena),
        .wea  (ram_wea),
        .addra(ram_addra),
        .dina (ram_dina),
        .clkb (clk_sys),
        .enb  (ram_enb),
        .addrb(ram_addrb),
        .doutb(ram_doutb)
    );

    //--------------------------------------------------------------------------
    // Peripherals (LEDs, seven segments, timer, temperature)
    //--------------------------------------------------------------------------
    logic [15:0] led_reg;
    logic [31:0] sevenseg_reg;

    logic        timer_ctrl_we;
    logic [31:0] timer_ctrl_wdata;
    logic        timer_data_we;
    logic [31:0] timer_data_wdata;
    logic [31:0] timer_ctrl_rdata;
    logic [31:0] timer_data_rdata;

    timer_peripheral timer_inst (
        .clk        (clk_sys),
        .resetn     (resetn),
        .ctrl_we    (timer_ctrl_we),
        .ctrl_wdata (timer_ctrl_wdata),
        .data_we    (timer_data_we),
        .data_wdata (timer_data_wdata),
        .ctrl_rdata (timer_ctrl_rdata),
        .data_rdata (timer_data_rdata)
    );

    logic        temp_ctrl_we;
    logic [31:0] temp_ctrl_wdata;
    logic [31:0] temp_ctrl_rdata;
    logic [31:0] temp_data_rdata;

`ifdef SYNTHESIS
    localparam bit TEMP_SIMULATION = 1'b0;
`else
    localparam bit TEMP_SIMULATION = 1'b1;
`endif

    temp_sensor_xadc #(
        .SIMULATION(TEMP_SIMULATION)
    ) temp_inst (
        .clk        (clk_sys),
        .resetn     (resetn),
        .ctrl_we    (temp_ctrl_we),
        .ctrl_wdata (temp_ctrl_wdata),
        .ctrl_rdata (temp_ctrl_rdata),
        .data_rdata (temp_data_rdata),
        .SCL        (SCL),
        .SDA        (SDA)
    );

    seven_seg_driver seg_driver (
        .clk     (clk_sys),
        .resetn  (resetn),
        .data_reg(sevenseg_reg),
        .an_o    (AN),
        .seg_o   (SEG)
    );

    assign led = led_reg;

    //--------------------------------------------------------------------------
    // Memory map interconnect (data bus)
    //--------------------------------------------------------------------------
    typedef enum logic [1:0] {
        BUS_IDLE,
        BUS_WAIT_RAM_READ,
        BUS_RESPOND
    } bus_state_t;

    bus_state_t bus_state;
    logic [31:0] response_data;
    logic [31:0] data_rdata_reg;
    logic        data_ready_reg;

    assign data_rdata = data_rdata_reg;
    assign data_ready = data_ready_reg;

    localparam logic [31:0] RAM_BASE         = 32'h0000_1000;
    localparam logic [31:0] RAM_LIMIT        = 32'h0000_2000; // 4 KiB window
    localparam logic [31:0] SWITCHES_ADDR    = 32'h0000_2000;
    localparam logic [31:0] LED_ADDR         = 32'h0000_2004;
    localparam logic [31:0] SEVENSEG_ADDR    = 32'h0000_2008;
    localparam logic [31:0] TIMER_CTRL_ADDR  = 32'h0000_2018;
    localparam logic [31:0] TIMER_DATA_ADDR  = 32'h0000_201C;
    localparam logic [31:0] TEMP_CTRL_ADDR   = 32'h0000_2030;
    localparam logic [31:0] TEMP_DATA_ADDR   = 32'h0000_2034;

    always_ff @(posedge clk_sys) begin
        if (!resetn) begin
            bus_state        <= BUS_IDLE;
            data_ready_reg   <= 1'b0;
            data_rdata_reg   <= 32'h0;
            response_data    <= 32'h0;
            ram_ena          <= 1'b0;
            ram_enb          <= 1'b0;
            ram_wea          <= 1'b0;
            ram_addra        <= 10'd0;
            ram_addrb        <= 10'd0;
            ram_dina         <= 32'h0;
            led_reg          <= 16'd0;
            sevenseg_reg     <= 32'd0;
            timer_ctrl_we    <= 1'b0;
            timer_ctrl_wdata <= 32'd0;
            timer_data_we    <= 1'b0;
            timer_data_wdata <= 32'd0;
            temp_ctrl_we     <= 1'b0;
            temp_ctrl_wdata  <= 32'd0;
        end else begin
            data_ready_reg <= 1'b0;
            ram_ena        <= 1'b0;
            ram_enb        <= 1'b0;
            ram_wea        <= 1'b0;
            timer_ctrl_we  <= 1'b0;
            timer_data_we  <= 1'b0;
            temp_ctrl_we   <= 1'b0;

            case (bus_state)
                BUS_IDLE: begin
                    if (data_req) begin
                        logic [31:0] addr;
                        addr = data_addr;
                        if ((addr >= RAM_BASE) && (addr < RAM_LIMIT)) begin
                            logic [9:0] word_addr;
                            word_addr = (addr - RAM_BASE) >> 2;
                            if (data_we && (data_be == 4'b1111)) begin
                                ram_ena   <= 1'b1;
                                ram_wea   <= 1'b1;
                                ram_addra <= word_addr;
                                ram_dina  <= data_wdata;
                                response_data <= 32'h0000_0000;
                                bus_state <= BUS_RESPOND;
                            end else begin
                                ram_enb   <= 1'b1;
                                ram_addrb <= word_addr;
                                bus_state <= BUS_WAIT_RAM_READ;
                            end
                        end else begin
                            response_data <= 32'h0000_0000;
                            unique case (addr)
                                SWITCHES_ADDR: response_data <= switches_reg;
                                LED_ADDR:      response_data <= {16'd0, led_reg};
                                SEVENSEG_ADDR: response_data <= sevenseg_reg;
                                TIMER_CTRL_ADDR: response_data <= timer_ctrl_rdata;
                                TIMER_DATA_ADDR: response_data <= timer_data_rdata;
                                TEMP_CTRL_ADDR:  response_data <= temp_ctrl_rdata;
                                TEMP_DATA_ADDR:  response_data <= temp_data_rdata;
                                default: response_data <= 32'hDEAD_BEEF;
                            endcase

                            if (data_we) begin
                                unique case (addr)
                                    LED_ADDR:      led_reg      <= data_wdata[15:0];
                                    SEVENSEG_ADDR: sevenseg_reg <= data_wdata;
                                    TIMER_CTRL_ADDR: begin
                                        timer_ctrl_we    <= 1'b1;
                                        timer_ctrl_wdata <= data_wdata;
                                    end
                                    TIMER_DATA_ADDR: begin
                                        timer_data_we    <= 1'b1;
                                        timer_data_wdata <= data_wdata;
                                    end
                                    TEMP_CTRL_ADDR: begin
                                        temp_ctrl_we    <= 1'b1;
                                        temp_ctrl_wdata <= data_wdata;
                                    end
                                    default: ;
                                endcase
                                response_data <= 32'h0000_0000;
                            end

                            bus_state <= BUS_RESPOND;
                        end
                    end
                end

                BUS_WAIT_RAM_READ: begin
                    response_data <= ram_doutb;
                    bus_state     <= BUS_RESPOND;
                end

                BUS_RESPOND: begin
                    data_ready_reg <= 1'b1;
                    data_rdata_reg <= response_data;
                    bus_state      <= BUS_IDLE;
                end

                default: bus_state <= BUS_IDLE;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // I2C pins connected to temp_sensor_xadc module for ADT7420 communication
    // TMP_INT and TMP_CT available for future use; currently sampled into switches_reg.
    //--------------------------------------------------------------------------

endmodule
