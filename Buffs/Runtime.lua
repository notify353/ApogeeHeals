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
    if unit == "target" and (A.Access.Read(UnitIsPlayer, "target") ~= true
        or A.Access.Read(UnitCanAssist, "player", "target") ~= true) then return nil end
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
-- Only public, finite timing can establish an expiring buff. Unknown timing
-- remains coverage and never produces a guessed countdown.
function B.Remaining(aura)
    if not A.Access.Readable(aura.duration, aura.expirationTime) then return end
    local duration, expires = aura.duration, aura.expirationTime
    if type(duration) ~= "number" or duration <= 0 or duration ~= duration or duration >= math.huge
        or type(expires) ~= "number" or expires <= 0 or expires ~= expires or expires >= math.huge then return end
    return math.max(0, expires - GetTime())
end
-- Rank alone cannot establish strength: another caster may have an improved
-- version of the same spell ID. Only refresh our own observed applications.
function B.OwnApplication(aura)
    local source = aura.sourceUnit
    if not A.Access.Readable(source) or type(source) ~= "string" then return false end
    return source == "player" or A.Access.Read(UnitIsUnit, source, "player") == true
end
function B.Coverage(auras)
    if not auras then return end
    local result = {}
    for _, aura in ipairs(auras) do
        local remaining = B.Remaining(aura)
        if not B.OwnApplication(aura) or not remaining or remaining >= 120 then result[#result + 1] = aura end
    end
    return result
end
function B.WithTimers(choices, auras, nativeMode)
    local result = {}
    for _, entry in ipairs(choices) do
        local remaining, unknown, protected
        local blessing = A.BuffDefaults.Group(entry.id)
        local catalog = A.BuffCatalog.TimerGroup(entry.id)
        for _, aura in ipairs(auras or {}) do
            if (aura.spellId == entry.id or (entry.name and aura.name == entry.name)
                or (blessing and A.BuffDefaults.Group(aura.spellId) == blessing)
                or (catalog and A.BuffCatalog.TimerGroup(aura.spellId) == catalog))
                and (not nativeMode or B.OwnApplication(aura)) then
                local value = B.Remaining(aura)
                if not B.OwnApplication(aura) then protected = true end
                if value then remaining = math.max(remaining or 0, value) else unknown = true end
            end
        end
        if not protected then
            result[#result + 1] = {id=entry.id, icon=entry.icon, remaining=not unknown and remaining or nil}
        end
    end
    return result
end
function B.ForParty(entry)
    local selfOnly = A.Access.Read(C_Spell and C_Spell.IsSelfBuff, entry.id)
    if selfOnly == true then return false end
    if selfOnly == false then return true end
    -- Unknown classification retains actual observation, not a guessed scope.
    return entry.party == true
end
function B.Learn(aura, unit)
    if (A.BuffCatalog and A.BuffCatalog.Recognized(aura.spellId))
        or (B.modeIDs and B.modeIDs[aura.spellId]) then return end
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
-- Native own stance state distinguishes a Paladin aura or Hunter aspect from
-- another player's effect. Unknown/incomplete state never means "missing".
function B.AuraChoices(includeActive)
    B.modeIDs = {}
    if InCombatLockdown() or B.suspended or A.View.unlocked then return {} end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or (class ~= "PALADIN" and class ~= "HUNTER") then return {} end
    local count = A.Access.Read(GetNumShapeshiftForms)
    if type(count) ~= "number" or count < 0 or count > 32 or count % 1 ~= 0
        or type(GetShapeshiftFormInfo) ~= "function" then return {} end
    local choices, selected = {}, false
    for index = 1, count do
        local readable, _, active, _, id = pcall(GetShapeshiftFormInfo, index)
        if not readable or not A.Access.Readable(active, id) or type(active) ~= "boolean"
            or type(id) ~= "number" then return {} end
        if active then selected = true end
        B.modeIDs[id] = true
        local info = A.Bindings.Resolve(id)
        if not info then return {} end
        choices[#choices + 1] = {id=id, icon=info.iconID}
    end
    return selected and not includeActive and {} or choices
end
function B.Refresh()
    if InCombatLockdown() or B.suspended then return end
    A.BuffDefaults.Seed()
    local now = GetTime()
    for id, expires in pairs(B.candidates) do if expires < now then B.candidates[id] = nil end end
    local auraChoices = B.AuraChoices()
    local blessingChoices = A.BuffDefaults.Choices()
    local snapshots, catalogCache = {}, {}
    for index, row in ipairs(A.View.supportRows or A.View.rows) do
        local auras = B.Scan(row.unit); snapshots[index] = auras
        if auras and row.unit ~= "target" then for _, aura in ipairs(auras) do B.Learn(aura, row.unit) end end
    end
    local watched = {}
    for _, entry in ipairs(A.db.buffs) do
        local info = entry.enabled and A.Bindings.Resolve(entry.id)
        if info and not (A.BuffCatalog and A.BuffCatalog.Recognized(entry.id))
            and not B.modeIDs[entry.id] then watched[#watched + 1] = { entry = entry, info = info, party = B.ForParty(entry) } end
    end
    for index, row in ipairs(A.View.supportRows or A.View.rows) do
        local missing, blessings = {}, {}
        if B.recipientRow == row and (not snapshots[index] or A.View.unlocked) then B.CloseRecipient() end
        local expanded = B.recipientRow == row
        local coverage = B.Coverage(snapshots[index])
        if snapshots[index] and not A.View.unlocked then
            local names, ids, blessed = {}, {}, false
            for _, aura in ipairs(coverage) do
                names[aura.name] = true; ids[aura.spellId] = true
                if A.BuffDefaults.Group(aura.spellId) then blessed = true end
            end
            if expanded or not blessed then blessings = blessingChoices end
            for _, watch in ipairs(watched) do
                local grouped = A.BuffDefaults.active and A.BuffDefaults.Group(watch.entry.id)
                if (row.unit == "player" or watch.party
                    or (row.unit == "target" and A.Access.Read(UnitIsUnit, "target", "player") == true))
                    and not grouped
                    and (expanded or (not ids[watch.entry.id] and not names[watch.info.name])) then
                    missing[#missing + 1] = { id = watch.entry.id, icon = watch.info.iconID, name = watch.info.name }
                end
            end
        end
        missing = B.WithTimers(missing, snapshots[index])
        blessings = B.WithTimers(blessings, snapshots[index])
        B.Paint(row, missing)
        B.PaintBlessings(row, blessings, #missing)
        local upkeep, suggested, reason = {}, nil, nil
        if A.BuffCatalog and not A.View.unlocked then
            upkeep, suggested, reason = A.BuffCatalog.Choices(row.unit, expanded and {} or coverage, catalogCache, expanded)
        end
        upkeep = B.WithTimers(upkeep, snapshots[index])
        B.PaintCatalog(row, upkeep, #missing, #blessings, suggested, reason)
        if row.unit == "player" then
            local modes = snapshots[index] and (expanded and B.AuraChoices(true) or auraChoices) or {}
            modes = B.WithTimers(modes, snapshots[index], true)
            B.PaintAuras(row, modes, #missing, #blessings + #upkeep)
            if A.WeaponUpkeep then
                local offset = math.min(#missing, 4) + (#missing > 4 and 1 or 0)
                    + #blessings + #upkeep + #modes
                A.WeaponUpkeep.Refresh(row, offset)
            end
        end
    end
    if B.picker and B.picker:IsShown() then B.RefreshPicker() end
end
function B.Stop()
    B.CloseRecipient()
    B.candidates = {}
    for _, row in ipairs(A.View.supportRows or A.View.rows) do
        B.Paint(row, {})
        B.PaintBlessings(row, {}, 0)
        B.PaintCatalog(row, {}, 0, 0)
        if row.unit == "player" then B.PaintAuras(row, {}, 0) end
    end
    if A.WeaponUpkeep then A.WeaponUpkeep.Stop() end
    if B.picker then B.picker:Hide() end
end
