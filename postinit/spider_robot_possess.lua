----------------------------------------------------------------------
-- 遗迹守卫 (spider_robot)：附身 (Poss2) 时可正常激光攻击
-- 原版 doattack 需 8 码内或卡住才进 laserbeam，附身操控时经常打不出
----------------------------------------------------------------------

local _roge_special_attacks = rawget(GLOBAL, "SPECIAL_ATTACKS_CONFIG") or {}
_roge_special_attacks["spider_robot"] = { event = "doattack" }
rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)

local ROGE_SPIDER_ROBOT_BEAM_RANGE = 12

local function RogeSpiderRobotResolveTarget(inst, target)
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

function RogeSpiderRobotDoLaserAttack(inst, target, ignore_range)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "spider_robot" then
		return false
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("busy") then
		return true
	end

	target = RogeSpiderRobotResolveTarget(inst, target)
	if target == nil then
		return false
	end

	if inst.components.combat ~= nil then
		inst.components.combat:SetTarget(target)
		if inst.components.combat:InCooldown() then
			inst.components.combat:ResetCooldown()
		end
	end
	inst:ForceFacePoint(target.Transform:GetWorldPosition())

	if not ignore_range and not inst:IsNear(target, ROGE_SPIDER_ROBOT_BEAM_RANGE) then
		if inst.components.locomotor ~= nil and not inst.sg:HasStateTag("busy") then
			inst.components.locomotor:GoToEntity(target, nil, ROGE_SPIDER_ROBOT_BEAM_RANGE - 1)
		end
		return true
	end

	if inst.sg:HasState("laserbeam") then
		inst.sg:GoToState("laserbeam", target)
		return true
	end

	inst:PushEvent("doattack", { target = target })
	return true
end

local function RogeTryPossessedSpiderRobotAttack(player, target)
	if player == nil or player.Poss2 == nil or player.Poss2.Possessing == nil then
		return false
	end
	local possessed = player.Poss2.Possessing
	if possessed.prefab ~= "spider_robot" then
		return false
	end
	return RogeSpiderRobotDoLaserAttack(possessed, target, true)
end

AddStategraphPostInit("SGspider_robot", function(sg)
	local doattack = sg.events.doattack
	if doattack ~= nil and not doattack._roge_spider_robot_possess_patched then
		doattack._roge_spider_robot_possess_patched = true
		local old_fn = doattack.fn
		doattack.fn = function(inst, data)
			if inst.components.health:IsDead() or inst.sg:HasStateTag("busy") then
				return
			end

			local target = data ~= nil and data.target or nil
			if target == nil and inst.components.combat ~= nil then
				target = inst.components.combat.target
			end

			if target ~= nil and target:IsValid()
				and inst:IsNear(target, ROGE_SPIDER_ROBOT_BEAM_RANGE)
			then
				inst.sg:GoToState("laserbeam", target)
				return
			end

			if inst.components.stuckdetection ~= nil and inst.components.stuckdetection:IsStuck() then
				inst.sg:GoToState("laserbeam")
				return
			end

			return old_fn(inst, data)
		end
	end
end)

AddComponentPostInit("playercontroller", function(self)
	if self._roge_spider_robot_possess_patched then
		return
	end
	self._roge_spider_robot_possess_patched = true

	local _OnRemoteControllerAttackButton = self.OnRemoteControllerAttackButton
	self.OnRemoteControllerAttackButton = function(pc, attack_target, isreleased, noforce)
		if RogeTryPossessedSpiderRobotAttack(pc.inst, attack_target) then
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
		if RogeTryPossessedSpiderRobotAttack(pc.inst, target) then
			return
		end
		return _DoAttackButton(pc, retarget, isleftmouse)
	end

	local _OnRemoteAttackButton = self.OnRemoteAttackButton
	self.OnRemoteAttackButton = function(pc, target, force_attack, noforce, isleftmouse, isreleased)
		if RogeTryPossessedSpiderRobotAttack(pc.inst, target) then
			return
		end
		return _OnRemoteAttackButton(pc, target, force_attack, noforce, isleftmouse, isreleased)
	end
end)
