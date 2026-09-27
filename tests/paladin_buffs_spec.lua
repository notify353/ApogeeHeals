local Mock = dofile("tests/mock.lua")
local function setup(saved, class)
    local m = Mock.New()
    m.units.player.class = class or "PALADIN"
    m.units.party1 = {name="Friend",health=100,maxHealth=100,power=100,maxPower=100,
        kind=1,connected=true,dead=false,auras={}}
    local names = {[19740]="Might",[19834]="Might",[19742]="Wisdom",[20217]="Kings",[700001]="Other upkeep"}
    m.known = {[19740]=true}
    Enum.SpellBookSpellBank = {Player=0}
    C_Spell.GetSpellInfo = function(id)
        if names[id] then return {spellID=id,name=names[id],iconID=id} end
    end
    C_Spell.IsSpellHelpful = function() return true end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    C_Spell.IsSelfBuff = function() return false end
    C_SpellBook = {IsSpellInSpellBook=function(id) return m.known[id] == true end,
        IsSpellKnown=function(id) return m.known[id] == true end}
    local a=m.Load(); ApogeeHealsDB=saved
    m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
    return m,a
end
local m,a=setup()
assert(#a.db.buffs==1 and a.db.buffs[1].id==19740 and a.db.buffs[1].enabled)
assert(a.View.rows[1].blessingButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].blessingButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].blessingButtons[1].attributes.unit=="party1")
m.known[19742]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(#a.db.buffs==2)
assert(not a.db.buffs[2].enabled)
assert(a.View.rows[1].blessingButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].blessingButtons[1].attributes.spell1==19740)
assert(a.View.rows[1].blessingButtons[2].attributes.spell1==19742)
m.units.player.auras={{spellId=20217,name="Kings",duration=300,sourceUnit="party1"}}
a.Buffs.Refresh();assert(not a.View.rows[1].blessingButtons[1].icon.shown)
m.units.player.auras={{spellId=25916,name="Greater Might",duration=900,sourceUnit="party1"}}
a.Buffs.Refresh();assert(not a.View.rows[1].blessingButtons[1].icon.shown)
m.units.player.auras={}
a.db.buffs[1].enabled=false;a.db.buffs[2].enabled=true;a.Buffs.Refresh()
assert(a.View.rows[1].blessingButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].blessingButtons[2].attributes.spell1==19742)
-- All learned choices are offered regardless of old reminder opt-outs.
m,a=setup({version=3,buffs={{id=20217,enabled=true,party=true}}})
m.known[20217]=true;a.Buffs.Refresh()
assert(a.View.rows[1].blessingButtons[2].attributes.spell1==20217)
print("PASS fresh Paladin seeds only learned blessings, offers all learned choices per unit and respects existing blessings")

