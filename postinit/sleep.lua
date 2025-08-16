TUNING.SLEEP_HEALTH_PER_TICK = 2  --帐篷回血增强，2是二倍
TUNING.SLEEP_HUNGER_PER_TICK = -2 --帐篷掉饱食度双倍
TUNING.SLEEP_SANITY_PER_TICK = 2  --帐篷回san双倍
TUNING.PORTABLE_TENT_USES = 5     --尼哥的帐篷五次耐久

--- 干燥时间 （480就是一天的长度）
TUNING.DRY_SUPERFAST = 0.12 * 480 -- 海带
TUNING.DRY_FAST = 0.25 * 480      -- 怪物肉
TUNING.DRY_MED = 0.5 * 480        -- 大肉

--- 肉干加强
local function modify_meat_dried(inst)
    if inst.components.edible ~= nil then
        inst.components.edible.healthvalue = 40
        inst.components.edible.hungervalue = 62.5
        inst.components.edible.sanityvalue = 20
    end
end

AddPrefabPostInit("meat_dried", modify_meat_dried)

--- 小肉干加强
local function modify_smallmeat_dried(inst)
    if inst.components.edible ~= nil then
        inst.components.edible.healthvalue = 20
        inst.components.edible.hungervalue = 25
        inst.components.edible.sanityvalue = 10
    end
end

AddPrefabPostInit("smallmeat_dried", modify_smallmeat_dried)


--- 怪物肉干加强
local function modify_monstermeat_dried(inst)
    if inst.components.edible ~= nil then
        inst.components.edible.healthvalue = -3
        inst.components.edible.hungervalue = 80
        inst.components.edible.sanityvalue = -5
    end
end

AddPrefabPostInit("monstermeat_dried", modify_monstermeat_dried)
