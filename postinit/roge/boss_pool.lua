-- roge/boss_pool.lua

-- 怪物池、Boss 血量、各类召唤物

-- ====== spawn_pools ======
-- ====== 怪物池 =====
SMALL_CREATURES = { "gingerbreadwarg","lordfruitfly" ,"grassgator","nightmarebeak","chest_mimic_revealed","koalefant_summer","koalefant_winter","mandrakeman","fused_shadeling","archive_centipede","beefalo","mandrakeman","bishop_nightmare","crabking_mob_knight","bishop","gingerbreadwarg","cave_vent_mite","knight_nightmare","krampus","lightninggoat","merm","pigguard","powder_monkey","rabbitkingminion_bunnyman","rook_nightmare","rocky","squid","tallbird","warglet","worm","shadow_bishop","shadow_rook" }
ROGE_CLOCKWORK_SQUAD_KEY = "roge_clockwork_squad"
ROGE_LUNARFROG_RAIN_KEY = "roge_lunarfrog_rain"
ROGE_WALRUS_SQUAD_KEY = "roge_walrus_squad"
ROGE_MERMGUARD_PACK_KEY = "roge_mermguard_pack"
ROGE_MERMCORPS_KEY = "roge_mermcorps"
ROGE_PIGELITE_SQUAD_KEY = "roge_pigelite_squad"
ROGE_CRABKNIGHT_SQUAD_KEY = "roge_crabknight_squad"
ROGE_EYETURRET_OUTPOST_KEY = "roge_eyeturret_outpost"
MINI_BOSSES     = { "deer_blue","deer_red","walrus","mossling","ruinsnightmare","rabbitking_aggressive","mossling","shadowthrall_hands","shadowthrall_horns","shadowthrall_mouth","shadowdragon","pigtorch","prime_mate","mutatedbuzzard_gestalt", ROGE_LUNARFROG_RAIN_KEY, ROGE_CLOCKWORK_SQUAD_KEY, ROGE_MERMGUARD_PACK_KEY, ROGE_MERMCORPS_KEY, ROGE_PIGELITE_SQUAD_KEY, ROGE_CRABKNIGHT_SQUAD_KEY,"shadow_bishop", "shadow_rook", "spiderqueen", "spider_robot" }
LARGE_BOSSES    = { "moose","sharkboi","twinofterror2","twinofterror1","warg","eyeofterror","bearger","mutatedwarg","stalker","shadow_bishop","shadow_rook","klaus","mutatedbearger","dragonfly","fissure_lower","nightmarelight", ROGE_EYETURRET_OUTPOST_KEY, "daywalker2" }

-- boss 池眼球哨卫：2×2 码头地皮 + 眼球守卫1/2 各一 + 发条主教/骑士各4 + 梦魇灯座1
ROGE_EYETURRET_OUTPOST_DOCK_TILE = WORLD_TILES.MONKEY_DOCK

-- 精英池抽到 pigtorch 时，火炬周围立刻生成 6 名猪守卫
ROGE_PIGTORCH_GUARD_COUNT = 6
ROGE_PIGTORCH_GUARD_RADIUS = 3.5
-- 强怪池 spider_robot：出场即为死亡状态，首次 30 秒必定复活，之后复活 90 秒
-- 强怪池 spiderqueen：身边额外生成穴居/喷吐/护士蜘蛛
ROGE_SPIDERQUEEN_MINION_RADIUS = 4
ROGE_SPIDERQUEEN_EXTRA_SPAWNS = {
	{ prefab = "spider_hider", count = 6 },   -- 穴居蜘蛛
	{ prefab = "spider_spitter", count = 4 }, -- 喷吐蜘蛛
	{ prefab = "spider_healer", count = 3 },  -- 护士蜘蛛
}
-- 精英池 roge_clockwork_squad：一次性 3 骑士 + 3 主教 + 3 战车（发条）
-- 精英池 roge_crabknight_squad：蟹骑士头领 + 2 随从（800 血）+ 6 蟹卫（各跟一只骑士）
ROGE_CLOCKWORK_SQUAD_RADIUS = 5
ROGE_CLOCKWORK_SQUAD_SPAWNS = {
	{ prefab = "knight", count = 3 },
	{ prefab = "bishop", count = 3 },
	{ prefab = "rook", count = 3 },
}
-- 精英池 knight_yoth：本体 + 周围额外 4 只
ROGE_KNIGHT_YOTH_EXTRA_COUNT = 4
ROGE_KNIGHT_YOTH_EXTRA_RADIUS = 5
-- 精英池明眼青蛙雨：60 秒内于 10 地皮范围内落下 25-35 只 lunarfrog
ROGE_TURF_SIZE = 4
ROGE_EYETURRET_OUTPOST_CLOCKWORK_RADIUS = ROGE_TURF_SIZE * 1.35
ROGE_LUNARFROG_RAIN_DURATION = 60
ROGE_LUNARFROG_RAIN_COUNT_MIN = 25
ROGE_LUNARFROG_RAIN_COUNT_MAX = 35
ROGE_LUNARFROG_RAIN_RADIUS = 10 * ROGE_TURF_SIZE
ROGE_LUNARFROG_RAIN_SPAWN_HEIGHT = 35
ROGE_LUNARFROG_HEALTH = 200
-- 精英池 prime_mate：随机武器 + 铥矿帽，600 血，死亡不掉武器
ROGE_PRIME_MATE_HEALTH = 600
ROGE_PRIME_MATE_WEAPONS = {
	"pocketwatch_weapon", -- 警钟 81
	"icestaff3",          -- 深冻魔杖 无近战伤害
	"firestaff",          -- 火魔杖 无近战伤害
	"nightstick",         -- 晨星锤 51
}
ROGE_PRIME_MATE_WEAPON_DAMAGE = {
	pocketwatch_weapon = 81,
	icestaff3 = 0,
	firestaff = 0,
	nightstick = 51,
}

local function RogePrimeMateApplyControlledLongBurn(target)
	if target == nil or not target:IsValid() then
		return
	end
	local burnable = target.components.burnable
	if burnable == nil or not burnable:IsBurning() then
		return
	end
	burnable.controlled_burn = {
		duration_creature = TUNING.CONTROLLED_BURN_DURATION_CREATURE_MULT or 3,
	}
	if burnable.ExtendBurning ~= nil then
		burnable:ExtendBurning()
	end
	if burnable.fxchildren ~= nil then
		for _, fx in ipairs(burnable.fxchildren) do
			if fx ~= nil and fx:IsValid() and fx.components.firefx ~= nil then
				fx.components.firefx:SetLevel(burnable.fxlevel or 1, true, burnable.controlled_burn)
			end
		end
	end
