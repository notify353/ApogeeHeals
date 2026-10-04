local m = dofile("tests/mock.lua").New()
local oldSet, oldAvailable = SetRaidTarget, GetNextAvailableRaidTargetMarkerIndex
local calls = 0
SetRaidTarget = function() calls=calls+1; error("Native marking blocked") end
GetNextAvailableRaidTargetMarkerIndex = function() calls=calls+1; return 8 end
local a = m.Start()
a.db.threatEnabled = true
m.units.target = {hostile=true,dead=false,connected=true,health=100,maxHealth=100,kind=0,maxPower=100}
m.units.nameplate1 = m.units.target
m.combat = true
for _,event in ipairs({"PLAYER_TARGET_CHANGED","NAME_PLATE_UNIT_ADDED","PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED","UNIT_THREAT_LIST_UPDATE"}) do m.Event(event,"nameplate1") end
for _,frame in ipairs(m.frames) do
    if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,3) end
end
m.combat = false
m.Event("PLAYER_REGEN_ENABLED"); m.Event("PLAYER_LEAVING_WORLD")
assert(calls==0 and a.ThreatMarkers.frame==nil)
SetRaidTarget, GetNextAvailableRaidTargetMarkerIndex = oldSet, oldAvailable
print("PASS blocked automatic marking is inert at startup, target/combat events and periodic refresh")
