-------------------------------------------------------------------------------
-- Title      : Dual-port RAM for WR core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : wrc_dpram.vhd
-- Author     : Grzegorz Daniluk
-- Company    : Elproma
-- Created    : 2011-02-15
-- Last update: 2011-09-26
-- Platform   : FPGA-generics
-- Standard   : VHDL '93
-------------------------------------------------------------------------------
-- Description:
--
-- Dual port RAM with wishbone interface
-------------------------------------------------------------------------------
-- Copyright (c) 2011 Grzegorz Daniluk
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-02-15  1.0      greg.d          Created
-- 2011-06-09  1.01     twlostow        Removed unnecessary generics
-- 2011-21-09  1.02     twlostow        Struct-ized version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.genram_pkg.all;
use work.wishbone_pkg.all;

entity xwb_dpram_raw is
  generic(
    g_size                  : natural := 16384;
    g_init_file             : string  := "";
    g_must_have_init_file   : boolean := true;
    g_slave1_interface_mode : t_wishbone_interface_mode;
    g_slave2_interface_mode : t_wishbone_interface_mode;
    g_slave1_granularity    : t_wishbone_address_granularity;
    g_slave2_granularity    : t_wishbone_address_granularity
    );
  port(
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    slave1_i : in  t_wishbone_slave_in;
    slave1_o : out t_wishbone_slave_out;
    
          -- Port B
    ram_bweb_i  : in std_logic_vector(3 downto 0);
    ram_web_i   : in std_logic;
    ram_ab_i   : in std_logic_vector(f_log2_size(g_size)-1 downto 0);
    ram_db_i   : in std_logic_vector(31 downto 0);
    ram_qb_o   : out std_logic_vector(31 downto 0)
    --slave2_i : in  t_wishbone_slave_in;
    --slave2_o : out t_wishbone_slave_out
    );
end xwb_dpram_raw;

architecture struct of xwb_dpram_raw is

  function f_zeros(size : integer)
    return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(0, size));
  end f_zeros;


  signal s_wea  : std_logic;
  signal s_web  : std_logic;
  signal s_bwea : std_logic_vector(3 downto 0);
  signal s_bweb : std_logic_vector(3 downto 0);

  signal slave1_in  : t_wishbone_slave_in;
  signal slave1_out : t_wishbone_slave_out;
  signal slave2_in  : t_wishbone_slave_in;
  signal slave2_out : t_wishbone_slave_out;
  
  

  
begin
  U_Adapter1 : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => g_slave1_interface_mode,
      g_master_granularity => WORD,
      g_slave_use_struct   => true,
      g_slave_mode         => g_slave1_interface_mode,
      g_slave_granularity  => g_slave1_granularity)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,
      slave_i   => slave1_i,
      slave_o   => slave1_o,
      master_i  => slave1_out,
      master_o  => slave1_in);

--  U_Adapter2 : wb_slave_adapter
--    generic map (
--      g_master_use_struct  => true,
--      g_master_mode        => g_slave2_interface_mode,
--      g_master_granularity => WORD,
--      g_slave_use_struct   => true,
--      g_slave_mode         => g_slave2_interface_mode,
--      g_slave_granularity  => g_slave2_granularity)
--    port map (
--      clk_sys_i => clk_sys_i,
--      rst_n_i   => rst_n_i,
--      slave_i   => slave2_i,
--      slave_o   => slave2_o,
--      master_i  => slave2_out,
--      master_o  => slave2_in);

  U_DPRAM : generic_dpram
    generic map(
      -- standard parameters
      g_data_width               => 32,
      g_size                     => g_size,
      g_with_byte_enable         => true,
      g_addr_conflict_resolution => "dont_care",
      g_init_file                => g_init_file,
      g_dual_clock               => false
      )
    port map(
      rst_n_i => rst_n_i,
      -- Port A
      clka_i  => clk_sys_i,
      bwea_i  => s_bwea,
      wea_i   => s_wea,
      aa_i    => slave1_in.adr(f_log2_size(g_size)-1 downto 0),
      da_i    => slave1_in.dat,
      qa_o    => slave1_out.dat,
      -- Port B
      clkb_i  => clk_sys_i,
      bweb_i  => ram_bweb_i,
      web_i   => ram_web_i,
      ab_i    => ram_ab_i,
      db_i    => ram_db_i,
      qb_o    => ram_qb_o
      );

  -- I know this looks weird, but otherwise ISE generates distributed RAM instead of block
  -- RAM
  s_bwea <= slave1_in.sel when s_wea = '1' else f_zeros(c_wishbone_data_width/8);
  --s_bweb <= slave2_in.sel when s_web = '1' else f_zeros(c_wishbone_data_width/8);

  s_wea <= slave1_in.we and slave1_in.stb and slave1_in.cyc;
  --s_web <= slave2_in.we and slave2_in.stb and slave2_in.cyc;

  process(clk_sys_i)
  begin
    if(rising_edge(clk_sys_i)) then
      if(rst_n_i = '0') then
        slave1_out.ack <= '0';
--        slave2_out.ack <= '0';
      else
        if(slave1_out.ack = '1' and g_slave1_interface_mode = CLASSIC) then
          slave1_out.ack <= '0';
        else
          slave1_out.ack <= slave1_in.cyc and slave1_in.stb;
        end if;

        --if(slave2_out.ack = '1' and g_slave2_interface_mode = CLASSIC) then
--          slave2_out.ack <= '0';
--        else
--          slave2_out.ack <= slave2_in.cyc and slave2_in.stb;
--        end if;
      end if;
    end if;
  end process;

  slave1_out.stall <= '0';
--  slave2_out.stall <= '0';
  slave1_out.err <= '0';
--  slave2_out.err <= '0';
  slave1_out.rty <= '0';
--  slave2_out.rty <= '0';
  
end struct;

