-- Trusted exported implementations, executed separately from the addon. This
-- establishes selection/tooltip contracts, not native hit testing or taint safety.
local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP native fixed debuffs (no export)"); return end
local function read(path)
    local file=assert(io.open(root.."/"..path,"rb"))
    local data=file:read("*a"):gsub("\r\n","\n"); file:close(); return data
end
local function definition(source,name)
    local start=assert(source:find("function "..name.."(",1,true))
    return source:sub(start,assert(source:find("\nend",start,true))+3)
end
local env=setmetatable({}, {__index=_G})
local function execute(code) local f=assert(loadstring(code)); setfenv(f,env); return f() end
local shared=read("Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua")
local toc=read("Blizzard_AuraContainer/Blizzard_AuraContainer.toc")
assert(toc:find("## UseSecureEnvironment: 1",1,true))
assert(toc:find("\nBlizzard_CustomAuraContainer.lua\n",1,true))
assert(toc:find("\nBlizzard_CustomAuraButton.lua\n",1,true))
assert(toc:find("Blizzard_CustomAuraContainer.xml [LoadIntoEnvironment global]",1,true))
assert(shared:find("_G.AuraContainerSortMethod = securecopy(AuraContainerSortMethod)",1,true))
assert(shared:find("_G.AuraContainerSortDirection = securecopy(AuraContainerSortDirection)",1,true))
local containerXML=read("Blizzard_AuraContainer/Blizzard_CustomAuraContainer.xml")
local buttonXML=read("Blizzard_AuraContainer/Blizzard_CustomAuraButton.xml")
assert(containerXML:find('key="CustomAuraContainerInboundMixin" source="secure" targetPartition="public"',1,true))
assert(buttonXML:find('key="CustomAuraButtonInboundMixin" source="secure" targetPartition="public"',1,true))
for _,name in ipairs({"Blizzard_CustomAuraContainer.lua","Blizzard_CustomAuraButton.lua","Blizzard_AuraButton.lua"}) do
    assert(not read("Blizzard_AuraContainer/"..name):find("_G.",1,true), "review changes to exported mixin visibility")
end
for _,name in ipairs({"AuraContainerSortMethod","AuraContainerSortDirection","AuraContainerAuraDataType"}) do
    execute(assert(shared:match(name.." =\n%{.-\n%};")))
end
env.AuraUtil={}
execute(definition(read("Blizzard_FrameXMLUtil/AuraUtil.lua"),"AuraUtil.AuraInstanceIDOnlyAuraCompare"))
env.AuraContainerUtil={CanApplyIdentityCandidateFilters=function() return false end}
local util=read("Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua")
execute(definition(util,"AuraContainerUtil.DoesAuraPassCandidateFilters"))
local mapStart=assert(util:find("local AuraContainerSortComparators",1,true))
local comparatorStart=assert(util:find("function AuraContainerUtil.GetAuraSortComparator",mapStart,true))
execute(util:sub(mapStart,comparatorStart-1)..definition(util,"AuraContainerUtil.GetAuraSortComparator"))
env.TableUtil={Constants={AssociativePriorityTable=true}}
execute("local tRemove,tInsert=table.remove,table.insert\n"..definition(
    read("Blizzard_SharedXMLBase/TableUtil.lua"),"TableUtil.CreatePriorityTable"))
env.AuraContainerAuraSlotConstants={CandidatesChanged=true,CandidatesNotChanged=false}
env.AuraContainerAuraSlotMixin={}
local slots=read("Blizzard_AuraContainer/Blizzard_AuraContainerSlots.lua")
for _,method in ipairs({"SetCandidate","RemoveCandidate","GetPreferredAuraData","ClearCandidates","MarkDirty"}) do
    execute(definition(slots,"AuraContainerAuraSlotMixin:"..method))
end
local compare=env.AuraContainerUtil.GetAuraSortComparator(
    env.AuraContainerSortMethod.AuraInstanceIDOnly,env.AuraContainerSortDirection.Reverse)
