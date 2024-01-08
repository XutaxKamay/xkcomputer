library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CentralProcessingUnit_Package is

    type MEMORY_MODE_TYPE is
    (
        MEMORY_MODE_READ,
        MEMORY_MODE_WRITE
    );

    constant MAX_INTEGER_BITS: integer := 512;
    constant MAX_INTERNAL_MEMORY_IN_BITS: integer := 2**11;
    subtype MEMORY_BIT_VECTOR is std_logic_vector((MAX_INTERNAL_MEMORY_IN_BITS - 1) downto 0);

    subtype ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) downto 0);
    subtype MAX_ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) * 2 downto 0);
    constant ALU_INTEGER_IN_TYPE_SIZE: integer := ALU_INTEGER_IN_TYPE'length;

    type ALU_INTEGER_OUT_TYPE is record
        -- Resulting integer --
        value: ALU_INTEGER_IN_TYPE;
        -- Overflow flag --
        overflow : std_logic;
    end record;

    type ALU_OPERATION_TYPE is
    (
        ALU_OPERATION_TYPE_OR,
        ALU_OPERATION_TYPE_AND,
        ALU_OPERATION_TYPE_ADD,
        ALU_OPERATION_TYPE_SUBTRACT,
        ALU_OPERATION_TYPE_DIVISION,
        ALU_OPERATION_TYPE_MULTIPLY
    );

    ----------------------------------------
    -- I don't think we're going to reach --
    -- ~18k trillion of bits yet          --
    ----------------------------------------
    subtype CPU_ADDRESS_TYPE is unsigned(63 downto 0);
    constant CPU_ADDRESS_TYPE_SIZE: integer := CPU_ADDRESS_TYPE'length;

    subtype CPU_INTEGER_TYPE is ALU_INTEGER_IN_TYPE;
    constant CPU_INTEGER_TYPE_SIZE: integer := CPU_INTEGER_TYPE'length;

    subtype OPCODE_TYPE is std_logic_vector(3 downto 0);
    constant OPCODE_TYPE_SIZE: integer := OPCODE_TYPE'length;

    -- Integer operations --
    constant OPCODE_TYPE_SET: OPCODE_TYPE := "0000";
    constant OPCODE_TYPE_OR: OPCODE_TYPE := "0001";
    constant OPCODE_TYPE_AND: OPCODE_TYPE := "0010";
    constant OPCODE_TYPE_NOT: OPCODE_TYPE := "0011";
    constant OPCODE_TYPE_ADD: OPCODE_TYPE := "0100";
    constant OPCODE_TYPE_SUBSTRACT: OPCODE_TYPE := "0101";
    constant OPCODE_TYPE_DIVISION: OPCODE_TYPE := "0110";
    constant OPCODE_TYPE_MULTIPLY: OPCODE_TYPE := "0111";
    -- Memory instructions --
    constant OPCODE_TYPE_READ: OPCODE_TYPE := "1000";
    constant OPCODE_TYPE_WRITE: OPCODE_TYPE := "1001";
    -- Branch instructions --
    constant OPCODE_TYPE_IS_BIGGER: OPCODE_TYPE := "1010";
    constant OPCODE_TYPE_IS_LOWER: OPCODE_TYPE := "1011";
    constant OPCODE_TYPE_IS_EQUAL: OPCODE_TYPE := "1100";
    constant OPCODE_TYPE_HAD_INTEGER_OVERFLOW: OPCODE_TYPE := "1101";
    -- Will be used for both jumping and branches --
    constant OPCODE_TYPE_JUMP: OPCODE_TYPE := "1110";
    -----------------------------------------------------
    -- TODO:                                           --
    -- Will be used to set a special internal register --
    -- for the number of bits that an integer is       --
    -- actually.                                       --
    -- That would be great                             --
    -- because we wouldn't need to play by             --
    -- shifting bits and so on                         --
    -----------------------------------------------------
    -- constant OPCODE_TYPE_CHANGE_INTERNAL_INTEGER_BIT_SIZE: OPCODE_TYPE := "1111";

    subtype OPERAND_TYPE is std_logic;
    constant OPERAND_TYPE_SIZE: integer := 1;

    constant OPERAND_ADDRESS: OPERAND_TYPE := '0';
    constant OPERAND_INTEGER: OPERAND_TYPE := '1';

    type OPERAND_RIGHT is record
        mode: OPERAND_TYPE;
        value: CPU_INTEGER_TYPE;
    end record;

    constant OPERAND_RIGHT_SIZE: integer := OPERAND_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE;

    type INSTRUCTION is record
        opcode_type: OPCODE_TYPE;
        -- The left operand is always an address --
        operand_left: CPU_INTEGER_TYPE;
        operand_right: OPERAND_RIGHT;
    end record;

    -----------------------------------------------------------------
    -- Instruction size is always the same.                        --
    -- opcode type size + operand left size + operand right size   --
    -----------------------------------------------------------------
    constant INSTRUCTION_SIZE: integer := OPCODE_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE + OPERAND_RIGHT_SIZE;
    constant MEMORY_MAX_WORD_SIZE: integer := INSTRUCTION_SIZE;

    subtype INSTRUCTION_BIT_VECTOR is std_logic_vector((INSTRUCTION_SIZE - 1) downto 0);

    -- General control unit states --
    type UNIT_STATE is
    (
        UNIT_STATE_NOT_RUNNING,
        UNIT_STATE_FETCHING_INSTRUCTION,
        UNIT_STATE_EXECUTING_INSTRUCTION
    );

    -- Function and procedures --

    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE;

    procedure ReadMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        vector: out std_logic_vector;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR
    );

    procedure WriteMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        vector: in std_logic_vector;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR
    );

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION;

    procedure DoALUInstruction
    (
        operation_type: in ALU_OPERATION_TYPE;
        decoded_instruction: in INSTRUCTION;
        address_in: inout CPU_ADDRESS_TYPE;
        signal signal_has_error: inout std_logic;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR;
        signal signal_overflow_flag: inout std_logic
    );

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        signal signal_has_error: inout std_logic;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR;
        signal signal_overflow_flag: inout std_logic
    );

