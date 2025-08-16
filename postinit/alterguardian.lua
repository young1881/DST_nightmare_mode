local function TrueFn()
    return true
end

local function anticheating(inst)
    -- inst.components.freezable:SetRedirectFn(TrueFn)
end

local lunargazer_limit = 3
local lunargazer_possibility = 0.25

local function TrySpawnLunarGrazer(inst, data)
    if data.victim and data.victim:IsValid() and data.victim.isplayer and lunargazer_limit > 0 and math.random() < lunargazer_possibility then
        local lunargazer = SpawnPrefab("lunar_grazer")
        lunargazer.Transform:SetPosition(data.victim.Transform:GetWorldPosition())
        lunargazer.components.combat:SetShouldAvoidAggro(inst)
        lunargazer:AddTag("superplant")
        if lunargazer.components.damagetyperesist == nil then
            lunargazer:AddComponent("damagetyperesist")
        end
        lunargazer.components.combat:AddNoAggroTag("epic")
        lunargazer.components.combat:AddNoAggroTag("superplant")
        lunargazer.components.damagetyperesist:AddResist("epic", inst, 0)
        lunargazer.components.damagetyperesist:AddResist("superplant", inst, 0)
        -- lunargazer_limit = lunargazer_limit - 1
    end
end

local function TrySpawnLunarPlant(inst, data)
    if data.victim and data.victim:IsValid() and data.victim.isplayer then
        local lunarplant = SpawnPrefab("lunarthrall_plant")
        lunarplant.Transform:SetPosition(data.victim.Transform:GetWorldPosition())
        lunarplant.persists = false
        lunarplant:AddTag("brightmare")
        lunarplant:AddTag("superplant")
        lunarplant.components.combat:SetShouldAvoidAggro(inst)
        lunarplant.Transform:SetScale(1.25, 1.25, 1.25)
        TUNING.LUNARTHRALL_PLANT_RANGE = 20

        if lunarplant.sg and lunarplant.sg.mem then
            lunarplant.sg.mem.noelectrocute = true
        end
        lunarplant:AddTag("electricdamageimmune")

        if lunarplant.components.damagetyperesist == nil then
            lunarplant:AddComponent("damagetyperesist")
        end
        lunarplant.components.combat:AddNoAggroTag("epic")
        lunarplant.components.damagetyperesist:AddResist("epic", inst, 0)
        if lunarplant.components.health then
            lunarplant.components.health:SetMaxHealth(1800)
        end
    end
end

AddPrefabPostInit("lunarthrall_plant_vine_end", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:AddTag("superplant")
    if inst.components.damagetyperesist == nil then
        inst:AddComponent("damagetyperesist")
    end
    if inst.components.combat then
        inst.components.combat:AddNoAggroTag("epic")
    end
    inst.components.damagetyperesist:AddResist("epic", inst, 0)
end)

AddPrefabPostInit("lunarthrall_plant_vine", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:AddTag("superplant")
    if inst.components.damagetyperesist == nil then
        inst:AddComponent("damagetyperesist")
    end
    if inst.components.combat then
        inst.components.combat:AddNoAggroTag("epic")
    end
    inst.components.damagetyperesist:AddResist("epic", inst, 0)
end)

AddStategraphPostInit("lunarthrall_plant", function(sg)
    local function ShouldModify(inst)
        return inst:HasTag("superplant")
    end

    local idle = sg.states["idle"]
    if idle then
        local original_onenter = idle.onenter
        idle.onenter = function(inst, ...)
            if ShouldModify(inst) then
                inst.sg:GoToState("attack")
            else
                if original_onenter then
                    original_onenter(inst, ...)
                end
            end
        end
    end

    local hit = sg.states["hit"]
    if hit then
        local original_events = hit.events
        hit.events = {
            EventHandler("animover", function(inst)
                if ShouldModify(inst) then
                    inst.sg:GoToState("attack")
                else
                    if original_events then
                        for _, event in ipairs(original_events) do
                            event.fn(inst)
                        end
                    end
                end
            end),
        }
    end

    local tired_pst = sg.states["tired_pst"]
    if tired_pst then
        local original_events = tired_pst.events
        tired_pst.events = {
            EventHandler("animover", function(inst)
                if ShouldModify(inst) then
                    inst.sg:GoToState("attack")
                else
                    if original_events then
                        for _, event in ipairs(original_events) do
                            event.fn(inst)
                        end
                    end
                end
            end),
        }
    end
end)


--------------------------------------------
---PHASES1
--------------------------------------------

local easing = require("easing")

AddComponentPostInit("meteorshower", function(self)
    local function OnUpdate(inst, self)
        if inst:IsNearPlayer(30) then
            self:SpawnCrazyMeteor()
        end

        if GetTime() >= self.tasktotime then
            self:StartCooldown()
        end
    end
    function self:StartCrazyShower()
        self:StopShower()

        local duration = 30

        self.dt = 2
        self.large_remaining = 40

        self.task = self.inst:DoPeriodicTask(self.dt, OnUpdate, nil, self)
        self.tasktotime = GetTime() + duration
    end

    function self:SpawnCrazyMeteor(mod)
        --Randomize spawn point
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local theta = math.random() * PI2
        -- Do some easing fanciness to make it less clustered around the spawner prefab
        local radius = easing.linear(math.random(), math.random() * 7, 22, 1)

        local met = SpawnPrefab("firerain_cs")
        met.Transform:SetPosition(x + radius * math.cos(theta), 0, z - radius * math.sin(theta))
        met:StartStep()


        return met
    end
end)


local SPIKE_SIZES =
{
    "short",
    "med",
    "tall",
}

local SPIKE_RADIUS =
{
    ["short"] = .2,
    ["med"] = .4,
    ["tall"] = .6,
    ["block"] = 1.1,
}

local function CanSpawnSpikeAt(pos, size)
    local radius = SPIKE_RADIUS[size]
    for i, v in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, radius + 1.5, nil, { "antlion_sinkhole" }, { "groundspike", "antlion_sinkhole_blocker" })) do
        if v.Physics == nil then
            return false
        end
        local spacing = radius + v:GetPhysicsRadius(0)
        if v:GetDistanceSqToPoint(pos) < spacing * spacing then
            return false
        end
    end
    return true
end

