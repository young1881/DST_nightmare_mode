local assets = {
    Asset("ANIM", "anim/pocketwatch_cherrift.zip"),
    Asset("ATLAS", "images/inventoryimages/pocketwatch_cherrift.xml"),
    Asset("IMAGE", "images/inventoryimages/pocketwatch_cherrift.tex"),
}

STRINGS.NAMES.POCKETWATCH_CHERRIFT = "时停表"
STRINGS.RECIPE_DESC.POCKETWATCH_CHERRIFT = "将其他生物的时间转移到自己的年龄上"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCH_CHERRIFT = "一个能够暂停时间的强大魔法，但是也会给施术者很大副作用"
STRINGS.CHARACTERS.WANDA.DESCRIBE.POCKETWATCH_CHERRIFT = "本该由其他生物流逝的时间可能会由我来承担"

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
    "shadow_pillar",
    "shadow_pillar_base_fx",
    "reticuleaoeshadowtarget_6",
    "roge_cherrift_shockwave",
}

local shockwave_assets =
{
    Asset("ANIM", "anim/mushroombomb_base.zip"),
}

local PocketWatchCommon = require("prefabs/pocketwatch_common")

local TIMESTOP_DURATION = 12
local TIMESTOP_IMMUNITY_DURATION = 15
local TIMESTOP_FX_RADIUS = 10
local SHADOW_TRAP_VISUAL_RADIUS = 6
local TIMESTOP_FX_RING_SCALE = TIMESTOP_FX_RADIUS / SHADOW_TRAP_VISUAL_RADIUS
local TIMESTOP_FX_SHOCKWAVE_SCALE = 1.9 * TIMESTOP_FX_RING_SCALE
local TIMESTOP_FX_PILLAR_SPACING = 1.4

local excluded_tags = { "ai_stopped", "player", "abigail", "companion", "INLIMBO", "structure",
    "butterfly", "wall", "balloon", "groundspike", "stalkerminion", "lightflier",
    "smashable" }

local function GetTimestopDuration(entity)
    if entity ~= nil and entity:IsValid() and entity:HasTag("epic") then
        return TIMESTOP_DURATION / 3
    end
    return TIMESTOP_DURATION
end

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

    monster._roge_cherrift_timestop_end = nil
    monster._roge_cherrift_timestop_task = nil
    monster._roge_cherrift_timestop_immunity_until = GetTime() + TIMESTOP_IMMUNITY_DURATION
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

local function RogeIsValidTimestopFxPoint(map, x, z)
    return map:IsPassableAtPoint(x, 0, z, false)
        and map:IsVisualGroundAtPoint(x, 0, z)
        and not map:IsOceanAtPoint(x, 0, z, false)
end

local function RogeRemoveTimestopFx(fx)
    if fx == nil or not fx:IsValid() then
        return
    end
    if fx.KillFX ~= nil then
        fx:KillFX()
    else
        fx:Remove()
    end
end

local function RogeConfigureTimestopPillar(pillar, duration)
    pillar:DoTaskInTime(1.5, function()
        if not pillar:IsValid() or pillar.components.timer == nil then
            return
        end
        if pillar.components.timer:TimerExists("lifetime") then
            pillar.components.timer:SetTimeLeft("lifetime", math.max(0.5, duration - 1.5))
        end
        pillar.components.timer:StopTimer("warningtime")
    end)
end

