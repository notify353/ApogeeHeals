local m=dofile("tests/mock.lua").New()
m.units.player.class="PRIEST"
for i=1,4 do
    m.units["party"..i]={name="Party",health=80,maxHealth=100,power=50,maxPower=100,
        kind=0,connected=true,dead=false,auras={}}
end
local known={[2050]=true,[700001]=true,[700002]=true}
Enum.SpellBookSpellBank={Player=0}
C_Spell.GetSpellInfo=function(id) return {name="Heal",iconID=1,spellID=id} end
C_Spell.IsSpellHelpful=function() return true end
C_Spell.IsSpellHarmful=function() return false end
C_Spell.IsSpellPassive=function() return false end
C_SpellBook={IsSpellInSpellBook=function(id) return known[id]==true end,
    IsSpellKnown=function(id) return known[id]==true end}
local results, calls = {player=true,party1=false,party2=true}, {}
C_Spell.IsSpellInRange=function(id,unit)
    calls[#calls+1]={id,unit};return results[unit]
end
local a=m.Load();m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
assert(a.Bindings.rangeSpell==2050)
for _,call in ipairs(calls) do assert(call[1]==2050 and call[2]~="target") end
local row=a.View.rows[2]
assert(row.alpha==0.45 and row.rangeStatus.shown and not row.name.shown)
assert(a.View.rows[1].alpha==1 and not a.View.rows[4].rangeStatus.shown)
assert(a.Bindings.Put("1",700001));assert(a.Bindings.rangeSpell==700001)
assert(a.Bindings.Put("shift-1",700002));assert(a.Bindings.rangeSpell==700001)
local reads=m.auraReads;calls={}
a.Runtime.driver.scripts.OnUpdate(nil,0.1);assert(#calls==0)
a.Runtime.driver.scripts.OnUpdate(nil,0.1);assert(#calls==5 and m.auraReads==reads)
for _,call in ipairs(calls) do assert(call[1]==700001) end
for _,value in ipairs({true,m.Secret(),0,1,"false",m.InaccessibleTable()}) do
    results.party1=value;a.View.RefreshRange();assert(row.alpha==1 and not row.rangeStatus.shown)
end
results.party1=nil;a.View.RefreshRange();assert(not row.rangeStatus.shown)
C_Spell.IsSpellInRange=function() error("unavailable") end
a.View.RefreshRange();assert(not row.rangeStatus.shown)
C_Spell.IsSpellInRange=function(id,unit) calls[#calls+1]={id,unit};return false end
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");m.Flush()
assert(row.rangeStatus.shown and row.attributes.spell1==700001)
a.db.bindings["1"]=700002;a.Bindings.Apply();a.View.RefreshRange()
assert(a.Bindings.rangeSpell==700001 and calls[#calls][1]==700001)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(a.Bindings.rangeSpell==700002 and row.attributes.spell1==700002)
for _,field in ipairs({"dead","connected"}) do
    m.units.party1[field]=field=="dead";a.View.Refresh()
    assert(not row.rangeStatus.shown and row.alpha==1)
    m.units.party1[field]=field=="connected"
end
m.units.party1=nil;a.View.Refresh();assert(not row.rangeStatus.shown)
a.View.SetUnlocked(true);assert(not a.Runtime.driver.scripts.OnUpdate)
for _,r in ipairs(a.View.rows) do assert(r.alpha==0 and not r.rangeStatus.shown) end
a.View.SetUnlocked(false);assert(a.Runtime.driver.scripts.OnUpdate)
m.Event("PLAYER_LEAVING_WORLD");assert(not a.Runtime.driver.scripts.OnUpdate)
for _,r in ipairs(a.View.rows) do assert(not r.rangeStatus.shown) end
m.Event("PLAYER_ENTERING_WORLD");m.Flush();assert(a.Runtime.driver.scripts.OnUpdate)
known[700002]=false;m.Event("SPELLS_CHANGED");m.Flush()
assert(not a.Bindings.rangeSpell and not a.Runtime.driver.scripts.OnUpdate)
assert(row.attributes.type1=="")
a.Bindings.Put("1",nil);assert(a.Bindings.rangeSpell==2050)
m.units.player.class="WARRIOR";a.Bindings.Apply()
assert(not a.Bindings.rangeSpell and a.View.rows[1].attributes.type1=="target")
C_Spell.IsSpellInRange=nil;a.Bindings.Put("1",700001)
assert(not a.Runtime.driver.scripts.OnUpdate and row.alpha==1)
print("PASS exact applied left-spell/fixed-unit range, guarded unknowns, combat deferral, polling isolation and lifecycle cleanup")