local function SpawnSpikes(inst, pos, count)
    for i = #SPIKE_SIZES, 1, -1 do
        local size = SPIKE_SIZES[i]
        if CanSpawnSpikeAt(pos, size) then
            SpawnPrefab("sandspike_" .. size).Transform:SetPosition(pos:Get())
            count = count - 1
            break
        end
    end
    if count > 0 then
        local dtheta = TWOPI / count
        for theta = math.random() * dtheta, TWOPI, dtheta do
            local size = SPIKE_SIZES[math.random(#SPIKE_SIZES)]
            local offset = FindWalkableOffset(pos, theta, 2 + math.random() * 2, 3, false, true,
                function(pt)
                    return CanSpawnSpikeAt(pt, size)
                end,
                false, true)
            if offset ~= nil then
                SpawnPrefab("sandspike_" .. size).Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
            end
        end
    end
end

local function FindSandSpikeTarget(inst)
    local targets = {}
    local ix, _, iz = inst.Transform:GetWorldPosition()
    for i, p in ipairs(AllPlayers) do
        local dsq_to_player = p:GetDistanceSqToPoint(ix, 0, iz)
        if dsq_to_player < 400
            and not p:HasTag("playerghost") then
            table.insert(targets, p)
        end
    end
    return targets
end

local function TrySandSpikeAttacks(inst)
    local targets = FindSandSpikeTarget(inst)
    if next(targets) ~= nil then
        for k, v in ipairs(targets) do
            if v:IsValid() then
                SpawnSpikes(inst, v:GetPosition(), math.random(5, 6))
            end
        end
    end
end

AddPrefabPostInit("alterguardian_phase1", function(inst)
    inst:AddTag("meteor_protection")


    if not TheWorld.ismastersim then
        return
    end

    inst.components.locomotor:EnableGroundSpeedMultiplier(false)

    anticheating(inst)

    inst:AddComponent("meteorshower")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder:UseRingMode()
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.initialRadius = 1.5
    inst.components.groundpounder.radiusStepDistance = 2
    inst.components.groundpounder.ringWidth = 2
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 3
    inst.components.groundpounder.platformPushingRings = 3
    inst.components.groundpounder.fxRings = 2
    inst.components.groundpounder.fxRadiusOffset = 1.5
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.groundpoundfx = "firesplash_fx"
    inst.components.groundpounder.groundpoundringfx = "firering_fx"


    local function OnBossDeath(inst, data)
        if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("player") then
            local killer = data.afflicter
            if killer.SoundEmitter ~= nil then
                killer.SoundEmitter:PlaySound("lumos/group1/Exordium_Slain")
            end
        end
    end

    inst:ListenForEvent("death", OnBossDeath)
end)


---SG-change
local function roll_screenshake(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, 0.05, 0.075, inst, 40)
end


local function SpawnSpell(x, z, prefab)
    local spell = SpawnPrefab(prefab)
    spell.Transform:SetPosition(x, 0, z)
    if spell.TriggerFX then
        spell:DoTaskInTime(2.5, spell.TriggerFX)
    end
    spell:DoTaskInTime(20, spell.KillFX)
end

local function spawn_landfx(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local sinkhole = SpawnPrefab("lava_sinkhole")
    sinkhole.Transform:SetPosition(ix, iy, iz)
end


local SEPLL_ONEOF_TAGS = { "character" }
local SPELL_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }
local ice_circle = true
local function CastSpells(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, 30, nil, SPELL_CANT_TAGS, SEPLL_ONEOF_TAGS)) do
        if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            local px, py, pz = v.Transform:GetWorldPosition()
            SpawnSpell(px, pz, ice_circle and "deer_ice_circle" or "deer_fire_circle")
        end
    end
    ice_circle = not ice_circle
end

-- 防止新天体炸
AddPrefabPostInit("alterguardian_phase1_lunarrift", function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.groundpounder == nil then
        inst:AddComponent("groundpounder")
        inst.components.groundpounder.numRings = 2
        inst.components.groundpounder.radiusStepDistance = 3
        inst.components.groundpounder.initialRadius = 3
        inst.components.groundpounder.damageRings = 2
    end
end)

AddStategraphPostInit("alterguardian_phase1", function(sg)
    sg.states.roll.onenter = function(inst, speed)
        inst:EnableRollCollision(true)

        inst.components.locomotor:Stop()
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.Physics:SetMotorVelOverride(speed or 10, 0, 0)
        inst.sg.statemem.rollhits = {}

        inst.AnimState:PlayAnimation("roll_loop", true)

        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())

        if inst.sg.mem._num_rolls == nil then
            inst.sg.mem._num_rolls = TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT + (2 * math.random())
        else
            inst.sg.mem._num_rolls = inst.sg.mem._num_rolls - 1
        end

        inst.components.combat:RestartCooldown()
    end
    sg.states.roll.timeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian1/roll")

            roll_screenshake(inst)

            spawn_landfx(inst)
            local roll_speed = 10
            local target = inst.components.combat.target
            if target ~= nil and target:IsValid() and target.components.locomotor ~= nil then
                roll_speed = math.max(10,
                    target.components.locomotor:GetRunSpeed() * inst.components.locomotor:GetSpeedMultiplier() + 3)
                roll_speed = math.min(roll_speed, 35)
            end
            inst.sg.statemem.roll_speed = roll_speed
        end),
    }
    sg.states.roll.ontimeout = function(inst)
        if not inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
            local final_rotation = nil
            if inst.components.combat.target ~= nil then
                -- Retarget, and keep rolling!
                local tx, ty, tz = inst.components.combat.target.Transform:GetWorldPosition()
                local target_facing = inst:GetAngleToPoint(tx, ty, tz)

                local current_facing = inst:GetRotation()

                local target_angle_diff = ((target_facing - current_facing + 540) % 360) - 180

                if math.abs(target_angle_diff) > 120 then
                    final_rotation = target_facing + GetRandomWithVariance(0, -4)
                elseif target_angle_diff < 0 then
                    final_rotation = (current_facing + math.max(target_angle_diff, -120)) % 360
                else
                    final_rotation = (current_facing + math.min(target_angle_diff, 120)) % 360
                end
            else
                final_rotation = 360 * math.random()
            end

            inst.Transform:SetRotation(final_rotation)

            inst.sg:GoToState("roll", inst.sg.statemem.roll_speed)
        elseif inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
            inst.sg.mem._num_rolls = math.max(inst.sg.mem._num_rolls - 2, 0)
            inst.sg:GoToState("roll", inst.sg.statemem.roll_speed)
        else
            inst.sg.mem._num_rolls = nil
            inst.sg:GoToState("roll_stop")
        end
    end
    sg.states.shield_end.onenter = function(inst)
        inst.AnimState:PlayAnimation("shield_pst")
        CastSpells(inst)
    end

    sg.states.shield_pre.onenter = function(inst)
        inst.Physics:Stop()

        inst.AnimState:PlayAnimation("shield_pre")
        inst.components.meteorshower:StartCrazyShower()
    end
    sg.states.shield.onupdate = function(inst, dt)
        if inst.sg.statemem.spike_tick == nil or inst.sg.statemem.spike_tick < 0 then
            TrySandSpikeAttacks(inst)
            inst.sg.statemem.spike_tick = 2
        else
            inst.sg.statemem.spike_tick = inst.sg.statemem.spike_tick - dt
        end
    end
    sg.states.tantrum.onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("tantrum_loop")

        if inst.sg.mem.aoes_remaining == nil or inst.sg.mem.aoes_remaining == 0 then
            inst.sg.mem.aoes_remaining = RoundBiasedUp(GetRandomMinMax(3, 5))
        end
        inst.components.groundpounder:GroundPound()
    end
