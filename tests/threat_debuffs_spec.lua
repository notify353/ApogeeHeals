local Mock=dofile("tests/mock.lua")
local m=Mock.New(); local a=m.Start(); local v=a.ThreatView
local containers,buttons={},{}
C_XMLUtil={GetTemplateInfo=function() return {type="AuraContainer"} end}
local create=CreateFrame
CreateFrame=function(kind,name,parent,template)
    local frame=create(kind,name,parent,template)
    if template=="CustomAuraContainerTemplate" then
        assert(not m.combat); containers[#containers+1]=frame
        function frame:SetUnit(unit) assert(type(unit)=="string"); self.unit=unit end
        function frame:SetEnabled(enabled) self.enabled=enabled end
        function frame:AddAuraGroup(key,filter,options)
            self.options=options; self.filter=filter
            local button=create("AuraButton",nil,self)
            function button:SetCancelAuraButtons(value) assert(value==nil) end
            function button:SetTooltipAnchorPoint(value) self.tooltipAnchor=value end
            function button:SetApplicationCount(label) self.count=label end
            options.initializeFrame(button); buttons[#buttons+1]=button
        end
    end
    return frame
end
v.PrepareDebuffs(); assert(#containers==24 and #buttons==24)
v.PrepareDebuffs(); assert(#containers==24)
for i,c in ipairs(containers) do
    assert(c.filter=="HARMFUL|PLAYER" and c.options.maxFrameCount==1)
    assert(c.options.candidateFilters.includeSpellIDs and c.options.layout.elementHeight==7)
    assert(not c.enabled and c.unit==nil)
end
assert(containers[1].options.candidateFilters.includeSpellIDs[7386])
assert(containers[1].options.candidateFilters.includeSpellIDs[11597])
assert(containers[2].options.candidateFilters.includeSpellIDs[6343])
assert(containers[3].options.candidateFilters.includeSpellIDs[1160])
assert(buttons[1].count and not buttons[2].count)
C_UnitAuras.GetAuraDataByIndex=function() error("Lua must not enumerate auras") end
m.combat=true; local row=v.rows[1]
a.ThreatModel.PaintDebuffs(row,"nameplate7")
for _,c in ipairs(row.debuffContainers) do assert(c.unit=="nameplate7" and c.enabled) end
assert(not row.debuffs[1].shown and not row.debuffs[2].shown)
v.ClearRow(row)
for _,c in ipairs(row.debuffContainers) do assert(not c.enabled) end
a.ThreatModel.PaintDebuffs(row,"nameplate8")
for _,c in ipairs(row.debuffContainers) do assert(c.unit=="nameplate8" and c.enabled) end
v.PaintDemo(0)
for _,c in ipairs(containers) do assert(not c.enabled) end
assert(v.rows[1].debuffs[1].text:sub(1,1)=="S")
print("PASS native enemy aura containers: player filter, spell ranks, native stacks, zero Lua scans, fixed layout, reuse and demo cleanup")

C_XMLUtil=nil; CreateFrame=create -- Do not leak native template mocks into the next generated fixture.
