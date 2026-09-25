local Mock = dofile("tests/mock.lua")
local function setup(saved)
    local m = Mock.New()
    local oldResizeCalls = 0
    Minimap:SetScript("OnSizeChanged", function() oldResizeCalls = oldResizeCalls + 1 end)
    local a = m.Load(); ApogeeHealsDB = saved
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    return m, a, function() return oldResizeCalls end
end
local function close(x,y) assert(math.abs(x-y)<0.000001, tostring(x).." ~= "..tostring(y)) end
local m,a,resizes=setup()
local M,button=a.Minimap,a.Minimap.button
assert(button.width==32 and button.height==32 and button.parent==Minimap)
assert(button.strata=="MEDIUM" and button.level==Minimap:GetFrameLevel()+20)
assert(button.drags[1]=="RightButton" and #button.drags==1)
assert(button.point[1]=="CENTER" and button.point[2]==Minimap and button.point[3]=="CENTER")
close(button.point[4],90*math.cos(math.rad(260)));close(button.point[5],90*math.sin(math.rad(260)))
assert(a.db.minimapAngle==nil and button.scripts.OnUpdate==nil)
for _, size in ipairs({{120,120},{140,140},{200,200},{120,200},{200,120},{320,100}}) do
    Minimap.width,Minimap.height=unpack(size)
    local radius=math.max(size[1],size[2])/2+20
    for _, angle in ipairs({0,17,45,90,135,180,190,225,260,270,315,359}) do
        assert(M.Position(angle));local x,y=button.point[4],button.point[5]
        close(math.sqrt(x*x+y*y),radius)
        close(x,radius*math.cos(math.rad(angle)));close(y,radius*math.sin(math.rad(angle)))
    end
    local positions={}
    for _, angle in ipairs({190,225,260}) do
        assert(M.Position(angle)); local x,y=button.point[4],button.point[5]
        close(math.sqrt(x*x+y*y),radius)
        positions[#positions+1]={x,y}
    end
    for i=1,3 do for j=i+1,3 do
        assert(math.abs(positions[i][1]-positions[j][1])>=32 or math.abs(positions[i][2]-positions[j][2])>=32)
    end end
end
assert(a.db.minimapAngle==nil)
local old=button.point;Minimap.width=0;assert(not M.Position() and button.point==old)
Minimap.width=140;Minimap.level=m.Secret();assert(not M.Position() and button.point==old)
Minimap.level=math.huge;assert(not M.Position() and button.point==old)
Minimap.level=1
Minimap.width=m.Secret();assert(not M.Position() and button.point==old)
Minimap.width=140;Minimap.height=0/0;assert(not M.Position() and button.point==old)
Minimap.height=math.huge;assert(not M.Position() and button.point==old)
Minimap.height=140;Minimap.scripts.OnSizeChanged(Minimap)
assert(resizes()==1 and button.point~=old)
print("PASS circular constant-radius orbit and default nonoverlap across sizes/rectangles, finite dimensions and resize hook")

local opened=0;a.Settings.category={GetID=function() return 123 end}
Settings.OpenToCategory=function(id) assert(id==123);opened=opened+1 end
button.scripts.OnMouseDown(button,"RightButton");button.scripts.OnClick(button,"RightButton");assert(opened==1)
button.scripts.OnEnter();assert(GameTooltip.owner==button and GameTooltip.shown)
Minimap.scale=0.5;m.cursorX=(500+100)*0.5;m.cursorY=500*0.5
button.scripts.OnDragStart(button,"LeftButton");assert(not M.dragging)
button.scripts.OnDragStart(button,"RightButton")
assert(M.dragging and button.scripts.OnUpdate and not GameTooltip.shown)
close(a.db.minimapAngle,0);close(button.point[4],90);close(button.point[5],0)
Minimap.scale=2;m.cursorX=500*2;m.cursorY=(500+100)*2;button.scripts.OnUpdate()
close(a.db.minimapAngle,90)
button.scripts.OnDragStop();assert(not M.dragging and not button.scripts.OnUpdate)
button.scripts.OnClick(button,"RightButton");assert(opened==1)
button.scripts.OnMouseDown(button,"RightButton");button.scripts.OnClick(button,"RightButton");assert(opened==2)
-- Also recover when the client emits no click after the drag.
button.scripts.OnDragStart(button,"RightButton");button.scripts.OnDragStop()
button.scripts.OnMouseDown(button,"RightButton");button.scripts.OnClick(button,"RightButton");assert(opened==3)
button.scripts.OnDragStart(button,"RightButton");button.scripts.OnMouseUp(button,"RightButton")
assert(not M.dragging and not button.scripts.OnUpdate)
button.scripts.OnClick(button,"RightButton");assert(opened==3)
local saved=a.db;m,a=setup(saved);M,button=a.Minimap,a.Minimap.button
assert(a.db.minimapAngle==90);close(button.point[4],0);close(button.point[5],90)
for _, angle in ipairs({135,17.5,-30,1080,1e8}) do
    local restored=a.Storage.Open({version=3,minimapAngle=angle})
    assert(restored.minimapAngle==angle)
end
for _, angle in ipairs({0/0,math.huge,-math.huge,"135",{}}) do
    assert(a.Storage.Open({version=3,minimapAngle=angle}).minimapAngle==nil)
end
assert(a.Storage.Open({version=3}).minimapAngle==nil)
print("PASS scale-correct right drag, reload/finite-angle preservation and post-drag click suppression recovery")

local function drag()
    m.cursorX,m.cursorY=400,500
    button.scripts.OnMouseDown(button,"RightButton");button.scripts.OnDragStart(button,"RightButton")
end
drag();local angle=a.db.minimapAngle;old=button.point
m.cursorX=m.Secret();button.scripts.OnUpdate();assert(a.db.minimapAngle==angle and button.point==old)
m.cursorX=400;Minimap.centerX=nil;button.scripts.OnUpdate();assert(a.db.minimapAngle==angle)
Minimap.centerX=m.Secret();button.scripts.OnUpdate();assert(a.db.minimapAngle==angle)
Minimap.centerX=500;Minimap.scale=0;button.scripts.OnUpdate();assert(a.db.minimapAngle==angle)
local scaleGetter=Minimap.GetEffectiveScale
Minimap.GetEffectiveScale=function() return m.Secret() end
button.scripts.OnUpdate();assert(a.db.minimapAngle==angle)
Minimap.GetEffectiveScale=scaleGetter
Minimap.scale=1;m.cursorX,m.cursorY=500,500;button.scripts.OnUpdate();assert(a.db.minimapAngle==angle)
m.combat=true;m.Event("PLAYER_REGEN_DISABLED")
assert(not M.dragging and button.scripts.OnUpdate==nil and not button.enabled)
Minimap.width=200;Minimap.scripts.OnSizeChanged(Minimap);assert(button.point==old)
button.scripts.OnDragStart(button,"RightButton");assert(not M.dragging)
m.combat=false;m.Event("PLAYER_REGEN_ENABLED");assert(button.point~=old and button.enabled)
drag();button:Hide();assert(not M.dragging and not button.scripts.OnUpdate and a.db.minimapAngle==angle)
button:Show();drag();m.Event("PLAYER_LEAVING_WORLD")
assert(not M.dragging and not button.scripts.OnUpdate and a.db.minimapAngle==angle)
old=button.point;Minimap.height=200;Minimap.scripts.OnSizeChanged(Minimap);assert(button.point==old)
m.Event("PLAYER_ENTERING_WORLD");assert(button.point~=old)
old=button.point;m.Event("UI_SCALE_CHANGED");assert(button.point~=old)
old=button.point;m.Event("DISPLAY_SIZE_CHANGED");assert(button.point~=old)
assert(button.scripts.OnUpdate==nil and a.db.minimapAngle==angle)
print("PASS invalid cursor/scale/center guards, combat deferral, cancellation and event-only repositioning")
