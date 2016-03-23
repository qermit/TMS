----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/05/2015 12:55:07 PM
-- Design Name: 
-- Module Name: test_adapter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.wishbone_pkg.all;
use work.spi2wbm_pkg.all;


entity test_adapter is
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC);
end test_adapter;

architecture Behavioral of test_adapter is

   signal s_rstn: std_logic;
   signal wb_int_master_input   : t_wishbone_master_in;
   signal wb_int_master_output  :t_wishbone_master_out;

   signal wb_ext_master_input   : t_wishbone_master_in;
   signal wb_ext_master_output  :t_wishbone_master_out;


begin

  vio_clasic_inst : vio_boot
  PORT MAP (
    clk => clk_i,
    probe_in0(0) => wb_int_master_input.ack,
    probe_in0(1) => wb_int_master_input.stall,
    probe_in0(2) => wb_int_master_input.rty,
    probe_in0(3) => wb_int_master_input.err,
    probe_in0(7 downto 4) => "1111",
    
    probe_out0(0) => wb_int_master_output.cyc,
    probe_out0(1) => wb_int_master_output.stb,
    probe_out0(5 downto 2) => wb_int_master_output.sel,
    probe_out0(6) => wb_int_master_output.we,
    probe_out0(7) => s_rstn
  );


  vio_pipelined_inst: vio_boot
  PORT MAP (
    clk => clk_i,
    probe_out0(0) => wb_ext_master_input.ack,
    probe_out0(1) => wb_ext_master_input.stall,
    probe_out0(2) => wb_ext_master_input.rty,
    probe_out0(3) => wb_ext_master_input.err,
    probe_out0(7 downto 4) => open,
    
    probe_in0(0) => wb_ext_master_output.cyc,
    probe_in0(1) => wb_ext_master_output.stb,
    probe_in0(5 downto 2) => wb_ext_master_output.sel,
    probe_in0(6) => wb_ext_master_output.we,
    probe_in0(7) => '1'
  );
 
  wb_int_master_output.dat <= x"deadbeef";
  wb_int_master_output.adr <= x"B16B00B5";
  wb_ext_master_input.dat <= x"CAFEBABE";

  cmp_spi_slave_adapter : wb_slave_adapter
  generic map (
    g_master_use_struct                     => false,
    g_master_mode                           => PIPELINED,
    g_master_granularity                    => BYTE,
    g_slave_use_struct                      => false,
    g_slave_mode                            => CLASSIC,
    g_slave_granularity                     => BYTE
  )
  port map (
    clk_sys_i                               => clk_i,
    rst_n_i                                 => s_rstn,

    sl_adr_i                                => wb_int_master_output.adr,
    sl_dat_i                                => wb_int_master_output.dat,
    sl_sel_i                                => wb_int_master_output.sel,
    sl_cyc_i                                => wb_int_master_output.cyc,
    sl_stb_i                                => wb_int_master_output.stb,
    sl_we_i                                 => wb_int_master_output.we,
    
    sl_dat_o                                => wb_int_master_input.dat,
    sl_ack_o                                => wb_int_master_input.ack,
    sl_stall_o                              => wb_int_master_input.stall,
    sl_int_o                                => open,
    sl_rty_o                                => wb_int_master_input.rty,
    sl_err_o                                => wb_int_master_input.err,

    ma_adr_o                                => wb_ext_master_output.adr,
    ma_dat_o                                => wb_ext_master_output.dat,
    ma_sel_o                                => wb_ext_master_output.sel,
    ma_cyc_o                                => wb_ext_master_output.cyc,
    ma_stb_o                                => wb_ext_master_output.stb,
    ma_we_o                                 => wb_ext_master_output.we,
    
    ma_dat_i                                => wb_ext_master_input.dat,
    ma_ack_i                                => wb_ext_master_input.ack,
    ma_stall_i                              => wb_ext_master_input.stall,
    ma_rty_i                                => wb_ext_master_input.rty,
    ma_err_i                                => wb_ext_master_input.err
  );

end Behavioral;
