require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/wormwood_seeds.zip"),
	Asset("ANIM", "anim/oceanfishing_lure_mis.zip"), --钓鱼杆用
    Asset("ATLAS", "images/inventoryimages/wormwood_seeds.xml"),
	Asset("IMAGE", "images/inventoryimages/wormwood_seeds.tex"),
}

local prefabs =
{
    "seeds_cooked",
    "spoiled_food",
    "plant_normal_ground",
	"farm_plant_randomseed",
	"weed_forgetmelots",
	"weed_tillweed",
	"weed_firenettle",
	"weed_ivy",
}

local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab("farm_plant_randomseed")
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    inst:Remove()
end

local function can_plant_seed(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wormwood_seeds")
    inst.AnimState:SetBuild("wormwood_seeds")
    inst.AnimState:PlayAnimation("idle")
    --inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("deployedplant")
    inst:AddTag("deployedfarmplant")
    inst:AddTag("cookable")
    inst:AddTag("oceanfishing_lure")
    inst:AddTag("treeseed")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    inst._custom_candeploy_fn = can_plant_seed -- for DEPLOYMODE.CUSTOM

    if not TheWorld.ismastersim then
        return inst
    end
    inst.Transform:SetScale(0.8,0.8,0.8) 
	
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/wormwood_seeds.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.SEEDS
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 1.5

    inst:AddComponent("cookable")
    inst.components.cookable.product = "seeds_cooked"

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("bait")

    inst:AddComponent("farmplantable")
    inst.components.farmplantable.plant = "farm_plant_randomseed"

    inst:AddComponent("oceanfishingtackle")
	inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
    inst.components.deployable.restrictedtag = "plantkin"
    inst.components.deployable.ondeploy = OnDeploy

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndPerish(inst)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

local function update_seed_placer_outline(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:CanTillSoilAtPoint(x, y, z) then
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
		inst.outline.Transform:SetPosition(cx, cy, cz)
		inst.outline:Show()
	else
		inst.outline:Hide()
	end
end

local function seed_placer_postinit(inst)
	inst.outline = SpawnPrefab("tile_outline")

	inst.outline.Transform:SetPosition(2, 0, 0)
	inst.outline:ListenForEvent("onremove", function() inst.outline:Remove() end, inst)
	inst.outline.AnimState:SetAddColour(.25, .75, .25, 0)
	inst.outline:Hide()

	inst.components.placer.onupdatetransform = update_seed_placer_outline
end

return Prefab("wormwood_seeds", fn, assets, prefabs),
       MakePlacer("wormwood_seeds_placer", "farm_soil", "farm_soil", "till_idle", nil, nil, nil, nil, nil, nil, seed_placer_postinit)
