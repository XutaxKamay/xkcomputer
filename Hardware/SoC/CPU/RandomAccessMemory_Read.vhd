library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity RandomAccessMemory_Read is
	port
	(
		address_in: in CPU_INTEGER_TYPE;
		integer_out: out CPU_INTEGER_TYPE;
		done_job: out std_logic
	);
end RandomAccessMemory_Read;