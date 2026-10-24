---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
--[[
	_invoker_tornado_ally_cc_guard.lua   v5.0   (Umbrella Lua API 1.0.4 / 2.0)

	Охранник Tornado для Invoker. Не даёт Tornado сбить контроль на враге (чужой или свой) и сам
	кидает его стыком: смерч долетает в момент, когда контроль заканчивается.

	v5.0: ПРИ СОМНЕНИИ ЗАПРЕЩАЕМ. Раньше, если остаток контроля считался как 0 (часы модификатора и
	игры не совпали), Tornado пропускался в середину стана. Теперь:
	  * остаток берётся у движка (NPC.GetStatesDuration), потом из модификатора с проверкой часов;
	  * если враг ещё в контроле, а остаток не читается или вышел ~0, срок считается НЕИЗВЕСТНЫМ,
	    и Tornado ждёт, пока контроль реально спадёт;
	  * враги ищутся и среди «считающихся героями» (манекен в демо, медведь и т.п.);
	  * зоны союзников (Kinetic Field, Arena, Chrono, Black Hole) тоже держат Tornado;
	  * сетевой фильтр читает msg_object (API 2.0), комбо Jarvis 2 / invoker.lua спрашивают
	    охранника через package.loaded["tornado_guard_api"];
	  * каждый запрет пишется в лог, с отладкой пишется и каждое разрешение с причиной.

	v5.1: КОМБО ПРОПУСКАЕТ TORNADO. invoker.lua на каждом шаге спрашивает api.would_block (только
	проверка). Цель под контролем: Tornado выкидывается из очереди ещё до Invoke, остальные скиллы
	пересчитываются и идут дальше. Контроль кончится через <= 0.3 с: комбо ждёт эти доли секунды,
	чтобы смерч лёг стыком. Отказ из комбо НЕ ставит автокаст охранника (он влез бы посреди комбо);
	для ручного нажатия автостык остаётся.

	УСТАНОВКА
	  Файл кладётся в scripts именно с "!_" в начале имени: так он грузится раньше комбо.
	  Старые версии (invoker_tornado_ally_cc_guard.lua и т.п.) удали.
	  Меню: Heroes -> Hero List -> Invoker -> Main Settings -> группа "Tornado Guard".

	ОТКУДА ЦИФРЫ (из файлов игры, не на глаз)
	  * Valve KV (SteamDatabase/GameTracking-Dota2, scripts/npc/heroes/npc_dota_hero_invoker.txt):
	    скорость Tornado 1000 на ЛЮБОМ уровне; каст-поинт 0.05; радиус 200 (+ бонусы радиуса);
	    дальность по Wex 1500/1800/2100/2400/2700/3000/3300/3600/3900; подъём по Quas 1.2 ... 2.8 с;
	    аганим даёт +1 уровень сферы. Поворот Invoker 0.6 (npc_dota_hero_base.txt).
	  * Liquipedia: дальность Tornado растёт от бонусов дальности каста.
	  * Valve Protobufs (dota_clientmessages.proto): все приказы уходят на сервер сообщением
	    CDOTAClientMsg_ExecuteOrders (id 350). Охранник проверяет его прямо перед отправкой,
	    поэтому Tornado не проходит мимо ни из ручного нажатия, ни из любого комбо.

	КАК СЧИТАЕТСЯ МОМЕНТ
	  долёт = пинг + тик сервера + поворот к точке (считает сама игра) + каст-поинт
	          + путь до касания / скорость, где касание = радиус смерча + хитбокс цели.
	  контроль = сколько осталось у цели: стан, хекс, сон, страх, таунт, заморозка, рестрикт
	             (+ по пресету руты, неуязвимость/изгнание/циклон, молчание/дизарм/мьют)
	             + канал союзника на цель (Dismember, Shackles, Fiend's Grip ...).
	  Tornado пропускается, только если долетит ПОСЛЕ конца контроля (+ запас пресета).
	  Заблокированный каст не пропадает: охранник сам кинет его в нужный кадр.
	  Союзники активно бьют стоящую цель: Tornado ждёт, пока цель побежит (в воздухе цель неуязвима).
	  Автокалибровка: после стыка реальный момент попадания сравнивается с реальным концом
	  контроля, поправка сохраняется между играми.
]]

local script = {}

local VERSION = "5.1"
local TAG = "[tornado_guard] "
local CFG = "tornado_guard"

-- Данные текущего патча (Valve KV)
local DATA = {
	ABILITY = "invoker_tornado",
	HERO = "npc_dota_hero_invoker",
	WEX = "invoker_wex",
	QUAS = "invoker_quas",
	TRAVEL = { 1500, 1800, 2100, 2400, 2700, 3000, 3300, 3600, 3900 },
	LIFT = { 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8 },
	SPEED = 1000,
	RADIUS = 200,
	CAST_POINT = 0.05,
	TURN_RATE = 0.6,
	TURN_TOLERANCE = 0.2, -- рад: каст начинается, когда до точки осталось меньше этого угла
	HULL = 24,
	TICK = 1 / 30,
}

-- Сеть (Valve Protobufs)
local NET = { ID = 350, NAME = "CDOTAClientMsg_ExecuteOrders", CAST_POSITION = 5, CAST_TARGET = 6 }
local ORDER_NAMES = { DOTA_UNIT_ORDER_CAST_POSITION = 5, DOTA_UNIT_ORDER_CAST_TARGET = 6 }

local K = {
	UNKNOWN_HOLD = 6.0, -- сколько держать каст, если срок контроля неизвестен
	NOTICE = 1.6,
	REWRAP_EVERY = 1.0,
	SAMPLE_EVERY = 0.1,
	SAMPLE_KEEP = 3.0,
	VELOCITY_SPAN = 0.4,
	ESCAPE_COS = 0.35,
	ALLY_NEAR = 1000,
	ALLY_FAR = 800,
	OWN_ORDER_WINDOW = 0.35,
	ALLOWED_RECENT = 0.15,
	LEAD_MAX = 0.02,
	AIM_LEAD_MAX = 450,
	CAL_MAX = 0.35,
	CAL_STEP = 0.5,
	CAL_FIRST_STEP = 0.8,
	CAL_OUTLIER = 0.6,
	PROBE_TTL = 8.0,
	PROBE_STILL = 60,
	STATUS_EVERY = 0.5,
}

-- Пресеты тайминга. margin: на сколько секунд ПОСЛЕ конца контроля долетает Tornado (минус = чуть раньше).
local PRESETS = {
	{ name = "Идеальный стык (рекомендую)", margin = 0.03, margin_ch = 0.08, roots = true, soft = false, invuln = true,
		prolong = true, focus = true, escape = true, focus_pct = 6, kill_hp = 30, escape_speed = 180, hold = 2.5 },
	{ name = "Без щели (агрессивно)", margin = -0.08, margin_ch = 0.05, roots = true, soft = false, invuln = true,
		prolong = true, focus = true, escape = true, focus_pct = 6, kill_hp = 30, escape_speed = 160, hold = 2.5 },
	{ name = "Безопасно (высокий пинг)", margin = 0.12, margin_ch = 0.18, roots = true, soft = true, invuln = true,
		prolong = true, focus = true, escape = true, focus_pct = 5, kill_hp = 35, escape_speed = 200, hold = 3.0 },
	{ name = "Только запрет, без автокаста", margin = 0.03, margin_ch = 0.08, roots = true, soft = false, invuln = true,
		prolong = false, focus = true, escape = false, focus_pct = 6, kill_hp = 30, escape_speed = 180, hold = 2.5 },
	{ name = "Свои настройки" },
}
local CUSTOM = #PRESETS

-- ============================================================================
-- Меню
-- ============================================================================
local function const(v) return { Get = function() return v end } end

local ui = {
	enabled = const(true), preset = const(0),
	c_margin = const(30), c_margin_ch = const(80), c_roots = const(true), c_soft = const(false),
	c_invuln = const(true), c_prolong = const(true), c_focus = const(true), c_escape = const(true),
	c_focus_pct = const(6), c_kill_hp = const(30), c_escape_speed = const(180), c_hold = const(2.5),
	net = const(true), hooks = const(true), manual = const(true), autocal = const(true),
	hud = const(true), notice = const(true), debug = const(false),
	own = const(true), zones = const(true),
}

local custom_widgets = {}

local ok_menu, err_menu = pcall(function()
	local grp
	local ok_a, res_a = pcall(Menu.Create, "Heroes", "Hero List", "Invoker", "Main Settings", "Tornado Guard")
	if ok_a and res_a then
		grp = res_a
	else
		grp = Menu.Create("Heroes", "Hero List", "Invoker", "Main Settings"):Create("Tornado Guard")
	end
	ui.enabled = grp:Switch("Охрана Tornado", true, "\u{f132}")
	ui.enabled:ToolTip("Не даёт Tornado сбить контроль на враге и кидает его стыком к концу контроля")

	local names = {}
	for i, p in ipairs(PRESETS) do names[i] = p.name end
	ui.preset = grp:Combo("Пресет тайминга", names, 0)
	ui.preset:ToolTip("Идеальный стык: смерч долетает через 30-50 мс после конца контроля (каналы +80 мс).\n"
		.. "Без щели: долетает за 50-100 мс до конца, у цели нет ни кадра свободы.\n"
		.. "Безопасно: +100-150 мс, для высокого или скачущего пинга.\n"
		.. "Только запрет: Tornado не кидается сам, комбо кинет его, когда станет можно.\n"
		.. "Точность ограничена тиком сервера (33 мс); автокалибровка подгоняет стык после первых боёв.")
	ui.status = grp:Label("Ожидание игры")
	ui.calib_label = grp:Label("Калибровка: нет данных")

	local own = ui.enabled:Gear("Свои настройки")
	ui.c_margin = own:Slider("Стык: попадание после конца контроля, мс", -200, 300, 30, "%d")
	ui.c_margin_ch = own:Slider("Стык для каналов (Dismember и т.п.), мс", 0, 400, 80, "%d")
	ui.c_roots = own:Switch("Учитывать руты", true)
	ui.c_soft = own:Switch("Учитывать молчание, дизарм, мьют", false)
	ui.c_invuln = own:Switch("Ждать конца неуязвимости, изгнания, циклона", true)
	ui.c_prolong = own:Switch("Сам кидать Tornado к концу контроля", true)
	ui.c_focus = own:Switch("Не кидать, пока союзники бьют стоящую цель", true)
	ui.c_escape = own:Switch("Кинуть, когда цель побежала", true)
	ui.c_focus_pct = own:Slider("Бьют: урон союзников за 1 с, % макс. хп", 2, 30, 6, "%d")
	ui.c_kill_hp = own:Slider("Добивают: хп цели ниже, %", 5, 60, 30, "%d")
	ui.c_escape_speed = own:Slider("Бегство: скорость от союзников, ед./с", 80, 400, 180, "%d")
	ui.c_hold = own:Slider("Ждать бегства не дольше, с", 1.0, 6.0, 2.5, "%.1f")
	custom_widgets = { ui.c_margin, ui.c_margin_ch, ui.c_roots, ui.c_soft, ui.c_invuln, ui.c_prolong, ui.c_focus,
		ui.c_escape, ui.c_focus_pct, ui.c_kill_hp, ui.c_escape_speed, ui.c_hold }

	local tech = ui.preset:Gear("Перехват и отладка")
	ui.own = tech:Switch("Ждать и мой собственный контроль (Cold Snap, Deafening Blast)", true)
	ui.zones = tech:Switch("Зоны союзников: Kinetic Field, Arena, Chrono, Black Hole", true)
	ui.net = tech:Switch("Сетевой фильтр приказов (ловит любое комбо)", true)
	ui.hooks = tech:Switch("Обёртки функций каста (запасной перехват)", true)
	ui.manual = tech:Switch("Проверять мои ручные нажатия", true)
	ui.autocal = tech:Switch("Автокалибровка по реальным попаданиям", true)
	tech:Button("Сбросить калибровку", function()
		script._reset_calibration()
	end)
	ui.hud = tech:Switch("Таймер над врагом", true)
	ui.notice = tech:Switch("Надпись у курсора", true)
	ui.debug = tech:Switch("Отладочный лог", false)

	local function sync_custom()
		local custom = (ui.preset:Get() + 1) == CUSTOM
		for _, w in ipairs(custom_widgets) do pcall(function() w:Disabled(not custom) end) end
	end
	ui.preset:SetCallback(sync_custom, true)
end)

-- ============================================================================
-- Вспомогательные
-- ============================================================================
local function try(fn, ...)
	if type(fn) ~= "function" then return nil end
	local r = table.pack(pcall(fn, ...))
	if r[1] then return table.unpack(r, 2, r.n) end
	return nil
end

local function dbg(fmt, ...)
	if ui.debug:Get() then
		local ok, s = pcall(string.format, fmt, ...)
		Log.Write(TAG .. (ok and s or tostring(fmt)))
	end
end

local logged_once = {}
local function log_once(key, text)
	if logged_once[key] then return end
	logged_once[key] = true
	Log.Write(TAG .. text)
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function idx_of(e)
	return e and try(Entity.GetIndex, e)
end

local function same(a, b)
	if a == nil or b == nil then return false end
	if a == b then return true end
	local ia, ib = idx_of(a), idx_of(b)
	return ia ~= nil and ia == ib
end

local function has_flag(value, flag)
	local v = value and (math.tointeger(value) or math.floor(value))
	return v ~= nil and (v & flag) ~= 0
end

local function bit_set(mask, bit)
	local m = mask and (math.tointeger(mask) or math.floor(mask))
	if not m then return false end
	return ((m >> bit) & 1) == 1
end

local function game_now()
	local t = try(GameRules.GetGameTime)
	if type(t) == "number" and t > 0 then return t end
	t = try(GlobalVars.GetCurTime)
	if type(t) == "number" then return t end
	return os.clock()
end

local function local_invoker()
	local me = try(Heroes.GetLocal)
	if not me or try(NPC.GetUnitName, me) ~= DATA.HERO then return nil end
	return me
end

local function display(unit)
	local name = try(NPC.GetUnitName, unit) or "враг"
	return try(Engine.GetDisplayNameByUnitName, name) or name
end

-- Враги: герои + юниты, которые считаются героями (манекен в демо, медведь Лон Друида и т.п.)
local function enemy_heroes(me)
	local list, seen = {}, {}
	local function add(h)
		local idx = idx_of(h)
		if not idx or seen[idx] then return end
		if try(Entity.IsSameTeam, h, me) ~= false then return end
		if try(NPC.IsIllusion, h) or not try(Entity.IsAlive, h) or try(Entity.IsDormant, h) then return end
		seen[idx] = true
		list[#list + 1] = h
	end
	for _, h in ipairs(try(Heroes.GetAll) or {}) do add(h) end
	local F = Enum and Enum.UnitTypeFlags
	if F and F.TYPE_HERO then
		local flags = F.TYPE_HERO | (F.TYPE_CONSIDERED_HERO or 0)
		for _, n in ipairs(try(NPCs.GetAll, flags) or {}) do add(n) end
	end
	return list
end

local function find_by_index(idx)
	if not idx then return nil end
	local e = try(Entity.Get, idx)
	if e and idx_of(e) == idx then return e end
	for _, h in ipairs(try(Heroes.GetAll) or {}) do
		if idx_of(h) == idx then return h end
	end
	return nil
end

-- ============================================================================
-- Состояние
-- ============================================================================
local S = {
	samples = {}, -- [idx] = { {t, x, y, hp, mx}, ... }
	ally_hits = {}, -- [idx] = { {t, dmg}, ... } (из OnEntityHurt)
	hurt_seen = false,
	last_sample = -99,
	pending = nil,
	own_until = -99,
	last_allowed = -99,
	last_order_seen = -99,
	prev_cd = 0,
	last_warn = -99,
	probe = nil,
	cal = { bias = 0, n = 0 },
	net = { seen = 0, decoded = 0, failed = 0, blocked = 0, dumped = 0, last_error = "" },
	resending = false,
	status_at = -99,
	frame_dt = 0.016,
	last_clock = nil,
}
script._S = S

do
	local b = try(Config.ReadFloat, CFG, "bias", 0)
	local n = try(Config.ReadInt, CFG, "samples", 0)
	if type(b) == "number" and b == b then S.cal.bias = clamp(b, -K.CAL_MAX, K.CAL_MAX) end
	if type(n) == "number" then S.cal.n = math.max(0, math.floor(n)) end
end

local function save_calibration()
	pcall(Config.WriteFloat, CFG, "bias", S.cal.bias)
	pcall(Config.WriteInt, CFG, "samples", S.cal.n)
end

function script._reset_calibration()
	S.cal.bias, S.cal.n, S.probe = 0, 0, nil
	save_calibration()
	Log.Write(TAG .. "calibration reset")
end

local function cfg()
	local idx = (tonumber(ui.preset:Get()) or 0) + 1
	if idx == CUSTOM then
		return {
			margin = ui.c_margin:Get() / 1000, margin_ch = ui.c_margin_ch:Get() / 1000,
			roots = ui.c_roots:Get(), soft = ui.c_soft:Get(), invuln = ui.c_invuln:Get(),
			prolong = ui.c_prolong:Get(), focus = ui.c_focus:Get(), escape = ui.c_escape:Get(),
			focus_pct = ui.c_focus_pct:Get(), kill_hp = ui.c_kill_hp:Get(),
			escape_speed = ui.c_escape_speed:Get(), hold = ui.c_hold:Get(),
		}
	end
	return PRESETS[idx] or PRESETS[1]
end
script._cfg = cfg

-- ============================================================================
-- Параметры Tornado с учётом уровня сфер
-- ============================================================================
local function orb_level(me, name)
	local ab = try(NPC.GetAbility, me, name)
	local lvl = ab and try(Ability.GetLevel, ab) or 0
	if type(lvl) ~= "number" or lvl < 1 then lvl = 1 end
	return lvl
end

local function tornado_stats(me, ab)
	local scepter = try(NPC.HasScepter, me) and 1 or 0 -- +1 к сфере (с запасом: считаем даже без фасета)
	local wex, quas = orb_level(me, DATA.WEX), orb_level(me, DATA.QUAS)
	local wl = math.min(#DATA.TRAVEL, wex + scepter)
	local ql = math.min(#DATA.LIFT, quas + scepter)

	local distance = DATA.TRAVEL[wl]
	local api_dist = try(Ability.GetLevelSpecialValueFor, ab, "travel_distance")
	if type(api_dist) == "number" and api_dist > distance and api_dist < 6000 then distance = api_dist end
	local bonus = try(NPC.GetCastRangeBonus, me)
	if type(bonus) == "number" and bonus > 0 and bonus < 1500 then distance = distance + bonus end

	local radius = DATA.RADIUS
	local api_r = try(Ability.GetLevelSpecialValueFor, ab, "area_of_effect")
	if type(api_r) == "number" and api_r > radius and api_r < 600 then radius = api_r end

	local speed = DATA.SPEED
	local api_s = try(Ability.GetLevelSpecialValueFor, ab, "travel_speed")
	if type(api_s) == "number" and api_s >= 500 and api_s <= 3000 then speed = api_s end

	local cp = try(Ability.GetCastPoint, ab, true)
	if type(cp) ~= "number" or cp < 0 or cp > 0.5 then cp = DATA.CAST_POINT end

	return {
		wex = wex, quas = quas, scepter = scepter, distance = distance, radius = radius,
		speed = speed, cast_point = cp, lift = DATA.LIFT[ql],
	}
end
script._stats = tornado_stats

-- Пинг: Umbrella отдаёт пинг канала. Для стыка нужен полный круг (клиент видит контроль с опозданием,
-- а приказ ещё летит до сервера), поэтому берётся целиком.
local function latency()
	local flow = Enum and Enum.Flow and Enum.Flow.FLOW_OUTGOING or 0
	local l = try(NetChannel.GetAvgLatency, flow)
	if type(l) ~= "number" or l < 0 or l > 1 then l = try(NetChannel.GetLatency, flow) end
	if type(l) ~= "number" or l < 0 or l > 1 then l = 0.05 end
	return math.min(l, 0.3)
end

local function tick_interval()
	local t = try(GlobalVars.GetIntervalPerTick)
	if type(t) ~= "number" or t <= 0 or t > 0.1 then t = DATA.TICK end
	return t
end

local function turn_time(me, x, y, z)
	local t = try(NPC.GetTimeToFacePosition, me, Vector(x, y, z or 0))
	if type(t) == "number" and t >= 0 and t < 2 then return t end
	local ox, oy = try(Entity.GetAbsOriginXYZ, me)
	local fwd = try(Entity.GetForwardPosition, me, 100)
	if not ox or not fwd then return 0 end
	local fx, fy = fwd.x - ox, fwd.y - oy
	local dx, dy = x - ox, y - oy
	local angle = math.abs(math.atan(fx * dy - fy * dx, fx * dx + fy * dy))
	local rate = try(NPC.GetTurnRate, me)
	if type(rate) ~= "number" or rate <= 0 then rate = DATA.TURN_RATE end
	return math.max(0, angle - DATA.TURN_TOLERANCE) * 0.03 / rate
end

-- Сколько пролетит центр смерча до касания цели. nil: смерч цель не заденет.
local function path_hit(ox, oy, ux, uy, ex, ey, contact, max_s)
	local rx, ry = ex - ox, ey - oy
	local along = rx * ux + ry * uy
	local perp = math.abs(rx * uy - ry * ux)
	if perp > contact then return nil end
	local half = math.sqrt(contact * contact - perp * perp)
	if along + half < 0 then return nil end -- цель позади
	local s = math.max(0, along - half)
	if s > max_s then return nil end -- дальше, чем летит смерч
	return s
end
script._path_hit = path_hit

-- ============================================================================
-- Контроль на цели
-- ============================================================================
local STATE_GROUPS = {
	hard = { "STUNNED", "HEXED", "NIGHTMARED", "FEARED", "TAUNTED", "FROZEN", "COMMAND_RESTRICTED",
		"IGNORING_MOVE_ORDERS" },
	invuln = { "INVULNERABLE", "OUT_OF_GAME" },
	root = { "ROOTED", "TETHERED" },
	soft = { "SILENCED", "DISARMED", "MUTED" },
}
local GROUP_ORDER = { "hard", "invuln", "root", "soft" }
local NAME_HINTS = {
	hard = { "stun", "voodoo", "hex", "sheep", "sleep", "nightmare", "fear", "terror", "taunt", "berserkers_call",
		"freeze", "frozen", "bash", "dismember", "shackle", "fiends_grip", "duel", "polarity", "dream_coil",
		"petrif", "chronosphere", "black_hole", "knockback", "knock_back", "vacuum", "telekinesis", "toss",
		"meat_hook", "lasso", "impale", "ravage", "hoof_stomp", "echo_stomp", "stasis", "pull" },
	invuln = { "cyclone", "eul", "astral_imprisonment", "disruption", "wind_waker", "banish" },
	root = { "root", "entangle", "ensnare", "overgrowth", "gleipnir", "rod_of_atos", "earthbind", "leash", "coiled" },
	soft = { "silence", "disarm", "mute" },
}
-- Сильные подсказки: такой эффект держит цель, даже если его срок не читается
local STRONG_HINTS = { "dismember", "shackle", "fiends_grip", "duel", "chronosphere", "black_hole", "cyclone", "eul",
	"astral_imprisonment", "disruption", "telekinesis", "vacuum", "meat_hook", "lasso", "knockback", "knock_back",
	"toss", "stun", "hex", "sheep", "voodoo", "sleep", "nightmare", "taunt", "berserkers_call", "fear" }
-- Это не контроль: кулдауны, счётчики, ауры, пассивки предметов, наш же смерч
local NAME_EXCLUDE = { "cooldown", "counter", "tracker", "_slow", "immun", "resist", "aura", "passive", "_charge",
	"_stack", "vision", "reveal", "_damage", "thinker", "modifier_item_", "invoker_tornado", "_buff", "bonus",
	"_armor", "lifesteal" }

-- Зоны союзников: тинкер с модификатором, внутри которого враг заперт
local ZONES = {
	{ hint = "kinetic_field", radius = 350 },
	{ hint = "arena_of_blood", radius = 550 },
	{ hint = "chronosphere", radius = 500 },
	{ hint = "black_hole", radius = 420 },
}

local state_cache = {}
local function state_ids(group)
	if state_cache[group] then return state_cache[group] end
	local list = {}
	local E = Enum and Enum.ModifierState
	for _, n in ipairs(STATE_GROUPS[group]) do
		local v = E and E["MODIFIER_STATE_" .. n]
		if v ~= nil then list[#list + 1] = math.tointeger(v) or v end
	end
	state_cache[group] = list
	return list
end

local state_names
local function state_name(id)
	if not state_names then
		state_names = {}
		local E = Enum and Enum.ModifierState
		if type(E) == "table" then
			for k, v in pairs(E) do
				state_names[math.tointeger(v) or v] = (tostring(k):gsub("^MODIFIER_STATE_", ""))
			end
		end
	end
	return state_names[id] or tostring(id)
end

local function name_has(name, list)
	for _, part in ipairs(list) do
		if name:find(part, 1, true) then return true end
	end
	return false
end

-- Группа контроля по имени модификатора (для эффектов без состояния в маске)
local function name_group(name, groups)
	if name == "" or name_has(name, NAME_EXCLUDE) then return nil end
	for _, g in ipairs(GROUP_ORDER) do
		if groups[g] and name_has(name, NAME_HINTS[g]) then return g end
	end
	return nil
end

local function own_tornado_name(name)
	return name:find("invoker_tornado", 1, true) ~= nil
end

-- Кто наложил эффект: "me" (я и мои юниты), "ally", "other" (враги/нейтралы), "unknown"
local function modifier_side(m, name, me)
	if name:find("invoker", 1, true) then return "me" end
	local ab = try(Modifier.GetAbility, m)
	local caster = try(Modifier.GetCaster, m) or (ab and try(Ability.GetOwner, ab)) or try(Modifier.GetAuraOwner, m)
	if not caster then return "unknown" end
	if same(caster, me) or try(Entity.RecursiveOwnedBy, caster, me) then return "me" end
	local team = try(Entity.IsSameTeam, caster, me)
	if team == true then return "ally" end
	if team == false then return "other" end
	return "unknown"
end

-- Часы игры. Модификатор хранит время в игровых часах; пробуем оба источника и берём тот, с которым
-- числа сходятся. Не сошлись ни с одним: срок НЕИЗВЕСТЕН (nil), а не 0. Именно 0 раньше и пропускал
-- Tornado в середину стана.
local function game_clocks()
	local list = {}
	local a = try(GameRules.GetGameTime)
	if type(a) == "number" and a > 0 then list[#list + 1] = a end
	local b = try(GlobalVars.GetCurTime)
	if type(b) == "number" and b > 0 then list[#list + 1] = b end
	return list
end

local function mod_left(m, clocks)
	local die = tonumber(try(Modifier.GetDieTime, m)) or 0
	local dur = tonumber(try(Modifier.GetDuration, m)) or 0
	local born = tonumber(try(Modifier.GetCreationTime, m)) or 0
	for _, now in ipairs(clocks) do
		if born <= 0 or born <= now + 0.15 then
			if die > 0 then
				local r = die - now
				if r > -0.1 and r < 60 and (dur <= 0 or r <= dur + 0.2) then return math.max(0, r) end
			elseif dur > 0 and born > 0 then
				local age = now - born
				if age >= -0.15 and age <= dur + 0.2 then return math.max(0, dur - age) end
			end
		end
	end
	return nil
end
script._mod_left = mod_left

-- Остаток состояний прямо от движка (сам считает время). API 2.0 принимает набор {[id]=true},
-- API 1.0.4 описывает массив: пробуем оба вида.
local function engine_durations(enemy, ids)
	local out = {}
	if #ids == 0 then return out end
	local set = {}
	for _, id in ipairs(ids) do set[id] = true end
	local function read(t, positional)
		if type(t) ~= "table" then return end
		for i, id in ipairs(ids) do
			local v = t[id]
			if v == nil and positional then v = t[i] end
			v = tonumber(v)
			if v and v > 0 and v < 60 then out[id] = v end
		end
	end
	read(try(NPC.GetStatesDuration, enemy, set, true), false)
	if next(out) == nil then
		local t = try(NPC.GetStatesDuration, enemy, ids, true)
		read(t, type(t) == "table" and #t == #ids)
	end
	return out
end

-- Союзник каналирует способность на цель (Dismember, Shackles, Fiend's Grip, Life Drain ...)
local BEHAVIOR_UNIT_TARGET, BEHAVIOR_CHANNELLED = 8, 128
local function channel_of(unit)
	if not try(NPC.IsChannellingAbility, unit) then return nil end
	local ab = try(NPC.GetChannellingAbility, unit)
	if not ab then return nil end
	local beh = try(Ability.GetBehavior, ab)
	if not has_flag(beh, BEHAVIOR_CHANNELLED) then return nil end
	return ab, beh
end

local function channel_points_at(ally, ab, enemy, me)
	local ex, ey = try(Entity.GetAbsOriginXYZ, enemy)
	local ax, ay = try(Entity.GetAbsOriginXYZ, ally)
	if not ex or not ax then return false end
	local range = try(Ability.GetCastRange, ab) or 0
	local d = math.sqrt((ex - ax) ^ 2 + (ey - ay) ^ 2)
	if range <= 0 or d > range + 200 then return false end
	for _, other in ipairs(enemy_heroes(me)) do
		if not same(other, enemy) then
			local ox, oy = try(Entity.GetAbsOriginXYZ, other)
			if ox and math.sqrt((ox - ax) ^ 2 + (oy - ay) ^ 2) < d then return false end
		end
	end
	return true
end

-- Зоны союзников обновляются раз в 0.25 с (ищем тинкеры)
local Z = { list = {}, at = -99 }
local function refresh_zones(me, clk)
	if clk - Z.at < 0.25 then return end
	Z.at = clk
	Z.list = {}
	if not ui.zones:Get() then return end
	for _, npc in ipairs(try(NPCs.GetAll) or {}) do
		if try(NPC.GetUnitName, npc) == "npc_dota_thinker" and try(Entity.IsSameTeam, npc, me) == true then
			local x, y = try(Entity.GetAbsOriginXYZ, npc)
			if x then
				for _, m in ipairs(try(NPC.GetModifiers, npc) or {}) do
					local name = string.lower(try(Modifier.GetName, m) or "")
					for _, z in ipairs(ZONES) do
						if name:find(z.hint, 1, true) then
							Z.list[#Z.list + 1] = { x = x, y = y, r = z.radius, m = m, name = name }
						end
					end
				end
			end
		end
	end
end
script._refresh_zones = refresh_zones

-- Это канал союзника/мой на цель? (Dismember, Shackles, Fiend's Grip ...)
local function modifier_is_channel(m)
	local ab = try(Modifier.GetAbility, m)
	local caster = (ab and try(Ability.GetOwner, ab)) or try(Modifier.GetCaster, m)
	if not (ab and caster) then return false end
	local cab = channel_of(caster)
	return cab ~= nil and same(cab, ab)
end

-- Возвращает {R, group, label, channel} самого долгого контроля или nil.
-- R = math.huge: враг в контроле, но срок неизвестен -> Tornado ждёт, пока контроль реально спадёт.
local function control(enemy, me, c)
	local best
	local function take(r, group, label, channel)
		local R = r
		if R == nil then R = math.huge end
		if not best or R > best.R then best = { R = R, group = group, label = label, channel = channel } end
	end
	local groups = { hard = true, invuln = c.invuln, root = c.roots, soft = c.soft }
	local own_blocks = ui.own:Get()
	local clocks = game_clocks()

	-- 1) модификаторы: чей эффект, какие состояния даёт, сколько осталось
	local by_state = {} -- [id] = { mine, foreign, left, unknown, label, group, channel }
	for _, m in ipairs(try(NPC.GetModifiers, enemy) or {}) do
		local name = string.lower(try(Modifier.GetName, m) or "")
		if not own_tornado_name(name) then
			local side = modifier_side(m, name, me)
			local foreign = side ~= "me" or own_blocks
			local mask = try(Modifier.GetState, m)
			local matched = false
			if type(mask) == "number" and mask ~= 0 then
				for _, g in ipairs(GROUP_ORDER) do
					if groups[g] then
						for _, id in ipairs(state_ids(g)) do
							if bit_set(mask, id) then
								matched = true
								local e = by_state[id]
								if not e then
									e = { group = g }
									by_state[id] = e
								end
								if foreign then
									e.foreign = true
									e.label = e.label or name
									if modifier_is_channel(m) then e.channel = true end
									local r = mod_left(m, clocks)
									if r == nil then
										e.unknown = true
									elseif not e.left or r > e.left then
										e.left = r
									end
								else
									e.mine = true
								end
							end
						end
					end
				end
			end
			-- эффекты без нужного состояния в маске: отталкивания, притягивания, каналы на цель...
			if not matched and foreign then
				local g = name_group(name, groups)
				if g and try(Modifier.IsDebuff, m) ~= false then
					local r = mod_left(m, clocks)
					-- срок не читается: держим только по «сильным» именам, чтобы не зависнуть на пассивке
					if r ~= nil or name_has(name, STRONG_HINTS) then
						if r ~= nil and r <= 0.01 then r = nil end
						take(r, g, name, modifier_is_channel(m))
					end
				end
			end
		end
	end

	-- 2) состояния движка: это правда «враг в контроле прямо сейчас», кто бы его ни наложил
	local hs_works = false
	for _, g in ipairs(GROUP_ORDER) do
		if groups[g] then
			local present = {}
			for _, id in ipairs(state_ids(g)) do
				local v = try(NPC.HasState, enemy, id)
				if v ~= nil then hs_works = true end
				if v then present[#present + 1] = id end
			end
			if g == "hard" and #present == 0 and try(NPC.IsStunned, enemy) then
				local st = Enum and Enum.ModifierState and Enum.ModifierState.MODIFIER_STATE_STUNNED
				if st ~= nil then present[1] = math.tointeger(st) or st end
			end
			if #present > 0 then
				local dur = engine_durations(enemy, present)
				for _, id in ipairs(present) do
					local e = by_state[id]
					-- это состояние держит только мой контроль, а ждать свой контроль выключено
					if not (e and e.mine and not e.foreign) then
						-- движок и модификатор разошлись: берём больший остаток (лучше подождать лишний тик)
						local r = dur[id]
						if e and e.foreign and not e.unknown and e.left and (r == nil or e.left > r) then r = e.left end
						if r ~= nil and r <= 0.01 then r = nil end -- в контроле, а остаток ~0: часы врут, ждём спада
						take(r, g, (e and e.label) or ("state:" .. state_name(id)), e and e.channel or false)
					end
				end
			end
		end
	end
	-- HasState не отвечает (другая версия API): верим модификаторам
	if not hs_works then
		for id, e in pairs(by_state) do
			if e.foreign then
				local r = (not e.unknown) and e.left or nil
				if r ~= nil and r <= 0.01 then r = nil end
				take(r, e.group, e.label or ("state:" .. state_name(id)), e.channel or false)
			end
		end
	end

	-- 3) канал союзника на цель без читаемого модификатора
	if not (best and best.channel) then
		for _, ally in ipairs(try(Heroes.GetAll) or {}) do
			if not same(ally, me) and try(Entity.IsSameTeam, ally, me) == true and try(Entity.IsAlive, ally) then
				local cab, beh = channel_of(ally)
				if cab and has_flag(beh, BEHAVIOR_UNIT_TARGET) and channel_points_at(ally, cab, enemy, me) then
					local r = math.huge
					if best and best.R < math.huge then r = best.R end
					take(r, "hard", "channel:" .. tostring(try(Ability.GetName, cab)), true)
					if best then best.channel = true end
				end
			end
		end
	end

	-- 4) враг внутри зоны союзника
	if #Z.list > 0 then
		local x, y = try(Entity.GetAbsOriginXYZ, enemy)
		if x then
			for _, z in ipairs(Z.list) do
				if math.sqrt((x - z.x) ^ 2 + (y - z.y) ^ 2) <= z.r + 30 then
					local r = mod_left(z.m, clocks)
					if r ~= nil and r <= 0.01 then r = nil end
					take(r, "hard", "zone:" .. z.name, false)
				end
			end
		end
	end
	return best
end
script._control = control

-- ============================================================================
-- История врагов: позиция и хп (бьют ли цель и убегает ли она)
-- ============================================================================
local function sample_enemies(me, clk)
	if clk - S.last_sample < K.SAMPLE_EVERY then return end
	S.last_sample = clk
	for _, h in ipairs(enemy_heroes(me)) do
		local idx = idx_of(h)
		local x, y = try(Entity.GetAbsOriginXYZ, h)
		if idx and x then
			local list = S.samples[idx]
			if not list then
				list = {}
				S.samples[idx] = list
			end
			list[#list + 1] = { t = clk, x = x, y = y, hp = try(Entity.GetHealth, h) or 0, mx = try(Entity.GetMaxHealth, h) or 1 }
			while #list > 1 and clk - list[1].t > K.SAMPLE_KEEP do table.remove(list, 1) end
		end
	end
	for idx, hits in pairs(S.ally_hits) do
		while #hits > 0 and clk - hits[1].t > K.SAMPLE_KEEP do table.remove(hits, 1) end
		if #hits == 0 then S.ally_hits[idx] = nil end
	end
end
script._sample = sample_enemies

local function damage_in(idx, window, clk)
	local list = S.samples[idx]
	if not list then return 0 end
	local total = 0
	for i = 2, #list do
		if list[i].t >= clk - window then
			local d = list[i - 1].hp - list[i].hp
			if d > 0 then total = total + d end
		end
	end
	return total
end

local function velocity(idx, clk)
	local list = S.samples[idx]
	if not list or #list < 2 then return nil end
	local newest = list[#list]
	if clk - newest.t > 0.5 then return nil end
	local oldest
	for i = 1, #list do
		if list[i].t >= newest.t - K.VELOCITY_SPAN then
			oldest = list[i]
			break
		end
	end
	if not oldest or newest.t - oldest.t < 0.15 then return nil end
	local dt = newest.t - oldest.t
	local vx, vy = (newest.x - oldest.x) / dt, (newest.y - oldest.y) / dt
	return { x = vx, y = vy, speed = math.sqrt(vx * vx + vy * vy) }
end

local function nearest_ally(me, ex, ey)
	local best, bd
	for _, h in ipairs(try(Heroes.GetAll) or {}) do
		if try(Entity.IsSameTeam, h, me) == true and try(Entity.IsAlive, h) and not try(NPC.IsIllusion, h) then
			local ax, ay = try(Entity.GetAbsOriginXYZ, h)
			if ax then
				local d = math.sqrt((ex - ax) ^ 2 + (ey - ay) ^ 2)
				if not bd or d < bd then best, bd = { x = ax, y = ay, unit = h }, d end
			end
		end
	end
	return best, bd
end

local function ally_hero_near(me, ex, ey, radius)
	for _, h in ipairs(try(Heroes.GetAll) or {}) do
		if not same(h, me) and try(Entity.IsSameTeam, h, me) == true and try(Entity.IsAlive, h)
			and not try(NPC.IsIllusion, h) then
			local ax, ay = try(Entity.GetAbsOriginXYZ, h)
			if ax and math.sqrt((ex - ax) ^ 2 + (ey - ay) ^ 2) <= radius then return true end
		end
	end
	return false
end

-- Союзники бьют цель: урон за секунду выше порога или добивают при малом хп.
local function attacked(me, idx, clk, c)
	local list = S.samples[idx]
	if not list or #list < 2 then return false, 0 end
	local newest = list[#list]
	local mx = math.max(1, newest.mx)
	local pct, recent
	if S.hurt_seen then
		local sum1, sum15 = 0, 0
		for _, h in ipairs(S.ally_hits[idx] or {}) do
			if clk - h.t <= 1.0 then sum1 = sum1 + h.dmg end
			if clk - h.t <= 1.5 then sum15 = sum15 + h.dmg end
		end
		pct, recent = sum1 / mx * 100, sum15 > 0
	else
		if not ally_hero_near(me, newest.x, newest.y, K.ALLY_NEAR) then return false, 0 end
		pct, recent = damage_in(idx, 1.0, clk) / mx * 100, damage_in(idx, 1.5, clk) > 0
	end
	if pct >= c.focus_pct then return true, pct end
	if newest.hp / mx * 100 <= c.kill_hp and recent then return true, pct end
	return false, pct
end

-- Цель убегает: быстро движется от ближайшего союзника или уже оторвалась от всех.
local function escaping(me, idx, ex, ey, clk, c)
	local v = velocity(idx, clk)
	if not v or v.speed < c.escape_speed then return false end
	local ally, dist = nearest_ally(me, ex, ey)
	if not ally or dist >= K.ALLY_FAR then return true end
	local rx, ry = ex - ally.x, ey - ally.y
	local rl = math.sqrt(rx * rx + ry * ry)
	if rl < 1 then return true end
	return (v.x * rx + v.y * ry) / (v.speed * rl) >= K.ESCAPE_COS
end

-- ============================================================================
-- Решение по одному приказу Tornado
-- ============================================================================
-- Возвращает: блок (или nil), пробу для калибровки, таблицу попаданий [idx]=s, параметры.
local function evaluate(me, ab, px, py, pz, clk, c)
	local st = tornado_stats(me, ab)
	local ox, oy = try(Entity.GetAbsOriginXYZ, me)
	if not ox then return nil, nil, {}, st end
	local dx, dy = px - ox, py - oy
	local len = math.sqrt(dx * dx + dy * dy)
	local ux, uy
	if len > 1 then
		ux, uy = dx / len, dy / len
	else
		local f = try(Entity.GetForwardPosition, me, 100)
		if not f then return nil, nil, {}, st end
		ux, uy = f.x - ox, f.y - oy
		local l2 = math.sqrt(ux * ux + uy * uy)
		if l2 < 1e-6 then return nil, nil, {}, st end
		ux, uy = ux / l2, uy / l2
		px, py = ox + ux * 100, oy + uy * 100
	end

	local parts = {
		lat = latency(), tick = tick_interval(), turn = turn_time(me, px, py, pz),
		cp = st.cast_point, bias = S.cal.bias,
	}
	local base = parts.lat + parts.tick + parts.turn + parts.cp + parts.bias

	local block, probe, hits, trace = nil, nil, {}, {}
	local enemies = enemy_heroes(me)
	for _, enemy in ipairs(enemies) do
		local ex, ey = try(Entity.GetAbsOriginXYZ, enemy)
		local hull = try(NPC.GetHullRadius, enemy)
		if type(hull) ~= "number" or hull < 8 or hull > 80 then hull = DATA.HULL end
		local s = ex and path_hit(ox, oy, ux, uy, ex, ey, st.radius + hull, st.distance)
		if s then
			local idx = idx_of(enemy)
			hits[idx] = s
			local eta = base + s / st.speed
			local ctl = control(enemy, me, c)
			trace[#trace + 1] = string.format("%s путь %.0f долёт %.2f контроль %s", display(enemy), s, eta,
				ctl and string.format("%s ост.%s", tostring(ctl.label), ctl.R == math.huge and "?" or string.format("%.2f", ctl.R))
				or "нет")
			if ctl then
				local margin = ctl.channel and c.margin_ch or c.margin
				local need = ctl.R + margin
				if eta < need then
					local wait = need - eta
					if not block or block.mode == "focus" or wait > block.wait then
						block = { mode = "control", idx = idx, wait = wait, R = ctl.R, eta = eta, group = ctl.group,
							label = ctl.label, channel = ctl.channel, name = display(enemy), parts = parts, s = s }
					end
				end
				-- для калибровки: какой стык ожидаем, если Tornado уйдёт сейчас
				if ctl.R > 0 and ctl.R < 30 and (ctl.group == "hard" or ctl.group == "invuln")
					and type(ctl.label) == "string" and not ctl.label:find("^state:") and not ctl.label:find("^channel:")
					and not ctl.label:find("^zone:") then
					probe = probe or { idx = idx, expected_gap = eta - ctl.R, label = ctl.label, channel = ctl.channel,
						x = ex, y = ey }
				end
			elseif c.focus and not block then
				local hit, pct = attacked(me, idx, clk, c)
				if hit and not escaping(me, idx, ex, ey, clk, c) then
					block = { mode = "focus", idx = idx, wait = math.huge, pct = pct, eta = eta, name = display(enemy),
						parts = parts, s = s }
				end
			end
		end
	end
	return block, probe, hits, st, parts, trace, #enemies
end
script._evaluate = evaluate

-- ============================================================================
-- Надписи
-- ============================================================================
local notice = nil
local font

local function show_notice(text)
	if ui.notice:Get() then notice = { text = text, till = os.clock() + K.NOTICE } end
end

local function fmt_block(b)
	if b.mode == "focus" then
		return string.format("Tornado ждёт: %s под ударами союзников (%.0f%% хп за 1 с), он не бежит", b.name, b.pct or 0)
	end
	local left = b.R == math.huge and "?" or string.format("%.2f", b.R)
	local what = b.channel and "канал союзника" or "контроль"
	return string.format("Tornado ждёт: %s, %s ещё %s с, долёт %.2f с", b.name, what, left, b.eta)
end

-- ============================================================================
-- Калибровка по реальным попаданиям
-- ============================================================================
-- Проба создаётся по ПЕРВОМУ пропущенному приказу: комбо долбит приказами, но сервер исполняет первый,
-- остальные (пока идёт каст и перезарядка) он игнорирует.
local function start_probe(p)
	if not ui.autocal:Get() or not p then return end
	if S.probe and os.clock() - S.probe.born < K.PROBE_TTL then return end
	S.probe = { idx = p.idx, expected_gap = p.expected_gap, label = p.label, channel = p.channel,
		x = p.x, y = p.y, born = os.clock(), impact = nil, ctrl_end = nil }
end

local function own_tornado_modifier(m)
	local name = try(Modifier.GetName, m)
	if name == "modifier_invoker_tornado" then return true end
	local ab = try(Modifier.GetAbility, m)
	return ab ~= nil and try(Ability.GetName, ab) == DATA.ABILITY
end

-- Контроль из пробы ещё держится? (по имени модификатора, без учёта нашего же смерча)
local function probe_control_alive(enemy, label)
	for _, m in ipairs(try(NPC.GetModifiers, enemy) or {}) do
		if not own_tornado_modifier(m) and string.lower(try(Modifier.GetName, m) or "") == label then return true end
	end
	return false
end

local function probe_tick()
	local p = S.probe
	if not p then return end
	if os.clock() - p.born > K.PROBE_TTL then
		S.probe = nil
		return
	end
	local enemy = find_by_index(p.idx)
	if not enemy then
		S.probe = nil
		return
	end
	if not p.ctrl_end and not probe_control_alive(enemy, p.label) then p.ctrl_end = game_now() end
	if not (p.impact and p.ctrl_end) then return end
	S.probe = nil
	local gap = p.impact - p.ctrl_end
	if p.channel and gap <= 0.02 then return end -- канал оборвался в момент попадания: не измерить
	if p.moved then return end
	local err = gap - p.expected_gap
	if math.abs(err) > K.CAL_OUTLIER then
		dbg("calibration: outlier gap=%.3f expected=%.3f", gap, p.expected_gap)
		return
	end
	local step = S.cal.n < 2 and K.CAL_FIRST_STEP or K.CAL_STEP
	S.cal.bias = clamp(S.cal.bias + step * err, -K.CAL_MAX, K.CAL_MAX)
	S.cal.n = S.cal.n + 1
	save_calibration()
	Log.Write(string.format("%scalibration: gap %+.3f s, expected %+.3f s, error %+.3f s -> bias %+.3f s (n=%d)",
		TAG, gap, p.expected_gap, err, S.cal.bias, S.cal.n))
end
script._probe_tick = probe_tick

function script.OnModifierCreate(entity, m)
	local p = S.probe
	if not p or p.impact or idx_of(entity) ~= p.idx then return end
	if own_tornado_modifier(m) then
		p.impact = game_now()
		local x, y = try(Entity.GetAbsOriginXYZ, entity)
		if x and p.x and math.sqrt((x - p.x) ^ 2 + (y - p.y) ^ 2) > K.PROBE_STILL then p.moved = true end
	end
end

function script.OnModifierDestroy(entity, m)
	local p = S.probe
	if not p or p.ctrl_end or idx_of(entity) ~= p.idx then return end
	if string.lower(try(Modifier.GetName, m) or "") == p.label then p.ctrl_end = game_now() end
end

function script.OnModifierUpdate(entity, m)
	local p = S.probe
	if p and idx_of(entity) == p.idx and string.lower(try(Modifier.GetName, m) or "") == p.label then
		S.probe = nil -- контроль обновили
	end
end

-- ============================================================================
-- Отложенный каст: стык к концу контроля или в момент бегства
-- ============================================================================
local installed = {} -- имя -> { wrapper, original }

local function schedule(block, c)
	if block.mode == "control" and not c.prolong then return end
	if block.mode == "focus" and not c.escape then return end
	local clk = os.clock()
	local expire
	if block.mode == "control" then
		expire = (block.wait == math.huge or block.R == math.huge) and (clk + K.UNKNOWN_HOLD) or (clk + block.wait + 1.0)
	else
		expire = clk + c.hold
	end
	S.pending = { mode = block.mode, idx = block.idx, expire = expire, name = block.name, born = clk }
end

local function aim_point(me, idx, ex, ey, st, clk)
	local v = velocity(idx, clk)
	if not v or v.speed < 60 then return ex, ey end
	local ox, oy = try(Entity.GetAbsOriginXYZ, me)
	if not ox then return ex, ey end
	local ax, ay = ex, ey
	for _ = 1, 2 do
		local d = math.sqrt((ax - ox) ^ 2 + (ay - oy) ^ 2)
		local t = latency() + tick_interval() + DATA.CAST_POINT + math.max(0, d - st.radius) / st.speed
		local lx, ly = v.x * t, v.y * t
		local l = math.sqrt(lx * lx + ly * ly)
		if l > K.AIM_LEAD_MAX then lx, ly = lx / l * K.AIM_LEAD_MAX, ly / l * K.AIM_LEAD_MAX end
		ax, ay = ex + lx, ey + ly
	end
	return ax, ay
end

local function fire(ab, x, y, z, probe)
	local rec = installed.CastPosition
	local fn = (rec and rec.original) or Ability.CastPosition
	local clk = os.clock()
	S.own_until = clk + K.OWN_ORDER_WINDOW
	S.last_allowed = clk
	S.pending = nil
	start_probe(probe)
	fn(ab, Vector(x, y, z or 0), false, false, true, "tornado_guard")
end

local function pending_tick(clk)
	local p = S.pending
	if not p then return end
	if clk > p.expire then
		S.pending = nil
		dbg("pending expired (%s)", tostring(p.name))
		return
	end
	if S.last_allowed > p.born and clk - S.last_allowed < K.ALLOWED_RECENT then
		S.pending = nil -- комбо само кинуло Tornado в правильный момент
		return
	end
	local me = local_invoker()
	if not me or not try(Entity.IsAlive, me) then
		S.pending = nil
		return
	end
	local ab = try(NPC.GetAbility, me, DATA.ABILITY)
	if not ab or try(Ability.IsHidden, ab) or not try(Ability.IsCastable, ab) then return end
	if try(NPC.IsStunned, me) or try(NPC.IsSilenced, me) then return end
	local enemy = find_by_index(p.idx)
	if not enemy or not try(Entity.IsAlive, enemy) or try(Entity.IsDormant, enemy) then
		S.pending = nil
		return
	end
	local ex, ey, ez = try(Entity.GetAbsOriginXYZ, enemy)
	if not ex then return end
	local c = cfg()
	local st = tornado_stats(me, ab)
	local ax, ay = aim_point(me, p.idx, ex, ey, st, clk)
	local block, probe, hits = evaluate(me, ab, ax, ay, ez, clk, c)
	if not hits[p.idx] then return end -- цель вне досягаемости смерча
	local lead = math.min(K.LEAD_MAX, 0.5 * S.frame_dt)
	p.wait = block and block.wait or 0
	if block and block.wait > lead then return end
	dbg("pending fire: %s (%s)", tostring(p.name), p.mode)
	show_notice(p.mode == "control" and ("Tornado: стык по " .. tostring(p.name)) or ("Tornado: " .. tostring(p.name) .. " побежал"))
	fire(ab, ax, ay, ez, probe)
end
script._pending_tick = pending_tick

-- ============================================================================
-- Проверка приказа (общая для всех путей перехвата)
-- ============================================================================
local last_log = {}
local function rate_log(key, text, gap)
	local t = os.clock()
	if last_log[key] and t - last_log[key] < (gap or 0.3) then return end
	last_log[key] = t
	Log.Write(TAG .. text)
end

-- true: каст разрешён, false: заблокирован. source: "player", "net", "api", "script:<имя>".
local function check(ab, pos, target, source)
	if not ui.enabled:Get() then return true end
	if not ab or try(Ability.GetName, ab) ~= DATA.ABILITY then return true end
	local me = local_invoker()
	if not me then return true end
	local clk = os.clock()
	S.last_order_seen = clk
	if clk < S.own_until then return true end -- наш собственный каст
	if source == "player" and not ui.manual:Get() then return true end

	local px, py, pz
	if pos and pos.x then
		px, py, pz = pos.x, pos.y, pos.z or 0
	elseif target then
		px, py, pz = try(Entity.GetAbsOriginXYZ, target)
	end
	if not px then return true end

	local c = cfg()
	local block, probe, _, _, _, trace, n_enemies = evaluate(me, ab, px, py, pz, clk, c)
	trace = trace or {}
	if not block then
		if ui.debug:Get() then
			rate_log("allow", string.format("ALLOW src=%s врагов %d, на пути: %s", source, n_enemies or 0,
				#trace > 0 and table.concat(trace, " | ") or "никого"))
		end
		S.pending = nil
		S.last_allowed = clk
		start_probe(probe)
		return true
	end

	S.last_block_text = fmt_block(block)
	rate_log("block", string.format("BLOCK src=%s %s [%s]", source, S.last_block_text, table.concat(trace, " | ")), 0.5)
	if ui.debug:Get() and block.parts then
		local p = block.parts
		dbg("BLOCK %s src=%s %s R=%s eta=%.3f (ping %.3f tick %.3f turn %.3f cp %.3f fly %.3f bias %+.3f) wait=%s %s",
			block.mode, source, tostring(block.name), block.R == math.huge and "?" or string.format("%.3f", block.R or 0),
			block.eta or 0, p.lat, p.tick, p.turn, p.cp, (block.s or 0) / DATA.SPEED, p.bias,
			block.wait == math.huge and "?" or string.format("%.3f", block.wait), tostring(block.label))
	end
	show_notice(S.last_block_text)
	S.last_block_wait = block.wait
	-- отказ пришёл из комбо: комбо пропустит Tornado и пойдёт дальше, сами его не кидаем
	if source ~= "api" then schedule(block, c) end
	S.blocked = (S.blocked or 0) + 1
	return false
end
script._check = check

-- ============================================================================
-- Вызов для комбо, которые кастуют мимо Lua-хуков (Jarvis 2 кастует через Panorama JS).
-- В комбо перед кастом Tornado:
--   local api = package.loaded["tornado_guard_api"] or _G.TornadoGuard
--   if api then local stop, why = api.blocks(ability, position, target) ... end
-- Возвращает (true, причина, ждать_секунд), если Tornado сейчас кидать нельзя, иначе false.
-- ждать_секунд = math.huge, если срок контроля неизвестен.
--
-- api.would_block(...) то же самое, но ТОЛЬКО проверка: без надписи, без автокаста. Комбо зовёт его
-- на каждом шаге, чтобы заранее выкинуть Tornado из очереди и не тратить на него Invoke.
-- ============================================================================
local api = { version = VERSION }
function api.blocks(ab, position, target)
	local ok, allowed = pcall(check, ab, position, target, "api")
	if not ok then
		log_once("api_error", "api.blocks ERROR: " .. tostring(allowed))
		return false
	end
	if allowed == false then return true, S.last_block_text, S.last_block_wait or math.huge end
	return false
end

function api.would_block(ab, position, target)
	local ok, stop, why, wait = pcall(function()
		if not ui.enabled:Get() then return false end
		local me = local_invoker()
		if not me then return false end
		if not ab or try(Ability.GetName, ab) ~= DATA.ABILITY then ab = try(NPC.GetAbility, me, DATA.ABILITY) end
		if not ab then return false end
		local px, py, pz
		if position and position.x then
			px, py, pz = position.x, position.y, position.z or 0
		elseif target then
			px, py, pz = try(Entity.GetAbsOriginXYZ, target)
		end
		if not px then return false end
		local block, _, _, _, _, trace = evaluate(me, ab, px, py, pz, os.clock(), cfg())
		if not block then return false end
		local text = fmt_block(block)
		rate_log("combo_skip", string.format("COMBO: %s [%s]", text, table.concat(trace or {}, " | ")), 0.5)
		return true, text, block.wait
	end)
	if not ok then
		log_once("api_would_error", "api.would_block ERROR: " .. tostring(stop))
		return false
	end
	return stop == true, why, wait
end
local function publish_api()
	local ok1 = pcall(function() package.loaded["tornado_guard_api"] = api end)
	local ok2 = pcall(function() _G.TornadoGuard = api end)
	return ok1 or ok2
end
script._api = api

-- ============================================================================
-- Перехват 1: сеть (последний рубеж перед сервером)
-- ============================================================================
local has_protobuf, protobuf = pcall(require, "protobuf")
local has_json, JSON = pcall(require, "assets.JSON")

local function field(o, snake, camel)
	local v = o[snake]
	if v == nil then v = o[camel] end
	return v
end

local function order_type_num(v)
	if type(v) == "number" then return v end
	if type(v) == "string" then return ORDER_NAMES[v] or tonumber(v) end
	return nil
end

local function decode_orders(msg)
	if not (has_protobuf and has_json) then return nil, "нет модулей protobuf/assets.JSON" end
	local js
	-- API 2.0: в колбэке приходит msg_object (указатель на protobuf-сообщение)
	if msg.msg_object ~= nil then
		local ok0, r0 = pcall(protobuf.decodeToJSONfromObject, msg.msg_object)
		if ok0 and type(r0) == "string" and #r0 > 1 then js = r0 end
	end
	if not js and msg.buffer ~= nil then
		local ok1, r1 = pcall(protobuf.decodeToJSON, NET.NAME, msg.buffer, msg.size)
		if ok1 and type(r1) == "string" and #r1 > 1 then js = r1 end
	end
	if not js then return nil, "не удалось разобрать сообщение" end
	local ok3, t = pcall(JSON.decode, JSON, js)
	if not ok3 or type(t) ~= "table" then return nil, "не удалось разобрать JSON" end
	return t, js
end

local function net_filter(msg)
	local me = local_invoker()
	if not me then return true end
	local ab = try(NPC.GetAbility, me, DATA.ABILITY)
	if not ab then return true end
	local tidx = idx_of(ab)
	S.net.seen = S.net.seen + 1
	local t, js = decode_orders(msg)
	if not t then
		S.net.failed = S.net.failed + 1
		S.net.last_error = tostring(js)
		log_once("net_decode", "net filter: " .. tostring(js) .. " (оставлены обёртки функций)")
		return true
	end
	S.net.decoded = S.net.decoded + 1
	if ui.debug:Get() and S.net.dumped < 2 and type(js) == "string" then
		S.net.dumped = S.net.dumped + 1
		Log.Write(TAG .. "net sample: " .. js:sub(1, 400))
	end
	local orders = t.orders
	if type(orders) ~= "table" then return true end
	local keep, blocked_any = {}, false
	for _, o in ipairs(orders) do
		local typ = order_type_num(field(o, "order_type", "orderType"))
		local abi = tonumber(field(o, "ability_index", "abilityIndex"))
		if abi ~= nil and abi == tidx and (typ == NET.CAST_POSITION or typ == NET.CAST_TARGET) then
			local p = field(o, "position", "position")
			local pos = (type(p) == "table" and p.x) and { x = tonumber(p.x) or 0, y = tonumber(p.y) or 0, z = tonumber(p.z) or 0 } or nil
			local target
			if not pos then
				local ti = tonumber(field(o, "target_index", "targetIndex"))
				if ti and ti > 0 then target = try(Entity.Get, ti) end
			end
			if check(ab, pos, target, "net") then
				keep[#keep + 1] = o
			else
				blocked_any = true
			end
		else
			keep[#keep + 1] = o
		end
	end
	if not blocked_any then return true end
	S.net.blocked = S.net.blocked + 1
	if #keep > 0 then
		local out = { orders = keep }
		local lol = field(t, "last_order_latency", "lastOrderLatency")
		if lol ~= nil then out.last_order_latency = lol end
		S.resending = true
		local ok_enc, encoded = pcall(JSON.encode, JSON, out)
		if ok_enc then pcall(NetChannel.SendNetMessage, NET.NAME, encoded) end
		S.resending = false
	end
	return false
end
script._net_filter = net_filter

function script.OnSendNetMessage(msg)
	if type(msg) ~= "table" or S.resending then return true end
	if msg.message_id ~= NET.ID and msg.message_name ~= NET.NAME then return true end
	if not ui.enabled:Get() or not ui.net:Get() then return true end
	local ok, allow = pcall(net_filter, msg)
	if not ok then
		log_once("net_error", "net filter ERROR: " .. tostring(allow))
		return true
	end
	return allow ~= false
end

-- ============================================================================
-- Перехват 2: ручные приказы
-- ============================================================================
function script.OnPrepareUnitOrders(data)
	if type(data) ~= "table" or data.identifier == "tornado_guard" then return true end
	local ok, allow = pcall(check, data.ability, data.position, data.target, "player")
	if not ok then
		log_once("order_error", "order handler ERROR: " .. tostring(allow))
		return true
	end
	return allow
end

-- ============================================================================
-- Перехват 3: обёртки функций каста (для скриптов, которые зовут API напрямую)
-- ============================================================================
local function install(ns, name, extract)
	if type(ns) ~= "table" or type(ns[name]) ~= "function" then return false end
	local current = ns[name]
	local rec = installed[name]
	if rec and current == rec.wrapper then return true end
	local original = current
	local function wrapper(...)
		local args = table.pack(...)
		if ui.hooks:Get() then
			local ok, allow = pcall(function()
				local a, p, t = extract(args)
				return check(a, p, t, "script:" .. name)
			end)
			if ok and allow == false then return nil end
		end
		return original(table.unpack(args, 1, args.n))
	end
	local ok = pcall(function() ns[name] = wrapper end)
	if not ok or ns[name] ~= wrapper then return false end
	installed[name] = { wrapper = wrapper, original = original }
	return true
end

local TARGETS = {
	{ ns = function() return Ability end, name = "CastPosition", extract = function(a) return a[1], a[2], nil end },
	{ ns = function() return Ability end, name = "CastTarget", extract = function(a) return a[1], nil, a[2] end },
	{ ns = function() return Player end, name = "PrepareUnitOrders", extract = function(a) return a[5], a[4], a[3] end },
}

local function install_all(report)
	for _, t in ipairs(TARGETS) do
		local ok = install(t.ns(), t.name, t.extract)
		if report then Log.Write(TAG .. "wrap " .. t.name .. ": " .. (ok and "ok" or "FAILED")) end
	end
end
script._install_all = install_all

local meta_done = {}
local function install_meta(ab)
	local mt = try(getmetatable, ab)
	local index = type(mt) == "table" and mt.__index
	if type(index) ~= "table" or index == Ability or meta_done[index] then return end
	meta_done[index] = true
	local ok_cp = install(index, "CastPosition", function(a) return a[1], a[2], nil end)
	local ok_ct = install(index, "CastTarget", function(a) return a[1], nil, a[2] end)
	Log.Write(TAG .. "wrap (metatable) CastPosition: " .. (ok_cp and "ok" or "FAILED")
		.. ", CastTarget: " .. (ok_ct and "ok" or "FAILED"))
end

-- ============================================================================
-- Колбэки
-- ============================================================================
function script.OnEntityHurt(data)
	if type(data) ~= "table" then return end
	S.hurt_seen = true
	local me = Heroes and try(Heroes.GetLocal)
	local src, tgt = data.source, data.target
	if not me or not src or not tgt then return end
	if try(Entity.IsSameTeam, tgt, me) ~= false or try(Entity.IsSameTeam, src, me) ~= true then return end
	if same(src, me) or try(Entity.RecursiveOwnedBy, src, me) then return end
	local idx = idx_of(tgt)
	if not idx then return end
	local list = S.ally_hits[idx]
	if not list then
		list = {}
		S.ally_hits[idx] = list
	end
	list[#list + 1] = { t = os.clock(), dmg = tonumber(data.damage) or 0 }
end

local function update_status(me, clk)
	if clk - S.status_at < K.STATUS_EVERY then return end
	S.status_at = clk
	local ab = try(NPC.GetAbility, me, DATA.ABILITY)
	if not ab then return end
	local st = tornado_stats(me, ab)
	local net
	if S.net.decoded > 0 then
		net = "сеть: да"
	elseif S.net.failed > 0 then
		net = "сеть: ошибка"
	else
		net = "сеть: ждёт приказ"
	end
	local text = string.format("Wex %d%s: %d ед. · %d ед./с · Quas %d: подъём %.1f с · пинг %d мс · %s",
		st.wex, st.scepter > 0 and "+1" or "", st.distance, st.speed, st.quas, st.lift,
		math.floor(latency() * 1000 + 0.5), net)
	pcall(function() ui.status:Name(text) end)
	pcall(function()
		ui.calib_label:Name(S.cal.n > 0 and string.format("Калибровка: %+d мс по %d стыкам", math.floor(S.cal.bias * 1000 + 0.5), S.cal.n)
			or "Калибровка: нет данных (появится после первого стыка)")
	end)
end

-- Tornado ушёл на перезарядку, а приказа не видел ни один перехват
local function unseen_cast_check(me, clk)
	local ab = try(NPC.GetAbility, me, DATA.ABILITY)
	if not ab then return end
	local cd = try(Ability.GetCooldown, ab) or 0
	if S.prev_cd <= 0.05 and cd > 1 and clk - S.last_order_seen > 1.0 and clk - S.last_warn > 10 then
		S.last_warn = clk
		Log.Write(TAG .. "WARNING: Tornado was cast but no guard layer saw the order. net seen="
			.. S.net.seen .. " decoded=" .. S.net.decoded .. " failed=" .. S.net.failed .. " " .. S.net.last_error)
		show_notice("Tornado ушёл мимо охраны: включи отладку и пришли лог")
	end
	S.prev_cd = cd
end

local last_rewrap = -99
function script.OnUpdate()
	local clk = os.clock()
	if S.last_clock then S.frame_dt = clamp(clk - S.last_clock, 0.001, 0.1) end
	S.last_clock = clk
	if clk - last_rewrap >= K.REWRAP_EVERY then
		last_rewrap = clk
		install_all(false)
	end
	if not ui.enabled:Get() or not try(Engine.IsInGame) then return end
	local me = local_invoker()
	if not me then return end
	if try(GameRules.IsPaused) then return end
	sample_enemies(me, clk)
	refresh_zones(me, clk)
	pending_tick(clk)
	probe_tick()
	unseen_cast_check(me, clk)
	update_status(me, clk)
	local ab = try(NPC.GetAbility, me, DATA.ABILITY)
	if ab then install_meta(ab) end
end

function script.OnDraw()
	if not try(Engine.IsInGame) then return end
	font = font or try(Render.LoadFont, "MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 600)
	if not font then return end
	local t = os.clock()

	-- таймер над врагом, пока Tornado ждёт
	local p = S.pending
	if p and ui.hud:Get() then
		local enemy = find_by_index(p.idx)
		local ex, ey, ez = enemy and try(Entity.GetAbsOriginXYZ, enemy)
		if ex then
			local scr, visible = try(Render.WorldToScreen, Vector(ex, ey, (ez or 0) + 260))
			if scr and visible ~= false then
				local text
				if p.mode ~= "control" then
					text = "Tornado: ждёт бегства"
				elseif p.wait and p.wait < 30 then
					text = string.format("Tornado через %.2f с", math.max(0, p.wait))
				else
					text = "Tornado: ждёт конца контроля"
				end
				local size = 15
				local w = Render.TextSize(font, size, text).x
				local x, y = scr.x - w / 2 - 8, scr.y - 13
				Render.FilledRect(Vec2(x, y), Vec2(x + w + 16, y + 26), Color(12, 16, 26, 210), 6)
				Render.FilledRect(Vec2(x, y + 23), Vec2(x + w + 16, y + 26), Color(90, 200, 255, 230), 2)
				Render.Text(font, size, text, Vec2(x + 8, y + 4), Color(240, 244, 255, 255))
			end
		end
	end

	-- надпись у курсора
	if not notice then return end
	if t > notice.till then
		notice = nil
		return
	end
	local cx, cy = try(Input.GetCursorPos)
	if not cx then return end
	local a = math.min(1, (notice.till - t) / 0.3)
	local size = 14
	local w = Render.TextSize(font, size, notice.text).x
	local x, y = cx + 26, cy + 22
	local function A(v) return math.floor(v * a) end
	Render.FilledRect(Vec2(x, y), Vec2(x + w + 16, y + 26), Color(12, 16, 26, A(215)), 6)
	Render.FilledRect(Vec2(x, y + 3), Vec2(x + 3, y + 23), Color(255, 90, 90, A(255)), 2)
	Render.Text(font, size, notice.text, Vec2(x + 10, y + 5), Color(240, 244, 255, A(255)))
end

function script.OnScriptsLoaded()
	install_all(true)
	publish_api()
end

function script.OnGameEnd()
	S.samples, S.ally_hits, S.pending, S.probe, S.prev_cd = {}, {}, nil, nil, 0
	Z.list = {}
end

install_all(true)
local api_ok = publish_api()
Log.Write(string.format("%sv%s loaded, menu %s, net filter %s, api %s, calibration %+.3f s (n=%d)", TAG, VERSION,
	ok_menu and "ok" or ("FAILED: " .. tostring(err_menu)),
	(has_protobuf and has_json) and "ready" or "unavailable (no protobuf/assets.JSON)",
	api_ok and "published" or "FAILED", S.cal.bias, S.cal.n))

return script
