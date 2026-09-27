local _, A = ...
local B = { candidates = {}, limit = 32 }
A.Buffs = B
function B.OnCast(unit, id)
    if InCombatLockdown() or not A.Access.Readable(unit, id) or unit ~= "player"
        or not A.Bindings.Resolve(id) then return end
    B.candidates[id] = GetTime() + 10
end
-- nil is unknown, not an empty list. Never learn from partial observations.
function B.Scan(unit)
    if unit == "target" and A.Access.Read(UnitCanAssist, "player", "target") ~= true then return nil end
    if InCombatLockdown() or A.UnitAPI.State(unit) ~= "alive" then return nil end
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(getter) ~= "function" then return nil end
    local auras = {}
    for index = 1, 255 do
        local ok, aura = pcall(getter, unit, index, "HELPFUL")
        if not ok or not A.Access.Readable(aura) then return nil end
        if aura == nil then return auras end
        if type(aura) ~= "table" or not A.Access.Readable(aura.spellId, aura.name)
            or type(aura.spellId) ~= "number" or type(aura.name) ~= "string" then return nil end
        auras[#auras + 1] = aura
    end
end
function B.Info(id)
    local info = A.Access.Read(C_Spell and C_Spell.GetSpellInfo, id)
    if type(info) == "table" and A.Access.Readable(info.name, info.iconID)
        and type(info.name) == "string" and info.name ~= "" then return info end
end
function B.ForParty(entry)
    local selfOnly = A.Access.Read(C_Spell and C_Spell.IsSelfBuff, entry.id)
    if selfOnly == true then return false end
    if selfOnly == false then return true end
    -- Unknown classification retains actual observation, not a guessed scope.
    return entry.party == true
end
function B.Learn(aura, unit)
    if not B.candidates[aura.spellId] or not A.Access.Readable(aura.duration, aura.sourceUnit)
        or type(aura.duration) ~= "number" or aura.duration ~= aura.duration
        or aura.duration < 300 or aura.duration >= math.huge
        or type(aura.sourceUnit) ~= "string" then return end
    local own = aura.sourceUnit == "player" or A.Access.Read(UnitIsUnit, aura.sourceUnit, "player") == true
    if not own or not A.Bindings.Resolve(aura.spellId) then return end
    local spell = B.Info(aura.spellId)
    if not spell then return end
    local group = A.BuffDefaults.SeededGroup(aura.spellId)
    local learnedID = A.BuffDefaults.active and group and A.BuffDefaults.ranks[group] or aura.spellId
    for _, entry in ipairs(A.db.buffs) do
        local previous = B.Info(entry.id)
        if entry.id == aura.spellId or (previous and previous.name == spell.name)
            or (A.BuffDefaults.active and group and A.BuffDefaults.SeededGroup(entry.id) == group) then
            entry.id = learnedID -- Keep the highest learned seeded rank, including after a downrank cast.
            if unit ~= "player" then entry.party = true end
            return
        end
    end
    if #A.db.buffs < B.limit then
        A.db.buffs[#A.db.buffs + 1] = { id = learnedID, enabled = true, party = unit ~= "player" }
    end
end
-- Paladin's own native stance state distinguishes their aura from another
-- Paladin's party buff. Unknown or incomplete state never means "no aura".
function B.AuraChoices()
    if InCombatLockdown() or B.suspended or A.View.unlocked then return {} end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or class ~= "PALADIN" then return {} end
    local count = A.Access.Read(GetNumShapeshiftForms)
    if type(count) ~= "number" or count < 0 or count > 32 or count % 1 ~= 0
        or type(GetShapeshiftFormInfo) ~= "function" then return {} end
    local choices = {}
    for index = 1, count do
        local readable, _, active, _, id = pcall(GetShapeshiftFormInfo, index)
        if not readable or not A.Access.Readable(active, id) or type(active) ~= "boolean"
            or type(id) ~= "number" then return {} end
        if active then return {} end
        local info = A.Bindings.Resolve(id)
        if not info then return {} end
        choices[#choices + 1] = {id=id, icon=info.iconID}
    end
    return choices
end
function B.Refresh()
    if InCombatLockdown() or B.suspended then return end
    A.BuffDefaults.Seed()
    local now = GetTime()
    for id, expires in pairs(B.candidates) do if expires < now then B.candidates[id] = nil end end
    local auraChoices = B.AuraChoices()
    local blessingChoices = A.BuffDefaults.Choices()
    local snapshots = {}
    for index, row in ipairs(A.View.supportRows or A.View.rows) do
        local auras = B.Scan(row.unit); snapshots[index] = auras
        if auras and row.unit ~= "target" then for _, aura in ipairs(auras) do B.Learn(aura, row.unit) end end
    end
    local watched = {}
    for _, entry in ipairs(A.db.buffs) do
        local info = entry.enabled and A.Bindings.Resolve(entry.id)
        if info then watched[#watched + 1] = { entry = entry, info = info, party = B.ForParty(entry) } end
    end
    for index, row in ipairs(A.View.supportRows or A.View.rows) do
        local missing, blessings = {}, {}
        if snapshots[index] and not A.View.unlocked then
            local names, ids, blessed = {}, {}, false
            for _, aura in ipairs(snapshots[index]) do
                names[aura.name] = true; ids[aura.spellId] = true
                if A.BuffDefaults.Group(aura.spellId) then blessed = true end
            end
            if not blessed then blessings = blessingChoices end
            for _, watch in ipairs(watched) do
                local grouped = A.BuffDefaults.active and A.BuffDefaults.Group(watch.entry.id)
                if (row.unit == "player" or watch.party
                    or (row.unit == "target" and A.Access.Read(UnitIsUnit, "target", "player") == true))
                    and not grouped
                    and not ids[watch.entry.id] and not names[watch.info.name] then
                    missing[#missing + 1] = { id = watch.entry.id, icon = watch.info.iconID }
                end
            end
        end
        B.Paint(row, missing)
        B.PaintBlessings(row, blessings, #missing)
        if row.unit == "player" then B.PaintAuras(row, snapshots[index] and auraChoices or {}, #missing, #blessings) end
    end
    if B.picker and B.picker:IsShown() then B.RefreshPicker() end
end
function B.Stop()
    B.candidates = {}
    for _, row in ipairs(A.View.supportRows or A.View.rows) do
        B.Paint(row, {})
        B.PaintBlessings(row, {}, 0)
        if row.unit == "player" then B.PaintAuras(row, {}, 0) end
    end
    if B.picker then B.picker:Hide() end
end
