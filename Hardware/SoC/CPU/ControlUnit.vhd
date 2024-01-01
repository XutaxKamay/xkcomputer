library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity ControlUnit is
	port
	(
		reset: in std_logic;
		do_job: inout std_logic
	);
end ControlUnit;

architecture ControlUnit_Implementation of ControlUnit is

	type UNIT_STATE is
	(
		UNIT_STATE_FETCHING_INSTRUCTION,
		UNIT_STATE_EXECUTING_INSTRUCTION
	);

	component RandomAccessMemory_Read_Instruction is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			instruction_out: out INSTRUCTION;
			done_job: out std_logic
		);
	end component;

	component RandomAccessMemory_Read is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			integer_out: out CPU_INTEGER_TYPE;
			done_job: out std_logic
		);
	end component;

	component RandomAccessMemory_Write is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			integer_in: in CPU_INTEGER_TYPE;
			done_job: out std_logic
		);
	end component;

	type INSTRUCTION_FETCH is record
		address_in: CPU_INTEGER_TYPE;
		instruction_out: INSTRUCTION;
		done_job: std_logic;
	end record;

	signal instruction_signal: INSTRUCTION_FETCH;

begin
	process (do_job, reset)
		variable program_counter : CPU_INTEGER_TYPE := (others => '0');
		variable state: UNIT_STATE := UNIT_STATE_FETCHING_INSTRUCTION;
    begin
		if rising_edge(do_job) then
			-- CPU Reset --
			if reset = '1' then
				program_counter := (others => '0');
			end if;

			case state is
				-- Fetch the instruction first --
				when UNIT_STATE_FETCHING_INSTRUCTION =>
					state := UNIT_STATE_EXECUTING_INSTRUCTION;
				-- Then executes the instruction --
				when UNIT_STATE_EXECUTING_INSTRUCTION =>
					state := UNIT_STATE_FETCHING_INSTRUCTION;
			end case;

			program_counter := program_counter + 1;
			-- Signal that the job has been done --
			do_job <= '0';
		end if;
	end process;
end ControlUnit_Implementation;
