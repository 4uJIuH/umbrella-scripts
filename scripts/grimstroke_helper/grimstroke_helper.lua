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
        gh_panel = "Helper Window",
        gh_panel_tip = "On-screen window: ally icons for Ink Swell and combo filters.\nDrag it to a screen edge to dock it there.",
        gh_ink_enable = "Auto Ink Swell",
        gh_ink_enable_tip = "Casts Ink Swell on an ally standing next to enemies.",
        gh_ink_mode = "Ally Choice",
        gh_ink_mode_tip = "Allies are allowed or forbidden in the on-screen panel.",
        gh_ink_modes_closest = "Any ally near enemies",
        gh_ink_modes_whitelist = "Allowed ally closest to enemies",
        gh_ink_modes_whitelist_range = "Allowed ally near enemies",
        gh_ink_dist = "Ally to Enemy Distance",
        gh_ink_dist_tip = "An ally farther than this from every enemy is skipped.",
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
        gh_dp_wl_tip = "Built-in combo casts Dark Portrait only on checked enemies\nor on enemies Soulbound to a checked one.",
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
        gh_filters_key_tip = "Opens the window on the filters page.\nPress again to close it.",
        gh_filters_key_name = "Grimstroke: filters",
        gh_size = "Window Size",
        gh_size_tip = "Scale of the on-screen window.",
        gh_title = "Grimstroke Helper",
        gh_hint_filters = "Combo filters",
        gh_hint_pause = "Pause automation",
        gh_hint_resume = "Resume automation",
        gh_no_allies = "Allies appear here in a match",
        gh_hud_ink = "Ink Swell Targets",
        gh_hud_you = " (You)",
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
        gh_panel = "Окно помощника",
        gh_panel_tip = "Окно на экране: союзники для Ink Swell и фильтры комбо.\nПеретащите к краю экрана, чтобы прикрепить.",
        gh_ink_enable = "Авто Ink Swell",
        gh_ink_enable_tip = "Кастует Ink Swell на союзника рядом с врагами.",
        gh_ink_mode = "Выбор союзника",
        gh_ink_mode_tip = "Разрешенные союзники отмечаются в панели на экране.",
        gh_ink_modes_closest = "Любой рядом с врагами",
        gh_ink_modes_whitelist = "Разрешенный, ближайший к врагам",
        gh_ink_modes_whitelist_range = "Разрешенный рядом с врагами",
        gh_ink_dist = "Дистанция до врага",
        gh_ink_dist_tip = "Союзник дальше этого от всех врагов пропускается.",
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
        gh_dp_wl_tip = "Встроенное комбо кастует Dark Portrait только на отмеченных врагов\nи на врагов, связанных с ними Soulbind.",
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
        gh_filters_key_tip = "Открывает окно на странице фильтров.\nПовторное нажатие закрывает его.",
        gh_filters_key_name = "Grimstroke: фильтры",
        gh_size = "Размер окна",
        gh_size_tip = "Масштаб окна на экране.",
        gh_title = "Grimstroke Helper",
        gh_hint_filters = "Фильтры комбо",
        gh_hint_pause = "Пауза автоматики",
        gh_hint_resume = "Включить автоматику",
        gh_no_allies = "Союзники появятся здесь в матче",
        gh_hud_ink = "Цели Ink Swell",
        gh_hud_you = " (вы)",
        gh_hud_none = "Иллюзии нет",
        gh_hud_paused = "Автоматика на паузе",
        gh_hud_focus = "Цель: %s (%.0f HP)",
        gh_hud_follow = "Иллюзия идет за вами",
    },
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

--by m0rc1

local VERSION = "1.4.1"
local GrimHelper = {}

-- ============================================================================
-- Menu Variables
-- ============================================================================
local ui_enabled            = nil
local ui_draw_panel         = nil
local ui_scale              = nil

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

