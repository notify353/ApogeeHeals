local _, A = ...
local V, S = {}, A.Style
A.View = V
local units = { "player", "party1", "party2", "party3", "party4" }
local function bar(parent, height, y, width)
    local result = CreateFrame("StatusBar", nil, parent)
    result:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    result:SetSize(width or S.width, height); result:EnableMouse(false)
    result:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    S.Background(result); A.UnitAPI.Clear(result)
    return result
end
local function buildRow(row, preview, first, width)
    width = width or S.width
    row:SetSize(width, S.clusterHeight)
    row.health = bar(row, S.healthHeight, 0, width)
    row.incoming = A.IncomingHeals.Create(row.health, preview, width)
    -- A separate text layer stays above both the health fill and incoming heals.
    row.nameLayer = CreateFrame("Frame", nil, row.health)
    row.nameLayer:SetAllPoints(row.health)
    row.nameLayer:SetFrameLevel(row.incoming.bar:GetFrameLevel() + 1)
    row.nameLayer:EnableMouse(false)
    row.level = S.Text(row.nameLayer, 8)
    row.level:SetPoint("LEFT", row.health, "LEFT", 4, 0)
    row.level:SetSize(13, S.healthHeight)
    row.level:SetJustifyH("LEFT"); row.level:SetJustifyV("MIDDLE")
    row.level:SetTextColor(unpack(S.muted))
    row.level:SetShadowColor(0, 0, 0, 1); row.level:SetShadowOffset(1, -1)
    row.name = S.Text(row.nameLayer, 8)
    row.name:SetPoint("LEFT", row.health, "LEFT", 18.5, 0)
    row.name:SetSize(width - 22.5, S.healthHeight)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("MIDDLE")
    row.name:SetShadowColor(0, 0, 0, 1); row.name:SetShadowOffset(1, -1)
    row.status = S.Text(row.nameLayer, 8)
    row.status:SetPoint("CENTER", row.health, "CENTER", 0, 0)
    row.status:SetSize(width - 8, S.healthHeight)
    row.status:SetJustifyH("CENTER"); row.status:SetJustifyV("MIDDLE")
    row.status:SetTextColor(unpack(S.muted))
    row.status:SetShadowColor(0, 0, 0, 1); row.status:SetShadowOffset(1, -1)
    row.rangeStatus = S.Text(row.nameLayer, 8)
    row.rangeStatus:SetAllPoints(row.status)
    row.rangeStatus:SetJustifyH("CENTER"); row.rangeStatus:SetJustifyV("MIDDLE")
    row.rangeStatus:SetTextColor(unpack(S.muted)); row.rangeStatus:SetText("OUT OF RANGE")
    row.rangeStatus:Hide()
    -- Smaller artwork in an inset dark frame, attached closely to the row.
    row.drinkIcon = CreateFrame("Frame", nil, row)
    row.drinkIcon:SetSize(12, 12)
    row.drinkIcon:SetPoint("LEFT", row.health, "RIGHT", 2, 0)
    row.drinkIcon:EnableMouse(false)
    local drinkBackground = row.drinkIcon:CreateTexture(nil, "BACKGROUND")
    drinkBackground:SetAllPoints(); drinkBackground:SetColorTexture(0.08, 0.10, 0.13, 1)
    local drinkArtwork = row.drinkIcon:CreateTexture(nil, "ARTWORK")
    drinkArtwork:SetPoint("TOPLEFT", row.drinkIcon, "TOPLEFT", 1, -1)
    drinkArtwork:SetPoint("BOTTOMRIGHT", row.drinkIcon, "BOTTOMRIGHT", -1, 1)
    drinkArtwork:SetTexture("Interface\\Icons\\INV_Drink_07")
    drinkArtwork:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.drinkIcon:Hide()
    row.power = bar(row, S.powerHeight, -(S.healthHeight + S.barGap), width)
    S.RowEdges(row, first, width)
end
function V.ApplyPosition()
    if InCombatLockdown() then return end
    local p = A.db.position
    local minX = -math.max(0, UIParent:GetWidth() / S.scale / 2 - S.width - 15)
    local maxX = math.max(minX, UIParent:GetWidth() / S.scale / 2 - S.width - S.targetGap - S.targetWidth - 15)
    local maxY = math.max(0, UIParent:GetHeight() / S.scale / 2 - S.clusterHeight - S.targetTargetGap - 12)
    local minY = math.min(maxY, -UIParent:GetHeight() / S.scale / 2 + S.stackHeight)
    p.x = math.max(minX, math.min(maxX, p.x))
    p.y = math.max(minY, math.min(maxY, p.y))
    V.root:ClearAllPoints(); V.root:SetPoint("TOPLEFT", UIParent, "CENTER", p.x, p.y)