end)


--------------------------------------------
---PHASES2
--------------------------------------------

local function spawn_spike_with_pos(inst, pos, angle)
    local spike = SpawnPrefab("alterguardian_phase2spiketrail")
    spike.Transform:SetPosition(pos.x, 0, pos.z)
    spike.Transform:SetRotation(angle)
    spike:SetOwner(inst)
end


local function spawnbarrier(inst)
    local angle = 0
    local radius = 15
    local number = 8
    local pos = inst:GetPosition()
    for i = 1, number do
        local offset = Vector3(radius * math.cos(angle * DEGREES), 0, -radius * math.sin(angle * DEGREES))
        local newpt = pos + offset

        --local tile = GetWorld().Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)
        if TheWorld.Map:IsPassableAtPoint(newpt.x, 0, newpt.z) then
            inst:DoTaskInTime(0.3, spawn_spike_with_pos, newpt, angle)
        end
        angle = angle + (360 / number)
    end
end

AddPrefabPostInit("alterguardian_phase2", function(inst)
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")

    if not TheWorld.ismastersim then
        return
    end

    anticheating(inst)

    local oldDoSpikeAttack = inst.DoSpikeAttack
    inst.DoSpikeAttack = function(inst)
        oldDoSpikeAttack(inst)
        spawnbarrier(inst)
    end

    inst:ListenForEvent("killed", TrySpawnLunarPlant)

    if inst.components.damagetyperesist == nil then
        inst:AddComponent("damagetyperesist")
    end
    inst.components.combat:AddNoAggroTag("superplant")
    inst.components.damagetyperesist:AddResist("lunarthrall_plant", inst, 0)

    local function OnBossDeath(inst, data)
        if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("player") then
            local killer = data.afflicter
            if killer.SoundEmitter ~= nil then
                killer.SoundEmitter:PlaySound("lumos/group1/The_City_Slain")
            end
        end
    end

    inst:ListenForEvent("death", OnBossDeath)
end)




---SG
local AOE_RANGE_PADDING = 3
local CHOP_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE * TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE
local SPIN_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE


local NUM_SMALLGUARDS = 12
local Z_SPAWN_DIFF = 0.50
local X_SPAWN_DIFF = 1.75 * 2
local function do_gestalt_summon(inst)
    local target = inst.components.combat.target
    if target == nil then
        return
    end

    local tpos = target:GetPosition()
    local ipos = inst:GetPosition()

    local itot_normal, itot_len = (tpos - ipos):GetNormalizedAndLength()
    local itot_perp = Vector3(itot_normal.z, 0, -itot_normal.x)

    local spawn_len = math.max(2, itot_len - 4)
    local spawn_start = ipos + (itot_normal * spawn_len) + (itot_perp * GetRandomWithVariance(0, 0.5))
    for i = 1, NUM_SMALLGUARDS do
        inst:DoTaskInTime((i - 1) * 3 * FRAMES, function(inst2)
            local spawn_pos = spawn_start
            if i ~= 1 then
                -- At each step, go "back" (towards the boss) a little bit, (RoundBiasedUp)
                -- then spawn subsequent objects on opposite sides. (IsNumberEven)
                local num_steps = RoundBiasedUp((i - 1) / 2)
                local x_step, z_step = nil, nil
                if IsNumberEven(i) then
                    z_step = -1 * Z_SPAWN_DIFF * num_steps
                    x_step = X_SPAWN_DIFF * num_steps
                else
                    z_step = -1 * Z_SPAWN_DIFF * num_steps
                    x_step = -1 * X_SPAWN_DIFF * num_steps
                end
                spawn_pos = spawn_pos + (itot_normal * z_step) + (itot_perp * x_step)
            end

            local smallguard = SpawnPrefab((i % 4 == 0 or i % 4 == 1) and "gestalt_alterguardian_projectile" or
                "largeguard_alterguardian_projectile")
            smallguard.Transform:SetPosition(spawn_pos:Get())
            smallguard:SetTargetPosition(spawn_pos + itot_normal)
        end)
    end
end

AddStategraphPostInit("alterguardian_phase2", function(sg)
    sg.events["doattack"].fn = function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)
            local can_spin = not inst.components.timer:TimerExists("spin_cd")
            local can_deadspin = not inst.components.timer:TimerExists("deadspin_cd")
            local can_summon = not inst.components.timer:TimerExists("summon_cd")
            local can_spike = not inst.components.timer:TimerExists("spike_cd")
            local can_atk2 = not inst.components.timer:TimerExists("lightning_cd")
            local attack_state = (not data.target:IsOnValidGround() and "antiboat_attack")
                or (dsq_to_target < SPIN_RANGE_DSQ and can_spin and (can_deadspin and "deadspin_pre" or "spin_pre"))
                or (can_summon and "atk_summon")
                or (can_spike and "atk_spike")
                or (can_atk2 and "lightning_trial")
                or (dsq_to_target < CHOP_RANGE_DSQ and "atk_chop")
                or nil
            if attack_state ~= nil then
                inst.sg:GoToState(attack_state, data.target)
            end
        end
    end
    sg.states.atk_summon.timeline[6].fn = do_gestalt_summon
end)

local function spike_break(inst)
    inst.Physics:SetActive(false)

    inst.components.workable:SetWorkable(false)

    if math.random() < 0.1 then
        local pos = inst:GetPosition()
        local alterguardian_phase3trap = SpawnPrefab("alterguardian_phase3trap")
        alterguardian_phase3trap.Transform:SetPosition(pos:Get())
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.AnimState:PlayAnimation("spike_pst")

    inst.SoundEmitter:PlaySound("turnoftides/common/together/moon_glass/break", nil, .25)
end

local function on_spike_mining_finished(inst, worker)
    if inst._break_task ~= nil then
        inst._break_task:Cancel()
        inst._break_task = nil
    end

    spike_break(inst)
end

AddPrefabPostInit("alterguardian_phase2spike", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.workable:SetOnFinishCallback(on_spike_mining_finished)

    inst._break_task = inst:DoTaskInTime(TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME, spike_break)
end)


local function dospark(inst)
    local shock_fx = SpawnPrefab("moonstorm_spark_shock_fx")
    shock_fx.Transform:SetScale(2, 2, 2)
    inst:AddChild(shock_fx)


    --inst:SpawnChild("electricchargedfx").AnimState:SetScale(1.5,1.5,1.5)
end

