------------------------------------------------------------------------------
-- Title      : Top DSP design
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2013-09-01
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: Top design for testing the integration/control of the DSP with
-- FMC130M_4ch board
-------------------------------------------------------------------------------
-- Copyright (c) 2012 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-09-01  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Memory core generator
use work.gencores_pkg.all;
-- Custom Wishbone Modules
use work.dbe_wishbone_pkg.all;
-- Custom common cores
use work.dbe_common_pkg.all;
-- Wishbone stream modules and interface
use work.wb_stream_generic_pkg.all;
-- FMC516 definitions
use work.fmc_adc_pkg.all;
-- DSP definitions
use work.dsp_cores_pkg.all;
-- Positicon Calc constants
use work.position_calc_uvx_const_pkg.all;
-- Genrams
use work.genram_pkg.all;
-- Data Acquisition core
use work.acq_core_pkg.all;
-- PCIe Core
use work.bpm_pcie_a7_pkg.all;
-- PCIe Core Constants
use work.bpm_pcie_a7_const_pkg.all;
-- Meta Package
use work.sdb_meta_pkg.all;

use work.spi2wbm_pkg.all;
use work.fmc_general_pkg.all;
use work.fmc_boards_pkg.all;
use work.afc_pkg.all;

entity dbe_bpm_dsp is
port(
  -----------------------------------------
  -- Clocking pins
  -----------------------------------------
  sys_clk_p_i                                : in std_logic;
  sys_clk_n_i                                : in std_logic;

  -----------------------------------------
  -- Reset Button
  -----------------------------------------
  sys_rst_button_n_i                         : in std_logic;

  
  
  -- 20MHz boot clock, always active
  boot_clk_i                                 : in std_logic;

  -----------------------------------------
  -- UART pins
  -----------------------------------------

  rs232_txd_o                                : out std_logic;
  rs232_rxd_i                                : in std_logic;

  -----------------------------
  -- AFC Diagnostics
  -----------------------------

  diag_spi_cs_i                             : in std_logic;
  diag_spi_si_i                             : in std_logic;
  diag_spi_so_o                             : out std_logic;
  diag_spi_clk_i                            : in std_logic;


  -- MLVDS
  mlvds_io                                  : inout std_logic_vector(7 downto 0);
  mlvds_dir_o                               : out std_logic_vector(7 downto 0);

--  -- FMC 5ch ttla
  
--  fmc1_in_p : in std_logic_vector(4 downto 0);
--  fmc1_in_n : in std_logic_vector(4 downto 0);
--  fmc1_term_o : out std_logic_vector(4 downto 0);
    
--  fmc1_oen_o : out std_logic_vector(4 downto 0);
--  fmc1_out_p : out std_logic_vector(4 downto 0);
--  fmc1_out_n : out std_logic_vector(4 downto 0);
  
  

--  -- FMC2 dio 5ch ttl a
  fmc1_in: in t_fmc_signals_in;
  fmc1_out: out t_fmc_signals_out;
  fmc1_inout: inout t_fmc_signals_bidir;
  
--  fmc2_in: in t_fmc_signals_in;
--  fmc2_out: out t_fmc_signals_out;
  
--  -----------------------------
--  -- FMC1_130m_4ch ports
--  -----------------------------

--  -- ADC LTC2208 interface
--  fmc1_adc_pga_o                             : out std_logic;
--  fmc1_adc_shdn_o                            : out std_logic;
--  fmc1_adc_dith_o                            : out std_logic;
--  fmc1_adc_rand_o                            : out std_logic;

--  -- ADC0 LTC2208
--  fmc1_adc0_clk_i                            : in std_logic;
--  fmc1_adc0_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc1_adc0_of_i                             : in std_logic; -- Unused

--  -- ADC1 LTC2208
--  fmc1_adc1_clk_i                            : in std_logic;
--  fmc1_adc1_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc1_adc1_of_i                             : in std_logic; -- Unused

--  -- ADC2 LTC2208
--  fmc1_adc2_clk_i                            : in std_logic;
--  fmc1_adc2_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc1_adc2_of_i                             : in std_logic; -- Unused

--  -- ADC3 LTC2208
--  fmc1_adc3_clk_i                            : in std_logic;
--  fmc1_adc3_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc1_adc3_of_i                             : in std_logic; -- Unused

--  ---- FMC General Status
--  --fmc1_prsnt_i                               : in std_logic;
--  --fmc1_pg_m2c_i                              : in std_logic;
--  --fmc1_clk_dir_i                             : in std_logic;

--  -- Trigger
--  fmc1_trig_dir_o                            : out std_logic;
--  fmc1_trig_term_o                           : out std_logic;
--  fmc1_trig_val_p_b                          : inout std_logic;
--  fmc1_trig_val_n_b                          : inout std_logic;

--  -- Si571 clock gen
--  fmc1_si571_scl_pad_b                       : inout std_logic;
--  fmc1_si571_sda_pad_b                       : inout std_logic;
--  fmc1_si571_oe_o                            : out std_logic;

--  -- AD9510 clock distribution PLL
--  fmc1_spi_ad9510_cs_o                       : out std_logic;
--  fmc1_spi_ad9510_sclk_o                     : out std_logic;
--  fmc1_spi_ad9510_mosi_o                     : out std_logic;
--  fmc1_spi_ad9510_miso_i                     : in std_logic;

--  fmc1_pll_function_o                        : out std_logic;
--  fmc1_pll_status_i                          : in std_logic;

--  -- AD9510 clock copy
--  fmc1_fpga_clk_p_i                          : in std_logic;
--  fmc1_fpga_clk_n_i                          : in std_logic;

--  -- Clock reference selection (TS3USB221)
--  fmc1_clk_sel_o                             : out std_logic;

--  -- EEPROM (Connected to the CPU)
--  --eeprom_scl_pad_b                          : inout std_logic;
--  --eeprom_sda_pad_b                          : inout std_logic;
--  fmc1_eeprom_scl_pad_b                     : inout std_logic;
--  fmc1_eeprom_sda_pad_b                     : inout std_logic;

--  -- Temperature monitor (LM75AIMM)
--  fmc1_lm75_scl_pad_b                       : inout std_logic;
--  fmc1_lm75_sda_pad_b                       : inout std_logic;

--  fmc1_lm75_temp_alarm_i                     : in std_logic;

--  -- FMC LEDs
--  fmc1_led1_o                                : out std_logic;
--  fmc1_led2_o                                : out std_logic;
--  fmc1_led3_o                                : out std_logic;

--  -----------------------------
--  -- FMC2_130m_4ch ports
--  -----------------------------

--  -- ADC LTC2208 interface
--  fmc2_adc_pga_o                             : out std_logic;
--  fmc2_adc_shdn_o                            : out std_logic;
--  fmc2_adc_dith_o                            : out std_logic;
--  fmc2_adc_rand_o                            : out std_logic;

--  -- ADC0 LTC2208
--  fmc2_adc0_clk_i                            : in std_logic;
--  fmc2_adc0_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc2_adc0_of_i                             : in std_logic; -- Unused

--  -- ADC1 LTC2208
--  fmc2_adc1_clk_i                            : in std_logic;
--  fmc2_adc1_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc2_adc1_of_i                             : in std_logic; -- Unused

--  -- ADC2 LTC2208
--  fmc2_adc2_clk_i                            : in std_logic;
--  fmc2_adc2_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc2_adc2_of_i                             : in std_logic; -- Unused

--  -- ADC3 LTC2208
--  fmc2_adc3_clk_i                            : in std_logic;
--  fmc2_adc3_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
--  fmc2_adc3_of_i                             : in std_logic; -- Unused

--  ---- FMC General Status
--  --fmc2_prsnt_i                               : in std_logic;
--  --fmc2_pg_m2c_i                              : in std_logic;
--  --fmc2_clk_dir_i                             : in std_logic;

--  -- Trigger
--  fmc2_trig_dir_o                            : out std_logic;
--  fmc2_trig_term_o                           : out std_logic;
--  fmc2_trig_val_p_b                          : inout std_logic;
--  fmc2_trig_val_n_b                          : inout std_logic;

--  -- Si571 clock gen
--  fmc2_si571_scl_pad_b                       : inout std_logic;
--  fmc2_si571_sda_pad_b                       : inout std_logic;
--  fmc2_si571_oe_o                            : out std_logic;

--  -- AD9510 clock distribution PLL
--  fmc2_spi_ad9510_cs_o                       : out std_logic;
--  fmc2_spi_ad9510_sclk_o                     : out std_logic;
--  fmc2_spi_ad9510_mosi_o                     : out std_logic;
--  fmc2_spi_ad9510_miso_i                     : in std_logic;

--  fmc2_pll_function_o                        : out std_logic;
--  fmc2_pll_status_i                          : in std_logic;

--  -- AD9510 clock copy
--  fmc2_fpga_clk_p_i                          : in std_logic;
--  fmc2_fpga_clk_n_i                          : in std_logic;

--  -- Clock reference selection (TS3USB221)
--  fmc2_clk_sel_o                             : out std_logic;

--  -- EEPROM (Connected to the CPU)
--  --eeprom_scl_pad_b                          : inout std_logic;
--  --eeprom_sda_pad_b                          : inout std_logic;

--  -- Temperature monitor (LM75AIMM)
--  fmc2_lm75_scl_pad_b                       : inout std_logic;
--  fmc2_lm75_sda_pad_b                       : inout std_logic;

--  fmc2_lm75_temp_alarm_i                     : in std_logic;

--  -- FMC LEDs
--  fmc2_led1_o                                : out std_logic;
--  fmc2_led2_o                                : out std_logic;
--  fmc2_led3_o                                : out std_logic;

  -----------------------------------------
  -- Position Calc signals
  -----------------------------------------

  -- Uncross signals
  --clk_swap_o                                 : out std_logic;
  --clk_swap2x_o                               : out std_logic;
  --flag1_o                                    : out std_logic;
  --flag2_o                                    : out std_logic;

  -----------------------------------------
  -- General board status
  -----------------------------------------
  --fmc_mmcm_lock_led_o                       : out std_logic;
  --fmc_pll_status_led_o                      : out std_logic

  -----------------------------------------
  -- PCIe pins
  -----------------------------------------

--  -- DDR3 memory pins
--  ddr3_dq_b                                 : inout std_logic_vector(c_ddr_dq_width-1 downto 0);
--  ddr3_dqs_p_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
--  ddr3_dqs_n_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
--  ddr3_addr_o                               : out   std_logic_vector(c_ddr_row_width-1 downto 0);
--  ddr3_ba_o                                 : out   std_logic_vector(c_ddr_bank_width-1 downto 0);
--  ddr3_cs_n_o                               : out   std_logic_vector(0 downto 0);
--  ddr3_ras_n_o                              : out   std_logic;
--  ddr3_cas_n_o                              : out   std_logic;
--  ddr3_we_n_o                               : out   std_logic;
--  ddr3_reset_n_o                            : out   std_logic;
--  ddr3_ck_p_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
--  ddr3_ck_n_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
--  ddr3_cke_o                                : out   std_logic_vector(c_ddr_cke_width-1 downto 0);
--  ddr3_dm_o                                 : out   std_logic_vector(c_ddr_dm_width-1 downto 0);
--  ddr3_odt_o                                : out   std_logic_vector(c_ddr_odt_width-1 downto 0);

--  -- PCIe transceivers
--  pci_exp_rxp_i                             : in  std_logic_vector(c_pcie_lanes - 1 downto 0);
--  pci_exp_rxn_i                             : in  std_logic_vector(c_pcie_lanes - 1 downto 0);
--  pci_exp_txp_o                             : out std_logic_vector(c_pcie_lanes - 1 downto 0);
--  pci_exp_txn_o                             : out std_logic_vector(c_pcie_lanes - 1 downto 0);

--  -- PCI clock and reset signals
--  pcie_clk_p_i                              : in std_logic;
--  pcie_clk_n_i                              : in std_logic

  -----------------------------------------
  -- Button pins
  -----------------------------------------
  --buttons_i                                 : in std_logic_vector(7 downto 0);

  -----------------------------------------
  -- User LEDs
  -----------------------------------------
  --leds_o                                    : out std_logic_vector(7 downto 0)
  vadj2_clk_updaten_o                        : inout std_logic
);
end dbe_bpm_dsp;

