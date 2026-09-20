local _, A = ...
function A.CheckClient()
    local version, build, _, interface = GetBuildInfo()
    if WOW_PROJECT_ID ~= 1 or type(version) ~= "string"
        or not version:match("^1%.60%.") or tonumber(interface) ~= 16001 then
        return false, "Requires WoW Forever 1.60.x (interface 16001)."
    end
    for _, name in ipairs({ "issecretvalue", "canaccessvalue", "RegisterStateDriver",
        "InCombatLockdown", "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax",
        "UnitPowerType", "UnitExists", "UnitName", "UnitIsConnected", "UnitIsDeadOrGhost" }) do
        if type(_G[name]) ~= "function" then return false, "Missing client API: " .. name end
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then return false, "Missing timer API." end
    if tostring(build) ~= "69913" then
        print("Apogee Heals: unreviewed Forever build; in-game validation is required.")
    end
    return true
end
