local script = {}

local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local sin, cos, pi, sqrt = math.sin, math.cos, math.pi, math.sqrt
local rand = math.random
pcall(math.randomseed, os.time() + floor(os.clock() * 1000))

-- ===== Состояние (объявлено выше меню, его используют колбэки) =====
local K = {
    mood = "idle", mood_t0 = 0, mood_until = 0, next_mood = nil, next_dur = 0,
    hunger = 80, love = 60,                       -- потребности 0..100
    kills = nil, deaths = nil, alive = nil, src = nil,
    last_poll = 0, last_kill_at = -100, streak = 0, deaths_row = 0, death_at = -100,
    last_activity = os.clock(),
    sleeping = false,
    say_text = "", say_t0 = -100, say_until = -100, say_last = "",
    jump_t0 = -10, blink_t0 = -10, blink_next = 2,
    look = { x = 0, y = 0 },
    rim = { 150, 125, 255 },
    menu_open = false, menu_t0 = 0, menu_seen = 0,
    over_ui = false,
    born = os.clock(), said_hello = false,
    next_chat = os.clock() + 25, last_hungry = os.clock(), next_fx = 0,
    side = 1,                                     -- с какой стороны летит рыбка / мячик
    cand = {}, next_disc = { kills = 0, deaths = 0 },
    g = nil, clicks = 0, mouse_down = false,
}
local P = {}                                      -- частицы
local last_clock = os.clock()
local mouse_prev = false
local mouse_warned = false
local err_printed = false
local on_kill, on_death, dbg_print                -- объявлены заранее для кнопок меню

-- ===== Меню =====
local tab = Menu.Create("General", "Main", "Kitty Widget")
tab:Icon("\u{f1b0}")

local g_main = tab:Create("Kitty"):Create("Main")
local g_look = tab:Create("Look"):Create("Widget")

local FONT_NAMES = { "MuseoSansEx", "Arial", "Verdana", "Tahoma" }

local ui = {}
ui.enabled = g_main:Switch("Enabled", true, "\u{f00c}")
ui.name    = g_main:Input("Cat name", "Мурзик")
ui.lang    = g_main:Combo("Language", { "English", "Russian" }, 1)
ui.chatty  = g_main:Slider("Chattiness (%)", 0, 100, 60)
ui.t_kill  = g_main:Button("Test: kill", function() on_kill(1) end)
ui.t_death = g_main:Button("Test: death", function() on_death() end)
ui.t_dbg   = g_main:Button("Print debug info", function() dbg_print() end)
g_main:Label("Click the cat to open the action menu")

ui.pos_x   = g_look:Slider("Position X (%)", 0, 100, 98)
ui.pos_y   = g_look:Slider("Position Y (%)", 0, 100, 1)
ui.scale   = g_look:Slider("Scale (%)", 60, 220, 100)
ui.opacity = g_look:Slider("Opacity (%)", 30, 100, 100)
ui.font    = g_look:Combo("Font", FONT_NAMES, 0)
ui.ledge   = g_look:Switch("Show ledge (black line)", true)
ui.glow    = g_look:Switch("Mood glow", true)
ui.fx      = g_look:Switch("Particles", true)
ui.needs   = g_look:Switch("Needs bars on hover", true)
ui.debug   = g_look:Switch("Debug overlay", true)

-- ===== Шрифты =====
local fonts = {}
for i, name in ipairs(FONT_NAMES) do
    fonts[i] = Render.LoadFont(name, Enum.FontCreate.FONTFLAG_ANTIALIAS, 500)
end

local function get_font()
    local idx = (ui.font:Get() or 0) + 1
    return fonts[idx] or fonts[1]
end

-- ===== Фразы =====
local PH = {}

PH.ru = {
    hello = {
        "Мяу! Я {n}. Буду сидеть тут и тихо осуждать.",
        "Привет! Я {n}. Ничего не делаю, зато красиво.",
        "О, ты пришёл. А я как раз ничего не делал.",
    },
    idle = {
        "Мур. Смотрю на крипов. Крипы смотрят на меня.",
        "Хвост двигается. Это всё, что я умею.",
        "Я бы пикнул кота, но такого героя нет.",
        "Если ты читаешь это, значит, ты не смотришь на миникарту.",
        "Хочу рыбку. Или рошана. Или рыбку из рошана.",
        "Прошёл час. Или минута. Я не умею в время.",
        "Знаешь, чем я лучше твоего саппорта? Я хотя бы красиво сижу.",
        "Мяу. Это был совет по игре.",
        "Я не спал. Я отдыхал глазами.",
        "Если упадёшь с башни, я сделаю вид, что не видел.",
    },
    bored = {
        "Скууучно... Убей кого-нибудь, а?",
        "Я зеваю. Ты тоже зевни. Давай, не стесняйся.",
        "Тут так тихо, что я слышу, как растут крипы.",
    },
    kill1 = {
        "Мяу! Один готов!",
        "Красиво! Я даже не моргнул... ладно, моргнул.",
        "Фраг! Мне положена рыбка.",
        "Он даже не понял, откуда прилетело.",
        "+1. Продолжай, и я стану твоим фанатом.",
    },
    kill2 = {
        "ДАБЛ КИЛЛ! МЯУ!",
        "Двое сразу! Хвост в шоке, я в шоке.",
        "Два по цене одного. Люблю скидки!",
    },
    kill3 = {
        "ТРИПЛ КИЛЛ! Мне надо присесть. Я уже сижу. Всё равно надо!",
        "Трое! Мур-р-р, ты просто зверь!",
        "Три фрага! Я так горжусь, что забыл вылизываться.",
    },
    kill4 = {
        "РАМПАГА! Все коты мира гордятся тобой!",
        "Они убегают! Не останавливайся!",
        "Это уже не игра, это охота. Я в восторге!",
    },
    death1 = {
        "Мяу?! Ты умер?!",
        "Ну... бывает. Это был лаг, да?",
        "Я не смотрел. Честно. (Смотрел.)",
        "Вставай, нас ждёт рыбка.",
    },
    death2 = {
        "Опять?! Мур... нет.",
        "Уже второй раз кормишь врага. Может, лучше меня?",
        "Может, рыбки перед следующей жизнью?",
    },
    death3 = {
        "ТИЛЬТ. Я чувствую тильт. Дыши. Мяу.",
        "Три смерти подряд. Давай просто погладим кота и забудем.",
        "Ладно. Я злюсь. Вместе с тобой.",
    },
    respawn = {
        "С возвращением! Я скучал. Минут пять.",
        "Воскрес! Теперь не ходи туда.",
        "О, ты живой. Не делай так больше.",
    },
    pet = {
        "Мурррр...",
        "Ещё! Нет, ещё! Нет, хватит! Нет, ещё.",
        "Ты лучший. По крайней мере, лучше врага.",
        "М-р-р-р... тильт уходит.",
    },
    feed = {
        "Ням! Лучшая рыбка в патче.",
        "Чавк-чавк. Баланс восстановлен.",
        "Хрум. Теперь я готов к ганку.",
    },
    full = {
        "Я не голоден. Лучше погладь.",
        "Не-не, я сыт. Давай лучше поиграем.",
    },
    hungry = {
        "Я голоден. Когда там рыбка?",
        "Мой живот урчит громче, чем твои тиммейты.",
        "Не покормишь, начну есть крипов.",
    },
    play = {
        "Мячик! Мячик! МЯЧИК!",
        "Лови! Нет, это я ловлю!",
        "Я убиваю этот шар. Это мой первый килл.",
    },
    sleep = {
        "Zzz... разбуди, если будет Рошан.",
        "Спокойной ночи. Или дня. Тут не понять.",
    },
    wake = {
        "Мяу?! Я проспал ганк?",
        "Я не спал. Я проверял веки изнутри.",
    },
    stats = "{n}: убийств {k}, смертей {d}. Сытость {h}%, любовь {l}%.",
    nostats = "Статистику героя не вижу, но выглядишь уверенно. Сытость {h}%, любовь {l}%.",
}

