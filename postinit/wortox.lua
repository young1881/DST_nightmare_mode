local allowedplants = {
    carrot = true,
    potato = true,
    tomato = true,
}

local function AbleToAcceptTest(inst, item, giver, count)
    if inst.iscollapsed:value() then
        return false
    end

    if not allowedplants[item.prefab] then
        return false
    end

    if not giver:HasTag("player") then
        return false
    end

    local rabbitkingmanager = TheWorld.components.rabbitkingmanager
    if rabbitkingmanager == nil or not rabbitkingmanager:CanFeedCarrot(giver) then
        return false
    end

    return true
end

local function OnItemAccepted(inst, giver, item, count)
    if allowedplants[item.prefab] then
        local rabbitkingmanager = TheWorld.components.rabbitkingmanager
        if rabbitkingmanager then
            rabbitkingmanager:AddCarrotFromPlayer(giver, inst)
        end
    end
end

AddPrefabPostInit("rabbithole", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.trader ~= nil then
        local trader = inst.components.trader
        trader:SetAbleToAcceptTest(AbleToAcceptTest)
        trader:SetOnAccept(OnItemAccepted)
    end
end)

----------  沃托克斯：每实际造成 500 伤害，灵魂治疗周围 3 地皮内玩家 10 生命  ----------

local WORTOX_DAMAGE_HEAL_THRESHOLD = 500
local WORTOX_DAMAGE_HEAL_AMOUNT = 10
local WORTOX_DAMAGE_HEAL_RANGE = 3 * 4

local function WortoxSoulHealNearbyPlayers(wortox)
	if wortox == nil or not wortox:IsValid() then
		return
	end
	local x, y, z = wortox.Transform:GetWorldPosition()
	local rangesq = WORTOX_DAMAGE_HEAL_RANGE * WORTOX_DAMAGE_HEAL_RANGE
	for _, player in ipairs(AllPlayers) do
		if player ~= nil and player:IsValid()
			and player.components.health ~= nil
			and not player.components.health:IsDead()
			and not player:HasTag("playerghost")
			and player.entity:IsVisible()
			and player:GetDistanceSqToPoint(x, y, z) < rangesq then
			player.components.health:DoDelta(WORTOX_DAMAGE_HEAL_AMOUNT, nil, "wortox_soul")
			if player.components.combat ~= nil then
				local fx = SpawnPrefab("wortox_soul_heal_fx")
				if fx ~= nil then
					fx.entity:AddFollower():FollowSymbol(
						player.GUID,
						player.components.combat.hiteffectsymbol,
						0,
						-50,
						0
					)
					if fx.Setup ~= nil then
						fx:Setup(player)
					end
				end
			end
		end
	end
end

local function WortoxOnHitOtherEvent(wortox, data)
	if wortox == nil or not wortox:IsValid() or data == nil then
		return
	end
	-- 伤害转移、格挡等情况下 damageresolved 为 0，不计入
	if data.redirected ~= nil then
		return
	end
	local dealt = data.damageresolved
	if dealt == nil or type(dealt) ~= "number" or dealt <= 0 then
		return
	end
	-- damageresolved 为 health:DoDelta 返回值，已含物理+位面等全部实际扣血，勿再用 damage/spdamage 估算
	wortox._roge_wortox_damage_accum = (wortox._roge_wortox_damage_accum or 0) + dealt
	while wortox._roge_wortox_damage_accum >= WORTOX_DAMAGE_HEAL_THRESHOLD do
		wortox._roge_wortox_damage_accum = wortox._roge_wortox_damage_accum - WORTOX_DAMAGE_HEAL_THRESHOLD
		WortoxSoulHealNearbyPlayers(wortox)
	end
end

local function WortoxInstallDamageHealHook(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "wortox" then
		return
	end
	if inst._roge_wortox_damage_heal_hooked then
		return
	end
	inst._roge_wortox_damage_heal_hooked = true
	inst:ListenForEvent("onhitother", WortoxOnHitOtherEvent)
end

----------  无灵魂时仍可灵魂跳跃，每次消耗 10 生命  ----------

local WORTOX_SOULHOP_HEALTH_COST = 10

local function WortoxIsNotRiding(inst)
	local rider = inst.replica ~= nil and inst.replica.rider or nil
	return rider == nil or not rider:IsRiding()
end

local function WortoxGetSoulCount(inst)
	if inst.GetSouls ~= nil then
		local _, count = inst:GetSouls()
		return count or 0
	end
	if inst.replica ~= nil and inst.replica.inventory ~= nil then
		return inst.replica.inventory:Count("wortox_soul")
	end
	if inst.components.inventory ~= nil then
		return inst.components.inventory:Count("wortox_soul")
	end
	return 0
end

local function WortoxCanPayHealthForSoulhop(inst)
	if not WortoxIsNotRiding(inst) then
		return false
	end
	if inst.components.health ~= nil then
		local h = inst.components.health
		return not h:IsDead() and h.currenthealth > WORTOX_SOULHOP_HEALTH_COST
	end
	if inst.replica ~= nil and inst.replica.health ~= nil then
		local h = inst.replica.health
		return not h:IsDead() and h:GetCurrent() > WORTOX_SOULHOP_HEALTH_COST
	end
	return false
end

local function WortoxIsMapSoulhopContext(inst)
	if inst.checkingmapactions then
		return true
	end
	local buffaction = inst.GetBufferedAction ~= nil and inst:GetBufferedAction() or nil
	return buffaction ~= nil
		and buffaction.action ~= nil
		and ACTIONS.BLINK_MAP ~= nil
		and buffaction.action == ACTIONS.BLINK_MAP
end

local function RogeCanSoulhop(inst, souls)
	if WortoxIsMapSoulhopContext(inst) then
		return inst._roge_vanilla_CanSoulhop ~= nil and inst._roge_vanilla_CanSoulhop(inst, souls) or false
	end
	if inst._roge_vanilla_CanSoulhop ~= nil and inst._roge_vanilla_CanSoulhop(inst, souls) then
		return true
	end
	return WortoxCanPayHealthForSoulhop(inst)
end

local function RogeTryToPortalHop(inst, souls, consumeall)
	if inst._roge_vanilla_TryToPortalHop == nil then
		return false
	end
	if WortoxIsMapSoulhopContext(inst) then
		return inst._roge_vanilla_TryToPortalHop(inst, souls, consumeall)
	end
	souls = souls or 1
	if WortoxGetSoulCount(inst) >= souls then
		return inst._roge_vanilla_TryToPortalHop(inst, souls, consumeall)
	end
	if not WortoxCanPayHealthForSoulhop(inst) then
		return false
	end
	inst.components.health:DoDelta(-WORTOX_SOULHOP_HEALTH_COST, false, "wortox_soulhop")
	return true
end

local function WortoxInstallSoulhopHook(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "wortox" or inst._roge_soulhop_hooked then
		return
	end
	if inst.CanSoulhop == nil then
		return
	end
	inst._roge_soulhop_hooked = true
	inst._roge_vanilla_CanSoulhop = inst.CanSoulhop
	inst.CanSoulhop = RogeCanSoulhop
	if TheWorld.ismastersim and inst.TryToPortalHop ~= nil then
		inst._roge_vanilla_TryToPortalHop = inst.TryToPortalHop
		inst.TryToPortalHop = RogeTryToPortalHop
	end
end

AddPrefabPostInit("wortox", function(inst)
	inst:DoTaskInTime(0, WortoxInstallSoulhopHook)
	if TheWorld.ismastersim then
		inst:DoTaskInTime(0, WortoxInstallDamageHealHook)
	end
end)
