----------------------------------------------------------------------

-- 主教：prefab bishop = 旧版 bishop_charge；bishop_nightmare = 新版 charge2

-- 旧版攻击节奏：对齐 modmain 眼球塔（拉长动画 + 延后出弹帧），非仅改 SetAttackPeriod

----------------------------------------------------------------------

TUNING.BISHOP_LEGACY_ATTACK_PERIOD = TUNING.BISHOP_LEGACY_ATTACK_PERIOD or 1.5
TUNING.BISHOP_LEGACY_ATTACK_WINDUP_FRAMES = TUNING.BISHOP_LEGACY_ATTACK_WINDUP_FRAMES or 45
TUNING.BISHOP_LEGACY_ATTACK_FIRE_FRAME = TUNING.BISHOP_LEGACY_ATTACK_FIRE_FRAME or 24

local function NightmareBishopLegacyPeriod()

	return TUNING.BISHOP_LEGACY_ATTACK_PERIOD or 1.5

end



local function NightmareBishopLegacyWindupFrames()

	return TUNING.BISHOP_LEGACY_ATTACK_WINDUP_FRAMES or 45

end



local function NightmareBishopLegacyFireFrame()

	return TUNING.BISHOP_LEGACY_ATTACK_FIRE_FRAME or 24

end



local function NightmareBishopLegacyAnimSync()

	return NightmareBishopLegacyFireFrame() / NightmareBishopLegacyWindupFrames()

end



local function NightmareBishopUsesNewWeapon(inst)

	if inst == nil then

		return false

	end

	if inst._nm_bishop_new_weapon ~= nil then

		return inst._nm_bishop_new_weapon

	end

	if inst.prefab == "bishop_nightmare" then

		return true

	end

	if inst.prefab == "bishop" then

		return false

	end

	if inst.kind == "_nightmare" then

		return true

	end

	local anim = inst.AnimState

	if anim ~= nil and anim:GetBuild() == "bishop_nightmare" then

		return true

	end

	return false

end



local function NightmareBishopGetAttackState(inst)

	return NightmareBishopUsesNewWeapon(inst) and "attack2" or "attack"

end



local function NightmareBishopIsIntactLegacy(inst)

	return not NightmareBishopUsesNewWeapon(inst)

end



local function NightmareBishopResolveAttackTarget(inst, target)

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



local function NightmareBishopTargetIsAttackable(inst, target)

	if target == nil or not target:IsValid() then

		return false

	end

	if inst.components.health ~= nil and inst.components.health:IsDead() then

		return false

	end

	if target.components.health ~= nil and target.components.health:IsDead() then

		return false

	end

	return true

end



local BISHOP_TAUNT_EVERY_N_ATTACKS = 2

-- 完好主教：每 N 次攻击中的第 N 次先战吼（1 直接攻、2 战吼→攻、3 直接攻 …）

local function NightmareBishopIsTauntState(inst)

	return inst.sg ~= nil and inst.sg.currentstate ~= nil and inst.sg.currentstate.name == "taunt"

end



local function NightmareBishopIsPreAttackTauntPending(inst)

	return inst._nm_bishop_pre_attack_taunt == true or inst._nm_bishop_taunt_cycle_pending == true

end



local function NightmareBishopNeedsPreAttackTaunt(inst)

	if not NightmareBishopIsIntactLegacy(inst) then

		return false

	end

	if NightmareBishopIsPreAttackTauntPending(inst) then

		return false

	end

	local n = inst._nm_bishop_attack_count or 0

	return (n + 1) % BISHOP_TAUNT_EVERY_N_ATTACKS == 0

end



local function NightmareBishopClearAttackQueue(inst)
	inst._nm_bishop_pre_attack_taunt = nil
	inst._nm_bishop_pending_attack = nil
	inst._nm_bishop_taunt_cycle_pending = nil
	if inst.sg ~= nil and inst.sg.statemem ~= nil then
		inst.sg.statemem.doattack = nil
	end
end

