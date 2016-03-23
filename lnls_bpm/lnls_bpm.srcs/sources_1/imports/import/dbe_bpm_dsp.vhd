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

-- 
--use work.fmc_pkg.all;
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

entity dbe_tms_bpm is
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

  vadj2_clk_updaten_o                        : inout std_logic;
  
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

  -- FMC2 dio 5ch ttl a
  fmc1_in: in t_fmc_signals_in;
  fmc1_out: out t_fmc_signals_out;
  fmc1_io: inout t_fmc_signals_in;
  
  fmc2_in: in t_fmc_signals_in;
  fmc2_out: out t_fmc_signals_out;
  fmc2_io: inout t_fmc_signals_in;
  
  -----------------------------
  -- FMC1_130m_4ch ports
  -----------------------------

  -- ADC LTC2208 interface
  fmc1_adc_pga_o                             : out std_logic;
  fmc1_adc_shdn_o                            : out std_logic;
  fmc1_adc_dith_o                            : out std_logic;
  fmc1_adc_rand_o                            : out std_logic;

  -- ADC0 LTC2208
  fmc1_adc0_clk_i                            : in std_logic;
  fmc1_adc0_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc1_adc0_of_i                             : in std_logic; -- Unused

  -- ADC1 LTC2208
  fmc1_adc1_clk_i                            : in std_logic;
  fmc1_adc1_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc1_adc1_of_i                             : in std_logic; -- Unused

  -- ADC2 LTC2208
  fmc1_adc2_clk_i                            : in std_logic;
  fmc1_adc2_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc1_adc2_of_i                             : in std_logic; -- Unused

  -- ADC3 LTC2208
  fmc1_adc3_clk_i                            : in std_logic;
  fmc1_adc3_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc1_adc3_of_i                             : in std_logic; -- Unused

  ---- FMC General Status
  --fmc1_prsnt_i                               : in std_logic;
  --fmc1_pg_m2c_i                              : in std_logic;
  --fmc1_clk_dir_i                             : in std_logic;

  -- Trigger
  fmc1_trig_dir_o                            : out std_logic;
  fmc1_trig_term_o                           : out std_logic;
  fmc1_trig_val_p_b                          : inout std_logic;
  fmc1_trig_val_n_b                          : inout std_logic;

  -- Si571 clock gen
  fmc1_si571_scl_pad_b                       : inout std_logic;
  fmc1_si571_sda_pad_b                       : inout std_logic;
  fmc1_si571_oe_o                            : out std_logic;

  -- AD9510 clock distribution PLL
  fmc1_spi_ad9510_cs_o                       : out std_logic;
  fmc1_spi_ad9510_sclk_o                     : out std_logic;
  fmc1_spi_ad9510_mosi_o                     : out std_logic;
  fmc1_spi_ad9510_miso_i                     : in std_logic;

  fmc1_pll_function_o                        : out std_logic;
  fmc1_pll_status_i                          : in std_logic;

  -- AD9510 clock copy
  fmc1_fpga_clk_p_i                          : in std_logic;
  fmc1_fpga_clk_n_i                          : in std_logic;

  -- Clock reference selection (TS3USB221)
  fmc1_clk_sel_o                             : out std_logic;

  -- EEPROM (Connected to the CPU)
  --eeprom_scl_pad_b                          : inout std_logic;
  --eeprom_sda_pad_b                          : inout std_logic;
  fmc1_eeprom_scl_pad_b                     : inout std_logic;
  fmc1_eeprom_sda_pad_b                     : inout std_logic;

  -- Temperature monitor (LM75AIMM)
  fmc1_lm75_scl_pad_b                       : inout std_logic;
  fmc1_lm75_sda_pad_b                       : inout std_logic;

  fmc1_lm75_temp_alarm_i                     : in std_logic;

  -- FMC LEDs
  fmc1_led1_o                                : out std_logic;
  fmc1_led2_o                                : out std_logic;
  fmc1_led3_o                                : out std_logic;

  -----------------------------
  -- FMC2_130m_4ch ports
  -----------------------------

  -- ADC LTC2208 interface
  fmc2_adc_pga_o                             : out std_logic;
  fmc2_adc_shdn_o                            : out std_logic;
  fmc2_adc_dith_o                            : out std_logic;
  fmc2_adc_rand_o                            : out std_logic;

  -- ADC0 LTC2208
  fmc2_adc0_clk_i                            : in std_logic;
  fmc2_adc0_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc2_adc0_of_i                             : in std_logic; -- Unused

  -- ADC1 LTC2208
  fmc2_adc1_clk_i                            : in std_logic;
  fmc2_adc1_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc2_adc1_of_i                             : in std_logic; -- Unused

  -- ADC2 LTC2208
  fmc2_adc2_clk_i                            : in std_logic;
  fmc2_adc2_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc2_adc2_of_i                             : in std_logic; -- Unused

  -- ADC3 LTC2208
  fmc2_adc3_clk_i                            : in std_logic;
  fmc2_adc3_data_i                           : in std_logic_vector(c_num_adc_bits-1 downto 0);
  fmc2_adc3_of_i                             : in std_logic; -- Unused

  ---- FMC General Status
  --fmc2_prsnt_i                               : in std_logic;
  --fmc2_pg_m2c_i                              : in std_logic;
  --fmc2_clk_dir_i                             : in std_logic;

  -- Trigger
  fmc2_trig_dir_o                            : out std_logic;
  fmc2_trig_term_o                           : out std_logic;
  fmc2_trig_val_p_b                          : inout std_logic;
  fmc2_trig_val_n_b                          : inout std_logic;

  -- Si571 clock gen
  fmc2_si571_scl_pad_b                       : inout std_logic;
  fmc2_si571_sda_pad_b                       : inout std_logic;
  fmc2_si571_oe_o                            : out std_logic;

  -- AD9510 clock distribution PLL
  fmc2_spi_ad9510_cs_o                       : out std_logic;
  fmc2_spi_ad9510_sclk_o                     : out std_logic;
  fmc2_spi_ad9510_mosi_o                     : out std_logic;
  fmc2_spi_ad9510_miso_i                     : in std_logic;

  fmc2_pll_function_o                        : out std_logic;
  fmc2_pll_status_i                          : in std_logic;

  -- AD9510 clock copy
  fmc2_fpga_clk_p_i                          : in std_logic;
  fmc2_fpga_clk_n_i                          : in std_logic;

  -- Clock reference selection (TS3USB221)
  fmc2_clk_sel_o                             : out std_logic;

  -- EEPROM (Connected to the CPU)
  --eeprom_scl_pad_b                          : inout std_logic;
  --eeprom_sda_pad_b                          : inout std_logic;

  -- Temperature monitor (LM75AIMM)
  fmc2_lm75_scl_pad_b                       : inout std_logic;
  fmc2_lm75_sda_pad_b                       : inout std_logic;

  fmc2_lm75_temp_alarm_i                     : in std_logic;

  -- FMC LEDs
  fmc2_led1_o                                : out std_logic;
  fmc2_led2_o                                : out std_logic;
  fmc2_led3_o                                : out std_logic;

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

  -- DDR3 memory pins
  ddr3_dq_b                                 : inout std_logic_vector(c_ddr_dq_width-1 downto 0);
  ddr3_dqs_p_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_dqs_n_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_addr_o                               : out   std_logic_vector(c_ddr_row_width-1 downto 0);
  ddr3_ba_o                                 : out   std_logic_vector(c_ddr_bank_width-1 downto 0);
  ddr3_cs_n_o                               : out   std_logic_vector(0 downto 0);
  ddr3_ras_n_o                              : out   std_logic;
  ddr3_cas_n_o                              : out   std_logic;
  ddr3_we_n_o                               : out   std_logic;
  ddr3_reset_n_o                            : out   std_logic;
  ddr3_ck_p_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_ck_n_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_cke_o                                : out   std_logic_vector(c_ddr_cke_width-1 downto 0);
  ddr3_dm_o                                 : out   std_logic_vector(c_ddr_dm_width-1 downto 0);
  ddr3_odt_o                                : out   std_logic_vector(c_ddr_odt_width-1 downto 0);

  -- PCIe transceivers
  pci_exp_rxp_i                             : in  std_logic_vector(c_pcie_lanes - 1 downto 0);
  pci_exp_rxn_i                             : in  std_logic_vector(c_pcie_lanes - 1 downto 0);
  pci_exp_txp_o                             : out std_logic_vector(c_pcie_lanes - 1 downto 0);
  pci_exp_txn_o                             : out std_logic_vector(c_pcie_lanes - 1 downto 0);

  -- PCI clock and reset signals
  pcie_clk_p_i                              : in std_logic;
  pcie_clk_n_i                              : in std_logic

  -----------------------------------------
  -- Button pins
  -----------------------------------------
  --buttons_i                                 : in std_logic_vector(7 downto 0);

  -----------------------------------------
  -- User LEDs
  -----------------------------------------
  --leds_o                                    : out std_logic_vector(7 downto 0)
);
end dbe_tms_bpm;

architecture rtl of dbe_tms_bpm is

  -- Top crossbar layout
  -- Number of slaves
  constant c_slaves                         : natural := 6;
  -- General Dual-port memory, FMC130_1, FMC130_2, Acq_Core 1, Acq_Core 2,
  -- Position_calc_1, Posiotion_calc_2, Peripherals, AFC diagnostics, Repo URL,
  -- SDB synthesis, SDB integration

  -- Slaves indexes
  -----------------------------------------------------------
  constant c_slv_dpram_sys_port0_id        : natural := 0;
  --constant c_slv_afc_diag_id               : natural := 1;
  constant c_slv_periph_id                 : natural := 1;
  constant c_slv_fmcdio5chttl_1_id          : natural := 2;
  
  constant c_slv_sdb_repo_url_id           : natural := c_slaves-3;
  constant c_slv_sdb_synthesis_id          : natural := c_slaves-2;
  constant c_slv_sdb_integration_id        : natural := c_slaves-1;
  
    --constant c_slv_periph_id                 : natural := 1;
    --constant c_slv_afc_diag_id               : natural := 2;
    

  --constant c_slv_dpram_sys_port1_id        : natural := 1;
  --constant c_slv_pos_calc_1_id             : natural := 2;
  
  --constant c_slv_acq_core_1_id             : natural := 4;
  --constant c_slv_pos_calc_2_id             : natural := 5;
  --constant c_slv_fmc130m_4ch_2_id          : natural := 6;
  --constant c_slv_acq_core_2_id             : natural := 7;
  
--  constant c_slv_periph_id                 : natural := 8;

