TUNING.SHADOWWAXWELL_SHADOWSTRIKE_DAMAGE_MULT = 2.6 --暗影角斗士冲刺伤害倍率

-- 暗影突袭（影袭）：对非玩家生物累计有效命中 HITS_REQUIRED 次触发；伤害为当前武器物理 × DAMAGE_MULT、位面 × PLANAR_DAMAGE_MULT
TUNING.THE_FORGE_ITEM_PACK = TUNING.THE_FORGE_ITEM_PACK or {}
TUNING.THE_FORGE_ITEM_PACK.SHADOWS = TUNING.THE_FORGE_ITEM_PACK.SHADOWS or {}
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.MAX_SHADOW_SPAWN = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.MAX_SHADOW_SPAWN or 6
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.HITS_REQUIRED = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.HITS_REQUIRED or 4
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.DAMAGE_MULT = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.DAMAGE_MULT or 1.0
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.PLANAR_DAMAGE_MULT = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.PLANAR_DAMAGE_MULT or 1.5
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT or 0.2
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FAIL_ANNOUNCE = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FAIL_ANNOUNCE
	or "我的暗影力量正在流失..."
TUNING.THE_FORGE_ITEM_PACK.SHADOWS.LUNGE_SPEED = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.LUNGE_SPEED or 30

-- 暗影牢笼/陷阱：基础 5 秒；受击后缩短为总时长的 1/5（2 证明时挨打为 1 秒）
local function RogeShadowTrapResolveDuration(target)
	if target == nil then
		return ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
	end
	if target._roge_shadow_trap_total_duration ~= nil then
		return target._roge_shadow_trap_total_duration
	end
	local x, y, z = target.Transform:GetWorldPosition()
	for _, ent in ipairs(TheSim:FindEntities(x, y, z, 8)) do
		if ent.prefab == "shadow_trap" and ent._roge_shadow_trap_total_duration ~= nil then
			target._roge_shadow_trap_total_duration = ent._roge_shadow_trap_total_duration
			return ent._roge_shadow_trap_total_duration
		end
		if ent.prefab == "shadow_pillar_spell" then
			if ent._roge_shadow_trap_total_duration ~= nil then
				target._roge_shadow_trap_total_duration = ent._roge_shadow_trap_total_duration
				return ent._roge_shadow_trap_total_duration
			end
			if ent.caster ~= nil and ent.caster:IsValid() and ent.caster.prefab == "waxwell" then
				local dur = RogeWaxwellGetShadowTrapDuration(ent.caster)
				target._roge_shadow_trap_total_duration = dur
				return dur
			end
		end
	end
	return ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
end

local function RogeShadowTrapHitDurationForTarget(target)
	return RogeWaxwellGetShadowTrapHitDuration(RogeShadowTrapResolveDuration(target))
end

TUNING.SHADOW_TRAP_PANIC_TIME = ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
TUNING.SHADOW_TRAP_NIGHTMARE_TIME = ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
TUNING.SHADOW_PILLAR_DURATION = ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
TUNING.SHADOW_PILLAR_DURATION_BOSS = ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
TUNING.SHADOW_PILLAR_DURATION_PLAYER = ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION

local function RogeShadowTrapClearAttackListener(target)
	if target._roge_shadow_trap_attack_fn ~= nil then
		target:RemoveEventCallback("attacked", target._roge_shadow_trap_attack_fn)
		target._roge_shadow_trap_attack_fn = nil
	end
end

local function RogeShadowTrapEndDebuff(target)
	RogeShadowTrapClearAttackListener(target)
	target._shadow_trap_task = nil
	if target._shadow_trap_fx ~= nil then
		target._shadow_trap_fx:KillFX()
		target._shadow_trap_fx = nil
	end
	if target.components.locomotor ~= nil then
		target.components.locomotor:RemoveExternalSpeedMultiplier(target, "shadow_trap")
	end
end

local function RogeShadowTrapSetDuration(target, duration)
	if target._shadow_trap_task ~= nil then
		target._shadow_trap_task:Cancel()
	end
	target._shadow_trap_task = target:DoTaskInTime(duration, RogeShadowTrapEndDebuff)
	if target.components.hauntable ~= nil and target.components.hauntable.panic then
		target.components.hauntable.panictimer = duration
		target.components.hauntable.cooldowntimer = math.max(target.components.hauntable.cooldowntimer or 0, duration)
	end
