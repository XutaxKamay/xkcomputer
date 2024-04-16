library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;
-- use std.textio.all;

entity CentralProcessingUnit is
    port
    (
        controller_has_read_memory: in BOOLEAN;
        controller_has_written_memory: in BOOLEAN;
        memory_word_read: in WORD_TYPE;
        committing_read_memory: out BOOLEAN;
        committing_write_memory: out BOOLEAN;
        memory_address_read: out CPU_ADDRESS_TYPE;
        memory_address_write: out CPU_ADDRESS_TYPE;
        memory_word_write: out WORD_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is
    signal internal_committing_read_memory: BOOLEAN := false;
    signal internal_committing_write_memory: BOOLEAN := false;
    signal internal_memory_address_read: CPU_ADDRESS_TYPE := (others => '0');
    signal internal_memory_address_write: CPU_ADDRESS_TYPE := (others => '0');
    signal internal_memory_word_write: WORD_TYPE := (others => '0');
begin
    ----------------------------------------------------------------------------
    -- Handle control unit states
    -- Feedback loop based on signal_unit_state FSM
    process (controller_has_read_memory, controller_has_written_memory)
        variable internal_registers: REGISTERS_RECORD := 
            (general => (others => (others => '0')),
             special => (overflow_flag => false, 
                         condition_flag => false,
                         program_counter => (others => '0')));
        variable internal_unit_state: UNIT_STATE_TYPE := UNIT_STATE_INITIAL;
        variable internal_instruction_to_commit: COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE :=
            (address => (others => '0'),
             bit_buffer => (others => '0'),
             bit_index => 0,
             bit_shift => 0);
        variable internal_integer_to_commit: INTEGER_TO_COMMIT_TYPE :=
            (mode => MEMORY_MODE_READ,
             address => (others => '0'),
             read_type => (register_index => (others => '0')),
             write_type => (integer_value => (others => '0'), is_inside_read_phase => false),
             bit_buffer => (others => '0'),
             bit_index => 0,
             bit_shift => 0);
        -- variable internal_memory_mode_to_commit: MEMORY_MODE_TYPE := MEMORY_MODE_READ;
        -- variable debug_line: line;
    begin
        ------------------------------------------------------------------------
        -- During instruction phase, there's no I/O for memory.
        -- Instead, it will be preparing data for I/O memory.
        -- During commiting phase, special logic will be applied for both
        -- possible states, first for fetching the instruction,
        -- second for the decode and execute phase.
        -- The second phase is for commiting if an integer needs to be read
        -- or written to a specific address.
        case internal_unit_state is
            when UNIT_STATE_INITIAL =>
                AskFetchInstruction(internal_committing_read_memory,
                                    internal_memory_address_read,
                                    internal_registers,
                                    internal_instruction_to_commit,
                                    internal_unit_state);
                                    -- write(debug_line, STRING'("UNIT_STATE_INITIAL"));
                                    -- writeline(output, debug_line);
            when UNIT_STATE_FETCH_AND_EXECUTE_INSTRUCTION =>
                HandleInstruction(controller_has_read_memory,
                                  internal_committing_read_memory,
                                  internal_memory_address_read,
                                  memory_word_read,
                                  internal_instruction_to_commit,
                                  internal_integer_to_commit,
                                  internal_registers,
                                  internal_unit_state);
                                --   write(debug_line, STRING'("UNIT_STATE_FETCH_AND_EXECUTE_INSTRUCTION"));
                                --   writeline(output, debug_line);
            when UNIT_STATE_COMMITTING_MEMORY =>
                HandlePostExecution(controller_has_read_memory,
                                    controller_has_written_memory,
                                    internal_committing_read_memory,
                                    internal_committing_write_memory,
                                    internal_memory_address_read,
                                    internal_memory_address_write,
                                    memory_word_read,
                                    internal_memory_word_write,
                                    internal_instruction_to_commit,
                                    internal_integer_to_commit,
                                    internal_registers,
                                    internal_unit_state);
                                    -- write(debug_line, STRING'("UNIT_STATE_COMMITTING_MEMORY => "));
                                    -- if internal_memory_mode_to_commit = MEMORY_MODE_READ then
                                    --     write(debug_line, STRING'("MEMORY_MODE_READ"));
                                    -- else
                                    --     write(debug_line, STRING'("MEMORY_MODE_WRITE"));
                                    -- end if;
                                    -- writeline(output, debug_line);
        end case;
    end process;

    -- Assign ports --
    committing_read_memory <= internal_committing_read_memory;
    committing_write_memory <= internal_committing_write_memory;
    memory_address_read <= internal_memory_address_read;
    memory_address_write <= internal_memory_address_write;
    memory_word_write <= internal_memory_word_write;

end CentralProcessingUnit_Implementation;
