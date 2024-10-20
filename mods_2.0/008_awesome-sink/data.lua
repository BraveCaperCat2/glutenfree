local sink = table.deepcopy(data.raw["linked-belt"]["linked-belt"])
local shop = table.deepcopy(data.raw["linked-container"]["linked-chest"])

local sink_item = table.deepcopy(data.raw["item"]["linked-belt"])
local shop_item = table.deepcopy(data.raw["item"]["linked-chest"])

sink_item.name = "awesome-sink"
sink_item.icon = "__awesome-sink__/graphics/icons/awesome-sink.png"
sink.name = sink_item.name
sink.icon = sink_item.icon

shop_item.name = "awesome-shop"
shop_item.icon = "__awesome-sink__/graphics/icons/awesome-shop.png"
shop.name = shop_item.name
shop.icon = shop_item.icon

sink_item.place_result = sink.name
shop_item.place_result = shop.name

sink.minable.result = sink_item.name
shop.minable.result = shop_item.name

for _, direction_thing in pairs(sink.structure) do
  if direction_thing.sheet.filename then
    direction_thing.sheet.filename = "__awesome-sink__/graphics/entity/awesome-sink.png"
  end
end
shop.picture.layers[1].filename = "__awesome-sink__/graphics/entity/awesome-shop.png"

-- too heavy for rocket
sink_item.weight = 10 * tons
shop_item.weight = 10 * tons

sink_item.stack_size = 1
shop_item.stack_size = 1

shop.inventory_size = 48
shop.inventory_type = "normal"
shop.gui_mode = "none"
table.insert(shop.flags, "no-automated-item-insertion")

data:extend{
  sink, sink_item,
  shop, shop_item,
}

for _, prototype in ipairs({
  data.raw["decider-combinator"]["decider-combinator"],
  data.raw["arithmetic-combinator"]["arithmetic-combinator"],
}) do
  local awesome_combinator = table.deepcopy(prototype)
  awesome_combinator.name = "awesome-" .. awesome_combinator.name
  awesome_combinator.energy_source = {type = "void"}
  awesome_combinator.minable.result = nil
  awesome_combinator.hidden_in_factoriopedia = true
  data:extend{awesome_combinator}
end

-- data.raw["container"]["wooden-chest"].picture.layers[1] = util.empty_sprite()

local assembler = {
  type = "assembling-machine",
  name = "awesome-sink-gui",

  icon = sink_item.icon,

  selection_box = sink.selection_box,
  collision_box = sink.collision_box,
  collision_mask = sink.collision_mask,

  flags = {"placeable-neutral", "placeable-player", "player-creation"},
  crafting_categories = {"crafting", "basic-crafting", "advanced-crafting"}, -- todo: awesome sink

  graphics_set = util.empty_sprite(),

  module_slots = 2,
  allowed_effects = {"quality"},

  energy_usage = "1kW",
  energy_source = {type = "void"},
  crafting_speed = 0.5,

  icon_draw_specification = {scale = 0.35},
  selection_priority = 51,
}

-- honestly im not even gonna try, its too much pain for too little effort merely to make blueprint support better rn
-- assembler.graphics_set =
-- {
--   animation = make_4way_animation_from_spritesheet({ layers =
--   {
--     {
--       filename = "__awesome-sink__/graphics/entity/awesome-sink.png",
--       width = 220,
--       height = 292,
--       frame_count = 24,
--       line_length = 12,
--       shift = util.by_pixel(0.5, -9),
--       scale = 0.5
--     },
--     -- {
--     --   filename = "__base__/graphics/entity/chemical-plant/chemical-plant.png",
--     --   width = 220,
--     --   height = 292,
--     --   frame_count = 24,
--     --   line_length = 12,
--     --   shift = util.by_pixel(0.5, -9),
--     --   scale = 0.5
--     -- },
--     -- {
--     --   filename = "__base__/graphics/entity/chemical-plant/chemical-plant-shadow.png",
--     --   width = 312,
--     --   height = 222,
--     --   repeat_count = 24,
--     --   shift = util.by_pixel(27, 6),
--     --   draw_as_shadow = true,
--     --   scale = 0.5
--     -- }
--   }})
-- }

assembler.selection_box = {{-1, -1}, {1, 1}}

data:extend{assembler}
