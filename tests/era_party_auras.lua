-- Also run by era_spec against the generated DEV package.
local function fixture(class)
    local m=dofile("tests/mock.lua").New()
    local runtime=os.getenv("APOGEE_ERA_RUNTIME_ROOT")
    local name=runtime and "ApogeeHealsDev" or "ApogeeHeals"
    local prefix=runtime and runtime.."/" or ""
    local a={__ApogeeClient="classic-era",__ApogeeFamilyAdmission=function(n) return n==name end}
    WOW_PROJECT_ID=2; WOW_PROJECT_CLASSIC=2
    GetBuildInfo=function() return "1.15.9","70003","",11509 end
    C_XMLUtil=nil
    Enum.SpellBookSpellBank={Player=0}
    m.units.player.class=class
    C_SpellBook={IsSpellInSpellBook=function() return true end,IsSpellKnown=function() return true end}
    C_Spell.GetSpellInfo=function(id) return {name="Spell "..id,iconID=id+100,spellID=id} end
    C_Spell.IsSpellHelpful=function() return true end
    C_Spell.IsSpellHarmful=function(id) return id==527 or id==988 end
    C_Spell.IsSpellPassive=function() return false end
    GetSpellBookItemInfo=function() return "SPELL",2050 end
    local shared=C_UnitAuras.GetAuraDataByIndex
    m.harmful={};m.reads=0
    C_UnitAuras.GetAuraDataByIndex=function(unit,index,filter)
        if filter=="HELPFUL" then return shared(unit,index,filter) end
        assert(filter=="HARMFUL");m.reads=m.reads+1
        if m.failure then error("unavailable") end
        return (m.harmful[unit] or {})[index]
    end
    GameTooltip.SetUnitAuraByAuraInstanceID=function(self,unit,id) self.unit,self.aura=unit,id;self:Show() end
    _G[name.."DB"]=nil
    for line in io.lines(prefix..(runtime and name..".toc" or name.."_Era.toc")) do
        if line:match("%.lua$") and not line:match("^__Distribution/") then assert(loadfile(prefix..line))(name,a) end
    end
    m.addon=a;m.Event("ADDON_LOADED",name);m.Flush()
    return m,a
