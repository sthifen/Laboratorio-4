`timescale 1ns/1ps

module timer_peripheral (
    input  logic        clk,
    input  logic        resetn,
    input  logic        ctrl_we,
    input  logic [31:0] ctrl_wdata,
    input  logic        data_we,
    input  logic [31:0] data_wdata,
    output logic [31:0] ctrl_rdata,
    output logic [31:0] data_rdata
);

    logic [31:0] period_reg;
    logic [31:0] counter;
    logic        running;
    logic        done_flag;
    logic [31:0] ctrl_shadow;

    assign data_rdata = period_reg;
    assign ctrl_rdata = {ctrl_shadow[31:2], done_flag, running};

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            period_reg <= 32'd0;
            counter    <= 32'd0;
            running    <= 1'b0;
            done_flag  <= 1'b0;
            ctrl_shadow<= 32'd0;
        end else begin
            if (data_we) begin
                period_reg <= data_wdata;
            end

            if (ctrl_we) begin
                ctrl_shadow <= ctrl_wdata;
                if (ctrl_wdata[0]) begin
                    running   <= 1'b1;
                    done_flag <= 1'b0;
                    counter   <= period_reg;
                end
                if (ctrl_wdata[1]) begin
                    done_flag <= 1'b0;
                end
            end

            if (running) begin
                if (counter > 32'd0) begin
                    counter <= counter - 32'd1;
                end else begin
                    running   <= 1'b0;
                    done_flag <= 1'b1;
                end
            end
        end
    end

endmodule
