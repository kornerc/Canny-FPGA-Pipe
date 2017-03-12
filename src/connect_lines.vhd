library ieee;

use ieee.std_logic_1164.all;

--! @brief stage 4 of pipeline
--! @details It takes 2 clock cyles for an input value, to appear at the output.
--! 1 clock for the input shift register and 1 clock cycle for the connection.
--! The 3 input values are the values of the line which should be filtered and
--! the values of the line above and below, starting from the left values to the
--! right ones.
entity connect_lines is
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
end entity connect_lines;

architecture connect_lines_beh of connect_lines is
    component mux4 is
        generic(bits : integer);
        port(signal s : in std_logic_vector(2-1 downto 0);
             signal a0 : in std_logic_vector(bits-1 downto 0);
             signal a1 : in std_logic_vector(bits-1 downto 0);
             signal a2 : in std_logic_vector(bits-1 downto 0);
             signal a3 : in std_logic_vector(bits-1 downto 0);
             signal z : out std_logic_vector(bits-1 downto 0));
    end component mux4;

    component shift_reg is
        generic(bits : integer);
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal shift : in std_logic;
             signal a : in std_logic_vector(bits-1 downto 0);
             signal z0 : out std_logic_vector(bits-1 downto 0);
             signal z1 : out std_logic_vector(bits-1 downto 0);
             signal z2 : out std_logic_vector(bits-1 downto 0));
    end component shift_reg;

    component connect is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal set_strong : in std_logic;
             signal e00 : in std_logic_vector(2-1 downto 0);
             signal e01 : in std_logic_vector(2-1 downto 0);
             signal e02 : in std_logic_vector(2-1 downto 0);
             signal e10 : in std_logic_vector(2-1 downto 0);
             signal e11 : in std_logic_vector(2-1 downto 0);
             signal e12 : in std_logic_vector(2-1 downto 0);
             signal e20 : in std_logic_vector(2-1 downto 0);
             signal e21 : in std_logic_vector(2-1 downto 0);
             signal e22 : in std_logic_vector(2-1 downto 0);
             signal strong : out std_logic;
             signal result : out std_logic_vector(2-1 downto 0));
    end component connect;

    constant zero : std_logic := '0';

    signal mux0s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux1s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux2s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux0z_shiftreg0a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z0_neighbore02 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z1_neighbore01 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z2_neighbore00 : std_logic_vector(val0'length-1 downto 0);

    signal mux1z_shiftreg1a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z0_neighbore12 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z1_neighbore11 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z2_neighbore10 : std_logic_vector(val0'length-1 downto 0);

    signal mux2z_shiftreg2a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z0_neighbore22 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z1_neighbore21 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z2_neighbore20 : std_logic_vector(val0'length-1 downto 0);

    signal strong_s : std_logic;
begin

    MUX0 : mux4 generic map(bits => val0'length)
                port map(s => mux0s,
                         a0 => val0,
                         a1 => val1,
                         a2 => val2,
                         a3 => val3,
                         z => mux0z_shiftreg0a);
    MUX1 : mux4 generic map(bits => val0'length)
                port map(s => mux1s,
                         a0 => val0,
                         a1 => val1,
                         a2 => val2,
                         a3 => val3,
                         z => mux1z_shiftreg1a);
    MUX2 : mux4 generic map(bits => val0'length)
                port map(s => mux2s,
                         a0 => val0,
                         a1 => val1,
                         a2 => val2,
                         a3 => val3,
                         z => mux2z_shiftreg2a);

    SHIFTREG0 : shift_reg generic map(bits => val0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux0z_shiftreg0a,
                                   z0 => shiftreg0z0_neighbore02,
                                   z1 => shiftreg0z1_neighbore01,
                                   z2 => shiftreg0z2_neighbore00);
    SHIFTREG1 : shift_reg generic map(bits => val0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux1z_shiftreg1a,
                                   z0 => shiftreg1z0_neighbore12,
                                   z1 => shiftreg1z1_neighbore11,
                                   z2 => shiftreg1z2_neighbore10);
    SHIFTREG2 : shift_reg generic map(bits => val0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux2z_shiftreg2a,
                                   z0 => shiftreg2z0_neighbore22,
                                   z1 => shiftreg2z1_neighbore21,
                                   z2 => shiftreg2z2_neighbore20);

    NEIGHBOR : connect port map(clk => clk,
                                reset => reset,
                                en => en,
                                set_strong => strong_s,
                                e00 => shiftreg0z2_neighbore00,
                                e01 => shiftreg0z1_neighbore01,
                                e02 => shiftreg0z0_neighbore02,
                                e10 => shiftreg1z2_neighbore10,
                                e11 => shiftreg1z1_neighbore11,
                                e12 => shiftreg1z0_neighbore12,
                                e20 => shiftreg2z2_neighbore20,
                                e21 => shiftreg2z1_neighbore21,
                                e22 => shiftreg2z0_neighbore22,
                                strong => strong_s,
                                result => result);

    mux_select : process(topmost_val)
    begin
        case topmost_val is
            when "00" =>
                mux0s <= "00";
                mux1s <= "01";
                mux2s <= "10";
            when "01" =>
                mux0s <= "01";
                mux1s <= "10";
                mux2s <= "11";
            when "10" =>
                mux0s <= "10";
                mux1s <= "11";
                mux2s <= "00";
            when others =>
                mux0s <= "11";
                mux1s <= "00";
                mux2s <= "01";
        end case;
    end process;
end architecture connect_lines_beh;
