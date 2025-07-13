local RuinsRespawner = require "prefabs/ruinsrespawner"
local assets =
{
    Asset("ANIM", "anim/eyeball_turret.zip"),
    Asset("ANIM", "anim/eyeball_turret_object.zip"),
}

local prefabs =
{
    "eye_charge",
    "shadoweyeturret_base",
    "thulecite"
}

local brain = require "brains/eyeturretbrain"

local GEMCOLOUR = {
    red = { 1, 0, 0, 1 },
    blue = { 0, 0, 1, 1 },
    purple = { 128 / 255, 0, 128 / 255, 1 },
    yellow = { 1, 1, 0, 1 },
    orange = { 1, 165 / 255, 0, 1 },
    green = { 0, 128 / 255, 0, 1 }
}

local function triggerlight(inst)
    if inst._lightframe ~= nil then
        if inst.OnLightDirty then
            inst:OnLightDirty()
        else
            print("Error: OnLightDirty function is not defined")
        end
    else
        print("Error: _lightframe is nil")
        -- 初始化 _lightframe 或执行其他错误处理
        inst._lightframe = net_smallbyte(inst.GUID, "ruinseyeturret._lightframe", "lightdirty")
    end
end

local function retargetfn(inst)
    local target = inst.components.combat.target
    if target ~= nil and
        target:IsValid() and
        inst:IsNear(target, TUNING.EYETURRET_RANGE + 3) then
        --keep current target
        return
    end
    for i, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") then
            local distsq = v:GetDistanceSqToInst(inst)
            if distsq < inst.targetdsq and inst.components.combat:CanTarget(v) then
                return v, true
            end
        end
    end
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and not target:HasTag("shadow_aligned")
        and inst:IsNear(target, 26)
end

local function ShareTargetFn(dude)
    return dude:HasTag("chess")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil then
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, 30, ShareTargetFn, 8)
    end
end

SetSharedLootTable("ruinsnightmare",
    {
        { "nightmarefuel", 1.00 },
        { "nightmarefuel", 1.00 },
        { "nightmarefuel", 0.50 },
        { "nightmarefuel", 0.25 },
    })

