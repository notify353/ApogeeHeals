local Mock = dofile("tests/mock.lua")
local count = 0
local function test(name, fn) fn(); count=count+1; print("PASS " .. name) end
test("native prediction geometry and total-healer display", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    assert(row.health.clipsChildren and row.incoming.bar.mouse == false)
    assert(row.incoming.bar.point[2] == row.health.fill and row.incoming.bar.point[3] == "TOPRIGHT")
    assert(row.incoming.bar.width == 112 and row.incoming.bar.height == 14)
    assert(row.incoming.calculator.overflow == 1 and row.incoming.calculator.clampMode == 0)
    m.units.player.incoming=15
    local original=row.incoming.bar.SetValue
    row.incoming.bar.SetValue=function(self, value, ...) assert(select("#", ...) == 0); original(self, value) end
    m.Event("UNIT_HEAL_PREDICTION", "player"); m.Flush()
    assert(row.incoming.bar.value == 15 and row.incoming.bar.max == 100)
    m.units.player.incoming=50; m.Event("UNIT_HEAL_PREDICTION", "player"); m.Flush()
    assert(row.incoming.bar.value == 20) -- native missing-health clamp simulation
    m.units.player.health=100; m.Event("UNIT_HEALTH", "player"); m.Flush()
    assert(row.incoming.bar.value == 0)
end)
test("cancellation, health changes and heal absorption refresh", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    m.units.player.incoming=15; a.View.Refresh(); assert(row.incoming.bar.value == 15)
    m.units.player.healAbsorb=10; m.Event("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player"); m.Flush()
    assert(row.incoming.bar.value == 5)
    m.units.player.incoming=0; m.Event("UNIT_HEAL_PREDICTION", "player"); m.Flush()
    assert(row.incoming.bar.value == 0)
end)
test("restricted prediction values reach native sinks without arithmetic", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    local secret=m.Secret(); m.secretPrediction=secret
    m.units.player.health=secret; m.units.player.maxHealth=secret
    m.combat=true; m.Event("UNIT_HEAL_PREDICTION", "player"); m.Flush()
    assert(row.incoming.bar.value == secret and row.incoming.bar.max == secret)
end)
test("unavailable predictions and invalid unit states clear stale fills", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    m.units.player.incoming=15; a.View.Refresh(); assert(row.incoming.bar.value == 15)
    m.predictionError=true; a.View.Refresh(); assert(row.incoming.bar.value == 0)
    m.predictionError=false; a.View.Refresh(); assert(row.incoming.bar.value == 15)
    m.predictionEmpty=true; a.View.Refresh(); assert(row.incoming.bar.value == 0)
    m.predictionEmpty=false; a.View.Refresh()
    UnitHealth=function() error("unavailable health") end
    a.View.Refresh(); assert(row.incoming.bar.value == 0)
    m.units.player.dead=true; a.View.Refresh(); assert(row.incoming.bar.value == 0)
    m.units.player.connected=false; a.View.Refresh(); assert(row.incoming.bar.value == 0)
    m.units.player=nil; a.View.Refresh(); assert(row.incoming.bar.value == 0)
end)
test("optional prediction API absence leaves base frames working", function()
    local m=Mock.New(); CreateUnitHealPredictionCalculator=nil
    local a=m.Start(); assert(a.View.rows[1].health.value == 80)
    assert(a.View.rows[1].incoming.bar.value == 0)
end)
test("party prediction events coalesce and do not mutate secure frames", function()
    local m=Mock.New(); local a=m.Start()
    m.units.party1={name="Tank",health=30,maxHealth=100,power=0,maxPower=100,kind=1,connected=true,dead=false,auras={},incoming=40}
    m.combat=true; m.Event("GROUP_ROSTER_UPDATE"); m.Event("UNIT_HEAL_PREDICTION", "party1")
    assert(#m.timers == 1); m.Flush(); assert(a.View.rows[2].incoming.bar.value == 40)
    m.units.party1=nil; m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    assert(a.View.rows[2].incoming.bar.value == 0)
end)
print(count .. " incoming-heal scenarios passed")