end

local function RogeSetupPrimeMateFirestaff(weapon)
	if weapon == nil or weapon.prefab ~= "firestaff" or weapon.components.weapon == nil then
		return
	end
	if weapon._roge_prime_mate_firestaff_hooked then
		return
	end
	weapon._roge_prime_mate_firestaff_hooked = true
	local old_onattack = weapon.components.weapon.onattack
	weapon.components.weapon:SetOnAttack(function(wep, attacker, target, skipsanity)
		if old_onattack ~= nil then
			old_onattack(wep, attacker, target, skipsanity)
		end
		if attacker ~= nil and attacker:IsValid() and attacker.prefab == "prime_mate" then
			RogePrimeMateApplyControlledLongBurn(target)
		end
	end)
end

-- boss 池 nightmarelight：周围额外 5-7 盏，立刻暴动，15 秒后移除本次召唤的全部灯座
ROGE_NIGHTMARELIGHT_EXTRA_MIN = 6
ROGE_NIGHTMARELIGHT_EXTRA_MAX = 8
ROGE_NIGHTMARELIGHT_EXTRA_RADIUS_MIN = 6
ROGE_NIGHTMARELIGHT_EXTRA_RADIUS_MAX = 14
ROGE_NIGHTMARELIGHT_LIFETIME = 30

-- 肉鸽召唤的大霜鲨：击败（minhealth）后 5 秒移除尸体，避免长期留在场上
ROGE_SHARKBOI_DEFEAT_DESPAWN_DELAY = 5
ROGE_SHARKBOI_HEALTH = 5000
ROGE_SHARKBOI_HEALTH_DAY8 = 8000
ROGE_SHARKBOI_ICESPIKE_LIFETIME_MIN = 60
ROGE_SHARKBOI_ICESPIKE_LIFETIME_MAX = 80
ROGE_STALKER_HEALTH = 5000
ROGE_STALKER_HEALTH_DAY8 = 8000

-- boss 池抽到 fissure_lower 时，在裂隙旁额外生成暗影三件套
ROGE_FISSURE_THRALL_SPAWNS = {
	{ prefab = "shadowthrall_horns", count = 1 },
	{ prefab = "shadowthrall_hands", count = 1 },
	{ prefab = "shadowthrall_mouth", count = 3 },
}

-- ====== 根据百分位选生�?======
-- pct = roll/max*100；Boss 池未解锁时封顶精英
ROGE_SPAWN_POOL_SMALL = 1
ROGE_SPAWN_POOL_ELITE = 2
ROGE_SPAWN_POOL_LARGE = 3

function RogeResolveSpawnPool(roll_result, max_sides)
	if not IsWeakPoolUnlocked() or IsDiceWeakPoolOnlyPhase() then
		return SMALL_CREATURES, ROGE_SPAWN_POOL_SMALL
	end
	local maxv = math.max(max_sides or DEFAULT_DICE_SIDES, 1)
	local pct = (roll_result / maxv) * 100
	if pct < DICE_PCT_NORMAL_MAX then
		if IsNormalPoolReplacedByElite() and IsElitePoolUnlocked() then
			return MINI_BOSSES, ROGE_SPAWN_POOL_ELITE
		end
		return SMALL_CREATURES, ROGE_SPAWN_POOL_SMALL
	end
	if pct < DICE_PCT_ELITE_MAX then
		if not IsElitePoolUnlocked() then
			return SMALL_CREATURES, ROGE_SPAWN_POOL_SMALL
		end
		return MINI_BOSSES, ROGE_SPAWN_POOL_ELITE
	end
	if not IsLargeBossDiceUnlocked() then
		if IsElitePoolUnlocked() then
			return MINI_BOSSES, ROGE_SPAWN_POOL_ELITE
		end
		return SMALL_CREATURES, ROGE_SPAWN_POOL_SMALL
	end
	return LARGE_BOSSES, ROGE_SPAWN_POOL_LARGE
end

