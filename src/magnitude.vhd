library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity magnitude is
    -- 0 -- 16320*2 = 0 -- 32640
    port(signal clk : in std_logic;
         signal reset : in std_logic;
         signal en : in std_logic;
         signal a : in std_logic_vector(15-1 downto 0);
         signal b : in std_logic_vector(15-1 downto 0);
         signal z : out std_logic_vector(15-1 downto 0));
end entity magnitude;

architecture magnitude_beh of magnitude is
    signal z_temp : unsigned(z'length-1 downto 0) := (others => '0');
begin
    z <= std_logic_vector(z_temp);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                z_temp <= (others => '0');
            else
                if en = '1' then
                    z_temp <= unsigned(abs(signed(a))) + unsigned(abs(signed(b)));
                end if;
            end if;
        end if;
    end process;
end architecture magnitude_beh;
