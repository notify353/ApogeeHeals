local Mock = dofile("tests/mock.lua")
local m=Mock.New(); local a=m.Start(); local row=a.View.targetTarget
assert(row.unit=="targettarget" and row.attributes.unit=="targettarget")
assert(row.attributes.type1=="target" and row.attributes.useOnKeyDown==false)
assert(row.driver=="[@targettarget,exists] show; hide")
assert(row.point[1]=="BOTTOMLEFT" and row.point[2]==a.View.target and row.point[3]=="TOPLEFT")
assert(row.point[4]==0 and row.point[5]==4 and row.width==a.View.target.width)
assert(row.caption==nil)
assert(row.health.value==0 and row.name.text=="")
UnitIsPlayer=function(unit) return unit=="targettarget" end
m.units.target={name="Enemy",health=90,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
m.units.targettarget={name="Friendly Player",health=70,maxHealth=100,power=40,maxPower=100,
    kind=0,class="MAGE",auras={}}
m.Event("UNIT_TARGET","target")
assert(row.name.text=="Friendly Player" and row.health.value==70 and row.power.value==40)
assert(row.name.font[2]==6 and a.View.target.name.font[2]==6)
assert(a.View.target.name.text=="Enemy" and row.classStrip.color[1]==0.25)
m.units.targettarget.health=55
m.Event("UNIT_HEALTH","targettarget"); assert(row.health.value==55)
-- Polling catches changing health/identity even when no alias unit event arrives.
m.units.targettarget.name="Another Player";m.units.targettarget.health=30
row.scripts.OnUpdate(row,0.1);assert(row.health.value==55)
row.scripts.OnUpdate(row,0.1);assert(row.health.value==30 and row.name.text=="Another Player")
m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
local anchor=row.point
m.units.targettarget.health=m.Secret();m.units.targettarget.maxHealth=m.Secret()
m.units.targettarget.power=m.Secret();m.units.targettarget.maxPower=m.Secret();m.secretPrediction=m.Secret()
m.units.targettarget.name=m.Secret()
row.scripts.OnUpdate(row,0.2)
assert(row.health.value==m.units.targettarget.health and row.power.value==m.units.targettarget.power)
assert(row.name.text==m.units.targettarget.name and row.point==anchor and row.attributes.unit=="targettarget")
m.units.targettarget=nil;m.Event("UNIT_TARGET","target")
assert(row.health.value==0 and row.power.value==0 and row.name.text=="")
m.units.targettarget={name="Back",health=10,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
row.scripts.OnShow(row);assert(row.health.value==10 and row.name.text=="Back")
m.Event("PLAYER_LEAVING_WORLD");m.units.targettarget.health=25
row.scripts.OnUpdate(row,0.2);m.Event("UNIT_HEALTH","targettarget")
assert(row.health.value==10)
m.Event("PLAYER_ENTERING_WORLD");m.Flush();assert(row.health.value==25)
assert(#a.View.rows==5 and a.Bindings.byId["targettarget"]==nil)
print("PASS target-of-target placement, fixed secure unit, change events, throttled refresh, secrets and zoning")
