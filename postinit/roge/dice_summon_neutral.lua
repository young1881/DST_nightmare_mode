-- 骰子召唤物：仅玩家（含附身操控）可对其索敌，其他生物不会主动攻击
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

function RogeIsDiceSummon(ent)
	return ent ~= nil and ent:IsValid()
		and (ent._roge_summoned or ent:HasTag("roge_dice_summon"))
end

function RogeIsPlayerControlledCombat(attacker)
	if attacker == nil or not attacker:IsValid() then
		return false
	end
	if attacker:HasTag("player") then
		return true
	end
	for _, player in ipairs(AllPlayers) do
		if player ~= nil and player:IsValid() and player.Poss2 ~= nil
			and player.Poss2.Possessing == attacker then
			return true
		end
	end
	return false
end

function RogeMarkDiceSummon(inst)
	if inst == nil or not inst:IsValid() or inst._roge_dice_summon_marked then
		return
	end
	inst._roge_dice_summon_marked = true
	inst._roge_summoned = true
	inst:AddTag("roge_dice_summon")
end

function RogeMarkDiceSummonDeep(inst, seen)
	if inst == nil or not inst:IsValid() then
		return
	end
	seen = seen or {}
	if seen[inst] then
		return
	end
	seen[inst] = true
	RogeMarkDiceSummon(inst)
	if inst.components.leader ~= nil then
		for follower in pairs(inst.components.leader.followers) do
			RogeMarkDiceSummonDeep(follower, seen)
		end
	end
end

AddComponentPostInit("combat", function(combat)
	if combat._roge_dice_summon_neutral_patched then
		return
	end
	combat._roge_dice_summon_neutral_patched = true

	local old_CanTarget = combat.CanTarget
	function combat:CanTarget(target, ...)
		if RogeIsDiceSummon(target) and not RogeIsPlayerControlledCombat(self.inst) then
			return false
		end
		return old_CanTarget(self, target, ...)
	end

	if combat.KeepTarget ~= nil then
		local old_KeepTarget = combat.KeepTarget
		function combat:KeepTarget(target, ...)
			if RogeIsDiceSummon(target) and not RogeIsPlayerControlledCombat(self.inst) then
				return false
			end
			return old_KeepTarget(self, target, ...)
		end
	end
end)
