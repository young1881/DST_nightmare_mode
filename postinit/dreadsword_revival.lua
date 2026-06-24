-- 绝望剑模组 (3199743326) 联动：勇者证明 → 注能-绝望石剑；彩红宝石 → 随机君王之剑变体

local DREADSWORD_PREFAB = "dreadsword"
local REVIVAL_TAG = "dreadsword_revival"
local REVIVAL_UPGRADE_ITEM = "coin_1"
local KINGLY_TAG = "dreadsword_kingly"
local UPGRADE_GEM = "opalpreciousgem"
local PARRY_DURATION = 5.5
local PARRY_COOLDOWN = 8
local PARRY_CD_ON_BLOCK = 0.7
local PARRY_EQUIP_LOCK = 2
local HORRORFUEL_REPAIR_ITEM = "horrorfuel"
local HORRORFUEL_REPAIR_PERCENT = 0.10

local SWORDMASTER_CRIT_CHANCE = 0.5
local TRACKING_AOE_RADIUS = 4
local TRACKING_FAN_ANGLE = 60 * DEGREES
local BULWARK_DAMAGE_MULT = 0.75
local BULWARK_PLANAR_DEF = 10
local DEATHSONG_MAX_HEALTH_MULT = 0.25
local DEATHSONG_LIFESTEAL = 3
local SMITH_PLANAR_BONUS = 20

local VARIANTS = {
	{ id = "parry", tag = "nm_kingly_parry" },
	{ id = "swordmaster", tag = "nm_kingly_swordmaster" },
	{ id = "tracking", tag = "nm_kingly_tracking" },
	{ id = "bulwark", tag = "nm_kingly_bulwark" },
	{ id = "deathsong", tag = "nm_kingly_deathsong" },
	{ id = "smith", tag = "nm_kingly_smith" },
}

local VARIANT_BY_ID = {}
for _, variant in ipairs(VARIANTS) do
	VARIANT_BY_ID[variant.id] = variant
end

local DREADSWORD_PARRY_STATES = {
	parry_pre = true,
	parry_idle = true,
	parry_hit = true,
	parry_knockback = true,
}

local AOE_MUST_TAGS = { "_combat" }
local AOE_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "player" }

-- 绝望剑本体模组若在服务端单独 AddComponentAction，客户端 modactioncomponents 会不同步，
-- 悬停装备槽生成动作提示时会走 DROP/CASTAOE.strfn → HasActionComponent 并崩溃。
AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
	local _orig_has_action_component = self.HasActionComponent
	if _orig_has_action_component == nil then
		return
	end

	self.HasActionComponent = function(inst, name)
		if name == nil then
			return false
		end
		local ok, ret = pcall(_orig_has_action_component, inst, name)
		if ok then
			return ret
		end
		if inst.modactioncomponents ~= nil then
			inst.modactioncomponents = nil
		end
		ok, ret = pcall(_orig_has_action_component, inst, name)
		if ok then
			return ret
		end
		return false
	end

	-- 客户端动态 AddComponent("reticule") 后，CancelAOETargeting → StopTargeting →
	-- RemoveComponent 可能在 UnregisterComponentActions 处因 modactioncomponents 不同步而崩溃。
	local _orig_remove_component = self.RemoveComponent
	if _orig_remove_component ~= nil then
		self.RemoveComponent = function(inst, name, ...)
			if name == nil then
				return
			end
			local ok, ret = pcall(_orig_remove_component, inst, name, ...)
			if ok then
				return ret
			end
			if inst.modactioncomponents ~= nil then
				inst.modactioncomponents = nil
			end
			ok, ret = pcall(_orig_remove_component, inst, name, ...)
			if ok then
				return ret
			end
			if inst.components ~= nil then
				inst.components[name] = nil
			end
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 通用

local function GetKinglyVariantId(inst)
	if inst == nil then
		return nil
	end
	if inst._nm_kingly_variant ~= nil then
		return inst._nm_kingly_variant
	end
	for _, variant in ipairs(VARIANTS) do
		if inst:HasTag(variant.tag) then
			return variant.id
		end
	end
	return nil
end

local function GetKinglyStringKey(variant_id)
	return "DREADSWORD_" .. string.upper(variant_id or "")
end

local function GetKinglyVariantName(variant_id)
	local key = GetKinglyStringKey(variant_id)
	return STRINGS.NAMES[key] or "君王之剑"
end

local function CanWilsonUpgradeDreadsword(doer)
	return doer ~= nil and doer.prefab == "wilson"
end

local function IsKinglyDreadsword(inst)
	return inst ~= nil and (inst:HasTag(KINGLY_TAG) or GetKinglyVariantId(inst) ~= nil)
end

local function IsRevivalDreadsword(inst)
	return inst ~= nil and (inst:HasTag(REVIVAL_TAG) or inst._nm_revival_parry_applied)
end

local function IsUpgradedDreadsword(inst)
	return IsKinglyDreadsword(inst) or IsRevivalDreadsword(inst)
end

local function GetDreadswordUpgradeKey(inst)
	if inst == nil then
		return nil
	end
	if inst.nameoverride ~= nil and inst.nameoverride ~= "" then
		return inst.nameoverride
	end
	if inst.replica ~= nil and inst.replica.inspectable ~= nil then
		if inst.replica.inspectable.GetNameOverride ~= nil then
			local override = inst.replica.inspectable:GetNameOverride()
			if override ~= nil and override ~= "" then
				return override
			end
		end
		local classified = inst.replica.inspectable.classified
		if classified ~= nil and classified.nameoverride ~= nil then
			local override = classified.nameoverride:value()
			if override ~= nil and override ~= "" then
				return override
			end
		end
	end
	return nil
end

local function IsDreadswordUpgradeKey(key)
	return key ~= nil and key ~= "" and key ~= "dreadsword"
		and string.sub(key, 1, 10) == "dreadsword"
end

-- 服务端 AddTag 不会同步到客户端，修复/给予动作需额外依据名称或本地应用状态判断
local function IsUpgradedDreadswordForAction(inst)
	if IsUpgradedDreadsword(inst) then
		return true
	end
	if inst._nm_revival_parry_applied or inst._nm_kingly_applied then
		return true
	end
	return IsDreadswordUpgradeKey(GetDreadswordUpgradeKey(inst))
