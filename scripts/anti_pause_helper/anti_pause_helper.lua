local menu = Menu.Create("Scripts", "Other", "AntiPause Helper")
menu:Icon("\u{f04c}")

local script = {}
local ui = {}
local last_unpause_time = 0
local last_chat_pause_player_id = -1
local is_pause_processed = false

function script.OnScriptsLoaded()
    local menu_main = menu:Create("AntiPause Helper")
    local group = menu_main:Create("Settings")

    ui.auto = group:Switch("Отжимать автоматически", true)
    ui.ignore_allies = group:Switch("Игнорировать союзников", true)
end

function script.OnChatEvent(event)
    if event.type == Enum.DotaChatMessage.CHAT_MESSAGE_PAUSED then
        last_chat_pause_player_id = event.player_id
        is_pause_processed = false
    end
end

function script.OnUpdate()
    if not ui.auto:Get() then return end
    
    local is_paused = GameRules.IsPaused()
    local now = os.clock()

    if is_paused then
        if is_pause_processed then return end
        if now < last_unpause_time + 5 then return end
        if last_chat_pause_player_id == -1 then return end

        local local_player = Players.GetLocal()
        if not local_player then return end

        local local_player_id = Player.GetPlayerID(local_player)
        
        if last_chat_pause_player_id == local_player_id then
            is_pause_processed = true
            return
        end

        if ui.ignore_allies:Get() then
            local pauser_player = Players.Get(last_chat_pause_player_id)
            if pauser_player and Entity.GetTeamNum(local_player) == Entity.GetTeamNum(pauser_player) then
                is_pause_processed = true
                return
            end
        end

        Engine.ExecuteCommand("dota_pause")
        last_unpause_time = now
        is_pause_processed = true
    else
        last_chat_pause_player_id = -1
        is_pause_processed = false
    end
end

return script