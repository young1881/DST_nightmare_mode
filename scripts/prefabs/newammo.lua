local assets =
{
    Asset("ANIM", "anim/ammo.zip"),
    Asset("IMAGE", "images/inventoryimages/newammo.tex"),
    Asset("ATLAS", "images/inventoryimages/newammo.xml"),
    Asset("IMAGE", "images/inventoryimages/glass.tex"),
    Asset("ATLAS", "images/inventoryimages/glass.xml"),
    Asset("IMAGE", "images/inventoryimages/lunarplant.tex"),
    Asset("ATLAS", "images/inventoryimages/lunarplant.xml"),
    Asset("IMAGE", "images/inventoryimages/voidcloth.tex"),
    Asset("ATLAS", "images/inventoryimages/voidcloth.xml"),
}
----------------
-- temp aggro system for the slingshots
local function no_aggro(attacker, target)
    local targets_target = target.components.combat ~= nil and target.components.combat.target or nil
    return targets_target ~= nil and targets_target:IsValid() and targets_target ~= attacker and attacker ~= nil and
        attacker:IsValid()
        and (GetTime() - target.components.combat.lastwasattackedbytargettime) < 2
        and (targets_target.components.health ~= nil and not targets_target.components.health:IsDead())
end

local function ImpactFx(inst, attacker, target) --击中特效
    if target ~= nil and target:IsValid() then
        local impactfx = SpawnPrefab(inst.ammo_def.impactfx)
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function OnAttack(inst, attacker, target)
    if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() then
        if inst.ammo_def ~= nil and inst.ammo_def.onhit ~= nil then
            inst.ammo_def.onhit(inst, attacker, target)
        end
        ImpactFx(inst, attacker, target)
    end
end

local function OnPreHit(inst, attacker, target)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil and no_aggro(attacker, target) then
        target.components.combat:SetShouldAvoidAggro(attacker)
    end
end

local function OnHit(inst, attacker, target)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        target.components.combat:RemoveShouldAvoidAggro(attacker)
    end
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    inst:Remove()
end

----------------
--子弹效果
local function SpawnGestalt(target, owner)
    local x, y, z = target.Transform:GetWorldPosition()

    local gestalt = SpawnPrefab("alterguardianhat_projectile")
    local r = GetRandomMinMax(3, 5)
    local delta_angle = GetRandomMinMax(-90, 90)
    local angle = (owner:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES
    gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
    gestalt:ForceFacePoint(x, y, z)
    gestalt:SetTargetPosition(Vector3(x, y, z))
    gestalt.components.follower:SetLeader(owner)
end

local function OnHit_Gestalt(inst, attacker, target)
    if math.random() < 0.7 then
        SpawnGestalt(target, attacker)
    end
    inst:Remove()
end

local function OnHit_Bramble(inst, attacker, target)
    local x, y, z = target.Transform:GetWorldPosition()
    local bramble = SpawnPrefab("lunarplantfx")
    bramble.Transform:SetPosition(x, y, z)
    inst:Remove()
end

local function OnHit_Voidcloth(inst, attacker, target)
    if target.components.health ~= nil and not target.components.health:IsDead() then
        local current_health = target.components.health.currenthealth

        -- 参数设置
        local threshold = 1000     -- 阈值
        local base_damage = 20     -- 基础伤害
        local linear_scale = 0.022 -- 线性伤害系数
        local log_scale = 40.5
        local log_param1 = 1000
        local log_param2 = -517
        local max_damage = 135 -- 最大伤害上限

        local final_damage

        -- 分段函数设计
        if current_health <= threshold then
            -- 低于阈值的部分，线性增长
            final_damage = base_damage + current_health * linear_scale
        else
            -- 高于阈值的部分，使用对数函数或其他平滑增长方式
            final_damage = log_scale * math.log(current_health * log_param1) + log_param2
        end

        -- 设置最大伤害上限
        final_damage = math.min(final_damage, max_damage)

        -- 对目标施加伤害
        target.components.combat:GetAttacked(inst, final_damage)
    end
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function SpawnLunarplantTentacle(target, pt, starting_angle)
    local offset = FindWalkableOffset(pt, starting_angle, 2, 3, false, true, NoHoles, false, true)
    if offset ~= nil then
        local tentacle = SpawnPrefab("lunarplanttentacle")
        if tentacle ~= nil then
            tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
            tentacle.components.combat:SetTarget(target)

            -- tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_1")
            -- tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_2")
        end
    end
end

local function OnHit_Thulecite(inst, attacker, target)
    if math.random() < .8 then
        local pt
        if target ~= nil and target:IsValid() then
            pt = target:GetPosition()
        else
            pt = inst:GetPosition()
            target = nil
        end

        local theta = math.random() * 2 * PI
        SpawnLunarplantTentacle(target, pt, theta)
    end

    inst:Remove()
end
--lunarplanttentacle

----------------
--弹道prefab
local function projectile_fn(ammo_def)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced() --?

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("ammo")                  --slingshotammo的第一个贴图
    inst.AnimState:SetBuild("ammo")
    inst.AnimState:PlayAnimation("spin_loop", true) --转的动画
    if ammo_def.symbol ~= nil then
        inst.AnimState:OverrideSymbol("rock", "ammo", ammo_def.symbol)
    end

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    if ammo_def.tags then
        for _, tag in pairs(ammo_def.tags) do
            inst:AddTag(tag)
        end
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.ammo_def = ammo_def

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(ammo_def.damage)
    inst.components.weapon:SetOnAttack(OnAttack)

    --位面伤害
    if ammo_def.planardamage then
        inst:AddComponent("planardamage")
        inst.components.planardamage:SetBaseDamage(ammo_def.planardamage)
    end

    if ammo_def.name == "slingshotammo_lunarplant" or ammo_def.name == "slingshotammo_glass" then
        local damagetypebonus = inst:AddComponent("damagetypebonus")
        damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.WEAPONS_LUNARPLANT_VS_SHADOW_BONUS)
    end

    if ammo_def.name == "slingshotammo_voidcloth" then
        local damagetypebonus = inst:AddComponent("damagetypebonus")
        damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25) --子弹速度
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnPreHitFn(OnPreHit)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 20
    inst.components.projectile.has_damage_set = true

    return inst
