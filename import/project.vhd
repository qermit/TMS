library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;

package sdb_meta_pkg is

  ------------------------------------------------------------------------------
  -- Meta-information sdb records
  ------------------------------------------------------------------------------

 -- Top module repository url
  constant c_sdb_repo_url : t_sdb_repo_url := (
    -- url (string, 63 char)
    repo_url => "                                                               ");

  -- Synthesis informations
  constant c_sdb_synthesis : t_sdb_synthesis := (
    -- Top module name (string, 16 char)
    syn_module_name  => "dbe_bpm_dsp     ",
    -- Commit ID (hex string, 128-bit = 32 char)
    -- git log -1 --format="%H" | cut -c1-32
    syn_commit_id    => "                                ",
    -- Synthesis tool name (string, 8 char)
    syn_tool_name    => "VIVADO  ",
    -- Synthesis tool version (bcd encoded, 32-bit)
    syn_tool_version => x"00020144",
    -- Synthesis date (bcd encoded, 32-bit)
    syn_date         => x"20150901",    -- yyyymmdd
    -- Synthesised by (string, 15 char)
    syn_username     => "pmiedzik       ");

  -- Integration record
  constant c_sdb_integration : t_sdb_integration := (
    product     => (
      vendor_id => x"0000000000000651",  -- GSI
      device_id => x"00000001",          -- Device id: 1 = master. 2 = adc
      version   => x"00010000",          -- bcd encoded, [31:16] = major, [15:0] = minor
      date      => x"20150901",          -- yyyymmdd
      name      => "tms-master         "));

end sdb_meta_pkg;