architecture rtl of dbe_bpm_dsp is

  -- Top crossbar layout
  -- Number of slaves
  constant c_slaves                         : natural := 3;
  -----------------------------------------------------------
  constant c_slv_dpram_sys_port0_id        : natural := 0;
  constant c_slv_periph_id                 : natural := 1;
  constant c_slv_fmcdio5chttl_1_id          : natural := 2;
  

  -- Number of masters
  constant c_masters                        : natural := 1;            -- RS232-Syscon, PCIe

  -- Master indexes
  constant c_ma_spi_id                     : natural := 0;
  constant c_ma_rs232_syscon_id            : natural := 1;
  constant c_ma_pcie_id                    : natural := 2;
    
  constant c_dpram_size                     : natural := 16384/4; -- in 32-bit words (16KB)
  constant c_acq_fifo_size                  : natural := 256;


  -- GPIO num pinscalc
  constant c_leds_num_pins                  : natural := 8;
  constant c_buttons_num_pins               : natural := 8;

  -- Counter width. It willl count up to 2^32 clock cycles
  constant c_counter_width                  : natural := 32;

  -- TICs counter period. 100MHz clock -> msec granularity
  constant c_tics_cntr_period               : natural := 100000;
  --constant c_tics_cntr_period               : natural := 100000000;

  -- Number of reset clock cycles (FF)
  constant c_button_rst_width               : natural := 255;

  -- number of the ADC reference clock used for all downstream
  -- FPGA logic
  constant c_adc_ref_clk                    : natural := 0;

  -- Number of top level clocks
  constant c_num_tlvl_clks                  : natural := 2; -- CLK_SYS and CLK_200 MHz
  constant c_clk_sys_id                     : natural := 0; -- CLK_SYS and CLK_200 MHz
  constant c_clk_200mhz_id                  : natural := 1; -- CLK_SYS and CLK_200 MHz

  -- FMC130m_4ch layout. Size (0x00000FFF) is larger than needed. Just to be sure
  -- no address overlaps will occur
  -- @todo: export sdb layouts to pkg files  
  constant c_fmc1_dio5cha_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000300");
  constant c_periph_bridge_sdb       : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000600");
 
  -- WB SDB (Self describing bus) layout
  constant g_en_fmc1_dio : boolean := true;
  constant g_en_dpram_raw : boolean := false;
  
  
  constant c_req_layout : t_sdb_record_array(c_slaves-1 downto 0) :=

    (c_slv_dpram_sys_port0_id  => f_sdb_auto_device(f_xwb_dpram(c_dpram_size),  g_en_dpram_raw),   -- 16KB RAM
     c_slv_fmcdio5chttl_1_id   => f_sdb_auto_bridge(c_fmc1_dio5cha_bridge_sdb, g_en_fmc1_dio),
     c_slv_periph_id           => f_sdb_auto_bridge(c_periph_bridge_sdb,        true)   -- General peripherals control port
    );
  
  
  constant c_layout : t_sdb_record_array(c_slaves-1 downto 0) := f_sdb_auto_layout(c_req_layout);
  constant c_sdb_address                    : t_wishbone_address := f_sdb_auto_sdb(c_req_layout);
  constant c_top_bridge_sdb  : t_sdb_bridge       := f_xwb_bridge_layout_sdb(true, c_layout, c_sdb_address);

  -- Crossbar master/slave arrays
  signal cbar_slave_i                       : t_wishbone_slave_in_array (c_masters-1 downto 0);
  signal cbar_slave_o                       : t_wishbone_slave_out_array(c_masters-1 downto 0);
  signal cbar_master_i                      : t_wishbone_master_in_array(c_slaves-1 downto 0);
  signal cbar_master_o                      : t_wishbone_master_out_array(c_slaves-1 downto 0);

  -- LM32 signals
  signal clk_sys                            : std_logic;
  signal lm32_interrupt                     : std_logic_vector(31 downto 0);
  signal lm32_rstn                          : std_logic;

  -- PCIe signals
  signal wb_ma_pcie_ack_in                  : std_logic;
  signal wb_ma_pcie_dat_in                  : std_logic_vector(63 downto 0);
  signal wb_ma_pcie_addr_out                : std_logic_vector(28 downto 0);
  signal wb_ma_pcie_dat_out                 : std_logic_vector(63 downto 0);
  signal wb_ma_pcie_we_out                  : std_logic;
  signal wb_ma_pcie_stb_out                 : std_logic;
  signal wb_ma_pcie_sel_out                 : std_logic;
  signal wb_ma_pcie_cyc_out                 : std_logic;

  signal wb_ma_pcie_rst                     : std_logic;
  signal wb_ma_pcie_rstn                    : std_logic;

  signal wb_ma_sladp_pcie_ack_in            : std_logic;
  signal wb_ma_sladp_pcie_dat_in            : std_logic_vector(31 downto 0);
  signal wb_ma_sladp_pcie_addr_out          : std_logic_vector(31 downto 0);
  signal wb_ma_sladp_pcie_dat_out           : std_logic_vector(31 downto 0);
  signal wb_ma_sladp_pcie_we_out            : std_logic;
  signal wb_ma_sladp_pcie_stb_out           : std_logic;
  signal wb_ma_sladp_pcie_sel_out           : std_logic_vector(3 downto 0);
  signal wb_ma_sladp_pcie_cyc_out           : std_logic;

  -- PCIe Debug signals

  signal dbg_app_addr                       : std_logic_vector(31 downto 0);
  signal dbg_app_cmd                        : std_logic_vector(2 downto 0);
  signal dbg_app_en                         : std_logic;
  signal dbg_app_wdf_data                   : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal dbg_app_wdf_end                    : std_logic;
  signal dbg_app_wdf_wren                   : std_logic;
  signal dbg_app_wdf_mask                   : std_logic_vector(c_ddr_payload_width/8-1 downto 0);
  signal dbg_app_rd_data                    : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal dbg_app_rd_data_end                : std_logic;
  signal dbg_app_rd_data_valid              : std_logic;
  signal dbg_app_rdy                        : std_logic;
  signal dbg_app_wdf_rdy                    : std_logic;
  signal dbg_ddr_ui_clk                     : std_logic;
  signal dbg_ddr_ui_reset                   : std_logic;

  signal dbg_arb_req                        : std_logic_vector(1 downto 0);
  signal dbg_arb_gnt                        : std_logic_vector(1 downto 0);

  -- To/From Acquisition Core
  signal acq1_chan_array                    : t_acq_chan_array(c_acq_num_channels-1 downto 0);
  signal acq2_chan_array                    : t_acq_chan_array(c_acq_num_channels-1 downto 0);

  
  -- memory arbiter interface
  signal memarb_acc_req                     : std_logic;
  signal memarb_acc_gnt                     : std_logic;

  -- Clocks and resets signals
  signal locked                             : std_logic;
  signal clk_sys_rstn                       : std_logic;
  signal clk_sys_rstn2                      : std_logic;
  signal clk_sys_rst                        : std_logic;
  signal clk_200mhz_rst                     : std_logic;
  signal clk_200mhz_rstn                    : std_logic;

  signal rst_button_sys_pp                  : std_logic;
  signal rst_button_sys                     : std_logic;
  signal rst_button_sys_n                   : std_logic;

  -- "c_num_tlvl_clks" clocks
  signal reset_clks                         : std_logic_vector(c_num_tlvl_clks-1 downto 0);
  signal reset_rstn                         : std_logic_vector(c_num_tlvl_clks-1 downto 0);

  signal rs232_rstn                         : std_logic;
  signal fs_rstn_dbg                        : std_logic;
  signal fs_rst2xn_dbg                      : std_logic;
  signal fs1_rstn                           : std_logic;
  signal fs1_rst2xn                         : std_logic;
  signal fs2_rstn                           : std_logic;
  signal fs2_rst2xn                         : std_logic;

  -- 200 Mhz clocck for iodelay_ctrl
  signal clk_200mhz                         : std_logic;

  -- ADC clock
  signal fs_clk_dbg                         : std_logic;
  signal fs_clk2x_dbg                       : std_logic;
  signal fs1_clk                            : std_logic;
  signal fs1_clk2x                          : std_logic;
  signal fs2_clk                            : std_logic;
  signal fs2_clk2x                          : std_logic;

   -- Global Clock Single ended
  signal sys_clk_gen                        : std_logic;
  signal sys_clk_gen_bufg                   : std_logic;



  -- GPIO LED signals
  signal gpio_slave_led_o                   : t_wishbone_slave_out;
  signal gpio_slave_led_i                   : t_wishbone_slave_in;
  signal gpio_leds_int                      : std_logic_vector(c_leds_num_pins-1 downto 0);
  -- signal leds_gpio_dummy_in                : std_logic_vector(c_leds_num_pins-1 downto 0);

  signal buttons_dummy                      : std_logic_vector(7 downto 0) := (others => '0');

  -- GPIO Button signals
  signal gpio_slave_button_o                : t_wishbone_slave_out;
  signal gpio_slave_button_i                : t_wishbone_slave_in;

  -- AFC diagnostics signals
  signal dbg_spi_clk                        : std_logic;
  signal dbg_spi_valid                      : std_logic;
  signal dbg_en                             : std_logic;
  signal dbg_addr                           : std_logic_vector(31 downto 0);
  signal dbg_serial_data                    : std_logic_vector(31 downto 0);
  signal dbg_spi_data                       : std_logic_vector(31 downto 0);

  -- Chipscope control signals
  signal CONTROL0                           : std_logic_vector(35 downto 0);
  signal CONTROL1                           : std_logic_vector(35 downto 0);
  signal CONTROL2                           : std_logic_vector(35 downto 0);
  signal CONTROL3                           : std_logic_vector(35 downto 0);
  signal CONTROL4                           : std_logic_vector(35 downto 0);

  -- Chipscope ILA 0 signals
  signal TRIG_ILA0_0                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA0_1                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA0_2                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA0_3                        : std_logic_vector(31 downto 0);

  -- Chipscope ILA 1 signals
  signal TRIG_ILA1_0                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA1_1                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA1_2                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA1_3                        : std_logic_vector(31 downto 0);

  -- Chipscope ILA 2 signals
  signal TRIG_ILA2_0                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA2_1                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA2_2                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA2_3                        : std_logic_vector(31 downto 0);

  -- Chipscope ILA 3 signals
  signal TRIG_ILA3_0                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA3_1                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA3_2                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA3_3                        : std_logic_vector(31 downto 0);

  -- Chipscope ILA 4 signals
  signal TRIG_ILA4_0                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA4_1                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA4_2                        : std_logic_vector(31 downto 0);
  signal TRIG_ILA4_3                        : std_logic_vector(31 downto 0);


  signal rst_async_n: std_logic;

  ---------------------------
  --      Components       --
  ---------------------------

  -- Clock generation
  component clk_gen is
  port(
    sys_clk_p_i                             : in std_logic;
    sys_clk_n_i                             : in std_logic;
    sys_clk_o                               : out std_logic;
    sys_clk_bufg_o                          : out std_logic
  );
  end component;

  -- Xilinx PLL
  component sys_pll is
  generic(
    -- 200 MHz input clock
    g_clkin_period                          : real := 5.000;
    g_divclk_divide                         : integer := 1;
    g_clkbout_mult_f                        : integer := 5;

    -- 100 MHz output clock
    g_clk0_divide_f                         : integer := 10;
    -- 200 MHz output clock
    g_clk1_divide                           : integer := 5
  );
  port(
    rst_i                                   : in std_logic := '0';
    clk_i                                   : in std_logic := '0';
    clk0_o                                  : out std_logic;
    clk1_o                                  : out std_logic;
    locked_o                                : out std_logic
  );
  end component;

  -- Xilinx Chipscope Controller
  component chipscope_icon_1_port
  port (
    CONTROL0                                : inout std_logic_vector(35 downto 0)
  );
  end component;

  component multiplier_16x10_DSP
  port (
    clk                                     : in std_logic;
    a                                       : in std_logic_vector(15 downto 0);
    b                                       : in std_logic_vector(9 downto 0);
    p                                       : out std_logic_vector(25 downto 0)
  );
  end component;

  component dds_adc_input
  port (
    aclk                                    : in std_logic;
    m_axis_data_tvalid                      : out std_logic;
    m_axis_data_tdata                       : out std_logic_vector(31 downto 0)
  );
  end component;

  component chipscope_icon_4_port
  port (
    CONTROL0                                : inout std_logic_vector(35 downto 0);
    CONTROL1                                : inout std_logic_vector(35 downto 0);
    CONTROL2                                : inout std_logic_vector(35 downto 0);
    CONTROL3                                : inout std_logic_vector(35 downto 0)
  );
  end component;

