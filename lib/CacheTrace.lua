-- Bounded desktop session diagnostics; failures never affect rendering.
local Trace = {}
local started, bytes = false, 0
local path = "battleart-gen1-cache.log"
function Trace.enabled()
  if not (love and love.system and love.system.getOS) then return false end
  local ok, name = pcall(love.system.getOS)
  return ok and (name == "Windows" or name == "Linux" or name == "OS X")
end
function Trace.log(event, map, detail)
  if not Trace.enabled() then return end
  pcall(function()
    local fs = love.filesystem
    if not started then
      started = true
      if fs and fs.write then fs.write(path, "Battle Art Gen1 cache trace: new session\n") end
      print("[BAV cache] log: " .. ((fs and fs.getSaveDirectory and fs.getSaveDirectory()) or "") .. "/" .. path)
    end
    local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
    local line = string.format("[BAV cache %.3f] %s map=%s %s\n", now,
      tostring(event), tostring(map or "*"), tostring(detail or ""))
    print(line:sub(1, -2))
    if fs and fs.append then
      if bytes + #line > 4 * 1024 * 1024 then
        if not (fs.read and fs.write) then return end
        local old = fs.read(path)
        if old then fs.write("battleart-gen1-cache.previous.log", old) end
        fs.write(path, "Trace continued after rotation\n")
        bytes = 0
      end
      fs.append(path, line)
      bytes = bytes + #line
    end
  end)
end
return Trace
