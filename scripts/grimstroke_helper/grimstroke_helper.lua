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
        gh_group_main = "Grimstroke Helper",
        gh_group_ink = "Ink Swell",
        gh_group_dp = "Dark Portrait Illusion",
        gh_group_combo = "Built-in Combo",
        gh_enable = "Enable",
        gh_enable_tip = "Turns on every feature of this helper.",
        gh_panel = "Ally Panel",
        gh_panel_tip = "On-screen panel: click an ally icon to allow or forbid Ink Swell.\nThe header switch pauses the helper.",
        gh_ink_enable = "Auto Ink Swell",
        gh_ink_enable_tip = "Casts Ink Swell on an ally standing next to enemies.",
        gh_ink_mode = "Ally Choice",
        gh_ink_mode_tip = "Allies are allowed or forbidden in the on-screen panel.",
        gh_ink_modes_closest = "Any ally near enemies",
        gh_ink_modes_whitelist = "Allowed ally closest to enemies",
        gh_ink_modes_whitelist_range = "Allowed ally near enemies",
        gh_ink_dist = "Ally to Enemy Distance",
        gh_ink_dist_tip = "An ally farther than this from every enemy is skipped.\nNot used in the second mode.",
        gh_ink_self = "Allow Self by Default",
        gh_ink_self_tip = "Whether Grimstroke himself starts as allowed in the panel.",
        gh_dp_enable = "Control Illusion",
        gh_dp_enable_tip = "Sends the Dark Portrait illusion to attack automatically.",
        gh_dp_priority = "Target Priority",
        gh_dp_priorities_hp = "Lowest HP",
        gh_dp_priorities_pct = "Lowest HP %",
        gh_dp_heroes = "Heroes Only",
        gh_dp_heroes_tip = "Off: the illusion also attacks creeps when no enemy hero is visible.",
        gh_dp_idle = "No Visible Heroes",
        gh_dp_idles_follow = "Follow Grimstroke",
        gh_dp_idles_attack = "Attack nearest enemies",
        gh_dp_idles_hold = "Stay in place",
        gh_dp_wl = "Dark Portrait Whitelist",
        gh_dp_wl_tip = "While the combo key is held, the built-in combo casts Dark Portrait only on checked enemies.\nOther abilities are not affected.",
        gh_dp_list = "Dark Portrait Targets",
        gh_sb_wl = "Solo Soulbind Whitelist",
        gh_sb_wl_tip = "With the level 15 talent, the combo Soulbinds a checked enemy even when alone.\nOther enemies still need a second enemy in link range.",
        gh_sb_list = "Solo Soulbind Targets",
        gh_wl_empty = "Enemies appear here in a match",
        gh_gear_extra = "Extra",
        gh_debug = "Debug Log",
        gh_debug_tip = "Logs panel clicks and key presses.",
        gh_panel_key = "Panel Key",
        gh_panel_key_tip = "Shows or hides the ally panel.",
        gh_panel_key_name = "Grimstroke: panel",
        gh_filters_key = "Filters Key",
        gh_filters_key_tip = "Opens a window with both combo filters.\nClick an enemy icon to check it.",
        gh_filters_key_name = "Grimstroke: filters",
        gh_hud_filters = "Combo Filters",
        gh_hud_sb = "Solo Soulbind",
        gh_hud_ink = "Ink Swell Targets",
        gh_hud_you = " (You)",
        gh_hud_dp = "Dark Portrait",
        gh_hud_none = "Illusion: none",
        gh_hud_paused = "Automation: paused",
        gh_hud_focus = "Focus: %s (%.0f HP)",
        gh_hud_follow = "Illusion: following",
    },
    ru = {
        gh_group_main = "Grimstroke Helper",
        gh_group_ink = "Ink Swell",
        gh_group_dp = "Иллюзия Dark Portrait",
        gh_group_combo = "Встроенное комбо",
        gh_enable = "Включить",
        gh_enable_tip = "Включает все функции помощника.",
        gh_panel = "Панель союзников",
        gh_panel_tip = "Панель на экране: клик по иконке союзника разрешает Ink Swell.\nПереключатель в заголовке ставит помощника на паузу.",
        gh_ink_enable = "Авто Ink Swell",
        gh_ink_enable_tip = "Кастует Ink Swell на союзника рядом с врагами.",
        gh_ink_mode = "Выбор союзника",
        gh_ink_mode_tip = "Разрешенные союзники отмечаются в панели на экране.",
        gh_ink_modes_closest = "Любой рядом с врагами",
        gh_ink_modes_whitelist = "Разрешенный, ближайший к врагам",
        gh_ink_modes_whitelist_range = "Разрешенный рядом с врагами",
        gh_ink_dist = "Дистанция до врага",
        gh_ink_dist_tip = "Союзник дальше этого от всех врагов пропускается.\nВо втором режиме не используется.",
        gh_ink_self = "Себя разрешить сразу",
        gh_ink_self_tip = "Разрешен ли сам Grimstroke в панели при старте.",
        gh_dp_enable = "Управлять иллюзией",
        gh_dp_enable_tip = "Иллюзия Dark Portrait сама атакует цель.",
        gh_dp_priority = "Приоритет цели",
        gh_dp_priorities_hp = "Меньше всего HP",
        gh_dp_priorities_pct = "Меньше всего HP в %",
        gh_dp_heroes = "Только герои",
        gh_dp_heroes_tip = "Выключено: без видимых героев иллюзия бьет и крипов.",
        gh_dp_idle = "Нет видимых героев",
        gh_dp_idles_follow = "Идти за Grimstroke",
        gh_dp_idles_attack = "Атаковать ближайших",
        gh_dp_idles_hold = "Стоять на месте",
        gh_dp_wl = "Фильтр Dark Portrait",
        gh_dp_wl_tip = "Пока зажата клавиша комбо, встроенное комбо кастует Dark Portrait только на отмеченных врагов.\nОстальные способности работают как обычно.",
        gh_dp_list = "Цели Dark Portrait",
        gh_sb_wl = "Фильтр соло Soulbind",
        gh_sb_wl_tip = "С талантом 15 уровня комбо связывает отмеченного врага, даже если он один.\nОстальным врагам по-прежнему нужен второй враг рядом.",
        gh_sb_list = "Цели соло Soulbind",
        gh_wl_empty = "Враги появятся здесь в матче",
        gh_gear_extra = "Дополнительно",
        gh_debug = "Отладка в лог",
        gh_debug_tip = "Пишет в лог клики по панели и нажатия клавиш.",
        gh_panel_key = "Клавиша панели",
        gh_panel_key_tip = "Показывает или прячет панель союзников.",
        gh_panel_key_name = "Grimstroke: панель",
        gh_filters_key = "Клавиша фильтров",
        gh_filters_key_tip = "Открывает окно с обоими фильтрами комбо.\nКлик по иконке врага отмечает его.",
        gh_filters_key_name = "Grimstroke: фильтры",
        gh_hud_filters = "Фильтры комбо",
        gh_hud_sb = "Соло Soulbind",
        gh_hud_ink = "Цели Ink Swell",
        gh_hud_you = " (вы)",
        gh_hud_dp = "Dark Portrait",
        gh_hud_none = "Иллюзии нет",
        gh_hud_paused = "Автоматика на паузе",
        gh_hud_focus = "Цель: %s (%.0f HP)",
        gh_hud_follow = "Иллюзия идет за вами",
    },
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

