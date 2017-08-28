-----------------------------------------
-- main callbacks
-----------------------------------------

frameTime = 1 / config.fps
hostTime = 0

function love.load()
	log.info(
		"neko 8 " .. config.version.string
	)

	neko.init()

	giflib = require "gif"
end

function love.update(dt)
	neko.update()
end

function love.draw()
	love.graphics.setCanvas(
		canvas.renderable
	)

	love.graphics.setShader(
		colors.drawShader
	)

	neko.draw()
	api.flip()
end

function love.resize(w, h)
	resizeCanvas(w,h)
	log.debug(
		"new window size: " .. w
		.. "x" .. h .. "px"
	)
end

function love.keypressed(
	key, scancode, isRepeat
)
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, k
				in pairs(api.keyMap[p][i]) do
				if key == k then
					api.keyPressed[p][i] = -1
					break
				end
			end
		end
	end

	local handled = true

	if love.keyboard.isDown("rctrl") or
		love.keyboard.isDown("lctrl") then
		if key == "r" then
			if neko.loadedCart then
				runCart(neko.loadedCart)
			end
		elseif key == "v" then
			love.textinput(
				love.system.getClipboardText()
			)
		elseif key == "c" then
			love.system.setClipboardText(
				triggerCallback("_copy") or ""
			)
		else
			handled = false
		end
	else
		if key == "escape" then
			if neko.cart then
				neko.cart = nil
			elseif editors.opened then
				editors.close()
			else
				editors.open()
			end
		elseif key == "f1" then
			local s =
				love.graphics.newScreenshot(false)
			local file = "neko8-"
				.. os.time() .. ".png"

			s:encode("png", file)
			log.info(
				"saved screenshot to " .. file
			)
		elseif key == "f8" then
			gif = giflib.new("neko8.gif")
			log.info("recording gif..")
		elseif key == "f9" then
			if not gif then return end
			gif:close()
      gif = nil
      love.filesystem.write(
				"neko8-" .. os.time() .. ".gif",
				love.filesystem.read("neko8.gif")
			)
      love.filesystem.remove("neko8.gif")
		else
			handled = false
		end
	end

	if not handled then
		triggerCallback(
			"_keydown", key, isRepeat
		)
	end
end

function love.keyreleased(key)
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, k
				in pairs(api.keyMap[p][i]) do
				if key == k then
					api.keyPressed[p][i] = nil
					break
				end
			end
		end
	end

	triggerCallback("_keyup", key)
end

function replaceChar(pos, str, r)
    return str:sub(1, pos - 1)
			.. r .. str:sub(pos + 1)
end

function validateText(text)
	for i = 1, #text do
		local c = text:sub(i, i)
		local valid = false
		for j = 1, #config.font.letters do
			local ch = config.font.letters:sub(j, j)
			if c == ch then
				valid = true
				break
			end
		end
		if not valid then
			print("Invalid " .. c)
			text = replaceChar(i, text, "")
		end
	end

	return text
end

function love.textinput(text)
	text = validateText(text)
	triggerCallback("_text", text)
end

function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
		for i = 1, 3 do love.math.random() end
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end
	if love.timer then love.timer.step() end

	local dt = 0
	while true do
		if love.event then
			love.event.pump()
			for e, a, b, c, d in
				love.event.poll() do
				if e == "quit" then
					if not love.quit
						or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a,b,c,d)
			end
		end
		if love.timer then
			love.timer.step()
			dt = dt + love.timer.getDelta()
		end
		local render = false
		while dt > frameTime do
			hostTime = hostTime + dt
			if hostTime > 65536 then
				hostTime = hostTime - 65536
			end
			if love.update then
				love.update(frameTime)
			end
			dt = dt - frameTime
			render = true
		end
		if render and love.window
			and love.graphics
			and love.window.isCreated() then

			love.graphics.origin()
			if love.draw then love.draw() end
		end
		if love.timer then
			love.timer.sleep(0.001)
		end
	end
end

function triggerCallback(c, ...)
	if neko.cart
		and neko.cart.sandbox[c] then

		return cart.sandbox[c](...)
	elseif editors.opened then
		if editors.current[c] then
			editors.current[c](...)
		end
	elseif neko.core.sandbox[c] then
		return neko.core.sandbox[c](...)
	end

	return nil
