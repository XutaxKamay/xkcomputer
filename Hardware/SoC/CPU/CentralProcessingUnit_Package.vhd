library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CentralProcessingUnit_Package is

    type MEMORY_MODE_TYPE is
    ( 
        MEMORY_MODE_READ,
        MEMORY_MODE_WRITE
    );

    constant MAX_MEMORY_BITS: integer := 2**11;
    subtype MEMORY_BIT_VECTOR is BIT_VECTOR((MAX_MEMORY_BITS - 1) downto 0);

    constant MAX_INTEGER_BITS: integer := 2**9;

    subtype ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) downto 0);
    subtype MAX_ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) * 2 downto 0);
    constant ALU_INTEGER_IN_TYPE_SIZE: integer := ALU_INTEGER_IN_TYPE'length;

    type ALU_INTEGER_OUT_TYPE is record
        -- Resulting integer --
        value: ALU_INTEGER_IN_TYPE;
        -- Overflow flag --
        overflow: boolean;
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
    ----------------------------------------
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
    subtype REGISTER_TYPE is unsigned(3 downto 0);
    constant REGISTER_TYPE_SIZE: integer := REGISTER_TYPE'length;
    type REGISTER_ARRAY is array((REGISTER_TYPE'high - 1) downto 0) of CPU_INTEGER_TYPE;

    type SPECIAL_REGISTERS is record
        overflow_flag: boolean;
        condition_flag: boolean;
        program_counter: CPU_ADDRESS_TYPE;
    end record;

    type REGISTERS is record
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
        register_index: REGISTER_TYPE;
    end record;

    type OPERAND_RIGHT is record
        mode: OPERAND_TYPE;
        register_index: REGISTER_TYPE;
        integer: CPU_INTEGER_TYPE;
    end record;

    type INSTRUCTION is record
        opcode: OPCODE_TYPE;
        operand_left: OPERAND_LEFT;
        operand_right: OPERAND_RIGHT;
    end record;

    constant INSTRUCTION_SIZE: integer := OPCODE_TYPE_SIZE
        + REGISTER_TYPE_SIZE
        + (OPERAND_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE + REGISTER_TYPE_SIZE);

    subtype INSTRUCTION_BIT_VECTOR is BIT_VECTOR((INSTRUCTION_SIZE - 1) downto 0);

    -------------------------------------------------------------------------------------------------
    -- 1) ask & fetch instruction
    --
    -- (memory_address inout, memory_size inout, mode out, memory_data inout)
    -- how we send a request to read the memory you say?
    -- when commit_read_memory is 1. after that it has been set to 0,
    -- we know that the memory has been read and we can continue safely.
    -- 
    -- 2) we got the data => decode instruction and execute instruction
    --
    -- in theory we could start to decode the next instruction
    -- just after we have executed it, but i prefer to keep it simple
    --
    --
    -- if there's only registers, we can apply the normal operations.
    -- problem comes when there's something to read/write to instead
    -- if not we can repeat again and ask for next instruction
    --
    -- 3) commit memory
    -- if there's a write, we need a signal to write the integer into,
    -- but also its address to know where to write,
    -- if there's a read, we need a signal to save the resultting integer into,
    -- but also its address to know where to read.
    -- we need memory commit structure with it's type (read or write mode)
    -- 
    -- for writes, it will be the same for reading memory, except it has commit_write_memory to 1.
    --
    -- 4) repeat 1)

    type UNIT_STATE is
    (
        UNIT_STATE_NOT_RUNNING,
        UNIT_STATE_BEGIN,
        UNIT_STATE_FETCH_AND_DECODE_AND_EXECUTE,
        UNIT_STATE_COMMITING_MEMORY
    );

    type COMMIT_MEMORY_RECORD is record
        mode: MEMORY_MODE_TYPE;
        value: CPU_INTEGER_TYPE;
        address: CPU_ADDRESS_TYPE;
        register_index: REGISTER_TYPE;
        has_commit: boolean;
    end record;

    -- Function and procedures --
    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE;

    procedure AskInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address: inout CPU_ADDRESS_TYPE;
        signal memory_size: inout CPU_ADDRESS_TYPE;
        signal memory_mode: inout MEMORY_MODE_TYPE;
        signal program_counter: inout CPU_ADDRESS_TYPE
    );

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION;

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION
    );

    procedure FetchAndDecodeAndExecuteInstruction
    (
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_address: inout CPU_ADDRESS_TYPE;
        signal memory_size: inout CPU_ADDRESS_TYPE;
        signal memory_data: inout MEMORY_BIT_VECTOR;
        signal memory_mode: inout MEMORY_MODE_TYPE;
        signal program_counter: inout CPU_ADDRESS_TYPE;
        signal has_asked_instruction: inout boolean;
        signal signal_unit_state: inout UNIT_STATE;
        signal memory_to_commit: inout COMMIT_MEMORY_RECORD
    );

    procedure CheckCommitMemory
    (
        signal memory_to_commit: inout COMMIT_MEMORY_RECORD;
        signal general_registers: inout REGISTER_ARRAY;
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_data: inout MEMORY_BIT_VECTOR;
        signal signal_unit_state: inout UNIT_STATE
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
            integer_out.overflow := true;
        else
            integer_out.overflow := false;
        end if;

        return integer_out;
    end HandleALUOperations;

    procedure AskInstruction
    (
        signal commit_read_memory: inout boolean;
        signal memory_address: inout CPU_ADDRESS_TYPE;
        signal memory_size: inout CPU_ADDRESS_TYPE;
        signal memory_mode: inout MEMORY_MODE_TYPE;
        signal program_counter: inout CPU_ADDRESS_TYPE
    ) is
    begin
        memory_address <= program_counter;
        program_counter <= program_counter + INSTRUCTION_SIZE;
        memory_size <= to_signed(INSTRUCTION_SIZE, CPU_ADDRESS_TYPE_SIZE);
        memory_mode <= MEMORY_MODE_READ;
        -- Signal the external component for reading memory --
        commit_read_memory <= true;
    end AskInstruction;

    function DecodeInstruction
    (
        instruction_in_bits: INSTRUCTION_BIT_VECTOR
    ) return INSTRUCTION is

    variable decoded_instruction: INSTRUCTION;
    variable count_bits: integer := 0;

    begin

        return decoded_instruction;
    end DecodeInstruction;

    procedure ExecuteInstruction
    (
        decoded_instruction: in INSTRUCTION
    ) is

        variable address_in: CPU_ADDRESS_TYPE;
        variable temporary_integer_bit_vec: BIT_VECTOR((CPU_INTEGER_TYPE_SIZE - 1) downto 0);

    begin
        case decoded_instruction.opcode is
            when OPCODE_TYPE_SET =>
            when OPCODE_TYPE_OR =>
            when OPCODE_TYPE_AND =>
            when OPCODE_TYPE_NOT =>
            when OPCODE_TYPE_ADD =>
            when OPCODE_TYPE_SUBSTRACT =>
            when OPCODE_TYPE_DIVISION =>
            when OPCODE_TYPE_MULTIPLY =>
            when OPCODE_TYPE_READ =>
            when OPCODE_TYPE_WRITE =>
            when OPCODE_TYPE_IS_BIGGER =>
            when OPCODE_TYPE_IS_LOWER => 
            when OPCODE_TYPE_IS_EQUAL =>
            when OPCODE_TYPE_HAD_INTEGER_OVERFLOW =>
            when OPCODE_TYPE_JUMP =>
            when OPCODE_TYPE_BRANCH =>
        end case;
    end ExecuteInstruction;

    procedure FetchAndDecodeAndExecuteInstruction
    (
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_address: inout CPU_ADDRESS_TYPE;
        signal memory_size: inout CPU_ADDRESS_TYPE;
        signal memory_data: inout MEMORY_BIT_VECTOR;
        signal memory_mode: inout MEMORY_MODE_TYPE;
        signal program_counter: inout CPU_ADDRESS_TYPE;
        signal has_asked_instruction: inout boolean;
        signal signal_unit_state: inout UNIT_STATE;
        signal memory_to_commit: inout COMMIT_MEMORY_RECORD
    ) is
        variable var_decoded_instruction: INSTRUCTION;
        variable var_instruction_fetched: INSTRUCTION_BIT_VECTOR;
        variable should_commit_memory: boolean;
    begin
        if not has_asked_instruction then
            has_asked_instruction <= true;
            -- AskInstruction will trigger new execution --
            AskInstruction(commit_read_memory,
                           memory_address,
                           memory_size,
                           memory_mode,
                           program_counter);
        else
            -- Has instruction has been fetched ? --
            if not commit_read_memory then
                has_asked_instruction <= false;

                -- Get instruction data --
                var_instruction_fetched := memory_data((INSTRUCTION_BIT_VECTOR'length - 1) downto 0);

                -- Decode instruction --
                var_decoded_instruction := DecodeInstruction(var_instruction_fetched);

                -- Execute instruction --
                ExecuteInstruction(var_decoded_instruction);

                -- Check if we have to commit memory --
                if should_commit_memory then
                    memory_mode <= memory_to_commit.mode;
                    memory_size <= to_signed(CPU_INTEGER_TYPE_SIZE, CPU_ADDRESS_TYPE_SIZE);
                    memory_address <= memory_to_commit.address;
                    if memory_mode = MEMORY_MODE_WRITE then
                        memory_data <= to_bitvector(std_logic_vector(memory_to_commit.value));
                    end if;
                    -- Finally, change state as soon as possible to wait for commiting memory --
                    signal_unit_state <= UNIT_STATE_COMMITING_MEMORY;
                else
                    -- Otherwise, begin another fetch --
                    signal_unit_state <= UNIT_STATE_BEGIN;
                end if;
            end if;
        end if;
    end FetchAndDecodeAndExecuteInstruction;

    procedure CheckCommitMemory
    (
        signal memory_to_commit: inout COMMIT_MEMORY_RECORD;
        signal general_registers: inout REGISTER_ARRAY;
        signal commit_read_memory: inout boolean;
        signal commit_write_memory: inout boolean;
        signal memory_data: inout MEMORY_BIT_VECTOR;
        signal signal_unit_state: inout UNIT_STATE
    ) is
    begin
        if not memory_to_commit.has_commit then
            memory_to_commit.has_commit <= true;
            case memory_to_commit.mode is
                -- If it's read, it's always a register to set --
                when MEMORY_MODE_READ =>
                    commit_read_memory <= true;
                -- If it's write, it's always an address to write to --
                when MEMORY_MODE_WRITE =>
                    commit_write_memory <= true;
            end case;
        else
            -- Check if memory has been commited --
            if not commit_read_memory and not commit_write_memory then
                if memory_to_commit.mode = MEMORY_MODE_READ then
                    general_registers(to_integer(memory_to_commit.register_index))
                        <= CPU_INTEGER_TYPE(to_stdlogicvector(memory_data((CPU_ADDRESS_TYPE_SIZE - 1) downto 0)));
                end if;
                memory_to_commit.has_commit <= false;
                -- Do again another instruction --
                signal_unit_state <= UNIT_STATE_BEGIN;
            end if;
        end if;
    end CheckCommitMemory;

end CentralProcessingUnit_Package;