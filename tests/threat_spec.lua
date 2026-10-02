local Mock = dofile("tests/mock.lua")
local function setup(saved, useDefaults)
    if saved == nil and not useDefaults then saved = {version=3,threatEnabled=true} end
    local m = Mock.New()
    m.threatReads, m.leadReads, m.pairReads = 0, 0, 0
    UnitDetailedThreatSituation = function(player, unit)
        assert(player == "player"); m.threatReads = m.threatReads + 1
        if m.threatError then error("unavailable") end
        local data = m.units[unit]
        if data then return data.tanking, data.threatStatus, data.percent, data.percent, data.amount end
    end
    UnitThreatLeadSituation = function(player, unit)
        assert(player == "player"); m.leadReads = m.leadReads + 1
        if m.leadError then error("unavailable") end
        return m.units[unit] and m.units[unit].lead
    end
    UnitThreatPercentageOfLead = function(player, unit)
        assert(player == "player")
        return m.units[unit] and m.units[unit].leadPercent
    end
    GetRaidTargetIndex = function(unit) return m.units[unit] and m.units[unit].marker end
    UnitIsUnit = function(first, second)
        m.pairReads = m.pairReads + 1
        if m.matchError then error("incomparable") end
        if m.secretMatch then return m.secretMatch end
        return m.units[first] ~= nil and m.units[first] == m.units[second]
    end
    C_NamePlate = {GetNamePlates=function() return m.plates or {} end}
    local a=m.Load(); ApogeeHealsDB=saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    function m.Mob(index, tanking, status, lead)
        local token = "nameplate" .. index
        m.units[token] = {name="Mob " .. index, hostile=true, tanking=tanking, threatStatus=status,
            lead=lead, leadPercent=150, health=50, maxHealth=100, power=0, maxPower=0, kind=0, auras={}}
        m.Event("NAME_PLATE_UNIT_ADDED", token); return token
    end
    function m.Target(token)
        m.units.target = token and m.units[token] or nil
        m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    end
    return m,a,a.Threat,a.ThreatView
