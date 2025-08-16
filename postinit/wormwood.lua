--真正的种子侦探
require "prefabs/veggies"
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WORMWOOD_SEEDS = Action {
	priority = 999,
}
WORMWOOD_SEEDS.id = "WORMWOOD_SEEDS"
WORMWOOD_SEEDS.str = "辨识"
WORMWOOD_SEEDS.fn = function(act)
	local seeds = act.target and act.target:IsValid() and act.target.prefab == "seeds"
	if seeds and act.doer then
		local x, y, z = act.target.Transform:GetWorldPosition()
		local emote_fx = SpawnPrefab("emote_fx")
		emote_fx.Transform:SetScale(0.5, 0.5, 0.5)
		emote_fx.Transform:SetPosition(x, y + 0.5, z)

		for i = 1, act.target.components.stackable:StackSize() do
			--20%出杂草
			local weed = false
			if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
				weed = true
			end

			--官方随机加权代码
			local season = TheWorld.state.season
			local weights = {}
			local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD
			for k, v in pairs(VEGGIES) do
				weights[k] = v.seed_weight * ((PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[season]) and season_mod or 1)
			end
			local RTseed_prefab = weighted_random_choice(weights) .. "_seeds"
			local RTseed = SpawnPrefab(RTseed_prefab)

			if RTseed and not weed then
				RTseed.Transform:SetPosition(act.target.Transform:GetWorldPosition())
				RTseed.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
				act.doer.components.inventory:GiveItem(RTseed, nil, RTseed:GetPosition())
				act.doer.components.talker:Say("新的宝宝")
			end
			if weed then
				local zc = SpawnPrefab("wormwood_seeds")
				zc.Transform:SetPosition(act.target.Transform:GetWorldPosition())
				zc.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
				act.doer.components.inventory:GiveItem(zc, nil, zc:GetPosition())
				act.doer.components.talker:Say("新的宝宝")
			end

			act.doer.SoundEmitter:PlaySound("dontstarve/common/plant")
			act.target.components.stackable:Get(1):Remove() --删除这一个种子
		end
		return true
	end
end
AddAction(WORMWOOD_SEEDS)

--压键种子侦探
AddComponentAction("INVENTORY", "deployable", function(inst, doer, actions, right)
	if doer.prefab == "wormwood" and inst.prefab == "seeds" then
		if doer.components.playercontroller and doer.components.playercontroller:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
			table.insert(actions, ACTIONS.WORMWOOD_SEEDS_X)
		end
	end
end)

local WORMWOOD_SEEDS_X = Action({ priority = 2, mount_valid = true })
WORMWOOD_SEEDS_X.str = "辨识"
WORMWOOD_SEEDS_X.id = "WORMWOOD_SEEDS_X"
WORMWOOD_SEEDS_X.fn = function(act)
	local seeds = act.invobject and act.invobject:IsValid() and act.invobject.prefab == "seeds"
	if seeds and act.doer then
		local x, y, z = act.doer.Transform:GetWorldPosition()
		local emote_fx = SpawnPrefab("emote_fx")
		emote_fx.Transform:SetScale(0.5, 0.5, 0.5)
		emote_fx.Transform:SetPosition(x, y + 0.5, z)

		for i = 1, act.invobject.components.stackable:StackSize() do
			--20%出杂草
			local weed = false
			if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
				weed = true
			end

			--官方随机加权代码
			local season = TheWorld.state.season
			local weights = {}
			local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD
			for k, v in pairs(VEGGIES) do
				weights[k] = v.seed_weight * ((PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[season]) and season_mod or 1)
			end
			local RTseed_prefab = weighted_random_choice(weights) .. "_seeds"
			local RTseed = SpawnPrefab(RTseed_prefab)

			if RTseed and not weed then
				RTseed.Transform:SetPosition(act.invobject.Transform:GetWorldPosition())
				RTseed.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
				act.doer.components.inventory:GiveItem(RTseed, nil, RTseed:GetPosition())
				act.doer.components.talker:Say("新的宝宝")
			end
			if weed then
				local zc = SpawnPrefab("wormwood_seeds")
				zc.Transform:SetPosition(act.invobject.Transform:GetWorldPosition())
				zc.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
				act.doer.components.inventory:GiveItem(zc, nil, zc:GetPosition())
				act.doer.components.talker:Say("新的宝宝")
			end

			act.doer.SoundEmitter:PlaySound("dontstarve/common/plant")
			act.invobject.components.stackable:Get(1):Remove() --删除这一个种子
		end
		return true
	end
end
AddAction(WORMWOOD_SEEDS_X)