local function NightmareBishopShouldDeferAttack(inst)
	return inst.sg ~= nil
		and inst.sg:HasAnyStateTag("stunned", "electrocute", "frozen")
end

local function NightmareBishopNoteAttackFinished(inst)

	if not NightmareBishopIsIntactLegacy(inst) then

		return

	end

	inst._nm_bishop_attack_count = (inst._nm_bishop_attack_count or 0) + 1

	inst._nm_bishop_pre_attack_taunt = nil

	inst._nm_bishop_pending_attack = nil

	inst._nm_bishop_taunt_cycle_pending = nil

end



local function NightmareBishopQueuePreAttackTaunt(inst, target)

	if NightmareBishopIsTauntState(inst) and NightmareBishopIsPreAttackTauntPending(inst) then

		return true

	end

	target = NightmareBishopResolveAttackTarget(inst, target)

	if not NightmareBishopTargetIsAttackable(inst, target) then

		return false

	end

	inst._nm_bishop_pre_attack_taunt = true

	inst._nm_bishop_pending_attack = target

	inst._nm_bishop_taunt_cycle_pending = true

	inst.sg:GoToState("taunt")

	return true

end



local function NightmareBishopRequestAttack(inst, target)

	if not NightmareBishopIsIntactLegacy(inst) then

		target = NightmareBishopResolveAttackTarget(inst, target)

		if not NightmareBishopTargetIsAttackable(inst, target) then

			return false

		end

		inst.sg:GoToState(NightmareBishopGetAttackState(inst), target)

		return true

	end

	if NightmareBishopNeedsPreAttackTaunt(inst) then

		return NightmareBishopQueuePreAttackTaunt(inst, target)

	end

	target = NightmareBishopResolveAttackTarget(inst, target)

	if not NightmareBishopTargetIsAttackable(inst, target) then

		return false

	end

	inst.sg:GoToState("attack", target)

	return true

end



local function NightmareBishopFireLegacyCharge(inst)

	local combat = inst.components.combat

	local target = combat ~= nil and combat.target or nil

	if target == nil or not target:IsValid() then

		if combat ~= nil then

			combat:DoAttack()

		end

		return

	end

	inst:ForceFacePoint(target.Transform:GetWorldPosition())

	local projectile = SpawnPrefab("bishop_charge")

	if projectile ~= nil and projectile.components.projectile ~= nil then

		local x, y, z = inst.Transform:GetWorldPosition()

		projectile.Transform:SetPosition(x, y, z)

		projectile.components.projectile:Throw(inst, target, inst)

	elseif combat ~= nil then

		combat:DoAttack(target)

	end

end



local function NightmareBishopLegacyAttackFire(inst)

	if inst.sg.statemem.fired then

		return

	end

	inst.sg.statemem.fired = true

	NightmareBishopFireLegacyCharge(inst)

	inst.AnimState:SetDeltaTimeMultiplier(1)

	inst.sg:RemoveStateTag("busy")

	if inst.sg:HasStateTag("attack") then

		NightmareBishopNoteAttackFinished(inst)

		inst.sg:GoToState("idle")

	end

end



local function NightmareBishopLegacyAttackOnEnter(inst, target)

	inst.sg.statemem.fired = false

	inst.components.locomotor:StopMoving()

	if inst.targetingfx then

		inst.targetingfx:KillFx()

		inst.targetingfx = nil

	end

	target = NightmareBishopResolveAttackTarget(inst, target)

	if target ~= nil then

		inst.sg.statemem.target = target

		inst:ForceFacePoint(target.Transform:GetWorldPosition())

	end

	-- bishop_build 已无 atk，须用 atk2_*（与原版 SG 一致）再放慢并发射 bishop_charge

	inst.AnimState:PlayAnimation("atk2_pre")

	inst.AnimState:PushAnimation("atk2_loop")

	inst.AnimState:SetDeltaTimeMultiplier(NightmareBishopLegacyAnimSync())

	inst.components.combat:StartAttack()

	inst.sg:SetTimeout(NightmareBishopLegacyPeriod() + 4 * FRAMES)

