local m = dofile("tests/mock.lua").New()
local names = {[1243]="Power Word: Fortitude",[1244]="Power Word: Fortitude",[19740]="Blessing of Might"}
local ranks = {[1243]="Rank 1",[1244]="Rank 2",[19740]="Rank 1"}
C_Spell.GetSpellInfo = function(id) return names[id] and {name=names[id],iconID=1,spellID=id} end
C_Spell.GetSpellSubtext = function(id) return ranks[id] end
local a = m.Start()
local paths = {
    {key="buffButtons",paint=function(row,items) a.Buffs.Paint(row,items) end},
    {key="blessingButtons",paint=function(row,items) a.Buffs.PaintBlessings(row,items,0) end},
    {key="upkeepButtons",paint=function(row,items) a.Buffs.PaintCatalog(row,items,0,0) end},
}
local recipients = {unpack(a.View.rows)}; recipients[#recipients+1]=a.View.target
for _,path in ipairs(paths) do
    for _,row in ipairs(recipients) do
        path.paint(row,{{id=1243,icon=1}})
        local button=row[path.key][1]
        assert(button.attributes.unit==row.unit and not button.scripts.OnClick)
        assert(button.attributes.useOnKeyDown==false and button.clicks[1]=="LeftButtonUp")
        assert(button.attributes["shift-type1"]=="" and button.attributes["alt-type1"]=="")
        if row.unit=="player" then
            assert(button.attributes.type1=="spell" and button.attributes.macrotext1==nil)
        else
            assert(button.attributes.type1=="macro")
            assert(button.attributes.macrotext1=="/cast [@"..row.unit..",exists,help] Power Word: Fortitude(Rank 1)\n/stopspelltarget")
        end
        path.paint(row,{{id=1244,icon=2}})
        assert(button.attributes.spell1==1244)
        if row.unit~="player" then assert(button.attributes.macrotext1:find("Rank 2",1,true)) end
        path.paint(row,{})
        assert(button.attributes.type1=="" and button.attributes.macrotext1==nil and button.driver=="hide")
    end
end
local row=a.View.rows[2]
for _,path in ipairs(paths) do
    ranks[1243]=nil
    path.paint(row,{{id=1243,icon=1}})
    local button=row[path.key][1]
    assert(button.attributes.type1=="" and button.attributes.macrotext1==nil)
    ranks[1243]="Rank 1"; path.paint(row,{{id=1243,icon=1}})
    assert(button.attributes.type1=="macro", "Unavailable rank text must retry without a spell-ID change")
    local old=button.attributes.macrotext1
    m.combat=true; ranks[1243]="Rank 3"; m.Event("SPELL_TEXT_UPDATE")
    path.paint(row,{{id=19740,icon=2}})
    assert(button.attributes.spell1==1243 and button.attributes.macrotext1==old)
    m.combat=false; path.paint(row,{{id=1243,icon=1}})
    assert(button.attributes.macrotext1:find("Rank 3",1,true))
    ranks[1243]=m.Secret(); m.Event("SPELL_TEXT_UPDATE"); path.paint(row,{{id=1243,icon=1}})
    assert(button.attributes.type1=="" and button.attributes.macrotext1==nil)
    ranks[1243]="Rank 1\n/cast Other"; path.paint(row,{{id=1243,icon=1}})
    assert(button.attributes.type1=="")
    ranks[1243]="Rank 1"; path.paint(row,{{id=1243,icon=1}})
    assert(button.attributes.type1=="macro")
    path.paint(row,{})
end
-- Player-only aura/aspect choices keep their native fixed-self action, even if
-- rank text is unavailable. The ordinary self-buff paths above do the same.
ranks[1243]=nil
a.Buffs.PaintAuras(a.View.rows[1],{{id=1243,icon=1}},0,0)
local aura=a.View.rows[1].auraButtons[1]
assert(aura.attributes.unit=="player" and aura.attributes.type1=="spell" and aura.attributes.macrotext1==nil)
print("PASS strict buff recipients across reminders, blessings, catalog and target choices; exact ranks, self buffs, clearing, text recovery and combat deferral")
-- Native range/LOS, macro parsing and taint acceptance remain in-game checks.
