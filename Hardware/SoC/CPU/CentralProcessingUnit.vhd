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
        memory_word_read: in MEMORY_WORD_TYPE;
        memory_word_write: out MEMORY_WORD_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is

    signal signal_reset_request: boolean;
    signal signal_unit_state: UNIT_STATE := UNIT_STATE_INSTRUCTION_PHASE;

begin
    -- Handle control unit reset --
    process (reset)
    begin
        if reset then
            signal_reset_request <= true;
        else
            signal_reset_request <= false;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Handle control unit states
    -- Feedback loop based on signal_unit_state FSM
    process (signal_reset_request, signal_unit_state)
        variable var_registers: REGISTERS_RECORD;
        variable var_memory_to_commmit: COMMIT_MEMORY_RECORD;
        variable var_instruction_phase: INSTRUCTION_PHASE := INSTRUCTION_PHASE_FETCHING;
        variable var_instruction_fetch_word_count: integer range 2 downto 0 := 0;
        variable var_instruction_fetched: INSTRUCTION_BIT_VECTOR;
    begin
        -- Reset has been raised --
        if signal_reset_request then
            -- Reset CPU --
            var_registers := (general => (others => (others => '0')),
                              special => (overflow_flag => false, 
                                          condition_flag => false,
                                          program_counter => (others => '0'),
                                          register_index_read_commit => (others => '0'))); 
            -- Do not wait for memory to set them to false --
            commit_read_memory <= false;
            commit_write_memory <= false;
            -- Will trigger again a new process execution --
            signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
        end if;

        case signal_unit_state is
            when UNIT_STATE_INSTRUCTION_PHASE =>
                case var_instruction_phase is
                    when INSTRUCTION_PHASE_FETCHING =>
                        HandleFetchInstruction(commit_read_memory,
                                               memory_address_read,
                                               memory_word_read,
                                               var_registers,
                                               signal_unit_state,
                                               var_instruction_phase,
                                               var_memory_to_commmit,
                                               var_instruction_fetch_word_count,
                                               var_instruction_fetched);
                    when INSTRUCTION_PHASE_DECODE_AND_EXECUTE =>
                end case;
            when UNIT_STATE_COMMITING_MEMORY =>

        end case;
    end process;

end CentralProcessingUnit_Implementation;
    
