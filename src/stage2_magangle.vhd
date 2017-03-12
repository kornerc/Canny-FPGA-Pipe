library ieee;

use ieee.std_logic_1164.all;

--! @brief stage 2 of pipeline; sobel filtering, and magnitude and direction calculation
--! @details It takes 3 clock cyles for an input value, to appear at the output.
--! 1 clock for the input shift register, 1 clock cycle for the sobel filters
--! and 1 clock cycle for the magnitude and direction calculation.
--! The 3 input values are the values of the line which should be filtered and
--! the values of the line above and below, starting from the left values to the
--! right ones.
entity stage2_magangle is
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
end entity stage2_magangle;

architecture stage2_magangle_beh of stage2_magangle is
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_PARAMETER of reset : signal is "POLARITY ACTIVE_HIGH";

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

    component filter_sobelx is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal e00 : in std_logic_vector(12-1 downto 0);
             signal e01 : in std_logic_vector(12-1 downto 0);
             signal e02 : in std_logic_vector(12-1 downto 0);
             signal e10 : in std_logic_vector(12-1 downto 0);
             signal e11 : in std_logic_vector(12-1 downto 0);
             signal e12 : in std_logic_vector(12-1 downto 0);
             signal e20 : in std_logic_vector(12-1 downto 0);
             signal e21 : in std_logic_vector(12-1 downto 0);
             signal e22 : in std_logic_vector(12-1 downto 0);
             signal result : out std_logic_vector(15-1 downto 0));
    end component filter_sobelx;

    component filter_sobely is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal e00 : in std_logic_vector(12-1 downto 0);
             signal e01 : in std_logic_vector(12-1 downto 0);
             signal e02 : in std_logic_vector(12-1 downto 0);
             signal e10 : in std_logic_vector(12-1 downto 0);
             signal e11 : in std_logic_vector(12-1 downto 0);
             signal e12 : in std_logic_vector(12-1 downto 0);
             signal e20 : in std_logic_vector(12-1 downto 0);
             signal e21 : in std_logic_vector(12-1 downto 0);
             signal e22 : in std_logic_vector(12-1 downto 0);
             signal result : out std_logic_vector(15-1 downto 0));
    end component filter_sobely;

    component magnitude is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal a : in std_logic_vector(15-1 downto 0);
             signal b : in std_logic_vector(15-1 downto 0);
             signal z : out std_logic_vector(15-1 downto 0));
    end component magnitude;

    component angle is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal y : in std_logic_vector(15-1 downto 0);
             signal x : in std_logic_vector(15-1 downto 0);
             signal direction : out std_logic_vector(2-1 downto 0));
    end component angle;

    for ANGLECOMP : angle use entity work.angle(angle_approx_beh);

    signal mux0s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux1s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux2s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux0z_shiftreg0a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z0_e02 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z1_e01 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg0z2_e00 : std_logic_vector(val0'length-1 downto 0);

    signal mux1z_shiftreg1a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z0_e12 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z1_e11 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg1z2_e10 : std_logic_vector(val0'length-1 downto 0);

    signal mux2z_shiftreg2a : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z0_e22 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z1_e21 : std_logic_vector(val0'length-1 downto 0);
    signal shiftreg2z2_e20 : std_logic_vector(val0'length-1 downto 0);

    signal dx : std_logic_vector(15-1 downto 0);
    signal dy : std_logic_vector(15-1 downto 0);
begin

    MUX0 : mux4 generic map(bits => val0'length)
                port map(s => mux0s,
                         a0 => val0,
                         a1 => val1,
                         a2 => val2,
                         a3 => val3,
                         z =>mux0z_shiftreg0a);
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
                                   z0 => shiftreg0z0_e02,
                                   z1 => shiftreg0z1_e01,
                                   z2 => shiftreg0z2_e00);
    SHIFTREG1 : shift_reg generic map(bits => val0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux1z_shiftreg1a,
                                   z0 => shiftreg1z0_e12,
                                   z1 => shiftreg1z1_e11,
                                   z2 => shiftreg1z2_e10);
    SHIFTREG2 : shift_reg generic map(bits => val0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux2z_shiftreg2a,
                                   z0 => shiftreg2z0_e22,
                                   z1 => shiftreg2z1_e21,
                                   z2 => shiftreg2z2_e20);

    SOBELX : filter_sobelx port map(clk => clk,
                                    reset => reset,
                                    en => en,
                                    e00 => shiftreg0z2_e00,
                                    e01 => shiftreg0z1_e01,
                                    e02 => shiftreg0z0_e02,
                                    e10 => shiftreg1z2_e10,
                                    e11 => shiftreg1z1_e11,
                                    e12 => shiftreg1z0_e12,
                                    e20 => shiftreg2z2_e20,
                                    e21 => shiftreg2z1_e21,
                                    e22 => shiftreg2z0_e22,
                                    result => dx);

    SOBELY : filter_sobely port map(clk => clk,
                                    reset => reset,
                                    en => en,
                                    e00 => shiftreg0z2_e00,
                                    e01 => shiftreg0z1_e01,
                                    e02 => shiftreg0z0_e02,
                                    e10 => shiftreg1z2_e10,
                                    e11 => shiftreg1z1_e11,
                                    e12 => shiftreg1z0_e12,
                                    e20 => shiftreg2z2_e20,
                                    e21 => shiftreg2z1_e21,
                                    e22 => shiftreg2z0_e22,
                                    result => dy);


    MAGCOMP : magnitude port map(clk => clk,
                                 reset => reset,
                                 en => en,
                                 a => dx,
                                 b => dy,
                                 z => mag);

    ANGLECOMP : angle port map(clk => clk,
                               reset => reset,
                               en => en,
                               y => dy,
                               x => dx,
                               direction => direction);


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

end architecture stage2_magangle_beh;