--by m0rc1

local VERSION = "1.3.0"
local GrimHelper = {}

-- ============================================================================
-- Menu Variables
-- ============================================================================
local ui_enabled            = nil
local ui_draw_panel         = nil

-- Ink Swell settings
local ui_ink_enabled        = nil
local ui_ink_mode           = nil
local ui_ink_max_dist       = nil
local ui_ink_self           = nil

-- Dark Portrait settings
local ui_dp_enabled         = nil
local ui_dp_target_mode     = nil
local ui_dp_heroes_only     = nil
local ui_dp_fallback        = nil

-- Built-in combo whitelists
local ui_dp_wl_enabled      = nil
local ui_dp_wl              = nil
local ui_sb_wl_enabled      = nil
local ui_sb_wl              = nil
local ui_wl_empty           = nil
local ui_panel_key          = nil
local ui_debug              = nil
local ui_filters_key        = nil

-- ============================================================================
-- State & Performance Cache
-- ============================================================================
local panel_active          = true
local last_ink_cast_time    = 0
local last_illu_orders      = {}
local allowed_allies        = {}

local cache = {
    last_ally_scan_t = 0,
    last_illu_scan_t = 0,
    allies = {},
    illusions = {},
    illu_target = nil,
    allowed_count = 0
}

local SOLO_SOUL_TALENT  = "special_bonus_unique_grimstroke_soul_chain_reflect_damage"
local SOUL_LATCH_RADIUS = 600

local whitelist = { dp = {}, sb = {} }
local builtin   = {}
local combo = {
    target = nil,
    saved = {},
    enemy_key = nil,
    next_list_t = 0,
    last_soul_t = 0,
    updating = false
}

-- ============================================================================
-- On-Screen Panel State & Animation
-- ============================================================================
local win = {
    main = { x = 40, y = 160, alpha = 0 },
    filters = { x = 300, y = 160, alpha = 0, open = false },
    hot = nil,
    drag = nil,
    swallow = false,
    fonts = nil
}

-- Fonts
local font_main = nil
local font_bold = nil
local font_icon = nil

pcall(function()
    font_main = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 500)
    font_bold = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 700)
    font_icon = Render.LoadFont("FontAwesomeEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 400)
end)

if not font_main then
    pcall(function()
        font_main = Render.LoadFont("Segoe UI", Enum.FontCreate.FONTFLAG_ANTIALIAS, 400)
        font_bold = Render.LoadFont("Segoe UI", Enum.FontCreate.FONTFLAG_ANTIALIAS, 700)
    end)
end

-- ============================================================================
-- Whitelist Storage & Built-in Combo Settings
-- ============================================================================
local function StoragePath()
    local dir = Engine.GetCheatDirectory and Engine.GetCheatDirectory()
    if not dir or dir == "" then return nil end
    return (dir:gsub("[\\/]+$", "")) .. "/configs/grimstroke_helper.txt"
end

local function SaveWhitelist()
    local path = StoragePath()
    local file = path and io.open(path, "w")
    if not file then return end
    for kind, list in pairs(whitelist) do
        for name, on in pairs(list) do
            if on then file:write(kind, " ", name, "\n") end
        end
    end
    for key, value in pairs(combo.saved) do
        file:write("restore ", key, " ", value and "1" or "0", "\n")
    end
    file:close()
end

local function LoadWhitelist()
    local path = StoragePath()
    local file = path and io.open(path, "r")
    if not file then return end
    for line in file:lines() do
        local kind, name, value = line:match("^(%S+)%s+(%S+)%s*(%S*)")
        if kind == "restore" then
            combo.saved[name] = value == "1"
        elseif kind and whitelist[kind] then
            whitelist[kind][name] = true
        end
    end
    file:close()
end

local function WhitelistItems(kind, names)
    if #names == 0 then
        for name, on in pairs(whitelist[kind]) do
            if on then table.insert(names, name) end
        end
        table.sort(names)
    end
    local items = {}
    for i, name in ipairs(names) do
        items[i] = { name, "panorama/images/heroes/icons/" .. name .. "_png.vtex_c", whitelist[kind][name] == true }
    end
    return items
end

local BUILTIN_PATHS = {
    abilities = { "Main Settings", "Hero Settings", "Abilities" },
    key       = { "Main Settings", "Hero Settings", "Combo Key" },
    solo      = { "Main Settings", "Hero Settings", "Use in Solo Target with Talent" },
    range     = { "Extra Settings", "Target Selection", "Search Range" }
}

local function BuiltinWidget(key)
    if builtin[key] == nil then
        local p = BUILTIN_PATHS[key]
        builtin[key] = Menu.Find("Heroes", "Hero List", "Grimstroke", p[1], p[2], p[3]) or false
    end
    return builtin[key] or nil
end

local function GetBuiltin(key)
    if key == "dp" then
        local w = BuiltinWidget("abilities")
        return w, w and w:Get("grimstroke_dark_portrait")
    end
    local w = BuiltinWidget("solo")
    return w, w and w:Get()
end

local function WriteBuiltin(key, w, value)
    if key == "dp" then w:Set("grimstroke_dark_portrait", value) else w:Set(value) end
end

local function SetBuiltin(key, allowed)
    local w, current = GetBuiltin(key)
    if not w then return end
    local original = combo.saved[key]
    if original == nil then original = current end
    local value = original and allowed
    if value == current then return end
    if combo.saved[key] == nil then
        combo.saved[key] = original
        SaveWhitelist()
    end
    WriteBuiltin(key, w, value)
end

local function RestoreBuiltin()
    if next(combo.saved) == nil then return end
    for key, original in pairs(combo.saved) do
        local w, current = GetBuiltin(key)
        if w and current ~= original then WriteBuiltin(key, w, original) end
    end
    combo.saved = {}
    SaveWhitelist()
end

LoadWhitelist()

-- ============================================================================
-- Menu Setup (Heroes -> Hero List -> Grimstroke -> Helper)
-- ============================================================================
local function MenuOn(w)
    return w ~= nil and w:Get()
end

