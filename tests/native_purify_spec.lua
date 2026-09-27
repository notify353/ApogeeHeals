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

-- Verify why composing the two intrinsic/template handlers is invalid.
-- The actual rejection is established by the live engine warning, not this test.
local intrinsic=read("Blizzard_AuraContainer/Blizzard_AuraButton.xml")
local secure=read("Blizzard_FrameXML/SecureTemplates.xml")
assert(intrinsic:find('aspect="UntrustedScriptExecution"',1,true))
assert(intrinsic:find('aspect="AlwaysPropagateInput"',1,true))
assert(intrinsic:find('method="OnClick_Intrinsic"',1,true))
assert(secure:find('function="SecureActionButton_OnClick"',1,true))
local click=definition(read("Blizzard_AuraContainer/Blizzard_AuraButton.lua"),
    "AuraButtonPrivateMixin:OnClick_Intrinsic")
assert(click:find("CancelAuraByInstanceID",1,true))
assert(click:find("CancelTemporaryEnchantment",1,true))
assert(not click:find("CastSpell",1,true))
local m,a=dofile("tests/purify_fixture.lua").New({might=true,cleanse=true})
assert(#a.View.rows==5 and #m.cleanseContainers==10 and m.xmlWarnings==0)
-- Never combine the intrinsic AuraButton with a secure action template. Instead,
-- the permanent actions are ordinary siblings of the native halo container.
for _, row in ipairs(a.View.rows) do
    for _, button in ipairs(row.cleanseButtons) do
        assert(button.parent == row and button.point[2] == row.health)
        assert(button.parent ~= row.cleanseIndicator and not button.scripts.OnClick)
    end
end
local source = read("Blizzard_FrameXML/SecureTemplates.lua")
local casts, lastID, lastUnit = 0
env.SecureButton_GetAttribute = function(frame, key) return frame.attributes[key] end
env.SecureButton_GetModifiedAttribute = function(frame, key) return frame.attributes[key .. "1"] end
env.CastSpellByID = function(id, unit) casts, lastID, lastUnit = casts + 1, id, unit end
env.CastSpellByName = function() error("lost exact spell ID") end
env.GetCVarBool = function() return true end
env.OnActionButtonPressAndHoldRelease = function() error("unexpected held action") end
local action = assert(source:match("SECURE_ACTIONS%.spell%s*=%s*(function.-\n    end);"))
local cast = execute("return " .. action, env)
env.OnActionButtonClick = function(frame, button) cast(frame, frame.attributes.unit, button) end
execute(definition(source, "SecureActionButton_ShouldUseOnKeyDown") .. "\n"
    .. definition(source, "SecureActionButton_OnClick"), env)
for _, row in ipairs(a.View.rows) do
    for index, button in ipairs(row.cleanseButtons) do
        local before = casts
        env.SecureActionButton_OnClick(button, "LeftButton", true)
        assert(casts == before)
        env.SecureActionButton_OnClick(button, "LeftButton", false)
        assert(casts == before + 1 and lastID == (index == 1 and 1152 or 4987) and lastUnit == row.unit)
    end
end
print("PASS matching-export native poison display; forbidden intrinsic composition remains absent with separate permanent actions")
