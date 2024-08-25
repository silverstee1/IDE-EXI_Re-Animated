--------------------------------------------------------------------------------
--
-- IDE_EXI.vhdl
--
-- Modified firmware for gc-forever.com's IDE-EXI adapter
-- Copyright (C) 2011,2012 Albert Herranz
--
-- Based on EXI_IDE.vhd by Dampro (Damián).
-- See http://www.gc-linux.org/wiki/EXI:IDEHostAdapter
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IDE_EXI is
	port(
		ide_adr : out   std_logic_vector(4 downto 0);	-- /CS0, /CS1, A2..A0
		ide_dat : inout std_logic_vector(15 downto 0);	-- D15..D0
		ide_rd  : out   std_logic;								-- /IOR
		ide_wr  : out   std_logic;								-- /IOW

		exi_in  : in  std_logic;								-- MOSI
		exi_out : out std_logic;								-- MISO
		exi_clk : in  std_logic;								-- CLK
		exi_cs  : in  std_logic	);								-- CS
end IDE_EXI;

architecture behavioral of IDE_EXI is

	-- EXI ID of the IDE-EXI
	constant exi_id : std_logic_vector(31 downto 0) := "01001001010001000100010100110010"; -- "IDE2"

	-- IDE signals
	signal ide_host_adr: std_logic_vector(4 downto 0);
	signal ide_host_dat: std_logic_vector(15 downto 0);
	signal ide_host_rd: std_logic;
	signal ide_host_wr: std_logic;

	-- IDE-EXI internal control signals
	signal exi_ide_adr: std_logic_vector(4 downto 0);	-- same as ide_adr
	signal exi_out_latch: std_logic; -- MISO latch for the next cycle
	signal exi_data0: std_logic_vector(15 downto 0); -- 16-bit data0 word
	signal exi_data1: std_logic_vector(15 downto 0); -- 16-bit data1 word
	signal do_write: std_logic; -- set when writing vs reading
	signal do_16bit: std_logic; -- set when doing 16-bit vs 8-bit ops
	signal do_multi_init: std_logic; -- set on the first cycle of a multi op
	signal multi: std_logic := '0'; -- set when a multi op is in progress
	signal multi_count: std_logic_vector(15 downto 0); -- # of words for a multi op
	
	signal exi_idx: integer range 0 to 31 := 31; -- bit index within a 32-bit exi cycle
	signal do_getid: std_logic := '0'; -- set when a exi_get_id() has been detected
	signal orsum: std_logic := '0'; -- artifact used to detect an exi_get_id()
	
begin -- behavioral

IDE_bus:
	process (ide_host_adr, ide_host_dat, ide_host_rd, ide_host_wr)
	begin
		ide_adr <= ide_host_adr;
		
		if ide_host_wr = '0' then
			ide_dat <= ide_host_dat;
		else
			ide_dat <= (others => 'Z');		
		end if;
		
		ide_rd <= ide_host_rd;
		ide_wr <= ide_host_wr;
	end process;