local function RestoreBuiltin(only)
    local changed = false
    for key, original in pairs(combo.saved) do
        if not only or key == only then
            local w, current = GetBuiltin(key)
            if w and current ~= original then WriteBuiltin(key, w, original) end
            combo.saved[key] = nil
            changed = true
        end
    end
    if changed then SaveWhitelist() end
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
    ui_scale:Disabled(not on)
    ui_panel_key:Disabled(not on)
    ui_filters_key:Disabled(not on)
    ui_ink_enabled:Disabled(not on)
    ui_ink_mode:Disabled(not ink_on)
    ui_ink_max_dist:Disabled(not ink_on)
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
    ui_scale = g_extra:Slider("gh_size", 70, 150, 100, "%d%%")
    ui_scale:Icon("\u{f065}")
    ui_scale:ToolTip("gh_size_tip")
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
                if node.enemy_dist <= max_enemy_dist and node.enemy_dist < best_enemy_dist then
                    best_enemy_dist = node.enemy_dist
                    best_target = node.ent
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
        if not Entity.IsEntity(illu) or not Entity.IsAlive(illu) then goto continue end
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
        ::continue::
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

local function CursorTarget(enemies)
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
    return best
end

local function GetComboTarget(enemies)
    local t = combo.target
    if t and Entity.IsEntity(t) and Entity.IsAlive(t) and not Entity.IsDormant(t) then return t end
    combo.target = CursorTarget(enemies)
    return combo.target
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

local function DarkPortraitAllowed(target, enemies)
    if whitelist.dp[NPC.GetUnitName(target) or ""] then return true end
    if not NPC.HasModifier(target, "modifier_grimstroke_soul_chain") then return false end
    for i = 1, #enemies do
        local e = enemies[i]
        if e ~= target and NPC.HasModifier(e, "modifier_grimstroke_soul_chain") and whitelist.dp[NPC.GetUnitName(e) or ""] then
            return true
        end
    end
    return false
end

local function ProcessComboWhitelists(my_hero)
    local dp_on = panel_active and GetVal(ui_dp_wl_enabled)
    local sb_on = panel_active and GetVal(ui_sb_wl_enabled)
    if not dp_on then RestoreBuiltin("dp") end
    if not sb_on then RestoreBuiltin("solo") end

    local key_w = BuiltinWidget("key")
    if not (dp_on or sb_on) or not key_w or not key_w:IsDown() then
        combo.target = nil
        if dp_on then SetBuiltin("dp", false) end
        if sb_on then SetBuiltin("solo", false) end
        return
    end

    local enemies = GetVisibleEnemies(my_hero)
    local target = GetComboTarget(enemies)
    local name = target and NPC.GetUnitName(target)

    if dp_on then
        local hovered = CursorTarget(enemies)
        SetBuiltin("dp", target ~= nil and DarkPortraitAllowed(target, enemies)
            and (hovered == nil or hovered == target or DarkPortraitAllowed(hovered, enemies)))
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
-- UI Kit (umbrella-ui)
-- ============================================================================

local K = {
    NAME = "Grimstroke Helper",
    CFG = "grimstroke_helper_ui",
    W = 260,
    HEAD = 22,
    PAD = 10,
    EVERYWHERE = false,
    SMALL = true,
    DOCK = true,
    SNAP = 24,
    THEME = "umbrella",
    ACCENT = "umbrella",
    SINK_ID = "GrimstrokeHelperInput",
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
    local f = asset.fonts[weight]
    if not f then
        f = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, weight)
        asset.fonts[weight] = f
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
    local key = weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. g.s .. ":" .. str
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
    local key = weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. g.s .. ":" .. str
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
        local c = kind == "accent" and A or C.menu
        g.rect(x, y, w, h, c, 4)
        if hv > 0.01 then g.rect(x, y, w, h, T.white, 4, 0.05 * hv) end
        g.text(500, 12.5, label, x + w / 2, y + h / 2, kind == "accent" and T.white or anim.mix(T.t3, T.t1, hv), 1, "c")
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

function view.dock(on)
    if on == nil then on = not P.set.docked end
    P.set.docked = on and view.edge() ~= nil
    save("docked", P.set.docked)
    if P.set.docked then
        P.menu = nil
        edit.blur()
    end
end