local states = {
    red = function(inst, target, damageredirecttarget)
        if target.components.temperature ~= nil then
            target.components.temperature:DoDelta(40)
        end
        if damageredirecttarget ~= nil then
            return
        end
        if target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
            if target.components.burnable.canlight or target.components.combat ~= nil then
                target.components.burnable:Ignite(true, inst)
            end
        end
        -- if target.components.grogginess then
        --     target.components.grogginess:AddGrogginess(3, TUNING.MANDRAKE_SLEEP_TIME)
        -- end

        local x, y, z = target.Transform:GetWorldPosition()
        for i = 1, 4 do
            local offset = 1 + (i - 1) * 0.4
            local angle = (i - 1) * (360 / 4) * DEGREES
            local offset_x = math.cos(angle) * offset
            local offset_z = math.sin(angle) * offset
            local houndfire = SpawnPrefab("houndfire")
            houndfire.Transform:SetPosition(x + offset_x, y, z + offset_z)
        end
    end,

    blue = function(inst, target, damageredirecttarget)
        local canFreezeTarget = target.components.freezable ~= nil and target:IsValid()
        if canFreezeTarget then
            target.components.freezable:AddColdness(1)
        end

        if damageredirecttarget then
            return
        end

        local target_x, target_y, target_z = target.Transform:GetWorldPosition()
        local nearbyEntities = TheSim:FindEntities(target_x, target_y, target_z, 6, { "player" })
        for _, ent in ipairs(nearbyEntities) do
            local canFreeze = ent.components.freezable ~= nil and ent:IsValid() and ent ~= target
            if canFreeze then
                ent.components.freezable:AddColdness(1)
            end
        end

        local x, y, z = target.Transform:GetWorldPosition()
        local center_spell = SpawnPrefab("deer_ice_circle")
        center_spell.Transform:SetPosition(x, 0, z)
        if center_spell.TriggerFX then
            center_spell:DoTaskInTime(8, center_spell.TriggerFX)
        end
        center_spell:DoTaskInTime(10, center_spell.KillFX)
    end,

    purple = function(inst, target, damageredirecttarget)
        if damageredirecttarget == nil and target.components.sanity ~= nil then
            target.components.sanity:DoDelta(-20)
        end

        local x, y, z = target.Transform:GetWorldPosition()
        local nightmare_prefabs = { "crawlingnightmare", "nightmarebeak", "ruinsnightmare" }
        for i, prefab in ipairs(nightmare_prefabs) do
            local offset = 1 + (i - 1) * 0.3
            local angle = (i - 1) * (360 / #nightmare_prefabs) * DEGREES
            local offset_x = math.cos(angle) * offset
            local offset_z = math.sin(angle) * offset

            local nightmare = SpawnPrefab(prefab)
            nightmare.Transform:SetPosition(x + offset_x, y, z + offset_z)

            if prefab == "crawlingnightmare" and nightmare ~= nil then
                nightmare.components.health:SetMaxHealth(150)
            end

            if prefab == "nightmarebeak" and nightmare ~= nil then
                nightmare.components.health:SetMaxHealth(200)
            end

            if prefab == "ruinsnightmare" and nightmare ~= nil then
                if nightmare.components.planarentity ~= nil then
                    nightmare:RemoveComponent("planarentity")
                    nightmare:RemoveComponent("planardamage")
                end

                nightmare.components.health:SetMaxHealth(425)

                if nightmare.components.lootdropper ~= nil then
                    nightmare.components.lootdropper:SetChanceLootTable("ruinsnightmare")
                end

                if nightmare.components.locomotor ~= nil then
                    nightmare.components.locomotor.walkspeed = TUNING.RUINSNIGHTMARE_SPEED
                end

                nightmare.AnimState:HideSymbol("red")
                nightmare.AnimState:SetLightOverride(0)
                nightmare.AnimState:SetMultColour(1, 1, 1, 0.5)
            end
        end
    end,

    yellow = function(inst, target)
        if target.isplayer then
            target:ScreenFade(false)
            target:ScreenFade(true, 8, false)
        elseif target.components.hauntable ~= nil and target.components.hauntable.panicable then
            target.components.hauntable:Panic(15)
        end

        local function SummonHolyLight(attacker, target, num, radius)
            if target and target:IsValid() then
                local x, _, z = target.Transform:GetWorldPosition()
                local angle = math.random() * 360
                local angle_delta = 360 / num

                for i = 1, num do
                    local fx_x = x + radius * math.cos(angle * DEGREES)
                    local fx_z = z - radius * math.sin(angle * DEGREES)
                    angle = angle + angle_delta

                    local fx = SpawnPrefab("small_alter_light")
                    if fx then
                        fx.Transform:SetPosition(fx_x, 0, fx_z)
                    end
                end

                local center_fx = SpawnPrefab("small_alter_light")
                if center_fx then
                    center_fx.Transform:SetPosition(x, 0, z)
                end
            end
        end

        SummonHolyLight(inst, target, 3, 6)
    end,

    orange = function(inst, target, damageredirecttarget)
        local x, y, z = target.Transform:GetWorldPosition()
        local radius = 5.5        -- 半径
        local num_sandblocks = 14 -- 沙堡数量
        local spacing = 1.5       -- 间隔

        for i = 1, num_sandblocks do
            local angle = (i - 1) * (360 / num_sandblocks) * DEGREES
            local offset_x = math.cos(angle) * radius
            local offset_z = math.sin(angle) * radius

            local sandblock = SpawnPrefab("sandblock")
            sandblock.Transform:SetPosition(x + offset_x, y, z + offset_z)
        end

        local x, y, z = target.Transform:GetWorldPosition()
        for i = 1, 3 do
            local offset = 1 + (i - 1) * 0.5
            local angle = (i - 1) * (360 / 3) * DEGREES
            local offset_x = math.cos(angle) * offset
            local offset_z = math.sin(angle) * offset

            local houndfire = SpawnPrefab("antlion_sinkhole")
            houndfire.Transform:SetPosition(x + offset_x, y, z + offset_z)
            local delay_time = 15
            houndfire:DoTaskInTime(delay_time, function()
                if houndfire and houndfire.entity and houndfire.entity:IsValid() then
                    houndfire:Remove()
                end
            end)
        end

        -- local center_spell = SpawnPrefab("deer_fire_circle")
        -- center_spell.Transform:SetPosition(x, 0, z)
        -- if center_spell.TriggerFX then
        --     center_spell:DoTaskInTime(2.5, center_spell.TriggerFX)
        -- end
        -- center_spell:DoTaskInTime(20, center_spell.KillFX)
    end,

    green = function(inst, target, damageredirecttarget)
        if target.components.inventory ~= nil then
            for _, equip_slot in ipairs({ EQUIPSLOTS.BODY, EQUIPSLOTS.HEAD, EQUIPSLOTS.HANDS }) do
                local item = target.components.inventory:GetEquippedItem(equip_slot)
                if item ~= nil and item.components.armor ~= nil and item.components.armor.condition > 0 then
                    local half = math.floor(item.components.armor.condition * 0.9)
                    item.components.armor:SetCondition(half)
                end
            end
        end
        local x, y, z = target.Transform:GetWorldPosition()
        local center_spell = SpawnPrefab("sporecloud")
        center_spell.Transform:SetPosition(x, 0, z)
    end

}

local function gemmagic(inst, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
    local gem = inst.colours[inst.gemindex]
    if target:IsValid() and not target.components.health:IsDead() then
        states[gem](inst, target, damageredirecttarget)
    end
end

local function EquipWeapon(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        weapon.persists = false

        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange + 4)
        weapon.components.weapon:SetProjectile("eye_charge")

        weapon:AddComponent("inventoryitem")
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)

        weapon:AddComponent("equippable")
        inst.components.inventory:Equip(weapon)
    end
end

local function syncanim(inst, animname, loop)
    inst.AnimState:PlayAnimation(animname, loop)
    inst.base.AnimState:PlayAnimation(animname, loop)
end

local function syncanimpush(inst, animname, loop)
    inst.AnimState:PushAnimation(animname, loop)
    inst.base.AnimState:PushAnimation(animname, loop)
end

local telebase_parts =
{
    { x = -1.6, z = -1.6 },
    { x = 2.7,  z = -0.8 },
    { x = -0.8, z = 2.7 },
}

local function SpawnGemBase(inst)
    if next(inst.components.objectspawner.objects) ~= nil then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = (45 - inst.Transform:GetRotation()) * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    for i, v in ipairs(telebase_parts) do
        local part = inst.components.objectspawner:SpawnObject(inst.colours[i] .. "gembase")
        part.Transform:SetPosition(x + v.x * cos_rot - v.z * sin_rot, 0, z + v.z * cos_rot + v.x * sin_rot)
    end
end

local function changegem(inst)
    inst.gemindex = (inst.gemindex + 1) % 3 + 1
    local gem = inst.colours[inst.gemindex]
    inst.AnimState:SetMultColour(unpack(GEMCOLOUR[gem]))
    -- 更新灯光颜色
    inst.Light:SetColour(unpack(GEMCOLOUR[gem]))
end

local function onsave(inst, data)
    data.gemindex = inst.gemindex
end

local function onload(inst, data)
    inst.gemindex = data ~= nil and data.gemindex or 1
    local gem = inst.colours[inst.gemindex]
    inst.Light:SetColour(unpack(GEMCOLOUR[gem]))
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Remove()
    end
end

local function CommonFn(types, aggro)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.Transform:SetFourFaced()

    inst:AddTag("hostile")
    inst:AddTag("shadoweyeturret")
    inst:AddTag("chess")
    inst:AddTag("shadow_aligned")
    inst:AddTag("laser_immune")
    inst:AddTag("cavedweller")
    inst:AddTag("ignore_holy_damage")

    inst.AnimState:SetBank("eyeball_turret")
    inst.AnimState:SetBuild("eyeball_turret")
    inst.AnimState:PlayAnimation("idle_loop")

    -- 初始化灯光效果
    inst.Light:SetRadius(3.5)                         -- 设置光的半径
    inst.Light:SetIntensity(0.95)                     -- 设置光的强度
    inst.Light:SetFalloff(0.5)                        -- 设置光的衰减
    inst.Light:SetColour(unpack(GEMCOLOUR[types[1]])) -- 初始灯光颜色为第一个宝石颜色
    inst.Light:Enable(true)                           -- 启用发光效果
    inst.Light:EnableClientModulation(true)           -- 启用客户端光效调节

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.targetdsq = aggro and 400 or 36

    inst.base = SpawnPrefab("shadoweyeturret_base")
    inst.base.entity:SetParent(inst.entity)
    inst.highlightchildren = { inst.base }

    inst:AddComponent("objectspawner")
    inst:AddComponent("savedrotation")

    inst.syncanim = syncanim
    inst.syncanimpush = syncanimpush

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1600)
    inst.components.health:StartRegen(TUNING.EYETURRET_REGEN, 1)
    inst.components.health.fire_damage_scale = 0

    inst:AddComponent("combat")
    inst.components.combat:SetRange(aggro and 16 or 14)
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat.onhitotherfn = gemmagic
    inst.components.combat:AddNoAggroTag("shadowthrall")

    inst:AddComponent("inventory")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetLoot({ "thulecite", "thulecite", "thulecite" })
    lootdropper:AddChanceLoot("minotaurhorn", 0.1)
    for k, v in ipairs(types) do
        table.insert(lootdropper.loot, v .. "gem")
    end

    inst:SetStateGraph("SGeyeturret")
    inst:SetBrain(brain)

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.triggerlight = triggerlight

    MakeLargeFreezableCharacter(inst)
    inst.components.freezable:SetResistance(8)
    inst.components.freezable.diminishingreturns = true

    inst.colours = types
    inst.gemindex = 1
    EquipWeapon(inst)
    inst:DoTaskInTime(0, SpawnGemBase)

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:DoPeriodicTask(10 + 5 * math.random(), changegem, 0)

    return inst
