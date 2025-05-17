local assets =
{
    Asset("ANIM", "anim/winona_catapult_projectile.zip"),
}

local prefabs = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("winona_catapult_projectile")
    inst.AnimState:SetBuild("winona_catapult_projectile")
    inst.AnimState:PlayAnimation("impact1_lunar")

    inst.entity:SetPristine()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end


return Prefab("wd_projectilefx", fn, assets)