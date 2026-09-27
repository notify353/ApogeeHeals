local Mock = dofile("tests/mock.lua")
local m = Mock.New(); local a = m.Start()
local row = a.View.target
UnitIsPlayer = function() return m.targetPlayer end
UnitReaction = function() return m.reaction end
assert(row.unit == "target" and row.attributes.unit == "target")
assert(row.attributes.type1 == "target" and row.driver == "[@target,exists] show; hide")
assert(row.point[1] == "BOTTOMLEFT" and row.point[2] == a.View.rows[1] and row.point[3] == "TOPLEFT")
assert(row.point[4] == 0 and row.point[5] == row.height)
assert(row.width == a.Style.width and row.health.width == a.Style.width and row.incoming.bar.width == a.Style.width)
assert(row.power.width == a.Style.width and row.name.width == 89.5)
assert(row.name.text == "" and row.health.value == 0)
m.units.target = {name="High Priestess of the Silver Moon",health=80,maxHealth=100,
    power=20,maxPower=100,kind=0,level=61,class="MAGE",auras={}}
m.targetPlayer=false; m.reaction=5
m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(row.name.text == m.units.target.name and row.level.text == "61" and row.name.font[2] == 6)
assert(row.health.value == 80 and row.power.value == 20 and row.classStrip.color[2] == 0.74)
m.reaction=4; m.Event("UNIT_FACTION", "target"); assert(row.classStrip.color[1] == 0.90)
m.reaction=2; m.Event("UNIT_FACTION", "target"); assert(row.classStrip.color[1] == 0.86)
m.targetPlayer=true
UnitName=function(unit) if unit == "target" then return "Jane", "Silver Moon" end return "Priest" end
m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(row.name.text == "Jane Silver Moon" and row.classStrip.color[1] == 0.25 and row.name.font[2] == 6)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
assert(row.name.text == "Jane Silver Moon")
m.units.target.health=m.Secret(); m.units.target.maxHealth=m.Secret()
m.units.target.power=m.Secret(); m.units.target.maxPower=m.Secret()
m.secretPrediction=m.Secret(); m.reaction=m.Secret(); m.targetPlayer=false
UnitName=function() return m.Secret() end
m.Event("UNIT_HEALTH", "target")
assert(row.health.value == m.units.target.health and row.power.value == m.units.target.power)
assert(row.name.text == "" and row.classStrip.color[1] == a.Style.muted[1])
assert(row.name.font[2] == 6)
m.targetPlayer=m.Secret(); m.Event("UNIT_NAME_UPDATE", "target")
assert(row.name.font[2] == 6)
m.units.target.maxPower=0; m.Event("UNIT_MAXPOWER", "target")
assert(row.power.value == 0 and row.power.max == 1)
m.units.target=nil; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(row.health.value == 0 and row.power.value == 0 and row.name.text == "")
assert(row.attributes.unit == "target" and #a.View.rows == 5)
print("PASS target identity, reaction, events, native restricted display and combat-safe geometry")
