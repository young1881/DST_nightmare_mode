-- roge/crab_knight.lua
-- 弱怪池蟹骑士：满宝石属性、头顶寄生加农炮、强化旋转攻击

local easing = require("easing")

local ROGE_CRABKNIGHT_MAXGEM_PURPLE = 11
local ROGE_CRABKNIGHT_WEAK_HEALTH = 800
local ROGE_CRABKNIGHT_SCALE = 1.85
local ROGE_CRABKNIGHT_VANILLA_SCALE = 1.7

-- 旋转攻击：略大于原版范围；近战距离仅随模型缩放，不再额外乘 1.35
local ROGE_CRABKNIGHT_SPIN_AOE_DIST = -0.4
local ROGE_CRABKNIGHT_SPIN_AOE_RADIUS = 2.5
local ROGE_CRABKNIGHT_SPIN_AOE_PADDING = 3
local ROGE_CRABKNIGHT_ATTACK_PERIOD_MULT = 0.5
local ROGE_CRABKNIGHT_SPIN_KNOCKBACK_RADIUS = 2.8
local ROGE_CRABKNIGHT_SPIN_KNOCKBACK_STRENGTH = 1.6
local ROGE_CRABKNIGHT_SPIN_LOOP_DURATION = 1.2

local function RogeGetCrabKnightScaleRatio()
	return ROGE_CRABKNIGHT_SCALE / ROGE_CRABKNIGHT_VANILLA_SCALE
end

-- 爪击命中/AI 开攻距离：原版骑士 4.5，仅随模型放大。
local function RogeGetCrabKnightMeleeRange()
	return TUNING.CRABKING_MOB_KNIGHT_ATTACK_RANGE * RogeGetCrabKnightScaleRatio()
end

-- 旋转触发：原版 largecreature 用 MELEE_RANGE(3)，缩放后约 3.2。
local function RogeGetCrabKnightSpinTriggerRange()
	return TUNING.CRABKING_MOB_MELEE_RANGE * RogeGetCrabKnightScaleRatio()
end

local ROGE_SPIN_AOE_MUST_TAGS = { "_combat" }
local ROGE_SPIN_AOE_CANT_TAGS = {
	"crabking_ally", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost",
}
local ROGE_CRABKNIGHT_CANNON_SYMBOL = "cc_bod"
local ROGE_CRABKNIGHT_CANNON_BASE_SYMBOL = "leak_part"
local ROGE_CRABKNIGHT_CROWN_ABOVE_BOD = 2.05
local ROGE_CRABKNIGHT_CANNON_SCALE = 0.8
local ROGE_PARASITE_CANNON_SHOT_COUNT = 3
-- 与鱿鱼王喷墨同量级：远距索敌 + 弹道可飞满程
local ROGE_PARASITE_CANNON_CAST_RANGE = 30
local ROGE_PARASITE_CANNON_SPEED_NEAR = 15
local ROGE_PARASITE_CANNON_SPEED_FAR = 6
local ROGE_PARASITE_CANNON_SPLASH_RADIUS = TILE_SCALE
local ROGE_PARASITE_CANNON_GRAVITY = -40

local ROGE_PARASITE_CANNON_TARGET_CANT = {
	"FX", "NOCLICK", "DECOR", "INLIMBO", "noattack", "crabking_ally", "playerghost",
}
local _roge_spawning_parasite_cannon = false
local function RogeIsCrabKnight(inst)
	return inst ~= nil and inst:IsValid() and inst:HasTag("crab_mob_knight")
end

local function RogeCalcCrabKnightMaxGemHealth(purple_count)
	local health = TUNING.CRABKING_MOB_KNIGHT_HEALTH
	local increment = 20
	if purple_count > 4 then
		increment = 30
	end
	if purple_count > 7 then
		increment = 40
	end
	health = health + purple_count * increment
	if purple_count >= 11 then
		health = health + TUNING.CRABKING_MOB_HEALTH_BONUS_MAXGEM
	end
	return health
end

local function RogeCalcCrabKnightMaxGemSleepResistance(purple_count)
	local resistance = 2
	if purple_count > 4 then
		resistance = resistance + 10
	end
	if purple_count > 7 then
		resistance = resistance + 10
	end
	return resistance + 10
end

local function RogeApplyCrabKnightCommonCombat(inst)
	if inst.components.combat ~= nil then
		local base_period = TUNING.CRABKING_MOB_ATTACK_PERIOD + math.random() * 2
		inst.components.combat:SetAttackPeriod(base_period * ROGE_CRABKNIGHT_ATTACK_PERIOD_MULT)
		local melee_range = RogeGetCrabKnightMeleeRange()
		inst.components.combat:SetRange(melee_range, melee_range)
	end
end

local function RogeApplyCrabKnightHealth(inst, hp)
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:SetMaxHealth(hp)
		inst.components.health:SetPercent(1)
	end
