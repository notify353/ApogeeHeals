local m = dofile("tests/mock.lua").New()
local a = m.Start()
for _, unit in ipairs({"target", "targettarget"}) do
    local row = unit == "target" and a.View.target or a.View.targetTarget
    local nameWidth, anchor = row.name.width, row.point
    m.units[unit] = {name="Long Selected Creature Name", health=80, maxHealth=100,
        power=50, maxPower=100, kind=0, level=6, connected=true, dead=false, auras={}}
    m.Event("UNIT_HEALTH", unit)
    assert(row.name.shown and row.level.shown and (row.status.text or "") == "")
    assert(row.health.value == 80 and row.power.value == 50)
    m.combat = true
    -- Death must update immediately, before the range poll, even with stale resource data.
    m.units[unit].dead = true
    if row.cast then row.cast:SetAlpha(1) end
    m.Event("UNIT_HEALTH", unit)
    assert(row.name.shown and row.name.text == m.units[unit].name and row.level.shown)
    assert(row.status.text == "DEAD" and row.name.width == nameWidth - 30)
    assert(row.health.value == 0 and row.power.value == 0)
    assert(not row.cast or row.cast.alpha == 0)
    a.View.RefreshRange()
    assert(row.name.shown and row.status.text == "DEAD" and row.health.alpha == 1)
    assert(row.point == anchor and row.attributes.unit == unit)
    -- Connection status wins, matching the existing party-state policy.
    m.units[unit].connected = false
    m.Event("UNIT_CONNECTION", unit)
    assert(row.status.text == "OFFLINE" and row.name.shown)
    m.units[unit].connected = true; m.units[unit].dead = false
    m.Event("UNIT_FLAGS", unit)
    assert(row.status.text == "" and row.name.width == nameWidth and row.name.shown)
    assert(row.health.value == 80 and row.power.value == 50)
    -- Restricted state is not proof of death: preserve native display sinks.
    m.units[unit].dead = m.Secret(); m.units[unit].name = m.Secret()
    m.units[unit].health = m.Secret(); m.units[unit].power = m.Secret()
    m.Event("UNIT_HEALTH", unit)
    assert(row.status.text == "" and row.name.shown and row.name.width == nameWidth)
    assert(row.name.text == m.units[unit].name and row.health.value == m.units[unit].health)
    assert(row.power.value == m.units[unit].power)
    m.units[unit].dead = true; m.Event("UNIT_FLAGS", unit)
    m.units[unit] = nil; m.Event("UNIT_HEALTH", unit)
    assert(row.status.text == "" and row.name.text == "" and not row.name.shown)
    assert(row.health.value == 0 and row.power.value == 0 and row.name.width == nameWidth)
    m.combat = false
end
-- Party death presentation remains the established centered status.
m.units.player.dead = true; a.View.Refresh()
assert(a.View.rows[1].status.text == "DEAD" and not a.View.rows[1].name.shown)
print("PASS selected corpse identity, status layout, stale resources, resurrection, restricted values and combat")