end

local function DreadswordNeedsRepair(target)
	if target.replica ~= nil and target.replica.finiteuses ~= nil then
		return target.replica.finiteuses:GetPercent() < 1
	end
	if target.components ~= nil and target.components.finiteuses ~= nil then
		return target.components.finiteuses:GetPercent() < 1
	end
	-- 客户端可能暂时没有 finiteuses replica，交给服务端 trader 校验
	return not TheWorld.ismastersim
end

local function GetEquippedHandsItem(owner)
	if owner == nil then
		return nil
	end
	if owner.components ~= nil and owner.components.inventory ~= nil then
		return owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	end
	if owner.replica ~= nil and owner.replica.inventory ~= nil then
		return owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	end
	return nil
end

local function GetEquippedRevivalDreadsword(owner)
	local weapon = GetEquippedHandsItem(owner)
	if weapon ~= nil and weapon:HasTag(REVIVAL_TAG) then
		return weapon
	end
	return nil
end

local function PickRandomVariantId()
	return VARIANTS[math.random(#VARIANTS)].id
end

local function GetEquippedKinglyDreadsword(owner, variant_id)
	local weapon = GetEquippedHandsItem(owner)
	if weapon == nil or not IsKinglyDreadsword(weapon) then
		return nil
	end
	if variant_id ~= nil and GetKinglyVariantId(weapon) ~= variant_id then
		return nil
	end
	return weapon
end

local function WrapWeaponOnAttack(inst, fn)
	if inst.components.weapon == nil or fn == nil then
		return
	end
	local old_onattack = inst.components.weapon.onattack
	inst.components.weapon:SetOnAttack(function(weapon, attacker, target, ...)
		if old_onattack ~= nil then
			old_onattack(weapon, attacker, target, ...)
		end
		fn(weapon, attacker, target)
	end)
end

------------------------------------------------------------------------------------------------------------------------
-- 准星（招架变体，与 ruins_bat 一致）

local function ReticuleTargetFn()
	if ThePlayer == nil or ThePlayer.entity == nil then
		return Vector3(0, 0, 0)
	end
	return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
	if mousepos ~= nil and inst ~= nil and inst.Transform ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local dx = mousepos.x - x
		local dz = mousepos.z - z
		local l = dx * dx + dz * dz
		if l <= 0 then
			if inst.components.reticule ~= nil then
				return inst.components.reticule.targetpos
			end
			return Vector3(x, 0, z)
		end
		l = 6.5 / math.sqrt(l)
		return Vector3(x + dx * l, 0, z + dz * l)
	end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	if inst == nil or inst.Transform == nil or pos == nil or reticule == nil or reticule.Transform == nil then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	reticule.Transform:SetPosition(x, 0, z)
	local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
	if ease and dt ~= nil then
		local rot0 = reticule.Transform:GetRotation()
		local drot = rot - rot0
		rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
	end
	reticule.Transform:SetRotation(rot)
end

local function SafeAoetargetingSetEnabled(aoetargeting, enabled)
	if aoetargeting == nil then
		return
	end
	if TheWorld.ismastersim then
		if aoetargeting.enabled:value() ~= enabled then
			aoetargeting.enabled:set(enabled)
		end
	end
end

local function IsParryDreadsword(inst)
	return IsRevivalDreadsword(inst) or GetKinglyVariantId(inst) == "parry"
end

local function IsDreadswordParryCharged(inst)
	if inst == nil then
		return false
	end
	if inst.components.rechargeable ~= nil then
		return inst.components.rechargeable:IsCharged()
	end
	if inst.replica ~= nil and inst.replica.rechargeable ~= nil then
		return inst.replica.rechargeable:IsCharged()
	end
	-- 客户端 rechargeable 可能尚未同步，用服务端写入的 aoetargeting.enabled 推断
	if not TheWorld.ismastersim and inst.components.aoetargeting ~= nil then
		return inst.components.aoetargeting:IsEnabled()
	end
	return false
end

local function IsDreadswordParryTargetingEnabled(inst)
	if inst == nil or inst.components.aoetargeting == nil then
		return false
	end
	if not IsParryDreadsword(inst) then
		return inst.components.aoetargeting:IsEnabled()
	end
	if not IsDreadswordParryCharged(inst) then
		return false
	end
	return inst.components.aoetargeting:IsEnabled()
end

local function GetDreadswordOwner(inst)
	if inst == nil or not inst:IsValid() then
		return nil
	end
	if TheWorld.ismastersim then
		if inst.components.inventoryitem ~= nil then
			return inst.components.inventoryitem:GetGrandOwner()
		end
		return nil
	end
	local player = ThePlayer
	if player == nil or player.replica.inventory == nil then
		return nil
	end
	if inst.replica ~= nil and inst.replica.inventoryitem ~= nil
		and inst.replica.inventoryitem:IsGrandOwner(player) then
		return player
	end
	if player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == inst then
		return player
	end
	return nil
end

local function SafeRemoveDreadswordReticule(inst)
	if inst == nil or inst.components.reticule == nil then
		return
	end
	local ok = pcall(function()
		inst:RemoveComponent("reticule")
	end)
	if not ok and inst.components.reticule ~= nil then
		if inst.modactioncomponents ~= nil then
			inst.modactioncomponents = nil
		end
		inst.components.reticule = nil
	end
end

local function StopDreadswordParryTargeting(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	local owner = GetDreadswordOwner(inst)
	if owner ~= nil and owner:IsValid() and owner.components.playercontroller ~= nil then
		owner.components.playercontroller:RefreshReticule(nil)
	end
	SafeRemoveDreadswordReticule(inst)
end

local function StartDreadswordParryTargeting(inst, owner)
	if TheWorld.ismastersim then
		return false
	end
	if inst == nil or inst.components.aoetargeting == nil or not IsDreadswordParryTargetingEnabled(inst) then
		return false
	end
	owner = owner or GetDreadswordOwner(inst) or ThePlayer
	if owner == nil or owner.components.playercontroller == nil then
		return false
	end
	if inst.components.reticule == nil then
		inst:AddComponent("reticule")
		for k, v in pairs(inst.components.aoetargeting.reticule) do
			inst.components.reticule[k] = v
		end
	end
	owner.components.playercontroller:RefreshReticule(inst)
	return true
end

local function PatchDreadswordParryAoetargeting(inst)
	if inst.components.aoetargeting == nil or not IsParryDreadsword(inst) then
		return
	end

	if not inst._nm_start_targeting_patched then
		inst._nm_start_targeting_patched = true
		local aoetargeting = inst.components.aoetargeting
		local _StartTargeting = aoetargeting.StartTargeting
		aoetargeting.StartTargeting = function(self, ...)
			if not IsDreadswordParryTargetingEnabled(inst) then
				return false
			end
			if not TheWorld.ismastersim then
				return StartDreadswordParryTargeting(inst, ThePlayer)
			end
			return _StartTargeting(self, ...)
		end
	end

	if not inst._nm_stop_targeting_patched then
		inst._nm_stop_targeting_patched = true
		local aoetargeting = inst.components.aoetargeting
		local _StopTargeting = aoetargeting.StopTargeting
		aoetargeting.StopTargeting = function(self, ...)
			if not TheWorld.ismastersim then
				StopDreadswordParryTargeting(inst)
				return
			end
			return _StopTargeting(self, ...)
		end
	end
end

local function PatchDreadswordParryStartTargeting(inst)
	PatchDreadswordParryAoetargeting(inst)
end

local function RefreshOwnerParryReticule(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	local owner = GetDreadswordOwner(inst)
	if owner == nil or not owner:IsValid() or owner.components.playercontroller == nil then
		return
	end
	local equipped = owner.replica ~= nil
		and owner.replica.inventory ~= nil
		and owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		or (owner.components.inventory ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS))
	if equipped == inst and IsDreadswordParryTargetingEnabled(inst) then
		owner.components.playercontroller:RefreshReticule(inst)
	else
		owner.components.playercontroller:RefreshReticule(nil)
	end
end

local function SyncParryTargetingClient(inst)
	if inst.components.aoetargeting == nil then
		return
	end
	PatchDreadswordParryStartTargeting(inst)
	if not inst._nm_parry_client_synced then
		inst._nm_parry_client_synced = true
		inst:ListenForEvent("enableddirty", function()
			RefreshOwnerParryReticule(inst)
		end)
		if inst.replica ~= nil and inst.replica.rechargeable ~= nil then
			inst:ListenForEvent("rechargdirty", function()
				RefreshOwnerParryReticule(inst)
			end)
		end
	end
	RefreshOwnerParryReticule(inst)
end

local function SyncRevivalParryTargeting(inst)
	if inst.components.aoetargeting == nil or not inst:HasTag(REVIVAL_TAG) then
		SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)
		return
	end
	if not TheWorld.ismastersim then
		return
	end
	local charged = inst.components.rechargeable ~= nil and inst.components.rechargeable:IsCharged()
	SafeAoetargetingSetEnabled(inst.components.aoetargeting, charged)
	RefreshOwnerParryReticule(inst)
end

local function SyncParryTargeting(inst)
	if inst.components.aoetargeting == nil or GetKinglyVariantId(inst) ~= "parry" then
		SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)
		return
	end
	if not TheWorld.ismastersim then
		return
	end
	local charged = inst.components.rechargeable ~= nil and inst.components.rechargeable:IsCharged()
	SafeAoetargetingSetEnabled(inst.components.aoetargeting, charged)
	RefreshOwnerParryReticule(inst)
end

local function EnsureParryAoetargeting(inst)
	if inst._nm_kingly_aoetargeting_setup and inst.components.aoetargeting == nil then
		inst._nm_kingly_aoetargeting_setup = nil
	end
	if inst._nm_kingly_aoetargeting_setup then
		return
	end
	inst._nm_kingly_aoetargeting_setup = true

	if inst.components.aoetargeting == nil then
		inst:AddComponent("aoetargeting")
		inst.components.aoetargeting:SetAlwaysValid(true)
		inst.components.aoetargeting:SetAllowRiding(false)
		inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
		inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
		inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
		inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
		inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
		inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
		inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
		inst.components.aoetargeting.reticule.ease = true
		inst.components.aoetargeting.reticule.mouseenabled = true
	end

	if TheWorld.ismastersim then
		SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)
	end
