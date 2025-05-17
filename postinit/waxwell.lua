--开局带影刀影甲
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "nightsword")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "armor_sanity")

--解锁暗影装备
AddPrefabPostInit("waxwell", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("darkmagic")
    inst:DoTaskInTime(0, function()
        if inst.components.builder then
            if not inst.components.builder:KnowsRecipe("nightsword") and inst.components.builder:CanLearn("nightsword") then
                inst.components.builder:UnlockRecipe("nightsword")
            end
            if not inst.components.builder:KnowsRecipe("armor_sanity") and inst.components.builder:CanLearn("armor_sanity") then
                inst.components.builder:UnlockRecipe("armor_sanity")
            end
        end
    end)
end)

local ACTIONS = GLOBAL.ACTIONS

-- 定义召回动作
local recall_action = Action({ priority = 20, rmb = true, distance = 1, mount_valid = true })
recall_action.id = "WURTCH"
recall_action.str = "召回"
recall_action.fn = function(act)
    if act.doer and act.doer.components.leader then
        local followers_to_remove = {}
        for follower in pairs(act.doer.components.leader.followers) do
            if follower:HasTag("shadowminion") and follower.prefab ~= "old_shadowwaxwell" then
                -- 记录需要移除的影人
                table.insert(followers_to_remove, follower)
            end
        end

        -- 移除影人并生成效果
        for _, follower in ipairs(followers_to_remove) do
            SpawnPrefab("shadow_despawn").Transform:SetPosition(follower.Transform:GetWorldPosition())
            if follower.components.inventory then
                follower.components.inventory:DropEverything(true)
            end
            follower:DoTaskInTime(0, follower.Remove)
        end

        -- 提示召回完成
        if #followers_to_remove > 0 then
            act.doer.components.talker:Say("回来，我的暗影仆从！")
        else
            act.doer.components.talker:Say("没有影人可召回。")
        end

        return true
    end
    return false
end

AddAction(recall_action)

AddComponentAction("SCENE", "inventory", function(inst, doer, actions)
    if inst == doer and inst.prefab == "waxwell" and inst:HasTag("player") then
        if inst.replica.rider and inst.replica.rider:IsRiding() then
            return -- 如果骑乘状态，直接不添加动作
        end
        table.insert(actions, ACTIONS.WURTCH)
    end
end)

for sg, is_client in pairs({ wilson = false, wilson_client = true }) do
    AddStategraphActionHandler(sg, ActionHandler(ACTIONS.WURTCH, "doshortaction"))
end

AddPrefabPostInit("waxwell", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end

    inst:DoPeriodicTask(1, function()
        if inst:HasTag("playerghost") then
            inst:RemoveTag("Puren")
            return
        end
        if inst.components.leader and inst.components.leader:CountFollowers("shadowminion") > 0 then
            inst:AddTag("Puren")
        else
            inst:RemoveTag("Puren")
        end
    end)
end)
