-----------------------------------------
-- carts
-----------------------------------------

local carts = {}

function carts.load(name)
	local cart = {}

	local pureName = name
	local extensions = { "", ".n8" }

	if name:sub(-3) == ".n8" then
		extensions = { ".n8" }
		pureName = name:sub(1, -4)
	end

	local found = false

	for i = 1, #extensions do
		if love.filesystem.isFile(
			neko.currentDirectory
			.. pureName .. extensions[i]
		) then
			found = true
			name = neko.currentDirectory
				.. pureName .. extensions[i]
			break
		end
	end

	if not found then
		log.error("failed to load cart")
		if neko.core == nil then
			error("Failed to load neko.n8. Did you delete it, hacker?")
		end
		return nil
	end

	cart.name = name
	cart.pureName = pureName

	local data, size =
		love.filesystem.read(name)

	if not data then
		log.error("failed to open cart")
		return cart
	end

	-- local loadData = neko.core
	local loadData = true
	local header = "neko8 cart"

	if not data:find(header) then
		log.error("invalid cart")
		return nil
	end

	cart.code, cart.lang = carts.loadCode(data, cart)
	cart.sandbox = createSandbox(cart.lang)

	if not cart.code then
		log.error("failed to load code")
		return cart
	end

	cart.sprites = carts.loadSprites(data, cart)

	if not cart.sprites then
		log.error("failed to load sprites")
		return cart
	end

	cart.map = carts.loadMap(data, cart)

	if not cart.map then
		log.error("failed to load map")
		return cart
	end

	cart.sfx = carts.loadSFX(data, cart)

	if not cart.sfx then
		log.error("failed to load sfx")
		return cart
	end

	if loadData then
		carts.import(cart)
	end

	--
	-- possible futures:
	-- maps
	-- music
	-- sfx
	--

	love.graphics.setShader(
		colors.drawShader
	)

	neko.loadedCart = cart

	return cart
end

function carts.import(cart)
	editors.code.import(cart.code)
	editors.sprites.import(cart.sprites)
	editors.map.import(cart.map)
	editors.sfx.import(cart.sfx)
end

function carts.export()
	neko.loadedCart.code =
		editors.code.export()

	neko.loadedCart.sprites =
		editors.sprites.export()

	neko.loadedCart.map =
		editors.map.export()

	neko.loadedCart.sfx =
		editors.sfx.export()
end

function carts.create(lang)
	local cart = {}
	cart.sandbox = createSandbox()
    cart.lang = lang or "lua"
    if cart.lang == "lua" then
	    cart.code = [[
-- see https://github.com/egordorichev/neko8
-- for help

function _init()

end

function _update()

end

function _draw()
 cls()
end
]]
    elseif cart.lang == "asm" then
        cart.code = [[
section .data

section .text

extern _init
extern _update
extern _draw

init:
 ret
end

update:
 ret
end

draw:
 ret
end

mov [_init], [init]
mov [_update], [update]
mov [_draw], [draw]
]]
    end

	cart.sprites = {}
	cart.sprites.data =
		love.image.newImageData(128, 256)
	cart.sprites.sheet =
		love.graphics.newImage(cart.sprites.data)
	cart.sprites.quads = {}

	local sprite = 0

	for y = 0, 31 do
		for x = 0, 15 do
			cart.sprites.quads[sprite] =
				love.graphics.newQuad(
					8 * x, 8 * y, 8, 8, 128, 256
			)

			sprite = sprite + 1
		end
	end

	cart.sprites.flags = {}

	for i = 0, 511 do
		cart.sprites.flags[i] = 0
	end

	cart.map = {}

	for y = 0, 127 do
		cart.map[y] = {}
		for x = 0, 127 do
			cart.map[y][x] = 0
		end
	end

	return cart
end

function carts.loadCode(data, cart)
	local codeTypes = { "lua", "asm" }

	local codeType
	local codeStart

	for _, v in ipairs(codeTypes) do
		_, codeStart = data:find("\n__" .. v .. "__\n")
		if codeStart then
      codeType = v
    	break
    end
	end

	if not codeStart then
    runtimeError("Could't find a valid code section in cart")
		return
  end

	local codeEnd = data:find("\n__gfx__\n")

	local code = data:sub(
		codeStart + 1, codeEnd
	)

	return code, codeType
end

