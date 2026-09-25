-- Run from the child repository: lua tests/generated_dev.lua <generated ApogeeHealsDev root>
-- Execute packaged gameplay chunks with their actual DEV identity. Admission is
-- mocked as granted here; central distribution tests own gate/pin/identity isolation.
local root = assert(arg[1], "Generated ApogeeHealsDev root required")
local name = "ApogeeHealsDev"
local function read(path)
    local file = assert(io.open(path, "rb")); local data = file:read("*a"); file:close(); return data
end
local fixture = read("tests/mock.lua"):gsub("ApogeeHeals", name)
local realDofile = dofile
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
for _, path in ipairs({ "tests/buffs_spec.lua", "tests/paladin_buffs_spec.lua", "tests/minimap_spec.lua",
    "tests/purify_spec.lua", "tests/native_purify_spec.lua", "tests/range_spec.lua" }) do
    local fixtureTest = read(path):gsub("ApogeeHeals", name)
    assert(loadstring(fixtureTest, "@" .. path .. " (DEV fixture)"))()
end
dofile = realDofile
print("PASS generated DEV buffs, tooltips, minimap and disabled Purify and spell-range scenarios")