component test_adapter
port (
  clk_i : in std_logic;
  rst_i : in std_logic
  );
  end component;

  signal s_diag_spi_cs : std_logic;
  signal s_diag_spi_si : std_logic;
  signal s_diag_spi_so : std_logic;
  signal s_diag_spi_clk : std_logic;
  signal s_diag_bwbe : std_logic_vector(3 downto 0);
  signal s_diag_we: std_logic;
  signal s_diag_en: std_logic;
  signal s_diag_ram_q: std_logic_vector(31 downto 0);
  signal s_diag_ram_d: std_logic_vector(31 downto 0);

 signal s_sys_pll_rst: std_logic;

 signal dbg_slave_i: t_wishbone_master_out;
 signal dbg_slave_o: t_wishbone_slave_out;

      
           
signal fmc1_dio_raw_o: std_logic_vector(4 downto 0);
signal fmc1_dio_raw_i: std_logic_vector(4 downto 0);
signal mlvds_raw_in_o: std_logic_vector(7 downto 0);
signal mlvds_raw_out_i: std_logic_vector(7 downto 0);
signal s_trig: std_logic;
signal s_tick: std_logic;

signal s_rst_crossbar_n: std_logic;
signal r_rst_crossbar: std_logic;
signal s_rst_spi : std_logic;
signal r_rst_spi : std_logic;


 
component spi2wbm_link_top
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
end component spi2wbm_link_top;

