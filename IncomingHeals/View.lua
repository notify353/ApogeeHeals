local _, A = ...
local H = {}
A.IncomingHeals = H
local function clearShields(view)
    for _, bar in ipairs(view.shields or {}) do
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        bar:SetAlpha(0)
    end
end
function H.Clear(view)
    view.bar:SetMinMaxValues(0, 1)
    view.bar:SetValue(0)
    clearShields(view)
end
local function createShields(view, health, width)
    local calculator = view.calculator
    if not calculator or not Enum.UnitDamageAbsorbClampMode
        or type(calculator.SetDamageAbsorbClampMode) ~= "function"
        or type(calculator.GetDamageAbsorbs) ~= "function"
        or type(calculator.GetTotalDamageAbsorbs) ~= "function" then return end
    calculator:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealthWithoutIncomingHeals)
    view.shields = {}
    for index = 1, 2 do
        local bar = CreateFrame("StatusBar", nil, health)
        view.shields[index] = bar
        bar:SetSize(width or A.Style.width, A.Style.healthHeight)
        bar:SetFrameLevel(view.bar:GetFrameLevel() + 1)
        bar:EnableMouse(false)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(0.60, 0.85, 1, 0.48)
        bar:SetAlpha(0)
        bar:SetMinMaxValues(0, 1); bar:SetValue(0)
        if type(bar.SetAlphaFromBoolean) ~= "function" then return end
        if index == 1 then
            bar:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        else
            bar:SetPoint("TOPRIGHT", health, "TOPRIGHT", 0, 0)
            bar:SetReverseFill(true)
        end
        local stripes = bar:CreateTexture(nil, "OVERLAY")
        stripes:SetTexture("Interface\\RaidFrame\\Shield-Overlay")
        stripes:SetHorizTile(true); stripes:SetVertTile(true)
        stripes:SetAllPoints(bar:GetStatusBarTexture())
        stripes:SetVertexColor(0.75, 0.93, 1, 0.30)
    end
    view.shieldsReady = true
end
function H.Create(health, preview, width)
    health:SetClipsChildren(true)
    local bar = CreateFrame("StatusBar", nil, health)
    bar:SetSize(width or A.Style.width, A.Style.healthHeight)
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
    -- Missing optional absorb capabilities must not disable incoming healing.
    local shieldsOK = pcall(createShields, view, health, width)
    if not shieldsOK then clearShields(view) end
    return view
end
local function paintShields(view, unit)
    clearShields(view)
    if not view.shieldsReady then return end
    if unit ~= "player" and not unit:match("^party[1-4]$")
        and A.Access.Read(UnitCanAssist, "player", unit) ~= true then return end
    local calculator = view.calculator
    local maximum, total = calculator:GetMaximumHealth(), calculator:GetTotalDamageAbsorbs()
    local _, overflow = calculator:GetDamageAbsorbs()
    for _, bar in ipairs(view.shields) do
        bar:SetMinMaxValues(0, maximum)
        bar:SetValue(total)
    end
    -- Native sinks choose between fixed anchors. Never branch on secret amounts
    -- or overflow, calculate a width, or move protected frames during combat.
    -- Overflow moves the whole shield inward, retaining its correct total width.
    view.shields[1]:SetAlphaFromBoolean(overflow, 0, 1)
    view.shields[2]:SetAlphaFromBoolean(overflow, 1, 0)
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
    if not ok then H.Clear(view); return end
    local shieldsOK = pcall(paintShields, view, unit)
    if not shieldsOK then clearShields(view) end
end
