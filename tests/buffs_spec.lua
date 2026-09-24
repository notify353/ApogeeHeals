local Mock = dofile("tests/mock.lua")
local function setup(saved)
    local m = Mock.New()
    m.units.player.class = "MAGE" -- No class-specific knowledge is needed.
    m.units.party1 = {name="Friend", health=100,maxHealth=100,power=100,maxPower=100,
        kind=0,connected=true,dead=false,auras={}}
    Enum.SpellBookSpellBank = {Player=0}
    local names = {[700001]="Test Upkeep",[700002]="Short Effect",[700003]="Test Upkeep"}
    C_Spell.GetSpellInfo = function(id)
        if names[id] then return {spellID=id,name=names[id],iconID=id} end
    end
    C_Spell.IsSpellHelpful = function() return true end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    C_SpellBook = { IsSpellInSpellBook=function(id) return names[id] ~= nil end,
        IsSpellKnown=function(id) return names[id] ~= nil end }
    local a=m.Load(); ApogeeHealsDB=saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    local function cast(id, duration, target, source)
        m.units[target or "party1"].auras={{spellId=id,name=names[id],duration=duration,sourceUnit=source or "player"}}
        m.Event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", id); m.Flush()
    end
    return m,a,cast
end
local m,a,cast=setup({version=2,position={x=-100,y=20},bindings={["2"]=700001}})
assert(a.db.version==3 and a.db.position.x==-100 and a.db.bindings["2"]==700001)
cast(700002, 299); assert(#a.db.buffs==0)
cast(700001, 600, "party1", "pet"); assert(#a.db.buffs==0)
cast(700001, m.Secret()); assert(#a.db.buffs==0)
cast(700001, 0/0); assert(#a.db.buffs==0)
cast(700001, 300)
assert(#a.db.buffs==1 and a.db.buffs[1].party and a.db.buffs[1].enabled)
assert(a.View.rows[1].buffReminders[1].shown and not a.View.rows[2].buffReminders[1].shown)
local action = a.View.rows[1].buffButtons[1]
assert(action.protected and action.attributes.unit == "player")
assert(action.attributes.type1 == "spell" and action.attributes.spell1 == 700001)
assert(action.clicks[1] == "LeftButtonUp" and action.attributes.useOnKeyDown == false)
assert(action.attributes["shift-type1"] == "" and action.driver == "[combat] hide; show")
m.units.player.auras={{spellId=700003,name="Test Upkeep",sourceUnit="party1",duration=600}}
m.Event("UNIT_AURA", "player"); m.Flush()
assert(not a.View.rows[1].buffReminders[1].shown)
assert(action.attributes.type1 == "" and action.attributes.spell1 == nil and action.driver == "hide")
m.units.player.auras={}; m.units.party1.auras={}
m.Event("UNIT_AURA", "party1"); m.Flush()
assert(a.View.rows[2].buffReminders[1].shown)
local partyAction = a.View.rows[2].buffButtons[1]
assert(partyAction.attributes.unit == "party1" and partyAction.attributes.spell1 == 700001)
a.View.SetUnlocked(true)
assert(partyAction.attributes.type1 == "" and partyAction.driver == "hide")
a.View.SetUnlocked(false)
assert(partyAction.attributes.type1 == "spell")
print("PASS class-independent five-minute learning, ownership and other-caster/rank coverage")

a.Buffs.OpenPicker()
a.Buffs.checks[1]:SetChecked(false); a.Buffs.checks[1].scripts.OnClick(a.Buffs.checks[1])
assert(not a.db.buffs[1].enabled and not a.View.rows[2].buffReminders[1].shown)
cast(700003,600)
assert(#a.db.buffs==1 and a.db.buffs[1].id==700003 and not a.db.buffs[1].enabled)
local saved=a.db
m,a,cast=setup(saved)
assert(#a.db.buffs==1 and not a.db.buffs[1].enabled)
a.db.buffs[1].enabled=true
m.units.party1.auras={{spellId=m.Secret(),name="Unknown"}}
m.Event("UNIT_AURA","party1");m.Flush()
assert(not a.View.rows[2].buffReminders[1].shown)
m.auraError=true; a.Buffs.Refresh()
assert(not a.View.rows[1].buffReminders[1].shown)
m.auraError=false; m.units.party1.auras={};a.Buffs.Refresh()
assert(a.View.rows[2].buffReminders[1].shown)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not a.View.rows[2].buffReminders[1].shown)
local reads=m.auraReads;m.Event("UNIT_AURA","party1");m.Flush();assert(m.auraReads==reads)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(a.View.rows[2].buffReminders[1].shown)
m.Event("PLAYER_LEAVING_WORLD");a.Buffs.Refresh()
assert(not a.View.rows[2].buffReminders[1].shown)
m.Event("PLAYER_ENTERING_WORLD");m.Flush();assert(a.View.rows[2].buffReminders[1].shown)
print("PASS persistent opt-out, unavailable reads, combat lock and zoning")

m,a,cast=setup()
cast(700001,600,"player")
assert(#a.db.buffs==1 and not a.db.buffs[1].party)
m.units.player.auras={};a.Buffs.Refresh()
assert(a.View.rows[1].buffReminders[1].shown and not a.View.rows[2].buffReminders[1].shown)
cast(700001,600,"party1"); assert(a.db.buffs[1].party)
m.units.party1.dead=true;a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
m.units.party1.dead=false;m.units.party1.connected=false;a.Buffs.Refresh()
assert(not a.View.rows[2].buffReminders[1].shown)
print("PASS self-only scope until party application is observed and invalid recipient suppression")

m,a,cast=setup()
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",700001)
m.time=11
m.units.party1.auras={{spellId=700001,name="Test Upkeep",duration=600,sourceUnit="player"}}
m.Flush();assert(#a.db.buffs==0)
local getter=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function() return {spellId=700001,name="Test Upkeep",duration=600,sourceUnit="player"} end
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",700001);m.Flush()
assert(#a.db.buffs==0)
C_UnitAuras.GetAuraDataByIndex=getter
m.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast",m.Secret());m.Flush()
assert(a.Storage.Open({version=4})==nil)
print("PASS candidate expiry, bounded complete-scan requirement and future-schema preservation")

-- A persisted self observation must immediately cover party-capable buffs,
-- without recasting on a party member or changing disabled preferences.
m,a,cast=setup({version=3,buffs={{id=700001,enabled=true,party=false}}})
C_Spell.IsSelfBuff=function() return false end
m.units.player.auras={{spellId=700001,name="Test Upkeep",duration=600,sourceUnit="player"}}
a.Buffs.Refresh()
assert(not a.View.rows[1].buffReminders[1].shown)
assert(a.View.rows[2].buffReminders[1].shown)
assert(a.View.rows[2].buffButtons[1].attributes.unit=="party1")
assert(a.View.rows[2].buffButtons[1].attributes.spell1==700001)
a.Buffs.OpenPicker();assert(a.Buffs.checks[1].label.text=="Test Upkeep")
C_Spell.IsSelfBuff=function() return true end
a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
C_Spell.IsSelfBuff=function() return m.Secret() end
a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
C_Spell.IsSelfBuff=function() error("unavailable") end
a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
a.db.buffs[1].party=true;a.Buffs.Refresh();assert(a.View.rows[2].buffReminders[1].shown)
C_Spell.IsSelfBuff=function() return true end
a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
C_Spell.IsSelfBuff=function() return false end
a.db.buffs[1].enabled=false;a.Buffs.Refresh();assert(not a.View.rows[2].buffReminders[1].shown)
print("PASS native self-buff classification repairs existing party scope without relearning")
