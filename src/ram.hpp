#ifndef neko_ram_hpp
#define neko_ram_hpp

#include <config.hpp>

// Video memory
#define VRAM_START 0x0
#define VRAM_SIZE 0x3800
#define VRAM_END (VRAM_START + VRAM_SIZE)

// Sprite memory
#define SPRITE_START VRAM_END
#define SPRITE_SIZE 0x8000
#define SPRITE_END (SPRITE_START + SPRITE_SIZE)

// Map memory
#define MAP_START SPRITE_END
#define MAP_SIZE 0x4000
#define MAP_END (MAP_START + MAP_SIZE)

// Sprite flags memory
#define FLAGS_START MAP_END
#define FLAGS_SIZE 0x0200
#define FLAGS_END (FLAGS_START + FLAGS_SIZE)

// Sfx memory
#define SFX_START FLAGS_END
#define SFX_SIZE 0x10FF
#define SFX_END (SFX_START + SFX_SIZE)

// Music memory
#define MUSIC_START SFX_END
#define MUSIC_SIZE 0x00FF
#define MUSIC_END (MUSIC_START + MUSIC_SIZE)

// Persistent data memory
#define PERSISTENT_START MUSIC_END
#define PERSISTENT_SIZE 0x00FF
#define PERSISTENT_END (PERSISTENT_START + PERSISTENT_SIZE)

// Draw state memory
#define DRAW_START PERSISTENT_END
#define DRAW_SIZE 0x00FF
#define DRAW_END (DRAW_START + DRAW_SIZE)

// Other memory
#define OTHER_START DRAW_END
#define OTHER_SIZE 0x00FF
#define OTHER_END (OTHER_START + OTHER_SIZE)

/*
 * Other memory layout:
 * 0x0000 - pen color (1 byte)
 * 0x0001 - camera position (2 bytes)
 * 0x0003 - cursor position (2 bytes)
 * 0x0005 - clip rect (4 bytes)
 * 0x0009 - palette (48 bytes)
 * 0x0039 - palette mapping (8 bytes)
 */

// Total memory size
#define RAM_SIZE (VRAM_SIZE + SPRITE_END + MAP_SIZE \
	+ FLAGS_SIZE + MUSIC_SIZE + PERSISTENT_SIZE + DRAW_SIZE + OTHER_SIZE)

typedef struct neko_ram {
	// The actual memory
	byte *string;
} neko_ram;

struct neko;

// Basic memory operations
void memcpy(neko *machine, unsigned int destination, unsigned int src, unsigned int len);
void memset(neko *machine, unsigned int destination, byte value, unsigned int len);
byte peek(neko *machine, unsigned int address);
byte peek4(neko *machine, unsigned int address);
void poke(neko *machine, unsigned int address, byte value);
void poke4(neko *machine, unsigned int address, byte value);

namespace ram {
	// Creates RAM instance
	neko_ram *init(neko *machine);
};

#endif