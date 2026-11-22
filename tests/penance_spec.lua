local Mock = dofile("tests/mock.lua")
local root = os.getenv("APOGEE_HEALS_RUNTIME_ROOT")
local name = os.getenv("APOGEE_HEALS_RUNTIME_NAME") or "ApogeeHeals"
local ranks = {402174,1240720,1240721,1316995}
local function setup(saved)
    local m = Mock.New()
    m.units.player.class = "PRIEST"
    local state = {helpful=false, harmful=true, passive=false, known=true}
    Enum.SpellBookSpellBank = {Player=0}
    C_SpellBook = {
        IsSpellInSpellBook=function(_,bank,overrides) assert(bank==0 and overrides==false); return state.known end,
        IsSpellKnown=function(_,bank) assert(bank==0); return state.known end,
        GetSpellBookItemInfo=function() return {spellID=state.bookID or ranks[1]} end,
    }
    C_Spell.GetSpellInfo=function(id) return {name="Localized Penance", iconID=123, spellID=id} end
    C_Spell.GetSpellSubtext=function(id)
        for rank,spell in ipairs(ranks) do if id==spell then return "Rank "..rank end end
        return ""
    end
    C_Spell.IsSpellHelpful=function() return state.helpful end
    C_Spell.IsSpellHarmful=function() return state.harmful end
    C_Spell.IsSpellPassive=function() return state.passive end
    local a = {__ApogeeFamilyAdmission=function(candidate) return candidate==name end}
    local prefix = root and root.."/" or ""
    for line in io.lines(prefix..name..".toc") do
        if line:match("%.lua$") and not line:match("^__Distribution/") then
            assert(loadfile(prefix..line))(name,a)
        end
    end
    _G[name.."DB"]=saved or {bindings={},defaultSpells={enabled=false,time=1,serial=0}}
    m.addon=a; m.Event("ADDON_LOADED",name); m.Flush()
    local rows={unpack(a.View.rows)}
    rows[#rows+1]=a.View.target; rows[#rows+1]=a.View.targetTarget
    return m,a,state,rows
end
local m,a,state,rows=setup()
for rank,id in ipairs(ranks) do
    assert(a.Bindings.Resolve(id),"castable Forever Penance rank must accept its harmful/not-helpful flags")
    a.BindingEditor.Open()
    m.cursor={"spell",1,"spell",id}
    a.BindingEditor.buttons["1"].scripts.OnReceiveDrag()
    assert(a.db.bindings["1"]==id and m.cursor==nil,"editor accepts and clears cursor only on success")
    assert(a.BindingEditor.buttons["1"].icon.texture==123)
    for _,slot in ipairs(a.Bindings.slots) do
        assert(a.Bindings.Put(slot.id,id))
        for _,row in ipairs(rows) do
            local key=slot.prefix
            local button=slot.button
            assert(row.attributes[key.."type"..button]=="macro")
            assert(row.attributes[key.."spell"..button]==id)
            assert(row.attributes[key.."macrotext"..button]==
                "/cast [@"..row.unit..",exists,help] Localized Penance(Rank "..rank..")\n/stopspelltarget",
                "exact rank and one fixed friendly recipient, with no hostile/self fallback")
        end
    end
end
-- Spellbook-slot cursors resolve the same wrapper, never a triggered bolt.
state.bookID=ranks[1]; m.cursor={"spell",7,0}
assert(a.Bindings.Cursor()==ranks[1])
m.cursor={"spell",7,"pet",ranks[1]}; assert(not a.Bindings.Cursor())
for _,flags in ipairs({{true,true},{true,false},{false,true},{false,false}}) do
    state.helpful,state.harmful=flags[1],flags[2]
    assert(a.Bindings.Resolve(ranks[1]),"public flags do not invalidate the exact hybrid exception")
end
state.helpful,state.harmful=false,true
for _,id in ipairs({585,527,988,47540,402261,402277,1240732,1316991,1316993,1316994,999999}) do
    assert(not a.Bindings.Resolve(id),"no general harmful-spell, old-client ID or triggered-bolt exception")
end
state.helpful=true; assert(not a.Bindings.Resolve(585),"unrelated dual-purpose flags remain rejected")
state.helpful=false
local previous=a.db.bindings["1"]
m.cursor={"spell",1,"spell",585}
a.BindingEditor.Drop("1")
assert(a.db.bindings["1"]==previous and m.cursor~=nil,"rejected drop preserves the prior binding and cursor")
state.known=false; assert(not a.Bindings.Resolve(ranks[1])); state.known=true
state.passive=true; assert(not a.Bindings.Resolve(ranks[1])); state.passive=false
for _,field in ipairs({"helpful","harmful","passive","known"}) do
    local before=state[field]
    state[field]=m.Secret()
    local info,_,retry=a.Bindings.Resolve(ranks[1])
    assert(not info and retry,"restricted classification/knowledge remains retryable")
    state[field]=nil
    info,_,retry=a.Bindings.Resolve(ranks[1]); assert(not info and retry)
    state[field]=before
end
local helpful=C_Spell.IsSpellHelpful
C_Spell.IsSpellHelpful=function() error("temporary API failure") end
local info,_,retry=a.Bindings.Resolve(ranks[1]); assert(not info and retry)
C_Spell.IsSpellHelpful=nil
info,_,retry=a.Bindings.Resolve(ranks[1]); assert(not info and not retry,"missing capability must not poll")
C_Spell.IsSpellHelpful=helpful
-- Existing recovery, persistence and combat behavior must include Penance.
state.helpful=m.Secret(); m.Event("SPELLS_CHANGED")
for _,row in ipairs(rows) do assert(row.attributes.type1=="") end
assert(a.Bindings.retryNeeded)
state.helpful=false; m.Flush()
for _,row in ipairs(rows) do assert(row.attributes.type1=="macro") end
assert(not a.Bindings.retryNeeded)
m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
assert(not a.Bindings.Put("1",ranks[1]))
state.known=false; m.Event("SPELLS_CHANGED")
for _,row in ipairs(rows) do assert(row.attributes.spell1==ranks[4]) end
m.combat=false; m.Event("PLAYER_REGEN_ENABLED")
for _,row in ipairs(rows) do assert(row.attributes.type1=="") end
state.known=true; m.Event("SPELLS_CHANGED")
local saved=a.db
local _,reloaded=setup(saved)
assert(reloaded.db.bindings["1"]==ranks[4] and reloaded.View.rows[1].attributes.spell1==ranks[4])
print("PASS Penance: four Forever ranks, editor drop, 15 slots/seven recipients, friendly-only exact ranks, strict rejection, recovery, combat and reload")
