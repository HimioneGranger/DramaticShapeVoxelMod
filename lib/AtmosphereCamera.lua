local M={}
local function finite(n,lo,hi)return type(n)=='number' and n==n and n>=lo and n<=hi end
local function vec(v)
 if type(v)~='table' then return nil end
 local r={};for i=1,3 do if not finite(v[i],-1048576,1048576)then return nil end;r[i]=v[i]end
 return r
end
local function normal(v)
 local l=math.sqrt(v[1]^2+v[2]^2+v[3]^2);if l<1e-8 then return nil end
 return {v[1]/l,v[2]/l,v[3]/l}
end
local function cross(a,b)return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function copy(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
function M.build(eye,focus,up,near,far,fov,mode)
 eye,focus,up=vec(eye),vec(focus),vec(up)
 if not eye or not focus or not up or not finite(near,.001,1048576)or not finite(far,near+.001,1048576)or not finite(fov,.001,math.pi-.001)then return nil end
 if mode~='first_person' and mode~='third_person' and mode~='diorama'then return nil end
 local forward=normal({focus[1]-eye[1],focus[2]-eye[2],focus[3]-eye[3]});if not forward then return nil end
 local right=normal(cross(forward,up));if not right then return nil end
 local vertical=normal(cross(right,forward));if not vertical then return nil end
 return {eye=eye,focus=focus,forward=forward,right=right,up=vertical,near=near,far=far,fov=fov,mode=mode,overhead=mode~='diorama'}
end
function M.complete(facts,frame,mapId)
 if not facts or not finite(frame,0,9007199254740991)or frame%1~=0 or type(mapId)~='string'or #mapId>128 then return nil end
 local clean=M.build(facts.eye,facts.focus,facts.up,facts.near,facts.far,facts.fov,facts.mode);if not clean then return nil end
 clean.sampledFrame=frame;clean.mapId=mapId;return clean
end
function M.snapshot(facts,frame,mapId,mode)
 local function unavailable(reason)return {available=false,reason=reason,currentFrame=frame,source='last_completed_desktop_center'}end
 if not facts then return unavailable('no_completed_center_camera')end
 if facts.mapId~=mapId then return unavailable('map_changed')end
 if facts.mode~=mode then return unavailable('camera_mode_changed')end
 local age=frame-facts.sampledFrame
 if age<0 or age>2 then return unavailable('stale_camera')end
 local r=copy(facts);r.available=true;r.currentFrame=frame;r.ageFrames=age;r.source='last_completed_desktop_center';return r
end
return M
