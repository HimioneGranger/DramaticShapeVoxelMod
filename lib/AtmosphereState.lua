-- Private contract prototype; no advertised renderer capabilities.
local M={}
local function num(a,b)return {kind='number',lo=a,hi=b}end
local function vec(n,a,b)return {kind='vector',n=n,lo=a,hi=b}end
local u,b,rgb=num(0,1),{kind='boolean'},vec(3,0,1)
local schema={sky={dim=u,flash=u,smooth=b,dither=b,replaceCelestials=b},
 tint={multiplier=vec(3,0,2),additive=rgb},haze={density=num(0,.00010),color=rgb},
 cloud={coverage=u,opacity=u,overcast=u,color=rgb,light=vec(3,0,2),phase=u,warp=u,density=u,drift=num(-1048576,1048576)},
 front={x=num(-1048576,1048576),z=num(-1048576,1048576),radius=num(1,262144),axis=vec(2,-1,1),strength=u,canopy=u,fill=u,ready=u},
 lightning={x=num(-1048576,1048576),z=num(-1048576,1048576),radius=num(1,262144),strength=u}}
local function finite(v,a,b)return type(v)=='number' and v==v and v>=a and v<=b end
local function plain(t)return type(t)=='table' and getmetatable(t)==nil end
local function copy(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function parse(v,s,path)
 if s.kind=='number'then if not finite(v,s.lo,s.hi)then return nil,path..': invalid number' end;return v end
 if s.kind=='boolean'then if type(v)~='boolean'then return nil,path..': invalid boolean' end;return v end
 if not plain(v)then return nil,path..': expected plain table' end
 local out,n={},0
 for k,x in pairs(v)do
  n=n+1
  if s.kind=='vector'then
   if n>s.n or not finite(k,1,s.n) or k%1~=0 or not finite(x,s.lo,s.hi)then return nil,path..': invalid vector' end
   out[k]=x
  else
   if n>16 or type(k)~='string' or not s[k]then return nil,path..': unknown field' end
   local value,err=parse(x,s[k],path..'.'..k);if err then return nil,err end;out[k]=value
  end
 end
 if s.kind=='vector' and n~=s.n then return nil,path..': vector missing component' end
 return out
end
function M.validate(packet)
 local r,err=parse(packet,schema,'atmosphere');if not r then return nil,err end
 for _,name in ipairs({'front','lightning'})do
  local f=r[name];if f then for _,key in ipairs({'x','z','radius','strength'})do if f[key]==nil then return nil,name..': missing '..key end end end
 end
 if r.front then
  local a=r.front.axis;if not a then return nil,'front: missing axis' end
  local length=math.sqrt(a[1]^2+a[2]^2);if length<1e-9 then return nil,'front: zero axis' end
  a[1],a[2]=a[1]/length,a[2]/length
 end
 if r.haze and (r.haze.density or 0)>0 and not r.haze.color then return nil,'haze: missing color' end
 return r
end
function M.new()
 local R={};local token,owner,frame,eligible,state,ready=nil,nil,nil,false,nil,false
 local function clear()state=nil;ready=false end
 function R.beginFrame(id,allowed)
  assert(finite(id,0,9007199254740991) and id%1==0,'invalid frame')
  if frame and id<frame then return nil,'decreasing frame' end
  if frame==id then if not allowed then eligible=false;clear()end;return true end
  frame,eligible=id,allowed==true;clear();return true
 end
 function R.acquire(id)
  if type(id)~='string' or #id==0 or #id>128 then return nil,'invalid owner' end
  if token then return nil,'atmosphere already owned' end
  local key={};token,owner=key,id;local L={}
  function L.submit(packet,id)
   if token~=key then return nil,'revoked lease' end
   if id~=frame or not eligible then clear();return nil,'ineligible or stale frame' end
   local value,err=M.validate(packet);if not value then clear();return nil,err end
   state=value;return true
  end
  function L.clear()if token~=key then return nil,'revoked lease' end;clear();return true end
  function L.dispose()if token~=key then return nil,'revoked lease' end;token,owner=nil,nil;clear();return true end
  return L
 end
 function R.celestialStatus(id,ok)ready=id==owner and ok==true and eligible end
 function R.snapshot()
  if not state or not eligible then return {} end
  local r=copy(state);if r.sky and r.sky.replaceCelestials and not ready then r.sky.replaceCelestials=false end;return r
 end
 function R.reset()token,owner,frame,eligible=nil,nil,nil,false;clear()end
 return R
end
return M
