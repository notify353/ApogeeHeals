local Mock = dofile("tests/mock.lua")
local cases = {
    {class="DRUID",ids={1126,467},party=2,self=2},
    {class="PRIEST",ids={1243,14752,976,588},party=3,self=4},
    {class="MAGE",ids={1459,168,7302,6117},party=1,self=4},
    {class="SHAMAN",ids={324},party=0,self=1},
    {class="WARLOCK",ids={687,706},party=0,self=2},
    {class="HUNTER",ids={19506},party=0,self=1},
    {class="WARRIOR",ids={6673,5242,6192,11549,11550,11551,25289},party=0,self=0},
    {class="ROGUE",ids={},party=0,self=0},
}
for _, case in ipairs(cases) do
    local m = Mock.New()
    m.units.player.class=case.class
    for _, unit in ipairs({"party1","party2","party3","party4","target"}) do
        m.units[unit]={class="MAGE",connected=true,dead=false,auras={},health=80,maxHealth=100}
    end
    local known={}
    for _, id in ipairs(case.ids) do known[id]=true end
    Enum.SpellBookSpellBank={Player=0}
    C_Spell.GetSpellInfo=function(id) return {spellID=id,name="Spell"..id,iconID=id} end
    C_Spell.IsSpellHelpful=function() return true end
    C_Spell.IsSpellHarmful=function() return false end
    C_Spell.IsSpellPassive=function() return false end
    C_SpellBook={IsSpellInSpellBook=function(id) return known[id]==true end,
        IsSpellKnown=function(id) return known[id]==true end}
    UnitCanAssist=function() return not m.hostile end
    UnitGroupRolesAssigned=function() return "NONE" end
    GetNumShapeshiftForms=function() return 0 end
    local a=m.Start()
    local function active(row)
        local count=0
        for _, button in ipairs(row.upkeepButtons) do
            if button.attributes.type1=="spell" then
                count=count+1
                assert(button.attributes.unit==row.unit and button.attributes.useOnKeyDown==false)
                assert(button.clicks[1]=="LeftButtonUp" and button.attributes["ctrl-type1"]=="")
                assert(button.width==a.Style.sideIconSize and button.height==a.Style.sideIconSize)
                assert(button.driver=="[combat] hide; show")
            end
        end
        return count
    end
    for index,row in ipairs(a.View.supportRows) do assert(active(row)==(index==1 and case.self or case.party)) end
    assert(not a.View.targetTarget.upkeepButtons)
    -- Catalog recognition prevents a saved generic entry from duplicating or
    -- spreading a self/area action onto party rows. Storage stays untouched.
    if case.ids[1] then
        local id=case.ids[1]
        a.db.buffs={{id=id,enabled=true,party=true}}
        a.Buffs.Refresh()
        for _,row in ipairs(a.View.supportRows) do assert(row.buffButtons[1].attributes.type1=="") end
        assert(a.db.buffs[1].party==true)
        for _,unit in pairs(m.units) do unit.auras={{spellId=id,name="Spell"..id}} end
        a.Buffs.Refresh()
        assert(active(a.View.rows[1])<case.self or case.self==0)
        for _,unit in pairs(m.units) do unit.auras={} end
        a.Buffs.Refresh()
    end
    if case.class=="WARRIOR" then
        for _, id in ipairs(case.ids) do
            a.db.buffs={{id=id,enabled=true,party=true}}
            a.Buffs.Refresh()
            for _, row in ipairs(a.View.supportRows) do
                assert(active(row)==0 and row.buffButtons[1].attributes.type1=="")
            end
            a.db.buffs={}
            a.Buffs.OnCast("player",id)
            a.Buffs.Learn({spellId=id,name="Spell"..id,duration=300,sourceUnit="player"},"player")
            assert(#a.db.buffs==0)
            assert(a.Bindings.Resolve(id)) -- The ordinary action remains available.
        end
    end
    m.hostile=true; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    assert(active(a.View.target)==0)
    m.hostile=false; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    assert(active(a.View.target)==case.party)
    m.combat=true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
    for _,row in ipairs(a.View.supportRows) do
        for _,button in ipairs(row.upkeepButtons) do
            assert(not button.icon.shown and not button.suggestion.shown)
        end
    end
    m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
    assert(active(a.View.rows[1])==case.self)
    a.View.unlocked=true; a.Buffs.Refresh(); assert(active(a.View.rows[1])==0)
    a.View.unlocked=false; a.Buffs.Refresh()
    m.Event("PLAYER_LEAVING_WORLD"); assert(active(a.View.rows[1])==0)
    m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); assert(active(a.View.rows[1])==case.self)
end
print("PASS eight-class integrated upkeep, fixed recipients, no generic duplicates, friendly-target gating and combat/preview/world recovery")
