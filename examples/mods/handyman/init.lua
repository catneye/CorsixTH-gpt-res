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

  api.hooks.register("humanoid.use_object_animation", function(anim_table, object, humanoid, phase)
    if humanoid.humanoid_class ~= "Handyman" then
      return
    end

    local object_id = object.object_type.id
    api.log("use_object hook: object=" .. tostring(object_id) ..
      ", phase=" .. tostring(phase))

    local animation_name
    local marker
    local label

    if object_id == "cardio" then
      animation_name = phase == 0 and "gpt_handyman_repair_cardio"
        or phase == 1 and "gpt_handyman_repair_cardio_finish"
      marker = phase == 0 and {-21, -13, "px"} or {-20, -13, "px"}
      label = "cardio"
    elseif object_id == "ultrascanner" and phase == 0 then
      animation_name = "gpt_handyman_repair_ultrascanner"
      marker = {60, -4, "px"}
      label = "ultrascanner"
    elseif object_id == "slicer" and phase == 0 then
      animation_name = "gpt_handyman_repair_slicer"
      marker = {28, -20, "px"}
      label = "slicer"
    elseif object_id == "inflator" and phase == 0 then
      animation_name = "gpt_handyman_repair_inflator"
      marker = {59, -3, "px"}
      label = "inflator"
    else
      return
    end

    if animation_name then
      local _, animation = TheApp.animation_manager.anims:getAnimations(32, animation_name)
      anim_table.Handyman = {
        animation,
        object_visible = true,
        mirror = true,
      }
      TheApp.animation_manager:setStaffMarker(animation, marker)
      api.log("custom " .. label .. " repair phase " .. tostring(phase) ..
        " assigned: " .. tostring(animation))
    end
  end)

  api.hooks.register("humanoid.sweep_floor_animations", function(animation_numbers)
    api.log("sweep animation 1: " .. tostring(animation_numbers[1]))
    api.log("sweep animation 2: " .. tostring(animation_numbers[2]))
  end)
end
