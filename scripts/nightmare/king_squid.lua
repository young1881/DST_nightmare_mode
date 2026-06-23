local easing = require("easing")

local KING_SQUID_STAT_SCALE          = 0.9  -- 体型、攻击范围等整体 ×0.9（缩小 10%）
local KING_SQUID_SIZE_MULT           = 1.15 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_SCALE            = 1.8 * KING_SQUID_SIZE_MULT

TUNING.KING_SQUID_PHYSICS_MASS     = 10
TUNING.KING_SQUID_PHYSICS_RADIUS   = 0.5 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_SHADOW_WIDTH     = 2.5 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_SHADOW_HEIGHT    = 1.5 * KING_SQUID_STAT_SCALE

TUNING.KING_SQUID_HEALTH           = 1600
TUNING.KING_SQUID_MELEE_HIT_PHYSICAL = 65  -- 近战每一击物理伤害
TUNING.KING_SQUID_MELEE_HIT_PLANAR   = 20  -- 近战每一击位面伤害
TUNING.KING_SQUID_DAMAGE             = TUNING.KING_SQUID_MELEE_HIT_PHYSICAL
TUNING.KING_SQUID_MELEE_COMBO_HITS   = 3
TUNING.KING_SQUID_ATTACK_PERIOD      = 3
TUNING.KING_SQUID_PLANAR_DAMAGE      = TUNING.KING_SQUID_MELEE_HIT_PLANAR
TUNING.KING_SQUID_TARGET_RANGE     = 2 * KING_SQUID_SIZE_MULT
TUNING.KING_SQUID_ATTACK_RANGE     = 1.5
TUNING.KING_SQUID_TARGET_KEEP      = 52 * KING_SQUID_SIZE_MULT
TUNING.KING_SQUID_AREA_DAMAGE_MULT = 1
TUNING.KING_SQUID_RETARGET_PERIOD  = 5.5

TUNING.KING_SQUID_SPAWN_LEASH        = 36
TUNING.KING_SQUID_GO_HOME_DIST       = 3   -- 距巢穴超过此距离且无目标时主动走回 spawner
TUNING.KING_SQUID_WANDER_RADIUS      = 11
-- 索敌：6 格地皮半径（每格 4 世界单位）
TUNING.KING_SQUID_PLAYER_DETECT_TILES = 6 * KING_SQUID_SIZE_MULT
-- 入睡
TUNING.KING_SQUID_SLEEP_STILL_SEC = 5
TUNING.KING_SQUID_SLEEP_HEALTH_REGEN = 10
TUNING.KING_SQUID_SLEEP_HEALTH_REGEN_PERIOD = 5
-- 玩家进入该距离内会苏醒
TUNING.KING_SQUID_WAKE_DETECT_RANGE = 25 * KING_SQUID_STAT_SCALE

TUNING.KING_SQUID_SPEED_MULT       = 0.175
TUNING.KING_SQUID_RUN_SPEED        = 6 * TUNING.KING_SQUID_SPEED_MULT
TUNING.KING_SQUID_WALK_SPEED       = 3 * TUNING.KING_SQUID_SPEED_MULT
TUNING.KING_SQUID_WATER_HOP_DIST   = 4

TUNING.KING_SQUID_SANITY_AURA      = -(TUNING.SANITYAURA_MED or 40)
-- 眼部光：发暗紫色
TUNING.KING_SQUID_LIGHT_R          = 72 / 255
TUNING.KING_SQUID_LIGHT_G          = 16 / 255
TUNING.KING_SQUID_LIGHT_B          = 98 / 255
TUNING.KING_SQUID_LIGHT_INTENSITY  = 0.52
TUNING.KING_SQUID_LIGHT_FALLOFF    = 0.65
TUNING.KING_SQUID_LIGHT_RADIUS     = 1.35

TUNING.KING_SQUID_INK_BURST_COUNT  = 15
-- 弹速插值：近快远慢（同帝王蟹加农炮 / 原版鱿鱼），配合 usehigharc=false 低弧度
TUNING.KING_SQUID_INK_SPEED_NEAR   = 15
TUNING.KING_SQUID_INK_SPEED_FAR    = 6  -- 插值下限；远距离由下方射程保底覆盖
TUNING.KING_SQUID_INK_GRAVITY      = -25
TUNING.KING_SQUID_INK_HIT_RADIUS   = 1 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_INK_PHYSICAL_DAMAGE = 15
TUNING.KING_SQUID_INK_PLANAR_DAMAGE   = 30
-- 跳跃接近：朝玩家方向起跳，落地后再锁当前位置近战（起跳不锁死落点）
TUNING.KING_SQUID_LUNGE_LAND_MARGIN  = 0.25
TUNING.KING_SQUID_LUNGE_STAND_OFF    = 1   -- 落在目标「前方」的世界单位（朝玩家面向/逃跑方向，非鱿王→目标直线）
TUNING.KING_SQUID_LUNGE_TARGET_LEAD  = 0.18 -- 起跳前锁定目标（与 LEAP_WINDUP 一致）
TUNING.KING_SQUID_HITSTUN_IMMUNE_AFTER    = 2   -- 受击僵直累计超过此秒数
TUNING.KING_SQUID_HITSTUN_IMMUNE_DURATION = 1   -- 触发后免疫 hit 的时长（秒）
TUNING.KING_SQUID_LUNGE_MIN_DIST     = 0.55
-- 跳跃/喷墨：触发距离与最大水平位移（世界单位）
TUNING.KING_SQUID_COMBAT_RANGE       = 30 * KING_SQUID_SIZE_MULT
TUNING.KING_SQUID_LUNGE_MAX_DIST     = 30 * KING_SQUID_SIZE_MULT
TUNING.KING_SQUID_INK_CAST_RANGE     = 30 * KING_SQUID_SIZE_MULT
-- 抛物线跳跃
TUNING.KING_SQUID_LEAP_WINDUP        = 0.18 -- 仅用于锁定目标，实际起跳以 jump 动画时长为准
TUNING.KING_SQUID_LEAP_JUMP_FALLBACK = 10 * FRAMES
TUNING.KING_SQUID_LEAP_LOOP_FALLBACK = 26 * FRAMES
TUNING.KING_SQUID_LEAP_HSPEED        = 42
TUNING.KING_SQUID_LEAP_ARC_HEIGHT    = 2.2
TUNING.KING_SQUID_LEAP_ARC_HEIGHT_PER_DIST = 0.025
TUNING.KING_SQUID_LEAP_ARC_HEIGHT_MAX = 3.8
TUNING.KING_SQUID_LEAP_AIR_TIME_SCALE = 0.55 -- 腾空位移时长 = 动画全长 × 此比例（<1 更快）；动画本身保持 1 倍速
TUNING.KING_SQUID_LEAP_DURATION_MIN  = 0.34
TUNING.KING_SQUID_LEAP_DURATION_MAX  = 0.72
-- 水平位移低于此值时：腾空时长对齐 jump+jump_loop 全长，压低弧高，避免近距滑铲动画错位
TUNING.KING_SQUID_LEAP_ANIM_SYNC_TRAVEL = 7 * KING_SQUID_SIZE_MULT
-- 喷墨冷却（与 ATTACK_PERIOD 接近，配合交替逻辑使跳跃/喷墨次数相当）
TUNING.KING_SQUID_INK_COOLDOWN_MIN   = 2.4
TUNING.KING_SQUID_INK_COOLDOWN_MAX   = 3.2
TUNING.KING_SQUID_INK_CAST_TILES         = 8 -- 兼容旧引用
TUNING.KING_SQUID_CROSS_MEDIUM_LUNGE_MAX_DIST = 30 * KING_SQUID_SIZE_MULT
TUNING.KING_SQUID_SLEEP_HEALTH_CAP = 0.5
-- 受伤大跳
TUNING.KING_SQUID_POST_RETREAT_PANIC = 3
TUNING.KING_SQUID_POST_RETREAT_WANDER_RADIUS = 5
-- 滑铲接近战首段
TUNING.KING_SQUID_MELEE_ENTRY_CARRY_MULT   = 0.34
TUNING.KING_SQUID_MELEE_ENTRY_CARRY_FRAMES = 2
-- 普攻
TUNING.KING_SQUID_MELEE_PER_HIT_SLIDE = 4.2
TUNING.KING_SQUID_MELEE_HIT_SLIDE_TIME = 0.18
TUNING.KING_SQUID_MELEE_SLIDE_DECAY = 5
TUNING.KING_SQUID_MELEE_KNOCKBACK_DISTANCE = 4 -- 兼容旧引用
TUNING.KING_SQUID_MELEE_KNOCKBACK_STRENGTH = 1
TUNING.KING_SQUID_MELEE_LAUNCH_DISTANCE = 4 -- 第三击击飞水平距离（1 格地皮）
TUNING.KING_SQUID_MELEE_FINAL_LAUNCH_SCALE = 1
-- 攻击循环一轮：跳跃×2 → 双重喷墨 → 双重战吼
TUNING.KING_SQUID_LEAPS_PER_INK = 2
-- 喷墨：每波 8 发；一次技能连续两波
TUNING.KING_SQUID_INK_BURST_DELAY  = 0
TUNING.KING_SQUID_INK_BURST_WAVE_DELAY = 0.42
-- 喷墨落点：以目标前方为圆心均匀散布（随距离略扩大）
TUNING.KING_SQUID_INK_SPREAD_RADIUS = 2.6 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_INK_SPREAD_RADIUS_PER_DIST = 0.08 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_INK_SPREAD_RADIUS_MAX = 7 * KING_SQUID_STAT_SCALE
TUNING.KING_SQUID_INK_SPREAD_RING_MIN = 0.42 -- 圆环内径 = 半径 × 此值
TUNING.KING_SQUID_INK_SPREAD_RING_RAND = 0.36 -- 再加随机 × 此值（更密、少外圈空档）
TUNING.KING_SQUID_INK_SPREAD_FORWARD_BIAS = 0.35
TUNING.KING_SQUID_INK_SPREAD_FORWARD_BIAS_MAX = 10
-- 仅用于弹速插值分母；与 INK_CAST_RANGE 对齐，远距离也能打满速
TUNING.KING_SQUID_INK_PROJECTILE_SPEED_RANGE = 30 * KING_SQUID_SIZE_MULT
-- 水中喷墨概率（含跨介质：水中鱿王 vs 岸上目标）
TUNING.KING_SQUID_WATER_INK_CHANCE = 0.42
-- 每次跳跃攻击结束后慌乱躲闪（秒，由大脑 Wander/RunAway 驱动）
TUNING.KING_SQUID_POST_ATTACK_RETREAT_TIME = 2.6
-- 逃离阈值
TUNING.KING_SQUID_RETREAT_DAMAGE   = 350
TUNING.KING_SQUID_RETREAT_SPEED    = 14
TUNING.KING_SQUID_RETREAT_TIME     = 0.58
TUNING.KING_SQUID_RETREAT_CHAIN_DELAY = 0.15 

TUNING.KING_SQUID_LOOT = {
	{ "monstermeat", 1.00 },
	{ "lightbulb",   1.00 },
}
-- 绝望小石：最多 5 个，首判 80%，之后每次降 15%（65% / 50% / 35% / 20%）
TUNING.KING_SQUID_DREADSTONE_LOOT_CHANCES = { 0.8, 0.65, 0.50, 0.35, 0.20 }
----------------------------------------------------------------------

local KING_SQUID_TILE_SIZE = 4

-- 大脑索敌/后撤常量（须在引用它们的函数之前声明）
local KING_SQUID_COOLDOWN_RUNAWAY_START = 7
local KING_SQUID_COOLDOWN_RUNAWAY_STOP = 13
local KING_SQUID_POST_ATTACK_RUNAWAY_START = 6
local KING_SQUID_POST_ATTACK_RUNAWAY_STOP = 12
local KING_SQUID_NEARBY_AVOID_RADIUS = 14 * KING_SQUID_STAT_SCALE
local KING_SQUID_NEARBY_AVOID_RUNAWAY_START = 5
local KING_SQUID_NEARBY_AVOID_RUNAWAY_STOP = 16
local KING_SQUID_PANIC_RUNAWAY_START = 4
local KING_SQUID_PANIC_RUNAWAY_STOP = 14
local KING_SQUID_NEARBY_AVOID_MUST = { "_combat", "character" }
local KING_SQUID_NEARBY_AVOID_CANT = { "INLIMBO", "playerghost", "flight", "king_squid", "chess" }

local function KingSquidTilesToDist(tiles)
	return (tiles or 0) * KING_SQUID_TILE_SIZE
end

-- 跳跃/喷墨共用距离（世界单位，已含 KING_SQUID_SIZE_MULT）
local function KingSquidGetCombatApproachRange(_inst)
	return TUNING.KING_SQUID_COMBAT_RANGE or TUNING.KING_SQUID_INK_CAST_RANGE or (30 * KING_SQUID_SIZE_MULT)
end

local SCALE = TUNING.KING_SQUID_SCALE
local KING_SQUID_APPROACH_RANGE = KingSquidGetCombatApproachRange()
local ATTACK_RANGE = TUNING.KING_SQUID_ATTACK_RANGE * SCALE
local TARGET_KEEP = TUNING.KING_SQUID_TARGET_KEEP * SCALE

local function KingSquidApplyEyeGlowLight(inst)
	local glow = inst.eyeglow
	if glow == nil or not glow:IsValid() or glow.Light == nil then
		return
	end
	local sm = inst.king_squid_scale_mult or SCALE
	glow.Light:SetColour(
		TUNING.KING_SQUID_LIGHT_R or (72 / 255),
		TUNING.KING_SQUID_LIGHT_G or (16 / 255),
		TUNING.KING_SQUID_LIGHT_B or (98 / 255)
	)
	glow.Light:SetIntensity(TUNING.KING_SQUID_LIGHT_INTENSITY or 0.52)
	glow.Light:SetFalloff(TUNING.KING_SQUID_LIGHT_FALLOFF or 0.65)
	glow.Light:SetRadius((TUNING.KING_SQUID_LIGHT_RADIUS or 1.35) * sm)
	glow.Light:Enable(true)
end

require("behaviours/wander")
require("behaviours/chaseandattack")
require("behaviours/doaction")
require("behaviours/runaway")
require("behaviours/standstill")
require("stategraphs/commonstates")
local BrainCommon = require("brains/braincommon")

local BRAIN_MAX_CHASE_TIME = 14

local function KingSquidIsKing(inst)
	return inst ~= nil and inst.prefab == "king_squid"
end

-- Possession 2（workshop-3676492192）：被附身时 Poss2.Level > 0
local function KingSquidPossessedByPoss2(inst)
	if inst == nil or not inst:IsValid() or inst.Poss2 == nil then
		return false
	end
	return (inst.Poss2.Level or 0) > 0
end