end
for _,class in ipairs({"PRIEST","PALADIN","SHAMAN","DRUID","MAGE","WARRIOR"}) do
    local m,a=fixture(class)
    local row=a.View.rows[1]
    assert(row.eraDebuffs and #row.eraDebuffs==8,"Era party debuff slots missing without native template")
    m.harmful.player={{icon=123,dispelName="Magic",auraInstanceID=41}}
    m.Event("UNIT_AURA","player");m.Flush()
    assert(row.eraDebuffs[1].alpha==1 and row.eraDebuffs[1].icon.texture==123)
    row.eraDebuffs[1].scripts.OnEnter(row.eraDebuffs[1])
    assert(GameTooltip.unit=="player" and GameTooltip.aura==41)
    m.Event("UNIT_HEALTH","player");m.Flush()
    assert(GameTooltip.shown and GameTooltip.aura==41,"Health refresh must retain a current hovered tooltip")
    assert(row.eraDebuffs[1].mouse==false and row.eraDebuffs[1].mouseMotion==true)
    local create=CreateFrame
    CreateFrame=function(...) assert(not m.combat,"No combat construction");return create(...) end
    m.combat=true
    for _,kind in ipairs({"Magic","Poison","Disease","Curse","Bleed"}) do
        m.harmful.player={{icon=456,dispelName=kind,auraInstanceID=42}}
        m.Event("UNIT_AURA","player");m.Flush()
        assert(row.eraDebuffs[1].icon.texture==456)
        for index,button in ipairs(row.cleanseButtons or {}) do
            local expected=row.cleanseSpells[index].types[kind]==true
            assert(button.eraGlow.alpha==(expected and 1 or 0),class.." "..kind)
            assert(button.icon.desaturated==not expected)
            assert(button.attributes.unit=="player" and button.attributes.type1=="spell")
        end
    end
    m.harmful.player={};m.Event("UNIT_AURA","player");m.Flush()
    assert(row.eraDebuffs[1].alpha==0 and not GameTooltip.shown)
    for _,button in ipairs(row.cleanseButtons or {}) do assert(button.eraGlow.alpha==0) end
    for _,bad in ipairs({m.Secret(),m.InaccessibleTable(),{icon=m.Secret()}, {icon=12,dispelName=m.Secret()}}) do
        m.harmful.player={{icon=1,dispelName="Magic"},bad}
        m.Event("UNIT_AURA","player");m.Flush()
        assert(row.eraDebuffs[1].alpha==0,"Incomplete snapshot must clear")
    end
    m.failure=true;m.Event("UNIT_AURA","player");m.Flush();assert(row.eraDebuffs[1].alpha==0);m.failure=false
    m.harmful.player={}
    for i=1,64 do m.harmful.player[i]={icon=i,dispelName=i==64 and "Magic" or nil} end
    m.reads=0;m.Event("UNIT_AURA","player");m.Flush()
    assert(row.eraDebuffs[8].icon.texture==8 and m.reads==65)
    if class=="PRIEST" then assert(row.cleanseButtons[1].eraGlow.alpha==1,"Scan beyond eight displayed icons") end
    m.harmful.player[65]={icon=65};m.Event("UNIT_AURA","player");m.Flush();assert(row.eraDebuffs[1].alpha==0)
    m.combat=false;CreateFrame=create
    m.units.target={connected=true,dead=false,health=20,maxHealth=50,kind=0,power=0,maxPower=0}
    UnitIsPlayer=function() return true end;UnitCanAssist=function() return true end
    m.harmful.target={{icon=789,dispelName="Magic",auraInstanceID=99}}
    m.harmful.player={};m.Event("PLAYER_TARGET_CHANGED");m.Flush()
    assert(a.View.target.eraDebuffs[1].alpha==1)
    m.harmful.target={};m.Event("PLAYER_TARGET_CHANGED")
    assert(a.View.target.eraDebuffs[1].alpha==0,"Target change clears synchronously");m.Flush()
    m.harmful.target={{icon=789}};UnitCanAssist=function() return false end
    m.Event("UNIT_AURA","target");m.Flush();assert(a.View.target.eraDebuffs[1].alpha==0)
    m.harmful.player={{icon=123,dispelName="Magic"}};m.Event("UNIT_AURA","player");m.Flush()
    a.View.SetUnlocked(true);assert(row.eraDebuffs[1].alpha==0)
    a.View.SetUnlocked(false);m.Flush();assert(row.eraDebuffs[1].alpha==1)
    m.Event("PLAYER_LEAVING_WORLD");assert(row.eraDebuffs[1].alpha==0)
    m.Event("UNIT_AURA","player");m.Flush();assert(row.eraDebuffs[1].alpha==0)
    m.Event("PLAYER_ENTERING_WORLD");m.Flush();assert(row.eraDebuffs[1].alpha==1)
    m.units.player.dead=true;m.Event("UNIT_FLAGS","player");m.Flush();assert(row.eraDebuffs[1].alpha==0)
    m.units.player.dead=false
    C_SpellBook.IsSpellKnown=function() return false end
    a.Cleansing.pending=true;a.Cleansing.Refresh()
    for _,button in ipairs(row.cleanseButtons or {}) do
        assert(button.eraGlow.alpha==0 and button.attributes.type1=="","Unlearned actions never glow or cast")
    end
    m.units.party1={connected=true,dead=false,health=80,maxHealth=100,power=0,maxPower=0,kind=1}
    m.harmful.party1={{icon=987,dispelName="Curse"}};m.Event("GROUP_ROSTER_UPDATE");m.Flush()
    assert(a.View.rows[2].eraDebuffs[1].alpha==1)
    m.units.party1=nil;m.Event("GROUP_ROSTER_UPDATE");m.Flush()
    assert(a.View.rows[2].eraDebuffs[1].alpha==0,"Removed party slots clear")
end
print("PASS Era party debuffs and cleansing: all classes, fixed actions, combat, unknowns, cap, tooltip and lifecycle")
