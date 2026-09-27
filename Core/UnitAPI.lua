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
function U.PaintName(label, unit)
    local classOK, _, classToken = pcall(UnitClass, unit)
    if classOK then U.PaintClassColor(label, classToken)
    else label:SetTextColor(1, 1, 1, 1) end
    -- Only shorten readable names; never inspect a restricted identity.
    local name = R(UnitName, unit)
    if type(name) ~= "string" then label:SetText(""); return end
    local separators = Constants and Constants.CharacterNameSeparatorConsts
    local separator = separators and separators.CHARACTERNAME_SURNAME_SEPARATOR
    if type(separator) == "string" and separator ~= "" then
        local index = name:find(separator, 1, true)
        if index then name = name:sub(1, index - 1) end
    end
    label:SetText(name:match("^[^%s%-]+") or "")
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
    local player = R(UnitIsPlayer, "target")
    local font, _, flags = row.name:GetFont()
    row.name:SetFont(font, player == false and 6 or 8, flags)
    row.name:SetText(""); row.level:SetText("")
    row.name:SetTextColor(1, 1, 1, 1)
    row.classStrip:SetColorTexture(unpack(A.Style.muted))
    if R(UnitExists, "target") == false then return end
    -- UnitName separates the realm in its second return. Preserve the entire
    -- first return, including spaces, NPC titles and character surnames.
    local name = R(UnitName, "target")
    if type(name) == "string" then row.name:SetText(name) end
    U.PaintLevel(row.level, "target")
    if player == true then
        local ok, _, classToken = pcall(UnitClass, "target")
        if ok then U.PaintClassStrip(row.classStrip, classToken) end
    elseif player == false then
        local reaction = R(UnitReaction, "target", "player")
        if type(reaction) ~= "number" then return end
        if reaction >= 5 then row.classStrip:SetColorTexture(0.28, 0.74, 0.46, 1)
        elseif reaction == 4 then row.classStrip:SetColorTexture(0.90, 0.74, 0.22, 1)
        elseif reaction >= 1 then row.classStrip:SetColorTexture(0.86, 0.30, 0.30, 1) end
    end
end
