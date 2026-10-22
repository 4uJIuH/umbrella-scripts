-- muerta_anti_techies 1.0, Umbrella API v2.
-- Muerta Dead Shot -> tree -> Techies during Blast Off windup or flight.
-- Requires timely replicated cast / movement data and a feasible ricochet path.
-- No file logging or diagnostic menu. Enable from Scripts / Other / muerta_anti_techies.
local script = {}
local group = Menu.Create("Scripts", "Other", "muerta_anti_techies"):Create("Защита"):Create("Blast Off")
local enabled = group:Switch("Включить", false)
local LEAP = "modifier_techies_suicide_leap"
local FEAR = "modifier_muerta_dead_shot_fear"
local state = {jumps={}, phaseHistory={}, animations={}, errors={}, nextShot=0}

local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end
local function now() return read(GameRules.GetGameTime) or 0 end
local function valid(e) return e ~= nil and (not Entities or read(Entities.Contains,e)==true) end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<1e9 end
local function pos(e)
    local p = read(Entity.GetAbsOrigin,e)
    if p and finite(p.x) and finite(p.y) then return {x=p.x,y=p.y,z=p.z or 0} end
end
local function targetPos(e)
    -- Prefer network position to rendered/interpolated position when the API supplies it.
    local p=read(Entity.GetNetOrigin,e)
    if p and finite(p.x) and finite(p.y) then return {x=p.x,y=p.y,z=p.z or 0},"net" end
    return pos(e),"abs"
