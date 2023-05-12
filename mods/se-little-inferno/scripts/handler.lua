util = require("util")

local Handler = {}

function Handler.on_init()
  global.next_tick_events = {}
  global.surfaces = {}

  -- nauvis & adding it halfway through run
  for _, surface in pairs(game.surfaces) do
    Handler.on_surface_created({surface_index = surface.index, name = defines.events.on_surface_created})
  end
end

function Handler.on_load()
  if #global.next_tick_events > 0 then
    script.on_event(defines.events.on_tick, Handler.on_tick)
  end
end

function Handler.on_tick(event)
  for _, e in ipairs(global.next_tick_events) do
    if e.name == defines.events.on_surface_created then Handler.on_post_surface_created(e) end
  end

  global.next_tick_events = {}
  script.on_event(defines.events.on_tick, nil)
end

local force_charting_ignored = util.list_to_map({'neutral', 'enemy'})

function Handler.is_chunk_charted(surface, position) -- by any player force, only called when the mod is added
  for _, force in pairs(game.forces) do
    if not force_charting_ignored[force.name] then
      if force.is_chunk_charted(surface, position) then
        return true
      end
    end
  end

  return false
end

local pollutable = util.list_to_map({'planet', 'moon'})

function Handler.on_surface_created(event)
  global.surfaces[event.surface_index] = {
    enabled = false,
    chunks = {},
  }

  table.insert(global.next_tick_events, event)
  script.on_event(defines.events.on_tick, Handler.on_tick)
end

function Handler.on_post_surface_created(event)
  game.print('post')
  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = event.surface_index})
  if zone and pollutable[zone.type] then
    game.print(zone.name)

    Handler.set_enabled_for_surface_index({surface_index = event.surface_index, enabled = true})
  end
end

function Handler.on_surface_deleted(event)
  global.surfaces[event.surface_index] = nil
end

function Handler.on_chunk_charted(event)
  if not global.surfaces[event.surface_index].enabled then return end

  local chunk_key = util.positiontostr(event.position)
  if global.surfaces[event.surface_index].chunks[chunk_key] == nil then
    local surface = game.get_surface(event.surface_index)

    -- print(serpent.block(surface.name), chunk_key)

    local entity_to_create = {
      name = "se-little-inferno",
      position = {event.position.x * 32 + 16, event.position.y * 32 + 16} -- the center of each chunk
    }
  
    -- todo: do we even need this check if we track it with global.surfaces anyways?
    -- if surface.can_place_entity(entity_to_create) then

    local entity = surface.find_entity(entity_to_create.name, entity_to_create.position)
    if not entity then
      entity = surface.create_entity(entity_to_create)
    else
      game.print('you should not see this message, contact Quezler.')
    end

    global.surfaces[event.surface_index].chunks[chunk_key] = entity
  end



  -- game.forces['player'].chart(event.surface, event.area)
end

function Handler.on_chunk_deleted(event)
  for _, position in ipairs(event.positions) do
    local chunk_key = util.positiontostr(position)
    global.surfaces[event.surface_index].chunks[chunk_key] = nil
  end
end

--

function Handler.on_entity_cloned(event)
  event.destination.destroy() -- gotta pay the cheese tax
  -- local chunk_key = util.positiontostr({math.floor(event.destination.position.x / 32), math.floor(event.destination.position.y / 32)})
  -- game.print('cloned ' .. chunk_key)
  -- game.print('cloned ' .. event.destination.name)

  
end

function Handler.script_raised_destroy(event)
  local position = {x = math.floor(event.entity.position.x / 32), y = math.floor(event.entity.position.y / 32)}
  local chunk_key = util.positiontostr(position)
  -- game.print('destroyed ' .. chunk_key)
  -- game.print('destroyed ' .. event.entity.name)

  -- if event.entity == global.surfaces[event.entity.surface.index].chunks[chunk_key] then
    -- already being destroyed, but the surface.find_entity above can still see it
    -- global.surfaces[event.entity.surface.index].chunks[chunk_key].destroy()
    -- global.surfaces[event.entity.surface.index].chunks[chunk_key] = nil
  -- else
    -- game.print('you should not see this message, contact Quezler.')
  -- end

  -- Handler.on_chunk_charted({
  --   position = position,
  --   surface_index = event.entity.surface.index,
  -- })

  global.surfaces[event.entity.surface.index].chunks[chunk_key] = event.entity.surface.create_entity{
    name = "se-little-inferno",
    position = {position.x * 32 + 16, position.y * 32 + 16} -- the center of each chunk
  }
end

--

-- function Handler.get_or_create_surface_struct(surface_index)
-- end

function Handler.get_enabled_for_surface_index(data)
  return global.surfaces[data.surface_index].enabled
end

function Handler.set_enabled_for_surface_index(data)
  if global.surfaces[data.surface_index].enabled == data.enabled then return end 

  if data.enabled == true then
    global.surfaces[data.surface_index].enabled = true
    local surface = game.surfaces[data.surface_index]
    for chunk in surface.get_chunks() do
      local position = {x = chunk.x, y = chunk.y}
      if Handler.is_chunk_charted(surface, position) then
        Handler.on_chunk_charted({position = position, surface_index = surface.index})
      end
    end
  elseif data.enabled == false then
    for _, entity in pairs(global.surfaces[data.surface_index].chunks) do
      entity.destroy() -- entity.valid not needed for .destroy()
    end
    global.surfaces[data.surface_index].chunks = {}
    global.surfaces[data.surface_index].enabled = false
  else
    error('enabled must be a boolean.')
  end
end

return Handler
