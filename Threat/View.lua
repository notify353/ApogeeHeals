local _, A = ...
local V, S = {}, A.Style
A.ThreatView = V
local width, rowHeight, header = 64, 7.5, 0
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
    if InCombatLockdown() then return end
    V.root:ClearAllPoints()
    V.root:SetPoint("TOPLEFT", UIParent, "CENTER", -width/2, 3.5)
end
function V.StopMoving()
    -- Compatibility with runtime lifecycle calls; the meter is permanently fixed.
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
-- Native-only complement: a left-to-right opaque mask covers a colored left
-- half. Its uncovered portion extends from center to left as percentage falls.
-- The right half uses native range 100..200. Neither requires Lua arithmetic.
local function nativeLane(row)
    local lane = CreateFrame("Frame",nil,row); lane:SetAllPoints(row); lane:EnableMouse(false)
    lane.fill = lane:CreateTexture(nil,"BACKGROUND"); lane.fill:SetSize((width-5)/2,7)
    lane.fill:SetPoint("TOPLEFT",5,0)
    lane.mask = bar(lane,(width-5)/2,7,"TOPLEFT",5,0,false)
    lane.mask:SetStatusBarColor(S.background[1],S.background[2],S.background[3],1)
    lane.right = bar(lane,(width-5)/2,7,"TOPRIGHT",0,0,false)
    lane.right:SetMinMaxValues(100,200)
    lane.notice = S.Text(lane.right,5); lane.notice:SetPoint("TOPRIGHT",-2,0)
    lane.notice:SetSize(21,7); lane.notice:SetJustifyH("RIGHT"); lane.notice:Hide()
    lane:SetAlpha(0)
    return lane
end
local function clearNative(row)
    for _,lane in ipairs({row.nativeTank,row.nativeRaw}) do
        lane:SetAlpha(0); lane.mask:SetValue(100); lane.right:SetValue(100); lane.notice:SetText("")
    end
end
local function paintNative(lane, value, tanking)
    lane.mask:SetValue(100); lane.right:SetValue(100); lane.notice:SetText("")
    if A.Access.Readable(value) then
        if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
            lane.notice:SetText("?"); return
        end
        if tanking and value == 0 then lane.notice:SetText("-"); return end
    end
    -- A tank lead value is not a deficit measurement. In particular, an
    -- opaque zero must stay neutral. Only the non-tanking lane exposes left.
    local ok = pcall(function()
        if not tanking then lane.mask:SetValue(value) end
        lane.right:SetValue(value)
    end)
    if not ok then
        lane.mask:SetValue(100); lane.right:SetValue(100); lane.notice:SetText("?")
    end
end
local function createRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width,7); row:SetPoint("TOPLEFT",V.root,"TOPLEFT",0,-header-(index-1)*rowHeight)
    row:EnableMouse(false); S.Background(row)
    -- Immutable half-bars meet at the center. Left fills toward the left edge.
    row.left = bar(row,(width-5)/2,7,"TOPLEFT",5,0,true)
    row.right = bar(row,(width-5)/2,7,"TOPRIGHT",0,0,false)
    row.nativeTank, row.nativeRaw = nativeLane(row), nativeLane(row)
    row.rail = row:CreateTexture(nil,"OVERLAY"); row.rail:SetSize(4,7)
    row.rail:SetPoint("TOPLEFT",0,0); row.rail:SetColorTexture(0.57,0.58,0.61,1)
    local overlay = CreateFrame("Frame",nil,row); overlay:SetAllPoints(row); overlay:EnableMouse(false)
    local level = A.Access.Read(row.GetFrameLevel,row)
    if finite(level) then overlay:SetFrameLevel(level+5) end
    row.reference = overlay:CreateTexture(nil,"OVERLAY"); row.reference:SetSize(0.5,7)
    row.reference:SetPoint("TOPLEFT",row,"TOPLEFT",5+(width-5)/2,0); row.reference:SetColorTexture(0.83,0.87,0.85,0.25)
    row.notice = S.Text(overlay,5); row.notice:SetPoint("TOPRIGHT",-2,0); row.notice:SetSize(21,7)
    row.notice:SetJustifyH("RIGHT"); row.notice:Hide()
    row.selection = CreateFrame("Frame",nil,overlay); row.selection:SetAllPoints(row); row.selection:EnableMouse(false)
    for _,edge in ipairs({{"TOPLEFT",width,0.5},{"BOTTOMLEFT",width,0.5},{"TOPLEFT",0.5,7},{"TOPRIGHT",0.5,7}}) do
        local line = row.selection:CreateTexture(nil,"OVERLAY")
        line:SetSize(edge[2],edge[3]); line:SetPoint(edge[1],row,edge[1],0,0)
        line:SetColorTexture(0.87,0.76,0.48,1)
    end
    row.debuffs = {}
    for i=1,3 do
        local label=S.Text(overlay,5); label:SetSize(12,7)
        label:SetPoint("TOPLEFT",row,"TOPLEFT",width+2+(i-1)*12,0)
        label:SetJustifyH("LEFT"); row.debuffs[i]=label
    end
    row:SetAlpha(0); row.selection:SetAlpha(0)
    return row
