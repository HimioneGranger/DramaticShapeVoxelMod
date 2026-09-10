-- Regression coverage for the authored Pokemon Tower seam landscaping.
-- ROM/GPU-free: luajit tests/lavender_approach_visuals_test.lua

local checks = 0
local function check(v, message)
  checks = checks + 1
  assert(v, message)
end
local function eq(a, b, message)
  check(a == b, message .. ' (expected ' .. tostring(b) .. ', got ' .. tostring(a) .. ')')
end
local function key(x, z) return (z + 64) * 4096 + x + 64 end

-- Buildings.stamp owns discovery of the exact claim-only Tower-top footprint.
local Buildings = assert(loadfile('lib/Buildings.lua'))({
  require = function(name)
    if name == 'BuildBudget' then return { tick = function() end } end
    return {}
  end,
})

local S = {
  outdoor = false, objectQuads = {}, shapeAt = {}, tileAt = {}, skip = {}, ground = {},
}
for z = 19, 28 do
  for x = 9, 22 do
    local k = key(x, z)
    S.shapeAt[k] = { flat = true, class = 'ground' }
    S.tileAt[k] = 44
  end
end
local original = {}
for k, v in pairs(S.tileAt) do original[k] = v end
Buildings.stamp(S, { id = 'ROUTE_10' }, {}, 10, 20, 12, 8,
  { id = 'pokemon_tower_top', claimOnly = true })
check(S.lavenderFlowerbed ~= nil, 'Route 10 Tower-top claim records a flowerbed footprint')
eq(S.lavenderFlowerbed.minX, 10, 'flowerbed keeps matched west edge')
eq(S.lavenderFlowerbed.maxX, 21, 'flowerbed keeps matched east edge')
eq(S.lavenderFlowerbed.minY, 20, 'flowerbed keeps matched north edge')
eq(S.lavenderFlowerbed.maxY, 27, 'flowerbed keeps matched south edge')
for k, v in pairs(original) do
  eq(S.tileAt[k], v, 'flowerbed discovery never rewrites source map tiles')
end

-- Load just the Structures module with lightweight dependencies. The test
-- exercises the production flower-template builder and placement function.
package.loaded['src.render.Assets'] = {
  imageData = function() return nil end,
  register = function() end,
}
package.loaded['src.world.Map'] = { isOutdoor = function() return true end }
local grassMode = false
local Structures = assert(loadfile('lib/Structures.lua'))({
  require = function(name)
    if name == 'BuildBudget' then return { tick = function() end } end
    if name == 'CommunityVisuals' then
      return { customGrass = function() return grassMode end }
    end
    return {}
  end,
})

local pixels = {}
function pixels:getPixel()
  -- All-dark source gives a deterministic nonempty cutout without requiring
  -- the game atlas or flower-frame assets in this standalone test.
  return .25, .25, .25, 1
end

local blockedCalls = 0
local map = {
  id = 'ROUTE_10',
  tileset = {
    id = 'OVERWORLD', tilesPerRow = 16, imageWidth = 128, imageHeight = 48,
    animatedTiles = {},
  },
  isWalkableCell = function(_, cx, cy)
    blockedCalls = blockedCalls + 1
    -- One collision cell in the rectangle is walkable and must stay flower-free.
    return cx == 5 and cy == 10
  end,
}
local bed = {
  lavenderFlowerbed = { minX = 10, maxX = 21, minY = 20, maxY = 27 },
  flowerQuads = {},
}
eq(Structures.buildLavenderFlowerbed(bed, map, pixels), 0,
  'Battle Art GRASS does not add Legendary flowerbed standees')
eq(#bed.flowerQuads, 0, 'Battle Art keeps the claim-only rectangle undecorated')

grassMode = true
local emitted = Structures.buildLavenderFlowerbed(bed, map, pixels)
check(emitted > 0 and #bed.flowerQuads == emitted,
  'Legendary GRASS emits flower standees inside the Tower rectangle')
eq(blockedCalls, 12 * 8,
  'every candidate tile checks the engine collision cell before decoration')
-- 48 checkerboard positions minus the two even-parity 8px tiles in the one
-- walkable 16px collision cell; the fully-dark template emits 17 quads each.
eq(emitted, 46 * 17,
  'flowerbed fills the blocked checkerboard while preserving the walking cell')

print(checks .. ' checks passed (Lavender approach visuals)')
