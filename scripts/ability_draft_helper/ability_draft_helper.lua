--[[
     ~ Ability Draft Helper
     ~ author: 4uJIuH

     ~ localization: qLocalization by qfun (qfun_g9s), shipped as !_qLocalizer.lua
]]

-- The localization library is a separate script (!_qLocalizer.lua). Without it the menu cannot be built.
if not qLocalization then
	return {
		OnScriptsLoaded = function()
			if ai_bridge and ai_bridge.mcp_log then
				ai_bridge.mcp_log("error", "[AD Helper] qLocalization is missing: put !_qLocalizer.lua into the scripts folder", nil)
			end
		end,
	}
end

local localization = qLocalization.new({
	en = {
		-- menu
		adh_group_main = "Ability Draft Helper",
		adh_group_data = "Data and tools",
		adh_enable = "Enable",
		adh_enable_tip = "Ranks the full ability pool, including ultimates, by Ability Draft statistics and picked-ability synergy",
		adh_show = "Show panel",
		adh_show_tip = "Draws the recommendation panel on the draft screen",
		adh_key = "Toggle panel",
		adh_key_tip = "Shows or hides the panel with one key",
		adh_bind_name = "Ability Draft Helper panel",
		adh_preview = "Show outside draft",
		adh_preview_tip = "Keeps the panel visible everywhere so you can place it and tune the look",
		adh_side = "Default side",
		adh_side_tip = "Where the panel appears until you drag it. Changing this resets the saved position",
		adh_side_left = "Left",
		adh_side_right = "Right",
		adh_role = "Draft role focus",
		adh_role_tip = "Optional role-aware ranking. Fills scarce build needs; does not change the default ranking when Off",
		adh_role_off = "Off",
		adh_role_carry = "Carry",
		adh_role_mid = "Mid",
		adh_role_offlane = "Offlane",
		adh_role_support = "Soft support",
		adh_role_hard_support = "Hard support",
		adh_refresh = "Refresh data",
		adh_refresh_tip = "Downloads fresh statistics, no more than once a minute. Data is cached for 12 hours anyway",
		adh_reset_pos = "Reset panel position",
		adh_reset_pos_tip = "Puts the panel back to the default side",
		adh_dump = "Draft screen snapshot",
		adh_dump_tip = "Open the draft screen first, then press. Sends the panel tree to the bridge log",
		adh_debug = "Debug log",
		adh_debug_tip = "Logs state changes and sends a snapshot whenever the draft screen changes",

		-- panel
		adh_title = "Ability Draft Helper",
		adh_loading = "Loading data %d/%d",
		adh_error = "Data error: %s",
		adh_retry = "Retry",
		adh_waiting = "Waiting for the draft",
		adh_waiting_count = "Recognized %d of %d abilities",
		adh_waiting_hint = "Recommendations appear as soon as the ability pool is on screen",
		adh_status = "Pool %d  ·  Mine %d/%d",
		adh_status_game = "Match build  ·  mine %d  ·  enemy %d",
		adh_tab_picks = "Picks",
		adh_tab_combos = "Combos",
		adh_tab_counters = "Counters",
		adh_rs_off = "Any",
		adh_rs_carry = "Carry",
		adh_rs_mid = "Mid",
		adh_rs_offlane = "Off",
		adh_rs_support = "Pos 4",
		adh_rs_hard_support = "Pos 5",
		adh_top = "Best picks",
		adh_op = "OP combos",
		adh_trap = "Traps",
		adh_tri = "Triplets",
		adh_counter = "Direct counters",
		adh_deny = "Deny picks",
		adh_none = "Nothing found",
		adh_ult = "ULT",
		adh_role_fit = "role fit",
		adh_role_avoid = "poor fit",
		adh_vs = "vs %s  ·  %s",
		adh_deny_sub = "blocks %s combo",
		adh_counter_channel = "interrupt channeling",
		adh_counter_mobility = "control mobility",
		adh_counter_cleanse = "dispel silence or root",
		adh_counter_heal = "prevent healing",
		adh_counter_break = "break passive",
		adh_skipped = "Skipped: %d",
		adh_restore = "Restore",
		adh_offline = "GitHub is unavailable, using saved data",
		adh_pairs_offline = "Pair sample counts are unavailable",
		adh_skip_tip = "Skip this ability (right click works too)",
		adh_unskip = "Skipped abilities are hidden from picks",

		-- tooltips
		adh_t_wr = "Win rate",
		adh_t_order = "Average pick order",
		adh_t_samples = "Samples",
		adh_t_score = "Score",
		adh_t_syn = "Best synergy",
		adh_t_role = "Role",
		adh_t_pair = "Pair win rate",
		adh_t_gain = "Gain over solo",
		adh_t_enemy = "Enemy ability",
		adh_t_reason = "Why",
		adh_t_hero = "Hero",
		adh_t_hint = "Click to pick in the draft, × or right click to skip",
		adh_t_model = "Hero model",
		adh_t_abilities = "Abilities",
		adh_t_delta = "Win rate change",
		adh_t_model_syn = "With your model",
		adh_t_timing = "Usually taken",
		adh_t_partner = "Pairs well with",
		adh_t_sink = "Skill points",
		adh_foes = "Enemy drafts",
		adh_t_foe = "Draft strength vs 50%",
		adh_t_foe_syn = "Synergy between picks",
		adh_t_hs = "High-skill win rate",
		adh_t_sink_v = "competes with %d of your picks",
		adh_t_rearm = "Rearm",
		adh_t_rearm_v = "refreshes this ability",
		adh_t_bad_partner = "Poor with",
		adh_t_timing_v = "pick #%.0f, now #%d",
		adh_wait = "can wait",
		adh_mc = "On your model",
		adh_models = "Hero models",
		adh_abilities = "Abilities",
		adh_hero_sub = "strong with %s",
		adh_hero_sub_none = "no strong abilities in the pool",
		adh_badge_top = "Top pick",
		adh_badge_syn = "Synergy pick",
		adh_badge_model = "Top model",
		adh_t_model_pick = "Hero model",
		adh_t_yours = "yours",
		adh_t_ag_sc = "Strong Aghanim's Scepter upgrade",
		adh_t_ag_sh = "Strong Aghanim's Shard upgrade",
		adh_t_soon = "Usually drafted by now, may not survive another round",
		adh_t_later = "Usually drafted later, can wait a round",
		adh_s_strong = "Strong synergies",
		adh_s_heroes = "Hero synergies",
		adh_s_weak = "Weak synergies",
		adh_s_weak_heroes = "Weak hero synergies",
		adh_s_strong_ab = "Strong abilities for this hero",
		adh_s_weak_ab = "Weak abilities for this hero",
		adh_mc_sub = "strong on %s",

		-- build
		adh_tab_build = "Build",
		adh_fit_good = "model",
		adh_fit_bad = "bad model",
		adh_fit_ranged = "Needs a ranged hero",
		adh_fit_melee = "Needs a melee hero",
		adh_fit_grants = "Gives a melee model attack range",
		adh_fit_attack = "Attack steroid on a fast attacker",
		adh_fit_mana = "Mana-hungry spell on an intelligence hero",
		adh_fit_tank = "Sustain on a strength hero",
		adh_fit_rc = "Attack steroid on a model with right-click talents",
		adh_fit_range = "Attack steroid on a long-range model",
		adh_fit_caster = "Spell on a model with caster talents",
		adh_fit_tanky = "Durability on a model with tank talents",
		adh_fit_team = "Team spell on a model with utility talents",
		adh_b_model_unknown = "Hero model is not detected yet",
		adh_b_aghs = "Aghanim's",
		adh_b_core = "Core",
		adh_b_early = "Early game",
		adh_b_late = "Late game",
		adh_g_init = "initiation and positioning",
		adh_i_sustain = "regeneration for a support without mana spells",
		adh_i_tempo = "lane and early tempo",
		adh_i_survive = "survive without an escape spell",
		adh_i_burst = "magic burst for your nukes",
		adh_i_hybrid = "spells and attacks together",
		adh_i_melee_int = "melee intelligence model",
		adh_i_lockdown = "lock down a target",
		adh_i_meta = "built with %s in %d%% of 7000+ games",
		adh_g_meta = "popular with your abilities",
		adh_t_meta = "7000+ builds",
		adh_b_counter = "Against enemies",
		adh_b_upgrades = "upgrades %s",
		adh_b_vs = "vs %s",
		adh_t_need = "Works with",
		adh_t_bought = "Usually bought",
		adh_t_pro = "%s  %d%%",
		adh_min = "%d min",
		adh_t_unlock = "Enables upgrade",
		adh_up_sc = "Scepter",
		adh_up_sh = "Shard",
		adh_b_melee = "Melee",
		adh_b_ranged = "Ranged",
		adh_attr_str = "Strength",
		adh_attr_agi = "Agility",
		adh_attr_int = "Intelligence",
		adh_attr_all = "Universal",
		adh_arch_carry = "Right-click carry",
		adh_arch_caster = "Caster",
		adh_arch_tank = "Tank initiator",
		adh_arch_support = "Support",
		adh_i_stats = "attack speed and stats",
		adh_i_chase = "chase and damage",
		adh_i_mana = "mana for spells",
		adh_i_farm = "faster farm",
		adh_f_slot = "FARM",
		adh_f_cleave = "attack cleave already farms, add attack speed",
		adh_f_dominate = "dominate a creep, empower summons",
		adh_f_offlane = "dominated creep for the offlane",
		adh_f_midas = "gold and levels without a farming spell",
		adh_f_mjollnir = "chain lightning clears waves",
		adh_f_radiance = "burns waves and camps on a durable body",
		adh_f_bfury = "cleave for fast farm",
		adh_i_initiate = "initiation",
		adh_i_channel = "channel without interruption",
		adh_i_bkb = "survive control in fights",
		adh_i_spell = "spell damage and cooldowns",
		adh_i_range = "cast range",
		adh_i_cd = "cooldowns and mana",
		adh_i_refresh = "double ultimate",
		adh_i_summon = "stronger summons",
		adh_i_save = "save allies",
		adh_i_position = "positioning and saves",
		adh_i_team = "team aura",
		adh_i_damage = "right-click damage",
		adh_i_range_atk = "attack range",
		adh_i_lifesteal = "lifesteal and status resistance",
		adh_i_kite = "slow and kite",
		adh_i_tank = "health pool",
		adh_ci_heal = "cut healing",
		adh_ci_break = "break passives",
		adh_ci_evasion = "pierce evasion",
		adh_ci_invis = "reveal invisibility",
		adh_ci_illusion = "clear illusions and summons",
		adh_ci_silence = "dispel silences and roots",
		adh_ci_cc = "lots of enemy control",
		adh_ci_magic = "lots of magic burst",
		adh_ci_mobility = "catch mobile heroes",
		adh_ci_physical = "lots of physical damage",
		adh_ci_saves = "dispel enemy saves",
		adh_ci_channel = "interrupt channels",
		adh_counter_invis = "reveal invisibility",
		adh_counter_illusion = "clear illusions",

		-- settings
		adh_s_title = "Panel settings",
		adh_s_theme = "Theme",
		adh_s_accent = "Accent",
		adh_s_opacity = "Opacity",
		adh_s_blur = "Background blur",
		adh_s_compact = "Compact rows",
		adh_s_icons = "Ability icons",
		adh_s_scale = "Scale",
		adh_s_text = "Text size",
		adh_s_shadow = "Text shadow",
		adh_s_reset = "Reset position",
		adh_s_hint = "Drag the header to move the panel, drag the corner to resize",
	},
	ru = {
		-- menu
		adh_group_main = "Помощник Ability Draft",
		adh_group_data = "Данные и инструменты",
		adh_enable = "Включить",
		adh_enable_tip = "Ранжирует обычные способности и ультимейты по статистике Ability Draft и синергии с уже выбранными способностями",
		adh_show = "Показывать панель",
		adh_show_tip = "Рисует панель с рекомендациями на экране драфта",
		adh_key = "Показать/скрыть панель",
		adh_key_tip = "Прячет и возвращает панель одной клавишей",
		adh_bind_name = "Панель Ability Draft Helper",
		adh_preview = "Показывать вне драфта",
		adh_preview_tip = "Держит панель на экране всегда, чтобы можно было расположить её и настроить внешний вид",
		adh_side = "Сторона по умолчанию",
		adh_side_tip = "Где появляется панель, пока ты её не передвинул. При смене сбрасывает сохранённую позицию",
		adh_side_left = "Слева",
		adh_side_right = "Справа",
		adh_role = "Роль для подбора",
		adh_role_tip = "Дополнительный подбор под роль: усиливает редкие недостающие функции сборки. В режиме «Не учитывать» базовый рейтинг не меняется",
		adh_role_off = "Не учитывать",
		adh_role_carry = "Керри",
		adh_role_mid = "Мид",
		adh_role_offlane = "Оффлейн",
		adh_role_support = "Саппорт 4",
		adh_role_hard_support = "Саппорт 5",
		adh_refresh = "Обновить данные",
		adh_refresh_tip = "Скачивает свежую статистику, не чаще раза в минуту. В любом случае данные кэшируются на 12 часов",
		adh_reset_pos = "Сбросить позицию панели",
		adh_reset_pos_tip = "Возвращает панель на сторону по умолчанию",
		adh_dump = "Снимок экрана драфта",
		adh_dump_tip = "Сначала открой экран драфта, потом нажми. Дерево панелей уйдёт в лог моста",
		adh_debug = "Отладочный лог",
		adh_debug_tip = "Пишет смену состояний в лог и отправляет снимок при каждом изменении экрана драфта",

		-- panel
		adh_title = "Ability Draft Helper",
		adh_loading = "Загрузка данных %d/%d",
		adh_error = "Ошибка данных: %s",
		adh_retry = "Повторить",
		adh_waiting = "Ждём драфт",
		adh_waiting_count = "Распознано способностей: %d из %d",
		adh_waiting_hint = "Рекомендации появятся, как только пул способностей окажется на экране",
		adh_status = "Пул %d  ·  Мои %d/%d",
		adh_status_game = "Билд на матч  ·  мои %d  ·  враги %d",
		adh_tab_picks = "Пики",
		adh_tab_combos = "Связки",
		adh_tab_counters = "Контры",
		adh_rs_off = "Любая",
		adh_rs_carry = "Керри",
		adh_rs_mid = "Мид",
		adh_rs_offlane = "Офф",
		adh_rs_support = "Поз. 4",
		adh_rs_hard_support = "Поз. 5",
		adh_top = "Лучшие пики",
		adh_op = "OP связки",
		adh_trap = "Ловушки",
		adh_tri = "Тройки",
		adh_counter = "Прямые контры",
		adh_deny = "Не отдавать связку",
		adh_none = "Ничего не найдено",
		adh_ult = "УЛЬТ",
		adh_role_fit = "под роль",
		adh_role_avoid = "не по роли",
		adh_vs = "против %s  ·  %s",
		adh_deny_sub = "ломает связку с %s",
		adh_counter_channel = "прервать канал",
		adh_counter_mobility = "поймать мобильного",
		adh_counter_cleanse = "снять сайленс или рут",
		adh_counter_heal = "запретить лечение",
		adh_counter_break = "сломать пассивку",
		adh_skipped = "Скрыто: %d",
		adh_restore = "Вернуть",
		adh_offline = "GitHub недоступен, используются сохранённые данные",
		adh_pairs_offline = "У связок неизвестно число выборок",
		adh_skip_tip = "Скрыть способность (работает и правый клик)",
		adh_unskip = "Скрытые способности не попадают в пики",

		-- tooltips
		adh_t_wr = "Винрейт",
		adh_t_order = "Средний порядок пика",
		adh_t_samples = "Выборка",
		adh_t_score = "Рейтинг",
		adh_t_syn = "Лучшая синергия",
		adh_t_role = "Роль",
		adh_t_pair = "Винрейт пары",
		adh_t_gain = "Прирост к одиночной",
		adh_t_enemy = "Способность врага",
		adh_t_reason = "Зачем",
		adh_t_hero = "Герой",
		adh_t_hint = "ЛКМ: выбрать в драфте, × или ПКМ: скрыть",
		adh_t_model = "Модель героя",
		adh_t_abilities = "Способности",
		adh_t_delta = "Изменение винрейта",
		adh_t_model_syn = "С твоей моделью",
		adh_t_timing = "Обычно берут",
		adh_t_partner = "Хорошо с",
		adh_t_sink = "Очки навыков",
		adh_foes = "Драфты врагов",
		adh_t_foe = "Сила драфта к 50%",
		adh_t_foe_syn = "Синергия между пиками",
		adh_t_hs = "Винрейт у сильных игроков",
		adh_t_sink_v = "делит уровни с %d твоими",
		adh_t_rearm = "Rearm",
		adh_t_rearm_v = "перезаряжает эту способность",
		adh_t_bad_partner = "Плохо с",
		adh_t_timing_v = "на пике #%.0f, сейчас #%d",
		adh_wait = "подождёт",
		adh_mc = "На твою модель",
		adh_models = "Модели героев",
		adh_abilities = "Способности",
		adh_hero_sub = "сильна с %s",
		adh_hero_sub_none = "нет сильных способностей в пуле",
		adh_badge_top = "Лучший пик",
		adh_badge_syn = "Пик под синергию",
		adh_badge_model = "Лучшая модель",
		adh_t_model_pick = "Модель героя",
		adh_t_yours = "твоя",
		adh_t_ag_sc = "Сильное улучшение от Аганима",
		adh_t_ag_sh = "Сильное улучшение от Шарда",
		adh_t_soon = "Обычно её уже забирают, до следующего круга может не дожить",
		adh_t_later = "Обычно берут позже, можно подождать круг",
		adh_s_strong = "Сильные синергии",
		adh_s_heroes = "С героями",
		adh_s_weak = "Слабые синергии",
		adh_s_weak_heroes = "Слабо с героями",
		adh_s_strong_ab = "Сильные способности для героя",
		adh_s_weak_ab = "Слабые способности для героя",
		adh_mc_sub = "сильна на %s",

		-- build
		adh_tab_build = "Билд",
		adh_fit_good = "модель",
		adh_fit_bad = "не та модель",
		adh_fit_ranged = "Нужен герой дальнего боя",
		adh_fit_melee = "Нужен герой ближнего боя",
		adh_fit_grants = "Даёт мили-модели дальнюю атаку",
		adh_fit_attack = "Усиление атаки на быстрой модели",
		adh_fit_mana = "Затратная по мане на герое интеллекта",
		adh_fit_tank = "Живучесть на силовом герое",
		adh_fit_rc = "Усиление атаки на модели с талантами на руку",
		adh_fit_range = "Усиление атаки на модели с большой дальностью",
		adh_fit_caster = "Заклинание на модели с талантами мага",
		adh_fit_tanky = "Живучесть на модели с талантами танка",
		adh_fit_team = "Командная способность на модели с талантами поддержки",
		adh_b_model_unknown = "Модель героя пока не определена",
		adh_b_aghs = "Аганим и Шард",
		adh_b_core = "Основа",
		adh_b_early = "Ранняя игра",
		adh_b_late = "Поздняя игра",
		adh_g_init = "инициация и позиционка",
		adh_i_sustain = "реген саппорту без затратных спеллов",
		adh_i_tempo = "лайн и ранний темп",
		adh_i_survive = "выжить без спелла на побег",
		adh_i_burst = "магический бурст под твои нюки",
		adh_i_hybrid = "спеллы и атака вместе",
		adh_i_melee_int = "мили-модель интеллекта",
		adh_i_lockdown = "держать цель",
		adh_i_meta = "с %s берут в %d%% игр 7000+",
		adh_g_meta = "популярно с твоими способностями",
		adh_t_meta = "Билды 7000+",
		adh_b_counter = "Против врагов",
		adh_b_upgrades = "улучшает %s",
		adh_b_vs = "против %s",
		adh_t_need = "Работает с",
		adh_t_bought = "Обычно покупают",
		adh_t_pro = "%s  %d%%",
		adh_min = "на %d мин",
		adh_t_unlock = "Включает апгрейд",
		adh_up_sc = "Аганим",
		adh_up_sh = "Шард",
		adh_b_melee = "Ближний бой",
		adh_b_ranged = "Дальний бой",
		adh_attr_str = "Сила",
		adh_attr_agi = "Ловкость",
		adh_attr_int = "Интеллект",
		adh_attr_all = "Универсал",
		adh_arch_carry = "Керри с руки",
		adh_arch_caster = "Маг",
		adh_arch_tank = "Танк-инициатор",
		adh_arch_support = "Саппорт",
		adh_i_stats = "скорость атаки и статы",
		adh_i_chase = "догонять и бить",
		adh_i_mana = "мана на заклинания",
		adh_i_farm = "быстрее фарм",
		adh_f_slot = "ФАРМ",
		adh_f_cleave = "сплеш с руки уже фармит, нужна скорость атаки",
		adh_f_dominate = "доминировать крипа, сильнее призванные",
		adh_f_offlane = "доминированный крип для оффлейна",
		adh_f_midas = "золото и опыт без фарм-скилла",
		adh_f_mjollnir = "цепная молния чистит пачки",
		adh_f_radiance = "жжёт пачки и лес на живучем теле",
		adh_f_bfury = "сплеш для быстрого фарма",
		adh_i_initiate = "инициация",
		adh_i_channel = "канал без прерываний",
		adh_i_bkb = "переживать контроль в драках",
		adh_i_spell = "урон заклинаний и кулдауны",
		adh_i_range = "дальность каста",
		adh_i_cd = "кулдауны и мана",
		adh_i_refresh = "двойной ульт",
		adh_i_summon = "сильнее призванные",
		adh_i_save = "спасать союзников",
		adh_i_position = "позиционка и сейвы",
		adh_i_team = "командная аура",
		adh_i_damage = "урон с руки",
		adh_i_range_atk = "дальность атаки",
		adh_i_lifesteal = "вампиризм и стойкость",
		adh_i_kite = "замедление и кайт",
		adh_i_tank = "запас здоровья",
		adh_ci_heal = "срезать лечение",
		adh_ci_break = "сломать пассивки",
		adh_ci_evasion = "пробить уклонение",
		adh_ci_invis = "раскрыть невидимость",
		adh_ci_illusion = "чистить иллюзии и призванных",
		adh_ci_silence = "снимать сайленсы и руты",
		adh_ci_cc = "у врагов много контроля",
		adh_ci_magic = "много магического урона",
		adh_ci_mobility = "ловить мобильных",
		adh_ci_physical = "много физического урона",
		adh_ci_saves = "снимать сейвы врага",
		adh_ci_channel = "прерывать каналы",
		adh_counter_invis = "раскрыть невидимость",
		adh_counter_illusion = "чистить иллюзии",

		-- settings
		adh_s_title = "Настройки панели",
		adh_s_theme = "Тема",
		adh_s_accent = "Акцент",
		adh_s_opacity = "Прозрачность",
		adh_s_blur = "Размытие фона",
		adh_s_compact = "Компактные строки",
		adh_s_icons = "Иконки способностей",
		adh_s_scale = "Масштаб",
		adh_s_text = "Размер текста",
		adh_s_shadow = "Тень текста",
		adh_s_reset = "Сбросить позицию",
		adh_s_hint = "Тяни за шапку, чтобы двигать панель, и за угол, чтобы менять размер",
	},
})

local UI = localization.WrapLibrary(Menu)
local L = localization.Get

local VERSION = "1.0.0"

local K = {
	TAG = "[AD Helper] ",
	DATA = "https://raw.githubusercontent.com/4uJIuH/umbrella-scripts/main/scripts/ability_draft_helper/data/",
	-- Steam account ids (the short profile number) allowed to run the helper, one per line
	USERS = "ad_users.txt",
	TTL = 43200,
	RETRY = 60,
	REFRESH_COOLDOWN = 60,
	TIMEOUT = 60,
	RETRY_MAX = 900,
	AGENT = "umbrella-ability-draft-helper/1.0",
	MIN_PICKS = 50,
	W_WR = 0.4,
	W_PICK = 0.6,
	PAIR_SCALE = 0.4,
	PAIR_CAP = 0.10,
	ROLE_NEED_WEIGHT = 0.05,
	ROLE_CURATED_BONUS = 0.08,
	ROLE_CAP = 0.10,
	OP = 0.05,
	TRAP = 0.05,
	TOP = 10,
	MAX_COUNTER = 6,
	MODEL_BAD = 0.06,
	MODEL_SYN_SCALE = 0.5,
	SOON = 10,
	LATE = 20,
	TIMING_BONUS = 0.01,
	SINK_PENALTY = 0.02,
	HS_SCALE = 0.3,
	HS_CAP = 0.02,
	REARM_BONUS = 0.03,
	MODEL_SYN_CAP = 0.05,
	MODEL_SYN_SHOW = 0.02,
	MODEL_COMBO = 0.04,
	MAX_MODEL_COMBO = 6,
	MODEL_GOOD = 0.03,
	MODEL_SOFT = 0.015,
	AGHS_GOOD = 0.015,
	TOP_MODELS = 4,
	AGHS_PRO = 0.3,
	UNLOCK_BONUS = 0.012,
	UPGRADES = "ad_ability_upgrades.json",
	SHRINK = { troll_warlord_berserkers_rage = true, lone_druid_true_form = true },
	MAX_CORE = 7,
	MAX_COUNTER_ITEMS = 6,
	HERO_META = "ad_hero_meta.json",
	ITEM_ICON = "panorama/images/items/%s_png.vtex_c",
	HERO_ICON = "panorama/images/heroes/icons/%s_png.vtex_c",
	MAX_DENY = 4,
	MAX_OP = 8,
	MAX_TRAP = 5,
	MAX_TRI = 4,
	MIN_POOL = 12,
	MINE_SHOW = 4,
	SLOTS = 4,
	SCAN_EVERY = 1,
	CARDS_TTL = 20,
	GAME_SCAN_EVERY = 3,
	TAG_JS = [[
(function () {
	const pre = $.GetContextPanel();
	const tag = img => {
		const name = img.abilityname || '';
		if (img.GetAttributeString('ability_name', '') !== name) img.SetAttributeString('ability_name', name);
	};
	for (const side of ['RadiantHeroes', 'DireHeroes']) {
		const team = pre.FindChildTraverse(side);
		if (team) team.FindChildrenWithClassTraverse('HeroAbility').forEach(tag);
	}
	for (const id of ['AbilityDraftAbilitiesHitbox', 'AbilityDraftUltimatesHitbox']) {
		const box = pre.FindChildTraverse(id);
		if (!box) continue;
		for (const card of box.FindChildrenWithClassTraverse('Ability')) {
			const img = card.GetChild(0);
			if (img) tag(img);
		}
	}
})();
]],
	PICK_JS = [[
(function () {
	const pre = $.GetContextPanel();
	const name = '%s';
	for (const id of ['AbilityDraftAbilitiesHitbox', 'AbilityDraftUltimatesHitbox']) {
		const box = pre.FindChildTraverse(id);
		if (!box) continue;
		for (const card of box.FindChildrenWithClassTraverse('Ability')) {
			if (card.BHasClass('AbilityChosen')) continue;
			const img = card.GetChild(0);
			if (!img || img.abilityname !== name) continue;
			$.DispatchEvent('Activated', card, 'mouse');
			$.Schedule(0.2, () => {
				if (card.IsValid() && !card.BHasClass('AbilityChosen') && img.IsValid()) $.DispatchEvent('Activated', img, 'mouse');
			});
			return;
		}
	}
})();
]],
	MAX_NODES = 4000,
	MAX_DEPTH = 16,
	DUMP_LINES = 8000,
	DUMP_SKIP = { HeroGrid = true, StrategyScreen = true, HeroPickLeftColumn = true },
	PARSE_SLICE = 0.004,
	META = "ad_meta.txt",
	TAGS = "ad_ability_tags.json",
	TREE = "ability_draft_tree.txt",
	PANELS = {
		POOL = "AbilityDraftAbilitiesHitbox",
		ULT_POOL = "AbilityDraftUltimatesHitbox",
		RADIANT = "RadiantHeroes",
		DIRE = "DireHeroes",
		NAME = "PlayerName",
		ABILITIES = "HeroAbilityContainer",
		IMAGE = "AbilityImage",
	},
	-- every file comes from K.DATA; "raw" files are only saved, their loaders read them after the last job
	JOBS = {
		{ key = "sabil", file = "ad_static_abilities.json" },
		{ key = "shero", file = "ad_static_heroes.json" },
		{ key = "stats", file = "ad_abilities.json" },
		{ key = "pairs", file = "ad_ability_pairs.json" },
		{ key = "tri", file = "ad_ability_triplets.json" },
		{ key = "mpair", file = "ad_model_pairs.json" },
		{ key = "mtri", file = "ad_model_triplets.json" },
		{ key = "hs", file = "ad_ability_hs.json" },
		{ key = "hbuild", file = "ad_hero_builds.json" },
		{ key = "mstat", file = "ad_model_stats.json" },
		{ key = "tags", file = "ad_ability_tags.json", raw = true },
		{ key = "upg", file = "ad_ability_upgrades.json", raw = true },
		{ key = "hmeta", file = "ad_hero_meta.json", raw = true },
	},
}

