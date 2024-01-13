local print_gui = require('scripts.print_gui')
local shared = require('shared')

local mod_prefix = 'fietff-'

local item_box_products = 1
local item_box_byproducts = 2
local item_box_ingredients = 3

local function split_class_and_name(class_and_name)
  local class, name = class_and_name:match('([^/]+)/([^/]+)')
  assert(class)
  assert(name)
  return class, name
end

local function active_radio_button(buttons)
  for _, button in ipairs(buttons) do
    if button.toggled then return button end
  end
  error('none of the buttons are active')
end

local function prefix_to_multiplier(locale_key)
  local multiplier = 1
  local prefixes = {"kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta"}

  if locale_key == nil then
    return multiplier
  end

  for _, prefix in ipairs(prefixes) do
    if 'fp.prefix_' .. prefix == locale_key then
      return multiplier * 1000
    else
      multiplier = multiplier * 1000
    end
  end
end

local function merge_ingredients(ingredients, new_ingredient)
  for _, ingredient in ipairs(ingredients) do
    if ingredient.type == new_ingredient.type and ingredient.name == new_ingredient.name then
      ingredient.amount = ingredient.amount + new_ingredient.amount
      return
    end
  end
  table.insert(ingredients, new_ingredient)
end

local function get_item_box_contents(root, item_box_index)
  local products = {}
  for _, sprite_button in ipairs(root.children[2].children[2].children[1].children[item_box_index].children[2].children[1].children[1].children) do
    if sprite_button.sprite ~= "utility/add" then
      local class, name = split_class_and_name(sprite_button.sprite)
      table.insert(products, {type = class, name = name, amount = sprite_button.number})
    end
  end
  return products
end

