local lunarTouchDamage = 5               -- 近战基础物理伤害 (注意：近战触发AOE时主目标会受到 1.5倍 伤害，即 17 + 8.5 = 25.5)
local lunarTouchAttackRange = 1.0         -- 近战攻击距离 (标准近战武器范围)
local lunarTorchThrowDamage_Physical = 35 -- 投掷物理伤害
local lunarTorchThrowDamage_Planar = 15   -- 投掷位面伤害
local lunarTorchThrowFreezeColdness = 100 -- 投掷落地冰冻层数
local lunarTorchThrowBonus = 0.1          -- 无限火把形态的伤害加成系数 (每点一级威尔逊火把技能增加 10% 基础伤害)
local lunarTouchFanRadius = 1.66          -- 近战攻击时的扇形溅射(AOE)半径 (在攻击前方扇形区域内的敌人都会受伤)

local assets =
{

	Asset("SOUND", "sound/common.fsb"),
	Asset("ANIM", "anim/lunar_torch.zip"),
	Asset("ANIM", "anim/swap_lunar_torch.zip"), --文件夹名字没有swap
}

local assets_ping =
{
	Asset("ANIM", "anim/deerclops_mutated_actions.zip"),
	Asset("ANIM", "anim/deerclops_mutated.zip"),
}

local prefabs =
{
	"lunar_torchfire",     -- 添加月亮火把光芒
	"lunar_torch_projectile", ---- 火焰投掷
}

local function DoIgniteSound(inst, owner)
	inst._ignitesoundtask = nil
	local se = (owner ~= nil and owner:IsValid() and owner or inst).SoundEmitter
	if se ~= nil then
		se:PlaySound("dontstarve/wilson/torch_swing")
	end
end

local function DoExtinguishSound(inst, owner)
	inst._extinguishsoundtask = nil
	local se = (owner ~= nil and owner:IsValid() and owner or inst).SoundEmitter
	if se ~= nil then
		se:PlaySound("dontstarve/common/fireOut")
	end
end

local function PlayIgniteSound(inst, owner, instant, force)
	if inst._extinguishsoundtask ~= nil then
		inst._extinguishsoundtask:Cancel()
		inst._extinguishsoundtask = nil
		if not force then
			return
		end
	end
	if instant then
		if inst._ignitesoundtask ~= nil then
			inst._ignitesoundtask:Cancel()
		end
		DoIgniteSound(inst, owner)
	elseif inst._ignitesoundtask == nil then
		inst._ignitesoundtask = inst:DoTaskInTime(0, DoIgniteSound, owner)
	end
end

local function PlayExtinguishSound(inst, owner, instant, force)
	if inst._ignitesoundtask ~= nil then
		inst._ignitesoundtask:Cancel()
		inst._ignitesoundtask = nil
		if not force then
			return
		end
	end
	if instant then
		if inst._extinguishsoundtask ~= nil then
			inst._extinguishsoundtask:Cancel()
		end
		DoExtinguishSound(inst, owner)
	elseif inst._extinguishsoundtask == nil then
		inst._extinguishsoundtask = inst:DoTaskInTime(0, DoExtinguishSound, owner)
	end
end

local function OnRemoveEntity(inst)
	--Due to timing of unequip on removal, we may have passed CancelAllPendingTasks already.
	if inst._ignitesoundtask ~= nil then
		inst._ignitesoundtask:Cancel()
		inst._ignitesoundtask = nil
	end
	if inst._extinguishsoundtask ~= nil then
		inst._extinguishsoundtask:Cancel()
		inst._extinguishsoundtask = nil
	end
end

local function applyskillbrightness(inst, value)
	if inst.fires then
		for i, fx in ipairs(inst.fires) do
			value = value + 4 -- 更明亮的月亮火把
			fx:SetLightRange(value)
		end
	end
end

local function applyskillfueleffect(inst, value)
	if inst.components.fueled then
		if value ~= 1 then
			value = value / 10 -- 更耐用的月亮火把
			inst.components.fueled.rate_modifiers:SetModifier(inst, value, "wilsonskill")
		else
			inst.components.fueled.rate_modifiers:RemoveModifier(inst, "wilsonskill")
		end
	end
end

