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
            controller_has_read_memory : in BOOLEAN;
            controller_has_written_memory : in BOOLEAN;
            memory_word_read : in WORD_TYPE;
            committing_read_memory : out BOOLEAN;
            committing_write_memory : out BOOLEAN;
            memory_address_read : out CPU_ADDRESS_TYPE;
            memory_address_write : out CPU_ADDRESS_TYPE;
            memory_word_write : out WORD_TYPE
        );
    end component;

    -- Ports
    signal controller_has_read_memory : BOOLEAN := false;
    signal controller_has_written_memory : BOOLEAN := false;
    signal committing_read_memory : BOOLEAN;
    signal committing_write_memory : BOOLEAN;
    signal memory_address_read : CPU_ADDRESS_TYPE;
    signal memory_address_write : CPU_ADDRESS_TYPE;
    signal memory_word_read : WORD_TYPE;
    signal memory_word_write : WORD_TYPE;

begin
    CentralProcessingUnit_inst : CentralProcessingUnit
    port map (
        controller_has_read_memory => controller_has_read_memory,
        controller_has_written_memory => controller_has_written_memory,
        committing_read_memory => committing_read_memory,
        committing_write_memory => committing_write_memory,
        memory_address_read => memory_address_read,
        memory_address_write => memory_address_write,
        memory_word_read => memory_word_read,
        memory_word_write => memory_word_write
    );

    process (committing_read_memory)
        variable l: line;
    begin
        write(l, STRING'("committing_read_memory: "));
        write(l, committing_read_memory);
        writeline(output, l);
        if committing_read_memory then
            controller_has_read_memory <= true;
        else
            controller_has_read_memory <= false;
        end if;
    end process;

    process (committing_write_memory)
        variable l: line;
    begin
        write(l, STRING'("committing_write_memory: "));
        write(l, committing_write_memory);
        writeline(output, l);
        if committing_write_memory then
            controller_has_written_memory <= true;
        else
            controller_has_written_memory <= false;
        end if;
    end process;
end;