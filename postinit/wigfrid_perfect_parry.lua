-- 战斗圆盾精确格挡
-- 防御开始后 0.28 秒内格挡成功 → 僵直、反伤（角色倍率×攻击伤害×2，位面伤害×3）
-- 须先学习技能树「战斗圆盾」制作技能（wathgrithr_arsenal_shield_1）后，按 R 格挡
-- CD：精确格挡 3s / 普通格挡 8s / 未格挡 15s

local WATHGRITHR_SHIELD = "wathgrithr_shield"
local BATTLE_SHIELD_SKILL = "wathgrithr_arsenal_shield_1"

local PARRY_WINDOW = 0.28
local INVENTORY_PARRY_DURATION = 1
local PARRY_CAST_RANGE = 6.5

local WATHGRITHR_PARRY_REPAIR_AMOUNT = 20
local PARRY_CD_PERFECT = 3
local PARRY_CD_NORMAL = 8
local PARRY_CD_FAIL = 15

local PARRY_RPC_DEBOUNCE = 0.35

local PARRY_LINES = {
	wathgrithr = {
		"我完全看穿了你的行动！",
		"你就这点本事？",
		"还不够热身呢！",
		"下一招，可要看好了！",
	},
	default = { "精确格挡！" },
}

------------------------------------------------------------------------------------------------------------------------
-- 工具函数

local function IsMasterSim()
	return TheWorld ~= nil and TheWorld.ismastersim
end

local function HasBattleShieldSkill(player)
	if player == nil then
		return false
	end
	if player.components.skilltreeupdater ~= nil then
		return player.components.skilltreeupdater:IsActivated(BATTLE_SHIELD_SKILL)
	end
	if player.replica ~= nil and player.replica.skilltreeupdater ~= nil then
		return player.replica.skilltreeupdater:IsActivated(BATTLE_SHIELD_SKILL)
	end
	return false
end

local function HasShieldSkill(doer)
	return HasBattleShieldSkill(doer)
end

local function GetShieldSkillLevel(doer)
	if not HasShieldSkill(doer) then
		return 0, false, false
	end
	local updater = doer.components.skilltreeupdater
	return 1,
		updater:IsActivated("wathgrithr_arsenal_shield_2"),
		updater:IsActivated("wathgrithr_arsenal_shield_3")
end

local function CanPerfectParry(doer)
	return true
end

local function CanNormalParry(doer)
	return GetShieldSkillLevel(doer) > 0
end

local function ShouldApplySkillBonus(doer)
	return GetShieldSkillLevel(doer) > 0
end

