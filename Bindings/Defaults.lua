local _, A = ...
local D = {}
A.BindingDefaults = D
-- Class -> slot -> candidate ranks, highest first. Every candidate must be
-- resolved and learned on the running client; never persist automatic choices.
local classes = { PRIEST = {
    ["1"] = { 2053, 2052, 2050 }, -- Lesser Heal
    ["2"] = { 10901, 10900, 10899, 10898, 6066, 6065, 3747, 600, 592, 17 }, -- Power Word: Shield
}, PALADIN = {
    ["1"] = { 25292, 10329, 10328, 3472, 1042, 1026, 647, 639, 635 }, -- Holy Light
} }
function D.Spell(slot)
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not A.Access.Readable(class) or type(class) ~= "string" then return nil end
    local ranks = classes[class] and classes[class][slot]
    if not ranks then return nil end
    for _, id in ipairs(ranks) do
        if A.Bindings.Resolve(id) then return id end
    end
end
