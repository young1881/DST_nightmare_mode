-- 精英池鱼人召唤：守卫三连 / 鱼人兵团（随机变异·暗影·月灵等，共 4 只）

ROGE_MERMGUARD_PACK_COUNT = 3
ROGE_MERMCORPS_COUNT = 4
ROGE_MERMGUARD_PACK_RADIUS = 4
ROGE_MERMCORPS_RADIUS = 5
ROGE_MERMGUARD_PLANAR_DAMAGE = 5
ROGE_MERMGUARD_TRIPLE_HIT_DAMAGES = { 45, 45, 60 }
ROGE_MERMGUARD_TRIPLE_KNOCKBACK_RADIUS = 2
ROGE_MERMGUARD_TRIPLE_KNOCKBACK_STRENGTH = 1
ROGE_MERMGUARD_DEATH_MUTATE_CHANCE = 0.5
ROGE_MERMCORPS_PREFABS = {
	"merm_lunar",
	"mermguard_shadow",
	"mermguard_lunar",
}
local ROGE_MERMPACK_PREFABS = {
	mermguard = true,
	merm_lunar = true,
	mermguard_shadow = true,
	mermguard_lunar = true,
}
local ROGE_MERMPACK_BUILD_BY_PREFAB = {
	mermguard = "merm_guard_build",
	mermguard_shadow = "merm_guard_shadow_build",
	mermguard_lunar = "merm_guard_lunar_build",
	merm_lunar = "merm_lunar_build",
}
local ROGE_MERMGUARD_TRIPLE_MOD_KEY = "roge_mermguard_tri_hit"

local function RogeMermguardShouldTripleAttack(inst)
	return inst ~= nil and inst:IsValid()
		and inst._roge_mermguard_pack
		and inst._roge_mermguard_triple_only
end

local function RogeMermguardTriAttackApplyKnockback(inst, target)
	if inst == nil or not inst:IsValid() or target == nil or not target:IsValid() then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	local dist = inst:GetDistanceSqToInst(target)
	local radius = ROGE_MERMGUARD_TRIPLE_KNOCKBACK_RADIUS + math.sqrt(dist)
	target:PushEventImmediate("knockback", {
		knocker = inst,
		radius = radius,
		strengthmult = ROGE_MERMGUARD_TRIPLE_KNOCKBACK_STRENGTH,
		forcelanded = true,
	})
end

local function RogeMermguardPackOnHitOther(inst, data)
	if not RogeMermguardShouldTripleAttack(inst) then
		return
	end
	if inst._roge_mermguard_tri_hit_num ~= 3 then
		return
	end
	local target = data ~= nil and data.target or nil
	if target == nil or not target:IsValid() then
		return
	end
	RogeMermguardTriAttackApplyKnockback(inst, target)
end

