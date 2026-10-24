--[[
    ~ Techies Auto Mine Placer
    ~ Platform: Umbrella Dota 2 (API v2)
    ~ Version: v1.5 (menu integration build)
    ~ Features:
      - Automatically mines selected territories without skipping any valid placement spots
      - Interactive Dota 2 minimap overlay to select territories (Own/Enemy Base, Triangle/Outpost, Jungle, Secret Shop)
      - Manual mouse-drawn zones: press the draw key, LMB adds a vertex, Ctrl+LMB closes; multiple areas are supported
      - Neutral-camp toggle: camps are excluded by default and can be mined on demand
      - Full base coverage: bases use a square plateau grid anchored to the real fort, not a half-off-map circle
      - Correct territory positions: Triangle is between Base and Secret Shop, anchored to Outposts
      - Full bilingual localization (Russian / English) using qLocalization
      - Smart grid generation respecting placement radius (350+ units) and GridNav.IsTraversable
      - Automatic mana management: Arcane Boots, Magic Wand/Stick/Holy Locket, Enchanted Mango
      - Automatic cooldown & charge recovery waiting
      - Instant cancellation on player screen click / RMB movement command (with script order protection)
      - In-world ESP: mine coverage circles, unmined spots, target tracer, status HUD
    ~ v1.5 changes:
      - Script menu is embedded into Heroes -> Hero List -> Techies ("Авто-минирование")
      - All hotkeys are unbound by default and assigned by the user in the menu
        (F7 reloads scripts and F10 is occupied by the cheat)
      - The map panel START button starts mining without any hotkey bound
    ~ v1.4 changes:
      - Merged the manual polygon miner: world-space mouse drawing, multiple areas, saved to config
      - Added a "mine camps" switch; camp spawn boxes are skipped by default
      - Base grids are now rectangular and cover the whole plateau (fort -> tier-3 front)
      - Default mine spacing lowered to 360 (minimum legal is 350) for denser base coverage
      - Blocked/unreachable points are retried instead of leaving permanent holes in the base
      - Map key and start/stop key are user-rebindable, draw key is user-rebindable too
    ~ v1.3 changes:
      - Fixed: zones were generated in OnScriptsLoaded (menu) where GridNav is empty,
        which left every zone with zero spots and made Start instantly report COMPLETED
      - Fixed: NPC.IsMoving is not in API v2, waiting for mana/CD threw every frame
      - Fixed: shell/base landmark anchoring moved the circle but not the spot grid
      - Fixed: ambiguous watchtower matching could anchor a triangle to the wrong tower
      - Fixed: spots were marked as mined right after the cast order, even if it failed
      - Fixed: 340..350 distance range caused casts rejected by the 350 placement rule
      - Menu is created through several known paths and every widget call is protected
      - Added diagnostics HUD and a debug-log dump hotkey for user reports
]]

local script = {}

local VERSION = "v1.5"

local function log(msg)
    msg = "[techies_auto_miner] " .. tostring(msg)
    local written = false
    pcall(function()
        if Log ~= nil and Log.Write ~= nil then
            Log.Write(msg)
            written = true
        end
    end)
    if not written then
        pcall(print, msg)
    end
end

log("SCRIPT LOAD STARTED " .. VERSION)

-- ============================================================================
-- Localization Setup (qLocalization)
-- ============================================================================
local qLoc = nil
local okLoc, resLoc = pcall(function() return qLocalization end)
if okLoc and type(resLoc) == "table" then
    qLoc = resLoc
else
    local okReq, resReq = pcall(require, "!_qLocalizer")
    if okReq and type(resReq) == "table" then
        qLoc = resReq
    end
end

local translations = {
    en = {
        techies_am = {
            tab = "Techies",
            group_main = "Auto Mine Placer",
            group_map = "Interactive Map & Zones",
            group_esp = "World ESP & Visuals",
            group_mana = "Mana & Item Recovery",

            enabled = "Enable Auto Miner",
            enabled_tip = "Master switch for Techies Auto Mine Placer script.",
            toggle_mining = "Start / Stop Mining Hotkey",
            toggle_mining_tip = "Press this key to start or stop the auto-mining process.",

            map_key = "Open Map Key",
            map_key_tip = "Hotkey to open/close the interactive minimap window for territory selection.",
            show_map = "Show Interactive Map",
            show_map_tip = "Toggles the interactive minimap window on screen.",

            panel_scale = "Map Panel Scale",
            panel_scale_tip = "Scale factor for the interactive map window.",

            use_arcane = "Auto Arcane Boots",
            use_arcane_tip = "Automatically activate Arcane Boots if mana is insufficient for a mine.",
            use_stick = "Auto Magic Stick / Wand",
            use_stick_tip = "Automatically use Magic Stick, Magic Wand, or Holy Locket if mana is insufficient.",
            use_mango = "Auto Enchanted Mango",
            use_mango_tip = "Automatically consume Enchanted Mango if mana is insufficient for a mine.",

            mine_spacing = "Mine Spacing",
            mine_spacing_tip = "Distance between placed mines (minimum in Dota is 350, recommended 360-380).",

            world_esp = "Show World ESP",
            world_esp_tip = "Draws circles for existing mines, planned spots, and zone boundaries in the world.",
            draw_tracers = "Draw Target Tracer",
            draw_tracers_tip = "Draws a line connecting Techies to the current target mining position.",
            draw_status_hud = "Draw Status HUD",
            draw_status_hud_tip = "Displays status banner above Techies with current mining progress.",

            -- UI In-Panel Texts
            panel_title = "TECHIES AUTO MINER",
            btn_start = "START MINING",
            btn_stop = "STOP MINING",
            btn_my_team = "My Side",
            btn_enemy_team = "Enemy Side",
            btn_select_all = "All Zones",
            btn_clear_all = "Clear All",

            status_active = "MINING",
            status_idle = "IDLE",
            status_waiting_mana = "WAITING MANA",
            status_waiting_cd = "WAITING CD",
            status_completed = "COMPLETED",
            status_interrupted = "INTERRUPTED",
            status_not_techies = "NOT TECHIES",
            status_no_ability = "MINES NOT LEARNED",

            -- Territories
            zone_radiant_base = "Radiant Base",
            zone_radiant_triangle = "Radiant Triangle (Outpost)",
            zone_radiant_jungle = "Radiant Main Jungle",
            zone_radiant_secret_shop = "Radiant Secret Shop",

            zone_dire_base = "Dire Base",
            zone_dire_triangle = "Dire Triangle (Outpost)",
            zone_dire_jungle = "Dire Main Jungle",
            zone_dire_secret_shop = "Dire Secret Shop",
            zone_manual = "Manual zone",

            tip_selected = "Zone: SELECTED (Click to toggle)",
            tip_unselected = "Zone: UNSELECTED (Click to toggle)",
            tip_spots_info = "Spots: %d total, %d mined, %d left",
            tip_status_line = "Status: %s",
            tip_start_hint = "Select zones, then press START",
            tip_interrupt_hint = "Right-click anywhere in game to cancel"
        }
    },
    ru = {
        techies_am = {
            tab = "Techies",
            group_main = "Авто-минирование",
            group_map = "Интерактивная карта и зоны",
            group_esp = "ESP и визуализация в мире",
            group_mana = "Восстановление маны и предметы",

            enabled = "Включить авто-минирование",
            enabled_tip = "Главный переключатель скрипта авто-минирования за Techies.",
            toggle_mining = "Клавиша Старт / Стоп",
            toggle_mining_tip = "Горячая клавиша для немедленного запуска или остановки процесса минирования.",

            map_key = "Клавиша открытия карты",
            map_key_tip = "Клавиша для открытия/закрытия интерактивной карты выбора территорий.",
            show_map = "Показать карту территорий",
            show_map_tip = "Отображает окно с интерактивной картой для клика по территориям.",

            panel_scale = "Масштаб окна карты",
            panel_scale_tip = "Масштаб интерактивного окна карты.",

            use_arcane = "Авто Arcane Boots",
            use_arcane_tip = "Автоматически использовать Arcane Boots при нехватке маны на мину.",
            use_stick = "Авто Стики / Magic Wand",
            use_stick_tip = "Автоматически прожимать Magic Stick, Wand или Holy Locket при нехватке маны.",
            use_mango = "Авто Enchanted Mango",
            use_mango_tip = "Автоматически съедать Mango при нехватке маны на мину.",

            mine_spacing = "Расстояние между минами",
            mine_spacing_tip = "Расстояние между минами (в Доте минимум 350, рекомендуется 360-380).",

            world_esp = "Отображение ESP в мире",
            world_esp_tip = "Отображает круги установленных мин, не заминированные точки и границы зон.",
            draw_tracers = "Линия к текущей точке",
            draw_tracers_tip = "Рисует трассирующую линию от Течиса к текущей целевой точке минирования.",
            draw_status_hud = "Информационный статус в HUD",
            draw_status_hud_tip = "Отображает плашку со статусом минирования над Течисом.",

            -- UI In-Panel Texts
            panel_title = "ТЕЧИС: АВТО-МИНИРОВАНИЕ",
            btn_start = "СТАРТ МИНИРОВАНИЯ",
            btn_stop = "ОСТАНОВИТЬ",
            btn_my_team = "Своя сторона",
            btn_enemy_team = "Вражеская",
            btn_select_all = "Все зоны",
            btn_clear_all = "Сброс",

            status_active = "МИНИРОВАНИЕ",
            status_idle = "ОЖИДАНИЕ",
            status_waiting_mana = "ЖДЕМ МАНУ",
            status_waiting_cd = "ЖДЕМ КД / ЗАРЯД",
            status_completed = "ЗАВЕРШЕНО",
            status_interrupted = "ПРЕРВАНО ИГРОКОМ",
            status_not_techies = "ВЫ НЕ TECHIES",
            status_no_ability = "МИНЫ НЕ ПРОКАЧАНЫ",

            -- Territories
            zone_radiant_base = "Своя база Radiant",
            zone_radiant_triangle = "Тройка Radiant (Аванпост)",
            zone_radiant_jungle = "Лес Radiant (Основной)",
            zone_radiant_secret_shop = "Потайной магазин Radiant",

            zone_dire_base = "База Dire",
            zone_dire_triangle = "Тройка Dire (Аванпост)",
            zone_dire_jungle = "Лес Dire (Основной)",
            zone_dire_secret_shop = "Потайной магазин Dire",
            zone_manual = "Ручная зона",

            tip_selected = "Зона: ВЫБРАНА (Клик для переключения)",
            tip_unselected = "Зона: НЕ ВЫБРАНА (Клик для переключения)",
            tip_spots_info = "Точки: всего %d, готово %d, осталось %d",
            tip_status_line = "Статус: %s",
            tip_start_hint = "Выберите зоны и нажмите СТАРТ",
            tip_interrupt_hint = "Нажмите ПКМ в игре для отмены"
        }
    }
}

local localization = qLoc and qLoc.new(translations) or nil
local MenuLib = localization and localization.WrapLibrary and localization.WrapLibrary(Menu) or Menu

local function tr(key, ...)
    local res = nil
    if localization and type(localization.Localize) == "function" then
        res = localization.Localize(key)
    end
    if res == nil or res == key then
        local lang = (localization and type(localization.GetLanguage) == "function" and localization.GetLanguage()) or "ru"
        local dict = translations[lang] or translations.en
        local path = key:gsub("^techies_am%.", "")
        res = dict.techies_am and dict.techies_am[path]
        if res == nil then
            res = translations.en.techies_am and translations.en.techies_am[path] or key
        end
    end
    if ... then
        return string.format(res, ...)
    end
    return res
end

-- ============================================================================
-- Constants
-- ============================================================================
local C = {
    HERO_NAME = "npc_dota_hero_techies",
    MINE_ABILITY = "techies_land_mines",
    MINE_UNIT = "npc_dota_techies_land_mine",
    MINE_PROXIMITY_RADIUS = 350.0, -- Dota 2 land mine placement exclusion radius
    MINE_TRIGGER_RADIUS = 500.0,
    ORDER_IDENTIFIER = "techies_auto_miner",
    CONFIG_NAME = "techies_auto_miner",

    ITEMS = {
        arcane_boots = "item_arcane_boots",
        magic_wand = "item_magic_wand",
        magic_stick = "item_magic_stick",
        holy_locket = "item_holy_locket",
        mango = "item_enchanted_mango"
    },

    WORLD_MIN = -8800,
    WORLD_MAX = 8800,

    MAP_IMAGE_PATHS = {
        "panorama/images/minimap/dotamap_psd.vtex_c",
        "panorama/images/textures/minimap_game_png.vtex_c"
    },

    FALLBACK_SVG = [[
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="g" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="#2a3826"/>
      <stop offset="0.48" stop-color="#18221c"/>
      <stop offset="0.52" stop-color="#202428"/>
      <stop offset="1" stop-color="#34383c"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="12" fill="#101412"/>
  <path d="M0 512V214L64 180l70 18 72-46 57 30 64-42 74 16 111-72v428z" fill="url(#g)"/>
  <path d="M-16 352C88 306 120 262 192 248s114 30 184-8 98-81 152-96" fill="none" stroke="#121e26" stroke-width="36" opacity=".95"/>
  <path d="M-16 352C88 306 120 262 192 248s114 30 184-8 98-81 152-96" fill="none" stroke="#223d4c" stroke-width="16" opacity=".75"/>
  <circle cx="50" cy="462" r="28" fill="#4d853e" opacity=".8"/>
  <circle cx="462" cy="50" r="28" fill="#8f352f" opacity=".8"/>
</svg>
]],

    COLORS = {
        bg = Color(18, 22, 26, 245),
        header = Color(26, 32, 38, 255),
        border = Color(52, 62, 72, 220),
        plate = Color(12, 16, 20, 230),

        accent = Color(255, 140, 30, 255),
        accent_bright = Color(255, 175, 45, 255),
        success = Color(65, 215, 105, 255),
        warning = Color(250, 185, 45, 255),
        danger = Color(245, 65, 65, 255),
        info = Color(65, 185, 245, 255),

        text = Color(235, 242, 248, 255),
        text_muted = Color(140, 150, 162, 255),

        btn_bg = Color(32, 40, 48, 220),
        btn_hover = Color(48, 58, 70, 240),
        btn_border = Color(65, 78, 92, 220),

        -- Zone colors
        zone_radiant = Color(70, 210, 130, 255),
        zone_dire = Color(245, 75, 75, 255),
        zone_triangle = Color(255, 195, 50, 255),
        zone_shop = Color(85, 185, 255, 255)
    }
}

