--月鹿
AddPrefabPostInit("mutateddeerclops", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
end)

--月狼
AddPrefabPostInit("mutatedwarg", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('purebrilliance', 1)
	inst.components.lootdropper:AddChanceLoot('purebrilliance', 1)
end)

--月熊
AddPrefabPostInit("mutatedbearger", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('security_pulse_cage', 1) --火花柜
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
end)

--海象
AddPrefabPostInit("walrus", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('walrus_tusk', 0.5) --象牙
end)

--铁巨人
AddPrefabPostInit("ancient_hulk", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('eyeturret_item', 1)       --眼球塔
	inst.components.lootdropper:AddChanceLoot('armorskeleton', 1)        --骨甲
	inst.components.lootdropper:AddChanceLoot('armorskeleton', 1)        --骨甲
	inst.components.lootdropper:AddChanceLoot('armorskeleton_blueprint', 1) --骨甲蓝图
	inst.components.lootdropper:AddChanceLoot('opalpreciousgem', 1)      --彩虹宝石
	inst.components.lootdropper:AddChanceLoot('opalpreciousgem', 1)      --彩虹宝石
	inst.components.lootdropper:AddChanceLoot('brainjellyhat', 1)
	inst.components.lootdropper:AddChanceLoot('brainjellyhat_blueprint', 1)
end)

--小海象
AddPrefabPostInit("little_walrus", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('walrus_tusk', 0.5) --象牙
end)

-- 伏特羊额外羊角
AddPrefabPostInit("lightninggoat", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('lightninggoathorn', 0.05)
end)

-- 龙蝇额外羊角和宝石
AddPrefabPostInit("dragonfly", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('lightninggoathorn', 1)

	inst.components.lootdropper:AddChanceLoot('greengem', 1)
	inst.components.lootdropper:AddChanceLoot('greengem', 1)

	inst.components.lootdropper:AddChanceLoot('yellowgem', 1)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 1)

	inst.components.lootdropper:AddChanceLoot('orangegem', 1)
	inst.components.lootdropper:AddChanceLoot('orangegem', 1)

	inst.components.lootdropper:AddChanceLoot('redgem', 1)
	inst.components.lootdropper:AddChanceLoot('redgem', 1)

	inst.components.lootdropper:AddChanceLoot('purplegem', 1)
	inst.components.lootdropper:AddChanceLoot('purplegem', 1)

	inst.components.lootdropper:AddChanceLoot('bluegem', 1)
	inst.components.lootdropper:AddChanceLoot('bluegem', 1)

	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
end)


--额外亮茄壳
AddPrefabPostInit("lunarthrall_plant", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
	inst.components.lootdropper:AddChanceLoot('lunarplant_husk', 1)
end)

--墨荒暗影碎布翻倍
for k, v in ipairs({ "horns", "wings", "mouth", "hands" }) do
	AddPrefabPostInit("shadowthrall_" .. v, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		inst.components.lootdropper:SetLoot({ "voidcloth", "voidcloth", "voidcloth" })
	end)
end

--潜伏梦魇掉碎布和三色宝石
AddPrefabPostInit("ruinsnightmare", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('voidcloth', 0.8)
	inst.components.lootdropper:AddChanceLoot('voidcloth', 0.5)
	inst.components.lootdropper:AddChanceLoot('voidcloth', 0.3)
	inst.components.lootdropper:AddChanceLoot('greengem', 0.1)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 0.1)
	inst.components.lootdropper:AddChanceLoot('orangegem', 0.1)
end)

--克劳斯掉落小偷包
AddPrefabPostInit("klaus", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('krampus_sack', 1)
	inst.components.lootdropper:AddChanceLoot('krampus_sack', 0.1)
	inst.components.lootdropper:AddChanceLoot('moonrockseed', 1)
end)

--果蝇王掉落辣蒜葱
local function LordLootSetupFunction(lootdropper)
	lootdropper:AddChanceLoot("fruitflyfruit", 1.0)
	lootdropper:AddChanceLoot('soil_amender_fermented', 1)

	for i = 1, 6 do
		lootdropper:AddChanceLoot("garlic_seeds", 1.0)
		lootdropper:AddChanceLoot("pepper_seeds", 1.0)
		lootdropper:AddChanceLoot("onion_seeds", 1.0)
		lootdropper:AddChanceLoot("dragonfruit_seeds", 1.0)
	end

	for i = 1, 6 do
		lootdropper:AddChanceLoot("garlic_seeds", 0.5)
		lootdropper:AddChanceLoot("pepper_seeds", 0.5)
		lootdropper:AddChanceLoot("onion_seeds", 0.5)
		lootdropper:AddChanceLoot("dragonfruit_seeds", 1.0)
	end
end

AddPrefabPostInit("lordfruitfly", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.lootdropper:SetLootSetupFn(LordLootSetupFunction)
end)


--勇者的证明掉落
RegisterInventoryItemAtlas("images/coin_1.xml", "coin_1.tex")
STRINGS.NAMES.COIN_1 = "勇者的证明"