end



local function NightmareBishopLegacyAttackOnExit(inst)

	inst.AnimState:SetDeltaTimeMultiplier(1)

	inst.sg:RemoveStateTag("busy")

end



-- 原 atk 约第 24 帧出弹；拉到 WINDUP_FRAMES，用 ANIM_SYNC 放慢动画（同眼球塔）

local function NightmareBishopMakeOldAttackState()

	local shoot_snd_frame = 15

	local shoot_snd_time = (shoot_snd_frame / NightmareBishopLegacyAnimSync()) * FRAMES



	return State({

		name = "attack",

		tags = { "attack", "busy" },

		onenter = NightmareBishopLegacyAttackOnEnter,

		onexit = NightmareBishopLegacyAttackOnExit,

		ontimeout = function(inst)

			if inst.sg:HasStateTag("attack") then

				if not inst.sg.statemem.fired then

					NightmareBishopLegacyAttackFire(inst)

				else

					inst.sg:GoToState("idle")

				end

			end

		end,

		timeline = {

			TimeEvent(0, function(inst)

				inst.SoundEmitter:PlaySound(inst.soundpath .. "charge")

			end),

			TimeEvent(shoot_snd_time, function(inst)

				inst.SoundEmitter:PlaySound(inst.soundpath .. "shoot")

			end),

			TimeEvent(NightmareBishopLegacyWindupFrames() * FRAMES, function(inst)

				if inst.sg:HasStateTag("attack") then

					NightmareBishopLegacyAttackFire(inst)

				end

			end),

		},

		events = {

			EventHandler("animover", function(inst)

				if inst.AnimState:AnimDone() and not inst.sg:HasStateTag("busy") then

					inst.sg:GoToState("idle")

				end

			end),

		},

	})

end



local function NightmareBishopPatchLegacyAttackState(attack)

	if attack == nil or attack._nm_bishop_legacy_attack_patched then

		return

	end

	attack._nm_bishop_legacy_attack_patched = true

	attack.onenter = NightmareBishopLegacyAttackOnEnter

	attack.onexit = NightmareBishopLegacyAttackOnExit

	attack.ontimeout = function(inst)

		if inst.sg:HasStateTag("attack") then

			if not inst.sg.statemem.fired then

				NightmareBishopLegacyAttackFire(inst)

			else

				inst.sg:GoToState("idle")

			end

		end

	end

	local shoot_snd_time = (15 / NightmareBishopLegacyAnimSync()) * FRAMES

	attack.timeline = {

		TimeEvent(0, function(inst)

			inst.SoundEmitter:PlaySound(inst.soundpath .. "charge")

		end),

		TimeEvent(shoot_snd_time, function(inst)

			inst.SoundEmitter:PlaySound(inst.soundpath .. "shoot")

		end),

		TimeEvent(NightmareBishopLegacyWindupFrames() * FRAMES, function(inst)

			if inst.sg:HasStateTag("attack") then

				NightmareBishopLegacyAttackFire(inst)

			end

		end),

	}

end



local function NightmareBishopOnTauntAnimOver(inst)

	if not inst.AnimState:AnimDone() then

		return

	end

	if NightmareBishopShouldDeferAttack(inst) then
		NightmareBishopClearAttackQueue(inst)
		inst.sg.statemem.keepsixfaced = true
		inst.sg:GoToState("idle")
		return
	end

	if not NightmareBishopIsIntactLegacy(inst) then

		inst.sg.statemem.keepsixfaced = true

		inst.sg:GoToState("idle")

		return

	end

	if inst._nm_bishop_pre_attack_taunt then

		inst._nm_bishop_pre_attack_taunt = nil

		inst._nm_bishop_taunt_cycle_pending = nil

		local target = inst._nm_bishop_pending_attack

		inst._nm_bishop_pending_attack = nil

		if NightmareBishopTargetIsAttackable(inst, target) then

			inst.sg.statemem.keepsixfaced = true

			inst.sg:GoToState("attack", target)

			return

		end

	end

	inst._nm_bishop_taunt_cycle_pending = nil

	inst.sg.statemem.keepsixfaced = true

	inst.sg:GoToState("idle")

