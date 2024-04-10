library ieee;

use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity CentralProcessingUnit_TestBench is
end;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit_TestBench is

    component CentralProcessingUnit
        port (
            committing_read_memory  : inout BOOLEAN;
            committing_write_memory : inout BOOLEAN;
            memory_address_read     : out CPU_ADDRESS_TYPE;
            memory_address_write    : out CPU_ADDRESS_TYPE;
            memory_word_read        : in WORD_TYPE;
            memory_word_write       : out WORD_TYPE
        );
    end component;

    -- Ports
    signal committing_read_memory  : BOOLEAN;
    signal committing_write_memory : BOOLEAN;
    signal memory_address_read     : CPU_ADDRESS_TYPE;
    signal memory_address_write    : CPU_ADDRESS_TYPE;
    signal memory_word_read        : WORD_TYPE;
    signal memory_word_write       : WORD_TYPE;
    signal self_clock              : BOOLEAN;

begin

    CentralProcessingUnit_inst : CentralProcessingUnit
    port map(
        committing_read_memory  => committing_read_memory,
        committing_write_memory => committing_write_memory,
        memory_address_read     => memory_address_read,
        memory_address_write    => memory_address_write,
        memory_word_read        => memory_word_read,
        memory_word_write       => memory_word_write
    );

    process (self_clock)
        variable l : line;
    begin
        if committing_read_memory then
            committing_read_memory <= false;
            write(l, STRING'("Doing good!"));
            writeline(output, l);
        end if;
        if self_clock then
            self_clock <= false;
        else
            self_clock <= true;
        end if;
    end process;
end;