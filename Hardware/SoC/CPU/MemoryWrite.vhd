library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryWrite is
    port
    (
        address_in: in CPU_ADDRESS_TYPE;
        request_size: in CPU_ADDRESS_TYPE;
        value_in: in std_logic_vector((MEMORY_MAX_WORD_SIZE - 1) downto 0);
        done_job: out std_logic
    );
end MemoryWrite;