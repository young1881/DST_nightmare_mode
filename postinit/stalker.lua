local function ResetAbilityCooldown(inst, ability)
    local id = ability .. "_cd"
    local remaining = TUNING["STALKER_" .. string.upper(id)] -
        (inst.components.timer:GetTimeElapsed(id) or TUNING.STALKER_ABILITY_RETRY_CD)
    inst.components.timer:StopTimer(id)
    if remaining > 0 then
        inst.components.timer:StartTimer(id, remaining)
    end
end

local SHARED_COOLDOWNS =
{
    "snare",
    "spikes",
    "mindcontrol",
}

local function DelaySharedAbilityCooldown(inst, ability)
    local todelay = {}
    local maxdt = 0
    for i, v in ipairs(SHARED_COOLDOWNS) do
        if v ~= ability then
            local id = v .. "_cd"
            local remaining = inst.components.timer:GetTimeLeft(id) or 0
            maxdt = math.max(maxdt, TUNING["STALKER_" .. string.upper(id)] * .5 - remaining)
            todelay[id] = remaining
        end
    end
    for id, remaining in pairs(todelay) do
        inst.components.timer:StopTimer(id)
        inst.components.timer:StartTimer(id, remaining + maxdt)
    end
end

local function DoSpawnChanneler(inst, prefab)
    if inst.components.health:IsDead() then
        inst.channelertask = nil
        inst.channelerparams = nil
        return
    end

    local CHANNELER_SPAWN_RADIUS = 8.7
    local CHANNELER_SPAWN_PERIOD = 1

    for CHANNELER_SPAWN_RADIUS = 8.7, 0.7, -1 do
        local x = inst.channelerparams.x + CHANNELER_SPAWN_RADIUS * math.cos(inst.channelerparams.angle)
        local z = inst.channelerparams.z + CHANNELER_SPAWN_RADIUS * math.sin(inst.channelerparams.angle)

        if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) or TheWorld.Map:GetPlatformAtPoint(x, 0, z) then
            local channeler = SpawnPrefab(prefab)
            channeler.Transform:SetPosition(x, 0, z)
            channeler:ForceFacePoint(Vector3(inst.channelerparams.x, 0, inst.channelerparams.z))
            inst.components.commander:AddSoldier(channeler)
            break
        end
    end
    if inst.channelerparams.count > 1 then
        inst.channelerparams.angle = inst.channelerparams.angle + inst.channelerparams.delta
        inst.channelerparams.count = inst.channelerparams.count - 1
        inst.channelertask = inst:DoTaskInTime(CHANNELER_SPAWN_PERIOD, function() DoSpawnChanneler(inst, prefab) end)
    else
        inst.channelertask = nil
        inst.channelerparams = nil
    end
end

local function mySpawnChannelers(inst)
    ResetAbilityCooldown(inst, "channelers")

    local count = TUNING.STALKER_CHANNELERS_COUNT
    if count <= 0 or inst.channelertask ~= nil then
        return
    end

    local prefabs = { "shadowthrall_mouth", "shadowthrall_horns", "shadowdragon" }

    if not inst.spawn_channeler_index then
        inst.spawn_channeler_index = 1
    end

    local prefab = prefabs[inst.spawn_channeler_index]

    inst.spawn_channeler_index = inst.spawn_channeler_index + 1
    if inst.spawn_channeler_index > #prefabs then
        inst.spawn_channeler_index = 1
    end

    inst.spawn_channeler_count = (inst.spawn_channeler_count or 0) + 1

    local x, y, z = (inst.components.entitytracker:GetEntity("stargate") or inst).Transform:GetWorldPosition()

    inst.channelerparams =
    {
        x = x,
        z = z,
        angle = math.random() * 2 * PI,
        delta = -2 * PI / count,
        count = count,
    }

    DoSpawnChanneler(inst, prefab)

    local extraPrefabs = { "shadoweyeturret", "shadoweyeturret2" }
    local spawnDistance = 20 -- 眼球塔的距离

    for i = 1, 2 do
        local extraPrefab = extraPrefabs[i]
        local extraEntity = SpawnPrefab(extraPrefab)
        if extraEntity then
            local angle = math.random() * 2 * PI
            local offsetX = spawnDistance * math.cos(angle)
            local offsetZ = spawnDistance * math.sin(angle)
            extraEntity.Transform:SetPosition(x + offsetX, y, z + offsetZ)
        end
    end
end
AddPrefabPostInit("shadoweyeturret", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    MakePlayerOnlyTarget(inst)
end)

AddPrefabPostInit("shadoweyeturret2", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    MakePlayerOnlyTarget(inst)
end)

AddPrefabPostInit("shadowthrall_horns", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    MakePlayerOnlyTarget(inst)
end)

AddPrefabPostInit("shadowthrall_mouth", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    MakePlayerOnlyTarget(inst)
end)

AddPrefabPostInit("shadowdragon", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    MakePlayerOnlyTarget(inst)
end)
local crazy_percent = 0.5 --精神控制的阈值

