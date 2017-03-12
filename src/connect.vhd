library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity connect is
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
end entity connect;

architecture connect_beh of connect is
    signal result_temp : std_logic_vector(result'length-1 downto 0) := (others => '0');
    signal strong_temp : std_logic := '0';
begin
    result <= result_temp;
    strong <= strong_temp;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                strong_temp <= '0';
                result_temp <= (others => '0');
            else
                if en = '1' then
                    case e11 is
                        when "01" =>
                            strong_temp <= '0';
                            result_temp <= "01";
                        when "10" =>
                            -- if any LSB is '1' the point has a strong neighbor (strong point --> "01")
                            if (set_strong or e00(0) or e01(0) or e02(0) or e10(0) or e12(0) or e20(0) or e21(0) or e22(0)) = '1' then
                                strong_temp <= '1';
                                result_temp <= "01";
                            else
                                strong_temp <= '0';
                                result_temp <= "10";
                            end if;
                        when others =>
                            result_temp <= (others => '0');
                            strong_temp <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;
end architecture connect_beh;