end

local function fn()
    local colors = {
        { "purple", "red",    "blue" },
        { "blue",   "orange", "yellow" },
        { "purple", "orange", "red" },
        { "yellow", "orange", "purple" }
    }
    local type = colors[math.random(#colors)]
    return CommonFn(type)
end


local function fn2()
    local colors = {
        { "yellow", "orange", "green" },
        { "blue",   "green",  "orange" },
        { "red",    "green",  "orange" },
        { "purple", "green",  "yellow" }
    }
    local type = colors[math.random(#colors)]
    return CommonFn(type, true)
end

local baseassets =
{
    Asset("ANIM", "anim/eyeball_turret_base.zip"),
}

local function OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and parent.prefab == "shadoweyeturret" then
        parent.highlightchildren = { inst }
    end
end

local function basefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("eyeball_turret_base")
    inst.AnimState:SetBuild("eyeball_turret_base")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetMultColour(85 / 255, 26 / 255, 139 / 255, 1)

    inst.entity:SetPristine()

    inst:AddTag("DECOR")

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    return inst
end

local socketassets =
{
    Asset("ANIM", "anim/staff_purple_base.zip"),
}

local function MakeGemBase(type)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("staff_purple_base")
        inst.AnimState:SetBuild("staff_purple_base")
        inst.AnimState:PlayAnimation("idle_full_loop", true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:OverrideSymbol("gem", "gems", "swap_" .. type .. "gem")

        inst:AddTag("NOCLICK")
        inst:AddTag("DECOR")

        return inst
    end
    return Prefab(type .. "gembase", fn, socketassets)
end

return Prefab("shadoweyeturret", fn, assets, prefabs),
    Prefab("shadoweyeturret2", fn2, assets, prefabs),
    Prefab("shadoweyeturret_base", basefn, baseassets),
    MakeGemBase("green"),
    MakeGemBase("blue"),
    MakeGemBase("purple"),
    MakeGemBase("yellow"),
    MakeGemBase("red"),
    MakeGemBase("orange"),
    RuinsRespawner.Inst("shadoweyeturret"), RuinsRespawner.WorldGen("shadoweyeturret"),
    RuinsRespawner.Inst("shadoweyeturret2"), RuinsRespawner.WorldGen("shadoweyeturret2")
