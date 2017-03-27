library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use iEEE.std_logic_unsigned.all ;
USE ieee.numeric_std.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity l1_cache is
  Port(
    Clock                : in  std_logic;
    reset                : in  std_logic;
    cpu_req              : in  STD_LOGIC_VECTOR(72 downto 0);
    snoop_req            : in  STD_LOGIC_VECTOR(72 downto 0);
    bus_res              : in  STD_LOGIC_VECTOR(552 downto 0);
    --01: read response
    --10: write response
    --11: fifo full response
    cpu_res              : out STD_LOGIC_VECTOR(72 downto 0) := (others => '0');
    --01: read response 
    --10: write response
    --11: fifo full response
    snoop_hit            : out std_logic;
    snoop_res            : out STD_LOGIC_VECTOR(72 downto 0) := (others => '0');

    --goes to cache controller ask for data
    snoop_c_req          : out std_logic_vector(72 downto 0);
    snoop_c_res          : in  std_logic_vector(72 downto 0);
    snoop_c_hit          : in  std_logic;
    up_snoop             : in  std_logic_vector(75 downto 0);
    up_snoop_res         : out std_logic_vector(75 downto 0);
    up_snoop_hit         : out std_logic;
    wb_req               : out std_logic_vector(552 downto 0);
    --01: read request
    --10: write request
    --10,11: write back function
    full_cprq            : out std_logic := '0';
    full_srq             : out std_logic := '0';
    full_brs             : out std_logic := '0';
    full_crq, full_wb, full_srs : in  std_logic;
    cache_req            : out STD_LOGIC_VECTOR(72 downto 0) := (others => '0')
	);

end l1_cache;

architecture Behavioral of l1_cache is
  --IMB cache 1
  --3 lsb: dirty bit, valid bit, exclusive bit
  --cache hold valid bit ,dirty bit, exclusive bit, 6 bits tag, 32 bits data,
  --41 bits in total
  type rom_type is
    array (natural(2 ** 14 - 1) downto 0) of std_logic_vector(56 downto 0);
  signal ROM_array                      : rom_type  := (others => (others => '0'));
  signal we1, we2, we3, we4, re1, re2, re3, re4, re5, we5 : std_logic := '0';
  signal out1, out2, out3, out5         : std_logic_vector(72 downto 0);
  signal out4, in4                      : std_logic_vector(75 downto 0);
  signal emp1, emp2, emp3, emp4, emp5,ful4, ful5: std_logic := '0';
  signal mem_req1, mem_req2, write_req  : std_logic_vector(72 downto 0);
  signal mem_req3, mem_res3             : std_logic_vector(75 downto 0);
  signal mem_ack3                       : std_logic;
  signal mem_req2_1, mem_req2_2         : std_logic_vector(72 downto 0);
  signal mem_req2_ack1, mem_req2_ack2   : std_logic;
  signal upd_req, in3                   : std_logic_vector(552 downto 0);
  signal mem_res1, wt_res, upd_res      : std_logic_vector(71 downto 0);
  signal mem_res2                       : std_logic_vector(71 downto 0);
  signal hit1, hit2, hit3, upd_ack, write_ack, mem_ack1, mem_ack2 : std_logic;
  signal in1, in2, in5                  : std_logic_vector(72 downto 0);
  signal cpu_res1, cpu_res2             : std_logic_vector(72 downto 0);
  signal ack1, ack2                     : std_logic;
  signal snp_c_req1, snp_c_req2         : std_logic_vector(72 downto 0);
  signal snp_c_ack1, snp_c_ack2         : std_logic;

  signal prc          : std_logic_vector(1 downto 0);
  signal tmp_cpu_res1 : std_logic_vector(72 downto 0) := (others => '0');
  signal tmp_snp_res  : std_logic_vector(72 downto 0);
  signal tmp_hit      : std_logic;
  signal tmp_mem      : std_logic_vector(40 downto 0);
  ---this one is important!!!!
  signal upreq        : std_logic_vector(75 downto 0);
  signal snpreq       : std_logic_vector(73 downto 0);

