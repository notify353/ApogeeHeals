-- Visual vocabulary adapted from Apogee Keybinds (MIT, copyright 2026 notify353).
local _, A = ...
local E = { buttons = {} }
A.BindingEditor = E
local style = { size = 36, gap = 4, header = 18, headerGap = 4 }
local function text(parent, value, x, y, size)
    local label = A.Style.Text(parent, size or 11)
    label:SetPoint("TOPLEFT", x, y); label:SetText(value); return label
end
local function finite(value)
    return A.Access.Readable(value) and type(value) == "number"
        and value == value and math.abs(value) < 100000
end
function E.Place()
    if not E.frame or InCombatLockdown() or E.moving or E.customPosition then return end
    local saved = A.db.editorPosition
    E.frame:ClearAllPoints()
    if type(saved) == "table" and finite(saved.x) and finite(saved.y) then
        E.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        return
    end
    -- Optional public anchor only; never access Keybinds' namespace or saved data.
    -- Central DEV generation rewrites this explicitly audited cross-addon identity.
    local header = _G["ApogeeKeybindsWeaponsHeader"]
    if A.Access.Readable(header) and type(header) == "table" then
        E.frame:SetPoint("TOPLEFT", header, "TOPRIGHT", 8, 0)
    else E.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end
function E.StopMoving()
    if not E.frame then return end
    E.frame:StopMovingOrSizing()
    if not E.moving then return end
    E.moving, E.customPosition = nil, true
    if InCombatLockdown() then return end
    local x = A.Access.Read(E.frame.GetLeft, E.frame)
    local y = A.Access.Read(E.frame.GetBottom, E.frame)
    local scale = A.Access.Read(E.frame.GetEffectiveScale, E.frame)
    local parentScale = A.Access.Read(UIParent.GetEffectiveScale, UIParent)
    if finite(x) and finite(y) and finite(scale) and scale > 0
        and finite(parentScale) and parentScale > 0 then
        x, y = x * scale / parentScale, y * scale / parentScale
        if finite(x) and finite(y) then A.db.editorPosition = { x = x, y = y } end
    end
end
function E.Cancel()
    E.source = nil
    if E.frame then E.Refresh() end
end
function E.Close()
    E.Cancel()
    E.StopMoving()
    if E.frame then E.frame:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end
function E.Refresh()
    if not E.frame then return end
    for id, button in pairs(E.buttons) do
        local spell = A.Bindings.Effective(id)
        local info = spell and A.Bindings.Resolve(spell)
        button.icon:SetTexture(info and info.iconID or spell and "Interface/Icons/INV_Misc_QuestionMark" or nil)
        button.icon:SetAlpha(E.source == id and 0.35 or 1)
        button.remove:SetShown(A.db.bindings[id] ~= nil)
    end
end
function E.Drop(id)
    if InCombatLockdown() then E.Cancel(); return end
    if E.source then
        local source = E.source; E.source = nil
        A.Bindings.Swap(source, id)
    else
        local spell, reason = A.Bindings.Cursor()
        if spell and A.Bindings.Put(id, spell) then
            ClearCursor()
        else print("Apogee Heals: " .. (reason or "Unable to assign spell.")) end
    end
    E.Refresh()
end
function E.Open()
    if InCombatLockdown() then return end
    if not E.frame then E.Create() end
    E.Cancel()
    E.Place()
    E.frame:Show()
    A.Minimap.Refresh()
