return function(api)
  api.hooks.register("humanoid.animations", function(animations)
    local anims = TheApp.animation_manager.anims

    local north = anims:getAnimations(32, "gpt_handyman_idle_north")
    local _, east = anims:getAnimations(32, "gpt_handyman_idle_east")

    animations.Handyman.idle_north = north
    animations.Handyman.idle_east = east

    local walk_north = anims:getAnimations(32, "gpt_handyman_walk_north")
    local _, walk_east = anims:getAnimations(32, "gpt_handyman_walk_east")
    animations.Handyman.walk_north = walk_north
    animations.Handyman.walk_east = walk_east

    api.log("custom walk north assigned: " .. tostring(walk_north))
    api.log("custom walk east assigned: " .. tostring(walk_east))

    api.log("custom idle north assigned: " .. tostring(north))
    api.log("custom idle east assigned: " .. tostring(east))
  end)

  api.hooks.register("humanoid.sweep_floor_animations", function(animation_numbers)
    api.log("sweep animation 1: " .. tostring(animation_numbers[1]))
    api.log("sweep animation 2: " .. tostring(animation_numbers[2]))
  end)
end
