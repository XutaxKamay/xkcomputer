library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory_Read_Instruction is
	port
	(
		address_in: in CPU_INTEGER_TYPE;
		instruction_out: out INSTRUCTION;
		done_job: out std_logic
	);
end Memory_Read_Instruction;