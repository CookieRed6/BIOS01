local sprites = {}

function sprites.init()
	sprites.color = 7
	sprites.sprite = 0
	sprites.page = 0
	sprites.scale = 1
	sprites.icon = 9
	sprites.name = "sprite editor"
	sprites.bg = config.editors.sprites.bg
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
	api.brectfill(0, 8, 64, 64, 0)

	api.sspr(
		sprites.sprite % 16 * 8,
		api.flr(sprites.sprite / 16) * 8,
		8 * sprites.scale, 8 * sprites.scale,
		0, 8, 64, 64
	)

	-- palette
	for x = 0, 3 do
		for y = 0, 3 do
			local c = x + y * 4
			api.brectfill(
				x * 12, 72 + y * 12,
				12, 12, c
			)
		end
	end

	-- current color

	local x = sprites.color % 4
	local y = api.flr(sprites.color / 4)

	api.brect(
		x * 12, 72 + y * 12,
		12, 12, 0
	)

	api.brect(
		x * 12 - 1, 71 + y * 12,
		14, 14, 7
	)

	-- sprites
	api.brectfill(
		64, 8, 128,
		64, 0
	)

	api.sspr(
		0, api.flr(sprites.page % 8),
		128, 64, 64, 8, 128, 64
	)

	-- current sprite
	local s = sprites.sprite - sprites.page * 64
	x = s % 16
	y = api.flr(s / 16)

	if y >= 0 then
		api.brect(
			63 + x * 8, 7 + y * 8,
			8 * sprites.scale, 8 * sprites.scale, 0
		)

		api.brect(
			62 + x * 8, 6 + y * 8,
			8 * sprites.scale + 2, 8 * sprites.scale + 2, 7,
			8 * sprites.scale + 2, 8 * sprites.scale + 2, 7
		)
	end

	editors.drawUI()
	neko.cart = nil -- see spr and sspr
end

local function flip(byte, b)
  b = 2 ^ b
  return bit.bxor(byte, b)
end

local mx, my, mb, lmb

function sprites._update()
	lmb = mb
	mx, my, mb = api.mstat(1)

	if mb then
		if mx > 64 and mx < 192
			and my > 8 and my < 72 then

			my = my - 8
			mx = mx - 64

			print(mx, my)

			sprites.sprite = api.mid(0, 511, api.flr(mx / 8)
				+ api.flr(my / 8) * 16 + sprites.page * 64)


			sprites.forceDraw = true
		elseif mx > 0 and mx < 64
			and my > 8 and my < 72 then

			mx = api.flr(mx / (8 * sprites.scale))
			my = api.flr((my - 8) / (8 * sprites.scale))

			local v = sprites.color * 16
			local s = sprites.sprite

			sprites.data.data:setPixel(
				api.mid(mx, 0, 7) + s % 16 * 8,
				api.mid(my, 0, 7) + api.flr(s / 16) * 8,
				v, v, v
			)

			sprites.data.sheet:refresh()
			sprites.forceDraw = true
		elseif my > 72 and my < 120 and
			mx > 0 and mx < 48 then
			mx = api.flr(mx / 12)
			my = api.flr((my - 72) / 12)

			sprites.color = api.mid(0, 15, mx + my * 4)
			sprites.forceDraw = true
		elseif lmb == false and my >= 60 and my <= 66 then
			for i = 0, 7 do
				if mx >= 69 + i * 6 and mx <= 76 + i * 6 then
					local b = sprites.data.flags[sprites.sprite]
					sprites.data.flags[sprites.sprite] = flip(b, i)
					sprites.forceDraw = true
					return
				end
			end
		elseif lmb == false and my >= 80 and my <= 88 then
			for i = 0, 7 do
				if mx >= 19 + i * 8 and mx <= 26 + i * 8 then
					sprites.page = i
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