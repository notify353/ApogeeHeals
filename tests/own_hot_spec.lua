local Mock = dofile("tests/mock.lua")
local oldXML, oldUtil = C_XMLUtil, C_AuraContainerUtil
local function fixture(class, unavailable, failStartup)
    local m = Mock.New()
    m.units.player.class = class
    C_XMLUtil = {GetTemplateInfo = function() return {type="AuraContainer"} end}
    C_AuraContainerUtil = {ProcessCustomAuraButtonDurationBarOptions=function() end}
    if unavailable then C_AuraContainerUtil=nil end
    local create = CreateFrame
    local containers = {}
    CreateFrame = function(kind, name, parent, template)
        local frame = create(kind, name, parent, template)
        if template == "CustomAuraContainerTemplate" then
            function frame:AddAuraSlot() end
            function frame:SetAuraSlotCandidateFilters() end
            function frame:SetUnit(unit) assert(not m.combat); self.unit=unit end
            function frame:SetEnabled(enabled) self.enabled=enabled end
            function frame:UpdateAllAuras() self.refreshes=(self.refreshes or 0)+1 end
            function frame:AddAuraGroup(key, filter, options)
                if key ~= "ownPrimaryHot" then return end
                assert(not m.combat)
                self.filter, self.options = filter, options
                containers[#containers+1] = self
                local button = create("AuraButton", nil, self)
                self.button = button
                function button:SetCancelAuraButtons(value) assert(value==nil) end
                function button:SetDurationBar(duration, settings)
                    self.duration, self.settings = duration, settings
                end
                function button:IsShown() error("native visibility must not be read") end
                options.initializeFrame(button)
            end
        end
        return frame
    end
    local a = m.Load()
    if failStartup then a.Threat.Start=function() error("injected post-HoT startup failure") end end
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    assert(a.started == not failStartup)
    return m, a, containers
end
for _, class in ipairs({"PRIEST", "DRUID"}) do
    local m, a, containers = fixture(class)
    assert(#containers==7)
    local rows = {unpack(a.View.rows)}
    rows[#rows+1], rows[#rows+2] = a.View.target, a.View.targetTarget
    for index, row in ipairs(rows) do
        local c = containers[index]
        assert(row.hotContainer==c and c.enabled and c.unit==row.unit)
        assert(c.filter=="HELPFUL|PLAYER" and c.options.maxFrameCount==1)
        local ids = c.options.candidateFilters.includeSpellIDs
        assert(ids[class=="PRIEST" and 139 or 774])
        assert(ids[class=="PRIEST" and 25315 or 25299])
        assert(not ids[class=="PRIEST" and 774 or 139] and not ids[17])
        assert(c.parent.driver=="[@"..row.unit..",help,nodead] show; hide")
        assert(c.parent.point[2]==row.health and c.parent.point[1]=="BOTTOMLEFT")
        assert(c.parent.width==a.Style.width-a.Style.classStripHitWidth and c.parent.height==1.5)
        assert(c.parent.level>row.nameLayer.level and c.parent.mouse==false)
        assert(c.button.mouse==false and c.button.duration.mouse==false)
        assert(c.button.duration.allPoints==c.button and c.button.duration.color[1]==1)
        assert(c.button.settings.direction==Enum.StatusBarTimerDirection.RemainingTime)
        assert(c.button.settings.interpolation==Enum.StatusBarInterpolation.Immediate)
        assert(not next(c.button.scripts) and not next(c.button.attributes))
        assert(row.attributes.unit==row.unit and row.template=="SecureActionButtonTemplate")
    end
    a.View.SetUnlocked(true)
    for _, c in ipairs(containers) do assert(not c.enabled) end
    a.View.SetUnlocked(false)
    for _, c in ipairs(containers) do assert(c.enabled) end
    m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
    for _, c in ipairs(containers) do assert(c.enabled) end
    local before=containers[6].refreshes or 0
    m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    assert(containers[6].refreshes>before)
    before=containers[7].refreshes or 0
    a.View.targetTarget.scripts.OnUpdate(a.View.targetTarget,0.2)
    assert(containers[7].refreshes>before)
    before=containers[2].refreshes or 0
    m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    assert(containers[2].refreshes>before)
    m.Event("PLAYER_LEAVING_WORLD")
    for _, c in ipairs(containers) do assert(not c.enabled) end
    m.Flush(); a.View.RefreshHotRecipients()
    for _, c in ipairs(containers) do assert(not c.enabled) end
    m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
    for _, c in ipairs(containers) do assert(c.enabled) end
end
local _, _, unsupported = fixture("WARRIOR")
assert(#unsupported==0)
local _, _, absent = fixture("PRIEST", true)
assert(#absent==0)
local m, a, failed = fixture("PRIEST", false, true)
assert(#failed==7 and a.startupState=="failed")
for _, c in ipairs(failed) do assert(not c.enabled) end
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
for _, c in ipairs(failed) do assert(not c.enabled) end
C_XMLUtil, C_AuraContainerUtil = oldXML, oldUtil
print("PASS own HoT native configuration, seven fixed recipients, rank families, combat, preview, roster, target aliases, zoning and absent capabilities")
