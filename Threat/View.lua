local _, A = ...
local V, S = {}, A.Style
A.ThreatView = V
local width, rowHeight, header = 96, 11, 7
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
local function bar(parent, w, h, point, x, y, reverse)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetSize(w,h); b:SetPoint(point,parent,point,x,y); b:EnableMouse(false)
    b:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    b:SetMinMaxValues(0,100); b:SetValue(0); b:SetReverseFill(reverse == true)
    return b
end
local function createRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width,9.5); row:SetPoint("TOPLEFT",V.root,"TOPLEFT",0,-header-(index-1)*rowHeight)
    row:EnableMouse(false); S.Background(row)
    -- Immutable half-bars meet at the center. Left fills toward the left edge.
    row.left = bar(row,46.5,7,"TOPLEFT",3,0,true)
    row.right = bar(row,46.5,7,"TOPRIGHT",0,0,false)
    row.health = bar(row,93,2,"BOTTOMRIGHT",0,0,false)
    row.health:SetStatusBarColor(0.51,0.65,0.58,1)
    row.rail = row:CreateTexture(nil,"OVERLAY"); row.rail:SetSize(2,9.5)
    row.rail:SetPoint("TOPLEFT",0,0); row.rail:SetColorTexture(0.57,0.58,0.61,1)
    local overlay = CreateFrame("Frame",nil,row); overlay:SetAllPoints(row); overlay:EnableMouse(false)
    local level = A.Access.Read(row.GetFrameLevel,row)
    if finite(level) then overlay:SetFrameLevel(level+5) end
    row.reference = overlay:CreateTexture(nil,"OVERLAY"); row.reference:SetSize(0.5,7)
    row.reference:SetPoint("TOPLEFT",row,"TOPLEFT",49.5,0); row.reference:SetColorTexture(0.83,0.87,0.85,0.25)
    row.notice = S.Text(overlay,5); row.notice:SetPoint("TOPRIGHT",-2,0); row.notice:SetSize(21,7)
    row.notice:SetJustifyH("RIGHT")
    row.selection = CreateFrame("Frame",nil,overlay); row.selection:SetAllPoints(row); row.selection:EnableMouse(false)
    for _,edge in ipairs({{"TOPLEFT",width,0.5},{"BOTTOMLEFT",width,0.5},{"TOPLEFT",0.5,9.5},{"TOPRIGHT",0.5,9.5}}) do
        local line = row.selection:CreateTexture(nil,"OVERLAY")
        line:SetSize(edge[2],edge[3]); line:SetPoint(edge[1],row,edge[1],0,0)
        line:SetColorTexture(0.87,0.76,0.48,1)
    end
    row:SetAlpha(0); row.selection:SetAlpha(0)
    return row
end
function V.Create()
    V.root = CreateFrame("Frame",nil,UIParent)
    V.root:SetScale(S.scale); V.root:SetSize(width,header+8*rowHeight+7)
    V.root:SetMovable(true); V.root:SetClampedToScreen(true); V.root:EnableMouse(false)
    V.handle = CreateFrame("Button",nil,V.root); V.handle:EnableMouse(true)
    V.handle:SetPoint("TOPLEFT",0,0); V.handle:SetSize(width,header); V.handle:RegisterForDrag("LeftButton")
    V.title = S.CleanText(V.handle,5); V.title:SetAllPoints(); V.title:SetJustifyH("LEFT")
    V.title:SetText("Threat"); V.title:SetTextColor(unpack(S.muted))
    V.handle:SetScript("OnDragStart",function()
        if not InCombatLockdown() then V.root:StartMoving(); V.moving = true end
    end)
    V.handle:SetScript("OnDragStop",function() V.StopMoving(true) end)
    V.footer = S.CleanText(V.root,5); V.footer:SetPoint("BOTTOMLEFT",0,0); V.footer:SetTextColor(unpack(S.muted))
    V.rows, V.gates = {}, {}
    for i=1,7 do V.rows[i] = createRow(V.root,i) end
    local parent = V.root
    for i=1,7 do
        local gate = CreateFrame("Frame",nil,parent); gate:SetAllPoints(V.root); gate:EnableMouse(false)
        V.gates[i], parent = gate, gate
    end
    V.rows[8] = createRow(parent,8)
    V.Place(); V.Clear()
end
function V.ClearRow(row)
    row:SetAlpha(0); row.notice:SetText("")
    row.left:SetValue(0); row.right:SetValue(0); row.health:SetMinMaxValues(0,1); row.health:SetValue(0)
    row.selection:SetAlpha(0); row.rail:SetColorTexture(0.57,0.58,0.61,1); row.unit = nil