PH.en = {
    hello = {
        "Meow! I'm {n}. I'll sit here and quietly judge you.",
        "Hi! I'm {n}. I do nothing, but beautifully.",
        "Oh, you're here. I was just doing nothing.",
    },
    idle = {
        "Purr. Watching creeps. Creeps watching me.",
        "Tail is moving. That's all I can do.",
        "I'd pick cat, but there's no such hero.",
        "If you're reading this, you're not watching the minimap.",
        "I want fish. Or Roshan. Or fish from Roshan.",
        "An hour passed. Or a minute. I can't time.",
        "If you fall off a tower, I'll pretend I didn't see.",
        "Meow. That was a gameplay tip.",
    },
    bored = {
        "Boooored... kill someone, will you?",
        "I'm yawning. Yawn with me. Don't be shy.",
        "It's so quiet I can hear the creeps grow.",
    },
    kill1 = {
        "Meow! One down!",
        "Beautiful! I didn't even blink... okay, I blinked.",
        "Frag! I deserve a fish.",
        "He never saw it coming.",
    },
    kill2 = {
        "DOUBLE KILL! MEOW!",
        "Two at once! My tail is in shock.",
    },
    kill3 = {
        "TRIPLE KILL! I need to sit down. I'm already sitting. Still!",
        "Three! You absolute beast!",
    },
    kill4 = {
        "RAMPAGE! Every cat in the world is proud!",
        "They're running! Don't stop!",
    },
    death1 = {
        "Meow?! You died?!",
        "Well... it happens. It was lag, right?",
        "I wasn't looking. Honest. (I was.)",
    },
    death2 = {
        "Again?! Purr... no.",
        "Feeding the enemy twice now. Feed me instead?",
    },
    death3 = {
        "TILT. I can feel the tilt. Breathe. Meow.",
        "Three deaths in a row. Let's just pet the cat and forget.",
        "Okay. I'm mad. Together with you.",
    },
    respawn = {
        "Welcome back! I missed you. For five minutes.",
        "You're alive! Don't go there again.",
    },
    pet = {
        "Purrrr...",
        "More! No, more! No, stop! No, more.",
        "You're the best. At least better than the enemy.",
    },
    feed = {
        "Yum! Best fish of the patch.",
        "Nom nom. Balance restored.",
        "Crunch. Ready to gank now.",
    },
    full = {
        "I'm not hungry. Pet me instead.",
        "Nope, I'm full. Let's play instead.",
    },
    hungry = {
        "I'm hungry. Where's my fish?",
        "My stomach growls louder than your teammates.",
        "Feed me or I'll start eating creeps.",
    },
    play = {
        "Ball! Ball! BALL!",
        "Catch! No, I'm catching!",
        "I'm killing this ball. My first kill.",
    },
    sleep = {
        "Zzz... wake me up if Roshan spawns.",
        "Good night. Or day. Can't tell in here.",
    },
    wake = {
        "Meow?! Did I miss a gank?",
        "I wasn't sleeping. I was checking my eyelids.",
    },
    stats = "{n}: kills {k}, deaths {d}. Fed {h}%, love {l}%.",
    nostats = "I can't see hero stats, but you look confident. Fed {h}%, love {l}%.",
}

local LABEL = {
    ru = { pet = "Погладить", feed = "Покормить", play = "Поиграть", sleep = "Спать",
           wake = "Разбудить", chat = "Поболтать", stats = "Статистика" },
    en = { pet = "Pet", feed = "Feed", play = "Play", sleep = "Sleep",
           wake = "Wake up", chat = "Chat", stats = "Stats" },
}

local ACTIONS = {
    { id = "pet",   icon = "heart" },
    { id = "feed",  icon = "fish" },
    { id = "play",  icon = "ball" },
    { id = "sleep", icon = "moon" },
    { id = "chat",  icon = "chat" },
    { id = "stats", icon = "bars" },
}

-- ===== Цвета =====
local BODY = { 18, 18, 27 }
local RIM = {
    idle = { 150, 125, 255 }, bored = { 120, 110, 180 }, happy = { 255, 190, 120 },
    love = { 255, 120, 170 }, eat = { 255, 180, 110 }, excited = { 255, 214, 100 },
    shock = { 200, 220, 255 }, sad = { 110, 150, 230 }, angry = { 255, 80, 80 },
    sleep = { 100, 110, 200 }, play = { 120, 230, 200 },
}

-- скорость и размах движения хвоста по настроению
local TAIL = {
    idle = { 2.2, 0.16 }, bored = { 1.2, 0.08 }, happy = { 5, 0.30 }, love = { 6, 0.32 },
    eat = { 5, 0.25 }, excited = { 10, 0.45 }, shock = { 0, 0 }, sad = { 1, 0.05 },
    angry = { 16, 0.50 }, sleep = { 0.8, 0.04 }, play = { 7, 0.40 },
}

-- ===== Вспомогательное =====
local function clamp(v, lo, hi) return max(lo, min(hi, v)) end

local function ease_out_cubic(x)
    x = clamp(x, 0, 1)
    return 1 - (1 - x) ^ 3
end

local function ease_out_back(x)
    x = clamp(x, 0, 1)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function col(c, a, k)
    k = k or 1
    return Color(floor(c[1] * k), floor(c[2] * k), floor(c[3] * k), floor(a or 255))
end

local function text(size, str, x, y, color, shadow)
    local f = get_font()
    size = floor(size)
    if shadow ~= false then
        Render.Text(f, size, str, Vec2(x + 1, y + 1), Color(0, 0, 0, floor(color.a * 0.55)))
    end
    Render.Text(f, size, str, Vec2(x, y), color)
end

local function text_dim(size, str)
    local ok, w, h = pcall(function()
        local v = Render.TextSize(get_font(), floor(size), str)
        return v.x, v.y
    end)
    if ok and w then return w, h end
    return #str * size * 0.5, size
end

local function ulen(s)
    local ok, n = pcall(utf8.len, s)
    if ok and n then return n end
    return #s
end

local function usub(s, n)
    if n <= 0 then return "" end
    local ok, o = pcall(utf8.offset, s, n + 1)
    if ok and o then return s:sub(1, o - 1) end
    return s
end

