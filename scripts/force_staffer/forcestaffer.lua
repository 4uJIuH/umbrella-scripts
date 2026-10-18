local forceStaffer = {}

--#region UI

local localization = qLocalization.new({
    en = {
        fs_group_main = "Force Staffer",
        fs_enable = "Enable",
        fs_enable_tip = "Turns the script on or off",
        fs_gear_main = "Mode",
        fs_mode = "Operating mode",
        fs_modes_hold = "While held",
        fs_modes_press = "One press",
        fs_mode_tip = "While held: works only while the key is down\nOne press: a single press is enough, the hero turns and\nuses the item by itself (gives up after 3 s)",
        fs_key = "Use key",
        fs_key_tip = "The hero turns toward the cursor,\nthen uses Force Staff or Hurricane Pike on itself",
        fs_bind_name = "Force Staffer",
    },
    ru = {
        fs_group_main = "Force Staffer",
        fs_enable = "Включить",
        fs_enable_tip = "Включает и выключает скрипт",
        fs_gear_main = "Режим",
        fs_mode = "Режим работы",
        fs_modes_hold = "По удержанию",
        fs_modes_press = "По нажатию",
        fs_mode_tip = "По удержанию: работает, пока клавиша зажата\nПо нажатию: хватит одного нажатия, герой сам развернется и\nиспользует предмет (сдастся через 3 с)",
        fs_key = "Клавиша использования",
        fs_key_tip = "Герой развернется к курсору,\nзатем использует на себя Force Staff или Hurricane Pike",
        fs_bind_name = "Force Staffer",
    },
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

local ui = {}

do
    local tab = UI.Create("Scripts", "Scripts", "Force Staffer")
    tab:Icon("\u{f6b6}")
    local page = tab:Create("Settings")
    local group = page:Create("fs_group_main", Enum.GroupSide.Left)

    ui.global_switch = group:Switch("fs_enable", true, "\u{f011}")
    ui.global_switch:ToolTip("fs_enable_tip")
    local g_main = ui.global_switch:Gear("fs_gear_main")
    ui.mode = g_main:Combo("fs_mode", { "fs_modes_hold", "fs_modes_press" }, 0)
    ui.mode:Icon("\u{f1de}")
    ui.mode:ToolTip("fs_mode_tip")

    ui.forceKey = group:Bind("fs_key", Enum.ButtonCode.KEY_NONE, "\u{f11c}")
    ui.forceKey:ToolTip("fs_key_tip")
    ui.forceKey:Properties(L("fs_bind_name"))
end

local function refresh_disabled()
    local on = ui.global_switch:Get()
    ui.mode:Disabled(not on)
    ui.forceKey:Disabled(not on)
end

ui.global_switch:SetCallback(refresh_disabled, true)

--#endregion UI

--#region Vars

local my_hero = nil
local waitTime = 0.0
local pressActive = false
local pressUntil = 0.0
local pressPos = nil
local PRESS_TIMEOUT = 3.0
local FACE_DOT = 0.9
local ORDER_DELAY = 0.05
local TURN_DIST = 25
local forceStaff = "item_force_staff"
local hurricanePike = "item_hurricane_pike"

--#endregion Vars

--#region Callbacks

forceStaffer.OnUpdate = function()
    if not ui.global_switch:Get() then
        my_hero = nil
        pressActive = false
        return
    end

    local now = GlobalVars.GetCurTime()
    local key = ui.forceKey:Get()
    local isKeyPressed

    if ui.mode:Get() == 1 then
        if key ~= Enum.ButtonCode.KEY_NONE and ui.forceKey:IsPressed() and not Input.IsInputCaptured() then
            pressActive = true
            pressUntil = now + PRESS_TIMEOUT
            pressPos = Input.GetWorldCursorPos()
        end

        if pressActive and now > pressUntil then
            pressActive = false
        end

        isKeyPressed = pressActive
    else
        pressActive = false
        isKeyPressed = key ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(key)
    end

    if not isKeyPressed then
        return
    end

    if waitTime > now then
        return
    end

    if not my_hero then
        my_hero = Heroes.GetLocal()
        if not my_hero then
            return
        end
        return
    end

    if not my_hero then
        Log.Write("Error: can't find player")
        return
    end

    local item = NPC.GetItem(my_hero, forceStaff)

    if not item then
        item = NPC.GetItem(my_hero, hurricanePike)
    end

    if not item then
        pressActive = false
        return
    end

    if not Ability.IsCastable(item, NPC.GetMana(my_hero)) then
        return
    end

    local rotation = Entity.GetRotation(my_hero)
    local forward_direction = rotation:GetForward():Normalized():Scaled(100)
    local playerPos = Entity.GetAbsOrigin(my_hero)
    local forwardPos = playerPos + forward_direction
    local mousePos = (ui.mode:Get() == 1 and pressPos) or Input.GetWorldCursorPos()

    local forwardDir = (forwardPos - playerPos):Normalized()
    local mouseDir = (mousePos - playerPos):Normalized()
    local dot2D = forwardDir:Dot2D(mouseDir)

    if dot2D > FACE_DOT then
        Ability.CastTarget(item, my_hero)
        pressActive = false
    else
        NPC.MoveTo(my_hero, playerPos + mouseDir:Scaled(TURN_DIST))
    end

    waitTime = GlobalVars.GetCurTime() + ORDER_DELAY
end

return forceStaffer
