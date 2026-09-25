local _, A = ...
local P = { pending = true }
A.Cleansing = P
local spellID = 1152 -- Purify candidate: the running client must confirm it is learned/helpful.
local function spell()
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or class ~= "PALADIN" then return end
    local info = A.Bindings.Resolve(spellID)
    if info and type(info.iconID) == "number" and info.iconID > 0 and info.iconID < math.huge then return info end
end
local function supported()
    local getter = C_XMLUtil and C_XMLUtil.GetTemplateInfo
    for _, name in ipairs({ "CustomAuraContainerTemplate", "CustomAuraButtonTemplate", "SecureActionButtonTemplate" }) do
        local info = A.Access.Read(getter, name)
        if type(info) ~= "table" then return false end
    end
    return true
end
local function create(row, info)
    local host = CreateFrame("Frame", nil, row)
    host:SetSize(12, 12); host:Hide()
    row.cleanseHost = host
    P.Place(row, 0)
    row.buffOverflow:ClearAllPoints(); row.buffOverflow:SetPoint("RIGHT", row.health, "LEFT", -75, 0)
    local ok = pcall(function()
        local container = CreateFrame("AuraContainer", nil, host, "CustomAuraContainerTemplate")
        container:SetAllPoints(host)
        container:AddAuraSlot("poison", "HARMFUL", {
            candidateFilters = { includeDispelTypes = { Poison = true } },
            templateNames = { "SecureActionButtonTemplate" },
            initializeFrame = function(button)
                -- The native provider runs this once, before it restricts access to
                -- the button. Never retain/read/mutate this button after initialization.
                assert(not InCombatLockdown())
                assert(A.Access.Read(button.IsProtected, button) == true)
                button:SetSize(12, 12); button:SetPoint("CENTER", container, "CENTER", 0, 0)
                button:SetAttribute("unit", row.unit)
                button:SetAttribute("useOnKeyDown", false)
                button:SetAttribute("type1", "spell"); button:SetAttribute("spell1", spellID)
                for _, prefix in ipairs({ "shift-", "ctrl-", "ctrl-shift-", "alt-",
                    "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
                    button:SetAttribute(prefix .. "type1", "")
                end
                button:SetCancelAuraButtons(nil)
                button:RegisterForClicks("LeftButtonUp")
                button:SetTooltipAnchorPoint("ANCHOR_RIGHT") -- Native tooltip describes the triggering poison.
                local icon = button:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints(); icon:SetTexture(info.iconID); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
            end,
        })
        container:SetUnit(row.unit); container:SetEnabled(true)
    end)
    if not ok then
        -- Construction occurs out of combat with the host hidden. No active
        -- fallback hitbox or guessed aura state survives a missing native capability.
        P.failed = true
    end
end
function P.Place(row, buffCount)
    if InCombatLockdown() or not row.cleanseHost or row.cleanseSlot == buffCount then return end
    row.cleanseHost:ClearAllPoints()
    row.cleanseHost:SetPoint("RIGHT", row.health, "LEFT", -3 - buffCount * 14, 0)
    row.cleanseSlot = buffCount
end
function P.Refresh()
    if InCombatLockdown() or not P.pending or not A.View.rows then return end
    P.pending = nil
    local info = spell()
    local available = info and supported() and not P.failed
    if available then
        for _, row in ipairs(A.View.rows) do
            if not row.cleanseHost and not P.failed then create(row, info) end
        end
    end
    local enabled = available and not P.failed and not A.View.unlocked
    for _, row in ipairs(A.View.rows) do
        if row.cleanseHost then
            local driver = enabled and ("[group:raid] hide; [@" .. row.unit .. ",exists,nodead,help] show; hide") or "hide"
            if row.cleanseDriver ~= driver then
                RegisterStateDriver(row.cleanseHost, "visibility", driver); row.cleanseDriver = driver
            end
        end
    end
    P.status = P.failed and "Native Purify control could not be initialized."
        or (not info and "Purify is not available as a learned Paladin spell.")
        or (not available and "Native poison controls are unavailable on this client.")
        or "Purify is configured for native poison indicators."
    if A.Settings and A.Settings.cleanseStatus then A.Settings.cleanseStatus:SetText(P.status) end
end
