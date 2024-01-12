library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CentralProcessingUnit_Package.all;

entity Memory is
    port
    (
        commit_read_memory: inout boolean;
        commit_write_memory: inout boolean;
        memory_size_read: in MEMORY_INTEGER_SIZE_TYPE;
        memory_size_write: in MEMORY_INTEGER_SIZE_TYPE;
        memory_address_read: in CPU_ADDRESS_TYPE;
        memory_address_write: in CPU_ADDRESS_TYPE;
        memory_data_read: out MEMORY_BIT_VECTOR;
        memory_data_write: in MEMORY_BIT_VECTOR
    );
end Memory;

architecture Memory_Implementation of Memory is
    constant REAL_MEMORY_END_ADDRESS: integer := 2**20 - 1;
    -- Will be used for I/O devices --
    constant MMIO_ADDRESS_START: integer := REAL_MEMORY_END_ADDRESS + 1;
    
    signal internal_memory: BIT_VECTOR(REAL_MEMORY_END_ADDRESS downto 0);
begin
    process(commit_read_memory)
    begin
       if commit_read_memory then
            memory_data_read((memory_size_read - 1) downto 0) 
                <= internal_memory((to_integer(memory_address_read) + memory_size_read - 1) downto 0);
            -- ack --
            commit_read_memory <= false;
       end if;
    end process;

    process(commit_write_memory)
    begin
       if commit_write_memory then
            internal_memory((to_integer(memory_address_write) + memory_size_write - 1) downto 0)
                <= memory_data_write((memory_size_write - 1) downto 0);
            -- ack --
            commit_write_memory <= false;
       end if;
    end process;
end Memory_Implementation;