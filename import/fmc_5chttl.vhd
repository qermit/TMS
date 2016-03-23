----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/09/2015 02:24:27 PM
-- Design Name: 
-- Module Name: fmc_5chttl - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.wishbone_pkg.all;


entity fmc_5chttl is
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
end fmc_5chttl;

architecture Behavioral of fmc_5chttl is

signal s_io_out_tmp: std_logic_vector(g_num_io-1 downto 0);
signal s_io_out: std_logic_vector(g_num_io-1 downto 0);

signal s_io_in: std_logic_vector(g_num_io-1 downto 0);

signal s_io_in_tmp: std_logic_vector(g_num_io-1 downto 0);

signal rst_n_i: std_logic;

begin

  rst_n_i <= not rst_i;

  cmp_IO : xwb_gpio_port
  generic map(
    g_interface_mode                        => PIPELINED,
    g_address_granularity                   => BYTE,
    g_num_pins                              => g_num_io,
    g_with_builtin_tristates                => false
  )
  port map(
    clk_sys_i                               => clk_i,
    rst_n_i                                 => rst_n_i,

    -- Wishbone
    slave_i                                 => slave_i,
    slave_o                                 => slave_o,
    desc_o                                  => open,    -- Not implemented

    --gpio_b : inout std_logic_vector(g_num_pins-1 downto 0);

    gpio_out_o                              => s_io_out_tmp,
    gpio_in_i                               => s_io_in,
    gpio_oen_o                              => dir_o,
    gpio_term_o                             => term_o,
    
    raw_o => raw_o,
    raw_i => raw_i
    
    
    
  );


 GEN_REG:  for I in 0 to (g_num_io-1) generate
  cmp_ibuf : IBUFDS
  generic map(
    IOSTANDARD => "DEFAULT"
  )
  port map(
    I  => in_p_i(I),
    IB => in_n_i(I),
    O  => s_io_in_tmp(I)
  );
  -- mozna zrobic xor
--   GEN_REG_NORM: if g_negate_in(I) = '0' generate
--   s_io_in(I) <= s_io_in_tmp(I);
--   end generate GEN_REG_NORM;

--   GEN_REG_NEG: if g_negate_in(I) = '0' generate
--   s_io_in(I) <= not s_io_in_tmp(I);
--   end generate GEN_REG_NEG;   
   
   
  cmp_obuf : OBUFDS
    generic map(
      IOSTANDARD => "DEFAULT"
    )
    port map(
      O  => out_p_o(I),
      OB => out_n_o(I),
      I  => s_io_out(I)
    );
 
   end generate;
   s_io_out <= s_io_out_tmp xor g_negate_out(g_num_io -1 downto 0);
   s_io_in <= s_io_in_tmp xor g_negate_in(g_num_io -1 downto 0);
   
   
   
  -- LVDS input to internal single
  
end Behavioral;
