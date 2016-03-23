// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4 (win64) Build 1071353 Tue Nov 18 18:24:04 MST 2014
// Date        : Wed Mar 23 14:26:38 2016
// Host        : SDPC117 running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               D:/Devel/projekty/TMS/lnls_out/tms_master/tms_master.srcs/sources_1/ip/vio_boot/vio_boot_stub.v
// Design      : vio_boot
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tffg1156-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "vio,Vivado 2014.4" *)
module vio_boot(clk, probe_in0, probe_out0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[7:0],probe_out0[7:0]" */;
  input clk;
  input [7:0]probe_in0;
  output [7:0]probe_out0;
endmodule
