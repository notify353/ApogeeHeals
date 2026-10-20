local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local calls, inRange, inspectable = {}, true, true
FollowUnit = function(unit) calls[#calls + 1] = {"follow", unit} end
InspectUnit = function(unit) calls[#calls + 1] = {"inspect", unit} end
CanInspect = function() return inspectable end
CheckInteractDistance = function(unit, distance)
    assert(unit:match("^party[1-4]$"))
    assert(distance == 1 or distance == 4)
    return inRange
end
m.units.party1 = {name="First", connected=true, dead=false, health=90, maxHealth=100, auras={}}
local a = m.Start()
local row = a.View.rows[2]
local follow, inspect = unpack(row.partyActions)
local function click(button, mouse) button.scripts.OnClick(button, mouse or "LeftButton") end
assert(not a.View.rows[1].partyActions and not a.View.target.partyActions
    and not a.View.targetTarget.partyActions)
assert(follow.propagateMouseClicks == false and inspect.propagateMouseClicks == false)
assert(follow.width == a.Style.sideIconSize and inspect.width == a.Style.sideIconSize)
assert(follow.point[4] + follow.width < inspect.point[4])
assert(inspect.point[4] + inspect.width < row.drinkIcon.point[4])
click(follow); click(inspect)
assert(#calls == 2 and calls[1][1] == "follow" and calls[1][2] == "party1")
assert(calls[2][1] == "inspect" and calls[2][2] == "party1")
click(follow, "RightButton"); assert(#calls == 2)
inRange = false; click(follow); click(inspect); assert(#calls == 2)
inRange = m.Secret(); click(follow); click(inspect); assert(#calls == 2)
inRange = true; inspectable = m.Secret(); click(inspect); assert(#calls == 2)
inspectable = true
m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(not follow.enabled and not inspect.enabled)
click(follow); click(inspect); assert(#calls == 2)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(follow.enabled and inspect.enabled and #calls == 2, "no deferred actions")
m.units.party1 = nil; click(follow); click(inspect); assert(#calls == 2)
m.units.party1 = {name="Replacement", connected=true, dead=false, health=80, maxHealth=100, auras={}}
click(follow); assert(#calls == 3 and calls[3][2] == "party1", "fixed current slot, never cached name")
m.units.party1.connected = m.Secret()
click(follow); click(inspect); assert(#calls == 3)
m.units.party1.connected = true
a.View.unlocked = true; click(follow); click(inspect); assert(#calls == 3)
a.View.unlocked = false
m.Event("PLAYER_LEAVING_WORLD"); click(follow); click(inspect); assert(#calls == 3)
assert(not follow.enabled and not inspect.enabled)
print("party_actions_spec: OK")