local function RefreshDisabled()
    local on = MenuOn(ui_enabled)
    local ink_on = on and MenuOn(ui_ink_enabled)
    local dp_on = on and MenuOn(ui_dp_enabled)
    ui_draw_panel:Disabled(not on)
    ui_debug:Disabled(not on)
    ui_panel_key:Disabled(not on)
    ui_filters_key:Disabled(not on)
    ui_ink_enabled:Disabled(not on)
    ui_ink_mode:Disabled(not ink_on)
    ui_ink_max_dist:Disabled(not ink_on or MenuOn(ui_ink_mode) == 1)
    ui_ink_self:Disabled(not ink_on)
    ui_dp_enabled:Disabled(not on)
    ui_dp_target_mode:Disabled(not dp_on)
    ui_dp_heroes_only:Disabled(not dp_on)
    ui_dp_fallback:Disabled(not dp_on)
    ui_dp_wl_enabled:Disabled(not on)
    ui_dp_wl:Disabled(not on or not MenuOn(ui_dp_wl_enabled))
    ui_sb_wl_enabled:Disabled(not on)
    ui_sb_wl:Disabled(not on or not MenuOn(ui_sb_wl_enabled))
end

local function ShowWhitelists(has_items)
    ui_dp_wl:Visible(has_items)
    ui_sb_wl:Visible(has_items)
    ui_wl_empty:Visible(not has_items)
end