end
function V.Create()
    V.root = CreateFrame("Frame",nil,UIParent)
    V.root:SetScale(S.scale); V.root:SetSize(width+38,8*rowHeight-0.5)
    V.root:SetMovable(false); V.root:SetClampedToScreen(true); V.root:EnableMouse(false)
    V.handle = CreateFrame("Button",nil,V.root); V.handle:EnableMouse(false)
    V.handle:SetPoint("TOPLEFT",0,0); V.handle:SetSize(width,header)
    V.title = S.CleanText(V.handle,5); V.title:SetAllPoints(); V.title:SetJustifyH("LEFT")
    V.title:SetText("Threat"); V.title:SetTextColor(unpack(S.muted))
    V.title:SetAlpha(0); V.handle:Hide()
    V.footer = S.CleanText(V.root,5); V.footer:SetPoint("BOTTOMLEFT",0,0); V.footer:SetTextColor(unpack(S.muted)); V.footer:SetAlpha(0)
    V.rows = {}
    for i=1,8 do V.rows[i] = createRow(V.root,i) end
    V.Place(); V.Clear()
end
-- Independent implementation using Blizzard's documented native container API.
local debuffRanks = {
    {[7386]=true,[7405]=true,[8380]=true,[11596]=true,[11597]=true},
    {[1160]=true,[6190]=true,[11554]=true,[11555]=true,[11556]=true},
    {[6343]=true,[8198]=true,[8204]=true,[8205]=true,[11580]=true,[11581]=true},
}
function V.PrepareDebuffs()
    if InCombatLockdown() then return end
    local info=A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo,"CustomAuraContainerTemplate")
    if type(info)~="table" or not A.Access.Readable(info.type) or info.type~="AuraContainer" then return end
    for _,row in ipairs(V.rows) do
        if not row.debuffContainers then
            row.debuffContainers={}
            for i,ids in ipairs(debuffRanks) do
                local index=i
                local container=CreateFrame("AuraContainer",nil,row,"CustomAuraContainerTemplate")
                local level=A.Access.Read(row.GetFrameLevel,row)
                if finite(level) then container:SetFrameLevel(level+10) end
                container:SetSize(12,7); container:SetPoint("TOPLEFT",row,"TOPLEFT",width+2+(i-1)*12,0)
                container:AddAuraGroup("own","HARMFUL|PLAYER",{
                    maxFrameCount=1, candidateFilters={includeSpellIDs=ids},
                    layout={elementWidth=12,elementHeight=7,elementSpacing=0},
                    initializeFrame=function(button)
                        button:SetSize(12,7); button:SetCancelAuraButtons(nil)
                        button:SetTooltipAnchorPoint("ANCHOR_RIGHT")
                        S.Background(button)
                        local label=S.Text(button,5); label:SetPoint("TOPLEFT",0,0); label:SetSize(12,7)
                        label:SetJustifyH("LEFT"); label:SetText(({"S","D","T"})[index])
                        label:SetTextColor(0.28,0.85,0.46,1)
                        if index==1 then
                            local count=S.Text(button,5); count:SetPoint("TOPLEFT",5,0); count:SetSize(7,7)
                            count:SetJustifyH("LEFT"); count:SetTextColor(0.28,0.85,0.46,1)
                            button:SetApplicationCount(count)
                        end
                    end,
                })
                container:SetEnabled(false)
                row.debuffContainers[i]=container
            end
        end
    end
end
function V.ClearRow(row)
    for _,container in ipairs(row.debuffContainers or {}) do container:SetEnabled(false) end
    for _,label in ipairs(row.debuffs) do label:SetText("") end
    clearNative(row)
    row:SetAlpha(0); row.notice:SetText("")
    row.left:SetValue(0); row.right:SetValue(0)
    row.selection:SetAlpha(0); row.rail:SetColorTexture(0.57,0.58,0.61,1); row.unit = nil
end
function V.Clear()
    for _,row in ipairs(V.rows) do V.ClearRow(row) end
    V.footer:SetText("")
