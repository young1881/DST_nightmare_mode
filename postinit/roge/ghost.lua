-- roge/ghost.lua

-- ====== 常量（作祟 / 韦伯） ======
ROGE_WEBBER_GHOST_CHECK_INTERVAL = 30
ROGE_HAUNT_PREMIUM_MIN_CYCLES = 3       -- 第4天起：premium Boss 作祟/附身
ROGE_HAUNT_PREMIUM_MIN_TIME = 0
ROGE_HAUNT_ROGE_SHADOWDRAGON_MIN_CYCLES = 2 -- 第3天起：roge 召唤的恐惧之龙附身
ROGE_HAUNT_ROGE_SHADOWDRAGON_MIN_TIME = 0
ROGE_HAUNT_LATE_PREMIUM_MIN_CYCLES = 5  -- 恐惧之龙、鱿鱼王：第6天黄昏
ROGE_HAUNT_LATE_PREMIUM_MIN_TIME = 0.5
ROGE_HAUNT_LATE_PREMIUM_PREFABS = {
	shadowdragon = true,
	king_squid = true,
}
ROGE_PREMIUM_PREFABS = {
	shadowdragon = true,
	shadoweyeturret = true,
	shadoweyeturret2 = true,
	king_squid = true,
	klaus = true,
	mutatedbearger = true,
	eyeofterror = true,
	twinofterror1 = true,
	twinofterror2 = true,
	dragonfly = true,
}
ROGE_WARG_HAUNT_BLOCK_PREFABS = {
	warg = true,
	mutatedwarg = true,
}

-- ====== 附身天数判定 ======
function IsPremiumHauntUnlocked()
	return RogeIsUnlockedAtCycleDusk(ROGE_HAUNT_PREMIUM_MIN_CYCLES, ROGE_HAUNT_PREMIUM_MIN_TIME)
end

function IsLatePremiumHauntUnlocked()
	return RogeIsUnlockedAtCycleDusk(ROGE_HAUNT_LATE_PREMIUM_MIN_CYCLES, ROGE_HAUNT_LATE_PREMIUM_MIN_TIME)
end

function IsRogeSummonedShadowdragonHauntUnlocked()
	return RogeIsUnlockedAtCycleDusk(ROGE_HAUNT_ROGE_SHADOWDRAGON_MIN_CYCLES, ROGE_HAUNT_ROGE_SHADOWDRAGON_MIN_TIME)
end

function RogeIsHauntDayUnlocked(inst)
	if inst == nil or not inst:IsValid() then
		return true
	end
	-- 骰子/控制池等 roge 召唤的恐惧之龙：第3天起可附身（野外自然刷新的仍为第6天黄昏）
	if inst.prefab == "shadowdragon" and inst._roge_summoned then
		return IsRogeSummonedShadowdragonHauntUnlocked()
	end
	if ROGE_HAUNT_LATE_PREMIUM_PREFABS[inst.prefab] then
		return IsLatePremiumHauntUnlocked()
	end
	if ROGE_PREMIUM_PREFABS[inst.prefab] then
		return IsPremiumHauntUnlocked()
	end
	return true
end

function IsWargHauntBlocked()
	return RogeGetClockDay() >= 4
end

-- 非韦伯玩家鬼魂作祟/附身权限（控制台同步，默认开启）
local ROGE_NON_WEBBER_HAUNT_DEFAULT = true

