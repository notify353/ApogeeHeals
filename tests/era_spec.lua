local M=dofile("tests/mock.lua").New()
local runtime=os.getenv("APOGEE_ERA_RUNTIME_ROOT")
local name=runtime and "ApogeeHealsDev" or "ApogeeHeals"
local prefix=runtime and runtime.."/" or ""
local A={__ApogeeClient="classic-era",__ApogeeFamilyAdmission=function(n) return n==name end}
WOW_PROJECT_ID=2; WOW_PROJECT_CLASSIC=2
GetBuildInfo=function() return "1.15.9","70003","",11509 end
Enum.SpellBookSpellBank={Player=0}
C_SpellBook={IsSpellInSpellBook=function(id) return id==2050 end,IsSpellKnown=function(id) return id==2050 end}
C_Spell.GetSpellInfo=function(id) return {name="Heal",iconID=123,spellID=id} end
C_Spell.IsSpellHelpful=function() return true end
C_Spell.IsSpellHarmful=function() return false end
C_Spell.IsSpellPassive=function() return false end
GetSpellBookItemInfo=function(slot,bank) assert(bank=="spell"); return slot==3 and "SPELL" or "FUTURESPELL",2050 end
for line in io.lines(prefix..(runtime and name..".toc" or name.."_Era.toc")) do
    if line:match("%.lua$") and not line:match("^__Distribution/") then assert(loadfile(prefix..line))(name,A) end
end
M.addon=A; M.Event("ADDON_LOADED",name); M.Flush()
assert(A.db and #A.View.rows==5,"Era frames must start")
assert(not A.View.targetActions,"No partial native inspection strip")
M.cursor={"spell",3,"spell"}; assert(A.Bindings.Cursor()==2050)
M.cursor={"spell",3,"pet"}; assert(A.Bindings.Cursor()==nil)
M.cursor={"spell",4,"spell"}; assert(A.Bindings.Cursor()==nil)
local label={SetText=function(self,value) self.text=value end}
UnitName=function() return "Player","AnotherRealm" end
A.UnitAPI.PaintFullName(label,"party1"); assert(label.text=="Player")
assert(A.Bindings.Put("2",2050))
local before=A.View.rows[2].attributes.macrotext2
assert(before and before:find("@party1",1,true),"Strict recipient preserved")
M.combat=true; A.Bindings.Apply(); assert(A.Bindings.pending)
assert(A.View.rows[2].attributes.macrotext2==before,"No protected combat rewrite")
print("PASS Era Heals startup, legacy spell slots, fixed recipients, combat deferral and realm formatting")
