local script = {}

local HERO_NAME = "npc_dota_hero_arc_warden"
local TEMPEST_MODIFIER = "modifier_arc_warden_tempest_double"
local PIKE_NAME = "item_hurricane_pike"
local ORDER_IDENTIFIER = "pika_arc_clone_pike"
local TEMPEST_ABILITY = "arc_warden_tempest_double"
local PENDING_CLONE_TIMEOUT = 8

local MENU_PATH = {
    "Heroes",
    "Hero List",
    "Arc Warden",
    "Main Settings",
    "Utility",
}

local controls = Menu.Find(
    MENU_PATH[1],
    MENU_PATH[2],
    MENU_PATH[3],
    MENU_PATH[4],
    MENU_PATH[5]
)

local function get_or_create_bind(name)
    local bind = Menu.Find(
        MENU_PATH[1],
        MENU_PATH[2],
        MENU_PATH[3],
        MENU_PATH[4],
        MENU_PATH[5],
        name
    )
    if bind then
        return bind
    end

    if not controls then
        return nil
    end

    return controls:Bind(name, Enum.ButtonCode.KEY_NONE, "\u{f11c}")
end

local pike_bind = get_or_create_bind("Save by clone")
if pike_bind then pike_bind:ShowInBindIsland(false) end
local pike_gear = pike_bind and pike_bind:Gear("Settings")

local function get_or_create_gear_bind(name)
    local bind = Menu.Find(
        MENU_PATH[1],
        MENU_PATH[2],
        MENU_PATH[3],
        MENU_PATH[4],
        MENU_PATH[5],
        "Save by clone",
        "Settings",
        name
    )
    if bind then
        return bind
    end

    if not pike_gear then
        return nil
    end

    return pike_gear:Bind(name, Enum.ButtonCode.KEY_NONE, "\u{f11c}")
end

local spawn_and_pike_bind = get_or_create_gear_bind("Spawn clone and save")
if spawn_and_pike_bind then spawn_and_pike_bind:ShowInBindIsland(false) end
local bind_states = {
    pike = pike_bind and pike_bind:IsDown() or false,
    spawn_and_pike = spawn_and_pike_bind and spawn_and_pike_bind:IsDown() or false,
}
local pending_spawn = nil

if pike_bind then
    pike_bind:ToolTip("On press, the Tempest Double casts Hurricane Pike on the original Arc Warden.")
end
if spawn_and_pike_bind then
    spawn_and_pike_bind:ToolTip("On press, cast Tempest Double, wait for it to spawn, then cast Pike on the original Arc Warden.")
end

local function log(message)
    if Log and Log.Write then
        Log.Write("[Pike Arc] " .. message)
    end
end

local function get_tempest_double(original)
    local fallback = nil

    for _, hero in ipairs(Heroes.GetAll()) do
        if hero ~= original
            and NPC.GetUnitName(hero) == HERO_NAME
            and Entity.IsSameTeam(hero, original)
            and Entity.IsAlive(hero)
            and not Entity.IsDormant(hero)
            and NPC.IsIllusion(hero) then
            if NPC.HasModifier(hero, TEMPEST_MODIFIER) then
                return hero
            end

            if NPC.GetItem(hero, PIKE_NAME, true) then
                fallback = hero
            end
        end
    end

    return fallback
end

local function cast_pike_on_original(original, clone)
    local pike = NPC.GetItem(clone, PIKE_NAME, true)
    if not pike then
        return false, "Tempest Double has no Hurricane Pike in its active inventory."
    end

    if not Ability.IsCastable(pike, NPC.GetMana(clone)) then
        return false, "Tempest Double's Hurricane Pike is not ready."
    end

    local player = Players.GetLocal()
    if not player then
        return false, "Local player handle is unavailable."
    end

    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
        original,
        Entity.GetAbsOrigin(original),
        pike,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        clone,
        false,
        false,
        false,
        true,
        ORDER_IDENTIFIER,
        false
    )
    return true
end

local function cast_tempest_double(original, now)
    local ability = NPC.GetAbility(original, TEMPEST_ABILITY)
    if not ability then
        log("Tempest Double ability not found.")
        return false
    end
    if not Ability.IsCastable(ability, NPC.GetMana(original)) then
        log("Tempest Double ability is not ready.")
        return false
    end

    local player = Players.GetLocal()
    if not player then
        log("Local player handle is unavailable.")
        return false
    end

    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        Entity.GetAbsOrigin(original),
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        original,
        false,
        false,
        false,
        true,
        "pika_arc_spawn_tempest",
        false
    )
    pending_spawn = { deadline = now + PENDING_CLONE_TIMEOUT }
    log("Tempest Double cast order sent; waiting for clone.")
    return true
end

local function was_pressed(bind, state_key)
    if not bind then return false end

    local is_down = bind:IsDown()
    local pressed = is_down and not bind_states[state_key]
    bind_states[state_key] = is_down
    return pressed
end

function script.OnUpdate()
    local pike_pressed = was_pressed(pike_bind, "pike")
    local spawn_pressed = was_pressed(spawn_and_pike_bind, "spawn_and_pike")
    if not pike_pressed and not spawn_pressed and not pending_spawn then
        return
    end

    local original = Heroes.GetLocal()
    if not original or NPC.GetUnitName(original) ~= HERO_NAME then
        if spawn_pressed or pike_pressed then
            log("Local hero is not Arc Warden.")
        end
        pending_spawn = nil
        return
    end

    if not Entity.IsAlive(original) then
        if spawn_pressed or pike_pressed or pending_spawn then
            log("Original Arc Warden is dead.")
        end
        pending_spawn = nil
        return
    end

    local now = GameRules.GetGameTime()
    local clone = get_tempest_double(original)

    if pending_spawn then
        if clone then
            local ok, reason = cast_pike_on_original(original, clone)
            if ok then
                log("Tempest Double spawned; Pike cast order sent to original Arc Warden.")
            else
                log(reason)
            end
            pending_spawn = nil
        elseif now >= pending_spawn.deadline then
            log("Timed out waiting for Tempest Double.")
            pending_spawn = nil
        end
        return
    end

    if pike_pressed then
        if not clone then
            log("Living Tempest Double not found.")
            return
        end

        local ok, reason = cast_pike_on_original(original, clone)
        if ok then
            log("Pike cast order sent from Tempest Double to original Arc Warden.")
        else
            log(reason)
        end
        return
    end

    if spawn_pressed then
        if clone then
            local ok, reason = cast_pike_on_original(original, clone)
            if ok then
                log("Tempest Double already exists; Pike cast order sent to original Arc Warden.")
            else
                log(reason)
            end
            return
        end
        cast_tempest_double(original, now)
    end
end

return script