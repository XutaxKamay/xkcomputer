library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity CentralProcessingUnit is
    port
    (
        reset: in std_logic;
        has_error: out std_logic
    );
end CentralProcessingUnit;

architecture CentralProcessingUnit_Implementation of CentralProcessingUnit is

    -- Internal memory --
    signal signal_internal_memory: MEMORY_BIT_VECTOR;
    signal signal_reset_request: std_logic;
    signal signal_overflow_flag: std_logic := '0';
    signal signal_program_counter: CPU_ADDRESS_TYPE := (others => '0');
    signal signal_unit_state: UNIT_STATE;
    -- signal signal_integer_bit_size: integer range 1 to MAX_INTEGER_BITS := MAX_INTEGER_BITS;

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
        variable var_decoded_instruction: INSTRUCTION;
        variable var_instruction_fetched: INSTRUCTION_BIT_VECTOR;
        variable var_address_in: CPU_ADDRESS_TYPE;
    begin
        -- Reset has been raised --
        if signal_reset_request = '1' then
            -- CPU Reset --
            signal_program_counter <= (others => '0');
            -- Will trigger again a new process execution --
            signal_unit_state <= UNIT_STATE_NOT_RUNNING;
        end if;

        case signal_unit_state is
            -- Always start by fetching --
            when UNIT_STATE_NOT_RUNNING =>
                signal_unit_state <= UNIT_STATE_FETCHING_INSTRUCTION;

            -- Fetch the instruction first --
            when UNIT_STATE_FETCHING_INSTRUCTION =>
                var_address_in := signal_program_counter;

                -- Fetch instruction from memory --
                ReadMemory(var_address_in, var_instruction_fetched, signal_internal_memory);

                signal_program_counter <= var_address_in;

                -- Decode instruction --
                var_decoded_instruction := DecodeInstruction(var_instruction_fetched);

                -- And then signal to execute instruction --
                signal_unit_state <= UNIT_STATE_EXECUTING_INSTRUCTION;

            -- Then we execute the instruction --
            when UNIT_STATE_EXECUTING_INSTRUCTION =>
                -- Execute instruction --
                ExecuteInstruction(var_decoded_instruction,
                                   has_error,
                                   signal_internal_memory,
                                   signal_overflow_flag);

                -- Fetch again next instruction --
                signal_unit_state <= UNIT_STATE_FETCHING_INSTRUCTION;
        end case;
    end process;

end CentralProcessingUnit_Implementation;
    