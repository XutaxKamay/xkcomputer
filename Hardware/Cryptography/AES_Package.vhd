library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package AES_Package is

    constant AES_INTEGER_BITS: integer := 256;
    subtype AES_256_INTEGER_TYPE is BIT_VECTOR((AES_INTEGER_BITS - 1) downto 0);

    function Encrypt256Bits
    (
        bits: AES_256_INTEGER_TYPE;
        key: AES_256_INTEGER_TYPE
    ) return AES_256_INTEGER_TYPE;

    function Decrypt256Bits
    (
        bits: AES_256_INTEGER_TYPE;
        key: AES_256_INTEGER_TYPE
    ) return AES_256_INTEGER_TYPE;

end AES_Package;

package body AES_Package is
    function Encrypt256Bits
    (
        bits: AES_256_INTEGER_TYPE;
        key: AES_256_INTEGER_TYPE
    ) return AES_256_INTEGER_TYPE
    is
    begin
        return bits;
    end Encrypt256Bits;

    function Decrypt256Bits
    (
        bits: AES_256_INTEGER_TYPE;
        key: AES_256_INTEGER_TYPE
    ) return AES_256_INTEGER_TYPE
    is
    begin
        return bits;
    end Decrypt256Bits;
end AES_Package;