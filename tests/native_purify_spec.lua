local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP native Purify contracts (set APOGEE_FOREVER_EXPORT)");return end
local function read(path)
    local file=assert(io.open(root.."/"..path,"rb"))
    local data=file:read("*a"):gsub("\r\n","\n");file:close();return data
end
local function definition(source,name)
    local start=assert(source:find("function "..name,1,true))
    local finish=assert(source:find("\nend",start,true))
    return source:sub(start,finish+3)
end
local function execute(code,env)
    local chunk=assert(loadstring(code));setfenv(chunk,env);return chunk()
end
local env=setmetatable({}, {__index=_G})
env.AuraContainerUtil={CanApplyIdentityCandidateFilters=function() return false end}
execute(definition(read("Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua"),
    "AuraContainerUtil.DoesAuraPassCandidateFilters"),env)
local filter=env.AuraContainerUtil.DoesAuraPassCandidateFilters
local config={includeDispelTypes={Poison=true}}
for _,unit in ipairs({"player","party1","party2","party3","party4"}) do
    assert(filter(unit,{dispelName="Poison"},config))
    for _,kind in ipairs({"Disease","Magic","Curse",""}) do assert(not filter(unit,{dispelName=kind},config)) end
    assert(not filter(unit,{},config))
end
-- Execute the exact trusted visibility method. It passes secret-wrapped state
-- to the native sink; the addon never observes/unwraps it.
env.CustomAuraButtonPrivateMixin={}
env.secretwrap=function(value) return {nativeSecret=value} end
env.PlayAnimationGroups=function() end;env.StopAnimationGroups=function() end
execute(definition(read("Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua"),
    "CustomAuraButtonPrivateMixin:ApplyVisibility"),env)
local frame={shown=false,IsShown=function(self)return self.shown end,
    SetShown=function(self,state) assert(type(state)=="table");self.shown=state.nativeSecret end}
env.CustomAuraButtonPrivateMixin.ApplyVisibility(frame,"party1",{})
assert(frame.shown)
env.CustomAuraButtonPrivateMixin.ApplyVisibility(frame,"party1",nil)
assert(not frame.shown)

-- Exact native frame-provider ordering: public initialization happens before
-- access restrictions and initial native display. No addon script replaces it.
env.AuraContainerCustomFrameProviderMixin={}
local phase=0
local object={GetObjectTable=function(self)return self end,
    UpdateAuraDisplay=function() assert(phase==3);phase=4 end}
env.CreateFrameOutbound=function(kind,_,_,templates)
    assert(kind=="AuraButton" and templates=="CustomAuraButtonTemplate, SecureActionButtonTemplate")
    assert(phase==0);phase=1;return object
end
env.securecallfunction=function(fn,...) return fn(...) end
env.AuraContainerUtil.ApplyAccessRestrictions=function(button,flags)
    assert(button==object and phase==2 and flags=="native restrictions");phase=3
end
execute(definition(read("Blizzard_AuraContainer/Blizzard_AuraContainerFrameProviders.lua"),
    "AuraContainerCustomFrameProviderMixin:CreateFrame"),env)
local provider={ownedFrames={},availableFrames={},accessRestrictions="native restrictions",
    GetParent=function() return {} end,
    GetTemplateString=function() return "CustomAuraButtonTemplate, SecureActionButtonTemplate" end,
    initializeFrame=function(button) assert(phase==1 and button==object);phase=2 end}
env.AuraContainerCustomFrameProviderMixin.CreateFrame(provider)
assert(phase==4 and provider.ownedFrames[1]==object)
print("PASS matching-export poison-only filter, native secret visibility and initialization-before-restrictions contracts")

local m,a=dofile("tests/purify_fixture.lua").New()
local secure=read("Blizzard_FrameXML/SecureTemplates.lua")
env.SecureButton_GetAttribute=function(button,key) return button.attributes[key] end
env.SecureButton_GetModifiedAttribute=function(button,key) return button.attributes[key.."1"] end
local casts,recipient=0,nil
env.CastSpellByID=function(id,unit) assert(id==1152);casts=casts+1;recipient=unit end
env.CastSpellByName=function() error("lost exact Purify identity") end
env.TargetUnit=function() error("Purify changed selected target") end
local action=assert(secure:match("SECURE_ACTIONS%.spell%s*=%s*(function.-\n    end);"))
local cast=execute("return "..action,env)
env.OnActionButtonClick=function(button,mouse) cast(button,button.attributes.unit,mouse) end
env.OnActionButtonPressAndHoldRelease=function() error("unexpected hold") end
execute(definition(secure,"SecureActionButton_ShouldUseOnKeyDown").."\n"..
    definition(secure,"SecureActionButton_OnClick"),env)
for index,container in ipairs(m.cleanseContainers) do
    local button=container.nativeButton
    for _,keyDown in ipairs({false,true}) do
        env.GetCVarBool=function() return keyDown end
        local before=casts
        env.SecureActionButton_OnClick(button,"LeftButton",true);assert(casts==before)
        env.SecureActionButton_OnClick(button,"LeftButton",false)
        assert(casts==before+1 and recipient==a.View.rows[index].unit)
    end
end
-- These intrinsic restrictions are material. Source tests cannot prove that
-- secure-action template composition is accepted by the real input/taint engine.
local intrinsic=read("Blizzard_AuraContainer/Blizzard_AuraButton.xml")
assert(intrinsic:find('aspect="UntrustedScriptExecution"',1,true))
assert(intrinsic:find('aspect="AlwaysPropagateInput"',1,true))
print("PASS matching-export Purify release action on five fixed units; live restricted-aura/input composition still unverified")