component spi_multiplexer 
    generic (
       g_i2c_addr : natural := 40;
       g_modules : natural := 4;
       g_slaves_per_module : natural := 4
    );
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;

           i2c_sck : inout STD_LOGIC;
           i2c_sda : inout STD_LOGIC;

           
           sel_i : in STD_LOGIC;
           sclk_i : in STD_LOGIC;
           mosi_i : in STD_LOGIC;
           miso_o : out STD_LOGIC;
           
           m_ssel_o : out STD_LOGIC_VECTOR ((g_modules * g_slaves_per_module)-1 downto 0);
           m_mosi_o : out STD_LOGIC_VECTOR (g_modules-1 downto 0);
           m_sclk_o : out STD_LOGIC_VECTOR (g_modules-1 downto 0);
           m_miso_i : in STD_LOGIC_VECTOR (g_modules-1 downto 0)
           );
end component spi_multiplexer;

component xwb_dpram_raw
    generic (
      g_size                  : natural;
      g_init_file             : string                         := "";
      g_must_have_init_file   : boolean                        := true;
      g_slave1_interface_mode : t_wishbone_interface_mode      := CLASSIC;
      g_slave2_interface_mode : t_wishbone_interface_mode      := CLASSIC;
      g_slave1_granularity    : t_wishbone_address_granularity := WORD;
      g_slave2_granularity    : t_wishbone_address_granularity := WORD);
    port (
      clk_sys_i : in  std_logic;
      rst_n_i   : in  std_logic;
      slave1_i  : in  t_wishbone_slave_in;
      slave1_o  : out t_wishbone_slave_out;
      --slave2_i  : in  t_wishbone_slave_in;
      --slave2_o  : out t_wishbone_slave_out
                     -- Port B
      ram_bweb_i  : in std_logic_vector(3 downto 0);
      ram_web_i   : in std_logic;
      ram_ab_i   : in std_logic_vector(f_log2_size(g_size)-1 downto 0);
      ram_db_i   : in std_logic_vector(31 downto 0);
      ram_qb_o   : out std_logic_vector(31 downto 0)
);
end component;

