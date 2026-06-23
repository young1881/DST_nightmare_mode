local max_health_bonus = 50 -- 铥甲加强的血量上限
-- 与 dreadsword_revival 死歌变体一致：装备时 maxhealth 为真实上限的 25%
local DEATHSONG_MAX_HEALTH_MULT = 0.25

local function ApplyArmorRuinsMaxHealthDelta(owner, delta)
    if owner.components.health == nil then
        return
    end
    local percent = owner.components.health:GetPercent()
    local minhealth = owner.components.health.minhealth or 1

    if owner._nm_deathsong_orig_max ~= nil then
        owner._nm_deathsong_orig_max = math.max(1, owner._nm_deathsong_orig_max + delta)
        owner.components.health.maxhealth = math.max(
            minhealth, owner._nm_deathsong_orig_max * DEATHSONG_MAX_HEALTH_MULT)
    else
        owner.components.health.maxhealth = math.max(
            minhealth, owner.components.health.maxhealth + delta)
    end
    owner.components.health:SetPercent(percent)
end

AddPrefabPostInit("armorruins", function(inst)
    local function onequip(inst, owner)
        if inst._oldonequipfn ~= nil then
            inst._oldonequipfn(inst, owner)
        end

        if owner.components.sanity ~= nil then
            owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.5)
        end

        if owner.components.health ~= nil and not owner.armorruins_bonus then
            local base_max = owner._nm_deathsong_orig_max or owner.components.health.maxhealth
            if base_max < 150 then
                ApplyArmorRuinsMaxHealthDelta(owner, max_health_bonus)
                owner.armorruins_bonus = true
            end
        end
    end

    local function onunequip(inst, owner)
        if inst._oldunequipfn ~= nil then
            inst._oldunequipfn(inst, owner)
        end

        if owner.components.sanity ~= nil then
            owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
        end

        if owner.components.health ~= nil and owner.armorruins_bonus then
            ApplyArmorRuinsMaxHealthDelta(owner, -max_health_bonus)
            owner.armorruins_bonus = nil
        end
    end

    inst:AddTag("poison_immune")
    inst:AddTag("soul_protect")

    if not TheWorld.ismastersim then
        return inst
    end

    inst._oldonequipfn = inst.components.equippable.onequipfn
    inst._oldunequipfn = inst.components.equippable.onunequipfn

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.components.equippable.insulated = true
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(5)
end)


-------------------------------------------------------------

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function SafeAoetargetingSetEnabled(aoetargeting, enabled)
    if aoetargeting == nil then
        return
    end
    if TheWorld.ismastersim then
        if aoetargeting.enabled:value() ~= enabled then
            aoetargeting.enabled:set(enabled)
        end
    end
end

local function SpellFn(inst, doer, pos)
    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), 5.5)
    inst.components.rechargeable:Discharge(8)
end

local function OnParry(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)
    doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")

    doer:AddTag("curse_immune")
    doer:DoTaskInTime(0.3, function()
        if doer:IsValid() then
            doer:RemoveTag("curse_immune")
        end
    end)
    if inst.components.rechargeable:GetPercent() < 0.7 then
        inst.components.rechargeable:SetPercent(0.7)
    end
end


local function OnDischarged(inst)
    SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)
end

local function OnCharged(inst)
    SafeAoetargetingSetEnabled(inst.components.aoetargeting, true)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_sword_buster", "swap_sword_buster")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    if inst.components.rechargeable:GetTimeToCharge() < 2 then
        inst.components.rechargeable:Discharge(2)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end


PREFAB_SKINS.ruins_bat = nil
AddPrefabPostInit("ruins_bat", function(inst)
    inst.AnimState:SetBank("sword_buster")
    inst.AnimState:SetBuild("sword_buster")
    inst.AnimState:PlayAnimation("idle")



    --parryweapon (from parryweapon component) added to pristine state for optimization
    inst:AddTag("parryweapon")
    inst:AddTag("battleshield")
    --rechargeable (from rechargeable component) added to pristine state for optimization
    inst:AddTag("rechargeable")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
    inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true



    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(10)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst.components.inventoryitem:ChangeImageName("lavaarena_heavyblade")

    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(178)
    --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)
end)



