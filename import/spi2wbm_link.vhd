library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.spi2wbm_pkg.all;

entity spi2wbm_link is
    generic (
      g_debug: boolean:= false
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
end entity spi2wbm_link;

architecture RTL of spi2wbm_link is
	signal bit_count  : integer range 0 to 8;
	signal byte_count : integer range 0 to 7;

	signal command : std_logic_vector(7 downto 0);

	TYPE STATE_TYPE IS (
		idle,
		cs_low,
		clk_h,
		wait_clk_l,
		wait_clk_h,
		clk_l,
		latch_byte_out,
		latch_byte_in
	);

	signal reset                           : std_logic;
	signal SCK_synch, SDI_synch, SCS_synch, SDO_synch : std_logic;
	SIGNAL state                           : STATE_TYPE;

	signal s_latch_data_in  : std_logic;
	signal s_latch_data_out : std_logic;
	signal s_shift_data_in  : std_logic;
	signal s_shift_data_out : std_logic;
	signal s_dpram_address  : std_logic_vector(31 downto 0);
	signal s_dpram_addr     : std_logic_vector(31 downto 0);
	signal s_dpram_data_in  : std_logic_vector(7 downto 0);
	signal s_dpram_data_out : std_logic_vector(7 downto 0);
	signal s_dpram_en       : std_logic;
	signal r_wbone_en       : std_logic;
	signal r_dpram_wr       : std_logic;
	signal r_wbone_wr       : std_logic;

	signal s_wbone_address    : std_logic_vector(31 downto 0);
	signal s_wishbone_data_in : std_logic_vector(31 downto 0);
	signal r_wishbone_data_in : std_logic_vector(31 downto 0);

	signal r_command               : std_logic_vector(7 downto 0);
	signal r_dpram_address_counter : integer range 0 to 3;
	signal r_dpram_address_catched : std_logic;
	signal r_wbone_address_catched : std_logic;
	signal r_wbone_address_counter : integer range 0 to 4;
	signal s_wbone_data_out        : std_logic_vector(7 downto 0);
	signal s_wbone_data_out32      : std_logic_vector(31 downto 0);
	signal s_wbone_addr            : std_logic_vector(31 downto 0);

	signal r_output : std_logic_vector(7 downto 0);
	signal r_input  : std_logic_vector(7 downto 0);

	signal s_rdid_data_out : std_logic_vector(7 downto 0);
	signal r_rdid_shift    : std_logic_vector(3 * 8 - 1 downto 0);

	signal r_wbone_hit, r_wbone_miss : std_logic;
	signal r_rdid_hit, r_rdid_miss   : std_logic;
	signal r_dpram_hit, r_dpram_miss : std_logic;


   signal s_bweb: std_logic_vector(3 downto 0);
   
   
   signal wb_master_input   : t_wishbone_master_in;
   signal wb_master_output  :t_wishbone_master_out;
   
begin
	reset <= rst_i;

	p_line_synch : process(clk_i, reset)
	begin
		if (reset = '1') then
			SCK_synch <= '0';
			SDI_synch <= '0';
			SCS_synch <= '1';
		elsif rising_edge(clk_i) then
			SCK_synch <= spi_clk;
			SDI_synch <= spi_mosi;
			SCS_synch <= spi_sel;
		end if;
	end process;

	p_fsm : process(clk_i, reset)
	begin
		if reset = '1' then
			state <= idle;
		elsif rising_edge(clk_i) then
			case state is
				when idle =>
					byte_count <= 0;
					command    <= (others => '0');

					if SCS_synch = '0' then
						state <= cs_low;
					end if;

				when cs_low =>
					bit_count <= 7;
					if SCS_synch = '1' then
						state <= idle;
					elsif SCK_synch = '1' then
						state <= clk_h;
					end if;

				when wait_clk_h =>
					if SCS_synch = '1' then
						state <= idle;
					elsif (SCK_synch = '1') then
						state <= clk_h;
					end if;

				when clk_h =>
					if SCS_synch = '1' then
						state <= idle;
					elsif bit_count = 0 then
						state <= latch_byte_in;
					else
						state <= wait_clk_l;
					end if;
				-- @todo handling lath cpol=0/cpha=0 ; cpol=1/cpha=1
				-- @todo shif output byte

				when wait_clk_l =>
					if SCS_synch = '1' then
						state <= idle;
					elsif (SCK_synch = '0') then
						state <= clk_l;
					end if;

				when clk_l =>
					if SCS_synch = '1' then
						state <= idle;
					elsif bit_count = 0 then
						state <= latch_byte_out;
					else
						bit_count <= bit_count - 1;
						state     <= wait_clk_h;
					end if;

				when latch_byte_out =>
					if SCS_synch = '1' then
						state <= idle;
					else
						state <= cs_low;
					end if;
				when latch_byte_in =>
					if SCS_synch = '1' then
						state <= idle;
					else
						state <= wait_clk_l;
					end if;

			end case;
		end if;
	end process;

	WITH state SELECT s_latch_data_in <=
		'1' when latch_byte_in,
		'0' when others;
	WITH state SELECT s_latch_data_out <=
		'1' when latch_byte_out,
		'0' when others;
	WITH state SELECT s_shift_data_in <=
		'1' when clk_h,
		'0' when others;

	WITH state SELECT s_shift_data_out <=
		'1' when clk_l,
		'0' when others;

	spi_miso <= r_output(7);
    SDO_synch <= r_output(7);
    
    -- latch data to r_input register --
	p_data_in : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if reset = '1' then
				r_input <= (others => '0');
			elsif s_latch_data_in = '1' then
				r_input <= (others => '0');
			elsif s_shift_data_in = '1' then
				r_input <= r_input(6 downto 0) & SDI_synch;
			end if;
		end if;
	end process;

	p_data_out : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if reset = '1' or SCS_synch = '1' then
				r_output <= (others => '1');
			elsif s_latch_data_out = '1' then
				if r_command = c_CMD_UNKNOWN or r_command = c_CMD_EMPTY then
					r_output <= x"FF";
				elsif r_command = c_CMD_READ_BRAM or r_command = c_CMD_WRITE_BRAM then
					if r_dpram_address_catched = '1' then
						r_output <= s_dpram_data_out;
					else
						r_output <= x"FF";
					end if;
				elsif r_command = c_CMD_READ_WBONE or r_command = c_CMD_WRITE_WBONE then
					if r_wbone_address_catched = '1' then
						r_output <= s_wbone_data_out;
					else
						r_output <= x"FF";
					end if;
				elsif r_command = c_CMD_READID then
					r_output <= s_rdid_data_out;
				else
					r_output <= x"AA";
				end if;

			elsif s_shift_data_out = '1' then
				r_output <= r_output(6 downto 0) & '1';
			end if;
		end if;
	end process;

	p_command_latch : process(clk_i)
		variable tmp_command : std_logic_vector(7 downto 0);
	begin
		if rising_edge(clk_i) then
			tmp_command := r_input(6 downto 0) & SDI_synch;
			if reset = '1' or SCS_synch = '1' then
				r_command <= c_CMD_EMPTY;

				r_rdid_miss  <= '0';
				r_rdid_hit   <= '0';
				r_wbone_miss <= '0';
				r_wbone_hit  <= '0';
				r_dpram_miss <= '0';
				r_dpram_hit  <= '0';
				r_dpram_wr   <= '0';
				r_wbone_wr   <= '0';
			elsif s_shift_data_in = '1' and r_command = c_CMD_EMPTY and bit_count = 0 then
				r_rdid_miss  <= '1';
				r_wbone_miss <= '1';
				r_dpram_miss <= '1';
				r_dpram_wr   <= '0';
				r_wbone_wr   <= '0';

				if tmp_command = c_CMD_READID then
					r_rdid_hit  <= '1';
					r_rdid_miss <= '0';
					r_command   <= c_CMD_READID;
				elsif tmp_command = c_CMD_READ_BRAM then
					r_command    <= c_CMD_READ_BRAM;
					r_dpram_hit  <= '1';
					r_dpram_miss <= '0';
				elsif tmp_command = c_CMD_READ_WBONE then
					r_wbone_hit  <= '1';
					r_wbone_miss <= '0';
					r_command    <= c_CMD_READ_WBONE;
				elsif tmp_command = c_CMD_WRITE_BRAM then
					r_command    <= c_CMD_WRITE_BRAM;
					r_dpram_hit  <= '1';
					r_dpram_miss <= '0';
					r_dpram_wr   <= '1';
				elsif tmp_command = c_CMD_WRITE_WBONE then
					r_wbone_hit  <= '1';
					r_wbone_miss <= '0';
					r_wbone_wr   <= '1';
					r_command    <= c_CMD_WRITE_WBONE;
				else
					r_command <= c_CMD_UNKNOWN;
				end if;
			end if;
		end if;
	end process;

	p_dpram : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if reset = '1' then
				r_dpram_address_counter <= 3;
				s_dpram_address         <= (others => '0');
				r_dpram_address_catched <= '0';
				s_dpram_addr            <= (others => '0');
			elsif SCS_synch = '1' then
				r_dpram_address_counter <= 3;
				s_dpram_address         <= (others => '0');
				r_dpram_address_catched <= '0';
				s_dpram_data_in         <= (others => '1');
			    s_dpram_addr            <= (others => '0');
			elsif s_latch_data_in = '1' and r_dpram_hit = '1' then
				if r_dpram_address_catched = '0' then
					if r_dpram_address_counter = 3 then
						s_dpram_address(31 downto 24) <= (others => '0');
						r_dpram_address_counter       <= r_dpram_address_counter - 1;
					elsif r_dpram_address_counter = 2 then
						s_dpram_address(23 downto 16) <= r_input;
						r_dpram_address_counter       <= r_dpram_address_counter - 1;
					elsif r_dpram_address_counter = 1 then
						s_dpram_address(15 downto 8) <= r_input;
						r_dpram_address_counter      <= r_dpram_address_counter - 1;
					elsif r_dpram_address_counter = 0 then
						s_dpram_address(7 downto 0) <= r_input;
						r_dpram_address_counter     <= 3;
						r_dpram_address_catched     <= '1';
						s_dpram_addr    <= s_dpram_address(31 downto 8) & r_input;
						if (r_dpram_wr = '0') then
                               s_dpram_en <= '1';
                        end if;
					end if;
				else
					--if (r_dpram_address_counter = 0) then
					--	r_dpram_address_counter <= 3;
					--s_dpram_address <= std_logic_vector(unsigned(s_dpram_address) + 1);
					--else
					--	r_dpram_address_counter <= r_dpram_address_counter - 1;
					--end if;
					s_dpram_data_in <= r_input;
					s_dpram_en      <= '1';
					s_dpram_addr    <= s_dpram_address;

				end if;

			-- @todo increment address	each cycle
			-- @todo dpram - 32 bit and 8 bit interface
			elsif s_dpram_en = '1' then
			    s_dpram_address <= std_logic_vector(unsigned(s_dpram_address) + 1);
				s_dpram_en <= '0';
			--s_dpram_addr <= (others => '0');
			end if;
		end if;
	end process;

	

	p_wbone : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if reset = '1' or SCS_synch = '1' then
				s_wbone_address         <= (others => '0');
				r_wbone_address_catched <= '0';
				r_wbone_address_counter <= 4;
				s_wishbone_data_in      <= (others => '1');
				r_wbone_en              <= '0';
				s_wbone_addr            <= (others => '1');
			elsif s_latch_data_in = '1' and r_wbone_hit = '1' then
				if r_wbone_address_catched = '0' then
					if r_wbone_address_counter = 4 then
						r_wbone_address_counter <= r_wbone_address_counter - 1;
					elsif r_wbone_address_counter = 3 then
						s_wbone_address(31 downto 24) <= r_input;
						r_wbone_address_counter       <= r_wbone_address_counter - 1;
					elsif r_wbone_address_counter = 2 then
						s_wbone_address(23 downto 16) <= r_input;
						r_wbone_address_counter       <= r_wbone_address_counter - 1;
					elsif r_wbone_address_counter = 1 then
						s_wbone_address(15 downto 8) <= r_input;
						r_wbone_address_counter      <= r_wbone_address_counter - 1;
					elsif r_wbone_address_counter = 0 then
						s_wbone_address(7 downto 0) <= r_input;

						r_wbone_address_counter <= 3;
						r_wbone_address_catched <= '1';

						s_wbone_addr <= s_wbone_address(31 downto 8) & r_input;
						if (r_wbone_wr = '0') then
							r_wbone_en <= '1';
						end if;

					end if;
				else
					r_wbone_en <= '0';
					s_wishbone_data_in <= s_wishbone_data_in(23 downto 0) & r_input;
					
					if (r_wbone_address_counter = 0) then
						r_wbone_address_counter <= 3;
						r_wbone_en              <= '1';
						s_wbone_addr            <= s_wbone_address;
						r_wishbone_data_in <= s_wishbone_data_in(23 downto 0) & r_input;
					else
						r_wbone_address_counter <= r_wbone_address_counter - 1;

					end if;
					

				end if;

			-- @todo increment address each 4 cycle
			-- @todo wishbone write after 4 cycles
			elsif r_wbone_en = '1' then
			    s_wbone_address <= std_logic_vector(unsigned(s_wbone_address) + 1);
				r_wbone_en <= '0';
			end if;
		end if;
	end process;


    p_wbone2: process(clk_i)
    begin
      if rising_edge(clk_i) then
        if reset = '1' or SCS_synch = '1' then
          wb_master_output.cyc <= '0';
          wb_master_output.stb <= '0';
          wb_master_output.sel <= "0000";
          s_wbone_data_out32 <= (others => '0');
          s_wbone_data_out <= x"00";
        else 
         --if (
         if r_wbone_address_counter = 0 then
           s_wbone_data_out <= s_wbone_data_out32(7 downto 0);
         elsif r_wbone_address_counter = 1 then
           s_wbone_data_out <= s_wbone_data_out32(15 downto 8);
         elsif r_wbone_address_counter = 2 then
           s_wbone_data_out <= s_wbone_data_out32(23 downto 16);
         elsif r_wbone_address_counter = 3 then
           s_wbone_data_out <= s_wbone_data_out32(31 downto 24);
         else
           s_wbone_data_out <= x"00";
         end if;
         
         if wb_master_output.cyc = '1' then
          if wb_master_input.ack = '1' then
            wb_master_output.cyc <= '0';
            wb_master_output.stb <= '0';
            wb_master_output.sel <= "0000";
            s_wbone_data_out32 <= wb_master_input.dat;
          elsif wb_master_input.err = '1' then
            wb_master_output.cyc <= '0';
            wb_master_output.stb <= '0';
            wb_master_output.sel <= "0000";
            s_wbone_data_out32 <= x"1CEB00DA";    
          end if;
        elsif s_latch_data_in = '1' and r_wbone_hit = '1' then
          if r_wbone_address_catched = '0' then
            if r_wbone_address_counter = 0 then
              if r_wbone_wr = '0' then
                wb_master_output.cyc <= '1';
                wb_master_output.stb <= '1';
                wb_master_output.sel <= "1111";
              end if;
            end if;
          else
            if (r_wbone_address_counter = 0) then
              wb_master_output.cyc <= '1';
              wb_master_output.stb <= '1';
              wb_master_output.sel <= "1111";
            end if;
          end if;
        end if;
        end if;
      end if;
    end process;
	p_rdid : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if reset = '1' or SCS_synch = '1' then
				r_rdid_shift    <= x"aabbcc";
				s_rdid_data_out <= (others => '1');
			elsif s_latch_data_in = '1' and r_rdid_hit = '1' then
				r_rdid_shift    <= r_rdid_shift(r_rdid_shift'left - 8 downto 0) & r_rdid_shift(r_rdid_shift'left downto r_rdid_shift'left - 7);
				s_rdid_data_out <= r_rdid_shift(r_rdid_shift'left downto r_rdid_shift'left - 7);
			end if;
		end if;
	end process;

	SERIAL_addr   <= "00" & s_dpram_addr(31 downto 2);
	SERIAL_we     <= r_dpram_wr AND s_dpram_en;
	SERIAL_data_o <= s_dpram_data_in & s_dpram_data_in & s_dpram_data_in & s_dpram_data_in;

	process(r_dpram_wr, s_dpram_en, s_dpram_addr(1 downto 0))
	begin
		if (r_dpram_wr = '1' and s_dpram_en = '1') then
			if (s_dpram_addr(1 downto 0) = "00") then
				s_bweb <= "1000";
			elsif (s_dpram_addr(1 downto 0) = "01") then
				s_bweb <= "0100";
			elsif (s_dpram_addr(1 downto 0) = "10") then
				s_bweb <= "0010";
			elsif (s_dpram_addr(1 downto 0) = "11") then
				s_bweb <= "0001";
			end if;

		else
			s_bweb <= "0000";
		end if;
	end process;

SERIAL_bwbe <= s_bweb;

s_dpram_data_out <= SERIAL_data_i(31 downto 24) when s_dpram_addr(1 downto 0) = "00" else
					SERIAL_data_i(23 downto 16) when s_dpram_addr(1 downto 0) = "01" else
					SERIAL_data_i(15 downto 8) when s_dpram_addr(1 downto 0) = "10" else
					SERIAL_data_i(7 downto 0) when s_dpram_addr(1 downto 0) = "11" else
					x"FF";



SERIAL_en <= 	s_dpram_en;	

wb_master_o <= wb_master_output;
wb_master_input <= wb_master_i;
wb_master_output.adr <= s_wbone_addr;
wb_master_output.dat <= r_wishbone_data_in;
wb_master_output.we <= r_wbone_wr;

GEN_DEBUG: if g_debug = true generate


cmp_chipscope_ila_spi2wbm : chipscope_ila
  port map (
    CLK                                    => clk_i,
    probe0                                 => wb_master_output.adr,
    probe1                                 => wb_master_output.dat,
    probe2                                 => wb_master_input.dat,
    
    probe3(0)                              => wb_master_output.cyc,
    probe3(1)                              => wb_master_output.stb,
    probe3(5 downto 2)                     => wb_master_output.sel,
    probe3(6)                              => wb_master_output.we,
    
    probe3(7)                              => wb_master_input.ack,
    probe3(8)                              => wb_master_input.err,
    probe3(9)                              => wb_master_input.rty,
    probe3(10)                             => wb_master_input.stall,
    probe3(11)                             => wb_master_input.int,
    
    probe3(12)                             => r_wbone_address_catched,
    probe3(13)                             => r_wbone_en,
    probe3(14)                             => r_wbone_wr,
    probe3(15)                             => s_latch_data_in,
    probe3(23 downto 16)                   => r_command,
    probe3(24)                             => r_wbone_hit,
    probe3(25)                             => s_latch_data_out,
    probe3(27 downto 26)                   => (others => '1'),
    probe3(28)                             => SDO_synch,
    probe3(29)                             => SCK_synch,
    probe3(30)                             => SDI_synch,
    probe3(31)                             => SCS_synch
);

end generate GEN_DEBUG;

--SERIAL_bwbe   <= (r_dpram_wr and  s_dpram_en = '1' ) & (r_dpram_wr and  s_dpram_en = '1' ) & (r_dpram_wr and  s_dpram_en = '1' ) & (r_dpram_wr and  s_dpram_en = '1' );
--	p_dpram : process(sys_clk_i)
--	begin
--		if rising_edge(sys_clk_i) then
--			if reset = '1' then
--				null;
--			else
--				if r_command = c_CMD_READ_BRAM and r_dpram_address_catched = '0' ; end if;

end architecture;