end
function E.Create()
    local frame = CreateFrame("Frame", "ApogeeHealsBindingEditor", UIParent)
    local step = style.size + style.gap
    local width = 5 * step - style.gap
    local gridTop = style.header + style.headerGap
    E.frame = frame; frame:SetSize(width, gridTop + 3 * step - style.gap)
    E.Place()
    frame:SetFrameStrata("LOW"); frame:EnableMouse(false); frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    local handle = CreateFrame("Button", nil, frame)
    handle:SetSize(width, style.header); handle:SetPoint("TOPLEFT", 0, 0); handle:RegisterForDrag("LeftButton")
    local background = handle:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(); background:SetColorTexture(0.09, 0.12, 0.17, 0.8)
    local title = A.Style.Text(handle, 9)
    title:SetPoint("CENTER", 0, 0); title:SetText("Healing Mouse")
    E.handle = handle
    handle:SetScript("OnDragStart", function()
        if not InCombatLockdown() then E.moving = true; frame:StartMoving() end
    end)
    handle:SetScript("OnDragStop", E.StopMoving)
    handle:SetScript("OnEnter", function()
        if InCombatLockdown() then return end
        GameTooltip:SetOwner(handle, "ANCHOR_RIGHT"); GameTooltip:SetText("Healing bindings")
        GameTooltip:AddLine("Drag the header to move. Drop spells onto the tiles.", 0.8, 0.85, 0.9, true)
        GameTooltip:AddLine("Columns: Left, Right, Middle, Mouse 4, Mouse 5.", 0.8, 0.85, 0.9, true)
        GameTooltip:AddLine("Rows: plain, Shift (S-), Ctrl (C-). L = Left, R = Right, M = Middle.", 0.8, 0.85, 0.9, true)
        GameTooltip:AddLine("Priest defaults: Left Lesser Heal, Right Power Word: Shield.", 0.8, 0.85, 0.9, true)
        GameTooltip:AddLine("Without an assignment or learned default, plain Left targets.", 0.8, 0.85, 0.9, true)
        GameTooltip:AddLine("Escape or the minimap button closes.", 0.8, 0.85, 0.9, true)
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    for _, slot in ipairs(A.Bindings.slots) do
        local id = slot.id
        local button = CreateFrame("Button", nil, frame)
        E.buttons[id] = button; button:SetSize(style.size, style.size)
        button:SetPoint("TOPLEFT", (slot.button - 1) * step, -gridTop - (slot.row - 1) * step)
        A.Style.Background(button)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 2, -2); button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        text(button, ({ "", "S-", "C-" })[slot.row]
            .. ({ "L", "R", "M", "4", "5" })[slot.button], 2, -2, 9)
        button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
        button:RegisterForClicks("LeftButtonUp"); button:RegisterForDrag("LeftButton")
        button:SetScript("OnReceiveDrag", function() E.Drop(id) end)
        button:SetScript("OnClick", function()
            if E.suppressClick then E.suppressClick = nil; return end
            if E.source or GetCursorInfo() then E.Drop(id) end
        end)
        button:SetScript("OnDragStart", function()
            if not InCombatLockdown() and A.db.bindings[id] and not GetCursorInfo() then
                E.source = id; E.Refresh()
            end
        end)
        button:SetScript("OnDragStop", function()
            if E.source then
                for target, candidate in pairs(E.buttons) do
                    if candidate:IsMouseOver() then E.Drop(target); break end
                end
            end
            E.Cancel(); E.suppressClick = true
        end)
        button:SetScript("OnMouseDown", function() E.suppressClick = nil end)
        button:SetScript("OnEnter", function()
            if InCombatLockdown() then return end
            local spell, automatic = A.Bindings.Effective(id)
            local info, reason
            if spell then info, reason = A.Bindings.Resolve(spell) end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetText(slot.label)
            if info then
                GameTooltip:AddLine(info.name, 1, 1, 1)
                local rank = A.Access.Read(C_Spell.GetSpellSubtext, spell)
                if type(rank) == "string" and rank ~= "" then GameTooltip:AddLine(rank) end
            else GameTooltip:AddLine(reason or (id == "1" and "Empty: targets the clicked party member."
                or "Empty: drop a learned healing spell.")) end
            if automatic then
                GameTooltip:AddLine("Class default: highest learned rank. Drop a spell to override.", 0.8, 0.85, 0.9, true)
            else
                GameTooltip:AddLine("Drag to move or swap. Use x to restore the default.", 0.8, 0.85, 0.9, true)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local remove = CreateFrame("Button", nil, button)
        button.remove = remove; remove:SetSize(12, 12); remove:SetPoint("TOPRIGHT", -1, -1)
        A.Style.Background(remove); text(remove, "×", 2, 0, 10)
        remove:SetScript("OnClick", function() E.Cancel(); A.Bindings.Put(id, nil) end)
    end
    frame:SetScript("OnHide", function()
        E.Cancel(); E.StopMoving(); GameTooltip:Hide()
        A.Minimap.Refresh()
    end)
    frame:SetScript("OnShow", function() E.Place(); A.Minimap.Refresh() end)
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED" }) do
        frame:RegisterEvent(event)
    end
    frame:SetScript("OnEvent", function()
        if E.placementPending then return end
        E.placementPending = true
        C_Timer.After(0, function() E.placementPending = nil; E.Place() end)
    end)
    UISpecialFrames[#UISpecialFrames + 1] = "ApogeeHealsBindingEditor"
end
