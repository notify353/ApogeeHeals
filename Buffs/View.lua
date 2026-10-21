local _, A = ...
local B = A.Buffs
local function configureAction(button, id, unit)
    if InCombatLockdown() then return end
    local revision = B.actionRevision or 0
    if button.configured and button.configuredSpell == id
        and button.configuredRevision == revision then return end
    local text
    if id and unit ~= "player" then
        local info = B.Info(id)
        local rank = A.Access.Read(C_Spell and C_Spell.GetSpellSubtext, id)
        -- Same explicit recipient/rank program as the accepted healing fix.
        -- Missing text fails closed and retries on the next out-of-combat refresh.
        if info and type(rank) == "string" and not info.name:find("[\r\n;%[%]]")
            and not rank:find("[\r\n;%[%]]") then
            local name = info.name .. (rank ~= "" and "(" .. rank .. ")" or "")
            text = "/cast [@" .. unit .. ",exists,help] " .. name .. "\n/stopspelltarget"
        end
    end
    local active = id and (unit == "player" or text ~= nil)
    button:SetAttribute("type1", active and (unit == "player" and "spell" or "macro") or "")
    button:SetAttribute("spell1", id)
    button:SetAttribute("macrotext1", text)
    RegisterStateDriver(button, "visibility", active and "[combat] hide; show" or "hide")
    button.configured, button.configuredSpell, button.configuredRevision = not id or active, id, revision
end
local function createTimer(button)
    button.buffTimer = A.Style.CleanText(button, 5.5)
    local font = button.buffTimer:GetFont()
    button.buffTimer:SetFont(font, 5.5, "OUTLINE")
    button.buffTimer:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    button.buffTimer:SetSize(A.Style.sideIconSize - 4, 7)
    button.buffTimer:SetJustifyH("CENTER")
    button.buffTimer:SetTextColor(1, 1, 1, 1)
    button.buffTimer:SetShadowColor(0, 0, 0, 1); button.buffTimer:SetShadowOffset(1, -1)
end
local function paintTimer(button, entry)
    local remaining = entry and entry.remaining
    local seconds = remaining and remaining > 0 and math.ceil(remaining) or nil
    local text = ""
    if seconds then
        if seconds >= 3600 then text = math.floor(seconds / 3600) .. "h"
        elseif seconds >= 120 then text = math.floor(seconds / 60) .. "m"
        else text = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) end
    end
    button.buffTimer:SetText(text)
end
function B.HideTooltip(button)
    if not button or B.tooltipButton ~= button then return end
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    B.tooltipButton = nil
end
function B.Create(row)
    if not B.timerDriver then
        B.timerDriver = CreateFrame("Frame")
        local elapsed = 0
        B.timerDriver:SetScript("OnUpdate", function(_, delta)
            if InCombatLockdown() or B.suspended or A.View.unlocked then elapsed = 0; return end
            elapsed = elapsed + delta
            if elapsed < 1 then return end
            elapsed = 0; B.Refresh()
        end)
    end
    -- Parent to the whole row: the health-only name layer excludes the power
    -- section from child hit testing even when the strip artwork extends there.
    local strip = CreateFrame("Button", nil, row)
    row.buffStrip = strip
    strip:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    strip:SetSize(A.Style.classStripHitWidth, A.Style.clusterHeight)
    strip:SetFrameLevel(row.nameLayer:GetFrameLevel() + 2)
    strip:EnableMouse(true)
    strip:SetPropagateMouseClicks(false)
    strip:RegisterForClicks("AnyDown", "AnyUp")
    strip:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    strip:SetScript("OnClick", function(_, button, down)
        if button == "LeftButton" and not down then B.ToggleRecipient(row) end
    end)
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
        createTimer(button)
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
        paintTimer(button, entry)
        if not InCombatLockdown() then
            -- Cache only our public configured spell identity, never aura data.
            -- Combat painting leaves this untouched so deferred changes still apply.
            configureAction(button, id, row.unit)
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
            button = CreateFrame("Button", nil, row.supportFrame or row, "SecureActionButtonTemplate")
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
            createTimer(button)
        end
        if button then
            local id = entry and entry.id
            local reason = id and id == recommendedID and recommendation or nil
            if button.reminderSpell ~= id or button.recommendation ~= reason then B.HideTooltip(button) end
            button.reminderSpell, button.recommendation = id, reason
            if button.suggestion then button.suggestion:SetShown(reason ~= nil) end
            button.icon:SetTexture(entry and entry.icon); button.icon:SetShown(entry ~= nil)
            paintTimer(button, entry)
            if not InCombatLockdown() then
                local position = offset + index - 1
                if button.configuredPosition ~= position then
                    button:ClearAllPoints()
                    button:SetPoint("TOPRIGHT", row.health, "TOPLEFT", -gap - position * (size + gap), A.Style.sideIconY)
                    button.configuredPosition = position
                end
                configureAction(button, id, row.unit)
            end
        end
    end

