local m,a=dofile("tests/purify_fixture.lua").New({might=true})
UnitCanAssist=function() return true end
UnitIsPlayer=function() return true end
for _,unit in ipairs({"party1","target"}) do
    m.units[unit]={class="PALADIN",connected=true,dead=false,health=100,maxHealth=100,auras={}}
end
local outside=true
C_Spell.SpellHasRange=function() return true end
C_Spell.IsSpellInRange=function(id,unit)
    assert(not m.combat)
    assert(id==19740 and (unit=="party1" or unit=="target"))
    return not outside
end
local function shown(row)
    for _,b in ipairs(row.blessingButtons) do if b.attributes.type1=="spell" then return true end end
    return false
end
a.Buffs.Refresh()
assert(shown(a.View.rows[1]),"Self buffs must not depend on target distance")
assert(not shown(a.View.rows[2]) and not shown(a.View.target),"Hide out-of-range party and target reminders")
a.View.target.buffStrip.scripts.OnClick()
assert(not shown(a.View.target),"Manual expansion must also respect range")
outside=false;a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver,1)
assert(shown(a.View.rows[2]) and shown(a.View.target),"Walking into range restores options without aura events")
outside=true;a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver,1)
assert(not shown(a.View.rows[2]) and not shown(a.View.target),"Walking away clears options")
for _,result in ipairs({m.Secret(),"invalid"}) do
    C_Spell.IsSpellInRange=function() return result end
    a.Buffs.Refresh();assert(shown(a.View.target),"Unavailable range must not be treated as false")
end
C_Spell.IsSpellInRange=function() return nil end
a.Buffs.Refresh();assert(shown(a.View.target))
C_Spell.IsSpellInRange=function() error("unavailable") end
a.Buffs.Refresh();assert(shown(a.View.target))
C_Spell.SpellHasRange=function() return false end
C_Spell.IsSpellInRange=function() error("Range-less buffs must skip range query") end
a.Buffs.Refresh();assert(shown(a.View.target))
C_Spell.SpellHasRange=function() return true end
C_Spell.IsSpellInRange=function(id) return id~=19740 end
local choices=a.Buffs.WithTimers({{id=19740,name="Might"},{id=700001,name="Watched buff"}}, {},nil,"target")
assert(#choices==1 and choices[1].id==700001,"Filter by each buff's range, including generic watched buffs")
m.combat=true;a.Buffs.Refresh();a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver,1)
UnitCanAssist=nil;UnitIsPlayer=nil
print("PASS buff recipient range: automatic/manual, walking recovery, self, unknown/restricted data and combat")