end

-----------------------------------------
-- canvas helpers
-----------------------------------------

canvas = {
	x = 0,
	y = 0,
	scaleX = 1,
	scaleY = 1,
	renderable = nil
}

function initCanvas()
	canvas.renderable =
		love.graphics.newCanvas(
			config.canvas.width,
			config.canvas.height
		)


	canvas.renderable:setFilter(
		"nearest", "nearest"
	)

	resizeCanvas(
		love.graphics.getWidth(),
		love.graphics.getHeight()
	)
end

function resizeCanvas(width, height)
	local size = math.floor(
		math.min(
			width / config.canvas.width,
			height / config.canvas.height
		)
	)

	canvas.scaleX = size
	canvas.scaleY = size

	canvas.x =
		(width - size * config.canvas.width)
		/ 2
	canvas.y =
		(height - size * config.canvas.height)
		/ 2
end

-----------------------------------------
-- neko8
-----------------------------------------

neko = {}

function neko.init()
	neko.currentDirectory = "/"

	initCanvas()
	initFont()
	initPalette()
	initApi()

	editors = require "editors"
	editors.init()

	neko.core = loadCart("neko")
	runCart(neko.core)
end

function neko.update()
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, key in pairs(
				api.keyMap[p][i]
			) do
				local v = api.keyPressed[p][i]
				if v then
					v = v + 1
					api.keyPressed[p][i] = v
					break
				end
			end
		end
	end

	triggerCallback("_update")
end

function neko.draw()
	triggerCallback("_draw")
end

-----------------------------------------
-- font
-----------------------------------------

function initFont()
	font = love.graphics.newFont(
		config.font.file, 4
	)


	font:setFilter("nearest", "nearest")

	love.graphics.setFont(font)
end

-----------------------------------------
-- carts
-----------------------------------------

function loadCart(name)
	local cart = createCart()
	log.debug("loading cart " .. name)

	local pureName = name
	local extensions = { "", ".n8" }

	if name:sub(-3) == ".n8" then
		extensions = { ".n8" }
		pureName = name:sub(1, -4)
	end

	local found = false
	for i = 1, #extensions do
		if love.filesystem.isFile(
			pureName .. extensions[i]
		) then
			found = true
			name = pureName .. extensions[i]
			break
		end
	end

	cart.name = name
	cart.pureName = pureName

	if not found then
		log.error("failed to load cart")
		return nil
	end

	local data, size =
		love.filesystem.read(name)

	if not data then
		log.error("failed to open cart")
		return cart
	end

	local header = "neko8 cart"

	if not data:find(header) then
		log.error("invalid cart")
	end

	cart.code = loadCode(data, cart)
	editors.code.import(cart.code)

	--
	-- possible futures:
	-- sprites
	-- maps
	-- music
	-- sfx
	--

	love.graphics.setShader(
		colors.drawShader
	)

	return cart
end

function createCart()
	local cart = {}
	cart.sandbox = createSandbox()

	return cart
end

function loadCode(data, cart)
	local codeStart = data:find("__lua__")
		+ 8
	local codeEnd = data:find("__end__")
		- 1

	local code = data:sub(
		codeStart, codeEnd
	)

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
		"(%S+)%s*([%+-%*/%%])=",
		"%1 = %1 %2 "
	)

	return code
end

function runCart(cart)
	if not cart or not cart.sandbox then
		return
	end

	log.info(
		"running cart " .. cart.pureName
	)

	local ok, f, e = pcall(
		load, cart.code, cart.name
	)

	if e then
		log.error("syntax error:")
		log.error(e)
		return
	end

	local result
	setfenv(f, cart.sandbox)
	ok, result = pcall(f)

	if not ok then
		log.error("runtime error:")
		log.error(result)
		return
	end

	love.graphics.setCanvas(
		canvas.renderable
	)

	love.graphics.setShader(
		colors.drawShader
	)
	if cart.sandbox._init then
		cart.sandbox._init()
	end
	api.flip()
end

function saveCart()
	if not neko.loadedCart then
		return false
	end

	--
	-- todo!
	-- save cart
	--

	cart.code = editors.code.export()

	return true
end

-----------------------------------------
-- api
-----------------------------------------

