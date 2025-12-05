`timescale 1ns/1ps
//==============================================================================
// I2C Master - Para comunicación con ADT7420
// Genera señales SCL/SDA para leer temperatura del sensor I2C
//==============================================================================

module i2c_master (
    input  logic        clk,           // 10 MHz
    input  logic        resetn,
    input  logic        start,         // Iniciar transacción
    output logic        busy,          // Transacción en proceso
    output logic        ready,         // Dato listo
    output logic [15:0] temp_data,     // Dato de temperatura (16 bits)
    input  logic        scl_in,
    output logic        scl_drive_low,
    input  logic        sda_in,
    output logic        sda_drive_low
);

    // Dirección I2C del ADT7420 en Nexys4
    localparam logic [6:0] ADT7420_ADDR = 7'h4B;  // 0x4B según datasheet Nexys4
    localparam logic [7:0] TEMP_REG_MSB = 8'h00;  // Registro MSB de temperatura

    // Generación de SCL: 100 kHz desde 10 MHz
    // Divisor = 10MHz / (100kHz * 4) = 25
    localparam int SCL_DIV = 25;

    typedef enum logic [3:0] {
        IDLE,
        START_BIT,
        SEND_ADDR_W,
        ACK_ADDR_W,
        SEND_REG,
        ACK_REG,
        RESTART,
        SEND_ADDR_R,
        ACK_ADDR_R,
        READ_BYTE_H,
        ACK_BYTE_H,
        READ_BYTE_L,
        NACK_BYTE_L,
        STOP_BIT,
        DONE
    } state_t;

    state_t state;
    logic [7:0] bit_count;
    logic [7:0] scl_count;
    logic [7:0] shift_reg;
    logic [15:0] data_buffer;

    logic scl_en;
    logic sda_en;

    assign scl_drive_low = scl_en;
    assign sda_drive_low = sda_en;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state      <= IDLE;
            busy       <= 1'b0;
            ready      <= 1'b0;
            temp_data  <= 16'h0;
            scl_en     <= 1'b0;
            sda_en     <= 1'b0;
            bit_count  <= 8'd0;
            scl_count  <= 8'd0;
            shift_reg  <= 8'h0;
            data_buffer <= 16'h0;
        end else begin
            ready <= 1'b0;  // Pulso de 1 ciclo

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    scl_en <= 1'b0;
                    sda_en <= 1'b0;
                    if (start && scl_in) begin
                        busy <= 1'b1;
                        state <= START_BIT;
                        scl_count <= 8'd0;
                    end
                end

                START_BIT: begin
                    // Condición START: SDA cae mientras SCL está alto
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b0;  // SDA alto
                    end else if (scl_count < SCL_DIV * 2) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b1;  // SDA bajo (START)
                    end else begin
                        scl_count <= 8'd0;
                        bit_count <= 8'd7;
                        shift_reg <= {ADT7420_ADDR, 1'b0};  // Dirección + Write
                        state <= SEND_ADDR_W;
                    end
                end

                SEND_ADDR_W, SEND_REG: begin
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= ~shift_reg[7];  // Bit actual
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                    end else begin
                        scl_count <= 8'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_count == 0) begin
                            state <= (state == SEND_ADDR_W) ? ACK_ADDR_W : ACK_REG;
                        end else begin
                            bit_count <= bit_count - 8'd1;
                        end
                    end
                end

                ACK_ADDR_W, ACK_REG, ACK_ADDR_R, ACK_BYTE_H: begin
                    // Leer ACK del esclavo
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= 1'b0;  // Liberar SDA
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto (esclavo puede enviar ACK)
                    end else begin
                        scl_count <= 8'd0;
                        // Siguiente estado
                        if (state == ACK_ADDR_W) begin
                            shift_reg <= TEMP_REG_MSB;
                            bit_count <= 8'd7;
                            state <= SEND_REG;
                        end else if (state == ACK_REG) begin
                            state <= RESTART;
                        end else if (state == ACK_ADDR_R) begin
                            bit_count <= 8'd7;
                            state <= READ_BYTE_H;
                        end else begin  // ACK_BYTE_H
                            bit_count <= 8'd7;
                            state <= READ_BYTE_L;
                        end
                    end
                end

                RESTART: begin
                    // Condición RESTART
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= 1'b0;  // SDA alto
                    end else if (scl_count < SCL_DIV * 2) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b0;  // SDA alto
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b1;  // SDA bajo (START)
                    end else begin
                        scl_count <= 8'd0;
                        bit_count <= 8'd7;
                        shift_reg <= {ADT7420_ADDR, 1'b1};  // Dirección + Read
                        state <= SEND_ADDR_R;
                    end
                end

                SEND_ADDR_R: begin
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= ~shift_reg[7];
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                    end else begin
                        scl_count <= 8'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_count == 0) begin
                            state <= ACK_ADDR_R;
                        end else begin
                            bit_count <= bit_count - 8'd1;
                        end
                    end
                end

                READ_BYTE_H, READ_BYTE_L: begin
                    // Leer byte del esclavo
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= 1'b0;  // Liberar SDA
                    end else if (scl_count < SCL_DIV * 2) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        shift_reg <= {shift_reg[6:0], sda_in};  // Leer bit
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                    end else begin
                        scl_count <= 8'd0;
                        if (bit_count == 0) begin
                            if (state == READ_BYTE_H) begin
                                data_buffer[15:8] <= shift_reg;
                                state <= ACK_BYTE_H;
                            end else begin
                                data_buffer[7:0] <= shift_reg;
                                state <= NACK_BYTE_L;
                            end
                        end else begin
                            bit_count <= bit_count - 8'd1;
                        end
                    end
                end

                NACK_BYTE_L: begin
                    // Enviar NACK (último byte)
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= 1'b0;  // SDA alto (NACK)
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                    end else begin
                        scl_count <= 8'd0;
                        state <= STOP_BIT;
                    end
                end

                STOP_BIT: begin
                    // Condición STOP: SDA sube mientras SCL está alto
                    if (scl_count < SCL_DIV) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b1;  // SCL bajo
                        sda_en <= 1'b1;  // SDA bajo
                    end else if (scl_count < SCL_DIV * 2) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b1;  // SDA bajo
                    end else if (scl_count < SCL_DIV * 3) begin
                        scl_count <= scl_count + 8'd1;
                        scl_en <= 1'b0;  // SCL alto
                        sda_en <= 1'b0;  // SDA alto (STOP)
                    end else begin
                        scl_count <= 8'd0;
                        state <= DONE;
                    end
                end

                DONE: begin
                    temp_data <= data_buffer;
                    ready <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
