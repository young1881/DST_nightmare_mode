-- local function OnDead(inst)
--     AwardRadialAchievement("deerclops_killed", inst:GetPosition(), TUNING.ACHIEVEMENT_RADIUS_FOR_GIANT_KILL)
--     TheWorld:PushEvent("hasslerkilled", inst)
-- end

-- AddPrefabPostInit("deerclops", function(inst)
--     if not TheWorld.ismastersim then
--         return
--     end

--     inst:ListenForEvent("death", OnDead)
-- end)

local function DoEraser(inst, target)
    if target.components.inventory then
        target.components.inventory:ApplyDamage(5000)
    end
end


AddPrefabPostInit("mutateddeerclops", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("truedamage")
    inst.components.truedamage:SetBaseDamage(25)
    MakePlayerOnlyTarget(inst)
end)