-----------冰冻技能
local ICE_LANCE_RADIUS = 6.5 --冰冻半径
local AREAATTACK_MUST_TAGS = { "_combat" }
local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "brightmareboss" }
local function DoIceLanceAOE(inst, pt)
    local fx = SpawnPrefab("crabking_ring_fx")
    fx.Transform:SetPosition(pt.x, 0, pt.z)
    local dist = math.sqrt(inst:GetDistanceSqToPoint(pt))
    inst.components.combat.ignorehitrange = true
    local ents = TheSim:FindEntities(pt.x, 0, pt.z, ICE_LANCE_RADIUS, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and not v:IsInLimbo() and
            not (v.components.health ~= nil and v.components.health:IsDead()) and
            inst.components.combat:CanTarget(v)
        then
            local wasfrozen = v.components.freezable ~= nil and v.components.freezable:IsFrozen()
            inst.components.combat:DoAttack(v)
            if v.components.freezable ~= nil then
                v.components.freezable:AddColdness(99, 18) --freezetime:12
            end
            if wasfrozen then
                v:PushEvent("knockback", { knocker = inst, radius = dist + ICE_LANCE_RADIUS })
            end
        end
    end
    inst.components.combat.ignorehitrange = false
end



local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end


local function spawn_spintrail(inst)
    local spawn_pt = inst:GetPosition() --- Vector3(1.5 * math.cos(facing_dir), 0, -1.5 * math.sin(facing_dir))
    SpawnPrefab("alterguardian_spintrail_fx").Transform:SetPosition(spawn_pt:Get())
    SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(spawn_pt:Get())
end


local SPIN_CANT_TAGS = { "brightmareboss", "brightmare", "INLIMBO", "FX", "NOCLICK", "playerghost", "flight", "invisible",
    "notarget", "noattack" }
local SPIN_ONEOF_TAGS = { "_health", "CHOP_workable", "HAMMER_workable", "MINE_workable" }
local SPIN_FX_RATE = 10 * FRAMES

AddStategraphState("alterguardian_phase2", State {
    name = "lightning_trial",
    tags = { "attack", "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()

        inst.components.combat:StartAttack()

        inst.AnimState:PlayAnimation("attk_chop")

        local target = inst.components.combat.target
        if target ~= nil and target:IsValid() then
            inst.sg.statemem.target = target
            inst.sg.statemem.targetpos = target:GetPosition()
            inst.sg.statemem.targetrot = target.Transform:GetRotation()
            inst:ForceFacePoint(inst.sg.statemem.targetpos)
        end

        if inst.sg.mem.num_summons == nil then
            inst.components.timer:StartTimer("lightning_cd", TUNING.ALTERGUARDIAN_PHASE2_LIGHTNINGCOOLDOWN)
            inst.sg.mem.num_summons = 4
        else
            inst.sg.mem.num_summons = inst.sg.mem.num_summons - 1
        end
        inst.sg:SetTimeout(1.5)
    end,

    timeline =
    {
        TimeEvent(0 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/summon")
        end),
        TimeEvent(20 * FRAMES, function(inst)
            dospark(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            inst.sg.statemem.target = nil
            local p = inst.sg.statemem.targetpos
            if p ~= nil then
                p.y = 0
                --local theta = inst.sg.statemem.targetrot*DEGREES
                --local radius = 6 + 4*math.random()

                inst.sg.statemem.ping1 = SpawnPrefab("deerclops_icelance_ping_fx")
                inst.sg.statemem.ping1.Transform:SetPosition(p:Get())

                --inst.sg.statemem.ping2 = SpawnPrefab("deerclops_icelance_ping_fx")
                --inst.sg.statemem.ping2.Transform:SetPosition(p.x + radius*math.cos(theta), 0, p.z - radius*math.sin(theta))
            end
        end),
        TimeEvent(22 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/spell_cast")
            ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
        end),
        TimeEvent(38 * FRAMES, function(inst)
            if inst.sg.statemem.ping1 ~= nil then
                inst.sg.statemem.ping1:KillFX()
                inst.sg.statemem.ping1 = nil
                DoIceLanceAOE(inst, inst.sg.statemem.targetpos)
            end
        end),
        TimeEvent(40 * FRAMES, function(inst)
            --[[if inst.sg.statemem.ping2~= nil then
                local lightning = SpawnPrefab("moon_lightning2")
                lightning:SetOwner(inst)
                lightning.Transform:SetPosition(inst.sg.statemem.ping2.Transform:GetWorldPosition())
                inst.sg.statemem.ping2:KillFX()
                inst.sg.statemem.ping2 = nil
            end ]]
        end),
    },
    ontimeout = function(inst)
        if inst.sg.mem.num_summons and inst.sg.mem.num_summons > 0 then
            inst.sg:GoToState("lightning_trial")
        else
            inst.sg.mem.num_summons = nil
            inst.sg:GoToState("idle")
        end
    end,

    onexit = function(inst)
        if inst.sg.statemem.ping1 ~= nil then
            inst.sg.statemem.ping1:KillFX()
            inst.sg.statemem.ping1 = nil
        end
        --[[if inst.sg.statemem.ping2~= nil then
            inst.sg.statemem.ping2:KillFX()
            inst.sg.statemem.ping2 = nil
        end]]
    end
})




AddStategraphState("alterguardian_phase2", State {
    name = "deadspin_pre",
    tags = { "busy", "canrotate", "spin" },

    onenter = function(inst, target)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("attk_spin_pre")

        dospark(inst)

        inst.components.timer:StartTimer("deadspin_cd", TUNING.ALTERGUARDIAN_PHASE2_SPIN2CD)
        inst.sg.mem.deadcount = 2
        --inst.Physics:ClearCollidesWith(COLLISION.WORLD)
        --inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.sg.statemem.target = target
    end,

    onupdate = function(inst, dt)
        local target = inst.sg.statemem.target
        if target ~= nil and target:IsValid() then
            inst:ForceFacePoint(target.Transform:GetWorldPosition())
        end

        if inst.sg.timeinstate > 32 * FRAMES then
            local time_in_spin = inst.sg.timeinstate - 32 * FRAMES
            if time_in_spin > (FRAMES ^ 3) and time_in_spin % SPIN_FX_RATE < (FRAMES ^ 3) then
                spawn_spintrail(inst)
            end
        end

        -- Do a check for AOE damage & smashing occasionally.
        if inst.sg.statemem.attack_time == nil then
            --not yet
        elseif inst.sg.statemem.attack_time > 0 then
            inst.sg.statemem.attack_time = inst.sg.statemem.attack_time - dt
        else
            local ix, iy, iz = inst.Transform:GetWorldPosition()
            local targets = TheSim:FindEntities(
                ix, iy, iz, TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + AOE_RANGE_PADDING,
                nil, SPIN_CANT_TAGS, SPIN_ONEOF_TAGS
            )
            for _, target in ipairs(targets) do
                if target:IsValid() and not target:IsInLimbo() then
                    local range = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + target:GetPhysicsRadius(0)
                    if target:GetDistanceSqToPoint(ix, iy, iz) < range * range then
                        local has_health = target.components.health ~= nil
                        if has_health and target:HasTag("smashable") then
                            target.components.health:Kill()
                        elseif target.components.workable ~= nil
                            and target.components.workable:CanBeWorked() then
                            if not target:HasTag("moonglass") then
                                local tx, ty, tz = target.Transform:GetWorldPosition()
                                local collapse_fx = SpawnPrefab("collapse_small")
                                collapse_fx.Transform:SetPosition(tx, ty, tz)
                            end

                            target.components.workable:Destroy(inst)
                        elseif has_health and not target.components.health:IsDead() then
                            inst.components.combat:DoAttack(target, nil, nil, "electric")
                        end
                    end
                end
            end

            inst.sg.statemem.attack_time = 8 * FRAMES
        end
    end,

    timeline =
    {
        TimeEvent(30 * FRAMES, function(inst)
            dospark(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_pre")
        end),
        TimeEvent(32 * FRAMES, function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.Physics:SetMotorVelOverride(TUNING.ALTERGUARDIAN_PHASE2_DEADSPIN_SPEED, 0, 0)
        end),
        TimeEvent(35 * FRAMES, function(inst)
            inst.sg.statemem.attack_time = 0
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.sg.statemem.target ~= nil and not inst.sg.statemem.target.components.health:IsDead() then
                local loop_data =
                {
                    spin_time_remaining = (inst.sg.timeinstate - 18 * FRAMES) % SPIN_FX_RATE,
                    target = inst.sg.statemem.target,
                    attack_time = inst.sg.statemem.attack_time,
                }
                inst.sg:GoToState("deadspin_loop", loop_data)
            else
                inst.sg.mem.deadcount = nil


                go_to_idle(inst)
            end
        end),
    },

    onexit = function(inst)
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()
    end,
})


AddStategraphState("alterguardian_phase2", State {
    name = "deadspin_loop",
    tags = { "busy", "canrotate", "spin" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)

        inst.AnimState:PlayAnimation("attk_spin_loop", true)
        dospark(inst)

        inst.sg.statemem.loop_len = inst.AnimState:GetCurrentAnimationLength()
        --local num_loops = 2
        inst.sg:SetTimeout(inst.sg.statemem.loop_len * 2)

        inst.sg.statemem.attack_time = data.attack_time or 0
        inst.sg.statemem.target = data.target
        inst.sg.statemem.speed = TUNING.ALTERGUARDIAN_PHASE2_DEADSPIN_SPEED
        inst.sg.statemem.initial_spin_fx_time = data.spin_time_remaining

        if data.target ~= nil and data.target:IsValid() then
            inst:ForceFacePoint(data.target.Transform:GetWorldPosition())
        end
        inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_LP", "spin_loop")

        inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
    end,

    onupdate = function(inst, dt)
        -- If our original target is still alive, chase them down.
        -- Otherwise, we'll just go in the direction we were facing until we finish.


        local fx_time_in_state = inst.sg.statemem.initial_spin_fx_time + inst.sg.timeinstate
        if fx_time_in_state % SPIN_FX_RATE < (FRAMES ^ 3) then
            spawn_spintrail(inst)
        end

        -- Do a check for AOE damage & smashing occasionally.
        if inst.sg.statemem.attack_time > 0 then
            inst.sg.statemem.attack_time = inst.sg.statemem.attack_time - dt
        else
            local hit_player = false

            local ix, iy, iz = inst.Transform:GetWorldPosition()
            local targets = TheSim:FindEntities(
                ix, iy, iz, TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + AOE_RANGE_PADDING,
                nil, SPIN_CANT_TAGS, SPIN_ONEOF_TAGS
            )
            for _, target in ipairs(targets) do
                if target:IsValid() and not target:IsInLimbo() then
                    local range = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + target:GetPhysicsRadius(0)
                    if target:GetDistanceSqToPoint(ix, iy, iz) < range * range then
                        local has_health = target.components.health ~= nil
                        if has_health and target:HasTag("smashable") then
                            target.components.health:Kill()
                        elseif target.components.workable ~= nil
                            and target.components.workable:CanBeWorked() then
                            if not target:HasTag("moonglass") then
                                local tx, ty, tz = target.Transform:GetWorldPosition()
                                local collapse_fx = SpawnPrefab("collapse_small")
                                collapse_fx.Transform:SetPosition(tx, ty, tz)
                            end

                            target.components.workable:Destroy(inst)
                        elseif has_health and not target.components.health:IsDead() then
                            inst.components.combat:DoAttack(target, nil, nil, "electric")
                            if target:HasTag("player") then
                                hit_player = true
                            end
                        end
                    end
                end
            end

            inst.sg.statemem.attack_time = 8 * FRAMES

            -- If we hit a player and have more than a loop left, finish our looping early.
            -- This is to help prevent players being strung along in a long hit chain.
            if hit_player and (inst.sg.timeout == nil or inst.sg.timeout > inst.sg.statemem.loop_len) then
                inst.sg:SetTimeout(inst.sg.statemem.loop_len)
            end
        end
    end,
    timeline = {
        TimeEvent(35 * FRAMES, function(inst)
            dospark(inst)
            inst.sg.statemem.attack_time = 0
        end),
    },
    ontimeout = function(inst)
        inst.sg.statemem.exit_by_timeout = true
        if inst.sg.mem.deadcount and inst.sg.mem.deadcount > 0 then
            inst.sg.mem.deadcount = inst.sg.mem.deadcount - 1
            local loop_data =
            {
                spin_time_remaining = (inst.sg.timeinstate - 18 * FRAMES) % SPIN_FX_RATE,
                target = inst.sg.statemem.target,
                attack_time = inst.sg.statemem.attack_time,
            }
            inst.sg:GoToState("deadspin_loop", loop_data)
        else
            --inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.sg:GoToState("spin_pst", inst.sg.statemem.speed)
        end
    end,

    onexit = function(inst)
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()

        -- We may be exiting this state via death, freezing, etc.
        if not inst.sg.statemem.exit_by_timeout then
            inst.SoundEmitter:KillSound("spin_loop")
        end
    end,
})


--------------------------------------------
---PHASES3
--------------------------------------------


local function CalcSanityAura(inst, observer)
    return (inst.sg.statemem.in_eraser and 2 * TUNING.SANITYAURA_HUGE) or
        (inst.components.combat.target ~= nil and TUNING.SANITYAURA_HUGE) or TUNING.SANITYAURA_LARGE
end

local function FallOffFn(inst, observer, dsq)
    return inst.sg.statemem.in_eraser and 1 or math.max(1, dsq)
end



AddPrefabPostInit("alterguardian_phase3", function(inst)
    inst:AddTag("toughworker")
    inst:AddTag("notraptrigger")


    if not TheWorld.ismastersim then
        return
    end

    anticheating(inst)
    inst:AddComponent("debuffable")
    inst.components.combat:SetAreaDamage(4)

    inst.components.sanityaura.aurafn = CalcSanityAura
    inst.components.sanityaura.max_distsq = 400
    inst.components.sanityaura.fallofffn = FallOffFn

    inst:AddComponent("truedamage")

    inst:ListenForEvent("killed", TrySpawnLunarPlant)
    inst:ListenForEvent("killed", TrySpawnLunarGrazer)

    if inst.components.damagetyperesist == nil then
        inst:AddComponent("damagetyperesist")
    end
    inst.components.combat:AddNoAggroTag("superplant")
    inst.components.damagetyperesist:AddResist("lunarthrall_plant", inst, 0)

    local function OnBossDeath(inst, data)
        if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("player") then
            local killer = data.afflicter
            if killer.SoundEmitter ~= nil then
                killer.SoundEmitter:PlaySound("lumos/group1/The_Beyond_Slain")
            end
        end
    end

    inst:ListenForEvent("death", OnBossDeath)
end)



local MIN_TRAP_COUNT_FOR_RESPAWN = 4
local maxdeflect = 3
local RANGED_ATTACK_DSQ = TUNING.ALTERGUARDIAN_PHASE3_STAB_RANGE ^ 2
local SUMMON_DSQ = TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ - 36

local function post_attack_idle(inst)
    inst.components.timer:StopTimer("runaway_blocker")
    inst.components.timer:StartTimer("runaway_blocker", TUNING.ALTERGUARDIAN_PHASE3_RUNAWAY_BLOCK_TIME)

    inst.sg:GoToState("idle")
end

local function set_lightvalues(inst, val)
    inst.Light:SetIntensity(0.60 + (0.39 * val * val))
    inst.Light:SetRadius(5 * val)
    inst.Light:SetFalloff(0.85)
end

local function dowarning(inst, shouldadd)
    local ix, _, iz = inst.Transform:GetWorldPosition()

    inst.components.debuffable:RemoveOnDespawn()
    SpawnPrefab("moonpulse_spawner").Transform:SetPosition(ix, 0, iz)
end


local function laser_sound(inst)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam_laser")
end

local NUM_STEPS = 10
local STEP = 1.0
local OFFSET = 2 - STEP
local function DoEraser(inst, target)
    if target.components.inventory ~= nil then
        for k, v in pairs(target.components.inventory.equipslots) do
            --if v.components.finiteuses ~= nil then
            --    v.components.finiteuses:SetUses(0)
            --end
            if v.components.armor ~= nil then
                v.components.armor:SetCondition(0)
            end
            if v.components.fueled ~= nil then
                v.components.fueled:MakeEmpty()
            end
            if v.components.perishable ~= nil then
                v.components.perishable:Perish()
            end
        end
    end
    if target.components.burnable ~= nil then
        target.components.burnable:Ignite()
    end
    target.components.health:DoDelta(-100000, false, "alterguardian_phase3", true, nil, true)
    target.components.health:DeltaPenalty(0.25)
end

local DAMAGE_CANT_TAGS = { "brightmareboss", "brightmare", "playerghost", "INLIMBO", "DECOR", "FX" }
local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable",
    "DIG_workable" }
local LAUNCH_MUST_TAGS = { "_inventoryitem" }
local LAUNCH_CANT_TAGS = { "locomotor", "INLIMBO" }
local function DoDamage(inst, targets, skiptoss, skipscorch)
    local RADIUS = .7
    local LAUNCH_SPEED = .2
    if inst.type ~= nil then
        RADIUS = 2
        LAUNCH_SPEED = 1
    end
    inst.task = nil

    local x, y, z = inst.Transform:GetWorldPosition()

    -- First, get our presentation out of the way, since it doesn't change based on the find results.
    if inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation("hit_" .. tostring(math.random(5)))
        inst:Show()
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

        inst.Light:Enable(true)
        inst:DoTaskInTime(4 * FRAMES, SetLightRadius, .5)
        inst:DoTaskInTime(5 * FRAMES, DisableLight)

        if not skipscorch and TheWorld.Map:IsPassableAtPoint(x, 0, z, false) then
            SpawnPrefab("alterguardian_laserscorch").Transform:SetPosition(x, 0, z)
        end

        local fx = SpawnPrefab("alterguardian_lasertrail")
        fx.Transform:SetPosition(x, 0, z)
        fx:FastForward(GetRandomMinMax(.3, .7))
    else
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end

    inst.components.combat.ignorehitrange = true
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, nil, DAMAGE_CANT_TAGS, DAMAGE_ONEOF_TAGS)) do
        if not targets[v] and v:IsValid() and
            not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = RADIUS + v:GetPhysicsRadius(.5)
            local dsq_to_laser = v:GetDistanceSqToPoint(x, y, z)
            if dsq_to_laser < range * range then
                v:PushEvent("onalterguardianlasered")

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
                    v.components.workable:Destroy(inst)

                    -- Completely uproot trees.
                    if v:HasTag("stump") then
                        v:Remove()
                    end
                elseif v.components.pickable ~= nil
                    and v.components.pickable:CanBePicked()
                    and not v:HasTag("intense") then
                    targets[v] = true
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                    if product ~= nil and num > 0 then
                        for i = 1, num do
                            local loot = SpawnPrefab(product)
                            loot.Transform:SetPosition(x1, 0, z1)
                            skiptoss[loot] = true
                            targets[loot] = true
                            Launch(loot, inst, LAUNCH_SPEED)
                        end
                    end
                elseif v.components.combat == nil and v.components.health ~= nil then
                    targets[v] = true
                elseif inst.components.combat:CanTarget(v) then
                    targets[v] = true
                    if inst.type == "eraser" and v.components.health ~= nil then
                        DoEraser(inst, v)
                    else
                        if inst.caster ~= nil and inst.caster:IsValid() then
                            inst.caster.components.combat.ignorehitrange = true
                            inst.caster.components.combat:DoAttack(v)
                            inst.caster.components.combat.ignorehitrange = false
                        else
                            inst.components.combat:DoAttack(v)
                        end
                    end

                    SpawnPrefab("alterguardian_laserhit"):SetTarget(v)

                    if not v.components.health:IsDead() then
                        if v.components.freezable ~= nil then
                            if v.components.freezable:IsFrozen() then
                                v.components.freezable:Unfreeze()
                            elseif v.components.freezable.coldness > 0 then
                                v.components.freezable:AddColdness(-2)
                            end
                        end
                        if v.components.temperature ~= nil then
                            local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                            local curtemp = v.components.temperature:GetCurrent()
                            if maxtemp > curtemp then
                                v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                            end
                        end
                        if v.components.sanity ~= nil then
                            v.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY)
                        end
                    end
                end
            end
        end
    end
    inst.components.combat.ignorehitrange = false

    -- After lasering stuff, try tossing any leftovers around.
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, LAUNCH_MUST_TAGS, LAUNCH_CANT_TAGS)) do
        if not skiptoss[v] then
            local range = RADIUS + v:GetPhysicsRadius(.5)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if v.components.mine ~= nil then
                    targets[v] = true
                    skiptoss[v] = true
                    v.components.mine:Deactivate()
                end
                if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
                    targets[v] = true
                    skiptoss[v] = true
                    Launch(v, inst, LAUNCH_SPEED)
                end
            end
        end
    end

    -- If the laser hit a boat, do boat stuff!
    local platform_hit = TheWorld.Map:GetPlatformAtPoint(x, 0, z)
    if platform_hit then
        local dsq_to_boat = platform_hit:GetDistanceSqToPoint(x, 0, z)
        if dsq_to_boat < TUNING.GOOD_LEAKSPAWN_PLATFORM_RADIUS then
            platform_hit:PushEvent("spawnnewboatleak",
                { pt = Vector3(x, 0, z), leak_size = "small_leak", playsoundfx = true })
        end
        platform_hit.components.health:DoDelta(-1 * TUNING.ALTERGUARDIAN_PHASE3_LASERDAMAGE / 10)
    end
