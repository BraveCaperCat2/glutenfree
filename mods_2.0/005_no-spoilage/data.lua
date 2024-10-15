-- there are so many children of item prototypes, might as well run through all the entities too since only items have spoil_ticks.
-- log('these items have spoil ticks defined:')
-- for _, prototypes in pairs(data.raw) do
--   for _, prototype in pairs(prototypes) do
--     if prototype.spoil_ticks ~= nil then
--       log(prototype.type .. ':' .. prototype.name)
--       -- prototype.spoil_ticks = nil
--     end
--   end
-- end

-- the above code outputs this list, we're gonna curate it manually to avoid conflicts with other mods.

-- item:copper-bacteria
-- item:iron-bacteria
-- item:nutrients
-- item:captive-biter-spawner
-- item:biter-egg
-- item:pentapod-egg
-- item:disposable-construction-robot
-- capsule:raw-fish
-- capsule:yumako
-- capsule:jellynut
-- capsule:yumako-mash
-- capsule:jelly
-- capsule:bioflux
-- tool:agricultural-science-pack

local function remove_spoil_mechanic(prototype)
  prototype.spoil_ticks = nil
  prototype.spoil_result = nil
  prototype.spoil_to_trigger_result = nil
end

-- remove_spoil_mechanic(data.raw["item"]["copper-bacteria"])
-- remove_spoil_mechanic(data.raw["item"]["iron-bacteria"])
remove_spoil_mechanic(data.raw["item"]["nutrients"])
remove_spoil_mechanic(data.raw["item"]["captive-biter-spawner"])
remove_spoil_mechanic(data.raw["item"]["biter-egg"])
remove_spoil_mechanic(data.raw["item"]["pentapod-egg"])
remove_spoil_mechanic(data.raw["item"]["disposable-construction-robot"])
remove_spoil_mechanic(data.raw["capsule"]["raw-fish"])
remove_spoil_mechanic(data.raw["capsule"]["yumako"])
remove_spoil_mechanic(data.raw["capsule"]["jellynut"])
remove_spoil_mechanic(data.raw["capsule"]["yumako-mash"])
remove_spoil_mechanic(data.raw["capsule"]["jelly"])
remove_spoil_mechanic(data.raw["capsule"]["bioflux"])
remove_spoil_mechanic(data.raw["tool"]["agricultural-science-pack"])