end
-- The strip expands the existing left-hand buff choices for one recipient.
function B.CloseRecipient()
    B.HideTooltip(B.tooltipButton)
    B.recipientRow = nil
end
function B.ToggleRecipient(row)
    if InCombatLockdown() or B.suspended or A.View.unlocked then return end
    local previous = B.recipientRow
    B.CloseRecipient()
    if previous ~= row and B.Scan(row.unit) then B.recipientRow = row end
    B.Refresh()
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
    local entries = A.SmartBuffs.Entries()
    B.empty:SetShown(#entries == 0)
    for index = 1, math.max(#entries, #B.preferenceRows) do
        local row, entry = B.preferenceRows[index], entries[index]
        if entry and not row then
            row = CreateFrame("Frame", nil, B.content)
            B.preferenceRows[index] = row
            row:SetSize(476, 30); row:SetPoint("TOPLEFT", 4, -(index - 1) * 32)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
            row.label:SetSize(258, 28); row.label:SetJustifyH("LEFT")
            row.buttons = {}
            for position, mode in ipairs({"smart", "manual", "off"}) do
                local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.buttons[mode] = button
                button:SetSize(68, 24); button:SetPoint("LEFT", row, "LEFT", 264 + (position - 1) * 70, 0)
                button:SetScript("OnClick", function() A.SmartBuffs.Set(row.entry.key, mode) end)
            end
        end
        if row then
            row:SetShown(entry ~= nil); row.entry = entry
            if entry then
                row.label:SetText(entry.label)
                local current = A.SmartBuffs.Mode(entry.key, entry.fallback)
                for mode, button in pairs(row.buttons) do
                    local label = mode:sub(1, 1):upper() .. mode:sub(2)
                    button:SetText(mode == current and ("|cffffd100" .. label .. "|r") or label)
                    button:SetEnabled(not InCombatLockdown())
                end
            end
        end
    end
    B.content:SetHeight(math.max(32, #entries * 32))
end
function B.OpenPicker()
    if InCombatLockdown() then return end
    if not B.picker then
        local frame = CreateFrame("Frame", "ApogeeHealsBuffPicker", UIParent)
        B.picker = frame; frame:SetSize(530, 350); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true); A.Style.Background(frame)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -12); title:SetText("Smart buffs")
        local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        help:SetPoint("TOPLEFT", 12, -38); help:SetSize(500, 54); help:SetJustifyH("LEFT")
        help:SetText("Smart: useful missing buffs. Manual: expanded choices only. Off: hidden.\nClick a player's class strip to expand choices; click a buff to cast.\nYellow marks a suggestion. Your choices are saved for this character.")
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -102); scroll:SetPoint("BOTTOMRIGHT", -30, 36)
        B.content = CreateFrame("Frame", nil, scroll); B.content:SetSize(488, 32)
        scroll:SetScrollChild(B.content); B.preferenceRows = {}
        B.empty = B.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        B.empty:SetPoint("TOPLEFT", 4, -4); B.empty:SetText("No supported buffs learned yet.")
        local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        close:SetSize(70, 22); close:SetPoint("BOTTOMRIGHT", -12, 8); close:SetText("Close")
        close:SetScript("OnClick", function() frame:Hide() end)
        UISpecialFrames[#UISpecialFrames + 1] = "ApogeeHealsBuffPicker"
    end
    B.RefreshPicker(); B.picker:Show()
end