-- Poss2 附身或实体带 playercontroller：视为玩家操控
local function KingSquidIsPlayerControlled(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if KingSquidPossessedByPoss2(inst) then
		return true
	end
	local p2 = inst.Poss2
	if p2 ~= nil and p2.Possessors ~= nil then
		for _ in pairs(p2.Possessors) do
			return true
		end
	end
	if inst.components.playercontroller ~= nil then
		return true
	end
	return false
end

-- 静止判定：位移超过约 0.25m 则视为在动，重置「开始静止」时间
local KING_SQUID_STILL_MOVE_THRESH_SQ = 0.25 * 0.25

local function KingSquidUpdateStillness(inst)
	if inst == nil or not inst:IsValid() or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	local x, _, z = inst.Transform:GetWorldPosition()
	local ox, oz = inst._king_squid_track_x, inst._king_squid_track_z
	if ox == nil then
		inst._king_squid_track_x = x
		inst._king_squid_track_z = z
		inst._king_squid_still_since = GetTime()
		return
	end
	local dx, dz = x - ox, z - oz
	if dx * dx + dz * dz > KING_SQUID_STILL_MOVE_THRESH_SQ then
		inst._king_squid_track_x = x
		inst._king_squid_track_z = z
		inst._king_squid_still_since = GetTime()
	end
end

-- 入睡：仅当连续静止满 KING_SQUID_SLEEP_STILL_SEC，且无战斗目标、非恐慌/燃烧/冰冻、非 busy
local function KingSquidShouldSleep(inst)
	if KingSquidPossessedByPoss2(inst) then
		return false
	end
	if inst.components.combat ~= nil and inst.components.combat:HasTarget() then
		return false
	end
	if inst._king_squid_panic_until ~= nil and GetTime() < inst._king_squid_panic_until then
		return false
	end
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return false
	end
	if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
		return false
	end
	if inst.sg ~= nil and inst.sg:HasStateTag("busy") then
		return false
	end
	local need = TUNING.KING_SQUID_SLEEP_STILL_SEC or 5
	local since = inst._king_squid_still_since
	if since == nil or GetTime() - since < need then
		return false
	end
	return true
end

-- 苏醒：玩家进入较大范围、已有目标、燃烧/冰冻等
local function KingSquidShouldWake(inst)
	if KingSquidPossessedByPoss2(inst) then
		return true
	end
	if inst.components.combat ~= nil and inst.components.combat:HasTarget() then
		return true
	end
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return true
	end
	if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
		return true
	end
	if inst.components.health ~= nil and inst.components.health.takingfiredamage then
		return true
	end
	local r = (TUNING.KING_SQUID_WAKE_DETECT_RANGE or 48) * (inst.king_squid_scale_mult or 1)
	local p = FindClosestPlayerToInst(inst, r, true)
	if p ~= nil and p.entity:IsVisible() and p:HasTag("player") and not p:HasTag("playerghost") then
		if p.components.health == nil or not p.components.health:IsDead() then
			return true
		end
	end
	return false
end

local function KingSquidShouldStandStill(inst)
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		return false
	end
	if inst._king_squid_panic_until ~= nil and GetTime() < inst._king_squid_panic_until then
		return false
	end
	local c = inst.components.combat
	return c == nil or not c:HasTarget()
end

local KING_SQUID_RESPAWNER_PREFAB = "king_squid_ruinsrespawner_inst"
local KING_SQUID_LINK_RESPAWNER_RANGE_SQ = 100 * 100

-- OnSave/OnLoad 的 spawnlocation 常为纯表 {x,y,z}，无 :Get()；传入 BufferedAction 会触发 util DynamicPosition 崩溃
local function KingSquidEnsureVector3(pos)
	if pos == nil then
		return nil
	end
	if type(pos.Get) == "function" then
		return pos
	end
	if pos.x ~= nil then
		return Vector3(pos.x, pos.y or 0, pos.z or 0)
	end
	return nil
end

local function KingSquidGetNestPos(inst)
	if inst.spawnlocation ~= nil then
		return KingSquidEnsureVector3(inst.spawnlocation)
	end
	if inst.components.knownlocations ~= nil then
		local pos = inst.components.knownlocations:GetLocation("king_squid_spawn")
		if pos ~= nil then
			return KingSquidEnsureVector3(pos)
		end
		return KingSquidEnsureVector3(inst.components.knownlocations:GetLocation("home"))
	end
	return nil
end

local function KingSquidRememberNest(inst, pos)
	pos = KingSquidEnsureVector3(pos)
	if pos == nil then
		return
	end
	inst.spawnlocation = pos
	if inst.components.knownlocations ~= nil then
		inst.components.knownlocations:RememberLocation("king_squid_spawn", pos)
		inst.components.knownlocations:RememberLocation("home", pos, true)
	end
end

local function KingSquidFindNestFromRespawner(inst)
	local best, bestd
	for _, v in pairs(Ents) do
		if v.prefab == KING_SQUID_RESPAWNER_PREFAB and v:IsValid() then
			local d = inst:GetDistanceSqToInst(v)
			if bestd == nil or d < bestd then
				best = v
				bestd = d
			end
		end
	end
	if best ~= nil and bestd ~= nil and bestd <= KING_SQUID_LINK_RESPAWNER_RANGE_SQ then
		return Vector3(best.Transform:GetWorldPosition())
	end
	return nil
end

local function GetSpawnPos(inst)
	return KingSquidGetNestPos(inst)
end

local function GetLeashRadius(inst)
	return (TUNING.KING_SQUID_SPAWN_LEASH or 32) * (inst.king_squid_scale_mult or 1)
end

local function GetWanderRadius(inst)
	return (TUNING.KING_SQUID_WANDER_RADIUS or 10) * (inst.king_squid_scale_mult or 1)
end

-- 巡逻中心：水中用出生点；在陆地且出生点在海上时，改找陆地上的可走点，避免 GoToPoint 进海导致单向狂奔
local function GetPatrolHome(inst)
	local home = GetSpawnPos(inst)
	if home == nil then
		return nil
	end
	if inst:HasTag("swimming") then
		return home
	end
	local px, py, pz = inst.Transform:GetWorldPosition()
	if not TheWorld.Map:IsOceanAtPoint(home.x, 0, home.z) then
		return home
	end
	local angle = inst:GetAngleToPoint(home.x, 0, home.z) * DEGREES
	local offset = FindWalkableOffset(Vector3(px, py, pz), angle, 4, 8, false, false, nil, false)
	if offset ~= nil then
		return Vector3(px, py, pz) + offset
	end
	return Vector3(px, py, pz)
end

local function KingSquidGetNestLeashSq(inst)
	local r = GetLeashRadius(inst)
	return r * r
end

local function KingSquidGetGoHomeArriveDistSq(inst)
	local d = (TUNING.KING_SQUID_GO_HOME_DIST or 3) * (inst.king_squid_scale_mult or 1)
	return d * d
end

local function KingSquidHasNoCombatTarget(inst)
	local c = inst.components.combat
	return c == nil or not c:HasTarget()
end

local function KingSquidShouldGoHome(inst)
	if not KingSquidHasNoCombatTarget(inst) then
		return false
	end
	if inst._king_squid_panic_until ~= nil and GetTime() < inst._king_squid_panic_until then
		return false
	end
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		return false
	end
	if inst.sg ~= nil and (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("jumping")) then
		return false
	end
	local nest = KingSquidGetNestPos(inst)
	if nest == nil then
		return false
	end
	-- 仿发条主教：不在巢穴/spawner 旁就持续走回（非“超出拴绳半径才回”）
	return inst:GetDistanceSqToPoint(nest.x, nest.y, nest.z) > KingSquidGetGoHomeArriveDistSq(inst)
end

local function KingSquidGoHomeAction(inst)
	if not KingSquidHasNoCombatTarget(inst) then
		return nil
	end
	local dest = KingSquidEnsureVector3(GetPatrolHome(inst))
	if dest == nil then
		return nil
	end
	return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, dest, nil, 0.2)
end

-- 逃离后游荡：以落点为「家」，小半径随机走（Wander 的 home / leash）
local function GetRetreatWanderHome(inst)
	local a = inst._king_squid_retreat_anchor
	if a ~= nil then
		return a
	end
	return GetPatrolHome(inst)
end

local function GetRetreatWanderLeash(inst)
	if inst._king_squid_retreat_anchor ~= nil then
		return (TUNING.KING_SQUID_POST_RETREAT_WANDER_RADIUS or 5) * (inst.king_squid_scale_mult or 1)
	end
	return GetLeashRadius(inst)
end

-- 累计受伤撤退恐慌：优先远离的对象（落地后仍可用 combat.target 兜底）
local function KingSquidGetRetreatThreat(inst)
	local t = inst._king_squid_retreat_threat
	if t ~= nil and t:IsValid() then
		return t
	end
	if inst.components.combat ~= nil then
		t = inst.components.combat.target
		if t ~= nil and t:IsValid() then
			return t
		end
	end
	return nil
end

local function KingSquidIsNearbyAvoidEntity(inst, ent)
	if ent == nil or ent == inst or not ent:IsValid() then
		return false
	end
	if ent:HasTag("playerghost") or ent:HasTag("chess") then
		return false
	end
	if ent.components.health ~= nil and ent.components.health:IsDead() then
		return false
	end
	if ent.components.combat ~= nil and ent.components.combat.target == inst then
		return true
	end
	if ent:HasTag("player") or ent:HasTag("hostile") or ent:HasTag("monster") then
		return true
	end
	return false
end

-- 逃离落地后：优先远离最近的附近敌对单位，否则仍远离原威胁
local function KingSquidGetNearbyAvoidThreat(inst)
	local sm = inst.king_squid_scale_mult or SCALE
	local radius = KING_SQUID_NEARBY_AVOID_RADIUS * sm
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, radius, KING_SQUID_NEARBY_AVOID_MUST, KING_SQUID_NEARBY_AVOID_CANT)
	local best, bestd
	for _, ent in ipairs(ents) do
		if KingSquidIsNearbyAvoidEntity(inst, ent) then
			local d = inst:GetDistanceSqToInst(ent)
			if bestd == nil or d < bestd then
				best = ent
				bestd = d
			end
		end
	end
	if best ~= nil then
		return best
	end
	return KingSquidGetRetreatThreat(inst)
end

local function KingSquidGetPostAttackThreat(inst)
	local t = inst._king_squid_post_attack_threat
	if t ~= nil and t:IsValid() then
		return t
	end
	if inst.components.combat ~= nil then
		t = inst.components.combat.target
		if t ~= nil and t:IsValid() then
			return t
		end
	end
	return nil
end

local function KingSquidBeginPostAttackRetreat(inst)
	local t = KingSquidGetPostAttackThreat(inst)
	if t == nil then
		return
	end
	inst._king_squid_post_attack_threat = t
	local x, y, z = inst.Transform:GetWorldPosition()
	inst._king_squid_post_attack_anchor = Vector3(x, y, z)
	local dur = TUNING.KING_SQUID_POST_ATTACK_RETREAT_TIME or 2.6
	inst._king_squid_post_attack_until = GetTime() + dur
	if inst._king_squid_post_attack_clear_task ~= nil then
		inst._king_squid_post_attack_clear_task:Cancel()
	end
	inst._king_squid_post_attack_clear_task = inst:DoTaskInTime(dur, function(i)
		if not i:IsValid() then
			return
		end
		i._king_squid_post_attack_clear_task = nil
		i._king_squid_post_attack_until = nil
		i._king_squid_post_attack_threat = nil
		i._king_squid_post_attack_anchor = nil
	end)
end

local function SetKingSquidPathcaps(inst)
	if inst.components.locomotor == nil then
		return
	end
	-- 两栖寻路：始终允许经过海洋（同原版 squid），便于绕水路索敌
	inst.components.locomotor.pathcaps = { allowocean = true }
end

local function KingSquidSegmentCrossesOcean(x1, z1, x2, z2, samples)
	samples = samples or 8
	if samples < 2 then
		samples = 2
	end
	for i = 1, samples - 1 do
		local t = i / samples
		local x = x1 + (x2 - x1) * t
		local z = z1 + (z2 - z1) * t
		if TheWorld.Map:IsOceanAtPoint(x, 0, z) then
			return true
		end
	end
	return false
end

local function KingSquidIsCrossMediumCombat(inst, target)
	if inst == nil or target == nil or not target:IsValid() then
		return false
	end
	local sx, sy, sz = inst.Transform:GetWorldPosition()
	local tx, ty, tz = target.Transform:GetWorldPosition()
	local squid_on_water = inst:HasTag("swimming") or TheWorld.Map:IsOceanAtPoint(sx, sy, sz)
	local target_on_land = not TheWorld.Map:IsOceanAtPoint(tx, ty, tz)
	return squid_on_water and target_on_land
end

local function KingSquidDistToTarget(inst, target)
	if target == nil or not target:IsValid() then
		return math.huge
	end
	local sx, _, sz = inst.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - sx, tz - sz
	return math.sqrt(dx * dx + dz * dz)
end

local function KingSquidGetInkCastRange(_inst)
	return TUNING.KING_SQUID_INK_CAST_RANGE or KingSquidGetCombatApproachRange()
end

local function KingSquidCanStartRangedAttack(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if inst.components.health == nil or inst.components.health:IsDead() then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("busy")
		and not (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) then
		return false
	end
	return true
end

-- 需经水域才能接近：水中→陆地、陆地↔隔岸陆地等
local function KingSquidNeedsCrossWaterApproach(inst, target)
	if inst == nil or target == nil or not target:IsValid() then
		return false
	end
	if KingSquidIsCrossMediumCombat(inst, target) then
		return true
	end
	local sx, sy, sz = inst.Transform:GetWorldPosition()
	local tx, ty, tz = target.Transform:GetWorldPosition()
	if not KingSquidSegmentCrossesOcean(sx, sz, tx, tz) then
		return false
	end
	local inst_on_ocean = inst:HasTag("swimming") or TheWorld.Map:IsOceanAtPoint(sx, sy, sz)
	local tgt_on_ocean = TheWorld.Map:IsOceanAtPoint(tx, ty, tz)
	return not (inst_on_ocean and tgt_on_ocean)
end

local function KingSquidIsInWaterCombat(inst)
	return inst:HasTag("swimming") or inst:IsOnOcean()
end

local function KingSquidCanInkAtTarget(inst, target)
	if inst == nil or target == nil or not target:IsValid() then
		return false
	end
	local dist = KingSquidDistToTarget(inst, target)
	local max_r = KingSquidGetInkCastRange(inst)
	return dist <= max_r
end

local function KingSquidResetAttackCycle(inst)
	inst._king_squid_leaps_since_ink = 0
	inst._king_squid_last_attack_kind = "leap"
end

-- 攻击一旦开始即计入 2跳→喷墨→战吼 进度（附身解除/被打断也不回退）
local function KingSquidCommitLeapAttackCycle(inst)
	if not KingSquidIsKing(inst) then
		return
	end
	inst._king_squid_leaps_since_ink = (inst._king_squid_leaps_since_ink or 0) + 1
	inst._king_squid_last_attack_kind = "leap"
end

local function KingSquidCommitInkAttackCycle(inst)
	if not KingSquidIsKing(inst) then
		return
	end
	inst._king_squid_leaps_since_ink = 0
	inst._king_squid_last_attack_kind = "ink"
	-- 水中开场喷墨不计入循环；其余喷墨结束后必须双重战吼
	if not (KingSquidIsInWaterCombat(inst) and not inst._king_squid_water_opening_ink_done) then
		inst._king_squid_pending_double_taunt = true
	end
end

local function KingSquidNeedsDoubleTaunt(inst)
	return inst._king_squid_pending_double_taunt == true
end

local function KingSquidClearPendingDoubleTaunt(inst)
	inst._king_squid_pending_double_taunt = nil
end

-- 附身解除 / 被操控时喷墨可能被打断，恢复时优先补完双重战吼
local function KingSquidTryEnterPendingDoubleTaunt(inst)
	if not KingSquidIsKing(inst) or not KingSquidNeedsDoubleTaunt(inst) then
		return false
	end
	if inst.sg == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return false
	end
	if inst.sg.currentstate ~= nil and inst.sg.currentstate.name == "king_squid_double_taunt" then
		return true
	end
	if inst.sg:HasStateTag("busy") then
		return false
	end
	inst.sg:GoToState("king_squid_double_taunt")
	return true
end

local function KingSquidSchedulePendingDoubleTaunt(inst)
	if not KingSquidNeedsDoubleTaunt(inst) then
		return
	end
	inst:DoTaskInTime(0, function(i)
		if i:IsValid() then
			KingSquidTryEnterPendingDoubleTaunt(i)
		end
	end)
end

local function KingSquidClearWaterOpeningInkIfLeftWater(inst)
	if not KingSquidIsInWaterCombat(inst) then
		inst._king_squid_water_opening_ink_done = nil
	end
end

-- 水中作战：本轮先喷墨一次，再进入 2 跳 → 喷墨 → 双重战吼 循环
local function KingSquidWantsWaterOpeningInk(inst)
	if not KingSquidIsInWaterCombat(inst) then
		return false
	end
	return not inst._king_squid_water_opening_ink_done
end

local function KingSquidBeginWaterOpeningInk(inst)
	inst._king_squid_water_opening_ink_done = false
end

-- 每累计 2 次跳跃接近后才允许双重喷墨（水中且未做过开场喷墨时优先喷墨）
local function KingSquidShouldPreferInk(inst)
	if KingSquidNeedsDoubleTaunt(inst) then
		return false
	end
	KingSquidClearWaterOpeningInkIfLeftWater(inst)
	local c = inst.components.combat
	if c == nil or c.target == nil then
		return false
	end
	if inst.components.timer ~= nil and inst.components.timer:TimerExists("ink_cooldown") then
		return false
	end
	if not KingSquidCanInkAtTarget(inst, c.target) then
		return false
	end
	if KingSquidIsCrossMediumCombat(inst, c.target) and not KingSquidIsInWaterCombat(inst) then
		return false
	end
	if KingSquidWantsWaterOpeningInk(inst) then
		return true
	end
	local need = TUNING.KING_SQUID_LEAPS_PER_INK or 2
	return (inst._king_squid_leaps_since_ink or 0) >= need
end

local function KingSquidTryInkAtRange(inst)
	if not KingSquidShouldPreferInk(inst) then
		return
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target == nil or not target:IsValid() then
		return
	end
	if not KingSquidCanInkAtTarget(inst, target) then
		return
	end
	if not KingSquidCanStartRangedAttack(inst) then
		return
	end
	inst.sg:GoToState("king_squid_double_shoot", target)
end

local function KingSquidResolveCombatTarget(inst, target)
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

-- 喷墨优先于跳跃（水中开场喷墨 / 累计 2 跳后的喷墨）
local function KingSquidTryInkBeforeLeap(inst, target)
	if KingSquidTryEnterPendingDoubleTaunt(inst) then
		return true
	end
	if not KingSquidShouldPreferInk(inst) then
		return false
	end
	target = KingSquidResolveCombatTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if not KingSquidCanInkAtTarget(inst, target) or not KingSquidCanStartRangedAttack(inst) then
		return false
	end
	inst.sg:GoToState("king_squid_double_shoot", target)
	return true
end

local function shouldink(inst)
	if not KingSquidShouldPreferInk(inst) then
		return nil
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target == nil or not target:IsValid() then
		return nil
	end
	return BufferedAction(inst, target, ACTIONS.TOSS)
end

-- 在岸上时：沿目标方向找首个海洋格子，作为「先入水再索敌」的寻路落点
local function KingSquidGetWaterEntryDest(inst, target)
	if inst == nil or target == nil or not target:IsValid() then
		return nil
	end
	if inst:HasTag("swimming") then
		return nil
	end
	local sx, sy, sz = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsOceanAtPoint(sx, sy, sz) then
		return nil
	end
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - sx, tz - sz
	local len = math.sqrt(dx * dx + dz * dz)
	if len < 0.01 then
		return nil
	end
	dx, dz = dx / len, dz / len
	local step = 2
	local max_steps = math.ceil(math.min(len, 28) / step)
	for i = 1, max_steps do
		local px, pz = sx + dx * step * i, sz + dz * step * i
		if TheWorld.Map:IsOceanAtPoint(px, 0, pz) then
			return Vector3(px, sy, pz)
		end
	end
	return nil
end

local function KingSquidCrossWaterChaseAction(inst)
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target == nil or not target:IsValid() then
		return nil
	end
	if inst.sg ~= nil and (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("jumping")) then
		return nil
	end
	if not KingSquidNeedsCrossWaterApproach(inst, target) then
		return nil
	end
	local dest = KingSquidGetWaterEntryDest(inst, target)
	if dest == nil then
		return nil
	end
	return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, dest, nil, 0.2)
