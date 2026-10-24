---@diagnostic disable: undefined-global
local script = {}

local E = Enum.ParticleAttachment

local EFFECTS = {
    { "Огонь - Radiance 2022", { "particles/econ/events/fall_2022/radiance/radiance_owner_fall2022.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Огонь - Radiance TI9", { "particles/econ/events/ti9/radiance_owner_ti9.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Огонь - Radiance TI6", { "particles/econ/events/ti6/radiance_owner_ti6.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Огонь - Radiance 2021", { "particles/econ/events/fall_2021/radiance_owner_fall_2021.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Огонь - онибi", { "particles/econ/courier/courier_onibi/courier_onibi_black_ambient_fire_lvl21.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Молния - Storm", {
        "particles/econ/items/storm_spirit/storm_spirit_tormenta_armor/storm_spirit_tormenta_ambient_back.vpcf",
        "particles/econ/items/storm_spirit/storm_spirit_tormenta_armor/storm_spirit_tormenta_ambient_cuff.vpcf",
        "particles/econ/items/storm_spirit/storm_spirit_tormenta_armor/storm_spirit_tormenta_ambient_front.vpcf",
    }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Молния - Zeus", { "particles/econ/items/zeus/arcana_chariot/zeus_arcana_chariot.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Лёд - CM ground", { "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_arcana_ground_ambient.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Silver", { "particles/econ/seasonal/seasonal_ambient_silver.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Candy Caster", { "particles/econ/seasonal/seasonal_ambient_candy_mint.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Snowdrift", { "particles/econ/seasonal/seasonal_ambient_snow.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Gold Glow", { "particles/econ/seasonal/new_bloom/seasonal_ambient_gold_glow.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Smoke", { "particles/econ/seasonal/new_bloom/seasonal_ambient_smoke.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Ravenblight", { "particles/econ/seasonal/crownfall/seasonal_ambient_screeauk.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
    { "Featherfall", { "particles/econ/seasonal/crownfall/seasonal_ambient_screeauk_v2.vpcf" }, E.PATTACH_ABSORIGIN_FOLLOW, nil },
}

local SPREAD = {
    E.PATTACH_ROOTBONE_FOLLOW,
    E.PATTACH_CENTER_FOLLOW,
    E.PATTACH_EYES_FOLLOW,
    E.PATTACH_RENDERORIGIN_FOLLOW,
}

local names = {}
for index, row in ipairs(EFFECTS) do names[index] = row[1] end

Menu.Create("Changer", "Main", "Burning Changer (Alternate)"):Icon("\u{f06d}")
local group = Menu.Create("Changer", "Main", "Burning Changer (Alternate)", "Main", "Эффект")
local enable = group:Switch("Включить", false, "\u{f06d}")
local effect = group:Combo("Эффект", names, 0)
local on_items = group:Switch("Вешать на все вещи", false, "\u{f553}")
local stack = group:Slider("Слоёв", 1, 6, 1, "%d")
local size = group:Slider("Размер", 1, 5, 1, "%d")
local target = group:Combo("Цель", { "Только я", "Я и союзники", "Все герои" }, 0)

local preview_group = Menu.Create("Changer", "Main", "Burning Changer (Alternate)", "Main", "Превью")
local preview = preview_group:Switch("Превью в меню и витрине", true, "\u{f03e}")

for _, name in ipairs({ "Куда вешать", "Свой путь .vpcf" }) do
    local stale = Menu.Find("Changer", "Main", "Burning Changer (Alternate)", "Main", "Эффект", name)
    if stale then stale:Visible(false) end
end
local stale_diag = Menu.Find("Changer", "Main", "Burning Changer (Alternate)", "Main", "Превью", "Диагностика")
if stale_diag then stale_diag:Visible(false) end

local live_game, live_menu, next_scan, next_menu_scan = {}, {}, 0, 0

local function chosen()
    return EFFECTS[effect:Get() + 1]
end

local function wearables_by_owner()
    local found = {}
    for _, ent in pairs(Entities.GetAll()) do
        if Entity.GetClassName(ent) == "C_DOTAWearableItem" then
            local owner = Entity.GetOwner(ent)
            if owner then
                local key = Entity.GetIndex(owner)
                found[key] = found[key] or {}
                found[key][#found[key] + 1] = ent
            end
        end
    end
    return found
end

local function worn(list)
    if not list then return {} end
    local crowd, place = {}, {}
    for _, ent in ipairs(list) do
        local spot = Entity.GetAbsOrigin(ent)
        place[ent] = string.format("%.1f,%.1f,%.1f", spot.x, spot.y, spot.z)
        crowd[place[ent]] = (crowd[place[ent]] or 0) + 1
    end
    local kept = {}
    for _, ent in ipairs(list) do
        if crowd[place[ent]] <= 4
            or Entity.GetField(ent, "m_bHiddenByCombiner", false)
            or Entity.GetField(ent, "m_bParticleSystemsCreated", false)
        then
            kept[#kept + 1] = ent
        end
    end
    return kept
end

local function targets()
    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsAlive(hero) then return {} end
    local mode = target:Get()
    if mode == 0 then return { hero } end
    local team = Entity.GetTeamNum(hero)
    local out = {}
    for _, other in ipairs(Heroes.GetAll()) do
        if Entity.IsAlive(other) and not Entity.IsDormant(other)
            and not NPC.IsIllusion(other) and not NPC.IsMeepoClone(other)
            and (mode == 2 or Entity.GetTeamNum(other) == team)
        then
            out[#out + 1] = other
        end
    end
    return out
end

local function portrait_units()
    local units = {}
    for _, ent in pairs(Entities.GetAll()) do
        local class = Entity.GetClassName(ent)
        if class == "C_PortraitWorldUnit" or class == "C_DOTAPortraitUnit" then
            units[#units + 1] = ent
        end
    end
    return units
end

local function build_wanted(units, row)
    local layers = stack:Get()
    local spread = size:Get()
    local wanted = {}
    local found = on_items:Get() and wearables_by_owner() or nil
    for _, unit in ipairs(units) do
        local carriers = { unit }
        if found then
            local origin = Entity.GetAbsOrigin(unit)
            for _, item in ipairs(worn(found[Entity.GetIndex(unit)])) do
                if Entity.GetAbsOrigin(item):Distance(origin) <= 300 then
                    carriers[#carriers + 1] = item
                end
            end
        end
        for _, carrier in ipairs(carriers) do
            for layer = 1, layers do
                for part = 1, #row[2] do
                    for spot = 1, spread do
                        local key = Entity.GetIndex(carrier) .. "|" .. layer .. "|" .. part .. "|" .. spot
                        wanted[key] = { carrier, row, part, spot }
                    end
                end
            end
        end
    end
    return wanted
end

local function spawn(unit, row, part, spot)
    local attach = spot == 1 and row[3] or SPREAD[spot - 1]
    local id = Particle.Create(row[2][part], attach, unit)
    if row[4] then
        for _, cp in ipairs(row[4]) do
            Particle.SetControlPointEnt(id, cp[1], unit, cp[2], cp[3], Vector(0, 0, 0), true)
        end
    end
    return id
end

local function apply(active, wanted)
    for key, record in pairs(active) do
        local want = wanted[key]
        if not want or want[2][2][want[3]] ~= record.path or want[4] ~= record.spot then
            Particle.Destroy(record.id)
            active[key] = nil
        end
    end
    for key, want in pairs(wanted) do
        if not active[key] then
            active[key] = { id = spawn(want[1], want[2], want[3], want[4]), path = want[2][2][want[3]], spot = want[4] }
        end
    end
end

local function clear(active)
    for key, record in pairs(active) do
        Particle.Destroy(record.id)
        active[key] = nil
    end
end


function script.OnUpdate()
    local now = GlobalVars.GetCurTime()
    if now < next_scan then return end
    next_scan = now + 0.5
    local row = enable:Get() and chosen() or nil
    if not row then
        clear(live_game)
        return
    end
    apply(live_game, build_wanted(targets(), row))
end

function script.OnUpdateEx()
    local now = GlobalVars.GetCurTime()
    if now < next_menu_scan then return end
    next_menu_scan = now + 0.5
    local row = preview:Get() and chosen() or nil
    if not row then
        clear(live_menu)
        return
    end
    apply(live_menu, build_wanted(portrait_units(), row))
end

function script.OnGameEnd()
    clear(live_game)
    clear(live_menu)
end

return script
