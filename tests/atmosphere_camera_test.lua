local C=assert(loadfile('lib/AtmosphereCamera.lua'))()
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local eye={10,20,30};local f=assert(C.build(eye,{10,20,20},{0,1,0},1,4136,1,'first_person'));eye[1]=99
check(f.eye[1]==10,'input alias');check(f.right[1]==1 and f.up[2]==1 and f.forward[3]==-1,'axes')
local completed=assert(C.complete(f,4,'MAP'));f.eye[1]=77
local a=C.snapshot(completed,5,'MAP','first_person');check(a.available and a.ageFrames==1 and a.far==4136 and a.overhead,'facts')
a.eye[1]=66;check(C.snapshot(completed,5,'MAP','first_person').eye[1]==10,'output alias')
for _,args in ipairs({{8,'MAP','first_person'},{5,'OTHER','first_person'},{5,'MAP','diorama'},{3,'MAP','first_person'}})do check(not C.snapshot(completed,unpack(args)).available,'stale facts accepted')end
check(not C.snapshot(nil,1,'MAP','first_person').available,'invented camera')
check(not C.build({0/0,0,0},{0,0,-1},{0,1,0},1,100,1,'first_person'),'NaN')
check(not C.build({0,0,0},{0,0,0},{0,1,0},1,100,1,'first_person'),'zero direction')
check(not C.build({0,0,0},{0,1,0},{0,1,0},1,100,1,'first_person'),'degenerate up')
check(not C.build({0,0,0},{0,0,-1},{0,1,0},1,math.huge,1,'first_person'),'infinite far')
local d=assert(C.build({0,10,0},{0,0,0},{0,0,-1},1,4496,1,'diorama'));check(not d.overhead and d.up[3]==-1,'diorama')
local V={require=function(name)return assert(loadfile('lib/'..name..'.lua'))()end}
local S=assert(loadfile('lib/AtmosphereEffects.lua'))(V).new();S.beginFrame(5,true,C.snapshot(completed,5,'MAP','first_person'))
local api=S.owner('test');local c=api:camera();check(c.eye[1]==10,'facade source');c.eye[1]=0;check(api:camera().eye[1]==10,'facade alias')
S.beginFrame(6,false);check(not api:camera().available and api:camera().eye==nil,'indoor facts leaked')
S.revoke('test');check(api:camera()==nil,'revoked camera')
print('PASS '..n..' camera facts checks')
