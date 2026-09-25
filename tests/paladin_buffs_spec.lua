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
assert(a.View.rows[1].buffButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].buffButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].buffButtons[1].attributes.unit=="party1")
m.known[19742]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(#a.db.buffs==2)
assert(not a.db.buffs[2].enabled)
assert(a.View.rows[1].buffButtons[1].attributes.spell1==19740)
assert(a.View.rows[2].buffButtons[1].attributes.spell1==19740)
assert(not a.View.rows[1].buffReminders[2].shown)
m.units.player.auras={{spellId=20217,name="Kings",duration=300,sourceUnit="party1"}}
a.Buffs.Refresh();assert(not a.View.rows[1].buffReminders[1].shown)
m.units.player.auras={{spellId=25916,name="Greater Might",duration=900,sourceUnit="party1"}}
a.Buffs.Refresh();assert(not a.View.rows[1].buffReminders[1].shown)
m.units.player.auras={}
a.db.buffs[1].enabled=false;a.db.buffs[2].enabled=true;a.Buffs.Refresh()
assert(a.View.rows[1].buffButtons[1].attributes.spell1==19742)
assert(a.View.rows[2].buffButtons[1].attributes.spell1==19742)
-- Existing enabled/discovered choice stays ahead of newly seeded defaults.
m,a=setup({version=3,buffs={{id=20217,enabled=true,party=true}}})
m.known[20217]=true;a.Buffs.Refresh()
assert(a.View.rows[1].buffButtons[1].attributes.spell1==20217)
print("PASS fresh Paladin seeds only learned blessings, chooses one per unit and respects existing blessings")

m,a=setup({version=3,buffs={{id=19740,enabled=false,party=false},{id=19834,enabled=true,party=true}}})
assert(#a.db.buffs==1 and a.db.buffs[1].id==19740 and not a.db.buffs[1].enabled)
m.known[19834]=true;m.known[19740]=nil;m.Event("SPELLS_CHANGED");m.Flush()
assert(#a.db.buffs==1 and a.db.buffs[1].id==19834 and not a.db.buffs[1].enabled)
assert(not a.View.rows[1].buffReminders[1].shown)
local saved=a.db;m,a=setup(saved)
assert(#a.db.buffs==1 and not a.db.buffs[1].enabled)
a.db.buffs[1].enabled=true;m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
m.units.player.auras={{spellId=19740,name="Might",duration=300,sourceUnit="player"}}
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",19740);m.Flush()
assert(#a.db.buffs==1 and a.db.buffs[1].id==19834)
assert(a.View.rows[2].buffButtons[1].attributes.spell1==19834)
print("PASS saved opt-outs survive duplicate consolidation, reload, rank upgrade and downrank casting")

m,a=setup()
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(a.db.buffs[1].id==19740 and not a.View.rows[1].buffReminders[1].shown)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(a.db.buffs[1].id==19834)
m.known[19834]=nil;m.known[19740]=nil;m.Event("SPELLS_CHANGED");m.Flush()
assert(not a.View.rows[1].buffReminders[1].shown)
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
local button=a.View.rows[2].buffButtons[1]
button.scripts.OnEnter();assert(tooltip.shown and tooltip.id==19740 and tooltip.owner==button)
button.scripts.OnLeave();assert(not tooltip.shown)
button.scripts.OnEnter();m.known[19834]=true;m.Event("SPELLS_CHANGED");m.Flush()
assert(not tooltip.shown and button.reminderSpell==19834)
button.scripts.OnEnter();assert(tooltip.id==19834)
m.Event("GROUP_ROSTER_UPDATE");m.Flush();assert(not tooltip.shown)
button.scripts.OnEnter();button.scripts.OnHide();assert(not tooltip.shown)
button.scripts.OnEnter();m.units.party1.auras={{spellId=19834,name="Might"}}
m.Event("UNIT_AURA","party1");m.Flush();assert(not tooltip.shown and not button.reminderSpell)
m.units.party1.auras={};a.Buffs.Refresh();button.scripts.OnEnter()
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");assert(not tooltip.shown)
button.scripts.OnEnter();assert(not tooltip.shown)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
tooltip.fail=true;button.scripts.OnEnter();assert(not tooltip.shown)
tooltip.fail=nil;button.scripts.OnEnter();tooltip.owner={};tooltip.shown=true
button.scripts.OnLeave();assert(tooltip.shown) -- Another UI's tooltip remains owned by that UI.
print("PASS native exact-rank tooltip handlers, recycling, aura/roster/hide/combat cleanup and ownership")
