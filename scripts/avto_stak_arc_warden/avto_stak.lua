--[[
  Arc Warden — Clone Auto Stack + Midas
  Umbrella / UC.Zone API v2

  Меню:
    Heroes → Hero List → Arc Warden → AW Helper
      ├─ Основные
      └─ Авто стак клоном
]]

local AWHelper = {}

--------------------------------------------------------------------------------
-- Конфиг
--------------------------------------------------------------------------------
local CFG = {
    STACK_START = 53.0,
    STACK_END   = 55.5,
    CAMP_RADIUS = 420,
    PULL_DIST   = 720,
    MIDAS_RANGE = 700,
}

-- Координаты нейтральных кемпов (подправь под карту при необходимости)
local CAMPS = {
    Vector(-1860,  420, 0),
    Vector(-3060,  200, 0),
    Vector(-4350,  800, 0),
    Vector(-4200, -400, 0),
    Vector(-2800,-1200, 0),
    Vector( -500,-3300, 0),
    Vector(  100,-4600, 0),
    Vector(  860,-4200, 0),
    Vector( 1800, -300, 0),
    Vector( 3000, -150, 0),
    Vector( 4200, -700, 0),
    Vector( 4100,  450, 0),
    Vector( 2700, 1100, 0),
    Vector(  400, 3200, 0),
    Vector( -100, 4500, 0),
    Vector( -800, 4100, 0),
}

--------------------------------------------------------------------------------
-- Состояние
--------------------------------------------------------------------------------
local state = {
    clone      = nil,
    phase      = "idle", -- idle / go1 / stack1 / go2 / stack2 / midas / done
    camp1      = nil,
    camp2      = nil,
    stackDone1 = false,
    stackDone2 = false,
    lastOrder  = 0,
    jobToken   = 0,      -- чтобы не перезапускать один и тот же клон
}

--------------------------------------------------------------------------------
-- Меню Umbrella
--------------------------------------------------------------------------------
local UI = nil

local function BuildUI(tab)
    if not tab or not tab.Create then return nil end

    local main  = tab:Create("Основные")
    local stack = tab:Create("Авто стак клоном")

    return {
        -- Основные
        Enabled     = main:Switch("Включить скрипт", true),
        Debug       = main:Switch("Логи в консоль", false),

        -- Авто стак клоном
        StackEnabled   = stack:Switch("Авто стак после ульты", true),
        StackCamps     = stack:Slider("Сколько кемпов", 1, 2, 2, "%d"),
        OnlyAllyJungle = stack:Switch("Только свой лес", true),
        MidasAfter     = stack:Switch("Мидас после стака", true),
        StackStart     = stack:Slider("Окно стака от (сек)", 50, 56, 53, "%d"),
        StackEnd       = stack:Slider("Окно стака до (сек)", 52, 58, 55, "%d"),
        ManualStack    = stack:Bind("Стак вручную (бинп)", Enum.ButtonCode.KEY_NONE),
    }
end

local function InitMenu()
    local ok, section = pcall(function()
        return Menu.Find("Heroes", "Hero List", "Arc Warden")
    end)

    if ok and section and section.Create then
        local tab = section:Create("AW Helper")
        if tab then
            local ui = BuildUI(tab)
            if ui then return ui end
        end
    end

    -- fallback
    local root = Menu.Create("Общее", "AW Helper", "aw_helper")
    if root and root.Create then
        return BuildUI(root)
    end
    return nil
end

UI = InitMenu()

--------------------------------------------------------------------------------
-- Утилиты
--------------------------------------------------------------------------------
local function Log(msg)
    if UI and UI.Debug and UI.Debug:Get() then
        Log.Write("[AW] " .. tostring(msg))
    end
end

local function IsAW()
    local h = Heroes.GetLocal()
    return h and NPC.GetUnitName(h) == "npc_dota_hero_arc_warden"
end

local function GetHero()
    local h = Heroes.GetLocal()
    if h and Entity.IsAlive(h) then return h end
    return nil
end