local function GetParryLine(doer)
	if doer == nil then
		return PARRY_LINES.default[1]
	end
	local lines = PARRY_LINES[doer.prefab] or PARRY_LINES.default
	if #lines > 1 then
		return lines[math.random(#lines)]
	end
	return lines[1]
end

local function GetWathgrithrShieldBonusTuning()
	local skills = TUNING.SKILLS
	if skills == nil or skills.WATHGRITHR == nil then
		return nil
	end
	return skills.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE,
		skills.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_SCALE,
		skills.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_DURATION,
		skills.WATHGRITHR.SHIELD_PARRY_DURATION_MULT
end

local function ApplyPerfectParryOnAttacker(attacker, doer, weapon)
	if attacker == nil or not attacker:IsValid() then
		return
	end

	if attacker.sg ~= nil and attacker.sg:HasState("hit") then
		attacker.sg:GoToState("hit")
	else
		attacker:PushEvent("attacked", { attacker = doer, damage = 0, weapon = weapon })
	end

	if attacker.components.grogginess ~= nil then
		attacker.components.grogginess:AddGrogginess(1, 1)
	elseif attacker.components.sleeper ~= nil and not attacker.components.sleeper:IsAsleep() then
		attacker.components.sleeper:AddSleepiness(1, 1)
	else
		attacker:PushEvent("stunned", { source = doer })
	end
end

local function BeginParryWindow(doer, can_normal)
	if doer == nil or not doer:IsValid() then
		return
	end

	doer._nm_parry_window_active = true
	doer._nm_can_normal_parry = can_normal
	doer._nm_parry_block_count = 0

	if doer._nm_parry_window_task ~= nil then
		doer._nm_parry_window_task:Cancel()
	end
	doer._nm_parry_window_task = doer:DoTaskInTime(PARRY_WINDOW, function()
		if not doer:IsValid() then
			return
		end
		doer._nm_parry_window_active = false
		doer._nm_parry_window_task = nil
		if not doer._nm_can_normal_parry then
			doer:PushEvent("combat_parry_end")
		end
	end)
end

local function EndParryWindow(doer)
	if doer == nil or not doer:IsValid() then
		return
	end
	doer._nm_parry_window_active = false
	if doer._nm_parry_window_task ~= nil then
		doer._nm_parry_window_task:Cancel()
		doer._nm_parry_window_task = nil
	end
end

local function IsPerfectParryActive(doer)
	return doer ~= nil and doer._nm_parry_window_active == true
end

local function GetItemPrefab(item)
	if item == nil then
		return nil
	end
	if item.prefab ~= nil then
		return item.prefab
	end
	if item.inst ~= nil and item.inst.prefab ~= nil then
		return item.inst.prefab
	end
	return nil
end

local function FindBattleShield(doer)
	if doer == nil or doer.components.inventory == nil then
		return nil
	end

	local equipped = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if equipped ~= nil and GetItemPrefab(equipped) == WATHGRITHR_SHIELD then
		return equipped
	end

	return doer.components.inventory:FindItem(function(item)
		return item ~= nil and GetItemPrefab(item) == WATHGRITHR_SHIELD
	end)
end

local function EnsureShieldAoetargetingForCast(shield)
	if shield == nil or not shield:IsValid() then
		return
	end
	if shield.components.rechargeable ~= nil
		and shield.components.rechargeable:IsCharged()
		and shield.components.aoetargeting ~= nil
		and not shield.components.aoetargeting:IsEnabled() then
		shield.components.aoetargeting:SetEnabled(true)
	end
end

local function LockShieldSkillAfterCast(shield)
	if shield ~= nil and shield:IsValid() and shield.components.aoetargeting ~= nil then
		shield.components.aoetargeting:SetEnabled(false)
	end
end

local function BattleShieldIsEquippedInHands(shield)
	return shield ~= nil and shield:IsValid()
		and shield.components.equippable ~= nil
		and shield.components.equippable:IsEquipped()
end

local function SuppressOffhandShieldAoetargeting(shield)
	if shield == nil or not shield:IsValid() then
		return
	end
	if BattleShieldIsEquippedInHands(shield) then
		return
	end
	if shield.components.aoetargeting ~= nil then
		shield.components.aoetargeting:SetEnabled(false)
	end
end

local function SuppressAllInventoryBattleShields(owner)
	if owner == nil or owner.components.inventory == nil then
		return
	end
	local function suppress(item)
		if item ~= nil and GetItemPrefab(item) == WATHGRITHR_SHIELD then
			SuppressOffhandShieldAoetargeting(item)
		end
	end
	for _, item in pairs(owner.components.inventory.itemslots) do
		suppress(item)
	end
	local active = owner.components.inventory:GetActiveItem()
	if active ~= nil then
		suppress(active)
	end
end

local function DoRefreshWeaponSkillsAfterParry(doer)
	if doer == nil or not doer:IsValid() then
		return
	end
	SuppressAllInventoryBattleShields(doer)
	if doer.components.playercontroller ~= nil then
		doer.components.playercontroller:CancelAOETargeting()
	end
	if GLOBAL.NM_RefreshWigfridEquippedWeaponSkills ~= nil then
		GLOBAL.NM_RefreshWigfridEquippedWeaponSkills(doer)
	end
end

local function ApplyParryCooldown(shield, seconds)
	if shield == nil or not shield:IsValid() or shield.components.rechargeable == nil then
		return
	end
	shield.components.rechargeable:Discharge(seconds)
	SuppressOffhandShieldAoetargeting(shield)
	local owner = shield.components.inventoryitem ~= nil and shield.components.inventoryitem:GetGrandOwner() or nil
	if owner ~= nil and owner:IsValid() then
		DoRefreshWeaponSkillsAfterParry(owner)
	end
end

local function ResolveParryFailCooldown(doer, shield)
	if doer == nil or shield == nil or not shield:IsValid() then
		return
	end
	if (doer._nm_parry_block_count or 0) > 0 then
		return
	end
	ApplyParryCooldown(shield, PARRY_CD_FAIL)
end

local function IsInventoryParryShield(shield, doer)
	return shield ~= nil
		and shield.components.inventoryitem ~= nil
		and shield.components.inventoryitem:IsHeldBy(doer)
		and (shield.components.equippable == nil or not shield.components.equippable:IsEquipped())
end

local function ApplyInventoryParryShieldVisual(doer, shield)
	if doer == nil or not doer:IsValid() or shield == nil or not shield:IsValid() then
		return
	end
	if doer.AnimState == nil then
		return
	end

	doer._nm_inventory_parry_visual_active = true
	doer.AnimState:Show("ARM_carry")
	doer.AnimState:Hide("ARM_normal")
	doer.AnimState:Show("LANTERN_OVERLAY")
	doer.AnimState:HideSymbol("swap_object")

	local skin_build = shield:GetSkinBuild()
	if skin_build ~= nil then
		doer.AnimState:OverrideItemSkinSymbol(
			"lantern_overlay", skin_build, "swap_shield", shield.GUID, "swap_wathgrithr_shield")
		doer.AnimState:OverrideItemSkinSymbol(
			"swap_shield", skin_build, "swap_shield", shield.GUID, "swap_wathgrithr_shield")
	else
		doer.AnimState:OverrideSymbol("lantern_overlay", "swap_wathgrithr_shield", "swap_shield")
		doer.AnimState:OverrideSymbol("swap_shield", "swap_wathgrithr_shield", "swap_shield")
	end
end

local function ApplyHandItemVisualOnly(doer, hand_item)
	if doer == nil or not doer:IsValid() or doer.AnimState == nil then
		return
	end

	if hand_item == nil or not hand_item:IsValid() then
		doer.AnimState:Hide("ARM_carry")
		doer.AnimState:Show("ARM_normal")
		doer.AnimState:ShowSymbol("swap_object")
		return
	end

	doer.AnimState:Show("ARM_carry")
	doer.AnimState:Hide("ARM_normal")
	doer.AnimState:ShowSymbol("swap_object")
	doer.AnimState:ClearOverrideSymbol("swap_object")

	local swap_build = hand_item._swapbuild
	local swap_symbol = hand_item._swapsymbol
	if swap_build == nil or swap_symbol == nil then
		return
	end

	local skin_build = hand_item:GetSkinBuild()
	if skin_build ~= nil then
		doer.AnimState:OverrideItemSkinSymbol(
			"swap_object", skin_build, swap_symbol, hand_item.GUID, swap_build)
	else
		doer.AnimState:OverrideSymbol("swap_object", swap_build, swap_symbol)
	end
end

local function RestoreHandItemVisual(doer)
	if doer == nil or not doer:IsValid() or doer.AnimState == nil then
		return
	end

	local hand_item = doer.components.inventory ~= nil
		and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		or nil
	ApplyHandItemVisualOnly(doer, hand_item)
end

local function ClearInventoryParryShieldVisual(doer, shield)
	if doer == nil or not doer:IsValid() or not doer._nm_inventory_parry_visual_active then
		return
	end
	doer._nm_inventory_parry_visual_active = nil

	if doer.AnimState ~= nil then
		doer.AnimState:ClearOverrideSymbol("lantern_overlay")
		doer.AnimState:ClearOverrideSymbol("swap_shield")
		doer.AnimState:Hide("LANTERN_OVERLAY")
		RestoreHandItemVisual(doer)
	end
end

local function CancelDeferredInventoryParryRedirects(doer)
	if doer == nil then
		return
	end
	if doer._nm_inventory_parry_redirect_task1 ~= nil then
		doer._nm_inventory_parry_redirect_task1:Cancel()
		doer._nm_inventory_parry_redirect_task1 = nil
	end
	if doer._nm_inventory_parry_redirect_task2 ~= nil then
		doer._nm_inventory_parry_redirect_task2:Cancel()
		doer._nm_inventory_parry_redirect_task2 = nil
	end
end

local function RefreshWeaponSkillsAfterParry(doer)
	if doer == nil or not doer:IsValid() then
		return
	end
	DoRefreshWeaponSkillsAfterParry(doer)
	doer:DoTaskInTime(0, function()
		if doer:IsValid() then
			DoRefreshWeaponSkillsAfterParry(doer)
		end
	end)
	doer:DoTaskInTime(2 * FRAMES, function()
		if doer:IsValid() then
			DoRefreshWeaponSkillsAfterParry(doer)
		end
	end)
end

local function ClearInventoryParryState(doer)
	if doer == nil then
		return
	end
	if doer._nm_inventory_parry_visual_active then
		ClearInventoryParryShieldVisual(doer, doer._nm_parry_from_inventory)
	end
	doer._nm_parry_from_inventory = nil
end

local function FinishInventoryParrySession(doer)
	if doer == nil or not doer:IsValid() or doer._nm_parry_from_inventory == nil then
		return
	end
	local shield = doer._nm_parry_from_inventory
	ResolveParryFailCooldown(doer, shield)
	if doer._nm_inventory_parry_cleanup_task ~= nil then
		doer._nm_inventory_parry_cleanup_task:Cancel()
		doer._nm_inventory_parry_cleanup_task = nil
	end
	CancelDeferredInventoryParryRedirects(doer)
	if doer.components.combat ~= nil then
		doer.components.combat.redirectdamagefn = nil
	end
	EndParryWindow(doer)
	ClearInventoryParryState(doer)
	SuppressOffhandShieldAoetargeting(shield)
	RefreshWeaponSkillsAfterParry(doer)
end

local function RefreshInventoryParryShieldVisual(doer)
	if doer == nil or not doer:IsValid() then
		return
	end
	local shield = doer._nm_parry_from_inventory
	if shield == nil or not shield:IsValid() then
		return
	end
	ApplyInventoryParryShieldVisual(doer, shield)
end

local function SetupInventoryParryRedirect(doer, weapon)
	if doer == nil or not doer:IsValid() or weapon == nil or not weapon:IsValid() then
		return
	end
	if doer.components.combat == nil then
		return
	end

	doer._nm_parry_from_inventory = weapon
	doer.components.combat.redirectdamagefn = function(owner, attacker, damage, atk_weapon, stimuli, spdamage)
		if owner == nil or not owner:IsValid() or not weapon:IsValid() then
			return nil
		end
		if weapon.components.inventoryitem == nil or not weapon.components.inventoryitem:IsHeldBy(owner) then
			return nil
		end
		if weapon.components.parryweapon == nil then
			return nil
		end
		owner._nm_last_parry_spdamage = spdamage
		if weapon.components.parryweapon:TryParry(owner, attacker, damage, atk_weapon, stimuli, spdamage) then
			return weapon
		end
		return nil
	end
end

local INVENTORY_PARRY_STATES = {
	parry_idle = true,
	parry_hit = true,
	parry_knockback = true,
}

local function OnInventoryParryStateExit(inst, nextstate)
	if inst._nm_parry_from_inventory == nil then
		return
	end
	if nextstate ~= nil and INVENTORY_PARRY_STATES[nextstate] then
		local shield = inst._nm_parry_from_inventory
		if shield ~= nil and shield:IsValid() then
			SetupInventoryParryRedirect(inst, shield)
		end
		return
	end
	FinishInventoryParrySession(inst)
end

local function OnParryStateExit(inst, nextstate)
	OnInventoryParryStateExit(inst, nextstate)
	if inst._nm_parry_from_inventory == nil then
		if nextstate ~= nil and not INVENTORY_PARRY_STATES[nextstate] then
			if inst._nm_parry_shield_ref ~= nil then
				ResolveParryFailCooldown(inst, inst._nm_parry_shield_ref)
				inst._nm_parry_shield_ref = nil
			end
			RefreshWeaponSkillsAfterParry(inst)
		end
	end
end

local function GetMouseGroundPos(player, maxrange)
	if player == nil or TheInput == nil then
		return nil
	end

	local pos = nil
	if TheInput.GetWorldPosition ~= nil then
		pos = TheInput:GetWorldPosition()
	end
	if pos == nil and TheInput.GetHoverWorldPosition ~= nil then
		pos = TheInput:GetHoverWorldPosition()
	end
	if pos == nil and player.components.playercontroller ~= nil then
		if player.components.playercontroller.GetWorldPosition ~= nil then
			pos = player.components.playercontroller:GetWorldPosition()
		elseif player.components.playercontroller.GetRemotePredictPosition ~= nil then
			pos = player.components.playercontroller:GetRemotePredictPosition()
		end
	end

	local px, py, pz = player.Transform:GetWorldPosition()
	if pos == nil then
		local dist = maxrange * 0.6
		local rad = player.Transform:GetRotation() * DEGREES
		return Vector3(px + math.cos(rad) * dist, py, pz - math.sin(rad) * dist)
	end

	local dx, dz = pos.x - px, pos.z - pz
	local distsq = dx * dx + dz * dz
	local maxsq = maxrange * maxrange
	if distsq > maxsq and distsq > 0 then
		local scale = maxrange / math.sqrt(distsq)
		pos = Vector3(px + dx * scale, pos.y or py, pz + dz * scale)
	end
	if pos.y == nil then
		pos.y = py
	end
	return pos
end

local function ClampCastPos(doer, pos, maxrange)
	if doer == nil or pos == nil then
		return pos
	end
	local startpos = doer:GetPosition()
	local dx, dz = pos.x - startpos.x, pos.z - startpos.z
	local distsq = dx * dx + dz * dz
	local maxsq = maxrange * maxrange
	if distsq > maxsq and distsq > 0 then
		local scale = maxrange / math.sqrt(distsq)
		return Vector3(startpos.x + dx * scale, pos.y, startpos.z + dz * scale)
	end
	return pos
end

local function PlayPerfectParryFeedback(doer, inst)
	if doer.components.talker ~= nil then
		doer.components.talker:Say(GetParryLine(doer))
	end
	if doer.SoundEmitter ~= nil then
		doer.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
	end
	if inst ~= nil and inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
	end
end

local function ApplyParryReflectDamage(doer, attacker, damage, spdamage, weapon)
	if attacker == nil or not attacker:IsValid() or attacker.components.combat == nil then
		return
	end

	local physical = 0
	if damage ~= nil and damage > 0 and doer.components.combat ~= nil then
		local mult = doer.components.combat.damagemultiplier or 1
		physical = mult * damage * 2
	end

	local planar_spdamage = nil
	if spdamage ~= nil and spdamage.planar ~= nil and spdamage.planar > 0 then
		planar_spdamage = { planar = spdamage.planar * 3 }
	end

	if physical > 0 or planar_spdamage ~= nil then
		attacker.components.combat:GetAttacked(doer, physical, weapon, nil, planar_spdamage)
	end
end

local function HandlePerfectParrySuccess(inst, doer, attacker, damage, opts)
	if inst == nil or not inst:IsValid() or doer == nil or not doer:IsValid() then
		return
	end

	opts = opts or {}

	ApplyParryCooldown(inst, opts.cd or PARRY_CD_PERFECT)

	ApplyPerfectParryOnAttacker(attacker, doer, inst)

	if opts.repair_amount ~= nil and inst.components.armor ~= nil then
		inst.components.armor:Repair(opts.repair_amount)
	end

	ApplyParryReflectDamage(doer, attacker, damage, opts.spdamage, inst)

	PlayPerfectParryFeedback(doer, inst)
	doer._nm_parry_block_count = (doer._nm_parry_block_count or 0) + 1
	EndParryWindow(doer)
end

------------------------------------------------------------------------------------------------------------------------
-- 战斗圆盾：精确格挡 + R 键格挡（须先点击技能）

local function WathgrithrShieldOnParry(inst, doer, attacker, damage, old_onparry)
	if inst == nil or doer == nil or not doer:IsValid() then
		return
	end

	local spdamage = doer._nm_last_parry_spdamage
	doer._nm_last_parry_spdamage = nil

	if IsPerfectParryActive(doer) then
		HandlePerfectParrySuccess(inst, doer, attacker, damage, {
			repair_amount = WATHGRITHR_PARRY_REPAIR_AMOUNT,
			spdamage = spdamage,
			cd = PARRY_CD_PERFECT,
		})
		return
	end

	if old_onparry ~= nil then
		old_onparry(inst, doer, attacker, damage)
	end

	doer._nm_parry_block_count = (doer._nm_parry_block_count or 0) + 1
	ApplyParryCooldown(inst, PARRY_CD_NORMAL)
end

local function WathgrithrShieldSpellFn(inst, doer, pos)
	if inst == nil or not inst:IsValid() or doer == nil or not doer:IsValid() or pos == nil then
		return false
	end
	if inst.components.parryweapon == nil or inst.components.rechargeable == nil then
		return false
	end
	if not inst.components.rechargeable:IsCharged() then
		return false
	end
	if not HasBattleShieldSkill(doer) then
		return false
	end

	local _, has_duration = GetShieldSkillLevel(doer)
	local duration_mult = 1
	local base_duration = TUNING.WATHGRITHR_SHIELD_PARRY_DURATION
	if not CanNormalParry(doer) then
		base_duration = PARRY_WINDOW
	elseif ShouldApplySkillBonus(doer) and has_duration then
		local _, _, _, duration_skill_mult = GetWathgrithrShieldBonusTuning()
		duration_mult = duration_skill_mult or 2.5
	end

	inst.components.parryweapon:EnterParryState(
		doer,
		doer:GetAngleToPoint(pos),
		base_duration * duration_mult
	)
	LockShieldSkillAfterCast(inst)
	doer._nm_parry_shield_ref = inst
	BeginParryWindow(doer, CanNormalParry(doer))
	return true
end

AddPrefabPostInit(WATHGRITHR_SHIELD, function(inst)
	if not IsMasterSim() then
		return
	end
	if inst._nm_perfect_parry_patched then
		return
	end
	inst._nm_perfect_parry_patched = true

	if inst.components.aoespell ~= nil then
		inst.components.aoespell:SetSpellFn(WathgrithrShieldSpellFn)
	end

	if inst.components.parryweapon ~= nil then
		local old_onparry = inst.components.parryweapon.onparryfn
		local old_tryparry = inst.components.parryweapon.TryParry
		if old_tryparry ~= nil then
			inst.components.parryweapon.TryParry = function(self, doer, attacker, damage, weapon, stimuli, spdamage)
				if doer ~= nil then
					doer._nm_last_parry_spdamage = spdamage
				end
				return old_tryparry(self, doer, attacker, damage, weapon, stimuli, spdamage)
			end
		end
		inst.components.parryweapon:SetOnParryFn(function(shield, doer, attacker, damage)
			WathgrithrShieldOnParry(shield, doer, attacker, damage, old_onparry)
		end)
	end

	if inst.components.rechargeable ~= nil then
		local old_oncharged = inst.components.rechargeable.onchargedfn
		local old_ondischarged = inst.components.rechargeable.ondischargedfn
		inst.components.rechargeable:SetOnChargedFn(function(shield)
			if BattleShieldIsEquippedInHands(shield) then
				if old_oncharged ~= nil then
					old_oncharged(shield)
				end
			else
				SuppressOffhandShieldAoetargeting(shield)
			end
			local owner = shield.components.inventoryitem ~= nil and shield.components.inventoryitem:GetGrandOwner() or nil
			if owner ~= nil and owner:IsValid() then
				DoRefreshWeaponSkillsAfterParry(owner)
			end
		end)
		inst.components.rechargeable:SetOnDischargedFn(function(shield)
			if old_ondischarged ~= nil then
				old_ondischarged(shield)
			end
			SuppressOffhandShieldAoetargeting(shield)
			local owner = shield.components.inventoryitem ~= nil and shield.components.inventoryitem:GetGrandOwner() or nil
			if owner ~= nil and owner:IsValid() then
				DoRefreshWeaponSkillsAfterParry(owner)
			end
		end)
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 服务端：背包格挡（直接施法，不依赖装备与 BufferedAction）

local function StartInventoryParryAnimation(doer)
	if doer == nil or doer.sg == nil or not doer.sg:HasState("parry_idle") then
		return
	end

	doer:ClearBufferedAction()
	if doer.components.locomotor ~= nil then
		doer.components.locomotor:Stop()
	end

	doer.sg:GoToState("parry_idle", {
		duration = INVENTORY_PARRY_DURATION,
		isshield = true,
		pauseframes = 30,
	})
end

local function CastInventoryParryDirect(doer, shield, pos)
	if doer == nil or not doer:IsValid() or shield == nil or not shield:IsValid() or pos == nil then
		return false
	end
	if shield.components.parryweapon == nil or shield.components.rechargeable == nil then
		return false
	end
	if not shield.components.rechargeable:IsCharged() then
		return false
	end
	if not HasBattleShieldSkill(doer) then
		return false
	end
	if not IsInventoryParryShield(shield, doer) then
		return false
	end

	doer._nm_parry_from_inventory = shield
	local angle = doer:GetAngleToPoint(pos)
	doer.Transform:SetRotation(angle)

	CancelDeferredInventoryParryRedirects(doer)
	shield.components.parryweapon:EnterParryState(doer, angle, INVENTORY_PARRY_DURATION)
	LockShieldSkillAfterCast(shield)
	BeginParryWindow(doer, true)
	SetupInventoryParryRedirect(doer, shield)
	ApplyInventoryParryShieldVisual(doer, shield)
	StartInventoryParryAnimation(doer)

	-- 原版 parry_pre 会覆盖 redirect，延迟再写一次确保背包格挡生效
	doer._nm_inventory_parry_redirect_task1 = doer:DoTaskInTime(0, function()
		doer._nm_inventory_parry_redirect_task1 = nil
		if doer:IsValid() and doer._nm_parry_from_inventory ~= nil and doer._nm_parry_from_inventory:IsValid() then
			SetupInventoryParryRedirect(doer, doer._nm_parry_from_inventory)
		end
	end)
	doer._nm_inventory_parry_redirect_task2 = doer:DoTaskInTime(2 * FRAMES, function()
		doer._nm_inventory_parry_redirect_task2 = nil
		if doer:IsValid() and doer._nm_parry_from_inventory ~= nil and doer._nm_parry_from_inventory:IsValid() then
			SetupInventoryParryRedirect(doer, doer._nm_parry_from_inventory)
		end
	end)
	if doer._nm_inventory_parry_cleanup_task ~= nil then
		doer._nm_inventory_parry_cleanup_task:Cancel()
	end
	doer._nm_inventory_parry_cleanup_task = doer:DoTaskInTime(INVENTORY_PARRY_DURATION + 1, function()
		doer._nm_inventory_parry_cleanup_task = nil
		FinishInventoryParrySession(doer)
	end)
	return true
end

local function PatchParryStateForInventoryCleanup(sg, state_name)
	local state = sg.states[state_name]
	if state == nil or state._nm_inventory_cleanup_patch then
		return
	end
	state._nm_inventory_cleanup_patch = true

	local old_onexit = state.onexit
	state.onexit = function(inst, nextstate)
		if old_onexit ~= nil then
			old_onexit(inst, nextstate)
		end
		OnParryStateExit(inst, nextstate)
	end
end

local function PatchInventoryParryCleanupStates(sg)
	PatchParryStateForInventoryCleanup(sg, "parry_idle")
	PatchParryStateForInventoryCleanup(sg, "parry_hit")
	PatchParryStateForInventoryCleanup(sg, "parry_knockback")
end

local function PatchInventoryParryVisualStates(sg)
	local function WrapParryStateOnEnter(state_name)
		local state = sg.states[state_name]
		if state == nil or state._nm_inventory_parry_visual_patch then
			return
		end
		state._nm_inventory_parry_visual_patch = true

		local old_onenter = state.onenter
		state.onenter = function(inst, data)
			if old_onenter ~= nil then
				old_onenter(inst, data)
			end
			RefreshInventoryParryShieldVisual(inst)
		end
	end

	WrapParryStateOnEnter("parry_idle")
	WrapParryStateOnEnter("parry_hit")
	WrapParryStateOnEnter("parry_knockback")
end

local function ServerCastParryAt(doer, x, z)
	if not IsMasterSim() or doer == nil or not doer:IsValid() then
		return false
	end
	if doer.prefab ~= "wathgrithr" then
		return false
	end
	if doer.components.locomotor == nil or doer.components.inventory == nil then
		return false
	end
	if doer:HasTag("playerghost") or (doer.components.health ~= nil and doer.components.health:IsDead()) then
		return false
	end

	local shield = FindBattleShield(doer)
	if shield == nil or not shield:IsValid() then
		return false
	end
	if not HasBattleShieldSkill(doer) then
		return false
	end
	if shield.components.rechargeable ~= nil and not shield.components.rechargeable:IsCharged() then
		return false
	end

	x = tonumber(x)
	z = tonumber(z)
	if x == nil or z == nil then
		return false
	end

	local pos = Vector3(x, 0, z)
	if TheWorld.Map ~= nil and TheWorld.Map.GetHeightAtPoint ~= nil then
		pos.y = TheWorld.Map:GetHeightAtPoint(pos.x, pos.z) or doer:GetPosition().y
	else
		pos.y = doer:GetPosition().y
	end
	pos = ClampCastPos(doer, pos, PARRY_CAST_RANGE)

	if shield.components.equippable ~= nil and shield.components.equippable:IsEquipped() then
		EnsureShieldAoetargetingForCast(shield)
		local act = BufferedAction(doer, nil, ACTIONS.CASTAOE, shield, pos)
		if doer.components.locomotor:PushAction(act, true) then
			return true
		end
		LockShieldSkillAfterCast(shield)
		DoRefreshWeaponSkillsAfterParry(doer)
		return false
	end

	return CastInventoryParryDirect(doer, shield, pos)
end

local function PatchParryPreForInventoryParry(sg)
	local state = sg.states.parry_pre
	if state == nil or state._nm_inventory_parry_patch then
		return
	end
	state._nm_inventory_parry_patch = true

	local old_onenter = state.onenter
	state.onenter = function(inst)
		old_onenter(inst)
		if inst._nm_parry_from_inventory ~= nil and inst._nm_parry_from_inventory:IsValid() then
			SetupInventoryParryRedirect(inst, inst._nm_parry_from_inventory)
		end
	end
end

AddStategraphPostInit("wilson", PatchParryPreForInventoryParry)
AddStategraphPostInit("wilson_client", PatchParryPreForInventoryParry)
AddStategraphPostInit("wilson", PatchInventoryParryVisualStates)
AddStategraphPostInit("wilson_client", PatchInventoryParryVisualStates)
AddStategraphPostInit("wilson", PatchInventoryParryCleanupStates)
AddStategraphPostInit("wilson_client", PatchInventoryParryCleanupStates)

AddPrefabPostInit("wathgrithr", function(inst)
	if not IsMasterSim() then
		return
	end

	local function CleanupParryState(owner)
		if owner == nil or not owner:IsValid() then
			return
		end
		EndParryWindow(owner)
		FinishInventoryParrySession(owner)
	end

	inst:ListenForEvent("newstate", function(owner, data)
		if owner._nm_parry_from_inventory == nil or data == nil or data.statename == nil then
			return
		end
		if INVENTORY_PARRY_STATES[data.statename] then
			return
		end
		FinishInventoryParrySession(owner)
	end)

	inst:ListenForEvent("death", function(owner)
		CleanupParryState(owner)
	end)
	inst:ListenForEvent("ms_becameghost", function(owner)
		CleanupParryState(owner)
	end)

	inst:ListenForEvent("nm_inventory_parry_cast", function(owner, data)
		if data ~= nil and data.x ~= nil and data.z ~= nil then
			ServerCastParryAt(owner, data.x, data.z)
		end
	end)
end)

AddModRPCHandler("my_mod", "wigfrid_inventory_parry_cast", function(inst, x, z)
	if inst ~= nil and inst:IsValid() and inst.prefab == "wathgrithr"
		and tonumber(x) ~= nil and tonumber(z) ~= nil then
		inst:PushEvent("nm_inventory_parry_cast", { x = x, z = z })
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 客户端：R 键（须已学习战斗圆盾制作技能）

local function ClientFindBattleShield(player)
	if player == nil or player.replica.inventory == nil then
		return nil
	end
	local equipped = player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if equipped ~= nil and GetItemPrefab(equipped) == WATHGRITHR_SHIELD then
		return equipped
	end
	return player.replica.inventory:FindItem(function(item)
		return item ~= nil and GetItemPrefab(item) == WATHGRITHR_SHIELD
	end)
end

local function ClientShieldIsCharged(player)
	local shield = ClientFindBattleShield(player)
	if shield == nil then
		return false
	end
	if shield.replica ~= nil and shield.replica.rechargeable ~= nil then
		return shield.replica.rechargeable:IsCharged()
	end
	return true
end

local function TryShieldParryOnR()
	local player = ThePlayer
	if player == nil or player.prefab ~= "wathgrithr" then
		return
	end
	if TheInput ~= nil and TheInput:IsKeyDown(KEY_SHIFT) then
		return
	end
	if player:HasTag("playerghost") then
		return
	end
	if not HasBattleShieldSkill(player) then
		return
	end
	if ClientFindBattleShield(player) == nil then
		return
	end
	if not ClientShieldIsCharged(player) then
		if player.components.talker ~= nil then
			player.components.talker:Say("格挡尚未就绪")
		end
		return
	end

	if MOD_RPC["my_mod"] == nil or MOD_RPC["my_mod"]["wigfrid_inventory_parry_cast"] == nil then
		return
	end

	local t = GetTime()
	if player._nm_inventory_parry_rpc_sent ~= nil and t - player._nm_inventory_parry_rpc_sent < PARRY_RPC_DEBOUNCE then
		return
	end

	local pos = GetMouseGroundPos(player, PARRY_CAST_RANGE)
	if pos == nil or pos.x == nil or pos.z == nil then
		return
	end

	player._nm_inventory_parry_rpc_sent = t
	if player.components.playercontroller ~= nil then
		player.components.playercontroller:CancelAOETargeting()
	end
	if GLOBAL.NM_RefreshWigfridEquippedWeaponSkills ~= nil then
		GLOBAL.NM_RefreshWigfridEquippedWeaponSkills(player)
	end
	SendModRPCToServer(MOD_RPC["my_mod"]["wigfrid_inventory_parry_cast"], pos.x, pos.z)
end

function GLOBAL.NM_WigfridHandleShieldParryR()
	TryShieldParryOnR()
end

local function RegisterShieldParryKeyHandler()
	if TheInput == nil then
		return
	end
	if TheInput._nm_shield_parry_key_registered then
		return
	end
	TheInput._nm_shield_parry_key_registered = true
	TheInput:AddKeyDownHandler(KEY_R, function()
		if GLOBAL.NM_WigfridHandleShieldParryR ~= nil then
			GLOBAL.NM_WigfridHandleShieldParryR()
		end
	end)
end

AddSimPostInit(RegisterShieldParryKeyHandler)

-- 背包中的战斗圆盾永不启用 aoetargeting，避免抢占主武器右键准星
AddComponentPostInit("aoetargeting", function(self)
	local old_SetEnabled = self.SetEnabled
	self.SetEnabled = function(cmp, enabled)
		local inst = cmp.inst
		if enabled and inst ~= nil and inst.prefab == WATHGRITHR_SHIELD then
			if inst.components.equippable == nil or not inst.components.equippable:IsEquipped() then
				enabled = false
			end
		end
		return old_SetEnabled(cmp, enabled)
	end
end)

STRINGS.ACTIONS.CASTAOE.WATHGRITHR_SHIELD = "格挡"
