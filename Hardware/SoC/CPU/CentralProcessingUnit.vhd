library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity CentralProcessingUnit is
    port
    (
        reset: in BIT;
        commit_read_memory: inout BIT;
        commit_write_memory: inout BIT;
        memory_address: inout CPU_ADDRESS_TYPE;
        memory_size: inout CPU_ADDRESS_TYPE;
        memory_data: inout MEMORY_DATA;
        memory_mode: inout MEMORY_MODE_TYPE
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is
    signal signal_reset_request: std_logic;
    signal signal_unit_state: UNIT_STATE := UNIT_STATE_NOT_RUNNING;
    signal signal_registers: REGISTERS;
    signal signal_has_asked_instruction: boolean := false;
    signal signal_commit_memory: COMMIT_MEMORY_RECORD;
begin
    -- Handle control unit reset --
    process (reset)
    begin
        if reset = '1' then
            signal_reset_request <= '1';
        else
            signal_reset_request <= '0';
        end if;
    end process;

    -- Handle control unit states --
    process (signal_reset_request, signal_unit_state)
    begin
        -- Reset has been raised --
        if signal_reset_request = '1' then
            -- Reset CPU --
            signal_registers.special.program_counter <= (others => '0');
            -- Will trigger again a new process execution --
            signal_unit_state <= UNIT_STATE_BEGIN;
        end if;

        case signal_unit_state is
            when UNIT_STATE_BEGIN =>
                signal_unit_state <= UNIT_STATE_FETCH_AND_DECODE_AND_EXECUTE;
            when UNIT_STATE_FETCH_AND_DECODE_AND_EXECUTE =>
                FetchAndDecodeAndExecuteInstruction(commit_read_memory,
                                                    memory_address,
                                                    memory_size,
                                                    memory_data,
                                                    memory_mode,
                                                    signal_registers.special.program_counter,
                                                    signal_has_asked_instruction,
                                                    signal_unit_state);
            when UNIT_STATE_COMMIT_MEMORY =>
                
        end case;
    end process;

end CentralProcessingUnit_Implementation;
    
