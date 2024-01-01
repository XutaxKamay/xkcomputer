library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity ControlUnit is
	port
	(
		reset: in std_logic
	);
end ControlUnit;

architecture ControlUnit_Implementation of ControlUnit is

	-- General control unit state --
	type UNIT_STATE is
	(
		UNIT_STATE_NOT_RUNNING,
		UNIT_STATE_FETCHING_INSTRUCTION,
		UNIT_STATE_EXECUTING_INSTRUCTION
	);

	-- Control unit sub-state during instruction execution --
	type EXECUTING_STATE is
	(
		EXECUTING_NORMAL_OPERATIONS,
		EXECUTING_READING_INTEGER,
		EXECUTING_WRITING_INTEGER
	);

	component MemoryRead is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			integer_out: out CPU_INTEGER_TYPE;
			done_job: out std_logic
		);
	end component;

	component MemoryWrite is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			integer_in: in CPU_INTEGER_TYPE;
			done_job: out std_logic
		);
	end component;

	type INTEGER_READ is record
		address_in: CPU_INTEGER_TYPE;
		integer_out: INTEGER;
		done_job: std_logic;
	end record;

	type INTEGER_WRITE is record
		address_in: CPU_INTEGER_TYPE;
		integer_in: INTEGER;
		done_job: std_logic;
	end record;

	signal signal_integer_read: INTEGER_READ;
	signal signal_integer_write: INTEGER_WRITE;
	signal signal_unit_state: UNIT_STATE := UNIT_STATE_NOT_RUNNING;

begin
	-- Handle control unit and reset --
	process (reset, signal_unit_state)
		variable var_executing_state: EXECUTING_STATE := EXECUTING_NORMAL_OPERATIONS;
		variable var_program_counter: CPU_INTEGER_TYPE := (others => '0');
		variable var_instruction: INSTRUCTION;
    begin
		-- Reset has been raised --
		if rising_edge(reset) then
			-- CPU Reset --
			var_program_counter := (others => '0');
			-- Will trigger again a new process execution --
			signal_unit_state <= UNIT_STATE_NOT_RUNNING;
		else
			case signal_unit_state is
				-- Always start by fetching --
				when UNIT_STATE_NOT_RUNNING =>
					signal_unit_state <= UNIT_STATE_FETCHING_INSTRUCTION;
				-- Fetch the instruction first --
				when UNIT_STATE_FETCHING_INSTRUCTION =>

					var_program_counter := var_program_counter + 1;
					signal_unit_state <= UNIT_STATE_EXECUTING_INSTRUCTION;
				-- Then executes the instruction --
				when UNIT_STATE_EXECUTING_INSTRUCTION =>
					-- TODO: ... case instruction_fetched. --
			end case;
		end if;
	end process;

end ControlUnit_Implementation;
