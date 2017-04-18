library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;
use work.test.all;
use work.rand.all;
use work.util.all;

entity peripheral is
  Port(Clock      : in  std_logic;
       reset      : in  std_logic;
       ---write address chanel
       waddr      : in  std_logic_vector(31 downto 0);
       wlen       : in  std_logic_vector(9 downto 0);
       wsize      : in  std_logic_vector(9 downto 0);
       wvalid     : in  std_logic;
       wready     : out std_logic;
       ---write data channel
       wdata      : in  std_logic_vector(31 downto 0);
       wtrb       : in  std_logic_vector(3 downto 0);
       wlast      : in  std_logic;
       wdvalid    : in  std_logic;
       wdataready : out std_logic;
       ---write response channel
       wrready    : in  std_logic;
       wrvalid    : out std_logic;
       wrsp       : out std_logic_vector(1 downto 0);

       ---read address channel
       raddr      : in  std_logic_vector(31 downto 0);
       rlen       : in  std_logic_vector(9 downto 0);
       rsize      : in  std_logic_vector(9 downto 0);
       rvalid     : in  std_logic;
       rready     : out std_logic;
       ---read data channel
       rdata       : out std_logic_vector(31 downto 0);
       rstrb       : out std_logic_vector(3 downto 0);
       rlast       : out std_logic;
       rdvalid     : out std_logic;
       rdready     : in  std_logic;
       rres        : out std_logic_vector(1 downto 0);
       pwr_req_in  : in  std_logic_vector(2 downto 0);
       pwr_res_out : out std_logic_vector(2 downto 0);
       
       
       upreq_out  : out std_logic_vector(72 downto 0);
       upres_in   : in  std_logic_vector(72 downto 0);
       upreq_full : in  std_logic
       );
end peripheral;

architecture Behavioral of peripheral is
  type ram_type is array (0 to natural(2 ** 5 - 1) - 1) of std_logic_vector(31 downto 0);
  signal ROM_array : ram_type  := (others => (others => '0'));
  signal poweron   : std_logic := '1';

  signal emp3, emp2 : std_logic := '0';
  signal tmp_req : std_logic_vector(50 downto 0);

begin
  
--	p1 : process
--		variable nilreq : std_logic_vector(50 downto 0) := (others => '0');
--
--		variable zero  : std_logic_vector(31 downto 0) := "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000";
--		variable one   : std_logic_vector(31 downto 0) := "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0001";
--		variable two   : std_logic_vector(31 downto 0) := "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0010";
--		variable rand1 : integer                       := 1;
--		variable rand2 : std_logic_vector(15 downto 0) := "0101010101010111";
--		variable rand3 : std_logic_vector(31 downto 0) := "10101010101010101010101010101010";
--
--	begin
--		--    	wait for 70 ps;
--
--		---power(pwrcmd, tmp_req, hwlc);
--		--for I in 1 to 1 loop
--			rand1 := selection(2); -- TODO replace all calls "selection" in this file by rand_int, etc...
--			rand2 := '0' & selection(2 ** 2 - 1, 3) & "111111000000";
--			rand3 := selection(2 ** 15 - 1, 32);
--			rand2 := "0110101010101010";
--		---if rand1=1 then
--		---    write(rand2,tmp_req,rand3);
--		---else
--		--	   wait for 370 ps;
--		--  write(rand2,tmp_req,rand3);
--
--		---end if;
--
--		--end loop;
--
----		wait;
--
--	end process;
--
  write_req_handler : process(Clock, reset)
    variable address : integer;
    variable len     : integer;
    variable size    : std_logic_vector(9 downto 0);
    variable state   : integer := 0;
    variable lp      : integer := 0;
  begin
    if reset = '1' then
      wready     <= '1';
      wdataready <= '0';
    elsif (rising_edge(Clock)) then
      if state = 0 then
        wrvalid <= '0';
        wrsp    <= "10";
        if wvalid = '1' then
          wready     <= '0';
          address    := to_integer(unsigned(waddr(31 downto 29)));
          len        := to_integer(unsigned(wlen));
          size       := wsize;
          state      := 2;
          wdataready <= '1';
        end if;

      elsif state = 2 then
        if wdvalid = '1' then
          ---not sure if lengh or length -1
          if lp < len - 1 then
            wdataready              <= '0';
            ---strob here is not considered
            ROM_array(address + lp) <= wdata(31 downto 0);
            lp                      := lp + 1;
            wdataready              <= '1';
            if wlast = '1' then
              state := 3;
            end if;
          else
            state := 3;
          end if;

        end if;
      elsif state = 3 then
        if wrready = '1' then
          wrvalid <= '1';
          wrsp    <= "00";
          state   := 0;
        end if;
      end if;
    end if;
  end process;
