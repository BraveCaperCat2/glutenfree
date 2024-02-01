local function starts_with(str, start)
  return str:sub(1, #start) == start
end

script.on_event(defines.events.on_player_clicked_gps_tag, function(event)
  -- game.print(string.format('x=%d, y=%d, surface=%s', event.position.x, event.position.y, event.surface))

  if starts_with(event.surface, 'https://') == false then return end

  local player = game.get_player(event.player_index)

  if game.active_mods['space-exploration'] == nil then
    player.print({"space-exploration.gps_invalid"})
  end

  player.print('[img=newsletter-for-mods-made-by-quezler-crater] Quezler released a new mod!')
end)
