library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity MemoryController is
    port
    (
        commit_read_memory: inout boolean;
        commit_write_memory: inout boolean;
        memory_address_read: in CPU_ADDRESS_TYPE;
        memory_address_write: in CPU_ADDRESS_TYPE;
        memory_word_read: out WORD_TYPE;
        memory_word_write: in WORD_TYPE
    );
end MemoryController;

architecture MemoryController_Implementation of MemoryController is
    ----------------------------------------
    -- I don't think we're going to reach --
    -- 2^512 bits of bit address space    --
    ----------------------------------------
    constant REAL_MEMORY_END_ADDRESS: integer := 2**20 - 1;
    -- Will be used for I/O devices --
    constant MMIO_ADDRESS_START: integer := REAL_MEMORY_END_ADDRESS + 1;

    signal internal_memory: BIT_VECTOR(REAL_MEMORY_END_ADDRESS downto 0) := (others => '0');
begin
    process (commit_read_memory)
    begin
       if commit_read_memory then
            if memory_address_read + WORD_SIZE - 1 < MMIO_ADDRESS_START then
                for i in 0 to WORD_SIZE - 1 loop
                    memory_word_read(i) <= internal_memory(to_integer(memory_address_read) + i);
                end loop;
            end if;
            -- ack --
            commit_read_memory <= false;
       end if;
    end process;

    process (commit_write_memory)
    begin
       if commit_write_memory then
            if memory_address_write + WORD_SIZE - 1 < MMIO_ADDRESS_START then
                for i in 0 to WORD_SIZE - 1 loop
                    internal_memory(to_integer(memory_address_write) + i) <= memory_word_write(i);
                end loop;
            end if;
            -- ack --
            commit_write_memory <= false;
       end if;
    end process;
end MemoryController_Implementation;