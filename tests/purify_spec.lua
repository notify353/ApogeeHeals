local Fixture = dofile("tests/purify_fixture.lua")
for _, options in ipairs({{might=true}, {cleanse=true}, {class="PRIEST"}, {known=false},
    {noTemplates=true}, {secretTemplates=true}}) do
    local m, a = Fixture.New(options)
    local function check()
        assert(m.xmlWarnings == 0)
        for _, row in ipairs(a.View.rows) do
            if options.class == "PRIEST" then assert(not row.cleanseButtons)
            else
                assert(#row.cleanseButtons == 2)
                for index, button in ipairs(row.cleanseButtons) do
                    local learned = index == 1 and m.known or index == 2 and m.cleanse
                    assert(button.parent == row and button.point[2] == row.health)
                    assert(button.width == row.height and button.height == row.height and button.point[5] == 0)
                    assert(button.point[4] == 2 + (index - 1) * (row.height + 2))
                    assert(button.template == "SecureActionButtonTemplate" and not button.scripts.OnClick)
                    assert(button.attributes.unit == row.unit and button.attributes.useOnKeyDown == false)
                    assert(button.clicks[1] == "LeftButtonUp")
                    assert(button.icon.desaturated and button.icon.alpha == 0.3)
                    assert(button.driver == (learned and "show" or "hide"))
                    assert(button.attributes.spell1 == (learned and (index == 1 and 1152 or 4987) or nil))
                    for _, prefix in ipairs({"shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-"}) do
                        assert(button.attributes[prefix .. "type1"] == "")
                    end
                end
                assert(row.drinkIcon.point[4] == 2 + 2 * (row.height + 2))
                if not options.noTemplates and not options.secretTemplates then
                    local indicator = assert(row.cleanseIndicator)
                    assert(indicator.parent == row and indicator.unit == row.unit)
                    for key, slot in pairs(indicator.slots) do
                        assert(slot.frame.mouse == false and slot.frame.parent == indicator)
                        assert(slot.frame.width == row.height and slot.frame.height == row.height)
                        local index = key == "purify" and 1 or 2
                        assert(slot.frame:GetFrameLevel() > row.cleanseButtons[index]:GetFrameLevel())
                        local activeIcon
                        for _, child in ipairs(m.frames) do
                            if child.parent == slot.frame and child.drawLayer == "ARTWORK" then activeIcon = child end
                        end
                        assert(activeIcon and activeIcon.texture == (index == 1 and 135949 or 135953))
                        local types = slot.filters.includeDispelTypes
                        local learned = key == "purify" and m.known or key == "cleanse" and m.cleanse
                        assert((types.Poison == true) == learned and (types.Disease == true) == learned)
                        assert((types.Magic == true) == (key == "cleanse" and learned))
                        assert(not types.Curse)
                    end
                end
            end
            assert(row.buffOverflow.point[4] == -2 - 4 * (row.height + 2))
            for index, button in ipairs(row.buffButtons) do
                assert(button.width == row.height and button.height == row.height)
                assert(button.point[1] == "TOPRIGHT" and button.point[3] == "TOPLEFT" and button.point[5] == 0)
                assert(button.point[4] == -2 - (index - 1) * (row.height + 2))
            end
        end
    end
    check()
    a.View.SetUnlocked(true)
    if a.View.rows[1].cleanseButtons then
        for _, button in ipairs(a.View.rows[1].cleanseButtons) do assert(button.driver == "hide") end
    end
    a.View.SetUnlocked(false); check()
    m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
    local reads = m.auraReads
    for _, event in ipairs({"GROUP_ROSTER_UPDATE", "UNIT_AURA", "SPELLS_CHANGED"}) do
        m.Event(event, "player"); m.Flush(); check()
    end
    assert(m.auraReads == reads)
    m.cleanse = true
    m.Event("SPELLS_CHANGED"); m.Flush()
    if a.View.rows[1].cleanseButtons then
        assert(a.View.rows[1].cleanseButtons[2].driver == (options.cleanse and "show" or "hide"))
    end
    m.combat = false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush(); check()
    m.known, m.cleanse = false, false
    m.Event("SPELLS_CHANGED"); m.Flush(); check()
end
print("PASS permanent learned cleansing actions, separate native halos, type filters, modifiers, preview, spellbook changes and combat deferral")