end

local AddRevivalParryComponents
local ApplyKinglyUpgrade
local ClientApplyUpgradedDreadswordFromPlayer

local function ApplyDreadswordUpgradeOnClient(sword_guid, variant_id)
	if TheWorld.ismastersim then
		return
	end
	local sword = sword_guid ~= nil and Ents[sword_guid] or nil
	if sword == nil or not sword:IsValid() or sword.prefab ~= DREADSWORD_PREFAB then
		if ClientApplyUpgradedDreadswordFromPlayer ~= nil then
			ClientApplyUpgradedDreadswordFromPlayer(ThePlayer)
		end
		return
	end
	if variant_id == "revival" then
		AddRevivalParryComponents(sword)
	elseif variant_id ~= nil and variant_id ~= "" then
		ApplyKinglyUpgrade(sword, variant_id)
	end
end

local function NotifyClientDreadswordUpgradeSync(sword, giver, variant_id)
	if not TheWorld.ismastersim or giver == nil or giver.userid == nil or sword == nil then
		return
	end
	if MOD_RPC["my_mod"] == nil or MOD_RPC["my_mod"]["dreadsword_upgrade_sync"] == nil then
		return
	end
	SendModRPCToClient(MOD_RPC["my_mod"]["dreadsword_upgrade_sync"], giver.userid, sword.GUID, variant_id or "revival")
end

local function NotifyClientRevivalParrySync(inst, owner)
	if not TheWorld.ismastersim or owner == nil or owner.userid == nil then
		return
	end
	if MOD_RPC["my_mod"] == nil or MOD_RPC["my_mod"]["dreadsword_revival_parry_sync"] == nil then
		return
	end
	SendModRPCToClient(MOD_RPC["my_mod"]["dreadsword_revival_parry_sync"], owner.userid)
end

local function NotifyClientParrySync(inst, owner)
	if not TheWorld.ismastersim or owner == nil or owner.userid == nil then
		return
	end
	if MOD_RPC["my_mod"] == nil or MOD_RPC["my_mod"]["dreadsword_kingly_parry_sync"] == nil then
		return
	end
	SendModRPCToClient(MOD_RPC["my_mod"]["dreadsword_kingly_parry_sync"], owner.userid)
