local _, A = ...
local D = { pending = true, ranks = {} }
A.BuffDefaults = D
-- Candidate identities, never an assertion that a spell exists/is learned on Forever.
-- Ordinary Might/Wisdom remain seeded for saved-data compatibility; the chooser
-- offers lasting party blessings independently of reminder preferences.
-- Emergency Protection/Freedom/Sacrifice are neither choices nor upkeep coverage.
local families = {
    might = { 25291, 19838, 19837, 19836, 19835, 19834, 19740, 25782, 25916 },
    wisdom = { 25290, 19854, 19853, 19852, 19850, 19742, 25894, 25918 },
    kings = { 20217, 25898 }, salvation = { 1038, 25895 },
    sanctuary = { 20914, 20913, 20912, 20911, 25899 },
    light = { 19979, 19978, 19977, 25890 },
}
local groups, seeds = {}, {}
for group, ids in pairs(families) do for _, id in ipairs(ids) do groups[id] = group end end
for _, group in ipairs({ "might", "wisdom" }) do
    for index = 1, #families[group] - 2 do seeds[families[group][index]] = group end
end
function D.Group(id) return groups[id] end
function D.SeededGroup(id) return seeds[id] end
function D.Seed()
    if not D.pending or InCombatLockdown() then return end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or type(class) ~= "string" then return end
    D.pending, D.active, D.ranks = nil, class == "PALADIN", {}
    if not D.active then return end
    for _, group in ipairs({ "might", "wisdom" }) do
        local ids = families[group]
        -- Last two identities are greater blessings: recognized for coverage, not defaults.
        for index = 1, #ids - 2 do
            local id = ids[index]
            if A.Bindings.Resolve(id) then D.ranks[group] = id; break end
        end
        local id = D.ranks[group]
        if id then
            local existing
            for _, entry in ipairs(A.db.buffs) do
                if D.SeededGroup(entry.id) == group then existing = entry; break end
            end
            for index = #A.db.buffs, 1, -1 do
                local entry = A.db.buffs[index]
                if entry ~= existing and D.SeededGroup(entry.id) == group then
                    existing.enabled = existing.enabled and entry.enabled
                    table.remove(A.db.buffs, index)
                end
            end
            if existing then existing.id, existing.party = id, true
            elseif #A.db.buffs < A.Buffs.limit then
                A.db.buffs[#A.db.buffs + 1] = { id = id, enabled = group == "might", party = true }
            end
        end
    end
end
-- Each row is one selectable variant, highest rank first. Greater variants
-- remain separate explicit choices; native casting owns reagents and targeting.
local choices = {
    {25291,19838,19837,19836,19835,19834,19740}, {25290,19854,19853,19852,19850,19742},
    {20217}, {1038}, {20914,20913,20912,20911}, {19979,19978,19977},
    {25916,25782}, {25918,25894}, {25898}, {25895}, {25899}, {25890},
}
function D.Choices()
    local result = {}
    if not D.active or InCombatLockdown() then return result end
    for _, ranks in ipairs(choices) do
        for _, id in ipairs(ranks) do
            local info = A.Bindings.Resolve(id)
            if info then result[#result + 1] = {id=id, icon=info.iconID}; break end
        end
    end
    return result
end

-- Conservative novice guidance, not an optimizer. See docs/BLESSING_GUIDANCE.md.
function D.Recommend(unit, available)
    if InCombatLockdown() or not D.active or #available == 0 then return end
    local role = A.Access.Read(UnitGroupRolesAssigned, unit)
    local ok, _, class = pcall(UnitClass, unit)
    if not ok or not A.Access.Readable(class) or type(class) ~= "string" then class = nil end
    local order, basis
    if role == "TANK" then
        basis = "assigned tank"
        if class == "PALADIN" then order = {"kings", "wisdom"}
        elseif class == "WARRIOR" or class == "DRUID" then order = {"kings", "might"}
        else order = {"kings"} end
    elseif role == "HEALER" then
        order, basis = {"wisdom", "kings"}, "assigned healer"
    elseif class == "WARRIOR" or class == "ROGUE"
        or (role == "DAMAGER" and class == "PALADIN") then
        order, basis = {"might", "kings"}, role == "DAMAGER" and "melee damage role" or "melee class fallback"
    elseif class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then
        order, basis = {"wisdom", "kings"}, "caster class"
    elseif class == "HUNTER" then
        order, basis = {"kings", "wisdom"}, "hunter class; combat style unknown"
    elseif class == "PALADIN" or class == "DRUID" or class == "SHAMAN" then
        order, basis = {"kings", "wisdom"}, "hybrid class; specialization unknown"
    else
        order, basis = {"kings"}, "general stat benefit; role/class unavailable"
    end
    local benefits = {kings="broad stat support", wisdom="mana regeneration", might="melee attack power"}
    -- Choices list ordinary variants before Greater variants, keeping a per-row
    -- suggestion targeted to that player when both versions are learned.
    for _, group in ipairs(order) do
        for _, entry in ipairs(available) do
            if D.Group(entry.id) == group then
                return entry.id, "Suggested: " .. benefits[group] .. " (" .. basis .. ")."
            end
        end
    end
end
