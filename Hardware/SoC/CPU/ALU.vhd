library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CPU_Package.all;

entity ALU is
	port
	(
		operation_type: in ALU_OPERATION_TYPE;
		integer_in_left: in ALU_INTEGER_IN_TYPE;
		integer_in_right: in ALU_INTEGER_IN_TYPE;
		integer_out: out ALU_INTEGER_OUT_TYPE
	);
end ALU;

architecture ALU_Implementation of ALU is
begin
	process (operation_type, integer_in_left, integer_in_right)
		-- Store integer result, make it big enough for multiplication --
		variable temporary_resulting_integer : signed((MAX_INTEGER_BITS - 1) * 2 downto 0);
		variable division_by_zero : boolean := false;
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
		integer_out.value <= resize(temporary_resulting_integer, integer_out.value'length);

		if temporary_resulting_integer > ALU_INTEGER_IN_TYPE'high
			or temporary_resulting_integer < ALU_INTEGER_IN_TYPE'low
			or division_by_zero then
			integer_out.overflow <= '1';
		else
			integer_out.overflow <= '0';
		end if;
	end process;
end ALU_Implementation;
