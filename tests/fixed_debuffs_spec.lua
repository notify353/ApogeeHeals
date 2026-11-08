local Mock = dofile("tests/mock.lua")
local kinds = {"Magic", "Disease", "Poison", "Curse", "Other"}
local cases = {
    PALADIN={4987,1152,1152,false}, PRIEST={988,528,false,false},
    SHAMAN={false,2870,526,false}, DRUID={false,false,8946,2782},
    MAGE={false,false,false,475}, WARRIOR={false,false,false,false},
    ROGUE={false,false,false,false}, HUNTER={false,false,false,false},
    WARLOCK={false,false,false,false},
}
local function fixture(class, option)
    option = option or {}
    local m = Mock.New()
    m.units.player.class = class
    m.unknown = {}
    Enum.SpellBookSpellBank = {Player=0}
    C_Spell.GetSpellInfo = function(id) return {spellID=id,name="Spell "..id,iconID=id+100000} end
    C_Spell.IsSpellHelpful = function() return true end
    C_Spell.IsSpellHarmful = function(id) return id==988 or id==527 end
    C_Spell.IsSpellPassive = function() return false end
    C_SpellBook = {IsSpellInSpellBook=function(id, bank, overrides)
        assert(bank==0 and overrides==false); return not m.unknown[id]
    end, IsSpellKnown=function(id) return not m.unknown[id] end}
    local globals = {"C_XMLUtil", "AuraContainerSortMethod", "AuraContainerSortDirection",
        "CustomAuraContainerSharedMixin", "CustomAuraButtonSharedMixin", "AuraButtonSharedMixin"}
    local previous = {}
    for _, key in ipairs(globals) do previous[key]=_G[key] end
    AuraContainerSortMethod = {AuraInstanceIDOnly=8}
    AuraContainerSortDirection = {Reverse=1}
    CustomAuraContainerSharedMixin = {AddAuraSlot=function() end,SetAuraSlotCandidateFilters=function() end}
    CustomAuraButtonSharedMixin = {SetIcon=function() end}
    AuraButtonSharedMixin = {SetHideTooltipInCombat=function() end}
    C_XMLUtil = {GetTemplateInfo=function() return {type="AuraContainer"} end}
    if option.noSort then AuraContainerSortMethod=nil end
    local create = CreateFrame
    CreateFrame = function(kind, name, parent, template)
        local frame = create(kind, name, parent, template)
        if template=="CustomAuraContainerTemplate" then
            frame.slots, frame.refreshes = {}, 0
            function frame:SetUnit(unit) assert(not m.combat); self.unit=unit end
            function frame:UpdateAllAuras() self.refreshes=self.refreshes+1 end
            function frame:AddAuraGroup(_, filter, config) self.group=config end
            function frame:AddAuraSlot(key, filter, config)
                assert(not m.combat and filter=="HARMFUL" and not config.templateNames)
                local visual = create("AuraButton", nil, self, "CustomAuraButtonTemplate")
                function visual:SetCancelAuraButtons(value) assert(value==nil) end
                function visual:SetTooltipAnchorPoint(value) self.tooltipAnchor=value end
                function visual:SetHideTooltipInCombat(value) self.hideTooltipInCombat=value end
                function visual:SetIcon(value) self.nativeIcon=value end
                config.initializeFrame(visual)
                assert(not next(visual.scripts) and not next(visual.attributes))
                visual.IsShown=function() error("addon read native aura visibility") end
                visual.GetAuraInstance=function() error("addon read native aura") end
                self.slots[key]={frame=visual, config=config, filters=config.candidateFilters}
            end
            function frame:SetAuraSlotCandidateFilters(key, filters)
                assert(not m.combat); self.slots[key].filters=filters
            end
        end
        return frame
    end
    local a=m.Load()
    if option.fail then a.Threat.Start=function() error("injected startup failure") end end
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    for _, key in ipairs(globals) do _G[key]=previous[key] end
    assert(a.started==not option.fail)
    return m,a
