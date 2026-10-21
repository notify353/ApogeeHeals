local _, A = ...
local V, S = {}, A.Style
A.View = V
local units = { "player", "party1", "party2", "party3", "party4" }
local function eligibleTarget()
    local read = A.Access.Read
    return read(UnitExists, "target") == true
        and read(UnitIsPlayer, "target") == true
        and read(UnitCanAssist, "player", "target") == true
        and read(UnitIsUnit, "player", "target") == false
end
local function partyActionReason(row, inspect, checkRange, talents)
    local read = A.Access.Read
    if InCombatLockdown() then return "Unavailable during combat." end
    if not eligibleTarget() then return "Select another friendly player." end
    if A.Runtime.suspended or V.unlocked then return "Unavailable while moving frames or loading." end
    if read(UnitExists, row.unit) ~= true or read(UnitIsConnected, row.unit) ~= true
        or read(UnitIsDeadOrGhost, "player") ~= false then return "Player unavailable." end
    if inspect then
        if talents then
            if type(NotifyInspect) ~= "function" or type(PlayerSpellsUtil) ~= "table"
                or type(PlayerSpellsUtil.OpenToClassTalentsTab) ~= "function" then
                return "Talent inspection unavailable."
            end
        elseif type(InspectUnit) ~= "function" then return "Inspect unavailable." end
        if checkRange and (read(CanInspect, row.unit) ~= true
            or read(CheckInteractDistance, row.unit, 1) ~= true) then
            return "Move closer to inspect this player."
        end
    else
        if type(FollowUnit) ~= "function" then return "Follow unavailable." end
        if read(UnitIsDeadOrGhost, row.unit) ~= false then return "Cannot follow a dead player." end
        if checkRange and read(CheckInteractDistance, row.unit, 4) ~= true then
            return "Move closer to follow this player."
        end
    end
end
local talentRequest, talentEvents
local function cancelTalentRequest()
    talentRequest = nil
    if talentEvents then talentEvents:UnregisterAllEvents() end
end
local function inspectTalents(row)
    cancelTalentRequest()
    local guid = A.Access.Read(UnitGUID, row.unit)
    if type(guid) ~= "string" or guid == "" then return end
    if not talentEvents then
        talentEvents = CreateFrame("Frame")
        talentEvents:SetScript("OnEvent", function(_, event, inspectedGUID)
            local request = talentRequest
            if not request then return end
            if event ~= "INSPECT_READY" then cancelTalentRequest(); return end
            if not A.Access.Readable(inspectedGUID) or inspectedGUID ~= request.guid then return end
            cancelTalentRequest()
            if partyActionReason(request.row, true, true, true)
                or A.Access.Read(UnitGUID, request.row.unit) ~= request.guid then return end
            PlayerSpellsUtil.OpenToClassTalentsTab(request.row.unit)
        end)
    end
    local request = {row = row, guid = guid}
    talentRequest = request
    for _, event in ipairs({"INSPECT_READY", "PLAYER_REGEN_DISABLED", "GROUP_ROSTER_UPDATE",
        "PLAYER_LEAVING_WORLD", "PLAYER_TARGET_CHANGED"}) do talentEvents:RegisterEvent(event) end
    -- Never leave a request able to open a window long after its initiating click.
    C_Timer.After(5, function()
        if talentRequest == request then cancelTalentRequest() end
    end)
    NotifyInspect(row.unit)
end
function V.RefreshPartyActions()
    local row, strip = V.target, V.targetActions
    if not strip then return end
    -- The native parent owns combat visibility; only ordinary content is toggled.
    if not InCombatLockdown() then
        local available = partyActionReason(row, false, true) == nil
            and partyActionReason(row, true, true) == nil
            and partyActionReason(row, true, true, true) == nil
        strip.content:SetShown(available)
    end
    for index, button in ipairs(row.partyActions) do
        local available = partyActionReason(row, index >= 2, false, index == 3) == nil
        button:SetEnabled(available)
        button.icon:SetAlpha(available and (button.hovered and 1 or 0.75) or 0.25)
        button.highlight:SetAlpha(available and button.hovered and 0.12 or 0)
        if not available and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end
