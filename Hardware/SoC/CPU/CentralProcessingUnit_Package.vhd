library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TinyEncryptionAlgorithm_Package.all;
use work.Maths_Package.all;

package CentralProcessingUnit_Package is

    -----------------------------------------------------------------------------------
    -- ° Stage 1: UNIT_STATE_INSTRUCTION_PHASE & INSTRUCTION_PHASE_FETCHING
    -- ° Stage 2: UNIT_STATE_COMMITTING_MEMORY & INSTRUCTION_PHASE_FETCHING
    -- ° Stage 3: UNIT_STATE_INSTRUCTION_PHASE & INSTRUCTION_PHASE_DECODE_AND_EXECUTE
    -- ° Stage 4: UNIT_STATE_COMMITTING_MEMORY & INSTRUCTION_PHASE_DECODE_AND_EXECUTE
    -- Step 4 isn't always needed, sometimes we operate directly on registers.
    -- ° Repeat stage 1.

    type UNIT_STATE is
    (
        UNIT_STATE_INSTRUCTION_PHASE,
        UNIT_STATE_COMMITTING_MEMORY
    );

    type INSTRUCTION_PHASE is
    (
        INSTRUCTION_PHASE_FETCHING,
        INSTRUCTION_PHASE_DECODE_AND_EXECUTE
    );

    type MEMORY_MODE_TYPE is
    ( 
        MEMORY_MODE_READ,
        MEMORY_MODE_WRITE
    );

    -- Needs to be power of two for ROR/ROL instruction --
    constant INTEGER_SIZE: integer := 64;

    type ALU_OPERATION_INTEGER_TYPE is
    (
        ALU_OPERATION_INTEGER_DEFAULT,
        ALU_OPERATION_INTEGER_ADD,
        ALU_OPERATION_INTEGER_MULTIPLY
    );

    subtype ALU_INTEGER_IN_TYPE is signed(INTEGER_SIZE - 1 downto 0);
    subtype MAX_ADD_ALU_INTEGER_IN_TYPE is signed(INTEGER_SIZE downto 0);
    subtype MAX_MULTIPLY_ALU_INTEGER_IN_TYPE is signed(INTEGER_SIZE * 2 - 1 downto 0);
    constant ALU_INTEGER_IN_TYPE_SIZE: integer := ALU_INTEGER_IN_TYPE'length;

    type ALU_INTEGER_OUT_TYPE is record
        -- Resulting integer --
        value: ALU_INTEGER_IN_TYPE;
        -- Overflow flag --
        overflow: boolean;
        condition: boolean;
    end record;

    type ALU_OPERATION_TYPE is
    (
        ALU_OPERATION_TYPE_OR,
        ALU_OPERATION_TYPE_AND,
        ALU_OPERATION_TYPE_ADD,
        ALU_OPERATION_TYPE_SUBTRACT,
        ALU_OPERATION_TYPE_DIVISION,
        ALU_OPERATION_TYPE_MULTIPLY,
        ALU_OPERATION_TYPE_SLA,
        ALU_OPERATION_TYPE_SRA,
        ALU_OPERATION_TYPE_SLL,
        ALU_OPERATION_TYPE_SRL,
        ALU_OPERATION_TYPE_ROL,
        ALU_OPERATION_TYPE_ROR,
        -- Operation with only one integer --
        ALU_OPERATION_TYPE_SET,
        ALU_OPERATION_TYPE_NOT,
        ALU_OPERATION_TYPE_BIGGER,
        ALU_OPERATION_TYPE_LOWER,
        ALU_OPERATION_TYPE_EQUAL
    );

    subtype CPU_ADDRESS_TYPE is ALU_INTEGER_IN_TYPE;
    constant CPU_ADDRESS_TYPE_SIZE: integer := CPU_ADDRESS_TYPE'length;

    subtype CPU_INTEGER_TYPE is ALU_INTEGER_IN_TYPE;
    constant CPU_INTEGER_TYPE_SIZE: integer := CPU_INTEGER_TYPE'length;

    subtype OPCODE_TYPE is BIT_VECTOR(4 downto 0);
    constant OPCODE_TYPE_SIZE: integer := OPCODE_TYPE'length;

    -- Integer operations --
    constant OPCODE_TYPE_SET: OPCODE_TYPE := "00000";
    constant OPCODE_TYPE_OR: OPCODE_TYPE := "00001";
    constant OPCODE_TYPE_AND: OPCODE_TYPE := "00010";
    constant OPCODE_TYPE_NOT: OPCODE_TYPE := "00011";
    constant OPCODE_TYPE_ADD: OPCODE_TYPE := "00100";
    constant OPCODE_TYPE_SUBSTRACT: OPCODE_TYPE := "00101";
    constant OPCODE_TYPE_DIVISION: OPCODE_TYPE := "00110";
    constant OPCODE_TYPE_MULTIPLY: OPCODE_TYPE := "00111";
    constant OPCODE_TYPE_SLA: OPCODE_TYPE := "01000";
    constant OPCODE_TYPE_SRA: OPCODE_TYPE := "01001";
    constant OPCODE_TYPE_SLL: OPCODE_TYPE := "01010";
    constant OPCODE_TYPE_SRL: OPCODE_TYPE := "01011";
    constant OPCODE_TYPE_ROL: OPCODE_TYPE := "01100";
    constant OPCODE_TYPE_ROR: OPCODE_TYPE := "01101";
    -- Memory instructions --
    constant OPCODE_TYPE_READ: OPCODE_TYPE := "01110";
    constant OPCODE_TYPE_WRITE: OPCODE_TYPE := "01111";
    -- Branch instructions --
    constant OPCODE_TYPE_IS_BIGGER: OPCODE_TYPE := "10000";
    constant OPCODE_TYPE_IS_LOWER: OPCODE_TYPE := "10001";
    constant OPCODE_TYPE_IS_EQUAL: OPCODE_TYPE := "10010";
    constant OPCODE_TYPE_HAD_INTEGER_OVERFLOW: OPCODE_TYPE := "10011";
    -- Jumping and branches --
    constant OPCODE_TYPE_JUMP: OPCODE_TYPE := "10100";
    constant OPCODE_TYPE_BRANCH: OPCODE_TYPE := "10101";

    subtype OPERAND_TYPE is BIT;
    constant OPERAND_TYPE_SIZE: integer := 1;

    constant OPERAND_REGISTER: OPERAND_TYPE := '0';
    -- Can be either an address or a value depending on the opcode --
    constant OPERAND_INTEGER: OPERAND_TYPE := '1';

    -- 16 registers is way more than enough --
    subtype REGISTER_INDEX_TYPE is unsigned(3 downto 0);
    constant REGISTER_INDEX_TYPE_SIZE: integer := REGISTER_INDEX_TYPE'length;
    type REGISTER_ARRAY is array(REGISTER_INDEX_TYPE'high - 1 downto 0) of CPU_INTEGER_TYPE;
    subtype REGISTER_INTEGER_TYPE is integer range REGISTER_INDEX_TYPE'high - 1 downto 0;

    type SPECIAL_REGISTERS is record
        overflow_flag: boolean;
        condition_flag: boolean;
        program_counter: CPU_ADDRESS_TYPE;
    end record;

    type REGISTERS_RECORD is record
        general: REGISTER_ARRAY;
        special: SPECIAL_REGISTERS;
    end record;

    ---------------------------------
    -- Operands and mnemonics:     --
    -- opcode destination, source  --
    -- except for write/read       --
    -- opcode.                     --
    --                             --
    -- set register0, integer      --
    -- add register0, register1    --
    -- write register0, address    --
    -- write register0, register1  --
    -- read register3, address     --
    -- cmp register3, register1    --
    -- branch register3, register3 --
    ---------------------------------

    ---------------------------------------------
    -- Results in a bigger instruction set,    --
    -- but predictable and easier to implement --
    ---------------------------------------------
    type OPERAND_LEFT is record
        register_index: REGISTER_INDEX_TYPE;
    end record;

    type OPERAND_RIGHT is record
        mode: OPERAND_TYPE;
        register_index: REGISTER_INDEX_TYPE;
        integer_value: CPU_INTEGER_TYPE;
    end record;

    type INSTRUCTION is record
        opcode: OPCODE_TYPE;
        operand_left: OPERAND_LEFT;
        operand_right: OPERAND_RIGHT;
    end record;

    constant INSTRUCTION_SIZE: integer := OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE
        + OPERAND_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE;
    subtype INSTRUCTION_BIT_VECTOR is BIT_VECTOR(INSTRUCTION_SIZE - 1 downto 0);

    constant ENCRYPTED_CHUNK_SIZE: integer := TEA_INTEGERS_TYPE'length * TEA_INTEGER_TYPE'length;

    constant WORD_SIZE: integer := ENCRYPTED_CHUNK_SIZE;
    constant ALIGN_SIZE: integer := IntegerMax(ENCRYPTED_CHUNK_SIZE, WORD_SIZE);
    subtype WORD_TYPE is BIT_VECTOR(WORD_SIZE - 1 downto 0);
    subtype WORD_INTEGER_TYPE is integer range WORD_SIZE - 1 downto 0;

    -- Add a ALIGN_SIZE because we need to get the bits left too inside memory, even if we don't need those --
    constant AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INSTRUCTION: integer := INSTRUCTION_SIZE
        + (ALIGN_SIZE - (INSTRUCTION_SIZE mod ALIGN_SIZE)) + ALIGN_SIZE;
    subtype INSTRUCTION_BIT_BUFFER is
        BIT_VECTOR(AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INSTRUCTION - 1 downto 0);

    -- Add a ALIGN_SIZE because we need to get the bits left too inside memory, even if we don't need those --
    constant AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INTEGER: integer := CPU_INTEGER_TYPE_SIZE
        + (ALIGN_SIZE - (CPU_INTEGER_TYPE_SIZE mod ALIGN_SIZE)) + ALIGN_SIZE;
    subtype INTEGER_BIT_BUFFER is BIT_VECTOR(AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INTEGER - 1 downto 0);

    -- Need specialized type for such fetchs --
    type COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE is record
        address: CPU_ADDRESS_TYPE;
        bit_buffer: INSTRUCTION_BIT_BUFFER;
        bit_index: integer range INSTRUCTION_BIT_BUFFER'length downto 0;
        bit_shift: WORD_INTEGER_TYPE;
    end record;

    type COMMIT_READ_WORD_TYPE is record
        register_index: REGISTER_INDEX_TYPE;
    end record;

    type COMMIT_WRITE_WORD_TYPE is record
        integer_value: CPU_INTEGER_TYPE;
        is_inside_read_phase: boolean;
    end record;

    type INTEGER_TO_COMMIT_TYPE is record
        mode: MEMORY_MODE_TYPE;
        address: CPU_ADDRESS_TYPE;
        read_type: COMMIT_READ_WORD_TYPE;
        write_type: COMMIT_WRITE_WORD_TYPE;
        bit_buffer: INTEGER_BIT_BUFFER;
        bit_index: integer range INTEGER_BIT_BUFFER'length downto 0;
        bit_shift: WORD_INTEGER_TYPE;
    end record;

    -- b392387fe1c4e11afb34f1ca52261c26 --
    constant TEA_KEY: TEA_KEY_TYPE := (x"b392387f", x"e1c4e11a", x"fb34f1ca", x"52261c26");

    -- If word size is bigger than encrypted chunk size --
    procedure Encrypt
    (
        bit_buffer: inout BIT_VECTOR
    );

    procedure Decrypt
    (
        bit_buffer: inout BIT_VECTOR
    );

    -- Function and procedures --
    procedure Stage1
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    );

    procedure Stage2
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    );

    procedure Stage3
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    );

    procedure Stage4
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    );

    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE;

    procedure HandleMemoryALUOperations
    (
        mode: in MEMORY_MODE_TYPE;
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE
    );

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION;

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE
    );

    procedure AskFetchInstruction
    (
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        registers: in REGISTERS_RECORD;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    );

    procedure HandleFetchInstruction
    (
        signal controller_has_read_memory: in boolean;
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    );

    procedure DecodeAndExecuteInstruction
    (
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        registers: inout REGISTERS_RECORD;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    );

    procedure HandlePostExecution
    (
        signal controller_has_read_memory: in boolean;
        signal controller_has_written_memory: in boolean;
        committing_read_memory: inout boolean;
        committing_write_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        memory_address_write: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        memory_word_write: out WORD_TYPE;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE;
        registers: inout REGISTERS_RECORD;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    );