--
  read_req_handler : process(Clock, reset)
    variable address : integer;
    variable len     : integer;
    variable size    : std_logic_vector(9 downto 0);
    variable state   : integer := 0;
    variable lp      : integer := 0;
    variable dt      : std_logic_vector(31 downto 0);
  begin
    if reset = '1' then
      rready  <= '1';
      rdvalid <= '0';
      rstrb   <= "1111";
      rlast   <= '0';
      address := 0;
    elsif (rising_edge(Clock)) then
      if state = 0 then
        lp := 0;
        if rvalid = '1' then
          rready  <= '0';
          address := to_integer(unsigned(raddr(31 downto 29)));
          len     := to_integer(unsigned(rlen));
          size    := rsize;
          state   := 2;
        end if;

      elsif state = 2 then
        if rdready = '1' then
          if lp < 16 then
            rdvalid <= '1';
            ---strob here is not considered
            ---left alone , dono how to fix
            ---if ROM_array(address+lp) ="00000000000000000000000000000000" then
            ---ROM_array(address+lp) := selection(2**15-1,32);
            ---end if;
            --dt      := selection(2 ** 15 - 1, 32);
            ---rdata <= dt;
            rdata   <= ROM_array(address);
            lp      := lp + 1;
            rres    <= "00";
            if lp = len then
              state := 3;
              rlast <= '1';
            end if;
          else
            state := 3;
          end if;

        end if;
      elsif state = 3 then
        rdvalid <= '0';
        rready  <= '1';
        rlast   <= '0';
        state   := 0;
      end if;
    end if;
  end process;

  pwr_req_handler : process(Clock)
  begin
    if reset = '1' then
      pwr_res_out <= (others => '0');

    elsif (rising_edge(Clock)) then
      if pwr_req_in(2 downto 2) = "1" then
        if pwr_req_in(1 downto 0) = "00" then
          poweron <= '0';
        elsif (pwr_req_in(1 downto 0) = "11" or
               pwr_req_in(1 downto 0) = "10") then
          poweron <= '1';
        end if;
        pwr_res_out <= pwr_req_in;
      else
        pwr_res_out <= "000";
      end if;

    end if;
  end process;

  t1 : process(clock, reset) -- up read test
    variable ct : natural;
    variable st : natural := 0;
  begin
    if is_tset(RND1_TEST) then
      if reset = '1' then
        upreq_out <= (others => '0');
        ct := rand_nat(to_integer(unsigned(RND1_TEST)));
        --ct := rand_int(RAND_MAX_DELAY, to_int(ct'instance_name),
        --        to_integer(unsigned(GFX_R_TEST)));
        st := 0;
      elsif(rising_edge(clock)) then
        if st = 0 then -- wait
          delay(ct, st, 1);
        elsif st = 1 then -- snd up_req 
          report "rnd1_test @ " & integer'image(time'pos(now));
          upreq_out <= '1' &
                       READ_CMD &
                       "1000000000000000" &
                       "1000000000000000" &
                       ZEROS32;
          st := 2;
        elsif st = 2 then -- done
          upreq_out <= (others => '0');
        end if;
      end if;
    end if;
  end process;  
end Behavioral;