end
local function createTargetActions(row)
    local strip = CreateFrame("Frame", nil, V.root)
    strip:SetSize(56, 16)
    strip:SetPoint("TOP", row, "BOTTOM", 0, -2)
    strip:EnableMouse(false)
    V.targetActions = strip
    RegisterStateDriver(strip, "visibility", "[combat] hide; [@target,help,exists] show; hide")
    strip.content = CreateFrame("Frame", nil, strip)
    strip.content:SetAllPoints(); strip.content:EnableMouse(false)
    strip.content:Hide()
    row.partyActions = {}
    local width, gap = 16, 4
    for index, label in ipairs({"Follow", "Inspect", "Talents"}) do
        local inspect, talents = index >= 2, index == 3
        local button = CreateFrame("Button", nil, strip.content)
        button:SetSize(width, 16)
        button:SetPoint("LEFT", strip.content, "LEFT", (index - 1) * (width + gap), 0)
        button:SetPropagateMouseClicks(false)
        button:RegisterForClicks("LeftButtonUp")
        button.highlight = button:CreateTexture(nil, "BACKGROUND")
        button.highlight:SetAllPoints(); button.highlight:SetColorTexture(0.65, 0.78, 1, 1)
        button.highlight:SetAlpha(0)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        local iconSize = talents and 13 or 10
        button.icon:SetSize(iconSize, iconSize)
        button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        if talents then button.icon:SetAtlas("UI-HUD-MicroMenu-SpecTalents-Up", false)
        elseif inspect then button.icon:SetAtlas("common-icon-search", false)
        else button.icon:SetTexture("Interface\\Icons\\Ability_Tracking") end
        button.icon:SetDesaturated(not talents)
        button.icon:SetAlpha(0.75)
        button:SetScript("OnEnter", function()
            if InCombatLockdown() then return end
            button.hovered = true
            V.RefreshPartyActions()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(talents and "Inspect Talents" or label)
            GameTooltip:AddLine(partyActionReason(row, inspect, true, talents) or
                (talents and "View this player's talent points."
                or inspect and "Inspect this player." or "Follow this player."), 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        local function hideTooltip()
            button.hovered = false
            button.icon:SetAlpha(0.75)
            button.highlight:SetAlpha(0)
            if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
        end
        button:SetScript("OnLeave", hideTooltip)
        button:SetScript("OnHide", hideTooltip)
        button:SetScript("OnClick", function(_, mouseButton)
            if mouseButton ~= "LeftButton" or partyActionReason(row, inspect, true, talents) then return end
            -- Resolve the current target at the click; never retarget or queue follow.
            if talents then inspectTalents(row)
            elseif inspect then cancelTalentRequest(); InspectUnit(row.unit)
            else FollowUnit(row.unit) end
        end)
        row.partyActions[index] = button
    end
end
local roleAtlases = {
    TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer", DAMAGER = "roleicon-tiny-dps",
}
function V.PaintRole(row, role)
    local atlas = A.Access.Readable(role) and type(role) == "string" and roleAtlases[role]
    if atlas then row.roleIcon:SetAtlas(atlas, false) end
    row.roleIcon:SetShown(atlas ~= nil and atlas ~= false)
end
local function createDebuffs(row)
    -- All aura selection, ordering, visibility and updates stay in native code.
    -- Never retain or inspect the native aura buttons after initialization.
    local info = A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
    if not info or not A.Access.Readable(info.type) or info.type ~= "AuraContainer" then return end
    local container = CreateFrame("AuraContainer", nil, row.supportFrame or row, "CustomAuraContainerTemplate")
    local size, gap = S.sideIconSize, S.sideIconGap
    local offset = (row.unit == "target" and S.sideIconGap or S.sideIconOffset)
        + (row.cleanseSlotCount or 0) * (size + gap)
    container:SetPoint("TOPLEFT", row.health, "TOPRIGHT", offset, A.Style.sideIconY)
    container:SetSize(8 * size + 7 * gap, size)
    container:SetUnit(row.unit)
    container:AddAuraGroup("debuffs", "HARMFUL", {
        maxFrameCount = 8,
        layout = { elementSpacing = gap, elementWidth = size, elementHeight = size },
        initializeFrame = function(button)
            button:SetSize(size, size)
            button:SetCancelAuraButtons(nil)
            button:SetTooltipAnchorPoint("ANCHOR_RIGHT")
            local background = button:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints(); background:SetColorTexture(0.35, 0.08, 0.08, 1)
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            button:SetIcon(icon)
        end,
    })
    container:SetEnabled(true)
    row.debuffContainer = container
end
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
    -- The class rail is never part of the secure healing/targeting hit area.
    if not preview then row:SetHitRectInsets(S.classStripHitWidth, 0, 0, 0) end
    row.health = bar(row, S.healthHeight, 0, width)
    row.incoming = A.IncomingHeals.Create(row.health, preview, width)
    -- A separate text layer stays above both the health fill and incoming heals.
    row.nameLayer = CreateFrame("Frame", nil, row.health)
    row.nameLayer:SetAllPoints(row.health)
    row.nameLayer:SetFrameLevel(row.incoming.bar:GetFrameLevel() + 1)
    row.nameLayer:EnableMouse(false)
    local indicatorSpace = 0
    if preview or row.unit == "player" or row.unit:match("^party%d$") then
        indicatorSpace = 20
        row.leader = row.nameLayer:CreateTexture(nil, "OVERLAY")
        row.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        row.leader:SetSize(8, 8)
        row.leader:SetPoint("RIGHT", row.health, "RIGHT", -12, 0)
        row.leader:Hide()
        row.roleIcon = row.nameLayer:CreateTexture(nil, "OVERLAY")
        row.roleIcon:SetSize(8, 8)
        row.roleIcon:SetPoint("RIGHT", row.health, "RIGHT", -2, 0)
        row.roleIcon:Hide()
    end
    -- Match the name font so two-digit levels fit the reserved level column.
    row.level = S.Text(row.nameLayer, 6)
    row.level:SetPoint("LEFT", row.health, "LEFT", 4, 0)
    row.level:SetSize(13, S.healthHeight)
    row.level:SetJustifyH("LEFT"); row.level:SetJustifyV("MIDDLE")
    row.level:SetTextColor(unpack(S.muted))
    row.level:SetShadowColor(0, 0, 0, 1); row.level:SetShadowOffset(1, -1)
    row.name = S.Text(row.nameLayer, 6)
    row.name:SetPoint("LEFT", row.health, "LEFT", 18.5, 0)
    row.name:SetSize(width - 22.5 - indicatorSpace, S.healthHeight)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("MIDDLE")
    row.name:SetShadowColor(0, 0, 0, 1); row.name:SetShadowOffset(1, -1)
    row.status = S.Text(row.nameLayer, 8)
    row.status:SetPoint("CENTER", row.health, "CENTER", -indicatorSpace / 2, 0)
    row.status:SetSize(width - 8 - indicatorSpace, S.healthHeight)
    row.status:SetJustifyH("CENTER"); row.status:SetJustifyV("MIDDLE")
    row.status:SetTextColor(unpack(S.muted))
    row.status:SetShadowColor(0, 0, 0, 1); row.status:SetShadowOffset(1, -1)
    row.rangeStatus = S.Text(row.nameLayer, 8)
    row.rangeStatus:SetAllPoints(row.status)
    row.rangeStatus:SetJustifyH("CENTER"); row.rangeStatus:SetJustifyV("MIDDLE")
    row.rangeStatus:SetTextColor(unpack(S.muted)); row.rangeStatus:SetText("")
    row.rangeStatus:Hide()
    -- Smaller artwork in an inset dark frame, attached closely to the row.
    row.drinkIcon = CreateFrame("Frame", nil, row)
    row.drinkIcon:SetSize(S.sideIconSize, S.sideIconSize)
    row.drinkIcon:SetPoint("TOPLEFT", row.health, "TOPRIGHT", S.sideIconGap, A.Style.sideIconY)
    row.drinkIcon:EnableMouse(false)
    local drinkBackground = row.drinkIcon:CreateTexture(nil, "BACKGROUND")
    drinkBackground:SetAllPoints(); drinkBackground:SetColorTexture(0.08, 0.10, 0.13, 1)
    local drinkArtwork = row.drinkIcon:CreateTexture(nil, "ARTWORK")
    drinkArtwork:SetPoint("TOPLEFT", row.drinkIcon, "TOPLEFT", 1, -1)
    drinkArtwork:SetPoint("BOTTOMRIGHT", row.drinkIcon, "BOTTOMRIGHT", -1, 1)
    drinkArtwork:SetTexture("Interface\\Icons\\INV_Drink_07")
    drinkArtwork:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.drinkArtwork = drinkArtwork
    row.drinkIcon:Hide()
    A.Drinking.CreateTooltip(row, preview)
    A.Drinking.CreateTimer(row, preview)
    row.power = bar(row, S.powerHeight, -(S.healthHeight + S.barGap), width)
    if not preview then
        local top = -(S.healthHeight + S.barGap)
        row.manaPower = bar(row, S.powerHeight / 2, top, width)
        row.formPower = bar(row, S.powerHeight / 2, top - S.powerHeight / 2, width)
        row.manaPower:SetAlpha(0); row.formPower:SetAlpha(0)
    end
    S.RowEdges(row, first, width)
end
function V.ApplyPosition()
    if InCombatLockdown() then return end
    local p = A.db.position
    local minX = -math.max(0, UIParent:GetWidth() / S.scale / 2 - S.width - 15)
    local maxX = math.max(minX, UIParent:GetWidth() / S.scale / 2 - S.width - 15)
    local maxY = math.max(0, UIParent:GetHeight() / S.scale / 2 - S.handleOffset - 10)
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
    V.RefreshPartyActions()
    for _, row in ipairs(V.rows) do row:SetAlpha(V.unlocked and 0 or 1) end
    A.Cleansing.pending = true; A.Cleansing.Refresh()
    A.Buffs.Refresh()
    if A.Runtime.driver then A.Runtime.RangePolling() end
end
local function followHandle()
    if InCombatLockdown() then return end
    local ratio = V.handle:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = V.handle:GetLeft() - UIParent:GetWidth() / (2 * ratio)
    local y = V.handle:GetBottom() - S.handleOffset - UIParent:GetHeight() / (2 * ratio)
    V.root:ClearAllPoints(); V.root:SetPoint("TOPLEFT", UIParent, "CENTER", x, y)
end
local function anchorHandle()
    V.handle:ClearAllPoints()
    V.handle:SetPoint("BOTTOMLEFT", V.root, "TOPLEFT", 0, S.handleOffset)
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
        A.Cleansing.Create(row)
        createDebuffs(row)
        A.Buffs.Create(row)
        row:Hide()
        RegisterStateDriver(row, "visibility", "[group:raid] hide; [@" .. unit .. ",exists] show; hide")
        V.rows[i] = row
    end
    -- Separate immutable recipients share healing bindings, but not party buff scans.
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
    V.target.supportFrame = CreateFrame("Frame", nil, V.target, "SecureHandlerStateTemplate")
    V.target.supportFrame:SetAllPoints(V.target)
    V.target.supportFrame:EnableMouse(false)
    RegisterStateDriver(V.target.supportFrame, "visibility", "[@target,help,nodead] show; hide")
    A.Cleansing.Create(V.target)
    createDebuffs(V.target)
    A.Buffs.Create(V.target)
    V.supportRows = {unpack(V.rows)}
    V.supportRows[#V.supportRows + 1] = V.target
    V.target:SetPoint("BOTTOMLEFT", V.rows[1], "TOPLEFT", 0, S.targetGap)
    createTargetActions(V.target)
    V.target.cast = bar(V.target, S.powerHeight, -(S.healthHeight + S.barGap), S.targetWidth)
    V.target.cast:SetAlpha(0)
    RegisterStateDriver(V.target, "visibility", "[@target,exists] show; hide")
    V.targetTarget = targetRow("targettarget")
    V.targetTarget:SetPoint("BOTTOMLEFT", V.target, "TOPLEFT", 0, S.targetTargetGap)
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
    V.target:SetScript("OnShow", function() if not A.Runtime.suspended then V.RefreshTarget() end end)
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
local function proximity(unit)
    if unit == "player" or A.Access.Read(UnitIsUnit, unit, "player") == true then return true end
    if type(UnitDistanceSquared) ~= "function" then return nil end
    local ok, distance, checked = pcall(UnitDistanceSquared, unit)
    if ok and A.Access.Readable(distance, checked) and checked == true
        and type(distance) == "number" and distance >= 0 and distance < math.huge then
        return distance <= 40 * 40
    end
end
function V.PaintRange(row, state)
    local result
    if not V.unlocked and not A.Runtime.suspended and state == "alive" then
        if A.Bindings.rangeSpell then
            -- Unknown spell range stays unknown; distance cannot prove cast range.
            result = A.Bindings.SpellRange(A.Bindings.rangeSpell, row.unit)
        else
            result = proximity(row.unit)
        end
    end
    row.rangeStatus:Hide()
    -- Only health artwork (including its text/incoming heals) inherits the fade.
    -- Buff buttons are siblings, so their own spell range remains independent.
    row.health:SetAlpha(result == false and 0.45 or 1)
    row:SetAlpha(V.unlocked and 0 or 1)
    local showName = state ~= "missing" and state ~= "dead" and state ~= "offline"
    row.name:SetShown(showName); row.level:SetShown(showName)
end
function V.RefreshRange()
    V.RefreshPartyActions()
    for _, row in ipairs(V.rows) do V.PaintRange(row, A.UnitAPI.State(row.unit)) end
    for _, row in ipairs({V.target, V.targetTarget}) do
        V.PaintRange(row, A.UnitAPI.State(row.unit))
    end
end
local function refreshTargetRow(row)
    A.UnitAPI.PaintTargetIdentity(row)
    -- Unknown/restricted state must not prevent native health/power display.
    if A.Access.Read(UnitExists, row.unit) == false then
        if row.cast then V.ClearTargetCast() end
        A.UnitAPI.Clear(row.health); A.UnitAPI.ClearRowPower(row)
        A.IncomingHeals.Clear(row.incoming)
        return
    end
    if A.UnitAPI.PaintHealth(row.health, row.unit, V.curve) then
        A.IncomingHeals.Paint(row.incoming, row.unit)
    else A.IncomingHeals.Clear(row.incoming) end
    local casting = row.cast and not A.Runtime.suspended and A.UnitAPI.PaintCast(row.cast, row.unit)
    if row.cast then row.cast:SetAlpha(casting and 1 or 0) end
    A.UnitAPI.PaintRowPower(row, casting)
end
function V.ClearTargetCast()
    V.target.cast:SetAlpha(0); A.UnitAPI.PaintRowPower(V.target)
end
function V.RefreshTargetTarget()
    if not A.Runtime.suspended then refreshTargetRow(V.targetTarget) end
end
function V.RefreshTargetAuras()
    -- Only invoke the public inbound refresh; never inspect native aura state.
    for _, key in ipairs({"debuffContainer", "cleanseIndicator"}) do
        local container = V.target[key]
        if container and type(container.UpdateAllAuras) == "function" then container:UpdateAllAuras() end
    end
end
function V.RefreshTarget()
    V.RefreshPartyActions()
    refreshTargetRow(V.target)
    V.RefreshTargetTarget()
end
function V.Refresh()
    V.RefreshTarget()
    local showIndicators = not InCombatLockdown() and not A.Runtime.suspended
    for _, row in ipairs(V.rows) do
        local state = A.UnitAPI.State(row.unit)
        row.leader:SetShown(showIndicators
            and A.Access.Read(UnitExists, "party1") == true
            and A.Access.Read(UnitExists, row.unit) == true
            and A.Access.Read(UnitIsGroupLeader, row.unit) == true)
        local role
        if showIndicators and A.Access.Read(UnitExists, row.unit) == true then
            role = A.Access.Read(UnitGroupRolesAssigned, row.unit)
        end
        V.PaintRole(row, role)
        local classOK, _, classToken = pcall(UnitClass, row.unit)
        if not classOK then classToken = nil end
        A.UnitAPI.PaintClassStrip(row.classStrip, classToken)
        row.name:SetText(""); row.level:SetText(""); row.status:SetText("")
        local showName = state ~= "missing" and state ~= "dead" and state ~= "offline"
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
            A.UnitAPI.PaintRowPower(row)
            A.Drinking.Paint(row)
        else
            A.Drinking.Clear(row)
            A.UnitAPI.Clear(row.health); A.UnitAPI.ClearRowPower(row)
            A.IncomingHeals.Clear(row.incoming)
            if state == "offline" then row.status:SetText("OFFLINE")
            elseif state == "dead" then row.status:SetText("DEAD") end
        end
        V.PaintRange(row, state)
    end
end
