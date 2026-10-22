local script = {}
local ui, native_bind
local run, held = nil, false
local last_draw_error
local observers={}
local manual_jump
local threat_roster, roster_updated = {}, -math.huge
local last_status = "ready"
local unpack_args = table.unpack or unpack
local ID = "techies_cursor_standalone"
local last_update_error
local callback_errors={}
local BASE = {"Heroes", "Hero List", "Techies"}
local TAB_NAME = "Жёсткий Ебырь"
local indicator_paths = {
    {"Heroes", "Hero List", "Techies", "Extra Settings", "Target Selection", "Draw Particle"},
    {"Heroes", "", "Settings", "General", "Target Selection", "Draw Particle"},
    {"Heroes", "Hero List", "Techies", "Main Settings", "Hero Settings", "Draw Radius"},
}
local BLINKS={"item_arcane_blink","item_swift_blink","item_overwhelming_blink","item_blink"}
local MAD="techies_mutually_assured_destruction"
local DETONATE="techies_focused_detonate"
local SPELLS={"techies_reactive_tazer","techies_suicide","techies_land_mines","techies_sticky_bomb","techies_reactive_tazer_stop",MAD}
local MAIN_SPELLS={}
for _,name in ipairs(SPELLS) do MAIN_SPELLS[#MAIN_SPELLS+1]=name end
table.insert(MAIN_SPELLS,#MAIN_SPELLS,"item_refresher")
local DANGEROUS={"enigma_black_hole","faceless_void_chronosphere","magnataur_reverse_polarity",
    "tidehunter_ravage","earthshaker_echo_slam","doom_bringer_doom","disruptor_static_storm",
    "silencer_global_silence","legion_commander_duel","bane_fiends_grip","lion_voodoo","shadow_shaman_voodoo"}
local THREAT_HEROES={enigma_black_hole="npc_dota_hero_enigma",faceless_void_chronosphere="npc_dota_hero_faceless_void",
    magnataur_reverse_polarity="npc_dota_hero_magnataur",tidehunter_ravage="npc_dota_hero_tidehunter",
    earthshaker_echo_slam="npc_dota_hero_earthshaker",doom_bringer_doom="npc_dota_hero_doom_bringer",
    disruptor_static_storm="npc_dota_hero_disruptor",silencer_global_silence="npc_dota_hero_silencer",
    legion_commander_duel="npc_dota_hero_legion_commander",bane_fiends_grip="npc_dota_hero_bane",
    lion_voodoo="npc_dota_hero_lion",shadow_shaman_voodoo="npc_dota_hero_shadow_shaman"}
local ITEMS={"item_blink","item_black_king_bar","item_bloodthorn","item_orchid","item_sheepstick",
    "item_abyssal_blade","item_gungir","item_rod_of_atos","item_nullifier","item_disperser",
    "item_diffusal_blade","item_veil_of_discord","item_shivas_guard","item_ethereal_blade",
    "item_dagon_5","item_heavens_halberd","item_refresher","item_glimmer_cape","item_ghost"}
local NAMES={
    techies_reactive_tazer={"Reactive Tazer","Реактивный тазер"},techies_suicide={"Blast Off","Прыжок Blast Off"},
    techies_land_mines={"Proximity Mines","Мины вокруг Techies"},techies_sticky_bomb={"Sticky Bomb","Липкая бомба"},
    techies_reactive_tazer_stop={"Detonate Tazer","Взорвать тазер"},
    techies_mutually_assured_destruction={"M.A.D. shard","Шард M.A.D."},
    techies_focused_detonate={"Detonate M.A.D.","Подорвать M.A.D."},
    item_blink={"Blink (all upgrades)","Блинк (все улучшения)"},item_black_king_bar={"Black King Bar","БКБ"},
    item_bloodthorn={"Bloodthorn","Бладторн"},item_orchid={"Orchid","Орчид"},item_sheepstick={"Scythe of Vyse","Хекс"},
    item_abyssal_blade={"Abyssal Blade","Абиссал"},item_gungir={"Gleipnir","Глейпнир"},item_rod_of_atos={"Rod of Atos","Атос"},
    item_nullifier={"Nullifier","Нулифаер"},item_disperser={"Disperser","Дисперсер"},item_diffusal_blade={"Diffusal Blade","Диффуза"},
    item_veil_of_discord={"Veil of Discord","Вейл"},item_shivas_guard={"Shiva's Guard","Шива"},
    item_ethereal_blade={"Ethereal Blade","Этериал"},item_dagon_5={"Dagon (all levels)","Дагон (все уровни)"},
    item_heavens_halberd={"Heaven's Halberd","Алебарда"},item_refresher={"Refresher: second wave of mines","Рефрешер: вторая волна мин"},
    item_glimmer_cape={"Glimmer Cape: self","Глиммер: на себя"},
    item_ghost={"Ghost Scepter: self","Гост: на себя"}}
for id,name in pairs({enigma_black_hole="Black Hole",faceless_void_chronosphere="Chronosphere",
    magnataur_reverse_polarity="Reverse Polarity",tidehunter_ravage="Ravage",earthshaker_echo_slam="Echo Slam",
    doom_bringer_doom="Doom",disruptor_static_storm="Static Storm",silencer_global_silence="Global Silence",
    legion_commander_duel="Duel",bane_fiends_grip="Fiend's Grip",lion_voodoo="Lion: Hex",shadow_shaman_voodoo="Shaman: Hex"}) do
    NAMES[id]={name,name}
end
local TEXT={
    ready={"Ready — hold your combo key","Готово — удерживай клавишу комбо"},finished={"Done — release key","Готово — отпусти клавишу"},
    conflict={"Native combo active — release both keys","Штатное комбо активно — отпусти обе клавиши"},
    stopped={"Combo stopped","Комбо остановлено"},changed={"Hero changed","Герой сменился"},
    timeout={"Timed out — release key","Таймаут — отпусти клавишу"},nopoint={"No cursor point","Нет точки курсора"},
    error={"Error — see log","Ошибка — смотри журнал"},gameend={"Game ended","Игра завершена"},
    castwait={"Cast timed out — release key","Применение затянулось — отпусти клавишу"},
    approach={"Moving into Blast Off range","Подход к дальности Blast Off"},
    jumpwait={"Waiting for Blast Off","Ожидание готовности Blast Off"},
    cursor={"Cursor: ","Курсор: "},target={"Item target","Цель предметов"}}

local sequence_text=qLocalization.new({
    en={post="After Refresher",post_tip="Click to enable; drag to order. Abilities only, including a second Blast Off. Both mine waves use Mines per wave. M.A.D. plants and detonates without Blink.",
        main_tip="Click to enable; drag abilities and Refresher into order. Refresher runs its separate ability list here, then resumes this list. M.A.D. plants and detonates. Retreat Blink follows the complete cast sequence.",
        item_tip="Drag to set item order. Combat items keep their target priorities and run once after the opening Tazer/Blast Off steps. BKB prepares entry; Blink keeps its entry/retreat setting. Refresher is in the main ability order.",
        refresher="Refresher: run the After Refresher list",mad_post="M.A.D.: plant and detonate",
        panel={combo="Combo",items="Items & retreat",enabled="Enable",bind="Combo key",interface="Interface",
            compact="Collapse settings",show_combo="Sequences",show_mines="Mines",show_items="Items",show_visuals="Indicators",
            layout_tip="Only changes what is displayed. Hidden settings keep working. Collapse settings leaves Enable and Combo key.",
            bind_tip="Hold to execute one combo. Release to stop new orders. Use a separate, unused key.",
            mine_tip="Shared by the main and post-Refresher waves. Open the gear for radius and timing.",
            ring_tip="Radius of the existing mine formation. Applies to both waves.",
            near_tip="Distance to the landing point at which mine placement can begin.",
            interval_tip="Minimum interval between combo orders, in milliseconds.",
            radius_tip="Enemy search radius around the cursor for combat items.",
            lock_mode="Cast mode",lock_mode_tip="Off: cast at cursor. Lock point: freeze cursor on press. Lock target: pick one enemy hero — Blast Off, mines, and all spells go at that hero.",
            lock_off="Off",lock_point="Lock point",lock_target="Lock target",
            hex="Smart Hex",priority="Target priority",ethereal="Ethereal on self",
            hex_tip="Dangerous heroes in icon order, then BKB carriers, then nearest. Hex keeps its place in item order and waits for range. Unseen, immune and reflecting targets are excluded.",
            priority_tip="Click to enable, drag to prioritize. First enabled icon has the highest priority.",
            ethereal_tip="On: Ethereal Blade targets yourself. Off: the enemy item target. Ghost Scepter always targets yourself.",
            cursor="Cursor position",target="Item target",mine_marks="Mine positions",
            random="Random",fountain="Fountain",back="Back to start",
            direction_tip="Maximum range in the chosen direction. Nearby points in that direction are checked if the path is blocked.",
            legit="Legit mines",legit_tip="Adds random jitter to mine positions and random pauses between casts.",
            legit_jitter="Position jitter",legit_jitter_tip="Max offset of each mine from the perfect point, in units. 0 = perfect.",
            legit_pause="Random pause",legit_pause_tip="Random pause before each mine placement, in milliseconds. 0 = instant.",
            inflight="Mines in flight",inflight_tip="Place all mines at the landing point while airborne after Blast Off. Never at the jump start.",
            mine_delay="Delay between mines",mine_delay_tip="Delay between individual mine placements, in milliseconds. Lower = faster.",
            spells_in_flight="Tazer + Sticky in flight",spells_in_flight_tip="Cast Reactive Tazer and Sticky Bomb while airborne after Blast Off.",
            mine_speed_block="Mine speed"},
        menu={section="Section",compact="Collapsed",combo="Combo",mines="Mines",items="Items",visuals="Indicators",all="All settings",
            section_tip="Show one section at a time. Collapsed hides settings without disabling them. All settings shows every control.",
            general="Control",rules="Item rules",advanced="Details",advanced_tip="Show fine-tuning and language. All settings always includes these controls.",
            main="Main sequence",post="After Refresher",item_order="Item order",mine_count="Mines per wave",ring="Ring radius",
            near="Start placement",interval="Order interval, ms",radius="Target radius",exit="Retreat Blink",direction="Retreat direction",
            exit_tip="Attempt retreat after all selected casts. An unavailable opening jump can still trigger entry Blink; retreat requires Blink to be ready.",
            visual="Show indicators",language="Language",mine_speed="Mine placement",legit="Legit mines",spells_flight="Spells in flight"}},
    ru={post="После Рефрешера",post_tip="Клик — включить; перетаскивание — порядок. Только способности, включая второй прыжок. Обе волны используют настройку «Мин за волну». M.A.D.: установка и подрыв без Блинка.",
        main_tip="Клик — включить; перетаскивание — порядок способностей и Рефрешера. Рефрешер выполняет отдельный список способностей, затем продолжается этот список. M.A.D.: установка и подрыв. Блинк для отхода — после всего прокаста.",
        item_tip="Перетаскивание задаёт порядок предметов. Боевые предметы сохраняют приоритеты целей и применяются один раз после начальных тазера/прыжка. БКБ готовит вход; Блинк сохраняет настройку входа/отхода. Рефрешер находится в основном порядке способностей.",
        refresher="Рефрешер: выполнить список «После Рефрешера»",mad_post="M.A.D.: установка и подрыв",
        panel={combo="Комбо",items="Предметы и отход",enabled="Включить",bind="Клавиша комбо",interface="Интерфейс",
            compact="Свернуть настройки",show_combo="Последовательности",show_mines="Мины",show_items="Предметы",show_visuals="Индикация",
            layout_tip="Меняет только видимость. Скрытые настройки продолжают работать. Сворачивание оставляет включение и клавишу комбо.",
            bind_tip="Удерживай для одного комбо. Отпускание останавливает новые команды. Выбери отдельную свободную клавишу.",
            mine_tip="Общее количество для основной волны и волны после Рефрешера. Радиус и тайминги — в шестерёнке.",
            ring_tip="Радиус существующей схемы расстановки. Применяется к обеим волнам.",
            near_tip="Расстояние до точки приземления, с которого разрешено начинать установку мин.",
            interval_tip="Минимальный интервал между командами комбо в миллисекундах.",
            radius_tip="Радиус поиска вражеской цели предметов вокруг курсора.",
            lock_mode="Режим каста",lock_mode_tip="Выкл: каст по курсору. Фикс точки: точка замораживается при нажатии. Фикс цели: одна цель — Бласт, мины и все способности летят в неё.",
            lock_off="Выкл",lock_point="Фикс точки",lock_target="Фикс цели",
            hex="Умный Hex",priority="Приоритет целей",ethereal="Этериал на себя",
            hex_tip="Опасные герои по порядку иконок, затем владельцы БКБ, затем ближайший. Hex сохраняет место в порядке предметов и ждёт дальности. Невидимые цели, активный иммунитет и отражение исключаются.",
            priority_tip="Клик — включить, перетаскивание — приоритет. Первая включённая иконка имеет высший приоритет.",
            ethereal_tip="Включено: Этериал применяется на себя. Выключено: на вражескую цель предметов. Гост всегда активируется на себя.",
            cursor="Точка курсора",target="Цель предметов",mine_marks="Позиции мин",
            random="Случайно",fountain="К фонтану",back="К началу комбо",
            direction_tip="Предельная дальность в выбранном направлении. При препятствии проверяются соседние точки в том же направлении.",
            legit="Легит мины",legit_tip="Добавляет случайный разброс позициям мин и случайные паузы между кастами.",
            legit_jitter="Разброс позиций",legit_jitter_tip="Максимальное смещение каждой мины от идеальной точки, в юнитах. 0 = идеально.",
            legit_pause="Случайная пауза",legit_pause_tip="Случайная пауза перед установкой каждой мины, в миллисекундах. 0 = мгновенно.",
            inflight="Мины в полёте",inflight_tip="Ставит все мины в точку приземления пока летишь после Blast Off. Никогда в точку старта.",
            mine_delay="Задержка между минами",mine_delay_tip="Задержка между отдельными постановками мин, в миллисекундах. Меньше = быстрее.",
            spells_in_flight="Тазер + Липкая в полёте",spells_in_flight_tip="Кастует Reactive Tazer и Sticky Bomb пока летишь после Blast Off.",
            mine_speed_block="Скорость мин"},
        menu={section="Раздел",compact="Свернуто",combo="Комбо",mines="Мины",items="Предметы",visuals="Индикация",all="Все настройки",
            section_tip="Один раздел за раз. Свернутые настройки продолжают работать. «Все настройки» показывает все параметры.",
            general="Управление",rules="Правила предметов",advanced="Подробно",advanced_tip="Показать тонкую настройку и язык. В режиме «Все настройки» они видны всегда.",
            main="Порядок способностей",post="После Рефрешера",item_order="Порядок предметов",mine_count="Мин за волну",ring="Радиус схемы",
            near="Начало установки",interval="Интервал команд, мс",radius="Радиус выбора цели",exit="Blink для отхода",direction="Направление отхода",
            exit_tip="Отход после всех выбранных действий. Если начальный прыжок недоступен, Blink может использоваться для входа; для отхода он должен быть готов.",
            visual="Показывать индикацию",language="Язык",mine_speed="Постановка мин",legit="Легит мины",spells_flight="Способности в полёте"}}
})
local localized={}
local function lang() return ui and ui.language and ui.language:Get()==1 and 1 or 2 end
local function label(key)
    local pair=TEXT[key] or NAMES[key]
    if not pair and key:match("^item_dagon") then pair=NAMES.item_dagon_5 end
    if not pair and key:match("^item_.*blink$") then pair=NAMES.item_blink end
    return pair and pair[lang()] or key
end
local function localize_widget(w,en,ru,tip_en,tip_ru)
    localized[#localized+1]={w=w,text={en,ru},tip=tip_en and {tip_en,tip_ru} or nil}
    return w
end
local function apply_language()
    local index=lang()
    for _,entry in ipairs(localized) do
        if entry.text then entry.w:ForceLocalization(entry.text[index]) end
        if entry.tip then entry.w:ToolTip(entry.tip[index]) end
    end

    local language_index
    for i=0,32 do
        if sequence_text.GetLanguage(i)==(index==2 and "ru" or "en") then language_index=i; break end
    end
    sequence_text.Update(language_index)
    for _,pair in ipairs({{ui.abilities,MAIN_SPELLS},{ui.items,ITEMS},{ui.dangerous,DANGEROUS},{ui.post,SPELLS}}) do
        local tips={}
        for _,id in ipairs(pair[2]) do
            tips[id]=id=="item_refresher" and sequence_text.Localize("refresher",language_index)
                or id==MAD and sequence_text.Localize("mad_post",language_index) or label(id)
        end
        pair[1]:UpdateToolTips(tips)
        if ui.panel then
            for _,name in ipairs({"abilities","items","dangerous","post"}) do
                if ui[name]==pair[1] then ui.panel[name]:UpdateToolTips(tips) end
            end
        end
    end
    if ui.blink_direction and not ui.panel then
        local selected=ui.blink_direction:Get()
        ui.blink_direction:Update(index==2 and {"Случайно","К фонтану","Назад"} or {"Random","Fountain","Back to start"},selected)
    end

end
local function icon_items(ids)
    local result={}
    for _,id in ipairs(ids) do
        local item=id:sub(1,5)=="item_"
        local icon=item and id:sub(6) or id
        result[#result+1]={id,"panorama/images/"..(item and "items/" or "spellicons/")..icon.."_png.vtex_c",
            id~="item_refresher" and id~="item_black_king_bar"}
    end
    return result
end
local function enabled_proxy(selector,id) return {Get=function() return selector:Get(id) end} end

local function lock_mode() return ui.lock_mode and ui.lock_mode:Get() or 0 end
local function lock_point() return lock_mode()==1 end
local function lock_target() return lock_mode()==2 end

local function build_menu_panel(tab,old_groups)

    for _,group in ipairs(old_groups) do group:Visible(false) end
    local migrated=old_groups[1]:Switch("Compact menu values migrated v5",false)
    migrated:Visible(false)
    local importing=not migrated:Get()
    local left=sequence_text.Wrap(tab:Create("Compact combo v5",Enum.GroupSide.Left),true)
    local right=sequence_text.Wrap(tab:Create("Compact items v5",Enum.GroupSide.Right),true)
    sequence_text.Register(left,"panel.combo"); sequence_text.Register(right,"panel.items")
    local p,view={},{}
    ui.panel,ui.view=p,view
    ui.menu_groups={combo=left,items=right}
    local function rows(w)
        local list={}
        for _,id in ipairs(w:List()) do
            local row=icon_items({id})[1]; row[3]=w:Get(id); list[#list+1]=row
        end
        return list
    end
    local function link(name,widget,kind,tip)
        p[name]=widget
        widget:Icon("")
        if tip then widget:ToolTip(tip) end
        local old=ui[name]
        if importing then

            if kind=="select" then widget:Set(old:ListEnabled())
            elseif kind=="bind" then widget:Set(old:Buttons())
            else widget:Set(old:Get()) end
        end
        ui[name]=widget
        return widget
    end
    local function switch(parent,name,key,tip) return link(name,parent:Switch(key,ui[name]:Get()),nil,tip) end
    local function slider(parent,name,key,min,max,tip) return link(name,parent:Slider(key,min,max,ui[name]:Get()),nil,tip) end
    local function select(parent,name,key,tip)
        local w=link(name,parent:MultiSelect(key,rows(ui[name]),true),"select",tip)
        w:DragAllowed(true)
        return w
    end
    switch(left,"enabled","panel.enabled")
    local layout=p.enabled:Gear("panel.interface")
    view.compact=layout:Switch("panel.compact",false); view.compact:ToolTip("panel.layout_tip")
    for _,name in ipairs({"combo","mines","items","visuals"}) do
        view[name]=layout:Switch("panel.show_"..name,true); view[name]:ToolTip("panel.layout_tip")
    end
    link("language",layout:Combo("menu.language",{"Русский","English"},0))
    link("bind",left:Bind("panel.bind",ui.bind:Get()),"bind","panel.bind_tip")
    p.lock_mode=left:Combo("panel.lock_mode",{"panel.lock_off","panel.lock_point","panel.lock_target"},ui.lock_mode and ui.lock_mode:Get() or 0)
    p.lock_mode:ToolTip("panel.lock_mode_tip")
    p.lock_mode:Icon("")
    ui.lock_mode=p.lock_mode
    select(left,"abilities","menu.main","main_tip")
    select(left,"post","menu.post","post_tip")
    slider(left,"mines","menu.mine_count",0,3,"panel.mine_tip")
    local formation=p.mines:Gear("menu.mines")
    slider(formation,"ring","menu.ring",210,320,"panel.ring_tip")
    slider(formation,"near","menu.near",240,500,"panel.near_tip")
    slider(formation,"interval","menu.interval",30,200,"panel.interval_tip")
    switch(left,"inflight","panel.inflight","panel.inflight_tip")
    switch(left,"spells_in_flight","panel.spells_in_flight","panel.spells_in_flight_tip")
    slider(left,"mine_delay","panel.mine_delay",10,300,"panel.mine_delay_tip")
    switch(left,"visual","menu.visual")
    local indicators=p.visual:Gear("menu.visuals")
    switch(indicators,"cursor_mark","panel.cursor")
    switch(indicators,"target_mark","panel.target")
    switch(indicators,"mine_mark","panel.mine_marks")
    select(right,"items","menu.item_order","item_tip")
    slider(right,"radius","menu.radius",100,1200,"panel.radius_tip")
    switch(right,"smart_hex","panel.hex","panel.hex_tip")
    local priorities=p.smart_hex:Gear("panel.priority")
    select(priorities,"dangerous","panel.priority","panel.priority_tip")
    switch(right,"ethereal_self","panel.ethereal","panel.ethereal_tip")
    switch(right,"exit_blink","menu.exit","menu.exit_tip")
    local retreat=p.exit_blink:Gear("menu.direction")
    link("blink_direction",retreat:Combo("menu.direction",{"panel.random","panel.fountain","panel.back"},0),nil,"panel.direction_tip")
    local previous
    local function update_visibility()
        local compact=view.compact:Get()
        local disabled=not p.enabled:Get()
        local combo,mines,items,visuals=not compact and view.combo:Get(),not compact and view.mines:Get(),
            not compact and view.items:Get(),not compact and view.visuals:Get()
        local refresh=ui.abilities:Get("item_refresher")
        local key=table.concat({tostring(compact),tostring(disabled),tostring(combo),tostring(mines),tostring(items),tostring(visuals),tostring(refresh)},"|")
        if key==previous then return end
        previous=key
        p.abilities:Visible(combo); p.post:Visible(combo and refresh)
        p.mines:Visible(mines); p.visual:Visible(visuals)
        p.inflight:Visible(mines); p.mine_delay:Visible(mines); p.spells_in_flight:Visible(mines)

        for _,name in ipairs({"items","radius","smart_hex","dangerous","ethereal_self","exit_blink","blink_direction"}) do
            p[name]:Visible(items)
        end
        right:Visible(items)
        for name,widget in pairs(p) do widget:Disabled(name~="enabled" and disabled) end
        for _,name in ipairs({"combo","mines","items","visuals"}) do view[name]:Visible(not compact) end
    end
    for _,w in pairs(view) do w:SetCallback(update_visibility) end
    ui.abilities:SetCallback(update_visibility)
    ui.refresh_visibility=update_visibility
    migrated:Set(true)
    update_visibility()
    return update_visibility
end

local function safe(fn,...)
    if type(fn)~="function" then return nil end
    local ok,result=pcall(fn,...)
    return ok and result or nil
end
local function guarded_event(name,fn)
    local ok,err=pcall(fn)
    if not ok and callback_errors[name]~=tostring(err) then
        callback_errors[name]=tostring(err)

        safe(Log.Write,"Techies Cursor "..name..": "..tostring(err))
    end
end
local function now() return GlobalVars.GetCurTime() end
local function copy(v) return Vector(v.x,v.y,v.z) end
local function dist(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
local function find(path) return safe(Menu.Find,unpack_args(path)) end
local function state(npc,name)
    local value=Enum.ModifierState[name]
    return value~=nil and NPC.HasState(npc,value)
end
local function restore_indicators()
    if not ui or not ui.restore:Get() then return end
    for i,path in ipairs(indicator_paths) do
        local widget=find(path)
        if widget and ui.saved_exists[i]:Get() then widget:Set(ui.saved[i]:Get()) end
    end
    ui.restore:Set(false)
end
local function hide_indicators()

    for i,path in ipairs(indicator_paths) do
        local widget=find(path)
        ui.saved_exists[i]:Set(widget~=nil)
        if widget then ui.saved[i]:Set(widget:Get()) end
    end
    ui.restore:Set(true)
    for _,path in ipairs(indicator_paths) do local w=find(path); if w then w:Set(false) end end
end
local function stop_walk()
    if run and run.walking then
        run.walking=false
        if Player and Players then safe(Player.HoldPosition,Players.GetLocal(),run.hero,false,false,true,ID) end
    end
end
local function stop(reason)
    stop_walk()

    if run and run.pending and not run.pending.logged and run.pending.mode=="mine" then
        observers[#observers+1]=run.pending
    end

    run=nil; last_status=reason or "ready"
    restore_indicators()
end
local function init()
    if ui then return true end
    local root=find(BASE)
    if not root then return false end
    local tab=root:Create(TAB_NAME)
    tab:Image("")
    local g=localize_widget(tab:Create("Controls",Enum.GroupSide.Left),"General","Основное")
    ui={}
    ui.enabled=localize_widget(g:Switch("Enable",true),"Enable","Включить")
    ui.enabled:Icon("")
    ui.bind=localize_widget(g:Bind("Cursor Combo Key",Enum.ButtonCode.KEY_G),"Combo key","Клавиша комбо",
        "One combo per press. Release stops new orders. Choose a separate, unused key.","Одно комбо за нажатие. Отпускание останавливает новые команды. Выбери отдельную свободную клавишу.")
    ui.bind:Icon(utf8.char(0xf11c))

    ui.menu_section=sequence_text.Wrap(g,true):Combo("menu.section",
        {"menu.compact","menu.combo","menu.mines","menu.items","menu.visuals","menu.all"},0)
    ui.menu_section:ToolTip("menu.section_tip")
    ui.advanced=localize_widget(g:Switch("Advanced settings",false),"Advanced settings","Подробные настройки",
        "Language, mine geometry and timing, target priorities and indicators.","Язык, геометрия и тайминги мин, приоритеты целей и индикаторы.")
    ui.advanced:Icon(utf8.char(0xf1de))
    ui.language=localize_widget(g:Combo("Language / Язык",{"Русский","English"},0),"Language","Язык")
    ui.lock=localize_widget(g:Switch("Lock point on press",false),"Lock cast position","Зафиксировать точку")
    ui.lock:Visible(false)
    ui.target_lock=localize_widget(g:Switch("Fix target",false),"Fix target","Фиксация цели")
    ui.target_lock:Visible(false)
    ui.lock_mode=nil
    local a=localize_widget(tab:Create("Abilities",Enum.GroupSide.Left),"Abilities","Способности")
    ui.abilities=localize_widget(a:MultiSelect("Abilities",icon_items(MAIN_SPELLS),true),"Order","Порядок")
    sequence_text.Wrap(ui.abilities,true):ToolTip("main_tip")

    ui.post=sequence_text.Wrap(a,true):MultiSelect("post",icon_items(SPELLS),true)
    ui.post:ToolTip("post_tip")
    ui.post:DragAllowed(true)
    ui.post:Icon("")
    ui.abilities:DragAllowed(true)
    ui.abilities:Icon("")
    local m=localize_widget(tab:Create("Mine formation",Enum.GroupSide.Left),"Mine formation","Расстановка мин")
    ui.mines=localize_widget(m:Slider("Proximity Mines per press",0,3,3),"Mines per wave","Мин за волну")
    ui.mines:Image("panorama/images/spellicons/techies_land_mines_png.vtex_c")
    ui.inflight=localize_widget(m:Switch("Mines in flight",true),"Mines in flight","Мины в полёте",
        "Place all mines at the landing point while airborne after Blast Off. Never at the jump start.","Ставит все мины в точку приземления пока летишь после Blast Off. Никогда в точку старта.")
    ui.inflight:Image("panorama/images/spellicons/techies_suicide_png.vtex_c")
    ui.spells_in_flight=localize_widget(m:Switch("Tazer + Sticky in flight",true),"Tazer + Sticky in flight","Тазер + Липкая в полёте",
        "Cast Reactive Tazer and Sticky Bomb while airborne after Blast Off.","Кастует Reactive Tazer и Sticky Bomb пока летишь после Blast Off.")
    ui.mine_delay=localize_widget(m:Slider("Delay between mines",10,300,50),"Delay between mines","Задержка между минами",
        "Delay between individual mine placements, in milliseconds. Lower = faster.","Задержка между отдельными постановками мин, в миллисекундах. Меньше = быстрее.")
    ui.ring=localize_widget(m:Slider("Ring radius",210,320,230),"Formation radius","Радиус схемы")
    ui.near=localize_widget(m:Slider("Start near landing",240,500,290),"Placement distance","Начало установки",
        "First mine below Techies near the landing point; next two ahead left/right.","Первая мина под Techies ближе к концу прыжка; две следующие впереди слева и справа.")
    ui.interval=localize_widget(m:Slider("Order interval ms",30,200,60),"Interval, ms","Интервал, мс")
    local legit_tab=localize_widget(tab:Create("Легит мины",Enum.GroupSide.Right),"Legit mines","Легит мины")
    ui.legit=localize_widget(legit_tab:Switch("Enable legit",false),"Legit mines","Легит мины",
        "Adds random jitter to mine positions and random pauses between casts.","Добавляет случайный разброс позициям мин и случайные паузы между кастами.")
    ui.legit:Icon(utf8.char(0xf06e))
    ui.legit_jitter=localize_widget(legit_tab:Slider("Position jitter",0,200,60),"Position jitter","Разброс позиций",
        "Max offset of each mine from the perfect point, in units. 0 = perfect.","Максимальное смещение каждой мины от идеальной точки, в юнитах. 0 = идеально.")
    ui.legit_pause=localize_widget(legit_tab:Slider("Random pause",0,3000,800),"Random pause","Случайная пауза",
        "Random pause before each mine placement, in milliseconds. 0 = instant.","Случайная пауза перед установкой каждой мины, в миллисекундах. 0 = мгновенно.")
    local it=localize_widget(tab:Create("Items",Enum.GroupSide.Right),"Items","Предметы")
    ui.items=localize_widget(it:MultiSelect("Items",icon_items(ITEMS),true),"Order","Порядок")
    sequence_text.Wrap(ui.items,true):ToolTip("item_tip")
    local migrated=g:Switch("Refresher sequence migration v1",false); migrated:Visible(false)
    if not migrated:Get() then
        ui.abilities:Set("item_refresher",ui.items:Get("item_refresher"))
        ui.post:Set({"techies_land_mines"})
        migrated:Set(true)
    end

    local item_rows={}
    for _,name in ipairs(ui.items:List()) do
        if name~="item_refresher" then
            local row=icon_items({name})[1]; row[3]=ui.items:Get(name); item_rows[#item_rows+1]=row
        end
    end
    ui.items:Update(item_rows,true,true)
    ui.items:DragAllowed(true)
    ui.items:Icon("")
    ui.radius=localize_widget(it:Slider("Enemy radius near cursor",100,1200,600),"Target radius","Радиус цели")
    local rules=localize_widget(tab:Create("Item rules",Enum.GroupSide.Right),"Item settings","Настройки предметов")
    ui.smart_hex=localize_widget(rules:Switch("Smart Hex priority",true),"Smart Hex","Умный хекс",
        "Plan the target before jumping: dangerous heroes in icon order, then BKB carriers, then nearest. Hex keeps its place in item order and waits for cast range. Unseen enemies cannot be hexed. Active immunity and reflection are excluded.",
        "Цель выбирается до прыжка: опасные герои по порядку иконок, затем владельцы БКБ, затем ближайший. Хекс сохраняет своё место в порядке предметов и ждёт дальности. Невидимые цели, активный иммунитет и отражение исключаются.")
    ui.dangerous=localize_widget(rules:MultiSelect("Dangerous abilities",icon_items(DANGEROUS),true),"Target priority","Приоритет целей",
        "First enabled icon has highest target priority. Drag left to right, row by row. Disabled icons do not affect target selection.",
        "Первая включённая иконка — самый высокий приоритет цели. Порядок слева направо, по строкам. Выключенные иконки не учитываются.")
    ui.dangerous:DragAllowed(true)
    ui.ethereal_self=localize_widget(rules:Switch("Ethereal on self",false),"Ethereal on self","Этериал на себя",
        "On: cast Ethereal Blade on yourself. Off: use the enemy item target. Ghost Scepter always activates on yourself.",
        "Включено: Этериал применяется на себя. Выключено: на вражескую цель предметов. Гост всегда активируется на себя.")
    ui.ethereal_self:Image("panorama/images/items/ethereal_blade_png.vtex_c")
    ui.smart_hex:Image("panorama/images/items/sheepstick_png.vtex_c")
    ui.exit_blink=localize_widget(rules:Switch("Blink after combo",true),"Save Blink for combo end","Блинк в конце комбо",
        "Reserve Blink for the selected retreat direction at maximum range after all casts, including Refresher. Unavailable Blink is skipped. Disable to use Blink at the beginning.",
        "Сохранить Блинк для отхода в выбранном направлении на предельной дальности после всего прокаста, включая Рефрешер. Недоступный Блинк пропускается. Выключи для Блинка в начале.")
    ui.exit_blink:Image("panorama/images/items/blink_png.vtex_c")
    ui.blink_direction=localize_widget(rules:Combo("Blink direction",{"Случайно","К фонтану","Назад"},0),"Retreat","Отход",
        "Maximum range toward your fountain or the combo starting position. Nearby blocked points are checked only in that direction.",
        "На предельную дальность в сторону своего фонтана или начала комбо. При препятствии проверяются соседние точки в том же направлении.")
    local v=localize_widget(tab:Create("Visuals",Enum.GroupSide.Right),"Indicators","Индикаторы")
    ui.visual=localize_widget(v:Switch("Show cursor and item target",true),"Show indicators","Показывать индикаторы")
    ui.visual:Icon(utf8.char(0xf06e))
    ui.target_mark=localize_widget(v:Switch("Target marker",true),"Target marker","Метка цели")
    ui.cursor_mark=localize_widget(v:Switch("Cursor marker",true),"Cast position","Точка применения")
    ui.mine_mark=localize_widget(v:Switch("Mine placement markers",false),"Mine placement markers","Места установки мин")
    local update_visibility=build_menu_panel(tab,{g,a,m,it,rules,v})
    ui.blink=enabled_proxy(ui.items,"item_blink"); ui.bkb=enabled_proxy(ui.items,"item_black_king_bar")
    ui.refresher=enabled_proxy(ui.abilities,"item_refresher"); ui.jump=enabled_proxy(ui.abilities,"techies_suicide")

    ui.restore=g:Switch("Restore indicators pending",false); ui.restore:Visible(false)
    ui.saved,ui.saved_exists={},{}
    for i=1,#indicator_paths do
        ui.saved[i]=g:Switch("Saved indicator "..i,true); ui.saved[i]:Visible(false)
        ui.saved_exists[i]=g:Switch("Saved indicator exists "..i,false); ui.saved_exists[i]:Visible(false)
    end
    native_bind=find({"Heroes","Hero List","Techies","Main Settings","Hero Settings","Combo Key"})
    restore_indicators()
    ui.enabled:SetCallback(function()
        update_visibility()
        if not ui.enabled:Get() then stop("stopped") end
    end)
    ui.language:SetCallback(function() apply_language(); update_visibility() end)
    do
        local legacy_migrated=g:Switch("Lock mode migration v2",false); legacy_migrated:Visible(false)
        if not legacy_migrated:Get() then
            local initial=0
            if ui.target_lock:Get() then initial=2
            elseif ui.lock:Get() then initial=1 end
            if ui.lock_mode then ui.lock_mode:Set(initial) end
            ui.lock:Set(false)
            ui.target_lock:Set(false)
            legacy_migrated:Set(true)
        end
    end
    apply_language()
    update_visibility()
    last_status="ready"
    return true
end

local function hero_valid(hero)
    return hero and Entity.IsEntity(hero) and Entity.IsAlive(hero)
        and Entity.GetUnitName(hero)=="npc_dota_hero_techies"
end
local function target_valid(hero,target)
    return target and Entity.IsEntity(target) and Entity.IsAlive(target)
        and not Entity.IsSameTeam(hero,target) and not Entity.IsDormant(target)
        and NPC.IsVisible(target) and not NPC.IsIllusion(target)
        and not state(target,"MODIFIER_STATE_INVULNERABLE")
        and not state(target,"MODIFIER_STATE_OUT_OF_GAME")
end
local function nearest(hero,point)
    local best,best_distance=nil,ui.radius:Get()+0.01
    for _,target in pairs(Heroes.GetAll()) do
        if target_valid(hero,target) then
            local d=dist(Entity.GetAbsOrigin(target),point)
            if d<best_distance then best,best_distance=target,d end
        end
    end
    return best
end
-- Locked hero (for lock_target mode). Falls back to cursor if none.
local function locked_hero(hero)
    if not lock_target() then return nil end
    local t = run and run.lock_hero
    if t and target_valid(hero,t) then return t end
    return nil
end
local function aim()
    if not run then return Input.GetWorldCursorPos() end
    -- lock target: aim at the hero
    if lock_target() and run.lock_hero and target_valid(run.hero,run.lock_hero) then
        return Entity.GetAbsOrigin(run.lock_hero)
    end
    if run.manual_point then return run.manual_point end
    if lock_point() then return run.anchor end
    return Input.GetWorldCursorPos()
end
local function ability(hero,name,is_item)
    return is_item and NPC.GetItem(hero,name,true) or (not is_item and NPC.GetAbility(hero,name))
end
local function choose_item(hero,names)
    for _,name in ipairs(names) do if NPC.GetItem(hero,name,true) then return name end end
end
local function cast_range(hero,ab)

    return math.max(0,Ability.GetCastRange(ab))
end
local function refresh_threat_roster(hero,force)
    if not force and now()-roster_updated<0.2 then return end
    roster_updated=now()
    local present={}
    for _,enemy in pairs(Heroes.GetAll()) do
        if Entity.IsEntity(enemy) and not Entity.IsSameTeam(hero,enemy) and not NPC.IsIllusion(enemy) then
            local index=Entity.GetIndex(enemy)
            local profile=threat_roster[index]
            if not profile or profile.entity~=enemy then profile={entity=enemy}; threat_roster[index]=profile end
            present[index]=true
            profile.name=Entity.GetUnitName(enemy)
            profile.visible=not Entity.IsDormant(enemy) and NPC.IsVisible(enemy)
            profile.dangerous=false; profile.channel=false; profile.rank=nil
            if profile.visible then
                profile.has_bkb=NPC.GetItem(enemy,"item_black_king_bar",true)~=nil
                profile.last_seen=now(); profile.position=copy(Entity.GetAbsOrigin(enemy))
            end
            for rank,name in ipairs(ui.dangerous:ListEnabled()) do
                local matches=false

                if THREAT_HEROES[name]==profile.name then matches=true end
                if profile.visible then
                    local ab=NPC.GetAbility(enemy,name)
                    if ab and Ability.GetLevel(ab)>0 and not Ability.IsHidden(ab) then
                        matches=true
                        if Ability.IsChannelling(ab) then profile.channel=true end
                    end
                end
                if matches then profile.dangerous=true; profile.rank=profile.rank or rank end
            end
            profile.score=profile.dangerous and (300+(#DANGEROUS-profile.rank+1)*10)
                or profile.has_bkb and 200 or 0
            profile.reason=profile.channel and "dangerous channel" or profile.dangerous and "dangerous hero"
                or profile.has_bkb and "BKB carrier" or "nearest"
            if profile.dangerous and profile.has_bkb then profile.score=profile.score+2 end
            if profile.channel then profile.score=profile.score+1 end
        end
    end
    for index in pairs(threat_roster) do if not present[index] then threat_roster[index]=nil end end
end
local function hex_valid(hero,target,point)
    return target_valid(hero,target) and dist(Entity.GetAbsOrigin(target),point)<=ui.radius:Get()
        and not state(target,"MODIFIER_STATE_MAGIC_IMMUNE")
        and not NPC.HasModifier(target,"modifier_black_king_bar_immune")
        and not NPC.HasModifier(target,"modifier_item_lotus_orb_active")
        and not NPC.HasModifier(target,"modifier_antimage_counterspell")
end
local function best_hex_target(hero,point,max_range)
    local best,best_score,best_distance=nil,-1,math.huge
    for _,profile in pairs(threat_roster) do
        local target=profile.entity
        if hex_valid(hero,target,point) and (not max_range or dist(Entity.GetAbsOrigin(hero),Entity.GetAbsOrigin(target))<=max_range) then
            local distance=dist(Entity.GetAbsOrigin(target),point)
            if profile.score>best_score or (profile.score==best_score and distance<best_distance) then
                best,best_score,best_distance=target,profile.score,distance
            end
        end
    end
    return best
end
local function set_hex_plan(target)
    if run.hex_target==target then return end
    run.hex_target=target
    local profile=target and threat_roster[Entity.GetIndex(target)]
    run.hex_reason=profile and profile.reason or nil

end
local function prepare_hex_plan(hero,point)
    -- Lock target: force pick the locked hero
    if lock_target() and run.lock_hero and target_valid(hero,run.lock_hero) then
        set_hex_plan(run.lock_hero)
        run.hex_point = Entity.GetAbsOrigin(run.lock_hero)
        return
    end
    if not ui.smart_hex:Get() or not ui.items:Get("item_sheepstick") then return end
    refresh_threat_roster(hero,true)
    run.hex_point=copy(point)
    set_hex_plan(best_hex_target(hero,point))
end
local function hex_target(hero,point,hex)
    -- Lock target: return locked hero if valid, regardless of hex conditions
    if lock_target() then
        local t = locked_hero(hero)
        if t then return t end
        return nil,"lock target lost"
    end
    point=run and (run.hex_point or point) or point
    local planned=run and run.hex_target
    local flight=run and run.flight
    local waiting=flight and now()<=(flight.landed_at and flight.landed_at+0.1 or flight.expires+0.25)
    local candidate=best_hex_target(hero,point)
    if not hex_valid(hero,planned,point) then
        if not planned or not waiting then set_hex_plan(candidate); planned=candidate
        else return nil,"hex wait visibility" end
    end

    if waiting and candidate then
        local selected=planned and threat_roster[Entity.GetIndex(planned)]
        local revealed=threat_roster[Entity.GetIndex(candidate)]
        if not selected or revealed.score>selected.score then
            set_hex_plan(candidate); planned=candidate
        end
    end
    if not planned then return nil,waiting and "hex wait visibility" or "no enemy near cursor" end
    if dist(Entity.GetAbsOrigin(hero),Entity.GetAbsOrigin(planned))>cast_range(hero,hex) then
        if waiting then return nil,"hex wait range" end
        planned=best_hex_target(hero,point,cast_range(hero,hex)); set_hex_plan(planned)
        if not planned then return nil,"enemy out of range" end
    end
    return planned
end
local function add_spell(list,name,wave,hero)
    local function add(id,mode,item)
        list[#list+1]={name=id,mode=mode,item=item,wave=wave}
    end
    if name=="techies_land_mines" then
        local count=run and run.mine_settings and run.mine_settings.count or ui.mines:Get()
        for slot=1,count do add(name,"mine",false); list[#list].mine_slot=slot end
    elseif name==MAD then
        add(name,"mad",false)

        add(DETONATE,"detonate",false)
    elseif name=="item_refresher" then
        add(name,"refresh",true)
    else
        add(name,(name=="techies_suicide" or name=="techies_sticky_bomb") and "point" or "self",false)
    end
end
local function queues(hero)
    local pre,combat,items,tail={},{},{},{}
    local function add(list,name,item,mode)
        if name then list[#list+1]={name=name,item=item,mode=mode,wave=1} end
    end
    if ui.blink:Get() and not ui.exit_blink:Get() then add(pre,choose_item(hero,BLINKS),true,"blink") end
    if ui.bkb:Get() then add(pre,"item_black_king_bar",true,"self") end
    local opening=true
    for _,name in ipairs(ui.abilities:ListEnabled()) do

        if name~="techies_reactive_tazer" and name~="techies_suicide" then opening=false end
        add_spell(opening and pre or combat,name,1,hero)
    end
    for _,id in ipairs(ui.items:ListEnabled()) do
        if id~="item_blink" and id~="item_black_king_bar" and id~="item_refresher" then
            local name=id=="item_dagon_5" and choose_item(hero,{"item_dagon_5","item_dagon_4","item_dagon_3","item_dagon_2","item_dagon"}) or id
            if name and NPC.GetItem(hero,name,true) then add(items,name,true,(name=="item_glimmer_cape" or name=="item_ghost" or (name=="item_ethereal_blade" and ui.ethereal_self:Get())) and "self" or "auto") end
        end
    end
    if ui.blink:Get() and ui.exit_blink:Get() then add(tail,choose_item(hero,BLINKS) or "item_blink",true,"escape") end
    return pre,combat,items,tail
end
local function plan(hero)
    local a,b,c,d=queues(hero)
    local result={}
    for _,list in ipairs({a,c,b,d}) do for _,step in ipairs(list) do result[#result+1]=step end end
    return result
end
local function setup_pass(hero,point)
    run.mine_settings={count=ui.mines:Get(),radius=ui.ring:Get(),near=ui.near:Get(),interval=ui.interval:Get(),
        inflight=ui.inflight:Get(),spells_inflight=ui.spells_in_flight:Get(),delay=(ui.mine_delay:Get() or 50)/1000}

    run.mine_receipts={}; run.mine_observed={}; run.mine_deadlines={}; run.mine_skip={}
    run.pre,run.combat,run.items,run.tail=queues(hero)
    run.hex_target=nil; run.hex_point=nil; run.hex_sent=false
    run.index=1; run.formation=nil; run.mine_index=1; run.mine_wave=1; run.flight=nil; run.mad_armed=false
    run.tazer_pops=0; run.mine_latency=0.15; run.waves={}; run.post_order=ui.post:ListEnabled()
    run.legit_next=0; run.mine_next_cast=0
    -- lock target: pick hero at press
    run.lock_hero = nil
    if lock_target() and point then
        run.lock_hero = nearest(hero, point)
    end
end
local function observe_manual_jump(hero)
    local m=manual_jump
    if not m then return end
    if m.hero~=hero or not hero_valid(hero) or now()>m.expires then manual_jump=nil; return end
    local phase=Ability.IsInAbilityPhase(m.ab)
    if phase then
        if not m.phase_seen then
            m.origin=copy(Entity.GetAbsOrigin(hero)); m.phase_seen=true
            m.direction={x=m.destination.x-m.origin.x,y=m.destination.y-m.origin.y}
        end
        m.expires=now()+2
    elseif not m.departed and (Ability.GetCooldown(m.ab)>m.cooldown+0.01
        or (m.phase_seen and Entity.GetAbsOrigin(hero).z-World.GetGroundZ(Entity.GetAbsOrigin(hero).x,Entity.GetAbsOrigin(hero).y)>12)) then
        m.departed=true; m.expires=now()+1.4
    elseif m.phase_seen and not m.departed then manual_jump=nil end
end
local function adopt_manual_jump(hero)
    local m=manual_jump
    if not m or m.hero~=hero or m.consumed or not (m.phase_seen or m.departed) then return end
    if run.flight and not run.flight.manual and m.sent<run.started then return end
    m.consumed=true
    run.flight=m; m.manual=true
    run.manual_point=copy(m.destination); run.anchor=copy(m.destination)
    run.start_origin=copy(m.origin); run.formation=nil; run.walking=false
    for i=#run.pre,1,-1 do
        local step=run.pre[i]
        if step.name=="techies_suicide" or step.mode=="blink" then table.remove(run.pre,i) end
    end
    if run.pending and run.pending.name=="techies_suicide" then run.pending=nil end
    prepare_hex_plan(hero,m.destination)

end
local function cast_available(hero,ab,item)
    return ab and Entity.IsAbility(ab) and Ability.GetLevel(ab)>0 and not Ability.IsHidden(ab)
        and Ability.IsCastable(ab,NPC.GetMana(hero))
        and (item and not state(hero,"MODIFIER_STATE_MUTED") or not item and not NPC.IsSilenced(hero))
end
local function move_into_range(hero,point,range)
    if dist(Entity.GetAbsOrigin(hero),point)>range then
        if state(hero,"MODIFIER_STATE_ROOTED") then stop_walk();last_status="approach";return false end
        if not run.last_move or now()-run.last_move>=0.25 then
            NPC.MoveTo(hero,point,false,false,false,true,ID,false)
            run.walking=true; run.last_move=now()

        end
        last_status="approach";return false
    end
    if run.walking then stop_walk();run.approach_ready=now()+0.1;return false end
    return not run.approach_ready or now()>=run.approach_ready
end
local function prepare_entry(hero)
    if run.flight then
        if run.flight.manual and not run.flight.departed then
            if manual_jump~=run.flight then stop("jumpwait") end
            return false
        end
        return true
    end
    if run.entry_ready then return true end
    local point=aim(); if not point then return false end
    local jump=NPC.GetAbility(hero,"techies_suicide")
    local opening_jump=false
    for _,step in ipairs(run.pre) do if step.name=="techies_suicide" then opening_jump=true end end
    local jump_ready=opening_jump and cast_available(hero,jump,false) and not state(hero,"MODIFIER_STATE_ROOTED")
    if not run.entry and jump_ready then return move_into_range(hero,point,cast_range(hero,jump)) end
    if not run.entry then
        run.entry="walk"
        for i=#run.pre,1,-1 do
            if run.pre[i].name=="techies_suicide" or run.pre[i].mode=="blink" then table.remove(run.pre,i) end
        end
        local blink_name=ui.blink:Get() and choose_item(hero,BLINKS)
        local blink=blink_name and NPC.GetItem(hero,blink_name,true)
        if cast_available(hero,blink,true) and not state(hero,"MODIFIER_STATE_ROOTED")
            and dist(Entity.GetAbsOrigin(hero),point)>250 then
            run.entry="blink"
            run.pre[#run.pre+1]={name=blink_name,item=true,mode="entry_blink"}
        end

    end
    for _,step in ipairs(run.pre) do if step.mode=="entry_blink" then return true end end
    if not move_into_range(hero,point,75) then return false end
    run.entry_ready=true
    prepare_hex_plan(hero,point)
    return true
end
local function is_airborne()
    local f=run and run.flight
    return f and f.departed and now()<f.expires
end
local function mine_ready(hero)
    local f=run.flight
    if not f or not f.departed or now()>f.expires then return true end
    if run.mine_settings.inflight then return true end
    return dist(Entity.GetAbsOrigin(hero),f.destination)<=ui.near:Get()
end
local function reserve_mine_window(hero)
    local f=run.flight
    if not f or not f.departed or now()>f.expires or not run.combat[1] or run.combat[1].mode~="mine" then return false end
    local margin=math.min(220,math.max(100,dist(f.origin,f.destination)*0.2))
    return dist(Entity.GetAbsOrigin(hero),f.destination)<=ui.near:Get()+margin
end
local function other_bomb(npc)

    for _,modifier in ipairs(NPC.GetModifiers(npc)) do
        local ab=Modifier.GetAbility(modifier)
        if ab and Entity.IsAbility(ab) then
            local name=Ability.GetName(ab)
            if name==MAD or name==DETONATE then return "mad" end
            if name=="techies_sticky_bomb" then return "sticky" end
        end
    end
    return nil
end
local function observe_mine(npc,source)
    if not run or not run.mine_receipts then return end
    if other_bomb(npc) then return end

    local position=Entity.GetAbsOrigin(npc)
    local index=Entity.GetIndex(npc)
    if run.mine_observed[index] then return end
    for _,p in ipairs(run.mine_receipts) do
        if not p.spawned and now()-p.sent<1.5 and not p.existing_mines[index] and dist(position,p.position)<12 then
            p.spawned=true; p.mine_entity=npc
            run.mine_observed[index]=true

            return
        end
    end
end
local function live_mines(hero)
    local list,mad,sticky={},{},{}

    for _,npc in pairs(NPCs.GetAll()) do
        if Entity.IsEntity(npc) and Entity.IsAlive(npc) and Entity.IsSameTeam(hero,npc)
            and Entity.GetUnitName(npc)=="npc_dota_techies_mines" then
            local kind=other_bomb(npc)
            if kind=="mad" then mad[#mad+1]=npc
            elseif kind=="sticky" then sticky[#sticky+1]=npc
            else list[#list+1]=npc end
        end
    end
    return list,mad,sticky
end
local function update_mine_evidence(hero)
    if not run or not run.mine_receipts or #run.mine_receipts==0 then return end
    if run.mine_scan_at and now()<run.mine_scan_at then return end
    run.mine_scan_at=now()+0.1
    for _,npc in ipairs(live_mines(hero)) do observe_mine(npc,"entity scan") end
end
local function mine_point(hero,unused,ab)
    local occupied={}
    local existing={}
    local mines=live_mines(hero)
    for _,npc in ipairs(mines) do
        observe_mine(npc,"placement scan")
        occupied[#occupied+1]=Entity.GetAbsOrigin(npc)
        existing[Entity.GetIndex(npc)]=true
    end

    for _,p in ipairs(run.mine_receipts) do
        if p.logged and not p.spawned and now()-p.sent<0.75 then
            occupied[#occupied+1]=p.position
        end
    end
    run.current_mine_entities=existing

    local spacing=360
    local origin=Entity.GetAbsOrigin(hero)
    local range=cast_range(hero,ab)
    local function ground(x,y) return Vector(x,y,World.GetGroundZ(x,y)) end
    local function clear(p,list)
        for _,old in ipairs(list) do if dist(old,p)<spacing then return false end end
        return true
    end
    -- center: destination (Blast Off landing) if flying, otherwise lock_hero position, otherwise origin
    local f=run.flight
    local center
    if f and f.departed then
        center=ground(f.destination.x,f.destination.y)
    elseif lock_target() and run.lock_hero and target_valid(hero,run.lock_hero) then
        local hpos = Entity.GetAbsOrigin(run.lock_hero)
        center=ground(hpos.x,hpos.y)
    else
        center=ground(origin.x,origin.y)
    end
    local radius=run.mine_settings.radius
    local jitter = (ui.legit and ui.legit:Get() and ui.legit_jitter:Get()) or 0
    local function apply_jitter(p)
        if jitter <= 0 then return p end
        local ang = math.random() * math.pi * 2
        local rad = math.random() * jitter
        return ground(p.x + math.cos(ang) * rad, p.y + math.sin(ang) * rad)
    end
    if not run.formation then
        local direction=f and f.direction or {x=aim().x-origin.x,y=aim().y-origin.y}
        local forward=math.atan(direction.y,direction.x)
        local needed=math.max(1,run.mine_settings.count-run.mine_index+1)
        local free_but_out_of_range=false
          for attempt=0,12 do
            local angle=forward+(attempt==0 and 0 or (attempt%2==0 and -1 or 1)*math.ceil(attempt/2)*math.pi/12)
            local dx,dy=math.cos(angle),math.sin(angle)
            local first=ground(center.x-dx*radius,center.y-dy*radius)
            local side=radius*math.sqrt(3)/2
            local points={first,
                ground(center.x+dx*radius/2-dy*side,center.y+dy*radius/2+dx*side),
                ground(center.x+dx*radius/2+dy*side,center.y+dy*radius/2-dx*side)}
            local checked={}; local free=true
            for i=1,needed do
                local p=apply_jitter(points[i])
                points[i]=p
                if not clear(p,occupied) or not clear(p,checked) then free=false; break end
                checked[#checked+1]=p
            end
            if free and run.mine_wave==2 and not run.mine_settings.inflight then
                for _,p in ipairs(checked) do
                    if dist(origin,p)>range then free=false; free_but_out_of_range=true; break end
                end
            end
            if free then
                run.formation=points; run.formation_start=run.mine_index

                break
            end
          end
        if not run.formation and free_but_out_of_range then return nil,"mine position out of range" end
    end
    if not run.formation then return nil,"no free mine triangle" end
    local p=run.formation[run.mine_index-(run.formation_start or 1)+1]
    if not p then return nil,"mine triangle complete" end
    if not clear(p,occupied) then return nil,"mine position occupied" end
    if not run.mine_settings.inflight and not is_airborne() and dist(origin,p)>range then return nil,"mine position out of range" end
    return p
end
local function has_flag(flags,flag) return flag and (flags & flag)~=0 end
local function cast_mode(ab,preferred)
    local behavior=Ability.GetBehavior(ab)
    local flags=Enum.AbilityBehavior
    if preferred=="point" or preferred=="blink" or preferred=="entry_blink" or preferred=="mine" or preferred=="escape" or preferred=="mad" then return "point" end
    if preferred=="self" then
        if has_flag(behavior,flags.DOTA_ABILITY_BEHAVIOR_NO_TARGET) then return "none" end
        if has_flag(behavior,flags.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then return "self" end
        return nil
    end
    if has_flag(behavior,flags.DOTA_ABILITY_BEHAVIOR_POINT) then return "point" end
    if has_flag(behavior,flags.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then return "target" end
    if has_flag(behavior,flags.DOTA_ABILITY_BEHAVIOR_NO_TARGET) then return "none" end
end
local function pending_done(hero,t)
    local p=run.pending
    if not p then return true end
    local valid=Entity.IsAbility(p.ab)
    local consumed=p.mode=="refresh" and p.name=="item_refresher_shard" and not valid
    if not valid and not consumed then run.pending=nil; return true
    end
    local cooldown=valid and Ability.GetCooldown(p.ab) or 0
    local charges=valid and Ability.GetCurrentCharges(p.ab) or 0
    local confirmed=p.confirmed or cooldown>p.cooldown+0.01 or charges<p.charges
        or ((p.mode=="blink" or p.mode=="entry_blink" or p.mode=="escape") and dist(Entity.GetAbsOrigin(hero),p.origin)>100)

    if p.mode=="mine" then
        if not p.logged and not p.spawned and charges<p.charges then

            for _,npc in ipairs(live_mines(hero)) do observe_mine(npc,"charge confirmation scan") end
        end
        confirmed=p.spawned or charges<p.charges
    end
    if p.mode=="refresh" then
        confirmed=cooldown>p.cooldown+0.01 or charges<p.charges or consumed
    end
    if p.mode=="mad" then
        local det=NPC.GetAbility(hero,DETONATE)
        confirmed=cooldown>p.cooldown+0.01 and Ability.IsHidden(p.ab) and det and not Ability.IsHidden(det)
        if confirmed then run.mad_armed=true end
    end
    if confirmed and not p.logged then
        if p.mode=="mine" then

            run.mine_latency=math.max(run.mine_latency,t-p.sent)
            run.reserved[#run.reserved+1]=copy(p.position)
            run.mine_index=run.mine_index+1
        end
        if p.mode=="escape" then run.escape_used=true end
        if p.mode=="detonate" then run.mad_armed=false end

        p.logged=true; p.confirmed_at=t
    end
    if valid and (Ability.IsInAbilityPhase(p.ab) or Ability.IsChannelling(p.ab)) then
        p.phase_seen=true
        if t-p.sent>6 then stop("castwait") end
        return false
    end
    if p.name=="techies_suicide" then

        local pos=Entity.GetAbsOrigin(hero)
        local departed=cooldown>p.cooldown+0.01
            or (p.phase_seen and pos.z-World.GetGroundZ(pos.x,pos.y)>12)
        if not departed and t<p.sent+p.cast_point+0.8 then return false end
        if not departed then
            if p.step.wave==2 then run.pending=nil; run.flight=nil; return true
            end
            stop("jumpwait"); return false
        end
        if departed and run.flight and not run.flight.departed then
            run.flight.departed=true; run.flight.expires=t+1.4
            run.flight.airborne_seen=pos.z-World.GetGroundZ(pos.x,pos.y)>12

        end
    end
    if t<p.ready_at then return false end
    if p.mode=="mad" and not confirmed and t<p.sent+p.cast_point+1.5 then return false end
    if p.mode=="refresh" and confirmed then
        if t<(p.confirmed_at or t)+0.1 then return false end
        local mines=NPC.GetAbility(hero,"techies_land_mines")
        if mines and Ability.GetCurrentCharges(mines)<run.mine_settings.count and t<p.sent+0.3 then return false end
    end
    if p.mode=="mine" and not confirmed then
        if t<p.sent+1.5 then return false end

        if (p.step.attempts or 0)<3 then
            p.step.retry_at=t+0.1
            table.insert(run.combat,1,p.step)
            run.formation=nil
        end
        run.pending=nil
        return true
    end
    local urgent_mine=p.cast_point==0 and p.mode=="auto" and reserve_mine_window(hero)
    if not confirmed and urgent_mine then

        observers[#observers+1]=p
        run.pending=nil
        return true
    end
    if not confirmed and not urgent_mine and t<p.sent+math.max(p.cast_point+0.25,0.3) then return false end

    if p.mode=="refresh" and confirmed then
        local next_wave={}
        for _,name in ipairs(run.post_order) do add_spell(next_wave,name,2,hero) end

        for i=#next_wave,1,-1 do table.insert(run.combat,1,next_wave[i]) end

    end

    run.pending=nil
    return true
end
local function step_enabled(step)
    if step.mode=="refresh" then return ui.refresher:Get() end
    if step.mode=="escape" and run and run.escape_used then return false end
    if not step.item then return (step.wave==2 and ui.post or ui.abilities):Get(step.name==DETONATE and MAD or step.name) end
    local id=step.name
    if id:match("^item_dagon") then id="item_dagon_5"
    elseif id:match("^item_.*blink$") then id="item_blink"
    elseif id=="item_refresher_shard" then id="item_refresher" end
    return ui.items:Get(id)
end
local function dispatch(hero,step,point)
    if not step_enabled(step) then return "disabled in selector" end
    if step.mode=="refresh" then
        if #run.post_order==0 then return "empty post-Refresher sequence" end

        local selected
        for _,name in ipairs({"item_refresher","item_refresher_shard"}) do
            if cast_available(hero,NPC.GetItem(hero,name,true),true) then selected=name; break end
        end
        if not selected then return "Refresher absent, on cooldown, muted or insufficient mana" end
        step.name=selected
    end
    if step.mode=="mad" and not safe(NPC.HasShard,hero) then return "no Aghanim shard" end
    if step.mode=="detonate" and not run.mad_armed then return "no confirmed M.A.D. from this combo" end
    if step.mode=="escape" and (#run.pre>0 or #run.items>0 or #run.combat>0 or run.pending) then
        return "retreat deferred until all casts finish"
    end
    if step.mode=="mine" and run.mine_skip[step.wave] then return "mine wave placement timeout" end
    if step.mode=="mine" and run.mine_wave~=step.wave then
        run.waves[run.mine_wave]={formation=run.formation,index=run.mine_index,start=run.formation_start,center=run.mine_center}
        local saved=run.waves[step.wave] or {index=1}
        run.mine_wave=step.wave; run.formation=saved.formation; run.mine_index=saved.index; run.formation_start=saved.start; run.mine_center=saved.center
    end
    if step.mode=="mine" and ui.legit and ui.legit:Get() then
        local pause = (ui.legit_pause:Get() or 0) / 1000
        if pause > 0 then
            if not run.legit_next or now() < run.legit_next then
                if not run.legit_next or run.legit_next == 0 then
                    run.legit_next = now() + math.random() * pause
                end
                return "legit pause"
            end
            run.legit_next = now() + math.random() * pause
        end
    end
    if step.mode=="mine" then
        local d = run.mine_settings.delay or 0
        if d > 0 then
            if not run.mine_next_cast or run.mine_next_cast == 0 then
                run.mine_next_cast = now() + d
            end
            if now() < run.mine_next_cast then return "mine delay" end
            run.mine_next_cast = now() + d
        end
    end
    local ab=ability(hero,step.name,step.item)
    if not ab or not Entity.IsAbility(ab) then return "ability or item absent" end
    if Ability.GetLevel(ab)<1 or Ability.IsHidden(ab) then return "unlearned or hidden" end

    if NPC.GetMana(hero)<Ability.GetManaCost(ab) then return "insufficient mana" end
    if step.mode=="mine" and Ability.GetCurrentCharges(ab)<=0 then return "no mine charges" end
    if step.mode=="escape" and Ability.GetCooldown(ab)>0 then return "Blink on cooldown" end
    if not Ability.IsCastable(ab,NPC.GetMana(hero)) then return "cooldown or not castable" end
    if step.item and state(hero,"MODIFIER_STATE_MUTED") then return "muted" end
    if not step.item and NPC.IsSilenced(hero) then return "silenced" end
    if (step.name=="techies_suicide" or step.mode=="escape" or step.mode=="blink" or step.mode=="entry_blink")
        and state(hero,"MODIFIER_STATE_ROOTED") then return "rooted" end
    local mode=cast_mode(ab,step.mode)
    if not mode then return "unsupported behavior" end
    local target,position=nil,copy(point)
    local origin=Entity.GetAbsOrigin(hero)
    local airborne=is_airborne()
    if step.mode=="mad" then
        local center=run.flight and run.flight.destination or origin
        position=Vector(center.x,center.y,World.GetGroundZ(center.x,center.y))
    elseif step.mode=="escape" then
        local range=cast_range(hero,ab)
        if range<=1 then return "unknown blink range" end
        position=nil
        local start=math.random()*2*math.pi
        local direction=ui.blink_direction:Get()
        if direction~=0 then
            local destination=direction==2 and run.start_origin or nil
            if direction==1 then
                for _,npc in pairs(NPCs.GetAll()) do
                    if Entity.IsEntity(npc) and Entity.IsSameTeam(hero,npc) then
                        local name=Entity.GetUnitName(npc)
                        if name=="dota_fountain" or name=="npc_dota_fountain" then destination=Entity.GetAbsOrigin(npc); break end
                    end
                end
            end
            if not destination then return "blink direction unavailable" end
            if dist(origin,destination)<10 then return "already at blink destination" end
            start=math.atan(destination.y-origin.y,destination.x-origin.x)
        end
        for i=0,31 do
            if direction~=0 and i>8 then break end
            local offset=direction==0 and i*2*math.pi/32 or (i%2==0 and -1 or 1)*math.ceil(i/2)*math.pi/36
            local angle=start+offset
            local x,y=origin.x+math.cos(angle)*(range-1),origin.y+math.sin(angle)*(range-1)
            local candidate=Vector(x,y,World.GetGroundZ(x,y))
            if GridNav and safe(GridNav.IsTraversable,candidate,0x1,0x112) then position=candidate; break end
        end
        if not position then return "no traversable blink destination" end
    elseif step.mode=="blink" or step.mode=="entry_blink" then
        if dist(origin,point)<250 then return "already near cursor" end
        local jump=ui.jump:Get() and NPC.GetAbility(hero,"techies_suicide")
        if step.mode=="blink" and jump and cast_available(hero,jump,false) and dist(origin,point)<=cast_range(hero,jump) then
            return "cursor already in jump range"
        end
        local range=cast_range(hero,ab)
        local d=dist(origin,point)
        if range<=0 then return "unknown blink range" end
        if d>range-25 then
            local scale=(range-25)/d
            local x,y=origin.x+(point.x-origin.x)*scale,origin.y+(point.y-origin.y)*scale
            position=Vector(x,y,World.GetGroundZ(x,y))
        end
    elseif step.mode=="mine" then
        local reason
        position,reason=mine_point(hero,point,ab)
        if not position then return reason end
    elseif mode=="target" then
        -- Lock target: force the locked hero
        if lock_target() then
            local t = locked_hero(hero)
            if not t then return "lock target lost" end
            target = t
        elseif step.name=="item_sheepstick" and ui.smart_hex:Get() then
            local reason
            target,reason=hex_target(hero,point,ab)
            if not target then return reason end
        else
            target=nearest(hero,point)
        end
        if not target then return "no enemy near cursor" end
        if state(target,"MODIFIER_STATE_MAGIC_IMMUNE") then return "enemy debuff immune" end
        if NPC.HasModifier(target,"modifier_item_lotus_orb_active")
            or NPC.HasModifier(target,"modifier_antimage_counterspell") then return "spell reflection" end
        if not has_flag(Ability.GetTargetTeam(ab),Enum.TargetTeam.DOTA_UNIT_TARGET_TEAM_ENEMY)
            or not has_flag(Ability.GetTargetType(ab),Enum.TargetType.DOTA_UNIT_TARGET_HERO) then return "unsupported target" end
        if not airborne and dist(origin,Entity.GetAbsOrigin(target))>cast_range(hero,ab) then return "enemy out of range" end
    elseif mode=="self" then target=hero end
    if mode=="point" and not airborne and not run.mine_settings.inflight then
        if dist(origin,position)>cast_range(hero,ab) then return "point out of range" end
    end
    if mode=="none" and step.mode=="auto" and dist(origin,point)>800 then return "point too far for area item" end
    local t=now()
    local cp=math.max(0,safe(Ability.GetCastPoint,ab,true) or 0)
    local wait=cp+ui.interval:Get()/1000
    if step.mode=="mine" and run.mine_settings.inflight then wait=cp end
    if step.mode=="blink" or step.mode=="entry_blink" then wait=0.15 end
    if step.mode=="escape" then wait=cp end
    if step.mode=="mad" then wait=cp end
    run.pending={ab=ab,name=step.name,mode=step.mode,sent=t,ready_at=t+wait,
        cooldown=Ability.GetCooldown(ab),charges=Ability.GetCurrentCharges(ab),
        origin=copy(origin),position=mode=="point" and copy(position) or nil,
        target_index=target and Entity.GetIndex(target),confirmed=false,cast_point=cp,step=step}
    if step.mode=="mine" then

        run.pending.existing_mines=run.current_mine_entities or {}

        run.mine_receipts[#run.mine_receipts+1]=run.pending

    end
    step.attempts=(step.attempts or 0)+1

    if step.name=="techies_suicide" then
        prepare_hex_plan(hero,position)
        manual_jump=nil
        run.walking=false
        run.formation=nil
        run.flight={destination=copy(position),origin=copy(origin),departed=false,expires=t+cp+2,
            direction={x=position.x-origin.x,y=position.y-origin.y}}
    end

    if mode=="point" then Ability.CastPosition(ab,position,false,false,true,ID,false)
    elseif mode=="none" then Ability.CastNoTarget(ab,false,false,true,ID)
    else Ability.CastTarget(ab,target,false,false,true,ID) end
    last_status=step.name
    if step.name=="item_sheepstick" then run.hex_sent=true end
    if step.name=="techies_reactive_tazer_stop" then run.tazer_pops=run.tazer_pops+1 end

    return nil
end

local function update_observers()
    for i=#observers,1,-1 do
        local p=observers[i]
        local confirmed=p.spawned or (p.mode~="mine" and Entity.IsEntity(p.ab)
            and (Ability.GetCooldown(p.ab)>p.cooldown+0.01 or Ability.GetCurrentCharges(p.ab)<p.charges))
        if confirmed then

            table.remove(observers,i)
        elseif now()>p.sent+1.5 then

            table.remove(observers,i)
        end
    end
end

local function retry_mine(step,reason,flying)
    if step.mode~="mine" or (reason~="no free mine triangle" and reason~="mine position occupied" and reason~="mine position out of range") then return false end
    run.mine_deadlines[step.wave]=run.mine_deadlines[step.wave] or now()+2.5
    if now()>=run.mine_deadlines[step.wave] then
        run.mine_skip[step.wave]=true

        return false
    end
    step.retry_at=now()+0.1
    if not flying or reason~="mine position out of range" then run.formation=nil end
    if step.wait_reason~=reason then step.wait_reason=reason end
    return true
end

local function wait_for_retreat_landing(hero,step)
    local f=run.flight

    local pos=Entity.GetAbsOrigin(hero)
    local jumping=NPC.HasModifier(hero,"modifier_techies_suicide_leap")
        or (f and f.departed and pos.z-World.GetGroundZ(pos.x,pos.y)>12)
    if jumping then
        if not step.landing_wait then
            step.landing_wait=now();

        end
        if now()-step.landing_wait<6 then return true end

        table.remove(run.tail,1)
        return true
    end
    if step.landing_wait then

        step.landing_wait=nil
    end
    return false
end

local function update()
    if not init() then return end
    ui.refresh_visibility()
    update_observers()
    local down=ui.bind:IsDown()
    local hero=Heroes.GetLocal()
    observe_manual_jump(hero)
    if Engine.IsInGame() and hero_valid(hero) then refresh_threat_roster(hero) end
    local blocked=not ui.enabled:Get() or not Engine.IsInGame() or not hero_valid(hero)
        or GameRules.IsPaused() or Menu.Opened() or Input.IsInputCaptured() or Input.IsPopupOpen()
    if native_bind and native_bind:IsDown() then
        if down or run then stop("conflict") end
        held=down; return
    end
    if blocked then if run then stop("stopped") end; held=down; return end
    if not down then
        if held or run then stop("ready") end
        held=false; return
    end
    if not held then
        held=true
        local point=Input.GetWorldCursorPos()
        if not point then return end

        run={hero=hero,anchor=copy(point),start_origin=copy(Entity.GetAbsOrigin(hero)),reserved={},started=now()}
        setup_pass(hero,point)
        prepare_hex_plan(hero,point)
        hide_indicators();
    end
    if not run or run.finished then return end
    if run.hero~=hero then stop("changed"); return end
    if now()-run.started>60 then stop("timeout"); return end
    -- lock target: bail out if target died/disappeared (but not while flying, we need to finish mines)
    if lock_target() and run.lock_hero and not target_valid(hero,run.lock_hero) and not is_airborne() and not run.finished then
        -- keep going if we haven't started casting mines yet, just stop buying new spells at target
    end
    adopt_manual_jump(hero)
    update_mine_evidence(hero)
    if not pending_done(hero,now()) or not run then return end
    if run.flight and run.flight.departed then
        local pos=Entity.GetAbsOrigin(hero)
        if pos.z-World.GetGroundZ(pos.x,pos.y)>12 then run.flight.airborne_seen=true
        elseif run.flight.airborne_seen and not run.flight.landed_at then run.flight.landed_at=now() end
    end
    if NPC.IsStunned(hero) or NPC.IsChannellingAbility(hero) then return end

    for slot=0,40 do
        local ab
        if slot<24 then ab=NPC.GetAbilityByIndex(hero,slot) else ab=NPC.GetItemByIndex(hero,slot-24) end
        if ab and (Ability.IsInAbilityPhase(ab) or Ability.IsChannelling(ab)) then return end
    end
    local airborne=is_airborne()
    if not airborne then
        if not prepare_entry(hero) then return end
    end
    local list=run.pre
    if airborne and run.mine_settings.spells_inflight then
        local boosted=false
        if #run.pre>0 and (run.pre[1].mode=="self" or run.pre[1].mode=="point") and run.pre[1].name~="techies_suicide" then
            list=run.pre
            boosted=true
        elseif #run.combat>0 and (run.combat[1].mode=="self" or run.combat[1].mode=="point") and run.combat[1].mode~="mine" then
            list=run.combat
            boosted=true
        end
        if boosted then
        elseif #run.combat>0 and run.combat[1].mode=="mine" and mine_ready(hero) then
            list=run.combat
        end
    end
    if #list==0 then
        local combat=run.combat[1]
        local combat_ready=combat and (combat.mode~="mine" or mine_ready(hero))
        if #run.items>0 then
            list=run.items
            if list[1].retry_at and now()<list[1].retry_at then return end
        elseif combat_ready and (not combat.retry_at or now()>=combat.retry_at) then list=run.combat
        elseif #run.combat>0 then return
        else list=run.tail end
    end
    local step=list[1]
    if step and step.mode=="escape" then
        if wait_for_retreat_landing(hero,step) then return end

    end
    if step and step.mode=="detonate" and run.mad_armed then

        local det=NPC.GetAbility(hero,DETONATE)
        step.wait_started=step.wait_started or now()
        if det and Ability.GetCooldown(det)>0 and now()-step.wait_started<1.2 then return end
    end
    if step and step.name=="techies_suicide" and run.flight and run.flight.departed and now()<run.flight.expires then
        local pos=Entity.GetAbsOrigin(hero)
        if pos.z-World.GetGroundZ(pos.x,pos.y)>12 then return end
    end
    if not step or step.mode~="mine" then

        for _,pending in ipairs(observers) do if pending.mode=="mine" and not pending.spawned then return end end
    end
    if not step then run.finished=true; last_status="finished"; return end
    local point=aim(); if not point then stop("nopoint"); return end
    run.index=run.index+1
    local skipped=dispatch(hero,step,point)
    if step.name=="techies_suicide" and skipped and step.wave~=2 then table.remove(list,1); return
    end
    local flying=run.flight and run.flight.departed and now()<run.flight.expires
    if skipped=="hex wait visibility" and not run.hex_target then
        local combat=run.combat[1]
        if combat and (combat.mode~="mine" or mine_ready(hero)) and (not combat.retry_at or now()>=combat.retry_at) then
            local reason=dispatch(hero,combat,point)
            if retry_mine(combat,reason,flying) then
            else
                table.remove(run.combat,1)

            end
        end
        return
    end
    if skipped=="hex wait range" or skipped=="hex wait visibility" or flying and skipped=="enemy out of range" then
        step.retry_at=now()+0.05
        if step.wait_reason~=skipped then step.wait_reason=skipped end
        return
    end
    if retry_mine(step,skipped,flying) then return end
    if skipped=="mine delay" or skipped=="legit pause" then return end

    table.remove(list,1)

end

function script.OnUpdate()
    local ok,err=pcall(update)
    if not ok then
        safe(stop,"error")
        if ui then ui.enabled:Set(false) end
        if last_update_error~=tostring(err) then
            safe(Log.Write,"Techies Cursor OnUpdate: "..tostring(err))
        end
        last_update_error=tostring(err)

    else
        last_update_error=nil
    end
end
function script.OnPrepareUnitOrders(order)
    guarded_event("OnPrepareUnitOrders",function()
        if not order or order.identifier==ID or not Players or order.player~=Players.GetLocal() then return end
        local hero=Heroes.GetLocal()
        if not hero_valid(hero) or (order.npc and order.npc~=hero) then return end

        if run then run.walking=false end
        if native_bind and native_bind:IsDown() then return end
        if not order.ability or order.ability~=NPC.GetAbility(hero,"techies_suicide") or not order.position then return end
        local origin=copy(Entity.GetAbsOrigin(hero)); local destination=copy(order.position)
        manual_jump={hero=hero,ab=order.ability,origin=origin,destination=destination,sent=now(),
            cooldown=Ability.GetCooldown(order.ability),departed=false,expires=now()+8,
            direction={x=destination.x-origin.x,y=destination.y-origin.y}}
    end)
    return true
end
function script.OnUnitAnimation(data)
    guarded_event("OnUnitAnimation",function()
        if not run or not run.pending or data.unit~=run.hero then return end
        local ab=NPC.GetAbilityByActivity(data.unit,data.activity)
        if ab and Ability.GetName(ab)==run.pending.name and run.pending.mode~="mine" then
            run.pending.confirmed=true
        end
    end)
end
function script.OnNpcSpawned(npc)
    guarded_event("OnNpcSpawned",function()
        if Entity.GetUnitName(npc)~="npc_dota_techies_mines" then return end
        local hero=Heroes.GetLocal()
        if not hero or not Entity.IsSameTeam(hero,npc) then return end
        observe_mine(npc,"OnNpcSpawned")
    end)
end
local function ground_ring(center,radius,color,width,start,arc)
    local points={}
    start=start or 0; arc=arc or math.pi*2
    local segments=math.max(12,math.floor(64*arc/(math.pi*2)))
    for i=0,segments do
        local angle=start+arc*i/segments
        local pos=Vector(center.x+math.cos(angle)*radius,center.y+math.sin(angle)*radius,center.z+4)
        local p,visible=Render.WorldToScreen(pos)
        if visible then points[#points+1]=p
        else
            if #points>1 then Render.PolyLine(points,color,width) end
            points={}
        end
    end
    if #points>1 then Render.PolyLine(points,color,width) end
end
local function visual_target(hero,point)
    -- lock target: always the locked hero
    if lock_target() and run and run.lock_hero and target_valid(hero,run.lock_hero) then
        return run.lock_hero
    end
    if run and run.pending and run.pending.target_index and run.pending.target_index~=Entity.GetIndex(hero) then
        for _,target in pairs(Heroes.GetAll()) do
            if Entity.GetIndex(target)==run.pending.target_index and target_valid(hero,target) then return target end
        end
    end
    for _,step in ipairs(run and run.items or {}) do
        local ab=ability(hero,step.name,step.item)
        if step_enabled(step) and cast_available(hero,ab,step.item) and cast_mode(ab,step.mode)=="target" then
            if step.name=="item_sheepstick" and ui.smart_hex:Get() then
                local target=run.hex_target
                if hex_valid(hero,target,run.hex_point or point) then return target end
                return best_hex_target(hero,run.hex_point or point)
            end
            return nearest(hero,point)
        end
    end
    return nil
end
local function draw()
    if not ui or not ui.enabled:Get() or not ui.visual:Get() or not Engine.IsInGame() or Menu.Opened() then return end
    local hero=Heroes.GetLocal(); if not hero_valid(hero) then return end
    if not run or not ui.bind:IsDown() or (native_bind and native_bind:IsDown()) then return end
    local point=run.flight and run.flight.destination or aim(); if not point then return end
    if ui.cursor_mark:Get() then
        local jump=NPC.GetAbility(hero,"techies_suicide")
        local radius=jump and safe(Ability.GetAOERadius,jump) or 0
        if not radius or radius<=0 then radius=400 end
        ground_ring(point,radius,Color(164,235,245,100),1)
        ground_ring(point,30,Color(111,220,235,40),6)
        ground_ring(point,30,Color(164,235,245,210),1.5)
        local p,visible=Render.WorldToScreen(point)
        if visible then Render.Circle(p,2,Color(216,250,255,235)) end
    end
    local target=ui.target_mark:Get() and visual_target(hero,point)
    if target then
        local pos=Entity.GetAbsOrigin(target)
        local center=Vector(pos.x,pos.y,World.GetGroundZ(pos.x,pos.y))
        local red=Color(245,76,88,220)
        ground_ring(center,82,Color(245,60,75,35),7)
        ground_ring(center,82,red,1.8)
        ground_ring(center,92,Color(255,142,148,180),1.2,now()*1.5,math.pi*.65)
        local origin=Entity.GetAbsOrigin(hero)
        local a,va=Render.WorldToScreen(Vector(origin.x,origin.y,origin.z+20))
        local b,vb=Render.WorldToScreen(Vector(pos.x,pos.y,pos.z+20))
        if va and vb then
            Render.Line(a,b,Color(245,76,88,32),5)
            Render.Line(a,b,Color(245,100,110,150),1)
            for i=0,1 do
                local f=(now()*.45+i*.5)%1
                Render.Circle(Vec2(a.x+(b.x-a.x)*f,a.y+(b.y-a.y)*f),2,red)
            end
        end
    end
    if ui.mine_mark:Get() then
        for _,pos in ipairs(run.reserved) do
            ground_ring(pos,18,Color(164,235,245,140),1)
        end
    end
end
function script.OnDraw()
    local ok,err=pcall(draw)
    if not ok and last_draw_error~=tostring(err) then
        safe(Log.Write,"Techies Cursor OnDraw: "..tostring(err))

    end
    last_draw_error=not ok and tostring(err) or nil
end
function script.OnGameEnd() safe(stop,"gameend"); held=false; observers={}; manual_jump=nil; threat_roster={}; roster_updated=-math.huge end

function script.OnScriptsLoaded()
    init()

end
return script