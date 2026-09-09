-- Viridian Forest's grounded finishing pass.
--
-- The ROM's stump quartet is useful collision/layout data, but its bright cut
-- face reads as a white-and-orange crate once the drawing is extruded.  When
-- the existing VIRIDIAN FOREST: LEGENDARY VISUALS row is selected,
-- Structures hides only that source hull and this module puts a low faceted
-- boulder back on the exact same cell.  Nothing here edits map blocks,
-- walkability, encounters or object positions.
--
-- Four deterministic silhouette families keep authored rows from looking
-- stamped: a low slab, a tall crag, broad fieldstone, and a split boulder.
-- They share one tiny generated stone/moss texture and one mesh per map, so
-- the steady-state cost is one draw call for the whole forest (and the same
-- cached mesh is reused by the battle stage).

local V = ...

local Voxel3D = V.require("Voxel3D")
local Mat4 = V.require("Mat4")
local CommunityVisuals = V.require("CommunityVisuals")
local RenderDistance = V.require("RenderDistance")
local TileRenderer = require("src.render.TileRenderer")

local Dressing = {}

local cache = {}
local rockTexture = nil

local function idFor(map)
  return map and (map.id or (map.def and map.def.id)) or nil
end

function Dressing.isViridian(map)
  if not map then return false end
  local tileset = tostring((map.tileset and map.tileset.id)
                    or (map.def and map.def.tileset) or "")
  return tileset == "FOREST" and tostring(idFor(map) or "") == "VIRIDIAN_FOREST"
end

-- Keep this synchronized with Structures.ROUND_RING (four 8px tiles). The
-- replacement owns the same two-cell visual apron that the round-hull builder
-- keeps at a forest edge; it never expands the rendered border beyond it.
local RING_CELLS = 2

local function tileAt(map, tx, ty)
  local def = map.def or {}
  local wc = map.widthCells or (tonumber(def.width) or 0) * 2
  local hc = map.heightCells or (tonumber(def.height) or 0) * 2
  local tw, th = wc * 2, hc * 2
  if tx >= 0 and ty >= 0 and tx < tw and ty < th then
    local ok, tile = pcall(function() return map:tileAt(tx, ty) end)
    return ok and tile or nil
  end
  local ok, borderId = pcall(TileRenderer.borderBlockFor, map)
  local block = ok and borderId and map.tileset
                and map.tileset.blocks and map.tileset.blocks[borderId + 1]
  if not block then return nil end
  return block[(ty % 4) * 4 + (tx % 4) + 1] or 0
end

-- The exact authored 2x2-tile cut-stump drawing.  Requiring all four tiles is
-- what keeps an unrelated use of any one brown tile from becoming a rock.
function Dressing.isBoulderCell(map, cx, cy)
  return Dressing.isViridian(map)
     and tileAt(map, cx * 2,     cy * 2)     == 2
     and tileAt(map, cx * 2 + 1, cy * 2)     == 3
     and tileAt(map, cx * 2,     cy * 2 + 1) == 18
     and tileAt(map, cx * 2 + 1, cy * 2 + 1) == 19
end

local function hash01(x, y, salt)
  local n = math.sin(x * 12.9898 + y * 78.233 + salt * 37.719) * 43758.5453
  return n - math.floor(n)
end

local function clamp(v)
  return math.max(0, math.min(1, v))
end

local function texture()
  if rockTexture ~= nil then return rockTexture or nil end
  if not (love and love.image and love.image.newImageData
          and love.graphics and love.graphics.newImage) then
    rockTexture = false
    return nil
  end
  local ok, image = pcall(function()
    local w, h = 64, 64
    local data = love.image.newImageData(w, h)
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local coarse = hash01(math.floor(x / 7), math.floor(y / 6), 11) - 0.5
        local grain = hash01(math.floor(x / 2), math.floor(y / 2), 17) - 0.5
        local fleck = hash01(x, y, 23)
        local r, g, b
        if y < 32 then
          -- Moss cap: broad green islands broken by exposed warm grey stone.
          local moss = hash01(math.floor((x + 3) / 8),
                              math.floor((y + 5) / 7), 31)
          if moss > 0.34 then
            local v = 0.80 + coarse * 0.22 + grain * 0.08
            r, g, b = 0.25 * v, 0.36 * v, 0.17 * v
          else
            local v = 0.79 + coarse * 0.18 + grain * 0.10
            r, g, b = 0.34 * v, 0.31 * v, 0.25 * v
          end
          if fleck > 0.965 then
            r, g, b = r * 1.18, g * 1.22, b * 1.10
          elseif fleck < 0.025 then
            r, g, b = r * 0.67, g * 0.70, b * 0.66
          end
        else
          -- Sides: damp brown-grey fieldstone with restrained lichen flecks.
          local v = 0.82 + coarse * 0.20 + grain * 0.10
          r, g, b = 0.35 * v, 0.32 * v, 0.26 * v
          if fleck > 0.975 then
            r, g, b = 0.26, 0.34, 0.17
          elseif fleck < 0.020 then
            r, g, b = r * 0.58, g * 0.60, b * 0.59
          end
        end
        data:setPixel(x, y, clamp(r), clamp(g), clamp(b), 1)
      end
    end
    local out = love.graphics.newImage(data)
    out:setFilter("nearest", "nearest")
    out:setWrap("repeat", "clamp")
    return out
  end)
  rockTexture = (ok and image) or false
  return rockTexture or nil