begin
  cpu_req_fif : entity work.fifo(Behavioral)
    generic map(
      DATA_WIDTH => 73,
      FIFO_DEPTH => 256
      )
    port map(
      CLK     => Clock,
      RST     => reset,
      DataIn  => in1,
      WriteEn => we1,
      ReadEn  => re1,
      DataOut => mem_req1,
      Full    => full_cprq,
      Empty   => emp1
      );
  snp_res_fif : entity work.fifo(Behavioral)
    generic map(
      DATA_WIDTH => 73,
      FIFO_DEPTH => 256
      )
    port map(
      CLK     => Clock,
      RST     => reset,
      DataIn  => in5,
      WriteEn => we5,
      ReadEn  => re5,
      DataOut => out5,
      Full    => ful5,
      Empty   => emp5
      );
  up_snp_req_fif : entity work.fifo(Behavioral)
    generic map(
      DATA_WIDTH => 76,
      FIFO_DEPTH => 256
      )
    port map(
      CLK     => Clock,
      RST     => reset,
      DataIn  => in4,
      WriteEn => we4,
      ReadEn  => re4,
      DataOut => mem_req3,
      Full    => ful4,
      Empty   => emp4
      );
  snp_req_fif : entity work.fifo(Behavioral)
    generic map(
      DATA_WIDTH => 73,
      FIFO_DEPTH => 256
      )
    port map(
      CLK     => Clock,
      RST     => reset,
      DataIn  => in2,
      WriteEn => we2,
      ReadEn  => re2,
      DataOut => out2,
      Full    => full_srq,
      Empty   => emp2
      );
  bus_res_fif : entity work.fifo(Behavioral)
    generic map(
      DATA_WIDTH => 553,
      FIFO_DEPTH => 256
      )
    port map(
      CLK     => Clock,
      RST     => reset,
      DataIn  => in3,
      WriteEn => we3,
      ReadEn  => re3,
      DataOut => upd_req,
      Full    => full_brs,
      Empty   => emp3
      );
  cpu_res_arbitor : entity work.arbiter2(Behavioral)
    port map(
      clock => Clock,
      reset => reset,
      din1  => cpu_res1,
      ack1  => ack1,
      din2  => cpu_res2,
      ack2  => ack2,
      dout  => cpu_res
      );
  snp_c_req_arbitor : entity work.arbiter2(Behavioral)
    port map(
      clock => Clock,
      reset => reset,
      din1  => snp_c_req1,
      ack1  => snp_c_ack1,
      din2  => snp_c_req2,
      ack2  => snp_c_ack2,
      dout  => snoop_c_req
      );

  mem_req2_arbitor : entity work.arbiter2(Behavioral)
    port map(
      clock => Clock,
      reset => reset,
      din1  => mem_req2_1,
      ack1  => mem_req2_ack1,
      din2  => mem_req2_2,
      ack2  => mem_req2_ack2,
      dout  => mem_req2
      );
  -- Store CPU requests into fifo	
  cpu_req_fifo : process(Clock)
  begin
    if reset = '1' then
      we1 <= '0';
    elsif rising_edge(Clock) then
      if cpu_req(72 downto 72) = "1" then
        in1 <= cpu_req;
        we1 <= '1';
      else
        we1 <= '0';
      end if;
    end if;
  end process;

  snp_req_fifo : process(Clock)
  begin
    if reset = '1' then
      we2 <= '0';

    elsif rising_edge(Clock) then
      if (snoop_req(72 downto 72) = "1") then
        in2 <= snoop_req;
        we2 <= '1';
      else
        we2 <= '0';
      end if;
    end if;
  end process;

  bus_res_fifo : process(Clock)
  begin
    if reset = '1' then
      we3 <= '0';

    elsif rising_edge(Clock) then
      if (bus_res(552 downto 552) = "1") then
        in3 <= bus_res;
        we3 <= '1';
      else
        we3 <= '0';
      end if;
    end if;
  end process;

  cpu_req_p : process(reset, Clock)
    variable nilreq : std_logic_vector(72 downto 0) := (others => '0');
    variable state  : integer                       := 0;
  begin
    if (reset = '1') then
      -- reset signals
      cpu_res1  <= nilreq;
      write_req <= nilreq;
      cache_req <= nilreq;
    --tmp_write_req <= nilreq;
    elsif rising_edge(Clock) then
      if state = 0 then
        cache_req <= nilreq;

        if re1 = '0' and emp1 = '0' then
          re1   <= '1';
          state := 1;
        end if;

      elsif state = 1 then
        re1 <= '0';
        if mem_ack1 = '1' then
          if hit1 = '1' then
            if mem_res1(71 downto 64) = "10000000" then
              write_req    <= '1' & mem_res1;
              tmp_cpu_res1 <= '1' & mem_res1;
              state        := 3;
            else
              cpu_res1 <= '1' & mem_res1;
              state    := 4;
            end if;
          else
            snp_c_req1 <= '1' & mem_res1;
            --snpreq     <= '1' & mem_res1;
            state      := 5;
          end if;
        end if;

      elsif state = 3 then
        if write_ack = '1' then
          write_req <= nilreq;
          cpu_res1  <= tmp_cpu_res1;
          state     := 4;
        end if;
      elsif state = 4 then
        if ack1 = '1' then
          cpu_res1 <= nilreq;
          state    := 0;
        end if;
      elsif state = 5 then
        if snp_c_ack1 = '1' then
          snp_c_req1 <= (others => '0');
          state      := 6;
        end if;
      --now we wait for the snoop response
      elsif state = 6 then
        if snoop_c_res(72 downto 72) = "1" then
          --if we get a snoop response  and the address is the same  => 
          if snoop_c_res(63 downto 32) = snpreq(63 downto 32) then
            if snoop_c_hit = '1' then
              state    := 4;
              cpu_res1 <= snoop_c_res;
            else
              cache_req <= snoop_c_res;
              state     := 0;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  ---deal with snoop request from bus,
  --the difference is that when it's  uprequest snoop, once it fails,
  --it will go to the other cache snoop
  --also when found, the write will be operated here directly, and return
  --nothing
  --if it's read, then the data will be returned to request source
  up_snp_req_p : process(reset, Clock)
    variable state : integer := 0;
  begin
    if (reset = '1') then
      state        := 0;
      up_snoop_res <= (others => '0');
      up_snoop_hit <= '1';
    elsif rising_edge(Clock) then
      if state = 0 then
        up_snoop_res <= (others => '0');
        up_snoop_hit <= '0';
        if re4 = '0' and emp4 = '0' then
          re4   <= '1';
          state := 1;
        end if;
      elsif state = 1 then
        re4 <= '0';
        if mem_ack3 = '1' then
          if hit3 = '1' then
            up_snoop_res <= mem_res3;
            up_snoop_hit <= '1';
            state        := 0;
          else
            snp_c_req2 <= mem_res3(72 downto 0);
            upreq      <= mem_res3;
            state      := 2;
          end if;
        end if;
      elsif state = 2 then
        if snp_c_ack2 = '1' then
          snp_c_req2 <= (others => '0');
          state      := 3;
        end if;
      elsif state = 3 then
        if snoop_c_res(72 downto 72) = "1" then
          --if we get a snoop response  and the address is the same  => 
          if snoop_c_res(63 downto 32) = upreq(63 downto 32) then
            up_snoop_res <= upreq(75 downto 73) & snoop_c_res;
            up_snoop_hit <= snoop_c_hit;
          end if;
        end if;
      end if;
    end if;

  end process;
  --deal with snoop request
  snp_req_p : process(reset, Clock)
    variable nilreq1 : std_logic_vector(552 downto 0) := (others => '0');
    variable addr    : std_logic_vector(31 downto 0);
    variable state   : integer                        := 0;
  begin
    if (reset = '1') then
      -- reset signals
      snoop_res <= (others => '0');
      snoop_hit <= '0';
    elsif rising_edge(Clock) then
      if state = 0 then
        snoop_res <= (others => '0');
        if re2 = '0' and emp2 = '0' then
          re2   <= '1';
          state := 1;
        end if;
      elsif state = 1 then
        re2 <= '0';
        if out2(72 downto 72) = "1" then
          mem_req2_1 <= out2;
          addr       := out2(63 downto 32);
          state      := 3;
        end if;
      elsif state = 3 then
        if mem_req2_ack1 = '1' then
          mem_req2_1 <= (others => '0');
          state      := 4;
        end if;
      elsif state = 4 then
        if mem_ack2 = '1' and mem_res2(63 downto 32) = addr then
          tmp_snp_res <= '1' & mem_res2;
          tmp_hit     <= hit2;
          state       := 2;
        end if;
      elsif state = 2 then
        if full_srs = '0' then
          snoop_hit <= tmp_hit;
          snoop_res <= tmp_snp_res;
          state     := 0;
        end if;
      end if;
    end if;
  end process;

  ---deal with bus response
  bus_res_p : process(reset, Clock)
    variable nilreq : std_logic_vector(72 downto 0) := (others => '0');
    variable state  : integer                       := 0;
  begin
    if reset = '1' then
      -- reset signals
      cpu_res2 <= nilreq;
    --upd_req <= nilreq;
    elsif rising_edge(Clock) then
      if state = 0 then
        if re3 = '0' and emp3 = '0' then
          re3   <= '1';
          state := 1;
        end if;
      elsif state = 1 then
        re3 <= '0';
        if upd_ack = '1' then
          cpu_res2 <= '1' & upd_res;
          state    := 2;
        end if;
      elsif state = 2 then
        if ack2 = '1' then
          cpu_res2 <= nilreq;
          state    := 0;
        end if;
      end if;

    end if;
  end process;

  --deal with cache memory
  mem_control_unit : process(reset, Clock)
    variable indx    : integer;
    variable memcont : std_logic_vector(56 downto 0);
    variable nilreq  : std_logic_vector(72 downto 0)  := (others => '0');
    variable nilreq2 : std_logic_vector(552 downto 0) := (others => '0');
    variable shifter : boolean                        := false;
  begin
    if (reset = '1') then
      -- reset signals;
      mem_res1  <= (others => '0');
      mem_res2  <= (others => '0');
      write_ack <= '0';
      upd_ack   <= '0';
    elsif rising_edge(Clock) then
      mem_res1  <= nilreq(71 downto 0);
      mem_res2  <= nilreq(71 downto 0);
      write_ack <= '0';
      upd_ack   <= '0';
      wb_req    <= nilreq2;
      if mem_req1(72 downto 72) = "1" then
        indx    := to_integer(unsigned(mem_req1(45 downto 32)));
        memcont := ROM_array(indx);
        --if we can't find it in memory
        if memcont(56 downto 56) = "0" or
          (mem_req1(71 downto 64) = "10000000" and
           memcont(54 downto 54) = "0") or
          mem_req1(71 downto 64) = "11000000"
          or memcont(53 downto 32) /= mem_req1(63 downto 42) then
          mem_ack1 <= '1';
          hit1     <= '0';
          mem_res1 <= mem_req1(71 downto 0);
        else
          mem_ack1 <= '1';
          hit1     <= '1';
          if mem_req1(71 downto 64) = "10" then
            mem_res1 <= mem_req1(71 downto 0);
          else
            mem_res1 <= mem_req1(71 downto 32) & memcont(31 downto 0);
          end if;
        end if;
      else
        mem_ack1 <= '0';
      end if;

      if mem_req2(72 downto 72) = "1" then
        indx    := to_integer(unsigned(mem_req2(45 downto 32)));
        memcont := ROM_array(indx);
        -- if we can't find it in memory
        if memcont(56 downto 56) = "0" or
          memcont(53 downto 32) /= mem_req2(63 downto 42) then
          mem_ack2 <= '1';
          hit2     <= '0';
          mem_res2 <= mem_req2(71 downto 0);
        else
          mem_ack2 <= '1';
          hit2     <= '1';
          --if it's write, invalidate the cache line
          if mem_req2(71 downto 64) = "10000000" then
            ROM_array(indx)(56)          <= '0';
            ROM_array(indx)(31 downto 0) <= mem_req2(31 downto 0);
            mem_res2                     <= mem_req2(71 downto 32) &
                                            ROM_array(indx)(31 downto 0);
          else
            --if it's read, mark the exclusive as 0
            ROM_array(indx)(54) <= '0';
            mem_res2            <= mem_req2(71 downto 32) &
                                   ROM_array(indx)(31 downto 0);
          end if;

        end if;
      else
        mem_ack2 <= '0';
      end if;

      if mem_req3(72 downto 72) = "1" then
        indx    := to_integer(unsigned(mem_req3(45 downto 32)));
        memcont := ROM_array(indx);
        -- if we can't find it in memory
        --invalide  ---or tag different
        --or its write, but not exclusive
        if memcont(56 downto 56) = "0" or
          (mem_req1(71 downto 64) = "10000000" and
           memcont(54 downto 54) = "0") or
          memcont(53 downto 32) /= mem_req3(63 downto 42) then
          mem_ack3 <= '1';
          hit3     <= '0';
          mem_res3 <= mem_req3;
        else
          mem_ack3 <= '1';
          hit3     <= '1';
          --if it's write, write it directly
          -----this need to be changed
          if mem_req3(71 downto 64) = "10000000" then
            ROM_array(indx)(56)          <= '0';
            ROM_array(indx)(31 downto 0) <= mem_req3(31 downto 0);
            mem_res3                     <= mem_req3(75 downto 32) &
                                            ROM_array(indx)(31 downto 0);
          else
            --if it's read, mark the exclusive as 0
            ---not for this situation, because it is shared by other ips
            ---ROM_array(indx)(54) <= '0';
            mem_res3 <= mem_req3(75 downto 32) & ROM_array(indx)(31 downto 0);
          end if;

        end if;
      else
        mem_ack3 <= '0';
      end if;
      --first deal with write request from cpu_request
      --the write is only sent here if the data exist in cahce memory

      -- Handling CPU write request (no update req from bus)
      if write_req(72 downto 72) = "1" and upd_req(552 downto 552) = "0" then
        indx            := to_integer(unsigned(write_req(45 downto 32)));
        ROM_array(indx) <= "110" & write_req(63 downto 42) &
                           write_req(31 downto 0);
        write_ack       <= '1';
        upd_ack         <= '0';
        wt_res          <= write_req(71 downto 0);

      -- Handling update request (no write_req from CPU)
      elsif upd_req(552 downto 552) = "1" and write_req(72 downto 72) = "0" then
        indx    := to_integer(unsigned(upd_req(525 downto 508))) * 16;
        memcont := ROM_array(indx);
        --if tags do not match, dirty bit is 1,
        -- and write_back fifo in BUS is not full,
        if memcont(56 downto 56) = "1" and
          memcont(55 downto 55) = "1" and
          memcont(53 downto 32) /= upd_req(63 downto 42) and
          full_wb /= '1' then
          wb_req <= "110000000" & upd_req(63 downto 32) &
                    memcont(31 downto 0) &
                    ROM_array(indx + 1)(31 downto 0) &
                    ROM_array(indx + 2)(31 downto 0) &
                    ROM_array(indx + 3)(31 downto 0) &
                    ROM_array(indx + 4)(31 downto 0) &
                    ROM_array(indx + 5)(31 downto 0) &
                    ROM_array(indx + 6)(31 downto 0) &
                    ROM_array(indx + 7)(31 downto 0) &
                    ROM_array(indx + 8)(31 downto 0) &
                    ROM_array(indx + 9)(31 downto 0) &
                    ROM_array(indx + 10)(31 downto 0) &
                    ROM_array(indx + 11)(31 downto 0) &
                    ROM_array(indx + 12)(31 downto 0) &
                    ROM_array(indx + 13)(31 downto 0) &
                    ROM_array(indx + 14)(31 downto 0) &
                    ROM_array(indx + 15)(31 downto 0);
        end if;
        ROM_array(indx) <= "100" & upd_req(63 downto 42) & upd_req(31 downto 0);
        upd_ack         <= '1';
        upd_res         <= upd_req(71 downto 0);
        write_ack       <= '0';
      elsif upd_req(552 downto 552) = "1" and write_req(72 downto 72) = "1" then
        if shifter = true then
          shifter         := false;
          indx            := to_integer(unsigned(write_req(45 downto 32)));
          ROM_array(indx) <= "110" & write_req(63 downto 42) &
                             write_req(31 downto 0);
          write_ack       <= '1';
          upd_ack         <= '0';
          wt_res          <= write_req(71 downto 0);
        else
          shifter := true;
          indx    := to_integer(unsigned(upd_req(525 downto 512))) / 16 * 16;
          memcont := ROM_array(indx);
          --if tags do not match, dirty bit is 1, and write_back fifo in BUS is not full, 
          if memcont(56 downto 56) = "1" and
            memcont(53 downto 32) /= upd_req(63 downto 42) and
            full_wb /= '1' then
            wb_req <= "110000000" & upd_req(63 downto 32) & memcont(31 downto 0) &
                      ROM_array(indx + 1)(31 downto 0) &
                      ROM_array(indx + 2)(31 downto 0) &
                      ROM_array(indx + 3)(31 downto 0) &
                      ROM_array(indx + 4)(31 downto 0) &
                      ROM_array(indx + 5)(31 downto 0) &
                      ROM_array(indx + 6)(31 downto 0) &
                      ROM_array(indx + 7)(31 downto 0) &
                      ROM_array(indx + 8)(31 downto 0) &
                      ROM_array(indx + 9)(31 downto 0) &
                      ROM_array(indx + 10)(31 downto 0) &
                      ROM_array(indx + 11)(31 downto 0) &
                      ROM_array(indx + 12)(31 downto 0) &
                      ROM_array(indx + 13)(31 downto 0) &
                      ROM_array(indx + 14)(31 downto 0) &
                      ROM_array(indx + 15)(31 downto 0);
          end if;
          ROM_array(indx) <= "100" & upd_req(63 downto 42) & upd_req(31 downto 0);
          upd_ack         <= '1';
          upd_res         <= upd_req(71 downto 0);
          write_ack       <= '0';
        end if;

      end if;
    end if;
  end process;

end Behavioral;