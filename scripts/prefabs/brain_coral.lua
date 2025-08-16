local assets =
{
    Asset("ANIM", "anim/brain_coral.zip"),
    Asset("IMAGE", "images/inventoryimages/brain_coral.tex"),
    Asset("ATLAS", "images/inventoryimages/brain_coral.xml"),
}

local prefabs = {
    "spoiled_food",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("brain_coral")
    inst.AnimState:SetBuild("brain_coral")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("fishmeat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunchAndPerish(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/brain_coral.xml"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = -10
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE
    inst.components.edible.hungervalue = 10


    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
    return inst
end

return Prefab("brain_coral", fn, assets, prefabs)
