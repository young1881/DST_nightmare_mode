local assets = {
	Asset("ANIM", "anim/pocketwatch_dreadstone.zip"),

	Asset("ATLAS", "images/inventoryimages/pocketwatch_injure.xml"),
	Asset("IMAGE", "images/inventoryimages/pocketwatch_injure.tex"),
}

STRINGS.NAMES.POCKETWATCH_INJURE = "岁月表"
STRINGS.RECIPE_DESC.POCKETWATCH_INJURE = "人生越老，岁月越短。"
STRINGS.CHARACTERS.GENERIC.POCKETWATCH_INJURE_FAIL = "仅旺达可用"
STRINGS.CHARACTERS.WANDA.POCKETWATCH_INJURE_FAIL = "也许表的结构出现了问题？"
STRINGS.SCRAPBOOK.SPECIALINFO.POCKETWATCH_INJURE = "岁月催人老，及时行乐"

local prefabs =
{
	"pocketwatch_cast_fx",
	"pocketwatch_cast_fx_mount",
}

local PocketWatchCommon = require("prefabs/pocketwatch_common")

local function CalcOldAgerHealDuration(heal_amount)
	local S = TUNING.OLDAGE_HEALTH_SCALE
	local damage_remaining = heal_amount * S
	local dps = math.min(math.ceil(math.sqrt(math.abs(damage_remaining)) * 1.5), 30)
	return math.abs(damage_remaining) / math.abs(dps)
end

local function Heal_DoCastSpell(inst, doer)
	if doer == nil or not doer:IsValid() then
		return
	end
	local health = doer.components.health
	if health == nil or health:IsDead() then
		return
	end
	if doer.components.oldager ~= nil then
		doer.components.oldager:StopDamageOverTime()
	end
	-- local old_DoDelta = health.DoDelta
	-- health.DoDelta = function(self, amount, overtime, cause, ...)
	-- 	if amWount < 0 and cause ~= "oldager" and cause ~= inst.prefab then
	-- 		return
	-- 	end
	-- 	return old_DoDelta(self, amount, overtime, cause, ...)
	-- end
	health:DoDelta(TUNING.POCKETWATCH_HEAL_HEALING, true, inst.prefab)
	-- local duration = CalcOldAgerHealDuration(TUNING.POCKETWATCH_HEAL_HEALING)
	-- doer:DoTaskInTime(duration, function()
	-- 	if doer ~= nil and doer:IsValid() and doer.components.health ~= nil then
	-- 		doer.components.health.DoDelta = old_DoDelta
	-- 	end
	-- end)
	if doer.components.debuffable ~= nil then
		doer.components.debuffable:AddDebuff("buff_moistureimmunity", "buff_moistureimmunity")
	end
	if doer.components.temperature ~= nil then
		doer.components.temperature:SetTemperature(TUNING.BOOK_TEMPERATURE_AMOUNT)
	end
	local fx = SpawnPrefab((doer.components.rider ~= nil and doer.components.rider:IsRiding())
		and "pocketwatch_heal_fx_mount" or "pocketwatch_heal_fx")
	if fx ~= nil then
		fx.entity:SetParent(doer.entity)
	end
	if inst.components.rechargeable ~= nil then
		inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_HEAL_COOLDOWN / 2)
	end
end


local MOUNTED_CAST_TAGS = { "pocketwatch_mountedcast" }

local function injurefn()
	local inst = PocketWatchCommon.common_fn("pocketwatch", "pocketwatch_dreadstone", Heal_DoCastSpell, true,
		MOUNTED_CAST_TAGS)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.castfxcolour = { 241 / 255, 147 / 255, 156 / 255 }

	inst.components.inventoryitem.imagename = "pocketwatch_injure"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_injure.xml"

	return inst
end


return Prefab("pocketwatch_injure", injurefn, assets, prefabs)
