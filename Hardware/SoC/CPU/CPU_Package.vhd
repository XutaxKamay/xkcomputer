library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CPU_Package is

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

	type INSTRUCTION_TYPE is
	(
		INSTRUCTION_TYPE_SET,
		INSTRUCTION_TYPE_OR,
		INSTRUCTION_TYPE_AND,
		INSTRUCTION_TYPE_NOT,
		INSTRUCTION_TYPE_ADD,
		INSTRUCTION_TYPE_SUBSTRACT,
		INSTRUCTION_TYPE_DIVISION,
		INSTRUCTION_TYPE_MULTIPLY,
		INSTRUCTION_TYPE_READ_INTEGER,
		INSTRUCTION_TYPE_WRITE_INTEGER,
		INSTRUCTION_TYPE_IS_BIGGER,
		INSTRUCTION_TYPE_IS_LOWER,
		INSTRUCTION_TYPE_IS_BIGGER_EQUAL,
		INSTRUCTION_TYPE_IS_LOWER_EQUAL,
		INSTRUCTION_TYPE_IS_EQUAL,
		INSTRUCTION_TYPE_IS_OVERFLOW,
		INSTRUCTION_TYPE_JUMP
	);

	type MNEMONIC_TYPE is
	(
		MNEMONIC_ADDRESS,
		MNEMONIC_INTEGER
	);

	type MNEMONIC is record
		mnemonic_type: MNEMONIC_TYPE;
		value: CPU_INTEGER_TYPE;
	end record;

	type INSTRUCTION is record
		instruction_type: INSTRUCTION_TYPE;
		integer_left: MNEMONIC;
		integer_right: MNEMONIC;
	end record;

end CPU_Package;