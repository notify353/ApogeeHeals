local addonName, A = ...
-- Shared preference protocol v1; keep identical in Heals and Keybinds.
-- Only this preference is mirrored. Assignment tables are never read or written.
local function JoinDefaultSpells(registry, getDB, refresh, container)
    local function choice(value)
        if type(value) ~= "table" or type(value.enabled) ~= "boolean"
            or type(value.time) ~= "number" or value.time < 0 or value.time ~= value.time
            or value.time == math.huge or type(value.serial) ~= "number"
            or value.serial < 0 or value.serial ~= value.serial or value.serial == math.huge then
            return {enabled=false, time=0, serial=0}
        end
        return {enabled=value.enabled, time=value.time, serial=value.serial}
    end
    local function newer(a, b)
        return a.time > b.time or (a.time == b.time and (a.serial > b.serial
            or (a.serial == b.serial and not a.enabled and b.enabled)))
    end
    local policy = registry.defaultSpells
    if not policy then
        policy = {value={enabled=false,time=0,serial=0}, consumers={}}
        registry.defaultSpells = policy
        function policy:Apply()
            for _, consumer in pairs(self.consumers) do
                local db = consumer.getDB()
                local old = choice(db.defaultSpells)
                db.defaultSpells = choice(self.value)
                if old.enabled ~= self.value.enabled then consumer.refresh() end
            end
            if self.check then
                self.check:SetChecked(self.value.enabled)
                self.check:SetEnabled(not InCombatLockdown())
                local color = InCombatLockdown() and 0.5 or 1
                self.check.label:SetTextColor(color, color, color)
            end
        end
        function policy:Set(enabled)
            if InCombatLockdown() then self:Apply(); return false end
            local now = GetServerTime()
            self.value = {enabled=enabled == true, time=math.max(now,self.value.time),
                serial=now > self.value.time and 0 or self.value.serial + 1}
            self:Apply()
            return true
        end
    end
    policy.consumers[addonName] = {getDB=getDB, refresh=refresh}
    local saved = choice(getDB().defaultSpells)
    if newer(saved, policy.value) then policy.value = saved end
    local overview = container -- Only Keybinds supplies the feature settings container.
    if overview and not policy.check then
        local check = CreateFrame("CheckButton", nil, overview, "UICheckButtonTemplate")
        policy.check = check
        check:SetPoint("TOPLEFT", 12, -84); check:SetSize(24, 24)
        check.label = overview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check.label:SetText("Enable default spells")
        check:SetScript("OnClick", function(self) policy:Set(self:GetChecked()) end)
        check:SetScript("OnShow", function() policy:Apply() end)
        check:RegisterEvent("PLAYER_REGEN_DISABLED"); check:RegisterEvent("PLAYER_REGEN_ENABLED")
        check:SetScript("OnEvent", function() policy:Apply() end)
    end
    policy:Apply()
    return policy.check
end
-- End shared preference protocol.

-- Each independent addon joins one family-local native settings parent.
local function RegisterApogeeCategory(panel, label, standaloneTitle)
    if type(Settings.RegisterCanvasLayoutSubcategory) ~= "function" then
        return Settings.RegisterCanvasLayoutCategory(panel, standaloneTitle)
    end
    local registry = _G.ApogeeSettingsRegistry
    if registry ~= nil and (type(registry) ~= "table" or registry.schema ~= 1
        or type(registry.category) ~= "table" or type(registry.category.GetID) ~= "function"
        or type(registry.children) ~= "table") then return nil end
    if not registry then
        local parentName = addonName:sub(-3) == "Dev" and "Apogee DEV" or "Apogee"
        local overview = CreateFrame("Frame")
        local background = overview:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(overview)
        background:SetColorTexture(0.035, 0.035, 0.045, 0.96)
        local title = overview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16); title:SetText(parentName)
        local description = overview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        description:SetPoint("TOPLEFT", 16, -52)
        description:SetPoint("TOPRIGHT", -16, -52)
        description:SetJustifyH("LEFT"); description:SetTextColor(0.8, 0.8, 0.8)
        description:SetText("Select an enabled addon's settings from the list on the left.")
        local parent = Settings.RegisterCanvasLayoutCategory(overview, parentName)
        Settings.RegisterAddOnCategory(parent)
        registry = {schema = 1, category = parent, children = {}, overview = overview}
        _G.ApogeeSettingsRegistry = registry
    end
    JoinDefaultSpells(registry, function() return A.db end, function() A.Bindings.Apply() end)
    local existing = registry.children[label]
    if existing ~= nil then
        if type(existing) == "table" and type(existing.GetID) == "function" then return existing end
        return nil
    end
    local category = Settings.RegisterCanvasLayoutSubcategory(registry.category, panel, label)
    registry.children[label] = category
    return category
end

local S = {}
A.Settings = S
function S.ResetPositions()
    if InCombatLockdown() then return end
    A.View.Lock(); A.View.pendingPosition = nil
    A.View.ResetPosition(); A.BindingEditor.ResetPosition(); A.Minimap.ResetPosition()
    if A.ThreatView.root then A.ThreatView.ResetPosition() end
    S.Refresh()