end
local function Trigger(inst, delay, targets, skiptoss, skipscorch)
    if inst.task ~= nil then
        inst.task:Cancel()
        if (delay or 0) > 0 then
            inst.task = inst:DoTaskInTime(delay, DoDamage, targets or {}, skiptoss or {}, skipscorch)
        else
            DoDamage(inst, targets or {}, skiptoss or {}, skipscorch)
        end
    end
end


AddPrefabPostInit("alterguardian_laser", function(inst)
    inst.type = nil
    inst.Trigger = Trigger
end)


local function SpawnEraserBeam(inst, target_pos)
    if target_pos == nil then
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()

    -- This is the "step" of fx spawning that should align with the position the beam is targeting.

    local angle = nil

    -- gx, gy, gz is the point of the actual first beam fx
    local gx, gy, gz = nil, 0, nil
    local x_step = STEP

    angle = math.atan2(iz - target_pos.z, ix - target_pos.x)

    gx, gy, gz = inst.Transform:GetWorldPosition()
    gx = gx + (2 * math.cos(angle))
    gz = gz + (2 * math.sin(angle))

    local targets, skiptoss = {}, {}
    local x, z = nil, nil
    local trigger_time = nil


    local i = -1
    while i < 40 do
        i = i + 1
        x = gx - i * x_step * math.cos(angle)
        z = gz - i * STEP * math.sin(angle)

        local first = (i == 0)
        local prefab = (i > 0 and "alterguardian_laser") or "alterguardian_laserempty"
        local x1, z1 = x, z

        trigger_time = (math.max(0, i - 1) * FRAMES) * 0.2
        inst:DoTaskInTime(trigger_time, function(inst2)
            local fx = SpawnPrefab(prefab)
            fx.caster = inst2
            fx.type = "eraser"
            fx.Transform:SetPosition(x1, 0, z1)
            fx:Trigger(0, targets, skiptoss)
            if first then
                ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .2, target_pos or fx, 30)
            end
        end)
        if i % 4 == 0 and i > 0 then
            local spell = SpawnPrefab("deer_fire_circle")
            spell.Transform:SetPosition(x1, 0, z1)
            spell:DoTaskInTime(trigger_time + 20, spell.KillFX)
        end
    end
