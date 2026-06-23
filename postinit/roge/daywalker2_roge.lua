-- roge/daywalker2_roge.lua
-- 拾荒疯猪 daywalker2：Boss 池召唤，3500 血（第 8 天 6500），初始满装且装备不损坏

ROGE_DAYWALKER2_HEALTH = 3500
ROGE_DAYWALKER2_HEALTH_DAY8 = 6500
ROGE_DAYWALKER2_EQUIP_USES = 9999

local function RogeDaywalker2MakeEquipmentIndestructible(inst)
	if inst._roge_vanilla_onitemused == nil then
		inst._roge_vanilla_onitemused = inst.OnItemUsed
		inst._roge_vanilla_dropitem = inst.DropItem
		inst._roge_vanilla_dropitemasloot = inst.DropItemAsLoot
	end
	inst.OnItemUsed = function()
		return true
	end
	inst.DropItem = function() end
	inst.DropItemAsLoot = function() end
end

function RogeSetupDaywalker2RogeBoss(inst, target)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "daywalker2" then
		return
	end
	inst._roge_daywalker2_boss = true
	RogeSetupStandardHauntable(inst)

	if inst._roge_vanilla_make_defeated == nil and inst.MakeDefeated ~= nil then
		inst._roge_vanilla_make_defeated = inst.MakeDefeated
		inst.MakeDefeated = function(self, force)
			if self._roge_daywalker2_boss then
				if not self.looted and self.components.lootdropper ~= nil then
					self.defeated = true
					self.looted = true
					self.components.lootdropper:DropLoot(self:GetPosition())
				end
				if self.components.health ~= nil and not self.components.health:IsDead() then
					self.components.health:Kill()
				end
				return
			end
			return self._roge_vanilla_make_defeated(self, force)
		end
	end

	if inst.components.health ~= nil then
		inst.components.health:SetMinHealth(0)
		local maxhp = ROGE_DAYWALKER2_HEALTH
		if RogeGetDay8HealthMult() > 1 then
			maxhp = ROGE_DAYWALKER2_HEALTH_DAY8
		end
		local pct = inst.components.health:GetPercent()
		inst.components.health:SetMaxHealth(maxhp)
		inst.components.health:SetPercent(pct)
		inst.components.health:StopRegen()
	end

	inst.canmultiwield = true
	inst.candoublerummage = true
	inst.canavoidjunk = true

	if inst.SetEquip ~= nil then
		inst:SetEquip("swing", "object", ROGE_DAYWALKER2_EQUIP_USES)
		inst:SetEquip("tackle", "spike", ROGE_DAYWALKER2_EQUIP_USES)
		inst:SetEquip("cannon", "cannon", ROGE_DAYWALKER2_EQUIP_USES)
	end
	RogeDaywalker2MakeEquipmentIndestructible(inst)

	if target ~= nil and target:IsValid() and inst.components.combat ~= nil then
		inst.components.combat:SetTarget(target)
	end
	if inst.SetEngaged ~= nil then
		inst:SetEngaged(true)
	end
end

function RogeSpawnDaywalker2RogePack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	local boss = SpawnPrefab("daywalker2")
	if boss == nil then
		return nil
	end
	boss.Transform:SetPosition(
		x + math.cos(angle) * radius,
		y,
		z + math.sin(angle) * radius
	)
	boss:DoTaskInTime(0, function(e)
		RogeSetupDaywalker2RogeBoss(e, target)
	end)
	return boss
end

local function RogeHookDaywalkerMinotaurChest(inst)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid()
		or inst._roge_minotaur_chest_loot_hooked then
		return
	end
	inst._roge_minotaur_chest_loot_hooked = true
	local lootdropper = inst.components.lootdropper
	if lootdropper == nil then
		return
	end
	local old_droploot = lootdropper.DropLoot
	lootdropper.DropLoot = function(self, pt, ...)
		local results = old_droploot(self, pt, ...)
		if not self.inst._roge_minotaur_chest_spawned and SpawnMinotaurStyleChest ~= nil then
			self.inst._roge_minotaur_chest_spawned = true
			SpawnMinotaurStyleChest(self.inst)
		end
		return results
	end
end

AddPrefabPostInit("daywalker", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, RogeHookDaywalkerMinotaurChest)
end)