end
local function vec(p) return Vector(p.x,p.y,p.z or 0) end
local function dist(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
local function has(e,key)
    local flag = Enum.ModifierState and Enum.ModifierState["MODIFIER_STATE_"..key]
    return flag ~= nil and read(NPC.HasState,e,flag)==true
end
local function reason(j,key)
    if not j.attempted then j.reason=key end
end
local function protect(name, fn)
    return function(...)
        local ok,err=pcall(fn,...)
        if ok then return err end
        if not ok and not state.errors[name] then
            state.errors[name]=true
            if Log then read(Log.Write,"[muerta_anti_techies] ERROR "..name..": "..tostring(err)) end
        end
        if name=="OnPrepareUnitOrders" then return true end
    end
end
local function reset()
    state={jumps={},phaseHistory={},animations={},errors={},nextShot=0}
end
enabled:SetCallback(function() reset() end)

local function enemy(e)
    return valid(e) and read(NPC.GetUnitName,e)=="npc_dota_hero_techies"
        and read(Entity.GetTeamNum,e)~=read(Entity.GetTeamNum,state.hero)
        and read(NPC.IsIllusion,e)==false and read(Entity.IsAlive,e)==true
end
local function visible(e)
    return read(Entity.IsDormant,e)==false and read(NPC.IsVisible,e)==true
end
local function available(e)
    -- Invisibility alone is not a reason to ignore a replicated leap.
    -- Flight sampling needs live coordinates. Windup has a separate fresh-signal gate.
    return read(Entity.IsDormant,e)==false
end
local function special(a,name,fallback)
    local value=read(Ability.GetLevelSpecialValueFor,a,name)
    if not finite(value) or value<=0 then value=read(Ability.GetSpecialValueFor,a,name) end
    if finite(value) and value>0 then return value end
    return fallback
end
local function lag()
    if not NetChannel or not Enum.Flow then return 0.10 end
    local incoming=read(NetChannel.GetLatency,Enum.Flow.FLOW_INCOMING)
    local outgoing=read(NetChannel.GetLatency,Enum.Flow.FLOW_OUTGOING)
    if not finite(incoming) or not finite(outgoing) then return 0.10 end
    return math.max(0,incoming)+math.max(0,outgoing)
end

-- Solve |P + V*(delay + flight) - tree| = projectile_speed*flight + radius in XY.
-- 'delay' includes turning, cast point, latency and the initial shot to the tree.
local function intercept(p,v,tree,speed,delay,radius)
    radius=radius or 0
    local x,y=p.x+v.x*delay-tree.x,p.y+v.y*delay-tree.y
    local a=v.x*v.x+v.y*v.y-speed*speed
    local b=2*(x*v.x+y*v.y-speed*radius)
    local c=x*x+y*y-radius*radius
    local flight
    if c<=0 then
        return delay,{x=p.x+v.x*delay,y=p.y+v.y*delay,z=tree.z},0
    end
    if math.abs(a)<0.0001 then
        if math.abs(b)<0.0001 then return nil end
        flight=-c/b
    else
        local d=b*b-4*a*c
        if d<0 then return nil end
        local s=math.sqrt(d)
        local t1,t2=(-b-s)/(2*a),(-b+s)/(2*a)
        if t1>0 then flight=t1 end
        if t2>0 and (not flight or t2<flight) then flight=t2 end
    end
    if not finite(flight) or flight<=0 then return nil end
    return delay+flight,{x=p.x+v.x*(delay+flight),y=p.y+v.y*(delay+flight),z=tree.z},flight
end

local function register(unit,mod)
    if not enemy(unit) or not available(unit) then return end
    local id=read(Entity.GetIndex,unit)
    local p,positionSource=targetPos(unit)
    if not id or not p then return end
    local t=now()
    local created=read(Modifier.GetCreationTime,mod)
    -- Do not invent a fresh full jump if the modifier was already running in fog.
    if not finite(created) or created>t+0.1 then
        ;return
    end
    local old=state.jumps[id]
    if old and old.mode~="windup" and old.unit==unit and math.abs(old.created-created)<0.01 then return old end
    local blast=read(NPC.GetAbility,unit,"techies_suicide")
    local duration=special(blast,"duration",0.75)
    local modDuration=read(Modifier.GetDuration,mod)
    if finite(modDuration) and modDuration>0 and modDuration<2 then duration=math.min(duration,modDuration) end
    local finish=created+duration
    local die=read(Modifier.GetDieTime,mod)
    if finite(die) and die>created and die-created<2 then finish=math.min(finish,die) end
    local jump={unit=unit,id=id,created=created,finish=finish,sample=p,sampleAt=t,mode="flight",
        first=p,reason="sampling_velocity",attempted=false,positionSource=positionSource}
    if old and old.mode=="windup" and old.attempted and t-old.shotAt<1.5 then
        jump.attempted=true;jump.shotAt=old.shotAt;jump.ability=old.ability
        jump.fearSeen=old.fearSeen;jump.reason="windup_shot_pending"
    end
    state.jumps[id]=jump
    return jump
end

local function registerWindup(unit,blast,history,signal)
    local id=read(Entity.GetIndex,unit)
    local p,source=targetPos(unit)
    if not id or not p then return end
    local t=now()
    -- Includes Yasha and Kaya and any other engine cast-point modifiers exactly once.
    local castPoint=read(Ability.GetCastPoint,blast,true)
    if not finite(castPoint) or castPoint<=0 or castPoint>3 then return end
    -- API docs describe this as the future time when the spell will execute.
    -- Do not assume a newly observed enemy has a full cast point remaining.
    local finish=read(Ability.GetCastStartTime,blast)
    local origin="api_deadline"
    local old=state.jumps[id]
    if not finite(finish) or finish<=t or finish>t+castPoint+0.10 then
        if old and old.mode=="windup" and not old.ended and old.unit==unit then
            finish=old.finish;origin=old.deadlineSource
        elseif read(Ability.IsInAbilityPhase,blast)==true and history and history.unit==unit
            and history.phase==false and t-history.at<=0.10 then
            finish=history.at+castPoint;origin="observed_phase_transition"
        else
            return nil,true
        end
    end
    if finish<=t then return end
    if old and old.mode=="windup" and not old.ended and old.unit==unit then
        old.finish=math.min(old.finish,finish,old.created+castPoint)
        old.velocityAt=t
        old.hiddenSignal=old.hiddenSignal or signal
        if dist(old.first,p)>16 then reason(old,"windup_position_changed");old.moved=true end
        return old
    end
    local j={unit=unit,id=id,mode="windup",blast=blast,created=finish-castPoint,finish=finish,
        sample=p,sampleAt=t,first=p,reason="windup_detected",attempted=false,positionSource=source,
        velocity={x=0,y=0},velocityAt=t,deadlineSource=origin,hiddenSignal=signal}
    state.jumps[id]=j
    return j
end

local function sample(jump,p,t,positionSource)
    if jump.suspended or jump.positionSource~=positionSource then
        jump.suspended=false;jump.velocity=nil;jump.sample=p;jump.sampleAt=t
        jump.positionSource=positionSource;return
    end
    local dt=t-jump.sampleAt
    if dt<1/60 then return end
    if dt>0.15 then
        jump.velocity=nil; jump.sample=p; jump.sampleAt=t;return
    end
    local vx,vy=(p.x-jump.sample.x)/dt,(p.y-jump.sample.y)/dt
    if vx*vx+vy*vy>3500*3500 then
        jump.velocity=nil; reason(jump,"unreliable_velocity")
        jump.sample=p;jump.sampleAt=t
    elseif dist(p,jump.sample)>0.5 then
        jump.velocity={x=vx,y=vy};jump.velocityAt=t
        jump.sample=p; jump.sampleAt=t
    elseif visible(jump.unit) and not jump.velocity and t-jump.created>=0.10 and dt>=0.06 then
        -- A very short / vertical jump still has a leap modifier.
        jump.velocity={x=0,y=0};jump.velocityAt=t
        jump.sample=p; jump.sampleAt=t
    end
end

local function canShoot(ability)
    if not valid(ability) or (read(Ability.GetLevel,ability) or 0)<1 then return false,"unlearned" end
    if read(Ability.IsCastable,ability,read(NPC.GetMana,state.hero) or 0)~=true then return false,"not_ready" end
    for _,key in ipairs({"STUNNED","SILENCED","HEXED","COMMAND_RESTRICTED","OUT_OF_GAME","INVULNERABLE"}) do
        if has(state.hero,key) then return false,"hero_"..key end
    end
    if read(NPC.IsChannellingAbility,state.hero)==true or read(Ability.IsInAbilityPhase,ability)==true then
        return false,"already_casting"
    end
    return true
end

local function blockedByHero(tree,aim,target,delay,speed,radius)
    local length=dist(tree,aim)
    if length<1 then return true end
    local dx,dy=(aim.x-tree.x)/length,(aim.y-tree.y)/length
    for _,other in pairs(read(Heroes.GetAll) or {}) do
        if other~=target and valid(other) and read(Entity.IsAlive,other)==true
            and read(Entity.GetTeamNum,other)~=read(Entity.GetTeamNum,state.hero) and visible(other) then
            local p=pos(other)
            if p then
                local x,y=p.x-tree.x,p.y-tree.y
                local along=x*dx+y*dy
                local perpendicular=math.abs(x*dy-y*dx)
                -- Conservative current-position blocker check; moving blockers remain uncertain.
                if along>0 and along<length and perpendicular<radius+(read(NPC.GetHullRadius,other) or 24) then
                    return true
                end
            end
        end
    end
    return false
end

local function plan(jump,ability,trees,networkDelay)
    local t=now()
    if jump.attempted or jump.ended then return end
    if jump.mode=="windup" and jump.moved then return end
    local target=jump.unit
    if has(target,"DEBUFF_IMMUNE") or has(target,"MAGIC_IMMUNE") or has(target,"INVULNERABLE")
        or has(target,"OUT_OF_GAME") or read(NPC.GetModifier,target,FEAR) then
        reason(jump,"target_protected_or_feared");return
    end
    local hp,tp=pos(state.hero),targetPos(target)
    if not hp or not tp or not jump.velocity or t-(jump.velocityAt or 0)>0.10 then
        reason(jump,"sampling_velocity");return
    end
    local range=read(Ability.GetCastRange,ability)
    if not finite(range) or range<=0 then reason(jump,"cast_range_unavailable");return end
    local speed=special(ability,"speed",2000)
    local multiplier=special(ability,"ricochet_distance_multiplier",1.5)
    local castPoint=read(Ability.GetCastPoint,ability,true)
    if not finite(castPoint) or castPoint<0 then castPoint=0.15 end
    local radius=special(ability,"ricochet_radius_start",115)
    -- Aim so the projectile's inner 75% radius reaches the hero's centre.
    -- Hull radius and Scepter expansion are intentionally not needed for the estimate.
    local hitRadius=radius*0.75
    local remaining=jump.finish-t
    local best
    local earliest,closest=math.huge,math.huge
    local inRange,turnKnown,blocked=0,0,0
    for _,tree in ipairs(trees) do
        if read(Tree.IsActive,tree)==true then
            local p=pos(tree)
            if p then
                local initial=dist(hp,p)
                closest=math.min(closest,initial)
                -- Never order a walk into range; target only trees already reachable.
                if initial<=range-5 then
                    inRange=inRange+1
                    local turn=read(NPC.GetTimeToFacePosition,state.hero,vec(p))
                    if finite(turn) and turn>=0 and turn<1 then
                        turnKnown=turnKnown+1
                        local delay=networkDelay+castPoint+turn+1/30+initial/speed
                        local total,aim,flight=intercept(tp,jump.velocity,p,speed,delay,hitRadius)
                        if total and speed*flight<=range*multiplier-5 then
                            earliest=math.min(earliest,total)
                            if total+1/30<remaining then
                              if blockedByHero(p,aim,target,delay,speed,radius) then blocked=blocked+1
                              elseif not best or total<best.total then
                                best={tree=tree,treePos=p,aim=aim,total=total,turn=turn,
                                    firstDistance=initial,secondDistance=speed*flight,jump=jump,remaining=remaining,
                                    hitRadius=hitRadius}
                              end
                            end
                        end
                    end
                end
            end
        end
    end
    if not best then
        local why=jump.mode=="windup" and "no_intercept_before_takeoff" or "no_intercept_before_landing"
        if #trees==0 then why="no_trees"
        elseif inRange==0 then why="no_live_tree_in_range"
        elseif turnKnown==0 then why="turn_time_unavailable"
        elseif blocked>0 then why="ricochet_blocked_by_hero" end
        reason(jump,why,{trees_in_range=inRange,closest_tree=closest<math.huge and closest or -1,
            earliest_eta=earliest<math.huge and earliest or -1,network_delay=networkDelay,
            late_by=earliest<math.huge and math.max(0,earliest+1/30-remaining) or -1})
    end
    return best
end

local function fire(ability,best)
    local j=best.jump
    if read(Tree.IsActive,best.tree)~=true then return end
    if j.mode=="windup" then
        local animation=state.animations[j.id]
        local fresh=animation and animation.unit==j.unit and now()-animation.at<=0.10
        if (not available(j.unit) and not j.hiddenSignal) or now()>=j.finish then return end
        if read(Ability.IsInAbilityPhase,j.blast)~=true and not fresh then return end
    elseif not available(j.unit) or not read(NPC.GetModifier,j.unit,LEAP) then return end
    local player=read(Players.GetLocal)
    local orders=Enum.UnitOrder or {}
    local issuer=Enum.PlayerOrderIssuer and Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY
    if not player or not issuer or not orders.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION
        or not orders.DOTA_UNIT_ORDER_CAST_TARGET_TREE then reason(j,"order_api_missing");return end
    j.attempted=true;j.shotAt=now();j.ability=ability;j.reason="orders_sent"
    state.nextShot=now()+math.max(0.35,best.total)
    -- Keep the pair proven to produce fear in the 0.1 demo; callback dispatch may reorder it.
    Player.PrepareUnitOrders(player,orders.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,nil,vec(best.aim),ability,
        issuer,state.hero,false,false,true,true,"muerta_anti_techies_vector",false)
    Player.PrepareUnitOrders(player,orders.DOTA_UNIT_ORDER_CAST_TARGET_TREE,best.tree,vec(best.treePos),ability,
        issuer,state.hero,false,false,true,true,"muerta_anti_techies_tree",false)
end

script.OnUpdate=protect("OnUpdate",function()
    if not enabled:Get() then return end
    local hero=read(Heroes.GetLocal)
    if not valid(hero) or read(NPC.GetUnitName,hero)~="npc_dota_hero_muerta" then
        if state.hero then reset() end;return
    end
    local t=now()
    if state.hero~=hero or (state.lastTime and t<state.lastTime) then
        reset();state.hero=hero;
    end
    state.lastTime=t
    if read(Entity.IsAlive,hero)~=true then state.jumps={};state.phaseHistory={};state.animations={};return end
    local active={}
    for _,unit in pairs(read(Heroes.GetAll) or {}) do
        if enemy(unit) then
            local id=read(Entity.GetIndex,unit)
            local blast=read(NPC.GetAbility,unit,"techies_suicide")
            local inPhase=read(Ability.IsInAbilityPhase,blast)
            local history=id and state.phaseHistory[id]
            local animation=id and state.animations[id]
            local freshAnimation=animation and animation.unit==unit and t-animation.at<=0.10
            local transition=inPhase==true and history and history.unit==unit
                and history.phase==false and t-history.at<=0.10
            local old=id and state.jumps[id]
            local signal=freshAnimation and "blast_animation" or transition and "phase_transition" or nil
            local hiddenConfirmed=old and old.unit==unit and old.mode=="windup" and not old.ended
                and old.hiddenSignal and t<old.finish
            local unknown=false
            local mod=read(NPC.GetModifier,unit,LEAP)
            if mod and available(unit) then
                local j=register(unit,mod)
                local p,source=targetPos(unit)
                if j and p and not j.ended then active[j.id]=true;sample(j,p,t,source) end
            elseif not mod and (inPhase==true or freshAnimation)
                and (available(unit) or signal or hiddenConfirmed) then
                local j
                j,unknown=registerWindup(unit,blast,history,signal)
                if j and not j.ended then active[j.id]=true end
            end
            if id then state.phaseHistory[id]={unit=unit,at=t,phase=inPhase,
                unknownLogged=unknown==true} end
        end
    end
    for id,j in pairs(state.jumps) do
        if not active[id] and not j.ended then
            if j.mode~="windup" and enemy(j.unit) and not available(j.unit) and t<j.finish+0.35 then
                j.suspended=true;j.velocity=nil
                reason(j,"awaiting_entity_update")
            else
                j.ended=t
            end
        end
        if j.ended and t-j.ended>1.5 then state.jumps[id]=nil end
    end
    if not next(active) or t<state.nextShot then return end
    local ability=read(NPC.GetAbility,hero,"muerta_dead_shot")
    local ready,why=canShoot(ability)
    if not ready then for id in pairs(active) do
        -- Preserve the original cause and every transition; never overwrite a completed shot.
        reason(state.jumps[id],why)
    end;return end
    local hp=pos(hero)
    local range=read(Ability.GetCastRange,ability)
    if not hp or not finite(range) or range<=0 then return end
    local trees={}
    local seen={}
    for _,list in ipairs({read(Trees.InRadius,vec(hp),range,true) or {},
        TempTrees and read(TempTrees.InRadius,vec(hp),range) or {}}) do
        for _,tree in pairs(list) do if not seen[tree] then trees[#trees+1]=tree;seen[tree]=true end end
    end
    local best
    local networkDelay=lag()
    for id in pairs(active) do
        local candidate=plan(state.jumps[id],ability,trees,networkDelay)
        if candidate and (not best or candidate.total<best.total) then best=candidate end
    end
    if best then fire(ability,best) end
end)

script.OnUnitAnimation=protect("OnUnitAnimation",function(data)
    if not enabled:Get() or not state.hero or not data or not enemy(data.unit) then return end
    local unit=data.unit
    local blast=read(NPC.GetAbility,unit,"techies_suicide")
    local mapped=read(NPC.GetAbilityByActivity,unit,data.activity)
    local id=read(Entity.GetIndex,unit)
    local confirmed=blast~=nil and mapped==blast
    if not confirmed or not id then return end
    state.animations[id]={unit=unit,at=now()}
    -- Do not derive a fresh full cast duration from receipt time or undocumented lag semantics.
    -- The normal path still requires an engine deadline or a recent observed phase transition.
    script.OnUpdate()
end)

script.OnUnitAnimationEnd=protect("OnUnitAnimationEnd",function(data)
    if not data or not data.unit then return end
    local id=read(Entity.GetIndex,data.unit)
    if id then state.animations[id]=nil end
end)

script.OnModifierCreate=protect("OnModifierCreate",function(unit,mod)
    if not enabled:Get() or not state.hero or not enemy(unit) then return end
    if read(Modifier.GetName,mod)==LEAP then register(unit,mod) end
end)

script.OnGameEnd=protect("OnGameEnd",function() reset() end)
return script
