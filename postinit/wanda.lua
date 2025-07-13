local STRINGS = GLOBAL.STRINGS
local UPGRADETYPES = GLOBAL.UPGRADETYPES
local GetString = GLOBAL.GetString

-- 定义旺达的年龄上下界
TUNING.WANDA_MIN_YEARS_OLD = 20
TUNING.WANDA_MAX_YEARS_OLD = 80

-- 这里旺达的年龄血条，必须严格等于上面的上界 - 下界
TUNING.WANDA_OLDAGER = 60
-- 这个是年龄和血量的转换，也就是说 60 血量等于 150 血量
TUNING.OLDAGE_HEALTH_SCALE = 60 / 150

-- 老年界限，这里的意思是旺达血条总共 60 血量， 剩 1/3 （即20血量，即60岁）的时候老年
TUNING.WANDA_AGE_THRESHOLD_OLD = 1 / 3
-- 中年界限，这里的意思是旺达血条总共 60 血量， 剩 2/3 （即40血量，即40岁）的时候中年
TUNING.WANDA_AGE_THRESHOLD_YOUNG = 2 / 3
TUNING.WANDA_READING_SANITY_MULT = 3
TUNING.WANDA_READ_PENALTY = 5

TUNING.POCKETWATCH_HEAL_COOLDOWN = 60    --不老表CD减半
TUNING.POCKETWATCH_RECALL_COOLDOWN = 240 --半天

-- 开局多送1个时间碎片
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WANDA, "pocketwatch_parts")

-- 旺达自带三本科技
AddPrefabPostInit("wanda", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddTag("darkmagic")
	-- inst.components.builder.magic_bonus = 2
	inst.components.builder:GiveTempTechBonus({ MAGIC = 2 })
end)


UPGRADETYPES.POCKETWATCH_WEAPON = "pocketwatch_weapon"

--TUNING.POCKETWATCH_WEAPON_HORROR_PLANAR_DAMAGE = 15

STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HORRORCLOCK = "我认为这个恐惧表已经完全超越了警告表了"
STRINGS.CHARACTERS.WANDA.ANNOUNCE_HORRORCLOCK = "一些事情已经无法回头了"
STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_HORRORCLOCK = "这个武器已经不再听从我的使唤了"
STRINGS.CHARACTERS.WICKERBOTTOM.ANNOUNCE_HORRORCLOCK = "我的老天，肮脏的暗影魔法污染了这个武器"

STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HORRORCLOCK_FUEL = "它渴望别的东西"
STRINGS.CHARACTERS.WANDA.ANNOUNCE_HORRORCLOCK_FUEL = "给它这样的低级燃料是一种不敬"

local Fueled = require("components/fueled")

local OldTakeFuelItem = Fueled.TakeFuelItem
function Fueled:TakeFuelItem(item, ...)
	if self.inst.MakeHorrorClock and not self.inst:HasTag("horrorclock") and item.prefab == "horrorfuel" then
		local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()

		self.inst:MakeHorrorClock()
		if owner and owner.components.talker then
			owner.components.talker:Say(GetString(owner, "ANNOUNCE_HORRORCLOCK"))
		end
	end

	return OldTakeFuelItem(self, item, ...)
end

local OldCanAcceptFuelItem = Fueled.CanAcceptFuelItem
function Fueled:CanAcceptFuelItem(item, ...)
	if self.inst:HasTag("horrorclock") and item.prefab ~= "horrorfuel" then
		local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()

		if owner and owner.components.talker then
			owner:DoTaskInTime(0,
				function() owner.components.talker:Say(GetString(owner, "ANNOUNCE_HORRORCLOCK_FUEL")) end)
		end

		return false
	end

	return OldCanAcceptFuelItem(self, item, ...)
end

