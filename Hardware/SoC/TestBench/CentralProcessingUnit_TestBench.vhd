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
            controller_has_read_memory    : in BOOLEAN;
            controller_has_written_memory : in BOOLEAN;
            committing_read_memory        : out BOOLEAN;
            committing_write_memory       : out BOOLEAN;
            memory_address_read           : out CPU_ADDRESS_TYPE;
            memory_address_write          : out CPU_ADDRESS_TYPE;
            memory_word_read              : in WORD_TYPE;
            memory_word_write             : out WORD_TYPE
        );
    end component;

    -- Ports
    signal controller_has_read_memory    : BOOLEAN := false;
    signal controller_has_written_memory : BOOLEAN := false;
    signal committing_read_memory        : BOOLEAN;
    signal committing_write_memory       : BOOLEAN;
    signal memory_address_read           : CPU_ADDRESS_TYPE;
    signal memory_address_write          : CPU_ADDRESS_TYPE;
    signal memory_word_read              : WORD_TYPE;
    signal memory_word_write             : WORD_TYPE;
    signal self_clock                    : BOOLEAN;

begin

    CentralProcessingUnit_inst : CentralProcessingUnit
    port map(
        controller_has_read_memory    => controller_has_read_memory,
        controller_has_written_memory => controller_has_written_memory,
        committing_read_memory        => committing_read_memory,
        committing_write_memory       => committing_write_memory,
        memory_address_read           => memory_address_read,
        memory_address_write          => memory_address_write,
        memory_word_read              => memory_word_read,
        memory_word_write             => memory_word_write
    );

    process (self_clock)
        variable debug_line : line;
        variable has_committed_read_memory: boolean := false;
        variable has_committed_write_memory: boolean := false;
    begin
        if not has_committed_read_memory then
            if committing_read_memory then
                write(debug_line, STRING'("Memory Controller: committing "));
                write(debug_line, to_integer(memory_address_read));
                writeline(output, debug_line);
                has_committed_read_memory := true;
                controller_has_read_memory <= true;
            end if;
        else
            if not committing_read_memory then
                has_committed_read_memory := false;
                controller_has_read_memory <= false;
            end if;
        end if;
        if self_clock then
            self_clock <= false;
        else
            self_clock <= true;
        end if;
    end process;
end;