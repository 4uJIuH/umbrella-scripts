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
        awp_auto_play_group = "Auto Play Settings",
        awp_enable = "Smart Wave Pusher",
        awp_enable_tip = "The enabled addon fully manages clone wave pushing without a separate hotkey",
        awp_gear_debug = "Diagnostics",
        awp_debug = "Push debug",
        awp_debug_tip = "Writes compact decisions and corrected Spark outcomes to the MCP debug log",
        awp_smart_position = "Smart Magnetic Field",
        awp_smart_position_tip = "Finds the best Field position for allied creeps at enemy towers and before the clone expires",
        awp_spark_ranged = "Spark on Ranged Creep",
        awp_spark_ranged_tip = "Uses Spark only when it improves the ranged-creep kill plan and preserves mana for Magnetic Field",
        awp_priority_flag = "Prioritize Flagbearer",
        awp_priority_flag_tip = "Locks onto the flagbearer after ranged creeps and accounts for incoming allied projectiles",
        awp_attack_lead = "Last-hit Attack Lead",
        awp_attack_lead_tip = "Extra timing margin for allied projectiles and network latency",
        awp_draw_target = "Show Push Target",
        awp_draw_target_tip = "Shows a native Dota marker under the clone's locked push target",
        awp_gear_target = "Target Marker",
        awp_target_effect = "Effect",
        awp_target_effect_creep = "Creep Reticle",
        awp_target_effect_glow = "Selection Glow",
        awp_target_color = "Color",
        awp_target_size = "Size",
        awp_field_info = "Magnetic Field Info",
        awp_field_info_tip = "Shows the planned Field radius and the number of allied creeps it will cover",
        awp_gear_field_info = "Display Settings",
        awp_show_field_radius = "Radius",
        awp_show_field_count = "Creep Count",
        awp_field_mode = "Mode",
        awp_field_mode_cast_range = "Within Cast Range",
        awp_field_mode_anywhere = "Anywhere",
        awp_field_effect = "Effect",
        awp_field_effect_dota = "Dota",
        awp_field_effect_clean = "Clean Ring",
        awp_field_radius_color = "Radius Color",
        awp_field_count_size = "Counter Size",
        awp_field_count_color = "Counter Color",
        awp_hero_override = "Yield to Combo & Nearby Heroes",
        awp_hero_override_tip = "Immediately yields clone control to manual orders, combo logic, and nearby enemy heroes",
    },
    ru = {
        awp_auto_play_group = "Auto Play Settings",
        awp_enable = "Умный пуш пачек",
        awp_enable_tip = "Включённый аддон сам управляет пушем копии без отдельной горячей клавиши",
        awp_gear_debug = "Диагностика",
        awp_debug = "Отладка пуша",
        awp_debug_tip = "Записывает основные решения и исправления Спарка в MCP debug log",
        awp_smart_position = "Умный Magnetic Field",
        awp_smart_position_tip = "Ищет лучшую позицию купола для союзных крипов у вражеской башни и перед исчезновением копии",
        awp_spark_ranged = "Спарк под дальника",
        awp_spark_ranged_tip = "Использует Спарк только когда он улучшает добивание дальника и сохраняет ману на купол",
        awp_priority_flag = "Приоритет знаменосца",
        awp_priority_flag_tip = "После дальников фиксирует знаменосца и учитывает летящие снаряды союзных крипов",
        awp_attack_lead = "Упреждение ластхита",
        awp_attack_lead_tip = "Дополнительный запас времени на союзные снаряды и сетевую задержку",
        awp_draw_target = "Отображать цель пуша",
        awp_draw_target_tip = "Показывает нативный эффект Dota под зафиксированной целью копии",
        awp_gear_target = "Метка цели",
        awp_target_effect = "Эффект",
        awp_target_effect_creep = "Прицел крипа",
        awp_target_effect_glow = "Подсветка выбора",
        awp_target_color = "Цвет",
        awp_target_size = "Размер",
        awp_field_info = "Информация Magnetic Field",
        awp_field_info_tip = "Показывает запланированный радиус купола и количество союзных крипов внутри",
        awp_gear_field_info = "Настройки отображения",
        awp_show_field_radius = "Радиус",
        awp_show_field_count = "Количество крипов",
        awp_field_mode = "Режим",
        awp_field_mode_cast_range = "В радиусе способности",
        awp_field_mode_anywhere = "В любом радиусе",
        awp_field_effect = "Эффект",
        awp_field_effect_dota = "Dota",
        awp_field_effect_clean = "Чистое кольцо",
        awp_field_radius_color = "Цвет радиуса",
        awp_field_count_size = "Размер счётчика",
        awp_field_count_color = "Цвет счётчика",
        awp_hero_override = "Уступать комбо и при врагах рядом",
        awp_hero_override_tip = "Сразу уступает управление ручным приказам, комбо и при приближении вражеского героя",
    },
})

local UI = localization.WrapLibrary(Menu)

--[[
    Arc Warden Clone Wave Pusher Addon (Умный пуш пачек для клона Арк Вардена)
    
    Новая логика: УМНЫЙ КАЛЬКУЛЯТОР УРОНА И РАСПРЕДЕЛЕННЫЙ ПУШ
    1. Калькулятор урона от Спарка:
       - Рассчитывает точный чистый урон Spark Wraith по крипу с учетом уровня,
         таланта 25-го уровня (+240 урона), Spell Amplification и маг. резиста крипа (25%).
    2. Умное распределение тычек (Damage Accounting):
       - Считает, сколько ХП останется у дальника после взрыва Спарка.
       - Если Спарк ваншотит дальника (ХП <= урон спарка) — клон ставит спарк и дает 0 ТЫЧЕК!
       - Если не хватает урона — клон делает РОВНО столько тычек (обычно 1), сколько нужно,
         чтобы суммарный урон (тычка + Спарк) гарантированно убил дальника.
       - Как только нужная тычка выпущена, крип помечается как «гарантированно труп».
         Клон НЕ ЖДЕТ взрыва и НЕ ДЕЛАЕТ лишних тычек, а мгновенно переключается дальше!
    3. Жесткая отмена атак по милишникам:
       - В OnPrepareUnitOrders приказы базового скрипта бить милишников жестко отменяются
         через return false (а не просто data.target), с мгновенной переотдачей в приоритетную цель.
    4. Очередь целей:
       - Дальник №1 ➔ Дальник №2 (если дабл-пачка) ➔ Знаменосец ➔ Остальные милишники.
--]]

local SCRIPT_NAME = "ArcWardenWavePusher"
local ORDER_IDENTIFIER = "AW_Wave_Pusher"

local ui = {}

local auto_play_group = UI.Create("Heroes", "Hero List", "Arc Warden", "Clone Settings", "awp_auto_play_group")

ui.enable = auto_play_group:Switch("awp_enable", true, "\u{f0e7}")
ui.enable:ToolTip("awp_enable_tip")
ui.debug_gear = ui.enable:Gear("awp_gear_debug")
ui.debug = ui.debug_gear:Switch("awp_debug", false, "\u{f188}")
ui.debug:ToolTip("awp_debug_tip")

ui.smart_position = auto_play_group:Switch("awp_smart_position", true, "\u{f1ad}")
ui.smart_position:ToolTip("awp_smart_position_tip")

ui.spark_ranged = auto_play_group:Switch("awp_spark_ranged", true, "\u{f06d}")
ui.spark_ranged:ToolTip("awp_spark_ranged_tip")

ui.priority_flagbearer = auto_play_group:Switch("awp_priority_flag", true, "\u{f024}")
ui.priority_flagbearer:ToolTip("awp_priority_flag_tip")

ui.attack_lead = auto_play_group:Slider("awp_attack_lead", 0, 150, 40, "%d ms")
ui.attack_lead:ToolTip("awp_attack_lead_tip")

ui.draw_target = auto_play_group:Switch("awp_draw_target", true, "\u{f140}")
ui.draw_target:ToolTip("awp_draw_target_tip")
ui.target_gear = ui.draw_target:Gear("awp_gear_target")
ui.target_effect = ui.target_gear:Combo("awp_target_effect", { "awp_target_effect_creep", "awp_target_effect_glow" }, 0)
ui.target_color = ui.target_gear:ColorPicker("awp_target_color", Color(55, 210, 255, 255), "\u{f53f}")
ui.target_color:HideAlphaBar(true)
ui.target_size = ui.target_gear:Slider("awp_target_size", 45, 100, 68, "%d%%")

ui.field_info = auto_play_group:Switch("awp_field_info", true, "\u{f1ce}")
ui.field_info:ToolTip("awp_field_info_tip")
ui.field_info_gear = ui.field_info:Gear("awp_gear_field_info")
ui.show_field_radius = ui.field_info_gear:Switch("awp_show_field_radius", true, "\u{f1ce}")
ui.show_field_count = ui.field_info_gear:Switch("awp_show_field_count", true, "\u{f03a}")
ui.field_mode = ui.field_info_gear:Combo("awp_field_mode", { "awp_field_mode_cast_range", "awp_field_mode_anywhere" }, 0)
ui.field_effect = ui.field_info_gear:Combo("awp_field_effect", { "awp_field_effect_dota", "awp_field_effect_clean" }, 0)
ui.field_radius_color = ui.field_info_gear:ColorPicker("awp_field_radius_color", Color(55, 225, 120, 255), "\u{f53f}")
ui.field_radius_color:HideAlphaBar(true)
ui.field_count_size = ui.field_info_gear:Slider("awp_field_count_size", 35, 100, 58, "%d%%")
ui.field_count_color = ui.field_info_gear:ColorPicker("awp_field_count_color", Color(30, 235, 70, 255), "\u{f53f}")
ui.field_count_color:HideAlphaBar(true)

ui.hero_override = auto_play_group:Switch("awp_hero_override", true, "\u{f06e}")
ui.hero_override:ToolTip("awp_hero_override_tip")

local function update_visibility(widget)
    local enabled = widget:Get()
    ui.smart_position:Visible(enabled)
    ui.spark_ranged:Visible(enabled)
    ui.priority_flagbearer:Visible(enabled)
    ui.attack_lead:Visible(enabled)
    ui.draw_target:Visible(enabled)
    ui.field_info:Visible(enabled)
    ui.hero_override:Visible(enabled)
    ui.debug:Disabled(not enabled)
