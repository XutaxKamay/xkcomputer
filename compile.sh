ghdl -a -fsynopsys --workdir=work --std=08 \
	./Hardware/Cryptography/AES_Package.vhd \
	./Hardware/SoC/CPU/CentralProcessingUnit_Package.vhd \
	./Hardware/SoC/CPU/CentralProcessingUnit.vhd \
	./Hardware/SoC/Memory/MemoryController.vhd