local function SetupMenu()
    if ui_enabled ~= nil then return end

    local page = UI.Create("Heroes", "Hero List", "Grimstroke", "Helper")
    local g_main = page:Create("gh_group_main", Enum.GroupSide.Left)
    local g_ink = page:Create("gh_group_ink", Enum.GroupSide.Left)
    local g_dp = page:Create("gh_group_dp", Enum.GroupSide.Right)
    local g_combo = page:Create("gh_group_combo", Enum.GroupSide.Right)

    ui_enabled = g_main:Switch("gh_enable", true, "\u{f011}")
    ui_enabled:ToolTip("gh_enable_tip")
    local g_extra = ui_enabled:Gear("gh_gear_extra")
    ui_debug = g_extra:Switch("gh_debug", true, "\u{f188}")
    ui_debug:ToolTip("gh_debug_tip")
    ui_draw_panel = g_main:Switch("gh_panel", true, "\u{f05a}")
    ui_draw_panel:ToolTip("gh_panel_tip")
    ui_panel_key = g_main:Bind("gh_panel_key", Enum.ButtonCode.KEY_NONE, "\u{f11c}")
    ui_panel_key:ToolTip("gh_panel_key_tip")
    ui_panel_key:Properties(L("gh_panel_key_name"))
    ui_filters_key = g_main:Bind("gh_filters_key", Enum.ButtonCode.KEY_NONE, "\u{f0b0}")
    ui_filters_key:ToolTip("gh_filters_key_tip")
    ui_filters_key:Properties(L("gh_filters_key_name"))

    ui_ink_enabled = g_ink:Switch("gh_ink_enable", true, "\u{f0e7}")
    ui_ink_enabled:ToolTip("gh_ink_enable_tip")
    ui_ink_mode = g_ink:Combo("gh_ink_mode", { "gh_ink_modes_closest", "gh_ink_modes_whitelist", "gh_ink_modes_whitelist_range" }, 2)
    ui_ink_mode:Icon("\u{f05b}")
    ui_ink_mode:ToolTip("gh_ink_mode_tip")
    ui_ink_max_dist = g_ink:Slider("gh_ink_dist", 300, 1000, 650, "%d")
    ui_ink_max_dist:Icon("\u{f337}")
    ui_ink_max_dist:ToolTip("gh_ink_dist_tip")
    ui_ink_self = g_ink:Switch("gh_ink_self", true, "\u{f007}")
    ui_ink_self:ToolTip("gh_ink_self_tip")

    ui_dp_enabled = g_dp:Switch("gh_dp_enable", true, "\u{f6e2}")
    ui_dp_enabled:ToolTip("gh_dp_enable_tip")
    ui_dp_target_mode = g_dp:Combo("gh_dp_priority", { "gh_dp_priorities_hp", "gh_dp_priorities_pct" }, 0)
    ui_dp_target_mode:Icon("\u{f004}")
    ui_dp_heroes_only = g_dp:Switch("gh_dp_heroes", true, "\u{f505}")
    ui_dp_heroes_only:ToolTip("gh_dp_heroes_tip")
    ui_dp_fallback = g_dp:Combo("gh_dp_idle", { "gh_dp_idles_follow", "gh_dp_idles_attack", "gh_dp_idles_hold" }, 0)
    ui_dp_fallback:Icon("\u{f070}")

    ui_dp_wl_enabled = g_combo:Switch("gh_dp_wl", false, "\u{f03e}")
    ui_dp_wl_enabled:ToolTip("gh_dp_wl_tip")
    local dp_items = WhitelistItems("dp", {})
    ui_dp_wl = g_combo:MultiSelect("gh_dp_list", dp_items, false)
    ui_dp_wl:Icon("\u{f05b}")
    ui_sb_wl_enabled = g_combo:Switch("gh_sb_wl", false, "\u{f0c1}")
    ui_sb_wl_enabled:ToolTip("gh_sb_wl_tip")
    local sb_items = WhitelistItems("sb", {})
    ui_sb_wl = g_combo:MultiSelect("gh_sb_list", sb_items, false)
    ui_sb_wl:Icon("\u{f05b}")
    ui_wl_empty = g_combo:Label("gh_wl_empty", "\u{f05a}")
    ShowWhitelists(#dp_items > 0 and #sb_items > 0)

    for kind, list in pairs({ dp = ui_dp_wl, sb = ui_sb_wl }) do
        list:SetCallback(function()
            if combo.updating then return end
            for _, id in ipairs(list:List()) do
                whitelist[kind][id] = list:Get(id) == true
            end
            SaveWhitelist()
        end)
    end

    for _, w in ipairs({ ui_enabled, ui_ink_enabled, ui_ink_mode, ui_dp_enabled, ui_dp_wl_enabled, ui_sb_wl_enabled }) do
        w:SetCallback(RefreshDisabled)
    end
    RefreshDisabled()

    RestoreBuiltin()
end

-- ============================================================================
-- Helpers
-- ============================================================================
local function GetVal(item)
    if not item or not item.Get then return false end
    return item:Get()
end


local hero_icons = {}

local function HeroIcon(name)
    if hero_icons[name] == nil then
        hero_icons[name] = Render.LoadImage("panorama/images/heroes/icons/" .. name .. "_png.vtex_c") or false
    end
    return hero_icons[name] or nil
end

local hero_names = {}

local function HeroDisplayName(name)
    local cached = hero_names[name]
    if cached then return cached end
    local loc = GameLocalizer.FindNPC(name)
    if not loc or loc == "" then
        loc = name:gsub("npc_dota_hero_", ""):gsub("_", " ")
        loc = loc:sub(1, 1):upper() .. loc:sub(2)
    end
    hero_names[name] = loc
    return loc
end

local function IsGrimstroke(hero)
    if not hero or not Entity.IsAlive(hero) then return false end
    local name = NPC.GetUnitName(hero)
    return name and name == "npc_dota_hero_grimstroke"
end

local function IsAbilityReady(hero, ability)
    if not ability or not hero then return false end
    if Ability.GetLevel(ability) == 0 then return false end
    if Ability.GetCooldown(ability) > 0 then return false end

    local mana_cost = Ability.GetManaCost(ability) or 0
    if NPC.GetMana(hero) < mana_cost then return false end

    if Ability.CanBeExecuted then
        local res = Ability.CanBeExecuted(ability)
        return (res == -1 or res == 0 or res == true)
    end
    return true
end

local function IsHeroDisabled(hero)
    if not hero then return true end

    if NPC.IsStunned then
        local ok, s = pcall(NPC.IsStunned, hero)
        if ok and s then return true end
    end

    if NPC.IsSilenced then
        local ok, s = pcall(NPC.IsSilenced, hero)
        if ok and s then return true end
    end

    if NPC.HasModifier then
        if NPC.HasModifier(hero, "modifier_sheepstick_debuff") or
           NPC.HasModifier(hero, "modifier_lion_voodoo") or
           NPC.HasModifier(hero, "modifier_shadow_shaman_voodoo") or
           NPC.HasModifier(hero, "modifier_eul_cyclone") or
           NPC.HasModifier(hero, "modifier_stunned") or
           NPC.HasModifier(hero, "modifier_silence") then
            return true
        end
    end

    return false
end

local function IssueOrder(player, order_type, target, pos, ability, unit)
    if not player or not unit then return false end

    pcall(Player.PrepareUnitOrders,
        player,
        order_type,
        target,
        pos or Vector(0, 0, 0),
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        unit,
        false,
        false,
        false,
        true
    )
    return true
end

-- ============================================================================
-- Performance Optimized Cache Updates
-- ============================================================================
local function UpdateThrottledData(my_hero)
    local now = GameRules.GetGameTime()

    -- 1. Allies & Distances Scan (every 0.15s)
    if now - cache.last_ally_scan_t >= 0.15 then
        cache.last_ally_scan_t = now

        local my_team = Entity.GetTeamNum(my_hero)
        local all_heroes = Heroes.GetAll() or {}

        local enemy_positions = {}
        for i = 1, #all_heroes do
            local h = all_heroes[i]
            if h and Entity.IsAlive(h) and not Entity.IsDormant(h) and Entity.GetTeamNum(h) ~= my_team then
                if not (NPC.IsIllusion and NPC.IsIllusion(h)) then
                    table.insert(enemy_positions, Entity.GetAbsOrigin(h))
                end
            end
        end

        local allies = {}
        local count_allowed = 0

        for i = 1, #all_heroes do
            local h = all_heroes[i]
            if h and Entity.IsAlive(h) and not Entity.IsDormant(h) and Entity.GetTeamNum(h) == my_team then
                if not (NPC.IsIllusion and NPC.IsIllusion(h)) then
                    local name = NPC.GetUnitName(h) or ""
                    if name ~= "" then
                        if allowed_allies[name] == nil then
                            if h == my_hero then
                                allowed_allies[name] = GetVal(ui_ink_self)
                            else
                                allowed_allies[name] = true
                            end
                        end

                        local is_allowed = allowed_allies[name]
                        if is_allowed then count_allowed = count_allowed + 1 end

                        local ally_pos = Entity.GetAbsOrigin(h)
                        local min_e_dist = math.huge

                        for k = 1, #enemy_positions do
                            local d = (enemy_positions[k] - ally_pos):Length2D()
                            if d < min_e_dist then min_e_dist = d end
                        end

                        local display = HeroDisplayName(name)
                        if h == my_hero then display = display .. L("gh_hud_you") end

                        table.insert(allies, {
                            ent = h,
                            name = name,
                            display = display,
                            pos = ally_pos,
                            is_self = (h == my_hero),
                            enemy_dist = min_e_dist,
                            enabled = is_allowed
                        })
                    end
                end
            end
        end

        cache.allies = allies
        cache.allowed_count = count_allowed
    end

    -- 2. Dark Portrait Illusions Scan (every 0.25s)
    if now - cache.last_illu_scan_t >= 0.25 then
        cache.last_illu_scan_t = now

        local pid = Hero.GetPlayerID(my_hero)
        local my_team = Entity.GetTeamNum(my_hero)
        local npcs = NPCs.GetAll() or {}
        local list = {}

        for i = 1, #npcs do
            local u = npcs[i]
            if u and Entity.IsAlive(u) and not Entity.IsDormant(u) then
                if NPC.IsIllusion and NPC.IsIllusion(u) and NPC.IsControllableByPlayer(u, pid) and Entity.GetTeamNum(u) == my_team then
                    local is_not_grim = (NPC.GetUnitName(u) or "") ~= "npc_dota_hero_grimstroke"
                    local has_dp_mod  = NPC.HasModifier and NPC.HasModifier(u, "modifier_grimstroke_dark_portrait")
                    if has_dp_mod or is_not_grim then
                        table.insert(list, u)
                    end
                end
            end
        end

        cache.illusions = list
    end
end

-- ============================================================================
-- Ink Swell Logic
-- ============================================================================
local function ProcessInkSwell(my_hero, my_player)
    if not GetVal(ui_ink_enabled) then return end

    local now = GameRules.GetGameTime()
    if now - last_ink_cast_time < 0.22 or now < (cache.next_ink_t or 0) then return end
    cache.next_ink_t = now + 0.1
    if IsHeroDisabled(my_hero) then return end

    local ink_ability = NPC.GetAbility(my_hero, "grimstroke_spirit_walk")
    if not ink_ability or not IsAbilityReady(my_hero, ink_ability) then return end

    local cast_range = Ability.GetCastRange(ink_ability)
    if NPC.GetCastRangeBonus then
        cast_range = cast_range + (NPC.GetCastRangeBonus(my_hero) or 0)
    end

    local hero_pos = Entity.GetAbsOrigin(my_hero)
    local max_enemy_dist = GetVal(ui_ink_max_dist) or 650
    local mode = GetVal(ui_ink_mode) or 2

    local best_target = nil
    local best_enemy_dist = math.huge
    local allies = cache.allies

    for i = 1, #allies do
        local node = allies[i]
        local allowed = false

        if mode == 0 then
            allowed = true
        elseif mode == 1 or mode == 2 then
            allowed = node.enabled
        end

        if allowed then
            local dist_to_grim = (node.pos - hero_pos):Length2D()
            if dist_to_grim <= (cast_range + 80) then
                if mode == 1 then
                    if node.enemy_dist < best_enemy_dist then
                        best_enemy_dist = node.enemy_dist
                        best_target = node.ent
                    end
                else
                    if node.enemy_dist <= max_enemy_dist and node.enemy_dist < best_enemy_dist then
                        best_enemy_dist = node.enemy_dist
                        best_target = node.ent
                    end
                end
            end
        end
    end

    if best_target then
        IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET, best_target, nil, ink_ability, my_hero)
        last_ink_cast_time = now
    end
end

