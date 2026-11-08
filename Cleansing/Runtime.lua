local _, A = ...
local P = { pending = true }
A.Cleansing = P
-- Candidate IDs only: every action still requires a learned player-book spell.
-- Fixed type slots prefer the first learned action below, then its highest rank.
-- The legacy/Era renderer keeps Cure/Abolish as separate choices.
-- Felhunter is deferred: native type="pet" passes a fixed unit, but action is
-- a mutable pet-bar slot. It has no expected-spell-ID guard at click time;
-- an out-of-combat Devour Magic lookup cannot establish combat slot identity.
local classes = {
    PALADIN = {
        {id=1152, ranks={1152}, key="purify", types={Poison=true, Disease=true}},
        {id=4987, ranks={4987}, key="cleanse", types={Poison=true, Disease=true, Magic=true}},
    },
    PRIEST = {
        {id=527, ranks={988,527}, key="dispelMagic", types={Magic=true}},
        {id=528, ranks={528}, key="cureDisease", types={Disease=true}},
        {id=552, ranks={552}, key="abolishDisease", types={Disease=true}},
    },
    SHAMAN = {
        {id=526, ranks={526}, key="curePoison", types={Poison=true}},
        {id=2870, ranks={2870}, key="cureDisease", types={Disease=true}},
    },
    DRUID = {
        {id=8946, ranks={8946}, key="curePoison", types={Poison=true}},
        {id=2893, ranks={2893}, key="abolishPoison", types={Poison=true}},
        {id=2782, ranks={2782}, key="removeCurse", types={Curse=true}},
    },
    MAGE = {
        {id=475, ranks={475}, key="removeCurse", types={Curse=true}},
    },
}
local function classSpells()
    local ok, _, class = pcall(UnitClass, "player")
    if ok and A.Access.Readable(class) and type(class) == "string" then return classes[class] end
end
local function resolve(id)
    if id ~= 527 and id ~= 988 then return A.Bindings.Resolve(id) end
    -- Dispel Magic is both helpful and harmful. This narrow exception never
    -- relaxes the ordinary binding editor's friendly-only validation.
    local read = A.Access.Read
    local info = A.Buffs.Info(id)
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if not info or not bank or not C_SpellBook or not C_Spell then return end
    local harmful = read(C_Spell.IsSpellHarmful, id)
    if read(C_SpellBook.IsSpellInSpellBook, id, bank, false) == true
        and read(C_SpellBook.IsSpellKnown, id, bank) == true
        and read(C_Spell.IsSpellHelpful, id) == true
        and type(harmful) == "boolean"
        and read(C_Spell.IsSpellPassive, id) == false then return info end
end
function P.HideTooltip()
    if P.tooltip and GameTooltip:IsOwned(P.tooltip) then GameTooltip:Hide() end
    P.tooltip = nil
end
-- Permanent action positions; native slots alone select and display aura data.
local dispelTypes = {"Magic", "Disease", "Poison", "Curse"}
local allDispelTypes = {Magic=true, Disease=true, Poison=true, Curse=true}
local function supportsSlots(container)
    for _, method in ipairs({"AddAuraSlot", "SetAuraSlotCandidateFilters", "SetUnit", "SetEnabled"}) do
        if type(container[method]) ~= "function" then return false end
    end
    return true
