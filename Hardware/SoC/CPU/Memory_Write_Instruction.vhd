library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory_Write_Instruction is
	port
	(
		address_in: in CPU_INTEGER_TYPE;
		instruction_in: in INSTRUCTION;
		done_job: out std_logic
	);
end Memory_Write_Instruction;