-- ============================================================================
-- Dark Portrait Logic
-- ============================================================================
local function VisibleEnemyHeroes(my_team)
    local list = {}
    local all_heroes = Heroes.GetAll() or {}
    for i = 1, #all_heroes do
        local e = all_heroes[i]
        if e and Entity.IsAlive(e) and not Entity.IsDormant(e) and Entity.GetTeamNum(e) ~= my_team and not NPC.IsIllusion(e) then
            list[#list + 1] = e
        end
    end
    return list
end

local function GetBestTargetForIllusion(my_team, illu_pos, visible_enemy_heroes)
    local target_mode = GetVal(ui_dp_target_mode) or 0
    local heroes_only = GetVal(ui_dp_heroes_only)

    if #visible_enemy_heroes > 0 then
        local best = nil
        local lowest_metric = math.huge

        for i = 1, #visible_enemy_heroes do
            local e = visible_enemy_heroes[i]
            local metric = Entity.GetHealth(e)
            if target_mode == 1 then
                metric = Entity.GetHealth(e) / Entity.GetMaxHealth(e)
            end

            if metric < lowest_metric then
                lowest_metric = metric
                best = e
            end
        end

        return best
    end

    if heroes_only then return nil end

    local enemies_near = NPCs.InRadius(illu_pos, 1100, my_team, Enum.TeamType.TEAM_ENEMY) or {}
    local closest, closest_dist = nil, math.huge

    for i = 1, #enemies_near do
        local n = enemies_near[i]
        if n and Entity.IsAlive(n) and not Entity.IsDormant(n) then
            local d = (Entity.GetAbsOrigin(n) - illu_pos):Length2D()
            if d < closest_dist then
                closest_dist = d
                closest = n
            end
        end
    end

    return closest
end

local function ProcessDarkPortrait(my_hero, my_player)
    if not GetVal(ui_dp_enabled) then return end

    local illusions = cache.illusions
    if #illusions == 0 then
        cache.illu_target = nil
        if next(last_illu_orders) then last_illu_orders = {} end
        return
    end

    local now = GameRules.GetGameTime()
    if now < (cache.next_dp_t or 0) then return end
    cache.next_dp_t = now + 0.1

    local fallback_mode = GetVal(ui_dp_fallback) or 0
    local my_team = Entity.GetTeamNum(my_hero)
    local enemies = VisibleEnemyHeroes(my_team)
    local live_orders = {}
    local no_order = { t = 0 }

    for i = 1, #illusions do
        local illu = illusions[i]
        local idx = Entity.GetIndex(illu)
        local u_pos = Entity.GetAbsOrigin(illu)

        local order_data = last_illu_orders[idx] or no_order
        live_orders[idx] = last_illu_orders[idx]
        local target = GetBestTargetForIllusion(my_team, u_pos, enemies)

        cache.illu_target = target

        if target then
            if (now - order_data.t >= 0.35) or (order_data.target ~= target) then
                IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, target, nil, nil, illu)
                live_orders[idx] = { t = now, target = target }
            end
        else
            if fallback_mode == 0 then
                local dist_to_hero = (Entity.GetAbsOrigin(my_hero) - u_pos):Length2D()
                if dist_to_hero > 350 and (now - order_data.t >= 0.40) then
                    IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET, my_hero, nil, nil, illu)
                    live_orders[idx] = { t = now, target = my_hero }
                end
            elseif fallback_mode == 1 then
                if now - order_data.t >= 0.50 then
                    local forward_pos = u_pos + Vector(400, 0, 0)
                    IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, nil, forward_pos, nil, illu)
                    live_orders[idx] = { t = now }
                end
            end
        end
    end
    last_illu_orders = live_orders
end

-- ============================================================================
-- Built-in Combo Whitelists
-- ============================================================================
local function RefreshWhitelistWidgets(my_hero)
    local now = GameRules.GetGameTime()
    if now < combo.next_list_t then return end
    combo.next_list_t = now + 1

    local my_team = Entity.GetTeamNum(my_hero)
    local names, seen = {}, {}
    local all_heroes = Heroes.GetAll() or {}
    for i = 1, #all_heroes do
        local h = all_heroes[i]
        if h and Entity.GetTeamNum(h) ~= my_team and not NPC.IsIllusion(h) then
            local name = NPC.GetUnitName(h) or ""
            if name:find("^npc_dota_hero_") and not seen[name] then
                seen[name] = true
                table.insert(names, name)
            end
        end
    end
    if #names == 0 then return end
    table.sort(names)

    local key = table.concat(names, ",")
    if key == combo.enemy_key then return end
    combo.enemy_key = key
    combo.enemy_names = names

    combo.updating = true
    if ui_dp_wl then ui_dp_wl:Update(WhitelistItems("dp", names), true, false) end
    if ui_sb_wl then ui_sb_wl:Update(WhitelistItems("sb", names), true, false) end
    combo.updating = false
    if ui_wl_empty then ShowWhitelists(true) end
end

local function GetVisibleEnemies(my_hero)
    local my_team = Entity.GetTeamNum(my_hero)
    local list = {}
    local all_heroes = Heroes.GetAll() or {}
    for i = 1, #all_heroes do
        local h = all_heroes[i]
        if h and Entity.IsAlive(h) and not Entity.IsDormant(h) and Entity.GetTeamNum(h) ~= my_team and not NPC.IsIllusion(h) then
            table.insert(list, h)
        end
    end
    return list
end

local function GetComboTarget(enemies)
    local t = combo.target
    if t and Entity.IsAlive(t) and not Entity.IsDormant(t) then return t end

    local range_w = BuiltinWidget("range")
    local best_dist = range_w and range_w:Get() or 800
    local cursor = Input.GetWorldCursorPos()
    local best = nil
    for i = 1, #enemies do
        local d = (Entity.GetAbsOrigin(enemies[i]) - cursor):Length2D()
        if d <= best_dist then
            best_dist = d
            best = enemies[i]
        end
    end
    combo.target = best
    return best
end

local function TrySoloSoulbind(my_hero, target, enemies)
    local abilities = BuiltinWidget("abilities")
    if abilities and not abilities:Get("grimstroke_soul_chain") then return end

    local talent = NPC.GetAbility(my_hero, SOLO_SOUL_TALENT)
    if not talent or Ability.GetLevel(talent) == 0 then return end

    local soul = NPC.GetAbility(my_hero, "grimstroke_soul_chain")
    if not soul or not IsAbilityReady(my_hero, soul) then return end
    if NPC.IsLinkensProtected(target) then return end

    local target_pos = Entity.GetAbsOrigin(target)
    for i = 1, #enemies do
        local e = enemies[i]
        if e ~= target and (Entity.GetAbsOrigin(e) - target_pos):Length2D() <= SOUL_LATCH_RADIUS then return end
    end

    local cast_range = Ability.GetCastRange(soul) + (NPC.GetCastRangeBonus(my_hero) or 0)
    if (target_pos - Entity.GetAbsOrigin(my_hero)):Length2D() > cast_range + 50 then return end

    local now = GameRules.GetGameTime()
    if now - combo.last_soul_t < 0.3 then return end
    combo.last_soul_t = now
    Ability.CastTarget(soul, target, false, false, true, "GrimHelperSoulbind")
