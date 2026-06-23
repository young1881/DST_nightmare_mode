local lunarTouchDamage = 17
require "prefabutil"

local assets =
{
    ---- 用座狼的火焰
    Asset("ANIM", "anim/warg_mutated_breath_fx.zip"),
}
local prefabs = {}

local preAnim = {"flame1_pre", "flame2_pre", "flame3_pre"}
local loopAnim = {"flame1_loop", "flame2_loop", "flame3_loop"}
local pstAnim = {"flame1_pst", "flame2_pst", "flame3_pst"}
local smokeAnim = {"smoke1_float", "smoke2_float"}

local function getRandomElement(array)
    if #array == 0 then
        return nil  -- 如果数组为空，返回 nil
    end
    local randomIndex = math.random(1, #array)  -- 生成一个随机索引
    return array[randomIndex]  -- 返回随机选择的元素
end

local function CreateProjectileLight()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddLight()

    inst.Light:SetIntensity(0.75)
    inst.Light:SetColour(255 / 255, 255 / 255, 255 / 255)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetRadius(2)

    return inst
end

local function boomfx(inst)
    local random_index = math.random(1, 3)  -- 生成 1 到 3 的随机数
    local fx_name = "halloween_firepuff_cold_" .. random_index  -- 拼接字符串
    local fx = SpawnPrefab(fx_name)  -- 创建特效
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())  -- 设置位置
end

local function attack_behaviour(inst)
	if inst.components.combat ~= nil then
		if inst.components.combat:CanTarget(inst.target) then
			if inst._nm_fx_only then
				return true
			end
			inst.components.combat:DoAttack(inst.target)
			return true
		else
			return false
		end
	end
end

local function on_anim_over(inst)
    if inst.AnimState:IsCurrentAnimation("flame1_pre")
        or inst.AnimState:IsCurrentAnimation("flame2_pre")
        or inst.AnimState:IsCurrentAnimation("flame3_pre")
    then  --1 
        attack_behaviour(inst)
        inst.AnimState:PushAnimation(getRandomElement(loopAnim))  --2 
    elseif inst.AnimState:IsCurrentAnimation("flame1_loop")
        or inst.AnimState:IsCurrentAnimation("flame2_loop")
        or inst.AnimState:IsCurrentAnimation("flame3_loop")
    then
        boomfx(inst)
        attack_behaviour(inst)
    --     inst.AnimState:PushAnimation(getRandomElement(pstAnim))
    -- elseif inst.AnimState:IsCurrentAnimation("flame1_pst")
    --     or inst.AnimState:IsCurrentAnimation("flame2_pst")
    --     or inst.AnimState:IsCurrentAnimation("flame3_pst")
    -- then
        attack_behaviour(inst)
        inst.AnimState:PushAnimation(getRandomElement(smokeAnim))
    elseif inst.AnimState:IsCurrentAnimation("smoke1_float")
        or inst.AnimState:IsCurrentAnimation("smoke2_float")
    then
        attack_behaviour(inst)
        inst:Remove()
    end
end

----------- lunar_torch_projectile -----------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()


    inst._light = CreateProjectileLight()
    inst._light.entity:SetParent(inst.entity)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("warg_mutated_breath_fx")
	inst.AnimState:SetBuild("warg_mutated_breath_fx")
    inst.AnimState:PlayAnimation(getRandomElement(preAnim)) --1 
    inst.AnimState:SetMultColour(1, 1, 1, 0.6)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(0.1)
    local scale = math.random(9, 11) * 0.1
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")
    inst:AddTag("crazy")
    inst:AddTag("extinguisher")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    print("start AddComponent combat")
	inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(0)
    inst.components.combat:SetRange(1)
    print("start AddComponent planardamage")
    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(lunarTouchDamage)

    inst.persists = false

    inst:ListenForEvent("animover", on_anim_over)
    inst.target = nil

    return inst
end


return Prefab("lunar_torch_projectile", fn, assets, prefabs)

