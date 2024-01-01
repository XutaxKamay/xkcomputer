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

	subtype INSTRUCTION_BIT_VECTOR is std_logic_vector((INSTRUCTION_SIZE - 1) downto 0);

	-- General control unit state --
	type UNIT_STATE is
	(
		UNIT_STATE_NOT_RUNNING,
		UNIT_STATE_FETCHING_INSTRUCTION,
		UNIT_STATE_EXECUTING_INSTRUCTION
	);

	type BIT_READ is record
		address_in: CPU_INTEGER_TYPE;
		bit_out: std_logic;
		done_job: std_logic;
	end record;

	type BIT_WRITE is record
		address_in: CPU_INTEGER_TYPE;
		bit_in: std_logic;
		done_job: std_logic;
	end record;

	component MemoryRead is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			bit_out: out std_logic;
			done_job: out std_logic
		);
	end component;

	component MemoryWrite is
		port
		(
			address_in: in CPU_INTEGER_TYPE;
			bit_in: in std_logic;
			done_job: out std_logic
		);
	end component;

	function DecodeInstruction
	(
		instruction_in_bits: INSTRUCTION_BIT_VECTOR
	) return INSTRUCTION is

	variable decoded_instruction: INSTRUCTION;
	variable count_bits: integer := 0;
	begin
		decoded_instruction.mnemonic_type := instruction_in_bits((MNEMONIC_TYPE_SIZE - 1) + count_bits downto count_bits);
		count_bits := count_bits + MNEMONIC_TYPE_SIZE;

		decoded_instruction.operand_left.kind := instruction_in_bits((OPERAND_TYPE_SIZE - 1) + count_bits downto count_bits);
		count_bits := count_bits + OPERAND_TYPE_SIZE;

		decoded_instruction.operand_left.value := CPU_INTEGER_TYPE(instruction_in_bits((CPU_INTEGER_TYPE_SIZE - 1) + count_bits downto count_bits));
		count_bits := count_bits + CPU_INTEGER_TYPE_SIZE;

		decoded_instruction.operand_right.kind := instruction_in_bits((OPERAND_TYPE_SIZE - 1) + count_bits downto count_bits);
		count_bits := count_bits + OPERAND_TYPE_SIZE;

		decoded_instruction.operand_right.value := CPU_INTEGER_TYPE(instruction_in_bits((CPU_INTEGER_TYPE_SIZE - 1) + count_bits downto count_bits));
		count_bits := count_bits + CPU_INTEGER_TYPE_SIZE;

		return decoded_instruction;
	end DecodeInstruction;

	procedure HandleInstruction
	(
		decoded_instruction: in INSTRUCTION;
		signal_bit_read: inout BIT_READ;
		signal_bit_write: inout BIT_WRITE
	) is
	begin
		case decoded_instruction.mnemonic_type is
			when MNEMONIC_TYPE_SET =>
			when MNEMONIC_TYPE_OR => 
			when MNEMONIC_TYPE_AND =>
			when MNEMONIC_TYPE_NOT =>
			when MNEMONIC_TYPE_ADD =>
			when MNEMONIC_TYPE_SUBSTRACT =>
			when MNEMONIC_TYPE_DIVISION => 
			when MNEMONIC_TYPE_MULTIPLY => 
			when MNEMONIC_TYPE_READ_INTEGER => 
			when MNEMONIC_TYPE_WRITE_INTEGER =>
			when MNEMONIC_TYPE_IS_BIGGER => 
			when MNEMONIC_TYPE_IS_LOWER => 
			when MNEMONIC_TYPE_IS_EQUAL =>
			when MNEMONIC_TYPE_HAD_OVERFLOW =>
			when MNEMONIC_TYPE_JUMP =>
		end case;
	end procedure;

	signal signal_bit_read: BIT_READ;
	signal signal_bit_write: BIT_WRITE;
	signal signal_unit_state: UNIT_STATE := UNIT_STATE_NOT_RUNNING;

begin
	MemoryReadInstance: MemoryRead port map
	(
		address_in => signal_bit_read.address_in,
		bit_out => signal_bit_read.bit_out,
		done_job => signal_bit_read.done_job
	);

	MemoryWriteInstance: MemoryWrite port map
	(
		address_in => signal_bit_write.address_in,
		bit_in => signal_bit_write.bit_in,
		done_job => signal_bit_write.done_job
	);

	-- Handle control unit and reset --
	process (reset, signal_unit_state)
		variable var_program_counter: CPU_INTEGER_TYPE := (others => '0');
		variable var_decoded_instruction: INSTRUCTION;
		variable var_instruction_fetched: INSTRUCTION_BIT_VECTOR;
		variable var_overflow_flag: std_logic := '0'; 
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

					-- Fetch instruction from memory --
					for i in 0 to INSTRUCTION_SIZE loop
						signal_bit_read.done_job <= '0';
						signal_bit_read.address_in <= var_program_counter;
						var_program_counter := var_program_counter + 1;
						wait until signal_bit_read.done_job;
						var_instruction_fetched(i) := signal_bit_read.bit_out;
					end loop;

					-- Decode instruction --
					var_decoded_instruction := DecodeInstruction(var_instruction_fetched);

					-- Handle instruction --
					HandleInstruction(var_decoded_instruction, signal_bit_read, signal_bit_write);

					signal_unit_state <= UNIT_STATE_EXECUTING_INSTRUCTION;
				-- Then executes the instruction --
				when UNIT_STATE_EXECUTING_INSTRUCTION =>
				-- TODO: ... case instruction_fetched. --
			end case;
		end if;
	end process;

end ControlUnit_Implementation;
