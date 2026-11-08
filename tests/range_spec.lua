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
assert(a.Bindings.Put("shift-1",700002))
a.View.RefreshRange()
assert(row.health.alpha==0.45 and row.alpha==1 and not row.rangeStatus.shown)
assert(row.name.shown and row.level.shown and a.Bindings.rangeSpell==700001)
-- Only unmodified left determines the health fade; other binds/modifiers do not.
for _,field in ipairs({"shift","ctrl","alt"}) do
    m[field]=true; a.View.RefreshRange(); assert(row.health.alpha==0.45); m[field]=false
end
-- Buffs remain outside the health parent and query their own spell.
for _,button in ipairs(row.buffButtons or {}) do assert(button.parent~=row.health) end
assert(not a.Buffs.OutOfRange(700002,"party1") and a.Buffs.OutOfRange(700001,"party1"))
-- Unknown spell checks fall back to readable, spell-specific proximity.
local minimum, maximum = 0, 40
C_Spell.GetSpellInfo=function(id)
    return {name="Heal",iconID=1,spellID=id,minRange=minimum,maxRange=maximum}
end
UnitDistanceSquared=function() return 10000,true end
for _,value in ipairs({m.Secret(),m.InaccessibleTable(),0,1,"false"}) do
    results[700001]=value; a.View.RefreshRange(); assert(row.health.alpha==0.45)
end
results[700001]=nil; a.View.RefreshRange(); assert(row.health.alpha==0.45)
C_Spell.IsSpellInRange=function() error("unavailable") end
a.View.RefreshRange(); assert(row.health.alpha==0.45)
C_Spell.IsSpellInRange=nil
a.View.RefreshRange(); assert(row.health.alpha==0.45)
C_Spell.IsSpellInRange=function(id) return results[id] end
-- Native results take priority even when distance disagrees or is unavailable.
results[700001]=true;a.View.RefreshRange();assert(row.health.alpha==1)
UnitDistanceSquared=function() error("Native result must not query distance") end
results[700001]=false;a.View.RefreshRange();assert(row.health.alpha==0.45)
C_Spell.SpellHasRange=function() return false end
a.View.RefreshRange(); assert(row.health.alpha==1)
C_Spell.SpellHasRange=function() return true end
results[700001]=nil
-- Exact boundary, longer-range spell and minimum range; never impose 40 yards.
UnitDistanceSquared=function() return 1600,true end
a.View.RefreshRange();assert(row.health.alpha==1)
UnitDistanceSquared=function() return 1601,true end
a.View.RefreshRange();assert(row.health.alpha==0.45)
maximum=60;UnitDistanceSquared=function() return 2500,true end
a.View.RefreshRange();assert(row.health.alpha==1)
minimum=10;UnitDistanceSquared=function() return 99,true end
a.View.RefreshRange();assert(row.health.alpha==0.45)
UnitDistanceSquared=function() return 100,true end
a.View.RefreshRange();assert(row.health.alpha==1)
minimum=0;maximum=40
-- Neither a secret result nor inaccessible/malformed metadata is usable evidence.
for _,value in ipairs({m.Secret(),m.InaccessibleTable(),-1,math.huge,0/0,"1600"}) do
    UnitDistanceSquared=function() return value,true end
    a.View.RefreshRange();assert(row.health.alpha==0.7)
end
for _,checked in ipairs({false,m.Secret(),1}) do
    UnitDistanceSquared=function() return 10000,checked end
    a.View.RefreshRange();assert(row.health.alpha==0.7)
end
UnitDistanceSquared=function() return 10000,true end
local getInfo=C_Spell.GetSpellInfo
for _,info in ipairs({m.Secret(),m.InaccessibleTable(),{},
    {minRange=0,maxRange=m.Secret()},{minRange=m.Secret(),maxRange=40},
    {minRange=-1,maxRange=40},{minRange=50,maxRange=40},
    {minRange=0,maxRange=0},{minRange=0,maxRange=math.huge},
    {minRange=0,maxRange=0/0},{minRange=0,maxRange="40"}}) do
    C_Spell.GetSpellInfo=function() return info end
    a.View.RefreshRange();assert(row.health.alpha==0.7)
