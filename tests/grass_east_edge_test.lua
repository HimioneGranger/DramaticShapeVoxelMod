-- Standalone geometry regression; no ROM, graphics device or engine required.
package.loaded['src.render.Assets'] = {register = function() end}
package.loaded['src.world.Map'] = {}
local SLib = assert(loadfile('lib/Structures.lua'))({require = function(name)
  return name == 'BuildBudget' and {tick = function() end} or {}
end})
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function key(x, y) return (y + 64) * 4096 + x + 64 end
local function build(neighborArt, neighborGrass, edge, tx, ty)
  tx, ty = tx or 1, ty or 0
  local S = {grassQuads = {}, shapeAt = {}, tileAt = {}}
  S.shapeAt[key(tx, ty)] = {art = 'grass'}
  S.tileAt[key(tx, ty)] = 0
  if neighborArt then S.shapeAt[key(tx + 1, ty)] = {art = neighborArt} end
  local map = {tileset = {tilesPerRow = 1, imageWidth = 8, imageHeight = 8}}
  function map:isGrassCell(cx, cy)
    if cx == math.floor(tx / 2) and cy == math.floor(ty / 2) then return true end
    return neighborGrass
  end
  local pixels = {getPixel = function(_, x, y)
    -- A single opaque stroke; all other pixels are transparent.
    if y == 3 and x >= 2 and x <= edge then return .2, .2, .2, 1 end
    return 1, 1, 1, 0
  end}
  SLib.buildGrass(S, map, tx, tx, ty, ty, pixels)
  return S.grassQuads
end
local function signature(q)
  local out = {tostring(q.shade)}
  for i = 1, 4 do
    for j = 1, 3 do out[#out + 1] = tostring(q[i][j]) end
    for j = 1, 2 do out[#out + 1] = tostring(q.uv[i][j]) end
  end
  return table.concat(out, ',')
end
local closed = build('grass', true, 7)
local exposed = build(nil, false, 7)
check(#closed == 6 and #exposed == 5, 'only one exposed east cap removed')
local retained = {}
for _, q in ipairs(exposed) do retained[signature(q)] = true end
local removed = {}
for _, q in ipairs(closed) do
  if not retained[signature(q)] then removed[#removed + 1] = q end
end
check(#removed == 1, 'front/back/west/tip/crossed card retain exact vertices, UVs and shading')
for i = 1, 4 do check(removed[1][i][1] == 16, 'removed face is on the east tile boundary') end
check(#build('ground', true, 7) == 5, 'non-grass artwork cannot preserve the boundary cap')
check(#build('grass', false, 7) == 5, 'decorative grass in a non-encounter cell cannot preserve it')
check(#build(nil, false, 6) == 6, 'non-boundary blade caps remain closed')
check(#build('grass', true, 7, -1, -1) == 6, 'negative coordinates resolve the adjoining grass cell')
check(#build(nil, false, 7, -1, -1) == 5, 'negative-coordinate exposed boundary is softened')

package.loaded['src.core.Version'] = {engine = '0.2.53'}
package.loaded['src.core.Platform'] = {detect = function() return {os = 'Windows'} end}
local setting = {get = function() return 'default' end}
local visuals = setmetatable({layout = function() return 'default' end,
  customForest = function() return false end, customSigns = function() return false end},
  {__index = function() return setting end})
local disk = assert(loadfile('lib/VoxelMeshDisk.lua'))({require = function(name)
  if name == 'CommunityVisuals' then return visuals end
  if name == 'StaticGeometry' then return {source = function(map) return map end} end
  if name == 'LoadTimings' then return {wrap = function(_, fn) return fn end} end
  return {}
end})
local map = {id = 'TEST', def = {}, tileset = {}}
local aux = disk.fingerprint(map, 'aux', nil, 'aux')
local terrain = disk.fingerprint(map, 'body', nil, 'terrain')
check(aux:find('closed-tall-grass-v5-east-edge-softened', 1, true), 'auxiliary cache uses the new geometry identity')
check(not aux:find('closed-tall-grass-v4-camera-safe', 1, true), 'old grass cache cannot match')
check(not terrain:find('closed-tall-grass-', 1, true), 'terrain identity is unaffected by the grass revision')
check(disk.CACHE_REVISION == 37, 'combined cave cache format remains intact')
print(checks .. ' checks passed (grass east-edge geometry and cache)')
