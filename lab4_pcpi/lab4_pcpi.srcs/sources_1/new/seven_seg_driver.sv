`timescale 1ns/1ps

module seven_seg_driver (
    input  logic        clk,        // 10 MHz
    input  logic        resetn,
    input  logic [31:0] data_reg,
    output logic [7:0]  an_o,
    output logic [7:0]  seg_o
);

    localparam int CLK_FREQ_HZ   = 10_000_000;
    localparam int NUM_DIGITS    = 8;
    localparam logic [NUM_DIGITS-1:0] ACTIVE_MASK = 8'b1100_0000; // Solo AN0 y AN1 encendidos
    localparam int REFRESH_COUNT = CLK_FREQ_HZ / (60 * NUM_DIGITS);
    localparam int REFRESH_WIDTH = $clog2(REFRESH_COUNT);
    localparam int DIGIT_IDX_W   = $clog2(NUM_DIGITS);

    logic [REFRESH_WIDTH-1:0] refresh_counter;
    logic [DIGIT_IDX_W-1:0]   digit_index;
    logic [3:0]               current_nibble;
    logic [6:0]               segments_low;

    function automatic [6:0] hex_to_segments(input logic [3:0] value);
        case (value)
            4'h0: hex_to_segments = 7'b1000000;
            4'h1: hex_to_segments = 7'b1111001;
            4'h2: hex_to_segments = 7'b0100100;
            4'h3: hex_to_segments = 7'b0110000;
            4'h4: hex_to_segments = 7'b0011001;
            4'h5: hex_to_segments = 7'b0010010;
            4'h6: hex_to_segments = 7'b0000010;
            4'h7: hex_to_segments = 7'b1111000;
            4'h8: hex_to_segments = 7'b0000000;
            4'h9: hex_to_segments = 7'b0010000;
            4'hA: hex_to_segments = 7'b0001000;
            4'hB: hex_to_segments = 7'b0000011;
            4'hC: hex_to_segments = 7'b1000110;
            4'hD: hex_to_segments = 7'b0100001;
            4'hE: hex_to_segments = 7'b0000110;
            4'hF: hex_to_segments = 7'b0001110;
            default: hex_to_segments = 7'b1111111;
        endcase
    endfunction

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            refresh_counter <= '0;
            digit_index     <= '0;
        end else begin
            if (refresh_counter == (REFRESH_COUNT - 1)) begin
                refresh_counter <= '0;
                if (digit_index == NUM_DIGITS - 1)
                    digit_index <= '0;
                else
                    digit_index <= digit_index + 1'b1;
            end else begin
                refresh_counter <= refresh_counter + 1'b1;
            end
        end
    end

    always_comb begin
        unique case (digit_index)
            0: current_nibble = data_reg[3:0];
            1: current_nibble = data_reg[7:4];
            2: current_nibble = data_reg[11:8];
            3: current_nibble = data_reg[15:12];
            4: current_nibble = data_reg[19:16];
            5: current_nibble = data_reg[23:20];
            6: current_nibble = data_reg[27:24];
            default: current_nibble = data_reg[31:28];
        endcase

        segments_low = hex_to_segments(current_nibble);
        an_o         = 8'hFF;
        if (ACTIVE_MASK[digit_index])
            an_o[digit_index] = 1'b0;

        seg_o[6:0] = segments_low;
        seg_o[7]   = 1'b1; // Punto decimal apagado
    end

endmodule
