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

----------  荆棘茄甲：沃姆伍德穿戴时治疗效果 +50%  ----------

local WORMWOOD_HUSK_HEAL_MULT = 1.5

local function WormwoodWearingLunarplantHusk(inst)
	local inv = inst.components.inventory
	if inv == nil then
		return false
	end
	local body = inv:GetEquippedItem(EQUIPSLOTS.BODY)
	return body ~= nil and body.prefab == "armor_lunarplant_husk"
end

local function WormwoodHuskHealDeltaModifier(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	local basefn = inst._wormwood_husk_base_deltamodifierfn
	if basefn ~= nil then
		amount = basefn(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	end
	if amount > 0 and WormwoodWearingLunarplantHusk(inst) then
		amount = amount * WORMWOOD_HUSK_HEAL_MULT
	end
	return amount
end

local function WormwoodInstallHuskHealModifier(inst)
	if inst.components.health == nil or inst._wormwood_husk_heal_modifier_installed then
		return
	end
	inst._wormwood_husk_heal_modifier_installed = true
	inst._wormwood_husk_base_deltamodifierfn = inst.components.health.deltamodifierfn
	inst.components.health.deltamodifierfn = WormwoodHuskHealDeltaModifier
end
----------  加强茄甲自动恢复耐久（沃姆伍德物品栏内亦可恢复）  ----------

local HUSK_MIN_EQUIP_PERCENT = 0.1
local HUSK_REGEN_PERIOD = 3

local function HuskCanEquip(inst)
	if inst:HasTag("broken") then
		return false
	end
	return inst.components.armor == nil or inst.components.armor:GetPercent() >= HUSK_MIN_EQUIP_PERCENT
end

local function HuskTryReturnToInventory(inst, owner)
	if owner == nil or owner.components == nil or owner.components.inventory == nil then
		return
	end
	if HuskCanEquip(inst) then
		return
	end
	local inv = owner.components.inventory
	if inv:GetEquippedItem(EQUIPSLOTS.BODY) ~= inst then
		return
	end
	inv:Unequip(EQUIPSLOTS.BODY)
	inv:GiveItem(inst)
end

local function DoRegen(inst, owner)
	if inst:HasTag("broken") or owner.components.hunger == nil then
		return
	end
	local bloom_component = owner.components.bloomness
	local bloom_level = 1
	if bloom_component ~= nil then
		bloom_level = bloom_component:GetLevel() + 1 or 1
	end
	local rate = 2.0 * bloom_level
	local sanity_cost = 0.5 * bloom_level
	local hunger_cost = 0.25 * bloom_level

	local sanity = owner.components.sanity
	if sanity ~= nil and sanity:GetPercent() <= 0 then
		return
	end
	if sanity ~= nil and sanity.current < sanity_cost then
		return
	end
	if owner.components.hunger.current < hunger_cost then
		return
	end

	if sanity ~= nil then
		sanity:DoDelta(-sanity_cost)
	end
	owner.components.hunger:DoDelta(-hunger_cost)
	inst.components.armor:Repair(rate)
end

local function WormwoodRepairHusksTick(player)
	if player == nil or not player:IsValid() or player.prefab ~= "wormwood" then
		return
	end
	local inv = player.components.inventory
	if inv == nil then
		return
	end
	local function repair_one(item)
		if item == nil or item.prefab ~= "armor_lunarplant_husk" then
			return
		end
		if item.components.armor == nil or not item.components.armor:IsDamaged() then
			return
		end
		DoRegen(item, player)
		HuskTryReturnToInventory(item, player)
	end
	for _, item in pairs(inv.itemslots) do
		repair_one(item)
	end
	for _, item in pairs(inv.equipslots) do
		repair_one(item)
	end
end

local function WormwoodEnsureHuskRegenTask(inst)
	if inst._wormwood_husk_regen_task ~= nil then
		return
	end
	inst._wormwood_husk_regen_task = inst:DoPeriodicTask(HUSK_REGEN_PERIOD, WormwoodRepairHusksTick)
end

local function postinitfn(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.isonattack = false

	local originalOnEquip = inst.components.equippable.onequipfn or function() end
	local originalOnUnequip = inst.components.equippable.onunequipfn or function() end
	local originalRestrictedFn = inst.components.equippable.restrictedfn

	inst.components.equippable.restrictedfn = function(husk, owner)
		if not HuskCanEquip(husk) then
			return true
		end
		return originalRestrictedFn ~= nil and originalRestrictedFn(husk, owner) or false
	end

	inst.components.equippable:SetOnEquip(function(husk, owner)
		originalOnEquip(husk, owner)
		HuskTryReturnToInventory(husk, owner)
	end)

	inst.components.equippable:SetOnUnequip(function(husk, owner)
		originalOnUnequip(husk, owner)
	end)

	inst:ListenForEvent("armordamaged", function(husk)
		local owner = husk.components.inventoryitem and husk.components.inventoryitem.owner
		HuskTryReturnToInventory(husk, owner)
	end)

	if inst.components.armor == nil then
		inst:AddComponent("armor")
	end
	inst.components.armor:InitCondition(1250, 0.9) -- 物理防御 90%
	inst.components.armor.conditionlossmultipliers:SetModifier(inst, 2 / 3, "roge_lunarplant_husk") -- 耐久损耗减少三分之一

	if inst.components.planardefense == nil then
		inst:AddComponent("planardefense")
	end
	inst.components.planardefense:SetBaseDefense(20) --位面防御
end

AddPrefabPostInit("armor_lunarplant_husk", postinitfn)

table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WORMWOOD, "compostwrap")   --开局粑粑包
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WORMWOOD, "armor_bramble") --开局荆棘甲

TUNING.WORMWOOD_ARMOR_BRAMBLE_RELEASE_SPIKES_HITCOUNT = 1                      --荆棘专家攻击次数
TUNING.ARMORBRAMBLE_DMG = 35                                                   --荆棘甲反伤伤害
TUNING.ARMORBRAMBLE_DMG_PLANAR_UPGRADE = 40                                    --荆棘茄甲位面反伤

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

--树莓酱
AddRecipe2("treegrowthsolution",
    { Ingredient("moonglass", 1), Ingredient("goldnugget", 2), Ingredient("spoiled_food", 3) }, TECH.NONE_TWO,
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

-- 沃姆伍德消耗饱食度制作月亮蘑菇 prefab「moon_cap」（须用 AddRecipe2 才会进制作栏并 SetModRPCID；仅用 Recipe2 不会注册过滤器）
local WORMWOOD_MOON_CAP_RECIPE = "moon_cap"
local WORMWOOD_MOON_CAP_HUNGER_COST = 50

AddRecipe2(WORMWOOD_MOON_CAP_RECIPE,
	{},
	TECH.NONE,
	{
		builder_tag = "plantkin",
		product = "moon_cap",
		sg_state = "form_moon",
		actionstr = "GROW",
		allowautopick = true,
		no_deconstruction = true,
		description = "wormwood_moon_cap_recipe",
		canbuild = function(recipe, builder)
			local h = builder.components.hunger
			if h == nil then
				return false
			end
			if h.current >= WORMWOOD_MOON_CAP_HUNGER_COST then
				return true
			end
			return false, "WORMWOOD_MOON_CAP_HUNGER"
		end,
	},
	{ "CHARACTER" }
)

----------  亮茄小触手：自动索敌并进入攻击（修复召唤后不攻击）  ----------

local LUNARPLANT_TENTACLE_RETARGET_RANGE = 10
local LUNARPLANT_TENTACLE_FIND_MUST = { "_combat" }
local LUNARPLANT_TENTACLE_FIND_CANT = {
	"INLIMBO", "player", "playerghost", "companion", "wall", "abigail", "chester", "glommer",
	"hutch", "friendly", "lunarplanttentacle",
}

local function LunarPlantTentacleFindTarget(inst)
	if inst.components.combat == nil then
		return nil
	end
	local owner = inst.owner
	if owner ~= nil and owner:IsValid() and owner.components.combat ~= nil then
		local ct = owner.components.combat.target
		if ct ~= nil and ct:IsValid() and inst.components.combat:CanTarget(ct) then
			return ct
		end
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, LUNARPLANT_TENTACLE_RETARGET_RANGE, LUNARPLANT_TENTACLE_FIND_MUST, LUNARPLANT_TENTACLE_FIND_CANT)
	local best, bestsq
	for _, ent in ipairs(ents) do
		if ent ~= inst and ent ~= owner and ent.components.health ~= nil and not ent.components.health:IsDead()
			and inst.components.combat:CanTarget(ent) then
			local dsq = inst:GetDistanceSqToInst(ent)
			if bestsq == nil or dsq < bestsq then
				best = ent
				bestsq = dsq
			end
		end
	end
	return best
end

local function LunarPlantTentacleRetarget(inst)
	return LunarPlantTentacleFindTarget(inst)
end

local function LunarPlantTentacleEngage(inst, target, owner)
	if not inst:IsValid() or inst.components.combat == nil or inst.sg == nil then
		return
	end
	if owner ~= nil and owner:IsValid() then
		inst.owner = owner
	end
	local t = target
	if t == nil or not t:IsValid() or t.components.combat == nil then
		t = LunarPlantTentacleFindTarget(inst)
	end
	if t == nil then
		return
	end
	inst.components.combat:SetTarget(t)
	if not inst.sg:HasStateTag("attack") and inst.components.combat.target ~= nil then
		inst.sg:GoToState("taunt")
	end
end

AddPrefabPostInit("lunarplanttentacle", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.combat:SetRetargetFunction(0.25, LunarPlantTentacleRetarget)
	inst:DoTaskInTime(0, function()
		LunarPlantTentacleEngage(inst, inst.components.combat.target, inst.owner)
	end)
	inst:ListenForEvent("droppedtarget", function()
		inst:DoTaskInTime(0, function()
			LunarPlantTentacleEngage(inst, nil, inst.owner)
		end)
	end)
end)

AddComponentPostInit("lunarplant_tentacle_weapon", function(self)
	local old_should = self.should_do_tentacles_fn
	self.should_do_tentacles_fn = function(weapon, owner, attack_data)
		if owner ~= nil and owner:HasTag("plantkin") then
			return true
		end
		return old_should ~= nil and old_should(weapon, owner, attack_data)
	end
end)

----------  荆棘茄甲：沃姆伍德穿戴时，任意攻击命中概率召唤亮茄触手（等同月亮守卫2亮茄线，不限制武器）  ----------
-- 使用 onhitother：与 combat:GetAttacked 一致，在确实造成伤害时触发（onattackother 在部分流程下可能早于结算或与 mod 冲突）

local WORMWOOD_HUSK_TENTACLE_CHANCE = 0.1

local function WormwoodHuskTentacle_NoHoles(pt)
	return not TheWorld.Map:IsPointNearHole(pt)
end

local function WormwoodHuskTentacle_Spawn(target, pt, starting_angle, owner)
	local offset = FindWalkableOffset(pt, starting_angle, 2, 3, false, true, WormwoodHuskTentacle_NoHoles, false, true)
	if offset == nil then
		return
	end
	local tentacle = SpawnPrefab("lunarplanttentacle")
	if tentacle == nil then
		return
	end
	tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
	LunarPlantTentacleEngage(tentacle, target, owner)
end

local function WormwoodHuskTentacle_OnHitOther(inst, data)
	if data == nil then
		return
	end
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	local body = inv:GetEquippedItem(EQUIPSLOTS.BODY)
	if body == nil or body.prefab ~= "armor_lunarplant_husk" then
		return
	end
	local resolved = data.damageresolved ~= nil and math.abs(data.damageresolved) or (data.damage or 0)
	if resolved <= 0 then
		return
	end
	local weapon = data.weapon
	if weapon ~= nil and weapon.components.inventoryitem == nil then
		return
	end
	local target = data.target
	if target == nil or not target:IsValid() or target.components.combat == nil then
		return
	end
	if math.random() >= WORMWOOD_HUSK_TENTACLE_CHANCE then
		return
	end
	local pt = target:GetPosition()
	WormwoodHuskTentacle_Spawn(target, pt, math.random() * 2 * PI, inst)
end

----------  光合作用：亮光中回血，每次 +3 生命、消耗 5 饱食度（无需满开/白天）  ----------

local WORMWOOD_PHOTOSYNTHESIS_SKILL = "wormwood_blooming_photosynthesis"
local WORMWOOD_PHOTO_HEAL_AMOUNT = 3
local WORMWOOD_PHOTO_HUNGER_COST = 5
local WORMWOOD_PHOTO_PERIOD = 10

local function WormwoodHasPhotosynthesisSkill(inst)
	local skill = inst.components.skilltreeupdater
	return skill ~= nil and skill:IsActivated(WORMWOOD_PHOTOSYNTHESIS_SKILL)
end

local function WormwoodIsInBrightLight(inst)
	if inst:IsInLight() then
		return true
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	for _, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.DAYLIGHT_SEARCH_RANGE, { "daylight" }, { "INLIMBO" })) do
		if v.Light ~= nil then
			local lightrad = v.Light:GetCalculatedRadius() * 0.7
			if inst:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
				return true
			end
		end
	end
	return false
