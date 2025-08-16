local RuinsRespawner = require "prefabs/ruinsrespawner"
local brain = require("brains/ancient_hulkbrain")

--local easing=require("easing")


local assets =
{
    Asset("ANIM", "anim/metal_hulk_build.zip"),
    Asset("ANIM", "anim/metal_hulk_basic.zip"),
    Asset("ANIM", "anim/metal_hulk_attacks.zip"),
    Asset("ANIM", "anim/metal_hulk_actions.zip"),
    Asset("ANIM", "anim/metal_hulk_barrier.zip"),
    Asset("ANIM", "anim/metal_hulk_explode.zip"),
    Asset("ANIM", "anim/metal_hulk_bomb.zip"),
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),

    Asset("ANIM", "anim/laser_explode_sm.zip"),
    Asset("ANIM", "anim/smoke_aoe.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),
    Asset("ANIM", "anim/ground_chunks_breaking_brown.zip"),
}

local prefabs =
{
    "deerclops_laserhit",
    "deerclops_laserscorch",
    "groundpound_fx",
    "groundpoundring_fx",
    "ancient_hulk_mine",
    "ancient_hulk_orb"
}

SetSharedLootTable('ancient_hulk',
    {
        { 'coin_1',        1.0 },
        { 'coin_1',        1.0 },
        { "armorskeleton", 1.0 },
        { "shadowheart",   1.0 },
    })



local PHASES =
{

    --
    [1] = {
        hp = 0.7,
        fn = function(inst)
            inst.angry = true

            inst.cancharge = false
            inst.canbarrier = false
        end,
    },
    [2] = {
        hp = 0.4,
        fn = function(inst)
            inst.angry = true
            inst.cancharge = true
            inst.canbarrier = true
        end,
    },
}

local INTENSITY = .75
local function SetLightValue(inst, val1, val2, time)
    inst.components.fader:StopAll()
    if val1 and val2 and time then
        inst.Light:Enable(true)
        inst.components.fader:Fade(val1, val2, time, function(v) inst.Light:SetIntensity(v) end)
        --[[
        if inst.Light ~= nil then
            inst.Light:Enable(true)
            inst.Light:SetIntensity(.6 * val)
            inst.Light:SetRadius(5 * val)
            inst.Light:SetFalloff(3 * val)
        end
        ]]
    else
        inst.Light:Enable(false)
    end
end


local function ApplyDamageToEnt(inst, v, targets)
    local isworkable = false
    if v.components.workable ~= nil then
        local work_action = v.components.workable:GetWorkAction()
        --V2C: nil action for NPC_workable (e.g. campfires)
        isworkable =
            (work_action == nil and v:HasTag("NPC_workable")) or
            (v.components.workable:CanBeWorked() and
                (work_action == ACTIONS.CHOP or
                    work_action == ACTIONS.HAMMER or
                    work_action == ACTIONS.MINE or
                    (work_action == ACTIONS.DIG and
                        v.components.spawner == nil and
                        v.components.childspawner == nil
                    )
                )
            )
    end
    if isworkable then
        targets[v] = true
        v.components.workable:Destroy(inst.caster and inst.caster:IsValid() and inst.caster or inst)

        -- Completely uproot trees.
        if v:HasTag("stump") then
            v:Remove()
        end
    elseif v.components.pickable ~= nil
        and v.components.pickable:CanBePicked()
        and not v:HasTag("intense") then
        targets[v] = true
        v.components.pickable:Pick(inst)
    elseif v.components.combat == nil and v.components.health ~= nil then
        targets[v] = true
    elseif inst.components.combat:CanTarget(v) then
        targets[v] = true
        inst.components.combat:DoAttack(v)

        SpawnPrefab("deerclops_laserhit"):SetTarget(v)
        if not v.components.health:IsDead() then
            if v.components.temperature ~= nil then
                local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                local curtemp = v.components.temperature:GetCurrent()
                if maxtemp > curtemp then
                    v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                end
            end
            if v.components.fueled == nil and
                v.components.burnable ~= nil and not v.components.burnable:IsBurning() then
                v.components.burnable:Ignite()
            end
        end
    end
end

local DAMAGE_CANT_TAGS = { "laser_immune", "playerghost", "INLIMBO", "DECOR", "FX" }
local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable",
    "DIG_workable" }

local function DoDamage(inst, rad, startang, endang)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()

    inst.components.combat.ignorehitrange = true

    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad + 3, nil, DAMAGE_CANT_TAGS, DAMAGE_ONEOF_TAGS)) do
        if not targets[v] and v:IsValid() and
            not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = rad + v:GetPhysicsRadius(.5)
            local dsq_to_laser = v:GetDistanceSqToPoint(x, y, z)
            if dsq_to_laser < range * range then
                local dir = inst:GetAngleToPoint(v.Transform:GetWorldPosition()) + 180

                if not (startang and endang and (dir < startang or dir > endang)) then
                    ApplyDamageToEnt(inst, v, targets)
                end
            end
        end
    end
    inst.components.combat.ignorehitrange = false