end

local function addQuad(verts, indices, quad, uv, shade)
  local q = #verts / 4
  for i = 1, 4 do
    verts[#verts + 1] = {
      quad[i][1], quad[i][2], quad[i][3], uv[i][1], uv[i][2], shade,
    }
  end
  Voxel3D.pushQuad(indices, q)
end

local FAMILY = {
  -- Low trail-side slab: long plan, low crown and broad shoulder.
  { lobes = {
    { sides=7, rx=7.45, rz=4.85, h=5.15, low=.84, shoulder=.73 },
  } },
  -- Upright crag: narrow base and a visibly off-centre high point.
  { lobes = {
    { sides=7, rx=5.55, rz=5.15, h=9.35, low=.70, shoulder=.50,
      peakLean=1.35 },
  } },
  -- Broad old fieldstone: full footprint without the first family's flatness.
  { lobes = {
    { sides=8, rx=7.25, rz=6.20, h=7.05, low=.78, shoulder=.66 },
  } },
  -- Two interlocked stones. They still occupy one authored collision cell and
  -- are packed into the same map mesh, so the silhouette changes, not cost in
  -- draw calls or gameplay behavior.
  { lobes = {
    { sides=6, rx=5.10, rz=4.35, h=6.15, low=.78, shoulder=.59,
      ox=-2.45, oz=-.55, yaw=-.18 },
    { sides=6, rx=4.45, rz=3.90, h=4.75, low=.81, shoulder=.67,
      ox= 2.55, oz= .75, yaw= .31 },
  } },
}

local function ring(cx, cy, centerX, centerZ, spec, count, yaw, scale, y,
                    salt)
  local out = {}
  for i = 0, count - 1 do
    local a = yaw + i * math.pi * 2 / count
    local wobble = 0.88 + hash01(cx * 17 + i, cy * 13 - i, salt) * 0.22
    out[i + 1] = {
      centerX + math.cos(a) * spec.rx * scale * wobble,
      y + (hash01(cx + i * 3, cy - i * 5, salt + 7) - 0.5) * 0.34,
      centerZ + math.sin(a) * spec.rz * scale * wobble,
    }
  end
  return out
end

local function appendLobe(verts, indices, cx, cy, centerX, centerZ, spec,
                          baseYaw, scale, salt)
  local count = spec.sides
  local yaw = baseYaw + (spec.yaw or 0)
                  + (hash01(cx, cy, salt + 2) - .5) * .20
  local height = spec.h * scale * (0.94 + hash01(cx, cy, salt + 4) * 0.12)
  local low = ring(cx, cy, centerX, centerZ, spec, count, yaw,
                   spec.low or .76, 0.12, salt + 10)
  local belly = ring(cx, cy, centerX, centerZ, spec, count, yaw,
                     1.00, height * 0.34, salt + 20)
  -- A small independent twist makes the upper facets lean instead of tracing
  -- the lower ring as a uniformly scaled dome.
  local shoulderYaw = yaw + (hash01(cx, cy, salt + 6) - .5) * .32
  local shoulder = ring(cx, cy, centerX, centerZ, spec, count, shoulderYaw,
                        spec.shoulder or .62, height * 0.69, salt + 30)
  local peakLean = spec.peakLean or .9
  local peak = {
    centerX + (hash01(cx, cy, salt + 40) - 0.5) * peakLean * 2,
    height,
    centerZ + (hash01(cx, cy, salt + 44) - 0.5) * peakLean * 2,
  }
  for i = 1, count do
    local j = i % count + 1
    local a = yaw + (i - 0.5) * math.pi * 2 / count
    local sun = (math.cos(a) + math.sin(a)) * 0.5
    local lowerShade = 0.61 + (sun + 1) * 0.075
    local upperShade = 0.70 + (sun + 1) * 0.085
    local u0, u1 = (i - 1) / count, i / count
    addQuad(verts, indices,
      { low[i], low[j], belly[j], belly[i] },
      { {u0,.98}, {u1,.98}, {u1,.75}, {u0,.75} }, lowerShade)
    addQuad(verts, indices,
      { belly[i], belly[j], shoulder[j], shoulder[i] },
      { {u0,.75}, {u1,.75}, {u1,.51}, {u0,.51} }, upperShade)
    local function topUV(p)
      return { 0.5 + (p[1] - centerX) / 16 * 0.88,
               0.25 + (p[3] - centerZ) / 16 * 0.44 }
    end
    addQuad(verts, indices,
      { peak, shoulder[i], shoulder[j], peak },
      { topUV(peak), topUV(shoulder[i]), topUV(shoulder[j]), topUV(peak) },
      0.94 + hash01(cx + i, cy - i, salt + 50) * 0.05)
  end
