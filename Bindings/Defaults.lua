local _, A = ...
local D = {}
A.BindingDefaults = D
-- Class -> slot -> candidate ranks, highest first. Every candidate must be
-- resolved and learned on the running client; never persist automatic choices.
local classes = { PRIEST = {
    ["1"] = { 2053, 2052, 2050 }, -- Lesser Heal
}, PALADIN = {
    ["1"] = { 25292, 10329, 10328, 3472, 1042, 1026, 647, 639, 635 }, -- Holy Light
}, DRUID = {
    ["1"] = { 25297, 9889, 9888, 9758, 8903, 6778, 5189, 5188, 5187, 5186, 5185 }, -- Healing Touch
}, SHAMAN = {
    ["1"] = { 25357, 10396, 10395, 8005, 959, 939, 913, 547, 332, 331 }, -- Healing Wave
} }
local bandageClasses = { WARRIOR=true, ROGUE=true, HUNTER=true, MAGE=true, WARLOCK=true }
function D.Action(slot)
    if not A.db or type(A.db.defaultSpells) ~= "table" or A.db.defaultSpells.enabled ~= true then return nil end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or type(class) ~= "string" then return nil end
    -- Keep the item selected even without stock or usable item information. The
    -- existing resolver and native item action enforce readiness/use requirements.
    if slot == "1" and bandageClasses[class] then return {kind="item", id=1251} end
    local ranks = classes[class] and classes[class][slot]
    if not ranks then return nil end
    for _, id in ipairs(ranks) do
        if A.Bindings.Resolve(id) then return id end
    end
end