local function MakeHorrorClock(inst)
	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
	end
	inst.components.planardamage:SetBaseDamage(30) --位面伤害

	if inst.components.armor == nil then
		inst:AddComponent("armor")
	end
	inst.components.armor:InitIndestructible(0.6) --普通防御

	if inst.components.planardefense == nil then
		inst:AddComponent("planardefense")
	end
	inst.components.planardefense:SetBaseDefense(20) -- 位面防御

	inst.components.equippable.walkspeedmult = 1.20 --移速

	local damagetypebonus = inst:AddComponent("damagetypebonus")
	damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)

	inst.components.equippable.restrictedtag = "pocketwatchcaster"
	inst:AddTag("horrorclock")
	inst:AddTag("magiciantool")
end

local OldOnSave
local function OnSave(inst, data, ...)
	if OldOnSave then
		OldOnSave(inst, data, ...)
	end
	data.horrorclock = inst:HasTag("horrorclock")
end

local OldOnLoad
local function OnLoad(inst, data, ...)
	if OldOnLoad then
		OldOnLoad(inst, data, ...)
	end
	if data and data.horrorclock then
		inst:MakeHorrorClock()
	end
end

AddPrefabPostInit("pocketwatch_weapon", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	inst.components.equippable.restrictedtag = "darkmagic"

	inst.MakeHorrorClock = MakeHorrorClock

	-- inst.components.weapon:SetOnAttack(onattack)

	if not OldOnSave then
		OldOnSave = inst.OnSave
	end
	inst.OnSave = OnSave

	if not OldOnLoad then
		OldOnLoad = inst.OnLoad
	end
	inst.OnLoad = OnLoad
end)

local function ShadowWeaponFx(inst, target, damage, stimuli, weapon, damageresolved)
	if weapon ~= nil and target ~= nil and target:IsValid() and weapon:IsValid() and weapon:HasTag("pocketwatch") then
		local fx_prefab = weapon:HasTag("pocketwatch") and "wanda_attack_pocketwatch_old_fx"
		if fx_prefab ~= nil then
			local fx = SpawnPrefab(fx_prefab)

			local x, y, z = target.Transform:GetWorldPosition()
			local radius = target:GetPhysicsRadius(.5)
			local angle = (inst.Transform:GetRotation() - 90) * DEGREES
			fx.Transform:SetPosition(x + math.sin(angle) * radius, 0, z + math.cos(angle) * radius)
		end
	end
end

AddPrefabPostInit("waxwell", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	inst.components.combat.onhitotherfn = ShadowWeaponFx
end)

AddPrefabPostInit("wickerbottom", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	inst.components.combat.onhitotherfn = ShadowWeaponFx
end)



------------- 第二次机会表给无敌效果 -----------

local function ActivateForceField(target)
	if target and target:IsValid() then
		local fx = SpawnPrefab("forcefieldfx")
		if fx then
			-- 设置无敌效果在一段时间后消失(注意时间是从被拉的时候算的，所以有动画的一段时间)
			local invincible_time = 12
			fx.entity:SetParent(target.entity)
			fx.Transform:SetPosition(0, 0.2, 0)

			target.components.health.externalabsorbmodifiers:SetModifier(fx, TUNING.FULL_ABSORPTION)
			target:AddTag("invincible")
			target:DoTaskInTime(invincible_time, function()
				if fx:IsValid() then
					fx:Remove()
				end
				target.components.health.externalabsorbmodifiers:RemoveModifier(fx)
				target:RemoveTag("invincible")
			end)
		end
	end
end

local function OnReviveWithPocketWatch(inst, data)
	if data and data.source and data.source.prefab == "pocketwatch_revive" then
		local target = data.target or inst
		ActivateForceField(target)
	end
end

AddPlayerPostInit(function(player)
	if not TheWorld.ismastersim then return end
	player:ListenForEvent("respawnfromghost", function(inst, data)
		OnReviveWithPocketWatch(inst, data)
	end)
end)

---- 钟表盒 ----

local containers = require("containers")
local params = containers.params