end
local instances = {}
for class, expected in pairs(cases) do
    local m,a=fixture(class)
    instances[#instances+1]={m=m,a=a}
    assert(#a.View.supportRows==6 and not a.View.targetTarget.debuffContainer)
    for _,row in ipairs(a.View.supportRows) do
        assert(row.fixedDebuffs and row.cleanseSlotCount==5 and #row.cleanseButtons==4)
        local icons, highlights = row.debuffContainer, row.cleanseIndicator
        assert(not icons.group and icons.unit==row.unit and highlights.unit==row.unit)
        assert(icons.parent==highlights.parent and icons.parent.driver=="[@"..row.unit..",help,nodead] show; hide")
        assert(icons.parent.point[2]==row.health and icons.parent.point[4]==a.Style.sideIconGap)
        assert(icons.width==5*a.Style.sideIconSize+4*a.Style.sideIconGap)
        assert(row.drinkIcon.point[4]==a.Style.sideIconGap+5*(a.Style.sideIconSize+a.Style.sideIconGap))
        for index,kind in ipairs(kinds) do
            local slot=assert(icons.slots[kind])
            local visual=slot.frame
            assert(slot.config.sortMethod==8 and slot.config.sortDirection==1)
            assert(visual.mouse==false and visual.mouseMotion==true)
            assert(visual.tooltipAnchor=="ANCHOR_RIGHT" and visual.hideTooltipInCombat==false)
            assert(visual.nativeIcon and not visual.nativeIcon.texture, "native aura icon must supply artwork")
            assert(visual.point[2]==icons.parent and visual.point[4]==(index-1)*(a.Style.sideIconSize+a.Style.sideIconGap))
            if index<=4 then
                assert(slot.filters.includeDispelTypes[kind])
                local button=row.cleanseButtons[index]
                assert(button.parent==icons.parent and button.parent~=icons)
                assert(button.point[2]==icons.parent and button.point[4]==visual.point[4])
                assert(button.template=="SecureActionButtonTemplate" and not next(button.scripts) and not button.icon)
                assert(button.attributes.unit==row.unit and button.attributes.useOnKeyDown==false)
                assert(button.clicks[1]=="LeftButtonUp" and button.attributes.spell1==(expected[index] or nil))
                assert(button.driver==(expected[index] and "show" or "hide"))
                for _,prefix in ipairs({"shift-","ctrl-","ctrl-shift-","alt-","alt-shift-","alt-ctrl-","alt-ctrl-shift-"}) do
                    assert(button.attributes[prefix.."type1"]=="")
                end
                local glow=highlights.slots[kind]
                assert((glow.filters.includeDispelTypes[kind]==true)==(expected[index]~=false))
                assert(glow.config.sortMethod==slot.config.sortMethod and glow.config.sortDirection==slot.config.sortDirection)
                assert(glow.frame.mouse==false and not glow.frame.mouseMotion)
                assert(button.level<visual.level and visual.level<glow.frame.level)
                local edges=0
                for _,child in ipairs(m.frames) do
                    if child.parent==glow.frame and child.kind=="Texture" then
                        edges=edges+1; assert(child.width==1 or child.height==1, "highlight obscures icon")
                    end
                end
                assert(edges==4)
            else
                assert(not highlights.slots.Other and not row.cleanseButtons[5])
                for i=1,4 do assert(slot.filters.excludeDispelTypes[kinds[i]]) end
            end
        end
    end
    a.View.SetUnlocked(true)
    for _,row in ipairs(a.View.supportRows) do
        assert(not row.debuffContainer.enabled and not row.cleanseIndicator.enabled)
        for _,button in ipairs(row.cleanseButtons) do assert(button.driver=="hide" and not button.spell) end
    end
    a.View.SetUnlocked(false)
    local reads=m.auraReads
    m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
    m.Event("UNIT_AURA","party1"); m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    local before=a.View.target.debuffContainer.refreshes
    m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    assert(a.View.target.debuffContainer.refreshes>before and m.auraReads==reads)
    for _,id in ipairs(expected) do if id then m.unknown[id]=true end end
    m.Event("SPELLS_CHANGED"); m.Flush()
    for i,id in ipairs(expected) do assert(a.View.target.cleanseButtons[i].spell==(id or nil)) end
    m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
    local fallback={PRIEST={527,552,false,false},DRUID={false,false,2893,false}}
    for i,id in ipairs(fallback[class] or {false,false,false,false}) do
        assert(a.View.target.cleanseButtons[i].spell==(id or nil))
    end
    m.Event("PLAYER_LEAVING_WORLD"); m.Flush()
    for _,row in ipairs(a.View.supportRows) do
        assert(not row.debuffContainer.enabled and not row.cleanseIndicator.enabled)
        for _,button in ipairs(row.cleanseButtons) do assert(not button.spell) end
    end
    m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
    assert(a.View.target.debuffContainer.enabled and a.View.target.cleanseIndicator.enabled)
end
local _,failed=fixture("PRIEST",{fail=true})
for _,row in ipairs(failed.View.supportRows) do
    assert(not row.debuffContainer.enabled and not row.cleanseIndicator.enabled)
    for _,button in ipairs(row.cleanseButtons) do assert(not button.spell) end
end
local _,fallback=fixture("PRIEST",{noSort=true})
assert(not fallback.View.target.fixedDebuffs and #fallback.View.target.cleanseButtons==3)
print("PASS fixed type slots, native hover/click separation, learned ranks, empty/Other slots, lifecycle, combat deferral and capability fallback")

-- Exercise exact native release dispatch for the new transparent secure buttons.
local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP native fixed-slot dispatch (no export)"); return end
local file=assert(io.open(root.."/Blizzard_FrameXML/SecureTemplates.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n"); file:close()
local function definition(name)
    local start=assert(source:find("function "..name,1,true))
    return source:sub(start,assert(source:find("\nend",start,true))+3)
end
local env=setmetatable({}, {__index=_G})
local function execute(code) local f=assert(loadstring(code)); setfenv(f,env); return f() end
local casts,lastID,lastUnit=0
env.SecureButton_GetAttribute=function(frame,key) return frame.attributes[key] end
env.SecureButton_GetModifiedAttribute=function(frame,key) return frame.attributes[key.."1"] end
env.CastSpellByID=function(id,unit) casts,lastID,lastUnit=casts+1,id,unit end
env.CastSpellByName=function() error("lost exact ID") end
env.GetCVarBool=function() return true end
env.OnActionButtonPressAndHoldRelease=function() error("unexpected held action") end
local cast=execute("return "..assert(source:match("SECURE_ACTIONS%.spell%s*=%s*(function.-\n    end);")))
env.OnActionButtonClick=function(frame,button)
    if frame.attributes.type1=="spell" then cast(frame,frame.attributes.unit,button) end
end
execute(definition("SecureActionButton_ShouldUseOnKeyDown").."\n"..definition("SecureActionButton_OnClick"))
for _,instance in ipairs(instances) do
    for _,row in ipairs(instance.a.View.supportRows) do
        for _,button in ipairs(row.cleanseButtons) do
            local before=casts
            env.SecureActionButton_OnClick(button,"LeftButton",true); assert(casts==before)
            env.SecureActionButton_OnClick(button,"LeftButton",false)
            assert(casts==before+(button.spell and 1 or 0))
            if button.spell then assert(lastID==button.spell and lastUnit==row.unit) end
        end
    end
end
print("PASS retained-export fixed type action exact-recipient/rank release dispatch")
