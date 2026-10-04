local _, A = ...
local M, read = {}, A.Access.Read
A.ThreatMarkers = M

local function enabled()
    return A.db.threatEnabled == true and not A.Threat.demo and not A.Threat.suspended
end

-- Only public classification/availability may prepare a physical click.
-- Existing target icons are checked by Blizzard's secure set-unmarked action.
local function candidate()
    if not enabled() or read(UnitCanAttack, "player", "target") ~= true then return end
    local boss, classification = read(UnitIsBossMob, "target"), read(UnitClassification, "target")
    local marker
    if boss == true or classification == "worldboss" then
        marker = 2
    elseif boss == false then
        local mana = read(UnitHasPowerType, "target", 0)
        if mana == nil and read(UnitPowerType, "target") == 0 then
            local capacity = read(UnitPowerMax, "target", 0)
            mana = type(capacity) == "number" and capacity > 0
        end
        if mana == true then marker = 8 end
    end
    if not marker then return end
    local available = read(GetNextAvailableRaidTargetMarkerIndex, marker, false, false, true)
    if available ~= marker then return nil, "Icon unavailable" end
    return marker
end

function M.Refresh()
    if not M.button or InCombatLockdown() then return end
    -- Never leave an action armed between clicks or across combat/target changes.
    M.button:SetAttribute("type1", nil)
    RegisterStateDriver(M.button, "visibility", enabled()
        and "[combat] hide; [@target,harm,nodead] show; hide" or "hide")
    local marker, reason = candidate()
    M.label:SetText(marker == 2 and "Mark circle" or marker == 8 and "Mark skull" or reason or "No priority mark")
end

function M.Start()
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    M.button = button
    -- Independent of the threat frame: adding a protected child would restrict
    -- that frame's existing combat visibility and rendering lifecycle.
    button:SetSize(110, 22)
    button:SetPoint("BOTTOM", UIParent, "CENTER", 0, 14)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("unit", "target")
    button:SetAttribute("action", "set-unmarked")
    button:SetAttribute("useOnKeyDown", false)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(); background:SetColorTexture(0.08, 0.10, 0.13, 0.9)
    M.label = A.Style.CleanText(button, 11); M.label:SetAllPoints()
    button:SetScript("PreClick", function(self, mouseButton)
        if InCombatLockdown() then return end
        self:SetAttribute("type1", nil)
        if mouseButton ~= "LeftButton" then return end
        local marker = candidate()
        if marker then
            self:SetAttribute("marker", marker)
            self:SetAttribute("type1", "raidtarget")
        end
    end)
    button:SetScript("PostClick", function(self)
        if not InCombatLockdown() then self:SetAttribute("type1", nil) end
    end)
    M.frame = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE", "PLAYER_REGEN_ENABLED",
        "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "UNIT_DISPLAYPOWER", "UNIT_MAXPOWER"}) do
        M.frame:RegisterEvent(event)
    end
    M.frame:SetScript("OnEvent", function() M.Refresh() end)
    M.Refresh()
end
