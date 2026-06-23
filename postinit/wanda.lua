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

-- TUNING.POCKETWATCH_HEAL_COOLDOWN = 60    --不老表CD减半
TUNING.POCKETWATCH_RECALL_COOLDOWN = 240 -- 溯源表 CD：4 分钟（半游戏日）

-- 开局送 5 个时间碎片
for _ = 1, 5 do
	table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WANDA, "pocketwatch_parts")
end

-- 旺达自带三本科技
AddPrefabPostInit("wanda", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddTag("darkmagic")
	-- inst.components.builder.magic_bonus = 2
	inst.components.builder:GiveTempTechBonus({ MAGIC = 2 })

	inst.components.oldager:AddValidHealingCause("pocketwatch_injure")
end)

AddRecipe2(
	"pocketwatch_injure",
	{ Ingredient("pocketwatch_heal", 1), Ingredient("horrorfuel", 10), Ingredient("redgem", 1) },
	TECH.NONE,
	{
		builder_tag = "clockmaker",
		no_deconstruction = pocketwatch_nodecon,
		atlas =
		"images/inventoryimages/pocketwatch_injure.xml"
	},
	{ "CHARACTER", "RESTORATION", "MOD" }
)

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
	inst.components.planardamage:SetBaseDamage(35) --位面伤害

	if inst.components.armor == nil then
		inst:AddComponent("armor")
	end
	inst.components.armor:InitIndestructible(0.6) --普通防御

	if inst.components.planardefense == nil then
		inst:AddComponent("planardefense")
	end
	inst.components.planardefense:SetBaseDefense(20) -- 位面防御

	inst.components.equippable.walkspeedmult = 1.25 --移速

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
		animbank       = "ui_chester_upgraded_3x4",
		animbuild      = "ui_chester_upgraded_3x4",
		pos            = Vector3(590, -350, 0),
		side_align_tip = 160,
	},
	type = "watchbox",
	itemtestfn = function(inst, item, slot)
		return item:HasTag("pocketwatch")
	end
}