params.clock_container = {
	widget =
	{
		slotpos        = {},
		slotbg         = {},
		animbank       = "ui_krampusbag_2x8",
		animbuild      = "ui_krampusbag_2x8",
		pos            = Vector3(75, 195, 0),
		side_align_tip = 160,
	},
	type = "chest",
	itemtestfn = function(inst, item, slot)
		return item:HasTag("pocketwatch")
	end
}

local clock_container_bg = { image = "battlesong_slot.tex", atlas = "images/hud2.xml" }

for y = -2, 4 do
	table.insert(params.clock_container.widget.slotpos, Vector3(-162, -75 * y + 90, 0))
	table.insert(params.clock_container.widget.slotpos, Vector3(-162 + 75, -75 * y + 90, 0))

	table.insert(params.clock_container.widget.slotbg, clock_container_bg)
	table.insert(params.clock_container.widget.slotbg, clock_container_bg)
end

STRINGS.NAMES.CLOCK_CONTAINER = "钟表罐"
STRINGS.RECIPE_DESC.CLOCK_CONTAINER = "保存你所有的表"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CLOCK_CONTAINER = "很能装的存表罐"

-- 具体的配方
AddRecipe2("clock_container",
	{
		Ingredient("pocketwatch_parts", 1),
		Ingredient("thulecite_pieces", 2),
		Ingredient("silk", 8),
	},
	TECH.NONE,
	{
		atlas = "images/inventoryimages/clock_container.xml",
		builder_tag = "clockmaker",
	},
	{ "CHARACTER" }
)

-- 不可燃
AddPrefabPostInit("clock_container", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:RemoveComponent("burnable")
end)

-- --警告表
-- AddRecipe2("pocketwatch_weapon",
--     { Ingredient("nightsword", 1), Ingredient("waxwelljournal", 1),Ingredient("livinglog", 5),Ingredient("nightmarefuel", 20) }, TECH.NONE_TWO,
--     { builder_tag = "reader" }, { "CHARACTER" })
-- STRINGS.RECIPE_DESC.SPEAR_WATHGRITHR_LIGHTNING_CHARGED = "暗影大法师的得意复制品——通过暗影魔典的力量使用基础材料来将武器附魔重铸"


local function pocketwatch_nodecon(inst) return not inst:HasTag("pocketwatch_inactive") end
AddRecipe2("pocketwatch_cherrift",
	{
		Ingredient("pocketwatch_parts", 1),
		Ingredient("dreadstone", 1),
		Ingredient("purebrilliance", 1)
	},
	TECH.NONE,
	{
		builder_tag = "clockmaker",
		atlas = "images/inventoryimages/pocketwatch_cherrift.xml",
		no_deconstruction = pocketwatch_nodecon,
	},
	{ "CHARACTER" }
)
STRINGS.NAMES.POCKETWATCH_CHERRIFT = "时停表"
STRINGS.RECIPE_DESC.POCKETWATCH_CHERRIFT = "将其他生物的时间转移到自己的年龄上"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCH_CHERRIFT = "一个能够暂停时间的强大魔法，但是也会给施术者很大副作用"
STRINGS.CHARACTERS.WANDA.DESCRIBE.POCKETWATCH_CHERRIFT = "本该由其他生物流逝的时间可能会由我来承担"

--显示范围圈
local function showRange(oldtarget, newtarget)
	if oldtarget and oldtarget.range_widget then
		oldtarget.range_widget:Remove()
		oldtarget.range_widget = nil
	end
	if not newtarget then
		return
	end
	if newtarget.cast_scope then
		newtarget.range_widget = SpawnPrefab("range_widget")
		if newtarget:HasTag("INLIMBO") and ThePlayer then
			newtarget.range_widget:Attach(ThePlayer)
		else
			newtarget.range_widget:Attach(newtarget)
		end
		local radius = newtarget.cast_scope
		if ThePlayer then
			--防止玩家的缩放影响范围圈
			local scalex, scaley, scalez = ThePlayer.Transform:GetScale()
			if scalex and scalex > 0 then
				radius = radius / (scalex * scalex)
			end
		end
		newtarget.range_widget:SetRadius(radius)
	end
