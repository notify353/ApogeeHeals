local Mock=dofile("tests/mock.lua")
local m=Mock.New()
Enum.SpellBookSpellBank={Player=0}
local known={[2050]=true,[17]=true}
C_Spell.GetSpellInfo=function(id) return {name="Heal",iconID=1,spellID=id} end
C_Spell.IsSpellHelpful=function() return true end
C_Spell.IsSpellHarmful=function() return false end
C_Spell.IsSpellPassive=function() return false end
C_SpellBook={IsSpellKnown=function(id) return known[id]==true end,
    IsSpellInSpellBook=function(id) return known[id]==true end}
Enum.ItemClass={Consumable=0};Enum.ItemConsumableSubclass={Bandage=7}
C_Item={GetItemInfoInstant=function(id) return id,"Consumable","Bandage","",1,0,7 end,
    GetItemNameByID=function() return "Bandage" end}
local a=m.Start();local targets={a.View.target,a.View.targetTarget}
for _,row in ipairs(targets) do
    assert(row.attributes.spell1==2050 and row.attributes.spell2==17) -- learned Priest defaults
    assert(row.attributes.type1=="spell" and #row.clicks==5)
end
for _,slot in ipairs(a.Bindings.slots) do assert(a.Bindings.Put(slot.id,2050)) end
for _,row in ipairs(targets) do
    for _,slot in ipairs(a.Bindings.slots) do
        assert(row.attributes[slot.prefix.."type"..slot.button]=="spell")
        assert(row.attributes[slot.prefix.."spell"..slot.button]==2050)
    end
    assert(row.attributes["alt-type1"]=="" and row.attributes["ctrl-shift-type2"]=="")
end
assert(a.Bindings.Put("ctrl-5",{kind="item",id=1251}))
for _,row in ipairs(targets) do
    assert(row.attributes["ctrl-type5"]=="item" and row.attributes["ctrl-item5"]=="item:1251")
    assert(row.attributes["ctrl-spell5"]==nil)
end
m.combat=true
known[2050]=nil; a.Bindings.Apply()
assert(a.Bindings.pending and not a.Bindings.Put("1",17))
m.Event("PLAYER_TARGET_CHANGED");m.Event("UNIT_TARGET","target");m.Flush()
for _,row in ipairs(targets) do
    assert(row.attributes.spell1==2050 and row.attributes.unit==row.unit)
end
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
for _,row in ipairs(targets) do assert(row.attributes.type1=="" and row.attributes.spell1==nil) end
-- Removing unavailable overrides restores native targeting when no default is learned.
assert(a.Bindings.Put("1",nil))
for _,row in ipairs(targets) do assert(row.attributes.type1=="target" and row.attributes.unit==row.unit) end
assert(a.Bindings.Put("ctrl-5",17))
for _,row in ipairs(targets) do assert(row.attributes["ctrl-item5"]==nil and row.attributes["ctrl-spell5"]==17) end
assert(#a.View.rows==5 and a.View.target.attributes.unit=="target" and a.View.targetTarget.attributes.unit=="targettarget")
print("PASS target healing bindings: all slots, class defaults, bandages, modifiers, immutable units and combat deferral")
