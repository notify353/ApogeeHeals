local _, A = ...
local V, S = {}, A.Style
A.ThreatView = V
local width, rowHeight, header = 156, 24, 18
local warnings = {
    lead={"LEAD", 0.28,0.74,0.46}, weak={"WEAK LEAD", 0.90,0.74,0.22},
    noLead={"NO LEAD", 0.92,0.48,0.24}, noAggro={"NO AGGRO", 0.86,0.30,0.30},
    unknown={"UNKNOWN", 0.65,0.70,0.78},
}
local function finite(value)
    return A.Access.Readable(value) and type(value) == "number"
        and value == value and math.abs(value) < 100000
end
-- Secret booleans go directly through native conversion to a native alpha sink.
-- The returned alpha and frame visibility are never read back.
function V.BooleanAlpha(region, value, yes, no)
    local ok = pcall(function()
        if A.Access.Readable(value) then
            if type(value) ~= "boolean" then error("unknown comparison") end
            region:SetAlpha(value and yes or no)
        else
            region:SetAlpha(C_CurveUtil.EvaluateColorValueFromBoolean(value, yes, no))
        end
    end)
    if not ok then region:SetAlpha(0) end
    return ok
end
function V.Place()
    if InCombatLockdown() or V.moving then return end
    local position = A.db.threatPosition or {x=-100, y=-45}
    V.root:ClearAllPoints()
    V.root:SetPoint("TOPLEFT", UIParent, "CENTER", position.x, position.y)
end
function V.StopMoving(save)
    if not V.moving then return end
    V.root:StopMovingOrSizing(); V.moving = nil
    if not save or InCombatLockdown() then return end
    local x = A.Access.Read(V.root.GetLeft, V.root)
    local y = A.Access.Read(V.root.GetTop, V.root)
    local scale = A.Access.Read(V.root.GetEffectiveScale, V.root)
    local parentScale = A.Access.Read(UIParent.GetEffectiveScale, UIParent)
    local w = A.Access.Read(UIParent.GetWidth, UIParent)
    local h = A.Access.Read(UIParent.GetHeight, UIParent)
    if finite(x) and finite(y) and finite(scale) and scale > 0 and finite(parentScale) and parentScale > 0
        and finite(w) and finite(h) then
        x, y = x * scale / parentScale - w / 2, y * scale / parentScale - h / 2
        -- Position offsets are in the panel's scale, matching Place's anchors.
        x, y = x * parentScale / scale, y * parentScale / scale
        if finite(x) and finite(y) then A.db.threatPosition = {x=x, y=y} end
    end
end
function V.ResetPosition()
    if InCombatLockdown() then return end
    V.StopMoving(false); A.db.threatPosition = nil; V.Place()