local COUNTER_RULES = {
	{
		label = "adh_counter_channel",
		enemies = {
			enigma_black_hole = true, bane_fiends_grip = true, shadow_shaman_shackles = true,
			witch_doctor_death_ward = true, crystal_maiden_freezing_field = true, pudge_dismember = true,
		},
		picks = {
			lion_impale = true, lion_voodoo = true, shadow_shaman_voodoo = true,
			shadow_shaman_shackles = true, silencer_global_silence = true, axe_berserkers_call = true,
			earthshaker_fissure = true, sven_storm_bolt = true, centaur_hoof_stomp = true,
			tidehunter_ravage = true, disruptor_static_storm = true, riki_smoke_screen = true,
			slardar_slithereen_crush = true,
		},
	},
	{
		label = "adh_counter_cleanse",
		enemies = {
			silencer_last_word = true, silencer_global_silence = true, skywrath_mage_ancient_seal = true,
			drow_ranger_wave_of_silence = true, crystal_maiden_frostbite = true,
			ember_spirit_searing_chains = true, dark_willow_bramble_maze = true,
			naga_siren_ensnare = true, treant_overgrowth = true, abyssal_underlord_pit_of_malice = true,
		},
		picks = {
			abaddon_aphotic_shield = true, legion_commander_press_the_attack = true,
			oracle_fortunes_end = true, slark_dark_pact = true, life_stealer_rage = true,
			juggernaut_blade_fury = true,
		},
	},
	{
		label = "adh_counter_heal",
		enemies = {
			omniknight_purification = true, witch_doctor_voodoo_restoration = true,
			oracle_purifying_flames = true, necrolyte_death_pulse = true, dazzle_shadow_wave = true,
			phoenix_sun_ray = true, chen_hand_of_god = true, warlock_shadow_word = true,
			wisp_tether = true,
		},
		picks = { ancient_apparition_ice_blast = true },
	},
	{
		label = "adh_counter_break",
		enemies = {
			bristleback_bristleback = true, spectre_dispersion = true, faceless_void_time_lock = true,
			ursa_fury_swipes = true, phantom_assassin_coup_de_grace = true,
			drow_ranger_marksmanship = true, medusa_mana_shield = true, abaddon_borrowed_time = true,
		},
		picks = { viper_viper_strike = true },
	},
	{
		label = "adh_counter_mobility",
		enemies = {
			antimage_blink = true, queenofpain_blink = true, storm_spirit_ball_lightning = true,
			faceless_void_time_walk = true, weaver_shukuchi = true, slark_pounce = true,
			puck_illusory_orb = true,
		},
		picks = {
			naga_siren_ensnare = true, meepo_earthbind = true, dark_willow_bramble_maze = true,
			crystal_maiden_frostbite = true, treant_overgrowth = true,
			abyssal_underlord_pit_of_malice = true, grimstroke_ink_creature = true,
			slardar_slithereen_crush = true, lion_impale = true, earthshaker_fissure = true,
			axe_berserkers_call = true,
		},
	},
	{
		label = "adh_counter_invis",
		enemies = {
			riki_permanent_invisibility = true, riki_backstab = true, bounty_hunter_wind_walk = true,
			clinkz_wind_walk = true, weaver_shukuchi = true, nyx_assassin_vendetta = true,
			mirana_invis = true, invoker_ghost_walk = true, treant_natures_guise = true,
		},
		picks = { slardar_amplify_damage = true, bounty_hunter_track = true, zuus_lightning_bolt = true },
	},
	{
		label = "adh_counter_illusion",
		enemies = {
			phantom_lancer_juxtapose = true, phantom_lancer_doppelwalk = true, naga_siren_mirror_image = true,
			terrorblade_conjure_image = true, chaos_knight_phantasm = true,
		},
		picks = {},
		tags = { "aoe", "waveclear" },
	},
}

local RULE = {}
for _, rule in ipairs(COUNTER_RULES) do RULE[rule.label] = rule.enemies end

local ARCH_ORDER = { "carry", "caster", "tank", "support" }

local B = {
	arch = {
		carry = { steroid = 1.0, farm_tool = 0.8, passive_value = 0.5, mobility = 0.3, sustain_self = 0.3 },
		caster = { nuke = 1.0, teamfight_ult = 0.6, mana_hungry = 0.3, aoe = 0.3, setup_cc = 0.3, waveclear = 0.3 },
		tank = { initiation = 0.5, sustain_self = 0.7, hard_cc = 0.4, passive_value = 0.2, teamfight_ult = 0.3 },
		support = { save_ally = 1.0, team_aura = 0.8, soft_cc = 0.4, hard_cc = 0.4, setup_cc = 0.4 },
	},
	attr = { agi = "carry", int = "caster", str = "tank" },
	hero_tag = {
		rc_talents = "carry", innate_offense = "carry", caster_talents = "caster",
		tank_talents = "tank", innate_tank = "tank", utility_talents = "support", innate_team = "support",
	},
	role = {
		[1] = { carry = 1.0 },
		[2] = { caster = 0.7, carry = 0.4 },
		[3] = { tank = 1.0 },
		[4] = { support = 0.7, caster = 0.4 },
		[5] = { support = 1.2 },
	},
	items = {
		{ "item_power_treads", 1400, "boots", { carry = 1, caster = 0.3 }, function(c)
			return (c.attr == "agi" or not c.melee) and 0.3 or 0, "adh_i_stats"
		end },
		{ "item_phase_boots", 1450, "boots", { carry = 0.8, tank = 0.8 }, function(c)
			return c.melee and 0.35 or -0.3, "adh_i_chase"
		end },
		{ "item_arcane_boots", 1500, "boots", { caster = 0.9, support = 0.8, tank = 0.3 }, function(c)
			return 0.12 * math.min(3, c.n.mana_hungry), "adh_i_mana", c.has.mana_hungry
		end },
		{ "item_tranquil_boots", 900, "boots", { support = 0.6, tank = 0.3 }, function(c)
			return c.n.mana_hungry == 0 and 0.3 or -0.2, "adh_i_sustain"
		end },
		{ "item_soul_ring", 805, "lane", { tank = 0.5, carry = 0.3 }, function(c)
			return (c.n.mana_hungry > 0 and c.attr == "str") and 0.35 or -0.2, "adh_i_mana", c.has.mana_hungry
		end },
		{ "item_falcon_blade", 1125, "lane", { carry = 0.45, caster = 0.35 }, function(c)
			return c.role == 2 and 0.2 or 0, "adh_i_tempo"
		end },
		{ "item_orb_of_corrosion", 1050, "lane", { tank = 0.45, carry = 0.3 }, function(c)
			return c.melee and 0.15 or -0.3, "adh_i_tempo"
		end },
		{ "item_urn_of_shadows", 825, "lane", { support = 0.45 }, function(c)
			return c.role == 4 and 0.25 or 0, "adh_i_tempo"
		end },
		{ "item_vanguard", 1700, "lane", { tank = 0.55 }, function(c)
			if not c.melee then return -0.3, "adh_i_tank" end
			return c.has.sustain_self and 0.25 or 0, "adh_i_tank", c.has.sustain_self
		end },
		{ "item_pavise", 1350, "save", { support = 0.5 }, function(c)
			return c.has.save_ally and 0.1 or 0, "adh_i_save", c.has.save_ally
		end },
		{ "item_mekansm", 1775, "aura", { support = 0.45, tank = 0.3 }, function(c)
			return c.role == 5 and 0.25 or 0, "adh_i_team"
		end },
		{ "item_blink", 2250, "init", { tank = 0.8, caster = 0.3, support = 0.3, carry = 0.15 }, function(c)
			local id = c.has.initiation
			local b = id and 0.5 or 0
			if c.has.hard_cc and c.has.aoe then b = b + 0.15 end
			if not id and c.escape then b = b - 0.4 end
			return b, id and "adh_i_initiate" or "adh_g_init", id
		end },
		{ "item_black_king_bar", 4050, "immune", { carry = 0.85, tank = 0.45, caster = 0.3 }, function(c)
			local b, r, id = 0, "adh_i_bkb", nil
			if c.has.channeled then b, r, id = 0.6, "adh_i_channel", c.has.channeled end
			if not c.escape and c.melee then b = b + 0.15 end
			if c.en.hard_cc >= 2 then
				b = b + 0.2
				if r == "adh_i_bkb" then r = "adh_ci_cc" end
			end
			return b, r, id
		end },
		{ "item_glimmer_cape", 2150, "save", { support = 0.9, caster = 0.25 }, function(c)
			return c.has.save_ally and 0.1 or 0, "adh_i_save"
		end },
		{ "item_force_staff", 2200, "save", { support = 0.75, caster = 0.35, carry = 0.15 }, function(c)
			return not c.escape and 0.2 or 0, "adh_i_position"
		end },
		{ "item_ghost", 1500, "save", { support = 0.45, caster = 0.35 }, function(c)
			if c.en.steroid >= 2 then return 0.3, "adh_ci_physical" end
			return 0, "adh_i_survive"
		end },
		{ "item_cyclone", 2600, "save", { caster = 0.55, support = 0.35 }, function(c)
			return (not c.escape and 0.2 or 0) + (c.n.mana_hungry > 0 and 0.1 or 0), "adh_i_survive"
		end },
		{ "item_lotus_orb", 3850, "save", { tank = 0.55, support = 0.35 }, function(c)
			return c.en.hard_cc >= 2 and 0.2 or 0, "adh_ci_silence"
		end },
		{ "item_solar_crest", 2575, "save", { support = 0.6 }, function(c)
			return c.en.steroid >= 1 and 0.1 or 0, "adh_i_save"
		end },
		{ "item_aeon_disk", 3000, "save", { caster = 0.4, carry = 0.3 }, function(c)
			return not c.escape and 0.25 or -0.1, "adh_i_survive"
		end },
		{ "item_wind_waker", 6800, "save", { caster = 0.45, support = 0.3 }, function(c)
			return not c.escape and 0.15 or 0, "adh_i_survive"
		end },
		{ "item_hurricane_pike", 4450, "save", { carry = 0.6, caster = 0.2 }, function(c)
			return c.melee and -1 or 0.3, "adh_i_kite"
		end },
		{ "item_dragon_lance", 1900, "range", { carry = 0.7 }, function(c)
			return c.melee and -1 or 0.25, "adh_i_range_atk"
		end },
		{ "item_kaya", 2100, "spell", { caster = 1 }, function(c)
			return (c.melee and -0.3 or 0.1) + 0.15 * math.min(2, c.n.nuke), "adh_i_spell", c.has.nuke
		end },
		{ "item_kaya_and_sange", 4200, "spell", { caster = 0.7, tank = 0.4 }, function(c)
			return (c.melee and 0.3 or -0.2) + 0.1 * math.min(2, c.n.nuke), "adh_i_spell", c.has.nuke
		end },
		{ "item_ethereal_blade", 5200, "spell", { caster = 0.6 }, function(c)
			return c.n.nuke >= 2 and 0.35 or -0.2, "adh_i_burst", c.has.nuke
		end },
		{ "item_revenants_brooch", 3300, "spell", { caster = 0.35, carry = 0.3 }, function(c)
			return (c.has.steroid and c.attr == "int") and 0.45 or -0.2, "adh_i_hybrid", c.has.steroid
		end },
		{ "item_witch_blade", 2775, "spell", { caster = 0.35, carry = 0.25 }, function(c)
			return (c.attr == "int" and not c.melee) and 0.3 or -0.2, "adh_i_hybrid"
		end },
		{ "item_angels_demise", 5600, "spell", { caster = 0.45, carry = 0.3 }, function(c)
			return (c.has.nuke and c.has.steroid) and 0.35 or 0, "adh_i_hybrid", c.has.nuke
		end },
		{ "item_devastator", 5975, "spell", { caster = 0.35, carry = 0.2 }, function(c)
			return (c.attr == "int" and c.has.steroid) and 0.45 or -0.2, "adh_i_hybrid", c.has.steroid
		end },
		{ "item_aether_lens", 2275, "spell", { caster = 0.45, support = 0.55 }, function(c)
			local id = c.has.setup_cc or c.has.nuke or c.has.hard_cc
			return id and 0.2 or -0.1, "adh_i_range", id
		end },
		{ "item_harpoon", 4700, "spell", { carry = 0.35, caster = 0.35 }, function(c)
			return (c.melee and c.attr == "int") and 0.45 or -0.3, "adh_i_melee_int"
		end },
		{ "item_octarine_core", 4900, "cd", { caster = 0.7, tank = 0.3 }, function(c)
			return c.n.mana_hungry >= 2 and 0.3 or 0, "adh_i_cd", c.has.mana_hungry
		end },
		{ "item_bloodstone", 4700, "cd", { caster = 0.4, tank = 0.35 }, function(c)
			return (c.n.mana_hungry >= 1 and c.has.sustain_self) and 0.3 or -0.1, "adh_i_cd", c.has.mana_hungry
		end },
		{ "item_refresher", 5000, "refresh", { caster = 0.45, tank = 0.45 }, function(c)
			return c.has.teamfight_ult and 0.5 or -1, "adh_i_refresh", c.has.teamfight_ult
		end },
		{ "item_crimson_guard", 3725, "aura", { tank = 0.8 }, function(c)
			if c.en.steroid >= 2 then return 0.3, "adh_ci_physical" end
			return 0, "adh_i_team"
		end },
		{ "item_pipe", 3725, "aura", { tank = 0.7, support = 0.3 }, function(c)
			if c.en.nuke >= 3 then return 0.4, "adh_ci_magic" end
			return -0.1, "adh_i_team"
		end },
		{ "item_vladmir", 2200, "aura", { tank = 0.4, support = 0.4 }, function(c)
			return (c.has.summon and 0.5 or 0) + (c.has.team_aura and 0.15 or 0),
				c.has.summon and "adh_i_summon" or "adh_i_team", c.has.summon
		end },
		{ "item_assault", 5125, "aura", { tank = 0.45, carry = 0.45 }, function(c)
			return (c.has.team_aura and 0.15 or 0) + (c.melee and 0.1 or 0), "adh_i_team"
		end },
		{ "item_guardian_greaves", 4450, "aura", { support = 0.65, tank = 0.35 }, function(c)
			local id = c.has.team_aura or c.has.save_ally
			return id and 0.2 or 0, "adh_i_team", id
		end },
		{ "item_helm_of_the_overlord", 5650, "summon", { tank = 0.35, support = 0.25 }, function(c)
			return c.has.summon and 0.55 or -1, "adh_i_summon", c.has.summon
		end },
		{ "item_spirit_vessel", 2725, "vessel", { support = 0.45, tank = 0.35 }, function(c)
			if c.en.sustain_self >= 2 then return 0.3, "adh_ci_heal" end
			return 0, "adh_i_tempo"
		end },
		{ "item_heart", 5100, "tank", { tank = 0.9, carry = 0.2 }, function(c)
			return (c.attr == "str" and 0.3 or 0) + (c.has.sustain_self and 0.1 or 0), "adh_i_tank", c.has.sustain_self
		end },
		{ "item_blade_mail", 2400, "tank", { tank = 0.6 }, function(c)
			return (c.has.initiation and 0.1 or 0) + (c.en.steroid >= 2 and 0.25 or 0), "adh_i_tank", c.has.initiation
		end },
		{ "item_heavens_halberd", 3400, "tank", { tank = 0.45, carry = 0.3 }, function(c)
			return ((c.melee and c.attr == "str") and 0.2 or 0) + (c.en.steroid >= 2 and 0.2 or 0), "adh_i_tank"
		end },
		{ "item_shivas_guard", 4500, "tank", { tank = 0.6, caster = 0.4 }, function(c)
			if c.en.sustain_self >= 2 then return 0.3, "adh_ci_heal" end
			return c.has.aoe and 0.1 or 0, "adh_i_team"
		end },
		{ "item_desolator", 3500, "dmg", { carry = 0.8 }, function(c)
			return (c.melee and 0.2 or 0) + (c.has.steroid and 0.15 or 0), "adh_i_damage", c.has.steroid
		end },
		{ "item_sange_and_yasha", 4200, "dmg", { carry = 0.7 }, function(c)
			return c.melee and 0.2 or -0.2, "adh_i_stats"
		end },
		{ "item_echo_sabre", 2700, "dmg", { carry = 0.35, tank = 0.35 }, function(c)
			return (c.melee and c.attr == "str") and 0.3 or -0.3, "adh_i_damage"
		end },
		{ "item_diffusal_blade", 2500, "dmg", { carry = 0.5 }, function(c)
			return (c.melee and c.attr == "agi") and 0.3 or -0.2, "adh_i_damage"
		end },
		{ "item_greater_crit", 5100, "dmg", { carry = 0.9 }, function(c)
			return c.has.steroid and 0.15 or 0, "adh_i_damage", c.has.steroid
		end },
		{ "item_satanic", 5050, "dmg", { carry = 0.75 }, function(c)
			return (c.melee and 0.25 or -0.1) + (c.attr == "str" and 0.1 or 0), "adh_i_lifesteal"
		end },
		{ "item_skadi", 5900, "dmg", { carry = 0.65, tank = 0.25 }, function(c)
			return c.melee and 0 or 0.3, "adh_i_kite"
		end },
		{ "item_butterfly", 5450, "dmg", { carry = 0.75 }, function(c)
			return c.attr == "agi" and 0.3 or 0, "adh_i_damage"
		end },
		{ "item_bloodthorn", 6400, "dmg", { carry = 0.45, caster = 0.25 }, function(c)
			return c.melee and 0 or 0.2, "adh_i_lockdown"
		end },
		{ "item_manta", 4650, "dmg", { carry = 0.75 }, function(c)
			return (c.attr == "agi" and 0.25 or 0) + (c.en.hard_cc >= 2 and 0.1 or 0), "adh_i_stats"
		end },
		{ "item_disperser", 6100, "dmg", { carry = 0.45 }, function(c)
			return c.attr == "agi" and 0.2 or 0, "adh_i_damage"
		end },
		{ "item_moon_shard", 4000, "dmg", { carry = 0.55 }, function(c)
			return c.has.steroid and 0.15 or 0, "adh_i_damage", c.has.steroid
		end },
		{ "item_silver_edge", 5700, "dmg", { carry = 0.45 }, function(c)
			if c.en.passive_value >= 2 then return 0.35, "adh_ci_break" end
			return 0, "adh_i_damage"
		end },
		{ "item_monkey_king_bar", 5000, "dmg", { carry = 0.35 }, function(c)
			if c.en.evasion > 0 then return 0.6, "adh_ci_evasion" end
			return -0.1, "adh_i_damage"
		end },
		{ "item_abyssal_blade", 6250, "control", { carry = 0.5, tank = 0.45 }, function(c)
			return c.melee and 0.25 or -1, "adh_i_lockdown"
		end },
		{ "item_sheepstick", 5200, "control", { caster = 0.75, support = 0.35 }, function(c)
			return not c.has.hard_cc and 0.2 or 0, "adh_i_lockdown"
		end },
		{ "item_rod_of_atos", 2250, "control", { support = 0.5, caster = 0.3 }, function(c)
			return not c.has.hard_cc and 0.25 or 0, "adh_i_lockdown"
		end },
		{ "item_orchid", 3275, "control", { caster = 0.35, carry = 0.3 }, function(c)
			if c.en.mobility >= 2 then return 0.25, "adh_ci_mobility" end
			return 0, "adh_i_lockdown"
		end },
	},
	limit = {
		meta = 2, boots = 1, lane = 1, init = 1, immune = 1, save = 2, range = 1, spell = 2, cd = 1, refresh = 1,
		aura = 2, summon = 1, vessel = 1, tank = 2, dmg = 3, control = 1,
	},
	stage_cap = { early = 3, core = 4, late = 3 },
	farm_cost = {
		item_mask_of_madness = 1900, item_hand_of_midas = 2200, item_helm_of_the_dominator = 2550,
		item_bfury = 3900, item_radiance = 4700, item_mjollnir = 5500,
	},
	evasion = { phantom_assassin_blur = true, windrunner_windrun = true, brewmaster_drunken_brawler = true },
	closer = {
		antimage_blink = true, queenofpain_blink = true, phantom_assassin_phantom_strike = true, riki_blink_strike = true,
		faceless_void_time_walk = true, void_spirit_astral_step = true, void_spirit_dissimilate = true,
		storm_spirit_ball_lightning = true, ember_spirit_fire_remnant = true, ember_spirit_sleight_of_fist = true,
		morphling_waveform = true, slark_pounce = true, mirana_leap = true, magnataur_skewer = true,
		earth_spirit_rolling_boulder = true, sandking_burrowstrike = true, puck_illusory_orb = true,
		pangolier_swashbuckle = true, spirit_breaker_charge_of_darkness = true, shredder_timber_chain = true,
		rattletrap_hookshot = true, tusk_snowball = true, marci_companion_run = true, kez_grappling_claw = true,
		kez_falcon_rush_ad = true, monkey_king_tree_dance = true, huskar_life_break = true, phoenix_icarus_dive = true,
		primal_beast_onslaught = true, zuus_heavenly_jump = true, dawnbreaker_celestial_hammer = true,
		vengefulspirit_nether_swap = true, chaos_knight_reality_rift = true, techies_suicide = true,
		snapfire_firesnap_cookie = true,
	},
	blinks = { item_blink = true, item_overwhelming_blink = true, item_swift_blink = true, item_arcane_blink = true },
	THRESHOLD = 0.5,
	SCALE = 1.6,
	META_W = 0.9,
	META_MIN = 0.35,
	META_SHOW = 0.15,
	META_STAGE = 0.15,
	cleave = { sven_great_cleave = true, luna_moon_glaive = true, kunkka_tidebringer = true, magnataur_empower = true },
	multishot = { medusa_split_shot = true, gyrocopter_flak_cannon = true },
	boots = { item_power_treads = true, item_phase_boots = true, item_arcane_boots = true },
	counter = {
		{ reason = "adh_ci_cc", tag = "hard_cc", min = 3,
			pick = { carry = "item_black_king_bar", tank = "item_black_king_bar", caster = "item_black_king_bar", support = "item_glimmer_cape" } },
		{ reason = "adh_ci_heal", set = RULE.adh_counter_heal, tag = "sustain_self", min = 3,
			pick = { carry = "item_skadi", caster = "item_shivas_guard", tank = "item_shivas_guard", support = "item_spirit_vessel" } },
		{ reason = "adh_ci_break", set = RULE.adh_counter_break, tag = "passive_value", min = 3,
			pick = { carry = "item_silver_edge", tank = "item_silver_edge", caster = "item_silver_edge" } },
		{ reason = "adh_ci_evasion",
			set = { phantom_assassin_blur = true, windrunner_windrun = true, brewmaster_drunken_brawler = true },
			pick = { carry = "item_monkey_king_bar", tank = "item_monkey_king_bar" } },
		{ reason = "adh_ci_invis", set = RULE.adh_counter_invis,
			pick = { carry = "item_dust", caster = "item_dust", tank = "item_dust", support = "item_ward_sentry" } },
		{ reason = "adh_ci_illusion", set = RULE.adh_counter_illusion, tag = "summon", min = 1,
			pick = { carry = "item_mjollnir", caster = "item_shivas_guard", tank = "item_shivas_guard" } },
		{ reason = "adh_ci_silence", set = RULE.adh_counter_cleanse,
			pick = { carry = "item_manta", tank = "item_lotus_orb", caster = "item_cyclone", support = "item_lotus_orb" } },
		{ reason = "adh_ci_magic", tag = "nuke", min = 4,
			pick = { carry = "item_black_king_bar", tank = "item_pipe", caster = "item_black_king_bar", support = "item_glimmer_cape" } },
		{ reason = "adh_ci_mobility", set = RULE.adh_counter_mobility, tag = "mobility", min = 3,
			pick = { carry = { "item_abyssal_blade", "item_bloodthorn" }, tank = { "item_abyssal_blade", "item_sheepstick" },
				caster = "item_sheepstick", support = "item_rod_of_atos" } },
		{ reason = "adh_ci_physical", tag = "steroid", min = 3,
			pick = { carry = "item_butterfly", tank = "item_blade_mail", caster = "item_ghost", support = "item_ghost" } },
		{ reason = "adh_ci_saves", tag = "save_ally", min = 2,
			pick = { carry = "item_nullifier", caster = "item_nullifier" } },
		{ reason = "adh_ci_channel", set = RULE.adh_counter_channel, tag = "channeled", min = 1,
			pick = { carry = { "item_abyssal_blade", "item_orchid" }, caster = "item_cyclone", support = "item_cyclone" } },
	},
}

local S = { loaded = false, skipped = {}, skip_n = 0 }
local ui = {}

local D = {
	i = 0, job = nil, ready = false, wait = 0, cool = 0, err = nil, meta = nil,
	abil = {}, short = {}, hero = {}, stat = {}, pair = {}, tri = {}, aghs = {}, model_meta = {}, mpair = {}, mtri = {}, hs = {}, hbuild = {}, mstat = {},
	tags = {}, role_must = {}, role_avoid = {}, requires = {}, tags_loaded = false, tag_error = nil,
	upg = {}, upg_loaded = false,
	cache_fallback = false, pair_cache_fallback = false,
}

local R = { top = {}, op = {}, trap = {}, tri = {}, counter = {}, deny = {}, build = {} }
local reader = { next = 0, visible = false, active = false, pool = {}, mine = {}, enemy = {}, total = 0, sig = "", how = "", model = 0, phase = "none" }
local dump_tree
local V = { fonts = {}, lines = {}, dirty = true, next = 0, sc = 0 }

local function say(text)
	if S.loaded and ai_bridge and ai_bridge.mcp_log then
		ai_bridge.mcp_log("info", K.TAG .. text, nil)
	end
end

local function dbg(text)
	if ui.debug and ui.debug:Get() then say(text) end
end

local function configs_path(name)
	local dir = Engine.GetCheatDirectory()
	if not dir:match("[\\/]$") then dir = dir .. "\\" end
	return dir .. "configs\\" .. name
end

local function read_file(name)
	local file = io.open(configs_path(name), "rb")
	if not file then return nil end
	local text = file:read("a")
	file:close()
	return text
end

local function write_file(name, text)
	local file = io.open(configs_path(name), "wb")
	if not file then return false end
	file:write(text)
	file:close()
	return true
end

local function clamp(v, a, b) return v < a and a or (v > b and b or v) end

local FIELD, SFIELD = {}, {}

local function field(obj, key)
	local p = FIELD[key]
	if not p then
		p = '"' .. key .. '"%s*:%s*(-?[%d%.eE%+%-]+)'
		FIELD[key] = p
	end
	return tonumber(obj:match(p))
end

local function sfield(obj, key)
	local p = SFIELD[key]
	if not p then
		p = '"' .. key .. '"%s*:%s*"([^"]*)"'
		SFIELD[key] = p
	end
	return obj:match(p)