--  constant c_slv_sdb_repo_url_id           : natural := 10;
--  constant c_slv_sdb_synthesis_id          : natural := 11;
--  constant c_slv_sdb_integration_id        : natural := 12;

  -- Number of masters
  constant c_masters                        : natural := 1;            -- RS232-Syscon, PCIe

  -- Master indexes
  constant c_ma_spi_id                     : natural := 0;
  constant c_ma_rs232_syscon_id            : natural := 1;
  constant c_ma_pcie_id                    : natural := 2;
    
  constant c_dpram_size                     : natural := 16384/4; -- in 32-bit words (16KB)
  constant c_acq_fifo_size                  : natural := 256;

  constant c_acq_addr_width                 : natural := c_ddr_addr_width;
  constant c_acq_ddr_addr_res_width         : natural := 32;
  constant c_acq_ddr_addr_diff              : natural := c_acq_ddr_addr_res_width-c_ddr_addr_width;

  constant c_acq_adc_id                     : natural := 0;
  constant c_acq_adc_swap_id                : natural := 1;
  constant c_acq_mixiq12_id                 : natural := 2;
  constant c_acq_mixiq34_id                 : natural := 3;
  constant c_acq_tbtdecimiq12_id            : natural := 4;
  constant c_acq_tbtdecimiq34_id            : natural := 5;
  constant c_acq_tbt_amp_id                 : natural := 6;
  constant c_acq_tbt_phase_id               : natural := 7;
  constant c_acq_tbt_pos_id                 : natural := 8;
  constant c_acq_fofbdecimiq12_id           : natural := 9;
  constant c_acq_fofbdecimiq34_id           : natural := 10;
  constant c_acq_fofb_amp_id                : natural := 11;
  constant c_acq_fofb_phase_id              : natural := 12;
  constant c_acq_fofb_pos_id                : natural := 13;
  constant c_acq_monit_amp_id               : natural := 14;
  constant c_acq_monit_pos_id               : natural := 15;
  constant c_acq_monit_1_pos_id             : natural := 16;

  constant c_acq_pos_ddr3_width             : natural := 32;
  constant c_acq_num_channels               : natural := 17; -- ADC + ADC SWAP + MIXER + TBT AMP + TBT POS +
                                                            -- FOFB AMP + FOFB POS + MONIT AMP + MONIT POS + MONIT_1 POS
                                                            -- for each FMC
  constant c_acq_channels                   : t_acq_chan_param_array(c_acq_num_channels-1 downto 0) :=
    ( c_acq_adc_id            => (width => to_unsigned(64, c_acq_chan_max_w_log2)),
      c_acq_adc_swap_id       => (width => to_unsigned(64, c_acq_chan_max_w_log2)),
      c_acq_mixiq12_id        => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_mixiq34_id        => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_tbtdecimiq12_id   => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_tbtdecimiq34_id   => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_tbt_amp_id        => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_tbt_phase_id      => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_tbt_pos_id        => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_fofbdecimiq12_id  => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_fofbdecimiq34_id  => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_fofb_amp_id       => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_fofb_phase_id     => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_fofb_pos_id       => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_monit_amp_id      => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_monit_pos_id      => (width => to_unsigned(128, c_acq_chan_max_w_log2)),
      c_acq_monit_1_pos_id    => (width => to_unsigned(128, c_acq_chan_max_w_log2))
    );

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
  constant c_fmc130m_4ch_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000800");

  -- Position CAlC. layout. Regs, SWAP
  constant c_pos_calc_core_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000600");

  -- General peripherals layout. UART, LEDs (GPIO), Buttons (GPIO) and Tics counter
  constant c_periph_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000400");

  -- WB SDB (Self describing bus) layout
  constant c_layout : t_sdb_record_array(c_slaves-1 downto 0) :=

    (c_slv_dpram_sys_port0_id  => f_sdb_embed_device(f_xwb_dpram(c_dpram_size),  x"00000000"),   -- 16KB RAM
--     c_slv_dpram_sys_port1_id  => f_sdb_embed_device(f_xwb_dpram(c_dpram_size),  x"00100000"),   -- Second port to the same memory
--     c_slv_pos_calc_1_id       => f_sdb_embed_bridge(c_pos_calc_core_bridge_sdb,          x"00308000"),   -- Position Calc Core 1 control port
--   
     c_slv_fmcdio5chttl_1_id => f_sdb_embed_device(      c_xwb_gpio32_sdb, x"00310000"),
     --c_slv_fmc130m_4ch_1_id    => f_sdb_embed_bridge(c_fmc130m_4ch_bridge_sdb,   x"00310000"),   -- FMC130m_4ch control 1 port
--     c_slv_acq_core_1_id       => f_sdb_embed_device(c_xwb_acq_core_sdb,         x"00330000"),   -- Data Acquisition control port
--     c_slv_pos_calc_2_id       => f_sdb_embed_bridge(c_pos_calc_core_bridge_sdb,
--                                                                                 x"00340000"),   -- Position Calc Core 2 control port
--     c_slv_fmc130m_4ch_2_id    => f_sdb_embed_bridge(c_fmc130m_4ch_bridge_sdb,   x"00350000"),   -- FMC130m_4ch control 2 port
--     c_slv_acq_core_2_id       => f_sdb_embed_device(c_xwb_acq_core_sdb,         x"00360000"),   -- Data Acquisition control port
     c_slv_periph_id           => f_sdb_embed_bridge(c_periph_bridge_sdb,        x"00370000"),   -- General peripherals control port
     --c_slv_afc_diag_id         => f_sdb_embed_device(c_xwb_afc_diag_sdb,         x"00380000"),   -- AFC Diagnostics control port
       c_slv_sdb_repo_url_id     => f_sdb_embed_repo_url(c_sdb_repo_url),
           c_slv_sdb_synthesis_id    => f_sdb_embed_synthesis(c_sdb_synthesis),
       c_slv_sdb_integration_id  => f_sdb_embed_integration(c_sdb_integration)
    );

  -- Self Describing Bus ROM Address. It will be an addressed slave as well
  constant c_sdb_address                    : t_wishbone_address := x"00300000";

  -- FMC ADC data constants
  constant c_adc_data_ch0_lsb               : natural := 0;
  constant c_adc_data_ch0_msb               : natural := c_num_adc_bits-1 + c_adc_data_ch0_lsb;

  constant c_adc_data_ch1_lsb               : natural := c_adc_data_ch0_msb + 1;
  constant c_adc_data_ch1_msb               : natural := c_num_adc_bits-1 + c_adc_data_ch1_lsb;

  constant c_adc_data_ch2_lsb               : natural := c_adc_data_ch1_msb + 1;
  constant c_adc_data_ch2_msb               : natural := c_num_adc_bits-1 + c_adc_data_ch2_lsb;

  constant c_adc_data_ch3_lsb               : natural := c_adc_data_ch2_msb + 1;
  constant c_adc_data_ch3_msb               : natural := c_num_adc_bits-1 + c_adc_data_ch3_lsb;

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

  signal bpm_acq_dpram_dout                 : std_logic_vector(f_acq_chan_find_widest(c_acq_channels)-1 downto 0);
  signal bpm_acq_dpram_valid                : std_logic;

  signal bpm_acq_ext_dout                   : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal bpm_acq_ext_valid                  : std_logic;
  signal bpm_acq_ext_addr                   : std_logic_vector(c_acq_addr_width-1 downto 0);
  signal bpm_acq_ext_sof                    : std_logic;
  signal bpm_acq_ext_eof                    : std_logic;
  signal bpm_acq_ext_dreq                   : std_logic;
  signal bpm_acq_ext_stall                  : std_logic;

  signal memc_ui_clk                        : std_logic;
  signal memc_ui_rst                        : std_logic;
  signal memc_ui_rstn                       : std_logic;
  signal memc_cmd_rdy                       : std_logic;
  signal memc_cmd_en                        : std_logic;
  signal memc_cmd_instr                     : std_logic_vector(2 downto 0);
  signal memc_cmd_addr_resized              : std_logic_vector(c_acq_ddr_addr_res_width-1 downto 0);
  signal memc_cmd_addr                      : std_logic_vector(c_ddr_addr_width-1 downto 0);
  signal memc_wr_en                         : std_logic;
  signal memc_wr_end                        : std_logic;
  signal memc_wr_mask                       : std_logic_vector(c_ddr_payload_width/8-1 downto 0);
  signal memc_wr_data                       : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal memc_wr_rdy                        : std_logic;
  signal memc_rd_data                       : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal memc_rd_valid                      : std_logic;

  signal dbg_ddr_rb_data                    : std_logic_vector(c_ddr_payload_width-1 downto 0);
  signal dbg_ddr_rb_addr                    : std_logic_vector(c_acq_addr_width-1 downto 0);
  signal dbg_ddr_rb_valid                   : std_logic;

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

  -- FMC130m_4ch 1 Signals
  signal wbs_fmc1_in_array                  : t_wbs_source_in16_array(c_num_adc_channels-1 downto 0);
  signal wbs_fmc1_out_array                 : t_wbs_source_out16_array(c_num_adc_channels-1 downto 0);

  signal fmc1_mmcm_lock_int                  : std_logic;
  signal fmc1_pll_status_int                 : std_logic;

  signal fmc1_led1_int                       : std_logic;
  signal fmc1_led2_int                       : std_logic;
  signal fmc1_led3_int                       : std_logic;

  signal fmc1_clk                            : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc1_clk2x                          : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc1_data                           : std_logic_vector(c_num_adc_channels*c_num_adc_bits-1 downto 0);
  signal fmc1_data_valid                     : std_logic_vector(c_num_adc_channels-1 downto 0);

  signal fmc1_adc_data_ch0                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc1_adc_data_ch1                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc1_adc_data_ch2                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc1_adc_data_ch3                   : std_logic_vector(c_num_adc_bits-1 downto 0);

  signal fmc1_debug                          : std_logic;
  signal fmc1_rst_n                          : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc1_rst2x_n                        : std_logic_vector(c_num_adc_channels-1 downto 0);

  -- FMC130M 1 Debug
  signal fmc1_debug_valid_int                : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc1_debug_full_int                 : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc1_debug_empty_int                : std_logic_vector(c_num_adc_channels-1 downto 0);

  signal fmc1_adc_dly_debug_int             : t_adc_fn_dly_array(c_num_adc_channels-1 downto 0);

  -- FMC130m_4ch 2 Signals
  signal wbs_fmc2_in_array                  : t_wbs_source_in16_array(c_num_adc_channels-1 downto 0);
  signal wbs_fmc2_out_array                 : t_wbs_source_out16_array(c_num_adc_channels-1 downto 0);

  signal fmc2_mmcm_lock_int                  : std_logic;
  signal fmc2_pll_status_int                 : std_logic;

  signal fmc2_led1_int                       : std_logic;
  signal fmc2_led2_int                       : std_logic;
  signal fmc2_led3_int                       : std_logic;

  signal fmc2_clk                            : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc2_clk2x                          : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc2_data                           : std_logic_vector(c_num_adc_channels*c_num_adc_bits-1 downto 0);
  signal fmc2_data_valid                     : std_logic_vector(c_num_adc_channels-1 downto 0);

  signal fmc2_adc_data_ch0                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc2_adc_data_ch1                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc2_adc_data_ch2                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal fmc2_adc_data_ch3                   : std_logic_vector(c_num_adc_bits-1 downto 0);

  signal fmc2_debug                          : std_logic;
  signal fmc2_rst_n                          : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc2_rst2x_n                        : std_logic_vector(c_num_adc_channels-1 downto 0);

  -- FMC130M 2 Debug
  signal fmc2_debug_valid_int                : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc2_debug_full_int                 : std_logic_vector(c_num_adc_channels-1 downto 0);
  signal fmc2_debug_empty_int                : std_logic_vector(c_num_adc_channels-1 downto 0);

  signal fmc2_adc_dly_debug_int              : t_adc_fn_dly_array(c_num_adc_channels-1 downto 0);

  -- Uncross 1 signals
  signal dsp1_clk_rffe_swap                  : std_logic;
  signal dsp1_flag1_int                      : std_logic;
  signal dsp1_flag2_int                      : std_logic;

  -- DSP 1 signals
  signal dsp1_adc_ch0_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp1_adc_ch1_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp1_adc_ch2_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp1_adc_ch3_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);

  signal dsp1_mixi_ch0                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixi_ch1                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixi_ch2                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixi_ch3                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mix_valid                      : std_logic;

  signal dsp1_mixq_ch0                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixq_ch1                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixq_ch2                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp1_mixq_ch3                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);

  signal dsp1_tbtdecimi_ch0                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimi_ch1                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimi_ch2                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimi_ch3                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecim_valid                 : std_logic;

  signal dsp1_tbtdecimq_ch0                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimq_ch1                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimq_ch2                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbtdecimq_ch3                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);

  signal dsp1_tbt_amp_ch0                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_amp_ch1                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_amp_ch2                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_amp_ch3                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_amp_valid                  : std_logic;

  signal dsp1_tbt_pha_ch0                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_pha_ch1                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_pha_ch2                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_pha_ch3                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_tbt_pha_valid                  : std_logic;

  signal dsp1_fofbdecimi_ch0                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimi_ch1                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimi_ch2                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimi_ch3                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecim_valid                : std_logic;

  signal dsp1_fofbdecimq_ch0                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimq_ch1                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimq_ch2                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofbdecimq_ch3                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);

  signal dsp1_fofb_amp_ch0                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_amp_ch1                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_amp_ch2                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_amp_ch3                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_amp_valid                 : std_logic;

  signal dsp1_fofb_pha_ch0                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_pha_ch1                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_pha_ch2                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_pha_ch3                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_fofb_pha_valid                 : std_logic;

  signal dsp1_monit_amp_ch0                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_monit_amp_ch1                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_monit_amp_ch2                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_monit_amp_ch3                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_monit_amp_valid                : std_logic;

  signal dsp1_pos_x_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_pos_y_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_pos_q_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_pos_sum_tbt                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp1_pos_tbt_valid                  : std_logic;

  signal dsp1_pos_x_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_pos_y_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_pos_q_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_pos_sum_fofb                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp1_pos_fofb_valid                 : std_logic;

  signal dsp1_pos_x_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_pos_y_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_pos_q_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_pos_sum_monit                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp1_pos_monit_valid                : std_logic;

  signal dsp1_dbg_cur_address                : std_logic_vector(31 downto 0);
  signal dsp1_dbg_adc_ch0_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp1_dbg_adc_ch1_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp1_dbg_adc_ch2_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp1_dbg_adc_ch3_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);

  -- Uncross 2 signals
  signal dsp2_clk_rffe_swap                  : std_logic;
  signal dsp2_flag1_int                      : std_logic;
  signal dsp2_flag2_int                      : std_logic;

  -- DSP 2 signals
  signal dsp2_adc_ch0_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp2_adc_ch1_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp2_adc_ch2_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);
  signal dsp2_adc_ch3_data                   : std_logic_vector(c_num_adc_bits-1 downto 0);

  signal dsp2_mixi_ch0                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixi_ch1                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixi_ch2                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixi_ch3                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mix_valid                      : std_logic;

  signal dsp2_mixq_ch0                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixq_ch1                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixq_ch2                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);
  signal dsp2_mixq_ch3                       : std_logic_vector(c_pos_calc_IQ_width-1 downto 0);

  signal dsp2_tbtdecimi_ch0                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimi_ch1                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimi_ch2                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimi_ch3                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecim_valid                 : std_logic;

  signal dsp2_tbtdecimq_ch0                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimq_ch1                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimq_ch2                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbtdecimq_ch3                  : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);

  signal dsp2_tbt_amp_ch0                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_amp_ch1                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_amp_ch2                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_amp_ch3                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_amp_valid                  : std_logic;

  signal dsp2_tbt_pha_ch0                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_pha_ch1                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_pha_ch2                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_pha_ch3                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_tbt_pha_valid                  : std_logic;

  signal dsp2_fofbdecimi_ch0                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimi_ch1                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimi_ch2                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimi_ch3                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecim_valid                : std_logic;

  signal dsp2_fofbdecimq_ch0                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimq_ch1                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimq_ch2                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofbdecimq_ch3                 : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);

  signal dsp2_fofb_amp_ch0                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_amp_ch1                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_amp_ch2                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_amp_ch3                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_amp_valid                 : std_logic;

  signal dsp2_fofb_pha_ch0                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_pha_ch1                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_pha_ch2                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_pha_ch3                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_fofb_pha_valid                 : std_logic;

  signal dsp2_monit_amp_ch0                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_monit_amp_ch1                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_monit_amp_ch2                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_monit_amp_ch3                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_monit_amp_valid                : std_logic;

  signal dsp2_pos_x_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_pos_y_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_pos_q_tbt                      : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_pos_sum_tbt                    : std_logic_vector(c_pos_calc_tbt_decim_width-1 downto 0);
  signal dsp2_pos_tbt_valid                  : std_logic;

  signal dsp2_pos_x_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_pos_y_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_pos_q_fofb                     : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_pos_sum_fofb                   : std_logic_vector(c_pos_calc_fofb_decim_width-1 downto 0);
  signal dsp2_pos_fofb_valid                 : std_logic;

  signal dsp2_pos_x_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_pos_y_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_pos_q_monit                    : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_pos_sum_monit                  : std_logic_vector(c_pos_calc_monit_decim_width-1 downto 0);
  signal dsp2_pos_monit_valid                : std_logic;

  signal dsp2_dbg_cur_address                : std_logic_vector(31 downto 0);
  signal dsp2_dbg_adc_ch0_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp2_dbg_adc_ch1_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp2_dbg_adc_ch2_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);
  signal dsp2_dbg_adc_ch3_cond               : std_logic_vector(c_pos_calc_input_width-1 downto 0);

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

  ---- Chipscope ILA 6 signals
  --signal TRIG_ILA6_0                        : std_logic_vector(7 downto 0);
  --signal TRIG_ILA6_1                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA6_2                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA6_3                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA6_4                        : std_logic_vector(31 downto 0);

  ---- Chipscope ILA 7 signals
  --signal TRIG_ILA7_0                        : std_logic_vector(7 downto 0);
  --signal TRIG_ILA7_1                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA7_2                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA7_3                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA7_4                        : std_logic_vector(31 downto 0);

  ---- Chipscope ILA 8 signals
  --signal TRIG_ILA8_0                        : std_logic_vector(7 downto 0);
  --signal TRIG_ILA8_1                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA8_2                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA8_3                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA8_4                        : std_logic_vector(31 downto 0);

  ---- Chipscope ILA 9 signals
  --signal TRIG_ILA9_0                        : std_logic_vector(7 downto 0);
  --signal TRIG_ILA9_1                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA9_2                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA9_3                        : std_logic_vector(31 downto 0);
  --signal TRIG_ILA9_4                        : std_logic_vector(31 downto 0);

  ---- Chipscope ILA 10 signals
  --signal TRIG_ILA10_0                       : std_logic_vector(7 downto 0);
  --signal TRIG_ILA10_1                       : std_logic_vector(31 downto 0);
  --signal TRIG_ILA10_2                       : std_logic_vector(31 downto 0);
  --signal TRIG_ILA10_3                       : std_logic_vector(31 downto 0);
  --signal TRIG_ILA10_4                       : std_logic_vector(31 downto 0);

  ---- Chipscope VIO signals
  --signal vio_out                             : std_logic_vector(255 downto 0);
  --signal vio_out_dsp_config                  : std_logic_vector(255 downto 0);

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