signal s_spi_ssel : std_logic_vector(15 downto 0);
signal s_spi_mosi : STD_LOGIC_VECTOR (3 downto 0);
signal s_spi_sclk : STD_LOGIC_VECTOR (3 downto 0);
signal s_spi_miso : STD_LOGIC_VECTOR (3 downto 0);

  -- Xilinx Chipscope Logic Analyser
  -- Functions
  -- Generate dummy (0) values
  function f_zeros(size : integer)
      return std_logic_vector is
  begin
      return std_logic_vector(to_unsigned(0, size));
  end f_zeros;

begin

  -- Clock generation
  cmp_clk_gen : clk_gen
  port map (
    sys_clk_p_i                             => sys_clk_p_i,
    sys_clk_n_i                             => sys_clk_n_i,
    sys_clk_o                               => sys_clk_gen,
    sys_clk_bufg_o                          => sys_clk_gen_bufg
  );

   -- Obtain core locking and generate necessary clocks
  cmp_sys_pll_inst : sys_pll
  generic map (
    -- 125 MHz input clock
    g_clkin_period                          => 8.000,
    g_divclk_divide                         => 5,
    g_clkbout_mult_f                        => 32,

    -- 100 MHz output clock
    g_clk0_divide_f                         => 8,
    -- 200 MHz output clock
    g_clk1_divide                           => 4
  )
  port map (
    rst_i                                   => s_sys_pll_rst,
    clk_i                                   => sys_clk_gen_bufg,
    --clk_i                                   => sys_clk_gen,
    clk0_o                                  => clk_sys,     -- 100MHz locked clock
    clk1_o                                  => clk_200mhz,  -- 200MHz locked clock
    locked_o                                => locked        -- '1' when the PLL has locked
  );

  -- Reset synchronization. Hold reset line until few locked cycles have passed.
