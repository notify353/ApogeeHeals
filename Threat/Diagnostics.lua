local _, A = ...
local D = {enabled=false, elapsed=0}
A.ThreatDiagnostics = D
local fields = {"Tanking flag", "Threat status", "Scaled percentage", "Raw percentage", "Threat amount",
    "Lead warning", "Percentage of lead"}

local function result(label, passed)
    label:SetText(passed and "PASS" or "FAIL")
    if passed then label:SetTextColor(0.28,0.85,0.46,1)
    else label:SetTextColor(1,0.38,0.32,1) end
end

function D.Reset()
    D.sampled = false
    D.duration, D.samples, D.pollSamples, D.skipped, D.longestGap = 0, 0, 0, 0, 0
    D.firstSample, D.lastSample = nil, nil
    for _, row in ipairs(D.rows) do
        row.readable, row.native = nil, nil
        row.access:SetText("--"); row.sink:SetText("--"); row.reason:SetText("")
    end
    D.PaintCoverage()
end

function D.PaintCoverage()
    -- Frame elapsed time and these counters are public diagnostics, not threat data.
    local gap = math.max(D.longestGap, D.duration - (D.lastSample or 0))
    D.coverage:SetFormattedText("Samples: %d (%d polled) | Skipped checks: %d | Combat: %.1fs",
        D.samples, D.pollSamples, D.skipped, D.duration)
    if D.firstSample then
        D.timing:SetFormattedText("First: %.1fs | Last: %.1fs into combat | Longest gap: %.1fs",
            D.firstSample, D.lastSample, gap)
    else D.timing:SetFormattedText("First: -- | Last: -- | Time without samples: %.1fs", D.duration) end
end

function D.Probe(row, ok, value, boolean)
    -- Only public capability outcomes are retained; never retain the value.
    local readable, sent, reason = false, false, "API error"
    if ok then
        -- Access checks precede every type test, comparison and Lua operation.
        readable = A.Access.Readable(value)
        if readable then
            if value == nil then readable = false; reason = "Missing"
            elseif (boolean and type(value) ~= "boolean") or (not boolean and
                (type(value) ~= "number" or value ~= value or math.abs(value) == math.huge)) then
                readable = false; reason = "Invalid"
            else reason = "" end
        else reason = "Restricted" end
        if readable or reason == "Restricted" then
            if boolean then
                sent = A.ThreatView.BooleanAlpha(D.booleanSink, value, 1, 0)
            else
                sent = pcall(D.numberSink.SetFormattedText, D.numberSink, "%.2f", value)
            end
        end
    end
    -- FAIL latches for this fight, even when a later sample succeeds.
    if row.readable ~= false then
        row.readable = readable
        if not readable then row.reason:SetText(reason) end
    end
    if row.native ~= false then row.native = sent end
    result(row.access, row.readable); result(row.sink, row.native)
    -- Clear the native sinks immediately; they are probes, not sample storage.
    D.numberSink:SetText(""); D.booleanSink:SetAlpha(0)
end

function D.Refresh(polled)
    if not D.enabled or D.suspended or not D.collecting or not InCombatLockdown() then return end
    -- Target gaps/friendly targets do not count as failed threat observations.
    if A.Access.Read(UnitExists, "target") ~= true or A.Access.Read(UnitCanAttack, "player", "target") ~= true
        or A.Access.Read(UnitIsDeadOrGhost, "target") ~= false then
        D.skipped = D.skipped + 1; D.PaintCoverage(); return
    end
    D.samples = D.samples + 1
    if polled then D.pollSamples = D.pollSamples + 1 end
    D.longestGap = math.max(D.longestGap, D.duration - (D.lastSample or 0))
    D.firstSample = D.firstSample or D.duration
    D.lastSample = D.duration
    D.sampled = true
    D.context:SetText("IN COMBAT - checking your threat against selected enemies")
    local ok, tanking, status, scaled, raw, amount = pcall(UnitDetailedThreatSituation, "player", "target")
    D.Probe(D.rows[1], ok, tanking, true)
    D.Probe(D.rows[2], ok, status)
    D.Probe(D.rows[3], ok, scaled)
    D.Probe(D.rows[4], ok, raw)
    D.Probe(D.rows[5], ok, amount)
    local leadOK, lead = pcall(UnitThreatLeadSituation, "player", "target")
    D.Probe(D.rows[6], leadOK, lead)
    local percentOK, percent = pcall(UnitThreatPercentageOfLead, "player", "target")
    D.Probe(D.rows[7], percentOK, percent)
    D.PaintCoverage()
