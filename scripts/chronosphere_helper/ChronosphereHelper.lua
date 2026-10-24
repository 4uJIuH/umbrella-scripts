-- Chronosphere Helper v1.
-- Helper adjusts Chronosphere to catch enemies while keeping allies outside.
-- Combo uses Time Walk and Blink to position and cast near the cursor.
-- Fail Switch prevents empty Chronospheres when all enemy locations are known.
local Diagnostics={}
Diagnostics.sinks={
    function(text) if type(print)=="function" then print(text);return true end end,
    function(text) if type(_G.log)=="function" then _G.log(text);return true end end,
    function(text) if Log and type(Log.Write)=="function" then Log.Write(text);return true end end,
}
function Diagnostics.text(message)
    if type(message)=="function" then message=message() end
    return type(message)=="string" and message or tostring(message)
end
function Diagnostics.enabled()
    local ok,value=pcall(function() return Diagnostics.control:Get() end)
    return ok and value==true
end
local function console(message)
    local ok,text=pcall(Diagnostics.text,message)
    if not ok then return end
    for _,write in ipairs(Diagnostics.sinks) do
        local success,written=pcall(write,text)
        if success and written then return end
    end
end
console(function() return "[ChronosphereHelper v1] Initializing" end)

local function featureGroup(name,side)
    local ok,result=pcall(function()
        return Menu.Create("Scripts","General","\u{f0ad} Utility","Chronosphere"):Create(name,side)
    end)
    if ok and result then return result end
    return Menu.Create("Scripts","General","\u{f0ad} Utility","Chronosphere",name)
end
local sides=Enum.GroupSide or {Left=1,Right=2}
local group=featureGroup("Helper",sides.Left)
local comboGroup=featureGroup("Combo",sides.Right)
local master = group:Switch("Enable script", true)
master:ToolTip("Disable Helper, Combo, Fail Switch and hotkey handling.")
local syncBinding
local enabled = group:Switch("Helper", true)
enabled:ToolTip("Adjust manual Chronospheres while preserving their original enemy targets.")
local timeBudget = group:Slider("Max additional time (ms)", 0, 1500, 150, "%d ms")
timeBudget:ToolTip("Estimated extra turn + movement time compared with your manual order. Cast point is unchanged.")
local meleeAccess = group:Switch("Prefer melee access", true)
meleeAccess:ToolTip("When possible, place enemies near the dome edge facing nearby melee allies. Enemy centers stay inside.")
local edgeInset = group:Slider("Enemy edge inset", 4, 80, 12, "%d units")
edgeInset:ToolTip("Preferred distance INSIDE the dome boundary. Visual model overlap is not a hit test.")
local comboEnabled = comboGroup:Switch("Combo", false)

local okButton,comboButton=pcall(function()
    assert(type(comboEnabled.Set)=="function" and type(comboEnabled.Visible)=="function")
    local button=comboGroup:Button("Toggle Combo",function(this)
        comboEnabled:Set(not comboEnabled:Get())
        if syncBinding then syncBinding() end
        this:ForceLocalization(comboEnabled:Get() and "Combo: ON" or "Combo: OFF")
    end)
    button:ForceLocalization(comboEnabled:Get() and "Combo: ON" or "Combo: OFF")
    return button
end)
if okButton and comboButton then comboEnabled:Visible(false) end
local useBlink = comboGroup:Switch("Use Blink", true)
local useTimeWalk = comboGroup:Switch("Use Time Walk", true)
local comboSearch = comboGroup:Slider("Cursor search radius", 200, 1600, 800, "%d units")
local comboMinimum = comboGroup:Slider("Minimum enemies", 1, 5, 1, "%d")
comboMinimum:ToolTip("Minimum enemies required to start Combo. During the cast animation, Fail Switch cancels only a confirmed empty area.")
local comboSetup = comboGroup:Slider("Max combo setup (ms)", 100, 3000, 1500, "%d ms")
comboSetup:ToolTip("Maximum time for positioning before Chronosphere. Separate from the manual Helper time limit.")
local diagnostic = group:Switch("Diagnostic logs", true)
Diagnostics.control=diagnostic
diagnostic:ToolTip("Log decisions and orders. 500-line limit; toggle off/on to reset.")

local function uiControl(name,constructor,method)
    local ok,widget=pcall(function()
        local control=constructor()
        if not control or type(control[method])~="function" then error("invalid widget or missing " .. method) end
        return control
    end)
    if ok then
        pcall(function() if type(widget.Visible)=="function" then widget:Visible(true) end end)
        return widget
    end
    console(function() return "[ChronosphereHelper v1] UI " .. name .. " failed: " .. tostring(widget) end)
end
local failGroup=featureGroup("Fail Switch",sides.Right)
local failEnabled=failGroup:Switch("Fail Switch",true)
failEnabled:ToolTip("Block empty Chronospheres only with a complete, currently known enemy team. Hidden enemies, uncertain deaths or pending Aegis returns inside allow casting. Defensive effects do not matter. Also checks the cast animation; one remaining enemy keeps the cast. Independent of Helper and Combo.")
local DEFAULT_ROLES={"HC","Mid","Offlane","Support","Hard Support"}
local ROLE_FLAGS={[1]="HC",[4]="Mid",[2]="Offlane",[8]="Support",[16]="Hard Support"}
local targetPriority=uiControl("Target priority",function()
    local widget=group:Combo("Target priority",{"Enemies first","Allies first"},0)
    widget:ToolTip("Shared by Helper and Combo. Helper always preserves original enemies; Combo always respects Minimum enemies and its cursor target.")
    return widget
end,"Get")

