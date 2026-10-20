local m = dofile("tests/mock.lua").New()
local a = m.Start()
local d = a.HealthDiagnostics
local calls = 0
local originalHealth = UnitHealth
UnitHealth = function(unit, predicted)
    assert(unit == "player" or unit:match("^party[1-4]$"), "fixed recipients only")
    assert(predicted == false, "actual health, not predicted")
    calls = calls + 1
    return originalHealth(unit)
end
UnitInRaid = function(unit) assert(unit == "player"); return m.raid and 1 or nil end
PlaySound = function() error("diagnostic must be silent") end
PlaySoundFile = PlaySound
assert(not d.enabled and not d.root.shown and not d.frame.scripts.OnUpdate)
assert(next(d.frame.events) == nil and calls == 0)
a.Settings.healthDiagnostics.scripts.OnClick()
assert(d.root.shown and not d.enabled and calls == 0)
d.startButton.scripts.OnClick()
assert(d.enabled and d.rows.player.Outside.Readable == 1)
assert(d.rows.party1.Outside.Skipped == 1)
local p = d.rows.player
m.units.player.health = 50; d.Sample("player")
assert(p.Outside.drops == 0)
m.units.player.health = 49; d.Sample("player")
assert(p.Outside.drops == 1)
d.Sample("player"); assert(p.Outside.drops == 1)
m.units.player.health = 50; d.Sample("player")
assert(p.Outside.recoveries == 1)
m.units.player.health = 49; m.combat = true; d.Sample("player")
assert(p.Combat.drops == 1 and p.Combat.Readable == 1)
m.units.player.health = 51; d.Sample("player")
assert(p.Combat.recoveries == 1)
-- Permission guards reject health and maximum before arithmetic or display.
m.units.player.health = m.Secret(); d.Sample("player")
assert(p.Combat.Restricted == 1 and d.previous.player == nil)
assert(p.labels.Combat.status.text == "UNSUPPORTED")
m.units.player.health = 49; d.Sample("player")
assert(p.Combat.drops == 1, "after a gap, first observation is only a baseline")
m.units.player.maxHealth = m.Secret(); d.Sample("player")
assert(p.Combat.Restricted == 2 and d.previous.player == nil)
m.units.player.maxHealth = 100
for _, value in ipairs({-1, 101, math.huge, 0/0, "49", {}}) do
    m.units.player.health = value; d.Sample("player")
end
assert(p.Combat.Unavailable == 6)
m.units.player.health = nil; d.Sample("player")
m.units.player.health = 49
for _, value in ipairs({0, -1, math.huge, 0/0, "100"}) do
    m.units.player.maxHealth = value; d.Sample("player")
end
m.units.player.maxHealth = nil; d.Sample("player")
assert(p.Combat.Unavailable == 13)
m.units.player.maxHealth = 100
local guardedHealth = UnitHealth
UnitHealth = function() error("API unavailable") end
d.Sample("player"); assert(p.Combat.Unavailable == 14)
UnitHealth = nil; d.Sample("player"); assert(p.Combat.Unavailable == 15)
UnitHealth = guardedHealth
-- Unknown eligibility never permits a health read.
local before = calls
m.units.player.connected = m.Secret(); d.Sample("player")
assert(p.Combat.Restricted == 3 and calls == before)
m.units.player.connected = nil; d.Sample("player")
assert(p.Combat.Unavailable == 16 and calls == before)
m.units.player.connected = false; d.Sample("player")
m.units.player.connected = true; m.units.player.dead = true; d.Sample("player")
m.units.player.dead = false; m.raid = true; d.Sample("player")
assert(p.Combat.Skipped == 3 and calls == before)
m.raid = false
d.Sample("player")
assert(p.labels.Combat.status.text == "UNSUPPORTED", "failure history is latched")
assert(p.Combat.drops == 1)
d.resetButton.scripts.OnClick()
assert(d.enabled and p.Combat.Readable == 0 and d.previous.player == nil)
d.Sample("player"); assert(p.Combat.drops == 0 and p.Combat.Readable == 1)
-- Roster changes cannot compare different occupants.
m.units.party1 = {health=80,maxHealth=100,connected=true,dead=false}
d.Sample("party1")
m.units.party1.health = 40; d.Sample("party1")
assert(d.rows.party1.Combat.drops == 1)
local playerSamples = p.Combat.Readable
d.frame.scripts.OnEvent(d.frame, "GROUP_ROSTER_UPDATE")
assert(d.rosterChanges == 1 and d.rows.party1.Combat.drops == 0)
assert(p.Combat.Readable == playerSamples + 1)
assert(d.rows.party1.Combat.Readable == 1)
m.units.party1 = nil; d.Sample("party1")
m.units.party1 = {health=40,maxHealth=100,connected=true,dead=false}
d.Sample("party1"); assert(d.rows.party1.Combat.drops == 0)
before = calls
for _, unit in ipairs({"target", "targettarget", "pet", "raid1", m.Secret()}) do
    d.frame.scripts.OnEvent(d.frame, "UNIT_HEALTH", unit)
end
assert(calls == before)
m.units.party1.health = 50
d.frame.scripts.OnEvent(d.frame, "UNIT_HEALTH", "party1")
assert(d.rows.party1.Combat.recoveries == 1)
-- Polling covers both contexts, pauses across loading and stops completely.
before = calls
d.frame.scripts.OnUpdate(d.frame, 0.1); assert(calls == before)
d.frame.scripts.OnUpdate(d.frame, 0.1); assert(calls == before + 2)
d.frame.scripts.OnEvent(d.frame, "PLAYER_LEAVING_WORLD")
before = calls
d.frame.scripts.OnUpdate(d.frame, 1)
d.Sample(); assert(calls == before and d.previous.player == nil)
d.frame.scripts.OnEvent(d.frame, "PLAYER_ENTERING_WORLD")
assert(calls == before + 2 and p.Combat.drops == 0)
m.combat = false
d.frame.scripts.OnEvent(d.frame, "PLAYER_REGEN_ENABLED")
assert(p.Outside.Readable == 1)
d.stopButton.scripts.OnClick()
assert(not d.enabled and not d.frame.scripts.OnUpdate and next(d.frame.events) == nil)
before = calls
d.Sample(); assert(calls == before and d.root.shown and p.Outside.Readable == 1)
d.Begin(); assert(d.enabled and p.Outside.Readable == 1 and p.Combat.Readable == 0)
d.Close(); assert(not d.enabled and not d.root.shown)
d.Open(); d.Begin(); a.ResetCharacter()
assert(not d.enabled and not d.root.shown and a.db.healthDiagnostics == nil)
-- No identities or raw samples in accumulated results.
for _, value in pairs(d.previous) do assert(type(value) == "boolean") end
for _, row in pairs(d.rows) do
    for _, mode in ipairs({"Outside","Combat"}) do
        for key, value in pairs(row[mode]) do
            assert(({Readable=true,Restricted=true,Unavailable=true,Skipped=true,drops=true,recoveries=true})[key])
            assert(type(value) == "number" and value >= 0 and value == math.floor(value))
        end
    end
end
print("PASS silent health checks: boundaries, guards, contexts, gaps, roster, polling, lifecycle and no saved samples")
