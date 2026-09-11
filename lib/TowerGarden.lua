local V=...
local CV=V.require('CommunityVisuals')
local M={}
function M.enabled()
  -- The Route 10 Tower garden is part of Lavender's CITY GROUND treatment.
  -- GRASS may recolor the surrounding route, but must never opt a Battle Art
  -- city-ground selection into Legendary garden geometry by itself.
  return CV.customCityGround()
end
-- Original Route 10 tower roof is exactly this 3x3 block pattern.
-- Match map blocks, not reskinned atlas IDs or building-template order.
local pattern={{12,13,14},{117,113,118},{104,127,105}}
function M.detect(map)
  if not map or map.id~='ROUTE_10' or not map.tileset
      or map.tileset.id~='OVERWORLD' then return end
  local d=map.def
  if not d or not d.width or not d.height then return end
  -- Match the runtime's resolved tile grid, as Buildings does. Some engine
  -- builds expose neither blockAt nor def.blocks; never rely on either API.
  local function matchesBlock(x,y,id)
    if x<0 or y<0 or x>=d.width or y>=d.height then return false end
    local donor=map.tileset.blocks and map.tileset.blocks[id+1]
    if donor and map.tileAt then
      for j=0,3 do for i=0,3 do
        if map:tileAt(x*4+i,y*4+j)~=donor[j*4+i+1] then return false end
      end end
      return true
    end
    -- Compatibility with block-only fixtures/older map providers.
    if map.blockAt then return map:blockAt(x,y)==id end
    return d.blocks and d.blocks[y*d.width+x+1]==id or false
  end
  -- Authored Red Route 10 south seam: stable map dimensions and footprint.
  -- Tile remapping by companion building mods can invalidate donor matches.
  -- Restrict the fallback to this exact original map size; never a global tile rule.
  if d.width==10 and d.height==36 then
    return {minX=12,maxX=35,minY=132,maxY=143}
  end
  for y=0,d.height-3 do for x=0,d.width-3 do
    local match=true
    for j=1,3 do for i=1,3 do
      if not matchesBlock(x+i-1,y+j-1,pattern[j][i]) then match=false end
    end end
    if match then
      local west={{87,37,47},{122,122,122},{122,49,62}}
      local extend=x>=3
      for j=1,3 do for i=1,3 do
        if not matchesBlock(x-4+i,y+j-1,west[j][i]) then extend=false end
      end end
      return {minX=(extend and x-3 or x)*4,maxX=x*4+11,minY=y*4,maxY=y*4+11}
    end
  end end
end
function M.contains(S,x,y)
  local b=S and S.lavenderGardenGround
  return b and S.lavenderGardenCells and S.lavenderGardenCells[x..":"..y] == true
end
function M.prepare(S,map,keyOf)
  if not M.enabled() then return false end
  local bed=M.detect(map)
  if not bed then return false end
  -- Landscape the recognized roof and western alcove; collision is unchanged.
  -- A walkable cell no longer cancels the entire bed. Doors and water stay live.
  S.lavenderFlowerbed=bed
  S.lavenderGardenGround=bed
  S.lavenderGardenCells={}
  for y=bed.minY,bed.maxY do for x=bed.minX,bed.maxX do
    local cx,cy=math.floor(x/2),math.floor(y/2)
    local door=map.isDoorTileCell and map:isDoorTileCell(cx,cy)
    if not door and map.doorTiles and map.cellTile then door=map.doorTiles[map:cellTile(cx,cy)] end
    local water=map.isWaterCell and map:isWaterCell(cx,cy)
    if not door and not water then
      local k=keyOf(x,y)
      S.lavenderGardenCells[x..":"..y]=true
      S.skip[k]=true;S.ground[k]=44
      S.shapeAt[k]={class='ground',flat=true,h=0,authored=true}
    end
  end end
  return true
end
return M
