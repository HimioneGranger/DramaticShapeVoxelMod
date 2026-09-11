-- Optional capture-only material. Owns one shader; never changes Voxel3D state.
-- Uses the active eye's host transform and pure ray-depth pull verbatim.
local Material = {}
local shader, attempted, lastError = nil, false, nil
local IDENTITY = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}

local SOURCE = [[
varying LOVE_HIGHP_OR_MEDIUMP vec3 captureWorld;
#ifdef VERTEX
uniform mat4 vp;
uniform mat4 model;
uniform vec3 eye;
uniform vec3 curve;
uniform float pull;
uniform vec3 energyMouth;
uniform float mouthClearance;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  vec4 w = model * vertex_position;
  captureWorld = w.xyz;
  if (curve.z > 0.0) {
    vec2 cd = w.xz - curve.xy;
    w.y -= dot(cd, cd) * curve.z;
  }
  if (pull > 0.0) {
    // Preserve world depth at the aperture; do not drag energy over the shell.
    // Keep the body/terrain separation farther away, without transparency.
    float localPull = pull * (mouthClearance > 0.0 ? smoothstep(0.0, mouthClearance,
      distance(captureWorld, energyMouth)) : 1.0);
    w.xyz += normalize(eye - w.xyz) * localPull;
  }
  return vp * w;
}
#endif
#ifdef PIXEL
uniform Image sourceTexture;
uniform vec2 texelSize;
uniform float captureTime;
uniform float conversion;
uniform float subjectMode;
uniform float releaseMode;
uniform LOVE_HIGHP_OR_MEDIUMP vec3 captureOrigin;
uniform vec3 captureRight;
uniform vec2 captureSize;
uniform vec2 captureFlow;

float cloudHash(vec2 p) {
  // Keep the hash intermediate precise on mobile fragment shaders; mediump
  // rounding at 43758 can otherwise erase its fractional component entirely.
  LOVE_HIGHP_OR_MEDIUMP vec2 q = p;
  LOVE_HIGHP_OR_MEDIUMP float h = sin(dot(q, vec2(127.1, 311.7))) * 43758.5453;
  return fract(h);
}
float cloudNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = cloudHash(i);
  float b = cloudHash(i + vec2(1.0, 0.0));
  float c = cloudHash(i + vec2(0.0, 1.0));
  float d = cloudHash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
// Broad filled luminous cells, with a second scale to break their contours.
// No stepped time, narrow sine bands, independent speckle, or global flash.
float cloudBody(vec2 p) {
  float broad = cloudNoise(p);
  vec2 warp = vec2(broad - 0.5, cloudNoise(p * 0.83 + 8.7) - 0.5);
  return 0.56 * broad + 0.44 * cloudNoise(p * 2.10 + warp * 1.6 + 3.1);
}
float sharedCloud() {
  // The deformed source and surrounding intake share this exact world field.
  // No independently shaded patch can sit over the body like a second object.
  LOVE_HIGHP_OR_MEDIUMP vec3 relative = captureWorld - captureOrigin;
  vec2 bodyUV = vec2(dot(relative, captureRight) / captureSize.x,
                    relative.y / captureSize.y);
  return cloudBody(bodyUV * vec2(5.3, 6.1) - captureFlow * captureTime);
}
vec3 energyColor(float cloud, float core) {
  // Approved capture palette: saturated red, with only rare pale highlights.
  // Release uses the preserved blue flow; its growing subject is white below.
  vec3 cobalt = mix(vec3(0.66, 0.008, 0.025), vec3(0.025, 0.20, 0.90), releaseMode);
  vec3 blue = mix(vec3(0.94, 0.015, 0.045), vec3(0.045, 0.42, 1.0), releaseMode);
  vec3 ice = mix(vec3(1.0, 0.055, 0.09), vec3(0.46, 0.81, 1.0), releaseMode);
  vec3 white = mix(vec3(1.0, 0.19, 0.22), vec3(0.985, 0.995, 1.0), releaseMode);
  // Luminance comes from filled cloud cells, not a smooth specular gradient.
  vec3 body = mix(blue, ice, smoothstep(0.22, 0.48, cloud));
  body = mix(body, white, smoothstep(0.42, 0.61, cloud));
  body = mix(body, vec3(1.0, 0.92, 0.92), smoothstep(0.73, 0.84, cloud) * 0.65 * (1.0-releaseMode));
  return mix(cobalt, body, smoothstep(0.02, 0.24, core));
}
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 screen_coords) {
  if (subjectMode > 0.5) {
    vec4 source = Texel(sourceTexture, tc);
    // Same alpha-mask threshold as the host's card shader. Empty texels never
    // write depth; occupied texels remain opaque throughout the conversion.
    if (source.a < 0.5) discard;
    if (conversion <= 0.0) return vec4(source.rgb, 1.0);
    // The growing release silhouette is white, never red or blue-filled.
    if (releaseMode > 0.5) return vec4(mix(source.rgb, vec3(1.0), conversion), 1.0);
    float cloud = sharedCloud();
    // A blue boundary follows the actual alpha silhouette, including ears,
    // limbs and tails. It never substitutes an oval for the original body.
    float neighbour = min(Texel(sourceTexture, tc + vec2(texelSize.x,0.0)).a,
                          Texel(sourceTexture, tc - vec2(texelSize.x,0.0)).a);
    neighbour = min(neighbour,
                    min(Texel(sourceTexture, tc + vec2(0.0,texelSize.y)).a,
                        Texel(sourceTexture, tc - vec2(0.0,texelSize.y)).a));
    float core = mix(0.045, 1.0, step(0.5, neighbour));
    vec3 energy = energyColor(cloud, core);
    return vec4(mix(source.rgb, energy, conversion), 1.0);
  }
  // tc.x runs ball -> subject; tc.y runs once around the closed section.
  // Keep the narrow cobalt boundary only on the exposed neck near the ball.
  // At the body end its color field is identical to the source silhouette.
  float angle = tc.y * 6.28318530718;
  float core = pow(abs(sin(angle)), 0.72);
  core = mix(core, 1.0, smoothstep(0.25, 0.5, tc.x));
  return vec4(energyColor(sharedCloud(), core), 1.0);
}
#endif
]]

