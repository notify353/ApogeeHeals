local _, A = ...
local U, R = {}, A.Access.Read
A.UnitAPI = U
function U.Clear(bar)
    bar:SetMinMaxValues(0, 1); bar:SetValue(0)
    bar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
end
function U.CreateHealthCurve()
    if not C_CurveUtil or not C_CurveUtil.CreateColorCurve or not Enum
        or not Enum.LuaCurveType or not CreateColor then return nil end
    local ok, curve = pcall(function()
        local result = C_CurveUtil.CreateColorCurve()
        result:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs({ 0, 0.150001, 0.350001, 0.600001, 1 }) do
            result:AddPoint(point, CreateColor(A.Style.HealthColor(point)))
        end
        return result
    end)
    if ok then return curve end
end
function U.PaintHealth(bar, unit, curve)
    -- Native display sinks accept secrets. Do not read these values back into Lua.
    local ok = pcall(function()
        bar:SetMinMaxValues(0, UnitHealthMax(unit)); bar:SetValue(UnitHealth(unit))
    end)
    if not ok then U.Clear(bar); return false end
    local colored = curve and pcall(function()
        bar:SetStatusBarColor(UnitHealthPercent(unit, true, curve):GetRGBA())
    end)
    if not colored then bar:SetStatusBarColor(0.7, 0.7, 0.7, 1) end
    return true
end
function U.PaintPower(bar, unit)
    local kind = R(UnitPowerType, unit)
    if type(kind) ~= "number" then U.Clear(bar); return end
    local maximum = R(UnitPowerMax, unit, kind)
    if type(maximum) == "number" and maximum <= 0 then U.Clear(bar); return end
    local ok = pcall(function()
        bar:SetMinMaxValues(0, UnitPowerMax(unit, kind)); bar:SetValue(UnitPower(unit, kind))
        bar:SetStatusBarColor(A.Style.PowerColor(kind))
    end)
    if not ok then U.Clear(bar) end
end
function U.PaintClassColor(label, classToken)
    -- Always reset first so reused party slots cannot retain the previous class.
    label:SetTextColor(1, 1, 1, 1)
    if not A.Access.Readable(classToken) or type(classToken) ~= "string" then return end
    pcall(function()
        local color = C_ClassColor.GetClassColor(classToken)
        if A.Access.Readable(color) and color then label:SetTextColor(color:GetRGB()) end
    end)
end
local function hasCast(info, unit, idIndex)
    if type(info) ~= "function" then return false end
    local ok, active = pcall(function()
        local values = { info(unit) }
        -- Cast-bar IDs are documented NeverSecret; still guard before branching.
        local id = values[idIndex]
        if A.Access.Readable(id) and id ~= nil then return true end
        local name = values[1]
        return A.Access.Readable(name) and type(name) == "string" and name ~= ""
    end)
    return ok and active == true
end
function U.PaintCast(bar, unit)
    local directions = Enum and Enum.StatusBarTimerDirection
    local interpolation = Enum and Enum.StatusBarInterpolation
    if not directions or not interpolation or type(bar.SetTimerDuration) ~= "function" then return false end
    local duration, direction
    if hasCast(UnitCastingInfo, unit, 10) then
        duration, direction = UnitCastingDuration, directions.ElapsedTime
    elseif hasCast(UnitChannelInfo, unit, 11) then
        duration, direction = UnitChannelDuration, directions.RemainingTime
    end
    if type(duration) ~= "function" or direction == nil then return false end
    -- Pass the duration directly to the native timer sink; never read timestamps
    -- or do arithmetic/comparisons on restricted cast data. Failure leaves power.
    return pcall(function()
        bar:SetTimerDuration(duration(unit), interpolation.Immediate, direction)
        bar:SetStatusBarColor(0.95, 0.65, 0.20, 1)
    end)
end
function U.PaintClassStrip(strip, classToken)
    strip:SetColorTexture(unpack(A.Style.muted))
    if not A.Access.Readable(classToken) or type(classToken) ~= "string" then return end
    pcall(function()
        local color = C_ClassColor.GetClassColor(classToken)
        if A.Access.Readable(color) and color then
            local r, g, b = color:GetRGB()
            strip:SetColorTexture(r, g, b, 1)
        end
    end)
end
function U.PaintFullName(label, unit)
    label:SetText("")
    -- Unit names may be restricted in instances. Pass them straight to native
    -- text sinks; never concatenate, compare, or read back restricted text.
    local ok, name, surname = pcall(UnitName, unit)
    if not ok or (A.Access.Readable(name) and type(name) ~= "string") then return end
    -- A restricted optional surname cannot establish whether a suffix exists.
    -- Still display the name instead of blanking the entire identity.
    if not A.Access.Readable(surname) or type(surname) ~= "string" or surname == "" then
        pcall(label.SetText, label, name)
        return
    end
    local constants = Constants and Constants.CharacterNameSeparatorConsts
    local separator = constants and constants.CHARACTERNAME_SURNAME_SEPARATOR
    if not A.Access.Readable(separator) or type(separator) ~= "string" then separator = " " end
    pcall(label.SetFormattedText, label, "%s%s%s", name, separator, surname)
end
function U.PaintName(label, unit)
    local classOK, _, classToken = pcall(UnitClass, unit)
    if classOK then U.PaintClassColor(label, classToken)
    else label:SetTextColor(1, 1, 1, 1) end
    U.PaintFullName(label, unit)
end
function U.State(unit)
    if R(UnitExists, unit) ~= true then return "missing" end
    local connected, dead = R(UnitIsConnected, unit), R(UnitIsDeadOrGhost, unit)
    if connected == false then return "offline" end
    if dead == true then return "dead" end
    if connected ~= true or dead ~= false then return "unknown" end
    return "alive"
end
function U.PaintLevel(label, unit)
    local level = R(UnitLevel, unit)
    if type(level) == "number" and level > 0 then label:SetFormattedText("%d", level)
    else label:SetText("?") end
end

function U.PaintTargetIdentity(row)
    local unit = row.unit
    local player = R(UnitIsPlayer, unit)
    row.name:SetText(""); row.level:SetText("")
    row.name:SetTextColor(1, 1, 1, 1)
    row.classStrip:SetColorTexture(unpack(A.Style.muted))
    if R(UnitExists, unit) == false then return end
    U.PaintFullName(row.name, unit)
    U.PaintLevel(row.level, unit)
    if player == true then
        local ok, _, classToken = pcall(UnitClass, unit)
        if ok then U.PaintClassStrip(row.classStrip, classToken) end
    elseif player == false then
        local reaction = R(UnitReaction, unit, "player")
        if type(reaction) ~= "number" then return end
        if reaction >= 5 then row.classStrip:SetColorTexture(0.28, 0.74, 0.46, 1)
        elseif reaction == 4 then row.classStrip:SetColorTexture(0.90, 0.74, 0.22, 1)
        elseif reaction >= 1 then row.classStrip:SetColorTexture(0.86, 0.30, 0.30, 1) end
    end
end
