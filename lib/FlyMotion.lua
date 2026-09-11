-- Gen 1 Fly choreography. Reads battle state; never changes battle logic.
local M = {}
local states = setmetatable({}, {__mode = "k"})
local owners = setmetatable({}, {__mode = "k"})
function M.claim(battle, host) owners[battle]=host end
local function ease(t) t=math.max(0,math.min(1,t)); return t*t*(3-2*t) end
local function isFly(move)
  return move == "FLY" or (type(move)=="table" and move.id=="FLY")
end
local function pending(battle, side)
  for _,row in ipairs(battle.queue or {}) do
    if row.anim=="FLY" and row.attackerIsPlayer==(side=="player") then return true end
  end
  return false
end
function M.update(battle, dt, owner)
  if not battle then return end
  if owners[battle] and owners[battle]~=owner then return end
  local slots=states[battle] or {}; states[battle]=slots
  dt=math.max(0,tonumber(dt) or 0)
  for _,side in ipairs({"player","enemy"}) do
    local b=battle[side]
    local s=slots[side]
    if not b or b.fainted or (b.mon and b.mon.hp==0) or (s and s.battler~=b) then
      slots[side]=nil; s=nil
    end
    local charging=b and isFly(b.charging) and not b.fainted and not (b.mon and b.mon.hp==0)
    if charging and not s then
      s={battler=b,phase="rise",time=0}; slots[side]=s
    end
    if s then
      local active=battle.animPlaying and battle.animName=="FLY"
        and battle.animAttackerIsPlayer==(side=="player")
      if charging then
        if s.phase~="rise" and s.phase~="hold" then s.phase="rise";s.time=0 end
      elseif s.phase=="rise" or s.phase=="hold" or s.phase=="wait" then
        if active then s.phase="dive";s.time=0
        elseif pending(battle,side) then s.phase="wait";s.time=0
        else s.phase="land";s.time=0 end
      end
      s.time=s.time+dt
      if s.phase=="rise" and s.time>=0.6 then s.phase="hold";s.time=0
      elseif s.phase=="dive" and s.time>=0.35 then s.phase="recover";s.time=0
      elseif (s.phase=="recover" or s.phase=="land") and s.time>=0.35 then slots[side]=nil end
    end
  end
end
function M.pose(battle, side)
  local s=states[battle] and states[battle][side]
  if not s or s.battler~=battle[side] or s.battler.fainted then return nil end
  local p={height=0,advance=0,hidden=false,phase=s.phase}
  if s.phase=="hold" or s.phase=="wait" then p.hidden=true
  elseif s.phase=="rise" then p.height=72*ease(s.time/0.6)
  elseif s.phase=="dive" then
    local t=ease(s.time/0.35);p.height=72*(1-t);p.advance=0.68*t
  elseif s.phase=="recover" then p.advance=0.68*(1-ease(s.time/0.35))
  elseif s.phase=="land" then p.height=72*(1-ease(s.time/0.35)) end
  return p
end
return M
