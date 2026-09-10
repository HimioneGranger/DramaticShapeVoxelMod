-- Stable read-only diagnostics provider for external performance monitors.
--
-- This is intentionally a sampling API rather than a profiler UI. Battle Art
-- owns the counters because it knows what "cache hit", "tree queue" and the
-- timing buckets mean; a separate monitor mod owns capture cadence, reporting
-- and presentation. Consumers must not depend on Battle Art private files.

local V = ...

local M = {
  API_VERSION = 1,
  SCHEMA_VERSION = 1,
  SOURCE_MOD_ID = "BATTLE_ART_VOXEL_FORK",
}

local function clock()
  if love and love.timer and love.timer.getTime then return love.timer.getTime() end
  return os.clock()
end

local function copy(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return nil end
  local out = {}
  seen[value] = out
  for key, child in pairs(value) do
    local copiedKey = type(key) == "table" and tostring(key) or key
    out[copiedKey] = copy(child, seen)
  end
  return out
end

local function call(module, method, fallback)
  local okModule, value = pcall(V.require, module)
  if not okModule or type(value) ~= "table" or type(value[method]) ~= "function" then
    return fallback
  end
  local ok, result = pcall(value[method])
  if not ok then return fallback end
  return result
end

function M.snapshot(hostVersion)
  local ram = call("VoxelMeshDisk", "ramStats", {})
  local timing = call("LoadTimings", "snapshot", {})
  local out = {
    apiVersion = M.API_VERSION,
    schemaVersion = M.SCHEMA_VERSION,
    sourceModId = M.SOURCE_MOD_ID,
    sourceVersion = tostring(hostVersion or "unknown"),
    monotonicSeconds = clock(),
    timings = copy(timing),
    cache = {
      available = call("VoxelMeshDisk", "available", false) and true or false,
      precacheAvailable = call("VoxelMeshDisk", "precacheAvailable", false) and true or false,
      readOnly = call("VoxelMeshDisk", "cacheReadOnly", true) and true or false,
      ram = copy(ram),
      trace = copy(call("CacheTrace", "snapshot", {})),
    },
    mesher = copy(call("ChunkMesher", "stats", {})),
    trees = copy(call("CommunityFlora", "treeStats", {})),
    shadow = copy(call("ShadowMap", "stats", {})),
    saplings = copy(call("SaplingEdits", "stats", {})),
  }
  return out
end

function M.export(hostVersion)
  hostVersion = tostring(hostVersion or "unknown")
  return {
    apiVersion = M.API_VERSION,
    schemaVersion = M.SCHEMA_VERSION,
    sourceModId = M.SOURCE_MOD_ID,
    sourceVersion = hostVersion,
    capabilities = {
      timings = 1,
      cache = 1,
      cacheTrace = 1,
      storage = 1,
      mesher = 1,
      trees = 1,
      shadow = 1,
      saplings = 1,
    },
    snapshot = function() return M.snapshot(hostVersion) end,
    storageSnapshot = function()
      return copy(call("VoxelMeshDisk", "stats", {}))
    end,
  }
end

return M
