-- q57 presentation for CPU-skinned Stadium 1 meshes. Normal rig rows remain
-- untouched; a separate mesh serves the camera and shadow passes.
local V=...
local Plasma=V.require('q57/Plasma')
local Material=V.require('q57/Material')
local Voxel3D=V.require('Voxel3D')
local Mat4=V.require('Mat4')
local F={}
local IDENTITY=Mat4.identity()
function F.clear(rig)
  for _,part in ipairs(rig.parts or {}) do
    if part.q57Mesh then pcall(part.q57Mesh.release,part.q57Mesh) end
    part.q57Mesh,part.q57Rows=nil,nil
  end
  rig.q57Pose=nil
end
function F.prepare(rig,matrix,pose)
  rig.q57Pose=nil
  if not pose or pose.subjectDone then return false end
  local ok,err=pcall(function()
    for _,part in ipairs(rig.parts or {}) do
      if part.texture then
        if not part.q57Rows then
          part.q57Rows={}
          for i,row in ipairs(part.rows) do part.q57Rows[i]={unpack(row)} end
        end
        Plasma.updateSubject(part.q57Rows,part.rows,pose,matrix)
        if not part.q57Mesh then
          part.q57Mesh=love.graphics.newMesh(Voxel3D.FORMAT,part.q57Rows,'triangles','dynamic')
          part.q57Mesh:setVertexMap(part.prim.index)
        else part.q57Mesh:setVertices(part.q57Rows) end
      end
    end
  end)
  if not ok then F.clear(rig);rig.q57Error=tostring(err);return false end
  rig.q57Pose,rig.q57Error=pose,nil
  return true
end
function F.drawPart(rig,part,pull)
  if not (rig.q57Pose and part.q57Mesh) then return false end
  if not Material.draw(Voxel3D,part.q57Mesh,part.texture,IDENTITY,pull,rig.q57Pose,true) then
    -- Preserve the deformation if the optional energy shader is unavailable.
    rig.q57Error=Material.status().error or 'q57 material unavailable'
    Voxel3D.draw(part.q57Mesh,part.texture,IDENTITY,pull)
  end
  return true
end
function F.shadowPart(rig,part,shadowMap)
  if not (rig.q57Pose and part.q57Mesh) then return false end
  shadowMap.draw(part.q57Mesh,part.texture,IDENTITY)
  return true
end
return F
