library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;

package spi2wbm_pkg is
	constant c_CMD_EMPTY       : std_logic_vector(7 downto 0) := x"FF";
	constant c_CMD_UNKNOWN     : std_logic_vector(7 downto 0) := x"00";
	constant c_CMD_READID      : std_logic_vector(7 downto 0) := x"9F";
	constant c_CMD_READ_BRAM   : std_logic_vector(7 downto 0) := x"03";
	constant c_CMD_WRITE_BRAM  : std_logic_vector(7 downto 0) := x"02";
	constant c_CMD_READ_WBONE  : std_logic_vector(7 downto 0) := x"13";
	constant c_CMD_WRITE_WBONE : std_logic_vector(7 downto 0) := x"12";
	
	
component spi2wbm_link 
port(rst_i         : in  std_logic;
     clk_i         : in  std_logic;
     spi_sel       : in  std_logic;
     spi_mosi      : in  std_logic;
     spi_miso      : out std_logic;
     spi_clk       : in  std_logic;
     
     wb_master_i   : in  t_wishbone_master_in;
     wb_master_o   : out t_wishbone_master_out;
     
     SERIAL_addr   : out STD_LOGIC_VECTOR(31 downto 0);
     SERIAL_data_o : out STD_LOGIC_VECTOR(31 downto 0);
     SERIAL_data_i : in  std_logic_vector(31 downto 0);
     SERIAL_bwbe   : out std_logic_vector(3 downto 0);
     SERIAL_we     : out STD_LOGIC;
     SERIAL_en     : out std_logic
 );
 

end component spi2wbm_link;
	
	
 COMPONENT chipscope_ila

PORT (
    clk : IN STD_LOGIC;


    probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

COMPONENT vio_boot
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

 -- FMC150 Interface
  constant c_fmcdio5chttl_sdb : t_sdb_device := (
    abi_class     => x"0000",                 -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"00",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                     -- 8/16/32-bit port granularity (0111)
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"00000000000000FF",
    product => (
    vendor_id     => x"1000000000001215",     -- LNLS
    device_id     => x"f8c1505a",
    version       => x"00000001",
    date          => x"20151109",
    name          => "FMC_5ch_TTLA       ")));


end package spi2wbm_pkg;

package body spi2wbm_pkg is


 

end package body spi2wbm_pkg;
