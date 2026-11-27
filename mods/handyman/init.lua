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
    local sweep = TheApp.animation_manager.anims:getAnimations(
      32, "gpt_handyman_sweep"
    )

    animation_numbers[2] = sweep

    api.log("custom sweep animation assigned: " .. tostring(sweep))
  end)


  api.hooks.register("humanoid.door_animations", function(door_animations)
    local anims = TheApp.animation_manager.anims
    local handyman = door_animations.Handyman

    local function replace(name, field, direction)
      local north, east = anims:getAnimations(32, name)
      local animation = direction == "north" and north or east
      handyman[field] = animation
      api.log("custom " .. field .. " assigned: " .. tostring(animation))
    end

    replace("gpt_handyman_door_enter", "entering", "east")
    replace("gpt_handyman_door_leave", "leaving", "north")
    replace("gpt_handyman_swing_enter", "entering_swing", "east")
    replace("gpt_handyman_swing_leave", "leaving_swing", "north")
  end)

api.hooks.register("humanoid.use_object_animation", function(anim_table, object, humanoid, phase)
  if humanoid.humanoid_class ~= "Handyman" then
    return
  end

  local object_id = object.object_type.id
  api.log("use_object hook: object=" .. tostring(object_id) ..
    ", phase=" .. tostring(phase))

  local anims = TheApp.animation_manager.anims

  if object_id == "cardio" then
    if phase == 0 then
      local _, repair = anims:getAnimations(32, "gpt_handyman_repair_cardio")
      anim_table.Handyman = {
        repair,
        object_visible = true,
        mirror = true,
      }
      TheApp.animation_manager:setStaffMarker(repair, {-21, -13, "px"})
      api.log("custom cardio repair assigned: " .. tostring(repair))

    elseif phase == 1 then
      local _, finish = anims:getAnimations(32, "gpt_handyman_repair_cardio_finish")
      anim_table.Handyman = {
        finish,
        object_visible = true,
        mirror = true,
      }
      TheApp.animation_manager:setStaffMarker(finish, {-20, -13, "px"})
      api.log("custom cardio repair finish assigned: " .. tostring(finish))
    end

  elseif object_id == "slicer" and phase == 0 then
    local _, repair = anims:getAnimations(32, "gpt_handyman_repair_slicer")
    anim_table.Handyman = {
      repair,
      object_visible = true,
      mirror = true,
    }
    TheApp.animation_manager:setStaffMarker(repair, {28, -20, "px"})
    api.log("custom slicer repair assigned: " .. tostring(repair))

  elseif object_id == "hair_restorer" and phase == 0 then
    local _, repair = anims:getAnimations(32, "gpt_handyman_repair_hair_restorer")
    anim_table.Handyman = {
      repair,
      object_visible = true,
      mirror = true,
    }
    TheApp.animation_manager:setStaffMarker(repair, {61, -36, "px"})
    api.log("custom hair restorer repair assigned: " .. tostring(repair))
  end
end)

end