component fmc_5chttl 
generic (
  g_num_io                : natural                        := 5;
g_negate_in    : std_logic_vector(255 downto 0) := (others => '0');
    g_negate_out   : std_logic_vector(255 downto 0) := (others => '0')
);
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           in_p_i : in STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           in_n_i : in STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           term_o : out STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           dir_o : out STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           out_p_o : out STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           out_n_o : out STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           
           slave_i       : in  t_wishbone_slave_in;
           slave_o       : out t_wishbone_slave_out;
                      
           raw_o: out STD_LOGIC_VECTOR (g_num_io-1 downto 0);
           raw_i: in  STD_LOGIC_VECTOR (g_num_io-1 downto 0)
           );
           end component;
           
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

  -- Generate button reset synchronous to each clock domain
  -- Detect button positive edge of clk_sys
--  cmp_button_sys_ffs : gc_sync_ffs
--  port map (
--    clk_i                                   => clk_sys,
--    rst_n_i                                 => '1',
--    data_i                                  => sys_rst_button_n_i and s_sys_pll_rst,
--    npulse_o                                => rst_button_sys_pp
--  );

  -- Generate the reset signal based on positive edge
  -- of synched gc
--  cmp_button_sys_rst : gc_extend_pulse
--  generic map (
--    g_width                                 => c_button_rst_width
--  )
--  port map(
--    clk_i                                   => clk_sys,
--    rst_n_i                                 => '1',
--    pulse_i                                 => rst_button_sys_pp,
--    extended_o                              => rst_button_sys
--  );

--  rst_button_sys_n                          <= not rst_button_sys;


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

  -- The LM32 is master 0+1
  --lm32_rstn                                 <= clk_sys_rstn;

  --cmp_lm32 : xwb_lm32
  --generic map(
  --  g_profile                               => "medium_icache_debug"
  --) -- Including JTAG and I-cache (no divide)
  --port map(
  --  clk_sys_i                               => clk_sys,
  --  rst_n_i                                 => lm32_rstn,
  --  irq_i                                   => lm32_interrupt,
  --  dwb_o                                   => cbar_slave_i(0), -- Data bus
  --  dwb_i                                   => cbar_slave_o(0),
  --  iwb_o                                   => cbar_slave_i(1), -- Instruction bus
  --  iwb_i                                   => cbar_slave_o(1)
  --);

  -- Interrupt '0' is Button(0).
  -- Interrupts 31 downto 1 are disabled

  --lm32_interrupt <= (0 => not buttons_i(0), others => '0');

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

--  cmp_xwb_bpm_pcie_a7 : xwb_bpm_pcie_a7
--  generic map (
--    g_ma_interface_mode                       => PIPELINED,
--    g_ma_address_granularity                  => BYTE,
--    g_ext_rst_pin                             => false,
--    g_sim_bypass_init_cal                     => "OFF"
--  )
--  port map (
--    -- DDR3 memory pins
--    ddr3_dq_b                                 => ddr3_dq_b,
--    ddr3_dqs_p_b                              => ddr3_dqs_p_b,
--    ddr3_dqs_n_b                              => ddr3_dqs_n_b,
--    ddr3_addr_o                               => ddr3_addr_o,
--    ddr3_ba_o                                 => ddr3_ba_o,
--    ddr3_cs_n_o                               => ddr3_cs_n_o,
--    ddr3_ras_n_o                              => ddr3_ras_n_o,
--    ddr3_cas_n_o                              => ddr3_cas_n_o,
--    ddr3_we_n_o                               => ddr3_we_n_o,
--    ddr3_reset_n_o                            => ddr3_reset_n_o,
--    ddr3_ck_p_o                               => ddr3_ck_p_o,
--    ddr3_ck_n_o                               => ddr3_ck_n_o,
--    ddr3_cke_o                                => ddr3_cke_o,
--    ddr3_dm_o                                 => ddr3_dm_o,
--    ddr3_odt_o                                => ddr3_odt_o,

--    -- PCIe transceivers
--    pci_exp_rxp_i                             => pci_exp_rxp_i,
--    pci_exp_rxn_i                             => pci_exp_rxn_i,
--    pci_exp_txp_o                             => pci_exp_txp_o,
--    pci_exp_txn_o                             => pci_exp_txn_o,

--    -- Necessity signals
--    ddr_clk_p_i                               => clk_200mhz,   --200 MHz DDR core clock (connect through BUFG or PLL)
--    ddr_clk_n_i                               => '0',          --200 MHz DDR core clock (connect through BUFG or PLL)
--    pcie_clk_p_i                              => pcie_clk_p_i, --100 MHz PCIe Clock (connect directly to input pin)
--    pcie_clk_n_i                              => pcie_clk_n_i, --100 MHz PCIe Clock
--    pcie_rst_n_i                              => clk_sys_rstn, -- PCIe core reset

--    -- DDR memory controller interface --
--    ddr_core_rst_i                            => clk_sys_rst,
--    memc_ui_clk_o                             => memc_ui_clk,
--    memc_ui_rst_o                             => memc_ui_rst,
--    memc_cmd_rdy_o                            => memc_cmd_rdy,
--    memc_cmd_en_i                             => memc_cmd_en,
--    memc_cmd_instr_i                          => memc_cmd_instr,
--    memc_cmd_addr_i                           => memc_cmd_addr_resized,
--    memc_wr_en_i                              => memc_wr_en,
--    memc_wr_end_i                             => memc_wr_end,
--    memc_wr_mask_i                            => memc_wr_mask,
--    memc_wr_data_i                            => memc_wr_data,
--    memc_wr_rdy_o                             => memc_wr_rdy,
--    memc_rd_data_o                            => memc_rd_data,
--    memc_rd_valid_o                           => memc_rd_valid,
--    ---- memory arbiter interface
--    memarb_acc_req_i                          => memarb_acc_req,
--    memarb_acc_gnt_o                          => memarb_acc_gnt,

--    -- Wishbone interface --
--    wb_clk_i                                  => clk_sys,
--    wb_rst_i                                  => clk_sys_rst,
--    wb_ma_i                                   => cbar_slave_o(c_ma_pcie_id),
--    wb_ma_o                                   => cbar_slave_i(c_ma_pcie_id),
--    -- Additional exported signals for instantiation
--    wb_ma_pcie_rst_o                          => wb_ma_pcie_rst,

--    -- Debug signals
--    dbg_app_addr_o                            => dbg_app_addr,
--    dbg_app_cmd_o                             => dbg_app_cmd,
--    dbg_app_en_o                              => dbg_app_en,
--    dbg_app_wdf_data_o                        => dbg_app_wdf_data,
--    dbg_app_wdf_end_o                         => dbg_app_wdf_end,
--    dbg_app_wdf_wren_o                        => dbg_app_wdf_wren,
--    dbg_app_wdf_mask_o                        => dbg_app_wdf_mask,
--    dbg_app_rd_data_o                         => dbg_app_rd_data,
--    dbg_app_rd_data_end_o                     => dbg_app_rd_data_end,
--    dbg_app_rd_data_valid_o                   => dbg_app_rd_data_valid,
--    dbg_app_rdy_o                             => dbg_app_rdy,
--    dbg_app_wdf_rdy_o                         => dbg_app_wdf_rdy,
--    dbg_ddr_ui_clk_o                          => dbg_ddr_ui_clk,
--    dbg_ddr_ui_reset_o                        => dbg_ddr_ui_reset,

--    dbg_arb_req_o                             => dbg_arb_req,
--    dbg_arb_gnt_o                             => dbg_arb_gnt
--  );

  wb_ma_pcie_rstn                             <= not wb_ma_pcie_rst;

  ----------------------------------
--  --         RS232 Core            --
--  ----------------------------------
--  cmp_xwb_rs232_syscon : xwb_rs232_syscon
--  generic map (
--    g_ma_interface_mode                       => PIPELINED,
--    g_ma_address_granularity                  => BYTE
--  )
--  port map(
--    -- WISHBONE common
--    wb_clk_i                                  => clk_sys,
--    wb_rstn_i                                 => '1', -- No need for resetting the controller

--    -- External ports
--    rs232_rxd_i                               => rs232_rxd_i,
--    rs232_txd_o                               => rs232_txd_o,

--    -- Reset to FPGA logic
--    rstn_o                                    => rs232_rstn,

--    -- WISHBONE master
--    wb_master_i                               => cbar_slave_o(c_ma_rs232_syscon_id),
--    wb_master_o                               => cbar_slave_i(c_ma_rs232_syscon_id)
--  );

  ----------------------------------------------------------------------
  --                            SYS DPRAM                             --
  ----------------------------------------------------------------------
  -- Generic System DPRAM
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
    
    
--    slave2_i                                => cbar_master_o(c_slv_dpram_sys_port1_id),
--    slave2_o                                => cbar_master_i(c_slv_dpram_sys_port1_id)
  );

  ----------------------------------------------------------------------
  --                      FMC 130M_4CH 1 Core                         --
  ----------------------------------------------------------------------