local function RogeGetNonWebberHauntLobbyOrDefault()
	local lobby_options = rawget(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS")
	if lobby_options ~= nil and lobby_options.non_webber_haunt_enabled ~= nil then
		return lobby_options.non_webber_haunt_enabled == true
	end
	return ROGE_NON_WEBBER_HAUNT_DEFAULT
end

function RogeNonWebberGhostHauntEnabled()
	if TheWorld ~= nil and TheWorld.net ~= nil
		and TheWorld.net._nightmare_non_webber_haunt_enabled ~= nil then
		return TheWorld.net._nightmare_non_webber_haunt_enabled:value()
	end
	return RogeGetNonWebberHauntLobbyOrDefault()
end

function RogeSetNonWebberGhostHauntEnabled(enabled)
	local lobby_options = rawget(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS")
	if lobby_options == nil then
		lobby_options = {}
		rawset(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS", lobby_options)
	end
	lobby_options.non_webber_haunt_enabled = enabled == true
	if TheWorld ~= nil and TheWorld.net ~= nil
		and TheWorld.net._nightmare_non_webber_haunt_enabled ~= nil then
		TheWorld.net._nightmare_non_webber_haunt_enabled:set(enabled == true)
	end
	return lobby_options.non_webber_haunt_enabled
end

AddPrefabPostInit("forest_network", function(inst)
	local created = inst._nightmare_non_webber_haunt_enabled == nil
	if created then
		inst._nightmare_non_webber_haunt_enabled = net_bool(
			inst.GUID,
			"nightmare_lobby_changes._non_webber_haunt_enabled",
			"nightmare_non_webber_haunt_dirty"
		)
	end
	if created and TheWorld ~= nil and TheWorld.ismastersim then
		inst._nightmare_non_webber_haunt_enabled:set(RogeGetNonWebberHauntLobbyOrDefault())
	end
end)

-- 控制台（需开启「允许作弊」且为管理员）：
-- c_nonwebberhaunt()        切换开关（聊天栏提示）
-- c_nonwebberhaunt(true)    允许附身
-- c_nonwebberhaunt(false)   禁止附身
GLOBAL.c_nonwebberhaunt = function(enabled)
	if TheWorld == nil or not TheWorld.ismastersim then
		print("[roge] c_nonwebberhaunt: mastersim only")
		return
	end
	local new_val
	if enabled == nil then
		new_val = not RogeNonWebberGhostHauntEnabled()
	else
		new_val = enabled == true
	end
	RogeSetNonWebberGhostHauntEnabled(new_val)
	local msg = new_val
		and string.char(229, 183, 178, 229, 188, 128, 229, 144, 175, 239, 188, 154, 229, 133, 129, 232, 174, 184, 233, 153, 132, 232, 186, 171)
		or string.char(229, 183, 178, 229, 133, 179, 233, 151, 173, 239, 188, 154, 231, 166, 129, 230, 173, 162, 233, 153, 132, 232, 186, 171)
	print("[roge] " .. msg)
	if TheNet ~= nil and TheNet.SystemMessage ~= nil then
		TheNet:SystemMessage(msg)
	end
	return new_val
end

-- 韦伯鬼魂始终可作祟/附身；其他玩家鬼魂由 RogeNonWebberGhostHauntEnabled 控制
function RogeCanGhostHauntOrPossess(doer)
	if doer == nil or not doer:IsValid() then
		return false
	end
	if doer:HasTag("playerghost") then
		if doer.prefab == "webber" then
			return true
		end
		return RogeNonWebberGhostHauntEnabled()
	end
	return true
end

-- ====== haunt ======
-- 第 4 天起可附身/作祟 premium Boss；恐惧之龙与鱿鱼王仍为第 6 天黄昏
function RogePatchHauntableEarlyBlock(h)
	if h == nil or h._roge_early_haunt_patched then
		return
	end
	h._roge_early_haunt_patched = true
	local oldDoHaunt = h.DoHaunt
	h.DoHaunt = function(self, doer, ...)
		if not RogeCanGhostHauntOrPossess(doer) then
			return
		end
		if not RogeIsHauntDayUnlocked(self.inst) then
			return
		end
		return oldDoHaunt(self, doer, ...)
	end
end

function RogePatchWargHauntBlock(h)
	if h == nil or h._roge_warg_haunt_patched then
		return
	end
	h._roge_warg_haunt_patched = true
	local oldDoHaunt = h.DoHaunt
	h.DoHaunt = function(self, doer, ...)
		if not RogeCanGhostHauntOrPossess(doer) then
			return
		end
		local inst = self.inst
		if inst ~= nil and ROGE_WARG_HAUNT_BLOCK_PREFABS[inst.prefab] and IsWargHauntBlocked() then
			return
		end
		return oldDoHaunt(self, doer, ...)
	end
end

hauntable_list = {
	"ruinsnightmare",
	"crawlinghorror",
	"terrorbeak",
	"shadowwaxwell",
	"shadowbishop",
	"shadowknight",
	"shadowrook",
	"worm_boss",
	"shadoweyeturret",
	"shadoweyeturret2",
	"king_squid",
	"klaus",
	"mutatedbearger",
	"eyeofterror",
	"twinofterror1",
	"twinofterror2",
	"dragonfly",
	"pigelitefighter1",
	"pigelitefighter2",
	"pigelitefighter3",
	"pigelitefighter4",
}

for _, prefab in ipairs(hauntable_list) do
    AddPrefabPostInit(prefab, function(inst)
        if not inst.components.hauntable then
            inst:AddComponent("hauntable")
        end
        local h = inst.components.hauntable
        if ROGE_PREMIUM_PREFABS[prefab] or prefab == "king_squid" then
            RogePatchHauntableEarlyBlock(h)
        end
        h:SetHauntValue(TUNING.HAUNT_MED)
        if prefab:find("^pigelitefighter") ~= nil then
            h.panicable = false
            h.cooldown = 0
            h.usefx = false
        end

        inst:AddTag("hauntable")
    end)
end

function RogeSetupStandardHauntable(inst)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() then
		return
	end
	if inst.components.hauntable == nil then
		inst:AddComponent("hauntable")
	end
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_MED)
	inst:AddTag("hauntable")
end

function RogeSetupPremiumHauntable(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.hauntable == nil then
		inst:AddComponent("hauntable")
	end
	RogePatchHauntableEarlyBlock(inst.components.hauntable)
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_MED)
	inst:AddTag("hauntable")
end

local function RogeBellLinksToBeefalo(bell, beefalo)
	if bell == nil or not bell:IsValid() or beefalo == nil or not beefalo:IsValid() then
		return false
	end
	if bell.GetBeefalo ~= nil then
		local linked = bell:GetBeefalo()
		return linked ~= nil and linked:IsValid() and linked == beefalo
	end
	if bell.components.leader ~= nil and bell.components.leader.followers[beefalo] then
		return true
	end
	return false
end

local function RogePlayerCarriesBondedBellForBeefalo(player, beefalo)
	if player == nil or not player:IsValid() or player.components.inventory == nil then
		return false
	end
	local items = player.components.inventory:FindItems(function(item)
		return item ~= nil and item:IsValid() and item:HasTag("bell")
			and RogeBellLinksToBeefalo(item, beefalo)
	end)
	return items ~= nil and #items > 0
end

function RogeBeefaloHasBeefBell(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "beefalo" then
		return false
	end
	if inst.GetBeefBellOwner ~= nil then
		local bell = inst:GetBeefBellOwner()
		if bell ~= nil and bell:IsValid() then
			return true
		end
	end
	local follower = inst.components.follower
	if follower == nil then
		return false
	end
	local leader = follower:GetLeader()
	if leader ~= nil and leader:IsValid() then
		if leader:HasTag("bell") and RogeBellLinksToBeefalo(leader, inst) then
			return true
		end
		if leader:HasTag("player") and RogePlayerCarriesBondedBellForBeefalo(leader, inst) then
			return true
		end
	end
	return false
end

function RogeEnsureBeefbellHauntSeal(inst)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() then
		return
	end
	if not RogeBeefaloHasBeefBell(inst) then
		if inst._roge_beefbell_haunt_period ~= nil then
			inst._roge_beefbell_haunt_period:Cancel()
			inst._roge_beefbell_haunt_period = nil
		end
		return
	end
	RogeSealBlockedHauntOnInst(inst)
	if inst._roge_beefbell_haunt_period == nil then
		inst._roge_beefbell_haunt_period = inst:DoPeriodicTask(0.5, function(i)
			if not i:IsValid() then
				return
			end
			if RogeBeefaloHasBeefBell(i) then
				RogeSealBlockedHauntOnInst(i)
			elseif i._roge_beefbell_haunt_period ~= nil then
				i._roge_beefbell_haunt_period:Cancel()
				i._roge_beefbell_haunt_period = nil
			end
		end)
	end
end

function RogeIsHauntBlocked(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if inst._roge_daywalker2_boss then
		return false
	end
	if RogeBeefaloHasBeefBell(inst) then
		return true
	end
	return ROGE_BLOCK_HAUNT_PREFABS[inst.prefab] == true
end

for prefab in pairs(ROGE_PREMIUM_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		RogeSetupPremiumHauntable(inst)
		inst:DoTaskInTime(0, RogeSetupPremiumHauntable)
	end)
end

AddPrefabPostInit("king_squid", function(inst)
	RogeSetupPremiumHauntable(inst)
	inst:DoTaskInTime(0, RogeSetupPremiumHauntable)
end)

for prefab in pairs(ROGE_WARG_HAUNT_BLOCK_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		if TheWorld == nil or not TheWorld.ismastersim then
			return
		end
		inst:DoTaskInTime(0, function(e)
			if e.components.hauntable ~= nil then
				RogePatchWargHauntBlock(e.components.hauntable)
			end
		end)
	end)
end

-- 禁止玩家鬼魂对上述实体作祟（阿比盖尔、暗影角斗士、暗影仆从、嗡嗡蜜蜂、沃比、伯尼各形态）
-- 原版作祟入口�?ACTIONS.HAUNT.fn -> hauntable:DoHaunt；仅改实�?DoHaunt 易被覆盖或错过时机，
-- 故同时：�?包装 Hauntable �?DoHaunt �?拦截 ACTIONS.HAUNT.fn（与 playercontroller 选目标逻辑一致）�?local ROGE_BLOCK_HAUNT_PREFABS = {
ROGE_BLOCK_HAUNT_PREFABS = {
	abigail = true,
	shadowprotector = true, -- 若模组使用此�?	shadowwaxwell = true, -- 原版暗影角斗�?随扈常用 prefab
	shadowwaxwell = true,
	shadowworker = true,
	beeguard = true,
	woby = true,
	wobysmall = true,
	wobybig = true,
	willow_ember = true, -- 薇洛余烬容器：仅检查，不可作祟/附身
	bernie_inactive = true,
	bernie_active = true,
	bernie_big = true,
	gelblob = true,
	shadowthrall_centipede_controller = true,
	minotaur = true,       -- 远古守卫者
	leechterror = true,    -- 远古守护者寄生暗影（不可作祟/附身）
	small_leechterror = true,
	shadow_leech = true,   -- 梦魇疯猪寄生暗影（不可作祟/附身）
	crabking_cannontower = true, -- 蟹骑士寄生加农炮塔（不可作祟/附身）
	daywalker = true,
	daywalker1 = true,
	daywalker2 = true,
	ancient_hulk = true,   -- 远古兵器
	-- 矮星、火球术不可作祟
	stafflight = true,
	constant_fire = true,
	constant_light = true,
	cs_fireball_projectile = true,
	emberlight = true,
	-- WX-78 扫描无人机、扫描成功物、月亮孢子、暗影仆从寄生帽不可作祟/附身
	wx78_scanner = true,
	wx78_scanner_succeeded = true,
	spore_moon = true,
	shadow_thrall_parasitehat = true,
}

for prefab in pairs({
	stafflight = true,
	constant_fire = true,
	constant_light = true,
	cs_fireball_projectile = true,
	emberlight = true,
	wx78_scanner = true,
	wx78_scanner_succeeded = true,
	spore_moon = true,
	shadow_thrall_parasitehat = true,
}) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		if inst.components.hauntable ~= nil then
			inst:RemoveComponent("hauntable")
		end
		inst:RemoveTag("hauntable")
	end)
end

function RogeBlockedHauntOnHaunt(inst, haunter)
	return false
end

function RogeSealBlockedHauntOnInst(inst)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() then
		return
	end
	if not RogeIsHauntBlocked(inst) then
		return
	end
	if inst.components.hauntable ~= nil then
		inst.components.hauntable.onhaunt = RogeBlockedHauntOnHaunt
	end
end

function RogeStartBlockedHauntPossessSeal(inst, max_ticks)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() then
		return
	end
	max_ticks = max_ticks or 8
	RogeSealBlockedHauntOnInst(inst)
	inst:DoTaskInTime(0, RogeSealBlockedHauntOnInst)
	inst:DoTaskInTime(FRAMES, RogeSealBlockedHauntOnInst)
	inst:DoTaskInTime(1, RogeSealBlockedHauntOnInst)
	if inst._roge_haunt_block_period ~= nil then
		inst._roge_haunt_block_period:Cancel()
		inst._roge_haunt_block_period = nil
	end
	local ticks = 0
	inst._roge_haunt_block_period = inst:DoPeriodicTask(0.5, function(i)
		RogeSealBlockedHauntOnInst(i)
		ticks = ticks + 1
		if ticks >= max_ticks and i._roge_haunt_block_period ~= nil then
			i._roge_haunt_block_period:Cancel()
			i._roge_haunt_block_period = nil
		end
	end)
end

for prefab in pairs({
	wobysmall = true,
	wobybig = true,
	willow_ember = true,
	shadow_leech = true,
}) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		RogeStartBlockedHauntPossessSeal(inst)
	end)
end

AddPrefabPostInit("beefalo", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst._roge_beefbell_haunt_hooked then
		return
	end
	inst._roge_beefbell_haunt_hooked = true
	local function on_bond_state_changed(i)
		i:DoTaskInTime(0, RogeEnsureBeefbellHauntSeal)
	end
	inst:ListenForEvent("stopfollowing", on_bond_state_changed)
	inst:ListenForEvent("leaderchanged", on_bond_state_changed)
	inst:DoTaskInTime(0, RogeEnsureBeefbellHauntSeal)
end)

function RogePatchHauntableClass(Hauntable)
	if Hauntable == nil or Hauntable.DoHaunt == nil or Hauntable._roge_DoHaunt_wrapped then
		return
	end
	local old_DoHaunt = Hauntable.DoHaunt
	Hauntable._roge_DoHaunt_wrapped = true
	function Hauntable:DoHaunt(doer)
		if not RogeCanGhostHauntOrPossess(doer) then
			return
		end
		local inst = self.inst
		if inst ~= nil and RogeIsHauntBlocked(inst) then
			return
		end
		if inst ~= nil and ROGE_WARG_HAUNT_BLOCK_PREFABS[inst.prefab] and IsWargHauntBlocked() then
			return
		end
		if inst ~= nil and inst._roge_pigelite_squad and RogePigelitePreHauntSeal ~= nil then
			RogePigelitePreHauntSeal(inst)
		end
		return old_DoHaunt(self, doer)
	end
	if Hauntable.SetOnHauntFn ~= nil and not Hauntable._roge_SetOnHauntFn_wrapped then
		Hauntable._roge_SetOnHauntFn_wrapped = true
		local old_SetOnHauntFn = Hauntable.SetOnHauntFn
		function Hauntable:SetOnHauntFn(fn)
			if self.inst ~= nil and RogeIsHauntBlocked(self.inst) then
				return old_SetOnHauntFn(self, RogeBlockedHauntOnHaunt)
			end
			return old_SetOnHauntFn(self, fn)
		end
	end
end

AddClassPostConstruct("components/hauntable", RogePatchHauntableClass)

local _roge_haunt_action_fn_old = nil
function RogeHookHauntAction()
	local A = GLOBAL.ACTIONS
	if A == nil or A.HAUNT == nil or A.HAUNT.fn == nil then
		return
	end
	if _roge_haunt_action_fn_old ~= nil then
		return
	end
	_roge_haunt_action_fn_old = A.HAUNT.fn
	A.HAUNT.fn = function(act)
		local doer = act.doer
		if doer ~= nil and not RogeCanGhostHauntOrPossess(doer) then
			return false
		end
		local t = act.target
		if t ~= nil and t:IsValid() and RogeIsHauntBlocked(t) then
			return false
		end
		if t ~= nil and t:IsValid()
			and (ROGE_PREMIUM_PREFABS[t.prefab] or t.prefab == "king_squid")
			and not RogeIsHauntDayUnlocked(t) then
			return false
		end
		if t ~= nil and t:IsValid() and ROGE_WARG_HAUNT_BLOCK_PREFABS[t.prefab]
			and IsWargHauntBlocked() then
			return false
		end
		if t ~= nil and t:IsValid() and t._roge_pigelite_squad and RogePigelitePreHauntSeal ~= nil then
			RogePigelitePreHauntSeal(t)
		end
		-- Possession 类 mod（如 Poss2）：同一生物已有「其他」玩家在附身时拒绝新的作祟附身
		if doer ~= nil and t ~= nil and t:IsValid() and doer:HasTag("playerghost") then
			local p2 = t.Poss2
			if p2 ~= nil and p2.Possessors ~= nil then
				local blocked = false
				for guid, possessor in pairs(p2.Possessors) do
					if guid ~= doer.GUID and possessor ~= nil and possessor:IsValid() then
						blocked = true
						break
					end
				end
				if blocked then
					if doer.components.talker ~= nil then
						doer.components.talker:Say("Already possessed by another player.")
					end
					return false
				end
			end
		end
		return _roge_haunt_action_fn_old(act)
	end
end

AddSimPostInit(function()
	RogeHookHauntAction()
	local ok, Hauntable = pcall(GLOBAL.require, "components/hauntable")
	if ok then
		RogePatchHauntableClass(Hauntable)
	end
end)

-- 客户端：未开启非韦伯作祟权限时，隐藏「作祟」选项；牛铃铛绑定的牛不可作祟/附身
AddComponentAction("SCENE", "hauntable", function(inst, doer, actions, right)
	if doer ~= nil and doer:HasTag("playerghost") and doer.prefab ~= "webber"
		and not RogeNonWebberGhostHauntEnabled() then
		RemoveByValue(actions, ACTIONS.HAUNT)
	end
	if inst.prefab == "beefalo" and RogeBeefaloHasBeefBell(inst) then
		RemoveByValue(actions, ACTIONS.HAUNT)
	end
end)


-- ====== ruinsnightmare ======
-- 修复潜伏梦魇在隐身夹击状态下解除附身后，服务端没有强制恢复可见状态，导致其他玩家看不见的问题。
function RogeRuinsNightmareIsAlive(inst)
    return inst ~= nil
        and inst:IsValid()
        and inst.components ~= nil
        and inst.components.health ~= nil
        and not inst.components.health:IsDead()
end

function RogeRuinsNightmareIsInvisibleState(inst)
    return inst ~= nil
        and inst.sg ~= nil
        and inst.sg:HasStateTag("invisible")
end

function RogeRuinsNightmareForceVisible(inst)
    if not RogeRuinsNightmareIsAlive(inst) then
        return
    end

    inst:Show()
    inst:RemoveTag("NOCLICK")

    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(true)
    end
end

function RogeRuinsNightmareWrapPoss2End(inst)
    local poss2 = inst.Poss2
    if poss2 == nil or poss2.EndFN == nil or poss2._roge_ruinsnightmare_end_wrapped then
        return
    end

    poss2._roge_ruinsnightmare_end_wrapped = true
    local old_end = poss2.EndFN

    poss2.EndFN = function(possessed, possessor, ...)
        local was_invisible = RogeRuinsNightmareIsInvisibleState(possessed)
        local ret = old_end(possessed, possessor, ...)

        if was_invisible and RogeRuinsNightmareIsAlive(possessed) then
            RogeRuinsNightmareForceVisible(possessed)
            if possessed.sg ~= nil then
                possessed.sg:GoToState("hit")
            end
        end

        return ret
    end
end


-- ====== death_penalty ======
-- ====== 死亡惩罚：每次死亡 +30% health.penalty（与原版复活/骨架惩罚同机制，自动存档） ======
-- 有效血下限 50%：penalty 上限 0.50，达上限后不再降低（原版默认 0.75）
TUNING.MAXIMUM_HEALTH_PENALTY = 0.50
ROGE_DEATH_HEALTH_PENALTY = 0.30
ROGE_MAX_HEALTH_PENALTY = TUNING.MAXIMUM_HEALTH_PENALTY

function RogeClampPlayerHealthPenalty(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	local health = inst.components.health
	if health == nil or health.disable_penalty then
		return
	end
	if health.penalty > ROGE_MAX_HEALTH_PENALTY then
		health:SetPenalty(ROGE_MAX_HEALTH_PENALTY)
	end
end

function RogeOnPlayerDeathHealthPenalty(inst, data)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() then
		return
	end
	if inst:HasTag("playerghost") then
		return
	end
	local health = inst.components.health
	if health == nil or health.disable_penalty then
		return
	end
	if health.penalty >= ROGE_MAX_HEALTH_PENALTY then
		return
	end
	health:DeltaPenalty(ROGE_DEATH_HEALTH_PENALTY)
end

AddPlayerPostInit(function(inst)
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, RogeClampPlayerHealthPenalty)
	inst:ListenForEvent("death", RogeOnPlayerDeathHealthPenalty)
end)

-- ====== webber_ghost ======
AddPrefabPostInit("ruinsnightmare", function(inst)
    if TheWorld == nil or not TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, RogeRuinsNightmareWrapPoss2End)
    inst:DoTaskInTime(FRAMES, RogeRuinsNightmareWrapPoss2End)
end)

--鬼魂移�?local MOD_GHOST_RUN_SPEED = 10
local MOD_GHOST_RUN_SPEED = 10
local MOD_GHOST_WALK_SPEED = TUNING.WILSON_WALK_SPEED * 2.0
ROGE_WEBBER_GHOST_SPEED_MULT = 1.5

local _jiaqiang_wrapped_ex_fns = {}

function IsRogeWebberGhost(inst)
    return inst ~= nil
        and inst:IsValid()
        and inst.prefab == "webber"
        and inst:HasTag("playerghost")
end

function IsRogeWebberGhostNightVisionTarget(inst)
    return inst ~= nil
        and inst:IsValid()
        and inst.prefab == "webber"
        and (inst:HasTag("playerghost")
            or inst.poss2_possessing == true
            or (inst.Poss2 ~= nil and inst.Poss2.Possessing ~= nil))
end

function ApplyGhostLocomotorSpeedFromGhostConfig(inst)
    if not IsRogeWebberGhost(inst) then
        return
    end
    local locomotor = inst.components and inst.components.locomotor or nil
    if locomotor == nil then
        return
    end
    locomotor:SetSlowMultiplier(1)
    locomotor.runspeed = MOD_GHOST_RUN_SPEED * ROGE_WEBBER_GHOST_SPEED_MULT
    locomotor.walkspeed = MOD_GHOST_WALK_SPEED * ROGE_WEBBER_GHOST_SPEED_MULT
end

function ApplyModGhostLocomotorSpeed(inst)
    if not IsRogeWebberGhost(inst) then
        return
    end
    ApplyGhostLocomotorSpeedFromGhostConfig(inst)
end

function BumpGhostLocomotorLater(inst)
    ApplyModGhostLocomotorSpeed(inst)
    local delays = { FRAMES, 3 * FRAMES, 8 * FRAMES, 0.35, 0.75 }
    for i = 1, #delays do
        inst:DoTaskInTime(delays[i], function()
            if inst:IsValid() then
                ApplyModGhostLocomotorSpeed(inst)
            end
        end)
    end
end

--神秘发光�?local GHOST_LIGHT_RADIUS = 18.0
local GHOST_LIGHT_RADIUS = 18.0
local GHOST_LIGHT_INTENSITY = 0.2
local GHOST_LIGHT_FALLOFF = 6.1
local GHOST_LIGHT_R, GHOST_LIGHT_G, GHOST_LIGHT_B = 170 / 255, 195 / 255, 235 / 255

function StopJiaqiangGhostLightWatch(inst)
    if inst._jiaqiang_ghostlight_task ~= nil then
        inst._jiaqiang_ghostlight_task:Cancel()
        inst._jiaqiang_ghostlight_task = nil
    end
end

function ApplyJiaqiangGhostLight(inst, full_reset)
    if inst == nil or not inst:IsValid() or not inst:HasTag("playerghost") or inst.Light == nil then
        return
    end
    if full_reset then
        inst.Light:Enable(false)
    end
    inst.Light:SetIntensity(GHOST_LIGHT_INTENSITY)
    inst.Light:SetRadius(GHOST_LIGHT_RADIUS)
    inst.Light:SetFalloff(GHOST_LIGHT_FALLOFF)
    inst.Light:SetColour(GHOST_LIGHT_R, GHOST_LIGHT_G, GHOST_LIGHT_B)
    inst.Light:Enable(true)
end

function StartJiaqiangGhostLightWatch(inst)
    StopJiaqiangGhostLightWatch(inst)
    if not inst:HasTag("playerghost") then
        return
    end
    inst._jiaqiang_ghostlight_task = inst:DoPeriodicTask(1.0, function()
        if not (inst:IsValid() and inst:HasTag("playerghost") and inst.Light ~= nil) then
            StopJiaqiangGhostLightWatch(inst)
            return
        end
        ApplyJiaqiangGhostLight(inst, false)
    end)
end

function BumpJiaqiangGhostLightLater(inst)
    ApplyJiaqiangGhostLight(inst, true)
    local delays = { FRAMES, 3 * FRAMES, 8 * FRAMES, 0.35, 0.75, 1.25 }
    for i = 1, #delays do
        inst:DoTaskInTime(delays[i], function()
            if inst:IsValid() and inst:HasTag("playerghost") then
                ApplyJiaqiangGhostLight(inst, false)
            end
        end)
    end
    StartJiaqiangGhostLightWatch(inst)
end

ROGE_WEBBER_GHOST_NIGHTVISION_PRIORITY = 10

function StopRogeWebberGhostNightVision(inst)
    if inst ~= nil and inst._roge_webber_ghost_nightvision_task ~= nil then
        inst._roge_webber_ghost_nightvision_task:Cancel()
        inst._roge_webber_ghost_nightvision_task = nil
    end
    if inst ~= nil and inst._jiaqiang_ghostlight_task ~= nil then
        inst._jiaqiang_ghostlight_task:Cancel()
        inst._jiaqiang_ghostlight_task = nil
    end
    local playervision = inst ~= nil and inst.components ~= nil and inst.components.playervision or nil
    if playervision ~= nil and inst._roge_webber_ghost_nightvision_active then
        playervision:PopForcedNightVision(inst)
    end
    if inst ~= nil then
        inst._roge_webber_ghost_nightvision_active = nil
    end
end

function ApplyRogeWebberGhostNightVision(inst)
    if not IsRogeWebberGhostNightVisionTarget(inst) then
        StopRogeWebberGhostNightVision(inst)
        return
    end
    if inst.Light ~= nil then
        inst.Light:Enable(false)
    end
    local playervision = inst.components ~= nil and inst.components.playervision or nil
    if playervision ~= nil then
        playervision:PushForcedNightVision(inst, ROGE_WEBBER_GHOST_NIGHTVISION_PRIORITY)
        playervision.islegitnightvision = true
        inst._roge_webber_ghost_nightvision_active = true
    end
end

StopJiaqiangGhostLightWatch = StopRogeWebberGhostNightVision
BumpJiaqiangGhostLightLater = function(inst)
    StopRogeWebberGhostNightVision(inst)
    ApplyRogeWebberGhostNightVision(inst)
    local delays = { FRAMES, 3 * FRAMES, 8 * FRAMES, 0.35, 0.75, 1.25 }
    for i = 1, #delays do
        inst:DoTaskInTime(delays[i], function()
            if inst:IsValid() then
                ApplyRogeWebberGhostNightVision(inst)
            end
        end)
    end
    if IsRogeWebberGhostNightVisionTarget(inst) then
        ApplyRogeWebberGhostNightVision(inst)
        inst._roge_webber_ghost_nightvision_task = inst:DoPeriodicTask(0.25, function()
            ApplyRogeWebberGhostNightVision(inst)
        end)
    end
end

function TryWrapConfigureGhostLocomotor(inst)
    local ex = inst.ex_fns
    if ex == nil or ex.ConfigureGhostLocomotor == nil then
        return false
    end
    if _jiaqiang_wrapped_ex_fns[ex] then
        return true
    end
    _jiaqiang_wrapped_ex_fns[ex] = true
    local old = ex.ConfigureGhostLocomotor
    ex.ConfigureGhostLocomotor = function(player)
        old(player)
        ApplyGhostLocomotorSpeedFromGhostConfig(player)
    end
    return true
end

function TryWrapSetGhostMode(inst)
    if inst.SetGhostMode == nil or inst._jiaqiang_setghostmode_wrapped then
        return
    end
    inst._jiaqiang_setghostmode_wrapped = true
    local old = inst.SetGhostMode
    inst.SetGhostMode = function(player, isghost, ...)
        old(player, isghost, ...)
        if isghost and player.prefab == "webber" then
            BumpGhostLocomotorLater(player)
            BumpJiaqiangGhostLightLater(player)
        elseif IsRogeWebberGhostNightVisionTarget(player) then
            BumpJiaqiangGhostLightLater(player)
        else
            StopJiaqiangGhostLightWatch(player)
        end
    end
end

function TryWrapPossessionNightVision(inst)
    if inst.SetPossessing ~= nil and not inst._roge_webber_setpossessing_nightvision_wrapped then
        inst._roge_webber_setpossessing_nightvision_wrapped = true
        local old_setpossessing = inst.SetPossessing
        inst.SetPossessing = function(player, state, ...)
            old_setpossessing(player, state, ...)
            if state and player.prefab == "webber" then
                BumpJiaqiangGhostLightLater(player)
            elseif player.prefab == "webber" and not player:HasTag("playerghost") then
                StopJiaqiangGhostLightWatch(player)
            end
        end
    end
    local playervision = inst.components ~= nil and inst.components.playervision or nil
    if playervision ~= nil and playervision.SetGhostVision ~= nil and not playervision._roge_webber_possession_nightvision_wrapped then
        playervision._roge_webber_possession_nightvision_wrapped = true
        local old_setghostvision = playervision.SetGhostVision
        playervision.SetGhostVision = function(self, enabled, ...)
            old_setghostvision(self, enabled, ...)
            local player = self.inst
            if IsRogeWebberGhostNightVisionTarget(player) then
                player:DoTaskInTime(0, function()
                    if player:IsValid() then
                        ApplyRogeWebberGhostNightVision(player)
                    end
                end)
            end
        end
    end
end

function SetupPlayerGhostSpeed(inst)
    inst:ListenForEvent("poss2_possessing_dirty", function()
        if IsRogeWebberGhostNightVisionTarget(inst) then
            BumpJiaqiangGhostLightLater(inst)
        elseif inst.prefab == "webber" and not inst:HasTag("playerghost") then
            StopJiaqiangGhostLightWatch(inst)
        end
    end)

    inst:ListenForEvent("ms_becameghost", function()
        if inst.prefab == "webber" then
            BumpGhostLocomotorLater(inst)
            BumpJiaqiangGhostLightLater(inst)
        else
            StopJiaqiangGhostLightWatch(inst)
        end
    end)
    inst:ListenForEvent("ms_respawnedfromghost", function()
        if IsRogeWebberGhostNightVisionTarget(inst) then
            BumpJiaqiangGhostLightLater(inst)
        else
            StopJiaqiangGhostLightWatch(inst)
        end
    end)

    local function try_once()
        TryWrapConfigureGhostLocomotor(inst)
        TryWrapSetGhostMode(inst)
        TryWrapPossessionNightVision(inst)
        if IsRogeWebberGhost(inst) then
            BumpGhostLocomotorLater(inst)
        end
        if IsRogeWebberGhostNightVisionTarget(inst) then
            BumpJiaqiangGhostLightLater(inst)
        else
            StopJiaqiangGhostLightWatch(inst)
        end
    end

    try_once()
    local attempts = 0
    local function retry()
        if not inst:IsValid() or attempts >= 25 then
            return
        end
        attempts = attempts + 1
        try_once()
        inst:DoTaskInTime(0, retry)
    end
    inst:DoTaskInTime(0, retry)
end

AddPlayerPostInit(function(inst)
    SetupPlayerGhostSpeed(inst)
end)


-- ====== waxwell ======
-- 麦斯威尔：暗影秘典牢笼/陷阱需投入 2 个勇者证明解锁；之后每多 1 个证明 +1.5 秒控制
ROGE_WAXWELL_SHADOW_TRAP_COIN_COST = 2
ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION = 5
ROGE_WAXWELL_SHADOW_TRAP_DURATION_PER_EXTRA_COIN = 1.5
ROGE_WAXWELL_SHADOW_TRAP_BLOCK_SAY = "我需要更多勇者的证明，才能驾驭牢笼与陷阱。"
ROGE_WAXWELL_SHADOW_TRAP_SAY_COOLDOWN = 4
ROGE_WAXWELL_JOURNAL_SHADOW_TRAP_SPELL_INDEX = 3

ROGE_SHADOW_TRAP_LABELS = {
	["暗影囚笼"] = true,
	["暗影囚牢"] = true,
	["暗影牢笼"] = true,
	["暗影陷阱"] = true,
}

function RogeWaxwellGetShadowTrapCoinProgress(doer)
	if doer == nil or doer.prefab ~= "waxwell" then
		return 0
	end
	return doer._roge_waxwell_shadow_trap_coins or 0
end

function RogeWaxwellHasShadowTrapUnlocked(doer)
	return RogeWaxwellGetShadowTrapCoinProgress(doer) >= ROGE_WAXWELL_SHADOW_TRAP_COIN_COST
end

function RogeWaxwellGetShadowTrapDuration(doer)
	if doer == nil or doer.prefab ~= "waxwell" then
		return ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
	end
	local coins = RogeWaxwellGetShadowTrapCoinProgress(doer)
	if coins < ROGE_WAXWELL_SHADOW_TRAP_COIN_COST then
		return ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
	end
	local extra = coins - ROGE_WAXWELL_SHADOW_TRAP_COIN_COST
	return ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION + extra * ROGE_WAXWELL_SHADOW_TRAP_DURATION_PER_EXTRA_COIN
end

function RogeWaxwellGetShadowTrapHitDuration(total_duration)
	local total = total_duration or ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
	return total / 5
end

function RogeWaxwellJournalIsShadowCageOrTrap(book_inst, doer)
	if RogeWaxwellJournalIsShadowTrap(book_inst, doer) then
		return true
	end
	if book_inst == nil or book_inst.prefab ~= "waxwelljournal" then
		return false
	end
	local sb = book_inst.components.spellbook
	if sb == nil then
		return false
	end
	local name = sb:GetSpellName()
	return name ~= nil and STRINGS ~= nil and STRINGS.SPELLS ~= nil and name == STRINGS.SPELLS.SHADOW_PILLARS
end

function RogeWaxwellShadowTrapTrySay(doer)
	if doer == nil or doer.components.talker == nil then
		return
	end
	local now = GetTime()
	if doer._roge_shadow_trap_block_say_time == nil
		or now - doer._roge_shadow_trap_block_say_time >= ROGE_WAXWELL_SHADOW_TRAP_SAY_COOLDOWN then
		doer._roge_shadow_trap_block_say_time = now
		doer.components.talker:Say(ROGE_WAXWELL_SHADOW_TRAP_BLOCK_SAY)
	end
end

function RogeWaxwellJournalIsShadowTrap(book_inst, doer)
	if book_inst == nil or not book_inst:IsValid() or book_inst.prefab ~= "waxwelljournal" then
		return false
	end
	if doer == nil or not doer:IsValid() or doer.prefab ~= "waxwell" then
		return false
	end
	local at = book_inst.components.aoetargeting
	if at ~= nil and at.deployradius == 1 then
		return true
	end
	local sb = book_inst.components.spellbook
	if sb == nil then
		return false
	end
	local name = sb:GetSpellName()
	if name ~= nil then
		if ROGE_SHADOW_TRAP_LABELS[name] then
			return true
		end
		if STRINGS ~= nil and STRINGS.SPELLS ~= nil and STRINGS.SPELLS.SHADOW_TRAP ~= nil and name == STRINGS.SPELLS.SHADOW_TRAP then
			return true
		end
	end
	return sb:GetSelectedSpell() == ROGE_WAXWELL_JOURNAL_SHADOW_TRAP_SPELL_INDEX
end

AddComponentPostInit("aoespell", function(self)
	local inst = self.inst
	if inst == nil or inst.prefab ~= "waxwelljournal" then
		return
	end
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if self._roge_waxwell_shadow_trap_hooked then
		return
	end
	self._roge_waxwell_shadow_trap_hooked = true

	local old_cast = self.CastSpell
	self.CastSpell = function(cmp, doer, pos)
		if RogeWaxwellJournalIsShadowCageOrTrap(cmp.inst, doer) and not RogeWaxwellHasShadowTrapUnlocked(doer) then
			RogeWaxwellShadowTrapTrySay(doer)
			return false
		end
		return old_cast(cmp, doer, pos)
	end

	local old_can = self.CanCast
	self.CanCast = function(cmp, doer, pos)
		if RogeWaxwellJournalIsShadowCageOrTrap(cmp.inst, doer) and not RogeWaxwellHasShadowTrapUnlocked(doer) then
			return false
		end
		return old_can(cmp, doer, pos)
	end
end)

AddSimPostInit(function()
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if ACTIONS == nil or ACTIONS.CASTAOE == nil or ACTIONS.CASTAOE.fn == nil then
		return
	end
	if ACTIONS.CASTAOE._roge_waxwell_shadow_trap_fn then
		return
	end
	local old_fn = ACTIONS.CASTAOE.fn
	ACTIONS.CASTAOE._roge_waxwell_shadow_trap_fn = true
	ACTIONS.CASTAOE.fn = function(act)
		local inv = act.invobject
		local doer = act.doer
		if inv ~= nil and doer ~= nil and RogeWaxwellJournalIsShadowCageOrTrap(inv, doer)
			and not RogeWaxwellHasShadowTrapUnlocked(doer) then
			RogeWaxwellShadowTrapTrySay(doer)
			return false
		end
		return old_fn(act)
	end
end)


-- ====== webber_permanent_ghost ======
-- Rule target: only Webber is forced into permanent ghost mode.
function IsRogeWebber(inst)
    return inst ~= nil and inst:IsValid() and inst.prefab == "webber"
end

-- Convert Webber into a ghost without requesting skeleton creation.
function MakeRogeWebberGhost(inst)
    if TheWorld == nil then
        return
    end
    if not TheWorld.ismastersim then
        return
    end
    if not IsRogeWebber(inst) then
        return
    end
    if inst:HasTag("playerghost") then
        return
    end

    inst.skeleton_prefab = nil
    inst:PushEvent("makeplayerghost", { loading = true, roge_webber_permanent_ghost = true })
end

-- Install permanent ghost rules:
-- block standard revive events and keep a low-frequency fallback check.
function SetupRogeWebberPermanentGhost(inst)

    if TheWorld == nil then
        return
    end
    if not TheWorld.ismastersim then
        return
    end
    if not IsRogeWebber(inst) then
        return
    end

    inst.skeleton_prefab = nil
    inst:AddTag("roge_webber_permanent_ghost")

    if not inst._roge_webber_block_revive_push_wrapped then
        inst._roge_webber_block_revive_push_wrapped = true
        local old_push_event = inst.PushEvent
        inst.PushEvent = function(player, event, data, ...)
            if event == "respawnfromghost" or event == "respawnfromcorpse" then
                return
            end
            return old_push_event(player, event, data, ...)
        end
    end

    inst:ListenForEvent("ms_respawnedfromghost", function()
        inst:DoTaskInTime(0, MakeRogeWebberGhost)
    end)

    inst:DoTaskInTime(2, MakeRogeWebberGhost)
    inst:DoTaskInTime(5, MakeRogeWebberGhost)

    if inst._roge_webber_permanent_ghost_task == nil then
        inst._roge_webber_permanent_ghost_task =
            inst:DoPeriodicTask(ROGE_WEBBER_GHOST_CHECK_INTERVAL, MakeRogeWebberGhost)
    end
end

-- Player init entry point.
AddPlayerPostInit(SetupRogeWebberPermanentGhost)
--