api = {}

function initApi()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	love.keyboard.setKeyRepeat(true)
	api.color()

	api.keyPressed = {
		[0] = {},
		[1] = {}
	}

	api.keyMap = {
		[0] = {
			[0] = { "left" },
			[1] = { "right" },
			[2] = { "up" },
			[3] = { "down" },
			[4] = { "z", "n" },
			[5] = { "x", "m" }
		},
		[1] = {
			[0] = { "s" },
			[1] = { "f" },
			[2] = { "e" },
			[3] = { "d" },
			[4] = { "tab", "lshift" },
			[5] = { "q", "a" }
		}
	}
end

function createSandbox()
	return {
		pcall = pcall,
		loadstring = loadstring,

		printh = print,
		csize = api.csize,
		rect = api.rect,
		rectfill = api.rectfill,
		brect = api.brect,
		brectfill = api.brectfill,
		color = api.color,
		cls = api.cls,
		circ = api.circ,
		circfill = api.circfill,
		pset = api.pset,
		pget = api.pget,
		line = api.line,
		print = api.print,
		flip = api.flip,
		cursor = api.cursor,
		cget = api.cget,
		scroll = api.scroll,

		memcpy = api.memcpy,

		btn = api.btn,
		btnp = api.btnp,
		key = api.key,

		flr = api.flr,
		ceil = api.ceil,
		cos = api.cos,
		sin = api.sin,
		rnd = api.rnd,
		srand = api.srand,
		max = api.max,
		min = api.min,
		mid = api.mid,

		help = commands.help,
		folder = commands.folder,
		ls = commands.ls,
		cls = commands.cls,
		run = commands.run,
		new = commands.new,
		mkdir = commands.mkdir,
		load = commands.load,
		save = commands.save,
		reboot = commands.reboot,
		shutdown = commands.shutdown,
		cd = commands.cd,
		rm = commands.rm,

		pairs = pairs,
		ipairs = ipairs,
		string = string,
		add = api.add,
		del = api.del,
		all = api.all,
		count = api.count,
		foreach = api.foreach
	}
end

function api.csize()
	return config.canvas.width,
		config.canvas.height
end

