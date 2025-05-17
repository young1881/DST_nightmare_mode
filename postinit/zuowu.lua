--作物全季节生长
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
for _, plant_def in pairs(PLANT_DEFS) do
    plant_def.good_seasons = {
        autumn = true,
        winter = true,
        spring = true,
        summer = true
    }
end
return {PLANT_DEFS = PLANT_DEFS}