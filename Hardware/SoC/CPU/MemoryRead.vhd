library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryRead is
    port
    (
        address_in: in CPU_ADDRESS_TYPE;
        value_out: out std_logic;
        done_job: out std_logic
    );
end MemoryRead;