--  cmp_reset : gc_reset
--  generic map(
--    g_clocks                                => c_num_tlvl_clks    -- CLK_SYS & CLK_200
--  )
--  port map(
--    --free_clk_i                              => sys_clk_gen,
--    free_clk_i                              => sys_clk_gen_bufg,
--    locked_i                                => locked,
--    clks_i                                  => reset_clks,
--    rstn_o                                  => reset_rstn
--  );

  reset_clks(c_clk_sys_id)                  <= clk_sys;
  reset_clks(c_clk_200mhz_id)               <= clk_200mhz;
  
  --clk_sys_rstn                              <= reset_rstn(c_clk_sys_id) and rst_button_sys_n and
  --                                                rs232_rstn;-- and wb_ma_pcie_rstn;
  
  rst_async_n <= sys_rst_button_n_i and (not s_sys_pll_rst) and (locked);
  --- process with delayed sys_rst deassert ---
  rst_proc: process(clk_sys, rst_async_n)
  begin
    if rst_async_n = '0' then
       clk_sys_rstn <= '0';
       clk_sys_rstn2 <= '0';
    elsif rising_edge(clk_sys) then
       clk_sys_rstn2 <= '1';
       clk_sys_rstn <=  clk_sys_rstn2;
    end if;
  end process;
  
  clk_sys_rst                               <= not clk_sys_rstn;
  --mrstn_o                                   <= clk_sys_rstn;
  
  clk_200mhz_rstn                           <= reset_rstn(c_clk_200mhz_id);
  clk_200mhz_rst                            <=  not(reset_rstn(c_clk_200mhz_id));


  s_rst_crossbar_n <= '0' when clk_sys_rstn = '0' or r_rst_crossbar = '1' else '1';
  -- The top-most Wishbone B.4 crossbar
  cmp_interconnect : xwb_sdb_crossbar
  generic map(
    g_num_masters                           => c_masters,
    g_num_slaves                            => c_slaves,
    g_registered                            => true,
    g_wraparound                            => true, -- Should be true for nested buses
    g_layout                                => c_layout,
    g_sdb_addr                              => c_sdb_address
  )
  port map(
    clk_sys_i                               => clk_sys,
    rst_n_i                                 => s_rst_crossbar_n,
    -- Master connections (INTERCON is a slave)
    slave_i                                 => cbar_slave_i,
    slave_o                                 => cbar_slave_o,
    -- Slave connections (INTERCON is a master)
    master_i                                => cbar_master_i,
    master_o                                => cbar_master_o
  );

  ----------------------------------
  --         PCIe Core            --
  ----------------------------------

