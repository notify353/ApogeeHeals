local _, A = ...
local M = {}
A.ThreatModel = M
local function state(value)
    return A.Access.Readable(value) and type(value) == "number"
        and value >= 0 and value <= 3 and value % 1 == 0
end
function M.Classify(lead, tanking, status)
    -- Lead state 3 means not first on threat, NOT necessarily loss of aggro.
    -- States 1/2 are combined by Blizzard's tank nameplate presentation.
    if not state(status) then return "unknown" end
    if A.Access.Readable(tanking) and tanking == false then return "noAggro" end
    if not A.Access.Readable(tanking) or tanking ~= true or not state(lead) then return "unknown" end
    if lead == 3 then return "noLead" end
    if lead == 1 or lead == 2 then return "weak" end
    return "lead"
end
function M.Sample(unit)
    local hostile = A.Access.Read(UnitCanAttack, "player", unit)
    if A.Access.Read(UnitExists, unit) == false
        or A.Access.Read(UnitIsDeadOrGhost, unit) == true
        or hostile == false then
        return "absent", "unknown"
    end
    if hostile ~= true then return "unknown", "unknown" end
    local ok, tanking, status = pcall(UnitDetailedThreatSituation, "player", unit)
    local presence = "unknown"
    if ok and A.Access.Readable(status) then
        if status == nil then presence = "unengaged"
        elseif state(status) then presence = "present" end
    end
    -- Only public values leave this function. Secret results are never cached.
    if presence == "unengaged" then return presence, "unknown" end
    local lead = A.Access.Read(UnitThreatLeadSituation, "player", unit)
    return presence, ok and M.Classify(lead, tanking, status) or "unknown"
end
function M.New()
    return {entries={}, slots={}, sequence=0}
end
function M.Remove(model, unit)
    model.entries[unit] = nil
    for i = 1, 7 do if model.slots[i] == unit then model.slots[i] = nil end end
end
function M.Observe(model, unit, presence, warning)
    local entry = model.entries[unit]
    if presence == "absent" then M.Remove(model, unit); return end
    if presence == "unengaged" and not entry then return end
    if not entry then
        model.sequence = model.sequence + 1
        entry = {order=model.sequence}; model.entries[unit] = entry
    end
    entry.warning = warning
end
function M.Fill(model)
    local waiting, occupied = {}, {}
    for i = 1, 7 do if model.slots[i] then occupied[model.slots[i]] = true end end
    for unit, entry in pairs(model.entries) do
        if not occupied[unit] then waiting[#waiting+1] = {unit=unit, order=entry.order} end
    end
    -- Sort acquisition sequence only; threat and selection never reorder rows.
    table.sort(waiting, function(a, b) return a.order < b.order end)
    local at = 1
    for i = 1, 7 do
        if not model.slots[i] and waiting[at] then model.slots[i] = waiting[at].unit; at = at + 1 end
    end
end
