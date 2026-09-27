-- Catalog policy tests use the actual native-validation resolver without UI setup.
local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local a = {db={buffs={}}}
assert(loadfile("Core/Access.lua"))("ApogeeHeals", a)
assert(loadfile("Bindings/Runtime.lua"))("ApogeeHeals", a)
assert(loadfile("Buffs/Catalog.lua"))("ApogeeHeals", a)
local known, passive = {}, {}
Enum.SpellBookSpellBank = {Player=0}
C_Spell.GetSpellInfo = function(id) return {name="Spell "..id, spellID=id, iconID=id} end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function(id) return passive[id] == true end
C_SpellBook = {
    IsSpellInSpellBook=function(id, bank, overrides) assert(bank==0 and overrides==false); return known[id] == true end,
    IsSpellKnown=function(id, bank) assert(bank==0); return known[id] == true end,
}
local role = "NONE"
UnitGroupRolesAssigned = function() return role end
m.units.party1 = {class="MAGE"}
local C = a.BuffCatalog
local function setup(class, ids)
    m.combat=false; m.units.player.class=class; m.units.party1.class="MAGE"
    role="NONE"; a.db.buffs={}; known={}; passive={}
    for _, id in ipairs(ids) do known[id]=true end
end
local function choices(unit, auras)
    return C.Choices(unit or "player", auras or {})
end
local function has(list, id)
    for _, entry in ipairs(list) do if entry.id==id then assert(entry.icon==id); return true end end
    return false
