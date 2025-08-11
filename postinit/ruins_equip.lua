local max_health_bonus = 50 -- 铥甲加强的血量上限

AddPrefabPostInit("armorruins", function(inst)
    local function onequip(inst, owner)
        if inst._oldonequipfn ~= nil then
            inst._oldonequipfn(inst, owner)
        end

        if owner.components.sanity ~= nil then
            owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.5)
        end

        if owner.components.health ~= nil then
            if owner.components.health.maxhealth < 150 then
                local old = owner.components.health:GetPercent()
                owner.components.health.maxhealth = owner.components.health.maxhealth + max_health_bonus
                owner.components.health:SetPercent(old)
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
            local old = owner.components.health:GetPercent()
            owner.components.health.maxhealth = owner.components.health.maxhealth - max_health_bonus
            owner.components.health:SetPercent(old)
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
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
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

AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
    inst:AddTag("hammer")

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.PICKAXE_LUNARPLANT_EFFICIENCY)
    inst.components.tool:EnableToughWork(true)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MULTITOOL_AXE_PICKAXE_USES)
    inst.components.finiteuses:SetUses(TUNING.MULTITOOL_AXE_PICKAXE_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 3)
    inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 3)
end)
