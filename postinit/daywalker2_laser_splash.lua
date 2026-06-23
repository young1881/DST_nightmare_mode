-- daywalker2 / spider_robot：恢复原版溅射型 alterguardian_laser Trigger 与伤害
-- 不修改 alterguardian.lua / jiaqiang.lua；jiaqiang 会把激光基数改为 450，导致近距 900 伤

local SPLASH_LASER_CASTERS = {
	daywalker2 = true,
	spider_robot = true,
}

-- 原版 ALTERGUARDIAN_PHASE3_LASERDAMAGE（jiaqiang 覆盖前）
local VANILLA_CANNON_LASER_BASE = 120

local VANILLA_ALTERGUARDIAN_LASER_TRIGGER = nil

function GLOBAL.RogeCalcCannonLaserDamage(dist)
	local min = VANILLA_CANNON_LASER_BASE * TUNING.DAYWALKER2_CANNON_FAR_DAMAGE_MULT
	local max = VANILLA_CANNON_LASER_BASE * TUNING.DAYWALKER2_CANNON_NEAR_DAMAGE_MULT
	return math.clamp(Remap(dist, 5.4, 10, max, min), min, max), TUNING.ALTERGUARDIAN_PLAYERDAMAGEPERCENT
end

local function SplashLaserOverrideDamage(laser_inst, damage, playerdamagepercent, prefab_override)
	local caster = laser_inst.caster
	if caster ~= nil and caster:IsValid() and SPLASH_LASER_CASTERS[caster.prefab] then
		local lx, ly, lz = laser_inst.Transform:GetWorldPosition()
		damage, playerdamagepercent = GLOBAL.RogeCalcCannonLaserDamage(math.sqrt(caster:GetDistanceSqToPoint(lx, ly, lz)))
	end
	return prefab_override(laser_inst, damage, playerdamagepercent)
end

local function ApplySplashLaserRestore(inst)
	if not TheWorld.ismastersim then
		return
	end

	local eraser_trigger = inst.Trigger
	local prefab_override_damage = inst.OverrideDamage

	inst.OverrideDamage = function(laser_inst, damage, playerdamagepercent)
		return SplashLaserOverrideDamage(laser_inst, damage, playerdamagepercent, prefab_override_damage)
	end

	inst.Trigger = function(laser, delay, targets, skiptoss, skipscorch, scale, scorchscale, hitscale, heavymult, mult, forcelanded)
		if laser.type == "eraser" then
			return eraser_trigger(laser, delay, targets, skiptoss, skipscorch)
		end
		local caster = laser.caster
		if caster ~= nil and caster:IsValid() and SPLASH_LASER_CASTERS[caster.prefab]
			and VANILLA_ALTERGUARDIAN_LASER_TRIGGER ~= nil
		then
			return VANILLA_ALTERGUARDIAN_LASER_TRIGGER(
				laser, delay, targets, skiptoss, skipscorch,
				scale, scorchscale, hitscale, heavymult, mult, forcelanded
			)
		end
		return eraser_trigger(laser, delay, targets, skiptoss, skipscorch)
	end
end

function RogeDaywalker2LaserSplashCapture()
	AddPrefabPostInit("alterguardian_laser", function(inst)
		if not TheWorld.ismastersim then
			return
		end
		if VANILLA_ALTERGUARDIAN_LASER_TRIGGER == nil and inst.OverrideDamage ~= nil then
			VANILLA_ALTERGUARDIAN_LASER_TRIGGER = inst.Trigger
		end
	end)
end

function RogeDaywalker2LaserSplashRestore()
	AddPrefabPostInit("alterguardian_laser", ApplySplashLaserRestore)
	AddPrefabPostInit("alterguardian_laserempty", ApplySplashLaserRestore)
end
