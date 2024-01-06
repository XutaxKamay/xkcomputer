library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory is
    port
    (
        request: inout std_logic;
        address_in: in CPU_ADDRESS_TYPE;
        mode: in MEMORY_MODE_TYPE;
        value: inout std_logic_vector((MEMORY_MAX_WORD_SIZE - 1) downto 0)
    );
end Memory;

architecture Memory_Implementation of Memory is
    constant MAX_MEMORY_IN_BITS: integer := 2**24;
    signal signal_internal_memory: std_logic_vector((MAX_MEMORY_IN_BITS - 1) downto 0);
begin
    process (request)
    begin
        if rising_edge(request) then
            if address_in + value'length < MAX_MEMORY_IN_BITS then
                case mode is
                    when MEMORY_MODE_READ =>
                        value <= signal_internal_memory((to_integer(address_in) + value'length - 1) downto to_integer(address_in));
                    when MEMORY_MODE_WRITE =>
                        signal_internal_memory((to_integer(address_in) + value'length - 1) downto to_integer(address_in)) <= value;
                end case;
            end if;
            request <= '0';
        end if;
    end process;
end architecture;