end


local function FindHolyLightTarget(inst, target)
    local targets = {}
    if target and target:IsValid() then
        table.insert(targets, target)
    end
    local ix, _, iz = inst.Transform:GetWorldPosition()
    for i, p in ipairs(AllPlayers) do
        local dsq_to_player = p:GetDistanceSqToPoint(ix, 0, iz)
        if dsq_to_player < 36 * 36
            and not p:HasTag("playerghost") and p ~= target then
            table.insert(targets, p)
        end
    end
    return targets, next(targets) ~= nil
end



local function SummonHolyLight(inst, target, num, radius)
    if target and target:IsValid() then
        local x, _, z = target.Transform:GetWorldPosition()
        local angle = 360 * math.random()
        local angle_delta = 360 / num
        for i = 1, num do
            local projectile = SpawnPrefab("alter_light")
            projectile.Transform:SetPosition(x + radius * math.cos(angle * DEGREES), 0,
                z - radius * math.sin(angle * DEGREES))
            angle = angle + angle_delta
        end
        SpawnPrefab("alter_light").Transform:SetPosition(x, 0, z)
    end
end


local function HolyLightAttack(inst)
    local targets = inst.sg.statemem.targets
    for k, v in pairs(targets) do
        SummonHolyLight(inst, v, 3, 8)
    end
    inst:DoTaskInTime(1.5, function()
        for k, v in pairs(targets) do
            SummonHolyLight(inst, v, 4, 8)
        end
    end)
    inst:DoTaskInTime(3, function()
        for k, v in pairs(targets) do
            SummonHolyLight(inst, v, 6, 8)
        end
    end)