end



local function NightmareBishopPatchTauntState(sg)

	local taunt = sg.states ~= nil and sg.states.taunt or nil

	if taunt == nil or taunt._nm_bishop_taunt_patched then

		return

	end

	taunt._nm_bishop_taunt_patched = true

	if taunt.events == nil then

		taunt.events = { EventHandler("animover", NightmareBishopOnTauntAnimOver) }

		return

	end

	for _, ev in ipairs(taunt.events) do

		if ev ~= nil and ev.name == "animover" then

			ev.fn = NightmareBishopOnTauntAnimOver

			return

		end

	end

	table.insert(taunt.events, EventHandler("animover", NightmareBishopOnTauntAnimOver))

end



local function NightmareBishopPatchDoattack(sg)

	local doattack = sg.events.doattack

	if doattack == nil or doattack._nm_bishop_doattack_patched then

		return

	end

	doattack._nm_bishop_doattack_patched = true

	doattack.fn = function(inst, data)

		if inst.components.health:IsDead() then

			return

		end

		if not NightmareBishopUsesNewWeapon(inst) and inst.sg:HasStateTag("attack") then

			return

		end

		if NightmareBishopIsTauntState(inst) then

			return

		end

		if inst.sg:HasStateTag("taunt") then

			return

		end

		if NightmareBishopShouldDeferAttack(inst) then

			return

		end

		-- 与原版一致：busy 时仅由 hit 状态内的事件排队，全局 doattack 不得打断受击/眩晕
		if inst.sg:HasStateTag("busy") then

			return

		end

		local target = data ~= nil and data.target or nil

		if not NightmareBishopRequestAttack(inst, target) then

			target = NightmareBishopResolveAttackTarget(inst, target)

			if NightmareBishopTargetIsAttackable(inst, target) then

				inst.sg:GoToState(NightmareBishopGetAttackState(inst), target)

			end

		end

	end

end



local function NightmareBishopPatchHitState(hit)

	if hit == nil or hit._nightmare_bishop_hit_patched then

		return

	end

	hit._nightmare_bishop_hit_patched = true



	local pending_attack_time = 8 * FRAMES

	for _, te in ipairs(hit.timeline) do

		if te.time == pending_attack_time then

			te.fn = function(inst)

				local target = inst.sg.statemem.doattack

				inst.sg.statemem.doattack = nil

				if NightmareBishopShouldDeferAttack(inst) then

					inst.sg:RemoveStateTag("busy")

					return

				end

				if target ~= nil and target:IsValid() then

					if NightmareBishopRequestAttack(inst, target) then

						return

					end

				end

				inst.sg:RemoveStateTag("busy")

			end

			break

		end

	end



	local doattack = hit.events.doattack

	if doattack ~= nil then

		doattack.fn = function(inst, data)

			local target = data ~= nil and data.target or inst.components.combat.target

			if NightmareBishopShouldDeferAttack(inst) then

				return true

			end

			if inst.sg:HasStateTag("busy") then

				inst.sg.statemem.doattack = target

			elseif target ~= nil and target:IsValid() then

				if not NightmareBishopRequestAttack(inst, target) then

					inst.sg:GoToState(NightmareBishopGetAttackState(inst), target)

				end

			end

			return true

		end

	end

end



local function NightmareBishopWrapStateOnenter(state, fn)

	if state == nil or fn == nil or state._nm_bishop_onenter_wrapped then

		return

	end

	state._nm_bishop_onenter_wrapped = true

	local old_onenter = state.onenter

	state.onenter = function(inst, ...)

		return fn(inst, old_onenter, ...)

	end

end