end
function V.SavePosition()
    if InCombatLockdown() then return end
    local ratio = V.root:GetEffectiveScale() / UIParent:GetEffectiveScale()
    A.db.position = {
        x = V.root:GetLeft() - UIParent:GetWidth() / (2 * ratio),
        y = V.root:GetTop() - UIParent:GetHeight() / (2 * ratio),
    }
    V.ApplyPosition()
end
function V.SetUnlocked(value)
    if not value and V.dragging then V.Lock(); return end
    V.unlocked = value == true and not InCombatLockdown()
    -- The handle is independent of protected frames and can hide on combat entry.
    V.handle:SetShown(V.unlocked)
    A.Preview.SetShown(V.unlocked)
    for _, row in ipairs(V.rows) do row:SetAlpha(V.unlocked and 0 or 1) end
    A.Cleansing.pending = true; A.Cleansing.Refresh()
    A.Buffs.Refresh()
    if A.Runtime.driver then A.Runtime.RangePolling() end
end
local function followHandle()
    if InCombatLockdown() then return end
    local ratio = V.handle:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = V.handle:GetLeft() - UIParent:GetWidth() / (2 * ratio)
    local y = V.handle:GetBottom() - 2 - UIParent:GetHeight() / (2 * ratio)
    V.root:ClearAllPoints(); V.root:SetPoint("TOPLEFT", UIParent, "CENTER", x, y)
end
local function anchorHandle()
    V.handle:ClearAllPoints()
    V.handle:SetPoint("BOTTOMLEFT", V.root, "TOPLEFT", 0, 2)
end
function V.ResetPosition()
    if InCombatLockdown() then return end
    A.db.position = A.Storage.DefaultPosition(); V.ApplyPosition()
end
function V.Create()
    V.rows = {}; V.curve = A.UnitAPI.CreateHealthCurve()
    V.root = CreateFrame("Frame", "ApogeeHealsAnchor", UIParent)
    V.root:SetSize(S.width, S.stackHeight); V.root:SetScale(S.scale)
    V.root:SetClampedToScreen(true); V.ApplyPosition()
    for i, unit in ipairs(units) do
        local row = CreateFrame("Button", "ApogeeHealsUnit" .. i, V.root, "SecureActionButtonTemplate")
        row.unit = unit
        row:SetPoint("TOPLEFT", V.root, "TOPLEFT", 0, -(i - 1) * S.rowHeight)
        row:RegisterForClicks("LeftButtonUp")
        row:SetAttribute("useOnKeyDown", false)
        row:SetAttribute("unit", unit); row:SetAttribute("type1", "target")
        buildRow(row, false, i == 1)
        A.Buffs.Create(row)
        row:Hide()
        RegisterStateDriver(row, "visibility", "[group:raid] hide; [@" .. unit .. ",exists] show; hide")
        V.rows[i] = row
    end
    -- Separate immutable recipients; never enter healing bindings or buff scans.
    local function targetRow(unit)
        local row = CreateFrame("Button", nil, V.root, "SecureActionButtonTemplate")
        row.unit = unit
        buildRow(row, false, false, S.targetWidth)
        row:RegisterForClicks("LeftButtonUp")
        row:SetAttribute("useOnKeyDown", false)
        row:SetAttribute("unit", unit); row:SetAttribute("type1", "target")
        row:Hide()
        return row
    end
    V.target = targetRow("target")
    V.target:SetPoint("BOTTOMLEFT", V.rows[1].power, "BOTTOMRIGHT", S.targetGap, 0)
    RegisterStateDriver(V.target, "visibility", "[@target,exists] show; hide")
    V.targetTarget = targetRow("targettarget")
    V.targetTarget:SetPoint("BOTTOMLEFT", V.target, "TOPLEFT", 0, S.targetTargetGap)
    local caption = S.CleanText(V.targetTarget, 6)
    caption:SetPoint("BOTTOMLEFT", V.targetTarget, "TOPLEFT", 0, 2)
    caption:SetSize(S.targetWidth, 8); caption:SetJustifyH("LEFT")
    caption:SetTextColor(unpack(S.muted)); caption:SetText("Target's target")
    V.targetTarget.caption = caption
    local elapsed = 0
    V.targetTarget:SetScript("OnShow", function() elapsed = 0; V.RefreshTargetTarget() end)
    V.targetTarget:SetScript("OnHide", function() elapsed = 0 end)
    V.targetTarget:SetScript("OnUpdate", function(_, delta)
        if A.Runtime.suspended then return end
        elapsed = elapsed + delta
        if elapsed < 0.2 then return end
        elapsed = 0; V.RefreshTargetTarget()
    end)
    RegisterStateDriver(V.targetTarget, "visibility", "[@targettarget,exists] show; hide")
    A.Preview.Create(V.root, buildRow)
    V.handle = CreateFrame("Button", nil, UIParent)
    V.handle:SetScale(S.scale); V.handle:SetSize(S.width, 10)
    V.handle:SetMovable(true); V.handle:SetClampedToScreen(true); anchorHandle()
    S.Background(V.handle)
    local text = S.CleanText(V.handle, 6.5); text:SetAllPoints(); text:SetText("Preview - drag to move")
    text:SetTextColor(unpack(S.muted))
    V.handle:RegisterForDrag("LeftButton")
    V.handle:SetScript("OnDragStart", function()
        if V.unlocked and not InCombatLockdown() then
            V.handle:StartMoving(); V.dragging = true
            V.handle:SetScript("OnUpdate", followHandle)
        end
    end)
    V.handle:SetScript("OnDragStop", function()
        if not V.dragging then return end
        V.Lock()
    end)
    V.SetUnlocked(false)
    if A.Settings then A.Settings.Refresh() end