end

local function RogeShadowTrapSetupAttackListener(target)
	if target._roge_shadow_trap_attack_fn ~= nil then
		return
	end
	target._roge_shadow_trap_attack_fn = function(t, data)
		if t._shadow_trap_task == nil then
			return
		end
		if data ~= nil and data.damage ~= nil and data.damage > 0 then
			RogeShadowTrapSetDuration(t, RogeShadowTrapHitDurationForTarget(t))
		end
	end
	target:ListenForEvent("attacked", target._roge_shadow_trap_attack_fn)
end

local function RogeShadowTrapOnShortNightmareState(inst, data)
	if data == nil or data.duration == nil then
		return
	end
	if data.duration > RogeShadowTrapResolveDuration(inst) + 1 then
		return
	end
	if inst._roge_shadow_trap_nightmare_attack_fn ~= nil then
		return
	end
	inst._roge_shadow_trap_nightmare_attack_fn = function(t, adata)
		if adata == nil or adata.damage == nil or adata.damage <= 0 then
			return
		end
		if t.components.timer ~= nil and t.components.timer:TimerExists("forcenightmare") then
			t.components.timer:SetTimeLeft("forcenightmare", RogeShadowTrapHitDurationForTarget(t))
		end
	end
	inst:ListenForEvent("attacked", inst._roge_shadow_trap_nightmare_attack_fn)
end

AddComponentPostInit("locomotor", function(self)
	local old_set = self.SetExternalSpeedMultiplier
	function self:SetExternalSpeedMultiplier(source, key, m, ...)
		local ret = old_set(self, source, key, m, ...)
		if key == "shadow_trap" and self.inst ~= nil and TheWorld ~= nil and TheWorld.ismastersim then
			local dur = RogeShadowTrapResolveDuration(self.inst)
			self.inst._roge_shadow_trap_total_duration = dur
			RogeShadowTrapSetDuration(self.inst, dur)
			RogeShadowTrapSetupAttackListener(self.inst)
		end
		return ret
	end
end)

AddPrefabPostInit("shadow_pillar_target", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local old_settarget = inst.SetTarget
	inst.SetTarget = function(pillar_inst, target, radius, hasplatform)
		old_settarget(pillar_inst, target, radius, hasplatform)
		if target == nil or not target:IsValid() then
			return
		end
		local dur = RogeShadowTrapResolveDuration(target)
		target._roge_shadow_trap_total_duration = dur
		pillar_inst._roge_shadow_trap_total_duration = dur
		if pillar_inst._roge_shadow_pillar_hit_wrapped then
			return
		end
		pillar_inst._roge_shadow_pillar_hit_wrapped = true
		local function on_damage_hit(t, data)
			if data == nil or data.damage == nil or data.damage <= 0 then
				return
			end
			if pillar_inst.components.timer ~= nil and pillar_inst.components.timer:TimerExists("lifetime") then
				pillar_inst.components.timer:SetTimeLeft("lifetime", RogeShadowTrapHitDurationForTarget(target))
			end
		end
		pillar_inst:ListenForEvent("attacked", on_damage_hit, target)
		pillar_inst:ListenForEvent("blocked", on_damage_hit, target)
	end

	if inst.components.timer ~= nil and not inst._roge_shadow_pillar_timer_wrapped then
		inst._roge_shadow_pillar_timer_wrapped = true
		local old_start = inst.components.timer.StartTimer
		inst.components.timer.StartTimer = function(timer, name, time, ...)
			if name == "lifetime" and inst._roge_shadow_trap_total_duration ~= nil then
				time = inst._roge_shadow_trap_total_duration
			end
			return old_start(timer, name, time, ...)
		end
	end
end)

AddPrefabPostInit("shadow_trap", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		local old_trigger = inst.TriggerTrap
		if old_trigger == nil then
			return
		end
		inst.TriggerTrap = function(trap)
			local trap_dur = trap._roge_shadow_trap_total_duration or ROGE_WAXWELL_SHADOW_TRAP_BASE_DURATION
			local old_panic = TUNING.SHADOW_TRAP_PANIC_TIME
			local old_nightmare = TUNING.SHADOW_TRAP_NIGHTMARE_TIME
			TUNING.SHADOW_TRAP_PANIC_TIME = trap_dur
			TUNING.SHADOW_TRAP_NIGHTMARE_TIME = trap_dur
			old_trigger(trap)
			TUNING.SHADOW_TRAP_PANIC_TIME = old_panic
			TUNING.SHADOW_TRAP_NIGHTMARE_TIME = old_nightmare
		end
	end)