end

local function RefreshDreadswordBladeFx(weapon, owner)
	if weapon == nil or owner == nil or not owner:IsValid() then
		return
	end
	if weapon.blade1 ~= nil and weapon.blade1:IsValid() and weapon.blade1.Follower ~= nil then
		weapon.blade1.entity:SetParent(owner.entity)
		weapon.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
		if weapon.blade1.components.highlightchild ~= nil then
			weapon.blade1.components.highlightchild:SetOwner(owner)
		end
	end
	if weapon.blade2 ~= nil and weapon.blade2:IsValid() and weapon.blade2.Follower ~= nil then
		weapon.blade2.entity:SetParent(owner.entity)
		weapon.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
		if weapon.blade2.components.highlightchild ~= nil then
			weapon.blade2.components.highlightchild:SetOwner(owner)
		end
	end
end

local function OnDreadswordParryStateEnter(inst)
	local weapon = GetEquippedKinglyDreadsword(inst, "parry") or GetEquippedRevivalDreadsword(inst)
	if weapon ~= nil then
		RefreshDreadswordBladeFx(weapon, inst)
	end
end

local function PatchDreadswordParryVisualState(sg, state_name)
	local state = sg.states[state_name]
	if state == nil or state._nm_dreadsword_parry_visual_patch then
		return
	end
	state._nm_dreadsword_parry_visual_patch = true

	local old_onenter = state.onenter
	state.onenter = function(inst, data)
		if old_onenter ~= nil then
			old_onenter(inst, data)
		end
		OnDreadswordParryStateEnter(inst)
	end
end

local function PatchDreadswordParryVisualStates(sg)
	for state_name in pairs(DREADSWORD_PARRY_STATES) do
		PatchDreadswordParryVisualState(sg, state_name)
	end
end

AddStategraphPostInit("wilson", PatchDreadswordParryVisualStates)
AddStategraphPostInit("wilson_client", PatchDreadswordParryVisualStates)

------------------------------------------------------------------------------------------------------------------------
-- 变体效果

local function ParrySpellFn(inst, doer, pos)
	if not TheWorld.ismastersim then
		return true
	end
	inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), PARRY_DURATION)
	inst.components.rechargeable:Discharge(PARRY_COOLDOWN)
end

local function ParryOnParry(inst, doer, attacker, damage)
	doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)
	if doer.SoundEmitter ~= nil then
		doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
	end

	doer:AddTag("curse_immune")
	doer:DoTaskInTime(0.3, function()
		if doer:IsValid() then
			doer:RemoveTag("curse_immune")
		end
	end)

	if inst.components.rechargeable:GetPercent() < PARRY_CD_ON_BLOCK then
		inst.components.rechargeable:SetPercent(PARRY_CD_ON_BLOCK)
	end
end

local function ParryOnDischarged(inst)
	SafeAoetargetingSetEnabled(inst.components.aoetargeting, false)
	RefreshOwnerParryReticule(inst)
end

local function ParryOnCharged(inst)
	SafeAoetargetingSetEnabled(inst.components.aoetargeting, true)
	RefreshOwnerParryReticule(inst)
end

local function SetupParryVariant(inst)
	inst:AddTag("parryweapon")
	inst:AddTag("battleshield")
	inst:AddTag("rechargeable")

	-- 与 ruins_bat 一致：客户端仅 aoetargeting；rechargeable/parryweapon/aoespell 仅服务端
	EnsureParryAoetargeting(inst)
	PatchDreadswordParryStartTargeting(inst)

	if not TheWorld.ismastersim then
		SyncParryTargetingClient(inst)
		return
	end

	if inst.components.parryweapon == nil then
		inst:AddComponent("parryweapon")
		inst.components.parryweapon:SetParryArc(178)
	end
	inst.components.parryweapon:SetOnParryFn(ParryOnParry)

	if inst.components.rechargeable == nil then
		inst:AddComponent("rechargeable")
	end
	inst.components.rechargeable:SetOnDischargedFn(ParryOnDischarged)
	inst.components.rechargeable:SetOnChargedFn(ParryOnCharged)

	if inst.components.aoespell == nil then
		inst:AddComponent("aoespell")
	end
	inst.components.aoespell:SetSpellFn(ParrySpellFn)

	SyncParryTargeting(inst)
end

local function GetDreadswordAttackDamage(weapon)
	local physical = weapon.components.weapon ~= nil and weapon.components.weapon.damage or 0
	local planar = 0
	if weapon.components.planardamage ~= nil then
		planar = weapon.components.planardamage:GetBaseDamage() or 0
	end
	return physical, planar
end

local function SwordmasterOnAttack(weapon, attacker, target)
	if target == nil or not target:IsValid() or target.components.combat == nil then
		return
	end
	if math.random() >= SWORDMASTER_CRIT_CHANCE then
		return
	end

	local physical, planar = GetDreadswordAttackDamage(weapon)
	if physical <= 0 and planar <= 0 then
		return
	end
	local spdamage = planar > 0 and { planar = planar } or nil
	target.components.combat:GetAttacked(attacker, physical, weapon, nil, spdamage)
end

local function SetupSwordmasterVariant(inst)
	if not TheWorld.ismastersim then
		return
	end
	WrapWeaponOnAttack(inst, SwordmasterOnAttack)
end

local function TrackingCanHit(attacker, victim)
	if victim == nil or not victim:IsValid() or victim:IsInLimbo() then
		return false
	end
	if victim.components.health ~= nil and victim.components.health:IsDead() then
		return false
	end
	if attacker ~= nil and attacker.components.combat ~= nil then
		return attacker.components.combat:CanTarget(victim)
	end
	return victim.components.combat ~= nil
end

