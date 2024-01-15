library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_Package.all;

package CentralProcessingUnit_Package is

    type MEMORY_MODE_TYPE is
    ( 
        MEMORY_MODE_READ,
        MEMORY_MODE_WRITE
    );

    -- 256 bits, ideal for AES and other encryption methods --
    constant INTEGER_SIZE: integer := 42;

    type ALU_OPERATION_INTEGER_TYPE is
    (
        ALU_OPERATION_INTEGER_DEFAULT,
        ALU_OPERATION_INTEGER_ADD,
        ALU_OPERATION_INTEGER_MULTIPLY
    );

    subtype ALU_INTEGER_IN_TYPE is signed((INTEGER_SIZE - 1) downto 0);
    subtype MAX_ADD_ALU_INTEGER_IN_TYPE is signed(INTEGER_SIZE downto 0);
    subtype MAX_MULTIPLY_ALU_INTEGER_IN_TYPE is signed(((INTEGER_SIZE * 2) - 1) downto 0);
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
        -- Operation with only one integer --
        ALU_OPERATION_TYPE_SET,
        ALU_OPERATION_TYPE_NOT,
        ALU_OPERATION_TYPE_BIGGER,
        ALU_OPERATION_TYPE_LOWER,
        ALU_OPERATION_TYPE_EQUAL
    );

    ----------------------------------------
    -- I don't think we're going to reach --
    -- 2^512 bits of bit address space    --
    ----------------------------------------
    constant REAL_MEMORY_END_ADDRESS: integer := 2**20 - 1;
    -- Will be used for I/O devices --
    constant MMIO_ADDRESS_START: integer := REAL_MEMORY_END_ADDRESS + 1;

    subtype CPU_ADDRESS_TYPE is ALU_INTEGER_IN_TYPE;
    constant CPU_ADDRESS_TYPE_SIZE: integer := CPU_ADDRESS_TYPE'length;

    subtype CPU_INTEGER_TYPE is ALU_INTEGER_IN_TYPE;
    constant CPU_INTEGER_TYPE_SIZE: integer := CPU_INTEGER_TYPE'length;

    subtype OPCODE_TYPE is BIT_VECTOR(3 downto 0);
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
    -- Jumping and branches --
    constant OPCODE_TYPE_JUMP: OPCODE_TYPE := "1110";
    constant OPCODE_TYPE_BRANCH: OPCODE_TYPE := "1111";

    subtype OPERAND_TYPE is BIT;
    constant OPERAND_TYPE_SIZE: integer := 1;

    constant OPERAND_REGISTER: OPERAND_TYPE := '0';
    -- Can be either an address or a value depending on the opcode --
    constant OPERAND_INTEGER: OPERAND_TYPE := '1';

    -- 16 registers is way more than enough --
    subtype REGISTER_INDEX_TYPE is unsigned(3 downto 0);
    constant REGISTER_INDEX_TYPE_SIZE: integer := REGISTER_INDEX_TYPE'length;
    type REGISTER_ARRAY is array((REGISTER_INDEX_TYPE'high - 1) downto 0) of CPU_INTEGER_TYPE;

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

    constant INSTRUCTION_SIZE: integer := OPCODE_TYPE_SIZE
        + REGISTER_INDEX_TYPE_SIZE
        + (OPERAND_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE + REGISTER_INDEX_TYPE_SIZE);
    subtype INSTRUCTION_BIT_VECTOR is BIT_VECTOR((INSTRUCTION_SIZE - 1) downto 0);

    constant WORD_SIZE: integer := INTEGER_SIZE;
    subtype WORD_TYPE is BIT_VECTOR((WORD_SIZE - 1) downto 0);

    constant AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INSTRUCTION: integer := INSTRUCTION_SIZE
        + (WORD_SIZE - (INSTRUCTION_SIZE mod WORD_SIZE));
    subtype INSTRUCTION_BIT_BUFFER is
        BIT_VECTOR((AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INSTRUCTION - 1) downto 0);

    constant AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INTEGER: integer := CPU_INTEGER_TYPE_SIZE
        + (WORD_SIZE - (CPU_INTEGER_TYPE_SIZE mod WORD_SIZE));
    subtype INTEGER_BIT_BUFFER is BIT_VECTOR((AMOUNT_OF_BITS_FOR_FULL_FETCH_FROM_WORDS_FOR_INTEGER - 1) downto 0);

    type UNIT_STATE is
    (
        UNIT_STATE_INSTRUCTION_PHASE,
        UNIT_STATE_COMMITING_MEMORY
    );

    type INSTRUCTION_PHASE is
    (
        INSTRUCTION_PHASE_FETCHING,
        INSTRUCTION_PHASE_DECODE_AND_EXECUTE
    );

    -- Need specialized type for such fetchs --
    type COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE is record
        address: CPU_ADDRESS_TYPE;
        bit_buffer: INSTRUCTION_BIT_BUFFER;
        bit_count: integer;
        bit_index: integer;
        bit_shift: integer;
    end record;

    type COMMIT_READ_WORD_TYPE is record
        register_index: REGISTER_INDEX_TYPE;
    end record;

    type COMMIT_WRITE_WORD_TYPE is record
        word_value: CPU_INTEGER_TYPE;
        is_inside_read_phase: boolean;
    end record;

    type WORD_TO_COMMIT_TYPE is record
        mode: MEMORY_MODE_TYPE;
        address: CPU_ADDRESS_TYPE;
        read_type: COMMIT_READ_WORD_TYPE;
        write_type: COMMIT_WRITE_WORD_TYPE;
        bit_buffer: INTEGER_BIT_BUFFER;
        bit_count: integer;
        bit_index: integer;
        bit_shift: integer;
    end record;

    -- Function and procedures --
    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE;

    procedure HandleMemoryOperations
    (
        mode: in MEMORY_MODE_TYPE;
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        word_to_commit: inout WORD_TO_COMMIT_TYPE
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
        word_to_commit: inout WORD_TO_COMMIT_TYPE
    );

    procedure AskFetchInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        registers: in REGISTERS_RECORD;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        signal signal_unit_state: inout UNIT_STATE
    );

    procedure HandleFetchInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    );

    procedure DecodeAndExecuteInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        registers: inout REGISTERS_RECORD;
        word_to_commit: inout WORD_TO_COMMIT_TYPE;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    );

    procedure HandlePostExecution
    (
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_address_write: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        signal memory_word_write: out WORD_TYPE;
        word_to_commit: inout WORD_TO_COMMIT_TYPE;
        registers: inout REGISTERS_RECORD;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
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
            
            when ALU_OPERATION_TYPE_SET =>
                temporary_resulting_integer := integer_in_right;

            when ALU_OPERATION_TYPE_NOT =>
                temporary_resulting_integer := not integer_in_left;

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

                if temporary_add_resulting_integer > ALU_INTEGER_IN_TYPE'high
                    or temporary_add_resulting_integer < ALU_INTEGER_IN_TYPE'low
                    or division_by_zero then
                    integer_out.overflow := true;
                else
                    integer_out.overflow := false;
                end if;

            when ALU_OPERATION_INTEGER_MULTIPLY =>
                integer_out.value := resize(temporary_multiply_resulting_integer, ALU_INTEGER_IN_TYPE_SIZE);

                if temporary_multiply_resulting_integer > ALU_INTEGER_IN_TYPE'high
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

    procedure HandleMemoryOperations
    (
        mode: in MEMORY_MODE_TYPE;
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        word_to_commit: inout WORD_TO_COMMIT_TYPE
    ) is
    begin
        should_commit_memory := true;
        word_to_commit.mode := mode;

        case decoded_instruction.operand_right.mode is
            when OPERAND_REGISTER =>
                case mode is
                    -- read reg1, reg2 --
                    when MEMORY_MODE_READ =>
                        word_to_commit.address
                            := registers.general(to_integer(decoded_instruction.operand_right.register_index));
                        word_to_commit.read_type.register_index
                            := decoded_instruction.operand_left.register_index;

                    -- write reg1, reg2 --
                    when MEMORY_MODE_WRITE =>
                        word_to_commit.address
                            := registers.general(to_integer(decoded_instruction.operand_right.register_index));
                        word_to_commit.write_type.word_value
                            := registers.general(to_integer(decoded_instruction.operand_left.register_index));
                end case;

            when OPERAND_INTEGER =>
                case mode is
                    -- read reg1, address --
                    when MEMORY_MODE_READ =>
                        word_to_commit.address
                            := decoded_instruction.operand_right.integer_value;
                        word_to_commit.read_type.register_index
                            := decoded_instruction.operand_left.register_index;

                    -- write reg1, address --
                    when MEMORY_MODE_WRITE =>
                        word_to_commit.address
                            := decoded_instruction.operand_right.integer_value;
                        word_to_commit.write_type.word_value
                            := registers.general(to_integer(decoded_instruction.operand_left.register_index));
                end case;
        end case;
    end;

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION is

    variable decoded_instruction: INSTRUCTION;
    variable count_bits: integer := 0;

    begin
        decoded_instruction.opcode := instruction_in_bits((count_bits + (OPCODE_TYPE_SIZE - 1)) downto count_bits);
        count_bits := count_bits + OPCODE_TYPE_SIZE;

        decoded_instruction.operand_left.register_index := REGISTER_INDEX_TYPE(
            to_stdlogicvector(instruction_in_bits((count_bits + (REGISTER_INDEX_TYPE_SIZE - 1)) downto count_bits)));
        count_bits := count_bits + REGISTER_INDEX_TYPE_SIZE;
        
        decoded_instruction.operand_right.mode := instruction_in_bits(count_bits);
        count_bits := count_bits + OPERAND_TYPE_SIZE;

        decoded_instruction.operand_right.register_index := REGISTER_INDEX_TYPE(
            to_stdlogicvector(instruction_in_bits((count_bits + (REGISTER_INDEX_TYPE_SIZE - 1)) downto count_bits)));
        count_bits := count_bits + REGISTER_INDEX_TYPE_SIZE;

        decoded_instruction.operand_right.integer_value := CPU_INTEGER_TYPE(
            to_stdlogicvector(instruction_in_bits((count_bits + (CPU_INTEGER_TYPE_SIZE - 1)) downto count_bits)));
        count_bits := count_bits + CPU_INTEGER_TYPE_SIZE;

        return decoded_instruction;
    end DecodeInstruction;

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION;
        registers: inout REGISTERS_RECORD;
        should_commit_memory: inout boolean;
        word_to_commit: inout WORD_TO_COMMIT_TYPE
    ) is

        variable alu_integer_out: ALU_INTEGER_OUT_TYPE;
        variable operation_type: ALU_OPERATION_TYPE;
        variable is_alu_operation_type: boolean := false;
        variable is_alu_operation_condition_flag_type: boolean := false;
        variable is_jumping: boolean := false;

    begin
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

            when OPCODE_TYPE_READ =>
                HandleMemoryOperations(MEMORY_MODE_READ,
                                       decoded_instruction,
                                       registers,
                                       should_commit_memory,
                                       word_to_commit);

            when OPCODE_TYPE_WRITE =>
                HandleMemoryOperations(MEMORY_MODE_WRITE,
                                       decoded_instruction,
                                       registers,
                                       should_commit_memory,
                                       word_to_commit);

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
                registers.special.program_counter := registers.general(
                    to_integer(decoded_instruction.operand_left.register_index));
                is_jumping := true;

            -----------------------------------------------------------------
            -- Take the first register for jumping, otherwise the second one
            -- TODO: figure out what to do with the right integer.
            when OPCODE_TYPE_BRANCH =>
                if registers.special.condition_flag then
                    registers.special.program_counter := registers.general(
                        to_integer(decoded_instruction.operand_left.register_index));
                else
                    registers.special.program_counter := registers.general(
                        to_integer(decoded_instruction.operand_right.register_index));
                end if;
                is_jumping := true;
        end case;

        if is_alu_operation_type then
            case decoded_instruction.operand_right.mode is
                -- opcode register1, register2 --
                when OPERAND_REGISTER =>
                    alu_integer_out := HandleALUOperations(operation_type,
                                                           ALU_INTEGER_IN_TYPE(registers.general(
                                                            to_integer(decoded_instruction.operand_left.register_index))),
                                                           ALU_INTEGER_IN_TYPE(registers.general(
                                                            to_integer(decoded_instruction.operand_right.register_index))));
                    registers.general(to_integer(decoded_instruction.operand_left.register_index)) := CPU_INTEGER_TYPE(alu_integer_out.value);
                -- opcode register1, integer --
                when OPERAND_INTEGER =>
                    alu_integer_out := HandleALUOperations(operation_type,
                                                           ALU_INTEGER_IN_TYPE(registers.general(
                                                            to_integer(decoded_instruction.operand_left.register_index))),
                                                           ALU_INTEGER_IN_TYPE(decoded_instruction.operand_right.integer_value));
                    registers.general(to_integer(decoded_instruction.operand_left.register_index)) := CPU_INTEGER_TYPE(alu_integer_out.value);
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
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        registers: in REGISTERS_RECORD;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        signal signal_unit_state: inout UNIT_STATE
    ) is
        variable bit_shift: integer := to_integer(instruction_to_commit.address mod WORD_SIZE);
    begin
        instruction_to_commit.address := registers.special.program_counter;
        instruction_to_commit.bit_count := 0;
        instruction_to_commit.bit_index := 0;
        instruction_to_commit.bit_shift := bit_shift;
        memory_address_read <= instruction_to_commit.address - instruction_to_commit.bit_shift;
        commit_read_memory <= true;
        signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
    end AskFetchInstruction;

    procedure HandleFetchInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
    begin
        -- Wait for memory commit --
        if not commit_read_memory then
            -- Store the bits inside a buffer, they will be decoded later --
            instruction_to_commit.bit_buffer
                ((instruction_to_commit.bit_index + WORD_SIZE - 1) 
                    downto instruction_to_commit.bit_index) := memory_word_read;
            instruction_to_commit.bit_index := instruction_to_commit.bit_index + WORD_SIZE;

            ---------------------------------------------------------------------------------
            -- Increment to WORD_SIZE - shift,
            -- the shift is used so we're sure that we got the exact number of bits we want
            -- This is only needed the first time though
            instruction_to_commit.bit_count := instruction_to_commit.bit_count + WORD_SIZE;
            if instruction_to_commit.bit_count = 0 then
                instruction_to_commit.bit_count := instruction_to_commit.bit_count - instruction_to_commit.bit_shift;
            end if;

            -- Do we keep fetching ? --
            if instruction_to_commit.bit_count < INSTRUCTION_BIT_BUFFER'length then
                memory_address_read <= instruction_to_commit.address - instruction_to_commit.bit_shift + instruction_to_commit.bit_index;
                commit_read_memory <= true;
                signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
            else
                -- TODO: Decrypt memory here --
                -- We fetched the whole instruction, trigger a new execution on instruction phase --
                var_instruction_phase := INSTRUCTION_PHASE_DECODE_AND_EXECUTE;
                signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
            end if;
        else
            -- Keep waiting for memory --
            signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
        end if;
    end HandleFetchInstruction;

    procedure DecodeAndExecuteInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        instruction_to_commit: inout COMMIT_MEMORY_FETCH_INSTRUCTION_TYPE;
        registers: inout REGISTERS_RECORD;
        word_to_commit: inout WORD_TO_COMMIT_TYPE;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
        variable encoded_instruction: INSTRUCTION_BIT_VECTOR;
        variable decoded_instruction: INSTRUCTION;
        variable should_commit_memory: boolean := false;
    begin
        -- Decode instruction --
        encoded_instruction := instruction_to_commit.bit_buffer(
            (INSTRUCTION_SIZE + instruction_to_commit.bit_shift - 1) downto instruction_to_commit.bit_shift);
        decoded_instruction := DecodeInstruction(encoded_instruction);
        
        -- Execute instruction --
        ExecuteInstruction(decoded_instruction, registers, should_commit_memory, word_to_commit);

        -- Should we commit memory before going on another instruction ? --
        if should_commit_memory then
            word_to_commit.bit_count := 0;
            word_to_commit.bit_index := 0;
            word_to_commit.bit_shift := to_integer(word_to_commit.address mod WORD_SIZE);
            word_to_commit.write_type.is_inside_read_phase := true;
            memory_address_read <= word_to_commit.address - word_to_commit.bit_shift;
            --------------------------------------------------
            -- Doesn't matter if it's a read or a write,
            -- we always need to read first the word anyway.
            -- This is because the address can be misaligned
            -- to a word, so we need to retrieve the old
            -- words in order to write them again correctly.
            -- Normally, this isn't needed, but in case
            -- of encryption/decryption, it is.
            -- So it starts with reading memory anyway.
            commit_read_memory <= true;
            signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
        -- Otherwise fetch again another instruction --
        else
            var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
            signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
        end if;
    end DecodeAndExecuteInstruction;

    -- Mostly same logic as HandleFetchInstruction --
    procedure HandleFetchWord
    (
        signal commit_read_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        word_to_commit: inout WORD_TO_COMMIT_TYPE
    ) is
    begin
        -- Has something been fetch yet ? --
        if not commit_read_memory then
            -- Gotcha, need to store into buffer --
            word_to_commit.bit_buffer((word_to_commit.bit_index + WORD_SIZE - 1) 
                downto word_to_commit.bit_index) := memory_word_read;
            word_to_commit.bit_index := word_to_commit.bit_index + WORD_SIZE;

            word_to_commit.bit_count := word_to_commit.bit_count + WORD_SIZE;

            if word_to_commit.bit_count = 0 then
                word_to_commit.bit_count := word_to_commit.bit_count - word_to_commit.bit_shift;
            end if;

            -- Do we keep fetching ? --
            if word_to_commit.bit_count < INTEGER_BIT_BUFFER'length then
                memory_address_read <= word_to_commit.address - word_to_commit.bit_shift + word_to_commit.bit_index;
                commit_read_memory <= true;
            end if;
        end if;
    end HandleFetchWord;

    procedure HandlePostExecution
    (
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_address_read: out CPU_ADDRESS_TYPE;
        signal memory_address_write: out CPU_ADDRESS_TYPE;
        signal memory_word_read: in WORD_TYPE;
        signal memory_word_write: out WORD_TYPE;
        word_to_commit: inout WORD_TO_COMMIT_TYPE;
        registers: inout REGISTERS_RECORD;
        signal signal_unit_state: inout UNIT_STATE;
        var_instruction_phase: out INSTRUCTION_PHASE
    ) is
    begin
        case word_to_commit.mode is
            when MEMORY_MODE_READ =>
                    HandleFetchWord(commit_read_memory,
                                    memory_address_read,
                                    memory_word_read,
                                    word_to_commit);
                    if word_to_commit.bit_count >= INTEGER_BIT_BUFFER'length then
                        -- TODO: Decrypt memory here --
                        -- Stop here and ask another instruction while setting the register --
                        registers.general(to_integer(word_to_commit.read_type.register_index)) := CPU_INTEGER_TYPE(to_stdlogicvector(
                            word_to_commit.bit_buffer((CPU_INTEGER_TYPE_SIZE + word_to_commit.bit_shift - 1) downto word_to_commit.bit_shift)));
                        var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
                        signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
                    else
                        -- Keep reading memory --
                        signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
                    end if;

            when MEMORY_MODE_WRITE =>
                if word_to_commit.write_type.is_inside_read_phase then
                    HandleFetchWord(commit_read_memory,
                                    memory_address_read,
                                    memory_word_read,
                                    word_to_commit);
                    -- Do we still need to be in read phase ? --
                    if word_to_commit.bit_count >= INTEGER_BIT_BUFFER'length then
                        -- TODO: Decrypt bit_buffer here --
                        -- Then prepare the word to write --
                        word_to_commit.bit_buffer((CPU_INTEGER_TYPE_SIZE + word_to_commit.bit_shift - 1) downto word_to_commit.bit_shift)
                            := to_bitvector(std_logic_vector(word_to_commit.write_type.word_value));
                        word_to_commit.bit_index := WORD_SIZE;
                        memory_address_write <= word_to_commit.address - word_to_commit.bit_shift;
                        -- TODO: Encrypt again bit_buffer here --
                        memory_word_write <= word_to_commit.bit_buffer(WORD_SIZE - 1 downto 0);
                        commit_write_memory <= true;
                        word_to_commit.write_type.is_inside_read_phase := false;
                    end if;

                    -- Keep commiting --
                    signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
                else
                    if not commit_write_memory then
                        if word_to_commit.bit_index < INTEGER_BIT_BUFFER'length then
                            memory_address_write <= word_to_commit.address + word_to_commit.bit_index;
                            memory_word_write <= word_to_commit.bit_buffer((word_to_commit.bit_index + WORD_SIZE - 1) 
                                downto word_to_commit.bit_index);
                            word_to_commit.bit_index := word_to_commit.bit_index + WORD_SIZE;
                            commit_write_memory <= true;
                            signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
                        else
                            -- Return to ask another instruction --
                            var_instruction_phase := INSTRUCTION_PHASE_FETCHING;
                            signal_unit_state <= UNIT_STATE_INSTRUCTION_PHASE;
                        end if;
                    else
                        -- Keep commiting --
                        signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
                    end if;
                end if;
        end case;
    end HandlePostExecution;

end CentralProcessingUnit_Package;