function view.dock_tab(o, edge, d)
    local tw, th = 20 + (o.tab_w or 0), 22
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
    local cc = U.flat and T.t4 or T.t3
    g.glyph(edge > 0 and K.G.left or K.G.right, 10, cx, th / 2, anim.mix(cc, T.t1, anim.hover("btn_undock")))
    hit.add(cx - 10, 0, 20, th, "btn_undock", { click = function() view.dock(false) end })
    if o.tab then o.tab(edge > 0 and (U.flat and 22 or 20) or 6, th / 2) end
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
    local x = 6
    if o.switch then
        view.switch(x, H / 2, o.switch.on, o.switch.id or "head_sw", o.switch.click, true)
        x = x + 26
    end
    for _, b in ipairs(o.buttons or {}) do
        view.icon_button(x, by, bs, b.glyph, b.id, b.active, b.click)
        x = x + bs + 2
    end
    local rx = W - 6 - bs
    local glyph = edge and (edge > 0 and K.G.right or K.G.left) or (P.set.collapsed and K.G.down or K.G.left)
    view.icon_button(rx, by, bs, glyph, "btn_head", true, edge and function() view.dock(true) end or view.fold)
    local room = 2 * math.min(W / 2 - x - 4, rx - W / 2 - 4)
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

-- ============================================================================
-- Helper Window
-- ============================================================================
P.set.opacity = 100

local GW = {
    filters = Config.ReadInt(K.CFG, "tab", 1) == 2,
    body_h = 120,
    next_data_t = 0,
    allies = {},
    dp_text = "",
    dp_col = T.t3
}

local function BridgeLog(text, data)
    if not ai_bridge or not ai_bridge.mcp_log or not GetVal(ui_debug) then return end
    ai_bridge.mcp_log("info", "[Grimstroke Helper] " .. text, data)
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

local function RefreshWindowData()
    if P.now < GW.next_data_t then return end
    GW.next_data_t = P.now + 0.1

    local max_dist = GetVal(ui_ink_max_dist) or 650
    local allies = {}
    for i, node in ipairs(cache.allies) do
        allies[i] = {
            key = node.name,
            img = asset.hero(node.name),
            label = HeroDisplayName(node.name),
            on = allowed_allies[node.name] == true,
            dot = (allowed_allies[node.name] and node.enemy_dist <= max_dist) and T.green or nil
        }
    end
    GW.allies = allies

    if not panel_active then
        GW.dp_text, GW.dp_col = L("gh_hud_paused"), T.yellow
    elseif #cache.illusions == 0 then
        GW.dp_text, GW.dp_col = L("gh_hud_none"), T.t4
    elseif cache.illu_target and Entity.IsEntity(cache.illu_target) and Entity.IsAlive(cache.illu_target) then
        local t_name = HeroDisplayName(NPC.GetUnitName(cache.illu_target))
        GW.dp_text, GW.dp_col = string.format(L("gh_hud_focus"), t_name, Entity.GetHealth(cache.illu_target)), AT
    else
        GW.dp_text, GW.dp_col = L("gh_hud_follow"), T.t2
    end
end

local function EnemyItems(kind)
    local items = {}
    for i, name in ipairs(combo.enemy_names or {}) do
        items[i] = { key = name, img = asset.hero(name), label = HeroDisplayName(name), on = whitelist[kind][name] == true }
    end
    return items
end

local function Grid(x, y, w, items, id, dim, empty, click)
    if #items == 0 then
        view.status(x, y + 10, w, K.G.info, empty, T.t4)
        return 20
    end
    local base = g.a
    if dim then g.a = base * 0.45 end
    local h = view.grid(x, y, w, items, 30, 6, id, click)
    g.a = base
    return h
end