local function wrap(str, maxw, size)
    local lines, cur = {}, ""
    for word in str:gmatch("%S+") do
        local try_s = (cur == "") and word or (cur .. " " .. word)
        if cur ~= "" and text_dim(size, try_s) > maxw then
            lines[#lines + 1] = cur
            cur = word
        else
            cur = try_s
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

local function in_rect(mx, my, x1, y1, x2, y2)
    return mx ~= nil and my ~= nil and mx >= x1 and mx <= x2 and my >= y1 and my <= y2
end

local function lang_tab()
    return ((ui.lang:Get() or 0) == 1) and PH.ru or PH.en
end

local function lang_key()
    return ((ui.lang:Get() or 0) == 1) and "ru" or "en"
end

local function fmt(str, vars)
    vars = vars or {}
    local nm = ui.name:Get() or ""
    if nm == "" then nm = "Kitty" end
    vars.n = vars.n or nm
    return (str:gsub("{(%w+)}", function(k) return tostring(vars[k] or "") end))
end

-- ===== Ввод =====
local MOUSE1
do
    local ok, bc = pcall(function() return Enum.ButtonCode end)
    if ok and bc then
        for _, nm in ipairs({ "KEY_MOUSE1", "MOUSE_LEFT", "KEY_MOUSE_LEFT", "MOUSE1", "BUTTON_LEFT" }) do
            local ok2, v = pcall(function() return bc[nm] end)
            if ok2 and v ~= nil then MOUSE1 = v break end
        end
    end
end

local function cursor()
    for _, nm in ipairs({ "GetCursorPos", "GetMousePos" }) do
        local f = Input and Input[nm]
        if type(f) == "function" then
            local ok, a, b = pcall(f)
            if ok and a ~= nil then
                if type(a) == "number" then return a, b end   -- вернулись два числа
                local ok2, x, y = pcall(function() return a.x, a.y end)
                if ok2 and x then return x, y end             -- вернулся Vec2
            end
        end
    end
    return nil, nil
end

local function mouse_clicked()
    if not MOUSE1 then
        if not mouse_warned then
            mouse_warned = true
            print("[Kitty] mouse button enum not found, clicks disabled")
        end
        return false
    end
    local once = false
    local ok1, v1 = pcall(function() return Input.IsKeyDownOnce(MOUSE1) end)
    if ok1 and v1 == true then once = true end
    local ok2, v2 = pcall(function() return Input.IsKeyDown(MOUSE1) end)
    local down = ok2 and v2 == true
    local edge = down and not mouse_prev
    mouse_prev = down
    K.mouse_down = down
    return once or edge
end

-- ===== Чтение игры (все обращения к API через pcall, чтобы ничего не падало) =====
local function api(tbl, fn, ...)
    local t = _G[tbl]
    local f = t and t[fn]
    if type(f) ~= "function" then return nil end
    local ok, v = pcall(f, ...)
    if ok then return v end
    return nil
end

local ARG_ORDER = { "lp", "pid", "hero" }

-- ищем среди всех глобальных таблиц функцию вроде GetKills, которая принимает игрока/ид/героя и отдаёт число
local function find_stat(kind, names, args, t)
    local c = K.cand[kind]
    if c then
        local tb = _G[c.tbl]
        local f = tb and tb[c.fn]
        local arg = args[c.arg]
        if type(f) == "function" and arg ~= nil then
            local ok, v = pcall(f, arg)
            if ok and type(v) == "number" then return v, c.tbl .. "." .. c.fn end
        end
    end
    if t < K.next_disc[kind] then return nil end
    K.next_disc[kind] = t + 3

    for tn, tv in pairs(_G) do
        if type(tn) == "string" and type(tv) == "table" then
            for _, fn in ipairs(names) do
                local okf, f = pcall(function() return tv[fn] end)
                if okf and type(f) == "function" then
                    for _, an in ipairs(ARG_ORDER) do
                        local arg = args[an]
                        if arg ~= nil then
                            local ok, v = pcall(f, arg)
                            if ok and type(v) == "number" then
                                K.cand[kind] = { tbl = tn, fn = fn, arg = an }
                                print(("[Kitty] %s source: %s.%s(%s)"):format(kind, tn, fn, an))
                                return v, tn .. "." .. fn
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function read_game(t)
    local lp   = api("Players", "GetLocal")
    local hero = api("Heroes", "GetLocal")
    if hero == nil and lp ~= nil then hero = api("Player", "GetAssignedHero", lp) end

    local alive
    if hero ~= nil then
        alive = api("Entity", "IsAlive", hero)
        if alive == nil then alive = api("NPC", "IsAlive", hero) end
        if alive == nil then
            local hp = api("Entity", "GetHealth", hero)
            if type(hp) == "number" then alive = hp > 0 end
        end
    end

    local pid = lp ~= nil and api("Player", "GetPlayerID", lp) or nil
    local args = { lp = lp, pid = pid, hero = hero }
    local kills, ksrc = find_stat("kills", { "GetKills", "GetPlayerKills", "GetHeroKills" }, args, t)
    local deaths = find_stat("deaths", { "GetDeaths", "GetPlayerDeaths", "GetHeroDeaths" }, args, t)

    return { kills = kills, deaths = deaths, alive = alive, src = ksrc,
             lp = lp ~= nil, hero = hero ~= nil }
end

dbg_print = function()
    local g = read_game(math.huge)
    print(("[Kitty] lp=%s hero=%s kills=%s deaths=%s alive=%s src=%s"):format(
        tostring(g.lp), tostring(g.hero), tostring(g.kills), tostring(g.deaths), tostring(g.alive), tostring(g.src)))
    local mx, my = cursor()
    print(("[Kitty] cursor=%s,%s MOUSE1=%s"):format(tostring(mx), tostring(my), tostring(MOUSE1)))

    local pats = { "kill", "death", "alive", "dead", "cursor", "mouse", "click", "keydown", "getlocal", "assigned" }
    local lines = {}
    for tn, tv in pairs(_G) do
        if type(tn) == "string" and type(tv) == "table" then
            local hit = {}
            pcall(function()
                for fn, fv in pairs(tv) do
                    if type(fn) == "string" and type(fv) == "function" then
                        local l = fn:lower()
                        for _, pt in ipairs(pats) do
                            if l:find(pt, 1, true) then hit[#hit + 1] = fn break end
                        end
                    end
                end
            end)
            if #hit > 0 then
                table.sort(hit)
                lines[#lines + 1] = tn .. ": " .. table.concat(hit, ", ")
            end
        end
    end
    table.sort(lines)
    for _, l in ipairs(lines) do print("[Kitty] " .. l) end

    local mouse = {}
    pcall(function()
        for nm in pairs(Enum.ButtonCode) do
            if type(nm) == "string" and nm:upper():find("MOUSE", 1, true) then mouse[#mouse + 1] = nm end
        end
    end)
    table.sort(mouse)
    print("[Kitty] Enum.ButtonCode mouse names: " .. table.concat(mouse, ", "))
end

-- ===== Рисование: примитивы =====
-- заливка треугольника веером линий из вершины a (не зависит от наличия FilledPolygon)
local function tri(ax, ay, bx, by, cx, cy, color, thick, n)
    n = n or 10
    local a = Vec2(ax, ay)
    for i = 0, n do
        local u = i / n
        Render.Line(a, Vec2(bx + (cx - bx) * u, by + (cy - by) * u), color, thick)
    end
end

local function arc_pts(cx, cy, r, a0, a1, n)
    local pts = {}
    for i = 0, n do
        local a = a0 + (a1 - a0) * i / n
        pts[#pts + 1] = Vec2(cx + cos(a) * r, cy + sin(a) * r)
    end
    return pts
end

local function heart(cx, cy, sz, color)
    Render.FilledCircle(Vec2(cx - sz * 0.5, cy - sz * 0.2), sz * 0.55, color)
    Render.FilledCircle(Vec2(cx + sz * 0.5, cy - sz * 0.2), sz * 0.55, color)
    tri(cx, cy + sz * 1.05, cx - sz * 1.0, cy - sz * 0.05, cx + sz * 1.0, cy - sz * 0.05,
        color, max(1.2, sz * 0.2), 8)
end

local function star4(cx, cy, r, rot, color)
    local ir = r * 0.3
    for i = 0, 3 do
        local a = rot + i * pi / 2
        local a1, a2 = a - pi / 4, a + pi / 4
        tri(cx + cos(a) * r, cy + sin(a) * r,
            cx + cos(a1) * ir, cy + sin(a1) * ir,
            cx + cos(a2) * ir, cy + sin(a2) * ir, color, max(1, r * 0.14), 4)
    end
    Render.FilledCircle(Vec2(cx, cy), ir * 1.05, color)
end

local function fish(cx, cy, s, dir, alpha)
    local a = alpha or 255
    local c = Color(255, 168, 90, a)
    Render.FilledCircle(Vec2(cx, cy), s * 0.8, c)
    Render.FilledCircle(Vec2(cx + dir * s * 0.6, cy), s * 0.65, c)
    tri(cx - dir * s * 0.5, cy, cx - dir * s * 1.7, cy - s * 0.75, cx - dir * s * 1.7, cy + s * 0.75,
        c, max(1.2, s * 0.25), 8)
    Render.FilledCircle(Vec2(cx + dir * s * 1.0, cy - s * 0.2), max(0.8, s * 0.14), Color(30, 30, 40, a))
end

local function draw_icon(kind, cx, cy, s, color, bg)
    if kind == "heart" then
        heart(cx, cy - s * 0.1, s * 0.55, color)
    elseif kind == "fish" then
        fish(cx + s * 0.1, cy, s * 0.5, 1, color.a)
    elseif kind == "ball" then
        Render.FilledCircle(Vec2(cx, cy), s * 0.75, color)
        Render.Line(Vec2(cx - s * 0.5, cy - s * 0.2), Vec2(cx + s * 0.5, cy + s * 0.2), bg, 1.2)
    elseif kind == "moon" then
        Render.FilledCircle(Vec2(cx, cy), s * 0.75, color)
        Render.FilledCircle(Vec2(cx + s * 0.4, cy - s * 0.2), s * 0.62, bg)
    elseif kind == "chat" then
        Render.FilledRect(Vec2(cx - s * 0.8, cy - s * 0.55), Vec2(cx + s * 0.8, cy + s * 0.45), color, s * 0.3)
        for i = -1, 1 do
            Render.FilledCircle(Vec2(cx + i * s * 0.4, cy - s * 0.05), max(0.8, s * 0.1), bg)
        end
    elseif kind == "bars" then
        local hs = { 0.5, 0.95, 0.7 }
        for i = 1, 3 do
            local bx = cx + (i - 2) * s * 0.5
            Render.FilledRect(Vec2(bx - s * 0.16, cy + s * 0.55 - hs[i] * s * 1.1),
                Vec2(bx + s * 0.16, cy + s * 0.55), color, 1.5)
        end
    end
end

-- ===== Частицы (координаты в "единицах" относительно кота, умножаются на масштаб) =====
local function emit(kind, x, y, vx, vy, life, sz, extra)
    if not ui.fx:Get() then return end
    if #P > 70 then table.remove(P, 1) end
    P[#P + 1] = { k = kind, x = x, y = y, vx = vx, vy = vy, born = os.clock(),
                  life = life, sz = sz or 4, ex = extra, ph = rand() * 6.28 }
end

local function update_particles(dt, t)
    local i = 1
    while i <= #P do
        local p = P[i]
        if t - p.born >= p.life then
            table.remove(P, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            if p.k == "tear" or p.k == "crumb" then p.vy = p.vy + 170 * dt end
            i = i + 1
        end
    end
end

local function draw_particles(cx, ground, S, t)
    for _, p in ipairs(P) do
        local age = t - p.born
        local u = age / p.life
        local a = max(0, 1 - u * u)
        local px, py = cx + p.x * S, ground + p.y * S
        local k = p.k
        if k == "heart" then
            heart(px + sin(age * 4 + p.ph) * 4 * S, py, p.sz * S * (0.6 + 0.4 * min(1, age * 4)),
                Color(255, 110, 160, floor(255 * a)))
        elseif k == "star" then
            star4(px, py, p.sz * S * (1 - u * 0.5), age * 5 + p.ph, Color(255, 226, 120, floor(255 * a)))
        elseif k == "tear" then
            Render.FilledCircle(Vec2(px, py), p.sz * S, Color(150, 200, 255, floor(220 * a)))
        elseif k == "crumb" then
            Render.FilledCircle(Vec2(px, py), p.sz * S, Color(255, 190, 110, floor(255 * a)))
        elseif k == "smoke" then
            Render.FilledCircle(Vec2(px, py), p.sz * S * (1 + u), Color(120, 120, 140, floor(150 * a)))
        elseif k == "z" then
            local size = p.sz * S * (1 + u * 0.8)
            text(size, "z", px + sin(age * 2 + p.ph) * 5 * S, py, Color(210, 220, 255, floor(255 * a)), false)
        elseif k == "text" then
            local size = p.sz * S
            local w = text_dim(size, p.ex.str)
            text(size, p.ex.str, px - w * 0.5, py, Color(p.ex.c[1], p.ex.c[2], p.ex.c[3], floor(255 * a)))
        end
    end
end

-- ===== Настроение и речь =====
local function set_mood(name, dur, nxt, nxt_dur)
    local t = os.clock()
    K.mood, K.mood_t0 = name, t
    K.mood_until = t + (dur or 3)
    K.next_mood, K.next_dur = nxt, nxt_dur or 4
end

local function base_mood(t)
    if K.sleeping then return "sleep" end
    if K.hunger < 25 or (t - K.last_activity) > 150 then return "bored" end
    return "idle"
end

local function say_text(str, dur)
    str = fmt(str)
    K.say_last = str
    local n = ulen(str)
    K.say_text = str
    K.say_t0 = os.clock()
    K.say_until = K.say_t0 + n / 34 + (dur or max(2.6, n / 15))
end

local function say(key, vars)
    local pool = lang_tab()[key]
    local str
    if type(pool) == "table" then
        for _ = 1, 4 do
            str = pool[rand(#pool)]
            if fmt(str, vars) ~= K.say_last or #pool == 1 then break end
        end
    else
        str = tostring(pool or key)
    end
    say_text(fmt(str, vars))
end

local function stats_text()
    local lang = lang_tab()
    local vars = { h = floor(K.hunger + 0.5), l = floor(K.love + 0.5) }
    if K.kills then
        vars.k = K.kills
        vars.d = K.deaths or "?"
        return fmt(lang.stats, vars)
    end
    return fmt(lang.nostats, vars)
end

-- ===== События игры =====
on_kill = function(n)
    local t = os.clock()
    n = n or 1
    if t - K.last_kill_at < 20 then K.streak = K.streak + n else K.streak = n end
    K.last_kill_at, K.deaths_row, K.last_activity = t, 0, t
    K.love = min(100, K.love + 2 * n)
    K.sleeping = false
    K.jump_t0 = t
    set_mood("excited", 3.4)

    emit("text", 0, -112, 0, -26, 1.6, 17,
        { str = (K.streak > 1) and ("x" .. K.streak) or "+1", c = { 255, 226, 120 } })
    for _ = 1, 10 do
        local a, sp = rand() * 2 * pi, 40 + rand() * 60
        emit("star", 0, -60, cos(a) * sp, sin(a) * sp * 0.8 - 30, 0.9 + rand() * 0.4, 4 + rand() * 4)
    end
    say(K.streak >= 4 and "kill4" or ("kill" .. max(1, K.streak)))
end

on_death = function()
    local t = os.clock()
    K.death_at, K.streak, K.last_activity = t, 0, t
    K.deaths_row = K.deaths_row + 1
    K.sleeping = false
    if K.deaths_row >= 3 then
        set_mood("shock", 1.0, "angry", 6)
        say("death3")
    else
        set_mood("shock", 1.0, "sad", 5)
        say("death" .. K.deaths_row)
    end
end

local function on_respawn()
    K.last_activity = os.clock()
    set_mood("happy", 3)
    say("respawn")
end

local function tick_game(t)
    if t - K.last_poll < 0.25 then return end
    K.last_poll = t

    local g = read_game(t)
    K.g = g
    if not g.lp and not g.hero then
        K.kills, K.deaths, K.alive = nil, nil, nil
        return
    end
    if g.src and K.src ~= g.src then
        K.src = g.src
        print("[Kitty] stats source: " .. g.src)
    end

    if g.kills then
        if K.kills == nil or g.kills < K.kills then
            K.kills = g.kills
        elseif g.kills > K.kills then
            local n = g.kills - K.kills
            K.kills = g.kills
            on_kill(n)
        end
    end

    if g.deaths then
        if K.deaths == nil or g.deaths < K.deaths then
            K.deaths = g.deaths
        elseif g.deaths > K.deaths then
            K.deaths = g.deaths
            on_death()
        end
    end

    if g.alive ~= nil then
        -- без счётчика смертей ловим смерть по смене состояния
        if K.alive == true and g.alive == false and not g.deaths and t - K.death_at > 2 then
            on_death()
        end
        if K.alive == false and g.alive == true then on_respawn() end
        K.alive = g.alive
    end
end

-- ===== Действия из меню =====
local function do_action(id)
    local t = os.clock()
    K.last_activity = t
    K.side = (rand() < 0.5) and -1 or 1

    if id == "pet" then
        K.sleeping = false
        K.love = min(100, K.love + 12)
        set_mood("love", 4.2)
        say("pet")
    elseif id == "feed" then
        K.sleeping = false
        if K.hunger > 88 then
            set_mood("idle", 1)
            say("full")
        else
            K.hunger = min(100, K.hunger + 35)
            set_mood("eat", 3.4, "happy", 2.5)
            say("feed")
        end
    elseif id == "play" then
        K.sleeping = false
        K.hunger = max(0, K.hunger - 3)
        K.love = min(100, K.love + 5)
        set_mood("play", 5.5, "happy", 2)
        say("play")
    elseif id == "sleep" then
        K.sleeping = not K.sleeping
        if K.sleeping then
            say("sleep")
        else
            set_mood("shock", 0.7)
            say("wake")
        end
    elseif id == "chat" then
        K.sleeping = false
        set_mood("happy", 2.2)
        say(K.hunger < 25 and "hungry" or "idle")
    elseif id == "stats" then
        K.sleeping = false
        set_mood("happy", 2)
        say_text(stats_text(), 5)
    end
end

-- ===== Обновление логики =====
local function update(dt, t)
    K.hunger = max(0, K.hunger - dt * 0.045)
    K.love = max(0, K.love - dt * 0.012)

    -- моргание
    if t >= K.blink_next then
        K.blink_t0 = t
        K.blink_next = t + ((rand() < 0.2) and 0.35 or (2 + rand() * 3.5))
    end

    -- смена настроения
    if t >= K.mood_until then
        if K.next_mood then
            set_mood(K.next_mood, K.next_dur)
        else
            local bm = base_mood(t)
            if K.mood ~= bm then K.mood, K.mood_t0 = bm, t end
        end
    end

    -- плавная смена цвета подсветки
    local target = RIM[K.mood] or RIM.idle
    local k = min(1, dt * 5)
    for i = 1, 3 do K.rim[i] = K.rim[i] + (target[i] - K.rim[i]) * k end

    -- эффекты по настроению
    if t >= K.next_fx then
        local m = K.mood
        if m == "love" then
            emit("heart", (rand() - 0.5) * 34, -90, (rand() - 0.5) * 10, -28, 1.5, 5 + rand() * 3)
            K.next_fx = t + 0.3
        elseif m == "eat" then
            emit("crumb", (rand() - 0.5) * 8, -52, (rand() - 0.5) * 55, -30 - rand() * 30, 0.7, 1.7)
            K.next_fx = t + 0.16
        elseif m == "sad" then
            local sg = (rand() < 0.5) and -1 or 1
            emit("tear", sg * 11, -60, 0, 18, 1.2, 2.4)
            K.next_fx = t + 0.8
        elseif m == "sleep" then
            emit("z", 18, -92, 8, -14, 2.4, 11)
            K.next_fx = t + 1.0
        elseif m == "angry" then
            local sg = (rand() < 0.5) and -1 or 1
            emit("smoke", sg * 16, -92, sg * 10, -22, 0.9, 4.5)
            K.next_fx = t + 0.3
        else
            K.next_fx = t + 0.2
        end
    end

    -- приветствие и болтовня
    local chatty = ui.chatty:Get() or 0
    local speaking = t < K.say_until
    if not K.said_hello and t - K.born > 1.4 then
        K.said_hello = true
        say("hello")
    elseif chatty > 0 and not speaking and not K.menu_open then
        if K.hunger < 25 and t - K.last_hungry > 75 and not K.sleeping then
            K.last_hungry = t
            say("hungry")
        elseif t >= K.next_chat then
            K.next_chat = t + (35 + rand() * 45) * (100 / max(chatty, 10))
            if not K.sleeping then
                say(((t - K.last_activity) > 150) and "bored" or "idle")
            end
        end
    end

    update_particles(dt, t)
end

-- ===== Рисование: котик =====
local function draw_eyes(hx, ey, lx, ly, S, t, mood)
    local W = Color(255, 255, 255, 255)
    local bc = Color(BODY[1], BODY[2], BODY[3], 255)
    local sp, r = 11 * S, 6.4 * S

    local bl = (t - K.blink_t0) / 0.17
    local lid = 0
    if bl >= 0 and bl < 1 then lid = (bl < 0.5) and bl * 2 or (1 - bl) * 2 end

    for _, sg in ipairs({ -1, 1 }) do
        local ex, eyy = hx + sg * sp + lx, ey + ly
        if mood == "happy" or mood == "eat" then
            Render.PolyLine(arc_pts(ex, eyy + 2.5 * S, r * 0.95, pi, 2 * pi, 8), W, 2.6 * S)
        elseif mood == "sleep" then
            Render.PolyLine(arc_pts(ex, eyy - 1.5 * S, r * 0.95, 0, pi, 8), W, 2.4 * S)
        elseif mood == "love" then
            heart(ex, eyy - 1 * S, r * (0.95 + 0.12 * sin(t * 8)), W)
        elseif mood == "excited" then
            Render.FilledCircle(Vec2(ex, eyy), r * 1.2, W)
            star4(ex, eyy, r * 0.8, t * 2.5, bc)
        elseif mood == "shock" then
            Render.FilledCircle(Vec2(ex, eyy), r * 1.3, W)
            Render.FilledCircle(Vec2(ex, eyy), r * 0.22, bc)
        else
            -- белые пустые глазки
            local rr = (mood == "play") and r * 1.12 or r
            Render.FilledCircle(Vec2(ex, eyy), rr, W)
            local ll = lid
            if mood == "bored" then ll = max(lid, 0.5) end
            if ll > 0.02 then
                Render.FilledRect(Vec2(ex - rr - 1, eyy - rr - 1), Vec2(ex + rr + 1, eyy - rr + 2 * rr * ll), bc)
            end
            if mood == "sad" then
                tri(ex + sg * rr * 1.3, eyy - rr * 0.1,
                    ex - sg * rr * 1.3, eyy - rr * 1.3,
                    ex + sg * rr * 1.3, eyy - rr * 1.3, bc, 2.2 * S, 10)
            elseif mood == "angry" then
                tri(ex - sg * rr * 1.3, eyy - rr * 0.1,
                    ex + sg * rr * 1.3, eyy - rr * 1.3,
                    ex - sg * rr * 1.3, eyy - rr * 1.3, bc, 2.2 * S, 10)
            end
        end
    end
end

local function draw_mouth(hx, my, S, t, mood)
    local W = Color(255, 255, 255, 235)
    local bc = Color(BODY[1], BODY[2], BODY[3], 255)
    local pink = Color(235, 95, 130, 255)

    if mood == "happy" or mood == "love" or mood == "excited" or mood == "play" then
        Render.FilledCircle(Vec2(hx, my + 0.5 * S), 5 * S, pink)
        Render.FilledRect(Vec2(hx - 7 * S, my - 6 * S), Vec2(hx + 7 * S, my + 0.5 * S), bc)
        Render.PolyLine(arc_pts(hx, my + 0.5 * S, 5 * S, 0, pi, 10), W, 1.3 * S)
    elseif mood == "eat" then
        local r = (1.8 + abs(sin(t * 13)) * 3.4) * S
        Render.FilledCircle(Vec2(hx, my + 2 * S), r + 1 * S, W)
        Render.FilledCircle(Vec2(hx, my + 2 * S), r, pink)
    elseif mood == "shock" then
        Render.FilledCircle(Vec2(hx, my + 2.5 * S), 3.6 * S, W)
        Render.FilledCircle(Vec2(hx, my + 2.5 * S), 2.7 * S, pink)
    elseif mood == "sad" then
        Render.PolyLine(arc_pts(hx, my + 5 * S, 4.2 * S, pi, 2 * pi, 8), W, 1.5 * S)
    elseif mood == "angry" then
        local pts = {
            Vec2(hx - 6 * S, my + 3 * S), Vec2(hx - 3 * S, my + 1 * S), Vec2(hx, my + 3 * S),
            Vec2(hx + 3 * S, my + 1 * S), Vec2(hx + 6 * S, my + 3 * S),
        }
        Render.PolyLine(pts, W, 1.4 * S)
    else
        local a = (mood == "sleep") and 150 or 235
        local c = Color(255, 255, 255, a)
        Render.Line(Vec2(hx, my - 2 * S), Vec2(hx, my), c, 1.4 * S)
        Render.PolyLine(arc_pts(hx - 3.4 * S, my, 3.4 * S, 0, pi, 8), c, 1.5 * S)
        Render.PolyLine(arc_pts(hx + 3.4 * S, my, 3.4 * S, 0, pi, 8), c, 1.5 * S)
    end
end

local function draw_cat(cx, ground, S, t, dt, mood, mt, over, mx, my)
    local rim = K.rim

    -- прыжок и дыхание
    local jt = t - K.jump_t0
    local jy = (jt >= 0 and jt < 0.55) and sin(jt / 0.55 * pi) * 22 * S or 0
    local base = ground - jy
    local bob = sin(t * 2.2) * 1.2 * S
    local shx = 0
    if mood == "love" then shx = sin(t * 55) * 0.9 * S end          -- мурчит, дрожит
    if mood == "angry" then shx = sin(t * 70) * 0.8 * S end
    local ccx = cx + shx

    -- куда смотрит
    local tx, ty = 0, 0
    if mood == "play" then
        tx, ty = sin(mt * 3.0), 0.5
    elseif mood == "sleep" then
        tx, ty = 0, 0.4
    elseif mx then
        local dx, dy = mx - ccx, my - (base - 60 * S)
        local d = sqrt(dx * dx + dy * dy)
        if d > 1 then
            local k = min(1, d / 350)
            tx, ty = dx / d * k, dy / d * k
        end
    end
    local lk = min(1, dt * 9)
    K.look.x = K.look.x + (tx - K.look.x) * lk
    K.look.y = K.look.y + (ty - K.look.y) * lk

    local hx = ccx + K.look.x * 2 * S
    local hy = base - 62 * S + bob + ((mood == "sleep") and 5 * S or 0)

    -- свечение настроения
    if ui.glow:Get() then
        local pulse = 0.75 + 0.25 * sin(t * 2)
        Render.CircleGradient(Vec2(ccx, base - 45 * S), 78 * S,
            Color(floor(rim[1]), floor(rim[2]), floor(rim[3]), 0),
            Color(floor(rim[1]), floor(rim[2]), floor(rim[3]), floor(60 * pulse)))
    end

    -- чёрная линия, на которой сидит кот
    if ui.ledge:Get() then
        local lw = 112 * S
        local a, b = Vec2(ccx - lw / 2, ground - 1 * S), Vec2(ccx + lw / 2, ground + 5 * S)
        Render.FilledRect(a, b, Color(8, 8, 12, 240), 3 * S)
        Render.Rect(a, b, Color(floor(rim[1]), floor(rim[2]), floor(rim[3]), 70), 3 * S,
            Enum.DrawFlags.None, 1 * S)
    end

    local rim_c = Color(floor(rim[1]), floor(rim[2]), floor(rim[3]), 150)
    local body_c = Color(BODY[1], BODY[2], BODY[3], 255)

    -- хвост: цепочка кружков с изгибом и волной
    local ts = TAIL[mood] or TAIL.idle
    local sp = ts[1] * (over and 1.4 or 1)
    local function draw_tail(grow, c)
        local px, py = ccx + 17 * S, base - 9 * S
        Render.FilledCircle(Vec2(px, py), 4.4 * S + grow, c)
        local seg = 7.4 * S
        for i = 1, 10 do
            local ang = -0.12 - 0.20 * i + sin(t * sp - i * 0.5) * ts[2] * (i / 10)
            px, py = px + cos(ang) * seg, py + sin(ang) * seg
            Render.FilledCircle(Vec2(px, py), (4.4 - i * 0.22) * S + grow, c)
        end
    end
    draw_tail(1.5 * S, rim_c)
    draw_tail(0, body_c)

    -- уши
    local twitch = ((t * 0.6) % 4 < 0.22) and sin(t * 50) * 2 * S or 0
    local edy, eout = 0, 0
    if mood == "angry" then edy, eout = 9 * S, 6 * S
    elseif mood == "sad" then edy, eout = 5 * S, 3 * S
    elseif mood == "excited" then edy = -3 * S end
    local ears = {}
    for i, sg in ipairs({ -1, 1 }) do
        ears[i] = {
            tx = hx + sg * (20 * S + eout) + ((sg == -1) and twitch or 0), ty = hy - 41 * S + edy,
            ax = hx + sg * 23 * S, ay = hy - 12 * S,
            bx = hx + sg * 4 * S,  by = hy - 23 * S,
        }
    end

    -- тело, лапки, уши, голова: сначала обводка, потом заливка
    local function shapes(c, g)
        Render.FilledCircle(Vec2(ccx, base - 26 * S), 25 * S + g, c)
        Render.FilledRect(Vec2(ccx - 25 * S - g, base - 28 * S), Vec2(ccx + 25 * S + g, base - 3 * S + g * 0.5), c, 11 * S)
        Render.FilledRect(Vec2(ccx - 20 * S - g, base - 12 * S), Vec2(ccx - 6 * S + g, base + g * 0.5), c, 6 * S)
        Render.FilledRect(Vec2(ccx + 6 * S - g, base - 12 * S), Vec2(ccx + 20 * S + g, base + g * 0.5), c, 6 * S)
        for _, e in ipairs(ears) do
            tri(e.tx, e.ty, e.ax, e.ay, e.bx, e.by, c, 2.4 * S + g * 2, 12)
        end
        Render.FilledCircle(Vec2(hx, hy), 25 * S + g, c)
    end
    shapes(rim_c, 1.7 * S)
    shapes(body_c, 0)

    -- розовое внутри ушей
    for _, e in ipairs(ears) do
        local mx_, my_ = (e.tx + e.ax + e.bx) / 3, (e.ty + e.ay + e.by) / 3
        local function sh(px, py) return mx_ + (px - mx_) * 0.5, my_ + (py - my_) * 0.5 end
        local x1, y1 = sh(e.tx, e.ty)
        local x2, y2 = sh(e.ax, e.ay)
        local x3, y3 = sh(e.bx, e.by)
        tri(x1, y1, x2, y2, x3, y3, Color(255, 150, 175, 170), 1.8 * S, 8)
    end

    -- мордочка
    local ey = hy - 2 * S
    draw_eyes(hx, ey, K.look.x * 2.6 * S, K.look.y * 2 * S, S, t, mood)
    local ny = hy + 6 * S
    draw_mouth(hx, ny + 3 * S, S, t, mood)
    tri(hx, ny + 3 * S, hx - 3.4 * S, ny - 1 * S, hx + 3.4 * S, ny - 1 * S, Color(255, 140, 170, 255), 1.6 * S, 6)

    -- усы
    local droop = (mood == "sad") and 3 * S or 0
    for _, sg in ipairs({ -1, 1 }) do
        for k = -1, 1 do
            Render.Line(Vec2(hx + sg * 13 * S, hy + 6 * S + k * 2.5 * S),
                Vec2(hx + sg * 34 * S, hy + 6 * S + k * 5.5 * S + droop + sin(t * 1.5 + k) * 0.8 * S),
                Color(255, 255, 255, 85), 1.1 * S)
        end
    end

    -- рыбка (кормление)
    if mood == "eat" then
        local p = clamp(mt / 3.4, 0, 1)
        local side = K.side
        local mouth_y = hy + 11 * S
        local fx, fy, fs
        if p < 0.25 then
            local u = ease_out_cubic(p / 0.25)
            fx = hx + side * 60 * S * (1 - u)
            fy = (hy - 36 * S) * (1 - u) + mouth_y * u
            fs = 6.5 * S
        else
            local u2 = clamp((p - 0.25) / 0.55, 0, 1)
            fx, fy = hx, mouth_y + sin(t * 13) * 1.2 * S
            fs = 6.5 * S * (1 - u2)
        end
        if fs > 0.8 * S then fish(fx, fy, fs, -side) end
    end

    -- мячик (игра)
    if mood == "play" then
        local bx = hx + sin(mt * 3.0) * 46 * S
        local by = ground - 7 * S - abs(sin(mt * 6.0)) * 24 * S
        Render.FilledCircle(Vec2(bx, by), 7 * S, Color(255, 110, 150, 255))
        local a = mt * 8
        Render.Line(Vec2(bx - cos(a) * 5 * S, by - sin(a) * 5 * S), Vec2(bx + cos(a) * 5 * S, by + sin(a) * 5 * S),
            Color(255, 255, 255, 200), 1.4 * S)
    end

    return hy
end

local function draw_needs(cx, ground, S)
    local by = ground + 9 * S
    local function bar(x1, val, c)
        Render.FilledRect(Vec2(x1, by), Vec2(x1 + 40 * S, by + 5 * S), Color(255, 255, 255, 40), 3 * S)
        local w = 40 * S * clamp(val / 100, 0, 1)
        if w > 1 then Render.FilledRect(Vec2(x1, by), Vec2(x1 + w, by + 5 * S), c, 3 * S) end
    end
    bar(cx - 44 * S, K.love, Color(255, 110, 160, 235))
    bar(cx + 4 * S, K.hunger, Color(255, 168, 90, 235))
    heart(cx - 51 * S, by + 2 * S, 3.2 * S, Color(255, 110, 160, 235))
    fish(cx + 53 * S, by + 2.5 * S, 2.6 * S, 1)
end

-- ===== Рисование: реплика =====
local function draw_bubble(cx, hy, S, t, side, opacity, scr)
    if t >= K.say_until or K.say_text == "" then return end

    local size = 12.5 * S
    local lines = wrap(K.say_text, 190 * S, size)
    local wmax = 0
    for _, ln in ipairs(lines) do wmax = max(wmax, (text_dim(size, ln))) end

    local lh = size * 1.35
    local pad = 10 * S
    local bw = wmax + pad * 2
    local bh = #lines * lh + pad * 2 - 2 * S

    local fade_in = clamp((t - K.say_t0) / 0.18, 0, 1)
    local fade_out = clamp((K.say_until - t) / 0.35, 0, 1)
    local al = min(fade_in, fade_out)
    local e = ease_out_cubic(fade_in)

    local tipx = cx + side * 32 * S
    local bx1 = (side == -1) and (tipx - 9 * S - bw) or (tipx + 9 * S)
    bx1 = clamp(bx1, 6, max(6, scr.x - bw - 6))
    local by1 = max(6, hy - bh * 0.5) + (1 - e) * 6 * S
    local a, b = Vec2(bx1, by1), Vec2(bx1 + bw, by1 + bh)
    local round = 11 * S

    Render.SetGlobalAlpha(opacity * al)
    Render.Shadow(a, b, Color(0, 0, 0, 110), 16 * S, round)
    Render.Gradient(a, b, Color(24, 26, 40, 240), Color(24, 26, 40, 240),
        Color(40, 42, 64, 240), Color(40, 42, 64, 240), round)
    Render.Rect(a, b, Color(floor(K.rim[1]), floor(K.rim[2]), floor(K.rim[3]), 120), round,
        Enum.DrawFlags.None, 1.2 * S)

    local edge = (side == -1) and (bx1 + bw) or bx1
    tri(tipx, hy + 2 * S, edge, hy - 5 * S, edge, hy + 7 * S, Color(32, 34, 52, 240), 1.6 * S, 8)

    -- печатная машинка
    local remaining = floor((t - K.say_t0) * 34)
    for i, ln in ipairs(lines) do
        local n = ulen(ln)
        local take = min(n, remaining)
        remaining = remaining - take
        if take > 0 then
            text(size, usub(ln, take), bx1 + pad, by1 + pad - 1 * S + (i - 1) * lh, Color(240, 242, 252, 255))
        end
    end
end

-- ===== Рисование: меню действий =====
local function menu_layout(x, y, w, S, scr)
    local n = #ACTIONS
    local bw, bh, gap = 132 * S, 27 * S, 6 * S
    local total = n * bh + (n - 1) * gap
    local cxm = x + w * 0.5
    local side = (cxm > scr.x * 0.5) and -1 or 1
    local px = (side == -1) and (cxm - 38 * S - bw) or (cxm + 38 * S)
    local py = clamp(y + 6 * S, 8, max(8, scr.y - total - 8))
    local rects = {}
    for i = 1, n do
        local ry = py + (i - 1) * (bh + gap)
        rects[i] = { px, ry, px + bw, ry + bh }
    end
    return rects, side, { px, py, px + bw, py + total }
end

local function draw_menu(rects, side, t, S, opacity, hover_idx)
    local labels = LABEL[lang_key()]
    for i, act in ipairs(ACTIONS) do
        local r = rects[i]
        local age = t - K.menu_t0 - (i - 1) * 0.05
        local e = ease_out_back(age / 0.28)
        local al = clamp(age / 0.18, 0, 1)
        Render.SetGlobalAlpha(opacity * al)

        local hov = (i == hover_idx)
        local off = (1 - e) * 22 * S * (-side) + (hov and side * 3 * S or 0)
        local a, b = Vec2(r[1] + off, r[2]), Vec2(r[3] + off, r[4])
        local top = hov and { 96, 74, 180 } or { 28, 30, 46 }
        local bot = hov and { 132, 98, 224 } or { 44, 48, 72 }
        local round = 9 * S

        Render.Shadow(a, b, Color(0, 0, 0, 100), 12 * S, round)
        Render.Gradient(a, b, col(top, 240), col(top, 240), col(bot, 240), col(bot, 240), round)
        Render.Rect(a, b, Color(255, 255, 255, hov and 90 or 40), round, Enum.DrawFlags.None, 1.1 * S)

        local mid = (r[2] + r[4]) * 0.5
        local icol = hov and Color(255, 255, 255, 255) or Color(215, 220, 245, 255)
        draw_icon(act.icon, r[1] + off + 15 * S, mid, 8 * S, icol, col(top, 255))

        local label = labels[act.id]
        if act.id == "sleep" and K.sleeping then label = labels.wake end
        text(12 * S, label, r[1] + off + 30 * S, mid - 7.5 * S, Color(240, 242, 252, 255))
    end
end

-- ===== Рисование: виджет =====
local function card_rect()
    local S = ui.scale:Get() / 100
    local scr = Render.ScreenSize()
    local w, h = 150 * S, 132 * S
    local x = (scr.x - w) * ui.pos_x:Get() / 100
    local y = (scr.y - h) * ui.pos_y:Get() / 100
    return x, y, w, h, S
end

local function draw_debug(x, y, w, ground, S, mx, my)
    local g = K.g or {}
    local lines = {
        ("hero=%s lp=%s src=%s"):format(tostring(g.hero), tostring(g.lp), tostring(g.src)),
        ("kills=%s deaths=%s alive=%s"):format(tostring(g.kills), tostring(g.deaths), tostring(g.alive)),
        ("cursor=%s,%s down=%s clicks=%d"):format(
            mx and floor(mx) or "nil", my and floor(my) or "nil", tostring(K.mouse_down), K.clicks),
    }
    local size = 10 * S
    local right = x + w
    local yy = ground + 22 * S
    for i, ln in ipairs(lines) do
        local lw = text_dim(size, ln)
        text(size, ln, right - lw, yy + (i - 1) * size * 1.3, Color(200, 255, 200, 230))
    end
end

local function draw_widget()
    local x, y, w, h, S = card_rect()
    local scr = Render.ScreenSize()
    local t = os.clock()
    local dt = min(0.1, t - last_clock)
    last_clock = t

    local opacity = ui.opacity:Get() / 100
    local appear = ease_out_cubic(min(1, (t - K.born) / 1.0))
    y = y - (1 - appear) * 40 * S

    local cx = x + w * 0.5
    local ground = y + h - 8 * S

    -- ввод: клик по коту открывает меню, клик по пункту выполняет действие
    local mx, my = cursor()
    local over_cat = in_rect(mx, my, x + w * 0.2, y + h * 0.12, x + w * 0.8, y + h)
    local clicked = mouse_clicked()
    if clicked then K.clicks = K.clicks + 1 end
    local rects, side, bounds = menu_layout(x, y, w, S, scr)
    local over_menu = K.menu_open and in_rect(mx, my, bounds[1], bounds[2], bounds[3], bounds[4])

    local hover_idx
    if K.menu_open then
        for i, r in ipairs(rects) do
            if in_rect(mx, my, r[1], r[2], r[3], r[4]) then hover_idx = i break end
        end
        if over_cat or over_menu then K.menu_seen = t end
        if t - K.menu_seen > 10 then K.menu_open = false end
    end

    if clicked then
        if K.menu_open then
            if hover_idx then do_action(ACTIONS[hover_idx].id) end
            K.menu_open = false
        elseif over_cat then
            K.menu_open, K.menu_t0, K.menu_seen, K.last_activity = true, t, t, t
        end
    end
    K.over_ui = over_cat or (K.menu_open and over_menu) or false

    update(dt, t)

    Render.SetGlobalAlpha(opacity * appear)
    local mood = K.mood
    local hy = draw_cat(cx, ground, S, t, dt, mood, t - K.mood_t0, over_cat, mx, my)
    draw_particles(cx, ground, S, t)

    if ui.needs:Get() and over_cat and not K.menu_open then
        draw_needs(cx, ground, S)
    end
    if ui.debug:Get() then draw_debug(x, y, w, ground, S, mx, my) end

    if K.menu_open then
        draw_menu(rects, side, t, S, opacity, hover_idx)
    else
        draw_bubble(cx, hy, S, t, side, opacity, scr)
    end
end

-- ===== Колбэки =====
function script.OnUpdateEx()
    if not ui.enabled:Get() then return end
    tick_game(os.clock())
end

function script.OnDraw()
    if not ui.enabled:Get() then return end
    local ok, err = pcall(draw_widget)
    Render.ResetGlobalAlpha()
    if not ok and not err_printed then
        err_printed = true
        print("[Kitty] draw error: " .. tostring(err))
    end
end

-- не даём клику по коту уйти в игру приказом героя
function script.OnPrepareUnitOrders()
    if ui.enabled:Get() and K.over_ui then return false end
    return true
end

print("[Kitty] loaded")

return script