end
setup("DRUID", {1126,9885,467,9910,21850})
local list, id, reason=choices("party1")
assert(#list==2 and has(list,9885) and has(list,9910) and id==9885 and reason)
assert(not has(list,1126) and not has(list,21850))
-- Family coverage uses exact identities, any rank/caster, never localized names.
list,id=choices("party1", {{spellId=1126,name="anything",sourceUnit="party4"}})
assert(#list==1 and has(list,9910) and id==nil)
role="TANK";m.units.party1.class="MAGE"
list,id,reason=choices("party1", {{spellId=21849}})
assert(#list==1 and id==9910 and reason:find("assigned tank",1,true))
list,id=choices("party1", {{spellId=467}});assert(#list==1 and id==9885)
assert(#choices("party1", {{spellId=21850},{spellId=467}})==0)
assert(#choices("party1", {{spellId=999999,name="Spell 9885"}})==2)
known[9885]=nil;list,id=choices("party1");assert(has(list,1126) and id==1126)
a.db.buffs={{id=1126,enabled=false},{id=9885,enabled=true}}
local original=a.db.buffs
list,id=choices("party1");assert(#list==1 and id==9910)
assert(a.db.buffs==original and #original==2 and original[1].id==1126 and original[1].enabled==false)
a.db.buffs={{id=21850,enabled=false}};assert(not has(choices("party1"),1126))
setup("MAGE", {1459,10157,23028,168,7301,7302,10220,6117,22783})
list,id=choices();assert(#list==4 and id==10157)
list,id=choices("party1");assert(#list==1 and id==10157)
list,id=choices("target");assert(#list==1 and id==nil) -- No class/role proof for Intellect guidance.
assert(#choices("player",{{spellId=168}})==1)
assert(#choices("player",{{spellId=23028}})==3)
a.db.buffs={{id=168,enabled=false}}
list=choices();assert(#list==3 and not has(list,7301) and has(list,10220) and has(list,22783))
m.units.party1.class="WARRIOR";list,id=choices("party1");assert(#list==1 and id==nil)
role="HEALER";list,id=choices("party1");assert(id==10157)
setup("PRIEST", {1243,10938,14752,27841,976,10958,588,10952,21564,27681,27683})
list,id=choices();assert(#list==4 and id==10938)
list,id=choices("party1",{{spellId=21562}});assert(#list==2 and id==27841)
m.units.party1.class="WARRIOR"
list,id=choices("party1",{{spellId=1243}});assert(#list==2 and id==nil)
role="HEALER";list,id=choices("party1",{{spellId=1243}});assert(id==27841)
list,id=choices("player",{{spellId=21564},{spellId=27681}});assert(#list==2 and id==10952)
list,id=choices("party1",{{spellId=21564},{spellId=27681}});assert(#list==1 and id==nil and has(list,10958))
assert(#choices("party1",{{spellId=21564},{spellId=27681},{spellId=27683}})==0)
local selfCases={
    {class="SHAMAN",ids={324,10432},best=10432,covered=325},
    {class="WARLOCK",ids={687,696,706,11735},best=11735,covered=687,count=2},
    {class="WARRIOR",ids={6673,25289},best=25289,covered=5242},
    {class="HUNTER",ids={19506,20906,1299348,1299346},best=20906,covered=20905},
}
for _, case in ipairs(selfCases) do
    setup(case.class,case.ids)
    list,id=choices();assert(#list==(case.count or 1) and id==case.best)
    for _, unit in ipairs({"party1","party2","party3","party4","target","targettarget"}) do assert(#choices(unit)==0) end
    assert(#choices("player",{{spellId=case.covered}})==0)
    a.db.buffs={{id=case.ids[1],enabled=false}}
    assert(not has(choices(),case.class=="WARLOCK" and 696 or case.best))
end
setup("HUNTER",{1299348,1299346});list,id=choices();assert(#list==1 and id==1299348)
setup("WARLOCK",{687,696});list,id=choices();assert(#list==1 and id==696)
for _, class in ipairs({"ROGUE","PALADIN","UNKNOWN"}) do
    setup(class,{9885,9910,10938,19740});assert(#choices()==0)
end
setup("DRUID",{9885,9910,16864})
passive[9885]=true;list,id=choices();assert(#list==1 and id==nil)
assert(not C.Recognized(16864) and not C.Recognized(19740) and C.Recognized(21850) and C.Recognized(1299346))
known={};assert(#choices()==0)
setup("DRUID",{9885,9910})
local secret=m.Secret()
assert(not C.Recognized(secret))
assert(#C.Choices("player",nil)==0 and #C.Choices("player",secret)==0)
assert(#C.Choices(secret,{})==0 and #choices("targettarget")==0)
assert(#choices("player",{secret})==0 and #choices("player",{{spellId=secret}})==0)
assert(#choices("player",{{spellId=9885},{spellId=secret}})==0)
m.units.player.class=secret;assert(#choices()==0)
m.units.player.class="DRUID";role=secret;m.units.party1.class=secret
list,id=choices("party1");assert(id==9885)
list,id=choices("party1",{{spellId=9885}});assert(#list==1 and id==nil)
UnitGroupRolesAssigned=nil;list,id=choices("party1");assert(id==9885)
m.combat=true;assert(#choices()==0)
-- A caller-owned cache lasts for one refresh, including failed rank probes.
setup("DRUID",{1126})
local nativeResolve, reads=a.Bindings.Resolve, {}
a.Bindings.Resolve=function(spell)
    reads[spell]=(reads[spell] or 0)+1
    return nativeResolve(spell)
end
local cache={}
for _, unit in ipairs({"player","party1","party2","party3","party4","target"}) do
    list,id=C.Choices(unit,{},cache);assert(#list==1 and id==1126)
end
assert(cache[9885]==false and type(cache[1126])=="table")
for _, count in pairs(reads) do assert(count==1) end
known[9885]=true
list,id=C.Choices("player",{},{});assert(id==9885 and reads[9885]==2)
known[9885]=nil
list,id=C.Choices("player",{});assert(id==1126 and reads[9885]==3)
known[9885]=true
list,id=C.Choices("player",{});assert(id==9885 and reads[9885]==4)
a.Bindings.Resolve=nativeResolve
-- 70009's six Inner Fire ranks include 7128, not 10950.
setup("PRIEST",{588,7128,10950})
list,id=choices();assert(#list==1 and id==7128)
assert(C.Recognized(7128) and not C.Recognized(10950))
assert(#choices("player",{{spellId=7128}})==0)
print("PASS class upkeep ranks, independent/exclusive coverage, ordinary actions, self scope, opt-outs, conservative guidance and unreadable/no-capability behavior")