--  cmp1_xwb_fmc130m_4ch : xwb_fmc130m_4ch
--  generic map(
--    g_fpga_device                           => "7SERIES",
--    g_delay_type                            => "VAR_LOAD",
--    g_interface_mode                        => PIPELINED,
--    g_address_granularity                   => BYTE,
--    g_with_extra_wb_reg	                    => true,
--    --g_adc_clk_period_values                 => default_adc_clk_period_values,
--    g_adc_clk_period_values                 => (8.88, 8.88, 8.88, 8.88),
--    --g_use_clk_chains                        => default_clk_use_chain,
--    -- using clock1 from fmc130m_4ch (CLK2_ M2C_P, CLK2_ M2C_M pair)
--    -- using clock0 from fmc130m_4ch.
--    -- BUFIO can drive half-bank only, not the full IO bank
--    g_use_clk_chains                        => "1111",
--    g_with_bufio_clk_chains                 => "0000",
--    g_with_bufr_clk_chains                  => "1111",
--    g_with_idelayctrl                       => false,
--    --g_with_idelayctrl                       => true,
--    g_use_data_chains                       => "1111",
--    --g_map_clk_data_chains                   => (-1,-1,-1,-1),
--    -- Clock 1 is the adc reference clock
--    g_ref_clk                               => c_adc_ref_clk,
--    g_packet_size                           => 32,
--    g_sim                                   => 0
--  )
--  port map(
--    sys_clk_i                               => clk_sys,
--    sys_rst_n_i                             => clk_sys_rstn,
--    sys_clk_200Mhz_i                        => clk_200mhz,

--    -----------------------------
--    -- Wishbone Control Interface signals
--    -----------------------------
--    wb_slv_i                                => cbar_master_o(c_slv_fmc130m_4ch_1_id),
--    wb_slv_o                                => cbar_master_i(c_slv_fmc130m_4ch_1_id),

--    -----------------------------
--    -- External ports
--    -----------------------------

--    -- ADC LTC2208 interface
--    fmc_adc_pga_o                           => fmc1_adc_pga_o,
--    fmc_adc_shdn_o                          => fmc1_adc_shdn_o,
--    fmc_adc_dith_o                          => fmc1_adc_dith_o,
--    fmc_adc_rand_o                          => fmc1_adc_rand_o,

--    -- ADC0 LTC2208
--    fmc_adc0_clk_i                          => fmc1_adc0_clk_i,
--    fmc_adc0_data_i                         => fmc1_adc0_data_i,
--    fmc_adc0_of_i                           => fmc1_adc0_of_i,

--    -- ADC1 LTC2208
--    fmc_adc1_clk_i                          => fmc1_adc1_clk_i,
--    fmc_adc1_data_i                         => fmc1_adc1_data_i,
--    fmc_adc1_of_i                           => fmc1_adc1_of_i,

--    -- ADC2 LTC2208
--    fmc_adc2_clk_i                          => fmc1_adc2_clk_i,
--    fmc_adc2_data_i                         => fmc1_adc2_data_i,
--    fmc_adc2_of_i                           => fmc1_adc2_of_i,

--    -- ADC3 LTC2208
--    fmc_adc3_clk_i                          => fmc1_adc3_clk_i,
--    fmc_adc3_data_i                         => fmc1_adc3_data_i,
--    fmc_adc3_of_i                           => fmc1_adc3_of_i,

--    -- FMC General Status
--    --fmc_prsnt_i                             => fmc1_prsnt_i,
--    --fmc_pg_m2c_i                            => fmc1_pg_m2c_i,
--    fmc_prsnt_i                             => '0', -- Connected to the CPU
--    fmc_pg_m2c_i                            => '0', -- Connected to the CPU

--    -- Trigger
--    fmc_trig_dir_o                          => fmc1_trig_dir_o,
--    fmc_trig_term_o                         => fmc1_trig_term_o,
--    fmc_trig_val_p_b                        => fmc1_trig_val_p_b,
--    fmc_trig_val_n_b                        => fmc1_trig_val_n_b,

--    -- Si571 clock gen
--    si571_scl_pad_b                         => fmc1_si571_scl_pad_b,
--    si571_sda_pad_b                         => fmc1_si571_sda_pad_b,
--    fmc_si571_oe_o                          => fmc1_si571_oe_o,

--    -- AD9510 clock distribution PLL
--    spi_ad9510_cs_o                         => fmc1_spi_ad9510_cs_o,
--    spi_ad9510_sclk_o                       => fmc1_spi_ad9510_sclk_o,
--    spi_ad9510_mosi_o                       => fmc1_spi_ad9510_mosi_o,
--    spi_ad9510_miso_i                       => fmc1_spi_ad9510_miso_i,

--    fmc_pll_function_o                      => fmc1_pll_function_o,
--    fmc_pll_status_i                        => fmc1_pll_status_i,

--    -- AD9510 clock copy
--    fmc_fpga_clk_p_i                        => fmc1_fpga_clk_p_i,
--    fmc_fpga_clk_n_i                        => fmc1_fpga_clk_n_i,

--    -- Clock reference selection (TS3USB221)
--    fmc_clk_sel_o                           => fmc1_clk_sel_o,

--    -- EEPROM (Connected to the CPU)
--    --eeprom_scl_pad_b                        => eeprom_scl_pad_b,
--    --eeprom_sda_pad_b                        => eeprom_sda_pad_b,
--    eeprom_scl_pad_b                       => fmc1_eeprom_scl_pad_b,
--    eeprom_sda_pad_b                       => fmc1_eeprom_sda_pad_b,

--    -- Temperature monitor
--    -- LM75AIMM
--    lm75_scl_pad_b                          => fmc1_lm75_scl_pad_b,
--    lm75_sda_pad_b                          => fmc1_lm75_sda_pad_b,

--    fmc_lm75_temp_alarm_i                   => fmc1_lm75_temp_alarm_i,

--    -- FMC LEDs
--    fmc_led1_o                              => fmc1_led1_int,
--    fmc_led2_o                              => fmc1_led2_int,
--    fmc_led3_o                              => fmc1_led3_int,

--    -----------------------------
--    -- Optional external reference clock ports
--    -----------------------------
--    fmc_ext_ref_clk_i                       => '0',
--    fmc_ext_ref_clk2x_i                     => '0',
--    fmc_ext_ref_mmcm_locked_i               => '0',

--    -----------------------------
--    -- ADC output signals. Continuous flow
--    -----------------------------
--    adc_clk_o                               => fmc1_clk,
--    adc_clk2x_o                             => fmc1_clk2x,
--    adc_rst_n_o                             => fmc1_rst_n,
--    adc_rst2x_n_o                           => fmc1_rst2x_n,
--    adc_data_o                              => fmc1_data,
--    adc_data_valid_o                        => fmc1_data_valid,

--    -----------------------------
--    -- General ADC output signals and status
--    -----------------------------
--    -- Trigger to other FPGA logic
--    trig_hw_o                               => open,
--    trig_hw_i                               => dsp1_clk_rffe_swap,  -- To FMC1 Trigger Front Panel

--    -- General board status
--    fmc_mmcm_lock_o                         => fmc1_mmcm_lock_int,
--    fmc_pll_status_o                        => fmc1_pll_status_int,

--    -----------------------------
--    -- Wishbone Streaming Interface Source
--    -----------------------------
--    wbs_source_i                            => wbs_fmc1_in_array,
--    wbs_source_o                            => wbs_fmc1_out_array,

--    adc_dly_debug_o                         => fmc1_adc_dly_debug_int,

--    fifo_debug_valid_o                      => fmc1_debug_valid_int,
--    fifo_debug_full_o                       => fmc1_debug_full_int,
--    fifo_debug_empty_o                      => fmc1_debug_empty_int
--  );

--  gen_wbs1_dummy_signals : for i in 0 to c_num_adc_channels-1 generate
--    wbs_fmc1_in_array(i)                    <= cc_dummy_src_com_in;
--  end generate;

  --fmc1_mmcm_lock_led_o                       <= fmc1_mmcm_lock_int;
  --fmc1_pll_status_led_o                      <= fmc1_pll_status_int;

  fmc1_led1_o                                <= fmc1_led1_int;
  fmc1_led2_o                                <= fmc1_led2_int;
  fmc1_led3_o                                <= fmc1_led3_int;

  fmc1_adc_data_ch0                          <= fmc1_data(c_adc_data_ch0_msb downto c_adc_data_ch0_lsb);
  fmc1_adc_data_ch1                          <= fmc1_data(c_adc_data_ch1_msb downto c_adc_data_ch1_lsb);
  fmc1_adc_data_ch2                          <= fmc1_data(c_adc_data_ch2_msb downto c_adc_data_ch2_lsb);
  fmc1_adc_data_ch3                          <= fmc1_data(c_adc_data_ch3_msb downto c_adc_data_ch3_lsb);

  fs1_clk                                    <= fmc1_clk(c_adc_ref_clk);
  fs1_rstn                                   <= fmc1_rst_n(c_adc_ref_clk);
  fs1_clk2x                                  <= fmc1_clk2x(c_adc_ref_clk);
  fs1_rst2xn                                 <= fmc1_rst2x_n(c_adc_ref_clk);

  -- Debug clock for chipscope
  fs_clk_dbg                                 <= fs1_clk;
  fs_rstn_dbg                                <= fs1_rstn;
  fs_clk2x_dbg                               <= fs1_clk2x;
  fs_rst2xn_dbg                              <= fs1_rst2xn;

--  ----------------------------------------------------------------------
--  --                      FMC 130M_4CH 2 Core                         --
--  ----------------------------------------------------------------------

--  cmp2_xwb_fmc130m_4ch : xwb_fmc130m_4ch
--  generic map(
--    g_fpga_device                           => "7SERIES",
--    g_delay_type                            => "VAR_LOAD",
--    g_interface_mode                        => PIPELINED,
--    g_address_granularity                   => BYTE,
--    g_with_extra_wb_reg                     => true,
--    --g_adc_clk_period_values                 => default_adc_clk_period_values,
--    g_adc_clk_period_values                 => (8.88, 8.88, 8.88, 8.88),
--    --g_use_clk_chains                        => default_clk_use_chain,
--    -- using clock1 from fmc130m_4ch (CLK2_ M2C_P, CLK2_ M2C_M pair)
--    -- using clock0 from fmc130m_4ch.
--    -- BUFIO can drive half-bank only, not the full IO bank
--    g_use_clk_chains                        => "1111",
--    g_with_bufio_clk_chains                 => "0000",
--    g_with_bufr_clk_chains                  => "1111",
--    g_with_idelayctrl                       => false,
--    --g_with_idelayctrl                       => true,
--    g_use_data_chains                       => "1111",
--    --g_map_clk_data_chains                   => (-1,-1,-1,-1),
--    -- Clock 1 is the adc reference clock
--    g_ref_clk                               => c_adc_ref_clk,
--    g_packet_size                           => 32,
--    g_sim                                   => 0
--  )
--  port map(
--    sys_clk_i                               => clk_sys,
--    sys_rst_n_i                             => clk_sys_rstn,
--    sys_clk_200Mhz_i                        => clk_200mhz,

--    -----------------------------
--    -- Wishbone Control Interface signals
--    -----------------------------
--    wb_slv_i                                => cbar_master_o(c_slv_fmc130m_4ch_2_id),
--    wb_slv_o                                => cbar_master_i(c_slv_fmc130m_4ch_2_id),

--    -----------------------------
--    -- External ports
--    -----------------------------

--    -- ADC LTC2208 interface
--    fmc_adc_pga_o                           => fmc2_adc_pga_o,
--    fmc_adc_shdn_o                          => fmc2_adc_shdn_o,
--    fmc_adc_dith_o                          => fmc2_adc_dith_o,
--    fmc_adc_rand_o                          => fmc2_adc_rand_o,

--    -- ADC0 LTC2208
--    fmc_adc0_clk_i                          => fmc2_adc0_clk_i,
--    fmc_adc0_data_i                         => fmc2_adc0_data_i,
--    fmc_adc0_of_i                           => fmc2_adc0_of_i,

--    -- ADC1 LTC2208
--    fmc_adc1_clk_i                          => fmc2_adc1_clk_i,
--    fmc_adc1_data_i                         => fmc2_adc1_data_i,
--    fmc_adc1_of_i                           => fmc2_adc1_of_i,

--    -- ADC2 LTC2208
--    fmc_adc2_clk_i                          => fmc2_adc2_clk_i,
--    fmc_adc2_data_i                         => fmc2_adc2_data_i,
--    fmc_adc2_of_i                           => fmc2_adc2_of_i,

--    -- ADC3 LTC2208
--    fmc_adc3_clk_i                          => fmc2_adc3_clk_i,
--    fmc_adc3_data_i                         => fmc2_adc3_data_i,
--    fmc_adc3_of_i                           => fmc2_adc3_of_i,

--    -- FMC General Status
--    --fmc_prsnt_i                             => fmc2_prsnt_i,
--    --fmc_pg_m2c_i                            => fmc2_pg_m2c_i,
--    fmc_prsnt_i                             => '0', -- Connected to the CPU
--    fmc_pg_m2c_i                            => '0', -- Connected to the CPU

--    -- Trigger
--    fmc_trig_dir_o                          => fmc2_trig_dir_o,
--    fmc_trig_term_o                         => fmc2_trig_term_o,
--    fmc_trig_val_p_b                        => fmc2_trig_val_p_b,
--    fmc_trig_val_n_b                        => fmc2_trig_val_n_b,

--    -- Si571 clock gen
--    si571_scl_pad_b                         => fmc2_si571_scl_pad_b,
--    si571_sda_pad_b                         => fmc2_si571_sda_pad_b,
--    fmc_si571_oe_o                          => fmc2_si571_oe_o,

--    -- AD9510 clock distribution PLL
--    spi_ad9510_cs_o                         => fmc2_spi_ad9510_cs_o,
--    spi_ad9510_sclk_o                       => fmc2_spi_ad9510_sclk_o,
--    spi_ad9510_mosi_o                       => fmc2_spi_ad9510_mosi_o,
--    spi_ad9510_miso_i                       => fmc2_spi_ad9510_miso_i,

--    fmc_pll_function_o                      => fmc2_pll_function_o,
--    fmc_pll_status_i                        => fmc2_pll_status_i,

--    -- AD9510 clock copy
--    fmc_fpga_clk_p_i                        => fmc2_fpga_clk_p_i,
--    fmc_fpga_clk_n_i                        => fmc2_fpga_clk_n_i,

--    -- Clock reference selection (TS3USB221)
--    fmc_clk_sel_o                           => fmc2_clk_sel_o,

--    -- EEPROM (Connected to the CPU)
--    --eeprom_scl_pad_b                        => eeprom_scl_pad_b,
--    --eeprom_sda_pad_b                        => eeprom_sda_pad_b,
--    eeprom_scl_pad_b                        => open,
--    eeprom_sda_pad_b                        => open,

--    -- Temperature monitor
--    -- LM75AIMM
--    lm75_scl_pad_b                          => fmc2_lm75_scl_pad_b,
--    lm75_sda_pad_b                          => fmc2_lm75_sda_pad_b,

--    fmc_lm75_temp_alarm_i                   => fmc2_lm75_temp_alarm_i,

--    -- FMC LEDs
--    fmc_led1_o                              => fmc2_led1_int,
--    fmc_led2_o                              => fmc2_led2_int,
--    fmc_led3_o                              => fmc2_led3_int,

--    -----------------------------
--    -- Optional external reference clock ports
--    -----------------------------
--    fmc_ext_ref_clk_i                       => '0',
--    fmc_ext_ref_clk2x_i                     => '0',
--    fmc_ext_ref_mmcm_locked_i               => '0',

--    -----------------------------
--    -- ADC output signals. Continuous flow
--    -----------------------------
--    adc_clk_o                               => fmc2_clk,
--    adc_clk2x_o                             => fmc2_clk2x,
--    adc_rst_n_o                             => fmc2_rst_n,
--    adc_rst2x_n_o                           => fmc2_rst2x_n,
--    adc_data_o                              => fmc2_data,
--    adc_data_valid_o                        => fmc2_data_valid,

--    -----------------------------
--    -- General ADC output signals and status
--    -----------------------------
--    -- Trigger to other FPGA logic
--    trig_hw_o                               => open,
--    trig_hw_i                               => dsp2_clk_rffe_swap,  -- To FMC2 Trigger Front Panel

--    -- General board status
--    fmc_mmcm_lock_o                         => fmc2_mmcm_lock_int,
--    fmc_pll_status_o                        => fmc2_pll_status_int,

--    -----------------------------
--    -- Wishbone Streaming Interface Source
--    -----------------------------
--    wbs_source_i                            => wbs_fmc2_in_array,
--    wbs_source_o                            => wbs_fmc2_out_array,

--    adc_dly_debug_o                         => fmc2_adc_dly_debug_int,

--    fifo_debug_valid_o                      => fmc2_debug_valid_int,
--    fifo_debug_full_o                       => fmc2_debug_full_int,
--    fifo_debug_empty_o                      => fmc2_debug_empty_int
--  );