local function IsCrazyGuy(guy)
    if guy ~= nil and guy.components.sanity:GetRealPercent() <= crazy_percent then
        return true
    end
    return false
end

local function IsValidMindControlTarget(inst, target, inatrium)
    if target ~= nil and target:IsValid() and target.components.sanity ~= nil then
        if inatrium or target:IsNear(inst, TUNING.STALKER_MINDCONTROL_RANGE) and target.components.sanity:GetRealPercent() <= crazy_percent then
            return true
        end
    end
    return false
end

local function HasMindControlTarget(inst)
    local insanecount = 0
    local sanecount = 0
    local inatrium = inst.atriumstalker
    for i, v in ipairs(AllPlayers) do
        if IsValidMindControlTarget(inst, v, inatrium) then
            --Use fully crazy check for initiating mind control
            --Use IsCrazyGuy check for effect to actually stick
            if v.components.sanity:GetRealPercent() <= crazy_percent then
                insanecount = insanecount + 1
            else
                sanecount = sanecount + 1
            end
        end
    end
    return insanecount >= math.ceil((insanecount + sanecount) / 3)
end

local function DoMindControl(inst)
    ResetAbilityCooldown(inst, "mindcontrol")
    local count = 0
    local inatrium = inst.atriumstalker
    for i, v in ipairs(AllPlayers) do
        if IsValidMindControlTarget(inst, v, inatrium) and IsCrazyGuy(v) then
            count = count + 1
            v:AddDebuff("mindcontroller", "mindcontroller")
        end
    end

    if count > 0 then
        DelaySharedAbilityCooldown(inst, "mindcontrol")
    end
    return count
end

AddPrefabPostInit("stalker_atrium", function(inst)
    if TheWorld.ismastersim then
        inst.IsNearAtrium = function() return true end

        inst.spawn_channeler_count = inst.spawn_channeler_count or 0

        inst.SpawnChannelers = mySpawnChannelers

        inst.HasMindControlTarget = HasMindControlTarget
        inst.MindControl = DoMindControl

        inst.components.combat:AddNoAggroTag("shadow_aligned")
        if inst.components.damagetyperesist == nil then
            inst:AddComponent("damagetyperesist")
        end
        inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0)
        inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE * 3 --掉san光环的倍数，原版-400

        local function OnBossDeath(inst, data)
            if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("player") then
                local killer = data.afflicter
                if killer.SoundEmitter ~= nil then
                    killer.SoundEmitter:PlaySound("lumos/group1/The_Spire_Slain")
                end
            end
        end

        inst:ListenForEvent("death", OnBossDeath)
    end
end)

AddPrefabPostInit("stalker_minion", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(15)
        inst.components.health.nofadeout = true
        inst.components.health.redirect = nostalkerordebrisdmg

        inst.components.combat:AddNoAggroTag("shadow_aligned")
        if inst.components.damagetyperesist == nil then
            inst:AddComponent("damagetyperesist")
        end
        inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0)
    end
end)

AddPrefabPostInit("stalker_atrium", function(inst) --只因者的大小
    inst.Transform:SetScale(1.25, 1.25, 1.25)
end)
AddPrefabPostInit("shadowthrall_mouth", function(inst) --只因者的大小
    inst.Transform:SetScale(1.25, 1.25, 1.25)
end)

-- 修复虫子被无限吃
AddStategraphPostInit("stalker_minion", function(sg)
    for i, evt in ipairs(sg.events) do
        if evt.name == "stalkerconsumed" then
            sg.events[i] = EventHandler("stalkerconsumed", function(inst)
                if not inst.sg:HasStateTag("dead") then
                    if inst:HasTag("ai_stopped") then
                        inst:RemoveTag("ai_stopped")
                        if inst.start_ai_fn then
                            inst.start_ai_fn(inst)
                        elseif inst.RestartBrain then
                            inst:RestartBrain()
                        end
                        if inst.AnimState then
                            inst.AnimState:Resume()
                            inst.AnimState:SetAddColour(0, 0, 0, 0)
                        end
                    end
                    inst.sg:GoToState("death", "eaten")
                end
            end)
            break
        end
    end


    local death = sg.states["death"]
    if death then
        local old_onenter = death.onenter
        death.onenter = function(inst, anim)
            if old_onenter then
                old_onenter(inst, anim)
            end
            inst:DoTaskInTime(0.5, function()
                if inst:IsValid() then
                    inst:Remove()
                end
            end)
        end
    end
end)

local function AddStartAIFn(inst)
    if not TheWorld.ismastersim then return end

    inst.start_ai_fn = function(monster)
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
        monster:RemoveEventCallback("death", inst.start_ai_fn)
    end
end

AddPrefabPostInit("stalker_minion", AddStartAIFn)
AddPrefabPostInit("stalker_minion1", AddStartAIFn)
AddPrefabPostInit("stalker_minion2", AddStartAIFn)
