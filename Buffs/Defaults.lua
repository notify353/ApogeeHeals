local _, A = ...
local D = { pending = true, ranks = {} }
A.BuffDefaults = D
-- Candidate identities, never an assertion that a spell exists/is learned on Forever.
-- Only ordinary Might/Wisdom are seeded; the remaining blessing identities prevent
-- mutually exclusive reminders for effects learned through ordinary discovery.
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
function D.Choose(watched, unit)
    if not D.active then return nil end
    -- Preserve existing watch order; appended defaults never supersede a prior
    -- enabled blessing. No class, resource or guessed role optimization.
    for _, watch in ipairs(watched) do
        local group = D.Group(watch.entry.id)
        if group and (unit == "player" or watch.party) then return watch end
    end
end
