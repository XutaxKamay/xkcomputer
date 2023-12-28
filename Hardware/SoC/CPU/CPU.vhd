library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CPU_Package is

	constant MAX_INTEGER_BITS : integer := 512;
	subtype INTEGER_IN_TYPE is signed((MAX_INTEGER_BITS - 1) downto 0);

	-- MULTIPLY is at least 2^(n*2)
	subtype INTEGER_OUT_TYPE is signed((MAX_INTEGER_BITS * 2 - 1) downto 0);
	
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
		INSTRUCTION_TYPE_READ_MEMORY,
		INSTRUCTION_TYPE_WRITE_MEMORY,
		INSTRUCTION_TYPE_IS_BIGGER,
		INSTRUCTION_TYPE_IS_LOWER,
		INSTRUCTION_TYPE_IS_BIGGER_EQUAL,
		INSTRUCTION_TYPE_IS_LOWER_EQUAL,
		INSTRUCTION_TYPE_JMP
	);

	type ALU_OPERATION_TYPE is
	(
		ALU_OPERATION_TYPE_OR,
		ALU_OPERATION_TYPE_AND,
		ALU_OPERATION_TYPE_ADD,
		ALU_OPERATION_TYPE_SUBSTRACT,
		ALU_OPERATION_TYPE_DIVISION,
		ALU_OPERATION_TYPE_MULTIPLY
	);

end CPU_Package;

use work.CPU_Package.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
	port
	(
		operation_type: in ALU_OPERATION_TYPE;
		integer_in_1: in INTEGER_IN_TYPE;
		integer_in_2: in INTEGER_IN_TYPE;
		integer_out: out INTEGER_OUT_TYPE;
		error: out bit
	);
end ALU;

architecture ALU_Implementation of ALU is
begin
	process (operation_type, integer_in_1, integer_in_2)
	begin
		case operation_type is
			when ALU_OPERATION_TYPE_ADD =>
				integer_out <= integer_in_1 + integer_in_2;
				error <= '0';
			when ALU_OPERATION_TYPE_SUBSTRACT =>
				integer_out <= integer_in_1 - integer_in_2;
				error <= '0';
			when ALU_OPERATION_TYPE_DIVISION =>
				integer_out <= integer_in_1 / integer_in_2;
				error <= '0';
			when ALU_OPERATION_TYPE_MULTIPLY =>
				integer_out <= integer_in_1 * integer_in_2;
				error <= '0';
			when ALU_OPERATION_TYPE_OR =>
				integer_out <= integer_in_1 or integer_in_2;
				error <= '0';
			when ALU_OPERATION_TYPE_AND =>
				integer_out <= integer_in_1 and integer_in_2;
				error <= '0';
			when others =>
				error <= '1';
		end case;
	end process;
end ALU_Implementation;
