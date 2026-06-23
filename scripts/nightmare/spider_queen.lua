----------------------------------------------------------------------
-- 蜘蛛女王：AOE 近战 + 生产蜘蛛动作（poop_pre / poop_loop）地面冲刺接近攻击
----------------------------------------------------------------------

local SPIDER_QUEEN_SCALE = 1.25
local SPIDER_QUEEN_TILE_SIZE = 4
local SPIDER_QUEEN_PHYSICS_RADIUS_EXTRA = 1 -- 碰撞胶囊半径额外 +1 世界单位

TUNING.SPIDER_QUEEN_SCALE             = SPIDER_QUEEN_SCALE
TUNING.SPIDER_QUEEN_MAX_HEALTH        = 5000
TUNING.SPIDER_QUEEN_SPAWN_HEALTH      = 2000
TUNING.SPIDER_QUEEN_RETARGET_PERIOD   = 3 -- 重新锁定最远目标的间隔（秒）
TUNING.SPIDER_QUEEN_RETARGET_RANGE    = 30
TUNING.SPIDER_QUEEN_ATTACK_RANGE_OFFSET       = -1 -- 相对缩放基础再减的世界单位
TUNING.SPIDER_QUEEN_ATTACK_RANGE_TRIGGER_EXTRA = 0.5 -- 触发攻击距离 = 缩放基础 + 0.5
TUNING.SPIDER_QUEEN_HIT_RANGE_EXTRA   = 1.5 -- 实际命中距离 = 触发距离 + 1
TUNING.SPIDER_QUEEN_DAMAGE            = 120
TUNING.SPIDER_QUEEN_PLANAR_DAMAGE     = 5
TUNING.SPIDER_QUEEN_AOE_MULT          = 1
TUNING.SPIDER_QUEEN_ATTACK_ANGLE      = 120
TUNING.SPIDER_QUEEN_CHARGE_STOP_RANGE_FRAC = 0.5
TUNING.SPIDER_QUEEN_SPAWN_SPECIAL_COUNT = 3
TUNING.SPIDER_QUEEN_TAUNT_EVERY_N_ATTACKS   = 2
TUNING.SPIDER_QUEEN_SPAWN_EVERY_N_ATTACKS = 5
TUNING.SPIDER_QUEEN_CHARGE_MAX_TILES   = 4
TUNING.SPIDER_QUEEN_CHARGE_MIN_DIST    = 5 * SPIDER_QUEEN_SCALE
TUNING.SPIDER_QUEEN_CHARGE_MAX_DIST    = TUNING.SPIDER_QUEEN_CHARGE_MAX_TILES * SPIDER_QUEEN_TILE_SIZE
TUNING.SPIDER_QUEEN_CHARGE_MAX_TRAVEL  = TUNING.SPIDER_QUEEN_CHARGE_MAX_TILES * SPIDER_QUEEN_TILE_SIZE
TUNING.SPIDER_QUEEN_CHARGE_MIN_TIME    = 0.15
TUNING.SPIDER_QUEEN_CHARGE_MAX_TIME    = 1.0
TUNING.SPIDER_QUEEN_CHARGE_SPEED       = 30
TUNING.SPIDER_QUEEN_CHARGE_PRE_FRAMES  = 10
TUNING.SPIDER_QUEEN_CHARGE_LOOP_VISUAL = 0.38
TUNING.SPIDER_QUEEN_WEB_RADIUS         = 6
TUNING.SPIDER_QUEEN_WEB_SPACING        = 4
TUNING.SPIDER_QUEEN_WEB_LINGER         = 30
TUNING.SPIDER_QUEEN_HITSTUN_COOLDOWN = 2.5 -- 触发僵直后 N 秒内不再进入 hit
TUNING.SPIDER_QUEEN_TARGET_LOCK_AFTER_ATTACK = 2.5 -- 攻击目标后 N 秒内不因受击改目标
TUNING.SPIDER_QUEEN_CHARGE_TARGET_EXCLUDE_RADIUS = 2 -- 不击飞距锁定目标此范围内的其他玩家
TUNING.SPIDER_QUEEN_CHARGE_HIT_DAMAGE           = 160
TUNING.SPIDER_QUEEN_CHARGE_KNOCKBACK_DIST       = 8  -- 击退距离（×体型）
TUNING.SPIDER_QUEEN_CHARGE_COLLIDE_MIN_SPEED_SQ = 36 -- 碰撞击飞所需最低速度平方

local SPIDER_QUEEN_SPECIAL_SPIDER_POOL = {
	"spider_warrior",
	"spider_healer",
	"spider_spitter",
	"spider_hider",
	"spider_dropper",
}

local SPIDER_QUEEN_CHARGE_BRAIN = "spider_queen_charge_attack"
local SPIDER_QUEEN_WEB_CREEP_PREFAB = "spider_web_spit_creep"

local AREAATTACK_MUST_TAGS = { "_combat" }
local AREAATTACK_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" }
local SPIDER_QUEEN_RETARGET_MUST_TAGS = { "character", "_combat" }
local SPIDER_QUEEN_RETARGET_CANT_TAGS = { "spiderwhisperer", "spiderdisguise", "INLIMBO" }
local function SpiderQueenWebCreepStartDespawn(creep)
	if creep._spider_queen_despawn_task ~= nil then
		return
	end
	local linger = creep._spider_queen_linger_remaining
	if linger == nil or linger <= 0 then
		linger = TUNING.SPIDER_QUEEN_WEB_LINGER or 30
	end
	creep._spider_queen_linger_remaining = nil
	creep._spider_queen_allow_remove = true
	creep._spider_queen_despawn_taskinfo = creep:GetTaskInfo(linger)
	creep._spider_queen_despawn_task = creep:DoTaskInTime(linger, function(c)
		c._spider_queen_despawn_task = nil
		c._spider_queen_despawn_taskinfo = nil
		if c._SpiderQueenWebCreepRemove ~= nil then
			c:_SpiderQueenWebCreepRemove()
		else
			c:Remove()
		end
	end)
end

local function SpiderQueenWebCreepCancelDespawn(creep)
	if creep._spider_queen_despawn_task ~= nil then
		if creep._spider_queen_despawn_taskinfo ~= nil then
			creep._spider_queen_linger_remaining = creep:TimeRemainingInTask(creep._spider_queen_despawn_taskinfo)
		end
		creep._spider_queen_despawn_task:Cancel()
		creep._spider_queen_despawn_task = nil
		creep._spider_queen_despawn_taskinfo = nil
	end
	creep._spider_queen_allow_remove = false
