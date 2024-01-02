library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryWrite is
	port
	(
		address_in: in CPU_ADDRESS_TYPE;
		value_in: in std_logic;
		done_job: out std_logic
	);
end MemoryWrite;