end

local function rate(v)
	if v and v > 1.5 then return v / 100 end
	return v
end

local function link(tbl, a, b, wr)
	local t = tbl[a]
	if not t then
		t = {}
		tbl[a] = t
	end
	t[b] = wr
end

local HANDLE = {}

function HANDLE.sabil(o)
	local id = field(o, "valveId")
	local short = sfield(o, "shortName")
	if not id or not short then return false end
	D.abil[id] = {
		id = id,
		name = sfield(o, "englishName") or short,
		short = short,
		owner = field(o, "ownerHeroId"),
		ult = o:find('"isUltimate"%s*:%s*true') ~= nil,
	}
	D.short[short] = id
	return true
end

function HANDLE.shero(o)
	local id = field(o, "id")
	local short = sfield(o, "shortName")
	if not id or not short then return false end
	D.hero[id] = { id = id, name = sfield(o, "englishName") or short, short = short }
	return true
end

function HANDLE.stats(o)
	local id = field(o, "abilityId")
	local wr = rate(field(o, "winrate"))
	if not id or not wr then return false end
	D.stat[id] = { wr = wr, pick = field(o, "avgPickPosition"), n = field(o, "numPicks") }
	return true
end

function HANDLE.pairs(o)
	local a, b = field(o, "abilityIdOne"), field(o, "abilityIdTwo")
	local wr = rate(field(o, "winrate"))
	if not a or not b or not wr then return false end
	local picks = field(o, "numPicks")
	if picks and picks < K.MIN_PICKS then return true end
	link(D.pair, a, b, wr)
	link(D.pair, b, a, wr)
	return true
end

function HANDLE.mpair(o)
	local h, id, inc = field(o, "h"), D.short[sfield(o, "a") or ""], field(o, "inc")
	if not h or not id or not inc then return false end
	D.mpair[h] = D.mpair[h] or {}
	D.mpair[h][id] = { wr = field(o, "wr"), inc = inc }
	return true
end

