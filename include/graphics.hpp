#ifndef neko_graphics_hpp
#define neko_graphics_hpp

#include <SDL2/SDL.h>
#include "config.hpp"

typedef struct neko_graphics {
	SDL_Window *window;
	SDL_Renderer *renderer;
	SDL_Texture *buffer;
	u16 scale;
	u16 x;
	u16 y;
} neko_graphics;

struct neko;

namespace graphics {
	neko_graphics *init(neko *machine);
	void clean(neko_graphics *graphics);
}

#endif
