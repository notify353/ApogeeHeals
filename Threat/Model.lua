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
    if state(status) and A.Access.Readable(tanking) and tanking == false then return "noAggro" end
    -- Lead is an independent native reading; missing detailed data must not
    -- discard it. Aggro availability is presented separately by the view.
    if not state(lead) then return "unknown" end
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
    local leadOK, lead = pcall(UnitThreatLeadSituation, "player", unit)
    if not leadOK then lead = nil end
    if not A.Access.Readable(lead) then presence, lead = "unknown", nil end
    if state(lead) then presence = "present" end
    -- Only public values leave this function. Secret results are never cached.
    if not ok then tanking, status = nil, nil end
    return presence, M.Classify(lead, tanking, status)
end
function M.New()
    return {entries={}, slots={}, sequence=0}
end
function M.Remove(model, unit)
    model.entries[unit] = nil
    for i = 1, 8 do if model.slots[i] == unit then model.slots[i] = nil end end
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
    for i = 1, 8 do if model.slots[i] then occupied[model.slots[i]] = true end end
    for unit, entry in pairs(model.entries) do
        if not occupied[unit] then waiting[#waiting+1] = {unit=unit, order=entry.order} end
    end
    -- Sort acquisition sequence only; threat and selection never reorder rows.
    table.sort(waiting, function(a, b) return a.order < b.order end)
    local at = 1
    for i = 1, 8 do
        if not model.slots[i] and waiting[at] then model.slots[i] = waiting[at].unit; at = at + 1 end
    end
end

-- Read-only warrior debuff observations. Unknown/incomplete scans never mean absent.
local debuffs = {{7386,"S"},{1160,"D"},{6343,"T"}}
function M.PaintDebuffs(row, unit)
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    local names, found, uncertain = {}, {}, {}
    local complete = false
    for i,entry in ipairs(debuffs) do
        local info = A.Access.Read(C_Spell and C_Spell.GetSpellInfo,entry[1])
        if type(info)=="table" and A.Access.Readable(info.name) and type(info.name)=="string" then
            names[i]=info.name
        end
    end
    if type(getter)=="function" then
        for index=1,64 do
            local ok,aura=pcall(getter,unit,index,"HARMFUL")
            if not ok or not A.Access.Readable(aura) then break end
            if aura==nil then complete=true; break end
            if type(aura)~="table" or not A.Access.Readable(aura.name) or type(aura.name)~="string" then break end
            for i,entry in ipairs(debuffs) do
                if names[i] and aura.name==names[i] then
                    local source=aura.sourceUnit
                    if not A.Access.Readable(source) or type(source)~="string" then uncertain[i]=true
                    else
                        local own=source=="player" or A.Access.Read(UnitIsUnit,source,"player")
                        if own==true then found[i]=aura
                        elseif own~=false then uncertain[i]=true end
                    end
                end
            end
        end
    end
    for i,entry in ipairs(debuffs) do
        local label, aura = row.debuffs[i],found[i]
        label:SetTextColor(0.65,0.70,0.78,1)
        if aura then
            label:SetTextColor(0.28,0.85,0.46,1)
            if i==1 then
                local count=aura.applications
                if A.Access.Readable(count) then
                    if type(count)=="number" and count==count and count>=0 and count<math.huge then
                        label:SetFormattedText("S%d",math.max(1,count))
                    else label:SetText("S?") end
                elseif not pcall(label.SetFormattedText,label,"S%d",count) then label:SetText("S?") end
            else label:SetText(entry[2].."+") end
        elseif complete and names[i] and not uncertain[i] then
            label:SetText(entry[2].."-"); label:SetTextColor(0.42,0.45,0.50,1)
        else label:SetText(entry[2].."?") end
    end
end
