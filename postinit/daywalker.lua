-- 梦魇疯猪 daywalker：固定 30000 血，Hook SetMaxHealth 以盖过其他 mod

NM_DAYWALKER_HEALTH = 30000

local function ApplyDaywalkerHealth(inst, preserve_percent)
	if inst == nil or not inst:IsValid() or inst.components.health == nil then
		return
	end
	local pct = preserve_percent and inst.components.health:GetPercent() or 1
	inst.components.health:SetMaxHealth(NM_DAYWALKER_HEALTH)
	inst.components.health:SetPercent(pct)
end

local function HookDaywalkerHealth(inst)
	if inst == nil or not inst:IsValid() or inst._nm_daywalker_health_hooked then
		return
	end
	inst._nm_daywalker_health_hooked = true

	local health = inst.components.health
	if health == nil then
		return
	end

	if health._nm_daywalker_setmax_hooked == nil then
		health._nm_daywalker_setmax_hooked = true
		local old_setmax = health.SetMaxHealth
		health.SetMaxHealth = function(self, amount, ...)
			if amount ~= NM_DAYWALKER_HEALTH then
				amount = NM_DAYWALKER_HEALTH
			end
			return old_setmax(self, amount, ...)
		end
	end

	ApplyDaywalkerHealth(inst, true)
end

local function OnDaywalkerPostInit(inst)
	if not TheWorld.ismastersim then
		return
	end
	HookDaywalkerHealth(inst)
	inst:DoTaskInTime(0, HookDaywalkerHealth)

	if inst.MakeChained ~= nil then
		local old_make_chained = inst.MakeChained
		inst.MakeChained = function(...)
			old_make_chained(...)
			HookDaywalkerHealth(inst)
		end
	end
	if inst.MakeUnchained ~= nil then
		local old_make_unchained = inst.MakeUnchained
		inst.MakeUnchained = function(...)
			old_make_unchained(...)
			HookDaywalkerHealth(inst)
		end
	end
end

AddPrefabPostInit("daywalker", OnDaywalkerPostInit)
