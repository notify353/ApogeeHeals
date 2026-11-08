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
local expectedRanks = {
    PRIEST = {139,6074,6075,6076,6077,6078,10927,10928,10929,25315},
    DRUID = {774,1058,1430,2090,2091,3627,8910,9839,9840,9841,25299},
    SHAMAN = {408521,1239242,1239243},
}
for _, class in ipairs({"PRIEST", "DRUID", "SHAMAN"}) do
    local m, a, containers = fixture(class)
    assert(#containers==7)
    local rows = {unpack(a.View.rows)}
    rows[#rows+1], rows[#rows+2] = a.View.target, a.View.targetTarget
    for index, row in ipairs(rows) do
        local c = containers[index]
        assert(row.hotContainer==c and c.enabled and c.unit==row.unit)
        assert(c.filter=="HELPFUL|PLAYER" and c.options.maxFrameCount==1)
        local ids = c.options.candidateFilters.includeSpellIDs
        for _, id in ipairs(expectedRanks[class]) do assert(ids[id], "missing HoT rank "..id) end
        local count=0
        for _ in pairs(ids) do count=count+1 end
        assert(count==#expectedRanks[class], "unexpected HoT identity")
        -- Exclude shields, Regrowth, NPC Riptide, its rune wrapper and Retail ranks.
        assert(not ids[17] and not ids[8936] and not ids[22419]
            and not ids[409954] and not ids[61295])
        assert(c.parent.driver=="[@"..row.unit..",help,nodead] show; hide")
        assert(c.parent.point[2]==row.health and c.parent.point[1]=="BOTTOMLEFT")
        assert(c.parent.width==a.Style.width-a.Style.classStripHitWidth and c.parent.height==1.5)
        assert(c.parent.level>row.nameLayer.level and c.parent.mouse==false)
        assert(c.button.mouse==false and c.button.duration.mouse==false)
        assert(c.button.duration.allPoints==c.button)
        for channel=1,4 do assert(c.button.duration.color[channel]==1, "HoT must stay white") end
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
for _, class in ipairs({"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "MAGE", "WARLOCK"}) do
    local _, _, unsupported = fixture(class)
    assert(#unsupported==0)
end
local _, _, absent = fixture("PRIEST", true)
assert(#absent==0)
local m, a, failed = fixture("PRIEST", false, true)
assert(#failed==7 and a.startupState=="failed")
for _, c in ipairs(failed) do assert(not c.enabled) end
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
for _, c in ipairs(failed) do assert(not c.enabled) end
C_XMLUtil, C_AuraContainerUtil = oldXML, oldUtil
print("PASS own HoT native configuration, seven fixed recipients, rank families, combat, preview, roster, target aliases, zoning and absent capabilities")
