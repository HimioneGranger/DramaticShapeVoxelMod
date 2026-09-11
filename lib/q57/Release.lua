-- Shared visual base for a chosen Pokemon sent into battle, follow, or a field move.
-- The caller owns selection, throw/open motion, spawning, and gameplay timing.
-- This module never mutates a party, entity, input, or capture state.
local V=...
local Plasma=V.require("q57/Plasma")
local Material=V.require("q57/Material")
local R={}
R.GROW_SEC,R.SETTLE_SEC,R.DURATION=1.0,.35,1.35
R.RECALL_DURATION=1.555
R.PURPOSES={battle=true,follow=true,field_move=true,recall=true}
local IDENTITY={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local function clamp(x)return math.max(0,math.min(1,x))end
local function ease(x)x=clamp(x);return x*x*x*(x*(x*6-15)+10)end
local function release(object)
  if object and type(object.release)=="function" then pcall(object.release,object)end
end
-- source means the final full-size sprite centre, mouth the open ball aperture.
-- Reverse only the intake geometry. Do not reverse the capture gameplay clock.
function R.pose(timer,source,mouth,width,height,yaw,purpose)
  assert(R.PURPOSES[purpose or "battle"],"unsupported release purpose")
  timer=tonumber(timer)
  local duration=purpose=='recall' and R.RECALL_DURATION or R.DURATION
  if not timer or timer~=timer or timer<0 or timer>=duration then return nil end
  if purpose=='recall' then
    return Plasma.pose({},timer+.77,source,mouth,width,height,yaw,1)
  end
  local p=Plasma.pose({},1.32,source,mouth,width,height,yaw)
  p.timer,p.release,p.purpose=timer,true,purpose or "battle"
  p.pull=1-ease(timer/R.GROW_SEC)
  p.convert=1-ease((timer-R.GROW_SEC)/R.SETTLE_SEC)
  p.reach,p.wrap=1,1
  -- Clear the connector as the fully grown white silhouette takes over.
  p.fade=1-ease((timer-(R.GROW_SEC-.15))/.30)
  return p
end
local Instance={}
Instance.__index=Instance
function R.new(voxel,mat4)
  assert(voxel and mat4,"release requires a renderer and matrix provider")
  return setmetatable({voxel=voxel,M=mat4},Instance)
end
function Instance:clear()
  release(self.volumeMesh);release(self.subjectMesh)
  self.volumeMesh,self.subjectMesh,self.native=nil,nil,nil
  self.volumeVertices,self.volumeIndices=nil,nil
  self.subjectVertices,self.subjectIndices,self.rest=nil,nil,nil
  self.volumeKey,self.subjectKey=nil,nil
end
local function key(p,model)
  return table.concat({p.timer,p.source[1],p.source[2],p.source[3],
    p.mouth[1],p.mouth[2],p.mouth[3],p.width,p.height,p.yaw,unpack(model)},":")
end
local function upload(self,name,vertices,indices)
  local mesh=self[name]
  if not mesh then
    mesh=self.voxel.newMesh(vertices,indices);self[name]=mesh
  elseif type(mesh.setVertices)=="function" then mesh:setVertices(vertices) end
  return mesh
end
-- Returns draw success and "active"/"complete"/"waiting"/"unavailable".
-- While active, caller suppresses the normal world sprite; after complete it
-- draws that sprite normally. Call clear on cancellation, map exit, or teardown.
function Instance:draw(timer,subject,mouth,purpose)
  timer=tonumber(timer)
  local duration=purpose=='recall' and R.RECALL_DURATION or R.DURATION
  if timer and timer>=duration then return true,"complete" end
  if not (subject and subject.mesh and subject.texture and subject.model
      and subject.center and mouth) then return false,"unavailable" end
  local p=R.pose(timer,subject.center,mouth,subject.width,subject.height,subject.yaw,purpose)
  if not p then return false,"waiting" end
  if p.pull>=.995 then return true,"active" end
  local poseKey=key(p,subject.model)
  local drawn=true
  if p.fade>.001 then
    if not self.volumeVertices then self.volumeVertices,self.volumeIndices=Plasma.newGeometry()end
    if self.volumeKey~=poseKey then
      Plasma.update(self.volumeVertices,p)
      upload(self,"volumeMesh",self.volumeVertices,self.volumeIndices)
      self.volumeKey=poseKey
    end
    -- Keep blue energy at world depth. The ordinary character bias lets the
    -- white growing silhouette cover it, without disabling wall occlusion.
    drawn=Material.draw(self.voxel,self.volumeMesh,subject.texture,IDENTITY,0,p,false) and drawn
  end
  local mesh,model=subject.mesh,subject.model
  if p.pull>0 then
    if type(mesh.getVertex)=="function" then
      if self.native~=mesh then
        local corners={}
        for i=1,4 do corners[i]={mesh:getVertex(i)}end
        release(self.subjectMesh);self.subjectMesh=nil
        self.subjectVertices,self.subjectIndices,self.rest=Plasma.newSubjectGeometry(corners)
        self.native,self.subjectKey=mesh,nil
      end
      if self.subjectKey~=poseKey then
        Plasma.updateSubject(self.subjectVertices,self.rest,p,subject.model)
        upload(self,"subjectMesh",self.subjectVertices,self.subjectIndices)
        self.subjectKey=poseKey
      end
      mesh,model=self.subjectMesh,IDENTITY
    else
      local x,y,z=Plasma.center(p,p.pull)
      local size=math.max(.001,(1-p.pull)^1.9)
      local M=self.M
      model=M.mul(M.translate(x,y,z),M.mul(M.scale(size,size,size),
        M.mul(M.translate(-p.source[1],-p.source[2],-p.source[3]),subject.model)))
    end
  end
  drawn=Material.draw(self.voxel,mesh,subject.texture,model,8.25,p,true) and drawn
  return drawn,"active"
end
return R
