TUNING.BEAVER_ABSORPTION = 0.9

local wudi_duration = 0.6   --无敌盾持续时间
local cooldown_duration = 4 --这段时间内无敌盾不会重复触发

local function UpdataHealth(inst, num)
    if inst.components.health then
        local old = inst.components.health:GetPercent()
        inst.components.health.maxhealth = inst.components.health.maxhealth + num
        inst.components.health:SetPercent(old)
    end
end

local skilltreedefs = require "prefabs/skilltree_defs"

if skilltreedefs and skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS["woodie"] and skilltreedefs.SKILLTREE_DEFS["woodie"]["woodie_allegiance_lunar"] then
    local oldonactivate = skilltreedefs.SKILLTREE_DEFS["woodie"]["woodie_allegiance_lunar"].onactivate
    skilltreedefs.SKILLTREE_DEFS["woodie"]["woodie_allegiance_lunar"].onactivate = function(inst, ...)
        if oldonactivate then
            oldonactivate(inst, ...)
        end
        UpdataHealth(inst, 50)
    end

    local oldondeactivate = skilltreedefs.SKILLTREE_DEFS["woodie"]["woodie_allegiance_lunar"].ondeactivate
    skilltreedefs.SKILLTREE_DEFS["woodie"]["woodie_allegiance_lunar"].ondeactivate = function(inst, ...)
        if oldondeactivate then
            oldondeactivate(inst, ...)
        end
        UpdataHealth(inst, -50)
    end
end

local function FnDecorator(obj, key, beforeFn, afterFn, isUseBeforeReturn)
    assert(type(obj) == "table")
    assert(beforeFn == nil or type(beforeFn) == "function", "beforeFn must be nil or a function")
    assert(afterFn == nil or type(afterFn) == "function", "afterFn must be nil or a function")

    local oldVal = obj[key]

    obj[key] = function(...)
        local retTab, isSkipOld, newParam, r
        if beforeFn then
            retTab, isSkipOld, newParam = beforeFn(...)
        end

        if type(oldVal) == "function" and not isSkipOld then
            if newParam ~= nil then
                r = { oldVal(unpack(newParam)) }
            else
                r = { oldVal(...) }
            end
            if not isUseBeforeReturn then
                retTab = r
            end
        end

        if afterFn then
            retTab = afterFn(retTab, ...)
        end

        if retTab == nil then
            return nil
        end
        return unpack(retTab)
    end
end

local function GetStateTimelineIndex(timeline, time)
    for i, timeEvent in ipairs(timeline) do
        if timeEvent.time == time then
            return i
        end
    end
end

local function activeskill(inst, name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function ruinshat_fxanim(inst)
    if inst.wd_fx then
        inst.wd_fx.AnimState:PlayAnimation("hit")
        inst.wd_fx.AnimState:PushAnimation("idle_loop")
    end
end

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
local COLLAPSIBLE_TAGS_OCEAN = { "kelp", "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    local tag = k .. "_workable"
    table.insert(COLLAPSIBLE_TAGS, tag)
    table.insert(COLLAPSIBLE_TAGS_OCEAN, tag)
end

local NON_COLLAPSIBLE_TAGS = { "FX", "DECOR", "INLIMBO", "wall", "walkableperipheral" }

local function DoAOEWork(inst, x, z, isocean)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 3, nil, NON_COLLAPSIBLE_TAGS, isocean and COLLAPSIBLE_TAGS_OCEAN or COLLAPSIBLE_TAGS)) do
        if v:IsValid() and not v:IsInLimbo() then
            if v.prefab == "bullkelp_plant" then
                local x1, y1, z1 = v.Transform:GetWorldPosition()

                local loot = SpawnPrefab("bullkelp_root")
                loot.Transform:SetPosition(x1, 0, z1)

                if v.components.pickable and v.components.pickable:CanBePicked() then
                    loot = SpawnPrefab(v.components.pickable.product)
                    if loot then
                        loot.Transform:SetPosition(x1, 0, z1)
                        if loot.components.inventoryitem then
                            loot.components.inventoryitem:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS)
                        end
                        if loot.components.stackable and v.components.pickable.numtoharvest > 1 then
                            loot.components.stackable:SetStackSize(v.components.pickable.numtoharvest)
                        end
                    end
                end

                v:Remove()
            elseif (not v:HasTag("structure") or
                    (v.components.childspawner and not v:HasTag("playerowned")) or
                    (v:HasTag("statue") and not v:HasTag("sculpture")) or
                    v:HasTag("smashable")
                )
            then
                local isworkable = false
                if v.components.workable then
                    local work_action = v.components.workable:GetWorkAction()
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

