#ifndef neko_api_hpp
#define neko_api_hpp

#include <config.hpp>
#include <LuaJIT/lua.hpp>

struct neko;

int defineLuaAPI(neko *n, lua_State *state);

namespace api {
	// Math
	float rnd(neko *machine, float a = 1);
	float min(neko *machine, float a, float b);
	float max(neko *machine, float a, float b);
	float mid(neko *machine, float a, float b, float c);
	// Graphics
	void cls(neko *machine, u32 c = 0);
	u32 color(neko *machine, int c = 0);
	void line(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void rect(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void rectfill(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void circ(neko *machine, u32 ox = 0, u32 oy = 0, u32 r = 1, int c = -1);
	void circfill(neko *machine, u32 ox = 0, u32 oy = 0, u32 r = 1, int c = -1);
	u32 pget(neko *machine, int x = -1, int y = -1);
	void pset(neko *machine, int x = -1, int y = -1, int c = -1);
	void flip(neko *machine);
	void clip(neko *machine, int x = -1, int y = -1, int w = -1, int h = -1);
	void print(neko *machine, char *str, int px = 0, int py = 0, int c = -1);
}

#endif
