local _, A = ...
local W = { rows = {} }
A.WeaponUpkeep = W
local classes = { ROGUE = true, SHAMAN = true, WARLOCK = true }
local function supported()
    local ok, _, class = pcall(UnitClass, "player")
    return ok and A.Access.Readable(class) and type(class) == "string" and classes[class] == true
end
local function disable(row)
    local holder = row.weaponUpkeep
    if not holder then return end
    -- Inbound native clearing also owns tooltip/duration cleanup. No aura state
    -- or native child visibility is ever inspected by the addon.
    for _, container in ipairs(holder.containers) do container:SetEnabled(false) end
    holder:SetAlpha(0)
    if not InCombatLockdown() and holder.driver ~= "hide" then
        RegisterStateDriver(holder, "visibility", "hide"); holder.driver = "hide"
    end
end
function W.Create(row)
    if InCombatLockdown() or not row or row.unit ~= "player" or row.weaponUpkeep
        or row.weaponUpkeepUnavailable or not supported() then return end
    local info = A.Access.Read(C_XMLUtil and C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
    local slots = AuraContainerItemEnchantmentSlot
    if type(info) ~= "table" or not A.Access.Readable(info.type) or info.type ~= "AuraContainer"
        or type(slots) ~= "table" or not A.Access.Readable(slots)
        or not A.Access.Readable(slots.MainHand, slots.OffHand)
        or type(slots.MainHand) ~= "number" or type(slots.OffHand) ~= "number" then return end
    local size, gap = A.Style.sideIconSize, A.Style.sideIconGap
    local holder = CreateFrame("Frame", nil, row, "SecureHandlerStateTemplate")
    holder:SetSize(2 * size + gap, size)
    holder.containers = {}
    holder:SetAlpha(0)
    RegisterStateDriver(holder, "visibility", "hide")
    holder.driver = "hide"
    -- One native container per hand preserves fixed hand positions when only
    -- one weapon is coated. Never anchor anything to native flowing children.
    for index, slot in ipairs({slots.MainHand, slots.OffHand}) do
        local container = CreateFrame("AuraContainer", nil, holder, "CustomAuraContainerTemplate")
        if type(container.AddItemEnchantment) ~= "function" or type(container.SetItemEnchantmentLayout) ~= "function"
            or type(container.SetUnit) ~= "function" or type(container.SetEnabled) ~= "function" then
            row.weaponUpkeepUnavailable = true; return
        end
        holder.containers[#holder.containers + 1] = container
        container:SetEnabled(false)
        container:SetUnit("player")
        container:SetSize(size, size)
        container:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -(index - 1) * (size + gap), 0)
        container:SetItemEnchantmentLayout({elementWidth=size, elementHeight=size, elementSpacing=gap})
        container:AddItemEnchantment(slot, {
            hidePermanent = false,
            initializeFrame = function(button)
                button:SetSize(size, size)
                button:SetCancelAuraButtons(nil)
                button:SetTooltipAnchorPoint("ANCHOR_LEFT")
                local background = button:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints(); background:SetColorTexture(0.08, 0.10, 0.13, 1)
                local icon = button:CreateTexture(nil, "ARTWORK")
                icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                button:SetIcon(icon)
                if type(button.SetDurationText) == "function" then
                    local text = A.Style.Text(button, 8)
                    text:SetAllPoints(); text:SetJustifyH("CENTER"); text:SetJustifyV("MIDDLE")
                    text:SetShadowColor(0, 0, 0, 1); text:SetShadowOffset(1, -1)
                    button:SetDurationText(text, {})
                end
            end,
        })
    end
    row.weaponUpkeep = holder
    W.rows[#W.rows + 1] = row
end
-- leftOffset is the number of icon positions already occupied by upkeep,
-- overflow and class choices, not a pixel offset. No occupied-state reads.
function W.Refresh(row, leftOffset)
    if InCombatLockdown() or not row or row.unit ~= "player" then return end
    if (A.Runtime and A.Runtime.suspended) or (A.View and A.View.unlocked)
        or not supported() or A.UnitAPI.State("player") ~= "alive" then disable(row); return end
    if not A.Access.Readable(leftOffset) or type(leftOffset) ~= "number"
        or leftOffset < 0 or leftOffset > 128 or leftOffset % 1 ~= 0 then disable(row); return end
    W.Create(row)
    local holder = row.weaponUpkeep
    if not holder then return end
    local size, gap = A.Style.sideIconSize, A.Style.sideIconGap
    if holder.leftOffset ~= leftOffset then
        holder:ClearAllPoints()
        holder:SetPoint("TOPRIGHT", row.health, "TOPLEFT", -gap - leftOffset * (size + gap), A.Style.sideIconY)
        holder.leftOffset = leftOffset
    end
    for _, container in ipairs(holder.containers) do container:SetEnabled(true) end
    holder:SetAlpha(1)
    if holder.driver ~= "[combat] hide; show" then
        RegisterStateDriver(holder, "visibility", "[combat] hide; show"); holder.driver = "[combat] hide; show"
    end
end
function W.Stop()
    for _, row in ipairs(W.rows) do disable(row) end
end
-- Display only: active temporary enchants may be poison, imbue or spellstone.
-- No recipe/item/rank guesses, missing-coating claim, automatic replacement or
-- application chooser. Available items and replacement behavior need separate
-- matching-client validation and physical fixed-slot acceptance.
