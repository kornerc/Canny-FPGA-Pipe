library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity filter_gauss is
    -- kernel: / 1 2 1 \
    --         | 2 4 2 |
    --         \ 1 2 1 /
    -- 0 -- 255*16 = 0 --4080
    port(signal clk : in std_logic;
         signal reset : in std_logic;
         signal en : in std_logic;
         signal e00 : in std_logic_vector(8-1 downto 0);
         signal e01 : in std_logic_vector(8-1 downto 0);
         signal e02 : in std_logic_vector(8-1 downto 0);
         signal e10 : in std_logic_vector(8-1 downto 0);
         signal e11 : in std_logic_vector(8-1 downto 0);
         signal e12 : in std_logic_vector(8-1 downto 0);
         signal e20 : in std_logic_vector(8-1 downto 0);
         signal e21 : in std_logic_vector(8-1 downto 0);
         signal e22 : in std_logic_vector(8-1 downto 0);
         signal result : out std_logic_vector(12-1 downto 0));
end entity filter_gauss;

architecture filter_gauss_beh of filter_gauss is
    signal result_temp : unsigned(result'length-1 downto 0) := (others => '0');
begin
    result <= std_logic_vector(result_temp);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                result_temp <= (others => '0');
            else
                if en = '1' then
                    result_temp <=
                            resize(unsigned(e00), result'length) -- 1*e00
                            + shift_left(resize(unsigned(e01), result'length), 1) -- 2*e01
                            + resize(unsigned(e02), result'length) -- 1*e02
                            + shift_left(resize(unsigned(e10), result'length), 1) -- 2*e10
                            + shift_left(resize(unsigned(e11), result'length), 2) -- 4*e11
                            + shift_left(resize(unsigned(e12), result'length), 1) -- 2*e12
                            + resize(unsigned(e20), result'length) -- 1*e20
                            + shift_left(resize(unsigned(e21), result'length), 1) -- 2*e21
                            + resize(unsigned(e22), result'length); -- 1*e22
                end if;
            end if;
        end if;
    end process;
end architecture filter_gauss_beh;
