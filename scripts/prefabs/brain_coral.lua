local assets =
{
    Asset("ANIM", "anim/brain_coral.zip"),
    Asset("IMAGE", "images/inventoryimages/brain_coral.tex"),
    Asset("ATLAS", "images/inventoryimages/brain_coral.xml"),
}

local prefabs = {
    "spoiled_food",
}

STRINGS.NAMES.BRAIN_CORAL = "智慧果"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BRAIN_CORAL = "精神食粮。"
STRINGS.CHARACTERS.WORTOX.DESCRIBE.BRAIN_CORAL = "我想吃它，但是这样做会引起肠道不适。"
STRINGS.CHARACTERS.WURT.DESCRIBE.BRAIN_CORAL = "在这个附近我有一种不舒服的绝望感觉。"
STRINGS.CHARACTERS.WARLY.DESCRIBE.BRAIN_CORAL = "这些东西真的可以补脑吗？"
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.BRAIN_CORAL = "我吃掉它的话能得到它的知识吗？"
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BRAIN_CORAL = "现在我可以利用它的思维力量了。"
STRINGS.CHARACTERS.WEBBER.DESCRIBE.BRAIN_CORAL = "美味的脑花！"
STRINGS.CHARACTERS.WENDY.DESCRIBE.BRAIN_CORAL = "我的内在就是这个样子吗？"
STRINGS.CHARACTERS.WANDA.DESCRIBE.BRAIN_CORAL = "你在想什么呢？"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BRAIN_CORAL = "充满智慧！"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.BRAIN_CORAL = "我可以学着喜欢这种味道..."
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.BRAIN_CORAL = "嗬嗬。它沃尔夫冈的触碰下咯吱吱响。"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.BRAIN_CORAL = "好有脑子。"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.BRAIN_CORAL = "思考..."
STRINGS.CHARACTERS.WX78.DESCRIBE.BRAIN_CORAL = "食用可引发智力刺激状态"


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