local function TrackingBladeOnAttack(weapon, attacker, target)
	if target == nil or not target:IsValid() or attacker.components.combat == nil then
		return
	end

	local tx, ty, tz = target.Transform:GetWorldPosition()
	local ax, _, az = attacker.Transform:GetWorldPosition()
	local forward_angle = math.atan2(tz - az, tx - ax)
	local ents = TheSim:FindEntities(tx, ty, tz, TRACKING_AOE_RADIUS, AOE_MUST_TAGS, AOE_EXCLUDE_TAGS)

	for _, v in ipairs(ents) do
		if v ~= attacker and v ~= target and TrackingCanHit(attacker, v) then
			local vx, _, vz = v.Transform:GetWorldPosition()
			local target_angle = math.atan2(vz - tz, vx - tx)
			local angle_diff = math.atan2(
				math.sin(target_angle - forward_angle),
				math.cos(target_angle - forward_angle))
			if math.abs(angle_diff) <= TRACKING_FAN_ANGLE then
				local splash = weapon.components.weapon ~= nil and weapon.components.weapon.damage or 0
				v.components.combat:GetAttacked(attacker, splash, weapon)
			end
		end
	end
end

local function SetupTrackingVariant(inst)
	if not TheWorld.ismastersim then
		return
	end
	WrapWeaponOnAttack(inst, TrackingBladeOnAttack)
end

local function ApplyBulwarkBuff(weapon, owner)
	if owner.components.combat ~= nil then
		owner.components.combat.externaldamagetakenmultipliers:SetModifier(
			weapon, BULWARK_DAMAGE_MULT, "dreadsword_bulwark")
	end
	if owner.components.planardefense == nil then
		owner:AddComponent("planardefense")
	end
	if owner.components.planardefense.AddBonus ~= nil then
		owner.components.planardefense:AddBonus(weapon, BULWARK_PLANAR_DEF, "dreadsword_bulwark")
	else
		owner.components.planardefense:SetBaseDefense(
			(owner.components.planardefense:GetDefense() or 0) + BULWARK_PLANAR_DEF)
		owner._nm_bulwark_planar_applied = true
	end
end

local function RemoveBulwarkBuff(weapon, owner)
	if owner.components.combat ~= nil then
		owner.components.combat.externaldamagetakenmultipliers:RemoveModifier(weapon, "dreadsword_bulwark")
	end
	if owner.components.planardefense ~= nil then
		if owner.components.planardefense.RemoveBonus ~= nil then
			owner.components.planardefense:RemoveBonus(weapon, "dreadsword_bulwark")
		elseif owner._nm_bulwark_planar_applied then
			local current = owner.components.planardefense:GetDefense() or 0
			owner.components.planardefense:SetBaseDefense(math.max(0, current - BULWARK_PLANAR_DEF))
			owner._nm_bulwark_planar_applied = nil
		end
	end
end

local function ApplyDeathsongPenalty(owner)
	-- 暂时禁用死歌变体血上限惩罚
	--[[
	if owner.components.health == nil or owner._nm_deathsong_orig_max ~= nil then
		return
	end
	owner._nm_deathsong_orig_max = owner.components.health.maxhealth
	local percent = owner.components.health:GetPercent()
	owner.components.health.maxhealth = math.max(1, owner._nm_deathsong_orig_max * DEATHSONG_MAX_HEALTH_MULT)
	owner.components.health:SetPercent(percent)
	--]]
end

local function RemoveDeathsongPenalty(owner)
	-- 暂时禁用死歌变体血上限惩罚
	--[[
	if owner.components.health == nil or owner._nm_deathsong_orig_max == nil then
		return
	end
	local percent = owner.components.health:GetPercent()
	owner.components.health.maxhealth = owner._nm_deathsong_orig_max
	owner.components.health:SetPercent(percent)
	owner._nm_deathsong_orig_max = nil
	--]]
end

local function DeathsongOnAttack(weapon, attacker, target)
	if attacker.components.health ~= nil and not attacker.components.health:IsDead() then
		attacker.components.health:DoDelta(DEATHSONG_LIFESTEAL, false, "dreadsword_deathsong")
	end
end

local function SetupDeathsongVariant(inst)
	if not TheWorld.ismastersim then
		return
	end
	WrapWeaponOnAttack(inst, DeathsongOnAttack)
end