-- ============================================================================
-- Runtime State & Variables
-- ============================================================================
local opt = {}
local ui = {
    font = nil,
    fontBold = nil,
    iconFont = nil,
    mapImage = nil,
    fallbackImage = nil,

    panelX = nil,
    panelY = nil,
    width = 410,
    height = 550,
    headerHeight = 34,

    dragging = false,
    dragOffsetX = 0,
    dragOffsetY = 0,

    hoveredZone = nil,
    buttons = {},
    markers = {},
    closeBounds = nil,
    startBtnBounds = nil
}

local state = {
    isMining = false,
    statusText = "IDLE",
    statusDetail = "",
    lastStatusUpdate = 0,

    currentZone = nil,
    currentTargetSpot = nil,
    miningPath = {},
    lastMoveOrderTime = 0,
    lastCastOrderTime = 0,
    lastItemUseTime = 0,
    lastScanTime = 0,
    targetStartTime = 0,
    targetBestDist = 0,
    nextTargetRetryAt = 0,

    zones = {},
    existingMines = {},
    recentlyPlacedMines = {},

    landmarksAnchored = false,
    isScriptIssuingOrder = false,
    toggleKeyHeld = false,

    -- Robustness / diagnostics state
    zonesReady = false,
    zoneRetryAt = 0,
    anchorRetryAt = 0,
    spacingUsed = 0,
    heroTeam = nil,
    menuPath = "",
    menuRetryAt = nil,
    lastError = "",
    lastErrorLog = -999,
    lastHeroPos = nil,
    lastHeroPosTime = 0,
    pendingCast = nil,
    landmarkCandidates = nil,
    campBoxes = {},
    campRetryAt = 0,

    -- Manual mouse-drawn zones (world-space polygons)
    manualPolygons = {},   -- { { points = {Vector,...}, closed = true }, ... }
    drawPolygon = {},      -- polygon currently being drawn
    drawMode = false,
    manualZone = nil,
    manualSpots = {},
    manualVersion = 0,
    manualDirty = false,
    manualBuiltVersion = -1,
    manualBuiltSpacing = 0,
    manualCampsUsed = false,
    mineCampsUsed = false,
    drawClickConsumed = false
}

-- ============================================================================
-- Territory & Zone Definitions
-- Territory order is logically arranged: Base -> Triangle (Outpost) -> Secret Shop -> Main Jungle
-- ============================================================================
local ZONE_CONFIG = {
    {
        id = "radiant_base",
        nameKey = "techies_am.zone_radiant_base",
        team = Enum.TeamNum.TEAM_RADIANT,
        side = "radiant",
        center = Vector(-5800, -5600, 384),
        radius = 1650,
        shape = "base", -- square plateau from the fort towards the map centre
        color = Color(65, 215, 120, 255),
        glyph = "\u{f015}" -- Home
    },
    {
        id = "radiant_triangle",
        nameKey = "techies_am.zone_radiant_triangle",
        team = Enum.TeamNum.TEAM_RADIANT,
        side = "radiant",
        center = Vector(-4000, -2200, 384), -- Between Base and Secret Shop, around Outpost
        radius = 1700,
        color = Color(255, 195, 50, 255),
        glyph = "\u{f6ff}" -- Mountain / Outpost
    },
    {
        id = "radiant_secret_shop",
        nameKey = "techies_am.zone_radiant_secret_shop",
        team = Enum.TeamNum.TEAM_RADIANT,
        side = "radiant",
        center = Vector(-4600, 1250, 384),
        radius = 950,
        color = Color(65, 180, 255, 255),
        glyph = "\u{f290}" -- Shopping bag
    },
    {
        id = "radiant_jungle",
        nameKey = "techies_am.zone_radiant_jungle",
        team = Enum.TeamNum.TEAM_RADIANT,
        side = "radiant",
        center = Vector(1500, -4200, 384),
        radius = 2300,
        color = Color(55, 205, 175, 255),
        glyph = "\u{f1bb}" -- Tree
    },
    {
        id = "dire_base",
        nameKey = "techies_am.zone_dire_base",
        team = Enum.TeamNum.TEAM_DIRE,
        side = "dire",
        center = Vector(5800, 5600, 384),
        radius = 1650,
        shape = "base", -- square plateau from the fort towards the map centre
        color = Color(245, 65, 65, 255),
        glyph = "\u{f015}" -- Home
    },
    {
        id = "dire_triangle",
        nameKey = "techies_am.zone_dire_triangle",
        team = Enum.TeamNum.TEAM_DIRE,
        side = "dire",
        center = Vector(4000, 2200, 384), -- Between Base and Secret Shop, around Outpost
        radius = 1700,
        color = Color(255, 145, 45, 255),
        glyph = "\u{f6ff}" -- Mountain / Outpost
    },
    {
        id = "dire_secret_shop",
        nameKey = "techies_am.zone_dire_secret_shop",
        team = Enum.TeamNum.TEAM_DIRE,
        side = "dire",
        center = Vector(4600, -1250, 384),
        radius = 950,
        color = Color(195, 120, 255, 255),
        glyph = "\u{f290}" -- Shopping bag
    },
    {
        id = "dire_jungle",
        nameKey = "techies_am.zone_dire_jungle",
        team = Enum.TeamNum.TEAM_DIRE,
        side = "dire",
        center = Vector(-1500, 4200, 384),
        radius = 2300,
        color = Color(225, 95, 220, 255),
        glyph = "\u{f1bb}" -- Tree
    }
}

-- ============================================================================
-- Math & Helper Functions
-- ============================================================================
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function dist2D(v1, v2)
    if v1 == nil or v2 == nil then return 99999 end
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    return math.sqrt(dx * dx + dy * dy)
end

local function isPlayingTechies()
    local hero = Heroes.GetLocal()
    if hero == nil then return false, nil end
    local name = NPC.GetUnitName(hero)
    if name == C.HERO_NAME then
        return true, hero
    end
    return false, hero
end

local function findMineAbility(hero)
    local direct = NPC.GetAbility(hero, C.MINE_ABILITY)
    if direct ~= nil then return direct end

    -- Fallback: the internal ability name changed between patches more than once.
    for i = 0, 25 do
        local ab = NPC.GetAbilityByIndex(hero, i)
        if ab ~= nil then
            local name = Ability.GetName(ab) or ""
            if name:find("land_mines", 1, true) or name:find("proximity", 1, true) then
                log("land mines ability resolved by name: " .. name)
                return ab
            end
        end
    end
    return nil
end

-- NPC.IsMoving is not part of the public API v2 surface anymore, so fall back
-- to NPC.IsRunning and finally to a position-delta check.
local function isHeroMoving(hero, now)
    if type(NPC.IsMoving) == "function" then
        local ok, res = pcall(NPC.IsMoving, hero)
        if ok and res ~= nil then return res end
    end
    if type(NPC.IsRunning) == "function" then
        local ok, res = pcall(NPC.IsRunning, hero)
        if ok and res ~= nil then return res end
    end

    local pos = Entity.GetAbsOrigin(hero)
    if pos == nil then return false end
    local moving = false
    if state.lastHeroPos ~= nil then
        local dt = (now or 0) - (state.lastHeroPosTime or 0)
        if dt > 0.05 then
            moving = dist2D(pos, state.lastHeroPos) > 12
            state.lastHeroPos = Vector(pos.x, pos.y, pos.z)
            state.lastHeroPosTime = now or 0
        end
    else
        state.lastHeroPos = Vector(pos.x, pos.y, pos.z)
        state.lastHeroPosTime = now or 0
    end
    return moving
end

local function clockNow()
    local t = nil
    pcall(function() t = os.clock() end)
    if t == nil then
        pcall(function() t = GameRules.GetGameTime() end)
    end
    return t or 0
end

local function traceErr(err)
    if debug ~= nil and type(debug.traceback) == "function" then
        return tostring(err) .. "\n" .. debug.traceback("", 2)
    end
    return tostring(err)
end

local function noteError(where, err)
    state.lastError = tostring(where) .. ": " .. tostring(err)
    local now = 0
    pcall(function() now = GameRules.GetGameTime() end)
    if now - (state.lastErrorLog or -999) > 3 then
        state.lastErrorLog = now
        log(state.lastError)
    end
end

-- Convert 3D world coordinates to 2D interactive minimap panel coordinates
local function worldToMapCoords(worldX, worldY, mapX, mapY, mapSize)
    local span = C.WORLD_MAX - C.WORLD_MIN
    local normX = clamp((worldX - C.WORLD_MIN) / span, 0, 1)
    local normY = clamp(1.0 - (worldY - C.WORLD_MIN) / span, 0, 1)

    local inset = math.max(2, math.floor(mapSize * 0.015))
    local usableSize = mapSize - inset * 2
    return mapX + inset + normX * usableSize,
           mapY + inset + normY * usableSize
end

-- ============================================================================
-- Territory Grid Generation & Mine Spot Analysis
-- ============================================================================
-- Neutral camps are spawn areas: a mine dropped inside a camp box blocks the
-- camp and it stops spawning. Collect the boxes once per game and skip every
-- grid point that falls inside one (plus a safety margin).
local function collectCampBoxes()
    local boxes = {}

    if Camps ~= nil and type(Camps.GetAll) == "function"
        and Camp ~= nil and type(Camp.GetCampBox) == "function" then
        local ok, list = pcall(Camps.GetAll)
        if ok and type(list) == "table" then
            for i = 1, #list do
                local camp = list[i]
                if camp ~= nil then
                    local boxOk, box = pcall(Camp.GetCampBox, camp)
                    if boxOk and type(box) == "table" and box.min ~= nil and box.max ~= nil then
                        local minX = math.min(box.min.x, box.max.x)
                        local maxX = math.max(box.min.x, box.max.x)
                        local minY = math.min(box.min.y, box.max.y)
                        local maxY = math.max(box.min.y, box.max.y)
                        if maxX > minX and maxY > minY then
                            boxes[#boxes + 1] = {
                                minX = minX, maxX = maxX,
                                minY = minY, maxY = maxY
                            }
                        end
                    end
                end
            end
        end
    end

    -- Fallback for the loading screen or an API without Camps: use the neutral
    -- creeps themselves. Covers only spawned camps, but it is better than
    -- blindly dropping a mine into a camp.
    if #boxes == 0 and NPCs ~= nil and type(NPCs.GetAll) == "function" then
        local npcOk, npcs = pcall(NPCs.GetAll)
        if npcOk and type(npcs) == "table" then
            for i = 1, #npcs do
                local npc = npcs[i]
                if npc ~= nil then
                    local name = NPC.GetUnitName(npc)
                    if name ~= nil and name:find("npc_dota_neutral_", 1, true) == 1 then
                        local pos = Entity.GetAbsOrigin(npc)
                        if pos ~= nil then
                            boxes[#boxes + 1] = {
                                minX = pos.x - 300, maxX = pos.x + 300,
                                minY = pos.y - 300, maxY = pos.y + 300
                            }
                        end
                    end
                end
            end
        end
    end

    return boxes
end

local function pointInCampBox(pos, boxes, margin)
    if pos == nil or boxes == nil or #boxes == 0 then return false end
    for i = 1, #boxes do
        local b = boxes[i]
        if pos.x >= b.minX - margin and pos.x <= b.maxX + margin
            and pos.y >= b.minY - margin and pos.y <= b.maxY + margin then
            return true
        end
    end
    return false
end

local function generateZoneGridSpots(zone, spacing)
    local spots = {}
    local cx, cy = zone.center.x, zone.center.y
    local cz = zone.center.z or 384
    local radius = zone.radius or 0
    local allowCamps = (opt.mineCamps ~= nil and opt.mineCamps:Get()) or false
    local rowIndex = 0

    -- Bases are squares extending from the fort towards the map centre, not
    -- circles: a circle centred on the fort wastes half of its radius off-map
    -- and leaves the tier-3 part of the base uncovered.
    local isRect = (zone.shape == "base")
    local gridSpacing = spacing
    if isRect then
        -- Bases get the densest legal lattice (360) regardless of the global
        -- slider, otherwise "fill the base" would depend on a setting.
        gridSpacing = math.min(spacing, 360)
    end
    local rowStep = gridSpacing * 0.866
    local xMin, xMax, yMin, yMax
    if isRect then
        local dir = (zone.team == Enum.TeamNum.TEAM_RADIANT) and 1 or -1
        local back = 800
        local front = 2600
        if dir > 0 then
            xMin, xMax = cx - back, cx + front
            yMin, yMax = cy - back, cy + front
        else
            xMin, xMax = cx - front, cx + back
            yMin, yMax = cy - front, cy + back
        end
    else
        xMin, xMax = cx - radius, cx + radius
        yMin, yMax = cy - radius, cy + radius
    end

    for y = yMin, yMax, rowStep do
        rowIndex = rowIndex + 1
        local rowOffset = (rowIndex % 2 == 0) and (gridSpacing * 0.5) or 0
        for x = xMin, xMax, gridSpacing do
            local px = x + rowOffset
            local py = y
            local inside = true
            if not isRect then
                inside = ((px - cx) ^ 2 + (py - cy) ^ 2) <= radius ^ 2
            end

            if inside then
                local candPos = Vector(px, py, cz)
                -- Techies land mines reject LOCATION (0x002) and BUILDING (0x100) cells.
                local ok, traversable = pcall(GridNav.IsTraversable, candPos, 0x1, 0x102)
                if not ok then
                    ok, traversable = pcall(GridNav.IsTraversable, candPos)
                end
                if ok and traversable
                    and (allowCamps or not pointInCampBox(candPos, state.campBoxes, 160)) then
                    table.insert(spots, {
                        pos = candPos,
                        zoneId = zone.id,
                        mined = false
                    })
                end
            end
        end
    end

    return spots
