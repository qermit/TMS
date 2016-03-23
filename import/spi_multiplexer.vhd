----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2015 03:39:52 PM
-- Design Name: 
-- Module Name: spi_multiplexer - Behavioral
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

entity spi_multiplexer is
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
end spi_multiplexer;

architecture Behavioral of spi_multiplexer is

signal r_mode : std_logic_vector(7 downto 0) := "00000000";
signal r_group : std_logic_vector(g_modules-1 downto 0) := ( others => '0');

signal s_ssel : std_logic_vector((g_modules * g_slaves_per_module)-1 downto 0);
signal s_mosi : STD_LOGIC_VECTOR (g_modules-1 downto 0);
signal s_sclk : STD_LOGIC_VECTOR (g_modules-1 downto 0);
signal s_miso : std_logic;

begin

   s_miso <= m_miso_i(0) when r_group(0) = '1' else
             m_miso_i(1) when r_group(1) = '1' else
             m_miso_i(2) when r_group(2) = '1' else
             m_miso_i(3) when r_group(3) = '1' else
            '1';


 GEN_modules:  for i in 0 to (g_modules-1) generate
   s_sclk(i) <= sclk_i when r_group(i) = '1' else '1';
   s_mosi(i) <= mosi_i when r_group(i) = '1' else '1';
   
   GEN_ssel:  for j in 0 to (g_slaves_per_module-1) generate
      s_ssel( (g_slaves_per_module*i)+j) <= sel_i when r_group(i) = '1' and r_mode(j) = '1' else '1' ;
   end generate GEN_ssel;
   
   end generate GEN_modules;
   
   m_ssel_o <= s_ssel; 
   m_mosi_o <= s_mosi;
   m_sclk_o <= s_sclk;
   
   miso_o <= s_miso;
   
   process(clk_i)
   begin
     if rising_edge(clk_i) then
       if (rst_i = '1') then
         r_mode <= "00010001";
         r_group <=  (0 => '1', others => '0');
       end if;
     end if;
   end process;
   
end Behavioral;
