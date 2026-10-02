local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local a = m.Start()
local d = a.ThreatDiagnostics
local reads = 0
local mode = "public"
local secret = m.Secret()
UnitDetailedThreatSituation = function(player, unit)
    assert(player == "player" and unit == "target"); reads = reads + 1
    if mode == "error" then error("API failure") end
    if mode == "missing" then return end
    if mode == "secret" then return secret, secret, secret, secret, secret end
    return false, 0, 0, 12.5, 50
end
UnitThreatLeadSituation = function() return 3 end
UnitThreatPercentageOfLead = function() return mode == "secret" and secret or 25 end
assert(not d.enabled and not d.root.shown and not d.frame.scripts.OnUpdate)
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); assert(reads == 0)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
a.Settings.threatDiagnostics:SetChecked(true)
a.Settings.threatDiagnostics.scripts.OnClick(a.Settings.threatDiagnostics)
assert(d.enabled and d.root.shown and a.db.threatEnabled == nil and reads == 0)
assert(not d.frame.scripts.OnUpdate and d.rows[1].access.text == "--")
m.units.target = {hostile=true, dead=false}
m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(reads == 1 and d.rows[1].access.text == "PASS" and d.rows[1].sink.text == "PASS")
assert(d.rows[3].access.text == "PASS") -- zero is a valid reading
local accepted = 0
d.numberSink.SetFormattedText = function(_, pattern, value)
    assert(pattern == "%.2f"); accepted = accepted + 1
    -- Native sink simulation accepts the secret without inspecting it.
end
C_CurveUtil = {EvaluateColorValueFromBoolean=function(value, yes, no)
    assert(issecretvalue(value)); return secret
end}
mode = "secret"; d.Refresh()
assert(accepted == 6 and d.rows[1].access.text == "FAIL" and d.rows[1].sink.text == "PASS")
assert(d.rows[1].reason.text == "Restricted" and d.rows[3].reason.text == "Restricted")
mode = "public"; d.Refresh(); assert(d.rows[1].access.text == "FAIL")
d.numberSink.SetFormattedText = function() error("sink rejected") end
d.Refresh(); assert(d.rows[5].sink.text == "FAIL")
local before = reads
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
assert(not d.collecting and not d.frame.scripts.OnUpdate and d.context.text:find("FROZEN",1,true))
mode = "missing"; m.Event("PLAYER_TARGET_CHANGED"); m.Event("UNIT_THREAT_LIST_UPDATE")
assert(reads == before and d.rows[5].sink.text == "FAIL" and d.rows[1].reason.text == "Restricted")
assert(d.numberSink.text == "" and d.booleanSink.alpha == 0)
m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(d.rows[1].reason.text == "Missing" and d.rows[1].access.text == "FAIL")
d.SetEnabled(false); assert(d.enabled) -- no combat edits
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
m.units.target = nil; m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
assert(d.rows[1].access.text == "--")
m.units.target = {hostile=false, dead=false}; d.Refresh(); assert(d.rows[1].access.text == "--")
m.units.target = {hostile=true, dead=true}; d.Refresh(); assert(d.rows[1].access.text == "--")
m.units.target.dead = false; mode = "error"; d.Refresh()
assert(d.rows[1].reason.text == "API error")
before = reads; m.Event("PLAYER_LEAVING_WORLD"); d.Refresh(); assert(reads == before)
assert(not d.frame.scripts.OnUpdate)
m.combat = false; m.Event("PLAYER_ENTERING_WORLD")
assert(reads == before and d.rows[1].reason.text == "API error")
d.SetEnabled(false); assert(not d.root.shown and not d.frame.scripts.OnUpdate)
d.SetEnabled(true); a.ResetCharacter(); assert(not d.enabled)
assert(a.db.threatDiagnostics == nil)
print("PASS threat diagnostics: combat-only, secret-safe native probes, latched failures, frozen results, reset and lifecycle")
