local Mock=dofile('tests/mock.lua')
local root=os.getenv('APOGEE_HEALS_RUNTIME_ROOT')
local name=os.getenv('APOGEE_HEALS_RUNTIME_NAME') or 'ApogeeHeals'
local era=os.getenv('APOGEE_HEALS_TEST_ERA')=='1'
local function load()
    local m=Mock.New()
    if not root then return m,m.Load() end
    C_Spell.GetSpellInfo=function(id) return {name='Heal '..id,iconID=123,spellID=id} end
    C_Spell.IsSpellHelpful=function() return true end
    C_Spell.IsSpellHarmful=function() return false end
    C_Spell.IsSpellPassive=function() return false end
    C_SpellBook={IsSpellKnown=function() return true end,IsSpellInSpellBook=function() return true end}
    Enum.SpellBookSpellBank={Player=0}
    if era then
        WOW_PROJECT_ID=2; WOW_PROJECT_CLASSIC=2
        GetBuildInfo=function() return '1.15.9','70003','',11509 end
        GetSpellBookItemInfo=function() return 'SPELL',2050 end
    end
    ApogeeUIDev=ApogeeUI
    local A={__ApogeeClient=era and 'classic-era' or nil,__ApogeeFamilyAdmission=function(n) return n==name end}
    for line in io.lines(root..'/'..name..'.toc') do
        if line:match('%.lua$') and not line:match('^__Distribution/') then assert(loadfile(root..'/'..line))(name,A) end
    end
    m.addon=A; return m,A
end
for _,stage in ipairs({'view','bindings','settings','runtime','threat','diagnostics'}) do
    local m,A=load()
    local owner,key
    if stage=='view' then owner,key=A.View,'Create'
    elseif stage=='bindings' then owner,key=A.Bindings,'Apply'
    elseif stage=='settings' then owner,key=A.Settings,'Create'
    elseif stage=='runtime' then owner,key=A.Runtime,'Start'
    elseif stage=='threat' then owner,key=A.Threat,'Start'
    else owner,key=A.ThreatDiagnostics,'Start' end
    local original=owner[key]
    owner[key]=function() original(); error('injected '..stage..' failure') end
    local saved={bindings={['1']=2050},defaultSpells={enabled=false,time=1,serial=0},position={x=12,y=34}}
    _G[name..'DB']=saved
    assert(pcall(m.Event,'ADDON_LOADED',name),'startup exception escaped: '..stage)
    assert(A.startupState=='failed' and not A.started and not ApogeeUI.components.heals)
    assert(A.db.bindings['1']==2050 and A.db.defaultSpells.enabled==false)
    local count=#m.frames
    m.Flush(); m.Event('PLAYER_REGEN_ENABLED'); m.Event('PLAYER_ENTERING_WORLD')
    assert(#m.frames==count and not A.started,'failed startup retried')
    for _,driver in pairs({A.Runtime.driver,A.Threat.frame,A.ThreatDiagnostics.frame,A.Buffs.timerDriver,
        A.EraPartyAuras and A.EraPartyAuras.driver}) do
        assert(next(driver.events)==nil and not driver.scripts.OnUpdate,'failed startup kept a driver')
    end
    if A.View.root then assert(not A.View.root:IsShown()) end
    assert(not A.ResetCharacter(),'failed component allowed a settings reset')
end
do
    local m,A=load()
    ApogeeUI.RegisterComponent=function() error('injected registration failure') end
    m.Event('ADDON_LOADED',name)
    assert(A.started and A.startupState=='active','launcher failure disabled healthy healing')
end
print('PASS Heals startup failure cleanup, saved binds and reload-only recovery')
