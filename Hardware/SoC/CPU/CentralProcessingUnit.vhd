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
        memory_address: inout CPU_ADDRESS_TYPE;
        memory_size: inout CPU_ADDRESS_TYPE;
        memory_data: inout MEMORY_BIT_VECTOR;
        memory_mode: inout MEMORY_MODE_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is
    signal signal_reset_request: boolean;
    signal signal_unit_state: UNIT_STATE := UNIT_STATE_NOT_RUNNING;
    signal signal_registers: REGISTERS_RECORD;
    signal signal_has_asked_instruction: boolean := false;
    signal signal_memory_to_commmit: COMMIT_MEMORY_RECORD;
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
    -- commit_read_memory should trigger a new execution also when it is zero,
    -- in oreder to fetch a new instruction
    -- both commit_read_memory/commit_write_memory
    -- will be used too for commit_memory unit state.
    process (signal_reset_request, signal_unit_state, commit_read_memory, commit_write_memory)
    begin
        -- Reset has been raised --
        if signal_reset_request then
            -- Reset CPU --
            signal_registers.special.program_counter <= (others => '0');
            -- Will trigger again a new process execution --
            signal_unit_state <= UNIT_STATE_BEGIN;
        end if;

        case signal_unit_state is
            -- Should never happen --
            when UNIT_STATE_NOT_RUNNING =>
                signal_unit_state <= UNIT_STATE_BEGIN;
            when UNIT_STATE_BEGIN =>
                signal_unit_state <= UNIT_STATE_FETCH_AND_DECODE_AND_EXECUTE;
            when UNIT_STATE_FETCH_AND_DECODE_AND_EXECUTE =>
                FetchAndDecodeAndExecuteInstruction(commit_read_memory,
                                                    commit_write_memory,
                                                    memory_address,
                                                    memory_size,
                                                    memory_data,
                                                    memory_mode,
                                                    signal_registers,
                                                    signal_has_asked_instruction,
                                                    signal_unit_state,
                                                    signal_memory_to_commmit);
            when UNIT_STATE_COMMITING_MEMORY =>
                CheckCommitMemory(signal_memory_to_commmit,
                                  signal_registers.general,
                                  commit_read_memory,
                                  commit_write_memory,
                                  memory_data,
                                  signal_unit_state);
        end case;
    end process;

end CentralProcessingUnit_Implementation;
    