end
local function createRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, 22); row:SetPoint("TOPLEFT", V.root, "TOPLEFT", 0, -header-(index-1)*rowHeight)
    row:EnableMouse(false); S.Background(row)
    row.name = S.Text(row, 6); row.name:SetPoint("LEFT", 13, 6); row.name:SetSize(85, 7)
    row.name:SetJustifyH("LEFT"); row.name:SetShadowColor(0,0,0,1); row.name:SetShadowOffset(1,-1)
    row.warning = S.Text(row, 6); row.warning:SetPoint("RIGHT", -3, 6); row.warning:SetSize(55, 7)
    row.warning:SetJustifyH("RIGHT")
    row.amount = S.Text(row, 5); row.amount:SetPoint("LEFT", 13, -1); row.amount:SetSize(85, 6)
    row.amount:SetJustifyH("LEFT"); row.amount:SetTextColor(unpack(S.muted))
    row.aggro = {}
    for _, text in ipairs({"AGGRO", "NO AGGRO", "AGGRO ?"}) do
        local label = S.Text(row, 5); label:SetPoint("RIGHT", -3, -1); label:SetSize(55, 6)
        label:SetJustifyH("RIGHT"); label:SetText(text); label:SetTextColor(unpack(S.muted))
        row.aggro[#row.aggro+1] = label
    end
    row.relative = CreateFrame("StatusBar", nil, row)
    row.relative:SetSize(140, 4); row.relative:SetPoint("BOTTOMLEFT", 13, 1)
    row.relative:EnableMouse(false); row.relative:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.relative:SetMinMaxValues(0, 200); row.relative:SetReverseFill(false)
    local track = row:CreateTexture(nil, "BACKGROUND")
    track:SetSize(140, 4); track:SetPoint("BOTTOMLEFT", 13, 1); track:SetColorTexture(0.14,0.16,0.20,1)
    row.reference = row.relative:CreateTexture(nil, "OVERLAY")
    row.reference:SetSize(0.5, 4); row.reference:SetPoint("CENTER", row.relative, "CENTER")
    row.reference:SetColorTexture(1,1,1,0.8)
    -- Discrete native warning scale, never a percentage or a lead margin.
    row.risk = CreateFrame("StatusBar", nil, row); row.risk:SetSize(55, 1)
    row.risk:SetPoint("BOTTOMRIGHT", -3, 0); row.risk:EnableMouse(false)
    row.risk:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.risk:SetStatusBarColor(0.90,0.74,0.22,1); row.risk:SetMinMaxValues(0,3)
    row.risk:SetReverseFill(true)
    row.marker = row:CreateTexture(nil, "ARTWORK"); row.marker:SetSize(10,10); row.marker:SetPoint("LEFT", 1, 1)
    row.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    row.strip = row:CreateTexture(nil, "ARTWORK"); row.strip:SetSize(width, 1)
    row.strip:SetPoint("BOTTOMLEFT", 0, 0)
    row.selection = CreateFrame("Frame", nil, row); row.selection:SetAllPoints(row); row.selection:EnableMouse(false)
    for _, edge in ipairs({{"TOPLEFT",width,0.5},{"BOTTOMLEFT",width,0.5},{"TOPLEFT",0.5,22},{"TOPRIGHT",0.5,22}}) do
        local line = row.selection:CreateTexture(nil, "OVERLAY")
        line:SetSize(edge[2], edge[3]); line:SetPoint(edge[1], row, edge[1], 0, 0)
        line:SetColorTexture(1, 0.85, 0.25, 1)
    end
    row:SetAlpha(0); row.selection:SetAlpha(0)
    return row
end
function V.Create()
    V.root = CreateFrame("Frame", nil, UIParent)
    V.root:SetScale(S.scale); V.root:SetSize(width, header+8*rowHeight+9)
    V.root:SetMovable(true); V.root:SetClampedToScreen(true); V.root:EnableMouse(false)
    V.handle = CreateFrame("Button", nil, V.root)
    V.handle:EnableMouse(true)
    V.handle:SetPoint("TOPLEFT", 0, 0); V.handle:SetSize(width, header); V.handle:RegisterForDrag("LeftButton")
    V.title = S.CleanText(V.handle, 6); V.title:SetPoint("TOPLEFT", 0, 0); V.title:SetSize(width, 9); V.title:SetJustifyH("LEFT")
    V.title:SetText("Threat - drag to move"); V.title:SetTextColor(unpack(S.muted))
    local scale = S.CleanText(V.handle, 5); scale:SetPoint("BOTTOMLEFT", 0, 1); scale:SetSize(width, 7)
    scale:SetJustifyH("LEFT"); scale:SetText("Prototype: 0%  |  middle 100%  |  full 200%")
    V.handle:SetScript("OnDragStart", function()
        if not InCombatLockdown() then V.root:StartMoving(); V.moving = true end
    end)
    V.handle:SetScript("OnDragStop", function() V.StopMoving(true) end)
    V.footer = S.CleanText(V.root, 6); V.footer:SetPoint("BOTTOMLEFT", 0, 0)
    V.footer:SetTextColor(unpack(S.muted))
    V.rows, V.gates = {}, {}
    for i = 1, 7 do V.rows[i] = createRow(V.root, i) end
    -- Seven native alpha parents implement duplicate suppression even when
    -- target comparisons are secret. Never combine secret booleans in Lua.
    local parent = V.root
    for i = 1, 7 do
        local gate = CreateFrame("Frame", nil, parent); gate:SetAllPoints(V.root); gate:EnableMouse(false)
        V.gates[i], parent = gate, gate
    end
    V.rows[8] = createRow(parent, 8)
    V.Place(); V.Clear()
end
function V.ClearRow(row)
    row:SetAlpha(0); row.name:SetText(""); row.warning:SetText("")
    row.amount:SetText(""); row.risk:SetAlpha(0); row.risk:SetValue(0)
    row.relative:SetAlpha(0); row.relative:SetValue(0)
    for _, label in ipairs(row.aggro) do label:SetAlpha(0) end
    row.marker:SetAlpha(0); row.selection:SetAlpha(0); row.unit = nil
end
function V.Clear()
    for _, row in ipairs(V.rows) do V.ClearRow(row) end
    for _, gate in ipairs(V.gates) do gate:SetAlpha(1) end
    V.footer:SetText("")
end
local function quantity(value)
    if not A.Access.Readable(value) then return true end
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end
function V.PaintRelative(row, unit, ok, tanking, rawPercentage)
    -- Mirror native UnitFrame selection only when the selector is public.
    -- The percentage itself may be restricted and goes directly to native sinks.
    row.amount:SetText("NO DATA")
    if not ok or not A.Access.Readable(tanking) or type(tanking) ~= "boolean" then return end
    local percentage = rawPercentage
    if tanking then
        local leadOK, leadPercentage = pcall(UnitThreatPercentageOfLead, "player", unit)
        if not leadOK then return end
        percentage = leadPercentage
    end
    if not quantity(percentage) then return end
    -- Native numeric threat hides tank lead zero. It cannot establish a cushion.
    if tanking and A.Access.Readable(percentage) and percentage == 0 then
        row.amount:SetText("NO COMPARISON"); return
    end
    local displayed = pcall(function()
        row.relative:SetValue(percentage)
        row.amount:SetFormattedText("Relative %.0f%%", percentage)
    end)
    if displayed then row.relative:SetAlpha(1)
    else row.relative:SetValue(0); row.amount:SetText("NO DATA") end
end
function V.PaintNative(row, unit)
    row.amount:SetText(""); row.risk:SetAlpha(0); row.risk:SetValue(0)
    row.relative:SetAlpha(0); row.relative:SetValue(0)
    for _, label in ipairs(row.aggro) do label:SetAlpha(0) end
    row.aggro[3]:SetAlpha(1)
    -- Requery directly at presentation time. No opaque threat value enters
    -- tracking, arithmetic, formatting in Lua, or presentation readback.
    if A.Access.Read(UnitCanAttack, "player", unit) ~= true then return end
    local ok, tanking, _, _, rawPercentage = pcall(UnitDetailedThreatSituation, "player", unit)
    V.PaintRelative(row, unit, ok, tanking, rawPercentage)
    if ok then
        local yes = V.BooleanAlpha(row.aggro[1], tanking, 1, 0)
        local no = V.BooleanAlpha(row.aggro[2], tanking, 0, 1)
        if yes and no then row.aggro[3]:SetAlpha(0)
        else row.aggro[1]:SetAlpha(0); row.aggro[2]:SetAlpha(0) end
    end
    local leadOK, lead = pcall(UnitThreatLeadSituation, "player", unit)
    if leadOK and not A.Access.Readable(lead) then
        row.warning:SetTextColor(0.65,0.70,0.78,1)
        row.strip:SetColorTexture(0.65,0.70,0.78,1)
        local displayed = pcall(function()
            row.warning:SetFormattedText("RISK %.0f/3", lead)
            row.risk:SetValue(lead); row.risk:SetAlpha(1)
        end)
        if not displayed then row.warning:SetText("UNKNOWN"); row.risk:SetAlpha(0); row.risk:SetValue(0) end
    elseif leadOK and type(lead) == "number" and lead >= 0 and lead <= 3 and lead % 1 == 0 then
        row.risk:SetValue(lead); row.risk:SetAlpha(1)
    end
end
function V.Paint(row, unit, warning)
    row.unit = unit; row:SetAlpha(1)
    A.UnitAPI.PaintFullName(row.name, unit)
    local info = warnings[warning] or warnings.unknown
    row.warning:SetText(info[1]); row.warning:SetTextColor(info[2],info[3],info[4],1)
    row.strip:SetColorTexture(info[2],info[3],info[4],1)
    row.relative:SetStatusBarColor(info[2],info[3],info[4],1)
    V.PaintNative(row, unit)
    row.marker:SetAlpha(0)
    local marker = A.Access.Read(GetRaidTargetIndex, unit)
    if type(marker) == "number" and marker >= 1 and marker <= 8 and marker % 1 == 0 then
        local column, line = (marker-1)%4, math.floor((marker-1)/4)
        row.marker:SetTexCoord(column/4,(column+1)/4,line/2,(line+1)/2); row.marker:SetAlpha(1)
    end
end
