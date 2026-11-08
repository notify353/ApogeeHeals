-- Verify the matching exported public contracts, not C++ rendering or taint.
local root=os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root=="" then print("SKIP native shield contracts (no export)"); return end
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb")); local s=f:read("*a"); f:close(); return s
end
local docs="Blizzard_APIDocumentationGenerated/"
local calc=read(docs.."UnitHealPredictionCalculatorAPIDocumentation.lua")
assert(calc:find('Environment = "All"',1,true))
for _, name in ipairs({"GetDamageAbsorbs","GetTotalDamageAbsorbs","SetDamageAbsorbClampMode","GetMaximumHealth"}) do
    assert(calc:find('Name = "'..name..'"',1,true))
end
local enums=read(docs.."UnitHealPredictionCalculatorSharedDocumentation.lua")
assert(enums:find('Name = "MissingHealthWithoutIncomingHeals"',1,true))
assert(enums:find('Incoming heals do not decrease missing health.',1,true))
local frame=read(docs.."SimpleFrameAPIDocumentation.lua")
local first=assert(frame:find('Name = "SetAlphaFromBoolean"',1,true))
local contract=frame:sub(first,first+650)
assert(contract:find('SecretArguments = "AllowedWhenTainted"',1,true))
assert(contract:find('Enum.SecretAspect.Alpha',1,true))
local unit=read(docs.."UnitDocumentation.lua")
assert(unit:find('LiteralName = "UNIT_ABSORB_AMOUNT_CHANGED"',1,true))
local status=read(docs.."SimpleStatusBarAPIDocumentation.lua")
assert(status:find('Name = "SetReverseFill"',1,true))
local texture=read(docs.."SimpleTextureBaseAPIDocumentation.lua")
for _, name in ipairs({"SetTexture","SetHorizTile","SetVertTile"}) do
    assert(texture:find('Name = "'..name..'"',1,true))
end
local native=read("Blizzard_UnitFrame/Shared/StatusBarOverlaySegment.xml")
assert(native:find('file="Interface\\RaidFrame\\Shield-Overlay" vertTile="true" horizTile="true"',1,true))
print("PASS exported public absorb calculator, secret alpha sink, event, reverse fill and native shield texture contracts; live rendering remains separate")
