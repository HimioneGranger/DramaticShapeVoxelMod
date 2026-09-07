local state={angle=0,FOCAL=1,isFirstPerson=function()return true end,isThirdPerson=function()return false end}
local V={require=function(name)
 if name=='VoxelState'then return state end
 if name=='Mat4' or name=='AtmosphereCamera'then return assert(loadfile('lib/'..name..'.lua'))()end
 return {}
end}
local R=assert(loadfile('lib/Voxel3D.lua'))(V)
R.camera={eye={0,5,10},focus={0,5,0},up={0,1,0},fov=1}
R.viewProjection(0,0,100,100)
assert(R.atmosphereCameraCandidate.far==4136 and R.atmosphereCameraCandidate.near==1)
assert(R.atmosphereCameraCandidate.mode=='first_person' and R.atmosphereCameraCandidate.overhead)
R.camera.eye[1]=2;assert(R.atmosphereCameraCandidate.eye[1]==0)
R.camera.view={};R.viewProjection(0,0,100,100);assert(R.atmosphereCameraCandidate==nil,'external eye published as center')
R.camera=nil;state.isFirstPerson=function()return false end
R.viewProjection(0,0,100,100)
assert(R.atmosphereCameraCandidate.far==4496 and not R.atmosphereCameraCandidate.overhead)
assert(R.atmosphereCameraCandidate.up[3]==-1)
print('PASS actual Voxel3D placed/orbit projection facts and external-eye exclusion')
