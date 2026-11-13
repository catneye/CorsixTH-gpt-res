-- CorsixTH external mod loader.
-- Mods are trusted Lua code and run in the game's Lua environment.

local ModLoader = {}

local hooks = {}
local registration_sequence = 0
local current_mod = nil
local loading_started = false

local pathsep = package.config:sub(1, 1)

local function log(message)
  print("[ModLoader] " .. tostring(message))
end

local function join_path(...)
  local parts = {...}
  return table.concat(parts, pathsep)
end

local function is_valid_mod_id(id)
  return type(id) == "string" and id:match("^[%w_-]+$") ~= nil
end

local function run_file(filename, ...)
  local chunk, load_error = loadfile(filename)
  if not chunk then
    return false, load_error
  end

  return pcall(chunk, ...)
end

local function remove_mod_hooks(mod_id)
  for _, handlers in pairs(hooks) do
    for index = #handlers, 1, -1 do
      if handlers[index].mod_id == mod_id then
        table.remove(handlers, index)
      end
    end
  end
end

local function load_mod(mods_dir, mod_id)
  local mod_dir = join_path(mods_dir, mod_id)
  local manifest_file = join_path(mod_dir, "mod.lua")
  local manifest_ok, manifest = run_file(manifest_file)

  if not manifest_ok then
    log("Cannot load manifest for '" .. mod_id .. "': " .. tostring(manifest))
    return false
  end

  if type(manifest) ~= "table" then
    log("Manifest for '" .. mod_id .. "' must return a table")
    return false
  end

  local entry = manifest.entry or "init.lua"
  if type(entry) ~= "string"
      or entry == ""
      or entry:find("[/\\]")
      or entry == "."
      or entry == ".."
      or not entry:match("%.lua$") then
    log("Invalid entry file in manifest for '" .. mod_id .. "'")
    return false
  end

  local entry_file = join_path(mod_dir, entry)
  local entry_chunk, load_error = loadfile(entry_file)
  if not entry_chunk then
    log("Cannot load '" .. mod_id .. "' entry point: " .. tostring(load_error))
    return false
  end

  current_mod = mod_id
  local ok, result = pcall(entry_chunk, ModLoader)
  current_mod = nil

  if not ok then
    remove_mod_hooks(mod_id)
    log("Mod '" .. mod_id .. "' failed during initialization: " .. tostring(result))
    return false
  end

  local display_name = manifest.name or mod_id
  log("Loaded '" .. tostring(display_name) .. "' (" .. mod_id .. ")")
  return true
end

-- Register a callback for an event.
-- Higher priority values run first. Equal priorities retain registration order.
-- Registration is only allowed while a mod's init.lua is executing.
function ModLoader.register(event, callback, priority)
  if not current_mod then
    log("Ignoring hook registration outside mod initialization")
    return false
  end

  if type(event) ~= "string" or event == "" then
    log("Mod '" .. current_mod .. "' tried to register an invalid event")
    return false
  end

  if type(callback) ~= "function" then
    log("Mod '" .. current_mod .. "' tried to register a non-function callback")
    return false
  end

  if priority == nil then
    priority = 0
  elseif type(priority) ~= "number" then
    log("Mod '" .. current_mod .. "' supplied a non-numeric hook priority")
    return false
  end

  registration_sequence = registration_sequence + 1

  local handlers = hooks[event]
  if not handlers then
    handlers = {}
    hooks[event] = handlers
  end

  handlers[#handlers + 1] = {
    mod_id = current_mod,
    callback = callback,
    priority = priority,
    sequence = registration_sequence,
  }

  table.sort(handlers, function(a, b)
    if a.priority ~= b.priority then
      return a.priority > b.priority
    end
    return a.sequence < b.sequence
  end)

  return true
end

-- Dispatch an event to all registered callbacks.
-- A failing callback is logged and does not prevent later callbacks from running.
function ModLoader.emit(event, ...)
  local handlers = hooks[event]
  if not handlers then
    return
  end

  for index = 1, #handlers do
    local handler = handlers[index]
    local ok, err = pcall(handler.callback, ...)
    if not ok then
      log("Hook '" .. event .. "' from mod '" .. handler.mod_id
        .. "' failed: " .. tostring(err))
    end
  end
end

-- Load enabled mods from <config_path>/mods/enabled.txt.
-- The file contains one mod directory name per line; blank lines and # comments
-- are ignored.
function ModLoader.load()
  if loading_started then
    return 0
  end
  loading_started = true

  local config_finder = corsixth.require("config_finder")
  if type(config_finder.config_path) ~= "string" then
    log("Configuration directory is unavailable; no mods loaded")
    return 0
  end

  local mods_dir = join_path(config_finder.config_path, "mods")
  local enabled_file = join_path(mods_dir, "enabled.txt")
  local file, open_error = io.open(enabled_file, "r")

  if not file then
    log("No enabled mods list found; no mods loaded (" .. tostring(open_error) .. ")")
    return 0
  end

  local enabled = {}
  local seen = {}

  for line in file:lines() do
    local mod_id = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
    if mod_id ~= "" and not mod_id:match("^#") then
      if not is_valid_mod_id(mod_id) then
        log("Ignoring invalid mod id: " .. mod_id)
      elseif not seen[mod_id] then
        seen[mod_id] = true
        enabled[#enabled + 1] = mod_id
      end
    end
  end

  file:close()

  local loaded_count = 0
  for _, mod_id in ipairs(enabled) do
    if load_mod(mods_dir, mod_id) then
      loaded_count = loaded_count + 1
    end
  end

  log("Finished loading mods: " .. loaded_count .. "/" .. #enabled)
  return loaded_count
end

return ModLoader
