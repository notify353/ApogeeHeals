local _, A = ...
local D, R = {}, A.Access.Read
A.Drinking = D
-- Classic drink identities from APHB (MIT). Resolve on this client before use.
-- Export documentation verifies API contracts, not server spell/aura coverage.
local candidates = { 430, 431, 432, 1133, 1135, 1137, 10250, 22734 }
local ids, names = {}, {}
function D.Resolve()
    ids, names = {}, {}
    for _, id in ipairs(candidates) do
        local info = R(C_Spell and C_Spell.GetSpellInfo, id)
        if type(info) == "table" and A.Access.Readable(info.name, info.spellID)
            and type(info.name) == "string" and info.name ~= "" and info.spellID == id then
            ids[id], names[info.name] = true, true
        end
    end
end
function D.IsDrinking(unit)
    if InCombatLockdown() or A.UnitAPI.State(unit) ~= "alive" then return false end
    local getAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(getAura) ~= "function" then return false end
    local found = false
    -- Bounded full scan: unreadable or incomplete data never becomes a positive claim.
    for index = 1, 255 do
        local ok, aura = pcall(getAura, unit, index, "HELPFUL")
        if not ok or not A.Access.Readable(aura) then return false end
        if aura == nil then return found end
        if type(aura) ~= "table" or not A.Access.Readable(aura.spellId, aura.name) then return false end
        if ids[aura.spellId] or names[aura.name] then found = true end
    end
    return false
end
