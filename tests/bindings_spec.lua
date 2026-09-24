local Mock = dofile("tests/mock.lua")
local function setup(saved, class)
    local m = Mock.New()
    m.units.player.class = class or "WARRIOR"
    local known = { [2050] = true, [2052] = true, [100001] = true }
    Enum.SpellBookSpellBank = { Player = 0 }
    C_Spell.GetSpellInfo = function(id) return {name="Heal", iconID=123, spellID=id} end
    C_Spell.IsSpellHelpful = function() return true end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    C_SpellBook = {
        IsSpellInSpellBook=function(id, bank, overrides) assert(bank == 0 and overrides == false); return known[id] == true end,
        IsSpellKnown=function(id) return known[id] == true end,
        GetSpellBookItemInfo=function() return {spellID=2050} end,
    }
    local a = m.Load(); ApogeeHealsDB = saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    return m, a, known
end
local m, a, known = setup({version=1, position={x=-120,y=30}})
assert(a.db.version == 3 and a.db.position.x == -120 and next(a.db.bindings) == nil)
assert(a.Bindings.Put("2", 2050)); assert(a.Bindings.Put("shift-2", 2052))
for _, row in ipairs(a.View.rows) do
    assert(row.attributes.type1 == "target" and row.attributes.type2 == "spell")
    assert(row.attributes.spell2 == 2050 and row.attributes["shift-spell2"] == 2052)
    assert(row.attributes["ctrl-type2"] == "" and row.attributes["alt-type2"] == "")
    assert(row.attributes["ctrl-shift-type2"] == "" and row.attributes["alt-ctrl-shift-type2"] == "")
    assert(row.attributes.unit == row.unit and #row.clicks == 5 and row.attributes.useOnKeyDown == false)
end
assert(not a.Bindings.Put("alt-2", 2050))
assert(not a.Bindings.Put("2", 999))
C_Spell.IsSpellHarmful = function() return m.Secret() end
assert(not a.Bindings.Put("3", 2050))
C_Spell.IsSpellHarmful = function() return false end
assert(a.Bindings.Put("2", nil))
assert(a.View.rows[1].attributes.type2 == "" and a.View.rows[1].attributes.spell2 == nil)
assert(a.View.rows[1].attributes["shift-spell2"] == 2052)
known[2052] = nil; m.Event("SPELLS_CHANGED")
assert(a.db.bindings["shift-2"] == 2052 and a.View.rows[1].attributes["shift-type2"] == "")
known[2052] = true; m.Event("SPELLS_CHANGED")
assert(a.View.rows[1].attributes["shift-spell2"] == 2052)
print("PASS schema migration, exact ranks, modifier isolation, removal and unavailable spell recovery")

a.BindingEditor.Open()
local editor = a.BindingEditor
for _, button in pairs(editor.buttons) do assert(not button.protected and not button.attributes.type) end
m.cursor = {"spell", 1, "pet", 2050}
assert(a.Bindings.Cursor() == nil)
m.cursor = {"spell", 1, "spell"}
assert(a.Bindings.Cursor() == 2050)
m.cursor = {"spell", 1, "spell", 2050}
editor.buttons["2"].scripts.OnReceiveDrag()
assert(a.db.bindings["2"] == 2050 and m.cursor == nil)
editor.buttons["2"].scripts.OnDragStart()
editor.buttons["shift-2"].hovered = true
editor.buttons["2"].scripts.OnDragStop()
assert(a.db.bindings["2"] == 2052 and a.db.bindings["shift-2"] == 2050)
editor.buttons["shift-2"].hovered = false
editor.buttons["2"].scripts.OnDragStart(); editor.buttons["2"].scripts.OnDragStop()
assert(a.db.bindings["2"] == 2052 and editor.source == nil)
editor.buttons["2"].remove.scripts.OnClick()
assert(a.db.bindings["2"] == nil)
editor.buttons["shift-2"].scripts.OnDragStart()
m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(editor.source == nil and not editor.frame.shown)
assert(not a.Bindings.Put("3", 2050)); assert(not a.Bindings.Swap("3", "shift-2"))
known[2050] = nil; m.Event("SPELLS_CHANGED")
assert(a.View.rows[1].attributes["shift-spell2"] == 2050)
editor.Open(); assert(not editor.frame.shown)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
assert(a.View.rows[1].attributes["shift-type2"] == "" and a.db.bindings["shift-2"] == 2050)
print("PASS non-casting editor, drag swap/cancel/remove and combat deferral")

local saved = a.db
local m2, a2 = setup(saved)
assert(a2.db.bindings["shift-2"] == 2050 and a2.View.rows[1].attributes["shift-spell2"] == 2050)
local validated = a2.Storage.Open({version=2,bindings={["2"]=100001,["3"]=-1,["4"]=0/0,["alt-2"]=2050}})
assert(validated.bindings["2"] == 100001 and validated.bindings["3"] == nil and validated.bindings["4"] == nil)
assert(validated.bindings["alt-2"] == nil)
assert(a2.Storage.Open({version=4}) == nil)
a2.View.SetUnlocked(true)
for _, row in ipairs(a2.Preview.rows) do assert(not row.protected and row.attributes.type2 == nil) end
print("PASS reload persistence, invalid storage filtering and inert preview")

local minimap = a2.Minimap
local click = minimap.button.scripts.OnClick
assert(minimap.button.enabled and minimap.border.vertexColor[2] == 1)
click(minimap.button, "LeftButton")
assert(a2.BindingEditor.frame:IsShown() and minimap.border.vertexColor[2] == 0.8)
click(minimap.button, "LeftButton")
assert(not a2.BindingEditor.frame:IsShown() and minimap.border.vertexColor[2] == 1)
a2.BindingEditor.Open(); a2.BindingEditor.frame:Hide()
assert(minimap.border.vertexColor[2] == 1)
a2.BindingEditor.Open(); m2.combat = true; m2.Event("PLAYER_REGEN_DISABLED")
assert(not minimap.button.enabled and not a2.BindingEditor.frame:IsShown())
click(minimap.button, "LeftButton"); assert(not a2.BindingEditor.frame:IsShown())
m2.combat = false; m2.Event("PLAYER_REGEN_ENABLED"); assert(minimap.button.enabled)
local opened
a2.Settings.category.GetID = function() return 123 end
Settings.OpenToCategory = function(id) opened = id end
click(minimap.button, "RightButton"); assert(opened == 123)
print("PASS minimap toggle, settings shortcut, Escape state and combat lock")

local lm, la, learned = setup()
assert(#la.Bindings.slots == 15)
la.BindingEditor.Open()
lm.cursor = {"spell", 1, "spell", 2050}
la.BindingEditor.buttons["1"].scripts.OnReceiveDrag()
assert(la.Bindings.Put("shift-1", 2052) and la.Bindings.Put("ctrl-1", 2050))
for _, row in ipairs(la.View.rows) do
    assert(row.attributes.type1 == "spell" and row.attributes.spell1 == 2050)
    assert(row.attributes["shift-spell1"] == 2052 and row.attributes["ctrl-spell1"] == 2050)
    assert(row.attributes["alt-type1"] == "" and row.attributes["ctrl-shift-type1"] == "")
end
local _, reloaded = setup(la.db)
assert(reloaded.db.bindings["1"] == 2050 and reloaded.View.rows[1].attributes.spell1 == 2050)
-- Recreate the fixture because setup replaces the simulated game globals.
lm, la, learned = setup(la.db)
learned[2050] = nil; lm.Event("SPELLS_CHANGED")
assert(la.View.rows[1].attributes.type1 == "" and la.db.bindings["1"] == 2050)
learned[2050] = true; lm.Event("SPELLS_CHANGED")
assert(la.View.rows[1].attributes.type1 == "spell")
lm.combat = true; lm.Event("PLAYER_REGEN_DISABLED")
assert(not la.Bindings.Put("1", nil) and la.View.rows[1].attributes.type1 == "spell")
lm.combat = false; lm.Event("PLAYER_REGEN_ENABLED")
assert(la.Bindings.Put("1", nil))
assert(la.View.rows[1].attributes.type1 == "target" and la.View.rows[1].attributes.spell1 == nil)
assert(la.Bindings.Put("shift-1", nil))
assert(la.View.rows[1].attributes["shift-type1"] == "")
assert(la.View.rows[1].attributes["ctrl-spell1"] == 2050)
print("PASS left-click assignment, modifiers, persistence, combat lock and targeting restoration")

local pm, pa, priestKnown = setup(nil, "PRIEST")
assert(pa.db.bindings["1"] == nil and pa.View.rows[1].attributes.spell1 == 2052)
pa.BindingEditor.Open()
assert(pa.BindingEditor.buttons["1"].icon.texture == 123)
assert(not pa.BindingEditor.buttons["1"].remove.shown)
pa.BindingEditor.buttons["1"].scripts.OnDragStart(); assert(pa.BindingEditor.source == nil)
priestKnown[2053] = true; pm.Event("SPELLS_CHANGED")
for _, row in ipairs(pa.View.rows) do assert(row.attributes.spell1 == 2053) end
assert(pa.db.bindings["1"] == nil and pa.View.rows[1].attributes["shift-type1"] == "")
assert(pa.Bindings.Put("1", 2050)); assert(pa.View.rows[1].attributes.spell1 == 2050)
priestKnown[2050] = nil; pm.Event("SPELLS_CHANGED")
assert(pa.View.rows[1].attributes.type1 == "" and pa.db.bindings["1"] == 2050)
assert(pa.Bindings.Put("1", nil)); assert(pa.View.rows[1].attributes.spell1 == 2053)
pm.combat = true; priestKnown[2053] = nil; pm.Event("SPELLS_CHANGED")
assert(pa.View.rows[1].attributes.spell1 == 2053)
pm.combat = false; pm.Event("PLAYER_REGEN_ENABLED")
assert(pa.View.rows[1].attributes.spell1 == 2052)
priestKnown[2052] = nil; pm.Event("SPELLS_CHANGED")
assert(pa.View.rows[1].attributes.type1 == "target")
pm.units.player.class = pm.Secret(); pm.Event("SPELLS_CHANGED")
assert(pa.View.rows[1].attributes.type1 == "target")
print("PASS Priest class default, learned ranks, manual priority, removal and combat deferral")

local sm, sa, shieldKnown = setup(nil, "PRIEST")
assert(sa.View.rows[1].attributes.type2 == "")
shieldKnown[17] = true; sm.Event("SPELLS_CHANGED")
assert(sa.View.rows[1].attributes.spell2 == 17 and sa.db.bindings["2"] == nil)
shieldKnown[592] = true; sm.Event("SPELLS_CHANGED")
assert(sa.View.rows[1].attributes.spell2 == 592)
assert(sa.Bindings.Put("2", 2050))
shieldKnown[10901] = true; sm.Event("SPELLS_CHANGED")
assert(sa.View.rows[1].attributes.spell2 == 2050)
assert(sa.Bindings.Put("2", nil))
for _, row in ipairs(sa.View.rows) do
    assert(row.attributes.spell2 == 10901 and row.attributes["shift-type2"] == "")
end
sa.BindingEditor.Open(); assert(not sa.BindingEditor.buttons["2"].remove.shown)
sm.combat = true; shieldKnown[10901] = nil; sm.Event("SPELLS_CHANGED")
assert(sa.View.rows[1].attributes.spell2 == 10901)
sm.combat = false; sm.Event("PLAYER_REGEN_ENABLED")
assert(sa.View.rows[1].attributes.spell2 == 592)
sm.units.player.class = "MAGE"; sm.Event("SPELLS_CHANGED")
assert(sa.View.rows[1].attributes.type2 == "")
print("PASS Priest right-click shield default, rank upgrades, override priority and class isolation")

local hm, ha, holyKnown = setup(nil, "PALADIN")
assert(ha.View.rows[1].attributes.type1 == "target")
holyKnown[635] = true; hm.Event("SPELLS_CHANGED")
assert(ha.View.rows[1].attributes.spell1 == 635 and ha.db.bindings["1"] == nil)
holyKnown[639] = true; hm.Event("SPELLS_CHANGED")
assert(ha.View.rows[1].attributes.spell1 == 639)
assert(ha.Bindings.Put("1", 635))
holyKnown[25292] = true; hm.Event("SPELLS_CHANGED")
assert(ha.View.rows[1].attributes.spell1 == 635)
assert(ha.Bindings.Put("1", nil))
for _, row in ipairs(ha.View.rows) do
    assert(row.attributes.spell1 == 25292 and row.attributes.type2 == "")
    assert(row.attributes["shift-type1"] == "" and row.attributes["ctrl-type1"] == "")
end
hm.combat = true; holyKnown[25292] = nil; hm.Event("SPELLS_CHANGED")
assert(ha.View.rows[1].attributes.spell1 == 25292)
hm.combat = false; hm.Event("PLAYER_REGEN_ENABLED")
assert(ha.View.rows[1].attributes.spell1 == 639)
hm.units.player.class = "MAGE"; hm.Event("SPELLS_CHANGED")
assert(ha.View.rows[1].attributes.type1 == "target")
print("PASS Paladin Holy Light default, rank upgrades, manual priority, combat deferral and class isolation")
