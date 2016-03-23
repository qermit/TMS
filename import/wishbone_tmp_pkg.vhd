  library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;
use work.wishbone_pkg.all;

package wishbone_tmp_pkg is

  type t_sdb_repo_url is record
    repo_url : string(1 to 63);
  end record t_sdb_repo_url;
  
    type t_sdb_synthesis is record
    syn_module_name  : string(1 to 16);
    syn_commit_id    : string(1 to 32);
    syn_tool_name    : string(1 to 8);
    syn_tool_version : std_logic_vector(31 downto 0);
    syn_date         : std_logic_vector(31 downto 0);
    syn_username     : string(1 to 15);
  end record t_sdb_synthesis;
  
    type t_sdb_product is record
    vendor_id : std_logic_vector(63 downto 0);
    device_id : std_logic_vector(31 downto 0);
    version   : std_logic_vector(31 downto 0);
    date      : std_logic_vector(31 downto 0);
    name      : string(1 to 19);
  end record t_sdb_product;
    type t_sdb_integration is record
    product : t_sdb_product;
  end record t_sdb_integration;
  
  
    constant c_xwb_i2c_master_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                 -- 8/16/32-bit port granularity
    sdb_component => (
      addr_first  => x"0000000000000000",
      addr_last   => x"00000000000000ff",
      product     => (
        vendor_id => x"000000000000CE42",  -- CERN
        device_id => x"123c5443",
        version   => x"00000001",
        date      => x"20121129",
        name      => "WB-I2C-Master      ")));
  
  
  
    constant c_xwb_onewire_master_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                 -- 8/16/32-bit port granularity
    sdb_component => (
      addr_first  => x"0000000000000000",
      addr_last   => x"00000000000000ff",
      product     => (
        vendor_id => x"000000000000CE42",  -- CERN
        device_id => x"779c5443",
        version   => x"00000001",
        date      => x"20121129",
        name      => "WB-OneWire-Master  ")));
  
  
    function f_sdb_embed_repo_url(url : t_sdb_repo_url)
    return t_sdb_record
  is
    variable result : t_sdb_record;
  begin
    result(511 downto 8) := f_string2svl(url.repo_url);
    result(  7 downto 0) := x"81"; -- repo_url record
    return result;
  end;
end wishbone_tmp_pkg;
