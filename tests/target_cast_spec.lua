local Mock = dofile("tests/mock.lua")
local m = Mock.New(); local a = m.Start(); local row = a.View.target
m.units.target = {name="Enemy Caster",health=80,maxHealth=100,power=25,maxPower=100,kind=0,level=60,auras={}}
local casting, channeling, castDuration, channelDuration
UnitCastingInfo = function(unit)
    assert(unit == "target")
    if casting then return m.Secret(), nil, nil, m.Secret(), m.Secret(), false, m.Secret(), m.Secret(), m.Secret(), 101 end
end
UnitChannelInfo = function(unit)
    assert(unit == "target")
    if channeling then return m.Secret(), nil, nil, m.Secret(), m.Secret(), false, m.Secret(), m.Secret(), false, 0, 102 end
end
UnitCastingDuration = function(unit) assert(unit=="target"); return castDuration end
UnitChannelDuration = function(unit) assert(unit=="target"); return channelDuration end
local anchor, height = row.point, row.height
assert(row.cast.width==row.power.width and row.cast.height==row.power.height)
assert(row.cast.point[5]==row.power.point[5] and not row.cast.mouse)
assert(a.View.targetTarget.cast==nil)
a.View.RefreshTarget(); assert(row.cast.alpha==0 and row.power.alpha==1 and row.power.value==25)
casting, castDuration = true, m.Secret()
m.combat=true; m.Event("UNIT_SPELLCAST_START","target")
assert(row.cast.alpha==1 and row.power.alpha==0 and row.cast.duration==castDuration)
assert(row.cast.direction==Enum.StatusBarTimerDirection.ElapsedTime)
assert(row.cast.color[1]==0.95 and row.health.value==80 and row.name.text=="Enemy Caster")
-- Power updates must not replace a cast; delayed casts use the replacement duration.
m.units.target.power=40; m.Event("UNIT_POWER_UPDATE","target")
assert(row.power.value==40 and row.cast.alpha==1 and row.power.alpha==0)
castDuration=m.Secret(); m.Event("UNIT_SPELLCAST_DELAYED","target")
assert(row.cast.duration==castDuration)
for _, event in ipairs({"UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED"}) do
    casting=true; m.Event("UNIT_SPELLCAST_START","target")
    casting=false; m.Event(event,"target")
    assert(row.cast.alpha==0 and row.power.alpha==1 and row.power.value==40)
end
channeling, channelDuration=true,m.Secret(); m.Event("UNIT_SPELLCAST_CHANNEL_START","target")
assert(row.cast.alpha==1 and row.cast.duration==channelDuration)
assert(row.cast.direction==Enum.StatusBarTimerDirection.RemainingTime)
m.Event("UNIT_SPELLCAST_SUCCEEDED","target"); assert(row.cast.alpha==1)
channelDuration=m.Secret();m.Event("UNIT_SPELLCAST_CHANNEL_UPDATE","target")
assert(row.cast.duration==channelDuration)
channeling=false;m.Event("UNIT_SPELLCAST_CHANNEL_STOP","target")
assert(row.cast.alpha==0 and row.power.alpha==1)
-- Selecting an already-casting target works without seeing its start event.
casting=true;m.Event("PLAYER_TARGET_CHANGED");m.Flush();assert(row.cast.alpha==1)
casting=false;m.Event("PLAYER_TARGET_CHANGED");m.Flush();assert(row.cast.alpha==0)
casting=true;row.scripts.OnShow();assert(row.cast.alpha==1)
-- A late stop event for an older cast must not erase the current cast.
m.Event("UNIT_SPELLCAST_STOP","target","old-cast")
assert(row.cast.alpha==1 and row.cast.duration==castDuration)
m.Event("PLAYER_LEAVING_WORLD");assert(row.cast.alpha==0 and row.power.alpha==1)
m.Event("UNIT_SPELLCAST_START","target");assert(row.cast.alpha==0)
m.Event("PLAYER_ENTERING_WORLD");m.Flush();assert(row.cast.alpha==1)
m.units.target=nil;m.Event("PLAYER_TARGET_CHANGED");m.Flush()
assert(row.cast.alpha==0 and row.power.value==0)
assert(row.point==anchor and row.height==height and row.attributes.unit=="target")
-- Missing, restricted or failing APIs restore power, never stale casting.
m.units.target={name="Caster",health=50,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
a.View.RefreshTarget();assert(row.cast.alpha==1 and row.power.alpha==0)
castDuration=nil;a.View.RefreshTarget();assert(row.cast.alpha==0 and row.power.alpha==1)
castDuration=m.Secret();m.timerError=true;a.View.RefreshTarget();assert(row.cast.alpha==0)
m.timerError=false;UnitCastingInfo=function() return m.Secret() end
a.View.RefreshTarget();assert(row.cast.alpha==0)
UnitCastingInfo=function() return "Readable cast" end
a.View.RefreshTarget();assert(row.cast.alpha==1) -- Optional cast-bar ID may be absent.
UnitCastingDuration=nil;a.View.RefreshTarget();assert(row.cast.alpha==0)
row.cast.SetTimerDuration=false;a.View.RefreshTarget();assert(row.power.alpha==1)
print("PASS native target strip casting/channels, stop/interrupt/switch, combat geometry and restricted fallback")
