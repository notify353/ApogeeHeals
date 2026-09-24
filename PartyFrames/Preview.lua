local _, A = ...
local P = {}
A.Preview = P
-- Synthetic presentation only: never write these examples into live units or storage.
local samples = {
    { name = "Priest", class = "PRIEST", health = 85, power = 70, incoming = 10 },
    { name = "Warrior", class = "WARRIOR", health = 45, power = 60, incoming = 30, rage = true },
    { name = "Mage", class = "MAGE", health = 100, power = 35, drinking = true },
    { name = "Rogue", class = "ROGUE", health = 65, power = 80, energy = true },
    { name = "Druid", class = "DRUID", health = 25, power = 55, incoming = 20 },
}
local function smooth(value)
    return value * value * (3 - 2 * value)
end
local function render(time)
    -- Three seconds clean, two taking damage, two showing heals, three recovering,
    -- then two clean again before the loop. All arithmetic is synthetic data only.
    local depth = 0
    if time >= 3 and time < 5 then depth = smooth((time - 3) / 2)
    elseif time >= 5 and time < 7 then depth = 1
    elseif time >= 7 and time < 10 then depth = 1 - smooth((time - 7) / 3) end
    for index, sample in ipairs(samples) do
        local row = P.rows[index]
        local health = 100 - (100 - sample.health) * depth
        local power = 100 - (100 - sample.power) * depth
        row.health:SetValue(health)
        row.health:SetStatusBarColor(A.Style.HealthColor(health / 100))
        row.power:SetValue(power)
        local incoming = 0
        if time >= 5 and time < 10 then
            incoming = math.min(100 - health, (sample.incoming or 0) * math.min(1, time - 5))
        end
        row.incoming.bar:SetValue(incoming)
        row.drinkIcon:SetShown(sample.drinking == true and time >= 5 and time < 10 and power < 90)
        row:SetAlpha(1); row.name:Show(); row.level:Show(); row.status:SetText("")
        -- Demonstration only: no live range API or synthetic state in live frames.
        if index == 4 and time >= 5 and time < 8 then
            row:SetAlpha(0.45); row.name:Hide(); row.level:Hide(); row.status:SetText("OUT OF RANGE")
        elseif (index == 5 and time >= 6 and time < 9)
            or (index == 1 and time >= 7 and time < 9) then
            row.name:Hide(); row.level:Hide(); row.status:SetText(index == 5 and "OFFLINE" or "DEAD")
            row.health:SetValue(0); row.power:SetValue(0)
            row.incoming.bar:SetValue(0); row.drinkIcon:Hide()
        end
    end
end
function P.Create(anchor, buildRow)
    local root = CreateFrame("Frame", nil, UIParent)
    root:SetScale(A.Style.scale)
    root:SetSize(A.Style.width, A.Style.stackHeight)
    root:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
    root:SetFrameLevel(anchor:GetFrameLevel() + 10)
    -- Consume clicks over fictional members; never click through to live targets.
    root:EnableMouse(true)
    P.root, P.rows = root, {}
    for index, sample in ipairs(samples) do
        local row = CreateFrame("Frame", nil, root)
        row:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -(index - 1) * A.Style.rowHeight)
        buildRow(row, true, index == 1)
        row.name:SetText(sample.name); row.status:SetText(sample.status or "")
        row.level:SetText("60")
        A.UnitAPI.PaintClassColor(row.name, sample.class)
        A.UnitAPI.PaintClassStrip(row.classStrip, sample.class)
        row.drinkIcon:SetShown(sample.drinking == true)
        row.health:SetMinMaxValues(0, 100); row.health:SetValue(sample.health)
        row.health:SetStatusBarColor(A.Style.HealthColor(sample.health / 100))
        row.power:SetMinMaxValues(0, 100); row.power:SetValue(sample.power)
        row.power:SetStatusBarColor(A.Style.PowerColor(sample.rage and 1 or sample.energy and 3 or 0))
        row.incoming.bar:SetMinMaxValues(0, 100)
        row.incoming.bar:SetValue(sample.incoming or 0)
        P.rows[index] = row
    end
    render(0)
    root:Hide()
end
function P.SetShown(value)
    local shown = value == true and not InCombatLockdown()
    P.root:SetShown(shown)
    P.elapsed, P.accumulated = 0, 0
    P.root:SetScript("OnUpdate", nil)
    if shown then
        render(0)
        P.root:SetScript("OnUpdate", function(_, elapsed)
            if InCombatLockdown() then P.SetShown(false); return end
            P.elapsed = (P.elapsed + elapsed) % 12
            P.accumulated = P.accumulated + elapsed
            if P.accumulated >= 0.05 then
                P.accumulated = 0
                render(P.elapsed)
            end
        end)
    end
end
