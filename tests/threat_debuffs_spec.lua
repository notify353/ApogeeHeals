local Mock=dofile("tests/mock.lua")
local m=Mock.New(); local a=m.Start(); local row=a.ThreatView.rows[1]
local names={[7386]="Sunder Armor",[1160]="Demoralizing Shout",[6343]="Thunder Clap"}
C_Spell.GetSpellInfo=function(id) return names[id] and {name=names[id]} end
local list={}
C_UnitAuras.GetAuraDataByIndex=function(unit,index,filter)
    assert(unit=="nameplate1" and filter=="HARMFUL"); return list[index]
end
UnitIsUnit=function(source,player) return source=="playerAlias" end
local function paint() a.ThreatModel.PaintDebuffs(row,"nameplate1") end
paint(); assert(row.debuffs[1].text=="S-" and row.debuffs[2].text=="D-" and row.debuffs[3].text=="T-")
list={{name=names[7386],spellId=999,sourceUnit="player",applications=3},
    {name=names[1160],sourceUnit="playerAlias"},{name=names[6343],sourceUnit="party1"}}
paint(); assert(row.debuffs[1].text=="S3" and row.debuffs[2].text=="D+" and row.debuffs[3].text=="T-")
list[1].applications=5; list[3].sourceUnit="player"; paint()
assert(row.debuffs[1].text=="S5" and row.debuffs[3].text=="T+")
list[1].sourceUnit=m.Secret(); paint(); assert(row.debuffs[1].text=="S?")
list[1].sourceUnit="player"; local count=m.Secret(); list[1].applications=count
local original=row.debuffs[1].SetFormattedText
row.debuffs[1].SetFormattedText=function(_,fmt,value) assert(fmt=="S%d" and rawequal(value,count)) end
paint(); row.debuffs[1].SetFormattedText=original
list={m.Secret()}; paint()
for _,label in ipairs(row.debuffs) do assert(label.text:sub(-1)=="?") end
list={{name=m.Secret()}}; paint(); assert(row.debuffs[1].text=="S?")
C_UnitAuras.GetAuraDataByIndex=function() error("no aura access") end
paint(); assert(row.debuffs[2].text=="D?")
C_UnitAuras.GetAuraDataByIndex=function() return {name="Unrelated"} end
paint(); assert(row.debuffs[3].text=="T?") -- truncated scan cannot prove absence
C_UnitAuras.GetAuraDataByIndex=function() return nil end
C_Spell.GetSpellInfo=function() return nil end
paint(); assert(row.debuffs[1].text=="S?")
a.ThreatView.ClearRow(row); for _,label in ipairs(row.debuffs) do assert(label.text=="") end
print("PASS per-enemy debuffs: rank names, ownership, stack updates, native secret count, unavailable/incomplete scans and cleanup")