function HANDLE.mtri(o)
	local h, a, b = field(o, "h"), D.short[sfield(o, "a") or ""], D.short[sfield(o, "b") or ""]
	local inc = field(o, "inc")
	if not h or not a or not b or not inc then return false end
	if (field(o, "n") or 0) < K.MIN_PICKS then return true end
	local by = D.mtri[h]
	if not by then
		by = {}
		D.mtri[h] = by
	end
	by[a] = by[a] or {}
	by[b] = by[b] or {}
	by[a][#by[a] + 1] = { b = b, inc = inc, wr = field(o, "wr") }
	by[b][#by[b] + 1] = { b = a, inc = inc, wr = field(o, "wr") }
	return true
end

function HANDLE.hbuild(o)
	local h, list = sfield(o, "h"), sfield(o, "i")
	if not h or not list then return false end
	local key = h:lower():gsub("[^a-z]", "")
	if key == "zuus" then key = "zeus" end
	local items = {}
	for name, pr, mn, wr in list:gmatch("([%w_]+):([%d.]+):([%d.]+):([%d.]+)") do
		items["item_" .. name] = { pr = tonumber(pr), min = tonumber(mn), wr = tonumber(wr) }
	end
	D.hbuild[key] = { pos = field(o, "p"), items = items }
	return true
end

function HANDLE.mstat(o)
	local h, n, wr = field(o, "h"), sfield(o, "n"), field(o, "wr")
	if not h or not n or not wr then return false end
	local key = n:lower():gsub("[^a-z]", "")
	if key == "zuus" then key = "zeus" end
	D.mstat[key] = { h = math.tointeger(h) or h, wr = wr, hs = field(o, "hs"), pr = field(o, "pr") }
	return true
end

function HANDLE.hs(o)
	local id, v = D.short[sfield(o, "a") or ""], rate(field(o, "hs"))
	if not id or not v then return false end
	D.hs[id] = v
	return true
end

function HANDLE.tri(o)
	local a, b, c = field(o, "abilityIdOne"), field(o, "abilityIdTwo"), field(o, "abilityIdThree")
	local wr = rate(field(o, "winrate"))
	if not a or not b or not c or not wr then return false end
	if (field(o, "numPicks") or 0) < K.MIN_PICKS then return true end
	local entry = { a, b, c, wr }
	for i = 1, 3 do
		local list = D.tri[entry[i]]
		if not list then
			list = {}
			D.tri[entry[i]] = list
		end
		list[#list + 1] = entry
	end
	return true
end

local engine = {}
local data = {}
local load_ability_tags

local function load_meta()
	local meta = {}
	local text = read_file(K.META)
	if text then
		for key, ts in text:gmatch("(%w+)=(%d+)") do meta[key] = tonumber(ts) end
	end
	return meta
end

local function save_meta(meta)
	local parts = {}
	for key, ts in pairs(meta) do parts[#parts + 1] = key .. "=" .. ts end
	table.sort(parts)
	if not write_file(K.META, table.concat(parts, "\n")) then
		say("failed to save cache freshness metadata")
	end
end

local function begin_parse(job, text)
	if job.def.raw then
		job.state, job.seen, job.ok = "done", 1, 1
		return
	end
	job.text, job.pos, job.state, job.seen, job.ok = text, 1, "parse", 0, 0
end

local function head_of(body)
	return (body:sub(1, 200):gsub("%s+", " "))
end

local function parse_cached(job, reason)
	local stale = read_file(job.def.file)
	if not stale or #stale == 0 then return false end
	D.cache_fallback = true
	if job.def.key == "pairs" then D.pair_cache_fallback = true end
	say(string.format("%s: using local snapshot after %s", job.def.key, reason))
	begin_parse(job, stale)
	return true
end

local function request(job)
	job.state = "wait"
	local headers = { ["Accept"] = "application/json", ["User-Agent"] = K.AGENT }
	local sent = HTTP.Request("GET", K.DATA .. job.def.file, { headers = headers, timeout = K.TIMEOUT }, function(r)
		local code = tonumber(r.code) or 0
		local body = type(r.response) == "string" and r.response or ""
		if code == 200 and #body > 0 then
			if not write_file(job.def.file, body) then
				say(job.def.key .. ": downloaded but failed to save cache")
			end
			D.meta[job.def.key] = os.time()
			save_meta(D.meta)
			D.err, D.fails = nil, 0
			dbg(string.format("%s: downloaded %d bytes", job.def.key, #body))
			begin_parse(job, body)
			return
		end
		local reason = code > 0 and ("HTTP " .. code) or tostring(r.error_message or "no answer")
		say(string.format("%s: %s, answer: %s", job.def.key, reason, head_of(body)))
		if parse_cached(job, reason) then return end
		D.err = job.def.key .. " " .. reason
		D.fails = (D.fails or 0) + 1
		D.wait = os.clock() + math.min(K.RETRY_MAX, K.RETRY * 2 ^ (D.fails - 1))
		job.state = "fetch"
	end)
	if not sent then
		say(job.def.key .. ": request was not sent")
		if parse_cached(job, "request not sent") then return end
		D.err = job.def.key .. " not sent"
		D.fails = (D.fails or 0) + 1
		D.wait = os.clock() + math.min(K.RETRY_MAX, K.RETRY * 2 ^ (D.fails - 1))
		job.state = "fetch"
	end
end

local function parse_step(job)
	local text, pos, handler = job.text, job.pos, HANDLE[job.def.key]
	local t0, n = os.clock(), 0
	while true do
		local s, e = text:find("{[^{}]*}", pos)
		if not s then
			job.state = "done"
			break
		end
		pos = e + 1
		job.seen = job.seen + 1
		if handler(text:sub(s, e)) then job.ok = job.ok + 1 end
		n = n + 1
		if n % 200 == 0 and os.clock() - t0 > K.PARSE_SLICE then break end
	end
	job.pos = pos
end

function data.next()
	D.i = D.i + 1
	local def = K.JOBS[D.i]
	if not def then
		load_ability_tags()
		data.upgrades()
		data.hero_meta()
		D.ready, D.job = true, nil
		engine.invalidate()
		say(string.format("data ready: %d abilities, %d heroes, %d stats%s",
			D.cnt_abil or 0, D.cnt_hero or 0, D.cnt_stat or 0,
			D.cache_fallback and " (local snapshot)" or ""))
		return
	end
	D.job = { def = def, state = "load" }
end

function data.tick()
	if D.ready or os.clock() < D.wait then return end
	local job = D.job
	if not job then
		D.meta = D.meta or load_meta()
		data.next()
		return
	end
	if job.state == "load" then
		local stamp = D.meta[job.def.key]
		local text = read_file(job.def.file)
		local fresh = not D.force and stamp and os.time() - stamp < K.TTL
		if text and #text > 0 and fresh then
			begin_parse(job, text)
		else
			job.state = "fetch"
		end
	elseif job.state == "fetch" then
		request(job)
	elseif job.state == "parse" then
		parse_step(job)
	elseif job.state == "done" then
		if job.ok == 0 then
			say(string.format("WARN %s: no records parsed out of %d objects, the response shape differs, see configs/%s", job.def.key, job.seen, job.def.file))
			D.err = job.def.key .. " format"
		end
		dbg(string.format("%s parsed: %d of %d objects", job.def.key, job.ok or 0, job.seen or 0))
		if job.def.key == "sabil" then D.cnt_abil = job.ok end
		if job.def.key == "shero" then D.cnt_hero = job.ok end
		if job.def.key == "stats" then D.cnt_stat = job.ok end
		data.next()
	end
end

local function parse_string_array(entry, key)
	local values, body = {}, entry:match('"' .. key .. '"%s*:%s*%[([^%]]*)%]')
	if not body then return values end
	for value in body:gmatch('"([^"]+)"') do values[#values + 1] = value end
	return values
end

local function parse_position_array(entry, key)
	local values, body = {}, entry:match('"' .. key .. '"%s*:%s*%[([^%]]*)%]')
	if not body then return values end
	for value in body:gmatch("%d+") do
		local position = tonumber(value)
		if position and position >= 1 and position <= 5 then values[position] = true end
	end
	return values
end

load_ability_tags = function()
	local text = read_file(K.TAGS)
	if not text or #text == 0 then
		D.tag_error = "missing configs/" .. K.TAGS
		say("role tags unavailable: " .. D.tag_error)
		D.tags_loaded = true
		return
	end
	local count = 0
	for short, entry in text:gmatch('"([%w_]+)"%s*:%s*{([^{}]*)}') do
		if D.short[short] then
			local tags = {}
			for _, tag in ipairs(parse_string_array(entry, "tags")) do tags[tag] = true end
			D.tags[short] = tags
			D.role_must[short] = parse_position_array(entry, "roleMust")
			D.role_avoid[short] = parse_position_array(entry, "roleAvoid")
			D.requires[short] = parse_string_array(entry, "requires")
			count = count + 1
		end
	end
	D.tags_loaded = true
	if count == 0 then
		D.tag_error = "no ability tags matched the static ability list"
		say("role tags failed: " .. D.tag_error)
	else
		D.tag_error = nil
		say(string.format("role tags loaded: %d abilities", count))
	end
end

data.model_keys = {}
data.KEY_ALIAS = { zuus = "zeus" }

function data.model_key(model)
	if not model or model <= 0 then return nil end
	local key = data.model_keys[model]
	if key == nil then
		local npc = Engine.GetHeroNameByID(model)
		key = type(npc) == "string" and npc:gsub("^npc_dota_hero_", ""):lower():gsub("[^a-z]", "") or false
		if key then key = data.KEY_ALIAS[key] or key end
		data.model_keys[model] = key
	end
	return key or nil
end

function data.owner_key(id)
	local rec = D.abil[id]
	local hero = rec and rec.owner and D.hero[rec.owner]
	if not hero then return nil end
	local key = hero.short:lower():gsub("[^a-z]", "")
	return data.KEY_ALIAS[key] or key
end

function data.meta_of(model)
	local key = data.model_key(model)
	return key and D.model_meta[key] or nil
end

function data.hero_meta()
	local text = read_file(K.HERO_META)
	if not text or #text == 0 then
		say("hero model data unavailable: missing configs/" .. K.HERO_META)
		return
	end
	local count = 0
	for key, entry in text:gmatch('"([%w_]+)"%s*:%s*{([^{}]*)}') do
		if sfield(entry, "attackType") then
			local tags = {}
			for _, tag in ipairs(parse_string_array(entry, "tags")) do tags[tag] = true end
			D.model_meta[(key:lower():gsub("[^a-z]", ""))] = {
				melee = sfield(entry, "attackType") == "Melee",
				attr = sfield(entry, "primaryAttr") or "all",
				bat = field(entry, "attackRate"),
				range = field(entry, "attackRange"),
				speed = field(entry, "moveSpeed"),
				armor = field(entry, "baseArmor"),
				tags = tags,
			}
			count = count + 1
		end
	end
	say(string.format("hero model data loaded: %d heroes", count))
end

function data.upgrades()
	D.upg, D.upg_loaded = {}, false
	local text = read_file(K.UPGRADES)
	if not text or #text == 0 then
		say("aghanim upgrade data unavailable: missing configs/" .. K.UPGRADES)
		return
	end
	local count = 0
	for short, entry in text:gmatch('"([%w_]+)"%s*:%s*{([^{}]*)}') do
		local rec = {}
		for _, key in ipairs({ "sc", "sh" }) do
			if field(entry, key) == 1 then
				rec[key] = {
					en = sfield(entry, key .. "_en"), ru = sfield(entry, key .. "_ru"),
					need = sfield(entry, key .. "_need"), new = sfield(entry, key .. "_new"),
				}
			end
		end
		D.upg[short] = rec
		count = count + 1
	end
	D.upg_loaded = count > 0
	say(string.format("aghanim upgrade data loaded: %d abilities", count))
end

function data.refresh()
	if os.clock() < D.cool then return end
	D.cool = os.clock() + K.REFRESH_COOLDOWN
	D.i, D.job, D.ready, D.wait, D.err = 0, nil, false, 0, nil
	D.force, D.fails = true, 0
	D.cache_fallback, D.pair_cache_fallback = false, false
	D.meta = load_meta()
	D.abil, D.short, D.hero, D.stat, D.pair, D.tri = {}, {}, {}, {}, {}, {}
	D.aghs, D.model_meta = {}, {}
	D.mpair, D.mtri, D.hs, D.hbuild, D.mstat = {}, {}, {}, {}, {}
	D.tags, D.role_must, D.role_avoid, D.requires = {}, {}, {}, {}
	D.tags_loaded, D.tag_error = false, nil
	D.upg, D.upg_loaded = {}, false
	reader.sig = ""
	V.dirty = true
	say("refresh requested")
end

local function nm(id)
	local rec = D.abil[id]
	if rec then return rec.name end
	local hero = id < 0 and D.hero[-id]
	if hero then return hero.name end
	return "#" .. tostring(id)
end

local function wr_of(id)
	local s = D.stat[id]
	return s and s.wr or 0.5
end

local function score(id)
	local s = D.stat[id]
	local wr = s and s.wr or 0.5
	local order = 0.5
	if s and s.pick then order = (50 - clamp(s.pick, 1, 50)) / 49 end
	return K.W_WR * wr + K.W_PICK * order
end

local function same_owner(a, b)
	local ra, rb = D.abil[a], D.abil[b]
	return ra and rb and ra.owner and ra.owner == rb.owner
end

local ROLE_NEEDS = {
	[1] = {
		{ groups = { { "steroid" } }, priority = 1.0 },
		{ groups = { { "farm_tool" }, { "waveclear" } }, priority = 0.75 },
		{ groups = { { "mobility" }, { "sustain_self" } }, priority = 0.7 },
	},
	[2] = {
		{ groups = { { "nuke" } }, priority = 1.0 },
		{ groups = { { "teamfight_ult" }, { "hard_cc" } }, priority = 0.75 },
		{ groups = { { "mobility" } }, priority = 0.5 },
	},
	[3] = {
		{ groups = { { "hard_cc", "aoe" } }, priority = 0.75 },
		{ groups = { { "initiation" } }, priority = 0.6 },
		{ groups = { { "sustain_self" }, { "passive_value" } }, priority = 0.4 },
	},
	[4] = {
		{ groups = { { "hard_cc" } }, priority = 1.0 },
		{ groups = { { "waveclear" }, { "nuke" } }, priority = 0.75 },
		{ groups = { { "mobility" } }, priority = 0.5 },
	},
	[5] = {
		{ groups = { { "hard_cc" } }, priority = 1.0 },
		{ groups = { { "waveclear" }, { "nuke" } }, priority = 0.75 },
		{ groups = { { "save_ally" } }, priority = 0.5 },
	},
}

local function tags_for(id)
	local rec = D.abil[id]
	return rec and D.tags[rec.short] or nil
end

local function satisfies_need(tags, need)
	for _, group in ipairs(need.groups) do
		local matches = true
		for _, tag in ipairs(group) do
			if not tags or not tags[tag] then
				matches = false
				break
			end
		end
		if matches then return true end
	end
	return false
end

local function contains_id(ids, target)
	for _, id in ipairs(ids) do
		if id == target then return true end
	end
	return false
end

local function requirement_met(requirement, pool, mine)
	if requirement:sub(1, 6) == "model:" then return true end
	if requirement:sub(1, 4) == "tag:" then
		local tag = requirement:sub(5)
		for _, id in ipairs(mine) do
			if tags_for(id) and tags_for(id)[tag] then return true end
		end
		for _, id in ipairs(pool) do
			if tags_for(id) and tags_for(id)[tag] then return true end
		end
		return false
	end
	local required_id = D.short[requirement]
	if not required_id then return true end
	return contains_id(pool, required_id) or contains_id(mine, required_id)
end

local function requirements_met(id, pool, mine)
	local rec = D.abil[id]
	local required = rec and D.requires[rec.short]
	if not required or #required == 0 then return true end
	for _, requirement in ipairs(required) do
		if requirement_met(requirement, pool, mine) then return true end
	end
	return false
end

local function role_adjustment(id, pool, mine, role)
	local needs = ROLE_NEEDS[role]
	local candidate_tags = tags_for(id)
	if not needs or not candidate_tags or not requirements_met(id, pool, mine) then return 0 end

	local mine_tags = {}
	for _, picked in ipairs(mine) do
		for tag in pairs(tags_for(picked) or {}) do mine_tags[tag] = true end
	end
	local adjustment = 0
	for _, need in ipairs(needs) do
		if not satisfies_need(mine_tags, need) and satisfies_need(candidate_tags, need) then
			local available = 0
			for _, candidate in ipairs(pool) do
				if satisfies_need(tags_for(candidate), need) then available = available + 1 end
			end
			adjustment = adjustment + K.ROLE_NEED_WEIGHT * need.priority / math.sqrt(math.max(1, available))
		end
	end
	local rec = D.abil[id]
	local short = rec and rec.short
	if short and D.role_must[short] and D.role_must[short][role] then
		adjustment = adjustment + K.ROLE_CURATED_BONUS
	end
	if short and D.role_avoid[short] and D.role_avoid[short][role] then
		adjustment = adjustment - K.ROLE_CAP
	end
	return clamp(adjustment, -K.ROLE_CAP, K.ROLE_CAP)
end

function engine.model_fit(id, model)
	local meta, tags = data.meta_of(model), tags_for(id)
	if not meta or not tags then return 0, nil end
	if meta.melee and tags.ranged_only then return -K.MODEL_BAD, "adh_fit_ranged" end
	if not meta.melee and tags.melee_only then return -K.MODEL_BAD, "adh_fit_melee" end
	if meta.melee and tags.grants_ranged then return K.MODEL_GOOD, "adh_fit_grants" end
	if tags.steroid and (meta.attr == "agi" or (meta.bat and meta.bat <= 1.6)) then return K.MODEL_SOFT, "adh_fit_attack" end
	if tags.mana_hungry and meta.attr == "int" then return K.MODEL_SOFT, "adh_fit_mana" end
	if tags.sustain_self and meta.attr == "str" then return K.MODEL_SOFT, "adh_fit_tank" end
	local mt = meta.tags or {}
	if tags.steroid and (mt.rc_talents or mt.innate_offense) then return K.MODEL_SOFT, "adh_fit_rc" end
	if tags.steroid and not meta.melee and (meta.range or 0) >= 600 then return K.MODEL_SOFT, "adh_fit_range" end
	if (tags.nuke or tags.mana_hungry) and mt.caster_talents then return K.MODEL_SOFT, "adh_fit_caster" end
	if (tags.sustain_self or tags.initiation) and (mt.tank_talents or mt.innate_tank) then return K.MODEL_SOFT, "adh_fit_tanky" end
	if (tags.save_ally or tags.team_aura) and (mt.utility_talents or mt.innate_team) then return K.MODEL_SOFT, "adh_fit_team" end
	return 0, nil
end

function B.meta(mine, model)
	local aff, minute, src, total = {}, {}, {}, 0
	local function add(key, w, id)
		local hb = key and D.hbuild[key]
		if not hb then return end
		total = total + w
		for item, v in pairs(hb.items) do
			aff[item] = (aff[item] or 0) + w * v.pr
			minute[item] = (minute[item] or 0) + w * v.pr * v.min
			if id and (not src[item] or w * v.pr > src[item].v) then src[item] = { id = id, v = w * v.pr, pr = v.pr } end
		end
	end
	for _, id in ipairs(mine) do
		local rec = D.abil[id]
		add(data.owner_key(id), rec and rec.ult and 1.5 or 1, id)
	end
	add(data.model_key(model), 0.5, nil)
	local out = {}
	if total <= 0 then return out end
	for item, a in pairs(aff) do
		out[item] = { aff = a / total, min = a > 0 and minute[item] / a or nil, src = src[item] }
	end
	return out
end

function B.upgrade(id, key)
	local rec = D.abil[id]
	if not rec then return nil end
	local up = D.upg[rec.short]
	return up and up[key] or nil
end

function B.aghs_list(mine)
	local out, owned = {}, {}
	for _, id in ipairs(mine) do
		local rec = D.abil[id]
		if rec then owned[rec.short] = true end
	end
	for _, kind in ipairs({ "scepter", "shard" }) do
		local key = kind == "scepter" and "sc" or "sh"
		local item = kind == "scepter" and "item_ultimate_scepter" or "item_aghanims_shard"
		local tag = kind == "scepter" and "good_aghanims" or "good_shard"
		local rows = {}
		for _, id in ipairs(mine) do
			local up = B.upgrade(id, key)
			if (up or not D.upg_loaded) and not (up and up.need and not owned[up.need]) then
				local stat = D.aghs[id] and D.aghs[id][kind]
				local hb = D.hbuild[data.owner_key(id) or ""]
				local pro = hb and hb.items[item]
				local tagged = tags_for(id) and tags_for(id)[tag]
				if tagged or (stat and stat.d >= K.AGHS_GOOD) or (pro and pro.pr >= K.AGHS_PRO) then
					rows[#rows + 1] = {
						id = id, up = up, stat = stat, pro = pro,
						v = (tagged and 0.5 or 0) + (stat and stat.d * 10 or 0) + (pro and pro.pr or 0) + (up and up.need and 0.3 or 0),
					}
				end
			end
		end
		table.sort(rows, function(a, b) return a.v > b.v end)
		local top = rows[1]
		if top then
			local entry = { item = item, key = key, ids = {}, up = top.up }
			for i, r in ipairs(rows) do
				entry.ids[i] = r.id
				if r.stat and (not entry.d or r.stat.d > entry.d) then entry.d = r.stat.d end
			end
			if top.pro then entry.meta = { id = top.id, pr = top.pro.pr, min = top.pro.min } end
			if top.up and top.up.need then entry.need = D.short[top.up.need] end
			out[#out + 1] = entry
		end
	end
	return out
end

function B.farm(c, mine, role)
	if c.arch == "support" or role == 4 or role == 5 then return nil end
	local cleave
	for _, id in ipairs(mine) do
		local rec = D.abil[id]
		if rec and B.multishot[rec.short] then return nil end
		if rec and B.cleave[rec.short] then cleave = cleave or id end
	end
	if cleave then return { item = "item_mask_of_madness", reason = "adh_f_cleave", id = cleave } end
	if c.has.summon then return { item = "item_helm_of_the_dominator", reason = "adh_f_dominate", id = c.has.summon } end
	if c.arch == "caster" then
		if c.has.farm_tool then return nil end
		return { item = "item_hand_of_midas", reason = "adh_f_midas" }
	end
	if c.arch == "tank" then
		if c.has.farm_tool or c.has.waveclear then return nil end
		return { item = "item_helm_of_the_dominator", reason = "adh_f_offlane" }
	end
	if not c.melee then return { item = "item_mjollnir", reason = "adh_f_mjollnir" } end
	if c.attr == "str" or c.has.sustain_self then
		return { item = "item_radiance", reason = "adh_f_radiance", id = c.has.sustain_self }
	end
	return { item = "item_bfury", reason = "adh_f_bfury" }
end

function B.run(mine, model, enemy)
	local out = { model = model, share = {}, aghs = {}, core = {}, counter = {} }
	local meta = data.meta_of(model)
	local c = { has = {}, n = setmetatable({}, { __index = function() return 0 end }),
		melee = meta and meta.melee or false, attr = meta and meta.attr or "all" }
	for _, id in ipairs(mine) do
		for tag in pairs(tags_for(id) or {}) do
			c.n[tag] = (c.n[tag] or 0) + 1
			c.has[tag] = c.has[tag] or id
		end
	end
	local role = ui.role and tonumber(ui.role:Get()) or 0
	local total, best, best_s = 0, nil, -1
	for _, a in ipairs(ARCH_ORDER) do
		local v = 0.2
		for tag, w in pairs(B.arch[a]) do v = v + w * (c.n[tag] or 0) end
		if B.attr[c.attr] == a then v = v + 0.6 end
		local mt = meta and meta.tags or {}
		for tag, arch in pairs(B.hero_tag) do
			if mt[tag] and arch == a then v = v + 0.4 end
		end
		local rb = B.role[role]
		if rb and rb[a] then v = v + rb[a] * 1.5 end
		out.share[a] = v
		total = total + v
		if v > best_s then best, best_s = a, v end
	end
	for _, a in ipairs(ARCH_ORDER) do out.share[a] = out.share[a] / total end
	c.arch, out.arch, out.melee, out.attr, out.known = best, best, c.melee, c.attr, meta ~= nil

	c.role, c.share, c.escape = role, out.share, c.has.mobility
	c.en = setmetatable({ evasion = 0 }, { __index = function() return 0 end })
	for _, id in ipairs(enemy) do
		for tag in pairs(tags_for(id) or {}) do c.en[tag] = c.en[tag] + 1 end
		local rec = D.abil[id]
		if rec and B.evasion[rec.short] then c.en.evasion = c.en.evasion + 1 end
	end

	local taken = {}
	for _, id in ipairs(mine) do
		local rec = D.abil[id]
		if rec and B.closer[rec.short] then
			for item in pairs(B.blinks) do taken[item] = true end
			break
		end
	end
	out.early, out.core, out.late = {}, {}, {}
	local farm = B.farm(c, mine, role)
	if farm then
		farm.farm = true
		taken[farm.item] = true
		if farm.item == "item_helm_of_the_dominator" then taken.item_helm_of_the_overlord = true end
		local stage = (B.farm_cost[farm.item] or 3000) < 2300 and "early" or "core"
		out[stage][#out[stage] + 1] = farm
		farm.cost = B.farm_cost[farm.item] or 3000
	end
	local meta = B.meta(mine, model)
	local scored, known = {}, {}
	for _, e in ipairs(B.items) do
		known[e[1]] = true
		if not taken[e[1]] then
			local v = 0
			for a, w in pairs(e[4]) do v = v + w * (out.share[a] or 0) end
			local bonus, reason, id = e[5](c)
			local m = meta[e[1]]
			local mb = m and m.aff * B.META_W or 0
			local row = {
				item = e[1], cost = e[2], group = e[3], s = v * B.SCALE + mb
					+ ((bonus or 0) < 0 and bonus or (bonus or 0) * clamp(v * 2, 0.25, 1)),
				reason = reason or ("adh_g_" .. e[3]), id = id,
				minute = m and m.aff >= B.META_STAGE and m.min or nil,
			}
			if m and m.src and m.aff >= B.META_SHOW and mb > math.max(bonus or 0, 0.15) then
				row.meta = { id = m.src.id, pr = m.src.pr }
			end
			scored[#scored + 1] = row
		end
	end
	for item, m in pairs(meta) do
		if not known[item] and not taken[item] and not B.farm_cost[item] and m.aff >= B.META_MIN and m.src
			and item ~= "item_ultimate_scepter" and item ~= "item_aghanims_shard" then
			scored[#scored + 1] = {
				item = item, cost = 3000, group = "meta", s = m.aff * B.META_W * 1.3 + 0.2,
				reason = "adh_g_meta", minute = m.min, meta = { id = m.src.id, pr = m.src.pr },
			}
		end
	end
	table.sort(scored, function(a, b) return a.s > b.s end)
	local used = {}
	local function stage_of(e)
		if e.minute then return e.minute <= 16 and "early" or (e.minute <= 28 and "core" or "late") end
		return e.cost < 2300 and "early" or (e.cost < 4800 and "core" or "late")
	end
	local function take(e)
		local stage = stage_of(e)
		if #out[stage] >= B.stage_cap[stage] or (used[e.group] or 0) >= (B.limit[e.group] or 1) then return false end
		used[e.group] = (used[e.group] or 0) + 1
		taken[e.item] = true
		out[stage][#out[stage] + 1] = e
		return true
	end
	for _, e in ipairs(scored) do
		if e.group == "boots" then
			take(e)
			break
		end
	end
	for _, e in ipairs(scored) do
		if e.s < B.THRESHOLD then break end
		if not taken[e.item] then take(e) end
	end
	for _, stage in ipairs({ "early", "core", "late" }) do
		table.sort(out[stage], function(a, b)
			return (a.minute or (a.cost or 0) / 250) < (b.minute or (b.cost or 0) / 250)
		end)
	end
	out.core_all = {}
	for _, stage in ipairs({ "early", "core", "late" }) do
		for _, e in ipairs(out[stage]) do out.core_all[#out.core_all + 1] = e end
	end
	out.aghs = B.aghs_list(mine)

	local counter = {}
	local en = {}
	for _, id in ipairs(enemy) do
		for tag in pairs(tags_for(id) or {}) do
			en[tag] = en[tag] or {}
			en[tag][#en[tag] + 1] = id
		end
	end
	for order, rule in ipairs(B.counter) do
		local pick = rule.pick[best]
		if type(pick) == "table" then pick = c.melee and pick[1] or pick[2] end
		if pick and not taken[pick] then
			local ids, seen = {}, {}
			if rule.set then
				for _, id in ipairs(enemy) do
					local rec = D.abil[id]
					if rec and rule.set[rec.short] then
						ids[#ids + 1], seen[id] = id, true
					end
				end
			end
			local tagged = rule.tag and en[rule.tag] or {}
			if rule.tag and #tagged >= rule.min then
				for _, id in ipairs(tagged) do
					if not seen[id] then ids[#ids + 1], seen[id] = id, true end
				end
			end
			if #ids > 0 then
				taken[pick] = true
				counter[#counter + 1] = { item = pick, reason = rule.reason, ids = ids, order = order }
			end
		end
	end
	table.sort(counter, function(a, b)
		if #a.ids ~= #b.ids then return #a.ids > #b.ids end
		return a.order < b.order
	end)
	for i = 1, math.min(K.MAX_COUNTER_ITEMS, #counter) do out.counter[i] = counter[i] end
	return out
end

local function increase(a, b)
	local t = D.pair[a]
	local wr = t and t[b]
	if not wr or same_owner(a, b) then return nil end
	return wr - math.sqrt(math.max(0, wr_of(a)) * math.max(0, wr_of(b)))
end

function engine.model_syn(id, model, mine)
	local p = D.mpair[model] and D.mpair[model][id]
	local d, with = p and p.inc or nil, nil
	for _, t in ipairs(D.mtri[model] and D.mtri[model][id] or {}) do
		if (not d or t.inc > d) and contains_id(mine, t.b) then d, with = t.inc, t.b end
	end
	return d, with
end

local function trim(t, n)
	for i = #t, n + 1, -1 do t[i] = nil end
	return t
end

local function by_wr(desc)
	return function(a, b)
		if a.mine ~= b.mine then return a.mine end
		if desc then return a.wr > b.wr end
		return a.wr < b.wr
	end
end

function engine.models(pool, mine)
	local seen, list, taken, ids = {}, {}, reader.taken_models or {}, {}
	for _, id in ipairs(pool) do ids[#ids + 1] = id end
	for _, id in ipairs(mine) do ids[#ids + 1] = id end
	for _, id in ipairs(reader.board or pool) do
		local key = data.owner_key(id)
		local st = key and D.mstat[key]
		if st and not seen[key] then
			seen[key] = true
			local by = D.mpair[st.h] or {}
			local syn, tops, good, bad = 0, {}, {}, {}
			for _, other in ipairs(mine) do
				local p = by[other]
				if p then syn = syn + p.inc end
			end
			for _, other in ipairs(pool) do
				local p = by[other]
				if p and p.inc > 0 then tops[#tops + 1] = p.inc end
			end
			table.sort(tops, function(a, b) return a > b end)
			for i = 1, math.min(3, #tops) do syn = syn + tops[i] / 3 end
			for _, other in ipairs(ids) do
				local p = by[other]
				if p and p.wr then
					local e = { id = other, wr = p.wr, mine = false }
					if p.wr >= 0.5 then good[#good + 1] = e else bad[#bad + 1] = e end
				end
			end
			table.sort(good, by_wr(true))
			table.sort(bad, by_wr(false))
			local wr = (st.hs and st.hs > 0) and (st.wr + st.hs) / 2 or st.wr
			list[#list + 1] = {
				h = st.h, wr = st.wr, hs = st.hs, pr = st.pr, syn = syn, score = wr + syn,
				good = trim(good, 5), bad = trim(bad, 3), taken = taken[st.h] or false, mine = st.h == reader.model,
			}
		end
	end
	table.sort(list, function(a, b) return a.score > b.score end)
	return list
end

function engine.explain(r, all, mine, models)
	local mine_set = {}
	for _, id in ipairs(mine) do mine_set[id] = true end
	local sg, sb = {}, {}
	local t = D.pair[r.id] or {}
	for _, other in ipairs(all) do
		local wr = t[other]
		if wr and other ~= r.id and not same_owner(r.id, other) then
			local e = { id = other, wr = wr, mine = mine_set[other] or false }
			if wr >= 0.5 then sg[#sg + 1] = e else sb[#sb + 1] = e end
		end
	end
	table.sort(sg, by_wr(true))
	table.sort(sb, by_wr(false))
	local hg, hb = {}, {}
	for _, m in ipairs(models) do
		local p = D.mpair[m.h] and D.mpair[m.h][r.id]
		if p and p.wr and (m.mine or not m.taken) then
			local e = { h = m.h, wr = p.wr, mine = m.mine }
			if p.wr >= 0.5 then hg[#hg + 1] = e else hb[#hb + 1] = e end
		end
	end
	table.sort(hg, by_wr(true))
	table.sort(hb, by_wr(false))
	r.syn_good, r.syn_bad, r.hero_good, r.hero_bad = trim(sg, 5), trim(sb, 3), trim(hg, 3), trim(hb, 2)
	local ag = D.aghs[r.id]
	r.ag_sc = (ag and ag.scepter and ag.scepter.d >= K.AGHS_GOOD) or false
	r.ag_sh = (ag and ag.shard and ag.shard.d >= K.AGHS_GOOD) or false
end

function engine.has_tags(id, list)
	if not list then return false end
	local tags = tags_for(id)
	if not tags then return false end
	for _, tag in ipairs(list) do
		if not tags[tag] then return false end
	end
	return true
end

function engine.invalidate()
	reader.sig = ""
end

function engine.allowed(pool)
	local meta = data.meta_of(reader.model)
	if meta and meta.melee then return pool end
	local out = {}
	for _, id in ipairs(pool) do
		local rec = D.abil[id]
		if not (rec and K.SHRINK[rec.short]) then out[#out + 1] = id end
	end
	return out
end

function engine.run(pool, mine, enemy)
	pool = engine.allowed(pool)
	local out = { top = {}, op = {}, trap = {}, tri = {}, counter = {}, deny = {} }
	out.build = B.run(mine, reader.model, enemy)
	local inpool, all = {}, {}
	for _, id in ipairs(pool) do
		inpool[id] = true
		all[#all + 1] = id
	end
	for _, id in ipairs(mine) do
		all[#all + 1] = id
	end

	local has_ult = false
	for _, id in ipairs(mine) do
		local rec = D.abil[id]
		if rec and rec.ult then has_ult = true end
	end

	local cand = {}
	local role = ui.role and tonumber(ui.role:Get()) or 0
	local sinks, rearm = 0, false
	for _, id in ipairs(mine) do
		local t = tags_for(id)
		if t and t.skill_point_sink then sinks = sinks + 1 end
		if D.abil[id] and D.abil[id].short == "tinker_rearm" then rearm = true end
	end
	local unlock, owned = {}, {}
	for _, id in ipairs(mine) do
		if D.abil[id] then owned[D.abil[id].short] = true end
		for _, key in ipairs({ "sc", "sh" }) do
			local up = B.upgrade(id, key)
			local need = up and up.need and D.short[up.need]
			if need then unlock[need] = { id = id, key = key } end
		end
	end
	for _, id in ipairs(pool) do
		local rec = D.abil[id]
		if not (has_ult and rec and rec.ult) and requirements_met(id, pool, mine) then
			local base_score, pair_delta = score(id), 0
			local row = { id = id, wr = wr_of(id), pick = D.stat[id] and D.stat[id].pick }
			for _, m in ipairs(mine) do
				local d = increase(id, m)
				if d then
					pair_delta = pair_delta + d
					if d > 0 and (not row.syn or d > row.syn) then row.syn, row.with = d, m end
				end
			end
			local role_delta = role_adjustment(id, pool, mine, role)
			row.role_fit = role_delta > 0.005
			row.role_avoid = role_delta < -0.005
			row.fit, row.fit_why = engine.model_fit(id, reader.model)
			row.msyn, row.mwith = engine.model_syn(id, reader.model, mine)
			local model_delta = row.msyn and clamp(row.msyn * K.MODEL_SYN_SCALE, -K.MODEL_SYN_CAP, K.MODEL_SYN_CAP) or 0
			row.hs = D.hs[id]
			if row.hs then model_delta = model_delta + clamp((row.hs - row.wr) * K.HS_SCALE, -K.HS_CAP, K.HS_CAP) end
			local ctags = tags_for(id) or {}
			if ctags.skill_point_sink and sinks > 0 then
				row.sink, model_delta = sinks, model_delta - K.SINK_PENALTY * sinks
			end
			if ctags.good_with_rearm and rearm then
				row.rearm, model_delta = true, model_delta + K.REARM_BONUS
			end
			row.unlock = unlock[id]
			for _, key in ipairs({ "sc", "sh" }) do
				local up = not row.unlock and B.upgrade(id, key)
				if up and up.need and owned[up.need] then row.unlock = { id = id, key = key } end
			end
			if row.unlock then model_delta = model_delta + K.UNLOCK_BONUS end
			local now_pick = (reader.picked or 0) + 1
			if row.pick and row.pick <= now_pick + K.SOON then
				row.timing, model_delta = "now", model_delta + K.TIMING_BONUS
			elseif row.pick and row.pick >= now_pick + K.LATE then
				row.timing, model_delta = "wait", model_delta - K.TIMING_BONUS
			end
			row.score = clamp(base_score + clamp(pair_delta * K.PAIR_SCALE, -K.PAIR_CAP, K.PAIR_CAP) + role_delta + row.fit + model_delta, 0, 1)
			cand[#cand + 1] = row
		end
	end
	table.sort(cand, function(x, y)
		return x.score > y.score
	end)
	for i = 1, math.min(K.TOP, #cand) do out.top[i] = cand[i] end
	for _, r in ipairs(out.top) do
		local good, bad = {}, {}
		for _, other in ipairs(all) do
			if other ~= r.id then
				local d = increase(r.id, other)
				if d and d >= 0.02 then good[#good + 1] = { id = other, d = d } end
				if d and d <= -0.02 then bad[#bad + 1] = { id = other, d = d } end
			end
		end
		table.sort(good, function(a, b) return a.d > b.d end)
		table.sort(bad, function(a, b) return a.d < b.d end)
		r.good, r.bad = { good[1], good[2] }, bad[1]
	end
	out.models = reader.phase == "draft" and engine.models(pool, mine) or {}
	for _, r in ipairs(out.top) do engine.explain(r, all, mine, out.models) end
	out.foes = {}
	for _, f in ipairs(reader.phase == "draft" and reader.foes or {}) do
		local sum, syn = 0, 0
		for i, a in ipairs(f.ids) do
			sum = sum + wr_of(a)
			for j = i + 1, #f.ids do
				local d = increase(a, f.ids[j])
				if d then syn = syn + clamp(d, -0.05, 0.05) end
			end
		end
		out.foes[#out.foes + 1] = { name = f.name, ids = f.ids, d = sum / #f.ids - 0.5 + 0.5 * syn, syn = syn }
	end
	table.sort(out.foes, function(a, b) return a.d > b.d end)
	out.model_combo = {}
	for _, r in ipairs(cand) do
		if r.msyn and r.msyn >= K.MODEL_COMBO then out.model_combo[#out.model_combo + 1] = r end
	end
	table.sort(out.model_combo, function(a, b) return a.msyn > b.msyn end)
	for i = #out.model_combo, K.MAX_MODEL_COMBO + 1, -1 do out.model_combo[i] = nil end

	for _, enemy_id in ipairs(enemy) do
		local enemy_ability = D.abil[enemy_id]
		if enemy_ability then
			for priority, rule in ipairs(COUNTER_RULES) do
				if rule.enemies[enemy_ability.short] then
					for _, id in ipairs(pool) do
						local ability = D.abil[id]
						if ability and (rule.picks[ability.short] or engine.has_tags(id, rule.tags)) then
							out.counter[#out.counter + 1] = {
								id = id, against = enemy_id, label = rule.label,
								priority = priority, score = score(id),
							}
						end
					end
				end
			end
			for _, id in ipairs(pool) do
				local d = increase(id, enemy_id)
				if d and d >= K.OP then
					out.deny[#out.deny + 1] = { id = id, against = enemy_id, d = d, score = score(id) }
				end
			end
		end
	end
	table.sort(out.counter, function(a, b)
		if a.priority ~= b.priority then return a.priority < b.priority end
		return a.score > b.score
	end)
	table.sort(out.deny, function(a, b)
		if a.d ~= b.d then return a.d > b.d end
		return a.score > b.score
	end)
	for i = #out.counter, K.MAX_COUNTER + 1, -1 do out.counter[i] = nil end
	for i = #out.deny, K.MAX_DENY + 1, -1 do out.deny[i] = nil end

	for i = 1, #all - 1 do
		for j = i + 1, #all do
			local a, b = all[i], all[j]
			if inpool[a] or inpool[b] then
				local d = increase(a, b)
				if d and d >= K.OP then
					out.op[#out.op + 1] = { a = a, b = b, d = d }
				elseif d and d <= -K.TRAP then
					out.trap[#out.trap + 1] = { a = a, b = b, d = d }
				end
			end
		end
	end
	table.sort(out.op, function(x, y) return x.d > y.d end)
	table.sort(out.trap, function(x, y) return x.d < y.d end)
	for i = #out.op, K.MAX_OP + 1, -1 do out.op[i] = nil end
	for i = #out.trap, K.MAX_TRAP + 1, -1 do out.trap[i] = nil end

	local universe, seen = {}, {}
	for _, id in ipairs(all) do universe[id] = true end
	for _, a in ipairs(pool) do
		for _, e in ipairs(D.tri[a] or {}) do
			if not seen[e] then
				seen[e] = true
				if universe[e[1]] and universe[e[2]] and universe[e[3]] then
					local d = e[4] - (wr_of(e[1]) + wr_of(e[2]) + wr_of(e[3])) / 3
					if d >= K.OP then out.tri[#out.tri + 1] = { e[1], e[2], e[3], d = d } end
				end
			end
		end
	end
	table.sort(out.tri, function(x, y) return x.d > y.d end)
	for i = #out.tri, K.MAX_TRI + 1, -1 do out.tri[i] = nil end
	return out
end

local function try_call(panel, method)
	local ok, value = pcall(function() return panel[method](panel) end)
	if ok then return value end
	return nil
end

local function child_at(panel, index)
	local ok, value = pcall(function() return panel:GetChild(index) end)
	if ok then return value end
	return nil
end

local IMG_HINT = { "Image", "Icon", "Portrait", "Avatar", "ability_id_", "AbilityContainer_" }
local TEXT_HINT = { "Name", "Label", "Text", "Title", "Description", "Level", "Order", "Count", "Timer" }

local function id_has(id, hints)
	for _, h in ipairs(hints) do
		if id:find(h, 1, true) then return true end
	end
	return false
end

local function image_src(panel)
	local panel_type = try_call(panel, "GetPanelType")
	if panel_type ~= "Image" then return nil end
	local src = try_call(panel, "GetImageSrc")
	return type(src) == "string" and src ~= "" and src or nil
end

local function panel_attribute(panel, key)
	local ok, value = pcall(function() return panel:GetAttribute(key, "") end)
	return ok and type(value) == "string" and value ~= "" and value or nil
end

local function panel_classes(panel)
	local classes = try_call(panel, "GetClassList")
	if type(classes) ~= "table" then return "" end
	return table.concat(classes, ",")
end

local function diagnostic_panel(panel)
	if not panel then return "<missing>" end
	local id = try_call(panel, "GetID")
	id = (type(id) == "string" and id ~= "") and id or "-"
	local result = id .. " type=" .. tostring(try_call(panel, "GetPanelType"))
	local classes = panel_classes(panel)
	if classes ~= "" then result = result .. " classes=" .. classes end
	result = result .. (try_call(panel, "IsVisible") == false and " hidden" or " visible")
	local src = image_src(panel)
	if src then result = result .. " src=" .. src end
	for _, key in ipairs({
		"ability_name", "abilityname", "ability", "name", "ability_id",
		"image", "image_src", "src", "source", "value", "selected_ability",
	}) do
		local value = panel_attribute(panel, key)
		if value then result = result .. " " .. key .. "=" .. value end
	end
	if try_call(panel, "GetPanelType") == "Label" then
		local text = try_call(panel, "GetText")
		if type(text) == "string" and text ~= "" then result = result .. " text=" .. text end
	end
	return result
end

-- opts.skip: set of ids whose subtree is not entered (still reported once);
-- opts.guard: only probe GetImageSrc on panels whose id looks image-related.
local function traverse(root, visit, limit, all, opts)
	local nodes, chain = 0, {}
	local skip = opts and opts.skip
	local guard = opts and opts.guard
	local function rec(panel, depth)
		if nodes >= limit then return end
		nodes = nodes + 1
		local id = panel:GetID()
		id = (type(id) == "string" and id ~= "") and id or "-"
		local src = (not guard or id_has(id, IMG_HINT)) and image_src(panel) or nil
		local count = tonumber(panel:GetChildCount()) or 0
		local visible = panel:IsVisible() ~= false
		visit(panel, id, src, count, visible, depth, chain)
		if (not visible and not all) or depth >= K.MAX_DEPTH or (skip and skip[id]) then return end
		chain[#chain + 1] = id
		for i = 0, count - 1 do
			local child = child_at(panel, i)
			if child then rec(child, depth + 1) end
		end
		chain[#chain] = nil
	end
	rec(root, 0)
	return nodes
end

local function icon_name(src)
	local name = src:match("spellicons/([%w_]+)")
	if not name then return nil end
	return (name:gsub("_png$", ""):gsub("%.png$", ""))
end

local function sorted_ids(set)
	local list = {}
	for id in pairs(set) do list[#list + 1] = id end
	table.sort(list)
	return list
end

local function norm(text)
	if type(text) ~= "string" then return nil end
	return (text:gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

local function src_id(panel)
	local src = image_src(panel)
	if not src then return nil end
	local name = icon_name(src)
	return name and D.short[name] or nil
end

local function ability_name_id(value)
	if type(value) ~= "string" or value == "" then return nil end
	local by_name = D.short[value]
	if by_name then return by_name end
	local numeric = tonumber(value)
	return numeric and D.abil[numeric] and numeric or nil
end

local function ability_panel_id(panel)
	for _, key in ipairs({ "ability_name", "abilityname", "ability", "name", "ability_id" }) do
		local id = ability_name_id(panel_attribute(panel, key))
		if id then return id end
	end
	return src_id(panel)
end

local function slot_ability_id(slot)
	local seen_panels, found = {}, nil
	local function scan(panel, depth)
		if not panel or depth > 6 or seen_panels[panel] then return end
		seen_panels[panel] = true
		found = ability_panel_id(panel)
		if found then return end
		local count = math.min(tonumber(panel:GetChildCount()) or 0, 12)
		for i = 0, count - 1 do
			scan(child_at(panel, i), depth + 1)
			if found then return end
		end
	end
	scan(slot, 0)
	return found
end

local function row_name(row)
	local label = row:FindChildTraverse(K.PANELS.NAME)
	if not label or try_call(label, "GetPanelType") ~= "Label" then return nil end
	return norm(try_call(label, "GetText"))
end

local function row_picks(row)
	local list = {}
	local box = row:FindChildTraverse(K.PANELS.ABILITIES)
	if not box then return list end
	local seen = {}
	for i = 0, (tonumber(box:GetChildCount()) or 0) - 1 do
		local slot = child_at(box, i)
		local id = slot and slot_ability_id(slot)
		if id and not seen[id] then
			seen[id] = true
			list[#list + 1] = id
		end
	end
	return list
end

local function team_index(my_id, team)
	local ids = {}
	for _, p in ipairs(Players.GetAll()) do
		if Entity.GetTeamNum(p) == team then ids[#ids + 1] = Player.GetPlayerID(p) end
	end
	table.sort(ids)
	for i, id in ipairs(ids) do
		if id == my_id then return i end
	end
	return nil
end

function reader.set(pool, mine, enemy, total)
	local skipped = sorted_ids(S.skipped)
	local sig = table.concat(pool, ",") .. "|" .. table.concat(mine, ",") .. "|"
		.. table.concat(enemy, ",") .. "|" .. total .. "|" .. tostring(ui.role and tonumber(ui.role:Get()) or 0)
		.. "|" .. table.concat(skipped, ",") .. "|" .. tostring(reader.model) .. "|" .. reader.phase .. "|" .. (reader.owned_sig or "") .. "|" .. (reader.extra_sig or "")
	if sig == reader.sig then return end
	reader.sig, reader.pool, reader.mine, reader.enemy, reader.total = sig, pool, mine, enemy, total
	reader.active = total >= K.MIN_POOL or reader.phase == "game"
	local ranked_pool = {}
	for _, id in ipairs(pool) do
		if not S.skipped[id] then ranked_pool[#ranked_pool + 1] = id end
	end
	R = engine.run(ranked_pool, mine, enemy)
	V.dirty = true
	if ui.debug and ui.debug:Get() and R.build and R.build.arch then
		local parts = {}
		for _, stage in ipairs({ "early", "core", "late" }) do
			local names = {}
			for _, e in ipairs(R.build[stage] or {}) do names[#names + 1] = e.item:gsub("^item_", "") end
			parts[#parts + 1] = stage .. "=" .. table.concat(names, ",")
		end
		local sh = R.build.share or {}
		say(string.format("build %s c%.2f m%.2f t%.2f s%.2f %s", R.build.arch, sh.carry or 0, sh.caster or 0, sh.tank or 0,
			sh.support or 0, table.concat(parts, " ")))
	end
	say(string.format("pool changed: %d icons, %d free, %d mine, %d enemy, %d top, phase %s, mine ids %s",
		total, #pool, #mine, #enemy, #R.top, reader.phase, table.concat(mine, ",")))
end

function reader.in_match()
	if not Engine.IsInGame() or not Heroes.GetLocal() then return false end
	local state = GameRules.GetGameState()
	return state >= Enum.GameState.DOTA_GAMERULES_STATE_PRE_GAME and state <= Enum.GameState.DOTA_GAMERULES_STATE_POST_GAME
end

function reader.detect_model(me)
	local model = 0
	if me then
		local ok, td = pcall(Player.GetTeamData, me)
		model = ok and td and math.tointeger(tonumber(td.selected_hero_id) or 0) or 0
	end
	if model ~= reader.model then
		reader.model = model
		say(string.format("own hero model: %d %s%s", model, tostring(data.model_key(model)),
			data.meta_of(model) and "" or " (no model data)"))
	end
end

function reader.hero_abilities(hero, into, seen)
	for i = 0, 23 do
		local ability = NPC.GetAbilityByIndex(hero, i)
		local id = ability and D.short[Ability.GetName(ability)]
		if id and not seen[id] then
			seen[id] = true
			into[#into + 1] = id
		end
	end
end

function reader.game()
	local now = os.clock()
	if now < (reader.game_next or 0) then return end
	reader.game_next = now + K.GAME_SCAN_EVERY
	local hero = Heroes.GetLocal()
	if not hero or not Entity.IsEntity(hero) then return end
	local mine, enemy, seen = {}, {}, {}
	reader.hero_abilities(hero, mine, {})
	reader.known = reader.known or {}
	for _, other in ipairs(Heroes.GetAll()) do
		if other ~= hero and Entity.IsEntity(other) and not Entity.IsSameTeam(hero, other)
			and not NPC.IsIllusion(other) and not Entity.IsDormant(other) then
			local list = {}
			reader.hero_abilities(other, list, {})
			if #list > 0 then reader.known[Hero.GetPlayerID(other)] = list end
		end
	end
	for _, list in pairs(reader.known) do
		for _, id in ipairs(list) do
			if not seen[id] then
				seen[id] = true
				enemy[#enemy + 1] = id
			end
		end
	end
	table.sort(mine)
	table.sort(enemy)
	local owned, names = {}, {}
	local b = R.build or {}
	for _, list in ipairs({ b.early or {}, b.core or {}, b.late or {}, b.aghs or {}, b.counter or {} }) do
		for _, e in ipairs(list) do
			if e.item and not owned[e.item] and NPC.HasItem(hero, e.item) then
				owned[e.item] = true
				names[#names + 1] = e.item
			end
		end
	end
	table.sort(names)
	reader.owned, reader.owned_sig = owned, table.concat(names, ",")
	reader.detect_model(Players.GetLocal())
	reader.set({}, mine, enemy, 0)
end

function reader.set_phase(phase)
	if phase == reader.phase then return end
	reader.phase = phase
	reader.cards = nil
	say("phase: " .. phase)
	V.dirty = true
end

function reader.scan()
	local root = Panorama.GetPanelByName("PreGame", false)
	local pregame = (root and root:IsValid() and root:IsVisible()) and true or false
	local match = reader.in_match()
	reader.visible = pregame and not match
	local screen_state = reader.visible and "visible" or "missing"
	if screen_state ~= reader.screen_state then
		reader.screen_state = screen_state
		say("PreGame screen " .. screen_state)
	end
	if match then
		reader.set_phase("game")
		if D.ready then reader.game() end
		return
	end
	if not reader.visible then
		reader.set_phase("none")
		reader.known, reader.owned, reader.owned_sig = nil, nil, nil
		reader.board, reader.taken_models, reader.extra_sig = nil, nil, nil
		if reader.total ~= 0 or #reader.mine > 0 then reader.set({}, {}, {}, 0) end
		return
	end
	reader.set_phase("draft")
	if not D.ready then return end

	local pool_set, total, slots, named, draft_flags = {}, 0, 0, 0, {}
	local chosen = {}
	local tagged = Engine.RunScript(K.TAG_JS, root)
	if tagged ~= reader.tagged then
		reader.tagged = tagged
		say("drafted slot tagging: " .. (tagged and "ok" or "failed"))
	end
	local hits = {}
	hits[1] = root:FindChildTraverse(K.PANELS.POOL)
	hits[2] = root:FindChildTraverse(K.PANELS.ULT_POOL)
	local pool_state = (hits[1] and hits[2]) and "found" or ((hits[1] or hits[2]) and "partial" or "missing")
	if pool_state ~= reader.pool_state then
		reader.pool_state = pool_state
		say("ability pool panels " .. pool_state)
	end
	local debug = ui.debug:Get()
	local cards = reader.cards
	if cards and os.clock() > reader.cards_until then cards = nil end
	if cards then
		for _, c in ipairs(cards) do
			if not c.card:IsValid() then
				cards = nil
				break
			end
		end
	end
	if cards then
		for _, c in ipairs(cards) do
			if not pool_set[c.id] then
				pool_set[c.id] = true
				total = total + 1
			end
			if c.card:HasClass("AbilityChosen") then chosen[c.id] = true end
		end
	else
		local found = {}
		for i = 1, 2 do
			local hit = hits[i]
			if hit then
				traverse(hit, function(panel, panel_id, src)
					slots = slots + 1
					if debug and panel_id:match("^AbilityContainer_") and panel:HasClass("AbilityChosen") then
						draft_flags[#draft_flags + 1] = "chosen:" .. panel_id
					end
					local name = panel_id:match("^ability_id_") and panel_attribute(panel, "ability_name") or nil
					if name then
						named = named + 1
					elseif src then
						named = named + 1
						name = icon_name(src)
					end
					local id = name and D.short[name]
					if id then
						local parent = panel:GetParent()
						if parent then
							found[#found + 1] = { card = parent, id = id }
							if parent:HasClass("AbilityChosen") then chosen[id] = true end
						end
					end
					if id and not pool_set[id] then
						pool_set[id] = true
						total = total + 1
					end
				end, 600, true, { guard = true })
			end
		end
		if total >= K.MIN_POOL and #found > 0 then
			reader.cards, reader.cards_until = found, os.clock() + K.CARDS_TTL
		else
			reader.cards = nil
		end
		local slot_sig = slots .. ":" .. named
		if slot_sig ~= reader.slot_sig then
			reader.slot_sig = slot_sig
			say(string.format("ability pool scan: %d panels, %d ability names, %d known",
				slots, named, total))
		end
	end

	local me = Players.GetLocal()
	local my_name = me and norm(Player.GetName(me))
	local my_team = me and Entity.GetTeamNum(me)
	local my_id = me and Player.GetPlayerID(me)
	local taken, mine_set, enemy_set, how = {}, {}, {}, "none"
	local foes = {}
	local sides = {
		{ K.PANELS.RADIANT, Enum.TeamNum.TEAM_RADIANT },
		{ K.PANELS.DIRE, Enum.TeamNum.TEAM_DIRE },
	}
	for _, side in ipairs(sides) do
		local team = root:FindChildTraverse(side[1])
		if team then
			local count = tonumber(team:GetChildCount()) or 0
			local own = my_team == side[2]
			local mine_row
			if own then
				for i = 0, count - 1 do
					local row = child_at(team, i)
					if row and my_name and row_name(row) == my_name then
						mine_row, how = i, "name"
						break
					end
				end
				if not mine_row then
					local index = team_index(my_id, my_team)
					if index then mine_row, how = index - 1, "index" end
				end
			end
			for i = 0, count - 1 do
				local row = child_at(team, i)
				if row then
					local abilities = row:FindChildTraverse(K.PANELS.ABILITIES)
					if abilities then
						for slot_index = 0, (tonumber(abilities:GetChildCount()) or 0) - 1 do
							local slot = child_at(abilities, slot_index)
							if slot and debug then
								local function collect_drafted(panel, depth)
									if not panel or depth > 4 then return end
									local classes = panel_classes(panel)
									if classes:find("AbilityDrafted", 1, true) then
										draft_flags[#draft_flags + 1] = string.format("drafted:%s:%d:%d:%s",
											side[1], i, slot_index, diagnostic_panel(panel))
									end
									for child_index = 0, (tonumber(panel:GetChildCount()) or 0) - 1 do
										collect_drafted(child_at(panel, child_index), depth + 1)
									end
								end
								collect_drafted(slot, 0)
							end
						end
					end
					local picks = row_picks(row)
					for _, id in ipairs(picks) do
						taken[id] = true
						if own and i == mine_row then mine_set[id] = true end
						if my_team and not own then enemy_set[id] = true end
					end
					if my_team and not own and #picks > 0 then
						foes[#foes + 1] = { name = row_name(row) or string.format("#%d", #foes + 1), ids = picks }
					end
				end
			end
		end
	end
	if how ~= reader.how then
		reader.how = how
		dbg("own row found by: " .. how)
	end
	local board = {}
	for id in pairs(pool_set) do board[id] = true end
	for id in pairs(taken) do board[id] = true end
	reader.board = sorted_ids(board)
	for id in pairs(taken) do pool_set[id] = nil end
	for id in pairs(chosen) do pool_set[id] = nil end
	local picked = 0
	for id in pairs(taken) do if not chosen[id] then picked = picked + 1 end end
	for _ in pairs(chosen) do picked = picked + 1 end
	reader.picked = picked
	reader.detect_model(me)
	local models, model_list = {}, {}
	local ok_all, players = pcall(Players.GetAll)
	for _, p in ipairs(ok_all and players or {}) do
		if p ~= me then
			local ok_td, td = pcall(Player.GetTeamData, p)
			local h = ok_td and td and math.tointeger(tonumber(td.selected_hero_id) or 0) or 0
			if h > 0 and not models[h] then
				models[h] = true
				model_list[#model_list + 1] = h
			end
		end
	end
	table.sort(model_list)
	reader.taken_models = models
	reader.extra_sig = table.concat(reader.board, ",") .. "/" .. table.concat(model_list, ",")
	reader.foes = foes
	reader.set(sorted_ids(pool_set), sorted_ids(mine_set), sorted_ids(enemy_set), total)
	table.sort(draft_flags)
	local draft_sig = table.concat(draft_flags, "|")
	if dump_tree and ui.debug:Get() and total >= K.MIN_POOL and draft_sig ~= reader.diagnostic_sig then
		local ok, err = pcall(dump_tree)
		if ok then
			reader.diagnostic_sig = draft_sig
		else
			say("automatic diagnostics dump failed: " .. tostring(err))
		end
	end
end

local function persist_skips()
	local ids = sorted_ids(S.skipped)
	local values = {}
	for _, id in ipairs(ids) do values[#values + 1] = tostring(id) end
	Config.WriteString("ability_draft_helper", "skip", table.concat(values, ","))
	S.skip_n = #ids
end

do
	local stored = Config.ReadString("ability_draft_helper", "skip", "")
	for value in stored:gmatch("%d+") do
		local id = tonumber(value)
		if id and id > 0 and id % 1 == 0 then S.skipped[id] = true end
	end
	S.skip_n = #sorted_ids(S.skipped)
end

function S.toggle_skip(id)
	id = tonumber(id)
	if not id or id <= 0 or id % 1 ~= 0 then return end
	if S.skipped[id] then
		S.skipped[id] = nil
	else
		S.skipped[id] = true
	end
	persist_skips()
	reader.set(reader.pool, reader.mine, reader.enemy, reader.total)
	V.dirty = true
end

function S.clear_skip()
	S.skipped = {}
	persist_skips()
	reader.set(reader.pool, reader.mine, reader.enemy, reader.total)
	V.dirty = true
end

function reader.pick(id)
	local rec = D.abil[id]
	if reader.phase ~= "draft" or not rec or not rec.short:match("^[%w_]+$") then return end
	local root = Panorama.GetPanelByName("PreGame", false)
	if not root or not root:IsValid() then return end
	local ok = Engine.RunScript(K.PICK_JS:format(rec.short), root)
	reader.next = 0
	say(string.format("pick %s: script %s", rec.short, ok and "sent" or "failed"))
end

function reader.refresh()
	engine.invalidate()
	reader.set(reader.pool, reader.mine, reader.enemy, reader.total)
	V.dirty = true
end

function reader.tick()
	local now = os.clock()
	if now < reader.next then return end
	reader.next = now + K.SCAN_EVERY
	local ok, err = pcall(reader.scan)
	if not ok then say("scan failed: " .. tostring(err)) end
end

dump_tree = function()
	local root = Panorama.GetPanelByName("PreGame", false)
	if not root or not root:IsValid() then
		say("PreGame panel not found, open the draft screen first")
		return
	end
	local lines, icons, diagnostics = {}, {}, { "== DRAFT STATE DIAGNOSTICS ==" }
	local me = Players.GetLocal()
	local my_name = me and norm(Player.GetName(me)) or "<unknown>"
	local my_team = me and Entity.GetTeamNum(me) or "<unknown>"
	diagnostics[#diagnostics + 1] = string.format("local player=%s team=%s", tostring(my_name), tostring(my_team))

	for _, side in ipairs({
		{ name = "Radiant", id = K.PANELS.RADIANT },
		{ name = "Dire", id = K.PANELS.DIRE },
	}) do
		local team = root:FindChildTraverse(side.id)
		diagnostics[#diagnostics + 1] = "TEAM " .. side.name .. " " .. diagnostic_panel(team)
		if team then
			for i = 0, (tonumber(team:GetChildCount()) or 0) - 1 do
				local row = child_at(team, i)
				if row then
					local name = row_name(row) or "<unknown>"
					diagnostics[#diagnostics + 1] = string.format("ROW %s[%d] name=%s%s", side.name, i, name,
						norm(name) == my_name and " LOCAL" or "")
					local abilities = row:FindChildTraverse(K.PANELS.ABILITIES)
					diagnostics[#diagnostics + 1] = "  " .. diagnostic_panel(abilities)
					if abilities then
						for j = 0, (tonumber(abilities:GetChildCount()) or 0) - 1 do
							local slot = child_at(abilities, j)
							if slot then
								diagnostics[#diagnostics + 1] = string.format("  SLOT[%d] %s parsed_id=%s",
									j, diagnostic_panel(slot), tostring(slot_ability_id(slot) or "<unresolved>"))
								local child_count = tonumber(slot:GetChildCount()) or 0
								for k = 0, child_count - 1 do
									local child = child_at(slot, k)
									if child then
										diagnostics[#diagnostics + 1] = "    CHILD " .. diagnostic_panel(child)
										for n = 0, (tonumber(child:GetChildCount()) or 0) - 1 do
											local grandchild = child_at(child, n)
											if grandchild then
												diagnostics[#diagnostics + 1] = "      GRANDCHILD " .. diagnostic_panel(grandchild)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	for _, panel_id in ipairs({ K.PANELS.POOL, K.PANELS.ULT_POOL }) do
		local pool = root:FindChildTraverse(panel_id)
		diagnostics[#diagnostics + 1] = "POOL " .. panel_id .. " " .. diagnostic_panel(pool)
		if pool then
			traverse(pool, function(panel, id)
				if id:match("^AbilityContainer_") then
					local classes = panel_classes(panel)
					local ability
					for i = 0, (tonumber(panel:GetChildCount()) or 0) - 1 do
						local child = child_at(panel, i)
						if child and try_call(child, "GetPanelType") == "DOTAAbilityImage" then
							ability = diagnostic_panel(child)
							break
						end
					end
					diagnostics[#diagnostics + 1] = string.format("CARD %s classes=%s%s",
						id, classes, ability and " | " .. ability or "")
				end
			end, 600, true, { guard = true })
		end
	end

	traverse(root, function(panel, id, src, count, visible, depth, chain)
		if #lines >= K.DUMP_LINES then return end
		local line = string.rep("  ", depth) .. id .. " [" .. count .. "]"
		local slot_context = false
		for _, ancestor in ipairs(chain) do
			if ancestor == "HeroAbilityContainer" or ancestor:match("^DraftedAbilityContainer") then
				slot_context = true
				break
			end
		end
		if id:match("^AbilityContainer_") or id:match("^ability_id_") or slot_context then
			line = line .. " type=" .. tostring(try_call(panel, "GetPanelType"))
			local classes = try_call(panel, "GetClassList")
			if type(classes) == "table" and #classes > 0 then
				line = line .. " classes=" .. table.concat(classes, ",")
			end
			for _, key in ipairs({ "ability_name", "abilityname", "ability", "name", "ability_id" }) do
				local value = panel_attribute(panel, key)
				if value then line = line .. " " .. key .. "=" .. value end
			end
			if src then
				line = line .. " src=" .. src
			end
		end
		if not visible then line = line .. " hidden" end
		if src then
			line = line .. " src=" .. src
			local name = icon_name(src)
			if name then
				local from = math.max(1, #chain - 5)
				icons[#icons + 1] = name .. (D.short[name] and "" or " (unknown ability)") .. "  <-  " .. table.concat(chain, "/", from) .. "/" .. id
			end
		end
		if try_call(panel, "GetPanelType") == "Label" and (id_has(id, TEXT_HINT) or id == "-") then
			local text = try_call(panel, "GetText")
			if type(text) == "string" and text ~= "" then line = line .. " text=" .. text end
		end
		lines[#lines + 1] = line
	end, K.DUMP_LINES, true, { skip = K.DUMP_SKIP, guard = true })
	-- direct children of PreGame first, so a truncated dump still shows every top-level branch
	local top = { "== PREGAME CHILDREN ==" }
	for i = 0, (tonumber(root:GetChildCount()) or 0) - 1 do
		local child = child_at(root, i)
		if child then
			local cid = child:GetID()
			cid = (type(cid) == "string" and cid ~= "") and cid or "-"
			top[#top + 1] = string.format("%d %s [%d]%s", i, cid, tonumber(child:GetChildCount()) or 0, child:IsVisible() == false and " hidden" or "")
		end
	end
	local parts = { "== SPELLICONS FOUND: " .. #icons .. " ==" }
	for _, line in ipairs(top) do parts[#parts + 1] = line end
	for _, line in ipairs(icons) do parts[#parts + 1] = line end
	for _, line in ipairs(diagnostics) do parts[#parts + 1] = line end
	parts[#parts + 1] = "== TREE: " .. #lines .. " lines =="
	for _, line in ipairs(lines) do parts[#parts + 1] = line end
	local saved = write_file(K.TREE, table.concat(parts, "\n"))
	say(string.format("tree dumped: %d lines, %d icons, saved=%s, file configs/%s", #lines, #icons, tostring(saved), K.TREE))
end

-- ===========================================================================
-- Panel UI (immediate-mode, same toolkit as Script Manager / Draft Helper)
-- ===========================================================================

local ROUND = Enum.DrawFlags.RoundCornersAll
local KEY = Enum.ButtonCode

local function ease_out(t) return 1 - (1 - t) * (1 - t) end
local function ease_in_out(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end

local U = {
	CFG = "ability_draft_helper",
	ICON = "panorama/images/spellicons/%s_png.vtex_c",
	W = 440, HEAD = 62, ROLE = 46, TABS = 40, FOOT = 38,
	PAD = 12, SB = 16,
	MAXH = 660, MIN_BODY = 96,
	CARD_LOAD = 128, CARD_WAIT = 152,
	SET_H = 430,
	SCALE_MIN = 70, SCALE_MAX = 150, TEXT_MIN = 90, TEXT_MAX = 125, WHEEL = 64,
	DOUBLE = 0.35, TIP_DELAY = 0.22, TIP_W = 290,
	G = {
		gear = "\u{f013}", close = "\u{f00d}", up = "\u{f077}", down = "\u{f078}", warn = "\u{f071}",
		undo = "\u{f0e2}", check = "\u{f00c}", wait = "\u{f254}", bolt = "\u{f0e7}", star = "\u{f005}",
	},
}

local TABS = { "picks", "combos", "counters", "build" }
local TABS_DRAFT = { "picks", "combos", "counters" }
local TABS_GAME = { "build" }
local TAB_LABEL = { picks = "adh_tab_picks", combos = "adh_tab_combos", counters = "adh_tab_counters", build = "adh_tab_build" }
local ROLE_LABEL = {
	"adh_rs_off", "adh_rs_carry", "adh_rs_mid", "adh_rs_offlane", "adh_rs_support", "adh_rs_hard_support",
}

local THEME_ORDER = { "graphite", "midnight", "purple", "forest", "oled" }
local THEMES = {
	graphite = { win = { 25, 25, 27 }, card = { 34, 34, 37 }, menu = { 42, 42, 46 }, off = { 58, 58, 63 } },
	midnight = { win = { 17, 20, 31 }, card = { 25, 30, 45 }, menu = { 34, 40, 58 }, off = { 52, 60, 84 } },
	purple = { win = { 22, 17, 32 }, card = { 32, 25, 47 }, menu = { 46, 36, 67 }, off = { 62, 49, 88 } },
	forest = { win = { 17, 25, 21 }, card = { 24, 35, 29 }, menu = { 37, 52, 44 }, off = { 52, 70, 60 } },
	oled = { win = { 0, 0, 0 }, card = { 15, 15, 17 }, menu = { 28, 28, 31 }, off = { 44, 44, 48 } },
}

local ACCENT_ORDER = { "blue", "teal", "green", "purple", "orange", "red", "pink" }
local ACCENTS = {
	blue = { 76, 130, 247 }, teal = { 38, 166, 154 }, green = { 52, 168, 83 }, purple = { 138, 99, 210 },
	orange = { 240, 140, 40 }, red = { 226, 75, 75 }, pink = { 232, 90, 150 },
}

local T = {
	t1 = { 250, 250, 252 }, t2 = { 218, 218, 224 }, t3 = { 180, 180, 188 }, t4 = { 148, 148, 156 },
	white = { 255, 255, 255 }, black = { 0, 0, 0 }, dark = { 17, 17, 19 }, knob = { 142, 142, 147 },
	green = { 104, 214, 126 }, red = { 255, 128, 120 }, yellow = { 255, 218, 40 }, cyan = { 96, 212, 232 },
}

local function save(key, value)
	if type(value) == "number" then
		Config.WriteInt(U.CFG, key, math.floor(value))
	else
		Config.WriteString(U.CFG, key, value)
	end
end

local function valid(list, v, default)
	for _, o in ipairs(list) do
		if o == v then return v end
	end
	return default
end

local P = {
	alpha = 0, wx = nil, wy = nil, h = 0, dt = 0, now = 0,
	tweens = {}, swaps = {}, press = nil, drag = nil, resize = nil, slide = nil, sb_drag = nil, moved = false,
	scroll = 0, scroll_to = 0, scroll_f = 0, scroll_t = -10, content_h = 0, view_h = 0, area = { 0, 0, 0, 0 },
	page_key = "", items = nil, items_lang = "", tip = nil, tip_last = nil,
	hover_item = nil, hover_prev = nil, hover_since = 0, hover_y = 0,
	last_click = { id = nil, t = -10 }, draw_error = nil, settings = false,
	tab = Config.ReadString(U.CFG, "tab", "picks"),
	set = {
		theme = Config.ReadString(U.CFG, "theme", "graphite"),
		accent = Config.ReadString(U.CFG, "accent", "blue"),
		opacity = Config.ReadInt(U.CFG, "opacity", 94),
		blur = Config.ReadInt(U.CFG, "blur", 1) == 1,
		compact = Config.ReadInt(U.CFG, "compact", 0) == 1,
		icons = Config.ReadInt(U.CFG, "icons", 1) == 1,
		scale = Config.ReadInt(U.CFG, "scale", 100),
		text = Config.ReadInt(U.CFG, "text", 100),
		shadow = Config.ReadInt(U.CFG, "shadow", 1) == 1,
		collapsed = Config.ReadInt(U.CFG, "collapsed", 0) == 1,
	},
}

P.tab = valid(TABS_DRAFT, P.tab, "picks")
P.set.theme = valid(THEME_ORDER, P.set.theme, "graphite")
P.set.accent = valid(ACCENT_ORDER, P.set.accent, "blue")
P.set.opacity = clamp(P.set.opacity, 40, 100)
P.set.scale = clamp(P.set.scale, U.SCALE_MIN, U.SCALE_MAX)
P.set.text = clamp(P.set.text, U.TEXT_MIN, U.TEXT_MAX)

local C = {}
local A, AT = { 76, 130, 247 }, { 127, 166, 255 }

local function copy_theme(dst, src)
	for name, v in pairs(src) do dst[name] = { v[1], v[2], v[3] } end
	return dst
end

copy_theme(C, THEMES[P.set.theme])

local function apply_accent(id)
	local a = ACCENTS[id]
	for i = 1, 3 do
		A[i] = a[i]
		AT[i] = math.floor(a[i] + (255 - a[i]) * 0.35 + 0.5)
	end
end

apply_accent(P.set.accent)

local fade = { theme = { k = 1 }, accent = { k = 1 } }

local function fade_theme(id)
	fade.theme = { k = 0, from = copy_theme({}, C), to = THEMES[id] }
end

local function fade_accent(id)
	fade.accent = { k = 0, from = { A[1], A[2], A[3] }, to = ACCENTS[id] }
end

local function fade_tick(dt)
	local t = fade.theme
	if t.k < 1 then
		t.k = math.min(1, t.k + dt / 0.32)
		local e = ease_in_out(t.k)
		for name, v in pairs(t.to) do
			local f = t.from[name]
			for i = 1, 3 do C[name][i] = f[i] + (v[i] - f[i]) * e end
		end
	end
	local a = fade.accent
	if a.k < 1 then
		a.k = math.min(1, a.k + dt / 0.32)
		local e = ease_in_out(a.k)
		for i = 1, 3 do
			local v = a.from[i] + (a.to[i] - a.from[i]) * e
			A[i] = math.floor(v + 0.5)
			AT[i] = math.floor(v + (255 - v) * 0.35 + 0.5)
		end
	end
end

-- ---------------------------------------------------------------------------
-- assets, text cache, drawing primitives
-- ---------------------------------------------------------------------------

local asset = { fonts = {}, sizes = {}, images = {}, dims = {}, budget = 3, size_n = 0 }

function asset.font(weight)
	local f = asset.fonts[weight]
	if not f then
		f = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, weight)
		asset.fonts[weight] = f
	end
	return f
end

function asset.icons()
	local f = asset.fonts.icon
	if not f then
		f = Render.LoadFont("FontAwesomeEx", Enum.FontCreate.FONTFLAG_ANTIALIAS, 400)
		asset.fonts.icon = f
	end
	return f
end

function asset.size(font, px, str)
	local by_font = asset.sizes[font]
	if not by_font then
		by_font = {}
		asset.sizes[font] = by_font
	end
	local by_px = by_font[px]
	if not by_px then
		by_px = {}
		by_font[px] = by_px
	end
	local v = by_px[str]
	if not v then
		if asset.size_n >= 6000 then asset.sizes, asset.size_n, by_px = {}, 0, {} end
		v = Render.TextSize(font, px, str)
		by_px[str] = v
		asset.size_n = asset.size_n + 1
	end
	return v
end

-- a few image loads per frame at most, so opening the draft screen never hitches
function asset.image(path)
	local img = asset.images[path]
	if img == nil then
		if asset.budget <= 0 then return nil end
		asset.budget = asset.budget - 1
		img = Render.LoadImage(path)
		if not img or img == 0 then img = false end
		asset.images[path] = img
	end
	return img or nil
end

function asset.ability(short)
	return asset.image(U.ICON:format(short))
end

asset.names = {}

function asset.npc(model)
	if model <= 0 then return nil end
	local key = "npc:" .. model
	local v = asset.names[key]
	if v == nil then
		v = Engine.GetHeroNameByID(model) or false
		asset.names[key] = v
	end
	return v or nil
end

function asset.item_name(name)
	local v = asset.names[name]
	if not v then
		local ok, found = pcall(GameLocalizer.FindItem, name)
		v = (ok and type(found) == "string" and found ~= "") and found
			or (name:gsub("^item_", ""):gsub("_", " "):gsub("^%l", string.upper))
		asset.names[name] = v
	end
	return v
end

function asset.hero_name(model)
	local key = "hero:" .. tostring(model)
	local v = asset.names[key]
	if not v then
		local npc = asset.npc(model)
		local ok, found = false, nil
		if npc then ok, found = pcall(GameLocalizer.FindNPC, npc) end
		v = (ok and type(found) == "string" and found ~= "") and found
			or data.model_key(model) or "?"
		if v ~= "?" then asset.names[key] = v end
	end
	return v
end

local g = { x = 0, y = 0, s = 1, a = 1, depth = 0, cache_s = 0, fits = {}, wraps = {}, clips = {}, fit_n = 0 }
local hit = { list = {}, prev = {}, hover = nil, clip = nil }

function g.reset()
	for _ = 1, g.depth do Render.PopClip() end
	g.depth, g.clips, g.a = 0, {}, 1
	hit.clip = nil
end

function g.rescale(s)
	local key = tostring(s) .. ":" .. tostring(P.set.text)
	if g.cache_s == key then return end
	g.cache_s, g.fits, g.wraps, g.fit_n = key, {}, {}, 0
end

function g.px(x) return math.floor(g.x + x * g.s + 0.5) end
function g.py(y) return math.floor(g.y + y * g.s + 0.5) end
function g.v(x, y) return Vec2(g.px(x), g.py(y)) end
function g.fs(size) return math.max(1, math.floor(size * g.s + 0.5)) end
function g.tz(size) return math.max(1, math.floor(size * g.s * P.set.text / 100 + 0.5)) end
function g.hair() return math.max(1, math.floor(g.s)) end

function g.col(c, a)
	return Color(math.floor(c[1] + 0.5), math.floor(c[2] + 0.5), math.floor(c[3] + 0.5),
		math.floor(clamp((c[4] or 255) * (a or 1) * g.a, 0, 255) + 0.5))
end

function g.rect(x, y, w, h, c, r, a, flags)
	Render.FilledRect(g.v(x, y), g.v(x + w, y + h), g.col(c, a), (r or 0) * g.s, flags or ROUND)
end

function g.frame(x, y, w, h, c, r, a, t)
	Render.Rect(g.v(x, y), g.v(x + w, y + h), g.col(c, a), (r or 0) * g.s, ROUND, (t or 1) * g.s)
end

function g.hl(x, y, w, c, a)
	local y0 = g.py(y)
	Render.FilledRect(Vec2(g.px(x), y0), Vec2(g.px(x + w), y0 + g.hair()), g.col(c, a))
end

function g.line(x1, y1, x2, y2, c, a, t)
	Render.Line(Vec2(g.x + x1 * g.s, g.y + y1 * g.s), Vec2(g.x + x2 * g.s, g.y + y2 * g.s), g.col(c, a), (t or 1) * g.s)
end

function g.dot(cx, cy, r, c, a)
	Render.FilledCircle(Vec2(g.x + cx * g.s, g.y + cy * g.s), r * g.s, g.col(c, a), 0, 1, 24)
end

function g.ring(cx, cy, r, c, a, t, start, pct)
	local full = (pct or 1) >= 1
	Render.Circle(Vec2(g.x + cx * g.s, g.y + cy * g.s), r * g.s, g.col(c, a), t * g.s, start or 270, pct or 1, not full, 48)
end

function g.width(weight, size, str)
	return asset.size(asset.font(weight), g.tz(size), str).x / g.s
end

function g.text(weight, size, str, x, cy, c, a, align)
	local font, px = asset.font(weight), g.tz(size)
	local ts = asset.size(font, px, str)
	local tx0 = g.x + x * g.s
	if align == "r" then tx0 = tx0 - ts.x elseif align == "c" then tx0 = tx0 - ts.x / 2 end
	local px0 = math.floor(tx0 + 0.5)
	local py0 = math.floor(g.y + cy * g.s - ts.y / 2 + 0.5)
	if P.set.shadow then
		local o = math.max(1, math.floor(g.s + 0.5))
		Render.Text(font, px, str, Vec2(px0 + o, py0 + o), g.col(T.black, 0.6 * (a or 1)))
	end
	Render.Text(font, px, str, Vec2(px0, py0), g.col(c, a))
	return ts.x / g.s
end

function g.glyph(glyph, size, x, cy, c, a)
	local font, px = asset.icons(), g.fs(size)
	local ts = asset.size(font, px, glyph)
	Render.Text(font, px, glyph, Vec2(math.floor(g.x + x * g.s - ts.x / 2 + 0.5), math.floor(g.y + cy * g.s - ts.y / 2 + 0.5)),
		g.col(c, a))
end

-- soft drop shadow made of a few stacked translucent rounded rects
function g.shadow(x, y, w, h, r, a)
	for i = 1, 5 do
		local e = i * 2.5
		g.rect(x - e, y - e + 4, w + e * 2, h + e * 2, T.black, r + e, (a or 0.07) * (1 - (i - 1) / 5))
	end
end

local function chars_of(str)
	local out = {}
	for _, c in utf8.codes(str) do out[#out + 1] = utf8.char(c) end
	return out
end

function g.fit(weight, size, str, max_w)
	local key = weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. str
	local out = g.fits[key]
	if out then return out end
	out = str
	if g.width(weight, size, str) > max_w then
		local chars = chars_of(str)
		out = "…"
		for n = #chars - 1, 1, -1 do
			local s = table.concat(chars, "", 1, n):gsub("%s+$", "") .. "…"
			if g.width(weight, size, s) <= max_w then
				out = s
				break
			end
		end
	end
	if g.fit_n >= 3000 then g.fits, g.fit_n = {}, 0 end
	g.fits[key], g.fit_n = out, g.fit_n + 1
	return out
end

function g.wrap(weight, size, str, max_w)
	local key = weight .. ":" .. size .. ":" .. math.floor(max_w) .. ":" .. str
	local out = g.wraps[key]
	if out then return out end
	out = {}
	local line = ""
	for word in str:gmatch("%S+") do
		local candidate = line == "" and word or line .. " " .. word
		if line ~= "" and g.width(weight, size, candidate) > max_w then
			out[#out + 1] = line
			line = word
		else
			line = candidate
		end
	end
	if line ~= "" then out[#out + 1] = line end
	g.wraps[key] = out
	return out
end

function g.clip(x, y, w, h)
	Render.PushClip(g.v(x, y), g.v(x + w, y + h), true)
	g.depth = g.depth + 1
	g.clips[#g.clips + 1] = hit.clip or false
	hit.clip = { g.x + x * g.s, g.y + y * g.s, g.x + (x + w) * g.s, g.y + (y + h) * g.s }
end

function g.unclip()
	Render.PopClip()
	g.depth = g.depth - 1
	hit.clip = g.clips[#g.clips] or nil
	g.clips[#g.clips] = nil
end

-- ability icon, cropped to a square; a lettered tile while the image is not loaded (or icons are off)
function g.ability(id, x, y, size, a, r)
	local rec = D.abil[id]
	g.square(rec and P.set.icons and asset.ability(rec.short) or nil, rec and rec.name or "?", x, y, size, a, r)
end

function g.item(name, x, y, size, a, r)
	local img = P.set.icons and asset.image(K.ITEM_ICON:format((name:gsub("^item_", "")))) or nil
	g.square(img, asset.item_name(name), x, y, size, a, r)
end

function g.hero(model, x, y, size, a, r)
	local npc = asset.npc(model)
	local img = npc and P.set.icons and asset.image(K.HERO_ICON:format(npc)) or nil
	g.square(img, asset.hero_name(model), x, y, size, a, r)
end

function g.square(img, name, x, y, size, a, r)
	if img then
		local dim = asset.dims[img]
		if not dim then
			dim = Render.ImageSize(img)
			asset.dims[img] = dim
		end
		local u0, v0, u1, v1 = 0, 0, 1, 1
		if dim.x > dim.y and dim.y > 0 then
			local d = (1 - dim.y / dim.x) / 2
			u0, u1 = d, 1 - d
		elseif dim.y > dim.x and dim.x > 0 then
			local d = (1 - dim.x / dim.y) / 2
			v0, v1 = d, 1 - d
		end
		local px = math.floor(size * g.s + 0.5)
		Render.Image(img, g.v(x, y), Vec2(px, px), g.col(T.white, a), r * g.s, ROUND, Vec2(u0, v0), Vec2(u1, v1))
	else
		g.rect(x, y, size, size, T.white, r, 0.10 * (a or 1))
		local first = name:sub(1, (utf8.offset(name, 2) or 2) - 1)
		g.text(700, size * 0.5, first:upper(), x + size / 2, y + size / 2, T.t3, a, "c")
	end
end

-- ---------------------------------------------------------------------------
-- hit testing and animation
-- ---------------------------------------------------------------------------

function hit.begin()
	hit.prev, hit.list, hit.clip = hit.list, {}, nil
	local mx, my = Input.GetCursorPos()
	hit.hover = nil
	for i = #hit.prev, 1, -1 do
		local h = hit.prev[i]
		if mx >= h[1] and mx < h[3] and my >= h[2] and my < h[4] then
			hit.hover = h[5]
			break
		end
	end
	if P.press and P.press.id and hit.hover ~= P.press.id then hit.hover = nil end
	if P.drag or P.resize or P.slide or P.sb_drag then hit.hover = nil end
end

function hit.add(x, y, w, h, id, on)
	local x1, y1, x2, y2 = g.x + x * g.s, g.y + y * g.s, g.x + (x + w) * g.s, g.y + (y + h) * g.s
	if hit.clip then
		x1, y1 = math.max(x1, hit.clip[1]), math.max(y1, hit.clip[2])
		x2, y2 = math.min(x2, hit.clip[3]), math.min(y2, hit.clip[4])
		if x2 <= x1 or y2 <= y1 then return end
	end
	hit.list[#hit.list + 1] = { x1, y1, x2, y2, id, on or {} }
end

function hit.is(id) return hit.hover == id end

function hit.at(mx, my)
	for i = #hit.list, 1, -1 do
		local h = hit.list[i]
		if mx >= h[1] and mx < h[3] and my >= h[2] and my < h[4] then return h end
	end
	return nil
end

local anim = {}

function anim.tween(key, target, time, curve)
	local t = P.tweens[key]
	if not t or (t.seen and P.now - t.seen > 0.1) then
		t = { from = target, to = target, v = target, k = 1 }
		P.tweens[key] = t
	end
	t.seen = P.now
	if t.to ~= target then t.from, t.to, t.k = t.v, target, 0 end
	if t.k < 1 then
		t.k = math.min(1, t.k + P.dt / time)
		t.v = t.from + (t.to - t.from) * (curve or ease_out)(t.k)
	else
		t.v = t.to
	end
	return t.v
end

function anim.snap(key, value)
	P.tweens[key] = { from = value, to = value, v = value, k = 1, seen = P.now }
end

function anim.hover(id)
	return anim.tween("hv:" .. id, hit.hover == id and 1 or 0, 0.12)
end

function anim.mix(a, b, k)
	return { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k }
end

-- translated strings are cached per language; switching the language rebuilds everything
local Lc = { map = {}, lang = "" }

local function tx(key)
	local v = Lc.map[key]
	if v == nil then
		v = L(key)
		Lc.map[key] = v
	end
	return v
end

local function lang_sync()
	local lang = localization.GetLanguage()
	if lang ~= Lc.lang then
		Lc.map, Lc.lang, V.dirty = {}, lang, true
		g.fits, g.wraps, g.fit_n = {}, {}, 0
	end
end

-- ---------------------------------------------------------------------------
-- formatting helpers
-- ---------------------------------------------------------------------------

local function pct(v) return string.format("%.1f%%", v * 100) end
local function gain(v) return string.format("%+.1f%%", v * 100) end

local function wr_color(wr)
	if wr >= 0.525 then return T.green end
	if wr <= 0.475 then return T.red end
	return T.t2
end

local function thousands(n)
	local s = string.format("%d", math.floor((n or 0) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (out:gsub("^%s+", ""))
end

local function owner_of(id)
	local rec = D.abil[id]
	local hero = rec and rec.owner and D.hero[rec.owner]
	return hero and hero.name or nil
end

local function pair_wr(a, b)
	local t = D.pair[a]
	return t and t[b]
end

-- ---------------------------------------------------------------------------
-- list items (rebuilt only when the recommendations change)
-- ---------------------------------------------------------------------------

local view = {}

local function section(list, title, entries, color)
	if #entries == 0 then return end
	list[#list + 1] = { kind = "head", key = "h:" .. title, text = title, n = #entries, c = color }
	for _, e in ipairs(entries) do list[#list + 1] = e end
end

local function pair_item(kind, a, b, d, bad)
	local ids = { a, b }
	local lines = {
		{ nm(a), pct(wr_of(a)), wr_color(wr_of(a)) },
		{ nm(b), pct(wr_of(b)), wr_color(wr_of(b)) },
	}
	local pw = pair_wr(a, b)
	if pw then lines[#lines + 1] = { tx("adh_t_pair"), pct(pw), wr_color(pw) } end
	lines[#lines + 1] = { tx("adh_t_gain"), gain(d), bad and T.red or T.green }
	return {
		kind = "pair", key = kind .. a .. "_" .. b, ids = ids, d = d, bad = bad,
		name = nm(a) .. "  +  " .. nm(b),
		tip = { title = nm(a) .. " + " .. nm(b), lines = lines },
	}
end

local function tri_item(t)
	local lines = {}
	for i = 1, 3 do lines[i] = { nm(t[i]), pct(wr_of(t[i])), wr_color(wr_of(t[i])) } end
	lines[4] = { tx("adh_t_gain"), gain(t.d), T.green }
	return {
		kind = "tri", key = "t" .. t[1] .. "_" .. t[2] .. "_" .. t[3], ids = { t[1], t[2], t[3] }, d = t.d,
		name = nm(t[1]) .. "  +  " .. nm(t[2]) .. "  +  " .. nm(t[3]),
		tip = { title = nm(t[1]) .. " + " .. nm(t[2]) .. " + " .. nm(t[3]), lines = lines },
	}
end

local function syn_lines(lines, title, list, c)
	if not list or #list == 0 then return end
	lines[#lines + 1] = { h = title, c = c }
	for _, e in ipairs(list) do
		local label = e.h and asset.hero_name(e.h) or nm(e.id)
		if e.mine then label = label .. "  ·  " .. tx("adh_t_yours") end
		lines[#lines + 1] = { label, pct(e.wr), c, s = true, mine = e.mine }
	end
end

local function hero_item(m, rank)
	local name = asset.hero_name(m.h)
	local lines = { { tx("adh_t_wr"), pct(m.wr), wr_color(m.wr) } }
	if m.hs and m.hs > 0 then lines[#lines + 1] = { tx("adh_t_hs"), pct(m.hs), wr_color(m.hs) } end
	if m.pr and m.pr > 0 then lines[#lines + 1] = { tx("adh_t_order"), string.format("#%.1f", m.pr) } end
	syn_lines(lines, tx("adh_s_strong_ab"), m.good, T.green)
	syn_lines(lines, tx("adh_s_weak_ab"), m.bad, T.red)
	local names = {}
	for i = 1, math.min(2, #m.good) do names[i] = nm(m.good[i].id) end
	local sub = #names > 0 and string.format(tx("adh_hero_sub"), table.concat(names, ", ")) or tx("adh_hero_sub_none")
	return {
		kind = "hero", key = "hm" .. m.h, h = m.h, rank = rank, wr = m.wr, name = name, sub = sub, good = #names > 0,
		tip = {
			hero = m.h, title = name, sub = tx("adh_t_model_pick"), lines = lines,
			badge = rank == 1 and { tx("adh_badge_model"), T.yellow } or nil,
		},
	}
end

function view.build_items()
	local items = { picks = {}, combos = {}, counters = {}, counts = {} }

	local top_score = R.top[1] and R.top[1].score or 1
	if top_score <= 0 then top_score = 1 end
	for i, r in ipairs(R.top) do
		local name = nm(r.id)
		local owner = owner_of(r.id)
		local sub, sk = owner or "", "plain"
		if r.pick then sub = (sub ~= "" and sub .. "  ·  " or "") .. string.format("#%.0f", r.pick) end
		if r.timing == "wait" then sub = tx("adh_wait") .. "  ·  " .. sub end
		if r.syn then sub, sk = "+ " .. nm(r.with) .. "  " .. gain(r.syn), "syn" end
		local lines = { { tx("adh_t_wr"), pct(r.wr), wr_color(r.wr) } }
		if r.pick then lines[#lines + 1] = { tx("adh_t_order"), string.format("#%.1f", r.pick) } end
		if r.hs then lines[#lines + 1] = { tx("adh_t_hs"), pct(r.hs), wr_color(r.hs) } end
		if r.msyn then
			lines[#lines + 1] = { tx("adh_t_model_syn") .. (r.mwith and (" + " .. nm(r.mwith)) or ""), gain(r.msyn),
				r.msyn >= 0 and T.green or T.red }
		end
		local function note(text, c) lines[#lines + 1] = { t = text, c = c } end
		if r.ag_sc then note(tx("adh_t_ag_sc"), T.cyan) end
		if r.ag_sh then note(tx("adh_t_ag_sh"), T.cyan) end
		if r.unlock then
			note(tx("adh_t_unlock") .. ": " .. tx("adh_up_" .. r.unlock.key) .. "  ·  " .. nm(r.unlock.id), T.yellow)
		end
		if r.timing == "now" then note(tx("adh_t_soon"), T.yellow) end
		if r.timing == "wait" then note(tx("adh_t_later"), T.t3) end
		if r.role_fit then note(tx("adh_t_role") .. ": " .. tx("adh_role_fit"), T.green) end
		if r.role_avoid then note(tx("adh_t_role") .. ": " .. tx("adh_role_avoid"), T.red) end
		if r.fit_why then note(tx("adh_t_model") .. ": " .. tx(r.fit_why), r.fit > 0 and T.green or T.red) end
		if r.sink then note(tx("adh_t_sink") .. ": " .. string.format(tx("adh_t_sink_v"), r.sink), T.yellow) end
		if r.rearm then note(tx("adh_t_rearm") .. ": " .. tx("adh_t_rearm_v"), T.green) end
		syn_lines(lines, tx("adh_s_strong"), r.syn_good, T.green)
		syn_lines(lines, tx("adh_s_heroes"), r.hero_good, T.green)
		syn_lines(lines, tx("adh_s_weak"), r.syn_bad, T.red)
		syn_lines(lines, tx("adh_s_weak_heroes"), r.hero_bad, T.red)
		local badge = i <= 3 and { tx("adh_badge_top"), T.green } or (r.syn and { tx("adh_badge_syn"), T.cyan }) or nil
		items.picks[#items.picks + 1] = {
			kind = "pick", key = "p" .. r.id, row = r, rank = i, name = name, sub = sub, sk = sk,
			rel = clamp(r.score / top_score, 0, 1),
			tip = { id = r.id, title = name, sub = owner, badge = badge, lines = lines, hint = true },
		}
	end
	local heroes = {}
	if reader.phase == "draft" and reader.model == 0 then
		for _, m in ipairs(R.models or {}) do
			if not m.taken and #heroes < K.TOP_MODELS then heroes[#heroes + 1] = hero_item(m, #heroes + 1) end
		end
	end
	if #heroes > 0 then
		local abilities = items.picks
		items.picks = {}
		section(items.picks, tx("adh_models"), heroes, T.yellow)
		section(items.picks, tx("adh_abilities"), abilities, A)
	end
	if #items.picks == 0 then items.picks[1] = { kind = "empty", key = "empty", text = tx("adh_none") } end

	local op, tri, trap = {}, {}, {}
	for _, p in ipairs(R.op) do op[#op + 1] = pair_item("o", p.a, p.b, p.d, false) end
	for _, t in ipairs(R.tri) do tri[#tri + 1] = tri_item(t) end
	for _, p in ipairs(R.trap) do trap[#trap + 1] = pair_item("x", p.a, p.b, p.d, true) end
	local mc = {}
	for i, r in ipairs(R.model_combo or {}) do
		local sub = string.format(tx("adh_mc_sub"), asset.hero_name(reader.model)) .. (r.mwith and ("  ·  + " .. nm(r.mwith)) or "")
		mc[#mc + 1] = {
			kind = "deny", key = "m" .. i .. "_" .. r.id, id = r.id, name = nm(r.id), sub = sub, d = r.msyn, model = true,
			tip = {
				id = r.id, title = nm(r.id), sub = owner_of(r.id),
				lines = {
					{ tx("adh_t_model"), asset.hero_name(reader.model), T.green },
					{ tx("adh_t_model_syn"), gain(r.msyn), T.green },
					{ tx("adh_t_wr"), pct(wr_of(r.id)), wr_color(wr_of(r.id)) },
				},
			},
		}
	end
	section(items.combos, tx("adh_mc"), mc, T.green)
	section(items.combos, tx("adh_op"), op, T.green)
	section(items.combos, tx("adh_tri"), tri, A)
	section(items.combos, tx("adh_trap"), trap, T.red)
	if #items.combos == 0 then items.combos[1] = { kind = "empty", key = "empty", text = tx("adh_none") } end

	local counter, deny = {}, {}
	for i, p in ipairs(R.counter) do
		local reason = tx(p.label)
		local sub = string.format(tx("adh_vs"), nm(p.against), reason)
		counter[#counter + 1] = {
			kind = "counter", key = "c" .. i .. "_" .. p.id, id = p.id, name = nm(p.id), sub = sub,
			tip = {
				id = p.id, title = nm(p.id), sub = owner_of(p.id),
				lines = {
					{ tx("adh_t_enemy"), nm(p.against), T.cyan },
					{ tx("adh_t_reason"), reason },
					{ tx("adh_t_wr"), pct(wr_of(p.id)), wr_color(wr_of(p.id)) },
				},
			},
		}
	end
	for i, p in ipairs(R.deny) do
		local sub = string.format(tx("adh_deny_sub"), nm(p.against))
		deny[#deny + 1] = {
			kind = "deny", key = "d" .. i .. "_" .. p.id, id = p.id, name = nm(p.id), sub = sub, d = p.d,
			tip = {
				id = p.id, title = nm(p.id), sub = owner_of(p.id),
				lines = {
					{ tx("adh_t_enemy"), nm(p.against), T.yellow },
					{ tx("adh_t_gain"), gain(p.d), T.yellow },
					{ tx("adh_t_wr"), pct(wr_of(p.id)), wr_color(wr_of(p.id)) },
				},
			},
		}
	end
	section(items.counters, tx("adh_counter"), counter, T.cyan)
	section(items.counters, tx("adh_deny"), deny, T.yellow)
	local foes = {}
	for i, f in ipairs(R.foes or {}) do
		local lines = {}
		for _, a in ipairs(f.ids) do lines[#lines + 1] = { nm(a), pct(wr_of(a)), wr_color(wr_of(a)) } end
		lines[#lines + 1] = { tx("adh_t_foe_syn"), gain(f.syn), f.syn > 0 and T.red or T.green }
		lines[#lines + 1] = { tx("adh_t_foe"), gain(f.d), f.d > 0 and T.red or T.green }
		foes[#foes + 1] = {
			kind = "pair", key = "f" .. i, ids = f.ids, d = f.d, bad = f.d > 0, name = f.name,
			tip = { title = f.name, sub = tx("adh_foes"), lines = lines },
		}
	end
	section(items.counters, tx("adh_foes"), foes, T.red)
	if #items.counters == 0 then items.counters[1] = { kind = "empty", key = "empty", text = tx("adh_none") } end

	local b = R.build or {}
	items.build = {}
	if b.arch then
		local lines = {}
		for _, a in ipairs(ARCH_ORDER) do
			lines[#lines + 1] = { tx("adh_arch_" .. a), string.format("%d%%", math.floor(b.share[a] * 100 + 0.5)),
				a == b.arch and T.green or nil }
		end
		local sub = b.known and (tx(b.melee and "adh_b_melee" or "adh_b_ranged") .. "  ·  " .. tx("adh_attr_" .. b.attr))
			or tx("adh_b_model_unknown")
		items.build[1] = {
			kind = "model", key = "model", model = b.model, arch = b.arch, share = b.share,
			name = b.model > 0 and asset.hero_name(b.model) or tx("adh_b_model_unknown"), sub = sub,
			tip = { title = tx("adh_arch_" .. b.arch), sub = sub, lines = lines },
		}
	end
	local function names(ids, n)
		local out = {}
		for i = 1, math.min(n, #ids) do out[i] = nm(ids[i]) end
		return table.concat(out, ", ") .. (#ids > n and " +" .. (#ids - n) or "")
	end
	local function gear(kind, key, e, sub, c, extra)
		if e.farm then c = T.green end
		local lines = { { tx("adh_t_reason"), sub } }
		for _, l in ipairs(extra or {}) do lines[#lines + 1] = l end
		return {
			kind = "gear", key = kind .. key, item = e.item, name = asset.item_name(e.item), sub = sub, c = c,
			d = e.d, n = e.ids and #e.ids or nil, counter = kind == "gc", farm = e.farm,
			tip = { item = e.item, title = asset.item_name(e.item), lines = lines },
		}
	end
	local aghs, core, counter_items = {}, {}, {}
	for i, e in ipairs(b.aghs or {}) do
		local extra = { { tx("adh_t_abilities"), names(e.ids, 3) } }
		if e.need then extra[#extra + 1] = { tx("adh_t_need"), nm(e.need), T.green } end
		if e.d then extra[#extra + 1] = { tx("adh_t_delta"), gain(e.d), e.d >= 0 and T.green or T.red } end
		if e.meta then
			extra[#extra + 1] = { tx("adh_t_meta"),
				string.format(tx("adh_t_pro"), owner_of(e.meta.id) or nm(e.meta.id), math.floor(e.meta.pr * 100 + 0.5)), T.green }
			if e.meta.min then extra[#extra + 1] = { tx("adh_t_bought"), string.format(tx("adh_min"), math.floor(e.meta.min + 0.5)) } end
		end
		local row = gear("ga", i, e, string.format(tx("adh_b_upgrades"), names(e.ids, 2)), T.yellow, extra)
		row.owned = reader.owned and reader.owned[e.item] or false
		if e.up then row.tip.note = (Lc.lang == "ru" and e.up.ru or e.up.en) or e.up.en end
		aghs[#aghs + 1] = row
	end
	local stages = {}
	for _, stage in ipairs({ "early", "core", "late" }) do
		local list = {}
		for i, e in ipairs(b[stage] or {}) do
			local sub = e.meta and string.format(tx("adh_i_meta"), nm(e.meta.id), math.floor(e.meta.pr * 100 + 0.5))
				or (tx(e.reason) .. (e.id and ("  ·  " .. nm(e.id)) or ""))
			local row = gear("g" .. stage, i, { item = e.item, farm = e.farm }, sub, A)
			row.owned = reader.owned and reader.owned[e.item] or false
			list[#list + 1] = row
			core[#core + 1] = row
		end
		stages[stage] = list
	end
	for i, e in ipairs(b.counter or {}) do
		local sub = tx(e.reason) .. "  ·  " .. string.format(tx("adh_b_vs"), names(e.ids, 2))
		counter_items[#counter_items + 1] = gear("gc", i, e, sub, T.cyan, { { tx("adh_t_enemy"), names(e.ids, 4), T.cyan } })
	end
	section(items.build, tx("adh_b_early"), stages.early, A)
	section(items.build, tx("adh_b_core"), stages.core, A)
	section(items.build, tx("adh_b_late"), stages.late, A)
	section(items.build, tx("adh_b_aghs"), aghs, T.yellow)
	section(items.build, tx("adh_b_counter"), counter_items, T.cyan)
	if #items.build == 0 then items.build[1] = { kind = "empty", key = "empty", text = tx("adh_none") } end

	items.counts.picks = #R.top
	items.counts.combos = #mc + #op + #tri + #trap
	items.counts.counters = #counter + #deny + #foes
	items.counts.build = #aghs + #core + #counter_items
	return items
end

local function item_h(it)
	local c = P.set.compact
	local k = it.kind
	if k == "head" then return 34 end
	if k == "empty" then return 48 end
	if k == "pick" then return c and 36 or 56 end
	if k == "pair" or k == "tri" then return c and 32 or 40 end
	if k == "model" then return c and 48 or 66 end
	return c and 36 or 56
end

local function list_height(list)
	local h = 12
	for _, it in ipairs(list) do h = h + item_h(it) end
	return h
end

-- ---------------------------------------------------------------------------
-- widgets
-- ---------------------------------------------------------------------------

function view.pill(x, y, w, h, label, kind, id, click, size)
	local hv = id and anim.hover(id) or 0
	size = size or 13
	if kind == "accent" then
		g.rect(x, y, w, h, A, h / 2, 0.9 + 0.1 * hv)
		g.text(600, size, label, x + w / 2, y + h / 2, T.white, 1, "c")
	elseif kind == "soft" then
		g.rect(x, y, w, h, T.white, h / 2, 0.10 + 0.05 * hv)
		g.text(600, size, label, x + w / 2, y + h / 2, T.t1, 1, "c")
	else
		g.rect(x, y, w, h, T.white, h / 2, 0.06 * hv)
		g.text(500, size, label, x + w / 2, y + h / 2, T.t3, 1, "c")
	end
	if id then hit.add(x, y, w, h, id, { click = click }) end
end

function view.icon_button(x, y, size, glyph, id, active, click, danger)
	local hv = anim.hover(id)
	local ak = anim.tween("ib_on:" .. id, active and 1 or 0, 0.16)
	if danger then
		g.rect(x, y, size, size, T.red, 8, 0.16 * hv)
	else
		g.rect(x, y, size, size, T.white, 8, 0.10 * ak + 0.08 * hv * (1 - ak))
	end
	local c = anim.mix(T.t3, T.t1, math.max(ak, hv))
	if danger then c = anim.mix(T.t3, T.red, hv) end
	g.glyph(glyph, 12, x + size / 2, y + size / 2, c)
	hit.add(x, y, size, size, id, { click = click })
end

function view.chip(x, cy, label, c)
	local w = g.width(700, 10, label) + 12
	g.rect(x, cy - 8, w, 16, c, 8, 0.18)
	g.frame(x, cy - 8, w, 16, c, 8, 0.38)
	g.text(700, 10, label, x + w / 2, cy, c, 1, "c")
	return w
end

function view.switch(x, y, on, id, click)
	local k = anim.tween("sw:" .. id, on and 1 or 0, 0.18, ease_in_out)
	local track = anim.mix(C.off, A, k)
	g.rect(x, y, 34, 20, track, 10)
	g.dot(x + 10 + 14 * k, y + 10, 8, anim.mix(T.knob, T.white, k))
	hit.add(x - 4, y - 4, 42, 28, id, { click = click })
end

function view.slide_to(mx)
	local sl = P.slide
	local v = clamp((mx - sl.x) / sl.w, 0, 1)
	P.set[sl.key] = sl.min + math.floor((sl.max - sl.min) * v / 5 + 0.5) * 5
end

function view.slider(right, cy, key, min, max)
	local tw = 150
	local x = right - tw - 6
	local val = P.set[key]
	local v = clamp((val - min) / (max - min), 0, 1)
	local id = "sl:" .. key
	local hot = hit.is(id) or (P.slide ~= nil and P.slide.key == key)
	g.text(600, 12, val .. "%", x - 12, cy, T.t3, 1, "r")
	g.rect(x, cy - 2, tw, 4, C.off, 2)
	if v > 0 then g.rect(x, cy - 2, tw * v, 4, A, 2) end
	g.dot(x + tw * v, cy, hot and 8.5 or 7.5, T.white)
	hit.add(x - 10, cy - 14, tw + 20, 28, id, { down = function(mx)
		P.slide = { key = key, min = min, max = max, x = g.x + x * g.s, w = tw * g.s }
		view.slide_to(mx)
	end })
end

function view.swatches(right, cy, order, cur, prefix, color, pick)
	local size, gap = 20, 8
	local x = right - (#order * size + (#order - 1) * gap)
	for i, id in ipairs(order) do
		local key = prefix .. id
		local hv = anim.hover(key)
		local on = anim.tween("sw_on:" .. key, cur == id and 1 or 0, 0.16)
		local sx = x + (i - 1) * (size + gap) + size / 2
		g.dot(sx, cy, size / 2 - 1 + 0.8 * hv, color(id))
		g.ring(sx, cy, size / 2 - 1, T.white, 0.14, 1, 0, 1)
		if on > 0.01 then g.ring(sx, cy, size / 2 + 3.5, T.white, 0.85 * on, 1.5, 0, 1) end
		hit.add(sx - size / 2 - gap / 2, cy - size / 2 - 4, size + gap, size + 8, key, { click = function() pick(id) end })
	end
end

function view.bar(x, y, w, frac)
	g.rect(x, y, w, 5, T.white, 2.5, 0.08)
	if frac > 0 then g.rect(x, y, math.max(5, w * clamp(frac, 0, 1)), 5, A, 2.5) end
end

-- ---------------------------------------------------------------------------
-- scrolling (frame-rate independent smoothing, snapped to whole pixels)
-- ---------------------------------------------------------------------------

function view.scroll_snap(v)
	P.scroll_f, P.scroll = v, v
end

function view.scroll_area(x, y, w, h)
	P.view_h, P.area = h, { x, y, w, h }
	local f = P.scroll_f
	local diff = P.scroll_to - f
	if math.abs(diff) * g.s < 0.5 then
		f = P.scroll_to
	else
		f = f + diff * (1 - math.exp(-P.dt * 18))
	end
	P.scroll_f = f
	P.scroll = math.floor(f * g.s + 0.5) / g.s
	hit.add(x, y, w, h, "content", { wheel = function(dir)
		P.wheel_n = (P.now - (P.wheel_t or -10) < 0.12) and math.min((P.wheel_n or 0) + 1, 6) or 0
		P.wheel_t = P.now
		local step = U.WHEEL * (1 + P.wheel_n * 0.25)
		P.scroll_to = clamp(P.scroll_to + dir * step, 0, math.max(0, P.content_h - P.view_h))
		P.scroll_t = P.now
	end })
	g.clip(x, y, w, h)
end

function view.end_scroll(content_h)
	g.unclip()
	P.content_h = content_h
	local max_scroll = math.max(0, content_h - P.view_h)
	if P.scroll_to > max_scroll then
		P.scroll_to = max_scroll
		view.scroll_snap(max_scroll)
	end
	local ax, ay, aw, ah = P.area[1], P.area[2], P.area[3], P.area[4]
	local ta = clamp(P.scroll / 14, 0, 1)
	if ta > 0.01 then g.hl(ax + 14, ay, aw - 28, T.white, 0.08 * ta) end
	local ba = clamp((max_scroll - P.scroll) / 14, 0, 1)
	if ba > 0.01 then g.hl(ax + 14, ay + ah - 1, aw - 28, T.white, 0.06 * ba) end
	if max_scroll <= 0 then return end

	local track = ah - 12
	local thumb = math.max(28, track * P.view_h / content_h)
	local span = math.max(1, track - thumb)
	local top = ay + 6 + span * clamp(P.scroll / max_scroll, 0, 1)
	local hot = hit.is("sb") or hit.is("sb_thumb") or P.sb_drag ~= nil
	local sa = anim.tween("scrollbar", (hot or P.now - P.scroll_t < 0.9) and 1 or 0, 0.2)
	local wide = anim.tween("scrollbar_w", hot and 1 or 0, 0.15)
	if sa > 0.01 then
		g.rect(ax + aw - 11, ay + 6, 8, track, T.white, 4, 0.06 * wide * sa)
		local bw = 3 + 2 * wide
		g.rect(ax + aw - 3 - bw - 1, top, bw, thumb, T.white, bw / 2, (0.22 + 0.2 * wide) * sa)
	end
	hit.add(ax + aw - 14, ay + 6, 14, track, "sb", { down = function(_, my)
		local rel = (my - g.y) / g.s - ay - 6 - thumb / 2
		local v = clamp(rel / span, 0, 1) * max_scroll
		P.scroll_to = v
		view.scroll_snap(v)
		P.sb_drag = { my = my, scroll = v, k = max_scroll / span }
		P.scroll_t = P.now
	end })
	hit.add(ax + aw - 14, top, 14, thumb, "sb_thumb", { down = function(_, my)
		P.sb_drag = { my = my, scroll = P.scroll, k = max_scroll / span }
		P.scroll_t = P.now
	end })
end

-- ---------------------------------------------------------------------------
-- list rows
-- ---------------------------------------------------------------------------

local function mark_hover(it, y)
	P.hover_item, P.hover_y = it, y
end

function view.draw_head(it, y, h)
	local x0 = U.PAD
	local c = it.c or A
	local cy = y + h - 14
	g.rect(x0 + 4, cy - 7, 3, 14, c, 1.5, 0.95)
	g.text(700, 12.5, it.text, x0 + 14, cy, T.t1)
	local w = g.width(700, 12.5, it.text)
	local label = tostring(it.n)
	local nw = g.width(700, 10.5, label) + 12
	g.rect(x0 + 14 + w + 8, cy - 8, nw, 16, c, 8, 0.18)
	g.text(700, 10.5, label, x0 + 14 + w + 8 + nw / 2, cy, c, 1, "c")
	g.hl(x0 + 4, y + h - 2, U.W - 2 * U.PAD - U.SB + 4 - 8, T.white, 0.08)
end

function view.draw_empty(it, y, h)
	g.text(500, 13, it.text, U.W / 2, y + h / 2, T.t3, 1, "c")
end

function view.draw_pick(it, y, h)
	local compact = P.set.compact
	local r = it.row
	local id, sid = "row:" .. it.key, "skip:" .. it.key
	local hot = hit.hover == id or hit.hover == sid
	local hv = anim.tween("hv:" .. id, hot and 1 or 0, 0.12)
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local first = it.rank == 1
	g.rect(x0, y + 2, w, h - 4, T.white, 10, 0.045 + 0.06 * hv)
	if first then
		g.rect(x0, y + 2, w, h - 4, A, 10, 0.12)
		g.frame(x0, y + 2, w, h - 4, A, 10, 0.45)
		g.rect(x0, y + 10, 3, h - 20, A, 1.5, 1)
	end

	-- rank badge
	local rx = x0 + 18
	g.dot(rx, y + h / 2, compact and 9 or 11, first and A or T.white, first and 1 or 0.10)
	g.text(700, compact and 11 or 12, tostring(it.rank), rx, y + h / 2, first and T.white or T.t3, 1, "c")

	-- icon with a frame (gold for ultimates)
	local isz = compact and 26 or 36
	local ix, iy = x0 + 36, y + (h - isz) / 2
	g.ability(r.id, ix, iy, isz, 1, 7)
	g.frame(ix, iy, isz, isz, r.ult and T.yellow or T.white, 7, r.ult and 0.8 or 0.16, 1.2)

	local tx0 = ix + isz + 11
	local right = x0 + w - 8 - 24
	local wc = wr_color(r.wr)
	local pw = g.width(700, 13, pct(r.wr)) + 16
	local text_w = right - pw - 10 - tx0
	if compact and r.syn then text_w = text_w - 52 end

	-- name and chips
	local line1 = compact and h / 2 or 20
	local ult_w = r.ult and (g.width(700, 10, tx("adh_ult")) + 16) or 0
	local role_key = r.role_fit and "adh_role_fit" or (r.role_avoid and "adh_role_avoid" or nil)
	local role_w = role_key and (g.width(700, 10, tx(role_key)) + 16) or 0
	local fit_total = (r.fit or 0) + ((r.msyn and math.abs(r.msyn) >= K.MODEL_SYN_SHOW) and r.msyn or 0)
	local fit_key = (r.fit_why or (r.msyn and math.abs(r.msyn) >= K.MODEL_SYN_SHOW))
		and (fit_total > 0 and "adh_fit_good" or (fit_total < 0 and "adh_fit_bad" or nil)) or nil
	local fit_w = fit_key and (g.width(700, 10, tx(fit_key)) + 16) or 0
	local name = g.fit(600, 14, it.name, text_w - ult_w - role_w - fit_w - 4)
	local nw = g.text(600, 14, name, tx0, y + line1, T.t1)
	local cx = tx0 + nw + 8
	if r.ult then cx = cx + view.chip(cx, y + line1, tx("adh_ult"), T.yellow) + 4 end
	if role_key then cx = cx + view.chip(cx, y + line1, tx(role_key), r.role_fit and T.green or T.red) + 4 end
	if fit_key then view.chip(cx, y + line1, tx(fit_key), fit_total > 0 and T.green or T.red) end

	-- win rate badge
	local py = compact and (h - 22) / 2 or 9
	g.rect(right - pw, y + py, pw, 22, wc, 11, 0.16)
	g.text(700, 13, pct(r.wr), right - pw / 2, y + py + 11, wc, 1, "c")

	if compact then
		if r.syn then g.text(600, 11.5, gain(r.syn), right - pw - 10, y + h / 2, T.green, 1, "r") end
	else
		local bw = 64
		local sub = g.fit(500, 12, it.sub, right - bw - 36 - tx0)
		g.text(500, 12, sub, tx0, y + h - 17, it.sk == "syn" and T.green or T.t3)
		g.rect(right - bw, y + h - 19, bw, 5, T.white, 2.5, 0.10)
		g.rect(right - bw, y + h - 19, math.max(5, bw * it.rel), 5, A, 2.5)
		g.text(600, 10.5, string.format("%d", math.floor(r.score * 100 + 0.5)), right - bw - 6, y + h - 16.5, T.t3, 1, "r")
	end

	hit.add(x0, y + 2, w, h - 4, id, { click = function() reader.pick(r.id) end, rclick = function() S.toggle_skip(r.id) end })
	local ba = hv
	if ba > 0.01 then
		local bx, by = x0 + w - 28, y + (h - 22) / 2
		local bh = anim.hover(sid)
		g.rect(bx, by, 22, 22, T.red, 7, (0.12 + 0.18 * bh) * ba)
		g.glyph(U.G.close, 10, bx + 11, by + 11, anim.mix(T.t2, T.red, bh), ba)
	end
	hit.add(x0 + w - 28, y + (h - 22) / 2, 22, 22, sid, { click = function() S.toggle_skip(r.id) end })
	if hot then mark_hover(it, y) end
end

function view.draw_pair(it, y, h)
	local compact = P.set.compact
	local id = "row:" .. it.key
	local hv = anim.hover(id)
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local c = it.bad and T.red or T.green
	g.rect(x0, y + 2, w, h - 4, T.white, 9, 0.045 + 0.06 * hv)
	g.rect(x0, y + 8, 3, h - 16, c, 1.5, 0.9)
	local isz = compact and 20 or 26
	local ix = x0 + 14
	for _, aid in ipairs(it.ids) do
		g.ability(aid, ix, y + (h - isz) / 2, isz, 1, 6)
		g.frame(ix, y + (h - isz) / 2, isz, isz, T.white, 6, 0.16, 1)
		ix = ix + isz + 3
	end
	local right = x0 + w - 10
	local label = gain(it.d)
	local pw = g.width(700, 12.5, label) + 16
	g.rect(right - pw, y + (h - 22) / 2, pw, 22, c, 11, 0.16)
	g.text(700, 12.5, label, right - pw / 2, y + h / 2, c, 1, "c")
	local name = g.fit(600, 12.5, it.name, right - pw - 10 - ix - 6)
	g.text(600, 12.5, name, ix + 6, y + h / 2, T.t1)
	hit.add(x0, y + 2, w, h - 4, id)
	if hit.is(id) then mark_hover(it, y) end
end

function view.draw_stack(it, y, h)
	local compact = P.set.compact
	local id = "row:" .. it.key
	local hv = anim.hover(id)
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local deny = it.kind == "deny"
	local c = it.model and T.green or (deny and T.yellow or T.cyan)
	g.rect(x0, y + 2, w, h - 4, T.white, 10, 0.045 + 0.06 * hv)
	g.rect(x0, y + 8, 3, h - 16, c, 1.5, 0.9)
	local isz = compact and 26 or 36
	local ix, iy = x0 + 14, y + (h - isz) / 2
	g.ability(it.id, ix, iy, isz, 1, 7)
	g.frame(ix, iy, isz, isz, T.white, 7, 0.16, 1.2)
	local tx0 = ix + isz + 11
	local right = x0 + w - 10
	local pw = 0
	if deny then
		local label = gain(it.d)
		pw = g.width(700, 12.5, label) + 16
		local py = compact and (h - 22) / 2 or 9
		g.rect(right - pw, y + py, pw, 22, c, 11, 0.16)
		g.text(700, 12.5, label, right - pw / 2, y + py + 11, c, 1, "c")
	end
	local max_w = right - tx0 - (deny and pw + 10 or 0)
	if compact then
		local label = g.fit(600, 12.5, it.name .. "  ·  " .. it.sub, max_w)
		g.text(600, 12.5, label, tx0, y + h / 2, T.t1)
	else
		g.text(600, 14, g.fit(600, 14, it.name, max_w), tx0, y + 20, T.t1)
		g.text(500, 12, g.fit(500, 12, it.sub, right - tx0), tx0, y + h - 17, c)
	end
	hit.add(x0, y + 2, w, h - 4, id, { click = function() reader.pick(it.id) end })
	if hit.is(id) then mark_hover(it, y) end
end

function view.draw_hero(it, y, h)
	local compact = P.set.compact
	local id = "row:" .. it.key
	local hv = anim.hover(id)
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local first = it.rank == 1
	g.rect(x0, y + 2, w, h - 4, T.white, 10, 0.045 + 0.06 * hv)
	if first then
		g.rect(x0, y + 2, w, h - 4, T.yellow, 10, 0.07)
		g.frame(x0, y + 2, w, h - 4, T.yellow, 10, 0.35)
	end
	g.rect(x0, y + 8, 3, h - 16, T.yellow, 1.5, first and 1 or 0.5)
	local isz = compact and 26 or 36
	local ix, iy = x0 + 14, y + (h - isz) / 2
	g.hero(it.h, ix, iy, isz, 1, 7)
	g.frame(ix, iy, isz, isz, first and T.yellow or T.white, 7, first and 0.8 or 0.16, 1.2)
	local tx0 = ix + isz + 11
	local right = x0 + w - 10
	local label, wc = pct(it.wr), wr_color(it.wr)
	local pw = g.width(700, 12.5, label) + 16
	local py = compact and (h - 22) / 2 or 9
	g.rect(right - pw, y + py, pw, 22, wc, 11, 0.16)
	g.text(700, 12.5, label, right - pw / 2, y + py + 11, wc, 1, "c")
	local max_w = right - tx0 - pw - 10
	if compact then
		g.text(600, 12.5, g.fit(600, 12.5, it.name .. "  ·  " .. it.sub, max_w), tx0, y + h / 2, T.t1)
	else
		local nw = g.text(600, 14, g.fit(600, 14, it.name, max_w), tx0, y + 20, T.t1)
		if first then view.chip(tx0 + nw + 8, y + 20, tx("adh_badge_model"), T.yellow) end
		g.text(500, 12, g.fit(500, 12, it.sub, right - tx0), tx0, y + h - 17, it.good and T.green or T.t3)
	end
	hit.add(x0, y + 2, w, h - 4, id)
	if hit.is(id) then mark_hover(it, y) end
end

function view.draw_model(it, y, h)
	local compact = P.set.compact
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local id = "row:" .. it.key
	g.rect(x0, y + 2, w, h - 4, A, 10, 0.10 + 0.04 * anim.hover(id))
	g.frame(x0, y + 2, w, h - 4, A, 10, 0.35)
	local isz = compact and 30 or 44
	local ix, iy = x0 + 10, y + (h - isz) / 2
	if it.model > 0 then
		g.hero(it.model, ix, iy, isz, 1, 8)
	else
		g.rect(ix, iy, isz, isz, T.white, 8, 0.10)
		g.glyph(U.G.wait, 14, ix + isz / 2, iy + isz / 2, T.t3)
	end
	local tx0 = ix + isz + 11
	local right = x0 + w - 10
	local label = tx("adh_arch_" .. it.arch)
	local lw = g.width(700, 11.5, label) + 18
	local cy = compact and h / 2 or 22
	g.rect(right - lw, y + cy - 11, lw, 22, A, 11, 0.9)
	g.text(700, 11.5, label, right - lw / 2, y + cy, T.white, 1, "c")
	g.text(700, 14, g.fit(700, 14, it.name, right - lw - 10 - tx0), tx0, y + cy, T.t1)
	if not compact then
		g.text(500, 12, g.fit(500, 12, it.sub, w * 0.45), tx0, y + h - 18, T.t3)
		local bx, bw = x0 + w * 0.55, w * 0.45 - 10
		local seg_x = bx
		for i, a in ipairs(ARCH_ORDER) do
			local sw = bw * it.share[a]
			local on = a == it.arch
			g.rect(seg_x, y + h - 21, math.max(2, sw - 2), 6, on and A or T.white, 3, on and 0.95 or 0.12 + 0.06 * i)
			seg_x = seg_x + sw
		end
	end
	hit.add(x0, y + 2, w, h - 4, id)
	if hit.is(id) then mark_hover(it, y) end
end

function view.draw_gear(it, y, h)
	local base_a = g.a
	if it.owned then g.a = base_a * 0.45 end
	view.draw_gear_row(it, y, h)
	g.a = base_a
	if it.owned then
		local isz = P.set.compact and 26 or 36
		local cx, cy = U.PAD + 14 + isz - 4, y + (h - isz) / 2 + isz - 4
		g.dot(cx, cy, 7, T.green)
		g.glyph(U.G.check, 8, cx, cy, T.white)
	end
end

function view.draw_gear_row(it, y, h)
	local compact = P.set.compact
	local id = "row:" .. it.key
	local hv = anim.hover(id)
	local x0, w = U.PAD, U.W - U.PAD - U.SB
	local c = it.c or A
	g.rect(x0, y + 2, w, h - 4, T.white, 10, 0.045 + 0.06 * hv)
	g.rect(x0, y + 8, 3, h - 16, c, 1.5, 0.9)
	local isz = compact and 26 or 36
	local ix, iy = x0 + 14, y + (h - isz) / 2
	g.item(it.item, ix, iy, isz, 1, 7)
	g.frame(ix, iy, isz, isz, T.white, 7, 0.16, 1.2)
	local tx0 = ix + isz + 11
	local right = x0 + w - 10
	local badge = it.d and gain(it.d) or (it.counter and it.n and it.n > 1 and ("x" .. it.n)) or nil
	local pw = 0
	if badge then
		local bc = it.d and (it.d >= 0 and T.green or T.red) or c
		pw = g.width(700, 12.5, badge) + 16
		local py = compact and (h - 22) / 2 or 9
		g.rect(right - pw, y + py, pw, 22, bc, 11, 0.16)
		g.text(700, 12.5, badge, right - pw / 2, y + py + 11, bc, 1, "c")
	end
	local max_w = right - tx0 - (badge and pw + 10 or 0)
	local chip_w = it.farm and (g.width(700, 10, tx("adh_f_slot")) + 20) or 0
	if compact then
		local nw = g.text(600, 12.5, g.fit(600, 12.5, it.name .. "  ·  " .. it.sub, max_w - chip_w), tx0, y + h / 2, T.t1)
		if it.farm then view.chip(tx0 + nw + 8, y + h / 2, tx("adh_f_slot"), T.green) end
	else
		local nw = g.text(600, 14, g.fit(600, 14, it.name, max_w - chip_w), tx0, y + 20, T.t1)
		if it.farm then view.chip(tx0 + nw + 8, y + 20, tx("adh_f_slot"), T.green) end
		g.text(500, 12, g.fit(500, 12, it.sub, right - tx0), tx0, y + h - 17, it.counter and T.cyan or T.t3)
	end
	hit.add(x0, y + 2, w, h - 4, id)
	if hit.is(id) then mark_hover(it, y) end
end

function view.draw_item(it, y, h)
	local k = it.kind
	if k == "pick" then view.draw_pick(it, y, h)
	elseif k == "model" then view.draw_model(it, y, h)
	elseif k == "hero" then view.draw_hero(it, y, h)
	elseif k == "gear" then view.draw_gear(it, y, h)
	elseif k == "pair" or k == "tri" then view.draw_pair(it, y, h)
	elseif k == "counter" or k == "deny" then view.draw_stack(it, y, h)
	elseif k == "head" then view.draw_head(it, y, h)
	else view.draw_empty(it, y, h) end
end

function view.draw_list(list, top, view_h)
	view.scroll_area(0, top, U.W, view_h)
	local y = top + 4 - P.scroll
	local bottom = top + view_h
	for _, it in ipairs(list) do
		local h = item_h(it)
		if y + h > top and y < bottom then view.draw_item(it, y, h) end
		y = y + h
	end
	view.end_scroll(list_height(list))
end

-- ---------------------------------------------------------------------------
-- tooltip (drawn beside the panel, never inside the clipped list)
-- ---------------------------------------------------------------------------

function view.tip_rows(lines, tw)
	local rows, h = {}, 0
	for _, l in ipairs(lines) do
		local row = { l = l, y = h }
		if l.h then
			row.kind, h = "h", h + 30
		elseif l.t then
			row.kind, row.wrap = "t", g.wrap(500, 12, l.t, tw - 28)
			h = h + #row.wrap * 16 + 6
		elseif l.s then
			row.kind, h = "s", h + 20
		else
			row.kind, h = "kv", h + 24
		end
		rows[#rows + 1] = row
	end
	return rows, h
end

function view.tip()
	local want = P.tip
	if want then P.tip_last = want end
	local k = anim.tween("tip", want and 1 or 0, want and 0.14 or 0.1)
	local tip = P.tip_last
	if not tip or k <= 0.01 then return end
	local data_tip = tip.tip
	local tw = U.TIP_W
	local badge_h = data_tip.badge and 20 or 0
	local head_h = (data_tip.sub and 54 or 42) + badge_h
	local rows, body_h = view.tip_rows(data_tip.lines, tw)
	local note = data_tip.note and g.wrap(500, 12, data_tip.note, tw - 28) or nil
	local th = head_h + 4 + body_h + (note and #note * 17 + 6 or 0) + (data_tip.hint and 30 or 0) + 8
	local screen = Render.ScreenSize()
	local left_side = P.wx + (U.W + 8 + tw) * g.s > screen.x
	local tx0 = left_side and -(tw + 8) or (U.W + 8)
	local ty = P.hover_y_last or 0
	local abs_bottom = P.wy + (ty + th) * g.s
	if abs_bottom > screen.y - 8 then ty = ty - (abs_bottom - screen.y + 8) / g.s end
	if P.wy + ty * g.s < 8 then ty = (8 - P.wy) / g.s end

	local prev = g.a
	g.a = prev * k
	local dy = (1 - k) * 4
	local top = ty + dy
	g.shadow(tx0, top, tw, th, 12, 0.08)
	g.rect(tx0, top, tw, th, C.win, 12, 0.98)
	g.rect(tx0, top, tw, th, T.white, 12, 0.04)
	g.frame(tx0, top, tw, th, T.white, 12, 0.12)
	g.rect(tx0 + 14, top, 28, 2, data_tip.badge and data_tip.badge[2] or A, 1, 0.9)
	if data_tip.badge then
		local bc = data_tip.badge[2]
		g.glyph(U.G.star, 10, tx0 + 19, top + 16, bc)
		g.text(700, 11.5, data_tip.badge[1], tx0 + 29, top + 16, bc)
	end
	local hy = top + badge_h
	local ix = tx0 + 14
	if data_tip.id then
		g.ability(data_tip.id, ix, hy + 12, 30, 1, 7)
		g.frame(ix, hy + 12, 30, 30, T.white, 7, 0.16, 1)
		ix = ix + 40
	elseif data_tip.item then
		g.item(data_tip.item, ix, hy + 12, 30, 1, 7)
		g.frame(ix, hy + 12, 30, 30, T.white, 7, 0.16, 1)
		ix = ix + 40
	elseif data_tip.hero then
		g.hero(data_tip.hero, ix, hy + 12, 30, 1, 7)
		g.frame(ix, hy + 12, 30, 30, T.white, 7, 0.16, 1)
		ix = ix + 40
	end
	g.text(700, 14, g.fit(700, 14, data_tip.title, tx0 + tw - 14 - ix), ix, hy + (data_tip.sub and 22 or 21), T.t1)
	if data_tip.sub then
		g.text(500, 12, g.fit(500, 12, data_tip.sub, tx0 + tw - 14 - ix), ix, hy + 41, T.t3)
	end
	g.hl(tx0 + 14, top + head_h, tw - 28, T.white, 0.09)
	local body = top + head_h + 4
	for _, row in ipairs(rows) do
		local l, ry = row.l, body + row.y
		if row.kind == "h" then
			g.text(700, 12.5, g.fit(700, 12.5, l.h, tw - 28), tx0 + 14, ry + 16, l.c or T.t1)
			g.hl(tx0 + 14, ry + 27, tw - 28, l.c or T.white, 0.25)
		elseif row.kind == "t" then
			for i, text in ipairs(row.wrap) do
				g.text(500, 12, text, tx0 + 14, ry + 9 + (i - 1) * 16, l.c or T.t2)
			end
		elseif row.kind == "s" then
			local value_w = g.width(600, 12, l[2])
			g.dot(tx0 + 19, ry + 10, 2, l[3] or T.t2, 0.8)
			g.text(500, 12, g.fit(500, 12, l[1], tw - 40 - value_w - 10), tx0 + 27, ry + 10, l.mine and T.t1 or T.t2)
			g.text(600, 12, l[2], tx0 + tw - 14, ry + 10, l[3] or T.t1, 1, "r")
		else
			local value_w = g.width(700, 12.5, l[2])
			local label_max = tw - 28 - math.min(value_w, tw * 0.6) - 12
			g.text(500, 12.5, g.fit(500, 12.5, l[1], label_max), tx0 + 14, ry + 12, T.t2)
			g.text(700, 12.5, g.fit(700, 12.5, l[2], tw * 0.6), tx0 + tw - 14, ry + 12, l[3] or T.t1, 1, "r")
		end
	end
	local cy = body + body_h + 12
	if note then
		g.hl(tx0 + 14, cy - 8, tw - 28, T.white, 0.09)
		cy = cy + 4
		for _, l in ipairs(note) do
			g.text(500, 12, l, tx0 + 14, cy, T.t2)
			cy = cy + 17
		end
	end
	if data_tip.hint then
		g.text(500, 11.5, g.fit(500, 11.5, tx("adh_t_hint"), tw - 28), tx0 + 14, cy + 8, T.t3)
	end
	g.a = prev
end

-- ---------------------------------------------------------------------------
-- window sections
-- ---------------------------------------------------------------------------

function view.home(screen)
	local wx, wy = Config.ReadInt(U.CFG, "wx", -1), Config.ReadInt(U.CFG, "wy", -1)
	if wx < 0 or wy < 0 then
		local margin = 18 * g.s
		wx = (ui.side and ui.side:Get() == 1) and math.floor(screen.x - U.W * g.s - margin) or math.floor(margin)
		wy = math.floor(screen.y * 0.14)
	end
	P.wx, P.wy = wx, wy
end

function view.reset_pos()
	save("wx", -1)
	save("wy", -1)
	P.wx = nil
end

function view.start_drag(mx, my)
	P.drag, P.moved = { mx = mx, my = my, wx = P.wx, wy = P.wy }, false
end

function view.fold()
	P.set.collapsed = not P.set.collapsed
	save("collapsed", P.set.collapsed and 1 or 0)
	P.tip, P.hover_item = nil, nil
end

function view.tab_list()
	return reader.phase == "game" and TABS_GAME or TABS_DRAFT
end

function view.cur_tab()
	local list = view.tab_list()
	return valid(list, P.tab, list[1])
end

function view.status_text()
	if not D.ready then
		return string.format(tx("adh_loading"), clamp(D.i, 1, #K.JOBS), #K.JOBS)
	end
	if reader.phase == "game" then return string.format(tx("adh_status_game"), #reader.mine, #reader.enemy) end
	if not reader.active then return tx("adh_waiting") end
	return string.format(tx("adh_status"), #reader.pool, #reader.mine, K.SLOTS)
end

function view.notice()
	local role = ui.role and tonumber(ui.role:Get()) or 0
	if D.err then return string.format(tx("adh_error"), D.err), "bad" end
	if role > 0 and D.tag_error then return string.format(tx("adh_error"), D.tag_error), "bad" end
	if D.cache_fallback then return tx("adh_offline"), "warn" end
	if D.pair_cache_fallback then return tx("adh_pairs_offline"), "dim" end
	return nil
end

function view.header()
	local W = U.W
	hit.add(0, 0, W - 110, U.HEAD, "drag", {
		down = view.start_drag,
		dbl = view.fold,
	})
	g.hl(14, U.HEAD - 1, W - 28, T.white, 0.07)
	g.rect(14, 15, 32, 32, A, 10, 0.22)
	g.frame(14, 15, 32, 32, A, 10, 0.55)
	g.glyph(U.G.bolt, 14, 30, 31, AT)
	g.text(700, 16, tx("adh_title"), 58, 24, T.t1)
	local sub = g.fit(500, 12, view.status_text(), W - 58 - 122)
	g.text(500, 12, sub, 58, 44, T.t2)

	local bx = W - 12 - 28
	view.icon_button(bx, 17, 28, U.G.close, "btn_close", false, function() ui.show:Set(false) end, true)
	bx = bx - 32
	view.icon_button(bx, 17, 28, P.set.collapsed and U.G.down or U.G.up, "btn_fold", false, view.fold)
	bx = bx - 32
	view.icon_button(bx, 17, 28, U.G.gear, "btn_settings", P.settings, function()
		P.settings = not P.settings
		if P.settings and P.set.collapsed then view.fold() end
		P.tip, P.hover_item = nil, nil
	end)
end

function view.roles(y)
	local x0, w = U.PAD, U.W - 2 * U.PAD
	local seg = w / #ROLE_LABEL
	local cur = ui.role and tonumber(ui.role:Get()) or 0
	g.rect(x0, y + 5, w, 34, T.white, 10, 0.055)
	local hx = anim.tween("role_x", cur, 0.2, ease_in_out)
	g.rect(x0 + 2 + hx * seg, y + 7, seg - 4, 30, A, 8, 0.26)
	g.frame(x0 + 2 + hx * seg, y + 7, seg - 4, 30, A, 8, 0.6)
	for i, key in ipairs(ROLE_LABEL) do
		local id = "role:" .. i
		local hv = anim.hover(id)
		local on = (i - 1) == cur
		local c = on and T.white or anim.mix(T.t3, T.t1, hv)
		g.text(on and 700 or 600, 12, g.fit(600, 12, tx(key), seg - 6), x0 + (i - 0.5) * seg, y + 22, c, 1, "c")
		hit.add(x0 + (i - 1) * seg, y + 5, seg, 34, id, { click = function()
			ui.role:Set(i - 1)
			reader.refresh()
		end })
	end
end

function view.tabs(y)
	local x0, w = U.PAD, U.W - 2 * U.PAD
	local tabs, cur = view.tab_list(), view.cur_tab()
	local seg = w / #tabs
	local idx = 1
	for i, key in ipairs(tabs) do if key == cur then idx = i end end
	local counts = P.items and P.items.counts or {}
	for i, key in ipairs(tabs) do
		local id = "tab:" .. key
		local hv = anim.hover(id)
		local on = key == cur
		local label = tx(TAB_LABEL[key])
		local n = counts[key] or 0
		local c = on and T.t1 or anim.mix(T.t3, T.t1, hv)
		local lw = g.width(700, 13, label)
		local nw = g.width(700, 10.5, tostring(n)) + 12
		local cx = x0 + (i - 0.5) * seg
		local left = cx - (lw + 7 + nw) / 2
		g.text(on and 700 or 600, 13, label, left, y + 20, c)
		g.rect(left + lw + 7, y + 11.5, nw, 17, on and A or T.white, 8.5, on and 0.95 or 0.10)
		g.text(700, 10.5, tostring(n), left + lw + 7 + nw / 2, y + 20, on and T.white or T.t2, 1, "c")
		hit.add(x0 + (i - 1) * seg, y, seg, U.TABS, id, { click = function()
			if P.tab ~= key then
				P.tab = key
				save("tab", key)
			end
		end })
	end
	local ux = anim.tween("tab_x", idx - 1, 0.22, ease_in_out)
	g.rect(x0 + ux * seg + 14, y + U.TABS - 3, seg - 28, 3, A, 1.5)
	g.hl(x0, y + U.TABS - 1, w, T.white, 0.07)
end

function view.state_card(y)
	local cx = U.W / 2
	if not D.ready then
		if D.err then
			g.glyph(U.G.warn, 22, cx, y + 26, T.red)
			local lines = g.wrap(500, 13, string.format(tx("adh_error"), D.err), U.W - 64)
			local n = math.min(2, #lines)
			for i = 1, n do g.text(500, 13, lines[i], cx, y + 52 + (i - 1) * 17, T.red, 1, "c") end
			view.pill(cx - 52, y + 56 + n * 17, 104, 30, tx("adh_retry"), "soft", "retry", data.refresh)
			return
		end
		local frac = (clamp(D.i, 1, #K.JOBS) - 1) / #K.JOBS
		local job = D.job
		if job and job.state == "parse" and job.text and #job.text > 0 then
			frac = frac + (job.pos / #job.text) / #K.JOBS
		end
		g.ring(cx, y + 30, 12, T.white, 0.12, 3, 0, 1)
		g.ring(cx, y + 30, 12, A, 1, 3, (P.now * 300) % 360, 0.28)
		g.text(600, 14, string.format(tx("adh_loading"), clamp(D.i, 1, #K.JOBS), #K.JOBS), cx, y + 62, T.t1, 1, "c")
		view.bar(U.PAD + 24, y + 86, U.W - 2 * U.PAD - 48, frac)
		return
	end
	g.glyph(U.G.wait, 22, cx, y + 26, AT)
	g.text(700, 15, tx("adh_waiting"), cx, y + 54, T.t1, 1, "c")
	g.text(500, 13, string.format(tx("adh_waiting_count"), reader.total, K.MIN_POOL), cx, y + 76, T.t2, 1, "c")
	view.bar(U.PAD + 24, y + 94, U.W - 2 * U.PAD - 48, reader.total / K.MIN_POOL)
	local lines = g.wrap(500, 12, tx("adh_waiting_hint"), U.W - 72)
	for i = 1, math.min(2, #lines) do g.text(500, 12, lines[i], cx, y + 114 + (i - 1) * 16, T.t3, 1, "c") end
end

function view.footer(y)
	local W = U.W
	g.hl(U.PAD, y, W - 2 * U.PAD, T.white, 0.07)
	local right = W - 34
	if S.skip_n > 0 then
		local label = tx("adh_restore")
		local pw = g.width(600, 12, label) + 30
		view.pill(right - pw, y + 7, pw, 24, label, "soft", "restore", S.clear_skip, 12)
		right = right - pw - 8
		local txt = string.format(tx("adh_skipped"), S.skip_n)
		g.text(600, 12, txt, right, y + 19, T.t2, 1, "r")
		right = right - g.width(600, 12, txt) - 12
	end
	local text, kind = view.notice()
	if text and right > U.PAD + 60 then
		local c = kind == "bad" and T.red or (kind == "warn" and T.yellow or T.t3)
		g.glyph(U.G.warn, 11, U.PAD + 7, y + 19, c)
		g.text(500, 11.5, g.fit(500, 11.5, text, right - U.PAD - 24), U.PAD + 20, y + 19, c)
	end
end

function view.settings_body(y)
	local cx, cw = U.PAD, U.W - 2 * U.PAD
	local function toggle(key, name)
		return function(right, cy)
			view.switch(right - 34, cy - 10, P.set[key], name, function()
				P.set[key] = not P.set[key]
				save(key, P.set[key] and 1 or 0)
			end)
		end
	end
	local rows = {
		{ "adh_s_theme", function(right, cy)
			view.swatches(right, cy, THEME_ORDER, P.set.theme, "th:", function(id) return THEMES[id].menu end, function(id)
				P.set.theme = id
				save("theme", id)
				fade_theme(id)
			end)
		end },
		{ "adh_s_accent", function(right, cy)
			view.swatches(right, cy, ACCENT_ORDER, P.set.accent, "ac:", function(id) return ACCENTS[id] end, function(id)
				P.set.accent = id
				save("accent", id)
				fade_accent(id)
			end)
		end },
		{ "adh_s_opacity", function(right, cy) view.slider(right, cy, "opacity", 40, 100) end },
		{ "adh_s_blur", toggle("blur", "blur") },
		{ "adh_s_compact", toggle("compact", "compact") },
		{ "adh_s_icons", toggle("icons", "icons") },
		{ "adh_s_text", function(right, cy) view.slider(right, cy, "text", U.TEXT_MIN, U.TEXT_MAX) end },
		{ "adh_s_shadow", toggle("shadow", "shadow") },
		{ "adh_s_scale", function(right, cy) view.slider(right, cy, "scale", U.SCALE_MIN, U.SCALE_MAX) end },
	}
	local ch = 8 + #rows * 40
	g.rect(cx, y, cw, ch, C.card, 12)
	g.frame(cx, y, cw, ch, T.white, 12, 0.07)
	for i, row in ipairs(rows) do
		local ry = y + 4 + (i - 1) * 40
		if i > 1 then g.hl(cx + 14, ry, cw - 28, T.white, 0.05) end
		g.text(500, 14, tx(row[1]), cx + 14, ry + 20, T.t1)
		row[2](cx + cw - 14, ry + 20)
	end
	local by = y + ch + 14
	view.pill(cx, by, 160, 32, tx("adh_s_reset"), "soft", "reset_pos", view.reset_pos, 13)
	local lines = g.wrap(500, 11.5, tx("adh_s_hint"), cw - 174)
	for i = 1, math.min(3, #lines) do g.text(500, 11.5, lines[i], cx + 172, by + 7 + (i - 1) * 15, T.t3) end
end

function view.strip_items()
	local out = {}
	if not (D.ready and reader.active) then return out end
	if reader.phase == "draft" then
		for _, it in ipairs(P.items and P.items.picks or {}) do
			if it.kind == "pick" then out[#out + 1] = it end
		end
	elseif reader.phase == "game" then
		for _, it in ipairs(P.items and P.items.build or {}) do
			if it.kind == "gear" then out[#out + 1] = it end
		end
	end
	return out
end

function view.strip_layout(n)
	local size, gap = 34, 6
	local per = math.max(1, math.floor((U.W - 2 * U.PAD + gap) / (size + gap)))
	local rows = math.ceil(n / per)
	return size, gap, per, rows, rows > 0 and rows * (size + gap) + 12 or 0
end

function view.strip(y)
	local list = view.strip_items()
	local size, gap, per, rows = view.strip_layout(#list)
	local used = math.min(#list, per)
	local x0 = U.PAD + (U.W - 2 * U.PAD - (used * (size + gap) - gap)) / 2
	g.rect(U.PAD - 4, y + 2, U.W - 2 * U.PAD + 8, rows * (size + gap) + 2, T.white, 10, 0.035)
	for i, it in ipairs(list) do
		local col, row = (i - 1) % per, math.floor((i - 1) / per)
		local x, iy = x0 + col * (size + gap), y + 6 + row * (size + gap)
		local id = "strip:" .. it.key
		local hv = anim.hover(id)
		local lift = 2 * hv
		local pick = it.kind == "pick"
		local c = it.c or A
		local row_a = g.a
		if it.owned then g.a = row_a * 0.4 end
		if pick then c = it.rank == 1 and A or T.white end
		if hv > 0.01 then g.rect(x - 3, iy - 3 - lift, size + 6, size + 6, c, 9, 0.18 * hv) end
		if pick then g.ability(it.row.id, x, iy - lift, size, 1, 7) else g.item(it.item, x, iy - lift, size, 1, 7) end
		g.frame(x, iy - lift, size, size, c, 7, (pick and it.rank ~= 1 and 0.16 or 0.30) + 0.5 * hv, 1.2)
		g.rect(x + 8, iy + size + 1, size - 16, 2, c, 1, (pick and it.rank ~= 1 and 0.2 or 0.55) + 0.4 * hv)
		g.a = row_a
		if it.owned then
			g.dot(x + size - 3, iy + size - 3, 6, T.green)
			g.glyph(U.G.check, 7, x + size - 3, iy + size - 3, T.white)
		end
		if pick then
			local rid = it.row.id
			hit.add(x, iy, size, size, id, { click = function() reader.pick(rid) end, rclick = function() S.toggle_skip(rid) end })
		else
			hit.add(x, iy, size, size, id)
		end
		if hit.is(id) then mark_hover(it, iy - 6) end
	end
end

function view.grip(h)
	local W = U.W
	local on = hit.is("grip") or P.resize ~= nil
	local c = on and T.t2 or T.t4
	g.line(W - 6, h - 14, W - 14, h - 6, c, 0.9, 1.5)
	g.line(W - 6, h - 9, W - 9, h - 6, c, 0.9, 1.5)
	hit.add(W - 20, h - 20, 20, 20, "grip", { down = function(mx)
		P.resize = { mx = mx, w = W * g.s, scale = P.set.scale }
	end })
	if P.resize then
		local label = P.set.scale .. "%"
		local w = g.width(600, 12, label) + 16
		g.rect(W - 26 - w, h - 30, w, 22, C.menu, 11)
		g.frame(W - 26 - w, h - 30, w, 22, T.white, 11, 0.12)
		g.text(600, 12, label, W - 26 - w / 2, h - 19, T.t1, 1, "c")
	end
end

function view.window()
	local screen = Render.ScreenSize()
	g.s = math.max(0.7, screen.y / 1080) * P.set.scale / 100
	g.rescale(g.s)
	local W = U.W
	if not P.wx then view.home(screen) end
	P.wx = clamp(P.wx, 0, math.max(0, screen.x - W * g.s))
	P.wy = clamp(P.wy, 0, math.max(0, screen.y - math.max(P.h, U.HEAD) * g.s))

	if V.dirty or not P.items then
		P.items, V.dirty = view.build_items(), false
	end

	local collapsed, settings = P.set.collapsed, P.settings
	local fold = anim.tween("fold", collapsed and 1 or 0, 0.26, ease_in_out)
	local active = D.ready and reader.active
	local notice = view.notice()
	local roles_h = (not settings and D.ready) and U.ROLE or 0
	local tabs_h = (not settings and active and #view.tab_list() > 1) and U.TABS or 0
	local foot_h = (not settings and active and (notice ~= nil or S.skip_n > 0)) and U.FOOT or 0
	local chrome = U.HEAD + roles_h + tabs_h + foot_h
	local tab = view.cur_tab()
	local list = active and P.items[tab] or nil
	local body
	if settings then
		body = U.SET_H
	elseif active then
		local room = screen.y / g.s - P.wy / g.s - 16
		body = math.min(list_height(list), math.max(U.MIN_BODY, math.min(U.MAXH, room) - chrome))
	else
		body = D.ready and U.CARD_WAIT or U.CARD_LOAD
	end
	local full_h = chrome + body
	local strip_h = select(5, view.strip_layout(#view.strip_items()))
	local target = collapsed and (U.HEAD + strip_h) or full_h
	if P.h <= 0 then anim.snap("win_h", target) end
	P.h = anim.tween("win_h", target, 0.26, ease_in_out)
	local h = P.h

	local page_key = tostring(tab) .. ":" .. tostring(settings) .. ":" .. tostring(active)
	if page_key ~= P.page_key then
		P.page_key = page_key
		P.scroll_to = 0
		view.scroll_snap(0)
	end

	g.x, g.y, g.a = P.wx, P.wy, P.alpha
	hit.begin()
	P.hover_item = nil

	hit.add(0, 0, W, h, "win")
	local opacity = P.set.opacity / 100
	g.shadow(0, 0, W, h, 14, 0.07 * opacity)
	local blur_k = P.alpha ^ 4
	if P.set.blur and opacity < 1 and blur_k > 0.01 then
		Render.Blur(g.v(0, 0), g.v(W, h), 0.6 * 2 * blur_k, blur_k, 14 * g.s, ROUND)
	end
	g.rect(0, 0, W, h, C.win, 14, opacity)
	g.clip(0, 0, W, math.min(h, U.HEAD))
	g.rect(0, 0, W, U.HEAD + 24, A, 14, 0.10)
	g.unclip()

	view.header()
	local base_a = g.a
	if h > U.HEAD + 1 then
		g.clip(0, U.HEAD, W, h - U.HEAD)
		if fold < 0.999 then
			local mark = #hit.list
			g.a = base_a * (1 - fold) ^ 1.5
			local y = U.HEAD
			if settings then
				view.settings_body(y + 4)
			else
				if roles_h > 0 then
					view.roles(y)
					y = y + roles_h
				end
				if tabs_h > 0 then
					view.tabs(y)
					y = y + tabs_h
				end
				if active then
					view.draw_list(list, y, math.max(0, full_h - y - foot_h))
					if foot_h > 0 then view.footer(full_h - foot_h) end
				else
					view.state_card(y)
				end
			end
			if collapsed then
				for k = #hit.list, mark + 1, -1 do hit.list[k] = nil end
				P.hover_item = nil
			end
		end
		if fold > 0.001 and strip_h > 0 then
			local mark = #hit.list
			g.a = base_a * fold ^ 1.5
			view.strip(U.HEAD + (1 - fold) * 10)
			if not collapsed then
				for k = #hit.list, mark + 1, -1 do hit.list[k] = nil end
			end
		end
		g.a = base_a
		g.unclip()
	end

	g.frame(0, 0, W, h, T.white, 14, 0.09)
	g.hl(18, 0, W - 36, AT, 0.35)
	if fold < 0.5 then view.grip(h) end

	-- tooltip target: the hovered row, after a short delay and never while dragging
	local hv = P.hover_item
	if hv ~= P.hover_prev then P.hover_prev, P.hover_since = hv, P.now end
	if hv then P.hover_y_last = P.hover_y end
	if hv and hv.tip and P.now - P.hover_since >= U.TIP_DELAY and not P.drag and not P.resize and not P.sb_drag then
		P.tip = hv
	else
		P.tip = nil
	end
	view.tip()
end

-- ---------------------------------------------------------------------------
-- menu
-- ---------------------------------------------------------------------------

do
	local tab = UI.Create("Scripts", "Scripts", "Ability Draft Helper")
	tab:Icon("\u{f0e7}")

	local page = tab:Create("Settings")
	local g_main = page:Create("adh_group_main", Enum.GroupSide.Left)

	ui.enable = g_main:Switch("adh_enable", true, "\u{f011}")
	ui.enable:ToolTip("adh_enable_tip")

	ui.show = g_main:Switch("adh_show", true, "\u{f06e}")
	ui.show:ToolTip("adh_show_tip")

	ui.key = g_main:Bind("adh_key", Enum.ButtonCode.KEY_NONE, "\u{f11c}")
	ui.key:ToolTip("adh_key_tip")
	ui.key:Properties(L("adh_bind_name"))

	ui.preview = g_main:Switch("adh_preview", false, "\u{f06e}")
	ui.preview:ToolTip("adh_preview_tip")

	ui.side = g_main:Combo("adh_side", { "adh_side_left", "adh_side_right" }, 0)
	ui.side:ToolTip("adh_side_tip")

	ui.role = g_main:Combo("adh_role", {
		"adh_role_off", "adh_role_carry", "adh_role_mid", "adh_role_offlane",
		"adh_role_support", "adh_role_hard_support",
	}, 0)
	ui.role:ToolTip("adh_role_tip")

	local g_data = page:Create("adh_group_data", Enum.GroupSide.Right or Enum.GroupSide.Left)

	ui.refresh = g_data:Button("adh_refresh", data.refresh)
	ui.refresh:Icon("\u{f021}")
	ui.refresh:ToolTip("adh_refresh_tip")

	ui.reset = g_data:Button("adh_reset_pos", view.reset_pos)
	ui.reset:Icon("\u{f0e2}")
	ui.reset:ToolTip("adh_reset_pos_tip")

	ui.dump = g_data:Button("adh_dump", dump_tree)
	ui.dump:Icon("\u{f0c9}")
	ui.dump:ToolTip("adh_dump_tip")

	ui.debug = g_data:Switch("adh_debug", false, "\u{f188}")
	ui.debug:ToolTip("adh_debug_tip")
end

-- ---------------------------------------------------------------------------
-- input
-- ---------------------------------------------------------------------------

local input = { swallow = false, held = {} }

local function inside(mx, my)
	return P.wx and mx >= P.wx and my >= P.wy and mx < P.wx + U.W * g.s and my < P.wy + P.h * g.s
end

function input.press(mx, my, button)
	local h = hit.at(mx, my)
	local id, on = h and h[5], h and h[6] or {}
	if button == 2 then
		if on.rclick then on.rclick(mx, my) end
		return
	end
	P.press = { id = id or false, on = on }
	if on.down then on.down(mx, my) end
end

function input.release(mx, my)
	local press = P.press
	P.press = nil
	if not press or not press.id then return end
	if P.moved then
		P.moved = false
		return
	end
	local h = hit.at(mx, my)
	if not h or h[5] ~= press.id then return end
	local on = press.on
	if on.dbl and P.last_click.id == press.id and P.now - P.last_click.t < U.DOUBLE then
		P.last_click.id = nil
		on.dbl()
		return
	end
	P.last_click.id, P.last_click.t = press.id, P.now
	if on.click then on.click(mx, my) end
end

function input.end_drag()
	if P.drag then
		save("wx", math.floor(P.wx))
		save("wy", math.floor(P.wy))
	end
	if P.resize then save("scale", P.set.scale) end
	if P.slide then save(P.slide.key, P.set[P.slide.key]) end
	P.drag, P.resize, P.slide, P.sb_drag = nil, nil, nil, nil
end

-- the helper runs only for accounts listed in K.USERS on GitHub; nil until Steam and the list answer
local access = { ok = nil, at = 0, wait = false }

local function access_decide(n, text)
	access.ok = false
	for line in text:gmatch("[^\r\n]+") do
		if tonumber(line:match("^%s*(%d+)")) == n then access.ok = true break end
	end
	if not access.ok then say("this Steam account has no access to the helper") end
end

function access.check()
	if access.ok ~= nil then return access.ok end
	if access.wait or os.clock() < access.at then return false end
	access.at = os.clock() + 2
	local ok, id = pcall(GC.GetSteamID)
	local n = ok and math.tointeger(tonumber(tostring(id or ""))) or nil
	if not n or n <= 76561197960265728 then return false end
	n = n - 76561197960265728
	access.wait = true
	local sent = HTTP.Request("GET", K.DATA .. K.USERS, { headers = { ["User-Agent"] = K.AGENT }, timeout = K.TIMEOUT }, function(r)
		access.wait = false
		local body = type(r.response) == "string" and r.response or ""
		if tonumber(r.code) == 200 and #body > 0 then
			write_file(K.USERS, body)
			access_decide(n, body)
			return
		end
		-- offline: fall back to the last list that came from GitHub
		local cached = read_file(K.USERS)
		if cached then return access_decide(n, cached) end
		access.at = os.clock() + K.RETRY
	end)
	if not sent then
		access.wait = false
		access.at = os.clock() + K.RETRY
	end
	return false
end

local script = {}

function script.OnScriptsLoaded()
	S.loaded = true
	say("loaded")
end

function script.OnUpdateEx()
	if not ui.enable:Get() or not access.check() then return end
	data.tick()
	reader.tick()
	if ui.key:IsPressed() and not Input.IsInputCaptured() then ui.show:Set(not ui.show:Get()) end
end

function script.OnFrame()
	if not ui.enable:Get() or not access.ok then return end
	local now = os.clock()
	local frame = GlobalVars.GetAbsFrameTime()
	P.dt = clamp(frame > 0 and frame or (now - (P.now > 0 and P.now or now)), 0, 0.1)
	P.now = now
	fade_tick(P.dt)
	asset.budget = 3
	lang_sync()
	local want = ui.show:Get() and (reader.visible or reader.phase == "game" or ui.preview:Get())
	P.alpha = anim.tween("window", want and 1 or 0, 0.18)
	if P.alpha <= 0.001 then
		P.tip, P.press, P.drag, P.resize, P.slide, P.sb_drag = nil, nil, nil, nil, nil, nil
		return
	end

	if P.press and not Input.IsKeyDown(KEY.KEY_MOUSE1, true) then
		input.end_drag()
		P.press = nil
	end
	for key in pairs(input.held) do
		if not Input.IsKeyDown(key, true) then input.held[key] = nil end
	end
	local mx, my = Input.GetCursorPos()
	if P.drag then
		if math.abs(mx - P.drag.mx) + math.abs(my - P.drag.my) > 4 then P.moved = true end
		P.wx, P.wy = P.drag.wx + mx - P.drag.mx, P.drag.wy + my - P.drag.my
	end
	if P.slide then view.slide_to(mx) end
	if P.sb_drag then
		local d = P.sb_drag
		local v = clamp(d.scroll + (my - d.my) / g.s * d.k, 0, math.max(0, P.content_h - P.view_h))
		P.scroll_to = v
		view.scroll_snap(v)
		P.scroll_t = P.now
	end
	if P.resize then
		local r = P.resize
		P.set.scale = clamp(math.floor(r.scale * (r.w + mx - r.mx) / r.w + 0.5), U.SCALE_MIN, U.SCALE_MAX)
	end

	local ok, err = pcall(view.window)
	if ok then return end
	g.reset()
	if err ~= P.draw_error then
		P.draw_error = err
		say("draw error: " .. tostring(err))
	end
end

function script.OnKeyEvent(e)
	if not ui.enable:Get() or not access.ok or P.alpha <= 0.02 then return true end
	local mx, my = Input.GetCursorPos()
	local over = inside(mx, my)

	if e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_UP or e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_DOWN then
		if not over then return true end
		for i = #hit.list, 1, -1 do
			local h = hit.list[i]
			if h[5] == "content" and mx >= h[1] and mx < h[3] and my >= h[2] and my < h[4] then
				h[6].wheel(e.event == Enum.EKeyEvent.EKeyEvent_SCROLL_DOWN and 1 or -1)
				break
			end
		end
		return false
	end

	if e.key == KEY.KEY_MOUSE1 or e.key == KEY.KEY_MOUSE2 then
		local left = e.key == KEY.KEY_MOUSE1
		if e.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN then
			if input.held[e.key] then return not input.swallow end
			input.held[e.key] = true
			if not over then
				if left then P.press = { id = false } end
				return true
			end
			input.swallow = true
			input.press(mx, my, left and 1 or 2)
			return false
		elseif e.event == Enum.EKeyEvent.EKeyEvent_KEY_UP then
			input.held[e.key] = nil
			if left then
				input.end_drag()
				input.release(mx, my)
			end
			if input.swallow then
				input.swallow = false
				return false
			end
		end
		return true
	end

	if e.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN and e.key == KEY.KEY_ESCAPE and over and P.settings then
		P.settings = false
		return false
	end
	return true
end

ui.enable:SetCallback(function()
	local on = ui.enable:Get()
	ui.show:Disabled(not on)
	ui.key:Disabled(not on)
	ui.preview:Disabled(not on)
	ui.side:Disabled(not on)
	ui.role:Disabled(not on)
	if not on then input.end_drag() end
end, true)

ui.side:SetCallback(function() view.reset_pos() end)
ui.role:SetCallback(function()
	local role = tonumber(ui.role:Get()) or 0
	if role == reader.role_seen then return end
	reader.role_seen = role
	reader.refresh()
end)

return script
