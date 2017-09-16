
local vi = {}
vi.commands = {}
vi.modes = {}
local lume = require "libs.lume"
local colorize = require "libs.colorize"

local tw = 40
local th = 20

function vi.init()
	vi.mode = "normal"
	vi.shift = false
	vi.ctrl = false
	vi.count = nil
	vi.allowWrite = false
	vi.needMotion = false
	vi.motion = nil
	vi.escape = 0.0
	vi.escapeTimeout = 1.5

	vi.lines = {}
	vi.t = 0
	vi.lines[1] = ""
	vi.icon = 8
	vi.name = "viNeko"
	vi.bg = config.editors.vi.bg

	vi.select = {
		start = {
			x = -1,
			y = -1
		},

		finish = {
			x = -1,
			y = -1
		},

		active = false
	}

	vi.cursor = {
		x = 0,
		y = 0
	}

	vi.view = {
		x = 0,
		y = 0
	}

	if config.editors.vi.virc then
		config.editors.vi.virc(vi)
	end
end

function vi.getcount()
	local count = vi.count or 1
	vi.count = nil
	return count
end

function vi.commands.nmap(key, func)
	vi.modes.normal[key] = vi.modes.normal[func]
end

function vi.commands.imap(key, func)
	vi.modes.insert[key] = vi.modes.insert[func]
end

function vi.open()
	vi.forceDraw = true
	vi.tryClose = false
end

function vi._draw()
	if vi.forceDraw then
		vi.redraw()
		vi.forceDraw = false
	end

	editors.drawUI()
	vi.drawInfo()
end

local function cursorBlink()
	return vi.t < 16 or vi.t % 30 < 16
end

