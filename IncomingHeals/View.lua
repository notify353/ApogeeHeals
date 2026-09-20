local _, A = ...
local H = {}
A.IncomingHeals = H
function H.Clear(view)
    view.bar:SetMinMaxValues(0, 1)
    view.bar:SetValue(0)
end
function H.Create(health, preview)
    health:SetClipsChildren(true)
    local bar = CreateFrame("StatusBar", nil, health)
    bar:SetSize(A.Style.width, A.Style.healthHeight)
    -- Let native anchoring track the restricted fill edge; never calculate its width.
    bar:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(0.55, 0.95, 0.70, 0.65)
    bar:EnableMouse(false)
    local view = { bar = bar }
    H.Clear(view)
    if preview then return view end
    local ok, calculator = pcall(function()
        local result = CreateUnitHealPredictionCalculator()
        result:SetMaximumHealthMode(Enum.UnitMaximumHealthMode.Default)
        result:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
        result:SetIncomingHealOverflowPercent(1)
        result:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals)
        return result
    end)
    if ok then view.calculator = calculator end
    return view
end
function H.Paint(view, unit)
    if not view.calculator then H.Clear(view); return end
    local ok = pcall(function()
        -- Reset only sampled values, preserving clamp configuration.
        view.calculator:ResetPredictedValues()
        UnitGetDetailedHealPrediction(unit, nil, view.calculator)
        view.bar:SetMinMaxValues(0, view.calculator:GetMaximumHealth())
        -- Parentheses deliberately select ONLY the total, not the healer split.
        view.bar:SetValue((view.calculator:GetIncomingHeals()))
    end)
    if not ok then H.Clear(view) end
end