end

--物品prefab
local function inv_fn(ammo_def)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("ammo") --第二个贴图
    inst.AnimState:SetBuild("ammo")
    inst.AnimState:PlayAnimation("idle")
    if ammo_def.symbol ~= nil then
        inst.AnimState:OverrideSymbol("rock", "ammo", ammo_def.symbol)
        inst.scrapbook_overridedata = { "rock", "ammo", ammo_def.symbol } --暂时不知道哪里的贴图替换了就是了
    end

    inst:AddTag("molebait")
    inst:AddTag("slingshotammo")
    inst:AddTag("reloaditem_ammo")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("reloaditem")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = ammo_def.imagename
    inst.components.inventoryitem.atlasname = ammo_def.atlasname
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bait")
    MakeHauntableLaunch(inst)

    if ammo_def.fuelvalue ~= nil then
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = ammo_def.fuelvalue
    end

    if ammo_def.onloadammo ~= nil and ammo_def.onunloadammo ~= nil then
        inst:ListenForEvent("ammoloaded", ammo_def.onloadammo)
        inst:ListenForEvent("ammounloaded", ammo_def.onunloadammo)
        inst:ListenForEvent("onremove", ammo_def.onunloadammo)
    end

    return inst
end

local ammo = {
    {
        name = "slingshotammo_newammo", -- 名字
        symbol = "newammo",             --图像symbol
        onhit = nil,                    --击中特效
        damage = 34 * 2,                --伤害
        imagename = "newammo",
        atlasname = "images/inventoryimages/newammo.xml",
    },
    {
        name = "slingshotammo_glass", -- 名字
        symbol = "glass",             --图像symbol
        onhit = OnHit_Gestalt,        --击中特效
        damage = 34 * 2,              --伤害
        imagename = "glass",
        atlasname = "images/inventoryimages/glass.xml",
    },
    {
        name = "slingshotammo_lunarplant", -- 名字
        symbol = "lunarplant",             --图像symbol
        onhit = OnHit_Thulecite,           --击中特效
        damage = 34,                       --伤害
        planardamage = 34,
        imagename = "lunarplant",
        atlasname = "images/inventoryimages/lunarplant.xml",
    },
    {
        name = "slingshotammo_voidcloth", -- 名字
        symbol = "voidcloth",             --图像symbol
        onhit = OnHit_Voidcloth,          --击中特效
        damage = 0,                       --伤害
        planardamage = 34,
        imagename = "voidcloth",
        atlasname = "images/inventoryimages/voidcloth.xml",
    },
}

local ammo_prefabs = {}
for _, v in ipairs(ammo) do
    v.impactfx = "ammo_hitfx_" .. (v.symbol or "rock")

    --物品prefab
    if not v.no_inv_item then
        table.insert(ammo_prefabs, Prefab(v.name, function() return inv_fn(v) end, assets))
    end

    local prefabs =
    {
        "shatter",
    }
    --弹道prefab
    table.insert(prefabs, v.impactfx)
    table.insert(ammo_prefabs, Prefab(v.name .. "_proj", function() return projectile_fn(v) end, assets, prefabs))
end

return unpack(ammo_prefabs)
