-- Run from the child repository: lua tests/generated_dev.lua <generated ApogeeHealsDev root>
-- Execute packaged gameplay chunks with their actual DEV identity. Admission is
-- mocked as granted here; central distribution tests own gate/pin/identity isolation.
local root = assert(arg[1], "Generated ApogeeHealsDev root required")
local name = "ApogeeHealsDev"
local function read(path)
    local file = assert(io.open(path, "rb")); local data = file:read("*a"); file:close(); return data
end
local fixture = read("tests/mock.lua"):gsub("ApogeeHeals", name)
local realDofile, realLoadfile = dofile, loadfile
local standalone = {["Core/Access.lua"]=true,["Bindings/Runtime.lua"]=true,
    ["Buffs/Catalog.lua"]=true,["WeaponUpkeep/Runtime.lua"]=true}
loadfile = function(path)
    if not standalone[path] then return realLoadfile(path) end
    local chunk = assert(realLoadfile(root .. "/" .. path))
    return function(addonName, addon)
        addon.__ApogeeFamilyAdmission = function(candidate) return candidate == name end
        return chunk(addonName, addon)
    end
end
dofile = function(path)
    if path == "tests/purify_fixture.lua" then
        local data = read(path):gsub("ApogeeHeals", name)
        return assert(loadstring(data, "@" .. path .. " (DEV fixture)"))()
    end
    if path ~= "tests/mock.lua" then return realDofile(path) end
    local Mock = assert(loadstring(fixture, "@tests/mock.lua (DEV fixture)"))()
    local new = Mock.New
    Mock.New = function()
        local m = new()
        m.Load = function()
            local addon = { __ApogeeFamilyAdmission = function(candidate) return candidate == name end }
            for line in io.lines(root .. "/" .. name .. ".toc") do
                line = line:gsub("\r$", "")
                if line:match("%.lua$") and line ~= "__Distribution/FamilyGate.lua" then
                    assert(loadfile(root .. "/" .. line))(name, addon)
                end
            end
            m.addon = addon; return addon
        end
        return m
    end
    return Mock
end
for _, path in ipairs({ "tests/markers_spec.lua", "tests/threat_debuffs_spec.lua", "tests/threat_demo_spec.lua", "tests/threat_diagnostics_spec.lua", "tests/threat_spec.lua", "tests/native_threat_spec.lua", "tests/input_feedback_spec.lua", "tests/target_bindings_spec.lua", "tests/native_contract_spec.lua", "tests/target_spec.lua", "tests/target_target_spec.lua", "tests/reset_spec.lua", "tests/items_spec.lua", "tests/bindings_spec.lua", "tests/buffs_spec.lua", "tests/paladin_buffs_spec.lua", "tests/minimap_spec.lua",
    "tests/names_spec.lua", "tests/full_names_spec.lua", "tests/class_names_spec.lua", "tests/compact_layout_spec.lua", "tests/target_cast_spec.lua",
    "tests/purify_spec.lua", "tests/native_purify_spec.lua", "tests/range_spec.lua", "tests/editor_position_spec.lua", "tests/debuffs_spec.lua", "tests/drinking_timer_spec.lua", "tests/paladin_aura_spec.lua", "tests/blessing_guidance_spec.lua", "tests/target_support_spec.lua", "tests/class_cleansing_spec.lua", "tests/class_upkeep_spec.lua", "tests/hunter_aspects_spec.lua", "tests/weapon_upkeep_spec.lua", "tests/class_integration_spec.lua" }) do
    local fixtureTest = read(path):gsub("ApogeeHeals", name)
        :gsub("APOGEE_HEALS_RESET_CHARACTER", "APOGEE_HEALS_DEV_RESET_CHARACTER")
    assert(loadstring(fixtureTest, "@" .. path .. " (DEV fixture)"))()
end
dofile, loadfile = realDofile, realLoadfile
print("PASS generated DEV buffs, tooltips, cleansing buttons, debuffs, drinking timers and spell-range scenarios")