local function SetupSmithVariant(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
		inst.components.planardamage:SetBaseDamage(SMITH_PLANAR_BONUS)
	else
		local current = inst.components.planardamage:GetBaseDamage() or 0
		inst.components.planardamage:SetBaseDamage(current + SMITH_PLANAR_BONUS)
	end
end

local VARIANT_SETUP = {
	parry = SetupParryVariant,
	swordmaster = SetupSwordmasterVariant,
	tracking = SetupTrackingVariant,
	deathsong = SetupDeathsongVariant,
	smith = SetupSmithVariant,
}

local function OnKinglyEquip(inst, owner, variant_id, old_equip)
	if old_equip ~= nil then
		old_equip(inst, owner)
	end
	if variant_id == "parry" and inst.components.rechargeable ~= nil
		and inst.components.rechargeable:GetTimeToCharge() < PARRY_EQUIP_LOCK then
		inst.components.rechargeable:Discharge(PARRY_EQUIP_LOCK)
	end
	if variant_id == "bulwark" then
		ApplyBulwarkBuff(inst, owner)
	elseif variant_id == "deathsong" then
		ApplyDeathsongPenalty(owner)
	end
	if variant_id == "parry" then
		SyncParryTargeting(inst)
	end
end

local function OnKinglyUnequip(inst, owner, variant_id, old_unequip)
	if variant_id == "bulwark" then
		RemoveBulwarkBuff(inst, owner)
	elseif variant_id == "deathsong" then
		RemoveDeathsongPenalty(owner)
	end
	if old_unequip ~= nil then
		old_unequip(inst, owner)
	end
	if owner ~= nil and owner.components.playercontroller ~= nil then
		owner.components.playercontroller:RefreshReticule(nil)
	end
end

local function PatchKinglyEquippable(inst, variant_id)
	if inst.components.equippable == nil then
		return
	end
	local old_equip = inst.components.equippable.onequipfn
	local old_unequip = inst.components.equippable.onunequipfn
	inst.components.equippable:SetOnEquip(function(equip, owner)
		OnKinglyEquip(equip, owner, variant_id, old_equip)
	end)
	inst.components.equippable:SetOnUnequip(function(equip, owner)
		OnKinglyUnequip(equip, owner, variant_id, old_unequip)
	end)
end

------------------------------------------------------------------------------------------------------------------------
-- 升级与存档

local function ApplyKinglyStrings(inst, variant_id)
	if variant_id == nil then
		return
	end
	local name_key = "dreadsword_" .. variant_id
	-- 物品栏/悬停名称走 EntityScript.nameoverride → STRINGS.NAMES
	inst.nameoverride = name_key

	if not TheWorld.ismastersim then
		return
	end

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
	if inst.components.inspectable.SetNameOverride ~= nil then
		inst.components.inspectable:SetNameOverride(name_key)
	else
		inst.components.inspectable.nameoverride = name_key
	end
end

-- 绝望剑 prefab 在客户端没有 inventoryitem 组件，名称需通过 displaynamefn + 同步 tag 解析
local function SetupKinglyEntityDisplayName(inst)
	if inst._nm_kingly_entity_display_setup then
		return
	end
	inst._nm_kingly_entity_display_setup = true

	local old_displaynamefn = inst.displaynamefn
	inst.displaynamefn = function(entity)
		if IsRevivalDreadsword(entity) then
			return STRINGS.NAMES.DREADSWORD_REVIVAL or "注能-绝望石剑"
		end
		if IsKinglyDreadsword(entity) then
			return GetKinglyVariantName(GetKinglyVariantId(entity))
		end
		if old_displaynamefn ~= nil then
			return old_displaynamefn(entity)
		end
	end
end

local function ApplyRevivalStrings(inst)
	local name_key = "dreadsword_revival"
	inst.nameoverride = name_key

	if not TheWorld.ismastersim then
		return
	end

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
	if inst.components.inspectable.SetNameOverride ~= nil then
		inst.components.inspectable:SetNameOverride(name_key)
	else
		inst.components.inspectable.nameoverride = name_key
	end
end

local SetupKinglyTrader

local function PatchRevivalEquippable(inst)
	if inst.components.equippable == nil then
		return
	end
	local old_equip = inst.components.equippable.onequipfn
	local old_unequip = inst.components.equippable.onunequipfn
	inst.components.equippable:SetOnEquip(function(equip, owner)
		if old_equip ~= nil then
			old_equip(equip, owner)
		end
		if TheWorld.ismastersim then
			if equip.components.rechargeable ~= nil
				and equip.components.rechargeable:GetTimeToCharge() < PARRY_EQUIP_LOCK then
				equip.components.rechargeable:Discharge(PARRY_EQUIP_LOCK)
			end
			SyncRevivalParryTargeting(equip)
			if owner ~= nil then
				NotifyClientRevivalParrySync(equip, owner)
			end
		else
			SyncParryTargetingClient(equip)
		end
	end)
	inst.components.equippable:SetOnUnequip(function(equip, owner)
		if old_unequip ~= nil then
			old_unequip(equip, owner)
		end
		if owner ~= nil and owner.components.playercontroller ~= nil then
			owner.components.playercontroller:RefreshReticule(nil)
		end
	end)
end

AddRevivalParryComponents = function(inst)
	if inst._nm_revival_parry_applied or IsKinglyDreadsword(inst) then
		return
	end
	inst._nm_revival_parry_applied = true

	inst:AddTag(REVIVAL_TAG)
	SetupParryVariant(inst)
	ApplyRevivalStrings(inst)
	SetupKinglyTrader(inst)
	inst:DoTaskInTime(0, function()
		if inst:IsValid() and inst:HasTag(REVIVAL_TAG) then
			ApplyRevivalStrings(inst)
		end
	end)

	if not TheWorld.ismastersim then
		SyncParryTargetingClient(inst)
		local owner = GetDreadswordOwner(inst)
		if owner ~= nil then
			RefreshOwnerParryReticule(inst)
		end
		return
	end

	PatchRevivalEquippable(inst)
	SyncRevivalParryTargeting(inst)

	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
	if owner ~= nil then
		RefreshOwnerParryReticule(inst)
		NotifyClientRevivalParrySync(inst, owner)
	end
end

SetupKinglyTrader = function(inst)
	-- 客户端也需要 trader 标签，否则 AddComponentAction 不会显示「给予」升级/修复
	inst:AddTag("trader")
	inst:AddTag("alltrader")

	if not TheWorld.ismastersim then
		return
	end

	if inst.components.trader == nil then
		inst:AddComponent("trader")
	end
	inst.components.trader:SetAcceptTest(function(sword, item, giver)
		if item == nil then
			return false
		end
		if IsRevivalDreadsword(sword) or IsKinglyDreadsword(sword) then
			if item.prefab ~= HORRORFUEL_REPAIR_ITEM then
				return false
			end
			if sword.components.finiteuses == nil then
				return false
			end
			return sword.components.finiteuses:GetPercent() < 1
		end
		if item.prefab == REVIVAL_UPGRADE_ITEM then
			return true
		end
		if item.prefab == UPGRADE_GEM then
			return CanWilsonUpgradeDreadsword(giver)
		end
		return false
	end)
	inst.components.trader:SetOnAccept(function(sword, giver, item)
		if item == nil then
			return
		end
		if item.prefab == REVIVAL_UPGRADE_ITEM and not IsUpgradedDreadsword(sword) then
			AddRevivalParryComponents(sword)
			if giver ~= nil and giver.components.talker ~= nil then
				giver.components.talker:Say("以勇者的证明，为绝望之刃注能！")
			end
			if giver ~= nil and giver.userid ~= nil then
				NotifyClientDreadswordUpgradeSync(sword, giver, "revival")
				NotifyClientRevivalParrySync(sword, giver)
			end
		elseif item.prefab == UPGRADE_GEM and not IsUpgradedDreadsword(sword) then
			local variant_id = PickRandomVariantId()
			ApplyKinglyUpgrade(sword, variant_id)
			if giver ~= nil and giver.components.talker ~= nil then
				giver.components.talker:Say(GetKinglyVariantName(variant_id) .. "！")
			end
			if giver ~= nil and giver.userid ~= nil then
				NotifyClientDreadswordUpgradeSync(sword, giver, variant_id)
				if variant_id == "parry" then
					NotifyClientParrySync(sword, giver)
				end
			end
		elseif item.prefab == HORRORFUEL_REPAIR_ITEM and IsUpgradedDreadsword(sword)
			and sword.components.finiteuses ~= nil then
			sword.components.finiteuses:Repair(sword.components.finiteuses.total * HORRORFUEL_REPAIR_PERCENT)
			if giver ~= nil and giver.components.talker ~= nil then
				giver.components.talker:Say("纯粹恐惧修补了剑刃。")
			end
			if giver ~= nil and giver.SoundEmitter ~= nil then
				giver.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
			end
		end
	end)
	inst.components.trader.deleteitemonaccept = true
end

ApplyKinglyUpgrade = function(inst, variant_id)
	if inst._nm_kingly_applied or IsRevivalDreadsword(inst)
		or variant_id == nil or VARIANT_BY_ID[variant_id] == nil then
		return
	end
	inst._nm_kingly_applied = true
	inst._nm_kingly_variant = variant_id

	inst:AddTag(KINGLY_TAG)
	inst:AddTag(VARIANT_BY_ID[variant_id].tag)

	ApplyKinglyStrings(inst, variant_id)
	inst:DoTaskInTime(0, function()
		if inst:IsValid() and GetKinglyVariantId(inst) == variant_id then
			ApplyKinglyStrings(inst, variant_id)
		end
	end)

	local setup_fn = VARIANT_SETUP[variant_id]
	if setup_fn ~= nil then
		setup_fn(inst)
	end

	SetupKinglyTrader(inst)

	if not TheWorld.ismastersim then
		if variant_id == "parry" then
			SyncParryTargetingClient(inst)
		end
		return
	end

	PatchKinglyEquippable(inst, variant_id)

	if variant_id == "parry" then
		SyncParryTargeting(inst)
		local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
		if owner ~= nil then
			RefreshOwnerParryReticule(inst)
			NotifyClientParrySync(inst, owner)
		end
	end
end

ClientApplyUpgradedDreadswordFromPlayer = function(player)
	if player == nil or player.replica.inventory == nil then
		return
	end
	local function TryApply(weapon)
		if weapon == nil or not weapon:IsValid() or weapon.prefab ~= DREADSWORD_PREFAB then
			return
		end
		if weapon:HasTag(REVIVAL_TAG) or GetDreadswordUpgradeKey(weapon) == "dreadsword_revival" then
			AddRevivalParryComponents(weapon)
			return
		end
		local variant_id = GetKinglyVariantId(weapon) or weapon._nm_kingly_variant
		if variant_id == nil then
			local key = GetDreadswordUpgradeKey(weapon)
			if IsDreadswordUpgradeKey(key) then
				variant_id = string.sub(key, 12)
			end
		end
		if variant_id ~= nil then
			ApplyKinglyUpgrade(weapon, variant_id)
		end
	end
	TryApply(player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS))
	if player.replica.inventory.GetItems ~= nil then
		for _, item in pairs(player.replica.inventory:GetItems()) do
			TryApply(item)
		end
	end