cmp_spi_multiplexer: spi_multiplexer 
    Port map ( clk_i => clk_sys,
           rst_i => s_rst_spi,

           i2c_sck => open,
           i2c_sda => open,

           
           sel_i => diag_spi_cs_i,
           sclk_i => diag_spi_clk_i,
           mosi_i =>  diag_spi_si_i,
           miso_o =>  diag_spi_so_o,
           
           m_ssel_o => s_spi_ssel,
           m_mosi_o  => s_spi_mosi,
           m_sclk_o  => s_spi_sclk,
           m_miso_i  => s_spi_miso
           );

  
  
  
s_rst_spi <= '1' when  clk_sys_rstn = '0' or r_rst_spi = '1' else '0';

cmp_spi2wbm_link_top: spi2wbm_link_top 
	port map (
		rst_i => s_rst_spi,
		clk_i => clk_sys,  
    
		-- SPI bus
		spi_sel => s_diag_spi_cs,
		spi_mosi => s_diag_spi_si,
		spi_miso   => s_diag_spi_so,
		spi_clk  => s_diag_spi_clk,


		-- WISHBONE master
		wb_master_i   => cbar_slave_o(c_ma_spi_id),
        wb_master_o => cbar_slave_i(c_ma_spi_id),
		   

		-- interface to dual port ram
		SERIAL_addr   =>  dbg_addr,
		SERIAL_data_o  =>  s_diag_ram_d,
		SERIAL_data_i  =>  s_diag_ram_q,
		SERIAL_bwbe   => s_diag_bwbe,
		SERIAL_we    => s_diag_we,
		SERIAL_en => s_diag_en
	);

s_diag_spi_cs <= s_spi_ssel(0);
s_diag_spi_si <= s_spi_mosi(0);
s_diag_spi_clk <= s_spi_sclk(0);
s_spi_miso(0) <= s_diag_spi_so;


  wb_ma_pcie_rstn                             <= not wb_ma_pcie_rst;


GEN_DPRAM_RAW_N: if not g_en_dpram_raw generate
  cbar_master_i(c_slv_dpram_sys_port0_id) <= cc_dummy_slave_out;
  s_diag_ram_q <= x"00000000";

end generate;


  ----------------------------------------------------------------------
  --                            SYS DPRAM                             --
  ----------------------------------------------------------------------
  -- Generic System DPRAM
  
GEN_DPRAM_RAW_Y: if g_en_dpram_raw generate
  
  
  cmp_ram : xwb_dpram_raw
  generic map(
    g_size                                  => c_dpram_size,
    g_must_have_init_file                   => false,
    g_slave1_interface_mode                 => PIPELINED,
    g_slave2_interface_mode                 => PIPELINED,
    g_slave1_granularity                    => BYTE,
    g_slave2_granularity                    => BYTE
  )
  port map(
    clk_sys_i                               => clk_sys,
    rst_n_i                                 => clk_sys_rstn,
    -- First port connected to the crossbar
    slave1_i                                => cbar_master_o(c_slv_dpram_sys_port0_id),
    slave1_o                                => cbar_master_i(c_slv_dpram_sys_port0_id),
    -- Second port connected to the crossbar
    ram_bweb_i  => s_diag_bwbe,
    ram_web_i   => s_diag_we,
    ram_ab_i(11 downto 8)   => (others =>'0'),
    ram_ab_i(7 downto 0)   => dbg_addr(7 downto 0),
    ram_db_i   => s_diag_ram_d,
    ram_qb_o   => s_diag_ram_q
    
  );

end generate;


  ----------------------------------------------------------------------
  --                      Peripherals Core                            --
  ----------------------------------------------------------------------

  cmp_xwb_dbe_periph : xwb_dbe_periph
  generic map(
    -- NOT used!
    --g_interface_mode                          : t_wishbone_interface_mode      := CLASSIC;
    -- NOT used!
    --g_address_granularity                     : t_wishbone_address_granularity := WORD;
    g_cntr_period                             => c_tics_cntr_period,
    g_num_leds                                => c_leds_num_pins,
    g_num_buttons                             => c_buttons_num_pins
  )
  port map(
    clk_sys_i                                 => clk_sys,
    rst_n_i                                   => clk_sys_rstn,

    -- UART
    --uart_rxd_i                                => uart_rxd_i,
    --uart_txd_o                                => uart_txd_o,
    uart_rxd_i                                => '1',
    uart_txd_o                                => open,

    -- LEDs
    led_out_o                                 => gpio_leds_int,
    led_in_i                                  => gpio_leds_int,
    led_oen_o                                 => open,

    -- Buttons
    button_out_o                              => open,
    --button_in_i                               => buttons_i,
    button_in_i                               => buttons_dummy,
    button_oen_o                              => open,


    -- MLVDS
    mlvds_io                                  => mlvds_io,
    mlvds_dir_o                               => mlvds_dir_o,
    mlvds_raw_in_o                            => mlvds_raw_in_o,
    mlvds_raw_out_i                           => mlvds_raw_out_i,

    tick_i                                    => fmc1_dio_raw_o(0),
    trig_i                                    => fmc1_dio_raw_o(1),
    tick_o                                    => s_tick,
    trig_o                                    => s_trig,
    
    -- Wishbone
    slave_i                                   => cbar_master_o(c_slv_periph_id),
    slave_o                                   => cbar_master_i(c_slv_periph_id)
  );

  --leds_o <= gpio_leds_int;

