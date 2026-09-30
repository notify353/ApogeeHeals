local _, A = ...
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
        S.threat:SetChecked(A.db.threatEnabled ~= false)
    end
    S.cleanseStatus:SetText(A.Cleansing.status or "Purify configuration is pending.")
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
    S.category = Settings.RegisterCanvasLayoutCategory(panel, "Apogee Heals")
    Settings.RegisterAddOnCategory(S.category); S.Refresh()
end
