local Grid = {}

local cachedCoords
local cachedX, cachedZ, cachedLevel, cachedRange

function Grid.clear()
    cachedCoords = nil
    cachedX, cachedZ, cachedLevel, cachedRange = nil, nil, nil, nil
end

-- These are display coordinates, never canonical marker/preset coordinates.
function Grid.query(from, range, enabled)
    if not enabled then
        Grid.clear()
        return nil
    end
    if cachedCoords ~= nil and cachedX == from.x and cachedZ == from.z
        and cachedLevel == from.level and cachedRange == range then
        return cachedCoords
    end

    local coords = {}
    for x = from.x - range, from.x + range do
        for z = from.z - range, from.z + range do
            coords[#coords + 1] = CoordGrid.new(
                from.level, x // 64, z // 64, x % 64, z % 64)
        end
    end
    cachedCoords = coords
    cachedX, cachedZ, cachedLevel, cachedRange = from.x, from.z, from.level, range
    return coords
end

return Grid
