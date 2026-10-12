local m,a=dofile("tests/purify_fixture.lua").New({might=true})
local getInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id)
    if id==19742 then return {spellID=id,name="Wisdom",iconID=id} end
    if id==25782 then return {spellID=id,name="Greater Might",iconID=id} end
    return getInfo(id)
end
local known=C_SpellBook.IsSpellKnown
C_SpellBook.IsSpellKnown=function(id,...) return id==19742 or known(id,...) end
C_SpellBook.IsSpellInSpellBook=C_SpellBook.IsSpellKnown
UnitCanAssist=function() return true end
UnitIsPlayer=function() return true end
m.time=100
local function offered(row, group)
    for _,button in ipairs(row.blessingButtons or {}) do
        if a.BuffDefaults.Group(button.attributes.spell1)==group then return true end
    end
end
for _,unit in ipairs({"player","party1","target"}) do
    local row=unit=="target" and a.View.target or a.View.rows[unit=="player" and 1 or 2]
    m.units[unit]={name=unit,class="PALADIN",connected=true,dead=false,health=100,maxHealth=100,auras={}}
    -- Same rank may be talent-enhanced; higher and Greater ranks are protected too.
    for _,id in ipairs({19740,19834,25782,25916,999999}) do
        local aura={spellId=id,name="Might",duration=300,expirationTime=159,sourceUnit="party2"}
        m.units[unit].auras={aura};a.Buffs.Refresh()
        assert(not offered(row,"might") and not offered(row,"wisdom"), "Foreign blessing remains coverage below two minutes")
        row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
        assert(not offered(row,"might") and offered(row,"wisdom"), "Manual alternatives must not offer a protected same-family replacement")
        local first=row.blessingButtons[1]
        assert(first.point[4]==-a.Style.sideIconGap, "Filtered options must not leave a gap")
        row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
        aura.sourceUnit=m.Secret();a.Buffs.Refresh();assert(not offered(row,"might"))
        aura.sourceUnit=nil;a.Buffs.Refresh();assert(not offered(row,"might"))
        m.units[unit].auras={};a.Buffs.Refresh();assert(offered(row,"might"))
    end
    m.units[unit].auras={{spellId=19740,name="Might",duration=300,expirationTime=159,sourceUnit="player"}}
    a.Buffs.Refresh();assert(offered(row,"might"), "Own applications still receive early refresh reminders")
    m.units[unit].auras={{spellId=999999,name="Greater Might",duration=300,expirationTime=159,sourceUnit="party2"}}
    a.Buffs.Refresh();assert(not offered(row,"might") and not offered(row,"wisdom"))
    row.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(not offered(row,"might") and offered(row,"wisdom"))
    row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
end
local groupMap={[19740]="might"}
assert(a.Buffs.NamedGroup(groupMap,999999,m.Secret())==nil,"Restricted names must not be compared or indexed")
assert(a.Buffs.NamedGroup(groupMap,999999,"Unrelated")==nil,"Unrelated effects must not suppress a buff")
UnitCanAssist=nil;UnitIsPlayer=nil
print("PASS foreign/unknown-source blessing coverage and replacement suppression across self/party/target; stronger/Greater/same-rank IDs; other choices, gap-free layout and removal recovery")
