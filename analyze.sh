ghdl -a -Wall --warn-delayed-checks -fsynopsys --workdir=work/ghdl --std=08 \
	./Hardware/VHDL/Cryptography/TEA_Package.vhd \
	./Hardware/VHDL/Maths/Maths_Package.vhd \
	./Hardware/VHDL/SoC/CPU/CentralProcessingUnit_Package.vhd \
	./Hardware/VHDL/SoC/CPU/CentralProcessingUnit.vhd \
	./Hardware/VHDL/SoC/TestBench/CentralProcessingUnit_TestBench.vhd 