local filter=env.AuraContainerUtil.DoesAuraPassCandidateFilters
local allTypes={Magic=true,Disease=true,Poison=true,Curse=true}
local selected
for _,kind in ipairs({"Magic","Disease","Poison","Curse","Other"}) do
    local config=kind=="Other" and {excludeDispelTypes=allTypes} or {includeDispelTypes={[kind]=true}}
    local slot=setmetatable({candidates=env.TableUtil.CreatePriorityTable(compare,true),dirtyAuraInstanceIDs={}},
        {__index=env.AuraContainerAuraSlotMixin})
    local older={auraInstanceID=100,dispelName=kind~="Other" and kind or nil,expirationTime=1000}
    local newest={auraInstanceID=102,dispelName=older.dispelName,expirationTime=10}
    local middle={auraInstanceID=101,dispelName=older.dispelName,expirationTime=100}
    for _,aura in ipairs({newest,older,middle}) do
        assert(filter("party1",aura,config)); slot:SetCandidate(aura)
    end
    assert(slot:GetPreferredAuraData()==newest, "selection must ignore expiration/scan order")
    older.expirationTime=2000; slot:SetCandidate(older)
    assert(slot:GetPreferredAuraData()==newest, "refreshing an existing instance isn't a new instance")
    slot:RemoveCandidate(102); assert(slot:GetPreferredAuraData()==middle)
    slot:RemoveCandidate(101); assert(slot:GetPreferredAuraData()==older)
    slot:ClearCandidates(); assert(not slot:GetPreferredAuraData())
    for candidate in pairs(allTypes) do
        assert(filter("party1",{dispelName=candidate},config)==(candidate==kind))
    end
    assert(filter("party1",{dispelName=""},config)==(kind=="Other"))
    assert(filter("party1",{dispelName="Bleed"},config)==(kind=="Other"))
    assert(not filter("party1",older,{includeDispelTypes={}}), "unknown cleanse must not highlight")
    selected=newest
end
env.AuraButtonPrivateMixin={}
local auraButton=read("Blizzard_AuraContainer/Blizzard_AuraButton.lua")
execute(definition(auraButton,"AuraButtonPrivateMixin:PopulateTooltip"))
selected.auraType=env.AuraContainerAuraDataType.Aura
local received
env.AuraButtonPrivateMixin.PopulateTooltip({}, {ShowAuraTooltip=function(_,unit,aura)
    assert(unit=="party1"); received=aura
end}, "party1", selected)
assert(received==selected, "native tooltip must use the selected aura, not the cleanse spell")
local input=read("Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua")
assert(input:find('Name = "SetMouseMotionEnabled"',1,true) and input:find('Name = "EnableMouse"',1,true))
local intrinsic=read("Blizzard_AuraContainer/Blizzard_AuraButton.xml")
assert(intrinsic:find('method="OnEnter_Intrinsic"',1,true))
assert(intrinsic:find('aspect="AlwaysPropagateInput"',1,true))
print("PASS retained-export newest-instance priority, refresh/removal fallback, disjoint type filters and native aura tooltip")

-- The native binding, not addon polling or arithmetic, owns countdown text.
local custom=read("Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua")
env.CustomAuraButtonSharedMixin={}; env.CustomAuraButtonPrivateMixin={}
env.Enum={SecretAspect={Text=1,Alpha=2,VertexColor=3}}
env.securecopy=function(value) assert(value==nil); return value end
env.C_AuraContainerUtil={ProcessCustomAuraButtonDurationTextOptions=function(value)
    assert(value==nil); return {}
end}
env.AuraContainerUtil.RequireObjectType=function(kind) assert(kind=="FontString"); return kind end
env.AuraContainerUtil.ValidateInboundScriptObject=function(font,parent,kind)
    assert(font.parent==parent and kind=="FontString")
end
env.AuraContainerUtil.InitializeInboundScriptObject=function(font) return font end
local formatter={}
env.addonTable={DefaultAuraDurationFormatter=formatter}
env.PackDisplayElement=function(value) return value end
execute(definition(custom,"CustomAuraButtonSharedMixin:SetDurationText"))
execute(definition(custom,"CustomAuraButtonPrivateMixin:ApplyDurationText"))
local binding={SetToDefaults=function(self) self.defaults=true end,
    SetFormatter=function(self,value) self.formatter=value end,
    SetFontString=function(self,value) self.font=value end,
    SetDuration=function(self,value) self.duration=value end,
    SetEnabled=function(self,value) self.enabled=value end}
local frame={GetDurationTextBinding=function() return binding end,
    GetAuraDuration=function() return nil end,UpdateAuraDisplay=function(self) self.updated=true end}
local font={parent=frame,aspects={},AddSecretAspect=function(self,value) self.aspects[value]=true end}
env.CustomAuraButtonSharedMixin.SetDurationText(frame,font,nil)
assert(frame.durationText==font and frame.updated and binding.font==font)
assert(binding.defaults and binding.formatter==formatter and font.aspects[1] and font.aspects[2] and font.aspects[3])
local timed={IsZero=function() return false end}
local permanent={IsZero=function() return true end}
env.CustomAuraButtonPrivateMixin.ApplyDurationText(frame,"party1",{},timed)
assert(binding.duration==timed and binding.enabled)
env.CustomAuraButtonPrivateMixin.ApplyDurationText(frame,"party1",{},permanent)
assert(binding.duration==permanent and not binding.enabled)
local replacement={IsZero=function() return false end}
env.CustomAuraButtonPrivateMixin.ApplyDurationText(frame,"party1",{},replacement)
assert(binding.duration==replacement and binding.enabled)
assert(shared:find("DefaultAuraDurationFormatter:SetDesiredUnitCount(1)",1,true))
assert(shared:find("DefaultAuraDurationFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)",1,true))
print("PASS native duration text binding, compact formatter, timed/permanent/replacement lifecycle and restricted text aspects")