function GetSpawnPrefab(roll_result, max_sides)
	local pool = RogeResolveSpawnPool(roll_result, max_sides)
	return pool[math.random(#pool)]
end

function RogePickSpawn(roll_result, max_sides)
	local pool, tier = RogeResolveSpawnPool(roll_result, max_sides)
	return pool[math.random(#pool)], tier
end

-- ====== boss_scaling ======
-- 暗影棋子：小怪池 1 级 / 精英池 2 级 / 巨型池 3 级（并套用下方自定义血量）
ROGE_SHADOW_CHESS_MAX_LEVEL = 3
ROGE_SHADOW_CHESS_LEVEL_BY_POOL = {
	[ROGE_SPAWN_POOL_SMALL] = 1,
	[ROGE_SPAWN_POOL_ELITE] = 2,
	[ROGE_SPAWN_POOL_LARGE] = 3,
}
ROGE_SHADOW_BISHOP_HEALTH_L2 = 1200
ROGE_SHADOW_KNIGHT_HEALTH_L2 = 2000
ROGE_SHADOW_ROOK_HEALTH_L1 = 1500
ROGE_SHADOW_ROOK_HEALTH_L2 = 2500
ROGE_SHADOW_BISHOP_HEALTH = 3000
ROGE_SHADOW_BISHOP_HEALTH_DAY8 = 4000 -- 第 8 天起（UI Day>=8），不再 ×2 通用倍率
ROGE_SHADOW_KNIGHT_HEALTH = 5000
ROGE_SHADOW_ROOK_HEALTH = 4500
ROGE_SHADOW_ROOK_HEALTH_DAY8 = 6500 -- 第 8 天起三级暗影战车
ROGE_SHADOW_CHESS_PREFABS = {
	shadow_bishop = true,
	shadow_knight = true,
	shadow_rook = true,
}

local function RogeSetShadowChessMaxHealth(inst, maxhp, skip_day8_mult)
	if maxhp == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	local pct = inst.components.health:GetPercent()
	if skip_day8_mult or inst.prefab == "shadow_bishop" or inst.prefab == "shadow_rook" then
		inst.components.health:SetMaxHealth(maxhp)
		inst.components.health:SetPercent(pct)
	else
		RogeScaleAdjustedMaxHealth(inst, maxhp)
	end
end

local function RogeGetShadowChessCustomHealth(inst)
	local level = inst.level or 1
	if level == 1 then
		if inst.prefab == "shadow_rook" then
			return ROGE_SHADOW_ROOK_HEALTH_L1
		end
		return nil
	end
	if level == 2 then
		if inst.prefab == "shadow_bishop" then
			return ROGE_SHADOW_BISHOP_HEALTH_L2
		elseif inst.prefab == "shadow_knight" then
			return ROGE_SHADOW_KNIGHT_HEALTH_L2
		elseif inst.prefab == "shadow_rook" then
			return ROGE_SHADOW_ROOK_HEALTH_L2
		end
		return nil
	end
	if level < ROGE_SHADOW_CHESS_MAX_LEVEL then
		return nil
	end
	if inst.prefab == "shadow_bishop" then
		return RogeGetDay8HealthMult() > 1
			and ROGE_SHADOW_BISHOP_HEALTH_DAY8
			or ROGE_SHADOW_BISHOP_HEALTH
	elseif inst.prefab == "shadow_knight" then
		return ROGE_SHADOW_KNIGHT_HEALTH
	elseif inst.prefab == "shadow_rook" then
		return RogeGetDay8HealthMult() > 1
			and ROGE_SHADOW_ROOK_HEALTH_DAY8
			or ROGE_SHADOW_ROOK_HEALTH
	end
	return nil
end

function RogeApplyShadowBishopHealth(inst)
	if inst == nil or not inst:IsValid() or not ROGE_SHADOW_CHESS_PREFABS[inst.prefab] then
		return
	end
	local maxhp = RogeGetShadowChessCustomHealth(inst)
	if maxhp == nil then
		return
	end
	local level = inst.level or 1
	RogeSetShadowChessMaxHealth(inst, maxhp, level == 2 or inst.prefab == "shadow_bishop" or inst.prefab == "shadow_rook")
end

ROGE_ROLL_BOSS_MAX_HEALTH = {
	klaus = 2000,
	mutatedbearger = 3000,
	dragonfly = 4000,
	moose = 4000, -- 第8天 +50% 后 = 6000
	sharkboi = ROGE_SHARKBOI_HEALTH,
	stalker = ROGE_STALKER_HEALTH,
}
ROGE_ROLL_BOSS_MAX_HEALTH_DAY8 = {
	sharkboi = ROGE_SHARKBOI_HEALTH_DAY8,
	stalker = ROGE_STALKER_HEALTH_DAY8,
}
ROGE_ROLL_BOSS_HEALTH_PREFABS = {
	klaus = true,
	mutatedbearger = true,
	dragonfly = true,
	moose = true,
	sharkboi = true,
	stalker = true,
}

local function RogeGetRollBossMaxHealth(prefab)
	local maxhp = ROGE_ROLL_BOSS_MAX_HEALTH[prefab]
	if maxhp == nil then
		return nil
	end
	local day8_hp = ROGE_ROLL_BOSS_MAX_HEALTH_DAY8[prefab]
	if day8_hp ~= nil and RogeGetDay8HealthMult() > 1 then
		return day8_hp
	end
	return maxhp
end

function RogeApplyRollBossHealth(inst)
	if inst == nil or not inst:IsValid() or not ROGE_ROLL_BOSS_HEALTH_PREFABS[inst.prefab] then
		return
	end
	local maxhp = RogeGetRollBossMaxHealth(inst.prefab)
	if maxhp == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	if ROGE_ROLL_BOSS_MAX_HEALTH_DAY8[inst.prefab] ~= nil and RogeGetDay8HealthMult() > 1 then
		local pct = inst.components.health:GetPercent()
		inst.components.health:SetMaxHealth(maxhp)
		inst.components.health:SetPercent(pct)
	else
		RogeScaleAdjustedMaxHealth(inst, maxhp)
	end
end

function RogeWrapKlausHealthLock(inst)
	if inst.Enrage ~= nil then
		local old_enrage = inst.Enrage
		inst.Enrage = function(klaus, warning)
			old_enrage(klaus, warning)
			RogeApplyRollBossHealth(klaus)
		end
	end
	if inst.Unchain ~= nil then
		local old_unchain = inst.Unchain
		inst.Unchain = function(klaus, warning)
			old_unchain(klaus, warning)
			RogeApplyRollBossHealth(klaus)
		end
	end
end

function RogeSpawnKlausSackAtDeath(klaus)
	if klaus == nil or not klaus:IsValid() or TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if klaus.IsUnchained ~= nil and not klaus:IsUnchained() then
		return
	end

	local x, y, z = klaus.Transform:GetWorldPosition()
	local sack = SpawnPrefab("klaus_sack")
	if sack ~= nil then
		sack.Transform:SetPosition(x, y, z)
	end
end

function RogeWrapDragonflyHealthLock(inst)
	if inst.TransformFire ~= nil then
		local old_fire = inst.TransformFire
		inst.TransformFire = function(df, ...)
			old_fire(df, ...)
			RogeApplyRollBossHealth(df)
		end
	end
	if inst.TransformNormal ~= nil then
		local old_normal = inst.TransformNormal
		inst.TransformNormal = function(df, ...)
			old_normal(df, ...)
			RogeApplyRollBossHealth(df)
		end
	end
end

local function RogeScheduleSharkboiDespawnAfterDefeat(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "sharkboi" then
		return
	end
	if inst._roge_sharkboi_despawn_task ~= nil then
		return
	end
	local h = inst.components.health
	if h == nil or h.currenthealth > h.minhealth then
		return
	end
	inst._roge_sharkboi_despawn_task = inst:DoTaskInTime(ROGE_SHARKBOI_DEFEAT_DESPAWN_DELAY, function(e)
		e._roge_sharkboi_despawn_task = nil
		if e ~= nil and e:IsValid() then
			e:Remove()
		end
	end)
end

AddPrefabPostInit("sharkboi", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:ListenForEvent("minhealth", RogeScheduleSharkboiDespawnAfterDefeat)
	inst:ListenForEvent("newstate", function(shark)
		if shark.sg ~= nil and shark.sg:HasStateTag("defeated") then
			RogeScheduleSharkboiDespawnAfterDefeat(shark)
		end
	end)
end)

AddPrefabPostInit("sharkboi_icespike", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(GetRandomMinMax(ROGE_SHARKBOI_ICESPIKE_LIFETIME_MIN, ROGE_SHARKBOI_ICESPIKE_LIFETIME_MAX), function(spike)
		if spike ~= nil and spike:IsValid() then
			spike:Remove()
		end
	end)
end)

for prefab in pairs(ROGE_ROLL_BOSS_HEALTH_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:DoTaskInTime(0, RogeApplyRollBossHealth)
		if prefab == "klaus" then
			inst:DoTaskInTime(0, RogeWrapKlausHealthLock)
			inst:ListenForEvent("dropkey", function(klaus)
				RogeSpawnKlausSackAtDeath(klaus)
			end)
		elseif prefab == "dragonfly" then
			inst:DoTaskInTime(0, RogeWrapDragonflyHealthLock)
		end
	end)
end

function RogeShadowChessSetLevel(inst, target_level)
	if inst == nil or not inst:IsValid() or TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if not ROGE_SHADOW_CHESS_PREFABS[inst.prefab] then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	target_level = math.clamp(target_level or 1, 1, ROGE_SHADOW_CHESS_MAX_LEVEL)
	if target_level >= 2 and inst.LevelUp ~= nil then
		if inst.level == nil or inst.level < target_level then
			inst:LevelUp(target_level)
		end
	end
	RogeApplyShadowBishopHealth(inst)
end

for prefab in pairs(ROGE_SHADOW_CHESS_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim or inst.LevelUp == nil then
			return
		end
		local old_levelup = inst.LevelUp
		inst.LevelUp = function(chess, overridelevel)
			old_levelup(chess, overridelevel)
			RogeApplyShadowBishopHealth(chess)
		end
		inst:DoTaskInTime(0, RogeApplyShadowBishopHealth)
	end)
end

-- ====== spawn_creature ======
-- ====== 在玩家附近生�?======
function RogeSpawnThrallsAtFissure(cx, y, cz, base_angle)
	local thrall_radius = 4
	local idx = 0
	for _, entry in ipairs(ROGE_FISSURE_THRALL_SPAWNS) do
		for _ = 1, entry.count do
			local a = base_angle + idx * (2 * PI / 6)
			local mob = SpawnPrefab(entry.prefab)
			if mob ~= nil then
				mob.Transform:SetPosition(
					cx + math.cos(a) * thrall_radius,
					y,
					cz + math.sin(a) * thrall_radius
				)
			end
			idx = idx + 1
		end
	end
end

function RogeSpawnPigguardsAtTorch(cx, y, cz)
	local count = ROGE_PIGTORCH_GUARD_COUNT
	local radius = ROGE_PIGTORCH_GUARD_RADIUS
	local base_angle = math.random() * 2 * PI
	for i = 1, count do
		local a = base_angle + (i - 1) * (2 * PI / count)
		local guard = SpawnPrefab("pigguard")
		if guard ~= nil then
			guard.Transform:SetPosition(
				cx + math.cos(a) * radius,
				y,
				cz + math.sin(a) * radius
			)
		end
	end
end

function RogeSpawnPigtorchPack(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local torch = SpawnPrefab("pigtorch")
	if torch ~= nil then
		torch.Transform:SetPosition(cx, y, cz)
		if torch.components.fueled ~= nil then
			local maxfuel = torch.components.fueled.maxfuel
				or (TUNING.PIGTORCH_FUEL_MAX)
			torch.components.fueled:InitializeFuelLevel(maxfuel)
		end
		if torch.components.burnable ~= nil and not torch.components.burnable:IsBurning() then
			torch.components.burnable:Ignite()
		end
	end
	RogeSpawnPigguardsAtTorch(cx, y, cz)
	return torch
end

function RogeSpawnSpiderqueenMinions(queen, cx, y, cz)
	local idx = 0
	local total = 0
	for _, entry in ipairs(ROGE_SPIDERQUEEN_EXTRA_SPAWNS) do
		total = total + entry.count
	end
	local base_angle = math.random() * 2 * PI
	for _, entry in ipairs(ROGE_SPIDERQUEEN_EXTRA_SPAWNS) do
		for _ = 1, entry.count do
			local a = base_angle + idx * (2 * PI / math.max(total, 1))
			local spider = SpawnPrefab(entry.prefab)
			if spider ~= nil then
				spider.Transform:SetPosition(
					cx + math.cos(a) * ROGE_SPIDERQUEEN_MINION_RADIUS,
					y,
					cz + math.sin(a) * ROGE_SPIDERQUEEN_MINION_RADIUS
				)
				if queen ~= nil and queen:IsValid() and queen.components.leader ~= nil then
					queen.components.leader:AddFollower(spider)
				end
				if queen ~= nil and queen:IsValid()
					and queen.components.combat ~= nil
					and queen.components.combat.target ~= nil
					and spider.components.combat ~= nil then
					spider.components.combat:SetTarget(queen.components.combat.target)
				end
			end
			idx = idx + 1
		end
	end
end

function RogeSpawnSpiderqueenPack(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local queen = SpawnPrefab("spiderqueen")
	if queen == nil then
		return nil
	end
	queen.Transform:SetPosition(cx, y, cz)
	RogeSpawnSpiderqueenMinions(queen, cx, y, cz)
	queen:DoTaskInTime(0, function(q)
		if not q:IsValid() then
			return
		end
		if q.components.combat ~= nil and q.components.combat.target == nil
			and player ~= nil and player:IsValid()
			and player.components.combat ~= nil
			and player.components.combat.target ~= nil then
			q.components.combat:SetTarget(player.components.combat.target)
		elseif q.components.combat ~= nil and q.components.combat.target == nil
			and player ~= nil and player:IsValid() then
			q.components.combat:SetTarget(player)
		end
		local tx = q.components.combat ~= nil and q.components.combat.target or nil
		if tx ~= nil and q.components.leader ~= nil then
			for follower in pairs(q.components.leader.followers) do
				if follower ~= nil and follower:IsValid()
					and follower.components.combat ~= nil then
					follower.components.combat:SetTarget(tx)
				end
			end
		end
	end)
	return queen
end

function RogeSpawnSpiderRobotPack(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local robot = SpawnPrefab("spider_robot")
	if robot == nil then
		return nil
	end
	robot.Transform:SetPosition(cx, y, cz)
	robot._roge_first_revive_pending = true
	robot._roge_skip_death_loot = true
	robot:DoTaskInTime(0, function(r)
		if not r:IsValid() then
			return
		end
		if r.components.health ~= nil and not r.components.health:IsDead() then
			r.components.health:Kill()
		end
	end)
	return robot
end

local function RogeResetAllNightmareSpawnerCounts(force_release)
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	local phase = TheWorld.state.nightmarephase
	local spawning_phase = force_release or phase == "wild" or phase == "dawn"
	for _, ent in ipairs(Ents) do
		if ent:IsValid()
			and (ent.prefab == "nightmarelight"
				or ent.prefab == "fissure_lower"
				or ent.prefab == "fissure") then
			local cs = ent.components.childspawner
			if cs ~= nil and cs.maxchildren > 0 then
				local deficit = cs.maxchildren - cs.NumChildren()
				if deficit > 0 then
					cs:AddChildrenInside(deficit)
				end
				if spawning_phase then
					cs:StartSpawning()
					cs:StopRegen()
					if cs.childreninside > 0 and cs:CanSpawn() then
						cs:ReleaseAllChildren()
					end
				end
			end
		end
	end
end

function RogeTriggerAncientNightmareWildPhase()
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	TheWorld:PushEvent("ms_setnightmarephase", "wild")
	-- 已在 wild 时 PushEvent 不会再次触发灯座/裂隙 phase 回调，需手动补满并立刻刷怪
	RogeResetAllNightmareSpawnerCounts(true)
end

function RogeSpawnNightmarelightAt(cx, y, cz, radius)
	local angle = math.random() * 2 * PI
	local dist = radius or 0
	local light = SpawnPrefab("nightmarelight")
	if light ~= nil then
		light.Transform:SetPosition(
			cx + math.cos(angle) * dist,
			y,
			cz + math.sin(angle) * dist
		)
	end
	return light
end

function RogeScheduleNightmarelightRemoval(lights)
	if lights == nil or #lights == 0 or TheWorld == nil then
		return
	end
	TheWorld:DoTaskInTime(ROGE_NIGHTMARELIGHT_LIFETIME, function()
		for _, inst in ipairs(lights) do
			if inst ~= nil and inst:IsValid() then
				inst:Remove()
			end
		end
	end)
end

function RogeSpawnNightmarelightPack(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local lights = {}
	local center = RogeSpawnNightmarelightAt(cx, y, cz, 0)
	if center ~= nil then
		table.insert(lights, center)
	end
	local extra_count = math.random(ROGE_NIGHTMARELIGHT_EXTRA_MIN, ROGE_NIGHTMARELIGHT_EXTRA_MAX)
	for _ = 1, extra_count do
		local r = ROGE_NIGHTMARELIGHT_EXTRA_RADIUS_MIN
			+ math.random()
				* (ROGE_NIGHTMARELIGHT_EXTRA_RADIUS_MAX - ROGE_NIGHTMARELIGHT_EXTRA_RADIUS_MIN)
		local light = RogeSpawnNightmarelightAt(cx, y, cz, r)
		if light ~= nil then
			table.insert(lights, light)
		end
	end
	RogeTriggerAncientNightmareWildPhase()
	RogeScheduleNightmarelightRemoval(lights)
	return center
end

local function RogeSpawnOutpostMob(prefab, x, y, z, target)
	local mob = SpawnPrefab(prefab)
	if mob == nil then
		return nil
	end
	mob.Transform:SetPosition(x, y, z)
	if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
		mob.components.combat:SetTarget(target)
	end
	if RogeSetupVoidProtection ~= nil then
		RogeSetupVoidProtection(mob)
	end
	return mob
end

local function RogePlaceEyeturretOutpostDockTurfs(cx, cz)
	local map = TheWorld.Map
	if map == nil then
		return {}
	end
	local tile = ROGE_EYETURRET_OUTPOST_DOCK_TILE
	if tile == nil then
		return {}
	end
	local anchor_tx, anchor_ty = map:GetTileCoordsAtPoint(cx, 0, cz)
	local centers = {}
	for dx = 0, 1 do
		for dy = 0, 1 do
			local tx, ty = anchor_tx + dx, anchor_ty + dy
			map:SetTile(tx, ty, tile)
			local wx, wy, wz = map:GetTileCenterPoint(tx, ty)
			table.insert(centers, { x = wx, y = wy, z = wz })
		end
	end
	return centers
end

function RogeSpawnEyeturretOutpostPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end

	local tile_centers = RogePlaceEyeturretOutpostDockTurfs(cx, cz)
	local pcx, pcy, pcz = cx, y, cz
	if #tile_centers >= 4 then
		pcx = (tile_centers[1].x + tile_centers[4].x) * 0.5
		pcy = (tile_centers[1].y + tile_centers[4].y) * 0.5
		pcz = (tile_centers[1].z + tile_centers[4].z) * 0.5
	elseif #tile_centers >= 1 then
		pcx, pcy, pcz = tile_centers[1].x, tile_centers[1].y, tile_centers[1].z
	end

	local turret1 = nil
	local turret2 = nil
	if #tile_centers >= 1 then
		turret1 = RogeSpawnOutpostMob(
			"shadoweyeturret", tile_centers[1].x, tile_centers[1].y, tile_centers[1].z, target)
	end
	if #tile_centers >= 4 then
		turret2 = RogeSpawnOutpostMob(
			"shadoweyeturret2", tile_centers[4].x, tile_centers[4].y, tile_centers[4].z, target)
	end

	RogeSpawnOutpostMob("nightmarelight", pcx, pcy, pcz, nil)
	RogeTriggerAncientNightmareWildPhase()

	local mob_radius = ROGE_EYETURRET_OUTPOST_CLOCKWORK_RADIUS
	local total = 8
	for i = 0, 3 do
		local a = i * (2 * PI / total)
		RogeSpawnOutpostMob(
			"bishop",
			pcx + math.cos(a) * mob_radius,
			pcy,
			pcz + math.sin(a) * mob_radius,
			target
		)
	end
	for i = 4, 7 do
		local a = i * (2 * PI / total)
		RogeSpawnOutpostMob(
			"knight",
			pcx + math.cos(a) * mob_radius,
			pcy,
			pcz + math.sin(a) * mob_radius,
			target
		)
	end

	return turret1 or turret2
end

function RogeSpawnClockworkSquadPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local idx = 0
	local total = 0
	for _, entry in ipairs(ROGE_CLOCKWORK_SQUAD_SPAWNS) do
		total = total + entry.count
	end
	local base_angle = math.random() * 2 * PI
	local first = nil
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	for _, entry in ipairs(ROGE_CLOCKWORK_SQUAD_SPAWNS) do
		for _ = 1, entry.count do
			local a = base_angle + idx * (2 * PI / math.max(total, 1))
			local mob = SpawnPrefab(entry.prefab)
			if mob ~= nil then
				mob.Transform:SetPosition(
					cx + math.cos(a) * ROGE_CLOCKWORK_SQUAD_RADIUS,
					y,
					cz + math.sin(a) * ROGE_CLOCKWORK_SQUAD_RADIUS
				)
				if first == nil then
					first = mob
				end
				if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
					mob.components.combat:SetTarget(target)
				end
			end
			idx = idx + 1
		end
	end
	return first
end

function RogeSpawnKnightYothPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	local first = SpawnPrefab("knight_yoth")
	if first == nil then
		return nil
	end
	first.Transform:SetPosition(cx, y, cz)
	if target ~= nil and target:IsValid() and first.components.combat ~= nil then
		first.components.combat:SetTarget(target)
	end
	local base_angle = math.random() * 2 * PI
	for i = 1, ROGE_KNIGHT_YOTH_EXTRA_COUNT do
		local a = base_angle + i * (2 * PI / ROGE_KNIGHT_YOTH_EXTRA_COUNT)
		local mob = SpawnPrefab("knight_yoth")
		if mob ~= nil then
			mob.Transform:SetPosition(
				cx + math.cos(a) * ROGE_KNIGHT_YOTH_EXTRA_RADIUS,
				y,
				cz + math.sin(a) * ROGE_KNIGHT_YOTH_EXTRA_RADIUS
			)
			if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
				mob.components.combat:SetTarget(target)
			end
		end
	end
	return first
end

local function RogeApplyLunarfrogRainHealth(frog)
	if frog ~= nil and frog.components.health ~= nil and not frog.components.health:IsDead() then
		RogeScaleAdjustedMaxHealth(frog, ROGE_LUNARFROG_HEALTH)
	end
end

local function RogeSpawnLunarfrogRainFrog(cx, cy, cz, target)
	local theta = math.random() * TWOPI
	local dist = math.random() * ROGE_LUNARFROG_RAIN_RADIUS
	local px = cx + math.cos(theta) * dist
	local pz = cz + math.sin(theta) * dist
	if TheWorld.Map ~= nil and not TheWorld.Map:IsAboveGroundAtPoint(px, cy, pz) then
		return nil
	end
	local frog = SpawnPrefab("lunarfrog")
	if frog == nil then
		return nil
	end
	frog.persists = false
	if frog.sg ~= nil then
		frog.sg:GoToState("fall")
	end
	if frog.Physics ~= nil then
		frog.Physics:Teleport(px, ROGE_LUNARFROG_RAIN_SPAWN_HEIGHT, pz)
	else
		frog.Transform:SetPosition(px, ROGE_LUNARFROG_RAIN_SPAWN_HEIGHT, pz)
	end
	RogeApplyLunarfrogRainHealth(frog)
	if target ~= nil and target:IsValid() and frog.components.combat ~= nil then
		frog.components.combat:SetTarget(target)
	end
	return frog
end

function RogeSpawnLunarfrogRainPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * TWOPI
	local spawn_offset = 5
	local cx = x + math.cos(angle) * spawn_offset
	local cz = z + math.sin(angle) * spawn_offset
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end

	local total = math.random(ROGE_LUNARFROG_RAIN_COUNT_MIN, ROGE_LUNARFROG_RAIN_COUNT_MAX)
	local first = RogeSpawnLunarfrogRainFrog(cx, y, cz, target)
	if total > 1 then
		local step = ROGE_LUNARFROG_RAIN_DURATION / (total - 1)
		for i = 2, total do
			TheWorld:DoTaskInTime(step * (i - 1), function()
				if TheWorld ~= nil and TheWorld.ismastersim then
					RogeSpawnLunarfrogRainFrog(cx, y, cz, target)
				end
			end)
		end
	end
	return first or player
end

function RogeStripNpcInventory(inv)
	if inv == nil then
		return
	end
	for _, item in pairs(inv.equipslots) do
		if item ~= nil and item:IsValid() then
			item:Remove()
		end
	end
	for _, item in pairs(inv.itemslots) do
		if item ~= nil and item:IsValid() then
			item:Remove()
		end
	end
end

function RogeClearEquippableRestriction(item)
	if item ~= nil and item.components.equippable ~= nil then
		item.components.equippable.restrictedtag = nil
	end
end

local function RogePreventPrimeMateWeaponDrop(weapon)
	if weapon == nil or not weapon:IsValid() or weapon.components.inventoryitem == nil then
		return
	end
	weapon.components.inventoryitem:SetOnDroppedFn(function(inst)
		if inst:IsValid() then
			inst:Remove()
		end
	end)
end

local function RogeSpawnPrimeMateWeapon()
	local prefab = ROGE_PRIME_MATE_WEAPONS[math.random(#ROGE_PRIME_MATE_WEAPONS)]
	local damage = ROGE_PRIME_MATE_WEAPON_DAMAGE[prefab] or 0
	local weapon = SpawnPrefab(prefab)
	if weapon == nil then
		return nil, 0
	end
	RogeClearEquippableRestriction(weapon)
	if weapon.components.weapon ~= nil then
		weapon.components.weapon:SetDamage(damage)
	end
	if weapon.components.finiteuses ~= nil then
		weapon.components.finiteuses:SetUses(weapon.components.finiteuses.total)
	end
	RogePreventPrimeMateWeaponDrop(weapon)
	if prefab == "firestaff" then
		RogeSetupPrimeMateFirestaff(weapon)
	end
	return weapon, damage
end

local function RogeHookPrimeMateWeaponNoDrop(inst)
	if inst._roge_prime_mate_weapon_nodrop_hooked then
		return
	end
	inst._roge_prime_mate_weapon_nodrop_hooked = true
	inst:ListenForEvent("death", function()
		local inv = inst.components.inventory
		if inv == nil then
			return
		end
		local weapon = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
		if weapon ~= nil and weapon:IsValid() then
			weapon:Remove()
		end
	end)
end

function RogeApplyPrimeMateElite(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "prime_mate" then
		return
	end
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	RogeStripNpcInventory(inv)
	local weapon, weapon_damage = RogeSpawnPrimeMateWeapon()
	local hat = SpawnPrefab("ruinshat")
	if weapon ~= nil then
		inv:GiveItem(weapon)
		inv:Equip(weapon)
	end
	if hat ~= nil then
		inv:GiveItem(hat)
		inv:Equip(hat)
		if inst.AnimState ~= nil then
			inst.AnimState:Show("hat")
		end
	end
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		RogeScaleAdjustedMaxHealth(inst, ROGE_PRIME_MATE_HEALTH)
	end
	if inst.components.combat ~= nil then
		inst.components.combat:SetDefaultDamage(weapon_damage)
	end
	RogeHookPrimeMateWeaponNoDrop(inst)
end

function RogeSpawnPrimeMatePack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local mate = SpawnPrefab("prime_mate")
	if mate == nil then
		return nil
	end
	mate.Transform:SetPosition(x + math.cos(angle) * radius, y, z + math.sin(angle) * radius)
	mate:DoTaskInTime(0, function(inst)
		if inst ~= nil and inst:IsValid() then
			RogeApplyPrimeMateElite(inst)
		end
	end)
	return mate
end

function RogeSetFixedMaxHealth(inst, maxhp)
	if inst == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	local hp = math.max(1, math.floor(maxhp))
	local pct = inst.components.health:GetPercent()
	inst.components.health:SetMaxHealth(hp)
	inst.components.health:SetPercent(pct)
end

function RogeSpawnFissureLowerPack(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local fissure = SpawnPrefab("fissure_lower")
	if fissure ~= nil then
		fissure.Transform:SetPosition(cx, y, cz)
	end
	RogeSpawnThrallsAtFissure(cx, y, cz, angle)
	return fissure
end

-- 骰子/调试召出的恐怖之眼、双子：出场即进二阶段（须在 SpawnNearPlayer 之前定义，供下方调用）
ROGE_EYEBOSS_HEALTH = 3500
ROGE_EYEBOSS_PHASE2_PREFABS = {
	eyeofterror = true,
	twinofterror1 = true,
	twinofterror2 = true,
}

function RogeApplyEyeBossHealth(inst)
	if inst == nil or not inst:IsValid() or not ROGE_EYEBOSS_PHASE2_PREFABS[inst.prefab] then
		return
	end
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		RogeScaleAdjustedMaxHealth(inst, ROGE_EYEBOSS_HEALTH)
	end
end

function RogeSnapEyeBossPhase2(inst)
	if inst.sg == nil then
		return
	end
	if inst.AnimState ~= nil then
		inst.AnimState:Show("mouth")
		inst.AnimState:Show("ball_mouth")
		inst.AnimState:Hide("eye")
		inst.AnimState:Hide("ball_eye")
	end
	inst.sg.mem.transformed = true
	inst.sg.mem.wantstotransform = false
	inst:AddTag("flying")
	inst:PushEvent("on_no_longer_landed")
	RogeApplyEyeBossHealth(inst)
end

function RogeTryForceEyeBossPhase2(inst)
	if inst == nil or not inst:IsValid() or not ROGE_EYEBOSS_PHASE2_PREFABS[inst.prefab] then
		return false
	end
	if inst.sg == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return false
	end
	if inst.sg.mem.transformed then
		return true
	end
	if inst.sg:HasStateTag("transform") then
		return false
	end
	inst.sg.mem.wantstotransform = true
	if not inst.sg:HasStateTag("busy") then
		if inst.sg:HasState("transform") then
			inst.sg:GoToState("transform")
		else
			inst:PushEvent("health_transform")
		end
	end
	return inst.sg.mem.transformed == true or inst.sg:HasStateTag("transform")
end

function RogeScheduleEyeBossPhase2(inst)
	if inst == nil or not ROGE_EYEBOSS_PHASE2_PREFABS[inst.prefab] then
		return
	end
	local delays = { 0, 2 * FRAMES, 8 * FRAMES, 15 * FRAMES, 0.5, 1, 2 }
	for i, d in ipairs(delays) do
		inst:DoTaskInTime(d, function(e)
			if e == nil or not e:IsValid() then
				return
			end
			if RogeTryForceEyeBossPhase2(e) then
				RogeApplyEyeBossHealth(e)
				return
			end
			if i == #delays and e.sg ~= nil and not e.sg.mem.transformed then
				RogeSnapEyeBossPhase2(e)
			else
				RogeApplyEyeBossHealth(e)
			end
		end)
	end
end

for prefab in pairs(ROGE_EYEBOSS_PHASE2_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:DoTaskInTime(0, RogeApplyEyeBossHealth)
	end)
end

function SpawnNearPlayer(player, prefab_name, spawn_tier)
	spawn_tier = spawn_tier or ROGE_SPAWN_POOL_LARGE
	if prefab_name == "fissure_lower" then
		return RogeSpawnFissureLowerPack(player)
	end
	if prefab_name == "pigtorch" then
		return RogeSpawnPigtorchPack(player)
	end
	if prefab_name == "spiderqueen" then
		local ent = RogeSpawnSpiderqueenPack(player)
		if ent ~= nil then
			RogeMarkDiceSummonDeep(ent)
		end
		return ent
	end
	if prefab_name == "spider_robot" then
		local ent = RogeSpawnSpiderRobotPack(player)
		if ent ~= nil then
			RogeMarkDiceSummonDeep(ent)
		end
		return ent
	end
	if prefab_name == "nightmarelight" then
		return RogeSpawnNightmarelightPack(player)
	end
	if prefab_name == ROGE_CLOCKWORK_SQUAD_KEY then
		return RogeSpawnClockworkSquadPack(player)
	end
	if prefab_name == "knight_yoth" then
		return RogeSpawnKnightYothPack(player)
	end
	if prefab_name == ROGE_LUNARFROG_RAIN_KEY or prefab_name == "lunarfrog" then
		return RogeSpawnLunarfrogRainPack(player)
	end
	if prefab_name == "prime_mate" then
		return RogeSpawnPrimeMatePack(player)
	end
	if prefab_name == ROGE_WALRUS_SQUAD_KEY then
		return RogeSpawnWalrusSquadPack(player)
	end
	if prefab_name == ROGE_MERMGUARD_PACK_KEY then
		return RogeSpawnMermguardPack(player)
	end
	if prefab_name == ROGE_MERMCORPS_KEY then
		return RogeSpawnMermcorpsPack(player)
	end
	if prefab_name == ROGE_PIGELITE_SQUAD_KEY then
		return RogeSpawnPigeliteSquadPack(player)
	end
	if prefab_name == ROGE_CRABKNIGHT_SQUAD_KEY then
		return RogeSpawnCrabKnightSquadPack(player)
	end
	if prefab_name == ROGE_EYETURRET_OUTPOST_KEY then
		return RogeSpawnEyeturretOutpostPack(player)
	end
	if prefab_name == "daywalker2" then
		return RogeSpawnDaywalker2RogePack(player)
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local creature = SpawnPrefab(prefab_name)
	if creature then
		creature.Transform:SetPosition(x + math.cos(angle) * radius, y, z + math.sin(angle) * radius)
		if creature.prefab == "crabking_mob_knight" then
			creature._roge_crab_knight_role = "weak"
		end
		if creature.prefab == "shadowdragon" then
			creature._roge_summoned = true
		end
		RogeScheduleEyeBossPhase2(creature)
		creature:DoTaskInTime(0, function(e)
			if ROGE_SHADOW_CHESS_PREFABS[e.prefab] then
				local level = ROGE_SHADOW_CHESS_LEVEL_BY_POOL[spawn_tier]
					or ROGE_SHADOW_CHESS_MAX_LEVEL
				RogeShadowChessSetLevel(e, level)
			end
			RogeApplyRollBossHealth(e)
			RogeApplyEyeBossHealth(e)
			RogeSetupCrabKnightRogeExtras(e)
			if RogeSetupVoidProtection ~= nil then
				RogeSetupVoidProtection(e)
			end
		end)
		RogeMarkDiceSummonDeep(creature)
	end
	return creature
end

-- 控制台测试（需开启「允许作弊」）：c_rogespawn("klaus") / c_rogespawn("mutatedbearger")
GLOBAL.c_rogespawn = function(prefab)
	if TheWorld == nil or not TheWorld.ismastersim then
		print("[roge] 仅主机可用")
		return
	end
	local player = ConsoleWorldEntity
	if player == nil or not player:IsValid() then
		player = ThePlayer
	end
	if player == nil or not player:IsValid() then
		print("[roge] 找不到玩家")
		return
	end
	prefab = prefab or "klaus"
	if not ROGE_ROLL_BOSS_HEALTH_PREFABS[prefab] and not ROGE_SHADOW_CHESS_PREFABS[prefab] then
		print("[roge] 未知 prefab: " .. tostring(prefab))
	end
	local ent = SpawnNearPlayer(player, prefab)
	if ent ~= nil then
		print(string.format("[roge] 已召唤 %s (GUID %s)", prefab, tostring(ent.GUID)))
	elseif prefab == ROGE_LUNARFROG_RAIN_KEY or prefab == "lunarfrog" then
		print("[roge] 明眼青蛙雨召唤失败：SpawnPrefab(lunarfrog) 返回 nil，请确认已启用含该生物的模组")
	elseif prefab == ROGE_EYETURRET_OUTPOST_KEY then
		print("[roge] 眼球哨卫召唤失败：请确认码头地皮与哨兵 prefab 可用")
	end
	return ent
end


function IsShiftYSummonUnlocked()
	return RogeGetClockDay() >= ROGE_SHIFT_Y_SUMMON_MIN_DAY
end

function TrySpawnShiftYSummon(player)
	if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
		return 0, 0
	end
	if not IsShiftYSummonUnlocked() then
		return 2, 0
	end
	local t = GetTime()
	if player._roge_shift_y_summon_cd ~= nil and t < player._roge_shift_y_summon_cd then
		return 0, math.max(0, math.ceil(player._roge_shift_y_summon_cd - t - 1e-4))
	end
	local prefab = ROGE_SHIFT_Y_SUMMON_POOL[math.random(#ROGE_SHIFT_Y_SUMMON_POOL)]
	player._roge_shift_y_summon_cd = t + ROGE_SHIFT_Y_SUMMON_COOLDOWN
	SpawnNearPlayer(player, prefab, ROGE_SPAWN_POOL_SMALL)
	return 1, 0
end

function TrySpawnShiftUSummon(player)
	if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
		return 0, 0
	end
	if not IsShiftUSummonUnlocked() then
		return 2, 0
	end
	local t = GetTime()
	if player._roge_shift_u_summon_cd ~= nil and t < player._roge_shift_u_summon_cd then
		return 0, math.max(0, math.ceil(player._roge_shift_u_summon_cd - t - 1e-4))
	end
	local pool = LARGE_BOSSES
	if pool == nil or #pool <= 0 then
		return 0, 0
	end
	local prefab = pool[math.random(#pool)]
	local cd = RogeShiftUSummonCooldownSeconds(player)
	player._roge_shift_u_summon_cd = t + cd
	player._roge_shift_u_used_once = true
	SpawnNearPlayer(player, prefab, ROGE_SPAWN_POOL_LARGE)
	return 1, 0
end

function TrySpawnDiceCreature(player, roll_result, max_sides)
    if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
        return
    end
    local t = GetTime()
    if player._dicespawncd and t < player._dicespawncd then
        return
    end
    player._dicespawncd = t + DICE_SPAWN_COOLDOWN

    roll_result, max_sides = ApplyDiceRollWorldRules(roll_result, max_sides)
    if roll_result <= 0 then
        return
    end
    local prefab_name, spawn_tier = RogePickSpawn(roll_result, max_sides)
    if prefab_name then
        SpawnNearPlayer(player, prefab_name, spawn_tier)
    end
end