end

function D.Begin()
    D.Reset(); D.collecting = true; D.elapsed = 0
    D.context:SetText("IN COMBAT - select a living enemy to check")
    D.frame:SetScript("OnUpdate", function(_, elapsed)
        if not InCombatLockdown() then return end
        D.duration = D.duration + elapsed
        D.elapsed = D.elapsed + elapsed
        if D.elapsed >= 0.2 then D.elapsed = 0; D.Refresh(true) end
    end)
    D.Refresh()
end

function D.Freeze()
    D.collecting = false; D.frame:SetScript("OnUpdate", nil)
    D.PaintCoverage()
    D.context:SetText(D.sampled and "FROZEN - ready for screenshot; next combat starts fresh"
        or "NO SAMPLES - select a living enemy during the next fight")
end

function D.SetEnabled(enabled)
    if InCombatLockdown() then return end
    D.enabled = enabled == true
    if not D.root then return end
    D.collecting = false; D.frame:SetScript("OnUpdate", nil)
    D.root:SetShown(D.enabled); D.Reset()
    D.context:SetText("READY - enter combat with a living enemy selected")
end

function D.Start()
    local root = CreateFrame("Frame", nil, UIParent)
    D.root = root
    root:SetSize(530, 360); root:SetPoint("CENTER", UIParent, "CENTER", 290, 80)
    root:SetMovable(true); root:SetClampedToScreen(true); root:EnableMouse(false)
    A.Style.Background(root)
    local function text(size, x, y, width)
        local label = A.Style.Text(root, size)
        label:SetPoint("TOPLEFT", x, y); label:SetSize(width, 18); label:SetJustifyH("LEFT")
        return label
    end
    text(13, 12, -8, 506):SetText("Threat checks - drag header outside combat")
    local handle = CreateFrame("Button", nil, root); D.handle = handle
    handle:SetSize(530, 30); handle:SetPoint("TOPLEFT"); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if not InCombatLockdown() then root:StartMoving(); D.moving = true end
    end)
    handle:SetScript("OnDragStop", function() root:StopMovingOrSizing(); D.moving = nil end)
    D.context = text(11, 12, -35, 506)
    text(11, 12, -65, 165):SetText("Threat field")
    text(11, 184, -65, 90):SetText("Lua read")
    text(11, 280, -65, 106):SetText("Display call")
    text(11, 396, -65, 122):SetText("Read failure")
    D.rows = {}
    for i, field in ipairs(fields) do
        local y = -89-(i-1)*23
        text(11, 12, y, 165):SetText(field)
        D.rows[i] = {access=text(11, 184, y, 90), sink=text(11, 280, y, 106), reason=text(11, 396, y, 122)}
    end
    text(10, 12, -255, 506):SetText("FAIL = at least one failed check this fight. -- = not checked.")
    text(10, 12, -274, 506):SetText("Display PASS confirms call acceptance only, not visible rendering.")
    D.coverage = text(11, 12, -299, 506)
    D.timing = text(11, 12, -318, 506)
    text(10, 12, -337, 506):SetText("Samples count API attempts. Gaps include skipped checks and frame stalls.")
    local hidden = CreateFrame("Frame", nil, root); hidden:Hide()
    D.numberSink = A.Style.Text(hidden, 11)
    D.booleanSink = hidden:CreateTexture(nil, "ARTWORK")
    D.frame = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_TARGET_CHANGED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD"}) do
        D.frame:RegisterEvent(event)
    end
    D.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVING_WORLD" then
            if D.moving then root:StopMovingOrSizing(); D.moving = nil end
        end
        if event == "PLAYER_LEAVING_WORLD" then
            D.suspended = true
            if D.enabled and D.collecting then D.Freeze() end
        elseif event == "PLAYER_ENTERING_WORLD" then
            D.suspended = nil
            if D.enabled and InCombatLockdown() then D.Begin() end
        elseif D.enabled and not D.suspended then
            if event == "PLAYER_REGEN_DISABLED" then D.Begin()
            elseif event == "PLAYER_REGEN_ENABLED" then D.Freeze()
            else D.Refresh() end
        end
    end)
    D.SetEnabled(false)
end
