library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory is
    port
    (
        commit_read_memory: inout boolean;
        commit_write_memory: inout boolean;
        memory_address_read: in CPU_ADDRESS_TYPE;
        memory_address_write: in CPU_ADDRESS_TYPE;
        memory_word_read: out MEMORY_WORD_TYPE;
        memory_word_write: in MEMORY_WORD_TYPE
    );
end Memory;

architecture Memory_Implementation of Memory is    
    signal internal_memory: BIT_VECTOR(REAL_MEMORY_END_ADDRESS downto 0);
begin
    process (commit_read_memory)
    begin
       if commit_read_memory then
            if memory_address_read + MEMORY_WORD_TYPE'length - 1 < MMIO_ADDRESS_START then
                for i in 0 to MEMORY_WORD_TYPE'length - 1 loop
                    memory_word_read(i) <= internal_memory(to_integer(memory_address_read) + i);
                end loop;
                -- ack --
                commit_read_memory <= false;
            end if;
       end if;
    end process;

    process (commit_write_memory)
    begin
       if commit_write_memory then
            if memory_address_write + MEMORY_WORD_TYPE'length - 1 < MMIO_ADDRESS_START then
                for i in 0 to MEMORY_WORD_TYPE'length - 1 loop
                    internal_memory(to_integer(memory_address_write) + i) <= memory_word_write(i);
                end loop;
                -- ack --
                commit_write_memory <= false;
            end if;
       end if;
    end process;
end Memory_Implementation;