local function getskillfueleffectmodifier(skilltreeupdater)
	return (skilltreeupdater:IsActivated("wilson_torch_3") and TUNING.SKILLS.WILSON_TORCH_3)
		or (skilltreeupdater:IsActivated("wilson_torch_2") and TUNING.SKILLS.WILSON_TORCH_2)
		or (skilltreeupdater:IsActivated("wilson_torch_1") and TUNING.SKILLS.WILSON_TORCH_1)
		or 1
end

local function getskillbrightnesseffectmodifier(skilltreeupdater)
	return (skilltreeupdater:IsActivated("wilson_torch_6") and TUNING.SKILLS.WILSON_TORCH_6)
		or (skilltreeupdater:IsActivated("wilson_torch_5") and TUNING.SKILLS.WILSON_TORCH_5)
		or (skilltreeupdater:IsActivated("wilson_torch_4") and TUNING.SKILLS.WILSON_TORCH_4)
		or 1
end

local function RefreshAttunedSkills(inst, owner)
	local skilltreeupdater = owner and owner.components.skilltreeupdater or nil
	if skilltreeupdater then
		applyskillbrightness(inst, getskillbrightnesseffectmodifier(skilltreeupdater))
		applyskillfueleffect(inst, getskillfueleffectmodifier(skilltreeupdater))
	else
		applyskillbrightness(inst, 1)
		applyskillfueleffect(inst, 1)
	end
end

local function WatchSkillRefresh(inst, owner)
	if inst._owner then
		inst:RemoveEventCallback("onactivateskill_server", inst._onskillrefresh, inst._owner)
		inst:RemoveEventCallback("ondeactivateskill_server", inst._onskillrefresh, inst._owner)
	end
	inst._owner = owner
	if owner then
		inst:ListenForEvent("onactivateskill_server", inst._onskillrefresh, owner)
		inst:ListenForEvent("ondeactivateskill_server", inst._onskillrefresh, owner)
	end
end

local function ignitecoldfire(inst, target)
	if target and target:IsValid() and (target.components.health == nil or not target.components.health:IsDead() and not target:HasTag("structure") and not target:HasTag("wall")) then
		if inst.components.weapon then
			local projectile = SpawnPrefab("lunar_torch_projectile")
			projectile.entity:SetParent(target.entity)
			projectile.Transform:SetPosition(0, 0.2, 0)
			projectile.target = target
			-- print("finish projectile Spawn")
		end
	end
end

local AOE_RADIUS = 5.5
local AREAATTACK_MUST_TAGS = { "_combat" }
local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "player" }

local function DoOnHitAOE(inst, pt, targets, consumefuel, damage, planar_damage)
	local sumconsumefuel = 0
	inst.components.combat.ignorehitrange = true
	local dist = math.sqrt(inst:GetDistanceSqToPoint(pt))
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, AOE_RADIUS, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
	for i, v in ipairs(ents) do
		if not targets[v] and v:IsValid() and not v:IsInLimbo() and
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			inst.components.combat:CanTarget(v)
		then
			local wasfrozen = v.components.freezable ~= nil and v.components.freezable:IsFrozen()
			inst.components.combat:SetDefaultDamage(damage)
			inst.components.planardamage:SetBaseDamage(planar_damage)
			inst.components.combat:DoAttack(v)
			inst.components.combat:SetDefaultDamage(0)
			inst.components.planardamage:SetBaseDamage(0)
			ignitecoldfire(inst, v)
			if wasfrozen then
				v:PushEvent("knockback", { knocker = inst, radius = dist + 5.5 })
			else
				if v.components.freezable ~= nil and v:IsValid() then
					v.components.freezable:AddColdness(lunarTorchThrowFreezeColdness)
					v.components.freezable:SpawnShatterFX()
				end
			end
			targets[v] = true
			if v:HasTag("epic") then
				sumconsumefuel = sumconsumefuel + consumefuel * 1.2
			else
				sumconsumefuel = sumconsumefuel + consumefuel * 0.2
			end
		end
	end
	if inst.components.fueled then
		inst.components.fueled:DoDelta(sumconsumefuel)
	end
	inst.components.combat.ignorehitrange = false
end

local function ShowColdStar(inst)
	if inst._staffstar == nil then
		inst._staffstar = SpawnPrefab("staffcoldlightfx")
		inst._staffstar.entity:SetParent(inst.entity)
		if not inst.Light:IsEnabled() then
			inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		end
	end
end