GEN_FMC1_DIO5_N: if not g_en_fmc1_dio generate
  --cbar_master_o(c_slv_fmcdio5chttl_1_id) <= cc_dummy_master_out;
  cbar_master_i(c_slv_fmcdio5chttl_1_id) <= cc_dummy_slave_out;
  fmc1_dio_raw_o <= "00000";
end generate;

GEN_FMC1_DIO5_Y: if g_en_fmc1_dio generate

cmp_fmc_5chttl_1_periph: fmc_dio5chttl
	generic map (g_interface_mode      => PIPELINED,
        g_address_granularity => BYTE,
        g_use_tristate => true,
        g_num_io => 5,
        g_fmc_id => 1,
        g_fmc_map => afc_v2_FMC_pinmap)
port map(clk_i         => clk_sys,
     rst_n_i       => clk_sys_rstn,
     port_fmc_in_i  => fmc1_in,
     port_fmc_out_o => fmc1_out,
     port_fmc_io    => fmc1_inout,
     slave_i        => cbar_master_o(c_slv_fmcdio5chttl_1_id),
     slave_o        => cbar_master_i(c_slv_fmcdio5chttl_1_id),
     raw_o          => fmc1_dio_raw_o,
     raw_i          => fmc1_dio_raw_i
     );
     
end generate;
  fmc1_dio_raw_i <= (3 => s_tick, 2 =>s_trig, others => '0');
  mlvds_raw_out_i <= (0 => s_tick, 1 =>s_trig, others => '0');

 


  
  cmp_chipscope_ila_wbm_top : chipscope_ila
    port map (
      CLK                                    => clk_sys,
      probe0                                 => cbar_slave_i(c_ma_spi_id).adr,
      probe1                                 => cbar_slave_i(c_ma_spi_id).dat,
      probe2                                 => cbar_slave_o(c_ma_spi_id).dat,
      
      probe3(0)                              => cbar_slave_i(c_ma_spi_id).cyc,
      probe3(1)                              => cbar_slave_i(c_ma_spi_id).stb,
      probe3(5 downto 2)                     => cbar_slave_i(c_ma_spi_id).sel,
      probe3(6)                              => cbar_slave_i(c_ma_spi_id).we,
      
      probe3(7)                              => cbar_slave_o(c_ma_spi_id).ack,
      probe3(8)                              => cbar_slave_o(c_ma_spi_id).err,
      probe3(9)                              => cbar_slave_o(c_ma_spi_id).rty,
      probe3(10)                             => cbar_slave_o(c_ma_spi_id).stall,
      probe3(11)                             => cbar_slave_o(c_ma_spi_id).int,
      
      probe3(15 downto 12)                   => (12 => fmc1_dio_raw_o(0), 13 => fmc1_dio_raw_o(1), 14 => s_tick,  15 => s_trig),

      probe3(16)                             => cbar_master_i(c_slv_dpram_sys_port0_id).stall,
      probe3(17)                             => cbar_master_i(c_slv_dpram_sys_port0_id).ack,
      probe3(18)                             => cbar_master_o(c_slv_dpram_sys_port0_id).stb,
      probe3(19)                             => cbar_master_o(c_slv_dpram_sys_port0_id).cyc,
            
      probe3(20)                             => cbar_master_i(c_slv_fmcdio5chttl_1_id).stall,
      probe3(21)                             => cbar_master_i(c_slv_fmcdio5chttl_1_id).ack,
      probe3(22)                             => cbar_master_o(c_slv_fmcdio5chttl_1_id).stb,
      probe3(23)                             => cbar_master_o(c_slv_fmcdio5chttl_1_id).cyc,
                  
      
      probe3(24)                             => cbar_master_i(c_slv_periph_id).stall,
      probe3(25)                             => cbar_master_i(c_slv_periph_id).ack,
      probe3(26)                             => cbar_master_o(c_slv_periph_id).stb,
      probe3(27)                             => cbar_master_o(c_slv_periph_id).cyc,
      
      
      -- SPI signals
      probe3(28)                             => s_diag_spi_si,
      probe3(29)                             => s_diag_spi_clk,
      probe3(30)                             => s_diag_spi_so,
      probe3(31)                             => s_diag_spi_cs
  );
  
  
 
  vio_boot_inst : vio_boot
  PORT MAP (
    clk => boot_clk_i,
    probe_in0 => (0 => sys_rst_button_n_i,
                  1 => s_sys_pll_rst,
                  2 => locked,
                  3 => rst_async_n,
                  4 => clk_sys_rstn,
                  5 => clk_sys_rstn2,
                  6 => clk_sys_rst,
                  others => '0'),
    
    probe_out0(0) => s_sys_pll_rst,
    probe_out0(1) => r_rst_crossbar,
    probe_out0(2) => r_rst_spi,
    probe_out0(7 downto 3) => open
  );
  --s_sys_pll_rst <= s_vio_boot_out0(0);

    vadj2_clk_updaten_o <= '1';
end rtl;
