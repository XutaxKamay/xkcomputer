library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Maths_Package is

    function IntegerMax
    (
        size1: integer;
        size2: integer
    ) return integer;

end Maths_Package;

package body Maths_Package is
    
    function IntegerMax
    (
        size1: integer;
        size2: integer
    ) return integer is
    begin
        if (size1 > size2) then
            return size1;
        else
            return size2;
        end if;
    end;

end Maths_Package;