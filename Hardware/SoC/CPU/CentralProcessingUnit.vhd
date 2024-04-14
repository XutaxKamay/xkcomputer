library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;
-- use std.textio.all;

entity CentralProcessingUnit is
    port
    (
        controller_has_read_memory: in boolean;
        controller_has_written_memory: in boolean;
        memory_word_read: in WORD_TYPE;
        committing_read_memory: out boolean;
        committing_write_memory: out boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        memory_address_write: out CPU_ADDRESS_TYPE;
        memory_word_write: out WORD_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is
    signal internal_clock: boolean;
begin
    ----------------------------------------------------------------------------
    -- Handle control unit states
    -- Feedback loop based on signal_unit_state FSM
    process (internal_clock)
        variable var_registers: REGISTERS_RECORD := 
            (general => (others => (others => '0')),
             special => (overflow_flag => false, 
                         condition_flag => false,
                         program_counter => (others => '0')));
        variable var_instruction_phase: INSTRUCTION_PHASE := INSTRUCTION_PHASE_FETCHING;
        variable var_unit_state: UNIT_STATE := UNIT_STATE_INSTRUCTION_PHASE;
        variable var_instruction_to_commit: COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE :=
            (address => (others => '0'),
             bit_buffer => (others => '0'),
             bit_index => 0,
             bit_shift => 0);
        variable var_integer_to_commit: INTEGER_TO_COMMIT_TYPE :=
            (mode => MEMORY_MODE_READ,
             address => (others => '0'),
             read_type => (register_index => (others => '0')),
             write_type => (integer_value => (others => '0'), is_inside_read_phase => false),
             bit_buffer => (others => '0'),
             bit_index => 0,
             bit_shift => 0);
        variable var_memory_mode_to_commit: MEMORY_MODE_TYPE := MEMORY_MODE_READ;

        -- Internal state --
        variable internal_committing_read_memory: boolean := false;
        variable internal_committing_write_memory: boolean := false;
        variable internal_memory_address_read: CPU_ADDRESS_TYPE := (others => '0');
        variable internal_memory_address_write: CPU_ADDRESS_TYPE := (others => '0');
        variable internal_memory_word_write: WORD_TYPE := (others => '0');
        -- variable debug_line: line;
    begin
        -- Check if we have sent something to memory controller --
        if controller_has_read_memory
            or controller_has_written_memory
            or internal_committing_read_memory
            or internal_committing_write_memory then
            -----------------------------------------------------------------------
            -- Tell to the controller that we've finished to read/write memory.
            -- We need to wait for the controller for us to set
            -- both controller_has_written_memory and controller_has_read_memory
            -- to false
            if controller_has_read_memory and internal_committing_read_memory then
                internal_committing_read_memory := false;
            end if;

            if controller_has_written_memory and internal_committing_write_memory then
                internal_committing_write_memory := false;
            end if;
        end if;

        ------------------------------------------------------------------------
        -- During instruction phase, there's no I/O for memory.
        -- Instead, it will be preparing data for I/O memory.
        -- During commiting phase, special logic will be applied for both
        -- possible states, first for fetching the instruction,
        -- second for the decode and execute phase.
        -- The second phase is for commiting if an integer needs to be read
        -- or written to a specific address.
        case var_unit_state is
            when UNIT_STATE_INSTRUCTION_PHASE =>
                case var_instruction_phase is
                    -- Stage 1 --
                    when INSTRUCTION_PHASE_FETCHING =>
                        AskFetchInstruction(internal_committing_read_memory,
                                            internal_memory_address_read,
                                            var_registers,
                                            var_instruction_to_commit,
                                            var_unit_state,
                                            var_instruction_phase);
                                            -- write(debug_line, STRING'("UNIT_STATE_INSTRUCTION_PHASE => INSTRUCTION_PHASE_FETCHING"));
                                            -- writeline(output, debug_line);

                    -- Stage 3 --
                    when INSTRUCTION_PHASE_DECODE_AND_EXECUTE =>
                        DecodeAndExecuteInstruction(internal_committing_read_memory,
                                                    internal_memory_address_read,
                                                    var_instruction_to_commit,
                                                    var_registers,
                                                    var_integer_to_commit,
                                                    var_unit_state,
                                                    var_instruction_phase);
                                                    -- write(debug_line, STRING'("UNIT_STATE_INSTRUCTION_PHASE => INSTRUCTION_PHASE_DECODE_AND_EXECUTE"));
                                                    -- writeline(output, debug_line);
                end case;

            when UNIT_STATE_COMMITTING_MEMORY =>
                case var_instruction_phase is
                    -- Stage 2 --
                    when INSTRUCTION_PHASE_FETCHING =>
                        HandleFetchInstruction(controller_has_read_memory,
                                               internal_committing_read_memory,
                                               internal_memory_address_read,
                                               memory_word_read,
                                               var_instruction_to_commit,
                                               var_unit_state,
                                               var_instruction_phase);
                                            --    write(debug_line, STRING'("UNIT_STATE_COMMITTING_MEMORY => INSTRUCTION_PHASE_FETCHING"));
                                            --    writeline(output, debug_line);
                    -- Stage 4 --
                    when INSTRUCTION_PHASE_DECODE_AND_EXECUTE =>
                        HandlePostExecution(controller_has_read_memory,
                                            controller_has_written_memory,
                                            internal_committing_read_memory,
                                            internal_committing_write_memory,
                                            internal_memory_address_read,
                                            internal_memory_address_write,
                                            memory_word_read,
                                            internal_memory_word_write,
                                            var_integer_to_commit,
                                            var_registers,
                                            var_unit_state,
                                            var_instruction_phase);
                                            -- write(debug_line, STRING'("UNIT_STATE_COMMITTING_MEMORY => INSTRUCTION_PHASE_DECODE_AND_EXECUTE => "));
                                            -- if var_memory_mode_to_commit = MEMORY_MODE_READ then
                                            --     write(debug_line, STRING'("MEMORY_MODE_READ"));
                                            -- else
                                            --     write(debug_line, STRING'("MEMORY_MODE_WRITE"));
                                            -- end if;
                                            -- writeline(output, debug_line);
                end case;
        end case;

        -- Assign ports --
        committing_read_memory <= internal_committing_read_memory;
        committing_write_memory <= internal_committing_write_memory;
        memory_address_read <= internal_memory_address_read;
        memory_address_write <= internal_memory_address_write;
        memory_word_write <= internal_memory_word_write;

        if internal_clock then
            internal_clock <= false;
        else
            internal_clock <= true;
        end if;
    end process;

end CentralProcessingUnit_Implementation;
