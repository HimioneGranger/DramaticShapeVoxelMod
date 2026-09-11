-- Legendary-only dimensional flower clusters. No collision or map edits.
local V=...
local M={}
local cached
local palette={{.12,.23,.13},{.21,.35,.20},{.34,.44,.27},{.48,.37,.61},
 {.65,.54,.74},{.80,.73,.85},{.85,.81,.69},{.65,.57,.35},
 {.23,.28,.20},{.35,.29,.43},{.72,.64,.80},{.91,.86,.75},
 {.3,.35,.25},{.4,.43,.3},{.5,.5,.4},{.6,.6,.5}}
function M.layout(map)
 if not(map and map.id=='ROUTE_10' and V.require('CommunityVisuals').customCityGround())then return end
 local bed=V.require('TowerGarden').detect(map);if not bed then return end
 local r={flowers={}}
 local function noise(x,y,s)return ((x*7381+y*1933+s*917)%1009)/1009 end
 for y=bed.minY+1,bed.maxY-1 do for x=bed.minX+1,bed.maxX-1 do
  local cx,cy=math.floor(x/2),math.floor(y/2)
  local blocked=not map.isWalkableCell or not map:isWalkableCell(cx,cy)
  local door=map.isDoorTileCell and map:isDoorTileCell(cx,cy)
  if not door and map.doorTiles and map.cellTile then door=map.doorTiles[map:cellTile(cx,cy)]end
  local water=map.isWaterCell and map:isWaterCell(cx,cy)
  -- Leave the middle open; broad irregular patches occupy the bed margins.
  local edge=math.min(x-bed.minX,bed.maxX-x,y-bed.minY,bed.maxY-y)
  local wave=math.sin(x*.63+y*.37)*.5+.5
  if blocked and not door and not water and edge<=3 and noise(x,y,1)<.40+wave*.25 then
   r.flowers[#r.flowers+1]={x=x*8+2+noise(x,y,2)*4,z=y*8+2+noise(x,y,3)*4,
    h=2.3+noise(x,y,4)*1.6,angle=noise(x,y,5)*6.283,col=noise(x,y,6)<.28 and 7 or 4}
  end
 end end
 return r
end
function M.geometry(r,part)
 local vs,ix={},{}
 local ox,oz,turn=0,0,0
 local function point(p)
  if turn==1 then return {ox+p[3],p[2],oz-p[1]}end
  if turn==-1 then return {ox-p[3],p[2],oz+p[1]}end
  if turn==2 then return {ox-p[1],p[2],oz-p[3]}end
  return {ox+p[1],p[2],oz+p[3]}
 end
 local function quad(a,b,c,d,col,shade)
  local n=#vs
  for _,p in ipairs({a,b,c,d})do p=point(p);vs[#vs+1]={p[1],p[2],p[3],(col-.5)/16,.5,shade or 1}end
  for _,i in ipairs({1,2,3,1,3,4})do ix[#ix+1]=n+i end
 end
 local function box(x,y,z,w,h,d,col)
  local X,Y,Z=x+w,y+h,z+d
  quad({x,y,Z},{X,y,Z},{X,Y,Z},{x,Y,Z},col,.95)
  quad({X,y,z},{x,y,z},{x,Y,z},{X,Y,z},col,.76)
  quad({x,y,z},{x,y,Z},{x,Y,Z},{x,Y,z},col,.82)
  quad({X,y,Z},{X,y,z},{X,Y,z},{X,Y,Z},col,.88)
  quad({x,Y,Z},{X,Y,Z},{X,Y,z},{x,Y,z},col,1)
  quad({x,y,z},{X,y,z},{X,y,Z},{x,y,Z},col,.7)
 end
 local function cylinder(y,h,r0,r1,col,x,z)
  x,z=x or 0,z or 0
  for i=0,11 do
   local a,b=i*math.pi/6,(i+1)*math.pi/6
   local ca,sa,cb,sb=math.cos(a),math.sin(a),math.cos(b),math.sin(b)
   quad({x+r0*ca,y,z+r0*sa},{x+r1*ca,y+h,z+r1*sa},
    {x+r1*cb,y+h,z+r1*sb},{x+r0*cb,y,z+r0*sb},col,.85+.10*ca)
   quad({x,y+h,z},{x+r1*cb,y+h,z+r1*sb},{x+r1*ca,y+h,z+r1*sa},{x,y+h,z},col)
  end
 end

 for _,p in ipairs(r.flowers)do
  ox,oz,turn=p.x,p.z,0
  box(-.13,0,-.13,.26,p.h,.26,1)
  for j=0,2 do
   local angle=p.angle+j*2.1;local c,s=math.cos(angle),math.sin(angle)
   local y=.65+j*.4
   quad({0,y,0},{c*1.3-s*.4,y+.35,s*1.3+c*.4},{c*2,y+.55,s*2},{c*1.3+s*.4,y+.25,s*1.3-c*.4},2+j%2)
   quad({0,y,0},{c*1.3+s*.4,y+.25,s*1.3-c*.4},{c*2,y+.55,s*2},{c*1.3-s*.4,y+.35,s*1.3+c*.4},2+j%2)
  end
  for j=0,4 do
   local angle=p.angle+j*math.pi*2/5;local c,s=math.cos(angle),math.sin(angle)
   local root={c*.18,p.h,s*.18};local left={c*.8-s*.5,p.h+.25,s*.8+c*.5}
   local tip={c*1.35,p.h+.6,s*1.35};local right={c*.8+s*.5,p.h+.25,s*.8-c*.5}
   quad(root,left,tip,right,p.col)
   quad(root,right,tip,left,p.col)
   local peak={c*.65,p.h+.45,s*.65}
   quad(root,left,peak,root,p.col==7 and 12 or 6)
   quad(left,tip,peak,left,p.col==7 and 7 or 5)
   quad(tip,right,peak,tip,p.col==7 and 12 or 6)
   quad(right,root,peak,right,p.col)
  end
  cylinder(p.h,.35,.3,.4,8)
 end
 return vs,ix
end
local function prepare(map)
 if not(map and map.id=='ROUTE_10' and V.require('CommunityVisuals').customCityGround())then return end
 if cached then return cached end
 local r=M.layout(map);if not r or #r.flowers==0 then return end
 local R=V.require('Voxel3D');local v,i=M.geometry(r);local mesh=R.newMesh(v,i);if not mesh then return end
 local d=love.image.newImageData(16,1)
 for i,c in ipairs(palette)do d:setPixel(i-1,0,c[1],c[2],c[3],1)end
 local texture=love.graphics.newImage(d);texture:setFilter('nearest','nearest');d:release()
 cached={mesh=mesh,texture=texture};return cached
end
function M.build(S,map)prepare(map)end
function M.draw(map,shadow,transform)
 local r=prepare(map);if not r then return end
 if shadow then shadow.draw(r.mesh,r.texture,transform)else
  local R=V.require('Voxel3D');local old=R.glassMask
  R.glassMaskNow(nil);R.glass(false)
  local ok,err=pcall(R.draw,r.mesh,r.texture,transform)
  R.glassMaskNow(old);R.glass(false)
  if not ok then error(err)end
 end
end
function M.invalidate()if cached then cached.mesh:release();cached.texture:release();cached=nil end end
function M.setLive(live)if not live.ROUTE_10 then M.invalidate()end end
return M
