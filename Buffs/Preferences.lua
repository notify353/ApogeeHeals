local _, A = ...
local P = {}
A.SmartBuffs = P
local valid = {smart=true, manual=true, off=true}
function P.Mode(key, fallback)
    local saved = A.db.smartBuffs and A.db.smartBuffs[key]
    if valid[saved] then return saved end
    -- Legacy opt-outs still apply to catalog and discovered buffs. Blessings
    -- were already independent of the old Might/Wisdom checkboxes.
    for _, entry in ipairs(A.db.buffs) do
        if key ~= "blessings" and not entry.enabled and P.Key(entry.id) == key then return "off" end
    end
    return fallback or "smart"
end
function P.Key(id)
    if A.BuffDefaults.Group(id) then return "blessings" end
    return A.BuffCatalog.PreferenceKey(id) or ("learned:" .. id)
end
function P.Allows(key, expanded, fallback)
    local mode = P.Mode(key, fallback)
    return mode == "smart" or (expanded and mode == "manual")
end
function P.Set(key, mode)
    if InCombatLockdown() or not valid[mode] then return end
    A.db.smartBuffs = A.db.smartBuffs or {}
    A.db.smartBuffs[key] = mode
    for _, entry in ipairs(A.db.buffs) do
        if key:sub(1, 8) == "learned:" and P.Key(entry.id) == key then entry.enabled = mode ~= "off" end
    end
    A.Buffs.Refresh()
end
function P.Rekey(previous, id)
    local prefs = A.db.smartBuffs
    if prefs and previous ~= id and prefs["learned:" .. id] == nil then
        prefs["learned:" .. id] = prefs["learned:" .. previous]
    end
end
function P.Entries()
    local entries, seen = {}, {}
    local function add(key, label, fallback)
        if seen[key] then return end
        seen[key] = true
        entries[#entries + 1] = {key=key, label=label, fallback=fallback}
    end
    if #A.BuffDefaults.Choices() > 0 then add("blessings", "Blessings") end
    local modes = A.Buffs.AuraChoices(true)
    if #modes > 0 then
        add("modes", A.BuffDefaults.active and "Auras (self)" or "Aspects (self)")
    end
    for _, definition in ipairs(A.BuffCatalog.Definitions()) do
        for _, id in ipairs(definition.ranks) do
            local info = A.Bindings.Resolve(id)
            if info then
                local label = definition.family and "Armor choices (self)"
                    or (info.name .. (definition.self and " (self)" or ""))
                add(definition.family or definition.key, label, definition.key == "shadow" and "manual" or nil)
                break
            end
        end
    end
    for _, entry in ipairs(A.db.buffs) do
        if not A.BuffDefaults.Group(entry.id) and not A.BuffCatalog.Recognized(entry.id)
            and not A.Buffs.modeIDs[entry.id] then
            local info = A.Bindings.Resolve(entry.id)
            if info then add(P.Key(entry.id), info.name .. (A.Buffs.ForParty(entry) and "" or " (self)")) end
        end
    end
    return entries
end