end

local WANDER_TIMES = { minwalktime = 1, randwalktime = 0.6, minwaittime = 1.5, randwaittime = 2 }

-- Wander 的 checkpointFn 只传入落脚点 Vector3(pt)，需闭包捕获 inst
local function MakeKingSquidWanderCheckpoint(inst)
	return function(pt)
		if inst ~= nil and inst:IsValid() and inst:HasTag("swimming") then
			return true
		end
		if pt == nil then
			return false
		end
		return not TheWorld.Map:IsOceanAtPoint(pt.x, 0, pt.z)
	end
end

local WANDER_DATA = {
	wander_dist = function(inst)
		return GetWanderRadius(inst)
	end,
	should_run = function(inst)
		return inst:HasTag("swimming")
	end,
}

local KingSquidBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function KingSquidBrain:OnStart()
	local inst = self.inst
	local chase_give_up = GetLeashRadius(inst)

	local PANIC_WANDER_TIMES = {
		minwalktime = 0.35,
		randwalktime = 1.2,
		minwaittime = 0,
		randwaittime = 0.35,
	}
	local panic_r = TUNING.KING_SQUID_POST_RETREAT_WANDER_RADIUS or 5
	local post_attack_r = panic_r
	local POST_ATTACK_WANDER_TIMES = {
		minwalktime = 0.35,
		randwalktime = 1.1,
		minwaittime = 0,
		randwaittime = 0.35,
	}
	local POST_ATTACK_WANDER_DATA = {
		wander_dist = function(i)
			local sm = i.king_squid_scale_mult or 1
			local w = post_attack_r * sm * (0.35 + math.random() * 0.55)
			return math.max(2, math.min(w, post_attack_r * sm * 1.1))
		end,
		should_run = function(i)
			return i:HasTag("swimming")
		end,
	}
	local PANIC_WANDER_DATA = {
		wander_dist = function(i)
			if i._king_squid_retreat_anchor ~= nil then
				local w = panic_r * (0.25 + math.random() * 0.35)
				local wlo, whi = 1.5, panic_r * 0.85
				if w < wlo then
					w = wlo
				elseif w > whi then
					w = whi
				end
				return w
			end
			return math.max(GetWanderRadius(i) * 2, 8)
		end,
		should_run = function(i)
			-- 恐慌落地阶段也快跑乱走
			return i._king_squid_retreat_anchor ~= nil or i:HasTag("swimming")
		end,
	}

	local root = PriorityNode({
		WhileNode(function()
			return not self.inst.sg:HasStateTag("jumping")
		end, "NotJumping", PriorityNode({
			BrainCommon.PanicTrigger(self.inst),
			BrainCommon.ElectricFencePanicTrigger(self.inst),

			WhileNode(function()
				local t = GetTime()
				local pu = self.inst._king_squid_panic_until
				return pu ~= nil and t < pu
			end, "PostRetreatPanic", PriorityNode({
				WhileNode(function()
					local thr = KingSquidGetNearbyAvoidThreat(self.inst)
					return thr ~= nil and self.inst:IsNear(thr, KING_SQUID_NEARBY_AVOID_RADIUS + 4)
				end, "PanicAvoidNearby", RunAway(
					self.inst,
					{ getfn = KingSquidGetNearbyAvoidThreat },
					KING_SQUID_NEARBY_AVOID_RUNAWAY_START,
					KING_SQUID_NEARBY_AVOID_RUNAWAY_STOP
				)),
				WhileNode(function()
					local thr = KingSquidGetRetreatThreat(self.inst)
					return thr ~= nil and self.inst:IsNear(thr, 30)
				end, "PanicRunAway", RunAway(
					self.inst,
					{ getfn = KingSquidGetRetreatThreat },
					KING_SQUID_PANIC_RUNAWAY_START,
					KING_SQUID_PANIC_RUNAWAY_STOP
				)),
				Wander(
					self.inst,
					GetRetreatWanderHome,
					GetRetreatWanderLeash,
					PANIC_WANDER_TIMES,
					nil,
					nil,
					MakeKingSquidWanderCheckpoint(self.inst),
					PANIC_WANDER_DATA
				),
			}, 0.25)),

			WhileNode(function()
				local until_t = self.inst._king_squid_post_attack_until
				return until_t ~= nil and GetTime() < until_t
			end, "PostAttackPanic", PriorityNode({
				WhileNode(function()
					local thr = KingSquidGetPostAttackThreat(self.inst)
					return thr ~= nil and self.inst:IsNear(thr, KING_SQUID_POST_ATTACK_RUNAWAY_STOP)
				end, "PostAttackRunAway", RunAway(
					self.inst,
					{ getfn = KingSquidGetPostAttackThreat },
					KING_SQUID_POST_ATTACK_RUNAWAY_START,
					KING_SQUID_POST_ATTACK_RUNAWAY_STOP
				)),
				Wander(
					self.inst,
					function(i)
						return i._king_squid_post_attack_anchor or GetPatrolHome(i)
					end,
					function(i)
						return post_attack_r * (i.king_squid_scale_mult or 1)
					end,
					POST_ATTACK_WANDER_TIMES,
					nil,
					nil,
					MakeKingSquidWanderCheckpoint(self.inst),
					POST_ATTACK_WANDER_DATA
				),
			}, 0.25)),

			-- 无目标：优先走回 spawner/巢穴（须在 AttackMomentarily 之前，否则 ChaseAndAttack 会抢先索敌）
			WhileNode(function()
				return KingSquidShouldGoHome(self.inst)
			end, "GoHome", DoAction(self.inst, KingSquidGoHomeAction, "Go Home", true)),

			-- 有目标且不在攻击冷却 → 追击/喷墨（双重战吼 busy 期间不追击）
			WhileNode(function()
				local pu = self.inst._king_squid_panic_until
				if pu ~= nil and GetTime() < pu then
					return false
				end
				local pa = self.inst._king_squid_post_attack_until
				if pa ~= nil and GetTime() < pa then
					return false
				end
				local i = self.inst
				if i.sg ~= nil and i.sg:HasStateTag("busy") then
					return false
				end
				local c = i.components.combat
				return c ~= nil and c:HasTarget() and not c:InCooldown()
			end, "AttackMomentarily", PriorityNode({
				DoAction(self.inst, KingSquidCrossWaterChaseAction, "CrossWaterChase", true),
				WhileNode(function()
					return KingSquidShouldPreferInk(self.inst)
				end, "InkAtRange", ActionNode(function()
					KingSquidTryInkAtRange(self.inst)
				end)),
				ChaseAndAttack(self.inst, BRAIN_MAX_CHASE_TIME, chase_give_up, nil, RetargetPlayer),
			}, 0.25)),

			WhileNode(function()
				local pu = self.inst._king_squid_panic_until
				if pu ~= nil and GetTime() < pu then
					return false
				end
				local c = self.inst.components.combat
				return c ~= nil and c:HasTarget()
			end, "AttackCooldownDodge", RunAway(
				self.inst,
				{ getfn = function(inst)
					return inst.components.combat ~= nil and inst.components.combat.target or nil
				end },
				KING_SQUID_COOLDOWN_RUNAWAY_START,
				KING_SQUID_COOLDOWN_RUNAWAY_STOP
			)),

			-- 无目标且已在巢穴旁：原地不动（静止满 KING_SQUID_SLEEP_STILL_SEC 后由 sleeper 入睡）
			WhileNode(function()
				return KingSquidShouldStandStill(self.inst)
			end, "NoTargetStandStill", StandStill(self.inst)),
		}, 0.25)),
	}, 0.25)

	self.bt = BT(self.inst, root)
end

local assets = {
	Asset("ANIM", "anim/squid.zip"),
	Asset("ANIM", "anim/squid_water.zip"),
	Asset("ANIM", "anim/squid_build.zip"),
}

local prefabs = {
	"lightbulb", "wake_small", "squideyelight", "inksplat",
	"squid_ink_player_fx", "monstermeat", "slingshotammo_dreadstone",
}

local sounds = {
	attack = "hookline/creatures/squid/attack",
	bite = "hookline/creatures/squid/gobble",
	taunt = "hookline/creatures/squid/taunt",
	death = "hookline/creatures/squid/death",
	sleep = "hookline/creatures/squid/sleep",
	hurt = "hookline/creatures/squid/hit",
	spit = "hookline/creatures/squid/spit",
	swim = "turnoftides/common/together/water/swim/medium",
}

SetSharedLootTable("king_squid", TUNING.KING_SQUID_LOOT)

local function KingSquidLootSetupFn(lootdropper)
	for _, chance in ipairs(TUNING.KING_SQUID_DREADSTONE_LOOT_CHANCES) do
		lootdropper:AddChanceLoot("slingshotammo_dreadstone", chance)
	end
end

local INK_HIT_MUST_TAGS = { "_combat", "player" }
local INK_HIT_CANT_TAGS = { "INLIMBO", "playerghost", "flight" }

local function KingSquidInkApplyToPlayer(ent)
	if ent == nil or not ent:IsValid() or ent.components.inkable == nil then
		return
	end
	ent.components.inkable:Ink()
end

-- 范围伤害 + 视野遮挡：原版 OnHitInk 仅对碰撞实体 Ink，墨弹打地时常常只有伤害
local function KingSquidInkHitPlayers(projectile, attacker, direct_target)
	if projectile == nil or not projectile:IsValid() then
		return
	end
	if attacker == nil or not attacker:IsValid() then
		return
	end
	local x, y, z = projectile.Transform:GetWorldPosition()
	local sm = attacker.king_squid_scale_mult or SCALE
	local radius = (TUNING.KING_SQUID_INK_HIT_RADIUS or 1) * sm
	local phys = TUNING.KING_SQUID_INK_PHYSICAL_DAMAGE or 0
	local planar = TUNING.KING_SQUID_INK_PLANAR_DAMAGE or 0
	local spdmg = planar > 0 and { planar = planar } or nil
	local inked = {}
	for _, ent in ipairs(TheSim:FindEntities(x, y, z, radius, INK_HIT_MUST_TAGS, INK_HIT_CANT_TAGS)) do
		if ent.components.health ~= nil and not ent.components.health:IsDead() then
			KingSquidInkApplyToPlayer(ent)
			inked[ent] = true
			if phys > 0 or planar > 0 then
				if ent.components.combat ~= nil then
					ent.components.combat:GetAttacked(attacker, phys, nil, nil, spdmg)
				end
			end
		end
	end
	if direct_target ~= nil and direct_target:IsValid() and not inked[direct_target] then
		KingSquidInkApplyToPlayer(direct_target)
	end
end

local function LaunchProjectile(inst, targetpos)
	local x, y, z = inst.Transform:GetWorldPosition()
	local projectile = SpawnPrefab("inksplat")
	if projectile == nil then
		return
	end
	projectile.Transform:SetPosition(x, y, z)
	local dx, dz = targetpos.x - x, targetpos.z - z
	local dist = math.sqrt(dx * dx + dz * dz)
	local rangesq = dist * dist
	local maxrange = TUNING.KING_SQUID_INK_PROJECTILE_SPEED_RANGE
		or KingSquidGetInkCastRange(inst)
		or TUNING.KING_SQUID_INK_CAST_RANGE
		or 30
	local cp = projectile.components.complexprojectile
	if cp == nil then
		return
	end
	cp.usehigharc = false
	cp:SetGravity(TUNING.KING_SQUID_INK_GRAVITY or -25)
	local sm = inst.king_squid_scale_mult or SCALE
	local launch_y = 2.5 * sm
	cp:SetLaunchOffset(Vector3(0, launch_y, 0))
	-- 近快远慢（帝王蟹风格），但远距离不得低于低弧度能命中的最低弹速
	local speed = easing.linear(
		rangesq,
		TUNING.KING_SQUID_INK_SPEED_NEAR or 15,
		TUNING.KING_SQUID_INK_SPEED_FAR or 6,
		maxrange * maxrange
	)
	if dist > 0.01 then
		local min_speed = cp:CalculateMinimumSpeedForDistance(dist)
		if min_speed ~= nil and min_speed > speed then
			speed = min_speed
		end
	end
	cp:SetHorizontalSpeed(speed)
	local squid = inst
	local old_onhit = cp.onhitfn
	cp:SetOnHit(function(proj, attacker, target)
		KingSquidInkHitPlayers(proj, squid, target)
		if old_onhit ~= nil then
			old_onhit(proj, attacker, target)
		end
	end)
	cp:Launch(targetpos, inst, inst)
end

local function KeepTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target:HasTag("playerghost") then
		return false
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return false
	end
	if not inst:IsNear(target, TARGET_KEEP) then
		return false
	end
	local nest = KingSquidGetNestPos(inst)
	if nest ~= nil then
		local leash_sq = KingSquidGetNestLeashSq(inst)
		if inst:GetDistanceSqToPoint(nest.x, nest.y, nest.z) >= leash_sq then
			return false
		end
		if target:GetDistanceSqToPoint(nest.x, nest.y, nest.z) >= leash_sq then
			return false
		end
	end
	return inst.components.combat:CanTarget(target)
end