local function NightmareBishopPatchStunElectrocuteStates(sg)

	local stun_states = {
		"electrocute",
		"electrocute_pst",
		"shock_to_stun",
		"stun_pre",
		"stun_loop",
		"stun_hit",
		"stun_pst",
	}

	for _, name in ipairs(stun_states) do

		local state = sg.states[name]

		if state ~= nil then

			NightmareBishopWrapStateOnenter(state, function(inst, old_onenter, ...)

				NightmareBishopClearAttackQueue(inst)

				if old_onenter ~= nil then

					return old_onenter(inst, ...)

				end

			end)

		end

	end

end



local function NightmareBishopWrapAttackStates(sg)

	local attack = sg.states.attack

	local attack2 = sg.states.attack2



	if attack ~= nil then

		NightmareBishopWrapStateOnenter(attack, function(inst, old_onenter, ...)

			if NightmareBishopUsesNewWeapon(inst) and attack2 ~= nil then

				return inst.sg:GoToState("attack2", ...)

			end

			if old_onenter ~= nil then

				return old_onenter(inst, ...)

			end

		end)

	end



	if attack2 ~= nil then

		NightmareBishopWrapStateOnenter(attack2, function(inst, old_onenter, ...)

			if not NightmareBishopUsesNewWeapon(inst) and attack ~= nil then

				return inst.sg:GoToState("attack", ...)

			end

			if old_onenter ~= nil then

				return old_onenter(inst, ...)

			end

		end)

	end

end



function NightmareBishopApplySgPatch(sg)

	if sg == nil or sg.states == nil then

		return

	end



	if sg.states.attack2 == nil and sg.states.attack ~= nil then

		sg.states.attack2 = sg.states.attack

		sg.states.attack = NightmareBishopMakeOldAttackState()

	end



	NightmareBishopPatchLegacyAttackState(sg.states.attack)

	NightmareBishopPatchTauntState(sg)

	NightmareBishopWrapAttackStates(sg)

	NightmareBishopPatchDoattack(sg)

	NightmareBishopPatchHitState(sg.states.hit)

	NightmareBishopPatchStunElectrocuteStates(sg)

end



AddStategraphPostInit("bishop", NightmareBishopApplySgPatch)



AddSimPostInit(function()

	if GLOBAL.package ~= nil and GLOBAL.package.loaded ~= nil then

		GLOBAL.package.loaded["stategraphs/SGbishop"] = nil

	end

	local ok, sg = pcall(require, "stategraphs/SGbishop")

	if ok and sg ~= nil then

		NightmareBishopApplySgPatch(sg)

	end

end)



local function NightmareBishopMarkWeaponFlags(inst, use_new)

	if not TheWorld.ismastersim then

		return

	end

	inst._nm_bishop_new_weapon = use_new

	inst:DoTaskInTime(0, function(i)

		if i:IsValid() and i.sg ~= nil and i.sg.sg ~= nil then

			NightmareBishopApplySgPatch(i.sg.sg)

		end

	end)

end



AddPrefabPostInit("bishop", function(inst)

	NightmareBishopMarkWeaponFlags(inst, false)

	if not TheWorld.ismastersim then

		return

	end

	inst._nm_bishop_attack_count = 0

	if inst.components.combat ~= nil then

		inst.components.combat:SetAttackPeriod(NightmareBishopLegacyPeriod())

	end

end)



AddPrefabPostInit("bishop_nightmare", function(inst)

	NightmareBishopMarkWeaponFlags(inst, true)

end)



AddPrefabPostInit("bishop_charge", function(inst)

	if not TheWorld.ismastersim or inst._nm_bishop_charge_weapon then

		return

	end

	inst._nm_bishop_charge_weapon = true

	if inst.components.weapon == nil then

		inst:AddComponent("weapon")

		inst.components.weapon:SetDamage(TUNING.BISHOP_DAMAGE or 40)

	end

end)



local _roge_special_attacks = rawget(GLOBAL, "SPECIAL_ATTACKS_CONFIG") or {}
_roge_special_attacks["bishop"] = { event = "doattack" }
rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)