end

local function SpiderQueenWebCreepUpdateQueenProximity(creep)
	local queen = creep._spider_queen_owner
	if queen == nil or not queen:IsValid()
		or (queen.components.health ~= nil and queen.components.health:IsDead()) then
		SpiderQueenWebCreepStartDespawn(creep)
		return
	end
	local near_dist = creep._queen_near_dist or 4
	if queen:GetDistanceSqToInst(creep) <= near_dist * near_dist then
		SpiderQueenWebCreepCancelDespawn(creep)
	else
		SpiderQueenWebCreepStartDespawn(creep)
	end
end

local function SpiderQueenWebCreepEnableTrail(creep, queen)
	if creep == nil or queen == nil then
		return
	end
	creep._spider_queen_trail = true
	creep._spider_queen_owner = queen
	creep._queen_near_dist = (TUNING.SPIDER_QUEEN_WEB_RADIUS or 6)
		+ queen:GetPhysicsRadius(0) + 0.5
	-- 原版 prefab 会在生成时挂 5 秒 Remove，必须清掉才能走自定义生命周期
	creep:CancelAllPendingTasks()
	creep._spider_queen_trail_task = nil
	creep._spider_queen_despawn_task = nil
	creep._spider_queen_despawn_taskinfo = nil
	SpiderQueenWebCreepCancelDespawn(creep)
	creep._spider_queen_trail_task = creep:DoPeriodicTask(0.25, SpiderQueenWebCreepUpdateQueenProximity)
	SpiderQueenWebCreepUpdateQueenProximity(creep)
end

local function SpiderQueenIsWalking(inst)
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.sg ~= nil and inst.sg:HasStateTag("busy") and inst.sg:HasStateTag("nointerrupt") then
		return false
	end
	local loc = inst.components.locomotor
	if loc == nil then
		return false
	end
	if loc.dest ~= nil or loc.wantstomoveforward then
		return true
	end
	if inst.Physics ~= nil then
		local vx, _, vz = inst.Physics:GetVelocity()
		if vx ~= nil and (vx * vx + vz * vz) > 0.04 then
			return true
		end
	end
	return false
end

local function SpiderQueenSpawnWalkWeb(inst)
	local creep = SpawnPrefab(SPIDER_QUEEN_WEB_CREEP_PREFAB)
	if creep == nil then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	creep.Transform:SetPosition(x, y, z)
	SpiderQueenWebCreepEnableTrail(creep, inst)
	local splash = SpawnPrefab("splash_spiderweb")
	if splash ~= nil then
		splash.Transform:SetPosition(x, y, z)
	end
end

local function SpiderQueenTryDropTrailWeb(inst)
	local x, _, z = inst.Transform:GetWorldPosition()
	local spacing = TUNING.SPIDER_QUEEN_WEB_SPACING or 4
	local lx, lz = inst._spider_queen_last_web_x, inst._spider_queen_last_web_z
	if lx ~= nil and lz ~= nil then
		local dx, dz = x - lx, z - lz
		if dx * dx + dz * dz < spacing * spacing then
			return
		end
	end
	SpiderQueenSpawnWalkWeb(inst)
	inst._spider_queen_last_web_x = x
	inst._spider_queen_last_web_z = z
end

local function SpiderQueenTryDropWalkWeb(inst)
	if not SpiderQueenIsWalking(inst) then
		return
	end
	SpiderQueenTryDropTrailWeb(inst)
end

local function SpiderQueenTryDropChargeWeb(inst)
	if inst.sg == nil or inst.sg.currentstate == nil
		or inst.sg.currentstate.name ~= "spider_queen_charge_attack"
		or not inst.sg.statemem.charge_started then
		return
	end
	SpiderQueenTryDropTrailWeb(inst)
end

local function SpiderQueenStartWalkWebTrail(inst)
	if inst._spider_queen_web_task ~= nil then
		return
	end
	inst._spider_queen_web_task = inst:DoPeriodicTask(0.25, SpiderQueenTryDropWalkWeb)
end

local function SpiderQueenIsNightmareBoss(inst)
	return inst._spider_queen_nightmare_patched == true
end

