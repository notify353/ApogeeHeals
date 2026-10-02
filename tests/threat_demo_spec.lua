local Mock = dofile("tests/mock.lua")
local m = Mock.New()
local reads = 0
UnitDetailedThreatSituation = function() reads=reads+1; return true,3,100,100,500 end
UnitThreatLeadSituation = function() reads=reads+1; return 0 end
UnitThreatPercentageOfLead = function() reads=reads+1; return 150 end
local a = m.Start()
local r,v = a.Threat,a.ThreatView
assert(not r.demo and not v.root.shown)
a.Settings.threatDemo:SetChecked(true); a.Settings.threatDemo.scripts.OnClick(a.Settings.threatDemo)
assert(r.demo and v.root.shown and a.db.threatEnabled==nil and reads==0)
assert(v.title.text:find("DEMO",1,true) and v.footer.text:find("DEMO",1,true))
assert(v.rows[1].relative.value==220 and v.rows[3].warning.text=="WEAK LEAD")
assert(v.rows[4].warning.text=="NO LEAD" and v.rows[5].warning.text=="NO AGGRO")
assert(v.rows[6].amount.text=="NO DATA" and v.rows[7].amount.text=="NO COMPARISON")
assert(v.rows[8].selection.alpha==1)
for _,row in ipairs(v.rows) do assert(row.unit==nil and not row.protected and next(row.attributes)==nil) end
assert(next(r.model.entries)==nil and next(r.exposed)==nil)
m.Event("PLAYER_TARGET_CHANGED"); m.Event("NAME_PLATE_UNIT_ADDED","nameplate1")
assert(reads==0 and next(r.model.entries)==nil)
r.frame.scripts.OnUpdate(r.frame,12)
assert(v.rows[2].relative.value==70 and v.rows[2].warning.text=="NO AGGRO")
r.frame.scripts.OnUpdate(r.frame,12)
assert(v.rows[2].relative.value==180 and v.rows[2].warning.text=="LEAD" and reads==0)
r.SetDemo(false)
assert(not v.root.shown and not r.frame.scripts.OnUpdate and a.db.threatEnabled==nil)
r.SetDemo(true); m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not r.demo and not v.root.shown and not a.Settings.threatDemo.checked)
r.SetDemo(true); assert(not r.demo)
m.combat=false; m.Event("PLAYER_REGEN_ENABLED")
m.units.nameplate1={name="Actual enemy",hostile=true,dead=false}
C_NamePlate={GetNamePlates=function() return {{IsForbidden=function() return false end,
    GetUnit=function() return "nameplate1" end}} end}
r.SetEnabled(true); assert(v.rows[1].unit=="nameplate1")
r.SetDemo(true); local before=reads
r.Refresh(); r.frame.scripts.OnUpdate(r.frame,0.2); assert(reads==before)
r.SetDemo(false)
assert(a.db.threatEnabled==true and v.rows[1].unit=="nameplate1" and v.rows[1].name.text=="Actual enemy")
r.SetDemo(true); m.Event("PLAYER_LEAVING_WORLD")
assert(not r.demo and not v.root.shown and not r.frame.scripts.OnUpdate)
m.Event("PLAYER_ENTERING_WORLD"); assert(not r.demo and v.rows[1].unit=="nameplate1")
r.SetDemo(true); a.ResetCharacter()
assert(not r.demo and not v.root.shown and a.db.threatDemo==nil)
print("PASS solo threat demo: shared rows, scripted animation, zero threat reads, isolation, stop/restore, combat/world/default cleanup")
