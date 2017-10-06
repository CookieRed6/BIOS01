#include <api.hpp>
#include <ram.hpp>

#include <iostream>
#include <vector>

#define GET_COLOR peek(machine, DRAW_START)

neko *machine; // Lil hack :P

static int rnd(lua_State *state) {
	s32 n = luaL_optint(state, 1, 1);
	lua_pushinteger(state, api::rnd(machine, n));

	return 1;
}

static int min(lua_State *state) {
	float a = luaL_optnumber(state, 1, 0);
	float b = luaL_optnumber(state, 2, 0);

	lua_pushnumber(state, api::min(machine, a, b));

	return 1;
}

static int max(lua_State *state) {
	float a = luaL_optnumber(state, 1, 0);
	float b = luaL_optnumber(state, 2, 0);

	lua_pushnumber(state, api::max(machine, a, b));

	return 1;
}

static int mid(lua_State *state) {
	float a = luaL_optnumber(state, 1, 0);
	float b = luaL_optnumber(state, 2, 0);
	float c = luaL_optnumber(state, 3, 0);

	lua_pushnumber(state, api::mid(machine, a, b, c));

	return 1;
}

static int cls(lua_State *state) {
	api::cls(machine, luaL_checkinteger(state, 1));
	return 0;
}

static int pset(lua_State *state) {
	s32 x = luaL_optint(state, 1, 0);
	s32 y = luaL_optint(state, 2, 0);
	s32 c = luaL_optint(state, 3, GET_COLOR);

	api::pset(machine, x, y, c);

	return 0;
}

static int pget(lua_State *state) {
	s32 x = luaL_optint(state, 1, 0);
	s32 y = luaL_optint(state, 2, 0);

	lua_pushnumber(state, api::pget(machine, x, y));

	return 1;
}

static int circ(lua_State *state) {
	s32 x = luaL_optint(state, 1, 0);
	s32 y = luaL_optint(state, 2, 0);
	s32 r = luaL_optint(state, 3, 1);
	s32 c = luaL_optint(state, 4, GET_COLOR);

	api::circ(machine, x, y, r, c);

	return 0;
}

static int circfill(lua_State *state) {
	s32 x = luaL_optint(state, 1, 0);
	s32 y = luaL_optint(state, 2, 0);
	s32 r = luaL_optint(state, 3, 1);
	s32 c = luaL_optint(state, 4, GET_COLOR);

	api::circfill(machine, x, y, r, c);

	return 0;
}

static int rect(lua_State *state) {
	s32 x0 = luaL_optint(state, 1, 0);
	s32 y0 = luaL_optint(state, 2, 0);
	s32 x1 = luaL_optint(state, 3, 1);
	s32 y1 = luaL_optint(state, 4, 1);
	s32 c = luaL_optint(state, 5, GET_COLOR);

	api::rect(machine, x0, y0, x1, y1, c);

	return 0;
}

static int rectfill(lua_State *state) {
	s32 x0 = luaL_optint(state, 1, 0);
	s32 y0 = luaL_optint(state, 2, 0);
	s32 x1 = luaL_optint(state, 3, 1);
	s32 y1 = luaL_optint(state, 4, 1);
	s32 c = luaL_optint(state, 5, GET_COLOR);

	api::rectfill(machine, x0, y0, x1, y1, c);

	return 0;
}

static int line(lua_State *state) {
	s32 x0 = luaL_optint(state, 1, 0);
	s32 y0 = luaL_optint(state, 2, 0);
	s32 x1 = luaL_optint(state, 3, 1);
	s32 y1 = luaL_optint(state, 4, 1);
	s32 c = luaL_optint(state, 5, GET_COLOR);

	api::line(machine, x0, y0, x1, y1, c);

	return 0;
}

static int color(lua_State *state) {
	s32 c = luaL_optint(state, 1, -1);
	lua_pushinteger(state, api::color(machine, c));

	return 1;
}

static int flip(lua_State *state) {
	api::flip(machine);
	return 0;
}

static int clip(lua_State *state) {
	s32 x = luaL_optint(state, 1, 0);
	s32 y = luaL_optint(state, 2, 0);
	s32 w = luaL_optint(state, 3, NEKO_W);
	s32 h = luaL_optint(state, 4, NEKO_H);

	api::clip(machine, x, y, w, h);

	return 0;
}

std::vector<luaL_Reg> luaAPI = {
	{ "rnd", rnd },
	{ "min", min },
	{ "max", max },
	{ "mid", mid },

	{ "cls", cls },
	{ "pset", pset },
	{ "pget", pget },
	{ "circ", circ },
	{ "circfill", circfill },
	{ "rect", rect },
	{ "rectfill", rectfill },
	{ "line", line },
	{ "color", color },
	{ "clip", clip },
};

LUALIB_API int defineLuaAPI(neko *n, lua_State *state) {
	machine = n;

	for (auto fn : luaAPI) {
		lua_pushcfunction(state, fn.func);
		lua_setglobal(state, fn.name);
	}

	return 1;
}