local function SecOfMinute()
    local t = (GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    return t % 60
end

local function MyTeam()
    local h = GetHero()
    if not h then return 2 end
    return Entity.GetTeamNum(h)
end

-- Radiant = низ карты (y < 0 чаще лес снизу), Dire = верх. Грубый фильтр «свой лес».
local function IsAllyCamp(campPos)
    if not UI or not UI.OnlyAllyJungle or not UI.OnlyAllyJungle:Get() then
        return true
    end
    local team = MyTeam()
    -- TEAM_RADIANT обычно 2, DIRE 3
    if team == 2 then
        return campPos:GetY() < 500  -- radiant-ish
    else
        return campPos:GetY() > -500
    end
end

local function OrderMove(unit, pos)
    local player = Players.GetLocal()
    if not player or not unit or not pos then return end
    pcall(function()
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil, pos, nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            unit, false, false, false, false
        )
    end)
end

local function OrderAttackMove(unit, pos)
    local player = Players.GetLocal()
    if not player or not unit or not pos then return end
    pcall(function()
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
            nil, pos, nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            unit, false, false, false, false
        )
    end)
end

local function FindClone()
    local me = GetHero()
    if not me then return nil end

    if Hero.GetTempestDouble then
        local c = Hero.GetTempestDouble(me)
        if c and Entity.IsAlive(c) then return c end
    end

    local pool = {}
    if Heroes.GetAll then
        for _, h in pairs(Heroes.GetAll() or {}) do
            table.insert(pool, h)
        end
    end
    if Entity.GetUnitsInRadius then
        for _, u in pairs(Entity.GetUnitsInRadius(me, 3500, Enum.TeamType.TEAM_FRIEND) or {}) do
            table.insert(pool, u)
        end
    end

    for _, u in pairs(pool) do
        if u and u ~= me and Entity.IsAlive(u)
            and NPC.GetUnitName(u) == "npc_dota_hero_arc_warden"
            and NPC.HasModifier(u, "modifier_arc_warden_tempest_double")
        then
            return u
        end
    end
    return nil
end

local function NearestCamps(fromPos, count)
    local list = {}
    for _, c in ipairs(CAMPS) do
        if IsAllyCamp(c) then
            table.insert(list, { pos = c, d = (c - fromPos):Length() })
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(count, #list) do
        out[i] = list[i].pos
    end
    return out
end

local function GetMidas(unit)
    return NPC.GetItem(unit, "item_hand_of_midas", true)
end

local function CanCast(ab, unit)
    if not ab then return false end
    if Ability.GetLevel(ab) <= 0 then return false end
    local mana = NPC.GetMana(unit) or 0
    if Ability.IsCastable then
        return Ability.IsCastable(ab, mana)
    end
    return Ability.IsReady(ab)
end

local function CastMidas(clone)
    local midas = GetMidas(clone)
    if not CanCast(midas, clone) then
        Log("мидас недоступен")
        return false
    end

    local creeps = Entity.GetUnitsInRadius(clone, CFG.MIDAS_RANGE, Enum.TeamType.TEAM_ENEMY) or {}
    local target = nil
    for _, c in pairs(creeps) do
        if c and Entity.IsAlive(c) and NPC.IsCreep and NPC.IsCreep(c) and not NPC.IsHero(c) then
            target = c
            break
        end
    end
    if not target then
        Log("нет крипа под мидас")
        return false
    end

    local player = Players.GetLocal()
    pcall(function()
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
            target, Vector(), midas,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            clone, false, false, false, true
        )
    end)
    Log("мидас")
    return true
end

--------------------------------------------------------------------------------
-- Логика стака
--------------------------------------------------------------------------------
local function StartStackJob(clone)
    if not clone or not Entity.IsAlive(clone) then return end

    local n = (UI and UI.StackCamps and UI.StackCamps:Get()) or 2
    local camps = NearestCamps(Entity.GetAbsOrigin(clone), n)

    state.clone      = clone
    state.camp1      = camps[1]
    state.camp2      = camps[2]
    state.stackDone1 = false
    state.stackDone2 = false
    state.jobToken   = state.jobToken + 1

    if state.camp1 then
        state.phase = "go1"
        OrderMove(clone, state.camp1)
        Log("старт стака → кемп 1")
    else
        state.phase = "midas"
        Log("кемпы не найдены, сразу мидас")
    end
end

local function ResetJob()
    state.phase = "idle"
    state.clone = nil
    state.camp1 = nil
    state.camp2 = nil
end

