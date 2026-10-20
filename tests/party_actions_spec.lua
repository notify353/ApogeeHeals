local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local calls, inRange, inspectable = {}, true, true
local requests, opened, guid = {}, {}, "Party-First"
NotifyInspect = function(unit) requests[#requests + 1] = unit end
PlayerSpellsUtil = {OpenToClassTalentsTab = function(unit) opened[#opened + 1] = unit end}
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
UnitGUID = function() return guid end
local row = a.View.rows[2]
local follow, inspect, talents = unpack(row.partyActions)
local function click(button, mouse) button.scripts.OnClick(button, mouse or "LeftButton") end
assert(not a.View.rows[1].partyActions and not a.View.target.partyActions
    and not a.View.targetTarget.partyActions)
assert(follow.propagateMouseClicks == false and inspect.propagateMouseClicks == false)
assert(follow.width == a.Style.sideIconSize and inspect.width == a.Style.sideIconSize)
for _, button in ipairs(row.partyActions) do
    assert(button.driver == "[combat] hide; show", "native combat visibility, including hit region")
    assert(button.icon.width == 10 and button.icon.height == 10 and button.icon.desaturated)
    assert(button.icon.alpha == 0.45)
end
follow.scripts.OnEnter()
assert(follow.icon.alpha == 0.8)
follow.scripts.OnLeave()
assert(follow.icon.alpha == 0.45)
assert(follow.point[1] == "TOPRIGHT" and follow.point[3] == "TOPLEFT")
assert(follow.point[4] + a.Style.sideIconGap == inspect.point[4] - inspect.width)
assert(inspect.point[4] + a.Style.sideIconGap == talents.point[4] - talents.width)
assert(talents.point[4] == -6)
assert(row.drinkIcon.point[4] > 0 and not row.partyActionWidth)
-- Real buff painters push the entire action group left, including overflow.
a.Buffs.Paint(row, {{id=1}, {id=2}})
assert(talents.point[4] == -6 - 2 * (a.Style.sideIconSize + a.Style.sideIconGap))
a.Buffs.PaintCatalog(row, {{id=3}, {id=4}, {id=5}}, 2, 0)
assert(row.partyActionSlots == 5)
a.Buffs.Paint(row, {{id=1}, {id=2}, {id=3}, {id=4}, {id=5}, {id=6}})
a.Buffs.PaintCatalog(row, {{id=7}, {id=8}}, 6, 0)
assert(row.partyActionSlots == 7, "four suggestions plus overflow plus two choices")
local oldPoint = talents.point
m.combat = true
a.Buffs.Paint(row, {}); a.Buffs.PaintCatalog(row, {}, 0, 0)
assert(talents.point == oldPoint, "no combat repositioning")
m.combat = false
a.Buffs.Paint(row, {}); a.Buffs.PaintCatalog(row, {}, 0, 0)
assert(talents.point[4] == -6, "collapse returns group next to bar")
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
click(talents); assert(#requests == 0)
-- Only the matching, still-current recipient can open the talent window.
a.Runtime.suspended = false
click(talents); assert(#requests == 1 and requests[1] == "party1" and #opened == 0)
m.Event("INSPECT_READY", "Unrelated"); assert(#opened == 0)
m.Event("INSPECT_READY", guid); assert(#opened == 1 and opened[1] == "party1")
click(talents); guid = "Party-Replacement"
m.Event("INSPECT_READY", "Party-First"); assert(#opened == 1)
click(talents); m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
m.Event("INSPECT_READY", guid); assert(#opened == 1)
m.combat = false; m.Flush()
click(talents); m.Event("GROUP_ROSTER_UPDATE")
m.Event("INSPECT_READY", guid); assert(#opened == 1)
click(talents); m.Flush()
m.Event("INSPECT_READY", guid); assert(#opened == 1, "expired request must not open")
click(talents); click(inspect)
m.Event("INSPECT_READY", guid); assert(#opened == 1, "gear inspection supersedes talents")
local count = #requests
guid = m.Secret(); click(talents); assert(#requests == count)
guid = "Party-Final"; inRange = false; click(talents); assert(#requests == count)
print("party_actions_spec: OK")
