-- Issue #54: Lavender/Fuchsia city turf has its own Battle Art/Legendary
-- switch instead of inheriting the broad GRASS setting.
-- ROM/GPU-free: luajit tests/city_ground_option_test.lua

local checks = 0
local function check(value, message)
  checks = checks + 1
  assert(value, message)
end
local function same(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

package.loaded['src.render.Assets'] = { register = function() end }
package.loaded['src.core.Version'] = { engine = '0.2.53' }
package.loaded['src.core.Platform'] = { detect = function() return { os = 'Windows' } end }
package.loaded['src.render.TileRenderer'] = {
  animFrame = function() return 0 end,
  defaultAnimatedTiles = function() return nil end,
}
package.loaded['src.render.PaletteFX'] = {}

local Setting = {}
function Setting.new(key, label, values, labels, defaultIndex)
  return {
    key = key, label = label, values = values, labels = labels,
    value = values[defaultIndex or 1],
    get = function(self) return self.value end,
    row = function()
      return { step = function() return true end }
    end,
  }
end

local Community = assert(loadfile('lib/CommunityVisuals.lua'))({
  require = function(name)
    if name == 'ModSetting' then return Setting end
    return { invalidate = function() end }
  end,
})

check(Community.cityGround:get() == 'default', 'CITY GROUND defaults to Battle Art')
check(not Community.customCityGround(), 'Battle Art city ground is opt-out safe')
check(Community.cityGround.label == 'CITY GROUND'
    and Community.cityGround.values[1] == 'default'
    and Community.cityGround.values[2] == 'n64memory',
  'CITY GROUND uses the established Battle Art/Legendary value ladder')
check(Community.isCityGroundMap({ id = 'LAVENDER_TOWN', tileset = { id = 'OVERWORLD' } }),
  'Lavender is owned by CITY GROUND')
check(Community.isCityGroundMap({ id = 'FUCHSIA_CITY', tileset = { id = 'OVERWORLD' } }),
  'Fuchsia is owned by CITY GROUND')
check(not Community.isCityGroundMap({ id = 'PALLET_TOWN', tileset = { id = 'OVERWORLD' } }),
  'ordinary Overworld maps remain owned by GRASS')
check(not Community.isCityGroundMap({ id = 'FUCHSIA_CITY', tileset = { id = 'FOREST' } }),
  'map name cannot leak CITY GROUND into another tileset')

local analysis
local directionShade = { [1]=.84, [2]=.72, [3]=1, [4]=.55, [5]=.9, [6]=.68 }
local modules = {
  Structures = { forMap = function() return analysis end },
  TileShape = {},
  BuildBudget = { tick = function() end },
  LoadTimings = {
    wrap = function(_, fn) return fn end,
    resume = coroutine.resume,
    cancel = function() end,
    jobError = function() end,
  },
  VoxelMeshDisk = {},
  Voxel3D = {
    FACE_SHADE = directionShade,
    pushQuad = function(indices, n)
      for _, i in ipairs({1, 2, 3, 1, 3, 4}) do
        indices[#indices + 1] = n * 4 + i
      end
    end,
  },
  CommunityVisuals = Community,
}
local C = assert(loadfile('lib/ChunkMesher.lua'))({
  require = function(name) return assert(modules[name], name) end,
})

local function key(x, z) return (z + 64) * 4096 + x + 64 end
local function fixture(id)
  analysis = {
    shapeAt = {}, tileAt = {}, runs = {}, skip = {}, ground = {}, doorFold = {},
    objectQuads = {}, roundStamps = {},
  }
  analysis.shapeAt[key(1, 1)] = { h = 0, class = 'ground', art = 'top', flat = true }
  analysis.tileAt[key(1, 1)] = 44
  return {
    id = id,
    def = { width = 1, height = 1 },
    tileset = { id = 'OVERWORLD', tilesPerRow = 16, imageWidth = 128, imageHeight = 48 },
    tileAt = function(_, x, z) return analysis.tileAt[key(x, z)] or 90 end,
  }
end

local function signature(id, city, grass)
  Community.cityGround.value = city and 'n64memory' or 'default'
  Community.grass.value = grass and 'n64memory' or 'default'
  local vertices = C.geometry(fixture(id), true)
  local out = {}
  for _, vertex in ipairs(vertices) do
    -- Geometry positions/topology must stay fixed; only UV/material shading is
    -- expected to change when a Legendary ground treatment owns this cell.
    out[#out + 1] = vertex[4]
    out[#out + 1] = vertex[5]
    out[#out + 1] = vertex[6]
  end
  return out, #vertices
end

local fuchsiaBattle, fuchsiaN = signature('FUCHSIA_CITY', false, false)
local fuchsiaGlobalGrass, fuchsiaGlobalN = signature('FUCHSIA_CITY', false, true)
local fuchsiaLegendary, fuchsiaLegendaryN = signature('FUCHSIA_CITY', true, false)
check(fuchsiaN == fuchsiaGlobalN and same(fuchsiaBattle, fuchsiaGlobalGrass),
  'Fuchsia Battle Art ground ignores the broad Legendary GRASS row')
check(fuchsiaLegendaryN == fuchsiaN and not same(fuchsiaBattle, fuchsiaLegendary),
  'Fuchsia CITY GROUND Legendary selects the tiled turf treatment')

local lavenderBattle, lavenderN = signature('LAVENDER_TOWN', false, false)
local lavenderGlobalGrass, lavenderGlobalN = signature('LAVENDER_TOWN', false, true)
local lavenderLegendary, lavenderLegendaryN = signature('LAVENDER_TOWN', true, false)
check(lavenderN == lavenderGlobalN and same(lavenderBattle, lavenderGlobalGrass),
  'Lavender Battle Art ground ignores the broad Legendary GRASS row')
check(lavenderLegendaryN == lavenderN and not same(lavenderBattle, lavenderLegendary),
  'Lavender CITY GROUND Legendary retains its authored Legendary treatment')

local palletBattle, palletN = signature('PALLET_TOWN', false, false)
local palletGrass, palletGrassN = signature('PALLET_TOWN', false, true)
check(palletN == palletGrassN and not same(palletBattle, palletGrass),
  'GRASS still controls ordinary Overworld turf outside the two city maps')

local Disk = assert(loadfile('lib/VoxelMeshDisk.lua'))({
  require = function(name)
    if name == 'CommunityVisuals' then return Community end
    if name == 'StaticGeometry' then return { source = function(map) return map end } end
    if name == 'LoadTimings' then return { wrap = function(_, fn) return fn end } end
    return {}
  end,
})
local function cacheMap(id)
  return {
    id = id,
    def = { tileset = 'OVERWORLD', width = 1, height = 1, blocks = {} },
    tileset = {
      id = 'OVERWORLD', image = 'overworld.png', imageWidth = 128,
      imageHeight = 48, tilesPerRow = 16, blocks = {},
    },
  }
end
local function fingerprint(id, city, grass)
  Community.cityGround.value = city and 'n64memory' or 'default'
  Community.grass.value = grass and 'n64memory' or 'default'
  return Disk.fingerprint(cacheMap(id), 'body', nil, 'terrain')
end
local fuchsiaCache = fingerprint('FUCHSIA_CITY', false, false)
check(fuchsiaCache == fingerprint('FUCHSIA_CITY', false, true),
  'Fuchsia cache identity ignores unrelated GRASS changes')
check(fuchsiaCache ~= fingerprint('FUCHSIA_CITY', true, false),
  'Fuchsia CITY GROUND choice owns its persistent mesh identity')
local lavenderCache = fingerprint('LAVENDER_TOWN', false, false)
check(lavenderCache == fingerprint('LAVENDER_TOWN', false, true),
  'Lavender cache identity ignores unrelated GRASS changes')
check(lavenderCache ~= fingerprint('LAVENDER_TOWN', true, false),
  'Lavender CITY GROUND choice owns its persistent mesh identity')
local palletCache = fingerprint('PALLET_TOWN', false, false)
check(palletCache == fingerprint('PALLET_TOWN', true, false),
  'CITY GROUND does not invalidate unrelated Overworld maps')
check(palletCache ~= fingerprint('PALLET_TOWN', false, true),
  'ordinary Overworld caches still follow GRASS')

-- The static community atlas and the immutable animated atlas have separate
-- caches. Both must be map-scoped for the two cities or visit order can make
-- Lavender reuse Fuchsia's baked turf (or vice versa) while water animates.
local TerrainAtlas = assert(loadfile('lib/TerrainAtlas.lua'))({
  require = function(name)
    if name == 'CommunityVisuals' then return Community end
    return {}
  end,
})
local function replaceUpvalue(fn, wanted, replacement)
  for i = 1, 100 do
    local name = debug.getupvalue(fn, i)
    if not name then break end
    if name == wanted then
      debug.setupvalue(fn, i, replacement)
      return
    end
  end
  error('missing TerrainAtlas test seam: ' .. wanted)
end
local built = 0
replaceUpvalue(TerrainAtlas.animate, 'newEntry', function(map)
  built = built + 1
  local image = { id = map.id, release = function() end }
  return {
    specs = { { kind = 'frames', sequence = { 1 }, period = 20 } },
    frames = { ['0'] = image },
  }
end)
local function animatedMap(id)
  return {
    id = id,
    renderer = {},
    tileset = { id = 'OVERWORLD', image = 'overworld.png' },
  }
end
Community.cityGround.value = 'default'
Community.grass.value = 'default'
local fuchsiaAnimated = TerrainAtlas.animate(animatedMap('FUCHSIA_CITY'), nil, {}, false)
local lavenderAnimated = TerrainAtlas.animate(animatedMap('LAVENDER_TOWN'), nil, {}, false)
check(fuchsiaAnimated and fuchsiaAnimated.id == 'FUCHSIA_CITY'
    and lavenderAnimated and lavenderAnimated.id == 'LAVENDER_TOWN'
    and built == 2,
  'animated city atlases stay isolated regardless of shared OVERWORLD source')
check(TerrainAtlas.animate(animatedMap('FUCHSIA_CITY'), nil, {}, false) == fuchsiaAnimated
    and built == 2,
  'revisiting a city reuses only its own animated atlas')
local routeAnimated = TerrainAtlas.animate(animatedMap('ROUTE_1'), nil, {}, false)
local routeShared = TerrainAtlas.animate(animatedMap('ROUTE_2'), nil, {}, false)
check(routeAnimated == routeShared and built == 3,
  'ordinary OVERWORLD maps retain the bounded shared animated cache')

print(checks .. ' checks passed (city ground option)')
