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

	type INTEGER_FETCH is record
		address_in: CPU_INTEGER_TYPE;
		integer_out: INTEGER;
		done_job: std_logic;
	end record;

	signal instruction_fetch_signal: INSTRUCTION_FETCH;
	signal unit_state_signal: UNIT_STATE := UNIT_STATE_NOT_RUNNING;
	signal executing_state_signal: EXECUTING_STATE := EXECUTING_NORMAL_OPERATIONS;

begin

	ram_read_instruction: RandomAccessMemory_Read_Instruction
		port map 
		(
			address_in => instruction_fetch_signal.address_in,
			instruction_out => instruction_fetch_signal.instruction_out,
			done_job => instruction_fetch_signal.done_job
		);

	-- Global process to handle instantiation of components --
	process (reset, unit_state_signal)
		variable program_counter: CPU_INTEGER_TYPE := (others => '0');
		variable instruction_fetched: INSTRUCTION;
    begin
		-- Reset has been raised --
		if rising_edge(reset) then

			-- CPU Reset --
			program_counter := (others => '0');
			-- Will trigger again a new process execution --
			unit_state_signal <= UNIT_STATE_NOT_RUNNING;
			executing_state_signal <= EXECUTING_NORMAL_OPERATIONS;
			instruction_fetch_signal.done_job <= '0';

		else

			case unit_state_signal is
				-- Always start by fetching --
				when UNIT_STATE_NOT_RUNNING =>
					unit_state_signal <= UNIT_STATE_FETCHING_INSTRUCTION;
				-- Fetch the instruction first --
				when UNIT_STATE_FETCHING_INSTRUCTION =>
					instruction_fetch_signal.address_in <= program_counter;
					program_counter := program_counter + 1;
				-- Then executes the instruction --
				when UNIT_STATE_EXECUTING_INSTRUCTION =>
					instruction_fetched := instruction_fetch_signal.instruction_out;
					-- TODO: ... case instruction_fetched. -
			end case;

		end if;
	end process;

	-- Handle fetch instruction --
	process (instruction_fetch_signal.done_job)
	begin
		-- As soon we are done, signal again the global process --
		-- that we need to execute the instruction fetched --
		unit_state_signal <= UNIT_STATE_EXECUTING_INSTRUCTION;
	end process;

end ControlUnit_Implementation;
