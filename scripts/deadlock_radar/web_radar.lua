local FB = {
	key = "AIzaSyCGf2e4CIJm1or0klbzXXI5wlfvXPqS514",
	db = "https://umbrella-scripts-default-rtdb.europe-west1.firebasedatabase.app",
	site = "https://4ujiuh.github.io/umbrella-scripts/deadlock.html#",
}

local localization = qLocalization.new({
	en = {
		wr_main = "Connection",
		wr_link_group = "Link",
		wr_data = "Data",
		wr_enabled = "Enabled",
		wr_enabled_tip = "Send the match to the web radar",
		wr_start = "Start",
		wr_stop = "Stop",
		wr_status = "Status",
		wr_link = "Link",
		wr_link_tip = "Open it in a browser or send it to friends",
		wr_new = "New link",
		wr_rate = "Updates per second",
		wr_objectives = "Objectives",
		wr_camps = "Camps",
		wr_powerups = "Powerups, urn, midboss",
		wr_troopers = "Troopers and neutrals",
		wr_pickups = "Pickups",
		wr_mods = "Hero modifiers",
		wr_debug = "Debug log",
		wr_debug_tip = "Log entity classes and map values to the bridge",
		wr_st_off = "off",
		wr_st_auth = "signing in",
		wr_st_live = "live",
		wr_st_fail = "error: HTTP %d",
	},
	ru = {
		wr_main = "Подключение",
		wr_link_group = "Ссылка",
		wr_data = "Данные",
		wr_enabled = "Включено",
		wr_enabled_tip = "Отправлять матч на веб-радар",
		wr_start = "Старт",
		wr_stop = "Стоп",
		wr_status = "Статус",
		wr_link = "Ссылка",
		wr_link_tip = "Откройте в браузере или отправьте друзьям",
		wr_new = "Новая ссылка",
		wr_rate = "Обновлений в секунду",
		wr_objectives = "Цели",
		wr_camps = "Кемпы",
		wr_powerups = "Бонусы, урна, мидбосс",
		wr_troopers = "Крипы и нейтралы",
		wr_pickups = "Подбираемые предметы",
		wr_mods = "Модификаторы героев",
		wr_debug = "Отладка",
		wr_debug_tip = "Писать классы сущностей и значения карты в мост",
		wr_st_off = "выключен",
		wr_st_auth = "вход",
		wr_st_live = "передача",
		wr_st_fail = "ошибка: HTTP %d",
	},
})
local Menu = localization.WrapLibrary(Menu)

local S = {
	token = nil,
	uid = nil,
	expires = 0,
	refresh = db.web_radar_refresh,
	sid = db.web_radar_sid,
	running = false,
	busy = false,
	nextSend = 0,
	nextSlow = 0,
	slow = {},
	stat = "wr_st_off",
	code = 0,
	debugAt = 0,
}

local ui = {}

local function now()
	return global_vars.curtime()
end

local function log(message, data)
	if ui.debug and ui.debug:Get() and global_ctx_t and global_ctx_t.mcp_log then
		global_ctx_t.mcp_log("info", "[WebRadar] " .. message, data)
	end
end

local function setStatus(key, code)
	S.stat, S.code = key, code or 0
	if not ui.status then return end
	local text = localization.Localize(key)
	if code then text = text:format(code) end
	ui.status:ForceLocalization(text)
end

local function request(method, url, body, headers, callback)
	local builder = http.request(url):timeout(10)
	if method == "GET" then builder:get() else builder:post() end
	builder:headers(headers or { ["Content-Type"] = "application/json" })
	if body then builder:body(body) end
	builder:send(function(code, text)
		local decoded = type(text) == "string" and text ~= "" and utils.json_decode(text) or nil
		callback(decoded, code)
	end)
end

local function authorize(callback)
	if S.token and os.time() < S.expires then return callback(true) end
	local function accept(data)
		S.token = data.idToken or data.id_token
		S.refresh = data.refreshToken or data.refresh_token
		S.uid = data.localId or data.user_id
		S.expires = os.time() + math.max(60, (tonumber(data.expiresIn or data.expires_in) or 3600) - 300)
		db.web_radar_refresh = S.refresh
	end
	local function signUp()
		request("POST", "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" .. FB.key, '{"returnSecureToken":true}', nil, function(data, code)
			if code == 200 and data then accept(data) end
			callback(code == 200, code)
		end)
	end
	if not S.refresh or S.refresh == "" then return signUp() end
	request("POST", "https://securetoken.googleapis.com/v1/token?key=" .. FB.key, "grant_type=refresh_token&refresh_token=" .. S.refresh,
		{ ["Content-Type"] = "application/x-www-form-urlencoded" }, function(data, code)
			if code == 200 and data then
				accept(data)
				callback(true, code)
			else
				S.refresh = nil
				signUp()
			end
		end)