end CentralProcessingUnit_Package;

package body CentralProcessingUnit_Package is
    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE is
    -- Store integer result, make it big enough for multiplication --
    variable temporary_resulting_integer: MAX_ALU_INTEGER_IN_TYPE;
    variable division_by_zero: boolean := false;
    variable integer_out: ALU_INTEGER_OUT_TYPE;
    begin
        case operation_type is
            when ALU_OPERATION_TYPE_ADD =>
                temporary_resulting_integer := resize(integer_in_left + integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);

            when ALU_OPERATION_TYPE_SUBTRACT =>
                temporary_resulting_integer := resize(integer_in_left - integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);

            when ALU_OPERATION_TYPE_DIVISION =>
                if integer_in_right = 0 then
                    division_by_zero := true;
                else
                    temporary_resulting_integer := resize(integer_in_left / integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);
                end if;

            when ALU_OPERATION_TYPE_MULTIPLY =>
                temporary_resulting_integer := resize(integer_in_left * integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);

            when ALU_OPERATION_TYPE_OR =>
                temporary_resulting_integer := resize(integer_in_left or integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);

            when ALU_OPERATION_TYPE_AND =>
                temporary_resulting_integer := resize(integer_in_left and integer_in_right, MAX_ALU_INTEGER_IN_TYPE'length);
        end case;

        -- Resize integer, even if it means to be an overflow --
        integer_out.value := resize(temporary_resulting_integer, ALU_INTEGER_IN_TYPE_SIZE);

        if temporary_resulting_integer > ALU_INTEGER_IN_TYPE'high
            or temporary_resulting_integer < ALU_INTEGER_IN_TYPE'low
            or division_by_zero then
            integer_out.overflow := '1';
        else
            integer_out.overflow := '0';
        end if;

        return integer_out;
    end HandleALUOperations;

    procedure ReadMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        vector: out std_logic_vector;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR
    ) is
    begin
        vector := signal_internal_memory((to_integer(address_in) + vector'length - 1)
            downto to_integer(address_in));
    end procedure;

    procedure WriteMemory
    (
        address_in: inout CPU_ADDRESS_TYPE;
        vector: in std_logic_vector;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR
    ) is
    begin
        signal_internal_memory((to_integer(address_in) + vector'length - 1)
            downto to_integer(address_in)) <= vector;
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
        operation_type: in ALU_OPERATION_TYPE;
        decoded_instruction: in INSTRUCTION;
        address_in: inout CPU_ADDRESS_TYPE;
        signal signal_has_error: inout std_logic;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR;
        signal signal_overflow_flag: inout std_logic
    ) is
        variable temporary_integer_bit_vec: std_logic_vector((CPU_INTEGER_TYPE_SIZE - 1) downto 0);
        variable temporary_integer: CPU_INTEGER_TYPE;
        variable temporary_alu_integer_out: ALU_INTEGER_OUT_TYPE;
    begin
        -- First operand is always an address for the ALU --
        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
        ReadMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);
        temporary_integer := CPU_INTEGER_TYPE(temporary_integer_bit_vec);

        case decoded_instruction.operand_right.mode is
            when OPERAND_ADDRESS =>
                address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_right.value, CPU_ADDRESS_TYPE_SIZE));
                ReadMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);
                temporary_alu_integer_out := HandleALUOperations(operation_type,
                                                                 temporary_integer,
                                                                 CPU_INTEGER_TYPE(temporary_integer_bit_vec));

                signal_has_error <= '0';

            when OPERAND_INTEGER =>
                temporary_alu_integer_out := HandleALUOperations(operation_type,
                                                                 temporary_integer,
                                                                 decoded_instruction.operand_right.value);

                signal_has_error <= '0';

            -- Others states, shouldn't happen, but who knows --
            when others =>
                signal_has_error <= '1';
        end case;

        -- keep track of overflow flag --
        signal_overflow_flag <= temporary_alu_integer_out.overflow;

    end DoALUInstruction; 

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        signal signal_has_error: inout std_logic;
        signal signal_internal_memory: inout MEMORY_BIT_VECTOR;
        signal signal_overflow_flag: inout std_logic
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
                        ReadMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);

                        -- Write the result --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);

                        signal_has_error <= '0';
        
                    when OPERAND_INTEGER =>
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    std_logic_vector(resize(decoded_instruction.operand_right.value,
                                                            CPU_INTEGER_TYPE_SIZE)), signal_internal_memory);

                        signal_has_error <= '0';
        
                    -- Others states, shouldn't happen, but who knows --
                    when others =>
                        signal_has_error <= '1';
                end case;

            when OPCODE_TYPE_OR =>
                DoALUInstruction(ALU_OPERATION_TYPE_OR,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

            when OPCODE_TYPE_AND =>
                DoALUInstruction(ALU_OPERATION_TYPE_AND,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

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
                        ReadMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);

                        -- Apply not operator --
                        temporary_integer_bit_vec := not temporary_integer_bit_vec;

                        -- Write the result --
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in, temporary_integer_bit_vec, signal_internal_memory);

                        signal_has_error <= '0';
        
                    when OPERAND_INTEGER =>
                        address_in := CPU_ADDRESS_TYPE(resize(decoded_instruction.operand_left, CPU_ADDRESS_TYPE_SIZE));
                        WriteMemory(address_in,
                                    std_logic_vector(resize(not decoded_instruction.operand_right.value,
                                                            CPU_INTEGER_TYPE_SIZE)), signal_internal_memory);
                        signal_has_error <= '0';
        
                    -- Others states, shouldn't happen, but who knows --
                    when others =>
                        signal_has_error <= '1';
                end case;

            when OPCODE_TYPE_ADD =>
                DoALUInstruction(ALU_OPERATION_TYPE_ADD,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

            when OPCODE_TYPE_SUBSTRACT =>
                DoALUInstruction(ALU_OPERATION_TYPE_SUBTRACT,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

            when OPCODE_TYPE_DIVISION =>
                DoALUInstruction(ALU_OPERATION_TYPE_DIVISION,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

            when OPCODE_TYPE_MULTIPLY =>
                DoALUInstruction(ALU_OPERATION_TYPE_MULTIPLY,
                                 decoded_instruction,
                                 address_in,
                                 signal_has_error,
                                 signal_internal_memory,
                                 signal_overflow_flag);

            when OPCODE_TYPE_READ =>
                address_in := (others => '0');
                signal_has_error <= '0';
            when OPCODE_TYPE_WRITE =>
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
-- TODO: pipe dream
--            when OPCODE_TYPE_CHANGE_INTERNAL_INTEGER_BIT_SIZE =>
--                address_in := (others => '0');
--                signal_has_error <= '0';                
            when others =>
                signal_has_error <= '1';
        end case;
    end ExecuteInstruction;
end CentralProcessingUnit_Package;