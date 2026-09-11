-- Route legacy cliff quads through the same masonry as ordinary terrain.
-- Pure mesh-build work: no frame-time changes and no collision edits.
local Masonry = {}
local CLIFF = {[1]=true,[17]=true,[19]=true,[30]=true,[53]=true}

function Masonry.wrap(original, width, height, generate)
  return function(c, uv, shade)
    -- Only original cliff atlas regions, never the material swatch itself.
    local minU,maxU,minV,maxV=1,0,1,0
    for i=1,4 do
      minU=math.min(minU,uv[i][1]); maxU=math.max(maxU,uv[i][1])
      minV=math.min(minV,uv[i][2]); maxV=math.max(maxV,uv[i][2])
    end
    local col=math.floor((minU+maxU)*0.5*width/8)
    local row=math.floor((minV+maxV)*0.5*height/8)
    local tile=row*math.floor(width/8)+col
    if not CLIFF[tile] or minU*width<col*8-0.001
        or maxU*width>(col+1)*8+0.001 or minV*height<row*8-0.001
        or maxV*height>(row+1)*8+0.001 then
      return original(c,uv,shade)
    end
    local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
    for i=1,4 do for k=1,3 do lo[k]=math.min(lo[k],c[i][k]);hi[k]=math.max(hi[k],c[i][k]) end end
    local axis
    for k=1,3 do if hi[k]-lo[k]<0.0001 then axis=k;break end end
    if not axis then return original(c,uv,shade) end -- preserve sloped art
    local uaxis,vaxis
    if axis==2 then uaxis,vaxis=1,3 elseif axis==1 then uaxis,vaxis=3,2 else uaxis,vaxis=1,2 end
    if hi[uaxis]-lo[uaxis]<0.0001 or hi[vaxis]-lo[vaxis]<0.0001 then return end
    -- Rectangles only; leave irregular silhouettes to their original builder.
    for i=1,4 do
      for _,k in ipairs({uaxis,vaxis}) do
        if math.abs(c[i][k]-lo[k])>0.0001 and math.abs(c[i][k]-hi[k])>0.0001 then
          return original(c,uv,shade)
        end
      end
    end
    local ax,ay,az=c[2][1]-c[1][1],c[2][2]-c[1][2],c[2][3]-c[1][3]
    local bx,by,bz=c[3][1]-c[1][1],c[3][2]-c[1][2],c[3][3]-c[1][3]
    local normal={ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx}
    local side=axis==1 and (normal[1]>=0 and 1 or 2) or (normal[3]>=0 and 5 or 6)
    local function clipped(points, tex, light)
      local poly={}
      for i=1,4 do poly[i]={points[i][1],points[i][2],points[i][3],tex[i][1],tex[i][2],type(light)=='table' and light[i] or light} end
      for _,k in ipairs({uaxis,vaxis}) do
        for _,sign in ipairs({1,-1}) do
          local bound=sign==1 and lo[k] or hi[k]
          local out={}
          if #poly==0 then return end
          local prev=poly[#poly];local dp=sign*(prev[k]-bound)
          for _,cur in ipairs(poly) do
            local dc=sign*(cur[k]-bound)
            if (dp>=0)~=(dc>=0) then
              local t=dp/(dp-dc);local p={}
              for j=1,6 do p[j]=prev[j]+(cur[j]-prev[j])*t end
              out[#out+1]=p
            end
            if dc>=0 then out[#out+1]=cur end
            prev,dp=cur,dc
          end
          poly=out
        end
      end
      for i=2,#poly-1 do
        local out={poly[1],poly[i],poly[i+1],poly[1]};local xyz,tint,texture={},{},{}
        for j,p in ipairs(out) do xyz[j]={p[1],p[2],p[3]};texture[j]={p[4],p[5]};tint[j]=p[6] end
        original(xyz,texture,tint)
      end
    end
    -- Repeat the existing 8px builder over the source face; clipping keeps
    -- partial object faces inside their own footprint, including chunk edges.
    for u=math.floor(lo[uaxis]/8)*8,hi[uaxis]-0.0001,8 do
      if axis==2 then
        for v=math.floor(lo[vaxis]/8)*8,hi[vaxis]-0.0001,8 do
          generate(clipped,true,0,u,v,lo[2],lo[2],shade)
        end
      else
        local x=axis==1 and lo[1]-(side==1 and 8 or 0) or u
        local z=axis==3 and lo[3]-(side==5 and 8 or 0) or u
        generate(clipped,false,side,x,z,math.floor(lo[2]/4)*4,math.ceil(hi[2]/4)*4,shade)
      end
    end
  end
end
return Masonry
