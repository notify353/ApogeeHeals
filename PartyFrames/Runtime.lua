local _, A = ...
local R = {}
A.Runtime = R
function R.Request()
    if R.suspended or R.pending then return end
    R.pending = true
    C_Timer.After(0, function()
        R.pending = false
        if R.suspended then return end
        A.View.Refresh(); A.Buffs.Refresh(); A.Cleansing.Refresh()
    end)
end
function R.RangePolling()
    if not R.driver then return end
    R.driver:SetScript("OnUpdate", nil)
    R.rangeElapsed = 0
    A.View.RefreshRange()
    if R.suspended or A.View.unlocked or not A.Bindings.rangeSpell
        or not C_Spell or type(C_Spell.IsSpellInRange) ~= "function" then return end
    R.driver:SetScript("OnUpdate", function(_, elapsed)
        R.rangeElapsed = R.rangeElapsed + elapsed
        if R.rangeElapsed < 0.2 then return end
        R.rangeElapsed = 0
        A.View.RefreshRange()
    end)
end
function R.Start()
    local driver = CreateFrame("Frame")
    R.driver = driver
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER", "UNIT_FLAGS", "UNIT_CONNECTION", "UNIT_NAME_UPDATE",
        "UNIT_LEVEL",
        "UNIT_AURA", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
        "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_LEAVING_WORLD",
        "UNIT_HEAL_PREDICTION", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED",
        "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do driver:RegisterEvent(event) end
    driver:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
        if event:match("^UNIT_") then
            if not A.Access.Readable(unit) then return end
            if unit ~= "player" and unit ~= "party1" and unit ~= "party2"
                and unit ~= "party3" and unit ~= "party4" then return end
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            A.Buffs.OnCast(unit, spellID)
        elseif event == "GROUP_ROSTER_UPDATE" then
            A.Buffs.HideTooltip(A.Buffs.tooltipButton)
        elseif event == "PLAYER_LEAVING_WORLD" then
            R.suspended = true
            A.Buffs.suspended = true
            A.Buffs.Stop()
            R.RangePolling()
            return
        elseif event == "PLAYER_REGEN_DISABLED" then
            A.Buffs.Stop()
            A.BindingEditor.Close()
            A.View.Lock(); A.Settings.Refresh()
            -- Hide names and clear drinking immediately, before the coalesced refresh.
            for _, row in ipairs(A.View.rows) do
                row.status:SetText(""); row.name:Hide(); row.level:Hide(); row.drinkIcon:Hide()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            A.Cleansing.pending = true
            A.Bindings.Apply()
            if A.View.pendingPosition then
                A.View.pendingPosition = nil; A.View.SavePosition()
            end
            A.View.ApplyPosition(); A.Settings.Refresh()
        elseif event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            A.Cleansing.pending = true
            A.BuffDefaults.pending = true
            if event == "PLAYER_ENTERING_WORLD" then
                R.suspended, A.Buffs.suspended = nil, nil
            end
            A.Bindings.Apply()
            A.Drinking.Resolve()
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            A.View.ApplyPosition()
        end
        R.Request()
    end)
    R.RangePolling()
    R.Request()
end
