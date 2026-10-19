--[[
     ~ qLocalization
     ~ automatic localization wrapper for Lua menu interfaces

     ~ author: qfun (qfun_g9s)
]]

local qLocalization = (function()
	local lib = {}

	local a = function(...)
		return ...
	end

	local state = {
		lang = Menu.Find("SettingsHidden", "", "", "", "Main", "Language"),
		instances = {},
	}

	local setters = {
		ToolTip = "tooltip",
	}

	local helpers
	do
		helpers = {
			resolve = a(function(root, path)
				for key in path:gmatch("[^.]+") do
					if type(root) ~= "table" then
						return
					end

					root = root[key]
				end

				return root
			end),

			is_object = a(function(value)
				return type(value) == "table" or type(value) == "userdata"
			end),

			has_method = a(function(object, name)
				return helpers.is_object(object) and type(object[name]) == "function"
			end),

			is_menu_object = a(function(value)
				return helpers.has_method(value, "Name") and helpers.has_method(value, "Type")
			end),

			is_list = a(function(value)
				if type(value) ~= "table" or #value == 0 then
					return false
				end

				for i = 1, #value do
					if type(value[i]) ~= "string" then
						return false
					end
				end

				return true
			end),

			is_indexed_list = a(function(object)
				return helpers.has_method(object, "List") and not helpers.has_method(object, "ListEnabled")
			end),
		}
	end

	function lib.new(translations)
		local languages = {}

		for i, name in ipairs(state.lang and state.lang:List() or {}) do
			local code = name:match("%a+")

			if code and translations[code] then
				languages[i - 1] = code
			end
		end

		local localization = {
			translations = translations,
			languages = languages,
			objects = {},
		}

		local methods
		do
			methods = {
				get_language = a(function(language_index)
					if language_index == nil and state.lang then
						language_index = state.lang:Get()
					end

					return localization.languages[language_index] or "en"
				end),

				localize = a(function(path, language_index)
					if type(path) ~= "string" then
						return path
					end

					local language = methods.get_language(language_index)

					return helpers.resolve(localization.translations[language], path)
						or helpers.resolve(localization.translations.en, path)
						or path
				end),

				has = a(function(path)
					if type(path) ~= "string" then
						return false
					end

					return helpers.resolve(localization.translations.en, path) ~= nil
						or helpers.resolve(localization.translations[methods.get_language()], path) ~= nil
				end),

				localize_items = a(function(items, language_index)
					local result, localized = {}, false

					for i = 1, #items do
						local value = items[i]

						if methods.has(value) then
							result[i] = methods.localize(value, language_index)
							localized = true
						else
							result[i] = value
						end
					end

					return result, localized
				end),

				apply = a(function(object, kind, path, language_index)
					if kind == "label" then
						object:ForceLocalization(methods.localize(path, language_index))
					elseif kind == "tooltip" then
						object:ToolTip(methods.localize(path, language_index))
					elseif kind == "items" then
						local value = object:Get()

						object:Update((methods.localize_items(path, language_index)))
						object:Set(value)
					end
				end),

				track = a(function(object, kind, path, apply_now)
					local record = localization.objects[object]

					if record == nil then
						record = {}
						localization.objects[object] = record
					end

					record[kind] = path

					if apply_now then
						methods.apply(object, kind, path)
					end
				end),

				register = a(function(object, path)
					if not methods.has(path) or not helpers.has_method(object, "ForceLocalization") then
						return
					end

					methods.track(object, "label", path, true)
				end),

				update = a(function(language_index)
					for object, record in pairs(localization.objects) do
						for kind, path in pairs(record) do
							methods.apply(object, kind, path, language_index)
						end
					end
				end),

				wrap = a(function(target, bind_self)
					if not helpers.is_object(target) then
						return target
					end

					local proxy

					proxy = setmetatable({}, {
						__index = function(_, key)
							local member = target[key]

							if type(member) ~= "function" then
								return member
							end

							return function(...)
								local args = table.pack(...)

								if bind_self and args[1] == proxy then
									table.remove(args, 1)
									args.n = args.n - 1
								end

								if key == "Switch" and args.n < 2 then
									args[2] = false
									args.n = 2
								end

								local name_path, item_paths

								if setters[key] then
									if methods.has(args[1]) then
										methods.track(target, setters[key], args[1], false)

										args[1] = methods.localize(args[1])
									end
								else
									local name_index = bind_self and 1 or args.n

									if methods.has(args[name_index]) then
										name_path = args[name_index]
									end

									local items_index

									if key == "Combo" then
										items_index = 2
									elseif key == "Update" and helpers.is_indexed_list(target) then
										items_index = 1
									end

									if items_index ~= nil and helpers.is_list(args[items_index]) then
										local items, localized = methods.localize_items(args[items_index])

										if localized then
											item_paths = args[items_index]
											args[items_index] = items
										end
									end
								end

								local results

								if bind_self then
									results = table.pack(member(target, table.unpack(args, 1, args.n)))
								else
									results = table.pack(member(table.unpack(args, 1, args.n)))
								end

								for i = 1, results.n do
									local result = results[i]

									if helpers.is_menu_object(result) then
										if name_path then
											methods.register(result, name_path)
										end

										if item_paths then
											methods.track(result, "items", item_paths, false)
											item_paths = nil
										end

										results[i] = methods.wrap(result, true)
									end
								end

								if item_paths then
									methods.track(target, "items", item_paths, false)
								end

								return table.unpack(results, 1, results.n)
							end
						end,

						__newindex = function(_, key, value)
							target[key] = value
						end,
					})

					return proxy
				end),
			}
		end

		state.instances[methods] = true

		return {
			GetLanguage = methods.get_language,

			Get = methods.localize,
			Localize = methods.localize,

			Update = methods.update,
			Register = methods.register,

			Wrap = methods.wrap,

			WrapLibrary = function(library)
				return methods.wrap(library, false)
			end,
		}
	end

	if state.lang then
		state.lang:SetCallback(function(this)
			local language_index = this:Get()

			for methods in pairs(state.instances) do
				methods.update(language_index)
			end
		end, true)
	else
		Log.Write("[qLocalization] Language widget not found, using English fallback")
	end

	return lib
end)()