end

local function ProcessComboWhitelists(my_hero)
    local dp_on = GetVal(ui_dp_wl_enabled)
    local sb_on = GetVal(ui_sb_wl_enabled)
    local key_w = BuiltinWidget("key")

    if not panel_active or not (dp_on or sb_on) or not key_w or not key_w:IsDown() then
        combo.target = nil
        RestoreBuiltin()
        return
    end

    local enemies = GetVisibleEnemies(my_hero)
    local target = GetComboTarget(enemies)
    local name = target and NPC.GetUnitName(target)

    if dp_on then
        SetBuiltin("dp", name ~= nil and whitelist.dp[name] == true)
    end

    if sb_on then
        SetBuiltin("solo", false)
        if name and whitelist.sb[name] and not IsHeroDisabled(my_hero) then
            TrySoloSoulbind(my_hero, target, enemies)
        end
    end
end

-- ============================================================================
-- Main Logic Loop
-- ============================================================================
function GrimHelper.OnUpdate()
    SetupMenu()

    if not Engine.IsInGame() or not GetVal(ui_enabled) then
        RestoreBuiltin()
        return
    end

    local my_hero = Heroes.GetLocal()
    if not IsGrimstroke(my_hero) then return end

    local my_player = Players.GetLocal()
    if not my_player then return end

    UpdateThrottledData(my_hero)
    RefreshWhitelistWidgets(my_hero)
    ProcessComboWhitelists(my_hero)

    if not panel_active then return end

    ProcessInkSwell(my_hero, my_player)

    ProcessDarkPortrait(my_hero, my_player)
end

-- ============================================================================
-- On-Screen Panels
-- ============================================================================
local UI_K = {
    W = 248,
    PAD = 10,
    HEAD = 40,
    ICON = 32,
    GAP = 6,
    ROUND = Enum.DrawFlags.RoundCornersAll,
    C_WIN = Color(25, 25, 27, 240),
    C_CARD = Color(34, 34, 37, 255),
    C_OFF = Color(58, 58, 63, 255),
    C_ACCENT = Color(76, 130, 247, 255),
    C_KNOB = Color(200, 200, 205, 255),
    C_WHITE = Color(255, 255, 255, 255),
    C_TEXT = Color(240, 240, 242, 255),
    C_MUTED = Color(150, 154, 160, 255),
    C_GOOD = Color(48, 209, 88, 255),
    C_WARN = Color(255, 159, 10, 255),
    G_CLOSE = "\u{f00d}",
    G_FOLD = "\u{f077}",
    G_UNFOLD = "\u{f078}"
}
UI_K.PER_ROW = math.floor((UI_K.W - UI_K.PAD * 4 + UI_K.GAP) / (UI_K.ICON + UI_K.GAP))
UI_K.ICON_SIZE = Vec2(UI_K.ICON, UI_K.ICON)
UI_K.UV0, UI_K.UV1 = Vec2(0, 0), Vec2(1, 1)

local function Log(text, data)
    if not ai_bridge or not ai_bridge.mcp_log or not GetVal(ui_debug) then return end
    ai_bridge.mcp_log("info", "[Grimstroke Helper] " .. text, data)
end

local function UiFonts()
    if not win.fonts then
        local bold = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, Enum.FontWeight.BOLD)
        local normal = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, Enum.FontWeight.NORMAL)
        win.fonts = { bold = bold or font_bold or font_main, normal = normal or font_main, icon = font_icon }
    end
    return win.fonts
end

local text_sizes = {}

local function TextSize(font, size, text)
    local key = font .. ":" .. size .. ":" .. text
    local ts = text_sizes[key]
    if not ts then
        ts = Render.TextSize(font, size, text)
        text_sizes[key] = ts
    end
    return ts
end

local function Fade(c, a)
    if a >= 0.999 then return c end
    return Color(c.r, c.g, c.b, math.floor(c.a * a))
end

local function Mix(c1, c2, k)
    if k <= 0.001 then return c1 end
    if k >= 0.999 then return c2 end
    return Color(
        math.floor(c1.r + (c2.r - c1.r) * k),
        math.floor(c1.g + (c2.g - c1.g) * k),
        math.floor(c1.b + (c2.b - c1.b) * k),
        math.floor(c1.a + (c2.a - c1.a) * k))
end

local function Approach(cur, target, speed)
    if math.abs(target - cur) < 0.002 then return target end
    return cur + (target - cur) * (1 - math.exp(-win.dt * speed))
end

local function SetHot(x, y, w, h, kind, arg_a, arg_b)
    if Input.IsCursorInRect(x, y, w, h) then
        win.hot_kind, win.hot_a, win.hot_b = kind, arg_a, arg_b
        return true
    end
    return false
end

local function DrawSwitch(x, cy, on, a, id)
    local k = Approach(win.anim[id] or (on and 1 or 0), on and 1 or 0, 18)
    win.anim[id] = k
    Render.FilledRect(Vec2(x, cy - 10), Vec2(x + 34, cy + 10), Fade(Mix(UI_K.C_OFF, UI_K.C_ACCENT, k), a), 10, UI_K.ROUND)
    Render.FilledCircle(Vec2(x + 10 + 14 * k, cy), 8, Fade(Mix(UI_K.C_KNOB, UI_K.C_WHITE, k), a))
end

local function DrawGlyphButton(cx, cy, glyph, a, kind, arg)
    local f = UiFonts()
    if not f.icon then return end
    local hover = SetHot(cx - 12, cy - 12, 24, 24, kind, arg)
    if hover then Render.FilledCircle(Vec2(cx, cy), 11, Color(255, 255, 255, math.floor(20 * a))) end
    local gs = TextSize(f.icon, 12, glyph)
    Render.Text(f.icon, 12, glyph, Vec2(cx - gs.x / 2, cy - gs.y / 2), Fade(hover and UI_K.C_TEXT or UI_K.C_MUTED, a))
end

local function DrawShadow(x, y, w, h, a)
    for i = 1, 4 do
        local e = i * 3
        Render.FilledRect(Vec2(x - e, y - e + 4), Vec2(x + w + e, y + h + e + 4),
            Color(0, 0, 0, math.floor(18 * (1 - (i - 1) / 4) * a)), 14 + e, UI_K.ROUND)
    end
end

