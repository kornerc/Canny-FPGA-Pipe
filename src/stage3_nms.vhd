library ieee;

use ieee.std_logic_1164.all;

--! @brief stage 3 of pipeline; non maximum suppression and hysteresis
--! @details It takes 2 clock cyles for an input value, to appear at the output.
--! 1 clock for the input shift register and 1 clock cycle for the non maximum suppression.
--! The 3 input values are the values of the line which should be filtered and
--! the values of the line above and below, starting from the left values to the
--! right ones.
entity stage3_nms is
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
end entity stage3_nms;

architecture stage3_nms_beh of stage3_nms is
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

    component non_maximum_suppression is
        port(signal clk : in std_logic;
             signal reset : in std_logic;
             signal en : in std_logic;
             signal thr_upper : in std_logic_vector(15-1 downto 0);
             signal thr_lower : in std_logic_vector(15-1 downto 0);
             signal reset_mag10 : in std_logic;
             signal mag00 : in std_logic_vector(15-1 downto 0);
             signal mag01 : in std_logic_vector(15-1 downto 0);
             signal mag02 : in std_logic_vector(15-1 downto 0);
             signal mag10 : in std_logic_vector(15-1 downto 0);
             signal mag11 : in std_logic_vector(15-1 downto 0);
             signal mag12 : in std_logic_vector(15-1 downto 0);
             signal mag20 : in std_logic_vector(15-1 downto 0);
             signal mag21 : in std_logic_vector(15-1 downto 0);
             signal mag22 : in std_logic_vector(15-1 downto 0);
             signal dir11 : in std_logic_vector(2-1 downto 0);
             signal result : out std_logic_vector(2-1 downto 0);
             signal reset_mag : out std_logic);
    end component non_maximum_suppression;

    signal muxangles : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux0s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux1s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal mux2s : std_logic_vector(2-1 downto 0) := (others => '0');

    signal muxanglez_shiftreganglea : std_logic_vector(angle0'length-1 downto 0);
    signal shiftreganglea_nmsdir11 : std_logic_vector(angle0'length-1 downto 0);

    signal mux0z_shiftreg0a : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg0z0_nmsmag02 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg0z1_nmsmag01 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg0z2_nmsmag00 : std_logic_vector(mag0'length-1 downto 0);

    signal mux1z_shiftreg1a : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg1z0_nmsmag12 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg1z1_nmsmag11 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg1z2_nmsmag10 : std_logic_vector(mag0'length-1 downto 0);

    signal mux2z_shiftreg2a : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg2z0_nmsmag22 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg2z1_nmsmag21 : std_logic_vector(mag0'length-1 downto 0);
    signal shiftreg2z2_nmsmag20 : std_logic_vector(mag0'length-1 downto 0);

    signal nmsreset_mag10 : std_logic;
begin

    MUXANGLE : mux4 generic map(bits => angle0'length)
                  port map(s => muxangles,
                           a0 => angle0,
                           a1 => angle1,
                           a2 => angle2,
                           a3 => angle3,
                           z => muxanglez_shiftreganglea);

    SHIFTREGANGLE : shift_reg generic map(bits => angle0'length)
                              port map(clk => clk,
                                       reset => reset,
                                       shift => en,
                                       a => muxanglez_shiftreganglea,
                                       z0 => open,
                                       z1 => shiftreganglea_nmsdir11,
                                       z2 => open);

    MUX0 : mux4 generic map(bits => mag0'length)
                port map(s => mux0s,
                         a0 => mag0,
                         a1 => mag1,
                         a2 => mag2,
                         a3 => mag3,
                         z => mux0z_shiftreg0a);
    MUX1 : mux4 generic map(bits => mag0'length)
                port map(s => mux1s,
                         a0 => mag0,
                         a1 => mag1,
                         a2 => mag2,
                         a3 => mag3,
                         z => mux1z_shiftreg1a);
    MUX2 : mux4 generic map(bits => mag0'length)
                port map(s => mux2s,
                         a0 => mag0,
                         a1 => mag1,
                         a2 => mag2,
                         a3 => mag3,
                         z => mux2z_shiftreg2a);

    SHIFTREG0 : shift_reg generic map(bits => mag0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux0z_shiftreg0a,
                                   z0 => shiftreg0z0_nmsmag02,
                                   z1 => shiftreg0z1_nmsmag01,
                                   z2 => shiftreg0z2_nmsmag00);
    SHIFTREG1 : shift_reg generic map(bits => mag0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux1z_shiftreg1a,
                                   z0 => shiftreg1z0_nmsmag12,
                                   z1 => shiftreg1z1_nmsmag11,
                                   z2 => shiftreg1z2_nmsmag10);
    SHIFTREG2 : shift_reg generic map(bits => mag0'length)
                          port map(clk => clk,
                                   reset => reset,
                                   shift => en,
                                   a => mux2z_shiftreg2a,
                                   z0 => shiftreg2z0_nmsmag22,
                                   z1 => shiftreg2z1_nmsmag21,
                                   z2 => shiftreg2z2_nmsmag20);

    NMS : non_maximum_suppression port map(clk => clk,
                                           reset => reset,
                                           en => en,
                                           thr_upper => thr_upper,
                                           thr_lower => thr_lower,
                                           reset_mag10 => nmsreset_mag10,
                                           mag00 => shiftreg0z2_nmsmag00,
                                           mag01 => shiftreg0z1_nmsmag01,
                                           mag02 => shiftreg0z0_nmsmag02,
                                           mag10 => shiftreg1z2_nmsmag10,
                                           mag11 => shiftreg1z1_nmsmag11,
                                           mag12 => shiftreg1z0_nmsmag12,
                                           mag20 => shiftreg2z2_nmsmag20,
                                           mag21 => shiftreg2z1_nmsmag21,
                                           mag22 => shiftreg2z0_nmsmag22,
                                           dir11 => shiftreganglea_nmsdir11,
                                           result => point_type,
                                           reset_mag => nmsreset_mag10);

    reset_val <= nmsreset_mag10;

    mux_select : process(topmost_val)
    begin
        case topmost_val is
            when "00" =>
                mux0s <= "00";
                mux1s <= "01";
                muxangles <= "01";
                mux2s <= "10";
            when "01" =>
                mux0s <= "01";
                mux1s <= "10";
                muxangles <= "10";
                mux2s <= "11";
            when "10" =>
                mux0s <= "10";
                mux1s <= "11";
                muxangles <= "11";
                mux2s <= "00";
            when others =>
                mux0s <= "11";
                mux1s <= "00";
                muxangles <= "00";
                mux2s <= "01";
        end case;
    end process;

end architecture stage3_nms_beh;