local newamount = TUNING.SKILLS.WOODIE.MOOSE_HEALTH_REGEN.amount * 2.5

AddComponentPostInit("health", function(self)
    local oldAddRegenSource = self.AddRegenSource

    self.AddRegenSource = function(self, source, amount, period, key, ...)
        if key == "weremoose_skill" and activeskill(self.inst, "woodie_allegiance_shadow") then
            return oldAddRegenSource(self, source, newamount, period, key, ...)
        end
        return oldAddRegenSource(self, source, amount, period, key, ...)
    end
end)

local INSTANT_TARGET_MUST_HAVE_TAGS = { "_combat", "_health" }
local INSTANT_TARGET_CANTHAVE_TAGS = { "INLIMBO", "epic", "structure", "butterfly", "wall", "balloon", "groundspike",
    "smashable", "companion" }

local function HasFriendlyLeader(target, singer, PVP_enabled)
    local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil

    if target_leader and target_leader.components.inventoryitem then
        target_leader = target_leader.components.inventoryitem:GetGrandOwner()
        -- Don't attack followers if their follow object has no owner, unless its pvp, then there are no rules!
        if target_leader == nil then
            return not PVP_enabled
        end
    end

    return (target_leader ~= nil and (target_leader == singer or (not PVP_enabled and target_leader:HasTag("player"))))
        or (not PVP_enabled and target.components.domesticatable and target.components.domesticatable:IsDomesticated())
        or (not PVP_enabled and target.components.saltlicker and target.components.saltlicker.salted)
end

local function AddEnemyDebuffFx(fx, target)
    target:DoTaskInTime(math.random() * 0.25, function()
        local x, y, z = target.Transform:GetWorldPosition()
        local fx = SpawnPrefab(fx)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end

        return fx
    end)
end

local function wudisg(sg)
    local Timeline = sg.states["attack"].timeline
    FnDecorator(Timeline[GetStateTimelineIndex(Timeline, 7 * FRAMES)], "fn", function(inst)
        if inst.sg.statemem.ismoose then
            if inst.sg.statemem.ismoosesmash then
                if activeskill(inst, "woodie_allegiance_shadow") then
                    TUNING.SKILLS.WOODIE.MOOSE_SMASH_DAMAGE = 34 * 4 + 10
                    TUNING.SKILLS.WOODIE.MOOSE_SMASH_PLANAR_DAMAGE = 90
                    -- 恐慌效果
                    local x, y, z = inst.Transform:GetWorldPosition()
                    if math.random() < 0.5 then
                        local entities_near_me = TheSim:FindEntities(x, y, z, TUNING.BATTLESONG_ATTACH_RADIUS,
                            INSTANT_TARGET_MUST_HAVE_TAGS, INSTANT_TARGET_CANTHAVE_TAGS)
                        for _, ent in ipairs(entities_near_me) do
                            if inst.components.combat:CanTarget(ent)
                                and not HasFriendlyLeader(ent, inst, PVP_enabled)
                                and (not ent:HasTag("prey") or (ent:HasTag("prey") and ent:HasTag("hostile"))) then
                                if ent.components.hauntable ~= nil and ent.components.hauntable.panicable then
                                    ent.components.hauntable:Panic(TUNING.BATTLESONG_PANIC_TIME)
                                    AddEnemyDebuffFx("battlesong_instant_panic_fx", ent)
                                end
                            end
                        end
                    end
                elseif activeskill(inst, "woodie_allegiance_lunar") then
                    local pos = inst:GetPosition()
                    if inst:IsValid() then
                        local fx = SpawnPrefab("wd_projectilefx")
                        local offset = Vector3(2, 0, 0)
                        local facing_angle = inst.Transform:GetRotation() * DEGREES
                        local new_x = pos.x + offset.x * math.cos(facing_angle)
                        local new_z = pos.z - offset.x * math.sin(facing_angle)
                        fx.Transform:SetPosition(new_x, 0, new_z)
                        fx.AnimState:PlayAnimation("impact1_lunar")

                        local isocean = TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z)
                        DoAOEWork(inst, new_x, new_z, isocean)
                    end
                end
            end
        end
    end)

    FnDecorator(Timeline[GetStateTimelineIndex(Timeline, 7 * FRAMES)], "fn", nil, function(retTab, inst)
        if inst.sg.statemem.ismoose and inst.sg.statemem.ismoosesmash then
            TUNING.SKILLS.WOODIE.MOOSE_SMASH_DAMAGE = 34 * 4
            TUNING.SKILLS.WOODIE.MOOSE_SMASH_PLANAR_DAMAGE = 80
        end
    end)

    local old_tackle = sg.states["tackle_pre"]
    if old_tackle then
        local old_onenter = old_tackle.onenter
        old_tackle.onenter = function(inst, ...)
            if old_onenter then
                old_onenter(inst, ...)
            end

            if not activeskill(inst, "woodie_allegiance_lunar") then
                return
            end

            if inst.wd_on_cooldown == nil then
                inst.wd_on_cooldown = false
            end

            if not inst.wd_on_cooldown then
                if inst.wd_fx == nil then
                    inst.wd_fx = SpawnPrefab("forcefieldfx")
                    inst.wd_fx.entity:SetParent(inst.entity)
                    inst.wd_fx.Transform:SetPosition(0, 0.2, 0)
                    inst:ListenForEvent("attacked", ruinshat_fxanim)
                    inst.components.health:SetInvincible(true)
                end

                if inst.wd_fxtask ~= nil then
                    inst.wd_fxtask:Cancel()
                    inst.wd_fxtask = nil
                end

                if inst.wd_fxtask == nil then
                    inst.wd_fxtask = inst:DoTaskInTime(wudi_duration, function()
                        inst:RemoveEventCallback("attacked", ruinshat_fxanim)
                        inst.components.health:SetInvincible(false)
                        if inst.wd_fx ~= nil then
                            inst.wd_fx:Remove()
                            inst.wd_fx = nil
                        end

                        inst.wd_on_cooldown = true

                        inst:DoTaskInTime(cooldown_duration, function()
                            inst.wd_on_cooldown = false
                        end)
                    end)
                end
            end
        end
    end
