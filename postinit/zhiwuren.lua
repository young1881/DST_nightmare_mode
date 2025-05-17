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
