local Fixture=dofile("tests/purify_fixture.lua")
for _,options in ipairs({{might=true},{class="PRIEST"},{known=false},{noTemplates=true},{secretTemplates=true}}) do
    local m,a=Fixture.New(options)
    local function unchanged()
        assert(#m.cleanseContainers==0 and m.xmlWarnings==0)
        assert(a.Cleansing.status:find("unavailable",1,true))
        for _,row in ipairs(a.View.rows) do
            assert(not row.cleanseHost and not row.cleanseButton)
            assert(row.buffOverflow.point[4]==-61)
        end
    end
    unchanged()
    if options.might then
        assert(a.View.rows[1].buffReminders[1].shown)
        assert(a.View.rows[1].buffButtons[1].point[4]==-3)
    end
    for iteration=1,3 do
        for _,event in ipairs({"SPELLS_CHANGED","PLAYER_ENTERING_WORLD","GROUP_ROSTER_UPDATE"}) do
            m.Event(event);m.Flush();unchanged()
        end
        a.View.SetUnlocked(true);a.View.SetUnlocked(false);unchanged()
        m.combat=true;m.Event("PLAYER_REGEN_DISABLED");m.Flush()
        local reads=m.auraReads
        a.Cleansing.pending=true;a.Cleansing.Refresh()
        assert(a.Cleansing.pending and m.auraReads==reads);unchanged()
        m.combat=false;m.Event("PLAYER_REGEN_ENABLED");m.Flush()
        assert(not a.Cleansing.pending);unchanged()
    end
    m.known=true;m.Event("SPELLS_CHANGED");m.Flush();unchanged()
end
print("PASS rejected Purify composition never constructed/retried; no XML warnings or fallback hitbox; buff layout preserved")
