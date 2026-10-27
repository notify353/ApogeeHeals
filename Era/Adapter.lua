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

-- Era has public aura records, but no Forever CustomAuraContainerTemplate.
-- Keep the same player-owned warrior families and fixed preallocated artwork;
-- the shared threat refresh/lifecycle still owns row ordering and scheduling.
local threatFamilies = {
    [7386]=1,[7405]=1,[8380]=1,[11596]=1,[11597]=1,
    [6343]=2,[8198]=2,[8204]=2,[8205]=2,[11580]=2,[11581]=2,
    [1160]=3,[6190]=3,[11554]=3,[11555]=3,[11556]=3,
}
function A.ThreatView.PrepareDebuffs()
    -- The fixed icon/count regions already exist before combat. No native
    -- aura containers or protected geometry are created for this Era display.
end
function A.ThreatModel.PaintDebuffs(row, unit)
    for i=1,3 do
        row.demoIcons[i]:Hide(); row.demoFrames[i]:Hide()
        row.debuffs[i]:SetText(""); row.debuffs[i]:Hide()
    end
    row.demoCount:SetText(""); row.demoCount:Hide(); row.debuffUnit=nil
    if not A.Access.Readable(unit) or type(unit)~="string" or not unit:match("^nameplate%d+$")
        or not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex)~="function" then return end
    local found, complete = {}, false
    -- Read at most 64 auras plus a terminating probe. Failed, unreadable or
    -- truncated snapshots never retain a stale icon or claim an absent effect.
    for index=1,65 do
        local ok, aura=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,"HARMFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok or not A.Access.Readable(aura) then return end
        if aura==nil then complete=true; break end
        if index==65 or type(aura)~="table" or not A.Access.Readable(aura.spellId) then return end
        local family=type(aura.spellId)=="number" and threatFamilies[aura.spellId]
        if family and not found[family] then
            if not A.Access.Readable(aura.sourceUnit) then return end
            local own=type(aura.sourceUnit)=="string" and A.Access.Read(UnitIsUnit,aura.sourceUnit,"player")
            if own==true then
                local count=aura.applications
                local public=A.Access.Readable(count) and type(count)=="number"
                    and count==count and count>=0 and count<math.huge and count%1==0
                found[family]={count=public and (count>1 and tostring(count) or "") or "?"}
            end
        end
    end
    if not complete then return end
    row.debuffUnit=unit
    for family, data in pairs(found) do
        row.demoIcons[family]:SetAlpha(1)
        row.demoIcons[family]:Show(); row.demoFrames[family]:Show()
        if family==1 then
            row.demoCount:SetText(data.count); row.demoCount:SetShown(data.count~="")
        end
    end
end
