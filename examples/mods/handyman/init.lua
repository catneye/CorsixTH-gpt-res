return function(api)
  api.hooks.register("humanoid.animations", function(animations)
    local anims = TheApp.animation_manager.anims

    local north = anims:getAnimations(32, "gpt_handyman_idle_north")
    local _, east = anims:getAnimations(32, "gpt_handyman_idle_east")

    animations.Handyman.idle_north = north
    animations.Handyman.idle_east = east

    api.log("custom idle north assigned: " .. tostring(north))
    api.log("custom idle east assigned: " .. tostring(east))
  end)

  api.hooks.register("humanoid.sweep_floor_animations", function(animation_numbers)
    api.log("sweep animation 1: " .. tostring(animation_numbers[1]))
    api.log("sweep animation 2: " .. tostring(animation_numbers[2]))
  end)
end
