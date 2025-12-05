`timescale 1ns/1ps

module rv32i_core (
    input  logic        clk,
    input  logic        resetn,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,
    output logic        data_req_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,
    input  logic        data_ready_i
);

    typedef enum logic [2:0] {
        RESET,
        FETCH,
        FETCH_WAIT,
        DECODE,
        MEM_ACCESS,
        WRITEBACK
    } state_t;

    state_t state;

    logic [31:0] pc;
    logic [31:0] instr_reg;
    logic [31:0] regs [0:31];

    logic [4:0]  rd_idx_reg;
    logic        rd_we_reg;
    logic [31:0] rd_data_reg;
    logic [31:0] next_pc_reg;

    logic        mem_is_write;
    logic        mem_is_load;
    logic [31:0] mem_addr_reg;
    logic [31:0] mem_wdata_reg;
    logic [3:0]  mem_wstrb_reg;
    logic        data_req_reg;

    assign data_req_o  = data_req_reg;
    assign data_we_o   = mem_is_write;
    assign data_be_o   = mem_wstrb_reg;
    assign data_addr_o = mem_addr_reg;
    assign data_wdata_o = mem_wdata_reg;
    assign instr_addr_o = pc;

    // Combinational helpers
    function automatic [31:0] imm_i(input logic [31:0] instr);
        imm_i = {{20{instr[31]}}, instr[31:20]};
    endfunction

    function automatic [31:0] imm_s(input logic [31:0] instr);
        imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    endfunction

    function automatic [31:0] imm_b(input logic [31:0] instr);
        imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    endfunction

    function automatic [31:0] imm_j(input logic [31:0] instr);
        imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    endfunction

    function automatic [31:0] imm_u(input logic [31:0] instr);
        imm_u = {instr[31:12], 12'h000};
    endfunction

    // Register file read helpers
    function automatic [31:0] get_rs1(input logic [31:0] instr);
        get_rs1 = regs[instr[19:15]];
    endfunction

    function automatic [31:0] get_rs2(input logic [31:0] instr);
        get_rs2 = regs[instr[24:20]];
    endfunction

    // Sequential control
    always_ff @(posedge clk) begin
        if (!resetn) begin
            state        <= RESET;
            pc           <= 32'h0000_0000;
            instr_reg    <= 32'h0000_0013;
            rd_idx_reg   <= 5'd0;
            rd_we_reg    <= 1'b0;
            rd_data_reg  <= 32'h0;
            next_pc_reg  <= 32'h0;
            mem_is_write <= 1'b0;
            mem_is_load  <= 1'b0;
            mem_addr_reg <= 32'h0;
            mem_wdata_reg<= 32'h0;
            mem_wstrb_reg<= 4'b0000;
            data_req_reg <= 1'b0;
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 32'h0;
            end
        end else begin
            data_req_reg <= 1'b0;
            case (state)
                RESET: begin
                    state <= FETCH;
                end

                FETCH: begin
                    state <= FETCH_WAIT;
                end

                FETCH_WAIT: begin
                    instr_reg <= instr_rdata_i;
                    state <= DECODE;
                end

                DECODE: begin
                    automatic logic [6:0] opcode;
                    automatic logic [2:0] funct3;
                    automatic logic [6:0] funct7;
                    automatic logic [4:0] rd_idx;
                    automatic logic [31:0] rs1_val;
                    automatic logic [31:0] rs2_val;
                    automatic logic [31:0] alu_result;
                    automatic logic [31:0] pc_plus4;
                    automatic logic branch_taken;
                    automatic logic [31:0] branch_target;
                    automatic logic take_default;

                    opcode = instr_reg[6:0];
                    funct3 = instr_reg[14:12];
                    funct7 = instr_reg[31:25];
                    rd_idx = instr_reg[11:7];
                    rs1_val = get_rs1(instr_reg);
                    rs2_val = get_rs2(instr_reg);
                    alu_result = 32'h0;
                    pc_plus4 = pc + 32'd4;
                    branch_taken = 1'b0;
                    branch_target = pc_plus4;
                    take_default = 1'b1;

                    rd_we_reg <= 1'b0;
                    rd_data_reg <= 32'h0;
                    rd_idx_reg <= rd_idx;
                    next_pc_reg <= pc_plus4;
                    mem_is_write <= 1'b0;
                    mem_is_load  <= 1'b0;
                    mem_addr_reg <= 32'h0;
                    mem_wdata_reg<= 32'h0;
                    mem_wstrb_reg<= 4'b0000;

                    unique case (opcode)
                        7'b0110011: begin
                            // R-type
                            unique case (funct3)
                                3'b000: begin
                                    if (funct7 == 7'b0100000)
                                        alu_result = rs1_val - rs2_val;
                                    else
                                        alu_result = rs1_val + rs2_val;
                                end
                                3'b001: alu_result = rs1_val << rs2_val[4:0];
                                3'b010: alu_result = ($signed(rs1_val) < $signed(rs2_val)) ? 32'd1 : 32'd0;
                                3'b011: alu_result = (rs1_val < rs2_val) ? 32'd1 : 32'd0;
                                3'b100: alu_result = rs1_val ^ rs2_val;
                                3'b101: begin
                                    if (funct7 == 7'b0100000)
                                        alu_result = $signed(rs1_val) >>> rs2_val[4:0];
                                    else
                                        alu_result = rs1_val >> rs2_val[4:0];
                                end
                                3'b110: alu_result = rs1_val | rs2_val;
                                3'b111: alu_result = rs1_val & rs2_val;
                                default: alu_result = 32'h0;
                            endcase
                            rd_we_reg <= 1'b1;
                            rd_data_reg <= alu_result;
                        end

                        7'b0010011: begin
                            // I-type ALU
                            automatic logic [31:0] imm = imm_i(instr_reg);
                            unique case (funct3)
                                3'b000: rd_data_reg <= rs1_val + imm; // ADDI
                                3'b010: rd_data_reg <= ($signed(rs1_val) < $signed(imm)) ? 32'd1 : 32'd0; // SLTI
                                3'b011: rd_data_reg <= (rs1_val < imm) ? 32'd1 : 32'd0; // SLTIU
                                3'b100: rd_data_reg <= rs1_val ^ imm; // XORI
                                3'b110: rd_data_reg <= rs1_val | imm; // ORI
                                3'b111: rd_data_reg <= rs1_val & imm; // ANDI
                                3'b001: rd_data_reg <= rs1_val << instr_reg[24:20]; // SLLI
                                3'b101: begin
                                    if (funct7[5])
                                        rd_data_reg <= $signed(rs1_val) >>> instr_reg[24:20]; // SRAI
                                    else
                                        rd_data_reg <= rs1_val >> instr_reg[24:20]; // SRLI
                                end
                                default: rd_data_reg <= 32'h0;
                            endcase
                            rd_we_reg <= 1'b1;
                        end

                        7'b0000011: begin
                            // LW
                            mem_is_load  <= 1'b1;
                            mem_is_write <= 1'b0;
                            mem_addr_reg <= rs1_val + imm_i(instr_reg);
                            mem_wstrb_reg<= 4'b0000;
                            state <= MEM_ACCESS;
                            take_default = 1'b0;
                        end

                        7'b0100011: begin
                            // SW
                            mem_is_load  <= 1'b0;
                            mem_is_write <= 1'b1;
                            mem_addr_reg <= rs1_val + imm_s(instr_reg);
                            mem_wdata_reg<= rs2_val;
                            mem_wstrb_reg<= 4'b1111;
                            state <= MEM_ACCESS;
                            take_default = 1'b0;
                        end

                        7'b1100011: begin
                            // Branch
                            automatic logic take;
                            take = 1'b0;
                            unique case (funct3)
                                3'b000: take = (rs1_val == rs2_val); // BEQ
                                3'b001: take = (rs1_val != rs2_val); // BNE
                                3'b100: take = ($signed(rs1_val) < $signed(rs2_val)); // BLT
                                3'b101: take = ($signed(rs1_val) >= $signed(rs2_val)); // BGE
                                default: take = 1'b0;
                            endcase
                            branch_taken = take;
                            branch_target = pc + imm_b(instr_reg);
                        end

                        7'b1101111: begin
                            // JAL
                            rd_we_reg   <= 1'b1;
                            rd_data_reg <= pc_plus4;
                            next_pc_reg <= pc + imm_j(instr_reg);
                        end

                        7'b0110111: begin
                            // LUI
                            rd_we_reg   <= 1'b1;
                            rd_data_reg <= imm_u(instr_reg);
                        end

                        7'b0010111: begin
                            // AUIPC
                            rd_we_reg   <= 1'b1;
                            rd_data_reg <= pc + imm_u(instr_reg);
                        end

                        default: begin
                            rd_we_reg <= 1'b0;
                        end
                    endcase

                    if (opcode == 7'b1100011) begin
                        if (branch_taken) begin
                            next_pc_reg <= branch_target;
                        end else begin
                            next_pc_reg <= pc_plus4;
                        end
                        rd_we_reg <= 1'b0;
                    end else if (opcode == 7'b0000011) begin
                        rd_idx_reg <= rd_idx;
                    end

                    if (take_default) begin
                        state <= WRITEBACK;
                    end
                end

                MEM_ACCESS: begin
                    data_req_reg <= 1'b1;
                    if (data_ready_i) begin
                        if (mem_is_load) begin
                            rd_data_reg   <= data_rdata_i;
                            rd_we_reg     <= 1'b1;
                        end else begin
                            rd_we_reg <= 1'b0;
                        end
                        state <= WRITEBACK;
                    end
                end

                WRITEBACK: begin
                    if (rd_we_reg && (rd_idx_reg != 5'd0)) begin
                        regs[rd_idx_reg] <= rd_data_reg;
                    end
                    regs[5'd0] <= 32'h0;
                    pc <= next_pc_reg;
                    state <= FETCH;
                end

                default: state <= FETCH;
            endcase
        end
    end

endmodule
