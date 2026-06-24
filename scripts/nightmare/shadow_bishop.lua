----------------------------------------------------------------------
-- 暗影主教：移植永不妥协（2039181790）冲刺攻击，替换原版站桩放电
----------------------------------------------------------------------

if TUNING.SHADOW_BISHOP ~= nil then
	TUNING.SHADOW_BISHOP.ATTACK_RANGE = { 8, 10, 12 }
	TUNING.SHADOW_BISHOP.ATTACK_PERIOD = { 14, 15, 16 }
	TUNING.SHADOW_BISHOP.DAMAGE = { 15, 25, 35 }
end

local AREAATTACK_EXCLUDETAGS = {
	"INLIMBO", "notarget", "invisible", "noattack", "flight",
	"playerghost", "shadow", "shadowchesspiece", "shadowcreature",
}

local CHARGE_SPEED = { 16, 14, 13 }
local TELEPORT_DIST = { 0.8, 1.2, 1.35 }
local CHARGE_COUNT_OFFSET = 2 -- 每轮冲刺次数 = level + 2

local function NightmareShadowBishopLevel(inst)
	local lv = inst.level or 1
	if lv < 1 then
		return 1
	end
	if lv > 3 then
		return 3
	end
	return lv
end

local function DoSwarmAttack(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:DoAreaAttack(
			inst, inst.components.combat.hitrange, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
	end
end

local function DoSwarmFX(inst)
	local fx = SpawnPrefab("shadow_bishop_fx")
	if fx == nil then
		return
	end
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx.Transform:SetScale(inst.Transform:GetScale())
	fx.AnimState:SetMultColour(inst.AnimState:GetMultColour())
end

local function NightmareShadowBishopFindTeleportOffset(inst, pos, tries, min_player_dist)
	local bestoffset = nil
	local lv = NightmareShadowBishopLevel(inst)
	local angles = { 1, 60, 120, 180, 240, 300, 360 }

	for i = 1, tries do
		local random_choose = math.floor(math.random(1, 7))
		local choose_angle = angles[random_choose]
		if inst._nm_shadow_bishop_angle ~= nil
			and math.abs(choose_angle - inst._nm_shadow_bishop_angle) <= 60 then
			if i == 1 then
				if random_choose + 4 <= 7 then
					random_choose = random_choose + 4
				elseif random_choose - 4 > 0 then
					random_choose = random_choose - 4
				end
			else
				local correcting_angle = math.floor(math.random(1, 3))
				if random_choose + correcting_angle <= 7 then
					random_choose = random_choose + correcting_angle
				elseif random_choose - 4 > 0 then
					random_choose = random_choose - 4
				end
			end
			inst._nm_shadow_bishop_angle = angles[random_choose]
		else
			inst._nm_shadow_bishop_angle = choose_angle
		end

		local offset = FindWalkableOffset(
			pos, inst._nm_shadow_bishop_angle, 12 * TELEPORT_DIST[lv], 8, false, true)
		if offset ~= nil then
			local player = FindClosestPlayerInRange(
				pos.x + offset.x, 0, pos.z + offset.z, min_player_dist, true)
			if player == nil then
				return offset, false
			elseif i == tries then
				return nil, true
			end
		end
	end

	return nil, false
end

local function NightmareShadowBishopResolveTarget(inst, target)
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

local function NightmareShadowBishopTargetIsAttackable(inst, target)
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

local function NightmareShadowBishopIsPlayerControlled(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if inst.Poss2 ~= nil and (inst.Poss2.Level or 0) > 0 then
		return true
	end
	if inst.Poss2 ~= nil and inst.Poss2.Possessors ~= nil then
		for _ in pairs(inst.Poss2.Possessors) do
			return true
		end
	end
	return false
end

local function NightmareShadowBishopClearAttackIntent(inst)
	inst._nm_sb_attack_target = nil
	inst._nm_sb_taunt_required = nil
end

local function NightmareShadowBishopMarkTauntComplete(inst)
	inst._nm_sb_taunt_complete = true
end

local function NightmareShadowBishopConsumeTauntComplete(inst)
	if inst._nm_sb_taunt_complete then
		inst._nm_sb_taunt_complete = nil
		return true
	end
	return false
end

local function NightmareShadowBishopIsPreAttackTauntState(inst)
	return inst.sg ~= nil and inst.sg.currentstate ~= nil
		and inst.sg.currentstate.name == "nm_pre_attack_taunt"
end

local function NightmareShadowBishopIsInAttackCycle(inst)
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("attack") then
		return true
	end
	if inst.sg.currentstate ~= nil then
		local state = inst.sg.currentstate.name
		if state == "attack" or state == "attack_loop"
			or state == "attack_loop_pst" or state == "attack_pst" then
			return true
		end
	end
	return false
end

local function NightmareShadowBishopBeginPreAttackTaunt(inst, target)
	target = NightmareShadowBishopResolveTarget(inst, target)
	if not NightmareShadowBishopTargetIsAttackable(inst, target) then
		return false
	end
	inst._nm_sb_attack_target = target
	inst._nm_sb_taunt_required = true
	inst.sg:GoToState("nm_pre_attack_taunt")
	return true
end

local function NightmareShadowBishopResumePreAttackTauntIfNeeded(inst)
	if not inst._nm_sb_taunt_required then
		return false
	end
	if inst.sg == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return false
	end
	if NightmareShadowBishopIsInAttackCycle(inst)
		or NightmareShadowBishopIsPreAttackTauntState(inst) then
		return true
	end
	if inst.sg:HasStateTag("hit") then
		return false
	end
	inst.sg:GoToState("nm_pre_attack_taunt")
	return true
end

local function NightmareShadowBishopScheduleResumePreAttackTaunt(inst)
	if not inst._nm_sb_taunt_required then
		return
	end
	inst:DoTaskInTime(0, function(i)
		if i:IsValid() then
			NightmareShadowBishopResumePreAttackTauntIfNeeded(i)
		end
	end)
end

local function NightmareShadowBishopRequestAttack(inst, target)
	if NightmareShadowBishopIsInAttackCycle(inst) then
		return true
	end
	if NightmareShadowBishopIsPreAttackTauntState(inst) then
		target = NightmareShadowBishopResolveTarget(inst, target)
		if target ~= nil then
			inst._nm_sb_attack_target = target
		end
		return true
	end
	if inst.sg ~= nil and inst.sg:HasStateTag("hit") then
		target = NightmareShadowBishopResolveTarget(inst, target)
		if target ~= nil and target:IsValid() then
			inst.sg.statemem.doattacktarget = target
		end
		return true
	end
	return NightmareShadowBishopBeginPreAttackTaunt(inst, target)
end

local function NightmareShadowBishopApplyPreAttackTarget(inst, target)
	target = NightmareShadowBishopResolveTarget(inst, target)
	if target == nil or not NightmareShadowBishopTargetIsAttackable(inst, target) then
		return nil
	end
	inst._nm_sb_attack_target = target
	inst:ForceFacePoint(target.Transform:GetWorldPosition())
	return target
end

local function NightmareShadowBishopPatchDoattack(sg)
	local doattack = sg.events.doattack
	if doattack == nil or doattack._nm_shadow_bishop_doattack_patched then
		return
	end
	doattack._nm_shadow_bishop_doattack_patched = true
	doattack.fn = function(inst, data)
		if inst.components.health:IsDead() then
			return
		end
		local target = data ~= nil and data.target or nil

		if NightmareShadowBishopIsInAttackCycle(inst) then
			return
		end
		if NightmareShadowBishopIsPreAttackTauntState(inst) then
			NightmareShadowBishopApplyPreAttackTarget(inst, target)
			return
		end

		if NightmareShadowBishopIsPlayerControlled(inst) then
			if inst._nm_sb_taunt_required then
				NightmareShadowBishopClearAttackIntent(inst)
			end
			if inst.sg:HasStateTag("taunt") or inst.sg:HasStateTag("levelup") then
				return
			end
			local can_start = not inst.sg:HasStateTag("busy")
				or (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute"))
			if not can_start then
				return
			end
			NightmareShadowBishopRequestAttack(inst, target)
			return
		end

		if inst.sg:HasStateTag("taunt") then
			return
		end
		if inst._nm_sb_taunt_required then
			local resolved = NightmareShadowBishopApplyPreAttackTarget(inst, target)
			if NightmareShadowBishopResumePreAttackTauntIfNeeded(inst) then
				return
			end
			if inst.sg:HasStateTag("hit") and resolved ~= nil then
				inst.sg.statemem.doattacktarget = resolved
			elseif resolved ~= nil then
				NightmareShadowBishopBeginPreAttackTaunt(inst, resolved)
			end
			return
		end
		if inst.sg:HasStateTag("levelup") then
			return
		end
		local can_start = not inst.sg:HasStateTag("busy")
			or (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute"))
		if not can_start then
			return
		end
		NightmareShadowBishopRequestAttack(inst, target)
	end
end

local function NightmareShadowBishopPatchAttacked(sg)
	local attacked = sg.events.attacked
	if attacked == nil or attacked._nm_shadow_bishop_attacked_patched then
		return
	end
	attacked._nm_shadow_bishop_attacked_patched = true
	local old_attacked = attacked.fn
	attacked.fn = function(inst, data)
		if NightmareShadowBishopIsPreAttackTauntState(inst)
			or (inst._nm_sb_taunt_required and inst.sg:HasStateTag("taunt")) then
			return
		end
		old_attacked(inst, data)
	end
end

local function NightmareShadowBishopPatchHitState(sg)
	local hit = sg.states ~= nil and sg.states.hit or nil
	if hit == nil or hit._nm_shadow_bishop_hit_patched then
		return
	end
	hit._nm_shadow_bishop_hit_patched = true
	if hit.timeline ~= nil then
		for _, te in ipairs(hit.timeline) do
			if te.time == 14 * FRAMES and te.fn ~= nil then
				te.fn = function(inst)
					if inst:WantsToLevelUp() then
						inst.sg:GoToState("levelup")
						return
					end
					if inst.sg.statemem.doattacktarget == nil then
						inst.sg:RemoveStateTag("busy")
					end
				end
				break
			end
		end
	end
	if hit.events ~= nil then
		for _, ev in ipairs(hit.events) do
			if ev ~= nil and ev.name == "doattack" then
				ev.fn = function(inst, data)
					local target = data ~= nil and data.target
						or (inst.components.combat ~= nil and inst.components.combat.target)
					if inst.sg:HasStateTag("busy") then
						inst.sg.statemem.doattacktarget = target
					else
						NightmareShadowBishopRequestAttack(inst, target)
					end
					return true
				end
			elseif ev ~= nil and ev.name == "animover" then
				ev.fn = function(inst)
					if not inst.AnimState:AnimDone() then
						return
					end
					if inst:WantsToLevelUp() then
						inst.sg:GoToState("levelup")
						return
					end
					local pending = inst.sg.statemem.doattacktarget
					if pending ~= nil then
						inst.sg.statemem.doattacktarget = nil
						if NightmareShadowBishopRequestAttack(inst, pending) then
							return
						end
					end
					if inst._nm_sb_taunt_required then
						if NightmareShadowBishopIsPlayerControlled(inst) then
							NightmareShadowBishopClearAttackIntent(inst)
							inst.sg:GoToState("idle")
						else
							NightmareShadowBishopScheduleResumePreAttackTaunt(inst)
						end
					else
						inst.sg:GoToState("idle")
					end
				end
			end
		end
	end
	local old_onexit = hit.onexit
	hit.onexit = function(inst)
		if old_onexit ~= nil then
			old_onexit(inst)
		end
		if inst._nm_sb_taunt_required then
			if NightmareShadowBishopIsPlayerControlled(inst) then
				NightmareShadowBishopClearAttackIntent(inst)
			else
				NightmareShadowBishopScheduleResumePreAttackTaunt(inst)
			end
		end
	end
end

-- 禁用原版 taunt 状态（大脑自发战吼 / 战后战吼等误入时直接 idle）
local function NightmareShadowBishopPatchVanillaTaunt(sg)
	local taunt = sg.states ~= nil and sg.states.taunt or nil
	if taunt == nil or taunt._nm_shadow_bishop_vanilla_taunt_patched then
		return
	end
	taunt._nm_shadow_bishop_vanilla_taunt_patched = true
	taunt.onenter = function(inst)
		inst.sg:GoToState("idle")
	end
	taunt.events = {}
	taunt.timeline = {}
end

local function NightmareShadowBishopPatchAttackPst(sg)
	local attack_pst = sg.states ~= nil and sg.states.attack_pst or nil
	if attack_pst == nil or attack_pst._nm_shadow_bishop_pst_patched then
		return
	end
	attack_pst._nm_shadow_bishop_pst_patched = true
	if attack_pst.events == nil then
		return
	end
	for _, ev in ipairs(attack_pst.events) do
		if ev ~= nil and ev.name == "animover" then
			ev.fn = function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end
			return
		end
	end
end

AddStategraphPostInit("shadow_bishop", function(sg)
	local states = {
		State({
			name = "nm_pre_attack_taunt",
			tags = { "busy", "taunt", "nointerrupt" },

			onenter = function(inst)
				inst.Physics:Stop()
				inst._nm_sb_taunt_complete = nil
				inst.AnimState:PlayAnimation("taunt")
			end,

			timeline = {
				TimeEvent(3 * FRAMES, function(inst)
					if inst.sounds ~= nil and inst.sounds.taunt ~= nil then
						inst.SoundEmitter:PlaySound(inst.sounds.taunt)
					end
				end),
			},

			events = {
				EventHandler("doattack", function(inst, data)
					NightmareShadowBishopApplyPreAttackTarget(
						inst, data ~= nil and data.target or nil)
				end),
				EventHandler("animover", function(inst)
					if not inst.AnimState:AnimDone() then
						return
					end
					local target = inst._nm_sb_attack_target
					if inst._nm_sb_taunt_required
						and NightmareShadowBishopTargetIsAttackable(inst, target) then
						inst.sg.statemem.nm_sb_taunt_to_attack = true
						inst._nm_sb_taunt_required = nil
						inst._nm_sb_attack_target = nil
						NightmareShadowBishopMarkTauntComplete(inst)
						inst.sg:GoToState("attack", target)
						return
					end
					NightmareShadowBishopClearAttackIntent(inst)
					inst.sg:GoToState("idle")
				end),
			},

			onexit = function(inst)
				if inst.sg.statemem.nm_sb_taunt_to_attack then
					inst.sg.statemem.nm_sb_taunt_to_attack = nil
					return
				end
				if inst._nm_sb_taunt_required then
					if NightmareShadowBishopIsPlayerControlled(inst) then
						NightmareShadowBishopClearAttackIntent(inst)
					else
						NightmareShadowBishopScheduleResumePreAttackTaunt(inst)
					end
				end
			end,
		}),

		State({
			name = "attack",
			tags = { "attack", "busy" },

			onenter = function(inst, target)
				if not NightmareShadowBishopConsumeTauntComplete(inst) then
					NightmareShadowBishopBeginPreAttackTaunt(inst, target)
					return
				end
				target = NightmareShadowBishopResolveTarget(inst, target)
				if not NightmareShadowBishopTargetIsAttackable(inst, target) then
					inst.sg:GoToState("idle")
					return
				end
				if target ~= nil and target:IsValid() then
					inst.sg.statemem.target = target
					inst.sg.statemem.targetpos = target:GetPosition()
				end
				inst.Physics:Stop()
				if inst.components.combat ~= nil then
					inst.components.combat:StartAttack()
				end
				inst.AnimState:PlayAnimation("atk_side_pre")
			end,

			onupdate = function(inst)
				if inst.sg.statemem.target ~= nil then
					if inst.sg.statemem.target:IsValid() then
						inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
					else
						inst.sg.statemem.target = nil
					end
				end
			end,

			timeline = {
				TimeEvent(8 * FRAMES, function(inst)
					inst.sg:AddStateTag("noattack")
					if inst.components.health ~= nil then
						inst.components.health:SetInvincible(true)
					end
					DoSwarmFX(inst)
					if inst.sounds ~= nil and inst.sounds.attack ~= nil then
						inst.SoundEmitter:PlaySound(inst.sounds.attack, "attack")
					end
				end),
			},

			events = {
				EventHandler("animover", function(inst)
					inst.sg.mem.charge_count = NightmareShadowBishopLevel(inst) + CHARGE_COUNT_OFFSET
					if inst.AnimState:AnimDone() then
						inst.sg.statemem.attack = true
						inst.sg:GoToState("attack_loop", inst.sg.statemem.target)
					end
				end),
			},

			onexit = function(inst)
				if not inst.sg.statemem.attack then
					if inst.components.health ~= nil then
						inst.components.health:SetInvincible(false)
					end
					inst.SoundEmitter:KillSound("attack")
				end
			end,
		}),

		State({
			name = "attack_loop",
			tags = { "attack", "busy", "noattack" },

			onenter = function(inst, target)
				if inst.components.health ~= nil then
					inst.components.health:SetInvincible(true)
				end
				inst.sg.statemem.target = target
				inst.Physics:Stop()

				local pos = inst.sg.statemem.target ~= nil
					and inst.sg.statemem.target:IsValid()
					and inst.sg.statemem.target:GetPosition()
					or inst:GetPosition()

				local bestoffset, surrounded = NightmareShadowBishopFindTeleportOffset(inst, pos, 8, 8)
				if bestoffset ~= nil then
					inst.Physics:Teleport(pos.x + bestoffset.x, 0, pos.z + bestoffset.z)
				end
				inst.sg.statemem.surrounded = surrounded

				if target ~= nil and target:IsValid()
					and target.components.health ~= nil
					and not target.components.health:IsDead() then
					local lv = NightmareShadowBishopLevel(inst)
					inst.sg.statemem.speed = CHARGE_SPEED[lv]
					if inst:IsNear(target, .5) then
						inst.Physics:Stop()
					elseif inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
						inst.sg.statemem.charge_delay = true
						inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
						local delay_time = inst.sg.statemem.surrounded and 0.95 or 0.5
						inst:DoTaskInTime(delay_time, function(i)
							if not i:IsValid() or i.sg == nil then
								return
							end
							i.sg.statemem.charge_delay = nil
							if i.sg.statemem.target ~= nil and i.sg.statemem.target:IsValid() then
								i:ForceFacePoint(i.sg.statemem.target.Transform:GetWorldPosition())
							end
						end)
					end
				end

				inst.AnimState:PlayAnimation("atk_side_loop_pre")

				local start_tick = TUNING.SHADOW_BISHOP ~= nil
					and TUNING.SHADOW_BISHOP.ATTACK_START_TICK
					or 0
				inst.sg.statemem.task = inst:DoPeriodicTask(0.15, DoSwarmAttack, start_tick)
				inst.sg.statemem.fxtask = inst:DoPeriodicTask(0.25, DoSwarmFX, .5)
				inst.sg:SetTimeout(50 * FRAMES)
			end,

			onupdate = function(inst)
				if inst.sg.statemem.target ~= nil then
					if not inst.sg.statemem.target:IsValid()
						or inst.sg.statemem.target.components.health == nil
						or inst.sg.statemem.target.components.health:IsDead() then
						inst.sg.statemem.target = nil
					elseif inst.sg.statemem.target:IsValid() and inst:IsNear(inst.sg.statemem.target, .5) then
						inst.Physics:Stop()
					elseif not inst.sg.statemem.charge_delay
						and inst.sg.statemem.speed
						and inst.sg.statemem.target:IsValid() then
						inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
					end
				end
			end,

			events = {
				EventHandler("animover", function(inst)
					if inst.AnimState:AnimDone()
						and inst.AnimState:IsCurrentAnimation("atk_side_loop_pre") then
						inst.AnimState:PlayAnimation("atk_side_loop", true)
					end
				end),
			},

			ontimeout = function(inst)
				inst.sg.statemem.attack = true
				inst.sg:GoToState("attack_loop_pst", inst.sg.statemem.target)
			end,

			onexit = function(inst)
				if inst.sg.statemem.task ~= nil then
					inst.sg.statemem.task:Cancel()
					inst.sg.statemem.task = nil
				end
				if inst.sg.statemem.fxtask ~= nil then
					inst.sg.statemem.fxtask:Cancel()
					inst.sg.statemem.fxtask = nil
				end
				if not inst.sg.statemem.attack then
					if inst.components.health ~= nil then
						inst.components.health:SetInvincible(false)
					end
					inst.SoundEmitter:KillSound("attack")
				end
			end,
		}),

		State({
			name = "attack_loop_pst",
			tags = { "attack", "busy", "noattack" },

			onenter = function(inst, target)
				inst.sg.statemem.target = target
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("atk_side_loop_pst")
			end,

			events = {
				EventHandler("animover", function(inst)
					if not inst.AnimState:AnimDone() then
						return
					end

					local pos = inst.sg.statemem.target ~= nil
						and inst.sg.statemem.target:IsValid()
						and inst.sg.statemem.target:GetPosition()
						or inst:GetPosition()
					local bestoffset = nil
					local minplayerdistsq = math.huge

					for i = 1, 4 do
						local offset = FindWalkableOffset(
							pos, math.random() * 2 * PI, 8 + math.random() * 2, 4, false, true)
						if offset ~= nil then
							local player, distsq = FindClosestPlayerInRange(
								pos.x + offset.x, 0, pos.z + offset.z, 6, true)
							if player == nil then
								bestoffset = offset
								break
							elseif distsq < minplayerdistsq then
								bestoffset = offset
								minplayerdistsq = distsq
							end
						end
					end

					if bestoffset ~= nil
						and (inst.sg.mem.charge_count == nil or inst.sg.mem.charge_count == 1) then
						inst.Physics:Teleport(pos.x + bestoffset.x, 0, pos.z + bestoffset.z)
					end

					inst.sg.statemem.attack = true
					inst.sg.mem.charge_count = inst.sg.mem.charge_count or 0
					inst.sg.mem.charge_count = inst.sg.mem.charge_count - 1

					if inst.sg.mem.charge_count > 0 and inst.sg.statemem.target ~= nil then
						inst.sg:GoToState("attack_loop", inst.sg.statemem.target)
					else
						inst.sg:GoToState("attack_pst")
					end
				end),
			},

			onexit = function(inst)
				if not inst.sg.statemem.attack then
					if inst.components.health ~= nil then
						inst.components.health:SetInvincible(false)
					end
				end
				inst.SoundEmitter:KillSound("attack")
			end,
		}),
	}

	for _, state in pairs(states) do
		sg.states[state.name] = state
	end

	NightmareShadowBishopPatchVanillaTaunt(sg)
	NightmareShadowBishopPatchAttackPst(sg)
	NightmareShadowBishopPatchDoattack(sg)
	NightmareShadowBishopPatchAttacked(sg)
	NightmareShadowBishopPatchHitState(sg)
end)

-- 原版大脑 idle 时每 3 秒 GoToState("taunt")，此处移除
AddBrainPostInit("shadow_bishopbrain", function(self)
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
					inst.components.combat.attackrange + (self._shouldchase and 0 or 3))
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
_roge_special_attacks["shadow_bishop"] = { event = "doattack" }
rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)

-- 冲刺时取消实体碰撞，避免卡身
AddPrefabPostInit("shadow_bishop", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst._nm_shadow_bishop_dash_physics then
		return
	end
	inst._nm_shadow_bishop_dash_physics = true
	RemovePhysicsColliders(inst)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	if not inst._nm_shadow_bishop_poss_watch then
		inst._nm_shadow_bishop_poss_watch = true
		inst._nm_shadow_bishop_was_controlled = false
		inst:DoPeriodicTask(0.25, function(i)
			if not i:IsValid() then
				return
			end
			local controlled = NightmareShadowBishopIsPlayerControlled(i)
			if controlled and i.brain ~= nil then
				i.brain:Stop()
			end
			if i._nm_shadow_bishop_was_controlled and not controlled then
				NightmareShadowBishopScheduleResumePreAttackTaunt(i)
			elseif not i._nm_shadow_bishop_was_controlled and controlled then
				if not NightmareShadowBishopIsInAttackCycle(i)
					and not NightmareShadowBishopIsPreAttackTauntState(i) then
					NightmareShadowBishopClearAttackIntent(i)
				end
			end
			i._nm_shadow_bishop_was_controlled = controlled
		end)
	end
end)
