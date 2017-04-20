library ieee;
use ieee.std_logic_1164.all;

package defs is
  --constant RD_CMD : std_logic_vector(1 downto 0) := "01";
  --constant WR_CMD : std_logic_vector(1 downto 0) := "10";
  --constant WB_CMD : std_logic_vector(1 downto 0) := "11";
  
  constant MSG_WIDTH : positive := 73;
  constant WMSG_WIDTH : positive := 76;
  constant BMSG_WIDTH : positive := 553;
  
  constant CMD_WIDTH : positive := 8;
  constant ADR_WIDTH : positive := 32;
  constant DAT_WIDTH : positive := 32;
  
  subtype MSG_T is std_logic_vector(MSG_WIDTH-1 downto 0);
  subtype CMD_T is std_logic_vector(CMD_WIDTH-1 downto 0);
  subtype ADR_T is std_logic_vector(ADR_WIDTH-1 downto 0);
  subtype DAT_T is std_logic_vector(DAT_WIDTH-1 downto 0);

  subtype WMSG_T is std_logic_vector(WMSG_WIDTH-1 downto 0);
  subtype BMSG_T is std_logic_vector(BMSG_WIDTH-1 downto 0); -- bus message
  subtype DEST_T is std_logic_vector(2 downto 0);

  constant ZERO_MSG : MSG_T := (others => '0');
  
  constant READ_CMD  : CMD_T := "01000000";
  constant WRITE_CMD : CMD_T := "10000000";
  constant PWRUP_CMD_MASK : CMD_T := "00100000";
  constant PWRDN_CMD_MASK : CMD_T := "01000000";
  constant ZEROS_CMD : CMD_T := (others => '0');
  constant ONES_CMD : CMD_T := (others => '1');
  
  constant ZEROS32 : std_logic_vector(31 downto 0) := (others => '0');
  constant ONES32 : std_logic_vector(31 downto 0) := (others => '1');

  constant VAL_MASK : MSG_T := "1" & ZEROS_CMD & ZEROS32 & ZEROS32;
  constant CMD_MASK : MSG_T := "0" & ONES_CMD & ZEROS32 & ZEROS32;
  constant ADR_MASK : MSG_T := "0" & ZEROS_CMD & ONES32 & ZEROS32;
  constant DAT_MASK : MSG_T := "0" & ZEROS_CMD & ZEROS32 & ONES32;

  constant CPU0_ID  : std_logic_vector(2 downto 0) := "000";
  constant GFX_ID   : std_logic_vector(2 downto 0) := "001";
  constant UART_ID  : std_logic_vector(2 downto 0) := "010";
  constant USB_ID   : std_logic_vector(2 downto 0) := "011";
  constant AUDIO_ID : std_logic_vector(2 downto 0) := "100";
  constant CPU1_ID  : std_logic_vector(2 downto 0) := "101";

  constant CACHE0_ID : std_logic_vector(2 downto 0) := "110";
  constant CACHE1_ID  : std_logic_vector(2 downto 0) := "111";
  
  --constant ZEROS72 : std_logic_vector(72 downto 0) := (others => '0');
  --constant ZEROS75 : std_logic_vector(75 downto 0) := (others => '0');
  
  -- indices
  --constant MEM_FOUND_IDX : positive := 56;
  constant MSG_VAL_IDX : natural := 72;
  constant MSG_CMD_IDX : natural := 63;
  constant MSG_ADR_IDX : natural := 31;  
  constant MSG_DAT_IDX : natural := 0;
end defs;
