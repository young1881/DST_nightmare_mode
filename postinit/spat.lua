----------------------------------------------------------------------
-- 钢羊 (spat)：附身 (Poss2) 时可正常吐痰攻击
-- 附身 mod 推送的 "spit" 事件原版 SG 未处理，且 defaultdamage=0 会被拦截
----------------------------------------------------------------------

-- 肉鸽模式：移速 5.5，攻击间隔延长（原版 run 7 / walk 1.5 / period 3）
local ROGE_SPAT_RUN_SPEED = 5.5
local ROGE_SPAT_WALK_SPEED = ROGE_SPAT_RUN_SPEED * (1.5 / 7)
local ROGE_SPAT_ATTACK_PERIOD = 5

local function RogeSpatApplyRogeStats(inst)
	if not GetModConfigData("roge") then
		return
	end
	local locomotor = inst.components.locomotor
	if locomotor ~= nil then
		locomotor.runspeed = ROGE_SPAT_RUN_SPEED
		locomotor.walkspeed = ROGE_SPAT_WALK_SPEED
	end
	local combat = inst.components.combat
	if combat ~= nil then
		combat:SetAttackPeriod(ROGE_SPAT_ATTACK_PERIOD)
	end
end

local function RogeSpatEquipSnotbomb(inst)
	if inst.weaponitems == nil or inst.weaponitems.snotbomb == nil then
		return false
	end
	local bomb = inst.weaponitems.snotbomb
	if inst.components.inventory == nil or bomb.components.equippable == nil then
		return false
	end
	if not bomb.components.equippable:IsEquipped() then
		inst.components.inventory:Equip(bomb)
	end
	return true
end

local function RogeSpatResolveAttackTarget(inst, target)
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

local function RogeSpatDoSpitAttack(inst, target)
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack") then
		return false
	end

	target = RogeSpatResolveAttackTarget(inst, target)
	if target ~= nil and inst.components.combat ~= nil then
		inst.components.combat:SetTarget(target)
		if inst.components.combat:InCooldown() then
			inst.components.combat:ResetCooldown()
		end
	end

	RogeSpatEquipSnotbomb(inst)

	if inst.sg:HasState("launchprojectile") then
		inst.sg:GoToState("launchprojectile", target)
		return true
	end

	inst:PushEvent("doattack", { target = target })
	return true
end

local function RogeSpatEnsureCombatDamageForPossess(inst)
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	if combat.defaultdamage == nil or combat.defaultdamage <= 0 then
		combat:SetDefaultDamage(TUNING.SPAT_PHLEGM_DAMAGE or 5)
	end
end

AddStategraphPostInit("spat", function(sg)
	local spit = sg.events.spit
	if spit == nil then
		spit = EventHandler("spit", function() end)
		sg.events.spit = spit
	end
	local old_spit = spit.fn
	spit.fn = function(inst, data)
		local target = data ~= nil and data.target or nil
		if RogeSpatDoSpitAttack(inst, target) then
			return
		end
		if old_spit ~= nil then
			old_spit(inst, data)
		end
	end
end)

AddPrefabPostInit("spat", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	RogeSpatApplyRogeStats(inst)
	inst:DoTaskInTime(0, RogeSpatApplyRogeStats)

	RogeSpatEnsureCombatDamageForPossess(inst)

	inst:ListenForEvent("spit", function(spat, data)
		RogeSpatDoSpitAttack(spat, data ~= nil and data.target or nil)
	end)
end)

-- 附身 mod 在攻击前检查 defaultdamage；钢羊伤害在武器上，此处再保底一次
AddComponentPostInit("playercontroller", function(self)
	if self._roge_spat_possess_attack_patched then
		return
	end
	self._roge_spat_possess_attack_patched = true

	local _OnRemoteControllerAttackButton = self.OnRemoteControllerAttackButton
	self.OnRemoteControllerAttackButton = function(pc, target, isreleased, noforce)
		local player = pc.inst
		if player ~= nil and player.Poss2 ~= nil and player.Poss2.Possessing ~= nil then
			local possessed = player.Poss2.Possessing
			if possessed.prefab == "spat" then
				RogeSpatEnsureCombatDamageForPossess(possessed)
			end
		end
		return _OnRemoteControllerAttackButton(pc, target, isreleased, noforce)
	end
end)