end


AddStategraphPostInit("alterguardian_phase3", function(sg)
    sg.events["doattack"].fn = function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)

            if not inst.components.timer:TimerExists("eraser_cd") then
                inst.sg:GoToState("eraserbeam", data.target)
            elseif not inst.components.timer:TimerExists("summon_cd") and dsq_to_target < SUMMON_DSQ then
                inst.sg.mem.summon_choice = not inst.sg.mem.summon_choice
                inst.sg:GoToState(inst.sg.mem.summon_choice and "atk_summon_pre" or "eraserflame", data.target)
            else
                local attack_state = "atk_stab"
                local geyser_pos = inst.components.knownlocations:GetLocation("geyser")
                if not inst.components.timer:TimerExists("traps_cd")
                    and GetTableSize(inst._traps) <= MIN_TRAP_COUNT_FOR_RESPAWN
                    and (geyser_pos == nil
                        or inst:GetDistanceSqToPoint(geyser_pos:Get()) < (TUNING.ALTERGUARDIAN_PHASE3_GOHOMEDSQ / 2)) then
                    attack_state = "atk_traps"
                elseif dsq_to_target > RANGED_ATTACK_DSQ then
                    attack_state = (math.random() > 0.5 and "atk_beam" or "atk_sweep")
                end

                inst.sg:GoToState(attack_state, data.target)
            end
        end
    end
    sg.states.atk_traps.onenter = function(inst, target)
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("attk_skybeam")
        inst.sg.statemem.skybeamanim_playing = true

        inst.components.combat:StartAttack()

        --[[if inst.components.health:GetPercent()<0.8 then
            inst.sg.statemem.targets,inst.sg.statemem.shouldholylight = FindHolyLightTarget(inst,target)
        end]]
        inst.sg:SetTimeout(9)
    end
end)


