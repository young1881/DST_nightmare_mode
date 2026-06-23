local assets =
{
    Asset("ANIM", "anim/lava_vomit.zip"),
}

STRINGS.NAMES.LAVA_SINKHOLE = "炽热熔岩"

local INTENSITY = .7

local function fade_in(inst)
    inst.components.fader:StopAll()
    inst.components.fader:Fade(0, INTENSITY, 5 * FRAMES, function(v) inst.Light:SetIntensity(v) end)
end

local function fade_out(inst)
    inst.components.fader:StopAll()
    inst.components.fader:Fade(INTENSITY, 0, 5 * FRAMES, function(v) inst.Light:SetIntensity(v) end,
        function() inst.Light:Enable(false) end)
end

local function OnExtinguish(inst)
    if inst.cooltask ~= nil then
        inst.cooltask:Cancel()
        inst.cooltask = nil
    end
    inst.AnimState:PushAnimation("cool", false)
    fade_out(inst)
    inst:DoTaskInTime(4 * FRAMES, function(inst)
        inst.AnimState:ClearBloomEffectHandle()
        inst.components.unevenground:Disable()
        inst.AnimState:SetPercent("cool", 1)
        inst.components.colourtweener:StartTween({ 0, 0, 0, 0 }, 5, inst.Remove)
    end)
end

local function OnCooldown(inst)
    inst.components.burnable:Extinguish()
end

local function OnInit(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:Ignite(true)
        inst.components.burnable:FixFX()
    end
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("lava_vomit")
    inst.AnimState:SetBuild("lava_vomit")
    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetScale(2.0, 2.0, 2.0)

    local light = inst.entity:AddLight()
    light:SetFalloff(.5)
    light:SetIntensity(INTENSITY)
    light:SetRadius(1)
    light:SetColour(200 / 255, 100 / 255, 170 / 255)



    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("fader")

    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0))

    -- inst.components.burnable:MakeNotWildfireStarter()
    inst:ListenForEvent("onextinguish", OnExtinguish)

    MakeMediumPropagator(inst)
    inst.components.propagator.heatoutput = 20
    inst.components.propagator:StartSpreading()

    inst:AddComponent("colourtweener")

    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = 1.9  --减速效果的半径

    fade_in(inst)

    inst.cooltask = inst:DoTaskInTime(40, OnCooldown)


    inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("lava_sinkhole", fn, assets)
