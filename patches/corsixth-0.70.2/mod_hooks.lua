-- Generic, deterministic event hooks for external CorsixTH mods.
-- Mods are trusted Lua code and run inside the game process.

local Hooks = {}
local handlers = {}
local next_id = 0

function Hooks.register(event, callback, priority, owner)
  assert(type(event) == "string" and event ~= "", "hook event must be a non-empty string")
  assert(type(callback) == "function", "hook callback must be a function")
  assert(priority == nil or type(priority) == "number", "hook priority must be a number")

  next_id = next_id + 1
  local handler = {
    id = next_id,
    callback = callback,
    priority = priority or 0,
    owner = owner or "unknown mod",
  }
  local list = handlers[event]
  if not list then
    list = {}
    handlers[event] = list
  end
  list[#list + 1] = handler
  return handler.id
end

function Hooks.unregister(id)
  for _, list in pairs(handlers) do
    for index = #list, 1, -1 do
      if list[index].id == id then
        table.remove(list, index)
        return true
      end
    end
  end
  return false
end

function Hooks.emit(event, ...)
  local list = handlers[event]
  if not list or #list == 0 then
    return
  end

  local snapshot = {}
  for index, handler in ipairs(list) do
    snapshot[index] = handler
  end
  table.sort(snapshot, function(a, b)
    if a.priority == b.priority then
      return a.id < b.id
    end
    return a.priority > b.priority
  end)

  for _, handler in ipairs(snapshot) do
    local ok, err = pcall(handler.callback, ...)
    if not ok then
      print("[ModLoader] hook '" .. event .. "' failed in " ..
        handler.owner .. ": " .. tostring(err))
    end
  end
end

return Hooks
