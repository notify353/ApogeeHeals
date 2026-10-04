local Mock = dofile("tests/mock.lua")
local names = {"IsInRaid","UnitIsGroupLeader","UnitIsGroupAssistant","UnitIsPlayer","CanBeRaidTarget",
    "UnitIsBossMob","UnitClassification","UnitHasPowerType","UnitAffectingCombat","GetRaidTargetIndex",
    "GetNextAvailableRaidTargetMarkerIndex","SetRaidTarget","UnitDetailedThreatSituation","UnitThreatLeadSituation"}
local saved = {}; for _,name in ipairs(names) do saved[name] = _G[name] end
local m = Mock.New()
local owners, calls = {}, {}
local raid, leader, restricted, failed, ignored = false,false,false,false,false
IsInRaid = function() return raid end
UnitIsGroupLeader = function() return leader end
UnitIsGroupAssistant = function() return false end
UnitIsPlayer = function() return false end
CanBeRaidTarget = function() return true end
UnitIsBossMob = function(unit) return m.units[unit].boss == true end
UnitClassification = function(unit) return m.units[unit].classification or "normal" end
UnitHasPowerType = function(unit,power) assert(power==0); return m.units[unit].mana end
UnitAffectingCombat = function(unit) return m.units[unit].engaged == true end
UnitDetailedThreatSituation = function(_,unit)
    if m.units[unit].engaged then return true,3,100,100,100 end
end
UnitThreatLeadSituation = function(_,unit) return m.units[unit].engaged and 0 or nil end
GetRaidTargetIndex = function(unit) return m.units[unit].mark end
GetNextAvailableRaidTargetMarkerIndex = function(index,reverse,wrap,deadAvailable)
    assert(not reverse and not wrap and deadAvailable)
    if restricted then return m.Secret() end
    local owner = owners[index]
    return (not owner or owner.dead or owner.gone) and index or nil
end
SetRaidTarget = function(unit,index)
    calls[#calls+1] = {unit,index}
    if failed then error("blocked") end
    if ignored then return end
    if owners[index] then owners[index].mark = nil end
    owners[index] = m.units[unit]; owners[index].mark = index
end
local a = m.Start(); a.db.threatEnabled = true
local r = a.ThreatMarkers
local function mob(unit,mana,boss,health)
    m.units[unit] = {hostile=true,dead=false,mana=mana,boss=boss,health=health or 100,engaged=true}
    return m.units[unit]
end
local function tick() r.frame.scripts.OnUpdate(r.frame,2.1) end
local first=mob("target",true,false)
local boss=mob("nameplate1",true,true)
local nextMana=mob("nameplate2",true,false)
r.Refresh()
assert(#calls==2 and owners[2]==boss and owners[8]==first)
-- Existing marker remains authoritative even after its nameplate/target vanishes.
mob("target",true,false); m.units.nameplate1=nil
tick(); tick(); assert(#calls==2)
first.dead=true; r.Refresh(); assert(owners[8]==m.units.target and #calls==3)
tick(); m.units.target.dead=true; r.Refresh(); assert(owners[8]==nextMana)
print("PASS circle boss precedence, targeted mana first, sticky offscreen owners and native death handoff")

tick(); nextMana.dead=true; m.units.target=nil
local low=mob("nameplate3",false,false,20)
local high=mob("nameplate4",false,false,80)
local healthAPI=UnitHealth
UnitHealth=function() error("Marking must not read health") end
high.health=m.Secret(); r.Refresh(); assert(#calls==4)
high.health=80; r.Refresh(); assert(#calls==4)
high.mana=m.Secret(); r.Refresh(); assert(#calls==4)
high.mana=true; high.mark=7; r.Refresh(); assert(#calls==4) -- preserve a readable manual mark
high.mark=m.Secret(); high.engaged=false; r.Refresh(); assert(#calls==4)
high.engaged=true; restricted=true; r.Refresh(); assert(#calls==4)
restricted=false; raid=true; r.Refresh(); assert(#calls==4)
leader=true; r.Refresh(); assert(owners[8]==high and #calls==5)
-- Secret existing-icon data must not block assignment to a publicly free icon.
-- Acknowledge immediately, so a fast death is not mistaken for a failed call.
r.Refresh(); assert(r.pending[8]==nil)
high.dead=true; low.mana=false; low.kind=0; low.maxPower=m.Secret()
r.Refresh(); assert(#calls==5)
low.maxPower=100; low.mark=0; r.Refresh(); assert(owners[8]==low and #calls==6)
UnitHealth=healthAPI
print("PASS no health reads/fallback, restricted existing icon, public mana capacity fallback, manual marks and raid permissions")

tick(); low.dead=true; mob("target",true,false)
a.db.threatEnabled=false; r.Refresh(); assert(#calls==6)
a.db.threatEnabled=true; a.Threat.demo=true; r.Refresh(); assert(#calls==6)
a.Threat.demo=false; m.Event("PLAYER_LEAVING_WORLD"); r.Refresh(); assert(#calls==6)
failed=true; m.Event("PLAYER_ENTERING_WORLD"); assert(#calls==7 and r.blocked[8])
tick(); r.Refresh(); assert(#calls==7)
-- A native call can return without throwing but still fail to assign.
r.blocked[8]=nil; r.pending[8]=nil; failed=false; ignored=true
r.Refresh(); assert(#calls==8)
r.Refresh(); assert(not r.blocked[8] and #calls==8)
tick(); assert(r.blocked[8] and #calls==8)
print("PASS off/demo/world suspension, blocked-call and unconfirmed-assignment pause without repeated marking")
for _,name in ipairs(names) do _G[name] = saved[name] end
