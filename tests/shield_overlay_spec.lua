local Mock = dofile("tests/mock.lua")
local function test(name, fn) fn(); print("PASS shield " .. name) end
local function fill(row, amount, inward)
    local out, inside = unpack(row.incoming.shields)
    assert(out.value == amount and inside.value == amount)
    assert(out.alpha == (inward and 0 or 1) and inside.alpha == (inward and 1 or 0))
end
local function clear(row)
    for _, bar in ipairs(row.incoming.shields or {}) do assert(bar.value == 0 and bar.alpha == 0) end
end
test("amount, consumption, replacement, full health, overflow and incoming heals", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    local data=m.units.player
    data.health=50; data.absorbs=20; data.incoming=10
    m.Event("UNIT_ABSORB_AMOUNT_CHANGED", "player"); m.Flush(); fill(row,20,false)
    assert(row.incoming.bar.value == 10 and row.incoming.shields[1].max == 100)
    data.absorbs=8; m.Event("UNIT_ABSORB_AMOUNT_CHANGED", "player"); m.Flush(); fill(row,8,false)
    data.health=100; m.Event("UNIT_HEALTH", "player"); m.Flush(); fill(row,8,true)
    data.health=90; data.absorbs=30; a.View.Refresh(); fill(row,30,true)
    data.health=70; a.View.Refresh(); fill(row,30,false) -- exact fit
    data.maxHealth=200; a.View.Refresh(); fill(row,30,false)
    assert(row.incoming.shields[1].max == 200)
    data.health=200; data.absorbs=250; a.View.Refresh(); fill(row,250,true) -- native bar clamps to max
    data.absorbs=0; a.View.Refresh(); fill(row,0,false)
end)
test("fixed clipped geometry, stripes, name/HoT layers and mouse pass-through", function()
    local m=Mock.New(); local a=m.Start()
    for _, row in ipairs({a.View.rows[1],a.View.target,a.View.targetTarget}) do
        local out,inside=unpack(row.incoming.shields)
        assert(row.health.clipsChildren)
        assert(out.point[2] == row.health.fill and out.point[3] == "TOPRIGHT")
        assert(inside.point[2] == row.health and inside.reverseFill)
        for _, bar in ipairs({out,inside}) do
            assert(bar.width == row.incoming.bar.width and bar.height == 14 and bar.mouse == false)
            assert(bar.level > row.incoming.bar:GetFrameLevel() and row.nameLayer.level > bar.level)
            local found=false
            for _, region in ipairs(m.frames) do
                if region.parent == bar and region.texture == "Interface\\RaidFrame\\Shield-Overlay" then
                    assert(region.horizTile and region.vertTile and region.allPoints == bar.fill)
                    found=true
                end
            end
            assert(found)
        end
    end
    assert(a.View.rows[1]:GetAttribute("type1") ~= nil)
end)
test("combat secret amounts and overflow go only to native sinks", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    local value,flag=m.Secret(),m.Secret()
    m.secretPrediction, m.secretOverflow = value,flag
    m.units.player.health,m.units.player.maxHealth=value,value
    m.combat=true; m.Event("UNIT_ABSORB_AMOUNT_CHANGED","player"); m.Flush()
    for _, bar in ipairs(row.incoming.shields) do
        assert(bar.value == value and bar.max == value and bar.alphaCondition == flag)
    end
    assert(row.incoming.shields[1].alphaYes == 0 and row.incoming.shields[2].alphaYes == 1)
end)
test("all casters, friendly targets, hostility changes and event filtering", function()
    local m=Mock.New(); local a=m.Start()
    m.units.party1={name="Friend",health=90,maxHealth=100,power=0,maxPower=100,kind=0,
        connected=true,dead=false,auras={},absorbs=25}
    m.units.target=m.units.party1; m.units.targettarget=m.units.party1
    m.Event("GROUP_ROSTER_UPDATE"); m.Event("UNIT_ABSORB_AMOUNT_CHANGED","party1"); m.Flush()
    fill(a.View.rows[2],25,true); fill(a.View.target,25,true); fill(a.View.targetTarget,25,true)
    m.units.target.absorbs=40; m.Event("UNIT_ABSORB_AMOUNT_CHANGED","target")
    fill(a.View.target,40,true); fill(a.View.targetTarget,40,true)
    m.units.target.hostile=true; m.Event("UNIT_FACTION","target"); m.Flush()
    clear(a.View.target); clear(a.View.targetTarget)
    m.Event("UNIT_ABSORB_AMOUNT_CHANGED","raid1"); assert(#m.timers == 0)
    m.units.party1=nil; m.Event("GROUP_ROSTER_UPDATE"); m.Flush(); clear(a.View.rows[2])
    m.units.target=nil; m.units.targettarget=nil; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    clear(a.View.target); clear(a.View.targetTarget)
end)
test("removal, death, disconnect, sample failure, zoning and recovery", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    m.units.player.absorbs=10; a.View.Refresh(); fill(row,10,false)
    m.absorbError=true; a.View.Refresh(); clear(row)
    m.absorbError=false; a.View.Refresh(); fill(row,10,false)
    m.predictionEmpty=true; a.View.Refresh(); fill(row,0,false)
    m.predictionEmpty=false; m.predictionError=true; a.View.Refresh(); clear(row)
    m.predictionError=false; m.units.player.dead=true; a.View.Refresh(); clear(row)
    m.units.player.dead=false; m.units.player.connected=false; a.View.Refresh(); clear(row)
    m.units.player.connected=true; a.View.Refresh(); fill(row,10,false)
    m.combat=true; m.Event("PLAYER_LEAVING_WORLD"); clear(row)
    m.Event("UNIT_ABSORB_AMOUNT_CHANGED","player"); m.Flush(); clear(row)
    m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); fill(row,10,false)
end)
test("optional absorb methods fail without suppressing health or incoming healing", function()
    for _, missing in ipairs({"GetTotalDamageAbsorbs","SetDamageAbsorbClampMode","GetDamageAbsorbs"}) do
        local m=Mock.New(); local factory=CreateUnitHealPredictionCalculator
        CreateUnitHealPredictionCalculator=function() local c=factory(); c[missing]=nil; return c end
        m.units.player.incoming=10; local a=m.Start(); local row=a.View.rows[1]
        assert(row.health.value == 80 and row.incoming.bar.value == 10 and not row.incoming.shieldsReady)
    end
    local m=Mock.New(); local create=CreateFrame
    CreateFrame=function(kind,...)
        local frame=create(kind,...)
        if kind == "StatusBar" then frame.SetAlphaFromBoolean=false end
        return frame
    end
    m.units.player.incoming=12
    local a=m.Start(); local row=a.View.rows[1]
    assert(not row.incoming.shieldsReady and row.incoming.bar.value == 12)
    clear(row)
end)
test("absorb read failure preserves incoming healing and does not add polling", function()
    local m=Mock.New(); local a=m.Start(); local row=a.View.rows[1]
    m.units.player.incoming=12; m.units.player.absorbs=10; m.absorbError=true
    for i=1,20 do m.Event("UNIT_ABSORB_AMOUNT_CHANGED","player") end
    assert(#m.timers == 1); m.Flush()
    assert(row.incoming.bar.value == 12); clear(row)
    for _, bar in ipairs(row.incoming.shields) do assert(bar.scripts.OnUpdate == nil) end
end)
