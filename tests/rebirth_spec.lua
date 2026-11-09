local m, a = dofile("tests/purify_fixture.lua").New({class="DRUID", known=false})
local ranks = {20484, 20739, 20742, 20747, 20748}
local learned, rankOf = {}, {}
for rank, id in ipairs(ranks) do rankOf[id] = rank end
C_Spell.GetSpellInfo = function(id)
    if rankOf[id] then return {name="Localized Rebirth", iconID=136080, spellID=id} end
    if id == 437138 then return {name="Revive", iconID=132132, spellID=id} end
end
C_Spell.GetSpellSubtext = function(id) return "Rank " .. (rankOf[id] or 1) end
C_SpellBook.IsSpellKnown = function(id) return learned[id] == true end
C_SpellBook.IsSpellInSpellBook = C_SpellBook.IsSpellKnown
C_Spell.IsSpellHelpful = function() return false end
UnitIsPlayer = function() return true end
local row, target = a.View.rows[2], a.View.target
local button = assert(row.rebirthButton)
assert(not a.View.rows[1].rebirthButton and not a.View.targetTarget.rebirthButton)
assert(button.parent == row and target.rebirthButton.parent == target)
assert(button.point[4] == -a.Style.sideIconSize - 2 * a.Style.sideIconGap)
assert(button.driver == "hide" and button.attributes.type1 == "")
for rank, id in ipairs(ranks) do
    learned[id] = true
    m.Event("SPELLS_CHANGED"); m.Flush()
    assert(button.reminderSpell == id and button.icon.texture == 136080)
    for _, recipient in ipairs(a.View.supportRows) do
        local action = recipient.rebirthButton
        if action then
            assert(action.attributes.macrotext1 == "/cast [@" .. recipient.unit
                .. ",exists,help,dead] Localized Rebirth(Rank " .. rank .. ")\n/stopspelltarget")
            assert(action.attributes.unit == recipient.unit and not action.scripts.OnClick)
            assert(action.attributes["shift-type1"] == "" and action.attributes["alt-type1"] == "")
            assert(action.attributes.useOnKeyDown == false and action.clicks[1] == "LeftButtonUp")
        end
    end
end
-- Prepared even when recipients are alive or absent; no combat rebinding needed.
m.units.party1 = {connected=true, dead=false, auras={}}
m.units.target = {connected=true, dead=false, auras={}}
learned[437138] = true
m.Event("SPELLS_CHANGED"); m.Flush()
assert(button.driver == "[@player,dead] hide; [@party1,exists,help,dead] show; hide")
assert(row.buffButtons[1].attributes.type1 == "")
local original = button.attributes.macrotext1
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
m.units.party1.dead = true
m.Event("UNIT_HEALTH", "party1"); m.Flush()
assert(button.attributes.macrotext1 == original and button.icon.shown)
assert(not row.buffReminders[1].shown)
C_Spell.SpellHasRange = function() return true end
C_Spell.IsSpellInRange = function() return false end
local function tick() a.Buffs.timerDriver.scripts.OnUpdate(a.Buffs.timerDriver, 1) end
tick(); assert(button.icon.desaturated and button.icon.vertexColor[1] == 0.45)
C_Spell.IsSpellInRange = function() return true end
tick(); assert(not button.icon.desaturated and button.icon.vertexColor[1] == 1)
C_Spell.IsSpellInRange = function() return m.Secret() end
tick(); assert(not button.icon.desaturated)
C_Spell.IsSpellInRange = function() error("released corpse unavailable") end
tick(); assert(not button.icon.desaturated and button.attributes.macrotext1 == original)
button.scripts.OnEnter(); assert(a.Buffs.tooltipButton == button)
learned[20748] = false
m.Event("SPELLS_CHANGED"); m.Flush(); assert(button.attributes.macrotext1 == original)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(button.reminderSpell == 20747 and row.buffButtons[1].reminderSpell == 437138)
-- Preview and loading preserve the prepared action for combat auto-lock/entry.
a.View.SetUnlocked(true)
assert(button.driver == "[@player,dead] hide; [combat,@party1,exists,help,dead] show; hide")
assert(button.attributes.type1 == "macro" and button.icon.alpha == 0)
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush(); tick()
assert(button.icon.alpha == 1 and button.reminderSpell == 20747)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
m.Event("PLAYER_LEAVING_WORLD")
assert(button.icon.alpha == 0 and button.attributes.type1 == "macro")
assert(button.driver:find("[combat,@party1", 1, true))
m.combat = true; m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); tick()
assert(button.icon.alpha == 1 and button.attributes.type1 == "macro")
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
-- Hostile/replaced/absent targets never retarget or change the fixed macro.
local targetMacro = target.rebirthButton.attributes.macrotext1
m.units.target = {connected=true, dead=true, hostile=true, auras={}}
m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(target.rebirthButton.attributes.macrotext1 == targetMacro)
m.units.target = nil; m.Event("PLAYER_TARGET_CHANGED"); m.Flush()
assert(target.rebirthButton.attributes.macrotext1 == targetMacro)
-- Unavailable localized text retries; injection and unsafe candidates fail closed.
C_Spell.GetSpellSubtext = function() return m.Secret() end
m.Event("SPELL_TEXT_UPDATE"); m.Flush(); assert(button.attributes.type1 == "")
C_Spell.GetSpellSubtext = function() return "Rank 4" end
a.Buffs.Refresh(); assert(button.attributes.type1 == "macro")
C_Spell.GetSpellSubtext = function() return "Rank 4\n/cast Other" end
m.Event("SPELL_TEXT_UPDATE"); m.Flush(); assert(button.attributes.type1 == "")
C_Spell.GetSpellSubtext = function() return "Rank 4" end
C_Spell.IsSpellHarmful = function() return true end
a.Buffs.Refresh(); assert(button.attributes.type1 == "")
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return true end
a.Buffs.Refresh(); assert(button.attributes.type1 == "")
C_Spell.IsSpellPassive = function() return false end
m.units.player.dead = true; a.Buffs.Refresh()
assert(button.attributes.type1 == "macro", "Native player-dead gate preserves the prepared action")
m.units.player.dead = false; a.Buffs.Refresh()
m.units.player.class = "PRIEST"; a.Buffs.Refresh(); assert(button.attributes.type1 == "")
m.units.player.class = "DRUID"; a.Buffs.Refresh(); assert(button.attributes.type1 == "macro")
a.startupState = "failed"; a.Buffs.Stop()
assert(button.attributes.type1 == "" and button.driver == "hide" and button.icon.alpha == 0)
UnitIsPlayer = nil
print("PASS Rebirth: learned ranks, fixed recipients, combat range and secure lifecycle")
