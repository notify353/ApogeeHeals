local Mock = dofile("tests/mock.lua")
local m = Mock.New(); local a = m.Start()
for _, rows in ipairs({a.View.rows, a.Preview.rows}) do
    for _, row in ipairs(rows) do
        assert(row.name.point[1] == "LEFT" and row.name.point[2] == row.health)
        assert(row.name.width == 89.5 and row.name.height == 14)
        assert(row.level.point[4] == 4 and row.name.point[4] == 18.5)
        assert(row.name.justify == "LEFT" and row.name.justifyV == "MIDDLE")
        assert(row.nameLayer:GetFrameLevel() > row.incoming.bar:GetFrameLevel())
        assert(row.nameLayer.mouse == false and row.name.wrap == false)
    end
end
local row=a.View.rows[1]
assert(row.name.shown and row.name.text == "Priest" and row.level.text == "60")
m.units.player.level=59; m.Event("UNIT_LEVEL", "player"); m.Flush()
assert(row.level.text == "59")
m.units.player.level=m.Secret(); a.View.Refresh(); assert(row.level.text == "?")
m.units.player.level=-1; a.View.Refresh(); assert(row.level.text == "?")
m.units.player.level=60
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not row.name.shown and not row.level.shown) -- No one-frame text flash.
m.Flush(); assert(not row.name.shown and row.name.text == "")
m.units.player.name="Changed Name"; m.Event("UNIT_NAME_UPDATE", "player"); m.Flush()
assert(not row.name.shown and row.name.text == "")
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(row.name.shown and row.name.text == "Changed")
assert(row.level.shown and row.level.text == "60")
assert(not a.View.rows[2].name.shown)
a.View.SetUnlocked(true); assert(a.Preview.root.shown and a.Preview.rows[1].name.text == "Priest")
print("PASS inset left-aligned name layering and out-of-combat-only visibility")
