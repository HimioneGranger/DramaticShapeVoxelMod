-- TEST105: undo an isolated Cut by restoring the exact saved sapling owner.
-- Terrain already contains its ground; mature groves own separate meshes.
-- A reload, invalidation, replacement mesh, or unfinished build discards this
-- shortcut. Those cases keep the ordinary terrain refresh path.
local V = ...
local M = {}
local saved = {}
local cuts, restores, fallbacks = 0, 0, 0

function M.invalidate(mapId)
  if mapId then saved[tostring(mapId)] = nil else saved = {} end
end

function M.resetStats() cuts, restores, fallbacks = 0, 0, 0 end
function M.stats() return { cuts = cuts, restores = restores, fallbacks = fallbacks } end

function M.apply(map, bx, by, before, after)
  if not (map and V.require("CommunityVisuals").customCutTrees()) then return false end
  local tileset = map.def and map.def.tileset
  if tileset ~= "OVERWORLD" and tileset ~= "GYM" then return false end
  local ok, game = pcall(require, "src.core.Game")
  local swaps = ok and game and game.data and game.data.field
                and game.data.field.cutTreeSwaps or {}
  local forward, reverse = false, false
  for _, swap in ipairs(swaps) do
    if swap.before == before and swap.after == after then forward = true end
    if swap.after == before and swap.before == after then reverse = true end
  end
  if not forward and not reverse then return false end

  local key = tostring(map.id)
  local blockKey = tostring(bx) .. "|" .. tostring(by)
  local rounds = (rawget(_G, "__ds_round_cells") or {})[key]
  local saplings = (rawget(_G, "__ds_sapling_cells") or {})[key]
  local bases = rawget(_G, "__ds_round_base") or {}
  local mesher = V.require("ChunkMesher")
  local function settled()
    return not mesher.jobPending(map.id, false) and not mesher.jobPending(map.id, true)
  end

  if reverse then
    local byBlock = saved[key]
    local record = byBlock and byBlock[blockKey]
    -- Consume before validation: no later unrelated write may reuse an undo.
    if byBlock then byBlock[blockKey] = nil end
    local valid = record and record.map == map and record.tileset == map.tileset
      and record.before == after and record.after == before
      and record.rounds == rounds and record.saplings == saplings and record.bases == bases
      and record.full == mesher.peek(map, false) and record.body == mesher.peek(map, true)
      and settled()
    if valid then
      for _, cell in ipairs(record.cells) do
        if rounds[cell.key] ~= nil or saplings[cell.key] ~= nil
           or bases[cell.baseKey] ~= nil then valid = false; break end
      end
    end
    if not valid then fallbacks = fallbacks + 1; return false end
    -- Validate every owner before changing any of them.
    for _, cell in ipairs(record.cells) do
      rounds[cell.key], saplings[cell.key] = cell.round, cell.sapling
      bases[cell.baseKey] = cell.base
    end
    restores = restores + 1
    return true
  end

  if not (rounds and saplings) then return false end
  local cells = {}
  for cell, marker in pairs(saplings) do
    local cx, cy = tostring(cell):match("^(-?%d+)|(-?%d+)$")
    cx, cy = tonumber(cx), tonumber(cy)
    if cx and cy and math.floor(cx / 2) == bx and math.floor(cy / 2) == by then
      local baseKey = key .. ":" .. (cx * 16 + 8) .. "|" .. (cy * 16 + 8)
      cells[#cells + 1] = { key = cell, round = rounds[cell], sapling = marker,
                          baseKey = baseKey, base = bases[baseKey] }
    end
  end
  if #cells == 0 then return false end
  local full, body = mesher.peek(map, false), mesher.peek(map, true)
  local canRestore = (full or body) and settled()
  for _, cell in ipairs(cells) do
    if cell.round == nil or cell.sapling ~= true then canRestore = false end
    saplings[cell.key], rounds[cell.key], bases[cell.baseKey] = nil, nil, nil
  end
  local byBlock = saved[key] or {}
  saved[key] = byBlock
  byBlock[blockKey] = canRestore and {
    map = map, tileset = map.tileset, before = before, after = after,
    rounds = rounds, saplings = saplings, bases = bases,
    full = full, body = body, cells = cells,
  } or nil
  cuts = cuts + 1
  return true
end

return M