local function RogeSpawnTimestopCageRing(map, cx, cz, radius, duration, fx_list)
    local num = math.max(8, math.floor(PI2 * radius / TIMESTOP_FX_PILLAR_SPACING + 0.5))
    local theta = math.random() * PI2
    local delta = PI2 / num
    local delays = {}
    for i = 1, num do
        table.insert(delays, (i - 1) / num * 0.8)
    end
    for i = 1, num do
        local x = cx + math.cos(theta) * radius
        local z = cz - math.sin(theta) * radius
        theta = theta + delta
        if RogeIsValidTimestopFxPoint(map, x, z) then
            local pillar = SpawnPrefab("shadow_pillar")
            if pillar ~= nil then
                pillar.Transform:SetPosition(x, 0, z)
                pillar:SetDelay(table.remove(delays, math.random(#delays)))
                RogeConfigureTimestopPillar(pillar, duration)
                table.insert(fx_list, pillar)
            end
        end
    end
end

local function RogeSpawnTimestopTrapRing(cx, cz, fx_list)
    local ring = SpawnPrefab("reticuleaoeshadowtarget_6")
    if ring ~= nil then
        ring.Transform:SetPosition(cx, 0, cz)
        ring.AnimState:SetScale(TIMESTOP_FX_RING_SCALE, TIMESTOP_FX_RING_SCALE, TIMESTOP_FX_RING_SCALE)
        table.insert(fx_list, ring)
    end
end

local function RogeSpawnTimestopShockwave(cx, cz, fx_list)
    local shock = SpawnPrefab("roge_cherrift_shockwave")
    if shock ~= nil then
        shock.Transform:SetPosition(cx, 0, cz)
        shock.AnimState:SetScale(TIMESTOP_FX_SHOCKWAVE_SCALE, TIMESTOP_FX_SHOCKWAVE_SCALE, TIMESTOP_FX_SHOCKWAVE_SCALE)
        table.insert(fx_list, shock)
    end
end

local function RogeSpawnTimestopCenterPool(cx, cz, fx_list)
    local pool = SpawnPrefab("shadow_pillar_base_fx")
    if pool ~= nil then
        local scale = TIMESTOP_FX_RING_SCALE * 0.7
        pool.Transform:SetPosition(cx, 0, cz)
        pool.Transform:SetScale(scale, scale, scale)
        pool.Transform:SetRotation(math.random() * 360)
        table.insert(fx_list, pool)
    end
end

local function RogeStopTimestopFieldFx(inst)
    if inst._roge_cherrift_fx ~= nil then
        for _, fx in ipairs(inst._roge_cherrift_fx) do
            RogeRemoveTimestopFx(fx)
        end
        inst._roge_cherrift_fx = nil
    end
end

local function RogeStartTimestopFieldFx(inst, cx, cy, cz, duration)
    RogeStopTimestopFieldFx(inst)

    local map = TheWorld.Map
    inst._roge_cherrift_fx = {}

    RogeSpawnTimestopShockwave(cx, cz, inst._roge_cherrift_fx)
    RogeSpawnTimestopTrapRing(cx, cz, inst._roge_cherrift_fx)
    RogeSpawnTimestopCenterPool(cx, cz, inst._roge_cherrift_fx)
    RogeSpawnTimestopCageRing(map, cx, cz, TIMESTOP_FX_RADIUS, duration, inst._roge_cherrift_fx)

    inst:DoTaskInTime(duration, function()
        RogeStopTimestopFieldFx(inst)
    end)
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

    local radius = TIMESTOP_FX_RADIUS
    local duration = TIMESTOP_DURATION
    local interval = 0.1

    local x, y, z = doer.Transform:GetWorldPosition()

    RogeStartTimestopFieldFx(inst, x, y, z, duration)
    if doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("maxwell_rework/shadow_pillar/pre")
        doer.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
    end

    local function ApplyTimestop(entity)
        local now = GetTime()
        if entity._roge_cherrift_timestop_immunity_until ~= nil and now < entity._roge_cherrift_timestop_immunity_until then
            return
        end
        local ent_duration = GetTimestopDuration(entity)
        if entity._roge_cherrift_timestop_end ~= nil and now < entity._roge_cherrift_timestop_end then
            stop_ai(entity)
            return
        end
        if entity._roge_cherrift_timestop_task ~= nil then
            entity._roge_cherrift_timestop_task:Cancel()
            entity._roge_cherrift_timestop_task = nil
        end
        entity._roge_cherrift_timestop_end = now + ent_duration
        stop_ai(entity)
        entity:AddTag("ai_stopped")
        entity._roge_cherrift_timestop_task = entity:DoTaskInTime(ent_duration, function()
            entity._roge_cherrift_timestop_task = nil
            if entity:IsValid() then
                start_ai(entity)
                entity:RemoveTag("ai_stopped")
            end
        end)
    end

    local function StopAIInArea()
        if doer == nil or not doer:IsValid() then return end

        local entities = TheSim:FindEntities(x, y, z, radius, { "_combat", "_health" }, { "playerghost", "INLIMBO" })
        for _, entity in ipairs(entities) do
            if entity ~= doer and not HasExcludedTags(entity) then
                ApplyTimestop(entity)
            end
        end
    end

    for i = 0, duration / interval do
        inst:DoTaskInTime(i * interval, StopAIInArea)
    end
    return true
end

local MOUNTED_CAST_TAGS = { "pocketwatch_mountedcast" }

local function healfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch", "pocketwatch_cherrift", DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.castfxcolour = { 255 / 255, 241 / 255, 236 / 255 }

    inst.components.inventoryitem.imagename = "pocketwatch_cherrift"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_cherrift.xml"

    inst:ListenForEvent("onremove", function()
        RogeStopTimestopFieldFx(inst)
    end)

    return inst
end

local function shockwave_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("mushroombomb_base")
    inst.AnimState:SetBuild("mushroombomb_base")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetMultColour(0, 0, 0, 0.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

-------------------------------------------------------------------------------
-- 裂缝表地面裂隙（与 pocketwatch_cherrift 同文件注册，避免独立 prefab 加载失败）

local portal_rift_assets =
{
    Asset("ANIM", "anim/pocketwatch_portal_fx.zip"),
}

local portal_rift_prefabs =
{
    "pocketwatch_portal_entrance_overlay",
    "pocketwatch_portal_entrance_underlay",
    "pocketwatch_portal_exit",
    "pocketwatch_portal_exit_fx",
}

local PORTAL_RIFT_RADIUS = 5
local PORTAL_RIFT_VISUAL_SCALE = 2.4
local PORTAL_RIFT_OPEN_DURATION = 10
local PORTAL_RIFT_PULL_DELAY = 0.75
local PORTAL_RIFT_PULL_INTERVAL = 0.2
local PORTAL_RIFT_MAX_LIGHT_FRAME = 14

local function RogePortalOnUpdateLight(inst, dframes)
    local done
    if inst._islighton:value() then
        local frame = inst._lightframe:value() + dframes * (inst.lightupdaterate or 1)
        done = frame >= PORTAL_RIFT_MAX_LIGHT_FRAME
        inst._lightframe:set_local(done and PORTAL_RIFT_MAX_LIGHT_FRAME or frame)
    else
        local frame = inst._lightframe:value() - dframes * 3
        done = frame <= 0
        inst._lightframe:set_local(done and 0 or frame)
    end

    inst.Light:SetRadius(2.5 * inst._lightframe:value() / PORTAL_RIFT_MAX_LIGHT_FRAME * PORTAL_RIFT_VISUAL_SCALE)

    if done then
        inst._lighttask:Cancel()
        inst._lighttask = nil
    end
end

local function RogePortalOnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, RogePortalOnUpdateLight, nil, 1)
    end
    RogePortalOnUpdateLight(inst, 0)
end

local function RogePortalCloseExit(inst)
    if not inst.components.teleporter:IsBusy() then
        inst:Remove()
    elseif not inst.queued_close then
        inst.queued_close = true
        inst:ListenForEvent("doneteleporting", RogePortalCloseExit)
    end
end

local function RogePortalCloseRift(inst)
    if inst._roge_pull_task ~= nil then
        inst._roge_pull_task:Cancel()
        inst._roge_pull_task = nil
    end

    if inst.components.teleporter:GetTarget() ~= nil then
        local exit = inst.components.teleporter.targetTeleporter
        inst.components.teleporter:Target(nil)
        RogePortalCloseExit(exit)
    elseif inst.components.teleporter.migration_data ~= nil then
        inst.components.teleporter:MigrationTarget(nil)
    end

    inst._islighton:set(false)
    RogePortalOnLightDirty(inst)

    inst.AnimState:PlayAnimation("portal_entrance_pst")
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pst")

    if inst.overlay ~= nil and inst.overlay:IsValid() then
        inst.overlay.AnimState:PlayAnimation("portal_entrance_pst")
    end
    if inst.underlay ~= nil and inst.underlay:IsValid() then
        inst.underlay.AnimState:PlayAnimation("portal_entrance_pst")
    end

    inst.persists = false
    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 1, inst.Remove)
end

local function RogePortalOnRiftTimerDone(inst, data)
    if data == nil then
        return
    end
    if data.name == "closeportal" then
        RogePortalCloseRift(inst)
    elseif data.name == "start_loop_sfx" then
        if inst.components.teleporter.targetTeleporter ~= nil or inst.components.teleporter.migration_data ~= nil then
            inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/portal_LP", "loop")
        end
    elseif data.name == "turn_on_light" then
        inst._islighton:set(true)
        RogePortalOnLightDirty(inst)
    end
end

local function RogePortalOnRiftActivate(inst, doer)
    if doer.components.talker ~= nil then
        doer.components.talker:ShutUp()
    end

    if doer.components.sanity ~= nil and not (doer:HasTag("pocketwatchcaster") or doer:HasTag("nowormholesanityloss")) then
        doer.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
    end
end

local function RogePortalIsRiftCaster(rift, player)
    if rift._roge_caster ~= nil and player == rift._roge_caster then
        return true
    end
    if rift._roge_caster_userid ~= nil and player.userid == rift._roge_caster_userid then
        return true
    end
    return false
end

local function RogePortalSetRiftCaster(rift, doer)
    rift._roge_caster = doer
    rift._roge_caster_userid = doer ~= nil and doer.userid or nil
end

local function RogePortalGetPullImmunity()
    return rawget(_G, "ROGE_PORTAL_PULL_IMMUNITY")
end

local function RogePortalIsPlayerFrozen(player)
    if player.components.freezable ~= nil and player.components.freezable:IsFrozen() then
        return true
    end
    if player.sg ~= nil then
        if player.sg:HasStateTag("frozen") then
            return true
        end
        local state = player.sg.currentstate ~= nil and player.sg.currentstate.name or nil
        if state == "frozen" then
            return true
        end
    end
    return false
end

local function RogePortalCanPullPlayer(rift, player)
    if player == nil or not player:IsValid() or player:HasTag("playerghost") then
        return false
    end
    if RogePortalIsRiftCaster(rift, player) then
        return false
    end
    if RogePortalIsPlayerFrozen(player) then
        return false
    end
    if player.sg == nil then
        return false
    end
    local teleporter = rift.components.teleporter
    if teleporter == nil or not teleporter:IsActive() or teleporter.teleportees[player] then
        return false
    end
    if player.sg:HasStateTag("jumping") then
        return false
    end
    local state = player.sg.currentstate.name
    if state == "jumpin" or state == "jumpin_pre" or state == "pocketwatch_portal_land" or state == "pocketwatch_portal_fallout" then
        return false
    end
    local px, _, pz = player.Transform:GetWorldPosition()
    local rx, _, rz = rift.Transform:GetWorldPosition()
    return distsq(px, pz, rx, rz) <= PORTAL_RIFT_RADIUS * PORTAL_RIFT_RADIUS
end

local function RogePortalTryPullPlayerIntoRift(rift, player)
    if not RogePortalCanPullPlayer(rift, player) then
        return
    end
    if player.components.sleeper ~= nil and player.components.sleeper:IsAsleep() then
        player.components.sleeper:WakeUp()
    end
    if player.sleepingbag ~= nil and player.sleepingbag:IsValid() then
        player.sleepingbag.components.sleepingbag:DoWakeUp(true)
        player.sleepingbag = nil
    end
    local immunity = RogePortalGetPullImmunity()
    if immunity ~= nil then
        immunity.BeginPullImmunity(player, rift)
    end
    player.sg:GoToState("jumpin", { teleporter = rift })
    if immunity ~= nil then
        player:DoTaskInTime(0, immunity.RefreshImmunityTags, player)
    end
end

local function RogePortalPullPlayersInRift(rift)
    if not rift:IsValid() or rift.components.teleporter == nil or not rift.components.teleporter:IsActive() then
        return
    end
    local x, y, z = rift.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x, y, z, PORTAL_RIFT_RADIUS, { "player" }, { "playerghost", "INLIMBO" })
    for _, player in ipairs(players) do
        RogePortalTryPullPlayerIntoRift(rift, player)
    end
end

local function RogePortalLinkExit(inst, exit)
    inst.components.teleporter:Target(exit)

    inst:ListenForEvent("onremove", function()
        if inst:IsValid() then
            inst.components.teleporter:Target(nil)
        end
    end, exit)

    exit:ListenForEvent("onremove", function()
        if inst:IsValid() then
            RogePortalCloseRift(inst)
        end
    end, inst)
end

local function RogePortalSetupMigrationDestination(inst, worldid, x, y, z)
    inst.components.teleporter:MigrationTarget(worldid, x, y, z)
end

local function RogePortalSetupExitDestination(inst, x, y, z)
    local exit = SpawnPrefab("pocketwatch_portal_exit")
    exit.Transform:SetPosition(x, y, z)
    RogePortalLinkExit(inst, exit)
end

local function RogePortalStartPullingPlayers(inst)
    inst:DoTaskInTime(PORTAL_RIFT_PULL_DELAY, function()
        if inst:IsValid() then
            inst._roge_pull_task = inst:DoPeriodicTask(PORTAL_RIFT_PULL_INTERVAL, RogePortalPullPlayersInRift, 0, inst)
            RogePortalPullPlayersInRift(inst)
        end
    end)
end

local function roge_portal_rift_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(PORTAL_RIFT_VISUAL_SCALE, PORTAL_RIFT_VISUAL_SCALE, PORTAL_RIFT_VISUAL_SCALE)

    inst.AnimState:SetBank("pocketwatch_portal_fx")
    inst.AnimState:SetBuild("pocketwatch_portal_fx")
    inst.AnimState:PlayAnimation("portal_entrance_pre")
    inst.AnimState:PushAnimation("portal_entrance_loop", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSortOrder(-1)
    inst.AnimState:Hide("front")
    inst.AnimState:Hide("water_shadow")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(0.6)
    inst.Light:SetFalloff(1.5)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst:AddTag("scarytoprey")
    inst:AddTag("ignorewalkableplatforms")

    inst:SetPhysicsRadiusOverride(PORTAL_RIFT_RADIUS)

    inst._lightframe = net_smallbyte(inst.GUID, "roge_portal_rift._lightframe", "lightdirty")
    inst._islighton = net_bool(inst.GUID, "roge_portal_rift._islighton", "lightdirty")
    inst._lighttask = nil
    inst._islighton:set(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", RogePortalOnLightDirty)
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("closeportal", PORTAL_RIFT_OPEN_DURATION)
    inst:ListenForEvent("timerdone", RogePortalOnRiftTimerDone)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = RogePortalOnRiftActivate
    inst.components.teleporter.offset = 0
    inst.components.teleporter.jumpinanim = "jumpportal"

    inst.components.timer:StartTimer("start_loop_sfx", 25 * FRAMES)
    inst.components.timer:StartTimer("turn_on_light", 10 * FRAMES)

    inst.SetupExitDestination = RogePortalSetupExitDestination
    inst.SetupMigrationDestination = RogePortalSetupMigrationDestination
    inst.StartPullingPlayers = RogePortalStartPullingPlayers
    inst.SetRiftCaster = RogePortalSetRiftCaster

    inst.overlay = SpawnPrefab("pocketwatch_portal_entrance_overlay")
    inst.overlay.entity:SetParent(inst.entity)
    inst.highlightchildren = { inst.overlay }

    inst.underlay = SpawnPrefab("pocketwatch_portal_entrance_underlay")
    inst.underlay.entity:SetParent(inst.entity)

    inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")

    inst.persists = false

    return inst
end

return Prefab("pocketwatch_cherrift", healfn, assets, prefabs),
    Prefab("roge_cherrift_shockwave", shockwave_fn, shockwave_assets),
    Prefab("roge_portal_rift", roge_portal_rift_fn, portal_rift_assets, portal_rift_prefabs)
