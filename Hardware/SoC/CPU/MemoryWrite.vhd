library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryWrite is
	port
	(
		address_in: in CPU_INTEGER_TYPE;
		bit_in: in std_logic;
		done_job: out std_logic
	);
end MemoryWrite;