library ieee;
use ieee.std_logic_1164.all;

package defs is
  constant MSG_WIDTH : positive := 73;
  constant WMSG_WIDTH : positive := 76;
  constant BMSG_WIDTH : positive := 553;
  
  constant CMD_WIDTH : positive := 8;
  constant ADR_WIDTH : positive := 32;
  constant DAT_WIDTH : positive := 32;

  type MSG_T is record
   val       : std_logic;                     -- valid bit;
   cmd       : std_logic_vector(7 downto 0);
   tag       : std_logic_vector(7 downto 0);  -- src
   id        : std_logic_vector(7 downto 0);  --sequence id
   adr       : std_logic_vector(31 downto 0);
   dat       : std_logic_vector(31 downto 0);
  end record MSG_T;

  type BMSG_T is record
   val       : std_logic;                     -- valid bit;
   cmd       : std_logic_vector(7 downto 0);
   tag       : std_logic_vector(7 downto 0);  -- src
   id        : std_logic_vector(7 downto 0);  --sequence id
   adr       : std_logic_vector(31 downto 0);
   dat       : std_logic_vector(511 downto 0);
  end record BMSG_T;

  type SNP_RES_T is record
    hit     : std_logic;
    msg     : MSG_T;
  end record SNP_RES_T;
  
  constant ZERO_MSG : MSG_T := ('0',
                                (others => '0'),
                                (others => '0'),
                                (others => '0'),
                                (others => '0'),
                                (others => '0'));

  constant ZERO_BMSG : BMSG_T := ('0',
                                  (others => '0'),
                                  (others => '0'),
                                  (others => '0'),
                                  (others => '0'),
                                  (others => '0'));

  
--  subtype MSG_T is std_logic_vector(MSG_WIDTH-1 downto 0);
  subtype CMD_T is std_logic_vector(CMD_WIDTH-1 downto 0);
  subtype ADR_T is std_logic_vector(ADR_WIDTH-1 downto 0);
  subtype DAT_T is std_logic_vector(DAT_WIDTH-1 downto 0);

--  subtype WMSG_T is std_logic_vector(WMSG_WIDTH-1 downto 0);
--  subtype BMSG_T is std_logic_vector(BMSG_WIDTH-1 downto 0); -- bus message
  subtype DEST_T is std_logic_vector(2 downto 0);

--  constant ZERO_MSG : MSG_T := (others => '0');
--  constant ZERO_BMSG : BMSG_T := (others => '0');
  
  constant READ_CMD  : CMD_T := "01000000"; --x"40";
  constant WRITE_CMD : CMD_T := "10000000"; --x"80";
  constant PWRUP_CMD : CMD_T := "00100000"; --x"20";
  constant PWRDN_CMD : CMD_T := "00010000"; --x"10";
  constant ZEROS_CMD : CMD_T := x"00";
  constant ONES_CMD : CMD_T  := x"ff";

  constant ZERO_480 : std_logic_vector(479 downto 0) := (others => '0');

  constant ZERO_TAG, ZERO_ID : std_logic_vector(7 downto 0) := x"00";
  constant ZEROS32, ZERO_ADR, ZERO_DAT : std_logic_vector(31 downto 0) := (others => '0');
  constant ONES32 : std_logic_vector(31 downto 0) := (others => '1');

  -- constant VAL_MASK : MSG_T := "1" & ZEROS_CMD & ZEROS32 & ZEROS32;
  -- constant CMD_MASK : MSG_T := "0" & ONES_CMD & ZEROS32 & ZEROS32;
  -- constant ADR_MASK : MSG_T := "0" & ZEROS_CMD & ONES32 & ZEROS32;
  -- constant DAT_MASK : MSG_T := "0" & ZEROS_CMD & ZEROS32 & ONES32;

  subtype IPTAG_T is std_logic_vector(7 downto 0);
  constant CPU0_TAG  : IPTAG_T := x"00";
  constant GFX_TAG   : IPTAG_T := x"01";
  constant UART_TAG  : IPTAG_T := x"02";
  constant USB_TAG   : IPTAG_T := x"03";
  constant AUDIO_TAG : IPTAG_T := x"04";
  constant CPU1_TAG  : IPTAG_T := x"05";
  -- TODO ips should b in order but b careful changing as it may break stg else!

  subtype IP_VECT_T is std_logic_vector(11 downto 0);
  type IP_T is (CPU0, CPU1, CACHE0, CACHE1,
                SA, MEM, GFX, PMU,
                AUDIO, USB, UART,
                NONE);
  type IP_VECT_ARRAY_T is array(IP_T) of IP_VECT_T;
  constant ip_enc : IP_VECT_ARRAY_T := (x"001", x"002", x"004", x"008",
                                        x"010", x"020", x"040", x"080",
                                        x"100", x"200", x"400",
                                        x"000");

  --constant TOMEM_ADR : ADR_T := x"80"; --1XXX...
  --constant TOGFX_ADR : ADR_T := x"00"; --X00X...
  --constant TOUART_ADR : ADR_T := x"20"; --X01X...
  --constant TOUSB_ADR : ADR_T := x"40"; --X10X...
  --constant TOAUDIO_ADR : ADR_T := x"60"; --X11X...  

  
  -- indices
  --constant MEM_FOUND_IDX : positive := 56;
  constant MSG_VAL_IDX : natural := 72;
  constant MSG_CMD_IDX : natural := 64;
  constant MSG_ADR_IDX : natural := 32;  
  constant MSG_DAT_IDX : natural := 0;

  -- PWRCMD is:
  --  a total of 73 bits:
  --     valid_bit & cmd[8] & src[8] & dst[8] & unused[24] 
  
end defs;