AddStategraphState("alterguardian_phase3", State {
    name = "eraserbeam",
    tags = { "attacking", "busy", "canrotate" },

    onenter = function(inst, target)
        inst.Transform:SetEightFaced()
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("idle")
        -- inst.AnimState:PlayAnimation("attk_beam")

        if inst.components.combat:TargetIs(target) then
            inst.components.combat:StartAttack()
        end
        inst.components.timer:StartTimer("eraser_cd", TUNING.ALTERGUARDIAN_PHASE3_ERASERCOOLDOWN)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst.sg.statemem.target = target
        -- inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        inst.sg.statemem.in_eraser = true
        inst.sg:SetTimeout(4)
        --inst.AnimState:SetHaunted(true)
        --inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
    end,

    onupdate = function(inst)
        if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
            local x, _, z = inst.Transform:GetWorldPosition()
            local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
            local dx, dz = x1 - x, z1 - z
            if math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                inst:ForceFacePoint(x1, y1, z1)
                return
            end
        end
    end,

    timeline =
    {
        TimeEvent(10 * FRAMES, function(inst)
            set_lightvalues(inst, 1)
            dowarning(inst)
        end),
        TimeEvent(40 * FRAMES, function(inst)
            inst.AnimState:PlayAnimation("attk_beam")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end),
        TimeEvent(68 * FRAMES, function(inst)
            set_lightvalues(inst, 0.95)
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                inst.sg.statemem.target_pos = inst.sg.statemem.target:GetPosition()
            end
            inst.sg.statemem.target = nil
        end),
        TimeEvent(72 * FRAMES, function(inst)
            local ipos = inst:GetPosition()

            local target_pos = inst.sg.statemem.target_pos
            if target_pos == nil then
                local angle = inst.Transform:GetRotation() * DEGREES
                target_pos = ipos + Vector3(OFFSET * math.cos(angle), 0, -OFFSET * math.sin(angle))
            end
            --inst.components.combat:SetDefaultDamage(100000)
            SpawnEraserBeam(inst, target_pos)
        end),
        TimeEvent(73 * FRAMES, laser_sound),

        -- TimeEvent(41 * FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
        -- TimeEvent(42 * FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
        -- TimeEvent(43 * FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        -- TimeEvent(44 * FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
        -- TimeEvent(45 * FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        -- TimeEvent(46 * FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
        -- TimeEvent(47 * FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        -- TimeEvent(48 * FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
        -- TimeEvent(49 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        -- TimeEvent(50 * FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        -- TimeEvent(51 * FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        -- TimeEvent(53 * FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        -- TimeEvent(54 * FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
        -- TimeEvent(55 * FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
        -- TimeEvent(56 * FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
        -- TimeEvent(57 * FRAMES, function(inst) set_lightvalues(inst, 0.5) end),

        -- TimeEvent(61 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        -- TimeEvent(62 * FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        -- TimeEvent(63 * FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        -- TimeEvent(64 * FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        -- TimeEvent(65 * FRAMES, function(inst) set_lightvalues(inst, 0.6) end),


        -- TimeEvent(72 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        -- TimeEvent(73 * FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        -- TimeEvent(74 * FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
    },

    ontimeout = post_attack_idle,
    onexit = function(inst)
        inst.Transform:SetSixFaced()
        inst.components.truedamage:SetBaseDamage(0)
        --inst.components.combat:SetDefaultDamage(TUNING.ALTERGUARDIAN_PHASE3_DAMAGE)
    end,
})



AddStategraphState("alterguardian_phase3", State {
    name = "eraserflame",
    tags = { "attacking", "busy", "canrotate" },

    onenter = function(inst, target)
        inst.Transform:SetEightFaced()
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("idle")

        if inst.components.combat:TargetIs(target) then
            inst.components.combat:StartAttack()
        end
        inst.components.timer:StartTimer("summon_cd", TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst.sg.statemem.target = target

        inst.sg.statemem.in_eraser = true

        dowarning(inst, true)
        inst.AnimState:SetHaunted(true)

        inst.sg:SetTimeout(8)
    end,

    onupdate = function(inst)
        -- local target = inst.sg.statemem.target
        -- if target ~= nil and target:IsValid() and
        --     target.components.health and not target.components.health:IsDead() then
        --     local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
        --     local x, _, z = inst.Transform:GetWorldPosition()
        --     local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
        --     local dx, dz = x1 - x, z1 - z
        --     if (dx * dx + dz * dz) < 900 then
        --         if inst.sg.statemem.dontkeep then
        --             local anglediff = angle - inst.Transform:GetRotation()
        --             if anglediff > 180 then
        --                 anglediff = anglediff - 360
        --             elseif anglediff < -180 then
        --                 anglediff = anglediff + 360
        --             end
        --             if math.abs(anglediff) > maxdeflect then
        --                 anglediff = math.clamp(anglediff, -maxdeflect, maxdeflect)
        --             end

        --             inst.Transform:SetRotation(inst.Transform:GetRotation() + anglediff)
        --         else
        --             inst.Transform:SetRotation(angle)
        --         end
        --         return
        --     end
        -- end
        -- if inst.sg.timeout > 0.5 then
        --     inst.sg:SetTimeout(0.5)
        -- end
        if inst.sg.statemem.clockwise ~= nil then
            inst.Transform:SetRotation(inst.Transform:GetRotation() + inst.sg.statemem.clockwise * maxdeflect)
        end
    end,

    timeline =
    {
        TimeEvent(40 * FRAMES, function(inst)
            inst.Transform:SetFourFaced()
            inst.AnimState:PlayAnimation("attk_swipe")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end),
        TimeEvent(60 * FRAMES, function(inst)
            local fx = SpawnPrefab("huge_flame_thrower")

            if fx ~= nil then
                fx.entity:SetParent(inst.entity)
                fx:SetFlamethrowerAttacker(inst)
                inst.hugeflame = fx
            else
                print("Failed to spawn huge_flame_thrower")
            end
        end),


        TimeEvent(31 * FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
        TimeEvent(32 * FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
        TimeEvent(33 * FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        TimeEvent(34 * FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
        TimeEvent(35 * FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(36 * FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
        TimeEvent(37 * FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        TimeEvent(38 * FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
        TimeEvent(39 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(40 * FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(41 * FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(42 * FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(43 * FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        TimeEvent(44 * FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
        TimeEvent(45 * FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
        TimeEvent(46 * FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
        TimeEvent(47 * FRAMES, function(inst) set_lightvalues(inst, 0.5) end),

        TimeEvent(51 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(52 * FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(53 * FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(54 * FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(55 * FRAMES, function(inst) set_lightvalues(inst, 0.6) end),

        TimeEvent(56 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(57 * FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(58 * FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(59 * FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(60 * FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        TimeEvent(61 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),

        TimeEvent(62 * FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(63 * FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        TimeEvent(64 * FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(65 * FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        TimeEvent(66 * FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
    },

    ontimeout = post_attack_idle,
    onexit = function(inst)
        if inst.hugeflame ~= nil then
            inst.hugeflame:KillFX()
            inst.hugeflame = nil
        end
        inst.Transform:SetSixFaced()
        inst.AnimState:SetHaunted(false)
    end,
})

AddPrefabPostInit("alterguardian_phase1", function(inst)
    inst.Transform:SetScale(1.1, 1.1, 1.1)
end)
AddPrefabPostInit("alterguardian_phase2", function(inst)
    inst.Transform:SetScale(1.15, 1.15, 1.15)
end)
AddPrefabPostInit("alterguardian_phase3", function(inst)
    inst.Transform:SetScale(1.2, 1.2, 1.2)
end)