-- Possession 2（Poss2.Level / Possessors）或实体带 playercontroller：视为玩家操控，禁用 AI 最远索敌
local function SpiderQueenIsPlayerControlled(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	local p2 = inst.Poss2
	if p2 ~= nil then
		if (p2.Level or 0) > 0 then
			return true
		end
		if p2.Possessors ~= nil then
			for _ in pairs(p2.Possessors) do
				return true
			end
		end
	end
	if inst.components.playercontroller ~= nil then
		return true
	end
	return false
end

local function SpiderQueenClearTargetLock(inst)
	inst._spider_queen_target_lock_until = nil
	inst._spider_queen_locked_target = nil
end

local function SpiderQueenResolveTarget(inst, target)
	if target ~= nil and target:IsValid() then
		return target
	end
	if inst.components.combat ~= nil then
		local t = inst.components.combat.target
		if t ~= nil and t:IsValid() then
			return t
		end
	end
	return nil
end

local function SpiderQueenGetTargetLockDuration()
	return TUNING.SPIDER_QUEEN_TARGET_LOCK_AFTER_ATTACK or 2
end

local function SpiderQueenIsTargetLockActive(inst)
	return inst._spider_queen_target_lock_until ~= nil
		and GetTime() < inst._spider_queen_target_lock_until
end

local function SpiderQueenLockTargetAfterAttack(inst, target)
	if not SpiderQueenIsNightmareBoss(inst) or SpiderQueenIsPlayerControlled(inst) then
		return
	end
	target = SpiderQueenResolveTarget(inst, target)
	inst._spider_queen_target_lock_until = GetTime() + SpiderQueenGetTargetLockDuration()
	if target ~= nil and target:IsValid() then
		inst._spider_queen_locked_target = target
	end
end

local function SpiderQueenCombatSetTarget(inst, target)
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	inst._spider_queen_allow_set_target = true
	combat:SetTarget(target)
	inst._spider_queen_allow_set_target = false
end

local function SpiderQueenClearFirePanic(health)
	if health.takingfiredamage then
		health.takingfiredamage = false
	end
	if health.takingfiredamagelow then
		health.takingfiredamagelow = nil
	end
	health.inst:StopUpdatingComponent(health)
	health.inst:PushEvent("stopfiredamage")
end

local function SpiderQueenDistToTarget(inst, target)
	if target == nil or not target:IsValid() then
		return math.huge
	end
	local sx, _, sz = inst.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - sx, tz - sz
	return math.sqrt(dx * dx + dz * dz)
end

local function SpiderQueenGetScaledAttackRange()
	return (TUNING.SPIDERQUEEN_ATTACKRANGE or 5) * (TUNING.SPIDER_QUEEN_SCALE or SPIDER_QUEEN_SCALE)
		+ (TUNING.SPIDER_QUEEN_ATTACK_RANGE_OFFSET or -1)
end

local function SpiderQueenGetTriggerAttackRange(inst)
	if inst.components.combat ~= nil and inst.components.combat.attackrange ~= nil then
		return inst.components.combat.attackrange
	end
	return SpiderQueenGetScaledAttackRange()
		+ (TUNING.SPIDER_QUEEN_ATTACK_RANGE_TRIGGER_EXTRA or 0.5)
end

local function SpiderQueenGetHitAttackRange(inst)
	if inst.components.combat ~= nil and inst.components.combat.hitrange ~= nil then
		return inst.components.combat.hitrange
	end
	return SpiderQueenGetTriggerAttackRange(inst)
		+ (TUNING.SPIDER_QUEEN_HIT_RANGE_EXTRA or 1)
end

local function SpiderQueenGetAttackRange(inst)
	return SpiderQueenGetHitAttackRange(inst)
end

local function SpiderQueenCanRetargetEntity(inst, guy)
	if guy == nil or not guy:IsValid() or guy == inst then
		return false
	end
	if not guy.entity:IsVisible() then
		return false
	end
	return (not guy:HasTag("monster") or guy:HasTag("player"))
		and inst.components.combat:CanTarget(guy)
end

local SPIDER_QUEEN_SHARE_TARGET_DIST = 30

local function SpiderQueenShareTargetFn(dude)
	return dude.prefab == "spiderqueen"
		and dude.components.health ~= nil
		and not dude.components.health:IsDead()
end

local function SpiderQueenCanRetargetNow(inst)
	local period = TUNING.SPIDER_QUEEN_RETARGET_PERIOD or 4
	local last = inst._spider_queen_last_retarget_time
	return last == nil or GetTime() - last >= period
end

local function SpiderQueenFindFarthestTarget(inst)
	if inst.components.health == nil or inst.components.health:IsDead() then
		return nil
	end
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		return nil
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = TUNING.SPIDER_QUEEN_RETARGET_RANGE or 30
	local best, best_dist_sq = nil, -1
	for _, guy in ipairs(TheSim:FindEntities(x, y, z, range, SPIDER_QUEEN_RETARGET_MUST_TAGS, SPIDER_QUEEN_RETARGET_CANT_TAGS)) do
		if SpiderQueenCanRetargetEntity(inst, guy) then
			local dist_sq = inst:GetDistanceSqToInst(guy)
			if dist_sq > best_dist_sq then
				best_dist_sq = dist_sq
				best = guy
			end
		end
	end
	return best
end

-- 每 N 秒至多重选一次最远目标（受击也受此冷却限制）；玩家附身/操控时不介入
local function SpiderQueenRetarget(inst)
	if SpiderQueenIsPlayerControlled(inst) then
		return nil
	end
	if not SpiderQueenCanRetargetNow(inst) then
		return
	end
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	local best = SpiderQueenFindFarthestTarget(inst)
	if best == nil then
		return
	end
	inst._spider_queen_last_retarget_time = GetTime()
	if best ~= combat.target then
		SpiderQueenCombatSetTarget(inst, best)
		combat:ShareTarget(best, SPIDER_QUEEN_SHARE_TARGET_DIST, SpiderQueenShareTargetFn, 2)
	end
	return best
end

local function SpiderQueenOnAttackedRetarget(inst, data)
	if not SpiderQueenIsNightmareBoss(inst) then
		return
	end
	if SpiderQueenIsPlayerControlled(inst) then
		return
	end
	if SpiderQueenIsTargetLockActive(inst) then
		return
	end
	-- 等原版 attacked 设完 attacker 后，仅在索敌冷却结束时才改打最远目标
	inst:DoTaskInTime(0, function(queen)
		if queen:IsValid() then
			SpiderQueenRetarget(queen)
		end
	end)
end

local function SpiderQueenPickSpecialSpiderPrefab()
	return SPIDER_QUEEN_SPECIAL_SPIDER_POOL[math.random(#SPIDER_QUEEN_SPECIAL_SPIDER_POOL)]
end

local function SpiderQueenSpawnSpecialSpider(inst, target, spawn_angle)
	local prefab = SpiderQueenPickSpecialSpiderPrefab()
	local spider = inst.components.lootdropper ~= nil and inst.components.lootdropper:SpawnLootPrefab(prefab) or nil
	if spider == nil then
		return
	end
	local rad = spider:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + 0.25
	local x, y, z = inst.Transform:GetWorldPosition()
	spider.Transform:SetPosition(
		x + rad * math.cos(spawn_angle),
		0,
		z - rad * math.sin(spawn_angle)
	)
	if spider.sg ~= nil and spider.sg:HasState("taunt") then
		spider.sg:GoToState("taunt")
	end
	if inst.components.leader ~= nil then
		inst.components.leader:AddFollower(spider)
	end
	if target ~= nil and target:IsValid() and spider.components.combat ~= nil then
		spider.components.combat:SetTarget(target)
	end
end

local function SpiderQueenMakeSpecialBabies(inst)
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	local count = TUNING.SPIDER_QUEEN_SPAWN_SPECIAL_COUNT or 3
	local base_angle = (inst.Transform:GetRotation() + 180) * DEGREES
	for i = 1, count do
		local angle = base_angle + (i - 1) * (TWOPI / count)
		SpiderQueenSpawnSpecialSpider(inst, target, angle)
	end
end

local function SpiderQueenTrySpawnSpiders(inst)
	if inst.sg == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	if inst.sg:HasState("spider_queen_spawn_spiders") then
		inst.sg:GoToState("spider_queen_spawn_spiders")
	end
end

local function SpiderQueenRecordAttackFinished(inst)
	if inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	inst._spider_queen_attack_count = (inst._spider_queen_attack_count or 0) + 1
end

local function SpiderQueenGoTaunt(inst)
	if inst.sg == nil then
		return
	end
	if inst.sg:HasState("taunt") then
		inst.sg:GoToState("taunt")
	else
		inst.sg:GoToState("idle")
	end
end

local function SpiderQueenGoDoubleTaunt(inst)
	if inst.sg == nil then
		return
	end
	if inst.sg:HasState("spider_queen_double_taunt") then
		inst.sg:GoToState("spider_queen_double_taunt")
	else
		SpiderQueenGoTaunt(inst)
	end
end

local function SpiderQueenEndAttackGoNext(inst)
	if inst.sg == nil then
		return
	end
	if inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	SpiderQueenRecordAttackFinished(inst)
	local count = inst._spider_queen_attack_count or 0
	local spawn_every = math.max(1, TUNING.SPIDER_QUEEN_SPAWN_EVERY_N_ATTACKS or 5)
	local taunt_every = math.max(1, TUNING.SPIDER_QUEEN_TAUNT_EVERY_N_ATTACKS or 2)
	if count % spawn_every == 0 then
		SpiderQueenTrySpawnSpiders(inst)
		return
	end
	if count % taunt_every == 0 then
		SpiderQueenGoDoubleTaunt(inst)
		return
	end
	inst.sg:GoToState("idle")
end

local function SpiderQueenEndChargeAttackGoNext(inst)
	if inst.sg == nil then
		return
	end
	if inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	SpiderQueenRecordAttackFinished(inst)
	local count = inst._spider_queen_attack_count or 0
	local spawn_every = math.max(1, TUNING.SPIDER_QUEEN_SPAWN_EVERY_N_ATTACKS or 5)
	if count % spawn_every == 0 then
		SpiderQueenTrySpawnSpiders(inst)
		return
	end
	inst.sg:GoToState("idle")
end

local function SpiderQueenShouldChargeAttack(inst, target)
	target = SpiderQueenResolveTarget(inst, target)
	if target == nil then
		return false
	end
	local dist = SpiderQueenDistToTarget(inst, target)
	local trigger_range = SpiderQueenGetTriggerAttackRange(inst)
	-- 超出触发近战范围（过远）时优先冲刺
	if dist > trigger_range * 0.85 then
		return true
	end
	return dist >= (TUNING.SPIDER_QUEEN_CHARGE_MIN_DIST or 5)
end

local function SpiderQueenGetChargeAttackTarget(inst)
	return SpiderQueenResolveTarget(inst, inst.sg ~= nil and inst.sg.statemem.target or nil)
end

local function SpiderQueenIsChargeLockedTarget(inst, ent)
	local target = SpiderQueenGetChargeAttackTarget(inst)
	return target ~= nil and ent == target
end

-- 不击飞站在锁定目标身旁的其他玩家
local function SpiderQueenIsPlayerNearChargeTarget(inst, player, exclude_radius)
	local target = SpiderQueenGetChargeAttackTarget(inst)
	if target == nil or player == target then
		return false
	end
	return player:GetDistanceSqToInst(target) <= exclude_radius * exclude_radius
end

local function SpiderQueenTryKnockbackPlayer(inst, player)
	if player == nil or not player:IsValid() or player:IsInLimbo() then
		return
	end
	if SpiderQueenIsChargeLockedTarget(inst, player) then
		return
	end
	if player:HasTag("playerghost") or player:HasTag("nopush") then
		return
	end
	if player.components.health == nil or player.components.health:IsDead() then
		return
	end
	inst._spider_queen_charge_hit = inst._spider_queen_charge_hit or {}
	if inst._spider_queen_charge_hit[player] then
		return
	end
	inst._spider_queen_charge_hit[player] = true

	local damage = TUNING.SPIDER_QUEEN_CHARGE_HIT_DAMAGE or 50
	if player.components.combat ~= nil then
		player.components.combat:GetAttacked(inst, damage, nil, nil, nil)
	end

	-- 先背对女王，保证 knockback 沿远离女王方向飞出
	local qx, qy, qz = inst.Transform:GetWorldPosition()
	local angle_to_queen = player:GetAngleToPoint(qx, qy, qz)
	player.Transform:SetRotation(angle_to_queen + 180)

	local knock_dist = (TUNING.SPIDER_QUEEN_CHARGE_KNOCKBACK_DIST or 5)
		* (TUNING.SPIDER_QUEEN_SCALE or SPIDER_QUEEN_SCALE)
	player:PushEvent("knockback", {
		knocker = inst,
		radius = knock_dist,
		strengthmult = 1,
		starthigh = false,
		forcelanded = false,
	})
end

local function SpiderQueenIsChargeColliding(inst)
	if inst.sg == nil or not inst.sg.statemem.charge_started then
		return false
	end
	if inst.Physics ~= nil then
		local vx, _, vz = inst.Physics:GetVelocity()
		local min_sq = TUNING.SPIDER_QUEEN_CHARGE_COLLIDE_MIN_SPEED_SQ or 36
		if vx * vx + vz * vz >= min_sq then
			return true
		end
	end
	return (inst.sg.statemem.charge_speed or 0) > 6
end

-- 仅在与玩家发生物理碰撞时击飞（参考发条战车 SetCollisionCallback）
local function SpiderQueenOnChargeCollide(inst, other)
	if other == nil or not other:IsValid() or not other:HasTag("player") then
		return
	end
	if not SpiderQueenIsChargeColliding(inst) then
		return
	end
	local exclude_radius = TUNING.SPIDER_QUEEN_CHARGE_TARGET_EXCLUDE_RADIUS or 3
	if SpiderQueenIsChargeLockedTarget(inst, other)
		or SpiderQueenIsPlayerNearChargeTarget(inst, other, exclude_radius) then
		return
	end
	SpiderQueenTryKnockbackPlayer(inst, other)
end

local function SpiderQueenAoeHitsEntity(ent, attacker)
	if ent == nil or not ent:IsValid() or attacker == nil or not attacker:IsValid() then
		return false
	end
	if ent == attacker then
		return false
	end
	if attacker.components.leader ~= nil and attacker.components.leader:IsFollower(ent) then
		return false
	end
	if ent:HasTag("spider") or ent:HasTag("spiderqueen") then
		return false
	end
	return true
end

local function SpiderQueenNormalizeAngleDiff(diff)
	while diff > 180 do
		diff = diff - 360
	end
	while diff < -180 do
		diff = diff + 360
	end
	return diff
end

local function SpiderQueenIsInAttackSector(inst, ent, range, half_angle)
	if ent == nil or not ent:IsValid() or inst == nil or not inst:IsValid() then
		return false
	end
	if inst.GetDistanceSqToInst == nil then
		return false
	end
	local dist_sq = inst:GetDistanceSqToInst(ent)
	if dist_sq > range * range then
		return false
	end
	local facing = inst.Transform:GetRotation()
	local ent_angle = inst:GetAngleToPoint(ent.Transform:GetWorldPosition())
	local diff = SpiderQueenNormalizeAngleDiff(ent_angle - facing)
	return math.abs(diff) <= half_angle
end

local function SpiderQueenDoSectorAttack(inst, targ, weapon, stimuli)
	local combat = inst.components.combat
	if combat == nil then
		return false
	end
	weapon = weapon or combat:GetWeapon()
	local range = SpiderQueenGetAttackRange(inst)
	local half_angle = (TUNING.SPIDER_QUEEN_ATTACK_ANGLE or 60) * 0.5
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, range, AREAATTACK_MUST_TAGS, AREAATTACK_EXCLUDE_TAGS)
	local mult = TUNING.SPIDER_QUEEN_AOE_MULT or 1
	local primary_hit = false

	for _, ent in ipairs(ents) do
		if ent ~= inst and combat:IsValidTarget(ent) and SpiderQueenAoeHitsEntity(ent, inst)
			and SpiderQueenIsInAttackSector(inst, ent, range, half_angle) then
			inst:PushEvent("onareaattackother", { target = ent, weapon = weapon, stimuli = stimuli })
			local dmg, spdmg = combat:CalcDamage(ent, weapon, mult)
			ent.components.combat:GetAttacked(inst, dmg, weapon, stimuli, spdmg)
			if targ ~= nil and ent == targ then
				primary_hit = true
			end
		end
	end

	if primary_hit and targ ~= nil and targ:IsValid() then
		inst:PushEvent("onattackother", { target = targ, weapon = weapon, stimuli = stimuli })
		if weapon ~= nil and weapon.components.weapon ~= nil then
			weapon.components.weapon:OnAttack(inst, targ, nil)
		end
	end

	combat:ClearAttackTemps()
	combat.lastdoattacktime = GetTime()
	if targ ~= nil and targ:IsValid() then
		SpiderQueenLockTargetAfterAttack(inst, targ)
	end
	return primary_hit
end

local function SpiderQueenCalcCharge(travel)
	local speed = TUNING.SPIDER_QUEEN_CHARGE_SPEED or 20
	local chargetime = travel / speed
	local tmin = TUNING.SPIDER_QUEEN_CHARGE_MIN_TIME or 0.35
	local tmax = TUNING.SPIDER_QUEEN_CHARGE_MAX_TIME or 1.25
	if chargetime < tmin then
		chargetime = tmin
	elseif chargetime > tmax then
		chargetime = tmax
	end
	speed = travel / chargetime
	return travel, chargetime, speed
end

local function SpiderQueenRestorePhysics(inst)
	if inst.Physics == nil then
		return
	end
	inst.Physics:SetCollisionMask(
		COLLISION.WORLD,
		COLLISION.OBSTACLES,
		COLLISION.SMALLOBSTACLES,
		COLLISION.CHARACTERS,
		COLLISION.GIANTS
	)
end

local function SpiderQueenBeginChargePhysics(inst)
	if inst.Physics == nil then
		return
	end
	inst.Physics:Stop()
	if inst.Physics.ClearCollisionMask ~= nil then
		inst.Physics:ClearCollisionMask()
		inst.Physics:CollidesWith(COLLISION.GROUND)
		inst.Physics:CollidesWith(COLLISION.WORLD)
		inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst.Physics:CollidesWith(COLLISION.GIANTS)
	else
		inst.Physics:SetCollisionMask(
			COLLISION.GROUND,
			COLLISION.WORLD,
			COLLISION.CHARACTERS,
			COLLISION.GIANTS
		)
	end
end

local function SpiderQueenGetChargeStopDist(inst)
	local frac = TUNING.SPIDER_QUEEN_CHARGE_STOP_RANGE_FRAC or 0.5
	return SpiderQueenGetAttackRange(inst) * frac
end

local function SpiderQueenComputeChargeTravel(inst, target)
	target = SpiderQueenResolveTarget(inst, target)
	if target == nil then
		return nil
	end
	local dist = SpiderQueenDistToTarget(inst, target)
	local stop_dist = SpiderQueenGetChargeStopDist(inst)
	local travel = dist - stop_dist
	if travel <= 0 then
		return target, nil
	end
	local dmax = TUNING.SPIDER_QUEEN_CHARGE_MAX_TRAVEL or 16
	if travel > dmax then
		travel = dmax
	end
	return target, travel
end

local function SpiderQueenShouldEndChargeEarly(inst)
	local target = SpiderQueenResolveTarget(inst, inst.sg ~= nil and inst.sg.statemem.target or nil)
	if target == nil then
		return false
	end
	return SpiderQueenDistToTarget(inst, target) <= SpiderQueenGetChargeStopDist(inst) + 0.15
end

local function SpiderQueenEndChargeMotor(inst)
	if inst.AnimState ~= nil then
		inst.AnimState:SetDeltaTimeMultiplier(1)
	end
	if inst.Physics ~= nil then
		inst.Physics:Stop()
		inst.Physics:ClearMotorVelOverride()
	end
	SpiderQueenRestorePhysics(inst)
	if inst.components.locomotor ~= nil then
		inst.components.locomotor:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
	end
end

-- 冲刺起跳瞬间锁定朝向；冲刺中每帧恢复（附身 mod 会改 locomotor 转向，必须写死）
-- 注意：不可在 locomote 回调里调用 locomotor:Stop()，否则会再次触发 locomote 导致栈溢出崩溃
local function SpiderQueenLockChargeHeading(inst)
	if inst.sg == nil or inst.sg.statemem == nil then
		return
	end
	local rot = inst.sg.statemem.charge_rotation
	if rot == nil then
		return
	end
	inst.Transform:SetRotation(rot)
	local speed = inst.sg.statemem.charge_speed
	if speed ~= nil and inst.Physics ~= nil then
		inst.Physics:SetMotorVelOverride(speed, 0, 0)
	end
end

local function SpiderQueenBeginChargeMotor(inst)
	local target, travel = SpiderQueenComputeChargeTravel(inst, inst.sg.statemem.target)
	if target == nil or travel == nil or travel <= 0 then
		return false
	end
	inst.sg.statemem.target = target
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	inst.sg.statemem.charge_rotation = inst.Transform:GetRotation()
	travel, inst.sg.statemem.charge_time, inst.sg.statemem.charge_speed = SpiderQueenCalcCharge(travel)
	inst.sg.statemem.travel_dist = travel
	local loop_visual = TUNING.SPIDER_QUEEN_CHARGE_LOOP_VISUAL or 0.38
	local charge_time = inst.sg.statemem.charge_time
	-- 近距冲刺：加快 loop；远距：放慢 loop 与位移时长对齐
	local mult = loop_visual / charge_time
	mult = math.max(0.55, math.min(mult, 2.5))
	inst.AnimState:SetDeltaTimeMultiplier(mult)
	SpiderQueenBeginChargePhysics(inst)
	SpiderQueenLockChargeHeading(inst)
	return true
end

local function SpiderQueenFinishChargeToLand(inst)
	if inst.sg == nil or inst.sg.currentstate == nil
		or inst.sg.currentstate.name ~= "spider_queen_charge_attack" then
		return
	end
	if inst.sg.statemem.charge_landing then
		return
	end
	inst.sg.statemem.charge_landing = true
	SpiderQueenEndChargeMotor(inst)
	inst:RestartBrain(SPIDER_QUEEN_CHARGE_BRAIN)
	inst.sg:GoToState("spider_queen_charge_land", inst.sg.statemem.target)
end

local function SpiderQueenDoMeleeHit(inst)
	if inst.components.combat == nil then
		return
	end
	local weapon = inst.components.combat:GetWeapon()
	local target = SpiderQueenResolveTarget(inst, inst.sg ~= nil and inst.sg.statemem.target or nil)
	if target ~= nil then
		inst:ForceFacePoint(target.Transform:GetWorldPosition())
	end
	SpiderQueenDoSectorAttack(inst, target, weapon)
end

local function SpiderQueenGoChargeAttack(inst, target)
	if SpiderQueenIsPlayerControlled(inst) then
		target = SpiderQueenResolveTarget(inst, target)
	else
		local farthest = SpiderQueenFindFarthestTarget(inst)
		if farthest ~= nil then
			target = farthest
			SpiderQueenCombatSetTarget(inst, farthest)
		else
			target = SpiderQueenResolveTarget(inst, target)
		end
	end
	if target == nil or inst.sg == nil then
		return false
	end
	SpiderQueenLockTargetAfterAttack(inst, target)
	inst.sg:GoToState("spider_queen_charge_attack", target)
	return true
end

local function SpiderQueenGoMeleeAttack(inst)
	if inst.sg == nil then
		return false
	end
	SpiderQueenLockTargetAfterAttack(inst, SpiderQueenResolveTarget(inst, nil))
	inst.sg:GoToState("attack")
	return true
end

local function SpiderQueenGetHitstunCooldown()
	return TUNING.SPIDER_QUEEN_HITSTUN_COOLDOWN or 2
end

local function SpiderQueenCanTriggerHitstun(inst)
	if not SpiderQueenIsNightmareBoss(inst) then
		return true
	end
	local last = inst._spider_queen_last_hitstun_time
	if last == nil then
		return true
	end
	return GetTime() - last >= SpiderQueenGetHitstunCooldown()
end

local function SpiderQueenRecordHitstun(inst)
	if SpiderQueenIsNightmareBoss(inst) then
		inst._spider_queen_last_hitstun_time = GetTime()
	end
end

local function SpiderQueenCanCombat(inst)
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.sg == nil then
		return false
	end
	return not inst.sg:HasStateTag("busy")
end

local function SpiderQueenStartCharge(inst)
	if inst.sg == nil or inst.sg.currentstate == nil or inst.sg.currentstate.name ~= "spider_queen_charge_attack" then
		return
	end
	if inst.sg.statemem.charge_started then
		return
	end
	inst.sg.statemem.charge_started = true
	inst._spider_queen_charge_hit = {}
	inst.AnimState:PlayAnimation("poop_loop")
	if not SpiderQueenBeginChargeMotor(inst) then
		inst:RestartBrain(SPIDER_QUEEN_CHARGE_BRAIN)
		inst.sg:GoToState("attack")
		return
	end
	inst.sg:SetTimeout(inst.sg.statemem.charge_time)
end

AddStategraphState("spiderqueen", State({
	name = "spider_queen_charge_attack",
	tags = { "attack", "busy", "nointerrupt" },
	onenter = function(inst, target)
		inst.sg.statemem.target = SpiderQueenResolveTarget(inst, target)
		inst.sg.statemem.charge_started = false
		inst.sg.statemem.charge_landing = false
		inst.sg.statemem.charge_rotation = nil
		inst:StopBrain(SPIDER_QUEEN_CHARGE_BRAIN)
		inst.Physics:Stop()
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		end
		local t = inst.sg.statemem.target
		if t ~= nil then
			inst:ForceFacePoint(t.Transform:GetWorldPosition())
		end
		inst.AnimState:PlayAnimation("poop_pre")
	end,
	events = {
		EventHandler("locomote", function(inst)
			if inst.sg.statemem.charge_started then
				SpiderQueenLockChargeHeading(inst)
			end
		end),
	},
	timeline = {
		TimeEvent(TUNING.SPIDER_QUEEN_CHARGE_PRE_FRAMES * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
			SpiderQueenStartCharge(inst)
		end),
	},
	onupdate = function(inst)
		if inst.sg.statemem.charge_started then
			SpiderQueenLockChargeHeading(inst)
			SpiderQueenTryDropChargeWeb(inst)
			if SpiderQueenShouldEndChargeEarly(inst) then
				SpiderQueenFinishChargeToLand(inst)
			end
		end
	end,
	ontimeout = function(inst)
		SpiderQueenFinishChargeToLand(inst)
	end,
	onexit = function(inst)
		inst._spider_queen_charge_hit = nil
		if inst.sg ~= nil and inst.sg.statemem ~= nil then
			inst.sg.statemem.charge_rotation = nil
		end
		if inst.sg ~= nil and inst.sg.statemem ~= nil and inst.sg.statemem.charge_landing then
			return
		end
		SpiderQueenEndChargeMotor(inst)
		inst:RestartBrain(SPIDER_QUEEN_CHARGE_BRAIN)
	end,
}))

AddStategraphState("spiderqueen", State({
	name = "spider_queen_charge_land",
	tags = { "attack", "busy" },
	onenter = function(inst, target)
		inst.sg.statemem.target = SpiderQueenResolveTarget(inst, target)
		inst.Physics:Stop()
		SpiderQueenRestorePhysics(inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		end
		if inst.components.combat ~= nil then
			inst.components.combat:StartAttack()
		end
		local t = inst.sg.statemem.target
		if t ~= nil then
			inst:ForceFacePoint(t.Transform:GetWorldPosition())
		end
		inst.AnimState:PlayAnimation("atk")
	end,
	timeline = {
		TimeEvent(0 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack")
		end),
		TimeEvent(25 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
		end),
		TimeEvent(28 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/swipe")
			SpiderQueenDoMeleeHit(inst)
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			SpiderQueenEndChargeAttackGoNext(inst)
		end),
	},
}))

AddStategraphState("spiderqueen", State({
	name = "spider_queen_double_taunt",
	tags = { "busy" },
	onenter = function(inst)
		inst.Physics:Stop()
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:Stop()
		end
		inst.sg.statemem.double_taunt_phase = 1
		inst.AnimState:PlayAnimation("taunt")
		inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
	end,
	events = {
		EventHandler("animover", function(inst)
			local p = inst.sg.statemem.double_taunt_phase or 1
			if p == 1 then
				inst.sg.statemem.double_taunt_phase = 2
				inst.AnimState:PlayAnimation("taunt")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
			else
				inst.sg:GoToState("idle")
			end
		end),
	},
}))

AddStategraphState("spiderqueen", State({
	name = "spider_queen_spawn_spiders",
	tags = { "busy", "nointerrupt" },
	onenter = function(inst)
		inst.Physics:Stop()
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:Stop()
		end
		inst.sg.statemem.spawn_phase = 1
		inst.AnimState:PlayAnimation("poop_pre")
	end,
	timeline = {
		TimeEvent(20 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			inst.sg:GoToState("spider_queen_spawn_spiders_loop")
		end),
	},
}))

AddStategraphState("spiderqueen", State({
	name = "spider_queen_spawn_spiders_loop",
	tags = { "busy", "nointerrupt" },
	onenter = function(inst)
		inst.AnimState:PlayAnimation("poop_loop")
	end,
	timeline = {
		TimeEvent(4 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice")
		end),
		TimeEvent(10 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley")
			SpiderQueenMakeSpecialBabies(inst)
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			if inst.sg:HasState("poop_pst") then
				inst.sg:GoToState("poop_pst")
			else
				inst.sg:GoToState("idle")
			end
		end),
	},
}))

AddStategraphPostInit("spiderqueen", function(sg)
	local attack = sg.states.attack
	if attack ~= nil and attack.events ~= nil and attack.events.animover ~= nil then
		attack.events.animover.fn = function(inst)
			SpiderQueenEndAttackGoNext(inst)
		end
	end

	local doattack = sg.events.doattack
	if doattack ~= nil then
		local old_doattack = doattack.fn
		doattack.fn = function(inst, data)
			if inst.components.health ~= nil and not inst.components.health:IsDead()
				and SpiderQueenCanCombat(inst) then
				local target = data ~= nil and data.target or nil
				if SpiderQueenIsPlayerControlled(inst) then
					target = SpiderQueenResolveTarget(inst, target)
					if target ~= nil then
						SpiderQueenCombatSetTarget(inst, target)
					end
				else
					target = SpiderQueenResolveTarget(inst, target)
				end
				if SpiderQueenShouldChargeAttack(inst, target) then
					SpiderQueenGoChargeAttack(inst, target)
					return
				end
				SpiderQueenGoMeleeAttack(inst)
				return
			end
			if old_doattack ~= nil then
				old_doattack(inst, data)
			end
		end
	end

	-- 模组蜘蛛女王：可僵直，但触发后 2 秒内免疫再次僵直
	local attacked = sg.events.attacked
	if attacked ~= nil then
		local old_attacked = attacked.fn
		attacked.fn = function(inst, data)
			if SpiderQueenIsNightmareBoss(inst) and not SpiderQueenCanTriggerHitstun(inst) then
				return
			end
			if old_attacked ~= nil then
				old_attacked(inst, data)
			end
			if SpiderQueenIsNightmareBoss(inst) and inst.sg ~= nil and inst.sg:HasStateTag("hit") then
				SpiderQueenRecordHitstun(inst)
			end
		end
	end
end)

AddPrefabPostInit("spiderqueen", function(inst)
	local scale = TUNING.SPIDER_QUEEN_SCALE or SPIDER_QUEEN_SCALE
	inst.Transform:SetScale(scale, scale, scale)
	if inst.DynamicShadow ~= nil then
		inst.DynamicShadow:SetSize(7 * scale, 3 * scale)
	end

	if not TheWorld.ismastersim then
		return
	end
	if inst._spider_queen_nightmare_patched then
		return
	end
	inst._spider_queen_nightmare_patched = true
	if inst.sg ~= nil and inst.sg.mem ~= nil then
		inst.sg.mem.noelectrocute = true
	end
	inst:AddTag("epic")

	if inst.components.health ~= nil then
		local maxhp = TUNING.SPIDER_QUEEN_MAX_HEALTH or 5000
		local spawnhp = TUNING.SPIDER_QUEEN_SPAWN_HEALTH or 2000
		inst.components.health:SetMaxHealth(maxhp)
		inst.components.health:SetCurrentHealth(math.min(spawnhp, maxhp))
	end

	if inst.Physics ~= nil then
		local rad = 1 * scale + SPIDER_QUEEN_PHYSICS_RADIUS_EXTRA
		if inst.Physics.SetCapsule ~= nil then
			inst.Physics:SetCapsule(rad, rad * 2)
		end
		if not inst._spider_queen_charge_collide_patched then
			inst._spider_queen_charge_collide_patched = true
			inst.Physics:SetCollisionCallback(function(queen, other)
				SpiderQueenOnChargeCollide(queen, other)
			end)
		end
	end

	local trigger_range = SpiderQueenGetScaledAttackRange()
		+ (TUNING.SPIDER_QUEEN_ATTACK_RANGE_TRIGGER_EXTRA or 0.5)
	local hit_range = trigger_range + (TUNING.SPIDER_QUEEN_HIT_RANGE_EXTRA or 1)
	local health = inst.components.health
	if health ~= nil and not inst._spider_queen_fire_panic_patched then
		inst._spider_queen_fire_panic_patched = true
		local _DoFireDamage = health.DoFireDamage
		health.DoFireDamage = function(self, amount, doer, instant)
			if not SpiderQueenIsNightmareBoss(self.inst) then
				return _DoFireDamage(self, amount, doer, instant)
			end
			_DoFireDamage(self, amount, doer, instant)
			SpiderQueenClearFirePanic(self)
		end
	end

	local combat = inst.components.combat
	if combat ~= nil then
		combat:SetDefaultDamage(TUNING.SPIDER_QUEEN_DAMAGE or 120)
		combat:SetRange(trigger_range, hit_range)
		combat:SetRetargetFunction(TUNING.SPIDER_QUEEN_RETARGET_PERIOD or 4, function(ent, ...)
			if SpiderQueenIsPlayerControlled(ent) then
				return nil
			end
			return SpiderQueenRetarget(ent, ...)
		end)
		combat:EnableAreaDamage(false)
		if not combat._spider_queen_settarget_patched then
			combat._spider_queen_settarget_patched = true
			local _SetTarget = combat.SetTarget
			combat.SetTarget = function(self, target)
				local owner = self.inst
				if owner ~= nil and owner:IsValid() and owner.prefab == "spiderqueen"
					and SpiderQueenIsNightmareBoss(owner) then
					if SpiderQueenIsPlayerControlled(owner) then
						SpiderQueenClearTargetLock(owner)
						return _SetTarget(self, target)
					end
					if SpiderQueenIsTargetLockActive(owner)
						and not owner._spider_queen_allow_set_target then
						return
					end
				end
				return _SetTarget(self, target)
			end
		end
		if not combat._spider_queen_sharetarget_patched then
			combat._spider_queen_sharetarget_patched = true
			local _ShareTarget = combat.ShareTarget
			combat.ShareTarget = function(self, newtarget, range, fn, maxnum)
				local owner = self.inst
				if owner ~= nil and owner:IsValid() and owner.prefab == "spiderqueen"
					and SpiderQueenIsNightmareBoss(owner)
					and SpiderQueenIsPlayerControlled(owner) then
					return
				end
				return _ShareTarget(self, newtarget, range, fn, maxnum)
			end
		end
		if not combat._spider_queen_doattack_patched then
			combat._spider_queen_doattack_patched = true
			local _DoAttack = combat.DoAttack
			combat.DoAttack = function(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
				local owner = self.inst
				if owner ~= nil and owner:IsValid() and owner.prefab == "spiderqueen" then
					return SpiderQueenDoSectorAttack(owner, targ, weapon, stimuli)
				end
				return _DoAttack(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
			end
		end
		if not combat._spider_queen_tryattack_patched then
			combat._spider_queen_tryattack_patched = true
			local _TryAttack = combat.TryAttack
			combat.TryAttack = function(self, target)
				local owner = self.inst
				if owner == nil or not owner:IsValid() or owner.prefab ~= "spiderqueen" then
					return _TryAttack(self, target)
				end
				if SpiderQueenIsPlayerControlled(owner) then
					return _TryAttack(self, target)
				end
				if owner.sg ~= nil and owner.sg:HasStateTag("busy") then
					return false
				end
				target = target or self.target
				if target ~= nil and target:IsValid() and not self:InCooldown()
					and SpiderQueenShouldChargeAttack(owner, target) then
					owner:PushEvent("doattack", { target = target })
					return true
				end
				return _TryAttack(self, target)
			end
		end
	end

	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
	end
	inst.components.planardamage:SetBaseDamage(TUNING.SPIDER_QUEEN_PLANAR_DAMAGE or 15)
	if inst.components.planarentity == nil then
		inst:AddComponent("planarentity")
	end

	inst._spider_queen_attack_count = 0
	inst._spider_queen_last_hitstun_time = nil

	if inst.components.locomotor ~= nil then
		inst.components.locomotor:SetTriggersCreep(false)
	end
	SpiderQueenStartWalkWebTrail(inst)

	if not inst._spider_queen_attacked_retarget_patched then
		inst._spider_queen_attacked_retarget_patched = true
		inst:ListenForEvent("attacked", SpiderQueenOnAttackedRetarget)
	end

	if not inst._spider_queen_possess_watch_patched then
		inst._spider_queen_possess_watch_patched = true
		inst._spider_queen_was_player_controlled = false
		inst:DoPeriodicTask(0.25, function(queen)
			if not queen:IsValid() then
				return
			end
			local pc = SpiderQueenIsPlayerControlled(queen)
			if pc then
				if not queen._spider_queen_was_player_controlled then
					SpiderQueenClearTargetLock(queen)
				end
				if queen.brain ~= nil then
					queen.brain:Stop()
				end
			end
			queen._spider_queen_was_player_controlled = pc
		end)
	end

	inst:ListenForEvent("onremove", function()
		if inst._spider_queen_web_task ~= nil then
			inst._spider_queen_web_task:Cancel()
			inst._spider_queen_web_task = nil
		end
	end)

	if inst.components.incrementalproducer ~= nil then
		inst.components.incrementalproducer.producefn = function() end
		inst.components.incrementalproducer.CanProduce = function()
			return false
		end
	end
end)

AddPrefabPostInit(SPIDER_QUEEN_WEB_CREEP_PREFAB, function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst._spider_queen_web_creep_patched then
		return
	end
	inst._spider_queen_web_creep_patched = true

	inst._SpiderQueenWebCreepRemove = inst.Remove
	inst.Remove = function(self)
		if self._spider_queen_trail and not self._spider_queen_allow_remove then
			return
		end
		if self._spider_queen_trail_task ~= nil then
			self._spider_queen_trail_task:Cancel()
			self._spider_queen_trail_task = nil
		end
		if self._spider_queen_despawn_task ~= nil then
			self._spider_queen_despawn_task:Cancel()
			self._spider_queen_despawn_task = nil
			self._spider_queen_despawn_taskinfo = nil
		end
		return self:_SpiderQueenWebCreepRemove()
	end
end)