end)

for _, prefab in ipairs({ "rabbit", "bunnyman", "monkey" }) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:ListenForEvent("ms_forcenightmarestate", RogeShadowTrapOnShortNightmareState)
	end)
end

---暗影点数：仅影响仆从回血幅度（影袭伤害按当前武器 × 倍率计算）
local function GetEquipped(inst, slot)
	local inv = inst.components.inventory
	if inv ~= nil then
		local it = inv:GetEquippedItem(slot)
		if it ~= nil then
			return it
		end
	end
	local rep = inst.replica ~= nil and inst.replica.inventory or nil
	if rep ~= nil then
		return rep:GetEquippedItem(slot)
	end
	return nil
end

local function GetShadowPoint(inst)
	local Point = 0
	local A1 = GetEquipped(inst, EQUIPSLOTS.HANDS)
	local A2 = GetEquipped(inst, EQUIPSLOTS.BODY)
	local A3 = GetEquipped(inst, EQUIPSLOTS.HEAD)
	if A1 and A1.components.shadowlevel then
		Point = Point + A1.components.shadowlevel.level
	end
	if A2 and A2.components.shadowlevel then
		Point = Point + A2.components.shadowlevel.level
	end
	if A3 and A3.components.shadowlevel then
		Point = Point + A3.components.shadowlevel.level
	end
	local shadow_gear_prefabs = {
		nightsword = true,
		nightsword_lunarplant = true,
		armor_sanity = true,
		voidcloth_scythe = true,
		voidcloth_boomerang = true,
		dreadstonehat = true,
	}
	if A1 ~= nil and A1.components.shadowlevel == nil and shadow_gear_prefabs[A1.prefab] then
		Point = Point + 1
	end
	if A2 ~= nil and A2.components.shadowlevel == nil and shadow_gear_prefabs[A2.prefab] then
		Point = Point + 1
	end
	if A3 ~= nil and A3.components.shadowlevel == nil and shadow_gear_prefabs[A3.prefab] then
		Point = Point + 1
	end
	if inst.components.rider and inst.components.rider:IsRiding() and inst.components.rider:GetSaddle() and inst.components.rider:GetSaddle().prefab == "saddle_shadow" then
		Point = Point + 3
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	for _, v in pairs(TheSim:FindEntities(x, y, z, 20, { "player" })) do
		if v ~= nil and v.prefab ~= "waxwell" then
			local V1 = GetEquipped(v, EQUIPSLOTS.HANDS)
			local V2 = GetEquipped(v, EQUIPSLOTS.BODY)
			local V3 = GetEquipped(v, EQUIPSLOTS.HEAD)
			if V1 and V1.components.shadowlevel then
				Point = Point + (V1.components.shadowlevel.level * 0.5)
			end
			if V2 and V2.components.shadowlevel then
				Point = Point + (V2.components.shadowlevel.level * 0.5)
			end
			if V3 and V3.components.shadowlevel then
				Point = Point + (V3.components.shadowlevel.level * 0.5)
			end
		end
	end
	return math.max(Point, 1)
end

--开局带影刀影甲
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "nightsword")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "armor_sanity")

--解锁暗影装备
AddPrefabPostInit("waxwell", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("darkmagic")
    inst:DoTaskInTime(0, function()
        if inst.components.builder then
            if not inst.components.builder:KnowsRecipe("nightsword") and inst.components.builder:CanLearn("nightsword") then
                inst.components.builder:UnlockRecipe("nightsword")
            end
            if not inst.components.builder:KnowsRecipe("armor_sanity") and inst.components.builder:CanLearn("armor_sanity") then
                inst.components.builder:UnlockRecipe("armor_sanity")
            end
        end
    end)
end)

-- 暗影突袭（影袭）：passive_shadows + ShadowPoint（仅加成用）
AddPrefabPostInit("waxwell", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:AddComponent("passive_shadows")
	inst.ShadowPoint = 1
	inst:DoTaskInTime(0, function()
		if inst:IsValid() then
			inst.ShadowPoint = GetShadowPoint(inst)
		end
	end)
	inst:DoPeriodicTask(0.5, function()
		if not inst:IsValid() then
			return
		end
		inst.ShadowPoint = GetShadowPoint(inst)
	end)
end)