end
local m,a,r,v=setup()
assert(#v.rows==8 and #v.gates==7 and v.root.parent==UIParent and not v.root.protected)
assert(v.rows[1].kind=="Frame" and v.rows[1].mouse==false and next(v.rows[1].attributes)==nil)
assert(v.root.scale==a.Style.scale and v.rows[1].name.font[2]==6)
local unit=m.Mob(1,true,3,0)
assert(v.rows[1].warning.text=="LEAD")
for _,lead in ipairs({1,2}) do
    m.units[unit].lead=lead; m.Event("UNIT_THREAT_SITUATION_UPDATE",unit)
    assert(v.rows[1].warning.text=="WEAK LEAD")
end
m.units[unit].lead=3; m.Event("UNIT_THREAT_LIST_UPDATE",unit)
assert(v.rows[1].warning.text=="NO LEAD") -- Still tanking, despite losing first place.
m.units[unit].tanking=false; m.Event("UNIT_THREAT_LIST_UPDATE",unit)
assert(v.rows[1].warning.text=="NO AGGRO")
m.units[unit].lead=0; m.Event("UNIT_THREAT_LIST_UPDATE",unit)
assert(v.rows[1].warning.text=="NO AGGRO") -- Never imply safety from lead alone.
print("PASS tank lead warning states distinguish weakening lead, lost first place and lost aggro")

for _,field in ipairs({"lead","threatStatus","tanking"}) do
    m.units[unit].lead=0; m.units[unit].threatStatus=3; m.units[unit].tanking=true
    m.units[unit][field]=m.Secret(); m.Event("UNIT_THREAT_LIST_UPDATE",unit)
    local expected=field=="lead" and "UNKNOWN" or "LEAD"
    assert(v.rows[1].warning.text==expected)
end
m.units[unit].threatStatus=3; m.units[unit].tanking=true
for _,value in ipairs({-1,4,0/0,math.huge,"0"}) do
    m.units[unit].lead=value; r.Refresh(); assert(v.rows[1].warning.text=="UNKNOWN")
end
m.units[unit].lead=0
m.threatError=true; r.Refresh(); assert(v.rows[1].warning.text=="LEAD" and v.rows[1].aggro[3].alpha==1)
m.threatError=nil; m.units[unit].lead=0; m.leadError=true
r.Refresh(); assert(v.rows[1].warning.text=="UNKNOWN")
m.leadError=nil; r.Refresh(); assert(v.rows[1].warning.text=="LEAD")
UnitCanAttack=function() return m.Secret() end
r.Refresh(); assert(v.rows[1].warning.text=="UNKNOWN")
UnitCanAttack=function(_,u) return m.units[u] and m.units[u].hostile==true end
m.units[unit].threatStatus=nil; m.units[unit].lead=nil; r.Refresh()
assert(v.rows[1].warning.text=="UNKNOWN" and r.model.slots[1]==unit)
print("PASS restricted, malformed and failed reads clear reassuring warnings; threat wipe remains visible")

-- Native presentation boundaries record opaque inputs without Lua formatting.
m,a,r,v=setup(); unit=m.Mob(1,true,3,0)
local row=v.rows[1]
local nativeFormat=row.warning.SetFormattedText
row.warning.SetFormattedText=function(self,pattern,value)
    if issecretvalue(value) then self.nativePattern=pattern; self.nativeValue=value; self.text="native risk"
    else nativeFormat(self,pattern,value) end
end
row.amount.SetFormattedText=function(self,pattern,value)
    if issecretvalue(value) then self.nativeValue=value; self.text="native amount"
    else nativeFormat(self,pattern,value) end
end
local secretLead,secretAmount,secretAggro=m.Secret(),m.Secret(),m.Secret()
m.units[unit].lead=secretLead; m.units[unit].amount=secretAmount; m.units[unit].tanking=secretAggro
C_CurveUtil.EvaluateColorValueFromBoolean=function(value,yes,no)
    assert(rawequal(value,secretAggro)); return m.Secret()
end
r.Refresh()
assert(row.warning.text=="native risk" and row.warning.nativePattern=="RISK %.0f/3")
assert(rawequal(row.risk.value,secretLead) and row.risk.alpha==1 and row.risk.reverseFill)
assert(row.amount.text=="NO DATA" and row.relative.alpha==0) -- secret selector cannot choose a percentage
assert(issecretvalue(row.aggro[1].alpha) and issecretvalue(row.aggro[2].alpha) and row.aggro[3].alpha==0)
assert(r.model.entries[unit].warning=="unknown")
for _,entry in pairs(r.model.entries) do for _,value in pairs(entry) do assert(not issecretvalue(value)) end end
m.units[unit].amount=42; m.units[unit].tanking=true; m.units[unit].threatStatus=nil; m.units[unit].lead=1
r.Refresh(); assert(row.warning.text=="WEAK LEAD" and row.amount.text=="Relative 150%")
assert(row.aggro[1].alpha==1 and row.aggro[2].alpha==0 and row.aggro[3].alpha==0)
m.units[unit].amount=nil; m.units[unit].tanking=nil; m.units[unit].lead=nil
r.Refresh(); assert(row.amount.text=="NO DATA" and row.warning.text=="UNKNOWN" and row.risk.alpha==0 and row.risk.value==0)
assert(row.aggro[1].alpha==0 and row.aggro[2].alpha==0 and row.aggro[3].alpha==1)
m.units[unit].lead=secretLead; row.warning.SetFormattedText=function() error("sink unavailable") end
r.Refresh(); assert(row.warning.text=="UNKNOWN" and row.risk.alpha==0)
m.Event("NAME_PLATE_UNIT_REMOVED",unit)
assert(row.amount.text=="" and row.risk.alpha==0 and row.risk.value==0 and row.aggro[3].alpha==0)
print("PASS independent solo lead, native opaque risk/aggro sinks, secret selector fallback and stale-data cleanup")

m,a,r,v=setup(); unit=m.Mob(1,true,3,0); row=v.rows[1]
assert(row.relative.min==0 and row.relative.max==200 and row.relative.reverseFill==false)
for _,percent in ipairs({90,100,125,200,350}) do
    m.units[unit].leadPercent=percent; r.Refresh()
    assert(row.relative.value==percent and row.relative.alpha==1)
    assert(row.amount.text=="Relative "..percent.."%")
end
m.units[unit].leadPercent=0; r.Refresh()
assert(row.amount.text=="NO COMPARISON" and row.relative.alpha==0 and row.relative.value==0)
m.units[unit].tanking=false; m.units[unit].percent=80; m.units[unit].lead=3; r.Refresh()
assert(row.relative.value==80 and row.warning.text=="NO AGGRO" and row.relative.color[1]==0.86)
m.units[unit].percent=0; r.Refresh(); assert(row.relative.alpha==1 and row.amount.text=="Relative 0%")
local opaque=m.Secret(); m.units[unit].percent=opaque
row.amount.SetFormattedText=function(self,pattern,value)
    assert(pattern=="Relative %.0f%%" and rawequal(value,opaque)); self.text="native relative"
end
r.Refresh(); assert(rawequal(row.relative.value,opaque) and row.relative.alpha==1)
row.amount.SetFormattedText=function() error("native text rejected") end
r.Refresh(); assert(row.relative.alpha==0 and row.relative.value==0 and row.amount.text=="NO DATA")
m.units[unit].percent=-1; r.Refresh(); assert(row.relative.alpha==0)
m.units[unit].percent=nil; r.Refresh(); assert(row.relative.alpha==0)
m.units[unit].tanking=true; UnitThreatPercentageOfLead=nil; r.Refresh(); assert(row.relative.alpha==0)
m.Event("NAME_PLATE_UNIT_REMOVED",unit); assert(row.relative.alpha==0 and row.relative.value==0)
print("PASS native-selected relative bars: direction, fixed scale, no-comparison zero, lost aggro, opaque sinks and clearing")

m,a,r,v=setup()
for i=1,10 do m.Mob(i,true,3,0) end
for i=1,7 do assert(r.model.slots[i]=="nameplate"..i) end
assert(v.footer.text=="+3 more")
local slots={unpack(r.model.slots)}
m.combat=true
for i=1,7 do
    m.Target("nameplate"..i)
    assert(v.rows[i].selection.alpha==1 and v.gates[i].alpha==0)
    assert(v.rows[8].unit=="target")
    for j=1,7 do assert(r.model.slots[j]==slots[j]) end
end
m.Target("nameplate9")
assert(v.rows[8].name.text=="Mob 9" and v.rows[8].selection.alpha==1 and v.footer.text=="+2 more")
for i=1,7 do assert(v.gates[i].alpha==1 and v.rows[i].selection.alpha==0) end
m.units.nameplate4.lead=3; r.Refresh()
for i=1,7 do assert(r.model.slots[i]==slots[i]) end
m.Event("NAME_PLATE_UNIT_REMOVED","nameplate3")
assert(r.model.entries.nameplate3==nil and r.model.slots[3]=="nameplate8")
assert(r.model.slots[4]=="nameplate4" and v.rows[3].name.text=="Mob 8")
m.units.nameplate3={name="Replacement", hostile=true, tanking=false, threatStatus=0,lead=3,
    health=50,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
m.Event("NAME_PLATE_UNIT_ADDED","nameplate3")
assert(r.model.entries.nameplate3.warning=="noAggro" and r.model.entries.nameplate3.order==11)
m.Mob(55,true,3,1); assert(r.model.entries.nameplate55.warning=="weak")
print("PASS stable seven slots, reserved overflow target, counts, departures and token reuse without threat sorting")

m,a,r,v=setup()
unit=m.Mob(1,true,3,0); m.combat=true; m.Target(unit)
m.units[unit].name=m.Secret(); m.units[unit].marker=m.Secret(); r.Refresh()
assert(rawequal(v.rows[1].name.text,m.units[unit].name) and v.rows[1].marker.alpha==0)
m.units[unit].name="Marked"; m.units[unit].marker=8; r.Refresh()
assert(v.rows[1].marker.alpha==1 and v.rows[1].marker.texCoord[1]==0.75)
m.units[unit].marker=nil; r.Refresh(); assert(v.rows[1].marker.alpha==0)
m.secretMatch=m.Secret()
local calls=0
C_CurveUtil.EvaluateColorValueFromBoolean=function(value,yes,no)
    assert(rawequal(value,m.secretMatch)); calls=calls+1
    return m.Secret() -- Engine boundary only; alpha sink accepts the opaque result.
end
r.Refresh()
assert(calls==2 and issecretvalue(v.rows[1].selection.alpha) and issecretvalue(v.gates[1].alpha))
assert(r.model.slots[1]==unit and not issecretvalue(r.model.entries[unit].warning))
C_CurveUtil.EvaluateColorValueFromBoolean=nil
r.Refresh(); assert(v.rows[1].selection.alpha==0 and v.rows[8].alpha==0 and v.footer.text=="Target match unknown")
m.secretMatch=nil; m.matchError=true; r.Refresh()
assert(v.rows[1].selection.alpha==0 and v.rows[8].alpha==0)
m.matchError=nil; r.Refresh(); assert(v.rows[1].selection.alpha==1 and v.gates[1].alpha==0)
print("PASS secret names and target comparisons use native sinks; unknown identity never guesses a target")

m,a,r,v=setup()
unit=m.Mob(1,true,3,0)
local anchors={}
for i,row in ipairs(v.rows) do anchors[i]=row.point end
v.handle.scripts.OnDragStart(); assert(v.moving)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not v.moving and not v.root.moving)
v.handle.scripts.OnDragStart(); assert(not v.moving)
r.SetEnabled(false); assert(a.db.threatEnabled==true)
local reads=m.threatReads; r.frame.scripts.OnUpdate(r.frame,0.19); assert(m.threatReads==reads)
r.frame.scripts.OnUpdate(r.frame,0.01); assert(m.threatReads==reads+2)
for i,row in ipairs(v.rows) do assert(row.point==anchors[i] and next(row.attributes)==nil) end
m.Event("PLAYER_LEAVING_WORLD")
assert(next(r.model.entries)==nil and r.frame.scripts.OnUpdate==nil and not v.root.shown)
reads=m.threatReads; m.Event("UNIT_THREAT_LIST_UPDATE",unit); assert(m.threatReads==reads)
m.combat=false
m.plates={{IsForbidden=function() return false end, GetUnit=function() return unit end},
    {IsForbidden=function() return true end, GetUnit=function() error("forbidden read") end}}
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
assert(v.root.shown and v.rows[1].name.text=="Mob 1" and r.frame.scripts.OnUpdate)
r.SetEnabled(false); assert(not v.root.shown and r.frame.scripts.OnUpdate==nil and next(r.model.entries)==nil)
reads=m.threatReads; m.Event("NAME_PLATE_UNIT_ADDED",unit); assert(m.threatReads==reads)
r.SetEnabled(true); assert(v.root.shown and r.model.slots[1]==unit)
v.handle.scripts.OnDragStart(); v.root.left=100; v.root.top=600
v.handle.scripts.OnDragStop(); assert(a.db.threatPosition.x==-380 and a.db.threatPosition.y==330)
v.Place(); assert(v.root.point[4]==-380 and v.root.point[5]==330)
local saved=a.db
m,a,r,v=setup(saved); assert(v.root.point[4]==-380 and v.root.point[5]==330)
a.Settings.ResetPositions(); assert(a.db.threatPosition==nil and v.root.point[4]==-100)
r.SetEnabled(false); a.ResetCharacter(); assert(a.db.threatEnabled==nil and not v.root.shown)
assert(a.Settings.threat.checked==false and r.frame.scripts.OnUpdate==nil)
local clean=a.Storage.Open({version=3,threatPosition={x=0/0,y=1},threatEnabled="true",bindings={["2"]=2050}})
assert(clean.threatPosition==nil and clean.threatEnabled==nil and clean.bindings["2"]==2050)
m,a,r,v=setup({version=3,threatEnabled=false}); assert(not v.root.shown and r.frame.scripts.OnUpdate==nil)
print("PASS combat-safe fixed geometry, bounded polling, zoning/bootstrap, toggle, position persistence and reset isolation")

m,a,r,v=setup()
unit=m.Mob(1,true,3,0); m.combat=true; m.Target(unit)
m.units[unit].threatStatus=nil; m.units[unit].lead=nil; r.Refresh()
assert(v.rows[1].warning.text=="UNKNOWN" and v.rows[8].warning.text=="UNKNOWN")
m.units[unit].dead=true; r.Refresh(); assert(v.rows[1].alpha==0 and v.rows[8].alpha==0)
m.units[unit].dead=nil; m.units[unit].hostile=false; r.Refresh(); assert(v.rows[8].alpha==0)
m.units.target={name="Untouched",hostile=true,health=50,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
m.combat=false; m.Event("PLAYER_REGEN_ENABLED")
assert(v.rows[8].alpha==0 and v.rows[8].name.text=="" and v.rows[8].warning.text=="")
m.Event("PLAYER_TARGET_CHANGED"); assert(v.rows[8].alpha==0)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
r.Refresh(); assert(v.rows[8].warning.text=="UNKNOWN" and v.rows[8].alpha==1)
UnitDetailedThreatSituation=nil; r.Refresh(); assert(v.rows[8].warning.text=="UNKNOWN")
m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); assert(v.rows[8].alpha==0)
print("PASS idle target suppression, combat target switching, dead/friendly cleanup and missing API fallback")

m,a,r,v=setup(nil,true)
assert(a.db.threatEnabled==nil and not v.root.shown and a.Settings.threat.checked==false)
assert(r.frame.scripts.OnUpdate==nil and m.threatReads==0 and m.leadReads==0)
m.Mob(1,true,3,0); m.Event("UNIT_THREAT_LIST_UPDATE","nameplate1")
assert(next(r.model.entries)==nil and m.threatReads==0 and m.leadReads==0)
a.Settings.threat:SetChecked(true); a.Settings.threat.scripts.OnClick(a.Settings.threat)
assert(a.db.threatEnabled==true and v.root.shown and a.Settings.threat.checked==true and r.frame.scripts.OnUpdate)
local savedEnabled=a.db
m,a,r,v=setup(savedEnabled); assert(v.root.shown and a.Settings.threat.checked==true)
a.Settings.threat:SetChecked(false); a.Settings.threat.scripts.OnClick(a.Settings.threat)
assert(a.db.threatEnabled==false and not v.root.shown and r.frame.scripts.OnUpdate==nil)
local savedDisabled=a.db
m,a,r,v=setup(savedDisabled); assert(not v.root.shown and a.Settings.threat.checked==false)
print("PASS default-off threat has no polling/reads; settings checkbox opt-in and explicit choices persist")
