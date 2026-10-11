local m,a=dofile("tests/purify_fixture.lua").New({might=true})
local row=a.View.rows[1]
m.time=1000
local aura={spellId=19740,name="Might",duration=300,expirationTime=1120}
m.units.player.auras={aura}
a.Buffs.Refresh()
local button=row.blessingButtons[1]
assert(not button.attributes.spell1, "Exactly two minutes remains covered")
m.time=1001
a.Buffs.timerDriver.scripts.OnUpdate(nil,1)
assert(button.attributes.spell1==19740 and button.buffTimer.text=="1:59")
m.time=1061;a.Buffs.timerDriver.scripts.OnUpdate(nil,1)
assert(button.buffTimer.text=="0:59")
-- Expiry removes the timer but leaves the missing reminder actionable.
m.time=1120;a.Buffs.Refresh();assert(button.buffTimer.text=="" and button.attributes.spell1==19740)
m.units.player.auras={};a.Buffs.Refresh();assert(button.buffTimer.text=="")
aura.expirationTime=1420;m.units.player.auras={aura};a.Buffs.Refresh()
assert(not button.attributes.spell1 and button.buffTimer.text=="")
row.buffStrip.scripts.OnClick();assert(button.buffTimer.text=="5:00")
row.buffStrip.scripts.OnClick();assert(not button.attributes.spell1)
for _,value in ipairs({m.Secret(),0,math.huge,0/0,-1,"soon"}) do
    aura.expirationTime=value;a.Buffs.Refresh()
    assert(not button.attributes.spell1, "Unknown/permanent timing must retain coverage")
    row.buffStrip.scripts.OnClick();assert(button.buffTimer.text=="")
    row.buffStrip.scripts.OnClick()
end
aura.expirationTime=1179;aura.duration=m.Secret();a.Buffs.Refresh();assert(not button.attributes.spell1)
aura.duration=300
-- A fresh equivalent buff from another caster prevents an early reminder.
m.units.player.auras={aura,{spellId=19834,name="Might",duration=300,expirationTime=1420}}
a.Buffs.Refresh();assert(not button.attributes.spell1)
m.units.player.auras={aura};a.Buffs.Refresh();assert(button.buffTimer.text=="0:59")
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
local reads=m.auraReads
a.Buffs.timerDriver.scripts.OnUpdate(nil,10)
assert(m.auraReads==reads and button.buffTimer.text=="")
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush();assert(button.buffTimer.text=="0:59")
m.Event("PLAYER_LEAVING_WORLD");reads=m.auraReads
a.Buffs.timerDriver.scripts.OnUpdate(nil,10);assert(m.auraReads==reads)
-- Catalog and generic watched buffs share the same threshold and timer.
local n,b=dofile("tests/purify_fixture.lua").New({class="DRUID"})
n.time=100
C_Spell.GetSpellInfo=function(id) return {spellID=id,name="Buff"..id,iconID=id} end
C_SpellBook.IsSpellKnown=function(id) return id==1126 or id==700001 end
C_SpellBook.IsSpellInSpellBook=C_SpellBook.IsSpellKnown
b.db.buffs={{id=700001,enabled=true,party=true}}
n.units.player.auras={{spellId=1126,name="Buff1126",duration=1800,expirationTime=219},
    {spellId=700001,name="Buff700001",duration=600,expirationTime=219}}
b.Buffs.Refresh()
local r=b.View.rows[1]
assert(r.upkeepButtons[1].attributes.spell1==1126 and r.upkeepButtons[1].buffTimer.text=="1:59")
assert(r.buffButtons[1].attributes.spell1==700001 and r.buffButtons[1].buffTimer.text=="1:59")
n.units.player.auras[1].expirationTime=1000;n.units.player.auras[2].expirationTime=1000
b.Buffs.Refresh();assert(not r.upkeepButtons[1].attributes.spell1 and not r.buffButtons[1].attributes.spell1)
print("PASS early buff reminders: strict 120s boundary, countdown polling, recast, catalog/watch/blessing coverage, restricted/permanent timing and combat/world cleanup")
