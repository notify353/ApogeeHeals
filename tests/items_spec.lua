local Mock = dofile("tests/mock.lua")
local function setup(saved)
    local m = Mock.New()
    Enum.ItemClass = {Consumable=0}
    Enum.ItemConsumableSubclass = {Bandage=7}
    C_Item = {
        GetItemInfoInstant=function(id) return id, "Consumable", "Bandage", "", 456, 0, id == 1251 and 7 or 5 end,
        GetItemNameByID=function() return "Linen Bandage" end,
    }
    local a = m.Load(); ApogeeHealsDB = saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    a.BindingEditor.Open()
    return m, a
end
local m, a = setup()
m.cursor = {"item", 1251, "item:1251"}
a.BindingEditor.buttons["1"].scripts.OnReceiveDrag()
assert(m.cursor == nil and a.db.bindings["1"].kind == "item" and a.db.bindings["1"].id == 1251)
assert(a.BindingEditor.buttons["1"].icon.texture == 456 and a.Bindings.rangeSpell == nil)
a.BindingEditor.buttons["1"].scripts.OnEnter()
for _, row in ipairs(a.View.rows) do
    assert(row.attributes.type1 == "item" and row.attributes.item1 == "item:1251")
    assert(row.attributes.spell1 == nil and row.attributes.unit == row.unit)
    assert(row.attributes["alt-type1"] == "" and row.attributes["alt-item1"] == nil)
end
m.cursor = {"item", 999, "item:999"}
a.BindingEditor.buttons["1"].scripts.OnReceiveDrag()
assert(m.cursor ~= nil and a.db.bindings["1"].id == 1251)
m.cursor = nil
assert(a.Bindings.Swap("1", "shift-2"))
assert(a.View.rows[1].attributes.item1 == nil and a.View.rows[1].attributes.type1 == "target")
assert(a.View.rows[1].attributes["shift-item2"] == "item:1251")
local saved = a.db
m, a = setup(saved)
assert(a.db.bindings["shift-2"].id == 1251 and a.View.rows[1].attributes["shift-type2"] == "item")
-- No inventory-count dependency: an empty stack remains assigned for replenishment.
C_Item.GetItemNameByID = function() return nil end
assert(a.Bindings.Resolve(a.db.bindings["shift-2"]).name == "Bandage (item 1251)")
local instant = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function() return nil end
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Event("GET_ITEM_INFO_RECEIVED", 1251)
assert(a.View.rows[1].attributes["shift-item2"] == "item:1251")
assert(not a.Bindings.Put("shift-2", nil) and not a.Bindings.Swap("shift-2", "3"))
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
assert(a.db.bindings["shift-2"].id == 1251 and a.View.rows[1].attributes["shift-type2"] == "")
C_Item.GetItemInfoInstant = instant; m.Event("GET_ITEM_INFO_RECEIVED", 1251)
assert(a.View.rows[1].attributes["shift-type2"] == "item")
-- Restricted return fields never participate in comparisons or persistence.
C_Item.GetItemInfoInstant = function() return 1251, nil, nil, nil, 456, m.Secret(), 7 end
assert(not a.Bindings.Put("3", {kind="item",id=1251}))
C_Item.GetItemInfoInstant = instant
m.cursor = {"item", m.Secret()}; assert(a.Bindings.Cursor() == nil); m.cursor = nil
assert(not a.Bindings.Put("3", {kind="item",id=0/0}))
assert(not a.Bindings.Put("3", {kind="item",id=math.huge}))
Enum.SpellBookSpellBank = {Player=0}
C_Spell.GetSpellInfo = function() return {name="Heal",iconID=123} end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
C_SpellBook = {IsSpellKnown=function() return true end, IsSpellInSpellBook=function() return true end}
assert(a.Bindings.Put("shift-2", 2050))
assert(a.View.rows[1].attributes["shift-item2"] == nil and a.View.rows[1].attributes["shift-spell2"] == 2050)
assert(a.Bindings.Put("shift-2", {kind="item",id=1251}))
assert(a.View.rows[1].attributes["shift-spell2"] == nil)
a.BindingEditor.buttons["shift-2"].remove.scripts.OnClick()
assert(a.db.bindings["shift-2"] == nil and a.View.rows[1].attributes["shift-item2"] == nil)
local clean = a.Storage.Open({version=3,bindings={
    ["1"]={kind="item",id=1251,extra="discard"}, ["2"]={kind="item",id=-1},
    ["3"]={kind="macro",id=1251}, ["4"]={kind="item",id=0/0}, ["5"]=2050}})
assert(clean.bindings["1"].id == 1251 and clean.bindings["1"].extra == nil and clean.bindings["5"] == 2050)
assert(clean.bindings["2"] == nil and clean.bindings["3"] == nil and clean.bindings["4"] == nil)
print("PASS bandage cursor, display, persistence, fixed units, replacement, removal, restrictions and combat deferral")
