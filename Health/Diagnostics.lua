local _, A = ...
local D = {enabled=false, elapsed=0, rows={}, previous={}}
A.HealthDiagnostics = D
local units = {"player", "party1", "party2", "party3", "party4"}
local tracked = {player=true, party1=true, party2=true, party3=true, party4=true}

-- Never retain API values. Only public outcomes, counters and a threshold
-- boolean survive a sample. Permission checks precede even type inspection.
local function read(fn, ...)
    if type(fn) ~= "function" then return "Unavailable" end
    local ok, value = pcall(fn, ...)
    if not ok then return "Unavailable" end
    if not A.Access.Readable(value) then return "Restricted" end
    return "Readable", value
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function observe(unit)
    local status, value = read(UnitInRaid, "player")
    if status ~= "Readable" then return status end
    if value ~= nil then
        if not finite(value) or value < 1 then return "Unavailable" end
        return "Skipped"
    end
    for _, check in ipairs({{UnitExists, true}, {UnitIsConnected, true}, {UnitIsDeadOrGhost, false}}) do
        status, value = read(check[1], unit)
        if status ~= "Readable" then return status end
        if type(value) ~= "boolean" then return "Unavailable" end
        if value ~= check[2] then return "Skipped" end
    end
    -- Request actual current health, not predicted health.
    local healthStatus, health = read(UnitHealth, unit, false)
    local maxStatus, maximum = read(UnitHealthMax, unit)
    if healthStatus == "Restricted" or maxStatus == "Restricted" then return "Restricted" end
    if healthStatus ~= "Readable" or maxStatus ~= "Readable"
        or not finite(health) or not finite(maximum) or maximum <= 0
        or health < 0 or health > maximum then return "Unavailable" end
    return "Readable", health < maximum / 2
end
local function empty()
    return {Readable=0, Restricted=0, Unavailable=0, Skipped=0, drops=0, recoveries=0}
end
function D.Paint()
    if not D.root then return end
    D.context:SetText(D.enabled and (D.suspended and "PAUSED - changing world" or
        "RUNNING - samples every 0.2s and on health changes") or "STOPPED - results retained until Start, Reset or reload")
    for _, unit in ipairs(units) do
        local row = D.rows[unit]
        for _, mode in ipairs({"Outside", "Combat"}) do
            local stats, labels = row[mode], row.labels[mode]
            labels.counts:SetFormattedText("%d / %d / %d / %d",
                stats.Readable, stats.Restricted, stats.Unavailable, stats.Skipped)
            labels.crossings:SetFormattedText("%d / %d", stats.drops, stats.recoveries)
            local status = stats.Restricted > 0 and "UNSUPPORTED"
                or stats.Unavailable > 0 and "INCOMPLETE"
                or stats.Readable > 0 and "READABLE" or "NOT TESTED"
            labels.status:SetText(status)
            if stats.Restricted > 0 then labels.status:SetTextColor(1, 0.38, 0.32)
            elseif stats.Unavailable > 0 then labels.status:SetTextColor(1, 0.75, 0.3)
            else labels.status:SetTextColor(0.8, 0.8, 0.8) end
        end
    end
    D.startButton:SetEnabled(not D.enabled)
    D.stopButton:SetEnabled(D.enabled)
end
function D.Reset(partyOnly)
    D.previous = {}
    D.elapsed = 0
    for _, unit in ipairs(units) do
        local row = D.rows[unit]
        if not partyOnly or unit ~= "player" then
            row.Outside, row.Combat = empty(), empty()
        end
    end
    if partyOnly then D.rosterChanges = D.rosterChanges + 1 else D.rosterChanges = 0 end
    if D.roster then D.roster:SetFormattedText("Party resets: %d (party counters reset when the roster changes)", D.rosterChanges) end
    D.Paint()
end
function D.Sample(onlyUnit)
    if not D.enabled or D.suspended then return end
    local mode = InCombatLockdown() and "Combat" or "Outside"
    for _, unit in ipairs(units) do
        if not onlyUnit or onlyUnit == unit then
            local stats = D.rows[unit][mode]
            local status, below = observe(unit)
            stats[status] = stats[status] + 1
            if status == "Readable" then
                local previous = D.previous[unit]
                if previous == false and below then stats.drops = stats.drops + 1 end
                if previous == true and not below then stats.recoveries = stats.recoveries + 1 end
                D.previous[unit] = below
            else
                -- A gap cannot establish a crossing or rearm from an inferred value.
                D.previous[unit] = nil
            end
        end
    end
    D.Paint()
