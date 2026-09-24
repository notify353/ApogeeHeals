local _, A = ...
local S = {}
A.Settings = S
function S.Refresh()
    A.Minimap.Refresh()
    if not S.unlock then return end
    S.unlock:SetChecked(A.View.unlocked)
    S.unlock:SetEnabled(not InCombatLockdown())
    S.reset:SetEnabled(not InCombatLockdown())
    S.bindings:SetEnabled(not InCombatLockdown())
    S.buffs:SetEnabled(not InCombatLockdown())
end
function S.Create()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local panel = CreateFrame("Frame")
    local title = A.Style.Text(panel, 16)
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("Apogee Heals")
    S.unlock = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.unlock:SetPoint("TOPLEFT", 16, -48); S.unlock:SetSize(24, 24)
    local label = A.Style.Text(S.unlock, 12)
    label:SetPoint("LEFT", S.unlock, "RIGHT", 4, 0); label:SetText("Unlock frames")
    S.unlock:SetScript("OnClick", function(self)
        if not InCombatLockdown() then A.View.SetUnlocked(self:GetChecked() == true) end
        S.Refresh()
    end)
    S.reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.reset:SetPoint("TOPLEFT", 16, -88); S.reset:SetSize(160, 24)
    S.reset:SetText("Reset position"); S.reset:SetScript("OnClick", A.View.ResetPosition)
    S.bindings = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.bindings:SetPoint("TOPLEFT", 16, -124); S.bindings:SetSize(180, 24)
    S.bindings:SetText("Edit healing bindings")
    S.bindings:SetScript("OnClick", function() A.BindingEditor.Open() end)
    S.buffs = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.buffs:SetPoint("TOPLEFT", 16, -160); S.buffs:SetSize(180, 24)
    S.buffs:SetText("Buff reminders")
    S.buffs:SetScript("OnClick", function() A.Buffs.OpenPicker() end)
    panel:SetScript("OnShow", S.Refresh)
    S.category = Settings.RegisterCanvasLayoutCategory(panel, "Apogee Heals")
    Settings.RegisterAddOnCategory(S.category); S.Refresh()
end
