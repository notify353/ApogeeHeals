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
local results = {[700001]=false, [700002]=true, [2050]=true}
C_Spell.IsSpellInRange=function(id,unit) return results[id] end
ApogeeHealsDB={defaultSpells={enabled=true,time=1,serial=0}}
local a=m.Load();m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
local row=a.View.rows[2]
assert(a.Bindings.Put("1",700001)); assert(a.Bindings.Put("2",700002))
a.View.RefreshRange()
assert(row.alpha==1 and row.name.shown and row.level.shown)
assert(row.rangeStates[1]=="out" and row.rangeStates[2]=="in")
-- Buffs use the same exact-spell contract, never the left-click range.
assert(not a.Buffs.OutOfRange(700002,"party1"))
assert(a.Buffs.OutOfRange(700001,"party1"))
-- Proximity is separate from cast range, including beyond 40 yards.
m.units.party1.distanceSquared=1601; a.View.RefreshRange()
assert(row.proximity==false and row.rangeStates[2]=="in" and row.alpha==1)
m.units.party1.distanceSquared=1600; a.View.RefreshRange(); assert(row.proximity==true)
for _,value in ipairs({m.Secret(),m.InaccessibleTable(),-1,math.huge,0/0,"1600"}) do
    UnitDistanceSquared=function() return value,true end
    a.View.RefreshRange(); assert(row.proximity==nil and row.rangeStates[2]=="in")
end
UnitDistanceSquared=function() return 1601,m.Secret() end
a.View.RefreshRange(); assert(row.proximity==nil)
UnitDistanceSquared=function() error("unavailable") end
a.View.RefreshRange(); assert(row.proximity==nil)
-- Unknown spell results cannot be replaced by proximity or another spell.
for _,value in ipairs({m.Secret(),m.InaccessibleTable(),0,1,"false"}) do
    results[700001]=value; a.View.RefreshRange()
    assert(row.rangeStates[1]=="unknown" and not a.Buffs.OutOfRange(700001,"party1"))
end
results[700001]=nil; a.View.RefreshRange(); assert(row.rangeStates[1]=="unknown")
C_Spell.IsSpellInRange=function() error("unavailable") end
a.View.RefreshRange(); assert(row.rangeStates[2]=="unknown")
C_Spell.IsSpellInRange=function(id,unit) return results[id] end
C_Spell.SpellHasRange=function() return false end
a.View.RefreshRange(); assert(row.rangeStates[1]=="in")
C_Spell.SpellHasRange=function() return true end
results[700001]=false
assert(a.Bindings.Put("shift-1",700002)); m.shift=true
a.View.RefreshRange(); assert(row.rangeStates[1]=="in" and row.rangeStates[2]==nil)
assert(a.Bindings.Put("ctrl-1",700001)); m.shift=false; m.ctrl=true
a.View.RefreshRange(); assert(row.rangeStates[1]=="out")
m.shift=true; a.View.RefreshRange(); assert(not next(row.rangeStates))
m.shift=false; m.ctrl=false; m.alt=true; a.View.RefreshRange(); assert(not next(row.rangeStates))
m.alt=false
-- Applied assignments, not pending edits, determine range during combat.
m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
a.db.bindings["1"]=700002; a.Bindings.Apply(); a.View.RefreshRange()
assert(row.rangeStates[1]=="out" and row.attributes.spell1==700001)
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(row.rangeStates[1]=="in" and row.attributes.spell1==700002)
-- Both target rows get independent recipient checks too.
m.units.target=m.units.party1; m.units.targettarget=m.units.party1
local calls={}
C_Spell.IsSpellInRange=function(id,unit) calls[unit]=true; return unit~="target" end
a.View.RefreshRange()
assert(calls.target and calls.targettarget)
assert(a.View.target.rangeStates[1]=="out" and a.View.targetTarget.rangeStates[1]=="in")
local reads=m.auraReads
a.Runtime.driver.scripts.OnUpdate(nil,0.2); assert(m.auraReads==reads)
for _,field in ipairs({"dead","connected"}) do
    m.units.party1[field]=field=="dead"; a.View.RefreshRange()
    assert(not row.rangeStatus.shown and row.alpha==1)
    m.units.party1[field]=field=="connected"
end
a.View.SetUnlocked(true); assert(not a.Runtime.driver.scripts.OnUpdate and row.alpha==0)
a.View.SetUnlocked(false); assert(a.Runtime.driver.scripts.OnUpdate)
m.Event("PLAYER_LEAVING_WORLD"); assert(not row.rangeStatus.shown and not a.Runtime.driver.scripts.OnUpdate)
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
-- A warrior without any spells still has proximity, never invented spell range.
m.units.player.class="WARRIOR"; a.db.bindings={}; a.Bindings.Apply()
UnitDistanceSquared=function() return 1601,true end
a.Runtime.RangePolling(); assert(a.Runtime.driver.scripts.OnUpdate)
assert(row.proximity==false and not next(row.rangeStates) and row.alpha==1)
UnitDistanceSquared=nil; a.Runtime.RangePolling()
assert(not a.Runtime.driver.scripts.OnUpdate and row.proximity==nil)
print("PASS independent exact spell ranges, modifiers, guarded unknowns, combat deferral, targets and separate warrior proximity")