end
function D.Stop()
    if D.moving then D.root:StopMovingOrSizing(); D.moving = nil end
    D.enabled = false
    D.previous = {}
    if D.frame then
        D.frame:SetScript("OnUpdate", nil)
        D.frame:UnregisterAllEvents()
    end
    D.Paint()
end
function D.Begin()
    if D.enabled then return end
    D.Reset()
    D.enabled, D.suspended = true, false
    for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_CONNECTION", "UNIT_FLAGS",
        "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD"}) do D.frame:RegisterEvent(event) end
    D.frame:SetScript("OnUpdate", function(_, elapsed)
        if D.suspended then return end
        D.elapsed = D.elapsed + elapsed
        if D.elapsed >= 0.2 then D.elapsed = 0; D.Sample() end
    end)
    D.Sample()
end
function D.Close()
    D.Stop()
    if D.root then D.root:Hide() end
end
function D.Open()
    D.root:Show()
    D.Paint()
end
function D.Create()
    local root = CreateFrame("Frame", nil, UIParent)
    D.root = root
    root:SetSize(780, 438); root:SetPoint("CENTER")
    root:SetFrameStrata("DIALOG")
    root:SetMovable(true); root:SetClampedToScreen(true)
    A.Style.Background(root)
    local function text(size, x, y, width)
        local label = A.Style.Text(root, size)
        label:SetPoint("TOPLEFT", x, y); label:SetSize(width, 18); label:SetJustifyH("LEFT")
        return label
    end
    text(13, 12, -10, 740):SetText("Focus health checks - silent; session only; drag header outside combat")
    local handle = CreateFrame("Button", nil, root)
    handle:SetSize(780, 32); handle:SetPoint("TOPLEFT"); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if not InCombatLockdown() then root:StartMoving(); D.moving = true end
    end)
    handle:SetScript("OnDragStop", function() root:StopMovingOrSizing(); D.moving = nil end)
    D.context = text(11, 12, -40, 750)
    text(11, 12, -68, 84):SetText("Unit")
    text(11, 96, -68, 80):SetText("Context")
    text(11, 186, -68, 240):SetText("Readable / Restricted / Missing / Skip")
    text(11, 436, -68, 130):SetText("Below 50 / Recover")
    text(11, 596, -68, 170):SetText("Readability")
    for i, unit in ipairs(units) do
        local row = {labels={}}
        D.rows[unit] = row
        for j, mode in ipairs({"Outside", "Combat"}) do
            local y = -92 - ((i-1)*2+j-1)*22
            text(11, 12, y, 80):SetText(unit)
            text(11, 96, y, 80):SetText(mode)
            row.labels[mode] = {counts=text(11,186,y,240), crossings=text(11,436,y,130),
                status=text(11,596,y,170)}
        end
    end
    text(10, 12, -316, 750):SetText("UNSUPPORTED = restricted read seen. Missing includes invalid/error reads. Neither implies healthy.")
    text(10, 12, -336, 750):SetText("Crossings need consecutive readable samples. Skip = absent, dead, offline or raid. No health values are saved.")
    D.roster = text(10, 12, -356, 750)
    local function button(label, x, callback)
        local b = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
        b:SetSize(100, 26); b:SetPoint("TOPLEFT", x, -392); b:SetText(label)
        b:SetScript("OnClick", callback)
        return b
    end
    D.startButton = button("Start", 12, D.Begin)
    D.stopButton = button("Stop", 124, D.Stop)
    D.resetButton = button("Reset", 236, function() D.Reset() end)
    button("Close", 668, D.Close)
    root:SetScript("OnHide", D.Stop)
    D.frame = CreateFrame("Frame")
    D.frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVING_WORLD" then
            if D.moving then root:StopMovingOrSizing(); D.moving = nil end
        end
        if event == "PLAYER_LEAVING_WORLD" then
            D.suspended = true; D.previous = {}; D.Paint()
        elseif event == "PLAYER_ENTERING_WORLD" then
            D.suspended = false; D.previous = {}; D.Sample()
        elseif event == "GROUP_ROSTER_UPDATE" then
            D.Reset(true); D.Sample()
        elseif event:sub(1, 5) == "UNIT_" then
            if A.Access.Readable(unit) and tracked[unit] then D.Sample(unit) end
        else D.Sample() end
    end)
    D.Reset()
    root:Hide()
end