end
C_Spell.GetSpellInfo=nil;a.View.RefreshRange();assert(row.health.alpha==0.7)
C_Spell.GetSpellInfo=getInfo
UnitDistanceSquared=function() error("unavailable") end
a.View.RefreshRange();assert(row.health.alpha==0.7)
UnitDistanceSquared=nil;a.View.RefreshRange();assert(row.health.alpha==0.7)
assert(a.View.rows[1].health.alpha==1) -- Self never fades for an unknown check.
-- Each fixed recipient recovers independently, including during combat polling.
m.units.target=m.units.party1;m.units.targettarget=m.units.party1
UnitDistanceSquared=function(unit) return unit=="target" and 10000 or 900,true end
m.combat=true
local reads=m.auraReads
a.Runtime.driver.scripts.OnUpdate(nil,0.2)
assert(row.health.alpha==1 and a.View.target.health.alpha==0.45
    and a.View.targetTarget.health.alpha==1 and m.auraReads==reads)
UnitDistanceSquared=function() return 10000,true end
a.Runtime.driver.scripts.OnUpdate(nil,0.2);assert(row.health.alpha==0.45)
UnitDistanceSquared=function() return nil,false end
a.Runtime.driver.scripts.OnUpdate(nil,0.2);assert(row.health.alpha==0.7)
m.combat=false
results[700001]=false
m.combat=true; m.Event("PLAYER_REGEN_DISABLED");m.Flush()
a.db.bindings["1"]=700002;a.Bindings.Apply();a.View.RefreshRange()
assert(a.Bindings.rangeSpell==700001 and row.health.alpha==0.45 and row.attributes.spell1==700001)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(a.Bindings.rangeSpell==700002 and row.health.alpha==1)
-- Target recipients are independent too; polling does not scan auras.
m.units.target=m.units.party1;m.units.targettarget=m.units.party1
C_Spell.IsSpellInRange=function(id,unit) return unit~="target" end
a.View.RefreshRange();assert(a.View.target.health.alpha==0.45 and a.View.targetTarget.health.alpha==1)
local reads=m.auraReads;a.Runtime.driver.scripts.OnUpdate(nil,0.2);assert(m.auraReads==reads)
-- Non-caster/no left spell gets inclusive 40-yard proximity, even with right heal.
m.units.player.class="WARRIOR";a.db.bindings={};a.Bindings.Apply()
assert(not a.Bindings.rangeSpell)
a.Bindings.Put("2",700002)
UnitDistanceSquared=function() return 1601,true end
a.Runtime.RangePolling();assert(row.health.alpha==0.45 and row.alpha==1)
UnitDistanceSquared=function() return 1600,true end
a.View.RefreshRange();assert(row.health.alpha==1)
for _,value in ipairs({m.Secret(),m.InaccessibleTable(),-1,math.huge,0/0,"1600"}) do
    UnitDistanceSquared=function() return value,true end
    a.View.RefreshRange();assert(row.health.alpha==0.7)
end
UnitDistanceSquared=function() return 1601,m.Secret() end
a.View.RefreshRange();assert(row.health.alpha==0.7)
UnitDistanceSquared=function() error("unavailable") end
a.View.RefreshRange();assert(row.health.alpha==0.7)
-- Bandage slot uses proximity, not any spell's range.
Enum.ItemClass={Consumable=0};Enum.ItemConsumableSubclass={Bandage=7}
C_Item={GetItemInfoInstant=function(id) return id,"Consumable","Bandage","",456,0,7 end,
    GetItemNameByID=function() return "Bandage" end}
assert(a.Bindings.Put("1",{kind="item",id=1251}));assert(not a.Bindings.rangeSpell)
UnitDistanceSquared=function() return 1601,true end
a.View.RefreshRange();assert(row.health.alpha==0.45)
for _,field in ipairs({"dead","connected"}) do
    m.units.party1[field]=field=="dead";a.View.RefreshRange();assert(row.health.alpha==1)
    m.units.party1[field]=field=="connected"
end
a.View.SetUnlocked(true);assert(row.alpha==0 and row.health.alpha==1 and not a.Runtime.driver.scripts.OnUpdate)
a.View.SetUnlocked(false);assert(a.Runtime.driver.scripts.OnUpdate)
m.Event("PLAYER_LEAVING_WORLD");assert(row.health.alpha==1 and not a.Runtime.driver.scripts.OnUpdate)
m.Event("PLAYER_ENTERING_WORLD");m.Flush()
UnitDistanceSquared=nil;CheckInteractDistance=nil;a.Runtime.RangePolling();assert(row.health.alpha==0.7 and not a.Runtime.driver.scripts.OnUpdate)
print("PASS left-click-only health fade, independent buffs, spell-specific proximity and distinct unknowns, warrior/bandage proximity, targets and combat lifecycle")