end

local function WormwoodShouldPhotosynthesize(inst)
	return not inst:HasTag("playerghost")
		and WormwoodHasPhotosynthesisSkill(inst)
		and WormwoodIsInBrightLight(inst)
end

local function WormwoodStopPhotosynthesisTask(inst)
	if inst._mod_photosynthesis_task ~= nil then
		inst._mod_photosynthesis_task:Cancel()
		inst._mod_photosynthesis_task = nil
	end
	inst.photosynthesizing = false
	if inst.components.health ~= nil then
		inst.components.health:RemoveRegenSource(inst, "photosynthesis_skill")
	end
end

local function WormwoodPhotosynthesisTick(inst)
	if not WormwoodShouldPhotosynthesize(inst) then
		if inst.photosynthesizing then
			inst.photosynthesizing = false
		end
		return
	end
	inst.photosynthesizing = true
	local health = inst.components.health
	local hunger = inst.components.hunger
	if health == nil or health:IsDead() or not health.canheal then
		return
	end
	if hunger == nil or hunger.current < WORMWOOD_PHOTO_HUNGER_COST then
		return
	end
	hunger:DoDelta(-WORMWOOD_PHOTO_HUNGER_COST)
	health:DoDelta(WORMWOOD_PHOTO_HEAL_AMOUNT, true, "photosynthesis_skill")
