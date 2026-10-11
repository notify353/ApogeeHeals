local _, A = ...
local B = A.Buffs
function B.HideTooltip(button)
    if not button or B.tooltipButton ~= button then return end
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    B.tooltipButton = nil
end
function B.Create(row)
    local strip = CreateFrame("Button", nil, row.nameLayer)
    row.buffStrip = strip
    strip:SetAllPoints(row.classStrip)
    strip:SetFrameLevel(row.nameLayer:GetFrameLevel() + 1)
    strip:RegisterForClicks("LeftButtonUp")
    strip:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    strip:SetScript("OnClick", function() B.ToggleRecipient(row) end)
    local size, gap = A.Style.sideIconSize, A.Style.sideIconGap
    row.buffReminders, row.buffButtons = {}, {}
    for index = 1, 4 do
        local button = CreateFrame("Button", nil, row.supportFrame or row, "SecureActionButtonTemplate")
        row.buffButtons[index] = button
        button:SetSize(size, size)
        button:SetPoint("TOPRIGHT", row.health, "TOPLEFT", -gap - (index - 1) * (size + gap), A.Style.sideIconY)
        button:SetAttribute("unit", row.unit); button:SetAttribute("useOnKeyDown", false)
        button:RegisterForClicks("LeftButtonUp")
        for _, prefix in ipairs({"shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
            button:SetAttribute(prefix .. "type1", "")
        end
        button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
        button:SetScript("OnEnter", function()
            if InCombatLockdown() or not button.reminderSpell then return end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            B.tooltipButton = button
            -- Native tooltip includes the actual configured rank and client spell text.
            if GameTooltip:SetSpellByID(button.reminderSpell, false, true) then GameTooltip:Show()
            else B.HideTooltip(button) end
        end)
        button:SetScript("OnLeave", function() B.HideTooltip(button) end)
        button:SetScript("OnHide", function() B.HideTooltip(button) end)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); icon:Hide()
        row.buffReminders[index] = icon
    end
    row.buffOverflow = A.Style.Text(row.supportFrame or row, 8)
    row.buffOverflow:SetPoint("RIGHT", row, "LEFT", -gap - 4 * (size + gap), 0); row.buffOverflow:Hide()
end
function B.Paint(row, missing)
    for index, icon in ipairs(row.buffReminders) do
        local entry = missing[index]
        local button = row.buffButtons[index]
        local id = entry and entry.id or nil
        if button.reminderSpell ~= id then B.HideTooltip(button) end
        button.reminderSpell = id -- Public display identity only; never a protected combat attribute.
        icon:SetTexture(entry and entry.icon); icon:SetShown(entry ~= nil)
        if not InCombatLockdown() then
            -- Cache only our public configured spell identity, never aura data.
            -- Combat painting leaves this untouched so deferred changes still apply.
            if not button.configured or button.configuredSpell ~= id then
                button:SetAttribute("type1", entry and "spell" or "")
                button:SetAttribute("spell1", id)
                RegisterStateDriver(button, "visibility", entry and "[combat] hide; show" or "hide")
                button.configured, button.configuredSpell = true, id
            end
        end
    end
    row.buffOverflow:SetText(#missing > 4 and "+" .. (#missing - 4) or "")
    row.buffOverflow:SetShown(#missing > 4)
end
local function paintChoices(row, key, choices, offset, recommendedID, recommendation)
    row[key] = row[key] or {}
    local buttons = row[key]
    local size, gap = A.Style.sideIconSize, A.Style.sideIconGap
    for index = 1, math.max(#choices, #buttons) do
        local entry, button = choices[index], buttons[index]
        if not button and not InCombatLockdown() then
            button = CreateFrame("Button", nil, key == "recipientButtons" and row.recipientPanel or row.supportFrame or row, "SecureActionButtonTemplate")
            buttons[index] = button
            button:SetSize(size, size)
            button:SetAttribute("unit", row.unit); button:SetAttribute("useOnKeyDown", false)
            button:RegisterForClicks("LeftButtonUp")
            for _, prefix in ipairs({"shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
                button:SetAttribute(prefix .. "type1", "")
            end
            button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
            button:SetScript("OnEnter", function(self)
                if InCombatLockdown() or not self.reminderSpell then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT"); B.tooltipButton = self
                if GameTooltip:SetSpellByID(self.reminderSpell, false, true) then
                    if self.recommendation then GameTooltip:AddLine(self.recommendation, 1, 0.8, 0.2, true) end
                    GameTooltip:Show()
                else B.HideTooltip(self) end
            end)
            button:SetScript("OnLeave", function(self) B.HideTooltip(self) end)
            button:SetScript("OnHide", function(self) B.HideTooltip(self) end)
            if key == "blessingButtons" or key == "upkeepButtons" or key == "auraButtons" then
                button.suggestion = button:CreateTexture(nil, "BACKGROUND")
                button.suggestion:SetAllPoints(button)
                button.suggestion:SetColorTexture(1, 0.75, 0.1, 1)
                button.suggestion:Hide()
            end
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1); button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1); button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
        if button then
            local id = entry and entry.id
            local reason = id and id == recommendedID and recommendation or nil
            if button.reminderSpell ~= id or button.recommendation ~= reason then B.HideTooltip(button) end
            button.reminderSpell, button.recommendation = id, reason
            if button.suggestion then button.suggestion:SetShown(reason ~= nil) end
            button.icon:SetTexture(entry and entry.icon); button.icon:SetShown(entry ~= nil)
            if not InCombatLockdown() then
                local position = offset + index - 1
                if button.configuredPosition ~= position then
                    button:ClearAllPoints()
                    if key == "recipientButtons" then
                        button:SetPoint("TOPLEFT", row.recipientPanel, "TOPLEFT", 12 + (position % 10) * (size + gap), -174 - math.floor(position / 10) * (size + gap))
                    else
                        button:SetPoint("TOPRIGHT", row.health, "TOPLEFT", -gap - position * (size + gap), A.Style.sideIconY)
                    end
                    button.configuredPosition = position
                end
                if not button.configured or button.configuredSpell ~= id then
                    button:SetAttribute("type1", entry and "spell" or "")
                    button:SetAttribute("spell1", id)
                    RegisterStateDriver(button, "visibility", entry and "[combat] hide; show" or "hide")
                    button.configured, button.configuredSpell = true, id
                end
            end
        end
    end
end
-- Recipient picker is session-only. Secure visibility owns combat hiding;
-- insecure code never changes protected attributes/layout while in combat.
function B.CloseRecipient()
    B.HideTooltip(B.tooltipButton)
    B.recipientRow = nil
    for _, row in ipairs(A.View.supportRows or A.View.rows) do
        if row.recipientPanel and not InCombatLockdown() then
            RegisterStateDriver(row.recipientPanel, "visibility", "hide")
        end
    end
end
function B.RefreshRecipient()
    if InCombatLockdown() then return end
    local row = B.recipientRow
    if not row then B.CloseRecipient(); return end
    local auras = not B.suspended and not A.View.unlocked and B.Scan(row.unit)
    if not auras then B.CloseRecipient(); return end
    local names, choices, seen = {}, {}, {}
    for _, aura in ipairs(auras) do names[#names + 1] = aura.name end
    local function add(entry)
        if not seen[entry.id] then seen[entry.id] = true; choices[#choices + 1] = entry end
    end
    for _, entry in ipairs(A.BuffDefaults.Choices()) do add(entry) end
    -- Empty coverage deliberately includes learned buffs already on this unit.
    for _, entry in ipairs(A.BuffCatalog.Choices(row.unit, {}, nil, true)) do add(entry) end
    if row.unit == "player" then
        for _, entry in ipairs(B.AuraChoices(true)) do add(entry) end
    end
    for _, entry in ipairs(A.db.buffs) do
        if row.unit == "player" or B.ForParty(entry) then
            local info = A.Bindings.Resolve(entry.id)
            if info then add({id=entry.id, icon=info.iconID}) end
        end
    end
    row.recipientCurrent:SetText(#names > 0 and table.concat(names, "\n") or "No current buffs")
    row.recipientContent:SetHeight(math.max(100, #names * 30))
    row.recipientCurrent:SetHeight(math.max(100, #names * 30))
    row.recipientHelp:SetText(#choices > 0 and "Click a spell to recast or change a buff" or "No learned buffs available for this player")
    paintChoices(row, "recipientButtons", choices, 0)
    row.recipientPanel:SetHeight(190 + math.max(1, math.ceil(#choices / 10)) * (A.Style.sideIconSize + A.Style.sideIconGap))
end
function B.ToggleRecipient(row)
    if InCombatLockdown() or B.suspended or A.View.unlocked then return end
    local previous = B.recipientRow
    B.CloseRecipient()
    if previous == row or not B.Scan(row.unit) then return end
    if not row.recipientPanel then
        local panel = CreateFrame("Frame", nil, row.supportFrame or row, "SecureHandlerStateTemplate")
        row.recipientPanel = panel
        panel:SetScale(1 / A.Style.scale)
        panel:SetSize(340, 240); panel:SetFrameStrata("DIALOG")
        panel:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -4)
        panel:SetClampedToScreen(true); panel:EnableMouse(true); A.Style.Background(panel)
        local title = A.Style.Text(panel, 12)
        title:SetPoint("TOPLEFT", 12, -10); title:SetText("Current buffs")
        local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        close:SetSize(24, 20); close:SetPoint("TOPRIGHT", -6, -6); close:SetText("X")
        close:SetScript("OnClick", function() if not InCombatLockdown() then B.CloseRecipient() end end)
        local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -34); scroll:SetSize(294, 110)
        row.recipientContent = CreateFrame("Frame", nil, scroll)
        row.recipientContent:SetSize(294, 110); scroll:SetScrollChild(row.recipientContent)
        row.recipientCurrent = A.Style.Text(row.recipientContent, 11)
        row.recipientCurrent:SetPoint("TOPLEFT", 0, 0); row.recipientCurrent:SetSize(294, 110)
        row.recipientCurrent:SetJustifyH("LEFT"); row.recipientCurrent:SetJustifyV("TOP")
        row.recipientCurrent:SetWordWrap(true)
        row.recipientHelp = A.Style.Text(panel, 10)
        row.recipientHelp:SetPoint("TOPLEFT", 12, -154)
    end
    B.recipientRow = row; B.RefreshRecipient()
    if B.recipientRow then
        -- No out-of-combat 'show' clause: leaving combat cannot reopen it.
        RegisterStateDriver(row.recipientPanel, "visibility", "[combat] hide")
        row.recipientPanel:Show()
    end
end
function B.PaintBlessings(row, choices, missingCount)
    local offset = math.min(missingCount, 4) + (missingCount > 4 and 1 or 0)
    local id, reason = A.BuffDefaults.Recommend(row.unit, choices)
    paintChoices(row, "blessingButtons", choices, offset, id, reason)
end
function B.PaintCatalog(row, choices, missingCount, blessingCount, id, reason)
    local offset = math.min(missingCount, 4) + (missingCount > 4 and 1 or 0) + (blessingCount or 0)
    paintChoices(row, "upkeepButtons", choices, offset, id, reason)
end
function B.PaintAuras(row, choices, missingCount, blessingCount)
    local offset = math.min(missingCount, 4) + (missingCount > 4 and 1 or 0) + (blessingCount or 0)
    -- A cautious ranged-play hint, not a claim about the Hunter's specialization.
    local id, reason
    local ok, _, class = pcall(UnitClass, "player")
    if ok and A.Access.Readable(class) and class == "HUNTER" then
        local role = A.Access.Read(UnitGroupRolesAssigned, "player")
        local hawk = {[13165]=true,[14318]=true,[14319]=true,[14320]=true,[14321]=true,[14322]=true,[25296]=true}
        for _, entry in ipairs(choices) do
            if role == "TANK" and entry.id == 13163 then
                id, reason = entry.id, "Suggested: personal dodge (assigned tank)."
                break
            elseif role ~= "TANK" and role ~= "HEALER" and hawk[entry.id] then
                id, reason = entry.id, "Suggested for ranged attacks (Hunter class fallback; combat style unknown)."
                break
            end
        end
    end
    paintChoices(row, "auraButtons", choices, offset, id, reason)
end
function B.RefreshPicker()
    if not B.picker then return end
    B.empty:SetShown(#A.db.buffs == 0)
    for index = 1, B.limit do
        local check = B.checks[index]
        local entry = A.db.buffs[index]
        if entry and not check then
            check = CreateFrame("CheckButton", nil, B.content, "UICheckButtonTemplate")
            B.checks[index] = check; check:SetSize(24, 24)
            check:SetPoint("TOPLEFT", 4, -(index - 1) * 28)
            check.label = A.Style.Text(check, 11); check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
            check:SetScript("OnClick", function(self)
                if InCombatLockdown() then return end
                A.db.buffs[index].enabled = self:GetChecked() == true; B.Refresh()
            end)
        end
        if check then
            check:SetShown(entry ~= nil)
            if entry then
                local info = B.Info(entry.id)
                check.label:SetText((info and info.name or "Unavailable spell") .. (B.ForParty(entry) and "" or " (self)"))
                check:SetChecked(entry.enabled); check:SetEnabled(not InCombatLockdown())
            end
        end
    end
    B.content:SetHeight(math.max(32, #A.db.buffs * 28))
end
function B.OpenPicker()
    if InCombatLockdown() then return end
    if not B.picker then
        local frame = CreateFrame("Frame", "ApogeeHealsBuffPicker", UIParent)
        B.picker = frame; frame:SetSize(310, 240); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true); A.Style.Background(frame)
        local title = A.Style.Text(frame, 12); title:SetPoint("TOPLEFT", 12, -12); title:SetText("Learned upkeep buffs")
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -36); scroll:SetPoint("BOTTOMRIGHT", -30, 36)
        B.content = CreateFrame("Frame", nil, scroll); B.content:SetSize(264, 32)
        scroll:SetScrollChild(B.content); B.checks = {}
        B.empty = A.Style.Text(B.content, 11); B.empty:SetPoint("TOPLEFT", 4, -4); B.empty:SetText("Cast a five-minute buff to learn it.")
        local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        close:SetSize(70, 22); close:SetPoint("BOTTOMRIGHT", -12, 8); close:SetText("Close")
        close:SetScript("OnClick", function() frame:Hide() end)
        UISpecialFrames[#UISpecialFrames + 1] = "ApogeeHealsBuffPicker"
    end
    B.RefreshPicker(); B.picker:Show()
end