EXI_bus:
	process(exi_cs, exi_clk)
	begin
		-- 31..24 command phase: direction, size, multi-op, cs1, cs0, a2, a1, a0
		-- 23..16 dummy in read / count lsb in multi / data lsb in write  
		-- 15..8  data lsb in read / count msb in multi / data msb in write16 / skipped in write8
		--  7..0  dummy in write / data msb in read16 / skipped in read8

		if exi_cs = '1' then
			-- when chip select disabled, just Z
			ide_host_adr <= (others => '0');
			ide_dat <= (others => 'Z');  --- ??? ide_host_dat?
			ide_host_rd <= '1';
			ide_host_wr <= '1';
			exi_out <= 'Z';

			exi_idx <= 31;
			multi <= '0';
			do_getid <= '0';
			orsum <= '0';
		else
			-- this outputs the latched value at the falling edge too
			exi_out <= exi_out_latch;

			-- rising edge
			if exi_clk = '1' and exi_clk'event then
			
				if do_getid = '1' then
				
					-- exi_get_id() was detected, we are supplying the EXI ID here
					if exi_idx = 0 then
						exi_idx <= 31;
						do_getid <= '0';
					else
						exi_out_latch <= exi_id(exi_idx-1);
						exi_idx <= exi_idx - 1;
					end if;
					
				else
				
					-- other operations
					case exi_idx is
					when 31 =>
						do_16bit <= '1';
						do_multi_init <= '0';
						if multi = '0' then
							-- IN: direction: read(0), write(1)
							do_write <= exi_in;
							orsum <= orsum or exi_in;
						else
							if do_write = '0' then
								-- (multi-read) prepare output for next cycle
								exi_out_latch <= exi_data1(6); -- 31 (data1 bit 6)
							else
								-- (multi-write) get data bit for this cycle
								exi_data1(15) <= exi_in; -- 31 (data1 bit 15)
							end if;
						end if;

					when 30 =>
						if multi = '0' then
							-- IN: size: 8 bit(0), 16-bit(1)
							do_16bit <= exi_in;
							orsum <= orsum or exi_in;
						else
							if do_write = '0' then
								-- (multi-read) prepare output for next cycle
								exi_out_latch <= exi_data1(5); -- 30 (data1 bit 5)
							else
								-- (multi-write) get data bit for this cycle
								exi_data1(14) <= exi_in; -- 30 (data1 bit 14)
							end if;
						end if;  

					when 29 =>
						if multi = '0' then
							-- IN: multiple: no(0), yes(1)
							do_multi_init <= exi_in;   -- first mult cycle
							multi <= exi_in;
							orsum <= orsum or exi_in;
						else
							if do_write = '0' then
								-- (multi-read) prepare output for next cycle
								exi_out_latch <= exi_data1(4); -- 29 (data1 bit 4)
							else
								-- (multi-write) get data bit for this cycle
								exi_data1(13) <= exi_in; -- 29 (data1 bit 13)
							end if;  
						end if;  
						
					when 28 downto 24 =>
						if multi = '0' then
							-- IN: address: [28:24] 5 bits
							exi_ide_adr <= exi_ide_adr(3 downto 0) & exi_in;
							orsum <= orsum or exi_in;
						else
							do_16bit <= '1'; -- this is actually 32-bit for multi-ops
							exi_ide_adr(4 downto 0)<= "10000";  -- force IDE data register
							
							if do_write = '0' then
								-- (multi-read) prepare output for next cycle
								if exi_idx = 24 then
									exi_out_latch <= exi_data1(15); -- 24 (data1 bit 15)
								else
									exi_out_latch <= exi_data1(exi_idx-25); -- 28..25 (data1 bits 3..0)
								end if;
							else
								-- (multi-write) get data bit for this cycle
								exi_data1(exi_idx-16) <= exi_in; -- 28..24 (data1 bit 12..8)
							end if;
						end if;

					when 23 downto 16 =>
						-- IN: LSB of word count for multi-reads/multi-writes, dummy for reads, LSB of data for writes
						if do_multi_init = '1' then
							-- 8-bit LSB of words to read or write (only in first cycle of multi)
							multi_count(exi_idx-16) <= exi_in; -- 7..0 / LSB
						else
							if do_write = '0' then
								-- (read or multi-read) generate RD pulse and get data0 from IDE bus
								if exi_idx >= 20 then
									ide_host_rd <= '0';	 	-- init rd pulse (4 cycles)
								else
									exi_data0 <= ide_dat; 	-- get data from IDE bus
									ide_host_rd <='1'; 		-- end rd pulse
								end if;

								-- (read or multi-read) prepare output for next cycle
								if exi_idx = 16 then
									exi_out_latch <= exi_data0(7); -- 16 (data0 bit 7)
								else
									exi_out_latch <= exi_data1(exi_idx-9); -- 23..17 (data1 bits 14..8)
								end if;
								orsum <= orsum or exi_in;
							else
								-- (write or multi-write) get data bit for this cycle
								exi_data0(exi_idx-16) <= exi_in; -- 23..16 (data0 bit 7..0)

								if multi = '1' then
									-- (multi-write) put data1 into IDE bus and generate WR pulse
									if exi_idx >= 20 then
										ide_host_dat <= exi_data1;	-- put data into IDE bus
										ide_host_wr <= '0';			-- init wr pulse (4 cycles)
									else
										ide_host_wr <='1';			-- end wr pulse
									end if;
								end if;
							end if;
						end if;

					when 15 downto 8 => 
						-- IN: MSB of word count for multi-reads/multi-writes, dummy for reads, MSB of data for writes
						if do_multi_init = '1' then
							-- 8-bit MSB of words to read or write (only in first cycle of multi)
							multi_count(exi_idx) <= exi_in; -- 15..8 / MSB
						else
							if do_write = '0' then
								-- (read or multi-read) prepare output for next cycle
								if exi_idx = 8 then
									exi_out_latch <= exi_data0(15); -- 8 (data0 bit 15)
								else
									exi_out_latch <= exi_data0(exi_idx-9); -- 15..9 (data0 bits 6..0)
								end if;
							else
								-- (write or multi-write) get data bit for this cycle
								exi_data0(exi_idx) <= exi_in; -- 15..8 (data0 bit 15..8)
							end if;
						end if;

					when 7 downto 0 =>
						-- 
						if do_write = '0' then
							if multi = '1' then
								-- (multi-read) generate RD pulse and get data1 from IDE bus
								if exi_idx >= 4 then
									ide_host_rd <= '0';	 	-- init rd pulse (4 cycles)
								else
									exi_data1 <= ide_dat; 	-- get data from IDE bus
									ide_host_rd <='1'; 		-- end rd pulse
								end if;
							end if;

							-- (read or multi-read) prepare output for next cycle
							if exi_idx = 0 then
								exi_out_latch <= exi_data1(7); -- 0 (data1 bit 7)
							else
								exi_out_latch <= exi_data0(exi_idx+7); -- 7..1 (data0 bits 14..8)
							end if;
						else
							if multi = '1' then
								-- (multi-write) get data bit for this cycle
								exi_data1(exi_idx) <= exi_in; -- 7..0 (data1 bits 7..0)
							end if;
							
							if do_multi_init = '0' then
								-- (write or write multiple) put data0 into IDE bus and generate WR pulse
								if exi_idx >= 4 then
									ide_host_dat <= exi_data0;	-- put data into IDE bus
									ide_host_wr <= '0';			-- init wr pulse (4 cycles)
								else
									ide_host_wr <='1';			-- end wr pulse
								end if;
							end if;
						end if;

					when others => NULL;
					
					end case;
				
					exi_idx <= exi_idx - 1;

					-- multi op accounting
					if exi_idx = 0 and multi = '1' then
						exi_idx <= 31;
						multi_count <= multi_count - '1'; -- decrement word count
						if multi_count = x"0" then
							multi <= '0'; -- finish multi operation
						end if;
					end if;

					-- special case for 8-bit writes
					if exi_idx = 16 and do_16bit = '0' and do_write = '1' then
						exi_idx <= 7; -- skip 15..8 phase
					end if;

					-- this marks the detection of a exi_get_id() op
					if exi_idx = 16 and orsum = '0' and exi_in = '0' then
						do_getid <= '1';
						exi_idx <= 31;
						exi_out_latch <= exi_id(31);
					end if;

				end if; -- do_getid = '1'
			
			end if; -- exi_clk = '1' and exi_clk'event

			ide_host_adr <= exi_ide_adr(4 downto 0);

		end if; -- exi_cs = '1'
	
	end process;

end behavioral;