ListOfBoss = {
	"malbatross",    --邪天翁
	"minotaur",      --犀牛
	"mutateddeerclops", --月鹿
	"mutatedbearger", --月熊
	"antlion",       --蚁狮
	"dragonfly",     --龙蝇
	"beequeen",      --蜂后
	"twinofterror1",
	"twinofterror2", --双子
	"klaus",         --克劳斯
	"moose",         --春鹅
	"eyeofterror",   --大眼
	"toadstool_dark", --大蛤蟆
	"toadstool",     --蛤蟆
}
for k, v in ipairs(ListOfBoss) do
	AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		inst.components.lootdropper:AddChanceLoot('coin_1', 1)
	end)
end

--天体一阶段
AddPrefabPostInit("alterguardian_phase1", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('yellowstaff', 1)
end)

--天体二阶段
AddPrefabPostInit("alterguardian_phase2", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('staff_lunarplant', 1)
end)

--天体三阶段
AddPrefabPostInit("alterguardian_phase3", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('yellowstaff', 1)
end)

-- 被击败的天体英雄
AddPrefabPostInit("alterguardian_phase3dead", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('stalker_atrium', 1)
end)

-- 只因掉落巨鹿
local function AtriumLootFn(lootdropper)
	lootdropper:SetLoot(nil)
	if lootdropper.inst.atriumdecay then
		lootdropper:AddChanceLoot("shadowheart", 1)
	else
		lootdropper:AddChanceLoot("thurible", 1)
		lootdropper:AddChanceLoot("armorskeleton", 1)
		lootdropper:AddChanceLoot("skeletonhat", 1)
		lootdropper:AddChanceLoot("chesspiece_stalker_sketch", 1)
		lootdropper:AddChanceLoot("nightmarefuel", 1)
		lootdropper:AddChanceLoot("nightmarefuel", 1)
		lootdropper:AddChanceLoot("nightmarefuel", 1)
		lootdropper:AddChanceLoot("nightmarefuel", 1)
		lootdropper:AddChanceLoot("nightmarefuel", .5)
		lootdropper:AddChanceLoot("nightmarefuel", .5)

		if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
			lootdropper:AddChanceLoot("winter_ornament_boss_fuelweaver", 1)
			lootdropper:AddChanceLoot(GetRandomBasicWinterOrnament(), 1)
			lootdropper:AddChanceLoot(GetRandomBasicWinterOrnament(), 1)
			lootdropper:AddChanceLoot(GetRandomBasicWinterOrnament(), 1)
		end

		-- 一半概率鱼啦啦，一半概率白云
		lootdropper:AddChanceLoot("alterguardian_phase1_lunarrift", 1)
		if math.random() < 0.5 then
			lootdropper:AddChanceLoot("deerclops", 1)
		else
			for i = 1, 30 do
				lootdropper:AddChanceLoot('cursed_monkey_token', 1)
			end
			lootdropper:AddChanceLoot('ironlord_death', 1)
		end
	end
end

AddPrefabPostInit("stalker_atrium", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.lootdropper:SetLootSetupFn(AtriumLootFn)
end)

-- 普通巨鹿掉落10个诅咒饰品
AddPrefabPostInit("deerclops", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	for i = 1, 10 do
		inst.components.lootdropper:AddChanceLoot('cursed_monkey_token', 1)
	end
end)

-- 鱼啦啦掉落12个敌对信号弹
AddPrefabPostInit("mutateddeerclops", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	for i = 1, 12 do
		inst.components.lootdropper:AddChanceLoot('megaflare', 1)
		inst.components.lootdropper:AddChanceLoot('torch', 1)
	end
end)

--鲨鱼
AddPrefabPostInit("shark", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('messagebottle', 0.8)
	inst.components.lootdropper:AddChanceLoot('chum', 0.5)
	inst.components.lootdropper:AddChanceLoot('chum', 1)
end)

--独角鲸
AddPrefabPostInit("gnarwail", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('messagebottle', 1.0)
	inst.components.lootdropper:AddChanceLoot('chum', 0.5)
	inst.components.lootdropper:AddChanceLoot('chum', 0.5)
end)

-- 蠕虫和巨大蠕虫
TUNING.WORMLIGHT_NIGHTVISION_DURATION = 120 -- 夜视持续时间，单位秒
local function NightVision_OnEaten(inst, eater)
	if eater.components.playervision ~= nil then
		eater:AddDebuff("nightvision_buff", "nightvision_buff")
	end
	if eater.components.grogginess ~= nil and eater.components.grogginess.MakeGrogginessAtLeast ~= nil then
		eater.components.grogginess:MakeGrogginessAtLeast(1.5)
	end
end


AddPrefabPostInit("ancientfruit_nightvision", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.edible:SetOnEatenFn(NightVision_OnEaten)
end)

local function GetRandomKillThreshold()
	return math.random(3, 6)
end