end

ui.enable:SetCallback(update_visibility, true)

--#region Runtime State
local last_spark_time = 0
local last_field_time = 0
local last_attack_time = 0
local last_move_time = 0
local last_spell_cast_time = 0
local last_ordered_target = nil
local last_hero_action_time = 0
local is_holding_fire = false
local is_in_attack_position = false
local active_priority_target = nil

-- Таблицы отслеживания плана урона по крипам
local spark_placed_time = {}   -- [creep] = timestamp
local incoming_damage = {}
local pending_spark_cast = nil
local attack_in_progress = nil -- { target = creep, start_time = timestamp, swing_time = number }
local tracked_clone = nil

local creep_health_cache = {}
local active_particle = nil
local last_particle_target = nil
local runtime = {
    locked_target = nil,
    locked_kind = nil,
    field_plan = nil,
    active_field = nil,
    pending_field_cast = nil,
    last_field_plan_time = -math.huge,
    field_particle = nil,
    field_particle_path = nil,
    ally_projectiles = {},
    spark_commitments = {},
    spark_followup_target = nil,
    spark_followup_shot_required = false,
    guaranteed_kill_wait = nil,
    next_spark_id = 0,
    counter_font = nil,
}
local native_spark = {
    item = "arc_warden_spark_wraith",
    entries = {
        { key = "native_spark_auto_usage", group = "Auto Play Settings", name = "Usage" },
        { key = "native_spark_auto_abilities", group = "Auto Play Settings", name = "Abilities" },
        { key = "native_spark_push_usage", group = "Push Settings", name = "Usage" },
    },
}
local native_field = {
    item = "arc_warden_magnetic_field",
    entries = {
        { key = "native_field_auto_usage", group = "Auto Play Settings", name = "Usage" },
        { key = "native_field_auto_abilities", group = "Auto Play Settings", name = "Abilities" },
        { key = "native_field_push_usage", group = "Push Settings", name = "Usage" },
    },
}
--#endregion

--#region Helper Functions
local function IsAlive(unit)
    if not unit then return false end
    local valid_ok, valid = pcall(Entity.IsEntity, unit)
    if not valid_ok or not valid then return false end
    local alive_ok, alive = pcall(Entity.IsAlive, unit)
    return alive_ok and alive == true
end

--- Находит живого клона Арк Вардена
---@param my_hero CHero
---@return CNPC?
local function GetClone(my_hero)
    if not my_hero then return nil end
    
    local tempest_double_ability = NPC.GetAbility(my_hero, "arc_warden_tempest_double")
    if tempest_double_ability then
        local clone = CustomEntities.GetTempestDouble(tempest_double_ability)
        if clone and IsAlive(clone) and not Entity.IsDormant(clone) then
            return clone
        end
    end
    
    local heroes = Heroes.GetAll()
    if heroes then
        for _, hero in ipairs(heroes) do
            if hero ~= my_hero 
                and NPC.GetUnitName(hero) == "npc_dota_hero_arc_warden" 
                and Entity.GetOwner(hero) == my_hero 
                and IsAlive(hero) 
                and not Entity.IsDormant(hero)
                and not NPC.IsIllusion(hero) then
                return hero
            end
        end
    end
    
    return nil
end

local combo_binds_cached = nil
local combo_bind_styles = {}

local function GetComboBinds()
    if combo_binds_cached and #combo_binds_cached >= 4 then
        return combo_binds_cached
    end
    
    local binds = {}
    local styles_ready = true
    local paths_ok = pcall(function()
        local function add_bind(tab, group, name)
            local bind = Menu.Find("Heroes", "Hero List", "Arc Warden", tab, group, name)
            if not bind then return end
            table.insert(binds, bind)
            local style = Menu.Find("Heroes", "Hero List", "Arc Warden", tab, group, name, name, "Key Style")
            combo_bind_styles[bind] = style
            if not style then styles_ready = false end
        end
        add_bind("Clone Settings", "Clone Settings", "Clone Combo Key")
        add_bind("Clone Settings", "Combo Settings", "Combo Key")
        add_bind("Main Settings", "Hero Settings", "Combo Key")
        add_bind("Main Settings", "Combo Settings", "Combo Key")
    end)
    
    if paths_ok and #binds >= 4 and styles_ready then
        combo_binds_cached = binds
    end
    return binds
end

local function IsComboActive()
    local binds = GetComboBinds()
    for _, b in ipairs(binds) do
        if b and b.IsDown and b:IsDown() then
            return true
        end
        local style = combo_bind_styles[b]
        if style and b.IsToggled then
            local ok, toggled = pcall(function()
                local value = style:Get()
                local name = type(value) == "number" and style:List()[value + 1] or value
                return name == "Toggle" and b:IsToggled()
            end)
            if ok and toggled then return true end
        end
    end
    
    return false
end

local function GetOrigin(obj)
    if not obj then return nil end
    if Entity and Entity.IsEntity and Entity.IsEntity(obj) then
        return Entity.GetAbsOrigin(obj)
    end
    local ok_ent, origin = pcall(Entity.GetAbsOrigin, obj)
    if ok_ent and origin then return origin end
    
    local ok_vec, x = pcall(function() return obj.x end)
    if ok_vec and x then return obj end
    
    return nil
end

--- Проверяет наличие живого видимого вражеского героя рядом с точкой/сущностью
---@param pos_or_entity Vector|CEntity
---@param max_range number
---@return boolean, CHero?
local function IsEnemyHeroNear(pos_or_entity, max_range)
    local check_pos = GetOrigin(pos_or_entity)
    if not check_pos then return false end
    
    local my_hero = Heroes.GetLocal()
    if not my_hero then return false end
    local my_team = Entity.GetTeamNum(my_hero)
    
    local all_heroes = Heroes.GetAll()
    if not all_heroes then return false end
    
    for _, h in ipairs(all_heroes) do
        if h and IsAlive(h) and not Entity.IsDormant(h) and not NPC.IsWaitingToSpawn(h) and Entity.GetTeamNum(h) ~= my_team then
            local h_pos = Entity.GetAbsOrigin(h)
            if h_pos and (h_pos - check_pos):Length2D() <= max_range then
                return true, h
            end
        end
    end
    return false
end

local function SyncNativeControl(control, owned)
    local frame = GlobalVars.GetFrameCount()
    for _, entry in ipairs(control.entries) do
        local ok = pcall(function()
            if entry.saved == nil then
                entry.saved = Config.ReadInt(SCRIPT_NAME, entry.key .. "_saved", 0) == 1
                entry.original = Config.ReadInt(SCRIPT_NAME, entry.key .. "_original", 0) == 1
            end
            if not owned and not entry.saved then return end

            if not entry.widget then
                if entry.find_frame and (frame - entry.find_frame) < 60 then return end
                entry.find_frame = frame
                local widget = Menu.Find("Heroes", "Hero List", "Arc Warden", "Clone Settings", entry.group, entry.name)
                if not widget then return end
                local found = false
                for _, item in ipairs(widget:List()) do
                    if item == control.item then
                        found = true
                        break
                    end
                end
                if not found then return end
                entry.widget = widget
            end

            local current = entry.widget:Get(control.item)
            if owned then
                if not entry.saved then
                    local original = current and 1 or 0
                    Config.WriteInt(SCRIPT_NAME, entry.key .. "_original", original)
                    Config.WriteInt(SCRIPT_NAME, entry.key .. "_saved", 1)
                    if Config.ReadInt(SCRIPT_NAME, entry.key .. "_original", -1) ~= original
                        or Config.ReadInt(SCRIPT_NAME, entry.key .. "_saved", 0) ~= 1 then
                        return
                    end
                    entry.original = current
                    entry.saved = true
                end
                if current then entry.widget:Set(control.item, false) end
            else
                if current ~= entry.original then
                    entry.widget:Set(control.item, entry.original)
                end
                if entry.widget:Get(control.item) == entry.original then
                    Config.WriteInt(SCRIPT_NAME, entry.key .. "_saved", 0)
                    entry.saved = Config.ReadInt(SCRIPT_NAME, entry.key .. "_saved", 1) == 1
                end
            end
        end)
        if not ok then entry.widget = nil end
    end
end

local function SyncNativeSpark(owned, field_owned)
    SyncNativeControl(native_spark, owned)
    SyncNativeControl(native_field, field_owned == true)
end

local VALID_RANGED_CREEPS = {
    ["npc_dota_creep_goodguys_ranged"] = true,
    ["npc_dota_creep_goodguys_ranged_upgraded"] = true,
    ["npc_dota_creep_goodguys_ranged_upgraded_mega"] = true,
    ["npc_dota_creep_goodguys_ranged_diretide"] = true,
    ["npc_dota_creep_badguys_ranged"] = true,
    ["npc_dota_creep_badguys_ranged_upgraded"] = true,
    ["npc_dota_creep_badguys_ranged_upgraded_mega"] = true,
    ["npc_dota_creep_badguys_ranged_diretide"] = true,
}

local VALID_FLAGBEARER_CREEPS = {
    ["npc_dota_creep_goodguys_flagbearer"] = true,
    ["npc_dota_creep_goodguys_flagbearer_upgraded"] = true,
    ["npc_dota_creep_goodguys_flagbearer_upgraded_mega"] = true,
    ["npc_dota_creep_badguys_flagbearer"] = true,
    ["npc_dota_creep_badguys_flagbearer_upgraded"] = true,
    ["npc_dota_creep_badguys_flagbearer_upgraded_mega"] = true,
}

--- Проверяет, является ли юнит настоящим крипом-дальником волны
---@param c CNPC
---@param name string
---@return boolean
local function IsRealRangedCreep(c, name)
    if not c or not name then return false end
    
    -- 1. Быстрый O(1) поиск по белому списку эталонных имен Доты
    if VALID_RANGED_CREEPS[name] then
        return true
    end
    
    -- 2. Строгий паттерн для возможных кастомных режимов / ивентов
    -- Должен содержать префикс creep_ и суффикс ranged, но ни в коем случае не siege, invoker, eidolon, beastmaster
    if string.find(name, "creep_") and string.find(name, "ranged") then
        if not string.find(name, "siege") 
            and not string.find(name, "invoker") 
            and not string.find(name, "eidolon")
            and not string.find(name, "beastmaster")
            and not string.find(name, "ward") then
            return true
        end
    end
    
    return false