end

function RogeApplyCrabKnightWeakStats(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "crabking_mob_knight" then
		return
	end
	RogeApplyCrabKnightHealth(inst, ROGE_CRABKNIGHT_WEAK_HEALTH)
	inst.Transform:SetScale(ROGE_CRABKNIGHT_SCALE, ROGE_CRABKNIGHT_SCALE, ROGE_CRABKNIGHT_SCALE)
	if inst.DynamicShadow ~= nil then
		inst.DynamicShadow:SetSize(1.5 * ROGE_CRABKNIGHT_SCALE, 0.5 * ROGE_CRABKNIGHT_SCALE)
	end
	if inst.components.sleeper ~= nil then
		inst.components.sleeper:SetResistance(12)
	end
	RogeApplyCrabKnightCommonCombat(inst)
end

function RogeApplyCrabKnightMaxGemStats(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "crabking_mob_knight" then
		return
	end
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:SetMaxHealth(RogeCalcCrabKnightMaxGemHealth(ROGE_CRABKNIGHT_MAXGEM_PURPLE))
		inst.components.health:SetPercent(1)
	end
	if inst.components.sleeper ~= nil then
		inst.components.sleeper:SetResistance(
			RogeCalcCrabKnightMaxGemSleepResistance(ROGE_CRABKNIGHT_MAXGEM_PURPLE))
	end
	inst.Transform:SetScale(ROGE_CRABKNIGHT_SCALE, ROGE_CRABKNIGHT_SCALE, ROGE_CRABKNIGHT_SCALE)
	if inst.DynamicShadow ~= nil then
		inst.DynamicShadow:SetSize(1.5 * ROGE_CRABKNIGHT_SCALE, 0.5 * ROGE_CRABKNIGHT_SCALE)
	end
	RogeApplyCrabKnightCommonCombat(inst)
end

local function RogeCrabKnightSpinAOE(inst)
	if inst.components.combat == nil then
		return
	end
	inst.components.combat.ignorehitrange = true
	local scale_ratio = RogeGetCrabKnightScaleRatio()
	local x, y, z = inst.Transform:GetWorldPosition()
	local cos_theta = math.cos(inst.Transform:GetRotation() * DEGREES)
	local sin_theta = math.sin(inst.Transform:GetRotation() * DEGREES)
	local dist = ROGE_CRABKNIGHT_SPIN_AOE_DIST * scale_ratio
	x = x + dist * cos_theta
	z = z - dist * sin_theta
	local radius = ROGE_CRABKNIGHT_SPIN_AOE_RADIUS * scale_ratio
	local max_reach = RogeGetCrabKnightMeleeRange() + 0.25
	local max_reach_sq = max_reach * max_reach
	local kx, _, kz = inst.Transform:GetWorldPosition()
	local targets = inst.sg.statemem.targets or {}
	for _, v in ipairs(TheSim:FindEntities(
		x, y, z, radius + ROGE_CRABKNIGHT_SPIN_AOE_PADDING, ROGE_SPIN_AOE_MUST_TAGS, ROGE_SPIN_AOE_CANT_TAGS)) do
		if v ~= inst and not targets[v] and v:IsValid() and not v:IsInLimbo()
			and not (v.components.health and v.components.health:IsDead())
			and inst.components.combat:CanTarget(v) then
			local range = radius + v:GetPhysicsRadius(0)
			local x1, _, z1 = v.Transform:GetWorldPosition()
			local dx, dz = x1 - x, z1 - z
			local dxk, dzk = x1 - kx, z1 - kz
			if dx * dx + dz * dz < range * range
				and dxk * dxk + dzk * dzk <= max_reach_sq then
				inst.components.combat:DoAttack(v)
				targets[v] = true
				if v:HasTag("player") then
					v:PushEventImmediate("knockback", {
						knocker = inst,
						radius = ROGE_CRABKNIGHT_SPIN_KNOCKBACK_RADIUS,
						strengthmult = ROGE_CRABKNIGHT_SPIN_KNOCKBACK_STRENGTH,
						forcelanded = true,
					})
				end
			end
		end
	end
	inst.sg.statemem.targets = targets
	inst.components.combat.ignorehitrange = false
end
local function RogeGetKnightCrownWorldPosDynamic(knight)
	local scale_ratio = RogeGetCrabKnightScaleRatio()
	local bx, by, bz = knight.AnimState:GetSymbolPosition(ROGE_CRABKNIGHT_CANNON_SYMBOL, 0, 0, 0)
	return bx, by + ROGE_CRABKNIGHT_CROWN_ABOVE_BOD * scale_ratio, bz
end

-- 受击/电击/旋转攻击时 cc_bod 会随动画偏移；用实体局部固定偏移避免加农炮错位。
local function RogeCalibrateCannontowerHeadAttach(knight, tower)
	if knight == nil or tower == nil or not knight:IsValid() or not tower:IsValid() then
		return
	end
	local hx, hy, hz = RogeGetKnightCrownWorldPosDynamic(knight)
	local kx, ky, kz = knight.Transform:GetWorldPosition()
	local theta = -knight.Transform:GetRotation() * DEGREES
	local cos_t, sin_t = math.cos(theta), math.sin(theta)
	local dx, dz = hx - kx, hz - kz
	knight._roge_cannon_local_offset = {
		x = dx * cos_t - dz * sin_t,
		y = hy - ky,
		z = dx * sin_t + dz * cos_t,
	}
	local tx, ty, tz = tower.Transform:GetWorldPosition()
	tower._roge_crown_to_root = Vector3(tx - hx, ty - hy, tz - hz)
end

local function RogeGetKnightCrownWorldPos(knight)
	local off = knight._roge_cannon_local_offset
	if off == nil then
		return RogeGetKnightCrownWorldPosDynamic(knight)
	end
	local kx, ky, kz = knight.Transform:GetWorldPosition()
	local theta = knight.Transform:GetRotation() * DEGREES
	local cos_t, sin_t = math.cos(theta), math.sin(theta)
	return kx + off.x * cos_t - off.z * sin_t,
		ky + off.y,
		kz + off.x * sin_t + off.z * cos_t
end

local function RogeAlignTowerBaseToWorldPoint(tower, wx, wy, wz)
	local root_off = tower._roge_crown_to_root
	if root_off ~= nil then
		tower.Transform:SetPosition(wx + root_off.x, wy + root_off.y, wz + root_off.z)
		return
	end
	local bx, by, bz = tower.AnimState:GetSymbolPosition(ROGE_CRABKNIGHT_CANNON_BASE_SYMBOL, 0, 0, 0)
	local tx, ty, tz = tower.Transform:GetWorldPosition()
	tower.Transform:SetPosition(tx + (wx - bx), ty + (wy - by), tz + (wz - bz))
end

local function RogeRemoveCrabKnightCannontower(knight)
	if knight == nil then
		return
	end
	local tower = knight._roge_cannontower
	if tower ~= nil and tower:IsValid() then
		if tower._roge_follow_task ~= nil then
			tower._roge_follow_task:Cancel()
			tower._roge_follow_task = nil
		end
		if tower.reloadtask ~= nil then
			tower.reloadtask:Cancel()
			tower.reloadtask = nil
		end
		tower:Remove()
	end
	knight._roge_cannontower = nil
	knight._roge_cannon_local_offset = nil
end

local function RogeStubParasiteCannontowerFloater(tower)
	if tower.components.floater == nil then
		return
	end
	tower.components.floater.OnLandedServer = function() end
	tower.components.floater.OnNoLongerLandedServer = function() end
end

local function RogeDisableParasiteCannontowerFloater(tower)
	if tower._roge_vanilla_onsink ~= nil then
		tower:RemoveEventCallback("onsink", tower._roge_vanilla_onsink)
	end
	if tower._roge_vanilla_oncollide ~= nil then
		tower:RemoveEventCallback("on_collide", tower._roge_vanilla_oncollide)
	end
	tower._OnSink = function() end
	tower._OnCollide = function() end
end

local function RogeIsPlayerCannonTarget(target)
	return target ~= nil and target:IsValid() and target:HasTag("player")
		and not target:HasTag("playerghost")
		and target.components.health ~= nil and not target.components.health:IsDead()
end

local function RogeIsValidCannonTarget(knight, target)
	return RogeIsPlayerCannonTarget(target)
		and knight ~= nil and knight.components.combat ~= nil
		and knight.components.combat:CanTarget(target)
end

local function RogeGetKnightCombatTarget(knight)
	if knight == nil or not knight:IsValid() or knight.components.combat == nil then
		return nil
	end
	local target = knight.components.combat.target
	if not RogeIsValidCannonTarget(knight, target) then
		return nil
	end
	return target
end

local function RogeGetParasiteCannonCastRange()
	return ROGE_PARASITE_CANNON_CAST_RANGE
end

local function RogeIsInParasiteCannonRange(knight, target, cast_range)
	if knight == nil or target == nil or not knight:IsValid() or not target:IsValid() then
		return false
	end
	cast_range = cast_range or RogeGetParasiteCannonCastRange()
	local kx, _, kz = knight.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - kx, tz - kz
	return dx * dx + dz * dz <= cast_range * cast_range
end

local function RogeResolveParasiteCannontowerTarget(tower, knight)
	if knight == nil or not knight:IsValid() then
		return nil
	end

	local cast_range = RogeGetParasiteCannonCastRange()
	local combat_target = RogeGetKnightCombatTarget(knight)
	if combat_target ~= nil and combat_target:HasTag("player")
		and RogeIsInParasiteCannonRange(knight, combat_target, cast_range) then
		return combat_target
	end

	local kx, y, kz = knight.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(
		kx, 0, kz, cast_range, { "player" }, ROGE_PARASITE_CANNON_TARGET_CANT)

	local best, best_dsq
	for _, ent in ipairs(ents) do
		if RogeIsValidCannonTarget(knight, ent)
			and RogeIsInParasiteCannonRange(knight, ent, cast_range) then
			local dsq = knight:GetDistanceSqToInst(ent)
			if best_dsq == nil or dsq < best_dsq then
				best = ent
				best_dsq = dsq
			end
		end
	end

	return best
end

local function RogeSyncCannontowerOnKnightHead(knight, tower)
	if knight == nil or tower == nil or not knight:IsValid() or not tower:IsValid() then
		return
	end
	local hx, hy, hz = RogeGetKnightCrownWorldPos(knight)
	RogeAlignTowerBaseToWorldPoint(tower, hx, hy, hz)
	local target = RogeResolveParasiteCannontowerTarget(tower, knight)
	if target ~= nil then
		tower.Transform:SetRotation(knight:GetAngleToPoint(target.Transform:GetWorldPosition()))
	else
		tower.Transform:SetRotation(knight.Transform:GetRotation())
	end
end

local function RogeApplyCannontowerVisualScale(tower)
	local s = ROGE_CRABKNIGHT_CANNON_SCALE
	tower.Transform:SetScale(s, s, s)
	if tower.AnimState ~= nil then
		tower.AnimState:SetScale(s, s)
	end
end

local function RogeParasiteGetShootTargetPosition(tower, target)
	local x, _, z
	if target ~= nil and target:IsValid() then
		x, _, z = target.Transform:GetWorldPosition()
	else
		x, _, z = tower.Transform:GetWorldPosition()
	end
	local angle = math.random() * TWOPI
	local offset = math.sqrt(math.random()) * ROGE_PARASITE_CANNON_SPLASH_RADIUS
	return Vector3(x + math.cos(angle) * offset, 0, z + math.sin(angle) * offset)
end

local function RogeParasiteGetRandomSplashPosition(cx, cz)
	local angle = math.random() * TWOPI
	local offset = math.sqrt(math.random()) * ROGE_PARASITE_CANNON_SPLASH_RADIUS
	return Vector3(cx + math.cos(angle) * offset, 0, cz + math.sin(angle) * offset)
end

local function RogeParasiteGetBurstLandingPositions(tower, target, count)
	local cx, _, cz
	if target ~= nil and target:IsValid() then
		cx, _, cz = target.Transform:GetWorldPosition()
	else
		cx, _, cz = tower.Transform:GetWorldPosition()
	end
	local positions = { Vector3(cx, 0, cz) }
	for _ = 2, count do
		table.insert(positions, RogeParasiteGetRandomSplashPosition(cx, cz))
	end
	return positions
end

local function RogeCalcParasiteMortarDamage(tower)
	local red = tower.redgemcount or 0
	local damage = TUNING.CRABKING_MORTAR_DAMAGE + red * TUNING.CRABKING_MORTAR_DAMAGE_BONUS
	if red >= ROGE_CRABKNIGHT_MAXGEM_PURPLE then
		damage = damage + TUNING.CRABKING_MORTAR_MAXGEM_DAMAGE_BONUS
	end
	return damage
end

local function RogeParasiteLaunchProjectile(tower, target, targetpos)
	targetpos = targetpos or RogeParasiteGetShootTargetPosition(tower, target)
	local knight = tower._roge_host_knight
	local attacker = (knight ~= nil and knight:IsValid()) and knight or tower
	local x, y, z = tower.AnimState:GetSymbolPosition("cannonball_rock02", 0, 0, 0)
	local projectile = SpawnPrefab("mortarball")
	if projectile == nil then
		return nil
	end

	projectile.Transform:SetPosition(x, y + 0.3, z)
	projectile.redgemcount = tower.redgemcount
	projectile:setdamage(RogeCalcParasiteMortarDamage(tower))

	local cp = projectile.components.complexprojectile
	if cp == nil then
		return projectile
	end

	local dx = targetpos.x - x
	local dz = targetpos.z - z
	local dist = math.sqrt(dx * dx + dz * dz)
	local rangesq = dist * dist
	local maxrange = RogeGetParasiteCannonCastRange()
	-- 近快远慢，远距离用最低命中弹速保底（同鱿鱼王喷墨）
	local speed = easing.linear(
		rangesq,
		ROGE_PARASITE_CANNON_SPEED_NEAR,
		ROGE_PARASITE_CANNON_SPEED_FAR,
		maxrange * maxrange)
	if dist > 0.01 and cp.CalculateMinimumSpeedForDistance ~= nil then
		local min_speed = cp:CalculateMinimumSpeedForDistance(dist)
		if min_speed ~= nil and min_speed > speed then
			speed = min_speed
		end
	end

	-- 高弧线迫击炮：远距仍用弹速保底，保证能落到瞄准点
	cp.usehigharc = true
	cp:SetGravity(ROGE_PARASITE_CANNON_GRAVITY)
	cp:SetHorizontalSpeed(speed)
	cp:Launch(targetpos, attacker, attacker)

	if tower.redgemcount ~= nil then
		local scale = (tower.redgemcount > 7 and 1.3) or (tower.redgemcount < 5 and 0.65) or nil
		if scale ~= nil then
			projectile.AnimState:SetScale(scale, scale)
		end
	end
	return projectile
end

local function RogeParasiteDoShootCannon(tower, ent)
	local landings = RogeParasiteGetBurstLandingPositions(tower, ent, ROGE_PARASITE_CANNON_SHOT_COUNT)
	for shot = 1, ROGE_PARASITE_CANNON_SHOT_COUNT do
		RogeParasiteLaunchProjectile(tower, ent, landings[shot])
	end
	tower:PushEvent("ck_shootcannon")
	if tower.reloadtask ~= nil then
		tower.reloadtask:Cancel()
		tower.reloadtask = nil
	end
	tower:TestForReload()
end

local function RogeParasiteTryShootCannon(tower)
	if not tower.sg:HasStateTag("loaded") then
		if tower.reloadtask == nil then
			tower:StartReloadTask(1)
		end
		return
	end
	local target = RogeResolveParasiteCannontowerTarget(tower, tower._roge_host_knight)
	if target ~= nil then
		return tower:DoShootCannon(target)
	end
	tower:StartReloadTask(2)
end

local function RogeBindParasiteCannontowerCombat(tower)
	if tower._roge_parasite_combat_bound then
		return
	end
	tower._roge_parasite_combat_bound = true
	tower.GetShootTargetPosition = function(inst, ent)
		return RogeParasiteGetShootTargetPosition(inst, ent)
	end
	tower.TryShootCannon = function(inst)
		RogeParasiteTryShootCannon(inst)
	end
	tower.DoShootCannon = function(inst, ent)
		RogeParasiteDoShootCannon(inst, ent)
	end
	tower.LaunchProjectile = function(inst, target)
		return RogeParasiteLaunchProjectile(inst, target)
	end
end

local function RogeStartCannontowerHeadFollow(knight, tower)
	RogeApplyCannontowerVisualScale(tower)
	if tower.MiniMapEntity ~= nil then
		tower.MiniMapEntity:SetEnabled(false)
	end
	RogeSyncCannontowerOnKnightHead(knight, tower)
	RogeCalibrateCannontowerHeadAttach(knight, tower)
	RogeSyncCannontowerOnKnightHead(knight, tower)
	if tower._roge_follow_task ~= nil then
		tower._roge_follow_task:Cancel()
	end
	tower._roge_follow_task = tower:DoPeriodicTask(0, function(t)
		RogeSyncCannontowerOnKnightHead(t._roge_host_knight, t)
	end)
end

function RogeSetupCrabKnightCannontower(knight)
	if knight == nil or not knight:IsValid() or knight.prefab ~= "crabking_mob_knight" then
		return
	end
	if knight._roge_cannontower ~= nil then
		return
	end
	if knight.components.health ~= nil and knight.components.health:IsDead() then
		return
	end

	_roge_spawning_parasite_cannon = true
	local tower = SpawnPrefab("crabking_cannontower")
	_roge_spawning_parasite_cannon = false
	if tower == nil then
		return
	end

	knight._roge_cannontower = tower
	tower._roge_host_knight = knight
	tower._roge_parasite_cannon = true
	tower.persists = false

	RogeStubParasiteCannontowerFloater(tower)
	RogeBindParasiteCannontowerCombat(tower)

	tower.redgemcount = ROGE_CRABKNIGHT_MAXGEM_PURPLE
	tower.yellowgemcount = ROGE_CRABKNIGHT_MAXGEM_PURPLE
	if tower.UpdateMortarArt ~= nil then
		tower:UpdateMortarArt()
	end

	local kx, ky, kz = knight.Transform:GetWorldPosition()
	tower.Transform:SetPosition(kx, ky, kz)

	tower:AddTag("NOCLICK")
	RogeDisableParasiteCannontowerFloater(tower)
	if tower.components.lootdropper ~= nil then
		tower.components.lootdropper:SetLoot({})
		tower.components.lootdropper:SetChanceLootTable(nil)
	end
	if tower.components.health ~= nil then
		tower.components.health:SetInvincible(true)
	end
	if tower.Physics ~= nil then
		RemovePhysicsColliders(tower)
	end

	tower:DoTaskInTime(2 * FRAMES, function(t)
		if not t:IsValid() or not knight:IsValid() or knight._roge_cannontower ~= t then
			return
		end
		RogeStartCannontowerHeadFollow(knight, t)
		if t.components.floater ~= nil then
			t:RemoveComponent("floater")
		end
	end)

	tower:PushEvent("ck_spawn")
end

function RogeSetupCrabKnightRogeExtras(knight)
	if knight == nil or not knight:IsValid() or knight.prefab ~= "crabking_mob_knight" then
		return
	end
	local role = knight._roge_crab_knight_role or "weak"
	if role == "leader" then
		RogeApplyCrabKnightMaxGemStats(knight)
		RogeSetupCrabKnightCannontower(knight)
	elseif role == "follower" then
		RogeApplyCrabKnightWeakStats(knight)
		RogeSetupCrabKnightCannontower(knight)
	else
		RogeApplyCrabKnightWeakStats(knight)
		RogeSetupCrabKnightCannontower(knight)
	end
end

-- 强怪池蟹骑士小队：头领满配 + 2 随从 800 血 + 每骑士 2 蟹卫
ROGE_CRABKNIGHT_SQUAD_KNIGHT_COUNT = 3
ROGE_CRABKNIGHT_SQUAD_FOLLOWER_COUNT = 2
ROGE_CRABKNIGHT_SQUAD_GUARDS_PER_KNIGHT = 2
ROGE_CRABKNIGHT_SQUAD_SPAWN_RADIUS = 5
ROGE_CRABKNIGHT_SQUAD_KNIGHT_RADIUS = 3.5
ROGE_CRABKNIGHT_SQUAD_GUARD_RADIUS = 2

local function RogeIsCrabSquadAlly(ent)
	return ent ~= nil and ent:IsValid()
		and (ent._roge_crab_squad_member or ent:HasTag("crabking_ally"))
end

local function RogeLinkCrabSquadFollower(minion, leader)
	if minion == nil or leader == nil or not minion:IsValid() or not leader:IsValid() then
		return
	end
	minion._roge_crab_squad_leader = leader
	minion._roge_crab_squad_member = true
	local follower = minion.components.follower
	if follower == nil then
		minion:AddComponent("follower")
		follower = minion.components.follower
	end
	if follower ~= nil then
		follower.neverexpire = true
		if follower:GetLeader() ~= leader then
			follower:SetLeader(leader)
		end
	end
	if leader.components.leader ~= nil then
		leader.components.leader:AddFollower(minion)
	end
end

local function RogeEnsureCrabSquadLeaderComponent(leader)
	if leader.components.leader == nil then
		leader:AddComponent("leader")
	end
end

local function RogeResolveCrabSquadCombatTarget(leader, fallback)
	if leader ~= nil and leader:IsValid() and leader.components.combat ~= nil then
		local t = leader.components.combat.target
		if t ~= nil and t:IsValid() and not RogeIsCrabSquadAlly(t) then
			return t
		end
	end
	if fallback ~= nil and fallback:IsValid() and not RogeIsCrabSquadAlly(fallback) then
		return fallback
	end
	return nil
end

local function RogeSyncCrabSquadCombatTarget(leader)
	if leader == nil or not leader:IsValid() then
		return
	end
	local target = RogeResolveCrabSquadCombatTarget(leader, leader._roge_crab_squad_fallback_target)
	if target == nil then
		return
	end
	local members = leader._roge_crab_squad_members
	if members == nil then
		return
	end
	for _, m in ipairs(members) do
		if m ~= nil and m:IsValid() and m.components.combat ~= nil
			and m.components.combat:CanTarget(target) then
			m.components.combat:SetTarget(target)
		end
	end
end

local function RogeEnsureCrabSquadFollow(minion, leader)
	if minion == nil or leader == nil or not minion:IsValid() or not leader:IsValid() then
		return
	end
	if minion.components.health ~= nil and minion.components.health:IsDead() then
		return
	end
	RogeLinkCrabSquadFollower(minion, leader)
	if minion:GetDistanceSqToInst(leader) > 64
		and minion.components.locomotor ~= nil then
		local lp = leader:GetPosition()
		local offset = FindWalkableOffset(lp, math.random() * TWOPI, 3, 8, false, true)
		if offset ~= nil then
			minion.components.locomotor:GoToPoint(lp + offset)
		end
	end
end

local function RogeScheduleCrabSquadFollowCheck(leader)
	if leader._roge_crab_squad_follow_task ~= nil then
		leader._roge_crab_squad_follow_task:Cancel()
		leader._roge_crab_squad_follow_task = nil
	end
	leader._roge_crab_squad_follow_task = leader:DoPeriodicTask(2, function(l)
		if l == nil or not l:IsValid() or l.components.health == nil or l.components.health:IsDead() then
			return
		end
		local members = l._roge_crab_squad_members
		if members == nil then
			return
		end
		for _, m in ipairs(members) do
			local follow_leader = m._roge_crab_squad_knight_leader or l
			RogeEnsureCrabSquadFollow(m, follow_leader)
		end
		for _, knight in ipairs(l._roge_crab_squad_knights or {}) do
			if knight ~= l then
				RogeEnsureCrabSquadFollow(knight, l)
			end
		end
	end)
end

local function RogeSetupCrabSquadLeaderCombat(leader, fallback_target)
	if leader._roge_crab_squad_combat_hooked then
		return
	end
	leader._roge_crab_squad_combat_hooked = true
	leader._roge_crab_squad_fallback_target = fallback_target
	RogeEnsureCrabSquadLeaderComponent(leader)
	if fallback_target ~= nil and fallback_target:IsValid() and leader.components.combat ~= nil then
		leader.components.combat:SetTarget(fallback_target)
	end
	RogeSyncCrabSquadCombatTarget(leader)
	leader:ListenForEvent("newcombattarget", function()
		RogeSyncCrabSquadCombatTarget(leader)
	end)
	leader:ListenForEvent("onattackother", function()
		RogeSyncCrabSquadCombatTarget(leader)
	end)
	leader:ListenForEvent("death", function(l)
		if l._roge_crab_squad_follow_task ~= nil then
			l._roge_crab_squad_follow_task:Cancel()
			l._roge_crab_squad_follow_task = nil
		end
	end)
	RogeScheduleCrabSquadFollowCheck(leader)
end

local function RogeFinalizeCrabKnightSquadMember(inst, role)
	if inst == nil or not inst:IsValid() then
		return
	end
	inst._roge_crab_knight_role = role
	inst._roge_crab_squad_defer_setup = nil
	if inst.prefab == "crabking_mob_knight" then
		RogeSetupCrabKnightRogeExtras(inst)
	elseif inst.prefab == "crabking_mob" then
		inst._roge_crab_squad_member = true
	end
end

function RogeSpawnCrabKnightSquadPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * TWOPI
	local cx = x + math.cos(angle) * ROGE_CRABKNIGHT_SQUAD_SPAWN_RADIUS
	local cz = z + math.sin(angle) * ROGE_CRABKNIGHT_SQUAD_SPAWN_RADIUS
	local fallback_target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		fallback_target = player.components.combat.target
	end

	local leader = SpawnPrefab("crabking_mob_knight")
	if leader == nil then
		return nil
	end
	leader._roge_crab_squad_defer_setup = true
	leader.Transform:SetPosition(cx, y, cz)

	local knights = { leader }
	local members = {}
	local base_angle = math.random() * TWOPI
	for i = 1, ROGE_CRABKNIGHT_SQUAD_FOLLOWER_COUNT do
		local follower = SpawnPrefab("crabking_mob_knight")
		if follower ~= nil then
			follower._roge_crab_squad_defer_setup = true
			local a = base_angle + i * (TWOPI / ROGE_CRABKNIGHT_SQUAD_KNIGHT_COUNT)
			follower.Transform:SetPosition(
				cx + math.cos(a) * ROGE_CRABKNIGHT_SQUAD_KNIGHT_RADIUS,
				y,
				cz + math.sin(a) * ROGE_CRABKNIGHT_SQUAD_KNIGHT_RADIUS)
			table.insert(knights, follower)
		end
	end

	for ki, knight in ipairs(knights) do
		if knight ~= leader then
			knight._roge_crab_squad_knight_leader = leader
			table.insert(members, knight)
		end
		for gi = 1, ROGE_CRABKNIGHT_SQUAD_GUARDS_PER_KNIGHT do
			local guard = SpawnPrefab("crabking_mob")
			if guard ~= nil then
				guard._roge_crab_squad_defer_setup = true
				guard._roge_crab_squad_knight_leader = knight
				local ga = base_angle + (ki - 1) * (TWOPI / ROGE_CRABKNIGHT_SQUAD_KNIGHT_COUNT)
					+ (gi - 0.5) * (PI / ROGE_CRABKNIGHT_SQUAD_GUARDS_PER_KNIGHT)
				local kx, _, kz = knight.Transform:GetWorldPosition()
				guard.Transform:SetPosition(
					kx + math.cos(ga) * ROGE_CRABKNIGHT_SQUAD_GUARD_RADIUS,
					y,
					kz + math.sin(ga) * ROGE_CRABKNIGHT_SQUAD_GUARD_RADIUS)
				table.insert(members, guard)
			end
		end
	end

	leader._roge_crab_squad_knights = knights
	leader._roge_crab_squad_members = members

	for _, knight in ipairs(knights) do
		local role = knight == leader and "leader" or "follower"
		RogeFinalizeCrabKnightSquadMember(knight, role)
	end
	for _, guard in ipairs(members) do
		if guard.prefab == "crabking_mob" then
			RogeFinalizeCrabKnightSquadMember(guard, nil)
			RogeLinkCrabSquadFollower(guard, guard._roge_crab_squad_knight_leader)
		end
	end
	for _, knight in ipairs(knights) do
		if knight ~= leader then
			RogeLinkCrabSquadFollower(knight, leader)
		end
	end
	RogeSetupCrabSquadLeaderCombat(leader, fallback_target)
	if RogeMarkDiceSummonDeep ~= nil then
		RogeMarkDiceSummonDeep(leader)
	end
	return leader
end

-- 蟹骑士：禁 hit / taunt；强化 spin_attack（更远、更大范围、击退玩家）
AddStategraphPostInit("crabking_mob", function(sg)
	local attacked = sg.events["attacked"]
	if attacked ~= nil then
		local old_attacked_fn = attacked.fn
		attacked.fn = function(inst, data)
			if RogeIsCrabKnight(inst) then
				if inst.components.health:IsDead() then
					return
				end
				if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
					return
				end
				return
			end
			return old_attacked_fn(inst, data)
		end
	end

	local doattack = sg.events["doattack"]
	if doattack ~= nil then
		local old_doattack_fn = doattack.fn
		doattack.fn = function(inst, data)
			if RogeIsCrabKnight(inst) then
				if inst.sg:HasStateTag("busy") or inst.components.health:IsDead() then
					return
				end
				if data ~= nil and data.target ~= nil and data.target:IsValid() then
					local use_spin = not inst:IsNear(data.target, RogeGetCrabKnightSpinTriggerRange())
					inst.sg:GoToState(use_spin and "spin_attack" or "attack", data.target)
				end
				return
			end
			return old_doattack_fn(inst, data)
		end
	end

	local taunt = sg.states["taunt"]
	if taunt ~= nil then
		local old_taunt_onenter = taunt.onenter
		taunt.onenter = function(inst, ...)
			if RogeIsCrabKnight(inst) then
				inst.sg:GoToState("idle")
				return
			end
			return old_taunt_onenter(inst, ...)
		end
	end

	local spin_loop = sg.states["spin_attack_loop"]
	if spin_loop ~= nil then
		local old_spin_onenter = spin_loop.onenter
		spin_loop.onenter = function(inst, targets)
			if old_spin_onenter ~= nil then
				old_spin_onenter(inst, targets)
			end
			if RogeIsCrabKnight(inst) then
				inst.sg:SetTimeout(ROGE_CRABKNIGHT_SPIN_LOOP_DURATION)
			end
		end
		local old_spin_onupdate = spin_loop.onupdate
		spin_loop.onupdate = function(inst, dt)
			if RogeIsCrabKnight(inst) then
				RogeCrabKnightSpinAOE(inst)
			elseif old_spin_onupdate ~= nil then
				old_spin_onupdate(inst, dt)
			end
		end
	end

	local spin_pst = sg.states["spin_attack_pst"]
	if spin_pst ~= nil and spin_pst.events ~= nil and spin_pst.events["animover"] ~= nil then
		spin_pst.events["animover"].fn = function(inst)
			if inst.AnimState:AnimDone() then
				if RogeIsCrabKnight(inst) then
					inst.sg:GoToState("idle")
				else
					inst.sg:GoToState("taunt")
				end
			end
		end
	end

	local idle = sg.states["idle"]
	if idle ~= nil then
		local old_idle_timeout = idle.ontimeout
		idle.ontimeout = function(inst)
			if RogeIsCrabKnight(inst) then
				inst.sg:GoToState("idle")
				return
			end
			if old_idle_timeout ~= nil then
				return old_idle_timeout(inst)
			end
			inst.sg:GoToState("taunt")
		end
	end
end)

AddPrefabPostInit("crabking_mob_knight", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		if inst._roge_crab_squad_defer_setup then
			return
		end
		if inst._roge_crab_knight_role == nil then
			inst._roge_crab_knight_role = "weak"
		end
		RogeSetupCrabKnightRogeExtras(inst)
	end)
	inst:ListenForEvent("death", RogeRemoveCrabKnightCannontower)
end)

AddPrefabPostInit("crabking_cannontower", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst._roge_vanilla_onsink = inst._OnSink
	inst._roge_vanilla_oncollide = inst._OnCollide
	if _roge_spawning_parasite_cannon then
		inst._roge_parasite_cannon = true
		RogeStubParasiteCannontowerFloater(inst)
	end
	inst:ListenForEvent("death", function(tower)
		if tower._roge_host_knight ~= nil and tower:IsValid() then
			if tower._roge_follow_task ~= nil then
				tower._roge_follow_task:Cancel()
				tower._roge_follow_task = nil
			end
			if tower.reloadtask ~= nil then
				tower.reloadtask:Cancel()
				tower.reloadtask = nil
			end
			tower:DoTaskInTime(0, tower.Remove)
		end
	end)
end)

-- mortarball 使用原版落点阴影与溅射逻辑，不再强制阴影到瞄准点（会与真实落点错位）。