--  gen_wbs2_dummy_signals : for i in 0 to c_num_adc_channels-1 generate
--    wbs_fmc2_in_array(i)                    <= cc_dummy_src_com_in;
--  end generate;

  -- Only FMC 1 is connected for now
  --fmc2_mmcm_lock_led_o                       <= fmc2_mmcm_lock_int;
  --fmc2_pll_status_led_o                      <= fmc2_pll_status_int;

  fmc2_led1_o                                <= fmc2_led1_int;
  fmc2_led2_o                                <= fmc2_led2_int;
  fmc2_led3_o                                <= fmc2_led3_int;

  fmc2_adc_data_ch0                          <= fmc2_data(c_adc_data_ch0_msb downto c_adc_data_ch0_lsb);
  fmc2_adc_data_ch1                          <= fmc2_data(c_adc_data_ch1_msb downto c_adc_data_ch1_lsb);
  fmc2_adc_data_ch2                          <= fmc2_data(c_adc_data_ch2_msb downto c_adc_data_ch2_lsb);
  fmc2_adc_data_ch3                          <= fmc2_data(c_adc_data_ch3_msb downto c_adc_data_ch3_lsb);

  fs2_clk                                    <= fmc2_clk(c_adc_ref_clk);
  fs2_rstn                                   <= fmc2_rst_n(c_adc_ref_clk);
  fs2_clk2x                                  <= fmc2_clk2x(c_adc_ref_clk);
  fs2_rst2xn                                 <= fmc2_rst2x_n(c_adc_ref_clk);

  ----------------------------------------------------------------------
  --                      DSP Chain 1 Core                            --
  ----------------------------------------------------------------------

--  cmp1_xwb_position_calc_core : xwb_position_calc_core
--  generic map (
--    g_interface_mode                        => PIPELINED,
--    g_address_granularity                   => BYTE,
--    g_with_extra_wb_reg                     => true,

--    -- input sizes
--    g_input_width                           => c_pos_calc_input_width,
--    g_mixed_width                           => c_pos_calc_mixed_width,
--    g_adc_ratio                             => c_pos_calc_adc_ratio,

--    -- mixer
--    g_dds_width                             => c_pos_calc_dds_width,
--    g_dds_points                            => c_pos_calc_dds_points,
--    g_sin_file                              => c_pos_calc_sin_file,
--    g_cos_file                              => c_pos_calc_cos_file,

--    -- CIC setup
--    g_tbt_cic_delay                         => c_pos_calc_tbt_cic_delay,
--    g_tbt_cic_stages                        => c_pos_calc_tbt_cic_stages,
--    g_tbt_ratio                             => c_pos_calc_tbt_ratio,
--    g_tbt_decim_width                       => c_pos_calc_tbt_decim_width,

--    g_fofb_cic_delay                        => c_pos_calc_fofb_cic_delay,
--    g_fofb_cic_stages                       => c_pos_calc_fofb_cic_stages,
--    g_fofb_ratio                            => c_pos_calc_fofb_ratio,
--    g_fofb_decim_width                      => c_pos_calc_fofb_decim_width,

--    g_monit1_cic_delay                      => c_pos_calc_monit1_cic_delay,
--    g_monit1_cic_stages                     => c_pos_calc_monit1_cic_stages,
--    g_monit1_ratio                          => c_pos_calc_monit1_ratio,

--    g_monit2_cic_delay                      => c_pos_calc_monit2_cic_delay,
--    g_monit2_cic_stages                     => c_pos_calc_monit2_cic_stages,
--    g_monit2_ratio                          => c_pos_calc_monit2_ratio,

--    g_monit_decim_width                     => c_pos_calc_monit_decim_width,

--    -- width of K constants
--    g_k_width                               => c_pos_calc_k_width,

--    --width for IQ output
--    g_IQ_width                              => c_pos_calc_IQ_width
--  )
--  port map (
--    rst_n_i                                 => clk_sys_rstn,
--    clk_i                                   => clk_sys,  -- Wishbone clock
--    fs_rst_n_i                              => fs1_rstn,
--    fs_rst2x_n_i                            => fs1_rst2xn,
--    fs_clk_i                                => fs1_clk,
--    fs_clk2x_i                              => fs1_clk2x,

--    -----------------------------
--    -- Wishbone signals
--    -----------------------------
--    wb_slv_i                                => cbar_master_o(c_slv_pos_calc_1_id),
--    wb_slv_o                                => cbar_master_i(c_slv_pos_calc_1_id),

--    -----------------------------
--    -- Raw ADC signals
--    -----------------------------
--    adc_ch0_i                               => fmc1_adc_data_ch0,
--    adc_ch1_i                               => fmc1_adc_data_ch1,
--    adc_ch2_i                               => fmc1_adc_data_ch2,
--    adc_ch3_i                               => fmc1_adc_data_ch3,

--    -----------------------------
--    -- Position calculation at various rates
--    -----------------------------
--    adc_ch0_swap_o                          => dsp1_adc_ch0_data,
--    adc_ch1_swap_o                          => dsp1_adc_ch1_data,
--    adc_ch2_swap_o                          => dsp1_adc_ch2_data,
--    adc_ch3_swap_o                          => dsp1_adc_ch3_data,

--    mix_ch0_i_o                             => dsp1_mixi_ch0,
--    mix_ch0_q_o                             => dsp1_mixq_ch0,
--    mix_ch1_i_o                             => dsp1_mixi_ch1,
--    mix_ch1_q_o                             => dsp1_mixq_ch1,
--    mix_ch2_i_o                             => dsp1_mixi_ch2,
--    mix_ch2_q_o                             => dsp1_mixq_ch2,
--    mix_ch3_i_o                             => dsp1_mixi_ch3,
--    mix_ch3_q_o                             => dsp1_mixq_ch3,
--    mix_valid_o                             => dsp1_mix_valid,

--    tbt_decim_ch0_i_o                       => dsp1_tbtdecimi_ch0,
--    tbt_decim_ch0_q_o                       => dsp1_tbtdecimq_ch0,
--    tbt_decim_ch1_i_o                       => dsp1_tbtdecimi_ch1,
--    tbt_decim_ch1_q_o                       => dsp1_tbtdecimq_ch1,
--    tbt_decim_ch2_i_o                       => dsp1_tbtdecimi_ch2,
--    tbt_decim_ch2_q_o                       => dsp1_tbtdecimq_ch2,
--    tbt_decim_ch3_i_o                       => dsp1_tbtdecimi_ch3,
--    tbt_decim_ch3_q_o                       => dsp1_tbtdecimq_ch3,
--    tbt_decim_valid_o                       => dsp1_tbtdecim_valid,

--    tbt_amp_ch0_o                           => dsp1_tbt_amp_ch0,
--    tbt_amp_ch1_o                           => dsp1_tbt_amp_ch1,
--    tbt_amp_ch2_o                           => dsp1_tbt_amp_ch2,
--    tbt_amp_ch3_o                           => dsp1_tbt_amp_ch3,
--    tbt_amp_valid_o                         => dsp1_tbt_amp_valid,

--    tbt_pha_ch0_o                           => dsp1_tbt_pha_ch0,
--    tbt_pha_ch1_o                           => dsp1_tbt_pha_ch1,
--    tbt_pha_ch2_o                           => dsp1_tbt_pha_ch2,
--    tbt_pha_ch3_o                           => dsp1_tbt_pha_ch3,
--    tbt_pha_valid_o                         => dsp1_tbt_pha_valid,

--    fofb_decim_ch0_i_o                      => dsp1_fofbdecimi_ch0,
--    fofb_decim_ch0_q_o                      => dsp1_fofbdecimq_ch0,
--    fofb_decim_ch1_i_o                      => dsp1_fofbdecimi_ch1,
--    fofb_decim_ch1_q_o                      => dsp1_fofbdecimq_ch1,
--    fofb_decim_ch2_i_o                      => dsp1_fofbdecimi_ch2,
--    fofb_decim_ch2_q_o                      => dsp1_fofbdecimq_ch2,
--    fofb_decim_ch3_i_o                      => dsp1_fofbdecimi_ch3,
--    fofb_decim_ch3_q_o                      => dsp1_fofbdecimq_ch3,
--    fofb_decim_valid_o                      => dsp1_fofbdecim_valid,

--    fofb_amp_ch0_o                          => dsp1_fofb_amp_ch0,
--    fofb_amp_ch1_o                          => dsp1_fofb_amp_ch1,
--    fofb_amp_ch2_o                          => dsp1_fofb_amp_ch2,
--    fofb_amp_ch3_o                          => dsp1_fofb_amp_ch3,
--    fofb_amp_valid_o                        => dsp1_fofb_amp_valid,

--    fofb_pha_ch0_o                          => dsp1_fofb_pha_ch0,
--    fofb_pha_ch1_o                          => dsp1_fofb_pha_ch1,
--    fofb_pha_ch2_o                          => dsp1_fofb_pha_ch2,
--    fofb_pha_ch3_o                          => dsp1_fofb_pha_ch3,
--    fofb_pha_valid_o                        => dsp1_fofb_pha_valid,

--    monit_amp_ch0_o                         => dsp1_monit_amp_ch0,
--    monit_amp_ch1_o                         => dsp1_monit_amp_ch1,
--    monit_amp_ch2_o                         => dsp1_monit_amp_ch2,
--    monit_amp_ch3_o                         => dsp1_monit_amp_ch3,
--    monit_amp_valid_o                       => dsp1_monit_amp_valid,

--    pos_x_tbt_o                             => dsp1_pos_x_tbt,
--    pos_y_tbt_o                             => dsp1_pos_y_tbt,
--    pos_q_tbt_o                             => dsp1_pos_q_tbt,
--    pos_sum_tbt_o                           => dsp1_pos_sum_tbt,
--    pos_tbt_valid_o                         => dsp1_pos_tbt_valid,

--    pos_x_fofb_o                            => dsp1_pos_x_fofb,
--    pos_y_fofb_o                            => dsp1_pos_y_fofb,
--    pos_q_fofb_o                            => dsp1_pos_q_fofb,
--    pos_sum_fofb_o                          => dsp1_pos_sum_fofb,
--    pos_fofb_valid_o                        => dsp1_pos_fofb_valid,

--    pos_x_monit_o                           => dsp1_pos_x_monit,
--    pos_y_monit_o                           => dsp1_pos_y_monit,
--    pos_q_monit_o                           => dsp1_pos_q_monit,
--    pos_sum_monit_o                         => dsp1_pos_sum_monit,
--    pos_monit_valid_o                       => dsp1_pos_monit_valid,

--    -----------------------------
--    -- Output to RFFE board
--    -----------------------------
--    clk_swap_o                              => dsp1_clk_rffe_swap,
--    flag1_o                                 => dsp1_flag1_int,
--    flag2_o                                 => dsp1_flag2_int,
--    ctrl1_o                                 => open,
--    ctrl2_o                                 => open,

--    -----------------------------
--    -- Clock drivers for various rates
--    -----------------------------
--    ce_adc_o                                => open,
--    ce_tbt_o                                => open,
--    ce_monit_o                              => open,
--    ce_fofb_o                               => open,

--    dbg_cur_address_o                       => dsp1_dbg_cur_address,
--    dbg_adc_ch0_cond_o                      => dsp1_dbg_adc_ch0_cond,
--    dbg_adc_ch1_cond_o                      => dsp1_dbg_adc_ch1_cond,
--    dbg_adc_ch2_cond_o                      => dsp1_dbg_adc_ch2_cond,
--    dbg_adc_ch3_cond_o                      => dsp1_dbg_adc_ch3_cond
--  );

