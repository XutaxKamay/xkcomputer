library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity ControlUnit is
    port
    (
        reset: in std_logic;
        has_error: out std_logic
    );
end ControlUnit;

architecture ControlUnit_Implementation of ControlUnit is

    subtype INSTRUCTION_BIT_VECTOR is std_logic_vector((INSTRUCTION_SIZE - 1) downto 0);

    -- General control unit states --
    type UNIT_STATE is
    (
        UNIT_STATE_NOT_RUNNING,
        UNIT_STATE_FETCHING_INSTRUCTION,
        UNIT_STATE_EXECUTING_INSTRUCTION
    );

    type BIT_READ is record
        address_in: CPU_ADDRESS_TYPE;
        value_out: std_logic;
        done_job: std_logic;
    end record;

    type BIT_WRITE is record
        address_in: CPU_ADDRESS_TYPE;
        value_in: std_logic;
        done_job: std_logic;
    end record;

    component MemoryRead is
        port
        (
            address_in: in CPU_ADDRESS_TYPE;
            value_out: out std_logic;
            done_job: out std_logic
        );
    end component;

    component MemoryWrite is
        port
        (
            address_in: in CPU_ADDRESS_TYPE;
            value_in: in std_logic;
            done_job: out std_logic
        );
    end component;

    procedure ReadMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        signal signal_bit_read: inout BIT_READ;
        vector: out std_logic_vector
    ) is
    begin
        for i in 0 to vector'length loop
            signal_bit_read.done_job <= '0';
            signal_bit_read.address_in <= address_in;
            address_in := address_in + 1;
            while (signal_bit_read.done_job /= '1') loop
            end loop;
            vector(i) := signal_bit_read.value_out;
        end loop;
    end procedure;

    procedure WriteMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        signal signal_bit_write: inout BIT_WRITE;
        vector: in std_logic_vector
    ) is
    begin
        for i in 0 to vector'length loop
            signal_bit_write.done_job <= '0';
            signal_bit_write.address_in <= address_in;
            signal_bit_write.value_in <= vector(i);
            address_in := address_in + 1;
            while (signal_bit_write.done_job /= '1') loop
            end loop;
        end loop;
    end procedure;

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION is

    variable decoded_instruction: INSTRUCTION;
    variable count_bits: integer := 0;
    begin
        -- Simply decodes into INSTRUCTION --
        decoded_instruction.opcode_type := instruction_in_bits(
            (OPCODE_TYPE_SIZE - 1) + count_bits downto count_bits);
        count_bits := count_bits + OPCODE_TYPE_SIZE;

        decoded_instruction.operand_left := CPU_INTEGER_TYPE(
            instruction_in_bits((CPU_INTEGER_TYPE_SIZE - 1) + count_bits downto count_bits));
        count_bits := count_bits + CPU_INTEGER_TYPE_SIZE;

        decoded_instruction.operand_right.mode := instruction_in_bits(count_bits);
        count_bits := count_bits + OPERAND_TYPE_SIZE;

        decoded_instruction.operand_right.value := CPU_INTEGER_TYPE(instruction_in_bits(
            (CPU_INTEGER_TYPE_SIZE - 1) + count_bits downto count_bits));
        count_bits := count_bits + CPU_INTEGER_TYPE_SIZE;

        return decoded_instruction;
    end DecodeInstruction;

    procedure DoALUInstruction
    (
        alu_operation_type: in ALU_OPERATION_TYPE;
        decoded_instruction: in INSTRUCTION;
        signal signal_bit_read: inout BIT_READ;
        overflow_flag: inout std_logic;
        signal signal_has_error: inout std_logic;
        address_in: inout CPU_ADDRESS_TYPE

    ) is
        variable temporary_integer_bit_vec: std_logic_vector((CPU_INTEGER_TYPE_SIZE - 1) downto 0);
        variable temporary_integer: CPU_INTEGER_TYPE;
        variable temporary_alu_integer_out: ALU_INTEGER_OUT_TYPE;
    begin
        -- First operand is always an address for the ALU --
        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
        ReadMemory(address_in, signal_bit_read, temporary_integer_bit_vec);
        temporary_integer := CPU_INTEGER_TYPE(temporary_integer_bit_vec);

        case decoded_instruction.operand_right.mode is
            when OPERAND_ADDRESS =>
                address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_right.value, CPU_ADDRESS_TYPE_SIZE));
                ReadMemory(address_in, signal_bit_read, temporary_integer_bit_vec);
                temporary_alu_integer_out := HandleALUOperations(alu_operation_type,
                                                                 temporary_integer,
                                                                 CPU_INTEGER_TYPE(temporary_integer_bit_vec));

                signal_has_error <= '0';

            when OPERAND_INTEGER =>
                temporary_alu_integer_out := HandleALUOperations(alu_operation_type,
                                                                 temporary_integer,
                                                                 decoded_instruction.operand_right.value);

                signal_has_error <= '0';

            -- Others states, shouldn't happen, but who knows --
            when others =>
                signal_has_error <= '1';
        end case;

        -- keep track of overflow flag --
        overflow_flag := temporary_alu_integer_out.overflow;

    end DoALUInstruction; 

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        signal signal_bit_read: inout BIT_READ;
        signal signal_bit_write: inout BIT_WRITE;
        program_counter: inout CPU_ADDRESS_TYPE;
        overflow_flag: inout std_logic;
        signal signal_has_error: inout std_logic
    ) is
        variable address_in: CPU_ADDRESS_TYPE;
        variable temporary_integer_bit_vec: std_logic_vector((CPU_INTEGER_TYPE_SIZE - 1) downto 0);
    begin
        case decoded_instruction.opcode_type is
            when OPCODE_TYPE_SET =>
                ------------------------------------------------------------
                -- NOTE:                                                  --
                -- Set is basically, get the address of the left operand, --
                -- and set it to the right operand integer value.         --
                ------------------------------------------------------------
                case decoded_instruction.operand_right.mode is
                    when OPERAND_ADDRESS =>
                        -- First get the address of the right operand and read the address --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_right.value, CPU_ADDRESS_TYPE_SIZE));
                        ReadMemory(address_in, signal_bit_read, temporary_integer_bit_vec);

                        -- Write the result --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    signal_bit_write,
                                    temporary_integer_bit_vec);

                        signal_has_error <= '0';
        
                    when OPERAND_INTEGER =>
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    signal_bit_write,
                                    std_logic_vector(resize(decoded_instruction.operand_right.value,
                                                            CPU_INTEGER_TYPE_SIZE)));

                        signal_has_error <= '0';
        
                    -- Others states, shouldn't happen, but who knows --
                    when others =>
                        signal_has_error <= '1';
                end case;

            when OPCODE_TYPE_OR =>
                DoALUInstruction(ALU_OPERATION_TYPE_OR,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_AND =>
                DoALUInstruction(ALU_OPERATION_TYPE_AND,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_NOT =>
                -------------------------------------------------
                -- NOTE:                                       --
                -- Special type of operator,                   --
                -- Similar to set as above,                    --
                -- set the not value                           --
                -- by directly by writing to memory            --
                -------------------------------------------------
                case decoded_instruction.operand_right.mode is
                    when OPERAND_ADDRESS =>
                        -- First get the address of the right operand and read the address --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_right.value, CPU_ADDRESS_TYPE_SIZE));
                        ReadMemory(address_in, signal_bit_read, temporary_integer_bit_vec);

                        -- Apply not operator --
                        temporary_integer_bit_vec := not temporary_integer_bit_vec;

                        -- Write the result --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    signal_bit_write,
                                    temporary_integer_bit_vec);

                        signal_has_error <= '0';
        
                    when OPERAND_INTEGER =>
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    signal_bit_write,
                                    std_logic_vector(resize(not decoded_instruction.operand_right.value,
                                                            CPU_INTEGER_TYPE_SIZE)));
                        signal_has_error <= '0';
        
                    -- Others states, shouldn't happen, but who knows --
                    when others =>
                        signal_has_error <= '1';
                end case;

            when OPCODE_TYPE_ADD =>
                DoALUInstruction(ALU_OPERATION_TYPE_ADD,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_SUBSTRACT =>
                DoALUInstruction(ALU_OPERATION_TYPE_SUBTRACT,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_DIVISION =>
                DoALUInstruction(ALU_OPERATION_TYPE_DIVISION,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_MULTIPLY =>
                DoALUInstruction(ALU_OPERATION_TYPE_MULTIPLY,
                                 decoded_instruction,
                                 signal_bit_read,
                                 overflow_flag,
                                 signal_has_error,
                                 address_in);

            when OPCODE_TYPE_READ_INTEGER =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_WRITE_INTEGER =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_IS_BIGGER =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_IS_LOWER => 
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_IS_EQUAL =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_HAD_INTEGER_OVERFLOW =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_JUMP =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when others =>
                signal_has_error <= '1';
        end case;
    end ExecuteInstruction;

    signal signal_bit_read: BIT_READ;
    signal signal_bit_write: BIT_WRITE;
    signal signal_unit_state: UNIT_STATE := UNIT_STATE_NOT_RUNNING;
    signal signal_reset_request: std_logic;
    signal signal_wake_up: std_logic := '0';
begin
    MemoryReadInstance: MemoryRead port map
    (
        address_in => signal_bit_read.address_in,
        value_out => signal_bit_read.value_out,
        done_job => signal_bit_read.done_job
    );

    MemoryWriteInstance: MemoryWrite port map
    (
        address_in => signal_bit_write.address_in,
        value_in => signal_bit_write.value_in,
        done_job => signal_bit_write.done_job
    );

    -- Handle control unit reset --
    process (reset)
        variable woke_up: std_logic := '0';
    begin
        if rising_edge(reset) then
            signal_reset_request <= '1';
            if woke_up /= '1' then
                woke_up := '1';
                signal_wake_up <= '1';
            end if;
        end if;
    end process;

    -- Handle control unit states --
    process (signal_wake_up, signal_unit_state)
        variable var_decoded_instruction: INSTRUCTION;
        variable var_instruction_fetched: INSTRUCTION_BIT_VECTOR;
        variable var_overflow_flag: std_logic := '0'; 
        variable var_program_counter: CPU_ADDRESS_TYPE := (others => '0');
    begin
        -- Reset has been raised --
        if signal_reset_request /= '0' then
            -- CPU Reset --
            var_program_counter := (others => '0');
            -- Will trigger again a new process execution --
            signal_reset_request <= '0';
            signal_unit_state <= UNIT_STATE_NOT_RUNNING;
        end if;

        case signal_unit_state is
            -- Always start by fetching --
            when UNIT_STATE_NOT_RUNNING =>
                signal_unit_state <= UNIT_STATE_FETCHING_INSTRUCTION;

            -- Fetch the instruction first --
            when UNIT_STATE_FETCHING_INSTRUCTION =>
                -- Fetch instruction from memory --
                ReadMemory(var_program_counter, signal_bit_read, var_instruction_fetched);

                -- Decode instruction --
                var_decoded_instruction := DecodeInstruction(var_instruction_fetched);

                -- And then signal to execute instruction --
                signal_unit_state <= UNIT_STATE_EXECUTING_INSTRUCTION;

            -- Then we execute the instruction --
            when UNIT_STATE_EXECUTING_INSTRUCTION =>
                -- Execute instruction --
                ExecuteInstruction(var_decoded_instruction,
                                signal_bit_read,
                                signal_bit_write,
                                var_program_counter,
                                var_overflow_flag,
                                has_error);

                -- Fetch again next instruction --
                signal_unit_state <= UNIT_STATE_FETCHING_INSTRUCTION;
        end case;
    end process;

end ControlUnit_Implementation;
    