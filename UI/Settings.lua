local addonName, A = ...
-- Each independent addon joins one family-local native settings parent.
local function RegisterApogeeCategory(panel, label, standaloneTitle)
    if type(Settings.RegisterCanvasLayoutSubcategory) ~= "function" then
        return Settings.RegisterCanvasLayoutCategory(panel, standaloneTitle)
    end
    local registry = _G.ApogeeSettingsRegistry
    if registry ~= nil and (type(registry) ~= "table" or registry.schema ~= 1
        or type(registry.category) ~= "table" or type(registry.category.GetID) ~= "function"
        or type(registry.children) ~= "table") then return nil end
    if not registry then
        local parentName = addonName:sub(-3) == "Dev" and "Apogee DEV" or "Apogee"
        local overview = CreateFrame("Frame")
        local title = overview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16); title:SetText(parentName)
        local description = overview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        description:SetPoint("TOPLEFT", 16, -52)
        description:SetText("Select an enabled addon's settings from the list on the left.")
        local parent = Settings.RegisterCanvasLayoutCategory(overview, parentName)
        Settings.RegisterAddOnCategory(parent)
        registry = {schema = 1, category = parent, children = {}}
        _G.ApogeeSettingsRegistry = registry
    end
    local existing = registry.children[label]
    if existing ~= nil then
        if type(existing) == "table" and type(existing.GetID) == "function" then return existing end
        return nil
    end
    local category = Settings.RegisterCanvasLayoutSubcategory(registry.category, panel, label)
    registry.children[label] = category
    return category
end

local S = {}
A.Settings = S
function S.ResetPositions()
    if InCombatLockdown() then return end
    A.View.Lock(); A.View.pendingPosition = nil
    A.View.ResetPosition(); A.BindingEditor.ResetPosition(); A.Minimap.ResetPosition()
    if A.ThreatView.root then A.ThreatView.ResetPosition() end
    S.Refresh()
end
function S.Refresh()
    A.Minimap.Refresh()
    if not S.defaults then return end
    S.defaults:SetEnabled(not InCombatLockdown())
    S.buffs:SetEnabled(not InCombatLockdown())
    if S.threat then
        S.threat:SetEnabled(not InCombatLockdown())
        S.threat:SetChecked(A.db.threatEnabled == true)
    end
    S.cleanseStatus:SetText(A.Cleansing.status or "Purify configuration is pending.")
    if S.threatDiagnostics then
        S.threatDiagnostics:SetEnabled(not InCombatLockdown())
        S.threatDiagnostics:SetChecked(A.ThreatDiagnostics.enabled)
    end
    if S.threatDemo then
        S.threatDemo:SetEnabled(not InCombatLockdown())
        S.threatDemo:SetChecked(A.Threat.demo == true)
    end
end
function S.Create()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local panel = CreateFrame("Frame")
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetColorTexture(0.035, 0.035, 0.045, 0.96)
    local title = A.Style.Text(panel, 16)
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("Apogee Heals")
    S.buffs = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.buffs:SetPoint("TOPLEFT", 16, -48); S.buffs:SetSize(180, 24)
    S.buffs:SetText("Buff reminders")
    S.buffs:SetScript("OnClick", function() A.Buffs.OpenPicker() end)
    S.cleanseStatus = A.Style.Text(panel, 11)
    S.cleanseStatus:SetPoint("TOPLEFT", 16, -88)
    S.threat = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threat:SetPoint("TOPLEFT", 12, -114); S.threat:SetSize(24, 24)
    local threatLabel = A.Style.Text(panel, 11)
    threatLabel:SetPoint("LEFT", S.threat, "RIGHT", 4, 0); threatLabel:SetText("Tank threat stack")
    S.threat:SetScript("OnClick", function(button) A.Threat.SetEnabled(button:GetChecked()); S.Refresh() end)
    S.threatDiagnostics = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threatDiagnostics:SetPoint("TOPLEFT", 12, -146); S.threatDiagnostics:SetSize(24, 24)
    local diagnosticLabel = A.Style.Text(panel, 11)
    diagnosticLabel:SetPoint("LEFT", S.threatDiagnostics, "RIGHT", 4, 0)
    diagnosticLabel:SetText("Threat checks (freeze after combat; until reload)")
    S.threatDiagnostics:SetScript("OnClick", function(button)
        A.ThreatDiagnostics.SetEnabled(button:GetChecked()); S.Refresh()
    end)
    S.threatDemo = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threatDemo:SetPoint("TOPLEFT", 12, -178); S.threatDemo:SetSize(24, 24)
    local demoLabel = A.Style.Text(panel, 11)
    demoLabel:SetPoint("LEFT", S.threatDemo, "RIGHT", 4, 0)
    demoLabel:SetText("Threat demo (solo preview; ends in combat)")
    S.threatDemo:SetScript("OnClick", function(button) A.Threat.SetDemo(button:GetChecked()) end)
    StaticPopupDialogs.APOGEE_HEALS_RESET_CHARACTER = {
        text = "Restore Apogee Heals defaults for this character?\n\nClears healing assignments, buff reminders and positions and restores defaults. This cannot be undone.\n\nOther characters, other addons and WoW keybindings are unchanged.",
        button1 = "Defaults", button2 = CANCEL or "Cancel",
        timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function() A.ResetCharacter() end,
    }
    S.defaults = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.defaults:SetPoint("TOPRIGHT", -16, -12); S.defaults:SetSize(100, 24)
    S.defaults:SetText("Defaults")
    S.defaults:SetScript("OnClick", function()
        if not InCombatLockdown() then StaticPopup_Show("APOGEE_HEALS_RESET_CHARACTER") end
    end)
    panel.OnDefault = function() A.ResetCharacter() end
    panel:SetScript("OnShow", S.Refresh)
    S.category = RegisterApogeeCategory(panel, "Heals", "Apogee Heals")
    if not S.category then return end
    Settings.RegisterAddOnCategory(S.category); S.Refresh()
end
