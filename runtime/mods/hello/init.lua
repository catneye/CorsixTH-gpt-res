-- Minimal example mod for the external ModLoader.

print("[HelloMod] Hello from an external CorsixTH mod!")

-- The loader passes its API table as the first argument.
local ModLoader = ...

ModLoader.register("example.hello", function()
  print("[HelloMod] example.hello event received")
end)
