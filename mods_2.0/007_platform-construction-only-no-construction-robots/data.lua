local construction_robot = data.raw["construction-robot"]["construction-robot"]

local function turn_construction_robots_invisible()
  construction_robot.idle = util.empty_sprite()
  -- construction_robot.idle_with_cargo = util.empty_sprite()
  construction_robot.in_motion = util.empty_sprite()
  -- construction_robot.in_motion_with_cargo = util.empty_sprite()
  construction_robot.shadow_idle = util.empty_sprite()
  -- construction_robot.shadow_idle_with_cargo = util.empty_sprite()
  construction_robot.shadow_in_motion = util.empty_sprite()
  -- construction_robot.shadow_in_motion_with_cargo = util.empty_sprite()
  construction_robot.working = util.empty_sprite()
  construction_robot.shadow_working = util.empty_sprite()

  construction_robot.icon_draw_specification = {scale = 0}
end

turn_construction_robots_invisible()

local space_platform_entity_build_animations = require("__space-age__/graphics/entity/space-platform-build-anim/entity-build-animations")

local function make_animation_prototype(a, b)
  local animation = table.deepcopy(space_platform_entity_build_animations[a][b])
  animation.type = "animation"
  animation.name = string.format("platform_entity_build_animations-%s-%s", a, b)
  data:extend{animation}
end

make_animation_prototype("back_left", "top")
make_animation_prototype("back_left", "body")

make_animation_prototype("back_right", "top")
make_animation_prototype("back_right", "body")

make_animation_prototype("front_left", "top")
make_animation_prototype("front_left", "body")

make_animation_prototype("front_right", "top")
make_animation_prototype("front_right", "body")

local created_effect = {
  type = "direct",
  action_delivery = {
    type = "instant",
    source_effects = {
      {
        type = "script",
        effect_id = "construction-robot-created",
      },
    }
  }
}

local construction_robot = data.raw["construction-robot"]["construction-robot"]
assert(construction_robot.created_effect == nil)
construction_robot.created_effect = created_effect
