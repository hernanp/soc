library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use work.defs.all;

entity b_arbiter6 is
    Port (
            clock: in std_logic;
            reset: in std_logic;
            
            din1: 	in BMSG_T;
            ack1: 	out STD_LOGIC;
            
            din2:	in BMSG_T;
            ack2:	out std_logic;
            
            din3:	in BMSG_T;
            ack3:	out std_logic;
            
            din4:	in BMSG_T;
            ack4:	out std_logic;
            
            din5:	in BMSG_T;
            ack5:	out std_logic;
            
            din6:	in BMSG_T;
            ack6:	out std_logic;
            
            dout:	out BMSG_T
     );
end b_arbiter6;

-- version 2
architecture rtl of b_arbiter6 is

    signal s_ack1, s_ack2,s_ack3,s_ack4, s_ack5,s_ack6 : std_logic;
    signal s_token : integer :=0;
		
begin  
 	process (reset, clock)
        variable nilreq : BMSG_T := ZERO_BMSG;
    begin
        if reset = '1' then
        	s_token <= 0;
        	s_ack1 <= '0';
        	s_ack2 <= '0';
        	s_ack3 <= '0';
        	s_ack4 <= '0';
        	s_ack5 <= '0';
        	s_ack6 <= '0';
        	dout <=  nilreq;
        elsif rising_edge(clock) then
        	dout <= nilreq;
            s_ack1 <= '0';
            s_ack2 <= '0';   
            s_ack3 <= '0'; 
            s_ack4 <= '0';
            s_ack5 <= '0';   
            s_ack6 <= '0'; 
            if din1.val = '1' then
            	if s_ack1 = '0' then
                    dout <= din1;
                    s_ack1 <= '1';
                end if; 
            elsif din2.val = '1' then
            	if s_ack2 = '0' then
                    dout <= din2;
                    s_ack2 <= '1';
                end if; 
         	elsif din3.val = '1' then
            	if s_ack3 = '0' then
                    dout <= din3;
                    s_ack3 <= '1';
                end if; 
            elsif din4.val = '1' then
            	if s_ack4 = '0' then
                    dout <= din4;
                    s_ack4 <= '1';
                end if; 
            elsif din5.val = '1' then
            	if s_ack5 = '0' then
                    dout <= din5;
                    s_ack5 <= '1';
                end if; 
            elsif din6.val = '1' then
            	if s_ack6 = '0' then
                    dout <= din6;
                    s_ack6 <= '1';
                end if; 
            end if;
        end if;
        ack1 <= s_ack1;
        ack2 <= s_ack2;
        ack3 <= s_ack3;
        ack4 <= s_ack4;
        ack5 <= s_ack5;
        ack6 <= s_ack6;
    end process;
end architecture rtl;   