function api.rect(x0, y0, x1, y1, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("line",
		api.flr(x0) + 1,
		api.flr(y0) + 1,
		api.flr(x1 - x0),
		api.flr(y1 - y0)
	)
end

function api.rectfill(x0, y0, x1, y1, c)
	if c then
		api.color(c)
	end

	local w = (x1 - x0) + 1
	local h = (y1 - y0) + 1

	if w < 0 then
		w = -w
		x0 = x0 - w
	end

	if h < 0 then
		h = -h
		y0 = y0 - h
	end

	love.graphics.rectangle(
		"fill", api.flr(x0),
		api.flr(y0), w, h
	)
end

function api.brect(x, y, w, h, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("line",
		api.flr(x) + 1,
		api.flr(y) + 1,
		api.flr(w),
		api.flr(h)
	)
end

function api.brectfill(x, y, w, h, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("fill",
		api.flr(x),
		api.flr(y),
		api.flr(w),
		api.flr(h))
end

function api.color(c)
	if not c then
		c = 7
	else
		c = api.flr(c % 16)
	end

	love.graphics.setColor(
		c * 16, 0, 0, 255
	)

	colors.current = c
end

function api.circ(ox, oy, r, c)
	if c then
		api.color(c)
	end

	ox = api.flr(ox)
	oy = api.flr(oy)
	r = api.flr(r)

	local points = {}
	local x = r
	local y = 0
	local decisionOver2 = 1 - x

	while y <= x do
		table.insert(points, {ox + x, oy + y})
		table.insert(points, {ox + y, oy + x})
		table.insert(points, {ox - x, oy + y})
		table.insert(points, {ox - y, oy + x})

		table.insert(points, {ox - x, oy - y})
		table.insert(points, {ox - y, oy - x})
		table.insert(points, {ox + x, oy - y})
		table.insert(points, {ox + y, oy - x})

		y = y + 1
		if decisionOver2 < 0 then
			decisionOver2 = decisionOver2
				+ 2 * y + 1
		else
			x = x - 1
			decisionOver2 = decisionOver2
				+ 2 * (y - x) + 1
		end
	end
	if #points > 0 then
		love.graphics.points(points)
	end
end

function _plot4points(
	points, cx, cy, x, y
)
	_horizontal_line(points, cx - x,
		cy + y, cx + x)
	if x ~= 0 and y ~= 0 then
		_horizontal_line(points, cx - x,
			cy - y, cx + x)
	end
end

function _horizontal_line(
	points, x0, y, x1
)
	for x = x0, x1 do
		table.insert(points, {x, y})
	end
end

function api.circfill(cx, cy, r, c)
	if c then
		api.color(c)
	end

	cx = api.flr(cx)
	cy = api.flr(cy)
	r = api.flr(r)

	local x = r
	local y = 0
	local err = 1 - r

	local points = {}

	while y <= x do
		_plot4points(points, cx, cy, x, y)

		if err < 0 then
			err = err + 2 * y + 3
		else
			if x ~= y then
				_plot4points(points, cx, cy, y, x)
			end

			x = x - 1
			err = err + 2 * (y - x) + 3
		end
		y = y + 1
	end

	if #points > 0 then
		love.graphics.points(points)
	end
end

function api.pget(x, y, c)
	return 0 -- todo
end

function api.pset(x, y, c)
	if not c then
		return
	end

	api.color(c)
	love.graphics.points(
		api.flr(x), api.flr(y),
		c * 16, 0, 0, 255
	)
end

function api.line(x1, y1, x2, y2, c)
	if c then
		api.color(c)
	end

	love.graphics.line(x1, y1, x2, y2)
end

cursor = {
	x = 0,
	y = 0
}

function api.print(s, x, y, c)
	if c then
		api.color(c)
	end

	local scroll = (y == nil)

	if type(x) == "boolean" then
		x = cursor.x
		cursor.x = cursor.x + #s*4
	end

	if type(y) == "boolean" then
		scroll = y
		if not scroll then
			y = cursor.y
		end
	end

	if scroll then
		y = cursor.y
	 	cursor.y = cursor.y + 6
	end

	if x == nil or type(x) == "boolean" then
		x = cursor.x
	end

	if scroll and y >= 120 then
		local c = c or colors.current
		api.scroll(6)
		y = 114

		api.rectfill(
			0, y - 1, config.canvas.width, y + 7, 0
		)

		api.color(c)
		api.cursor(0, y + 6)
		api.flip()
	end

	love.graphics.setShader(
		colors.textShader
	)

	love.graphics.print(
		s, api.flr(x), api.flr(y) + 1
		-- watch out that +1!
	)
end

function api.flip()
	love.graphics.setShader(
		colors.displayShader
	)

	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	love.graphics.setCanvas()
	love.graphics.clear()

	love.graphics.draw(
		canvas.renderable,
		canvas.x, canvas.y, 0,
		canvas.scaleX, canvas.scaleY
	)

	love.graphics.present()
	love.graphics.setShader(colors.drawShader)

	if gif then
		gif:frame(canvas.renderable:newImageData())
	end

	love.graphics.setCanvas(canvas.renderable)
end

function api.cursor(x, y)
	cursor.x = x or cursor.x
	cursor.y = y or cursor.y
end

function api.cget()
	return cursor.x, cursor.y
end

function api.scroll(pixels)
	local sc = canvas.renderable:newImageData()

	sc:mapPixel(function(x, y, r, g, b, a)
		return r - 1, g, b, a
	end)

	local i = love.graphics.newImage(sc)
	i:setFilter("nearest")

	api.cls()
	love.graphics.setShader(colors.spriteShader)
  love.graphics.draw(i, 0, -pixels)
  love.graphics.setShader(colors.drawShader)
end

function api.memcpy(
	dest_addr, source_addr, len
)
	-- todo
end

function api.btn(b, p)
	p = p or 0

	if api.keyMap[p][b] then
		return api.keyPressed[p][b] ~= nil
	end

	return false
end

function api.btnp(b, p)
	p = p or 0

	if api.keyMap[p][b] then
		local v = api.keyPressed[p][b]
		if v and (v == 0 or (v >= 12 and v % 4 == 0)) then
			return true
		end
	end

	return false
end

function api.key(k)
	return love.keyboard.isDown(k)
end

function api.cls(c)
	if c then
		api.color(c)
	end

	c = c or 0

	love.graphics.clear(
		(c + 1) * 16, 0, 0, 255
	)

	cursor.x = 0
	cursor.y = 0
end

function api.flr(n)
	return math.floor(n or 0)
end

function api.ceil(n)
	return math.ceil(n or 0)
end

function api.cos(n)
	return math.cos(
		(n or 0) * (math.pi * 2)
	)
end

function api.sin(n)
	return math.sin(
		-(n or 0) * (math.pi * 2)
	)
end

function api.rnd(min, max)
	min = min or 1
	if max then
		return math.random(min, max)
	else
		return math.random() * min
	end
end

function api.srand(s)
	math.randomseed(s or 0)
end

function api.min(a, b)
	return a < b and a or b
end

function api.max(a, b)
	return a > b and a or b
end

function api.mid(x, y, z)
	x, y, z = x or 0, y or 0, z or 0
	if x > y then
		x, y = y, x
	end

	return api.max(x, api.min(y, z))
end

function api.add(a, v)
	if a == nil then
		return
	end
	table.insert(a, v)
end

function api.del(a, dv)
	if a == nil then
		return
	end
	for i, v in ipairs(a) do
		if v == dv then
			table.remove(a,i)
		end
	end
end

function api.foreach(a, f)
	if not a then
		return
	end
	for i, v in ipairs(a) do
		f(v)
	end
end

function api.count(a)
	return #a
end

function api.all(a)
	local i = 0
	local n = table.getn(a)
	return function()
		i = i + 1
		if i <= n then return a[i] end
	end
end

-----------------------------------------
-- commands
-----------------------------------------

commands = {}

function commands.help(a)
	if #a == 0 then
		api.print("neko8 "
			.. config.version.string)
		api.print("")
		api.color(6)
		api.print("by @egordorichev")
		api.print("made with love")
		api.color(7)
		api.print("https://github.com/egordorichev/neko8")
		api.print("")
		api.print("todo")
	else
		api.print("todo: help on a subject")
	end
end

function commands.folder()
	local cdir =
		love.filesystem.getSaveDirectory()
		.. neko.currentDirectory
	love.system.openURL("file://" .. cdir)
end

function commands.ls(a)
	local dir = neko.currentDirectory
	if #a == 1 then
		dir = dir .. a[1]
	elseif #a > 1 then
		api.print("ls (dir)")
		return
	end

	if not love.filesystem
		.isDirectory(dir) then
		api.print(
			"no such directory", nil, nil, 14
		)
		return
	end

	local files =
		love.filesystem.getDirectoryItems(dir)

	api.print(
		"directory: " .. dir, nil, nil, 12
	)

	api.color(7)
	local out = {}

	for i, f in ipairs(files) do
		if love.filesystem.isDirectory(f)
		 	and f:sub(1, 1) ~= "." then
			api.add(out, {
				name = f:lower(),
				color = 12
			})
		end
	end

	for i, f in ipairs(files) do
		if not love.filesystem.isDirectory(f) then
			api.add(out, {
				name = f:lower(),
				color = f:sub(-3) == ".n8"
					and 6 or 5
			})
		end
	end

	for f in api.all(out) do
		api.print(f.name, nil, nil, f.color)
	end

	if #out == 0 then
		api.print("total: 0", nil, nil, 12)
	end
end

function commands.cls()
	api.cls()
end

function commands.run()
	if neko.loadedCart ~= nil then
		neko.cart = neko.loadedCart
		runCart(neko.loadedCart)
	else
		api.color(14)
		api.print("no carts loaded")
	end
end

function commands.new()
	neko.loadedCart = createCart()
	api.print("created new cart")
end

function commands.mkdir(a)
	if #a == 0 then
		api.print("mkdir [dir]")
	else
		api.foreach(a,function(name)
			love.filesystem.createDirectory(
				neko.currentDirectory .. name
			)
		end)
	end
end

function commands.load(a)
	if #a ~= 1 then
		api.print("load [cart]")
	else
		local c = loadCart(a[1])
		if not c then
			api.color(14)
			api.print(
				"failed to load " .. a[1]
			)
		else
			api.print(
				"loaded " .. c.pureName
			)
			neko.loadedCart = c
		end
	end
end

function commands.save(a)
	if not neko.loadedCart then
		api.color(14)
		api.print("no carts loaded")
		return
	end

	if not saveCart() then
		api.color(14)
		api.print(
			"failed to save cart"
		)
	else
		api.print(
			"saved " .. neko.loadedCart.pureName
		)
	end
end

function commands.reboot()
	neko.init()
end

function commands.shutdown()
	love.event.quit()
end

function commands.cd(a)
	if #a ~= 1 then
		api.print("cd [dir]")
		return
	end

	local dir = neko.currentDirectory
		.. a[1]

	-- todo: fix /test//../ and stuff

	if not love.filesystem.isDirectory(dir) then
		api.print(
			"no such directory", nil, nil, 14
		)
		return
	end

	neko.currentDirectory = dir
	api.print(dir, nil, nil, 12)
end

function commands.rm(a)
	if #a ~= 1 then
		api.print("rm [file]")
		return
	end

	local file = neko.currentDirectory
		.. a[1]

	-- todo: fix /test//../ and stuff

	if not love.filesystem.exists(file) then
		api.print(
			"no such file", nil, nil, 14
		)
		return
	end

	if not love.filesystem.remove(file) then
		api.print(
			"failed to delete file", nil, nil, 14
		)
	end
end

-----------------------------------------
-- shaders
-----------------------------------------

colors = {}
colors.current = 7

function shaderUnpack(t)
	return unpack(t, 1, 17)
	-- change to 16 once love2d
	-- shader bug is fixed
end

function initPalette()
	colors.palette = {
		{0, 0, 0, 255},
		{29, 43, 83, 255},
		{126, 37, 83, 255},
		{0, 135, 81, 255},
		{171, 82, 54, 255},
		{95, 87, 79, 255},
		{194, 195, 199, 255},
		{255, 241, 232, 255},
		{255, 0, 77, 255},
		{255, 163, 0, 255},
		{255, 240, 36, 255},
		{0, 231, 86, 255},
		{41, 173, 255, 255},
		{131, 118, 156, 255},
		{255, 119, 168, 255},
		{255, 204, 170, 255}
	}

	colors.display = {}
	colors.draw = {}
	colors.transparent = {}

	for i = 1, 16 do
		colors.draw[i] = i
		colors.transparent[i] =
			i == 1 and 0 or 1
		colors.display[i] = colors.palette[i]
	end

	colors.drawShader =
		love.graphics.newShader([[
extern float palette[16];
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	int index = int(color.r*16.0);
	return vec4(vec3(palette[index]/16.0),1.0);
}]])

	colors.drawShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader =
		love.graphics.newShader([[
extern float palette[16];
extern float transparent[16];
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	int index = int(floor(Texel(texture, texture_coords).r*16.0));
	float alpha = transparent[index];
	return vec4(vec3(palette[index]/16.0),alpha);
}]])

	colors.spriteShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)

	colors.textShader =
		love.graphics.newShader([[
extern float palette[16];
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	vec4 texcolor = Texel(texture, texture_coords);
	if(texcolor.a == 0.0) {
		return vec4(0.0,0.0,0.0,0.0);
	}
	int index = int(color.r*16.0);
	return vec4(vec3(palette[index]/16.0),1.0);
}]])

	colors.textShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.displayShader =
		love.graphics.newShader([[
extern vec4 palette[16];
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	int index = int(Texel(texture, texture_coords).r*15.0);
	return palette[index]/256.0;
}]])

	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)
end

-----------------------------------------
-- logging
-----------------------------------------

--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

log = { _version = "0.1.0" }

log.usecolor = true
log.outfile = nil
log.level = "trace"

local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select("#", ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    -- Return early if we"re below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    print(string.format("%s[%-6s%s]%s %s: %s",
      log.usecolor and x.color or "",
      nameupper,
      os.date("%H:%M:%S"),
      log.usecolor and "\27[0m" or "",
      lineinfo,
      msg))

    -- Output to log file
    if log.outfile then
      local fp = io.open(log.outfile, "a")
      local str = string.format("[%-6s%s] %s: %s\n",
        nameupper, os.date(), lineinfo, msg)

			fp:write(str)
      fp:close()
    end
  end
end