end
function V.PaintWarning(row, warning)
    local info = warnings[warning] or warnings.unknown
    row.left:SetStatusBarColor(info[2],info[3],info[4],1)
    row.right:SetStatusBarColor(info[2],info[3],info[4],1)
    for _,lane in ipairs({row.nativeTank,row.nativeRaw}) do
        lane.fill:SetColorTexture(info[2],info[3],info[4],1)
        lane.right:SetStatusBarColor(info[2],info[3],info[4],1)
    end
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
    clearNative(row)
    if not ok then return "?" end
    if not A.Access.Readable(tanking) then
        local leadOK, lead = pcall(UnitThreatPercentageOfLead,"player",unit)
        if not leadOK then lead = nil end
        paintNative(row.nativeTank,lead,true)
        paintNative(row.nativeRaw,rawPercentage,false)
        local tankOK = V.BooleanAlpha(row.nativeTank,tanking,1,0)
        local rawOK = V.BooleanAlpha(row.nativeRaw,tanking,0,1)
        if not tankOK or not rawOK then clearNative(row); return "?" end
        return
    end
    if type(tanking) ~= "boolean" then return "?" end
    local percentage = rawPercentage
    if tanking then
        local leadOK, value = pcall(UnitThreatPercentageOfLead,"player",unit)
        if not leadOK then return "?" end
        percentage = value
    end
    if not A.Access.Readable(percentage) then
        local lane = tanking and row.nativeTank or row.nativeRaw
        paintNative(lane,percentage,tanking); lane:SetAlpha(1)
        return
    end
    if tanking and percentage == 0 then return "-" end
    if tanking and type(percentage) == "number" and percentage >= 0 and percentage < 100 then
        -- Valid low lead readings can shrink to center, never assert a deficit.
        percentage = 100
    end
    if not V.PaintCentered(row,percentage) then return "?" end
end
function V.PaintIdentity(row, unit)
    row.rail:SetColorTexture(0.57,0.58,0.61,1)
    local kind = A.Access.Read(UnitPowerType,unit)
    if kind == 0 then
        local maximum = A.Access.Read(UnitPowerMax,unit,0)
        if type(maximum) == "number" and maximum > 0 then row.rail:SetColorTexture(0.31,0.55,0.80,1) end
    end
end
function V.Paint(row, unit, warning)
    row.unit = unit; row:SetAlpha(1); V.PaintIdentity(row,unit); V.PaintWarning(row,warning)
    A.ThreatModel.PaintDebuffs(row,unit)
    local ok,tanking,_,_,rawPercentage = pcall(UnitDetailedThreatSituation,"player",unit)
    local unavailable = V.PaintRelative(row,unit,ok,tanking,rawPercentage)
    if unavailable and warning ~= "noAggro" then row.notice:SetText(unavailable) end
end
local demoRows = {
    {"War Tank", "lead", 182, false},
    {"Dark Adept", "lead", 160, true},
    {"Bloodfang Scout", "weak", 112, false},
    {"Shadow Mystic", "noLead", 95, true},
    {"Training Hound", "noAggro", 70, false},
    {"Unknown reading", "unknown", nil, false},
    {"Solo comparison", "lead", nil, false, "-"},
    {"Selected enemy", "lead", 145, true},
}
function V.PaintDemo(time)
    local phase = (time%24)/12
    local depth = phase <= 1 and phase or 2-phase
    depth = depth*depth*(3-2*depth)
    for i,sample in ipairs(demoRows) do
        local row = V.rows[i]
        V.ClearRow(row); row:SetAlpha(1)
        local warning, percentage = sample[2],sample[3]
        if i == 2 then
            percentage = 180-110*depth
            if percentage < 85 then warning = "noAggro"
            elseif percentage < 100 then warning = "noLead"
            elseif percentage < 125 then warning = "weak" end
        end
        V.PaintWarning(row,warning)
        if percentage and warning ~= "noAggro" then percentage = math.max(100,percentage) end
        if not V.PaintCentered(row,percentage) then row.notice:SetText(sample[5] or "?") end
        if sample[4] then row.rail:SetColorTexture(0.31,0.55,0.80,1) end
        row.selection:SetAlpha(i == 8 and 1 or 0)
        for j,label in ipairs(row.debuffs) do
            local prefix=({"S","D","T"})[j]
            local active=(i+j)%3~=0
            label:SetText(prefix..(i==6 and "?" or (active and j==1 and tostring(i%5+1) or "")))
            if i==6 then label:SetTextColor(0.65,0.70,0.78,1)
            elseif active then label:SetTextColor(0.28,0.85,0.46,1)
            else label:SetTextColor(0.42,0.45,0.50,1) end
        end
    end
    V.footer:SetText("DEMO")
end