end



local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "chess", "INLIMBO", "FX", "playerghost" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }

local function RetargetFn(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return not (homePos ~= nil and
            inst:GetDistanceSqToPoint(homePos:Get()) >= 1600)
        and FindEntity(
            inst,
            28,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS
        )
        or nil
end

local function KeepTargetFn(inst, target)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return inst.components.combat:CanTarget(target) and
        not (homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) > 1600)
end



local function onload(inst)
    local healthpct = inst.components.health:GetPercent()
    for i = #PHASES, 1, -1 do
        local v = PHASES[i]
        if healthpct <= v.hp then
            v.fn(inst)
            break
        end
    end
end

local function OnAttacked(inst, data)
    if data.attacker then
        inst.components.combat:SetTarget(data.attacker)
        if data.attacker:HasTag("player") then
            inst.attackerUSERIDs[data.attacker.userid] = true
        end
    end
end

local function OnCollide(inst, other)
    if other ~= nil and other:IsValid() then
        if other:HasTag("smashable") and other.components.health ~= nil then
            other.components.health:Kill()
        elseif other.components.workable ~= nil
            and other.components.workable:CanBeWorked()
            and other.components.workable.action ~= ACTIONS.NET then
            SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
            other.components.workable:Destroy(inst)
        elseif other.components.combat ~= nil
            and other.components.health ~= nil and not other.components.health:IsDead()
            and (other:HasTag("wall") or other:HasTag("structure") or other.components.locomotor == nil) then
            other.components.health:Kill()
        end
    end
end

local function LaunchProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("ancient_hulk_mine")
    projectile.Transform:SetPosition(x, 0, z)
    --projectile.components
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end


local function ShootProjectile(inst, targetpos)
    local projectile = SpawnPrefab("ancient_hulk_orb")
    projectile.Transform:SetPosition(inst.AnimState:GetSymbolPosition("hand01"))
    --projectile.Physics:Teleport(x,4,z)
    projectile.components.complexprojectile:Launch(targetpos, inst)
    --projectile.owner = inst
end

local function spawnbarrier(inst)
    local angle = 0
    local radius = 10
    local number = 8
    local pt = inst:GetPosition()
    for i = 1, number do
        local offset = Vector3(radius * math.cos(angle), 0, -radius * math.sin(angle))
        local newpt = pt + offset
        --local tile = GetWorld().Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)
        local ground = TheWorld.Map
        if ground:IsPassableAtPoint(newpt.x, 0, newpt.z) then
            inst:DoTaskInTime(0.3, function()
                local spell = SpawnPrefab("deer_fire_circle")
                if spell.TriggerFX then spell:DoTaskInTime(2, spell.TriggerFX) end
                spell.Transform:SetPosition(newpt.x, 0, newpt.z)
                spell:DoTaskInTime(15, spell.KillFX)
            end)
        end
        angle = angle + (PI * 2 / number)
    end
end


local function EnterShield(inst)
    inst._is_shielding = true

    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0, "ruins_shield")
    inst.components.planardefense:SetBaseDefense(15)
    inst.components.debuffable:RemoveOnDespawn()
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
    end

    inst._shieldfx = SpawnPrefab("forcefieldfx")
    inst._shieldfx.Transform:SetScale(1.8, 1.8, 1.8)
    inst._shieldfx.entity:SetParent(inst.entity)
    inst._shieldfx.Transform:SetPosition(0, 0.5, 0)
end

local function ExitShield(inst)
    inst._is_shielding = nil
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
        inst._shieldfx = nil
    end
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1, "ruins_shield")
    inst.components.planardefense:SetBaseDefense(0)
end


local function rememberhome(inst)
    if inst.components.knownlocations:GetLocation("home") == nil then
        inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    end
end

local function OnTimerDone(inst, data)
    if data.name == "lob_cd" then
        inst.lob_count = 5
        inst.components.combat.attackrange = 18
    end
end



local function OnNewTarget(inst, data)
    if data.target ~= nil then
        inst:SetEngaged(true)
    end
end

local function SetEngaged(inst, engaged)
    --NOTE: inst.engaged is nil at instantiation, and engaged must not be nil
    if inst.engaged ~= engaged then
        inst.engaged = engaged
        if engaged then
            inst.components.health:StopRegen()
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        else
            inst.components.health:StartRegen(30, 1)
            inst:ListenForEvent("newcombattarget", OnNewTarget)
        end
    end
end

