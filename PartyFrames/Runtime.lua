local _, A = ...
local R = {}
A.Runtime = R
function R.Request()
    if R.pending then return end
    R.pending = true
    C_Timer.After(0, function() R.pending = false; A.View.Refresh() end)
end
function R.Start()
    local driver = CreateFrame("Frame")
    R.driver = driver
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER", "UNIT_FLAGS", "UNIT_CONNECTION", "UNIT_NAME_UPDATE",
        "UNIT_LEVEL",
        "UNIT_AURA", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
        "UNIT_HEAL_PREDICTION", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED",
        "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do driver:RegisterEvent(event) end
    driver:SetScript("OnEvent", function(_, event, unit)
        if event:match("^UNIT_") then
            if not A.Access.Readable(unit) then return end
            if unit ~= "player" and unit ~= "party1" and unit ~= "party2"
                and unit ~= "party3" and unit ~= "party4" then return end
        end
        if event == "PLAYER_REGEN_DISABLED" then
            A.View.Lock(); A.Settings.Refresh()
            -- Hide names and clear drinking immediately, before the coalesced refresh.
            for _, row in ipairs(A.View.rows) do
                row.status:SetText(""); row.name:Hide(); row.level:Hide(); row.drinkIcon:Hide()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if A.View.pendingPosition then
                A.View.pendingPosition = nil; A.View.SavePosition()
            end
            A.View.ApplyPosition(); A.Settings.Refresh()
        elseif event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            A.Drinking.Resolve()
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            A.View.ApplyPosition()
        end
        R.Request()
    end)
    R.Request()
end