local function HideColdStar(inst)
	if inst._staffstar ~= nil then
		inst._staffstar:Remove()
		inst._staffstar = nil
		if not inst.Light:IsEnabled() then
			inst.AnimState:ClearBloomEffectHandle()
		end
	end
end

local function onequip(inst, owner)
	local restrictedtag = UPGRADETYPES.TORCH .. "_upgradeuser"
	-- 立即检测标签
	owner:DoTaskInTime(0, function(owner)
		if not owner:HasTag(restrictedtag) then
			-- 卸下并提示
			owner.components.talker:Say(GetString(owner, "ANNOUNCE_TORCH_RESTRICTED"))
			owner.components.inventory:DropItem(inst, true, true)

			-- 延迟检查最多 3 次，为了兼容切场景
			local retry_count = 0
			local function TryReEquip()
				if not (owner:IsValid() and owner.components.inventory) then
					return
				end

				if owner:HasTag(restrictedtag) then
					if owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= inst then
						owner.components.inventory:GiveItem(inst)
						owner.components.inventory:Equip(inst)
					end
				else
					if retry_count < 3 then
						retry_count = retry_count + 1
						inst:DoTaskInTime(0.5, TryReEquip)
					end
				end
			end

			inst:DoTaskInTime(0.5, TryReEquip)
		end
	end)

	inst.components.burnable:Ignite()

	-- local skin_build = inst:GetSkinBuild()
	-- if skin_build ~= nil then
	--     owner:PushEvent("equipskinneditem", inst:GetSkinName())
	--     owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_torch", inst.GUID, "swap_torch")
	-- else
	-- owner.AnimState:OverrideSymbol("land", "lunar_torchfire", "lunar_torchfire") --暂时
	-- end
	owner.AnimState:OverrideSymbol("swap_object", "swap_lunar_torch", "swap_lunar_torch") ----唯一写swap的地方
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	PlayIgniteSound(inst, owner, true, false)

	if inst.fires == nil then
		inst.fires = {}
		-- 不检测皮肤
		-- inst:GetSkinName() == nil and { "torchfire" } or SKIN_FX_PREFAB[inst:GetSkinName()] or {}
		for i, fx_prefab in ipairs({ "lunar_torchfire" }) do
			local fx = SpawnPrefab(fx_prefab)
			fx.entity:SetParent(owner.entity)
			fx.entity:AddFollower()
			fx.Follower:FollowSymbol(owner.GUID, "swap_object", fx.fx_offset_x or 0, fx.fx_offset, 0)
			fx:AttachLightTo(owner)
			-- if fx.AssignSkinData ~= nil then
			--     fx:AssignSkinData(inst)
			-- end

			table.insert(inst.fires, fx)
		end
	end

	WatchSkillRefresh(inst, owner)
	RefreshAttunedSkills(inst, owner)

	HideColdStar(inst)
end

local function onunequip(inst, owner)
	-- local skin_build = inst:GetSkinBuild()
	-- if skin_build ~= nil then
	--     owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	-- end

	if inst.fires ~= nil then
		for i, fx in ipairs(inst.fires) do
			fx:Remove()
		end
		inst.fires = nil
		PlayExtinguishSound(inst, owner, false, false)
	end

	inst.components.burnable:Extinguish()
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	WatchSkillRefresh(inst, nil)
	RefreshAttunedSkills(inst, nil)

	HideColdStar(inst)
end

local function onequiptomodel(inst, owner, from_ground)
	if inst.fires ~= nil then
		for i, fx in ipairs(inst.fires) do
			fx:Remove()
		end
		inst.fires = nil
		PlayExtinguishSound(inst, owner, true, false)
	end

	inst.components.burnable:Extinguish()
end

