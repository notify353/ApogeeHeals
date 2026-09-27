local Mock = dofile("tests/mock.lua")
local oldDuration, oldString = C_DurationUtil, C_StringUtil
local m = Mock.New()
local bindings, requests = {}, {}
Enum.NumericRuleFormatRounding = {Up=1}
C_StringUtil = {CreateNumericRuleFormatter=function()
    return {
        AddBreakpoint=function(_, rule)
            assert(rule.threshold == 0 and rule.step == 1 and rule.rounding == 1 and rule.format == "%.0f")
        end,
    }
end}
local nativeDuration = setmetatable({}, {__index=function() error("addon inspected native duration") end})
C_DurationUtil = {CreateDurationTextBinding=function()
    local b = {}
    function b:SetEnabled(value) self.enabled = value end
    function b:SetFontString(value) self.text = value end
    function b:SetFormatter(value) self.formatter = value end
    function b:SetExpiredText(value) assert(value == "") end
    function b:SetZeroDurationText(value) assert(value == "") end
    function b:SetUpdateInterval(value) assert(value == 0.1) end
    function b:SetDuration(value) assert(value == nativeDuration); self.duration = value end
    function b:UpdateFontString() assert(self.duration == nativeDuration); self.text:SetText("30") end
    bindings[#bindings + 1] = b
    return b
end}
C_UnitAuras.GetAuraDuration = function(unit, instance)
    requests[#requests + 1] = {unit, instance}
    if m.failDuration then error("expired aura") end
    return nativeDuration
end
local a = m.Start()
assert(#bindings == 5 and not a.Preview.rows[1].drinkTimer and not a.View.target.drinkTimer)
for index, row in ipairs(a.View.rows) do
    m.units[row.unit] = m.units[row.unit] or {connected=true, dead=false, auras={}}
    m.units[row.unit].auras = {{spellId=430, name="Drink", auraInstanceID=100 + index}}
    a.Drinking.Clear(row); a.Drinking.Paint(row)
    assert(row.drinkIcon.shown and row.drinkTimer.enabled and row.drinkTimeText.text == "30")
    assert(requests[#requests][1] == row.unit and requests[#requests][2] == 100 + index)
end
local row = a.View.rows[1]
local function refresh()
    a.Drinking.Clear(row); a.Drinking.Paint(row)
end
m.failDuration = true; refresh()
assert(row.drinkIcon.shown and not row.drinkTimer.enabled and row.drinkTimeText.text == "")
m.failDuration = false
m.units.player.auras[1].auraInstanceID = nil; refresh()
assert(row.drinkIcon.shown and not row.drinkTimer.enabled)
m.units.player.auras[1].auraInstanceID = 101; refresh()
m.units.player.auras = {}; refresh()
assert(not row.drinkIcon.shown and not row.drinkTimer.enabled and row.drinkTimeText.text == "")
m.units.player.auras = {{spellId=430, name="Drink", auraInstanceID=101}}
refresh(); m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(not row.drinkIcon.shown and not row.drinkTimer.enabled)
m.combat = false; refresh(); m.Event("PLAYER_LEAVING_WORLD")
assert(not row.drinkIcon.shown and not row.drinkTimer.enabled)
m.auraError = true; refresh()
assert(not row.drinkIcon.shown and not row.drinkTimer.enabled)
C_DurationUtil, C_StringUtil = nil, nil
local without = Mock.New().Start()
assert(without.started and not without.View.rows[1].drinkTimer)
C_DurationUtil, C_StringUtil = oldDuration, oldString
print("PASS native drink remaining-time binding, fixed recipients, no duration reads, stop/combat/zoning cleanup and optional API fallback")
