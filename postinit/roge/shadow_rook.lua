-- 暗影战车：战吼一次 → 连续闪现啃咬（次数 = 等级 + 2），中途可换目标，最后一咬锁定

local ShadowChess = require("stategraphs/SGshadow_chesspieces")

local CHARGE_COUNT_OFFSET = 2
local PRE_ATTACK_TAUNT_STATE = "roge_pre_attack_taunt"

local AREAATTACK_EXCLUDETAGS = {
	"INLIMBO", "notarget", "invisible", "noattack", "flight",
	"playerghost", "shadow", "shadowchesspiece", "shadowcreature",
}

local function NightmareShadowRookLevel(inst)
	local lv = inst.level or 1
	return math.clamp(lv, 1, 3)
end

local function NightmareShadowRookGetBiteCount(inst)
	return NightmareShadowRookLevel(inst) + CHARGE_COUNT_OFFSET
end

local function NightmareShadowRookTargetIsAttackable(inst, target)
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

local function NightmareShadowRookIsInAttackCycle(inst)
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("taunt") then
		return true
	end
	if inst.sg.currentstate ~= nil then
		local state = inst.sg.currentstate.name
		if state == "attack" or state == "attack_teleport" or state == PRE_ATTACK_TAUNT_STATE then
			return true
		end
	end
	return false
end

local function NightmareShadowRookGetComboMem(inst)
	return inst.sg ~= nil and inst.sg.mem or nil
end

local function NightmareShadowRookClearComboMem(inst)
	local mem = NightmareShadowRookGetComboMem(inst)
	if mem == nil then
		return
	end
	mem.roge_bites_total = nil
	mem.roge_bites_done = nil
	mem.roge_final_target = nil
end

local function NightmareShadowRookBeginCombo(inst)
	local mem = NightmareShadowRookGetComboMem(inst)
	if mem == nil then
		return
	end
	mem.roge_bites_total = NightmareShadowRookGetBiteCount(inst)
	mem.roge_bites_done = 0
	mem.roge_final_target = nil
end

local function NightmareShadowRookIsLastBite(inst)
	local mem = NightmareShadowRookGetComboMem(inst)
	if mem == nil or mem.roge_bites_total == nil or mem.roge_bites_done == nil then
		return false
	end
	return mem.roge_bites_done >= mem.roge_bites_total - 1
end

local function NightmareShadowRookResolveTarget(inst, explicit_target)
	local mem = NightmareShadowRookGetComboMem(inst)

	if NightmareShadowRookIsLastBite(inst) and mem ~= nil then
		local locked = mem.roge_final_target
		if locked ~= nil and locked:IsValid() then
			return locked
		end
	end

	if explicit_target ~= nil and explicit_target:IsValid() then
		return explicit_target
	end

	if inst.components.combat ~= nil then
		local combat_target = inst.components.combat.target
		if combat_target ~= nil and combat_target:IsValid() then
			return combat_target
		end
	end

	if inst.sg ~= nil and inst.sg.statemem ~= nil then
		local stored = inst.sg.statemem.target
		if stored ~= nil and stored:IsValid() then
			return stored
		end
	end

	return nil
end

local function NightmareShadowRookApplyTarget(inst, target)
	if not NightmareShadowRookTargetIsAttackable(inst, target) then
		return nil
	end
	if inst.sg ~= nil and inst.sg.statemem ~= nil then
		inst.sg.statemem.target = target
	end
	if inst.components.combat ~= nil and inst.components.combat.target ~= target then
		inst.components.combat:SetTarget(target)
	end
	return target
end

local function NightmareShadowRookSyncComboTarget(inst, explicit_target)
	return NightmareShadowRookApplyTarget(
		inst, NightmareShadowRookResolveTarget(inst, explicit_target))
end