end

local function put(path, payload, callback)
	request("POST", FB.db .. "/sessions/" .. S.sid .. path .. ".json?print=silent&auth=" .. S.token, utils.json_encode(payload),
		{ ["Content-Type"] = "application/json", ["X-HTTP-Method-Override"] = "PUT" }, callback)
end

local function newSid()
	local alphabet, out = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", {}
	for i = 1, 20 do
		local n = math.random(1, #alphabet)
		out[i] = alphabet:sub(n, n)
	end
	return table.concat(out)
end

local function round(v)
	return math.floor(v + 0.5)
end

local function calibrate()
	local ok0, p0 = pcall(utils.world_to_map, Vector(0, 0, 0))
	local ok1, p1 = pcall(utils.world_to_map, Vector(10000, 10000, 0))
	if not (ok0 and ok1 and p0 and p1) then return nil end
	local ax, ay = (p1.x - p0.x) / 10000, (p1.y - p0.y) / 10000
	return { ax = ax, bx = p0.x, ay = ay, by = p0.y }
end

local function team(ent)
	local ok, v = pcall(function() return ent.m_iTeamNum end)
	return ok and v or 0
end

local function yawOf(pawn)
	local ang = pawn:get_angles()
	return ang and round(ang.yaw) or nil
end

local function kit(pawn)
	local out = {}
	for slot = 0, 7 do
		local ab = HERO_LIB.get_ability_by_slot(pawn, slot)
		if ab and ab.get_cooldown then
			out[#out + 1] = { s = slot, n = ab:get_name(), l = ab:get_level(), cd = round((ab:get_cooldown() or 0) * 10) / 10 }
		end
	end
	return out
end

local function mods(ent)
	local out = {}
	local list = ent:get_modifiers() or {}
	for i = 1, math.min(#list, 14) do
		local name = list[i]:get_name()
		if name and name ~= "" then out[#out + 1] = name end
	end
	return out
end

local function readField(obj, key)
	local ok, v = pcall(function() return obj[key] end)
	if ok then return v end
end

local function gameRules()
	local gr = game_rules.get()
	if not gr then return nil end
	return {
		ag = readField(gr, "m_nAmberGold"), sg = readField(gr, "m_nSapphireGold"),
		mk = readField(gr, "m_iMidbossKillCount"), ar = readField(gr, "m_iAmberRejuvCount"), sr = readField(gr, "m_iSapphireRejuvCount"),
		p = readField(gr, "m_bServerPaused"), gs = readField(gr, "m_eGameState"), w = readField(gr, "m_iWinningTeam"),
		nb = readField(gr, "m_tNextMidBossSpawnTime"), sp = readField(gr, "m_unSpectatorCount"),
	}
end

local function collectHeroes()
	local rows = {}
	local lp = entity_list.local_pawn()
	for _, pawn in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn")) do
		local pos = pawn:get_origin()
		if pos then
			local name = pawn:get_name() or ""
			rows[#rows + 1] = {
				i = pawn:get_index(),
				n = name:gsub("^hero_", ""),
				t = team(pawn),
				x = round(pos.x),
				y = round(pos.y),
				hp = round(HERO_LIB.get_health(pawn) or 0),
				mh = round(HERO_LIB.get_max_health(pawn) or 0),
				a = pawn:is_alive(),
				d = pawn:is_dormant(),
				v = pawn:is_visible(),
				g = pawn:get_currency(ECurrencyType.EGold),
				ap = pawn:get_currency(ECurrencyType.EAbilityPoints),
				yaw = yawOf(pawn),
				dist = pawn:get_map_district_id(),
				st = round(HERO_LIB.get_stamina(pawn) or 0),
				cc = HERO_LIB.is_stunned(pawn) or HERO_LIB.is_sleeped(pawn) or nil,
				zl = HERO_LIB.is_on_zipline(pawn) or nil,
				me = lp ~= nil and lp:get_index() == pawn:get_index() or nil,
			}
			if rows[#rows].me then rows[#rows].kit = kit(pawn) end
			if ui.mods:Get() then rows[#rows].mods = mods(pawn) end
		end
	end
	return rows
end

local OBJ_PATTERN = { "Boss", "Tower", "Guardian", "Walker", "Shrine", "Patron", "Barrack", "Base" }
local function isObjective(class)
	if class == "C_Citadel_Destroyable_Building" then return true end
	if class:find("^C_?NPC") == nil then return false end
	for _, word in ipairs(OBJ_PATTERN) do
		if class:find(word, 1, true) then return true end
	end
	return false
end

local function collectSlow()
	local slow = {}
	if ui.objectives:Get() or ui.troopers:Get() then
		local objectives, troopers = {}, {}
		for _, ent in ipairs(entity_list.get_all()) do
			local class = ent:get_class_name()
			if ui.objectives:Get() and isObjective(class) then
				local pos = ent:get_origin()
				if pos then
					objectives[#objectives + 1] = {
						c = class, x = round(pos.x), y = round(pos.y), t = team(ent), a = ent:is_alive(),
						hp = round(HERO_LIB.get_health(ent) or 0), mh = round(HERO_LIB.get_max_health(ent) or 0),
					}
				end
			elseif ui.troopers:Get() and class:find("^C_NPC_Trooper") and ent:is_alive() then
				local pos = ent:get_origin()
				if pos then troopers[#troopers + 1] = { round(pos.x), round(pos.y), class == "C_NPC_TrooperNeutral" and 0 or team(ent) } end
			end
		end
		slow.o, slow.tr = objectives, troopers
	end
	if ui.camps:Get() then
		local camps = {}
		for _, camp in ipairs(map_info.camps().items or {}) do
			camps[#camps + 1] = {
				x = round(camp.position.x), y = round(camp.position.y), k = camp.kind, s = camp.state,
				v = camp.visible, hp = camp.current_health, mh = camp.max_health,
				nx = camp.next_spawn and round(camp.next_spawn.earliest_at) or nil,
			}
		end
		slow.c = camps
		local sinners = {}
		for _, sn in ipairs(map_info.sinners().items or {}) do
			sinners[#sinners + 1] = { x = round(sn.position.x), y = round(sn.position.y), hp = sn.health, mh = sn.max_health, a = sn.alive, j = sn.jackpot_active or nil }
		end
		slow.sn = sinners
	end
	if ui.powerups:Get() then
		local ups = {}
		for _, up in ipairs(map_info.powerups().items or {}) do
			local p = up.active_position or up.position
			ups[#ups + 1] = { x = round(p.x), y = round(p.y), s = up.state, k = up.kind, sk = up.spawner_kind, nx = up.next_spawn and round(up.next_spawn.earliest_at) or nil }
		end
		slow.u = ups
		local boss = map_info.midboss()
		if boss and boss.position then
			slow.b = { x = round(boss.position.x), y = round(boss.position.y), s = boss.state, f = boss.health_fraction, nx = boss.next_spawn and round(boss.next_spawn.earliest_at) or nil }
		end
		local urn = map_info.urn()
		if urn then
			slow.ur = { s = urn.state, ct = urn.carrier_team, x = urn.position and round(urn.position.x) or nil, y = urn.position and round(urn.position.y) or nil }
			local dl = {}
			for _, d in ipairs(map_info.urn_deliveries().items or {}) do dl[#dl + 1] = { round(d.position.x), round(d.position.y) } end
			slow.ud = dl
		end
		local rift = map_info.rifts()
		if rift then
			local locs = {}
			for _, l in ipairs(rift.locations or {}) do locs[#locs + 1] = { x = round(l.position.x), y = round(l.position.y), l = l.lane, id = l.id } end
			slow.rf = { ph = rift.phase, aid = rift.active_location_id, wid = rift.warning_location_id, loc = locs, nx = rift.next_open and round(rift.next_open.earliest_at) or nil, ex = rift.expires_at and round(rift.expires_at) or nil }
		end
	end
	if ui.pickups:Get() then
		local pk = {}
		for _, ent in ipairs(entity_list.get_all()) do
			local class = ent:get_class_name()
			if class:find("^C_Citadel_Pickup_") then
				local pos = ent:get_origin()
				if pos then pk[#pk + 1] = { class:sub(18), round(pos.x), round(pos.y) } end
			end
		end
		slow.pk = pk
	end
	return slow
end

local function dumpClasses()
	local counts = {}
	for _, ent in ipairs(entity_list.get_all()) do
		local class = ent:get_class_name()
		if class:find("NPC") or class:find("Citadel") then counts[class] = (counts[class] or 0) + 1 end
	end
	local out = {}
	for class, n in pairs(counts) do out[#out + 1] = class .. "=" .. n end
	table.sort(out)
	log("classes", { list = table.concat(out, " ") })
end

local function send()
	if S.busy then return end
	local t = now()
	if t < S.nextSend then return end
	S.nextSend = t + 1 / ui.rate:Get()
	if t >= S.nextSlow then
		S.nextSlow = t + 1
		S.slow = collectSlow()
		if ui.debug:Get() and t >= S.debugAt then
			S.debugAt = t + 15
			dumpClasses()
		end
	end
	local live = {
		clock = { gt = game_rules.game_time(), mid = game_rules.match_id(), wall = os.time(), me = team(entity_list.local_pawn() or {}) },
		pos = collectHeroes(),
		mp = calibrate(),
		gr = gameRules(),
	}
	for k, v in pairs(S.slow) do live[k] = v end
	S.busy = true
	authorize(function(ok, code)
		if not ok then
			S.busy = false
			return setStatus("wr_st_fail", code)
		end
		put("/live", live, function(_, status)
			S.busy = false
			if status == 200 or status == 204 then setStatus("wr_st_live") else setStatus("wr_st_fail", status) end
		end)
	end)
end

local function start(fresh)
	if fresh or not S.sid or S.sid == "" then
		S.sid = newSid()
		db.web_radar_sid = S.sid
	end
	setStatus("wr_st_auth")
	authorize(function(ok, code)
		if not ok then return setStatus("wr_st_fail", code) end
		put("/meta", { owner = S.uid, started = os.time() }, function(_, status)
			if status ~= 200 and status ~= 204 then return setStatus("wr_st_fail", status) end
			S.running = true
			S.nextSend = 0
			ui.link:Set(FB.site .. S.sid)
			setStatus("wr_st_live")
		end)
	end)
end

local function stop()
	S.running = false
	setStatus("wr_st_off")
end

do
	local section = Menu.Create("Miscellaneous", "", "Web Radar", "General")
	section:Icon("\u{f279}")
	local connection = section:Create("Connection")
	local link = section:Create("Link")
	local data = section:Create("Data")

	ui.enabled = connection:Switch("wr_enabled", false, "\u{f011}")
	ui.enabled:ToolTip("wr_enabled_tip")
	ui.start = connection:Button("wr_start", function() start(false) end)
	ui.stop = connection:Button("wr_stop", stop)
	ui.status = connection:Label("wr_st_off", "\u{f05a}")
	ui.rate = connection:Slider("wr_rate", 1, 10, 4, "%d")
	ui.debug = connection:Switch("wr_debug", false, "\u{f188}")
	ui.debug:ToolTip("wr_debug_tip")

	ui.link = link:Input("wr_link", S.sid and S.sid ~= "" and (FB.site .. S.sid) or "", "\u{f0c1}")
	ui.link:ToolTip("wr_link_tip")
	link:Button("wr_new", function() start(true) end)

	ui.objectives = data:Switch("wr_objectives", true, "\u{f447}")
	ui.camps = data:Switch("wr_camps", true, "\u{f3c5}")
	ui.powerups = data:Switch("wr_powerups", true, "\u{f0eb}")
	ui.troopers = data:Switch("wr_troopers", true, "\u{f0c0}")
	ui.pickups = data:Switch("wr_pickups", true, "\u{f06b}")
	ui.mods = data:Switch("wr_mods", true, "\u{f1de}")
end

callback.on_scripts_loaded:set(function()
	log("loaded", { sid = S.sid })
end)

callback.on_frame:set(function()
	if not ui.enabled:Get() then
		if S.running then stop() end
		return
	end
	if not S.running then return end
	local ok, err = pcall(send)
	if not ok then
		S.busy = false
		log("send error", { error = tostring(err) })
	end
end)
