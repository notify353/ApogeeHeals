-- Era has public aura records but no native CustomAuraContainerTemplate.
-- Keep secure cleansing actions shared; only ordinary artwork is client-specific.
local _, A = ...
if A.__ApogeeClient ~= "classic-era" then return end
local E, V, P, R = {}, A.View, A.Cleansing, A.Access.Read
A.EraPartyAuras = E
local hovered
local function hideTooltip(frame)
    if GameTooltip and GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end
local function tooltip(frame)
    if InCombatLockdown() or not frame.auraID or not GameTooltip
        or type(GameTooltip.SetUnitAuraByAuraInstanceID) ~= "function" then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local ok = pcall(GameTooltip.SetUnitAuraByAuraInstanceID, GameTooltip, frame.unit, frame.auraID)
    if not ok then hideTooltip(frame) end
end
function E.Clear(row)
    for _, frame in ipairs(row.eraDebuffs or {}) do
        hideTooltip(frame); frame.auraID=nil; frame:SetAlpha(0)
    end
    for _, button in ipairs(row.cleanseButtons or {}) do
        if button.eraGlow then
            button.eraGlow:SetAlpha(0)
            button.icon:SetDesaturated(true); button.icon:SetAlpha(0.3)
        end
    end
end
local function snapshot(unit)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then return end
    local icons, types = {}, {}
    for index=1,65 do
        local ok, aura=pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HARMFUL")
        if not ok or not A.Access.Readable(aura) then return end
        if aura==nil then return icons, types end
        if index==65 or type(aura)~="table" or not A.Access.Readable(aura.icon, aura.dispelName)
            or type(aura.icon)~="number" or aura.icon<=0 or aura.icon>=math.huge or aura.icon%1~=0
            or (aura.dispelName~=nil and type(aura.dispelName)~="string") then return end
        if aura.dispelName then types[aura.dispelName]=true end
        if #icons<8 then
            local id = aura.auraInstanceID
            icons[#icons+1]={icon=aura.icon, id=A.Access.Readable(id) and type(id)=="number" and id or nil}
        end
    end
end
function E.Refresh()
    for _, row in ipairs(V.supportRows or {}) do
        E.Clear(row)
        local eligible=not A.Runtime.suspended and not V.unlocked and A.UnitAPI.State(row.unit)=="alive"
        if row.unit=="target" then eligible=eligible and R(UnitCanAssist,"player","target")==true end
        if eligible then
            local icons, types=snapshot(row.unit)
            if icons then
                for index, aura in ipairs(icons) do
                    local frame=row.eraDebuffs and row.eraDebuffs[index]
                    if frame then frame.icon:SetTexture(aura.icon);frame.auraID=aura.id;frame:SetAlpha(1) end
                end
                for index, button in ipairs(row.cleanseButtons or {}) do
                    if button.eraGlow and button.spell then
                        for kind in pairs(row.cleanseSpells[index].types) do
                            if types[kind] then
                                button.eraGlow:SetAlpha(1)
                                button.icon:SetDesaturated(false);button.icon:SetAlpha(1)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if hovered and hovered.auraID then tooltip(hovered) end
end
local create=V.Create
function V.Create()
    create()
    local S=A.Style
    for _, row in ipairs(V.supportRows) do
        -- Prefer the existing native path if a future reviewed Era provides it.
        if not row.debuffContainer then
            row.eraDebuffs={}
            local offset=(row.unit=="target" and S.sideIconGap or S.sideIconOffset)
                +(row.cleanseSlotCount or 0)*(S.sideIconSize+S.sideIconGap)
            for index=1,8 do
                local frame=CreateFrame("Frame",nil,row.supportFrame or row)
                frame.unit=row.unit
                frame:SetSize(S.sideIconSize,S.sideIconSize)
                frame:SetPoint("TOPLEFT",row.health,"TOPRIGHT",offset+(index-1)*(S.sideIconSize+S.sideIconGap),S.sideIconY)
                frame:EnableMouse(false);frame:SetMouseMotionEnabled(true)
                local background=frame:CreateTexture(nil,"BACKGROUND")
                background:SetAllPoints();background:SetColorTexture(0.35,0.08,0.08,1)
                frame.icon=frame:CreateTexture(nil,"ARTWORK")
                frame.icon:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-1)
                frame.icon:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1)
                frame.icon:SetTexCoord(0.07,0.93,0.07,0.93)
                frame:SetScript("OnEnter",function(self) hovered=self;tooltip(self) end)
                local function leave(self)
                    if hovered==self then hovered=nil end
                    hideTooltip(self)
                end
                frame:SetScript("OnLeave",leave)
                frame:SetScript("OnHide",leave)
                frame:SetAlpha(0)
                row.eraDebuffs[index]=frame
            end
        end
        if not row.cleanseIndicator then
            for _, button in ipairs(row.cleanseButtons or {}) do
                button.eraGlow=button:CreateTexture(nil,"BACKGROUND")
                button.eraGlow:SetAllPoints();button.eraGlow:SetColorTexture(1,0.75,0.1,0.85)
                button.eraGlow:SetAlpha(0)
            end
        end
    end
    local driver=CreateFrame("Frame")
    driver:RegisterEvent("PLAYER_LEAVING_WORLD")
    driver:SetScript("OnEvent",function()
        hovered=nil
        for _,row in ipairs(V.supportRows) do E.Clear(row) end
    end)
end
-- The shared coalesced unit/roster/spell/combat refresh calls this even when
-- secure action rebuilding is deferred. Never change actions from aura data.
local refresh=P.Refresh
function P.Refresh()
    refresh()
    E.Refresh()
    if P.status=="Cleansing buttons available; native glow unavailable." then
        P.status="Cleansing buttons glow for matching debuff types."
        if A.Settings and A.Settings.cleanseStatus then A.Settings.cleanseStatus:SetText(P.status) end
    end
end
local targetAuras=V.RefreshTargetAuras
function V.RefreshTargetAuras()
    E.Clear(V.target)
    targetAuras()
end
