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
for _, row in ipairs(a.View.rows) do
    m.units[row.unit] = {name="Druid",class="DRUID",health=80,maxHealth=100,
        connected=true,dead=false,kind=3,power=70,maxPower=100,mana=140,maxMana=200,auras={}}
end
m.combat=true
for _, row in ipairs(a.View.rows) do
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
assert(a.View.target.manaPower==nil and a.View.targetTarget.manaPower==nil)
print("PASS druid split power: every party unit, cat/bear/caster transitions, mana updates, restricted sinks, failures, slot reuse and combat geometry")
