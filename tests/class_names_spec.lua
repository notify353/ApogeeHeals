local m=dofile("tests/mock.lua").New(); local a=m.Start(); local label=a.View.rows[1].name
m.units.player.class="MAGE"; a.View.Refresh()
assert(label.color[1] == 0.25 and label.color[2] == 0.78 and label.color[3] == 0.92)
-- Use the client's returned color, never a duplicated addon palette.
m.classColors.MAGE={0.12,0.34,0.56}; a.View.Refresh(); assert(label.color[1] == 0.12)
m.units.player.class=m.Secret(); a.View.Refresh(); assert(label.color[1] == 1 and label.color[2] == 1)
m.units.player.class="UNAVAILABLE"; a.View.Refresh(); assert(label.color[3] == 1)
C_ClassColor=nil; a.View.Refresh(); assert(label.color[1] == 1)
local m2=dofile("tests/mock.lua").New(); local a2=m2.Start()
assert(a2.Preview.rows[2].name.color[1] == m2.classColors.WARRIOR[1])
assert(a2.Preview.rows[5].name.color[2] == m2.classColors.DRUID[2])
m2.combat=true; m2.Event("PLAYER_REGEN_DISABLED"); m2.Flush()
assert(not a2.View.rows[1].name.shown)
print("PASS native class-name colors, preview parity and unavailable-class fallback")
