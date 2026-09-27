local Mock = dofile("tests/mock.lua")
local cases = {
    {class="PALADIN", ids={1152,4987}, types={{Poison=true,Disease=true},{Poison=true,Disease=true,Magic=true}}},
    {class="PRIEST", ids={988,528,552}, types={{Magic=true},{Disease=true},{Disease=true}}},
    {class="SHAMAN", ids={526,2870}, types={{Poison=true},{Disease=true}}},
    {class="DRUID", ids={8946,2893,2782}, types={{Poison=true},{Poison=true},{Curse=true}}},
    {class="MAGE", ids={475}, types={{Curse=true}}},
    {class="ROGUE", ids={}, types={}}, {class="HUNTER", ids={}, types={}},
    {class="WARRIOR", ids={}, types={}}, {class="WARLOCK", ids={}, types={}},
}
local allIDs = {1152,4987,527,988,528,552,526,2870,8946,2893,2782,475,19505,19731,19734,19736}
local function fixture(class, options)
    options = options or {}
    local m = Mock.New()
    m.units.player.class = class
    m.learned = {}
    for _, id in ipairs(allIDs) do m.learned[id] = not options.unlearned end
    Enum.SpellBookSpellBank = {Player=0,Pet=1}
    C_Spell.GetSpellInfo = function(id)
        if options.secretInfo then return m.InaccessibleTable() end
        return {spellID=id,name="Spell "..id,iconID=id+100000}
    end
    C_Spell.IsSpellHelpful = function() return options.helpful ~= false end
    C_Spell.IsSpellHarmful = function(id)
        if options.secretHarmful then return m.Secret() end
        return id == 527 or id == 988 or options.harmful == true
    end
    C_Spell.IsSpellPassive = function() return options.passive == true end
    C_SpellBook = {
        IsSpellInSpellBook=function(id, bank, overrides)
            assert(bank == Enum.SpellBookSpellBank.Player and overrides == false)
            if options.secretKnown then return m.Secret() end
            return m.learned[id] == true
        end,
        IsSpellKnown=function(id, bank)
            assert(bank == Enum.SpellBookSpellBank.Player)
            return not options.bookOnly and m.learned[id] == true
        end,
    }
    C_XMLUtil = not options.noTemplates and {GetTemplateInfo=function() return {type="AuraContainer"} end} or nil
    local createFrame = CreateFrame
    CreateFrame = function(kind, name, parent, template)
        local frame = createFrame(kind, name, parent, template)
        if template == "CustomAuraContainerTemplate" then
            frame.slots, frame.refreshes = {}, 0
            function frame:AddAuraSlot(key, filter, config)
                assert(filter == "HARMFUL" and not config.templateNames)
                local indicator = createFrame("AuraButton", nil, self, "CustomAuraButtonTemplate")
                indicator.SetCancelAuraButtons = function(_, value) assert(value == nil) end
                config.initializeFrame(indicator)
                assert(not next(indicator.attributes) and not next(indicator.scripts))
                assert(indicator.mouse == false)
                indicator.IsShown = function() error("native visibility must not be observed") end
                self.slots[key] = {frame=indicator,filters=config.candidateFilters}
            end
            function frame:SetAuraSlotCandidateFilters(key, filters)
                assert(not m.combat); self.slots[key].filters = filters
            end
            function frame:AddAuraGroup(_, filter, config) assert(filter=="HARMFUL"); self.group=config end
            function frame:SetUnit(unit) assert(not m.combat); self.unit=unit end
            function frame:UpdateAllAuras() self.refreshes=self.refreshes+1 end
        end
        return frame
    end
    local a=m.Load(); m.Event("ADDON_LOADED","ApogeeHeals"); m.Flush()
    return m,a
end
local function assertTypes(actual, expected)
    for _, kind in ipairs({"Magic","Disease","Poison","Curse","Bleed",""}) do
        assert((actual[kind] == true) == (expected[kind] == true), "unexpected type "..kind)
    end
