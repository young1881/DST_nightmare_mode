local buff_time = 90

local function taser_cooldown(inst)
    inst._cdtask = nil
end

local function taser_apply_damage(attacker, wx, damage_mult, interval, count)
    if count <= 0 or attacker == nil or not attacker:IsValid() then
        return
    end

    SpawnPrefab("electrichitsparks"):AlignToTarget(attacker, wx, true)
    local base_damage = damage_mult * TUNING.WX78_TASERDAMAGE
    local planar_damage = 10
    local spdamage = { planar = planar_damage }

    attacker.components.combat:GetAttacked(wx, base_damage, nil, "electric", spdamage)
    attacker:DoTaskInTime(interval, function()
        taser_apply_damage(attacker, wx, damage_mult, interval, count - 1)
    end)
end

local excluded_tags = { "ai_stopped", "epic", "player", "abigail", "companion", "INLIMBO", "structure",
    "butterfly", "wall", "balloon", "groundspike", "stalkerminion",
    "smashable" }

local function taser_onblockedorattacked(wx, data, inst)
    if data and data.attacker and not data.redirected and inst._cdtask == nil then
        inst._cdtask = inst:DoTaskInTime(0.3, taser_cooldown)
        local x, y, z = wx.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 10, { "_combat", "_health" }, excluded_tags)

        for _, attacker in ipairs(ents) do
            if attacker ~= wx and
                attacker:IsValid() and
                attacker.components.health and not attacker.components.health:IsDead() and
                (not attacker.components.inventory or not attacker.components.inventory:IsInsulated()) and
                wx.components.combat:CanTarget(attacker) then
                local rand = math.random()
                if rand < 0.75 then
                    local damage_mult = attacker:HasTag("electricdamageimmune") and 1 or TUNING.ELECTRIC_DAMAGE_MULT
                    local wetness_mult = attacker.components.moisture and
                        attacker.components.moisture:GetMoisturePercent() or
                        (attacker:GetIsWet() and 1 or 0)
                    damage_mult = damage_mult + wetness_mult

                    taser_apply_damage(attacker, wx, damage_mult, 1, 3)
                else
                    if attacker.components.freezable then
                        attacker.components.freezable:AddColdness(4)
                        attacker.components.freezable:SpawnShatterFX()
                    end

                    if not attacker:HasTag("taser_slowed") and not attacker:HasTag("epic") then
                        attacker:AddTag("taser_slowed")
                        if attacker.components.locomotor then
                            attacker.components.locomotor:SetExternalSpeedMultiplier(inst, "taser_slow", 0.5)
                        end
                    end
                end
            end
        end
    end
end




local function OnAttached(inst, target)
    if target:HasTag("electricdamageimmune") then
        target:RemoveTag("electricdamageimmune")
    end
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_WX78_ELECTRICATTACK", priority = 2 })


    if target.components.electricattacks == nil then
        target:AddComponent("electricattacks")
    end
    target.components.electricattacks:AddSource(inst)


    inst._onblocked = function(owner, data) taser_onblockedorattacked(owner, data, inst) end
    inst:ListenForEvent("blocked", inst._onblocked, target)
    inst:ListenForEvent("attacked", inst._onblocked, target)

    SpawnPrefab("electricchargedfx"):SetTarget(target)
end

local function OnDetached(inst, target)
    target:AddTag("electricdamageimmune")
    if target.components.electricattacks then
        target.components.electricattacks:RemoveSource(inst)
    end

    if inst._onblocked then
        inst:RemoveEventCallback("blocked", inst._onblocked, target)
        inst:RemoveEventCallback("attacked", inst._onblocked, target)
        inst._onblocked = nil
    end

    if target._lastShield then
        target._lastShield:Remove()
        target._lastShield = nil
    end

    target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_WX78_ELECTRICATTACK", priority = 2 })
    inst:Remove()
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", buff_time)
    target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_WX78_ELECTRICATTACK", priority = 2 })
    SpawnPrefab("electricchargedfx"):SetTarget(target)
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end




local function fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.entity:AddTransform()
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("buffover", buff_time)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

STRINGS.CHARACTERS.GENERIC.ANNOUNCE_ATTACH_BUFF_WX78_ELECTRICATTACK = "静电释放，启动！"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_DETACH_BUFF_WX78_ELECTRICATTACK = "静电释放已结束"

return Prefab("wx78_electricattack", fn, nil, { "electrichitsparks", "electricchargedfx" })
