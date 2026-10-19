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
		pta_group_main = "Main",
		pta_enable = "Enable",
		pta_enable_tip = "If a spell lacks mana but Intelligence on\nPower Treads covers it, switches and casts it",
	},
	ru = {
		pta_group_main = "Основное",
		pta_enable = "Включить",
		pta_enable_tip = "Если маны на способность не хватает, а с интеллектом\nна Power Treads хватит, переключает PT и кастует",
	},
})

local UI = localization.WrapLibrary(Menu)

local ui = {}

do
	local tab = UI.Create("General", "Main", "PT Abuse")
	tab:Image("panorama/images/items/power_treads_png.vtex_c")

	local page = tab:Create("Settings")
	local g_main = page:Create("pta_group_main", Enum.GroupSide.Left)

	ui.enable = g_main:Switch("pta_enable", true, "\u{f011}")
	ui.enable:ToolTip("pta_enable_tip")
end

local cfg = Config
local CFG_NAME = "pt_mana_abuse"

local ATTR = Enum.Attributes
local INT = ATTR.DOTA_ATTRIBUTE_INTELLECT
local CYCLE_NEXT = {
	[ATTR.DOTA_ATTRIBUTE_STRENGTH] = INT,
	[INT] = ATTR.DOTA_ATTRIBUTE_AGILITY,
	[ATTR.DOTA_ATTRIBUTE_AGILITY] = ATTR.DOTA_ATTRIBUTE_STRENGTH,
}
local MANA_PER_INT = 12
local HIGHLIGHT_INTERVAL = 0.1
local CURSOR_PICK_RADIUS = 200
local BC = Enum.ButtonCode
local AB = Enum.AbilityBehavior
local MS = Enum.ModifierState
local O = Enum.UnitOrder
local CAST_ORDERS = {
	[O.DOTA_UNIT_ORDER_CAST_POSITION] = true,
	[O.DOTA_UNIT_ORDER_CAST_TARGET] = true,
	[O.DOTA_UNIT_ORDER_CAST_TARGET_TREE] = true,
	[O.DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
	[O.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION] = true,
}
local CANCEL_ORDERS = {
	[O.DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
	[O.DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
	[O.DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
	[O.DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
	[O.DOTA_UNIT_ORDER_STOP] = true,
	[O.DOTA_UNIT_ORDER_HOLD_POSITION] = true,
}

local KEY_NAMES = {}
for name, code in pairs(BC) do
	local short = name:match("^KEY_(.+)$")
	if short then KEY_NAMES[code] = short end
end

local state = {
	phase = "idle",
	phase_time = 0,
	ability = nil,
	code = nil,
	original = nil,
	cost = 0,
	mana_before = 0,
	retried = false,
	restore_try = -1,
	cancelled = false,
	cast_ordered = false,
	last_highlight = 0,
	highlight_sig = "",
}

local learn = {
	ability = nil,
	key = nil,
	code = nil,
	time = 0,
	down_frame = -1,
	up_frame = -1,
	click_frame = -1,
	repeated = false,
}

local function now()
	return GameRules.GetGameTime()
end

local function frame()
	return GlobalVars.GetFrameCount()
end

local function set_phase(phase)
	if state.phase ~= phase then
		state.phase = phase
		state.phase_time = now()
	end
end

local function reset()
	state.ability = nil
	state.code = nil
	set_phase("idle")
end

local function is_quick(key)
	return cfg.ReadInt(CFG_NAME, "mode_" .. key, 1) == 1
end

local function remember_mode(key, quick)
	if is_quick(key) ~= quick then
		cfg.WriteInt(CFG_NAME, "mode_" .. key, quick and 1 or 0)
	end
end

local function can_toggle(hero)
	return not NPC.IsStunned(hero)
		and not NPC.HasState(hero, MS.MODIFIER_STATE_HEXED)
		and not NPC.HasState(hero, MS.MODIFIER_STATE_MUTED)
		and not NPC.HasState(hero, MS.MODIFIER_STATE_COMMAND_RESTRICTED)
end

local function toggle_to(pt, from, to)
	local stat, clicks = from, 0
	while stat ~= to and clicks < 2 do
		stat = CYCLE_NEXT[stat]
		clicks = clicks + 1
	end
	if stat ~= to then return end
	for _ = 1, clicks do
		Ability.CastNoTarget(pt, false, false, true)
	end
end

local function mana_with_int(hero, pt)
	local mana = NPC.GetMana(hero)
	local max_mana = NPC.GetMaxMana(hero)
	if max_mana <= 0 then return mana end
	local bonus = Ability.GetLevelSpecialValueFor(pt, "bonus_stat") * MANA_PER_INT
	return mana * (max_mana + bonus) / max_mana
end

local function usable(hero, ability)
	return not Ability.IsPassive(ability)
		and not Ability.IsHidden(ability)
		and Ability.GetLevel(ability) > 0
		and Ability.GetCooldown(ability) <= 0
		and not NPC.IsSilenced(hero)
end

local function lacks_only_mana(hero, ability, mana_after)
	if not usable(hero, ability) then return false end
	local cost = Ability.GetManaCost(ability)
	return cost > 0 and NPC.GetMana(hero) < cost and mana_after >= cost
end

local function ability_for_key(hero, code)
	local name = KEY_NAMES[code]
	if not name then return nil end
	for i = 0, 23 do
		local ability = NPC.GetAbilityByIndex(hero, i)
		if ability and not Ability.IsHidden(ability) then
			local bind = Ability.GetKeybind(ability)
			if bind and bind:upper() == name then
				return ability, name
			end
		end
	end
	return nil
end

local function has_flag(value, flag)
	return value & flag ~= 0
end

local function needs_target(ability)
	local behavior = Ability.GetBehavior(ability)
	return has_flag(behavior, AB.DOTA_ABILITY_BEHAVIOR_POINT)
		or has_flag(behavior, AB.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
end

local function unit_at_cursor(hero, ability)
	local TT = Enum.TargetTeam
	local team = Ability.GetTargetTeam(ability)
	local kind = Enum.TeamType.TEAM_BOTH
	if team == TT.DOTA_UNIT_TARGET_TEAM_ENEMY then
		kind = Enum.TeamType.TEAM_ENEMY
	elseif team == TT.DOTA_UNIT_TARGET_TEAM_FRIENDLY then
		kind = Enum.TeamType.TEAM_FRIEND
	end
	local unit = Input.GetNearestUnitToCursor(Entity.GetTeamNum(hero), kind)
	if unit and Entity.GetAbsOrigin(unit):Distance2D(Input.GetWorldCursorPos()) <= CURSOR_PICK_RADIUS then
		return unit
	end
	return nil
end

local function quick_cast(hero, ability)
	local behavior = Ability.GetBehavior(ability)
	local point = has_flag(behavior, AB.DOTA_ABILITY_BEHAVIOR_POINT)
	local unit_target = has_flag(behavior, AB.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
	if not point and not unit_target then
		Ability.CastNoTarget(ability)
		return true
	end
	if unit_target then
		local unit = unit_at_cursor(hero, ability)
		if unit then
			Ability.CastTarget(ability, unit)
			return true
		end
	end
	if point then
		Ability.CastPosition(ability, Input.GetWorldCursorPos())
		return true
	end
	return false
end

local function run_hud(js)
	if not Engine.RunScript(js, "Hud") then
		Engine.RunScript(js, "DotaHud")
	end
end

local function open_targeting(hero, ability)
	run_hud(string.format("Abilities.ExecuteAbility(%d, %d, false);",
		Entity.GetIndex(ability), Entity.GetIndex(hero)))
end

local HUD_JS = [[
(function() {
	var ok = {%s};
	var root = $.GetContextPanel().FindChildTraverse("abilities");
	if (!root) return;
	for (var i = 0; i < root.GetChildCount(); i++) {
		var slot = root.GetChild(i);
		var img = slot && slot.FindChildTraverse("AbilityImage");
		if (!img) continue;
		var lit = ok[img.abilityname] === 1;
		img.style.saturation = lit ? "1" : null;
		img.style.washColor = lit ? "#00000000" : null;
		img.style.contrast = lit ? "1" : null;
		var bevel = slot.FindChildTraverse("AbilityBevel");
		if (bevel) bevel.style.washColor = lit ? "#00000000" : null;
		var button = slot.FindChildTraverse("AbilityButton");
		if (button) button.style.preTransformScale2d = lit ? "1" : null;
	}
})();]]

local function update_highlight(hero, pt)
	local names = {}
	if hero and pt and ui.enable:Get()
		and PowerTreads.GetStats(pt) ~= INT and can_toggle(hero) then
		local mana_after = mana_with_int(hero, pt)
		for i = 0, 23 do
			local ability = NPC.GetAbilityByIndex(hero, i)
			if ability and lacks_only_mana(hero, ability, mana_after) then
				names[#names + 1] = Ability.GetName(ability)
			end
		end
		table.sort(names)
	end
	local sig = table.concat(names, ",")
	if sig == state.highlight_sig then return end
	state.highlight_sig = sig
	local parts = {}
	for _, name in ipairs(names) do
		parts[#parts + 1] = string.format('"%s":1', name)
	end
	run_hud(string.format(HUD_JS, table.concat(parts, ",")))
end

local function restore()
	state.restore_try = -1
	set_phase("restoring")
end

local function tick_restore(hero, pt)
	local stat = PowerTreads.GetStats(pt)
	if state.original == INT or stat == state.original or now() - state.phase_time > 10 then
		reset()
	elseif can_toggle(hero) and now() - state.restore_try > 0.3 then
		state.restore_try = now()
		toggle_to(pt, stat, state.original)
	end
end

local function tick(hero, pt)
	local ability = state.ability
	local t = now() - state.phase_time
	local spent = Ability.GetCooldown(ability) > 0
		or NPC.GetMana(hero) < state.mana_before - state.cost * 0.5

	if state.phase == "restoring" then
		tick_restore(hero, pt)
	elseif spent then
		restore()
	elseif state.phase == "switching" then
		if PowerTreads.GetStats(pt) == INT and NPC.GetMana(hero) >= state.cost then
			open_targeting(hero, ability)
			state.cast_ordered = false
			state.cancelled = false
			set_phase("aiming")
		elseif t > 0.5 then
			restore()
		end
	elseif state.phase == "aiming" then
		local targeting = Player.GetActiveAbility(Players.GetLocal()) == ability
		if Ability.IsInAbilityPhase(ability) or NPC.IsChannellingAbility(hero) then
			set_phase("casting")
		elseif state.cancelled or (t > 0.3 and not targeting and not state.cast_ordered) or t > 15 then
			restore()
		end
	elseif state.phase == "ordered" then
		if Ability.IsInAbilityPhase(ability) or NPC.IsChannellingAbility(hero) then
			set_phase("casting")
		elseif state.cancelled or t > 6 then
			restore()
		elseif not state.retried and t > 0.15 and not NPC.IsRunning(hero)
			and PowerTreads.GetStats(pt) == INT and NPC.GetMana(hero) >= state.cost then
			state.retried = true
			quick_cast(hero, ability)
		end
	elseif state.phase == "casting" then
		if (t > 0.1 and not Ability.IsInAbilityPhase(ability)) or t > 4 then
			restore()
		end
	end
end

local function start_abuse(hero, pt, ability, key, code)
	local stat = PowerTreads.GetStats(pt)
	if state.phase ~= "restoring" then
		state.original = stat
	end
	state.ability = ability
	state.code = code
	state.cost = Ability.GetManaCost(ability)
	state.mana_before = NPC.GetMana(hero)
	state.retried = false
	state.cancelled = false

	toggle_to(pt, stat, INT)
	if is_quick(key) and quick_cast(hero, ability) then
		set_phase("ordered")
	else
		set_phase("switching")
	end
end

local function start_learn(ability, key, code)
	if learn.ability == ability and now() - learn.time < 1 then
		learn.repeated = true
		return
	end
	learn.ability = ability
	learn.key = key
	learn.code = code
	learn.time = now()
	learn.down_frame = frame()
	learn.up_frame = -1
	learn.click_frame = -1
	learn.repeated = false
end

local script = {}

function script.OnUpdate()
	local hero = Heroes.GetLocal()
	if not hero then return end
	local pt = NPC.GetItem(hero, "item_power_treads", true)

	if learn.ability and now() - learn.time > 10 then
		learn.ability = nil
	end

	if state.phase ~= "idle" then
		if not ui.enable:Get() or not pt or not Entity.IsAlive(hero) or not state.ability then
			reset()
		else
			tick(hero, pt)
		end
	end

	if now() - state.last_highlight >= HIGHLIGHT_INTERVAL then
		state.last_highlight = now()
		update_highlight(Entity.IsAlive(hero) and hero or nil, pt)
	end
end

function script.OnKeyEvent(data)
	if not ui.enable:Get() then return true end
	local code = data.key

	if data.event == Enum.EKeyEvent.EKeyEvent_KEY_UP then
		if learn.ability and code == learn.code then
			learn.up_frame = frame()
		end
		return true
	end
	if data.event ~= Enum.EKeyEvent.EKeyEvent_KEY_DOWN then return true end

	if code == BC.KEY_MOUSE1 then
		learn.click_frame = frame()
		return true
	end
	if state.phase == "switching" or state.phase == "ordered" then
		return code ~= state.code
	end
	if Input.IsInputCaptured() then return true end

	local hero = Heroes.GetLocal()
	if not hero or not Entity.IsAlive(hero) then return true end
	local ability, key = ability_for_key(hero, code)
	if not ability then return true end

	local pt = NPC.GetItem(hero, "item_power_treads", true)
	if (state.phase == "idle" or state.phase == "restoring") and pt and can_toggle(hero) and PowerTreads.GetStats(pt) ~= INT
		and lacks_only_mana(hero, ability, mana_with_int(hero, pt)) then
		start_abuse(hero, pt, ability, key, code)
		return false
	end

	if usable(hero, ability) and needs_target(ability) and NPC.GetMana(hero) >= Ability.GetManaCost(ability) then
		start_learn(ability, key, code)
	end
	return true
end

function script.OnPrepareUnitOrders(data)
	local hero = Heroes.GetLocal()
	if not hero or data.npc ~= hero then return true end
	local order = data.order

	if learn.ability and data.ability == learn.ability and CAST_ORDERS[order] then
		if not learn.repeated then
			local f = frame()
			local instant = f == learn.down_frame or f == learn.up_frame
			remember_mode(learn.key, instant and f ~= learn.click_frame)
		end
		learn.ability = nil
	end

	if state.phase == "aiming" and data.ability == state.ability and CAST_ORDERS[order] then
		state.cast_ordered = true
	elseif (state.phase == "aiming" or state.phase == "ordered") and CANCEL_ORDERS[order] then
		state.cancelled = true
	end
	return true
end

function script.OnGameEnd()
	reset()
	learn.ability = nil
	state.highlight_sig = ""
end

function script.OnScriptsLoaded()
	reset()
end

return script
