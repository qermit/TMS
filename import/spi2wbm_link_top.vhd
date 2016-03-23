library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.spi2wbm_pkg.all;

entity spi2wbm_link_top is
    generic (
	   constant g_ma_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
       constant g_ma_address_granularity    : t_wishbone_address_granularity := BYTE
    );
	port(
		rst_i         : in  std_logic;
		clk_i         : in  std_logic;  -- fast spi system clock 

		-- SPI bus
		spi_sel       : in  std_logic;
		spi_mosi      : in  std_logic;
		spi_miso      : out std_logic;
		spi_clk       : in  std_logic;

		-- WISHBONE master
		wb_master_i   : in  t_wishbone_master_in;
		wb_master_o   : out t_wishbone_master_out;

		-- interface to dual port ram
		SERIAL_addr   : out STD_LOGIC_VECTOR(31 downto 0);
		SERIAL_data_o : out STD_LOGIC_VECTOR(31 downto 0);
		SERIAL_data_i : in  std_logic_vector(31 downto 0);
		SERIAL_bwbe   : out std_logic_vector(3 downto 0);
		SERIAL_we     : out STD_LOGIC;
		SERIAL_en     : out std_logic
	);
end entity spi2wbm_link_top;

architecture RTL of spi2wbm_link_top is



attribute keep : string;

   signal s_rstn: std_logic;
   signal wb_master_input   : t_wishbone_master_in;
   signal wb_master_output  :t_wishbone_master_out;

   signal wb_ext_master_input   : t_wishbone_master_in;
   signal wb_ext_master_output  :t_wishbone_master_out;

attribute keep of wb_master_output : signal is "true";
attribute keep of wb_master_input : signal is "true";
attribute keep of wb_ext_master_input : signal is "true";
attribute keep of wb_ext_master_output : signal is "true";


begin
	s_rstn <= not rst_i;
	U_spi_link : spi2wbm_link
		port map(
			rst_i         => rst_i,
			clk_i         => clk_i,
			spi_sel       => spi_sel,
			spi_mosi      => spi_mosi, 
			spi_miso      => spi_miso,
			spi_clk       => spi_clk,
			
			wb_master_i  => wb_master_input,
			wb_master_o  => wb_master_output,
			
			SERIAL_addr   => SERIAL_addr,
			SERIAL_data_o => SERIAL_data_o,
			SERIAL_data_i => SERIAL_data_i,
			SERIAL_bwbe   => SERIAL_bwbe,
			SERIAL_we     => SERIAL_we,
			SERIAL_en     => SERIAL_en
		);

		

  -- ETHMAC master interface is byte addressed, classic wishbone
  cmp_spi_slave_adapter : wb_slave_adapter
  generic map (
    g_master_use_struct                     => false,
    g_master_mode                           => g_ma_interface_mode,
    g_master_granularity                    => g_ma_address_granularity,
    g_slave_use_struct                      => false,
    g_slave_mode                            => CLASSIC,
    g_slave_granularity                     => BYTE
  )
  port map (
    clk_sys_i                               => clk_i,
    rst_n_i                                 => s_rstn,

    sl_adr_i                                => wb_master_output.adr,
    sl_dat_i                                => wb_master_output.dat,
    sl_sel_i                                => wb_master_output.sel,
    sl_cyc_i                                => wb_master_output.cyc,
    sl_stb_i                                => wb_master_output.stb,
    sl_we_i                                 => wb_master_output.we,
    sl_dat_o                                => wb_master_input.dat,
    sl_ack_o                                => wb_master_input.ack,
    sl_stall_o                              => wb_master_input.stall,
    sl_int_o                                => open,
    sl_rty_o                                => wb_master_input.rty,
    sl_err_o                                => wb_master_input.err,

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


wb_master_o <= wb_ext_master_output;
wb_ext_master_input <= wb_master_i;




end architecture;
