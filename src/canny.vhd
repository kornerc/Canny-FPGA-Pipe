library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity canny is
    port(clk : in std_logic;
         reset : in std_logic;
         en : in std_logic;
         gray : in std_logic_vector(8-1 downto 0);
         gray_valid : in std_logic;
         output_image : in std_logic;
         thr_upper : in std_logic_vector(15-1 downto 0);
         thr_lower : in std_logic_vector(15-1 downto 0);
         on_edge : out std_logic;
         output_line : out std_logic;
         reset_fifo : out std_logic);
end entity canny;

architecture canny_beh of canny is
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_PARAMETER of reset : signal is "POLARITY ACTIVE_HIGH";

    ----------------------------------------------------------------------------------------------------------------------------------
    COMPONENT camera_blk_mem_0 IS
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT camera_blk_mem_0;

    COMPONENT camera_blk_mem_1 IS
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT camera_blk_mem_1;

    COMPONENT camera_blk_mem_2 IS
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT camera_blk_mem_2;

    COMPONENT camera_blk_mem_3 IS
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT camera_blk_mem_3;


    --! @brief stage 1 of pipeline; gauss filtering
    --! @details It takes 2 clock cyles for an input value, to appear at the output.
    --! 1 clock for the input shift register and 1 clock cycle for the filter.
    --! The 3 input values are the values of the line which should be filtered and
    --! the values of the line above and below, starting from the left values to the
    --! right ones.
    component stage1_gauss is
        port(--! clock
             signal clk : in std_logic;
             --! synchronous reset
             signal reset : in std_logic;
             --! enable
             signal en : in std_logic;
             --! value of line 0; grayscale (8 bit unsigned)
             signal val0 : in std_logic_vector(8-1 downto 0);
             --! value of line 1; grayscale (8 bit unsigned)
             signal val1 : in std_logic_vector(8-1 downto 0);
             --! value of line 2; grayscale (8 bit unsigned)
             signal val2 : in std_logic_vector(8-1 downto 0);
             --! value of line 3; grayscale (8 bit unsigned)
             signal val3 : in std_logic_vector(8-1 downto 0);
             --! @brief which of val0 - val3 is the oldest (topmost line)
             --! @details
             --! - "00": val0
             --! - "01": val1
             --! - "10": val2
             --! - "11": val3
             --!
             --! the two lines below the topmost line are considered (mod 4)<br>
             --! topmost_val = "10": upper line value: val2, middle line value: val3,
             --! lower line value: val0
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             --! result of the gauss filtering (12 bit unsigned)
             signal z : out std_logic_vector(12-1 downto 0));
    end component stage1_gauss;


    ----------------------------------------------------------------------------------------------------------------------------------
    COMPONENT gauss_blk_mem_0 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END COMPONENT gauss_blk_mem_0;

    COMPONENT gauss_blk_mem_1 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END COMPONENT gauss_blk_mem_1;

    COMPONENT gauss_blk_mem_2 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END COMPONENT gauss_blk_mem_2;

    COMPONENT gauss_blk_mem_3 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END COMPONENT gauss_blk_mem_3;

    --! @brief stage 2 of pipeline; sobel filtering, and magnitude and direction calculation
    --! @details It takes 3 clock cyles for an input value, to appear at the output.
    --! 1 clock for the input shift register, 1 clock cycle for the sobel filters
    --! and 1 clock cycle for the magnitude and direction calculation.
    --! The 3 input values are the values of the line which should be filtered and
    --! the values of the line above and below, starting from the left values to the
    --! right ones.
    component stage2_magangle is
        port(--! clock
             signal clk : in std_logic;
             --! synchronous reset
             signal reset : in std_logic;
             --! enable
             signal en : in std_logic;
             --! value of line 0; gauss filtered line (12 bit unsigned)
             signal val0 : in std_logic_vector(12-1 downto 0);
             --! value of line 1; gauss filtered line (12 bit unsigned)
             signal val1 : in std_logic_vector(12-1 downto 0);
             --! value of line 2; gauss filtered line (12 bit unsigned)
             signal val2 : in std_logic_vector(12-1 downto 0);
             --! value of line 3; gauss filtered line (12 bit unsigned)
             signal val3 : in std_logic_vector(12-1 downto 0);
             --! which of val0 - val3 is the oldest (topmost line) @see stage1_gauss::topmost_val
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             --! result of the filtering; magnitude (15 bit unsigned)
             signal mag : out std_logic_vector(15-1 downto 0);
             --! @brief result of the filtering; direction (2 bit)<br>
             --! @details 4 different directions are possible:
             --! - "00": east
             --! - "01": north east
             --! - "10": north
             --! - "11": north west
             signal direction : out std_logic_vector(2-1 downto 0));
    end component stage2_magangle;


    ----------------------------------------------------------------------------------------------------------------------------------
    COMPONENT dir_blk_mem_0 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT dir_blk_mem_0;

    COMPONENT dir_blk_mem_1 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT dir_blk_mem_1;

    COMPONENT dir_blk_mem_2 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT dir_blk_mem_2;

    COMPONENT dir_blk_mem_3 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT dir_blk_mem_3;

    COMPONENT mag_blk_mem_0 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
      );
    END COMPONENT mag_blk_mem_0;

    COMPONENT mag_blk_mem_1 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
      );
    END COMPONENT mag_blk_mem_1;

    COMPONENT mag_blk_mem_2 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
      );
    END COMPONENT mag_blk_mem_2;

    COMPONENT mag_blk_mem_3 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
      );
    END COMPONENT mag_blk_mem_3;

    --! @brief stage 3 of pipeline; non maximum suppression and hysteresis
    --! @details It takes 2 clock cyles for an input value, to appear at the output.
    --! 1 clock for the input shift register and 1 clock cycle for the non maximum suppression.
    --! The 3 input values are the values of the line which should be filtered and
    --! the values of the line above and below, starting from the left values to the
    --! right ones.
    component stage3_nms is
        port(--! clock
             signal clk : in std_logic;
             --! synchronous reset
             signal reset : in std_logic;
             --! enable
             signal en : in std_logic;
             --! upper threshold of the hysteresis (15 bit unsigned)
             signal thr_upper : in std_logic_vector(15-1 downto 0);
             --! lower threshold of the hysteresis (15 bit unsigned)
             signal thr_lower : in std_logic_vector(15-1 downto 0);
             --! magnitude value of line 0; magnitude (15 bit unsigned)
             signal mag0 : in std_logic_vector(15-1 downto 0);
             --! magnitude value of line 1; magnitude (15 bit unsigned)
             signal mag1 : in std_logic_vector(15-1 downto 0);
             --! magnitude value of line 2; magnitude (15 bit unsigned)
             signal mag2 : in std_logic_vector(15-1 downto 0);
             --! magnitude value of line 3; magnitude (15 bit unsigned)
             signal mag3 : in std_logic_vector(15-1 downto 0);
             --! direction value of line 0; (2 bit) @see stage2_magangle::direction
             signal angle0 : in std_logic_vector(2-1 downto 0);
             --! direction value of line 1; (2 bit) @see stage2_magangle::direction
             signal angle1 : in std_logic_vector(2-1 downto 0);
             --! direction value of line 2; (2 bit) @see stage2_magangle::direction
             signal angle2 : in std_logic_vector(2-1 downto 0);
             --! direction value of line 3; (2 bit) @see stage2_magangle::direction
             signal angle3 : in std_logic_vector(2-1 downto 0);
             --! which of val0 - val3 is the oldest (topmost line) @see stage1_gauss::topmost_val
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             --! reset the value (set to 0) in line memory, which is currently in the middle of the 3x3 filter
             signal reset_val : out std_logic;
             --! @brief type of the point (result of the hysteresis)
             --! @details 3 different types:
             --! - "00": point doesn't belong to an edge; magnitude[y, x] < stage3_nms::thr_lower
             --! - "01": point is a "strong point"; stage3_nms::thr_upper <= magnitude[y, x]
             --! - "10": point is a "weak point"; stage3_nms::thr_lower <= magnitude[y, x] < stage3_nms::thr_upper
             signal point_type : out std_logic_vector(2-1 downto 0));
    end component stage3_nms;


    ----------------------------------------------------------------------------------------------------------------------------------
    COMPONENT nms_blk_mem_0 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT nms_blk_mem_0;

    COMPONENT nms_blk_mem_1 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT nms_blk_mem_1;

    COMPONENT nms_blk_mem_2 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT nms_blk_mem_2;

    COMPONENT nms_blk_mem_3 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT nms_blk_mem_3;

    --! @brief stage 4 of pipeline; connect the points beginning from right to left (line wise right to left).
    --! @details It takes 2 clock cyles for an input value, to appear at the output.
    --! 1 clock for the input shift register and 1 clock cycle for the connection.
    --! The 3 input values are the values of the line which should be filtered and
    --! the values of the line above and below, starting from the right values to the
    --! left ones.
    component stage4_connect_rl is
        port(--! clock
             signal clk : in std_logic;
             --! synchronous reset
             signal reset : in std_logic;
             --! enable
             signal en : in std_logic;
             --! value of line 0; point type (2 bit) @see stage3_nms::point_type
             signal val0 : in std_logic_vector(2-1 downto 0);
             --! value of line 1; point type (2 bit) @see stage3_nms::point_type
             signal val1 : in std_logic_vector(2-1 downto 0);
             --! value of line 2; point type (2 bit) @see stage3_nms::point_type
             signal val2 : in std_logic_vector(2-1 downto 0);
             --! value of line 3; point type (2 bit) @see stage3_nms::point_type
             signal val3 : in std_logic_vector(2-1 downto 0);
             --! which of val0 - val3 is the oldest (topmost line) @see stage1_gauss::topmost_val
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             --! @brief new type of the point in the middle of the filter.
             --! @details the value must also be stored in the line memory! @see stage3_nms::point_type
             signal result : out std_logic_vector(2-1 downto 0));
    end component stage4_connect_rl;


    ----------------------------------------------------------------------------------------------------------------------------------
    COMPONENT conn_blk_mem_0 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT conn_blk_mem_0;

    COMPONENT conn_blk_mem_1 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT conn_blk_mem_1;

    COMPONENT conn_blk_mem_2 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT conn_blk_mem_2;

    COMPONENT conn_blk_mem_3 IS
          PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
          );
    END COMPONENT conn_blk_mem_3;

    --! @brief stage 5 of pipeline; connect the points beginning from bottom right to top left (line wise right to left).
    --! @details It takes 2 clock cyles for an input value, to appear at the output.
    --! 1 clock for the input shift register and 1 clock cycle for the connection.
    --! The 3 input values are the values of the line which should be filtered and
    --! the values of the line above and below, starting from the left values to the
    --! right ones.
    component stage5_connect_lr is
        port(--! clock
             signal clk : in std_logic;
             --! synchronous reset
             signal reset : in std_logic;
             --! enable
             signal en : in std_logic;
             --! value of line 0; point type (2 bit) @see stage3_nms::point_type
             signal val0 : in std_logic_vector(2-1 downto 0);
             --! value of line 1; point type (2 bit) @see stage3_nms::point_type
             signal val1 : in std_logic_vector(2-1 downto 0);
             --! value of line 2; point type (2 bit) @see stage3_nms::point_type
             signal val2 : in std_logic_vector(2-1 downto 0);
             --! value of line 3; point type (2 bit) @see stage3_nms::point_type
             signal val3 : in std_logic_vector(2-1 downto 0);
             --! which of val0 - val3 is the oldest (topmost line) @see stage1_gauss::topmost_val
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             --! @brief type of the point in the middle of the filter.
             --! @details the value must also be stored in the line memory!<br>
             --! 2 different types:
             --! - '0': point is not on an edge
             --! - '1': point is on an edge
             signal result : out std_logic);
    end component stage5_connect_lr;

    ----------------------------------------------------------------------------------------------------------------------------------
    constant width : unsigned(10-1 downto 0) := to_unsigned(640, 10);
    constant height : unsigned(9-1 downto 0) := to_unsigned(480, 9);


    ----------------------------------------------------------------------------------------------------------------------------------
    signal reset_pipelines : std_logic := '1';
    signal filter_pos : unsigned(10-1 downto 0) := (others => '0');
    signal iteration : unsigned(10-1 downto 0) := (others => '0');

    type state_t is (init, run);
    signal state : state_t := init;

    signal line_camera_ready : boolean := false;
    signal line_filter_ready : boolean := false;

    signal do_process : boolean := false;


    ----------------------------------------------------------------------------------------------------------------------------------
    signal gray_buff : std_logic_vector(8-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------------------------------------------------------------
    signal camera_blk_mem_addr_in_cnt : unsigned(9 downto 0) := (others => '1');

    signal camera_blk_mem_addr_in : std_logic_vector(9 downto 0) := (others => '0');
    signal camera_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal camera_blk_mem_0_en_in : std_logic := '0';
    signal camera_blk_mem_0_en_out : std_logic := '0';
    signal camera_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal camera_blk_mem_0_out : std_logic_vector(8-1 downto 0) := (others => '0');

    signal camera_blk_mem_1_en_in : std_logic := '0';
    signal camera_blk_mem_1_en_out : std_logic := '0';
    signal camera_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal camera_blk_mem_1_out : std_logic_vector(8-1 downto 0) := (others => '0');

    signal camera_blk_mem_2_en_in : std_logic := '0';
    signal camera_blk_mem_2_en_out : std_logic := '0';
    signal camera_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal camera_blk_mem_2_out : std_logic_vector(8-1 downto 0) := (others => '0');

    signal camera_blk_mem_3_en_in : std_logic := '0';
    signal camera_blk_mem_3_en_out : std_logic := '0';
    signal camera_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal camera_blk_mem_3_out : std_logic_vector(8-1 downto 0) := (others => '0');


    signal stage1_gauss_topmost_val : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage1_gauss_val0 : std_logic_vector(8-1 downto 0) := (others => '0');
    signal stage1_gauss_val1 : std_logic_vector(8-1 downto 0) := (others => '0');
    signal stage1_gauss_val2 : std_logic_vector(8-1 downto 0) := (others => '0');
    signal stage1_gauss_val3 : std_logic_vector(8-1 downto 0) := (others => '0');
    signal stage1_gauss_en : std_logic := '0';
    signal stage1_gauss_z : std_logic_vector(12-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------------------------------------------------------------
    signal gauss_blk_mem_addr_in : std_logic_vector(9 downto 0) := (others => '0');
    signal gauss_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal gauss_blk_mem_0_en_in : std_logic := '0';
    signal gauss_blk_mem_0_en_out : std_logic := '0';
    signal gauss_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal gauss_blk_mem_0_out : std_logic_vector(12-1 downto 0) := (others => '0');

    signal gauss_blk_mem_1_en_in : std_logic := '0';
    signal gauss_blk_mem_1_en_out : std_logic := '0';
    signal gauss_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal gauss_blk_mem_1_out : std_logic_vector(12-1 downto 0) := (others => '0');

    signal gauss_blk_mem_2_en_in : std_logic := '0';
    signal gauss_blk_mem_2_en_out : std_logic := '0';
    signal gauss_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal gauss_blk_mem_2_out : std_logic_vector(12-1 downto 0) := (others => '0');

    signal gauss_blk_mem_3_en_in : std_logic := '0';
    signal gauss_blk_mem_3_en_out : std_logic := '0';
    signal gauss_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal gauss_blk_mem_3_out : std_logic_vector(12-1 downto 0) := (others => '0');


    signal stage2_magangle_topmost_val : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage2_magangle_val0 : std_logic_vector(12-1 downto 0) := (others => '0');
    signal stage2_magangle_val1 : std_logic_vector(12-1 downto 0) := (others => '0');
    signal stage2_magangle_val2 : std_logic_vector(12-1 downto 0) := (others => '0');
    signal stage2_magangle_val3 : std_logic_vector(12-1 downto 0) := (others => '0');
    signal stage2_magangle_en : std_logic := '0';
    signal stage2_magangle_mag : std_logic_vector(15-1 downto 0) := (others => '0');
    signal stage2_magangle_direction : std_logic_vector(2-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------------------------------------------------------------
    signal dir_blk_mem_addr_in : std_logic_vector(9 downto 0) := (others => '0');
    signal dir_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal dir_blk_mem_0_en_in : std_logic := '0';
    signal dir_blk_mem_0_en_out : std_logic := '0';
    signal dir_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal dir_blk_mem_0_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal dir_blk_mem_1_en_in : std_logic := '0';
    signal dir_blk_mem_1_en_out : std_logic := '0';
    signal dir_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal dir_blk_mem_1_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal dir_blk_mem_2_en_in : std_logic := '0';
    signal dir_blk_mem_2_en_out : std_logic := '0';
    signal dir_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal dir_blk_mem_2_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal dir_blk_mem_3_en_in : std_logic := '0';
    signal dir_blk_mem_3_en_out : std_logic := '0';
    signal dir_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal dir_blk_mem_3_out : std_logic_vector(2-1 downto 0) := (others => '0');


    signal mag_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal mag_blk_mem_addr_0_in : std_logic_vector(9 downto 0) := (others => '0');
    signal mag_blk_mem_0_en_in : std_logic := '0';
    signal mag_blk_mem_0_en_out : std_logic := '0';
    signal mag_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal mag_blk_mem_0_in : std_logic_vector(15-1 downto 0) := (others => '0');
    signal mag_blk_mem_0_out : std_logic_vector(15-1 downto 0) := (others => '0');

    signal mag_blk_mem_addr_1_in : std_logic_vector(9 downto 0) := (others => '0');
    signal mag_blk_mem_1_en_in : std_logic := '0';
    signal mag_blk_mem_1_en_out : std_logic := '0';
    signal mag_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal mag_blk_mem_1_in : std_logic_vector(15-1 downto 0) := (others => '0');
    signal mag_blk_mem_1_out : std_logic_vector(15-1 downto 0) := (others => '0');

    signal mag_blk_mem_addr_2_in : std_logic_vector(9 downto 0) := (others => '0');
    signal mag_blk_mem_2_en_in : std_logic := '0';
    signal mag_blk_mem_2_en_out : std_logic := '0';
    signal mag_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal mag_blk_mem_2_in : std_logic_vector(15-1 downto 0) := (others => '0');
    signal mag_blk_mem_2_out : std_logic_vector(15-1 downto 0) := (others => '0');

    signal mag_blk_mem_addr_3_in : std_logic_vector(9 downto 0) := (others => '0');
    signal mag_blk_mem_3_en_in : std_logic := '0';
    signal mag_blk_mem_3_en_out : std_logic := '0';
    signal mag_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal mag_blk_mem_3_in : std_logic_vector(15-1 downto 0) := (others => '0');
    signal mag_blk_mem_3_out : std_logic_vector(15-1 downto 0) := (others => '0');


    signal stage3_nms_topmost_val : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage3_nms_dir0 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage3_nms_dir1 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage3_nms_dir2 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage3_nms_dir3 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage3_nms_mag0 : std_logic_vector(15-1 downto 0) := (others => '0');
    signal stage3_nms_mag1 : std_logic_vector(15-1 downto 0) := (others => '0');
    signal stage3_nms_mag2 : std_logic_vector(15-1 downto 0) := (others => '0');
    signal stage3_nms_mag3 : std_logic_vector(15-1 downto 0) := (others => '0');
    signal stage3_nms_en : std_logic := '0';
    signal stage3_nms_reset_val : std_logic := '0';
    signal stage3_nms_point_type : std_logic_vector(2-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------------------------------------------------------------
    signal nms_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal nms_blk_mem_addr_0_in : std_logic_vector(9 downto 0) := (others => '0');
    signal nms_blk_mem_0_en_in : std_logic := '0';
    signal nms_blk_mem_0_en_out : std_logic := '0';
    signal nms_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal nms_blk_mem_0_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal nms_blk_mem_0_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal nms_blk_mem_addr_1_in : std_logic_vector(9 downto 0) := (others => '0');
    signal nms_blk_mem_1_en_in : std_logic := '0';
    signal nms_blk_mem_1_en_out : std_logic := '0';
    signal nms_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal nms_blk_mem_1_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal nms_blk_mem_1_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal nms_blk_mem_addr_2_in : std_logic_vector(9 downto 0) := (others => '0');
    signal nms_blk_mem_2_en_in : std_logic := '0';
    signal nms_blk_mem_2_en_out : std_logic := '0';
    signal nms_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal nms_blk_mem_2_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal nms_blk_mem_2_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal nms_blk_mem_addr_3_in : std_logic_vector(9 downto 0) := (others => '0');
    signal nms_blk_mem_3_en_in : std_logic := '0';
    signal nms_blk_mem_3_en_out : std_logic := '0';
    signal nms_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal nms_blk_mem_3_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal nms_blk_mem_3_out : std_logic_vector(2-1 downto 0) := (others => '0');


    signal stage4_connect_rl_topmost_val : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage4_connect_rl_val0 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage4_connect_rl_val1 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage4_connect_rl_val2 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage4_connect_rl_val3 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage4_connect_rl_en : std_logic := '0';
    signal stage4_connect_rl_result : std_logic_vector(2-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------------------------------------------------------------
    signal conn_blk_mem_addr_out : std_logic_vector(9 downto 0) := (others => '0');

    signal conn_blk_mem_addr_0_in : std_logic_vector(9 downto 0) := (others => '0');
    signal conn_blk_mem_0_en_in : std_logic := '0';
    signal conn_blk_mem_0_en_out : std_logic := '0';
    signal conn_blk_mem_0_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal conn_blk_mem_0_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal conn_blk_mem_0_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal conn_blk_mem_addr_1_in : std_logic_vector(9 downto 0) := (others => '0');
    signal conn_blk_mem_1_en_in : std_logic := '0';
    signal conn_blk_mem_1_en_out : std_logic := '0';
    signal conn_blk_mem_1_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal conn_blk_mem_1_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal conn_blk_mem_1_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal conn_blk_mem_addr_2_in : std_logic_vector(9 downto 0) := (others => '0');
    signal conn_blk_mem_2_en_in : std_logic := '0';
    signal conn_blk_mem_2_en_out : std_logic := '0';
    signal conn_blk_mem_2_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal conn_blk_mem_2_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal conn_blk_mem_2_out : std_logic_vector(2-1 downto 0) := (others => '0');

    signal conn_blk_mem_addr_3_in : std_logic_vector(9 downto 0) := (others => '0');
    signal conn_blk_mem_3_en_in : std_logic := '0';
    signal conn_blk_mem_3_en_out : std_logic := '0';
    signal conn_blk_mem_3_wea : std_logic_vector(0 downto 0) := (others => '0');
    signal conn_blk_mem_3_in : std_logic_vector(2-1 downto 0) := (others => '0');
    signal conn_blk_mem_3_out : std_logic_vector(2-1 downto 0) := (others => '0');


    signal stage5_connect_lr_topmost_val : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage5_connect_lr_val0 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage5_connect_lr_val1 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage5_connect_lr_val2 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage5_connect_lr_val3 : std_logic_vector(2-1 downto 0) := (others => '0');
    signal stage5_connect_lr_en : std_logic := '0';
    signal stage5_connect_lr_result : std_logic := '0';

    ----------------------------------------------------------------------------------------------------------------------------------
    signal output_image_old : std_logic := '0';
begin
    --================================================================================================================================
    CAMERA_MEM_0 : camera_blk_mem_0 port map(clka => clk,
                                             clkb => clk,
                                             ena => camera_blk_mem_0_en_in,
                                             enb => camera_blk_mem_0_en_out,
                                             addra => camera_blk_mem_addr_in,
                                             addrb => camera_blk_mem_addr_out,
                                             dina => gray_buff,
                                             doutb => camera_blk_mem_0_out,
                                             wea => camera_blk_mem_0_wea);

    CAMERA_MEM_1 : camera_blk_mem_1 port map(clka => clk,
                                             clkb => clk,
                                             ena => camera_blk_mem_1_en_in,
                                             enb => camera_blk_mem_1_en_out,
                                             addra => camera_blk_mem_addr_in,
                                             addrb => camera_blk_mem_addr_out,
                                             dina => gray_buff,
                                             doutb => camera_blk_mem_1_out,
                                             wea => camera_blk_mem_1_wea);

    CAMERA_MEM_2 : camera_blk_mem_2 port map(clka => clk,
                                             clkb => clk,
                                             ena => camera_blk_mem_2_en_in,
                                             enb => camera_blk_mem_2_en_out,
                                             addra => camera_blk_mem_addr_in,
                                             addrb => camera_blk_mem_addr_out,
                                             dina => gray_buff,
                                             doutb => camera_blk_mem_2_out,
                                             wea => camera_blk_mem_2_wea);

    CAMERA_MEM_3 : camera_blk_mem_3 port map(clka => clk,
                                             clkb => clk,
                                             ena => camera_blk_mem_3_en_in,
                                             enb => camera_blk_mem_3_en_out,
                                             addra => camera_blk_mem_addr_in,
                                             addrb => camera_blk_mem_addr_out,
                                             dina => gray_buff,
                                             doutb => camera_blk_mem_3_out,
                                             wea => camera_blk_mem_3_wea);


    STAGE1 : stage1_gauss port map(clk => clk,
                                   reset => reset_pipelines,
                                   en => stage1_gauss_en,
                                   val0 => stage1_gauss_val0,
                                   val1 => stage1_gauss_val1,
                                   val2 => stage1_gauss_val2,
                                   val3 => stage1_gauss_val3,
                                   topmost_val => stage1_gauss_topmost_val,
                                   z => stage1_gauss_z);


    ----------------------------------------------------------------------------------------------------------------------------------
    GAUSS_MEM_0 : gauss_blk_mem_0 port map(clka => clk,
                                           clkb => clk,
                                           ena => gauss_blk_mem_0_en_in,
                                           enb => gauss_blk_mem_0_en_out,
                                           addra => gauss_blk_mem_addr_in,
                                           addrb => gauss_blk_mem_addr_out,
                                           dina => stage1_gauss_z,
                                           doutb => gauss_blk_mem_0_out,
                                           wea => gauss_blk_mem_0_wea);

    GAUSS_MEM_1 : gauss_blk_mem_1 port map(clka => clk,
                                           clkb => clk,
                                           ena => gauss_blk_mem_1_en_in,
                                           enb => gauss_blk_mem_1_en_out,
                                           addra => gauss_blk_mem_addr_in,
                                           addrb => gauss_blk_mem_addr_out,
                                           dina => stage1_gauss_z,
                                           doutb => gauss_blk_mem_1_out,
                                           wea => gauss_blk_mem_1_wea);

    GAUSS_MEM_2 : gauss_blk_mem_2 port map(clka => clk,
                                           clkb => clk,
                                           ena => gauss_blk_mem_2_en_in,
                                           enb => gauss_blk_mem_2_en_out,
                                           addra => gauss_blk_mem_addr_in,
                                           addrb => gauss_blk_mem_addr_out,
                                           dina => stage1_gauss_z,
                                           doutb => gauss_blk_mem_2_out,
                                           wea => gauss_blk_mem_2_wea);

    GAUSS_MEM_3 : gauss_blk_mem_3 port map(clka => clk,
                                           clkb => clk,
                                           ena => gauss_blk_mem_3_en_in,
                                           enb => gauss_blk_mem_3_en_out,
                                           addra => gauss_blk_mem_addr_in,
                                           addrb => gauss_blk_mem_addr_out,
                                           dina => stage1_gauss_z,
                                           doutb => gauss_blk_mem_3_out,
                                           wea => gauss_blk_mem_3_wea);

    STAGE2 : stage2_magangle port map(clk => clk,
                                      reset => reset_pipelines,
                                      en => stage2_magangle_en,
                                      val0 => stage2_magangle_val0,
                                      val1 => stage2_magangle_val1,
                                      val2 => stage2_magangle_val2,
                                      val3 => stage2_magangle_val3,
                                      topmost_val => stage2_magangle_topmost_val,
                                      mag => stage2_magangle_mag,
                                      direction => stage2_magangle_direction);


    ----------------------------------------------------------------------------------------------------------------------------------
    DIR_MEM_0 : dir_blk_mem_0 port map(clka => clk,
                                       clkb => clk,
                                       ena => dir_blk_mem_0_en_in,
                                       enb => dir_blk_mem_0_en_out,
                                       addra => dir_blk_mem_addr_in,
                                       addrb => dir_blk_mem_addr_out,
                                       dina => stage2_magangle_direction,
                                       doutb => dir_blk_mem_0_out,
                                       wea => dir_blk_mem_0_wea);

    DIR_MEM_1 : dir_blk_mem_1 port map(clka => clk,
                                       clkb => clk,
                                       ena => dir_blk_mem_1_en_in,
                                       enb => dir_blk_mem_1_en_out,
                                       addra => dir_blk_mem_addr_in,
                                       addrb => dir_blk_mem_addr_out,
                                       dina => stage2_magangle_direction,
                                       doutb => dir_blk_mem_1_out,
                                       wea => dir_blk_mem_1_wea);

    DIR_MEM_2 : dir_blk_mem_2 port map(clka => clk,
                                       clkb => clk,
                                       ena => dir_blk_mem_2_en_in,
                                       enb => dir_blk_mem_2_en_out,
                                       addra => dir_blk_mem_addr_in,
                                       addrb => dir_blk_mem_addr_out,
                                       dina => stage2_magangle_direction,
                                       doutb => dir_blk_mem_2_out,
                                       wea => dir_blk_mem_2_wea);

    DIR_MEM_3 : dir_blk_mem_3 port map(clka => clk,
                                       clkb => clk,
                                       ena => dir_blk_mem_3_en_in,
                                       enb => dir_blk_mem_3_en_out,
                                       addra => dir_blk_mem_addr_in,
                                       addrb => dir_blk_mem_addr_out,
                                       dina => stage2_magangle_direction,
                                       doutb => dir_blk_mem_3_out,
                                       wea => dir_blk_mem_3_wea);

    MAG_MEM_0 : mag_blk_mem_0 port map(clka => clk,
                                       clkb => clk,
                                       ena => mag_blk_mem_0_en_in,
                                       enb => mag_blk_mem_0_en_out,
                                       addra => mag_blk_mem_addr_0_in,
                                       addrb => mag_blk_mem_addr_out,
                                       dina => mag_blk_mem_0_in,
                                       doutb => mag_blk_mem_0_out,
                                       wea => mag_blk_mem_0_wea);

    MAG_MEM_1 : mag_blk_mem_1 port map(clka => clk,
                                       clkb => clk,
                                       ena => mag_blk_mem_1_en_in,
                                       enb => mag_blk_mem_1_en_out,
                                       addra => mag_blk_mem_addr_1_in,
                                       addrb => mag_blk_mem_addr_out,
                                       dina => mag_blk_mem_1_in,
                                       doutb => mag_blk_mem_1_out,
                                       wea => mag_blk_mem_1_wea);

    MAG_MEM_2 : mag_blk_mem_2 port map(clka => clk,
                                       clkb => clk,
                                       ena => mag_blk_mem_2_en_in,
                                       enb => mag_blk_mem_2_en_out,
                                       addra => mag_blk_mem_addr_2_in,
                                       addrb => mag_blk_mem_addr_out,
                                       dina => mag_blk_mem_2_in,
                                       doutb => mag_blk_mem_2_out,
                                       wea => mag_blk_mem_2_wea);

    MAG_MEM_3 : mag_blk_mem_3 port map(clka => clk,
                                       clkb => clk,
                                       ena => mag_blk_mem_3_en_in,
                                       enb => mag_blk_mem_3_en_out,
                                       addra => mag_blk_mem_addr_3_in,
                                       addrb => mag_blk_mem_addr_out,
                                       dina => mag_blk_mem_3_in,
                                       doutb => mag_blk_mem_3_out,
                                       wea => mag_blk_mem_3_wea);

    STAGE3 : stage3_nms port map(clk => clk,
                                 reset => reset_pipelines,
                                 en => stage3_nms_en,
                                 thr_upper => thr_upper,
                                 thr_lower => thr_lower,
                                 mag0 => stage3_nms_mag0,
                                 mag1 => stage3_nms_mag1,
                                 mag2 => stage3_nms_mag2,
                                 mag3 => stage3_nms_mag3,
                                 angle0 => stage3_nms_dir0,
                                 angle1 => stage3_nms_dir1,
                                 angle2 => stage3_nms_dir2,
                                 angle3 => stage3_nms_dir3,
                                 topmost_val => stage3_nms_topmost_val,
                                 reset_val => stage3_nms_reset_val,
                                 point_type => stage3_nms_point_type);


    ----------------------------------------------------------------------------------------------------------------------------------
    NMS_MEM_0 : nms_blk_mem_0 port map(clka => clk,
                                       clkb => clk,
                                       ena => nms_blk_mem_0_en_in,
                                       enb => nms_blk_mem_0_en_out,
                                       addra => nms_blk_mem_addr_0_in,
                                       addrb => nms_blk_mem_addr_out,
                                       dina => nms_blk_mem_0_in,
                                       doutb => nms_blk_mem_0_out,
                                       wea => nms_blk_mem_0_wea);

    NMS_MEM_1 : nms_blk_mem_1 port map(clka => clk,
                                       clkb => clk,
                                       ena => nms_blk_mem_1_en_in,
                                       enb => nms_blk_mem_1_en_out,
                                       addra => nms_blk_mem_addr_1_in,
                                       addrb => nms_blk_mem_addr_out,
                                       dina => nms_blk_mem_1_in,
                                       doutb => nms_blk_mem_1_out,
                                       wea => nms_blk_mem_1_wea);

    NMS_MEM_2 : nms_blk_mem_2 port map(clka => clk,
                                       clkb => clk,
                                       ena => nms_blk_mem_2_en_in,
                                       enb => nms_blk_mem_2_en_out,
                                       addra => nms_blk_mem_addr_2_in,
                                       addrb => nms_blk_mem_addr_out,
                                       dina => nms_blk_mem_2_in,
                                       doutb => nms_blk_mem_2_out,
                                       wea => nms_blk_mem_2_wea);

    NMS_MEM_3 : nms_blk_mem_3 port map(clka => clk,
                                       clkb => clk,
                                       ena => nms_blk_mem_3_en_in,
                                       enb => nms_blk_mem_3_en_out,
                                       addra => nms_blk_mem_addr_3_in,
                                       addrb => nms_blk_mem_addr_out,
                                       dina => nms_blk_mem_3_in,
                                       doutb => nms_blk_mem_3_out,
                                       wea => nms_blk_mem_3_wea);

    STAGE4 : stage4_connect_rl port map(clk => clk,
                                        reset => reset_pipelines,
                                        en => stage4_connect_rl_en,
                                        val0 => stage4_connect_rl_val0,
                                        val1 => stage4_connect_rl_val1,
                                        val2 => stage4_connect_rl_val2,
                                        val3 => stage4_connect_rl_val3,
                                        topmost_val => stage4_connect_rl_topmost_val,
                                        result => stage4_connect_rl_result);


    ----------------------------------------------------------------------------------------------------------------------------------
    CONN_MEM_0 : conn_blk_mem_0 port map(clka => clk,
                                         clkb => clk,
                                         ena => conn_blk_mem_0_en_in,
                                         enb => conn_blk_mem_0_en_out,
                                         addra => conn_blk_mem_addr_0_in,
                                         addrb => conn_blk_mem_addr_out,
                                         dina => conn_blk_mem_0_in,
                                         doutb => conn_blk_mem_0_out,
                                         wea => conn_blk_mem_0_wea);

     CONN_MEM_1 : conn_blk_mem_1 port map(clka => clk,
                                          clkb => clk,
                                          ena => conn_blk_mem_1_en_in,
                                          enb => conn_blk_mem_1_en_out,
                                          addra => conn_blk_mem_addr_1_in,
                                          addrb => conn_blk_mem_addr_out,
                                          dina => conn_blk_mem_1_in,
                                          doutb => conn_blk_mem_1_out,
                                          wea => conn_blk_mem_1_wea);

    CONN_MEM_2 : conn_blk_mem_2 port map(clka => clk,
                                         clkb => clk,
                                         ena => conn_blk_mem_2_en_in,
                                         enb => conn_blk_mem_2_en_out,
                                         addra => conn_blk_mem_addr_2_in,
                                         addrb => conn_blk_mem_addr_out,
                                         dina => conn_blk_mem_2_in,
                                         doutb => conn_blk_mem_2_out,
                                         wea => conn_blk_mem_2_wea);

    CONN_MEM_3 : conn_blk_mem_3 port map(clka => clk,
                                         clkb => clk,
                                         ena => conn_blk_mem_3_en_in,
                                         enb => conn_blk_mem_3_en_out,
                                         addra => conn_blk_mem_addr_3_in,
                                         addrb => conn_blk_mem_addr_out,
                                         dina => conn_blk_mem_3_in,
                                         doutb => conn_blk_mem_3_out,
                                         wea => conn_blk_mem_3_wea);

    STAGE5 : stage5_connect_lr port map(clk => clk,
                                        reset => reset_pipelines,
                                        en => stage5_connect_lr_en,
                                        val0 => stage5_connect_lr_val0,
                                        val1 => stage5_connect_lr_val1,
                                        val2 => stage5_connect_lr_val2,
                                        val3 => stage5_connect_lr_val3,
                                        topmost_val => stage5_connect_lr_topmost_val,
                                        result => stage5_connect_lr_result);


    --================================================================================================================================
    stage_pre_p : process(camera_blk_mem_addr_in_cnt)
    begin
        -- camera memory address in
        if camera_blk_mem_addr_in_cnt = (camera_blk_mem_addr_in_cnt'range => '1') then
            camera_blk_mem_addr_in <= (others => '0');
        else
            camera_blk_mem_addr_in <= std_logic_vector(camera_blk_mem_addr_in_cnt);
        end if;
    end process stage_pre_p;


    ----------------------------------------------------------------------------------------------------------------------------------
    stage1_p : process(stage1_gauss_topmost_val, stage2_magangle_topmost_val,
                       filter_pos, iteration,
                       camera_blk_mem_0_out, camera_blk_mem_1_out, camera_blk_mem_2_out, camera_blk_mem_3_out)
    begin
        -- stage 2 topmost value
        stage2_magangle_topmost_val <= std_logic_vector(unsigned(stage1_gauss_topmost_val) - 2);

        -- camera memory select in / out enable
        case stage1_gauss_topmost_val is
            when "00" =>
                camera_blk_mem_0_en_out <= '1';
                camera_blk_mem_0_en_in <= '0';
                camera_blk_mem_1_en_out <= '1';
                camera_blk_mem_1_en_in <= '0';
                camera_blk_mem_2_en_out <= '1';
                camera_blk_mem_2_en_in <= '0';
                camera_blk_mem_3_en_out <= '0';
                camera_blk_mem_3_en_in <= '1';
            when "01" =>
                camera_blk_mem_0_en_out <= '0';
                camera_blk_mem_0_en_in <= '1';
                camera_blk_mem_1_en_out <= '1';
                camera_blk_mem_1_en_in <= '0';
                camera_blk_mem_2_en_out <= '1';
                camera_blk_mem_2_en_in <= '0';
                camera_blk_mem_3_en_out <= '1';
                camera_blk_mem_3_en_in <= '0';
            when "10" =>
                camera_blk_mem_0_en_out <= '1';
                camera_blk_mem_0_en_in <= '0';
                camera_blk_mem_1_en_out <= '0';
                camera_blk_mem_1_en_in <= '1';
                camera_blk_mem_2_en_out <= '1';
                camera_blk_mem_2_en_in <= '0';
                camera_blk_mem_3_en_out <= '1';
                camera_blk_mem_3_en_in <= '0';
            when others =>
                camera_blk_mem_0_en_out <= '1';
                camera_blk_mem_0_en_in <= '0';
                camera_blk_mem_1_en_out <= '1';
                camera_blk_mem_1_en_in <= '0';
                camera_blk_mem_2_en_out <= '0';
                camera_blk_mem_2_en_in <= '1';
                camera_blk_mem_3_en_out <= '1';
                camera_blk_mem_3_en_in <= '0';
        end case;

        -- camera memory connections to stage 1
        -- it takes 2 iterations to fill 3 lines (1 is reflected)
        if iteration = 1*2 then
            -- reflect first line
            stage1_gauss_val0 <= camera_blk_mem_1_out;
            stage1_gauss_val1 <= camera_blk_mem_1_out;
            stage1_gauss_val2 <= camera_blk_mem_2_out;
            stage1_gauss_val3 <= camera_blk_mem_3_out;
        elsif iteration = height+1*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage1_gauss_val0 <= camera_blk_mem_1_out;
            stage1_gauss_val1 <= camera_blk_mem_1_out;
            stage1_gauss_val2 <= camera_blk_mem_2_out;
            stage1_gauss_val3 <= camera_blk_mem_3_out;
        else
            stage1_gauss_val0 <= camera_blk_mem_0_out;
            stage1_gauss_val1 <= camera_blk_mem_1_out;
            stage1_gauss_val2 <= camera_blk_mem_2_out;
            stage1_gauss_val3 <= camera_blk_mem_3_out;
        end if;

        -- camera memory address out
        if filter_pos = 0 then
            camera_blk_mem_addr_out <= std_logic_vector(filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            camera_blk_mem_addr_out <= std_logic_vector(filter_pos-1);
        elsif filter_pos = width+2-1 then
            camera_blk_mem_addr_out <= std_logic_vector(filter_pos-2);
        else
            camera_blk_mem_addr_out <= (others => '0');
        end if;

        -- gauss memory address in and wea
        gauss_blk_mem_0_wea <= "0";
        gauss_blk_mem_1_wea <= "0";
        gauss_blk_mem_2_wea <= "0";
        gauss_blk_mem_3_wea <= "0";

        -- 1. & 2. clock: memory adressing
        -- 3. & 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 then
            case stage2_magangle_topmost_val is
                when "00" =>
                    gauss_blk_mem_3_wea <= "1";
                when "01" =>
                    gauss_blk_mem_0_wea <= "1";
                when "10" =>
                    gauss_blk_mem_1_wea <= "1";
                when others =>
                    gauss_blk_mem_2_wea <= "1";
            end case;

            gauss_blk_mem_addr_in <= std_logic_vector(filter_pos - 6);
        else
            gauss_blk_mem_addr_in <= (others => '0');
        end if;
    end process stage1_p;


    ----------------------------------------------------------------------------------------------------------------------------------
    stage2_p : process(stage2_magangle_topmost_val, stage3_nms_topmost_val,
                       filter_pos, iteration,
                       gauss_blk_mem_0_out, gauss_blk_mem_1_out, gauss_blk_mem_2_out, gauss_blk_mem_3_out,
                       stage3_nms_reset_val, stage2_magangle_mag)
    begin
        -- stage 3 topmost value
        stage3_nms_topmost_val <= std_logic_vector(unsigned(stage2_magangle_topmost_val) - 2);

        -- gauss memory select in / out enable
        case stage2_magangle_topmost_val is
            when "00" =>
                gauss_blk_mem_0_en_out <= '1';
                gauss_blk_mem_0_en_in <= '0';
                gauss_blk_mem_1_en_out <= '1';
                gauss_blk_mem_1_en_in <= '0';
                gauss_blk_mem_2_en_out <= '1';
                gauss_blk_mem_2_en_in <= '0';
                gauss_blk_mem_3_en_out <= '0';
                gauss_blk_mem_3_en_in <= '1';
            when "01" =>
                gauss_blk_mem_0_en_out <= '0';
                gauss_blk_mem_0_en_in <= '1';
                gauss_blk_mem_1_en_out <= '1';
                gauss_blk_mem_1_en_in <= '0';
                gauss_blk_mem_2_en_out <= '1';
                gauss_blk_mem_2_en_in <= '0';
                gauss_blk_mem_3_en_out <= '1';
                gauss_blk_mem_3_en_in <= '0';
            when "10" =>
                gauss_blk_mem_0_en_out <= '1';
                gauss_blk_mem_0_en_in <= '0';
                gauss_blk_mem_1_en_out <= '0';
                gauss_blk_mem_1_en_in <= '1';
                gauss_blk_mem_2_en_out <= '1';
                gauss_blk_mem_2_en_in <= '0';
                gauss_blk_mem_3_en_out <= '1';
                gauss_blk_mem_3_en_in <= '0';
            when others =>
                gauss_blk_mem_0_en_out <= '1';
                gauss_blk_mem_0_en_in <= '0';
                gauss_blk_mem_1_en_out <= '1';
                gauss_blk_mem_1_en_in <= '0';
                gauss_blk_mem_2_en_out <= '0';
                gauss_blk_mem_2_en_in <= '1';
                gauss_blk_mem_3_en_out <= '1';
                gauss_blk_mem_3_en_in <= '0';
        end case;

        -- gauss memory connections to stage 2
        -- 2 lines behind the previous stage
        if iteration = 2*2 then
            -- reflect first line
            stage2_magangle_val0 <= gauss_blk_mem_1_out;
            stage2_magangle_val1 <= gauss_blk_mem_1_out;
            stage2_magangle_val2 <= gauss_blk_mem_2_out;
            stage2_magangle_val3 <= gauss_blk_mem_3_out;
        elsif iteration = height+2*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage2_magangle_val0 <= gauss_blk_mem_1_out;
            stage2_magangle_val1 <= gauss_blk_mem_1_out;
            stage2_magangle_val2 <= gauss_blk_mem_2_out;
            stage2_magangle_val3 <= gauss_blk_mem_3_out;
        else
            stage2_magangle_val0 <= gauss_blk_mem_0_out;
            stage2_magangle_val1 <= gauss_blk_mem_1_out;
            stage2_magangle_val2 <= gauss_blk_mem_2_out;
            stage2_magangle_val3 <= gauss_blk_mem_3_out;
        end if;

        -- gauss memory address out
        if filter_pos = 0 then
            gauss_blk_mem_addr_out <= std_logic_vector(filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            gauss_blk_mem_addr_out <= std_logic_vector(filter_pos-1);
        elsif filter_pos = width+2-1 then
            gauss_blk_mem_addr_out <= std_logic_vector(filter_pos-2);
        else
            gauss_blk_mem_addr_out <= (others => '0');
        end if;

        -- dir memory address in and wea
        dir_blk_mem_0_wea <= "0";
        dir_blk_mem_1_wea <= "0";
        dir_blk_mem_2_wea <= "0";
        dir_blk_mem_3_wea <= "0";

        -- 1. & 2. clock: memory adressing
        -- 3., 4. and 5. clock: filter delay
        -- 6. & 7. clock: fill filter pipeline
        if filter_pos >= 7 and filter_pos < width+7 then
            case stage3_nms_topmost_val is
                when "00" =>
                    dir_blk_mem_3_wea <= "1";
                when "01" =>
                    dir_blk_mem_0_wea <= "1";
                when "10" =>
                    dir_blk_mem_1_wea <= "1";
                when others =>
                    dir_blk_mem_2_wea <= "1";
            end case;

            dir_blk_mem_addr_in <= std_logic_vector(filter_pos - 7);
        else
            dir_blk_mem_addr_in <= (others => '0');
        end if;

        -- mag memory address in and wea
        mag_blk_mem_0_wea <= "0";
        mag_blk_mem_1_wea <= "0";
        mag_blk_mem_2_wea <= "0";
        mag_blk_mem_3_wea <= "0";

        -- 1. & 2. clock: memory adressing
        -- 3., 4. and 5. clock: filter delay
        -- 6. & 7. clock: fill filter pipeline
        if filter_pos >= 7 and filter_pos < width+7 then
            case stage3_nms_topmost_val is
                when "00" =>
                    mag_blk_mem_3_wea <= "1";
                when "01" =>
                    mag_blk_mem_0_wea <= "1";
                when "10" =>
                    mag_blk_mem_1_wea <= "1";
                when others =>
                    mag_blk_mem_2_wea <= "1";
            end case;

            mag_blk_mem_addr_0_in <= std_logic_vector(filter_pos - 7);
            mag_blk_mem_addr_1_in <= std_logic_vector(filter_pos - 7);
            mag_blk_mem_addr_2_in <= std_logic_vector(filter_pos - 7);
            mag_blk_mem_addr_3_in <= std_logic_vector(filter_pos - 7);
        else
            mag_blk_mem_addr_0_in <= (others => '0');
            mag_blk_mem_addr_1_in <= (others => '0');
            mag_blk_mem_addr_2_in <= (others => '0');
            mag_blk_mem_addr_3_in <= (others => '0');
        end if;

        -- mag memory write back from stage 3 address in
        -- timing stage 3
        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 and
           iteration >= 3*2 and iteration < height+3*2 then
            case stage3_nms_topmost_val is
                when "00" =>
                    mag_blk_mem_1_wea(0) <= stage3_nms_reset_val;
                    mag_blk_mem_addr_1_in <= std_logic_vector(filter_pos - 6);
                when "01" =>
                    mag_blk_mem_2_wea(0) <= stage3_nms_reset_val;
                    mag_blk_mem_addr_2_in <= std_logic_vector(filter_pos - 6);
                when "10" =>
                    mag_blk_mem_3_wea(0) <= stage3_nms_reset_val;
                    mag_blk_mem_addr_3_in <= std_logic_vector(filter_pos - 6);
                when others =>
                    mag_blk_mem_0_wea(0) <= stage3_nms_reset_val;
                    mag_blk_mem_addr_0_in <= std_logic_vector(filter_pos - 6);
            end case;
        end if;

        -- mag memory in
        case stage3_nms_topmost_val is
            when "00" =>
                mag_blk_mem_0_in <= stage2_magangle_mag;
                mag_blk_mem_1_in <= (others => '0');
                mag_blk_mem_2_in <= stage2_magangle_mag;
                mag_blk_mem_3_in <= stage2_magangle_mag;
            when "01" =>
                mag_blk_mem_0_in <= stage2_magangle_mag;
                mag_blk_mem_1_in <= stage2_magangle_mag;
                mag_blk_mem_2_in <= (others => '0');
                mag_blk_mem_3_in <= stage2_magangle_mag;
            when "10" =>
                mag_blk_mem_0_in <= stage2_magangle_mag;
                mag_blk_mem_1_in <= stage2_magangle_mag;
                mag_blk_mem_2_in <= stage2_magangle_mag;
                mag_blk_mem_3_in <= (others => '0');
            when others =>
                mag_blk_mem_0_in <= (others => '0');
                mag_blk_mem_1_in <= stage2_magangle_mag;
                mag_blk_mem_2_in <= stage2_magangle_mag;
                mag_blk_mem_3_in <= stage2_magangle_mag;
        end case;
    end process stage2_p;


    ----------------------------------------------------------------------------------------------------------------------------------
    stage3_p : process(stage3_nms_topmost_val, stage4_connect_rl_topmost_val,
                       filter_pos, iteration,
                       dir_blk_mem_0_out, dir_blk_mem_1_out, dir_blk_mem_2_out, dir_blk_mem_3_out,
                       mag_blk_mem_0_out, mag_blk_mem_1_out, mag_blk_mem_2_out, mag_blk_mem_3_out,
                       stage3_nms_point_type, stage4_connect_rl_result)
    begin
        -- stage 4 topmost value
        stage4_connect_rl_topmost_val <= std_logic_vector(unsigned(stage3_nms_topmost_val) - 2);

        -- dir memory select in / out enable
        case stage3_nms_topmost_val is
            when "00" =>
                dir_blk_mem_0_en_out <= '1';
                dir_blk_mem_0_en_in <= '0';
                dir_blk_mem_1_en_out <= '1';
                dir_blk_mem_1_en_in <= '0';
                dir_blk_mem_2_en_out <= '1';
                dir_blk_mem_2_en_in <= '0';
                dir_blk_mem_3_en_out <= '0';
                dir_blk_mem_3_en_in <= '1';
            when "01" =>
                dir_blk_mem_0_en_out <= '0';
                dir_blk_mem_0_en_in <= '1';
                dir_blk_mem_1_en_out <= '1';
                dir_blk_mem_1_en_in <= '0';
                dir_blk_mem_2_en_out <= '1';
                dir_blk_mem_2_en_in <= '0';
                dir_blk_mem_3_en_out <= '1';
                dir_blk_mem_3_en_in <= '0';
            when "10" =>
                dir_blk_mem_0_en_out <= '1';
                dir_blk_mem_0_en_in <= '0';
                dir_blk_mem_1_en_out <= '0';
                dir_blk_mem_1_en_in <= '1';
                dir_blk_mem_2_en_out <= '1';
                dir_blk_mem_2_en_in <= '0';
                dir_blk_mem_3_en_out <= '1';
                dir_blk_mem_3_en_in <= '0';
            when others =>
                dir_blk_mem_0_en_out <= '1';
                dir_blk_mem_0_en_in <= '0';
                dir_blk_mem_1_en_out <= '1';
                dir_blk_mem_1_en_in <= '0';
                dir_blk_mem_2_en_out <= '0';
                dir_blk_mem_2_en_in <= '1';
                dir_blk_mem_3_en_out <= '1';
                dir_blk_mem_3_en_in <= '0';
        end case;

        -- mag memory select in / out enable
        case stage3_nms_topmost_val is
            when "00" =>
                mag_blk_mem_0_en_out <= '1';
                mag_blk_mem_0_en_in <= '0';
                mag_blk_mem_1_en_out <= '1';
                mag_blk_mem_1_en_in <= '1';
                mag_blk_mem_2_en_out <= '1';
                mag_blk_mem_2_en_in <= '0';
                mag_blk_mem_3_en_out <= '0';
                mag_blk_mem_3_en_in <= '1';
            when "01" =>
                mag_blk_mem_0_en_out <= '0';
                mag_blk_mem_0_en_in <= '1';
                mag_blk_mem_1_en_out <= '1';
                mag_blk_mem_1_en_in <= '0';
                mag_blk_mem_2_en_out <= '1';
                mag_blk_mem_2_en_in <= '1';
                mag_blk_mem_3_en_out <= '1';
                mag_blk_mem_3_en_in <= '0';
            when "10" =>
                mag_blk_mem_0_en_out <= '1';
                mag_blk_mem_0_en_in <= '0';
                mag_blk_mem_1_en_out <= '0';
                mag_blk_mem_1_en_in <= '1';
                mag_blk_mem_2_en_out <= '1';
                mag_blk_mem_2_en_in <= '0';
                mag_blk_mem_3_en_out <= '1';
                mag_blk_mem_3_en_in <= '1';
            when others =>
                mag_blk_mem_0_en_out <= '1';
                mag_blk_mem_0_en_in <= '1';
                mag_blk_mem_1_en_out <= '1';
                mag_blk_mem_1_en_in <= '0';
                mag_blk_mem_2_en_out <= '0';
                mag_blk_mem_2_en_in <= '1';
                mag_blk_mem_3_en_out <= '1';
                mag_blk_mem_3_en_in <= '0';
        end case;

       -- dir memory connections to stage 3
       -- 2 lines behind the previous stage
        if iteration = 3*2 then
            -- reflect first line
            stage3_nms_dir0 <= dir_blk_mem_1_out;
            stage3_nms_dir1 <= dir_blk_mem_1_out;
            stage3_nms_dir2 <= dir_blk_mem_2_out;
            stage3_nms_dir3 <= dir_blk_mem_3_out;
        elsif iteration = height+3*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage3_nms_dir0 <= dir_blk_mem_1_out;
            stage3_nms_dir1 <= dir_blk_mem_1_out;
            stage3_nms_dir2 <= dir_blk_mem_2_out;
            stage3_nms_dir3 <= dir_blk_mem_3_out;
        else
            stage3_nms_dir0 <= dir_blk_mem_0_out;
            stage3_nms_dir1 <= dir_blk_mem_1_out;
            stage3_nms_dir2 <= dir_blk_mem_2_out;
            stage3_nms_dir3 <= dir_blk_mem_3_out;
        end if;

        -- mag memory connections to stage 3
        -- 2 lines behind the previous stage
        if iteration = 3*2 then
            -- reflect first line
            stage3_nms_mag0 <= mag_blk_mem_1_out;
            stage3_nms_mag1 <= mag_blk_mem_1_out;
            stage3_nms_mag2 <= mag_blk_mem_2_out;
            stage3_nms_mag3 <= mag_blk_mem_3_out;
        elsif iteration = height+3*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage3_nms_mag0 <= mag_blk_mem_1_out;
            stage3_nms_mag1 <= mag_blk_mem_1_out;
            stage3_nms_mag2 <= mag_blk_mem_2_out;
            stage3_nms_mag3 <= mag_blk_mem_3_out;
        else
            stage3_nms_mag0 <= mag_blk_mem_0_out;
            stage3_nms_mag1 <= mag_blk_mem_1_out;
            stage3_nms_mag2 <= mag_blk_mem_2_out;
            stage3_nms_mag3 <= mag_blk_mem_3_out;
        end if;

        -- dir memory address out
        if filter_pos = 0 then
            dir_blk_mem_addr_out <= std_logic_vector(filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            dir_blk_mem_addr_out <= std_logic_vector(filter_pos-1);
        elsif filter_pos = width+2-1 then
            dir_blk_mem_addr_out <= std_logic_vector(filter_pos-2);
        else
            dir_blk_mem_addr_out <= (others => '0');
        end if;

        -- mag memory address out
        if filter_pos = 0 then
            mag_blk_mem_addr_out <= std_logic_vector(filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            mag_blk_mem_addr_out <= std_logic_vector(filter_pos-1);
        elsif filter_pos = width+2-1 then
            mag_blk_mem_addr_out <= std_logic_vector(filter_pos-2);
        else
            mag_blk_mem_addr_out <= (others => '0');
        end if;

        -- nms memory address in and wea
        nms_blk_mem_0_wea <= "0";
        nms_blk_mem_1_wea <= "0";
        nms_blk_mem_2_wea <= "0";
        nms_blk_mem_3_wea <= "0";

        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 then
            case stage4_connect_rl_topmost_val is
                when "00" =>
                    nms_blk_mem_3_wea <= "1";
                when "01" =>
                    nms_blk_mem_0_wea <= "1";
                when "10" =>
                    nms_blk_mem_1_wea <= "1";
                when others =>
                    nms_blk_mem_2_wea <= "1";
            end case;

            nms_blk_mem_addr_0_in <= std_logic_vector(filter_pos - 6);
            nms_blk_mem_addr_1_in <= std_logic_vector(filter_pos - 6);
            nms_blk_mem_addr_2_in <= std_logic_vector(filter_pos - 6);
            nms_blk_mem_addr_3_in <= std_logic_vector(filter_pos - 6);
        else
            nms_blk_mem_addr_0_in <= (others => '0');
            nms_blk_mem_addr_1_in <= (others => '0');
            nms_blk_mem_addr_2_in <= (others => '0');
            nms_blk_mem_addr_3_in <= (others => '0');
        end if;

        -- nms memory write back from stage 4 address in
        -- timing stage 4
        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 and
               iteration >= 4*2 and iteration < height+4*2 then
            case stage4_connect_rl_topmost_val is
                when "00" =>
                    nms_blk_mem_1_wea <= "1";
                    nms_blk_mem_addr_1_in <= std_logic_vector(width - 1 - (filter_pos - 6));
                when "01" =>
                    nms_blk_mem_2_wea <= "1";
                    nms_blk_mem_addr_2_in <= std_logic_vector(width - 1 - (filter_pos - 6));
                when "10" =>
                    nms_blk_mem_3_wea <= "1";
                    nms_blk_mem_addr_3_in <= std_logic_vector(width - 1 - (filter_pos - 6));
                when others =>
                    nms_blk_mem_0_wea <= "1";
                    nms_blk_mem_addr_0_in <= std_logic_vector(width - 1 - (filter_pos - 6));
            end case;
        end if;

        -- nms memory in
        case stage4_connect_rl_topmost_val is
            when "00" =>
                nms_blk_mem_0_in <= stage3_nms_point_type;
                nms_blk_mem_1_in <= stage4_connect_rl_result;
                nms_blk_mem_2_in <= stage3_nms_point_type;
                nms_blk_mem_3_in <= stage3_nms_point_type;
            when "01" =>
                nms_blk_mem_0_in <= stage3_nms_point_type;
                nms_blk_mem_1_in <= stage3_nms_point_type;
                nms_blk_mem_2_in <= stage4_connect_rl_result;
                nms_blk_mem_3_in <= stage3_nms_point_type;
            when "10" =>
                nms_blk_mem_0_in <= stage3_nms_point_type;
                nms_blk_mem_1_in <= stage3_nms_point_type;
                nms_blk_mem_2_in <= stage3_nms_point_type;
                nms_blk_mem_3_in <= stage4_connect_rl_result;
            when others =>
                nms_blk_mem_0_in <= stage4_connect_rl_result;
                nms_blk_mem_1_in <= stage3_nms_point_type;
                nms_blk_mem_2_in <= stage3_nms_point_type;
                nms_blk_mem_3_in <= stage3_nms_point_type;
        end case;
    end process;


    ----------------------------------------------------------------------------------------------------------------------------------
    stage4_p : process(stage4_connect_rl_topmost_val, stage5_connect_lr_topmost_val,
                       filter_pos, iteration,
                       nms_blk_mem_0_out, nms_blk_mem_1_out, nms_blk_mem_2_out, nms_blk_mem_3_out,
                       stage4_connect_rl_result, stage5_connect_lr_result)
    begin
        -- stage 5 topmost value
        stage5_connect_lr_topmost_val <= std_logic_vector(unsigned(stage4_connect_rl_topmost_val) - 2);

        -- nms memory select in / out enable
        case stage4_connect_rl_topmost_val is
            when "00" =>
                nms_blk_mem_0_en_out <= '1';
                nms_blk_mem_0_en_in <= '0';
                nms_blk_mem_1_en_out <= '1';
                nms_blk_mem_1_en_in <= '1';
                nms_blk_mem_2_en_out <= '1';
                nms_blk_mem_2_en_in <= '0';
                nms_blk_mem_3_en_out <= '0';
                nms_blk_mem_3_en_in <= '1';
            when "01" =>
                nms_blk_mem_0_en_out <= '0';
                nms_blk_mem_0_en_in <= '1';
                nms_blk_mem_1_en_out <= '1';
                nms_blk_mem_1_en_in <= '0';
                nms_blk_mem_2_en_out <= '1';
                nms_blk_mem_2_en_in <= '1';
                nms_blk_mem_3_en_out <= '1';
                nms_blk_mem_3_en_in <= '0';
            when "10" =>
                nms_blk_mem_0_en_out <= '1';
                nms_blk_mem_0_en_in <= '0';
                nms_blk_mem_1_en_out <= '0';
                nms_blk_mem_1_en_in <= '1';
                nms_blk_mem_2_en_out <= '1';
                nms_blk_mem_2_en_in <= '0';
                nms_blk_mem_3_en_out <= '1';
                nms_blk_mem_3_en_in <= '1';
            when others =>
                nms_blk_mem_0_en_out <= '1';
                nms_blk_mem_0_en_in <= '1';
                nms_blk_mem_1_en_out <= '1';
                nms_blk_mem_1_en_in <= '0';
                nms_blk_mem_2_en_out <= '0';
                nms_blk_mem_2_en_in <= '1';
                nms_blk_mem_3_en_out <= '1';
                nms_blk_mem_3_en_in <= '0';
        end case;

        -- nms memory connections to stage 4
        -- 2 lines behind the previous stage
        if iteration = 4*2 then
            -- reflect first line
            stage4_connect_rl_val0 <= nms_blk_mem_1_out;
            stage4_connect_rl_val1 <= nms_blk_mem_1_out;
            stage4_connect_rl_val2 <= nms_blk_mem_2_out;
            stage4_connect_rl_val3 <= nms_blk_mem_3_out;
        elsif iteration = height+4*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage4_connect_rl_val0 <= nms_blk_mem_1_out;
            stage4_connect_rl_val1 <= nms_blk_mem_1_out;
            stage4_connect_rl_val2 <= nms_blk_mem_2_out;
            stage4_connect_rl_val3 <= nms_blk_mem_3_out;
        else
            stage4_connect_rl_val0 <= nms_blk_mem_0_out;
            stage4_connect_rl_val1 <= nms_blk_mem_1_out;
            stage4_connect_rl_val2 <= nms_blk_mem_2_out;
            stage4_connect_rl_val3 <= nms_blk_mem_3_out;
        end if;

        -- nms memory address out
        if filter_pos = 0 then
            nms_blk_mem_addr_out <= std_logic_vector(width - 1 - filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            nms_blk_mem_addr_out <= std_logic_vector(width - 1 - (filter_pos-1));
        elsif filter_pos = width+2-1 then
            nms_blk_mem_addr_out <= std_logic_vector(width - 1 - (filter_pos-2));
        else
            nms_blk_mem_addr_out <= std_logic_vector(width - 1);
        end if;

        -- conn memory address in and wea
        conn_blk_mem_0_wea <= "0";
        conn_blk_mem_1_wea <= "0";
        conn_blk_mem_2_wea <= "0";
        conn_blk_mem_3_wea <= "0";

        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 then
            case stage5_connect_lr_topmost_val is
                when "00" =>
                    conn_blk_mem_3_wea <= "1";
                when "01" =>
                    conn_blk_mem_0_wea <= "1";
                when "10" =>
                    conn_blk_mem_1_wea <= "1";
                when others =>
                    conn_blk_mem_2_wea <= "1";
            end case;

            conn_blk_mem_addr_0_in <= std_logic_vector(width - 1 - (filter_pos - 6));
            conn_blk_mem_addr_1_in <= std_logic_vector(width - 1 - (filter_pos - 6));
            conn_blk_mem_addr_2_in <= std_logic_vector(width - 1 - (filter_pos - 6));
            conn_blk_mem_addr_3_in <= std_logic_vector(width - 1 - (filter_pos - 6));
        else
            conn_blk_mem_addr_0_in <= std_logic_vector(width - 1);
            conn_blk_mem_addr_1_in <= std_logic_vector(width - 1);
            conn_blk_mem_addr_2_in <= std_logic_vector(width - 1);
            conn_blk_mem_addr_3_in <= std_logic_vector(width - 1);
        end if;

        -- conn memory write back from stage 5 address in
        -- timing stage 5
        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 and
                iteration >= 5*2 and iteration < height+5*2 then
            case stage5_connect_lr_topmost_val is
                when "00" =>
                    conn_blk_mem_1_wea <= "1";
                    conn_blk_mem_addr_1_in <= std_logic_vector(filter_pos - 6);
                when "01" =>
                    conn_blk_mem_2_wea <= "1";
                    conn_blk_mem_addr_2_in <= std_logic_vector(filter_pos - 6);
                when "10" =>
                    conn_blk_mem_3_wea <= "1";
                    conn_blk_mem_addr_3_in <= std_logic_vector(filter_pos - 6);
                when others =>
                    conn_blk_mem_0_wea <= "1";
                    conn_blk_mem_addr_0_in <= std_logic_vector(filter_pos - 6);
            end case;
        end if;

        -- conn memory in
        case stage5_connect_lr_topmost_val is
            when "00" =>
                conn_blk_mem_0_in <= stage4_connect_rl_result;
                conn_blk_mem_1_in <= '0' & stage5_connect_lr_result;
                conn_blk_mem_2_in <= stage4_connect_rl_result;
                conn_blk_mem_3_in <= stage4_connect_rl_result;
            when "01" =>
                conn_blk_mem_0_in <= stage4_connect_rl_result;
                conn_blk_mem_1_in <= stage4_connect_rl_result;
                conn_blk_mem_2_in <= '0' & stage5_connect_lr_result;
                conn_blk_mem_3_in <= stage4_connect_rl_result;
            when "10" =>
                conn_blk_mem_0_in <= stage4_connect_rl_result;
                conn_blk_mem_1_in <= stage4_connect_rl_result;
                conn_blk_mem_2_in <= stage4_connect_rl_result;
                conn_blk_mem_3_in <= '0' & stage5_connect_lr_result;
            when others =>
                conn_blk_mem_0_in <= '0' & stage5_connect_lr_result;
                conn_blk_mem_1_in <= stage4_connect_rl_result;
                conn_blk_mem_2_in <= stage4_connect_rl_result;
                conn_blk_mem_3_in <= stage4_connect_rl_result;
        end case;
    end process stage4_p;


    ----------------------------------------------------------------------------------------------------------------------------------
    stage5_p : process(stage5_connect_lr_topmost_val,
                       filter_pos, iteration,
                       conn_blk_mem_0_out, conn_blk_mem_1_out, conn_blk_mem_2_out, conn_blk_mem_3_out,
                       stage5_connect_lr_result)
    begin
        --  conn select in / out enable
        case stage5_connect_lr_topmost_val is
            when "00" =>
                conn_blk_mem_0_en_out <= '1';
                conn_blk_mem_0_en_in <= '0';
                conn_blk_mem_1_en_out <= '1';
                conn_blk_mem_1_en_in <= '1';
                conn_blk_mem_2_en_out <= '1';
                conn_blk_mem_2_en_in <= '0';
                conn_blk_mem_3_en_out <= '0';
                conn_blk_mem_3_en_in <= '1';
                when "01" =>
                conn_blk_mem_0_en_out <= '0';
                conn_blk_mem_0_en_in <= '1';
                conn_blk_mem_1_en_out <= '1';
                conn_blk_mem_1_en_in <= '0';
                conn_blk_mem_2_en_out <= '1';
                conn_blk_mem_2_en_in <= '1';
                conn_blk_mem_3_en_out <= '1';
                conn_blk_mem_3_en_in <= '0';
                when "10" =>
                conn_blk_mem_0_en_out <= '1';
                conn_blk_mem_0_en_in <= '0';
                conn_blk_mem_1_en_out <= '0';
                conn_blk_mem_1_en_in <= '1';
                conn_blk_mem_2_en_out <= '1';
                conn_blk_mem_2_en_in <= '0';
                conn_blk_mem_3_en_out <= '1';
                conn_blk_mem_3_en_in <= '1';
                when others =>
                conn_blk_mem_0_en_out <= '1';
                conn_blk_mem_0_en_in <= '1';
                conn_blk_mem_1_en_out <= '1';
                conn_blk_mem_1_en_in <= '0';
                conn_blk_mem_2_en_out <= '0';
                conn_blk_mem_2_en_in <= '1';
                conn_blk_mem_3_en_out <= '1';
                conn_blk_mem_3_en_in <= '0';
        end case;

        -- conn memory connections to stage 5
        -- 2 lines behind the previous stage
        if iteration = 5*2 then
            -- reflect first line
            stage5_connect_lr_val0 <= conn_blk_mem_1_out;
            stage5_connect_lr_val1 <= conn_blk_mem_1_out;
            stage5_connect_lr_val2 <= conn_blk_mem_2_out;
            stage5_connect_lr_val3 <= conn_blk_mem_3_out;
        elsif iteration = height+5*2-1 then
            -- height-1 mod 4 = 3
            -- reflect last line
            stage5_connect_lr_val0 <= conn_blk_mem_1_out;
            stage5_connect_lr_val1 <= conn_blk_mem_1_out;
            stage5_connect_lr_val2 <= conn_blk_mem_2_out;
            stage5_connect_lr_val3 <= conn_blk_mem_3_out;
        else
            stage5_connect_lr_val0 <= conn_blk_mem_0_out;
            stage5_connect_lr_val1 <= conn_blk_mem_1_out;
            stage5_connect_lr_val2 <= conn_blk_mem_2_out;
            stage5_connect_lr_val3 <= conn_blk_mem_3_out;
        end if;

        -- conn memory address out
        if filter_pos = 0 then
            conn_blk_mem_addr_out <= std_logic_vector(filter_pos);
        -- +2 because of 2 reflections
        elsif filter_pos > 0 and filter_pos < width+2-1 then
            conn_blk_mem_addr_out <= std_logic_vector(filter_pos-1);
        elsif filter_pos = width+2-1 then
            conn_blk_mem_addr_out <= std_logic_vector(filter_pos-2);
        else
            conn_blk_mem_addr_out <= (others => '0');
        end if;

        -- write result
        -- timing stage 5
        -- 1. & 2. clock: memory adressing
        -- 3. and 4. clock: filter delay
        -- 5. & 6. clock: fill filter pipeline
        if filter_pos >= 6 and filter_pos < width+6 and
                iteration >= 5*2 and iteration < height+5*2 then
            output_line <= '1';
            on_edge <= stage5_connect_lr_result;
        else
            output_line <= '0';
            on_edge <= '0';
        end if;
end process stage5_p;


    --================================================================================================================================
    state_p : process(clk)
    begin
        if rising_edge(clk) then
            reset_fifo <= '0';
            output_image_old <= output_image;
        
            reset_pipelines <= '0';

            camera_blk_mem_0_wea <= "0";
            camera_blk_mem_1_wea <= "0";
            camera_blk_mem_2_wea <= "0";
            camera_blk_mem_3_wea <= "0";

            if reset = '1' then
                state <= init;
                
                camera_blk_mem_addr_in_cnt <= (others => '1');
                filter_pos <= (others => '0');
                iteration <= (others => '0');
                stage1_gauss_topmost_val <= "10"; -- first the data should be written in camera_blk_mem0

                line_camera_ready <= false;
                line_filter_ready <= false;

                do_process <= false;

                reset_pipelines <= '1';
            else
                if en = '1' then
                    case state is
                        when init =>
                            camera_blk_mem_addr_in_cnt <= (others => '1');
                            filter_pos <= (others => '0');
                            iteration <= (others => '0');
                            stage1_gauss_topmost_val <= "10"; -- first the data should be written in camera_blk_mem0

                            line_camera_ready <= false;
                            line_filter_ready <= false;

                            do_process <= false;

                            state <= run;
                            reset_pipelines <= '1';
                        when run =>
                            if do_process or (output_image_old = '0' and output_image = '1') then
                                do_process <= true;

                                -- TODO 650 is a dummy value
                                -- filter next value
                                if filter_pos < 650 then
                                    filter_pos <= filter_pos + 1;
                                else
                                    line_filter_ready <= true;
                                end if;

                                -- stage 1 enable
                                -- stage1_gauss_val1 and stage1_gauss_val3 are filled stage1_gauss_val1 is reflected to stage1_gauss_val0
                                if iteration >= 1*2 and iteration < height+1*2 then
                                    stage1_gauss_en <= '1';
                                end if;

                                -- stage 2 enable
                                if iteration >= 2*2 and iteration < height+2*2 then
                                    stage2_magangle_en <= '1';
                                end if;

                                -- stage 3 enable
                                if iteration >= 3*2 and iteration < height+3*2 then
                                    stage3_nms_en <= '1';
                                end if;

                                -- stage 4 enable
                                if iteration >= 4*2 and iteration < height+4*2 then
                                    stage4_connect_rl_en <= '1';
                                end if;

                                -- stage 5 enable
                                if iteration >= 5*2 and iteration < height+5*2 then
                                    stage5_connect_lr_en <= '1';
                                end if;

                                -- new value from camera
                                if iteration >= 0 and iteration < height then
                                    if gray_valid = '1' and
                                            ((camera_blk_mem_addr_in_cnt < width) or (camera_blk_mem_addr_in_cnt = (camera_blk_mem_addr_in_cnt'range => '1'))) then
                                        gray_buff <= gray;

                                        case stage1_gauss_topmost_val is
                                            when "00" => camera_blk_mem_3_wea <= "1";
                                            when "01" => camera_blk_mem_0_wea <= "1";
                                            when "10" => camera_blk_mem_1_wea <= "1";
                                            when others => camera_blk_mem_2_wea <= "1";
                                        end case;

                                        camera_blk_mem_addr_in_cnt <= camera_blk_mem_addr_in_cnt + 1;
                                    elsif camera_blk_mem_addr_in_cnt = width-1 then
                                        line_camera_ready <= true;
                                    end if;
                                else
                                    line_camera_ready <= true;
                                end if;

                                -- end of line
                                if line_filter_ready and line_camera_ready then
                                    camera_blk_mem_addr_in_cnt <= (others => '1');
                                    filter_pos <= (others => '0');
                                    reset_pipelines <= '1';
                                    line_filter_ready <= false;
                                    line_camera_ready <= false;

                                    iteration <= iteration + 1;
                                    stage1_gauss_topmost_val <= std_logic_vector(unsigned(stage1_gauss_topmost_val) + 1);

                                    if iteration = height+5*2-1 then
                                        state <= init;
                                        reset_fifo <= '1';
                                        iteration <= (others => '0');
                                    end if;
                                end if;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process state_p;
end architecture canny_beh;
