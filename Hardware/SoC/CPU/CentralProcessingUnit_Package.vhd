library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CentralProcessingUnit_Package is

	constant MAX_INTEGER_BITS : integer := 512;

	subtype ALU_INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) downto 0);

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

	-------------------------------------------
	-- Yup, we can have negative addressing. --
	-- Those aren't real though.             --
	-- They will be still indexed,           --
	-- but they'll be simply taken in        --
	-- another matrix.                       --
	-- This is mainly for making the ALU     --
	-- and the CPU more easier.              --
	-------------------------------------------
	subtype CPU_ADDRESS_TYPE is unsigned(63 downto 0);
	constant CPU_ADDRESS_TYPE_SIZE: integer := CPU_ADDRESS_TYPE'length;

	subtype CPU_INTEGER_TYPE is ALU_INTEGER_IN_TYPE;
	constant CPU_INTEGER_TYPE_SIZE: integer := CPU_INTEGER_TYPE'length;

	subtype MNEMONIC_TYPE is std_logic_vector(3 downto 0);
	constant MNEMONIC_TYPE_SIZE: integer := MNEMONIC_TYPE'length;

	-- Integer operations --
	constant MNEMONIC_TYPE_SET: MNEMONIC_TYPE := "0000";
	constant MNEMONIC_TYPE_OR: MNEMONIC_TYPE := "0001";
	constant MNEMONIC_TYPE_AND: MNEMONIC_TYPE := "0010";
	constant MNEMONIC_TYPE_NOT: MNEMONIC_TYPE := "0011";
	constant MNEMONIC_TYPE_ADD: MNEMONIC_TYPE := "0100";
	constant MNEMONIC_TYPE_SUBSTRACT: MNEMONIC_TYPE := "0101";
	constant MNEMONIC_TYPE_DIVISION: MNEMONIC_TYPE := "0110";
	constant MNEMONIC_TYPE_MULTIPLY: MNEMONIC_TYPE := "0111";
	-- Memory instructions --
	constant MNEMONIC_TYPE_READ_INTEGER: MNEMONIC_TYPE := "1000";
	constant MNEMONIC_TYPE_WRITE_INTEGER: MNEMONIC_TYPE := "1001";
	-- Branch instructions --
	constant MNEMONIC_TYPE_IS_BIGGER: MNEMONIC_TYPE := "1010";
	constant MNEMONIC_TYPE_IS_LOWER: MNEMONIC_TYPE := "1011";
	constant MNEMONIC_TYPE_IS_EQUAL: MNEMONIC_TYPE := "1100";
	constant MNEMONIC_TYPE_HAD_INTEGER_OVERFLOW: MNEMONIC_TYPE := "1101";
	constant MNEMONIC_TYPE_JUMP: MNEMONIC_TYPE := "1110";
	
	subtype OPERAND_TYPE is std_logic_vector(1 downto 0);
	constant OPERAND_TYPE_SIZE: integer := OPERAND_TYPE'length;

	constant OPERAND_ADDRESS: OPERAND_TYPE := OPERAND_TYPE(to_unsigned(0, OPERAND_TYPE_SIZE));
	constant OPERAND_INTEGER: OPERAND_TYPE := OPERAND_TYPE(to_unsigned(1, OPERAND_TYPE_SIZE));

	type OPERAND is record
		kind: OPERAND_TYPE;
		value: CPU_INTEGER_TYPE;
	end record;

	constant OPERAND_SIZE: integer := OPERAND_TYPE_SIZE + CPU_INTEGER_TYPE_SIZE;

	type INSTRUCTION is record
		mnemonic_type: MNEMONIC_TYPE;
		operand_left: OPERAND;
		operand_right: OPERAND;
	end record;

	-----------------------------------------------------------------
	-- Instruction size is always the same.                        --
	-- mnemonic type size + operand left size + operand right size --
	-----------------------------------------------------------------
	constant INSTRUCTION_SIZE: integer := MNEMONIC_TYPE_SIZE + (2 * OPERAND_SIZE);

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
				temporary_resulting_integer := integer_in_left + integer_in_right;
			when ALU_OPERATION_TYPE_SUBTRACT =>
				temporary_resulting_integer := integer_in_left - integer_in_right;
			when ALU_OPERATION_TYPE_DIVISION =>
				if integer_in_right = 0 then
					division_by_zero := true;
				else
					temporary_resulting_integer := integer_in_left / integer_in_right;
				end if;
			when ALU_OPERATION_TYPE_MULTIPLY =>
				temporary_resulting_integer := integer_in_left * integer_in_right;
			when ALU_OPERATION_TYPE_OR =>
				temporary_resulting_integer := integer_in_left or integer_in_right;
			when ALU_OPERATION_TYPE_AND =>
				temporary_resulting_integer := integer_in_left and integer_in_right;
		end case;

		-- Resize integer, even if it means to be an overflow --
		integer_out.value := resize(temporary_resulting_integer, integer_out.value'length);

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