end

AddStategraphPostInit("wilson", wudisg)

------------ 树枝制作 -----------
local shuzhi = AddRecipe2("woodie_twigs", { Ingredient("log", 1), Ingredient("lucy", 0) }, TECH.NONE,
    { numtogive = 2, builder_tag = "werehuman", sg_state = "carvewood_boards" }, { "CHARACTER" })
shuzhi.product = "twigs"
shuzhi.image = "twigs.tex"
STRINGS.RECIPE_DESC.TWIGS = "劈木成柴!"

local function OnMakeArmor(inst, data)
    if data.item.prefab == "twigs" then --劈树枝的特效
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        SpawnPrefab("boat_bumper_hit_kelp").Transform:SetPosition(inst.Transform:GetWorldPosition())
        for k, v in pairs(inst.components.inventory.itemslots) do
            if v.prefab == "lucy" then
                if math.random() < 0.2 then
                    if math.random() < 0.5 then
                        v.components.talker:Say("你想要树枝吗？我给你更多树枝！嘿-呀！")
                    else
                        v.components.talker:Say("伙计，别割伤了手指！")
                    end
                end
                break
            end
        end
    end
end

---------- 快速拾取 -------------
AddStategraphPostInit("wilson", function(sg) -- 服务器
    local _attack = sg.states["doshortaction"]
    local _onenter = _attack.onenter
    _attack.onenter = function(inst, ...)
        _onenter(inst, ...)
        if inst.prefab == "woodie" and inst:HasTag("woodiequickpicker") and inst.sg and inst.sg.timeout then
            local speed = 1.75
            inst.sg:SetTimeout(inst.sg.timeout / speed)                                 --override timeout
            inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD / speed) --attack cooldown
            inst.AnimState:SetDeltaTimeMultiplier(speed)                                -- time multiplier
            inst.bihuan5 = true
            for k, v in pairs(_attack.timeline) do                                      --override timeline
                v.time = v.time / speed
            end
        end
        return
    end
    local _onexit = _attack.onexit
    _attack.onexit = function(inst, ...)
        if inst.bihuan5 then
            inst.bihuan5 = false
            local speed = 1.75
            inst.AnimState:SetDeltaTimeMultiplier(1)
            for k, v in pairs(_attack.timeline) do
                v.time = v.time * speed
            end
        end
        return _onexit(inst, ...)
    end
