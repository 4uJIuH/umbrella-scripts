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
        gh_panel_tip = "On-screen panel: click an ally to allow or forbid Ink Swell on them.\nThe header button pauses the helper.",
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
    },
    ru = {
        gh_group_main = "Grimstroke Helper",
        gh_group_ink = "Ink Swell",
        gh_group_dp = "Иллюзия Dark Portrait",
        gh_group_combo = "Встроенное комбо",
        gh_enable = "Включить",
        gh_enable_tip = "Включает все функции помощника.",
        gh_panel = "Панель союзников",
        gh_panel_tip = "Панель на экране: клик по союзнику разрешает или запрещает Ink Swell на него.\nКнопка в заголовке ставит помощника на паузу.",
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
        gh_dp_wl = "Белый список Dark Portrait",
        gh_dp_wl_tip = "Пока зажата клавиша комбо, встроенное комбо кастует Dark Portrait только на отмеченных врагов.\nОстальные способности работают как обычно.",
        gh_dp_list = "Цели Dark Portrait",
        gh_sb_wl = "Белый список Soulbind в одиночку",
        gh_sb_wl_tip = "С талантом 15 уровня комбо связывает отмеченного врага, даже если он один.\nОстальным врагам по-прежнему нужен второй враг рядом.",
        gh_sb_list = "Цели Soulbind в одиночку",
    },
})

local UI = localization.WrapLibrary(Menu)

--by m0rc1

local VERSION = "1.2.0"
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
local hud_panel = {
    x = 40,
    y = 160,
    w = 260,
    header_h = 24,
    collapsed = false,
    anim_progress = 1.0,
    dragging = false,
    drag_off = Vec2(0, 0),
    last_click = 0
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

local function SetupMenu()
    if ui_enabled ~= nil then return end

    local page = UI.Create("Heroes", "Hero List", "Grimstroke", "Helper")
    local g_main = page:Create("gh_group_main", Enum.GroupSide.Left)
    local g_ink = page:Create("gh_group_ink", Enum.GroupSide.Left)
    local g_dp = page:Create("gh_group_dp", Enum.GroupSide.Right)
    local g_combo = page:Create("gh_group_combo", Enum.GroupSide.Right)

    ui_enabled = g_main:Switch("gh_enable", true, "\u{f011}")
    ui_enabled:ToolTip("gh_enable_tip")
    ui_draw_panel = g_main:Switch("gh_panel", true, "\u{f05a}")
    ui_draw_panel:ToolTip("gh_panel_tip")

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
    ui_dp_wl = g_combo:MultiSelect("gh_dp_list", WhitelistItems("dp", {}), true)
    ui_dp_wl:Icon("\u{f05b}")
    ui_sb_wl_enabled = g_combo:Switch("gh_sb_wl", false, "\u{f0c1}")
    ui_sb_wl_enabled:ToolTip("gh_sb_wl_tip")
    ui_sb_wl = g_combo:MultiSelect("gh_sb_list", WhitelistItems("sb", {}), true)
    ui_sb_wl:Icon("\u{f05b}")

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

local function GetThemeColor(name, fallback)
    if Menu and Menu.Style then
        local ok, col = pcall(Menu.Style, name)
        if ok and col and col.r then return col end
    end
    return fallback
end

local function GetAccentColor(alpha)
    local col = GetThemeColor("primary", Color(0, 255, 128, 255))
    return Color(col.r, col.g, col.b, alpha or 255)
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

                        local display = name:gsub("npc_dota_hero_", ""):gsub("_", " ")
                        display = display:sub(1, 1):upper() .. display:sub(2)
                        if h == my_hero then display = display .. " (You)" end

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
    if now - last_ink_cast_time < 0.22 then return end

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
local function GetBestTargetForIllusion(my_hero, illu_pos)
    local my_team = Entity.GetTeamNum(my_hero)
    local target_mode = GetVal(ui_dp_target_mode) or 0
    local heroes_only = GetVal(ui_dp_heroes_only)

    local visible_enemy_heroes = {}
    local all_heroes = Heroes.GetAll() or {}

    for i = 1, #all_heroes do
        local e = all_heroes[i]
        if e and Entity.IsAlive(e) and not Entity.IsDormant(e) and Entity.GetTeamNum(e) ~= my_team then
            if not (NPC.IsIllusion and NPC.IsIllusion(e)) then
                table.insert(visible_enemy_heroes, e)
            end
        end
    end

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
        return
    end

    local now = GameRules.GetGameTime()
    local fallback_mode = GetVal(ui_dp_fallback) or 0

    for i = 1, #illusions do
        local illu = illusions[i]
        local idx = Entity.GetIndex(illu)
        local u_pos = Entity.GetAbsOrigin(illu)

        local order_data = last_illu_orders[idx] or { t = 0, target = nil, order = -1 }
        local target = GetBestTargetForIllusion(my_hero, u_pos)

        cache.illu_target = target

        if target then
            if (now - order_data.t >= 0.35) or (order_data.target ~= target) then
                IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, target, nil, nil, illu)
                last_illu_orders[idx] = { t = now, target = target, order = Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET }
            end
        else
            if fallback_mode == 0 then
                local dist_to_hero = (Entity.GetAbsOrigin(my_hero) - u_pos):Length2D()
                if dist_to_hero > 350 and (now - order_data.t >= 0.40) then
                    IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET, my_hero, nil, nil, illu)
                    last_illu_orders[idx] = { t = now, target = my_hero, order = Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET }
                end
            elseif fallback_mode == 1 then
                if now - order_data.t >= 0.50 then
                    local forward_pos = u_pos + Vector(400, 0, 0)
                    IssueOrder(my_player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, nil, forward_pos, nil, illu)
                    last_illu_orders[idx] = { t = now, target = nil, order = Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE }
                end
            end
        end
    end
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

    combo.updating = true
    if ui_dp_wl then ui_dp_wl:Update(WhitelistItems("dp", names), true, false) end
    if ui_sb_wl then ui_sb_wl:Update(WhitelistItems("sb", names), true, false) end
    combo.updating = false
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

    if not IsHeroDisabled(my_hero) then
        ProcessInkSwell(my_hero, my_player)
    end

    ProcessDarkPortrait(my_hero, my_player)
