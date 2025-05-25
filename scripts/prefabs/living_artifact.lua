local assets =
{
    Asset("ANIM", "anim/living_artifact.zip"),
    Asset("IMAGE", "images/inventoryimages/living_artifact.tex"),
    Asset("ATLAS", "images/inventoryimages/living_artifact.xml")
}

STRINGS.NAMES.LIVING_ARTIFACT = "核能电池"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.LIVING_ARTIFACT = "在每场战斗开始时， 生成1个等离子充能球。"

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("living_artifact")
    inst.AnimState:SetBuild("living_artifact")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "metal"

    inst:AddTag("molebait")

    MakeInventoryFloatable(inst, "med", nil, 0.7)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/living_artifact.xml"

    inst:AddComponent("bait")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GEARS
    inst.components.edible.healthvalue = TUNING.HEALING_HUGE * 1.5
    inst.components.edible.hungervalue = TUNING.CALORIES_HUGE * 1.5
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE * 1.5

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("living_artifact", fn, assets)