local localization = qLocalization.new({
    en = {
        cr_group_main = "Cloud Radar",
        cr_group_link = "Link for friends",
        cr_group_objects = "Map objects",
        cr_group_details = "Hero info",
        cr_group_events = "Event types",
        cr_group_extras = "Extra objects",
        cr_enabled = "Enable Cloud Radar",
        cr_enabled_tip = "Turn it on, then press Start.\nStop closes the session and the old link.",
        cr_gear_extra = "Diagnostics",
        cr_debug = "Log unknown effects",
        cr_debug_tip = "Writes unknown particle names\nto the AI bridge log",
        cr_status = "Status: %s",
        cr_start = "Start",
        cr_stop = "Stop",
        cr_link = "Link",
        cr_link_tip = "Full link for friends.\nCopy it whole from this field.",
        cr_get_link = "Show link",
        cr_get_link_tip = "Puts the current link\ninto the field above",
        cr_new_link = "New link",
        cr_new_link_tip = "Creates a new link,\nthe old one stops working",
        cr_heroes = "Heroes",
        cr_wards = "Wards",
        cr_wisdom = "Wisdom shrines",
        cr_buildings = "Towers",
        cr_roshan = "Roshan",
        cr_tormentors = "Tormentor",
        cr_runes = "Runes",
        cr_effects = "Map events",
        cr_layer_couriers = "Couriers",
        cr_layer_creeps = "Lane creeps",
        cr_layer_neutrals = "Neutral creeps",
        cr_layer_camps = "Neutral camps",
        cr_camps_tip = "Shows camps and seen neutrals.\nNo visible creeps does not mean farmed.",
        cr_items = "Items",
        cr_abilities = "Abilities and cooldowns",
        cr_modifiers = "Modifiers",
        cr_stats = "Player stats",
        cr_buybacks = "Buyback",
        cr_buybacks_tip = "Real cooldown from Player Resource.\nA ready buyback does not mean enough gold.",
        cr_teleports = "Teleports",
        cr_ultimates = "Ultimates",
        cr_active_items = "Active items",
        cr_casts = "Other abilities",
        cr_scans = "Scan",
        cr_profile = "Load mode",
        cr_profile_tip = "Sets the send rate and\nhow often details refresh",
        cr_profiles_eco = "Economy",
        cr_profiles_balanced = "Balanced",
        cr_profiles_smooth = "Smooth",
        cr_frequency = "Send rate",
        cr_performance_wait = "Radar load: waiting for data",
        cr_performance = "Load: collect %.1f ms, JSON %.1f ms, %.1f KB",
        cr_st_off = "off",
        cr_st_stopping = "stopping",
        cr_st_stopped = "stopped",
        cr_st_closed = "stopped, link closed",
        cr_st_close_fail = "could not close the link: HTTP %d. Press Stop again",
        cr_st_enable_first = "turn Cloud Radar on first",
        cr_st_no_json = "assets.JSON is not loaded",
        cr_st_creating = "creating a session",
        cr_st_connected = "connected, the link can be shared",
        cr_st_connect_fail = "connection error: HTTP %d",
        cr_st_start_first = "press Start first",
        cr_st_link_fail = "could not get the link: HTTP %d. Press Start",
        cr_st_collect_fail = "data collection error: %s",
        cr_st_running = "radar is running",
        cr_st_waiting = "waiting for a match",
        cr_group_server = "Network",
        cr_rate_3 = "3 Hz, lowest load",
        cr_rate_5 = "5 Hz",
        cr_rate_8 = "8 Hz",
        cr_rate_10 = "10 Hz, smooth",
        cr_preset_smooth = "Smooth map, 10 Hz",
        cr_preset_light = "Lowest load, 3 Hz",
        cr_st_auth = "signing in",
        cr_st_auth_fail = "sign-in error: HTTP %d",
        cr_st_link_ready = "the link is in the Link field",
        cr_st_send_fail = "upload failed: HTTP %d, retrying",
        cr_link_hint = "Press Start, then send the link to friends",
        cr_version = "Version 2.1.0, radar for friends",
    },
    ru = {
        cr_group_main = "Cloud Radar",
        cr_group_link = "Ссылка для друзей",
        cr_group_objects = "Объекты",
        cr_group_details = "Информация",
        cr_group_events = "Типы событий",
        cr_group_extras = "Дополнительные объекты",
        cr_enabled = "Включить Cloud Radar",
        cr_enabled_tip = "После включения нажмите Start.\nStop закрывает сессию и старую ссылку.",
        cr_gear_extra = "Диагностика",
        cr_debug = "Неизвестные эффекты в журнал",
        cr_debug_tip = "Пишет имена неизвестных частиц\nв журнал моста",
        cr_status = "Статус: %s",
        cr_start = "Start",
        cr_stop = "Stop",
        cr_link = "Ссылка",
        cr_link_tip = "Полная ссылка для друзей.\nКопируйте ее целиком из этого поля.",
        cr_get_link = "Показать ссылку",
        cr_get_link_tip = "Вставляет текущую ссылку\nв поле выше",
        cr_new_link = "Новая ссылка",
        cr_new_link_tip = "Создает новую ссылку,\nстарая перестает работать",
        cr_heroes = "Герои",
        cr_wards = "Варды",
        cr_wisdom = "Wisdom",
        cr_buildings = "Башни",
        cr_roshan = "Рошан",
        cr_tormentors = "Торментор",
        cr_runes = "Руны",
        cr_effects = "События на карте",
        cr_layer_couriers = "Курьеры",
        cr_layer_creeps = "Линейные крипы",
        cr_layer_neutrals = "Лесные крипы",
        cr_layer_camps = "Нейтральные кемпы",
        cr_camps_tip = "Показывает кемпы и замеченных нейтралов.\nНет видимых крипов не значит зафармлен.",
        cr_items = "Предметы",
        cr_abilities = "Способности и перезарядки",
        cr_modifiers = "Модификаторы",
        cr_stats = "Статистика игроков",
        cr_buybacks = "Байбек",
        cr_buybacks_tip = "Настоящий КД из Player Resource.\nГотовый байбек не значит, что хватит золота.",
        cr_teleports = "Телепорты",
        cr_ultimates = "Ультимейты",
        cr_active_items = "Активные предметы",
        cr_casts = "Остальные способности",
        cr_scans = "Скан",
        cr_profile = "Режим нагрузки",
        cr_profile_tip = "Задает частоту передачи\nи обновление деталей",
        cr_profiles_eco = "Экономный",
        cr_profiles_balanced = "Сбалансированный",
        cr_profiles_smooth = "Плавный",
        cr_frequency = "Частота передачи",
        cr_performance_wait = "Нагрузка радара: ожидание данных",
        cr_performance = "Нагрузка: сбор %.1f мс, JSON %.1f мс, %.1f КБ",
        cr_st_off = "выключен",
        cr_st_stopping = "остановка",
        cr_st_stopped = "остановлен",
        cr_st_closed = "остановлен, ссылка закрыта",
        cr_st_close_fail = "не удалось закрыть ссылку: HTTP %d. Повторите Stop",
        cr_st_enable_first = "сначала включите Cloud Radar",
        cr_st_no_json = "не загружен assets.JSON",
        cr_st_creating = "создание сессии",
        cr_st_connected = "подключен, можно поделиться ссылкой",
        cr_st_connect_fail = "ошибка подключения: HTTP %d",
        cr_st_start_first = "сначала нажмите Start",
        cr_st_link_fail = "не удалось получить ссылку: HTTP %d. Нажмите Start",
        cr_st_collect_fail = "ошибка сбора данных: %s",
        cr_st_running = "радар работает",
        cr_st_waiting = "ожидание матча",
        cr_group_server = "Сеть",
        cr_rate_3 = "3 Гц, минимум нагрузки",
        cr_rate_5 = "5 Гц",
        cr_rate_8 = "8 Гц",
        cr_rate_10 = "10 Гц, плавно",
        cr_preset_smooth = "Плавная карта, 10 Гц",
        cr_preset_light = "Минимум нагрузки, 3 Гц",
        cr_st_auth = "вход",
        cr_st_auth_fail = "ошибка входа: HTTP %d",
        cr_st_link_ready = "ссылка в поле «Ссылка»",
        cr_st_send_fail = "ошибка передачи: HTTP %d, повтор",
        cr_link_hint = "Нажмите Start и отправьте ссылку друзьям",
        cr_version = "Версия 2.1.0, радар для друзей",
    },
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

local script = {}
script.VERSION = "2.1.0"
local ui = {}
local JSON
local state = {
    ready = false, active = false, control = false, pendingStop = false,
    session = nil, url = "", nextSend = 0, nextSlow = 0, sending = false,
    requestId = 0, sentAt = 0, failures = 0, status = nil, statusKey = "cr_st_off",
    heroes = {}, events = {}, particles = {}, units = {}, wards = {}, runes = {}, camps = {},
    match = nil, requests = {}, details = {}, players = {}, nextPlayers = 0,
    casts = {}, castSerial = 0, roshan_units = {}, nextRoshan = 0, genericRates = {},
    flags = {}, nextFlags = 0, classifications = {}, scanJob = nil, detailsBudget = 1, detailCursor = 0,
    layersDirty = true, needFull = true, perf = {collect_ms = 0, encode_ms = 0, scan_ms = 0, bytes = 0},
    campDefs = {}, nextCampDefs = 0, activeEffects = {}, buybacks = {},
    roshanAttackers = {},
    wardMemory = {}, movers = {}, wisdom = {}, destroyed = {}, nextObjects = 0,
    innatePositions = {},
    teleports = {}, tormentor_units = {}, tormentorAttackers = {}, objectiveMotion = {},
    farming = {}, orbParticles = {}, unitMemory = {}, runeMemory = {}, laneMovers = {}, laneCursor = 0, laneList = {},
    courierCosts = {}, nextCouriers = 0, inventoryDirty = {}, courierMotion = {}, courierCursor = 0, courierSamples = {},
    itemKeys = setmetatable({}, {__mode = "k"}), loggedParticles = {},
    fb = {waiters = {}}, sentParts = {}, feedQueue = {}, feedSeq = 0, feedKeys = {}, feedPrune = {}, mem = {}, resendAll = true,
    relay = {units = {}, wards = {}, runes = {}}, kills = {},
}
local start, stop, copyLink
local observeCast
local observeItemEffect
local observeTeleport
local function invalidateDetails(id)
    local cached = state.details[tostring(id)]
    if cached then cached.wall = -math.huge end
end
local function excludedSpell(name)
    return type(name) == "string" and (name:find("sun_strike", 1, true) or name:find("sunstrike", 1, true)
        or name:find("meat_hook", 1, true) or name:find("meathook", 1, true)
        or name:find("mirana_arrow", 1, true) or name:find("mirana_spell_arrow", 1, true)) ~= nil
end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function get(widget, fallback)
    local value = widget and call(widget.Get, widget)
    if value == nil then return fallback end
    return value
end

local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function refreshFlags(now)
    if now < state.nextFlags then return end
    for _, key in ipairs({"heroes", "illusions", "wards", "couriers", "creeps", "neutrals", "wisdom", "buildings", "roshan", "tormentors", "runes", "camps", "effects", "items", "abilities", "modifiers", "stats", "buybacks", "teleports", "ultimates", "active_items", "casts", "projectiles", "scans"}) do
        local enabled = get(ui[key], key ~= "illusions" and key ~= "projectiles")
        if state.flags[key] ~= enabled then state.layersDirty, state.needFull = true, true end
        state.flags[key] = enabled
    end
    state.flags.enabled = get(ui.enabled, false)
    state.rate = ({3, 5, 8, 10})[get(ui.frequency, 1) + 1] or 5
    state.nextFlags = now + 0.5
end

local function clock()
    return os.clock()
end

local function gameClock()
    return call(GameRules and GameRules.GetGameTime) or 0
end

local function show(key, ...)
    local text = string.format(L(key), ...)
    if state.status == text then return end
    state.status, state.statusKey = text, key
    if ui.status then call(ui.status.Name, ui.status, string.format(L("cr_status"), text)) end
    if state.ready and ai_bridge and ai_bridge.mcp_log then
        call(ai_bridge.mcp_log, "info", "[Cloud Radar] status", {key = key, args = {...}})
    end
end

local function resetMatch()
    state.heroes, state.events, state.particles = {}, {}, {}
    state.units, state.wards, state.runes = {}, {}, {}
    state.camps, state.campDefs, state.nextCampDefs = {}, {}, 0
    state.activeEffects, state.buybacks = {}, {}
    state.roshanAttackers = {}
    state.wardMemory, state.movers, state.wisdom, state.destroyed, state.nextObjects = {}, {}, {}, {}, 0
    state.innatePositions = {}
    state.orbParticles = {}
    state.teleports, state.tormentor_units, state.tormentorAttackers, state.objectiveMotion = {}, {}, {}, {}
    state.farming, state.kills = {}, {}
    state.unitMemory, state.runeMemory, state.laneMovers, state.laneCursor = {}, {}, {}, 0
    state.laneList = {}
    state.courierCosts, state.nextCouriers, state.inventoryDirty = {}, 0, {}
    state.courierMotion, state.courierCursor = {}, 0
    state.courierSamples = {}
    state.itemKeys = setmetatable({}, {__mode = "k"})
    state.details, state.players, state.nextPlayers = {}, {}, 0
    state.casts, state.genericRates, state.roshan_units, state.nextRoshan = {}, {}, {}, 0
    state.roshan = nil
    state.classifications, state.scanJob, state.layersDirty, state.needFull = {}, nil, true, true
    state.nextSlow = 0
    state.detailCursor = 0
    state.localTeam, state.roshanLastHp, state.roshanLastTime, state.roshanDamageUntil = nil, nil, nil, 0
end

local function refreshDisabled()
    local on = get(ui.enabled, false)
    for key, widget in pairs(ui) do
        if key ~= "enabled" and key ~= "status" and type(widget) == "table" and widget.Disabled then
            call(widget.Disabled, widget, not on)
        end
    end
end

local function initMenu()
    if state.ready or not UI or not UI.Create then return end
    local root = UI.Create("Scripts", "Main", "Cloud Radar")
    if not root then return end
    root:Icon("\u{f279}")
    local main = root:Create("Main")
    local filters = root:Create("Layers")
    local settings = root:Create("Settings")
    local connection = main:Create("cr_group_main", Enum.GroupSide.Left)
    local link = main:Create("cr_group_link", Enum.GroupSide.Right)
    local objects = filters:Create("cr_group_objects", Enum.GroupSide.Left)
    local details = filters:Create("cr_group_details", Enum.GroupSide.Right)
    local events = filters:Create("cr_group_events", Enum.GroupSide.Right)
    local network = settings:Create("cr_group_server", Enum.GroupSide.Left)
    local extras = settings:Create("cr_group_extras", Enum.GroupSide.Right)
    ui.enabled = connection:Switch("cr_enabled", false, "\u{f011}")
    ui.enabled:ToolTip("cr_enabled_tip")
    local gear = ui.enabled:Gear("cr_gear_extra")
    ui.debug = gear:Switch("cr_debug", false, "\u{f188}")
    ui.debug:ToolTip("cr_debug_tip")
    ui.status = connection:Label("cr_st_off", "\u{f05a}")
    connection:Label("cr_version", "\u{f02b}")
    ui.start = connection:Button("cr_start", function() start() end)
    ui.start:Icon("\u{f144}")
    ui.stop = connection:Button("cr_stop", function() stop() end)
    ui.stop:Icon("\u{f04d}")
    ui.link = link:Input("cr_link", "", "\u{f0c1}")
    ui.link:ToolTip("cr_link_tip")
    ui.getLink = link:Button("cr_get_link", function() copyLink() end)
    ui.getLink:Icon("\u{f0c5}")
    ui.getLink:ToolTip("cr_get_link_tip")
    ui.linkHint = link:Label("cr_link_hint", "\u{f05a}")
    ui.newLink = link:Button("cr_new_link", function() start(true) end)
    ui.newLink:Icon("\u{f021}")
    ui.newLink:ToolTip("cr_new_link_tip")
    for _, row in ipairs({{"heroes", "\u{f007}"}, {"wards", "\u{f06e}"}, {"wisdom", "\u{f0eb}"},
        {"buildings", "\u{f447}"}, {"roshan", "\u{f6d5}"}, {"tormentors", "\u{f3ed}"}, {"runes", "\u{f219}"}, {"effects", "\u{f0f3}"}}) do
        ui[row[1]] = objects:Switch("cr_" .. row[1], true, row[2])
    end
    for _, row in ipairs({{"couriers", "\u{f0d1}"}, {"creeps", "\u{f0c0}"}, {"neutrals", "\u{f1bb}"}, {"camps", "\u{f3c5}"}}) do
        ui[row[1]] = extras:Switch("cr_layer_" .. row[1], true, row[2])
    end
    for _, row in ipairs({{"items", "\u{f290}"}, {"abilities", "\u{f0e7}"},
        {"modifiers", "\u{f1de}"}, {"stats", "\u{f080}"}, {"buybacks", "\u{f155}"}}) do
        ui[row[1]] = details:Switch("cr_" .. row[1], true, row[2])
    end
    for _, row in ipairs({{"teleports", "\u{f0ec}"}, {"ultimates", "\u{f005}"},
        {"active_items", "\u{f135}"}, {"casts", "\u{f0d0}"}, {"scans", "\u{f002}"}}) do
        ui[row[1]] = events:Switch("cr_" .. row[1], true, row[2])
    end
    ui.camps:ToolTip("cr_camps_tip")
    ui.buybacks:ToolTip("cr_buybacks_tip")
    ui.profile = network:Combo("cr_profile", {"cr_profiles_eco", "cr_profiles_balanced", "cr_profiles_smooth"}, 0)
    ui.profile:Icon("\u{f1de}")
    ui.profile:ToolTip("cr_profile_tip")
    ui.frequency = network:Combo("cr_frequency", {"cr_rate_3", "cr_rate_5", "cr_rate_8", "cr_rate_10"}, 1)
    ui.frequency:Icon("\u{f1da}")
    ui.profile:SetCallback(function()
        ui.frequency:Set(({0, 1, 3})[get(ui.profile, 0) + 1] or 1)
        state.nextFlags = 0
    end)
    ui.presetSmooth = network:Button("cr_preset_smooth", function() ui.frequency:Set(3); state.nextFlags = 0 end)
    ui.presetSmooth:Icon("\u{f04e}")
    ui.presetLight = network:Button("cr_preset_light", function() ui.frequency:Set(0); state.nextFlags = 0 end)
    ui.presetLight:Icon("\u{f06c}")
    ui.performance = network:Label("cr_performance_wait", "\u{f05a}")
    ui.enabled:SetCallback(function()
        state.flags.enabled = ui.enabled:Get()
        refreshDisabled()
        if not ui.enabled:Get() then stop() end
    end)
    refreshDisabled()
    state.ready = true
    state.status = nil
    show(state.statusKey or "cr_st_off")
end

local FB = {
    key = "AIzaSyCGf2e4CIJm1or0klbzXXI5wlfvXPqS514",
    db = "https://umbrella-scripts-default-rtdb.europe-west1.firebasedatabase.app",
    site = "https://4ujiuh.github.io/umbrella-scripts/radar.html#",
    config = "cloud_radar",
}

local saved
local function savedPath()
    local dir = call(Engine and Engine.GetCheatDirectory)
    if type(dir) ~= "string" or dir == "" then return nil end
    return (dir:gsub("[\\/]+$", "")) .. "/configs/cloud_radar.json"
end

local function savedGet(key)
    if not saved then
        saved = {}
        local path = savedPath()
        local file = path and io.open(path, "rb")
        if file then
            local decoded = call(JSON and JSON.decode, JSON, file:read("*a") or "")
            file:close()
            if type(decoded) == "table" then saved = decoded end
        end
    end
    local value = saved[key]
    if type(value) ~= "string" then value = call(Config.ReadString, FB.config, key, "") or "" end
    return value
end

local function savedSet(key, value)
    savedGet(key)
    if saved[key] == value then return end
    saved[key] = value
    local path = savedPath()
    local encoded = call(JSON and JSON.encode, JSON, saved)
    local file = path and encoded and io.open(path, "wb")
    if file then
        file:write(encoded)
        file:close()
    end
end

local function wallClock()
    return call(os and os.time) or clock()
end

local function request(method, url, body, callback, headers)
    local pending = {deadline = clock() + 15, finished = false}
    local function finish(decoded, code)
        if pending.finished then return end
        pending.finished = true
        callback(decoded, code)
    end
    pending.finish = finish
    state.requests[#state.requests + 1] = pending
    local data = {headers = headers or {["Content-Type"] = "application/json"}, timeout = 12000}
    if body then data.data = body end
    local sent = call(HTTP and HTTP.Request, method, url, data, function(response)
        local code = tonumber(response and response.code) or 0
        local text = response and response.response or ""
        local decoded = text ~= "" and call(JSON and JSON.decode, JSON, text) or nil
        finish(decoded, code)
    end)
    if not sent then finish(nil, 0) end
end

local function dbRequest(method, sid, body, callback)
    local headers = {["Content-Type"] = "application/json"}
    if method ~= "GET" then headers["X-HTTP-Method-Override"] = method end
    request(method == "GET" and "GET" or "POST", FB.db .. "/sessions/" .. sid .. ".json?print=silent&auth=" .. (state.fb.token or ""),
        body, callback, headers)
end

local function authorize(callback)
    local fb = state.fb
    if fb.token and wallClock() < (fb.expires or 0) then callback(true); return end
    fb.waiters[#fb.waiters + 1] = callback
    if fb.authorizing then return end
    fb.authorizing = true
    local function done(ok, code)
        fb.authorizing = false
        local waiters = fb.waiters
        fb.waiters = {}
        for _, waiter in ipairs(waiters) do waiter(ok, code) end
    end
    local function accept(token, refresh, expires, uid)
        if type(token) ~= "string" or type(uid) ~= "string" then return false end
        fb.token, fb.uid = token, uid
        fb.expires = wallClock() + math.max(60, (tonumber(expires) or 3600) - 300)
        if type(refresh) == "string" and refresh ~= fb.refresh then
            fb.refresh = refresh
            savedSet("refresh_token", refresh)
        end
        return true
    end
    local function signUp()
        request("POST", "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" .. FB.key, '{"returnSecureToken":true}', function(data, code)
            done(code == 200 and type(data) == "table" and accept(data.idToken, data.refreshToken, data.expiresIn, data.localId), code)
        end)
    end
    local refresh = fb.refresh or savedGet("refresh_token")
    if refresh == "" then signUp(); return end
    request("POST", "https://securetoken.googleapis.com/v1/token?key=" .. FB.key, "grant_type=refresh_token&refresh_token=" .. refresh, function(data, code)
        if code == 200 and type(data) == "table" and accept(data.id_token, data.refresh_token, data.expires_in, data.user_id) then
            done(true, code)
        elseif code == 400 then
            fb.refresh = ""
            savedSet("refresh_token", "")
            signUp()
        else done(false, code) end
    end, {["Content-Type"] = "application/x-www-form-urlencoded"})
end

local function newSessionId()
    local alphabet, out = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", {}
    for index = 1, 20 do
        local n = math.random(1, #alphabet)
        out[index] = alphabet:sub(n, n)
    end
    return table.concat(out)
end

local function finishControl()
    state.control = false
    if state.pendingStop or not get(ui.enabled, false) then
        state.pendingStop = false
        stop()
    end
end

stop = function()
    state.active, state.retryAt = false, nil
    state.requestId = state.requestId + 1
    state.sending = false
    if state.control then state.pendingStop = true; show("cr_st_stopping"); return end
    if not state.session then show("cr_st_stopped"); return end
    state.control = true
    authorize(function(ok, code)
        if not ok then state.control = false; show("cr_st_close_fail", code or 0); return end
        dbRequest("DELETE", state.session, nil, function(_, result)
            state.control, state.pendingStop = false, false
            if result >= 200 and result < 300 then
                state.session, state.url = nil, ""
                savedSet("session", "")
                if ui.link then ui.link:Set("") end
                show("cr_st_closed")
            else
                show("cr_st_close_fail", result)
            end
        end)
    end)
end

start = function(rotate)
    if state.control then return end
    if not get(ui.enabled, false) then show("cr_st_enable_first"); return end
    if not JSON then show("cr_st_no_json"); return end
    state.active, state.sending, state.control = false, false, true
    state.requestId = state.requestId + 1
    show("cr_st_auth")
    authorize(function(ok, code)
        if not ok then
            show("cr_st_auth_fail", code or 0)
            state.retryAt = clock() + 5
            finishControl()
            return
        end
        local old = state.session or savedGet("session")
        if not old:match("^%w+$") or #old ~= 20 then old = "" end
        if rotate and old ~= "" then dbRequest("DELETE", old, nil, function() end) end
        local function create(sid, retry)
            show("cr_st_creating")
            local body = string.format('{"meta/owner":%s,"meta/updated":{".sv":"timestamp"},"meta/v":1}',
                call(JSON.encode, JSON, state.fb.uid) or '""')
            dbRequest("PATCH", sid, body, function(_, result)
                if result >= 200 and result < 300 then
                    state.session, state.url = sid, FB.site .. sid
                    savedSet("session", sid)
                    if ui.link then ui.link:Set(state.url) end
                    state.active, state.failures, state.nextSend = true, 0, 0
                    state.needFull, state.layersDirty, state.nextFlags = true, true, 0
                    state.sentParts, state.feedQueue, state.feedSeq, state.mem = {}, {}, 0, {}
                    state.feedBase, state.feedKeys, state.feedPrune = math.floor(wallClock()), {}, {}
                    state.resendAll = true
                    state.relayMatch = sid == old and savedGet("match") or nil
                    refreshFlags(clock())
                    show("cr_st_connected")
                    finishControl()
                elseif retry and (result == 401 or result == 403) then
                    create(newSessionId(), false)
                else
                    show("cr_st_connect_fail", result)
                    if result == 0 or result >= 500 then state.retryAt = clock() + 5 end
                    finishControl()
                end
            end)
        end
        create((not rotate and old ~= "") and old or newSessionId(), true)
    end)
end

copyLink = function()
    if not state.session then show("cr_st_start_first"); return end
    if ui.link then ui.link:Set(state.url) end
    show("cr_st_link_ready")
end

local function pos(vector)
    if not vector then return nil end
    local x, y = vector.x, vector.y
    if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y
        or x == math.huge or x == -math.huge or y == math.huge or y == -math.huge then return nil end
    return {x = x, y = y}
end

local function forgetEntity(id)
    local key, prefix = tostring(id), tostring(id) .. ":"
    state.classifications[id], state.destroyed[id], state.heroes[id] = nil, nil, nil
    for _, name in ipairs({"details", "wardMemory", "unitMemory", "runeMemory", "wisdom", "movers", "laneMovers",
        "courierMotion", "inventoryDirty", "innatePositions", "teleports", "objectiveMotion", "farming", "roshanAttackers", "genericRates"}) do
        state[name][key] = nil
    end
    state.courierSamples[id] = nil
    for _, name in ipairs({"casts", "activeEffects"}) do
        for entry in pairs(state[name]) do if entry:sub(1, #prefix) == prefix then state[name][entry] = nil end end
    end
    for index, orb in pairs(state.orbParticles) do if orb.owner_id == key then state.orbParticles[index] = nil end end
    for entry, attacker in pairs(state.tormentorAttackers) do
        if attacker.id == key or attacker.target_id == key then state.tormentorAttackers[entry] = nil end
    end
    for entry, event in pairs(state.events) do
        if event.owner_id == key then state.events[entry], state.particles[entry] = nil, nil end
    end
    for _, name in ipairs({"units", "wards", "runes"}) do
        for index = #state[name], 1, -1 do if state[name][index].id == key then table.remove(state[name], index) end end
    end
    for _, name in ipairs({"roshan_units", "tormentor_units"}) do
        for index = #state[name], 1, -1 do if state[name][index].row.id == key then table.remove(state[name], index) end end
    end
    if state.scanJob then for _, name in ipairs({"units", "wards"}) do
        for index = #state.scanJob[name], 1, -1 do if state.scanJob[name][index].id == key then table.remove(state.scanJob[name], index) end end
    end end
    state.layersDirty, state.needFull = true, true
end

local function base(unit, kind, now)
    local id = call(Entity.GetIndex, unit)
    if not id then return nil end
    local hidden = call(Entity.IsDormant, unit) == true
    local previous = state.heroes[id]
    if previous and previous.entity and previous.entity ~= unit then
        local retired = previous.entity
        forgetEntity(id)
        state.destroyed[id] = retired
        previous = nil
    end
    local isWard = kind == "observer" or kind == "sentry"
    local isMapObject = isWard or kind == "building" or kind == "roshan" or kind == "tormentor" or kind == "wisdom"
    local location = (not hidden or isMapObject) and pos(call(Entity.GetAbsOrigin, unit)) or nil
    local source = "visible"
    local maphack
    if hidden then
        maphack = kind == "hero" and pos(call(Hero and Hero.GetLastMaphackPos, unit)) or nil
        source = maphack and "maphack_last" or (isMapObject and location and "entity_dormant") or (previous and previous.source == "maphack_last" and "maphack_last" or "last_seen")
        location = maphack or location or previous
    end
    local trace = kind == "hero" and state.innatePositions[tostring(id)]
    if trace and now - trace.observed_at > 3 then state.innatePositions[tostring(id)], trace = nil, nil end
    local maphackTime = maphack and (previous and previous.maphack_x == maphack.x and previous.maphack_y == maphack.y
        and previous.maphack_observed_at or now)
    if hidden and trace and now >= trace.observed_at and now - trace.observed_at <= 3
        and (not maphack or trace.observed_at > maphackTime) then
        location, source = trace, "innate_trace"
    end
    local cached = previous or {}
    cached.entity = unit
    if not cached.identity or clock() >= (cached.nextIdentity or 0) then
        cached.identity = {name = call(NPC.GetUnitName, unit) or kind, team = call(Entity.GetTeamNum, unit),
            max_hp = call(Entity.GetMaxHealth, unit), max_mana = kind == "hero" and call(NPC.GetMaxMana, unit) or nil,
            level = kind == "hero" and call(NPC.GetCurrentLevel, unit) or nil,
            player_id = kind == "hero" and call(Hero.GetPlayerID, unit) or nil}
        cached.nextIdentity = clock() + (kind == "hero" and 1 or 10)
    end
    local identity = cached.identity
    local row = {id = tostring(id), name = identity.name, kind = kind,
        team = identity.team, alive = call(Entity.IsAlive, unit),
        visible = not hidden, source = source, x = location and location.x, y = location and location.y,
        hp = call(Entity.GetHealth, unit), max_hp = identity.max_hp,
        mana = kind == "hero" and call(NPC.GetMana, unit) or nil, max_mana = identity.max_mana,
        level = identity.level, player_id = identity.player_id, heading = false}
    local yaw
    if kind == "hero" and not hidden and Entity.GetRotationPYR then
        local ok, pitch, value = pcall(Entity.GetRotationPYR, unit)
        if ok then yaw = value end
    end
    row.heading = yaw or false
    if not hidden then
        cached.x, cached.y, cached.last_seen = row.x, row.y, now
        cached.position_observed_at = now
        cached.maphack_x, cached.maphack_y, cached.maphack_observed_at = nil, nil, nil
    elseif maphack then
        -- The API supplies cached coordinates, not their original timestamp.
        -- Date only the first/new coordinate observed locally; repeated reads
        -- must not make an old MapHack observation look like fresh visibility.
        if cached.maphack_x ~= maphack.x or cached.maphack_y ~= maphack.y then
            cached.maphack_observed_at = now
        end
        cached.maphack_x, cached.maphack_y = maphack.x, maphack.y
        cached.x, cached.y = maphack.x, maphack.y
        cached.position_observed_at = cached.maphack_observed_at
    elseif isMapObject and location and (cached.x ~= row.x or cached.y ~= row.y) then
        cached.x, cached.y, cached.position_observed_at = row.x, row.y, now
    end
    cached.source = source
    state.heroes[id] = cached
    row.last_seen = cached.last_seen
    row.position_observed_at = cached.position_observed_at
    row.maphack_observed_at = hidden and cached.maphack_observed_at or nil
    row.position_timestamp_source = source == "maphack_last" and "local_observation" or "visibility"
    row.data_stale = hidden
    if not hidden then
        cached.hp, cached.mana, cached.alive = row.hp, row.mana, row.alive
    else
        if finite(cached.hp) then row.hp = cached.hp end
        if finite(cached.mana) then row.mana = cached.mana end
        if (isWard or kind == "neutral" or kind == "building") and cached.alive ~= nil then row.alive = cached.alive end
    end
    if source == "innate_trace" then
        row.position_observed_at, row.innate_observed_at = trace.observed_at, trace.observed_at
        row.position_timestamp_source = "particle_cp0"
    end
    return row
end

local itemModifiers = {
    modifier_black_king_bar_immune = "item_black_king_bar",
    modifier_item_aeon_disk_buff = "item_aeon_disk",
    modifier_item_mask_of_madness_berserk = "item_mask_of_madness",
    modifier_mask_of_madness_berserk = "item_mask_of_madness",
    modifier_item_satanic_unholy = "item_satanic",
    modifier_item_blade_mail_reflect = "item_blade_mail",
    modifier_item_lotus_orb_active = "item_lotus_orb",
    modifier_item_phase_boots_active = "item_phase_boots",
}
local orbModifiers = {modifier_invoker_quas_instance = "quas",
    modifier_invoker_wex_instance = "wex", modifier_invoker_exort_instance = "exort"}

local function inventoryKey(item)
    -- The item entity follows a delivery between hero/courier slots. Names
    -- cannot identify it: one player can own several identical items.
    local id = call(Entity.GetIndex, item)
    return id ~= nil and "item:" .. tostring(id) or tostring(item)
end

local function abilityData(ability, slot, owner, now, hidden, previous, ownerIndex)
    local name = call(Ability.GetName, ability)
    local same = previous and previous.name == name
    local ultimate, passive
    if same then ultimate, passive = previous.ultimate, previous.passive end
    if ultimate == nil then ultimate = call(Ability.IsUltimate, ability) end
    if passive == nil then passive = call(Ability.IsPassive, ability) end
    local info = {slot = slot, name = name, level = call(Ability.GetLevel, ability),
        cooldown = call(Ability.GetCooldown, ability), charges = call(Ability.GetCurrentCharges, ability),
        ultimate = ultimate, passive = passive,
        hidden = call(Ability.IsHidden, ability),
        observed_at = now, source = "ability_api", stale = hidden == true}
    if not finite(info.cooldown) or info.cooldown < 0 then info.cooldown = nil end
    local since = call(Ability.SecondsSinceLastUse, ability)
    if finite(since) and since >= 0 and since <= now and info.cooldown and info.cooldown > 0 then
        info.used_at, info.usage_source = now - since, "ability_last_use"
    end
    if observeCast then observeCast(owner, ability, "ability_sample", now, info, nil, ownerIndex) end
    local id = ownerIndex or call(Entity.GetIndex, owner)
    local effect = id and state.activeEffects[tostring(id) .. ":" .. tostring(info.name)]
    if effect and effect.active_until > now then
        info.active_until, info.active_source = effect.active_until, "modifier"
        info.active_observed_at = effect.observed_at
        if not info.used_at and finite(effect.used_at) then
            info.used_at, info.usage_source = effect.used_at, effect.usage_source
        end
    end
    return info
end

local function heroDetails(unit, row, now, refresh)
    local respawn = row.alive == false and call(Hero.GetRespawnTime, unit) or nil
    row.respawn = row.alive == false and respawn and math.max(0, respawn - now) or 0
    local signature = tostring(state.flags.items) .. tostring(state.flags.abilities)
        .. tostring(state.flags.modifiers) .. tostring(state.flags.stats) .. tostring(state.flags.buybacks)
    local cached = state.details[row.id]
    local detailInterval = get(ui.profile, 0) == 0 and 0.75 or 0.5
    if not refresh or (cached and clock() - cached.wall < detailInterval and signature == cached.signature) then
        if state.needFull then
            if cached then
                row.abilities, row.items, row.modifiers, row.stats, row.buyback, row.details_at, row.orbs = cached.abilities, cached.items, cached.modifiers, cached.stats, cached.buyback, cached.game, cached.orbs
                row.inventory_state, row.items_observed_at = cached.inventory_state, cached.items_observed_at
            end
        end
        return
    end
    if state.detailsBudget <= 0 then return end
    state.detailsBudget = state.detailsBudget - 1
    row.abilities, row.items, row.modifiers, row.orbs = {}, {}, {}, {}
    local invoker = row.name == "npc_dota_hero_invoker" and state.flags.abilities
    local modifiers = (state.flags.modifiers or state.flags.items or invoker) and (call(NPC.GetModifiers, unit) or {}) or {}
    local foundEffects = {}
    for index, modifier in ipairs(modifiers) do
        if index > 64 then break end
        local modifierName = call(Modifier.GetName, modifier)
        local effectItem = itemModifiers[modifierName]
        if invoker and orbModifiers[modifierName] and #row.orbs < 3 then
            row.orbs[#row.orbs + 1] = {name = orbModifiers[modifierName], observed_at = now, stale = row.data_stale}
        end
        if effectItem then foundEffects[effectItem] = true end
        if observeItemEffect then observeItemEffect(unit, modifier, "modifier_sample", now) end
        if state.flags.modifiers then
            local ending = call(Modifier.GetDieTime, modifier)
            row.modifiers[#row.modifiers + 1] = {name = modifierName,
                stacks = call(Modifier.GetStackCount, modifier),
                remaining = finite(ending) and ending > now and ending - now or nil,
                die_time = finite(ending) and ending or nil, observed_at = now, stale = row.data_stale}
        end
    end
    if invoker and #row.orbs == 0 then
        for _, orb in pairs(state.orbParticles) do
            if orb.owner_id == tostring(row.id) and #row.orbs < 3 then
                row.orbs[#row.orbs + 1] = {name = orb.name, observed_at = orb.observed_at,
                    stale = row.data_stale, source = "orb_particle"}
            end
        end
    end
    if not row.data_stale and #modifiers <= 64 and (state.flags.modifiers or state.flags.items) then
        for _, itemName in pairs(itemModifiers) do
            if not foundEffects[itemName] then state.activeEffects[row.id .. ":" .. itemName] = nil end
        end
    end
    local rescanSlots = not cached or clock() >= (cached.nextSlotScan or 0)
        or cached.level ~= row.level or state.inventoryDirty[row.id] or cached.signature ~= signature
    local abilitySlots, itemSlots = {}, {}
    local oldAbilities, oldItems = {}, {}
    if cached then
        for _, entry in ipairs(cached.abilities or {}) do oldAbilities[entry.slot] = entry end
        for _, entry in ipairs(cached.items or {}) do oldItems[entry.slot] = entry end
    end
    if state.flags.abilities then
        for slot = 0, 31 do
            local ability = (rescanSlots or cached.abilitySlots and cached.abilitySlots[slot]) and call(NPC.GetAbilityByIndex, unit, slot)
            if ability then
                abilitySlots[slot] = true
                row.abilities[#row.abilities + 1] = abilityData(ability, slot, unit, now, row.data_stale, oldAbilities[slot], tonumber(row.id))
            end
        end
    end
    if state.flags.items then
        local occupied, reused = {}, false
        for slot = 0, 20 do
            local item = (rescanSlots or cached.itemSlots and cached.itemSlots[slot]) and call(NPC.GetItemByIndex, unit, slot)
            if item then
                itemSlots[slot] = true
                local info = abilityData(item, slot, unit, now, row.data_stale, oldItems[slot], tonumber(row.id))
                info.charges = call(Item and Item.GetCurrentCharges, item)
                local prior = oldItems[slot]
                info.cost = prior and prior.name == info.name and prior.cost or call(Item and Item.GetCost, item)
                if not finite(info.cost) or info.cost < 0 then info.cost = nil end
                row.items[#row.items + 1] = info
                state.itemKeys[info] = inventoryKey(item)
                occupied[slot] = true
            end
        end
        -- A missing slot in fog is not evidence of selling an item. A native
        -- inventory update or fresh visible enumeration may clear old slots.
        if row.data_stale and cached then
            local observedKeys = {}; for _, item in ipairs(row.items) do
                local key = state.itemKeys[item]
                if key then observedKeys[key] = true end
            end
            for _, item in ipairs(cached.items or {}) do
                local key = state.itemKeys[item]
                if not occupied[item.slot] and not (key and observedKeys[key]) then
                    local copy = {}; for key, value in pairs(item) do copy[key] = value end
                    state.itemKeys[copy] = key
                    copy.stale = true; row.items[#row.items + 1] = copy; reused = true
                    itemSlots[item.slot] = true
                end
            end
        end
        row.inventory_state = reused and "last_observation" or row.data_stale and "partial" or "observed"
        row.items_observed_at = reused and cached.items_observed_at or now
    else
        row.inventory_state, row.items_observed_at = false, false
    end
    state.inventoryDirty[row.id] = nil
    row.stats = false
    row.buyback = false
    local playerData = cached and cached.playerData or {}
    if state.flags.stats or state.flags.buybacks then
        local player = state.players[row.player_id]
        if player then
            local team = state.hasLocalHero and row.team == state.localTeam and (call(Player.GetTeamData, player) or {}) or {}
            -- Reuse the native output table, but clear fields that would otherwise
            -- survive a missing field in the next Player Resource observation.
            for key in pairs(playerData) do playerData[key] = nil end
            local info = call(Player.GetTeamPlayer, player, playerData) or {}
            playerData = info
            if state.flags.stats then
                row.stats = {kills = team.kills, deaths = team.deaths, assists = team.assists,
                    networth = finite(info.networth) and info.networth >= 0 and info.networth or nil,
                    networth_source = "player_resource", networth_observed_at = now,
                    lasthits = info.lasthit_count, denies = info.deny_count}
            end
            if state.flags.buybacks then
                local last = state.buybacks[row.player_id]
                local ready = info.buyback_cooldown_time
                local nativeLast = team.last_buyback_time
                if finite(ready) and ready >= 0 or finite(nativeLast) and nativeLast > 0 or last then
                    row.buyback = {ready_at = finite(ready) and ready >= 0 and ready or nil,
                        cooldown = finite(ready) and ready >= 0 and math.max(0, ready - now) or nil,
                        last_at = finite(nativeLast) and nativeLast > 0 and nativeLast or last and last.last_at,
                        last_source = finite(nativeLast) and nativeLast > 0 and "team_data" or last and last.source,
                        source = finite(ready) and ready >= 0 and "player_resource" or last and last.source or "team_data",
                        observed_at = now}
                end
            end
        end
    end
    if state.flags.stats then
        row.stats = type(row.stats) == "table" and row.stats or {}
        local worth, known, itemKeys = 0, false, {}
        for _, item in ipairs(row.items) do
            local key = state.itemKeys[item]
            if finite(item.cost) and not (key and itemKeys[key]) then
                worth, known = worth + item.cost, true
                if key then itemKeys[key] = true end
            end
        end
        local inventoryWorth, courierWorth = worth, 0
        local courier = state.courierCosts[row.player_id]
        if courier then for key, cost in pairs(courier.items) do
            if not itemKeys[key] then
                itemKeys[key] = true
                courierWorth, known = courierWorth + cost, true
            end
        end end
        worth = worth + courierWorth
        -- Player Resource is authoritative. A zero contradicted by observed
        -- gear is unavailable enemy data; publish a labelled lower bound.
        if known and worth > 0 and (not finite(row.stats.networth) or row.stats.networth < worth) then
            local cash = (finite(playerData.reliable_gold) and math.max(0, playerData.reliable_gold) or 0)
                + (finite(playerData.unreliable_gold) and math.max(0, playerData.unreliable_gold) or 0)
            row.stats.networth, row.stats.networth_source = worth + cash, "observed_items_lower_bound"
            row.stats.networth_partial, row.stats.networth_observed_at = true, now
            row.stats.inventory_value, row.stats.courier_value = inventoryWorth, courierWorth
        end
    end
    state.details[row.id] = {wall = clock(), game = now, signature = signature,
        abilities = row.abilities, items = row.items, modifiers = row.modifiers, stats = row.stats,
        buyback = row.buyback, playerData = playerData, orbs = row.orbs,
        inventory_state = row.inventory_state, items_observed_at = row.items_observed_at,
        abilitySlots = abilitySlots, itemSlots = itemSlots, level = row.level,
        nextSlotScan = rescanSlots and clock() + 2 or cached.nextSlotScan}
    row.details_at = now
end

local function classify(unit)
    if call(NPC.GetUnitName, unit) == "npc_dota_xp_fountain" then return "wisdom", "wisdom" end
    if call(NPC.IsWard, unit) then
        local name = call(NPC.GetUnitName, unit) or ""
        return name:find("sentry", 1, true) and "sentry" or "observer", "wards"
    end
    if call(NPC.IsRoshan, unit) then return "roshan", "roshan" end
    if call(NPC.IsTormentor, unit) or call(NPC.GetUnitName, unit) == "npc_dota_miniboss" then return "tormentor", "tormentors" end
    if call(NPC.IsCourier, unit) then return "courier", "couriers" end
    if call(NPC.IsIllusion, unit) or call(NPC.IsMeepoClone, unit) then return "illusion", "illusions" end
    if call(NPC.IsTower, unit) or (call(NPC.GetUnitName, unit) or ""):find("_tower", 1, true) then return "building", "buildings" end
    local neutral = call(NPC.IsNeutral, unit) == true
    if neutral then return "neutral", "neutrals", true end
    if call(NPC.IsLaneCreep, unit) then return "creep", "creeps" end
    return nil
end

local function campDefinition(camp)
    local box = call(Camp and Camp.GetCampBox, camp)
    local low, high = box and pos(box.min), box and pos(box.max)
    local campType = call(Camp and Camp.GetType, camp)
    local id = call(Entity.GetIndex, camp)
    if not id or not low or not high or not finite(campType) or campType < 0 or campType > 3
        or campType % 1 ~= 0 or low.x > high.x or low.y > high.y then return nil end
    return {id = tostring(id), camp_type = campType, x = (low.x + high.x) / 2, y = (low.y + high.y) / 2,
        min_x = low.x, min_y = low.y, max_x = high.x, max_y = high.y,
        stack_count = call(Camp and Camp.GetStackCount, camp),
        z = finite(box.min.z) and box.min.z or 0}
end

local function campVisible(camp)
    -- This is evidence at nine native vision samples, not proof of a cleared
    -- camp. Pulled/stacked neutrals can be outside the spawn box.
    if not FogOfWar or type(FogOfWar.IsPointVisible) ~= "function" then return false end
    for _, x in ipairs({camp.min_x, camp.x, camp.max_x}) do
        for _, y in ipairs({camp.min_y, camp.y, camp.max_y}) do
            local point = call(Vector, x, y, camp.z) or {x = x, y = y, z = camp.z}
            if call(FogOfWar.IsPointVisible, point) ~= true then return false end
        end
    end
    return true
end

local function observeNeutral(job, unit, now)
    if #job.camps == 0 or call(Entity.IsAlive, unit) ~= true then return end
    local p = pos(call(Entity.GetAbsOrigin, unit))
    if not p then return end
    local hidden = call(Entity.IsDormant, unit) == true
    for _, camp in ipairs(job.camps) do
        if p.x >= camp.min_x and p.x <= camp.max_x and p.y >= camp.min_y and p.y <= camp.max_y then
            if hidden then camp.hidden_count = camp.hidden_count + 1
            else camp.count, camp.neutral_at = camp.count + 1, now; camp.representative_name = call(NPC.GetUnitName, unit) end
        end
    end
end

local function finishCamp(camp, previous, now)
    local visibleAfter = campVisible(camp)
    local occupied = camp.count > 0
    local empty = not occupied and camp.hidden_count == 0 and camp.visible_before and visibleAfter
    local status = occupied and "occupied" or empty and "empty" or "unknown"
    local stacks = occupied and finite(camp.stack_count) and camp.stack_count >= 0
        and camp.stack_count <= 256 and camp.stack_count % 1 == 0 and camp.stack_count or nil
    local row = {id = camp.id, x = camp.x, y = camp.y, camp_type = camp.camp_type,
        state = status, source = occupied and "visible_neutrals" or empty and "visible_samples_no_neutrals" or "unobserved",
        observed_at = occupied and camp.neutral_at or now, visible = occupied or empty,
        count = occupied and camp.count or empty and 0 or nil,
        stack_count = stacks, stack_source = stacks and "native_camp" or nil,
        min_x = camp.min_x, min_y = camp.min_y, max_x = camp.max_x, max_y = camp.max_y,
        representative_name = camp.representative_name or previous and previous.representative_name}
    if status == "unknown" and previous then
        row.last_state = previous.state ~= "unknown" and previous.state or previous.last_state
        row.last_observed_at = previous.state ~= "unknown" and previous.observed_at or previous.last_observed_at
        row.last_count = previous.count or previous.last_count
        row.last_stack_count = previous.stack_count or previous.last_stack_count
    end
    local dotaTime = call(GameRules.GetDOTATime, true, true) or 0
    row.memory_until = status == "unknown" and previous and previous.memory_until
        or now + (60 - math.max(0, dotaTime) % 60)
    return row
end

local function rememberUnit(unit, row, now)
    if row.kind == "neutral" or row.kind == "building" then
        local previous = state.unitMemory[row.id]
        if row.alive == false and row.visible then state.unitMemory[row.id] = nil; return end
        if row.visible and row.x then
            if row.kind == "neutral" then
                local dotaTime = call(GameRules.GetDOTATime, true, true) or 0
                row.memory_until = now + (60 - math.max(0, dotaTime) % 60)
            end
            state.unitMemory[row.id] = {unit = unit, row = row}
        elseif previous then
            row.x, row.y, row.hp, row.max_hp = previous.row.x, previous.row.y, previous.row.hp, previous.row.max_hp
            row.memory_until, row.position_observed_at = previous.row.memory_until, previous.row.position_observed_at
            row.source, row.visible, row.data_stale = "last_observation", false, true
        end
    elseif row.kind == "creep" then
        if row.alive ~= false then
            local entry = state.laneMovers[row.id]
            if entry and entry.unit == unit then entry.row = row
            else state.laneMovers[row.id] = {unit = unit, row = row} end
        else state.laneMovers[row.id] = nil end
    end
end

local function slowSnapshot(now)
    if not state.scanJob then
        local refreshCamps = state.flags.camps and clock() >= state.nextCampDefs
        local campList = state.flags.camps and (refreshCamps and call(Camps and Camps.GetAll) or state.campDefs) or {}
        local previous = {}
        for _, camp in ipairs(state.camps) do previous[camp.id] = camp end
        local list, seen = {}, {}
        for _, unit in ipairs(call(NPCs and NPCs.GetAll) or {}) do list[#list + 1] = unit; seen[unit] = true end
        if state.flags.buildings then for _, tower in ipairs(call(Towers and Towers.GetAll) or {}) do
            if not seen[tower] then list[#list + 1] = tower end
        end end
        state.scanJob = {list = list, index = 1, units = {}, wards = {}, roshan = {}, tormentors = {},
            phase = "camps", campList = campList or {}, campIndex = 1, refreshCamps = refreshCamps,
            campDefs = {}, camps = {}, previousCamps = previous, finishedCamps = {}}
    end
    local job, began, count, campWork = state.scanJob, clock(), 0, 0
    while count < 16 and clock() - began < 0.0015 do
        if job.phase == "camps" then
            if job.campIndex > #job.campList or job.campIndex > 256 then
                if job.refreshCamps then state.campDefs, state.nextCampDefs = job.campDefs, clock() + 1.5 end
                job.phase = "units"
            else
                if campWork >= 2 then break end
                local definition
                if job.refreshCamps then definition = campDefinition(job.campList[job.campIndex])
                else definition = job.campList[job.campIndex] end
                job.campIndex, count, campWork = job.campIndex + 1, count + 1, campWork + 1
                if definition then
                    job.campDefs[#job.campDefs + 1] = definition
                    local camp = {}
                    for key, value in pairs(definition) do camp[key] = value end
                    camp.count, camp.hidden_count, camp.visible_before = 0, 0, campVisible(camp)
                    job.camps[#job.camps + 1] = camp
                end
            end
        elseif job.phase == "camp_finish" then
            if job.campIndex > #job.camps then break end
            if campWork >= 2 then break end
            local camp = job.camps[job.campIndex]
            job.finishedCamps[#job.finishedCamps + 1] = finishCamp(camp, job.previousCamps[camp.id], now)
            job.campIndex, count, campWork = job.campIndex + 1, count + 1, campWork + 1
        elseif job.index > #job.list then
            job.phase, job.campIndex = "camp_finish", 1
        else
            local unit = job.list[job.index]
            job.index, count = job.index + 1, count + 1
            local identity = call(Entity.GetIndex, unit)
            local classification = identity and state.classifications[identity]
            if not classification and state.destroyed[identity] ~= unit then
                local kind, filter, neutral = classify(unit)
                classification = {kind = kind, filter = filter, neutral = neutral}
                if identity then state.classifications[identity] = classification end
            end
            classification = classification or {}
            if classification.neutral and state.destroyed[identity] ~= unit then observeNeutral(job, unit, now) end
            local kind, filter = classification.kind, classification.filter
            if kind and state.flags[filter] and state.destroyed[identity] ~= unit then
                local row = base(unit, kind, now)
                if row then
                    rememberUnit(unit, row, now)
                    if kind == "courier" then state.movers[row.id] = unit end
                    if kind == "wisdom" then
                        local previous = state.wisdom[row.id]
                        if previous and (previous.unit == unit or previous.unit == nil) then
                            for _, key in ipairs({"active", "cycle", "taken_at", "observed_at"}) do row[key] = previous.row[key] end
                        end
                        state.wisdom[row.id] = {unit = unit, row = row}
                    end
                    if kind == "roshan" then job.roshan[#job.roshan + 1] = {unit = unit, row = row} end
                    if kind == "tormentor" then job.tormentors[#job.tormentors + 1] = {unit = unit, row = row} end
                    if kind == "observer" or kind == "sentry" then
                        row.radius = kind == "sentry" and 900 or call(NPC.GetDayTimeVisionRange, unit)
                        for _, modifier in ipairs(call(NPC.GetModifiers, unit) or {}) do
                            local name = call(Modifier.GetName, modifier) or ""
                            if name:find("ward", 1, true) then
                                local ending = call(Modifier.GetDieTime, modifier)
                                if finite(ending) and ending > now then row.expires_at, row.remaining = ending, ending - now end
                            end
                        end
                        if #job.wards < 512 then
                            row.observed_at = now
                            local previous = state.wardMemory[row.id]
                            if previous then
                                row.x, row.y = previous.x, previous.y
                                row.expires_at = row.expires_at or previous.expires_at
                                if row.visible == false then row.observed_at = previous.observed_at end
                            end
                            if row.expires_at then row.remaining = math.max(0, row.expires_at - now) end
                            if row.alive == false then state.wardMemory[row.id] = nil
                            else state.wardMemory[row.id] = row; job.wards[#job.wards + 1] = row end
                        end
                    elseif #job.units < 512 then job.units[#job.units + 1] = row end
                end
            end
        end
    end
    if job.phase == "units" and job.index > #job.list then job.phase, job.campIndex = "camp_finish", 1 end
    if job.phase ~= "camp_finish" or job.campIndex <= #job.camps then return end
    local seen = {}
    for _, row in ipairs(job.units) do seen[row.id] = true end
    for id, entry in pairs(state.unitMemory) do
        local row = entry.row
        if row.memory_until and row.memory_until <= now then state.unitMemory[id] = nil
        elseif not seen[id] and state.flags[row.kind == "neutral" and "neutrals" or "buildings"] and #job.units < 512 then
            local copy = {}; for key, value in pairs(row) do copy[key] = value end
            copy.visible, copy.data_stale, copy.source = false, true, "last_observation"
            job.units[#job.units + 1] = copy
        end
    end
    seen = {}
    for _, row in ipairs(job.wards) do seen[row.id] = true end
    if state.flags.wards then
        for id, row in pairs(state.wardMemory) do
            if row.alive == false or row.expires_at and row.expires_at <= now then state.wardMemory[id] = nil
            elseif not seen[id] and #job.wards < 512 then
                local copy = {}; for key, value in pairs(row) do copy[key] = value end
                copy.visible, copy.data_stale = false, true
                state.wardMemory[id] = copy
                job.wards[#job.wards + 1] = copy
            end
        end
    end
    state.units, state.wards, state.roshan_units = job.units, job.wards, job.roshan
    local present = {}; for _, row in ipairs(job.units) do present[row.id] = true end
    for id in pairs(state.laneMovers) do if not present[id] then state.laneMovers[id] = nil end end
    state.laneList = {}; for _, entry in pairs(state.laneMovers) do state.laneList[#state.laneList + 1] = entry end
    state.tormentor_units = job.tormentors
    state.camps = state.flags.camps and job.finishedCamps or {}
    state.scanJob, state.layersDirty, state.nextSlow = nil, true, clock() + (get(ui.profile, 0) == 2 and 1 or 1.5)
end

local function objectSnapshot(now, packet)
    -- Small cached sets only. Couriers bypass the full NPC scan; rune and
    -- shrine observations run at 4 Hz, with at most 16 courier samples/packet.
    packet.units_patch = {}
    if state.flags.couriers then
        local count = 0
        for id, unit in pairs(state.movers) do
            if count >= 16 then break end
            count = count + 1
            if state.destroyed[call(Entity.GetIndex, unit)] == unit or call(Entity.IsAlive, unit) == false then
                packet.units_patch[#packet.units_patch + 1] = {id = id, _delete = true}; state.movers[id] = nil
            else
                local row = base(unit, "courier", now)
                if row then
                    local prior = state.courierMotion[id]
                    if row.visible and row.x then
                        local dt = prior and now - prior.time or 0
                        if dt > 0 and dt <= 1 and math.abs(row.x - prior.x) + math.abs(row.y - prior.y) < 1800 then
                            row.vx, row.vy = (row.x - prior.x) / dt, (row.y - prior.y) / dt
                            row.motion_source, row.motion_observed_at = "observed_displacement", now
                        end
                        state.courierMotion[id] = {x = row.x, y = row.y, time = now}
                    end
                    packet.units_patch[#packet.units_patch + 1] = row
                end
            end
        end
    end
    -- Moving lane creeps use a bounded round-robin cache, not NPCs.GetAll.
    if state.flags.creeps then
        local list = state.laneList
        for step = 1, math.min(32, #list) do
            state.laneCursor = state.laneCursor % #list + 1
            local entry = list[state.laneCursor]
            local row, unit = entry.row, entry.unit
            if state.laneMovers[row.id] == entry then
                if now >= (entry.nextVisibility or 0) then
                    entry.hidden, entry.alive = call(Entity.IsDormant, unit) == true, call(Entity.IsAlive, unit)
                    entry.nextVisibility = now + 0.25
                end
                if entry.alive == false then
                    packet.units_patch[#packet.units_patch + 1] = {id = row.id, _delete = true}; state.laneMovers[row.id] = nil
                elseif not entry.hidden then
                    local p = pos(call(Entity.GetAbsOrigin, unit))
                    if p then
                        local dt = entry.seenAt and now - entry.seenAt
                        if dt and dt > 0 and dt <= 2 and finite(row.x) then
                            entry.vx, entry.vy = (p.x - row.x) / dt, (p.y - row.y) / dt
                        end
                        entry.seenAt, entry.ms = now, entry.ms or call(NPC.GetMoveSpeed, unit)
                        row.x, row.y, row.visible, row.data_stale, row.position_observed_at = p.x, p.y, true, false, now
                        packet.units_patch[#packet.units_patch + 1] = {id = row.id, _merge = true,
                            x = p.x, y = p.y, visible = true, data_stale = false, source = "visible", position_observed_at = now}
                    end
                elseif row.visible ~= false then
                    row.visible, row.data_stale = false, true
                    packet.units_patch[#packet.units_patch + 1] = {id = row.id, _merge = true, visible = false, data_stale = true}
                end
            end
        end
    end
    if clock() < state.nextObjects then return end
    state.nextObjects = clock() + 0.25
    local couriers = (state.flags.couriers or state.flags.stats) and call(Couriers and Couriers.GetAll) or {}
    for index, unit in ipairs(couriers or {}) do
        if index > 16 then break end
        local id = call(Entity.GetIndex, unit)
        if state.flags.couriers and id and state.destroyed[id] ~= unit then state.movers[tostring(id)] = unit end
    end
    -- Sample one courier inventory per object tick; include only items with
    -- native player ownership. No guess from which courier is nearest a hero.
    if state.flags.stats and #couriers > 0 then
        state.courierCursor = state.courierCursor % math.min(16, #couriers) + 1
        local unit = couriers[state.courierCursor]
        local id = call(Entity.GetIndex, unit)
        if id then
            local values = {}
            if state.destroyed[id] ~= unit and call(Entity.IsAlive, unit) ~= false then
                for slot = 0, 20 do
                    local item = call(NPC.GetItemByIndex, unit, slot)
                    local owner = item and call(Item and Item.GetPlayerOwnerID, item)
                    local cost = item and call(Item and Item.GetCost, item)
                    if finite(owner) and owner >= 0 and finite(cost) and cost >= 0 then
                        values[owner] = values[owner] or {}
                        values[owner][inventoryKey(item)] = cost
                    end
                end
            end
            state.courierSamples[id] = {values = values, observed_at = now}
        end
    end
    state.courierCosts = {}
    for id, sample in pairs(state.courierSamples) do
        if now - sample.observed_at > 4 then state.courierSamples[id] = nil
        else for owner, items in pairs(sample.values) do
            local entry = state.courierCosts[owner] or {items = {}, observed_at = sample.observed_at}
            for key, cost in pairs(items) do entry.items[key] = cost end
            state.courierCosts[owner] = entry
        end end
    end
    local runes, runeSeen = {}, {}
    if state.flags.runes then for _, rune in ipairs(call(Runes and Runes.GetAll) or {}) do
        local id, hidden = call(Entity.GetIndex, rune), call(Entity.IsDormant, rune) == true
        if id and state.destroyed[id] ~= rune and #runes < 64 then
            local remembered = state.runeMemory[tostring(id)]
            local previous = remembered and remembered.row
            local p = not hidden and pos(call(Entity.GetAbsOrigin, rune)) or previous
            if p then
                local kind = not hidden and (call(Rune and Rune.GetRuneType, rune) or call(Entity.GetField, rune, "m_iRuneType")) or previous and previous.rune_type
                local row = {id = tostring(id), x = p.x, y = p.y, rune_type = finite(kind) and kind >= 0 and kind <= 9 and kind or nil,
                    name = call(Entity.GetUnitName, rune) or "Rune", visible = not hidden, data_stale = hidden,
                    observed_at = not hidden and now or previous and previous.observed_at, source = hidden and "last_observation" or "entity"}
                local dotaTime = call(GameRules.GetDOTATime, true, true) or 0
                -- Standard 7.41 clocks: bounty 4 min; water/power 2 min.
                -- Turbo uses half the scheduled interval.
                local turbo = Enum.GameMode and call(GameRules.GetGameMode) == Enum.GameMode.DOTA_GAMEMODE_TURBO
                local period = kind == 5 and 240 or kind == 8 and 420 or 120
                if turbo then period = period / 2 end
                row.memory_until = hidden and previous and previous.memory_until or now + (period - math.max(0, dotaTime) % period)
                row.next_expected_at = row.memory_until
                state.runeMemory[row.id] = {unit = rune, row = row}
                runeSeen[row.id] = not hidden
            end
        end
    end end
    if state.flags.runes then for id, entry in pairs(state.runeMemory) do
        local row = entry.row
        if row.memory_until and row.memory_until <= now then state.runeMemory[id] = nil
        elseif #runes < 64 then
            local copy = {}; for key, value in pairs(row) do copy[key] = value end
            if not runeSeen[id] then copy.visible, copy.data_stale, copy.source = false, true, "last_observation" end
            runes[#runes + 1] = copy
        end
    end end
    state.runes, packet.runes = runes, runes
    local wards = {}
    if state.flags.wards then for id, row in pairs(state.wardMemory) do
        if row.alive == false or row.expires_at and row.expires_at <= now then state.wardMemory[id] = nil
        else wards[#wards + 1] = row end
    end end
    state.wards, packet.wards = wards, wards
    for _, entry in pairs(state.wisdom) do
        local unit, row = entry.unit, entry.row
        if state.flags.wisdom then
            local hidden = unit == nil or call(Entity.IsDormant, unit) == true
            local native
            if not hidden then native = call(Entity.GetField, unit, "m_bActive") end
            local cycle = math.floor(math.max(0, call(GameRules.GetDOTATime, true, true) or 0) / 420)
            local value = type(native) == "boolean" and native or type(native) == "number" and native ~= 0 or nil
            if native == false or native == 0 then value = false end
            if row.cycle ~= cycle then row.taken_at, row.active = nil, nil end
            if value ~= nil then
                if value == false and row.active == true and row.cycle == cycle and now - (row.observed_at or 0) <= 2 then row.taken_at = now end
                row.active, row.observed_at, row.source = value, now, "native_active"
            end
            row.cycle, row.visible, row.data_stale = cycle, not hidden, hidden or value == nil
            local dotaTime = call(GameRules.GetDOTATime, true, true) or 0
            row.next_expected_at, row.schedule_source = now + ((math.floor(math.max(0, dotaTime) / 420) + 1) * 420 - dotaTime), "match_cycle_420"
        end
    end
end

local function isRoshan(unit)
    return unit ~= nil and (call(NPC.IsRoshan, unit) == true or call(NPC.GetUnitName, unit) == "npc_dota_roshan")
end

local function isTormentor(unit)
    return unit ~= nil and (call(NPC.IsTormentor, unit) == true or call(NPC.GetUnitName, unit) == "npc_dota_miniboss")
end
local function attackerOwner(unit)
    local owner = call(NPC.GetOwnerNPC, unit) or call(Entity.GetOwner, unit)
    local name = owner and call(NPC.GetUnitName, owner)
    if type(name) == "string" and name:find("npc_dota_hero_", 1, true) == 1 then
        local id = call(Entity.GetIndex, owner)
        return id and tostring(id), name
    end
end

local function recordTormentorAttacker(unit, target, source, now, damage)
    local owner, targetId = call(Entity.GetIndex, unit), call(Entity.GetIndex, target)
    if owner == nil or targetId == nil or call(Entity.IsAlive, unit) == false then return end
    local heroId, heroName = attackerOwner(unit)
    state.tormentorAttackers[tostring(targetId) .. ":" .. tostring(owner)] = {id = tostring(owner), target_id = tostring(targetId),
        hero_id = heroId, hero_name = heroName,
        name = call(NPC.GetUnitName, unit), team = call(Entity.GetTeamNum, unit), observed_at = now,
        source = source, damage = finite(damage) and damage > 0 and damage or nil,
        stale = source == "attack_target" and call(Entity.IsDormant, unit) == true}
end

local function objectivePosition(unit, kind, now)
    local row = base(unit, kind, now)
    if not row then return {} end
    local previous = state.objectiveMotion[row.id]
    if row.x and row.y then
        if previous and (previous.x ~= row.x or previous.y ~= row.y) then
            local distance = math.sqrt((row.x - previous.x)^2 + (row.y - previous.y)^2)
            if now >= previous.time and now - previous.time <= 2 and distance > 16 then
                previous.from_x, previous.from_y, previous.moved_at = previous.x, previous.y, now
                previous.relocated = distance > 1800
            end
        end
        previous = previous or {}
        previous.x, previous.y, previous.time = row.x, row.y, now
        state.objectiveMotion[row.id] = previous
    end
    return {x = row.x, y = row.y, visible = row.visible, position_source = row.source,
        position_observed_at = row.position_observed_at, moving = previous and previous.moved_at and now - previous.moved_at <= 1.5 or false,
        move_from_x = previous and previous.from_x, move_from_y = previous and previous.from_y,
        relocated = previous and previous.relocated}
end

local function tormentorSnapshot(now)
    local result = {}
    if not state.flags.tormentors then return result end
    for _, entry in ipairs(state.tormentor_units) do
        local unit, row = entry.unit, entry.row
        local info = objectivePosition(unit, "tormentor", now)
        info.id, info.hp, info.max_hp, info.alive = row.id, call(Entity.GetHealth, unit), call(Entity.GetMaxHealth, unit), call(Entity.IsAlive, unit)
        info.stale, info.observed_at, info.attackers = call(Entity.IsDormant, unit) == true, now, {}
        local motion = state.objectiveMotion[row.id]
        if motion and not info.stale and finite(info.hp) then
            if finite(motion.hp) and finite(motion.hp_at) and now >= motion.hp_at and now - motion.hp_at < 2
                and info.hp < motion.hp then motion.damage_until = now + 2 end
            motion.hp, motion.hp_at = info.hp, now
            if info.alive ~= false and finite(motion.damage_until) and now < motion.damage_until then info.under_attack = true end
        end
        for key, attacker in pairs(state.tormentorAttackers) do
            if now < attacker.observed_at or now - attacker.observed_at >= 4 then state.tormentorAttackers[key] = nil
            elseif attacker.target_id == row.id and info.alive ~= false then
                info.attackers[#info.attackers + 1] = attacker
                if attacker.stale ~= true then info.under_attack = true end
            end
        end
        result[#result + 1] = info
        if #result >= 8 then break end
    end
    return result
end

observeTeleport = function(unit, modifier, now)
    if not state.active or not state.flags.teleports or call(Modifier.GetName, modifier) ~= "modifier_teleporting" then return end
    local id, ending = call(Entity.GetIndex, unit), call(Modifier.GetDieTime, modifier)
    if id == nil or not finite(ending) or ending <= now or ending > now + 90 then return end
    local previous, started = state.teleports[tostring(id)], call(Modifier.GetCreationTime, modifier)
    state.teleports[tostring(id)] = {ends_at = ending, started_at = finite(started) and started <= now and started or nil,
        observed_at = previous and previous.ends_at == ending and previous.observed_at or now,
        source = "modifier_teleporting", stale = call(Entity.IsDormant, unit) == true}
end

local function sampleTeleport(unit, row, now)
    if not state.flags.teleports then return end
    local modifier = call(NPC.GetModifier, unit, "modifier_teleporting")
    if modifier then observeTeleport(unit, modifier, now)
    elseif row.visible == true and type(NPC.GetModifier) == "function" and state.teleports[row.id] then
        state.teleports[row.id] = nil
        for id, event in pairs(state.events) do
            if event.kind == "teleport" and event.owner_id == row.id and event.channel_end_at then state.events[id], state.particles[id] = nil, nil end
        end
    end
    local channel = state.teleports[row.id]
    if channel and channel.ends_at <= now then state.teleports[row.id], channel = nil, nil end
    if channel then
        row.teleport = {}; for key, value in pairs(channel) do row.teleport[key] = value end
    end
end

local function recordRoshanAttacker(unit, source, now, damage)
    local id = unit and call(Entity.GetIndex, unit)
    local name = unit and call(NPC.GetUnitName, unit)
    if id == nil or type(name) ~= "string" or name == "" or call(Entity.IsAlive, unit) == false then return end
    local key = tostring(id)
    local previous = state.roshanAttackers[key]
    if source == "attack_target" and previous and previous.source == "damage_event" and now - previous.observed_at < 1 then return end
    local heroId, heroName = attackerOwner(unit)
    state.roshanAttackers[key] = {id = key, name = name, team = call(Entity.GetTeamNum, unit),
        hero_id = heroId, hero_name = heroName,
        observed_at = now, source = source, damage = finite(damage) and damage > 0 and damage or nil,
        stale = source == "attack_target" and call(Entity.IsDormant, unit) == true}
end

local function sampleRoshanAttacker(unit, now)
    if call(Entity.IsDormant, unit) == true then
        local id = call(Entity.GetIndex, unit)
        local previous = id and state.roshanAttackers[tostring(id)]
        if previous and previous.source == "attack_target" then previous.stale = true end
        if id then for _, attacker in pairs(state.tormentorAttackers) do
            if attacker.id == tostring(id) and attacker.source == "attack_target" then attacker.stale = true end
        end end
        return
    end
    if call(NPC.IsAttacking, unit) ~= true then return end
    -- These getters are optional in local scripts, not part of the documented
    -- API. Never infer the target from proximity or the attacking state alone.
    local target = call(Entity and Entity.GetAttackTarget, unit) or call(NPC and NPC.GetAttackTarget, unit)
    if state.flags.roshan and isRoshan(target) and call(Entity.IsAlive, target) ~= false then recordRoshanAttacker(unit, "attack_target", now) end
    if state.flags.tormentors and isTormentor(target) and call(Entity.IsAlive, target) ~= false then recordTormentorAttacker(unit, target, "attack_target", now) end
    return target
end

local function roshanSnapshot(now)
    if not state.flags.roshan then return nil end
    local native = call(Entity and Entity.GetRoshanHealth)
    local result
    for _, entry in ipairs(state.roshan_units) do
        local unit, row = entry.unit, entry.row
        local hp = call(Entity.GetHealth, unit)
        local hidden = call(Entity.IsDormant, unit) == true
        local source = "entity"
        if hidden and type(native) == "number" and native > 0 then hp, source = native, "native_roshan" end
        if type(hp) == "number" then
            row.hp, row.max_hp = hp, call(Entity.GetMaxHealth, unit) or row.max_hp
            row.hp_source, row.hp_stale = source, hidden and source ~= "native_roshan"
            if not row.hp_stale then row.hp_observed_at = now end
        end
        row.visible, row.alive = not hidden, call(Entity.IsAlive, unit)
        if source == "native_roshan" and hp > 0 then row.alive = true end
        if not result or row.alive ~= false then
            result = objectivePosition(unit, "roshan", now)
            result.id, result.hp, result.max_hp, result.alive = row.id, row.hp, row.max_hp, row.alive
            result.stale, result.source, result.observed_at = row.hp_stale, row.hp_source, row.hp_observed_at
        end
    end
    if not result and type(native) == "number" and native > 0 then
        result = {hp = native, alive = true, stale = false, source = "native_roshan", observed_at = now}
    end
    if result and not result.stale and type(result.hp) == "number" then
        if state.roshanLastHp and state.roshanLastTime and now >= state.roshanLastTime and now - state.roshanLastTime < 2 and result.hp < state.roshanLastHp then
            state.roshanDamageUntil = now + 2
        end
        state.roshanLastHp, state.roshanLastTime = result.hp, now
        result.under_attack = result.alive ~= false and now < (state.roshanDamageUntil or 0)
    end
    if result and result.alive == false or native == 0 then state.roshanAttackers = {} end
    local attackers, hasDamage, hasProjectile = {}, false, false
    for id, attacker in pairs(state.roshanAttackers) do
        if now < attacker.observed_at or now - attacker.observed_at >= 4 then state.roshanAttackers[id] = nil
        else
            attackers[#attackers + 1] = attacker
            if attacker.source == "damage_event" then hasDamage = true end
            if attacker.source == "attack_projectile" then hasProjectile = true end
        end
    end
    table.sort(attackers, function(a, b) return a.id < b.id end)
    local nativeTargets = type(Entity and Entity.GetAttackTarget) == "function" or type(NPC and NPC.GetAttackTarget) == "function"
    result = result or {}
    result.attackers, result.attackers_available = attackers, nativeTargets or hasDamage or hasProjectile
    result.attackers_source = hasDamage and "damage_event" or hasProjectile and "attack_projectile" or nativeTargets and "attack_target" or "unavailable"
    for _, attacker in ipairs(attackers) do
        if attacker.stale ~= true then result.under_attack = true; break end
    end
    return result
end

local function eventAllowed(event)
    if not state.flags.effects then return false end
    if event.kind == "scan" then return state.flags.scans end
    if event.kind == "teleport" then return state.flags.teleports end
    if event.item_name or event.ability_name and event.ability_name:find("item_", 1, true) == 1 then return state.flags.active_items end
    if event.ultimate == true then return state.flags.ultimates end
    if event.kind == "projectile" or event.vx or event.kind == "arrow" or event.kind == "hook" then return state.flags.projectiles end
    return state.flags.casts
end

local function recordFarming(unit, target, source, now)
    if not unit or not target or call(NPC.IsNeutral, target) ~= true then return end
    local name = call(NPC.GetUnitName, unit)
    if type(name) ~= "string" or name:find("npc_dota_hero_", 1, true) ~= 1 then return end
    local id = call(Entity.GetIndex, unit)
    if not id then return end
    state.farming[tostring(id)] = {kind = "farm", target_id = tostring(call(Entity.GetIndex, target)),
        observed_at = now, expires_at = now + 4, source = source}
end

local function collect()
    local now = gameClock()
    local packet = {type = "update", match = tostring(call(GameRules.GetMatchID) or "local"),
        game_time = call(GameRules.GetDOTATime, true, true) or now, game_clock = now,
        paused = call(GameRules.IsPaused) == true, in_game = call(Engine.IsInGame) == true,
        heroes = {}, events = {}, objectives = {}}
    if not packet.in_game then resetMatch(); return packet end
    if state.match and state.match ~= packet.match then resetMatch() end
    state.match = packet.match
    local localHero = call(Heroes.GetLocal)
    packet.local_team = localHero and call(Entity.GetTeamNum, localHero) or 2
    state.hasLocalHero = localHero ~= nil
    state.localTeam, state.detailsBudget = packet.local_team, 1
    if clock() >= state.nextPlayers then
        state.players = {}
        for _, player in ipairs(call(Players and Players.GetAll) or {}) do
            local id = call(Player.GetPlayerID, player)
            if id then state.players[id] = player end
        end
        state.nextPlayers = clock() + 2
    end
    if state.flags.heroes then
        local heroes = call(Heroes.GetAll) or {}
        state.detailCursor = #heroes > 0 and state.detailCursor % #heroes + 1 or 0
        for index, unit in ipairs(heroes) do
            if not call(NPC.IsIllusion, unit) and not call(NPC.IsMeepoClone, unit) then
                local row = base(unit, "hero", now)
                if row and #packet.heroes < 64 then
                    row["local"] = localHero and unit == localHero or false
                    heroDetails(unit, row, now, index == state.detailCursor)
                    sampleTeleport(unit, row, now)
                    if index == state.detailCursor then
                        local target = sampleRoshanAttacker(unit, now)
                        recordFarming(unit, target, "attack_target", now)
                    end
                    local activity = state.farming[row.id]
                    if activity and activity.expires_at > now then row.activity = activity
                    elseif activity then state.farming[row.id] = nil end
                    packet.heroes[#packet.heroes + 1] = row
                end
            end
        end
    end
    objectSnapshot(now, packet)
    if state.layersDirty or state.needFull then
        local filters = {illusion = "illusions", courier = "couriers", creep = "creeps", neutral = "neutrals", building = "buildings", roshan = "roshan", tormentor = "tormentors", wisdom = "wisdom"}
        packet.units = {}
        for _, row in ipairs(state.units) do if state.flags[filters[row.kind]] then packet.units[#packet.units + 1] = row end end
        packet.wards, packet.runes = state.flags.wards and state.wards or {}, state.flags.runes and state.runes or {}
        packet.camps = state.flags.camps and state.camps or {}
        state.layersDirty = false
    end
    local function cooldown(fn)
        local ready = call(fn)
        return type(ready) == "number" and math.max(0, ready - now) or nil
    end
    packet.objectives = {glyph_radiant = cooldown(GameRules.GetGoodGlyphCD), glyph_dire = cooldown(GameRules.GetBadGlyphCD),
        scan_radiant = cooldown(GameRules.GetGoodScanCD), scan_dire = cooldown(GameRules.GetBadScanCD)}
    if clock() >= state.nextRoshan then
        state.roshan = roshanSnapshot(now)
        state.nextRoshan = clock() + 0.1
    end
    packet.objectives.roshan = state.roshan
    packet.objectives.tormentors = tormentorSnapshot(now)
    local cycleRemaining = call(GameRules.GetNextCycleTime)
    if finite(cycleRemaining) and cycleRemaining >= 0 and cycleRemaining <= 1200 then
        packet.objectives.cycle = {next_at = now + cycleRemaining, source = "native_cycle"}
    end
    packet.objectives.wisdom = {}
    if state.flags.wisdom then for _, entry in pairs(state.wisdom) do
        local row = {}; for key, value in pairs(entry.row) do row[key] = value end
        packet.objectives.wisdom[#packet.objectives.wisdom + 1] = row
    end end
    for id, event in pairs(state.events) do
        local channel = event.kind == "teleport" and event.owner_id and state.teleports[event.owner_id]
        if channel and channel.ends_at > now then
            event.channel_end_at, event.remaining, event.timing = channel.ends_at, channel.ends_at - now, "native_modifier"
            event.duration = channel.started_at and math.max(0.01, channel.ends_at - channel.started_at) or nil
            event.ending, event.stale = channel.ends_at, channel.stale
        end
        if event.ending <= now then
            state.events[id], state.particles[id] = nil, nil
        elseif eventAllowed(event) and event.x then
            local row = {}
            for key, value in pairs(event) do if key ~= "ending" then row[key] = value end end
            if event.timing == "observed_lifetime" then
                row.elapsed = math.max(0, now - event.started)
            else row.remaining = event.ending - now end
            packet.events[#packet.events + 1] = row
        end
    end
    packet.performance = state.perf
    state.needFull = false
    return packet
end

-- Confirmed in the lobby capture. Keep endpoint names exact: other control
-- points can be colors, attachment offsets or shader parameters, not positions.
local observedParticles = {
    keeper_light_speed = {kind = "innate", point = 0, ttl = 3},
    antimage_blink_start = {kind = "blink", phase = "origin", point = 0, entityPoint = 1, ttl = 1.5},
    antimage_blink_end = {kind = "blink", phase = "destination", entityPoint = 1, ttl = 1.5},
    blink_dagger_start = {kind = "blink", phase = "origin", point = 0, ttl = 4, item = "item_blink"},
    blink_dagger_end = {kind = "blink", phase = "destination", point = 0, ttl = 4, item = "item_blink"},
    teleport_start = {kind = "teleport", phase = "origin", point = 0, entityPoint = 0, ttl = 30},
    teleport_origin = {kind = "teleport", phase = "origin", point = 0, ttl = 30},
    teleport_end = {kind = "teleport", phase = "destination", point = 0, originPoint = 3, ttl = 30},
}
local patterns = {
    {"smoke_of_deceit", "smoke", 3},
}

local function active()
    return state.active and state.flags.enabled and state.flags.effects
end

local function eventOwner(event, entity, id)
    local index = entity and call(Entity.GetIndex, entity) or id
    if index ~= nil then event.owner_id = tostring(index) end
    if entity then
        event.owner_name = call(NPC.GetUnitName, entity) or event.owner_name
        event.team = call(Entity.GetTeamNum, entity) or event.team
        event.owner_hidden = call(Entity.IsDormant, entity) == true
        event.owner_player_id = call(Hero and Hero.GetPlayerID, entity)
    elseif index ~= nil then
        local cached = state.heroes[tonumber(index) or index]
        local identity = cached and cached.identity
        if identity then
            event.owner_name, event.team, event.owner_player_id = identity.name, identity.team, identity.player_id
        end
    end
end

observeCast = function(unit, ability, source, now, native, effect, ownerIndex)
    if not active() or not unit or not ability and not effect and not native then return end
    if native and native.passive == true then return end
    if ability and not effect and not native and call(Ability.IsPassive, ability) == true then return end
    local name = native and native.name or ability and call(Ability.GetName, ability) or effect and effect.item_name
    local owner = ownerIndex or call(Entity.GetIndex, unit)
    if not name or not owner or excludedSpell(name) then return end
    now = now or gameClock()
    local key = tostring(owner) .. ":" .. name
    local seen = state.casts[key] or {}
    local castTime = ability and call(Ability.GetCastStartTime, ability) or nil
    local cooldown = native and native.cooldown or ability and call(Ability.GetCooldown, ability)
    local fresh = source == "ability_animation" or source == "modifier_event" or source == "ability_projectile" or source == "ability_sound"
    if effect and source == "modifier_sample" then
        fresh = finite(effect.used_at) and now >= effect.used_at and now - effect.used_at < 2 and seen.effectUsedAt ~= effect.used_at
        seen.effectUsedAt = effect.used_at
    end
    -- Instant items may never expose a cast animation or cast-start timestamp.
    -- The API's last-use timestamp also confirms a first observation, while a
    -- cooldown increase alone could be Blink's damage lockout.
    local usedAt = native and native.used_at or effect and effect.used_at
    if source == "ability_sample" and finite(usedAt) then
        fresh = now >= usedAt and now - usedAt < 2 and (not finite(seen.usedAt) or usedAt > seen.usedAt + 0.2)
    end
    if not fresh and finite(castTime) and castTime > 0 then
        fresh = castTime ~= seen.castTime and now >= castTime and now - castTime < 2
    end
    if not fresh and source == "ability_sample" and not Ability.SecondsSinceLastUse
        and not name:find("blink", 1, true) and finite(cooldown) and finite(seen.cooldown) then
        fresh = cooldown > seen.cooldown + 0.75
    end
    seen.castTime, seen.cooldown = castTime, cooldown
    if finite(usedAt) then seen.usedAt = math.max(seen.usedAt or -math.huge, usedAt) end
    state.casts[key] = seen
    if not fresh or (seen.wall and clock() - seen.wall < 0.25) then return end
    seen.wall = clock()
    local hidden = call(Entity.IsDormant, unit) == true
    local cached = state.heroes[owner]
    local nativePosition = hidden and pos(call(Hero and Hero.GetLastMaphackPos, unit)) or nil
    local p = not hidden and pos(call(Entity.GetAbsOrigin, unit)) or nativePosition
    p = p or cached
    if not p or type(p.x) ~= "number" or type(p.y) ~= "number" then return end
    local count = 0
    for _ in pairs(state.events) do count = count + 1 end
    if count >= 96 then return end
    state.castSerial = state.castSerial + 1
    local id = "cast:" .. tostring(state.castSerial)
    local isBlink = name == "item_blink" or name == "item_overwhelming_blink" or name == "item_swift_blink" or name == "item_arcane_blink"
    local event = {id = id, kind = isBlink and "blink" or "cast", name = name, ability_name = name,
        x = p.x, y = p.y, started = now, ending = now + 4,
        timing = "observed_lifetime", source = source, location = "caster",
        position_source = hidden and (nativePosition and "maphack_last" or cached and cached.source or "last_seen") or "visible",
        observed_at = now, stale = hidden, cooldown = finite(cooldown) and cooldown >= 0 and cooldown or nil,
        ultimate = native and native.ultimate == true or ability and call(Ability.IsUltimate, ability) == true or false,
        item_name = name:find("item_", 1, true) == 1 and name or nil,
        active_until = effect and effect.active_until, active_source = effect and "modifier" or nil,
        used_at = usedAt or finite(castTime) and castTime > 0 and castTime <= now and castTime or nil}
    eventOwner(event, unit)
    state.events[id] = event
    invalidateDetails(owner)
end

local function particleAbility(entity, name)
    if name:find("arc_warden_spark_wraith", 1, true) == 1 then return "arc_warden_spark_wraith" end
    local id = entity and call(Entity.GetIndex, entity)
    local details = id and state.details[tostring(id)]
    if not details then return nil end
    local normalized = name:gsub("_spell_", "_")
    local best, bestLength
    local entries = {}
    for _, ability in ipairs(details.abilities or {}) do entries[#entries + 1] = ability end
    for _, item in ipairs(details.items or {}) do entries[#entries + 1] = item end
    for _, ability in ipairs(entries) do
        local candidate = ability.name
        if candidate and candidate:find("item_", 1, true) == 1 then candidate = candidate:sub(6) end
        if type(candidate) == "string" and #candidate >= 6 and not excludedSpell(candidate)
            and (normalized == candidate or normalized:find(candidate .. "_", 1, true) == 1
                or normalized:gsub("_", ""):find(candidate:gsub("_", ""), 1, true) == 1)
            and (not bestLength or #candidate > bestLength) then best, bestLength = ability.name, #candidate end
    end
    return best
end

observeItemEffect = function(unit, modifier, source, now)
    if not unit or not modifier then return end
    local modifierName = call(Modifier.GetName, modifier)
    local itemName = itemModifiers[modifierName]
    if not itemName then return end
    local owner, ending = call(Entity.GetIndex, unit), call(Modifier.GetDieTime, modifier)
    if not owner then return end
    if not finite(ending) or ending <= now then
        -- An activation callback remains evidence of use even when the runtime
        -- omits its expiry. Do not invent the active duration or item cooldown.
        if source == "modifier_event" then
            observeCast(unit, call(Modifier.GetAbility, modifier), source, now, {name = itemName})
        end
        return
    end
    local key = tostring(owner) .. ":" .. itemName
    local previous = state.activeEffects[key]
    local created = call(Modifier.GetCreationTime, modifier)
    local hidden = call(Entity.IsDormant, unit) == true
    local used = finite(created) and created > 0 and created <= now and created or nil
    local record = {item_name = itemName, active_until = ending,
        observed_at = previous and previous.active_until == ending and previous.observed_at or now,
        used_at = used or (source == "modifier_event" and now or previous and previous.used_at),
        usage_source = used and "modifier_creation" or source == "modifier_event" and "modifier_event" or previous and previous.usage_source,
        stale = hidden}
    state.activeEffects[key] = record
    -- Cached hidden modifiers do not become new activations on every sample.
    local newEffect = not previous or previous.active_until ~= ending
    if newEffect and (source == "modifier_event" or used and now - used < 2) then
        local ability = call(Modifier.GetAbility, modifier)
        observeCast(unit, ability, source, now, {name = itemName,
            cooldown = ability and call(Ability.GetCooldown, ability)}, record)
    end
end

local function groupEvent(event)
    if not event.phase or not event.owner_id then return end
    for _, other in pairs(state.events) do
        if other ~= event and other.owner_id == event.owner_id and other.kind == event.kind
            and other.name ~= event.name and other.ending > gameClock()
            and math.abs(other.started - event.started) <= 0.25 then
            event.group_id = other.group_id or other.id
            event.origin_x, event.origin_y = other.origin_x, other.origin_y
            event.destination_x, event.destination_y = other.destination_x, other.destination_y
            return
        end
    end
end

local function setEndpoint(event, phase, p)
    local xKey, yKey = phase .. "_x", phase .. "_y"
    event[xKey], event[yKey] = p.x, p.y
    if event.phase == phase then event.x, event.y = p.x, p.y end
    -- Share endpoints between a cast's origin/destination particles. A TP's
    -- owner-origin CP3 must never overwrite the destination marker's CP0.
    for _, other in pairs(state.events) do
        if other ~= event and event.group_id and other.group_id == event.group_id then
            other[xKey], other[yKey] = p.x, p.y
        end
    end
end

local function addEvent(data, projectile)
    if not state.active or not state.flags.enabled or type(data) ~= "table" then return end
    if projectile and not state.flags.projectiles then return end
    local name = tostring(data.name or data.fullName or ""):lower():gsub("\\", "/")
    local fullName = tostring(data.fullName or data.name or ""):lower():gsub("\\", "/")
    name = (name:match("([^/]+)$") or name):gsub("%.vpcf_c$", ""):gsub("%.vpcf$", "")
    local orbName = name:match("^invoker_(quas)_orb$") or name:match("^invoker_(wex)_orb$") or name:match("^invoker_(exort)_orb$")
    if orbName and not projectile then
        local owner = data.entity or data.entityForModifiers
        local ownerId = owner and call(Entity.GetIndex, owner)
        if state.flags.abilities and ownerId and call(NPC.GetUnitName, owner) == "npc_dota_hero_invoker" and data.index then
            local count = 0; for _ in pairs(state.orbParticles) do count = count + 1 end
            if count < 64 then
                state.orbParticles[tostring(data.index)] = {owner_id = tostring(ownerId), name = orbName, observed_at = gameClock()}
                invalidateDetails(ownerId)
            end
        end
        return
    end
    if not active() then return end
    if name:find("invoker_quas_", 1, true) == 1 or name:find("invoker_wex_", 1, true) == 1
        or name:find("invoker_exort_", 1, true) == 1 then return end -- cosmetic children of the three native orbs
    if excludedSpell(name) then return end
    if name:find("keeper_light_speed_", 1, true) == 1 then return end -- child visuals duplicate the innate trail
    if name:find("scan_preview", 1, true) or name:find("ambient", 1, true) or name:find("footstep", 1, true) then return end
    local observed = not projectile and observedParticles[name] or nil
    if name == "keeper_light_speed" and fullName:find("/", 1, true)
        and fullName ~= "particles/units/heroes/hero_keeper_of_the_light/keeper_light_speed.vpcf" then return end
    local kind, duration = "effect", 1.5
    local scan = name == "scan" and (not fullName:find("/", 1, true)
        or fullName:find("generic_gameplay/scan", 1, true) ~= nil)
    if observed then kind, duration = observed.kind, observed.ttl
    else
        for _, pattern in ipairs(patterns) do
            if name:find(pattern[1], 1, true) then kind, duration = pattern[2], pattern[3]; break end
        end
    end
    if scan then kind, duration = "scan", 12 end
    local entity = data.source or data.entity or data.entityForModifiers
    local owner = entity and (call(NPC.GetOwnerNPC, entity) or call(Entity.GetOwner, entity))
    if owner and (call(NPC.GetUnitName, owner) or ""):find("npc_dota_hero_", 1, true) == 1 then entity = owner end
    -- Hero-owned ability particles are supported generically, while persistent
    -- ambient/cosmetic/attack particles must not flood the event stream.
    local generic = false
    if kind == "effect" and not projectile then
        local ignored = false
        for _, token in ipairs({"ambient", "aura", "overhead", "attack", "wearable", "status", "idle", "blood", "illusion", "trail", "body", "footstep"}) do
            if name:find(token, 1, true) then ignored = true; break end
        end
        if ignored then return end
        local ownerName = entity and call(NPC.GetUnitName, entity) or ""
        generic = not ignored and (fullName:find("/heroes/hero_", 1, true) ~= nil or ownerName:find("npc_dota_hero_", 1, true) == 1)
        if not generic then
            if get(ui.debug, false) and not state.loggedParticles[name] and ai_bridge and ai_bridge.mcp_log then
                state.loggedParticles[name] = true
                call(ai_bridge.mcp_log, "debug", "[Cloud Radar] unknown particle", {name = name, full_name = fullName})
            end
            return
        end
        local ownerKey = tostring(entity and call(Entity.GetIndex, entity) or data.entity_id or "unknown")
        local rate = state.genericRates[ownerKey] or {time = clock(), count = 0}
        if clock() - rate.time >= 1 then rate.time, rate.count = clock(), 0 end
        if rate.count >= 6 then return end
        rate.count = rate.count + 1; state.genericRates[ownerKey] = rate
        duration = 15
    end
    if projectile and kind == "effect" then kind = "projectile" end
    local id = tostring(projectile and (data.handle or data.particleIndex) or data.index)
    if id == "nil" then return end
    id = (projectile and "projectile:" or "particle:") .. id
    local count = 0
    for _ in pairs(state.events) do count = count + 1 end
    if count >= 96 and not state.events[id] then return end
    local p = projectile and pos(data.origin or data.position) or nil
    -- Particle creation coordinates can be the caster rather than the target.
    -- Wait for control point 0 for particle world position.
    local now = gameClock()
    local velocity = pos(data.velocity)
    local speed = velocity and math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
    if projectile and speed and speed > 0 and type(data.distance) == "number" then
        duration = math.min(10, data.distance / speed)
    end
    local event = {id = id, kind = kind, name = name, x = p and p.x, y = p and p.y,
        duration = not observed and not generic and not scan and duration or nil, ending = now + duration, started = now,
        vx = velocity and velocity.x, vy = velocity and velocity.y,
        source = projectile and "projectile" or "particle", timing = (observed or generic or scan) and "observed_lifetime" or "estimated",
        location = (generic or scan) and "effect" or nil,
        phase = observed and observed.phase, group_id = observed and id}
    eventOwner(event, entity, data.entity_id or data.entity_for_modifiers_id)
    if generic then
        event.ability_name = particleAbility(entity, name)
        local details = event.owner_id and state.details[event.owner_id]
        if details and event.ability_name then
            for _, entry in ipairs(details.abilities or {}) do
                if entry.name == event.ability_name then
                    event.cooldown, event.cooldown_observed_at = entry.cooldown, entry.observed_at
                    event.ultimate = entry.ultimate
                    break
                end
            end
        end
    end
    if observed and observed.item then event.ability_name, event.item_name = observed.item, observed.item end
    if name == "keeper_light_speed" then event.ability_name = "keeper_of_the_light_bright_speed" end
    groupEvent(event)
    state.events[id] = event
    if not projectile then state.particles[id] = true end
end

local function updateParticle(data, attached)
    if not active() or type(data) ~= "table" then return end
    local event = state.events["particle:" .. tostring(data.index)]
    local p = pos(data.position)
    if not event or not p then return end
    local observed = observedParticles[event.name]
    if event.kind == "scan" and data.controlPoint == 9 and p.x >= 0 and p.x <= 1 then
        -- Verified in the installed scan.vpcf: CP9.x mixes green -> red.
        event.scan_response = p.x >= 0.5 and "red" or "green"
        event.scan_response_source = "particle_cp9"
        return
    end
    if not observed then
        if data.controlPoint == 0 and math.abs(p.x) <= 20000 and math.abs(p.y) <= 20000 then
            event.x, event.y = p.x, p.y
            event.position_source = "particle_cp0"
        end
        return
    end
    local point
    if attached then point = observed.entityPoint else point = observed.point end
    if event.name == "keeper_light_speed" and data.controlPoint == 0 then
        if math.abs(p.x) > 20000 or math.abs(p.y) > 20000 then return end
        local attachedId = attached and (data.entity and call(Entity.GetIndex, data.entity) or data.entIdx)
        if attachedId and (not event.owner_id or tostring(attachedId) == event.owner_id) then eventOwner(event, data.entity, attachedId)
        else eventOwner(event, nil, event.owner_id) end
        event.x, event.y, event.position_source, event.observed_at = p.x, p.y, "particle_cp0", gameClock()
        if event.owner_id and event.owner_name == "npc_dota_hero_keeper_of_the_light" then
            state.innatePositions[event.owner_id] = {x = p.x, y = p.y, observed_at = event.observed_at}
        end
        return
    end
    local phase = point ~= nil and data.controlPoint == point and event.phase or nil
    if attached and observed.originPoint ~= nil and data.controlPoint == observed.originPoint then phase = "origin" end
    if not phase then return end
    if attached then
        local owner = data.entity and call(Entity.GetIndex, data.entity) or data.entIdx
        if not event.owner_id or (owner ~= nil and tostring(owner) == event.owner_id) then
            local hadOwner = event.owner_id ~= nil
            eventOwner(event, data.entity, data.entIdx)
            if not hadOwner then groupEvent(event) end
        end
    end
    setEndpoint(event, phase, p)
end

function script.OnParticleCreate(data)
    addEvent(data, false)
end
function script.OnLinearProjectileCreate(data)
    addEvent(data, true)
end

function script.OnParticleUpdate(data)
    updateParticle(data, false)
end
script.OnParticleUpdateFallback = script.OnParticleUpdate

function script.OnParticleUpdateEntity(data)
    updateParticle(data, true)
end

function script.OnUnitAnimation(data)
    if type(data) ~= "table" then return end
    local ability = data.unit and call(NPC and NPC.GetAbilityByActivity, data.unit, data.activity)
    if ability then
        observeCast(data.unit, ability, "ability_animation", gameClock())

    end
end

function script.OnProjectile(data)
    if not state.active or not state.flags.enabled or type(data) ~= "table" then return end
    if data.isAttack == true then
        recordFarming(data.source, data.target, "attack_projectile", gameClock())
        if state.flags.roshan and isRoshan(data.target) and call(Entity.IsAlive, data.target) ~= false then
            recordRoshanAttacker(data.source, "attack_projectile", gameClock())
        end
        if state.flags.tormentors and isTormentor(data.target) and call(Entity.IsAlive, data.target) ~= false then
            recordTormentorAttacker(data.source, data.target, "attack_projectile", gameClock())
        end
    elseif active() and data.ability and data.source then
        observeCast(data.source, data.ability, "ability_projectile", gameClock())
    end
end

function script.OnStartSound(data)
    if not active() or type(data) ~= "table" or type(data.name) ~= "string" or not data.source then return end
    local id = call(Entity.GetIndex, data.source)
    local details = id and state.details[tostring(id)]
    if not details then return end
    -- Match only a known native ability and its exact cast/activation sound.
    -- Impact, looping and cosmetic sound suffixes never become new casts.
    local name = data.name:lower():gsub("^hero_", ""):gsub("[^a-z0-9]", "")
    for _, ability in ipairs(details.abilities or {}) do
        local key = type(ability.name) == "string" and ability.name:gsub("_", "")
        if key and (name == key or name == key .. "cast" or name == key .. "activate") then
            observeCast(data.source, nil, "ability_sound", gameClock(), ability)
            return
        end
    end
end

function script.OnModifierCreate(entity, modifier)
    local id = entity and call(Entity.GetIndex, entity)
    if state.active and id and orbModifiers[call(Modifier.GetName, modifier)] then invalidateDetails(id) end
    if state.active then observeItemEffect(entity, modifier, "modifier_event", gameClock()) end
    if state.active then observeTeleport(entity, modifier, gameClock()) end
    if active() then
        local ability = call(Modifier.GetAbility, modifier)
        local owner = ability and call(Ability.GetOwner, ability)
        if owner and not itemModifiers[call(Modifier.GetName, modifier)] then
            observeCast(owner, ability, "modifier_event", gameClock())
        end
    end
end

function script.OnModifierUpdate(entity, modifier)
    if state.active then observeItemEffect(entity, modifier, "modifier_sample", gameClock()) end
    if state.active then observeTeleport(entity, modifier, gameClock()) end
end

function script.OnModifierDestroy(entity, modifier)
    if not state.active then return end
    local itemName = itemModifiers[call(Modifier.GetName, modifier)]
    local owner = entity and call(Entity.GetIndex, entity)
    if owner and orbModifiers[call(Modifier.GetName, modifier)] then invalidateDetails(owner) end
    if owner and call(Modifier.GetName, modifier) == "modifier_teleporting" then
        state.teleports[tostring(owner)] = nil
        for id, event in pairs(state.events) do
            if event.kind == "teleport" and event.owner_id == tostring(owner) and event.channel_end_at then state.events[id], state.particles[id] = nil, nil end
        end
    end
    if itemName and owner then
        state.activeEffects[tostring(owner) .. ":" .. itemName] = nil
        state.details[tostring(owner)] = nil
    end
end

function script.OnChatEvent(data)
    local buybackType = Enum and Enum.DotaChatMessage and Enum.DotaChatMessage.CHAT_MESSAGE_BUYBACK
    if not state.active or not state.flags.buybacks or type(data) ~= "table" or buybackType == nil or data.type ~= buybackType then return end
    local playerId = data.playerid_1
    -- Chat payload semantics are not documented per event; accept the explicit
    -- player-ID field only when it resolves to a known player, never value/value2.
    if not finite(playerId) or playerId < 0 or playerId % 1 ~= 0 or not state.players[playerId] then return end
    state.buybacks[playerId] = {last_at = gameClock(), source = "chat_event"}
    for id, hero in pairs(state.heroes) do
        if hero.identity and hero.identity.player_id == playerId then state.details[tostring(id)] = nil end
    end
end

function script.OnEntityHurt(data)
    -- Umbrella dispatches this only when its existing unsafe mode permits it.
    -- The radar never enables that mode; no event means no damage evidence.
    if not state.active or type(data) ~= "table" or not finite(data.damage) or data.damage <= 0 then return end
    recordFarming(data.source, data.target, "damage_event", gameClock())
    if state.flags.roshan and isRoshan(data.target) then
        recordRoshanAttacker(data.source, "damage_event", gameClock(), data.damage)
        state.nextRoshan = 0
    end
    if state.flags.tormentors and isTormentor(data.target) then recordTormentorAttacker(data.source, data.target, "damage_event", gameClock(), data.damage) end
end

function script.OnEntityKilled(data)
    if state.active and type(data) == "table" and isRoshan(data.target) then
        state.roshanAttackers, state.roshanDamageUntil, state.nextRoshan = {}, 0, 0
    end
    if state.active and type(data) == "table" and data.target and (call(NPC.IsTower, data.target) == true
        or call(NPC.IsBarracks, data.target) == true) and #state.kills < 32 then
        local p = pos(call(Entity.GetAbsOrigin, data.target))
        state.kills[#state.kills + 1] = {name = call(NPC.GetUnitName, data.target), team = call(Entity.GetTeamNum, data.target),
            barracks = call(NPC.IsBarracks, data.target) == true, x = p and p.x, y = p and p.y}
    end
    if type(data) == "table" and data.target and (call(NPC.IsWard, data.target) == true
        or call(NPC.IsNeutral, data.target) == true or call(NPC.IsTower, data.target) == true) then script.OnEntityDestroy(data.target, true) end
    if type(data) == "table" and isTormentor(data.target) then
        local targetId = tostring(call(Entity.GetIndex, data.target))
        for key, attacker in pairs(state.tormentorAttackers) do if attacker.target_id == targetId then state.tormentorAttackers[key] = nil end end
    end
end

function script.OnParticleDestroy(data)
    if type(data) == "table" then
        local orb = state.orbParticles[tostring(data.index)]
        if orb then invalidateDetails(orb.owner_id); state.orbParticles[tostring(data.index)] = nil end
        local id = "particle:" .. tostring(data.index)
        local event = state.events[id]
        -- A short-lived Blink particle still leaves its observed action badge.
        if event and event.kind == "blink" and event.item_name and event.owner_id and event.x and event.ending > gameClock() then
            event.location, event.phase, event.group_id = "caster", nil, nil
        else state.events[id] = nil end
        state.particles[id] = nil
    end
end
function script.OnLinearProjectileDestroy(data)
    if type(data) == "table" then state.events["projectile:" .. tostring(data.handle)] = nil end
end

function script.OnGameEnd()
    resetMatch()
    state.match, state.nextSend = nil, 0
end

function script.OnUnitInventoryUpdated(entity)
    local id = call(Entity.GetIndex, entity)
    if id then invalidateDetails(id); state.inventoryDirty[tostring(id)] = true end
end

function script.OnEntityDestroy(entity, confirmedDeath)
    local id = call(Entity.GetIndex, entity)
    if id then
        local key = tostring(id)
        local cached = state.heroes[id]
        -- A late removal for an old handle must not erase a new NPC which has
        -- already reused that index.
        if cached and cached.entity and cached.entity ~= entity then return end
        local remembered = state.wardMemory[key] or state.unitMemory[key] and state.unitMemory[key].row
        local obscured = call(Entity.IsDormant, entity) == true or remembered and remembered.visible == false
        local keep = remembered and obscured and not confirmedDeath
        local keepHero = not confirmedDeath and obscured and cached and cached.identity
            and (cached.identity.name or ""):find("npc_dota_hero_", 1, true) == 1
        if keep then
            remembered.visible, remembered.data_stale, remembered.source = false, true, "last_observation"
        else state.unitMemory[key], state.wardMemory[key] = nil, nil end
        local rune = state.runeMemory[key]
        if rune then
            local observed = rune.row.visible ~= false
            rune.unit = nil; rune.row.visible, rune.row.data_stale = false, true
            if not obscured and observed then rune.row.taken_at, rune.row.source = gameClock(), "observed_disappearance" end
        end
        state.laneMovers[key], state.courierMotion[key], state.courierSamples[id] = nil, nil, nil
        local shrine = state.wisdom[key]
        if shrine then shrine.unit = nil; shrine.row.visible, shrine.row.data_stale = false, true end
        state.classifications[id] = nil
        state.heroes[id] = nil
        if not keepHero then state.details[key] = nil end
        state.innatePositions[tostring(id)] = nil
        state.teleports[tostring(id)], state.objectiveMotion[tostring(id)] = nil, nil
        state.farming[tostring(id)] = nil
        for index, orb in pairs(state.orbParticles) do if orb.owner_id == tostring(id) then state.orbParticles[index] = nil end end
        for _, name in ipairs({"tormentor_units", "roshan_units"}) do
            for index = #state[name], 1, -1 do if state[name][index].unit == entity then table.remove(state[name], index) end end
        end
        state.destroyed[id], state.movers[tostring(id)] = entity, nil
        for _, layer in ipairs({"units", "wards", "runes"}) do
            for index = #state[layer], 1, -1 do
                if state[layer][index].id == tostring(id) and not keep then table.remove(state[layer], index) end
            end
        end
        if state.scanJob then for _, layer in ipairs({"units", "wards"}) do
            for index = #state.scanJob[layer], 1, -1 do if state.scanJob[layer][index].id == tostring(id) then table.remove(state.scanJob[layer], index) end end
        end end
        state.layersDirty = true
    end
    state.nextSlow = math.min(state.nextSlow, clock() + 0.25)
end

function script.OnNpcSpawned(entity)
    local id = call(Entity.GetIndex, entity)
    if id then
        local cached = state.heroes[id]
        local memory = state.unitMemory[tostring(id)]
        local retired = cached and cached.entity or state.destroyed[id] or memory and memory.unit
        forgetEntity(id)
        if retired and retired ~= entity then state.destroyed[id] = retired end
    end
    if call(NPC.IsWard, entity) then state.nextSlow = math.min(state.nextSlow, clock() + 0.1) end
end

local relay = {}
do
    local PARTS = {"clock", "pos", "info", "units", "wards", "runes", "camps", "events", "objectives"}
    local RUNE_MODS = {modifier_rune_doubledamage = 0, modifier_rune_haste = 1, modifier_rune_invis = 3,
        modifier_rune_regen = 4, modifier_rune_arcane = 6}

    local function round(value)
        return finite(value) and math.floor(value + 0.5) or nil
    end

    local function byId(a, b)
        return tostring(a.id) < tostring(b.id)
    end

    local function strip(list)
        for _, row in ipairs(list or {}) do row.id = nil end
        return list
    end

    local function boss(row)
        local item = {id = row.id, alive = row.alive, under_attack = row.under_attack == true or nil}
        if finite(row.hp) and finite(row.max_hp) and row.max_hp > 0 then item.hp = round(row.hp / row.max_hp * 100) end
        if row.visible == true and finite(row.x) and finite(row.y) then item.x, item.y = round(row.x), round(row.y) end
        local names, seen = {}, {}
        for _, attacker in ipairs(row.attackers or {}) do
            local name = attacker.hero_name
            if attacker.stale ~= true and name and not seen[name] and #names < 3 then
                seen[name] = true
                names[#names + 1] = name
            end
        end
        item.attackers = names
        return item
    end

    function relay.merge(packet)
        local r = state.relay
        if not packet.in_game then
            r.units, r.wards, r.runes = {}, {}, {}
            return
        end
        if type(packet.units) == "table" then
            r.units = {}
            for _, row in ipairs(packet.units) do r.units[row.id] = row end
        end
        for _, patch in ipairs(packet.units_patch or {}) do
            if patch._delete then r.units[patch.id] = nil
            elseif patch._merge then
                local row = r.units[patch.id]
                if row then for key, value in pairs(patch) do if key ~= "_merge" then row[key] = value end end end
            else r.units[patch.id] = patch end
        end
        if type(packet.wards) == "table" then r.wards = packet.wards end
        if type(packet.runes) == "table" then r.runes = packet.runes end
    end

    local function buildPath(points)
        local path, total = {}, 0
        for index, p in ipairs(points) do
            if index > 1 then total = total + math.sqrt((p.x - points[index - 1].x) ^ 2 + (p.y - points[index - 1].y) ^ 2) end
            path[index] = {x = p.x, y = p.y, s = total}
        end
        return path
    end

    local function lanePaths()
        local m = state.mem
        m.paths = m.paths or {}
        local t = {}
        for _, tower in pairs(m.towers or {}) do t[tower.team .. tower.lane .. tower.tier] = tower end
        for _, lane in ipairs({"top", "mid", "bot"}) do
            local g1, g2, g3 = t["2" .. lane .. "1"], t["2" .. lane .. "2"], t["2" .. lane .. "3"]
            local b1, b2, b3 = t["3" .. lane .. "1"], t["3" .. lane .. "2"], t["3" .. lane .. "3"]
            if not m.paths[lane] and g1 and g2 and g3 and b1 and b2 and b3 then
                local points = {g3, g2, g1}
                if lane == "top" then points[#points + 1] = {x = g1.x, y = b1.y}
                elseif lane == "bot" then points[#points + 1] = {x = b1.x, y = g1.y} end
                for _, p in ipairs({b1, b2, b3}) do points[#points + 1] = p end
                m.paths[lane] = buildPath(points)
            end
        end
        return m.paths
    end

    local function project(path, x, y)
        local bestS, bestD
        for index = 2, #path do
            local a, b = path[index - 1], path[index]
            local dx, dy = b.x - a.x, b.y - a.y
            local len2 = dx * dx + dy * dy
            local k = len2 > 0 and math.max(0, math.min(1, ((x - a.x) * dx + (y - a.y) * dy) / len2)) or 0
            local d = (x - a.x - dx * k) ^ 2 + (y - a.y - dy * k) ^ 2
            if not bestD or d < bestD then bestD, bestS = d, a.s + (b.s - a.s) * k end
        end
        return bestS, bestD and math.sqrt(bestD)
    end

    local function along(path, s)
        s = math.max(0, math.min(path[#path].s, s))
        for index = 2, #path do
            local a, b = path[index - 1], path[index]
            if s <= b.s then
                local k = b.s > a.s and (s - a.s) / (b.s - a.s) or 0
                return a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k
            end
        end
        return path[#path].x, path[#path].y
    end

    local function laneOf(paths, x, y)
        local best, bestS, bestD
        for lane, path in pairs(paths) do
            local s, d = project(path, x, y)
            if s and d < 1500 and (not bestD or d < bestD) then best, bestS, bestD = lane, s, d end
        end
        return best, bestS
    end

    -- Creeps in fog: the last seen creep keeps walking its lane at its own
    -- move speed. It stops at the first enemy tower or where it meets the
    -- opposing wave, and is dropped once its predicted spot is visible.
    local function predictCreeps(hidden, visible, alive, now)
        local paths = lanePaths()
        local fronts, out = {}, {}
        local function front(lane, team, s, seen)
            local f = fronts[lane] or {}
            fronts[lane] = f
            local key = team == 2 and "r" or "d"
            local cur = f[key]
            if not cur or (team == 2 and s > cur.s) or (team ~= 2 and s < cur.s) then f[key] = {s = s, seen = seen} end
        end
        for _, u in ipairs(visible) do
            local lane, s = laneOf(paths, u.x, u.y)
            if lane then front(lane, u.team, s, true) end
        end
        local towerLimit = {}
        for _, tower in pairs(alive) do
            local path = paths[tower.lane]
            if path then
                local s = project(path, tower.x, tower.y)
                local limit = towerLimit[tower.lane] or {}
                towerLimit[tower.lane] = limit
                if tower.team == 3 then limit.r = math.min(limit.r or math.huge, s - 400)
                else limit.d = math.max(limit.d or -math.huge, s + 400) end
            end
        end
        local moving = {}
        for _, c in ipairs(hidden) do
            local entry = state.laneMovers[c.u.id]
            local lost = entry and entry.seenAt
            local elapsed = lost and now - lost
            if entry and not entry.gone and elapsed and elapsed >= 0 and elapsed <= 45 then
                local speed = finite(entry.ms) and entry.ms > 0 and entry.ms
                    or finite(entry.vx) and finite(entry.vy) and math.sqrt(entry.vx ^ 2 + entry.vy ^ 2) or 0
                local lane, s = laneOf(paths, c.u.x, c.u.y)
                if lane then
                    local dir = c.u.team == 2 and 1 or -1
                    c.lane, c.entry = lane, entry
                    c.s = s + dir * speed * elapsed
                    local limit = towerLimit[lane]
                    if limit and dir == 1 and limit.r then c.s = math.min(c.s, math.max(s, limit.r)) end
                    if limit and dir == -1 and limit.d then c.s = math.max(c.s, math.min(s, limit.d)) end
                    front(lane, c.u.team, c.s, false)
                    moving[#moving + 1] = c
                elseif finite(entry.vx) and finite(entry.vy) then
                    local t = math.min(elapsed, 6)
                    c.x, c.y, c.entry = c.u.x + entry.vx * t, c.u.y + entry.vy * t, entry
                    moving[#moving + 1] = c
                end
            end
        end
        for _, c in ipairs(moving) do
            local x, y = c.x, c.y
            if c.lane then
                local f = fronts[c.lane]
                if f and f.r and f.d and f.r.s > f.d.s then
                    local meet = f.d.seen and not f.r.seen and f.d.s or f.r.seen and not f.d.seen and f.r.s or (f.r.s + f.d.s) / 2
                    if c.u.team == 2 then c.s = math.min(c.s, meet - 100) else c.s = math.max(c.s, meet + 100) end
                end
                x, y = along(paths[c.lane], c.s)
            end
            local point = call(Vector, x, y, 0)
            if point and call(FogOfWar.IsPointVisible, point) == true then
                c.entry.gone = true
            else
                c.row.x, c.row.y, c.row.f = round(x), round(y), 2
                out[#out + 1] = c.row
            end
        end
        return out
    end

    function relay.view(packet)
        local gt = packet.game_time or 0
        local now = packet.game_clock or gt
        local offset = gt - now
        local v = {clock = {t = round(gt) or 0, in_game = packet.in_game == true, team = packet.local_team, paused = packet.paused == true}}
        if not packet.in_game then return v end
        local m = state.mem
        m.towers = m.towers or {}
        local function at(t)
            return finite(t) and round(t + offset) or nil
        end
        local function readyAt(observed, remaining)
            return finite(remaining) and remaining > 0.5 and round(observed + remaining + offset) or nil
        end
        v.pos, v.info = {}, {}
        for _, h in ipairs(packet.heroes or {}) do
            if finite(h.x) and finite(h.y) then
                local fog = h.visible == true and 0 or (h.source == "maphack_last" or h.source == "innate_trace") and 1 or 2
                v.pos[#v.pos + 1] = {id = h.id, name = h.name, team = h.team, x = round(h.x), y = round(h.y), f = fog,
                    seen = fog > 0 and at(h.position_observed_at) or nil,
                    hp = round(h.hp), max_hp = round(h.max_hp), mana = round(h.mana), max_mana = round(h.max_mana),
                    alive = h.alive, level = h.level, me = h["local"] == true or nil,
                    tp = type(h.teleport) == "table" and at(h.teleport.ends_at) or nil,
                    respawn_at = h.alive == false and finite(h.respawn) and h.respawn > 0 and round(gt + h.respawn) or nil}
                local d = state.details[h.id]
                if d and finite(d.game) then
                    local info = {items = {}, abilities = {}}
                    for _, item in ipairs(d.items or {}) do
                        if finite(item.slot) and item.name and (item.slot < 9 or item.slot == 15 or item.slot == 16) then
                            info.items[#info.items + 1] = {slot = item.slot, name = item.name, ready_at = readyAt(d.game, item.cooldown),
                                charges = finite(item.charges) and item.charges > 0 and item.charges or nil,
                                o = item.stale == true and 1 or nil}
                        end
                    end
                    table.sort(info.items, function(a, b) return a.slot < b.slot end)
                    for _, ability in ipairs(d.abilities or {}) do
                        local name = ability.name
                        if type(name) == "string" and ability.hidden ~= true and not name:find("special_bonus", 1, true) and name ~= "generic_hidden" and #info.abilities < 8 then
                            info.abilities[#info.abilities + 1] = {name = name, level = ability.level or 0,
                                ready_at = readyAt(d.game, ability.cooldown), ult = ability.ultimate == true or nil,
                                charges = finite(ability.charges) and ability.charges > 0 and ability.charges or nil}
                        end
                        if ability.ultimate == true and finite(ability.level) and ability.level > 0 and not info.ult then
                            info.ult = {name = name, level = ability.level, ready_at = readyAt(d.game, ability.cooldown)}
                        end
                    end
                    if type(d.stats) == "table" then
                        info.stats = {k = d.stats.kills, d = d.stats.deaths, a = d.stats.assists,
                            nw = round(d.stats.networth), partial = d.stats.networth_partial == true or nil,
                            lh = d.stats.lasthits, dn = d.stats.denies}
                        local pd = d.playerData
                        if h.team == state.localTeam and type(pd) == "table" and (finite(pd.reliable_gold) or finite(pd.unreliable_gold)) then
                            info.stats.g = round((finite(pd.reliable_gold) and pd.reliable_gold or 0) + (finite(pd.unreliable_gold) and pd.unreliable_gold or 0))
                        end
                    end
                    if type(d.buyback) == "table" and finite(d.buyback.cooldown) then
                        info.buyback = {ready_at = readyAt(d.game, d.buyback.cooldown) or 0}
                    end
                    v.info["h" .. h.id] = info
                end
            end
        end
        table.sort(v.pos, byId)
        local r = state.relay
        v.units = {}
        local hidden, visible, alive = {}, {}, {}
        for _, u in pairs(r.units) do
            if u.alive ~= false and finite(u.x) and finite(u.y) then
                local row = {id = u.id, kind = u.kind, team = u.team, x = round(u.x), y = round(u.y), f = u.visible == true and 0 or 1}
                if u.kind == "building" then
                    local tier, lane = tostring(u.name or ""):match("tower(%d)_(%a+)$")
                    if tier then
                        local tower = {x = u.x, y = u.y, team = u.team, tier = tonumber(tier), lane = lane}
                        m.towers[u.id], alive[u.id] = tower, tower
                    end
                    if finite(u.hp) and finite(u.max_hp) and u.max_hp > 0 then row.hp = round(u.hp / u.max_hp * 100) end
                end
                if u.kind == "creep" then
                    row.s = tostring(u.name or ""):find("siege", 1, true) and 1 or nil
                    local entry = state.laneMovers[u.id]
                    if u.visible == true then
                        if entry then entry.gone = nil end
                        visible[#visible + 1] = u
                        v.units[#v.units + 1] = row
                    else hidden[#hidden + 1] = {u = u, row = row} end
                elseif u.kind ~= "illusion" or u.visible == true then
                    v.units[#v.units + 1] = row
                end
            end
        end
        for _, row in ipairs(predictCreeps(hidden, visible, alive, now)) do v.units[#v.units + 1] = row end
        table.sort(v.units, byId)
        v.wards = {}
        for _, w in ipairs(r.wards or {}) do
            if finite(w.x) and finite(w.y) then
                v.wards[#v.wards + 1] = {id = w.id, kind = w.kind, team = w.team, x = round(w.x), y = round(w.y),
                    f = w.visible == true and 0 or 1, r = round(w.radius), e = at(w.expires_at)}
            end
        end
        table.sort(v.wards, byId)
        v.runes = {}
        for _, rune in ipairs(r.runes or {}) do
            if finite(rune.x) and finite(rune.y) then
                v.runes[#v.runes + 1] = {id = rune.id, x = round(rune.x), y = round(rune.y), rune_type = rune.rune_type,
                    f = rune.visible == true and 0 or 1}
            end
        end
        table.sort(v.runes, byId)
        v.camps = {}
        for _, c in ipairs(state.camps or {}) do
            if finite(c.x) and finite(c.y) then
                v.camps[#v.camps + 1] = {x = round(c.x), y = round(c.y), t = c.camp_type,
                    s = c.state == "occupied" and 1 or c.state == "empty" and 0 or nil,
                    n = c.count, st = finite(c.stack_count) and c.stack_count > 1 and c.stack_count or nil}
            end
        end
        v.events = {}
        for _, e in ipairs(packet.events or {}) do
            if finite(e.x) and finite(e.y) then
                local destination = e.kind == "teleport" and e.phase == "destination"
                v.events[#v.events + 1] = {id = e.id, kind = e.kind, x = round(e.x), y = round(e.y), a = e.ability_name,
                    h = e.owner_name, team = e.team, f = e.stale == true and 1 or nil, ph = e.phase,
                    ox = destination and round(e.origin_x) or nil, oy = destination and round(e.origin_y) or nil,
                    t0 = at(e.started), te = at(e.channel_end_at)}
            end
        end
        table.sort(v.events, byId)
        local o = packet.objectives or {}
        v.objectives = {tormentors = {}}
        for _, key in ipairs({"glyph_radiant", "glyph_dire", "scan_radiant", "scan_dire"}) do
            if finite(o[key]) then v.objectives[key] = o[key] > 0.5 and round(gt + o[key]) or 0 end
        end
        if type(o.roshan) == "table" and o.roshan.stale ~= true and o.roshan.source == "entity" then v.objectives.roshan = boss(o.roshan) end
        for _, t in ipairs(o.tormentors or {}) do
            if t.stale ~= true then v.objectives.tormentors[#v.objectives.tormentors + 1] = boss(t) end
        end
        return v
    end

    local function sideOf(team)
        local lt = state.localTeam
        if (team ~= 2 and team ~= 3) or (lt ~= 2 and lt ~= 3) then return "n" end
        return team == lt and "a" or "e"
    end

    local function place(x, y)
        if not finite(x) or not finite(y) then return nil end
        local m = state.mem
        if m.rosh and (x - m.rosh.x) ^ 2 + (y - m.rosh.y) ^ 2 < 1800 ^ 2 then return "rosh" end
        for _, t in ipairs(m.torm or {}) do
            if (x - t.x) ^ 2 + (y - t.y) ^ 2 < 1500 ^ 2 then return "torm" end
        end
        local tower, best = nil, 1100 ^ 2
        for _, t in pairs(m.towers or {}) do
            local d = (x - t.x) ^ 2 + (y - t.y) ^ 2
            if d < best then tower, best = t, d end
        end
        if tower then return "t" .. (tower.team == 2 and "r" or "d") .. tower.tier .. "_" .. tower.lane end
        local s, d = x + y, y - x
        if s < -9800 then return "base_r" end
        if s > 9800 then return "base_d" end
        local zone = math.abs(d) < 3000 and "mid" or (d > 0 and "top" or "bot")
        local side = s < -3500 and "r" or (s > 3500 and "d" or "c")
        return zone .. "_" .. side
    end

    local function log(entry)
        state.feedSeq = state.feedSeq + 1
        entry.t, entry.key = state.mem.gt or 0, string.format("e%010d%05d", state.feedBase or 0, state.feedSeq)
        state.feedQueue[#state.feedQueue + 1] = entry
        while #state.feedQueue > 200 do table.remove(state.feedQueue, 1) end
        return entry
    end

    local function requeue(entry)
        for _, queued in ipairs(state.feedQueue) do if queued == entry then return end end
        state.feedQueue[#state.feedQueue + 1] = entry
    end

    local function addScanPlace(where)
        local scan = state.mem.scan
        if not where or scan.places[where] then return end
        scan.places[where] = true
        scan.entry.p = scan.entry.p and (scan.entry.p .. "," .. where) or where
        requeue(scan.entry)
    end

    local function trackBoss(key, kind, info, side)
        local m = state.mem
        m.boss = m.boss or {}
        local b = m.boss[key] or {atk = false, last = 0}
        m.boss[key] = b
        local alive, pct = info.alive, info.hp
        local attackers = #info.attackers > 0 and info.attackers or nil
        if alive == false and b.alive == true then
            log({k = "boss_dead", b = kind, team = side})
            b.atk = false
        elseif alive == true and b.alive == false then
            log({k = "boss_up", b = kind, team = side})
        end
        if alive ~= nil then b.alive = alive end
        local attacking = info.under_attack == true and alive ~= false
        if attacking and not b.atk then
            log({k = "boss_hit", b = kind, team = side, v = pct, n = attackers})
            b.atk, b.pct = true, pct
        elseif attacking and pct and b.pct and b.pct - pct >= 15 then
            log({k = "boss_hp", b = kind, team = side, v = pct, n = attackers})
            b.pct = pct
        end
        if attacking then b.last = m.gt
        elseif b.atk and m.gt - b.last > 6 and alive ~= false then
            log({k = "boss_calm", b = kind, team = side, v = pct})
            b.atk = false
        end
    end

    local function campAt(x, y)
        for _, camp in ipairs(state.campDefs or {}) do
            if x >= camp.min_x - 220 and x <= camp.max_x + 220 and y >= camp.min_y - 220 and y <= camp.max_y + 220 then return camp.id end
        end
    end

    function relay.derive(packet, v)
        if not packet.in_game then state.mem = {}; return end
        local m = state.mem
        m.gt = v.clock.t
        local obj = v.objectives
        if obj.roshan and obj.roshan.x then m.rosh = {x = obj.roshan.x, y = obj.roshan.y} end
        local torm = {}
        for _, t in ipairs(obj.tormentors) do if t.x then torm[#torm + 1] = {x = t.x, y = t.y} end end
        if #torm > 0 then m.torm = torm end
        if obj.roshan then trackBoss("rosh", "rosh", obj.roshan) end
        for _, t in ipairs(obj.tormentors) do
            trackBoss("torm" .. tostring(t.id), "torm", t, t.x and (t.x + t.y < 0 and "r" or "d") or nil)
        end

        m.h, m.runeLog, m.runes, m.ev, m.cd = m.h or {}, m.runeLog or {}, m.runes or {}, m.ev or {}, m.cd or {}
        local heroes, seenNow = {}, {}
        for _, h in ipairs(v.pos) do
            heroes[h.id] = h
            if h.f == 0 then seenNow[#seenNow + 1] = h end
            local hm = m.h[h.id] or {}
            m.h[h.id] = hm
            if h.alive == false and hm.alive == true then
                log({k = "death", s = sideOf(h.team), h = h.name, r = h.respawn_at and math.max(0, h.respawn_at - m.gt) or nil})
            end
            if h.alive ~= nil then hm.alive = h.alive end
            local enemy = sideOf(h.team) == "e" and h.alive ~= false
            if enemy and h.f == 1 and h.seen and m.gt - h.seen <= 3 and h.seen ~= hm.spotSeen then
                hm.spotSeen = h.seen
                local far = not hm.spotX or (h.x - hm.spotX) ^ 2 + (h.y - hm.spotY) ^ 2 >= 800 ^ 2
                if far and m.gt - (hm.spotAt or -99) >= 15 then
                    log({k = "spot", s = "e", h = h.name, p = place(h.x, h.y)})
                    hm.spotAt, hm.spotX, hm.spotY = m.gt, h.x, h.y
                end
            end
            local camp = enemy and h.f == 1 and campAt(h.x, h.y)
            if camp then
                if hm.camp ~= camp then hm.camp, hm.campAt, hm.campLogged = camp, m.gt, false
                elseif not hm.campLogged and m.gt - hm.campAt >= 2 then
                    hm.campLogged = true
                    log({k = "farm", s = "e", h = h.name, p = place(h.x, h.y)})
                end
            elseif h.f ~= 1 or not enemy then hm.camp = nil end
            local d = state.details[h.id]
            if h.f == 0 and d and type(d.modifiers) == "table" and d.game ~= hm.modsAt then
                hm.modsAt = d.game
                local mods = {}
                for _, mod in ipairs(d.modifiers) do if mod.name then mods[mod.name] = true end end
                if hm.mods then
                    for name in pairs(mods) do
                        if RUNE_MODS[name] and not hm.mods[name] and m.gt - (m.runeLog[h.id] or -99) > 3 then
                            log({k = "rune", s = sideOf(h.team), h = h.name, a = RUNE_MODS[name]})
                            m.runeLog[h.id] = m.gt
                        end
                    end
                end
                hm.mods = mods
            end
        end

        local current = {}
        for _, rune in ipairs(v.runes) do
            if rune.f == 0 then
                current[rune.id] = true
                m.runes[rune.id] = {x = rune.x, y = rune.y, kind = rune.rune_type}
            end
        end
        for id, prev in pairs(m.runes) do
            if not current[id] then
                local near, best = nil, 450 ^ 2
                for _, h in ipairs(seenNow) do
                    if h.alive ~= false then
                        local dist = (h.x - prev.x) ^ 2 + (h.y - prev.y) ^ 2
                        if dist < best then near, best = h, dist end
                    end
                end
                if near and m.gt - (m.runeLog[near.id] or -99) > 3 then
                    log({k = "rune", s = sideOf(near.team), h = near.name, a = prev.kind, p = place(prev.x, prev.y)})
                    m.runeLog[near.id] = m.gt
                end
                m.runes[id] = nil
            end
        end

        m.wardSeen = m.wardSeen or {}
        local firstWards = not m.wardInit
        m.wardInit = true
        for _, w in ipairs(v.wards) do
            if not m.wardSeen[w.id] then
                m.wardSeen[w.id] = true
                if not firstWards and w.f == 0 and sideOf(w.team) == "e" then
                    log({k = "ward", s = "e", w = w.kind == "sentry" and "s" or "o", p = place(w.x, w.y)})
                end
            end
        end

        for _, kill in ipairs(state.kills) do
            log({k = kill.barracks and "rax" or "tower", team = kill.team == 2 and "r" or kill.team == 3 and "d" or nil,
                s = sideOf(kill.team), p = place(kill.x, kill.y)})
        end
        state.kills = {}

        for _, e in ipairs(packet.events or {}) do
            if e.id and finite(e.x) and finite(e.y) and not m.ev[e.id] then
                m.ev[e.id] = m.gt
                local owner = e.owner_id and heroes[e.owner_id]
                local name = owner and owner.name or (tostring(e.owner_name or ""):find("npc_dota_hero_", 1, true) == 1 and e.owner_name) or nil
                local entry = {s = sideOf(owner and owner.team or e.team), h = name, p = place(e.x, e.y)}
                if e.kind == "teleport" then
                    entry.k = e.phase == "destination" and "tp_to" or "tp_from"
                    log(entry)
                elseif e.kind == "scan" then
                    if m.scan and m.gt - m.scan.at <= 4 then addScanPlace(entry.p)
                    else m.scan = {entry = log({k = "scan", p = entry.p}), at = m.gt, places = {[entry.p or ""] = true}} end
                elseif e.kind == "smoke" then
                    entry.k = "smoke"
                    log(entry)
                elseif e.kind == "blink" then
                    if e.phase ~= "origin" then entry.k = "blink"; log(entry) end
                elseif e.kind ~= "innate" then
                    entry.k, entry.a = e.ultimate == true and "ult" or "ability", e.ability_name or e.name
                    log(entry)
                end
            end
        end
        for id, at in pairs(m.ev) do
            if m.gt - at > 120 or at > m.gt then m.ev[id] = nil end
        end

        for _, key in ipairs({"glyph_radiant", "glyph_dire", "scan_radiant", "scan_dire"}) do
            local value = obj[key]
            if value then
                local prev = m.cd[key]
                if prev and value > prev + 30 and value - m.gt > 100 then
                    local team = key:find("radiant", 1, true) and "r" or "d"
                    if key:find("glyph", 1, true) then log({k = "glyph", team = team})
                    elseif not (m.scan and m.gt - m.scan.at <= 4) then
                        m.scan = {entry = log({k = "scan_used", team = team}), at = m.gt, places = {}}
                    end
                end
                m.cd[key] = value
            end
        end
    end

    function relay.build(packet)
        if packet.in_game and packet.match ~= state.relayMatch then
            state.relayMatch, state.mem, state.feedQueue, state.clearFeed = packet.match, {}, {}, true
            state.feedKeys, state.feedPrune = {}, {}
            state.relay = {units = {}, wards = {}, runes = {}}
            savedSet("match", tostring(packet.match))
        end
        relay.merge(packet)
        local v = relay.view(packet)
        relay.derive(packet, v)
        for _, key in ipairs({"units", "wards", "runes", "events"}) do strip(v[key]) end
        return v
    end

    function relay.patch(v)
        local began = clock()
        local fields, commit, feedCount = {}, {}, 0
        for _, key in ipairs(PARTS) do
            local encoded = v[key] ~= nil and call(JSON.encode, JSON, v[key]) or "null"
            if encoded and (state.resendAll or state.sentParts[key] ~= encoded) then
                fields[#fields + 1] = '"live/' .. key .. '":' .. encoded
                commit[key] = encoded
            end
        end
        if state.clearFeed then
            fields[#fields + 1] = '"feed":null'
        else
            for _, key in ipairs(state.feedPrune) do fields[#fields + 1] = '"feed/' .. key .. '":null' end
            for index, entry in ipairs(state.feedQueue) do
                if index > 20 then break end
                local encoded = call(JSON.encode, JSON, entry)
                if encoded then fields[#fields + 1] = '"feed/' .. entry.key .. '":' .. encoded end
                feedCount = index
            end
        end
        fields[#fields + 1] = '"meta/updated":{".sv":"timestamp"}'
        state.perf.encode_ms = (clock() - began) * 1000
        return "{" .. table.concat(fields, ",") .. "}", commit, feedCount
    end
end

function script.OnScriptsLoaded()
    initMenu()
    local session = savedGet("session")
    if get(ui.enabled, false) and #session == 20 then start() end
end

function script.OnUpdateEx()
    initMenu()
    if state.retryAt and clock() >= state.retryAt and not state.active and not state.control then
        state.retryAt = nil
        if get(ui.enabled, false) then start() end
    end
    if #state.requests > 0 then
        local pending = state.requests
        state.requests = {}
        for _, entry in ipairs(pending) do
            if not entry.finished and clock() >= entry.deadline then entry.finish(nil, 0) end
            if not entry.finished then state.requests[#state.requests + 1] = entry end
        end
    end
    if not state.active then return end
    local now = clock()
    refreshFlags(now)
    if not state.flags.enabled then return end
    if not state.localTeam then local hero = call(Heroes.GetLocal); state.localTeam = hero and call(Entity.GetTeamNum, hero) or 2 end
    if call(Engine.IsInGame) == true and (state.scanJob or now >= state.nextSlow) then
        local scanBegan = clock()
        slowSnapshot(gameClock())
        state.perf.scan_ms = (clock() - scanBegan) * 1000
    end
    if state.sending then
        if now - state.sentAt < 5 then return end
        state.requestId = state.requestId + 1
        state.sending = false
        state.needFull, state.layersDirty, state.resendAll = true, true, true
    end
    if now < state.nextSend then return end
    local rate = state.rate or 5
    -- Keep the cadence across game frames (90 / 20 is not an integer).
    -- Reset after a long stall instead of sending a catch-up burst.
    local period = 1 / rate
    state.nextSend = now - state.nextSend > period and now + period or state.nextSend + period
    local fb = state.fb
    if not fb.token or wallClock() >= (fb.expires or 0) then
        if not fb.authorizing then
            authorize(function(ok, code) if not ok then show("cr_st_auth_fail", code or 0) end end)
        end
        return
    end
    local began = clock()
    local ok, packet = pcall(collect)
    state.perf.collect_ms = (clock() - began) * 1000
    if not ok then show("cr_st_collect_fail", tostring(packet)); state.nextSend = now + 1; return end
    local built, view = pcall(relay.build, packet)
    if not built then show("cr_st_collect_fail", tostring(view)); state.nextSend = now + 1; return end
    local body, commit, feedCount = relay.patch(view)
    local clearing = state.clearFeed
    state.perf.bytes = #body
    state.sending, state.sentAt = true, now
    state.requestId = state.requestId + 1
    local id = state.requestId
    state.perf.rate = rate
    dbRequest("PATCH", state.session, body, function(_, code)
        if state.requestId ~= id then return end
        state.sending = false
        if code >= 200 and code < 300 then
            for key, encoded in pairs(commit) do state.sentParts[key] = encoded end
            if not clearing then
                state.feedPrune = {}
                local known = {}
                for _, key in ipairs(state.feedKeys) do known[key] = true end
                for _ = 1, feedCount do
                    local entry = table.remove(state.feedQueue, 1)
                    if entry and not known[entry.key] then
                        known[entry.key] = true
                        state.feedKeys[#state.feedKeys + 1] = entry.key
                    end
                end
                while #state.feedKeys > 100 do state.feedPrune[#state.feedPrune + 1] = table.remove(state.feedKeys, 1) end
            else
                state.clearFeed = false
            end
            state.resendAll, state.failures = false, 0
            state.perf.upload_ms = math.max(0, (clock() - now) * 1000)
            show(packet.in_game and "cr_st_running" or "cr_st_waiting")
        else
            state.resendAll = true
            state.failures = math.min(state.failures + 1, 6)
            state.nextSend = clock() + math.min(8, 0.5 * 2 ^ state.failures)
            if code == 401 or code == 403 then state.fb.token = nil end
            if code == 403 and state.failures >= 3 then state.active = false end
            show("cr_st_send_fail", code)
        end
    end)
    if now >= (state.nextPerf or 0) then
        state.nextPerf = now + 2
        if ui.performance then ui.performance:Name(string.format(L("cr_performance"), state.perf.collect_ms, state.perf.encode_ms, state.perf.bytes / 1024)) end
    end
end

local ok, result = pcall(require, "assets.JSON")
if ok then JSON = result end
return script