end)

AddStategraphPostInit("wilson_client", function(sg) -- 客户端
    local _attack = sg.states["doshortaction"]
    local _onenter = _attack.onenter
    _attack.onenter = function(inst, ...)
        _onenter(inst, ...)
        if inst.prefab == "woodie" and inst:HasTag("woodiequickpicker") and inst.sg and inst.sg.timeout then
            local speed = 1.75
            inst.sg:SetTimeout(inst.sg.timeout / speed)
            inst.AnimState:SetDeltaTimeMultiplier(speed)
            inst.bihuan5 = true
            for k, v in pairs(_attack.timeline) do
                v.time = v.time / speed
            end
        end
        return
    end
end)

------------ 露西斧 ------------

local function onchopwood(inst, data)
    local action1 = data.action
    if not action1 or not (action1 == ACTIONS.CHOP or data.target:HasTag("mushtree")) then
        return
    end

    local isBeaver = inst:HasTag("beaver")
    inst.components.sanity:DoDelta(2)

    local lucy = inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local hasLucy = lucy and lucy.prefab == "lucy"

    if isBeaver or hasLucy then
        inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/ice_attack")

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 5)

        for _, v in ipairs(ents) do
            if v:HasTag("stump") and v.components.workable and not TheWorld.Map:IsFarmableSoilAtPoint(v.Transform:GetWorldPosition()) then
                v.components.workable:WorkedBy(inst, 4)
                if not isBeaver then
                    SpawnPrefab("lucy_ground_transform_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
                end
            end
        end

        if not isBeaver then
            inst:DoTaskInTime(0, function()
                local loot_list = {
                    "pinecone", "twiggy_nut", "bamboo", "vine", "bird_egg", "palmleaf", "coconut", "jungletreeseed",
                    "shyerrylog", "silk", "moon_cap", "blue_cap", "green_cap", "red_cap", "cave_banana", "charcoal",
                    "livinglog", "moonbutterfly", "moon_tree_blossom", "acorn", "palmcone_seed", "log", "twigs",
                    "palmcone_scale"
                }
                local loot_check = {}
                for _, item in ipairs(loot_list) do
                    loot_check[item] = true
                end

                local ents = TheSim:FindEntities(x, y, z, 5)
                for _, v in ipairs(ents) do
                    if loot_check[v.prefab] and v.components.inventoryitem and not v.components.inventoryitem.owner then
                        local stackable = v.components.stackable
                        if stackable and stackable:StackSize() >= 5 then
                            return
                        end
                        if inst.components.inventory:CanAcceptCount(v, 1) > 0 then
                            inst.components.inventory:GiveItem(v, nil, v:GetPosition())
                            SpawnPrefab("lucy_ground_transform_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
                        end
                    end
                end
            end)
        end
    end

    if not isBeaver and math.random() < 0.25 then
        inst.components.talker:Say(math.random() < 0.5 and "死！死！死！" or "这就是我活着的意义！")
    end

    if isBeaver then
        if inst.components.wereness then
            inst.components.wereness:DoDelta(1)
        end
        inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/ice_attack")
        SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(data.target.Transform:GetWorldPosition())
    end
end


AddPrefabPostInit("woodie", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("finishedwork", onchopwood)
    inst:ListenForEvent("builditem", OnMakeArmor)
    inst:ListenForEvent("performaction", function(inst, data) --露西砍树特效
        if data.action.action == ACTIONS.CHOP then
            if data.action.target ~= nil then
                if inst:HasTag("beaver") and data.action.target then --海狸啃树特效
                    SpawnPrefab("impact").Transform:SetPosition(data.action.target.Transform:GetWorldPosition())
                end
                local lucy = inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if lucy and lucy.prefab == "lucy" then
                    local snap111 = SpawnPrefab("lucy_transform_fx")
                    if math.random() <= 0.5 then
                        snap111 = SpawnPrefab("lucy_transform_fx")
                    else
                        snap111 = SpawnPrefab("lucy_ground_transform_fx")
                    end
                    local snax = SpawnPrefab("impact")
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local x1, y1, z1 = data.action.target.Transform:GetWorldPosition()
                    if z1 ~= nil then
                        local angle = -math.atan2(z1 - z, x1 - x)
                        snap111.Transform:SetPosition(x1, y1, z1)
                        snap111.Transform:SetRotation(angle * RADIANS)
                        snap111.Transform:SetScale(0.8, 0.8, 0.8)
                        snax.Transform:SetPosition(x1, y1, z1)
                        snax.Transform:SetRotation(angle * RADIANS)
                        snax.Transform:SetScale(0.8, 0.8, 0.8)
                    end
                end
            end
        end
    end)
end)


STRINGS.ACTIONS.CASTAOE.LUCY = "掷出露西"
local function Hitsparks(attacker, target, colour)
    local spark = SpawnPrefab("hitsparks_fx")
    spark:Setup(attacker, target, nil, colour)
    spark.red:set(true)
end

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


local function SpellFn(inst, caster, pos)
    inst.components.rechargeable:Discharge(4)
    -- if caster.components.inventory:Has("lunarplant_husk", 1) or caster.components.inventory:Has("voidcloth", 1) then
    --     inst.components.rechargeable:Discharge(2.5)
    -- else
    --     inst.components.rechargeable:Discharge(4)
    -- end
    inst:MakeProjectile()

    caster.components.inventory:DropItem(inst)
    inst.components.complexprojectile:Launch(pos, caster)

    inst:DoTaskInTime(0.125, function()
        local random_dx = {
            "芜湖！！！！！",
            "削它！",
            "伙计，你让我飞起来了！",
            "哈！！",
            "伙计，飞的准点！",
            "切碎他们！",
            "正中靶心！",
            "就像以前玩飞盘一样！",
            "一瞬间的事，别眨眼！",
            "别给我躲开！",
            "我还会回来的！",
            "我可不是害怕飞行的姑娘！" }
        local DX = math.random(1, #random_dx)
        local selected_dx = random_dx[DX]
        inst.components.talker:Say(selected_dx)
    end)
end

local function SimpleDropOnGround(inst)
    inst:Show()
    inst.components.inventoryitem.canbepickedup = true
    inst.components.scaler:ApplyScale()
    inst:MakeNonProjectile()
    inst.AnimState:PlayAnimation("idle", true)

    -- Drop on ground
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.components.inventoryitem:DoDropPhysics(x, y, z, true)
end


local function OnLaunch(inst, attacker, targetpos)
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.canbepickedup = false

    -- Personal params stored in complexprojectile
    inst.components.complexprojectile.startpos  = attacker:GetPosition()
    inst.components.complexprojectile.targetpos = targetpos

    inst.Physics:SetMotorVel(20, 0, 0)
end


local function OnHit(inst, attacker, target)
    inst.AnimState:PlayAnimation("bounce")
    inst.AnimState:PushAnimation("idle")
    if target ~= nil then
        attacker.components.combat:DoAttack(target, inst, inst, "strong", 0.6, 999, inst:GetPosition())
        Hitsparks(attacker, target, { 1, 0, 0 })
        attacker.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
        target:DoTaskInTime(0.15, function()
            attacker.components.combat:DoAttack(target, inst, inst, "strong", 0.6, 999, inst:GetPosition())
            Hitsparks(attacker, target, { 1, 0, 0 })
            attacker.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
        end)
        target:DoTaskInTime(0.4, function()
            attacker.components.combat:DoAttack(target, inst, inst, "strong", 0.6, 999, inst:GetPosition())
            Hitsparks(attacker, target, { 1, 0, 0 })
            attacker.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
        end)

        inst:GetPosition()
        -- if target.components.health and not target.components.health:IsDead() and target.sg and target.sg:HasState("hit") and not target.sg:HasStateTag("sleeping") and not target.sg:HasStateTag("grounded") and not target.sg:HasStateTag("stunned") and not target.sg:HasStateTag("tired") then
        --     target.sg:GoToState("hit")
        --     if target.prefab == "eyeofterror" or target.prefab == "twinofterror1" or target.prefab == "twinofterror2" then
        --         target.sg.statemem.fxtime = 0 --强制停球！
        --     end
        -- end
    end
    inst.Physics:SetMotorVel(5, 0, 0)

    local HIDE_TIME = 15 * FRAMES
    local PLAY_RETURN_ANIM_TIME = HIDE_TIME + 2 * FRAMES
    local TRUELY_RETURN_TIME = 12 * FRAMES

    inst:DoTaskInTime(HIDE_TIME, function()
        inst.Physics:Stop()
        inst:Hide()
        SpawnAt("lucy_transform_fx", inst)
    end)


    inst:DoTaskInTime(PLAY_RETURN_ANIM_TIME, function()
        if attacker and attacker:IsValid() then
            inst:Show()
            attacker:AddChild(inst)
            inst.Transform:SetPosition(0, 0, 0)
            inst.AnimState:PlayAnimation("return")

            --inst.Follower:FollowSymbol(attacker.GUID, "swap_object", 0, 0, 0)

            if attacker.SoundEmitter then
                attacker.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
            end

            local fx = SpawnPrefab("lucy_ground_transform_fx")
            fx.entity:SetParent(inst.entity)

            inst:DoTaskInTime(TRUELY_RETURN_TIME, function()
                --inst.Follower:StopFollowing()

                if attacker and attacker:IsValid() then
                    attacker:RemoveChild(inst)
                    inst.Transform:SetPosition(attacker:GetPosition():Get())
                    inst.components.inventoryitem.canbepickedup = true
                    inst.components.scaler:ApplyScale()
                    inst:MakeNonProjectile()
                    inst.AnimState:PlayAnimation("idle", true)

                    -- return to attacker
                    -- SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(attacker.GUID, "swap_object", 50,
                    --     -25, -1)
                    if attacker.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then --手里有东西就不强制装备
                        attacker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
                    else
                        attacker.components.inventory:Equip(inst)
                    end
                else
                    SimpleDropOnGround(inst)
                end
            end)
        else
            SimpleDropOnGround(inst)
        end
    end)
end

local function OnProjectileUpdate(inst, dt)
    dt = dt or FRAMES
    local x, y, z = inst:GetPosition():Get()
    local attacker = inst.components.complexprojectile.attacker
    if attacker == nil then
        print("Warning: attacker = nil")
        return
    end


    local WORKABLES_CANT_TAGS = { "insect", "INLIMBO" }
    local WORKABLES_ONEOF_TAGS = { "CHOP_workable" }
    local x, y, z = inst.Transform:GetWorldPosition()
    local heading_angle = inst.Transform:GetRotation() * DEGREES
    local x1, z1 = math.cos(heading_angle), -math.sin(heading_angle)

    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 1, nil, WORKABLES_CANT_TAGS, WORKABLES_ONEOF_TAGS)) do
        local x2, y2, z2 = v.Transform:GetWorldPosition()
        local dx, dz = x2 - x, z2 - z
        local len = math.sqrt(dx * dx + dz * dz)
        if len <= 0 or x1 * dx / len + z1 * dz / len > .3 then
            v.components.workable:WorkedBy(inst, 4)
            inst.components.complexprojectile:Hit() --破坏一个后直接结束
        end
    end

    if (inst:GetPosition() - inst.components.complexprojectile.startpos):Length() > 11 then
        inst.components.complexprojectile:Hit()
        return
    end

    local ents = TheSim:FindEntities(x, y, z, 1.5, { "_combat", "_health" }, { "INLIMBO" })
    for _, v in pairs(ents) do
        if attacker.components.combat:CanTarget(v)
            and not attacker.components.combat:IsAlly(v) then
            inst.components.complexprojectile:Hit(v)
            break
        end
    end

    return true
end

local function MakeProjectile(inst)
    inst:AddTag("NOCLICK")

    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("lavaarena_lucy")
    inst.AnimState:SetBuild("lavaarena_lucy")

    if not inst.components.complexprojectile then
        inst:AddComponent("complexprojectile")
    end

    inst.components.complexprojectile.onupdatefn = OnProjectileUpdate
    inst.components.complexprojectile:SetOnLaunch(OnLaunch)
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 0, 0))
end

