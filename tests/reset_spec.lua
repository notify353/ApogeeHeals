local Mock = dofile("tests/mock.lua")
local m = Mock.New(); local a = m.Start()
a.BindingEditor.Open()
a.db.bindings["1"] = 999
a.db.buffs = {{id=123, enabled=false, party=true}}
a.db.position = {x=10,y=20}
a.db.editorPosition = {x=200,y=300}; a.BindingEditor.customPosition = true
local bindings, buffs = a.db.bindings, a.db.buffs
a.Settings.reset.scripts.OnClick()
assert(a.db.bindings == bindings and a.db.buffs == buffs)
assert(a.db.position.x == a.Storage.DefaultPosition().x and a.db.editorPosition == nil)
assert(not a.BindingEditor.customPosition and a.BindingEditor.frame.point[4] == -270)
assert(a.BindingEditor.frame.point[5] == -232)
-- Reset during a drag stops it and does not restore the old saved position.
a.BindingEditor.handle.scripts.OnDragStart()
a.Settings.ResetPositions()
assert(not a.BindingEditor.moving and not a.BindingEditor.customPosition and a.db.editorPosition == nil)
a.View.SetUnlocked(true); a.View.handle.scripts.OnDragStart()
a.Settings.ResetPositions()
assert(not a.View.dragging and not a.View.unlocked)
local before = a.db
a.Settings.factoryReset.scripts.OnClick()
assert(m.popup == "APOGEE_HEALS_RESET_CHARACTER" and a.db == before)
local popup = StaticPopupDialogs[m.popup]
assert(popup.button2 == "Cancel" and popup.hideOnEscape and popup.timeout == 0)
-- An opened confirmation cannot reset after combat begins.
m.combat = true; a.Settings.Refresh()
assert(not a.Settings.reset.enabled and not a.Settings.factoryReset.enabled)
popup.OnAccept(); a.Settings.ResetPositions()
assert(a.db == before and a.db.bindings["1"] == 999)
m.combat = false
local otherAddon = {sentinel=true}; ApogeeKeybindsDB = otherAddon
a.Buffs.candidates[123] = 99
popup.OnAccept()
assert(a.db ~= before and ApogeeHealsDB == a.db and next(a.db.bindings) == nil)
assert(#a.db.buffs == 0 and next(a.Buffs.candidates) == nil)
assert(a.db.editorPosition == nil and a.db.minimapAngle == nil)
assert(ApogeeKeybindsDB == otherAddon and not a.BindingEditor.frame.shown)
assert(a.View.rows[1].attributes.type1 == "target" and a.View.target.attributes.unit == "target")
a.BindingEditor.Open(); assert(a.BindingEditor.frame.point[5] == -232)
-- A fresh load keeps the default placement and cleared settings.
local saved = a.db
m=Mock.New(); a=m.Load(); ApogeeHealsDB=saved
m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush(); a.BindingEditor.Open()
assert(next(a.db.bindings) == nil and a.BindingEditor.frame.point[4] == -270)
print("PASS independent default placement, nondestructive position reset, confirmed per-character factory reset and combat guards")
