local m=dofile("tests/mock.lua").New(); local a=m.Start()
local row=a.View.rows[1]
m.units.player.name="Jane";m.units.player.surname="Silver Moon"
a.View.Refresh();assert(row.name.text=="Jane Silver Moon")
m.combat=true;m.Event("PLAYER_REGEN_DISABLED");m.Flush()
assert(row.name.shown and row.name.text=="Jane Silver Moon")
m.units.target={name="Anduin",surname="Wrynn",health=10,maxHealth=20,power=0,maxPower=0,kind=0,auras={}}
m.units.targettarget={name="Élodie",surname="Dubois",health=10,maxHealth=20,power=0,maxPower=0,kind=0,auras={}}
a.View.RefreshTarget();assert(a.View.target.name.text=="Anduin Wrynn")
assert(a.View.targetTarget.name.text=="Élodie Dubois")
m.units.player.surname=m.Secret();a.View.Refresh();assert(row.name.text=="")
m.units.player.surname=nil;a.View.Refresh();assert(row.name.text=="Jane")
m.units.player.surname="";a.View.Refresh();assert(row.name.text=="Jane")
m.units.player.name="High Priestess of the Moon";a.View.Refresh()
assert(row.name.text=="High Priestess of the Moon")
m.units.player.name=m.Secret();m.units.player.surname="Public";a.View.Refresh();assert(row.name.text=="")
m.units.player.name="Jane";m.units.player.surname="Silver-Moon"
Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR="·"
a.View.Refresh();assert(row.name.text=="Jane·Silver-Moon")
local root=os.getenv("APOGEE_FOREVER_EXPORT")
if root and root~="" then
    local env=setmetatable({}, {__index=_G})
    local native=assert(loadfile(root.."/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua"))
    setfenv(native,env);native()
    assert(a.UnitAPI.FullName("player")==env.NameUtil.FormatUnitNameForDisplay("player"))
    assert(a.UnitAPI.FullName("target")==env.NameUtil.FormatUnitNameForDisplay("target"))
    print("PASS matching Camelot native name/surname composition")
end
print("PASS separate surnames on party and both target rows, combat and restricted identity guards")