end
function S.Refresh()
    A.Minimap.Refresh()
    if not S.defaults then return end
    S.defaults:SetEnabled(not InCombatLockdown())
    S.buffs:SetEnabled(not InCombatLockdown())
    if S.threat then
        S.threat:SetEnabled(not InCombatLockdown())
        local color = InCombatLockdown() and 0.5 or 1
        S.threat.label:SetTextColor(color, color, color)
        S.threat:SetChecked(A.db.threatEnabled == true)
    end
    S.cleanseStatus:SetText(A.Cleansing.status or "Purify configuration is pending.")
    if S.threatDiagnostics then
        S.threatDiagnostics:SetEnabled(not InCombatLockdown())
        local color = InCombatLockdown() and 0.5 or 1
        S.threatDiagnostics.label:SetTextColor(color, color, color)
        S.threatDiagnostics:SetChecked(A.ThreatDiagnostics.enabled)
    end
    if S.threatDemo then
        S.threatDemo:SetEnabled(not InCombatLockdown())
        local color = InCombatLockdown() and 0.5 or 1
        S.threatDemo.label:SetTextColor(color, color, color)
        S.threatDemo:SetChecked(A.Threat.demo == true)
    end
end
function S.Create()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local panel = CreateFrame("Frame")
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetColorTexture(0.035, 0.035, 0.045, 0.96)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("Apogee Heals")
    S.buffs = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.buffs:SetPoint("TOPLEFT", 16, -48); S.buffs:SetSize(180, 24)
    S.buffs:SetText("Buff reminders")
    S.buffs:SetScript("OnClick", function() A.Buffs.OpenPicker() end)
    S.cleanseStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    S.cleanseStatus:SetTextColor(0.8, 0.8, 0.8)
    S.cleanseStatus:SetPoint("TOPLEFT", 16, -88)
    S.threat = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threat:SetPoint("TOPLEFT", 12, -114); S.threat:SetSize(24, 24)
    local threatLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    S.threat.label = threatLabel
    threatLabel:SetPoint("LEFT", S.threat, "RIGHT", 4, 0); threatLabel:SetText("Tank threat stack")
    S.threat:SetScript("OnClick", function(button) A.Threat.SetEnabled(button:GetChecked()); S.Refresh() end)
    S.threatDiagnostics = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threatDiagnostics:SetPoint("TOPLEFT", 12, -146); S.threatDiagnostics:SetSize(24, 24)
    local diagnosticLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    S.threatDiagnostics.label = diagnosticLabel
    diagnosticLabel:SetPoint("LEFT", S.threatDiagnostics, "RIGHT", 4, 0)
    diagnosticLabel:SetText("Threat checks (freeze after combat; until reload)")
    S.threatDiagnostics:SetScript("OnClick", function(button)
        A.ThreatDiagnostics.SetEnabled(button:GetChecked()); S.Refresh()
    end)
    S.threatDemo = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    S.threatDemo:SetPoint("TOPLEFT", 12, -178); S.threatDemo:SetSize(24, 24)
    local demoLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    S.threatDemo.label = demoLabel
    demoLabel:SetPoint("LEFT", S.threatDemo, "RIGHT", 4, 0)
    demoLabel:SetText("Threat demo (solo preview; ends in combat)")
    S.threatDemo:SetScript("OnClick", function(button) A.Threat.SetDemo(button:GetChecked()) end)
    S.healthDiagnostics = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.healthDiagnostics:SetPoint("TOPLEFT", 16, -218); S.healthDiagnostics:SetSize(200, 24)
    S.healthDiagnostics:SetText("Focus health checks")
    S.healthDiagnostics:SetScript("OnClick", function() A.HealthDiagnostics.Open() end)
    StaticPopupDialogs.APOGEE_HEALS_RESET_CHARACTER = {
        text = "Restore Apogee Heals defaults for this character?\n\nClears healing assignments, buff reminders and positions and restores defaults. This cannot be undone.\n\nOther characters, other addons and WoW keybindings are unchanged.",
        button1 = "Defaults", button2 = CANCEL or "Cancel",
        timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function() A.ResetCharacter() end,
    }
    S.defaults = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    S.defaults:SetPoint("TOPRIGHT", -16, -12); S.defaults:SetSize(100, 24)
    S.defaults:SetText("Defaults")
    S.defaults:SetScript("OnClick", function()
        if not InCombatLockdown() then StaticPopup_Show("APOGEE_HEALS_RESET_CHARACTER") end
    end)
    panel.OnDefault = function() A.ResetCharacter() end
    panel:SetScript("OnShow", S.Refresh)
    S.category = RegisterApogeeCategory(panel, "Heals", "Apogee Heals")
    if not S.category then return end
    Settings.RegisterAddOnCategory(S.category); S.Refresh()
end
