-- 大厨：调料配方1：1兑换
AddRecipe2("spice_garlic", { Ingredient("garlic", 1, nil, nil, "quagmire_garlic.tex") }, TECH.FOODPROCESSING_ONE,
    { builder_tag = "professionalchef", numtogive = 1, nounlock = true })
AddRecipe2("spice_sugar", { Ingredient("honey", 1) }, TECH.FOODPROCESSING_ONE,
    { builder_tag = "professionalchef", numtogive = 1, nounlock = true })
AddRecipe2("spice_chili", { Ingredient("pepper", 1) }, TECH.FOODPROCESSING_ONE,
    { builder_tag = "professionalchef", numtogive = 1, nounlock = true })
AddRecipe2("spice_salt", { Ingredient("saltrock", 1) }, TECH.FOODPROCESSING_ONE,
    { builder_tag = "professionalchef", numtogive = 1, nounlock = true })

AddRecipe2("spice_garlic2", { Ingredient("garlic", 20, nil, nil, "quagmire_garlic.tex") }, TECH.FOODPROCESSING_ONE,
    {
        builder_tag = "professionalchef",
        product = "spice_garlic",
        image = "spice_garlic.tex",
        description =
        "spice_garlic2",
        numtogive = 20,
        nounlock = true
    })
STRINGS.RECIPE_DESC.spice_garlic2 = "批量蒜粉"

AddRecipe2("spice_chili2", { Ingredient("pepper", 20) }, TECH.FOODPROCESSING_ONE,
    {
        builder_tag = "professionalchef",
        product = "spice_chili",
        image = "spice_chili.tex",
        description = "spice_chili2",
        numtogive = 20,
        nounlock = true
    })
STRINGS.RECIPE_DESC.spice_chili2 = "批量辣椒面"

AddRecipe2("spice_sugar2", { Ingredient("honey", 20) }, TECH.FOODPROCESSING_ONE,
    {
        builder_tag = "professionalchef",
        product = "spice_sugar",
        image = "spice_sugar.tex",
        description = "spice_sugar2",
        numtogive = 20,
        nounlock = true
    })
STRINGS.RECIPE_DESC.spice_sugar2 = "批量蜂蜜水晶"

AddRecipe2("spice_salt2", { Ingredient("saltrock", 20) }, TECH.FOODPROCESSING_ONE,
    {
        builder_tag = "professionalchef",
        product = "spice_salt",
        image = "spice_salt.tex",
        description = "spice_salt2",
        numtogive = 20,
        nounlock = true
    })
STRINGS.RECIPE_DESC.spice_salt2 = "批量调味盐"

-- 美食家：吃食物时将获得额外收益1倍
local extra_food_benefits = 1

local function oneat(inst, data)
    local food = data.food
    if food and food.components.edible then
        local hungerbonus = food.components.edible:GetHunger() * extra_food_benefits
        local sanitybonus = food.components.edible:GetSanity() * extra_food_benefits
        local healthbonus = food.components.edible:GetHealth() * extra_food_benefits

        if inst.components.hunger and hungerbonus > 0 then
            inst.components.hunger:DoDelta(hungerbonus)
        end

        if inst.components.sanity and sanitybonus > 0 then
            inst.components.sanity:DoDelta(sanitybonus)
        end

        if inst.components.health and healthbonus > 0 then
            inst.components.health:DoDelta(healthbonus, true, food.prefab)
        end
    end
end

-- 屠夫：击打食物时有更多的概率获得额外掉落物
local warly_butcher = 0.75
local function Extraloot(inst, data)
    local target = data.target
    if target and target.components.lootdropper then
        if not target._hasExtraloot then
            target._hasExtraloot = true
            local loots = target.components.lootdropper:GenerateLoot()
            for i, loot in ipairs(loots) do
                local lootitem = SpawnPrefab(loot)
                if math.random() > warly_butcher and lootitem and lootitem.components and lootitem.components.edible
                    and table.contains(FOODGROUP.OMNI.types, lootitem.components.edible.foodtype)
                then
                    target.components.lootdropper:SpawnLootPrefab(loot)
                end
                lootitem:Remove()
            end
        end
    end
