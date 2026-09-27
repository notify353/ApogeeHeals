local m,a=dofile("tests/purify_fixture.lua").New({might=true,cleanse=true})
local row=a.View.target
assert(#a.View.rows==5 and #a.View.supportRows==6)
assert(row.supportFrame.template=="SecureHandlerStateTemplate")
assert(row.supportFrame.driver=="[@target,help,nodead] show; hide")
assert(not a.View.targetTarget.supportFrame and not a.View.targetTarget.buffButtons)
assert(not row.auraButtons and not row.drinkTimer)
assert(row.debuffContainer.unit=="target" and row.cleanseIndicator.unit=="target")
assert(row.debuffContainer.parent==row.supportFrame and row.cleanseIndicator.parent==row.supportFrame)
for _,b in ipairs(row.cleanseButtons) do
    assert(b.parent==row.supportFrame and b.attributes.unit=="target" and b.attributes.type1=="spell")
    assert(not b.scripts.OnClick)
end
local refreshes=0
row.debuffContainer.UpdateAllAuras=function() refreshes=refreshes+1 end
row.cleanseIndicator.UpdateAllAuras=function() refreshes=refreshes+1 end
UnitCanAssist=function(source,unit) assert(source=="player" and unit=="target");return m.friendly end
m.units.target={name="Friendly",class="WARRIOR",connected=true,dead=false,health=100,maxHealth=100,power=0,maxPower=0,auras={}}
m.friendly=true;m.Event("PLAYER_TARGET_CHANGED");m.Flush()
assert(refreshes==2)
local choice=row.blessingButtons[1]
assert(choice.attributes.unit=="target" and choice.attributes.spell1==19740 and choice.parent==row.supportFrame)
assert(choice.suggestion.shown)
choice.scripts.OnEnter(choice);assert(GameTooltip.shown)
m.units.target.auras={{spellId=19740,name="Might"}}
m.Event("UNIT_AURA","target");m.Flush()
assert(not choice.attributes.spell1 and not GameTooltip.shown)
m.units.target.auras={};m.Event("UNIT_AURA","target");m.Flush();assert(choice.attributes.spell1==19740)
m.friendly=false;m.Event("PLAYER_TARGET_CHANGED");assert(not choice.attributes.spell1);m.Flush()
assert(not choice.icon.shown and not choice.suggestion.shown)
m.friendly=m.Secret();m.Event("UNIT_FACTION","target");m.Flush();assert(not choice.attributes.spell1)
m.friendly=true;m.units.target.dead=true;m.Event("UNIT_FLAGS","target");m.Flush();assert(not choice.attributes.spell1)
m.units.target.dead=false;m.Event("UNIT_FLAGS","target");m.Flush();assert(choice.attributes.spell1==19740)
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");assert(not choice.icon.shown)
local before=refreshes
m.friendly=false;m.Event("PLAYER_TARGET_CHANGED");m.Flush()
assert(refreshes==before+2 and row.cleanseButtons[1].attributes.unit=="target")
-- Native help/nodead driver owns combat visibility, not the Lua mock.
m.friendly=true;m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush();assert(choice.attributes.spell1==19740)
m.units.target=nil;m.Event("PLAYER_TARGET_CHANGED");m.Flush();assert(not choice.attributes.spell1)
UnitCanAssist=nil
print("PASS friendly target upkeep/cleansing/native debuffs, fixed target actions, explicit aura refresh, hostile/unknown/dead switching and combat deferral")