local function BodyInk(y)
    local x, w = K.PAD, K.W - K.PAD * 2
    local top = y
    local items = GW.allies
    local whitelist_on = GetVal(ui_ink_enabled) and GetVal(ui_ink_mode) ~= 0
    y = y + view.caption(x, y, w, L("gh_hud_ink"), #items > 0 and string.format("%d/%d", cache.allowed_count, #items) or nil)
    y = y + Grid(x, y, w, items, "ally", not whitelist_on, L("gh_no_allies"), function(it)
        allowed_allies[it.key] = not allowed_allies[it.key]
        GW.next_data_t = 0
        BridgeLog("click: ally", { hero = it.key, allowed = allowed_allies[it.key] })
    end) + 12
    view.status(x, y + 8, w, "\u{f6e2}", GW.dp_text, GW.dp_col)
    return y + 16 - top
end

local function FilterRows(x, y, w, kind, label, switch_w)
    local top = y
    local on = GetVal(switch_w)
    y = y + view.toggle_row(x - 10, y, w + 20, label, on, "wl_sw:" .. kind, function()
        switch_w:Set(not switch_w:Get())
        RefreshDisabled()
        BridgeLog("click: filter switch", { list = kind, on = switch_w:Get() })
    end)
    y = y + Grid(x, y + 6, w, EnemyItems(kind), "wl:" .. kind, not on, L("gh_wl_empty"), function(it)
        SetWhitelist(kind, it.key, not whitelist[kind][it.key])
        BridgeLog("click: filter hero", { list = kind, hero = it.key, on = whitelist[kind][it.key] })
    end) + 6
    return y - top
end

local function BodyFilters(y)
    local x, w = K.PAD, K.W - K.PAD * 2
    local top = y
    y = y + FilterRows(x, y, w, "dp", L("gh_dp_wl"), ui_dp_wl_enabled) + 6
    y = y + FilterRows(x, y, w, "sb", L("gh_sb_wl"), ui_sb_wl_enabled)
    return y - top
end

local function SetFilters(on)
    if GW.filters == on then return end
    GW.filters = on
    save("tab", on and 2 or 1)
    BridgeLog("click: filters", { on = on })
end

local function TogglePause()
    panel_active = not panel_active
    GW.next_data_t = 0
    BridgeLog("click: pause", { active = panel_active })
end

local function DrawHelperWindow()
    RefreshWindowData()
    P.set.scale = GetVal(ui_scale) or 100
    view.window({
        title = L("gh_title"),
        body_h = anim.tween("gh_body_h", GW.body_h, 0.2),
        switch = { on = panel_active, id = "head_sw", click = TogglePause },
        buttons = {
            { glyph = "\u{f0b0}", id = "btn_filters", active = GW.filters, click = function() SetFilters(not GW.filters) end },
        },
        tab_w = 28,
        tab = function(x, cy) view.switch(x, cy, panel_active, "tab_on", TogglePause, true) end,
        body = function(y)
            local top = y
            y = y + 10
            y = y + (GW.filters and BodyFilters or BodyInk)(y)
            GW.body_h = y - top + K.PAD
        end
    })
    view.hint("btn_filters", L("gh_hint_filters"))
    view.hint("head_sw", L(panel_active and "gh_hint_pause" or "gh_hint_resume"))
end

local function HandleKeys()
    if Input.IsInputCaptured() then return end
    if ui_panel_key:IsPressed() then
        ui_draw_panel:Set(not ui_draw_panel:Get())
        BridgeLog("key: panel", { shown = ui_draw_panel:Get() })
    end
    if ui_filters_key:IsPressed() then
        if ui_draw_panel:Get() and GW.filters then
            ui_draw_panel:Set(false)
        else
            ui_draw_panel:Set(true)
            SetFilters(true)
            if P.set.docked then view.dock(false) end
        end
        BridgeLog("key: filters", { shown = ui_draw_panel:Get(), filters = GW.filters })
    end
end

K.DEBUG = function() return GetVal(ui_debug) end
K.ON_CLOSE = function()
    ui_draw_panel:Set(false)
    BridgeLog("click: close panel")
end

function GrimHelper.OnDraw()
    if not Engine.IsInGame() or not GetVal(ui_enabled) or not IsGrimstroke(Heroes.GetLocal()) then
        if P.alpha > 0 then
            P.alpha, P.open = 0, false
            hit.list = {}
            edit.blur()
            input.end_drag()
        end
        return
    end
    HandleKeys()
    P.open = GetVal(ui_draw_panel)
    input.frame(DrawHelperWindow)
end

function GrimHelper.OnKeyEvent(data)
    if not GetVal(ui_enabled) then return true end
    return input.event(data)
end

-- ============================================================================
-- Initialization
-- ============================================================================
SetupMenu()

return GrimHelper