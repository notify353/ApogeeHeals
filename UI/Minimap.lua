-- Interaction pattern adapted from Apogee Keybinds (MIT, copyright 2026 notify353).
local _, A = ...
local M = {}
local sessionAngle
A.Minimap = M
local function finite(value)
    return A.Access.Readable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
function M.HideTooltip()
    if GameTooltip:IsOwned(M.button) then GameTooltip:Hide() end
end
function M.StopDrag()
    M.dragging = nil
    if M.button then M.button:SetScript("OnUpdate", nil); M.HideTooltip() end
end
function M.Position(angle)
    if not M.button or M.suspended or InCombatLockdown() then return false end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not finite(width) or not finite(height) or width <= 0 or height <= 0 then return false end
    local level = Minimap:GetFrameLevel()
    if not finite(level) or level < 0 or level % 1 ~= 0 or not finite(level + 20) then return false end
    local radius = math.max(width, height) / 2 + 16
    if not finite(angle) then
        local spacing = math.max(15, math.deg(2 * math.asin(math.min(1, 46 / (2 * radius)))))
        angle = finite(sessionAngle) and sessionAngle or (220 - spacing)
    end
    local rad = math.rad(angle % 360)
    local c, s = math.cos(rad), math.sin(rad)
    local x, y = radius * c, radius * s
    if not finite(x) or not finite(y) then return false end
    M.button:SetFrameLevel(level + 20)
    M.button:ClearAllPoints(); M.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    return true
end
function M.DragUpdate()
    if not M.dragging then return end
    if M.suspended or InCombatLockdown() or not M.button:IsShown() then M.StopDrag(); return end
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = Minimap:GetCenter()
    if not finite(x) or not finite(y) or not finite(scale) or scale <= 0
        or not finite(cx) or not finite(cy) then return end
    local dx, dy = x / scale - cx, y / scale - cy
    if not finite(dx) or not finite(dy) or (dx == 0 and dy == 0) then return end
    local angle = math.deg(math.atan2(dy, dx)) % 360
    if M.Position(angle) then sessionAngle = angle end
end
function M.Refresh()
    if not M.button then return end
    M.button:SetEnabled(not InCombatLockdown())
    if InCombatLockdown() then M.StopDrag() else M.Position() end
    local open = A.BindingEditor.frame and A.BindingEditor.frame:IsShown()
    if open then M.border:SetVertexColor(1, 0.8, 0.3)
    else M.border:SetVertexColor(1, 1, 1) end
end
function M.Create()
    if M.button or not Minimap then return end
    local button = CreateFrame("Button", "ApogeeHealsMinimapButton", Minimap)
    M.button = button; button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface/Icons/Spell_Holy_Heal")
    local border = button:CreateTexture(nil, "OVERLAY"); M.border = border
    border:SetSize(54, 54); border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("RightButton")
    button:SetScript("OnMouseDown", function()
        if not M.dragging then M.suppressClick = nil end
    end)
    button:SetScript("OnDragStart", function(_, mouseButton)
        if mouseButton ~= "RightButton" or M.suspended or InCombatLockdown() then return end
        M.dragging, M.suppressClick = true, true
        M.HideTooltip(); button:SetScript("OnUpdate", M.DragUpdate)
        M.DragUpdate()
    end)
    button:SetScript("OnDragStop", M.StopDrag)
    button:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "RightButton" and M.dragging then M.StopDrag() end
    end)
    button:SetScript("OnHide", M.StopDrag)
    button:SetScript("OnShow", M.Refresh)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
        button:RegisterEvent(event)
    end
    button:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then
            M.suspended = true; M.StopDrag(); return
        end
        if event == "PLAYER_ENTERING_WORLD" then M.suspended = nil end
        M.Refresh()
    end)
    Minimap:HookScript("OnSizeChanged", function() M.Position() end)
    button:SetScript("OnClick", function(_, mouseButton)
        if M.suppressClick or M.dragging or M.suspended or InCombatLockdown() then return end
        M.HideTooltip()
        if mouseButton == "LeftButton" then
            if A.BindingEditor.frame and A.BindingEditor.frame:IsShown() then A.BindingEditor.Close()
            else A.BindingEditor.Open() end
        elseif mouseButton == "RightButton" and A.Settings.category and Settings.OpenToCategory then
            Settings.OpenToCategory(A.Settings.category:GetID())
        end
    end)
    button:SetScript("OnEnter", function()
        if M.dragging or M.suspended or InCombatLockdown() then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT"); GameTooltip:SetText("Apogee Heals")
        GameTooltip:AddLine("Left-click: open or close healing bindings.", 0.8, 0.85, 0.9)
        GameTooltip:AddLine("Right-click: settings.", 0.8, 0.85, 0.9)
        GameTooltip:AddLine("Right-drag: move around the minimap.", 0.8, 0.85, 0.9)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", M.HideTooltip)
    M.Refresh()
end
