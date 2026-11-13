-- External mod package loader for CorsixTH 0.70.2.
-- Mod code is trusted Lua code; this is not a security sandbox.

local lfs = require("lfs")
local Hooks = corsixth.require("mod_hooks")
local config_finder = corsixth.require("config_finder")
local pathsep = package.config:sub(1, 1)

local ModLoader = {}
local loaded = false
local mods_path = config_finder.config_path .. pathsep .. "mods"

local function log(message)
  print("[ModLoader] " .. tostring(message))
end

local function valid_id(id)
  return type(id) == "string" and id:match("^[%w_%-]+$") ~= nil
end

local function run_file(filename)
  local chunk, err = loadfile_envcall(filename)
  if not chunk then
    return nil, err
  end
  local environment = setmetatable({}, {__index = _G})
  local ok, result = pcall(chunk, environment)
  if not ok then
    return nil, result
  end
  return result
end

local function read_enabled_mods()
  local filename = mods_path .. pathsep .. "enabled.txt"
  local file = io.open(filename, "r")
  if not file then
    return {}
  end

  local result, seen = {}, {}
  for line in file:lines() do
    local id = line:match("^%s*(.-)%s*$")
    if id ~= "" and id:sub(1, 1) ~= "#" then
      if valid_id(id) then
        if not seen[id] then
          result[#result + 1] = id
          seen[id] = true
        else
          log("duplicate mod id ignored: " .. id)
        end
      else
        log("invalid mod id ignored: " .. id)
      end
    end
  end
  file:close()
  return result
end

local function load_mod(id)
  local mod_dir = mods_path .. pathsep .. id
  if lfs.attributes(mod_dir, "mode") ~= "directory" then
    log("enabled mod directory not found: " .. id)
    return
  end

  local manifest, manifest_err = run_file(mod_dir .. pathsep .. "mod.lua")
  if type(manifest) ~= "table" then
    log("cannot load manifest for " .. id .. ": " .. tostring(manifest_err or "expected a table"))
    return
  end
  if manifest.id ~= id then
    log("manifest id does not match enabled id: " .. id)
    return
  end

  local entry = manifest.entry or "init.lua"
  if type(entry) ~= "string" or not entry:match("^[%w_%-]+%.lua$") then
    log("invalid entry filename in mod " .. id)
    return
  end

  local initializer, entry_err = run_file(mod_dir .. pathsep .. entry)
  if type(initializer) ~= "function" then
    log("cannot load entry for " .. id .. ": " .. tostring(entry_err or "expected a function"))
    return
  end

  local api = {
    version = 1,
    id = id,
    name = manifest.name or id,
    version_string = manifest.version or "0",
    hooks = {
      register = function(event, callback, priority)
        return Hooks.register(event, callback, priority, id)
      end,
      unregister = Hooks.unregister,
    },
    log = function(message)
      log("[" .. id .. "] " .. tostring(message))
    end,
  }

  local ok, err = pcall(initializer, api)
  if not ok then
    log("initialization failed for " .. id .. ": " .. tostring(err))
    return
  end
  log("loaded " .. id .. " (" .. tostring(api.version_string) .. ")")
end

function ModLoader.load()
  if loaded then
    return
  end
  loaded = true

  if lfs.attributes(mods_path, "mode") ~= "directory" then
    local ok, err = lfs.mkdir(mods_path)
    if not ok and lfs.attributes(mods_path, "mode") ~= "directory" then
      log("cannot create mods directory: " .. tostring(err))
      return
    end
  end

  local enabled = read_enabled_mods()
  for _, id in ipairs(enabled) do
    local ok, err = pcall(load_mod, id)
    if not ok then
      log("unexpected error while loading " .. id .. ": " .. tostring(err))
    end
  end
  log("startup complete; enabled mods: " .. tostring(#enabled))
end

function ModLoader.emit(event, ...)
  Hooks.emit(event, ...)
end

return ModLoader
