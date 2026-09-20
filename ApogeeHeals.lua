local name, A = ...
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
local function start()
    if A.started or InCombatLockdown() then return end
    A.started = true
    A.View.Create(); A.Drinking.Resolve(); A.Settings.Create(); A.Runtime.Start()
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