local function DrawWindowBase(w, h, title, a)
    local tl, br = Vec2(w.x, w.y), Vec2(w.x + UI_K.W, w.y + h)
    DrawShadow(w.x, w.y, UI_K.W, h, a)
    Render.Blur(tl, br, a, 1.0, 14, UI_K.ROUND)
    Render.FilledRect(tl, br, Fade(UI_K.C_WIN, a), 14, UI_K.ROUND)
    local folded = h <= UI_K.HEAD + 1
    Render.FilledRect(tl, Vec2(w.x + UI_K.W, w.y + math.min(h, UI_K.HEAD)), Fade(UI_K.C_ACCENT, a * 0.10), 14,
        folded and UI_K.ROUND or Enum.DrawFlags.RoundCornersTop)
    local f = UiFonts()
    local ts = TextSize(f.bold, 14, title)
    Render.Text(f.bold, 14, title, Vec2(w.x + 14, w.y + (UI_K.HEAD - ts.y) / 2), Fade(UI_K.C_TEXT, a))
    SetHot(w.x, w.y, UI_K.W, h, "body")
    SetHot(w.x, w.y, UI_K.W, UI_K.HEAD, "drag", w)
end

local function DrawCard(x, y, h, a)
    Render.FilledRect(Vec2(x, y), Vec2(x + UI_K.W - UI_K.PAD * 2, y + h), Fade(UI_K.C_CARD, a), 10, UI_K.ROUND)
end

local function IconRowHeight(count)
    local rows = math.max(1, math.ceil(count / UI_K.PER_ROW))
    return rows * (UI_K.ICON + UI_K.GAP) - UI_K.GAP
end

local function ListCardHeight(row_h)
    return UI_K.PAD + 28 + row_h + UI_K.PAD
end

local function DrawIcon(name, ix, iy, on, lit, a, kind, list)
    local hover = SetHot(ix, iy, UI_K.ICON, UI_K.ICON, kind, name, list)
    local pos = Vec2(ix, iy)
    local icon = HeroIcon(name)
    local alpha = math.floor((on and 255 or (hover and 170 or 110)) * a)
    if icon then
        Render.Image(icon, pos, UI_K.ICON_SIZE, Color(255, 255, 255, alpha), 8, UI_K.ROUND, UI_K.UV0, UI_K.UV1, on and 0 or 1)
    else
        Render.FilledRect(pos, pos + UI_K.ICON_SIZE, Fade(UI_K.C_OFF, alpha / 255), 8, UI_K.ROUND)
    end
    if on then
        Render.Rect(pos, pos + UI_K.ICON_SIZE, Fade(UI_K.C_ACCENT, a), 8, UI_K.ROUND, 1.5)
        if lit then Render.FilledCircle(Vec2(ix + UI_K.ICON - 4, iy + 4), 3.5, Fade(UI_K.C_GOOD, a)) end
    elseif hover then
        Render.Rect(pos, pos + UI_K.ICON_SIZE, Color(255, 255, 255, math.floor(60 * a)), 8, UI_K.ROUND, 1)
    end
end

local function IconPos(x, y, i)
    local col = (i - 1) % UI_K.PER_ROW
    local row = (i - 1) // UI_K.PER_ROW
    return x + col * (UI_K.ICON + UI_K.GAP), y + row * (UI_K.ICON + UI_K.GAP)
end

local function DrawSectionHead(x, cy, title, a)
    local f = UiFonts()
    Render.FilledRect(Vec2(x, cy - 7), Vec2(x + 3, cy + 7), Fade(UI_K.C_ACCENT, a), 1.5, UI_K.ROUND)
    local ts = TextSize(f.bold, 12, title)
    Render.Text(f.bold, 12, title, Vec2(x + 10, cy - ts.y / 2), Fade(UI_K.C_TEXT, a))
    return ts.x
end

local function DrawBadge(right, cy, text, a)
    local f = UiFonts()
    local bs = TextSize(f.bold, 10, text)
    local bw = bs.x + 12
    Render.FilledRect(Vec2(right - bw, cy - 8), Vec2(right, cy + 8), Fade(UI_K.C_ACCENT, a * 0.18), 8, UI_K.ROUND)
    Render.Text(f.bold, 10, text, Vec2(right - bw + 6, cy - bs.y / 2), Fade(UI_K.C_ACCENT, a))
end

