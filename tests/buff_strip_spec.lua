local m,a=dofile("tests/purify_fixture.lua").New({might=true})
local row=a.View.rows[1]
local getInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id)
    if id==19742 then return {spellID=id,name="Wisdom",iconID=135970} end
    return getInfo(id)
end
local known=C_SpellBook.IsSpellKnown
C_SpellBook.IsSpellKnown=function(id,...) return id==19742 or known(id,...) end
C_SpellBook.IsSpellInSpellBook=C_SpellBook.IsSpellKnown
m.units.player.auras={{spellId=19740,name="Might"},{spellId=999,name="Other player's buff"}}
a.Buffs.Refresh()
assert(not row.blessingButtons or not row.blessingButtons[1].attributes.spell1)
row.buffStrip.scripts.OnClick()
assert(a.Buffs.recipientRow==row)
assert(row.recipientCurrent.text:find("Might") and row.recipientCurrent.text:find("Other player's buff"))
local button=row.recipientButtons[1]
assert(button.attributes.unit=="player" and button.attributes.spell1==19740)
assert(button.attributes.type1=="spell" and not button.scripts.OnClick)
assert(row.recipientButtons[2].attributes.spell1==19742)
assert(row.recipientButtons[2].attributes.unit=="player")
assert(row.recipientPanel.driver=="[combat] hide")
row.buffStrip.scripts.OnClick();assert(not a.Buffs.recipientRow and row.recipientPanel.driver=="hide")
row.buffStrip.scripts.OnClick()
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
assert(not a.Buffs.recipientRow)
row.buffStrip.scripts.OnClick();assert(not a.Buffs.recipientRow)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(row.recipientPanel.driver=="hide")
row.buffStrip.scripts.OnClick();m.Event("GROUP_ROSTER_UPDATE");assert(not a.Buffs.recipientRow)
UnitCanAssist=function() return true end
UnitIsPlayer=function() return true end
m.units.target={name="Friend",class="WARRIOR",connected=true,dead=false,health=100,maxHealth=100,auras={}}
m.Event("PLAYER_TARGET_CHANGED");m.Flush()
a.View.target.buffStrip.scripts.OnClick()
assert(a.Buffs.recipientRow==a.View.target)
assert(a.View.target.recipientButtons[1].attributes.unit=="target")
m.Event("PLAYER_TARGET_CHANGED");assert(not a.Buffs.recipientRow)
UnitIsPlayer=function() return false end
a.View.target.buffStrip.scripts.OnClick();assert(not a.Buffs.recipientRow)
UnitIsPlayer=function() return m.Secret() end
a.View.target.buffStrip.scripts.OnClick();assert(not a.Buffs.recipientRow)
row.buffStrip.scripts.OnClick()
m.units.player.auras={{spellId=m.Secret(),name="Unknown"}}
a.Buffs.Refresh();assert(not a.Buffs.recipientRow)
UnitIsPlayer=nil;UnitCanAssist=nil
print("PASS buff strip recast, current buffs, fixed recipients, toggle, combat closure, roster/target changes and restricted observations")
