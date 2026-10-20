local Mock = dofile("tests/mock.lua")
local cases = {
    {class="DRUID",ids={1126,467},party=1,self=1},
    {class="PRIEST",ids={1243,14752,976,588},party=2,self=3},
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
    UnitIsPlayer=function() return not m.targetNPC end
    UnitGroupRolesAssigned=function() return "NONE" end
    GetNumShapeshiftForms=function() return 0 end
    local a=m.Start()
    for _,row in ipairs(a.View.supportRows) do
        local strip=row.buffStrip
        assert(strip and strip.mouse and strip.propagateMouseClicks==false,case.class.." rail must consume mouse input")
        assert(row.hitRectInsets[1]==strip.width and strip.width>=row.classStrip.width)
        assert(strip.height==a.Style.clusterHeight and not strip.attributes.type1)
        strip.scripts.OnClick(strip,"LeftButton",false)
        assert(a.Buffs.recipientRow==row,case.class.." rail must toggle regardless of class/color or empty choices")
        strip.scripts.OnClick(strip,"LeftButton",false)
        assert(not a.Buffs.recipientRow)
    end
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
    m.targetNPC=true; a.Buffs.Refresh()
    assert(active(a.View.target)==0,"Friendly NPCs and pets receive no catalog buff suggestions")
    assert(active(a.View.rows[2])==case.party,"Party buff suggestions remain unchanged")
    m.targetNPC=false; a.Buffs.Refresh(); assert(active(a.View.target)==case.party)
    assert(not a.View.targetTarget.upkeepButtons)
    C_Spell.SpellHasRange=function() return true end
    C_Spell.IsSpellInRange=function() return false end
    a.Buffs.Refresh()
    assert(active(a.View.rows[1])==case.self,"Self upkeep stays available regardless of target range")
    assert(active(a.View.rows[2])==0 and active(a.View.target)==0,"Every class hides out-of-range recipient upkeep")
    a.View.target.buffStrip.scripts.OnClick(nil,"LeftButton",false);assert(active(a.View.target)==0)
    C_Spell.IsSpellInRange=function() return true end
    a.Buffs.Refresh();assert(active(a.View.target)==(case.class=="DRUID" and 2 or case.class=="PRIEST" and 3 or case.party))
    a.View.target.buffStrip.scripts.OnClick(nil,"LeftButton",false)
    C_Spell.SpellHasRange=nil;C_Spell.IsSpellInRange=nil
    if case.self > 0 then
        local id=case.ids[1]
        local groupID=({DRUID=21850,PRIEST=21564,MAGE=23028})[case.class] or id
        local function offered(row)
            for _,button in ipairs(row.upkeepButtons) do
                if button.attributes.type1=="spell" and button.attributes.spell1==id then return true end
            end
        end
        for _,row in ipairs(a.View.supportRows) do
            if row.unit=="player" or case.party>0 then
                for _,nameID in ipairs({id,groupID}) do
                    -- Simulate an unlisted rank, including differently named group buffs.
                    m.units[row.unit].auras={{spellId=999999,name="Spell"..nameID,
                        sourceUnit="party4",duration=300,expirationTime=GetTime()+59}}
                    a.Buffs.Refresh()
                    assert(not offered(row),case.class.." unlisted foreign rank must cover automatic reminders")
                    row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
                    assert(not offered(row),case.class.." unlisted foreign rank must block matching manual replacement")
                    row.buffStrip.scripts.OnClick(nil,"LeftButton",false)
                    m.units[row.unit].auras={};a.Buffs.Refresh()
                    assert(offered(row),case.class.." removal must restore reminder")
                end
            end
        end
    end
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