end

local function WormwoodEnsurePhotosynthesisTask(inst)
	if not WormwoodHasPhotosynthesisSkill(inst) then
		WormwoodStopPhotosynthesisTask(inst)
		return
	end
	if inst._mod_photosynthesis_task == nil then
		inst._mod_photosynthesis_task = inst:DoPeriodicTask(WORMWOOD_PHOTO_PERIOD, WormwoodPhotosynthesisTick)
	end
end

local function WormwoodModUpdatePhotosynthesisState(inst, _)
	if inst.components.health ~= nil then
		inst.components.health:RemoveRegenSource(inst, "photosynthesis_skill")
	end
	inst.photosynthesizing = WormwoodShouldPhotosynthesize(inst)
end

local function WormwoodPatchPhotosynthesisSkilltree()
	local skilltreedefs = require("prefabs/skilltree_defs")
	local defs = skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.wormwood
	if defs == nil or defs[WORMWOOD_PHOTOSYNTHESIS_SKILL] == nil or defs[WORMWOOD_PHOTOSYNTHESIS_SKILL]._mod_photosynthesis_patched then
		return
	end
	local skill = defs[WORMWOOD_PHOTOSYNTHESIS_SKILL]
	skill._mod_photosynthesis_patched = true
	local old_on = skill.onactivate
	local old_off = skill.ondeactivate
	skill.onactivate = function(inst)
		if old_on ~= nil then
			old_on(inst)
		end
		if inst.StopWatchingWorldState ~= nil then
			inst:StopWatchingWorldState("isday", inst.UpdatePhotosynthesisState)
		end
		WormwoodEnsurePhotosynthesisTask(inst)
	end
	skill.ondeactivate = function(inst)
		if old_off ~= nil then
			old_off(inst)
		end
		if inst.StopWatchingWorldState ~= nil then
			inst:StopWatchingWorldState("isday", inst.UpdatePhotosynthesisState)
		end
		WormwoodStopPhotosynthesisTask(inst)
	end
