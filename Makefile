CROSS_COMPILE ?= arm-linux-gnueabihf-

all: startup.s
	$(CROSS_COMPILE)as startup.s -o startup.o
	$(CROSS_COMPILE)ld -o startup -T memmap startup.o
	$(CROSS_COMPILE)objcopy startup startup.bin -O binary
	cp startup.bin /tftpboot/startup.bin

clean:
	rm *.o *.bin *.lst
