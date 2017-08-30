local sprites = {}
local editors = require "editors"

function sprites.init()
	sprites.color = 7
	sprites.sprite = 0
	sprites.page = 0
	sprites.scale = 1
end

function sprites.open()
	sprites.forceDraw = true
end

function sprites.close()

end

function sprites._draw()
	if sprites.forceDraw then
		sprites.redraw()
		sprites.forceDraw = false
	end
end

function sprites.redraw()
	api.cls(config.editors.sprites.bg)

	-- sprite space
	api.brectfill(3, 10, 64, 64, 0)

	api.sspr(
		sprites.sprite % 16 * 8,
		sprites.page * 32 + api.flr(sprites.sprite / 16) * 8,
		8 * sprites.scale, 8 * sprites.scale,
		3, 10, 64, 64
	)

	api.brect(3, 10, 64, 64, 0)

	-- palette
	for x = 0, 3 do
		for y = 0, 3 do
			local c = x + y * 4
			api.brectfill(
				71 + x * 12, 10 + y * 12,
				12, 12, c
			)
		end
	end

	api.brect(71, 10, 48, 48, 0)

	-- current color

	local x = sprites.color % 4
	local y = api.flr(sprites.color / 4)

	api.brect(
		71 + x * 12, 10 + y * 12,
		12, 12, 0
	)

	api.brect(
		70 + x * 12, 9 + y * 12,
		14, 14, 7
	)

	-- sprite select

	api.brectfill(
		3, 78, 13,
		7, 6
	)

	api.print(
		string.format(
			"%03d", sprites.sprite
		), 4, 79, 13
	)

	-- page buttons

	for i = 0, 7 do
		api.brectfill(
			19 + i * 8, 80, 7,
			8, 6
		)

		api.line(
			19 + i * 8, 88, 26 + i * 8, 88, 13
		)

		api.print(
			i, 21 + i * 8, 81, 13
		)
	end

	-- sprite flags
	for i = 0, 7 do
	local f = sprites.data.flags[sprites.sprite]
		local c =	bit.band(bit.rshift(f, i), 1) == 1
			and i + 8 or 0

		api.circfill(74 + i * 6, 65, 2, c)
		api.circ(74 + i * 6, 65, 2, 0)
	end

	-- sprites
	api.brectfill(
		0, 88, 129,
		33, 0
	)

	api.sspr(
		0, sprites.page * 32,
		128, 32, 0, 89
	)

	-- current sprite
	x = sprites.sprite % 16
	y = api.flr(sprites.sprite / 16)

	api.brect(
		x * 8, 89 + y * 8,
		8 * sprites.scale, 8 * sprites.scale, 0
	)

	api.brect(
		-1 + x * 8, 88 + y * 8,
		8 * sprites.scale + 2, 8 * sprites.scale + 2, 7
	)

	editors.drawUI()
	neko.cart = nil -- see spr and sspr
end

local function flip(byte, b)
  b = 2 ^ b
  return bit.bxor(byte, b)
end

function sprites._update()
	lmb = mb
	mx, my, mb = api.mstat(1)

	if mb then
		if mx >= 0 and mx <= 128
			and my >= 88 and my <= 88 + 32 then

			my = my - 88
			sprites.sprite = api.flr(mx / 8)
				+ api.flr(my / 8) * 16

			sprites.forceDraw = true
		elseif mx >= 3 and mx <= 67
			and my >= 10 and my <= 74 then

			mx = api.flr((mx - 3) / (8 * sprites.scale))
			my = api.flr((my - 10) / (8 * sprites.scale))

			local v = sprites.color * 16

			sprites.data.data:setPixel(
				mx + sprites.sprite % 16 * 8,
				my + api.flr(sprites.sprite / 16) * 8,
				v, v, v
			)

			sprites.data.sheet:refresh()
			sprites.forceDraw = true
		elseif mx >= 71 and mx <= 119 and
			my >= 10 and my <= 58 then

			mx = api.flr((mx - 71) / 12)
			my = api.flr((my - 10) / 12)

			sprites.color = mx + my * 4
			sprites.forceDraw = true
		elseif lmb == false and my >= 61 and my <= 65 then
			for i = 0, 7 do
				if mx >= 70 + i * 6 and mx <= 74 + i * 6 then
					local b = sprites.data.flags[sprites.sprite]
					sprites.data.flags[sprites.sprite] = flip(b, i)
					sprites.forceDraw = true
					return
				end
			end
		end
	end
end

function sprites.import(data)
	sprites.data = data
end

function sprites.export()
	return sprites.data
end

function sprites.exportGFX()
	local d = ""

	for y = 0, 127 do
		for x = 0, 127 do
			local v = sprites.data.data:getPixel(x, y)
			v = string.format("%x", v / 16)
			d = d .. v
		end

		d = d .. "\n"
	end

	return d
end

function sprites.exportGFF()
	local d = ""

	for s = 0, 511 do
		d = d .. string.format("%02x", sprites.data.flags[s])
		if s ~= 1 and (s + 1) % 128 == 0 then
			d = d .. "\n"
		end
	end

	return d
end

function sprites._keydown(k, r)
	if api.key("rctrl") or api.key("lctrl") then
    if k == "s" then
      commands.save()
    end
	else

	end
end

return sprites