end

AddSimPostInit(WormwoodPatchPhotosynthesisSkilltree)

TUNING.WORMWOOD_PHOTOSYNTHESIS_HEALTH_REGEN = { amount = WORMWOOD_PHOTO_HEAL_AMOUNT, period = WORMWOOD_PHOTO_PERIOD }

AddPrefabPostInit("wormwood", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.UpdatePhotosynthesisState = WormwoodModUpdatePhotosynthesisState
	WormwoodEnsurePhotosynthesisTask(inst)
	inst:ListenForEvent("onactivateskill_server", function(_, data)
		if data ~= nil and data.skill == WORMWOOD_PHOTOSYNTHESIS_SKILL then
			WormwoodEnsurePhotosynthesisTask(inst)
		end
	end)
	inst:ListenForEvent("ondeactivateskill_server", function(_, data)
		if data ~= nil and data.skill == WORMWOOD_PHOTOSYNTHESIS_SKILL then
			WormwoodStopPhotosynthesisTask(inst)
		end
	end)
	WormwoodInstallHuskHealModifier(inst)
	WormwoodEnsureHuskRegenTask(inst)
	inst:ListenForEvent("onhitother", WormwoodHuskTentacle_OnHitOther)
	inst:ListenForEvent("builditem", function(_, data)
		if data.recipe ~= nil and data.recipe.name == WORMWOOD_MOON_CAP_RECIPE then
			local hunger = inst.components.hunger
			if hunger ~= nil then
				hunger:DoDelta(-WORMWOOD_MOON_CAP_HUNGER_COST)
			end
		end
	end)
	return inst
end)

