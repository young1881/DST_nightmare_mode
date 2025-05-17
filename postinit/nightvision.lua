TUNING.WORMLIGHT_NIGHTVISION_DURATION = 120 -- 夜视持续时间，单位秒

local function AddNightVisionBuff(eater)
    if eater.components.playervision ~= nil then
        eater:AddDebuff("nightvision_buff", "nightvision_buff")
    end

    if eater.components.sanity ~= nil then
        eater.components.sanity.externalmodifiers:SetModifier(eater, -TUNING.DAPPERNESS_MED_LARGE)
    end
end

local function RemoveNightVisionBuff(eater)
    if eater.components.playervision ~= nil then
        eater.components.playervision:PopForcedNightVision(eater)
    end

    if eater.components.sanity ~= nil then
        eater.components.sanity.externalmodifiers:RemoveModifier(eater)
    end
end

local function Wormlight_OnEaten(inst, eater)
    -- 添加夜视增益
    AddNightVisionBuff(eater)

    -- 设置一个定时器，移除夜视增益，持续时间为 TUNING.WORMLIGHT_NIGHTVISION_DURATION
    inst:DoTaskInTime(TUNING.WORMLIGHT_NIGHTVISION_DURATION, function()
        RemoveNightVisionBuff(eater)
    end)
end


local function AddWormlightNightVision()
    local wormlight = GLOBAL.Prefabs.wormlight

    if wormlight ~= nil and wormlight.components.edible ~= nil then
        wormlight.components.edible:SetOnEatenFn(Wormlight_OnEaten)
    end
end

AddPrefabPostInit("wormlight", AddWormlightNightVision)


local function fn_nightvisionbuff()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:Hide()

    inst.persists = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(buff_OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(buff_OnExtended)
    inst.components.debuff.keepondespawn = true

    buff_OnExtended(inst)

    return inst
end

AddPrefabPostInit("nightvision_buff", fn_nightvisionbuff)
