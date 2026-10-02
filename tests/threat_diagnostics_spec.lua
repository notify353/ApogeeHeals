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
m.units.target = {hostile=true, dead=false}; mode = "public"
d.numberSink.SetFormattedText = function() end
d.SetEnabled(true); m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
for i=1,25 do d.frame.scripts.OnUpdate(d.frame, 0.2) end
assert(d.samples == 26 and d.pollSamples == 25 and d.skipped == 0)
assert(math.abs(d.lastSample-5) < 0.001 and d.firstSample == 0)
m.units.target = nil
for i=1,10 do d.frame.scripts.OnUpdate(d.frame, 0.2) end
assert(d.samples == 26 and d.skipped == 10 and math.abs(d.duration-7) < 0.001)
assert(d.timing.text:find("Longest gap: 2.0s",1,true))
m.units.target = {hostile=true, dead=false}; mode = "missing"
d.frame.scripts.OnUpdate(d.frame, 0.2)
assert(d.rows[1].access.text == "FAIL") -- failure well after entering combat
mode = "public"
for i=1,14 do d.frame.scripts.OnUpdate(d.frame, 0.2) end
assert(d.samples == 41 and d.pollSamples == 40 and math.abs(d.lastSample-10) < 0.001)
assert(d.rows[1].access.text == "FAIL" and math.abs(d.longestGap-2.2) < 0.001)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
local frozenCoverage, frozenTiming = d.coverage.text, d.timing.text
m.Event("PLAYER_TARGET_CHANGED"); m.Event("UNIT_THREAT_LIST_UPDATE")
assert(d.coverage.text == frozenCoverage and d.timing.text == frozenTiming and not d.frame.scripts.OnUpdate)
m.units.target = nil; m.combat = true; m.Event("PLAYER_REGEN_DISABLED")
for i=1,5 do d.frame.scripts.OnUpdate(d.frame, 0.2) end
assert(d.samples == 0 and d.pollSamples == 0 and d.skipped == 6 and d.firstSample == nil)
assert(d.timing.text:find("Time without samples: 1.0s",1,true))
m.combat = false; m.Event("PLAYER_REGEN_ENABLED")
assert(d.context.text:find("NO SAMPLES",1,true))
print("PASS threat diagnostics: combat-only, secret-safe native probes, latched failures, frozen results, reset and lifecycle")
print("PASS combat coverage: repeated polls, late failure, target gaps, elapsed sample times and frozen screenshot counters")
