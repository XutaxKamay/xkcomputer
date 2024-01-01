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

	type MNEMONIC_TYPE is
	(
		-- Integer operations --
		MNEMONIC_TYPE_SET,
		MNEMONIC_TYPE_OR,
		MNEMONIC_TYPE_AND,
		MNEMONIC_TYPE_NOT,
		MNEMONIC_TYPE_ADD,
		MNEMONIC_TYPE_SUBSTRACT,
		MNEMONIC_TYPE_DIVISION,
		MNEMONIC_TYPE_MULTIPLY,
		-- Memory instructions --
		MNEMONIC_TYPE_READ_INTEGER,
		MNEMONIC_TYPE_WRITE_INTEGER,
		-- Branch instructions --
		MNEMONIC_TYPE_IS_BIGGER,
		MNEMONIC_TYPE_IS_LOWER,
		MNEMONIC_TYPE_IS_BIGGER_EQUAL,
		MNEMONIC_TYPE_IS_LOWER_EQUAL,
		MNEMONIC_TYPE_IS_EQUAL,
		MNEMONIC_TYPE_HAD_OVERFLOW,
		MNEMONIC_TYPE_JUMP
	);

	type OPERAND_TYPE is
	(
		OPERAND_ADDRESS,
		OPERAND_INTEGER
	);

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