local ACTIONS = GLOBAL.ACTIONS

-- 定义召回动作
local recall_action = Action({ priority = 20, rmb = true, distance = 1, mount_valid = true })
recall_action.id = "WURTCH"
recall_action.str = "召回"
recall_action.fn = function(act)
    if act.doer and act.doer.components.leader then
        local followers_to_remove = {}
        for follower in pairs(act.doer.components.leader.followers) do
            if follower:HasTag("shadowminion") and follower.prefab ~= "old_shadowwaxwell" then
                -- 记录需要移除的影人
                table.insert(followers_to_remove, follower)
            end
        end

        -- 移除影人并生成效果
        for _, follower in ipairs(followers_to_remove) do
            SpawnPrefab("shadow_despawn").Transform:SetPosition(follower.Transform:GetWorldPosition())
            if follower.components.inventory then
                follower.components.inventory:DropEverything(true)
            end
            follower:DoTaskInTime(0, follower.Remove)
        end

        -- 提示召回完成
        if #followers_to_remove > 0 then
            act.doer.components.talker:Say("回来，我的暗影仆从！")
        else
            act.doer.components.talker:Say("没有影人可召回。")
        end

        return true
    end
    return false
end

AddAction(recall_action)

AddComponentAction("SCENE", "inventory", function(inst, doer, actions)
    if inst == doer and inst.prefab == "waxwell" and inst:HasTag("player") then
        if inst.replica.rider and inst.replica.rider:IsRiding() then
            return -- 如果骑乘状态，直接不添加动作
        end
        table.insert(actions, ACTIONS.WURTCH)
    end
end)

for sg, is_client in pairs({ wilson = false, wilson_client = true }) do
    AddStategraphActionHandler(sg, ActionHandler(ACTIONS.WURTCH, "doshortaction"))
end

AddPrefabPostInit("waxwell", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end

    inst:DoPeriodicTask(1, function()
        if inst:HasTag("playerghost") then
            inst:RemoveTag("Puren")
            return
        end
        if inst.components.leader and inst.components.leader:CountFollowers("shadowminion") > 0 then
            inst:AddTag("Puren")
        else
            inst:RemoveTag("Puren")
        end
    end)
end)

AddPrefabPostInit("waxwell", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end

    inst:DoPeriodicTask(1, function()
        if inst:HasTag("playerghost") then
            inst:RemoveTag("Puren")
            return
        end
        if inst.components.leader and inst.components.leader:CountFollowers("shadowminion") > 0 then
            inst:AddTag("Puren")
        else
            inst:RemoveTag("Puren")
        end
    end)
end)


AddPrefabPostInit("shadowworker", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if inst.components.workmultiplier == nil then
        inst:AddComponent("workmultiplier")
    end

    inst.components.workmultiplier:AddMultiplier(GLOBAL.ACTIONS.CHOP, 2, inst)
    inst.components.workmultiplier:AddMultiplier(GLOBAL.ACTIONS.MINE, 2, inst)
    -- inst.components.workmultiplier:AddMultiplier(GLOBAL.ACTIONS.DIG, 2, inst)
end)


-- 修复 Maxwell 暗影仆从（shadowminion）重登复制物品的问题。
-- 逻辑：暗影仆从在玩家离线时已经把物品丢在地上，但同时 Inventory 也被写入存档，
-- 下一次玩家重连时重新生成的暗影仆从会再带出同一批物品，形成两份。
-- 这里禁止为带有 shadowminion 标签的单位保存 Inventory 内容，保证物品只存在于掉落在地上的那一份。
AddComponentPostInit("inventory", function(self)
    local old_OnSave = self.OnSave

    function self:OnSave(...)
        if self.inst ~= nil and self.inst:HasTag("shadowminion") then
            -- 不保存暗影仆从身上的物品与装备，返回空数据以避免重登复制
            return { items = {}, equip = {} }, {}
        end

        if old_OnSave ~= nil then
            return old_OnSave(self, ...)
        end
    end
end)

