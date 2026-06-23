----------------------------------------------------------------------
-- 护士蜘蛛：对友方蜘蛛治疗，单次 +350（不超上限，超上限逻辑已注释）
----------------------------------------------------------------------

TUNING.SPIDER_HEALER_OVERHEAL_AMOUNT = 350

local SPIDER_HEAL_TARGET_TAGS = { "spider", "spiderwhisperer", "spiderqueen" }
local SPIDER_HEAL_IGNORE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "creaturecorpse" }

local function SpiderHealerSpawnHealFx(target, fx_prefab, scale)
	local x, y, z = target.Transform:GetWorldPosition()
	local fx = SpawnPrefab(fx_prefab)
	if fx == nil then
		return
	end
	fx.Transform:SetNoFaced()
	fx.Transform:SetPosition(x, y, z)
	scale = scale or 1
	fx.Transform:SetScale(scale, scale, scale)
end

local function SpiderHealerFindAllies(healer, radius)
	local x, y, z = healer.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, radius, nil, SPIDER_HEAL_IGNORE_TAGS, SPIDER_HEAL_TARGET_TAGS)
	local allies = {}
	for _, spider in ipairs(ents) do
		if spider:IsValid()
			and spider.components.health ~= nil
			and not spider.components.health:IsDead()
			and not spider:HasTag("playerghost") then
			table.insert(allies, spider)
		end
	end
	return allies
end

--[[ 突破血上限治疗（暂时禁用）
-- SetVal 会把血量限制在 maxhealth 内；治疗超上限时先临时抬高 maxhealth
local function SpiderHealerApplyOverheal(target, amount, cause, afflicter)
	local health = target.components.health
	if health == nil or health:IsDead() or amount == nil or amount <= 0 then
		return
	end

	local base_max = health.maxhealth
	local new_health = health.currenthealth + amount
	local old_percent = health:GetPercent()

	if new_health > base_max then
		health.maxhealth = new_health
	end

	health:SetVal(new_health, cause, afflicter)

	if base_max < new_health then
		health.maxhealth = base_max
		if target.replica ~= nil and target.replica.health ~= nil then
			target.replica.health:SetMax(base_max)
			target.replica.health:SetCurrent(health.currenthealth)
		end
	end

	target:PushEvent("healthdelta", {
		oldpercent = old_percent,
		newpercent = health:GetPercent(),
		overtime = false,
		cause = cause,
		afflicter = afflicter,
		amount = amount,
	})
	if health.ondelta ~= nil then
		health.ondelta(target, old_percent, health:GetPercent(), false, cause, afflicter, amount)
	end
end
--]]

local function SpiderHealerApplyHeal(target, amount, cause, afflicter)
	local health = target.components.health
	if health == nil or health:IsDead() or amount == nil or amount <= 0 then
		return
	end
	health:DoDelta(amount, false, cause, nil, afflicter)
end

local function SpiderHealerShouldSkipTarget(healer, spider)
	local target = healer.components.combat ~= nil and healer.components.combat.target or nil
	local leader = healer.components.follower ~= nil and healer.components.follower:GetLeader() or nil

	local targetting_us = target ~= nil
		and (target == healer
			or (leader ~= nil
				and (target == leader
					or (leader.components.leader ~= nil and leader.components.leader:IsFollower(target)))))

	local targetted_by_us = healer.components.combat ~= nil
		and healer.components.combat.target == spider
	if not targetted_by_us and leader ~= nil and leader.components.combat ~= nil then
		targetted_by_us = leader.components.combat:TargetIs(spider)
			or (leader.components.leader ~= nil and leader.components.leader:IsTargetedByFollowers(spider))
	end

	return targetting_us or targetted_by_us
end

local function SpiderHealerDoHeal(healer)
	local scale = 1.35
	if healer.SoundEmitter ~= nil then
		local path = healer.SoundPath ~= nil and healer:SoundPath("heal_fartcloud")
			or "webber1/creatures/spider_cannonfodder/heal_fartcloud"
		healer.SoundEmitter:PlaySound(path)
	end
	SpiderHealerSpawnHealFx(healer, "spider_heal_ground_fx", scale)
	SpiderHealerSpawnHealFx(healer, "spider_heal_fx", scale)

	local radius = TUNING.SPIDER_HEALING_RADIUS or 8
	local heal_amount = TUNING.SPIDER_HEALER_OVERHEAL_AMOUNT or 350
	local cause = healer.prefab or "spider_healer"

	for _, spider in ipairs(SpiderHealerFindAllies(healer, radius)) do
		if not SpiderHealerShouldSkipTarget(healer, spider) then
			SpiderHealerApplyHeal(spider, heal_amount, cause, healer)
			SpiderHealerSpawnHealFx(spider, "spider_heal_target_fx")
		end
	end

	healer.healtime = GetTime()
end

local function SpiderHealerBindDoHeal(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.DoHeal = SpiderHealerDoHeal
end

AddPrefabPostInit("spider_healer", SpiderHealerBindDoHeal)

-- 确保 SG 治疗帧调用的是覆盖后的 DoHeal（部分加载顺序下 PostInit 可能偏晚）
AddStategraphPostInit("spider", function(sg)
	local heal = sg.states.heal
	if heal == nil or heal.timeline == nil then
		return
	end
	for _, te in ipairs(heal.timeline) do
		if te.time == 30 * FRAMES and te.fn ~= nil then
			local old_fn = te.fn
			te.fn = function(inst)
				if inst.prefab == "spider_healer" then
					SpiderHealerDoHeal(inst)
				else
					old_fn(inst)
				end
			end
			break
		end
	end
end)