AddPrefabPostInit("thurible", function(inst)
    local function UpdateSnuff(inst, owner)
        local x, y, z = owner.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, 5, nil, { "INLIMBO" }, { "cs_soul" })) do
            if v:IsValid() and not v:IsInLimbo() then
                owner.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
                local fxprefab = SpawnPrefab("channel_absorb_embers")
                fxprefab.Follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)
                v.AnimState:PlayAnimation("idle_pst")
                v:DoTaskInTime(10 * FRAMES, function()
                    if not owner.components.health:IsDead() then
                        owner.components.inventory:GiveItem(v, nil, owner:GetPosition())
                    end
                    v.AnimState:PlayAnimation("idle_pre")
                    v.AnimState:PushAnimation("idle_loop", true)
                end)
            end
        end
    end
    local function onequip_2(inst, data)
        if inst.snuff_task then
            inst.snuff_task:Cancel()
        end
        if data.owner and data.owner:HasTag("player") then
            inst.snuff_task = inst:DoPeriodicTask(0.5, UpdateSnuff, nil, data.owner)
        end
    end
    local function onunequip_2(inst, data)
        if inst.snuff_task then
            inst.snuff_task:Cancel()
            inst.snuff_task = nil
        end
    end
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("equipped", onequip_2)
    inst:ListenForEvent("unequipped", onunequip_2)
end)

Recipe2("multitool_axe_pickaxe",
    { Ingredient("goldenaxe", 1), Ingredient("goldenpickaxe", 1), Ingredient("thulecite", 2), Ingredient("hammer", 1) },
    TECH.ANCIENT_FOUR, { nounlock = true })

TUNING.MULTITOOL_AXE_PICKAXE_USES = 1000
-- ===========================================================================
-- 1. 基础配置
-- ===========================================================================

local COOLDOWN_TIME = 4 -- 技能冷却时间（秒）
local GROUND_POUND_DAMAGE = 30
local GROUND_POUND_RADIUS = 4
local GROUND_POUND_MIGHTINESS_COST = 5
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }
local AOE_RANGE_PADDING = 3

local COLLAPSIBLE_WORK_ACTIONS = {
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k .. "_workable")
end
local NON_COLLAPSIBLE_TAGS = { "FX", "DECOR", "INLIMBO" }

local TWOPI = 2 * math.pi

-- ===========================================================================
-- 2. 辅助函数 (AOE与破坏)
-- ===========================================================================

local function GetGroundPoundPoints(pt, numRings, initialRadius, radiusStepDistance, pointDensity)
    local points = {}
    local radius = initialRadius
    for i = 1, numRings do
        local r = math.max(0, radius)
        local numPoints = math.floor(TWOPI * r * pointDensity)
        if i == 1 and numPoints <= 4 then numPoints = 1 end
        if not points[i] then points[i] = {} end
        if numPoints > 1 then
            for p = 1, numPoints do
                local theta = (TWOPI / numPoints) * p
                local x = pt.x + r * math.cos(theta)
                local z = pt.z + r * math.sin(theta)
                table.insert(points[i], Vector3(x, 0, z))
            end
        else
            table.insert(points[i], Vector3(pt.x, 0, pt.z))
        end
        radius = radius + radiusStepDistance
    end
    return points
end

local function DestroyStuff(pos, doer)
    local x, y, z = pos:Get()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, GROUND_POUND_RADIUS, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)) do
        if v:IsValid() and not v:IsInLimbo() and v.components.workable ~= nil then
            local work_action = v.components.workable:GetWorkAction()
            if (work_action == nil and v:HasTag("NPC_workable")) or
                (v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id]) then
                SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
                v.components.workable:Destroy(doer)
            end
        end
    end
end