script.on_event(defines.events.on_gui_opened, function(event)
  if event.gui_type ~= defines.gui_type.custom then return end
  if event.element.name ~= "fp_frame_main_dialog" then return end
  local root = event.element

  -- game.print(root.name .. ' @ ' .. event.tick)

  -- log(print_gui.serpent( root.children[2].children[1].children[1].children[2] ))
  -- local factories = root.children[2].children[1].children[1].children[2].children
  -- local factory_name = active_radio_button(factories).caption[3]
  -- log(factory_name)
  
  -- log(print_gui.serpent( root.children[2].children[1].children[2].children[3].children[1].children[3] ))
  -- log(print_gui.path_to_tooltip(root, 'fp.timescale_tt', 'root'))

  local ingredient_labels = root.children[2].children[2].children[1].children[item_box_products].children[1]
  if not ingredient_labels['ingredients_to_factorissimo'] then
    local button_factorissimo = ingredient_labels.add{
      name = "ingredients_to_factorissimo",
      type = "sprite-button",
      sprite = "entity/fietff-container-1",
      tooltip = {"fp.ingredients_to_factorissimo_tt"},
      mouse_button_filter = {"left"},
    }
    button_factorissimo.style.size = 24
    button_factorissimo.style.padding = -2
    button_factorissimo.style.left_margin = 4
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  if event.element.name ~= "ingredients_to_factorissimo" then return end
  local player = game.get_player(event.player_index)
  local root = player.opened
  assert(root.name == 'fp_frame_main_dialog')

  local items_per_timescale_button = root.children[2].children[2].children[2].children[1].children[9].children[1]
  assert(items_per_timescale_button.caption[2][1] == "fp.pu_item")
  if items_per_timescale_button.toggled == false then
    return player.create_local_flying_text{
      text = "Timescale must be set to items.", -- [items/s-m-h] so we can extract the doubles we need for math
      create_at_cursor = true,
    }
  end

  local clipboard = {
    tick = event.tick,
  }

  clipboard.products = get_item_box_contents(root, item_box_products)
  clipboard.byproducts = get_item_box_contents(root, item_box_byproducts)
  clipboard.ingredients = get_item_box_contents(root, item_box_ingredients)

  log('products: ' .. serpent.line(clipboard.products))
  log('byproducts: ' .. serpent.line(clipboard.byproducts))
  log('ingredients: ' .. serpent.line(clipboard.ingredients))

  -- todo: check if products can be barreled
  -- todo: check if byproducts can be barreled
  -- todo: check if ingredients can be unbarreled

  if #clipboard.ingredients == 0 then
    return player.create_local_flying_text{
      text = "No ingredients defined at all.", -- a check whether a factory is selected "should" come first, but who has none?
      create_at_cursor = true,
    }
  end

  for _, ingredient in ipairs(clipboard.ingredients) do
    if ingredient.type == "entity" then
      return player.create_local_flying_text{
        text = "Mining drills are not supported.", -- it seems selecting pumpjacks does not allow for oil to be selected
        create_at_cursor = true,
      }
    end
  end
  
  local _table = table
  local table = root.children[2].children[2].children[2].children[3].children[1].children[1]
  local columns = {} -- [fp.pu_recipe, fp.pu_machine, fp.pu_beacon]
  for i, cell in ipairs(table.children) do -- the table has no rows, everything is a cell
    if cell.type ~= "label" then break end -- stop once we have all the column names
    columns[cell.caption[1]] = i -- thanks to preferences the amount & positions of columns can vary
  end

  local column_count = table_size(columns) + 1 -- + 1 for the horizontal flow
  local row_count = #table.children / column_count

  clipboard.buildings = {}

  for row = 2, row_count do
    local offset = (row - 1) * column_count
    
    -- if the sprite ever changes into something else yet still doesn't have a `/` in it an assert will failsafe-block it
    if table.children[offset + columns['fp.pu_machine']].children[1].sprite == 'fp_generic_assembler' then
      return player.create_local_flying_text{
        text = "Subfloors are not supported.",
        create_at_cursor = true,
      }
    end
    
    local recipe_class, recipe_name = split_class_and_name(table.children[offset + columns['fp.pu_recipe']].children[2].sprite)
    local machine_class, machine_name = split_class_and_name(table.children[offset + columns['fp.pu_machine']].children[1].sprite)
    local machine_count = math.ceil(table.children[offset + columns['fp.pu_machine']].children[1].number)
    merge_ingredients(clipboard.buildings, {type = machine_class, name = machine_name, amount = machine_count})

    local modules = {}
    for i = 2, #table.children[offset + columns['fp.pu_machine']].children do
      local module_button = table.children[offset + columns['fp.pu_machine']].children[i]
      if module_button.sprite ~= "utility/add" then
        local module_class, module_name = split_class_and_name(module_button.sprite)
        -- _table.insert(modules, {type = module_class, name = module_name, amount = module_button.number})
        merge_ingredients(clipboard.buildings, {type = module_class, name = module_name, amount = module_button.number})
      end
    end

    -- log(serpent.line({recipe_name, machine_count .. 'x ' .. machine_name, modules}))

    if #table.children[offset + columns['fp.pu_beacon']].children > 1 then -- 1 = supports beacons, 2+ = beacon and module(s) selected
      return player.create_local_flying_text{
        text = "Beacons are not supported.",
        create_at_cursor = true,
      }
    end

    local force_recipe = player.force.recipes[recipe_name]
    if force_recipe.enabled == false then -- wouldn't want players obtaining item outputs they shouldn't have unlocked yet (or cheaper recipes)
      -- return player.create_local_flying_text{
      --   text = string.format("Recipe [%s] not researched yet.", recipe_name),
      --   create_at_cursor = true,
      -- }
    end
  end

  do -- ensure all input/output fluids are barreled
    for i, product in ipairs(clipboard.products) do
      if product.type == "fluid" and global.can_be_barreled[product.name] then
        clipboard.products[i] = {
          type = "item",
          name = product.name .. "-barrel",
          amount = product.amount / 50,
        }
        merge_ingredients(clipboard.ingredients, {
          type = "item",
          name = "empty-barrel",
          amount = product.amount / 50,
        })
      end
    end

    for i, byproduct in ipairs(clipboard.byproducts) do
      if byproduct.type == "fluid" and global.can_be_barreled[byproduct.name] then
        clipboard.byproducts[i] = {
          type = "item",
          name = byproduct.name .. "-barrel",
          amount = byproduct.amount / 50,
        }
        merge_ingredients(clipboard.ingredients, {
          type = "item",
          name = "empty-barrel",
          amount = byproduct.amount / 50,
        })
      end
    end
  
    for i, ingredient in ipairs(clipboard.ingredients) do
      if ingredient.type == "fluid" and global.can_be_unbarreled[ingredient.name] then
        clipboard.ingredients[i] = {
          type = "item",
          name = ingredient.name .. "-barrel",
          amount = ingredient.amount / 50,
        }
        merge_ingredients(clipboard.byproducts, {
          type = "item",
          name = "empty-barrel",
          amount = ingredient.amount / 50,
        })
      end
    end

    for _, foo in ipairs({clipboard.products, clipboard.byproducts, clipboard.ingredients}) do
      for _, bar in ipairs(foo) do
        if bar.type == "fluid" then
          return player.create_local_flying_text{
            text = string.format('There is no barrel for the %s fluid.', bar.name),
            create_at_cursor = true,
          }
        end
      end
    end
  end

  if player.clear_cursor() == false then
    return player.create_local_flying_text{
      text = "Failed to empty your hand.",
      create_at_cursor = true,
    }
  end

  local factories = root.children[2].children[1].children[1].children[2].children
  clipboard.factory_name = active_radio_button(factories).caption[3]
  log(clipboard.factory_name)

  local energy_amount = tonumber(root.children[2].children[1].children[2].children[1].children[3].children[1].tooltip[2])
  local energy_prefix = root.children[2].children[1].children[2].children[1].children[3].children[1].tooltip[3][1] -- k/m/w (watt)
  clipboard.watts = energy_amount * prefix_to_multiplier(energy_prefix)
  log(clipboard.watts) -- /60 = number to put into electric energy interface usage (* for buffer)

  local pollution_per_minute = tonumber(root.children[2].children[1].children[2].children[1].children[3].children[3].tooltip[2])
  local pollution_per_minute_prefix = root.children[2].children[1].children[2].children[1].children[3].children[3].tooltip[3][1]
  clipboard.pollution = pollution_per_minute * prefix_to_multiplier(pollution_per_minute_prefix)
  log(clipboard.pollution)

  local timescale_buttons = root.children[2].children[1].children[2].children[3].children[1].children[3].children
  local timescale_button = active_radio_button(timescale_buttons)
  clipboard.timescale = timescale_button.caption[3][1] -- [fp.unit_second, fp.unit_minute, fp.unit_hours]
  log(clipboard.timescale)

  if energy_amount == 0 then
    return player.create_local_flying_text{
      text = "Factory must use (some) power.", -- because i want to use an interface's buffer as progress bar #lazy
      create_at_cursor = true,
    }
  end

  player.cursor_stack.set_stack({name = mod_prefix .. 'item-1', count = 1})
  -- player.opened = nil

  global.clipboards[player.index] = clipboard
  log(serpent.block(clipboard, {sortkeys = false}))
end)

