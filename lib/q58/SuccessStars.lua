-- Portable successful-capture star burst extracted from the reviewed VRITK q58.
-- Renderer-neutral: buildMesh() supplies geometry and instances() supplies the
-- three world-space star transforms. See README.md before integrating.

local Stars = {}

Stars.DURATION = 0.90
Stars.PALETTE_255 = {
  { 255, 226, 76 },
  { 255, 248, 192 },
  { 196, 118, 10 },
  { 255, 255, 244 },
}

local function clamp01(value)
  return math.max(0, math.min(1, tonumber(value) or 0))
end

local function smootherstep(value)
  local t = clamp01(value)
  return t * t * t * (t * (t * 6 - 15) + 10)
end

function Stars.pose(timer)
  local u = clamp01((tonumber(timer) or 0) / Stars.DURATION)
  if u <= 0 or u >= 1 then return nil end
  local pop = smootherstep(u / 0.24)
  local settle = smootherstep((u - 0.24) / 0.76)
  return {
    progress = u,
    scale = 0.58 + pop * 0.92 - settle * 0.22,
    spin = (1 - settle) * 0.22,
    lift = math.sin(u * math.pi) * 0.006,
    halo = u < 0.34 and math.sin((u / 0.34) * math.pi) or 0,
  }
end

-- Exact q58 crossed, double-sided five-point star: 22 vertices, 120 indices.
function Stars.buildMesh()
  local vertices, indices = {}, {}
  for plane = 1, 2 do
    local center = #vertices + 1
    vertices[center] = { 0, 0, 0, 0.125, 0.5, 1 }
    for i = 0, 9 do
      local angle = math.pi / 2 + i * math.pi / 5
      local radius = i % 2 == 0 and 0.018 or 0.008
      local x, y = math.cos(angle) * radius, math.sin(angle) * radius
      vertices[#vertices + 1] = {
        plane == 1 and x or 0,
        y,
        plane == 2 and x or 0,
        0.125, 0.5, 1,
      }
    end
    for i = 0, 9 do
      local a = center + 1 + i
      local b = center + 1 + ((i + 1) % 10)
      indices[#indices + 1] = center
      indices[#indices + 1] = a
      indices[#indices + 1] = b
      indices[#indices + 1] = center
      indices[#indices + 1] = b
      indices[#indices + 1] = a
    end
  end
  return vertices, indices
end

local function matrixScale(frame)
  if type(frame) ~= "table" then return nil end
  local x, y, z = tonumber(frame[1]), tonumber(frame[5]), tonumber(frame[9])
  if not (x and y and z) then return nil end
  local scale = math.sqrt(x * x + y * y + z * z)
  return scale > 0 and scale or nil
end

-- q58 row-major matrix convention: translation at indices 4, 8 and 12.
-- Returned stars stay world-horizontal and intentionally ignore ball tilt.
function Stars.instances(timer, ballFrame, fallbackWorldScale)
  local pose = Stars.pose(timer)
  if not (pose and type(ballFrame) == "table") then return {} end
  local worldScale = matrixScale(ballFrame) or tonumber(fallbackWorldScale) or 10
  local u = pose.progress
  local radius = 0.052 + 0.032 * u
  local lift = 0.048 + 0.050 + 0.030 * u
  local size = math.sin(math.pi * u) ^ 0.45 * worldScale
  local result = {}
  for i = 0, 2 do
    local angle = 0.25 + i * math.pi * 2 / 3 + 0.55 * u
    result[#result + 1] = {
      x = ballFrame[4] + math.cos(angle) * radius * worldScale,
      y = ballFrame[8] + lift * worldScale,
      z = ballFrame[12] + math.sin(angle) * radius * worldScale,
      yaw = angle,
      scale = size,
    }
  end
  return result
end

return Stars
