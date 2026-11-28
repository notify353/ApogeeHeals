local _, A = ...
local B = { slots = {}, byId = {} }
A.Bindings = B
-- Public tri-state range for the exact spell and fixed recipient. No yard guess.
function B.SpellRange(id, unit)
    if not id or not unit then return nil end
    if unit == "player" or A.Access.Read(UnitIsUnit, unit, "player") == true then return true end
    if A.Access.Read(C_Spell and C_Spell.SpellHasRange, id) == false then return true end
    local result = A.Access.Read(C_Spell and C_Spell.IsSpellInRange, id, unit)
    if type(result) == "boolean" then return result end
end
-- Guarded proximity estimate shared by health fading and living buff recipients.
-- With a spell, use its reported limits; only unassigned healing uses 40 yards.
function B.Proximity(unit, spell, info)
    if unit == "player" or A.Access.Read(UnitIsUnit, unit, "player") == true then return true end
    if type(UnitDistanceSquared) ~= "function" then return nil end
    local minimum, maximum = 0, 40
    if spell then
        if info == nil then info = A.Access.Read(C_Spell and C_Spell.GetSpellInfo, spell) end
        if not A.Access.Readable(info) or type(info) ~= "table"
            or not A.Access.Readable(info.minRange, info.maxRange) then return nil end
        minimum, maximum = info.minRange, info.maxRange
        if type(minimum) ~= "number" or type(maximum) ~= "number"
            or not (minimum >= 0 and maximum > 0 and minimum <= maximum
                and maximum * maximum < math.huge) then return nil end
    end
    local ok, distance, checked = pcall(UnitDistanceSquared, unit)
    if ok and A.Access.Readable(distance, checked) and checked == true
        and type(distance) == "number" and distance >= 0 and distance < math.huge then
        return distance >= minimum * minimum and distance <= maximum * maximum
    end
end
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
-- Traditional bandages can be generic consumables (subclass 0) on Classic.
-- Do not accept the whole generic category or infer identity from localized text.
local standardBandages = {
    [1251]=true, [2581]=true, -- Linen, Heavy Linen
    [3530]=true, [3531]=true, -- Wool, Heavy Wool
    [6450]=true, [6451]=true, -- Silk, Heavy Silk
    [8544]=true, [8545]=true, -- Mageweave, Heavy Mageweave
    [14529]=true, [14530]=true, -- Runecloth, Heavy Runecloth
}
function B.ResolveItem(id)
    if not validID(id) then return nil, "Invalid bandage." end
    if not C_Item or type(C_Item.GetItemInfoInstant) ~= "function" then
        return nil, "Item information unavailable."
    end
    local ok, resolved, _, _, _, icon, class, subclass = pcall(C_Item.GetItemInfoInstant, id)
    if not ok or not A.Access.Readable(resolved, icon, class, subclass)
        or resolved == nil or class == nil or subclass == nil then
        return nil, "Item information unavailable.", true
    end
    local bandageSubclass = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Bandage
    local isBandage = (bandageSubclass ~= nil and subclass == bandageSubclass)
        or (subclass == 0 and standardBandages[id] == true)
    if resolved ~= id or not Enum or not Enum.ItemClass
        or class ~= Enum.ItemClass.Consumable or not isBandage then
        return nil, "Choose a bandage from your bags."
    end
    local name = A.Access.Read(C_Item.GetItemNameByID, id)
    if type(name) ~= "string" or name == "" then name = "Bandage (item " .. id .. ")" end
    return {name=name, iconID=icon, itemID=id}
end
-- Forever's castable Penance wrappers can report harmful/not helpful despite
-- healing friendly recipients. Candidate IDs only: learned player-book, active,
-- readable metadata checks still apply; never admit triggered heal/damage bolts.
local friendlyPenance = { [402174]=true, [1240720]=true, [1240721]=true, [1316995]=true }
function B.Resolve(id)
    if not A.Access.Readable(id) then return nil, "Assignment unavailable." end
    if type(id) == "table" then
        if not A.Access.Readable(id.kind, id.id) or id.kind ~= "item" then return nil, "Invalid item." end
        return B.ResolveItem(id.id)
    end
    if not validID(id) then return nil, "Invalid spell." end
    -- The third result distinguishes retryable reads from definitive rejection.
    -- Missing client capabilities cannot be repaired by a background timer.
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function"
        or type(C_Spell.IsSpellHelpful) ~= "function" or type(C_Spell.IsSpellHarmful) ~= "function"
        or type(C_Spell.IsSpellPassive) ~= "function" then return nil, "Spell API unavailable." end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if not bank or not C_SpellBook or type(C_SpellBook.IsSpellInSpellBook) ~= "function"
        or type(C_SpellBook.IsSpellKnown) ~= "function" then return nil, "Spell book unavailable." end
    local inBook = A.Access.Read(C_SpellBook.IsSpellInSpellBook, id, bank, false)
    local known = A.Access.Read(C_SpellBook.IsSpellKnown, id, bank)
    if inBook == false or known == false then
        return nil, "Spell is not learned."
    end
    if inBook ~= true or known ~= true then return nil, "Spell book unavailable.", true end
    local info = A.Access.Read(C_Spell and C_Spell.GetSpellInfo, id)
    if type(info) ~= "table" or not A.Access.Readable(info.name, info.iconID)
        or type(info.name) ~= "string" or info.name == "" then
        return nil, "Spell information unavailable.", true
    end
    local helpful = A.Access.Read(C_Spell.IsSpellHelpful, id)
    local harmful = A.Access.Read(C_Spell.IsSpellHarmful, id)
    local passive = A.Access.Read(C_Spell.IsSpellPassive, id)
    local penance = friendlyPenance[id] == true
    if passive == true or (not penance and (helpful == false or harmful == true)) then
        return nil, "Choose an active friendly spell."
    end
    if type(helpful) ~= "boolean" or type(harmful) ~= "boolean" or passive ~= false then
        return nil, "Spell classification unavailable.", true
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
    local id, unavailable = A.BindingDefaults.Action(slot)
    return id, id ~= nil, unavailable
