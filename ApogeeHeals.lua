local name, A = ...
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
function A.ResetCharacter()
    if not A.started or not A.db or InCombatLockdown() then return false end
    A.BindingEditor.Close(); A.View.Lock(); A.Buffs.Stop()
    A.db = A.Storage.Open(nil)
    ApogeeHealsDB = A.db
    A.BuffDefaults.pending = true
    A.Settings.ResetPositions()
    A.Threat.demo = false; A.Threat.ApplyEnabled()
    A.ThreatDiagnostics.SetEnabled(false)
    A.Bindings.Apply(); A.Buffs.Refresh(); A.Settings.Refresh()
    return true
end
local function start()
    if A.started or InCombatLockdown() then return end
    A.started = true
    A.View.Create(); A.Bindings.Apply(); A.Drinking.Resolve(); A.Settings.Create(); A.Runtime.Start()
    A.Minimap.Create()
    A.Threat.Start()
    A.ThreatDiagnostics.Start()
    loader:UnregisterAllEvents()
end
loader:SetScript("OnEvent", function(_, event, loaded)
    if event == "ADDON_LOADED" then
        if loaded ~= name then return end
        loader:UnregisterEvent("ADDON_LOADED")
        local ok, reason = A.CheckClient()
        if not ok then print("Apogee Heals: " .. reason); return end
        A.db, reason = A.Storage.Open(ApogeeHealsDB)
        if not A.db then print("Apogee Heals: " .. reason); return end
        ApogeeHealsDB = A.db
        loader:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    start()
end)
