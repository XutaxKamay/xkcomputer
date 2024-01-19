ghdl -a -fsynopsys --workdir=work/ghdl --std=08 \
	./Hardware/Cryptography/TEA_Package.vhd \
	./Hardware/SoC/CPU/CentralProcessingUnit_Package.vhd \
	./Hardware/SoC/CPU/CentralProcessingUnit.vhd \
	./Hardware/SoC/Memory/Memory.vhd