end

local function TryApplyUpgradedDreadswordComponents(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= DREADSWORD_PREFAB then
		return false
	end
	if IsRevivalDreadsword(inst) or GetDreadswordUpgradeKey(inst) == "dreadsword_revival" then
		if not inst._nm_revival_parry_applied then
			AddRevivalParryComponents(inst)
			return true
		end
		return true
	end
	local variant_id = GetKinglyVariantId(inst) or inst._nm_kingly_variant
	if variant_id == nil then
		local key = GetDreadswordUpgradeKey(inst)
		if IsDreadswordUpgradeKey(key) then
			variant_id = string.sub(key, 12)
		end
	end
	if variant_id ~= nil and not inst._nm_kingly_applied then
		ApplyKinglyUpgrade(inst, variant_id)
		return true
	end
	return inst._nm_revival_parry_applied or inst._nm_kingly_applied
end

local function ScheduleUpgradedComponentCheck(inst)
	if inst._nm_upgrade_check_task ~= nil then
		return
	end
	local tries = 0
	inst._nm_upgrade_check_task = inst:DoPeriodicTask(0.25, function()
		tries = tries + 1
		if not inst:IsValid() then
			return
		end
		if TryApplyUpgradedDreadswordComponents(inst)
			or tries >= 40
			or not (IsRevivalDreadsword(inst) or IsKinglyDreadsword(inst)
				or IsDreadswordUpgradeKey(GetDreadswordUpgradeKey(inst))) then
			if inst._nm_upgrade_check_task ~= nil then
				inst._nm_upgrade_check_task:Cancel()
				inst._nm_upgrade_check_task = nil
			end
		end
	end)
end

local function TryOpenDreadswordParryTargeting(player)
	if TheWorld.ismastersim or player == nil then
		return false
	end
	local inventory = player.replica ~= nil and player.replica.inventory or nil
	if inventory == nil then
		return false
	end
	local item = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if item == nil or item.prefab ~= DREADSWORD_PREFAB or not IsParryDreadsword(item) then
		return false
	end
	if IsRevivalDreadsword(item) and not item._nm_revival_parry_applied then
		AddRevivalParryComponents(item)
	elseif IsKinglyDreadsword(item) and not item._nm_kingly_applied then
		local variant_id = GetKinglyVariantId(item) or item._nm_kingly_variant
		if variant_id ~= nil then
			ApplyKinglyUpgrade(item, variant_id)
		end
	end
	PatchDreadswordParryStartTargeting(item)
	if not IsDreadswordParryTargetingEnabled(item) then
		return false
	end
	local rider = player.replica.rider
	if rider ~= nil and rider:IsRiding()
		and item.components.aoetargeting ~= nil
		and not item.components.aoetargeting.allowriding then
		return false
	end
	return StartDreadswordParryTargeting(item, player)
end

local function PatchLocalPlayerParryControls(player)
	if player == nil or player ~= ThePlayer or player._nm_dreadsword_parry_controls_patched then
		return
	end
	if player.components.playercontroller == nil then
		return
	end
	player._nm_dreadsword_parry_controls_patched = true
	local pc = player.components.playercontroller
	local _TryAOETargeting = pc.TryAOETargeting
	pc.TryAOETargeting = function(self, ...)
		if TryOpenDreadswordParryTargeting(self.inst) then
			return true
		end
		return _TryAOETargeting(self, ...)
	end

	local _CancelAOETargeting = pc.CancelAOETargeting
	pc.CancelAOETargeting = function(self, ...)
		local inventory = self.inst.replica ~= nil and self.inst.replica.inventory or nil
		if inventory ~= nil then
			local item = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if item ~= nil and item.prefab == DREADSWORD_PREFAB and IsParryDreadsword(item) then
				StopDreadswordParryTargeting(item)
			end
		end
		local ok, ret = pcall(_CancelAOETargeting, self, ...)
		if ok then
			return ret
		end
	end

	local _HasAOETargeting = pc.HasAOETargeting
	pc.HasAOETargeting = function(self, ...)
		local inventory = self.inst.replica ~= nil and self.inst.replica.inventory or nil
		if inventory ~= nil then
			local item = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if item ~= nil and item.prefab == DREADSWORD_PREFAB and IsParryDreadsword(item)
				and IsDreadswordParryTargetingEnabled(item) then
				if item.components.aoetargeting ~= nil then
					local rider = self.inst.replica ~= nil and self.inst.replica.rider or nil
					if item.components.aoetargeting.allowriding
						or rider == nil
						or not rider:IsRiding() then
						return true
					end
				end
			end
		end
		return _HasAOETargeting(self, ...)
	end
end

AddPlayerPostInit(function(inst)
	if TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		if inst:IsValid() then
			PatchLocalPlayerParryControls(inst)
		end
	end)
end)