for y = 2.5, -0.5, -1 do
	for x = 0, 2 do
		table.insert(params.clock_container.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
	end
end

STRINGS.NAMES.CLOCK_CONTAINER = "钟表罐"
STRINGS.RECIPE_DESC.CLOCK_CONTAINER = "保存你所有的表"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CLOCK_CONTAINER = "很能装的存表罐"

-- 具体的配方
AddRecipe2("clock_container",
	{
		Ingredient("pocketwatch_parts", 1),
		Ingredient("thulecite_pieces", 2),
		Ingredient("silk", 4),
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


local function pocketwatch_nodecon(inst) return not inst:HasTag("pocketwatch_inactive") end
AddRecipe2("pocketwatch_cherrift",
	{
		Ingredient("pocketwatch_parts", 3),
		Ingredient("coin_1", 1),
		Ingredient("dreadstone", 1),
		Ingredient("purebrilliance", 1),
	},
	TECH.NONE,
	{
		builder_tag = "clockmaker",
		atlas = "images/inventoryimages/pocketwatch_cherrift.xml",
		no_deconstruction = pocketwatch_nodecon,
	},
	{ "CHARACTER" }
)


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

--二次表作祟后不损坏
AddPrefabPostInit("pocketwatch_revive", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst._break = false
	local function Revive_OnHaunt(inst, haunter)
		inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
		if haunter:HasTag("pocketwatchcaster") and inst.components.pocketwatch:CastSpell(haunter, haunter) and inst._break then
			inst.components.lootdropper:DropLoot()
			SpawnPrefab("brokentool").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst:Remove() -- cannot withstand the paradox of being haunted by Wanda�s timeline
		else
			inst._break = true
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

----------  裂缝表：脚下开启更大的时间裂隙，范围内的玩家会被吸入传送到标记点  ----------

AddPrefabPostInit("pocketwatch_portal", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst._roge_vanilla_portal_cast = inst.components.pocketwatch.DoCastSpell
	inst.components.pocketwatch.DoCastSpell = function(watch, doer, target, pos)
		local recallmark = watch.components.recallmark
		if recallmark == nil or not recallmark:IsMarked() then
			return watch._roge_vanilla_portal_cast(watch, doer, target, pos)
		end

		if not Shard_IsWorldAvailable(recallmark.recall_worldid) then
			return false, "SHARD_UNAVAILABLE"
		end

		local x, y, z = doer.Transform:GetWorldPosition()
		local rift = SpawnPrefab("roge_portal_rift")
		rift.Transform:SetPosition(x, y, z)
		if rift.SetRiftCaster ~= nil then
			rift:SetRiftCaster(doer)
		else
			rift._roge_caster = doer
			rift._roge_caster_userid = doer.userid
		end

		if recallmark.recall_worldid ~= nil and recallmark.recall_worldid ~= TheShard:GetShardId() then
			rift:SetupMigrationDestination(recallmark.recall_worldid, recallmark.recall_x, recallmark.recall_y, recallmark.recall_z)
		else
			rift:SetupExitDestination(recallmark.recall_x, recallmark.recall_y, recallmark.recall_z)
		end
		rift:StartPullingPlayers()

		watch.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")

		local new_watch = SpawnPrefab("pocketwatch_recall")
		new_watch.components.recallmark:Copy(watch)
		local wx, wy, wz = watch.Transform:GetWorldPosition()
		new_watch.Transform:SetPosition(wx, wy, wz)
		new_watch.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN)

		local owner = watch.components.inventoryitem ~= nil and watch.components.inventoryitem.owner or nil
		local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
		if holder ~= nil then
			local slot = holder:GetItemSlot(watch)
			watch:Remove()
			holder:GiveItem(new_watch, slot, Vector3(wx, wy, wz))
		else
			watch:Remove()
		end

		return true
	end
end)

AddPrefabPostInit("pocketwatch_portal", function(inst)
	inst.cast_scope = 5
end)

AddPrefabPostInit("shadowthrall_mouth", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:AddTag("ai_stopped")
end)

----------  倒走表：投入 1 时间碎片升级为充能倒走表，随机传送消耗 20 岁，使用后分解  ----------

local ROGE_BACKTREK_RANDOM_AGE_COST = 12
local ROGE_BACKTREK_RANDOM_FUEL = "pocketwatch_parts"
local ROGE_BACKTREK_RANDOM_TELEPORT_ATTEMPTS = 80
local ROGE_WARP_CHARGED_NAME = "roge_pocketwatch_warp_charged"

STRINGS.NAMES.ROGE_POCKETWATCH_WARP_CHARGED = "充能倒走表"
STRINGS.RECIPE_DESC.ROGE_POCKETWATCH_WARP_CHARGED = "时间碎片已充能，下一次使用将随机传送并耗尽自身。"
STRINGS.CHARACTERS.WANDA.ANNOUNCE_BACKTREK_RANDOM_READY = "时间已扭曲，下一次倒走将坠入未知之地。"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_BACKTREK_RANDOM_READY = "时间碎片已嵌进表里了。"
STRINGS.CHARACTERS.WANDA.ANNOUNCE_BACKTREK_RANDOM_USED = "岁月……被扯向虚空！"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_BACKTREK_RANDOM_USED = "时间猛地把我拽走了。"
STRINGS.CHARACTERS.WANDA.DESCRIBE.POCKETWATCH_WARP = STRINGS.CHARACTERS.WANDA.DESCRIBE.POCKETWATCH_WARP or {}
STRINGS.CHARACTERS.WANDA.DESCRIBE.POCKETWATCH_WARP.ROGE_RANDOM_WARP_ARMED =
	"充能倒走表嗡嗡作响，下一次使用会把我甩到完全陌生的地方。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCH_WARP = STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCH_WARP or {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCH_WARP.ROGE_RANDOM_WARP_ARMED =
	"充能倒走表，下一次使用会随机传送。"
STRINGS.CHARACTERS.WANDA.DESCRIBE.ROGE_POCKETWATCH_WARP_CHARGED =
	"充能倒走表嗡嗡作响，下一次使用会把我甩到完全陌生的地方。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ROGE_POCKETWATCH_WARP_CHARGED =
	"充能倒走表，下一次使用会随机传送。"

local function RogeWandaApplyAgeCost(doer, years)
	if doer == nil or not doer:IsValid() then
		return
	end
	-- 本 mod 年龄条 60 血 = 60 岁，1 血 = 1 岁；勿乘 OLDAGE_HEALTH_SCALE（否则 20 岁只会扣 8 血）
	if doer.components.oldager ~= nil then
		doer.components.oldager:StopDamageOverTime()
	end
	if doer.components.health ~= nil and not doer.components.health:IsDead() then
		doer.components.health:DoDelta(-years, false, "oldager_component")
	end
end

local function RogeIsValidRandomTeleportPoint(map, x, z)
	if not map:IsPassableAtPoint(x, 0, z, false) then
		return false
	end
	if not map:IsVisualGroundAtPoint(x, 0, z) or map:IsOceanAtPoint(x, 0, z, false) then
		return false
	end
	if map.IsPointNearHole ~= nil and map:IsPointNearHole(Vector3(x, 0, z)) then
		return false
	end
	return true
end

local function RogeFindRandomMapTeleportPos(doer)
	if TheWorld == nil or not TheWorld.ismastersim or TheWorld.Map == nil then
		return nil
	end
	local map = TheWorld.Map
	local mapw, maph = map:GetSize()
	if mapw == nil or maph == nil or mapw <= 0 or maph <= 0 then
		return nil
	end
	local px, py, pz = doer.Transform:GetWorldPosition()
	for _ = 1, ROGE_BACKTREK_RANDOM_TELEPORT_ATTEMPTS do
		local x = (math.random() - 0.5) * mapw * TILE_SCALE
		local z = (math.random() - 0.5) * maph * TILE_SCALE
		if RogeIsValidRandomTeleportPoint(map, x, z) then
			local offset = FindWalkableOffset(Vector3(x, 0, z), math.random() * TWOPI, 0, 12, false, true, nil, false, true)
			if offset ~= nil then
				x = x + offset.x
				z = z + offset.z
			end
			if RogeIsValidRandomTeleportPoint(map, x, z) then
				local tx, ty = map:GetTileCoordsAtPoint(x, 0, z)
				x, ty, z = map:GetTileCenterPoint(tx, ty)
				if IsTeleportingPermittedFromPointToPoint(px, py, pz, x, ty, z) then
					return x, ty, z
				end
			end
		end
	end
	return nil
end

local function RogeWarpGiveDecomposeLoot(doer)
	if doer == nil or not doer:IsValid() or doer.components.inventory == nil then
		return
	end
	local inv = doer.components.inventory
	local parts = SpawnPrefab("pocketwatch_parts")
	if parts ~= nil then
		inv:GiveItem(parts)
	end
	for _ = 1, 2 do
		local gold = SpawnPrefab("goldnugget")
		if gold ~= nil then
			inv:GiveItem(gold)
		end
	end
end

local function RogeWarpDecomposeAfterUse(watch, doer)
	if watch ~= nil and watch:IsValid() then
		watch:Remove()
	end
	RogeWarpGiveDecomposeLoot(doer)
end

local function RogeWarpSetChargedAppearance(inst, charged)
	if inst == nil or not inst:IsValid() then
		return
	end
	if charged then
		inst:SetPrefabNameOverride(ROGE_WARP_CHARGED_NAME)
	else
		inst:SetPrefabNameOverride(nil)
	end
end

local function RogeWarpRandomCast(inst, doer)
	local tx, ty, tz = RogeFindRandomMapTeleportPos(doer)
	if tx == nil then
		return false
	end
	local px, py, pz = doer.Transform:GetWorldPosition()
	if not IsTeleportingPermittedFromPointToPoint(px, py, pz, tx, ty, tz) then
		return false, "NO_TELEPORT_ZONE"
	end
	inst._roge_random_warp_armed = false
	inst:RemoveTag("roge_backtrek_random_armed")
	inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_WARP_COOLDOWN)
	doer.sg.statemem.warpback = { dest_x = tx, dest_y = ty, dest_z = tz }
	RogeWandaApplyAgeCost(doer, ROGE_BACKTREK_RANDOM_AGE_COST)
	if doer.components.talker ~= nil then
		doer.components.talker:Say(GetString(doer, "ANNOUNCE_BACKTREK_RANDOM_USED"))
	end
	RogeWarpDecomposeAfterUse(inst, doer)
	return true
end

local function RogeWarp_CanAcceptUpgradeFuel(inst, item, giver)
	if item == nil or item.prefab ~= ROGE_BACKTREK_RANDOM_FUEL then
		return false
	end
	if inst._roge_random_warp_armed then
		return false
	end
	if giver == nil or not giver:HasTag("pocketwatchcaster") then
		return false
	end
	if inst.components.rechargeable ~= nil and not inst.components.rechargeable:IsCharged() then
		return false
	end
	return true
end

local function RogeWarp_OnAcceptUpgradeFuel(inst, giver, item)
	inst._roge_random_warp_armed = true
	inst:AddTag("roge_backtrek_random_armed")
	RogeWarpSetChargedAppearance(inst, true)
	if giver ~= nil and giver:IsValid() and giver.components.talker ~= nil then
		giver.components.talker:Say(GetString(giver, "ANNOUNCE_BACKTREK_RANDOM_READY"))
	end
end

local function RogeWarp_GetStatus(inst, viewer)
	if inst._roge_random_warp_armed and viewer ~= nil and viewer:HasTag("pocketwatchcaster") then
		return "ROGE_RANDOM_WARP_ARMED"
	end
	return (inst.components.rechargeable ~= nil and not inst.components.rechargeable:IsCharged()) and "RECHARGING"
		or nil
end

local function RogeWarp_AppendSave(inst, data)
	if inst._roge_random_warp_armed then
		data.roge_random_warp_armed = true
	end
end

local function RogeWarp_AppendLoad(inst, data)
	if data ~= nil and data.roge_random_warp_armed then
		inst._roge_random_warp_armed = true
		inst:AddTag("roge_backtrek_random_armed")
		RogeWarpSetChargedAppearance(inst, true)
	end
end

-- 时间碎片对倒走表：背包内右键给予（与宝石镶嵌溯源表同理，需要 USEITEM + tradable）
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if right or inst.prefab ~= ROGE_BACKTREK_RANDOM_FUEL or target == nil or target.prefab ~= "pocketwatch_warp" then
		return
	end
	if not target:HasTag("trader") and not target:HasTag("alltrader") then
		return
	end
	local rider = doer.replica ~= nil and doer.replica.rider or nil
	if rider ~= nil and rider:IsRiding() then
		local inventoryitem = target.replica ~= nil and target.replica.inventoryitem or nil
		if not (inventoryitem ~= nil and inventoryitem:IsGrandOwner(doer)) then
			return
		end
	end
	table.insert(actions, ACTIONS.GIVE)
end)

AddPrefabPostInit("pocketwatch_parts", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.tradable == nil then
		inst:AddComponent("tradable")
	end
end)

AddPrefabPostInit("pocketwatch_warp", function(inst)
	-- 客户端也要有此标签，背包里对表「给予」时间碎片才会出现 GIVE 而不是交换
	inst:AddTag("trader")
	inst:AddTag("alltrader")

	if inst._roge_random_warp_armed or inst:HasTag("roge_backtrek_random_armed") then
		RogeWarpSetChargedAppearance(inst, true)
	end

	if not TheWorld.ismastersim then
		return
	end

	inst._roge_vanilla_warp_cast = inst.components.pocketwatch.DoCastSpell
	inst.components.pocketwatch.DoCastSpell = function(watch, doer, target, pos)
		if watch._roge_random_warp_armed then
			return RogeWarpRandomCast(watch, doer)
		end
		return watch._roge_vanilla_warp_cast(watch, doer, target, pos)
	end

	if inst.components.trader == nil then
		inst:AddComponent("trader")
	end
	inst.components.trader:SetAbleToAcceptTest(RogeWarp_CanAcceptUpgradeFuel)
	inst.components.trader:SetAcceptTest(RogeWarp_CanAcceptUpgradeFuel)
	inst.components.trader:SetOnAccept(RogeWarp_OnAcceptUpgradeFuel)
	inst.components.trader.acceptnontradable = true
	inst.components.trader.deleteitemonaccept = true

	local old_getstatus = inst.components.inspectable ~= nil and inst.components.inspectable.getstatus or nil
	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
	inst.components.inspectable.getstatus = function(watch, viewer)
		local st = RogeWarp_GetStatus(watch, viewer)
		if st ~= nil then
			return st
		end
		return old_getstatus ~= nil and old_getstatus(watch, viewer) or nil
	end

	local old_onsave = inst.OnSave
	inst.OnSave = function(watch, data)
		if old_onsave ~= nil then
			old_onsave(watch, data)
		end
		RogeWarp_AppendSave(watch, data)
	end

	local old_onload = inst.OnLoad
	inst.OnLoad = function(watch, data)
		if old_onload ~= nil then
			old_onload(watch, data)
		end
		RogeWarp_AppendLoad(watch, data)
	end
end)