end
function V.Clear()
    for _,row in ipairs(V.rows) do V.ClearRow(row) end
    for _,gate in ipairs(V.gates) do gate:SetAlpha(1) end
    V.footer:SetText("")
end
function V.PaintWarning(row, warning)
    local info = warnings[warning] or warnings.unknown
    row.left:SetStatusBarColor(info[2],info[3],info[4],1)
    row.right:SetStatusBarColor(info[2],info[3],info[4],1)
    row.notice:SetTextColor(info[2],info[3],info[4],1)
    row.notice:SetText(warning == "noAggro" and "LOST" or (warning == "unknown" and "?" or ""))
end
function V.PaintCentered(row, percentage)
    row.left:SetValue(0); row.right:SetValue(0)
    -- Public-only transform. Never subtract/compare a restricted percentage.
    if not A.Access.Readable(percentage) or type(percentage) ~= "number"
        or percentage ~= percentage or percentage < 0 or percentage == math.huge then return false end
    local delta = percentage-100
    row.left:SetValue(math.min(100,math.max(0,-delta)))
    row.right:SetValue(math.min(100,math.max(0,delta)))
    return true
end
function V.PaintRelative(row, unit, ok, tanking, rawPercentage)
    row.left:SetValue(0); row.right:SetValue(0)
    if not ok or not A.Access.Readable(tanking) or type(tanking) ~= "boolean" then return "?" end
    local percentage = rawPercentage
    if tanking then
        local leadOK, value = pcall(UnitThreatPercentageOfLead,"player",unit)
        if not leadOK then return "?" end
        percentage = value
    end
    if tanking and A.Access.Readable(percentage) and percentage == 0 then return "-" end
    if not V.PaintCentered(row,percentage) then return "?" end
end
function V.PaintIdentity(row, unit)
    -- Health goes straight to native sinks; no arithmetic or cached health.
    A.UnitAPI.PaintHealth(row.health,unit)
    row.health:SetStatusBarColor(0.51,0.65,0.58,1)
    row.rail:SetColorTexture(0.57,0.58,0.61,1)
    local kind = A.Access.Read(UnitPowerType,unit)
    if kind == 0 then
        local maximum = A.Access.Read(UnitPowerMax,unit,0)
        if type(maximum) == "number" and maximum > 0 then row.rail:SetColorTexture(0.31,0.55,0.80,1) end
    end
end
function V.Paint(row, unit, warning)
    row.unit = unit; row:SetAlpha(1); V.PaintIdentity(row,unit); V.PaintWarning(row,warning)
    local ok,tanking,_,_,rawPercentage = pcall(UnitDetailedThreatSituation,"player",unit)
    local unavailable = V.PaintRelative(row,unit,ok,tanking,rawPercentage)
    if unavailable and warning ~= "noAggro" then row.notice:SetText(unavailable) end
end
local demoRows = {
    {"War Tank", "lead", 182, false, 82},
    {"Dark Adept", "lead", 160, true, 64},
    {"Bloodfang Scout", "weak", 112, false, 93},
    {"Shadow Mystic", "noLead", 95, true, 37},
    {"Training Hound", "noAggro", 70, false, 55},
    {"Unknown reading", "unknown", nil, false, 100},
    {"Solo comparison", "lead", nil, false, 100, "-"},
    {"Selected enemy", "lead", 145, true, 78},
}
function V.PaintDemo(time)
    local phase = (time%24)/12
    local depth = phase <= 1 and phase or 2-phase
    depth = depth*depth*(3-2*depth)
    for i,sample in ipairs(demoRows) do
        local row = V.rows[i]
        V.ClearRow(row); row:SetAlpha(1)
        local warning, percentage, hp = sample[2],sample[3],sample[5]
        if i == 2 then
            percentage = 180-110*depth; hp = 95-60*depth
            if percentage < 85 then warning = "noAggro"
            elseif percentage < 100 then warning = "noLead"
            elseif percentage < 125 then warning = "weak" end
        end
        V.PaintWarning(row,warning)
        if not V.PaintCentered(row,percentage) then row.notice:SetText(sample[6] or "?") end
        row.health:SetMinMaxValues(0,100); row.health:SetValue(hp)
        if sample[4] then row.rail:SetColorTexture(0.31,0.55,0.80,1) end
        row.selection:SetAlpha(i == 8 and 1 or 0)
    end
    V.footer:SetText("DEMO")
end