end

-- 刽子手：厨师使用具有新鲜度或克眼的那两个装备时获得额外的收益
local food_damage_mult = 0.25  --每穿戴一件有新鲜度的装备，伤害增加比率
local planar_damage_bonus = 10 -- 位面伤害加成

local function GetEquip(inst)
    local WARLY_DAMAGE_MULT = 1
    local planar_bonus = 0
    for k, v in pairs(EQUIPSLOTS) do
        local equip = inst.components.inventory:GetEquippedItem(v)
        if equip and equip.components and (equip.components.perishable or equip.components.eater) then
            WARLY_DAMAGE_MULT = WARLY_DAMAGE_MULT + food_damage_mult
            planar_bonus = planar_bonus + planar_damage_bonus
        end
    end

    inst.components.combat.damagemultiplier = WARLY_DAMAGE_MULT

    if inst.components.planardamage then
        inst.components.planardamage:SetBaseDamage(planar_bonus)
    else
        inst:AddComponent("planardamage")
        inst.components.planardamage:SetBaseDamage(planar_bonus)
    end
end

AddPrefabPostInit("warly", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("oneat", oneat)
    inst:ListenForEvent("onattackother", Extraloot)
    inst:ListenForEvent("equip", GetEquip)
    inst:ListenForEvent("unequip", GetEquip)

    -- inst:AddTag("multiplefoodharvester")
    -- inst:AddComponent("multiplefoodharvester")

    -- inst.components.multiplefoodharvester.mult = function(potprefab)
    --     if potprefab == "cookpot" or potprefab == "archive_cookpot" and math.random() < 0.1 then
    --         return 2
    --     end

    --     if potprefab == "portablecookpot" and math.random() < 0.2 then
    --         return 2
    --     end

    --     return 1
    -- end
end)


-- 厨师袋改成便携式袋
local containers = require("containers")
containers.params.spicepack = GLOBAL.deepcopy(containers.params.beargerfur_sack)
containers.params.spicepack.itemtestfn = function(container, item, slot)
    for i, v in ipairs(GLOBAL.FOODGROUP.OMNI.types) do
        if item:HasTag("edible_" .. v) or item:HasTag("spice") then return true end
    end
end
for k, v in pairs(containers.params.spicepack.widget.slotbg) do
    containers.params.spicepack.widget.slotbg[k] = { image = "inv_slot_morsel.tex" }
end
AddPrefabPostInit("spicepack", function(inst)
    inst:RemoveTag("backpack")
    inst:AddTag("portablestorage")

    if not TheWorld.ismastersim then return end

    if inst.components.equippable ~= nil then
        inst:RemoveComponent("equippable")
    end

    inst.components.inventoryitem.cangoincontainer = true
    inst.components.inventoryitem.canonlygoinpocket = true

    -- if inst.components.preserver == nil then
    --     inst:AddComponent("preserver")
    -- end
    -- inst.components.preserver:SetPerishRateMultiplier(1 * 0.5)

    -- inst.components.container.skipclosesnd = true
    -- inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true
end)

-- 厨师锅调整
-- 且具备保鲜能力与冰箱相同
TUNING.PORTABLE_COOK_POT_TIME_MULTIPLIER = 0.8
AddPrefabPostInit("portablecookpot", function(inst)
    inst:AddTag("fridge") --保鲜0.5倍
    inst:AddTag("nocool") --没有冷冻的效果

    if not TheWorld.ismastersim then return end
end)

-- 沃利的特殊料理时长是其他角色的2倍
local longer_buff_time = 2
AddComponentPostInit("debuffable", function(self)
    local O = self.AddDebuff
    self.AddDebuff = function(...)
        local ent = O(...)
        if self.inst.prefab == "warly" then
            local timer = ent and ent.components.timer
            if timer and timer:GetTimeLeft("buffover") then
                timer:SetTimeLeft("buffover", timer:GetTimeLeft("buffover") * longer_buff_time)
            end
        end
        return ent
    end
end)
