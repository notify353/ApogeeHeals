local _, A = ...
function A.CheckClient()
    local version, build, _, interface = GetBuildInfo()
    local forever = (type(WOW_PROJECT_CAMELOT) == "number" and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
        or (WOW_PROJECT_ID == 1 and type(version) == "string" and version:match("^1%.60%."))
    if not forever then return false, "This client is not identified as WoW Forever." end
    for _, name in ipairs({ "issecretvalue", "canaccessvalue", "canaccesstable", "RegisterStateDriver",
        "InCombatLockdown", "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax",
        "UnitPowerType", "UnitExists", "UnitName", "UnitIsConnected", "UnitIsDeadOrGhost" }) do
        if type(_G[name]) ~= "function" then return false, "Missing client API: " .. name end
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then return false, "Missing timer API." end
    if tostring(build) ~= "70205" then
        print("Apogee Heals: unreviewed Forever build; in-game validation is required.")
    end
    return true
end