local function PushMusic(inst)
    if ThePlayer == nil or not inst:HasTag("epic") then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 40 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", { name = "ancient_hulk" })
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 50) then
        inst._playingmusic = false
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    inst.DynamicShadow:SetSize(6, 3.5)

    MakeGiantCharacterPhysics(inst, 3000, 2)

    inst.AnimState:SetBank("metal_hulk")
    inst.AnimState:SetBuild("metal_hulk_build")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:AddOverrideBuild("laser_explode_sm")
    inst.AnimState:AddOverrideBuild("smoke_aoe")
    inst.AnimState:AddOverrideBuild("laser_explosion")
    inst.AnimState:AddOverrideBuild("ground_chunks_breaking")
    --inst.Transform:SetScale(1.2,1.2,1.2)


    inst:AddComponent("fader")

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("shadow_aligned")
    inst:AddTag("largecreature")
    inst:AddTag("ancient_hulk")
    inst:AddTag("laser_immune")
    inst:AddTag("mech")

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst.PushMusic = PushMusic

        inst._playingmusic = false
        inst:DoPeriodicTask(1, inst.PushMusic, 0)
    end

    if not TheWorld.ismastersim then
        return inst
    end


    inst.Physics:SetCollisionCallback(OnCollide)
    ----------------------------------------
    inst.angry = false
    inst.cancharge = false
    inst.canbarrier = false
    inst.lob_count = 4

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    ------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(12500)
    inst.components.health.destroytime = 5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(200)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(18, 6)
    inst.components.combat:SetAreaDamage(5, 0.8)
    inst.components.combat.hiteffectsymbol = "segment01"
    inst.components.combat:SetAttackPeriod(2.6)
    inst.components.combat:SetRetargetFunction(0.5, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    ----------------------
    inst:AddComponent("timer")

    inst:AddComponent("knownlocations")

    inst:AddComponent("drownable")

    inst:AddComponent("healthtrigger")
    for i, v in pairs(PHASES) do
        inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
    end

    -----------------

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(20)


    local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 1000
    stunnable.stun_period = 5
    stunnable.stun_duration = 8
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 4

    --[[inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("laser_spark")
    inst.components.periodicspawner:SetRandomTimes(6, 8)
    inst.components.periodicspawner:SetDensityInRange(10, 4)
	inst.components.periodicspawner:SetSpawnTestFn(CanSpark)
    inst.components.periodicspawner:SetOnSpawnFn(SparkOnSpawned)
    inst.components.periodicspawner:Start()]]


    inst._shieldfx = nil
    inst._is_shielding = nil
    inst.EnterShield = EnterShield
    inst.ExitShield = ExitShield
    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ancient_hulk")
    ------------------------------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("planardefense")

    ------------------------------------------

    local groundpounder = inst:AddComponent("groundpounder")
    groundpounder:UseRingMode()
    groundpounder.numRings = 3
    groundpounder.initialRadius = 1.5
    groundpounder.radiusStepDistance = 2
    groundpounder.ringWidth = 2
    groundpounder.damageRings = 2
    groundpounder.destructionRings = 3
    groundpounder.platformPushingRings = 3

    ------------------------------------------

    inst.OnLoad = onload
    inst.LaunchProjectile = LaunchProjectile
    inst.ShootProjectile = ShootProjectile
    inst.DoDamage = DoDamage
    inst.spawnbarrier = spawnbarrier
    inst.SetLightValue = SetLightValue
    inst.SetEngaged = SetEngaged

    inst.attackerUSERIDs = {}

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("timerdone", OnTimerDone)
    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 7

    inst:AddComponent("debuffable")

    inst:SetStateGraph("SGancient_hulk")
    inst:SetBrain(brain)
    inst:DoTaskInTime(0, rememberhome)

    SetEngaged(inst, false)


    return inst
end



local function MineOnHit(inst)
    inst.AnimState:PlayAnimation("land")
    inst.AnimState:PushAnimation("open", false)

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step_wires")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust")
    inst:ListenForEvent("animqueueover", function()
        inst.components.mine:Reset()
        inst.AnimState:PlayAnimation("green_loop", true)
    end)
end

local function minetrigger(inst)
    inst.SoundEmitter:KillSound("boom_loop")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")

    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Hide()

    SpawnPrefab("laser_ring").Transform:SetPosition(x, y, z)
    SpawnPrefab("laser_explosion").Transform:SetPosition(x, y, z)
    inst:DoTaskInTime(0.4, function()
        inst:DoDamage(5)
        inst:Remove()
    end)
end

local function onnearmine(inst)
    inst.AnimState:PlayAnimation("red_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/active_LP", "boom_loop")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
    inst:DoTaskInTime(0.5, minetrigger)
end