function carts.loadSprites(cdata, cart)
	local sprites = {}

	sprites.data =
		love.image.newImageData(128, 256)

	sprites.quads = {}
	sprites.flags = {}

	local _, gfxStart = cdata:find("\n__gfx__\n")
	local gfxEnd = cdata:find("\n__gff__\n")

	local data = cdata:sub(gfxStart, gfxEnd)

	local row = 0
	local col = 0
	local sprite = 0
	local shared = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line do
			-- fixme: windows fails?
			local v = line:sub(i, i)
			v = tonumber(v, 16) or 0
			sprites.data:setPixel(
				col, row, v * 16, v * 16,
				v * 16, 255
			)

			col = col + 1

			if col == 128 then
				col = 0
				row = row + 1
			end
		end

		nextLine = data:find("\n", lineEnd) + 1
	end

	for y = 0, 31 do
		for x = 0, 15 do
			sprites.quads[sprite] =
				love.graphics.newQuad(
					8 * x, 8 * y, 8, 8, 128, 256
			)

			sprite = sprite + 1
		end
	end

	if sprite ~= 512 then
		log.error("invalid sprite count: " .. sprite)
		return nil
	end

	sprites.sheet =
		love.graphics.newImage(sprites.data)

	local _, flagsStart = cdata:find("\n__gff__\n")
	local flagsEnd = cdata:find("\n__map__\n")
	local data = cdata:sub(
		flagsStart, flagsEnd
	)

	local sprite = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line, 2 do
			local v = line:sub(i, i + 1)
			v = tonumber(v, 16)
			sprites.flags[sprite] = v
			sprite = sprite + 1
		end

		nextLine = data:find("\n", lineEnd) + 1
	end

	if sprite ~= 512 then
		log.error("invalid flag count: " .. sprite)
		return nil
	end

	return sprites
end

function carts.loadMap(data, cart)
	local map = {}
	local _, mapStart = data:find("\n__map__\n")
	local mapEnd = data:find("\n__end__\n")
	data = data:sub(mapStart, mapEnd)

	for y = 0, 127 do
		map[y] = {}
		for x = 0, 127 do
			map[y][x] = 0
		end
	end

	local row = 0
	local col = 0
	local tiles = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)
		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line, 2 do
			local v = line:sub(i, i + 1)
			v = tonumber(v, 16)

			map[row][col] = v
			col = col + 1
			tiles = tiles + 1

			if col == 128 then
				col = 0
				row = row + 1
			end
		end
		nextLine = data:find("\n", lineEnd) + 1
	end

	assert(tiles == 128 * 128, "invalid map size: " .. tiles)

	return map
end

function carts.loadSFX(data, cart)
	local sfx = {}

	return sfx
end

function carts.patchLua(code)
	code = code:gsub("!=","~=")
	code = code:gsub(
		"if%s*(%b())%s*([^\n]*)\n",
		function(a,b)
			local nl = a:find("\n",nil,true)
			local th = b:find(
				"%f[%w]then%f[%W]"
			)
			local an = b:find("%f[%w]and%f[%W]")
			local o = b:find("%f[%w]or%f[%W]")
			local ce = b:find("--", nil, true)
			if not (nl or th or an or o) then
				if ce then
					local c,t = b:match(
						"(.-)(%s-%-%-.*)"
					)
					return "if " .. a:sub(2, -2)
						.." then " .. c
						.. " end" .. t .. "\n"
				else
					return "if " .. a:sub(2, -2)
					.. " then " .. b .. " end\n"
				end
			end
		end)

	code = code:gsub(
		"(%S+)%s*([%+%-%*/%%])=",
		"%1=%1%2 "
	)

	return code
end

function carts.run(cart)
	if not cart or not cart.sandbox then
		return
	end

	local name = cart.name
	if not name then
		name = "new cart"
		carts.export()
	end

	log.info(
		"running cart " .. name
	)

	local code
	if cart.lang == "lua" then
		code = cart.code
	elseif cart.lang == "asm" then
		code = try(function()
			return asm.compile(cart.code, DEBUG or false, true)
		end,
		runtimeError,
		function(result) return result end)
        if not code then
            return false
        end

		api.print(
			"successfully compiled " .. cart.pureName
		)
    else
        runtimeError("unrecognized language tag")
	end

	local ok, f, e = pcall(
		load, carts.patchLua(code), name
	)

	if not ok or f == nil then
		syntaxError(e)
		return
	end

	love.graphics.setCanvas(
		canvas.renderable
	)

	love.graphics.setShader(
		colors.drawShader
	)

	local result
	setfenv(f, cart.sandbox)
	ok, result = pcall(f)

	if not ok then
		runtimeError(result)
		return
	end

	try(function()
		if cart.sandbox._init then
			cart.sandbox._init()
		end

		if cart.sandbox._draw or
			cart.sandbox._update then
			neko.cart = cart
		end
	end, runtimeError)

	api.flip()
end

function carts.save(name)
	if not neko.loadedCart or not name then
		return false
	end

	name = name or neko.loadedCart.name
	log.info("saving " .. name)

	carts.export()

	local data = "neko8 cart\n"

	data = data .. string.format("__%s__\n", neko.loadedCart.lang)
	data = data .. neko.loadedCart.code
	data = data .. "__gfx__\n"
	data = data .. editors.sprites.exportGFX()
	data = data .. "__gff__\n"
	data = data .. editors.sprites.exportGFF()
	data = data .. "__map__\n"
	data = data .. editors.map.export()
	data = data .. "__end__\n"

	love.filesystem.write(
		name .. ".n8", data, #data
	)

	-- fixme: wrong names
	neko.loadedCart.pureName = name

	return true
end

return carts