end
function V.Lock()
    if V.dragging then
        followHandle()
        V.handle:StopMovingOrSizing(); V.handle:SetScript("OnUpdate", nil); V.dragging = false
        if not InCombatLockdown() then V.SavePosition() else V.pendingPosition = true end
        anchorHandle()
    end
    V.SetUnlocked(false)
    if A.Settings then A.Settings.Refresh() end
end
function V.PaintRange(row, state)
    local result
    if not V.unlocked and not A.Runtime.suspended and state == "alive" and A.Bindings.rangeSpell then
        result = A.Access.Read(C_Spell and C_Spell.IsSpellInRange, A.Bindings.rangeSpell, row.unit)
    end
    -- Only a public boolean false establishes out-of-range. Unknown clears stale feedback.
    local outside = result == false
    row.rangeStatus:SetShown(outside)
    row:SetAlpha(V.unlocked and 0 or (outside and 0.45 or 1))
    local showName = not outside and state ~= "missing" and state ~= "dead" and state ~= "offline"
        and not InCombatLockdown()
    row.name:SetShown(showName); row.level:SetShown(showName)
end
function V.RefreshRange()
    for _, row in ipairs(V.rows) do V.PaintRange(row, A.UnitAPI.State(row.unit)) end
end
local function refreshTargetRow(row)
    A.UnitAPI.PaintTargetIdentity(row)
    -- Unknown/restricted state must not prevent native health/power display.
    if A.Access.Read(UnitExists, row.unit) == false then
        A.UnitAPI.Clear(row.health); A.UnitAPI.Clear(row.power)
        A.IncomingHeals.Clear(row.incoming)
        return
    end
    if A.UnitAPI.PaintHealth(row.health, row.unit, V.curve) then
        A.IncomingHeals.Paint(row.incoming, row.unit)
    else A.IncomingHeals.Clear(row.incoming) end
    A.UnitAPI.PaintPower(row.power, row.unit)
end
function V.RefreshTargetTarget()
    if not A.Runtime.suspended then refreshTargetRow(V.targetTarget) end
end
function V.RefreshTarget()
    refreshTargetRow(V.target)
    V.RefreshTargetTarget()
end
function V.Refresh()
    V.RefreshTarget()
    for _, row in ipairs(V.rows) do
        local state = A.UnitAPI.State(row.unit)
        local classOK, _, classToken = pcall(UnitClass, row.unit)
        if not classOK then classToken = nil end
        A.UnitAPI.PaintClassStrip(row.classStrip, classToken)
        row.name:SetText(""); row.level:SetText(""); row.status:SetText("")
        row.drinkIcon:Hide()
        local showName = state ~= "missing" and state ~= "dead" and state ~= "offline"
            and not InCombatLockdown()
        row.name:SetShown(showName)
        row.level:SetShown(showName)
        if showName then
            A.UnitAPI.PaintName(row.name, row.unit)
            A.UnitAPI.PaintLevel(row.level, row.unit)
        end
        if state == "alive" then
            if A.UnitAPI.PaintHealth(row.health, row.unit, V.curve) then
                A.IncomingHeals.Paint(row.incoming, row.unit)
            else A.IncomingHeals.Clear(row.incoming) end
            A.UnitAPI.PaintPower(row.power, row.unit)
            row.drinkIcon:SetShown(A.Drinking.IsDrinking(row.unit))
        else
            A.UnitAPI.Clear(row.health); A.UnitAPI.Clear(row.power)
            A.IncomingHeals.Clear(row.incoming)
            if state == "offline" then row.status:SetText("OFFLINE")
            elseif state == "dead" then row.status:SetText("DEAD") end
        end
        V.PaintRange(row, state)
    end
end
