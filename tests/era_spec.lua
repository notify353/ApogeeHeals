local M=dofile("tests/mock.lua").New()
local runtime=os.getenv("APOGEE_ERA_RUNTIME_ROOT")
local name=runtime and "ApogeeHealsDev" or "ApogeeHeals"
local prefix=runtime and runtime.."/" or ""
local A={__ApogeeClient="classic-era",__ApogeeFamilyAdmission=function(n) return n==name end}
WOW_PROJECT_ID=2; WOW_PROJECT_CLASSIC=2
GetBuildInfo=function() return "1.15.9","70003","",11509 end
Enum.SpellBookSpellBank={Player=0}
C_SpellBook={IsSpellInSpellBook=function(id) return id==2050 end,IsSpellKnown=function(id) return id==2050 end}
C_Spell.GetSpellInfo=function(id) return {name="Heal",iconID=123,spellID=id} end
C_Spell.IsSpellHelpful=function() return true end
C_Spell.IsSpellHarmful=function() return false end
C_Spell.IsSpellPassive=function() return false end
GetSpellBookItemInfo=function(slot,bank) assert(bank=="spell"); return slot==3 and "SPELL" or "FUTURESPELL",2050 end
for line in io.lines(prefix..(runtime and name..".toc" or name.."_Era.toc")) do
    if line:match("%.lua$") and not line:match("^__Distribution/") then assert(loadfile(prefix..line))(name,A) end
