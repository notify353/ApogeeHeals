local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP matching-export threat contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local file=assert(io.open(root.."/"..path,"rb")); local data=file:read("*a"):gsub("\r\n","\n")
    file:close(); return data
end
local function declaration(source, name)
    return assert(source:match('Name = "'..name..'",(.-)\n%s*Arguments ='))
end
local unit=read("Blizzard_APIDocumentationGenerated/UnitDocumentation.lua")
assert(declaration(unit,"UnitPowerMax"):find("SecretWhenUnitPowerMaxRestricted = true",1,true))
assert(not declaration(unit,"UnitPowerType"):find("SecretReturns",1,true))
for _,name in ipairs({"UnitDetailedThreatSituation","UnitThreatLeadSituation","UnitThreatPercentageOfLead","UnitIsUnit"}) do
    local contract=declaration(unit,name)
    assert(contract:find('SecretArguments = "AllowedWhenUntainted"',1,true))
    assert(contract:find("SecretWhenUnit",1,true))
end
assert(declaration(unit,"UnitThreatLeadSituation"):find("If the unit is not first on threat, will always return red",1,true))
assert(unit:find('LiteralName = "UNIT_THREAT_LIST_UPDATE"',1,true))
assert(unit:find('LiteralName = "UNIT_THREAT_SITUATION_UPDATE"',1,true))
assert(unit:find('LiteralName = "UNIT_MAXPOWER"',1,true))
assert(unit:find('LiteralName = "UNIT_DISPLAYPOWER"',1,true))
local events=read("Blizzard_APIDocumentationGenerated/NamePlateManagerDocumentation.lua")
assert(events:find('LiteralName = "NAME_PLATE_UNIT_ADDED"',1,true))
assert(events:find('LiteralName = "NAME_PLATE_UNIT_REMOVED"',1,true))
local curve=read("Blizzard_APIDocumentationGenerated/CurveUtilDocumentation.lua")
assert(declaration(curve,"EvaluateColorValueFromBoolean"):find('SecretArguments = "AllowedWhenTainted"',1,true))
local region=read("Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua")
assert(declaration(region,"SetAlpha"):find('SecretArguments = "AllowedWhenTainted"',1,true))
assert(declaration(region,"SetAlpha"):find("Enum.SecretAspect.Alpha",1,true))
local bar=read("Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua")
assert(declaration(bar,"SetValue"):find('SecretArguments = "AllowedWhenTainted"',1,true))
assert(declaration(bar,"SetValue"):find("Enum.SecretAspect.BarValue",1,true))
assert(declaration(bar,"SetMinMaxValues"):find('SecretArguments = "AllowedWhenTainted"',1,true))
local font=read("Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua")
assert(declaration(font,"SetFormattedText"):find('SecretArguments = "AllowedWhenTainted"',1,true))
assert(declaration(read("Blizzard_APIDocumentationGenerated/RaidMarkersDocumentation.lua"),"GetRaidTargetIndex")
    :find("SecretReturns = true",1,true))
local base=read("Blizzard_NamePlates/Blizzard_NamePlateBase.lua")
assert(base:find("function NamePlateBaseMixin:GetUnit()\n\treturn self.unitToken;\nend",1,true))
local compact=read("Blizzard_UnitFrame/Shared/CompactUnitFrame.lua")
assert(compact:find("GAINING_THREAT_COLOR, -- low and medium threat both display as",1,true))
local start=assert(compact:find("local function GetAggroHighlightThreatSituation(frame)",1,true))
local finish=assert(compact:find("\nend",start,true))
local chunk=assert(loadstring(compact:sub(start,finish+3).."\nreturn GetAggroHighlightThreatSituation"))
local state, calls=0,0
local env={UnitInParty=function() return true end, PlayerUtil={IsPlayerEffectivelyTank=function() return true end},
    UnitThreatLeadSituation=function(player,mob) assert(player=="player" and mob=="nameplate1"); calls=calls+1; return state end,
    UnitThreatSituation=function() error("DPS threat must not replace tank lead") end}
setfenv(chunk,env); local native=chunk()
for lead=0,3 do
    state=lead; assert(native({optionTable={usePlayerForAggroHighlightThreat=true},displayedUnit="nameplate1"})==lead)
end
assert(calls==4)
local unitFrame=read("Blizzard_UnitFrame/Mainline/UnitFrame.lua")
assert(unitFrame:find("local display = rawPercentage;",1,true))
assert(unitFrame:find("display = UnitThreatPercentageOfLead(indicator.feedbackUnit, indicator.unit);",1,true))
assert(unitFrame:find("if ( display and display ~= 0 ) then",1,true))
print("PASS matching-export native tank lead dispatch, warning grouping, restrictions, nameplate and alpha contracts; live engine acceptance pending")
