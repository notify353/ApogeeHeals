local m, a = dofile("tests/runtime_fixture.lua").Start()
local target, alias = a.View.target, a.View.targetTarget
m.units.target = {name="Enemy", health=90, maxHealth=100, power=40, maxPower=100, kind=0, auras={}}
m.units.targettarget = {name="Ally", health=80, maxHealth=100, power=30, maxPower=100, kind=0, auras={}}
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
-- Count full native aura reconciliations, independently of the immediate health sinks.
local rebuilds, identities = 0, {}
alias.hotContainers = {{UpdateAllAuras=function()
    rebuilds = rebuilds + 1
    identities[#identities + 1] = m.units.targettarget and m.units.targettarget.name
end}}
local anchor, recipient = alias.point, alias.attributes.unit
for i = 1, 100 do
    m.units.target.health = 90 - i / 10
    m.units.targettarget.health = 80 - i / 10
    m.Event("UNIT_HEALTH", "target")
    m.Event("UNIT_POWER_UPDATE", "targettarget")
    assert(target.health.value == m.units.target.health and alias.health.value == m.units.targettarget.health,
        "health painting must stay immediate during event bursts")
end
assert(rebuilds == 0, "health/power bursts must not force full native aura rebuilds: " .. rebuilds)
assert(#m.timers == 0, "ordinary target values do not schedule party-wide scans")
for i = 1, 100 do m.Event("UNIT_AURA", "targettarget") end
assert(rebuilds == 0 and #m.timers == 1, "alias aura event bursts share one existing deferred refresh")
m.units.targettarget.name = "Replacement Ally"
m.Flush()
assert(rebuilds == 1 and identities[1] == "Replacement Ally", "queued refresh resolves the current alias")
assert(alias.name.text == "Replacement Ally")
for i = 1, 100 do m.Event("UNIT_AURA", "target") end
assert(rebuilds == 1 and #m.timers == 1, "target aura bursts do not rebuild synchronously")
m.Flush(); assert(rebuilds == 2, "target aura bursts reconcile once")
local before = rebuilds
m.units.targettarget.name = "Immediate Ally"
m.Event("UNIT_TARGET", "target")
assert(rebuilds == before + 1 and alias.name.text == "Immediate Ally", "alias changes reconcile immediately")
before = rebuilds
for i = 1, 100 do m.Event("UNIT_HEALTH", "nameplate1"); m.Event("UNIT_AURA", "raid1") end
assert(rebuilds == before and #m.timers == 0, "unrelated units must not schedule party or aura work")
alias.scripts.OnUpdate(alias, 0.2)
assert(rebuilds == before + 1, "existing alias polling still catches missed identity notifications")
m.Event("UNIT_AURA", "targettarget")
m.Event("PLAYER_LEAVING_WORLD")
before = rebuilds
m.Flush(); m.Event("UNIT_AURA", "targettarget"); alias.scripts.OnUpdate(alias, 0.2)
assert(rebuilds == before and #m.timers == 0, "departed-world callbacks cannot refresh auras")
m.units.targettarget.name = "Arriving Ally"
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
assert(rebuilds > before and alias.name.text == "Arriving Ally", "world entry reconciles current aliases")
assert(alias.point == anchor and alias.attributes.unit == recipient, "combat refreshes preserve protected layout and recipient")
print("PASS combat target event bursts: immediate health, coalesced auras, current aliases, unrelated-unit filtering and zoning")
