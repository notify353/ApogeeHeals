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
local function validID(id)
    return A.Access.Readable(id) and type(id) == "number"
        and id > 0 and id < 2147483647 and id % 1 == 0
end
function B.ResolveItem(id)
    if not validID(id) then return nil, "Invalid bandage." end
    if not C_Item or type(C_Item.GetItemInfoInstant) ~= "function" then
        return nil, "Item information unavailable."
    end
    local ok, resolved, _, _, _, icon, class, subclass = pcall(C_Item.GetItemInfoInstant, id)
    if not ok or not A.Access.Readable(resolved, icon, class, subclass) then
        return nil, "Item information unavailable."
    end
    if resolved ~= id or not Enum or not Enum.ItemClass or not Enum.ItemConsumableSubclass
        or class ~= Enum.ItemClass.Consumable or subclass ~= Enum.ItemConsumableSubclass.Bandage then
        return nil, "Choose a bandage from your bags."
    end
    local name = A.Access.Read(C_Item.GetItemNameByID, id)
    if type(name) ~= "string" or name == "" then name = "Bandage (item " .. id .. ")" end
    return {name=name, iconID=icon, itemID=id}
end
function B.Resolve(id)
    if not A.Access.Readable(id) then return nil, "Assignment unavailable." end
    if type(id) == "table" then
        if not A.Access.Readable(id.kind, id.id) or id.kind ~= "item" then return nil, "Invalid item." end
        return B.ResolveItem(id.id)
    end
    if not validID(id) then return nil, "Invalid spell." end
    local info = A.Access.Read(C_Spell and C_Spell.GetSpellInfo, id)
    if type(info) ~= "table" or not A.Access.Readable(info.name, info.iconID)
        or type(info.name) ~= "string" or info.name == "" then
        return nil, "Spell information unavailable."
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
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
    if not A.Access.Readable(kind, index, bank, id) then return nil, "Cursor unavailable." end
    if kind == "item" then
        local info, reason = B.ResolveItem(index)
        return info and {kind="item", id=index} or nil, reason
    end
    if kind ~= "spell" then
        return nil, "Drop a learned healing spell or a bandage from your bags."
    end
    local playerBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if bank ~= "spell" and (playerBank == nil or bank ~= playerBank) then
        return nil, "Choose a player spell."
    end
    if type(id) ~= "number" and type(index) == "number" and C_SpellBook
        and playerBank ~= nil then
        local info = A.Access.Read(C_SpellBook.GetSpellBookItemInfo, index, playerBank)
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
    end
    for _, prefix in ipairs({ "", "shift-", "ctrl-", "ctrl-shift-", "alt-",
        "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
        for button = 1, 5 do
            -- One transient resolution per combination, shared by its fixed recipients.
            local id = B.byId[prefix .. button] and B.Effective(prefix .. button)
            local info = id and B.Resolve(id)
            -- Plain left targets only without an assignment or learned default. Unavailable assignments
            -- and empty modified slots must not fall through to another action.
            local fallback = button == 1 and prefix == "" and id == nil and "target" or ""
            local item = info and info.itemID
            if prefix == "" and button == 1 then B.rangeSpell = info and not item and id or nil end
            for _, frame in ipairs(A.View.rows) do
                frame:SetAttribute(prefix .. "type" .. button, info and (item and "item" or "spell") or fallback)
                frame:SetAttribute(prefix .. "spell" .. button, info and not item and id or nil)
                frame:SetAttribute(prefix .. "item" .. button, item and "item:" .. item or nil)
            end
        end
    end
    if A.Runtime.driver then A.Runtime.RangePolling() end
    if A.BindingEditor then A.BindingEditor.Refresh() end
end
function B.Put(slot, id)
    if InCombatLockdown() or not B.byId[slot] then return false end
    if id and not B.Resolve(id) then return false end
    A.db.bindings[slot] = type(id) == "table" and {kind="item", id=id.id} or id
    B.Apply(); return true
end
function B.Swap(first, second)
    if InCombatLockdown() or not B.byId[first] or not B.byId[second] then return false end
    A.db.bindings[first], A.db.bindings[second] = A.db.bindings[second], A.db.bindings[first]
    B.Apply(); return true
end
