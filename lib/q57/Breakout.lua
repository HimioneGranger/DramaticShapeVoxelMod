-- q57 desktop breakout: extracted original geometry and pose; host adapter below.
local V=...
local M=V.require('Mat4')
local voxel=V.require('Voxel3D')
local B={}
local FAIL_BREAK_SEC=.28
local function clamp01(x)return math.max(0,math.min(1,x))end
local function smootherstep(x)x=clamp01(x);return x*x*x*(x*(x*6-15)+10)end
function B.pose(timer)
  local u = clamp01((tonumber(timer) or 0) / FAIL_BREAK_SEC)
  if u <= 0.03 or u >= 0.94 then return nil end
  local expansion = smootherstep((u - 0.03) / 0.72)
  local core = math.sin(clamp01((u - 0.03) / 0.78) * math.pi)
  return {
    progress = u,
    scale = 0.42 + expansion * 2.25,
    core = math.max(0, core),
    spin = u * math.pi * 0.55,
    halo = u < 0.62 and math.sin((u / 0.62) * math.pi) or 0,
  }
end

local function paletteImage(colors)
  if not (love.image and love.image.newImageData
          and love.graphics and love.graphics.newImage) then return nil end
  local okData, data = pcall(love.image.newImageData, #colors, 1)
  if not (okData and data) then return nil end
  for i, c in ipairs(colors) do
    data:setPixel(i - 1, 0, c[1] / 255, c[2] / 255, c[3] / 255, 1)
  end
  local okImage, image = pcall(love.graphics.newImage, data)
  if not okImage then return nil end
  pcall(image.setFilter, image, "nearest", "nearest")
  return image
end


local function addRing(Voxel3D, verts, indices, inner, outer, color, segments)
  local u = (color - 0.5) / 4
  segments = segments or 32
  for segment = 0, segments - 1 do
    local a0 = segment * math.pi * 2 / segments
    local a1 = (segment + 1) * math.pi * 2 / segments
    local c0, s0 = math.cos(a0), math.sin(a0)
    local c1, s1 = math.cos(a1), math.sin(a1)
    local base = #verts / 4
    verts[#verts + 1] = { c0 * inner, s0 * inner, 0, u, 0.5, 1 }
    verts[#verts + 1] = { c0 * outer, s0 * outer, 0, u, 0.5, 1 }
    verts[#verts + 1] = { c1 * outer, s1 * outer, 0, u, 0.5, 1 }
    verts[#verts + 1] = { c1 * inner, s1 * inner, 0, u, 0.5, 1 }
    Voxel3D.pushQuad(indices, base)
  end
end


local function buildRecallMesh(Voxel3D)
  local verts, indices = {}, {}
  -- A deterministic packet of small two-tone round motes. Six independently
  -- placed packets form the dissolve and spiral stream. The previous mesh used
  -- large four-corner diamonds and cloned the same sheet four times, which read
  -- as rigid confetti in-headset rather than energy particles.
  local function disc(cx, cy, cz, radius, color, segments)
    local u = (color - 0.5) / 4
    segments = segments or 6
    for segment = 0, segments - 1 do
      local a0 = segment * math.pi * 2 / segments
      local a1 = (segment + 1) * math.pi * 2 / segments
      local base = #verts / 4
      verts[#verts + 1] = { cx, cy, cz, u, 0.5, 1 }
      verts[#verts + 1] = {
        cx + math.cos(a0) * radius, cy + math.sin(a0) * radius,
        cz, u, 0.5, 1,
      }
      verts[#verts + 1] = {
        cx + math.cos(a1) * radius, cy + math.sin(a1) * radius,
        cz, u, 0.5, 1,
      }
      verts[#verts + 1] = { cx, cy, cz, u, 0.5, 1 }
      Voxel3D.pushQuad(indices, base)
    end
  end

  local golden = math.pi * (3 - math.sqrt(5))
  for i = 1, 48 do
    local ring = math.sqrt((i - 0.5) / 48) * 0.47
    local angle = i * golden
    local x = math.cos(angle) * ring * (0.84 + (i % 4) * 0.035)
    local y = math.sin(angle) * ring + math.sin(i * 1.71) * 0.025
    local z = ((i % 7) - 3) * 0.0012
    local size = 0.014 + (i % 6) * 0.0018
    local color = 1 + ((i * 5) % 3)
    disc(x, y, z, size, color, 6)
    disc(x, y, z + 0.0005, size * 0.42, 4, 5)
    -- A minority of motes carry a tiny trailing bead. It breaks up the cloned
    -- packet silhouette during motion without introducing a particle emitter.
    if i % 4 == 0 then
      local tail = size * 1.35
      disc(x - math.cos(angle) * tail, y - math.sin(angle) * tail,
        z - 0.0004, size * 0.46, color, 5)
    end
  end
  return Voxel3D.newMesh(verts, indices)
end


local function buildButtonFlashMesh(Voxel3D)
  local verts, indices = {}, {}
  addRing(Voxel3D, verts, indices, 0, 0.012, 4, 20)
  addRing(Voxel3D, verts, indices, 0.012, 0.017, 1, 20)
  -- A flat decal vanishes when the capture mouth turns toward the Pokemon.
  -- Give the red lamp a shallow outer wall so it remains visible in profile.
  local u = (1 - 0.5) / 4
  for segment = 0, 19 do
    local a0 = segment * math.pi * 2 / 20
    local a1 = (segment + 1) * math.pi * 2 / 20
    local base = #verts / 4
    verts[#verts + 1] = { math.cos(a0) * 0.017,
      math.sin(a0) * 0.017, -0.0025, u, 0.5, 1 }
    verts[#verts + 1] = { math.cos(a0) * 0.017,
      math.sin(a0) * 0.017, 0.0025, u, 0.5, 1 }
    verts[#verts + 1] = { math.cos(a1) * 0.017,
      math.sin(a1) * 0.017, 0.0025, u, 0.5, 1 }
    verts[#verts + 1] = { math.cos(a1) * 0.017,
      math.sin(a1) * 0.017, -0.0025, u, 0.5, 1 }
    Voxel3D.pushQuad(indices, base)
  end
  return Voxel3D.newMesh(verts, indices)
end


local spray,halo,palette
function B.draw(timer,mouth,yaw,ballScale)
  local p=B.pose(timer);if not p then return false end
  spray=spray or buildRecallMesh(voxel)
  halo=halo or buildButtonFlashMesh(voxel)
  palette=palette or paletteImage({{116,204,255},{202,244,255},{54,126,255},{255,255,255}})
  if not(spray and halo and palette)then return false end
  -- Convert the source's metre-sized effect to Battle Art pixel-world units.
  local units=2.2*(ballScale or 1)/.048
  local base=M.mul(M.translate(mouth[1],mouth[2],mouth[3]),
    M.mul(M.rotateY(yaw or 0),M.scale(units,units,units)))
  voxel.seams(false);voxel.glass(false)
  for layer=1,3 do
    local scale=p.scale*(.86+layer*.11)
    local model=M.mul(base,M.rotateZ(p.spin+(layer-2)*math.pi*.18))
    model=M.mul(model,M.scale(scale,scale,.38))
    voxel.draw(spray,palette,model,0)
  end
  if p.halo>0 then
    local ring=M.mul(base,M.translate(0,0,.048+.018))
    ring=M.mul(ring,M.scale(1.2+p.halo*2.4,1.2+p.halo*2.4,1))
    voxel.draw(halo,palette,ring,0)
  end
  return true
end
function B.clear()
 for _,o in ipairs({spray,halo,palette})do if o and o.release then o:release()end end
 spray,halo,palette=nil,nil,nil
end
return B
