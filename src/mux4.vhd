library ieee;

use ieee.std_logic_1164.all;

entity mux4 is
    generic(bits : integer);
    port(signal s : in std_logic_vector(2-1 downto 0);
         signal a0 : in std_logic_vector(bits-1 downto 0);
         signal a1 : in std_logic_vector(bits-1 downto 0);
         signal a2 : in std_logic_vector(bits-1 downto 0);
         signal a3 : in std_logic_vector(bits-1 downto 0);
         signal z : out std_logic_vector(bits-1 downto 0));
end entity mux4;

architecture mux4_beh of mux4 is
begin
    process(s, a0, a1, a2, a3)
    begin
        z <= (others => '0');

        case s is
            when "00" =>
                z <= a0;
            when "01" =>
                z <= a1;
            when "10" =>
                z <= a2;
            when others =>
                z <= a3;
        end case;
    end process;
end architecture mux4_beh;