local function RogeHookMermguardPackCombatHit(inst)
	local combat = inst.components.combat
	if combat == nil or combat._roge_mermguard_hit_hooked then
		return
	end
	combat._roge_mermguard_hit_hooked = true
	local old_fn = combat.onhitotherfn
	combat.onhitotherfn = function(attacker, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
		if old_fn ~= nil then
			old_fn(attacker, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
		end
		RogeMermguardPackOnHitOther(attacker, { target = target })
	end
end

local function RogeMermguardTriAttackDoHit(inst, hit_idx)
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	local desired = ROGE_MERMGUARD_TRIPLE_HIT_DAMAGES[hit_idx]
	if desired == nil then
		return
	end
	local base = combat.defaultdamage
	if base == nil or base <= 0 then
		base = TUNING.MERM_GUARD_DAMAGE - ROGE_MERMGUARD_PLANAR_DAMAGE
	end
	inst._roge_mermguard_tri_hit_num = hit_idx
	combat.externaldamagemultipliers:SetModifier(
		inst,
		desired / base,
		ROGE_MERMGUARD_TRIPLE_MOD_KEY
	)
	combat:DoAttack()
	combat.externaldamagemultipliers:RemoveModifier(inst, ROGE_MERMGUARD_TRIPLE_MOD_KEY)
	if inst.sounds ~= nil then
		inst.SoundEmitter:PlaySound(inst.sounds.attack)
	end
	inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
end

local function RogeApplyMermguardKingUpgrade(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:SetMaxHealth(TUNING.MERM_GUARD_HEALTH)
	end
	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
	end
	inst.components.planardamage:SetBaseDamage(ROGE_MERMGUARD_PLANAR_DAMAGE)
	if inst.components.combat ~= nil then
		local damage = TUNING.MERM_GUARD_DAMAGE
		if inst.components.planardamage ~= nil then
			damage = damage - inst.components.planardamage:GetBaseDamage()
		end
		inst.components.combat:SetDefaultDamage(damage)
	end
	local build = ROGE_MERMPACK_BUILD_BY_PREFAB[inst.prefab] or "merm_guard_build"
	inst.AnimState:SetBuild(build)
	inst.Transform:SetScale(1, 1, 1)
end

local function RogeHookMermguardPackDodge(inst)
	if inst == nil or inst.components.attackdodger ~= nil then
		return
	end
	local attackdodger = inst:AddComponent("attackdodger")
	attackdodger.ondodgefn = function(mob, attacker)
		mob:PushEvent("attackdodged", attacker)
	end
	attackdodger.cooldowntime = TUNING.MERMKING_CROWNBUFF_DODGE_COOLDOWN
end

local function RogeHookMermguardPackTripleAttack(inst)
	inst._roge_mermguard_triple_only = true
	inst.CanTripleAttack = function()
		return true
	end
end

local function RogeHookLunarMermPackNoRevert(inst)
	if inst.prefab ~= "merm_lunar" and inst.prefab ~= "mermguard_lunar" then
		return
	end
	local follower = inst.components.follower
	if follower == nil then
		return
	end
	follower.neverexpire = true
	follower.OnChangedLeader = function()
	end
	if inst.sg ~= nil and inst.sg.mem ~= nil then
		inst.sg.mem.nolunarmutate = true
		inst.sg.mem.nocorpse = true
	end
end

local function RogeIsRogeMermPackPrefab(prefab)
	return prefab ~= nil and ROGE_MERMPACK_PREFABS[prefab] == true
end

local function RogeMermguardPerformPossessAttack(guard, target)
	if not RogeMermguardShouldTripleAttack(guard) then
		return false
	end
	if guard.components.health ~= nil and guard.components.health:IsDead() then
		return false
	end
	if guard.sg == nil then
		return false
	end
	if guard.sg:HasStateTag("busy") then
		return true
	end
	if target == nil or not target:IsValid() then
		if guard.components.combat ~= nil then
			target = guard.components.combat.target
		end
	end
	if target == nil or not target:IsValid() then
		return false
	end
	if guard.components.combat ~= nil then
		guard.components.combat:SetTarget(target)
		if guard.components.combat:InCooldown() then
			guard.components.combat:ResetCooldown()
		end
	end
	guard:FacePoint(target.Transform:GetWorldPosition())
	guard:PushEvent("doattack", { target = target })
	return true
end

local function RogeTryPossessedMermguardAttack(player, target)
	if player == nil or player.Poss2 == nil or player.Poss2.Possessing == nil then
		return false
	end
	local possessed = player.Poss2.Possessing
	if not RogeIsRogeMermPackPrefab(possessed.prefab) or not possessed._roge_mermguard_pack then
		return false
	end
	return RogeMermguardPerformPossessAttack(possessed, target)
end

local function RogeInstallMermguardPossessAttackHooks()
	AddComponentPostInit("playercontroller", function(self)
		if self._roge_mermguard_poss_attack_patched then
			return
		end
		self._roge_mermguard_poss_attack_patched = true

		local _OnRemoteControllerAttackButton = self.OnRemoteControllerAttackButton
		self.OnRemoteControllerAttackButton = function(pc, attack_target, isreleased, noforce)
			if RogeTryPossessedMermguardAttack(pc.inst, attack_target) then
				return
			end
			return _OnRemoteControllerAttackButton(pc, attack_target, isreleased, noforce)
		end

		local _DoAttackButton = self.DoAttackButton
		self.DoAttackButton = function(pc, retarget, isleftmouse)
			local target = pc:GetAttackTarget(
				TheInput:IsControlPressed(CONTROL_FORCE_ATTACK),
				retarget,
				retarget ~= pc:GetCombatTarget())
			if RogeTryPossessedMermguardAttack(pc.inst, target) then
				return
			end
			return _DoAttackButton(pc, retarget, isleftmouse)
		end

		local _OnRemoteAttackButton = self.OnRemoteAttackButton
		self.OnRemoteAttackButton = function(pc, target, force_attack, noforce, isleftmouse, isreleased)
			if RogeTryPossessedMermguardAttack(pc.inst, target) then
				return
			end
			return _OnRemoteAttackButton(pc, target, force_attack, noforce, isleftmouse, isreleased)
		end
	end)
end

AddStategraphPostInit("merm", function(sg)
	local doattack = sg.events.doattack
	if doattack ~= nil and not doattack._roge_mermguard_triple_patched then
		doattack._roge_mermguard_triple_patched = true
		local old_fn = doattack.fn
		doattack.fn = function(inst, data)
			if RogeMermguardShouldTripleAttack(inst) then
				if inst.components.health and not inst.components.health:IsDead()
					and (not inst.sg:HasStateTag("busy")
						or (inst.sg:HasStateTag("hit")
							and not inst.sg:HasAnyStateTag("electrocute", "shadow_hit")))
				then
					inst.sg:GoToState("tri_attack")
					return
				end
			end
			return old_fn(inst, data)
		end
	end

	local attack = sg.states.attack
	if attack ~= nil and not attack._roge_mermguard_triple_patched then
		attack._roge_mermguard_triple_patched = true
		local old_onenter = attack.onenter
		attack.onenter = function(inst, ...)
			if RogeMermguardShouldTripleAttack(inst) then
				inst.sg:GoToState("tri_attack")
				return
			end
			if old_onenter ~= nil then
				return old_onenter(inst, ...)
			end
		end
	end

	local tri_attack = sg.states.tri_attack
	if tri_attack ~= nil and not tri_attack._roge_mermguard_dmg_patched then
		tri_attack._roge_mermguard_dmg_patched = true
		local old_onenter = tri_attack.onenter
		tri_attack.onenter = function(inst)
			if RogeMermguardShouldTripleAttack(inst) then
				inst._roge_mermguard_tri_hit_num = 0
				inst.components.combat:StartAttack()
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("atk_triplepunch")
				return
			end
			return old_onenter(inst)
		end
		for hit_idx = 1, 3 do
			local ev = tri_attack.timeline[hit_idx]
			if ev ~= nil and ev.fn ~= nil then
				local old_fn = ev.fn
				ev.fn = function(inst)
					if RogeMermguardShouldTripleAttack(inst) then
						RogeMermguardTriAttackDoHit(inst, hit_idx)
						return
					end
					return old_fn(inst)
				end
			end
		end
	end

	local death = sg.states.death
	if death ~= nil and not death._roge_mermguard_mutate_patched then
		death._roge_mermguard_mutate_patched = true
		if death.timeline ~= nil then
			for i, ev in ipairs(death.timeline) do
				if ev ~= nil and ev.fn ~= nil then
					local old_fn = ev.fn
					ev.fn = function(inst)
						if inst.TestForRogeMermguardDeathMutate ~= nil then
							inst:TestForRogeMermguardDeathMutate()
						end
						return old_fn(inst)
					end
					break
				end
			end
		end
	end
end)

RogeInstallMermguardPossessAttackHooks()

local function RogeMermguardTripleSquadTryDeathMutate(inst)
	if inst == nil or not inst:IsValid() or inst._roge_mermguard_death_mutated then
		return
	end
	if not inst._roge_mermguard_triple_squad or inst.prefab ~= "mermguard" then
		return
	end
	if math.random() >= ROGE_MERMGUARD_DEATH_MUTATE_CHANCE then
		return
	end
	inst._roge_mermguard_death_mutated = true

	local new_prefab = math.random() < 0.5 and "mermguard_shadow" or "mermguard_lunar"
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = inst.Transform:GetRotation()
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil

	local mob = SpawnPrefab(new_prefab)
	if mob == nil then
		return
	end
	mob.Transform:SetPosition(x, y, z)
	mob.Transform:SetRotation(rot)
	RogeSetupMermguardPackMember(mob)
	if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
		mob.components.combat:SetTarget(target)
	end
	if new_prefab == "mermguard_lunar" then
		mob:PushEvent("mutated", { oldbuild = "merm_guard_build" })
	else
		mob:PushEvent("shadowmerm_spawn")
	end
end

function RogeSetupMermguardPackMember(inst)
	if inst == nil or not inst:IsValid() or inst._roge_mermguard_pack then
		return
	end
	if not RogeIsRogeMermPackPrefab(inst.prefab) then
		return
	end
	inst._roge_mermguard_pack = true
	inst.persists = false
	inst:AddTag("flare_summoned")
	if inst.initialize_task ~= nil then
		inst.initialize_task:Cancel()
		inst.initialize_task = nil
	end
	inst.OnGuardInitialize = function() end
	inst.UpdateDamageAndHealth = function(guard)
		RogeApplyMermguardKingUpgrade(guard)
	end
	RogeHookLunarMermPackNoRevert(inst)
	RogeApplyMermguardKingUpgrade(inst)
	RogeHookMermguardPackDodge(inst)
	RogeHookMermguardPackTripleAttack(inst)
	RogeHookMermguardPackCombatHit(inst)
	if inst._roge_mermguard_triple_squad then
		inst.TestForRogeMermguardDeathMutate = function()
			RogeMermguardTripleSquadTryDeathMutate(inst)
		end
		if not inst._roge_mermguard_death_mutate_listen then
			inst._roge_mermguard_death_mutate_listen = true
			inst:ListenForEvent("death", RogeMermguardTripleSquadTryDeathMutate)
		end
	end
end

local function RogeSpawnMermPackAt(player, count, radius, prefab_picker, triple_squad)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local spawn_radius = 5
	local cx = x + math.cos(angle) * spawn_radius
	local cz = z + math.sin(angle) * spawn_radius
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	local first = nil
	local base_angle = math.random() * 2 * PI
	for i = 1, count do
		local prefab = prefab_picker()
		if prefab ~= nil then
			local a = base_angle + (i - 1) * (2 * PI / count)
			local mob = SpawnPrefab(prefab)
			if mob ~= nil then
				mob.Transform:SetPosition(
					cx + math.cos(a) * radius,
					y,
					cz + math.sin(a) * radius
				)
				if triple_squad then
					mob._roge_mermguard_triple_squad = true
				end
				RogeSetupMermguardPackMember(mob)
				if first == nil then
					first = mob
				end
				if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
					mob.components.combat:SetTarget(target)
				end
			end
		end
	end
	return first
end

function RogeSpawnMermguardPack(player)
	return RogeSpawnMermPackAt(player, ROGE_MERMGUARD_PACK_COUNT, ROGE_MERMGUARD_PACK_RADIUS, function()
		return "mermguard"
	end, true)
end

function RogeSpawnMermcorpsPack(player)
	return RogeSpawnMermPackAt(player, ROGE_MERMCORPS_COUNT, ROGE_MERMCORPS_RADIUS, function()
		return ROGE_MERMCORPS_PREFABS[math.random(#ROGE_MERMCORPS_PREFABS)]
	end, false)
end