--  --flag1_o                                   <= dsp1_flag1_int;
--  --flag2_o                                   <= dsp1_flag2_int;
--  ---- There is no clk_swap2x_o, so we just output the same as clk_swap_o
--  --clk_swap_o                                <= dsp1_clk_rffe_swap;
--  --clk_swap2x_o                              <= dsp1_clk_rffe_swap;

--  ----------------------------------------------------------------------
--  --                      DSP Chain 2 Core                            --
--  ----------------------------------------------------------------------

--  cmp2_xwb_position_calc_core : xwb_position_calc_core
--  generic map (
--    g_interface_mode                        => PIPELINED,
--    g_address_granularity                   => BYTE,
--    g_with_extra_wb_reg                     => true,

--    -- input sizes
--    g_input_width                           => c_pos_calc_input_width,
--    g_mixed_width                           => c_pos_calc_mixed_width,
--    g_adc_ratio                             => c_pos_calc_adc_ratio,

--    -- mixer
--    g_dds_width                             => c_pos_calc_dds_width,
--    g_dds_points                            => c_pos_calc_dds_points,
--    g_sin_file                              => c_pos_calc_sin_file,
--    g_cos_file                              => c_pos_calc_cos_file,

--    -- CIC setup
--    g_tbt_cic_delay                         => c_pos_calc_tbt_cic_delay,
--    g_tbt_cic_stages                        => c_pos_calc_tbt_cic_stages,
--    g_tbt_ratio                             => c_pos_calc_tbt_ratio,
--    g_tbt_decim_width                       => c_pos_calc_tbt_decim_width,

--    g_fofb_cic_delay                        => c_pos_calc_fofb_cic_delay,
--    g_fofb_cic_stages                       => c_pos_calc_fofb_cic_stages,
--    g_fofb_ratio                            => c_pos_calc_fofb_ratio,
--    g_fofb_decim_width                      => c_pos_calc_fofb_decim_width,

--    g_monit1_cic_delay                      => c_pos_calc_monit1_cic_delay,
--    g_monit1_cic_stages                     => c_pos_calc_monit1_cic_stages,
--    g_monit1_ratio                          => c_pos_calc_monit1_ratio,

--    g_monit2_cic_delay                      => c_pos_calc_monit2_cic_delay,
--    g_monit2_cic_stages                     => c_pos_calc_monit2_cic_stages,
--    g_monit2_ratio                          => c_pos_calc_monit2_ratio,

--    g_monit_decim_width                     => c_pos_calc_monit_decim_width,

--    -- width of K constants
--    g_k_width                               => c_pos_calc_k_width,

--    --width for IQ output
--    g_IQ_width                              => c_pos_calc_IQ_width
--  )
--  port map (
--    rst_n_i                                 => clk_sys_rstn,
--    clk_i                                   => clk_sys,  -- Wishbone clock
--    fs_rst_n_i                              => fs2_rstn,
--    fs_rst2x_n_i                            => fs2_rst2xn,
--    fs_clk_i                                => fs2_clk,
--    fs_clk2x_i                              => fs2_clk2x,

--    -----------------------------
--    -- Wishbone signals
--    -----------------------------
--    wb_slv_i                                => cbar_master_o(c_slv_pos_calc_2_id),
--    wb_slv_o                                => cbar_master_i(c_slv_pos_calc_2_id),

--    -----------------------------
--    -- Raw ADC signals
--    -----------------------------
--    adc_ch0_i                               => fmc2_adc_data_ch0,
--    adc_ch1_i                               => fmc2_adc_data_ch1,
--    adc_ch2_i                               => fmc2_adc_data_ch2,
--    adc_ch3_i                               => fmc2_adc_data_ch3,

--    -----------------------------
--    -- Position calculation at various rates
--    -----------------------------
--    adc_ch0_swap_o                          => dsp2_adc_ch0_data,
--    adc_ch1_swap_o                          => dsp2_adc_ch1_data,
--    adc_ch2_swap_o                          => dsp2_adc_ch2_data,
--    adc_ch3_swap_o                          => dsp2_adc_ch3_data,

--    mix_ch0_i_o                             => dsp2_mixi_ch0,
--    mix_ch0_q_o                             => dsp2_mixq_ch0,
--    mix_ch1_i_o                             => dsp2_mixi_ch1,
--    mix_ch1_q_o                             => dsp2_mixq_ch1,
--    mix_ch2_i_o                             => dsp2_mixi_ch2,
--    mix_ch2_q_o                             => dsp2_mixq_ch2,
--    mix_ch3_i_o                             => dsp2_mixi_ch3,
--    mix_ch3_q_o                             => dsp2_mixq_ch3,
--    mix_valid_o                             => dsp2_mix_valid,

--    tbt_decim_ch0_i_o                       => dsp2_tbtdecimi_ch0,
--    tbt_decim_ch0_q_o                       => dsp2_tbtdecimq_ch0,
--    tbt_decim_ch1_i_o                       => dsp2_tbtdecimi_ch1,
--    tbt_decim_ch1_q_o                       => dsp2_tbtdecimq_ch1,
--    tbt_decim_ch2_i_o                       => dsp2_tbtdecimi_ch2,
--    tbt_decim_ch2_q_o                       => dsp2_tbtdecimq_ch2,
--    tbt_decim_ch3_i_o                       => dsp2_tbtdecimi_ch3,
--    tbt_decim_ch3_q_o                       => dsp2_tbtdecimq_ch3,
--    tbt_decim_valid_o                       => dsp2_tbtdecim_valid,

--    tbt_amp_ch0_o                           => dsp2_tbt_amp_ch0,
--    tbt_amp_ch1_o                           => dsp2_tbt_amp_ch1,
--    tbt_amp_ch2_o                           => dsp2_tbt_amp_ch2,
--    tbt_amp_ch3_o                           => dsp2_tbt_amp_ch3,
--    tbt_amp_valid_o                         => dsp2_tbt_amp_valid,

--    tbt_pha_ch0_o                           => dsp2_tbt_pha_ch0,
--    tbt_pha_ch1_o                           => dsp2_tbt_pha_ch1,
--    tbt_pha_ch2_o                           => dsp2_tbt_pha_ch2,
--    tbt_pha_ch3_o                           => dsp2_tbt_pha_ch3,
--    tbt_pha_valid_o                         => dsp2_tbt_pha_valid,

--    fofb_decim_ch0_i_o                      => dsp2_fofbdecimi_ch0,
--    fofb_decim_ch0_q_o                      => dsp2_fofbdecimq_ch0,
--    fofb_decim_ch1_i_o                      => dsp2_fofbdecimi_ch1,
--    fofb_decim_ch1_q_o                      => dsp2_fofbdecimq_ch1,
--    fofb_decim_ch2_i_o                      => dsp2_fofbdecimi_ch2,
--    fofb_decim_ch2_q_o                      => dsp2_fofbdecimq_ch2,
--    fofb_decim_ch3_i_o                      => dsp2_fofbdecimi_ch3,
--    fofb_decim_ch3_q_o                      => dsp2_fofbdecimq_ch3,
--    fofb_decim_valid_o                      => dsp2_fofbdecim_valid,

--    fofb_amp_ch0_o                          => dsp2_fofb_amp_ch0,
--    fofb_amp_ch1_o                          => dsp2_fofb_amp_ch1,
--    fofb_amp_ch2_o                          => dsp2_fofb_amp_ch2,
--    fofb_amp_ch3_o                          => dsp2_fofb_amp_ch3,
--    fofb_amp_valid_o                        => dsp2_fofb_amp_valid,

--    fofb_pha_ch0_o                          => dsp2_fofb_pha_ch0,
--    fofb_pha_ch1_o                          => dsp2_fofb_pha_ch1,
--    fofb_pha_ch2_o                          => dsp2_fofb_pha_ch2,
--    fofb_pha_ch3_o                          => dsp2_fofb_pha_ch3,
--    fofb_pha_valid_o                        => dsp2_fofb_pha_valid,

--    monit_amp_ch0_o                         => dsp2_monit_amp_ch0,
--    monit_amp_ch1_o                         => dsp2_monit_amp_ch1,
--    monit_amp_ch2_o                         => dsp2_monit_amp_ch2,
--    monit_amp_ch3_o                         => dsp2_monit_amp_ch3,
--    monit_amp_valid_o                       => dsp2_monit_amp_valid,

--    pos_x_tbt_o                             => dsp2_pos_x_tbt,
--    pos_y_tbt_o                             => dsp2_pos_y_tbt,
--    pos_q_tbt_o                             => dsp2_pos_q_tbt,
--    pos_sum_tbt_o                           => dsp2_pos_sum_tbt,
--    pos_tbt_valid_o                         => dsp2_pos_tbt_valid,

--    pos_x_fofb_o                            => dsp2_pos_x_fofb,
--    pos_y_fofb_o                            => dsp2_pos_y_fofb,
--    pos_q_fofb_o                            => dsp2_pos_q_fofb,
--    pos_sum_fofb_o                          => dsp2_pos_sum_fofb,
--    pos_fofb_valid_o                        => dsp2_pos_fofb_valid,

--    pos_x_monit_o                           => dsp2_pos_x_monit,
--    pos_y_monit_o                           => dsp2_pos_y_monit,
--    pos_q_monit_o                           => dsp2_pos_q_monit,
--    pos_sum_monit_o                         => dsp2_pos_sum_monit,
--    pos_monit_valid_o                       => dsp2_pos_monit_valid,

--    -----------------------------
--    -- Output to RFFE board
--    -----------------------------
--    clk_swap_o                              => dsp2_clk_rffe_swap,
--    flag1_o                                 => dsp2_flag1_int,
--    flag2_o                                 => dsp2_flag2_int,
--    ctrl1_o                                 => open,
--    ctrl2_o                                 => open,

--    -----------------------------
--    -- Clock drivers for various rates
--    -----------------------------
--    ce_adc_o                                => open,
--    ce_tbt_o                                => open,
--    ce_monit_o                              => open,
--    ce_fofb_o                               => open,

--    dbg_cur_address_o                       => dsp2_dbg_cur_address,
--    dbg_adc_ch0_cond_o                      => dsp2_dbg_adc_ch0_cond,
--    dbg_adc_ch1_cond_o                      => dsp2_dbg_adc_ch1_cond,
--    dbg_adc_ch2_cond_o                      => dsp2_dbg_adc_ch2_cond,
--    dbg_adc_ch3_cond_o                      => dsp2_dbg_adc_ch3_cond
--  );

  -- FIXME: Only output DSP CHAIN 1 signals
  --flag1_o                                   <= dsp2_flag1_int;
  --flag2_o                                   <= dsp2_flag2_int;
  ---- There is no clk_swap2x_o, so we just output the same as clk_swap_o
  --clk_swap_o                                <= dsp2_clk_rffe_swap;
  --clk_swap2x_o                              <= dsp2_clk_rffe_swap;

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

cmp_fmc_5chttl_1_periph: fmc_dio5chttl
generic map (
    g_interface_mode        => PIPELINED,
    g_address_granularity   => BYTE,
    g_use_tristate          => true,

    g_num_io => 5,
    g_fmc_id => 1,
    g_fmc_map => afc_v2_FMC_pinmap
)
    Port map ( clk_i  => clk_sys,
           rst_n_i => clk_sys_rstn,
           
           port_fmc_in_i => fmc1_in,
           port_fmc_out_o => fmc1_out,
           port_fmc_io => fmc1_io,

           
           raw_i => fmc1_dio_raw_i,
           raw_o => fmc1_dio_raw_o,
           
           
           slave_i =>  cbar_master_o(c_slv_fmcdio5chttl_1_id),
           slave_o =>  cbar_master_i(c_slv_fmcdio5chttl_1_id)
           );

  fmc1_dio_raw_i <= (3 => s_tick, 2 =>s_trig, others => '0');
  mlvds_raw_out_i <= (0 => s_tick, 1 =>s_trig, others => '0');

  ----------------------------------------------------------------------
  --                      AFC Diagnostics                             --
  ----------------------------------------------------------------------

