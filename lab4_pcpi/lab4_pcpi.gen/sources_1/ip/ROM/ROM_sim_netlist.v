// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Wed Dec  3 14:29:17 2025
// Host        : KIM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top ROM -prefix
//               ROM_ ROM_sim_netlist.v
// Design      : ROM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "ROM,blk_mem_gen_v8_4_11,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_11,Vivado 2025.1" *) 
(* NotValidForBitStream *)
module ROM
   (clka,
    ena,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;

  wire [8:0]addra;
  wire clka;
  wire [31:0]douta;
  wire ena;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_doutb_UNCONNECTED;
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "9" *) 
  (* C_ADDRB_WIDTH = "9" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     3.375199 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "ROM.mem" *) 
  (* C_INIT_FILE_NAME = "ROM.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "512" *) 
  (* C_READ_DEPTH_B = "512" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "512" *) 
  (* C_WRITE_DEPTH_B = "512" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  ROM_blk_mem_gen_v8_4_11 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[31:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[8:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[8:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(1'b0),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
gydSV72FvW4hnoyUt6yZFJHfJqjRQWPUfYIuDKP0fpjrPOkLRbJGBr4Z9msYTvoIHRlYtXJ2YMY0
d1TIQb+FK4gKsTRru9wr397OxuFBsTRf4e+ZjpYZEdsnqYWcgMSzhN4yhPvO06GyZO15y/LKBxa8
3OKwxVlOLYXhv+sxdXg=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
WHB6Zbfa5Qi47krP9T4L8UnPOlr881dWx7UcYaZfNGIQQM0gadcoXbhucIpRaUuyOKxv6yhKveRN
h0l+N9+KX6rbZ6+TRhP9JAMuPhlpI7T42QtRv5zx9+m3ct5S0NMszbFaK8zeTAYra5BGP7BHmtkr
MpKfLK5sFyaTE/A7ACtAace9MwFTHDZdl9uUs4aY6KJlm6GaypKduiqkNugukJp5vlFPX/ZapJqG
KMtMhI6grhcuYb1FJrwRZ4jW7hs9HxddSdGLzsZ0HsBcO/qaCPTst+ZA0YIQfd5ULlFmPqq39FfO
p1P+2hEH2n+LycbMj5cn4Dxfqv2R8eucM78R3w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
SmAzQA1VEuJXtJi5vXa2Jg7YvRqAJs6PX9HTZ1YqrJw4VfonBW3726gJ81BjlizpMkcf/Uk5sFIK
aPedVhEs4xCIZylz7gXYDshtytOA/pXUID2qV9nXr8qfI+FydSADUF3ScYDZmlkclFqlZrGq6DQ7
da3lJAzt2h/iR+cczrA=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
iAph5JWb/chMQpLPX1UoLjQDxN5l2I8McM/k2xN5wRht7HXoE6F5yV8luDjn3zkI6vnfUYo7BaI1
mogRRx+R3XcwxvhHr+lngh4+/YLVex1TFncl+kiUMAsu3M/FjFSiqGMVMdKTNLDqr35DuZJVyuiF
lTwXob/KkbQDJiJjBEoxbt+968rKRKRyJGcqIjm4mqRBdqMcgo3HOJFG74SFsWAQrxvXfBhdLSG3
OfoLfls9XDojBjp7G83k0h82g1eeWgBfydm/OcX9o48Pst93NvI4ua8WShZL8MCvRWYqWZrrjrWi
cfUjXAF5SDACjq1/OU6arz/Idz6/a7AP/jmexw==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BY49GZBxBT/gjZDPyaSWlti/sctckoR7jK6NuWdhnF9tiyNfVU7BqjjwxSnyMi0Uucv1BKHXC18h
8hQbFWnNtrq71ilURotXux7sssHlVJ2i1CsJWU18DOcBWxm2ai89uwvxDJh3TJkBJixB5KPvsDhL
lWOjTvZWPoR+Ixy+Tzo+U5Vx7z7SOakRwTrn3u7+c3vmCEBphE+HKeJExhBAoOEd0SXK5iwXaByW
D7Wb7zq6NNUmnCyaJ2BG9kGxLVsf+md7SlocuaFsYyaRZhwPyTucxIlz1tLYwcytKzx0ovoax3no
nYgzlzP/F0/PDWk9BqXgr/tuclc4EZYX0cf4ng==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
qGnCvL35qO7cbUEKCL50yDv1UvezcqBz601zctKop1954QlcjemzZWZHg1zJ00nJaToNdH2S8AKX
n8hNJvbQ+x5HEGL5DoSU9m5qjXd8xxocnZ0yzuZX/dGCT8kDn3gWJR2Gz13pT+w2LQUno1fX+MsC
ehgwvjBBT6GeYjdxHi+aybQUP9AblSxX/z3vh857SGCPohEWvghOgORCHAe45YD+ZWnL62FLxMM2
c+Ozq/Au/Q4q1Yzlzcfv8Mnsvg7OqOeEamQHbuYOfdkJUuYqOwsskEWW348u7FXtsf8m7P3pZyyz
IWyTDAW4igGguMPLHfbtK/twZx8ScJQmOKzglg==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hz+6K8+wh5/fukU4ZWNDXGsq6hreSVCSPP67nA6kUz9Vpjy4TtTnOrrl1BWY0ivEC7Ldyw8VI60A
VO/WPlt409LdAZdMZGsEZ1JuTZ0m9LPcgu9CPCyoMECctmd8LHE+otY6etTmYABB9syY61rk2hrv
RgbcyT/HCK9TzWxSm+XMqvx2nvagCLkMDPh/JZv51fj2zcKaBPnxsz8rnDipaeo0fEyVRC3Y1F/V
U3RmXojBjIumPHSJkQ537dENJEIA0Ra65u8EM/+ItUn1bcryLcIbKy1xGadrHmHdHRUoRcAodO2C
B48bNVeL0VnGg8P9ACIB04lMNzn5p6A1tPOb4Q==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
YDpb+UeT0rJ543Q8wCo2xSS3gpVAT+JoStgBlV5IMjJoUOWkiOPn691FGChmDi3BTq5NxC73KHHR
1galACCjeTGq6cv+0Zc2Ocm1oobdrnSPHp7TMDr5Zle8FX6WywJCiGdoWBODggZSlbOASIK/PVfY
cZM2z60M6RSvzsi3TnYHiKYHpju8THVoSgRd6r31GcbiSy9TjjARERXan0OVc79jGuAg90mmDEEq
91eqmn6NZ9yLI2fgBjFUZbtFCpmJ8WGxOL1h39niWnRK3ZXnk8jcpnZUlxLbYTPO0Z3vVr1zrvcn
RVQloU0OLqg7M95zSs7NtX5Vzvb6jGbMehWV+WMMyxWmxL2XOwsAwPSeX2dI2r77pioY7X6VzH7f
/JxMAnq9udra3WGPsUkD1G0CvPkCC3zdxjpVaflY37ztX9UONhKtzMQa8lJc1IL8GhXRY3R9Lg2c
HIeXSGkpNNuFDqKT6Khe/6Casq+SjFJq+IH9IUtz6RUZTkbFb0Xhgm2P

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Q+63zFEYw/LeMgxa7g8g79GGvSyIKDKD8RvvC4DHDQuGObf6n9OGZX4e17v/E/+EDEwUhsWQHFDI
Lp/aH+6fNRmhu9BEWVjxq2WRrQSl4eQjfIaSOXu2dlYh3JjRJwiUp4LteVh8RFAf5t5sRQO4dRIK
x+h28yliSgibaWEAv5FaJQ1EFbNwmgedAaSYjgf2A3afBUcBh5Uy9VHbW/zRzdhhJdsVNBjZYcFy
CVLOcf1toCRp8J4U5FlnFMOzFegUbdXFQhq2VmIhPRxWjrfTk6iR4BcMEN9UMij/5IHRAeBdksyD
CqEKsyFxosbI5KVMRZ1Ln75Zipn0JdsGekHkxg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DPUa5DLPYRWvbPnX0U412yoWvvvHyuq43DrYmDJGTK0cR5U4U6th8icYgizC1/hUAEzt19kM/hVa
zZh7bXSWACYLpcfhPY8dRTVGDZVjpbkraw0ceBryLP7jc6Jt5JdNw88tZtZpprCB7nQ25lUL82Hf
WTwL1ZqgGIvtfHhxO0JF5L5ES5giedwQ6u5ffXG3UB6ELcpQD1NvpW5lAz4mfXyvVDCAPZN581TF
tlAy79iKbPKlJ2zFn1BS2cuRIHHe2JRxwPo+0n5VD5CXVgg+lCYxTnCxI8CdyFaTumbs4IfAKwVI
wSN/btbwDUhW9hAHWHIRo+BpdJ4qeGcTDPKtsA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mf5hcf6JE6yLm0jNCQnHMVmogjLlPz6re0FwG67yvOJ3FuEorru0emIeAKEwgOoxjUYNWvcM7QAH
/UEeB2EIdjLl6glPAUda0HjtaCU2rdncVdM8k6DSMBggc4yo18Qx5F+1TD/RoBgoo0jNkMdDy6wJ
JHjqlN+R01z3yYIMQ9f2z6ZaYncbBYEp4+YAb7g1D7CSMxP5cFRpQznRpYp0JwqJfT9CHzlKgdab
8B288NxeLM66iYodiTS+GSRGLGtDWXpz9yeiuiPe6kJxae2GJyHIMSfluO/0Slc3m24DQNdbojf8
jdc0G2UnrDe5mCUTfYiDmpOWTUJOdYo0FK0N2g==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 18832)
`pragma protect data_block
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
9ppJc0NQZnaMSpbC2LrnuuMElsYw7w==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
