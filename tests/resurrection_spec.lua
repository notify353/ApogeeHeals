local fixture = dofile("tests/purify_fixture.lua")
local families = {
    PRIEST = {2006, 2010, 10880, 10881, 20770},
    PALADIN = {7328, 10322, 10324, 20772, 20773},
    SHAMAN = {2008, 20609, 20610, 20776, 20777},
}
for class, ranks in pairs(families) do
    local m, a = fixture.New({class=class, known=false})
    local learned, names = {}, {}
    for rank, id in ipairs(ranks) do names[id] = rank end
    C_Spell.GetSpellInfo = function(id)
        if names[id] then return {name="Localized Rez", iconID=123, spellID=id} end
    end
    C_Spell.GetSpellSubtext = function(id) return "Rank " .. names[id] end
    C_SpellBook.IsSpellKnown = function(id) return learned[id] == true end
    C_SpellBook.IsSpellInSpellBook = C_SpellBook.IsSpellKnown
    UnitIsPlayer = function(unit) return unit ~= "target" or not m.npc end
    m.units.party1 = {connected=true, dead=true, auras={}}
    m.units.target = {connected=true, dead=true, auras={}}
    local row, target = a.View.rows[2], a.View.target
    local button = row.buffButtons[1]
    local function refresh() a.Buffs.Refresh() end
    local function absent() assert(button.attributes.type1 == "") end
    refresh(); absent()
    for rank, id in ipairs(ranks) do
        learned[id] = true
        m.Event("SPELLS_CHANGED"); m.Flush()
        assert(button.reminderSpell == id and button.attributes.type1 == "macro")
        assert(button.attributes.macrotext1 == "/cast [@party1,exists,help,dead] Localized Rez(Rank "
            .. rank .. ")\n/stopspelltarget")
        assert(button.driver == "[combat][@player,dead] hide; [@party1,exists,help,dead] show; hide")
        assert(button.attributes.unit == "party1" and button.clicks[1] == "LeftButtonUp")
        assert(button.attributes["shift-type1"] == "" and button.attributes["alt-type1"] == "")
        assert(button.point[1] == "TOPRIGHT" and button.point[3] == "TOPLEFT")
        assert(button.point[4] == -a.Style.sideIconGap)
        assert(button.buffTimer.text == "" and row.buffReminders[1].texture == 123)
        assert(a.View.rows[1].buffButtons[1].attributes.type1 == "", "Never rez self")
        assert(target.buffButtons[1].attributes.macrotext1:find("@target,exists,help,dead", 1, true))
        assert(target.buffButtons[1].parent == target,
            "Rez must not inherit the target support frame's nodead visibility gate")
        assert(target.supportFrame.driver == "[@target,help,nodead] show; hide",
            "Other target support retains its living-only gate")
    end
    button.scripts.OnEnter(); assert(a.Buffs.tooltipButton == button)
    m.units.party1.dead = false; refresh(); absent(); assert(not a.Buffs.tooltipButton)
    m.units.party1.dead = true; m.units.party1.connected = false; refresh(); absent()
    m.units.party1.connected = m.Secret(); refresh(); absent()
    m.units.party1.connected = true; m.units.party1.dead = m.Secret(); refresh(); absent()
    m.units.party1.dead = true; m.units.party1.hostile = true; refresh(); absent()
    m.units.party1.hostile = false
    C_Spell.SpellHasRange = function() return true end
    C_Spell.IsSpellInRange = function() return false end
    refresh(); assert(button.attributes.type1 == "macro", "Dead recipient stays actionable regardless of range")
    local deadOrGhost = UnitIsDeadOrGhost
    UnitIsDeadOrGhost = function(unit)
        if unit == "party1" then return true end -- Released ghost still satisfies the native contract.
        return deadOrGhost(unit)
    end
    C_Spell.IsSpellInRange = function() error("Rez must not query ghost/unit range as corpse range") end
    refresh(); assert(button.attributes.type1 == "macro", "Released ghost keeps rez action")
    UnitIsDeadOrGhost = deadOrGhost
    C_Spell.IsSpellInRange = function() return m.Secret() end
    refresh(); assert(button.attributes.type1 == "macro", "Unknown range is not false")
    C_Spell.IsSpellInRange = function() error("unavailable") end
    refresh(); assert(button.attributes.type1 == "macro")
    C_Spell.IsSpellInRange = function() return true end
    m.units.player.dead = true; refresh(); absent()
    m.units.player.dead = false
    m.npc = true; refresh(); assert(target.buffButtons[1].attributes.type1 == "")
    m.npc = false; refresh()
    a.Buffs.Paint(target, {{id=ranks[#ranks], icon=123}})
    assert(target.buffButtons[1].driver == "[combat] hide; [@target,help,nodead] show; hide",
        "Reusing the first target slot for a buff restores its living-only gate")
    refresh()
    assert(target.buffButtons[1].driver:find(",help,dead] show; hide", 1, true), "Rez restores dead-only gate")
    m.units.target = nil; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
    assert(target.buffButtons[1].attributes.type1 == "")
    local original = button.attributes.macrotext1
    m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
    learned[ranks[#ranks]] = false
    m.Event("SPELLS_CHANGED"); m.Flush()
    a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver, 1)
    assert(button.attributes.macrotext1 == original, "No protected combat edits")
    m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
    assert(button.reminderSpell == ranks[#ranks - 1], "Rank changes resume after combat")
    a.View.unlocked = true; refresh(); absent()
    a.View.unlocked = false; refresh(); assert(button.attributes.type1 == "macro")
    m.Event("PLAYER_LEAVING_WORLD"); absent()
    a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver, 1); absent()
    m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); assert(button.attributes.type1 == "macro")
    C_Spell.GetSpellSubtext = function() return m.Secret() end
    m.Event("SPELL_TEXT_UPDATE"); m.Flush(); absent()
    C_Spell.GetSpellSubtext = function() return "Rank 4" end
    refresh(); assert(button.attributes.type1 == "macro", "Unavailable text retries")
    C_Spell.GetSpellSubtext = function() return "Rank 4\n/cast Other" end
    m.Event("SPELL_TEXT_UPDATE"); m.Flush(); absent()
    m.units.player.class = "WARRIOR"; refresh(); absent()
    UnitIsPlayer = nil
end
print("PASS resurrection: learned ranks, strict dead recipients, styling, range, combat and lifecycle")
