-- Load the selected gameplay bytes; central tests cover distribution admission.
-- Tests must not silently fall back to source when a generated runtime is selected.
local Mock = dofile("tests/mock.lua")
local Runtime = {}
function Runtime.Start()
    local m = Mock.New()
    local root = os.getenv("APOGEE_HEALS_RUNTIME_ROOT")
    local name = os.getenv("APOGEE_HEALS_RUNTIME_NAME") or "ApogeeHeals"
    local prefix = root and root .. "/" or ""
    local a = {__ApogeeFamilyAdmission=function(candidate) return candidate == name end}
    for line in io.lines(prefix .. name .. ".toc") do
        line = line:gsub("\r$", "")
        if line:match("%.lua$") and not line:match("^__Distribution/") then
            assert(loadfile(prefix .. line))(name, a)
        end
    end
    _G[name .. "DB"] = nil
    m.addon = a
    m.Event("ADDON_LOADED", name); m.Flush()
    assert(a.started, "Selected Heals runtime failed to start: " .. name)
    return m, a
end
return Runtime