local function onpocket(inst, owner)
	--V2C: I think this is redundant, otherwise it would've needed fire fx cleanup as well
	inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
	if weapon.components.fueled then
		weapon.components.fueled:DoDelta(-.015 * weapon.components.fueled.maxfuel)
	end

	ignitecoldfire(weapon, target)

	local damage = lunarTouchDamage / 2
	local base_radius = lunarTouchFanRadius
	local extra_radius = 1

	local radius = base_radius
	local skillActivated = attacker.components.skilltreeupdater and
		attacker.components.skilltreeupdater:IsActivated("wilson_torch_7")
	if skillActivated then
		radius = radius + extra_radius
	end

	local tx, ty, tz = target.Transform:GetWorldPosition()
	local ax, ay, az = attacker.Transform:GetWorldPosition()
	local dx, dz = tx - ax, tz - az
	local forward_angle = math.atan2(dz, dx)

	local half_fan_angle = 60 * DEGREES
	local fx_list = { "halloween_firepuff_cold_1", "halloween_firepuff_cold_2", "halloween_firepuff_cold_3" }

	local ents = TheSim:FindEntities(tx, ty, tz, radius, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
	table.insert(ents, target)

	for _, v in ipairs(ents) do
		if v ~= attacker and v.components.combat and v.components.health and not v.components.health:IsDead() then
			local vx, vy, vz = v.Transform:GetWorldPosition()

			if v == target then
				-- target无条件命中
				v.components.combat:GetAttacked(attacker, damage, weapon)
				local fx_name = fx_list[math.random(#fx_list)]
				local fx = SpawnPrefab(fx_name)
				if fx then
					fx.Transform:SetPosition(vx, vy, vz)
				end
			else
				local offset_x, offset_z = vx - tx, vz - tz
				local target_angle = math.atan2(offset_z, offset_x)
				local angle_diff = math.atan2(math.sin(target_angle - forward_angle),
					math.cos(target_angle - forward_angle))
				if math.abs(angle_diff) <= half_fan_angle then
					v.components.combat:GetAttacked(attacker, damage, weapon)
					local fx_name = fx_list[math.random(#fx_list)]
					local fx = SpawnPrefab(fx_name)
					if fx then
						fx.Transform:SetPosition(vx, vy, vz)
					end
				end
			end
		end
	end
end

local function onupdatefueledraining(inst)
	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
	local owner_protected = owner ~= nil and
		(owner.components.sheltered ~= nil and owner.components.sheltered.sheltered or owner.components.rainimmunity ~= nil)
	if inst.components.fueled then
		inst.components.fueled.rate =
			(owner_protected or inst.components.rainimmunity ~= nil) and (inst._fuelratemult or 1) or
			(1 - TUNING.TORCH_RAIN_RATE * TheWorld.state.precipitationrate) * (inst._fuelratemult or 1)
	end
end

local function onisraining(inst, israining)
	if inst.components.fueled ~= nil then
		if israining then
			inst.components.fueled:SetUpdateFn(onupdatefueledraining)
			onupdatefueledraining(inst)
		else
			inst.components.fueled:SetUpdateFn()
			inst.components.fueled.rate = inst._fuelratemult or 1
		end
	end
end

local function onfuelchange(newsection, oldsection, inst)
	if newsection <= 0 then
		--when we burn out
		if inst.components.burnable ~= nil then
			inst.components.burnable:Extinguish()
		end
		local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
		if owner ~= nil then
			local equippable = inst.components.equippable
			if equippable ~= nil and equippable:IsEquipped() then
				local data =
				{
					prefab = inst.prefab,
					equipslot = equippable.equipslot,
					announce = "ANNOUNCE_TORCH_OUT",
				}
				PlayExtinguishSound(inst, owner, true, false)
				inst:Remove() --need to remove before "itemranout" for auto-reequip to work
				owner:PushEvent("itemranout", data)
			else
				inst:Remove()
			end
		elseif inst.fires ~= nil then
			for i, fx in ipairs(inst.fires) do
				fx:Remove()
			end
			inst.fires = nil
			PlayExtinguishSound(inst, nil, true, false)
			inst.persists = false
			inst:AddTag("NOCLICK")
			ErodeAway(inst)
		else
			--Shouldn't reach here
			inst:Remove()
		end
	end
end

local function SetFuelRateMult(inst, mult)
	mult = mult ~= 1 and mult or nil

	if inst._fuelratemult ~= mult then
		inst._fuelratemult = mult
		onisraining(inst, TheWorld.state.israining)
	end
end

local function IgniteTossed(inst)
	inst.components.burnable:Ignite()

	if inst.fires == nil then
		inst.fires = {}
		-- 不检测皮肤
		-- inst:GetSkinName() == nil and { "lunar_torchfire" } or SKIN_FX_PREFAB[inst:GetSkinName()] or {}
		for i, fx_prefab in ipairs({ "lunar_torchfire" }) do
			local fx = SpawnPrefab(fx_prefab)
			fx.entity:SetParent(inst.entity)
			fx.entity:AddFollower()
			fx.Follower:FollowSymbol(inst.GUID, "lunar_torch", fx.fx_offset_x or 0, fx.fx_offset, 0) --暂时 是swap.zip的文件夹的名字，这个和官方不一样
			fx:AttachLightTo(inst)
			-- if fx.AssignSkinData ~= nil then
			-- 	fx:AssignSkinData(inst)
			-- end

			table.insert(inst.fires, fx)
		end
	end
	if inst.thrower then
		applyskillbrightness(inst, inst.thrower.brightnessmod or 1)
		applyskillfueleffect(inst, inst.thrower.fuelmod or 1)
	end
end

local function OnThrown(inst, thrower)
	-- print("Start flying...")
	inst.thrower = thrower and thrower.components.skilltreeupdater and {
		fuelmod = getskillfueleffectmodifier(thrower.components.skilltreeupdater),
		brightnessmod = getskillbrightnesseffectmodifier(thrower.components.skilltreeupdater),
	} or nil
	inst.AnimState:PlayAnimation("spin_loop", true)
	-- inst.AnimState:PlayAnimation("idle", true) ---暂时
	inst.SoundEmitter:PlaySound("wilson_rework/torch/torch_spin", "spin_loop")
	PlayIgniteSound(inst, nil, true, true)
	IgniteTossed(inst)
	inst.components.inventoryitem.canbepickedup = false
	inst:AddTag("FX") --prevent targeting, like flingo
	-- print("End flying...")
end

local function OnHit(inst, attacker, target)
	-- print("Start Hit...")
	inst.AnimState:PlayAnimation("land")
	-- inst.AnimState:PlayAnimation("idle") ---暂时
	inst.SoundEmitter:KillSound("spin_loop")
	inst.SoundEmitter:PlaySound("wilson_rework/torch/stick_ground")
	inst.components.inventoryitem.canbepickedup = true
	inst:RemoveTag("FX")
	inst:AddTag("lighter") ---- 落地加火
	inst:AddComponent("lighter")
	-- print("Start Hit ShowColdStar...")
	ShowColdStar(inst)
	-- print("Start Hit lance...")
	local lance = SpawnPrefab("deerclops_impact_circle_fx")
	lance.Transform:SetPosition(inst.Transform:GetWorldPosition())

	local basedamage_phys = lunarTorchThrowDamage_Physical
	local basedamage_plan = lunarTorchThrowDamage_Planar
	if inst.infinite then -- 无限火炬加成计算
		local skilltreeupdater = attacker.components.skilltreeupdater
		local activedNumber = (skilltreeupdater:IsActivated("wilson_torch_3") and 3)
			or (skilltreeupdater:IsActivated("wilson_torch_2") and 2)
			or (skilltreeupdater:IsActivated("wilson_torch_1") and 1)
			or 0

		local multiplier = (1 + activedNumber * lunarTorchThrowBonus)
		basedamage_phys = basedamage_phys * multiplier
		basedamage_plan = basedamage_plan
	end

	local baseconsume = -.06 * (inst.components.fueled and inst.components.fueled.maxfuel or 0)

	DoOnHitAOE(inst, inst:GetPosition(), {}, baseconsume, basedamage_phys, basedamage_plan)

	local nearby_torches = TheSim:FindEntities(inst:GetPosition().x, 0, inst:GetPosition().z, AOE_RADIUS * 1.5,
		{ "lunar_torch" })
	for i, torch in ipairs(nearby_torches) do
		if torch ~= inst and torch.components.inventoryitem and not torch.components.inventoryitem:IsHeld() and torch:HasTag("lighter") then
			inst:DoTaskInTime(0.15 * i, function()
				local lance_follow = SpawnPrefab("deerclops_impact_circle_fx")
				if torch then
					lance_follow.Transform:SetPosition(torch.Transform:GetWorldPosition())
					torch:DoOnHitAOE(torch:GetPosition(), {}, baseconsume * 0.2, basedamage_phys * 0.2,
						basedamage_plan * 0.2)
				end
			end)
		end
	end
end

local function RemoveThrower(inst)
	if inst.thrower then
		if inst._owner == nil then
			applyskillbrightness(inst, 1)
			applyskillfueleffect(inst, 1)
		end
		inst.thrower = nil
	end
end

local function OnPutInInventory(inst, owner)
	RemoveThrower(inst)
	inst.AnimState:PlayAnimation("idle")

	if inst.fires ~= nil then
		for i, fx in ipairs(inst.fires) do
			fx:Remove()
		end
		inst.fires = nil
		PlayExtinguishSound(inst, owner, false, false)
	end

	inst.components.burnable:Extinguish()
	inst:RemoveTag("lighter") --拾起删掉火机效果
	inst:RemoveComponent("lighter")
	HideColdStar(inst)
end

local function OnExtinguish(inst)
	--V2C: Handle cases where we're extinguished externally while stuck in ground.
	--     e.g. flingo, waterballoon, icestaff
	--     NOTE: these checks should not pass for any internally handled extinguishes.
	if inst.components.fueled then
		if inst.fires ~= nil and not (inst.components.inventoryitem:IsHeld() or inst.components.fueled:IsEmpty()) then
			for i, fx in ipairs(inst.fires) do
				fx:Remove()
			end
			inst.fires = nil
			PlayExtinguishSound(inst, nil, true, false)
			--shouldn't be possible while spinning, but JUST IN CASE
			if inst:HasTag("activeprojectile") then
				inst.components.complexprojectile:Cancel()
				inst.SoundEmitter:KillSound("spin_loop")
				inst.components.inventoryitem.canbepickedup = true
				inst:RemoveTag("FX")
			end
			inst.AnimState:PlayAnimation("idle")
			local x, y, z = inst.Transform:GetWorldPosition()
			local theta = math.random() * TWOPI
			local speed = math.random()
			inst.Physics:Teleport(x, math.max(.1, y), z)
			inst.Physics:SetVel(speed * math.cos(theta), 8 + math.random(), -speed * math.sin(theta))
			HideColdStar(inst)
		end
	end
end

local function UpgradeInfinite(inst)
	inst:RemoveComponent("fueled")
	inst:RemoveTag(UPGRADETYPES.LUNAR_TORCH .. "_upgradeable")
	inst.infinite = true
	inst.AnimState:SetMultColour(0.7, 0.7, 0.7, 1) -- 修改颜色为灰一点
end

local function OnSave(inst, data)
	-- print("[OnSave] prefab =", inst.prefab, inst.GUID)
	-- print("[OnSave] infinite =", tostring(inst.infinite))

	local burnable = inst.components.burnable
	local inventoryitem = inst.components.inventoryitem

	-- if burnable ~= nil then
	-- 	print("[OnSave] IsBurning =", tostring(burnable:IsBurning()))
	-- else
	-- 	print("[OnSave] burnable = nil")
	-- end

	-- if inventoryitem ~= nil then
	-- 	print("[OnSave] IsHeld =", tostring(inventoryitem:IsHeld()))
	-- else
	-- 	print("[OnSave] inventoryitem = nil")
	-- end

	if burnable ~= nil
		and (burnable:IsBurning() or inst.infinite)
		and inventoryitem ~= nil
		and not inventoryitem:IsHeld()
	then
		if inst.thrower ~= nil then
			-- print("[OnSave] saving thrower =", inst.thrower)
			data.thrower = inst.thrower
		else
			-- print("[OnSave] saving lit = true")
			data.lit = true
		end
		-- else
		-- 	print("[OnSave] burn/hold condition not met")
	end

	data.infinite = inst.infinite
end

local function OnLoad(inst, data)
	-- print("[OnLoad] prefab =", inst.prefab)
	-- print("[OnLoad] data =", data ~= nil and "exists" or "nil")

	-- if data ~= nil then
	-- 	print("[OnLoad] data.lit =", tostring(data.lit))
	-- 	print("[OnLoad] data.thrower =", data.thrower)
	-- 	print("[OnLoad] data.infinite =", tostring(data.infinite))
	-- end

	local inventoryitem = inst.components.inventoryitem
	-- if inventoryitem ~= nil then
	-- 	print("[OnLoad] IsHeld =", tostring(inventoryitem:IsHeld()))
	-- else
	-- 	print("[OnLoad] inventoryitem = nil")
	-- end

	if data ~= nil
		and (data.lit or data.thrower ~= nil)
		and inventoryitem ~= nil
		and not inventoryitem:IsHeld()
	then
		-- print("[OnLoad] ignite condition met")

		inst.AnimState:PlayAnimation("land")
		inst:AddTag("lighter")
		inst:AddComponent("lighter")
		inst.thrower = data.thrower

		-- print("[OnLoad] calling IgniteTossed, thrower =", inst.thrower)
		IgniteTossed(inst)
		-- else
		-- 	print("[OnLoad] ignite condition NOT met")
	end

	if data ~= nil then
		inst.infinite = data.infinite
		-- print("[OnLoad] inst.infinite set to", tostring(inst.infinite))

		if inst.infinite then
			-- print("[OnLoad] calling UpgradeInfinite()")
			inst:UpgradeInfinite()
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("lunar_torch")
	inst.AnimState:SetBuild("lunar_torch") ----这个和官方不一样
	inst.AnimState:PlayAnimation("idle")
	-- inst.AnimState:SetBank("ruins_bat") -- 暂时
	-- inst.AnimState:SetBuild("swap_ruins_bat")
	-- inst.AnimState:PlayAnimation("idle")

	inst:AddTag("gestaltprotection")
	inst:AddTag("goggles")
	-- inst:AddTag("show_broken_ui")

	inst:AddTag("wildfireprotected")

	--lighter (from lighter component) added to pristine state for optimization
	inst:AddTag("lighter")

	--waterproofer (from waterproofer component) added to pristine state for optimization
	inst:AddTag("waterproofer")

	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")

	--projectile (from complexprojectile component) added to pristine state for optimization
	inst:AddTag("projectile")

	--Only get TOSS action via PointSpecialActions
	inst:AddTag("special_action_toss")
	inst:AddTag("keep_equip_toss")

	inst:AddTag("lunar_torch")

	MakeInventoryFloatable(inst, "med", nil, 0.68)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	-- inst.Transform:SetScale(1.75, 1.75, 1.75) -- 调整物体大小会影响投掷落点

	inst.entity:AddDynamicShadow()
	inst.DynamicShadow:SetSize(1.5, 1.75)


	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(lunarTouchDamage)
	inst.components.weapon:SetOnAttack(onattack)
	inst.components.weapon:SetRange(lunarTouchAttackRange)


	-----------------------------------
	-- inst:AddComponent("lighter")  ---- 删了就捡不起来
	-----------------------------------

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
	inst.components.inventoryitem:SetOnPickupFn(RemoveThrower)
	inst.components.inventoryitem.imagename = "lunar_torch"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/lunar_torch.xml"

	-----------------------------------

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnPocket(onpocket)
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable:SetOnEquipToModel(onequiptomodel)
	-- inst.components.equippable.restrictedtag = UPGRADETYPES.TORCH.."_upgradeuser"

	-----------------------------------

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(15 * 3)       -- 水平速度
	inst.components.complexprojectile:SetGravity(-35 * 3)              -- 重力值 大了就不会出屏幕
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0)) -- 发射偏移
	inst.components.complexprojectile:SetOnLaunch(OnThrown)
	inst.components.complexprojectile:SetOnHit(OnHit)
	inst.components.complexprojectile.ismeleeweapon = true

	-----------------------------------

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

	-----------------------------------

	inst:AddComponent("inspectable")

	-----------------------------------

	inst:AddComponent("burnable")
	inst.components.burnable.canlight = false
	inst.components.burnable.fxprefab = nil
	inst.components.burnable:SetOnExtinguishFn(OnExtinguish)

	-----------------------------------
	inst.infinite = false

	inst:AddComponent("fueled")
	inst.components.fueled:SetSectionCallback(onfuelchange)
	inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL)
	inst.components.fueled:SetDepletedFn(inst.Remove)
	inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

	inst:AddComponent("combat")
	inst:AddComponent("planardamage")

	inst._onskillrefresh = function(owner) RefreshAttunedSkills(inst, owner) end

	inst:WatchWorldState("israining", onisraining)
	onisraining(inst, TheWorld.state.israining)

	inst._fuelratemult = nil
	inst.SetFuelRateMult = SetFuelRateMult

	MakeHauntableLaunch(inst)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity
	inst.DoOnHitAOE = DoOnHitAOE
	inst.UpgradeInfinite = UpgradeInfinite

	inst.entity:AddLight()
	inst.Light:SetRadius(2)
	inst.Light:SetIntensity(.75)
	inst.Light:SetFalloff(.75)
	inst.Light:SetColour(128 / 255, 128 / 255, 255 / 255)
	inst.Light:Enable(false)

	return inst
end

return Prefab("lunar_torch", fn, assets, prefabs)