end
local instances = {}
for _, case in ipairs(cases) do
    local m,a=fixture(case.class)
    instances[#instances+1]={m=m,a=a,case=case}
    assert(#a.View.supportRows == 6 and not a.View.targetTarget.cleanseButtons)
    assert(a.View.target.supportFrame.driver == "[@target,help,nodead] show; hide")
    for _, row in ipairs(a.View.supportRows) do
        local count=#case.ids
        assert((row.cleanseSlotCount or 0) == count)
        assert(row.debuffContainer.point[4] == (row.unit=="target" and a.Style.sideIconGap or a.Style.sideIconOffset)
            + count*(row.height+2))
        if count==0 then assert(not row.cleanseButtons and not row.cleanseIndicator)
        else
            assert(#row.cleanseButtons==count)
            assert(row.drinkIcon.point[4]==2+count*(row.height+2))
            for index,button in ipairs(row.cleanseButtons) do
                assert(button.attributes.spell1==case.ids[index] and button.attributes.type1=="spell")
                assert(button.attributes.unit==row.unit and button.attributes.useOnKeyDown==false)
                assert(button.clicks[1]=="LeftButtonUp" and not button.scripts.OnClick)
                assert(button.parent==(row.supportFrame or row) and button.point[2]==row.health)
                assert(button.width==row.height and button.height==row.height)
                assert(button.point[4]==2+(index-1)*(row.height+2))
                assert(button.icon.desaturated and button.icon.alpha==0.3 and button.driver=="show")
                for _,prefix in ipairs({"shift-","ctrl-","alt-","ctrl-shift-","alt-shift-","alt-ctrl-","alt-ctrl-shift-"}) do
                    assert(button.attributes[prefix.."type1"]=="")
                end
                local slot=row.cleanseIndicator.slots[row.cleanseSpells[index].key]
                assertTypes(slot.filters.includeDispelTypes,case.types[index])
                assert(slot.frame.parent==row.cleanseIndicator and slot.frame:GetFrameLevel()>button:GetFrameLevel())
            end
        end
    end
end
-- Highest rank, strict ordinary bindings and deferred action/filter changes.
local m,a=fixture("PRIEST")
assert(not a.Bindings.Resolve(527) and not a.Bindings.Resolve(988))
local button=a.View.rows[1].cleanseButtons[1]
m.learned[988]=false; m.Event("SPELLS_CHANGED"); m.Flush(); assert(button.attributes.spell1==527)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
local reads=m.auraReads
m.learned[988]=true; m.Event("SPELLS_CHANGED"); m.Flush(); assert(button.attributes.spell1==527)
m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(a.View.target.cleanseIndicator.refreshes>0 and m.auraReads==reads)
assert(a.View.target.cleanseButtons[1].attributes.unit=="target")
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush(); assert(button.attributes.spell1==988)
a.View.SetUnlocked(true); assert(button.driver=="hide" and not button.attributes.spell1)
a.View.SetUnlocked(false); assert(button.driver=="show")
m.learned[988],m.learned[527]=false,false; m.Event("SPELLS_CHANGED"); m.Flush()
assert(button.driver=="hide" and not button.attributes.spell1)
assertTypes(a.View.rows[1].cleanseIndicator.slots.dispelMagic.filters.includeDispelTypes,{})
assert(a.View.rows[1].cleanseButtons[2].driver=="show" and a.View.rows[1].cleanseButtons[3].driver=="show")
for _,options in ipairs({{unlearned=true},{helpful=false},{passive=true},{secretInfo=true},{secretKnown=true},
    {secretHarmful=true},{bookOnly=true}}) do
    local _,invalid=fixture("PRIEST",options)
    for _,row in ipairs(invalid.View.supportRows) do
        assert(row.cleanseButtons[1].driver=="hide" and not row.cleanseButtons[1].attributes.spell1)
    end
end
local _,noGlow=fixture("PRIEST",{noTemplates=true})
assert(not noGlow.View.target.cleanseIndicator and noGlow.View.target.cleanseButtons[1].attributes.spell1==988)
local _,harmful=fixture("MAGE",{harmful=true})
assert(not harmful.View.target.cleanseButtons[1].attributes.spell1)
C_XMLUtil=nil
print("PASS class cleansing types, highest ranks, six fixed units, geometry, independent actions, restricted/API fallbacks and combat deferral")

local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP native multiclass cleansing contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local file=assert(io.open(root.."/"..path,"rb"))
    local data=file:read("*a"):gsub("\r\n","\n"); file:close(); return data
end
local function definition(source,name)
    local start=assert(source:find("function "..name,1,true))
    local finish=assert(source:find("\nend",start,true)); return source:sub(start,finish+3)
end
local function execute(code,env)
    local chunk=assert(loadstring(code)); setfenv(chunk,env); return chunk()
end
local env=setmetatable({}, {__index=_G})
env.AuraContainerUtil={CanApplyIdentityCandidateFilters=function() return false end}
execute(definition(read("Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua"),
    "AuraContainerUtil.DoesAuraPassCandidateFilters"),env)
local source=read("Blizzard_FrameXML/SecureTemplates.lua")
local cast=execute("return "..assert(source:match("SECURE_ACTIONS%.spell%s*=%s*(function.-\n    end);")),env)
local count,lastID,lastUnit=0
env.SecureButton_GetAttribute=function(frame,key) return frame.attributes[key] end
env.SecureButton_GetModifiedAttribute=function(frame,key) return frame.attributes[key.."1"] end
env.CastSpellByID=function(id,unit) count,lastID,lastUnit=count+1,id,unit end
env.CastSpellByName=function() error("lost exact spell rank") end
env.GetCVarBool=function() return true end
env.OnActionButtonPressAndHoldRelease=function() error("unexpected held action") end
env.OnActionButtonClick=function(frame,button) cast(frame,frame.attributes.unit,button) end
execute(definition(source,"SecureActionButton_ShouldUseOnKeyDown").."\n"
    ..definition(source,"SecureActionButton_OnClick"),env)
for _,instance in ipairs(instances) do
    for _,row in ipairs(instance.a.View.supportRows) do
        for index,button in ipairs(row.cleanseButtons or {}) do
            local before=count
            env.SecureActionButton_OnClick(button,"LeftButton",true); assert(count==before)
            env.SecureActionButton_OnClick(button,"LeftButton",false)
            assert(count==before+1 and lastID==instance.case.ids[index] and lastUnit==row.unit)
            local config={includeDispelTypes=instance.case.types[index]}
            for _,kind in ipairs({"Magic","Disease","Poison","Curse","Bleed",""}) do
                assert(env.AuraContainerUtil.DoesAuraPassCandidateFilters(row.unit,{dispelName=kind},config)
                    == (config.includeDispelTypes[kind]==true))
            end
        end
    end
end
print("PASS matching-export multiclass filters and exact-rank fixed-recipient release dispatch; live engine acceptance remains separate")

-- Native pet dispatch supports fixed recipients, but does not bind the slot
-- to an expected spell ID. Simulated reassignment demonstrates that contract,
-- not which pet/bar transitions the live engine permits during combat.
local petCast=execute("return "..assert(source:match("SECURE_ACTIONS%.pet%s*=%s*(function.-\n    end);")),env)
local petSlotSpell,seenSlot,seenUnit,seenSpell=19505
env.CastPetAction=function(slot,unit) seenSlot,seenUnit,seenSpell=slot,unit,petSlotSpell end
local petButton={attributes={type1="pet",action1=4,spell1=19505,unit="party2"}}
petCast(petButton,"party2","LeftButton")
assert(seenSlot==4 and seenUnit=="party2" and seenSpell==19505)
petSlotSpell=7814
petCast(petButton,"party2","LeftButton")
assert(seenSlot==4 and seenUnit=="party2" and seenSpell==7814)
print("PASS native fixed-unit pet dispatch has no spell-identity gate; Felhunter stays deferred")
