library ieee;

use ieee.std_logic_1164.all;

entity shift_reg is
    generic(bits : integer);
    port(signal clk : in std_logic;
         signal reset : in std_logic;
         signal shift : in std_logic;
         signal a : in std_logic_vector(bits-1 downto 0);
         signal z0 : out std_logic_vector(bits-1 downto 0);
         signal z1 : out std_logic_vector(bits-1 downto 0);
         signal z2 : out std_logic_vector(bits-1 downto 0));
end entity shift_reg;

architecture shift_reg_beh of shift_reg is

    signal z0_buff : std_logic_vector(bits-1 downto 0) := (others => '0');
    signal z1_buff : std_logic_vector(bits-1 downto 0) := (others => '0');
    signal z2_buff : std_logic_vector(bits-1 downto 0) := (others => '0');
begin
    z0 <= z0_buff;
    z1 <= z1_buff;
    z2 <= z2_buff;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                z0_buff <= (others => '0');
                z1_buff <= (others => '0');
                z2_buff <= (others => '0');
            else
                if shift = '1' then
                    z2_buff <= z1_buff;
                    z1_buff <= z0_buff;
                    z0_buff <= a;
                end if;
            end if;
        end if;
    end process;
end architecture shift_reg_beh;
