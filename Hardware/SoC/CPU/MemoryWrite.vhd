library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryWrite is
	port
	(
		address_in: in CPU_INTEGER_TYPE;
		integer_in: in CPU_INTEGER_TYPE;
		done_job: out std_logic
	);
end MemoryWrite;