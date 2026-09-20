local Mock = dofile("tests/mock.lua")
local m=Mock.New(); local a=m.Start()
for _, rows in ipairs({a.View.rows, a.Preview.rows}) do
    for i, row in ipairs(rows) do
        assert(row.health.point[5] == 0 and row.power.point[5] == -14.5)
        assert(row.height == 19.5)
        if i > 1 then assert(rows[i-1].point[5] - row.point[5] - row.height == 2) end
        assert(row.drinkIcon.point[2] == row.health and row.drinkIcon.point[3] == "RIGHT")
        assert(row.drinkIcon.width == 12 and row.drinkIcon.height == 12)
    end
end
assert(a.View.root.height == 105.5 and a.Preview.root.height == 105.5)
local row=a.View.rows[1]
m.units.player.auras={{spellId=430,name="Drink"}}; a.View.Refresh()
assert(row.drinkIcon.shown and row.status.text == "" and row.name.shown)
m.units.player.auras={}; a.View.Refresh(); assert(not row.drinkIcon.shown)
m.units.player.auras={{spellId=430,name="Drink"}}; a.View.Refresh()
m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); assert(not row.drinkIcon.shown)
m.Flush(); assert(not row.name.shown)
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
m.units.player.dead=true; a.View.Refresh()
assert(row.status.text == "DEAD" and not row.name.shown and not row.drinkIcon.shown)
m.units.player.connected=false; a.View.Refresh()
assert(row.status.text == "OFFLINE" and not row.name.shown)
assert(not a.Preview.rows[3].drinkIcon.shown) -- Demo begins with a clean full party.
print("PASS compact row spacing, cup indicator and non-overlapping state labels")
