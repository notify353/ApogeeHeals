local Mock = dofile("tests/mock.lua")
local m = Mock.New()
m.units.player.class = "HUNTER"
local forms = {{id=13165, name="Aspect of the Hawk"}, {id=13163, name="Aspect of the Monkey"}}
Enum.SpellBookSpellBank = {Player=0}
GetNumShapeshiftForms = function() return #forms end
GetShapeshiftFormInfo = function(index)
    if m.badForm then error("unavailable form") end
    return 100 + index, m.active == index, true, forms[index].id
end
C_Spell.GetSpellInfo = function(id)
    for _, form in ipairs(forms) do
        if id == form.id then return {spellID=id, name=form.name, iconID=id + 100} end
    end
end
C_Spell.IsSpellHelpful = function() return true end
C_Spell.IsSpellHarmful = function() return false end
C_Spell.IsSpellPassive = function() return false end
C_SpellBook = {IsSpellInSpellBook=function() return true end, IsSpellKnown=function() return true end}
GameTooltip.SetSpellByID = function(self, id) self.spell=id; return true end
UnitGroupRolesAssigned = function() return m.role end
local a = m.Start()
local row = a.View.rows[1]
assert(#row.auraButtons == 2)
for index, button in ipairs(row.auraButtons) do
    assert(button.attributes.unit == "player" and button.attributes.spell1 == forms[index].id)
    assert(button.attributes.type1 == "spell" and button.attributes["shift-type1"] == "")
    assert(button.attributes.useOnKeyDown == false and button.clicks[1] == "LeftButtonUp")
    assert(button.width == a.Style.sideIconSize and button.height == a.Style.sideIconSize)
    assert(button.point[4] == -a.Style.sideIconGap - (index-1)*(a.Style.sideIconSize+a.Style.sideIconGap))
    assert(button.driver == "[combat] hide; show" and not button.scripts.OnClick)
end
for index=2,5 do assert(not a.View.rows[index].auraButtons) end
local button = row.auraButtons[1]
assert(button.suggestion.shown and button.recommendation:find("combat style unknown",1,true))
m.role = "TANK"; a.Buffs.Refresh()
assert(not button.suggestion.shown and row.auraButtons[2].suggestion.shown)
m.role = "HEALER"; a.Buffs.Refresh()
assert(not button.suggestion.shown and not row.auraButtons[2].suggestion.shown)
m.role = m.Secret(); a.Buffs.Refresh()
assert(button.suggestion.shown)
m.role = nil
-- Travel aspects remain manual, even with an unknown role.
forms[3] = {id=13159,name="Aspect of the Pack"}
a.Buffs.Refresh(); assert(not row.auraButtons[3].suggestion.shown)
forms[3] = nil
button.scripts.OnEnter(button); assert(GameTooltip.spell == 13165 and GameTooltip.shown)
m.active = 2; m.Event("UPDATE_SHAPESHIFT_FORM"); m.Flush()
assert(button.driver == "hide" and button.attributes.type1 == "" and not GameTooltip.shown)
m.active = nil
-- Another Hunter's aspect does not establish this player's selected mode.
m.units.player.auras = {{spellId=13165,name="Aspect of the Hawk",sourceUnit="party1"}}
a.Buffs.Refresh(); assert(button.attributes.spell1 == 13165)
m.badForm = true; a.Buffs.Refresh(); assert(button.driver == "hide")
m.badForm = false; a.Buffs.Refresh()
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
assert(not button.icon.shown and button.attributes.spell1 == 13165)
m.active = 1; a.Buffs.Refresh(); assert(button.attributes.spell1 == 13165)
m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
assert(button.driver == "hide" and not button.attributes.spell1)
m.active = nil; a.View.unlocked = true; a.Buffs.Refresh(); assert(button.driver == "hide")
a.View.unlocked = false; a.Buffs.Refresh()
m.Event("PLAYER_LEAVING_WORLD"); assert(button.driver == "hide")
m.Event("PLAYER_ENTERING_WORLD"); m.Flush(); assert(button.attributes.spell1 == 13165)
m.units.player.class = "PRIEST"; a.Buffs.Refresh(); assert(button.driver == "hide")
GetNumShapeshiftForms, GetShapeshiftFormInfo = nil, nil
print("PASS Hunter native aspects, role suggestions, no travel suggestion, fixed-self actions and lifecycle cleanup")
