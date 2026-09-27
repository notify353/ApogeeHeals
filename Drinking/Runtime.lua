local _, A = ...
local D, R = {}, A.Access.Read
A.Drinking = D
-- Classic drink identities from APHB (MIT). Resolve on this client before use.
-- Export documentation verifies API contracts, not server spell/aura coverage.
local candidates = { 430, 431, 432, 1133, 1135, 1137, 10250, 22734 }
local ids, names = {}, {}
function D.Resolve()
    ids, names = {}, {}
    for _, id in ipairs(candidates) do
        local info = R(C_Spell and C_Spell.GetSpellInfo, id)
        if type(info) == "table" and A.Access.Readable(info.name, info.spellID)
            and type(info.name) == "string" and info.name ~= "" and info.spellID == id then
            ids[id], names[info.name] = true, true
        end
    end
end
function D.IsDrinking(unit)
    if InCombatLockdown() or A.UnitAPI.State(unit) ~= "alive" then return false end
    local getAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(getAura) ~= "function" then return false end
    local found = false
    local instance
    -- Bounded full scan: unreadable or incomplete data never becomes a positive claim.
    for index = 1, 255 do
        local ok, aura = pcall(getAura, unit, index, "HELPFUL")
        if not ok or not A.Access.Readable(aura) then return false end
        if aura == nil then return found, instance end
        if type(aura) ~= "table" or not A.Access.Readable(aura.spellId, aura.name) then return false end
        if (ids[aura.spellId] or names[aura.name]) and not found then
            found = true
            if A.Access.Readable(aura.auraInstanceID) and type(aura.auraInstanceID) == "number" then
                instance = aura.auraInstanceID
            end
        end
    end
    return false
end
function D.CreateTimer(row, preview)
    if preview or row.unit == "target" or row.unit == "targettarget"
        or not C_DurationUtil or not C_DurationUtil.CreateDurationTextBinding
        or not C_StringUtil or not C_StringUtil.CreateSecondsFormatter then return end
    local text = A.Style.Text(row.drinkIcon, 8)
    text:SetAllPoints(); text:SetJustifyH("CENTER"); text:SetJustifyV("BOTTOM")
    text:SetShadowColor(0, 0, 0, 1); text:SetShadowOffset(1, -1)
    text:SetText("")
    local ok, binding = pcall(function()
        local formatter = C_StringUtil.CreateSecondsFormatter()
        formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
        formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
        formatter:SetMaxInterval(Enum.SecondsFormatterInterval.Seconds)
        formatter:SetRounding(Enum.SecondsFormatterRounding.RoundUp)
        formatter:SetMillisecondsThreshold(0)
        formatter:SetDesiredUnitCount(1)
        local result = C_DurationUtil.CreateDurationTextBinding()
        result:SetEnabled(false)
        result:SetFontString(text); result:SetFormatter(formatter)
        result:SetExpiredText(""); result:SetZeroDurationText("")
        result:SetUpdateInterval(0.1)
        return result
    end)
    if ok then row.drinkTimer, row.drinkTimeText = binding, text end
end
function D.Clear(row)
    row.drinkIcon:Hide()
    if row.drinkTimer then
        row.drinkTimer:SetEnabled(false)
        row.drinkTimeText:SetText("")
    end
end
function D.Paint(row)
    local drinking, instance = D.IsDrinking(row.unit)
    row.drinkIcon:SetShown(drinking)
    if not drinking or not row.drinkTimer or not instance
        or not C_UnitAuras or type(C_UnitAuras.GetAuraDuration) ~= "function" then return end
    -- Native duration -> native text binding. Never inspect or calculate time values.
    local ok = pcall(function()
        row.drinkTimer:SetDuration(C_UnitAuras.GetAuraDuration(row.unit, instance))
        row.drinkTimer:SetEnabled(true)
        row.drinkTimer:UpdateFontString()
    end)
    if not ok then
        row.drinkTimer:SetEnabled(false); row.drinkTimeText:SetText("")
    end
end
