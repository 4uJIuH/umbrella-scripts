local SCRIPT_VERSION = "2.1.3"
local bh = {}

local protobuf = require('protobuf')
local JSON = require('assets.JSON')

local qLocalization = qLocalization
if type(qLocalization) ~= "table" or type(qLocalization.new) ~= "function" then
    local ok, lib = pcall(require, "!_qLocalizer")
    qLocalization = (ok and type(lib) == "table" and type(lib.new) == "function") and lib or nil
end
if not qLocalization then
    print("[BH] qLocalization not found, install !_qLocalizer.lua")
    return bh
end

local localization = qLocalization.new({
    en = {
        bs_group_greet = "Auto Greeting",
        bs_group_gg = "Auto GG",
        bs_group_ctrl = "Chat Control",
        bs_group_tox = "Toxic Report",
        bs_group_voice = "Voice Report",
        bs_group_feed = "Griefing Report",
        bs_group_mute = "Start Mute and Hide",
        bs_group_ping = "Ping Spam Filter",
        bs_group_pingme = "Death and XP Ping Mute",
        bs_group_like = "Auto Commend",
        bs_group_party = "Party",
        bs_group_notif = "Notifications",
        bs_gear_wards = "Ward Triggers",

        bs_fmt_sec = "%d s",
        bs_fmt_min = "%d min",
        bs_fmt_pcs = "%d",

        bs_enable = "Enable",
        bs_chat_to = "Channel",
        bs_chs_team = "Allies only",
        bs_chs_all = "All chat",
        bs_text = "Message text",
        bs_greet_enable_tip = "Writes a message to chat when the match starts.",
        bs_gg_enable_tip = "Writes a message to chat after the throne falls.",
        bs_gg_default = "gg wp, commend pls",

        bs_ctrl_enable = "Text Chat Control",
        bs_ctrl_enable_tip = "Holds back your own chat messages.\nMessages starting with - are always sent.",
        bs_ctrl_mode = "Mode",
        bs_ctrl_modes_block = "Block all",
        bs_ctrl_modes_chance = "Send chance",
        bs_ctrl_modes_censor = "Block profanity and insults",
        bs_ctrl_chance = "Send chance",
        bs_ctrl_echo = "Show Blocked to Me",
        bs_ctrl_echo_tip = "A blocked message is shown only to you.",
        bs_ctrl_blocked = "[BH] Message not sent, it has profanity or an insult (%s): %s",
        bs_mute_mic = "Mute My Mic",
        bs_mute_mic_tip = "Your voice is not sent to anyone.",

        bs_tox_enable_tip = "Reports players for chat messages.\nWords come from the files in scripts/filters.",
        bs_tox_reason = "Reason",
        bs_tox_reasons_all = "Profanity and insults",
        bs_tox_reasons_mat = "Profanity only",
        bs_tox_reasons_osk = "Insults only",
        bs_tox_reasons_spam = "Message spam",
        bs_tox_reasons_any = "Any message",
        bs_tox_match = "Match Mode",
        bs_tox_matches_exact = "Exact word",
        bs_tox_matches_sub = "Part of a word",
        bs_tox_matches_both = "Both",
        bs_tox_count = "Message Threshold",
        bs_tox_unmute = "Unmute After Report",
        bs_tox_unmute_tip = "A report mutes the player.\nOn: the mute is lifted after 3 s.",
        bs_target = "Target",
        bs_targets_enemies = "Enemies",
        bs_targets_allies = "Allies",
        bs_targets_all = "Everyone",

        bs_voice_enable_tip = "Reports allies for voice chat.",
        bs_voice_reason = "Reason",
        bs_voice_reasons_long = "Talks more than N s",
        bs_voice_reasons_any = "Turned on the mic",
        bs_voice_sec = "Talks More Than",

        bs_feed_enable_tip = "Reports for early buyback and ward griefing.",
        bs_feed_buyback = "Early Buyback",
        bs_feed_buyback_min = "Buyback Before Minute",
        bs_feed_wards = "Ward Griefing",
        bs_ward_base = "Ward in own base",
        bs_ward_pile = "Pile in one spot",
        bs_ward_tower = "Under enemy tower",
        bs_ward_deny_obs = "Deny own observer",
        bs_ward_deny_sen = "Deny own sentry",
        bs_ward_count = "Wards in One Spot",

        bs_mute_start = "Mute at Match Start",
        bs_mute_start_tip = "Mutes players in the first seconds of the match.",
        bs_mute_who = "Who to Mute",
        bs_hide_tilt = "Hide Tips and Pings",
        bs_hide_tilt_tip = "Hides tips and death or XP pings on your hero.",

        bs_ping_enable_tip = "Mutes a player who spams pings.",
        bs_ping_count = "More Than N Pings",
        bs_ping_window = "Within M Seconds",
        bs_action = "Action",
        bs_actions_forever = "Mute until game end",
        bs_actions_timed = "Mute for N min",
        bs_mute_min = "Mute Duration",
        bs_ping_ability = "Count Ability Pings",
        bs_ping_report = "Report on Mute",
        bs_ping_report_tip = "On a mute also reports for griefing\nand chat toxicity.",

        bs_pingme_enable_tip = "Mutes players who ping your death timer,\nyour XP or your hero.",
        bs_pingme_dead = "Death Timer Ping",
        bs_pingme_xp = "XP Ping",
        bs_pingme_hero = "Ping on My Hero",

        bs_like_enable_tip = "Commends every player on the end screen.",
        bs_like_delay_on = "Delay Before Commend",
        bs_like_delay = "Delay",
        bs_like_now = "Commend Now",
        bs_party_report = "Report Party Members",
        bs_party_mute = "Mute Party Members",
        bs_notif_screen = "On Screen",
        bs_notif_chat = "Print to Chat",
        bs_notif_chat_tip = "Only you see these lines.",
        bs_notif_log = "Print to Console",
        bs_notif_dur = "Duration on Screen",

        bs_msg_sent = "Report sent: %s, %s (%s)",
        bs_msg_party = "Not reporting %s, they are in your party",
        bs_msg_mute = "%s: %s, muted %s",
        bs_msg_forever = "until game end",
        bs_msg_accepted = "GC accepted the report",
        bs_msg_in_party = "Player is in a party, reports are off",
        bs_lbl_toxic = "toxicity",
        bs_lbl_spam = "chat spam",
        bs_lbl_voice = "voice chat",
        bs_lbl_feed = "griefing",
        bs_lbl_wards = "ward griefing",
        bs_lbl_ping_spam = "ping spam",
        bs_lbl_ping_dead = "death ping",
        bs_lbl_ping_xp = "XP ping",
        bs_lbl_ping_hero = "ping on my hero",
        bs_tr_msgs = "%d messages",
        bs_tr_pings = "%d pings in %d s",
        bs_tr_mic_sec = "mic %d s",
        bs_tr_mic = "turned on the mic",
        bs_tr_buyback = "buyback at %d min",
        bs_tr_ward_base = "ward in own base (%d)",
        bs_tr_ward_tower = "ward under enemy tower (%d)",
        bs_tr_ward_pile = "%d wards in one spot",
        bs_tr_deny_obs = "denied own observer",
        bs_tr_deny_sen = "denied own sentry",
    },
    ru = {
        bs_group_greet = "Авто-приветствие",
        bs_group_gg = "Авто-GG",
        bs_group_ctrl = "Контроль общения",
        bs_group_tox = "Репорт за токсичность",
        bs_group_voice = "Репорт за войс",
        bs_group_feed = "Репорт за препятствование игре",
        bs_group_mute = "Мут на старте и скрытие",
        bs_group_ping = "Фильтр спама пингами",
        bs_group_pingme = "Мут за пинги смерти и опыта",
        bs_group_like = "Авто-комменд",
        bs_group_party = "Пати",
        bs_group_notif = "Уведомления",
        bs_gear_wards = "За что репортить",

        bs_fmt_sec = "%d сек",
        bs_fmt_min = "%d мин",
        bs_fmt_pcs = "%d шт",

        bs_enable = "Включить",
        bs_chat_to = "Куда писать",
        bs_chs_team = "Только союзникам",
        bs_chs_all = "Всем в игру",
        bs_text = "Текст сообщения",
        bs_greet_enable_tip = "Пишет сообщение в чат в начале матча.",
        bs_gg_enable_tip = "Пишет сообщение в чат после падения трона.",
        bs_gg_default = "спс за игру, киньте лайк пж",

        bs_ctrl_enable = "Контроль текстового чата",
        bs_ctrl_enable_tip = "Сдерживает твои сообщения в чат.\nСообщения с - в начале уходят всегда.",
        bs_ctrl_mode = "Режим",
        bs_ctrl_modes_block = "Сдерживание",
        bs_ctrl_modes_chance = "Шанс отправки",
        bs_ctrl_modes_censor = "Не пускать маты и оски",
        bs_ctrl_chance = "Шанс отправки",
        bs_ctrl_echo = "Показывать сдержанное у себя",
        bs_ctrl_echo_tip = "Сдержанное сообщение видишь только ты.",
        bs_ctrl_blocked = "[BH] Сообщение не отправлено, в нём мат или оскорбление (%s): %s",
        bs_mute_mic = "Мут своего микрофона",
        bs_mute_mic_tip = "Твой голос никому не отправляется.",

        bs_tox_enable_tip = "Репортит игроков за сообщения в чате.\nСлова берутся из файлов в scripts/filters.",
        bs_tox_reason = "Причина",
        bs_tox_reasons_all = "Маты и оскорбления",
        bs_tox_reasons_mat = "Только маты",
        bs_tox_reasons_osk = "Только оскорбления",
        bs_tox_reasons_spam = "Спам сообщениями",
        bs_tox_reasons_any = "Любое сообщение",
        bs_tox_match = "Как искать",
        bs_tox_matches_exact = "Точное слово",
        bs_tox_matches_sub = "Часть слова",
        bs_tox_matches_both = "Оба",
        bs_tox_count = "Порог сообщений",
        bs_tox_unmute = "Снять мут после репорта",
        bs_tox_unmute_tip = "Репорт мутит игрока.\nВкл: мут снимается через 3 сек.",
        bs_target = "Кого репортить",
        bs_targets_enemies = "Врагов",
        bs_targets_allies = "Союзников",
        bs_targets_all = "Всех",

        bs_voice_enable_tip = "Репортит союзников за голосовой чат.",
        bs_voice_reason = "Причина",
        bs_voice_reasons_long = "Говорит больше N секунд",
        bs_voice_reasons_any = "Включил микрофон",
        bs_voice_sec = "Говорит больше",

        bs_feed_enable_tip = "Репортит за ранний байбек и слив вардов.",
        bs_feed_buyback = "Ранний байбек",
        bs_feed_buyback_min = "Байбек до минуты",
        bs_feed_wards = "Слив вардов",
        bs_ward_base = "Вард под свою базу",
        bs_ward_pile = "Куча в одной точке",
        bs_ward_tower = "Под вражескую вышку",
        bs_ward_deny_obs = "Денай своего обсервера",
        bs_ward_deny_sen = "Денай своего сентри",
        bs_ward_count = "Вардов в одной точке",

        bs_mute_start = "Мут на старте матча",
        bs_mute_start_tip = "Мутит игроков в первые секунды матча.",
        bs_mute_who = "Кого мутить",
        bs_hide_tilt = "Скрывать типы и пинги",
        bs_hide_tilt_tip = "Скрывает типы и пинги смерти или опыта\nпо твоему герою.",

        bs_ping_enable_tip = "Мутит игрока, который спамит пингами.",
        bs_ping_count = "Больше N пингов",
        bs_ping_window = "За M секунд",
        bs_action = "Действие",
        bs_actions_forever = "Замутить до конца игры",
        bs_actions_timed = "Замутить на N минут",
        bs_mute_min = "На сколько минут",
        bs_ping_ability = "Считать пинги способностей",
        bs_ping_report = "Репорт при муте",
        bs_ping_report_tip = "При муте также репортит за препятствование\nигре и токсичность в чате.",

        bs_pingme_enable_tip = "Мутит игроков за пинг твоего таймера смерти,\nопыта или героя.",
        bs_pingme_dead = "Пинг что я умер",
        bs_pingme_xp = "Пинг моего опыта",
        bs_pingme_hero = "Пинг по моему герою",

        bs_like_enable_tip = "Лайкает всех игроков на экране итогов.",
        bs_like_delay_on = "Пауза перед лайком",
        bs_like_delay = "Пауза",
        bs_like_now = "Лайкнуть сейчас",
        bs_party_report = "Репортить игроков из пати",
        bs_party_mute = "Мутить игроков из пати",
        bs_notif_screen = "На экране",
        bs_notif_chat = "Писать в чат",
        bs_notif_chat_tip = "Эти строки видишь только ты.",
        bs_notif_log = "Писать в консоль",
        bs_notif_dur = "Длительность на экране",

        bs_msg_sent = "Репорт отправлен: %s, %s (%s)",
        bs_msg_party = "Не репортим %s, он в пати",
        bs_msg_mute = "%s: %s, мут %s",
        bs_msg_forever = "до конца игры",
        bs_msg_accepted = "GC принял репорт",
        bs_msg_in_party = "Игрок в пати, репорты отключены",
        bs_lbl_toxic = "токсичность",
        bs_lbl_spam = "спам в чат",
        bs_lbl_voice = "голосовой чат",
        bs_lbl_feed = "препятствование игре",
        bs_lbl_wards = "слив вардов",
        bs_lbl_ping_spam = "спам пингами",
        bs_lbl_ping_dead = "пинг смерти",
        bs_lbl_ping_xp = "пинг опыта",
        bs_lbl_ping_hero = "пинг по моему герою",
        bs_tr_msgs = "%d сообщ.",
        bs_tr_pings = "%d пингов за %d сек",
        bs_tr_mic_sec = "микрофон %d сек",
        bs_tr_mic = "включил микрофон",
        bs_tr_buyback = "байбек на %d мин",
        bs_tr_ward_base = "вард под своей базой (%d)",
        bs_tr_ward_tower = "вард под вражеской вышкой (%d)",
        bs_tr_ward_pile = "%d вардов в одной точке",
        bs_tr_deny_obs = "разбил свой обсервер",
        bs_tr_deny_sen = "разбил свой сентри",
    },
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

local ru_lower = {
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="е", ["ё"]="е", ["Ж"]="ж",
    ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м", ["Н"]="н", ["О"]="о",
    ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у", ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц",
    ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ", ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я"
}

local function low(s)
    if not s then return "" end
    local r = s:lower()
    for k, v in pairs(ru_lower) do r = r:gsub(k, v) end
    return r
end

local wordsWhite = {
    "ребят", "хлеб", "себя", "тебя", "небе", "небо", "небу", "неба", "мебел", "дебат",
    "стеб", "гребен", "гребн", "грест", "греб", "требова", "требу", "колеб", "лебед",
    "серебр", "жереб", "амеб", "плацеб", "небылиц", "употреб", "истреб", "потреб", "разгреб",
    "оскорб", "барсук", "сукно", "скипидар",
    "наход", "монас", "монах", "альманах", "внахлест", "нахлыну", "нахрап",
    "педикюр", "нигери", "хачапур", "snigger", "shitake", "shiitake", "scunthorpe", "cocktail", "cockpit", "peacock", "hancock"
}

local fallbackMat = {
    "(на|по|о|а)?ху[йяеиё]\\w*", "хули", "\\w*пизд\\w*", "еб\\w*", "\\w*заеб\\w*", "уеб\\w*", "въеб\\w*",
    "бля(ть|т|ха|хи|д\\w*)?", "сук[аиу]", "сучк\\w*", "мудак\\w*", "мудил\\w*", "шлюх\\w*", "fuck\\w*", "shit\\w*", "bitch\\w*", "cunt\\w*"
}

local fallbackOsk = {
    "пид[оа]?р\\w*", "г[ао]нд[оа]н\\w*", "долб[ао]?[её]б\\w*", "еблан\\w*", "уебан\\w*", "хуесос\\w*",
    "даун(ы|а|у|е|ом|ов|ам|ами|ах|ский|ская|ское|ские)?", "дебил\\w*", "дегенерат\\w*", "сдохни", "kys", "retard\\w*", "nigg\\w*", "faggot\\w*"
}

local function resolveScriptDir()
    local ok, base = pcall(Engine.GetCheatDirectory)
    if ok and type(base) == "string" and base ~= "" then return (base:gsub("[/\\]+$", "")) .. "/scripts" end
    return "scripts"
end

local SCRIPT_DIR = resolveScriptDir()

local function loadWords(filename)
    local words = {}
    local file = io.open(SCRIPT_DIR .. "/filters/" .. filename, "r") or io.open("scripts/filters/" .. filename, "r")
    if not file then return words end
    for rawLine in file:lines() do
        local trimmed = rawLine:match("^%s*(.-)%s*$")
        if trimmed and #trimmed > 0 and not trimmed:match("^#") then
            words[#words + 1] = trimmed
        end
    end
    file:close()
    return words
end

local function joinLists(...)
    local res = {}
    for _, list in ipairs({ ... }) do
        for _, w in ipairs(list) do res[#res + 1] = w end
    end
    return res
end

local wordsMat = joinLists(loadWords("filter_profanity_russian_cached.txt"), loadWords("filter_profanity_english_cached.txt"))
local wordsOsk = joinLists(loadWords("filter_banned_russian_cached.txt"), loadWords("filter_banned_english_cached.txt"))
local rx = { esc = { w = "w", W = "W", d = "d", s = "s" } }

function rx.isWord(cp)
    return cp >= 128 or (cp >= 48 and cp <= 57) or (cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122) or cp == 95
end

function rx.cps(s)
    local t = {}
    local ok = pcall(function()
        for _, c in utf8.codes(s) do t[#t + 1] = c end
    end)
    if not ok then t = { s:byte(1, -1) } end
    return t
end

function rx.lowerCp(cp)
    local ok, c = pcall(utf8.codepoint, low(utf8.char(cp)), 1)
    return ok and c or cp
end

function rx.test(node, cp)
    local k = node.k
    if k == "ch" then return cp == node.c end
    if k == "any" then return true end
    if k == "w" then return rx.isWord(cp) end
    if k == "W" then return not rx.isWord(cp) end
    if k == "d" then return cp >= 48 and cp <= 57 end
    if k == "s" then return cp == 32 or cp == 9 end
    if k == "set" then
        local hit = false
        for _, it in ipairs(node.items) do
            if (it.k and rx.test(it, cp)) or (it.lo and cp >= it.lo and cp <= it.hi) then
                hit = true
                break
            end
        end
        return hit ~= node.neg
    end
    return false
end

function rx.parse(p, i, inGroup)
    local seq = {}
    local alts = { seq }
    while i <= #p do
        local c = p[i]
        if c == 41 and inGroup then return alts, i + 1 end
        if c == 124 then
            seq = {}
            alts[#alts + 1] = seq
            i = i + 1
        elseif c == 40 then
            local j = i + 1
            if p[j] == 63 and p[j + 1] == 58 then j = j + 2 end
            local sub
            sub, i = rx.parse(p, j, true)
            seq[#seq + 1] = { k = "grp", alts = sub }
        elseif c == 63 or c == 42 or c == 43 then
            local last = seq[#seq]
            if last and not last.q then last.q = c end
            i = i + 1
        elseif c == 91 then
            local node = { k = "set", items = {}, neg = false }
            i = i + 1
            if p[i] == 94 then
                node.neg = true
                i = i + 1
            end
            local first = true
            while i <= #p and (p[i] ~= 93 or first) do
                first = false
                local it
                if p[i] == 92 and p[i + 1] then
                    local e = rx.esc[utf8.char(p[i + 1])]
                    local v = rx.lowerCp(p[i + 1])
                    it = e and { k = e } or { lo = v, hi = v }
                    i = i + 2
                elseif p[i + 1] == 45 and p[i + 2] and p[i + 2] ~= 93 then
                    it = { lo = rx.lowerCp(p[i]), hi = rx.lowerCp(p[i + 2]) }
                    i = i + 3
                else
                    local v = rx.lowerCp(p[i])
                    it = { lo = v, hi = v }
                    i = i + 1
                end
                node.items[#node.items + 1] = it
            end
            i = i + 1
            seq[#seq + 1] = node
        elseif c == 92 and p[i + 1] then
            local e = rx.esc[utf8.char(p[i + 1])]
            if e then
                seq[#seq + 1] = { k = e }
            elseif p[i + 1] == 98 then
                seq[#seq + 1] = { k = "b" }
            elseif p[i + 1] ~= 66 then
                seq[#seq + 1] = { k = "ch", c = rx.lowerCp(p[i + 1]) }
            end
            i = i + 2
        elseif c == 46 then
            seq[#seq + 1] = { k = "any" }
            i = i + 1
        elseif c == 94 or c == 36 then
            i = i + 1
        else
            seq[#seq + 1] = { k = "ch", c = rx.lowerCp(c) }
            i = i + 1
        end
    end
    return alts, i
end

function rx.minLen(alts)
    local best
    for _, seq in ipairs(alts) do
        local n = 0
        for _, node in ipairs(seq) do
            if node.k ~= "b" and node.q ~= 63 and node.q ~= 42 then
                n = n + (node.k == "grp" and rx.minLen(node.alts) or 1)
            end
        end
        if not best or n < best then best = n end
    end
    return best or 0
end

function rx.one(node, s, pos, k)
    if node.k == "grp" then
        for _, seq in ipairs(node.alts) do
            if rx.seq(seq, 1, s, pos, k) then return true end
        end
        return false
    end
    if node.k == "b" then
        local before = pos > 1 and rx.isWord(s[pos - 1]) or false
        local after = s[pos] ~= nil and rx.isWord(s[pos]) or false
        return before ~= after and k(pos)
    end
    local cp = s[pos]
    return cp ~= nil and rx.test(node, cp) and k(pos + 1)
end

rx.toCyr = {
    [97] = 1072, [101] = 1077, [111] = 1086, [112] = 1088, [99] = 1089, [120] = 1093, [121] = 1091,
    [107] = 1082, [109] = 1084, [116] = 1090, [104] = 1085, [117] = 1080, [48] = 1086, [51] = 1079, [54] = 1073
}
rx.toLat = {
    [1072] = 97, [1077] = 101, [1086] = 111, [1088] = 112, [1089] = 99, [1093] = 120, [1091] = 121,
    [1082] = 107, [1084] = 109, [1090] = 116, [48] = 111, [49] = 105, [51] = 101, [52] = 97, [53] = 115
}

function rx.norm(s)
    local n, i = #s, 1
    while i <= n do
        if rx.isWord(s[i]) then
            local j = i
            while j < n and rx.isWord(s[j + 1]) do j = j + 1 end
            local cyr, lat = 0, 0
            for k = i, j do
                local c = s[k]
                if c >= 1024 and c <= 1279 then
                    cyr = cyr + 1
                elseif c >= 97 and c <= 122 then
                    lat = lat + 1
                end
            end
            local map = (cyr > 0 and cyr >= lat) and rx.toCyr or (lat > 0 and rx.toLat) or nil
            if map then
                for k = i, j do s[k] = map[s[k]] or s[k] end
            end
            i = j + 1
        else
            i = i + 1
        end
    end

    local out = {}
    i = 1
    while i <= n do
        local j = i
        while j < n and s[j + 1] == s[i] do j = j + 1 end
        local times = (j - i >= 2 and rx.isWord(s[i])) and 1 or (j - i + 1)
        for _ = 1, times do out[#out + 1] = s[i] end
        i = j + 1
    end
    return out
end

function rx.seq(seq, i, s, pos, k)
    local node = seq[i]
    if not node then return k(pos) end
    local function nxt(p) return rx.seq(seq, i + 1, s, p, k) end
    if node.q == 63 then return rx.one(node, s, pos, nxt) or nxt(pos) end
    if node.q == 42 or node.q == 43 then
        local function rep(p, n)
            if rx.one(node, s, p, function(p2) return p2 > p and rep(p2, n + 1) end) then return true end
            return (node.q == 42 or n > 0) and nxt(p)
        end
        return rep(pos, 0)
    end
    return rx.one(node, s, pos, nxt)
end

function rx.compile(src)
    local ok, alts = pcall(rx.parse, rx.cps(src), 1, false)
    if not ok or not alts then return nil end
    return { node = { k = "grp", alts = alts }, min = rx.minLen(alts) }
end

local function compileList(...)
    local res, seen = {}, {}
    for _, list in ipairs({ ... }) do
        for _, src in ipairs(list) do
            if not seen[src] then
                seen[src] = true
                local pat = rx.compile(src)
                if pat and pat.min > 0 then res[#res + 1] = pat end
            end
        end
    end
    return res
end

local setsMat = { compileList(wordsMat, fallbackMat) }
local setsOsk = { compileList(wordsOsk, fallbackOsk) }
local setsAll = { setsMat[1], setsOsk[1] }

local STEAM_TAIL = 97960265728

local function storePath()
    local ok, base = pcall(Engine.GetCheatDirectory)
    base = (ok and type(base) == "string") and base:gsub("[/\\]+$", "") or "."
    return base .. "/configs/behavior_score_helper.txt"
end

local function readStore()
    local res = {}
    local f = io.open(storePath(), "r")
    if not f then return res end
    for line in f:lines() do
        local k, v = line:match("^(%S+)%s?(.*)$")
        if k then res[k] = v end
    end
    f:close()
    return res
end

local store = readStore()

local function writeStore()
    local f = io.open(storePath(), "w")
    if not f then return end
    for k, v in pairs(store) do f:write(k, " ", v, "\n") end
    f:close()
end

local function storeSet(key, value)
    if store[key] == value then return end
    store[key] = value
    writeStore()
end

local tryProcessLikes
local ui = {}

do
    local root = UI.Create("Scripts", "Utility", "Behavior Score")
    root:Icon("\u{f164}")

    local tabChat = root:Create("Chat")
    local tabRep = root:Create("Reports")
    local tabTilt = root:Create("Anti-Tilt")
    local tabUtil = root:Create("Utilities")
    tabChat:Icon("\u{f086}")
    tabRep:Icon("\u{f024}")
    tabTilt:Icon("\u{f132}")
    tabUtil:Icon("\u{f0ad}")

    local fmtSec, fmtMin, fmtPcs = L("bs_fmt_sec"), L("bs_fmt_min"), L("bs_fmt_pcs")
    local chats = { "bs_chs_team", "bs_chs_all" }
    local targets = { "bs_targets_enemies", "bs_targets_allies", "bs_targets_all" }
    local actions = { "bs_actions_forever", "bs_actions_timed" }

    local gGreet = tabChat:Create("bs_group_greet", Enum.GroupSide.Left)
    local gGG = tabChat:Create("bs_group_gg", Enum.GroupSide.Left)
    local gCtrl = tabChat:Create("bs_group_ctrl", Enum.GroupSide.Right)

    ui.greetEnabled = gGreet:Switch("bs_enable", false, "\u{f2b5}")
    ui.greetEnabled:ToolTip("bs_greet_enable_tip")
    ui.greetChat = gGreet:Combo("bs_chat_to", chats, 0)
    ui.greetChat:Icon("\u{f075}")
    ui.greetText = gGreet:Input("bs_text", "gl hf!", "\u{f040}")

    ui.ggEnabled = gGG:Switch("bs_enable", true, "\u{f11e}")
    ui.ggEnabled:ToolTip("bs_gg_enable_tip")
    ui.ggChat = gGG:Combo("bs_chat_to", chats, 0)
    ui.ggChat:Icon("\u{f075}")
    ui.ggText = gGG:Input("bs_text", L("bs_gg_default"), "\u{f040}")

    ui.msgCtrlEnabled = gCtrl:Switch("bs_ctrl_enable", false, "\u{f05e}")
    ui.msgCtrlEnabled:ToolTip("bs_ctrl_enable_tip")
    ui.msgCtrlMode = gCtrl:Combo("bs_ctrl_mode", { "bs_ctrl_modes_block", "bs_ctrl_modes_chance", "bs_ctrl_modes_censor" }, 0)
    ui.msgCtrlMode:Icon("\u{f12a}")
    ui.msgCtrlChance = gCtrl:Slider("bs_ctrl_chance", 0, 100, 50, "%d%%")
    ui.msgCtrlChance:Icon("\u{f1d8}")
    ui.msgCtrlEcho = gCtrl:Switch("bs_ctrl_echo", true, "\u{f075}")
    ui.msgCtrlEcho:ToolTip("bs_ctrl_echo_tip")
    ui.muteMyVoice = gCtrl:Switch("bs_mute_mic", false, "\u{f130}")
    ui.muteMyVoice:ToolTip("bs_mute_mic_tip")

    local gTox = tabRep:Create("bs_group_tox", Enum.GroupSide.Left)
    local gVoice = tabRep:Create("bs_group_voice", Enum.GroupSide.Left)
    local gFeed = tabRep:Create("bs_group_feed", Enum.GroupSide.Right)

    ui.toxicEnabled = gTox:Switch("bs_enable", false, "\u{f071}")
    ui.toxicEnabled:ToolTip("bs_tox_enable_tip")
    ui.toxicReason = gTox:Combo("bs_tox_reason", {
        "bs_tox_reasons_all", "bs_tox_reasons_mat", "bs_tox_reasons_osk", "bs_tox_reasons_spam", "bs_tox_reasons_any"
    }, 0)
    ui.toxicReason:Icon("\u{f12a}")
    ui.toxicMatch = gTox:Combo("bs_tox_match", { "bs_tox_matches_exact", "bs_tox_matches_sub", "bs_tox_matches_both" }, 2)
    ui.toxicMatch:Icon("\u{f002}")
    ui.toxicMsgCount = gTox:Slider("bs_tox_count", 1, 50, 5, fmtPcs)
    ui.toxicMsgCount:Icon("\u{f075}")
    ui.toxicTarget = gTox:Combo("bs_target", targets, 2)
    ui.toxicTarget:Icon("\u{f05b}")
    ui.toxicUnmute = gTox:Switch("bs_tox_unmute", true, "\u{f028}")
    ui.toxicUnmute:ToolTip("bs_tox_unmute_tip")

    ui.voiceEnabled = gVoice:Switch("bs_enable", false, "\u{f130}")
    ui.voiceEnabled:ToolTip("bs_voice_enable_tip")
    ui.voiceReason = gVoice:Combo("bs_voice_reason", { "bs_voice_reasons_long", "bs_voice_reasons_any" }, 0)
    ui.voiceReason:Icon("\u{f12a}")
    ui.voiceSec = gVoice:Slider("bs_voice_sec", 1, 60, 15, fmtSec)
    ui.voiceSec:Icon("\u{f252}")

    ui.feedEnabled = gFeed:Switch("bs_enable", false, "\u{f06d}")
    ui.feedEnabled:ToolTip("bs_feed_enable_tip")
    ui.feedBuyback = gFeed:Switch("bs_feed_buyback", true, "\u{f021}")
    ui.feedBuybackMin = gFeed:Slider("bs_feed_buyback_min", 0, 20, 10, fmtMin)
    ui.feedBuybackMin:Icon("\u{f017}")
    ui.feedWards = gFeed:Switch("bs_feed_wards", true, "\u{f06e}")
    local gWards = ui.feedWards:Gear("bs_gear_wards")
    ui.wardBase = gWards:Switch("bs_ward_base", true, "\u{f015}")
    ui.wardPile = gWards:Switch("bs_ward_pile", true, "\u{f5fd}")
    ui.wardClusterCount = gWards:Slider("bs_ward_count", 3, 10, 3, fmtPcs)
    ui.wardClusterCount:Icon("\u{f1ce}")
    ui.wardTower = gWards:Switch("bs_ward_tower", true, "\u{f447}")
    ui.wardDenyObs = gWards:Switch("bs_ward_deny_obs", true, "\u{f06e}")
    ui.wardDenySen = gWards:Switch("bs_ward_deny_sen", false, "\u{f070}")
    ui.feedTarget = gFeed:Combo("bs_target", targets, 1)
    ui.feedTarget:Icon("\u{f05b}")

    local gMute = tabTilt:Create("bs_group_mute", Enum.GroupSide.Left)
    local gPing = tabTilt:Create("bs_group_ping", Enum.GroupSide.Left)
    local gPingMe = tabTilt:Create("bs_group_pingme", Enum.GroupSide.Right)

    ui.muteStartEnabled = gMute:Switch("bs_mute_start", false, "\u{f026}")
    ui.muteStartEnabled:ToolTip("bs_mute_start_tip")
    ui.muteWho = gMute:Combo("bs_mute_who", targets, 2)
    ui.muteWho:Icon("\u{f0c0}")
    ui.hideTiltAlerts = gMute:Switch("bs_hide_tilt", false, "\u{f070}")
    ui.hideTiltAlerts:ToolTip("bs_hide_tilt_tip")

    ui.pingEnabled = gPing:Switch("bs_enable", false, "\u{f124}")
    ui.pingEnabled:ToolTip("bs_ping_enable_tip")
    ui.pingCount = gPing:Slider("bs_ping_count", 1, 10, 3, fmtPcs)
    ui.pingCount:Icon("\u{f124}")
    ui.pingWindow = gPing:Slider("bs_ping_window", 1, 10, 5, fmtSec)
    ui.pingWindow:Icon("\u{f017}")
    ui.pingAction = gPing:Combo("bs_action", actions, 0)
    ui.pingAction:Icon("\u{f05e}")
    ui.pingMuteMin = gPing:Slider("bs_mute_min", 1, 15, 5, fmtMin)
    ui.pingMuteMin:Icon("\u{f017}")
    ui.pingAbility = gPing:Switch("bs_ping_ability", true, "\u{f002}")
    ui.pingReport = gPing:Switch("bs_ping_report", false, "\u{f024}")
    ui.pingReport:ToolTip("bs_ping_report_tip")

    ui.pingAtMeEnabled = gPingMe:Switch("bs_enable", false, "\u{f05e}")
    ui.pingAtMeEnabled:ToolTip("bs_pingme_enable_tip")
    ui.pingMeDead = gPingMe:Switch("bs_pingme_dead", true, "\u{f54c}")
    ui.pingMeXp = gPingMe:Switch("bs_pingme_xp", true, "\u{f201}")
    ui.pingMeHero = gPingMe:Switch("bs_pingme_hero", false, "\u{f05b}")
    ui.pingAtMeAction = gPingMe:Combo("bs_action", actions, 0)
    ui.pingAtMeAction:Icon("\u{f05e}")
    ui.pingAtMeMin = gPingMe:Slider("bs_mute_min", 1, 15, 5, fmtMin)
    ui.pingAtMeMin:Icon("\u{f017}")

    local gLike = tabUtil:Create("bs_group_like", Enum.GroupSide.Left)
    local gParty = tabUtil:Create("bs_group_party", Enum.GroupSide.Left)
    local gNotif = tabUtil:Create("bs_group_notif", Enum.GroupSide.Right)

    ui.likeEnabled = gLike:Switch("bs_enable", true, "\u{f164}")
    ui.likeEnabled:ToolTip("bs_like_enable_tip")
    ui.likeDelayOn = gLike:Switch("bs_like_delay_on", true, "\u{f017}")
    ui.likeDelay = gLike:Slider("bs_like_delay", 1, 5, 2, fmtSec)
    ui.likeDelay:Icon("\u{f017}")
    ui.likeNow = gLike:Button("bs_like_now", function() if tryProcessLikes then tryProcessLikes(true) end end)
    ui.likeNow:Icon("\u{f164}")

    ui.reportParty = gParty:Switch("bs_party_report", false, "\u{f0c0}")
    ui.muteParty = gParty:Switch("bs_party_mute", false, "\u{f0c0}")

    ui.notifyScreen = gNotif:Switch("bs_notif_screen", true, "\u{f0f3}")
    ui.notifyChat = gNotif:Switch("bs_notif_chat", false, "\u{f075}")
    ui.notifyChat:ToolTip("bs_notif_chat_tip")
    ui.notifyLog = gNotif:Switch("bs_notif_log", true, "\u{f15c}")
    ui.notifyDur = gNotif:Slider("bs_notif_dur", 1, 15, 4, fmtSec)
    ui.notifyDur:Icon("\u{f017}")
end

local function refreshUi()
    local greetOn = ui.greetEnabled:Get()
    ui.greetChat:Disabled(not greetOn)
    ui.greetText:Disabled(not greetOn)

    local ggOn = ui.ggEnabled:Get()
    ui.ggChat:Disabled(not ggOn)
    ui.ggText:Disabled(not ggOn)

    local ctrlOn = ui.msgCtrlEnabled:Get()
    ui.msgCtrlMode:Disabled(not ctrlOn)
    ui.msgCtrlEcho:Disabled(not ctrlOn)
    ui.msgCtrlChance:Disabled(not ctrlOn)
    ui.msgCtrlChance:Visible(ui.msgCtrlMode:Get() == 1)

    local toxOn, toxMode = ui.toxicEnabled:Get(), ui.toxicReason:Get()
    ui.toxicReason:Disabled(not toxOn)
    ui.toxicTarget:Disabled(not toxOn)
    ui.toxicUnmute:Disabled(not toxOn)
    ui.toxicMatch:Disabled(not toxOn)
    ui.toxicMatch:Visible(toxMode <= 2)
    ui.toxicMsgCount:Disabled(not toxOn)
    ui.toxicMsgCount:Visible(toxMode == 3)

    local voiceOn = ui.voiceEnabled:Get()
    ui.voiceReason:Disabled(not voiceOn)
    ui.voiceSec:Disabled(not voiceOn)
    ui.voiceSec:Visible(ui.voiceReason:Get() == 0)

    local feedOn = ui.feedEnabled:Get()
    local wardsOn = feedOn and ui.feedWards:Get()
    ui.feedBuyback:Disabled(not feedOn)
    ui.feedBuybackMin:Disabled(not feedOn or not ui.feedBuyback:Get())
    ui.feedWards:Disabled(not feedOn)
    ui.feedTarget:Disabled(not feedOn)
    ui.wardBase:Disabled(not wardsOn)
    ui.wardPile:Disabled(not wardsOn)
    ui.wardClusterCount:Disabled(not wardsOn or not ui.wardPile:Get())
    ui.wardTower:Disabled(not wardsOn)
    ui.wardDenyObs:Disabled(not wardsOn)
    ui.wardDenySen:Disabled(not wardsOn)

    ui.muteWho:Disabled(not ui.muteStartEnabled:Get())

    local pingOn = ui.pingEnabled:Get()
    ui.pingCount:Disabled(not pingOn)
    ui.pingWindow:Disabled(not pingOn)
    ui.pingAction:Disabled(not pingOn)
    ui.pingAbility:Disabled(not pingOn)
    ui.pingReport:Disabled(not pingOn)
    ui.pingMuteMin:Disabled(not pingOn)
    ui.pingMuteMin:Visible(ui.pingAction:Get() == 1)

    local pingMeOn = ui.pingAtMeEnabled:Get()
    ui.pingMeDead:Disabled(not pingMeOn)
    ui.pingMeXp:Disabled(not pingMeOn)
    ui.pingMeHero:Disabled(not pingMeOn)
    ui.pingAtMeAction:Disabled(not pingMeOn)
    ui.pingAtMeMin:Disabled(not pingMeOn)
    ui.pingAtMeMin:Visible(ui.pingAtMeAction:Get() == 1)

    local likeOn = ui.likeEnabled:Get()
    ui.likeDelayOn:Disabled(not likeOn)
    ui.likeNow:Disabled(not likeOn)
    ui.likeDelay:Disabled(not likeOn or not ui.likeDelayOn:Get())

    ui.notifyDur:Disabled(not ui.notifyScreen:Get())
end

local comboKeys = {
    "greetChat", "ggChat", "msgCtrlMode", "toxicReason", "toxicMatch", "toxicTarget",
    "voiceReason", "feedTarget", "muteWho", "pingAction", "pingAtMeAction"
}

local function saveCombos()
    local changed = false
    for _, key in ipairs(comboKeys) do
        local value = tostring(ui[key]:Get())
        if store["combo_" .. key] ~= value then
            store["combo_" .. key] = value
            changed = true
        end
    end
    if changed then writeStore() end
end

for _, key in ipairs(comboKeys) do
    local saved = tonumber(store["combo_" .. key])
    if saved and saved ~= ui[key]:Get() then ui[key]:Set(saved) end
end

local function onMenuChange()
    saveCombos()
    refreshUi()
end

local callbackItems = {
    ui.greetEnabled, ui.ggEnabled, ui.msgCtrlEnabled,
    ui.toxicEnabled, ui.voiceEnabled,
    ui.feedEnabled, ui.feedBuyback, ui.feedWards, ui.wardPile,
    ui.muteStartEnabled, ui.pingEnabled,
    ui.pingAtMeEnabled, ui.likeEnabled, ui.likeDelayOn, ui.notifyScreen
}
for _, key in ipairs(comboKeys) do callbackItems[#callbackItems + 1] = ui[key] end
for _, item in ipairs(callbackItems) do
    item:SetCallback(onMenuChange)
end
saveCombos()
refreshUi()

math.randomseed(os.time())

local heroNames = {
    windrunner = "windranger", nevermore = "shadow fiend", zuus = "zeus", wisp = "io",
    rattletrap = "clockwerk", furion = "nature's prophet", shredder = "timbersaw",
    obsidian_destroyer = "outworld destroyer", abyssal_underlord = "underlord",
    skeleton_king = "wraith king", doom_bringer = "doom", magnataur = "magnus",
    necrolyte = "necrophos", queenofpain = "queen of pain", antimage = "anti-mage",
    life_stealer = "lifestealer", nyx_assassin = "nyx assassin",
    templar_assassin = "templar assassin", vengefulspirit = "vengeful spirit"
}

local baseFallback = {
    [2] = { fort = Vector(-6100, -6200, 384), fountain = Vector(-6895, -6307, 384) },
    [3] = { fort = Vector(6100, 6200, 384), fountain = Vector(6845, 6318, 384) },
}

local wardClasses = {
    ["C_DOTA_NPC_Observer_Ward"] = true,
    ["C_DOTA_NPC_Sentry_Ward"] = true,
}

local init = false
local myTeam = nil
local myPid = -1
local myAcc = 0
local myHeroName = ""
local myHeroClean = ""

local m_players = {}
local slotToPid = {}
local accToPid = {}
local allyBuybackTime = {}
local lastSync = 0

local partyAccs = {}
local partyParsed = false
local lastPartyTry = 0
local lastLobbyCheck = 0
local cachedLobbyId = nil

local reportQueue = {}
local repKeys = {}
local regReports = {}
local lastRepTime = 0

local msgCount = {}
local pingTimes = {}
local pingCd = {}
local voiceData = {}
local lastSenderPid = -1

local hudRoot = nil
local lastHudCheck = 0

local knownWards = {}
local handledWards = {}
local pendingWards = {}
local bases = { forts = {}, fountains = {}, towers = {}, last = 0 }
local fortsCache = {}
local fortsLastScan = 0

local startDone = false
local greetSent = false
local muteStartDone = false
local throneBroken = false
local ggSent = false
local ggTime = nil

local stateInited = false
local lastGameState = -1
local gameEndTime = nil
local likePending = false
local likeAttempts = 0
local likeNextT = 0

local function getHud()
    if not hudRoot then
        hudRoot = Panorama.GetPanelByName("DotaHud", false)
    end
    return hudRoot
end

local function logLine(text)
    if ui.notifyLog:Get() then print("[BH] " .. text) end
end

local function notify(text)
    logLine(text)
    if ui.notifyChat:Get() then Chat.Print("ConsoleChat", "[BH] " .. text) end
    if ui.notifyScreen:Get() then Render.CenteredNotification(text, ui.notifyDur:Get()) end
end

local function muteText(forever, mins)
    return forever and L("bs_msg_forever") or string.format(L("bs_fmt_min"), mins)
end

local function toAccId(val)
    if not val then return nil end
    local s = tostring(val):gsub("[^%d]", "")
    if #s == 17 and s:sub(1, 4) == "7656" then
        local acc = tonumber(s:sub(-11)) - STEAM_TAIL
        if acc and acc > 0 and acc < 4294967295 then
            return math.floor(acc)
        end
        return nil
    end
    local n = tonumber(s)
    if n and n > 0 and n < 4294967295 then
        return math.floor(n)
    end
    return nil
end

local function getAcc(p)
    if not p then return 0 end
    local pd = Player.GetPlayerData(p)
    if pd and pd.steamid then
        return toAccId(pd.steamid) or 0
    end
    return 0
end

local function getLobbyId()
    local id = GameRules.GetLobbyID()
    if id and id ~= 0 then
        return string.format("%.0f", id)
    end
    local raw = GameRules.GetLobbyObjectJson()
    if raw and raw ~= "" then
        local lid = raw:match('"lobby_id"%s*:%s*"?(%d+)"?')
        if lid and lid ~= "0" then return lid end
    end
    return "0"
end

local function saveHeroName(hero)
    if not hero or myHeroClean ~= "" then return end
    local raw = NPC.GetUnitName(hero) or ""
    if raw ~= "" then
        myHeroName = raw
        local short = raw:gsub("^npc_dota_hero_", ""):lower()
        myHeroClean = heroNames[short] or short:gsub("_", " ")
    end
end

local handleBuyback

local function syncPlayers(force)
    local t = os.clock()
    if not force and (t - lastSync < 2.0) then return end
    lastSync = t

    for i = 0, Players.Count() - 1 do
        local p = Players.Get(i)
        if p then
            local pid = Player.GetPlayerID(p)
            if pid and pid >= 0 then
                local acc = getAcc(p)
                local slot = Player.GetPlayerSlot(p) or pid
                local team = Entity.GetTeamNum(p)
                if pid == myPid and acc > 0 then myAcc = acc end

                local rawName = Player.GetName(p)
                m_players[pid] = {
                    ent = p,
                    hero = m_players[pid] and m_players[pid].hero or nil,
                    name = (rawName and rawName ~= "") and rawName or ("Player " .. pid),
                    acc = acc,
                    team = team,
                    slot = slot
                }
                if slot >= 0 then slotToPid[slot] = pid end
                if acc > 0 then accToPid[acc] = pid end

                if myTeam and team == myTeam and pid ~= myPid then
                    local td = Player.GetTeamData(p)
                    local bbTime = td and td.last_buyback_time or 0
                    if bbTime > 0 then
                        local prev = allyBuybackTime[pid]
                        allyBuybackTime[pid] = bbTime
                        if prev and bbTime > prev and handleBuyback then
                            handleBuyback(pid)
                        end
                    elseif not allyBuybackTime[pid] then
                        allyBuybackTime[pid] = 0
                    end
                end
            end
        end
    end

    for _, h in pairs(Heroes.GetAll()) do
        if h and Entity.IsHero(h) then
            local hpid = Hero.GetPlayerID(h)
            if hpid and m_players[hpid] then
                m_players[hpid].hero = h
                if hpid == myPid then saveHeroName(h) end
            end
        end
    end
end

local function checkParty(force)
    if partyParsed and not force then return end
    local raw = GameRules.GetLobbyObjectJson()
    if not raw or raw == "" then return end

    local ok, data = pcall(JSON.decode, JSON, raw)
    if not ok or type(data) ~= "table" or type(data.all_members) ~= "table" then return end

    if myAcc == 0 then
        local me = Players.GetLocal()
        if me then myAcc = getAcc(me) end
    end

    syncPlayers(false)
    local inMatch = 0
    for _ in pairs(m_players) do inMatch = inMatch + 1 end
    if inMatch == 0 then return end

    local members = data.all_members
    if #members >= 1 and #members < 5 and #members < inMatch then
        for _, m in ipairs(members) do
            local acc = toAccId(m.id)
            if acc and acc ~= myAcc then
                partyAccs[acc] = true
            end
        end
    end
    partyParsed = true
end

local function inMyParty(pid)
    checkParty(false)
    local p = m_players[pid]
    return (p and p.acc > 0 and partyAccs[p.acc]) or false
end

local function checkText(msg, sets, exact, substr)
    if not msg or msg == "" then return false end
    local s = rx.norm(rx.cps(low(msg)))
    local n = #s
    local wordOf, white = {}, {}
    local w = 0
    for i = 1, n do
        if rx.isWord(s[i]) then
            if i == 1 or not rx.isWord(s[i - 1]) then
                w = w + 1
                local j = i
                while j < n and rx.isWord(s[j + 1]) do j = j + 1 end
                local word = utf8.char(table.unpack(s, i, j))
                for _, wl in ipairs(wordsWhite) do
                    if word:find(wl, 1, true) then
                        white[w] = true
                        break
                    end
                end
            end
            wordOf[i] = w
        end
    end

    for _, list in ipairs(sets) do
        for _, pat in ipairs(list) do
            local part = substr and pat.min >= 5
            for i = 1, n do
                local wi = wordOf[i]
                local start = wi and wordOf[i - 1] ~= wi
                if wi and not white[wi] and (part or (start and (exact or substr))) then
                    local stop
                    local hit = rx.one(pat.node, s, i, function(e)
                        if e <= i then return false end
                        if part or e > n or not rx.isWord(s[e]) then
                            stop = e
                            return true
                        end
                        return false
                    end)
                    if hit then return true, utf8.char(table.unpack(s, i, stop - 1)) end
                end
            end
        end
    end
    return false
end

local function getMatchDuration()
    local t = GameRules.GetGameTime() or 0
    local start = GameRules.GetGameStartTime() or 0
    local finish = GameRules.GetGameEndTime() or 0

    local played = 0
    if finish > 0 and start > 0 then
        played = finish - start
    elseif start > 0 and t > start then
        played = t - start
    else
        played = GameRules.GetDOTATime(false, false) or 0
    end
    return math.max(0, math.floor(played))
end

local function saveReportState()
    local lobby = getLobbyId()
    if lobby == "0" then return end
    local list = {}
    for acc, reg in pairs(regReports) do
        for r in pairs(reg) do
            list[#list + 1] = acc .. ":" .. r
            if #list >= 120 then break end
        end
        if #list >= 120 then break end
    end
    storeSet("lobby", lobby)
    storeSet("reports", table.concat(list, ";"))
end

local function loadSavedState()
    local lobby = getLobbyId()
    if lobby == "0" then return end
    if store.greet == lobby then
        greetSent = true
    end
    if store.lobby == lobby then
        for entry in (store.reports or ""):gmatch("[^;]+") do
            local acc, r = entry:match("^(%d+):(%d+)$")
            local nAcc, nR = tonumber(acc), tonumber(r)
            if nAcc and nR then
                regReports[nAcc] = regReports[nAcc] or {}
                regReports[nAcc][nR] = true
            end
        end
    end
end

local function mutePlayer(pid, dur)
    local hud = getHud()
    if not hud then return end

    local js = string.format("Game.SetPlayerMuted(%d, true);", pid)
    if dur and dur > 0 then
        js = js .. string.format(" $.Schedule(%.1f, function() { Game.SetPlayerMuted(%d, false); });", dur, pid)
    end
    Engine.RunScript(js, hud)
end

local function targetAllowed(team, widget)
    local mode = widget:Get()
    if mode == 2 then return true end
    if team == myTeam then return mode == 1 end
    return mode == 0
end

local function addReportQueue(pid, reason, label, trigger, needMute)
    syncPlayers(false)
    local p = m_players[pid]
    local acc = p and p.acc or 0
    if acc == 0 and p and p.ent then
        acc = getAcc(p.ent)
        p.acc = acc
    end
    local name = (p and p.name) or ("Player " .. pid)

    local key = acc .. ":" .. reason
    local dup = repKeys[key] or (regReports[acc] and regReports[acc][reason])
    if pid == myPid or dup or acc == 0 then return end

    checkParty(false)
    if not ui.reportParty:Get() and partyAccs[acc] then
        notify(string.format(L("bs_msg_party"), name))
        return
    end

    repKeys[key] = true
    reportQueue[#reportQueue + 1] = {
        pid = pid, acc = acc, reason = reason,
        label = label, trigger = trigger, mute = needMute, name = name
    }
end

local function processReportQueue()
    if #reportQueue == 0 then return end
    local t = os.clock()
    if t - lastRepTime < 2.0 then return end

    local entry = table.remove(reportQueue, 1)
    if entry.acc == 0 and m_players[entry.pid] then
        entry.acc = getAcc(m_players[entry.pid].ent)
    end
    if entry.acc == 0 then return end
    if not ui.reportParty:Get() and partyAccs[entry.acc] then return end

    if entry.mute then
        mutePlayer(entry.pid, ui.toxicUnmute:Get() and 3.0 or 0)
    end

    local me = Players.GetLocal()
    local mySlot = me and Player.GetPlayerSlot(me) or 0

    local okJson, jsonStr = pcall(JSON.encode, JSON, {
        target_account_id = entry.acc,
        report_reason = { entry.reason },
        lobby_id = getLobbyId(),
        game_time = GameRules.GetGameTime() or 0.0,
        debug_slot = mySlot,
        debug_match_id = "0"
    })
    if not okJson or not jsonStr then return end

    local okProto, protoData = pcall(protobuf.encodeFromJSON, "CMsgDOTASubmitPlayerReportV2", jsonStr)
    if not okProto or not protoData or not protoData.binary then return end

    GC.SendMessage(protoData.binary, 7082, protoData.size)
    if protobuf.free then pcall(protobuf.free, protoData.binary) end

    regReports[entry.acc] = regReports[entry.acc] or {}
    regReports[entry.acc][entry.reason] = true
    saveReportState()

    lastRepTime = t
    notify(string.format(L("bs_msg_sent"), entry.name, L(entry.label), entry.trigger or "?"))
end

local function handleChatMessage(pid, message)
    if not ui.toxicEnabled:Get() or not message or message == "" or pid == myPid then return end
    syncPlayers(false)

    local p = m_players[pid]
    if not p or not targetAllowed(p.team, ui.toxicTarget) then return end

    local rIdx = ui.toxicReason:Get()
    if rIdx == 4 then
        addReportQueue(pid, 2, "bs_lbl_toxic", "'" .. message:sub(1, 40) .. "'", true)
        return
    end

    if rIdx == 3 then
        msgCount[pid] = (msgCount[pid] or 0) + 1
        local limit = ui.toxicMsgCount:Get()
        if msgCount[pid] == limit then
            addReportQueue(pid, 2, "bs_lbl_spam", string.format(L("bs_tr_msgs"), limit), true)
        end
        return
    end

    local sets = setsAll
    if rIdx == 1 then sets = setsMat
    elseif rIdx == 2 then sets = setsOsk end

    local mode = ui.toxicMatch:Get()
    local isBad, trig = checkText(message, sets, mode ~= 1, mode ~= 0)
    if isBad then
        addReportQueue(pid, 2, "bs_lbl_toxic", trig, true)
    end
end

local function handleVoice(data)
    if not ui.voiceEnabled:Get() then return end
    syncPlayers(false)

    local acc = toAccId(data.xuid)
    local slot = tonumber(data.client_deprecated)
    local pid = (acc and accToPid[acc]) or (slot and slotToPid[slot]) or slot
    if not pid or pid < 0 or pid == myPid then return end

    local p = m_players[pid]
    if not p or (myTeam and p.team and p.team ~= myTeam) then return end

    local t = os.clock()
    local st = voiceData[pid]
    if not st then
        st = { last = t, active = 0.03, packets = 1, reported = false }
        voiceData[pid] = st
    else
        local dt = t - st.last
        if dt > 0.005 then
            st.active = st.active + (dt <= 0.25 and dt or 0.03)
            st.last = t
        end
        st.packets = st.packets + 1
    end

    if st.reported then return end

    local rMode = ui.voiceReason:Get()
    if rMode == 0 and st.active >= ui.voiceSec:Get() then
        st.reported = true
        addReportQueue(pid, 3, "bs_lbl_voice", string.format(L("bs_tr_mic_sec"), math.floor(st.active)), false)
    elseif rMode == 1 and st.packets >= 2 then
        st.reported = true
        addReportQueue(pid, 3, "bs_lbl_voice", L("bs_tr_mic"), false)
    end
end

local function muteForPing(pid, label)
    if not pid or pid < 0 or pid == myPid then return end
    local t = os.clock()
    if pingCd[pid] and t < pingCd[pid] then return end
    if not ui.muteParty:Get() and inMyParty(pid) then return end

    syncPlayers(false)
    local forever = (ui.pingAtMeAction:Get() == 0)
    local mins = ui.pingAtMeMin:Get()
    pingCd[pid] = t + 3.0
    mutePlayer(pid, forever and 0 or (mins * 60))
    local p = m_players[pid]
    local pName = (p and p.name) or ("Player " .. pid)
    notify(string.format(L("bs_msg_mute"), L(label), pName, muteText(forever, mins)))
end

local pingExtra = { [523] = true, [609] = true, [624] = true, [625] = true }

local function handlePing(msgId, data)
    local pid = tonumber(msgId == 609 and data.player_id_of_original_pinger or data.player_id)
    if not pid or pid < 0 or pid == myPid then return end

    lastSenderPid = pid
    if msgId ~= 477 and not (pingExtra[msgId] and ui.pingAbility:Get()) then return end

    local t = os.clock()
    if pingCd[pid] and t < pingCd[pid] then return end
    if not ui.muteParty:Get() and inMyParty(pid) then return end

    if ui.pingAtMeEnabled:Get() and ui.pingMeHero:Get() and msgId == 477 and type(data.location_ping) == "table" then
        local lp = data.location_ping
        local myHero = Heroes.GetLocal()
        if myHero and Entity.IsAlive(myHero) then
            local target = tonumber(lp.target)
            local hit = (target and target > 0 and target == Entity.GetIndex(myHero))
            if not hit then
                local px, py = tonumber(lp.x), tonumber(lp.y)
                local myPos = Entity.GetAbsOrigin(myHero)
                if px and py and myPos and Vector(px, py, 0):Distance2D(myPos) <= 150 then
                    hit = true
                end
            end
            if hit then
                muteForPing(pid, "bs_lbl_ping_hero")
                return
            end
        end
    end

    if ui.pingEnabled:Get() then
        local times = pingTimes[pid] or {}
        pingTimes[pid] = times
        times[#times + 1] = t

        local cutoff = t - ui.pingWindow:Get()
        local j = 1
        while j <= #times do
            if times[j] < cutoff then table.remove(times, j) else j = j + 1 end
        end

        if #times > ui.pingCount:Get() then
            local count = #times
            pingTimes[pid] = {}
            pingCd[pid] = t + 3.0
            syncPlayers(false)
            local forever = (ui.pingAction:Get() == 0)
            local mins = ui.pingMuteMin:Get()
            mutePlayer(pid, forever and 0 or (mins * 60))
            local p = m_players[pid]
            local pName = (p and p.name) or ("Player " .. pid)
            notify(string.format(L("bs_msg_mute"), L("bs_lbl_ping_spam"), pName, muteText(forever, mins)))
            if ui.pingReport:Get() then
                local trig = string.format(L("bs_tr_pings"), count, ui.pingWindow:Get())
                addReportQueue(pid, 5, "bs_lbl_feed", trig, false)
                addReportQueue(pid, 2, "bs_lbl_toxic", trig, false)
            end
        end
    end
end

local function jsQuote(s)
    return (s:gsub("\\", "\\\\"):gsub("'", "\\'"))
end

local function checkHud(localHero)
    local hide = ui.hideTiltAlerts:Get()
    local muteOn = ui.pingAtMeEnabled:Get()
    if not hide and not muteOn then return end

    local now = os.clock()
    if now - lastHudCheck < 0.1 then return end
    lastHudCheck = now

    local hud = getHud()
    if not hud then return end

    saveHeroName(localHero)
    local mDead = (muteOn and ui.pingMeDead:Get()) and 1 or 0
    local mXp = (muteOn and ui.pingMeXp:Get()) and 1 or 0
    local isDead = (localHero and not Entity.IsAlive(localHero)) and 1 or 0
    local dur = (ui.pingAtMeAction:Get() == 1) and (ui.pingAtMeMin:Get() * 60) or 0
    local fb = (lastSenderPid >= 0 and (ui.muteParty:Get() or not inMyParty(lastSenderPid))) and lastSenderPid or -1

    local pMap = "{"
    for pid, info in pairs(m_players) do
        if pid ~= myPid and info.name ~= "" and (ui.muteParty:Get() or not inMyParty(pid)) then
            local k = low(info.name):gsub('\\', ''):gsub('"', '')
            pMap = pMap .. '"' .. k .. '":' .. pid .. ','
        end
    end
    pMap = pMap .. "}"

    local js = "var hud = $.GetContextPanel();"
        .. "function grab(p){ if(!p) return ''; var s = p.text || ''; for(var i=0; i < (p.GetChildCount ? p.GetChildCount() : 0); i++) s += ' ' + grab(p.GetChild(i)); return s.toLowerCase(); }"
        .. "function has(s, arr){ for(var i=0; i<arr.length; i++) if(s.includes(arr[i])) return true; return false; }"
        .. "var tips = ['хвалит','благодарит','типает','tipped'];"

    if hide then
        js = js .. "var tms = [hud.FindChildTraverse('ToastManager'), hud.FindChildTraverse('SpectatorToastManager')];"
            .. "for(var m=0; m<2; m++){ var tm = tms[m]; if(!tm) continue;"
            .. "for(var i=0; i<tm.GetChildCount(); i++){ var c = tm.GetChild(i);"
            .. "if(c && c.style.visibility !== 'collapse' && (c.BHasClass('TipToast') || c.FindChildTraverse('SourceHeroImage') || has(grab(c), tips))) c.style.visibility = 'collapse'; } }"
    end

    js = js .. "var box = hud.FindChildTraverse('ChatLinesPanel');"
        .. "if(box){ var n = box.GetChildCount(), pls = " .. pMap .. ";"
        .. "var h1 = '" .. jsQuote(myHeroClean) .. "', h2 = '" .. jsQuote(myHeroName) .. "';"
        .. "var hLoc = h2 ? $.Localize('#' + h2).toLowerCase() : '';"
        .. "for(var i = Math.max(0, n - 12); i < n; i++){"
        .. "var row = box.GetChild(i); if(!row || row.style.visibility === 'collapse') continue;"
        .. "var s = grab(row); if(!s) continue;"
        .. (hide and "if(row.BHasClass('TipChat') || has(s, tips)){ row.style.visibility = 'collapse'; continue; }" or "")
        .. "if(s.includes('я возрожусь')) continue;"
        .. "var r = has(s, ['возродится','будет жив','respawn']), x = has(s, ['опыта до','ед. опыта','experience']);"
        .. "if(!r && !x) continue;"
        .. "if(!((h1 && s.includes(h1)) || (hLoc && hLoc[0] !== '#' && s.includes(hLoc)) || (r && " .. isDead .. " && s.includes('союзника возродится')))) continue;"
        .. "var who = " .. fb .. ", pref = s.split(':')[0];"
        .. "for(var name in pls){ if(name && pref.includes(name)){ who = pls[name]; break; } }"
        .. "if(who >= 0 && who !== " .. myPid .. " && !row.bhMuted && ((r && " .. mDead .. ") || (x && " .. mXp .. "))){"
        .. "row.bhMuted = true; Game.SetPlayerMuted(who, true);"
        .. (dur > 0 and ("let p = who; $.Schedule(" .. dur .. ", function(){ Game.SetPlayerMuted(p, false); });") or "")
        .. "}"
        .. (hide and "row.style.visibility = 'collapse';" or "")
        .. "} }"

    Engine.RunScript(js, hud)
end

local function isWardEnt(ent)
    if not ent or not Entity.IsEntity(ent) then return nil end
    local cls = Entity.GetClassName(ent)
    if cls and wardClasses[cls] then return cls end
    if Entity.IsNPC(ent) and NPC.IsWard(ent) then
        return NPC.GetUnitName(ent) or cls
    end
    return nil
end

local function getWardOwnerPid(ent)
    local o = Entity.GetOwner(ent)
    if o and Entity.IsEntity(o) then
        if Entity.IsHero(o) then return Hero.GetPlayerID(o) end
        if Entity.IsPlayer(o) then return Player.GetPlayerID(o) end
    end
    local ro = Entity.RecursiveGetOwner(ent)
    if ro and Entity.IsEntity(ro) then
        if Entity.IsPlayer(ro) then return Player.GetPlayerID(ro) end
        if Entity.IsHero(ro) then return Hero.GetPlayerID(ro) end
    end
    return nil
end

local function updateBases()
    local t = os.clock()
    if (t - bases.last) < 15.0 and next(bases.forts) ~= nil then return end
    bases.last = t

    local forts, fountains, towers = {}, {}, {}
    for _, npc in pairs(NPCs.GetAll()) do
        if npc and Entity.IsEntity(npc) then
            local cls = Entity.GetClassName(npc) or ""
            local name = Entity.IsNPC(npc) and (NPC.GetUnitName(npc) or "") or ""
            local full = (name .. " " .. cls):lower()
            local team = Entity.GetTeamNum(npc)
            if team == 2 or team == 3 then
                if NPC.IsFort(npc) or full:find("fort", 1, true) then
                    forts[team] = Entity.GetAbsOrigin(npc)
                elseif full:find("fountain", 1, true) then
                    fountains[team] = Entity.GetAbsOrigin(npc)
                else
                    local isTower = (cls == "C_DOTA_BaseNPC_Tower" or full:find("guys_tower", 1, true))
                        and not full:find("watch_tower", 1, true)
                        and not full:find("outpost", 1, true)
                        and not full:find("lantern", 1, true)
                    if isTower and Entity.IsAlive(npc) then
                        local pos = Entity.GetAbsOrigin(npc)
                        if pos then
                            towers[team] = towers[team] or {}
                            towers[team][#towers[team] + 1] = pos
                        end
                    end
                end
            end
        end
    end
    for team, coords in pairs(baseFallback) do
        if not forts[team] then forts[team] = coords.fort end
        if not fountains[team] then fountains[team] = coords.fountain end
    end
    bases.forts = forts
    bases.fountains = fountains
    bases.towers = towers
end

local function handleWard(wardEnt)
    if not wardEnt or not ui.feedEnabled:Get() or not ui.feedWards:Get() or not isWardEnt(wardEnt) then return end

    local eidx = Entity.GetIndex(wardEnt)
    if eidx then
        local old = handledWards[eidx]
        if old and (old == wardEnt or Entity.IsEntity(old)) then return end
        handledWards[eidx] = wardEnt
    end

    local pos = Entity.GetAbsOrigin(wardEnt)
    if not pos then return end

    local ownerPid = getWardOwnerPid(wardEnt)
    local wardTeam = Entity.GetTeamNum(wardEnt)
    if not ownerPid or ownerPid < 0 then
        syncPlayers(false)
        local bestDist = 1500
        for pid, info in pairs(m_players) do
            local unit = info.hero or info.ent
            if pid ~= myPid and info.team == wardTeam and unit and Entity.IsEntity(unit) then
                local uPos = Entity.GetAbsOrigin(unit)
                if uPos then
                    local d = uPos:Distance2D(pos)
                    if d <= bestDist then ownerPid, bestDist = pid, d end
                end
            end
        end
    end

    local ownerTeam = (ownerPid and m_players[ownerPid] and m_players[ownerPid].team) or wardTeam
    local t = os.clock()
    knownWards[#knownWards + 1] = { ent = wardEnt, pos = pos, pid = ownerPid, t = t }
    local k = 1
    while k <= #knownWards do
        local kw = knownWards[k]
        local alive = kw.ent and Entity.IsEntity(kw.ent) and Entity.IsAlive(kw.ent)
        if not alive or kw.t < (t - 90) then
            table.remove(knownWards, k)
        else
            k = k + 1
        end
    end

    if not ownerPid or ownerPid < 0 or ownerPid == myPid then return end
    local p = m_players[ownerPid]
    if not p or not targetAllowed(p.team, ui.feedTarget) then return end

    updateBases()
    local trigger = nil

    if ui.wardBase:Get() then
        local fPos = bases.forts[ownerTeam]
        local fnPos = bases.fountains[ownerTeam]
        local dFort = fPos and pos:Distance2D(fPos) or 99999
        local dFount = fnPos and pos:Distance2D(fnPos) or 99999
        local minD = math.min(dFort, dFount)
        if minD <= 1200 then
            trigger = string.format(L("bs_tr_ward_base"), math.floor(minD))
        end
    end

    if not trigger and ui.wardTower:Get() then
        local enemyTeam = (ownerTeam == 2) and 3 or 2
        for _, tPos in ipairs(bases.towers[enemyTeam] or {}) do
            local dTow = pos:Distance2D(tPos)
            if dTow <= 700 then
                trigger = string.format(L("bs_tr_ward_tower"), math.floor(dTow))
                break
            end
        end
    end

    if not trigger and ui.wardPile:Get() then
        local count = 0
        for _, w in ipairs(knownWards) do
            if w.pid == ownerPid and w.pos:Distance2D(pos) <= 250 then
                count = count + 1
            end
        end
        if count >= ui.wardClusterCount:Get() then
            trigger = string.format(L("bs_tr_ward_pile"), count)
        end
    end

    if trigger then
        addReportQueue(ownerPid, 5, "bs_lbl_wards", trigger, false)
    end
end

handleBuyback = function(pid)
    if not (ui.feedEnabled:Get() and ui.feedBuyback:Get()) then return end
    local clock = getMatchDuration()
    if pid and pid >= 0 and pid ~= myPid and (clock / 60) <= ui.feedBuybackMin:Get() then
        syncPlayers(false)
        local p = m_players[pid]
        if p and targetAllowed(p.team, ui.feedTarget) then
            addReportQueue(pid, 5, "bs_lbl_feed", string.format(L("bs_tr_buyback"), math.floor(clock / 60)), false)
        end
    end
end

tryProcessLikes = function(manual)
    if not (ui.likeEnabled:Get() or manual) then return end
    if not manual and not likePending then return end

    local panel = Panorama.GetPanelByName("OverviewHeroes", false)
    if not panel then return end

    local total = 0
    for _, side in ipairs({ "LeftHeroes", "RightHeroes" }) do
        local cont = panel:FindChildTraverse(side)
        if cont then
            for i = 0, cont:GetChildCount() - 1 do
                local card = cont:GetChild(i)
                local btn = card and card:FindChildTraverse("ButtonDrawer")
                if btn then
                    Engine.RunScript("$.DispatchEvent('OverviewHeroCommendPlayer')", btn)
                    total = total + 1
                end
            end
        end
    end

    if total > 0 then likePending = false end
    likeAttempts = likeAttempts + 1
    if likeAttempts > 240 then likePending = false end
end

local function resetMatchState()
    ggSent = false
    throneBroken = false
    ggTime = nil
    startDone = false
    greetSent = false
    muteStartDone = false
    msgCount = {}
    pingTimes = {}
    pingCd = {}
    voiceData = {}
    allyBuybackTime = {}
    pendingWards = {}
    knownWards = {}
    handledWards = {}
    fortsCache = {}
    fortsLastScan = 0
    likePending = false
    likeAttempts = 0
    gameEndTime = nil
    repKeys = {}
    reportQueue = {}
    myHeroName = ""
    myHeroClean = ""
    hudRoot = nil
end

local function sendChat(widget, text)
    local msg = (text or ""):gsub('"', '')
    if msg == "" then return end
    local cmd = (widget:Get() == 1) and "say " or "say_team "
    Engine.ExecuteCommand(cmd .. '"' .. msg .. '"')
end

function bh.OnUpdate()
    if init then return end

    local hero = Heroes.GetLocal()
    local me = Players.GetLocal()
    if not hero or not me then return end

    init = true
    myTeam = Entity.GetTeamNum(me)
    myPid = Player.GetPlayerID(me)
    local acc = getAcc(me)
    if acc > 0 then myAcc = acc end
    if myAcc == 0 then myAcc = toAccId(GC.GetSteamID()) or 0 end
    saveHeroName(hero)

    syncPlayers(true)
    checkParty(true)
    loadSavedState()
end

function bh.OnUpdateEx()
    local t = os.clock()
    if likePending and ui.likeEnabled:Get() then
        local delay = ui.likeDelayOn:Get() and ui.likeDelay:Get() or 0
        if gameEndTime and (t - gameEndTime) >= delay + 300 then
            likePending = false
        elseif gameEndTime and (t - gameEndTime) >= delay then
            if t >= likeNextT then
                likeNextT = t + 0.5
                tryProcessLikes(false)
            end
        elseif not gameEndTime then
            gameEndTime = t - delay
        end
    end

    local localHero = Heroes.GetLocal()
    if not localHero or not Entity.IsEntity(localHero) then
        if init then
            init = false
            hudRoot = nil
        end
        return
    end

    saveHeroName(localHero)

    if not partyParsed and (t - lastPartyTry >= 4.0) then
        lastPartyTry = t
        checkParty(true)
    end

    if t - lastLobbyCheck >= 15.0 then
        lastLobbyCheck = t
        local lid = getLobbyId()
        if lid ~= "0" and lid ~= cachedLobbyId then
            if cachedLobbyId ~= nil then
                resetMatchState()
                partyAccs = {}
                partyParsed = false
            end
            cachedLobbyId = lid
            loadSavedState()
            checkParty(true)
        end
    end

    local gs = GameRules.GetGameState()
    if gs then
        if not stateInited then
            stateInited = true
            lastGameState = gs
        elseif gs ~= lastGameState then
            local prev = lastGameState
            lastGameState = gs
            if gs == 2 and prev <= 1 then
                resetMatchState()
            elseif gs == 5 then
                partyParsed = false
                checkParty(true)
            elseif gs == 6 then
                gameEndTime = t
                if ui.likeEnabled:Get() then
                    likePending = true
                    likeAttempts = 0
                end
            end
        end
    end

    if #pendingWards > 0 then
        local i = 1
        while i <= #pendingWards do
            local pw = pendingWards[i]
            if t - pw.t < 0.3 then
                i = i + 1
            else
                table.remove(pendingWards, i)
                if pw.ent and Entity.IsEntity(pw.ent) then handleWard(pw.ent) end
            end
        end
        for eidx, ent in pairs(handledWards) do
            if not Entity.IsEntity(ent) then handledWards[eidx] = nil end
        end
    end

    processReportQueue()
    updateBases()
    if gs and gs >= 4 and gs < 6 then
        checkHud(localHero)
    end

    if not startDone then
        local wantGreet = ui.greetEnabled:Get()
        local wantMute = ui.muteStartEnabled:Get()
        local clock = GameRules.GetDOTATime(false, true)
        if not clock then
            local st = GameRules.GetGameStartTime() or 0
            if st > 0 then clock = GameRules.GetGameTime() - st end
        end

        if not muteStartDone and wantMute then
            if gs and gs >= 4 and clock and clock <= 30 and (gs < 5 or clock < 0) then
                muteStartDone = true
                syncPlayers(true)
                for pid, info in pairs(m_players) do
                    if pid ~= myPid and info.team and (ui.muteParty:Get() or not inMyParty(pid)) then
                        if targetAllowed(info.team, ui.muteWho) then
                            mutePlayer(pid, 0)
                        end
                    end
                end
            end
        end

        if not greetSent and wantGreet then
            local inGame = (gs ~= nil and gs >= 4) or (clock ~= nil and clock >= -60 and clock ~= 0)
            local tooLate = (clock ~= nil and clock > 180)

            if inGame and not tooLate then
                greetSent = true
                local lobby = getLobbyId()
                if lobby ~= "0" then storeSet("greet", lobby) end
                sendChat(ui.greetChat, ui.greetText:Get())
            elseif inGame and tooLate then
                greetSent = true
            end
        end

        if clock and clock > 180 and not muteStartDone then muteStartDone = true end
        startDone = (muteStartDone or not wantMute) and (greetSent or not wantGreet)
    end

    if not throneBroken then
        if t - fortsLastScan > 5.0 and #fortsCache < 2 then
            fortsLastScan = t
            fortsCache = {}
            for _, npc in pairs(NPCs.GetAll()) do
                if npc and Entity.IsNPC(npc) and NPC.IsFort(npc) then
                    fortsCache[#fortsCache + 1] = npc
                end
            end
        end
        for _, fort in ipairs(fortsCache) do
            local valid = Entity.IsEntity(fort)
            if not valid or not Entity.IsAlive(fort) or (Entity.GetHealth(fort) or 1) <= 0 then
                throneBroken = true
                ggTime = t
                break
            end
        end
    elseif ui.ggEnabled:Get() and not ggSent and ggTime and t >= ggTime then
        ggSent = true
        sendChat(ui.ggChat, ui.ggText:Get())
    end

    syncPlayers(false)
end

local function decodeNet(msg)
    local ok, jsonStr = pcall(protobuf.decodeToJSONfromObject, msg.msg_object or msg)
    if not ok or not jsonStr or jsonStr == "" then return nil end
    local okJson, data = pcall(JSON.decode, JSON, jsonStr)
    return okJson and type(data) == "table" and data or nil
end

function bh.OnPostReceivedNetMessage(msg)
    if not msg or not msg.message_id then return true end
    local id = msg.message_id

    if id == 553 and ui.hideTiltAlerts:Get() then
        return false
    end

    if id == 47 then
        if ui.voiceEnabled:Get() then
            local data = decodeNet(msg)
            if data then handleVoice(data) end
        end
        return true
    end

    if id == 477 or pingExtra[id] then
        local data = decodeNet(msg)
        if data then handlePing(id, data) end
        return true
    end

    if id == 612 then
        local data = decodeNet(msg)
        if data then
            local pid = tonumber(data.source_player_id)
            local text = data.message_text
            if pid and pid >= 0 and pid <= 9 then
                lastSenderPid = pid
                if type(text) == "string" and text ~= "" then
                    handleChatMessage(pid, text)
                end
            end
        end
        return true
    end

    if id == 466 and ui.hideTiltAlerts:Get() then
        local data = decodeNet(msg)
        if data and data.type == 71 then
            return false
        end
        return true
    end

    if (ui.pingAtMeEnabled:Get() or ui.hideTiltAlerts:Get()) and id >= 530 and id <= 660 then
        local gs = GameRules.GetGameState()
        if not gs or gs < 4 then return true end

        local data = decodeNet(msg)
        if data then
            local senderPid = tonumber(data.player_id)
            if senderPid and senderPid >= 0 and senderPid <= 9 and senderPid ~= myPid then
                lastSenderPid = senderPid
                local myHero = Heroes.GetLocal()
                local myHeroIdx = (myHero and Entity.GetIndex(myHero)) or -999
                local tEnt = tonumber(data.target_entindex)

                if myHeroIdx > 0 and tEnt and tEnt == myHeroIdx then
                    local meDead = not Entity.IsAlive(myHero)
                    if ui.pingAtMeEnabled:Get() then
                        if meDead and ui.pingMeDead:Get() then
                            muteForPing(senderPid, "bs_lbl_ping_dead")
                        elseif id == 555 and not meDead and ui.pingMeXp:Get() then
                            muteForPing(senderPid, "bs_lbl_ping_xp")
                        end
                    end
                    if ui.hideTiltAlerts:Get() then
                        return false
                    end
                end
            end
        end
    end

    return true
end

function bh.OnSendNetMessage(msg)
    if not msg then return true end

    if msg.message_id == 22 and ui.muteMyVoice:Get() then
        return false
    end

    if msg.message_id ~= 394 or not ui.msgCtrlEnabled:Get() then return true end

    local data = decodeNet(msg)
    if not data or type(data.message_text) ~= "string" then return true end

    local text = data.message_text
    if text:sub(1, 1) == "-" then return true end

    local mode = ui.msgCtrlMode:Get()
    local drop = false

    if mode == 0 then
        drop = true
    elseif mode == 1 then
        drop = (math.random(100) > ui.msgCtrlChance:Get())
    elseif mode == 2 then
        local word
        drop, word = checkText(text, setsAll, true, true)
        if drop then
            Chat.Print("ConsoleChat", string.format(L("bs_ctrl_blocked"), word or "?", text))
            return false
        end
    end

    if drop then
        if ui.msgCtrlEcho:Get() then
            Chat.Print("ConsoleChat", text)
        end
        return false
    end

    return true
end

function bh.OnGCMessage(msg)
    if not msg then return true end
    local mType = msg.msg_type and (msg.msg_type % 0x80000000) or 0
    if mType ~= 7083 then return true end

    local ok, jsonStr = pcall(protobuf.decodeToJSON, "CMsgDOTASubmitPlayerReportResponseV2", msg.binary_buffer_recv, msg.size)
    if ok and jsonStr and jsonStr ~= "" then
        local okJson, data = pcall(JSON.decode, JSON, jsonStr)
        if okJson and type(data) == "table" then
            local res = tonumber(data.enum_result) or -1
            local targetAcc = tonumber(data.target_account_id) or 0
            if res == 1 then
                logLine(L("bs_msg_accepted"))
            elseif res == 14 and targetAcc > 0 then
                partyAccs[targetAcc] = true
                logLine(L("bs_msg_in_party"))
            end
        end
    end
    return true
end

function bh.OnNpcSpawned(npc)
    if npc then handleWard(npc) end
end

function bh.OnEntityCreate(ent)
    if not ent or not (ui.feedEnabled:Get() and ui.feedWards:Get()) then return end
    local cls = Entity.GetClassName(ent)
    if cls and wardClasses[cls] then
        pendingWards[#pendingWards + 1] = { ent = ent, t = os.clock() }
        if #pendingWards > 64 then table.remove(pendingWards, 1) end
    end
end

function bh.OnEntityKilled(data)
    if not data or not data.target or not Entity.IsEntity(data.target) then return end
    local target = data.target

    if Entity.IsNPC(target) and NPC.IsFort(target) then
        throneBroken = true
        if not ggTime then
            ggTime = os.clock()
        end
        return
    end

    if not (ui.feedEnabled:Get() and ui.feedWards:Get()) then return end
    local wName = isWardEnt(target)
    local source = data.source
    if not wName or not source or not Entity.IsHero(source) then return end

    local isSentry = wName:lower():find("sentry", 1, true) ~= nil
    if isSentry and not ui.wardDenySen:Get() then return end
    if not isSentry and not ui.wardDenyObs:Get() then return end

    local owner = Entity.RecursiveGetOwner(target) or Entity.GetOwner(target)
    if owner and Entity.IsEntity(owner) and Entity.IsSameTeam(source, owner) then
        local killerPid = Hero.GetPlayerID(source)
        if killerPid and killerPid ~= myPid then
            syncPlayers(false)
            local p = m_players[killerPid]
            if p and targetAllowed(p.team, ui.feedTarget) then
                addReportQueue(killerPid, 5, "bs_lbl_wards", L(isSentry and "bs_tr_deny_sen" or "bs_tr_deny_obs"), false)
            end
        end
    end
end

function bh.OnChatEvent(data)
    if data and data.type == 7 and data.playerid_1 then
        handleBuyback(data.playerid_1)
    end
end

function bh.OnGameEnd()
    gameEndTime = os.clock()
    if ui.likeEnabled:Get() then
        likePending = true
        likeAttempts = 0
    end
end

return bh