end

local function appendBoulder(verts, indices, cx, cy)
  local familyIndex = math.floor(hash01(cx, cy, 41) * #FAMILY) + 1
  local family = FAMILY[familyIndex]
  local baseYaw = hash01(cx, cy, 43) * math.pi * 2
  local scale = 0.94 + hash01(cx, cy, 47) * 0.12
  local jitterX = (hash01(cx, cy, 79) - .5) * .9
  local jitterZ = (hash01(cx, cy, 83) - .5) * .9
  local ca, sa = math.cos(baseYaw), math.sin(baseYaw)
  for i, spec in ipairs(family.lobes) do
    local ox, oz = spec.ox or 0, spec.oz or 0
    local centerX = cx * 16 + 8 + jitterX + ox * ca - oz * sa
    local centerZ = cy * 16 + 8 + jitterZ + ox * sa + oz * ca
    appendLobe(verts, indices, cx, cy, centerX, centerZ, spec,
               baseYaw, scale, 101 + i * 67)
  end
end

function Dressing.geometry(map)
  local verts, indices, count = {}, {}, 0
  if not Dressing.isViridian(map) then return verts, indices, count end
  local def = map.def or {}
  local wc = map.widthCells or (tonumber(def.width) or 0) * 2
  local hc = map.heightCells or (tonumber(def.height) or 0) * 2
  for cy = -RING_CELLS, hc + RING_CELLS - 1 do
    for cx = -RING_CELLS, wc + RING_CELLS - 1 do
      if Dressing.isBoulderCell(map, cx, cy) then
        appendBoulder(verts, indices, cx, cy)
        count = count + 1
      end
    end
  end
  return verts, indices, count
end

local function entryFor(map)
  local key = idFor(map) or tostring(map)
  local held = cache[key]
  if held and held.map == map then return held end
  if held and held.mesh then pcall(held.mesh.release, held.mesh) end
  local verts, indices, count = Dressing.geometry(map)
  local mesh = count > 0 and Voxel3D.newMesh(verts, indices) or nil
  held = { map = map, mesh = mesh, count = count }
  cache[key] = held
  return held
end

local function drawMap(map, ox, oz)
  if not Dressing.isViridian(map) then return end
  local tx = texture()
  if not tx then return end
  local entry = entryFor(map)
  if not entry.mesh then return end
  local model = ((ox or 0) ~= 0 or (oz or 0) ~= 0)
    and Mat4.translate(ox or 0, 0, oz or 0) or nil
  Voxel3D.draw(entry.mesh, tx, model)
end

function Dressing.draw(state)
  if not CommunityVisuals.customForest() then return end
  if not state then return end
  drawMap(state.map, 0, 0)
  for _, neighbor in ipairs(state.neighbors or {}) do
    if RenderDistance.neighbor(neighbor, state.player) then
      drawMap(neighbor.map, neighbor.ox or 0, neighbor.oy or 0)
    end
  end
end

function Dressing.drawBattle(host, neighbors)
  if not CommunityVisuals.customForest() then return end
  drawMap(host, 0, 0)
  for _, neighbor in ipairs(neighbors or {}) do
    drawMap(neighbor.map, neighbor.ox or 0, neighbor.oy or 0)
  end
end

function Dressing.invalidate(mapId)
  for key, entry in pairs(cache) do
    if mapId == nil or tostring(key) == tostring(mapId) then
      if entry.mesh then pcall(entry.mesh.release, entry.mesh) end
      cache[key] = nil
    end
  end
  if mapId == nil then
    if rockTexture and rockTexture.release then
      pcall(rockTexture.release, rockTexture)
    end
    rockTexture = nil
  end
end

return Dressing