end
local function createFixed(row)
    if A.__ApogeeClient == "classic-era" then return false end
    local sort = AuraContainerSortMethod and AuraContainerSortMethod.AuraInstanceIDOnly
    local direction = AuraContainerSortDirection and AuraContainerSortDirection.Reverse
    local info = A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
    if not info or not A.Access.Readable(info.type) or info.type ~= "AuraContainer"
        or not A.Access.Readable(sort) or type(sort) ~= "number"
        or not A.Access.Readable(direction) or type(direction) ~= "number"
        or type(row.SetMouseMotionEnabled) ~= "function" then return false end
    local size, gap = A.Style.sideIconSize, A.Style.sideIconGap
    local width = 5 * size + 4 * gap
    local gate = CreateFrame("Frame", nil, row.supportFrame or row, "SecureHandlerStateTemplate")
    gate:SetSize(width, size)
    gate:SetPoint("TOPLEFT", row.health, "TOPRIGHT", gap, A.Style.sideIconY)
    gate:EnableMouse(false)
    local level = A.Access.Read(row.health.GetFrameLevel, row.health)
    if type(level) ~= "number" or level < 0 or level >= 10000 or level % 1 ~= 0 then level = 1 end
    local function container()
        local result = CreateFrame("AuraContainer", nil, gate, "CustomAuraContainerTemplate")
        -- The mixin definitions live in Blizzard's secure Lua environment.
        -- Check the public inbound methods on the actual object instead.
        if not supportsSlots(result) then return nil end
        result:SetAllPoints(gate); result:SetSize(width, size)
        result:EnableMouse(false); result:SetUnit(row.unit)
        return result
    end
    local icons, highlights = container(), container()
    if not icons or not highlights then gate:Hide(); return false end
    RegisterStateDriver(gate, "visibility", "[@" .. row.unit .. ",help,nodead] show; hide")
    row.fixedDebuffs, row.cleanseButtons = true, {}
    row.fixedDebuffGate = gate
    row.debuffContainer, row.cleanseIndicator = icons, highlights
    row.cleanseSlotCount = 5
    row.drinkIcon:ClearAllPoints()
    row.drinkIcon:SetPoint("TOPLEFT", row.health, "TOPRIGHT", gap + 5 * (size + gap), A.Style.sideIconY)
    for index = 1, 5 do
        local kind = dispelTypes[index] or "Other"
        local x = (index - 1) * (size + gap)
        local function place(frame, layer)
            frame:SetSize(size, size); frame:SetFrameLevel(level + layer)
            frame:SetPoint("TOPLEFT", gate, "TOPLEFT", x, 0)
            frame:EnableMouse(false); frame:SetCancelAuraButtons(nil)
        end
        icons:AddAuraSlot(kind, "HARMFUL", {
            sortMethod=sort, sortDirection=direction,
            candidateFilters=index <= 4 and {includeDispelTypes={[kind]=true}}
                or {excludeDispelTypes=allDispelTypes},
            initializeFrame=function(frame)
                place(frame, 5)
                -- Hover belongs to the intrinsic aura tooltip; clicks hit the
                -- ordinary secure sibling below. No propagation or custom scripts.
                frame:SetMouseMotionEnabled(true)
                frame:SetTooltipAnchorPoint("ANCHOR_RIGHT")
                frame:SetHideTooltipInCombat(false)
                local background = frame:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints(frame); background:SetColorTexture(0.15, 0.15, 0.15, 1)
                local icon = frame:CreateTexture(nil, "ARTWORK")
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
                icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                frame:SetIcon(icon)
                if type(frame.SetDurationText) == "function" and C_AuraContainerUtil
                    and type(C_AuraContainerUtil.ProcessCustomAuraButtonDurationTextOptions) == "function" then
                    local remaining = A.Style.CleanText(frame, 7)
                    local font = remaining:GetFont()
                    remaining:SetFont(font, 7, "OUTLINE")
                    remaining:SetPoint("BOTTOM", frame, "BOTTOM", 0, 1.5)
                    remaining:SetSize(size - 3, 8)
                    remaining:SetJustifyH("CENTER")
                    remaining:SetShadowColor(0, 0, 0, 1)
                    remaining:SetShadowOffset(0.5, -0.5)
                    -- Native binding formats/updates remaining time and hides
                    -- permanent effects. Never read duration or text back in Lua.
                    frame:SetDurationText(remaining)
                end
            end,
        })
        if index <= 4 then
            local button = CreateFrame("Button", nil, gate, "SecureActionButtonTemplate")
            button:SetSize(size, size); button:SetFrameLevel(level + 4)
            button:SetPoint("TOPLEFT", gate, "TOPLEFT", x, 0)
            button:SetAttribute("unit", row.unit); button:SetAttribute("useOnKeyDown", false)
            button:RegisterForClicks("LeftButtonUp")
            for _, prefix in ipairs({"shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
                button:SetAttribute(prefix .. "type1", "")
            end
            row.cleanseButtons[index] = button
            highlights:AddAuraSlot(kind, "HARMFUL", {
                sortMethod=sort, sortDirection=direction,
                candidateFilters={includeDispelTypes={}},
                initializeFrame=function(frame)
                    place(frame, 6)
                    -- Only four edges: a full background here would cover the icon.
                    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                        local texture = frame:CreateTexture(nil, "OVERLAY")
                        texture:SetColorTexture(1, 0.75, 0.1, 1)
                        texture:SetPoint(edge, frame, edge, 0, 0)
                        texture:SetSize((edge == "TOP" or edge == "BOTTOM") and size or 1,
                            (edge == "LEFT" or edge == "RIGHT") and size or 1)
                    end
                end,
            })
        end
    end
    icons:SetEnabled(true); highlights:SetEnabled(true)
    return true
end
function P.Create(row)
    if InCombatLockdown() or row.cleanseButtons then return end
    if createFixed(row) then return end
    local spells = classSpells()
    if not spells then return end
    local size, gap, offset = A.Style.sideIconSize, A.Style.sideIconGap, A.Style.sideIconGap
    row.cleanseSpells, row.cleanseSlotCount = spells, #spells
    row.cleanseButtons = {}
    row.drinkIcon:ClearAllPoints()
    row.drinkIcon:SetPoint("TOPLEFT", row.health, "TOPRIGHT", offset + #spells * (size + gap), A.Style.sideIconY)
    local info = A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
    local container
    if info and A.Access.Readable(info.type) and info.type == "AuraContainer" then
        container = CreateFrame("AuraContainer", nil, row.supportFrame or row, "CustomAuraContainerTemplate")
        if not supportsSlots(container) then container:Hide(); container = nil end
    end
    if container then
        container:SetPoint("TOPLEFT", row.health, "TOPRIGHT", offset, A.Style.sideIconY)
        container:SetSize(#spells * size + (#spells - 1) * gap, size)
        container:SetUnit(row.unit)
        row.cleanseIndicator = container
    end
    for index, spell in ipairs(spells) do
        local x = offset + (index - 1) * (size + gap)
        -- A permanent secure sibling, never a child of or anchored to an AuraButton.
        local button = CreateFrame("Button", nil, row.supportFrame or row, "SecureActionButtonTemplate")
        button:SetSize(size, size)
        button:SetPoint("TOPLEFT", row.health, "TOPRIGHT", x, A.Style.sideIconY)
        local level = A.Access.Read(row.health.GetFrameLevel, row.health)
        local publicLevel = type(level) == "number" and level >= 0 and level < 10000 and level % 1 == 0
        if publicLevel then
            button:SetFrameLevel(level + 4)
        end
        button:SetAttribute("unit", row.unit); button:SetAttribute("useOnKeyDown", false)
        button:RegisterForClicks("LeftButtonUp")
        for _, prefix in ipairs({"shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
            button:SetAttribute(prefix .. "type1", "")
        end
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1); button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1); button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.icon:SetDesaturated(true); button.icon:SetAlpha(0.3)
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
            local spellInfo = A.Buffs.Info(spell.id)
            -- Native visibility drives only this mouse-disabled artwork. No native
            -- aura object, visibility or selection is observed by addon code.
            container:AddAuraSlot(spell.key, "HARMFUL", {
                candidateFilters = {includeDispelTypes = {}},
                initializeFrame = function(indicator)
                    indicator:SetSize(size, size)
                    if publicLevel then indicator:SetFrameLevel(level + 5) end
                    indicator:SetPoint("TOPLEFT", container, "TOPLEFT", (index - 1) * (size + gap), 0)
                    indicator:EnableMouse(false)
                    indicator:SetCancelAuraButtons(nil)
                    -- Inset artwork keeps the gold border inside the clickable square.
                    local glow = indicator:CreateTexture(nil, "BACKGROUND")
                    glow:SetAllPoints(indicator)
                    glow:SetColorTexture(1, 0.75, 0.1, 0.85)
                    -- A constant spell image, not the native aura's icon. The
                    -- secure sibling underneath retains all click handling.
                    local activeIcon = indicator:CreateTexture(nil, "ARTWORK")
                    activeIcon:SetPoint("TOPLEFT", indicator, "TOPLEFT", 1, -1); activeIcon:SetPoint("BOTTOMRIGHT", indicator, "BOTTOMRIGHT", -1, 1); activeIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    activeIcon:SetTexture(spellInfo and spellInfo.iconID)
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
    local spells = classSpells()
    local resolved = {}
    local hasAction = false
    for index, spell in ipairs(spells or {}) do
        for _, id in ipairs(spell.ranks) do
            local info = resolve(id)
            if info then
                resolved[index] = {id=id, info=info}; hasAction = true; break
            end
        end
    end
    local hasGlow, hasFixed = false, false
    for _, row in ipairs(A.View.supportRows or A.View.rows) do
        if row.fixedDebuffs then
            -- Preview or loading may end after combat lockdown begins. Keep learned
            -- actions bound and let the preconfigured native gate reveal them;
            -- addon code cannot restore cleared spell attributes in combat.
            local condition = (A.View.unlocked or A.Runtime.suspended) and "[combat,@" or "[@"
            local failed = A.startupState == "failed"
            RegisterStateDriver(row.fixedDebuffGate, "visibility", failed and "hide"
                or condition .. row.unit .. ",help,nodead] show; hide")
            for index, button in ipairs(row.cleanseButtons) do
                local kind, result = dispelTypes[index]
                for spellIndex, spell in ipairs(spells or {}) do
                    if spell.types[kind] and resolved[spellIndex] then
                        result = resolved[spellIndex]; break
                    end
                end
                local enabled = result ~= nil and not failed
                button.spell = enabled and result.id or nil
                button:SetAttribute("type1", enabled and "spell" or "")
                button:SetAttribute("spell1", button.spell)
                RegisterStateDriver(button, "visibility", enabled and "show" or "hide")
                row.cleanseIndicator:SetAuraSlotCandidateFilters(kind,
                    {includeDispelTypes=enabled and {[kind]=true} or {}})
            end
            hasGlow, hasFixed = true, true
        elseif row.cleanseButtons then
            for index, button in ipairs(row.cleanseButtons) do
                local spell = row.cleanseSpells[index]
                local result = row.cleanseSpells == spells and resolved[index] or nil
                local info = result and result.info
                local enabled = info ~= nil and not A.View.unlocked
                button.spell = enabled and result.id or nil
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
    if not spells then P.status = "No supported player-cast cleansing actions for this class."
    elseif not hasAction then P.status = "Learn a class cleansing spell to enable cleansing."
    elseif hasFixed then P.status = "Matching debuff borders highlight; left-click to cleanse."
    elseif hasGlow then P.status = "Cleansing buttons glow for matching debuff types."
    else P.status = "Cleansing buttons available; native glow unavailable." end
    if A.Settings and A.Settings.cleanseStatus then A.Settings.cleanseStatus:SetText(P.status) end
end
function P.RefreshActivity()
    local enabled = not A.Runtime.suspended and not A.View.unlocked
    for _, row in ipairs(A.View.supportRows or {}) do
        if row.fixedDebuffs then
            row.debuffContainer:SetEnabled(enabled)
            row.cleanseIndicator:SetEnabled(enabled)
        end
    end
    P.pending = true
    P.Refresh()
end