end

-- ============================================================================
-- Manual mouse-drawn polygons (world-space, multiple areas)
-- ============================================================================
local function pointInPolygon(px, py, poly)
    if poly == nil or #poly < 3 then return false end
    local inside = false
    local j = #poly
    for i = 1, #poly do
        local xi, yi = poly[i].x, poly[i].y
        local xj, yj = poly[j].x, poly[j].y
        if (yi > py) ~= (yj > py) then
            local denom = yj - yi
            if denom ~= 0 then
                local crossX = (xj - xi) * (py - yi) / denom + xi
                if px < crossX then inside = not inside end
            end
        end
        j = i
    end
    return inside
end

local function serializeManualPolygons()
    local parts = {}
    for i = 1, #state.manualPolygons do
        local pts = state.manualPolygons[i].points
        if pts ~= nil and #pts >= 3 then
            local coords = {}
            for j = 1, #pts do
                coords[#coords + 1] = string.format("%.0f,%.0f", pts[j].x, pts[j].y)
            end
            parts[#parts + 1] = table.concat(coords, "/")
        end
    end
    return table.concat(parts, "|")
end

local function saveManualPolygons()
    pcall(Config.WriteString, C.CONFIG_NAME, "manual_polygons", serializeManualPolygons())
end

local function loadManualPolygons()
    state.manualPolygons = {}
    local ok, raw = pcall(Config.ReadString, C.CONFIG_NAME, "manual_polygons", "")
    if not ok or type(raw) ~= "string" or raw == "" then return end
    for polyStr in string.gmatch(raw, "([^|]+)") do
        local points = {}
        for ptStr in string.gmatch(polyStr, "([^/]+)") do
            local sx, sy = string.match(ptStr, "([^,]+),([^,]+)")
            local x = tonumber(sx)
            local y = tonumber(sy)
            if x ~= nil and y ~= nil then
                points[#points + 1] = Vector(x, y, 384)
            end
        end
        if #points >= 3 then
            state.manualPolygons[#state.manualPolygons + 1] = {
                points = points,
                closed = true
            }
        end
    end
    state.manualVersion = state.manualVersion + 1
    state.manualDirty = true
    log("manual polygons loaded: " .. tostring(#state.manualPolygons))
end

local function buildManualSpots(spacing)
    local spots = {}
    if #state.manualPolygons == 0 then return spots end
    spacing = math.max(350, spacing or 360)
    local candidateSpacing = spacing
    local rowStep = candidateSpacing * 0.866
    local allowCamps = (opt.mineCamps ~= nil and opt.mineCamps:Get()) or false

    for p = 1, #state.manualPolygons do
        local poly = state.manualPolygons[p].points
        if poly ~= nil and #poly >= 3 then
            local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
            for i = 1, #poly do
                local pt = poly[i]
                if pt.x < minX then minX = pt.x end
                if pt.x > maxX then maxX = pt.x end
                if pt.y < minY then minY = pt.y end
                if pt.y > maxY then maxY = pt.y end
            end

            local row = 0
            for y = minY, maxY, rowStep do
                row = row + 1
                local offset = (row % 2 == 0) and (candidateSpacing * 0.5) or 0
                for x = minX, maxX, candidateSpacing do
                    local px, py = x + offset, y
                    if pointInPolygon(px, py, poly) then
                        local pos = Vector(px, py, 384)
                        local ok, trav = pcall(GridNav.IsTraversable, pos, 0x1, 0x102)
                        if not ok then
                            ok, trav = pcall(GridNav.IsTraversable, pos)
                        end
                        if ok and trav
                            and (allowCamps or not pointInCampBox(pos, state.campBoxes, 160)) then
                            local dup = false
                            for s = 1, #spots do
                                if dist2D(spots[s].pos, pos) < candidateSpacing * 0.5 then
                                    dup = true
                                    break
                                end
                            end
                            if not dup then
                                spots[#spots + 1] = {
                                    pos = pos,
                                    zoneId = "manual",
                                    mined = false
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return spots
end

local function rebuildManualZone(hero, spacing)
    spacing = spacing or ((opt.mineSpacing and opt.mineSpacing:Get()) or 360)
    state.manualSpots = {}
    state.manualZone = nil

    for i = #state.zones, 1, -1 do
        if state.zones[i].id == "manual" then
            table.remove(state.zones, i)
        end
    end

    local spots = buildManualSpots(spacing)
    if #spots > 0 then
        local sx, sy, n = 0, 0, 0
        for i = 1, #spots do
            sx = sx + spots[i].pos.x
            sy = sy + spots[i].pos.y
            n = n + 1
        end
        local center = Vector(sx / math.max(1, n), sy / math.max(1, n), 384)
        local zone = {
            id = "manual",
            nameKey = "techies_am.zone_manual",
            team = state.heroTeam or Enum.TeamNum.TEAM_RADIANT,
            side = "custom",
            isOwn = true,
            isManual = true,
            center = center,
            baseCenter = center,
            radius = 0,
            shape = "manual",
            color = Color(80, 220, 255, 255),
            glyph = "\u{f245}",
            enabled = (opt.manualEnabled == nil) or opt.manualEnabled:Get(),
            spots = spots,
            unminedCount = 0,
            minedCount = 0
        }
        state.manualSpots = spots
        state.manualZone = zone
        state.zones[#state.zones + 1] = zone
    end

    state.manualBuiltVersion = state.manualVersion
    state.manualBuiltSpacing = spacing
    state.manualCampsUsed = (opt.mineCamps ~= nil and opt.mineCamps:Get()) or false
    state.manualDirty = false
    log(string.format("manual zone rebuilt: polygons=%d spots=%d",
        #state.manualPolygons, #spots))
end

-- Dynamic Landmark Anchoring (Outposts, Forts, Ancients)
local function applyZoneCenter(zone, pos, spacing)
    if zone == nil or pos == nil then return false end
    if zone.center ~= nil and dist2D(zone.center, pos) < 60 then return false end
    zone.center = Vector(pos.x, pos.y, pos.z)
    zone.spots = generateZoneGridSpots(zone, spacing)
    return true
end

local function anchorLandmarksToWorld(force)
    if state.landmarksAnchored and not force then return end

    local npcs = NPCs.GetAll()
    if npcs == nil or #npcs == 0 then return end

    local spacing = (opt.mineSpacing and opt.mineSpacing:Get()) or 360
    local candidates = {}
    local forts = {}
    local towers = {}

    for i = 1, #npcs do
        local npc = npcs[i]
        if npc ~= nil then
            local uName = NPC.GetUnitName(npc)
            local pos = Entity.GetAbsOrigin(npc)

            if pos ~= nil and uName ~= nil then
                if uName == "npc_dota_goodguys_fort" then
                    forts.radiant = pos
                    table.insert(candidates, string.format("%s %.0f %.0f", uName, pos.x, pos.y))
                elseif uName == "npc_dota_badguys_fort" then
                    forts.dire = pos
                    table.insert(candidates, string.format("%s %.0f %.0f", uName, pos.x, pos.y))
                elseif uName == "npc_dota_watch_tower" or uName == "npc_dota_outpost" then
                    table.insert(towers, { name = uName, pos = pos })
                    table.insert(candidates, string.format("%s %.0f %.0f", uName, pos.x, pos.y))
                end
            end
        end
    end

    -- Bases are anchored to the real forts and their grids are rebuilt too.
    for z = 1, #state.zones do
        local zone = state.zones[z]
        if zone.id == "radiant_base" and forts.radiant ~= nil then
            applyZoneCenter(zone, forts.radiant, spacing)
        elseif zone.id == "dire_base" and forts.dire ~= nil then
            applyZoneCenter(zone, forts.dire, spacing)
        end
    end

    -- Triangles attach to the tower closest to the configured centre. Comparing
    -- against baseCenter prevents several watchtowers from overwriting each
    -- other depending on NPC iteration order.
    for z = 1, #state.zones do
        local zone = state.zones[z]
        if zone.id == "radiant_triangle" or zone.id == "dire_triangle" then
            local anchor = zone.baseCenter or zone.center
            local best, bestDist = nil, 3500
            for i = 1, #towers do
                local d = dist2D(anchor, towers[i].pos)
                if d < bestDist then
                    best, bestDist = towers[i], d
                end
            end
            if best ~= nil then
                applyZoneCenter(zone, best.pos, spacing)
            end
        end
    end

    state.landmarkCandidates = candidates
    if #candidates == 0 then
        log("landmarks not found yet")
        return
    end
    state.landmarksAnchored = true
    log("landmarks anchored, candidates=" .. tostring(#candidates))
end

local function initializeZones(hero)
    local heroTeam = nil
    if hero ~= nil then
        local ok, team = pcall(Entity.GetTeamNum, hero)
        if ok then heroTeam = team end
    end
    if heroTeam == nil then heroTeam = Enum.TeamNum.TEAM_RADIANT end

    local spacing = (opt.mineSpacing and opt.mineSpacing:Get()) or 360
    if state.campBoxes == nil or #state.campBoxes == 0 then
        state.campBoxes = collectCampBoxes()
    end
    local previous = {}
    for i = 1, #state.zones do
        previous[state.zones[i].id] = state.zones[i]
    end

    state.zones = {}
    state.heroTeam = heroTeam
    state.spacingUsed = spacing

    local totalSpots = 0
    for i = 1, #ZONE_CONFIG do
        local cfg = ZONE_CONFIG[i]
        local isOwn = (cfg.team == heroTeam)
        local prev = previous[cfg.id]

        local enabled
        if prev ~= nil then
            enabled = prev.enabled
        else
            local ok, saved = pcall(Config.ReadInt, C.CONFIG_NAME, "zone_" .. cfg.id, isOwn and 1 or 0)
            enabled = (ok and saved == 1) or false
        end

        local zoneObj = {
            id = cfg.id,
            nameKey = cfg.nameKey,
            team = cfg.team,
            side = cfg.side,
            isOwn = isOwn,
            center = Vector(cfg.center.x, cfg.center.y, cfg.center.z),
            baseCenter = Vector(cfg.center.x, cfg.center.y, cfg.center.z),
            radius = cfg.radius,
            shape = cfg.shape,
            color = cfg.color,
            glyph = cfg.glyph,
            enabled = enabled,
            spots = {},
            unminedCount = 0,
            minedCount = 0
        }

        zoneObj.spots = generateZoneGridSpots(zoneObj, spacing)
        totalSpots = totalSpots + #zoneObj.spots
        table.insert(state.zones, zoneObj)
    end

    state.mineCampsUsed = (opt.mineCamps ~= nil and opt.mineCamps:Get()) or false
    rebuildManualZone(hero, spacing)
    totalSpots = totalSpots + #state.manualSpots

    state.zonesReady = (totalSpots > 0)
    state.landmarksAnchored = false
    state.currentTargetSpot = nil
    state.pendingCast = nil
    log(string.format("zones initialized: team=%s spacing=%d spots=%d camps=%d manual=%d",
        tostring(heroTeam), spacing, totalSpots, #state.campBoxes, #state.manualSpots))
end

local function isLandMineUnitName(name)
    if name == nil then return false end
    if name == C.MINE_UNIT or name == "npc_dota_techies_mines" then return true end
    if name:find("techies", 1, true) ~= nil
        and name:find("mine", 1, true) ~= nil
        and name:find("remote", 1, true) == nil then
        return true
    end
    return false
end

-- Refresh and scan all live land mines placed on the map
local function updateExistingMines(hero)
    state.existingMines = {}
    local npcs = NPCs.GetAll()
    if npcs == nil then return end

    local now = GameRules.GetGameTime()

    -- Clean up temporary recently placed mines older than 5s
    local cleanRecent = {}
    for r = 1, #state.recentlyPlacedMines do
        local item = state.recentlyPlacedMines[r]
        if now - item.time < 5.0 then
            table.insert(cleanRecent, item)
            table.insert(state.existingMines, item.pos)
        end
    end
    state.recentlyPlacedMines = cleanRecent

    -- Scan live mine NPCs. Dormancy is ignored on purpose: invisible mines can
    -- be flagged dormant and would otherwise be treated as "not placed".
    for i = 1, #npcs do
        local npc = npcs[i]
        if npc ~= nil and Entity.IsAlive(npc) then
            local uName = NPC.GetUnitName(npc)
            if isLandMineUnitName(uName) then
                if Entity.IsSameTeam(npc, hero) then
                    local mPos = Entity.GetAbsOrigin(npc)
                    if mPos ~= nil then
                        table.insert(state.existingMines, mPos)
                    end
                end
            end
        end
    end

    -- Update mined/unmined status for all zone spots
    local thresh = C.MINE_PROXIMITY_RADIUS + 10
    local thresh2 = thresh * thresh
    for z = 1, #state.zones do
        local zone = state.zones[z]
        local mined = 0
        local unmined = 0

        for s = 1, #zone.spots do
            local spot = zone.spots[s]

            -- A spot blocked by a failed cast is retried later; a temporary
            -- obstruction (another mine, a creep, a missing path) must not
            -- leave a permanent hole in the base.
            if spot.blocked and spot.blockedUntil ~= nil and now >= spot.blockedUntil then
                spot.blocked = false
                spot.blockedUntil = nil
                spot.attempts = 0
            end

            local hasMine = false
            local sx, sy = spot.pos.x, spot.pos.y

            for m = 1, #state.existingMines do
                local mPos = state.existingMines[m]
                -- Placement rule is 350; keep a safety margin instead of
                -- treating 340..350 as free (the game rejects those casts).
                local dx = mPos.x - sx
                local dy = mPos.y - sy
                if dx * dx + dy * dy < thresh2 then
                    hasMine = true
                    break
                end
            end

            spot.mined = hasMine
            if hasMine then
                mined = mined + 1
            else
                unmined = unmined + 1
            end
        end

        zone.minedCount = mined
        zone.unminedCount = unmined
    end
end

-- Stop Auto-Mining and return control to player
local function stopAutoMining(reason)
    if state.isMining then
        state.isMining = false
        state.currentTargetSpot = nil
        state.miningPath = {}
        state.pendingCast = nil
        state.statusText = "IDLE"
        state.statusDetail = reason or tr("techies_am.status_interrupted")

        log("mining stopped: " .. tostring(reason))
    end
end

-- Start Auto-Mining sequence
local function startAutoMining()
    local isTechies, hero = isPlayingTechies()
    if not isTechies or hero == nil then
        state.statusText = "NOT_TECHIES"
        return
    end

    local landMines = findMineAbility(hero)
    if landMines == nil or Ability.GetLevel(landMines) <= 0 then
        state.isMining = false
        state.statusText = "NO_ABILITY"
        state.statusDetail = tr("techies_am.status_no_ability")
        return
    end

    -- Zones are generated in game only; a menu-time grid is empty.
    if not state.zonesReady then
        state.statusText = "WAITING_MAP"
        state.statusDetail = "Map is not ready yet, wait for the game to start"
        return
    end

    updateExistingMines(hero)

    -- Collect all unmined spots from currently enabled zones
    local unminedPool = {}
    for z = 1, #state.zones do
        local zone = state.zones[z]
        if zone.enabled then
            for s = 1, #zone.spots do
                local sp = zone.spots[s]
                if not sp.mined and not sp.blocked then
                    table.insert(unminedPool, sp)
                end
            end
        end
    end

    if #unminedPool == 0 then
        state.isMining = false
        state.statusText = "COMPLETED"
        local emptyZones = true
        for z = 1, #state.zones do
            if state.zones[z].enabled and #state.zones[z].spots > 0 then
                emptyZones = false
                break
            end
        end
        state.statusDetail = emptyZones
            and "No selected zones with valid spots (open the map and pick zones)"
            or "All selected zones already fully mined!"
        return
    end

    state.pendingCast = nil
    state.isMining = true
    state.statusText = "ACTIVE"
    state.statusDetail = string.format("%d spots to mine", #unminedPool)
    state.currentTargetSpot = nil
    state.lastMoveOrderTime = 0
    state.lastCastOrderTime = 0
    log(string.format("mining started: %d spots", #unminedPool))
end

-- Find the optimal next spot using Greedy Nearest-Neighbor from current hero position
local function getNextTargetSpot(hero)
    local heroPos = Entity.GetAbsOrigin(hero)
    local bestSpot = nil
    local bestDist = math.huge
    local thresh2 = (C.MINE_PROXIMITY_RADIUS + 10) ^ 2
    local hx, hy = heroPos.x, heroPos.y

    for z = 1, #state.zones do
        local zone = state.zones[z]
        if zone.enabled then
            for s = 1, #zone.spots do
                local spot = zone.spots[s]
                if not spot.mined and not spot.blocked and not spot.pending then
                    -- Verify no mine was recently placed nearby
                    local sx, sy = spot.pos.x, spot.pos.y
                    local occupied = false
                    for m = 1, #state.existingMines do
                        local mp = state.existingMines[m]
                        local dx = mp.x - sx
                        local dy = mp.y - sy
                        if dx * dx + dy * dy < thresh2 then
                            occupied = true
                            spot.mined = true
                            break
                        end
                    end

                    if not occupied then
                        local ddx, ddy = hx - sx, hy - sy
                        local d2 = ddx * ddx + ddy * ddy
                        if d2 < bestDist then
                            bestDist = d2
                            bestSpot = spot
                        end
                    end
                end
            end
        end
    end

    return bestSpot
end

-- ============================================================================
-- Core Automation Execution Logic
-- ============================================================================
local function executeAutoMiningLogic(hero, now)
    if not state.isMining then return end

    if not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        stopAutoMining("Hero died or dormant")
        return
    end

    local isChanneling = false
    if type(NPC.IsChannellingAbility) == "function" then
        isChanneling = NPC.IsChannellingAbility(hero)
    end

    if NPC.IsStunned(hero) or NPC.IsSilenced(hero) or isChanneling then
        return
    end

    local landMines = findMineAbility(hero)
    if landMines == nil or Ability.GetLevel(landMines) <= 0 then
        stopAutoMining(tr("techies_am.status_no_ability"))
        return
    end

    -- Resolve the previous cast before issuing a new one. A spot is marked as
    -- mined only after the game actually consumed a charge or started a CD.
    if state.pendingCast ~= nil then
        local pc = state.pendingCast
        local elapsed = now - pc.time
        local waitTime = pc.waitTime or 0.65

        -- Never issue another order before the cast point finishes, otherwise
        -- the move order cancels the cast while the charge is already spent.
        if elapsed < waitTime then
            state.statusText = "ACTIVE"
            state.statusDetail = "Casting mine..."
            return
        end

        local confirmed = false

        if pc.chargesBefore ~= nil and Ability.GetCurrentCharges(landMines) < pc.chargesBefore then
            confirmed = true
        elseif Ability.GetCooldown(landMines) > 0 then
            confirmed = true
        else
            for m = 1, #state.existingMines do
                if dist2D(pc.pos, state.existingMines[m]) < 120 then
                    confirmed = true
                    break
                end
            end
        end

        if confirmed then
            if pc.spot ~= nil then
                pc.spot.mined = true
                pc.spot.pending = false
            end
            state.pendingCast = nil
        elseif elapsed > 2.0 then
            if pc.spot ~= nil then
                pc.spot.pending = false
                pc.spot.attempts = (pc.spot.attempts or 0) + 1
                if pc.spot.attempts >= 3 then
                    pc.spot.blocked = true
                    pc.spot.blockedUntil = now + 45.0
                    log(string.format("spot blocked, retry in 45s: %.0f %.0f",
                        pc.spot.pos.x, pc.spot.pos.y))
                end
            end
            state.pendingCast = nil
        else
            state.statusText = "ACTIVE"
            state.statusDetail = "Confirming mine placement..."
            return
        end
    end

    -- Periodically re-scan mines
    if now - state.lastScanTime > 1.5 then
        state.lastScanTime = now
        updateExistingMines(hero)
    end

    -- Validate or select current target spot
    if state.currentTargetSpot == nil and state.nextTargetRetryAt > now then
        return
    end
    if state.currentTargetSpot == nil or state.currentTargetSpot.mined then
        state.currentTargetSpot = getNextTargetSpot(hero)
        if state.currentTargetSpot == nil then
            -- Are there any unmined spots left (even temporarily blocked)?
            local remaining = 0
            for z = 1, #state.zones do
                local zone = state.zones[z]
                if zone.enabled then
                    for s = 1, #zone.spots do
                        if not zone.spots[s].mined then
                            remaining = remaining + 1
                            break
                        end
                    end
                end
            end
            if remaining > 0 then
                state.statusText = "WAITING_RETRY"
                state.statusDetail = "Temporarily blocked spots, retrying..."
                state.nextTargetRetryAt = now + 0.5
                return
            end
            state.isMining = false
            state.statusText = "COMPLETED"
            state.statusDetail = "All selected territories successfully mined!"
            return
        end
        state.nextTargetRetryAt = 0
        state.targetStartTime = now
        state.targetBestDist = dist2D(Entity.GetAbsOrigin(hero), state.currentTargetSpot.pos)
    end

    local targetPos = state.currentTargetSpot.pos
    local heroPos = Entity.GetAbsOrigin(hero)
    local dist = dist2D(heroPos, targetPos)

    local castRange = Ability.GetCastRange(landMines) + NPC.GetCastRangeBonus(hero)
    local effectiveRange = math.max(300, castRange - 40)

    local player = Players.GetLocal()

    -- Phase 1: Movement to target spot
    if dist > effectiveRange then
        -- If the hero makes no progress for 18 seconds (blocked path, cliff,
        -- closed base gate), skip the spot temporarily instead of standing
        -- still forever and leaving the base half-empty.
        if dist < (state.targetBestDist or dist) - 80 then
            state.targetBestDist = dist
            state.targetStartTime = now
        elseif now - (state.targetStartTime or now) > 18.0 then
            local spot = state.currentTargetSpot
            if spot ~= nil then
                spot.blocked = true
                spot.blockedUntil = now + 90.0
                log(string.format("unreachable spot, skip 90s: %.0f %.0f", spot.pos.x, spot.pos.y))
            end
            state.currentTargetSpot = nil
            state.targetStartTime = now
            return
        end

        state.statusText = "ACTIVE"
        state.statusDetail = string.format("Moving to spot (dist: %.0f)", dist)

        if now - state.lastMoveOrderTime > 0.30 then
            state.lastMoveOrderTime = now
            state.isScriptIssuingOrder = true

            -- Primary movement via NPC.MoveTo
            NPC.MoveTo(hero, targetPos, false, false, false, false, C.ORDER_IDENTIFIER, true)

            -- Backup movement via Player.PrepareUnitOrders if player is present
            if player ~= nil then
                Player.PrepareUnitOrders(
                    player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    targetPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    hero,
                    false, false, false, true,
                    C.ORDER_IDENTIFIER,
                    false
                )
            end

            state.isScriptIssuingOrder = false
        end
        return
    end

    -- Phase 2: In cast range -> Check Mana & Item Recovery
    local currentMana = NPC.GetMana(hero)
    local manaCost = Ability.GetManaCost(landMines)

    if currentMana < manaCost then
        state.statusText = "WAITING_MANA"
        state.statusDetail = string.format("Mana: %.0f / %d", currentMana, manaCost)

        -- 1. Try Arcane Boots
        if opt.useArcane:Get() and (now - state.lastItemUseTime > 0.4) then
            local boots = NPC.GetItem(hero, C.ITEMS.arcane_boots, true)
            if boots ~= nil and Ability.CanBeExecuted(boots) == Enum.AbilityCastResult.READY then
                state.lastItemUseTime = now
                state.isScriptIssuingOrder = true
                Ability.CastNoTarget(boots, false, false, true, C.ORDER_IDENTIFIER)
                state.isScriptIssuingOrder = false
                return
            end
        end

        -- 2. Try Magic Wand / Stick / Holy Locket
        if opt.useStick:Get() and (now - state.lastItemUseTime > 0.4) then
            local stickNames = { C.ITEMS.magic_wand, C.ITEMS.magic_stick, C.ITEMS.holy_locket }
            for s = 1, #stickNames do
                local stick = NPC.GetItem(hero, stickNames[s], true)
                if stick ~= nil and Item.GetCurrentCharges(stick) > 0 and Ability.CanBeExecuted(stick) == Enum.AbilityCastResult.READY then
                    state.lastItemUseTime = now
                    state.isScriptIssuingOrder = true
                    Ability.CastNoTarget(stick, false, false, true, C.ORDER_IDENTIFIER)
                    state.isScriptIssuingOrder = false
                    return
                end
            end
        end

        -- 3. Try Enchanted Mango
        if opt.useMango:Get() and (now - state.lastItemUseTime > 0.4) then
            local mango = NPC.GetItem(hero, C.ITEMS.mango, true)
            if mango ~= nil and Ability.CanBeExecuted(mango) == Enum.AbilityCastResult.READY then
                state.lastItemUseTime = now
                state.isScriptIssuingOrder = true
                pcall(Ability.CastTarget, mango, hero, false, false, true, C.ORDER_IDENTIFIER)
                state.isScriptIssuingOrder = false
                return
            end
        end

        -- Hold position while waiting for mana regeneration
        if isHeroMoving(hero, now) and now - state.lastMoveOrderTime > 0.5 then
            state.lastMoveOrderTime = now
            state.isScriptIssuingOrder = true
            if player ~= nil then
                Player.HoldPosition(player, hero, false, false, false, C.ORDER_IDENTIFIER)
            end
            state.isScriptIssuingOrder = false
        end
        return
    end

    -- Phase 3: Check Cooldown & Charges
    local charges = Ability.GetCurrentCharges(landMines)
    local cd = Ability.GetCooldown(landMines)
    local canExec = Ability.CanBeExecuted(landMines)

    if charges == 0 or cd > 0 or canExec ~= Enum.AbilityCastResult.READY then
        state.statusText = "WAITING_COOLDOWN"
        local restoreTime = 0
        if type(Ability.ChargeRestoreTimeRemaining) == "function" then
            restoreTime = Ability.ChargeRestoreTimeRemaining(landMines)
        end
        if restoreTime <= 0 then restoreTime = cd end
        state.statusDetail = string.format("Charge ready in %.1fs", math.max(0.1, restoreTime))

        -- Hold position while waiting for cooldown
        if isHeroMoving(hero, now) and now - state.lastMoveOrderTime > 0.5 then
            state.lastMoveOrderTime = now
            state.isScriptIssuingOrder = true
            if player ~= nil then
                Player.HoldPosition(player, hero, false, false, false, C.ORDER_IDENTIFIER)
            end
            state.isScriptIssuingOrder = false
        end
        return
    end

    -- Phase 4: Cast Proximity Mine!
    if now - state.lastCastOrderTime > 0.35 then
        state.lastCastOrderTime = now
        state.statusText = "ACTIVE"
        state.statusDetail = "Placing Proximity Mine..."

        state.currentTargetSpot.pending = true

        local castPoint = 0.5
        pcall(function() castPoint = Ability.GetCastPoint(landMines) end)

        state.pendingCast = {
            spot = state.currentTargetSpot,
            pos = Vector(targetPos.x, targetPos.y, targetPos.z),
            time = now,
            waitTime = math.max(0.45, (castPoint or 0.5) + 0.15),
            chargesBefore = Ability.GetCurrentCharges(landMines)
        }

        state.isScriptIssuingOrder = true
        Ability.CastPosition(landMines, targetPos, false, false, true, C.ORDER_IDENTIFIER, false)
        state.isScriptIssuingOrder = false

        state.currentTargetSpot = nil
    end
end

-- ============================================================================
-- Menu Setup
-- ============================================================================
local MENU_PATHS = {
    -- Prefer the real Techies hero page: the settings and binds live inside
    -- Heroes -> Hero List -> Techies, next to the built-in hero scripts.
    { "Heroes", "Hero List", "Techies" },
    { "Герои", "Список героев", "Techies" },
    { "Scripts", "User Scripts", "Techies Auto Miner" },
    { "General", "Main", "Techies Auto Miner" }
}

local function hasMethod(obj, name)
    if obj == nil then return false end
    local ok, fn = pcall(function() return obj[name] end)
    return ok and type(fn) == "function"
end

local fallbackWidgets = setmetatable({}, { __mode = "k" })

local function fallbackWidget(value)
    local widget = {
        Get = function() return value end,
        Set = function() end,
        IsPressed = function() return false end,
        IsDown = function() return false end,
        ToolTip = function() end,
        SetCallback = function() end,
        Icon = function() end
    }
    fallbackWidgets[widget] = true
    return widget
end

local function addSwitch(group, name, default, icon)
    if group == nil then return fallbackWidget(default) end
    local ok, w = pcall(group.Switch, group, name, default, icon)
    if ok and w ~= nil and hasMethod(w, "Get") then return w end
    log("menu: Switch failed '" .. name .. "' -> " .. tostring(w))
    return fallbackWidget(default)
end

local function addBind(group, name, default, icon)
    if group == nil then return fallbackWidget(Enum.ButtonCode.BUTTON_CODE_INVALID) end
    local ok, w = pcall(group.Bind, group, name, default, icon)
    if ok and w ~= nil and hasMethod(w, "Get") then return w end
    log("menu: Bind failed '" .. name .. "' -> " .. tostring(w))
    return fallbackWidget(Enum.ButtonCode.BUTTON_CODE_INVALID)
end

local function addSlider(group, name, minV, maxV, default, fmt)
    if group == nil then return fallbackWidget(default) end
    local ok, w = pcall(group.Slider, group, name, minV, maxV, default, fmt)
    if ok and w ~= nil and hasMethod(w, "Get") then return w end
    log("menu: Slider failed '" .. name .. "' -> " .. tostring(w))
    return fallbackWidget(default)
end

local function addButton(group, name, callback, icon)
    if group == nil or not hasMethod(group, "Button") then return fallbackWidget(nil) end
    local ok, w = pcall(group.Button, group, name, callback)
    if ok and w ~= nil then
        if icon ~= nil and hasMethod(w, "Icon") then
            pcall(w.Icon, w, icon)
        end
        return w
    end
    log("menu: Button failed '" .. name .. "' -> " .. tostring(w))
    return fallbackWidget(nil)
end

local function createGroup(self, name, side)
    if self == nil or not hasMethod(self, "Create") then return nil end
    local ok, group
    if side ~= nil then
        ok, group = pcall(self.Create, self, name, side)
    else
        ok, group = pcall(self.Create, self, name)
    end
    if ok and group ~= nil and hasMethod(group, "Switch") then
        return group
    end
    return nil
end

local function initializeMenu()
    if opt.ready then return true end

    local clock = clockNow()
    if state.menuRetryAt ~= nil and clock < state.menuRetryAt then return false end

    -- Menu.Create can either return a second tab (needs one more :Create) or
    -- a group, depending on the build. Walk down until a group is reached.
    local tab = nil
    local usedPath = nil
    for i = 1, #MENU_PATHS do
        local p = MENU_PATHS[i]
        -- Prefer an existing page (the Techies hero page already exists), then
        -- fall back to creating it. This mirrors the built-in hero-script pack.
        local okFind, found = pcall(Menu.Find, p[1], p[2], p[3])
        if okFind and found ~= nil then
            tab = found
            usedPath = table.concat(p, " / ")
            break
        end
        local ok, res = pcall(Menu.Create, p[1], p[2], p[3])
        if ok and res ~= nil then
            tab = res
            usedPath = table.concat(p, " / ")
            break
        else
            log("menu: Create failed for " .. table.concat(p, " / ") .. " -> " .. tostring(res))
        end
    end

    if tab == nil then
        state.menuRetryAt = clock + 3.0
        state.menuPath = "NOT FOUND"
        log("menu: no known menu path works, retry in 3s")
        return false
    end

    -- Menu.Create("Heroes","Hero List","Techies") returns the shared Techies
    -- hero page. Add a dedicated "Авто-минирование" tab/section so our widgets
    -- do not mix with the built-in hero settings.
    local third = tab
    local innerName = nil
    if hasMethod(tab, "Create") then
        local okChild, child = pcall(tab.Create, tab, "Авто-минирование")
        if okChild and child ~= nil then
            third = child
            innerName = "Авто-минирование"
        else
            log("menu: inner section not created -> " .. tostring(child))
        end
    end

    local mainGroup = nil
    if hasMethod(third, "Switch") then
        mainGroup = third
    else
        mainGroup = createGroup(third, "Главные настройки", Enum.GroupSide and Enum.GroupSide.Left or 1)
    end

    if mainGroup == nil then
        state.menuRetryAt = clock + 3.0
        state.menuPath = usedPath
        log("menu: tab found but group creation failed at " .. tostring(usedPath))
        return false
    end

    local mapGroup = createGroup(third, "Карта и зоны", Enum.GroupSide and Enum.GroupSide.Right or 2) or mainGroup
    local manaGroup = createGroup(third, "Контроль маны", Enum.GroupSide and Enum.GroupSide.Left or 1) or mainGroup
    local espGroup = createGroup(third, "ESP в мире", Enum.GroupSide and Enum.GroupSide.Right or 2) or mainGroup
    local manualGroup = createGroup(third, "Ручная зона", Enum.GroupSide and Enum.GroupSide.Right or 2) or mapGroup

    -- Main Settings
    opt.enabled = addSwitch(mainGroup, "Включить авто-минирование", true, "\u{f011}")
    opt.enabled:ToolTip("Главный переключатель работы скрипта.")

    opt.toggleMiningKey = addBind(mainGroup, "Клавиша Старт / Стоп", Enum.ButtonCode.BUTTON_CODE_INVALID, "\u{f04b}")
    opt.toggleMiningKey:ToolTip("Нажмите на поле и назначьте свою клавишу. По умолчанию не назначена: F7 занята перезагрузкой скриптов.")

    opt.mapKey = addBind(mainGroup, "Клавиша меню зон (карта)", Enum.ButtonCode.BUTTON_CODE_INVALID, "\u{f279}")
    opt.mapKey:ToolTip("Нажмите на поле и назначьте свою клавишу. По умолчанию не назначена.")

    opt.mineSpacing = addSlider(mainGroup, "Расстояние между минами", 360, 450, 360, "%d")
    opt.mineSpacing:ToolTip("Расстояние между минами (минимум в игре 350, рекомендуется 360-380).")

    opt.mineCamps = addSwitch(mainGroup, "Заставлять кемпы (нейтралы)", false, "\u{f1bb}")
    opt.mineCamps:ToolTip("Разрешить ставить мины в нейтральных кемпах. Выключено — кемпы не блокируются.")

    -- Map Settings
    opt.showMap = addSwitch(mapGroup, "Показать карту зон", true, "\u{f279}")
    opt.showMap:ToolTip("Отображает интерактивное окно с миникартой.")

    opt.panelScale = addSlider(mapGroup, "Масштаб окна карты", 70, 150, 100, "%d%%")
    opt.panelScale:ToolTip("Размер окна интерактивной карты.")

    -- Manual mouse-drawn zones
    opt.manualEnabled = addSwitch(manualGroup, "Включить ручную зону", true, "\u{f245}")
    opt.manualEnabled:ToolTip("Минирует точки внутри областей, нарисованных мышью.")

    opt.drawKey = addBind(manualGroup, "Рисовать зону (ЛКМ)", Enum.ButtonCode.BUTTON_CODE_INVALID, "\u{f303}")
    opt.drawKey:ToolTip("Нажмите на поле и назначьте свою клавишу. ЛКМ — точка, Ctrl+ЛКМ — замкнуть, ПКМ/Esc — отмена. Можно нарисовать несколько зон.")

    opt.clearManualBtn = addButton(manualGroup, "Очистить ручные зоны", function()
        state.manualPolygons = {}
        state.drawPolygon = {}
        state.drawMode = false
        state.manualVersion = state.manualVersion + 1
        state.manualDirty = true
        saveManualPolygons()
        log("manual polygons cleared")
    end, "\u{f014}")

    opt.undoManualBtn = addButton(manualGroup, "Удалить последнюю зону", function()
        if #state.manualPolygons > 0 then
            table.remove(state.manualPolygons, #state.manualPolygons)
            state.manualVersion = state.manualVersion + 1
            state.manualDirty = true
            saveManualPolygons()
            log("manual polygon removed, left=" .. tostring(#state.manualPolygons))
        end
    end, "\u{f0e2}")

    -- Mana & Items
    opt.useArcane = addSwitch(manaGroup, "Использовать Arcane Boots", true, "\u{f1fe}")
    opt.useArcane:ToolTip("Автоматически жать Arcane Boots при нехватке маны на мину.")

    opt.useStick = addSwitch(manaGroup, "Использовать Стики / Wand", true, "\u{f0e7}")
    opt.useStick:ToolTip("Автоматически жать стики при нехватке маны.")

    opt.useMango = addSwitch(manaGroup, "Кушать Enchanted Mango", true, "\u{f188}")
    opt.useMango:ToolTip("Автоматически съедать Mango при нехватке маны на мину.")

    -- ESP
    opt.worldEsp = addSwitch(espGroup, "Отображать зоны и мины в мире", true, "\u{f06e}")
    opt.worldEsp:ToolTip("Рисует на земле существующие мины, зоны и плановые точки.")

    opt.drawTracers = addSwitch(espGroup, "Линия к текущей точке", true, "\u{f1fe}")
    opt.drawTracers:ToolTip("Рисует линию от Течиса к следующей точке установки мины.")

    opt.drawStatusHud = addSwitch(espGroup, "Статус над героем", true, "\u{f05a}")
    opt.drawStatusHud:ToolTip("Отображает плашку со статусом минирования над Течисом.")

    opt.showDiag = addSwitch(espGroup, "Диагностика (для баг-репортов)", true, "\u{f188}")
    opt.showDiag:ToolTip("Показывает состояние скрипта и последнюю ошибку. Нужно для диагностики.")

    opt.dumpKey = addBind(espGroup, "Дамп логов (NPC/способности)", Enum.ButtonCode.BUTTON_CODE_INVALID, "\u{f0e3}")
    opt.dumpKey:ToolTip("Пишет в debug.log список способностей героя и ближайших зданий/landmarks.")

    if fallbackWidgets[opt.enabled] then
        state.menuRetryAt = clock + 3.0
        state.menuPath = usedPath
        log("menu: main switch could not be created at " .. tostring(usedPath))
        return false
    end

    state.menuPath = innerName and (usedPath .. " / " .. innerName) or usedPath
    opt.ready = true
    log("menu ready: " .. tostring(state.menuPath))
    return true
end

-- ============================================================================
-- UI Assets Initialization
-- ============================================================================
local function initializeUiAssets()
    local function loadFontSafe(name, weight)
        local handle = nil
        local ok = pcall(function()
            handle = Render.LoadFont(name, Enum.FontCreate.FONTFLAG_ANTIALIAS, weight)
        end)
        if not ok or handle == nil then
            pcall(function() handle = Render.LoadFont("Arial", 0, weight) end)
        end
        return handle
    end

    ui.font = loadFontSafe("MuseoSansEx", 500)
    ui.fontBold = loadFontSafe("MuseoSansEx", 700)
    ui.iconFont = loadFontSafe("FontAwesomeEx", 400)
    log("ui fonts: body=" .. tostring(ui.font) .. " bold=" .. tostring(ui.fontBold) .. " icon=" .. tostring(ui.iconFont))

    for i = 1, #C.MAP_IMAGE_PATHS do
        local ok, handle = pcall(Render.LoadImage, C.MAP_IMAGE_PATHS[i])
        if ok and handle ~= nil then
            local okSize, size = pcall(Render.ImageSize, handle)
            if okSize and size ~= nil and size.x > 8 and size.y > 8 then
                ui.mapImage = handle
                break
            end
        end
    end

    local okSvg, svgHandle = pcall(
        Render.LoadSvgString,
        C.FALLBACK_SVG,
        Vec2(512, 512),
        "techies_auto_miner_fallback_map"
    )
    if okSvg and svgHandle ~= nil then
        ui.fallbackImage = svgHandle
    end
end

-- ============================================================================
-- Interactive Map Panel Drawing & Input
-- ============================================================================
local function drawMapPanel(hero, now)
    if not opt.showMap:Get() or ui.font == nil then
        ui.dragging = false
        ui.hoveredZone = nil
        return
    end

    local screen = Render.ScreenSize()
    local scale = (opt.panelScale and opt.panelScale:Get() or 100) / 100.0

    local panelW = math.floor(410 * scale)
    local panelH = math.floor(550 * scale)
    local headerH = math.floor(34 * scale)
    local padding = math.floor(10 * scale)
    local mapSize = panelW - padding * 2

    ui.width = panelW
    ui.height = panelH
    ui.headerHeight = headerH

    if ui.panelX == nil or ui.panelY == nil then
        ui.panelX = Config.ReadInt(C.CONFIG_NAME, "panel_x", -1)
        ui.panelY = Config.ReadInt(C.CONFIG_NAME, "panel_y", -1)
        if ui.panelX < 0 or ui.panelY < 0 then
            ui.panelX = math.floor(screen.x * 0.02)
            ui.panelY = math.floor(screen.y * 0.12)
        end
    end

    local cursorX, cursorY = Input.GetCursorPos()

    -- Dragging handling
    if ui.dragging then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1, true) then
            ui.panelX = clamp(cursorX - ui.dragOffsetX, 0, screen.x - panelW)
            ui.panelY = clamp(cursorY - ui.dragOffsetY, 0, screen.y - panelH)
        else
            ui.dragging = false
            Config.WriteInt(C.CONFIG_NAME, "panel_x", ui.panelX)
            Config.WriteInt(C.CONFIG_NAME, "panel_y", ui.panelY)
        end
    end

    local x = ui.panelX
    local y = ui.panelY

    -- Panel Background & Border
    Render.Shadow(Vec2(x, y), Vec2(x + panelW, y + panelH), Color(0, 0, 0, 195), 18, 8)
    Render.FilledRect(Vec2(x, y), Vec2(x + panelW, y + panelH), C.COLORS.bg, 8)
    Render.Rect(Vec2(x, y), Vec2(x + panelW, y + panelH), C.COLORS.border, 8, Enum.DrawFlags.None, 1)

    -- Header Bar
    Render.FilledRect(Vec2(x, y), Vec2(x + panelW, y + headerH), C.COLORS.header, 8)
    Render.Line(Vec2(x, y + headerH), Vec2(x + panelW, y + headerH), C.COLORS.border, 1)

    -- Header Title & Bomb Glyph
    Render.Text(ui.iconFont, math.floor(14 * scale), "\u{f1e2}", Vec2(x + 10 * scale, y + 9 * scale), C.COLORS.accent)
    Render.Text(ui.fontBold or ui.font, math.floor(12 * scale), tr("techies_am.panel_title"), Vec2(x + 32 * scale, y + 9 * scale), C.COLORS.text)

    -- Status Badge in Header
    local statusText = tr("techies_am.status_idle")
    local statusColor = C.COLORS.text_muted
    if state.isMining then
        if state.statusText == "WAITING_MANA" then
            statusText = tr("techies_am.status_waiting_mana")
            statusColor = C.COLORS.info
        elseif state.statusText == "WAITING_COOLDOWN" then
            statusText = tr("techies_am.status_waiting_cd")
            statusColor = C.COLORS.warning
        else
            statusText = tr("techies_am.status_active")
            statusColor = C.COLORS.success
        end
    elseif state.statusText == "COMPLETED" then
        statusText = tr("techies_am.status_completed")
        statusColor = C.COLORS.success
    elseif state.statusText == "NO_ABILITY" then
        statusText = tr("techies_am.status_no_ability")
        statusColor = C.COLORS.danger
    end

    local statusSz = Render.TextSize(ui.font, math.floor(10 * scale), statusText)
    local statusX = x + panelW - statusSz.x - 36 * scale
    Render.FilledRect(Vec2(statusX - 5, y + 7 * scale), Vec2(statusX + statusSz.x + 5, y + headerH - 7 * scale), Color(statusColor.r, statusColor.g, statusColor.b, 45), 4)
    Render.Text(ui.font, math.floor(10 * scale), statusText, Vec2(statusX, y + 9 * scale), statusColor)

    -- Close Button [X]
    local closeX = x + panelW - 22 * scale
    local closeY = y + 9 * scale
    local closeHover = cursorX >= closeX - 4 and cursorX <= closeX + 16 and cursorY >= y and cursorY <= y + headerH
    Render.Text(ui.iconFont, math.floor(12 * scale), "\u{f00d}", Vec2(closeX, closeY), closeHover and C.COLORS.danger or C.COLORS.text_muted)
    ui.closeBounds = { x = closeX - 4, y = y, w = 24 * scale, h = headerH }

    -- Quick Filter Buttons
    local btnY = y + headerH + 6 * scale
    local btnH = math.floor(22 * scale)
    local btnW = math.floor((panelW - padding * 2 - 12 * scale) / 4)

    ui.buttons = {
        { id = "my_side", text = tr("techies_am.btn_my_team"), x = x + padding, y = btnY, w = btnW, h = btnH },
        { id = "enemy_side", text = tr("techies_am.btn_enemy_team"), x = x + padding + btnW + 4 * scale, y = btnY, w = btnW, h = btnH },
        { id = "all", text = tr("techies_am.btn_select_all"), x = x + padding + (btnW + 4 * scale) * 2, y = btnY, w = btnW, h = btnH },
        { id = "clear", text = tr("techies_am.btn_clear_all"), x = x + padding + (btnW + 4 * scale) * 3, y = btnY, w = btnW, h = btnH }
    }

    for b = 1, #ui.buttons do
        local btn = ui.buttons[b]
        local isHover = cursorX >= btn.x and cursorX <= btn.x + btn.w and cursorY >= btn.y and cursorY <= btn.y + btn.h
        Render.FilledRect(Vec2(btn.x, btn.y), Vec2(btn.x + btn.w, btn.y + btn.h), isHover and C.COLORS.btn_hover or C.COLORS.btn_bg, 4)
        Render.Rect(Vec2(btn.x, btn.y), Vec2(btn.x + btn.w, btn.y + btn.h), C.COLORS.btn_border, 4, Enum.DrawFlags.None, 1)

        local tSz = Render.TextSize(ui.font, math.floor(9 * scale), btn.text)
        local tx = btn.x + (btn.w - tSz.x) * 0.5
        local ty = btn.y + (btn.h - tSz.y) * 0.5
        Render.Text(ui.font, math.floor(9 * scale), btn.text, Vec2(tx, ty), isHover and C.COLORS.text or C.COLORS.text_muted)
    end

    -- Minimap Display Box
    local mapX = x + padding
    local mapY = btnY + btnH + 8 * scale
    Render.FilledRect(Vec2(mapX, mapY), Vec2(mapX + mapSize, mapY + mapSize), C.COLORS.plate, 6)

    local mapHandle = ui.mapImage or ui.fallbackImage
    if mapHandle ~= nil then
        Render.Image(mapHandle, Vec2(mapX, mapY), Vec2(mapSize, mapSize), Color(255, 255, 255, 240), 6)
    end
    Render.Rect(Vec2(mapX, mapY), Vec2(mapX + mapSize, mapY + mapSize), C.COLORS.border, 6, Enum.DrawFlags.None, 1)

    -- Manual polygons on the minimap
    local function drawManualOnMap(points, closed, color)
        if points == nil or #points < 2 then return end
        local prevX, prevY = nil, nil
        for i = 1, #points do
            local px, py = worldToMapCoords(points[i].x, points[i].y, mapX, mapY, mapSize)
            if prevX ~= nil then
                Render.Line(Vec2(prevX, prevY), Vec2(px, py), color, 1.5)
            end
            prevX, prevY = px, py
        end
        if closed and #points >= 3 then
            local px, py = worldToMapCoords(points[1].x, points[1].y, mapX, mapY, mapSize)
            Render.Line(Vec2(prevX, prevY), Vec2(px, py), color, 1.5)
        end
    end
    for i = 1, #state.manualPolygons do
        drawManualOnMap(state.manualPolygons[i].points, true, Color(80, 220, 255, 200))
    end
    if state.drawMode and #state.drawPolygon > 0 then
        drawManualOnMap(state.drawPolygon, false, Color(255, 210, 80, 220))
    end

    -- Draw Territory Markers on Map
    ui.markers = {}
    ui.hoveredZone = nil
    local nodeRadius = math.max(8, math.floor(13 * scale))

    for i = 1, #state.zones do
        local zone = state.zones[i]
        local mx, my = worldToMapCoords(zone.center.x, zone.center.y, mapX, mapY, mapSize)
        local center2D = Vec2(mx, my)

        local isHit = (cursorX - mx) ^ 2 + (cursorY - my) ^ 2 <= (nodeRadius + 4) ^ 2
        if isHit then
            ui.hoveredZone = zone
        end

        -- Base Zone Circle
        if zone.enabled then
            -- Selected: Bright filled circle with colored rim & checkmark
            Render.FilledCircle(center2D, nodeRadius + (isHit and 2 or 0), zone.color)
            Render.Circle(center2D, nodeRadius + (isHit and 4 or 2), C.COLORS.text, 1.5)

            local chkSz = Render.TextSize(ui.iconFont, math.floor(9 * scale), "\u{f00c}")
            Render.Text(ui.iconFont, math.floor(9 * scale), "\u{f00c}", Vec2(mx - chkSz.x * 0.5, my - chkSz.y * 0.5), Color(20, 24, 28, 255))
        else
            -- Unselected: Dark disc with colored rim and glyph
            Render.FilledCircle(center2D, nodeRadius - 1, Color(24, 30, 36, 220))
            Render.Circle(center2D, nodeRadius - 1, zone.color, 1.5)

            local gSz = Render.TextSize(ui.iconFont, math.floor(8 * scale), zone.glyph or "\u{f1e2}")
            Render.Text(ui.iconFont, math.floor(8 * scale), zone.glyph or "\u{f1e2}", Vec2(mx - gSz.x * 0.5, my - gSz.y * 0.5), zone.color)
        end

        table.insert(ui.markers, {
            zone = zone,
            x = mx,
            y = my,
            radius = nodeRadius + 4
        })
    end

    -- Start / Stop Action Button Below Map
    local actionBtnY = mapY + mapSize + 8 * scale
    local actionBtnH = math.floor(32 * scale)
    local actionBtnW = mapSize

    local startHover = cursorX >= mapX and cursorX <= mapX + actionBtnW and cursorY >= actionBtnY and cursorY <= actionBtnY + actionBtnH
    local actionBtnBg = state.isMining and (startHover and Color(255, 75, 75, 255) or Color(225, 55, 55, 230))
                                       or (startHover and Color(75, 225, 115, 255) or Color(55, 195, 95, 230))

    Render.FilledRect(Vec2(mapX, actionBtnY), Vec2(mapX + actionBtnW, actionBtnY + actionBtnH), actionBtnBg, 6)
    Render.Rect(Vec2(mapX, actionBtnY), Vec2(mapX + actionBtnW, actionBtnY + actionBtnH), C.COLORS.border, 6, Enum.DrawFlags.None, 1)

    local actionText = state.isMining and tr("techies_am.btn_stop") or tr("techies_am.btn_start")
    local actionGlyph = state.isMining and "\u{f04d} " or "\u{f04b} "
    local fullActionText = actionGlyph .. actionText
    local actSz = Render.TextSize(ui.fontBold or ui.font, math.floor(11 * scale), fullActionText)
    Render.Text(ui.fontBold or ui.font, math.floor(11 * scale), fullActionText, Vec2(mapX + (actionBtnW - actSz.x) * 0.5, actionBtnY + (actionBtnH - actSz.y) * 0.5), Color(255, 255, 255, 255))

    ui.startBtnBounds = { x = mapX, y = actionBtnY, w = actionBtnW, h = actionBtnH }

    -- Footer Status & Interrupt Hint
    local footerY = actionBtnY + actionBtnH + 6 * scale
    local totalEnabledSpots = 0
    local totalMinedSpots = 0
    for z = 1, #state.zones do
        if state.zones[z].enabled then
            totalEnabledSpots = totalEnabledSpots + #state.zones[z].spots
            totalMinedSpots = totalMinedSpots + state.zones[z].minedCount
        end
    end

    local progressText = string.format("Mines: %d / %d placed", totalMinedSpots, totalEnabledSpots)
    Render.Text(ui.font, math.floor(10 * scale), progressText, Vec2(x + padding, footerY), C.COLORS.text)

    if state.statusDetail and #state.statusDetail > 0 then
        Render.Text(ui.font, math.floor(9 * scale), state.statusDetail, Vec2(x + padding, footerY + 15 * scale), C.COLORS.accent_bright)
    end

    local hintText = state.isMining and tr("techies_am.tip_interrupt_hint")
        or tr("techies_am.tip_start_hint")
    Render.Text(ui.font, math.floor(9 * scale), hintText, Vec2(x + padding, footerY + 30 * scale), C.COLORS.text_muted)

    -- Tooltip on Zone Hover
    if ui.hoveredZone ~= nil then
        local z = ui.hoveredZone
        local tipLines = {
            tr(z.nameKey),
            z.enabled and tr("techies_am.tip_selected") or tr("techies_am.tip_unselected"),
            string.format(tr("techies_am.tip_spots_info"), #z.spots, z.minedCount, z.unminedCount)
        }

        local tipW = 0
        local lineHeights = 16 * scale
        for l = 1, #tipLines do
            local sz = Render.TextSize(ui.font, math.floor(10 * scale), tipLines[l])
            if sz.x > tipW then tipW = sz.x end
        end
        tipW = tipW + 18 * scale
        local tipH = #tipLines * lineHeights + 8 * scale

        local tipX = clamp(cursorX + 12, 0, screen.x - tipW)
        local tipY = clamp(cursorY - tipH - 8, 0, screen.y - tipH)

        Render.Shadow(Vec2(tipX, tipY), Vec2(tipX + tipW, tipY + tipH), Color(0, 0, 0, 210), 12, 4)
        Render.FilledRect(Vec2(tipX, tipY), Vec2(tipX + tipW, tipY + tipH), Color(24, 28, 34, 250), 4)
        Render.Rect(Vec2(tipX, tipY), Vec2(tipX + tipW, tipY + tipH), z.color, 4, Enum.DrawFlags.None, 1)

        for l = 1, #tipLines do
            local tColor = (l == 1) and z.color or (l == 2 and (z.enabled and C.COLORS.success or C.COLORS.text_muted) or C.COLORS.text)
            Render.Text(ui.font, math.floor(10 * scale), tipLines[l], Vec2(tipX + 8 * scale, tipY + 4 * scale + (l - 1) * lineHeights), tColor)
        end
    end
end

-- ============================================================================
-- World ESP & Visuals
-- ============================================================================
local function drawManualWorld()
    local function drawPolyline(points, closed, color, width)
        if points == nil or #points < 2 then return end
        local prev = nil
        for i = 1, #points do
            local s, vis = Render.WorldToScreen(points[i])
            if vis and s ~= nil then
                if prev ~= nil then Render.Line(prev, s, color, width) end
                Render.FilledCircle(s, 3, color)
                prev = s
            else
                prev = nil
            end
        end
        if closed and #points >= 3 then
            local s1, v1 = Render.WorldToScreen(points[1])
            local s2, v2 = Render.WorldToScreen(points[#points])
            if v1 and v2 and s1 ~= nil and s2 ~= nil then
                Render.Line(s2, s1, color, width)
            end
        end
    end

    for i = 1, #state.manualPolygons do
        drawPolyline(state.manualPolygons[i].points, true, Color(80, 220, 255, 210), 2.0)
    end

    if opt.worldEsp:Get() then
        for i = 1, #state.manualSpots do
            local spot = state.manualSpots[i]
            if not spot.mined then
                local s, vis = Render.WorldToScreen(spot.pos)
                if vis and s ~= nil then
                    Render.FilledCircle(s, 2, Color(80, 220, 255, 110))
                end
            end
        end
    end

    if state.drawMode then
        drawPolyline(state.drawPolygon, false, Color(255, 210, 80, 235), 2.0)
        if #state.drawPolygon > 0 then
            local wp = Input.GetWorldCursorPos()
            if wp ~= nil then
                local last = state.drawPolygon[#state.drawPolygon]
                local s1, v1 = Render.WorldToScreen(last)
                local s2, v2 = Render.WorldToScreen(wp)
                if v1 and v2 and s1 ~= nil and s2 ~= nil then
                    Render.Line(s1, s2, Color(255, 210, 80, 150), 1.5)
                end
            end
        end
    end
end

local function drawWorldEsp(hero, now)
    if not opt.worldEsp:Get() then return end

    -- Draw Land Mines in World
    for m = 1, #state.existingMines do
        local mPos = state.existingMines[m]
        local sPos, onScreen = Render.WorldToScreen(mPos)
        if onScreen and sPos ~= nil then
            Render.FilledCircle(sPos, 7, Color(255, 140, 30, 200))
            Render.Circle(sPos, 12, Color(255, 180, 50, 255), 1.5)
        end
    end

    -- Draw Target Spot & Line Tracer
    if state.isMining and state.currentTargetSpot ~= nil then
        local tPos = state.currentTargetSpot.pos
        local sPos, onScreen = Render.WorldToScreen(tPos)

        if onScreen and sPos ~= nil then
            -- Pulsing target ring
            local pulse = math.sin(now * 6) * 3
            Render.FilledCircle(sPos, 9 + pulse, Color(65, 215, 105, 150))
            Render.Circle(sPos, 16 + pulse, Color(75, 255, 125, 255), 2.0)

            local txt = "NEXT MINE"
            local sz = Render.TextSize(ui.font, 11, txt)
            Render.FilledRect(Vec2(sPos.x - sz.x * 0.5 - 4, sPos.y - sz.y - 18), Vec2(sPos.x + sz.x * 0.5 + 4, sPos.y - 14), Color(15, 20, 25, 210), 3)
            Render.Text(ui.font, 11, txt, Vec2(sPos.x - sz.x * 0.5, sPos.y - sz.y - 16), Color(75, 255, 125, 255))
        end

        -- Tracer line from Techies to target spot
        if opt.drawTracers:Get() then
            local heroPos = Entity.GetAbsOrigin(hero)
            local sHero, heroVisible = Render.WorldToScreen(heroPos)
            if heroVisible and onScreen and sHero ~= nil and sPos ~= nil then
                Render.Line(sHero, sPos, Color(255, 195, 45, 220), 2.0)
            end
        end
    end

    -- Draw Status HUD Above Techies
    if opt.drawStatusHud:Get() and state.isMining then
        local heroPos = Entity.GetAbsOrigin(hero)
        local headPos = Vector(heroPos.x, heroPos.y, heroPos.z + 160)
        local sHead, headVis = Render.WorldToScreen(headPos)

        if headVis and sHead ~= nil then
            local bannerText = string.format("[%s] %s", state.statusText, state.statusDetail or "")
            local bSz = Render.TextSize(ui.fontBold or ui.font, 12, bannerText)
            local bx = sHead.x - bSz.x * 0.5
            local by = sHead.y - bSz.y - 6

            Render.FilledRect(Vec2(bx - 6, by - 4), Vec2(bx + bSz.x + 6, by + bSz.y + 4), Color(18, 24, 30, 230), 4)
            Render.Rect(Vec2(bx - 6, by - 4), Vec2(bx + bSz.x + 6, by + bSz.y + 4), C.COLORS.accent, 4, Enum.DrawFlags.None, 1)
            Render.Text(ui.fontBold or ui.font, 12, bannerText, Vec2(bx, by), Color(255, 255, 255, 255))
        end
    end
end

-- ============================================================================
-- Diagnostics
-- ============================================================================
local function dumpDiagnostics()
    log("=== DIAG DUMP " .. VERSION .. " ===")
    log("menu=" .. tostring(state.menuPath) .. " ready=" .. tostring(opt.ready)
        .. " zonesReady=" .. tostring(state.zonesReady)
        .. " zones=" .. tostring(#state.zones)
        .. " spacing=" .. tostring(state.spacingUsed))
    log("lastError=" .. tostring(state.lastError))

    local isTech, hero = isPlayingTechies()
    if hero ~= nil then
        local pos = Entity.GetAbsOrigin(hero)
        log("hero=" .. tostring(NPC.GetUnitName(hero))
            .. " team=" .. tostring(Entity.GetTeamNum(hero))
            .. string.format(" pos=%.0f,%.0f,%.0f", pos.x, pos.y, pos.z))

        for i = 0, 25 do
            local ab = NPC.GetAbilityByIndex(hero, i)
            if ab ~= nil then
                log(string.format("ability[%d]=%s lvl=%s charges=%s",
                    i, tostring(Ability.GetName(ab)), tostring(Ability.GetLevel(ab)),
                    tostring(Ability.GetCurrentCharges(ab))))
            end
        end
    else
        log("hero=nil")
    end

    if state.landmarkCandidates ~= nil then
        for i = 1, #state.landmarkCandidates do
            log("landmark: " .. state.landmarkCandidates[i])
        end
    end

    -- Unique NPC names relevant to mining/anchoring, to catch renames in patches.
    local seen = {}
    local allNpcs = NPCs.GetAll()
    if allNpcs ~= nil then
        for i = 1, #allNpcs do
            local name = NPC.GetUnitName(allNpcs[i])
            if name ~= nil and not seen[name]
               and (name:find("techies", 1, true) or name:find("watch_tower", 1, true)
                    or name:find("outpost", 1, true) or name:find("fort", 1, true)) then
                seen[name] = true
                log("npc: " .. name)
            end
        end
    end

    for z = 1, #state.zones do
        local zone = state.zones[z]
        log(string.format("zone %s enabled=%s spots=%d mined=%d center=%.0f,%.0f",
            tostring(zone.id), tostring(zone.enabled), #zone.spots, zone.minedCount,
            zone.center.x, zone.center.y))
    end
    log(string.format("manual: areas=%d spots=%d draw=%s camps=%s",
        #state.manualPolygons, #state.manualSpots, tostring(state.drawMode),
        tostring(opt.mineCamps ~= nil and opt.mineCamps:Get() or false)))
    log("=== END DIAG DUMP ===")
end

local function drawDiagnostics(hero)
    if opt.showDiag == nil or not opt.showDiag:Get() then return end
    if ui.font == nil then return end

    local totalSpots, totalMined, enabledZones = 0, 0, 0
    for z = 1, #state.zones do
        local zone = state.zones[z]
        if zone.enabled then
            enabledZones = enabledZones + 1
            totalSpots = totalSpots + #zone.spots
            totalMined = totalMined + zone.minedCount
        end
    end

    local lines = {}
    table.insert(lines, string.format("TAM %s | menu: %s", VERSION, tostring(state.menuPath)))
    table.insert(lines, string.format("zones=%d/%d spots=%d mined=%d spacing=%s",
        enabledZones, #state.zones, totalSpots, totalMined, tostring(state.spacingUsed)))
    table.insert(lines, string.format("manual=%d areas %d spots draw=%s camps=%s",
        #state.manualPolygons, #state.manualSpots, tostring(state.drawMode),
        tostring(opt.mineCamps ~= nil and opt.mineCamps:Get() or false)))
    table.insert(lines, string.format("ready=%s zonesReady=%s status=%s",
        tostring(opt.ready), tostring(state.zonesReady), tostring(state.statusText)))

    local isTech, techHero = isPlayingTechies()
    if isTech and techHero ~= nil then
        local ab = findMineAbility(techHero)
        if ab ~= nil then
            table.insert(lines, string.format("land_mines lvl=%s charges=%s cd=%.1f mana=%.0f",
                tostring(Ability.GetLevel(ab)), tostring(Ability.GetCurrentCharges(ab)),
                Ability.GetCooldown(ab), NPC.GetMana(techHero)))
        else
            table.insert(lines, "land_mines: ABILITY NOT FOUND")
        end
    elseif techHero ~= nil then
        table.insert(lines, "hero=" .. tostring(NPC.GetUnitName(techHero)))
    else
        table.insert(lines, "hero=nil")
    end

    if state.drawMode then
        table.insert(lines, "DRAW: LMB point | Ctrl+LMB close | RMB/Esc cancel")
    end

    if state.lastError ~= nil and #state.lastError > 0 then
        local err = state.lastError
        if #err > 110 then err = err:sub(1, 110) .. "..." end
        table.insert(lines, "err: " .. err:gsub("\n", " "))
    end

    local lineH = 13
    local maxW = 0
    for i = 1, #lines do
        local sz = Render.TextSize(ui.font, 10, lines[i])
        if sz.x > maxW then maxW = sz.x end
    end

    local pad = 6
    local x, y = 12, 12
    Render.FilledRect(Vec2(x, y), Vec2(x + maxW + pad * 2, y + #lines * lineH + pad * 2), Color(10, 14, 18, 220), 4)
    Render.Rect(Vec2(x, y), Vec2(x + maxW + pad * 2, y + #lines * lineH + pad * 2), C.COLORS.border, 4, Enum.DrawFlags.None, 1)

    for i = 1, #lines do
        local color = (i == 1) and C.COLORS.accent_bright or C.COLORS.text
        if i == #lines and state.lastError ~= nil and #state.lastError > 0 then
            color = C.COLORS.danger
        end
        Render.Text(ui.font, 10, lines[i], Vec2(x + pad, y + pad + (i - 1) * lineH), color)
    end
end

-- ============================================================================
-- Callbacks & Event Handlers
-- ============================================================================
function script.OnScriptsLoaded()
    local ok1, err1 = pcall(initializeUiAssets)
    if not ok1 then noteError("initializeUiAssets", err1) end

    local ok3, err3 = pcall(loadManualPolygons)
    if not ok3 then noteError("loadManualPolygons", err3) end

    local ok2, err2 = pcall(initializeMenu)
    if not ok2 then noteError("initializeMenu", err2) end
    -- Zones are intentionally NOT built here: OnScriptsLoaded fires in the menu,
    -- where GridNav has no map and every zone would get an empty spot list.
end

local function onUpdateImpl()
    if not opt.ready then
        initializeMenu()
        if not opt.ready then return end
    end

    -- Hotkey: Toggle Start/Stop Mining. The bind is user-assigned in the menu;
    -- there is deliberately no hardcoded fallback (F7 reloads scripts).
    local startBind = opt.toggleMiningKey and opt.toggleMiningKey:Get() or Enum.ButtonCode.BUTTON_CODE_INVALID
    local hasStartBind = startBind ~= Enum.ButtonCode.BUTTON_CODE_INVALID
        and startBind ~= Enum.ButtonCode.KEY_NONE
    local startPressed = false
    if hasStartBind then
        local isPressed = opt.toggleMiningKey:IsPressed()
        if isPressed and not state.toggleKeyHeld then
            state.toggleKeyHeld = true
            startPressed = true
        elseif not isPressed then
            state.toggleKeyHeld = false
        end
    end

    if startPressed then
        if state.isMining then
            stopAutoMining("Остановлено горячей клавишей")
        else
            startAutoMining()
        end
    end

    -- Hotkey: Toggle Map Panel
    if opt.mapKey and opt.mapKey:IsPressed() then
        opt.showMap:Set(not opt.showMap:Get())
    end

    -- Hotkey: start/stop drawing a new manual polygon. Closed polygons stay.
    if opt.drawKey and opt.drawKey:IsPressed() then
        if isPlayingTechies() then
            if state.drawMode then
                state.drawMode = false
                state.drawPolygon = {}
            else
                state.drawMode = true
                state.drawPolygon = {}
            end
            state.drawClickConsumed = false
            log("draw mode: " .. tostring(state.drawMode))
        end
    end

    -- Hotkey: diagnostics dump into debug.log
    if opt.dumpKey and opt.dumpKey:IsPressed() then
        dumpDiagnostics()
    end

    local isTechies, hero = isPlayingTechies()
    if not isTechies or hero == nil then return end

    local now = GameRules.GetGameTime()
    local spacing = (opt.mineSpacing and opt.mineSpacing:Get()) or 360
    local team = Entity.GetTeamNum(hero)
    local allowCamps = (opt.mineCamps ~= nil and opt.mineCamps:Get()) or false

    -- Camps are static, but the spawner list can be empty during the loading
    -- screen. Retry once in a while and rebuild zones when the list appears.
    if (#state.campBoxes == 0) and now >= (state.campRetryAt or 0) then
        state.campBoxes = collectCampBoxes()
        state.campRetryAt = now + 5.0
        if #state.campBoxes > 0 and state.zonesReady then
            state.zonesReady = false
            state.spacingUsed = 0
        end
    end

    -- World-dependent initialisation, repeated when the hero/team or spacing changes.
    local needZones = (not state.zonesReady) or (#state.zones == 0)
        or (state.spacingUsed ~= spacing) or (state.heroTeam ~= team)
        or (state.mineCampsUsed ~= allowCamps)
    if needZones and now >= (state.zoneRetryAt or 0) then
        local ok, err = pcall(initializeZones, hero)
        if not ok then noteError("initializeZones", err) end
        if not state.zonesReady then
            state.zoneRetryAt = now + 2.0
            state.statusText = "WAITING_MAP"
            state.statusDetail = "Waiting for GridNav / game start"
        end
    end

    if state.zonesReady and not state.landmarksAnchored and now >= (state.anchorRetryAt or 0) then
        local ok, err = pcall(anchorLandmarksToWorld, true)
        if not ok then noteError("anchorLandmarks", err) end
        if not state.landmarksAnchored then
            state.anchorRetryAt = now + 3.0
        end
    end

    -- Rebuild manual polygon spots when polygons, spacing or camp mode change.
    if state.zonesReady and (state.manualDirty
        or state.manualBuiltVersion ~= state.manualVersion
        or state.manualBuiltSpacing ~= spacing
        or state.manualCampsUsed ~= allowCamps) then
        local ok, err = pcall(rebuildManualZone, hero, spacing)
        if not ok then noteError("rebuildManualZone", err) end
    end
    if state.manualZone ~= nil then
        state.manualZone.enabled = (opt.manualEnabled == nil) or opt.manualEnabled:Get()
    end

    -- Run auto-mining automation
    if opt.enabled:Get() and state.isMining and state.zonesReady then
        executeAutoMiningLogic(hero, now)
    end
end

function script.OnUpdate()
    local ok, err = xpcall(onUpdateImpl, traceErr)
    if not ok then noteError("OnUpdate", err) end
end

local function onDrawImpl()
    if not opt.ready then
        initializeMenu()
        if not opt.ready then return end
    end

    if ui.font == nil then
        local ok, err = pcall(initializeUiAssets)
        if not ok then noteError("initializeUiAssets", err) end
    end

    local isTechies, hero = isPlayingTechies()
    local now = GameRules.GetGameTime()

    if isTechies and hero ~= nil then
        local ok, err = pcall(drawWorldEsp, hero, now)
        if not ok then noteError("drawWorldEsp", err) end

        if opt.worldEsp:Get() or state.drawMode then
            local ok2, err2 = pcall(drawManualWorld)
            if not ok2 then noteError("drawManualWorld", err2) end
        end
    end

    local ok, err = pcall(drawMapPanel, hero, now)
    if not ok then noteError("drawMapPanel", err) end

    pcall(drawDiagnostics, hero)
end

function script.OnDraw()
    local ok, err = xpcall(onDrawImpl, traceErr)
    if not ok then noteError("OnDraw", err) end
end

-- Handle mouse clicks for UI panel interaction and player right-click cancellation
local function onKeyEventImpl(data)
    if not opt.ready or data == nil then
        return true
    end

    local cursorX, cursorY = Input.GetCursorPos()
    local insidePanel = opt.showMap:Get() and ui.panelX ~= nil and ui.panelY ~= nil
                    and cursorX >= ui.panelX and cursorX <= ui.panelX + ui.width
                    and cursorY >= ui.panelY and cursorY <= ui.panelY + ui.height

    -- Consume the rest of a click that was used to add a polygon vertex.
    if state.drawClickConsumed then
        if data.key == Enum.ButtonCode.KEY_MOUSE1
            and data.event == Enum.EKeyEvent.EKeyEvent_KEY_UP then
            state.drawClickConsumed = false
        end
        return false
    end

    -- Manual polygon drawing: LMB in the world adds a vertex, Ctrl+LMB closes
    -- the polygon, RMB/Esc cancels the current one.
    if state.drawMode and not insidePanel then
        if data.key == Enum.ButtonCode.KEY_MOUSE1
            and data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
            state.drawClickConsumed = true
            local wp = Input.GetWorldCursorPos()
            if wp ~= nil then
                table.insert(state.drawPolygon, Vector(wp.x, wp.y, wp.z or 384))
                local ctrl = Input.IsKeyDown(Enum.ButtonCode.KEY_LCONTROL, true)
                    or Input.IsKeyDown(Enum.ButtonCode.KEY_RCONTROL, true)
                if ctrl and #state.drawPolygon >= 3 then
                    table.insert(state.manualPolygons, {
                        points = state.drawPolygon,
                        closed = true
                    })
                    log(string.format("manual polygon added: %d points, total=%d",
                        #state.drawPolygon, #state.manualPolygons))
                    state.drawPolygon = {}
                    state.drawMode = false
                    state.manualVersion = state.manualVersion + 1
                    state.manualDirty = true
                    saveManualPolygons()
                end
            end
            return false
        elseif data.key == Enum.ButtonCode.KEY_MOUSE2
            and data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
            state.drawMode = false
            state.drawPolygon = {}
            state.drawClickConsumed = false
            log("manual drawing cancelled")
            return false
        elseif data.key == Enum.ButtonCode.KEY_ESCAPE
            and data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
            state.drawMode = false
            state.drawPolygon = {}
            state.drawClickConsumed = false
            return false
        end
    end

    -- INTERRUPT: Player right-click anywhere on the game world cancels auto-mining!
    if data.key == Enum.ButtonCode.KEY_MOUSE2 and data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
        if not insidePanel and state.isMining then
            stopAutoMining("Прервано кликом ПКМ по экрану")
            return true -- Allow move order to execute naturally
        end
    end

    if data.key ~= Enum.ButtonCode.KEY_MOUSE1 then
        return true
    end

    local isDown = (data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN)
    local isUp = (data.event == Enum.EKeyEvent.EKeyEvent_KEY_UP)

    if isUp then
        ui.dragging = false
        return true
    end

    if not isDown or not insidePanel then
        return true
    end

    -- 1. Check Close Button
    if ui.closeBounds ~= nil then
        if cursorX >= ui.closeBounds.x and cursorX <= ui.closeBounds.x + ui.closeBounds.w
           and cursorY >= ui.closeBounds.y and cursorY <= ui.closeBounds.y + ui.closeBounds.h
        then
            opt.showMap:Set(false)
            return false
        end
    end

    -- 2. Check Start / Stop Button
    if ui.startBtnBounds ~= nil then
        if cursorX >= ui.startBtnBounds.x and cursorX <= ui.startBtnBounds.x + ui.startBtnBounds.w
           and cursorY >= ui.startBtnBounds.y and cursorY <= ui.startBtnBounds.y + ui.startBtnBounds.h
        then
            if state.isMining then
                stopAutoMining("Остановлено кнопкой на панели")
            else
                startAutoMining()
            end
            return false
        end
    end

    -- 3. Check Toolbar Quick Buttons
    if ui.buttons ~= nil then
        for b = 1, #ui.buttons do
            local btn = ui.buttons[b]
            if cursorX >= btn.x and cursorX <= btn.x + btn.w and cursorY >= btn.y and cursorY <= btn.y + btn.h then
                local isTech, hero = isPlayingTechies()
                local heroTeam = hero and Entity.GetTeamNum(hero) or Enum.TeamNum.TEAM_RADIANT

                if btn.id == "my_side" then
                    for z = 1, #state.zones do
                        state.zones[z].enabled = (state.zones[z].team == heroTeam)
                        Config.WriteInt(C.CONFIG_NAME, "zone_" .. state.zones[z].id, state.zones[z].enabled and 1 or 0)
                    end
                elseif btn.id == "enemy_side" then
                    for z = 1, #state.zones do
                        state.zones[z].enabled = (state.zones[z].team ~= heroTeam)
                        Config.WriteInt(C.CONFIG_NAME, "zone_" .. state.zones[z].id, state.zones[z].enabled and 1 or 0)
                    end
                elseif btn.id == "all" then
                    for z = 1, #state.zones do
                        state.zones[z].enabled = true
                        Config.WriteInt(C.CONFIG_NAME, "zone_" .. state.zones[z].id, 1)
                    end
                elseif btn.id == "clear" then
                    for z = 1, #state.zones do
                        state.zones[z].enabled = false
                        Config.WriteInt(C.CONFIG_NAME, "zone_" .. state.zones[z].id, 0)
                    end
                end
                return false
            end
        end
    end

    -- 4. Check Zone Markers Click
    if ui.markers ~= nil then
        for m = 1, #ui.markers do
            local mark = ui.markers[m]
            local d2 = (cursorX - mark.x) ^ 2 + (cursorY - mark.y) ^ 2
            if d2 <= mark.radius ^ 2 then
                if not mark.zone.isManual then
                    mark.zone.enabled = not mark.zone.enabled
                    Config.WriteInt(C.CONFIG_NAME, "zone_" .. mark.zone.id, mark.zone.enabled and 1 or 0)
                end
                return false
            end
        end
    end

    -- 5. Check Header Dragging
    if cursorY <= ui.panelY + ui.headerHeight then
        ui.dragging = true
        ui.dragOffsetX = cursorX - ui.panelX
        ui.dragOffsetY = cursorY - ui.panelY
        return false
    end

    -- Block mouse click from falling through to the game world
    return false
end

function script.OnKeyEvent(data)
    local ok, res = pcall(onKeyEventImpl, data)
    if not ok then
        noteError("OnKeyEvent", res)
        return true
    end
    return res
end

-- INTERRUPT: Catch any manual unit orders issued by the player
local function onPrepareUnitOrdersImpl(data)
    if not opt.ready or not opt.enabled or not opt.enabled:Get() or data == nil then
        return true
    end

    -- Ignore orders originating from our own script
    if state.isScriptIssuingOrder or data.identifier == C.ORDER_IDENTIFIER then
        return true
    end

    -- If auto-mining is currently running and player gives ANY manual order to the hero:
    if state.isMining then
        local isTech, hero = isPlayingTechies()
        if isTech and hero ~= nil then
            local issuer = data.orderIssuer
            local order = data.order

            -- Check if the order affects our hero
            local affectsHero = false
            if issuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY then
                affectsHero = true
            elseif issuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS or
                   issuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY then
                affectsHero = true
            elseif issuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY then
                if data.npc == hero or (type(data.npc) == "table" and data.npc[1] == hero) then
                    affectsHero = true
                end
            end

            -- If player manually commanded movement, attack, or ability cast:
            if affectsHero then
                local manualOrders = {
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION] = true,
                    [Enum.UnitOrder.DOTA_UNIT_ORDER_STOP] = true
                }

                if manualOrders[order] then
                    stopAutoMining("Прервано ручным действием игрока")
                end
            end
        end
    end

    return true
end

function script.OnPrepareUnitOrders(data)
    local ok, res = pcall(onPrepareUnitOrdersImpl, data)
    if not ok then
        noteError("OnPrepareUnitOrders", res)
        return true
    end
    return res
end

function script.OnGameEnd()
    state.isMining = false
    state.currentTargetSpot = nil
    state.miningPath = {}
    state.zones = {}
    state.existingMines = {}
    state.recentlyPlacedMines = {}
    state.landmarksAnchored = false
    state.isScriptIssuingOrder = false
    state.toggleKeyHeld = false
    state.zonesReady = false
    state.zoneRetryAt = 0
    state.anchorRetryAt = 0
    state.spacingUsed = 0
    state.heroTeam = nil
    state.pendingCast = nil
    state.landmarkCandidates = nil
    state.lastHeroPos = nil
    state.lastHeroPosTime = 0
    state.targetStartTime = 0
    state.targetBestDist = 0
    state.nextTargetRetryAt = 0
    state.campBoxes = {}
    state.campRetryAt = 0
    state.manualSpots = {}
    state.manualZone = nil
    state.manualBuiltVersion = -1
    state.manualBuiltSpacing = 0
    state.drawMode = false
    state.drawPolygon = {}
    state.drawClickConsumed = false
end

return script
