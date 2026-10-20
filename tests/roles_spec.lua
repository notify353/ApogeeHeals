local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local roles = { player = "HEALER", party1 = "TANK" }
UnitGroupRolesAssigned = function(unit) return roles[unit] or "NONE" end
UnitIsGroupLeader = function(unit) return unit == "party1" end
m.units.party1 = {name="Warrior", connected=true, dead=false, health=90, maxHealth=100, auras={}}
local a = m.Start()
local player, party = a.View.rows[1], a.View.rows[2]
assert(player.roleIcon.shown and player.roleIcon.atlas == "roleicon-tiny-healer")
assert(party.roleIcon.shown and party.roleIcon.atlas == "roleicon-tiny-tank")
assert(party.leader.shown, "role and crown must coexist")
assert(player.name.point[4] + player.name.width < player.health.width - 20)
assert(not a.View.target.roleIcon and not a.View.targetTarget.roleIcon)
for i, atlas in ipairs({"roleicon-tiny-healer", "roleicon-tiny-tank", "roleicon-tiny-dps"}) do
    assert(a.Preview.rows[i].roleIcon.atlas == atlas)
end
m.combat = true
m.Event("PLAYER_REGEN_DISABLED")
assert(not player.roleIcon.shown and not party.roleIcon.shown and not party.leader.shown)
roles.party1 = "DAMAGER"; m.Event("ROLE_CHANGED_INFORM", m.Secret()); m.Flush()
assert(not party.roleIcon.shown and not party.leader.shown)
roles.player = "TANK"; m.Event("PLAYER_ROLES_ASSIGNED"); m.Flush()
assert(not player.roleIcon.shown)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(party.roleIcon.shown and party.roleIcon.atlas == "roleicon-tiny-dps")
assert(player.roleIcon.atlas == "roleicon-tiny-tank")
m.units.party1.dead = true; a.View.Refresh()
assert(party.roleIcon.shown, "assigned role survives death")
for _, value in ipairs({"NONE", "UNKNOWN", false, 1, m.Secret(), m.InaccessibleTable()}) do
    roles.party1 = value; m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    assert(not party.roleIcon.shown, "invalid/restricted role must clear old icon")
end
roles.party1 = "TANK"; a.View.Refresh(); assert(party.roleIcon.shown)
m.Event("PLAYER_LEAVING_WORLD"); assert(not party.roleIcon.shown)
m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); assert(party.roleIcon.shown)
m.units.party1 = nil; m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
assert(not party.roleIcon.shown)
UnitGroupRolesAssigned = function() error("unavailable") end
a.View.Refresh(); assert(not player.roleIcon.shown)
UnitGroupRolesAssigned = nil
a.View.Refresh(); assert(not player.roleIcon.shown)
print("PASS roles hidden throughout combat, fresh roles on exit, crown coexistence and restricted clearing")
