-- Single-camera visual flight adapted from q57 JuggleComfort/SummonReturn.
-- Units here are map pixels. No input, collision or gameplay ownership.
local B={WORLD_UNITS_PER_METRE=16, GRAVITY=9.81*16, THROW_SECONDS=.72}
function B.launch(origin,target,duration,gravity)
  duration=math.max(.001,duration or B.THROW_SECONDS)
  local g=gravity or B.GRAVITY
  return {origin={origin[1],origin[2],origin[3]},target={target[1],target[2],target[3]},
    duration=duration,gravity=g,velocity={(target[1]-origin[1])/duration,
    (target[2]-origin[2])/duration+.5*g*duration,(target[3]-origin[3])/duration}}
end
function B.sample(f,age)
  local t=math.max(0,math.min(f.duration,age))
  local o,v=f.origin,f.velocity
  return o[1]+v[1]*t,o[2]+v[2]*t-.5*f.gravity*t*t,o[3]+v[3]*t
end
return B