end
local mouseButtons = { LeftButton=1, RightButton=2, MiddleButton=3, Button4=4, Button5=5 }
function B.Feedback(_, mouseButton, down)
    if not A.Access.Readable(mouseButton, down) or down == true then return end
    local button = mouseButtons[mouseButton]
    if not button then return end
    local alt = A.Access.Read(IsAltKeyDown)
    local ctrl = A.Access.Read(IsControlKeyDown)
    local shift = A.Access.Read(IsShiftKeyDown)
    if alt ~= false or type(ctrl) ~= "boolean" or type(shift) ~= "boolean"
        or (ctrl and shift) then return end
    local prefix = ctrl and "ctrl-" or shift and "shift-" or ""
    A.BindingEditor.FlashInput(prefix .. button)
end
local function retryWhenReady(needed)
    B.retryNeeded = needed
    if not needed then B.retryToken, B.retryDelay = nil, nil; return end
    if B.retryToken then return end
    local token = {}
    B.retryToken = token
    local delay = B.retryDelay or 0.25
    B.retryDelay = math.min(delay * 2, 5)
    C_Timer.After(delay, function()
        if B.retryToken ~= token then return end
        B.retryToken = nil
        if A.startupState == "failed" then B.retryNeeded = nil; return end
        -- Combat/world-entry events resume recovery; never poll protected state here.
        if InCombatLockdown() or A.Runtime.suspended then B.pending = true; return end
        B.Apply()
    end)
end
local function setActionAttribute(frame, key, value)
    -- Only public, out-of-combat action attributes. Avoid repeated protected writes.
    local ok, current = pcall(frame.GetAttribute, frame, key)
    if not ok or not A.Access.Readable(current) or current ~= value then frame:SetAttribute(key, value) end
end
function B.Apply()
    if A.startupState == "failed" then return end
    if InCombatLockdown() then B.pending = true; return end
    if A.Runtime.suspended then B.pending = true; return end
    B.pending = nil
    local retry = false
    local recipients = { unpack(A.View.rows) }
    recipients[#recipients + 1] = A.View.target
    recipients[#recipients + 1] = A.View.targetTarget
    for _, frame in ipairs(recipients) do
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
        frame:SetScript("PostClick", B.Feedback)
    end
    for _, prefix in ipairs({ "", "shift-", "ctrl-", "ctrl-shift-", "alt-",
        "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
        for button = 1, 5 do
            -- One transient resolution per combination, shared by its fixed recipients.
            local id, automatic, unavailable
            if B.byId[prefix .. button] then id, automatic, unavailable = B.Effective(prefix .. button) end
            local info, reason, unresolved
            if id then info, reason, unresolved = B.Resolve(id) end
            retry = retry or unavailable == true or unresolved == true
            -- Plain left targets only without an assignment or learned default. Unavailable assignments
            -- and empty modified slots must not fall through to another action.
            local fallback = button == 1 and prefix == "" and id == nil and not unavailable and "target" or ""
            local item = info and info.itemID
            local castName
            if info and not item then
                local rank = A.Access.Read(C_Spell and C_Spell.GetSpellSubtext, id)
                -- Compile only public client text outside combat. Never emit a second
                -- recipient/empty conditional that could invoke automatic self casting.
                if type(rank) == "string" and not info.name:find("[\r\n;%[%]]")
                    and not rank:find("[\r\n;%[%]]") then
                    castName = info.name .. (rank ~= "" and "(" .. rank .. ")" or "")
                end
                if rank == nil and type(C_Spell.GetSpellSubtext) == "function" then retry = true end
            end
            if prefix == "" and button == 1 then
                B.rangeSpell = info and not item and id or nil
            end
            for _, frame in ipairs(recipients) do
                setActionAttribute(frame, prefix .. "type" .. button,
                    info and (item and "item" or (castName and "macro" or "")) or fallback)
                setActionAttribute(frame, prefix .. "macrotext" .. button, castName
                    and "/cast [@" .. frame.unit .. ",exists,help] " .. castName .. "\n/stopspelltarget" or nil)
                setActionAttribute(frame, prefix .. "spell" .. button, info and not item and id or nil)
                setActionAttribute(frame, prefix .. "item" .. button, item and "item:" .. item or nil)
            end
        end
    end
    -- Arm recovery before cosmetic refreshes, which must not strand disabled actions.
    retryWhenReady(retry)
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