end
M.addon=A; M.Event("ADDON_LOADED",name); M.Flush()
assert(A.db and #A.View.rows==5,"Era frames must start")
assert(not A.View.targetActions,"No partial native inspection strip")
M.cursor={"spell",3,"spell"}; assert(A.Bindings.Cursor()==2050)
M.cursor={"spell",3,"pet"}; assert(A.Bindings.Cursor()==nil)
M.cursor={"spell",4,"spell"}; assert(A.Bindings.Cursor()==nil)
local label={SetText=function(self,value) self.text=value end}
UnitName=function() return "Player","AnotherRealm" end
A.UnitAPI.PaintFullName(label,"party1"); assert(label.text=="Player")
assert(A.Bindings.Put("2",2050))
local before=A.View.rows[2].attributes.macrotext2
assert(before and before:find("@party1",1,true),"Strict recipient preserved")
M.combat=true; A.Bindings.Apply(); assert(A.Bindings.pending)
assert(A.View.rows[2].attributes.macrotext2==before,"No protected combat rewrite")
print("PASS Era Heals startup, legacy spell slots, fixed recipients, combat deferral and realm formatting")

-- Live Era threat icons must work without Forever's AuraContainer template.
M.combat=false
C_XMLUtil={GetTemplateInfo=function() return nil end}
local auras={
    {spellId=7386,sourceUnit="party1",applications=5},
    {spellId=11597,sourceUnit="player",applications=3},
    {spellId=11581,sourceUnit="player",applications=0},
    {spellId=11556,sourceUnit="player",applications=0},
}
local auraReads=0
local originalAuras=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(unit,index,filter)
    if filter=="HELPFUL" then return originalAuras(unit,index,filter) end
    assert(unit:match('^nameplate%d+$') and filter=="HARMFUL|INCLUDE_NAME_PLATE_ONLY")
    auraReads=auraReads+1
    return auras[index]
end
UnitIsUnit=function(first,second) return first==second end
UnitDetailedThreatSituation=function() return true,3,100,150,1000 end
UnitThreatLeadSituation=function() return 0 end
UnitThreatPercentageOfLead=function() return 150 end
A.Threat.SetEnabled(true)
M.units.nameplate1={hostile=true,dead=false,health=100,maxHealth=100,kind=1,auras={}}
M.Event("NAME_PLATE_UNIT_ADDED","nameplate1")
local row=A.ThreatView.rows[1]
assert(row.demoIcons[1].shown and row.demoFrames[1].shown and row.demoCount.text=="3",
    "Own live Era Sunder must render stacks without native containers")
assert(row.demoIcons[2].shown and row.demoIcons[3].shown and not row.debuffContainers)
local create=CreateFrame
CreateFrame=function(...) assert(not M.combat,"No frame creation during combat");return create(...) end
M.combat=true
auras[2].applications=5
A.Threat.frame.scripts.OnUpdate(A.Threat.frame,0.11)
assert(row.demoCount.text=="5","Stacks update while the nameplate token stays unchanged")
auras[2].applications=1;A.Threat.Refresh();assert(not row.demoCount.shown)
for _,id in ipairs({7386,7405,8380,11596,11597}) do
    auras={{spellId=id,sourceUnit="player",applications=2}}
    A.Threat.Refresh();assert(row.demoIcons[1].shown and row.demoCount.text=="2",id)
end
auras={{spellId=7386,sourceUnit="party1",applications=5}}
A.Threat.Refresh();assert(not row.demoIcons[1].shown,"Other warriors do not count as player-owned effects")
auras={{spellId=7386,sourceUnit="pet",applications=5}}
A.Threat.Refresh();assert(not row.demoIcons[1].shown)
auras={{spellId=7386,sourceUnit="player",applications=M.Secret()}}
A.Threat.Refresh();assert(row.demoIcons[1].shown and row.demoCount.text=="?","Unreadable stacks are not guessed")
auras={{spellId=M.Secret(),sourceUnit="player",applications=5}}
A.Threat.Refresh();assert(not row.demoIcons[1].shown)
auras={M.InaccessibleTable()};A.Threat.Refresh();assert(not row.demoIcons[1].shown)
auras={{spellId=7386,sourceUnit=M.Secret(),applications=5}}
A.Threat.Refresh();assert(not row.demoIcons[1].shown)
auras={{spellId=7386,sourceUnit="player",applications=5}}
local isUnit=UnitIsUnit;UnitIsUnit=function() return M.Secret() end
A.Threat.Refresh();assert(not row.demoIcons[1].shown);UnitIsUnit=isUnit
auras={};A.Threat.Refresh()
assert(not row.demoIcons[1].shown and not row.demoIcons[2].shown and not row.demoIcons[3].shown)
local scan=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function() error("unavailable") end
A.Threat.Refresh();assert(not row.demoIcons[1].shown)
C_UnitAuras.GetAuraDataByIndex=function(_,index)
    if index==1 then return {spellId=7386,sourceUnit="player",applications=5} end
    error("partial read")
end
A.Threat.Refresh();assert(not row.demoIcons[1].shown,"Partial/failed snapshots must not paint")
local bounded=0
C_UnitAuras.GetAuraDataByIndex=function() bounded=bounded+1;return {spellId=999,sourceUnit="player"} end
A.Threat.Refresh();assert(bounded<=65 and not row.demoIcons[1].shown)
C_UnitAuras.GetAuraDataByIndex=scan
auras={{spellId=7386,sourceUnit="player",applications=4}}
A.Threat.Refresh();assert(row.demoCount.text=="4")
M.Event("NAME_PLATE_UNIT_REMOVED","nameplate1")
assert(not row.demoIcons[1].shown and not row.demoCount.shown)
auras={};M.Event("NAME_PLATE_UNIT_ADDED","nameplate1")
assert(not row.demoIcons[1].shown,"A reused token must not inherit old auras")
M.combat=false;CreateFrame=create
local reads=auraReads
A.Threat.SetDemo(true);A.Threat.frame.scripts.OnUpdate(A.Threat.frame,0.11)
assert(auraReads==reads and row.demoIcons[1].shown,"Demo remains synthetic")
A.Threat.SetDemo(false);assert(not row.demoIcons[1].shown)
A.Threat.SetEnabled(false);assert(not row.demoIcons[1].shown)
local stopped=auraReads;M.Event("UNIT_AURA","nameplate1");assert(auraReads==stopped)
M.Event("PLAYER_LEAVING_WORLD");assert(not row.demoIcons[1].shown)

local export=os.getenv("APOGEE_ERA_EXPORT")
if export then
    local f=assert(io.open(export.."/Blizzard_FrameXMLUtil/AuraUtil.lua"))
    local source=f:read('*a');f:close()
    AuraUtil={}
    assert(loadstring(assert(source:match('(function AuraUtil.UnpackAuraData%(auraData%).-\nend)'))))()
    local _,icon,count,_,_,_,caster,_,_,id=AuraUtil.UnpackAuraData({name="Localized Sunder",icon=123,
        applications=5,sourceUnit="player",spellId=11597,points={}})
    assert(icon==123 and count==5 and caster=="player" and id==11597)
    print("PASS fresh native Era AuraUtil field contract under mocks")
end
print("PASS Era live threat auras: ranks, own caster, stacks, guards, bounded refresh and lifecycle")