local rolePriority
local updatingAllyWidget=false
local allyUI={order={},enabled={},edited={},customOrder=false,signature=nil,owner=nil,lastRefresh=-math.huge}
local function createAllyPriority(items)
    return uiControl("Ally role priority",function()
        local widget=group:MultiSelect("Ally role priority",items,true)
        assert(type(widget.Get)=="function" and type(widget.Update)=="function","missing roster widget methods")
        widget:DragAllowed(true)
        pcall(function() widget:SetCallback(function()
            if updatingAllyWidget then return end
            allyUI.customOrder=true
            allyUI.order={}
            for _,id in ipairs(widget:List()) do
                allyUI.order[#allyUI.order+1]=id
                allyUI.enabled[id]=widget:Get(id)==true;allyUI.edited[id]=true
            end
        end) end)
        widget:ToolTip("Shared by Helper and Combo. Click allied heroes to enable priority, drag to reorder. Roles set defaults only: positions 1/2/3 on, 4/5 off; unknown roles on. Faceless Void is excluded. Unselected allies still receive normal protection.")
        return widget
    end,"List")
end
local mobility=uiControl("Positioning (click / drag)",function()
    local widget=comboGroup:MultiSelect("Positioning (click / drag)",{
        {"Time Walk","panorama/images/spellicons/faceless_void_time_walk_png.vtex_c",true},
        {"Blink","panorama/images/items/blink_png.vtex_c",true}},true)
    widget:DragAllowed(true)
    widget:ToolTip("Click icons to enable/disable; drag to order. Blink always finishes positioning before Chronosphere.")
    return widget
end,"List")
if mobility then
    useBlink:Visible(false);useTimeWalk:Visible(false)
    useBlink={Get=function() return mobility:Get("Blink") end}
    useTimeWalk={Get=function() return mobility:Get("Time Walk") end}
end
local buttons=Enum.ButtonCode or {}
local comboKey=uiControl("Combo key",function()
    return comboGroup:Bind("Combo key",buttons.KEY_NONE or 0,"")
end,"IsPressed")
if not comboKey then
    local names,codes={"Unbound"},{0}

    for _,entry in ipairs({{"D","KEY_D",14},{"F","KEY_F",16},{"G","KEY_G",17},{"V","KEY_V",32},
        {"B","KEY_B",12},{"C","KEY_C",13},{"X","KEY_X",34},{"Z","KEY_Z",36},{"Space","KEY_SPACE",65}}) do
        local code=type(buttons[entry[2]])=="number" and buttons[entry[2]] or entry[3]
        names[#names+1]=entry[1];codes[#codes+1]=code
    end
    local selector=uiControl("Combo key selector",function() return comboGroup:Combo("Combo key (fallback)",names,0) end,"Get")
    local numeric=not selector
    if numeric then
        selector=comboGroup:Slider("Combo key code",0,106,0,"%d")
        selector:ToolTip("Fallback ButtonCode: 0 unbound, D=14, F=16, G=17, V=32, B=12, C=13, X=34, Z=36.")
    end
    local wasDown,lastCode,active=false,nil,false
    local function codeNow()
        local value=selector:Get()
        if type(value)~="number" or value~=value or value<0 or value>106 or value%1~=0 then return 0 end
        return numeric and value or codes[value+1] or 0
    end
    local function synchronize(isActive)
        active=isActive
        lastCode=codeNow()
        local ok,down=pcall(function() return lastCode>0 and Input.IsKeyDown(lastCode) end)
        wasDown=ok and down==true
        return true,lastCode,wasDown
    end
    comboKey={Get=codeNow,ResetInput=synchronize,RefreshInput=function()
        if codeNow()~=lastCode then return synchronize(active) end
        return false
    end,IsPressed=function()
        local code=codeNow()
        if code~=lastCode then synchronize(active);return false end
        if not active or not code or code<=0 then wasDown=false;return false end
        if Input and type(Input.IsKeyDownOnce)=="function" then
            local ok,pressed=pcall(Input.IsKeyDownOnce,code)
            local stateOK,down=pcall(function() return Input.IsKeyDown(code) end)
            if wasDown then wasDown=stateOK and down==true;return false end
            wasDown=stateOK and down==true
            return ok and pressed==true
        end
        local ok,down=pcall(function() return Input.IsKeyDown(code) end)
        local pressed=ok and down==true and not wasDown
        wasDown=ok and down==true
        return pressed
    end}
    console(function() return "[ChronosphereHelper v1] Using fallback Combo key selector" end)
end
console(function() return "[ChronosphereHelper v1] UI ready: key, Blink, Time Walk and mobility order configured" end)
local script, sending, pending, quiet, budgetCast, comboState = {}, false, nil, false, nil, nil

local Recovery={frame=nil}

local queuedPress, rawSeen, rawDown, bindingActive = nil, false, {}, nil
local castWatch
syncBinding=function()
    local active=master:Get() and comboEnabled:Get()
    local changed=bindingActive~=active
    local ok,inputChanged,code,held=pcall(function()
        if changed and comboKey.ResetInput then return comboKey.ResetInput(active) end
        if comboKey.RefreshInput then return comboKey.RefreshInput() end
    end)
    if not changed and not (ok and inputChanged) then return end
    bindingActive=active
    queuedPress=nil;rawDown={};rawSeen=false
    if ok and held and type(code)=="number" and code>0 then rawDown[code]=true end
    if not active then comboState=nil end
    pcall(function() if comboKey.Disabled then comboKey:Disabled(not active) end end)
    pcall(function() if comboKey.ShowInBindIsland then comboKey:ShowInBindIsland(active) end end)
    pcall(function() if not active and comboKey.SetToggled then comboKey:SetToggled(false) end end)
end
syncBinding()
pcall(function() master:SetCallback(syncBinding) end)
pcall(function() comboEnabled:SetCallback(syncBinding) end)
local logLines, diagnosticWas, announced, callbackSeen = 0, false, false, false
local function log(message)
    pcall(function()
        if quiet then return end
        if not Diagnostics.enabled() then diagnosticWas=false;return end
        if not diagnosticWas then logLines=0;diagnosticWas=true end
        if logLines>=500 then return end
        local text=Diagnostics.text(message)
        local ok,now=pcall(function() return GameRules.GetGameTime() end)
        local stamp=ok and type(now)=="number" and string.format("%.3f",now) or "?"
        logLines=logLines+1
        console(function() return "[ChronosphereHelper v1] t=" .. stamp .. " " .. text end)
        if logLines==500 then console(function() return "[ChronosphereHelper v1] Log limit reached; toggle Diagnostic logs to reset." end) end
    end)
end

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function point(p)
    if type(p)~="table" and type(p)~="userdata" then return false end
    return finite(p.x) and finite(p.y) and finite(p.z)
end
local function copyPoint(p)
    return point(p) and {x=p.x,y=p.y,z=p.z} or nil
end

local Native={}
function Native.member(value,kind)
    if (type(value)~="userdata" and type(value)~="table") or not Entity or type(Entity.IsEntity)~="function" then return false end
    local ok,present=pcall(Entity.IsEntity,value)
    if not ok or present~=true then return false end
    if not kind or kind=="IsEntity" then return true end
    if type(Entity[kind])~="function" then return false end
    local good,typed=pcall(Entity[kind],value)
    return good and typed==true
end
function Native.arguments(api,key,args)
    local kind=api==Ability and "IsAbility" or api==NPC and "IsNPC"
        or api==Player and "IsPlayer" or api==Entity and "IsEntity"
    if kind and not Native.member(args[1],kind) then return false,"invalid " .. kind end
    if api==NPC and key=="GetTimeToFacePosition" and not point(args[2]) then return false,"invalid position" end
    if api==Ability and key=="IsCastable" and (not finite(args[2]) or args[2]<0) then return false,"invalid mana" end
    if (api==NPC and (key=="GetAbilityByIndex" or key=="GetItemByIndex"))
        and (not finite(args[2]) or args[2]<0 or args[2]%1~=0) then return false,"invalid slot" end
    if (api==NPC and (key=="GetAbility" or key=="GetItem" or key=="HasModifier"))
        or (api==Ability and (key=="GetSpecialValueFor" or key=="GetLevelSpecialValueFor")) then
        if type(args[2])~="string" or args[2]=="" then return false,"invalid name" end
    end
    return true
end
function Native.call(api,key,report,...)
    if not api or type(api[key])~="function" then
        if report then log(function() return "Missing API: " .. key end) end
        return nil
    end
    local valid,reason=Native.arguments(api,key,{...})
    if not valid then
        if report then log(function() return "Native query skipped: " .. key .. "; " .. reason end) end
        return nil
    end
    local ok,value=pcall(api[key],...)
    if ok then return value end
    if report then log(function() return "API error " .. key .. ": " .. tostring(value) end) end
end
local function read(api,key,...) return Native.call(api,key,true,...) end
local function distance2(a, b)
    return (a.x-b.x)^2 + (a.y-b.y)^2
end
local function describe(p)
    if not point(p) then return tostring(p) end
    return string.format("(%.1f,%.1f,%.1f)", p.x,p.y,p.z)
end
local function screenPoint(p)

    if quiet or not Diagnostics.enabled() or logLines>=500 or not point(p) then return end

    if Renderer and type(Renderer.WorldToScreen)=="function" then
        local success,sx,sy,visible=pcall(Renderer.WorldToScreen,Vector(p.x,p.y,p.z))
        if success and visible~=false and finite(sx) and finite(sy) then return {x=sx,y=sy} end
    end
end
local function budgetSeconds()
    local value=timeBudget:Get()
    return finite(value) and math.max(0,math.min(1500,value))/1000 or 0
end

local MAX_EVALUATIONS, PRECISION = 4096, 0.5
local RADIAL_OFFSETS,SIGNS={-0.25,0.25},{1,-1}
local CARDINAL_ANGLES={0,math.pi/2,math.pi,3*math.pi/2}
local REFINEMENT_OFFSETS={}
for x=-1,1 do
    for y=-1,1 do
        if x~=0 or y~=0 then
            local norm=math.sqrt(x*x+y*y)
            REFINEMENT_OFFSETS[#REFINEMENT_OFFSETS+1]={x=x/norm,y=y/norm}
        end
    end
end
local function visitRefinement(visited,position,step)
    visited[step]=visited[step] or {}
    local positions=visited[step]
    positions[position.x]=positions[position.x] or {}
    if positions[position.x][position.y] then return false end
    positions[position.x][position.y]=true
    return true
end
local TAU = math.pi*2
local function intersections(a,b)
    local dx,dy=b.x-a.x,b.y-a.y
    local d2=dx*dx+dy*dy
    if d2<1e-12 then return {} end
    local d=math.sqrt(d2)
    if d>a.r+b.r+1e-7 or d<math.abs(a.r-b.r)-1e-7 then return {} end
    local along=(a.r*a.r-b.r*b.r+d2)/(2*d)
    local h2=a.r*a.r-along*along
    if h2 < -1e-5 then return {} end
    local h=math.sqrt(math.max(0,h2))
    local x,y=a.x+dx*along/d,a.y+dy*along/d
    local p={x=x-dy*h/d,y=y+dx*h/d}
    if h<1e-7 then return {p} end
    return {p,{x=x+dy*h/d,y=y-dx*h/d}}
end

local function optional(api,key,...)
    return Native.call(api,key,false,...)
end
local attemptSerial=0
local function nextAttempt()
    attemptSerial=attemptSerial+1
    return attemptSerial
end
local function trace(id,stage,detail)
    pcall(function()
        if not Diagnostics.enabled() then return end

        console(function()
            return string.format("[ChronosphereHelper v1] attempt=%s stage=%s %s",
                tostring(id),stage,detail~=nil and Diagnostics.text(detail) or "")
        end)
    end)
end
function Native.dispatch(hero,ability,pos,kind,showEffects,id,expectedName,interruptAbility)
    local player=optional(Players,"GetLocal")
    local castOrder=Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION
    local stopOrder=Enum.UnitOrder.DOTA_UNIT_ORDER_STOP or 21
    if not Native.member(hero,"IsHero") or not Native.member(hero,"IsNPC")
        or optional(Heroes,"GetLocal")~=hero or not Native.member(player,"IsPlayer")
        or optional(Entity,"IsAlive",hero)~=true
        or not point(pos) or not finite(kind) or (kind~=castOrder and kind~=stopOrder)
        or (kind==castOrder and ability==nil) or (kind==stopOrder and ability~=nil)
        or (interruptAbility~=nil and kind~=stopOrder)
        or not Player or type(Player.PrepareUnitOrders)~="function" then
        trace(id,"dispatch-skipped",function() return "invalid caster / player / position / order" end);return false
    end
    if ability and (not Native.member(ability,"IsAbility") or optional(Ability,"GetOwner",ability)~=hero) then
        trace(id,"dispatch-skipped",function() return "invalid ability or owner" end);return false
    end
    if ability then
        local name=optional(Ability,"GetName",ability)
        local supported=name=="faceless_void_chronosphere" or name=="faceless_void_time_walk"
            or name=="item_blink" or name=="item_overwhelming_blink" or name=="item_swift_blink" or name=="item_arcane_blink"
        if not supported or name~=expectedName or optional(Ability,"IsInAbilityPhase",ability)~=false or optional(Ability,"IsReady",ability)~=true then
            trace(id,"dispatch-skipped",function() return "ability changed / phase started / not ready" end);return false
        end
    end
    local issuer=(Enum.PlayerOrderIssuer or {}).DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY or 3
    local previousSending=sending
    sending=true
    trace(id,"native-order",function() return string.format("order=%d center=%s",kind,describe(pos)) end)
    local issued=false
    local ok,result=pcall(function()
        if interruptAbility and (not Native.member(interruptAbility,"IsAbility")
            or optional(Ability,"GetOwner",interruptAbility)~=hero
            or optional(Ability,"GetName",interruptAbility)~="faceless_void_chronosphere"
            or optional(Ability,"IsInAbilityPhase",interruptAbility)~=true
            or optional(Heroes,"GetLocal")~=hero) then return end
        issued=true
        return Player.PrepareUnitOrders(player,kind,nil,Vector(pos.x,pos.y,pos.z),ability,
            issuer,hero,false,showEffects==true,false,false,"ChronosphereHelper_v1")
    end)

    local sent=ok and issued
    if sent and Recovery.frame then Recovery.frame.emitted=true end
    sending=previousSending
    trace(id,"native-order-return",function()
        if sent then return "call completed; execution not assumed" end
        return ok and "skipped: cast phase changed before STOP" or tostring(result)
    end)
    return sent
end
local function abilityValue(ab,key,report)
    local reader=report and read or optional
    local value
    if Ability and type(Ability.GetSpecialValueFor)=="function" then value=reader(Ability,"GetSpecialValueFor",ab,key) end
    if not finite(value) or ((key=="radius" or key=="blink_range") and value<=0) then
        local fallback=reader(Ability,"GetLevelSpecialValueFor",ab,key)
        if finite(fallback) then value=fallback end
    end
    return finite(value) and value or nil
end

local aegisTracking={owner=nil,time=nil,records={}}
local function resetAegis()
    aegisTracking={owner=nil,time=nil,records={}}
end
local function observeAegis(hero)
    local now=optional(GameRules,"GetGameTime")
    if not hero or not finite(now) then resetAegis();return end
    if aegisTracking.owner~=hero or (aegisTracking.time and now<aegisTracking.time) then resetAegis() end
    aegisTracking.owner=hero;aegisTracking.time=now
    local team=optional(Entity,"GetTeamNum",hero)
    local seen={}
    for _,unit in ipairs(optional(Heroes,"GetAll") or {}) do
        local unitTeam=optional(Entity,"GetTeamNum",unit)
        if unit~=hero and team~=nil and unitTeam~=nil and unitTeam~=team
            and optional(NPC,"IsIllusion",unit)==false then
            seen[unit]=true
            local record=aegisTracking.records[unit] or {state="unknown"}
            aegisTracking.records[unit]=record
            local alive=optional(Entity,"IsAlive",unit)
            if alive==true then
                if record.state=="pending" then log(function() return "Aegis tracking: return observed; enemy=" .. tostring(unit) end) end
                local visible=optional(NPC,"IsVisible",unit)==true and optional(Entity,"IsDormant",unit)==false
                local at=optional(Entity,"GetAbsOrigin",unit)
                record.state="alive";record.position=nil
                record.trusted=visible and point(at) and true or false
                local held
                if record.trusted then held=optional(NPC,"HasAegis",unit) end
                if type(held)=="boolean" then record.held=held else record.held=nil end
                if record.held==nil then record.trusted=false end
            elseif alive==false then
                if record.state=="alive" then
                    if record.trusted and record.held==true then
                        local at=optional(Entity,"GetAbsOrigin",unit)
                        if point(at) and optional(Entity,"IsDormant",unit)==false then
                            record.state="pending";record.position=Vector(at.x,at.y,at.z)
                            log(function() return "Aegis tracking: pending return; enemy=" .. tostring(unit) .. " at=" .. describe(record.position) end)
                        else record.state="unknown";record.position=nil end
                    elseif record.trusted and record.held==false then
                        record.state="ordinary";record.position=nil
                        log(function() return "Aegis tracking: ordinary death confirmed; enemy=" .. tostring(unit) end)
                    else record.state="unknown";record.position=nil end
                end
                record.trusted=false;record.held=nil
            else record.state="unknown";record.trusted=false;record.held=nil;record.position=nil end
        end
    end
    for unit,record in pairs(aegisTracking.records) do
        if not seen[unit] then aegisTracking.records[unit]=nil end
    end
end
local function pendingReturnsInside(hero,pos,radius)
    local result={}
    if aegisTracking.owner~=hero then return result end
    for unit,record in pairs(aegisTracking.records) do
        if record.state=="pending" and point(record.position) and distance2(record.position,pos)<=radius^2 then
            result[#result+1]={unit=unit,pos=record.position,inside=true,future=true}
        end
    end
    return result
end
local function failAllows(hero,ab,pos,duringPhase)
    if not master:Get() or not failEnabled:Get() then return true end
    local phase=optional(Ability,"IsInAbilityPhase",ab)
    if duringPhase then
        if phase~=true then return true,"cast phase ended or unknown" end
    elseif phase~=false then return true,"cast phase already started or unknown" end
    log(function() return "Fail Switch query: enemy roster and current positions" end)
    local team=optional(Entity,"GetTeamNum",hero)
    local radius=abilityValue(ab,"radius")
    local players=optional(Players,"GetAll")
    if team==nil or not point(pos) or not finite(radius) or radius<=0 or type(players)~="table" then
        log(function() return "Fail Switch allowed: insufficient information (roster / geometry)" end);return true
    end
    observeAegis(hero)
    local roster,units,unknown={}, {},false
    for _,player in ipairs(players) do
        local unit=optional(Player,"GetAssignedHero",player)
        local playerTeam=optional(Entity,"GetTeamNum",player)
        local unitTeam=unit and optional(Entity,"GetTeamNum",unit)
        local enemyTeam=unitTeam or playerTeam
        if enemyTeam==nil then unknown=true
        elseif enemyTeam~=team and (enemyTeam==2 or enemyTeam==3) then
            if not unit or units[unit] or (playerTeam and unitTeam and playerTeam~=unitTeam) then unknown=true end
            if unit then units[unit]=true end
            roster[#roster+1]={unit=unit}
        end
    end
    if #roster~=5 then unknown=true end
    local dead,located,inside,returns=0,0,0,0
    for _,entry in ipairs(roster) do
        local unit=entry.unit
        if not unit or optional(NPC,"IsIllusion",unit)~=false then unknown=true
        else
            local alive=optional(Entity,"IsAlive",unit)
            if alive==false then
                dead=dead+1
                local record=aegisTracking.records[unit]
                if record and record.state=="pending" and point(record.position) then
                    if distance2(record.position,pos)<=radius^2 then returns=returns+1 end
                elseif not record or record.state~="ordinary" then unknown=true end
            elseif alive==true then
                local at=optional(Entity,"GetAbsOrigin",unit)
                if optional(NPC,"IsVisible",unit)~=true or optional(Entity,"IsDormant",unit)~=false or not point(at) then unknown=true
                else
                    located=located+1
                    if distance2(at,pos)<=radius^2 then inside=inside+1 end
                end
            else unknown=true end
        end
    end
    log(function() return string.format("Fail Switch roster: enemies=%d dead=%d located=%d inside=%d aegis_returns=%d unknown=%s center=%s",#roster,dead,located,inside,returns,tostring(unknown),describe(pos)) end)
    if inside>0 then log(function() return "Fail Switch allowed: enemy inside" end);return true end
    if returns>0 then log(function() return "Fail Switch allowed: pending Aegis return inside" end);return true end
    if unknown then log(function() return "Fail Switch allowed: insufficient information (hidden / incomplete / uncertain death)" end);return true end
    log(function() return "Fail Switch blocked: confirmed empty area" end)
    return false
end

local function armCastWatch(hero,ab,pos,id)
    castWatch=nil
    if master:Get() and failEnabled:Get() and point(pos) then
        castWatch={hero=hero,ability=ab,center=copyPoint(pos),attempt=id,active=false}
        trace(id,"cast-watch-armed",function() return describe(pos) end)
    end
end
local function allowManualCast(hero,order)
    if not failAllows(hero,order.ability,order.position) then return false end
    armCastWatch(hero,order.ability,order.position,order.attempt or nextAttempt())
    return true
end
local function checkCastWatch()
    local w=castWatch
    if not w then return false end
    if not master:Get() or not failEnabled:Get() or optional(Heroes,"GetLocal")~=w.hero
        or optional(Entity,"IsAlive",w.hero)~=true or optional(Ability,"GetOwner",w.ability)~=w.hero
        or optional(Ability,"GetName",w.ability)~="faceless_void_chronosphere" then castWatch=nil;return false end
    local phase=optional(Ability,"IsInAbilityPhase",w.ability)
    if phase~=true then
        if phase==nil or w.active or optional(Ability,"IsReady",w.ability)~=true then castWatch=nil end
        return false
    end
    w.active=true
    if failAllows(w.hero,w.ability,w.center,true) then return false end
    if castWatch~=w or optional(Ability,"IsInAbilityPhase",w.ability)~=true then return false end
    if failAllows(w.hero,w.ability,w.center,true) then return false end
    if castWatch~=w or optional(Heroes,"GetLocal")~=w.hero
        or optional(Ability,"GetOwner",w.ability)~=w.hero
        or optional(Ability,"IsInAbilityPhase",w.ability)~=true then return false end
    local at=copyPoint(optional(Entity,"GetAbsOrigin",w.hero))
    if not at or castWatch~=w or optional(Ability,"GetName",w.ability)~="faceless_void_chronosphere"
        or optional(Ability,"IsInAbilityPhase",w.ability)~=true then return false end
    castWatch=nil;pending=nil;budgetCast=nil;comboState=nil;queuedPress=nil
    if bindingActive then
        pcall(function() comboKey:IsPressed() end)
        pcall(function() if comboKey.ResetInput then comboKey.ResetInput(true) end end)
    end
    trace(w.attempt,"cast-empty-stop",function() return "confirmed empty during cast phase; one STOP attempt" end)
    Native.dispatch(w.hero,nil,at,Enum.UnitOrder.DOTA_UNIT_ORDER_STOP or 21,false,w.attempt,nil,w.ability)
    return true
end

local function prioritySnapshot(team,hero,all)
    local cached=Recovery.frame and Recovery.frame.priority
    if cached and cached.hero==hero and cached.team==team then return cached.mode,cached.order,cached.roles,cached.ids end
    local mode="Enemies first"
    local ok,value=pcall(function() return targetPriority:Get() end)
    if ok and value==1 then mode="Allies first" end
    local byHero,slots={},{}
    if Players and type(Players.GetAll)=="function" and Player
        and type(Player.GetAssignedHero)=="function" then
        local players=read(Players,"GetAll")
        if type(players)=="table" then
            for i,player in ipairs(players) do
                local unit=read(Player,"GetAssignedHero",player)
                if unit and unit~=hero and read(Entity,"GetTeamNum",unit)==team then
                    local data=type(Player.GetTeamData)=="function" and read(Player,"GetTeamData",player)
                    local flag=type(data)=="table" and data.lane_selection_flags
                    byHero[unit]=type(flag)=="number" and ROLE_FLAGS[flag] or "Unknown"
                    local slot=type(Player.GetPlayerTeamSlot)=="function" and read(Player,"GetPlayerTeamSlot",player)
                    slots[unit]=finite(slot) and slot or i
                end
            end
        end
    end
    local roster,ids,records={},{},{}
    for i,unit in ipairs(all or read(Heroes,"GetAll") or {}) do
        if unit~=hero and read(Entity,"GetTeamNum",unit)==team and read(NPC,"IsIllusion",unit)==false then
            local name=NPC and type(NPC.GetUnitName)=="function" and read(NPC,"GetUnitName",unit)
            if name~="npc_dota_hero_faceless_void" then
                local index=Entity and type(Entity.GetIndex)=="function" and read(Entity,"GetIndex",unit)
                local id=type(name)=="string" and name or ("Ally " .. tostring(index or i))
                if records[id] then id=id .. " #" .. tostring(index or i) end
                local role=byHero[unit] or "Unknown"
                local rank=6
                for r,known in ipairs(DEFAULT_ROLES) do if known==role then rank=r end end
                local record={id=id,unit=unit,role=role,rank=rank,slot=slots[unit] or index or math.huge,
                    icon=type(name)=="string" and ("panorama/images/heroes/icons/" .. name .. "_png.vtex_c") or ""}
                roster[#roster+1]=record;records[id]=record;ids[unit]=id
            end
        end
    end
    table.sort(roster,function(a,b)
        if a.rank~=b.rank then return a.rank<b.rank end
        if a.slot~=b.slot then return a.slot<b.slot end
        return a.id<b.id
    end)
    local now=read(GameRules,"GetGameTime")
    local reset=allyUI.owner~=hero or (finite(now) and now<allyUI.lastRefresh)
    if reset then
        allyUI={order={},enabled={},edited={},customOrder=false,signature=nil,owner=hero,lastRefresh=-math.huge}
    elseif rolePriority then

        pcall(function()
            local order,seen={},{}
            for _,id in ipairs(rolePriority:List()) do
                if records[id] and not seen[id] then
                    seen[id]=true;order[#order+1]=id
                    local selected=rolePriority:Get(id)==true
                    if selected~=allyUI.enabled[id] then allyUI.edited[id]=true end
                    allyUI.enabled[id]=selected
                end
            end
            if table.concat(order,"|")~=table.concat(allyUI.order,"|") and #order==#allyUI.order then
                allyUI.customOrder=true
            end
            allyUI.order=order
        end)
    end
    local signature={}
    for _,r in ipairs(roster) do signature[#signature+1]=r.id .. ":" .. r.role end
    signature=table.concat(signature,"|")
    if signature~=allyUI.signature then
        local order,seen={},{}
        if allyUI.customOrder then
            for _,id in ipairs(allyUI.order) do if records[id] then order[#order+1]=id;seen[id]=true end end
        end
        for _,r in ipairs(roster) do
            if not seen[r.id] then order[#order+1]=r.id;seen[r.id]=true end
            if not allyUI.edited[r.id] then allyUI.enabled[r.id]=r.rank<=3 or r.role=="Unknown" end
        end
        allyUI.order=order;allyUI.signature=signature
        local items={}
        for _,id in ipairs(order) do items[#items+1]={id,records[id].icon,allyUI.enabled[id]} end
        if not rolePriority and #items>0 then rolePriority=createAllyPriority(items) end
        if rolePriority then
            updatingAllyWidget=true
            local updated,err=pcall(function() rolePriority:Update(items,true,false) end)
            updatingAllyWidget=false
            if not updated then log(function() return "Ally roster UI update failed: " .. tostring(err) end) end
        end
    end
    allyUI.lastRefresh=finite(now) and now or allyUI.lastRefresh
    local selected={}
    for _,id in ipairs(allyUI.order) do if records[id] and allyUI.enabled[id] then selected[#selected+1]=id end end
    if Recovery.frame then Recovery.frame.priority={hero=hero,team=team,mode=mode,order=selected,roles=byHero,ids=ids} end
    return mode,selected,byHero,ids
end
local function roleCountsText(counts)
    local parts,keys={},{}
    for id in pairs(counts) do keys[#keys+1]=id end
    table.sort(keys)
    for _,id in ipairs(keys) do parts[#parts+1]=id .. "=" .. tostring(counts[id]) end
    return #parts>0 and table.concat(parts,",") or "none"
end

local Placement={}
function Placement.prepare(r,ordinal)
    r.ordinal=ordinal
    r.walking=finite(r.movement) and r.movement>0 or false
    r.rank={math.floor(r.violation/1e-9+0.5),math.floor(r.edge/1e-5+0.5),
        math.floor(r.safety/1e-6+0.5),math.floor(r.eta/1e-9+0.5),math.floor(r.shift/1e-7+0.5)}
    return r
end
function Placement.compareRoles(a,b,order)
    for _,id in ipairs(order) do
        local x,y=a[id] or 0,b[id] or 0
        if x~=y then return x<y and -1 or 1 end
    end
    return 0
end
function Placement.better(a,b,policy)
    if not b then return true end
    if policy.mode=="Enemies first" and a.captured~=b.captured then return a.captured>b.captured end
    if a.count~=b.count then return a.count<b.count end
    local roles=Placement.compareRoles(a.roles,b.roles,policy.order)
    if roles~=0 then return roles<0 end
    if a.captured~=b.captured then return a.captured>b.captured end
    local x,y=a.rank,b.rank
    if x[1]~=y[1] then return x[1]<y[1] end
    if not policy.automatic then
        if a.walking~=b.walking then return not a.walking end
        if x[4]~=y[4] then return x[4]<y[4] end
    end
    if policy.edge and x[2]~=y[2] then return x[2]>y[2] end
    if x[3]~=y[3] then return x[3]>y[3] end
    if x[4]~=y[4] then return x[4]<y[4] end
    if x[5]~=y[5] then return x[5]<y[5] end
    return a.ordinal<b.ordinal
end

local Motion={owner=nil,time=nil,records={},horizon=0.25}
function Motion.reset()
    if Motion.owner==nil and Motion.time==nil and next(Motion.records)==nil then return end
    Motion.owner=nil;Motion.time=nil;Motion.records={}
end
function Motion.observe(hero,states)
    local now=optional(GameRules,"GetGameTime")
    local team=optional(Entity,"GetTeamNum",hero)
    if not finite(now) or team==nil then Motion.reset();return end
    if Motion.owner~=hero or (Motion.time and now<Motion.time) then Motion.reset() end
    Motion.owner=hero;Motion.time=now
    if not states then
        local units=optional(Heroes,"GetAll")
        if type(units)~="table" then Motion.reset();return end
        states={}
        for _,unit in ipairs(units) do
            states[#states+1]={unit=unit,team=optional(Entity,"GetTeamNum",unit),alive=optional(Entity,"IsAlive",unit),
                visible=optional(NPC,"IsVisible",unit),dormant=optional(Entity,"IsDormant",unit),
                illusion=optional(NPC,"IsIllusion",unit),pos=copyPoint(optional(Entity,"GetAbsOrigin",unit))}
        end
    end
    local seen={}
    for _,state in ipairs(states) do
        local unit=state.unit
        if unit~=hero and state.team~=nil and state.team~=team and state.alive==true
            and state.visible==true and state.dormant==false and state.illusion==false and point(state.pos) then
            seen[unit]=true
            local previous=Motion.records[unit]
            local record={time=now,pos=copyPoint(state.pos)}
            local running=optional(NPC,"IsRunning",unit)
            local speed=optional(NPC,"GetMoveSpeed",unit)
            if previous and running==true and finite(speed) and speed>0 then
                local dt=now-previous.time
                if dt>0 and dt<=Motion.horizon then
                    local dx,dy=state.pos.x-previous.pos.x,state.pos.y-previous.pos.y
                    local length=math.sqrt(dx*dx+dy*dy)
                    if length>0 and length<=speed*dt+PRECISION then
                        local scale=math.min(1,speed*dt/length)/dt
                        record.velocity={x=dx*scale,y=dy*scale}
                    end
                elseif dt==0 and distance2(state.pos,previous.pos)==0 then record.velocity=previous.velocity end
            end
            Motion.records[unit]=record
        end
    end
    for unit in pairs(Motion.records) do if not seen[unit] then Motion.records[unit]=nil end end
end
function Motion.velocity(unit,at,now)
    local record=Motion.records[unit]
    if record and record.velocity and finite(now) and now>=record.time and now-record.time<=Motion.horizon
        and point(at) and distance2(at,record.pos)==0 then return record.velocity end
end
function Motion.project(at,velocity,preparation,castPoint)
    if not velocity or not finite(castPoint) or castPoint<0 then return at end
    local horizon=math.min(Motion.horizon,math.max(0,preparation)+castPoint)
    return {x=at.x+velocity.x*horizon,y=at.y+velocity.y*horizon,z=at.z}
end

local function analysisSnapshot(hero,ability)
    local all=read(Heroes,"GetAll")
    if type(all)~="table" then return nil end
    local team=read(Entity,"GetTeamNum",hero)
    local mode,order,roles,ids=prioritySnapshot(team,hero,all)
    local snapshot={origin=copyPoint(read(Entity,"GetAbsOrigin",hero)),radius=abilityValue(ability,"radius",true),
        range=read(Ability,"GetCastRange",ability),bonus=read(NPC,"GetCastRangeBonus",hero),team=team,
        speed=optional(NPC,"GetMoveSpeed",hero),castPoint=optional(Ability,"GetCastPoint",ability,true),time=optional(GameRules,"GetGameTime"),budget=budgetSeconds(),edge=meleeAccess:Get(),inset=edgeInset:Get(),mode=mode,order=order,roles=roles,ids=ids,units={}}
    for _,unit in ipairs(all) do
        local record={unit=unit,alive=read(Entity,"IsAlive",unit),illusion=read(NPC,"IsIllusion",unit),
            dormant=read(Entity,"IsDormant",unit),team=read(Entity,"GetTeamNum",unit),
            pos=copyPoint(read(Entity,"GetAbsOrigin",unit)),visible=read(NPC,"IsVisible",unit),
            hull=optional(NPC,"GetHullRadius",unit),ranged=optional(NPC,"IsRanged",unit)}
        snapshot.units[#snapshot.units+1]=record
    end
    Motion.observe(hero,snapshot.units)
    for _,state in ipairs(snapshot.units) do state.velocity=Motion.velocity(state.unit,state.pos,snapshot.time) end
    return snapshot
end

local function solveCorrection(hero, ability, original, options)
    options=options or {}
    local automatic=options.combo==true
    local rescue=options.rescueAnchor~=nil
    local snapshot=options.snapshot or analysisSnapshot(hero,ability)
    if not snapshot then return nil,"Heroes.GetAll did not return a table" end
    local origin,radius,range,bonus,team=snapshot.origin,snapshot.radius,snapshot.range,snapshot.bonus,snapshot.team
    log(function() return "Data: origin=" .. describe(origin) .. " destination=" .. describe(original)
        .. " radius=" .. tostring(radius) .. " range=" .. tostring(range)
        .. " bonus=" .. tostring(bonus) .. " team=" .. tostring(team) end)
    if not point(origin) or not point(original) or not finite(radius) or radius <= 0
        or not finite(range) or not finite(bonus) or team == nil then return nil, "incomplete or invalid data" end
    range = range + bonus
    if range < 1 then return nil, "insufficient effective cast range" end
    local length = math.sqrt(distance2(origin, original))
    local budget=automatic and options.setup or snapshot.budget
    local speed=snapshot.speed
    local canMove=budget>0 and finite(speed) and speed>0
    local originalMove=not automatic and canMove and math.max(0,length-range)/speed or 0
    local timingAPI=NPC and type(NPC.GetTimeToFacePosition)=="function"
    local timingErrors=0
    local function turnAt(p)
        if not timingAPI then return nil end
        local value=read(NPC,"GetTimeToFacePosition",hero,Vector(p.x,p.y,original.z))
        if finite(value) and value>=0 then return value end
        timingErrors=timingErrors+1
        if timingErrors==1 then log(function() return "Turn time unavailable: " .. tostring(value) end) end
    end
    local originalTurn
    if budget>0 then originalTurn=turnAt(original) end
    local searchRange=automatic and options.reach or (canMove and range+speed*(originalMove+(originalTurn or 0)+budget) or range)

    if length > range then
        log(function() return string.format("Original center out of range: distance=%.1f range=%.1f; searching within preparation budget",
            length,range) end)
    end
    local mode,roleOrder,roles,allyIDs=snapshot.mode,snapshot.order,snapshot.roles,snapshot.ids
    log(function() return "Target priority: " .. mode .. "; selected allies=" .. table.concat(roleOrder," > ") end)
    local allies, enemies = {}, {}
    local scanned = 0
    for _,state in ipairs(snapshot.units) do
        local unit=state.unit
        scanned=scanned+1
        local alive,illusion,dormant=state.alive,state.illusion,state.dormant
        if unit ~= hero and alive == true and illusion == false and dormant == false then
            local unitTeam = state.team
            local pos = state.pos
            local visible = unitTeam == team or state.visible
            if unitTeam ~= nil and point(pos)
                and visible == true then
                local ally = unitTeam == team
                local inside = distance2(pos, original) <= radius^2
                log(function() return "Hero " .. tostring(unit) .. " team=" .. tostring(unitTeam)
                    .. " pos=" .. describe(pos) .. " inside=" .. tostring(inside) end)

                local hull=state.hull
                local padding=finite(hull) and math.max(8,hull+4) or 8
                local record = {unit=unit,pos=pos,velocity=state.velocity,inside=inside,padding=padding,role=roles[unit] or "Unknown",priorityID=allyIDs[unit] or tostring(unit),
                    melee=ally and state.ranged==false}
                if ally then
                    allies[#allies+1] = record
                    log(function() return "Ally role: unit=" .. tostring(unit) .. "; role=" .. record.role end)
                else
                    record.required=not automatic and ((rescue and unit==options.rescueAnchor) or (not rescue and inside))
                    if record.required or (automatic and distance2(pos,original)<=options.search^2)
                        or (not automatic and distance2(pos,origin)<=(searchRange+radius)^2) then
                        enemies[#enemies+1]=record
                    end
                end
            else
                log(function() return "Skipped hero " .. tostring(unit) .. " team=" .. tostring(unitTeam)
                    .. " pos=" .. describe(pos) .. " visible=" .. tostring(visible) end)
            end
        elseif unit ~= hero then
            log(function() return "Skipped hero " .. tostring(unit) .. " alive=" .. tostring(alive)
                .. " illusion=" .. tostring(illusion) .. " dormant=" .. tostring(dormant) end)
        end
    end
    for _,record in ipairs(options.returnAnchors or {}) do
        record.required=true
        enemies[#enemies+1]=record
        log(function() return "Helper preserved Aegis return: " .. describe(record.pos) end)
    end
    local predicting=false
    if finite(snapshot.castPoint) and snapshot.castPoint>=0 then
        for _,enemy in ipairs(enemies) do if enemy.velocity then predicting=true;break end end
    end
    if predicting then
        trace(options.attempt,"prediction",function() return "observed movement; maximum horizon_ms=250; current targets preserved" end)
    end
    local originalEnemies=0
    for _,enemy in ipairs(enemies) do if enemy.inside then originalEnemies=originalEnemies+1 end end
    local baseline,baselineRoles=0,{}
    for _,a in ipairs(allies) do if a.inside then
        baseline=baseline+1;baselineRoles[a.priorityID]=(baselineRoles[a.priorityID] or 0)+1
    end end
    log(function() return "Original allies caught: " .. roleCountsText(baselineRoles) end)
    log(function() return string.format("Analysis: heroes=%d allies=%d allies_inside=%d enemies_inside=%d",
        scanned,#allies,baseline,originalEnemies) end)
    if #enemies == 0 then return nil, "no visible enemy inside the original area" end
    local hasMelee=false
    for _,a in ipairs(allies) do if a.melee then hasMelee=true end end
    local preferEdge=snapshot.edge and hasMelee
    local preferredInset=snapshot.inset
    if not finite(preferredInset) then preferredInset=12;log(function() return "Invalid Enemy edge inset; using default 12" end) end
    if not automatic and not rescue and not options.returnAnchors and baseline == 0 and not preferEdge and #enemies<=originalEnemies and not predicting then return nil, "no ally inside the original area" end

    for _, enemy in ipairs(enemies) do
        local distance=math.sqrt(distance2(origin,enemy.pos))
        if enemy.required and distance > searchRange+radius then
            local reason=budget>0 and "original enemy outside the preparation budget"
                or "original enemy unreachable without movement"
            return nil,string.format(reason .. ": distance=%.1f maximum=%.1f (search_range=%.1f + radius=%.1f) deficit=%.1f",
                distance,searchRange+radius,searchRange,radius,distance-searchRange-radius)
        end
    end
    if budget==0 then originalTurn=turnAt(original) end
    local prepBaseline=automatic and 0 or originalMove+(originalTurn or 0)
    log(function() return "Turn: original_time=" .. tostring(originalTurn) .. " search_2d=true" end)
    if not timingAPI then log(function() return "Turn timing API unavailable; reject unverifiable candidates without restricting geometry to one axis" end) end
    if options.emergency then
        log(function() return "Deadline fallback budget: current cast range only; no movement or new deadline" end)
    else
        log(function() return string.format("Budget: max_additional_ms=%.1f original_preparation_ms=%.1f speed=%s search_range=%.1f",
            budget*1000,prepBaseline*1000,tostring(speed),searchRange) end)
    end

    local collectStats=not quiet and Diagnostics.enabled() and logLines<500
    local evaluated, capped, seen, sources = 0,false,{},{}
    local rejects={range=0,enemy=0,ally=0,gain=0,time=0,unknown=0}
    local best, seeds, temporalSeeds = nil,{},{}
    local policy={automatic=automatic and not options.emergency,mode=mode,order=roleOrder,edge=preferEdge}
    local function compareRoles(a,b) return Placement.compareRoles(a,b,roleOrder) end
    local function better(a,b) return Placement.better(a,b,policy) end
    local function remember(r)
        if not r.verified then return end
        seeds[#seeds+1]=r
        table.sort(seeds,better)
        if #seeds>16 then seeds[#seeds]=nil end
        if r.violation>0 then
            temporalSeeds[#temporalSeeds+1]=r
            table.sort(temporalSeeds,better)
            if #temporalSeeds>8 then temporalSeeds[#temporalSeeds]=nil end
        end
    end
    local function evaluate(x,y,source,refining)
        if evaluated>=MAX_EVALUATIONS or (options.work and options.work.total>=MAX_EVALUATIONS) then capped=true; return end
        if not finite(x) or not finite(y) then return end
        local key=string.format("%.4f:%.4f",x,y)
        if seen[key] then
            if type(seen[key])=="table" then return seen[key] end
            return
        end
        seen[key]=true
        evaluated=evaluated+1
        if options.work then options.work.total=options.work.total+1 end
        if collectStats then
            local family=source:match("^[^_]+")
            sources[family]=(sources[family] or 0)+1
        end
        local p={x=x,y=y}
        local dist=math.sqrt(distance2(origin,p))
        if dist>searchRange+1e-7 then if collectStats then rejects.range=rejects.range+1 end; return end
        if dist>searchRange then
            local scale=(searchRange-1e-6)/dist
            x=origin.x+(x-origin.x)*scale; y=origin.y+(y-origin.y)*scale
            p.x=x;p.y=y;dist=math.sqrt(distance2(origin,p))
        end
        local represented=copyPoint(Vector(x,y,original.z))
        if not represented then return end
        p=represented;x=p.x;y=p.y
        dist=math.sqrt(distance2(origin,p))
        if dist>searchRange then if collectStats then rejects.range=rejects.range+1 end;return end
        local enemySlack,allySlack,captured=math.huge,math.huge,0
        local caught=preferEdge and {} or nil
        for _,e in ipairs(enemies) do
            local d2=distance2(e.pos,p)
            if d2>radius^2 then
                if e.required or (automatic and e.unit==options.anchor) then if collectStats then rejects.enemy=rejects.enemy+1 end; return end
            else
                captured=captured+1
                if caught then caught[#caught+1]=e end
                enemySlack=math.min(enemySlack,radius-math.sqrt(d2))
            end
        end
        if automatic and captured<options.minimum then if collectStats then rejects.enemy=rejects.enemy+1 end;return end
        local count,caughtRoles=0,{}
        for _,a in ipairs(allies) do
            local d2=distance2(a.pos,p)
            if d2<=(radius+a.padding)^2 then
                if (not automatic and not a.inside) or (options.protection and not options.protection.allowedAllies[a.unit]) then
                    if collectStats then rejects.ally=rejects.ally+1 end;return
                end
                count=count+1
                caughtRoles[a.priorityID]=(caughtRoles[a.priorityID] or 0)+1
            else
                allySlack=math.min(allySlack,math.sqrt(d2)-radius-a.padding)
            end
        end
        if options.protection and (count>options.protection.count
            or (count==options.protection.count and compareRoles(caughtRoles,options.protection.roles)>0)) then
            if collectStats then rejects.ally=rejects.ally+1 end;return
        end
        local ox,oy=original.x-origin.x,original.y-origin.y
        local px,py=x-origin.x,y-origin.y
        local same=length>1e-8 and dist>1e-8 and ox*px+oy*py>0
            and math.abs(ox*py-oy*px)<=length*dist*1e-10
        local turn
        if not automatic then
            if same and originalTurn~=nil then turn=originalTurn else turn=turnAt(p) end
        end
        local verified=turn~=nil or same
        local movement=canMove and math.max(0,dist-range)/speed or 0
        local eta=movement+(turn or 0)

        local base=prepBaseline
        if turn==nil and same then base=originalMove end
        local extra=math.max(0,eta-base)
        local route
        if automatic then
            route=options.route(p)
            if not route then if collectStats then rejects.time=rejects.time+1 end;return end
            eta=route.eta;extra=eta;verified=true;turn=route.turn;movement=route.movement
        end
        if predicting then
            captured=0;enemySlack=math.huge
            if caught then for i=#caught,1,-1 do caught[i]=nil end end
            for _,enemy in ipairs(enemies) do
                local actual=distance2(enemy.pos,p)
                local predicted=distance2(Motion.project(enemy.pos,enemy.velocity,eta,snapshot.castPoint),p)
                if actual<=radius^2 and predicted<=radius^2 then
                    captured=captured+1
                    enemySlack=math.min(enemySlack,radius-math.sqrt(math.max(actual,predicted)))
                    if caught then caught[#caught+1]=enemy end
                elseif enemy.required or (automatic and enemy.unit==options.anchor) then
                    if collectStats then rejects.enemy=rejects.enemy+1 end;return
                end
            end
            if automatic and captured<options.minimum then if collectStats then rejects.enemy=rejects.enemy+1 end;return end
        end
        local edge=0
        if preferEdge then
            local inset=math.min(radius/2,preferredInset)
            for _,e in ipairs(caught) do
                local outward=math.sqrt(distance2(e.pos,p))
                local score=0
                for _,a in ipairs(allies) do
                    local d=math.sqrt(distance2(a.pos,e.pos))
                    if a.melee and d>1 and d<=1200 and outward>1
                        and distance2(a.pos,p)>(radius+a.padding)^2 then
                        local alignment=((e.pos.x-x)*(a.pos.x-e.pos.x)+(e.pos.y-y)*(a.pos.y-e.pos.y))/(outward*d)
                        local closeness=math.max(0,1-math.abs((radius-outward)-inset)/math.max(32,radius/2))
                        score=math.max(score,math.max(0,alignment)*closeness)
                    end
                end
                edge=edge+score
            end
        end
        local r={x=x,y=y,count=count,source=source,turn=turn,movement=movement,
            eta=eta,extra=extra,verified=verified,violation=math.max(0,extra-budget),
            captured=captured,edge=edge,route=route,roles=caughtRoles,
            safety=math.min(enemySlack,allySlack),enemySlack=enemySlack,allySlack=allySlack,
            shift=math.sqrt(distance2(p,original))}
        Placement.prepare(r,evaluated)
        seen[key]=r
        if not verified then rejects.unknown=rejects.unknown+1 end
        if not automatic and count>=baseline then if collectStats then rejects.gain=rejects.gain+1 end end
        if verified and r.violation>1e-9 then if collectStats then rejects.time=rejects.time+1 end end
        if verified and r.violation<=1e-9 and (automatic or count<=baseline) and better(r,best) then best=r end
        if not refining then remember(r) end
        return r
    end

    local circles={}
    local function circle(pos,r,kind)
        circles[#circles+1]={x=pos.x,y=pos.y,r=r,kind=kind,angles={}}
    end
    for _,e in ipairs(enemies) do
        circle(e.pos,radius,"enemy")
        if predicting and e.velocity then
            circle(Motion.project(e.pos,e.velocity,Motion.horizon,snapshot.castPoint),radius,"predicted_enemy")
        end
    end

    for _,a in ipairs(allies) do circle(a.pos,radius+a.padding+0.1,"ally") end
    if preferEdge then
        for _,e in ipairs(enemies) do circle(e.pos,math.max(1,radius-preferredInset),"melee_edge") end
    end
    circle(origin,searchRange,"budget")
    if searchRange>range+1e-7 then circle(origin,range,"range") end
    local function surface(c,x,y,source)
        local dx,dy=x-c.x,y-c.y
        local d=math.sqrt(dx*dx+dy*dy)
        if d<1e-8 then return end
        c.angles[#c.angles+1]=math.atan(dy,dx)%TAU
        evaluate(x,y,source)
        for _,delta in ipairs(RADIAL_OFFSETS) do
            evaluate(x+dx/d*delta,y+dy/d*delta,source .. "_interior")
        end
    end
    local originalResult=evaluate(original.x,original.y,"original_center")
    evaluate(origin.x,origin.y,"void_center")
    if preferEdge then
        for _,e in ipairs(enemies) do
            for _,a in ipairs(allies) do
                local d=math.sqrt(distance2(e.pos,a.pos))
                if a.melee and d>1 and d<=1200 then
                    local r=math.max(1,radius-preferredInset)
                    evaluate(e.pos.x+(e.pos.x-a.pos.x)/d*r,e.pos.y+(e.pos.y-a.pos.y)/d*r,"ally_facing_edge")
                end
            end
        end
    end
    local projectionTargets={origin,original}
    for _,c in ipairs(circles) do
        if capped then break end
        evaluate(c.x,c.y,"center_" .. c.kind)
        for _,target in ipairs(projectionTargets) do
            local dx,dy=target.x-c.x,target.y-c.y
            local d=math.sqrt(dx*dx+dy*dy)
            if d>1e-8 then
                for _,sign in ipairs(SIGNS) do
                    surface(c,c.x+sign*dx/d*c.r,c.y+sign*dy/d*c.r,"projection_" .. c.kind)
                end
            end
        end
    end
    for i=1,#circles do
        if capped then break end
        for j=i+1,#circles do
            if capped then break end
            local a,b=circles[i],circles[j]
            for _,p in ipairs(intersections(a,b)) do
                local source="intersection_" .. a.kind .. "_" .. b.kind
                surface(a,p.x,p.y,source)
                surface(b,p.x,p.y,source)
            end
        end
    end
    for _,c in ipairs(circles) do
        if capped then break end
        local angles=c.angles
        if #angles==0 then angles=CARDINAL_ANGLES end
        table.sort(angles)

        for i=1,#angles do
            local nextAngle=i==#angles and angles[1]+TAU or angles[i+1]
            if nextAngle-angles[i]>1e-8 then
                local mid=(angles[i]+nextAngle)/2

                local x,y=c.x+c.r*math.cos(mid),c.y+c.r*math.sin(mid)
                evaluate(x,y,"arc_" .. c.kind)
                for _,delta in ipairs(RADIAL_OFFSETS) do
                    evaluate(c.x+(c.r+delta)*math.cos(mid),c.y+(c.r+delta)*math.sin(mid),"arc_interior_" .. c.kind)
                end
            end
            if capped then break end
        end
    end

    if best then
        local found=false
        for _,s in ipairs(seeds) do if s==best then found=true;break end end
        if not found then table.insert(seeds,1,best) end
    end
    local temporalAnchor=best
    if temporalAnchor then
        for _,s in ipairs(temporalSeeds) do
            if capped then break end
            if s.violation>0 then
                local inside,outside=temporalAnchor,s
                local visited={}
                while distance2(inside,outside)>PRECISION^2 and not capped do
                    local separation=distance2(inside,outside)
                    if not visitRefinement(visited,inside,separation) then break end
                    local r=evaluate((inside.x+outside.x)/2,(inside.y+outside.y)/2,"time_boundary",true)
                    if not r or not r.verified then break end
                    if r.violation>0 then outside=r else inside=r end
                end
            end
        end
    end
    for _,seed in ipairs(seeds) do
        if capped then break end
        local current,step=seed,math.max(PRECISION,math.min(radius,searchRange)/4)
        local visited={}
        while not capped do
            if not visitRefinement(visited,current,step) then break end
            local nextBest=current
            for _,offset in ipairs(REFINEMENT_OFFSETS) do
                local r=evaluate(current.x+offset.x*step,current.y+offset.y*step,"refinement_2d_from_" .. seed.source,true)
                if r and r.verified and better(r,nextBest) then nextBest=r end
            end
            if nextBest~=current then current=nextBest
            elseif step>PRECISION then step=math.max(PRECISION,step/2)
            else break end
        end
    end
    if best and not automatic and not rescue and best.captured<=originalEnemies and best.count==baseline
        and compareRoles(best.roles,baselineRoles)>=0 and not (predicting and not originalResult)
        and (not preferEdge or best.edge<=(originalResult and originalResult.edge or 0)+0.01) then best=nil end
    log(function() return string.format("2D search: evaluations=%d limit=%d precision=%.1f out_of_range=%d loses_enemy=%d new_ally=%d no_improvement=%d over_budget=%d unknown_time=%d",
        evaluated,MAX_EVALUATIONS,PRECISION,rejects.range,rejects.enemy,rejects.ally,rejects.gain,rejects.time,rejects.unknown) end)
    log(function() return string.format("2D geometry: intersections=%d projections=%d arcs=%d refinements=%d time_boundaries=%d",
        sources.intersection or 0,sources.projection or 0,sources.arc or 0,sources.refinement or 0,sources.time or 0) end)
    if capped then log(function() return "2D search limit reached: 4096 evaluations; partial, non-exhaustive result" end) end
    if best then
        log(function() return string.format("Improvement: allies %d -> %d saved=%d candidate_source=%s dx=%.2f dy=%.2f center_shift=%.2f",
            baseline,best.count,baseline-best.count,best.source,best.x-original.x,best.y-original.y,best.shift) end)
        log(function() return string.format("Chosen clearance: ally_outside=%.2f enemy_inside=%.2f minimum=%.2f",
            best.allySlack,best.enemySlack,best.safety) end)
        if collectStats then
            local originalScreen=screenPoint(original)
            local adjustedScreen=screenPoint({x=best.x,y=best.y,z=original.z})
            if originalScreen and adjustedScreen then
                log(function() return string.format("Screen displacement: dx_px=%.2f dy_px=%.2f (previous dx/dy are world coordinates)",
                    adjustedScreen.x-originalScreen.x,adjustedScreen.y-originalScreen.y) end)
            else log(function() return "Screen displacement: projection unavailable; previous dx/dy are world coordinates" end) end
        end
        log(function() return "Chosen turn: original=" .. tostring(originalTurn) .. " adjusted=" .. tostring(best.turn) end)
        log(function() return "Chosen allies caught: " .. roleCountsText(best.roles) end)
        log(function() return string.format("Placement: enemies=%d allies=%d melee_access=%.3f",best.captured,best.count,best.edge) end)
        if options.emergency then
            log(function() return string.format("Chosen deadline fallback timing: movement_ms=0 preparation_ms=%.1f; single cast attempt",best.eta*1000) end)
        else
            log(function() return string.format("Chosen timing: movement_ms=%.1f preparation_ms=%.1f additional_ms=%.1f limit_ms=%.1f",
                best.movement*1000,best.eta*1000,best.extra*1000,budget*1000) end)
        end
        local selectedEnemies={}
        for _,enemy in ipairs(enemies) do
            if distance2(enemy.pos,best)<=radius^2
                and distance2(Motion.project(enemy.pos,enemy.velocity,best.eta,snapshot.castPoint),best)<=radius^2 then
                selectedEnemies[#selectedEnemies+1]=enemy
            end
        end
        trace(options.attempt,"placement",function()
            return string.format("mode=%s original_enemies=%d enemies=%d allies=%d movement_ms=%.1f preparation_ms=%.1f center=%s",
                mode,originalEnemies,best.captured,best.count,best.movement*1000,best.eta*1000,describe({x=best.x,y=best.y,z=original.z}))
        end)
        local allowedAllies=options.protection and options.protection.allowedAllies or {}
        if not options.protection then
            for _,a in ipairs(allies) do if a.inside then allowedAllies[a.unit]=true end end
        end
        log(function() return automatic and not options.emergency
            and "Placement criterion order: target priority / allies / selected allies / melee access / clearance / time / shift"
            or "Placement criterion order: target priority / allies / selected allies / no walking / time / melee access / clearance / shift" end)
        return Vector(best.x,best.y,original.z),nil,{eta=best.eta,baseline=prepBaseline,budget=budget,route=best.route,
            attempt=options.attempt,guard={automatic=automatic,prediction=predicting,emergency=options.emergency,required=selectedEnemies,allowedAllies=allowedAllies,
                original=copyPoint(original),radius=radius,team=team,anchor=options.anchor,
                minimum=options.minimum,search=options.search,count=best.count,roles=best.roles,
                roleOrder=roleOrder,allyIDs=allyIDs,originalTurn=originalTurn}}
    end
    if not timingAPI and rejects.unknown>0 then
        return nil,"no safe improvement; turn timing API unavailable for 2D candidates"
    end
    return nil,"no safe 2D improvement preserving enemies, allies and budget; see 2D search rejections"
end

local function deadlineCasterReady(hero,ab)
    if optional(Heroes,"GetLocal")~=hero or optional(Entity,"IsAlive",hero)~=true
        or optional(NPC,"IsChannellingAbility",hero)~=false then return false end
    if optional(Ability,"GetName",ab)~="faceless_void_chronosphere"
        or optional(Ability,"GetOwner",ab)~=hero or optional(Ability,"IsInAbilityPhase",ab)~=false
        or optional(Ability,"IsReady",ab)~=true or optional(NPC,"IsSilenced",hero)~=false then return false end
    local states=Enum.ModifierState or {}
    for _,name in ipairs({"MODIFIER_STATE_STUNNED","MODIFIER_STATE_HEXED","MODIFIER_STATE_OUT_OF_GAME"}) do
        if states[name] and optional(NPC,"HasState",hero,states[name])~=false then return false end
    end
    local mana=optional(NPC,"GetMana",hero)
    if not finite(mana) or optional(Ability,"IsCastable",ab,mana)~=true then return false end
    return true
end

local function validatePlacement(hero,ab,pos,plan,positioning)
    local g=plan.guard
    if not g then return false,"missing placement snapshot" end
    if not finite(optional(GameRules,"GetGameTime")) then return false,"unknown preparation clock" end
    if not Native.member(hero,"IsHero") or not Native.member(ab,"IsAbility")
        or optional(Ability,"GetName",ab)~="faceless_void_chronosphere"
        or optional(Ability,"GetOwner",ab)~=hero or optional(Entity,"GetTeamNum",hero)~=g.team
        or optional(Entity,"IsAlive",hero)~=true or optional(Ability,"IsInAbilityPhase",ab)~=false
        or optional(Ability,"IsReady",ab)~=true or not point(pos) then return false,"caster changed or unavailable" end
    local radius=abilityValue(ab,"radius")
    if not finite(radius) or radius<=0 then return false,"unknown radius" end
    if radius~=g.radius then return false,"radius changed during search" end
    observeAegis(hero)
    local castPoint
    if g.prediction then
        Motion.observe(hero)
        castPoint=optional(Ability,"GetCastPoint",ab,true)
    end
    local function predicted(unit,at)
        return Motion.project(at,Motion.velocity(unit,at,Motion.time),plan.eta,castPoint)
    end
    for _,e in ipairs(g.required) do
        if not g.automatic or e.unit==g.anchor then
            local at
            if e.future then
                local record=aegisTracking.records[e.unit]
                if record and record.state=="pending" then at=record.position end
            end
            if not at then
                if optional(Entity,"IsAlive",e.unit)~=true or optional(NPC,"IsVisible",e.unit)~=true
                    or optional(Entity,"IsDormant",e.unit)~=false then return false,"required target unknown or unavailable" end
                at=copyPoint(optional(Entity,"GetAbsOrigin",e.unit))
            end
            if not point(at) or distance2(at,pos)>radius^2 then return false,"required target outside final center" end
            if g.prediction and not e.future and distance2(predicted(e.unit,at),pos)>radius^2 then
                return false,"required target predicted outside final center"
            end
        end
    end
    local units=optional(Heroes,"GetAll")
    if type(units)~="table" then return false,"unknown hero roster" end
    local caught,roles,captured=0,{},0
    for _,unit in ipairs(units) do
        if unit~=hero then
            local team=optional(Entity,"GetTeamNum",unit)
            if team==nil then return false,"invalid roster entity" end
            local alive=optional(Entity,"IsAlive",unit)
            local illusion=optional(NPC,"IsIllusion",unit)
            if alive==nil or illusion==nil then return false,"unknown hero state" end
            if alive and not illusion then
                local dormant=optional(Entity,"IsDormant",unit)
                local visible=team==g.team or optional(NPC,"IsVisible",unit)==true
                if team==g.team and dormant~=false then return false,"unknown ally position" end
                if dormant==false and visible then
                    local at=copyPoint(optional(Entity,"GetAbsOrigin",unit))
                    if not point(at) then return false,"unknown current position" end
                    if team==g.team then
                        local hull=optional(NPC,"GetHullRadius",unit)
                        local padding=finite(hull) and math.max(8,hull+4) or 8
                        if distance2(at,pos)<=(radius+padding)^2 then
                            if (not g.automatic or g.emergency) and not g.allowedAllies[unit] then return false,"new ally in final center" end
                            caught=caught+1
                            local id=g.allyIDs[unit] or tostring(unit)
                            roles[id]=(roles[id] or 0)+1
                        end
                    elseif g.automatic then
                        if distance2(at,g.original)<=g.search^2 and distance2(at,pos)<=radius^2
                            and (not g.prediction or distance2(predicted(unit,at),pos)<=radius^2) then captured=captured+1 end
                    elseif distance2(at,g.original)<=radius^2 and distance2(at,pos)>radius^2 then
                        return false,"new original enemy outside corrected center"
                    end
                end
            end
        end
    end
    if not g.automatic then
        for _,record in ipairs(pendingReturnsInside(hero,g.original,radius)) do
            if distance2(record.pos,pos)>radius^2 then return false,"new Aegis return outside final center" end
        end
    end
    if caught>g.count or (caught==g.count and Placement.compareRoles(roles,g.roles,g.roleOrder)>0) then
        return false,"ally protection became worse"
    end
    if g.automatic and captured<g.minimum then return false,"minimum enemies no longer met" end
    local origin=copyPoint(optional(Entity,"GetAbsOrigin",hero))
    local range,bonus=optional(Ability,"GetCastRange",ab),optional(NPC,"GetCastRangeBonus",hero)
    if not point(origin) or not finite(range) or not finite(bonus) or range+bonus<=0 then return false,"unknown current range" end
    range=range+bonus
    local dist=math.sqrt(distance2(origin,pos))
    if g.automatic then
        if g.emergency and dist>range then return false,"deadline fallback would require movement" end
        if not positioning and dist>range+1e-5 then return false,"final combo center outside range" end
    else
        local movement=0
        if dist>range then
            local speed=optional(NPC,"GetMoveSpeed",hero)
            if not finite(speed) or speed<=0 then return false,"unknown movement time" end
            movement=(dist-range)/speed
        end
        local turn=optional(NPC,"GetTimeToFacePosition",hero,Vector(pos.x,pos.y,pos.z))
        if not finite(turn) or turn<0 then
            local ox,oy=g.original.x-origin.x,g.original.y-origin.y
            local px,py=pos.x-origin.x,pos.y-origin.y
            local length=math.sqrt(ox*ox+oy*oy)
            if g.originalTurn~=nil or length<=1e-8 or dist<=1e-8 or ox*px+oy*py<=0
                or math.abs(ox*py-oy*px)>length*dist*1e-10 then return false,"unknown final turn time" end
            turn=0
        end
        if movement+turn>plan.baseline+math.min(plan.budget,budgetSeconds())+1e-9 then return false,"final preparation exceeds budget" end
    end
    if g.emergency and not deadlineCasterReady(hero,ab) then return false,"deadline caster no longer ready" end
    return true
end

local function correction(hero,ab,original,options)
    options=options or {}
    options.attempt=options.attempt or nextAttempt()
    trace(options.attempt,"search",function() return options.combo and "combo" or "helper" end)
    if not Native.member(hero,"IsHero") or not Native.member(ab,"IsAbility") then return nil,"invalid caster or ability" end
    if not options.combo then observeAegis(hero) end
    local snapshot=options.snapshot or analysisSnapshot(hero,ab)
    options.snapshot=snapshot
    local function solve(settings)
        settings=settings or options
        settings.snapshot=snapshot
        local pos,reason,plan=solveCorrection(hero,ab,original,settings)
        return pos,reason,plan,snapshot
    end
    if options.combo then return solve() end
    local radius=snapshot and snapshot.radius
    local team=snapshot and snapshot.team
    if not finite(radius) or radius<=0 or not point(original) or team==nil then return solve() end
    local returns=pendingReturnsInside(hero,original,radius)
    if #returns>0 then
        options.returnAnchors=returns
        log(function() return "Helper keeps original Aegis return objectives; empty-area retargeting skipped" end)
        return solve()
    end
    local candidates={}
    for _,state in ipairs(snapshot.units) do
        local unit,at=state.unit,state.pos
        if state.team~=team and state.alive==true and state.illusion==false
            and state.visible==true and state.dormant==false and point(at) then
            local d=distance2(at,original)
            if d<=radius^2 then return solve() end
            candidates[#candidates+1]={unit=unit,distance=d}
        end
    end
    if #candidates==0 then return solve() end
    table.sort(candidates,function(a,b) return a.distance<b.distance end)
    local work={total=0}
    for _,candidate in ipairs(candidates) do
        if work.total>=MAX_EVALUATIONS then break end
        log(function() return string.format("Helper rescue: target=%s edge_distance=%.2f evaluations_used=%d",tostring(candidate.unit),math.sqrt(candidate.distance)-radius,work.total) end)
        local pos,reason,plan=solve({rescueAnchor=candidate.unit,work=work,attempt=options.attempt})
        if pos then
            log(function() return string.format("Helper rescue selected: target=%s preparation_ms=%.1f evaluations_total=%d",tostring(candidate.unit),plan.eta*1000,work.total) end)
            return pos,nil,plan,snapshot
        end
        log(function() return "Helper rescue rejected: " .. tostring(reason) end)
    end
    if work.total>=MAX_EVALUATIONS then log(function() return "Helper rescue evaluation limit reached: 4096; shared across all targets" end) end
    return nil,"no safe Helper rescue within time / ally constraints",nil,snapshot
end
local function stopPendingCast(hero,ab,id)
    id=id or nextAttempt()
    if optional(Ability,"IsInAbilityPhase",ab)~=false then return end
    local at=copyPoint(optional(Entity,"GetAbsOrigin",hero))
    if at and optional(Ability,"GetOwner",ab)==hero then
        trace(id,"stop-pending",function() return describe(at) end)
        if castWatch and castWatch.hero==hero and castWatch.ability==ab then castWatch=nil end
        local ok=Native.dispatch(hero,nil,at,Enum.UnitOrder.DOTA_UNIT_ORDER_STOP or 21,false,id)
        log(function() return "Fail Switch stopped pending approach before cast phase: " .. tostring(ok) end)
    else
        trace(id,"stop-skipped",function() return "unknown caster position or owner" end)
    end
end
local function submit(hero, order, pos, plan)
    local id=plan and plan.attempt or order.attempt or nextAttempt()
    if not Native.member(hero,"IsHero") or not Native.member(order.ability,"IsAbility") then
        trace(id,"dispatch-skipped",function() return "invalid hero / ability" end);return false
    end
    local expectedName=order.abilityName or "faceless_void_chronosphere"
    if optional(Ability,"GetName",order.ability)~=expectedName then
        trace(id,"dispatch-skipped",function() return "ability identity changed" end);return false
    end
    if optional(Ability,"GetName",order.ability)=="faceless_void_chronosphere"
        and optional(Ability,"IsInAbilityPhase",order.ability)~=false then
        log(function() return "Chronosphere dispatch skipped: cast phase started or unknown" end);return false
    end
    if optional(Ability,"GetName",order.ability)=="faceless_void_chronosphere"
        and not failAllows(hero,order.ability,pos) then
        if plan and not plan.guard.automatic then
            trace(id,"placement-rejected",function() return "Fail Switch rejected corrected area; checking original" end)
            return false,not failAllows(hero,order.ability,order.position)
        end
        return false,true
    end
    if plan then

        local valid,reason=validatePlacement(hero,order.ability,pos,plan)
        if not valid then
            trace(id,"placement-rejected",function() return reason end)
            if not plan.guard.automatic then return false,not failAllows(hero,order.ability,order.position) end
            return false
        end
    end
    local sent=Native.dispatch(hero,order.ability,pos,order.order,order.showEffects,id,expectedName)
    if sent then
        if expectedName=="faceless_void_chronosphere" then pcall(armCastWatch,hero,order.ability,pos,id)
        else castWatch=nil end
    end
    log(function() return "Dispatch: destination=" .. describe(pos) .. " call_ok=" .. tostring(sent) end)
    local now=read(GameRules,"GetGameTime")
    if sent and plan and not plan.guard.automatic and plan.budget>0 and plan.eta>0 and finite(now) then
        budgetCast={hero=hero,started=now,baseline=plan.baseline,budget=plan.budget,
            protection={allowedAllies=plan.guard.allowedAllies,count=plan.guard.count,roles=plan.guard.roles},
            order={attempt=id,order=order.order,ability=order.ability,orderIssuer=order.orderIssuer,
                abilityName=expectedName,showEffects=order.showEffects,
                position=Vector(order.position.x,order.position.y,order.position.z)}}
        log(function() return string.format("Preparation watcher: preparation_limit_ms=%.1f",(plan.baseline+plan.budget)*1000) end)
    end
    return sent
end

local function tryDeadlineFallback(b)
    local hero,ab=b.hero,b.order.ability
    if not b.protection or not deadlineCasterReady(hero,ab) then return false end
    local snapshot=analysisSnapshot(hero,ab)
    if not snapshot or not point(snapshot.origin) or not finite(snapshot.range) or not finite(snapshot.bonus)
        or not finite(snapshot.radius) or snapshot.radius<=0 then return false end
    local range=snapshot.range+snapshot.bonus
    if range<=0 then return false end
    local options={combo=true,emergency=true,snapshot=snapshot,attempt=b.order.attempt,
        setup=math.huge,reach=range,minimum=1,protection=b.protection,
        search=math.sqrt(distance2(snapshot.origin,b.order.position))+range+snapshot.radius}
    options.route=function(center)
        if distance2(snapshot.origin,center)>range^2 then return end
        local turn=optional(NPC,"GetTimeToFacePosition",hero,Vector(center.x,center.y,b.order.position.z))
        if not finite(turn) or turn<0 then return end
        return {eta=turn,turn=turn,movement=0,steps={}}
    end
    trace(b.order.attempt,"deadline-fallback",function() return "searching current cast range; minimum=1; no new deadline" end)
    local pos,reason,plan=solveCorrection(hero,ab,b.order.position,options)
    if not pos then
        trace(b.order.attempt,"deadline-fallback-rejected",function() return reason end)
        return false
    end
    local sent=submit(hero,b.order,pos,plan)
    trace(b.order.attempt,"deadline-fallback-result",function() return sent and "cast order submitted; no new watcher" or "live validation or dispatch rejected" end)
    return sent
end

local function checkBudgetCast()
    if not budgetCast then return end
    local b=budgetCast
    local now=read(GameRules,"GetGameTime")
    if not enabled:Get() or not finite(now) or now<b.started
        or read(Heroes,"GetLocal")~=b.hero or read(Entity,"IsAlive",b.hero)~=true then
        budgetCast=nil; return
    end
    local phase=read(Ability,"IsInAbilityPhase",b.order.ability)
    if phase~=false or read(Ability,"IsReady",b.order.ability)~=true then
        budgetCast=nil
        log(function() return "Preparation watcher stopped: cast started or ability unavailable; no restart" end)
        return
    end
    local limit=b.baseline+math.min(b.budget,budgetSeconds())
    if now-b.started > limit then
        budgetCast=nil

        log(function() return string.format("Deadline expired: elapsed_ms=%.1f limit_ms=%.1f; checking immediate fallback",
            (now-b.started)*1000,limit*1000) end)
        if read(Ability,"GetOwner",b.order.ability)==b.hero
            and read(NPC,"IsChannellingAbility",b.hero)==false then
            local ok,sent=pcall(tryDeadlineFallback,b)
            if (ok and sent) or (Recovery.frame and Recovery.frame.emitted) then return end
            if not ok then trace(b.order.attempt,"deadline-fallback-error",function() return tostring(sent) end) end
            trace(b.order.attempt,"restore-original",function() return describe(b.order.position) end)
            local _,blocked=submit(b.hero,b.order,b.order.position)
            if blocked then stopPendingCast(b.hero,b.order.ability,b.order.attempt) end
        end
    end
end

local function approachSignature(hero,ab,original,snapshot)
    snapshot=snapshot or analysisSnapshot(hero,ab)
    if not snapshot or not Native.member(hero,"IsHero") or not Entity or type(Entity.GetRotationPYR)~="function" then return nil,snapshot end
    local ok,pitch,yaw,roll=pcall(Entity.GetRotationPYR,hero)
    if not ok or not finite(pitch) or not finite(yaw) or not finite(roll) then return nil,snapshot end
    local values={tostring(hero),tostring(ab),pitch,yaw,roll,snapshot.mode,table.concat(snapshot.order,"|")}
    local function add(value) values[#values+1]=tostring(value) end
    local function position(at)
        if not point(at) then return false end
        add(at.x);add(at.y);add(at.z);return true
    end
    if not position(original) or not position(snapshot.origin) then return nil,snapshot end
    add(snapshot.radius);add(snapshot.range);add(snapshot.bonus);add(snapshot.speed);add(snapshot.castPoint)
    add(snapshot.budget);add(snapshot.edge);add(snapshot.inset)
    for _,state in ipairs(snapshot.units) do
        local unit=state.unit
        add(unit);add(snapshot.roles[unit]);add(state.team);add(state.alive);add(state.dormant)
        add(state.illusion);add(state.visible);add(state.hull);add(state.ranged)
        add(state.velocity and state.velocity.x);add(state.velocity and state.velocity.y)
        if state.alive==true and not position(state.pos) then return nil,snapshot end
        local record=aegisTracking.records[unit]
        add(record and record.state)
        if record and record.state=="pending" and not position(record.position) then return nil,snapshot end
    end
    for i,value in ipairs(values) do values[i]=tostring(value) end
    return table.concat(values,";"),snapshot
end

local function watchApproach(hero, order,snapshot)
    local now=read(GameRules,"GetGameTime")
    local origin=read(Entity,"GetAbsOrigin",hero)
    local range=read(Ability,"GetCastRange",order.ability)
    local bonus=read(NPC,"GetCastRangeBonus",hero)
    if not finite(now) or not point(origin) or not point(order.position)
        or not finite(range) or not finite(bonus)
        or distance2(origin,order.position) <= (range+bonus)^2 then return end

    if read(Ability,"IsInAbilityPhase",order.ability) ~= false
        or read(Ability,"IsReady",order.ability) ~= true then
        log(function() return "Approach not tracked: ready ability and unstarted cast phase not confirmed" end); return
    end
    pending={hero=hero,started=now,expires=now+6,nextLog=now+0.5,
        signature=approachSignature(hero,order.ability,order.position,snapshot),
        order={order=order.order,ability=order.ability,orderIssuer=order.orderIssuer,
            abilityName="faceless_void_chronosphere",showEffects=order.showEffects,
            position=Vector(order.position.x,order.position.y,order.position.z)}}
    log(function() return "Approach tracking: original order continues; reevaluate before cast phase" end)
end

local function comboReady(hero,ability)
    if read(Entity,"IsAlive",hero)~=true or read(NPC,"IsChannellingAbility",hero)~=false
        or read(Ability,"IsInAbilityPhase",ability)~=false then return false end
    if read(NPC,"IsSilenced",hero)==true then return false end
    local states=Enum.ModifierState
    if states and NPC and type(NPC.HasState)=="function" then
        for _,name in ipairs({"MODIFIER_STATE_STUNNED","MODIFIER_STATE_HEXED","MODIFIER_STATE_OUT_OF_GAME"}) do
            if states[name] and read(NPC,"HasState",hero,states[name])==true then return false end
        end
    end
    if NPC and type(NPC.GetAbilityByIndex)=="function" then
        for i=0,31 do
            local ab=read(NPC,"GetAbilityByIndex",hero,i)
            if ab and read(Ability,"IsInAbilityPhase",ab)==true then return false end
        end
    end
    if NPC and type(NPC.GetItemByIndex)=="function" then
        for i=0,8 do
            local item=read(NPC,"GetItemByIndex",hero,i)
            if item and read(Ability,"IsInAbilityPhase",item)==true then return false end
        end
    end
    return read(Ability,"IsReady",ability)==true
        and read(Ability,"IsCastable",ability,read(NPC,"GetMana",hero))==true
end
local function comboOptions(state)
    local hero,chrono=state.hero,state.ability
    local origin=read(Entity,"GetAbsOrigin",hero)
    local mana=read(NPC,"GetMana",hero)
    local chronoCost=read(Ability,"GetManaCost",chrono)
    local castRange=read(Ability,"GetCastRange",chrono)
    local bonus=read(NPC,"GetCastRangeBonus",hero)
    local now=read(GameRules,"GetGameTime")
    if not finite(now) then return end
    local remaining=math.min(state.deadline,state.started+comboSetup:Get()/1000)-now
    if not point(origin) or not finite(mana) or not finite(chronoCost) or mana<chronoCost
        or not finite(castRange) or not finite(bonus) or remaining<=0 then return end
    castRange=castRange+bonus
    local tools={}
    local function tool(ab,kind)
        if not ab or state.used[ab] or read(Ability,"GetOwner",ab)~=hero
            or read(Ability,"IsReady",ab)~=true
            or read(Ability,"IsCastable",ab,mana)~=true then
            if ab and not state.used[ab] then log(function() return "Combo skipping unavailable positioning: " .. kind end) end
            return
        end
        local states=Enum.ModifierState
        if states and NPC and type(NPC.HasState)=="function" then
            for _,name in ipairs({"MODIFIER_STATE_ROOTED","MODIFIER_STATE_TETHERED"}) do
                if states[name] and read(NPC,"HasState",hero,states[name])==true then return end
            end
            if kind=="Blink" and states.MODIFIER_STATE_MUTED
                and read(NPC,"HasState",hero,states.MODIFIER_STATE_MUTED)==true then return end
        end
        local r=read(Ability,"GetCastRange",ab)
        if kind=="Time Walk" and (not finite(r) or r<=0) then r=abilityValue(ab,"range",true) end
        if kind=="Blink" and (not finite(r) or r<=32) then r=abilityValue(ab,"blink_range",true) end
        local cp=read(Ability,"GetCastPoint",ab,true)
        local cost=read(Ability,"GetManaCost",ab)
        local speed=kind=="Time Walk" and abilityValue(ab,"speed",true) or math.huge
        if not finite(r) or r<=32 or not finite(cp) or cp<0 or not finite(cost)
            or (kind=="Time Walk" and (not finite(speed) or speed<=0)) then return end
        tools[#tools+1]={ability=ab,kind=kind,range=r-(kind=="Blink" and 32 or 16),cp=cp,cost=cost,speed=speed}
    end
    local function blink()
        if not useBlink:Get() then return end
        for _,name in ipairs({"item_blink","item_overwhelming_blink","item_swift_blink","item_arcane_blink"}) do
            local before=#tools
            tool(read(NPC,"GetItem",hero,name,true),"Blink")
            if #tools>before then return end
        end
    end
    local function walk()
        if useTimeWalk:Get() then tool(read(NPC,"GetAbility",hero,"faceless_void_time_walk"),"Time Walk") end
    end

    local order=mobility and mobility:List() or {"Time Walk","Blink"}
    local seen={}
    for _,id in ipairs(order) do
        if not seen[id] then
            seen[id]=true
            if id=="Time Walk" then walk() elseif id=="Blink" then blink() end
        end
    end
    table.sort(tools,function(a,b) return a.kind=="Time Walk" and b.kind=="Blink" end)
    local reach=castRange
    for _,t in ipairs(tools) do reach=reach+t.range end
    local options={combo=true,setup=remaining,reach=reach,search=comboSearch:Get(),
        minimum=comboMinimum:Get(),anchor=state.anchor}
    options.route=function(center)
        local d=math.sqrt(distance2(origin,center))
        local turn=read(NPC,"GetTimeToFacePosition",hero,Vector(center.x,center.y,state.cursor.z))
        if not finite(turn) or turn<0 then return end
        local need=d>castRange and d-castRange+24 or 0
        local steps,cost,eta,covered,travelTime={},chronoCost,turn,0,0
        for _,t in ipairs(tools) do
            if need>0 and cost+t.cost<=mana then
                local reserve=0
                if t.kind=="Time Walk" then
                    for _,last in ipairs(tools) do
                        if last.kind=="Blink" and cost+t.cost+last.cost<=mana then reserve=need<=last.range and need or 32;break end
                    end
                end
                local travel=math.min(math.max(0,need-reserve),t.range)
                if travel>0 then
                covered=covered+travel
                steps[#steps+1]={ability=t.ability,kind=t.kind,
                    pos=Vector(origin.x+(center.x-origin.x)/d*covered,origin.y+(center.y-origin.y)/d*covered,state.cursor.z)}
                need=need-travel;cost=cost+t.cost
                travelTime=travelTime+travel/t.speed
                eta=eta+t.cp+travel/t.speed
                end
            end
        end
        if need>1e-5 or eta>remaining then return end
        return {eta=eta,steps=steps,turn=turn,movement=travelTime}
    end
    return options
end
local function comboOrder(ability,position)
    local issuer=Enum.PlayerOrderIssuer and Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY
    return {order=Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,ability=ability,
        abilityName=optional(Ability,"GetName",ability),
        orderIssuer=issuer or 3,showEffects=true,position=position}
end
local function advanceCombo(state)
    if not comboReady(state.hero,state.ability) then log(function() return "Combo cancelled: caster or Chronosphere is not ready" end);comboState=nil;return end
    local options=comboOptions(state)
    if not options then comboState=nil;log(function() return "Combo cancelled: setup budget or required data unavailable" end);return end

    if read(Entity,"IsAlive",state.anchor)~=true or read(NPC,"IsVisible",state.anchor)~=true
        or read(Entity,"IsDormant",state.anchor)~=false
        or not point(read(Entity,"GetAbsOrigin",state.anchor))
        or distance2(read(Entity,"GetAbsOrigin",state.anchor),state.cursor)>comboSearch:Get()^2 then
        comboState=nil;log(function() return "Combo cancelled: cursor target is no longer visible/alive" end);return
    end
    local ok,pos,reason,plan=pcall(correction,state.hero,state.ability,state.cursor,options)
    if not ok or not pos then comboState=nil;log(function() return "Combo cancelled: " .. tostring(ok and reason or pos) end);return end
    local step=plan.route.steps[1]
    if step then
        local valid,reason=validatePlacement(state.hero,state.ability,pos,plan,true)
        if not valid then
            comboState=nil;trace(plan.attempt,"positioning-rejected",function() return reason end);return
        end
        if not comboReady(state.hero,step.ability) then comboState=nil;log(function() return "Combo cancelled: positioning ability unavailable" end);return end
        state.departure=read(Entity,"GetAbsOrigin",state.hero)
        state.step=step
        if not submit(state.hero,comboOrder(step.ability,step.pos),step.pos) then comboState=nil;return end
        log(function() return "Combo positioning: " .. step.kind .. " -> " .. describe(step.pos) .. "; waiting for actual arrival" end)
    else

        local origin=read(Entity,"GetAbsOrigin",state.hero)
        local range,bonus=read(Ability,"GetCastRange",state.ability),read(NPC,"GetCastRangeBonus",state.hero)
        comboState=nil
        if not point(origin) or not finite(range) or not finite(bonus)
            or distance2(origin,pos)>(range+bonus)^2+1e-5 or not comboReady(state.hero,state.ability) then
            log(function() return "Combo cancelled: final cast is not immediately available" end);return
        end
        local sent=submit(state.hero,comboOrder(state.ability,pos),pos,plan)
        if sent then log(function() return "Combo Chronosphere dispatched after live target revalidation" end) end
    end
end
local function timeWalkInProgress(hero)
    if not Native.member(hero,"IsHero") then return false end
    local walk=read(NPC,"GetAbility",hero,"faceless_void_time_walk")
    return (walk and read(Ability,"IsInAbilityPhase",walk)==true)
        or read(NPC,"HasModifier",hero,"modifier_faceless_void_time_walk")==true
end
function script.OnKeyEvent(data)
    syncBinding()

    if not bindingActive or not data then return true end
    if not Native.member(optional(Heroes,"GetLocal"),"IsHero") then return true end
    if read(Input,"IsInputCaptured")~=false or read(Input,"IsPopupOpen")==true then return true end
    local ok,first,second=pcall(function()
        if type(comboKey.Buttons)=="function" then return comboKey:Buttons() end
        if type(comboKey.Get)=="function" then return comboKey:Get(),0 end
    end)
    if not ok or not finite(first) or first<=0 then return true end
    second=finite(second) and second>0 and second or nil
    if data.key~=first and data.key~=second then return true end
    local events=Enum.EKeyEvent or {}
    if data.event==(events.EKeyEvent_KEY_UP or 3) then rawDown[data.key]=nil;return true end
    if data.event~=(events.EKeyEvent_KEY_DOWN or 2) then return true end
    rawSeen=true
    if rawDown[data.key] then return true end
    rawDown[data.key]=true
    local other=second and (data.key==first and second or first)
    if other and not rawDown[other] and read(Input,"IsKeyDown",other)~=true then return true end
    local now=read(GameRules,"GetGameTime")
    local cursor=read(Input,"GetWorldCursorPos")
    if finite(now) and point(cursor) then
        queuedPress={time=now,cursor=Vector(cursor.x,cursor.y,cursor.z)}
        log(function() return "Combo key event buffered: time_walk=" .. tostring(timeWalkInProgress(read(Heroes,"GetLocal"))) end)
    end
    return true
end
local function updateCombo()
    syncBinding()
    if not bindingActive then comboState=nil;queuedPress=nil;return end
    local request=queuedPress;queuedPress=nil
    local pressed=request~=nil or (not rawSeen and comboKey:IsPressed())
    if not pressed and not comboState then return end
    if read(Input,"IsInputCaptured")~=false or read(Input,"IsPopupOpen")==true then comboState=nil;return end
    local hero=read(Heroes,"GetLocal")
    local now=read(GameRules,"GetGameTime")
    if not hero or not finite(now) then comboState=nil;return end
    if pressed then
        if comboState then comboState=nil;log(function() return "Combo cancelled by second key press" end);return end
        local chrono=read(NPC,"GetAbility",hero,"faceless_void_chronosphere")
        local cursor=request and request.cursor or read(Input,"GetWorldCursorPos")
        local approaching=timeWalkInProgress(hero)
        if not chrono or not point(cursor) or read(Ability,"GetOwner",chrono)~=hero
            then
            log(function() return "Combo not started: Chronosphere or caster unavailable" end);return
        end
        local started=request and request.time or now
        if now-started>comboSetup:Get()/1000 then log(function() return "Combo buffered key expired" end);return end
        local ready=not approaching and comboReady(hero,chrono)
        log(function() return "Combo key captured: time_walk=" .. tostring(approaching) .. "; ready=" .. tostring(ready) end)
        local team=read(Entity,"GetTeamNum",hero)
        local anchor,closest=nil,comboSearch:Get()^2
        for _,u in ipairs(read(Heroes,"GetAll") or {}) do
            local pos=read(Entity,"GetAbsOrigin",u)
            if read(Entity,"GetTeamNum",u)~=team and read(Entity,"IsAlive",u)==true
                and read(Entity,"IsDormant",u)==false and read(NPC,"IsVisible",u)==true
                and read(NPC,"IsIllusion",u)==false and point(pos) then
                local d=distance2(pos,cursor)
                if d<=closest then anchor,closest=u,d end
            end
        end
        if not anchor then log(function() return "Combo: no visible enemy near cursor" end);return end
        pending=nil;budgetCast=nil
        comboState={hero=hero,ability=chrono,cursor=Vector(cursor.x,cursor.y,cursor.z),anchor=anchor,
            started=started,deadline=started+comboSetup:Get()/1000,used={},waitingInitial=not ready}
        if not ready then
            log(function() return "Combo activation buffered: waiting for Time Walk / caster readiness within setup deadline" end)
        else advanceCombo(comboState) end
        return
    end
    local state=comboState
    if hero~=state.hero or now<state.started or now>math.min(state.deadline,state.started+comboSetup:Get()/1000)
        or read(Entity,"IsAlive",hero)~=true or read(Ability,"GetOwner",state.ability)~=hero then
        comboState=nil;log(function() return "Combo cancelled: context changed or setup deadline exceeded" end);return
    end
    if read(Ability,"IsInAbilityPhase",state.ability)~=false then comboState=nil;return end
    if state.waitingInitial then
        if timeWalkInProgress(hero) then return end

        if not comboReady(hero,state.ability) then return end
        state.waitingInitial=nil
        log(function() return "Combo current Time Walk finished; recomputing from actual position" end)
        advanceCombo(state)
        return
    end
    local step=state.step
    if not step then comboState=nil;return end
    if (step.kind=="Blink" and not useBlink:Get()) or (step.kind=="Time Walk" and not useTimeWalk:Get()) then comboState=nil;return end
    if read(Ability,"IsInAbilityPhase",step.ability)==true
        or (step.kind=="Time Walk" and read(NPC,"HasModifier",hero,"modifier_faceless_void_time_walk")==true) then return end
    local origin=read(Entity,"GetAbsOrigin",hero)
    if not point(origin) then comboState=nil;return end
    local travel=math.sqrt(distance2(state.departure,step.pos))
    if distance2(origin,step.pos)<=64^2 and distance2(origin,state.departure)>=math.min(16,travel*0.5)^2 then
        state.used[step.ability]=true;state.step=nil
        log(function() return "Combo arrival confirmed: " .. step.kind end)
        advanceCombo(state)
    end
end

function script.OnPrepareUnitOrders(order)
    if not callbackSeen then log(function() return "Callback received: OnPrepareUnitOrders" end); callbackSeen=true end
    if not master:Get() then return true end
    if sending or not order or order.identifier=="ChronosphereHelper_v1" then return true end
    local hero = read(Heroes, "GetLocal")
    if castWatch and order.npc==hero then castWatch=nil end
    if pending and order.npc == hero and not order.queue then
        pending=nil
        log(function() return "Approach tracking cancelled: new player order" end)
    end
    if budgetCast and order.npc==hero and not order.queue then
        budgetCast=nil; log(function() return "Preparation watcher cancelled: new player order" end)
    end
    if comboState and order.npc==hero and not order.queue then
        comboState=nil;log(function() return "Combo cancelled: new player order" end)
    end
    local name = order.ability and read(Ability, "GetName", order.ability)
    if name ~= "faceless_void_chronosphere" then
        if name and hero and order.npc == hero then
            log(function() return "Other ability: " .. tostring(name) .. " order=" .. tostring(order.order) end)
        end
        return true
    end
    log(function() return "Chronosphere received: order=" .. tostring(order.order) .. " expected_order="
        .. tostring(Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION) .. " npc=" .. tostring(order.npc)
        .. " local=" .. tostring(hero) .. " queued=" .. tostring(order.queue)
        .. " issuer=" .. tostring(order.orderIssuer) .. " destination=" .. describe(order.position) end)
        if order.queue then log(function() return "Original: queued order" end); return true end
    if order.order ~= Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION then log(function() return "Original: different order type" end); return true end
    local owner = read(Ability, "GetOwner", order.ability)
    if not hero or order.npc ~= hero or owner ~= hero then
        log(function() return "Original: caster mismatch; owner=" .. tostring(owner) end); return true
    end
    if optional(Ability,"IsInAbilityPhase",order.ability)~=false then return true end
    if not enabled:Get() then return allowManualCast(hero,order) end
    local ok, pos, reason, plan, snapshot = pcall(correction, hero, order.ability, order.position)
    if not ok then log(function() return "Calculation error: " .. tostring(pos) end); return allowManualCast(hero,order) end
    if not pos then
        log(function() return "Original: " .. tostring(reason) end)
        if not allowManualCast(hero,order) then return false end
        watchApproach(hero,order,snapshot)
        return true
    end

    local sent,blocked=submit(hero,order,pos,plan)
    if blocked then return false end
    if not sent then return allowManualCast(hero,order) end
    return false
end

local context={hero=nil,time=nil}
local function resetRuntime()
    pending=nil;budgetCast=nil;comboState=nil;queuedPress=nil;castWatch=nil
    rawSeen=false;rawDown={};sending=false;quiet=false
    resetAegis();Motion.reset()
    allyUI.owner=nil;allyUI.lastRefresh=-math.huge;allyUI.signature=nil
    context={hero=nil,time=nil}
end

function script.OnUpdate()
    syncBinding()
    if not master:Get() then
        if not context.disabled then resetRuntime();context.disabled=true end
        return
    end
    context.disabled=nil
    local localHero=optional(Heroes,"GetLocal")
    local time=optional(GameRules,"GetGameTime")
    if not Native.member(localHero,"IsHero") or not finite(time) then resetRuntime();return end
    if (context.hero and context.hero~=localHero) or (context.time and time<context.time) then
        resetRuntime()
        log(function() return "Runtime reset: local hero changed or clock rolled back" end)
    end
    context.hero=localHero;context.time=time
    if not Diagnostics.enabled() then
        diagnosticWas=false; announced=false; callbackSeen=false
    elseif not announced then
        log(function() return "Script active; helper_enabled=" .. tostring(enabled:Get()) .. "; waiting for Chronosphere order" end)
        announced=true
    end
    if enabled:Get() or failEnabled:Get() then observeAegis(optional(Heroes,"GetLocal")) else resetAegis() end
    if enabled:Get() or comboEnabled:Get() then Motion.observe(localHero) else Motion.reset() end
    if checkCastWatch() then return end
    updateCombo()
    local rosterHero=read(Heroes,"GetLocal")
    local rosterTime=read(GameRules,"GetGameTime")
    if rosterHero and finite(rosterTime) and (allyUI.owner~=rosterHero or rosterTime<allyUI.lastRefresh or rosterTime-allyUI.lastRefresh>=0.5) then
        prioritySnapshot(read(Entity,"GetTeamNum",rosterHero),rosterHero)
    end
    checkBudgetCast()
    if not pending then return end
    local p=pending
    local now=read(GameRules,"GetGameTime")
    local function stop(reason)
        pending=nil; log(function() return "Approach tracking stopped: " .. reason end)
    end
    if not enabled:Get() or not finite(now) or now < p.started or now > p.expires
        or read(Heroes,"GetLocal") ~= p.hero or read(Entity,"IsAlive",p.hero) ~= true then
        stop("context changed, disabled or expired"); return
    end

    if read(Ability,"IsInAbilityPhase",p.order.ability) ~= false then
        stop("cast started or phase unknown; no interruption"); return
    end
    if read(Ability,"GetOwner",p.order.ability) ~= p.hero
        or read(Ability,"GetName",p.order.ability) ~= "faceless_void_chronosphere"
        or read(Ability,"IsReady",p.order.ability) ~= true
        or read(NPC,"IsChannellingAbility",p.hero) ~= false then
        stop("ability unavailable or channeling"); return
    end
    local moving=read(NPC,"IsRunning",p.hero) == true
        or read(NPC,"HasModifier",p.hero,"modifier_faceless_void_time_walk") == true
    if not moving then
        if now-p.started > 0.15 then stop("approach no longer active") end
        return
    end
    local signature,snapshot=approachSignature(p.hero,p.order.ability,p.order.position)
    if signature and signature==p.signature then return end
    p.signature=signature

    quiet=now < p.nextLog
    local ok,pos,reason,plan=pcall(correction,p.hero,p.order.ability,p.order.position,{snapshot=snapshot})
    quiet=false
    if now >= p.nextLog then
        p.nextLog=now+0.5
        log(function() return "Approach tracking: " .. (ok and tostring(reason or "improvement available") or tostring(pos)) end)
    end
    if not ok then stop("calculation error: " .. tostring(pos)); return end
    if not pos then return end
    pending=nil

    if read(Ability,"IsInAbilityPhase",p.order.ability) ~= false then
        log(function() return "Approach tracking stopped: cast started; no interruption" end); return
    end
    log(function() return "Approach correction: placement improved before cast phase within the configured budget" end)
    local _,blocked=submit(p.hero,p.order,pos,plan)
    if blocked then stopPendingCast(p.hero,p.order.ability,plan.attempt) end
end

function script.OnGameEnd()
    resetRuntime()
    log(function() return "Runtime reset: game ended" end)
end

for _,name in ipairs({"OnUpdate","OnPrepareUnitOrders","OnKeyEvent","OnGameEnd"}) do
    local callback=script[name]
    script[name]=function(...)
        local parent=Recovery.frame
        local frame={emitted=false,sendingBefore=sending}
        Recovery.frame=frame
        local ok,result=pcall(callback,...)
        Recovery.frame=parent
        sending=frame.sendingBefore
        if ok then return result end
        resetRuntime()

        sending=frame.sendingBefore
        trace(nextAttempt(),"callback-error",function() return name .. ": " .. tostring(result) end)
        if name=="OnPrepareUnitOrders" then return not frame.emitted end
        if name=="OnKeyEvent" then return true end
    end
end

log(function() return "Script loaded; diagnostics v1" end)
return script
