-- roge/crab_knight.lua
-- 弱怪池蟹骑士：满宝石属性、头顶寄生加农炮、强化旋转攻击

local easing = require("easing")

local ROGE_CRABKNIGHT_MAXGEM_PURPLE = 11
local ROGE_CRABKNIGHT_WEAK_HEALTH = 800
local ROGE_CRABKNIGHT_SCALE = 1.85
local ROGE_CRABKNIGHT_VANILLA_SCALE = 1.7

-- 旋转攻击：更远触发、更大范围、更短 CD、命中玩家击退
local ROGE_CRABKNIGHT_SPIN_TRIGGER_RANGE = 5.5
local ROGE_CRABKNIGHT_SPIN_AOE_DIST = -0.6
local ROGE_CRABKNIGHT_SPIN_AOE_RADIUS = 4.5
local ROGE_CRABKNIGHT_SPIN_AOE_PADDING = 3
local ROGE_CRABKNIGHT_ATTACK_PERIOD_MULT = 0.5
local ROGE_CRABKNIGHT_ATTACK_RANGE_MULT = 1.35
local ROGE_CRABKNIGHT_SPIN_KNOCKBACK_RADIUS = 2.8
local ROGE_CRABKNIGHT_SPIN_KNOCKBACK_STRENGTH = 1.6

local ROGE_SPIN_AOE_MUST_TAGS = { "_combat" }
local ROGE_SPIN_AOE_CANT_TAGS = {
	"crabking_ally", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost",
}
local ROGE_CRABKNIGHT_CANNON_SYMBOL = "cc_bod"
local ROGE_CRABKNIGHT_CANNON_BASE_SYMBOL = "leak_part"
local ROGE_CRABKNIGHT_CROWN_ABOVE_BOD = 2.05
local ROGE_CRABKNIGHT_CANNON_SCALE = 0.8
local ROGE_PARASITE_CANNON_SHOT_COUNT = 3
local ROGE_PARASITE_CANNON_TILE_RANGE = 5
local ROGE_PARASITE_CANNON_FIND_DIST = ROGE_PARASITE_CANNON_TILE_RANGE * TILE_SCALE
local ROGE_PARASITE_CANNON_SPLASH_RADIUS = TILE_SCALE
local ROGE_PARASITE_CANNON_DAMAGE = 80
local ROGE_PARASITE_CANNON_HSPEED_MULT = 1
local ROGE_PARASITE_CANNON_GRAVITY = -40
local ROGE_PARASITE_CANNON_SHADOW_W = 4.4
local ROGE_PARASITE_CANNON_SHADOW_H = 3.3
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
		inst.components.combat:SetRange(
			TUNING.CRABKING_MOB_KNIGHT_ATTACK_RANGE * ROGE_CRABKNIGHT_ATTACK_RANGE_MULT,
			TUNING.CRABKING_MOB_HIT_RANGE)
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
	local x, y, z = inst.Transform:GetWorldPosition()
	local cos_theta = math.cos(inst.Transform:GetRotation() * DEGREES)
	local sin_theta = math.sin(inst.Transform:GetRotation() * DEGREES)
	local dist = ROGE_CRABKNIGHT_SPIN_AOE_DIST
	x = x + dist * cos_theta
	z = z - dist * sin_theta
	local radius = ROGE_CRABKNIGHT_SPIN_AOE_RADIUS
	local targets = inst.sg.statemem.targets or {}
	for _, v in ipairs(TheSim:FindEntities(
		x, y, z, radius + ROGE_CRABKNIGHT_SPIN_AOE_PADDING, ROGE_SPIN_AOE_MUST_TAGS, ROGE_SPIN_AOE_CANT_TAGS)) do
		if v ~= inst and not targets[v] and v:IsValid() and not v:IsInLimbo()
			and not (v.components.health and v.components.health:IsDead())
			and inst.components.combat:CanTarget(v) then
			local range = radius + v:GetPhysicsRadius(0)
			local x1, _, z1 = v.Transform:GetWorldPosition()
			local dx, dz = x1 - x, z1 - z
			if dx * dx + dz * dz < range * range then
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
local function RogeGetKnightCrownWorldPos(knight)
	local scale_ratio = ROGE_CRABKNIGHT_SCALE / ROGE_CRABKNIGHT_VANILLA_SCALE
	local bx, by, bz = knight.AnimState:GetSymbolPosition(ROGE_CRABKNIGHT_CANNON_SYMBOL, 0, 0, 0)
	return bx, by + ROGE_CRABKNIGHT_CROWN_ABOVE_BOD * scale_ratio, bz
end

local function RogeAlignTowerBaseToWorldPoint(tower, wx, wy, wz)
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

local function RogeIsValidCannonTarget(knight, target)
	return target ~= nil and target:IsValid()
		and target.components.health ~= nil and not target.components.health:IsDead()
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