local function RetargetPlayer(inst)
	if inst.components.combat == nil then
		return nil
	end
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		return nil
	end
	local detect = KingSquidTilesToDist(TUNING.KING_SQUID_PLAYER_DETECT_TILES or 6)
	local p = FindClosestPlayerToInst(inst, detect, true)
	if p == nil or not p.entity:IsVisible() then
		return nil
	end
	if p:HasTag("playerghost") or not p:HasTag("player") then
		return nil
	end
	if p.components.health ~= nil and p.components.health:IsDead() then
		return nil
	end
	if not inst.components.combat:CanTarget(p) then
		return nil
	end
	local nest = KingSquidGetNestPos(inst)
	if nest ~= nil and p:GetDistanceSqToPoint(nest.x, nest.y, nest.z) >= KingSquidGetNestLeashSq(inst) then
		return nil
	end
	return p
end

local KING_SQUID_RETARGET_PLAYER_MUST = { "_combat", "player" }
local KING_SQUID_RETARGET_PLAYER_CANT = { "INLIMBO", "playerghost", "flight" }

local function KingSquidIsValidPlayerTarget(inst, ent, leash_sq, nest)
	if ent == nil or not ent:IsValid() or inst.components.combat == nil then
		return false
	end
	if not ent.entity:IsVisible() or not ent:HasTag("player") or ent:HasTag("playerghost") then
		return false
	end
	if ent.components.health ~= nil and ent.components.health:IsDead() then
		return false
	end
	if not inst.components.combat:CanTarget(ent) then
		return false
	end
	if nest ~= nil and leash_sq ~= nil and ent:GetDistanceSqToPoint(nest.x, nest.y, nest.z) >= leash_sq then
		return false
	end
	return true
end

-- 双重战吼结束后：优先换一个新玩家目标，否则保留最近的有效目标
local function KingSquidTryPickNewTargetAfterDoubleTaunt(inst)
	if inst.prefab ~= "king_squid" or inst.components.combat == nil then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	if inst._king_squid_panic_until ~= nil and GetTime() < inst._king_squid_panic_until then
		return
	end
	local combat = inst.components.combat
	local old = combat.target
	local detect = KingSquidTilesToDist(TUNING.KING_SQUID_PLAYER_DETECT_TILES or 6)
	local ix, iy, iz = inst.Transform:GetWorldPosition()
	local nest = KingSquidGetNestPos(inst)
	local leash_sq = nest ~= nil and KingSquidGetNestLeashSq(inst) or nil
	local ents = TheSim:FindEntities(ix, iy, iz, detect, KING_SQUID_RETARGET_PLAYER_MUST, KING_SQUID_RETARGET_PLAYER_CANT)
	local best_any, best_any_d
	local best_new, best_new_d
	for _, ent in ipairs(ents) do
		if KingSquidIsValidPlayerTarget(inst, ent, leash_sq, nest) then
			local d = inst:GetDistanceSqToInst(ent)
			if best_any_d == nil or d < best_any_d then
				best_any = ent
				best_any_d = d
			end
			if ent ~= old and (best_new_d == nil or d < best_new_d) then
				best_new = ent
				best_new_d = d
			end
		end
	end
	local pick = best_new or best_any
	if pick == nil then
		combat:SetTarget(nil)
		return
	end
	if pick ~= old then
		inst._king_squid_engagement_taunt_target = nil
		inst._king_squid_skip_engagement_taunt = true
	end
	combat:SetTarget(pick)
end

-- 无目标时主动索敌玩家（已在巢穴旁才索敌，避免打断归巢）
local function KingSquidTryAcquirePlayerTarget(inst)
	if inst.components.combat == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		return
	end
	if inst._king_squid_panic_until ~= nil and GetTime() < inst._king_squid_panic_until then
		return
	end
	if KingSquidShouldGoHome(inst) then
		return
	end
	if inst.components.combat.target ~= nil then
		return
	end
	if inst.sg ~= nil and inst.sg:HasStateTag("jumping") then
		return
	end
	local p = RetargetPlayer(inst)
	if p ~= nil then
		inst.components.combat:SetTarget(p)
	end
end

local function OnAttacked(inst, data)
	if data.attacker ~= nil and data.attacker:IsValid() and data.attacker:HasTag("chess") then
		return
	end
	if data.attacker ~= nil and data.attacker:IsValid() then
		inst.components.combat:SetTarget(data.attacker)
	end
end

-- amount 与其它字段共存时只看 amount（避免又把 percent 加一遍）；无有效 amount 再用百分比估损
local function KingSquidDamageFromHealthDelta(inst, data)
	if data == nil then
		return 0
	end
	if type(data.amount) == "number" then
		if data.amount < 0 then
			return -data.amount
		end
		return 0
	end
	if data.oldpercent ~= nil and data.newpercent ~= nil and data.oldpercent > data.newpercent then
		local h = inst.components.health
		if h ~= nil then
			local maxh = h.GetMaxWithPenalty ~= nil and h:GetMaxWithPenalty() or h.maxhealth
			if maxh ~= nil and maxh > 0 then
				return (data.oldpercent - data.newpercent) * maxh
			end
		end
	end
	return 0
end

local function KingSquidRetreatThreatFromData(inst, data)
	if data ~= nil then
		local a = data.afflicter or data.attacker
		if a ~= nil and a:IsValid() then
			return a
		end
	end
	if inst.components.combat ~= nil then
		local t = inst.components.combat.target
		if t ~= nil and t:IsValid() then
			return t
		end
	end
	return nil
end

local function KingSquidRestorePhysics(inst)
	if inst.Physics ~= nil then
		inst.Physics:SetCollisionMask(
			COLLISION.WORLD,
			COLLISION.OBSTACLES,
			COLLISION.SMALLOBSTACLES,
			COLLISION.CHARACTERS,
			COLLISION.GIANTS
		)
	end
end

local function KingSquidIsElectricHit(data)
	if data == nil then
		return false
	end
	if data.stimuli == "electric" then
		return true
	end
	local w = data.weapon
	if w ~= nil and w:IsValid() and w.components.weapon ~= nil and w.components.weapon.stimuli == "electric" then
		return true
	end
	return false
end

local function KingSquidIsFrozen(inst)
	return inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()
end

local function KingSquidIsElectrocuted(inst)
	return inst.sg ~= nil and inst.sg:HasStateTag("electrocute")
end

local function KingSquidShouldBlockCombatDamage(inst)
	if inst.sg == nil then
		return false
	end
	return inst.sg:HasStateTag("jumping") or inst.sg:HasStateTag("electrocute")
end

local function KingSquidGetLungeStandOff(_inst)
	return TUNING.KING_SQUID_LUNGE_STAND_OFF or 1
end

-- 玩家前方：优先移动方向，否则面向；若面向鱿王则用「鱿王→玩家」作为逃跑方向
local function KingSquidGetLeapLandOffsetDir(inst, target, sx, sz, tx, tz)
	local dx, dz = tx - sx, tz - sz
	local len = math.sqrt(dx * dx + dz * dz)
	local ax, az = 0, 0
	if len > 0.01 then
		ax, az = dx / len, dz / len
	end
	if target ~= nil and target:IsValid() and target.Physics ~= nil then
		local vx, _, vz = target.Physics:GetVelocity()
		local vsq = vx * vx + vz * vz
		if vsq > 0.25 then
			local vlen = math.sqrt(vsq)
			return vx / vlen, vz / vlen
		end
	end
	if target ~= nil and target:IsValid() and target.Transform ~= nil then
		local theta = target.Transform:GetRotation() * DEGREES
		local fx, fz = math.cos(theta), -math.sin(theta)
		if ax ~= 0 or az ~= 0 then
			if fx * ax + fz * az > 0 then
				return fx, fz
			end
			return ax, az
		end
		return fx, fz
	end
	if ax ~= 0 or az ~= 0 then
		return ax, az
	end
	if inst ~= nil and inst.Transform ~= nil then
		local theta = inst.Transform:GetRotation() * DEGREES
		return math.cos(theta), -math.sin(theta)
	end
	return 1, 0
end

local function KingSquidPlanarDistSq(x1, z1, x2, z2)
	local dx, dz = x2 - x1, z2 - z1
	return dx * dx + dz * dz
end

local function KingSquidGetLeapGroundY(x, y, z)
	if TheWorld ~= nil and TheWorld.Map ~= nil then
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
		if cy ~= nil then
			return cy
		end
	end
	return y or 0
end

-- snap=true 仅用于起跳/落地；腾空过程中只用 SetPosition，避免每帧 Teleport 在洞穴下被网络插值成瞬移感
local function KingSquidSetLeapWorldPos(inst, x, y, z, snap)
	inst.Transform:SetPosition(x, y, z)
	if snap and inst.Physics ~= nil and inst.Physics.Teleport ~= nil then
		inst.Physics:Teleport(x, y, z)
	end
end

local function KingSquidBeginLeapFlightPhysics(inst)
	if inst.Physics == nil then
		return
	end
	inst.Physics:Stop()
	inst.Physics:ClearMotorVelOverride()
	if inst.Physics.ClearCollisionMask ~= nil then
		inst.Physics:ClearCollisionMask()
		inst.Physics:CollidesWith(COLLISION.WORLD)
	else
		inst.Physics:SetCollisionMask(COLLISION.GROUND)
	end
end

local function KingSquidClampLeapTravel(travel, dmin, dmax)
	if travel < dmin then
		return dmin
	end
	if travel > dmax then
		return dmax
	end
	return travel
end

local function KingSquidSnapLeapTargetPos(inst)
	local target = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	if target == nil then
		return nil
	end
	inst.sg.statemem.target = target
	local tx, ty, tz = target.Transform:GetWorldPosition()
	if KingSquidNeedsCrossWaterApproach(inst, target)
		and not KingSquidIsCrossMediumCombat(inst, target) then
		local sx, sy, sz = inst.Transform:GetWorldPosition()
		local dest = KingSquidGetWaterEntryDest(inst, target)
		if dest ~= nil then
			tx, ty, tz = dest.x, dest.y, dest.z
		end
	end
	inst.sg.statemem.targetpos = Vector3(tx, ty, tz)
	return inst.sg.statemem.targetpos
end

local function KingSquidGetHitstunImmuneAfter()
	return TUNING.KING_SQUID_HITSTUN_IMMUNE_AFTER or 2
end

local function KingSquidGetHitstunImmuneDuration()
	return TUNING.KING_SQUID_HITSTUN_IMMUNE_DURATION or 1
end

local function KingSquidIsHitImmune(inst)
	if inst.prefab ~= "king_squid" then
		return false
	end
	local until_t = inst._king_squid_hit_immune_until
	return until_t ~= nil and GetTime() < until_t
end

local function KingSquidCanTriggerHitstun(inst)
	if inst.prefab ~= "king_squid" then
		return true
	end
	return not KingSquidIsHitImmune(inst)
end

local function KingSquidUpdateHitstunAccum(inst, dt)
	if inst.prefab ~= "king_squid" or inst.sg == nil then
		return
	end
	if KingSquidIsHitImmune(inst) then
		return
	end
	if not (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) then
		inst._king_squid_hit_stun_accum = 0
		return
	end
	inst._king_squid_hit_stun_accum = (inst._king_squid_hit_stun_accum or 0) + dt
	if inst._king_squid_hit_stun_accum >= KingSquidGetHitstunImmuneAfter() then
		inst._king_squid_hit_immune_until = GetTime() + KingSquidGetHitstunImmuneDuration()
		inst._king_squid_hit_stun_accum = 0
		if inst.sg:HasStateTag("hit") then
			inst.sg:GoToState("idle")
		end
	end
end

-- 渡水跳跃：沿目标方向找首个「登岸/对岸陆地」落点，避免按直线全长冲刺
local function KingSquidGetCrossWaterLeapTravel(inst, sx, sz, tx, tz, len, stand_off, dmin, dmax)
	local dx, dz = tx - sx, tz - sz
	if len > 0.01 then
		dx, dz = dx / len, dz / len
	else
		local travel = len - stand_off
		return KingSquidClampLeapTravel(travel, dmin, dmax)
	end
	local start_ocean = TheWorld.Map:IsOceanAtPoint(sx, 0, sz) or inst:HasTag("swimming")
	local seen_ocean = start_ocean
	local land_dist = nil
	for step = 1, math.ceil(len) do
		local px, pz = sx + dx * step, sz + dz * step
		local on_ocean = TheWorld.Map:IsOceanAtPoint(px, 0, pz)
		if start_ocean and not on_ocean then
			land_dist = step
			break
		elseif not start_ocean and on_ocean then
			seen_ocean = true
		elseif seen_ocean and not on_ocean then
			land_dist = step
			break
		end
	end
	if land_dist == nil then
		return KingSquidClampLeapTravel(len - stand_off, dmin, dmax)
	end
	local travel = land_dist - stand_off
	if travel < dmin then
		travel = dmin
	elseif travel > dmax then
		travel = dmax
	end
	return travel
end

local function KingSquidSyncAmphibiousFromTerrain(inst)
	local ac = inst.components.amphibiouscreature
	if ac == nil then
		return
	end
	if inst:IsOnOcean() or inst:HasTag("swimming") then
		ac:OnEnterOcean()
		inst.fling_land = false
	else
		ac:OnExitOcean()
		inst.fling_land = true
	end
end

local function KingSquidGetLeapChaseRange(inst, target)
	if target ~= nil and KingSquidIsCrossMediumCombat(inst, target) then
		return KingSquidGetInkCastRange(inst)
	end
	if target ~= nil and KingSquidNeedsCrossWaterApproach(inst, target) then
		return KingSquidGetCombatApproachRange(inst)
	end
	return KingSquidGetCombatApproachRange(inst)
end

local function KingSquidClearRetreatLeapMotor(inst)
	inst.fling_land = nil
	if inst.Physics ~= nil then
		inst.Physics:Stop()
		inst.Physics:ClearMotorVelOverride()
	end
	KingSquidRestorePhysics(inst)
	if inst.components.locomotor ~= nil then
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
	end
end

-- 逃离跳跃中受电击：先停跳，再进入 electrocute 僵直（需 state 带 canelectrocute）
local function KingSquidTryBreakRetreatWithElectrocute(inst, data)
	if inst.sg == nil or inst.sg.currentstate == nil or inst.sg.currentstate.name ~= "king_squid_retreat_leap" then
		return false
	end
	if not KingSquidIsElectricHit(data) then
		return false
	end
	KingSquidClearRetreatLeapMotor(inst)
	if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
		return true
	end
	if inst.sg:HasState("electrocute") then
		inst.sg:GoToState("electrocute", data)
		return true
	end
	if inst.sg:HasState("hit") then
		inst.sg:GoToState("hit")
	else
		inst.sg:GoToState("idle")
	end
	return true
end

local function KingSquidInterruptRetreatLeap(inst)
	if inst.sg == nil or inst.sg.currentstate == nil or inst.sg.currentstate.name ~= "king_squid_retreat_leap" then
		return false
	end
	KingSquidClearRetreatLeapMotor(inst)
	if inst.sg:HasState("hit") then
		inst.sg:GoToState("hit")
	else
		inst.sg:GoToState("idle")
	end
	return true
end

local function OnKingSquidHealthDeltaForRetreat(inst, data)
	if inst.prefab ~= "king_squid" then
		return
	end
	if inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	if KingSquidIsFrozen(inst) then
		inst._king_squid_hurt_accum = 0
		return
	end
	if inst.sg ~= nil
		and inst.sg.currentstate ~= nil
		and inst.sg.currentstate.name == "king_squid_retreat_leap"
		and KingSquidTryBreakRetreatWithElectrocute(inst, data) then
		return
	end
	local dmg = KingSquidDamageFromHealthDelta(inst, data)
	if dmg <= 0 then
		return
	end
	local th = TUNING.KING_SQUID_RETREAT_DAMAGE or 300
	inst._king_squid_hurt_accum = (inst._king_squid_hurt_accum or 0) + dmg
	local atk = KingSquidRetreatThreatFromData(inst, data)
	local queued = 0
	local chain = TUNING.KING_SQUID_RETREAT_CHAIN_DELAY or 0.15
	while inst._king_squid_hurt_accum >= th do
		inst._king_squid_hurt_accum = inst._king_squid_hurt_accum - th
		local atk_ref = atk
		local kick_delay = queued * chain
		queued = queued + 1
		inst:DoTaskInTime(kick_delay, function(ent)
			if not ent:IsValid() or ent.components.health == nil or ent.components.health:IsDead() then
				return
			end
			if KingSquidIsFrozen(ent) then
				return
			end
			if ent.sg == nil then
				return
			end
			local st = ent.sg.currentstate ~= nil and ent.sg.currentstate.name or nil
			if st == "king_squid_retreat_leap" then
				return
			end
			local tht = atk_ref
			if tht == nil or not tht:IsValid() then
				tht = KingSquidRetreatThreatFromData(ent, nil)
			end
			ent.sg:GoToState("king_squid_retreat_leap", tht)
		end)
	end
