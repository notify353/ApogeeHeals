local Mock=dofile('tests/mock.lua')
local root=os.getenv('APOGEE_HEALS_RUNTIME_ROOT')
local name=os.getenv('APOGEE_HEALS_RUNTIME_NAME') or 'ApogeeHeals'
local era=os.getenv('APOGEE_HEALS_TEST_ERA')=='1'
local function setup(class,known,saved)
    local m=Mock.New(); m.units.player.class=class
    Enum.SpellBookSpellBank={Player=0}
    Enum.ItemClass={Consumable=0}; Enum.ItemConsumableSubclass={Bandage=7}
    C_Spell.GetSpellInfo=function(id) return {name='Heal '..id,iconID=123,spellID=id} end
    C_Spell.IsSpellHelpful=function() return true end
    C_Spell.IsSpellHarmful=function() return false end
    C_Spell.IsSpellPassive=function() return false end
    C_SpellBook={IsSpellKnown=function(id) return known[id]==true end,
        IsSpellInSpellBook=function(id) return known[id]==true end}
    C_Item={GetItemInfoInstant=function(id) return id,'Consumable','Bandage','',123,0,7 end,
        GetItemNameByID=function() return 'Bandage' end}
    if era then
        WOW_PROJECT_ID=2; WOW_PROJECT_CLASSIC=2
        GetBuildInfo=function() return '1.15.9','70003','',11509 end
        GetSpellBookItemInfo=function() return 'SPELL',2050 end
    end
    local a={__ApogeeFamilyAdmission=function(n) return n==name end,
        __ApogeeClient=era and 'classic-era' or nil}
    local prefix=root and root..'/' or ''
    for line in io.lines(prefix..name..'.toc') do
        if line:match('%.lua$') and not line:match('^__Distribution/') then assert(loadfile(prefix..line))(name,a) end
    end
    _G[name..'DB']=saved or {defaultSpells={enabled=true,time=1,serial=0}}
    m.addon=a; m.Event('ADDON_LOADED',name); m.Flush()
    assert(a.db and a.View.rows[1])
    return m,a
end
local cases={{'PRIEST',2050,2053},{'PALADIN',635,25292},{'DRUID',5185,25297},{'SHAMAN',331,25357}}
for _,case in ipairs(cases) do
    local class,base,highest=unpack(case)
    local known={[base]=true,[17]=true,[90001]=true}
    local m,a=setup(class,known)
    assert(a.Bindings.Effective('1')==base and next(a.db.bindings)==nil)
    assert(a.View.rows[1].attributes.spell1==base)
    for _,slot in ipairs(a.Bindings.slots) do
        if slot.id~='1' then assert(a.BindingDefaults.Action(slot.id)==nil) end
    end
    assert(a.View.rows[1].attributes.type2=='')
    assert(a.Bindings.Put('1',90001) and a.Bindings.Put('2',17))
    known[highest]=true; m.Event('SPELLS_CHANGED')
    assert(a.View.rows[1].attributes.spell1==90001 and a.View.rows[1].attributes.spell2==17)
    -- Recreate the addon with saved manual assignments; no defaults are persisted.
    m,a=setup(class,known,a.db)
    assert(a.View.rows[1].attributes.spell1==90001 and a.View.rows[1].attributes.spell2==17)
    known[90001]=nil; m.Event('SPELLS_CHANGED')
    assert(a.View.rows[1].attributes.type1=='' and a.db.bindings['1']==90001)
    assert(a.Bindings.Put('1',nil)); assert(a.View.rows[1].attributes.spell1==highest)
    assert(a.Bindings.Put('1',{kind='item',id=1251}))
    assert(a.View.rows[1].attributes.item1=='item:1251')
    assert(a.Bindings.Put('1',nil)); assert(a.View.rows[1].attributes.spell1==highest)
    assert(a.Bindings.Put('2',nil)); assert(a.View.rows[1].attributes.type2=='')
    m.combat=true; known[highest]=nil; m.Event('SPELLS_CHANGED')
    assert(a.View.rows[1].attributes.spell1==highest and a.Bindings.pending)
    m.combat=false; m.Event('PLAYER_REGEN_ENABLED')
    assert(a.View.rows[1].attributes.spell1==base)
    a.db.defaultSpells.enabled=false; a.Bindings.Apply()
    assert(a.View.rows[1].attributes.type1=='target' and next(a.db.bindings)==nil)