m,a=setup({version=3,buffs={{id=19740,enabled=false,party=false},{id=19834,enabled=true,party=true}}})
assert(#a.db.buffs==1 and a.db.buffs[1].id==19740 and not a.db.buffs[1].enabled)
m.known[19834]=true;m.known[19740]=nil;m.Event("SPELLS_CHANGED");m.Flush()
assert(#a.db.buffs==1 and a.db.buffs[1].id==19834 and not a.db.buffs[1].enabled)
assert(a.View.rows[1].blessingButtons[1].attributes.spell1==19834)
local saved=a.db;m,a=setup(saved)
assert(#a.db.buffs==1 and not a.db.buffs[1].enabled)
a.db.buffs[1].enabled=true;m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
m.units.player.auras={{spellId=19740,name="Might",duration=300,sourceUnit="player"}}
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",19740);m.Flush()
assert(#a.db.buffs==1 and a.db.buffs[1].id==19834)
assert(a.View.rows[2].blessingButtons[1].attributes.spell1==19834)
print("PASS saved opt-outs survive duplicate consolidation, reload, rank upgrade and downrank casting")

m,a=setup()
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(a.db.buffs[1].id==19740 and not a.View.rows[1].blessingButtons[1].icon.shown)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(a.db.buffs[1].id==19834)
m.known[19834]=nil;m.known[19740]=nil;m.Event("SPELLS_CHANGED");m.Flush()
assert(not a.View.rows[1].blessingButtons[1].icon.shown)
m.known[700001]=true;m.units.player.auras={{spellId=700001,name="Other upkeep",duration=600,sourceUnit="player"}}
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",700001);m.Flush()
assert(#a.db.buffs==2 and a.db.buffs[2].id==700001)
assert(a.View.rows[2].buffButtons[1].attributes.spell1==700001)
m,a=setup(nil,"MAGE");assert(#a.db.buffs==0)
print("PASS combat defers rank changes, unlearned spells disappear and other discovery/classes remain intact")

m,a=setup()
local tooltip={}
GameTooltip={SetOwner=function(_,button) tooltip.owner=button end,
    IsOwned=function(_,button) return tooltip.owner==button end,
    SetSpellByID=function(_,id,pet,subtext)
        assert(pet==false and subtext==true);tooltip.id=id;return not tooltip.fail
    end,
    Show=function() tooltip.shown=true end,
    Hide=function() tooltip.shown=false;tooltip.owner=nil end}
local button=a.View.rows[2].blessingButtons[1]
button.scripts.OnEnter(button);assert(tooltip.shown and tooltip.id==19740 and tooltip.owner==button)
button.scripts.OnLeave(button);assert(not tooltip.shown)
button.scripts.OnEnter(button);m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(not tooltip.shown and button.reminderSpell==19834)
button.scripts.OnEnter(button);assert(tooltip.id==19834)
m.Event("GROUP_ROSTER_UPDATE");m.Flush();assert(not tooltip.shown)
button.scripts.OnEnter(button);button.scripts.OnHide(button);assert(not tooltip.shown)
button.scripts.OnEnter(button);m.units.party1.auras={{spellId=19834,name="Might"}}
m.Event("UNIT_AURA","party1");m.Flush();assert(not tooltip.shown and not button.reminderSpell)
m.units.party1.auras={};a.Buffs.Refresh();button.scripts.OnEnter(button)
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");assert(not tooltip.shown)
button.scripts.OnEnter(button);assert(not tooltip.shown)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
tooltip.fail=true;button.scripts.OnEnter(button);assert(not tooltip.shown)
tooltip.fail=nil;button.scripts.OnEnter(button);tooltip.owner={};tooltip.shown=true
button.scripts.OnLeave(button);assert(tooltip.shown) -- Another UI's tooltip remains owned by that UI.
print("PASS native exact-rank tooltip handlers, recycling, aura/roster/hide/combat cleanup and ownership")

-- Every variant remains selectable past the old four-reminder limit.
m,a=setup()
local variants = {19740,19742,20217,1038,20911,19977,1022,1044,6940,25782,25894,25898,25895,25899,25890}
C_Spell.GetSpellInfo = function(id) return {spellID=id,name="Blessing "..id,iconID=id} end
for _,id in ipairs(variants) do m.known[id]=true end
for index=1,4 do m.units["party"..index]={connected=true,dead=false,auras={}} end
m.Event("SPELLS_CHANGED");m.Flush()
for _,row in ipairs(a.View.rows) do
    assert(#row.blessingButtons==#variants)
    for index,button in ipairs(row.blessingButtons) do
        assert(button.attributes.spell1==variants[index] and button.attributes.unit==row.unit)
        assert(button.attributes.type1=="spell" and button.attributes["shift-type1"]=="")
        assert(button.attributes.useOnKeyDown==false and button.clicks[1]=="LeftButtonUp")
        assert(button.width==a.Style.sideIconSize and not button.scripts.OnClick)
    end
end
m.units.party2.auras={{spellId=1044,name="Freedom",sourceUnit="party3"}}
a.Buffs.Refresh()
assert(a.View.rows[3].blessingButtons[1].driver=="hide")
assert(a.View.rows[2].blessingButtons[1].attributes.spell1==19740)
m.auraError=true;a.Buffs.Refresh()
for _,row in ipairs(a.View.rows) do assert(row.blessingButtons[1].driver=="hide") end
m.auraError=false;a.View.unlocked=true;a.Buffs.Refresh()
assert(a.View.rows[1].blessingButtons[1].driver=="hide")
a.View.unlocked=false;a.Buffs.Refresh()
m.Event("PLAYER_LEAVING_WORLD")
assert(a.View.rows[1].blessingButtons[1].driver=="hide")
print("PASS all blessing variants, five fixed recipients, more than four choices and unknown/preview/world cleanup")

-- Aura choices stay after all blessing choices and other upkeep reminders.
m,a=setup()
local originalInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id)
    if id==465 then return {spellID=id,name="Devotion Aura",iconID=id} end
    return originalInfo(id)
end
m.known[465]=true;m.known[700001]=true
GetNumShapeshiftForms=function() return 1 end
GetShapeshiftFormInfo=function() return 465,false,true,465 end
a.db.buffs[#a.db.buffs+1]={id=700001,enabled=true,party=true}
a.Buffs.Refresh()
local row=a.View.rows[1]
assert(row.buffButtons[1].attributes.spell1==700001)
assert(row.blessingButtons[1].point[4]==-a.Style.sideIconGap-(a.Style.sideIconSize+a.Style.sideIconGap))
assert(row.auraButtons[1].point[4]==-a.Style.sideIconGap-2*(a.Style.sideIconSize+a.Style.sideIconGap))
GetNumShapeshiftForms,GetShapeshiftFormInfo=nil,nil
print("PASS blessing/aura/upkeep geometry stays separate")