local function NightmareShadowRookTryRetargetDuringCombo(inst, data)
	if not NightmareShadowRookIsInAttackCycle(inst) then
		return false
	end
	if NightmareShadowRookIsLastBite(inst) then
		return true
	end

	local explicit = data ~= nil and data.target or nil
	local target = nil

	if explicit ~= nil and explicit:IsValid()
		and NightmareShadowRookTargetIsAttackable(inst, explicit) then
		target = explicit
	elseif inst.components.combat ~= nil then
		local combat_target = inst.components.combat.target
		if combat_target ~= nil and combat_target:IsValid()
			and NightmareShadowRookTargetIsAttackable(inst, combat_target) then
			target = combat_target
		end
	end

	if target ~= nil then
		NightmareShadowRookApplyTarget(inst, target)
		inst:ForceFacePoint(target.Transform:GetWorldPosition())
	end

	return true
end

local function NightmareShadowRookGoToPreAttackTaunt(inst, target)
	target = NightmareShadowRookSyncComboTarget(inst, target)
	if target == nil then
		NightmareShadowRookClearComboMem(inst)
		inst.sg:GoToState("idle")
		return
	end
	inst.sg:GoToState(PRE_ATTACK_TAUNT_STATE, target)
end

local function NightmareShadowRookOnBiteFinished(inst)
	local mem = NightmareShadowRookGetComboMem(inst)
	if mem == nil or mem.roge_bites_total == nil then
		inst.sg:GoToState("idle")
		return
	end

	mem.roge_bites_done = (mem.roge_bites_done or 0) + 1

	if mem.roge_bites_done < mem.roge_bites_total then
		local target = NightmareShadowRookSyncComboTarget(inst, nil)
		if target == nil then
			NightmareShadowRookClearComboMem(inst)
			inst.sg:GoToState("idle")
			return
		end
		inst.sg.statemem.attack = true
		inst.sg:GoToState("attack", target)
	else
		NightmareShadowRookClearComboMem(inst)
		inst.sg:GoToState("idle")
	end
end

local function NightmareShadowRookEnterPreAttackTaunt(inst, target)
	target = NightmareShadowRookSyncComboTarget(inst, target)
	if target == nil then
		NightmareShadowRookClearComboMem(inst)
		inst.sg:GoToState("idle")
		return
	end
	inst.Physics:Stop()
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	inst.AnimState:PlayAnimation("taunt")
end

local function NightmareShadowRookEnterAttack(inst, target)
	target = NightmareShadowRookSyncComboTarget(inst, target)
	if target == nil then
		NightmareShadowRookClearComboMem(inst)
		inst.sg:GoToState("idle")
		return
	end

	if NightmareShadowRookIsLastBite(inst) then
		local mem = NightmareShadowRookGetComboMem(inst)
		if mem ~= nil then
			mem.roge_final_target = target
		end
	end

	inst.Physics:Stop()
	if inst.components.combat ~= nil then
		inst.components.combat:StartAttack()
	end
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	inst.AnimState:PlayAnimation("teleport_pre")
	inst.AnimState:PushAnimation("teleport", false)
end

local function NightmareShadowRookEnterAttackTeleport(inst, target)
	if NightmareShadowRookIsLastBite(inst) then
		local mem = NightmareShadowRookGetComboMem(inst)
		if mem ~= nil and mem.roge_final_target ~= nil and mem.roge_final_target:IsValid() then
			target = mem.roge_final_target
		end
	else
		target = NightmareShadowRookSyncComboTarget(inst, target)
	end

	if target == nil or not NightmareShadowRookTargetIsAttackable(inst, target) then
		NightmareShadowRookClearComboMem(inst)
		inst.sg:GoToState("idle")
		return
	end

	inst.sg.statemem.target = target
	if inst.components.health ~= nil then
		inst.components.health:SetInvincible(true)
	end
	inst.Physics:Teleport(target.Transform:GetWorldPosition())
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	inst.AnimState:PlayAnimation("teleport_atk")
	inst.AnimState:PushAnimation("teleport_pst", false)
end

local function NightmareShadowRookOnAttackFacingUpdate(inst)
	if NightmareShadowRookIsLastBite(inst) then
		return
	end
	local target = NightmareShadowRookSyncComboTarget(inst, nil)
	if target ~= nil and target:IsValid() then
		inst:ForceFacePoint(target.Transform:GetWorldPosition())
	end
