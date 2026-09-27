local Mock = dofile("tests/mock.lua")
local m = Mock.New()
m.units.player.class = "PALADIN"
local ids = {19740,19742,20217,1038,19977,20911,25782,25894,25898}
local known = {}; for _,id in ipairs(ids) do known[id]=true end
Enum.SpellBookSpellBank = {Player=0}
C_Spell.GetSpellInfo = function(id) if known[id] then return {name="Blessing "..id,spellID=id,iconID=id} end end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
C_SpellBook = {IsSpellInSpellBook=function(id) return known[id] == true end,IsSpellKnown=function(id) return known[id] == true end}
UnitGroupRolesAssigned = function(unit) return m.units[unit] and m.units[unit].role or "NONE" end
GameTooltip.SetSpellByID = function() return true end
GameTooltip.AddLine = function(self,line) self.extra=line end
for i=1,4 do m.units["party"..i]={connected=true,dead=false,auras={},class="PRIEST"} end
local a=m.Start()
local function recommend(class,role,available)
    m.units.party1.class,m.units.party1.role=class,role
    return a.BuffDefaults.Recommend("party1",available or a.BuffDefaults.Choices())
end
assert(recommend("WARRIOR","TANK")==20217)
assert(recommend("PALADIN","HEALER")==19742)
assert(recommend("PALADIN","DAMAGER")==19740)
assert(recommend("WARRIOR","NONE")==19740)
assert(recommend("ROGUE",nil)==19740)
for _,class in ipairs({"MAGE","PRIEST","WARLOCK"}) do assert(recommend(class,"DAMAGER")==19742) end
assert(recommend("HUNTER","DAMAGER")==20217)
for _,class in ipairs({"DRUID","SHAMAN","PALADIN"}) do assert(recommend(class,"NONE")==20217) end
assert(recommend("DRUID","HEALER")==19742)
assert(recommend("DRUID","DAMAGER")==20217) -- No invented feral/caster spec.
assert(recommend("WARRIOR","TANK",{{id=19740}})==19740)
assert(recommend("PALADIN","TANK",{{id=19742}})==19742)
assert(recommend("MAGE","NONE",{{id=19740}})==nil)
assert(recommend("HUNTER","NONE",{{id=19740}})==nil)
assert(recommend("PRIEST","HEALER",{{id=20217}})==20217)
assert(recommend("ROGUE","DAMAGER",{{id=25782}})==25782)
for _,role in ipairs({"TANK","HEALER","DAMAGER","NONE"}) do
    assert(recommend("PALADIN",role,{{id=1038},{id=19977},{id=20911}})==nil)
end
local secret=m.Secret()
assert(recommend("ROGUE",secret)==19740)
assert(recommend(secret,"TANK")==20217)
assert(recommend(secret,secret)==20217)
UnitGroupRolesAssigned=nil
assert(recommend("PRIEST",nil)==19742)
UnitGroupRolesAssigned=function(unit) return m.units[unit] and m.units[unit].role or "NONE" end
m.units.party1.class,m.units.party1.role="WARRIOR","TANK"
a.Buffs.Refresh()
local row=a.View.rows[2]
local function selected()
    local result,count=nil,0
    for _,button in ipairs(row.blessingButtons) do
        if button.suggestion.shown then result=button;count=count+1 end
    end
    assert(count<=1);return result
end
local button=assert(selected());assert(button.attributes.spell1==20217)
button.scripts.OnEnter(button)
assert(GameTooltip.extra:find("assigned tank",1,true) and GameTooltip.shown)
m.units.party1.role="DAMAGER";m.Event("PLAYER_ROLES_ASSIGNED");m.Flush()
assert(not GameTooltip.shown and selected().attributes.spell1==19740)
for _,b in ipairs(row.blessingButtons) do
    assert(b.attributes.unit=="party1" and b.attributes.type1=="spell" and not b.scripts.OnClick)
end
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");assert(not selected())
m.units.party1.role="TANK";m.Event("PLAYER_ROLES_ASSIGNED");m.Flush();assert(not selected())
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush();assert(selected().attributes.spell1==20217)
m.units.party1.auras={{spellId=19742,name="Wisdom"}};a.Buffs.Refresh();assert(not selected())
m.units.party1.auras={};a.Buffs.Refresh();assert(selected())
m.auraError=true;a.Buffs.Refresh();assert(not selected())
m.auraError=false;a.View.unlocked=true;a.Buffs.Refresh();assert(not selected())
a.View.unlocked=false;a.Buffs.Refresh();m.Event("PLAYER_LEAVING_WORLD");assert(not selected())
UnitGroupRolesAssigned=nil
print("PASS role-first blessing guidance, class/secret/missing fallbacks, one yellow suggestion, tooltip and combat/role/lifecycle changes")
