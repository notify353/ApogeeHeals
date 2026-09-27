local _, A = ...
local P = { pending = true }
A.Cleansing = P
local spells = {
    {id=1152, key="purify", types={Poison=true, Disease=true}},
    {id=4987, key="cleanse", types={Poison=true, Disease=true, Magic=true}},
}
local function paladin()
    local ok, _, class = pcall(UnitClass, "player")
    return ok and A.Access.Readable(class) and class == "PALADIN"
end
function P.HideTooltip()
    if P.tooltip and GameTooltip:IsOwned(P.tooltip) then GameTooltip:Hide() end
    P.tooltip = nil
end
function P.Create(row)
    if not paladin() then return end
    row.cleanseButtons = {}
    local info = A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
    local container
    if info and A.Access.Readable(info.type) and info.type == "AuraContainer" then
        container = CreateFrame("AuraContainer", nil, row, "CustomAuraContainerTemplate")
        container:SetPoint("TOPLEFT", row.health, "TOPRIGHT", 16, -1)
        container:SetSize(26, 12)
        container:SetUnit(row.unit)
        row.cleanseIndicator = container
    end
    for index, spell in ipairs(spells) do
        local x = 16 + (index - 1) * 14
        -- A permanent secure sibling, never a child of or anchored to an AuraButton.
        local button = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
        button:SetSize(12, 12)
        button:SetPoint("TOPLEFT", row.health, "TOPRIGHT", x, -1)
        local level = A.Access.Read(row.health.GetFrameLevel, row.health)
        if type(level) == "number" and level >= 0 and level < 10000 and level % 1 == 0 then
            button:SetFrameLevel(level + 4)
        end
        button:SetAttribute("unit", row.unit); button:SetAttribute("useOnKeyDown", false)
        button:RegisterForClicks("LeftButtonUp")
        for _, prefix in ipairs({"shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
            button:SetAttribute(prefix .. "type1", "")
        end
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints(); button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button:SetScript("OnEnter", function()
            if InCombatLockdown() or not button.spell then return end
            P.HideTooltip(); P.tooltip = button
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            if GameTooltip:SetSpellByID(button.spell, false, true) then GameTooltip:Show()
            else P.HideTooltip() end
        end)
        button:SetScript("OnLeave", P.HideTooltip)
        button:SetScript("OnHide", P.HideTooltip)
        row.cleanseButtons[index] = button
        if container then
            -- Native visibility drives only this mouse-disabled halo. No native
            -- aura object, visibility or selection is observed by addon code.
            container:AddAuraSlot(spell.key, "HARMFUL", {
                candidateFilters = {includeDispelTypes = {}},
                initializeFrame = function(indicator)
                    indicator:SetSize(12, 12)
                    indicator:SetPoint("TOPLEFT", container, "TOPLEFT", (index - 1) * 14, 0)
                    indicator:EnableMouse(false)
                    indicator:SetCancelAuraButtons(nil)
                    for inset = 3, 1, -1 do
                        local glow = indicator:CreateTexture(nil, "ARTWORK")
                        glow:SetPoint("TOPLEFT", indicator, "TOPLEFT", -inset, inset)
                        glow:SetPoint("BOTTOMRIGHT", indicator, "BOTTOMRIGHT", inset, -inset)
                        glow:SetColorTexture(1, 0.75, 0.1, 0.25)
                    end
                end,
            })
        end
    end
    if container then container:SetEnabled(true) end
end
function P.Refresh()
    if InCombatLockdown() then P.HideTooltip(); return end
    if not P.pending or not A.View.rows then return end
    P.pending = nil; P.HideTooltip()
    local isPaladin = paladin()
    local resolved = {}
    for index, spell in ipairs(spells) do
        resolved[index] = isPaladin and A.Bindings.Resolve(spell.id) or nil
    end
    local hasGlow = false
    for _, row in ipairs(A.View.rows) do
        if row.cleanseButtons then
            for index, button in ipairs(row.cleanseButtons) do
                local spell, info = spells[index], resolved[index]
                local enabled = info ~= nil and not A.View.unlocked
                button.spell = enabled and spell.id or nil
                button.icon:SetTexture(info and info.iconID)
                button:SetAttribute("type1", enabled and "spell" or "")
                button:SetAttribute("spell1", button.spell)
                RegisterStateDriver(button, "visibility", enabled and "show" or "hide")
                if row.cleanseIndicator then
                    hasGlow = true
                    row.cleanseIndicator:SetAuraSlotCandidateFilters(spell.key,
                        {includeDispelTypes = enabled and spell.types or {}})
                end
            end
        end
    end
    if not isPaladin then P.status = "Cleansing buttons are for Paladins."
    elseif not resolved[1] and not resolved[2] then P.status = "Learn Purify or Cleanse to show cleansing buttons."
    elseif hasGlow then P.status = "Cleansing buttons glow for matching debuff types."
    else P.status = "Cleansing buttons available; native glow unavailable." end
    if A.Settings and A.Settings.cleanseStatus then A.Settings.cleanseStatus:SetText(P.status) end
end
