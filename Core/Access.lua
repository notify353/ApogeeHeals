-- Adapted from Apogee Tank (MIT, copyright 2026 notify353).
local _, A = ...
A.Access = {}
function A.Access.Readable(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if issecretvalue(value) or not canaccessvalue(value) then return false end
        -- A readable reference does not grant permission to index its contents.
        if type(value) == "table" and not canaccesstable(value) then return false end
    end
    return true
end
function A.Access.Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and A.Access.Readable(value) then return value end
end
