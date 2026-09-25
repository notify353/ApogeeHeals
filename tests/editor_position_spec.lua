local Mock=dofile("tests/mock.lua")
local headerName="ApogeeKeybindsWeaponsHeader"
local otherName=headerName:find("Dev",1,true) and ("ApogeeKeybinds".."WeaponsHeader")
    or ("ApogeeKeybinds".."DevWeaponsHeader")
local function setup(saved,anchor)
    local m=Mock.New();_G[headerName]=nil;_G[otherName]=nil
    if anchor then CreateFrame("Button",headerName,UIParent) end
    local a=m.Load();ApogeeHealsDB=saved
    m.Event("ADDON_LOADED","ApogeeHeals");m.Flush();a.BindingEditor.Open()
    return m,a,a.BindingEditor
end
local m,a,e=setup(nil,true)
local header=_G[headerName]
assert(e.frame.point[1]=="TOPLEFT" and e.frame.point[2]==header
    and e.frame.point[3]=="TOPRIGHT" and e.frame.point[4]==0 and e.frame.point[5]==0)
header:Hide();e.Close();e.Open()
assert(e.frame.shown and not header.shown and e.frame.point[2]==header)
-- Default docking does not write saved coordinates or copy Keybinds state.
assert(a.db.editorPosition==nil)
e.handle.scripts.OnDragStart();e.frame.left=430;e.frame.bottom=270
local movingPoint=e.frame.point;m.Event("UI_SCALE_CHANGED");m.Flush()
assert(e.frame.point==movingPoint)
e.handle.scripts.OnDragStop();assert(a.db.editorPosition.x==430 and a.db.editorPosition.y==270)
local custom=e.frame.point;e.Close();e.Open();m.Event("PLAYER_LOGIN");m.Flush()
assert(e.frame.point==custom and e.customPosition)
local saved=a.db
m,a,e=setup(saved,true)
assert(e.frame.point[1]=="BOTTOMLEFT" and e.frame.point[2]==UIParent
    and e.frame.point[4]==430 and e.frame.point[5]==270)
-- Different scale saves coordinates in UIParent space.
e.handle.scripts.OnDragStart();e.frame.scale=2;e.frame.left=100;e.frame.bottom=120
UIParent.scale=1.5;e.handle.scripts.OnDragStop()
assert(a.db.editorPosition.x==200 and a.db.editorPosition.y==240)
local prior=a.db.editorPosition
e.handle.scripts.OnDragStart();e.frame.left=m.Secret();e.handle.scripts.OnDragStop()
assert(a.db.editorPosition==prior)
m,a,e=setup(nil,false)
CreateFrame("Button",otherName,UIParent);e.Place()
assert(e.frame.point[1]=="CENTER" and e.frame.point[2]==UIParent)
-- Late Keybinds construction after the event is observed on the queued callback.
m.Event("ADDON_LOADED","optional addon")
header=CreateFrame("Button",headerName,UIParent);m.Flush()
assert(e.frame.point[2]==header)
_G[headerName]=m.InaccessibleTable();e.Place();assert(e.frame.point[1]=="CENTER")
_G[headerName]=header
m.combat=true;local before=e.frame.point;e.Place();assert(e.frame.point==before)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush();assert(e.frame.point[2]==header)
for _,position in ipairs({{}, {x=0/0,y=1}, {x=math.huge,y=1}, {x="2",y=1}}) do
    m,a,e=setup({version=3,editorPosition=position},true)
    assert(a.db.editorPosition==nil and e.frame.point[1]=="TOPLEFT")
end
_G[headerName]=nil;_G[otherName]=nil
print("PASS optional same-family header docking, hidden/late/absent anchor, saved/custom/scale guards and combat deferral")