for sg, client in pairs {
	wilson = false,
	wilson_client = true
} do
	AddStategraphActionHandler(sg, ActionHandler(ACTIONS.WORMWOOD_SEEDS_X, function(inst, action)
		if action.invobject.components.stackable then
			if action.invobject.components.stackable:StackSize() <= 5 then
				return "domediumaction"
			elseif action.invobject.components.stackable:StackSize() <= 10 then
				return "dolongaction"
			else
				return "dolongestaction"
			end
		else
			return "dolongaction"
		end
	end))
end

--种子侦探
AddComponentAction("SCENE", "deployable", function(inst, doer, actions, right)
	if doer.prefab == "wormwood" and inst.prefab == "seeds" and right then
		table.insert(actions, ACTIONS.WORMWOOD_SEEDS)
	end
end)

--种子侦探
for sg, client in pairs {
	wilson = false,
	wilson_client = true
} do
	AddStategraphActionHandler(sg, ActionHandler(ACTIONS.WORMWOOD_SEEDS, function(inst, action)
		if action.target.components.stackable then
			if action.target.components.stackable:StackSize() <= 5 then
				return "domediumaction"
			elseif action.target.components.stackable:StackSize() <= 10 then
				return "dolongaction"
			else
				return "dolongestaction"
			end
		else
			return "dolongaction"
		end
	end))
end

--月晷可接水
AddPrefabPostInit("moondial", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	if inst.components.watersource == nil then
		inst:AddTag("watersource")
		inst:AddComponent("watersource")
	end
end)

----------  加强茄甲自动恢复耐久  ----------

local function DoRegen(inst, owner)
	if inst:HasTag("broken") then
		if inst.regentask ~= nil then
			inst.regentask:Cancel()
			inst.regentask = nil
		end
		return
	end
	if owner.components.sanity ~= nil and owner.components.sanity:GetPercent() > 0 then
		local bloom_component = owner.components.bloomness
		local bloom_level = 1
		if bloom_component ~= nil then
			bloom_level = bloom_component:GetLevel() + 1 or 1
		end
		local rate = 2 * bloom_level
		local sanity_cost = 0.5 * bloom_level
		local hunger_cost = 0.25 * bloom_level

		if owner.components.sanity.current >= sanity_cost and owner.components.hunger.current >= hunger_cost then
			owner.components.sanity:DoDelta(-sanity_cost)
			owner.components.hunger:DoDelta(-hunger_cost)
			inst.components.armor:Repair(rate)
			if not inst.components.armor:IsDamaged() then
				inst.regentask:Cancel()
				inst.regentask = nil
			end
		else
			if inst.regentask ~= nil then
				inst.regentask:Cancel()
				inst.regentask = nil
			end
		end
	end
end


local function StartRegen(inst, owner)
	local repair_time = 3
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(repair_time, function()
			DoRegen(inst, owner)
		end)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function OnArmorDamaged(inst, owner)
	if owner ~= nil and owner.components ~= nil then
		if inst.regentask == nil then
			StartRegen(inst, owner)
		end
	end
end

local function postinitfn(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.isonattack = false

	-- Add the regen tasks to the existing equip and unequip functions
	local originalOnEquip = inst.components.equippable.onequipfn or function() end
	local originalOnUnequip = inst.components.equippable.onunequipfn or function() end

	inst.components.equippable:SetOnEquip(function(inst, owner)
		originalOnEquip(inst, owner)
		StartRegen(inst, owner)
	end)

	inst.components.equippable:SetOnUnequip(function(inst, owner)
		originalOnUnequip(inst, owner)
		StopRegen(inst)
	end)

	inst:ListenForEvent("armordamaged", function(inst, data)
		local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
		OnArmorDamaged(inst, owner)
	end)


	inst:AddComponent("armor")
	inst.components.armor:InitCondition(945, 0.9) --耐久调整防御力调整）

	inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(20) --位面防御
end

AddPrefabPostInit("armor_lunarplant_husk", postinitfn)

table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WORMWOOD, "compostwrap")   --开局粑粑包
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WORMWOOD, "armor_bramble") --开局荆棘甲

TUNING.WORMWOOD_ARMOR_BRAMBLE_RELEASE_SPIKES_HITCOUNT = 1                      --荆棘专家攻击次数
TUNING.ARMORBRAMBLE_DMG = 25                                                   --荆棘甲反伤伤害
TUNING.ARMORBRAMBLE_DMG_PLANAR_UPGRADE = 35                                    --荆棘茄甲位面反伤

AddPrefabPostInit("premiumwateringcan", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.wateryprotection.super = true;
end)


