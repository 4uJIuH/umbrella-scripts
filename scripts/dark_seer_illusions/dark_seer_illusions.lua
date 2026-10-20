local qLocalization = qLocalization
if type(qLocalization) ~= "table" or type(qLocalization.new) ~= "function" then
	local ok, lib = pcall(require, "!_qLocalizer")
	qLocalization = ok and type(lib) == "table" and type(lib.new) == "function" and lib or nil
end
if not qLocalization then
	Log.Write("[qLocalization] not found: put !_qLocalizer.lua into the scripts folder")
	return {}
end



local localization = qLocalization.new({
	en = {
		dsi_group_main = "Illusion Control",
		dsi_group_way = "Illusion Behavior",
		dsi_enable = "Control illusions",
		dsi_enable_tip = "Wall of Replica and Normal Punch illusions\nattack the heroes from the window",
		dsi_gear_extra = "Extra",
		dsi_debug = "Debug log",
		dsi_debug_tip = "Writes what the script is doing\nto the log",
		dsi_show = "Show window",
		dsi_show_tip = "Enemy priority: drag a row to reorder,\nits switch turns the hero off",
		dsi_order = "Attack order",
		dsi_order_tip = "Low HP first: a selected hero below the threshold\nis attacked before the others",
		dsi_orders_low = "Low HP first",
		dsi_orders_prio = "Priority first",
		dsi_low_hp = "Low HP threshold",
		dsi_low_hp_tip = "Below this share of HP the hero counts as low",
		dsi_others = "Attack unselected heroes",
		dsi_others_tip = "When no selected hero is in range:\nDark Seer's target, otherwise the lowest HP",
		dsi_radius = "Search radius",
		dsi_radius_tip = "Measured from each illusion",
		dsi_fallback = "No target",
		dsi_fallback_tip = "What the illusions do when there is no hero to attack",
		dsi_fallbacks_follow = "Follow Dark Seer",
		dsi_fallbacks_camps = "Farm jungle camps",
		dsi_fallbacks_lane = "Push lane and tower",
		dsi_manual = "Manual control",
		dsi_manual_tip = "After your own order the script\nleaves the illusion alone for this long",
		dsi_title = "Illusion Targets",
		dsi_no_enemies = "No enemies yet",
	},
	ru = {
		dsi_group_main = "Контроль иллюзий",
		dsi_group_way = "Поведение иллюзий",
		dsi_enable = "Управлять иллюзиями",
		dsi_enable_tip = "Иллюзии от Wall of Replica и Normal Punch\nбьют героев из окна",
		dsi_gear_extra = "Дополнительно",
		dsi_debug = "Отладка в лог",
		dsi_debug_tip = "Пишет в лог, что сейчас делает скрипт",
		dsi_show = "Показывать окно",
		dsi_show_tip = "Приоритет врагов: перетаскивай строки,\nпереключатель выключает героя",
		dsi_order = "Порядок атаки",
		dsi_order_tip = "Сначала мало HP: выбранный герой ниже порога\nбьётся раньше остальных",
		dsi_orders_low = "Сначала мало HP",
		dsi_orders_prio = "Сначала приоритет",
		dsi_low_hp = "Порог мало HP",
		dsi_low_hp_tip = "Ниже этой доли HP герой считается добиваемым",
		dsi_others = "Бить невыбранных героев",
		dsi_others_tip = "Если выбранных героев рядом нет:\nцель Dark Seer, иначе с меньшим HP",
		dsi_radius = "Радиус поиска",
		dsi_radius_tip = "Считается от каждой иллюзии",
		dsi_fallback = "Нет цели",
		dsi_fallback_tip = "Что делают иллюзии, когда бить некого",
		dsi_fallbacks_follow = "Следовать за Dark Seer",
		dsi_fallbacks_camps = "Бить лесные кемпы",
		dsi_fallbacks_lane = "Пушить линию и башню",
		dsi_manual = "Ручное управление",
		dsi_manual_tip = "После твоего приказа скрипт\nне трогает иллюзию это время",
		dsi_title = "Цели иллюзий",
		dsi_no_enemies = "Врагов пока нет",
	},
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

local ui = {}

do
	local hero_tab = UI.Find("Heroes", "Hero List", "Dark Seer")
	local page = hero_tab and hero_tab:Find("Main Settings")
	if not page then
		local tab = UI.Create("Scripts", "Scripts", "Illusion Control")
		tab:Icon("\u{f0c0}")
		page = tab:Create("Settings")
	end
	local g_main = page:Create("dsi_group_main", Enum.GroupSide.Left)
	local g_way = page:Create("dsi_group_way", Enum.GroupSide.Right)
	ui.hero_enable = Menu.Find("Heroes", "Hero List", "Dark Seer", "Main Settings", "Hero Settings", "Enable")

	ui.enable = g_main:Switch("dsi_enable", false, "\u{f0c0}")
	ui.enable:ToolTip("dsi_enable_tip")
	local g_gear = ui.enable:Gear("dsi_gear_extra")
	ui.debug = g_gear:Switch("dsi_debug", false, "\u{f188}")
	ui.debug:ToolTip("dsi_debug_tip")

	ui.show = g_main:Switch("dsi_show", true, "\u{f2d0}")
	ui.show:ToolTip("dsi_show_tip")

	ui.order = g_main:Combo("dsi_order", { "dsi_orders_low", "dsi_orders_prio" }, 0)
	ui.order:Icon("\u{f0dc}")
	ui.order:ToolTip("dsi_order_tip")

	ui.low_hp = g_main:Slider("dsi_low_hp", 5, 80, 30, "%d%%")
	ui.low_hp:Icon("\u{f21e}")
	ui.low_hp:ToolTip("dsi_low_hp_tip")

	ui.others = g_main:Switch("dsi_others", true, "\u{f05b}")
	ui.others:ToolTip("dsi_others_tip")

	ui.radius = g_way:Slider("dsi_radius", 300, 2000, 1000, "%d")
	ui.radius:Icon("\u{f1ce}")
	ui.radius:ToolTip("dsi_radius_tip")

	ui.fallback = g_way:Combo("dsi_fallback", { "dsi_fallbacks_follow", "dsi_fallbacks_camps", "dsi_fallbacks_lane" }, 0)
	ui.fallback:Icon("\u{f0e8}")
	ui.fallback:ToolTip("dsi_fallback_tip")

	ui.manual = g_way:Slider("dsi_manual", 1, 10, 3, "%d s")
	ui.manual:Icon("\u{f256}")
	ui.manual:ToolTip("dsi_manual_tip")
end

local function refresh_disabled()
	local on = ui.enable:Get()
	ui.debug:Disabled(not on)
	ui.order:Disabled(not on)
	ui.low_hp:Disabled(not on or ui.order:Get() ~= 0)
	ui.others:Disabled(not on)
	ui.radius:Disabled(not on)
	ui.fallback:Disabled(not on)
	ui.manual:Disabled(not on)
end

ui.enable:SetCallback(refresh_disabled, true)
ui.order:SetCallback(refresh_disabled)

local function active()
	return ui.enable:Get() and (not ui.hero_enable or ui.hero_enable:Get())
end

-- ===========================================================================
-- umbrella-ui kit (paste after the menu block)
-- Only edit the K block; everything below it is generic.
-- ===========================================================================

local K = {
	NAME = "Illusion Control",
	CFG = "dsi_illusion_control",
	W = 260,
	HEAD = 22,
	PAD = 10,
	EVERYWHERE = false,
	SMALL = true,
	DOCK = true,
	SNAP = 24,
	THEME = "umbrella",
	ACCENT = "umbrella",
	SINK_ID = "DsiIllusionInput",
	SINK_ALIVE = 0.4,
	SINK_TIMEOUT = 1500,
	TIP_DELAY = 0.35,
	TOAST_TIME = 4,
	WHEEL = 56,
	DOUBLE = 0.35,
	G = {
		close = "\u{f00d}", up = "\u{f077}", down = "\u{f078}", gear = "\u{f013}", check = "\u{f00c}",
		left = "\u{f053}", right = "\u{f054}",
		search = "\u{f002}", info = "\u{f05a}", warn = "\u{f071}", ok = "\u{f058}", empty = "\u{f49e}",
	},
}

local ROUND = Enum.DrawFlags.RoundCornersAll
local KEY = Enum.ButtonCode

local function clamp(v, a, b) return v < a and a or (v > b and b or v) end
local function ease_out(t) return 1 - (1 - t) * (1 - t) end
local function ease_in_out(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end

local THEME_ORDER = { "umbrella", "graphite", "midnight", "purple", "forest", "oled" }
local THEMES = {
	graphite = { win = { 25, 25, 27 }, card = { 34, 34, 37 }, menu = { 42, 42, 46 }, off = { 58, 58, 63 } },
	midnight = { win = { 17, 20, 31 }, card = { 25, 30, 45 }, menu = { 34, 40, 58 }, off = { 52, 60, 84 } },
	purple = { win = { 22, 17, 32 }, card = { 32, 25, 47 }, menu = { 46, 36, 67 }, off = { 62, 49, 88 } },
	forest = { win = { 17, 25, 21 }, card = { 24, 35, 29 }, menu = { 37, 52, 44 }, off = { 52, 70, 60 } },
	oled = { win = { 0, 0, 0 }, card = { 15, 15, 17 }, menu = { 28, 28, 31 }, off = { 44, 44, 48 } },
	umbrella = {
		win = { 16, 17, 21 }, card = { 19, 21, 25 }, menu = { 23, 26, 28 }, off = { 36, 38, 46 },
		line = { 51, 51, 51 }, knob = { 102, 102, 102 },
		t1 = { 245, 245, 245 }, t2 = { 207, 209, 222 }, t3 = { 176, 176, 176 }, t4 = { 115, 117, 130 },
	},
}

local ACCENT_ORDER = { "umbrella", "blue", "teal", "green", "purple", "orange", "pink" }
local ACCENTS = {
	umbrella = { 207, 54, 54 }, blue = { 76, 130, 247 }, teal = { 38, 166, 154 }, green = { 52, 168, 83 },
	purple = { 138, 99, 210 }, orange = { 240, 140, 40 }, red = { 226, 75, 75 }, pink = { 232, 90, 150 },
}

local UMBRELLA_STYLE = {
	win = "main_background", card = "group_background", menu = "button_background", off = "slider_background",
	line = "outline", knob = "disabled_switch_circle", t1 = "active_widgets_text", t2 = "primary_first_tab_text",
	t3 = "primary_widgets_text", t4 = "section_group_text", accent = "primary",
}

local T = {
	t1 = { 250, 250, 252 }, t2 = { 218, 218, 224 }, t3 = { 160, 160, 168 }, t4 = { 120, 120, 128 },
	white = { 255, 255, 255 }, black = { 0, 0, 0 }, knob = { 142, 142, 147 },
	green = { 104, 214, 126 }, red = { 255, 110, 100 }, yellow = { 255, 204, 64 },
}
local T_BASE = { t1 = T.t1, t2 = T.t2, t3 = T.t3, t4 = T.t4, knob = T.knob }

local function valid(list, v, default)
	for _, o in ipairs(list) do
		if o == v then return v end
	end
	return default
end

local P = {
	open = true, alpha = 0, wx = nil, wy = nil, h = 0, dt = 0, now = 0,
	tweens = {}, press = nil, drag = nil, slide = nil, sb_drag = nil, moved = false,
	menu = nil, menu_req = nil, tip_req = nil, tip_id = nil, tip_since = 0,
	scroll = {}, toasts = {}, last_click = { id = nil, t = -10 }, draw_error = nil,
	focus = nil, focus_id = nil, saved = {},
	set = {
		theme = Config.ReadString(K.CFG, "theme", K.THEME),
		accent = Config.ReadString(K.CFG, "accent", K.ACCENT),
		scale = Config.ReadInt(K.CFG, "scale", 100),
		opacity = Config.ReadInt(K.CFG, "opacity", 94),
		collapsed = Config.ReadInt(K.CFG, "collapsed", 0) == 1,
		docked = Config.ReadInt(K.CFG, "docked", 0) == 1,
	},
}
P.set.theme = K.SMALL and "umbrella" or valid(THEME_ORDER, P.set.theme, "umbrella")
P.set.accent = K.SMALL and "umbrella" or valid(ACCENT_ORDER, P.set.accent, "umbrella")
P.set.scale = clamp(P.set.scale, 70, 150)
P.set.opacity = clamp(P.set.opacity, 40, 100)
for k, v in pairs(P.set) do P.saved[k] = type(v) == "boolean" and (v and 1 or 0) or v end

local C, A, AT = {}, { 0, 0, 0 }, { 0, 0, 0 }
local U = { flat = false }

local function style_rgb(name, fallback)
	local ok, c = pcall(Menu.Style, name)
	if not ok or type(c) ~= "userdata" and type(c) ~= "table" or not c.r then return fallback end
	return { math.floor(c.r + 0.5), math.floor(c.g + 0.5), math.floor(c.b + 0.5) }
end

local function apply_theme()
	local umbrella = P.set.theme == "umbrella"
	U.flat = umbrella
	for name in pairs(C) do C[name] = nil end
	for name, v in pairs(T_BASE) do T[name] = v end
	for name, v in pairs(THEMES[P.set.theme]) do
		if umbrella then v = style_rgb(UMBRELLA_STYLE[name], v) end
		if T_BASE[name] then T[name] = v else C[name] = { v[1], v[2], v[3] } end
	end
	local a = ACCENTS[P.set.accent]
	if P.set.accent == "umbrella" then a = style_rgb(UMBRELLA_STYLE.accent, a) end
	for i = 1, 3 do
		A[i] = a[i]
		AT[i] = math.floor(a[i] + (255 - a[i]) * 0.35 + 0.5)
	end
end

apply_theme()

local function say(text)
	if K.DEBUG and K.DEBUG() then Log.Write("[" .. K.NAME .. "] " .. text) end
end

local function save(key, value)
	if type(value) == "boolean" then value = value and 1 or 0 end
	if P.saved[key] == value then return end
	P.saved[key] = value
	if type(value) == "number" then
		Config.WriteInt(K.CFG, key, math.floor(value))
	else
		Config.WriteString(K.CFG, key, tostring(value))
	end
end

-- ---------------------------------------------------------------------------
-- assets
-- ---------------------------------------------------------------------------

local asset = { fonts = {}, sizes = {}, size_n = 0, images = {}, dims = {}, budget = 3 }

function asset.font(weight)
	local name = U.flat and "MuseoSansEx" or "Inter"
	local key = name .. weight
	local f = asset.fonts[key]
	if not f then
		f = Render.LoadFont(name, Enum.FontCreate.FONTFLAG_ANTIALIAS, weight)
		asset.fonts[key] = f
	end
	return f
end

function asset.icons()
	local f = asset.fonts.icon
	if not f then
		f = Render.LoadFont("FontAwesomeEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 400)
		asset.fonts.icon = f
	end
	return f
end

function asset.size(font, px, str)
	local by_font = asset.sizes[font]
	if not by_font then
		by_font = {}
		asset.sizes[font] = by_font
	end
	local by_px = by_font[px]
	if not by_px then
		by_px = {}
		by_font[px] = by_px
	end
	local v = by_px[str]
	if not v then
		if asset.size_n >= 6000 then
			asset.sizes, asset.size_n = {}, 0
		end
		v = Render.TextSize(font, px, str)
		by_px[str] = v
		asset.size_n = asset.size_n + 1
	end
	return v
end

function asset.image(path)
	local img = asset.images[path]
	if img == nil then
		if asset.budget <= 0 then return nil end
		asset.budget = asset.budget - 1
		img = Render.LoadImage(path)
		if not img or img == 0 then img = false end
		asset.images[path] = img
	end
	return img or nil
end

function asset.hero(npc_name)
	return asset.image("panorama/images/heroes/icons/" .. npc_name .. "_png.vtex_c")
end

function asset.portrait(npc_name)
	return asset.image("panorama/images/heroes/" .. npc_name .. "_png.vtex_c")
end

function asset.item(item_name)
	return asset.image("panorama/images/items/" .. item_name:gsub("^item_", "") .. "_png.vtex_c")
end

function asset.ability(ability_name)
	return asset.image("panorama/images/spellicons/" .. ability_name .. "_png.vtex_c")
end

-- ---------------------------------------------------------------------------
-- drawing in window units: g.x/g.y is the origin, g.s the scale, g.a the alpha
-- ---------------------------------------------------------------------------

local g = { x = 0, y = 0, s = 1, a = 1, depth = 0, clips = {}, fits = {}, fit_n = 0, wraps = {} }
local hit = { list = {}, hover = nil, clip = nil }

function g.px(x) return math.floor(g.x + x * g.s + 0.5) end
function g.py(y) return math.floor(g.y + y * g.s + 0.5) end
function g.v(x, y) return Vec2(g.px(x), g.py(y)) end
function g.fs(size) return math.max(1, math.floor(size * g.s + 0.5)) end
function g.hair() return math.max(1, math.floor(g.s)) end

function g.origin(x, y)
	g.x, g.y = x, y
end

function g.col(c, a)
	return Color(math.floor(c[1] + 0.5), math.floor(c[2] + 0.5), math.floor(c[3] + 0.5),
		math.floor(clamp((c[4] or 255) * (a or 1) * g.a, 0, 255) + 0.5))
end

function g.r(r, w, h)
	r = r or 0
	if U.flat and r < math.min(w, h) / 2 then return math.min(r, 5) end
	return r
end

function g.rect(x, y, w, h, c, r, a, flags)
	Render.FilledRect(g.v(x, y), g.v(x + w, y + h), g.col(c, a), g.r(r, w, h) * g.s, flags or ROUND)
end

function g.frame(x, y, w, h, c, r, a, t, flags)
	Render.Rect(g.v(x, y), g.v(x + w, y + h), g.col(c, a), g.r(r, w, h) * g.s, flags or ROUND, (t or 1) * g.s)
end

function g.hl(x, y, w, c, a)
	local y0 = g.py(y)
	Render.FilledRect(Vec2(g.px(x), y0), Vec2(g.px(x + w), y0 + g.hair()), g.col(c, a))
end

function g.vl(x, y, h, c, a)
	local x0 = g.px(x)
	Render.FilledRect(Vec2(x0, g.py(y)), Vec2(x0 + g.hair(), g.py(y + h)), g.col(c, a))
end

function g.dot(cx, cy, r, c, a)
	Render.FilledCircle(Vec2(g.x + cx * g.s, g.y + cy * g.s), r * g.s, g.col(c, a), 0, 1, 24)
end

function g.ring(cx, cy, r, c, a, t)
	Render.Circle(Vec2(g.x + cx * g.s, g.y + cy * g.s), r * g.s, g.col(c, a), (t or 1) * g.s, 0, 1, false, 48)
end

function g.width(weight, size, str)
	return asset.size(asset.font(weight), g.fs(size), str).x / g.s
end

function g.text(weight, size, str, x, cy, c, a, align)
	local font, px = asset.font(weight), g.fs(size)
	local ts = asset.size(font, px, str)
	local x0 = g.x + x * g.s
	if align == "r" then x0 = x0 - ts.x elseif align == "c" then x0 = x0 - ts.x / 2 end
	Render.Text(font, px, str, Vec2(math.floor(x0 + 0.5), math.floor(g.y + cy * g.s - ts.y / 2 + 0.5)), g.col(c, a))
	return ts.x / g.s
end

function g.glyph(glyph, size, cx, cy, c, a)
	local font, px = asset.icons(), g.fs(size)
	local ts = asset.size(font, px, glyph)
	Render.Text(font, px, glyph, Vec2(math.floor(g.x + cx * g.s - ts.x / 2 + 0.5), math.floor(g.y + cy * g.s - ts.y / 2 + 0.5)),
		g.col(c, a))
end

function g.chars(str)
	local out = {}
	for _, c in utf8.codes(str) do out[#out + 1] = utf8.char(c) end
	return out
end

function g.fit(weight, size, str, max_w)
	local key = (U.flat and "m" or "i") .. weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. g.s .. ":" .. str
	local out = g.fits[key]
	if out then return out end
	out = str
	if g.width(weight, size, str) > max_w then
		local chars = g.chars(str)
		out = "…"
		for n = #chars - 1, 1, -1 do
			local s = table.concat(chars, "", 1, n):gsub("%s+$", "") .. "…"
			if g.width(weight, size, s) <= max_w then
				out = s
				break
			end
		end
	end
	if g.fit_n >= 3000 then g.fits, g.fit_n = {}, 0 end
	g.fits[key], g.fit_n = out, g.fit_n + 1
	return out
end

function g.wrap(weight, size, str, max_w)
	local key = (U.flat and "m" or "i") .. weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. g.s .. ":" .. str
	local out = g.wraps[key]
	if out then return out end
	out = {}
	local line = ""
	for word in str:gmatch("%S+") do
		local candidate = line == "" and word or line .. " " .. word
		if line ~= "" and g.width(weight, size, candidate) > max_w then
			out[#out + 1] = line
			line = word
		else
			line = candidate
		end
	end
	if line ~= "" then out[#out + 1] = line end
	g.wraps[key] = out
	return out
end

function g.clip(x, y, w, h)
	Render.PushClip(g.v(x, y), g.v(x + w, y + h), true)
	g.depth = g.depth + 1
	g.clips[#g.clips + 1] = hit.clip or false
	local c = { g.x + x * g.s, g.y + y * g.s, g.x + (x + w) * g.s, g.y + (y + h) * g.s }
	local p = hit.clip
	if p then c = { math.max(c[1], p[1]), math.max(c[2], p[2]), math.min(c[3], p[3]), math.min(c[4], p[4]) } end
	hit.clip = c
end

function g.unclip()
	Render.PopClip()
	g.depth = g.depth - 1
	hit.clip = g.clips[#g.clips] or nil
	g.clips[#g.clips] = nil
end

function g.reset()
	for _ = 1, g.depth do Render.PopClip() end
	g.depth, g.clips, g.a, hit.clip = 0, {}, 1, nil
end

function g.shadow(x, y, w, h, r, a)
	if U.flat then return end
	for i = 1, 5 do
		local e = i * 2.5
		g.rect(x - e, y - e + 4, w + e * 2, h + e * 2, T.black, r + e, (a or 0.07) * (1 - (i - 1) / 5))
	end
end

function g.square(img, label, x, y, size, a, r, gray)
	if img then
		local dim = asset.dims[img]
		if not dim then
			dim = Render.ImageSize(img)
			asset.dims[img] = dim
		end
		local u0, v0, u1, v1 = 0, 0, 1, 1
		if dim.x > dim.y and dim.y > 0 then
			local d = (1 - dim.y / dim.x) / 2
			u0, u1 = d, 1 - d
		elseif dim.y > dim.x and dim.x > 0 then
			local d = (1 - dim.x / dim.y) / 2
			v0, v1 = d, 1 - d
		end
		local px = math.floor(size * g.s + 0.5)
		Render.Image(img, g.v(x, y), Vec2(px, px), g.col(T.white, a), g.r(r, size, size) * g.s, ROUND, Vec2(u0, v0), Vec2(u1, v1), gray or 0)
	else
		g.rect(x, y, size, size, T.white, r, 0.10 * (a or 1))
		local first = label and label:sub(1, (utf8.offset(label, 2) or 2) - 1) or "?"
		g.text(700, size * 0.45, first:upper(), x + size / 2, y + size / 2, T.t3, a, "c")
	end
end

-- ---------------------------------------------------------------------------
-- hit testing and animation
-- ---------------------------------------------------------------------------

function hit.begin()
	local prev = hit.list
	hit.list, hit.clip = {}, nil
	local mx, my = Input.GetCursorPos()
	hit.hover = nil
	for i = #prev, 1, -1 do
		local h = prev[i]
		if mx >= h[1] and mx < h[3] and my >= h[2] and my < h[4] then
			hit.hover = h[5]
			break
		end
	end
	if P.press and P.press.id and hit.hover ~= P.press.id then hit.hover = nil end
	if P.drag or P.slide or P.sb_drag then hit.hover = nil end
end

function hit.add(x, y, w, h, id, on)
	local x1, y1, x2, y2 = g.x + x * g.s, g.y + y * g.s, g.x + (x + w) * g.s, g.y + (y + h) * g.s
	if hit.clip then
		x1, y1 = math.max(x1, hit.clip[1]), math.max(y1, hit.clip[2])
		x2, y2 = math.min(x2, hit.clip[3]), math.min(y2, hit.clip[4])
		if x2 <= x1 or y2 <= y1 then return end
	end
	hit.list[#hit.list + 1] = { x1, y1, x2, y2, id, on or {} }
end

function hit.is(id) return hit.hover == id end

function hit.at(mx, my, field)
	for i = #hit.list, 1, -1 do
		local h = hit.list[i]
		if mx >= h[1] and mx < h[3] and my >= h[2] and my < h[4] and (not field or h[6][field]) then return h end
	end
	return nil
end

local anim = {}

function anim.tween(key, target, time, curve)
	local t = P.tweens[key]
	if not t or (t.seen and P.now - t.seen > 0.1) then
		t = { from = target, to = target, v = target, k = 1 }
		P.tweens[key] = t
	end
	t.seen = P.now
	if t.to ~= target then t.from, t.to, t.k = t.v, target, 0 end
	if t.k < 1 then
		t.k = math.min(1, t.k + P.dt / time)
		t.v = t.from + (t.to - t.from) * (curve or ease_out)(t.k)
	else
		t.v = t.to
	end
	return t.v
end

function anim.snap(key, value)
	P.tweens[key] = { from = value, to = value, v = value, k = 1, seen = P.now }
end

function anim.hover(id, on)
	if on == nil then on = hit.hover == id end
	return anim.tween("hv:" .. id, on and 1 or 0, 0.12)
end

function anim.mix(a, b, k)
	return { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k }
end

-- ---------------------------------------------------------------------------
-- widgets (all coordinates in window units, cy = vertical center)
-- ---------------------------------------------------------------------------

local view = {}

function view.icon_button(x, y, size, glyph, id, active, click, danger)
	local hv = anim.hover(id)
	local ak = anim.tween("ib:" .. id, active and 1 or 0, 0.16)
	if U.flat then
		local c = danger and anim.mix(T.knob, T.red, hv) or anim.mix(anim.mix(T.knob, T.t3, hv), A, ak)
		g.glyph(glyph, 11, x + size / 2, y + size / 2, c, 1 - 0.2 * ak)
		hit.add(x, y, size, size, id, { click = click })
		return
	end
	if danger then
		g.rect(x, y, size, size, T.red, 8, 0.16 * hv)
	else
		g.rect(x, y, size, size, T.white, 8, 0.10 * ak + 0.08 * hv * (1 - ak))
	end
	local c = danger and anim.mix(T.t3, T.red, hv) or anim.mix(T.t3, T.t1, math.max(ak, hv))
	g.glyph(glyph, 12, x + size / 2, y + size / 2, c)
	hit.add(x, y, size, size, id, { click = click })
end

function view.button(x, y, w, h, label, kind, id, click)
	local hv = anim.hover(id)
	if U.flat then
		local k = kind == "accent" and 1 or hv
		if hv > 0.01 then g.rect(x - 2, y - 2, w + 4, h + 4, A, 6, 0.10 * hv) end
		g.rect(x, y, w, h, anim.mix(C.menu, A, k), 4)
		g.text(500, 13, label, x + w / 2, y + h / 2, anim.mix(T.t3, T.white, k), 1, "c")
	elseif kind == "accent" then
		g.rect(x, y, w, h, A, h / 2, 0.88 + 0.12 * hv)
		g.text(600, 12.5, label, x + w / 2, y + h / 2, T.white, 1, "c")
	elseif kind == "soft" then
		g.rect(x, y, w, h, T.white, h / 2, 0.10 + 0.05 * hv)
		g.text(600, 12.5, label, x + w / 2, y + h / 2, T.t1, 1, "c")
	else
		g.rect(x, y, w, h, T.white, h / 2, 0.06 * hv)
		g.text(500, 12.5, label, x + w / 2, y + h / 2, anim.mix(T.t3, T.t1, hv), 1, "c")
	end
	hit.add(x, y, w, h, id, { click = click })
end

function view.badge(right, cy, text, c)
	local w = g.width(700, 10, text) + 12
	g.rect(right - w, cy - 8, w, 16, c or A, 8, 0.18)
	g.text(700, 10, text, right - w / 2, cy, c or AT, 1, "c")
	return w
end

function view.card(x, y, w, h)
	g.rect(x, y, w, h, C.card, 10)
end

function view.section(x, y, w, title, count)
	g.rect(x, y + 3, 3, 14, A, 1.5)
	g.text(700, 12.5, title, x + 10, y + 10, T.t1)
	if count ~= nil then view.badge(x + w, y + 10, tostring(count)) end
	return 22
end

function view.caption(x, y, w, text, count)
	local wt = U.flat and 500 or 600
	local cw = count ~= nil and g.text(wt, 11.5, tostring(count), x + w, y + 7, T.t4, nil, "r") + 8 or 0
	g.text(wt, 11.5, g.fit(wt, 11.5, text, w - cw), x, y + 7, T.t3)
	return 22
end

function view.switch(x, cy, on, id, click, mini)
	local k = anim.tween("sw:" .. id, on and 1 or 0, 0.18, ease_in_out)
	if U.flat then
		local w, h = mini and 18 or 26, mini and 11 or 14
		g.rect(x, cy - h / 2, w, h, anim.mix(C.off, A, k), h / 2, 1 - 0.2 * k)
		g.dot(x + h / 2 + (w - h) * k, cy, h / 2 - 3, anim.mix(T.knob, C.win, k))
		hit.add(x - 4, cy - h / 2 - 4, w + 8, h + 8, id, { click = click })
		return
	end
	local w, h = mini and 24 or 34, mini and 14 or 20
	g.rect(x, cy - h / 2, w, h, anim.mix(C.off, A, k), h / 2)
	g.dot(x + h / 2 + (w - h) * k, cy, h / 2 - 2, anim.mix(T.knob, T.white, k))
	hit.add(x - 4, cy - h / 2 - 4, w + 8, h + 8, id, { click = click })
end

function view.toggle_row(x, y, w, label, on, id, click, sub)
	local hv = anim.hover(id)
	if U.flat then
		local h = sub and 40 or 28
		if sub then
			g.text(500, 12.5, g.fit(500, 12.5, label, w - 50), x + 10, y + 13, anim.mix(T.t3, T.t1, hv))
			g.text(500, 11, g.fit(500, 11, sub, w - 50), x + 10, y + 28, T.t4)
		else
			g.text(500, 12.5, g.fit(500, 12.5, label, w - 50), x + 10, y + h / 2, anim.mix(T.t3, T.t1, hv))
		end
		view.switch(x + w - 36, y + h / 2, on, id .. ":sw", click)
		hit.add(x, y, w - 40, h, id, { click = click })
		return h
	end
	local h = sub and 44 or 36
	g.rect(x, y, w, h, T.white, 8, 0.04 * hv)
	if sub then
		g.text(600, 12.5, g.fit(600, 12.5, label, w - 70), x + 10, y + 15, T.t1)
		g.text(500, 11, g.fit(500, 11, sub, w - 70), x + 10, y + 31, T.t3)
	else
		g.text(600, 12.5, g.fit(600, 12.5, label, w - 70), x + 10, y + h / 2, T.t1)
	end
	view.switch(x + w - 44, y + h / 2, on, id .. ":sw", click)
	hit.add(x, y, w - 50, h, id, { click = click })
	return h
end

function view.slider(x, cy, w, id, value, min, max, step, on_change, on_done, fmt)
	local v = clamp((value - min) / (max - min), 0, 1)
	local hot = hit.is(id) or (P.slide ~= nil and P.slide.id == id)
	local label = fmt and string.format(fmt, value) or tostring(value)
	local lw = 44
	local tx, tw = x, w - lw - 8
	local th, kr = U.flat and 5 or 4, U.flat and (hot and 6.5 or 5.5) or (hot and 8.5 or 7.5)
	g.rect(tx, cy - th / 2, tw, th, C.off, th / 2)
	if v > 0 then g.rect(tx, cy - th / 2, tw * v, th, A, th / 2) end
	g.dot(tx + tw * v, cy, kr, T.white)
	g.text(U.flat and 500 or 600, 12, label, x + w, cy, T.t3, 1, "r")
	local ax, aw = g.x + tx * g.s, tw * g.s
	hit.add(tx - 10, cy - 14, tw + 20, 28, id, { down = function(mx)
		P.slide = { id = id, x = ax, w = aw, min = min, max = max, step = step or 1,
			change = on_change, done = on_done, value = value }
		view.slide_to(mx)
	end })
end

function view.slide_to(mx)
	local sl = P.slide
	local v = clamp((mx - sl.x) / sl.w, 0, 1)
	local value = sl.min + math.floor((sl.max - sl.min) * v / sl.step + 0.5) * sl.step
	if value ~= sl.value then
		sl.value = value
		if sl.change then sl.change(value) end
	end
end

function view.tabs(x, y, w, labels, cur, pick, id)
	id = id or "tabs"
	local seg = w / #labels
	g.rect(x, y, w, 32, T.white, 9, 0.055)
	local hx = anim.tween(id .. ":x", cur - 1, 0.22, ease_in_out)
	g.rect(x + 2 + hx * seg, y + 2, seg - 4, 28, A, 7, 0.26)
	for i, label in ipairs(labels) do
		local tid = id .. ":" .. i
		local hv = anim.hover(tid)
		local on = i == cur
		local c = on and T.white or anim.mix(T.t3, T.t1, hv)
		g.text(on and 700 or 600, 12, g.fit(600, 12, label, seg - 10), x + (i - 0.5) * seg, y + 16, c, 1, "c")
		hit.add(x + (i - 1) * seg, y, seg, 32, tid, { click = function()
			if i ~= cur then pick(i) end
		end })
	end
	return 32
end

function view.row(x, y, w, h, o)
	local hv = o.id and anim.hover(o.id) or 0
	local sel = anim.tween("row_sel:" .. (o.id or ""), o.selected and 1 or 0, 0.14)
	if sel > 0.01 then g.rect(x, y, w, h, A, 8, 0.16 * sel) end
	if hv > 0.01 then g.rect(x, y, w, h, T.white, 8, 0.05 * hv) end
	local tx = x + 10
	local icon = math.min(h - 10, 28)
	if o.img or o.img_label then
		g.square(o.img, o.img_label or o.title, tx, y + (h - icon) / 2, icon, 1, 6, o.gray and 1 or 0)
		tx = tx + icon + 10
	elseif o.glyph then
		g.glyph(o.glyph, 13, tx + 8, y + h / 2, o.glyph_c or T.t3)
		tx = tx + 26
	end
	local vw = 0
	if o.value then
		vw = g.text(700, 12.5, o.value, x + w - 10, y + h / 2, o.value_c or T.t1, 1, "r") + 12
	end
	local max_w = x + w - 10 - vw - tx
	if o.sub then
		g.text(600, 12.5, g.fit(600, 12.5, o.title, max_w), tx, y + h / 2 - 8, T.t1)
		g.text(500, 11, g.fit(500, 11, o.sub, max_w), tx, y + h / 2 + 8, T.t3)
	else
		g.text(600, 12.5, g.fit(600, 12.5, o.title, max_w), tx, y + h / 2, T.t1)
	end
	if o.id then hit.add(x, y, w, h, o.id, { click = o.click, rclick = o.rclick }) end
	return h
end

function view.grid(x, y, w, items, size, gap, id, click)
	size, gap = size or 32, gap or 6
	local per_row = math.max(1, math.floor((w + gap) / (size + gap)))
	for i, it in ipairs(items) do
		local col, row = (i - 1) % per_row, (i - 1) // per_row
		local ix, iy = x + col * (size + gap), y + row * (size + gap)
		local cid = id .. ":" .. tostring(it.key)
		local hv = anim.hover(cid)
		local on = it.on ~= false
		local k = anim.tween("gr:" .. cid, on and 1 or 0, 0.14)
		local r = U.flat and 2 or 8
		g.square(it.img, it.label, ix, iy, size, 0.45 + 0.55 * math.max(k, hv * 0.6), r, 1 - k)
		if k > 0.01 and not U.flat then g.frame(ix, iy, size, size, A, r, k, 1.5) end
		if hv > 0.01 and (U.flat or k < 0.99) then g.frame(ix, iy, size, size, T.white, r, 0.25 * hv) end
		if it.dot then g.dot(ix + size - 4, iy + 4, 3.5, it.dot) end
		hit.add(ix, iy, size, size, cid, { click = function() click(it, i) end })
		if it.label then view.hint(cid, it.label) end
	end
	local rows = math.max(1, math.ceil(#items / per_row))
	return rows * (size + gap) - gap
end

function view.status(x, cy, w, glyph, text, c)
	c = c or T.t3
	local tx = x
	if glyph then
		g.glyph(glyph, 11, x + 6, cy, c)
		tx = x + 18
	end
	g.text(500, 11.5, g.fit(500, 11.5, text, w - (tx - x)), tx, cy, c)
end

function view.empty(x, y, w, h, glyph, text)
	g.glyph(glyph or K.G.empty, 20, x + w / 2, y + h / 2 - 12, T.t4)
	local lines = g.wrap(500, 12, text, w - 32)
	for i = 1, math.min(3, #lines) do
		g.text(500, 12, lines[i], x + w / 2, y + h / 2 + 10 + (i - 1) * 16, T.t3, 1, "c")
	end
end

function view.swatches(right, cy, order, cur, color, pick, prefix)
	local size, gap = 18, 8
	local x = right - (#order * size + (#order - 1) * gap)
	for i, id in ipairs(order) do
		local key = prefix .. id
		local hv = anim.hover(key)
		local on = anim.tween("swt:" .. key, cur == id and 1 or 0, 0.16)
		local sx = x + (i - 1) * (size + gap) + size / 2
		g.dot(sx, cy, size / 2 - 1 + 0.8 * hv, color(id))
		g.ring(sx, cy, size / 2 - 1, T.white, 0.14, 1)
		if on > 0.01 then g.ring(sx, cy, size / 2 + 3, T.white, 0.85 * on, 1.5) end
		hit.add(sx - size / 2 - gap / 2, cy - size / 2 - 4, size + gap, size + 8, key, { click = function() pick(id) end })
	end
end

function view.theme_settings(x, y, w, labels)
	local rows = 0
	if not K.SMALL then
		g.text(600, 12.5, labels.theme, x, y + 14, T.t2)
		view.swatches(x + w, y + 14, THEME_ORDER, P.set.theme, function(id) return THEMES[id].card end, function(id)
			P.set.theme = id
			apply_theme()
			save("theme", id)
		end, "th:")
		g.text(600, 12.5, labels.accent, x, y + 46, T.t2)
		view.swatches(x + w, y + 46, ACCENT_ORDER, P.set.accent, function(id) return ACCENTS[id] end, function(id)
			P.set.accent = id
			apply_theme()
			save("accent", id)
		end, "ac:")
		rows = 64
	end
	g.text(600, 12.5, labels.scale, x, y + rows + 14, T.t2)
	view.slider(x + w * 0.42, y + rows + 14, w * 0.58, "set_scale", P.set.scale, 70, 150, 5,
		function(v) P.set.scale = v end, function(v) save("scale", v) end, "%d%%")
	g.text(600, 12.5, labels.opacity, x, y + rows + 46, T.t2)
	view.slider(x + w * 0.42, y + rows + 46, w * 0.58, "set_opacity", P.set.opacity, 40, 100, 5,
		function(v) P.set.opacity = v end, function(v) save("opacity", v) end, "%d%%")
	return rows + 64
end

-- ---------------------------------------------------------------------------
-- dropdown: the field is drawn in place, the open list is drawn last, above everything
-- ---------------------------------------------------------------------------

function view.dropdown(x, y, w, id, options, cur, pick)
	local did = "dd:" .. id
	local open = P.menu == id
	local hv = anim.hover(did)
	local k = anim.tween("dd_on:" .. id, open and 1 or 0, 0.16)
	g.rect(x, y, w, 28, C.menu, 7)
	local fa = 0.14 * hv + (0.18 - 0.14 * hv) * k
	if fa > 0.005 then g.frame(x, y, w, 28, T.white, 7, fa) end
	local label = "?"
	for _, o in ipairs(options) do
		if o.value == cur then label = o.label end
	end
	g.text(500, 12, g.fit(500, 12, label, w - 34), x + 10, y + 14, T.t2)
	g.glyph(open and K.G.up or K.G.down, 9, x + w - 14, y + 14, T.t3)
	hit.add(x, y, w, 28, did, { click = function() P.menu = open and nil or id end })
	if open or k > 0.01 then
		P.menu_req = { x = g.x + x * g.s, y = g.y + (y + 32) * g.s, w = w, id = id, options = options, cur = cur, pick = pick, k = k }
	end
end

function view.draw_menu()
	local m = P.menu_req
	P.menu_req = nil
	if not m or m.k <= 0.01 then return end
	local ox, oy, oa = g.x, g.y, g.a
	g.x, g.y = m.x, m.y
	g.a = oa * m.k
	local h = 8 + #m.options * 28
	local dy = -6 * (1 - m.k)
	g.shadow(0, dy, m.w, h, 8, 0.10)
	g.rect(0, dy, m.w, h, C.menu, 8)
	g.frame(0, dy, m.w, h, T.white, 8, 0.10)
	hit.add(0, dy, m.w, h, "menu:" .. m.id .. ":bg")
	for i, o in ipairs(m.options) do
		local oid = "menu:" .. m.id .. ":" .. tostring(o.value)
		local iy = dy + 4 + (i - 1) * 28
		local hv = anim.hover(oid)
		g.rect(4, iy, m.w - 8, 28, T.white, 5, 0.08 * hv)
		local on = o.value == m.cur
		g.text(on and 600 or 500, 12, g.fit(500, 12, o.label, m.w - 36), 12, iy + 14, on and AT or T.t2)
		if on then g.glyph(K.G.check, 10, m.w - 16, iy + 14, AT) end
		if P.menu == m.id then
			hit.add(4, iy, m.w - 8, 28, oid, { click = function()
				P.menu = nil
				if o.value ~= m.cur then m.pick(o.value) end
			end })
		end
	end
	g.x, g.y, g.a = ox, oy, oa
end

-- ---------------------------------------------------------------------------
-- scroll areas (one state per id; wheel and a draggable thumb)
-- ---------------------------------------------------------------------------

function view.scroll_begin(id, x, y, w, h)
	local s = P.scroll[id]
	if not s then
		s = { f = 0, to = 0, v = 0, content = 0, view = h, t = -10 }
		P.scroll[id] = s
	end
	s.view, s.area = h, { x, y, w, h }
	local diff = s.to - s.f
	if math.abs(diff) * g.s < 0.5 then s.f = s.to else s.f = s.f + diff * (1 - math.exp(-P.dt * 18)) end
	s.v = math.floor(s.f * g.s + 0.5) / g.s
	hit.add(x, y, w, h, "scroll:" .. id, { wheel = function(dir)
		s.n = (P.now - (s.wt or -10) < 0.12) and math.min((s.n or 0) + 1, 6) or 0
		s.wt = P.now
		s.to = clamp(s.to + dir * K.WHEEL * (1 + s.n * 0.25), 0, math.max(0, s.content - s.view))
		s.t = P.now
	end })
	g.clip(x, y, w, h)
	return y - s.v
end

function view.scroll_end(id, content_h)
	local s = P.scroll[id]
	g.unclip()
	s.content = content_h
	local max_scroll = math.max(0, content_h - s.view)
	if s.to > max_scroll then s.to, s.f, s.v = max_scroll, max_scroll, max_scroll end
	local ax, ay, aw, ah = s.area[1], s.area[2], s.area[3], s.area[4]
	local ta = clamp(s.v / 14, 0, 1)
	if ta > 0.01 then g.hl(ax + 10, ay, aw - 20, T.white, 0.08 * ta) end
	if max_scroll <= 0 then return end
	local track = ah - 8
	local thumb = math.max(24, track * s.view / content_h)
	local span = math.max(1, track - thumb)
	local top = ay + 4 + span * clamp(s.v / max_scroll, 0, 1)
	local sid = "sb:" .. id
	local hot = hit.is(sid) or (P.sb_drag ~= nil and P.sb_drag.id == id)
	local sa = anim.tween(sid, (hot or P.now - s.t < 0.9) and 1 or 0, 0.2)
	if sa > 0.01 then
		local bw = hot and 5 or 3
		g.rect(ax + aw - bw - 2, top, bw, thumb, T.white, bw / 2, (hot and 0.42 or 0.24) * sa)
	end
	hit.add(ax + aw - 12, ay + 4, 12, track, sid, { down = function(_, my)
		P.sb_drag = { id = id, my = my, v = s.v, k = max_scroll / span }
		s.t = P.now
	end })
end

function view.scroll_drag(my)
	local d = P.sb_drag
	local s = P.scroll[d.id]
	if not s then return end
	local v = clamp(d.v + (my - d.my) / g.s * d.k, 0, math.max(0, s.content - s.view))
	s.to, s.f, s.v, s.t = v, v, v, P.now
end

-- ---------------------------------------------------------------------------
-- hover hints and toasts (screen space, drawn after the window)
-- ---------------------------------------------------------------------------

function view.hint(id, text)
	if hit.is(id) then P.tip_req = { id = id, text = text } end
end

function view.draw_tip()
	local req = P.tip_req
	P.tip_req = nil
	local id = req and req.id
	if id ~= P.tip_id then P.tip_id, P.tip_since = id, P.now end
	if not req or P.drag or P.slide or P.press then return end
	local k = clamp((P.now - P.tip_since - K.TIP_DELAY) / 0.12, 0, 1)
	if k <= 0 then return end
	local ox, oy, oa = g.x, g.y, g.a
	g.x, g.y, g.a = 0, 0, k
	local mx, my = Input.GetCursorPos()
	local screen = Render.ScreenSize()
	local w = g.width(600, 12, req.text) + 20
	local x = clamp(mx / g.s - w / 2, 4, screen.x / g.s - w - 4)
	local y = my / g.s + 22
	if (y + 30) * g.s > screen.y then y = my / g.s - 36 end
	g.rect(x, y, w, 26, C.menu, 7)
	g.frame(x, y, w, 26, T.white, 7, 0.12)
	g.text(600, 12, req.text, x + 10, y + 13, T.t1)
	g.x, g.y, g.a = ox, oy, oa
end

function view.toast(text, kind)
	table.insert(P.toasts, 1, { text = text, kind = kind or "info", t = P.now, id = tostring(P.now) .. text })
	while #P.toasts > 4 do table.remove(P.toasts) end
end

function view.draw_toasts()
	if #P.toasts == 0 then return end
	local ox, oy, oa = g.x, g.y, g.a
	local screen = Render.ScreenSize()
	g.x, g.y = 0, 0
	local w = 280
	local x = screen.x / g.s - w - 20
	local y = screen.y / g.s - 90
	for i = #P.toasts, 1, -1 do
		local t = P.toasts[i]
		local age = P.now - t.t
		if age > K.TOAST_TIME + 0.3 or t.closed then table.remove(P.toasts, i) end
	end
	for i, t in ipairs(P.toasts) do
		local age = P.now - t.t
		local k = math.min(1, age / 0.18) * clamp((K.TOAST_TIME + 0.3 - age) / 0.3, 0, 1)
		local target = (i - 1) * 50
		t.slide = t.slide and t.slide + (target - t.slide) * (1 - math.exp(-P.dt * 14)) or target
		local ty = y - t.slide + (1 - k) * 10
		g.a = k
		local c = t.kind == "ok" and T.green or (t.kind == "error" and T.red or (t.kind == "warn" and T.yellow or A))
		local glyph = t.kind == "ok" and K.G.ok or ((t.kind == "error" or t.kind == "warn") and K.G.warn or K.G.info)
		g.shadow(x, ty, w, 42, 10, 0.10)
		g.rect(x, ty, w, 42, C.win, 10, 0.97)
		g.frame(x, ty, w, 42, T.white, 10, 0.10)
		g.glyph(glyph, 13, x + 20, ty + 21, c)
		g.text(500, 12.5, g.fit(500, 12.5, t.text, w - 48), x + 36, ty + 21, T.t1)
		hit.add(x, ty, w, 42, "toast:" .. t.id, { click = function() t.closed = true end })
	end
	g.x, g.y, g.a = ox, oy, oa
end

-- ---------------------------------------------------------------------------
-- on-screen pill (small overlays: icon on the left, short text, dark rounded capsule)
-- ---------------------------------------------------------------------------

function view.pill(x, cy, o)
	local h = 26
	local tw = o.text and g.width(700, 12, o.text) or 0
	local dw = o.detail and (g.width(500, 11, o.detail) + 17) or 0
	local w = h + (tw > 0 and tw + 10 or 0) + dw + (tw > 0 and 10 or 0)
	local y = cy - h / 2
	g.rect(x, y, w, h, { 14, 16, 18 }, h / 2, 0.72)
	local isz = h - 6
	if o.img then
		g.square(o.img, o.text, x + 3, y + 3, isz, 1, isz / 2, o.gray and 1 or 0)
	elseif o.glyph then
		g.glyph(o.glyph, 11, x + h / 2, cy, o.c or T.t1)
	end
	local tx = x + h + 4
	if tw > 0 then
		g.text(700, 12, o.text, tx, cy, o.c or T.t1)
		tx = tx + tw + 8
	end
	if dw > 0 then
		g.vl(tx, cy - 7, 14, T.white, 0.18)
		g.text(500, 11, o.detail, tx + 8, cy, T.t3)
	end
	if o.id then hit.add(x, y, w, h, o.id, { click = o.click }) end
	return w
end

-- ---------------------------------------------------------------------------
-- text input: typed text comes from a hidden Panorama TextEntry (any layout, Cyrillic, Ctrl+V)
-- ---------------------------------------------------------------------------

local JS_SINK = [[
(function () {
	let root = $.GetContextPanel();
	while (root.GetParent()) root = root.GetParent();
	let sink = root.FindChild('%s');
	const drop = () => {
		sink.text = '';
		sink.DeleteAsync(0);
	};
	if (%s) {
		if (!sink) {
			sink = $.CreatePanel('TextEntry', root, '%s');
			sink.style.width = '1px';
			sink.style.height = '1px';
			sink.style.opacity = '0';
			sink.hittest = false;
			sink.SetPanelEvent('ontextentrychange', () => {
				if (!sink.IsValid() || sink.text === '') return;
				const typed = sink.GetAttributeString('typed', '') + sink.text;
				sink.text = '';
				sink.SetAttributeString('typed', typed);
			});
			const watch = () => {
				if (!sink.IsValid()) return;
				if (Date.now() - Number(sink.GetAttributeString('alive', '0')) > %d) return drop();
				$.Schedule(0.25, watch);
			};
			$.Schedule(0.25, watch);
		}
		sink.SetAttributeString('alive', String(Date.now()));
		sink.text = '';
		sink.SetFocus();
	} else if (sink) {
		drop();
	}
})();
]]

local CHARS = {}
for i = 0, 25 do
	local letter = string.char(65 + i)
	CHARS[KEY["KEY_" .. letter]] = letter:lower()
end
for i = 0, 9 do CHARS[KEY["KEY_" .. i]] = tostring(i) end
CHARS[KEY.KEY_SPACE] = " "

local edit = { sink_on = false, sink_at = 0, typed_ok = false, pend = {}, pend_t = 0, panel = nil, find_at = -10 }

function edit.sink(on, force)
	if edit.sink_on == on and not force and not (on and P.now >= edit.sink_at) then return end
	edit.sink_on, edit.sink_at = on, P.now + K.SINK_ALIVE
	Engine.RunScript(JS_SINK:format(K.SINK_ID, on and "true" or "false", K.SINK_ID, K.SINK_TIMEOUT))
end

function edit.field(f)
	f.text = f.text or ""
	f.caret = f.caret or #g.chars(f.text)
	return f
end

function edit.range(f)
	if f.anchor and f.anchor ~= f.caret then return math.min(f.anchor, f.caret), math.max(f.anchor, f.caret) end
	return nil
end

function edit.put(f, chars, caret)
	f.text, f.caret, f.anchor = table.concat(chars), caret, nil
	f.blink = P.now
	if f.on_change then f.on_change(f.text) end
end

function edit.cut(f, chars)
	local lo, hi = edit.range(f)
	if not lo then return chars, f.caret end
	local out = {}
	for i = 1, lo do out[#out + 1] = chars[i] end
	for i = hi + 1, #chars do out[#out + 1] = chars[i] end
	return out, lo
end

function edit.insert(f, str)
	local chars, caret = edit.cut(f, g.chars(f.text))
	if #chars >= (f.max or 64) then return end
	table.insert(chars, caret + 1, str)
	edit.put(f, chars, caret + 1)
end

local function is_gap(c) return c == " " end

function edit.word_left(chars, i)
	while i > 0 and is_gap(chars[i]) do i = i - 1 end
	while i > 0 and not is_gap(chars[i]) do i = i - 1 end
	return i
end

function edit.word_right(chars, i)
	local n = #chars
	while i < n and is_gap(chars[i + 1]) do i = i + 1 end
	while i < n and not is_gap(chars[i + 1]) do i = i + 1 end
	return i
end

function edit.erase(f, forward, word)
	local chars = g.chars(f.text)
	if not edit.range(f) then
		local a, b = f.caret, f.caret
		if forward then
			b = word and edit.word_right(chars, f.caret) or math.min(#chars, f.caret + 1)
		else
			a = word and edit.word_left(chars, f.caret) or math.max(0, f.caret - 1)
		end
		if a == b then return end
		f.anchor, f.caret = a, b
	end
	local out, caret = edit.cut(f, chars)
	edit.put(f, out, caret)
end

function edit.move(f, to, shift)
	if shift then f.anchor = f.anchor or f.caret else f.anchor = nil end
	f.caret, f.blink = to, P.now
end

function edit.focus(f, id)
	if P.focus == f then return end
	P.focus, P.focus_id = f, id
	edit.pend = {}
	edit.sink(f ~= nil, true)
end

function edit.blur()
	if not P.focus then return end
	P.focus, P.focus_id = nil, nil
	edit.pend = {}
	edit.sink(false, true)
end

function edit.key(key)
	local f = P.focus
	if not f then return end
	local ctrl = Input.IsKeyDown(KEY.KEY_LCONTROL) or Input.IsKeyDown(KEY.KEY_RCONTROL)
	local shift = Input.IsKeyDown(KEY.KEY_LSHIFT) or Input.IsKeyDown(KEY.KEY_RSHIFT)
	local chars = g.chars(f.text)
	local n = #chars
	local lo, hi = edit.range(f)
	if ctrl and key == KEY.KEY_A then
		f.anchor, f.caret = 0, n
	elseif key == KEY.KEY_LEFT then
		if lo and not shift then edit.move(f, lo, false) else edit.move(f, ctrl and edit.word_left(chars, f.caret) or math.max(0, f.caret - 1), shift) end
	elseif key == KEY.KEY_RIGHT then
		if hi and not shift then edit.move(f, hi, false) else edit.move(f, ctrl and edit.word_right(chars, f.caret) or math.min(n, f.caret + 1), shift) end
	elseif key == KEY.KEY_HOME then
		edit.move(f, 0, shift)
	elseif key == KEY.KEY_END then
		edit.move(f, n, shift)
	elseif key == KEY.KEY_BACKSPACE then
		edit.erase(f, false, ctrl)
	elseif key == KEY.KEY_DELETE then
		edit.erase(f, true, ctrl)
	elseif key == KEY.KEY_ESCAPE then
		if lo then f.anchor = nil else edit.blur() end
	elseif key == KEY.KEY_ENTER or key == KEY.KEY_PAD_ENTER then
		if f.on_enter then f.on_enter(f.text) end
		edit.blur()
	elseif not ctrl and CHARS[key] and not edit.typed_ok then
		edit.pend[#edit.pend + 1] = shift and CHARS[key]:upper() or CHARS[key]
		edit.pend_t = P.now
	end
end

function edit.poll()
	local f = P.focus
	if not f then return end
	local p = edit.panel
	if not p or not p:IsValid() then
		edit.panel = nil
		if P.now - edit.find_at < 0.2 then return end
		edit.find_at = P.now
		p = Panorama.GetPanelByName(K.SINK_ID, false)
		if not p then return end
		edit.panel = p
	end
	local typed = p:GetAttribute("typed", "")
	if type(typed) == "string" and typed ~= "" then
		p:SetAttribute("typed", "")
		edit.typed_ok, edit.pend = true, {}
		local clean = typed:gsub("%c", "")
		pcall(function()
			for _, ch in utf8.codes(clean) do edit.insert(f, utf8.char(ch)) end
		end)
	elseif #edit.pend > 0 and P.now - edit.pend_t > 0.08 then
		for _, ch in ipairs(edit.pend) do edit.insert(f, ch) end
		edit.pend = {}
	end
end

function view.input(x, y, w, id, f, placeholder, glyph)
	edit.field(f)
	local h = 32
	local focused = P.focus == f
	local fa = anim.tween("in_f:" .. id, focused and 1 or 0, 0.16)
	g.rect(x, y, w, h, T.white, 9, 0.06 + 0.04 * fa)
	if fa > 0.01 then g.frame(x, y, w, h, A, 9, 0.6 * fa) end
	local tx = x + 10
	if glyph then
		g.glyph(glyph, 12, x + 16, y + h / 2, anim.mix(T.t3, T.t1, fa))
		tx = x + 30
	end
	local maxw = x + w - 10 - tx
	local chars = g.chars(f.text)
	local widths = { [0] = 0 }
	for i = 1, #chars do widths[i] = g.width(400, 13, table.concat(chars, "", 1, i)) end
	local caret_x = widths[f.caret] or widths[#chars]
	f.off = f.off or 0
	if caret_x - f.off > maxw then f.off = caret_x - maxw elseif caret_x < f.off then f.off = caret_x end
	f.off = clamp(f.off, 0, math.max(0, widths[#chars] - maxw))
	g.clip(tx - 2, y, maxw + 4, h)
	if f.text == "" and placeholder then g.text(400, 13, placeholder, tx, y + h / 2, T.t4) end
	local lo, hi = edit.range(f)
	if focused and lo then g.rect(tx + widths[lo] - f.off, y + 8, widths[hi] - widths[lo], 16, A, 3, 0.45) end
	if f.text ~= "" then g.text(400, 13, f.text, tx - f.off, y + h / 2, T.t1) end
	if focused then
		local t = P.now - (f.blink or 0)
		local blink = t < 0.5 and 1 or (math.cos((t - 0.5) * math.pi * 2) + 1) / 2
		g.rect(tx + caret_x - f.off, y + 8, 1.5, 16, T.t1, 0, blink)
	end
	g.unclip()
	local gx, gs = g.x, g.s
	hit.add(x, y, w, h, id, { down = function(mx)
		edit.focus(f, id)
		local lx = (mx - gx) / gs - tx + f.off
		local best = #chars
		for k = 1, #chars do
			if lx < (widths[k - 1] + widths[k]) / 2 then
				best = k - 1
				break
			end
		end
		edit.move(f, best, false)
	end })
	return h
end

-- ---------------------------------------------------------------------------
-- window: position, fade, drag, fold, close; body is drawn by the script
-- ---------------------------------------------------------------------------

function view.home()
	local screen = Render.ScreenSize()
	local wx, wy = Config.ReadInt(K.CFG, "wx", -1), Config.ReadInt(K.CFG, "wy", -1)
	if wx < 0 or wy < 0 or wx > screen.x - 40 or wy > screen.y - 40 then
		wx, wy = math.floor(screen.x * 0.5 - K.W * g.s / 2), math.floor(screen.y * 0.18)
	end
	P.wx, P.wy = wx, wy
	P.saved.wx, P.saved.wy = wx, wy
end

function view.reset_pos()
	save("wx", -1)
	save("wy", -1)
	P.wx = nil
end

function view.fold()
	P.set.collapsed = not P.set.collapsed
	save("collapsed", P.set.collapsed)
	if P.set.collapsed then P.menu = nil end
end

-- side docking (K.SMALL and K.DOCK): a window that touches the left or right
-- screen wall can slide into it, leaving a small tab with a chevron
function view.edge()
	if not (K.SMALL and K.DOCK) or not P.wx then return nil end
	local sw = Render.ScreenSize().x
	if P.wx <= K.SNAP then return -1 end
	if P.wx + K.W * g.s >= sw - K.SNAP then return 1 end
	return nil
end

function view.pin()
	local edge = view.edge()
	if edge then P.wx = edge < 0 and 0 or math.floor(Render.ScreenSize().x - K.W * g.s) end
	return edge
end

function view.side()
	return P.wx + K.W * g.s / 2 > Render.ScreenSize().x / 2 and 1 or -1
end

function view.dock(on)
	if on == nil then on = not P.set.docked end
	if on and not view.edge() then
		P.wx = view.side() < 0 and 0 or math.floor(Render.ScreenSize().x - K.W * g.s)
		save("wx", P.wx)
	end
	P.set.docked = on and view.edge() ~= nil
	save("docked", P.set.docked)
	if P.set.docked then
		P.menu = nil
		edit.blur()
	end
end

function view.dock_tab(o, edge, d)
	local tw, th = 26 + (o.tab_w or 0), U.flat and K.HEAD or 22
	local sw = Render.ScreenSize().x
	g.origin(edge > 0 and sw - tw * g.s or 0, P.wy)
	g.a = P.alpha * d
	local flags = edge > 0 and Enum.DrawFlags.RoundCornersLeft or Enum.DrawFlags.RoundCornersRight
	g.shadow(0, 0, tw, th, 6, 0.07)
	g.rect(0, 0, tw, th, C.win, 6, P.set.opacity / 100, flags)
	if C.line then g.frame(0, 0, tw, th, C.line, 6, 1, 1, flags) else g.frame(0, 0, tw, th, T.white, 6, 0.09, 1, flags) end
	hit.add(0, 0, tw, th, "dock_tab", {
		down = function(mx, my) P.drag, P.moved = { mx = mx, my = my, wx = P.wx, wy = P.wy, lock = true }, false end,
	})
	local cx = edge > 0 and 10 or tw - 10
	local cc = U.flat and T.knob or T.t3
	g.glyph(edge > 0 and K.G.left or K.G.right, 11, cx, th / 2, anim.mix(cc, T.t2, anim.hover("btn_undock")))
	hit.add(edge > 0 and 0 or tw - 22, 0, 22, th, "btn_undock", { click = function() view.dock(false) end })
	if o.tab then o.tab(edge > 0 and 22 or 4, th / 2) end
end

function view.close()
	P.open = false
	P.menu = nil
	edit.blur()
	if K.ON_CLOSE then K.ON_CLOSE() end
end

function view.flat_head(o, W, edge)
	local H, bs = K.HEAD, K.HEAD - 6
	local by = (H - bs) / 2
	hit.add(0, 0, W, H, "drag", {
		down = function(mx, my) P.drag, P.moved = { mx = mx, my = my, wx = P.wx, wy = P.wy }, false end,
		dbl = view.fold,
	})
	local dock = K.SMALL and K.DOCK and edge
	local side = dock and edge or -1
	local glyph, click, lit = P.set.collapsed and K.G.down or K.G.left, view.fold, not P.set.collapsed
	if dock then glyph, click, lit = side > 0 and K.G.right or K.G.left, function() view.dock(true) end, true end
	local x, right = 6, W - 6
	if side > 0 then
		view.icon_button(x, by, bs, glyph, "btn_head", lit, click)
		x = x + bs + 2
	else
		right = right - bs
		view.icon_button(right, by, bs, glyph, "btn_head", lit, click)
	end
	if o.switch then
		view.switch(x + 2, H / 2, o.switch.on, o.switch.id or "head_sw", o.switch.click, true)
		x = x + 26
	end
	for _, b in ipairs(o.buttons or {}) do
		view.icon_button(x, by, bs, b.glyph, b.id, b.active, b.click)
		x = x + bs + 2
	end
	local room = 2 * math.min(W / 2 - x - 4, right - W / 2 - 4)
	g.text(500, 13, g.fit(500, 13, o.title, room), W / 2, H / 2, T.t2, nil, "c")
end

function view.window(o)
	g.s = P.set.scale / 100
	if not P.wx then view.home() end
	local W = K.W
	local edge = P.drag and view.edge() or view.pin()
	local d = anim.tween("dock", P.set.docked and edge and 1 or 0, 0.22, ease_in_out)
	if edge and d > 0.01 then view.dock_tab(o, edge, d) end
	if d > 0.99 then return end
	local fold = anim.tween("fold", P.set.collapsed and 0 or 1, 0.22, ease_in_out)
	local body_h = o.body_h or 0
	local flat = U.flat
	local gap = flat and body_h > 0 and 4 or 0
	local h = K.HEAD + math.floor((body_h + gap) * fold + 0.5)
	local top = K.HEAD + gap
	P.h = h
	g.origin(P.wx + (edge or 0) * d * (W + 8) * g.s, P.wy)
	g.a = P.alpha * (1 - d)
	local opacity = P.set.opacity / 100
	local R = K.SMALL and 10 or 14
	hit.add(0, 0, W, h, "win")
	if opacity < 1 then Render.Blur(g.v(0, 0), g.v(W, h), P.alpha, 1.0, g.r(R, W, h) * g.s, ROUND) end
	if flat then
		g.rect(0, 0, W, K.HEAD, C.win, R, opacity)
		g.frame(0, 0, W, K.HEAD, C.line, R)
		if h > top + 0.5 and not o.bare then
			g.rect(0, top, W, h - top, C.win, R, opacity)
			g.frame(0, top, W, h - top, C.line, R)
		end
		view.flat_head(o, W, edge)
	else
		local bs = K.SMALL and 22 or 28
		local step = bs + (K.SMALL and 2 or 4)
		local bx, by = W - (K.SMALL and (K.HEAD - bs) / 2 or 12) - bs, (K.HEAD - bs) / 2
		local left = bx - step * (1 + (edge and 1 or 0) + #(o.buttons or {}))
		g.shadow(0, 0, W, h, R, 0.07 * opacity)
		g.rect(0, 0, W, h, C.win, R, opacity)
		g.clip(0, 0, W, math.min(h, K.HEAD))
		g.rect(0, 0, W, K.HEAD + 24, A, R, 0.10)
		g.unclip()
		hit.add(0, 0, left, K.HEAD, "drag", {
			down = function(mx, my) P.drag, P.moved = { mx = mx, my = my, wx = P.wx, wy = P.wy }, false end,
			dbl = view.fold,
		})
		local tx = K.SMALL and 12 or 16
		if o.glyph then
			g.rect(14, (K.HEAD - 30) / 2, 30, 30, A, 9, 0.22)
			g.glyph(o.glyph, 13, 29, K.HEAD / 2, AT)
			tx = 54
		end
		local fs, tw = K.SMALL and 13 or 14.5, left - tx - 8
		if o.sub then
			g.text(700, fs, g.fit(700, fs, o.title, tw), tx, K.HEAD / 2 - 8, T.t1)
			g.text(500, 11.5, g.fit(500, 11.5, o.sub, tw), tx, K.HEAD / 2 + 9, T.t3)
		else
			g.text(700, fs, g.fit(700, fs, o.title, tw), tx, K.HEAD / 2, T.t1)
		end
		view.icon_button(bx, by, bs, K.G.close, "btn_close", false, view.close, true)
		bx = bx - step
		view.icon_button(bx, by, bs, P.set.collapsed and K.G.down or K.G.up, "btn_fold", false, view.fold)
		if edge then
			bx = bx - step
			view.icon_button(bx, by, bs, edge > 0 and K.G.right or K.G.left, "btn_dock", false,
				function() view.dock(true) end)
		end
		for _, b in ipairs(o.buttons or {}) do
			bx = bx - step
			view.icon_button(bx, by, bs, b.glyph, b.id, b.active, b.click)
		end
	end

	if fold > 0.01 and body_h > 0 then
		if not flat then g.hl(14, K.HEAD - 1, W - 28, T.white, 0.07 * fold) end
		g.clip(0, top, W, h - top)
		local base = g.a
		g.a = base * fold ^ 1.5
		o.body(top)
		g.a = base
		g.unclip()
	end
	if not flat then g.frame(0, 0, W, h, T.white, R, 0.09) end
	view.draw_menu()
end

-- ---------------------------------------------------------------------------
-- input routing and the frame driver
-- ---------------------------------------------------------------------------

local input = { swallow = false, held = {} }

function input.press(mx, my, button)
	local h = hit.at(mx, my)
	local id, on = h and h[5], h and h[6] or {}
	if P.menu and not (id and (id:sub(1, 5) == "menu:" or id == "dd:" .. P.menu)) then
		P.menu = nil
		P.press = { id = false }
		return
	end
	if P.focus and id ~= P.focus_id then edit.blur() end
	if button == 2 then
		if on.rclick then on.rclick(mx, my) end
		return
	end
	P.press = { id = id or false, on = on }
	if on.down then on.down(mx, my) end
end

function input.release(mx, my)
	local press = P.press
	P.press = nil
	if not press or not press.id then return end
	if P.moved then
		P.moved = false
		return
	end
	local h = hit.at(mx, my)
	if not h or h[5] ~= press.id then return end
	local on = press.on
	if on.dbl and P.last_click.id == press.id and P.now - P.last_click.t < K.DOUBLE then
		P.last_click.id = nil
		on.dbl()
		return
	end
	P.last_click.id, P.last_click.t = press.id, P.now
	if on.click then on.click(mx, my) end
end

function input.end_drag()
	if P.drag then
		view.pin()
		save("wx", math.floor(P.wx))
		save("wy", math.floor(P.wy))
	end
	if P.slide and P.slide.done then P.slide.done(P.slide.value) end
	P.drag, P.slide, P.sb_drag = nil, nil, nil
end

function input.tick()
	if P.press and not Input.IsKeyDown(KEY.KEY_MOUSE1, true) then
		input.end_drag()
		P.press = nil
	end
	for key in pairs(input.held) do
		if not Input.IsKeyDown(key, true) then input.held[key] = nil end
	end
	local mx, my = Input.GetCursorPos()
	if P.drag then
		if math.abs(mx - P.drag.mx) + math.abs(my - P.drag.my) > 4 then P.moved = true end
		if not P.drag.lock then P.wx = P.drag.wx + mx - P.drag.mx end
		P.wy = P.drag.wy + my - P.drag.my
	end
	if P.slide then view.slide_to(mx) end
	if P.sb_drag then view.scroll_drag(my) end
	if P.focus then
		if P.alpha < 0.5 then
			edit.blur()
		else
			edit.sink(true)
			edit.poll()
		end
	end
end

function input.event(e)
	if P.alpha <= 0.02 and #P.toasts == 0 then return true end
	local mx, my = Input.GetCursorPos()
	local over = hit.at(mx, my) ~= nil

	if e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_UP or e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_DOWN then
		if not over then return true end
		local h = hit.at(mx, my, "wheel")
		if h then h[6].wheel(e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_DOWN and 1 or -1) end
		return false
	end

	if e.key == KEY.KEY_MOUSE1 or e.key == KEY.KEY_MOUSE2 then
		local left = e.key == KEY.KEY_MOUSE1
		if e.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
			if input.held[e.key] then return not input.swallow end
			input.held[e.key] = true
			if not over then
				if P.focus then edit.blur() end
				P.menu = nil
				if left then P.press = { id = false } end
				return true
			end
			input.swallow = true
			input.press(mx, my, left and 1 or 2)
			return false
		elseif e.event == Enum.EKeyEvent.EKeyEvent_KEY_UP then
			input.held[e.key] = nil
			if left then
				input.end_drag()
				input.release(mx, my)
			end
			if input.swallow then
				input.swallow = false
				return false
			end
		end
		return true
	end

	if P.focus then
		if e.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
			edit.sink(true, true)
			edit.key(e.key)
		end
		return false
	end

	if e.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN and e.key == KEY.KEY_ESCAPE and over and P.menu then
		P.menu = nil
		return false
	end
	return true
end

function input.frame(draw)
	local frame = GlobalVars.GetAbsFrameTime()
	P.now = os.clock()
	P.dt = clamp(frame > 0 and frame or 0.016, 0, 0.1)
	asset.budget = 3
	P.alpha = anim.tween("window", P.open and 1 or 0, 0.18)
	input.tick()
	hit.begin()
	local ok, err = true, nil
	if P.alpha > 0.001 then
		ok, err = pcall(draw)
	else
		P.press, P.drag, P.slide, P.sb_drag, P.menu = nil, nil, nil, nil, nil
	end
	g.reset()
	if ok then ok, err = pcall(view.draw_toasts) end
	g.reset()
	if ok then ok, err = pcall(view.draw_tip) end
	g.reset()
	if not ok and err ~= P.draw_error then
		P.draw_error = err
		Log.Write("[" .. K.NAME .. "] draw error: " .. tostring(err))
	end
end

function input.shutdown()
	if edit.sink_on then Engine.RunScript(JS_SINK:format(K.SINK_ID, "false", K.SINK_ID, K.SINK_TIMEOUT)) end
end

local DS = "npc_dota_hero_dark_seer"
local ORDER = Enum.UnitOrder
local ISSUER = Enum.PlayerOrderIssuer
local STATE = Enum.ModifierState
local BAD = {
	STATE.MODIFIER_STATE_INVULNERABLE, STATE.MODIFIER_STATE_ATTACK_IMMUNE,
	STATE.MODIFIER_STATE_OUT_OF_GAME, STATE.MODIFIER_STATE_UNTARGETABLE,
}
local STOP_ORDERS = {
	[ORDER.DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true, [ORDER.DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
	[ORDER.DOTA_UNIT_ORDER_ATTACK_MOVE] = true, [ORDER.DOTA_UNIT_ORDER_STOP] = true,
	[ORDER.DOTA_UNIT_ORDER_HOLD_POSITION] = true,
}
local FALLBACKS = { "dsi_fallbacks_follow", "dsi_fallbacks_camps", "dsi_fallbacks_lane" }

local S = {
	order = {}, off = {}, enemies = {}, names = {},
	illus = {}, busy = {}, manual = {}, sent = {}, seen = {}, cleared = {},
	target = nil, ds_target = nil, next_t = 0, drag = nil, body_h = 60,
}

for name in Config.ReadString(K.CFG, "order", ""):gmatch("[^,]+") do S.order[#S.order + 1] = name end
for name in Config.ReadString(K.CFG, "off", ""):gmatch("[^,]+") do S.off[name] = true end

local function save_lists()
	local off = {}
	for _, name in ipairs(S.order) do
		if S.off[name] then off[#off + 1] = name end
	end
	save("order", table.concat(S.order, ","))
	save("off", table.concat(off, ","))
end

local function hero_label(name)
	local s = S.names[name]
	if not s then
		s = GameLocalizer.FindNPC(name)
		S.names[name] = s
	end
	return s
end

local function local_ds()
	local me = Heroes.GetLocal()
	if me and NPC.GetUnitName(me) == DS then return me end
end

local function refresh_enemies(me)
	local present, known, list = {}, {}, {}
	for _, h in ipairs(Heroes.GetAll()) do
		if not Entity.IsSameTeam(h, me) and not NPC.IsIllusion(h) then present[NPC.GetUnitName(h)] = true end
	end
	for _, name in ipairs(S.order) do known[name] = true end
	for name in pairs(present) do
		if not known[name] then S.order[#S.order + 1] = name end
	end
	for _, name in ipairs(S.order) do
		if present[name] then list[#list + 1] = name end
	end
	S.enemies = list
end

local function hp(n)
	return Entity.GetHealth(n) / math.max(1, Entity.GetMaxHealth(n))
end

local function attackable(n)
	if not n or not NPCs.Contains(n) or not Entity.IsAlive(n) or Entity.IsDormant(n) or not NPC.IsVisible(n) then
		return false
	end
	for _, st in ipairs(BAD) do
		if NPC.HasState(n, st) then return false end
	end
	return true
end

local function lowest(list)
	local best, bv
	for _, h in ipairs(list) do
		local v = hp(h)
		if not bv or v < bv then best, bv = h, v end
	end
	return best
end

local function candidates(free, me)
	local r, team, list, seen = ui.radius:Get(), Entity.GetTeamNum(me), {}, {}
	for _, il in ipairs(free) do
		for _, h in ipairs(Heroes.InRadius(Entity.GetAbsOrigin(il), r, team, Enum.TeamType.TEAM_ENEMY, true, true)) do
			local idx = Entity.GetIndex(h)
			if not seen[idx] and attackable(h) then
				seen[idx] = true
				list[#list + 1] = h
			end
		end
	end
	return list
end

local function pick(free, me)
	local list = candidates(free, me)
	local cur = S.target and Entity.GetIndex(S.target)
	for _, h in ipairs(list) do
		if Entity.GetIndex(h) == cur then return h end
	end
	local rank, chosen, rest = {}, {}, {}
	for i, name in ipairs(S.enemies) do rank[name] = i end
	for _, h in ipairs(list) do
		local name = NPC.GetUnitName(h)
		if rank[name] and not S.off[name] then chosen[#chosen + 1] = h else rest[#rest + 1] = h end
	end
	if #chosen > 0 then
		if ui.order:Get() == 0 then
			local low, line = {}, ui.low_hp:Get() / 100
			for _, h in ipairs(chosen) do
				if hp(h) <= line then low[#low + 1] = h end
			end
			if #low > 0 then return lowest(low) end
		end
		table.sort(chosen, function(a, b) return rank[NPC.GetUnitName(a)] < rank[NPC.GetUnitName(b)] end)
		return chosen[1]
	end
	if not ui.others:Get() or #rest == 0 then return nil end
	local ds = attackable(S.ds_target) and Entity.GetIndex(S.ds_target)
	for _, h in ipairs(rest) do
		if Entity.GetIndex(h) == ds then return h end
	end
	return lowest(rest)
end

local function set_target(t)
	local a, b = S.target and Entity.GetIndex(S.target), t and Entity.GetIndex(t)
	if a ~= b then say("target: " .. (t and NPC.GetUnitName(t) or "none")) end
	S.target = t
end

local function send(il, key, fn)
	local idx, now = Entity.GetIndex(il), GameRules.GetGameTime()
	local s = S.sent[idx]
	if s and s.key == key and (now - s.t < 2 or NPC.IsAttacking(il)) then return end
	S.sent[idx] = { key = key, t = now }
	fn()
end

local function cell(pos)
	return math.floor(pos.x / 200) .. ":" .. math.floor(pos.y / 200)
end

local function attack(il, t)
	send(il, "a" .. Entity.GetIndex(t), function() Player.AttackTarget(Players.GetLocal(), il, t) end)
end

local function attack_move(il, pos)
	send(il, "m" .. cell(pos), function()
		Player.PrepareUnitOrders(Players.GetLocal(), ORDER.DOTA_UNIT_ORDER_ATTACK_MOVE, nil, pos, nil,
			ISSUER.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, il)
	end)
end

local function move(il, pos)
	send(il, "f" .. cell(pos), function() NPC.MoveTo(il, pos) end)
end

local function follow(free, me)
	local t = S.ds_target
	if attackable(t) and not Entity.IsSameTeam(t, me) then
		for _, il in ipairs(free) do attack(il, t) end
		return
	end
	local pos = Entity.GetAbsOrigin(me)
	for _, il in ipairs(free) do
		if Entity.GetAbsOrigin(il):Distance2D(pos) > 350 then move(il, pos) end
	end
end

local function farm(free, me)
	local minute = math.floor(GameRules.GetDOTATime() / 60)
	local from = Entity.GetAbsOrigin(free[1])
	local best, bd
	for _, c in ipairs(Camps.GetAll()) do
		local b = Camp.GetCampBox(c)
		local pos = Vector((b.min.x + b.max.x) / 2, (b.min.y + b.max.y) / 2, (b.min.z + b.max.z) / 2)
		local key = cell(pos)
		if S.cleared[key] ~= minute then
			local d = from:Distance2D(pos)
			if not bd or d < bd then best, bd = { pos = pos, key = key }, d end
		end
	end
	if not best then return end
	local alive = false
	for _, n in ipairs(NPCs.InRadius(best.pos, 500, Entity.GetTeamNum(me), Enum.TeamType.TEAM_BOTH, true, true)) do
		if NPC.IsNeutral(n) and Entity.IsAlive(n) then
			alive = true
			break
		end
	end
	if not alive and bd < 250 then
		S.cleared[best.key] = minute
		say("camp cleared " .. best.key)
		return
	end
	for _, il in ipairs(free) do attack_move(il, best.pos) end
end

local function push(free, me)
	local from = Entity.GetAbsOrigin(free[1])
	local best, bd
	for _, t in ipairs(Towers.GetAll()) do
		if Entity.IsAlive(t) and not Entity.IsSameTeam(t, me) then
			local d = from:Distance2D(Entity.GetAbsOrigin(t))
			if not bd or d < bd then best, bd = t, d end
		end
	end
	if not best then return end
	local pos = Entity.GetAbsOrigin(best)
	for _, il in ipairs(free) do attack_move(il, pos) end
end

local function tick(me)
	local now = GameRules.GetGameTime()
	if now < S.next_t then return end
	S.next_t = now + 0.1
	refresh_enemies(me)
	local pid = Hero.GetPlayerID(me)
	local illus, free = {}, {}
	for _, h in ipairs(Heroes.GetAll()) do
		if NPC.IsIllusion(h) and Entity.IsAlive(h) and NPC.GetUnitName(h) ~= DS and NPC.IsControllableByPlayer(h, pid) then
			local idx = Entity.GetIndex(h)
			illus[idx] = h
			if not S.seen[idx] then
				S.seen[idx] = true
				if K.DEBUG() then
					local mods = {}
					for _, m in ipairs(NPC.GetModifiers(h)) do mods[#mods + 1] = Modifier.GetName(m) end
					say("new illusion " .. NPC.GetUnitName(h) .. ": " .. table.concat(mods, ", "))
				end
			end
			if (S.manual[idx] or 0) <= now then free[#free + 1] = h end
		end
	end
	S.illus, S.busy = illus, {}
	if #free == 0 then return set_target(nil) end
	local t = pick(free, me)
	set_target(t)
	if t then
		for _, il in ipairs(free) do
			S.busy[Entity.GetIndex(il)] = true
			attack(il, t)
		end
		return
	end
	local mode = ui.fallback:Get()
	if mode == 0 then
		follow(free, me)
	elseif mode == 1 then
		farm(free, me)
	else
		push(free, me)
	end
end

local function guard_selection(me)
	if not next(S.busy) then return end
	local player = Players.GetLocal()
	local keep, drop = {}, false
	for _, u in ipairs(Player.GetSelectedUnits(player)) do
		if S.busy[Entity.GetIndex(u)] then drop = true else keep[#keep + 1] = u end
	end
	if not drop then return end
	Player.ClearSelectedUnits(player)
	if #keep == 0 then keep[1] = me end
	for _, u in ipairs(keep) do Player.AddSelectedUnit(player, u) end
end

local function reorder(list)
	local set, i = {}, 0
	for _, name in ipairs(list) do set[name] = true end
	for n, name in ipairs(S.order) do
		if set[name] then
			i = i + 1
			S.order[n] = list[i]
		end
	end
	save_lists()
end

local ROW = 28
local ORDERS = { "dsi_orders_low", "dsi_orders_prio" }

local function toggle_enable()
	ui.enable:Set(not ui.enable:Get())
	refresh_disabled()
end

local function cycle(widget, n)
	widget:Set((widget:Get() + 1) % n)
	refresh_disabled()
end

local function draw_row(x, y, w, name, lifted)
	local on = not S.off[name]
	local cid = "en:" .. name
	local hv = anim.hover(cid)
	local k = anim.tween("on:" .. cid, on and 1 or 0, 0.14)
	local cy = y + ROW / 2
	if lifted then g.rect(x - 4, y + 2, w + 8, ROW - 4, C.menu, 4) end
	g.square(asset.portrait(name), hero_label(name), x, cy - 10, 20, 0.5 + 0.5 * k, 2, 1 - k)
	local right = x + w - 26
	if S.target and NPC.GetUnitName(S.target) == name then
		g.glyph("\u{f05b}", 11, right - 12, cy, A, 0.8)
		right = right - 24
	end
	local tc = anim.mix(T.t4, anim.mix(T.t3, T.t2, hv), k)
	g.text(500, 13, g.fit(500, 13, hero_label(name), right - x - 32), x + 28, cy, tc)
	view.switch(x + w - 26, cy, on, cid .. ":sw", function()
		S.off[name] = not S.off[name] or nil
		save_lists()
	end)
	if not lifted then
		hit.add(x, y, w - 32, ROW, cid, { down = function(_, py) S.drag = { name = name, my = py } end })
	end
end

local function draw_rows(x, y, w)
	local list = S.enemies
	local _, my = Input.GetCursorPos()
	local d = S.drag
	if d then
		if Input.IsKeyDown(KEY.KEY_MOUSE1, true) then
			if not d.active and math.abs(my - d.my) > 4 then d.active = true end
		else
			if d.active and d.list then reorder(d.list) end
			S.drag, d = nil, nil
		end
	end
	local uy = (my - g.y) / g.s
	if d and d.active then
		local moved = {}
		for _, name in ipairs(list) do
			if name ~= d.name then moved[#moved + 1] = name end
		end
		table.insert(moved, clamp(math.floor((uy - y) / ROW), 0, #list - 1) + 1, d.name)
		d.list, list = moved, moved
	end
	for i, name in ipairs(list) do
		if not (d and d.active and name == d.name) then draw_row(x, y + (i - 1) * ROW, w, name) end
	end
	if d and d.active then
		draw_row(x, clamp(uy - ROW / 2, y, y + (#list - 1) * ROW), w, d.name, true)
	end
	return #list * ROW
end

local function draw_window()
	view.window({
		title = L("dsi_title"),
		switch = { on = ui.enable:Get(), click = toggle_enable },
		tab_w = 22,
		tab = function(x, cy) view.switch(x, cy, ui.enable:Get(), "tab_sw", toggle_enable, true) end,
		body_h = anim.tween("body_h", S.body_h, 0.2),
		body = function(y)
			local top, x, w = y, K.PAD, K.W - K.PAD * 2
			y = y + 10
			view.button(x, y, w, 22, L(ORDERS[ui.order:Get() + 1]), "soft", "btn_order", function() cycle(ui.order, 2) end)
			view.hint("btn_order", L("dsi_order"))
			y = y + 28
			if #S.enemies == 0 then
				g.text(500, 13, L("dsi_no_enemies"), x, y + ROW / 2, T.t4)
				y = y + ROW
			else
				y = y + draw_rows(x, y, w)
			end
			y = y + 6
			view.button(x, y, w, 22, L(FALLBACKS[ui.fallback:Get() + 1]), "soft", "btn_fallback", function() cycle(ui.fallback, 3) end)
			view.hint("btn_fallback", L("dsi_fallback"))
			S.body_h = y + 22 + 10 - top
		end,
	})
end

K.DEBUG = function() return ui.debug:Get() end
K.ON_CLOSE = function() ui.show:Set(false) end

local script = {}

local function hero_on()
	return (not ui.hero_enable or ui.hero_enable:Get()) and local_ds()
end

function script.OnUpdate()
	local me = active() and local_ds()
	if not me then
		S.target, S.busy = nil, {}
		local ds = P.open and hero_on()
		local now = GameRules.GetGameTime()
		if ds and now >= S.next_t then
			S.next_t = now + 0.5
			refresh_enemies(ds)
		end
		return
	end
	tick(me)
	guard_selection(me)
end

function script.OnDraw()
	P.open = hero_on() and ui.show:Get() and true or false
	if not P.open then S.drag = nil end
	input.frame(draw_window)
end

function script.OnKeyEvent(e)
	if not hero_on() then return true end
	return input.event(e)
end

function script.OnPrepareUnitOrders(data)
	local me = active() and local_ds()
	if not me then return true end
	local units = data.npc and { data.npc } or {}
	if data.orderIssuer == ISSUER.DOTA_ORDER_ISSUER_SELECTED_UNITS then
		units = Player.GetSelectedUnits(data.player)
	elseif data.orderIssuer == ISSUER.DOTA_ORDER_ISSUER_HERO_ONLY then
		units = { me }
	end
	local my_idx, now = Entity.GetIndex(me), GameRules.GetGameTime()
	for _, u in ipairs(units) do
		local idx = Entity.GetIndex(u)
		if idx == my_idx then
			if data.order == ORDER.DOTA_UNIT_ORDER_ATTACK_TARGET and data.target and not Entity.IsSameTeam(data.target, me) then
				S.ds_target = data.target
			elseif STOP_ORDERS[data.order] then
				S.ds_target = nil
			end
		elseif S.illus[idx] then
			S.manual[idx] = now + ui.manual:Get()
			S.sent[idx] = nil
			say("manual order for " .. NPC.GetUnitName(u))
		end
	end
	return true
end

function script.OnGameEnd()
	S.illus, S.busy, S.manual, S.sent, S.seen, S.cleared = {}, {}, {}, {}, {}, {}
	S.target, S.ds_target, S.next_t = nil, nil, 0
end

return script