--  cmp_xwb_afc_diag : xwb_afc_diag
--  generic map(
--    g_interface_mode                          => PIPELINED,
--    g_address_granularity                     => BYTE
--  )
--  port map(
--    sys_clk_i                                 => clk_sys,
--    sys_rst_n_i                               => clk_sys_rstn,

--    -- Fast SPI clock. Same as Wishbone clock.
--    spi_clk_i                                 => clk_sys,

--    -----------------------------
--    -- Wishbone Control Interface signals
--    -----------------------------
--    wb_slv_i                                  => cbar_master_o(c_slv_afc_diag_id),
--    wb_slv_o                                  => cbar_master_i(c_slv_afc_diag_id),

--    dbg_spi_clk_o                             => dbg_spi_clk,
--    dbg_spi_valid_o                           => dbg_spi_valid,
--    dbg_en_o                                  => dbg_en,
--    dbg_addr_o                                => open,
--    dbg_serial_data_o                         => dbg_serial_data,
--    dbg_spi_data_o                            => open,

--    -----------------------------
--    -- SPI interface
--    -----------------------------

--    spi_cs                                    => '1',
--    spi_si                                    => '1',
--    spi_so                                    => open,
--    spi_clk                                   => '1'
--  );

  ----------------------------------------------------------------------
  --                      Acquisition Core                            --
  ----------------------------------------------------------------------



  --------------------
  -- ADC 1 data
  --------------------
  acq1_chan_array(c_acq_adc_id).val_low       <= fmc1_adc_data_ch3 &
                                                fmc1_adc_data_ch2 &
                                                fmc1_adc_data_ch1 &
                                                fmc1_adc_data_ch0;
  acq1_chan_array(c_acq_adc_id).val_high      <= (others => '0');
  acq1_chan_array(c_acq_adc_id).dvalid        <= '1';
  acq1_chan_array(c_acq_adc_id).trig          <= '0';

  --------------------
  -- ADC SWAP 1 data
  --------------------
  acq1_chan_array(c_acq_adc_swap_id).val_low       <= dsp1_adc_ch3_data &
                                                     dsp1_adc_ch2_data &
                                                     dsp1_adc_ch1_data &
                                                     dsp1_adc_ch0_data;
  acq1_chan_array(c_acq_adc_swap_id).val_high      <= (others => '0');
  acq1_chan_array(c_acq_adc_swap_id).dvalid        <= '1';
  acq1_chan_array(c_acq_adc_swap_id).trig          <= '0';

  --------------------
  -- MIXER I/Q 1/2 1 data
  --------------------
  acq1_chan_array(c_acq_mixiq12_id).val_low   <= std_logic_vector(resize(signed(dsp1_mixq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp1_mixi_ch0), 32));

  acq1_chan_array(c_acq_mixiq12_id).val_high  <= std_logic_vector(resize(signed(dsp1_mixq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp1_mixi_ch1), 32));

  acq1_chan_array(c_acq_mixiq12_id).dvalid    <= dsp1_mix_valid;
  acq1_chan_array(c_acq_mixiq12_id).trig      <= '0';

  --------------------
  -- MIXER I/Q 3/4 1 data
  --------------------
  acq1_chan_array(c_acq_mixiq34_id).val_low   <= std_logic_vector(resize(signed(dsp1_mixq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp1_mixi_ch2), 32));

  acq1_chan_array(c_acq_mixiq34_id).val_high  <= std_logic_vector(resize(signed(dsp1_mixq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp1_mixi_ch3), 32));

  acq1_chan_array(c_acq_mixiq34_id).dvalid    <= dsp1_mix_valid;
  acq1_chan_array(c_acq_mixiq34_id).trig      <= '0';

  --------------------
  -- TBT I/Q 1/2 1 data
  --------------------
  acq1_chan_array(c_acq_tbtdecimiq12_id).val_low   <= std_logic_vector(resize(signed(dsp1_tbtdecimq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbtdecimi_ch0), 32));

  acq1_chan_array(c_acq_tbtdecimiq12_id).val_high  <= std_logic_vector(resize(signed(dsp1_tbtdecimq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbtdecimi_ch1), 32));

  acq1_chan_array(c_acq_tbtdecimiq12_id).dvalid    <= dsp1_tbtdecim_valid;
  acq1_chan_array(c_acq_tbtdecimiq12_id).trig      <= '0';

  --------------------
  -- TBT I/Q 3/4 1 data
  --------------------
  acq1_chan_array(c_acq_tbtdecimiq34_id).val_low   <= std_logic_vector(resize(signed(dsp1_tbtdecimq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbtdecimi_ch2), 32));

  acq1_chan_array(c_acq_tbtdecimiq34_id).val_high  <= std_logic_vector(resize(signed(dsp1_tbtdecimq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbtdecimi_ch3), 32));

  acq1_chan_array(c_acq_tbtdecimiq34_id).dvalid    <= dsp1_tbtdecim_valid;
  acq1_chan_array(c_acq_tbtdecimiq34_id).trig      <= '0';

  --------------------
  -- TBT AMP 1 data
  --------------------
  acq1_chan_array(c_acq_tbt_amp_id).val_low   <= std_logic_vector(resize(signed(dsp1_tbt_amp_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbt_amp_ch0), 32));

  acq1_chan_array(c_acq_tbt_amp_id).val_high  <= std_logic_vector(resize(signed(dsp1_tbt_amp_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp1_tbt_amp_ch2), 32));

  acq1_chan_array(c_acq_tbt_amp_id).dvalid    <= dsp1_tbt_amp_valid;
  acq1_chan_array(c_acq_tbt_amp_id).trig      <= '0';

  --------------------
  -- TBT PHASE 1 data
  --------------------
  acq1_chan_array(c_acq_tbt_phase_id).val_low   <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq1_chan_array(c_acq_tbt_phase_id).val_high  <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq1_chan_array(c_acq_tbt_phase_id).dvalid    <= dsp1_tbt_pha_valid;
  acq1_chan_array(c_acq_tbt_phase_id).trig      <= '0';

  --------------------
  -- TBT POS 1 data
  --------------------
  acq1_chan_array(c_acq_tbt_pos_id).val_low   <= std_logic_vector(resize(signed(dsp1_pos_y_tbt), 32)) &
                                                std_logic_vector(resize(signed(dsp1_pos_x_tbt), 32));

  acq1_chan_array(c_acq_tbt_pos_id).val_high  <= std_logic_vector(resize(signed(dsp1_pos_sum_tbt), 32)) &
                                                std_logic_vector(resize(signed(dsp1_pos_q_tbt), 32));

  acq1_chan_array(c_acq_tbt_pos_id).dvalid    <= dsp1_pos_tbt_valid;
  acq1_chan_array(c_acq_tbt_pos_id).trig      <= '0';

  --------------------
  -- FOFB I/Q 1/2 1 data
  --------------------
  acq1_chan_array(c_acq_fofbdecimiq12_id).val_low   <= std_logic_vector(resize(signed(dsp1_fofbdecimq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp1_fofbdecimi_ch0), 32));

  acq1_chan_array(c_acq_fofbdecimiq12_id).val_high  <= std_logic_vector(resize(signed(dsp1_fofbdecimq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp1_fofbdecimi_ch1), 32));

  acq1_chan_array(c_acq_fofbdecimiq12_id).dvalid    <= dsp1_fofbdecim_valid;
  acq1_chan_array(c_acq_fofbdecimiq12_id).trig      <= '0';

  --------------------
  -- FOFB I/Q 3/4 1 data
  --------------------
  acq1_chan_array(c_acq_fofbdecimiq34_id).val_low   <= std_logic_vector(resize(signed(dsp1_fofbdecimq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp1_fofbdecimi_ch2), 32));

  acq1_chan_array(c_acq_fofbdecimiq34_id).val_high  <= std_logic_vector(resize(signed(dsp1_fofbdecimq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp1_fofbdecimi_ch3), 32));

  acq1_chan_array(c_acq_fofbdecimiq34_id).dvalid    <= dsp1_fofbdecim_valid;
  acq1_chan_array(c_acq_fofbdecimiq34_id).trig      <= '0';

  --------------------
  -- FOFB AMP 1 data
  --------------------
  acq1_chan_array(c_acq_fofb_amp_id).val_low   <= std_logic_vector(resize(signed(dsp1_fofb_amp_ch1), 32)) &
                                                 std_logic_vector(resize(signed(dsp1_fofb_amp_ch0), 32));

  acq1_chan_array(c_acq_fofb_amp_id).val_high  <= std_logic_vector(resize(signed(dsp1_fofb_amp_ch3), 32)) &
                                                 std_logic_vector(resize(signed(dsp1_fofb_amp_ch2), 32));

  acq1_chan_array(c_acq_fofb_amp_id).dvalid    <= dsp1_fofb_amp_valid;
  acq1_chan_array(c_acq_fofb_amp_id).trig      <= '0';

  --------------------
  -- FOFB PHASE 1 data
  --------------------
  acq1_chan_array(c_acq_fofb_phase_id).val_low   <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq1_chan_array(c_acq_fofb_phase_id).val_high  <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq1_chan_array(c_acq_fofb_phase_id).dvalid    <= dsp1_fofb_pha_valid;
  acq1_chan_array(c_acq_fofb_phase_id).trig      <= '0';

  --------------------
  -- FOFB POS 1 data
  --------------------
  acq1_chan_array(c_acq_fofb_pos_id).val_low   <= std_logic_vector(resize(signed(dsp1_pos_y_fofb), 32)) &
                                                 std_logic_vector(resize(signed(dsp1_pos_x_fofb), 32));

  acq1_chan_array(c_acq_fofb_pos_id).val_high  <= std_logic_vector(resize(signed(dsp1_pos_sum_fofb), 32)) &
                                                 std_logic_vector(resize(signed(dsp1_pos_q_fofb), 32));

  acq1_chan_array(c_acq_fofb_pos_id).dvalid    <= dsp1_pos_fofb_valid;
  acq1_chan_array(c_acq_fofb_pos_id).trig      <= '0';

  --------------------
  -- MONIT AMP 1 data
  --------------------
  acq1_chan_array(c_acq_monit_amp_id).val_low   <= std_logic_vector(resize(signed(dsp1_monit_amp_ch1), 32)) &
                                                  std_logic_vector(resize(signed(dsp1_monit_amp_ch0), 32));

  acq1_chan_array(c_acq_monit_amp_id).val_high  <= std_logic_vector(resize(signed(dsp1_monit_amp_ch3), 32)) &
                                                  std_logic_vector(resize(signed(dsp1_monit_amp_ch2), 32));

  acq1_chan_array(c_acq_monit_amp_id).dvalid    <= dsp1_monit_amp_valid;
  acq1_chan_array(c_acq_monit_amp_id).trig      <= '0';

  --------------------
  -- MONIT POS 1 data
  --------------------
  acq1_chan_array(c_acq_monit_pos_id).val_low   <= std_logic_vector(resize(signed(dsp1_pos_y_monit), 32)) &
                                                  std_logic_vector(resize(signed(dsp1_pos_x_monit), 32));

  acq1_chan_array(c_acq_monit_pos_id).val_high  <= std_logic_vector(resize(signed(dsp1_pos_sum_monit), 32)) &
                                                  std_logic_vector(resize(signed(dsp1_pos_q_monit), 32));

  acq1_chan_array(c_acq_monit_pos_id).dvalid    <= dsp1_pos_monit_valid;
  acq1_chan_array(c_acq_monit_pos_id).trig      <= '0';

  --------------------
  -- MONIT1 POS 1 data
  --------------------
  acq1_chan_array(c_acq_monit_1_pos_id).val_low   <= (others => '0');
  acq1_chan_array(c_acq_monit_1_pos_id).val_low   <= (others => '0');
  acq1_chan_array(c_acq_monit_1_pos_id).val_high  <= (others => '0');
  acq1_chan_array(c_acq_monit_1_pos_id).dvalid    <= '0';
  acq1_chan_array(c_acq_monit_1_pos_id).trig      <= '0';

  --------------------
  -- ADC 2 data
  --------------------
  acq2_chan_array(c_acq_adc_id).val_low       <= fmc2_adc_data_ch3 &
                                                fmc2_adc_data_ch2 &
                                                fmc2_adc_data_ch1 &
                                                fmc2_adc_data_ch0;
  acq2_chan_array(c_acq_adc_id).val_high      <= (others => '0');
  acq2_chan_array(c_acq_adc_id).dvalid        <= '1';
  acq2_chan_array(c_acq_adc_id).trig          <= '0';

  --------------------
  -- ADC SWAP 1 data
  --------------------
  acq2_chan_array(c_acq_adc_swap_id).val_low       <= dsp2_adc_ch3_data &
                                                     dsp2_adc_ch2_data &
                                                     dsp2_adc_ch1_data &
                                                     dsp2_adc_ch0_data;
  acq2_chan_array(c_acq_adc_swap_id).val_high      <= (others => '0');
  acq2_chan_array(c_acq_adc_swap_id).dvalid        <= '1';
  acq2_chan_array(c_acq_adc_swap_id).trig          <= '0';

  --------------------
  -- MIXER I/Q 1/2 2 data
  --------------------
  acq2_chan_array(c_acq_mixiq12_id).val_low   <= std_logic_vector(resize(signed(dsp2_mixq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp2_mixi_ch0), 32));

  acq2_chan_array(c_acq_mixiq12_id).val_high  <= std_logic_vector(resize(signed(dsp2_mixq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp2_mixi_ch1), 32));

  acq2_chan_array(c_acq_mixiq12_id).dvalid    <= dsp2_mix_valid;
  acq2_chan_array(c_acq_mixiq12_id).trig      <= '0';

  --------------------
  -- MIXER I/Q 3/4 2 data
  --------------------
  acq2_chan_array(c_acq_mixiq34_id).val_low   <= std_logic_vector(resize(signed(dsp2_mixq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp2_mixi_ch2), 32));

  acq2_chan_array(c_acq_mixiq34_id).val_high  <= std_logic_vector(resize(signed(dsp2_mixq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp2_mixi_ch3), 32));

  acq2_chan_array(c_acq_mixiq34_id).dvalid    <= dsp2_mix_valid;
  acq2_chan_array(c_acq_mixiq34_id).trig      <= '0';

  --------------------
  -- TBT I/Q 1/2 2 data
  --------------------
  acq2_chan_array(c_acq_tbtdecimiq12_id).val_low   <= std_logic_vector(resize(signed(dsp2_tbtdecimq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbtdecimi_ch0), 32));

  acq2_chan_array(c_acq_tbtdecimiq12_id).val_high  <= std_logic_vector(resize(signed(dsp2_tbtdecimq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbtdecimi_ch1), 32));

  acq2_chan_array(c_acq_tbtdecimiq12_id).dvalid    <= dsp2_tbtdecim_valid;
  acq2_chan_array(c_acq_tbtdecimiq12_id).trig      <= '0';

  --------------------
  -- TBT I/Q 3/4 2 data
  --------------------
  acq2_chan_array(c_acq_tbtdecimiq34_id).val_low   <= std_logic_vector(resize(signed(dsp2_tbtdecimq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbtdecimi_ch2), 32));

  acq2_chan_array(c_acq_tbtdecimiq34_id).val_high  <= std_logic_vector(resize(signed(dsp2_tbtdecimq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbtdecimi_ch3), 32));

  acq2_chan_array(c_acq_tbtdecimiq34_id).dvalid    <= dsp2_tbtdecim_valid;
  acq2_chan_array(c_acq_tbtdecimiq34_id).trig      <= '0';

  --------------------
  -- TBT AMP 2 data
  --------------------
  acq2_chan_array(c_acq_tbt_amp_id).val_low   <= std_logic_vector(resize(signed(dsp2_tbt_amp_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbt_amp_ch0), 32));

  acq2_chan_array(c_acq_tbt_amp_id).val_high  <= std_logic_vector(resize(signed(dsp2_tbt_amp_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp2_tbt_amp_ch2), 32));

  acq2_chan_array(c_acq_tbt_amp_id).dvalid    <= dsp2_tbt_amp_valid;
  acq2_chan_array(c_acq_tbt_amp_id).trig      <= '0';

  --------------------
  -- TBT PHASE 2 data
  --------------------
  acq2_chan_array(c_acq_tbt_phase_id).val_low   <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq2_chan_array(c_acq_tbt_phase_id).val_high  <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq2_chan_array(c_acq_tbt_phase_id).dvalid    <= dsp2_tbt_pha_valid;
  acq2_chan_array(c_acq_tbt_phase_id).trig      <= '0';

  --------------------
  -- TBT POS 2 data
  --------------------
  acq2_chan_array(c_acq_tbt_pos_id).val_low   <= std_logic_vector(resize(signed(dsp2_pos_y_tbt), 32)) &
                                                std_logic_vector(resize(signed(dsp2_pos_x_tbt), 32));

  acq2_chan_array(c_acq_tbt_pos_id).val_high  <= std_logic_vector(resize(signed(dsp2_pos_sum_tbt), 32)) &
                                                std_logic_vector(resize(signed(dsp2_pos_q_tbt), 32));

  acq2_chan_array(c_acq_tbt_pos_id).dvalid    <= dsp2_pos_tbt_valid;
  acq2_chan_array(c_acq_tbt_pos_id).trig      <= '0';

  --------------------
  -- FOFB I/Q 1/2 2 data
  --------------------
  acq2_chan_array(c_acq_fofbdecimiq12_id).val_low   <= std_logic_vector(resize(signed(dsp2_fofbdecimq_ch0), 32)) &
                                                std_logic_vector(resize(signed(dsp2_fofbdecimi_ch0), 32));

  acq2_chan_array(c_acq_fofbdecimiq12_id).val_high  <= std_logic_vector(resize(signed(dsp2_fofbdecimq_ch1), 32)) &
                                                std_logic_vector(resize(signed(dsp2_fofbdecimi_ch1), 32));

  acq2_chan_array(c_acq_fofbdecimiq12_id).dvalid    <= dsp2_fofbdecim_valid;
  acq2_chan_array(c_acq_fofbdecimiq12_id).trig      <= '0';

  --------------------
  -- FOFB I/Q 3/4 2 data
  --------------------
  acq2_chan_array(c_acq_fofbdecimiq34_id).val_low   <= std_logic_vector(resize(signed(dsp2_fofbdecimq_ch2), 32)) &
                                                std_logic_vector(resize(signed(dsp2_fofbdecimi_ch2), 32));

  acq2_chan_array(c_acq_fofbdecimiq34_id).val_high  <= std_logic_vector(resize(signed(dsp2_fofbdecimq_ch3), 32)) &
                                                std_logic_vector(resize(signed(dsp2_fofbdecimi_ch3), 32));

  acq2_chan_array(c_acq_fofbdecimiq34_id).dvalid    <= dsp2_fofbdecim_valid;
  acq2_chan_array(c_acq_fofbdecimiq34_id).trig      <= '0';

  --------------------
  -- FOFB AMP 2 data
  --------------------
  acq2_chan_array(c_acq_fofb_amp_id).val_low   <= std_logic_vector(resize(signed(dsp2_fofb_amp_ch1), 32)) &
                                                 std_logic_vector(resize(signed(dsp2_fofb_amp_ch0), 32));

  acq2_chan_array(c_acq_fofb_amp_id).val_high  <= std_logic_vector(resize(signed(dsp2_fofb_amp_ch3), 32)) &
                                                 std_logic_vector(resize(signed(dsp2_fofb_amp_ch2), 32));

  acq2_chan_array(c_acq_fofb_amp_id).dvalid    <= dsp2_fofb_amp_valid;
  acq2_chan_array(c_acq_fofb_amp_id).trig      <= '0';

  --------------------
  -- FOFB PHASE 2 data
  --------------------
  acq2_chan_array(c_acq_fofb_phase_id).val_low   <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq2_chan_array(c_acq_fofb_phase_id).val_high  <= std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32)) &
                                                  std_logic_vector(resize(to_signed(0, c_dsp_ref_num_bits_ns), 32));

  acq2_chan_array(c_acq_fofb_phase_id).dvalid    <= dsp2_fofb_pha_valid;
  acq2_chan_array(c_acq_fofb_phase_id).trig      <= '0';

  --------------------
  -- FOFB POS 2 data
  --------------------
  acq2_chan_array(c_acq_fofb_pos_id).val_low   <= std_logic_vector(resize(signed(dsp2_pos_y_fofb), 32)) &
                                                 std_logic_vector(resize(signed(dsp2_pos_x_fofb), 32));

  acq2_chan_array(c_acq_fofb_pos_id).val_high  <= std_logic_vector(resize(signed(dsp2_pos_sum_fofb), 32)) &
                                                 std_logic_vector(resize(signed(dsp2_pos_q_fofb), 32));

  acq2_chan_array(c_acq_fofb_pos_id).dvalid    <= dsp2_pos_fofb_valid;
  acq2_chan_array(c_acq_fofb_pos_id).trig      <= '0';

  --------------------
  -- MONIT AMP 2 data
  --------------------
  acq2_chan_array(c_acq_monit_amp_id).val_low   <= std_logic_vector(resize(signed(dsp2_monit_amp_ch1), 32)) &
                                                  std_logic_vector(resize(signed(dsp2_monit_amp_ch0), 32));

  acq2_chan_array(c_acq_monit_amp_id).val_high  <= std_logic_vector(resize(signed(dsp2_monit_amp_ch3), 32)) &
                                                  std_logic_vector(resize(signed(dsp2_monit_amp_ch2), 32));

  acq2_chan_array(c_acq_monit_amp_id).dvalid    <= dsp2_monit_amp_valid;
  acq2_chan_array(c_acq_monit_amp_id).trig      <= '0';

  --------------------
  -- MONIT POS 2 data
  --------------------
  acq2_chan_array(c_acq_monit_pos_id).val_low   <= std_logic_vector(resize(signed(dsp2_pos_y_monit), 32)) &
                                                  std_logic_vector(resize(signed(dsp2_pos_x_monit), 32));

  acq2_chan_array(c_acq_monit_pos_id).val_high  <= std_logic_vector(resize(signed(dsp2_pos_sum_monit), 32)) &
                                                  std_logic_vector(resize(signed(dsp2_pos_q_monit), 32));

  acq2_chan_array(c_acq_monit_pos_id).dvalid    <= dsp2_pos_monit_valid;
  acq2_chan_array(c_acq_monit_pos_id).trig      <= '0';

  --------------------
  -- MONIT1 POS 2 data
  --------------------
  acq2_chan_array(c_acq_monit_1_pos_id).val_low   <= (others => '0');
  acq2_chan_array(c_acq_monit_1_pos_id).val_high  <= (others => '0');
  acq2_chan_array(c_acq_monit_1_pos_id).dvalid    <= '0';
  acq2_chan_array(c_acq_monit_1_pos_id).trig      <= '0';