AddStategraphPostInit("wilson", function(sg)
	local old_pick = sg.actionhandlers[ACTIONS.PICK].deststate
	sg.actionhandlers[ACTIONS.PICK].deststate = function(inst, action)
		if inst:HasTag("farmplantfastpicker") and action.target and action.target:HasTag("farm_plant") then
			return "doshortaction"
		end
		return old_pick(inst, action)
	end

	local old_harvest = sg.actionhandlers[ACTIONS.HARVEST].deststate
	sg.actionhandlers[ACTIONS.HARVEST].deststate = function(inst, action)
		if inst:HasTag("farmplantfastpicker") and action.target and action.target:HasTag("farm_plant") then
			return "doshortaction"
		end
		return old_harvest(inst, action)
	end
end)

AddStategraphPostInit("wilson_client", function(sg)
	local old_pick = sg.actionhandlers[ACTIONS.PICK].deststate
	sg.actionhandlers[ACTIONS.PICK].deststate = function(inst, action)
		if inst:HasTag("farmplantfastpicker") and action.target and action.target:HasTag("farm_plant") then
			return "doshortaction"
		end
		return old_pick(inst, action)
	end

	local old_harvest = sg.actionhandlers[ACTIONS.HARVEST].deststate
	sg.actionhandlers[ACTIONS.HARVEST].deststate = function(inst, action)
		if inst:HasTag("farmplantfastpicker") and action.target and action.target:HasTag("farm_plant") then
			return "doshortaction"
		end
		return old_harvest(inst, action)
	end
end)

--鸟嘴壶"
AddRecipe2("premiumwateringcan",
	{ Ingredient("livinglog", 2), Ingredient("rope", 4), Ingredient("boneshard", 4), Ingredient("bluegem", 1) },
	TECH.NONE_TWO, nil, { "GARDENING" })

--荆棘茄甲
AddRecipe2("armor_lunarplant_husk",
	{ Ingredient("armor_bramble", 1), Ingredient("moonglass", 8), Ingredient("purebrilliance", 2) }, TECH.NONE_TWO,
	{ builder_tag = "plantkin", builder_skill = "wormwood_allegiance_lunar_plant_gear_1" },
	{ "CHARACTER" })

-- 远古粑粑包
AddRecipe2("transmute_compostwrap", { Ingredient("cave_banana",
		3), Ingredient("cutlichen", 2), Ingredient("thulecite_pieces", 2) }, TECH.ANCIENT_FOUR,
	{ product = "compostwrap", image = "compostwrap.tex", description = "transmute_compostwarp", builder_tag = "plantkin", nounlock = true },
	{ "CHARACTER" })
STRINGS.RECIPE_DESC.TRANSMUTE_COMPOSTWRAP = "远古秘制老八，九九八十一天发酵"

-- 小飞虫血量调整
AddRecipe2("wormwood_lightflier", { Ingredient(CHARACTER_INGREDIENT.HEALTH, 5), Ingredient("lightbulb", 1) }, TECH.NONE,
	{
		builder_skill = "wormwood_allegiance_lunar_mutations_2",
		product = "wormwood_mutantproxy_lightflier",
		sg_state =
		"spawn_mutated_creature",
		actionstr = "TRANSFORM",
		no_deconstruction = true,
		dropitem = true,
		nameoverride =
		"lightflier",
		description = "wormwood_lightflier",
		canbuild = function(inst, builder)
			return
				(builder.components.petleash and not builder.components.petleash:IsFullForPrefab("wormwood_lightflier")),
				"HASPET"
		end
	}, { "CHARACTER" })

local function livinglog_numtogive(recipe, doer)
	local total = 1
	if math.random() < 0.4 then
		total = total + 1
	end
	if math.random() < 0.1 then
		total = total + 1
	end
	if total > 2 then
		doer.SoundEmitter:PlaySound("meta5/wendy/elixir_bonus_2")
		doer.components.talker:Say("更多的朋友给更好的朋友！")
	elseif total > 1 then
		doer.SoundEmitter:PlaySound("meta5/wendy/elixir_bonus_1")
		doer.components.talker:Say("更多的朋友给更好的朋友！")
	end
	return total
end

Recipe2("livinglog",
	{ Ingredient(CHARACTER_INGREDIENT.HEALTH, 20) },
	TECH.NONE,
	{
		builder_tag = "plantkin",
		sg_state = "form_log",
		actionstr = "GROW",
		allowautopick = true,
		no_deconstruction = true,
		override_numtogive_fn = livinglog_numtogive
	}
)