end

local function KingSquidTryEngagementTaunt(inst, target)
	if inst.prefab ~= "king_squid" or target == nil or not target:IsValid() then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	if inst.sg == nil or inst.sg:HasStateTag("busy") then
		return
	end
	if inst._king_squid_engagement_taunt_target == target then
		return
	end
	if inst._king_squid_skip_engagement_taunt then
		inst._king_squid_skip_engagement_taunt = nil
		inst._king_squid_engagement_taunt_target = target
		return
	end
	inst._king_squid_engagement_taunt_target = target
	inst.sg:GoToState("king_squid_engagement_taunt", target)
end

local function KingSquidIsSameCycleTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	local ct = inst._king_squid_cycle_target
	if ct == nil then
		return false
	end
	if ct == target then
		return true
	end
	if ct:IsValid() and ct.GUID == target.GUID then
		return true
	end
	return false
end

local function KingSquidRefreshCycleTargetFromCombat(inst)
	if inst.components.combat == nil then
		return
	end
	local t = inst.components.combat.target
	if t ~= nil and t:IsValid() then
		inst._king_squid_cycle_target = t
	end
end

local function OnNewTarget(inst, data)
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
	local target = data ~= nil and data.target or nil
	if target == nil or not target:IsValid() then
		inst._king_squid_engagement_taunt_target = nil
		-- 附身解除 / brain 重启等会短暂 SetTarget(nil)，勿清空周期目标与 2跳→喷墨→战吼 进度
		return
	end
	if inst.prefab == "king_squid" then
		local was_same = KingSquidIsSameCycleTarget(inst, target)
		inst._king_squid_cycle_target = target
		-- 换目标也继续全局周期（2跳→喷墨→战吼），不重置 leaps_since_ink
		local on_ink_cd = inst.components.timer ~= nil
			and inst.components.timer:TimerExists("ink_cooldown")
		local cycle_start = (inst._king_squid_leaps_since_ink or 0) == 0 and not on_ink_cd
		if not was_same and cycle_start then
			if KingSquidIsInWaterCombat(inst) and inst._king_squid_water_opening_ink_done == nil then
				KingSquidBeginWaterOpeningInk(inst)
			end
			KingSquidTryEngagementTaunt(inst, target)
		end
	end
end

local function OnKingSquidWakeUp(inst)
	KingSquidTryAcquirePlayerTarget(inst)
end

