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
        memory_word_read: out WORD_TYPE;
        memory_word_write: in WORD_TYPE
    );
end Memory;

architecture Memory_Implementation of Memory is
    constant MEMORY_SIZE: integer := 2**20;

    signal internal_memory: BIT_VECTOR(MEMORY_SIZE - 1 downto 0) := (others => '0');
begin
    process (commit_read_memory)
        variable address: integer;
    begin
       if commit_read_memory then
            if memory_address_read + WORD_SIZE - 1 < MEMORY_SIZE then
                address := to_integer(memory_address_read);
                memory_word_read <= internal_memory(address + WORD_SIZE - 1 downto address);
            end if;
            -- ack --
            commit_read_memory <= false;
       end if;
    end process;

    process (commit_write_memory)
        variable address: integer;
    begin
       if commit_write_memory then
            if memory_address_write + WORD_SIZE - 1 < MEMORY_SIZE then
                address := to_integer(memory_address_write);
                internal_memory(address + WORD_SIZE - 1 downto address) <= memory_word_write;
            end if;
            -- ack --
            commit_write_memory <= false;
       end if;
    end process;
end Memory_Implementation;