local function MakeNonProjectile(inst)
    inst:RemoveTag("NOCLICK")

    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)

    inst.Transform:SetNoFaced()

    inst.AnimState:SetBank("lavaarena_lucy")
    inst.AnimState:SetBuild("lavaarena_lucy")

    if inst.components.complexprojectile then
        inst:RemoveComponent("complexprojectile")
    end
end

local function onattack(inst, owner, target)
    local suo = owner.replica.inventory and owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if owner and owner.sg then
        if suo == nil or (suo and suo.prefab ~= "klaus_amulet") then
            owner.sg:RemoveStateTag("attack")
            owner.sg:RemoveStateTag("abouttoattack")
        end
        if target then
            Hitsparks(owner, target, { 1, 0, 0 })
        end
        -- if owner.components.inventory then
        --     if owner.components.inventory:Has("lunarplant_husk", 1) and activeskill(owner, "woodie_allegiance_lunar") then
        --         if math.random() <= 1 / 75 then owner.components.inventory:ConsumeByName("lunarplant_husk", 1) end
        --         inst:AddComponent("planardamage")
        --         inst.components.planardamage:SetBaseDamage(17)
        --         Hitsparks(owner, target, { 1, 0, 0 })
        --         Hitsparks(owner, target, { 1, 0, 0 })
        --     else
        --         if owner.components.inventory:Has("voidcloth", 1) and activeskill(owner, "woodie_allegiance_shadow") then
        --             if math.random() <= 1 / 75 then owner.components.inventory:ConsumeByName("voidcloth", 1) end
        --             inst:AddComponent("planardamage")
        --             inst.components.planardamage:SetBaseDamage(17)
        --             Hitsparks(owner, target, { 1, 0, 0 })
        --             Hitsparks(owner, target, { 1, 0, 0 })
        --         else
        --             if inst.components.planardamage then
        --                 inst:RemoveComponent("planardamage")
        --             end
        --         end
        --     end
        -- end
    end

    if inst and inst.components.talker then
        local random_dx = {
            "正中目标！",
            "击中这个！",
            "伙计，斩击它的弱点！",
            "哈！",
            "我们会把你像树一样砍倒！",
            "伙计，狠狠的拷打它们！",
            "砍断切开剁碎！！！" }
        local DX = math.random(1, #random_dx)
        local selected_dx = random_dx[DX]
        if math.random() <= 0.5 and inst.shuohua then
            inst.components.talker:Say(selected_dx)
            inst.shuohua = false
            inst:DoTaskInTime(5, function() inst.shuohua = true end)
        end
    end
    if target:HasTag("plant") or target.prefab == "lunarthrall_plant_back" or target.prefab == "lunarthrall_plant_vine_end" or target.prefab == "leif" or target.prefab == "lunarthrall_plant" or target.prefab == "leif_sparse" or target.prefab == "stumpling" or target.prefab == "birchling" or target.prefab == "birchnutdrake" then
        if target.components.combat and not target.components.health:IsDead() then
            if math.random() < 0.05 then
                if math.random() < 0.5 then
                    owner.components.talker:Say("露西，剁碎这些会动的木头！")
                    inst.components.talker:Say("砍砍——砍！！该死的活着的植物！！")
                else
                    owner.components.talker:Say("你也会像你那些不会动的兄弟一样倒下！")
                    inst.components.talker:Say("伙计，狠狠的把它们砍碎！")
                end
            end
            target.components.combat:GetAttacked(owner, 42.5)
        end
    end
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

AddPrefabPostInit("lucy", function(inst)
    inst:AddTag("throw_line")
    inst:AddTag("chop_attack")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
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

    inst:ListenForEvent("floater_stopfloating", OnStopFloating)

    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED
    inst.components.inventoryitem.canonlygoinpocket = true

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)


    if inst.components.weapon ~= nil then
        inst.components.weapon:SetDamage(27.2)
        inst.components.weapon:SetOnAttack(onattack)
    end

    inst.MakeProjectile = MakeProjectile
    inst.MakeNonProjectile = MakeNonProjectile

    inst:AddComponent("scaler")
    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst.shuohua = true
    inst:AddComponent("waterproofer") --防水
    inst.components.waterproofer:SetEffectiveness(0)

    local oldonequipfn = inst.components.equippable.onequipfn
    local oldonunequipfn = inst.components.equippable.onunequipfn

    local function newonequip(inst, owner) --赋予伍迪不脱手buff
        owner:AddTag("stronggrip")
        owner:AddTag("lucyshouchi")
        owner.components.combat:SetAttackPeriod(0) -- 将攻速从2.5提高到3.3的关键
        oldonequipfn(inst, owner)
    end

    local function newonunequip(inst, owner)
        if owner.armorrepair == nil then --战歌生效时不会取消掉
            owner:RemoveTag("stronggrip")
        end
        owner:RemoveTag("lucyshouchi")
        owner.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
        oldonunequipfn(inst, owner)
    end

    inst.components.equippable:SetOnEquip(newonequip)
    inst.components.equippable:SetOnUnequip(newonunequip)
end)
