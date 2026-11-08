local root = os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP exported native HoT contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb")); local s=f:read("*a"):gsub("\r\n","\n"); f:close(); return s
end
local function definition(source, name)
    local first=assert(source:find("function "..name,1,true))
    local last=assert(source:find("\nend",first,true))
    return source:sub(first,last+3)
end
local function execute(source, env)
    local chunk=assert(loadstring(source)); setfenv(chunk,env); return chunk()
end
local env=setmetatable({AuraContainerUtil={}, CustomAuraButtonPrivateMixin={}}, {__index=_G})
env.Enum={SecrecyLevel={NeverSecret=0}, StatusBarInterpolation={Immediate=0},
    StatusBarTimerDirection={RemainingTime=1}, CustomAuraButtonUpdateMode={Update=1}}
env.C_Secrets={GetSpellAuraSecrecy=function() return 1 end}
env.UnitIsPlayerControlledOrGroupMember=function(unit) return unit=="player" or unit:match("^party")~=nil end
local friendly=true
env.UnitCanAssist=function() return friendly end
local source=read("Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua")
execute(definition(source,"AuraContainerUtil.CanApplyIdentityCandidateFilters"),env)
execute(definition(source,"AuraContainerUtil.DoesAuraPassCandidateFilters"),env)
local filter=env.AuraContainerUtil.DoesAuraPassCandidateFilters
for _, unit in ipairs({"player","party1","party2","party3","party4","target","targettarget"}) do
    assert(filter(unit,{isHelpful=true,spellId=139},{includeSpellIDs={[139]=true}}))
    assert(not filter(unit,{isHelpful=true,spellId=17},{includeSpellIDs={[139]=true}}))
    assert(filter(unit,{isHelpful=true,spellId=774},{includeSpellIDs={[774]=true}}))
end
friendly=false
assert(not filter("target",{isHelpful=true,spellId=139},{includeSpellIDs={[139]=true}}))
assert(not filter("targettarget",{isHelpful=true,spellId=774},{includeSpellIDs={[774]=true}}))
-- Native filter dispatch receives exactly the player-only filter unchanged.
env.C_UnitAuras={IsAuraFilteredOutByInstanceID=function(unit,id,filterString)
    assert(unit=="party1" and filterString=="HELPFUL|PLAYER"); return id==2
end}
execute(definition(source,"AuraContainerUtil.ShouldIncludeAuraForFilterString"),env)
assert(env.AuraContainerUtil.ShouldIncludeAuraForFilterString("party1",{auraInstanceID=1},"HELPFUL|PLAYER"))
assert(not env.AuraContainerUtil.ShouldIncludeAuraForFilterString("party1",{auraInstanceID=2},"HELPFUL|PLAYER"))
-- Execute the exact native timer sink on application and refresh. Duration
-- objects are opaque; addon code does not calculate from restricted timestamps.
source=read("Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua")
execute(definition(source,"UnpackDisplayElement"),env)
execute(definition(source,"GetStatusBarInterpolationForUpdateMode"),env)
execute(definition(source,"CustomAuraButtonPrivateMixin:ApplyDurationBar"),env)
local bar={SetTimerDuration=function(self,duration,interpolation,direction)
    self.duration=duration; assert(interpolation==0 and direction==1)
end}
local frame={durationBar={element=bar,options={interpolation=0,direction=1}}}
for _, token in ipairs({{}, {}}) do
    setmetatable(token,{__sub=function() error("restricted arithmetic") end})
    env.CustomAuraButtonPrivateMixin.ApplyDurationBar(frame,"party1",{},token,1)
    assert(bar.duration==token)
end
env.secretwrap=function(value) return {value=value} end
env.PlayAnimationGroups=function() end; env.StopAnimationGroups=function() end
execute(definition(source,"CustomAuraButtonPrivateMixin:ApplyVisibility"),env)
frame.IsShown=function(self) return self.shown end
frame.SetShown=function(self,value) self.shown=value.value end
env.CustomAuraButtonPrivateMixin.ApplyVisibility(frame,"party1",{})
assert(frame.shown)
env.CustomAuraButtonPrivateMixin.ApplyVisibility(frame,"party1",nil)
assert(not frame.shown)
-- Three simultaneous Druid aura identities feed separate native timer sinks.
-- Refreshing/removing Regrowth must leave Rejuvenation/Wild Growth untouched.
friendly=true
local lanes, spells = {}, {774,8936,408120}
for lane, id in ipairs(spells) do
    for _, other in ipairs(spells) do
        assert(filter("party1",{isHelpful=true,spellId=other},{includeSpellIDs={[id]=true}})==(id==other))
    end
    local sink={SetTimerDuration=bar.SetTimerDuration}
    local button={durationBar={element=sink,options={interpolation=0,direction=1}},
        IsShown=frame.IsShown,SetShown=frame.SetShown}
    local token=setmetatable({}, {__sub=function() error("restricted arithmetic") end})
    env.CustomAuraButtonPrivateMixin.ApplyDurationBar(button,"party1",{},token,1)
    env.CustomAuraButtonPrivateMixin.ApplyVisibility(button,"party1",{})
    lanes[lane]={button=button,sink=sink,token=token}
end
local refreshed={}
env.CustomAuraButtonPrivateMixin.ApplyDurationBar(lanes[2].button,"party1",{},refreshed,1)
assert(lanes[2].sink.duration==refreshed)
env.CustomAuraButtonPrivateMixin.ApplyVisibility(lanes[2].button,"party1",nil)
assert(not lanes[2].button.shown)
for _, lane in ipairs({1,3}) do
    assert(lanes[lane].sink.duration==lanes[lane].token and lanes[lane].button.shown)
end
print("PASS exported native friendly HoT identity filters, player-only filter forwarding, opaque duration refresh and removal visibility; live acceptance remains separate")