local WORM_KILL_THRESHOLD = GetRandomKillThreshold()
local WORM_KILL_COUNT = 0

AddPrefabPostInit("worm", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:ListenForEvent("death", function(inst)
		WORM_KILL_COUNT = WORM_KILL_COUNT + 1

		if WORM_KILL_COUNT >= WORM_KILL_THRESHOLD then
			if inst.components.lootdropper then
				inst.components.lootdropper:SpawnLootPrefab("worm_boss")
			end
			WORM_KILL_COUNT = 0
			WORM_KILL_THRESHOLD = GetRandomKillThreshold()
		end
	end)

	inst.components.lootdropper:AddChanceLoot('ancientfruit_nightvision', 0.05)
end)


-- 巨大蠕虫的掉落物
AddPrefabPostInit("worm_boss", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('meat', 1)
	inst.components.lootdropper:AddChanceLoot('meat', 1)
	inst.components.lootdropper:AddChanceLoot('meat', 1)

	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)

	-- -- 不是哥们，真别掉成品装备
	-- inst.components.lootdropper:AddChanceLoot('greenamulet', 0.3)
	-- inst.components.lootdropper:AddChanceLoot('ruinshat', 0.4)
	-- inst.components.lootdropper:AddChanceLoot('multitool_axe_pickaxe', 0.4)
	-- inst.components.lootdropper:AddChanceLoot('yellowstaff', 0.3)
	-- inst.components.lootdropper:AddChanceLoot('yellowamulet', 0.9)
	-- inst.components.lootdropper:AddChanceLoot('ruins_bat', 0.2)
	-- inst.components.lootdropper:AddChanceLoot('opalstaff', 0.1)

	inst.components.lootdropper:AddChanceLoot('ancientfruit_nightvision', 0.75)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_nightvision', 0.5)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_nightvision', 0.25)

	inst.components.lootdropper:AddChanceLoot('greengem', 1)
	inst.components.lootdropper:AddChanceLoot('greengem', 0.7)
	inst.components.lootdropper:AddChanceLoot('greengem', 0.3)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 1)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 0.5)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 0.5)
	inst.components.lootdropper:AddChanceLoot('yellowgem', 0.5)
	inst.components.lootdropper:AddChanceLoot('orangegem', 1)
	inst.components.lootdropper:AddChanceLoot('orangegem', 0.5)

	inst.components.lootdropper:AddChanceLoot('redgem', 0.5)
	inst.components.lootdropper:AddChanceLoot('redgem', 0.4)
	inst.components.lootdropper:AddChanceLoot('redgem', 0.4)
	inst.components.lootdropper:AddChanceLoot('redgem', 0.3)
	inst.components.lootdropper:AddChanceLoot('redgem', 0.3)

	inst.components.lootdropper:AddChanceLoot('purplegem', 1)
	inst.components.lootdropper:AddChanceLoot('purplegem', 1)
	inst.components.lootdropper:AddChanceLoot('purplegem', 0.5)
	inst.components.lootdropper:AddChanceLoot('purplegem', 0.5)
	inst.components.lootdropper:AddChanceLoot('purplegem', 0.5)

	inst.components.lootdropper:AddChanceLoot('bluegem', 1)
	inst.components.lootdropper:AddChanceLoot('bluegem', 1)
	inst.components.lootdropper:AddChanceLoot('bluegem', 0.3)
	inst.components.lootdropper:AddChanceLoot('bluegem', 0.3)
	inst.components.lootdropper:AddChanceLoot('bluegem', 0.3)

	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
	inst.components.lootdropper:AddChanceLoot('ancientfruit_gem', 1)
end)

-- 帝王蟹掉落锯马蓝图
AddPrefabPostInit("crabking", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('carpentry_station_blueprint', 1.0)
end)

-- 蔓草掉落曼德拉长老

-- local function ondeath(inst)
-- 	local mandrake = SpawnPrefab("mandrake")
-- 	mandrake.Transform:SetPosition(inst.Transform:GetWorldPosition())
-- 	mandrake.AnimState:PlayAnimation("death")
-- 	mandrake.AnimState:SetTime(mandrake.AnimState:GetCurrentAnimationLength())

-- 	local mandrakeman = SpawnPrefab("mandrakeman")
-- 	mandrakeman.Transform:SetPosition(inst.Transform:GetWorldPosition())

-- 	inst:Remove()
-- end


-- AddPrefabPostInit("mandrake_active", function(inst)
-- 	if not TheWorld.ismastersim then
-- 		return inst
-- 	end

-- 	inst.ondeath = ondeath
-- end)

--节日蠕虫掉巨大蠕虫
AddPrefabPostInit("yots_worm", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('worm_boss', 0.2)
end)

--眼球哨塔
AddPrefabPostInit("shadoweyeturret", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
end)

--眼球哨塔
AddPrefabPostInit("shadoweyeturret2", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
	inst.components.lootdropper:AddChanceLoot('thulecite', 1)
end)
