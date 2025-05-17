-- 蜂后帽加强
local function hivehat(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst.components.armor:InitCondition(945, 0.9)

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(10)
end

AddPrefabPostInit("hivehat", hivehat)

-- 蜂后帽配方
AddRecipe2("hivehat",
    { Ingredient("honeycomb", 2), Ingredient("honey", 3), Ingredient("bee", 2), Ingredient("royal_jelly", 1) }, TECH
    .LOST, nil,
    { "ARMOUR" })

STRINGS.RECIPE_DESC.HIVEHAT = "听说拿来打织影者有奇效"

-- 蜂后的四个阶段的分界点
local PHASE2_HEALTH = 0.99
local PHASE3_HEALTH = 0.75
local PHASE4_HEALTH = 0.5

local function OnLoad(inst, data)
    local healthpct = inst.components.health:GetPercent()
    SetPhaseLevel(
        inst,
        (healthpct > PHASE2_HEALTH and 1) or
        (healthpct > PHASE3_HEALTH and 2) or
        (healthpct > PHASE4_HEALTH and 3) or
        4
    )

    if data ~= nil and
        data.boost ~= nil and
        data.boost > inst.components.commander.trackingdist then
        inst.components.commander:SetTrackingDistance(data.boost)
        if not (inst.commanderboost or inst:IsAsleep()) then
            BoostCommanderRange(inst, false)
        end
    end
end

local function SetPhaseLevel(inst, phase)
    inst.focustarget_cd = TUNING.BEEQUEEN_FOCUSTARGET_CD[phase]
    inst.spawnguards_cd = TUNING.BEEQUEEN_SPAWNGUARDS_CD[phase]
    inst.spawnguards_maxchain = TUNING.BEEQUEEN_SPAWNGUARDS_CHAIN[phase]
    inst.spawnguards_threshold = phase > 1 and TUNING.BEEQUEEN_TOTAL_GUARDS or 1
end

local function EnterPhase2Trigger(inst)
    SetPhaseLevel(inst, 2)
    inst:PushEvent("screech")
end

local function EnterPhase3Trigger(inst)
    SetPhaseLevel(inst, 3)
    inst:PushEvent("screech")
end

local function EnterPhase4Trigger(inst)
    SetPhaseLevel(inst, 4)
    inst:PushEvent("screech")
end

AddPrefabPostInit("beequeen", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.healthtrigger:AddTrigger(PHASE2_HEALTH, EnterPhase2Trigger)
    inst.components.healthtrigger:AddTrigger(PHASE3_HEALTH, EnterPhase3Trigger)
    inst.components.healthtrigger:AddTrigger(PHASE4_HEALTH, EnterPhase4Trigger)
    inst.OnLoad = OnLoad
end)


--击杀蜂后生成五只小鸭子
AddPrefabPostInit("beequeen", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:AddChanceLoot('mossling', 1)
    inst.components.lootdropper:AddChanceLoot('mossling', 1)
    inst.components.lootdropper:AddChanceLoot('mossling', 1)
    inst.components.lootdropper:AddChanceLoot('mossling', 1)
    inst.components.lootdropper:AddChanceLoot('mossling', 1)
    inst.components.lootdropper:AddChanceLoot('moose', 1)
    inst.components.lootdropper:AddChanceLoot("hivehat_blueprint", 1)
end)

-- 小蜜蜂掉落蜂王浆
AddPrefabPostInit("beeguard", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:AddChanceLoot('royal_jelly', 0.01)
end)