function vi._update(dt)
	if vi.tryClose then
		vi.escape = vi.escape + dt
		if vi.escape >= vi.escapeTimeout then
			vi.escape = 0
			vi.tryClose = false
		end
	end

	local lb = cursorBlink()
	vi.t = vi.t + 1

	if cursorBlink() ~= lb then
		vi.redraw()
	end

	lmb = mb
	mx, my, mb = api.mstat(1)
	mx = mx + vi.view.x * 4
	my = my + vi.view.y * 6

	if mb then
		if not lmb or vi.select.start.x == -1 then
			vi.select.start.x = api.flr((mx - 1) / 4)
			vi.select.start.y = api.flr((my - 8) / 6)

			vi.select.start.y = api.mid(
				0, api.max(1, #vi.lines - 1), vi.select.start.y
			)

			vi.select.start.x = api.mid(
				0, #vi.lines[vi.select.start.y + 1],
				vi.select.start.x
			)
		end

		if lmb or vi.select.finish.x == -1 then
			vi.select.finish.x = api.flr((mx - 1) / 4)
			vi.select.finish.y = api.flr((my - 8) / 6)

			vi.select.finish.y = api.mid(
				0, api.max(1, #vi.lines - 1), vi.select.finish.y
			)

			vi.select.finish.x = api.mid(
				0, #vi.lines[vi.select.finish.y + 1],
				vi.select.finish.x
			)
		end

		vi.select.active =
			api.abs(vi.select.start.x - vi.select.finish.x) > 0
			or api.abs(vi.select.start.y - vi.select.finish.y) > 0

		vi.cursor.x = vi.select.finish.x
		vi.cursor.y = vi.select.finish.y
		vi.checkCursor()

		vi.forceDraw = true
	end
end

local function highlight(lines)
	return colorize(
		lines,
		config.editors.vi.colors
	)
end

local function colorPrint(tbl)
	for i = 1, #tbl, 2 do
		local cx, cy = api.cget()

		api.color(tbl[i])
		api.print(tbl[i + 1], true, false)
	end

	api.print("")
	api.cursor(1 - vi.view.x * 4)
end

function vi.redraw()
	api.cls(config.editors.vi.bg)

	local buffer = lume.clone(
		lume.slice(
			vi.lines, vi.view.y + 1,
			vi.view.y + th - 1
		)
	)

	buffer = highlight(buffer)

	api.cursor(1 - vi.view.x * 4, 9)

	local c = config.editors.vi.colors.select

	if vi.select.active then
		if vi.select.finish.y - vi.select.start.y == 0 then
			api.rectfill(
				vi.select.start.x * 4 - vi.view.x * 4,
				vi.select.start.y * 6 + 9 - vi.view.y * 6,
				vi.select.finish.x * 4 - vi.view.x * 4,
				(vi.select.start.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)
		else
			local min = vi.select.start.y
				> vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.y
				< vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			api.rectfill(
				min.x * 4 - vi.view.x * 4,
				min.y * 6 + 9 - vi.view.y * 6,
				#vi.lines[min.y + 1] * 4 - vi.view.x * 4,
				(min.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)

			for y = min.y + 1, max.y - 1 do
				api.rectfill(
					-vi.view.x * 4,
					y * 6 + 9 - vi.view.y * 6,
					#vi.lines[y + 1] * 4 - vi.view.x * 4,
					(y + 1) * 6 + 8 - vi.view.y * 6,
					c
				)
			end

			api.rectfill(
				-vi.view.x * 4,
				max.y * 6 + 9 - vi.view.y * 6,
				max.x * 4 - vi.view.x * 4,
				(max.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)
		end
	end

	for l in api.all(buffer) do
		colorPrint(l)
	end

	local cx = vi.cursor.x
			- vi.view.x

	local cy = vi.cursor.y
			- vi.view.y

	if cursorBlink() then
		api.rectfill(
			cx * 4,
			cy * 6 + 8,
			cx * 4 + 4,
			cy * 6 + 14,
			config.editors.vi.cursor
		)
	end

	api.line(
		0, config.canvas.height - 7,
		config.canvas.width,
		config.canvas.height - 7,
		config.editors.vi.bg
	)

	api.line(
		0, 8, config.canvas.width,
		8, config.editors.vi.bg
	)
end

function vi.drawInfo()
	if vi.tryClose then
		api.print(
			"press escape again to quit",
			1, config.canvas.height - 6,
			config.editors.ui.fg
		)
	else
		local cx = vi.cursor.x
		if #vi.lines[vi.cursor.y + 1] > 0 then
			cx = cx + 1
		end

		api.print(
			string.format(
				"%s line %d/%d, char %d/%d",
				vi.mode,
				vi.cursor.y + 1, #vi.lines,
				cx, #vi.lines[vi.cursor.y + 1]
			),
			1, config.canvas.height - 6,
			config.editors.ui.fg
		)
	end
end

function vi.close()

end

function vi.requestClose()
	if vi.tryClose then
		return true
	end
	vi.tryClose = true
end

vi.modes.normal = {
	["h"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.x = vi.cursor.x - vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["l"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.x = vi.cursor.x + vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["k"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.y = vi.cursor.y - vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["j"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.y = vi.cursor.y + vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["i"] = function()
		vi.mode = "insert"
		vi.allowWrite = false
	end,
	["a"] = function()
		vi.mode = "insert"
		vi.cursor.x = vi.cursor.x + 1
		vi.allowWrite = false
		vi.checkCursor()
	end,
	["x"] = function()
		vi.t = 0

		if vi.select.active then
			vi.replaceSelected("")
			return
		end

		if #vi.lines[vi.cursor.y + 1] > 0
			and vi.cursor.x < #vi.lines[vi.cursor.y + 1] then
			vi.lines[vi.cursor.y + 1] =
				vi.lines[vi.cursor.y + 1]
				:sub(1, vi.cursor.x)
				.. vi.lines[vi.cursor.y + 1]
				:sub(
					vi.cursor.x + 1 + vi.getcount(),
					#vi.lines[vi.cursor.y + 1]
				)
		elseif vi.cursor.y + 1 < #vi.lines then
			local l1 = vi.lines[vi.cursor.y + 1]
			local l2 = vi.lines[vi.cursor.y + 2]

			table.remove(vi.lines, vi.cursor.y + 1)

			if l1 and l2 then
				vi.lines[vi.cursor.y + 1] = l1 .. l2
			end
		end
	end,
}

vi.modes.insert = {
	["escape"] = function()
		vi.mode = "normal"
		vi.cursor.x = vi.cursor.x - 1
		vi.checkCursor()
	end,
	["left"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.x = vi.cursor.x - vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["right"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.x = vi.cursor.x + vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["up"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.y = vi.cursor.y - vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["down"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.cursor.y = vi.cursor.y + vi.getcount()
		vi.t = 0
		vi.checkCursor()
	end,
	["return"] = function()
		if vi.select.active then
			vi.replaceSelected("")
		end

		local cx, cy = vi.cursor.x, vi.cursor.y
		local newLine = vi.lines[cy + 1]:sub(cx + 1, -1)

		vi.lines[cy + 1] = vi.lines[cy + 1]:sub(0, cx)

		local snum = string.find(vi.lines[cy + 1] .. "a", "%S")
		snum = snum and snum - 1 or 0
		newLine = string.rep(" ", snum) .. newLine

		vi.cursor.x, vi.cursor.y = snum, cy + 1

		cx = vi.cursor.x
		cy = vi.cursor.y

		if cy + 1 > #vi.lines then
			api.add(vi.lines, newLine)
		else
			vi.lines = lume.concat(
				lume.slice(
					vi.lines, 0, cy
				), { newLine },
				lume.slice(
					vi.lines, cy + 1, -1
				)
			)
		end
		vi.t = 0
		vi.checkCursor()
	end,
	["home"] = function()
		vi.cursor.x = 0
		vi.t = 0
		vi.checkCursor()
	end,
	["end"] = function()
		vi.cursor.x = #vi.lines[vi.cursor.y + 1]
		vi.t = 0
		vi.checkCursor()
	end,
	["pagedown"] = function()
		vi.cursor.y = vi.cursor.y + th
		vi.checkCursor()
		vi.cursor.x = #vi.lines[vi.cursor.y + 1]
		vi.t = 0
	end,
	["pageup"] = function()
		vi.cursor.y = vi.cursor.y - th
		vi.cursor.x = 0
		vi.t = 0
		vi.checkCursor()
	end,
	["backspace"] = function()
		if vi.select.active then
			vi.replaceSelected("")
			return
		end
		if #vi.lines[vi.cursor.y + 1] > 0
			and vi.cursor.x > 0 then
			vi.lines[vi.cursor.y + 1] =
				vi.lines[vi.cursor.y + 1]
				:sub(1, vi.cursor.x - 1)
				.. vi.lines[vi.cursor.y + 1]
				:sub(
					vi.cursor.x + 1,
					#vi.lines[vi.cursor.y + 1]
				)

			vi.cursor.x = vi.cursor.x - 1
		elseif vi.cursor.y > 0 then
			local l1 = vi.lines[vi.cursor.y]
			local l2 = vi.lines[vi.cursor.y + 1]

			table.remove(vi.lines, vi.cursor.y + 1)

			if vi.lines[vi.cursor.y]
				and l1 and l2 then

				vi.lines[vi.cursor.y] = l1 .. l2
				vi.cursor.x = #l1
				vi.cursor.y = vi.cursor.y - 1
			end
		end
		vi.t = 0
		vi.checkCursor()
	end,
	["tab"] = function()
		vi._text(" ")
		vi.t = 0
	end,
	["delete"] = function()
		vi.t = 0

		if vi.select.active then
			vi.replaceSelected("")
			return
		end

		if #vi.lines[vi.cursor.y + 1] > 0
			and vi.cursor.x < #vi.lines[vi.cursor.y + 1] then
			vi.lines[vi.cursor.y + 1] =
				vi.lines[vi.cursor.y + 1]
				:sub(1, vi.cursor.x)
				.. vi.lines[vi.cursor.y + 1]
				:sub(
					vi.cursor.x + 2,
					#vi.lines[vi.cursor.y + 1]
				)
		elseif vi.cursor.y + 1 < #vi.lines then
			local l1 = vi.lines[vi.cursor.y + 1]
			local l2 = vi.lines[vi.cursor.y + 2]

			table.remove(vi.lines, vi.cursor.y + 1)

			if l1 and l2 then
				vi.lines[vi.cursor.y + 1] = l1 .. l2
			end
		end
	end,
}

function vi._keyup(k)
	if k == "lshift" or k == "rshift" then
		vi.shift = false
		return
	elseif k == "lctrl" or k == "rctrl" then
		vi.ctrl = false
		return
	end
end

function vi._keydown(k)
	if k ~= "escape" then
		vi.tryClose = false
	end

	if k == "lshift" or k == "rshift" then
		vi.shift = true
		return
	elseif k == "lctrl" or k == "rctrl" then
		vi.ctrl = true
		return
	end

	local count = tonumber(k)
	if count then
		vi.count = vi.count or 0 
		vi.count = vi.count * 10 + count
		return
	end

	local mode = vi.modes[vi.mode]
	if mode and mode[k] then
		mode[k]()
	end

	vi.redraw()
end

function vi.replaceSelected(text)
	if vi.select.finish.y - vi.select.start.y == 0 then
		local min = vi.select.start.x
			> vi.select.finish.x and
			vi.select.finish
			or vi.select.start

		local max = vi.select.start.x
			< vi.select.finish.x and
			vi.select.finish
			or vi.select.start

		local line = vi.lines[min.y + 1]
		local newLine

		if min.x == 0 then
			newLine = text
		else
			newLine = line:sub(0, min.x) ..
				text
		end

		vi.lines[min.y + 1] =
			newLine ..
			line:sub(max.x + 1, #line)

		vi.cursor.x = #newLine
		vi.checkCursor()
	else
		local min = vi.select.start.y
			> vi.select.finish.y and
			vi.select.finish
			or vi.select.start

		local max = vi.select.start.y
			< vi.select.finish.y and
			vi.select.finish
			or vi.select.start

		local line = vi.lines[min.y + 1]
		local newLine

		if min.x > 0 then
			newLine = line:sub(0, min.x) .. text
		else
			newLine = text
		end

		for y = min.y, max.y do
			table.remove(vi.lines, min.y + 1)
		end

		table.insert(vi.lines, min.y + 1, newLine)

		vi.cursor.x = #newLine
		vi.cursor.y = min.y
		vi.checkCursor()
	end

	vi.select.active = false
end

function vi._copy()
	if vi.select.active then
		local text = ""

		if vi.select.finish.y - vi.select.start.y == 0 then
			local min = vi.select.start.x
				> vi.select.finish.x and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.x
				< vi.select.finish.x and
				vi.select.finish
				or vi.select.start

			local line = vi.lines[min.y + 1]
			text = line:sub(min.x + 1, max.x)
		else
			local min = vi.select.start.y
				> vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.y
				< vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local line = vi.lines[min.y + 1]
			text = line:sub(0, min.x, #line)

			local m = 1

			for y = min.y + 1, max.y + m do
				text = text .. "\n\n" .. vi.lines[y]
			end

			text = text .. "\n\n" .. vi.lines[max.y + m]:sub(0, max.x)
		end

		vi.forceDraw = true
		vi.select.active = false

		return text
	end
end

function vi._cut()
	local active = vi.select.active
	local text = vi._copy()

	if active then
		vi.select.active = true
		vi.replaceSelected("")
	end

	return text
end

function vi._text(text)
	if vi.mode == "normal" then
		return
	elseif not vi.allowWrite then
		vi.allowWrite = true
		return
	end

	-- todo: rewrite
	text = text:gsub("\t", " ")
	local parts = {}

	for p in text:gmatch("([^\r\n]*)\r?\n") do
		table.insert(parts, p)
	end

	if #parts > 0 then
		for i, part in ipairs(parts) do
			if vi.select.active then
				vi.replaceSelected(part)
			else
				vi.lines[vi.cursor.y + 1] =
				vi.lines[vi.cursor.y + 1]:sub(
				1, vi.cursor.x) .. part
				.. vi.lines[vi.cursor.y + 1]:sub(
					vi.cursor.x + 1, #vi.lines[
						vi.cursor.y + 1
					]
				)

				vi.cursor.x = vi.cursor.x + #text
			end

			vi.checkCursor()

			if #parts > 1 then
				if i < #parts then
					table.insert(vi.lines, vi.cursor.y + 1, "")
				end
			end

			vi.select.active = false
		end

		vi.cursor.y = vi.cursor.y - 1
		vi.checkCursor()
		vi.cursor.x = #vi.lines[vi.cursor.y + 1]
	else
		if vi.select.active then
			vi.replaceSelected(text)
		else
			vi.lines[vi.cursor.y + 1] =
			vi.lines[vi.cursor.y + 1]:sub(
			1, vi.cursor.x) .. text
			.. vi.lines[vi.cursor.y + 1]:sub(
				vi.cursor.x + 1, #vi.lines[
					vi.cursor.y + 1
				]
			)

			vi.cursor.x = vi.cursor.x + #text
			vi.checkCursor()
		end
	end

	vi.t = 0
	vi.redraw()
end

function vi._wheel(a)
	if a < 0 then
		vi.view.y = api.max(0, api.min(vi.view.y + 1, #vi.lines - th + 2))
	elseif a > 0 then
		vi.view.y = api.max(vi.view.y - 1, 0)
	end

	vi.t = 0
	vi.forceDraw = true
end

function vi.checkCursorY()
	vi.cursor.y =
		api.mid(
			0, vi.cursor.y,
			api.max(1, #vi.lines - 1)
		)

	if vi.cursor.y > th + vi.view.y - 3 then
		vi.view.y = vi.cursor.y - (th - 3)
		return true
	elseif vi.cursor.y < vi.view.y then
		vi.view.y = vi.cursor.y
		return true
	end

	return false
end

function vi.checkCursorX()
	vi.cursor.x =
		api.mid(
			0, vi.cursor.x,
			#vi.lines[vi.cursor.y + 1]
		)

	if vi.cursor.x > vi.view.x + tw - 5 then
		vi.view.x = vi.cursor.x - tw + 5
		return true
	elseif vi.cursor.x < vi.view.x + 5 then
		vi.view.x = api.max(0, vi.cursor.x - 5)
		return true
	end

	return false
end

function vi.checkCursor()
	vi.checkCursorY()
	vi.checkCursorX()
end

local function lines(s)
	if s:sub(-1) ~= "\n" then
		s = s .. "\n"
	end

	return s:gmatch("(.-)\n")
end

function vi.import(c)
	vi.lines = {}

	c = c:gsub("\t", " ")
	-- todo: doesn't work?

	for l in lines(c) do
		api.add(vi.lines, l)
	end

	if not vi.lines[1] then
		vi.lines[1] = ""
	end
end

function vi.export()
	local data = {}

	for l in api.all(vi.lines) do
		table.insert(data, l)
		table.insert(data, "\n")
	end

	return table.concat(data)
end

return vi

-- vim: noet
