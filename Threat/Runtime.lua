local _, A = ...
local R, M, V = {}, A.ThreatModel, A.ThreatView
A.Threat = R
local function nameplate(unit)
    return A.Access.Readable(unit) and type(unit) == "string" and unit:match("^nameplate%d+$") ~= nil
end
function R.Reset()
    R.model, R.exposed = M.New(), {}; R.elapsed = 0; R.pending = nil
    V.Clear()
end
function R.Discover()
    local plates = A.Access.Read(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return end
    for _, plate in pairs(plates) do
        -- Only bootstrap existing plates; never inspect their unit-frame state.
        local ok, unit = pcall(function()
            if A.Access.Read(plate.IsForbidden, plate) ~= false then return end
            return plate:GetUnit()
        end)
        if ok and nameplate(unit) then R.exposed[unit] = true end
    end
end
function R.Refresh()
    if R.demo or R.suspended or A.db.threatEnabled ~= true then return end
    R.pending = nil; R.elapsed = 0
    for unit in pairs(R.exposed) do
        local presence, warning, ok, tanking, raw = M.Sample(unit)
        -- An API failure does not establish safety or absence. Keep an unknown
        -- row for exposed hostile mobs when their participation is restricted.
        M.Observe(R.model, unit, presence, warning)
        local entry = R.model.entries[unit]
        if entry and entry.slot then V.Paint(V.rows[entry.slot],unit,warning,ok,tanking,raw) end
    end
    M.Fill(R.model)
    -- All rows belong to stable nameplate lifetimes. Selection only paints
    -- an outline; it never creates a target placeholder or promotes a row.
    local comparisonsOK = true
    local count, visible = 0, 0
    for _ in pairs(R.model.entries) do count = count + 1 end
    for i = 1, 8 do
        local unit, row = R.model.slots[i], V.rows[i]
        if unit then
            visible = visible + 1
            if row.unit ~= unit then
                local _, warning, ok, tanking, raw = M.Sample(unit)
                V.Paint(row,unit,warning,ok,tanking,raw)
            end
            row.selection:SetAlpha(0)
            local ok, same = pcall(UnitIsUnit,unit,"target")
            if ok then
                if not V.BooleanAlpha(row.selection,same,1,0) then comparisonsOK = false end
            else comparisonsOK = false end
        else V.ClearRow(row) end
    end
    local extra = count-visible
    V.footer:SetText(extra > 0 and ("+" .. extra .. " more") or "")
    if not comparisonsOK then V.footer:SetText("Target match unknown")
    elseif visible == 0 then
        V.footer:SetText(InCombatLockdown() and "No tracked enemies - show nameplates" or "Idle - no tracked enemies")
    end
end
function R.ApplyEnabled()
    R.Reset(); V.Place()
    V.title:SetText(R.demo and "DEMO - drag to move" or "Threat")
    if R.demo and not R.suspended then
        R.demoTime = 0; V.root:Show(); V.PaintDemo(0)
        R.frame:SetScript("OnUpdate", function(_, elapsed)
            R.demoTime = R.demoTime + elapsed; R.elapsed = R.elapsed + elapsed
            if R.elapsed >= 0.05 then R.elapsed = 0; V.PaintDemo(R.demoTime) end
        end)
        return
    end
    local enabled = A.db.threatEnabled == true and not R.suspended
    V.root:SetShown(enabled)
    R.frame:SetScript("OnUpdate", enabled and function(_, elapsed)
        R.elapsed = R.elapsed + elapsed
        if R.pending or R.elapsed >= 0.1 then R.Refresh() end
    end or nil)
    if enabled then V.PrepareDebuffs(); R.Discover(); R.Refresh() end
end
function R.SetDemo(enabled)
    if InCombatLockdown() or R.suspended then return end
    R.demo = enabled == true; R.ApplyEnabled(); A.Settings.Refresh()
end
function R.SetEnabled(enabled)
    if InCombatLockdown() then return end
    A.db.threatEnabled = enabled == true; R.ApplyEnabled()
end
function R.Start()
    V.Create(); R.frame = CreateFrame("Frame")
    for _, event in ipairs({"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_THREAT_LIST_UPDATE",
        "UNIT_THREAT_SITUATION_UPDATE", "PLAYER_TARGET_CHANGED", "UNIT_FACTION",
        "UNIT_FLAGS", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
        R.frame:RegisterEvent(event)
    end
    R.frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_LEAVING_WORLD" then
            V.StopMoving(false); R.demo = false; R.suspended = true; R.ApplyEnabled(); A.Settings.Refresh(); return
        elseif event == "PLAYER_ENTERING_WORLD" then
            R.suspended = nil; R.ApplyEnabled(); return
        elseif event == "PLAYER_REGEN_DISABLED" then
            V.StopMoving(false)
            if R.demo then R.demo = false; R.ApplyEnabled(); A.Settings.Refresh() end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if A.db.threatEnabled == true then V.PrepareDebuffs() end
            V.Place(); A.Settings.Refresh()
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then V.Place() end
        if R.demo or R.suspended or A.db.threatEnabled ~= true then return end
        if event == "NAME_PLATE_UNIT_ADDED" and nameplate(unit) then
            -- Each added lifetime is new, even if the engine reuses the token.
            local entry = R.model.entries[unit]
            if entry and entry.slot then V.ClearRow(V.rows[entry.slot]) end
            M.Remove(R.model, unit); R.exposed[unit] = true
        elseif event == "NAME_PLATE_UNIT_REMOVED" and nameplate(unit) then
            R.exposed[unit] = nil; M.Remove(R.model, unit)
        elseif event:match("^UNIT_") then
            -- Coalesce combat bursts to the next frame. Native aura containers
            -- own their own events; unrelated units must not repaint this stack.
            if A.Access.Readable(unit) and (unit == "player" or unit == "target"
                or (nameplate(unit) and R.exposed[unit])) then R.pending = true end
            return
        end
        R.Refresh()
    end)
    R.ApplyEnabled()
end