-- 起跳/电击僵直期间禁止 DoAttack（含 AOE），伤害仅在 king_squid_melee 三段挥击结算
local function KingSquidPatchCombatDoAttack(inst)
	local combat = inst.components.combat
	if combat == nil or combat._king_squid_doattack_patched then
		return
	end
	combat._king_squid_doattack_patched = true
	local _DoAttack = combat.DoAttack
	combat.DoAttack = function(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
		local owner = self.inst
		if owner ~= nil and owner:IsValid() and KingSquidShouldBlockCombatDamage(owner) then
			self:ClearAttackTemps()
			return
		end
		return _DoAttack(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
	end
end

-- ChaseAndAttack 默认仅在近战距离才 TryAttack；扩展为在 LEAP_CHASE 距离内即可起跳接近
local function KingSquidPatchCombatTryAttack(inst)
	local combat = inst.components.combat
	if combat == nil or combat._king_squid_tryattack_patched then
		return
	end
	combat._king_squid_tryattack_patched = true
	local _TryAttack = combat.TryAttack
	combat.TryAttack = function(self, target)
		local owner = self.inst
		if owner == nil or not owner:IsValid() or owner.prefab ~= "king_squid" then
			return _TryAttack(self, target)
		end
		if KingSquidIsFrozen(owner) or KingSquidIsElectrocuted(owner) then
			return false
		end
		if KingSquidShouldPreferInk(owner) then
			return false
		end
		target = target or self.target
		if owner.sg ~= nil and owner.sg:HasStateTag("attack") then
			return true
		end
		if target ~= nil and target:IsValid() and owner.sg ~= nil and not owner.sg:HasStateTag("jumping") then
			local leap_r = KingSquidGetLeapChaseRange(owner, target)
			local sx, _, sz = owner.Transform:GetWorldPosition()
			local tx, _, tz = target.Transform:GetWorldPosition()
			local dx, dz = tx - sx, tz - sz
			if dx * dx + dz * dz <= leap_r * leap_r and not self:InCooldown() then
				local busy = owner.sg:HasStateTag("busy")
				local hit = owner.sg:HasStateTag("hit") and not owner.sg:HasStateTag("electrocute")
				if not busy or hit then
					owner:PushEvent("doattack", { target = target })
					return true
				end
			end
		end
		return _TryAttack(self, target)
	end
end

local function KingSquidPlayerTookMeleeDamage(data)
	if data == nil or data.target == nil or not data.target:IsValid() or data.redirected then
		return false
	end
	if not data.target:HasTag("player") or data.target:HasTag("playerghost") then
		return false
	end
	if (data.damageresolved or 0) > 0 then
		return true
	end
	local spd = data.spdamage
	if spd ~= nil then
		for _, v in pairs(spd) do
			if type(v) == "number" and v > 0 then
				return true
			end
		end
	end
	return false
end

-- 三连击最后一击：对玩家施加击飞
local function KingSquidApplyMeleeKnockback(inst, target, launch_scale)
	if target == nil or not target:IsValid() or target:IsInLimbo() then
		return
	end
	if not target:HasTag("player") or target:HasTag("playerghost") then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	launch_scale = launch_scale or 1
	local launch_dist = (TUNING.KING_SQUID_MELEE_LAUNCH_DISTANCE or KING_SQUID_TILE_SIZE) * launch_scale
	local launch_strength = (TUNING.KING_SQUID_MELEE_KNOCKBACK_STRENGTH or 1) * launch_scale
	target:PushEventImmediate("knockback", {
		knocker = inst,
		radius = launch_dist,
		strengthmult = launch_strength,
		starthigh = false,
		forcelanded = false,
	})
end

local function KingSquidQueueFinalMeleeKnockback(inst, target)
	if inst == nil or not inst:IsValid() or target == nil or not target:IsValid() then
		return
	end
	if not target:HasTag("player") or target:HasTag("playerghost") then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	inst._king_squid_melee_kb_pending = inst._king_squid_melee_kb_pending or {}
	inst._king_squid_melee_kb_pending[target] = true
end

local function KingSquidFlushFinalMeleeKnockbacks(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	local pending = inst._king_squid_melee_kb_pending
	if pending == nil then
		return
	end
	local applied = inst._king_squid_melee_kb_applied or {}
	local kb_scale = TUNING.KING_SQUID_MELEE_FINAL_LAUNCH_SCALE or 1
	for victim, _ in pairs(pending) do
		if victim ~= nil and victim:IsValid() and not applied[victim] then
			applied[victim] = true
			KingSquidApplyMeleeKnockback(inst, victim, kb_scale)
		end
	end
	inst._king_squid_melee_kb_applied = applied
end

local function KingSquidClearFinalMeleeKnockbackState(inst)
	if inst == nil then
		return
	end
	inst._king_squid_melee_kb_pending = nil
	inst._king_squid_melee_kb_applied = nil
	inst._king_squid_melee_hit_idx = nil
end

local function KingSquidPatchCombatOnHitOther(inst)
	local combat = inst.components.combat
	if combat == nil or combat._king_squid_onhitother_patched then
		return
	end
	combat._king_squid_onhitother_patched = true
	local old_fn = combat.onhitotherfn
	combat.onhitotherfn = function(attacker, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
		if old_fn ~= nil then
			old_fn(attacker, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
		end
		if not KingSquidIsKing(attacker) or attacker._king_squid_melee_hit_idx ~= 3 then
			return
		end
		if KingSquidIsElectrocuted(attacker) then
			return
		end
		if not KingSquidPlayerTookMeleeDamage({
			target = target,
			damageresolved = damageresolved,
			spdamage = spdamage,
		}) then
			return
		end
		KingSquidQueueFinalMeleeKnockback(attacker, target)
		KingSquidFlushFinalMeleeKnockbacks(attacker)
	end
end

local function KingSquidSleepHealthRegen(inst)
	if inst.components.sleeper == nil or not inst.components.sleeper:IsAsleep() then
		return
	end
	local h = inst.components.health
	if h == nil or h:IsDead() then
		return
	end
	local maxh = h.GetMaxWithPenalty ~= nil and h:GetMaxWithPenalty() or h.maxhealth
	if maxh == nil or maxh <= 0 then
		return
	end
	local cap_pct = TUNING.KING_SQUID_SLEEP_HEALTH_CAP or 0.5
	local cap = maxh * cap_pct
	if h.currenthealth >= cap then
		return
	end
	local regen = TUNING.KING_SQUID_SLEEP_HEALTH_REGEN or 15
	if regen > 0 then
		h:DoDelta(math.min(regen, cap - h.currenthealth), nil, "sleep_regen")
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()
	MakeCharacterPhysics(
		inst,
		TUNING.KING_SQUID_PHYSICS_MASS * SCALE,
		TUNING.KING_SQUID_PHYSICS_RADIUS * SCALE
	)
	inst.DynamicShadow:SetSize(
		TUNING.KING_SQUID_SHADOW_WIDTH * SCALE,
		TUNING.KING_SQUID_SHADOW_HEIGHT * SCALE
	)
	inst.Transform:SetSixFaced()
	inst.Transform:SetScale(SCALE, SCALE, SCALE)
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("minotaur")
	inst:AddTag("shadow_aligned")
	inst:AddTag("laser_immune")
	inst:AddTag("squid")
	inst:AddTag("king_squid")
	inst:AddTag("epic")
	inst:AddTag("likewateroffducksback")
	inst:AddTag("wet") -- 永久潮湿（同洞穴蠕虫，GetWetMultiplier 恒为 1）
	inst.AnimState:SetBank("squiderp")
	inst.AnimState:SetBuild("squid_build")
	inst.AnimState:PlayAnimation("idle")
	inst:AddComponent("spawnfader")
	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end
	inst.sounds = sounds
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.KING_SQUID_RUN_SPEED
	inst.components.locomotor.walkspeed = TUNING.KING_SQUID_WALK_SPEED
	inst.components.locomotor.skipHoldWhenFarFromHome = true
	inst:SetStateGraph("SGsquid")
	inst:AddComponent("embarker")
	inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
	inst.components.locomotor:SetAllowPlatformHopping(true)
	inst:AddComponent("amphibiouscreature")
	inst.components.amphibiouscreature:SetBanks("squiderp", "squiderp_water")
	inst.components.amphibiouscreature:SetEnterWaterFn(function(i)
		i.hop_distance = i.components.locomotor.hop_distance
		i.components.locomotor.hop_distance = TUNING.KING_SQUID_WATER_HOP_DIST * SCALE
		i.DynamicShadow:Enable(false)
		SetKingSquidPathcaps(i)
	end)
	inst.components.amphibiouscreature:SetExitWaterFn(function(i)
		if i.hop_distance then
			i.components.locomotor.hop_distance = i.hop_distance
		end
		i.DynamicShadow:Enable(true)
		SetKingSquidPathcaps(i)
	end)
	SetKingSquidPathcaps(inst)
	inst.king_squid_scale_mult = SCALE
	local px, _, pz = inst.Transform:GetWorldPosition()
	inst._king_squid_track_x = px
	inst._king_squid_track_z = pz
	inst._king_squid_still_since = GetTime()
	inst._king_squid_attack_count = 0
	inst._king_squid_hit_stun_accum = 0
	inst._king_squid_hit_immune_until = nil
	inst._king_squid_pending_double_taunt = nil
	KingSquidResetAttackCycle(inst)
	inst:DoPeriodicTask(0.5, KingSquidUpdateStillness)
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.KING_SQUID_HEALTH)
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = TUNING.KING_SQUID_SANITY_AURA
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.KING_SQUID_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.KING_SQUID_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(TUNING.KING_SQUID_RETARGET_PERIOD, RetargetPlayer)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound(inst.sounds.hurt)
	inst.components.combat:SetRange(KING_SQUID_APPROACH_RANGE, ATTACK_RANGE)
	inst.components.combat:EnableAreaDamage(true)
	inst.components.combat:SetAreaDamage(ATTACK_RANGE, TUNING.KING_SQUID_AREA_DAMAGE_MULT, function(ent, attacker)
		if ent:HasTag("chess") then
			return false
		end
		if not ent:HasTag("squid") then
			return true
		end
		if ent:IsValid() and ent.sg ~= nil then
			ent.SoundEmitter:PlaySound("hookline/creatures/squid/slap")
			local x, y, z = ent.Transform:GetWorldPosition()
			ent.Transform:SetRotation(attacker:GetAngleToPoint(x, y, z))
			if ent.sg:HasState("hit") then
				ent.sg:GoToState("hit")
			elseif ent.sg:HasState("fling") then
				ent.sg:GoToState("fling")
			end
		end
	end)
	inst.components.combat.battlecryenabled = false
	inst.components.combat:AddNoAggroTag("chess")
	inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.KING_SQUID_PLANAR_DAMAGE)
	KingSquidPatchCombatDoAttack(inst)
	KingSquidPatchCombatTryAttack(inst)
	KingSquidPatchCombatOnHitOther(inst)
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("king_squid")
	inst.components.lootdropper:SetLootSetupFn(KingSquidLootSetupFn)
	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")
	local nest = inst.spawnlocation or inst:GetPosition()
	KingSquidRememberNest(inst, nest)
	inst.OnSave = function(i, data)
		data.spawnlocation = i.spawnlocation
	end
	inst.OnLoad = function(i, data)
		if data ~= nil and data.spawnlocation ~= nil then
			KingSquidRememberNest(i, data.spawnlocation)
		end
	end
	inst.OnLoadPostPass = function(i)
		if i.spawnlocation == nil then
			local pos = KingSquidFindNestFromRespawner(i)
			if pos ~= nil then
				KingSquidRememberNest(i, pos)
			end
		end
	end
	inst:AddComponent("sleeper")
	inst.components.sleeper:SetWakeTest(KingSquidShouldWake)
	inst.components.sleeper:SetSleepTest(KingSquidShouldSleep)
	inst.components.sleeper:SetResistance(3)
	inst:AddComponent("timer")
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("onwakeup", OnKingSquidWakeUp)
	inst:ListenForEvent("healthdelta", OnKingSquidHealthDeltaForRetreat)
	inst:ListenForEvent("attacked", OnAttacked)
	inst:DoPeriodicTask(0.5, KingSquidTryAcquirePlayerTarget)
	inst:DoPeriodicTask(TUNING.KING_SQUID_SLEEP_HEALTH_REGEN_PERIOD or 5, KingSquidSleepHealthRegen)
	inst:DoPeriodicTask(0.1, function(i)
		if i:IsValid() then
			KingSquidUpdateHitstunAccum(i, 0.1)
		end
	end)
	-- 须在 combat 就绪后再启 brain，否则 RetargetPlayer 会空指针崩溃
	inst:SetBrain(KingSquidBrain)
	if not inst._king_squid_possess_watch then
		inst._king_squid_possess_watch = true
		inst._king_squid_was_player_controlled = false
		inst:DoPeriodicTask(0.25, function(i)
			if not i:IsValid() then
				return
			end
			local controlled = KingSquidIsPlayerControlled(i)
			if controlled and i.brain ~= nil then
				i.brain:Stop()
			end
			if i._king_squid_was_player_controlled and not controlled then
				-- 解除附身或其它操控结束：保持对当前敌人的攻击周期
				KingSquidRefreshCycleTargetFromCombat(i)
				KingSquidSchedulePendingDoubleTaunt(i)
			elseif not i._king_squid_was_player_controlled and controlled then
				-- 刚被操控：若循环喷墨已计入，先补双重战吼
				KingSquidSchedulePendingDoubleTaunt(i)
			end
			i._king_squid_was_player_controlled = controlled
		end)
	end
	MakeHauntablePanic(inst)
	if inst.components.hauntable ~= nil then
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_MED)
	end
	inst:AddTag("hauntable")
	MakeMediumFreezableCharacter(inst, "squid_body")
	if inst.components.freezable ~= nil then
		inst.components.freezable:SetResistance(4)
	end
	MakeMediumBurnableCharacter(inst, "squid_body")
	inst.LaunchProjectile = LaunchProjectile
	inst.eyeglow = SpawnPrefab("squideyelight")
	inst.eyeglow.entity:SetParent(inst.entity)
	inst.eyeglow.entity:AddFollower()
	inst.eyeglow.Follower:FollowSymbol(inst.GUID, "glow", 0, 0, 0)
	KingSquidApplyEyeGlowLight(inst)
	return inst
end

local RuinsRespawner = require("prefabs/ruinsrespawner")

local function OnKingSquidRuinsRespawn(inst, respawner)
	if respawner ~= nil and respawner:IsValid() then
		KingSquidRememberNest(inst, respawner:GetPosition())
	elseif inst.spawnlocation ~= nil then
		KingSquidRememberNest(inst, inst.spawnlocation)
	end
end

RegisterPrefabs(
	Prefab("king_squid", fn, assets, prefabs),
	RuinsRespawner.Inst("king_squid", OnKingSquidRuinsRespawn),
	RuinsRespawner.WorldGen("king_squid", OnKingSquidRuinsRespawn)
)

AddPrefabPostInit("king_squid", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst._king_squid_noclick_strip_task ~= nil then
		return
	end
	inst._king_squid_noclick_strip_task = inst:DoPeriodicTask(0.1, function(i)
		if not i:IsValid() then
			return
		end
		if i:HasTag("NOCLICK") then
			i:RemoveTag("NOCLICK")
		end
	end)
end)

local CLOCKWORK_NO_KING_SQUID_AGGRO = {
	"bishop", "bishop_nightmare",
	"knight", "knight_nightmare",
	"rook", "rook_nightmare",
}

local function PatchClockworkIgnoreKingSquid(inst)
	if not TheWorld.ismastersim or inst.components.combat == nil then
		return
	end
	local combat = inst.components.combat
	combat:AddNoAggroTag("king_squid")

	if combat._king_squid_aggro_patched then
		return
	end
	combat._king_squid_aggro_patched = true

	local old_set_target = combat.SetTarget
	combat.SetTarget = function(self, target, ...)
		if target ~= nil and target:IsValid() and target:HasTag("king_squid") then
			return
		end
		return old_set_target(self, target, ...)
	end

	local period, old_retarget = combat.retargetperiod, combat.targetfn
	if old_retarget ~= nil then
		combat:SetRetargetFunction(period, function(ent, ...)
			local t = old_retarget(ent, ...)
			if t ~= nil and t:IsValid() and t:HasTag("king_squid") then
				return nil
			end
			return t
		end)
	end

	inst:ListenForEvent("attacked", function(ent, data)
		local attacker = data ~= nil and data.attacker or nil
		if attacker ~= nil and attacker:IsValid() and attacker:HasTag("king_squid") then
			if ent.components.combat.target == attacker then
				ent.components.combat:SetTarget(nil)
			end
		end
	end)
end

for _, prefab in ipairs(CLOCKWORK_NO_KING_SQUID_AGGRO) do
	AddPrefabPostInit(prefab, PatchClockworkIgnoreKingSquid)
end

----------------------------------------------------------------------
-- SGsquid 内部注册名是 "squid"（不是 SGsquid）
-- 保留原版 idle/run/hop 等；鱿王专用：滑铲近战、喷墨（N 发聚团落点）、累计受伤后跳撤退；禁用吃鱼
----------------------------------------------------------------------

local function KingSquidCanCombat(inst)
	if KingSquidIsFrozen(inst) or KingSquidIsElectrocuted(inst) then
		return false
	end
	return inst.components.health ~= nil
		and not inst.components.health:IsDead()
		and (
			(inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute"))
			or not inst.sg:HasStateTag("busy")
		)
end

local function KingSquidMeleeClearSlideTask(inst)
	local task = inst._king_squid_melee_slide_task
	if task ~= nil then
		task:Cancel()
		inst._king_squid_melee_slide_task = nil
	end
	inst._king_squid_melee_slide_vel = nil
end

local function KingSquidMeleeClearCarryTask(inst)
	local task = inst._king_squid_melee_carry_task
	if task ~= nil then
		task:Cancel()
		inst._king_squid_melee_carry_task = nil
	end
end

local KING_SQUID_SLIDE_BRAIN = "king_squid_slide_attack"

local function KingSquidGetLeapTravelLimits(inst, target)
	local dmin = TUNING.KING_SQUID_LUNGE_MIN_DIST or 0.55
	local dmax = TUNING.KING_SQUID_LUNGE_MAX_DIST or KingSquidGetCombatApproachRange(inst)
	if target ~= nil and KingSquidIsCrossMediumCombat(inst, target) then
		dmax = TUNING.KING_SQUID_CROSS_MEDIUM_LUNGE_MAX_DIST or dmax
	end
	return dmin, dmax
end

-- 水平落点：目标位置 + 玩家前方 stand_off；再按最大跳跃距离裁切
local function KingSquidComputeLeapLandPos(inst, startpos, targetpos, target)
	local sx, sy, sz = startpos.x, startpos.y, startpos.z
	local tx, ty, tz = targetpos.x, targetpos.y, targetpos.z
	if target ~= nil and target:IsValid() then
		tx, ty, tz = target.Transform:GetWorldPosition()
	end
	local dx, dz = tx - sx, tz - sz
	local len = math.sqrt(dx * dx + dz * dz)
	local stand_off = KingSquidGetLungeStandOff(inst)
	local dmin, dmax = KingSquidGetLeapTravelLimits(inst, target)
	local fx, fz = KingSquidGetLeapLandOffsetDir(inst, target, sx, sz, tx, tz)
	local want_lx = tx + fx * stand_off
	local want_lz = tz + fz * stand_off
	local wdx, wdz = want_lx - sx, want_lz - sz
	local want_travel = math.sqrt(wdx * wdx + wdz * wdz)
	if want_travel < 0.01 then
		return Vector3(sx, sy, sz), 0
	end
	local travel = want_travel
	if target ~= nil and KingSquidNeedsCrossWaterApproach(inst, target)
		and not KingSquidIsCrossMediumCombat(inst, target) then
		local cap = KingSquidGetCrossWaterLeapTravel(inst, sx, sz, tx, tz, len, 0, dmin, dmax)
		if cap < travel then
			travel = cap
		end
	else
		travel = KingSquidClampLeapTravel(travel, dmin, dmax)
	end
	local scale = travel / want_travel
	local lx = sx + wdx * scale
	local lz = sz + wdz * scale
	local ly = KingSquidGetLeapGroundY(lx, sy, lz)
	return Vector3(lx, ly, lz), travel
end

local KingSquidSlideAttackLand

local function KingSquidGetLeapArcProgress(inst, sm)
	if sm == nil or not sm.leap_arc_active or sm.leap_arc_start == nil then
		return 0
	end
	local dur = sm.leap_arc_duration
	if dur == nil or dur <= 0 then
		dur = TUNING.KING_SQUID_LEAP_LOOP_FALLBACK or (26 * FRAMES)
	end
	return math.clamp((GetTime() - sm.leap_arc_start) / dur, 0, 1)
end

local function KingSquidSyncLeapAmphibious(inst, x, y, z)
	local ac = inst.components.amphibiouscreature
	if ac == nil then
		return
	end
	local on_ocean = TheWorld.Map:IsOceanAtPoint(x, y, z)
	if on_ocean then
		if inst.fling_land then
			ac:OnEnterOcean()
			inst.fling_land = false
		end
	else
		if not inst.fling_land then
			ac:OnExitOcean()
			inst.fling_land = true
		end
	end
end

local function KingSquidFinishParabolicLeap(inst)
	local sm = inst.sg ~= nil and inst.sg.statemem or nil
	if sm == nil or not sm.leap_arc_active then
		return
	end
	sm.leap_arc_active = false
	if sm.leap_lx ~= nil then
		KingSquidSetLeapWorldPos(inst, sm.leap_lx, sm.leap_ly, sm.leap_lz, true)
		KingSquidSyncLeapAmphibious(inst, sm.leap_lx, sm.leap_ly, sm.leap_lz)
	end
	KingSquidSlideAttackLand(inst)
end

local function KingSquidPlanParabolicLeap(inst)
	local targetpos = inst.sg.statemem.targetpos
	if targetpos == nil then
		targetpos = KingSquidSnapLeapTargetPos(inst)
	end
	if targetpos == nil then
		return false
	end
	local startpos = inst:GetPosition()
	local target = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	local landpos, travel = KingSquidComputeLeapLandPos(inst, startpos, targetpos, target)
	inst:ForceFacePoint(landpos:Get())

	local sm = inst.sg.statemem
	sm.leap_sx, sm.leap_sy, sm.leap_sz = startpos.x, startpos.y, startpos.z
	sm.leap_lx = landpos.x
	sm.leap_ly = landpos.y
	sm.leap_lz = landpos.z
	sm.leap_travel = travel
	sm.leap_landpos = landpos
	local arc_h = (TUNING.KING_SQUID_LEAP_ARC_HEIGHT or 4.5)
		+ travel * (TUNING.KING_SQUID_LEAP_ARC_HEIGHT_PER_DIST or 0.06)
	sm.leap_arc_height = math.min(arc_h, TUNING.KING_SQUID_LEAP_ARC_HEIGHT_MAX or 8)
	return true
end

-- 抛物线腾空：保留原版轨迹；不再用 SetDeltaTimeMultiplier 加速动画（洞穴下会与位移网络包错位卡顿）
local function KingSquidStartParabolicLeapArc(inst, air_duration)
	if inst.sg == nil then
		return false
	end
	if inst.sg.statemem.leap_arc_active then
		return true
	end
	if not KingSquidPlanParabolicLeap(inst) then
		return false
	end
	local sm = inst.sg.statemem
	if (sm.leap_travel or 0) <= 0 then
		KingSquidSlideAttackLand(inst)
		return true
	end
	sm.leap_arc_active = true
	sm.leap_arc_start = GetTime()
	local anim_full = sm.leap_anim_full
		or air_duration
		or (TUNING.KING_SQUID_LEAP_JUMP_FALLBACK or (10 * FRAMES))
			+ (TUNING.KING_SQUID_LEAP_LOOP_FALLBACK or (26 * FRAMES))
	local travel = sm.leap_travel or 0
	local smult = inst.king_squid_scale_mult or SCALE
	local sync_travel = (TUNING.KING_SQUID_LEAP_ANIM_SYNC_TRAVEL or (7 * KING_SQUID_SIZE_MULT)) * smult
	local dur
	if travel > 0 and travel <= sync_travel then
		-- 近距：按水平距离缩短腾空时长（勿用 anim_full，否则会空中悬停过久）
		local frac = math.clamp(travel / sync_travel, 0.35, 1)
		local hspeed = TUNING.KING_SQUID_LEAP_HSPEED or 42
		local tmin = TUNING.KING_SQUID_LEAP_DURATION_MIN or 0.34
		dur = math.max(tmin, travel / hspeed)
		dur = math.min(dur, anim_full * frac * (TUNING.KING_SQUID_LEAP_AIR_TIME_SCALE or 0.55))
		local arc = sm.leap_arc_height or (TUNING.KING_SQUID_LEAP_ARC_HEIGHT or 2.2)
		sm.leap_arc_height = arc * frac * frac
	else
		local scale = TUNING.KING_SQUID_LEAP_AIR_TIME_SCALE or 0.55
		local tmin = TUNING.KING_SQUID_LEAP_DURATION_MIN or 0.34
		local tmax = TUNING.KING_SQUID_LEAP_DURATION_MAX or 0.72
		local hspeed = TUNING.KING_SQUID_LEAP_HSPEED or 42
		dur = anim_full * scale
		if travel > 0 and hspeed > 0 then
			dur = math.min(dur, travel / hspeed)
		end
		if dur < tmin then
			dur = tmin
		elseif dur > tmax then
			dur = tmax
		end
		if dur > anim_full then
			dur = anim_full
		end
	end
	sm.leap_arc_duration = dur
	KingSquidBeginLeapFlightPhysics(inst)
	if anim_full > 0 and dur > 0 and dur < anim_full * 0.98 then
		inst.AnimState:SetDeltaTimeMultiplier(anim_full / dur)
	else
		inst.AnimState:SetDeltaTimeMultiplier(1)
	end
	inst.sg:SetTimeout(dur + FRAMES * 4)
	return true
end

local function KingSquidUpdateParabolicLeap(inst)
	local sm = inst.sg.statemem
	if sm == nil or not sm.leap_arc_active then
		return
	end
	local t = KingSquidGetLeapArcProgress(inst, sm)
	local sx, sy, sz = sm.leap_sx, sm.leap_sy, sm.leap_sz
	local lx, ly, lz = sm.leap_lx, sm.leap_ly, sm.leap_lz
	local px = sx + (lx - sx) * t
	local pz = sz + (lz - sz) * t
	local base_y = sy + (ly - sy) * t
	local py = base_y + (sm.leap_arc_height or 4) * 4 * t * (1 - t)
	KingSquidSetLeapWorldPos(inst, px, py, pz, false)
	KingSquidSyncLeapAmphibious(inst, px, py, pz)
	if t >= 1 then
		KingSquidFinishParabolicLeap(inst)
	end
end

local function KingSquidEndLeapMotor(inst)
	if inst.sg ~= nil and inst.sg.statemem ~= nil then
		inst.sg.statemem.leap_arc_active = false
		inst.sg.statemem.leap_arc_start = nil
		inst.sg.statemem.leap_landpos = nil
		inst.sg.statemem.startpos = nil
	end
	inst.AnimState:SetDeltaTimeMultiplier(1)
	inst.Physics:Stop()
	inst.Physics:ClearMotorVelOverride()
	KingSquidRestorePhysics(inst)
	if inst.components.locomotor ~= nil then
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
	end
end

KingSquidSlideAttackLand = function(inst)
	if inst.sg ~= nil and inst.sg.statemem.leap_landed then
		return
	end
	if inst.sg ~= nil then
		inst.sg.statemem.leap_landed = true
	end
	local lp = inst.sg.statemem.leap_landpos
	if lp ~= nil then
		KingSquidSetLeapWorldPos(inst, lp.x, lp.y, lp.z, true)
	end
	KingSquidEndLeapMotor(inst)
	KingSquidSyncAmphibiousFromTerrain(inst)
	local t = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	inst.sg.statemem.target = t
	inst.sg:GoToState("king_squid_melee", { target = t, from_leap = true })
end

local function KingSquidRefreshMeleeFacing(inst)
	local target = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	if target == nil then
		return
	end
	inst.sg.statemem.target = target
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
end

local function KingSquidMeleeEndSlide(inst)
	KingSquidMeleeClearSlideTask(inst)
	if inst.sg == nil or inst.sg.currentstate.name ~= "king_squid_melee" then
		return
	end
	inst.components.locomotor:Stop()
	inst.Physics:ClearMotorVelOverride()
	inst.components.locomotor:EnableGroundSpeedMultiplier(true)
end

local function KingSquidMeleeSlideTick(inst)
	if inst.sg == nil or inst.sg.currentstate.name ~= "king_squid_melee" then
		KingSquidMeleeEndSlide(inst)
		return
	end
	local vel = inst._king_squid_melee_slide_vel
	if vel == nil then
		KingSquidMeleeEndSlide(inst)
		return
	end
	local dt = FRAMES
	local decay = TUNING.KING_SQUID_MELEE_SLIDE_DECAY or 10
	vel = vel * math.max(0, 1 - decay * dt)
	if vel < 0.06 then
		KingSquidMeleeEndSlide(inst)
		return
	end
	inst._king_squid_melee_slide_vel = vel
	inst.Physics:SetMotorVelOverride(vel, 0, 0)
end

-- 每一击：65 物理 + 20 位面；朝向目标、DoAttack、短距离朝前滑；第三击命中玩家一律击飞（含 AOE 溅射）
local function KingSquidMeleeHit(inst, hit_idx, is_final)
	if not KingSquidIsKing(inst) then
		return
	end
	if KingSquidIsElectrocuted(inst) then
		return
	end
	local t = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	if t == nil or inst.components.combat == nil then
		return
	end
	inst.sg.statemem.target = t
	KingSquidRefreshMeleeFacing(inst)
	KingSquidMeleeClearSlideTask(inst)
	KingSquidMeleeClearCarryTask(inst)
	local combat = inst.components.combat
	local weapon = combat:GetWeapon()
	if is_final then
		inst._king_squid_melee_kb_pending = {}
		inst._king_squid_melee_kb_applied = {}
		local function on_hit_other(i, data)
			if i._king_squid_melee_hit_idx ~= 3 then
				return
			end
			if KingSquidPlayerTookMeleeDamage(data) then
				KingSquidQueueFinalMeleeKnockback(i, data.target)
				KingSquidFlushFinalMeleeKnockbacks(i)
			end
		end
		inst:ListenForEvent("onhitother", on_hit_other)
		inst._king_squid_melee_onhitother_fn = on_hit_other
	end
	inst._king_squid_melee_hit_idx = hit_idx
	combat:DoAttack(t, weapon)
	if is_final then
		local on_hit_other = inst._king_squid_melee_onhitother_fn
		-- onhitotherfn 同步收集；onhitother 事件 + 延迟刷新覆盖洞穴分线/网络延迟
		local function flush_kb(i)
			if i == nil or not i:IsValid() then
				return
			end
			KingSquidFlushFinalMeleeKnockbacks(i)
		end
		flush_kb(inst)
		inst:DoTaskInTime(0, flush_kb)
		inst:DoTaskInTime(4 * FRAMES, function(i)
			flush_kb(i)
			if on_hit_other ~= nil and i ~= nil and i:IsValid() then
				i:RemoveEventCallback("onhitother", on_hit_other)
			end
			if i ~= nil then
				i._king_squid_melee_onhitother_fn = nil
			end
			KingSquidClearFinalMeleeKnockbackState(i)
		end)
	else
		inst._king_squid_melee_hit_idx = nil
	end
	if hit_idx == 1 and inst.sounds ~= nil then
		inst.SoundEmitter:PlaySound(inst.sounds.attack)
	end
	-- 末段旋转起不应再前移：原版第三击仅 locomotor:Stop，不再 SetMotorVelOverride
	if is_final then
		KingSquidMeleeClearSlideTask(inst)
		inst.components.locomotor:Stop()
		inst.Physics:ClearMotorVelOverride()
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
	else
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		local cm = inst.king_squid_scale_mult or 1
		local spd = (TUNING.KING_SQUID_MELEE_PER_HIT_SLIDE or 7.2) * cm
		inst._king_squid_melee_slide_vel = spd
		inst.Physics:SetMotorVelOverride(spd, 0, 0)
		local prev_slide = inst._king_squid_melee_slide_task
		if prev_slide ~= nil then
			prev_slide:Cancel()
		end
		local slide_time = TUNING.KING_SQUID_MELEE_HIT_SLIDE_TIME or 0.28
		inst._king_squid_melee_slide_task = inst:DoPeriodicTask(0, KingSquidMeleeSlideTick)
		inst:DoTaskInTime(slide_time, function(i)
			if i._king_squid_melee_slide_task ~= nil then
				KingSquidMeleeEndSlide(i)
			end
		end)
	end
end

local function KingSquidApplyInkBurstCooldown(inst)
	if inst.components.timer ~= nil then
		local lo = TUNING.KING_SQUID_INK_COOLDOWN_MIN or 2.4
		local hi = TUNING.KING_SQUID_INK_COOLDOWN_MAX or 3.2
		if hi < lo then
			hi = lo
		end
		inst.components.timer:StopTimer("ink_cooldown")
		inst.components.timer:StartTimer("ink_cooldown", lo + math.random() * (hi - lo))
	end
end

local function KingSquidGetInkSpreadRadius(inst, target)
	local sm = inst.king_squid_scale_mult or SCALE
	local sx, _, sz = inst.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - sx, tz - sz
	local dist = math.sqrt(dx * dx + dz * dz)
	local r = (TUNING.KING_SQUID_INK_SPREAD_RADIUS or 3.5)
		+ dist * (TUNING.KING_SQUID_INK_SPREAD_RADIUS_PER_DIST or 0.12)
	r = math.min(r, TUNING.KING_SQUID_INK_SPREAD_RADIUS_MAX or 10)
	return r * sm
end

-- 单次齐射：落点圆心在玩家身前（逃跑/面向方向），勿沿鱿王方向往回偏（会落太近）
local function KingSquidGetInkBurstCenter(inst, target)
	local tx, ty, tz = target.Transform:GetWorldPosition()
	local sx, _, sz = inst.Transform:GetWorldPosition()
	local fx, fz = KingSquidGetLeapLandOffsetDir(inst, target, sx, sz, tx, tz)
	local bias = TUNING.KING_SQUID_INK_SPREAD_FORWARD_BIAS or 0.35
	local bias_max = TUNING.KING_SQUID_INK_SPREAD_FORWARD_BIAS_MAX or 10
	if bias > bias_max then
		bias = bias_max
	end
	local cx = tx + fx * bias
	local cz = tz + fz * bias
	local cy = KingSquidGetLeapGroundY(cx, ty, cz)
	return cx, cy, cz
end

local function KingSquidInkBurstFireWave(inst)
	if inst.LaunchProjectile == nil then
		return
	end
	local target = inst.sg.statemem.target
	if target == nil and inst.components.combat ~= nil then
		target = inst.components.combat.target
	end
	if target == nil or not target:IsValid() then
		return
	end
	local count = TUNING.KING_SQUID_INK_BURST_COUNT or 8
	local spread_r = KingSquidGetInkSpreadRadius(inst, target)
	local angle_step = (2 * PI) / count
	local angle_base = math.random() * angle_step
	local bx, by, bz = KingSquidGetInkBurstCenter(inst, target)
	for idx = 1, count do
		local angle = angle_base + (idx - 1) * angle_step
		local ring_min = TUNING.KING_SQUID_INK_SPREAD_RING_MIN or 0.42
		local ring_rand = TUNING.KING_SQUID_INK_SPREAD_RING_RAND or 0.36
		local ring = spread_r * (ring_min + math.random() * ring_rand)
		local lx = bx + math.cos(angle) * ring
		local lz = bz - math.sin(angle) * ring
		local ly = KingSquidGetLeapGroundY(lx, by, lz)
		inst:LaunchProjectile(Vector3(lx, ly, lz))
	end
end

local function KingSquidInkBurstSpawnProjectiles(inst)
	KingSquidInkBurstFireWave(inst)
end

local function KingSquidGoSlideAttack(inst, target)
	if KingSquidTryEnterPendingDoubleTaunt(inst) then
		return true
	end
	target = KingSquidResolveCombatTarget(inst, target)
	if target == nil then
		return false
	end
	if KingSquidIsFrozen(inst) or KingSquidIsElectrocuted(inst) then
		return false
	end
	local dist = KingSquidDistToTarget(inst, target)
	local leap_r = KingSquidGetLeapChaseRange(inst, target)
	if dist > leap_r then
		if inst.components.locomotor ~= nil then
			local stop = leap_r * 0.65
			local water_dest = KingSquidGetWaterEntryDest(inst, target)
			if water_dest ~= nil and not inst:HasTag("swimming") then
				inst.components.locomotor:GoToPoint(water_dest, nil, stop)
			else
				inst.components.locomotor:GoToEntity(target, nil, stop)
			end
		end
		inst.sg:GoToState("idle")
		return true
	end
	local stand_off = KingSquidGetLungeStandOff(inst)
	if dist <= ATTACK_RANGE + math.max(0, stand_off) then
		inst.sg:GoToState("king_squid_melee", { target = target })
		return true
	end
	inst.sg:GoToState("king_squid_slide_attack", target)
	return true
end

AddStategraphState("squid", State({
	name = "king_squid_retreat_leap",
	tags = { "busy", "jumping", "nointerrupt", "nofreeze", "nosleep", "canelectrocute" },
	onenter = function(inst, threat)
		inst.sg.statemem.target = threat
		local thr_save = threat
		if thr_save == nil or not thr_save:IsValid() then
			if inst.components.combat ~= nil then
				thr_save = inst.components.combat.target
			end
		end
		inst._king_squid_retreat_threat = thr_save ~= nil and thr_save:IsValid() and thr_save or nil
		local ix, iy, iz = inst.Transform:GetWorldPosition()
		local ax, ay, az = ix, iy, iz
		local src = threat
		if src == nil or not src:IsValid() then
			if inst.components.combat ~= nil then
				src = inst.components.combat.target
			end
		end
		if src ~= nil and src:IsValid() then
			ax, ay, az = src.Transform:GetWorldPosition()
		end
		local dx, dz = ix - ax, iz - az
		local len = math.sqrt(dx * dx + dz * dz)
		if len < 0.15 then
			local facing = inst.Transform:GetRotation() * DEGREES
			dx = math.cos(facing)
			dz = -math.sin(facing)
		else
			dx = dx / len
			dz = dz / len
		end
		inst:ForceFacePoint(ix + dx, iy, iz + dz)
		if inst:IsOnOcean() then
			inst.fling_land = false
		else
			inst.fling_land = true
		end
		if not inst:HasTag("swimming") then
			inst.SoundEmitter:PlaySound("hookline/creatures/squid/land")
		end
		inst.AnimState:PlayAnimation("jump")
		inst.AnimState:SetFrame(5)
		inst.AnimState:PushAnimation("jump_loop", false)
		inst.components.locomotor:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.Physics:SetMotorVelOverride(TUNING.KING_SQUID_RETREAT_SPEED or 14, 0, 0)
		inst.Physics:SetCollisionMask(COLLISION.GROUND)
		inst.sg:SetTimeout(TUNING.KING_SQUID_RETREAT_TIME or 0.58)
	end,
	onupdate = function(inst)
		local ac = inst.components.amphibiouscreature
		if ac == nil then
			return
		end
		if inst:IsOnOcean() then
			if inst.fling_land then
				ac:OnEnterOcean()
				inst.fling_land = false
			end
		elseif not inst.fling_land then
			ac:OnExitOcean()
			inst.fling_land = true
		end
	end,
	ontimeout = function(inst)
		inst.fling_land = nil
		inst.Physics:Stop()
		inst.Physics:ClearMotorVelOverride()
		KingSquidRestorePhysics(inst)
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		local ax, ay, az = inst.Transform:GetWorldPosition()
		inst._king_squid_retreat_anchor = Vector3(ax, ay, az)
		local calm = TUNING.KING_SQUID_POST_RETREAT_PANIC or 3
		inst._king_squid_panic_until = GetTime() + calm
		inst:DoTaskInTime(calm, function(i)
			if not i:IsValid() then
				return
			end
			i._king_squid_panic_until = nil
			i._king_squid_retreat_anchor = nil
			i._king_squid_retreat_threat = nil
		end)
		inst.sg:GoToState("idle")
	end,
	onexit = function(inst)
		KingSquidClearRetreatLeapMotor(inst)
	end,
}))

AddStategraphState("squid", State({
	name = "king_squid_slide_attack",
	tags = { "attack", "busy", "jumping" },
	onenter = function(inst, target)
		inst.sg.statemem.targetpos = nil
		inst.sg.statemem.leap_landed = false
		inst.sg.statemem.leap_arc_active = false
		inst.sg.statemem.leap_arc_start = nil
		inst.sg.statemem.target = KingSquidResolveCombatTarget(inst, target)
		if inst:IsOnOcean() then
			inst.fling_land = false
		else
			inst.fling_land = true
		end
		inst.Physics:Stop()
		inst.Physics:ClearMotorVelOverride()
		inst:StopBrain(KING_SQUID_SLIDE_BRAIN)
		if not inst:HasTag("swimming") then
			inst.SoundEmitter:PlaySound("hookline/creatures/squid/land")
		end
		inst.components.locomotor:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		local cross_water = inst.sg.statemem.target ~= nil
			and KingSquidNeedsCrossWaterApproach(inst, inst.sg.statemem.target)
		if cross_water or inst:HasTag("swimming") or inst:IsOnOcean() then
			inst.Physics:SetCollisionMask(COLLISION.GROUND)
		end
		KingSquidSnapLeapTargetPos(inst)
		local leap_target = inst.sg.statemem.target
		local leap_dist = leap_target ~= nil and KingSquidDistToTarget(inst, leap_target) or 999
		local leap_sync = (TUNING.KING_SQUID_LEAP_ANIM_SYNC_TRAVEL or (7 * KING_SQUID_SIZE_MULT))
			* (inst.king_squid_scale_mult or SCALE)
		inst.AnimState:SetDeltaTimeMultiplier(1)
		inst.AnimState:PlayAnimation("jump")
		if leap_dist <= leap_sync + ATTACK_RANGE then
			inst.AnimState:SetFrame(5)
		end
		local jump_len = inst.AnimState:GetCurrentAnimationLength()
		if jump_len == nil or jump_len <= 0 then
			jump_len = TUNING.KING_SQUID_LEAP_JUMP_FALLBACK or (10 * FRAMES)
		end
		inst.AnimState:PushAnimation("jump_loop", false)
		local loop_len = TUNING.KING_SQUID_LEAP_LOOP_FALLBACK or (26 * FRAMES)
		inst.sg.statemem.leap_anim_full = jump_len + loop_len
		local lead = TUNING.KING_SQUID_LEAP_WINDUP or TUNING.KING_SQUID_LUNGE_TARGET_LEAD or 0.18
		if lead > 0 then
			inst:DoTaskInTime(lead, function(i)
				if i:IsValid() then
					KingSquidSnapLeapTargetPos(i)
				end
			end)
		end
		KingSquidStartParabolicLeapArc(inst, inst.sg.statemem.leap_anim_full)
		KingSquidCommitLeapAttackCycle(inst)
	end,
	onupdate = function(inst)
		KingSquidUpdateParabolicLeap(inst)
	end,
	ontimeout = function(inst)
		if inst.sg.statemem.leap_arc_active then
			KingSquidFinishParabolicLeap(inst)
		elseif not inst.sg.statemem.leap_landed then
			KingSquidSlideAttackLand(inst)
		end
	end,
	onexit = function(inst)
		inst.AnimState:SetDeltaTimeMultiplier(1)
		inst.fling_land = nil
		if inst.sg ~= nil and inst.sg.currentstate.name ~= "king_squid_melee" then
			KingSquidEndLeapMotor(inst)
		end
		inst:RestartBrain(KING_SQUID_SLIDE_BRAIN)
	end,
}))

local function KingSquidPlayTauntRoarSound(inst)
	if inst.sounds ~= nil and inst.sounds.taunt ~= nil then
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end
end

local function KingSquidAfterLeapAttackRetreat(inst)
	if not KingSquidIsKing(inst) or inst.sg == nil then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	local threat = KingSquidResolveCombatTarget(inst, inst.sg.statemem.target)
	if threat ~= nil then
		inst._king_squid_post_attack_threat = threat
		KingSquidBeginPostAttackRetreat(inst)
	end
	inst.sg:GoToState("idle")
end

local function KingSquidOnLeapAttackComplete(inst)
	if not KingSquidIsKing(inst) then
		return
	end
	KingSquidAfterLeapAttackRetreat(inst)
end

-- 一轮结束（2 跳 + 双重喷墨）→ 双重战吼
local function KingSquidOnInkAttackComplete(inst)
	if not KingSquidIsKing(inst) or inst.sg == nil then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	-- 水中开场喷墨：不进入双重战吼，接着走 2 跳 → 喷墨 → 战吼 循环
	if KingSquidIsInWaterCombat(inst) and not inst._king_squid_water_opening_ink_done then
		inst._king_squid_water_opening_ink_done = true
		KingSquidClearPendingDoubleTaunt(inst)
		inst.sg:GoToState("idle")
		return
	end
	inst._king_squid_pending_double_taunt = true
	inst.sg:GoToState("king_squid_double_taunt")
end

AddStategraphState("squid", State({
	name = "king_squid_melee",
	tags = { "attack", "busy" },
	onenter = function(inst, data)
		local target
		local from_leap = false
		if type(data) == "table" then
			target = data.target
			from_leap = data.from_leap == true
		else
			target = data
		end
		if KingSquidIsKing(inst) and not from_leap then
			KingSquidCommitLeapAttackCycle(inst)
		end
		inst.sg.statemem.target = KingSquidResolveCombatTarget(inst, target)
		inst.Physics:Stop()
		inst.Physics:ClearMotorVelOverride()
		KingSquidRestorePhysics(inst)
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		if inst.components.combat ~= nil then
			inst.components.combat:StartAttack()
		end
		KingSquidRefreshMeleeFacing(inst)
		if not from_leap and KingSquidIsKing(inst) and inst.Physics ~= nil then
			local cm = TUNING.KING_SQUID_MELEE_ENTRY_CARRY_MULT or 0
			local cf = TUNING.KING_SQUID_MELEE_ENTRY_CARRY_FRAMES or 0
			if cm > 0 and cf > 0 then
				KingSquidMeleeClearCarryTask(inst)
				inst.components.locomotor:Stop()
				inst.components.locomotor:EnableGroundSpeedMultiplier(false)
				local spd = (TUNING.KING_SQUID_MELEE_PER_HIT_SLIDE or 4.2) * cm
				inst.Physics:SetMotorVelOverride(spd, 0, 0)
				inst._king_squid_melee_carry_task = inst:DoTaskInTime(cf * FRAMES, function(i)
					i._king_squid_melee_carry_task = nil
					if i.sg == nil or i.sg.currentstate.name ~= "king_squid_melee" then
						return
					end
					i.Physics:ClearMotorVelOverride()
					i.components.locomotor:EnableGroundSpeedMultiplier(true)
				end)
			end
		end
		inst.AnimState:PlayAnimation("attack")
	end,
	onexit = function(inst)
		KingSquidMeleeClearCarryTask(inst)
		KingSquidMeleeClearSlideTask(inst)
		inst.components.locomotor:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		inst.Physics:ClearMotorVelOverride()
	end,
	timeline = {
		TimeEvent(8 * FRAMES, function(inst)
			if inst:HasTag("swimming") then
				SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
			end
		end),
		TimeEvent(10 * FRAMES, function(inst)
			KingSquidMeleeHit(inst, 1, false)
		end),
		TimeEvent(18 * FRAMES, function(inst)
			KingSquidMeleeHit(inst, 2, false)
		end),
		TimeEvent(26 * FRAMES, function(inst)
			KingSquidMeleeHit(inst, 3, true)
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			KingSquidOnLeapAttackComplete(inst)
		end),
	},
}))

AddStategraphState("squid", State({
	name = "king_squid_double_shoot",
	tags = { "attack", "busy" },
	onenter = function(inst, target)
		target = KingSquidResolveCombatTarget(inst, target)
		if target ~= nil then
			inst.sg.statemem.target = target
		end
		inst.Physics:Stop()
		if target ~= nil then
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
		end
		KingSquidCommitInkAttackCycle(inst)
		inst.AnimState:PlayAnimation("flee")
	end,
	timeline = {
		TimeEvent(7 * FRAMES, function(inst)
			if not KingSquidIsKing(inst) then
				return
			end
			if inst.sounds ~= nil and inst.sounds.spit ~= nil then
				inst.SoundEmitter:PlaySound(inst.sounds.spit)
			end
		end),
		TimeEvent(15 * FRAMES, function(inst)
			if not KingSquidIsKing(inst) then
				return
			end
			if inst.LaunchProjectile ~= nil then
				KingSquidInkBurstFireWave(inst)
			end
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			if not KingSquidIsKing(inst) then
				inst.sg:GoToState("idle")
				return
			end
			inst.sg:GoToState("king_squid_double_shoot2", inst.sg.statemem.target)
		end),
	},
}))

AddStategraphState("squid", State({
	name = "king_squid_double_shoot2",
	tags = { "attack", "busy" },
	onenter = function(inst, target)
		target = KingSquidResolveCombatTarget(inst, target)
		if target ~= nil then
			inst.sg.statemem.target = target
		end
		inst.Physics:Stop()
		if target ~= nil then
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
		end
		inst.AnimState:PlayAnimation("flee")
	end,
	timeline = {
		TimeEvent(7 * FRAMES, function(inst)
			if not KingSquidIsKing(inst) then
				return
			end
			if inst.sounds ~= nil and inst.sounds.spit ~= nil then
				inst.SoundEmitter:PlaySound(inst.sounds.spit)
			end
		end),
		TimeEvent(15 * FRAMES, function(inst)
			if not KingSquidIsKing(inst) then
				return
			end
			if inst.LaunchProjectile ~= nil then
				KingSquidInkBurstFireWave(inst)
			end
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			if not KingSquidIsKing(inst) then
				inst.sg:GoToState("idle")
				return
			end
			KingSquidApplyInkBurstCooldown(inst)
			KingSquidOnInkAttackComplete(inst)
		end),
	},
	onexit = function(inst)
		if not KingSquidNeedsDoubleTaunt(inst) then
			return
		end
		if inst.sg ~= nil and inst.sg.currentstate ~= nil
			and inst.sg.currentstate.name == "king_squid_double_taunt" then
			return
		end
		KingSquidSchedulePendingDoubleTaunt(inst)
	end,
}))

AddStategraphState("squid", State({
	name = "king_squid_engagement_taunt",
	tags = { "busy", "taunt", "nointerrupt" },
	onenter = function(inst, target)
		inst.Physics:Stop()
		target = KingSquidResolveCombatTarget(inst, target)
		if target ~= nil then
			inst.sg.statemem.target = target
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
		end
		inst.AnimState:PlayAnimation("taunt")
	end,
	timeline = {
		TimeEvent(8 * FRAMES, function(inst)
			if KingSquidIsKing(inst) then
				KingSquidPlayTauntRoarSound(inst)
			end
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
}))

AddStategraphState("squid", State({
	name = "king_squid_double_taunt",
	tags = { "busy", "taunt", "nointerrupt" },
	onenter = function(inst)
		inst.Physics:Stop()
		inst.sg.statemem.double_taunt_phase = 1
		inst.AnimState:PlayAnimation("taunt")
	end,
	timeline = {
		TimeEvent(8 * FRAMES, function(inst)
			if not KingSquidIsKing(inst) then
				return
			end
			if (inst.sg.statemem.double_taunt_phase or 1) ~= 1 then
				return
			end
			KingSquidPlayTauntRoarSound(inst)
		end),
	},
	events = {
		EventHandler("animover", function(inst)
			if not KingSquidIsKing(inst) then
				inst.sg:GoToState("idle")
				return
			end
			local p = inst.sg.statemem.double_taunt_phase or 1
			if p == 1 then
				inst.sg.statemem.double_taunt_phase = 2
				inst.AnimState:PlayAnimation("taunt")
				inst._king_squid_taunt2_snd = inst:DoTaskInTime(8 * FRAMES, function(i)
					i._king_squid_taunt2_snd = nil
					if not i:IsValid() or i.sg == nil or i.sg.currentstate.name ~= "king_squid_double_taunt" then
						return
					end
					KingSquidPlayTauntRoarSound(i)
				end)
			else
				inst._king_squid_post_attack_threat = nil
				KingSquidClearPendingDoubleTaunt(inst)
				KingSquidResetAttackCycle(inst)
				KingSquidTryPickNewTargetAfterDoubleTaunt(inst)
				inst.sg:GoToState("idle")
			end
		end),
	},
	onexit = function(inst)
		local t = inst._king_squid_taunt2_snd
		if t ~= nil then
			t:Cancel()
			inst._king_squid_taunt2_snd = nil
		end
	end,
}))

-- 须在 AddStategraphPostInit 之前定义，否则 doattack 闭包会查全局 nil
local function KingSquidChoosePlayerAttack(inst, target)
	if not KingSquidIsKing(inst) or not KingSquidCanCombat(inst) then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if KingSquidTryEnterPendingDoubleTaunt(inst) then
		return true
	end
	if inst.sg:HasStateTag("busy")
		and not (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) then
		return true
	end
	target = KingSquidResolveCombatTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	local combat = inst.components.combat
	if combat ~= nil and combat.target ~= target then
		combat:SetTarget(target)
	end
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	-- 水中开场喷墨仅在新目标时由 OnNewTarget 初始化，勿在附身普攻里反复 KingSquidBeginWaterOpeningInk
	local on_ink_cd = inst.components.timer ~= nil
		and inst.components.timer:TimerExists("ink_cooldown")
	local want_ink = false
	if not on_ink_cd then
		if KingSquidWantsWaterOpeningInk(inst) then
			want_ink = true
		elseif (inst._king_squid_leaps_since_ink or 0) >= (TUNING.KING_SQUID_LEAPS_PER_INK or 2) then
			want_ink = true
		end
	end
	if want_ink and KingSquidCanInkAtTarget(inst, target) and KingSquidCanStartRangedAttack(inst) then
		inst.sg:GoToState("king_squid_double_shoot", target)
		return true
	end
	return KingSquidGoSlideAttack(inst, target)
end

AddStategraphPostInit("squid", function(sg)
	-- 鱿王不吃鱼、不咬钩
	local eat = sg.actionhandlers[ACTIONS.EAT]
	if eat ~= nil then
		local old_eat = eat.deststate
		eat.deststate = function(inst, action)
			if KingSquidIsKing(inst) then
				return nil
			end
			return old_eat(inst, action)
		end
	end

	-- 鱿王喷墨：king_squid_double_shoot，flee 播完进入攻击循环结算 + ink_cooldown
	local toss = sg.actionhandlers[ACTIONS.TOSS]
	if toss ~= nil then
		local old_toss = toss.deststate
		toss.deststate = function(inst, action)
			if KingSquidIsKing(inst) and not inst.sg:HasStateTag("busy") then
				inst.sg:GoToState("king_squid_double_shoot", action.target)
				return
			end
			return old_toss(inst, action)
		end
	end

	local attacked = sg.events.attacked
	if attacked ~= nil then
		local old_attacked = attacked.fn
		attacked.fn = function(inst, data)
			if KingSquidIsKing(inst) and inst.sg.currentstate ~= nil then
				local state = inst.sg.currentstate.name
				if state == "king_squid_retreat_leap" then
					if KingSquidTryBreakRetreatWithElectrocute(inst, data) then
						return
					end
					return
				end
				if state == "king_squid_engagement_taunt"
					or state == "king_squid_double_taunt" then
					if KingSquidIsElectricHit(data) and CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
						return
					end
					return
				end
			end
			if KingSquidIsKing(inst) and KingSquidIsElectricHit(data) then
				if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
					return
				end
			end
			if KingSquidIsKing(inst) and not KingSquidCanTriggerHitstun(inst) then
				if inst.sg ~= nil and inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute") then
					inst.sg:GoToState("idle")
				end
				return
			end
			old_attacked(inst, data)
		end
	end

	local doattack = sg.events.doattack
	if doattack ~= nil then
		local old_doattack = doattack.fn
		doattack.fn = function(inst, data)
			if KingSquidIsKing(inst) and KingSquidCanCombat(inst) then
				if KingSquidTryEnterPendingDoubleTaunt(inst) then
					return
				end
				local target = data ~= nil and data.target or nil
				if KingSquidIsPlayerControlled(inst) then
					if KingSquidChoosePlayerAttack(inst, target) then
						return
					end
				end
				if KingSquidTryInkBeforeLeap(inst, target) then
					return
				end
				KingSquidGoSlideAttack(inst, target)
				return
			end
			old_doattack(inst, data)
		end
	end

	local doink = sg.events.doink
	if doink ~= nil then
		local old_doink = doink.fn
		doink.fn = function(inst, data)
			if KingSquidIsKing(inst) then
				if not inst.components.health:IsDead()
					and ((inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) or not inst.sg:HasStateTag("busy")) then
					inst.sg:GoToState("king_squid_double_shoot", data ~= nil and data.target or nil)
				end
				return
			end
			old_doink(inst, data)
		end
	end

	local attack = sg.states.attack
	if attack ~= nil and attack.onenter ~= nil then
		local old_attack_enter = attack.onenter
		attack.onenter = function(inst, target)
			if KingSquidIsKing(inst) then
				if KingSquidIsPlayerControlled(inst) then
					if KingSquidChoosePlayerAttack(inst, target) then
						return
					end
				end
				if KingSquidTryInkBeforeLeap(inst, target) then
					return
				end
				KingSquidGoSlideAttack(inst, target)
				return
			end
			old_attack_enter(inst, target)
		end
	end
end)

AddPrefabPostInit("king_squid", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst._king_squid_electrocute_clear_patched then
		return
	end
	inst._king_squid_electrocute_clear_patched = true
	inst:ListenForEvent("electrocute", function(i, data)
		if not i:IsValid() then
			return
		end
		if i.sg ~= nil
			and i.sg.currentstate ~= nil
			and i.sg.currentstate.name == "king_squid_retreat_leap" then
			KingSquidClearRetreatLeapMotor(i)
			if i.sg:HasState("electrocute") then
				i.sg:GoToState("electrocute", data)
			end
		end
		KingSquidMeleeClearSlideTask(i)
		KingSquidMeleeClearCarryTask(i)
		if i.components.locomotor ~= nil then
			i.components.locomotor:Stop()
			i.Physics:ClearMotorVelOverride()
			i.components.locomotor:EnableGroundSpeedMultiplier(true)
		end
	end)
end)

-- 附身操控：统一走 doattack，与 AI 大脑触发相同逻辑
local function KingSquidPerformPlayerAttack(inst, target)
	if not KingSquidIsKing(inst) or not inst:IsValid() then
		return false
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.components.combat == nil then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("busy")
		and not (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) then
		return true
	end
	if not KingSquidCanCombat(inst) then
		return false
	end
	target = KingSquidResolveCombatTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	local p2 = inst.Poss2
	if p2 ~= nil then
		local now = GetTime()
		if p2.LastAttackTime ~= nil and (now - p2.LastAttackTime) < 0.45 then
			return true
		end
		p2.LastAttackTime = now
	end
	if inst.components.combat:InCooldown() then
		inst.components.combat:ResetCooldown()
	end
	return KingSquidChoosePlayerAttack(inst, target)
end

-- Poss2 在本 mod 之后加载；延迟一帧再包 playercontroller，确保包住 Poss2 的外层 hook
local function KingSquidInstallPossessAttackHook()
	local _roge_special_attacks = rawget(GLOBAL, "SPECIAL_ATTACKS_CONFIG") or {}
	_roge_special_attacks["king_squid"] = { event = "doattack" }
	rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)

	local function WrapPossessPlayerController(pc)
		if pc == nil or pc._king_squid_poss_attack_hook then
			return
		end
		pc._king_squid_poss_attack_hook = true
		local _OnRemoteControllerAttackButton = pc.OnRemoteControllerAttackButton
		pc.OnRemoteControllerAttackButton = function(controller, target, isreleased, noforce)
			local player = controller.inst
			if player ~= nil and player.Poss2 ~= nil and player.Poss2.Possessing ~= nil
				and target ~= nil and target:IsValid() then
				local possessed = player.Poss2.Possessing
				if possessed.prefab == "king_squid"
					and KingSquidPerformPlayerAttack(possessed, target) then
					return
				end
			end
			return _OnRemoteControllerAttackButton(controller, target, isreleased, noforce)
		end
	end

	AddComponentPostInit("playercontroller", WrapPossessPlayerController)
	if GLOBAL.AllPlayers ~= nil then
		for _, player in ipairs(GLOBAL.AllPlayers) do
			WrapPossessPlayerController(player.components.playercontroller)
		end
	end
end

AddSimPostInit(function()
	if TheWorld ~= nil and TheWorld.ismastersim then
		TheWorld:DoTaskInTime(0, KingSquidInstallPossessAttackHook)
	else
		KingSquidInstallPossessAttackHook()
	end
end)