-- 暗影秘典牢笼/陷阱：向秘典给予 2 个勇者证明解锁；解锁后每多 1 个证明延长控制 1.5 秒
local function RogeWaxwellJournal_CanAcceptCoin(inst, item, giver)
	if item == nil or item.prefab ~= "coin_1" then
		return false
	end
	if giver == nil or not giver:IsValid() or giver.prefab ~= "waxwell" then
		return false
	end
	return true
end

local function RogeWaxwellJournal_OnAcceptCoin(inst, giver, item)
	giver._roge_waxwell_shadow_trap_coins = RogeWaxwellGetShadowTrapCoinProgress(giver) + 1
	local coins = giver._roge_waxwell_shadow_trap_coins
	if giver.components.talker ~= nil then
		if coins < ROGE_WAXWELL_SHADOW_TRAP_COIN_COST then
			giver.components.talker:Say(string.format("还需 %d 个勇者的证明。", ROGE_WAXWELL_SHADOW_TRAP_COIN_COST - coins))
		elseif coins == ROGE_WAXWELL_SHADOW_TRAP_COIN_COST then
			giver.components.talker:Say("暗影牢笼与陷阱……终于听命于我了。")
		else
			giver.components.talker:Say(string.format("暗影束缚延长至 %.1f 秒。", RogeWaxwellGetShadowTrapDuration(giver)))
		end
	end
end

local function RogeWaxwellTagShadowTrapAtPos(doer, pos, dur)
	if doer == nil or pos == nil or dur == nil then
		return
	end
	doer:DoTaskInTime(0, function()
		if not doer:IsValid() then
			return
		end
		for _, ent in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, 6)) do
			if ent.prefab == "shadow_trap" or ent.prefab == "shadow_pillar_spell" then
				ent._roge_shadow_trap_total_duration = dur
			end
		end
	end)
end

AddComponentPostInit("aoespell", function(self)
	if self.inst == nil or self.inst.prefab ~= "waxwelljournal" then
		return
	end
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if self._roge_waxwell_shadow_trap_duration_hooked then
		return
	end
	self._roge_waxwell_shadow_trap_duration_hooked = true

	local old_cast = self.CastSpell
	self.CastSpell = function(cmp, doer, pos)
		local ret = old_cast(cmp, doer, pos)
		if ret ~= false and doer ~= nil and pos ~= nil and RogeWaxwellJournalIsShadowCageOrTrap(cmp.inst, doer) then
			RogeWaxwellTagShadowTrapAtPos(doer, pos, RogeWaxwellGetShadowTrapDuration(doer))
		end
		return ret
	end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if right or inst.prefab ~= "coin_1" or target == nil or target.prefab ~= "waxwelljournal" then
		return
	end
	if not target:HasTag("trader") and not target:HasTag("alltrader") then
		return
	end
	if doer == nil or doer.prefab ~= "waxwell" then
		return
	end
	table.insert(actions, ACTIONS.GIVE)
end)

AddPrefabPostInit("waxwelljournal", function(inst)
	inst:AddTag("trader")
	inst:AddTag("alltrader")

	if not TheWorld.ismastersim then
		return
	end

	if inst.components.trader == nil then
		inst:AddComponent("trader")
	end
	inst.components.trader:SetAbleToAcceptTest(RogeWaxwellJournal_CanAcceptCoin)
	inst.components.trader:SetAcceptTest(RogeWaxwellJournal_CanAcceptCoin)
	inst.components.trader:SetOnAccept(RogeWaxwellJournal_OnAcceptCoin)
	inst.components.trader.acceptnontradable = true
	inst.components.trader.deleteitemonaccept = true
end)

AddPrefabPostInit("waxwell", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	local old_onsave = inst.OnSave
	inst.OnSave = function(i, data)
		if old_onsave ~= nil then
			old_onsave(i, data)
		end
		if RogeWaxwellGetShadowTrapCoinProgress(i) > 0 then
			data.roge_waxwell_shadow_trap_coins = i._roge_waxwell_shadow_trap_coins
		end
	end

	local old_onload = inst.OnLoad
	inst.OnLoad = function(i, data)
		if old_onload ~= nil then
			old_onload(i, data)
		end
		if data ~= nil and data.roge_waxwell_shadow_trap_coins ~= nil then
			i._roge_waxwell_shadow_trap_coins = data.roge_waxwell_shadow_trap_coins
		end
	end
end)