local function UpdateStackJob()
    local clone = state.clone
    if not clone or not Entity.IsAlive(clone) then
        ResetJob()
        return
    end

    local now = os.clock()
    if now - state.lastOrder < 0.2 then return end
    state.lastOrder = now

    local stackStart = (UI and UI.StackStart and UI.StackStart:Get()) or CFG.STACK_START
    local stackEnd   = (UI and UI.StackEnd and UI.StackEnd:Get()) or CFG.STACK_END
    if stackEnd <= stackStart then stackEnd = stackStart + 2 end

    local sec = SecOfMinute()
    local inWindow = sec >= stackStart and sec <= stackEnd
    local pos = Entity.GetAbsOrigin(clone)

    if state.phase == "go1" and state.camp1 then
        if (pos - state.camp1):Length() < CFG.CAMP_RADIUS then
            state.phase = "stack1"
            Log("у кемпа 1")
        else
            OrderMove(clone, state.camp1)
        end

    elseif state.phase == "stack1" and state.camp1 then
        if inWindow and not state.stackDone1 then
            local pull = state.camp1 + Vector(CFG.PULL_DIST, 80, 0)
            OrderAttackMove(clone, pull)
            state.stackDone1 = true
            Log("стак #1")
        elseif state.stackDone1 and sec > stackEnd then
            if state.camp2 then
                state.phase = "go2"
                OrderMove(clone, state.camp2)
            else
                state.phase = "midas"
            end
        end

    elseif state.phase == "go2" and state.camp2 then
        if (pos - state.camp2):Length() < CFG.CAMP_RADIUS then
            state.phase = "stack2"
            Log("у кемпа 2")
        else
            OrderMove(clone, state.camp2)
        end

    elseif state.phase == "stack2" and state.camp2 then
        if inWindow and not state.stackDone2 then
            local pull = state.camp2 + Vector(-CFG.PULL_DIST, 80, 0)
            OrderAttackMove(clone, pull)
            state.stackDone2 = true
            Log("стак #2")
        elseif state.stackDone2 and sec > stackEnd then
            state.phase = "midas"
        end

    elseif state.phase == "midas" then
        local wantMidas = not UI or not UI.MidasAfter or UI.MidasAfter:Get()
        if not wantMidas then
            state.phase = "done"
            Log("без мидаса, done")
            return
        end
        if CastMidas(clone) or not GetMidas(clone) then
            state.phase = "done"
            Log("done")
        else
            local back = state.camp2 or state.camp1
            if back then OrderMove(clone, back) end
        end
    end
end

local function IsManualPressed()
    if not UI or not UI.ManualStack then return false end
    local k = UI.ManualStack
    if k.IsPressed and k:IsPressed() then return true end
    if k.Get then
        local c = k:Get()
        if c and c ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(c) then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------
function AWHelper.OnUpdate()
    if not UI or not UI.Enabled or not UI.Enabled:Get() then return end
    if not IsAW() then return end

    local stackOn = UI.StackEnabled and UI.StackEnabled:Get()

    -- ручной бинп
    if stackOn and IsManualPressed() and state.phase == "idle" then
        local clone = FindClone()
        if clone then
            StartStackJob(clone)
            return
        end
    end

    if not stackOn then
        if state.phase ~= "idle" then ResetJob() end
        return
    end

    if state.phase == "idle" then
        local clone = FindClone()
        if clone and Entity.IsAlive(clone) and clone ~= state.clone then
            -- новая копия после ульты
            StartStackJob(clone)
        end
    elseif state.phase == "done" then
        local clone = FindClone()
        if not clone or not Entity.IsAlive(clone) then
            ResetJob()
        end
        -- живой клон после done — ждём следующую ульту (новый entity)
    else
        UpdateStackJob()
    end
end

function AWHelper.OnModifierCreate(entity, mod)
    if not UI or not UI.Enabled or not UI.Enabled:Get() then return end
    if not UI.StackEnabled or not UI.StackEnabled:Get() then return end
    if not IsAW() or not mod then return end

    local name = Modifier.GetName(mod)
    if name == "modifier_arc_warden_tempest_double" and state.phase == "idle" then
        if entity and Entity.IsAlive(entity) then
            StartStackJob(entity)
        end
    end
end

return AWHelper