local Mock=dofile("tests/mock.lua")
local m=Mock.New(); local a=m.Start()
local panel=a.Settings.category.panel
local background,count=nil,0
for _,f in ipairs(m.frames) do
    if f.kind=="Texture" and f.parent==panel then background=f;count=count+1 end
end
assert(count==1 and background.drawLayer=="BACKGROUND" and background.allPoints==panel)
assert(background.color[1]==0.035 and background.color[2]==0.035 and background.color[3]==0.045 and background.color[4]==0.96)
assert(panel.alpha==nil and UIParent.alpha==nil and a.Settings.defaults.alpha==nil)
local frames=#m.frames
panel:SetSize(780,620); panel.scripts.OnShow(); a.Settings.Refresh()
assert(background.allPoints==panel and #m.frames==frames)
m.combat=true; a.Settings.Refresh()
assert(not a.Settings.defaults.enabled and not a.Settings.buffs.enabled)
m.combat=false; a.Settings.Refresh()
assert(a.Settings.defaults.enabled and a.Settings.buffs.enabled)
print("PASS settings-owned background, resize/refresh stability, unchanged alpha and combat controls")
