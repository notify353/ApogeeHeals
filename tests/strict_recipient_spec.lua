local m = dofile("tests/mock.lua").New()
C_Spell.GetSpellInfo = function(id) return {name="Lesser Heal",iconID=1,spellID=id} end
C_Spell.GetSpellSubtext = function(id) return id == 2050 and "Rank 1" or "Rank 2" end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
Enum.SpellBookSpellBank = {Player=0}
C_SpellBook = {IsSpellInSpellBook=function() return true end, IsSpellKnown=function() return true end}
local a = m.Start()
assert(a.Bindings.Put("1",2050) and a.Bindings.Put("2",2052))
local recipients = {unpack(a.View.rows)}
recipients[#recipients+1]=a.View.target; recipients[#recipients+1]=a.View.targetTarget
for _,row in ipairs(recipients) do
    assert(row.attributes.type1=="macro" and row.attributes.type2=="macro")
    assert(row.attributes.macrotext1=="/cast [@"..row.unit..",exists,help] Lesser Heal(Rank 1)\n/stopspelltarget")
    assert(row.attributes.macrotext2=="/cast [@"..row.unit..",exists,help] Lesser Heal(Rank 2)\n/stopspelltarget")
    assert(not row.attributes.macrotext1:find(";",1,true))
    assert(row.attributes["alt-macrotext1"]==nil and row.attributes["ctrl-shift-macrotext2"]==nil)
end
local party=a.View.rows[2]
-- Replacement and removal must clear the old program, including item assignments.
C_Item={GetItemInfoInstant=function(id) return id,nil,nil,nil,1,0,7 end,
    GetItemNameByID=function() return "Bandage" end}
Enum.ItemClass={Consumable=0}; Enum.ItemConsumableSubclass={Bandage=7}
assert(a.Bindings.Put("2",{kind="item",id=1251}))
assert(party.attributes.type2=="item" and party.attributes.macrotext2==nil)
assert(a.Bindings.Put("2",nil) and party.attributes.macrotext2==nil)
local old=party.attributes.macrotext1
m.combat=true
assert(not a.Bindings.Put("1",2052))
C_Spell.GetSpellSubtext=function() return "Rank 3" end
m.Event("SPELL_TEXT_UPDATE")
assert(party.attributes.macrotext1==old)
m.combat=false; m.Event("PLAYER_REGEN_ENABLED")
assert(party.attributes.macrotext1:find("Rank 3",1,true))
C_Spell.GetSpellSubtext=function() return m.Secret() end
m.Event("SPELL_TEXT_UPDATE")
assert(party.attributes.type1=="" and party.attributes.macrotext1==nil)
C_Spell.GetSpellSubtext=function() return "Rank 1\n/cast Heal" end
a.Bindings.Apply()
assert(party.attributes.type1=="" and party.attributes.macrotext1==nil)
C_Spell.GetSpellSubtext=function() return "Rank 1" end
m.Event("SPELL_TEXT_UPDATE")
assert(party.attributes.type1=="macro")

local root=os.getenv("APOGEE_FOREVER_EXPORT")
if root and root~="" then
    local f=assert(io.open(root.."/Blizzard_FrameXML/SecureTemplates.lua","rb"))
    local source=f:read("*a"):gsub("\r\n","\n"); f:close()
    local action=assert(source:match("SECURE_ACTIONS%.macro%s*=%s*(function.-\n    end);"))
    local invoked
    local env=setmetatable({
        SecureButton_GetModifiedAttribute=function(frame,key) return frame.attributes[key.."1"] end,
        C_Macro={RunMacroText=function(text,button) invoked={text,button} end},
        RunMacro=function() error("must not use a saved macro") end,
    },{__index=_G})
    local chunk=assert(loadstring("return "..action)); setfenv(chunk,env)
    local dispatch=chunk()
    for _,row in ipairs(recipients) do
        dispatch(row,row.unit,"LeftButton")
        assert(invoked[1]==row.attributes.macrotext1 and invoked[2]=="LeftButton")
    end
    print("PASS matching Forever macro action dispatches exact fixed-recipient program")
end
print("PASS strict recipients, explicit ranks, self row, modifier isolation, stale program clearing and combat/text deferral")
-- The engine owns macro condition parsing, range, line of sight and auto-self-cast.
-- These checks deliberately do not pretend to emulate that closed native behavior.
