local _, A = ...
local C = {}
A.BuffCatalog = C
-- Forever 70009 candidate identities, not spell grants. Resolve every action
-- through the player's native learned/helpful/active validation. Group spells
-- provide coverage only until their recipient behavior has live acceptance.
local classes = {
    DRUID = {
        {key="wild", ranks={9885,9884,8907,5234,6756,5232,1126}, coverage={21850,21849}},
        {key="thorns", ranks={9910,9756,8914,1075,782,467}},
    },
    MAGE = {
        {key="intellect", ranks={10157,10156,1461,1460,1459}, coverage={23028}},
        {key="mageArmor", family="mageArmor", self=true, ranks={22783,22782,6117}},
        {key="iceArmor", family="mageArmor", self=true, ranks={10220,10219,7320,7302}},
        {key="frostArmor", family="mageArmor", self=true, ranks={7301,7300,168}},
    },
    PRIEST = {
        {key="fortitude", ranks={10938,10937,2791,1245,1244,1243}, coverage={21564,21562}},
        {key="spirit", ranks={27841,14819,14818,14752}, coverage={27681}},
        {key="shadow", ranks={10958,10957,976}, coverage={27683}},
        {key="innerFire", self=true, ranks={10952,10951,1006,602,7128,588}},
    },
    SHAMAN = {{key="lightningShield", self=true, ranks={10432,10431,8134,945,905,325,324}}},
    WARLOCK = {
        {key="demonArmor", family="demonArmor", self=true, ranks={11735,11734,11733,1086,706}},
        {key="demonSkin", family="demonArmor", self=true, ranks={696,687}},
    },
    -- Area effects stay on the fixed player action, never on recipient rows.
    WARRIOR = {{key="battleShout", self=true, ranks={25289,11551,11550,11549,6192,5242,6673}}},
    HUNTER = {{key="trueshot", self=true, ranks={20906,20905,19506,1299348,1299346}}},
}
local recognized, families, variants = {}, {}, {}
for _, definitions in pairs(classes) do
    for _, definition in ipairs(definitions) do
        for _, ids in ipairs({definition.ranks, definition.coverage or {}}) do
            for _, id in ipairs(ids) do
                recognized[id] = true
                families[id] = definition.family or definition.key
                variants[id] = definition.key
            end
        end
    end
end
local recipients = {player=true, party1=true, party2=true, party3=true, party4=true, target=true}
local manaClasses = {DRUID=true, HUNTER=true, MAGE=true, PALADIN=true, PRIEST=true, SHAMAN=true, WARLOCK=true}
local function classOf(unit)
    if type(UnitClass) ~= "function" then return end
    local ok, _, class = pcall(UnitClass, unit)
    if ok and A.Access.Readable(class) and type(class) == "string" then return class end
end
function C.Recognized(id)
    return A.Access.Readable(id) and type(id) == "number" and recognized[id] == true
end
local function disabledVariants()
    local disabled = {}
    -- A saved opt-out applies across ranks of that variant. Never rewrite storage
    -- or let an enabled duplicate override a disabled entry.
    for _, entry in ipairs(A.db and A.db.buffs or {}) do
        if A.Access.Readable(entry) and type(entry) == "table"
            and A.Access.Readable(entry.id, entry.enabled) and entry.enabled == false
            and type(entry.id) == "number" and variants[entry.id] then
            disabled[variants[entry.id]] = true
        end
    end
    return disabled
end
local function suggest(class, unit, offered)
    local role = A.Access.Read(UnitGroupRolesAssigned, unit)
    local recipientClass = classOf(unit)
    local mana = role == "HEALER" or (recipientClass and manaClasses[recipientClass])
    local key, reason
    if class == "DRUID" then
        if offered.wild then key, reason = "wild", "general protection from Mark of the Wild"
        elseif role == "TANK" then key, reason = "thorns", "damages attackers when hit (assigned tank)" end
    elseif class == "PRIEST" then
        if offered.fortitude then key, reason = "fortitude", "stamina support for every role"
        elseif mana and offered.spirit then
            key, reason = "spirit", role == "HEALER" and "Spirit support (assigned healer)" or "Spirit support (mana-using class)"
        elseif unit == "player" then key, reason = "innerFire", "personal armor support" end
    elseif class == "MAGE" then
        if mana then
            key, reason = "intellect", role == "HEALER" and "Intellect support (assigned healer)" or "Intellect support (mana-using class)"
        end
        -- Armor alternatives depend on intent; keep them manual.
    elseif class == "WARLOCK" then
        key = offered.demonArmor and "demonArmor" or "demonSkin"
        reason = "personal armor upkeep"
    elseif class == "SHAMAN" then key, reason = "lightningShield", "personal shield upkeep"
    elseif class == "WARRIOR" then key, reason = "battleShout", "maintain your attack-power shout"
    elseif class == "HUNTER" then key, reason = "trueshot", "maintain your learned attack-power aura" end
    if key and offered[key] then return offered[key], "Suggested: " .. reason .. "." end
end
-- The caller may share a fresh cache among recipient calls in ONE refresh.
-- No cache is retained here: omitted/new caches always revalidate native state.
local function resolve(id, cache)
    if cache and cache[id] ~= nil then return cache[id] or nil end
    local info = A.Bindings.Resolve(id)
    if cache then cache[id] = info or false end
    return info
end
function C.Choices(unit, auras, cache)
    local choices = {}
    if InCombatLockdown() or not A.Access.Readable(unit, auras)
        or type(unit) ~= "string" or not recipients[unit] or type(auras) ~= "table" then return choices end
    if not A.Access.Readable(cache) or type(cache) ~= "table" then cache = nil end
    local class = classOf("player")
    local definitions = class and classes[class]
    if not definitions then return choices end
    local covered = {}
    for _, aura in ipairs(auras) do
        if not A.Access.Readable(aura) or type(aura) ~= "table"
            or not A.Access.Readable(aura.spellId) or type(aura.spellId) ~= "number" then return {} end
        local family = families[aura.spellId]
        if family then covered[family] = true end
    end
    local disabled, offered = disabledVariants(), {}
    for _, definition in ipairs(definitions) do
        if (not definition.self or unit == "player") and not disabled[definition.key]
            and not covered[definition.family or definition.key] then
            for _, id in ipairs(definition.ranks) do
                local info = resolve(id, cache)
                if info and A.Access.Readable(info) and type(info) == "table" and A.Access.Readable(info.iconID) then
                    choices[#choices + 1] = {id=id, icon=info.iconID}
                    offered[definition.key] = id
                    break
                end
            end
        end
    end
    local id, reason = suggest(class, unit, offered)
    return choices, id, reason
end
