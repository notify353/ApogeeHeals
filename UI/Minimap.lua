-- Interaction pattern adapted from Apogee Keybinds (MIT, copyright 2026 notify353).
local _, A = ...
local M = {}
A.Minimap = M
function M.Refresh()
    if not M.button then return end
    M.button:SetEnabled(not InCombatLockdown())
    local open = A.BindingEditor.frame and A.BindingEditor.frame:IsShown()
    if open then M.border:SetVertexColor(1, 0.8, 0.3)
    else M.border:SetVertexColor(1, 1, 1) end
end
function M.Create()
    if M.button or not Minimap then return end
    local button = CreateFrame("Button", "ApogeeHealsMinimapButton", Minimap)
    M.button = button; button:SetSize(32, 32)
    -- Opposite Keybinds' bottom-left button so both remain accessible.
    button:SetPoint("CENTER", Minimap, "BOTTOMRIGHT", -12, 12)
    button:SetFrameStrata("MEDIUM")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface/Icons/Spell_Holy_Heal")
    local border = button:CreateTexture(nil, "OVERLAY"); M.border = border
    border:SetSize(54, 54); border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouseButton)
        if InCombatLockdown() then return end
        GameTooltip:Hide()
        if mouseButton == "LeftButton" then
            if A.BindingEditor.frame and A.BindingEditor.frame:IsShown() then A.BindingEditor.Close()
            else A.BindingEditor.Open() end
        elseif mouseButton == "RightButton" and A.Settings.category and Settings.OpenToCategory then
            Settings.OpenToCategory(A.Settings.category:GetID())
        end
    end)
    button:SetScript("OnEnter", function()
        if InCombatLockdown() then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT"); GameTooltip:SetText("Apogee Heals")
        GameTooltip:AddLine("Left-click: open or close healing bindings.", 0.8, 0.85, 0.9)
        GameTooltip:AddLine("Right-click: settings.", 0.8, 0.85, 0.9)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    M.Refresh()
end