local function RogeGetParasiteCannontowerTarget(tower, knight)
	local target = RogeGetKnightCombatTarget(knight)
	if target == nil then
		return nil
	end
	local kx, _, kz = knight.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx, dz = tx - kx, tz - kz
	if dx * dx + dz * dz > ROGE_PARASITE_CANNON_FIND_DIST * ROGE_PARASITE_CANNON_FIND_DIST then
		return nil
	end
	return target
end

local function RogeSyncCannontowerOnKnightHead(knight, tower)
	if knight == nil or tower == nil or not knight:IsValid() or not tower:IsValid() then
		return
	end
	local hx, hy, hz = RogeGetKnightCrownWorldPos(knight)
	RogeAlignTowerBaseToWorldPoint(tower, hx, hy, hz)
	local target = RogeGetKnightCombatTarget(knight)
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

local function RogeApplyParasiteMortarballShadowStyle(shadow, gsh)
	if shadow._roge_shadow_styled then
		return
	end
	shadow._roge_shadow_styled = true
	if shadow.DynamicShadow ~= nil then
		shadow.DynamicShadow:SetSize(gsh.original_width, gsh.original_height)
	end
	if shadow.AnimState ~= nil then
		shadow.AnimState:OverrideMultColour(0, 0, 0, 1)
	end
end

local function RogeSetupParasiteMortarballGroundShadow(inst)
	if inst._roge_parasite_groundshadow_setup then
		return
	end
	local gsh = inst.components.groundshadowhandler
	if gsh == nil then
		inst:DoTaskInTime(0, function()
			if inst:IsValid() and inst:HasTag("_roge_parasite_mortar") then
				RogeSetupParasiteMortarballGroundShadow(inst)
			end
		end)
		return
	end
	inst._roge_parasite_groundshadow_setup = true
	gsh:SetSize(ROGE_PARASITE_CANNON_SHADOW_W, ROGE_PARASITE_CANNON_SHADOW_H)
	local old_onupdate = gsh.OnUpdate
	gsh.OnUpdate = function(self, dt)
		if not self.inst:IsValid() or not self.inst:HasTag("_roge_parasite_mortar") then
			if old_onupdate ~= nil then
				old_onupdate(self, dt)
			end
			return
		end
		if self.ground_shadow == nil or not self.ground_shadow:IsValid() then
			if old_onupdate ~= nil then
				old_onupdate(self, dt)
			end
			return
		end
		local land_x = self.inst._roge_land_x ~= nil and self.inst._roge_land_x:value() or nil
		local land_z = self.inst._roge_land_z ~= nil and self.inst._roge_land_z:value() or nil
		if land_x ~= nil and land_z ~= nil then
			self.ground_shadow.Transform:SetPosition(land_x, 0, land_z)
			RogeApplyParasiteMortarballShadowStyle(self.ground_shadow, self)
			return
		end
		if old_onupdate ~= nil then
			old_onupdate(self, dt)
		end
	end
end

local function RogeParasiteLaunchProjectile(tower, target, targetpos)
	targetpos = targetpos or RogeParasiteGetShootTargetPosition(tower, target)
	local x, y, z = tower.AnimState:GetSymbolPosition("cannonball_rock02", 0, 0, 0)
	local projectile = SpawnPrefab("mortarball")
	if projectile.components.complexprojectile == nil then
		projectile:AddComponent("complexprojectile")
	end
	projectile.Transform:SetPosition(x, y + 0.3, z)
	projectile.redgemcount = tower.redgemcount
	projectile:AddTag("_roge_parasite_mortar")
	if projectile._roge_land_x ~= nil then
		projectile._roge_land_x:set(targetpos.x)
	end
	if projectile._roge_land_z ~= nil then
		projectile._roge_land_z:set(targetpos.z)
	end

	local cp = projectile.components.complexprojectile
	cp.usehigharc = true
	cp:SetGravity(ROGE_PARASITE_CANNON_GRAVITY)
	local dx = targetpos.x - x
	local dz = targetpos.z - z
	local rangesq = dx * dx + dz * dz
	local maxrange = TUNING.FIRE_DETECTOR_RANGE
	local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange) * ROGE_PARASITE_CANNON_HSPEED_MULT
	cp:SetHorizontalSpeed(speed)
	cp:Launch(targetpos, tower)

	projectile:setdamage(ROGE_PARASITE_CANNON_DAMAGE)
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
	local target = RogeGetParasiteCannontowerTarget(tower, tower._roge_host_knight)
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
					local use_spin = not inst:IsNear(data.target, ROGE_CRABKNIGHT_SPIN_TRIGGER_RANGE)
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

AddPrefabPostInit("mortarball", function(inst)
	inst._roge_land_x = net_float(inst.GUID, "roge_parasite_land_x", "roge_parasite_land_dirty")
	inst._roge_land_z = net_float(inst.GUID, "roge_parasite_land_z")
	local function try_setup()
		if inst:IsValid() and inst:HasTag("_roge_parasite_mortar") then
			RogeSetupParasiteMortarballGroundShadow(inst)
		end
	end
	inst:DoTaskInTime(0, try_setup)
	inst:ListenForEvent("roge_parasite_land_dirty", try_setup)
end)
