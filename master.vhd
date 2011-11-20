-- Quartus II VHDL program
-- RS232 receiver/ Serial to parallel Converter
-- Author: Kiran Jose
-- Web: www.kiranjose.com
-- 9600 baud rate
-- bugs: we need to set data bits transmitted in pc as 7 otherwise bit 8 toggles initially[]

library ieee;
use ieee.std_logic_1164.all;

entity master is 
	generic
	(
		NUM_STAGES : natural := 8
	);
  
	port
	(
		rxd  				: in std_logic;
		txd  				: out std_logic;
		cts  				: buffer std_logic;
		rts                 : in std_logic;
		parallel_data  	    : out std_logic_vector(9 downto 0);
		clk  				: in std_logic
	);
end entity;

architecture rtl of master is
	--shift register array
	type sr_len is array ((NUM_STAGES-1) downto 0) of std_logic;
	--Declare the shift register signal
	signal shift_register: sr_len;
	signal parallel_data_signal: std_logic_vector(9 downto 0);
	
begin
	process (clk)
	variable clk_count : integer :=0;	
	variable bit_count : integer :=0;		 
	variable start : integer :=0;			 
	variable clear : integer :=0;	
	variable start_flag : integer :=0;		 
	begin
		if (rising_edge(clk)) then
			--counting starts when receive line goes low (start bit).
			if (rxd= '0') then
				--start_flag is used to start counting clock pulse
				start_flag:=1;
			end if;
			if (start_flag = 1) then
				--since start_flag is set, clk_count continues counting
				--it will continue until start_flag is set to 0
				clk_count:= clk_count+1;
			end if;
			if(clk_count = 2604) then --2604 for 9600 baud
				--means time to sample 9600 serial data
				--at 2604 times 50MHz clock cycle from the start of the start bit
				--the time is correct to sample at middle point of the received pulse
				if(bit_count < 10) then
					--the received data in 10 bit with start and stop bit
					--so only take first 10 samples from once the start_flag is set
					parallel_data_signal(bit_count) <= rxd;
					--after sampling bit_count is incremented
					bit_count:=bit_count+1;
				elsif(bit_count = 10) then
					--coupling data to output onall the 10 bits are captured
				    parallel_data <= parallel_data_signal;
					--once the 10 bits are captured, the start_flag is reset
					start_flag:=0;
					--bit_count is reset to 0
					bit_count:=0;
					--reseting clk_count
					clk_count:=0;
				end if;
				
			elsif(clk_count = 5208) then --5208 for 9600 baud
				--5208 clock pulse at 50MHz is the time for single serial pulse
				--the clk_count is reset to start for the next serial pulse
				clk_count:=0;
			end if;
	
				-- Shift data to the previous stage
				shift_register((NUM_STAGES-1) downto 1) <= shift_register((NUM_STAGES-2) downto 0);
				-- first stage of shift register will be the new data received
				shift_register(0) <= rxd;
				-- output data from the final stage
				txd <= shift_register(NUM_STAGES-1); 
			 
		end if;
    end process;
end rtl;

