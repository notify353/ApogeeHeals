local m, a = dofile("tests/runtime_fixture.lua").Start()
local deniedCalls, readableCalls = 0, 0
local function denied()
    deniedCalls = deniedCalls + 1
    error("native context denied before Lua error handler")
end
local blocked = {
    IsForbidden = function() return false end,
    CanBeAccessedInContext = function() return false end,
    GetUnit = denied,
}
local allowed = {
    CanBeAccessedInContext = function() return true end,
    GetUnit = function() readableCalls = readableCalls + 1; return "nameplate1" end,
}
local forbidden = {IsForbidden = function() return true end, GetUnit = denied}
local legacy = {IsForbidden = function() return false end,
    GetUnit = function() return "nameplate2" end}
local secretResult = {CanBeAccessedInContext = function() return m.Secret() end, GetUnit = denied}
local unknown = {CanBeAccessedInContext = function() error("unavailable") end,
    IsForbidden = function() return false end, GetUnit = denied}
C_NamePlate = {GetNamePlates = function()
    return {blocked, allowed, forbidden, legacy, secretResult, unknown, m.Secret(), m.InaccessibleTable()}
end}
m.combat = true
for i = 1, 20 do a.Threat.Discover() end
assert(deniedCalls == 0, "nameplate discovery called a context-denied frame API")
assert(readableCalls == 20 and a.Threat.exposed.nameplate1 and a.Threat.exposed.nameplate2)
-- The native access decision remains authoritative even when IsForbidden is false.
blocked.CanBeAccessedInContext = function() return true end
blocked.GetUnit = function() return "nameplate3" end
a.Threat.Discover()
assert(a.Threat.exposed.nameplate3, "accessible nameplate did not recover")
C_NamePlate.GetNamePlates = function() return m.InaccessibleTable() end
a.Threat.Discover()
C_NamePlate.GetNamePlates = function() error("unavailable") end
a.Threat.Discover()
assert(deniedCalls == 0)
print("PASS nameplate discovery skips denied/secret objects before native access and preserves allowed/legacy recovery")
