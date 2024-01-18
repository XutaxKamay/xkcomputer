library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity CentralProcessingUnit is
    port
    (
        reset: in boolean;
        commit_read_memory: inout boolean;
        commit_write_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        memory_address_write: out CPU_ADDRESS_TYPE;
        memory_word_read: in WORD_TYPE;
        memory_word_write: out WORD_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is

    signal signal_reset_request: boolean;
    signal signal_has_woke_up_once: boolean := false;
    signal signal_unit_state: UNIT_STATE := UNIT_STATE_INSTRUCTION_PHASE;

begin
    -- Handle control unit reset --
    process (reset)
    begin
        if reset then
            signal_reset_request <= true;
            if not signal_has_woke_up_once then
                signal_has_woke_up_once <= true;
            end if;
        else
            signal_reset_request <= false;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Handle control unit states
    -- Feedback loop based on signal_unit_state FSM
    process (signal_has_woke_up_once, signal_unit_state)
        variable var_registers: REGISTERS_RECORD;
        variable var_instruction_phase: INSTRUCTION_PHASE := INSTRUCTION_PHASE_FETCHING;
        variable var_instruction_to_commit: COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        variable var_integer_to_commit: INTEGER_TO_COMMIT_TYPE;
        variable var_memory_mode_to_commit: MEMORY_MODE_TYPE;
    begin
        -- Reset has been raised --
        if signal_reset_request then
            -- Reset CPU --
            var_registers := (general => (others => (others => '0')),
                              special => (overflow_flag => false, 
                                          condition_flag => false,
                                          program_counter => (others => '0'))); 
            -- Do not wait for memory controller to set them to false --
            commit_read_memory <= false;
            commit_write_memory <= false;
            var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
            -- Will trigger again a new process execution --
            signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
        end if;

        ---------------------------------------------------------------------
        -- During instruction phase, there's no I/O for memory.
        -- Instead, it will be preparing data for I/O memory.
        -- During commiting phase, special logic will be applied for both
        -- possible states, first for fetching the instruction,
        -- second for the decode and execute phase.
        -- The second phase is for commiting if an integer needs to be read
        -- or written to a specific address.
        case signal_unit_state is
            when UNIT_STATE_INSTRUCTION_PHASE =>
                case var_instruction_phase is
                    when INSTRUCTION_PHASE_FETCHING =>
                        AskFetchInstruction(commit_read_memory,
                                            memory_address_read,
                                            var_registers,
                                            var_instruction_to_commit,
                                            signal_unit_state);

                    when INSTRUCTION_PHASE_DECODE_AND_EXECUTE =>
                        DecodeAndExecuteInstruction(commit_read_memory,
                                                    memory_address_read,
                                                    var_instruction_to_commit,
                                                    var_registers,
                                                    var_integer_to_commit,
                                                    signal_unit_state,
                                                    var_instruction_phase);
                end case;

            when UNIT_STATE_COMMITING_MEMORY =>
                case var_instruction_phase is
                    when INSTRUCTION_PHASE_FETCHING =>
                        HandleFetchInstruction(commit_read_memory,
                                               memory_address_read,
                                               memory_word_read,
                                               var_instruction_to_commit,
                                               signal_unit_state,
                                               var_instruction_phase);

                    when INSTRUCTION_PHASE_DECODE_AND_EXECUTE =>
                        HandlePostExecution(commit_read_memory,
                                            commit_write_memory,
                                            memory_address_read,
                                            memory_address_write,
                                            memory_word_read,
                                            memory_word_write,
                                            var_integer_to_commit,
                                            var_registers,
                                            signal_unit_state,
                                            var_instruction_phase);
                end case;
        end case;
    end process;

end CentralProcessingUnit_Implementation;
    