----------  月亮蘑菇催眠孢子云（sleepcloud_lunar）：贴图与实际范围 ×1.2  ----------

local SLEEPCLOUD_LUNAR_VANILLA_RANGE = 3.5
local SLEEPCLOUD_LUNAR_MULT = 1.2
local SLEEPCLOUD_LUNAR_RANGE = SLEEPCLOUD_LUNAR_VANILLA_RANGE * SLEEPCLOUD_LUNAR_MULT
local SLEEPCLOUD_LUNAR_SCALE = SLEEPCLOUD_LUNAR_MULT
local SLEEPCLOUD_LUNAR_TICK = 0.5
local SLEEPCLOUD_LUNAR_TICK_VALUE = 10
local SLEEPCLOUD_LUNAR_MAX_SLEEP = 5
local SLEEPCLOUD_LUNAR_MIN_SLEEP = 1.5
local SLEEPCLOUD_LUNAR_PLAYER_TICK = 1
local SLEEPCLOUD_LUNAR_PLAYER_MAX_SLEEP = 4
local SLEEPCLOUD_LUNAR_PLAYER_MIN_SLEEP = 1
local SLEEPCLOUD_LUNAR_ATTACK_DELAY = 2
local SLEEPCLOUD_LUNAR_CHAIN_DELAY = 4
local SLEEPCLOUD_LUNAR_PVP_ONEOF = { "sleeper", "player" }
local SLEEPCLOUD_LUNAR_PVP_CANT = { "playerghost", "FX", "DECOR", "INLIMBO" }
local SLEEPCLOUD_LUNAR_MUST = { "sleeper" }
local SLEEPCLOUD_LUNAR_CANT = { "player", "FX", "DECOR", "INLIMBO" }