end

local last_rangetarget --暂存范围显示目标
--hook玩家鼠标停留函数
AddClassPostConstruct("widgets/hoverer", function(hoverer)
	local oldHide = hoverer.text.Hide
	local oldSetString = hoverer.text.SetString
	hoverer.text.SetString = function(text, str)
		--获取目标
		local target = TheInput:GetHUDEntityUnderMouse()
		target = (target and target.widget and target.widget.parent ~= nil and target.widget.parent.item) or
			TheInput:GetWorldEntityUnderMouse() or nil
		--显示范围圈
		if target and target.GUID then
			if last_rangetarget ~= target then
				showRange(last_rangetarget, target)
				last_rangetarget = target
			end
		elseif last_rangetarget then
			showRange(last_rangetarget, nil)
			last_rangetarget = nil
		end

		return oldSetString(text, str)
	end

	hoverer.text.Hide = function(text)
		if text.shown then
			if last_rangetarget then
				showRange(last_rangetarget, nil)
				last_rangetarget = nil
			end
			oldHide(text)
		end
	end
end)
AddPrefabPostInit("pocketwatch_cherrift", function(inst)
	inst.cast_scope = 11
end)

local function Heal_DoCastSpell(inst, doer)
	local health = doer.components.health
	if health ~= nil and not health:IsDead() then
		doer.components.oldager:StopDamageOverTime()
		health:DoDelta(TUNING.POCKETWATCH_HEAL_HEALING, true, inst.prefab)
		doer.components.temperature:SetTemperature(TUNING.BOOK_TEMPERATURE_AMOUNT)
		doer.components.moisture:SetMoistureLevel(0)

		local fx = SpawnPrefab((doer.components.rider ~= nil and doer.components.rider:IsRiding()) and
			"pocketwatch_heal_fx_mount" or "pocketwatch_heal_fx")
		fx.entity:SetParent(doer.entity)

		inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_HEAL_COOLDOWN)
		if doer._acidrain_immunity_task ~= nil then
			doer._acidrain_immunity_task:Cancel()
		end
		doer.components.acidlevel:SetIgnoreAcidRainTicks(true)
		doer._acidrain_immunity_task = doer:DoTaskInTime(10, function()
			if doer.components.acidlevel then
				doer.components.acidlevel:SetIgnoreAcidRainTicks(false)
			end
			doer._acidrain_immunity_task = nil
		end)

		return true
	end
end


AddPrefabPostInit("pocketwatch_heal", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.components.pocketwatch.DoCastSpell = Heal_DoCastSpell
end)



--二次表作祟后不损坏
AddPrefabPostInit("pocketwatch_revive", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local function Revive_OnHaunt(inst, haunter)
		inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
		if haunter:HasTag("pocketwatchcaster") and inst.components.pocketwatch:CastSpell(haunter, haunter) then

		else
			Launch(inst, haunter, TUNING.LAUNCH_SPEED_SMALL)
		end
	end
	if inst.components.hauntable ~= nil then
		inst.components.hauntable:SetOnHauntFn(Revive_OnHaunt)
	end
end)

--旺达溯源表
AddRecipePostInit("pocketwatch_recall", function(recipe)
	recipe.ingredients = {
		Ingredient("pocketwatch_parts", 1),
		Ingredient("goldnugget", 2)
	}
	recipe.level = TECH.SCIENCE_TWO -- 修改为二本
	recipe.builder_tag = "clockmaker"
	recipe.no_deconstruction = pocketwatch_nodecon
end)
AddRecipePostInit("pocketwatch_portal", function(recipe)
	recipe.level = TECH.SCIENCE_TWO
end)