end

--- Проверяет, является ли юнит крипом-знаменосцем волны
---@param c CNPC
---@param name string
---@return boolean
local function IsRealFlagbearerCreep(c, name)
    if not c then return false end
    if NPC.HasModifier(c, "modifier_creep_flagbearer") then
        return true
    end
    if name and VALID_FLAGBEARER_CREEPS[name] then
        return true
    end
    if name and string.find(name, "creep_") and string.find(name, "flagbearer") then
        return true
    end
    return false
end

--- Сканирует пачку вражеских крипов на широкой дистанции (до 1800)
---@param clone CNPC
---@param my_team integer
---@return CNPC[] ranged_creeps, CNPC? flagbearer_creep, boolean any_lane_creep
local function GetWaveCreeps(clone, my_team)
    local clone_origin = Entity.GetAbsOrigin(clone)
    local search_radius = 1800
    
    local ranged_creeps = {}
    local flagbearer_creep = nil
    local any_lane_creep = false
    local min_dist_flag = 999999
    
    local creeps = NPCs.GetAll(Enum.UnitTypeFlags.TYPE_LANE_CREEP)
    if not creeps then return ranged_creeps, nil, false end
    
    for _, c in ipairs(creeps) do
        if c and IsAlive(c) and not Entity.IsDormant(c) and not NPC.IsWaitingToSpawn(c) and not NPC.IsIllusion(c) then
            if Entity.GetTeamNum(c) ~= my_team and NPC.IsLaneCreep(c) and not NPC.IsStructure(c) then
                -- Отсекаем саммонов героя (форджей, кабанов, эйдолонов) и прирученных юнитов
                local owner = Entity.GetOwner(c)
                local is_player_summon = owner and (NPC.IsHero(owner) or NPC.IsConsideredHero(owner))
                
                if not is_player_summon then
                    local c_pos = Entity.GetAbsOrigin(c)
                    local dist = (c_pos - clone_origin):Length2D()
                    
                    if dist <= search_radius then
                        any_lane_creep = true
                        local name = NPC.GetUnitName(c) or ""
                        
                        -- 1. Проверка на настоящего дальника волны
                        if IsRealRangedCreep(c, name) then
                            table.insert(ranged_creeps, c)
                        -- 2. Проверка на знаменосца волны
                        elseif IsRealFlagbearerCreep(c, name) and dist < min_dist_flag then
                            flagbearer_creep = c
                            min_dist_flag = dist
                        end
                    end
                end
            end
        end
    end
    
    table.sort(ranged_creeps, function(a, b)
        local d1 = (Entity.GetAbsOrigin(a) - clone_origin):Length2D()
        local d2 = (Entity.GetAbsOrigin(b) - clone_origin):Length2D()
        return d1 < d2
    end)
    
    return ranged_creeps, flagbearer_creep, any_lane_creep
end

local function IsSiegeCreep(creep)
    local name = creep and NPC.GetUnitName(creep) or ""
    return name:find("_siege", 1, true) ~= nil
end

local function IsValidLaneCreep(creep, allow_dormant)
    if not creep or not IsAlive(creep) or NPC.IsWaitingToSpawn(creep) or NPC.IsIllusion(creep) then
        return false
    end
    if not allow_dormant and Entity.IsDormant(creep) then return false end
    if not NPC.IsLaneCreep(creep) or NPC.IsStructure(creep) then return false end
    local owner = Entity.GetOwner(creep)
    return not owner or (not NPC.IsHero(owner) and not NPC.IsConsideredHero(owner))
end

local function GetAbilityValue(ability, name, fallback)
    if not ability then return fallback end
    local ok, value = pcall(Ability.GetLevelSpecialValueFor, ability, name)
    if ok and type(value) == "number" and value > 0 then return value end
    return fallback
end