end CentralProcessingUnit_Package;

package body CentralProcessingUnit_Package is
    procedure Stage1
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    ) is
    begin
        var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
        var_unit_state := UNIT_STATE_INSTRUCTION_PHASE;
    end Stage1;

    procedure Stage2
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    ) is
    begin
        var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
        var_unit_state := UNIT_STATE_COMMITTING_MEMORY;
    end Stage2;

    procedure Stage3
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    ) is
    begin
        var_instruction_phase := INSTRUCTION_PHASE_DECODE_AND_EXECUTE;
        var_unit_state := UNIT_STATE_INSTRUCTION_PHASE;
    end Stage3;

    procedure Stage4
    (
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    ) is
    begin
        var_instruction_phase := INSTRUCTION_PHASE_DECODE_AND_EXECUTE;
        var_unit_state := UNIT_STATE_COMMITTING_MEMORY;
    end Stage4;

    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE is

    -- Store integer result, make it big enough for multiplication --
    variable temporary_multiply_resulting_integer: MAX_MULTIPLY_ALU_INTEGER_IN_TYPE;
    variable temporary_add_resulting_integer: MAX_ADD_ALU_INTEGER_IN_TYPE;
    variable temporary_resulting_integer: ALU_INTEGER_IN_TYPE;
    variable temporary_resulting_integer_type: ALU_OPERATION_INTEGER_TYPE := ALU_OPERATION_INTEGER_DEFAULT;
    variable division_by_zero: boolean := false;
    variable condition: boolean := false;
    variable integer_out: ALU_INTEGER_OUT_TYPE;

    begin
        case operation_type is
            when ALU_OPERATION_TYPE_ADD =>
                temporary_add_resulting_integer := resize(integer_in_right, MAX_ADD_ALU_INTEGER_IN_TYPE'length);
                temporary_add_resulting_integer := integer_in_left + temporary_add_resulting_integer;
                temporary_resulting_integer_type := ALU_OPERATION_INTEGER_ADD;

            when ALU_OPERATION_TYPE_SUBTRACT =>
                temporary_add_resulting_integer := resize(integer_in_right, MAX_ADD_ALU_INTEGER_IN_TYPE'length);
                temporary_add_resulting_integer := integer_in_left - temporary_add_resulting_integer;
                temporary_resulting_integer_type := ALU_OPERATION_INTEGER_ADD;

            when ALU_OPERATION_TYPE_DIVISION =>
                if integer_in_right = 0 then
                    division_by_zero := true;
                else
                    temporary_resulting_integer := integer_in_left / integer_in_right;
                end if;

            when ALU_OPERATION_TYPE_MULTIPLY =>
                temporary_multiply_resulting_integer := integer_in_left * integer_in_right;
                temporary_resulting_integer_type := ALU_OPERATION_INTEGER_MULTIPLY;

            when ALU_OPERATION_TYPE_OR =>
                temporary_resulting_integer := integer_in_left or integer_in_right;

            when ALU_OPERATION_TYPE_AND =>
                temporary_resulting_integer := integer_in_left and integer_in_right;

            when ALU_OPERATION_TYPE_SLA =>
                temporary_resulting_integer := integer_in_left sla to_integer(integer_in_right);

            when ALU_OPERATION_TYPE_SRA =>
                temporary_resulting_integer := integer_in_left sra to_integer(integer_in_right);
            
            when ALU_OPERATION_TYPE_SLL =>
                temporary_resulting_integer := integer_in_left sll to_integer(integer_in_right);

            when ALU_OPERATION_TYPE_SRL =>
                temporary_resulting_integer := integer_in_left srl to_integer(integer_in_right);

            when ALU_OPERATION_TYPE_ROL =>
                temporary_resulting_integer := integer_in_left rol to_integer(integer_in_right);

            when ALU_OPERATION_TYPE_ROR =>
                temporary_resulting_integer := integer_in_left ror to_integer(integer_in_right);

            when ALU_OPERATION_TYPE_SET =>
                temporary_resulting_integer := integer_in_right;

            when ALU_OPERATION_TYPE_NOT =>
                temporary_resulting_integer := not integer_in_right;

            when ALU_OPERATION_TYPE_BIGGER =>
                condition := integer_in_left > integer_in_right;

            when ALU_OPERATION_TYPE_LOWER =>
                condition := integer_in_left < integer_in_right;

            when ALU_OPERATION_TYPE_EQUAL =>
                condition := integer_in_left = integer_in_right;
        end case;

        -- Resize integer, even if it means to be an overflow --
        case temporary_resulting_integer_type is
            when ALU_OPERATION_INTEGER_DEFAULT =>
                integer_out.value := temporary_resulting_integer;

                if division_by_zero then
                    integer_out.overflow := true;
                else
                    integer_out.overflow := false;
                end if;

            when ALU_OPERATION_INTEGER_ADD =>
                integer_out.value := resize(temporary_add_resulting_integer, ALU_INTEGER_IN_TYPE_SIZE);

                if temporary_add_resulting_integer >= ALU_INTEGER_IN_TYPE'high
                    or temporary_add_resulting_integer < ALU_INTEGER_IN_TYPE'low
                    or division_by_zero then
                    integer_out.overflow := true;
                else
                    integer_out.overflow := false;
                end if;

            when ALU_OPERATION_INTEGER_MULTIPLY =>
                integer_out.value := resize(temporary_multiply_resulting_integer, ALU_INTEGER_IN_TYPE_SIZE);

                if temporary_multiply_resulting_integer >= ALU_INTEGER_IN_TYPE'high
                    or temporary_multiply_resulting_integer < ALU_INTEGER_IN_TYPE'low
                    or division_by_zero then
                    integer_out.overflow := true;
                else
                    integer_out.overflow := false;
                end if;
        end case;

        integer_out.condition := condition;

        return integer_out;
    end HandleALUOperations;

    procedure HandleMemoryALUOperations
    (
        mode: in MEMORY_MODE_TYPE;
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE
    ) is
        variable register_left_index: REGISTER_INTEGER_TYPE;
        variable register_right_index: REGISTER_INTEGER_TYPE;
    begin
        should_commit_memory := true;
        integer_to_commit.mode := mode;

        register_left_index := to_integer(decoded_instruction.operand_left.register_index);
        register_right_index := to_integer(decoded_instruction.operand_right.register_index);

        case decoded_instruction.operand_right.mode is
            when OPERAND_REGISTER =>
                case mode is
                    -- read reg1, reg2 --
                    when MEMORY_MODE_READ =>
                        integer_to_commit.address
                            := registers.general(register_right_index);
                        integer_to_commit.read_type.register_index
                            := decoded_instruction.operand_left.register_index;

                    -- write reg1, reg2 --
                    when MEMORY_MODE_WRITE =>
                        integer_to_commit.address
                            := registers.general(register_right_index);
                        integer_to_commit.write_type.integer_value
                            := registers.general(register_left_index);
                end case;

            when OPERAND_INTEGER =>
                case mode is
                    -- read reg1, address --
                    when MEMORY_MODE_READ =>
                        integer_to_commit.address
                            := decoded_instruction.operand_right.integer_value;
                        integer_to_commit.read_type.register_index
                            := decoded_instruction.operand_left.register_index;

                    -- write reg1, address --
                    when MEMORY_MODE_WRITE =>
                        integer_to_commit.address
                            := decoded_instruction.operand_right.integer_value;
                        integer_to_commit.write_type.integer_value
                            := registers.general(register_left_index);
                end case;
        end case;
    end;

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION is

    variable decoded_instruction: INSTRUCTION;
    begin
        for i in OPCODE_TYPE_SIZE - 1 downto 0 loop
            decoded_instruction.opcode(i) := instruction_in_bits(i);
        end loop;

        -- + OPCODE_TYPE_SIZE --
        for i in REGISTER_INDEX_TYPE_SIZE - 1 downto 0 loop
            decoded_instruction.operand_left.register_index(i) :=
                to_stdulogic(
                    instruction_in_bits(
                        i + OPCODE_TYPE_SIZE
                    )
                );
        end loop;

        -- + OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE --
        decoded_instruction.operand_right.mode := 
            instruction_in_bits(OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE);

        -- + OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + OPERAND_TYPE_SIZE --
        for i in REGISTER_INDEX_TYPE_SIZE - 1 downto 0 loop
            decoded_instruction.operand_right.register_index(i) :=
                to_stdulogic(
                    instruction_in_bits(
                        i + OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + OPERAND_TYPE_SIZE
                    )
                );
        end loop;

        -- + OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + OPERAND_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE --
        for i in CPU_INTEGER_TYPE_SIZE - 1 downto 0 loop
            decoded_instruction.operand_right.integer_value(i) :=
                to_stdulogic(
                    instruction_in_bits(
                        i + OPCODE_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE + OPERAND_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE
                    )
                );
        end loop;

        return decoded_instruction;
    end DecodeInstruction;

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE
    ) is

        variable alu_integer_out: ALU_INTEGER_OUT_TYPE;
        variable operation_type: ALU_OPERATION_TYPE;
        variable is_alu_operation_type: boolean := false;
        variable is_alu_operation_condition_flag_type: boolean := false;
        variable is_jumping: boolean := false;
        variable register_left_index: REGISTER_INTEGER_TYPE;
        variable register_right_index: REGISTER_INTEGER_TYPE;

    begin
        register_left_index := to_integer(decoded_instruction.operand_left.register_index);
        register_right_index := to_integer(decoded_instruction.operand_right.register_index);

        case decoded_instruction.opcode is
            when OPCODE_TYPE_SET =>
                operation_type := ALU_OPERATION_TYPE_SET;
                is_alu_operation_type := true;

            when OPCODE_TYPE_OR =>
                operation_type := ALU_OPERATION_TYPE_OR;
                is_alu_operation_type := true;

            when OPCODE_TYPE_AND =>
                operation_type := ALU_OPERATION_TYPE_AND;
                is_alu_operation_type := true;

            when OPCODE_TYPE_NOT =>
                operation_type := ALU_OPERATION_TYPE_NOT;
                is_alu_operation_type := true;

            when OPCODE_TYPE_ADD =>
                operation_type := ALU_OPERATION_TYPE_ADD;
                is_alu_operation_type := true;

            when OPCODE_TYPE_SUBSTRACT =>
                operation_type := ALU_OPERATION_TYPE_SUBTRACT;
                is_alu_operation_type := true;

            when OPCODE_TYPE_DIVISION =>
                operation_type := ALU_OPERATION_TYPE_DIVISION;
                is_alu_operation_type := true;

            when OPCODE_TYPE_MULTIPLY =>
                operation_type := ALU_OPERATION_TYPE_MULTIPLY;
                is_alu_operation_type := true;

            when OPCODE_TYPE_SLA =>
                operation_type := ALU_OPERATION_TYPE_SLA;
                is_alu_operation_type := true;

            when OPCODE_TYPE_SRA =>
                operation_type := ALU_OPERATION_TYPE_SRA;
                is_alu_operation_type := true;

            when OPCODE_TYPE_SLL =>
                operation_type := ALU_OPERATION_TYPE_SLL;
                is_alu_operation_type := true;
            
            when OPCODE_TYPE_SRL =>
                operation_type := ALU_OPERATION_TYPE_SRL;
                is_alu_operation_type := true;

            when OPCODE_TYPE_ROL =>
                operation_type := ALU_OPERATION_TYPE_ROL;
                is_alu_operation_type := true;

            when OPCODE_TYPE_ROR =>
                operation_type := ALU_OPERATION_TYPE_ROR;
                is_alu_operation_type := true;

            when OPCODE_TYPE_READ =>
                HandleMemoryALUOperations(MEMORY_MODE_READ,
                                          decoded_instruction,
                                          registers,
                                          should_commit_memory,
                                          integer_to_commit);

            when OPCODE_TYPE_WRITE =>
                HandleMemoryALUOperations(MEMORY_MODE_WRITE,
                                          decoded_instruction,
                                          registers,
                                          should_commit_memory,
                                          integer_to_commit);

            when OPCODE_TYPE_IS_BIGGER =>
                operation_type := ALU_OPERATION_TYPE_BIGGER;
                is_alu_operation_type := true;
                is_alu_operation_condition_flag_type := true;

            when OPCODE_TYPE_IS_LOWER =>
                operation_type := ALU_OPERATION_TYPE_LOWER;
                is_alu_operation_type := true;
                is_alu_operation_condition_flag_type := true;

            when OPCODE_TYPE_IS_EQUAL =>
                operation_type := ALU_OPERATION_TYPE_EQUAL;
                is_alu_operation_type := true;
                is_alu_operation_condition_flag_type := true;

            when OPCODE_TYPE_HAD_INTEGER_OVERFLOW =>
                -- Assign overflow flag to condition flag so that he can use BRANCH instruction --
                registers.special.condition_flag := registers.special.overflow_flag;

            ----------------------------------------------------
            -- In case of a simple jump, take the left register
            -- TODO: figure out what to do with the right one
            when OPCODE_TYPE_JUMP =>
                registers.special.program_counter := registers.general(register_left_index);
                -- We're jumping --
                is_jumping := true;

            -----------------------------------------------------------------
            -- Take the first register for jumping, otherwise the second one
            -- TODO: figure out what to do with the right integer.
            when OPCODE_TYPE_BRANCH =>
                if registers.special.condition_flag then
                    registers.special.program_counter := registers.general(register_left_index);
                else
                    registers.special.program_counter := registers.general(register_right_index);
                end if;
                -- We're jumping --
                is_jumping := true;

            -- For now ignore.
            when others =>
                null;
        end case;

        if is_alu_operation_type then
            case decoded_instruction.operand_right.mode is
                -- opcode register1, register2 --
                when OPERAND_REGISTER =>
                    alu_integer_out := HandleALUOperations(operation_type,
                                                           ALU_INTEGER_IN_TYPE(registers.general(register_left_index)),
                                                           ALU_INTEGER_IN_TYPE(registers.general(register_right_index)));
                    registers.general(register_left_index)
                        := CPU_INTEGER_TYPE(alu_integer_out.value);
                -- opcode register1, integer --
                when OPERAND_INTEGER =>
                    alu_integer_out := HandleALUOperations(operation_type,
                                                           ALU_INTEGER_IN_TYPE(registers.general(register_left_index)),
                                                           ALU_INTEGER_IN_TYPE(decoded_instruction.operand_right.integer_value));
                    registers.general(register_left_index)
                        := CPU_INTEGER_TYPE(alu_integer_out.value);
            end case;

            -- Assign overflow flag --
            registers.special.overflow_flag := alu_integer_out.overflow;

            -- Assign condition flag only when needed --
            if is_alu_operation_condition_flag_type then
                registers.special.condition_flag := alu_integer_out.condition;
            end if;
        end if;

        -- If not jumping, simply go the next instruction --
        if not is_jumping then
            -- Incrementing program counter here --
            registers.special.program_counter := registers.special.program_counter + INSTRUCTION_SIZE;
        end if;
    end ExecuteInstruction;

    procedure AskFetchInstruction
    (
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        registers: in REGISTERS_RECORD;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: inout INSTRUCTION_PHASE
    ) is
    begin
        instruction_to_commit.address := registers.special.program_counter;
        instruction_to_commit.bit_index := 0;
        instruction_to_commit.bit_shift := to_integer(registers.special.program_counter mod WORD_SIZE);
        memory_address_read := instruction_to_commit.address - instruction_to_commit.bit_shift;
        committing_read_memory := true;
        Stage2(var_unit_state, var_instruction_phase);
    end AskFetchInstruction;

    procedure HandleFetchInstruction
    (
        signal controller_has_read_memory: in boolean;
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
    begin
        -- Wait for memory commit --
        if not committing_read_memory and not controller_has_read_memory then
            -- Store the bits inside a buffer, they will be decoded later --
            for i in WORD_SIZE - 1 downto 0 loop
                instruction_to_commit.bit_buffer(
                    i + instruction_to_commit.bit_index
                ) := memory_word_read(i);
            end loop;

            instruction_to_commit.bit_index := instruction_to_commit.bit_index + WORD_SIZE;

            -- Do we keep fetching ? --
            if instruction_to_commit.bit_index < INSTRUCTION_BIT_BUFFER'length then
                memory_address_read := instruction_to_commit.address 
                    - instruction_to_commit.bit_shift + instruction_to_commit.bit_index;
                committing_read_memory := true;
                Stage2(var_unit_state, var_instruction_phase);
            else
                -- TODO: Decrypt memory here --
                Decrypt(instruction_to_commit.bit_buffer);
                -- We fetched the whole instruction, get on instruction phase --
                Stage3(var_unit_state, var_instruction_phase);
            end if;
        else
            -- Keep fetching instruction --
            Stage2(var_unit_state, var_instruction_phase);
        end if;
    end HandleFetchInstruction;

    procedure DecodeAndExecuteInstruction
    (
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        registers: inout REGISTERS_RECORD;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
        variable encoded_instruction: INSTRUCTION_BIT_VECTOR;
        variable decoded_instruction: INSTRUCTION;
        variable should_commit_memory: boolean := false;
    begin
        -- Decode instruction --
        for i in INSTRUCTION_SIZE - 1 downto 0 loop
            encoded_instruction(i) := instruction_to_commit.bit_buffer(
                i + instruction_to_commit.bit_shift
            );
        end loop;

        -- TODO: Do not leak information --
        Encrypt(instruction_to_commit.bit_buffer);
        decoded_instruction := DecodeInstruction(encoded_instruction);

        -- Execute instruction --
        ExecuteInstruction(decoded_instruction, registers, should_commit_memory, integer_to_commit);

        -- Should we commit memory before going on another instruction ? --
        if should_commit_memory then
            integer_to_commit.bit_index := 0;
            integer_to_commit.bit_shift := to_integer(integer_to_commit.address mod WORD_SIZE);
            integer_to_commit.write_type.is_inside_read_phase := true;
            memory_address_read := integer_to_commit.address - integer_to_commit.bit_shift;
            --------------------------------------------------
            -- Doesn't matter if it's a read or a write,
            -- we always need to read first the word anyway.
            -- This is because the address can be misaligned
            -- to a word, so we need to retrieve the old
            -- words in order to write them again correctly.
            -- Normally, this isn't needed, but in case
            -- of encryption/decryption, it is.
            -- So it starts with reading memory anyway.
            committing_read_memory := true;
            Stage4(var_unit_state, var_instruction_phase);
        -- Otherwise fetch again another instruction --
        else
            Stage1(var_unit_state, var_instruction_phase);
        end if;
    end DecodeAndExecuteInstruction;

    -- Mostly same logic as HandleFetchInstruction --
    procedure HandleFetchWord
    (
        signal controller_has_read_memory: in boolean;
        committing_read_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE
    ) is
    begin
        -- Has something been fetch yet ? --
        if not committing_read_memory and not controller_has_read_memory then
            -- Gotcha, need to store into buffer --
            for i in WORD_SIZE - 1 downto 0 loop
                integer_to_commit.bit_buffer(
                    integer_to_commit.bit_index + i
                ) := memory_word_read(i);
            end loop;

            integer_to_commit.bit_index := integer_to_commit.bit_index + WORD_SIZE;

            -- Do we keep fetching ? --
            if integer_to_commit.bit_index < INTEGER_BIT_BUFFER'length then
                memory_address_read := integer_to_commit.address - integer_to_commit.bit_shift + integer_to_commit.bit_index;
                committing_read_memory := true;
            else
                -- TODO: Decrypt --
                Decrypt(integer_to_commit.bit_buffer);
            end if;
        end if;
    end HandleFetchWord;

    procedure HandlePostExecution
    (
        signal controller_has_read_memory: in boolean;
        signal controller_has_written_memory: in boolean;
        committing_read_memory: inout boolean;
        committing_write_memory: inout boolean;
        memory_address_read: out CPU_ADDRESS_TYPE;
        memory_address_write: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        memory_word_write: out WORD_TYPE;
        integer_to_commit: inout INTEGER_TO_COMMIT_TYPE;
        registers: inout REGISTERS_RECORD;
        var_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
    begin
        case integer_to_commit.mode is
            when MEMORY_MODE_READ =>
                    HandleFetchWord(controller_has_read_memory,
                                    committing_read_memory,
                                    memory_address_read,
                                    memory_word_read,
                                    integer_to_commit);

                    -- Did we finish to get the word ? --
                    if integer_to_commit.bit_index >= INTEGER_BIT_BUFFER'length then
                        -- Stop here and ask another instruction while setting the register --
                        for i in CPU_INTEGER_TYPE_SIZE - 1 downto 0 loop
                            registers.general(to_integer(integer_to_commit.read_type.register_index))(i)
                                := to_stdulogic(
                                        integer_to_commit.bit_buffer(
                                            i + integer_to_commit.bit_shift
                                        )
                                    );
                        end loop;

                        -- TODO: Do not leak information for encrypted memory --
                        Encrypt(integer_to_commit.bit_buffer);
                        Stage1(var_unit_state, var_instruction_phase);
                    else
                        -- Keep reading memory --
                        Stage4(var_unit_state, var_instruction_phase);
                    end if;

            when MEMORY_MODE_WRITE =>
                if integer_to_commit.write_type.is_inside_read_phase then
                    HandleFetchWord(controller_has_read_memory,
                                    committing_read_memory,
                                    memory_address_read,
                                    memory_word_read,
                                    integer_to_commit);

                    -- Do we still need to be in read phase ? --
                    if integer_to_commit.bit_index >= INTEGER_BIT_BUFFER'length then
                        -- Then prepare the integer to write --
                        for i in CPU_INTEGER_TYPE_SIZE - 1 downto 0 loop
                            integer_to_commit.bit_buffer(
                                i + integer_to_commit.bit_shift
                            ) := to_bit(integer_to_commit.write_type.integer_value(i));
                        end loop;

                        integer_to_commit.bit_index := WORD_SIZE;
                        memory_address_write := integer_to_commit.address - integer_to_commit.bit_shift;

                        -- TODO: Encrypt again bit_buffer here --
                        Encrypt(integer_to_commit.bit_buffer);

                        -- Do not add shifted bits here, since we write the full buffer --
                        for i in WORD_SIZE - 1 downto 0 loop
                            memory_word_write(i) := integer_to_commit.bit_buffer(i);
                        end loop;

                        committing_write_memory := true;
                        integer_to_commit.write_type.is_inside_read_phase := false;
                    end if;

                    -- Keep commiting --
                    Stage4(var_unit_state, var_instruction_phase);
                else
                    -- Check if we have commited memory --
                    if not committing_write_memory and not controller_has_written_memory then
                        if integer_to_commit.bit_index < INTEGER_BIT_BUFFER'length then
                            memory_address_write := integer_to_commit.address +
                                integer_to_commit.bit_index - integer_to_commit.bit_shift;

                            for i in WORD_SIZE - 1 downto 0 loop
                                memory_word_write(i) := integer_to_commit.bit_buffer(
                                    i + integer_to_commit.bit_index
                                );
                            end loop;

                            integer_to_commit.bit_index := integer_to_commit.bit_index + WORD_SIZE;
                            committing_write_memory := true;
                            Stage4(var_unit_state, var_instruction_phase);
                        else
                            -- Return and ask another instruction --
                            Stage1(var_unit_state, var_instruction_phase);
                        end if;
                    else
                        -- Keep commiting --
                        Stage4(var_unit_state, var_instruction_phase);
                    end if;
                end if;
        end case;
    end HandlePostExecution;

    procedure Encrypt
    (
        bit_buffer: inout BIT_VECTOR
    ) is
        constant NUMBER_OF_ENCRYPTED_CHUNKS: integer := bit_buffer'length / ENCRYPTED_CHUNK_SIZE;
        variable bit_buffer_integer_part: BIT_VECTOR(ENCRYPTED_CHUNK_SIZE - 1 downto 0);
    begin
        for i in 0 to NUMBER_OF_ENCRYPTED_CHUNKS - 1 loop
            for j in ENCRYPTED_CHUNK_SIZE - 1 downto 0 loop
                bit_buffer_integer_part(j) := bit_buffer(i * ENCRYPTED_CHUNK_SIZE + j);
            end loop;

            TEAEncrypt(TEA_KEY, bit_buffer_integer_part);

            for j in ENCRYPTED_CHUNK_SIZE - 1 downto 0 loop
                bit_buffer(i * ENCRYPTED_CHUNK_SIZE + j) := bit_buffer_integer_part(j);
            end loop;
        end loop;
    end;

    procedure Decrypt
    (
        bit_buffer: inout BIT_VECTOR
    ) is
        constant NUMBER_OF_ENCRYPTED_CHUNKS: integer := bit_buffer'length / ENCRYPTED_CHUNK_SIZE;
        variable bit_buffer_integer_part: BIT_VECTOR(ENCRYPTED_CHUNK_SIZE - 1 downto 0);
    begin
        for i in 0 to NUMBER_OF_ENCRYPTED_CHUNKS - 1 loop
            for j in ENCRYPTED_CHUNK_SIZE - 1 downto 0 loop
                bit_buffer_integer_part(j) := bit_buffer(i * ENCRYPTED_CHUNK_SIZE + j);
            end loop;

            TEADecrypt(TEA_KEY, bit_buffer_integer_part);

            for j in ENCRYPTED_CHUNK_SIZE - 1 downto 0 loop
                bit_buffer(i * ENCRYPTED_CHUNK_SIZE + j) := bit_buffer_integer_part(j);
            end loop;
        end loop;
    end;

end CentralProcessingUnit_Package;