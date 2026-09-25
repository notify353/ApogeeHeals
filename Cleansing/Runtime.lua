local _, A = ...
local P = { pending = true }
A.Cleansing = P
-- Live build 70009 rejects SecureActionButtonTemplate on intrinsic AuraButton:
-- its forbidden OnClick cannot be replaced. Template presence and pcall do not
-- detect this non-throwing XML warning. Do not construct the rejected control.
function P.Refresh()
    if InCombatLockdown() or not P.pending or not A.View.rows then return end
    P.pending = nil
    P.status = "Poison-triggered Purify is unavailable on this client."
    if A.Settings and A.Settings.cleanseStatus then A.Settings.cleanseStatus:SetText(P.status) end
end