local function number(value, fallback)
  value = tonumber(value)
  if not value or value ~= value or value == math.huge or value == -math.huge then
    return fallback
  end
  return value
end

local function program(graphics)
  if attempted then return shader end
  if type(graphics.newShader) ~= 'function' then return nil end
  attempted = true
  local ok, result = pcall(graphics.newShader, SOURCE)
  if ok and result then
    shader, lastError = result, nil
  else
    shader, lastError = nil, tostring(result or 'capture shader unavailable')
  end
  return shader
end

-- Returns true only when this material completed the draw and state restore.
-- texture is sent as a private sampler: even the mesh's texture is untouched.
-- If unavailable, callers may draw their ordinary host material as fallback.
function Material.draw(voxel, mesh, texture, model, pull, pose, subject)
  local graphics = love and love.graphics
  if not (graphics and voxel and voxel.vp and voxel.eye and mesh and pose) then
    return false
  end
  for _, name in ipairs({'getShader','setShader','getColor','setColor','draw'}) do
    if type(graphics[name]) ~= 'function' then return false end
  end
  if subject and not texture and type(mesh.getTexture) == 'function' then
    local ok, result = pcall(mesh.getTexture, mesh)
    if ok then texture = result end
  end
  if subject and not texture then return false end
  local active = program(graphics)
  if not active then return false end

  -- Refuse to alter graphics state unless both exact prior values were read.
  local shaderOK, previousShader = pcall(graphics.getShader)
  local colorOK, r,g,b,a = pcall(graphics.getColor)
  if not (shaderOK and colorOK and r and g and b and a) then
    lastError = 'capture material could not snapshot graphics state'
    return false
  end

  local width, height = 32, 32
  if texture and type(texture.getDimensions) == 'function' then
    local ok, w, h = pcall(texture.getDimensions, texture)
    if ok then width,height = math.max(1,number(w,32)),math.max(1,number(h,32)) end
  end
  local origin = pose.source or {0,0,0}
  local mouth = pose.mouth or origin
  local yaw = number(pose.yaw,0)
  local rx,rz = number(pose.rx,math.cos(yaw)),number(pose.rz,-math.sin(yaw))
  local bodyWidth,bodyHeight = math.max(1,number(pose.width,16)),math.max(1,number(pose.height,16))
  local flowX = ((number(mouth[1],0)-number(origin[1],0))*rx
               +(number(mouth[3],0)-number(origin[3],0))*rz) / bodyWidth * 5.3
  local flowY = (number(mouth[2],0)-number(origin[2],0)) / bodyHeight * 6.1
  local flowLength = math.sqrt(flowX*flowX+flowY*flowY)
  if flowLength > 0.0001 then
    flowX,flowY = flowX/flowLength*0.95,flowY/flowLength*0.95
  else
    flowX,flowY = 0.45,0.65
  end
  if pose.release then flowX,flowY=-flowX,-flowY end
  local ok, err = pcall(function()
    active:send('vp', 'row', voxel.vp)
    active:send('model', 'row', model or IDENTITY)
    active:send('eye', voxel.eye)
    active:send('curve', {number(voxel.curveX,0), number(voxel.curveZ,0),
                          number(voxel.curveK,0)})
    active:send('pull', math.max(0,number(pull,0)))
    active:send('energyMouth', {number(mouth[1],0),number(mouth[2],0),number(mouth[3],0)})
    active:send('mouthClearance', pose.release and 0 or math.max(1,number(pull,0)*1.5,math.min(bodyWidth,bodyHeight)*.5))
    active:send('captureTime', number(pose.timer,0))
    active:send('conversion', math.max(0,math.min(1,number(pose.convert,0))))
    active:send('subjectMode', subject and 1 or 0)
    active:send('releaseMode', pose.release and 1 or 0)
    active:send('captureOrigin', {number(origin[1],0),number(origin[2],0),number(origin[3],0)})
    active:send('captureRight', {rx,0,rz})
    active:send('captureSize', {bodyWidth,bodyHeight})
    active:send('captureFlow', {flowX,flowY})
    active:send('texelSize', {1/width,1/height})
    if texture then active:send('sourceTexture', texture) end
    graphics.setShader(active)
    graphics.setColor(1,1,1,1)
    graphics.draw(mesh)
  end)
  -- Attempt both restorations independently even when send/draw/restore throws.
  -- Voxel3D's activeShader bookkeeping remains valid because we never change it.
  local restoredShader, shaderError = pcall(graphics.setShader, previousShader)
  local restoredColor, colorError = pcall(graphics.setColor, r,g,b,a)
  if not (ok and restoredShader and restoredColor) then
    lastError = tostring(err or shaderError or colorError)
    return false
  end
  lastError = nil
  return true
end

function Material.status()
  return {ready=shader~=nil, attempted=attempted, error=lastError}
end

function Material.release()
  if shader and type(shader.release) == 'function' then pcall(shader.release,shader) end
  shader, attempted, lastError = nil, false, nil
end

return Material