local function DoGroundPoundAOE(doer, pos)
    if not TheWorld.ismastersim then return end

    local x, y, z = pos:Get()
    DestroyStuff(pos, doer)

    local numRings = 3
    local initialRadius = 1
    local radiusStepDistance = 1.5
    local pointDensity = 0.3
    local points = GetGroundPoundPoints(pos, numRings, initialRadius, radiusStepDistance, pointDensity)
    local map = TheWorld.Map
    for i = 1, numRings do
        for _, point in ipairs(points[i]) do
            if map:IsLandTileAtPoint(point:Get()) and not map:IsDockAtPoint(point:Get()) then
                SpawnPrefab("groundpound_fx").Transform:SetPosition(point.x, 0, point.z)
            end
        end
    end

    doer.components.combat.ignorehitrange = true
    for i, v in ipairs(TheSim:FindEntities(x, y, z, GROUND_POUND_RADIUS + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        if v ~= doer and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = GROUND_POUND_RADIUS + v:GetPhysicsRadius(0)
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < range * range and doer.components.combat:CanTarget(v) then
                doer.components.combat:DoAttack(v, nil, nil, "electric",
                    GROUND_POUND_DAMAGE / (doer.components.combat.defaultdamage or 34))
                if not IsEntityElectricImmune(v) and (v.sg == nil or not v.sg:HasStateTag("noelectrocute")) then
                    v:PushEventImmediate("electrocute")
                end
                v:PushEvent("knockback", { knocker = doer, radius = GROUND_POUND_RADIUS, strengthmult = 1.5 })
            end
        end
    end
    doer.components.combat.ignorehitrange = false
end

-- ===========================================================================
-- 3. 瞄准逻辑 (Reticule)
-- ===========================================================================

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then return inst.components.reticule.targetpos end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

-- ===========================================================================
-- 4. 技能释放 (SpellFn) - 加入了CD消耗逻辑
-- ===========================================================================

local function SpellFn(inst, doer, pos)
    if not TheWorld.ismastersim then return false end

    -- 基础检查
    if doer == nil or doer.prefab ~= "wolfgang" then return false end
    if doer.components.mightiness == nil or doer.components.mightiness:GetState() ~= "mighty" then return false end
    if doer.components.mightiness:GetPercent() * 150 < GROUND_POUND_MIGHTINESS_COST then return false end

    -- [新增] CD 检查 (虽然 aoetargeting 会禁用，但加一层保险)
    if not inst.components.rechargeable:IsCharged() then return false end

    -- [新增] 触发冷却
    inst.components.rechargeable:Discharge(COOLDOWN_TIME)

    local player_pos = doer:GetPosition()
    if pos then doer:FacePoint(pos:Get()) end

    doer.components.mightiness:DoDelta(-GROUND_POUND_MIGHTINESS_COST)

    if doer.sg and doer.sg:HasState("jumpout") then
        doer.sg:GoToState("jumpout", pos)
    end

    if doer.SoundEmitter then
        doer.SoundEmitter:PlaySound("meta2/woodie/werebeaver_groundpound")
    end

    local fx = SpawnPrefab("groundpoundring_fx")
    if fx then
        fx.Transform:SetPosition(player_pos:Get())
        local scale = GROUND_POUND_RADIUS / 4
        fx.Transform:SetScale(scale, scale, scale)
    end

    doer:DoTaskInTime(10 * FRAMES, function()
        if doer:IsValid() then
            DoGroundPoundAOE(doer, player_pos)
            if doer.ShakeCamera then
                doer:ShakeCamera(CAMERASHAKE.FULL, 0.7, 0.02, 0.5)
            end
        end
    end)
    return true
end

-- ===========================================================================
-- 5. 注入逻辑
-- ===========================================================================

AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
    inst:AddTag("hammer")

    -- 基础组件
    if not inst.components.tool then inst:AddComponent("tool") end
    inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.PICKAXE_LUNARPLANT_EFFICIENCY)
    inst.components.tool:EnableToughWork(true)

    if not inst.components.finiteuses then
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.MULTITOOL_AXE_PICKAXE_USES)
        inst.components.finiteuses:SetUses(TUNING.MULTITOOL_AXE_PICKAXE_USES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
    end
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 3)
    inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 3)

    -- [AOE Targeting] 客户端和服务端都必须有
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleline"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelineping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)

    if not TheWorld.ismastersim then return inst end

    -- [服务端逻辑]

    -- 1. 添加 Rechargeable (CD组件)
    inst:AddComponent("rechargeable")

    -- 2. 添加 Spell (技能组件)
    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    -- 3. 核心状态更新逻辑
    --    开启条件：(持有者是Wolfgang) AND (强壮状态) AND (充能完毕)
    local function UpdateEnabled(inst, owner)
        local enabled = false

        -- 检查1: 是否为 Wolfgang 且 强壮
        if owner and owner.prefab == "wolfgang" and
            owner.components.mightiness and owner.components.mightiness:GetState() == "mighty" then
            -- 检查2: 是否冷却完毕
            if inst.components.rechargeable:IsCharged() then
                enabled = true
            end
        end

        SafeAoetargetingSetEnabled(inst.components.aoetargeting, enabled)
    end

    -- 4. 充能状态回调
    local function OnDischarged(inst)
        SafeAoetargetingSetEnabled(inst.components.aoetargeting, false) -- 进CD时强制关闭
    end

    local function OnCharged(inst)
        -- CD转好了，检查当前是否被强壮的Wolfgang装备着
        local owner = inst.components.inventoryitem:GetGrandOwner()
        UpdateEnabled(inst, owner)
    end

    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    -- 5. 装备/卸载逻辑
    if inst.components.equippable then
        local old_onequip = inst.components.equippable.onequipfn
        local old_onunequip = inst.components.equippable.onunequipfn

        inst.components.equippable:SetOnEquip(function(inst, owner)
            if old_onequip then old_onequip(inst, owner) end

            -- 装备瞬间检查一次
            UpdateEnabled(inst, owner)

            -- 监听强壮状态变化
            if owner and owner.prefab == "wolfgang" then
                if inst._mightiness_listener then
                    inst:RemoveEventCallback("mightiness_statechange", inst._mightiness_listener, owner)
                end
                inst._mightiness_listener = function(owner, data)
                    UpdateEnabled(inst, owner)
                end
                inst:ListenForEvent("mightiness_statechange", inst._mightiness_listener, owner)
            end
        end)

        inst.components.equippable:SetOnUnequip(function(inst, owner)
            if old_onunequip then old_onunequip(inst, owner) end

            SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)

            if owner and inst._mightiness_listener then
                inst:RemoveEventCallback("mightiness_statechange", inst._mightiness_listener, owner)
                inst._mightiness_listener = nil
            end
        end)
    end