local function WormwoodLunarSleepcloudDoAreaDrowsy(inst, sleeptimecache, sleepdelaycache)
	local x, y, z = inst.Transform:GetWorldPosition()
	local t = GetTime()
	local ents = TheNet:GetPVPEnabled()
		and TheSim:FindEntities(x, y, z, SLEEPCLOUD_LUNAR_RANGE, nil, SLEEPCLOUD_LUNAR_PVP_CANT, SLEEPCLOUD_LUNAR_PVP_ONEOF)
		or TheSim:FindEntities(x, y, z, SLEEPCLOUD_LUNAR_RANGE, SLEEPCLOUD_LUNAR_MUST, SLEEPCLOUD_LUNAR_CANT)
	for _, v in ipairs(ents) do
		if v ~= inst.owner then
			local delayed = false
			if (sleepdelaycache[v] or 0) > SLEEPCLOUD_LUNAR_TICK then
				if v.components.sleeper ~= nil then
					if not v.components.sleeper:IsAsleep() then
						sleepdelaycache[v] = sleepdelaycache[v] - SLEEPCLOUD_LUNAR_TICK
						delayed = true
					end
				elseif v.components.grogginess ~= nil and not v.components.grogginess:IsKnockedOut() then
					sleepdelaycache[v] = sleepdelaycache[v] - SLEEPCLOUD_LUNAR_TICK
					delayed = true
				end
			end
			if not delayed
				and not (v.components.combat ~= nil and v.components.combat:GetLastAttackedTime() + SLEEPCLOUD_LUNAR_ATTACK_DELAY > t)
				and not (v.components.burnable ~= nil and v.components.burnable:IsBurning())
				and not (v.components.freezable ~= nil and v.components.freezable:IsFrozen())
				and not (v.components.pinnable ~= nil and v.components.pinnable:IsStuck())
				and not (v.components.fossilizable ~= nil and v.components.fossilizable:IsFossilized())
			then
				local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil
				if mount ~= nil then
					mount:PushEvent("ridersleep", { sleepiness = SLEEPCLOUD_LUNAR_TICK_VALUE, sleeptime = SLEEPCLOUD_LUNAR_MAX_SLEEP })
				end
				if v.components.sleeper ~= nil then
					local sleeptime = sleeptimecache[v] or SLEEPCLOUD_LUNAR_MAX_SLEEP
					v.components.sleeper:AddSleepiness(
						SLEEPCLOUD_LUNAR_TICK_VALUE,
						sleeptime / v.components.sleeper:GetSleepTimeMultiplier()
					)
					if v.components.sleeper:IsAsleep() then
						sleeptimecache[v] = math.max(SLEEPCLOUD_LUNAR_MIN_SLEEP, sleeptime - SLEEPCLOUD_LUNAR_TICK)
						sleepdelaycache[v] = SLEEPCLOUD_LUNAR_CHAIN_DELAY
					else
						sleeptimecache[v] = nil
					end
				elseif v.components.grogginess ~= nil then
					local sleeptime = sleeptimecache[v] or SLEEPCLOUD_LUNAR_PLAYER_MAX_SLEEP
					if v.components.grogginess:IsKnockedOut() then
						v.components.grogginess:ExtendKnockout(sleeptime)
						sleeptimecache[v] = math.max(SLEEPCLOUD_LUNAR_PLAYER_MIN_SLEEP, sleeptime - SLEEPCLOUD_LUNAR_TICK)
						sleepdelaycache[v] = SLEEPCLOUD_LUNAR_CHAIN_DELAY
					else
						v.components.grogginess:AddGrogginess(SLEEPCLOUD_LUNAR_PLAYER_TICK, sleeptime)
						if v.components.grogginess:IsKnockedOut() then
							sleeptimecache[v] = math.max(SLEEPCLOUD_LUNAR_PLAYER_MIN_SLEEP, sleeptime - SLEEPCLOUD_LUNAR_TICK)
							sleepdelaycache[v] = SLEEPCLOUD_LUNAR_CHAIN_DELAY
						else
							sleeptimecache[v] = nil
						end
					end
				else
					v:PushEvent("knockedout")
				end
			else
				sleeptimecache[v] = nil
			end
		end
	end
end

local function WormwoodSetupLunarSleepcloudRange(inst)
	inst.Transform:SetScale(SLEEPCLOUD_LUNAR_SCALE, SLEEPCLOUD_LUNAR_SCALE, SLEEPCLOUD_LUNAR_SCALE)
	if not TheWorld.ismastersim then
		return
	end
	if inst._drowsytask ~= nil then
		inst._drowsytask:Cancel()
		inst._drowsytask = nil
	end
	inst._drowsytask = inst:DoPeriodicTask(SLEEPCLOUD_LUNAR_TICK, WormwoodLunarSleepcloudDoAreaDrowsy, nil, {}, {})
end

AddPrefabPostInit("sleepcloud_lunar", function(inst)
	inst:DoTaskInTime(0, WormwoodSetupLunarSleepcloudRange)
end)
