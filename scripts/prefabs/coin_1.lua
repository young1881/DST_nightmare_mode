local assets = {
    Asset("ANIM", "anim/coin_1.zip"),
    Asset("ATLAS", "images/coin_1.xml"),
    Asset("IMAGE", "images/coin_1.tex"),
}

local function Sparkle(inst)
    if not inst.AnimState:IsCurrentAnimation("shine") then
        inst.AnimState:PlayAnimation("shine")
        inst.AnimState:PushAnimation("idle", true)
    end
    inst:DoTaskInTime(4 + math.random(), Sparkle)
end

local function whatever()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.pickupsound = "gem"

    inst.AnimState:SetBank("coin_1")
    inst.AnimState:SetBuild("coin_1")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("piggy_bank_coin")

    MakeInventoryFloatable(inst, "med", 0.05, {0.65, 0.5, 0.65})

    inst.entity:SetPristine()

    inst.AnimState:SetScale(2.8, 2.8, 2.8)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.keepondeath = true
    inst.components.inventoryitem.imagename = "coin_1"
    inst.components.inventoryitem.atlasname = "images/coin_1.xml"
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:DoTaskInTime(1, Sparkle)

    return inst
end

return Prefab("coin_1", whatever, assets)