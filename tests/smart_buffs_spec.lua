local Mock = dofile("tests/mock.lua")
local function setup(class, ids, saved)
    local m = Mock.New()
    m.units.player.class = class
    m.units.party1 = {class="MAGE",connected=true,dead=false,auras={},health=100,maxHealth=100}
    m.units.party2 = {class="WARRIOR",connected=true,dead=false,auras={},health=100,maxHealth=100}
    local known = {}
    for _, id in ipairs(ids) do known[id] = true end
    Enum.SpellBookSpellBank = {Player=0}
    C_Spell.GetSpellInfo = function(id) return {spellID=id,name="Spell"..id,iconID=id} end
    C_Spell.IsSpellHelpful = function() return true end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    C_SpellBook = {IsSpellInSpellBook=function(id) return known[id]==true end,
        IsSpellKnown=function(id) return known[id]==true end}
    UnitGroupRolesAssigned = function(unit) return unit == "party2" and "TANK" or "NONE" end
    GetNumShapeshiftForms = function() return 0 end
    local a = m.Load()
    ApogeeHealsDB = saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    return m, a, known
end
local function offered(row, key, id)
    for _, button in ipairs(row[key] or {}) do
        if button.attributes.type1 == "spell" and button.attributes.spell1 == id then return button end
    end
end
local m, a, known = setup("PRIEST", {1243,14752,976,588})
local caster, tank = a.View.rows[2], a.View.rows[3]
assert(offered(caster,"upkeepButtons",1243) and offered(tank,"upkeepButtons",1243))
assert(offered(caster,"upkeepButtons",14752) and not offered(tank,"upkeepButtons",14752))
assert(not offered(caster,"upkeepButtons",976) and not offered(caster,"upkeepButtons",588))
m.units.party1.auras = {{spellId=21564,name="Prayer",sourceUnit="party2"}}
a.Buffs.Refresh()
assert(not offered(caster,"upkeepButtons",1243) and offered(caster,"upkeepButtons",14752))
assert(offered(caster,"upkeepButtons",14752).suggestion.shown)
a.Buffs.OpenPicker()
assert(#a.Buffs.preferenceRows == 4, "All learned catalog families appear without discovery casts")
local function control(key, mode)
    for _, row in ipairs(a.Buffs.preferenceRows) do
        if row.entry and row.entry.key == key then row.buttons[mode].scripts.OnClick(); return end
    end
    error("Missing preference " .. key)
end
control("spirit", "manual")
assert(not offered(caster,"upkeepButtons",14752))
a.Buffs.ToggleRecipient(caster)
assert(offered(caster,"upkeepButtons",14752) and offered(caster,"upkeepButtons",976))
assert(not offered(caster,"upkeepButtons",1243), "Expansion protects another caster's Fortitude")
control("spirit", "off")
assert(not offered(caster,"upkeepButtons",14752))
control("shadow", "smart")
a.Buffs.ToggleRecipient(caster)
assert(offered(caster,"upkeepButtons",976), "Explicit Smart enables automatic Shadow Protection")
known[10938] = true
m.Event("SPELLS_CHANGED"); m.Flush()
a.SmartBuffs.Set("fortitude", "off")
assert(not offered(tank,"upkeepButtons",10938), "Preferences apply across rank upgrades")
local saved = a.db
m, a = setup("PRIEST", {10938,14752,976}, saved)
assert(a.SmartBuffs.Mode("fortitude")=="off" and a.SmartBuffs.Mode("spirit")=="off")
assert(a.SmartBuffs.Mode("shadow")=="smart")
a.Buffs.OpenPicker()
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not a.Buffs.picker.shown)
a.SmartBuffs.Set("fortitude", "smart")
assert(a.SmartBuffs.Mode("fortitude")=="off", "Combat cannot alter preferences or secure actions")
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(not offered(a.View.rows[2],"upkeepButtons",10938))
-- Existing rank opt-outs migrate through the getter; an explicit choice supersedes them.
m,a = setup("PRIEST", {10938}, {version=3,buffs={{id=1243,enabled=false,party=true}}})
assert(a.SmartBuffs.Mode("fortitude")=="off")
a.SmartBuffs.Set("fortitude","manual");a.Buffs.ToggleRecipient(a.View.rows[2])
assert(offered(a.View.rows[2],"upkeepButtons",10938))
-- Paladin defaults must not inherit the obsolete seeded Wisdom=false choice.
m,a = setup("PALADIN", {19740,19742,20217})
assert(a.SmartBuffs.Mode("blessings")=="smart")
assert(offered(a.View.rows[2],"blessingButtons",19742).suggestion.shown)
assert(offered(a.View.rows[3],"blessingButtons",20217).suggestion.shown)
a.Buffs.OpenPicker()
assert(#a.Buffs.preferenceRows==1 and a.Buffs.preferenceRows[1].entry.key=="blessings")
a.SmartBuffs.Set("blessings","manual")
assert(not offered(a.View.rows[2],"blessingButtons",19742))
a.Buffs.ToggleRecipient(a.View.rows[2])
assert(offered(a.View.rows[2],"blessingButtons",19742))
a.SmartBuffs.Set("blessings","off")
assert(not offered(a.View.rows[2],"blessingButtons",19742))
a.SmartBuffs.Set("blessings","smart");a.Buffs.ToggleRecipient(a.View.rows[2])
m.units.party1.auras={{spellId=25898,name="Greater Kings",sourceUnit="party2"}}
a.Buffs.Refresh();assert(not offered(a.View.rows[2],"blessingButtons",19742))
-- The same modes apply to every curated class, self-only choices and mode pickers.
for _, case in ipairs({
    {"DRUID",{1126,467},"wild",1126}, {"MAGE",{1459,168,7302},"mageArmor",168},
    {"SHAMAN",{324},"lightningShield",324}, {"WARLOCK",{687,706},"demonArmor",687},
    {"HUNTER",{19506},"trueshot",19506},
}) do
    m,a=setup(case[1],case[2])
    local row=a.View.rows[1]
    a.Buffs.OpenPicker()
    a.SmartBuffs.Set(case[3],"manual");assert(not offered(row,"upkeepButtons",case[4]))
    a.Buffs.ToggleRecipient(row);assert(offered(row,"upkeepButtons",case[4]))
    a.SmartBuffs.Set(case[3],"off");assert(not offered(row,"upkeepButtons",case[4]))
    a.SmartBuffs.Set(case[3],"smart");a.Buffs.ToggleRecipient(row)
    assert(offered(row,"upkeepButtons",case[4]))
end
m,a=setup("PALADIN",{465})
GetNumShapeshiftForms=function() return 1 end
GetShapeshiftFormInfo=function() return 465,false,true,465 end
a.Buffs.Refresh();a.Buffs.OpenPicker()
assert(a.Buffs.preferenceRows[1].entry.key=="modes")
a.SmartBuffs.Set("modes","manual");assert(not offered(a.View.rows[1],"auraButtons",465))
a.Buffs.ToggleRecipient(a.View.rows[1]);assert(offered(a.View.rows[1],"auraButtons",465))
a.SmartBuffs.Set("modes","off");assert(not offered(a.View.rows[1],"auraButtons",465))
print("PASS Smart buffs: learned settings, stacking families, role guidance, manual/off expansion, migration, ranks, persistence, all classes and combat safety")
