local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local a = m.Start()
local inaccessible = m.InaccessibleTable()
assert(canaccessvalue(inaccessible) and not issecretvalue(inaccessible))
assert(not canaccesstable(inaccessible))

-- A readable table reference does not grant permission to index its contents.
local originalSpell = C_Spell.GetSpellInfo
C_Spell.GetSpellInfo = function() return inaccessible end
assert(a.Bindings.Resolve(430) == nil)
assert(a.Buffs.Info(430) == nil)
a.Drinking.Resolve()
C_Spell.GetSpellInfo = originalSpell
a.Drinking.Resolve()

C_UnitAuras.GetAuraDataByIndex = function() return inaccessible end
assert(a.Buffs.Scan("player") == nil, "An inaccessible scan is unknown, never empty")
assert(not a.Drinking.IsDrinking("player"))
a.View.Refresh(); a.Buffs.Refresh()
print("PASS readable references with inaccessible contents never enter table indexing")

-- Cursor spellbook fallback shares the same boundary before reading spellID.
Enum.SpellBookSpellBank = {Player=0}
C_SpellBook = {GetSpellBookItemInfo=function() return inaccessible end}
m.cursor = {"spell", 1, "spell"}
assert(a.Bindings.Cursor() == nil)

-- Unknown scans must clear an already visible reminder, and recover afterward.
local id = 700001
C_Spell.GetSpellInfo = function() return {name="Test Upkeep", spellID=id, iconID=id} end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
C_SpellBook.IsSpellInSpellBook = function() return true end
C_SpellBook.IsSpellKnown = function() return true end
a.db.buffs = {{id=id, enabled=true, party=true}}
C_UnitAuras.GetAuraDataByIndex = function() return nil end
a.Buffs.Refresh()
local row = a.View.rows[1]
assert(row.buffReminders[1].shown and row.buffButtons[1].attributes.spell1 == id)
C_UnitAuras.GetAuraDataByIndex = function() return inaccessible end
a.Buffs.Refresh()
assert(not row.buffReminders[1].shown and row.buffButtons[1].attributes.spell1 == nil)
C_UnitAuras.GetAuraDataByIndex = function() return nil end
a.Buffs.Refresh()
assert(row.buffReminders[1].shown and row.buffButtons[1].attributes.spell1 == id)
assert(a.Access.Readable(nil, false, 0, "", {}))
assert(not a.Access.Readable(m.Secret()))
print("PASS cursor rejection, stale reminder clearing and readable-data recovery")

local spellAPI, bookAPI, enum = C_Spell, C_SpellBook, Enum
C_Spell = nil
assert(a.Bindings.Resolve(id) == nil and a.Buffs.Info(id) == nil)
assert(a.Buffs.ForParty({id=id, party=true}) == true)
a.db.bindings["1"] = id
a.Bindings.Apply(); a.Buffs.Refresh()
assert(row.attributes.type1 == "" and a.db.bindings["1"] == id)
C_Spell = spellAPI; C_SpellBook = nil; Enum = nil
assert(a.Bindings.Resolve(id) == nil and a.Bindings.Cursor() == nil)
C_SpellBook = bookAPI; Enum = enum
a.Bindings.Apply()
assert(row.attributes.type1 == "spell" and row.attributes.spell1 == id)
print("PASS missing optional spell APIs retain assignments and recover without targeting fallback")

m = Mock.New(); a = m.Load(); canaccesstable = nil
m.Event("ADDON_LOADED", "ApogeeHeals")
assert(not a.started and ApogeeHealsDB == nil and not a.View.rows)
print("PASS missing table-access capability rejects startup before saved-data or frame changes")
