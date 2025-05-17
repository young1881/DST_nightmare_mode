GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

--视界扩展器效果
local function new_alterguardianhat_onequip(inst, owner)
    if owner.isplayer then
        owner:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
    end
end

local function new_alterguardianhat_onunequip(inst, owner)
    if owner.isplayer then
        owner:RemoveCameraExtraDistance(inst)
    end
end

--可穿戴
local function SetupEquippable(inst)
    if not inst.components.equippable then
        inst:AddComponent("equippable")
    end
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(
        function(inst, owner)
            new_alterguardianhat_onequip(inst, owner)
            if inst.old_onequip then
                inst.old_onequip(inst, owner)
            end
        end
    )
    inst.components.equippable:SetOnUnequip(
        function(inst, owner)
            new_alterguardianhat_onunequip(inst, owner)
            if inst.old_onunequip then
                inst.old_onunequip(inst, owner)
            end
        end
    )
	if inst._equippable_restrictedtag ~= nil then
		inst.components.equippable.restrictedtag = inst._equippable_restrictedtag
	end
end

--破损
local function OnBroken(inst)
	if inst.components.equippable ~= nil then
		inst:RemoveComponent("equippable")
		--inst.AnimState:PlayAnimation("broken")
		--inst.components.floater:SetSwapData(SWAP_DATA_BROKEN)
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

--修复
local function OnRepaired(inst)
	if inst.components.equippable == nil then
		SetupEquippable(inst)
		--inst.AnimState:PlayAnimation("anim")
		--inst.components.floater:SetSwapData(SWAP_DATA)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end

--亮茄装备buff
local function OnEnabledSetBonus(inst)
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.ARMOR_LUNARPLANT_SETBONUS_LUNAR_RESIST, "setbonus")
end

local function OnDisabledSetBonus(inst)
    inst.components.damagetyperesist:RemoveResist("lunar_aligned", inst, "setbonus")
end

local function ReflectDamageFn(inst, attacker, damage, weapon, stimuli, spdamage)
    return 0,
    {
        planar = attacker ~= nil and attacker:HasTag("shadow_aligned")
            and TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG_VS_SHADOW
            or TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG,
    }
end

local function OnReflectDamage(inst, data)
    --data.attacker is the target we are reflecting dmg to
    if data ~= nil and data.attacker ~= nil and data.attacker:IsValid() then
        SpawnPrefab("hitsparks_reflect_fx"):Setup(inst.components.inventoryitem.owner or inst, data.attacker)
    end
end

local function new_alterguardian_onsave(inst, data)
    local equipper = nil
    if inst.components.equippable then
        equipper = inst.components.equippable:IsEquipped() and inst.components.inventoryitem:GetGrandOwner() or nil
    end

    local keep_closed = (equipper ~= nil and inst.components.container.opencount == 0 and equipper.userid) or inst.keep_closed -- Try to get new data and fallback to saved variable.

    if keep_closed ~= nil then
        data.owner_id = keep_closed
    end
end

local function alterguardianhat(inst)
    inst:AddTag("goggles")
    inst:AddTag("nosteal")
    inst:AddTag("lunarplant")
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    -- Save original equip/unequip functions
    inst.old_onequip = inst.components.equippable and inst.components.equippable.onequipfn
    inst.old_onunequip = inst.components.equippable and inst.components.equippable.onunequipfn

    -- Setup equippable
    SetupEquippable(inst)

    --追加防御和位面
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMOR_LUNARPLANT, TUNING.ARMOR_LUNARPLANT_ABSORPTION)
    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(TUNING.ARMOR_LUNARPLANT_PLANAR_DEF)

    --可修复
    MakeForgeRepairable(inst, FORGEMATERIALS.LUNARPLANT, OnBroken, OnRepaired)

    --套装效果
    inst:AddComponent("damagereflect")
    inst.components.damagereflect:SetReflectDamageFn(ReflectDamageFn)
    inst:ListenForEvent("onreflectdamage", OnReflectDamage)
    ---
    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.ARMOR_LUNARPLANT_LUNAR_RESIST)
    ---
    local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName(EQUIPMENTSETNAMES.LUNARPLANT)
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
    setbonus:SetOnDisabledFn(OnDisabledSetBonus)

    -- Override the onsave function
    inst.OnSave = new_alterguardian_onsave
end

AddPrefabPostInit("alterguardianhat", alterguardianhat)