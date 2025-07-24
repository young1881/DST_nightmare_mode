local assets = {
    Asset("ANIM", "anim/pocketwatch_cherrift.zip"),
    Asset("ATLAS", "images/inventoryimages/pocketwatch_cherrift.xml"),
}

local prefabs =
{
    "pocketwatch_cast_fx",
    "pocketwatch_cast_fx_mount",
    "pocketwatch_heal_fx",
    "pocketwatch_heal_fx_mount",
    "pocketwatch_ground_fx",
    "pocketwatch_warp_marker",
    "pocketwatch_warpback_fx",
    "pocketwatch_warpbackout_fx",
    "pocketwatch_revive_reviver",
}

local PocketWatchCommon = require "prefabs/pocketwatch_common"

local excluded_tags = { "ai_stopped", "epic", "player", "abigail", "companion", "INLIMBO", "structure",
    "butterfly", "wall", "balloon", "groundspike", "stalkerminion", "lightflier",
    "smashable" }

local function HasExcludedTags(entity)
    for _, tag in ipairs(excluded_tags) do
        if entity:HasTag(tag) then
            return true
        end
    end
    return false
end

local function start_ai(monster) 
    if monster:IsValid() then
        monster:RestartBrain()
        if monster.sg then
            monster.sg:Start()
        end
        if monster.Physics then
            monster.Physics:SetActive(true)
        end
        if monster.AnimState then
            monster.AnimState:Resume()
            monster.AnimState:SetAddColour(0, 0, 0, 0)
        end
    end

    monster:RemoveEventCallback("death", start_ai)
end

local function stop_ai(monster)
    if HasExcludedTags(monster) then
        return
    end

    if monster.sg ~= nil and monster.sg:HasStateTag("dead") then
        return
    end

    monster:StopBrain()
    if monster.sg then
        monster.sg:Stop()
    end
    if monster.Physics then
        monster.Physics:ClearMotorVelOverride()
        monster.Physics:Stop()
        monster.Physics:SetActive(false)
    end
    if monster.AnimState then
        monster.AnimState:Pause()
        monster.AnimState:SetAddColour(0.4, 0, 0.45, 0)
    end

    monster:ListenForEvent("death", function() start_ai(monster) end)
end



local function DoCastSpell(inst, doer)
    local health = doer.components.health
    if health ~= nil and not health:IsDead() then
        doer.components.oldager:StopDamageOverTime()
        health:DoDelta(-TUNING.POCKETWATCH_HEAL_HEALING * 1.5, true, inst.prefab)

        local fx = SpawnPrefab((doer.components.rider ~= nil and doer.components.rider:IsRiding()) and
            "pocketwatch_heal_fx_mount" or "pocketwatch_heal_fx")
        fx.entity:SetParent(doer.entity)

        inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_HEAL_COOLDOWN * 2)
    end

    local radius = 10
    local duration = 16
    local interval = 0.1

    local x, y, z = doer.Transform:GetWorldPosition()

    local function StopAIInArea()
        if doer == nil or not doer:IsValid() then return end

        local entities = TheSim:FindEntities(x, y, z, radius, { "_combat", "_health" }, { "playerghost", "INLIMBO" })
        for _, entity in ipairs(entities) do
            if entity ~= doer and not HasExcludedTags(entity) then
                stop_ai(entity)
                entity:AddTag("ai_stopped")
                entity:DoTaskInTime(duration, function()
                    start_ai(entity)
                    entity:RemoveTag("ai_stopped")
                end)
            end
        end
    end

    for i = 0, duration / interval do
        inst:DoTaskInTime(i * interval, StopAIInArea)
    end
    return true
end

local PLAYERSKELETON_TAG = { "playerskeleton" }
local MOUNTED_CAST_TAGS = { "pocketwatch_mountedcast" }

local function healfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch", "pocketwatch_cherrift", DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.castfxcolour = { 255 / 255, 241 / 255, 236 / 255 }

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_cherrift.xml"

    return inst
end

return Prefab("pocketwatch_cherrift", healfn, assets, prefabs)
