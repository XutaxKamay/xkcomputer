library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://crypto.stackexchange.com/questions/16186/is-tea-considered-secure/16193#16193 --
-- Should be secure if used carefully --

package TinyEncryptionAlgorithm is

    subtype TEA_INTEGER_TYPE is unsigned(31 downto 0);
    type TEA_INTEGERS_TYPE is array(0 to 1) of TEA_INTEGER_TYPE;
    type TEA_KEY_TYPE is array(0 to 3) of TEA_INTEGER_TYPE;

    constant MAGIC_DELTA_NUMBER: TEA_INTEGER_TYPE := x"9E3779B9";

    procedure TEAEncrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers: inout TEA_INTEGERS_TYPE
    );

    procedure TEADecrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers: inout TEA_INTEGERS_TYPE
    );

    procedure TEAEncrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers_bit_vec: inout BIT_VECTOR(63 downto 0)
    );

    procedure TEADecrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers_bit_vec: inout BIT_VECTOR(63 downto 0)
    );

end TinyEncryptionAlgorithm;

package body TinyEncryptionAlgorithm is

    procedure TEAEncrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers: inout TEA_INTEGERS_TYPE
    ) is
        variable v0: TEA_INTEGER_TYPE := tea_integers(0);
        variable v1: TEA_INTEGER_TYPE := tea_integers(1);
        variable sum: TEA_INTEGER_TYPE := (others => '0');
        variable k0: TEA_INTEGER_TYPE := tea_key(0);
        variable k1: TEA_INTEGER_TYPE := tea_key(1);
        variable k2: TEA_INTEGER_TYPE := tea_key(2);
        variable k3: TEA_INTEGER_TYPE := tea_key(3);
    begin
        for i in 0 to TEA_INTEGER_TYPE'length - 1 loop
            sum := sum + MAGIC_DELTA_NUMBER;
            v0 := v0 + ((shift_left(v1, 4) + k0) xor (v1 + sum) xor (shift_right(v1, 5) + k1));
            v1 := v0 + ((shift_left(v1, 4) + k2) xor (v0 + sum) xor (shift_right(v0, 5) + k3));
        end loop;
    end;

    procedure TEADecrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers: inout TEA_INTEGERS_TYPE
    ) is
        variable v0: TEA_INTEGER_TYPE := tea_integers(0);
        variable v1: TEA_INTEGER_TYPE := tea_integers(1);
        variable sum: TEA_INTEGER_TYPE := x"C6EF3720";
        variable k0: TEA_INTEGER_TYPE := tea_key(0);
        variable k1: TEA_INTEGER_TYPE := tea_key(1);
        variable k2: TEA_INTEGER_TYPE := tea_key(2);
        variable k3: TEA_INTEGER_TYPE := tea_key(3);
    begin
        for i in 0 to TEA_INTEGER_TYPE'length - 1 loop
            v1 := v0 - ((shift_left(v1, 4) + k2) xor (v0 + sum) xor (shift_right(v0, 5) + k3));
            v0 := v0 - ((shift_left(v1, 4) + k0) xor (v1 + sum) xor (shift_right(v1, 5) + k1));
            sum := sum - MAGIC_DELTA_NUMBER;
        end loop;
    end;

    procedure TEAEncrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers_bit_vec: inout BIT_VECTOR(63 downto 0)
    ) is
        variable tea_integers: TEA_INTEGERS_TYPE := 
        (
            TEA_INTEGER_TYPE(to_stdlogicvector(tea_integers_bit_vec(31 downto 0))),
            TEA_INTEGER_TYPE(to_stdlogicvector(tea_integers_bit_vec(63 downto 32)))
        );
    begin
        TEAEncrypt(tea_key, tea_integers);

        tea_integers_bit_vec(31 downto 0) := to_bitvector(std_logic_vector(tea_integers(0)));
        tea_integers_bit_vec(63 downto 32) := to_bitvector(std_logic_vector(tea_integers(1)));
    end;

    procedure TEADecrypt
    (
        tea_key: in TEA_KEY_TYPE; 
        tea_integers_bit_vec: inout BIT_VECTOR(63 downto 0)
    ) is
        variable tea_integers: TEA_INTEGERS_TYPE := 
        (
            TEA_INTEGER_TYPE(to_stdlogicvector(tea_integers_bit_vec(31 downto 0))),
            TEA_INTEGER_TYPE(to_stdlogicvector(tea_integers_bit_vec(63 downto 32)))
        );
    begin
        TEAEncrypt(tea_key, tea_integers);

        tea_integers_bit_vec(31 downto 0) := to_bitvector(std_logic_vector(tea_integers(0)));
        tea_integers_bit_vec(63 downto 32) := to_bitvector(std_logic_vector(tea_integers(1)));
    end;

end TinyEncryptionAlgorithm;