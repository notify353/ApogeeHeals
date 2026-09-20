local _, A = ...
A.Storage = {}
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000
end
function A.Storage.Open(saved)
    if type(saved) == "table" and type(saved.version) == "number" and saved.version > 1 then
        return nil, "Saved position is from a newer version; data preserved."
    end
    local position = type(saved) == "table" and saved.position
    if type(position) ~= "table" or not finite(position.x) or not finite(position.y) then
        position = { x = -180, y = 55 }
    end
    return { version = 1, position = { x = position.x, y = position.y } }
end
