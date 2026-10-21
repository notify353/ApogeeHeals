local Mock = dofile("tests/mock.lua")
local m = Mock.New(); local a = m.Start()
UnitPower = function(unit, kind)
    local u = m.units[unit]
    if kind == 0 then
        if u.failMana then error("unavailable") end
        return u.mana
    end
    return u.power
end
UnitPowerMax = function(unit, kind)
    local u = m.units[unit]
    return kind == 0 and u.maxMana or u.maxPower
end
for _, row in ipairs({a.View.rows[1]}) do
    m.units[row.unit] = {name="Druid",class="DRUID",health=80,maxHealth=100,
        connected=true,dead=false,kind=3,power=70,maxPower=100,mana=140,maxMana=200,auras={}}
end
m.combat=true
for _, row in ipairs({a.View.rows[1]}) do
    local u=m.units[row.unit]
    local point, height=row.point,row.height
    local manaPoint, formPoint=row.manaPower.point,row.formPower.point
    assert(row.manaPower.height == a.Style.powerHeight/2)
    assert(row.formPower.height == row.manaPower.height)
    assert(manaPoint[5] - formPoint[5] == row.manaPower.height)
    assert(not row.manaPower.mouse and not row.formPower.mouse)
    for _, kind in ipairs({3,1,0,3}) do
        u.kind=kind;m.Event("UNIT_DISPLAYPOWER",row.unit);m.Flush()
        assert(row.power.alpha == (kind==0 and 1 or 0))
        assert(row.manaPower.alpha == (kind==0 and 0 or 1))
        if kind~=0 then
            assert(row.manaPower.value==140 and row.manaPower.max==200)
            assert(row.formPower.value==70)
            local r,g,b=a.Style.PowerColor(0)
            assert(row.manaPower.color[1]==r and row.manaPower.color[2]==g and row.manaPower.color[3]==b)
        end
    end
    u.mana=m.Secret();u.maxMana=m.Secret()
    m.Event("UNIT_POWER_UPDATE",row.unit,"MANA");m.Flush()
    assert(row.manaPower.value==u.mana and row.manaPower.max==u.maxMana)
    u.mana=90;u.maxMana=300;m.Event("UNIT_MAXPOWER",row.unit,"MANA");m.Flush()
    assert(row.manaPower.value==90 and row.manaPower.max==300)
    u.failMana=true;a.View.Refresh();assert(row.manaPower.value==0 and row.formPower.value==70)
    u.failMana=nil;u.mana=140;u.maxMana=200
    for _, state in ipairs({"dead","offline","missing"}) do
        if state=="dead" then u.dead=true
        elseif state=="offline" then u.dead=false;u.connected=false
        else m.units[row.unit]=nil end
        a.View.Refresh();assert(row.manaPower.alpha==0 and row.formPower.alpha==0)
        assert(row.manaPower.value==0 and row.formPower.value==0)
    end
    m.units[row.unit]=u;u.connected=true
    for _, class in ipairs({"WARRIOR","ROGUE","DRUID"}) do
        u.class=class;a.View.Refresh()
        assert(row.manaPower.alpha==(class=="DRUID" and 1 or 0))
    end
    u.class=m.Secret();a.View.Refresh();assert(row.manaPower.alpha==0)
    u.class="DRUID";u.kind=m.Secret();a.View.Refresh();assert(row.manaPower.alpha==0)
    u.kind=3;a.View.Refresh();assert(row.manaPower.alpha==1)
    assert(row.point==point and row.height==height)
    assert(row.manaPower.point==manaPoint and row.formPower.point==formPoint)
end
-- All other frames keep the active resource, even when they alias the player.
local ordinaryPower, ordinaryMax = UnitPower, UnitPowerMax
UnitIsUnit = function() return true end
for _, row in ipairs({a.View.rows[2],a.View.rows[3],a.View.rows[4],a.View.rows[5],a.View.target,a.View.targetTarget}) do
    local u={name="Druid",class="DRUID",health=80,maxHealth=100,
        connected=true,dead=false,kind=3,power=70,maxPower=100,mana=140,maxMana=200,auras={}}
    m.units[row.unit]=u
    local point,height=row.point,row.height
    for _, kind in ipairs({3,1,0,3}) do
        u.kind=kind
        UnitPower=function(unit,power)
            if unit==row.unit then assert(power==kind,"only active resource may be queried") end
            return ordinaryPower(unit,power)
        end
        UnitPowerMax=function(unit,power)
            if unit==row.unit then assert(power==kind,"no remote off-resource query") end
            return ordinaryMax(unit,power)
        end
        m.Event("UNIT_DISPLAYPOWER",row.unit);m.Flush()
        assert(row.power.alpha==1 and row.manaPower.alpha==0 and row.formPower.alpha==0)
        assert(row.power.value==(kind==0 and 140 or 70))
    end
    if row.cast then
        UnitCastingInfo=function() return "Cast" end
        UnitCastingDuration=function() return m.Secret() end
        m.Event("UNIT_SPELLCAST_START","target")
        assert(row.cast.alpha==1 and row.power.alpha==0 and row.manaPower.alpha==0)
        UnitCastingInfo=function() end;m.Event("UNIT_SPELLCAST_STOP","target")
        assert(row.cast.alpha==0 and row.power.alpha==1 and row.manaPower.alpha==0)
    end
    UnitPower,UnitPowerMax=ordinaryPower,ordinaryMax
    m.units[row.unit]=nil;a.View.Refresh()
    assert(row.power.value==0 and row.manaPower.alpha==0 and row.formPower.alpha==0)
    assert(row.point==point and row.height==height)
end
print("PASS player-only druid split; remote and self-target aliases use active power; combat, restricted sinks and cast restoration")
