`timescale 1ns/1ps

module io_sync_debounce #(
    parameter integer WIDTH = 1,
    parameter integer CTR_WIDTH = 18
) (
    input  logic                  clk,
    input  logic                  resetn,
    input  logic [WIDTH-1:0]      din,
    output logic [WIDTH-1:0]      dout
);

    logic [WIDTH-1:0] sync_stage0;
    logic [WIDTH-1:0] sync_stage1;
    logic [WIDTH-1:0][CTR_WIDTH-1:0] counters;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            sync_stage0 <= '0;
            sync_stage1 <= '0;
            dout        <= '0;
            counters    <= '0;
        end else begin
            sync_stage0 <= din;
            sync_stage1 <= sync_stage0;

            for (int i = 0; i < WIDTH; i++) begin
                if (sync_stage1[i] != dout[i]) begin
                    counters[i] <= counters[i] + {{(CTR_WIDTH-1){1'b0}}, 1'b1};
                    if (&counters[i]) begin
                        dout[i]     <= sync_stage1[i];
                        counters[i] <= '0;
                    end
                end else begin
                    counters[i] <= '0;
                end
            end
        end
    end

endmodule