local function AveragePosition(points)
    if #points == 0 then return nil end
    local sum = Vector(0, 0, 0)
    for _, point in ipairs(points) do
        sum = sum + point.pos
    end
    return sum * (1 / #points)
end

local function AddFieldCandidate(candidates, point)
    if not point then return end
    for _, existing in ipairs(candidates) do
        if (existing - point):Length2D() < 8 then return end
    end
    candidates[#candidates + 1] = point
end

local function AddPairFieldCandidates(candidates, first, second, radius)
    local delta = second - first
    delta.z = 0
    local distance = delta:Length2D()
    if distance <= 0.01 or distance > radius * 2 then return end
    local midpoint = (first + second) * 0.5
    AddFieldCandidate(candidates, midpoint)
    local height = math.sqrt(math.max(radius * radius - distance * distance * 0.25, 0))
    if height <= 0.01 then return end
    local direction = delta:Normalized()
    local perpendicular = Vector(-direction.y, direction.x, 0)
    AddFieldCandidate(candidates, midpoint + perpendicular * height)
    AddFieldCandidate(candidates, midpoint - perpendicular * height)
end

local function IsBetterFieldScore(score, best)
    if not best then return true end
    if score.siege ~= best.siege then return score.siege > best.siege end
    if score.total ~= best.total then return score.total > best.total end
    if score.tank ~= best.tank then return score.tank > best.tank end
    if score.clone ~= best.clone then return score.clone > best.clone end
    return score.stability > best.stability
end

local function FindBestFieldPlan(clone, field, points, tower, previous_center)
    if not clone or not field or #points == 0 then return nil end
    local radius = GetAbilityValue(field, "radius", 300)
    local cast_range = Ability.GetCastRange(field) or 900
    local clone_pos = Entity.GetAbsOrigin(clone)
    local candidates = {}
    local centroid = AveragePosition(points)
    AddFieldCandidate(candidates, centroid)
    for i, point in ipairs(points) do
        AddFieldCandidate(candidates, point.pos)
        for j = i + 1, #points do
        AddPairFieldCandidates(candidates, point.pos, points[j].pos, radius)
        end
    end

    local tower_pos = tower and Entity.GetAbsOrigin(tower) or nil
    local tower_target = tower and Tower.GetAttackTarget(tower) or nil
    local best_any, best_any_score = nil, nil
    local best_castable, best_castable_score = nil, nil
    for _, center in ipairs(candidates) do
        local tower_clear = not tower_pos or (center - tower_pos):Length2D() > radius + 65
        local traversable = true
        if tower_pos then traversable = GridNav.IsTraversable(center) == true end
        if tower_clear and traversable then
            local covered, siege, tank = 0, 0, 0
            for _, point in ipairs(points) do
                if (point.pos - center):Length2D() <= radius then
                    covered = covered + 1
                    if point.siege then siege = siege + 1 end
                    if point.unit == tower_target then tank = 1 end
                end
            end
            local score = {
                siege = siege,
                total = covered,
                tank = tank,
                clone = (clone_pos - center):Length2D() <= radius and 1 or 0,
                stability = previous_center and -(previous_center - center):Length2D() or 0,
            }
            if IsBetterFieldScore(score, best_any_score) then
                best_any, best_any_score = center, score
            end
            if (clone_pos - center):Length2D() <= cast_range and IsBetterFieldScore(score, best_castable_score) then
                best_castable, best_castable_score = center, score
            end
        end
    end

    local must_wait_for_siege = best_any_score and best_any_score.siege > 0
        and (not best_castable_score or best_castable_score.siege < best_any_score.siege)
    local center = must_wait_for_siege and best_any or (best_castable or best_any)
    local score = must_wait_for_siege and best_any_score or (best_castable_score or best_any_score)
    if not center or not score then return nil end
    return {
        center = center,
        radius = radius,
        count = score.total,
        siege_count = score.siege,
        castable = best_castable ~= nil and not must_wait_for_siege,
        created_at = GameRules.GetGameTime(),
    }
end

local function GetCloneRemainingLife(clone)
    local game_time = GameRules.GetGameTime()
    local modifiers = NPC.GetModifiers(clone) or {}
    local latest_die_time = nil
    for _, modifier in ipairs(modifiers) do
        local ability = Modifier.GetAbility(modifier)
        if ability and Ability.GetName(ability) == "arc_warden_tempest_double" then
            local die_time = Modifier.GetDieTime(modifier)
            if type(die_time) == "number" and die_time > game_time
                and (not latest_die_time or die_time > latest_die_time) then
                latest_die_time = die_time
            end
        end
    end
    if latest_die_time then return latest_die_time - game_time end
    return math.huge
end

local function BuildTowerFieldPlan(clone, field, my_team)
    local clone_pos = Entity.GetAbsOrigin(clone)
    local towers = Towers.InRadius(clone_pos, 1800, my_team, Enum.TeamType.TEAM_ENEMY) or {}
    local tower = nil
    local tower_distance = math.huge
    for _, candidate in ipairs(towers) do
        if IsAlive(candidate) and not Entity.IsDormant(candidate) then
            local distance = (Entity.GetAbsOrigin(candidate) - clone_pos):Length2D()
            if distance < tower_distance then
                tower, tower_distance = candidate, distance
            end
        end
    end
    if not tower then return nil end

    local tower_pos = Entity.GetAbsOrigin(tower)
    local points = {}
    for _, creep in ipairs(NPCs.GetAll(Enum.UnitTypeFlags.TYPE_LANE_CREEP) or {}) do
        if IsValidLaneCreep(creep, false) and Entity.GetTeamNum(creep) == my_team then
            local pos = Entity.GetAbsOrigin(creep)
            if (pos - tower_pos):Length2D() <= 1050 and (pos - clone_pos):Length2D() <= 1750 then
                points[#points + 1] = { unit = creep, pos = pos, siege = IsSiegeCreep(creep) }
            end
        end
    end
    if #points == 0 then return nil end

    local plan = FindBestFieldPlan(clone, field, points, tower, runtime.field_plan and runtime.field_plan.center)
    if not plan or (plan.siege_count == 0 and plan.count < 2) then return nil end
    plan.kind = "tower"
    plan.tower = tower
    plan.tower_target = Tower.GetAttackTarget(tower)
    plan.points = points
    return plan
end

local function GetAverageMoveSpeed(points)
    local total = 0
    for _, point in ipairs(points) do
        total = total + math.max(NPC.GetMoveSpeed(point.unit) or NPC.GetBaseSpeed(point.unit) or 325, 1)
    end
    return #points > 0 and total / #points or 325
end

local function BuildDeathFieldPlan(clone, field, my_team)
    local clone_pos = Entity.GetAbsOrigin(clone)
    local allies, enemies = {}, {}
    for _, creep in ipairs(NPCs.GetAll(Enum.UnitTypeFlags.TYPE_LANE_CREEP) or {}) do
        if IsValidLaneCreep(creep, true) then
            local point = { unit = creep, pos = Entity.GetAbsOrigin(creep), siege = IsSiegeCreep(creep) }
            if Entity.GetTeamNum(creep) == my_team then
                if (point.pos - clone_pos):Length2D() <= 2300 then allies[#allies + 1] = point end
            else
                enemies[#enemies + 1] = point
            end
        end
    end
    if #allies == 0 or #enemies == 0 then return nil end

    table.sort(allies, function(a, b)
        return (a.pos - clone_pos):Length2D() < (b.pos - clone_pos):Length2D()
    end)
    local allied_wave = {}
    local ally_anchor = allies[1].pos
    for _, point in ipairs(allies) do
        if (point.pos - ally_anchor):Length2D() <= 700 then allied_wave[#allied_wave + 1] = point end
    end
    local ally_center = AveragePosition(allied_wave)
    table.sort(enemies, function(a, b)
        return (a.pos - ally_center):Length2D() < (b.pos - ally_center):Length2D()
    end)
    if (enemies[1].pos - ally_center):Length2D() > 3600 then return nil end
    local enemy_wave = {}
    local enemy_anchor = enemies[1].pos
    for _, point in ipairs(enemies) do
        if (point.pos - enemy_anchor):Length2D() <= 700 then enemy_wave[#enemy_wave + 1] = point end
    end
    local enemy_center = AveragePosition(enemy_wave)
    local delta = enemy_center - ally_center
    delta.z = 0
    local distance = delta:Length2D()
    local duration = GetAbilityValue(field, "duration", 4)
    local meeting_time = 0
    local projected = {}
    local already_engaged = distance <= 475
    if already_engaged then
        for _, point in ipairs(allied_wave) do
            projected[#projected + 1] = {
                unit = point.unit,
                pos = point.pos,
                siege = point.siege,
            }
        end
    else
        local ally_speed = GetAverageMoveSpeed(allied_wave)
        local enemy_speed = GetAverageMoveSpeed(enemy_wave)
        meeting_time = distance / math.max(ally_speed + enemy_speed, 1)
        if meeting_time > duration - 0.25 or meeting_time > 8 then return nil end

        local direction = delta:Normalized()
        for _, point in ipairs(allied_wave) do
            local remaining = (enemy_center - point.pos):Length2D()
            local travel = math.min((NPC.GetMoveSpeed(point.unit) or 325) * meeting_time, remaining)
            projected[#projected + 1] = {
                unit = point.unit,
                pos = point.pos + direction * travel,
                siege = point.siege,
            }
        end
    end
    local plan = FindBestFieldPlan(clone, field, projected, nil, runtime.field_plan and runtime.field_plan.center)
    if not plan or plan.count == 0 then return nil end
    plan.kind = "death"
    plan.meeting_time = meeting_time
    plan.already_engaged = already_engaged
    plan.points = projected
    return plan
end

local function RefreshFieldPlan(clone, field, my_team, cur_time, remaining_life)
    if (cur_time - runtime.last_field_plan_time) < 0.12 then return runtime.field_plan end
    runtime.last_field_plan_time = cur_time
    local death_plan = nil
    local death_lookahead = math.max(GetAbilityValue(field, "duration", 4) + 2.0, 6.0)
    if remaining_life <= death_lookahead then
        death_plan = BuildDeathFieldPlan(clone, field, my_team)
    end
    runtime.field_plan = death_plan or BuildTowerFieldPlan(clone, field, my_team)
    return runtime.field_plan
end

--- Калькулятор чистого магического урона Spark Wraith
---@param clone CNPC
---@param spark CAbility
---@param creep CNPC
---@return number effective_spark_damage
local function CalculateSparkDamageOnCreep(clone, spark, creep)
    if not clone or not spark or not creep then return 0 end
    
    local lvl = Ability.GetLevel(spark) or 1
    if lvl == 0 then return 0 end
    
    -- 1. Базовый урон способности
    -- В KV Dota 2 это AbilityValues.spark_damage_base или spark_damage
    local base_damage = Ability.GetLevelSpecialValueFor(spark, "spark_damage_base", lvl) or 0
    if base_damage == 0 then
        base_damage = Ability.GetDamage(spark) or 0
    end
    if base_damage == 0 then
        local damages = { 100, 170, 240, 310 }
        base_damage = damages[lvl] or 310
    end
    
    -- 2. Проверка таланта на урон Spark Wraith
    local talent = NPC.GetAbility(clone, "special_bonus_unique_arc_warden") 
        or NPC.GetAbility(clone, "special_bonus_unique_arc_warden_4")
    if talent and Ability.GetLevel(talent) > 0 and base_damage <= 310 then
        local bonus = Ability.GetLevelSpecialValueFor(talent, "value") or 200
        base_damage = base_damage + bonus
    end
    
    -- 3. Spell Amplification (усиление магии)
    local spell_amp = 1.0
    if NPC.GetBaseSpellAmp then
        spell_amp = 1.0 + (NPC.GetBaseSpellAmp(clone) or 0)
    end
    
    -- 4. Магическое сопротивление крипа
    -- У линейных крипов 0% базового резиста магии (множитель 1.0).
    local magic_mult = 1.0
    if NPC.GetMagicalArmorDamageMultiplier then
        magic_mult = NPC.GetMagicalArmorDamageMultiplier(creep) or 1.0
    end
    
    return base_damage * spell_amp * magic_mult
end

local function GetPendingDamage(target, cur_time)
    local record = incoming_damage[target]
    if not record then return 0 end

    local current_hp = Entity.GetHealth(target)
    local hp_loss = math.max(record.last_hp - current_hp, 0)
    local damage = 0
    local shots = {}
    for _, shot in ipairs(record.shots) do
        local accounted = math.min(shot.damage, hp_loss)
        shot.damage = shot.damage - accounted
        hp_loss = hp_loss - accounted
        if shot.damage > 0 and shot.expires_at > cur_time then
            shots[#shots + 1] = shot
            damage = damage + shot.damage
        end
    end

    if #shots == 0 then
        incoming_damage[target] = nil
    else
        record.last_hp = current_hp
        record.shots = shots
    end
    return damage
end

local function AddPendingDamage(target, damage, expires_at, tag)
    GetPendingDamage(target, GameRules.GetGameTime())
    if damage <= 0 then return end
    local record = incoming_damage[target]
    if not record then
        record = { last_hp = Entity.GetHealth(target), shots = {} }
        incoming_damage[target] = record
    end
    record.shots[#record.shots + 1] = { damage = damage, expires_at = expires_at, tag = tag }
end

local function RemovePendingDamage(target, tag)
    local record = target and incoming_damage[target]
    if not record or not tag then return end
    local shots = {}
    for _, shot in ipairs(record.shots) do
        if shot.tag ~= tag then shots[#shots + 1] = shot end
    end
    record.shots = shots
    if #shots == 0 then incoming_damage[target] = nil end
end

local function ClearPendingSparkCast()
    local pending = pending_spark_cast
    if pending and spark_placed_time[pending.target] == pending.issued_at then
        spark_placed_time[pending.target] = nil
    end
    pending_spark_cast = nil
end

local function UpdatePendingSparkCast(clone, cur_time)
    local pending = pending_spark_cast
    if not pending then return false end
    if pending.clone ~= clone or not IsAlive(pending.clone) or not IsAlive(pending.target) then
        ClearPendingSparkCast()
        return false
    end

    local cooldown_ok, cooldown = pcall(Ability.GetCooldown, pending.ability)
    if not cooldown_ok or type(cooldown) ~= "number" then
        ClearPendingSparkCast()
        return false
    end
    if cooldown > 0 then
        spark_placed_time[pending.target] = cur_time
        runtime.next_spark_id = runtime.next_spark_id + 1
        local tag = "spark:" .. tostring(runtime.next_spark_id)
        local activation_delay = GetAbilityValue(pending.ability, "base_activation_delay", 1.5)
        local speed = GetAbilityValue(pending.ability, "wraith_speed_base", 550)
        local radius = GetAbilityValue(pending.ability, "radius", 375)
        local damage = CalculateSparkDamageOnCreep(clone, pending.ability, pending.target)
        local distance = (Entity.GetAbsOrigin(pending.target) - pending.cast_pos):Length2D()
        local expires_at = cur_time + activation_delay + distance / math.max(speed, 1) + 0.35
        AddPendingDamage(pending.target, damage, expires_at, tag)
        runtime.spark_followup_target = pending.target
        runtime.spark_followup_shot_required = true
        runtime.spark_commitments[#runtime.spark_commitments + 1] = {
            tag = tag,
            clone = clone,
            intended = pending.target,
            reserved_target = pending.target,
            cast_pos = pending.cast_pos,
            damage = damage,
            activates_at = cur_time + activation_delay,
            speed = speed,
            radius = radius,
            issued_at = pending.issued_at,
        }
        pending_spark_cast = nil
        return false
    end

    local phase_ok, in_phase = pcall(Ability.IsInAbilityPhase, pending.ability)
    if not phase_ok or (pending.phase_seen and not in_phase) or (cur_time - pending.issued_at) >= 1.5 then
        ClearPendingSparkCast()
        return false
    end
    if in_phase then pending.phase_seen = true end
    return true
end

local function ReconcileSparkCommitments(clone, my_team, cur_time)
    local remaining = {}
    for _, commitment in ipairs(runtime.spark_commitments) do
        if commitment.clone ~= clone or not IsAlive(clone) then
            RemovePendingDamage(commitment.reserved_target, commitment.tag)
        elseif cur_time < commitment.activates_at then
            remaining[#remaining + 1] = commitment
        else
            local actual, best_distance = nil, math.huge
            local candidates = NPCs.InRadius(
                commitment.cast_pos,
                commitment.radius,
                my_team,
                Enum.TeamType.TEAM_ENEMY,
                false,
                true
            ) or {}
            for _, npc in ipairs(candidates) do
                if IsAlive(npc) and not NPC.IsStructure(npc) then
                    local distance = (Entity.GetAbsOrigin(npc) - commitment.cast_pos):Length2D()
                    if distance < best_distance then actual, best_distance = npc, distance end
                end
            end
            RemovePendingDamage(commitment.reserved_target, commitment.tag)
            if actual and NPC.IsLaneCreep(actual) then
                AddPendingDamage(actual, commitment.damage, cur_time + best_distance / math.max(commitment.speed, 1) + 0.35, commitment.tag)
                spark_placed_time[actual] = commitment.issued_at
            end
            if actual ~= commitment.intended and IsAlive(commitment.intended) then
                runtime.spark_followup_target = commitment.intended
                if runtime.guaranteed_kill_wait == commitment.intended then
                    runtime.guaranteed_kill_wait = nil
                end
            end
            if ui.debug:Get() and ai_bridge and ai_bridge.mcp_log then
                ai_bridge.mcp_log("info", "spark outcome corrected", {
                    intended = commitment.intended and Entity.GetIndex(commitment.intended) or -1,
                    actual = actual and Entity.GetIndex(actual) or -1,
                    actual_name = actual and NPC.GetUnitName(actual) or "none",
                    distance = best_distance < math.huge and best_distance or -1,
                })
            end
        end
    end
    runtime.spark_commitments = remaining
end

local function GetAlliedProjectileDamage(target, horizon, cur_time)
    local record = runtime.ally_projectiles[target]
    if not record then return 0 end
    local damage, future = 0, {}
    for _, shot in ipairs(record) do
        if shot.impact_at > cur_time - 0.08 then
            future[#future + 1] = shot
            if shot.impact_at <= horizon then damage = damage + shot.damage end
        end
    end
    runtime.ally_projectiles[target] = #future > 0 and future or nil
    return damage
end

local CalculateLastHit

local function GetCreepKillPlan(clone, creep)
    local current_hp = Entity.GetHealth(creep)
    local min_damage = NPC.GetTrueDamage(clone) or 0
    local armor_mult = NPC.GetArmorDamageMultiplier(creep) or 1.0
    local attack_dmg = min_damage * armor_mult
    if attack_dmg <= 0 then attack_dmg = 50 end
    
    local pending_damage = GetPendingDamage(creep, GameRules.GetGameTime())
    local remaining_hp = current_hp - pending_damage
    local attacks_needed = 0
    if remaining_hp > 0 then
        attacks_needed = math.ceil(remaining_hp / attack_dmg)
    end
    
    return {
        current_hp = current_hp,
        attack_dmg = attack_dmg,
        remaining_hp = remaining_hp,
        pending_damage = pending_damage,
        attacks_needed = attacks_needed,
    }
end

local function IsUnfinishedRanged(clone, creep)
    if not IsAlive(creep) then return false end
    local name = NPC.GetUnitName(creep) or ""
    return IsRealRangedCreep(creep, name) and GetCreepKillPlan(clone, creep).remaining_hp > 0
end

local function SelectPriorityTarget(clone, ranged_creeps, flagbearer)
    local locked = runtime.locked_target
    if locked and IsAlive(locked) and not Entity.IsDormant(locked)
        and (Entity.GetAbsOrigin(locked) - Entity.GetAbsOrigin(clone)):Length2D() <= 2100 then
        local locked_name = NPC.GetUnitName(locked) or ""
        if IsRealRangedCreep(locked, locked_name) and IsUnfinishedRanged(clone, locked) then
            for _, creep in ipairs(ranged_creeps) do
                if creep == locked then return locked, "ranged" end
            end
        end
        if locked == flagbearer and IsRealFlagbearerCreep(locked, locked_name) and ui.priority_flagbearer:Get() then
            local unfinished_ranged = false
            for _, creep in ipairs(ranged_creeps) do
                if IsUnfinishedRanged(clone, creep) then unfinished_ranged = true break end
            end
            if not unfinished_ranged then return locked, "flag" end
        end
    end

    runtime.locked_target = nil
    runtime.locked_kind = nil
    for _, creep in ipairs(ranged_creeps) do
        if IsUnfinishedRanged(clone, creep) then
            runtime.locked_target = creep
            runtime.locked_kind = "ranged"
            return creep, "ranged"
        end
    end
    if flagbearer and IsAlive(flagbearer) and ui.priority_flagbearer:Get() then
        runtime.locked_target = flagbearer
        runtime.locked_kind = "flag"
        return flagbearer, "flag"
    end
    return nil, nil
end

local function GetOutgoingLatency()
    if NetChannel and NetChannel.GetAvgLatency then
        return NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) or 0.03
    end
    return 0.03
end

local function ShouldUseSpark(clone, spark, target, field, field_plan, cur_time)
    if not spark or not target or not Ability.IsCastable(spark, NPC.GetMana(clone)) then return false end
    local spark_cost = Ability.GetManaCost(spark) or 0
    local field_cost = field and (Ability.GetManaCost(field) or 0) or 0
    if field_plan and field and Ability.GetLevel(field) > 0 and Ability.GetCooldown(field) <= 0
        and NPC.GetMana(clone) < spark_cost + field_cost then
        return false
    end

    local last_hit = CalculateLastHit(clone, target)
    if not last_hit then return true end
    local cast_pos = Entity.GetAbsOrigin(target)
    local activation_delay = GetAbilityValue(spark, "base_activation_delay", 1.5)
    local speed = GetAbilityValue(spark, "wraith_speed_base", 550)
    local cast_point = Ability.GetCastPoint(spark) or 0.3
    local spark_eta = cast_point + activation_delay + (cast_pos - Entity.GetAbsOrigin(clone)):Length2D() / math.max(speed, 1)
    local allied_damage = GetAlliedProjectileDamage(target, cur_time + spark_eta, cur_time)
    local hp_before_spark = Entity.GetHealth(target) - allied_damage
    if hp_before_spark <= 0 then return false end
    if hp_before_spark <= last_hit.damage and last_hit.total_time <= spark_eta then return false end
    return true
end

--- Рассчитывает точные параметры атаки и ластхита
---@param clone CNPC
---@param target CNPC
---@return table?
CalculateLastHit = function(clone, target)
    if not clone or not target or not IsAlive(target) then
        return nil
    end
    
    local min_damage = NPC.GetTrueDamage(clone) or 0
    local armor_mult = NPC.GetArmorDamageMultiplier(target) or 1.0
    local true_damage = min_damage * armor_mult
    
    local anim_point = NPC.GetAttackAnimPoint(clone) or 0.3
    local attack_speed = NPC.GetAttackSpeed(clone) or 1.0
    if attack_speed <= 0 then attack_speed = 1.0 end
    
    local swing_time = anim_point / attack_speed
    local proj_speed = NPC.GetAttackProjectileSpeed(clone) or 900
    if proj_speed <= 0 then proj_speed = 900 end
    
    local clone_pos = Entity.GetAbsOrigin(clone)
    local target_pos = Entity.GetAbsOrigin(target)
    local distance = (target_pos - clone_pos):Length2D()
    local flight_time = distance / proj_speed
    
    local latency = 0.03
    if NetChannel and NetChannel.GetAvgLatency then
        latency = NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) or 0.03
    end
    
    local total_time = swing_time + flight_time + latency
    local current_hp = Entity.GetHealth(target)
    
    return {
        damage = true_damage,
        current_hp = current_hp,
        total_time = total_time,
        swing_time = swing_time,
        distance = distance,
        is_lethal = current_hp <= true_damage,
    }
end

--- Отслеживает динамику снижения HP крипа от союзных крипов (DPS входящего урона)
---@param target CNPC
---@param cur_time number
---@return number dps
local function UpdateCreepDPS(target, cur_time)
    local hp = Entity.GetHealth(target)
    local record = creep_health_cache[target]
    if not record then
        creep_health_cache[target] = { last_hp = hp, last_time = cur_time, dps = 0 }
        return 0
    end
    
    local dt = cur_time - record.last_time
    if dt >= 0.05 then
        local dhp = record.last_hp - hp
        if dhp > 0 then
            local instant_dps = dhp / dt
            record.dps = record.dps * 0.4 + instant_dps * 0.6
        elseif dhp < 0 then
            record.dps = 0
        else
            record.dps = record.dps * 0.8
        end
        record.last_hp = hp
        record.last_time = cur_time
    end
    return record.dps
end

--- Отдает приказ клону атаковать цель без сбития анимации
---@param clone CNPC
---@param player CPlayer
---@param target CNPC
---@param cur_time number
local function IssueCloneAttack(clone, player, target, cur_time)
    if not target or not IsAlive(target) then return end
    
    is_holding_fire = false
    
    if NPC.IsAttacking(clone) and last_ordered_target == target then
        return
    end
    
    if last_ordered_target == target and (cur_time - last_attack_time) < 0.12 then
        return
    end
    
    local anim_point = NPC.GetAttackAnimPoint(clone) or 0.3
    local attack_speed = NPC.GetAttackSpeed(clone) or 1.0
    if attack_speed <= 0 then attack_speed = 1.0 end
    local swing_time = anim_point / attack_speed
    
    attack_in_progress = {
        target = target,
        start_time = cur_time,
        swing_time = swing_time
    }
    
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
        target,
        Vector(0, 0, 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER
    )
    
    last_ordered_target = target
    last_attack_time = cur_time
end

--- Задерживает атаку клона в опасной зоне (Hold Position), чтобы не сбить ХП до стила союзниками
---@param clone CNPC
---@param player CPlayer
---@param cur_time number
local function HoldCloneAttack(clone, player, cur_time)
    if is_holding_fire then return end
    
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION,
        nil,
        Vector(0, 0, 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER
    )
    is_holding_fire = true
    last_ordered_target = nil
    attack_in_progress = nil
    last_attack_time = cur_time
end

--- Плавно ведет клона на дистанцию атаки к цели
---@param clone CNPC
---@param player CPlayer
---@param move_to_pos Vector
---@param cur_time number
local function MoveCloneTowards(clone, player, move_to_pos, cur_time)
    if (cur_time - last_move_time) < 0.22 then return end
    
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        move_to_pos,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER
    )
    is_holding_fire = false
    last_move_time = cur_time
end

---@param target CNPC
---@return Vector?
local function GetSparkCastPosition(target)
    if not target or not IsAlive(target) then return nil end
    return Entity.GetAbsOrigin(target)
end

local function TraceSparkOrder(clone, target, cast_pos, source)
    if not ui.debug:Get() or not ai_bridge or not ai_bridge.mcp_log then return end
    local target_pos = Entity.GetAbsOrigin(target)
    ai_bridge.mcp_log("info", "spark order", {
        event = "spark_order", source = source, time = GameRules.GetGameTime(),
        clone = Entity.GetIndex(clone), target = Entity.GetIndex(target),
        target_name = NPC.GetUnitName(target), running = NPC.IsRunning(target),
        target_position = { x = target_pos.x, y = target_pos.y, z = target_pos.z },
        cast_position = { x = cast_pos.x, y = cast_pos.y, z = cast_pos.z },
        offset = (cast_pos - target_pos):Length2D(),
    })
end

local function UpdateVisualRing(target)
    if not ui.draw_target:Get() or not target or not IsAlive(target) then
        if active_particle then
            Particle.Destroy(active_particle)
            active_particle = nil
            last_particle_target = nil
        end
        return
    end

    local effect_index = ui.target_effect:Get() or 0
    local particle_path = effect_index == 0
        and "particles/ui_mouseactions/range_finder_cp_color_creep.vpcf"
        or "particles/ui_mouseactions/selected_ring.vpcf"
    if last_particle_target ~= target or runtime.target_particle_path ~= particle_path then
        if active_particle then
            Particle.Destroy(active_particle)
            active_particle = nil
        end
        active_particle = Particle.Create(particle_path, Enum.ParticleAttachment.PATTACH_ABSORIGIN_FOLLOW, target)
        runtime.target_particle_path = particle_path
        last_particle_target = target
    end
    if active_particle then
        local color = ui.target_color:Get()
        local size = ui.target_size:Get() or 68
        Particle.SetControlPoint(active_particle, 0, Entity.GetAbsOrigin(target))
        Particle.SetControlPoint(active_particle, 1, Vector(color.r, color.g, color.b))
        Particle.SetControlPoint(active_particle, 2, Vector(size, 255, 255))
    end
end

local function UpdateFieldVisual(clone, plan)
    local show = ui.field_info:Get() and plan and (ui.field_mode:Get() == 1 or plan.castable)
    local show_radius = show and ui.show_field_radius:Get()
    if not show_radius then
        if runtime.field_particle then
            Particle.Destroy(runtime.field_particle)
            runtime.field_particle = nil
            runtime.field_particle_path = nil
        end
        return
    end

    local effect = ui.field_effect:Get()
    local path = effect == 0
        and "particles/ui_mouseactions/range_finder_cp_color_aoe.vpcf"
        or "particles/ui_mouseactions/drag_selected_ring.vpcf"
    if not runtime.field_particle or runtime.field_particle_path ~= path then
        if runtime.field_particle then Particle.Destroy(runtime.field_particle) end
        runtime.field_particle = Particle.Create(path, Enum.ParticleAttachment.PATTACH_WORLDORIGIN, clone)
        runtime.field_particle_path = path
    end
    local color = ui.field_radius_color:Get()
    if effect == 0 then
        Particle.SetControlPoint(runtime.field_particle, 2, plan.center)
        Particle.SetControlPoint(runtime.field_particle, 3, Vector(plan.radius, 0, 0))
        Particle.SetControlPoint(runtime.field_particle, 4, Vector(color.r, color.g, color.b))
    else
        Particle.SetControlPoint(runtime.field_particle, 0, plan.center)
        Particle.SetControlPoint(runtime.field_particle, 1, Vector(color.r, color.g, color.b))
        Particle.SetControlPoint(runtime.field_particle, 2, Vector(plan.radius, 255, 255))
    end
end

local function ClearVisuals()
    UpdateVisualRing(nil)
    if runtime.field_particle then
        Particle.Destroy(runtime.field_particle)
        runtime.field_particle = nil
        runtime.field_particle_path = nil
    end
end

local function DrawFieldCount()
    local plan = runtime.field_plan
    if not ui.enable:Get() or not ui.field_info:Get() or not ui.show_field_count:Get() or not plan then return end
    if ui.field_mode:Get() == 0 and not plan.castable then return end
    local screen, visible = Render.WorldToScreen(plan.center + Vector(0, 0, 45))
    if not visible then return end
    if not runtime.counter_font then
        runtime.counter_font = Render.LoadFont("SFProText-Heavy", Enum.FontCreate.FONTFLAG_ANTIALIAS, Enum.FontWeight.BOLD)
        if not runtime.counter_font or runtime.counter_font == 0 then
            runtime.counter_font = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, Enum.FontWeight.BOLD)
        end
    end
    local size = math.floor(44 + (ui.field_count_size:Get() or 58) * 0.9)
    local text = tostring(plan.count or 0)
    local bounds = Render.TextSize(runtime.counter_font, size, text)
    local pos = Vec2(math.floor(screen.x - bounds.x * 0.5), math.floor(screen.y - bounds.y * 0.5))
    local outline = math.max(3, math.floor(size * 0.055))
    local black = Color(0, 0, 0, 255)
    for _, offset in ipairs({
        Vec2(-outline, 0), Vec2(outline, 0), Vec2(0, -outline), Vec2(0, outline),
        Vec2(-outline, -outline), Vec2(outline, -outline),
        Vec2(-outline, outline), Vec2(outline, outline),
    }) do
        Render.Text(runtime.counter_font, size, text, pos + offset, black)
    end
    Render.Text(runtime.counter_font, size, text, pos, ui.field_count_color:Get())
end

local function IssueSparkCast(clone, player, spark, target, cur_time, source)
    local cast_pos = GetSparkCastPosition(target)
    if not cast_pos then return false end
    TraceSparkOrder(clone, target, cast_pos, source)
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        cast_pos,
        spark,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER
    )
    last_spark_time = cur_time
    last_spell_cast_time = cur_time
    spark_placed_time[target] = cur_time
    pending_spark_cast = {
        clone = clone,
        target = target,
        ability = spark,
        issued_at = cur_time,
        cast_pos = cast_pos,
    }
    return true
end

local function IssueFieldCast(clone, player, field, plan, cur_time, source)
    if not plan or not plan.castable then return false end
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        plan.center,
        field,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER
    )
    last_field_time = cur_time
    last_spell_cast_time = cur_time
    runtime.pending_field_cast = {
        clone = clone,
        field = field,
        center = plan.center,
        radius = plan.radius,
        count = plan.count,
        siege_count = plan.siege_count,
        kind = plan.kind,
        issued_at = cur_time,
        phase_seen = false,
    }
    if ui.debug:Get() and ai_bridge and ai_bridge.mcp_log then
        ai_bridge.mcp_log("info", "magnetic field order", {
            source = source,
            kind = plan.kind,
            count = plan.count,
            siege_count = plan.siege_count,
            x = plan.center.x,
            y = plan.center.y,
        })
    end
    return true
end

local function ClearPendingFieldCast()
    runtime.pending_field_cast = nil
end

local function UpdatePendingFieldCast(clone, cur_time)
    local pending = runtime.pending_field_cast
    if not pending then return false end
    if pending.clone ~= clone or not IsAlive(clone) then
        ClearPendingFieldCast()
        return false
    end

    local cooldown_ok, cooldown = pcall(Ability.GetCooldown, pending.field)
    if not cooldown_ok or type(cooldown) ~= "number" then
        ClearPendingFieldCast()
        return false
    end
    if cooldown > 0 then
        runtime.active_field = {
            clone = clone,
            center = pending.center,
            radius = pending.radius,
            count = pending.count,
            siege_count = pending.siege_count,
            kind = pending.kind,
            expires_at = cur_time + GetAbilityValue(pending.field, "duration", 4),
            require_entry = pending.kind == "tower",
        }
        ClearPendingFieldCast()
        return false
    end

    local phase_ok, in_phase = pcall(Ability.IsInAbilityPhase, pending.field)
    if not phase_ok or (pending.phase_seen and not in_phase) or (cur_time - pending.issued_at) >= 1.5 then
        ClearPendingFieldCast()
        return false
    end
    if in_phase then pending.phase_seen = true end
    return true
end

local function GetActiveField(clone, cur_time)
    local active = runtime.active_field
    if not active then return nil end
    if active.clone ~= clone or not IsAlive(clone) or cur_time >= active.expires_at then
        runtime.active_field = nil
        return nil
    end
    if not active.last_count_time or cur_time - active.last_count_time >= 0.15 then
        active.last_count_time = cur_time
        active.count = 0
        active.siege_count = 0
        local team = Entity.GetTeamNum(clone)
        for _, creep in ipairs(NPCs.GetAll(Enum.UnitTypeFlags.TYPE_LANE_CREEP) or {}) do
            if IsValidLaneCreep(creep, false) and Entity.GetTeamNum(creep) == team
                and (Entity.GetAbsOrigin(creep) - active.center):Length2D() <= active.radius then
                active.count = active.count + 1
                if IsSiegeCreep(creep) then active.siege_count = active.siege_count + 1 end
            end
        end
    end
    return active
end

local function ClampToActiveField(position, active)
    if not active or not active.require_entry then return position end
    local delta = position - active.center
    delta.z = 0
    local limit = math.max(active.radius - 70, 80)
    if delta:Length2D() <= limit then return position end
    return active.center + delta:Normalized() * limit
end

local function MoveIntoActiveField(clone, player, active, cur_time)
    if not active or not active.require_entry then return false end
    local clone_pos = Entity.GetAbsOrigin(clone)
    local delta = clone_pos - active.center
    delta.z = 0
    local inner_radius = math.max(active.radius - 70, 80)
    local distance = delta:Length2D()
    if distance <= inner_radius then return false end
    local time_left = active.expires_at - cur_time
    local travel_time = (distance - inner_radius) / math.max(NPC.GetMoveSpeed(clone) or 280, 1)
    if time_left <= travel_time + 0.15 then return false end
    local entry = active.center
    if distance > 1 then entry = active.center + delta:Normalized() * inner_radius end
    entry.z = clone_pos.z
    MoveCloneTowards(clone, player, entry, cur_time)
    return true
end

local function MoveIntoDeathFieldCastRange(clone, player, field, plan, remaining_life, cur_time)
    if not field or not plan or plan.kind ~= "death" or plan.castable then return false end
    if remaining_life > 6.0 or NPC.IsSilenced(clone)
        or not Ability.IsCastable(field, NPC.GetMana(clone)) then return false end

    local clone_pos = Entity.GetAbsOrigin(clone)
    local delta = clone_pos - plan.center
    delta.z = 0
    local distance = delta:Length2D()
    local cast_range = math.max((Ability.GetCastRange(field) or 900) - 65, 100)
    if distance <= cast_range then return false end

    local cast_lead = (Ability.GetCastPoint(field) or 0.3) + GetOutgoingLatency() + 0.12
    if remaining_life <= cast_lead then return false end
    local entry = plan.center
    if distance > 1 then entry = plan.center + delta:Normalized() * cast_range end
    entry.z = clone_pos.z
    MoveCloneTowards(clone, player, entry, cur_time)
    return true
end
--#endregion

local WavePusher = {}

---@param data table
local function ResetCloneState(clone)
    ClearVisuals()
    tracked_clone = clone
    incoming_damage = {}
    spark_placed_time = {}
    pending_spark_cast = nil
    creep_health_cache = {}
    attack_in_progress = nil
    last_ordered_target = nil
    active_priority_target = nil
    is_holding_fire = false
    is_in_attack_position = false
    runtime.locked_target = nil
    runtime.locked_kind = nil
    runtime.field_plan = nil
    runtime.active_field = nil
    runtime.pending_field_cast = nil
    runtime.last_field_plan_time = -math.huge
    runtime.ally_projectiles = {}
    runtime.spark_commitments = {}
    runtime.spark_followup_target = nil
    runtime.spark_followup_shot_required = false
    runtime.guaranteed_kill_wait = nil
    last_spark_time = -math.huge
    last_field_time = -math.huge
    last_attack_time = -math.huge
    last_move_time = -math.huge
    last_spell_cast_time = -math.huge
    last_hero_action_time = -math.huge
end

function WavePusher.OnPrepareUnitOrders(data)
    if not ui.enable:Get() then
        SyncNativeSpark(false)
        return true
    end
    if not data or data.identifier == ORDER_IDENTIFIER then return true end

    local hero = Heroes.GetLocal()
    if not hero or NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then return true end
    local cur_time = GameRules.GetGameTime()
    local hero_override = ui.hero_override:Get()

    if data.target and NPC.IsHero(data.target) and not Entity.IsSameTeam(hero, data.target) then
        last_hero_action_time = cur_time
        SyncNativeSpark(false)
        return true
    end
    if hero_override and data.position and IsEnemyHeroNear(data.position, 1200) then
        last_hero_action_time = cur_time
        SyncNativeSpark(false)
        return true
    end

    local clone = GetClone(hero)
    if not clone or data.npc ~= clone then return true end
    if hero_override and (IsComboActive() or IsEnemyHeroNear(clone, 1500)) then
        last_hero_action_time = cur_time
        SyncNativeSpark(false)
        return true
    end
    if (cur_time - last_hero_action_time) < 3.0 then
        SyncNativeSpark(false)
        return true
    end

    local active_field = GetActiveField(clone, cur_time)
    if active_field and active_field.require_entry then
        local destination = data.position
        if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET and data.target then
            destination = Entity.GetAbsOrigin(data.target)
        end
        if destination and (
            data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION
            or data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET
            or data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE
        ) and (destination - active_field.center):Length2D() > active_field.radius - 45 then
            return false
        end
    end

    local pending_field = runtime.pending_field_cast
    if pending_field and pending_field.clone == clone and (cur_time - pending_field.issued_at) < 1.5 then
        return false
    end

    if pending_spark_cast and pending_spark_cast.clone == clone
        and IsAlive(pending_spark_cast.target)
        and (cur_time - pending_spark_cast.issued_at) < 1.5 then
        return false
    end

    if data.ability then
        local ability_name = Ability.GetName(data.ability) or ""
        if ability_name == "arc_warden_spark_wraith" or ability_name == "arc_warden_spark_wraith_tempest" then
            local target = active_priority_target
            if not ui.spark_ranged:Get() then return true end
            if not target or not IsAlive(target) then
                return runtime.spark_followup_target == nil
            end
            local field = NPC.GetAbility(clone, "arc_warden_magnetic_field")
            local has_spark = target and spark_placed_time[target] and (cur_time - spark_placed_time[target]) < 4.5
            if runtime.locked_kind == "ranged" and is_in_attack_position
                and not has_spark and not NPC.IsSilenced(clone)
                and (cur_time - last_spark_time) > 1.2
                and ShouldUseSpark(clone, data.ability, target, field, runtime.field_plan, cur_time) then
                IssueSparkCast(clone, Players.GetLocal(), data.ability, target, cur_time, "intercept")
            end
            return false
        end
        if ability_name == "arc_warden_magnetic_field" or ability_name == "arc_warden_magnetic_field_tempest" then
            if ui.smart_position:Get() and runtime.field_plan and runtime.field_plan.castable
                and not NPC.IsSilenced(clone) and Ability.IsCastable(data.ability, NPC.GetMana(clone)) then
                IssueFieldCast(clone, Players.GetLocal(), data.ability, runtime.field_plan, cur_time, "intercept")
            end
            return not ui.smart_position:Get()
        end
        local farm_items = {
            item_hand_of_midas = true,
            item_mjollnir = true,
            item_shivas_guard = true,
            item_manta = true,
            item_phase_boots = true,
            item_demonicon = true,
            item_necronomicon = true,
            item_glimmer_cape = true,
            item_solar_crest = true,
            item_pavise = true,
        }
        if not farm_items[ability_name] then last_hero_action_time = cur_time end
        return true
    end

    if data.orderIssuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS then
        last_hero_action_time = cur_time
        SyncNativeSpark(false)
        return true
    end

    local target = active_priority_target and IsAlive(active_priority_target) and active_priority_target or nil
    local wait_target = runtime.guaranteed_kill_wait
    if wait_target then
        if not IsAlive(wait_target) or GetCreepKillPlan(clone, wait_target).remaining_hp > 0 then
            runtime.guaranteed_kill_wait = nil
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET and data.target == wait_target then
            return false
        end
    end
    if not target then return true end
    if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION
        or data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET
        or data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE then
        return false
    end
    if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET
        and data.target and NPC.IsLaneCreep(data.target) and data.target ~= target then
        return false
    end
    return true
end

function WavePusher.OnUpdate()
    if not ui.enable:Get() then
        SyncNativeSpark(false)
        ClearPendingSparkCast()
        ResetCloneState(nil)
        ClearVisuals()
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then
        SyncNativeSpark(false)
        ClearPendingSparkCast()
        ResetCloneState(nil)
        ClearVisuals()
        return
    end
    local clone = GetClone(hero)
    if not clone or not IsAlive(clone) or Entity.IsDormant(clone) then
        SyncNativeSpark(false)
        ClearPendingSparkCast()
        active_priority_target = nil
        ResetCloneState(nil)
        ClearVisuals()
        return
    end
    if tracked_clone ~= clone then ResetCloneState(clone) end

    local cur_time = GameRules.GetGameTime()
    local hero_override = ui.hero_override:Get()
    if hero_override and (IsComboActive() or IsEnemyHeroNear(clone, 1500)) then
        last_hero_action_time = cur_time
        active_priority_target = nil
        runtime.field_plan = nil
        SyncNativeSpark(false)
        ClearVisuals()
        return
    end
    if (cur_time - last_hero_action_time) < 3.0 then
        active_priority_target = nil
        runtime.field_plan = nil
        SyncNativeSpark(false)
        ClearVisuals()
        return
    end

    local channeling = NPC.IsChannellingAbility and NPC.IsChannellingAbility(clone) or false
    if not channeling then channeling = NPC.HasModifier(clone, "modifier_teleporting") end
    if NPC.IsStunned(clone) or channeling then
        active_priority_target = nil
        runtime.field_plan = nil
        SyncNativeSpark(false)
        ClearVisuals()
        return
    end

    local player = Players.GetLocal()
    local my_team = Entity.GetTeamNum(hero)
    local clone_pos = Entity.GetAbsOrigin(clone)
    local field = NPC.GetAbility(clone, "arc_warden_magnetic_field")
    local spark = NPC.GetAbility(clone, "arc_warden_spark_wraith")
    local remaining_life = GetCloneRemainingLife(clone)
    local active_field = GetActiveField(clone, cur_time)
    if active_field then
        runtime.field_plan = {
            center = active_field.center,
            radius = active_field.radius,
            count = active_field.count,
            siege_count = active_field.siege_count,
            castable = true,
            kind = "active",
        }
    elseif ui.smart_position:Get() and field and Ability.GetLevel(field) > 0 then
        RefreshFieldPlan(clone, field, my_team, cur_time, remaining_life)
    else
        runtime.field_plan = nil
    end
    UpdateFieldVisual(clone, runtime.field_plan)

    local owns_field = ui.smart_position:Get()
    SyncNativeControl(native_field, owns_field)

    for creep in pairs(spark_placed_time) do
        if not IsAlive(creep) then spark_placed_time[creep] = nil end
    end
    for creep in pairs(incoming_damage) do
        if not IsAlive(creep) then incoming_damage[creep] = nil else GetPendingDamage(creep, cur_time) end
    end
    for creep in pairs(creep_health_cache) do
        if not IsAlive(creep) then creep_health_cache[creep] = nil end
    end
    for creep in pairs(runtime.ally_projectiles) do
        if not IsAlive(creep) then runtime.ally_projectiles[creep] = nil else GetAlliedProjectileDamage(creep, cur_time + 8, cur_time) end
    end
    ReconcileSparkCommitments(clone, my_team, cur_time)

    if UpdatePendingFieldCast(clone, cur_time) then return end
    if UpdatePendingSparkCast(clone, cur_time) then return end
    if (cur_time - last_spell_cast_time) < 0.36 then return end

    local planned_field = runtime.field_plan
    local death_field_urgent = false
    local death_field_preposition = false
    if planned_field and planned_field.kind == "death" and field then
        local field_lead = (Ability.GetCastPoint(field) or 0.3) + GetOutgoingLatency()
        death_field_urgent = remaining_life <= field_lead + 1.15 and remaining_life > field_lead + 0.03
        death_field_preposition = not planned_field.castable and remaining_life <= 6.0
    end
    local followup = runtime.spark_followup_target
    if followup and (not IsAlive(followup) or Entity.IsDormant(followup)) then
        runtime.spark_followup_target = nil
        runtime.spark_followup_shot_required = false
        followup = nil
    end
    if followup and not death_field_urgent and not death_field_preposition then
        local followup_plan = GetCreepKillPlan(clone, followup)
        if not runtime.spark_followup_shot_required and followup_plan.attacks_needed <= 0 then
            runtime.spark_followup_target = nil
            runtime.guaranteed_kill_wait = followup
            HoldCloneAttack(clone, player, cur_time)
            return
        elseif not NPC.HasState(clone, Enum.ModifierState.MODIFIER_STATE_DISARMED) then
            local followup_range = math.max((NPC.GetAttackRange(clone) or 625) - 50, 100)
            local followup_pos = Entity.GetAbsOrigin(followup)
            local followup_distance = (followup_pos - clone_pos):Length2D()
            if followup_distance <= followup_range then
                IssueCloneAttack(clone, player, followup, cur_time)
            else
                local direction = clone_pos - followup_pos
                direction.z = 0
                if direction:Length2D() <= 1 then direction = Vector(0, -1, 0) else direction = direction:Normalized() end
                local walk_to = followup_pos + direction * math.max(followup_range - 70, 0)
                walk_to.z = clone_pos.z
                MoveCloneTowards(clone, player, walk_to, cur_time)
            end
            return
        end
    end
    if MoveIntoDeathFieldCastRange(clone, player, field, planned_field, remaining_life, cur_time) then return end
    if MoveIntoActiveField(clone, player, active_field, cur_time) then return end
    if attack_in_progress then
        if not IsAlive(attack_in_progress.target)
            or (cur_time - attack_in_progress.start_time) > attack_in_progress.swing_time + 0.35 then
            attack_in_progress = nil
        end
    end

    local plan = runtime.field_plan
    if not active_field and plan and field and plan.castable and not NPC.IsSilenced(clone)
        and Ability.IsCastable(field, NPC.GetMana(clone)) and (cur_time - last_field_time) > 1.0 then
        local should_cast = plan.kind == "tower"
        if plan.kind == "death" then
            local cast_point = Ability.GetCastPoint(field) or 0.3
            local lead = cast_point + GetOutgoingLatency()
            should_cast = remaining_life <= lead + 1.15 and remaining_life > lead + 0.03
                and plan.meeting_time <= GetAbilityValue(field, "duration", 4) - lead
        end
        if should_cast and IssueFieldCast(clone, player, field, plan, cur_time, "update") then return end
    end

    local ranged_creeps, flagbearer, any_lane_creep = GetWaveCreeps(clone, my_team)
    if not any_lane_creep then
        active_priority_target = nil
        runtime.locked_target = nil
        runtime.locked_kind = nil
        SyncNativeControl(native_spark, false)
        UpdateVisualRing(nil)
        is_in_attack_position = false
        return
    end

    local target, target_kind = SelectPriorityTarget(clone, ranged_creeps, flagbearer)
    active_priority_target = target
    local wait_target = runtime.guaranteed_kill_wait
    if wait_target and (not IsAlive(wait_target) or GetCreepKillPlan(clone, wait_target).remaining_hp > 0) then
        runtime.guaranteed_kill_wait = nil
        wait_target = nil
    end
    local owns_priority_spark = ui.spark_ranged:Get() and (target ~= nil or wait_target ~= nil)
    SyncNativeControl(native_spark, owns_priority_spark)
    if not target then
        UpdateVisualRing(nil)
        is_in_attack_position = true
        return
    end
    UpdateVisualRing(target)

    local attack_range = NPC.GetAttackRange(clone) or 625
    local safe_attack_range = math.max(attack_range - 50, 100)
    local target_pos = Entity.GetAbsOrigin(target)
    local distance = (target_pos - clone_pos):Length2D()
    if distance > safe_attack_range then
        is_in_attack_position = false
        local direction = clone_pos - target_pos
        direction.z = 0
        if direction:Length2D() <= 1 then direction = Vector(0, -1, 0) else direction = direction:Normalized() end
        local walk_to = target_pos + direction * math.max(safe_attack_range - 70, 0)
        walk_to = ClampToActiveField(walk_to, active_field)
        walk_to.z = clone_pos.z
        MoveCloneTowards(clone, player, walk_to, cur_time)
        return
    end
    is_in_attack_position = true

    local disarmed = NPC.HasState(clone, Enum.ModifierState.MODIFIER_STATE_DISARMED)
    if target_kind == "ranged" then
        local has_spark = spark_placed_time[target] and (cur_time - spark_placed_time[target]) < 4.5
        if not has_spark and ui.spark_ranged:Get() and not NPC.IsSilenced(clone)
            and (cur_time - last_spark_time) > 1.2
            and ShouldUseSpark(clone, spark, target, field, runtime.field_plan, cur_time) then
            if IssueSparkCast(clone, player, spark, target, cur_time, "update") then return end
        end
        local kill_plan = GetCreepKillPlan(clone, target)
        if kill_plan.attacks_needed <= 0 then
            runtime.guaranteed_kill_wait = target
            HoldCloneAttack(clone, player, cur_time)
        elseif not disarmed then
            IssueCloneAttack(clone, player, target, cur_time)
        end
        return
    end

    if target_kind == "flag" and not disarmed then
        local last_hit = CalculateLastHit(clone, target)
        if not last_hit then return end
        local lead = (ui.attack_lead:Get() or 40) / 1000
        local projectile_damage = GetAlliedProjectileDamage(target, cur_time + last_hit.total_time + lead, cur_time)
        local dps = UpdateCreepDPS(target, cur_time)
        local predicted_hp = last_hit.current_hp - projectile_damage - dps * (last_hit.total_time + lead)
        if last_hit.is_lethal or predicted_hp <= last_hit.damage
            or dps < 20
            or (last_hit.current_hp > last_hit.damage * 2 and predicted_hp > last_hit.damage * 1.8) then
            IssueCloneAttack(clone, player, target, cur_time)
        else
            HoldCloneAttack(clone, player, cur_time)
        end
    end
end

---@param data table
function WavePusher.OnProjectile(data)
    if not ui.enable:Get() then return end
    if not data or not data.source or not data.target or not data.isAttack then return end
    if not IsAlive(data.target) or not NPC.IsLaneCreep(data.target) then return end

    local hero = Heroes.GetLocal()
    if not hero or NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then return end
    local clone = GetClone(hero)
    if not clone then return end

    local source = data.source
    local target = data.target
    local cur_time = GameRules.GetGameTime()
    local speed = data.moveSpeed or NPC.GetAttackProjectileSpeed(source) or 900
    if speed <= 0 then speed = 900 end
    local distance = (Entity.GetAbsOrigin(target) - Entity.GetAbsOrigin(source)):Length2D()
    local impact_at = cur_time + distance / speed
    if type(data.maxImpactTime) == "number" and data.maxImpactTime > cur_time and data.maxImpactTime < cur_time + 8 then
        impact_at = math.min(impact_at, data.maxImpactTime)
    end
    local damage = math.max(0, (NPC.GetTrueDamage(source) or 0) * (NPC.GetArmorDamageMultiplier(target) or 1))

    if source == clone then
        AddPendingDamage(target, damage, impact_at + GetOutgoingLatency() + 0.12)
        if runtime.spark_followup_target == target then
            runtime.spark_followup_shot_required = false
        end
        if attack_in_progress and attack_in_progress.target == target then attack_in_progress = nil end
        return
    end
    if Entity.GetTeamNum(source) == Entity.GetTeamNum(hero)
        and NPC.IsLaneCreep(source) and Entity.GetTeamNum(target) ~= Entity.GetTeamNum(hero) then
        local shots = runtime.ally_projectiles[target] or {}
        shots[#shots + 1] = {
            damage = damage,
            impact_at = impact_at,
            handle = data.handle,
        }
        runtime.ally_projectiles[target] = shots
    end
end

function WavePusher.OnDraw()
    DrawFieldCount()
end

function WavePusher.OnUpdateEx()
    if not Engine.IsInGame() or not ui.enable:Get() or not ui.spark_ranged:Get() then
        SyncNativeSpark(false)
        return
    end
    local hero = Heroes.GetLocal()
    if not IsAlive(hero) or NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then
        SyncNativeSpark(false)
        return
    end
    if not IsAlive(GetClone(hero)) then
        SyncNativeSpark(false)
    end
end

function WavePusher.OnGameEnd()
    SyncNativeSpark(false)
    ClearPendingSparkCast()
    runtime.field_plan = nil
    runtime.spark_commitments = {}
    runtime.ally_projectiles = {}
    runtime.locked_target = nil
    ClearVisuals()
end

return WavePusher
