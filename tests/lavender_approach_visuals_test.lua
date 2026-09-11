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
for z = 19, 32 do
  for x = 9, 22 do
    local k = key(x, z)
    S.shapeAt[k] = { flat = true, class = 'ground' }
    S.tileAt[k] = 44
  end
end
local original = {}
for k, v in pairs(S.tileAt) do original[k] = v end
Buildings.stamp(S, { id = 'ROUTE_10' }, {}, 10, 20, 12, 12,
  { id = 'pokemon_tower_top', claimOnly = true })
check(S.lavenderFlowerbed ~= nil, 'Route 10 Tower-top claim records a flowerbed footprint')
eq(S.lavenderFlowerbed.minX, 10, 'flowerbed keeps matched west edge')
eq(S.lavenderFlowerbed.maxX, 21, 'flowerbed keeps matched east edge')
eq(S.lavenderFlowerbed.minY, 20, 'flowerbed keeps matched north edge')
eq(S.lavenderFlowerbed.maxY, 31, 'flowerbed keeps matched south edge')
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
    if name == 'VoxelVisualObjects' then
      return { id = function() return 'lavender-sign' end }
    end
    return {}
  end,
})

-- The screenshot's bald 16x16 square is not the Route 10 Tower claim above.
-- It is Lavender's Silph Scope sign at engine cell (9,3), source tiles
-- tx18..19 / ty6..7. Exercise the production object-ground vote with the exact
-- surrounding donors from the canonical map: five $30 non-path neighbours and
-- one $39 path neighbour. The sign must synthesize $30 beneath all four claimed
-- billboard tiles; ChunkMesher's Lavender parity test then proves that donor
-- renders as plain grass in both modes.
do
  local signS = {
    outdoor = true, objectQuads = {}, shapeAt = {}, tileAt = {},
    skip = {}, ground = {},
  }
  local signTiles = {
    {18, 6, 70}, {19, 6, 71}, {18, 7, 86}, {19, 7, 87},
  }
  for _, c in ipairs(signTiles) do
    local k = key(c[1], c[2])
    signS.shapeAt[k] = { class = 'signpost', art = 'billboard', authored = true, h = 16 }
    signS.tileAt[k] = c[3]
  end
  local function flat(x, z, tile)
    local k = key(x, z)
    signS.shapeAt[k] = { class = 'ground', art = 'flat', flat = true, h = 0 }
    signS.tileAt[k] = tile
  end
  flat(18, 5, 48); flat(19, 5, 48)
  flat(18, 8, 48); flat(19, 8, 57)
  flat(17, 6, 48); flat(17, 7, 48)
  for _, z in ipairs({6, 7}) do
    local k = key(20, z)
    signS.shapeAt[k] = { class = 'wall', art = 'upright', flat = false, h = 16 }
    signS.tileAt[k] = 39
  end

  local region = { minX = 18, maxX = 19, minY = 6, maxY = 7, tiles = {} }
  local cluster = { minX = 18, maxX = 19, minY = 6, maxY = 7, tiles = {} }
  for _, c in ipairs(signTiles) do
    region.tiles[#region.tiles + 1] = { c[1], c[2] }
    cluster.tiles[#cluster.tiles + 1] = { c[1], c[2] }
  end
  local W = 18 -- 16px drawing plus the flood border used by extractObjects
  local state, flooded, srcU, srcV = {}, {}, {}, {}
  for py = 0, 15 do
    for px = 0, 15 do
      local i = (py + 1) * W + (px + 1)
      state[i] = 'solid'
      srcU[i], srcV[i] = 0, 0
    end
  end
  local signMap = {
    id = 'LAVENDER_TOWN',
    tileset = { imageWidth = 128, imageHeight = 48 },
    isWalkableCell = function() return false end,
  }
  check(Structures.buildObject(signS, signMap, region, cluster,
    state, flooded, srcU, srcV, W, true),
    'Lavender Silph Scope sign builds as the claimed billboard target')
  for _, c in ipairs(signTiles) do
    local k = key(c[1], c[2])
    eq(signS.ground[k], 48,
      'Lavender Silph Scope sign synthesizes the canonical non-path $30 floor')
    eq(signS.tileAt[k], c[3],
      'Lavender Silph Scope sign never rewrites its source tile art')
  end
end

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
local function flowerbedFixture()
  return {
    lavenderFlowerbed = { minX = 10, maxX = 21, minY = 20, maxY = 31 },
    flowerQuads = {},
  }
end

local battleBed = flowerbedFixture()
local battleEmitted = Structures.buildLavenderFlowerbed(battleBed, map, pixels)
check(battleEmitted > 0 and #battleBed.flowerQuads == battleEmitted,
  'Battle Art keeps the approved Lavender flowerbed standees')
eq(blockedCalls, 12 * 12,
  'Battle Art flowerbed checks every candidate collision cell')
-- 72 checkerboard positions minus the two even-parity 8px tiles in the one
-- walkable 16px collision cell; the fully-dark template emits 17 quads each.
eq(battleEmitted, 70 * 17,
  'Battle Art flowerbed preserves the existing blocked checkerboard exactly')

grassMode = true
blockedCalls = 0
local legendaryBed = flowerbedFixture()
local legendaryEmitted = Structures.buildLavenderFlowerbed(legendaryBed, map, pixels)
check(legendaryEmitted > 0 and #legendaryBed.flowerQuads == legendaryEmitted,
  'Legendary keeps the same approved Lavender flowerbed geometry')
eq(blockedCalls, 12 * 12,
  'Legendary flowerbed checks every candidate collision cell')
eq(legendaryEmitted, battleEmitted,
  'Battle Art and Legendary flowerbed density remain identical')

print(checks .. ' checks passed (Lavender approach visuals)')
