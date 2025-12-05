// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Wed Dec  3 20:21:38 2025
// Host        : KIM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/KIMOA/Desktop/lab4s_copia/lab4_pcpi/lab4_pcpi.gen/sources_1/ip/RAM/RAM_sim_netlist.v
// Design      : RAM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "RAM,blk_mem_gen_v8_4_11,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_11,Vivado 2025.1" *) 
(* NotValidForBitStream *)
module RAM
   (clka,
    ena,
    wea,
    addra,
    dina,
    clkb,
    enb,
    addrb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [9:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_mode = "slave BRAM_PORTB" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [9:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [9:0]addra;
  wire [9:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire [0:0]wea;
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
  wire [31:0]NLW_U0_douta_UNCONNECTED;
  wire [9:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [9:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "10" *) 
  (* C_ADDRB_WIDTH = "10" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "1" *) 
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     5.254725 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
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
  (* C_INIT_FILE = "RAM.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "1" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "1024" *) 
  (* C_READ_DEPTH_B = "1024" *) 
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
  (* C_WRITE_DEPTH_A = "1024" *) 
  (* C_WRITE_DEPTH_B = "1024" *) 
  (* C_WRITE_MODE_A = "NO_CHANGE" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  RAM_blk_mem_gen_v8_4_11 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(NLW_U0_douta_UNCONNECTED[31:0]),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[9:0]),
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
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[9:0]),
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
        .wea(wea),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 28768)
`pragma protect data_block
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
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
