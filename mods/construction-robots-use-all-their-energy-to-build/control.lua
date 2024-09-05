local function drain_battery(event)
  event.robot.energy = 0
end

script.on_event(defines.events.on_robot_built_entity, drain_battery)
script.on_event(defines.events.on_robot_built_tile, drain_battery)

-- script.on_event(defines.events.on_robot_mined, drain_battery) -- this happens for every bot that tries to help mine a thing
script.on_event(defines.events.on_robot_mined_entity, drain_battery) -- this is only for the bot that does the final pickup

-- note how there is no event for proxy delivery
script.on_event(defines.events.on_robot_mined_tile, drain_battery)
-- script.on_event(defines.events.on_robot_exploded_cliff, drain_battery) -- does not look good
