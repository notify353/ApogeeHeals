local _, A = ...
local S = {}
A.Settings = S
function S.ResetPositions()
    if InCombatLockdown() then return end
    A.View.Lock(); A.View.pendingPosition = nil
    A.View.ResetPosition(); A.BindingEditor.ResetPosition(); A.Minimap.ResetPosition()
    S.Refresh()
end
function S.Refresh()
    A.Minimap.Refresh()
    if not S.reset then return end
    S.reset:SetEnabled(not InCombatLockdown())
    if S.factoryReset then S.factoryReset:SetEnabled(not InCombatLockdown()) end
    S.buffs:SetEnabled(not InCombatLockdown())
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
    local resetHelp = A.Style.Text(panel, 11)
    resetHelp:SetPoint("TOPLEFT", 16, -124)
    resetHelp:SetText("Reset positions keeps your assignments and buff reminders.")
    -- Matching footer in both addons: native buttons, 250x24, 12px vertical gap.
    S.reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.reset:SetPoint("TOPLEFT", 16, -152); S.reset:SetSize(250, 24)
    S.reset:SetText("Reset positions"); S.reset:SetScript("OnClick", S.ResetPositions)
    StaticPopupDialogs.APOGEE_HEALS_RESET_CHARACTER = {
        text = "Factory reset Apogee Heals for this character?\n\nClears healing assignments, buff reminders and positions and restores defaults. This cannot be undone.\n\nOther characters, other addons and WoW keybindings are unchanged.",
        button1 = "Factory reset", button2 = CANCEL or "Cancel",
        timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function() A.ResetCharacter() end,
    }
    S.factoryReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.factoryReset:SetPoint("TOPLEFT", 16, -188); S.factoryReset:SetSize(250, 24)
    S.factoryReset:SetText("Factory reset")
    S.factoryReset:SetScript("OnClick", function()
        if not InCombatLockdown() then StaticPopup_Show("APOGEE_HEALS_RESET_CHARACTER") end
    end)
    panel:SetScript("OnShow", S.Refresh)
    S.category = Settings.RegisterCanvasLayoutCategory(panel, "Apogee Heals")
    Settings.RegisterAddOnCategory(S.category); S.Refresh()
end