end

local function NightmareShadowRookReplaceAttackStates(sg)
	if sg._roge_shadow_rook_states_replaced then
		return
	end
	sg._roge_shadow_rook_states_replaced = true

	sg.states[PRE_ATTACK_TAUNT_STATE] = State({
		name = PRE_ATTACK_TAUNT_STATE,
		tags = { "busy", "taunt", "nointerrupt" },

		onenter = NightmareShadowRookEnterPreAttackTaunt,
		onupdate = NightmareShadowRookOnAttackFacingUpdate,

		timeline = {
			ShadowChess.Functions.ExtendedSoundTimelineEvent(7 * FRAMES, "taunt"),
			TimeEvent(45 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events = {
			EventHandler("doattack", function(inst, data)
				NightmareShadowRookTryRetargetDuringCombo(inst, data)
			end),
			EventHandler("animover", function(inst)
				if not inst.AnimState:AnimDone() then
					return
				end
				local target = NightmareShadowRookSyncComboTarget(inst, nil)
				if target ~= nil then
					inst.sg:GoToState("attack", target)
				else
					NightmareShadowRookClearComboMem(inst)
					inst.sg:GoToState("idle")
				end
			end),
		},
	})

	sg.states.attack = State({
		name = "attack",
		tags = { "attack", "busy" },

		onenter = NightmareShadowRookEnterAttack,
		onupdate = NightmareShadowRookOnAttackFacingUpdate,

		timeline = {
			ShadowChess.Functions.ExtendedSoundTimelineEvent(0, "attack_grunt"),
			ShadowChess.Functions.ExtendedSoundTimelineEvent(12 * FRAMES, "teleport"),
			TimeEvent(19 * FRAMES, function(inst)
				inst.sg:AddStateTag("noattack")
				if inst.components.health ~= nil then
					inst.components.health:SetInvincible(true)
				end
			end),
		},

		events = {
			EventHandler("doattack", function(inst, data)
				NightmareShadowRookTryRetargetDuringCombo(inst, data)
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg.statemem.attack = true
				local target
				if NightmareShadowRookIsLastBite(inst) then
					local mem = NightmareShadowRookGetComboMem(inst)
					target = mem ~= nil and mem.roge_final_target or inst.sg.statemem.target
				else
					target = NightmareShadowRookSyncComboTarget(inst, nil)
				end
				if target == nil or not NightmareShadowRookTargetIsAttackable(inst, target) then
					NightmareShadowRookClearComboMem(inst)
					inst.sg:GoToState("idle")
					return
				end
				inst.sg:GoToState("attack_teleport", target)
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.attack then
				if inst.components.health ~= nil then
					inst.components.health:SetInvincible(false)
				end
			end
		end,
	})

	sg.states.attack_teleport = State({
		name = "attack_teleport",
		tags = { "attack", "busy", "noattack" },

		onenter = NightmareShadowRookEnterAttackTeleport,

		timeline = {
			ShadowChess.Functions.ExtendedSoundTimelineEvent(0, "attack"),
			TimeEvent(17 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("noattack")
				if inst.components.health ~= nil then
					inst.components.health:SetInvincible(false)
				end
				if inst.components.combat ~= nil then
					inst.components.combat:DoAreaAttack(
						inst, inst.components.combat.hitrange, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
				end
			end),
			TimeEvent(34 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events = {
			EventHandler("doattack", function(inst, data)
				NightmareShadowRookTryRetargetDuringCombo(inst, data)
			end),
			EventHandler("animqueueover", function(inst)
				NightmareShadowRookOnBiteFinished(inst)
			end),
		},

		onexit = function(inst)
			if inst.components.health ~= nil then
				inst.components.health:SetInvincible(false)
			end
		end,
	})
end

local function NightmareShadowRookPatchDoattack(sg)
	local doattack = sg.events.doattack
	if doattack == nil or doattack._roge_shadow_rook_doattack_patched then
		return
	end
	doattack._roge_shadow_rook_doattack_patched = true
	doattack.fn = function(inst, data)
		if inst.components.health:IsDead() then
			return
		end
		if NightmareShadowRookTryRetargetDuringCombo(inst, data) then
			return
		end
		if inst.sg:HasStateTag("levelup") then
			return
		end
		local can_start = not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")
		if not can_start then
			return
		end
		local target = NightmareShadowRookSyncComboTarget(inst, data ~= nil and data.target or nil)
		if target == nil then
			return
		end
		NightmareShadowRookBeginCombo(inst)
		NightmareShadowRookGoToPreAttackTaunt(inst, target)
	end
end

local function NightmareShadowRookPatchVanillaTaunt(sg)
	local taunt = sg.states ~= nil and sg.states.taunt or nil
	if taunt == nil or taunt._roge_shadow_rook_vanilla_taunt_patched then
		return
	end
	taunt._roge_shadow_rook_vanilla_taunt_patched = true
	taunt.onenter = function(inst)
		inst.sg:GoToState("idle")
	end
	taunt.events = {}
	taunt.timeline = {}
end

local function NightmareShadowRookHookCombatRetarget(inst)
	if inst._roge_shadow_rook_combat_hooked or inst.components.combat == nil then
		return
	end
	inst._roge_shadow_rook_combat_hooked = true

	local combat = inst.components.combat
	local old_settarget = combat.SetTarget
	combat.SetTarget = function(self, target, ...)
		old_settarget(self, target, ...)
		local owner = self.inst
		if owner ~= nil and owner:IsValid()
			and NightmareShadowRookIsInAttackCycle(owner)
			and not NightmareShadowRookIsLastBite(owner)
			and target ~= nil and target:IsValid()
			and NightmareShadowRookTargetIsAttackable(owner, target) then
			if owner.sg ~= nil and owner.sg.statemem ~= nil then
				owner.sg.statemem.target = target
			end
		end
	end
end

AddStategraphPostInit("shadow_rook", function(sg)
	NightmareShadowRookReplaceAttackStates(sg)
	NightmareShadowRookPatchVanillaTaunt(sg)
	NightmareShadowRookPatchDoattack(sg)
end)

AddPrefabPostInit("shadow_rook", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, NightmareShadowRookHookCombatRetarget)
end)

AddBrainPostInit("shadow_rookbrain", function(self)
	function self:OnStart()
		local inst = self.inst
		local START_FACE_DIST = 8
		local KEEP_FACE_DIST = 15

		local function ShouldChase()
			self._shouldchase =
				not inst.components.combat:HasTarget()
				or not inst.components.combat:InCooldown()
				or not inst:IsNear(
					inst.components.combat.target,
					inst.components.combat.attackrange + (self._shouldchase and -2 or 2))
			return self._shouldchase
		end

		local function GetFaceTargetFn()
			local target = inst.components.combat.target
				or FindClosestPlayerToInst(inst, START_FACE_DIST, true)
			return target ~= nil and not target:HasTag("notarget") and target or nil
		end

		local function KeepFaceTargetFn(target)
			return target.components.health ~= nil
				and not target.components.health:IsDead()
				and not target:HasTag("playerghost")
				and not target:HasTag("notarget")
				and inst:IsNear(target, KEEP_FACE_DIST)
		end

		local root = PriorityNode({
			WhileNode(function() return ShouldChase() end, "Chase",
				ChaseAndAttack(inst, nil, 40)),
			FaceEntity(inst, GetFaceTargetFn, KeepFaceTargetFn),
			ParallelNode{
				SequenceNode{
					WaitNode(TUNING.SHADOW_CHESSPIECE_DESPAWN_TIME),
					ActionNode(function() inst:PushEvent("despawn") end),
				},
				Wander(inst),
			},
		}, .25)

		self.bt = BT(inst, root)
	end
end)

local _roge_special_attacks = rawget(GLOBAL, "SPECIAL_ATTACKS_CONFIG") or {}
_roge_special_attacks["shadow_rook"] = { event = "doattack" }
rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)
