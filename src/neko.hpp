#ifndef neko_hpp
#define neko_hpp

#include <config.hpp>
#include <ram.hpp>
#include <carts.hpp>
#include <graphics.hpp>
#include <fs.hpp>

typedef enum neko_state {
	STATE_CONSOLE,
	STATE_CODE_EDITOR,
	STATE_RUNNING_CART
} neko_state;

typedef struct neko {
	neko_ram *ram;
	neko_graphics *graphics;
	neko_carts *carts;
	neko_state state;
	neko_state prevState;
	neko_config *config;
	neko_fs *fs;
} neko;

namespace machine {
	neko *init(neko_config *config);
	void free(neko *machine);
	void render(neko *machine);
};

#endif