end
for _,class in ipairs({'WARRIOR','ROGUE','HUNTER','MAGE','WARLOCK'}) do
    local known={[2050]=true,[635]=true,[5185]=true,[331]=true}
    local m,a=setup(class,known)
    local function checkBandage()
        local action,automatic=a.Bindings.Effective('1')
        assert(automatic and action.kind=='item' and action.id==1251)
        assert(next(a.db.bindings)==nil and not a.Bindings.rangeSpell)
        local recipients={unpack(a.View.rows)}
        recipients[#recipients+1]=a.View.target; recipients[#recipients+1]=a.View.targetTarget
        for _,row in ipairs(recipients) do
            assert(row.attributes.type1=='item' and row.attributes.item1=='item:1251')
            assert(row.attributes.unit==row.unit and row.attributes.spell1==nil and row.attributes.macrotext1==nil)
            assert(row.attributes.type2=='' and row.attributes['alt-type1']=='')
        end
        for _,slot in ipairs(a.Bindings.slots) do
            if slot.id~='1' then assert(a.BindingDefaults.Action(slot.id)==nil) end
        end
    end
    checkBandage()
    -- No bag-count/readiness dependency: native use validates supplies and skill.
    C_Item.GetItemCount=function() error('Default selection must not depend on stock') end
    a.Bindings.Apply(); checkBandage()
    a.BindingEditor.Open()
    local lines={}; GameTooltip.AddLine=function(_,line) lines[#lines+1]=line end
    a.BindingEditor.buttons['1'].scripts.OnEnter()
    assert(table.concat(lines,'\n'):find('Default: Linen Bandage.',1,true))
    assert(not a.BindingEditor.buttons['1'].remove.shown)
    -- Actual editor drop overrides the transient default, and survives reload.
    m.cursor={'item',2581,'item:2581'}
    a.BindingEditor.buttons['1'].scripts.OnReceiveDrag()
    assert(m.cursor==nil and a.View.rows[1].attributes.item1=='item:2581')
    m,a=setup(class,known,a.db)
    assert(a.db.bindings['1'].id==2581 and a.View.rows[1].attributes.item1=='item:2581')
    assert(a.Bindings.Put('1',nil)); checkBandage()
    assert(a.Bindings.Put('1',2050) and a.View.rows[1].attributes.spell1==2050)
    known[2050]=nil; m.Event('SPELLS_CHANGED')
    assert(a.db.bindings['1']==2050 and a.View.rows[1].attributes.type1=='')
    assert(a.Bindings.Put('1',nil)); checkBandage()
    -- Missing/restricted item metadata stays inactive, never targets instead.
    local instant=C_Item.GetItemInfoInstant
    C_Item.GetItemInfoInstant=function() return nil end
    m.Event('GET_ITEM_INFO_RECEIVED',1251)
    assert(a.View.rows[1].attributes.type1=='' and next(a.db.bindings)==nil)
    C_Item.GetItemInfoInstant=function() return 1251,nil,nil,nil,123,m.Secret(),7 end
    m.Event('GET_ITEM_INFO_RECEIVED',1251)
    assert(a.View.rows[1].attributes.type1=='')
    m.combat=true; m.Event('PLAYER_REGEN_DISABLED')
    C_Item.GetItemInfoInstant=instant; m.Event('GET_ITEM_INFO_RECEIVED',1251)
    assert(a.View.rows[1].attributes.type1=='' and a.Bindings.pending)
    m.combat=false; m.Event('PLAYER_REGEN_ENABLED'); checkBandage()
    a.db.defaultSpells.enabled=false; a.Bindings.Apply()
    assert(a.View.rows[1].attributes.type1=='target' and next(a.db.bindings)==nil)
    a.db.defaultSpells.enabled=true; a.Bindings.Apply(); checkBandage()
end
local m,a=setup('UNKNOWN',{})
assert(a.View.rows[1].attributes.type1=='target')
UnitClass=function() return 'Unknown',m.Secret() end
a.Bindings.Apply(); assert(a.View.rows[1].attributes.type1=='target')
print('PASS left-only defaults: four healing classes, five Linen Bandage classes, overrides/reload, no stock dependency, metadata recovery and combat deferral')
