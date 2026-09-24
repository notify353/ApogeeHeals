local _, A = ...
local B = { slots = {}, byId = {} }
A.Bindings = B
for row, prefix in ipairs({ "", "shift-", "ctrl-" }) do
    for button = 1, 5 do
        local slot = { id = prefix .. button, prefix = prefix, button = button, row = row,
            label = ({ "", "Shift + ", "Ctrl + " })[row]
                .. ({ [1] = "Left", [2] = "Right", [3] = "Middle", [4] = "Mouse 4", [5] = "Mouse 5" })[button] }
        B.slots[#B.slots + 1] = slot; B.byId[slot.id] = slot
    end
end
function B.Resolve(id)
    if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then return nil, "Invalid spell." end
    local info = A.Access.Read(C_Spell.GetSpellInfo, id)
    if type(info) ~= "table" or not A.Access.Readable(info.name, info.iconID)
        or type(info.name) ~= "string" or info.name == "" then
        return nil, "Spell information unavailable."
    end
    local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if not bank or not C_SpellBook
        or A.Access.Read(C_SpellBook.IsSpellInSpellBook, id, bank, false) ~= true
        or A.Access.Read(C_SpellBook.IsSpellKnown, id, bank) ~= true then
        return nil, "Spell is not learned."
    end
    if A.Access.Read(C_Spell.IsSpellHelpful, id) ~= true
        or A.Access.Read(C_Spell.IsSpellHarmful, id) ~= false
        or A.Access.Read(C_Spell.IsSpellPassive, id) ~= false then
        return nil, "Choose an active friendly spell."
    end
    return info
end
function B.Cursor()
    local kind, index, bank, id = GetCursorInfo()
    if not A.Access.Readable(kind, index, bank, id) or kind ~= "spell" then
        return nil, "Drop a learned healing spell from your spellbook."
    end
    if bank ~= "spell" and (not Enum.SpellBookSpellBank or bank ~= Enum.SpellBookSpellBank.Player) then
        return nil, "Choose a player spell."
    end
    if type(id) ~= "number" and type(index) == "number" and C_SpellBook
        and Enum.SpellBookSpellBank then
        local info = A.Access.Read(C_SpellBook.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Player)
        if type(info) == "table" and A.Access.Readable(info.spellID) then id = info.spellID end
    end
    local info, reason = B.Resolve(id)
    return info and id or nil, reason
end
function B.Effective(slot)
    local assigned = A.db.bindings[slot]
    if assigned ~= nil then return assigned, false end
    local id = A.BindingDefaults.Spell(slot)
    return id, id ~= nil
end
function B.Apply()
    if InCombatLockdown() then B.pending = true; return end
    B.pending = nil
    for _, frame in ipairs(A.View.rows) do
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
        for _, prefix in ipairs({ "", "shift-", "ctrl-", "ctrl-shift-", "alt-",
            "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
            for button = 1, 5 do
                local id = B.Effective(prefix .. button)
                local info = B.byId[prefix .. button] and id and B.Resolve(id)
                -- Plain left targets only without an assignment or learned default. Unavailable assignments
                -- and empty modified slots must not fall through to another action.
                local fallback = button == 1 and prefix == "" and id == nil and "target" or ""
                frame:SetAttribute(prefix .. "type" .. button, info and "spell" or fallback)
                frame:SetAttribute(prefix .. "spell" .. button, info and id or nil)
            end
        end
    end
    if A.BindingEditor then A.BindingEditor.Refresh() end
end
function B.Put(slot, id)
    if InCombatLockdown() or not B.byId[slot] then return false end
    if id and not B.Resolve(id) then return false end
    A.db.bindings[slot] = id; B.Apply(); return true
end
function B.Swap(first, second)
    if InCombatLockdown() or not B.byId[first] or not B.byId[second] then return false end
    A.db.bindings[first], A.db.bindings[second] = A.db.bindings[second], A.db.bindings[first]
    B.Apply(); return true
end
