local name, A = ...
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
A.startupState = "pending"
local function stopFrame(frame)
    if not frame then return end
    pcall(frame.UnregisterAllEvents, frame)
    pcall(frame.SetScript, frame, "OnUpdate", nil)
    if not InCombatLockdown() then
        if type(UnregisterStateDriver) == "function" then pcall(UnregisterStateDriver,frame,"visibility") end
        pcall(frame.Hide, frame)
    end
end
local function fail(reason)
    A.started, A.startupState = false, "failed"
    A.Runtime.suspended, A.Buffs.suspended = true, true
    A.Runtime.pending, A.Bindings.pending, A.Cleansing.pending = nil, nil, nil
    loader:UnregisterAllEvents()
    pcall(A.Minimap.Unregister)
    local registry = ApogeeSettingsRegistry
    if registry and registry.defaultSpells and registry.defaultSpells.consumers then
        registry.defaultSpells.consumers[name] = nil
    end
    -- Each owned driver/root is independent: a broken cleanup cannot skip others.
    for _, frame in pairs({A.Runtime.driver,A.Threat.frame,A.ThreatDiagnostics.frame,
        A.View.root,A.View.handle,A.Preview.root,A.BindingEditor.frame,
        A.ThreatView.root,A.ThreatDiagnostics.root,A.Buffs.timerDriver,
        A.EraPartyAuras and A.EraPartyAuras.driver}) do stopFrame(frame) end
    for _, row in pairs(A.View.rows or {}) do stopFrame(row) end
    stopFrame(A.View.target); stopFrame(A.View.targetTarget)
    pcall(A.Buffs.Stop)
    pcall(A.Settings.Refresh)
    print("Apogee Heals: initialization failed; reload to recover. " .. tostring(reason))
end
function A.ResetCharacter()
    if not A.started or not A.db or InCombatLockdown() then return false end
    A.BindingEditor.Close(); A.View.Lock(); A.Buffs.Stop()
    local defaultSpells = A.db.defaultSpells
    A.db = A.Storage.Open(nil)
    A.db.defaultSpells = defaultSpells
    ApogeeHealsDB = A.db
    A.BuffDefaults.pending = true
    A.Settings.ResetPositions()
    A.Threat.demo = false; A.Threat.ApplyEnabled()
    A.ThreatDiagnostics.SetEnabled(false)
    A.Bindings.Apply(); A.Buffs.Refresh(); A.Settings.Refresh()
    return true
end
local function start()
    if A.startupState ~= "pending" or InCombatLockdown() then return end
    A.startupState = "initializing"
    local ok, err = pcall(function()
        A.View.Create(); A.Bindings.Apply(); A.Drinking.Resolve(); A.Settings.Create(); A.Runtime.Start()
        A.Threat.Start(); A.ThreatDiagnostics.Start()
    end)
    if not ok then fail(err); return end
    A.started, A.startupState = true, "active"
    -- Presentation failures must not tear down healthy healing behavior.
    pcall(A.Minimap.Create)
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
