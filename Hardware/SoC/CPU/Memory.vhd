library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory is
    port
    (
        request: inout std_logic;
        address_in: in CPU_ADDRESS_TYPE;
        request_size: in CPU_ADDRESS_TYPE;
        mode: in MEMORY_MODE_TYPE;
        value: inout std_logic_vector((MEMORY_MAX_WORD_SIZE - 1) downto 0)
    );
end Memory;

architecture Memory_Implementation of Memory is
begin
    process (request)
    begin
        if rising_edge(request) then
            case mode is
                when MEMORY_MODE_READ =>
                when MEMORY_MODE_WRITE =>
            end case;
            request <= '0';
        end if;
    end process;
end architecture;