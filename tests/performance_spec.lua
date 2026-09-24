local baseline = arg and arg[1] == "baseline"
local m = dofile("tests/mock.lua").New()
local id = 700001
for index = 0, 4 do
    local unit = index == 0 and "player" or "party" .. index
    m.units[unit] = {name=unit, class="MAGE", health=80, maxHealth=100,
        power=50, maxPower=100, kind=0, connected=true, dead=false, auras={}}
    for aura = 1, 10 do m.units[unit].auras[aura] = {spellId=aura, name="Aura" .. aura} end
end
Enum.SpellBookSpellBank = {Player=0}
local spells, scopes, drivers = 0, 0, 0
C_Spell.GetSpellInfo = function(spell)
    spells = spells + 1
    return {spellID=spell, name="Spell" .. spell, iconID=spell}
end
C_Spell.IsSelfBuff = function() scopes = scopes + 1; return false end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
C_SpellBook = {IsSpellInSpellBook=function() return true end, IsSpellKnown=function() return true end}
local nativeDriver = RegisterStateDriver
RegisterStateDriver = function(...) drivers = drivers + 1; return nativeDriver(...) end
local a = m.Load()
ApogeeHealsDB = {version=3, bindings={["2"]=id}, buffs={{id=id, enabled=true, party=true}}}
m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
spells = 0; a.Bindings.Apply()
local bindingReads = spells
a.Buffs.OpenPicker(); a.Buffs.picker:Hide()
spells, scopes, drivers, m.auraReads = 0, 0, 0, 0
for i = 1, 100 do m.Event("UNIT_HEALTH", "player"); m.Flush() end
print(string.format("100 refreshes: aura reads=%d, spell reads=%d, scope reads=%d, driver registrations=%d; binding apply spell reads=%d",
    m.auraReads, spells, scopes, drivers, bindingReads))
if not baseline then
    assert(drivers == 0, "Unchanged reminders must not re-register secure visibility")
    assert(bindingReads == 1, "One assignment is resolved once for all five fixed recipients")
    assert(spells == 100 and scopes == 100, "Resolve each watch once per refresh; skip hidden picker")
end
-- Bursts keep one refresh without deferring updates beyond the existing callback.
local reads = m.auraReads
for i = 1, 100 do m.Event("UNIT_AURA", "party1") end
assert(#m.timers == 1); m.Flush()
assert(m.auraReads == reads + 110)
local row = a.View.rows[1]
assert(row.buffButtons[1].attributes.spell1 == id)
-- Observation changes clear/recover actions; combat must not update protected state.
m.units.player.auras[11] = {spellId=id, name="Spell" .. id}
m.Event("UNIT_AURA", "player"); m.Flush()
assert(row.buffButtons[1].attributes.spell1 == nil)
m.units.player.auras[11] = nil
m.Event("UNIT_AURA", "player"); m.Flush()
assert(row.buffButtons[1].attributes.spell1 == id)
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
a.db.buffs[1].enabled = false
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(row.buffButtons[1].attributes.spell1 == nil)
a.Buffs.OpenPicker()
assert(a.Buffs.checks[1].checked == false, "Reopening a hidden picker must refresh its choices")
a.Buffs.picker:Hide()
-- A callback queued before zoning must not paint/query the departed world.
m.Event("UNIT_HEALTH", "player"); m.Event("PLAYER_LEAVING_WORLD")
reads = m.auraReads; m.Flush()
local departedReads = m.auraReads - reads
print("Queued refresh aura reads after leaving world: " .. departedReads)
if not baseline then assert(departedReads == 0) end
m.Event("UNIT_AURA", "player")
if not baseline then assert(#m.timers == 0) end
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
assert(m.auraReads > reads and row.health.value == 80)
reads = m.auraReads
m.Event("UNIT_HEALTH", "player"); m.Event("PLAYER_LEAVING_WORLD")
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
assert(m.auraReads == reads + 110 and #m.timers == 0,
    "Rapid world exit/reentry keeps one fresh callback without losing the arrival update")
print("PASS event bursts, action invalidation, combat deferral and zoning recovery")