end)


AddStategraphPostInit("wolfgang", function(sg)
    local old_jumpout = sg.states["jumpout"]

    local new_jumpout = State {
        name = "jumpout",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst, target_pos)
            ToggleOffPhysics(inst)
            inst.components.locomotor:Stop()

            inst.sg.statemem.heavy = inst.components.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_jumpout" or "jumpout")

            local mult = 1

            if target_pos then
                local dist = math.sqrt(inst:GetDistanceSqToPoint(target_pos:Get()))

                -- 1. 限制最大距离 (你想要的上限)
                -- 如果你想要跳得更远，除了改这个数，还要确保鼠标点得够远
                local max_dist = 20
                dist = math.min(dist, max_dist)

                -- 2. 计算倍率
                -- 这是一个经验公式：假设跳跃动作有效位移时间约为 0.5~0.6 秒
                -- 降低这个除数（例如改成 2.0），会让角色跳得更远/更快
                local base_dist_per_speed_unit = 1

                -- 计算出需要的速度倍率。
                mult = (dist / base_dist_per_speed_unit) / 1.5

                -- 3. 设定最小倍率，防止点脚下时速度为0卡住
                mult = math.max(mult, 0.5)
            end

            -- 将倍率存起来传给 Timeline
            inst.sg.statemem.jump_mult = mult

            -- 应用初始速度
            inst.Physics:SetMotorVel(4 * mult, 0, 0)
        end,

        timeline =
        {
            -- [重要] 所有的 SetMotorVel 必须乘上 mult
            -- 否则起跳虽快，几帧后就会被重置回慢速

            -- === 举重状态 ===
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(3 * (inst.sg.statemem.jump_mult or 1), 0, 0)
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(2 * (inst.sg.statemem.jump_mult or 1), 0, 0)
                end
            end),
            TimeEvent(16 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(1 * (inst.sg.statemem.jump_mult or 1), 0, 0)
                end
            end),
            TimeEvent(12.2 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    if inst.sg.statemem.isphysicstoggle then ToggleOnPhysics(inst) end
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
                end
            end),

            -- === 正常状态 (最关键的部分) ===
            TimeEvent(10 * FRAMES, function(inst)
                if not inst.sg.statemem.heavy then
                    -- 原版是3，必须乘以倍率，否则会急刹车
                    inst.Physics:SetMotorVel(3 * (inst.sg.statemem.jump_mult or 1), 0, 0)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.heavy then
                    -- 原版是2
                    inst.Physics:SetMotorVel(2 * (inst.sg.statemem.jump_mult or 1), 0, 0)
                end
            end),
            TimeEvent(17 * FRAMES, function(inst)
                -- 落地前的最后冲刺
                local base = inst.sg.statemem.heavy and .5 or 1
                inst.Physics:SetMotorVel(base * (inst.sg.statemem.jump_mult or 1), 0, 0)
            end),

            -- === 落地特效 ===
            TimeEvent(15.2 * FRAMES, function(inst)
                if not inst.sg.statemem.heavy then
                    if inst.sg.statemem.isphysicstoggle then ToggleOnPhysics(inst) end
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
                end
            end),


            TimeEvent(18 * FRAMES, function(inst)
                inst.Physics:Stop()
            end),
        },

        events = old_jumpout.events,
        onexit = old_jumpout.onexit,
    }

    sg.states["jumpout"] = new_jumpout
end)
