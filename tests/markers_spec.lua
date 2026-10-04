local m = dofile("tests/mock.lua").New()
local saved = {}
local globals = {"SetRaidTarget", "GetNextAvailableRaidTargetMarkerIndex", "UnitIsBossMob",
    "UnitClassification", "UnitHasPowerType", "GetRaidTargetIndex", "SecureButton_GetModifiedAttribute", "SECURE_ACTIONS"}
for _, key in ipairs(globals) do saved[key] = _G[key] end
local boss, mana, available, occupied, calls = false, true, 8, nil, 0
UnitIsBossMob = function() return boss end
UnitClassification = function() return "normal" end
UnitHasPowerType = function() return mana end
GetNextAvailableRaidTargetMarkerIndex = function(index, reverse, wrap, dead)
    assert(not reverse and not wrap and dead); return available
end
GetRaidTargetIndex = function(unit) assert(unit == "target"); return occupied end
local nativeInput = false
SetRaidTarget = function(unit, marker)
    assert(nativeInput, "addon must never directly place a marker")
    assert(unit == "target"); occupied = marker; calls = calls + 1
end
local a = m.Start()
a.db.threatEnabled = true
m.units.target = {hostile=true,kind=0,maxPower=100}
local button = a.ThreatMarkers.button
assert(button.parent == UIParent and button.attributes.unit == "target")
assert(button.attributes.action == "set-unmarked" and button.attributes.useOnKeyDown == false)
a.ThreatMarkers.Refresh()
assert(button.driver == "[combat] hide; [@target,harm,nodead] show; hide")
assert(button.attributes.type1 == nil)
local function prepare()
    button.scripts.PreClick(button, "LeftButton")
    return button.attributes.type1, button.attributes.marker
end
local function disarm() button.scripts.PostClick(button) end
local kind, marker = prepare(); assert(kind == "raidtarget" and marker == 8); disarm()
boss, available = true, 2
kind, marker = prepare(); assert(kind == "raidtarget" and marker == 2); disarm()
boss, available = false, 8
-- Availability must be sampled at click time, not cached from the label.
a.ThreatMarkers.Refresh(); available = 0
assert(prepare() == nil); disarm()
available = m.Secret(); assert(prepare() == nil); disarm()
available = 8; boss = m.Secret(); assert(prepare() == nil); disarm()
boss = false; mana = m.Secret(); m.units.target.maxPower = m.Secret()
assert(prepare() == nil); disarm()
mana = false; assert(prepare() == nil); disarm()
mana = true
button.scripts.PreClick(button, "RightButton"); assert(button.attributes.type1 == nil)
a.Threat.demo = true; assert(prepare() == nil); a.Threat.demo = false
a.db.threatEnabled = false; assert(prepare() == nil); a.db.threatEnabled = true
m.units.target.hostile = false; assert(prepare() == nil); m.units.target.hostile = true
-- Lifecycle events cannot arm actions; mocks reject protected combat writes.
m.combat = true
for _, event in ipairs({"PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE", "PLAYER_REGEN_DISABLED"}) do m.Event(event) end
assert(prepare() == nil); disarm()
assert(button.attributes.type1 == nil and calls == 0)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
assert(button.attributes.type1 == nil and calls == 0)
-- Exercise the matching export's action body, not a reimplementation.
local export = os.getenv("APOGEE_FOREVER_EXPORT")
if export and export ~= "" then
    local file = assert(io.open(export .. "/Blizzard_FrameXML/SecureTemplates.lua", "rb"))
    local source = file:read("*a"); file:close()
    local first = assert(source:find("SECURE_ACTIONS.raidtarget =", 1, true))
    local last = assert(source:find("SECURE_ACTIONS.worldmarker =", first, true))
    SECURE_ACTIONS = {}
    SecureButton_GetModifiedAttribute = function(frame, attribute)
        return frame.attributes[attribute .. "1"] or frame.attributes[attribute]
    end
    assert(loadstring(source:sub(first, last - 1)))()
    local function click()
        prepare()
        if button.attributes.type1 == "raidtarget" then
            nativeInput = true; SECURE_ACTIONS.raidtarget(button, "target", "LeftButton"); nativeInput = false
        end
        disarm(); assert(button.attributes.type1 == nil)
    end
    occupied = 4; click(); assert(calls == 0 and occupied == 4)
    occupied = nil; click(); assert(calls == 1 and occupied == 8)
    available = 0; click(); assert(calls == 1 and occupied == 8)
    print("PASS exported secure action preserves existing icons and sets only an unmarked target")
else print("SKIP matching-export marker action: set APOGEE_FOREVER_EXPORT") end
for _, key in ipairs(globals) do _G[key] = saved[key] end
print("PASS click-only boss/mana marking, fresh availability, restricted-data refusal and combat disarming")