local function RefreshPanelData()
    local now = os.clock()
    if now < (win.next_data_t or 0) then return end
    win.next_data_t = now + 0.1

    if win.allies_src ~= cache.allies then
        win.allies_src = cache.allies
        win.ally_names = {}
        for i, node in ipairs(cache.allies) do win.ally_names[i] = node.name end
    end
    win.ally_count = string.format("%d / %d", cache.allowed_count, #cache.allies)

    if not panel_active then
        win.dp_text, win.dp_col = L("gh_hud_paused"), UI_K.C_WARN
    elseif #cache.illusions == 0 then
        win.dp_text, win.dp_col = L("gh_hud_none"), UI_K.C_MUTED
    elseif cache.illu_target and Entity.IsAlive(cache.illu_target) then
        local t_name = HeroDisplayName(NPC.GetUnitName(cache.illu_target))
        win.dp_text, win.dp_col = string.format(L("gh_hud_focus"), t_name, Entity.GetHealth(cache.illu_target)), UI_K.C_TEXT
    else
        win.dp_text, win.dp_col = L("gh_hud_follow"), UI_K.C_TEXT
    end
end

local function DrawMainPanel(a)
    local w = win.main
    local allies = cache.allies
    local names = win.ally_names or {}
    local row_h = IconRowHeight(#names)
    local card_h = ListCardHeight(row_h)
    local body_h = card_h + 8 + 40 + UI_K.PAD
    w.fold = Approach(w.fold or 1, w.collapsed and 0 or 1, 16)
    local h = UI_K.HEAD + math.floor(body_h * w.fold)
    local cx = w.x + UI_K.PAD
    local x = cx + UI_K.PAD
    local right = w.x + UI_K.W - 18

    DrawWindowBase(w, h, "Grimstroke Helper", a)
    DrawGlyphButton(right, w.y + UI_K.HEAD / 2, UI_K.G_CLOSE, a, "close_main")
    DrawGlyphButton(right - 26, w.y + UI_K.HEAD / 2, w.collapsed and UI_K.G_UNFOLD or UI_K.G_FOLD, a, "fold")
    local sw_x = right - 26 - 14 - 40
    DrawSwitch(sw_x, w.y + UI_K.HEAD / 2, panel_active, a, "pause")
    SetHot(sw_x - 4, w.y + UI_K.HEAD / 2 - 14, 42, 28, "pause")

    if w.fold < 0.02 then return end
    local ba = a * w.fold
    Render.PushClip(Vec2(w.x, w.y + UI_K.HEAD), Vec2(w.x + UI_K.W, w.y + h), true)

    local y = w.y + UI_K.HEAD
    DrawCard(cx, y, card_h, ba)
    DrawSectionHead(x, y + UI_K.PAD + 10, L("gh_hud_ink"), ba)
    DrawBadge(w.x + UI_K.W - UI_K.PAD * 2, y + UI_K.PAD + 10, win.ally_count or "", ba)
    local max_dist = GetVal(ui_ink_max_dist) or 650
    local iy0 = y + UI_K.PAD + 28
    for i, node in ipairs(allies) do
        local ix, iy = IconPos(x, iy0, i)
        DrawIcon(node.name, ix, iy, allowed_allies[node.name] == true, node.enemy_dist <= max_dist, ba, "ally")
    end
    y = y + card_h + 8

    DrawCard(cx, y, 40, ba)
    local label_w = DrawSectionHead(x, y + 20, L("gh_hud_dp"), ba)
    local f = UiFonts()
    local status = win.dp_text or ""
    local ss = TextSize(f.normal, 11, status)
    local sx = math.max(x + 10 + label_w + 12, w.x + UI_K.W - UI_K.PAD * 2 - ss.x)
    Render.PushClip(Vec2(x, y), Vec2(w.x + UI_K.W - UI_K.PAD * 2, y + 40), true)
    Render.Text(f.normal, 11, status, Vec2(sx, y + 20 - ss.y / 2), Fade(win.dp_col or UI_K.C_MUTED, ba))
    Render.PopClip()

    Render.PopClip()
end

local function DrawFilterCard(cx, y, title, kind, switch_w, names, list_h, a)
    local x = cx + UI_K.PAD
    local card_h = ListCardHeight(list_h)
    local on = GetVal(switch_w)
    local cy = y + UI_K.PAD + 10
    local sw_x = cx + UI_K.W - UI_K.PAD * 3 - 34
    DrawCard(cx, y, card_h, a)
    DrawSectionHead(x, cy, title, a)
    DrawSwitch(sw_x, cy, on, a, kind)
    SetHot(sw_x - 4, cy - 14, 42, 28, "wl_switch", kind)
    local iy0 = y + UI_K.PAD + 28
    if #names == 0 then
        Render.Text(UiFonts().normal, 11, L("gh_wl_empty"), Vec2(x, iy0), Fade(UI_K.C_MUTED, a))
    else
        local list = whitelist[kind]
        local ia = on and a or a * 0.6
        for i, name in ipairs(names) do
            local ix, iy = IconPos(x, iy0, i)
            DrawIcon(name, ix, iy, list[name] == true, false, ia, "wl", kind)
        end
    end
    return y + card_h
end

local function DrawFiltersWindow(a)
    local w = win.filters
    local names = combo.enemy_names or {}
    local list_h = #names == 0 and 16 or IconRowHeight(#names)
    local h = UI_K.HEAD + ListCardHeight(list_h) * 2 + 8 + UI_K.PAD
    local cx = w.x + UI_K.PAD

    DrawWindowBase(w, h, L("gh_hud_filters"), a)
    DrawGlyphButton(w.x + UI_K.W - 18, w.y + UI_K.HEAD / 2, UI_K.G_CLOSE, a, "close_filters")

    local y = w.y + UI_K.HEAD
    y = DrawFilterCard(cx, y, L("gh_hud_dp"), "dp", ui_dp_wl_enabled, names, list_h, a)
    DrawFilterCard(cx, y + 8, L("gh_hud_sb"), "sb", ui_sb_wl_enabled, names, list_h, a)
end

local function SetWhitelist(kind, name, value)
    whitelist[kind][name] = value
    local list = kind == "dp" and ui_dp_wl or ui_sb_wl
    if list then
        combo.updating = true
        list:Set(name, value)
        combo.updating = false
    end
    SaveWhitelist()
end

local function Click(kind, arg_a, arg_b)
    if kind == "pause" then
        panel_active = not panel_active
        Log("click: pause", { active = panel_active })
    elseif kind == "fold" then
        win.main.collapsed = not win.main.collapsed
        Log("click: fold", { collapsed = win.main.collapsed })
    elseif kind == "close_main" then
        ui_draw_panel:Set(false)
        Log("click: close panel")
    elseif kind == "close_filters" then
        win.filters.open = false
        Log("click: close filters")
    elseif kind == "ally" then
        allowed_allies[arg_a] = not allowed_allies[arg_a]
        Log("click: ally", { hero = arg_a, allowed = allowed_allies[arg_a] })
    elseif kind == "wl" then
        SetWhitelist(arg_b, arg_a, not whitelist[arg_b][arg_a])
        Log("click: filter hero", { list = arg_b, hero = arg_a, on = whitelist[arg_b][arg_a] })
    elseif kind == "wl_switch" then
        local sw = arg_a == "dp" and ui_dp_wl_enabled or ui_sb_wl_enabled
        sw:Set(not sw:Get())
        RefreshDisabled()
        Log("click: filter switch", { list = arg_a, on = sw:Get() })
    elseif kind == "drag" then
        local cx, cy = Input.GetCursorPos()
        win.drag = { win = arg_a, dx = cx - arg_a.x, dy = cy - arg_a.y }
    end
end

local function HandleKeys()
    if Input.IsInputCaptured() then return end
    if ui_panel_key:IsPressed() then
        ui_draw_panel:Set(not ui_draw_panel:Get())
        Log("key: panel", { shown = ui_draw_panel:Get() })
    end
    if ui_filters_key:IsPressed() then
        win.filters.open = not win.filters.open
        Log("key: filters", { open = win.filters.open })
    end
end

function GrimHelper.OnDraw()
    win.hot_kind = nil
    if not Engine.IsInGame() or not GetVal(ui_enabled) or not IsGrimstroke(Heroes.GetLocal()) then
        win.main.alpha, win.filters.alpha, win.drag = 0, 0, nil
        return
    end

    HandleKeys()
    win.dt = math.min(0.1, GlobalVars.GetAbsFrameTime() or 0.016)
    win.anim = win.anim or {}

    if win.drag then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
            local cx, cy = Input.GetCursorPos()
            win.drag.win.x, win.drag.win.y = cx - win.drag.dx, cy - win.drag.dy
        else
            win.drag = nil
        end
    end

    win.main.alpha = Approach(win.main.alpha, GetVal(ui_draw_panel) and 1 or 0, 20)
    win.filters.alpha = Approach(win.filters.alpha, win.filters.open and 1 or 0, 20)

    if win.main.alpha > 0.02 then
        RefreshPanelData()
        DrawMainPanel(win.main.alpha)
    end
    if win.filters.alpha > 0.02 then DrawFiltersWindow(win.filters.alpha) end
    if win.main.alpha < 0.5 and win.filters.alpha < 0.5 then win.hot_kind = nil end
end

function GrimHelper.OnKeyEvent(data)
    if data.key ~= Enum.ButtonCode.KEY_MOUSE1 then return true end
    if data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
        if win.hot_kind and not Input.IsInputCaptured() then
            Click(win.hot_kind, win.hot_a, win.hot_b)
            win.swallow = true
            return false
        end
    elseif data.event == Enum.EKeyEvent.EKeyEvent_KEY_UP and win.swallow then
        win.swallow = false
        return false
    end
    return true
end

-- ============================================================================
-- Initialization
-- ============================================================================
SetupMenu()

return GrimHelper