local function ClientRefreshRevivalParryReticule()
	local player = ThePlayer
	if player == nil or player.replica.inventory == nil then
		return
	end
	PatchLocalPlayerParryControls(player)
	ClientApplyUpgradedDreadswordFromPlayer(player)
	local weapon = player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if weapon ~= nil and weapon:HasTag(REVIVAL_TAG) and player.components.playercontroller ~= nil then
		PatchDreadswordParryStartTargeting(weapon)
		if IsDreadswordParryTargetingEnabled(weapon) then
			player.components.playercontroller:RefreshReticule(weapon)
		end
	end
end

AddClientModRPCHandler("my_mod", "dreadsword_revival_parry_sync", ClientRefreshRevivalParryReticule)

local function ClientRefreshKinglyParryReticule()
	local player = ThePlayer
	if player == nil or player.replica.inventory == nil then
		return
	end
	PatchLocalPlayerParryControls(player)
	ClientApplyUpgradedDreadswordFromPlayer(player)
	local weapon = player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if weapon ~= nil and weapon:HasTag("nm_kingly_parry") and player.components.playercontroller ~= nil then
		PatchDreadswordParryStartTargeting(weapon)
		if IsDreadswordParryTargetingEnabled(weapon) then
			player.components.playercontroller:RefreshReticule(weapon)
		end
	end
end

AddClientModRPCHandler("my_mod", "dreadsword_kingly_parry_sync", ClientRefreshKinglyParryReticule)

AddClientModRPCHandler("my_mod", "dreadsword_upgrade_sync", function(sword_guid, variant_id)
	ApplyDreadswordUpgradeOnClient(sword_guid, variant_id)
end)

local function TryAddDreadswordHorrorfuelRepairAction(inst, target, actions)
	if inst.prefab ~= HORRORFUEL_REPAIR_ITEM or target == nil or target.prefab ~= DREADSWORD_PREFAB then
		return false
	end
	if not IsUpgradedDreadswordForAction(target) or not DreadswordNeedsRepair(target) then
		return false
	end
	if not target:HasTag("trader") and not target:HasTag("alltrader") then
		SetupKinglyTrader(target)
	end
	if not target:HasTag("trader") and not target:HasTag("alltrader") then
		return false
	end
	table.insert(actions, ACTIONS.GIVE)
	return true
end

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if target == nil or target.prefab ~= DREADSWORD_PREFAB then
		return
	end
	if not target:HasTag("trader") and not target:HasTag("alltrader") then
		return
	end

	if inst.prefab == REVIVAL_UPGRADE_ITEM and not IsUpgradedDreadswordForAction(target) then
		table.insert(actions, ACTIONS.GIVE)
		return
	end

	if inst.prefab == UPGRADE_GEM and not IsUpgradedDreadswordForAction(target) and CanWilsonUpgradeDreadsword(doer) then
		table.insert(actions, ACTIONS.GIVE)
		return
	end

	TryAddDreadswordHorrorfuelRepairAction(inst, target, actions)
end, modname)

AddPrefabPostInit(DREADSWORD_PREFAB, function(inst)
	SetupKinglyEntityDisplayName(inst)
	ScheduleUpgradedComponentCheck(inst)

	if IsRevivalDreadsword(inst) or inst._nm_revival_parry_applied then
		AddRevivalParryComponents(inst)
		return
	end

	if IsKinglyDreadsword(inst) or inst._nm_kingly_applied then
		ApplyKinglyUpgrade(inst, GetKinglyVariantId(inst) or inst._nm_kingly_variant)
		return
	end

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, function()
			if inst:IsValid() and not IsUpgradedDreadswordForAction(inst) then
				SetupKinglyTrader(inst)
			end
			PatchLocalPlayerParryControls(ThePlayer)
			ClientRefreshRevivalParryReticule()
		end)
	else
		inst:DoTaskInTime(0, function()
			if inst:IsValid() and not IsUpgradedDreadsword(inst) then
				SetupKinglyTrader(inst)
			end
		end)
	end

	local old_onsave = inst.OnSave
	inst.OnSave = function(save_inst, data)
		if old_onsave ~= nil then
			old_onsave(save_inst, data)
		end
		if not TheWorld.ismastersim then
			return
		end
		if IsRevivalDreadsword(save_inst) then
			data.nm_dreadsword_revival = true
			return
		end
		local variant_id = GetKinglyVariantId(save_inst)
		if variant_id ~= nil then
			data.nm_dreadsword_kingly = variant_id
		end
	end

	local old_onload = inst.OnLoad
	inst.OnLoad = function(load_inst, data)
		if old_onload ~= nil then
			old_onload(load_inst, data)
		end
		if data ~= nil and data.nm_dreadsword_revival then
			AddRevivalParryComponents(load_inst)
			if not TheWorld.ismastersim then
				load_inst:DoTaskInTime(0, ClientRefreshRevivalParryReticule)
			end
			return
		end
		local variant_id = data ~= nil and data.nm_dreadsword_kingly or nil
		if variant_id ~= nil then
			ApplyKinglyUpgrade(load_inst, variant_id)
			if not TheWorld.ismastersim and variant_id == "parry" then
				load_inst:DoTaskInTime(0, ClientRefreshKinglyParryReticule)
			end
		end
	end
end)