local function minefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 75, 0.5)


    inst.AnimState:SetBank("metal_hulk_mine")
    inst.AnimState:SetBuild("metal_hulk_bomb")
    inst.AnimState:PlayAnimation("green_loop", true)

    inst:AddTag("NOCLICK")

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(50)
    inst.components.complexprojectile:SetGravity(20)
    inst.components.complexprojectile:SetOnHit(MineOnHit)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(180) --ANCIENT_HULK_MINE_DAMAGE
    inst.components.combat.playerdamagepercent = .5

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(25)


    inst:AddComponent("mine")
    inst.components.mine:SetRadius(5.5)
    inst.components.mine:SetAlignment("ancient_hulk")
    inst.components.mine:SetOnExplodeFn(onnearmine)
    inst.components.mine:SetReusable(false)

    inst.DoDamage = DoDamage

    inst:DoTaskInTime(30, minetrigger)

    return inst
end

local function OnHitOrb(inst)
    inst.AnimState:PlayAnimation("impact")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")

    inst:ListenForEvent("animover", function()
        inst:Remove()
    end)


    SpawnPrefab("laser_ring").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:DoTaskInTime(0.3, function() DoDamage(inst, 3.5) end)
    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
end

local function orbfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetSphere(0.2)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)


    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)


    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --[[inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetOnHit(OnHitOrb)
    inst.components.linearprojectile:SetHorizontalSpeed(34)]]
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile.usehigharc = false
    inst.components.complexprojectile:SetOnHit(OnHitOrb)
    inst.components.complexprojectile:SetHorizontalSpeed(38)
    inst.components.complexprojectile:SetGravity(-20)




    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(120)
    inst.components.combat.playerdamagepercent = 0.5

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(30)

    return inst
end

local WORK_RADIUS_PADDING = 0.5
local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    local tag = k .. "_workable"
    table.insert(COLLAPSIBLE_TAGS, tag)
end

local NON_COLLAPSIBLE_TAGS = { "FX", --[["NOCLICK",]] "DECOR", "INLIMBO", --[["structure",]] "wall", "walkableperipheral" }

local function DoAOEWork(inst, x, z)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 3 + WORK_RADIUS_PADDING, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)) do
        if v:IsValid() and not v:IsInLimbo() then
            if (not v:HasTag("structure") or
                    (v.components.childspawner and not v:HasTag("playerowned")) or
                    (v:HasTag("statue") and not v:HasTag("sculpture")) or
                    v:HasTag("smashable")
                )
            then
                local isworkable = false
                if v.components.workable then
                    local work_action = v.components.workable:GetWorkAction()
                    --V2C: nil action for NPC_workable (e.g. campfires)
                    --     allow digging spawners (e.g. rabbithole)
                    isworkable = (
                        (work_action == nil and v:HasTag("NPC_workable")) or
                        (v.components.workable:CanBeWorked() and work_action and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
                    )
                end
                if isworkable then
                    v.components.workable:Destroy(inst)
                    if v:IsValid() and v:HasTag("stump") and v.components.workable and v.components.workable:CanBeWorked() then
                        v.components.workable:Destroy(inst)
                    end
                elseif v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
                    v.components.pickable:Pick(inst)
                end
            end
        end
    end
end

local function onhit(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()

    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    SpawnPrefab("laser_ring").Transform:SetPosition(x, y, z)
    DoAOEWork(inst, x, z)
    local ents = TheSim:FindEntities(x, y, z, 3, { "_combat" },
        { "INLIMBO", "player", "flight", "invisible", "notarget", "noattack" })
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() then
            v.components.combat:GetAttacked(attacker, 120, nil, nil, { ["planar"] = 50 })
        end
    end
    inst:Remove()
end

local function smallorbfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.AnimState:SetScale(0.9, 0.9, 0.9)


    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetOnHit(OnHitOrb)
    inst.components.linearprojectile:SetHorizontalSpeed(28)
    inst.components.linearprojectile:SetRange(16)
    inst.components.linearprojectile:SetOnHit(onhit)
    inst.components.linearprojectile:SetOnMiss(onhit)
    inst.components.linearprojectile.musttags = nil
    inst.components.linearprojectile.oneoftags = { "_combat", "blocker" }
    table.insert(inst.components.linearprojectile.notags, "player")
    table.insert(inst.components.linearprojectile.notags, "structure")

    return inst
end

return Prefab("ancient_hulk", fn, assets, prefabs),
    Prefab("ancient_hulk_mine", minefn, assets),
    Prefab("ancient_hulk_orb", orbfn, assets),
    Prefab("laser_orb", smallorbfn, assets),
    RuinsRespawner.Inst("ancient_hulk"), RuinsRespawner.WorldGen("ancient_hulk")
