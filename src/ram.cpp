#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

void memcpy(unsigned int destination, unsigned int src, unsigned int len) {
	if (destination < 0 || destination > RAM_SIZE - 1
			|| src < 0 || src > RAM_SIZE - 1) {
		return;
	}

	for (unsigned int i = 0; (i < len && src + i < RAM_SIZE
			&& destination + i < RAM_SIZE); i++) {
		machine.ram->string[destination + i] = machine.ram->string[src + i];
	}
}

void memset(unsigned int destination, byte value, unsigned int len) {
	if (destination < 0 || destination > RAM_SIZE - 1) {
		return;
	}

	for (unsigned int i = 0; (i < len && destination + i < RAM_SIZE); i++) {
		machine.ram->string[destination + i] = value;
	}
}

byte peek(unsigned int address) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return 0;
	}

	return machine.ram->string[address];
}

byte peek4(unsigned int address) {
	if (address < 0 || address > RAM_SIZE * 2 - 1) {
		return 0;
	}

	byte value = machine.ram->string[address / 2];

	if (address % 2 == 0) {
		return value >> 4;
	} else {
		return value & (byte) 0x0F;
	}
}

void poke(unsigned int address, byte value) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return;
	}

	machine.ram->string[address] = value;
}

void poke4(unsigned int address, byte value) {
	if (address < 0 || address > RAM_SIZE * 2 - 1) {
		return;
	}

	byte b = machine.ram->string[address / 2];

	if (address % 2 == 0) {
		b = b & (byte) 0x0F;
		value = value << 4;
		b = b | value;
	} else {
		b = b & (byte) 0xF0;
		b = b | value;
	}

	machine.ram->string[address / 2] = b;
}

neko_ram *initRAM() {
	neko_ram *ram = new neko_ram;
	ram->string = (byte *) malloc(RAM_SIZE * sizeof(byte));

	// Poke data into memory
	machine.ram = ram; // Lil hack

	poke(OTHER_START, 0); // Pen color
	poke(OTHER_START + 0x0001, 0); // Camera X
	poke(OTHER_START + 0x0002, 0); // Camera Y
	poke(OTHER_START + 0x0003, 0); // Cursor X
	poke(OTHER_START + 0x0004, 0); // Cursor Y
	poke(OTHER_START + 0x0005, 0); // Clip X
	poke(OTHER_START + 0x0006, 0); // Clip Y
	poke(OTHER_START + 0x0007, machine.config->canvasWidth); // Clip W
	poke(OTHER_START + 0x0008, machine.config->canvasHeight); // Clip H

	// Palette
	for (unsigned int i = 0; i < 15; i++) {
		for (unsigned int j = 0; j < 3; j++) {
			poke(OTHER_START + 0x0009 + i * 3 + j, machine.config->palette[i][j]);
		}

		// Color mapping
		poke(OTHER_START + 0x0039 + i, i);
	}

	return ram;
}