end

-- ============================================================================
-- Interactive On-Screen Panel (Animated & High-Performance)
-- ============================================================================
local function HandlePanelMouse(allies)
    local cx, cy = Input.GetCursorPos()
    local p = hud_panel
    local is_lclick = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1)
    local now = os.clock()

    if p.dragging then
        if is_lclick then
            p.x = cx - p.drag_off.x
            p.y = cy - p.drag_off.y
        else
            p.dragging = false
        end
    else
        if is_lclick and (now - p.last_click > 0.20) then
            if cx >= p.x and cx <= p.x + p.w and cy >= p.y and cy <= p.y + p.header_h then
                if cx >= p.x + p.w - 38 and cx <= p.x + p.w - 14 then
                    panel_active = not panel_active
                    p.last_click = now
                    return
                elseif (cx >= p.x + p.w - 14 and cx <= p.x + p.w) or (cx >= p.x and cx <= p.x + 22) then
                    p.collapsed = not p.collapsed
                    p.last_click = now
                    return
                else
                    p.dragging = true
                    p.drag_off = Vec2(cx - p.x, cy - p.y)
                end
            end

            if p.anim_progress > 0.8 then
                local list_y = p.y + 42
                for i = 1, #allies do
                    local node = allies[i]
                    local row_y = list_y + (i - 1) * 24
                    if cx >= p.x + 8 and cx <= p.x + p.w - 8 and cy >= row_y and cy <= row_y + 22 then
                        allowed_allies[node.name] = not allowed_allies[node.name]
                        p.last_click = now
                        return
                    end
                end
            end
        end
    end
end

