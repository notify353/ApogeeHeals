local Fixture=dofile("tests/purify_fixture.lua")
local m,a=Fixture.New()
assert(not a.Cleansing.failed and #m.cleanseContainers==5)
for index,container in ipairs(m.cleanseContainers) do
    local row=a.View.rows[index];local button=container.nativeButton
    assert(container.nativeUnit==row.unit and container.nativeEnabled)
    assert(button.attributes.unit==row.unit and button.attributes.spell1==1152)
    assert(button.attributes.type1=="spell" and button.attributes.useOnKeyDown==false)
    assert(button.clicks[1]=="LeftButtonUp" and #button.clicks==1)
    assert(button.attributes["shift-type1"]=="" and button.attributes["alt-type1"]=="")
    assert(row.cleanseHost.driver=="[group:raid] hide; [@"..row.unit..",exists,nodead,help] show; hide")
    assert(not button.shown and row.cleanseButton==nil)
    assert(button.width==12 and button.height==12 and row.cleanseHost.point[1]=="RIGHT")
end
local row=a.View.rows[1]
a.Buffs.Paint(row,{{id=19740,icon=1}})
assert(row.cleanseHost.point[4]==-17 and row.buffOverflow.point[4]==-75)
a.Buffs.Paint(row,{{id=1,icon=1},{id=2,icon=2},{id=3,icon=3},{id=4,icon=4},{id=5,icon=5}})
assert(row.cleanseHost.point[4]==-59 and row.buffOverflow.shown)
local frozenPoint=row.cleanseHost.point
local before=m.auraReads
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");m.Flush()
assert(row.cleanseHost.point==frozenPoint)
for _,container in ipairs(m.cleanseContainers) do
    m.NativePoison(container.nativeUnit,"Poison");assert(container.nativeButton.shown)
    m.NativePoison(container.nativeUnit,"Disease");assert(not container.nativeButton.shown)
    m.NativePoison(container.nativeUnit,"Magic");assert(not container.nativeButton.shown)
end
a.Cleansing.pending=true;a.Cleansing.Refresh()
assert(m.auraReads==before and a.Cleansing.pending and #m.cleanseContainers==5)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
assert(not a.Cleansing.pending and not a.Cleansing.failed and #m.cleanseContainers==5)
print("PASS native-only poison handoff, fixed-unit Purify setup and no addon aura reads/button access in combat")

a.View.SetUnlocked(true)
for _,row in ipairs(a.View.rows) do assert(row.cleanseHost.driver=="hide") end
a.View.SetUnlocked(false)
for _,row in ipairs(a.View.rows) do assert(row.cleanseHost.driver~="hide") end
m.known=false;m.Event("SPELLS_CHANGED");m.Flush()
for _,row in ipairs(a.View.rows) do assert(row.cleanseHost.driver=="hide") end
m.known=true;m.Event("SPELLS_CHANGED");m.Flush()
for _,row in ipairs(a.View.rows) do assert(row.cleanseHost.driver~="hide") end
assert(#m.cleanseContainers==5)
m.Event("GROUP_ROSTER_UPDATE");m.Flush()
assert(#m.cleanseContainers==5)
print("PASS preview/learned-spell gating and fixed token reuse without post-handoff native button mutation")

for _,options in ipairs({{class="PRIEST"},{known=false},{noTemplates=true},{secretTemplates=true},{helpful=false}}) do
    m,a=Fixture.New(options);assert(#m.cleanseContainers==0 and not a.Cleansing.failed)
end
m,a=Fixture.New({unprotected=true})
assert(a.Cleansing.failed and #m.cleanseContainers==1 and a.View.rows[1].cleanseHost.driver=="hide")
a.Cleansing.pending=true;a.Cleansing.Refresh();assert(#m.cleanseContainers==1)
print("PASS unavailable/unlearned/restricted/native-template failures have no active fallback hitbox")
