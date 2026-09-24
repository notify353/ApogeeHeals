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
    local info = A.Access.Read(C_Spell.GetSpellInfo, id)
    if type(info) == "table" and A.Access.Readable(info.name, info.iconID)
        and type(info.name) == "string" and info.name ~= "" then return info end
end
function B.ForParty(entry)
    local selfOnly = A.Access.Read(C_Spell.IsSelfBuff, entry.id)
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
    for _, entry in ipairs(A.db.buffs) do
        local previous = B.Info(entry.id)
        if entry.id == aura.spellId or (previous and previous.name == spell.name) then
            entry.id = aura.spellId -- Localized client names group observed ranks, not guessed equivalents.
            if unit ~= "player" then entry.party = true end
            return
        end
    end
    if #A.db.buffs < B.limit then
        A.db.buffs[#A.db.buffs + 1] = { id = aura.spellId, enabled = true, party = unit ~= "player" }
    end
end
function B.Refresh()
    if InCombatLockdown() or B.suspended then return end
    local now = GetTime()
    for id, expires in pairs(B.candidates) do if expires < now then B.candidates[id] = nil end end
    local snapshots = {}
    for index, row in ipairs(A.View.rows) do
        local auras = B.Scan(row.unit); snapshots[index] = auras
        if auras then for _, aura in ipairs(auras) do B.Learn(aura, row.unit) end end
    end
    local watched = {}
    for _, entry in ipairs(A.db.buffs) do
        local info = entry.enabled and A.Bindings.Resolve(entry.id)
        if info then watched[#watched + 1] = { entry = entry, info = info } end
    end
    for index, row in ipairs(A.View.rows) do
        local missing = {}
        if snapshots[index] and not A.View.unlocked then
            local names, ids = {}, {}
            for _, aura in ipairs(snapshots[index]) do names[aura.name] = true; ids[aura.spellId] = true end
            for _, watch in ipairs(watched) do
                if (row.unit == "player" or B.ForParty(watch.entry))
                    and not ids[watch.entry.id] and not names[watch.info.name] then
                    missing[#missing + 1] = { id = watch.entry.id, icon = watch.info.iconID }
                end
            end
        end
        B.Paint(row, missing)
    end
    if B.RefreshPicker then B.RefreshPicker() end
end
function B.Stop()
    B.candidates = {}
    for _, row in ipairs(A.View.rows) do B.Paint(row, {}) end
    if B.picker then B.picker:Hide() end
end
