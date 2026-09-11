-- Ember Legacy: original q58 geometry, palette, and instance equations.
local V=...
local Ref=V.require('q58/SuccessStars')
local Voxel3D=V.require('Voxel3D')
local M=V.require('Mat4')
local Ball=V.require('Pokeball')
local Stars={DURATION=Ref.DURATION}
local mesh,texture,cachedBall,cachedFrame,models
local function release(x)if x and x.release then pcall(x.release,x)end end
function Stars.invalidate()
  release(mesh);release(texture)
  mesh,texture,cachedBall,cachedFrame,models=nil,nil,nil,nil,nil
end
local function ensure()
  if not mesh then
    local v,i=Ref.buildMesh();mesh=Voxel3D.newMesh(v,i)
  end
  if not texture then
    local data=love.image.newImageData(4,1)
    for i,c in ipairs(Ref.PALETTE_255)do data:setPixel(i-1,0,c[1]/255,c[2]/255,c[3]/255,1)end
    local ok,value=pcall(love.graphics.newImage,data);release(data)
    if not ok then error(value)end
    texture=value;texture:setFilter('nearest','nearest')
  end
  return mesh and texture
end
function Stars.prepare(timer,ball,frame)
  if not ball or not ball.pos then models=nil;return end
  if frame~=nil and cachedBall==ball and cachedFrame==frame then return end
  cachedBall,cachedFrame=ball,frame;models={}
  -- q58's physical shell radius is .048; host shell radius is Ball.R.
  -- Match actual shell size, not a separately guessed global effect scale.
  local scale=(Ball.R/.048)*(tonumber(ball.scale) or 1)
  local f={scale,0,0,ball.pos[1],0,scale,0,ball.pos[2],0,0,scale,ball.pos[3],0,0,0,1}
  for _,p in ipairs(Ref.instances(timer,f))do
    models[#models+1]=M.mul(M.translate(p.x,p.y,p.z),
      M.mul(M.rotateY(p.yaw),M.scale(p.scale,p.scale,p.scale)))
  end
end
function Stars.draw(timer,ball,pull,frame)
  Stars.prepare(timer,ball,frame)
  if not models or #models==0 then return false end
  if not ensure()then return false end
  for _,model in ipairs(models)do Voxel3D.draw(mesh,texture,model,pull or 0)end
  return true
end
return Stars
