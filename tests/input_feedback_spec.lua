local m=dofile("tests/mock.lua").New();local a=m.Start()
local E=a.BindingEditor
local recipients={unpack(a.View.rows)};recipients[#recipients+1]=a.View.target;recipients[#recipients+1]=a.View.targetTarget
-- Feedback never creates or opens an editor as a side effect.
a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
assert(E.frame==nil)
E.Open();m.Flush()
local nativeTimer=C_Timer.After
C_Timer.After=function(delay,callback) assert(delay==0.15);nativeTimer(delay,callback) end
local names={"LeftButton","RightButton","MiddleButton","Button4","Button5"}
for _,row in ipairs(recipients) do
    local unit,action=row.attributes.unit,row.attributes.type1
    for _,prefix in ipairs({"","shift-","ctrl-"}) do
        m.shift=prefix=="shift-";m.ctrl=prefix=="ctrl-"
        for index,name in ipairs(names) do
            local tile=E.buttons[prefix..index]
            row.scripts.PostClick(row,name,true);assert(not tile.inputFlash.shown)
            row.scripts.PostClick(row,name,false);assert(tile.inputFlash.shown)
            assert(tile.inputFlash.color[1]==0.35 and tile.inputFlash.color[2]==0.75 and tile.inputFlash.color[4]==0.4)
            m.Flush();assert(not tile.inputFlash.shown)
        end
    end
    assert(row.attributes.unit==unit and row.attributes.type1==action and row.scripts.OnClick==nil)
end
m.shift=false;m.ctrl=false
E.buttons["1"].scripts.OnClick();assert(E.buttons["1"].inputFlash.shown)
local old=table.remove(m.timers,1)
a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
old();assert(E.buttons["1"].inputFlash.shown)
m.Flush();assert(not E.buttons["1"].inputFlash.shown)
m.alt=true;a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
assert(#m.timers==0)
m.alt=false;m.ctrl=true;m.shift=true;a.View.target.scripts.PostClick(a.View.target,"RightButton",false)
assert(#m.timers==0)
m.ctrl=m.Secret();a.View.target.scripts.PostClick(a.View.target,"LeftButton",false);assert(#m.timers==0)
m.ctrl=false;m.shift=false
a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
assert(E.buttons["1"].inputFlash.shown)
E.Close();assert(not E.buttons["1"].inputFlash.shown)
a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
m.Flush();assert(not E.frame.shown and not E.buttons["1"].inputFlash.shown)
E.Open();m.combat=true;C_Timer.After=nativeTimer
m.Event("PLAYER_REGEN_DISABLED");m.Flush()
a.View.target.scripts.PostClick(a.View.target,"LeftButton",false)
assert(not E.frame.shown and not E.buttons["1"].inputFlash.shown)
assert(a.View.target.attributes.unit=="target" and a.View.targetTarget.attributes.unit=="targettarget")
print("PASS matching Keybinds input flash, all recipients/modifiers, rapid presses, hidden editor and native action isolation")
