local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local leader = "player"
UnitIsGroupLeader = function(unit) return unit == leader end
local a = m.Start()
local player, party = a.View.rows[1], a.View.rows[2]
assert(not player.leader.shown, "solo must not show a leader")
assert(not a.View.target.leader and not a.View.targetTarget.leader)
assert(a.Preview.rows[1].leader.shown and not a.Preview.rows[2].leader.shown)
m.units.party1 = {name="Warrior", connected=true, dead=false, health=90, maxHealth=100, auras={}}
m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
assert(player.leader.shown and not party.leader.shown)
assert(player.name.point[4] + player.name.width < player.health.width - 10)
m.combat = true
m.Event("PLAYER_REGEN_DISABLED")
assert(not player.leader.shown and not party.leader.shown)
leader = "party1"; m.Event("PARTY_LEADER_CHANGED"); m.Flush()
assert(not player.leader.shown and not party.leader.shown)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(not player.leader.shown and party.leader.shown)
m.units.party1.dead = true; m.Event("UNIT_FLAGS", "party1"); m.Flush()
assert(party.leader.shown, "dead party leader retains the crown")
UnitIsGroupLeader = function() return m.Secret() end
m.Event("PARTY_LEADER_CHANGED"); m.Flush()
assert(not player.leader.shown and not party.leader.shown)
UnitIsGroupLeader = function() error("unavailable") end
a.View.Refresh(); assert(not party.leader.shown)
UnitIsGroupLeader = nil
a.View.Refresh(); assert(not party.leader.shown)
UnitIsGroupLeader = function(unit) return unit == leader end
a.View.Refresh(); assert(party.leader.shown)
m.Event("PLAYER_LEAVING_WORLD"); assert(not party.leader.shown)
m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); assert(party.leader.shown)
m.units.party1 = nil; m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
assert(not player.leader.shown and not party.leader.shown)
print("PASS leader hidden throughout combat, fresh transfer on exit, solo/leave and restricted clearing")