local function on_created_entity(event)
  local entity = event.created_entity or event.entity or event.destination

  if event.player_index == nil then
    game.print(string.format('The %s should only be built by players.', entity.name))
    entity.destroy()
  end

  local player = game.get_player(event.player_index)
  local clipboard = global.clipboards[player.index]
  if not clipboard then
    entity.destroy()
    return player.create_local_flying_text{
      text = "Grab a new one from the factory planner gui.",
      create_at_cursor = true,
    }
  else
    global.clipboards[player.index] = nil -- mark clipboard as consumed
  end

  local eei = entity.surface.create_entity{
    name = mod_prefix .. 'electric-energy-interface-1',
    force = entity.force,
    position = {entity.position.x, entity.position.y + shared.electric_energy_interface_1_y_offset},
  }

  eei.destructible = false

  rendering.draw_text{
    text = clipboard.factory_name,
    color = {1, 1, 1},
    surface = entity.surface,
    target = entity,
    target_offset = {0, -3.75},
    alignment = "center",
    use_rich_text = true,
  }

  local io_string = ""

  for _, product in ipairs(clipboard.products) do
    io_string = io_string .. string.format('[%s=%s]', product.type, product.name)
  end
  io_string = io_string .. ' - '

  if #clipboard.byproducts > 0 then
    for _, byproduct in ipairs(clipboard.byproducts) do
      io_string = io_string .. string.format('[%s=%s]', byproduct.type, byproduct.name)
    end
    io_string = io_string .. ' - '
  end

  for _, ingredient in ipairs(clipboard.ingredients) do
    io_string = io_string .. string.format('[%s=%s]', ingredient.type, ingredient.name)
  end

  rendering.draw_text{
    text = io_string,
    color = {1, 1, 1},
    surface = entity.surface,
    target = entity,
    target_offset = {0, -3.00},
    alignment = "center",
    use_rich_text = true,
    scale = 0.5,
  }
end

for _, event in ipairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
  defines.events.on_entity_cloned,
}) do
  script.on_event(event, on_created_entity, {
    {filter = 'name', name = mod_prefix .. 'container-1'},
    {filter = 'name', name = mod_prefix .. 'container-2'},
    {filter = 'name', name = mod_prefix .. 'container-3'},
  })
end

local function on_configuration_changed(event)
  global.clipboards = global.clipboards or {}

  global.can_be_barreled = {}
  global.can_be_unbarreled = {}

  -- assume the recipes are like this, and that the research state of being able to barrel or unbarrel is insignificant
  -- todo: loop through all recipe names, determine the input and output values, determine the item name of the barrel.
  for fluid_name, fluid_prototype in pairs(game.fluid_prototypes) do
    if game.recipe_prototypes['fill-' .. fluid_name .. '-barrel'] then
      global.can_be_barreled[fluid_name] = true
    end
    if game.recipe_prototypes['empty-' .. fluid_name .. '-barrel'] then
      global.can_be_unbarreled[fluid_name] = true
    end
  end
end

script.on_init(on_configuration_changed)
script.on_configuration_changed(on_configuration_changed)