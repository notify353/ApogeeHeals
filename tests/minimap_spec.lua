local registered,refreshes,removed
ApogeeUI={apiVersion=1,RegisterComponent=function(id,p) assert(id=="heals"); registered=p end,
    RefreshComponent=function(id) assert(id=="heals"); refreshes=true end,
    UnregisterComponent=function(id) assert(id=="heals"); removed=true end}
local open=false
local A={started=true,Settings={category={}},BindingEditor={frame={IsShown=function() return open end},
    Open=function() open=true end,Close=function() open=false end}}
assert(loadfile("UI/Minimap.lua"))("ApogeeHeals",A)
A.Minimap.Create(); assert(registered and registered.category==A.Settings.category and registered.available())
local reset=false
A.Settings.ResetPositions=function() reset=true end
registered.resetPositions(); assert(reset)
local action=registered.actions[1]; assert(action.label=="Healing bindings" and action.primary==true)
action.run(); assert(open and action.checked()); action.run(); assert(not open)
A.Minimap.Refresh(); assert(refreshes); A.Minimap.ResetPosition(); assert(not A.Minimap.button)
A.started=false; assert(not registered.available()); A.Minimap.Unregister(); assert(removed)
ApogeeUI.apiVersion=2; registered=nil; A.started=true; A.Minimap.Create(); assert(not registered)
print("PASS Heals launcher registration, editor callback, deactivation and no private button")
