local m,a=dofile("tests/purify_fixture.lua").New({might=true})
local row=a.View.rows[1]
for _,recipient in ipairs(a.View.supportRows) do
    local strip=recipient.buffStrip
    assert(strip.parent==recipient and strip.mouse==true)
    assert(strip.width==a.Style.classStripHitWidth and strip.height==a.Style.clusterHeight)
    assert(strip.height>a.Style.healthHeight+a.Style.barGap)
    assert(strip.point[2]==recipient and strip.point[3]=="TOPLEFT")
    assert(strip:GetFrameLevel()>recipient.nameLayer:GetFrameLevel())
    assert(not strip.template and not strip.attributes.type1)
    assert(strip.propagateMouseClicks==false)
    assert(strip.clicks[1]=="AnyDown" and strip.clicks[2]=="AnyUp")
    assert(recipient.hitRectInsets[1]==strip.width)
    assert(strip.width>=recipient.classStrip.width)
end
assert(a.View.targetTarget.hitRectInsets[1]==a.Style.classStripHitWidth,"Every unit rail excludes healing")
for _,button in ipairs({"LeftButton","RightButton","MiddleButton","Button4","Button5"}) do
    row.buffStrip.scripts.OnClick(row.buffStrip,button,true)
    assert(not a.Buffs.recipientRow,"Mouse-down never opens or casts")
    if button~="LeftButton" then
        row.buffStrip.scripts.OnClick(row.buffStrip,button,false)
        assert(not a.Buffs.recipientRow,"Non-left clicks are absorbed without opening")
    end
end
local getInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id)
    if id==19742 then return {spellID=id,name="Wisdom",iconID=135970} end
    return getInfo(id)
end
local known=C_SpellBook.IsSpellKnown
C_SpellBook.IsSpellKnown=function(id,...) return id==19742 or known(id,...) end
C_SpellBook.IsSpellInSpellBook=C_SpellBook.IsSpellKnown
m.units.player.auras={{spellId=19740,name="Might",sourceUnit="player"},{spellId=999,name="Other player's buff"}}
a.Buffs.Refresh()
assert(not row.blessingButtons or not row.blessingButtons[1].attributes.spell1)
row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
assert(a.Buffs.recipientRow==row)
assert(not row.recipientPanel and not row.recipientButtons)
local button=row.blessingButtons[1]
assert(button.attributes.unit=="player" and button.attributes.spell1==19740)
assert(button.attributes.type1=="spell" and not button.scripts.OnClick)
assert(row.blessingButtons[2].attributes.spell1==19742)
assert(row.blessingButtons[2].attributes.unit=="player")
assert(button.point[1]=="TOPRIGHT" and button.point[2]==row.health and button.point[3]=="TOPLEFT")
assert(button.driver=="[combat] hide; show")
row.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(not a.Buffs.recipientRow and not button.attributes.spell1)
row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
assert(not a.Buffs.recipientRow)
row.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(not a.Buffs.recipientRow)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(not button.attributes.spell1 and not button.icon.shown)
row.buffStrip.scripts.OnClick(nil,"LeftButton",false);m.Event("GROUP_ROSTER_UPDATE");assert(not a.Buffs.recipientRow)
UnitCanAssist=function() return true end
UnitIsPlayer=function() return true end
m.units.target={name="Friend",class="WARRIOR",connected=true,dead=false,health=100,maxHealth=100,auras={}}
m.Event("PLAYER_TARGET_CHANGED");m.Flush()
a.View.target.buffStrip.scripts.OnClick(nil,"LeftButton",false)
assert(a.Buffs.recipientRow==a.View.target)
assert(a.View.target.blessingButtons[1].attributes.unit=="target")
m.Event("PLAYER_TARGET_CHANGED");assert(not a.Buffs.recipientRow)
UnitIsPlayer=function() return false end
a.View.target.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(not a.Buffs.recipientRow)
UnitIsPlayer=function() return m.Secret() end
a.View.target.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(not a.Buffs.recipientRow)
row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
m.units.player.auras={{spellId=m.Secret(),name="Unknown"}}
a.Buffs.Refresh();assert(not a.Buffs.recipientRow)
UnitIsPlayer=nil;UnitCanAssist=nil
print("PASS buff strip expands existing left icons, recast/change, fixed recipients, toggle, combat closure and restricted observations without a panel")
