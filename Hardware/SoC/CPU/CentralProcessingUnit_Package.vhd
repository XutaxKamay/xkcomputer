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
	subtype CPU_INTEGER_TYPE is ALU_INTEGER_IN_TYPE;

	subtype MNEMONIC_TYPE is std_logic_vector(3 downto 0);

	-- Integer operations --
	constant MNEMONIC_TYPE_SET: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(0, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_OR: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(1, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_AND: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(2, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_NOT: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(3, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_ADD: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(4, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_SUBSTRACT: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(5, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_DIVISION: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(6, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_MULTIPLY: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(7, MNEMONIC_TYPE'length));
	-- Memory instructions --
	constant MNEMONIC_TYPE_READ_INTEGER: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(8, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_WRITE_INTEGER: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(9, MNEMONIC_TYPE'length));
	-- Branch instructions --
	constant MNEMONIC_TYPE_IS_BIGGER: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(10, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_IS_LOWER: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(11, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_IS_EQUAL: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(12, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_HAD_OVERFLOW: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(13, MNEMONIC_TYPE'length));
	constant MNEMONIC_TYPE_JUMP: MNEMONIC_TYPE := MNEMONIC_TYPE(to_unsigned(14, MNEMONIC_TYPE'length));
	
	subtype OPERAND_TYPE is std_logic;

	constant OPERAND_ADDRESS: OPERAND_TYPE := '0';
	constant OPERAND_INTEGER: OPERAND_TYPE := '1';

	type OPERAND is record
		kind: OPERAND_TYPE;
		value: CPU_INTEGER_TYPE;
	end record;

	type INSTRUCTION is record
		mnemonic_type: MNEMONIC_TYPE;
		operand_left: OPERAND;
		operand_right: OPERAND;
	end record;

end CentralProcessingUnit_Package;
