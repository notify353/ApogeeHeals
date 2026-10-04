local _, A = ...
local R = {pending={}, blocked={}}
A.ThreatMarkers = R
local units = {"target"}
for i=1,40 do units[#units+1] = "nameplate"..i end
local function read(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, value = pcall(fn,...)
    if not ok or not A.Access.Readable(value) then return false end
    return true, value
end
local function available(index)
    -- Native marker occupancy survives target changes and missing nameplates.
    -- No wrapping: another returned index does not mean this one is available.
    local ok, value = read(GetNextAvailableRaidTargetMarkerIndex,index,false,false,true)
    if not ok then return nil end
    return value == index
end
local function permission()
    local ok, raid = read(IsInRaid)
    if not ok then return false end
    if raid then
        return A.Access.Read(UnitIsGroupLeader,"player") == true
            or A.Access.Read(UnitIsGroupAssistant,"player") == true
    end
    return true
end
local function candidate(unit)
    if A.Access.Read(UnitExists,unit) ~= true or A.Access.Read(UnitIsDeadOrGhost,unit) ~= false
        or A.Access.Read(UnitCanAttack,"player",unit) ~= true
        or A.Access.Read(UnitIsPlayer,unit) ~= false
        or A.Access.Read(CanBeRaidTarget,unit) ~= true then return end
    -- Targeting is the owner's explicit acquisition gesture. Other candidates
    -- must already be publicly confirmed participants in the player's fight.
    if unit ~= "target" then
        if A.Access.Read(UnitAffectingCombat,unit) ~= true then return end
        local presence = A.ThreatModel.Sample(unit)
        if presence ~= "present" then return end
    end
    local ok, mark = read(GetRaidTargetIndex,unit)
    if not ok or mark ~= nil then return end -- Preserve existing/manual marks.
    local bossOK, boss = read(UnitIsBossMob,unit)
    local classOK, classification = read(UnitClassification,unit)
    if boss == true or classification == "worldboss" then return "boss" end
    if not bossOK or boss ~= false or not classOK or type(classification) ~= "string" then return "unknown" end
    local manaOK, mana = read(UnitHasPowerType,unit,0)
    if not manaOK or type(mana) ~= "boolean" then return "unknown" end
    return mana and "mana" or "other"
end
local function stop(index)
    if R.blocked[index] then return end
    R.blocked[index] = true
    print("Apogee Heals: Automatic raid marking could not be confirmed; marking paused until reload.")
end
local function ready(index)
    if R.blocked[index] then return false end
    local free = available(index)
    if R.pending[index] then
        if R.clock < R.pending[index] then return false end
        if free == true then stop(index)
        elseif free == false then R.pending[index] = nil end
        return false
    end
    return free == true
end
local function assign(unit,index)
    if not unit or available(index) ~= true then return end
    -- Let the native API enforce permissions/restrictions. Never emulate input,
    -- change a secure attribute or retry a blocked call in a loop.
    R.pending[index] = R.clock + 2
    if not pcall(SetRaidTarget,unit,index) then stop(index) end
end
function R.Refresh()
    if R.suspended or not A.db or A.db.threatEnabled ~= true or A.Threat.demo or not permission() then return end
    local circle, skull = ready(2), ready(8)
    if not circle and not skull then return end
    local bossUnit, manaUnit, lowestUnit, lowestHealth
    local complete = true
    for _,unit in ipairs(units) do
        local kind = candidate(unit)
        if kind == "boss" then
            bossUnit = bossUnit or unit
        elseif kind == "mana" then
            manaUnit = manaUnit or unit
        elseif kind == "unknown" then
            complete = false
        elseif kind == "other" then
            local ok, health = read(UnitHealth,unit)
            if not ok or type(health) ~= "number" or health ~= health or health <= 0 or health == math.huge then
                complete = false
            elseif not lowestHealth or health < lowestHealth then
                lowestUnit, lowestHealth = unit, health
            end
        end
    end
    if circle then assign(bossUnit,2) end
    if skull then assign(manaUnit or (complete and lowestUnit or nil),8) end
end
function R.Start()
    R.frame = CreateFrame("Frame")
    R.elapsed, R.clock = 0, 0
    for _,event in ipairs({"PLAYER_TARGET_CHANGED","PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD"}) do
        R.frame:RegisterEvent(event)
    end
    R.frame:SetScript("OnEvent",function(_,event)
        if event == "PLAYER_LEAVING_WORLD" then R.suspended = true; return end
        if event == "PLAYER_ENTERING_WORLD" then R.suspended = nil end
        R.elapsed = 0
        R.Refresh()
    end)
    R.frame:SetScript("OnUpdate",function(_,elapsed)
        R.clock = R.clock + elapsed
        R.elapsed = R.elapsed + elapsed
        if R.elapsed >= 0.5 then R.elapsed = 0; R.Refresh() end
    end)
end
