return function(api)
  api.log("test package initialized")

  api.hooks.register("humanoid.animations", function(animations)
    if animations.Handyman then
      api.log("humanoid.animations hook reached; Handyman table is available")
    else
      api.log("humanoid.animations hook reached")
    end
  end)
end