--  cmp_xwb_acq_core_2_to_1_mux : xwb_acq_core_2_to_1_mux
--  generic map
--  (
--    g_interface_mode                          => PIPELINED,
--    g_address_granularity                     => BYTE,
--    g_acq_addr_width                          => c_acq_addr_width,
--    g_acq_num_channels                        => c_acq_num_channels,
--    g_acq_channels                            => c_acq_channels,
--    g_ddr_payload_width                       => c_ddr_payload_width,
--    g_ddr_dq_width                            => c_ddr_dq_width,
--    g_ddr_addr_width                          => c_ddr_addr_width,
--    --g_multishot_ram_size                      => 2048,
--    g_fifo_fc_size                            => c_acq_fifo_size -- avoid fifo overflow
--    --g_sim_readback                            => false
--  )
--  port map
--  (
--    -- Clock signals for acquisition core 1
--    fs1_clk_i                                 => fs1_clk,
--    fs1_ce_i                                  => '1',
--    fs1_rst_n_i                               => fs1_rstn,

--    -- Clock signals for acquisition core 2
--    fs2_clk_i                                 => fs2_clk,
--    fs2_ce_i                                  => '1',
--    fs2_rst_n_i                               => fs2_rstn,

--    -- Clock signals for Wishbone
--    sys_clk_i                                 => clk_sys,
--    sys_rst_n_i                               => clk_sys_rstn,

--    -- From DDR3 Controller
--    ext_clk_i                                 => memc_ui_clk,
--    ext_rst_n_i                               => memc_ui_rstn,

--    -----------------------------
--    -- Wishbone Control Interface signals
--    -----------------------------
--    wb0_slv_i                                  => cbar_master_o(c_slv_acq_core_1_id),
--    wb0_slv_o                                  => cbar_master_i(c_slv_acq_core_1_id),

--    wb1_slv_i                                  => cbar_master_o(c_slv_acq_core_2_id),
--    wb1_slv_o                                  => cbar_master_i(c_slv_acq_core_2_id),

--    -----------------------------
--    -- External Interface
--    -----------------------------
--    acq0_chan_array_i                         => acq1_chan_array,
--    acq1_chan_array_i                         => acq2_chan_array,

--    -----------------------------
--    -- DRRAM Interface
--    -----------------------------
--    dpram0_dout_o                              => bpm_acq_dpram_dout , -- to chipscope
--    dpram0_valid_o                             => bpm_acq_dpram_valid, -- to chipscope

--    dpram1_dout_o                              => open,
--    dpram1_valid_o                             => open,

--    -----------------------------
--    -- External Interface (w/ FLow Control)
--    -----------------------------
--    ext0_dout_o                                => bpm_acq_ext_dout, -- to chipscope
--    ext0_valid_o                               => bpm_acq_ext_valid, -- to chipscope
--    ext0_addr_o                                => bpm_acq_ext_addr, -- to chipscope
--    ext0_sof_o                                 => bpm_acq_ext_sof, -- to chipscope
--    ext0_eof_o                                 => bpm_acq_ext_eof, -- to chipscope
--    ext0_dreq_o                                => bpm_acq_ext_dreq, -- to chipscope
--    ext0_stall_o                               => bpm_acq_ext_stall, -- to chipscope

--    ext1_dout_o                                => open,
--    ext1_valid_o                               => open,
--    ext1_addr_o                                => open,
--    ext1_sof_o                                 => open,
--    ext1_eof_o                                 => open,
--    ext1_dreq_o                                => open,
--    ext1_stall_o                               => open,

--    -----------------------------
--    -- DDR3 SDRAM Interface
--    -----------------------------
--    ui_app_addr_o                             => memc_cmd_addr,
--    ui_app_cmd_o                              => memc_cmd_instr,
--    ui_app_en_o                               => memc_cmd_en,
--    ui_app_rdy_i                              => memc_cmd_rdy,

--    ui_app_wdf_data_o                         => memc_wr_data,
--    ui_app_wdf_end_o                          => memc_wr_end,
--    ui_app_wdf_mask_o                         => memc_wr_mask,
--    ui_app_wdf_wren_o                         => memc_wr_en,
--    ui_app_wdf_rdy_i                          => memc_wr_rdy,

--    ui_app_rd_data_i                          => memc_rd_data,  -- not used!
--    ui_app_rd_data_end_i                      => '0',  -- not used!
--    ui_app_rd_data_valid_i                    => memc_rd_valid,  -- not used!

--    -- DDR3 arbitrer for multiple accesses
--    ui_app_req_o                              => memarb_acc_req,
--    ui_app_gnt_i                              => memarb_acc_gnt,

--    -----------------------------
--    -- Debug Interface
--    -----------------------------
--    dbg_ddr_rb0_start_p_i                     => '0',
--    dbg_ddr_rb0_rdy_o                         => open,
--    dbg_ddr_rb0_data_o                        => dbg_ddr_rb_data,
--    dbg_ddr_rb0_addr_o                        => dbg_ddr_rb_addr,
--    dbg_ddr_rb0_valid_o                       => dbg_ddr_rb_valid,

--    dbg_ddr_rb1_start_p_i                     => '0',
--    dbg_ddr_rb1_rdy_o                         => open,
--    dbg_ddr_rb1_data_o                        => open,
--    dbg_ddr_rb1_addr_o                        => open,
--    dbg_ddr_rb1_valid_o                       => open
--  );

  memc_ui_rstn <= not(memc_ui_rst);

  memc_cmd_addr_resized <= f_gen_std_logic_vector(c_acq_ddr_addr_diff, '0') &
                               memc_cmd_addr;

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
  

--  cmp_test_adapter: test_adapter
--  PORT MAP (
--    clk_i => boot_clk_i,
--    rst_i => clk_sys_rst
--  );
  
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
    vadj2_clk_updaten_o <= '1';
end rtl;
