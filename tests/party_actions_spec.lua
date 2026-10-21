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
    assert(unit == "target")
    assert(distance == 1 or distance == 4)
    return inRange
end
m.units.target = {name="First", connected=true, dead=false, health=90, maxHealth=100, auras={}}
local friendly, player, selfTarget = true, true, false
UnitIsPlayer = function() return player end
UnitCanAssist = function() return friendly end
UnitIsUnit = function(a, b) return a == b or selfTarget end
local a = m.Start()
UnitGUID = function() return guid end
local row = a.View.target
local follow, inspect, talents = unpack(row.partyActions)
local function click(button, mouse) button.scripts.OnClick(button, mouse or "LeftButton") end
for _, party in ipairs(a.View.rows) do assert(not party.partyActions) end
assert(not a.View.targetTarget.partyActions)
assert(follow.propagateMouseClicks == false and inspect.propagateMouseClicks == false)
assert(a.View.targetActions.driver == "[combat] hide; [@target,help,exists] show; hide")
assert(a.View.targetActions.point[2] == row and a.View.targetActions.point[3] == "BOTTOMLEFT")
assert(a.View.targetActions.height + 2 < a.Style.targetGap, "fits shared gap")
for _, button in ipairs(row.partyActions) do
    assert(button.height == 16 and button.icon.width == 10 and button.icon.desaturated)
    assert(button.icon.alpha == 0.75 and button.label.text)
end
follow.scripts.OnEnter(); assert(follow.icon.alpha == 1)
follow.scripts.OnLeave(); assert(follow.icon.alpha == 0.75)
assert(inspect.point[4] == follow.width + 2)
assert(talents.point[4] + talents.width == a.Style.targetWidth)
local oldPoint = a.View.targetActions.point
a.Buffs.Paint(row, {{id=1}, {id=2}})
a.Buffs.PaintCatalog(row, {{id=3}, {id=4}, {id=5}}, 2, 0)
assert(a.View.targetActions.point == oldPoint, "buffs never move the strip")
for _, kind in ipairs({"hostile", "npc", "self", "restricted"}) do
    friendly = kind ~= "hostile"
    player = kind ~= "npc"
    selfTarget = kind == "self"
    if kind == "restricted" then player = m.Secret() end
    a.View.RefreshPartyActions()
    assert(not a.View.targetActions.content.shown)
    click(follow); click(inspect); click(talents)
    assert(#calls == 0 and #requests == 0)
end
friendly, player, selfTarget = true, true, false
a.View.RefreshPartyActions(); assert(a.View.targetActions.content.shown)
click(follow); click(inspect)
assert(#calls == 2 and calls[1][1] == "follow" and calls[1][2] == "target")
assert(calls[2][1] == "inspect" and calls[2][2] == "target")
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
m.units.target = nil; click(follow); click(inspect); assert(#calls == 2)
m.units.target = {name="Replacement", connected=true, dead=false, health=80, maxHealth=100, auras={}}
click(follow); assert(#calls == 3 and calls[3][2] == "target", "fixed current slot, never cached name")
m.units.target.connected = m.Secret()
click(follow); click(inspect); assert(#calls == 3)
m.units.target.connected = true
a.View.unlocked = true; click(follow); click(inspect); assert(#calls == 3)
a.View.unlocked = false
m.Event("PLAYER_LEAVING_WORLD"); click(follow); click(inspect); assert(#calls == 3)
assert(not follow.enabled and not inspect.enabled)
click(talents); assert(#requests == 0)
-- Only the matching, still-current recipient can open the talent window.
a.Runtime.suspended = false
click(talents); assert(#requests == 1 and requests[1] == "target" and #opened == 0)
m.Event("INSPECT_READY", "Unrelated"); assert(#opened == 0)
m.Event("INSPECT_READY", guid); assert(#opened == 1 and opened[1] == "target")
click(talents); guid = "Party-Replacement"
m.Event("INSPECT_READY", "Party-First"); assert(#opened == 1)
click(talents); m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
m.Event("INSPECT_READY", guid); assert(#opened == 1)
m.combat = false; m.Flush()
click(talents); m.Event("PLAYER_TARGET_CHANGED")
m.Event("INSPECT_READY", guid); assert(#opened == 1, "target change cancels even if selected again")
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
