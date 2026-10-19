local function expect(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

local allocations = 0
CoordGrid = { new = function(level, mapX, mapZ, localX, localZ)
    allocations = allocations + 1
    return { level = level, x = mapX * 64 + localX, z = mapZ * 64 + localZ }
end }
-- Generating display coordinates must never consult region source mappings.
World = setmetatable({}, { __index = function() error("unexpected world query") end })
local Grid = require("src/grid")
local player = { x = 3200, z = 6400, level = 2 }
expect(Grid.query(player, 30, false), nil, "disabled grid has no coordinates")
expect(allocations, 0, "disabled grid allocates nothing")
local coords = Grid.query(player, 30, true)
expect(#coords, 61 * 61, "grid covers the full candidate square")
local seen = {}
for _, coord in ipairs(coords) do
    expect(coord.level, 2, "grid stays on current floor")
    assert(math.abs(coord.x - player.x) <= 30 and math.abs(coord.z - player.z) <= 30)
    local key = coord.x .. ":" .. coord.z
    expect(seen[key], nil, "grid has no duplicate coordinates")
    seen[key] = true
end
expect(seen["3170:6370"], true, "southwest corner included")
expect(seen["3230:6430"], true, "northeast corner included")
expect(Grid.query({ x = 3200, z = 6400, level = 2 }, 30, true), coords,
    "equivalent coordinates reuse the cache")
expect(allocations, #coords, "stationary queries allocate no coordinates")
player.x = player.x + 1
local moved = Grid.query(player, 30, true)
assert(moved ~= coords, "movement rebuilds coordinates even if player object is reused")
expect(moved[1].x, 3171, "grid follows player movement")
player.level = 3
expect(Grid.query(player, 30, true)[1].level, 3, "floor change invalidates cache")
expect(#Grid.query(player, 1, true), 9, "range is part of cache key")
coords = Grid.query(player, 30, true)
Grid.clear()
assert(Grid.query(player, 30, true) ~= coords, "region reset invalidates cache")
coords = Grid.query(player, 30, true)
expect(Grid.query(player, 30, false), nil, "disabling clears coordinates")
assert(Grid.query(player, 30, true) ~= coords, "re-enabling starts a fresh cache")
Grid.clear()
print("test_grid: ok")
