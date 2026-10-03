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
local unit=m.Mob(1,true,3,0)
local row=v.rows[1]
assert(#v.rows==8 and v.gates==nil and not row.protected and next(row.attributes)==nil)
assert(row.left.reverseFill and not row.right.reverseFill and row.left.width==row.right.width)
assert(row.left.height==7 and row.health==nil and row.height==7)
assert(row.right.value==50 and row.left.value==0 and row.notice.text=="")
for _,case in ipairs({{0,100,0},{70,30,0},{95,5,0},{100,0,0},{112,0,12},{150,0,50},{250,0,100}}) do
    assert(v.PaintCentered(row,case[1])); assert(row.left.value==case[2] and row.right.value==case[3])
end
local leftPoint,rightPoint=row.left.point,row.right.point
m.combat=true
for _,percent in ipairs({75,100,160}) do
    m.units[unit].leadPercent=percent; r.Refresh()
    assert(row.left.point==leftPoint and row.right.point==rightPoint)
end
m.units[unit].lead=3; m.units[unit].leadPercent=95; r.Refresh()
assert(r.model.entries[unit].warning=="noLead" and row.left.value==0 and row.notice.text=="")
m.units[unit].tanking=false; m.units[unit].percent=70; r.Refresh()
assert(r.model.entries[unit].warning=="noAggro" and row.notice.text=="LOST" and row.left.value==30)
m.units[unit].lead=0; r.Refresh(); assert(row.notice.text=="LOST")
m.units[unit].tanking=true; m.units[unit].leadPercent=0; r.Refresh()
assert(row.notice.text=="-" and row.left.value==0 and row.right.value==0)
-- Owner solo capture: tanking=true, status=3, scaled=100, raw=255,
-- threat=1299, lead warning=0, lead percentage=0 must never become a deficit.
m.units[unit].percent=255; m.units[unit].amount=1299; r.Refresh()
assert(row.left.value==0 and row.right.value==0 and row.notice.text=="-")
local opaque=m.Secret(); m.units[unit].leadPercent=opaque; r.Refresh()
assert(row.notice.text=="" and row.left.value==0 and row.right.value==0)
assert(row.nativeTank.alpha==1 and row.nativeTank.mask.value==100
    and rawequal(row.nativeTank.right.value,opaque) and row.nativeRaw.alpha==0)
m.units[unit].leadPercent=150; m.units[unit].tanking=opaque; r.Refresh()
assert(row.notice.text=="?" and row.left.value==0 and row.right.value==0)
local nativeAlphas={m.Secret(),m.Secret()}
C_CurveUtil.EvaluateColorValueFromBoolean=function(value,yes,no)
    assert(rawequal(value,opaque))
    return yes==1 and nativeAlphas[1] or nativeAlphas[2]
end
m.units[unit].percent=70; r.Refresh()
assert(row.notice.text=="" and rawequal(row.nativeTank.alpha,nativeAlphas[1])
    and rawequal(row.nativeRaw.alpha,nativeAlphas[2]))
assert(row.nativeTank.mask.value==100 and row.nativeTank.right.value==150)
assert(row.nativeRaw.mask.value==70 and row.nativeRaw.right.value==70)
assert(row.nativeTank.mask.min==0 and row.nativeTank.mask.max==100)
assert(row.nativeTank.right.min==100 and row.nativeTank.right.max==200)
assert(not row.nativeTank.mask.reverseFill and row.nativeTank.fill.width==row.left.width)
-- Missing data blanks only its own native lane; never reuse stale fill.
m.units[unit].leadPercent=nil; r.Refresh()
assert(row.nativeTank.notice.text=="?" and row.nativeTank.mask.value==100
    and row.nativeTank.right.value==100 and row.nativeRaw.mask.value==70)
m.units[unit].tanking=true; m.units[unit].leadPercent=150; r.Refresh()
assert(row.nativeTank.alpha==0 and row.nativeRaw.alpha==0 and row.right.value==50)
C_CurveUtil.EvaluateColorValueFromBoolean=nil
for _,bad in ipairs({-1,math.huge,0/0,"150",false}) do
    m.units[unit].leadPercent=bad; r.Refresh(); assert(row.notice.text=="?" and row.right.value==0)
end
m.units[unit].leadPercent=nil; r.Refresh(); assert(row.notice.text=="?")
UnitThreatPercentageOfLead=nil; r.Refresh(); assert(row.notice.text=="?")
assert(a.ThreatModel.Classify(0,true,3)=="lead")
assert(a.ThreatModel.Classify(1,true,3)=="weak" and a.ThreatModel.Classify(2,true,3)=="weak")
assert(a.ThreatModel.Classify(3,true,3)=="noLead" and a.ThreatModel.Classify(3,false,0)=="noAggro")
assert(a.ThreatModel.Classify(opaque,true,3)=="unknown")
print("PASS centered threat: both directions, empty equality, capped ends, independent aggro loss and guarded restricted arithmetic")

m,a,r,v=setup(); unit=m.Mob(1,true,3,0); row=v.rows[1]
assert(row.health==nil and row.background.color[1]==0.10)
m.units[unit].maxPower=200; m.units[unit].level=20; r.Refresh()
assert(row.background.color[3]==0.32 and row.level==nil and row.name==nil)
assert(row.nativeTank.mask.color[3]==0.32 and row.nativeRaw.mask.color[3]==0.32 and row.rail==nil)
m.units[unit].kind=1; r.Refresh(); assert(row.background.color[1]==0.10)
m.units[unit].kind=0; m.units[unit].maxPower=m.Secret(); r.Refresh(); assert(row.background.color[1]==0.10)
m.Event("NAME_PLATE_UNIT_REMOVED",unit)
assert(row.left.value==0 and row.right.value==0 and row.health==nil and row.name==nil and row.level==nil)
print("PASS threat-only rows, mana-type background and stale-data cleanup")

m,a,r,v=setup()
for i=1,10 do m.Mob(i,true,3,0) end
for i=1,8 do assert(r.model.slots[i]=="nameplate"..i) end
assert(v.footer.text=="+2 more")
local slots={unpack(r.model.slots)}
m.combat=true
for i=1,8 do
    m.Target("nameplate"..i)
    assert(v.rows[i].selection.alpha==1)
    for j=1,8 do assert(r.model.slots[j]==slots[j] and v.rows[j].unit==slots[j]) end
end
m.Target("nameplate9")
assert(v.rows[8].unit=="nameplate8" and v.rows[8].selection.alpha==0 and v.footer.text=="+2 more")
m.units.nameplate4.lead=3; r.Refresh()
for i=1,8 do assert(r.model.slots[i]==slots[i]) end
m.Event("NAME_PLATE_UNIT_REMOVED","nameplate3")
assert(r.model.entries.nameplate3==nil and r.model.slots[3]=="nameplate9")
assert(v.rows[3].selection.alpha==1 and r.model.slots[4]=="nameplate4")
m.units.nameplate3={name="Replacement",hostile=true,tanking=false,threatStatus=0,lead=3}
m.Event("NAME_PLATE_UNIT_ADDED","nameplate3")
assert(r.model.entries.nameplate3.warning=="noAggro" and r.model.entries.nameplate3.order==11)
print("PASS eight stable slots; selection never creates or moves rows; overflow fills only vacated slots")

m,a,r,v=setup()
unit=m.Mob(1,true,3,0); m.combat=true; m.Target(unit)
m.units[unit].name=m.Secret(); r.Refresh()
assert(v.rows[1].name==nil and v.rows[1].level==nil)
m.secretMatch=m.Secret()
local calls=0
C_CurveUtil.EvaluateColorValueFromBoolean=function(value,yes,no)
    assert(rawequal(value,m.secretMatch)); calls=calls+1
    return m.Secret() -- Engine boundary only; alpha sink accepts the opaque result.
end
r.Refresh()
assert(calls==1 and issecretvalue(v.rows[1].selection.alpha))
assert(r.model.slots[1]==unit and not issecretvalue(r.model.entries[unit].warning))
C_CurveUtil.EvaluateColorValueFromBoolean=nil
r.Refresh(); assert(v.rows[1].selection.alpha==0 and v.rows[8].alpha==0 and v.footer.text=="Target match unknown")
m.secretMatch=nil; m.matchError=true; r.Refresh()
assert(v.rows[1].selection.alpha==0 and v.rows[8].alpha==0)
m.matchError=nil; r.Refresh(); assert(v.rows[1].selection.alpha==1 and v.rows[1].alpha==1)
print("PASS nameless rows and native secret target comparisons; unknown identity never guesses a target")

m,a,r,v=setup()
unit=m.Mob(1,true,3,0)
local anchors={}
for i,row in ipairs(v.rows) do anchors[i]=row.point end
assert(not v.root.movable and not v.handle.mouse and not v.handle.scripts.OnDragStart)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not v.moving and not v.root.moving)
assert(not v.moving and v.title.alpha==0 and v.footer.alpha==0)
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
assert(v.root.shown and v.rows[1].unit=="nameplate1" and r.frame.scripts.OnUpdate)
r.SetEnabled(false); assert(not v.root.shown and r.frame.scripts.OnUpdate==nil and next(r.model.entries)==nil)
reads=m.threatReads; m.Event("NAME_PLATE_UNIT_ADDED",unit); assert(m.threatReads==reads)
r.SetEnabled(true); assert(v.root.shown and r.model.slots[1]==unit)
a.db.threatPosition={x=-380,y=330}
v.Place(); assert(v.root.point[1]=="TOPLEFT" and v.root.point[4]==-32 and v.root.point[5]==3.5)
local saved=a.db
m,a,r,v=setup(saved); assert(v.root.point[4]==-32 and v.root.point[5]==3.5)
a.Settings.ResetPositions(); assert(a.db.threatPosition==nil and v.root.point[4]==-32)
r.SetEnabled(false); a.ResetCharacter(); assert(a.db.threatEnabled==nil and not v.root.shown)
assert(a.Settings.threat.checked==false and r.frame.scripts.OnUpdate==nil)
local clean=a.Storage.Open({version=3,threatPosition={x=0/0,y=1},threatEnabled="true",bindings={["2"]=2050}})
assert(clean.threatPosition==nil and clean.threatEnabled==nil and clean.bindings["2"]==2050)
m,a,r,v=setup({version=3,threatEnabled=false}); assert(not v.root.shown and r.frame.scripts.OnUpdate==nil)
print("PASS combat-safe fixed geometry, bounded polling, zoning/bootstrap, toggle, fixed center and reset isolation")

