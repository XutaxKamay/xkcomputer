library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CentralProcessingUnit_Package is

    type MEMORY_MODE_TYPE is
    (
        MEMORY_MODE_READ,
        MEMORY_MODE_WRITE
    );

    constant MAX_INTEGER_BITS : integer := 512;

    subtype ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) downto 0);
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

    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE;

end CentralProcessingUnit_Package;

package body CentralProcessingUnit_Package is
    function HandleALUOperations
    (
        operation_type: ALU_OPERATION_TYPE;
        integer_in_left: ALU_INTEGER_IN_TYPE;
        integer_in_right: ALU_INTEGER_IN_TYPE
    ) return ALU_INTEGER_OUT_TYPE is

    -- Store integer result, make it big enough for multiplication --
    variable temporary_resulting_integer: signed((MAX_INTEGER_BITS - 1) * 2 downto 0);
    variable division_by_zero: boolean := false;
    variable integer_out: ALU_INTEGER_OUT_TYPE;

    begin
        case operation_type is
            when ALU_OPERATION_TYPE_ADD =>
                temporary_resulting_integer := '0' & integer_in_left + integer_in_right;

            when ALU_OPERATION_TYPE_SUBTRACT =>
                temporary_resulting_integer := '0' & integer_in_left - integer_in_right;

            when ALU_OPERATION_TYPE_DIVISION =>
                if integer_in_right = 0 then
                    division_by_zero := true;
                else
                    temporary_resulting_integer := '0' & integer_in_left / integer_in_right;
                end if;

            when ALU_OPERATION_TYPE_MULTIPLY =>
                temporary_resulting_integer := '0' & integer_in_left * integer_in_right;

            when ALU_OPERATION_TYPE_OR =>
                temporary_resulting_integer := '0' & integer_in_left or integer_in_right;

            when ALU_OPERATION_TYPE_AND =>
                temporary_resulting_integer := '0' & integer_in_left and integer_in_right;
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
end CentralProcessingUnit_Package;