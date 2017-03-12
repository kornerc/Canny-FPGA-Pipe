library ieee;

use ieee.std_logic_1164.all;

--! @brief stage 5 of pipeline; connect the points beginning from bottom right to top left (line wise right to left).
--! @details It takes 2 clock cyles for an input value, to appear at the output.
--! 1 clock for the input shift register and 1 clock cycle for the connection.
--! The 3 input values are the values of the line which should be filtered and
--! the values of the line above and below, starting from the left values to the
--! right ones.
entity stage5_connect_lr is
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
end entity stage5_connect_lr;

architecture stage5_connect_lr_beh of stage5_connect_lr is
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_PARAMETER of reset : signal is "POLARITY ACTIVE_HIGH";

    component connect_lines is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal val0 : in std_logic_vector(2-1 downto 0);
             signal val1 : in std_logic_vector(2-1 downto 0);
             signal val2 : in std_logic_vector(2-1 downto 0);
             signal val3 : in std_logic_vector(2-1 downto 0);
             signal topmost_val : in std_logic_vector(2-1 downto 0);
             signal result : out std_logic_vector(2-1 downto 0));
    end component connect_lines;

    signal result_temp : std_logic_vector(2-1 downto 0);
begin
    CONN_LINES : connect_lines port map(clk => clk,
                                        reset => reset,
                                        en => en,
                                        val0 => val0,
                                        val1 => val1,
                                        val2 => val2,
                                        val3 => val3,
                                        topmost_val => topmost_val,
                                        result => result_temp);

    result_c : process(result_temp)
    begin
        if result_temp = "01" then
            result <= '1';
        else
            result <= '0';
        end if;
    end process;
end architecture stage5_connect_lr_beh;