-- Reproduce target-before-damage: no bottom placeholder; acquisition uses one
-- stable row and later threat changes/target switches cannot move it.
m,a,r,v=setup(); m.combat=true
m.units.nameplate1={hostile=true}; m.Event("NAME_PLATE_UNIT_ADDED","nameplate1")
m.Target("nameplate1")
for _,row in ipairs(v.rows) do assert(row.alpha==0) end
m.units.nameplate1.threatStatus=3; m.units.nameplate1.tanking=true
m.units.nameplate1.lead=0; m.units.nameplate1.leadPercent=150
m.Event("UNIT_THREAT_LIST_UPDATE","nameplate1")
assert(v.rows[1].unit=="nameplate1" and v.rows[1].selection.alpha==1 and v.rows[8].alpha==0)
local anchor=v.rows[1].point
m.units.nameplate1.threatStatus=nil; m.units.nameplate1.lead=nil; r.Refresh()
assert(v.rows[1].unit=="nameplate1" and v.rows[1].point==anchor and v.rows[1].notice.text=="?")
m.Target(nil); assert(v.rows[1].unit=="nameplate1" and v.rows[1].selection.alpha==0)
m.Target("nameplate1"); assert(v.rows[1].selection.alpha==1 and v.rows[1].point==anchor)
m.units.nameplate1.dead=true; r.Refresh(); assert(v.rows[1].alpha==0)
print("PASS target-before-damage stays on one row; missing readings and selection never relocate it")

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

-- Empty-state text stays internal; the owner requested no visible heading/footer.
m,a,r,v=setup()
assert(v.root.shown and v.footer.alpha==0 and v.title.alpha==0 and v.footer.text=="Idle - no tracked enemies")
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(v.footer.text=="No tracked enemies - show nameplates")
unit=m.Mob(1,true,3,0); m.Target(unit)
assert(v.rows[1].alpha==1 and v.footer.text=="")
m.units[unit].dead=true; r.Refresh()
assert(v.footer.text=="No tracked enemies - show nameplates")
m.combat=false; m.Event("PLAYER_REGEN_ENABLED")
assert(v.footer.text=="Idle - no tracked enemies")
print("PASS empty threat state explains idle/combat and clears when an enemy is tracked")