function GrimHelper.OnDraw()
    if not ui_draw_panel or not GetVal(ui_draw_panel) then return end
    if not Engine.IsInGame() or not GetVal(ui_enabled) then return end

    local my_hero = Heroes.GetLocal()
    if not IsGrimstroke(my_hero) then return end

    local p = hud_panel
    local allies = cache.allies

    HandlePanelMouse(allies)

    local dt = 0.016
    if GlobalVars and GlobalVars.GetAbsFrameTime then
        dt = GlobalVars.GetAbsFrameTime() or 0.016
    end

    local target_anim = p.collapsed and 0.0 or 1.0
    p.anim_progress = p.anim_progress + (target_anim - p.anim_progress) * math.min(1.0, dt * 12.0)
    local progress = p.anim_progress * p.anim_progress * (3 - 2 * p.anim_progress)

    local row_h = 24
    local content_h = 18 + (#allies * row_h) + 40
    local current_content_h = math.floor(content_h * progress)
    local total_h = p.header_h + (current_content_h > 2 and current_content_h or 0)

    local tl = Vec2(p.x, p.y)
    local br = Vec2(p.x + p.w, p.y + total_h)

    local accent   = GetAccentColor()
    local c_body   = Color(15, 17, 23, 195)
    local c_border = Color(255, 255, 255, 16)
    local c_plate  = Color(25, 28, 38, 160)
    local c_text   = Color(225, 230, 240, 230)
    local c_muted  = Color(140, 145, 160, 200)
    local c_green  = GetThemeColor("multiselect_item_selected", Color(63, 191, 95, 245))
    local c_red    = GetThemeColor("multiselect_item", Color(224, 50, 45, 245))

    local f_bold = font_bold or Render.LoadFont("Segoe UI", Enum.FontCreate.FONTFLAG_ANTIALIAS, 700)
    local f_main = font_main or Render.LoadFont("Segoe UI", Enum.FontCreate.FONTFLAG_ANTIALIAS, 400)

    -- 1. Frosted Glass Body Background
    Render.Blur(tl, br, 2.0, 1.0, 7)
    Render.FilledRect(tl, br, c_body, 7)
    Render.Rect(tl, br, c_border, 7, Enum.DrawFlags.None, 1)

    -- 2. Header Bar
    if font_icon then
        Render.Text(font_icon, 11, "\u{f3c5}", Vec2(p.x + 9, p.y + 6), c_muted)
    else
        Render.FilledRect(Vec2(p.x + 9, p.y + 9), Vec2(p.x + 15, p.y + 15), c_muted, 2)
    end

    local title_str = "Grimstroke Helper"
    Render.Text(f_main, 12, title_str, Vec2(p.x + 68, p.y + 5), c_text)

    -- Miniature Switch Toggle
    local sw_x = p.x + p.w - 36
    local sw_y = p.y + 6
    local sw_bg = panel_active and accent or Color(40, 44, 54, 210)

    Render.FilledRect(Vec2(sw_x, sw_y), Vec2(sw_x + 22, sw_y + 12), sw_bg, 6)
    Render.Rect(Vec2(sw_x, sw_y), Vec2(sw_x + 22, sw_y + 12), Color(255, 255, 255, 20), 6, nil, 1)

    local thumb_x = panel_active and (sw_x + 16) or (sw_x + 6)
    if Render.FilledCircle then
        pcall(Render.FilledCircle, Vec2(thumb_x, sw_y + 6), 4, Color(245, 245, 250, 255))
    else
        Render.FilledRect(Vec2(thumb_x - 3, sw_y + 3), Vec2(thumb_x + 3, sw_y + 9), Color(245, 245, 250, 255), 2)
    end

    -- Chevron Glyph
    local chevron_glyph = p.collapsed and "\u{f078}" or "\u{f077}"
    if font_icon then
        Render.Text(font_icon, 9, chevron_glyph, Vec2(p.x + p.w - 11, p.y + 7), c_muted)
    end

    if progress <= 0.05 then return end

    Render.Line(Vec2(p.x + 8, p.y + p.header_h), Vec2(p.x + p.w - 8, p.y + p.header_h), Color(255, 255, 255, 12), 1)

    -- 3. Subheader: Count of allowed allies
    Render.FilledRect(Vec2(p.x + 10, p.y + 29), Vec2(p.x + 14, p.y + 34), accent, 2)
    Render.Text(f_bold, 11, "Ink Swell Targets", Vec2(p.x + 20, p.y + 26), c_text)

    local count_str = string.format("%d / %d", cache.allowed_count, #allies)
    Render.Text(f_main, 10, count_str, Vec2(p.x + p.w - 40, p.y + 27), c_muted)

    -- 4. Allied Heroes List
    local list_y = p.y + 42
    local cx, cy = Input.GetCursorPos()

    for i = 1, #allies do
        local node = allies[i]
        local row_y = list_y + (i - 1) * row_h

        local is_hover = (cx >= p.x + 8 and cx <= p.x + p.w - 8 and cy >= row_y and cy <= row_y + 22)
        local row_bg = is_hover and Color(40, 44, 58, 180) or c_plate

        Render.FilledRect(Vec2(p.x + 8, row_y), Vec2(p.x + p.w - 8, row_y + 21), row_bg, 4)
        Render.Rect(Vec2(p.x + 8, row_y), Vec2(p.x + p.w - 8, row_y + 21), Color(255, 255, 255, 10), 4, nil, 1)

        local node_col = node.enabled and c_green or c_red
        local pt_c = Vec2(p.x + 18, row_y + 10)

        if Render.FilledCircle then
            pcall(Render.FilledCircle, pt_c, 4.5, Color(16, 18, 24, 230))
            pcall(Render.Circle, pt_c, 4.5, node_col, 1.5)
            if node.enabled then
                pcall(Render.FilledCircle, pt_c, 2.0, Color(255, 255, 255, 255))
            end
        else
            Render.FilledRect(pt_c - Vec2(4, 4), pt_c + Vec2(4, 4), Color(16, 18, 24, 230), 3)
            Render.Rect(pt_c - Vec2(4, 4), pt_c + Vec2(4, 4), node_col, 3, nil, 1.2)
            if node.enabled then
                Render.FilledRect(pt_c - Vec2(1.5, 1.5), pt_c + Vec2(1.5, 1.5), Color(255, 255, 255, 255), 1)
            end
        end

        local txt_col = node.enabled and c_text or c_muted
        Render.Text(f_main, 11, node.display, Vec2(p.x + 28, row_y + 4), txt_col)

        local dist_str = "-"
        local dist_col = c_muted
        if node.enemy_dist < 3000 then
            dist_str = string.format("%.0f", node.enemy_dist)
            if node.enemy_dist <= (GetVal(ui_ink_max_dist) or 650) then
                dist_col = c_green
            end
        end
        Render.Text(f_main, 10, dist_str, Vec2(p.x + p.w - 38, row_y + 4), dist_col)
    end

    -- 5. Footer: Dark Portrait & Status
    local foot_y = list_y + (#allies * row_h) + 3
    Render.FilledRect(Vec2(p.x + 8, foot_y), Vec2(p.x + p.w - 8, foot_y + 35), c_plate, 5)
    Render.Rect(Vec2(p.x + 8, foot_y), Vec2(p.x + p.w - 8, foot_y + 35), Color(255, 255, 255, 10), 5, nil, 1)

    local illu_status = "Illusion: None"
    local illu_col = c_muted

    if not panel_active then
        illu_status = "Automation: PAUSED"
        illu_col = Color(255, 180, 0, 255)
    elseif #cache.illusions > 0 then
        if cache.illu_target then
            local t_name = NPC.GetUnitName(cache.illu_target):gsub("npc_dota_hero_", "")
            t_name = t_name:sub(1, 1):upper() .. t_name:sub(2)
            illu_status = string.format("Focus: %s (%.0f HP)", t_name, Entity.GetHealth(cache.illu_target))
            illu_col = accent
        else
            illu_status = "Illusion: Following"
            illu_col = Color(80, 180, 255, 255)
        end
    end

    Render.Text(f_bold, 10, "Dark Portrait", Vec2(p.x + 14, foot_y + 3), accent)
    Render.Text(f_main, 10, illu_status, Vec2(p.x + 14, foot_y + 18), illu_col)
end

-- ============================================================================
-- Initialization
-- ============================================================================
SetupMenu()

return GrimHelper