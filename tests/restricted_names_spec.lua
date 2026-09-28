local m=dofile("tests/mock.lua").New()
m.units.target={name="Enemy",health=50,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
m.units.targettarget={name="Tank",health=80,maxHealth=100,power=0,maxPower=0,kind=0,auras={}}
local a=m.Start()
local secretName,secretSurname=m.Secret(),m.Secret()
m.combat=true
for _, row in ipairs({a.View.target,a.View.targetTarget}) do
    local anchor,attributes=row.point,row.attributes
    local label=row.name
    local formatted=label.SetFormattedText
    -- This stub is the native sink boundary: record opaque arguments without
    -- emulating restricted string formatting in ordinary Lua.
    label.SetFormattedText=function(self,pattern,...)
        self.nativeFormat={pattern,...}
        if not issecretvalue(select(1,...)) then formatted(self,pattern,...) end
    end
    m.units[row.unit].name=secretName
    m.units[row.unit].surname=nil
    m.Event("UNIT_NAME_UPDATE",row.unit)
    assert(rawequal(label.text,secretName))
    m.units[row.unit].surname="Public Surname"
    m.Event("UNIT_NAME_UPDATE",row.unit)
    assert(label.nativeFormat[1]=="%s%s%s" and rawequal(label.nativeFormat[2],secretName))
    assert(label.nativeFormat[3]==" " and label.nativeFormat[4]=="Public Surname")
    m.units[row.unit].surname=secretSurname
    m.Event("UNIT_NAME_UPDATE",row.unit)
    assert(rawequal(label.text,secretName))
    m.units[row.unit].name="Public Name"
    m.Event("UNIT_NAME_UPDATE",row.unit)
    assert(label.text=="Public Name")
    m.units[row.unit].surname="Restored"
    m.Event("UNIT_NAME_UPDATE",row.unit)
    assert(label.text=="Public Name Restored")
    assert(row.point==anchor and row.attributes==attributes and row.attributes.unit==row.unit)
end
local label=a.View.target.name
UnitName=function() error("unavailable") end
a.View.RefreshTarget();assert(label.text=="")
UnitName=function() return nil end
a.View.RefreshTarget();assert(label.text=="")
UnitName=function() return "" end
a.View.RefreshTarget();assert(label.text=="")
UnitName=function() return secretName end
local setter=label.SetText
label.SetText=function(self,value)
    if issecretvalue(value) then error("native sink unavailable") end
    setter(self,value)
end
a.View.RefreshTarget();assert(label.text=="")
local root=os.getenv("APOGEE_FOREVER_EXPORT")
if root and root~="" then
    local file=assert(io.open(root.."/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua","rb"))
    local source=file:read("*a");file:close()
    for _, method in ipairs({"SetText","SetFormattedText"}) do
        local declaration=assert(source:match('Name = "'..method..'",(.-)\n%s*Arguments ='))
        assert(declaration:find('SecretArguments = "AllowedWhenTainted"',1,true))
        assert(declaration:find('SecretArgumentsAddAspect = { Enum.SecretAspect.Text }',1,true))
    end
    print("PASS matching-export FontString restricted text sink contracts")
end
print("PASS restricted target names reach native sinks, optional surname fallback, combat events, recovery and unavailable inputs")
