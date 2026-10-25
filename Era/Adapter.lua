-- Selected only by the Era TOC, after shared modules and before startup.
local _, A = ...
if A.__ApogeeClient ~= "classic-era" then return end
A.disableTargetActions = true
function A.CheckClient()
    for _, name in ipairs({"issecretvalue", "canaccessvalue", "canaccesstable",
        "RegisterStateDriver", "InCombatLockdown", "UnitHealth", "UnitHealthMax",
        "UnitPower", "UnitPowerMax", "UnitPowerType", "UnitExists", "UnitName",
        "UnitIsConnected", "UnitIsDeadOrGhost", "GetSpellBookItemInfo"}) do
        if type(_G[name]) ~= "function" then return false, "Missing Era API: " .. name end
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then return false, "Missing timer API." end
    if not C_SpellBook or type(C_SpellBook.IsSpellKnown) ~= "function"
        or type(C_SpellBook.IsSpellInSpellBook) ~= "function"
        or not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then
        return false, "Missing Era spell API."
    end
    return true
end
function A.Bindings.Cursor()
    local kind, index, bank, id = GetCursorInfo()
    if not A.Access.Readable(kind, index, bank, id) then return nil, "Cursor unavailable." end
    if kind == "item" then
        local info, reason = A.Bindings.ResolveItem(index)
        return info and {kind="item", id=index} or nil, reason
    end
    local player = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if kind ~= "spell" or (bank ~= "spell" and bank ~= "player"
        and not (type(player) == "number" and bank == player)) then
        return nil, "Choose a player spell."
    end
    if type(id) ~= "number" and type(index) == "number" and index >= 1 and index % 1 == 0 then
        local ok, spellType, spellID = pcall(GetSpellBookItemInfo, index, "spell")
        if ok and A.Access.Readable(spellType, spellID) and spellType == "SPELL" then id = spellID end
    end
    local info, reason = A.Bindings.Resolve(id)
    return info and id or nil, reason
end
function A.UnitAPI.PaintFullName(label, unit)
    -- Era's second return is the realm, not a surname. Match native short names.
    label:SetText("")
    local ok, name = pcall(UnitName, unit)
    if ok and (not A.Access.Readable(name) or type(name) == "string") then
        pcall(label.SetText, label, name)
    end
end
