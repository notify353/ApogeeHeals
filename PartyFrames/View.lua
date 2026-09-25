local _, A = ...
local V, S = {}, A.Style
A.View = V
local units = { "player", "party1", "party2", "party3", "party4" }
local function bar(parent, height, y)
    local result = CreateFrame("StatusBar", nil, parent)
    result:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    result:SetSize(S.width, height); result:EnableMouse(false)
    result:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    S.Background(result); A.UnitAPI.Clear(result)
    return result
end
local function buildRow(row, preview, first)
    row:SetSize(S.width, S.clusterHeight)
    row.health = bar(row, S.healthHeight, 0)
    row.incoming = A.IncomingHeals.Create(row.health, preview)
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
    row.name:SetSize(S.width - 22.5, S.healthHeight)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("MIDDLE")
    row.name:SetShadowColor(0, 0, 0, 1); row.name:SetShadowOffset(1, -1)
    row.status = S.Text(row.nameLayer, 8)
    row.status:SetPoint("CENTER", row.health, "CENTER", 0, 0)
    row.status:SetSize(S.width - 8, S.healthHeight)
    row.status:SetJustifyH("CENTER"); row.status:SetJustifyV("MIDDLE")
    row.status:SetTextColor(unpack(S.muted))
    row.status:SetShadowColor(0, 0, 0, 1); row.status:SetShadowOffset(1, -1)
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
    row.power = bar(row, S.powerHeight, -(S.healthHeight + S.barGap))
    S.RowEdges(row, first)
end
function V.ApplyPosition()
    if InCombatLockdown() then return end
    local p = A.db.position
    local maxX = math.max(0, UIParent:GetWidth() / S.scale / 2 - S.width - 15)
    local maxY = math.max(0, UIParent:GetHeight() / S.scale / 2 - 18)
    local minY = math.min(maxY, -UIParent:GetHeight() / S.scale / 2 + S.stackHeight)
    p.x = math.max(-maxX, math.min(maxX, p.x))
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
function V.Refresh()
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
    end
end
