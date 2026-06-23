-- roge/walrus_squad.lua
-- 海象家族：Boss 池召唤包。小海象原版带 taunt_attack，远程只会嘲讽不会吹箭，此处单独处理。

ROGE_WALRUS_SQUAD_RADIUS = 4
ROGE_WALRUS_SQUAD_HEALTH = 800
ROGE_LITTLE_WALRUS_SQUAD_HEALTH = 300
ROGE_WALRUS_SQUAD_ATTACK_INTERVAL = 3.5
ROGE_WALRUS_PIPE_FREEZE_COLDNESS = 2.8
ROGE_WALRUS_SQUAD_GEM_DEER_RADIUS = 6
ROGE_GEM_DEER_MAX_HEALTH = 700
ROGE_GEM_DEER_SPELL_INTERVAL = 8
ROGE_GEM_DEER_SPELL_TIMER = "roge_gem_spell_cd"
ROGE_GEM_DEER_CAST_RANGE = 6 * (ROGE_TURF_SIZE or 4) - 1
TUNING.DEER_GEMMED_CAST_RANGE = ROGE_GEM_DEER_CAST_RANGE
TUNING.DEER_GEMMED_CAST_MAX_RANGE = ROGE_GEM_DEER_CAST_RANGE
ROGE_WALRUS_SQUAD_GEM_DEER_SPAWNS = {
	{ prefab = "deer_red", name = "火焰宝石鹿", offset = Vector3(4, 0, 3) },
	{ prefab = "deer_blue", name = "冰冻宝石鹿", offset = Vector3(-4, 0, -3) },
}

-- 原版吹箭对应生物用 blowdart_walrus（无 blowdart 预制体）
ROGE_WALRUS_SQUAD_DART_TYPES = {
	"blowdart_walrus",
	"blowdart_sleep",
	"blowdart_fire",
	"blowdart_yellow",
	"blowdart_pipe",
}

ROGE_WALRUS_SQUAD_DART_NAMES = {
	blowdart_walrus = "原版吹箭",
	blowdart_sleep = "麻醉吹箭",
	blowdart_fire = "火焰吹箭",
	blowdart_yellow = "电击吹箭",
	blowdart_pipe = "冰冻吹箭",
}

ROGE_WALRUS_SQUAD_SPAWNS = {
	{ prefab = "walrus", weapon = "random" },
	{ prefab = "little_walrus", weapon = "blowdart_sleep" },
	{ prefab = "little_walrus", weapon = "blowdart_fire" },
	{ prefab = "little_walrus", weapon = "blowdart_yellow" },
	{ prefab = "little_walrus", weapon = "blowdart_pipe" },
	{ prefab = "little_walrus", weapon = "blowdart_walrus" },
}

local function RogeNormalizeWeaponKey(key)
	if key == "random" then
		return key
	end
	if key == "blowdart" then
		return "blowdart_walrus"
	end
	return key
end

local function RogePickRandomWalrusDartKey()
	return ROGE_WALRUS_SQUAD_DART_TYPES[math.random(#ROGE_WALRUS_SQUAD_DART_TYPES)]
end

local function RogeGemDeerIsInCastRange(inst, target)
	return inst ~= nil and inst:IsValid()
		and target ~= nil and target:IsValid()
		and inst:IsNear(target, ROGE_GEM_DEER_CAST_RANGE)
end

local function RogeGemDeerIsValidCastVictim(inst, target)
	return target ~= nil and target:IsValid()
		and target.components.health ~= nil and not target.components.health:IsDead()
		and not target:HasTag("playerghost")
		and not target:HasTag("deergemresistance")
		and RogeGemDeerIsInCastRange(inst, target)
end

local function RogeGemDeerFilterCastTargets(inst, targets)
	if targets == nil then
		return nil
	end
	local filtered = {}
	for _, v in ipairs(targets) do
		if RogeGemDeerIsValidCastVictim(inst, v) then
			table.insert(filtered, v)
		end
	end
	return #filtered > 0 and filtered or nil
end

local function RogeWalrusSquadIsAlly(inst)
	return inst ~= nil and inst:IsValid() and inst:HasTag("roge_walrus_squad_ally")
end

function RogeGemDeerResolveCastTargets(inst, target)
	if inst == nil or inst.gem == nil then
		return nil
	end
	if target == nil and inst.components.combat ~= nil then
		target = inst.components.combat.target
	end
	if RogeGemDeerIsValidCastVictim(inst, target) then
		return { target }
	end
	if inst._roge_vanilla_find_cast ~= nil then
		return RogeGemDeerFilterCastTargets(inst, inst._roge_vanilla_find_cast(inst, nil))
			or RogeGemDeerFilterCastTargets(inst, inst._roge_vanilla_find_cast(inst, target))
	end
	return nil
end

local function RogeGemDeerPickCastTarget(inst, targets)
	if targets == nil then
		return nil
	end
	local combat_target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if RogeGemDeerIsValidCastVictim(inst, combat_target) then
		for _, v in ipairs(targets) do
			if v == combat_target then
				return combat_target
			end
		end
	end
	for _, v in ipairs(targets) do
		if RogeGemDeerIsValidCastVictim(inst, v) then
			return v
		end
	end
	return nil
end

local function RogeGemDeerSpawnOneFormation(inst, target)
	local spells = {}
	local extra = 3
	local x, y, z = target.Transform:GetWorldPosition()
	local spell = SpawnPrefab(inst.castfx)
	if spell ~= nil then
		spell.Transform:SetPosition(x, 0, z)
		spell:DoTaskInTime(inst.castduration, spell.KillFX)
		table.insert(spells, spell)
	end
	local angle_step = 360 / extra
	local random_angle = 2 * PI * math.random()
	for n = 1, extra do
		local angle = (n - 1) * angle_step
		local radian = math.rad(angle) + random_angle
		local sx = x + 6 * math.cos(radian)
		local sz = z - 6 * math.sin(radian)
		spell = SpawnPrefab(inst.castfx)
		if spell ~= nil then
			spell.Transform:SetPosition(sx, 0, sz)
			spell:DoTaskInTime(inst.castduration, spell.KillFX)
			table.insert(spells, spell)
		end
	end
	return spells
end

local function RogeGemDeerDoCast(inst, targets)
	if inst == nil or inst.gem == nil or targets == nil or #targets == 0 then
		if inst ~= nil and inst._roge_vanilla_docast ~= nil then
			return inst._roge_vanilla_docast(inst, targets)
		end
		return nil
	end
	local primary = RogeGemDeerPickCastTarget(inst, targets)
	if primary == nil then
		if inst._roge_vanilla_docast ~= nil then
			return inst._roge_vanilla_docast(inst, targets)
		end
		return nil
	end
	local spells = RogeGemDeerSpawnOneFormation(inst, primary)
	if #spells > 0 and inst.components.timer ~= nil then
		inst.components.timer:StopTimer("deercast_cd")
		inst.components.timer:StartTimer("deercast_cd", inst.castcd or TUNING.DEER_GEMMED_FIRST_CAST_CD)
		return spells
	end
	return nil
end

local function RogeGemDeerShouldCastSpell(inst)
	if inst == nil or inst.gem == nil or inst._roge_gem_spell_ready ~= true then
		return false
	end
	if inst.sg ~= nil and (inst.sg:HasStateTag("busy")
		or inst.sg:HasStateTag("attack")
		or inst.sg:HasStateTag("casting")) then
		return false
	end
	if inst.components.timer ~= nil then
		if inst.components.timer:TimerExists(ROGE_GEM_DEER_SPELL_TIMER) then
			return false
		end
		if inst.components.timer:TimerExists("deercast_cd") then
			return false
		end
	end
	return true
end

local function RogeGemDeerStartSpellTimer(inst)
	if inst == nil or inst.components.timer == nil then
		return
	end
	inst._roge_gem_spell_ready = false
	inst.components.timer:StopTimer(ROGE_GEM_DEER_SPELL_TIMER)
	inst.components.timer:StartTimer(ROGE_GEM_DEER_SPELL_TIMER, ROGE_GEM_DEER_SPELL_INTERVAL)
end

local function RogeGemDeerOnSpellTimerDone(inst, data)
	if inst == nil or data == nil or data.name ~= ROGE_GEM_DEER_SPELL_TIMER then
		return
	end
	inst._roge_gem_spell_ready = true
	if inst._roge_walrus_squad_gem_deer then
		local target = RogeWalrusSquadGetGemDeerCombatTarget(inst)
		if target ~= nil and inst.sg ~= nil
			and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("attack") then
			RogeGemDeerTryCastSpell(inst, target)
		end
	end
end

local function RogeGemDeerPerformSpellCast(inst, target)
	if inst == nil or not inst:IsValid() or inst.gem == nil or inst.sg == nil then
		return false
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end
	if inst.sg:HasStateTag("busy") then
		return false
	end
	local targets = RogeGemDeerResolveCastTargets(inst, target)
	if targets ~= nil then
		inst.sg:GoToState("magic_pre", targets)
		return true
	end
	return false
end

function RogeGemDeerTryCastSpell(inst, target)
	if inst == nil or not inst:IsValid() or inst.gem == nil then
		return false
	end
	if target == nil and inst.components.combat ~= nil then
		target = inst.components.combat.target
	end
	if target ~= nil and not RogeGemDeerIsInCastRange(inst, target) then
		return false
	end
	if not RogeGemDeerShouldCastSpell(inst) then
		return false
	end
	inst._roge_gem_spell_ready = false
	RogeGemDeerStartSpellTimer(inst)
	if RogeGemDeerPerformSpellCast(inst, target) then
		return true
	end
	-- 施法动作未能启动，仍保留 CD
	return false
end

local function RogeWalrusSquadGetGemDeerKeeper(inst)
	return inst.components.entitytracker ~= nil
		and inst.components.entitytracker:GetEntity("keeper") or nil
end

local function RogeWalrusSquadGetGemDeerLeashPos(inst)
	local keeper = RogeWalrusSquadGetGemDeerKeeper(inst)
	if keeper == nil then
		return nil
	end
	local pos = keeper:GetPosition()
	local offset = inst.components.knownlocations ~= nil
		and inst.components.knownlocations:GetLocation("keeperoffset") or nil
	return offset ~= nil and pos + offset or pos
end

local function RogeWalrusSquadIsValidProtectTarget(target)
	return target ~= nil and target:IsValid()
		and target.components.health ~= nil and not target.components.health:IsDead()
		and not target:HasTag("playerghost")
		and not target:HasTag("deergemresistance")
end

local function RogeWalrusSquadGetGemDeerProtectTarget(leader)
	if leader == nil or not leader:IsValid() then
		return nil
	end
	local t = leader._roge_walrus_squad_protect_target
	if RogeWalrusSquadIsValidProtectTarget(t) and not t:HasTag("roge_walrus_squad_ally") then
		return t
	end
	return nil
end

function RogeWalrusSquadGetGemDeerCombatTarget(inst)
	return RogeWalrusSquadGetGemDeerProtectTarget(inst ~= nil and inst._roge_walrus_squad_leader or nil)
end

local function RogeWalrusSquadSyncGemDeerProtect(leader)
	local target = RogeWalrusSquadGetGemDeerProtectTarget(leader)
	local deers = leader ~= nil and leader._roge_walrus_squad_gem_deers or nil
	if deers == nil then
		return
	end
	for _, deer in ipairs(deers) do
		if deer ~= nil and deer:IsValid() and deer.components.combat ~= nil then
			deer.components.combat:SetTarget(target)
			if deer.SetEngaged ~= nil then
				deer:SetEngaged(target ~= nil)
			end
			if target ~= nil and deer.sg ~= nil
				and not deer.sg:HasStateTag("busy") and not deer.sg:HasStateTag("attack") then
				deer:FacePoint(target.Transform:GetWorldPosition())
				RogeGemDeerTryCastSpell(deer, target)
			end
		end
	end
end

local function RogeWalrusSquadGemDeerDefend(inst)
	local target = RogeWalrusSquadGetGemDeerCombatTarget(inst)
	if target == nil then
		if inst.components.combat ~= nil then
			inst.components.combat:SetTarget(nil)
		end
		if inst.SetEngaged ~= nil then
			inst:SetEngaged(false)
		end
		return false
	end
	if inst.components.combat ~= nil then
		inst.components.combat:SetTarget(target)
	end
	if inst.SetEngaged ~= nil then
		inst:SetEngaged(true)
	end
	if inst.sg ~= nil and (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack")) then
		return true
	end
	inst:FacePoint(target.Transform:GetWorldPosition())
	return RogeGemDeerTryCastSpell(inst, target) or true
end

local function RogeHookWalrusSquadLeaderProtect(leader)
	if leader == nil or not leader:IsValid() or leader._roge_walrus_squad_protect_hooked then
		return
	end
	leader._roge_walrus_squad_protect_hooked = true
	leader:ListenForEvent("attacked", function(l, data)
		if l == nil or not l:IsValid() or data == nil or data.attacker == nil
			or not data.attacker:IsValid() or RogeWalrusSquadIsAlly(data.attacker) then
			return
		end
		if data.attacker.components.health ~= nil and data.attacker.components.health:IsDead() then
			return
		end
		l._roge_walrus_squad_protect_target = data.attacker
		RogeWalrusSquadSyncGemDeerProtect(l)
	end)
	leader:DoPeriodicTask(2, function(l)
		if l == nil or not l:IsValid() then
			return
		end
		local t = l._roge_walrus_squad_protect_target
		if t == nil then
			return
		end
		if not t:IsValid() or RogeWalrusSquadIsAlly(t)
			or (t.components.health ~= nil and t.components.health:IsDead()) then
			l._roge_walrus_squad_protect_target = nil
			RogeWalrusSquadSyncGemDeerProtect(l)
		end
	end)
end

local function RogeStripSquadInventoryNoDrop(inst)
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	for _, item in pairs(inv.equipslots) do
		if item ~= nil and item:IsValid() then
			item:Remove()
		end
	end
	for _, item in pairs(inv.itemslots) do
		if item ~= nil and item:IsValid() then
			item:Remove()
		end
	end
end

local function RogeClearWalrusHands(inst)
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	local old = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
	if old ~= nil and old:IsValid() then
		old:Remove()
	end
end

local function RogeClearWalrusSquadHighlight(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	local hl = inst.components.highlight
	if hl == nil then
		return
	end
	hl.highlit = nil
	hl.flashing = false
	if inst.AnimState ~= nil then
		inst.AnimState:SetHighlightColour()
	end
end

local function RogeWalrusSquadIsHighlightSafeEntity(inst)
	return inst ~= nil and inst:IsValid()
		and (inst:HasTag("roge_walrus_squad_ally") or inst._roge_walrus_squad_member == true)
end

local roge_walrus_squad_safe_highlight_installed = false

local function RogeInstallWalrusSquadSafeHighlight()
	if roge_walrus_squad_safe_highlight_installed then
		return
	end
	roge_walrus_squad_safe_highlight_installed = true
	AddComponentPostInit("highlight", function(self)
		local old_unhighlight = self.UnHighlight
		self.UnHighlight = function(hl, ...)
			local owner = hl.inst
			if RogeWalrusSquadIsHighlightSafeEntity(owner) then
				hl.highlit = nil
				hl.flashing = false
				if owner.AnimState ~= nil then
					owner.AnimState:SetHighlightColour()
				end
				return
			end
			if old_unhighlight ~= nil then
				return old_unhighlight(hl, ...)
			end
		end
	end)
end

local function RogeApplyWalrusPipeFreeze(target)
	if target == nil or not target:IsValid() then
		return
	end
	local freezable = target.components.freezable
	if freezable ~= nil then
		freezable:AddColdness(ROGE_WALRUS_PIPE_FREEZE_COLDNESS)
	end
end

local function RogeIsWalrusPipeHit(weapon, attacker)
	if weapon ~= nil and weapon:IsValid() and weapon.prefab == "blowdart_pipe" then
		return true
	end
	return attacker ~= nil and attacker:IsValid()
		and attacker._roge_walrus_squad_weapon_key == "blowdart_pipe"
end

local function RogeHookWalrusPipeFreezeListener(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "little_walrus" then
		return
	end
	if inst._roge_walrus_pipe_freeze_listener then
		return
	end
	inst._roge_walrus_pipe_freeze_listener = true
	inst:ListenForEvent("onhitother", function(m, data)
		if data == nil or data.target == nil or not data.target:IsValid() then
			return
		end
		if RogeIsWalrusPipeHit(data.weapon, m) then
			RogeApplyWalrusPipeFreeze(data.target)
		end
	end)
end

local function RogePatchWalrusPipeDartProjectile(dart)
	local projectile = dart ~= nil and dart.components.projectile or nil
	if projectile == nil then
		return
	end
	projectile:SetLaunchOffset(Vector3(2, 1.5, 0))
	projectile:SetHitDist(math.sqrt(5))
end

local function RogePatchWalrusPipeDartWeapon(dart)
	if dart == nil or not dart:IsValid() or dart.components.weapon == nil then
		return
	end
	local weapon = dart.components.weapon
	local old_onattack = weapon.onattack
	weapon:SetOnAttack(function(wep, attacker, target)
		if target ~= nil and target:IsValid() then
			RogeApplyWalrusPipeFreeze(target)
		end
		if old_onattack ~= nil then
			old_onattack(wep, attacker, target)
		end
	end)
end

local function RogePatchSquadDartImpact(dart, weapon_key)
	if dart == nil or not dart:IsValid() or dart.components.projectile == nil then
		return
	end
	dart.components.projectile:SetOnHitFn(function(projectile, attacker, target)
		if weapon_key == "blowdart_pipe" then
			RogeApplyWalrusPipeFreeze(target)
		end
		local impactfx = SpawnPrefab("impact")
		if impactfx ~= nil and target ~= nil and target:IsValid()
			and target.components.combat ~= nil then
			local follower = impactfx.entity:AddFollower()
			follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
			if attacker ~= nil and attacker:IsValid() then
				impactfx:FacePoint(attacker.Transform:GetWorldPosition())
			end
		end
		-- 不 Remove 吹箭，避免命中后反复换装导致跟随丢失
	end)
	dart.components.projectile:SetOnMissFn(function() end)
end

local function RogePatchSquadDart(dart, owner, weapon_key)
	if dart == nil or not dart:IsValid() then
		return
	end
	dart.persists = false
	dart:AddTag("nosteal")
	if dart.components.stackable ~= nil then
		dart.components.stackable:SetStackSize(999)
	end
	if dart.components.equippable ~= nil then
		dart.components.equippable.restrictedtag = nil
	end
	if weapon_key == "blowdart_pipe" then
		RogePatchWalrusPipeDartWeapon(dart)
		RogePatchWalrusPipeDartProjectile(dart)
	end
	RogePatchSquadDartImpact(dart, weapon_key)
end

local function RogeWalrusSquadKeeperAlive(deer)
	local leader = deer ~= nil and deer._roge_walrus_squad_leader or nil
	return leader ~= nil and leader:IsValid()
		and leader.components.health ~= nil and not leader.components.health:IsDead()
end

local function RogeReleaseWalrusSquadGemDeers(leader)
	local deers = leader ~= nil and leader._roge_walrus_squad_gem_deers or nil
	if deers == nil then
		return
	end
	for _, deer in ipairs(deers) do
		if deer ~= nil and deer:IsValid()
			and deer.components.health ~= nil and not deer.components.health:IsDead() then
			deer._roge_walrus_squad_gem_locked = false
			deer._roge_allow_unshackle = true
			deer:PushEvent("unshackle")
		end
	end
end

local function RogeHookWalrusSquadFriendlyCombat(inst)
	if inst == nil or not inst:IsValid() or inst.components.combat == nil
		or inst._roge_walrus_squad_ff_hooked then
		return
	end
	inst._roge_walrus_squad_ff_hooked = true
	inst:AddTag("roge_walrus_squad_ally")
	if not inst:HasTag("deergemresistance") then
		inst:AddTag("deergemresistance")
	end
	local combat = inst.components.combat
	local old_targetfn = combat.targetfn
	combat:SetRetargetFunction(1, function(m)
		local target, force
		if old_targetfn ~= nil then
			target, force = old_targetfn(m)
		end
		if target ~= nil and RogeWalrusSquadIsAlly(target) then
			return nil
		end
		return target, force
	end)
	inst:ListenForEvent("newcombattarget", function(i, data)
		if data ~= nil and data.target ~= nil and RogeWalrusSquadIsAlly(data.target)
			and i.components.combat ~= nil then
			i.components.combat:SetTarget(nil)
		end
	end)
end

local function RogeRegisterWalrusSquadAttacker(leader, attacker)
	if leader == nil or attacker == nil or not leader:IsValid() or not attacker:IsValid() then
		return
	end
	if leader._roge_walrus_squad_attackers == nil then
		leader._roge_walrus_squad_attackers = {}
	end
	for _, a in ipairs(leader._roge_walrus_squad_attackers) do
		if a == attacker then
			return
		end
	end
	table.insert(leader._roge_walrus_squad_attackers, attacker)
end

-- 死亡时先清 highlight / 取消定时任务，再延迟剥离背包，避免 Action Queue 在 UnHighlight 时崩溃
local function RogeWalrusSquadDeathCleanup(inst)
	if inst == nil or inst._roge_walrus_squad_death_cleaned then
		return
	end
	inst._roge_walrus_squad_death_cleaned = true
	if inst._roge_walrus_squad_attack_task ~= nil then
		inst._roge_walrus_squad_attack_task:Cancel()
		inst._roge_walrus_squad_attack_task = nil
	end
	if inst._roge_walrus_squad_follow_task ~= nil then
		inst._roge_walrus_squad_follow_task:Cancel()
		inst._roge_walrus_squad_follow_task = nil
	end
	RogeReleaseWalrusSquadGemDeers(inst)
	RogeClearWalrusSquadHighlight(inst)
	inst:DoTaskInTime(0.15, function(w)
		if w ~= nil and w:IsValid() then
			RogeStripSquadInventoryNoDrop(w)
		end
	end)
end

local function RogeLinkSquadFollower(minion, leader)
	if minion == nil or leader == nil or not minion:IsValid() or not leader:IsValid() then
		return
	end
	minion._roge_walrus_squad_leader = leader
	local follower = minion.components.follower
	if follower == nil then
		minion:AddComponent("follower")
		follower = minion.components.follower
	end
	if follower ~= nil and follower:GetLeader() ~= leader then
		follower:SetLeader(leader)
	end
	if leader.components.leader ~= nil then
		leader.components.leader:AddFollower(minion)
	end
end

local function RogeLinkLittleWalrusToLeader(minion, leader)
	RogeLinkSquadFollower(minion, leader)
end

local function RogeEnsureWalrusSquadFollow(minion, leader)
	if minion == nil or leader == nil or not minion:IsValid() or not leader:IsValid() then
		return
	end
	if minion.components.health ~= nil and minion.components.health:IsDead() then
		return
	end
	local follower = minion.components.follower
	if follower == nil then
		RogeLinkSquadFollower(minion, leader)
		follower = minion.components.follower
	end
	if follower ~= nil and follower:GetLeader() ~= leader then
		RogeLinkSquadFollower(minion, leader)
	end
	if (minion.prefab == "deer_red" or minion.prefab == "deer_blue")
		and minion.components.locomotor ~= nil
		and minion:GetDistanceSqToInst(leader) > 64 then
		local lp = leader:GetPosition()
		local offset = FindWalkableOffset(lp, math.random() * 2 * PI, 4, 8, false, true)
		if offset ~= nil then
			minion.components.locomotor:GoToPoint(lp + offset)
		end
	end
end

local function RogeScheduleWalrusSquadFollowCheck(leader, minions)
	if leader == nil or not leader:IsValid() or minions == nil then
		return
	end
	if leader._roge_walrus_squad_follow_task ~= nil then
		leader._roge_walrus_squad_follow_task:Cancel()
		leader._roge_walrus_squad_follow_task = nil
	end
	leader._roge_walrus_squad_follow_task = leader:DoPeriodicTask(2, function(l)
		if l == nil or not l:IsValid() or l.components.health == nil or l.components.health:IsDead() then
			return
		end
		local squad = l._roge_walrus_squad_minions
		if squad == nil then
			return
		end
		for _, m in ipairs(squad) do
			RogeEnsureWalrusSquadFollow(m, l)
		end
		local gem_deers = l._roge_walrus_squad_gem_deers
		if gem_deers ~= nil then
			for _, deer in ipairs(gem_deers) do
				RogeEnsureWalrusSquadFollow(deer, l)
			end
		end
	end)
end

local function RogeEnsureWalrusLeaderCommander(leader)
	if leader.components.commander == nil then
		leader:AddComponent("commander")
		leader.components.commander:SetTrackingDistance(30)
	end
	if not leader:HasTag("deergemresistance") then
		leader:AddTag("deergemresistance")
	end
	RogeHookWalrusSquadLeaderProtect(leader)
end

local function RogeHookWalrusSquadGemDeerLock(deer)
	if deer == nil or deer._roge_walrus_squad_gem_lock_hooked then
		return
	end
	deer._roge_walrus_squad_gem_lock_hooked = true
	deer:ListenForEvent("lostcommander", function(d)
		if d._roge_walrus_squad_gem_locked and RogeWalrusSquadKeeperAlive(d) then
			local leader = d._roge_walrus_squad_leader
			if leader ~= nil and leader.components.commander ~= nil then
				leader.components.commander:AddSoldier(d)
			end
		end
	end)
end

local function RogeHookWalrusSquadGemDeerCombat(deer, leader, fallback_target)
	if deer == nil or not deer:IsValid() or deer.components.combat == nil then
		return
	end
	deer.components.combat:SetRetargetFunction(1, function(d)
		local t = RogeWalrusSquadGetGemDeerCombatTarget(d)
		if t ~= nil then
			return t, true
		end
		return nil
	end)
end

local function RogeHookGemDeerCombat(inst)
	if inst == nil or not inst:IsValid() or inst.gem == nil
		or inst._roge_gem_deer_combat_hooked then
		return
	end
	inst._roge_gem_deer_combat_hooked = true
	inst.castcd = ROGE_GEM_DEER_SPELL_INTERVAL
	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:SetMaxHealth(ROGE_GEM_DEER_MAX_HEALTH)
	end
	TUNING.DEER_GEMMED_CAST_RANGE = ROGE_GEM_DEER_CAST_RANGE
	TUNING.DEER_GEMMED_CAST_MAX_RANGE = ROGE_GEM_DEER_CAST_RANGE
	if not inst._roge_gem_spell_timer_listener then
		inst._roge_gem_spell_timer_listener = true
		inst:ListenForEvent("timerdone", RogeGemDeerOnSpellTimerDone)
	end
	RogeGemDeerStartSpellTimer(inst)
	if inst.FindCastTargets ~= nil and inst._roge_vanilla_find_cast == nil then
		inst._roge_vanilla_find_cast = inst.FindCastTargets
		inst.FindCastTargets = function(deer, target)
			return RogeGemDeerResolveCastTargets(deer, target)
		end
	end
	if inst.DoCast ~= nil and inst._roge_vanilla_docast == nil then
		inst._roge_vanilla_docast = inst.DoCast
	end
	inst.DoCast = RogeGemDeerDoCast
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	local _TryAttack = combat.TryAttack
	combat.TryAttack = function(self, target)
		local owner = self.inst
		if owner == nil or owner.gem == nil then
			return _TryAttack(self, target)
		end
		if owner._roge_walrus_squad_gem_deer then
			target = RogeWalrusSquadGetGemDeerCombatTarget(owner)
			if target == nil then
				return false
			end
			if owner.sg ~= nil and owner.sg:HasStateTag("attack") then
				return true
			end
			if owner.sg ~= nil and owner.sg:HasStateTag("busy") then
				return false
			end
			if self:InCooldown() then
				self:ResetCooldown()
			end
			self:SetTarget(target)
			owner:FacePoint(target.Transform:GetWorldPosition())
			return RogeGemDeerTryCastSpell(owner, target)
		end
		target = target or self.target
		if target == nil or not target:IsValid() then
			return false
		end
		if owner.sg ~= nil and owner.sg:HasStateTag("attack") then
			return true
		end
		if owner.sg ~= nil and owner.sg:HasStateTag("busy") then
			return false
		end
		if self:InCooldown() then
			self:ResetCooldown()
		end
		if RogeGemDeerTryCastSpell(owner, target) then
			return true
		end
		return _TryAttack(self, target)
	end
end

local function RogeApplyWalrusSquadGemDeerName(deer, display_name)
	if deer == nil or not deer:IsValid() or display_name == nil then
		return
	end
	if deer.components.named == nil then
		deer:AddComponent("named")
	end
	deer.components.named:SetName(display_name)
end

local function RogeSetupWalrusSquadGemDeer(deer, leader, display_name, fallback_target, offset)
	if deer == nil or not deer:IsValid() or leader == nil or not leader:IsValid() then
		return
	end
	deer._roge_walrus_squad_member = true
	deer._roge_walrus_squad_gem_deer = true
	deer._roge_walrus_squad_gem_locked = true
	deer._roge_walrus_squad_leader = leader
	deer.persists = false
	deer:AddTag("flare_summoned")
	RogeHookWalrusSquadFriendlyCombat(deer)
	RogeEnsureWalrusLeaderCommander(leader)
	leader.components.commander:AddSoldier(deer)
	if offset ~= nil and deer.OnUpdateOffset ~= nil then
		deer:OnUpdateOffset(offset)
	end
	RogeHookWalrusSquadGemDeerLock(deer)
	RogeHookWalrusSquadGemDeerCombat(deer, leader, fallback_target)
	RogeHookGemDeerCombat(deer)
	RogeApplyWalrusSquadGemDeerName(deer, display_name)
	if leader._roge_walrus_squad_gem_deers == nil then
		leader._roge_walrus_squad_gem_deers = {}
	end
	table.insert(leader._roge_walrus_squad_gem_deers, deer)
	if deer.components.combat ~= nil then
		deer.components.combat:SetTarget(nil)
	end
	if deer.SetEngaged ~= nil then
		deer:SetEngaged(false)
	end
	if deer.components.spawnfader ~= nil then
		deer.components.spawnfader:FadeIn()
	end
	if deer.brain ~= nil then
		deer.brain:Stop()
		deer.brain:Start()
	end
end

function RogeEquipWalrusSquadWeapon(inst, weapon_key)
	if inst == nil or not inst:IsValid() or weapon_key == nil then
		return nil
	end
	if weapon_key == "random" then
		weapon_key = RogePickRandomWalrusDartKey()
	else
		weapon_key = RogeNormalizeWeaponKey(weapon_key)
	end

	local combat = inst.components.combat
	local inv = inst.components.inventory
	if combat == nil or inv == nil then
		return nil
	end

	RogeClearWalrusHands(inst)

	local dart = SpawnPrefab(weapon_key)
	if dart == nil then
		return nil
	end
	if weapon_key == "blowdart_walrus" and dart.components.weapon ~= nil then
		dart.components.weapon:SetDamage(combat.defaultdamage)
		dart.components.weapon:SetRange(combat.attackrange, combat.attackrange + 2)
	end

	RogePatchSquadDart(dart, inst, weapon_key)

	inv:GiveItem(dart)
	inv:Equip(dart)
	inst._roge_walrus_squad_weapon_key = weapon_key
	if inst.prefab == "little_walrus" and inst._roge_walrus_squad_leader ~= nil
		and inst._roge_walrus_squad_leader:IsValid() then
		RogeLinkLittleWalrusToLeader(inst, inst._roge_walrus_squad_leader)
	end
	return weapon_key
end

function RogeHookLittleWalrusSquadCombat(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "little_walrus" then
		return
	end
	if inst._roge_walrus_combat_hooked then
		return
	end
	inst._roge_walrus_combat_hooked = true
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	combat:SetRetargetFunction(1, function(m)
		local leader = m._roge_walrus_squad_leader
		if leader ~= nil and leader:IsValid() and leader.components.combat ~= nil then
			local t = leader.components.combat.target
			if t ~= nil and t:IsValid() and not RogeWalrusSquadIsAlly(t) then
				return t, true
			end
		end
		local fb = m._roge_walrus_squad_fallback_target
		if fb ~= nil and fb:IsValid() and not RogeWalrusSquadIsAlly(fb) then
			return fb, true
		end
		return nil
	end)
end

local function RogeHookSquadInventoryNoDrop(inst)
	if inst._roge_walrus_inv_hooked or inst.components.inventory == nil then
		return
	end
	inst._roge_walrus_inv_hooked = true
	local inv = inst.components.inventory
	local old_drop = inv.DropEverything
	inv.DropEverything = function(self, ondeath, keepequip)
		if self.inst._roge_walrus_squad_member then
			RogeStripSquadInventoryNoDrop(self.inst)
			return
		end
		return old_drop(self, ondeath, keepequip)
	end
end

local function RogePrepareWalrusSquadMember(inst)
	RogeInstallWalrusSquadSafeHighlight()
	inst._roge_walrus_squad_member = true
	inst:AddTag("flare_summoned")
	inst:StopWatchingWorldState("stopday")
	inst.OnEntitySleep = nil
	RogeHookWalrusSquadFriendlyCombat(inst)
	if inst.prefab == "little_walrus" then
		inst:RemoveTag("taunt_attack")
		RogeHookLittleWalrusSquadCombat(inst)
		RogeHookWalrusPipeFreezeListener(inst)
	end
	RogeHookSquadInventoryNoDrop(inst)
	if inst._roge_walrus_squad_death_listener == nil then
		inst._roge_walrus_squad_death_listener = true
		inst:ListenForEvent("death", function(w)
			RogeWalrusSquadDeathCleanup(w)
		end)
		inst:ListenForEvent("onremove", function(w)
			RogeClearWalrusSquadHighlight(w)
		end)
	end
end

local function RogeApplyWalrusSquadStats(inst)
	if inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	local maxhp = inst.prefab == "walrus" and ROGE_WALRUS_SQUAD_HEALTH
		or inst.prefab == "little_walrus" and ROGE_LITTLE_WALRUS_SQUAD_HEALTH
	if maxhp ~= nil then
		RogeSetFixedMaxHealth(inst, maxhp)
	end
	if inst.prefab == "walrus" and RogeSetupVoidProtection ~= nil then
		RogeSetupVoidProtection(inst)
	end
end

local function RogeApplyLittleWalrusSquadName(inst, weapon_key)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "little_walrus" then
		return
	end
	weapon_key = RogeNormalizeWeaponKey(weapon_key)
	local weapon_name = ROGE_WALRUS_SQUAD_DART_NAMES[weapon_key]
	if weapon_name == nil then
		return
	end
	local base_name = inst:GetDisplayName() or inst.name or inst.prefab
	local suffix = "-" .. weapon_name
	if base_name:find(suffix, 1, true) then
		return
	end
	if inst.components.named == nil then
		inst:AddComponent("named")
	end
	inst.components.named:SetName(base_name .. suffix)
end

local function RogeApplyWalrusSquadMember(inst, weapon_key)
	if inst == nil or not inst:IsValid() or weapon_key == nil then
		return
	end
	RogePrepareWalrusSquadMember(inst)
	local resolved = RogeEquipWalrusSquadWeapon(inst, weapon_key)
	RogeApplyWalrusSquadStats(inst)
	if inst.prefab == "little_walrus" and resolved ~= nil then
		RogeApplyLittleWalrusSquadName(inst, resolved)
	end
	if inst.prefab == "walrus" and weapon_key == "random"
		and inst._roge_walrus_random_darts_listener == nil then
		inst._roge_walrus_random_darts_listener = true
		inst:ListenForEvent("doattack", function(w)
			if w ~= nil and w:IsValid() then
				RogeEquipWalrusSquadWeapon(w, "random")
			end
		end)
	end
end

local function RogeResolveWalrusSquadTarget(leader, fallback)
	if leader ~= nil and leader:IsValid() and leader.components.combat ~= nil then
		local t = leader.components.combat.target
		if t ~= nil and t:IsValid() then
			return t
		end
	end
	if fallback ~= nil and fallback:IsValid() then
		return fallback
	end
	return nil
end

local function RogeSyncMinionCombatTargets(leader)
	local minions = leader ~= nil and leader._roge_walrus_squad_minions or nil
	if minions == nil then
		return
	end
	local target = RogeResolveWalrusSquadTarget(leader, leader._roge_walrus_squad_fallback_target)
	if target == nil or RogeWalrusSquadIsAlly(target) then
		return
	end
	for _, m in ipairs(minions) do
		if m ~= nil and m:IsValid() and m.components.combat ~= nil then
			m._roge_walrus_squad_fallback_target = leader._roge_walrus_squad_fallback_target
			m.components.combat:SetTarget(target)
		end
	end
end

local function RogeSyncLeaderCombatTarget(leader)
	if leader == nil or not leader:IsValid() then
		return
	end
	local target = RogeResolveWalrusSquadTarget(leader, leader._roge_walrus_squad_fallback_target)
	if target == nil or RogeWalrusSquadIsAlly(target) then
		return
	end
	if leader.components.combat ~= nil then
		leader.components.combat:SetTarget(target)
	end
	RogeSyncMinionCombatTargets(leader)
end

local function RogeGrantWalrusSquadAttackTurn(minion, leader)
	if minion == nil or leader == nil then
		return
	end
	local minions = leader._roge_walrus_squad_minions
	if minions ~= nil then
		for _, m in ipairs(minions) do
			if m ~= nil and m:IsValid() then
				m._roge_walrus_squad_attack_turn = false
			end
		end
	end
	minion._roge_walrus_squad_attack_turn = true
end

local function RogeLittleWalrusTryAttack(inst, target, leader)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "little_walrus" then
		return false
	end
	if inst.components.health == nil or inst.components.health:IsDead() then
		return false
	end
	if target == nil or not target:IsValid() then
		return false
	end
	if inst.sg == nil then
		return false
	end
	if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack") then
		return false
	end
	local combat = inst.components.combat
	if combat == nil then
		return false
	end
	RogeGrantWalrusSquadAttackTurn(inst, leader)
	combat:SetTarget(target)
	if combat:InCooldown() then
		combat:ResetCooldown()
	end
	inst:FacePoint(target.Transform:GetWorldPosition())
	inst:PushEvent("doattack", { target = target })
	return true
end

local function RogeWalrusSquadAttackerTryAction(inst, target, leader)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if inst.prefab == "little_walrus" then
		return RogeLittleWalrusTryAttack(inst, target, leader)
	end
	return false
end

local function RogeSyncWalrusSquadTargets(leader)
	RogeSyncLeaderCombatTarget(leader)
end

local function RogeScheduleWalrusSquadRotatingAttack(leader)
	if leader == nil or not leader:IsValid() then
		return
	end
	if leader._roge_walrus_squad_attack_task ~= nil then
		leader._roge_walrus_squad_attack_task:Cancel()
		leader._roge_walrus_squad_attack_task = nil
	end
	leader._roge_walrus_squad_attack_task = leader:DoTaskInTime(ROGE_WALRUS_SQUAD_ATTACK_INTERVAL, function(l)
		l._roge_walrus_squad_attack_task = nil
		if l == nil or not l:IsValid() or l.components.health == nil or l.components.health:IsDead() then
			return
		end
		RogeSyncLeaderCombatTarget(l)
		local target = RogeResolveWalrusSquadTarget(l, l._roge_walrus_squad_fallback_target)
		local attackers = l._roge_walrus_squad_attackers
		local count = attackers ~= nil and #attackers or 0
		if target ~= nil and count > 0 then
			local idx = l._roge_walrus_squad_attack_idx or 1
			l._roge_walrus_squad_attack_idx = (idx % count) + 1
			local m = attackers[idx]
			if m ~= nil and m:IsValid() and m.components.health ~= nil and not m.components.health:IsDead() then
				RogeWalrusSquadAttackerTryAction(m, target, l)
			end
		end
		RogeScheduleWalrusSquadRotatingAttack(l)
	end)
end

local function RogeSetupWalrusSquadCombat(leader, minions, fallback_target)
	if leader == nil or not leader:IsValid() or minions == nil or #minions == 0 then
		return
	end
	leader._roge_walrus_squad_minions = minions
	leader._roge_walrus_squad_attackers = {}
	for _, m in ipairs(minions) do
		RogeRegisterWalrusSquadAttacker(leader, m)
	end
	leader._roge_walrus_squad_attack_idx = 1
	leader._roge_walrus_squad_fallback_target = fallback_target
	if leader._roge_walrus_squad_combat_setup then
		RogeSyncLeaderCombatTarget(leader)
		return
	end
	leader._roge_walrus_squad_combat_setup = true
	for _, m in ipairs(minions) do
		RogeLinkLittleWalrusToLeader(m, leader)
		RogeHookLittleWalrusSquadCombat(m)
	end
	if fallback_target ~= nil and fallback_target:IsValid() and leader.components.combat ~= nil then
		leader.components.combat:SetTarget(fallback_target)
	end
	RogeSyncLeaderCombatTarget(leader)
	leader:ListenForEvent("newcombattarget", function()
		RogeSyncLeaderCombatTarget(leader)
	end)
	leader:ListenForEvent("onattackother", function()
		RogeSyncLeaderCombatTarget(leader)
	end)
	leader:ListenForEvent("death", function(l)
		RogeWalrusSquadDeathCleanup(l)
	end)
	RogeScheduleWalrusSquadFollowCheck(leader, minions)
	RogeScheduleWalrusSquadRotatingAttack(leader)
end

function RogeSpawnWalrusSquadPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local radius = 5
	local cx = x + math.cos(angle) * radius
	local cz = z + math.sin(angle) * radius
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	local total = #ROGE_WALRUS_SQUAD_SPAWNS
	local base_angle = math.random() * 2 * PI
	local leader = nil
	local first = nil
	local minions = {}
	for i, entry in ipairs(ROGE_WALRUS_SQUAD_SPAWNS) do
		local mob = SpawnPrefab(entry.prefab)
		if mob ~= nil then
			if entry.prefab == "walrus" and leader == nil then
				mob.Transform:SetPosition(cx, y, cz)
				leader = mob
			else
				local a = base_angle + (i - 1) * (2 * PI / math.max(total, 1))
				mob.Transform:SetPosition(
					cx + math.cos(a) * ROGE_WALRUS_SQUAD_RADIUS,
					y,
					cz + math.sin(a) * ROGE_WALRUS_SQUAD_RADIUS
				)
			end
			if entry.prefab == "little_walrus" then
				table.insert(minions, mob)
			end
			if first == nil then
				first = mob
			end
			local weapon = entry.weapon
			local function ApplyMember(inst)
				if inst ~= nil and inst:IsValid() then
					RogeApplyWalrusSquadMember(inst, weapon)
				end
			end
			mob:DoTaskInTime(0, ApplyMember)
			-- 覆盖原版 1 秒后的 EquipBlowdart
			mob:DoTaskInTime(1.1, function(inst)
				if inst ~= nil and inst:IsValid() then
					RogeApplyWalrusSquadMember(inst, weapon)
					if inst.prefab == "little_walrus" and leader ~= nil and leader:IsValid() then
						RogeLinkLittleWalrusToLeader(inst, leader)
					end
				end
			end)
			if leader ~= nil and mob ~= leader and mob.prefab == "little_walrus" then
				RogeLinkLittleWalrusToLeader(mob, leader)
			end
			if target ~= nil and target:IsValid() and mob.components.combat ~= nil
				and mob.prefab == "walrus" then
				mob.components.combat:SetTarget(target)
			end
		end
	end
	if leader ~= nil then
		leader:DoTaskInTime(0, function(l)
			if l ~= nil and l:IsValid() then
				RogeSetupWalrusSquadCombat(l, minions, target)
			end
		end)
		local deer_total = #ROGE_WALRUS_SQUAD_GEM_DEER_SPAWNS
		for i, entry in ipairs(ROGE_WALRUS_SQUAD_GEM_DEER_SPAWNS) do
			local deer = SpawnPrefab(entry.prefab)
			if deer ~= nil then
				local a = base_angle + (i - 1) * (2 * PI / math.max(deer_total, 1))
				deer.Transform:SetPosition(
					cx + math.cos(a) * ROGE_WALRUS_SQUAD_GEM_DEER_RADIUS,
					y,
					cz + math.sin(a) * ROGE_WALRUS_SQUAD_GEM_DEER_RADIUS
				)
				deer:DoTaskInTime(0, function(d)
					if d ~= nil and d:IsValid() and leader ~= nil and leader:IsValid() then
						RogeSetupWalrusSquadGemDeer(d, leader, entry.name, target, entry.offset)
					end
				end)
			end
		end
	end
	return first
end

-- 小队小海象：强制走 blowdart 攻击态，而非原版 taunt_attack
AddStategraphPostInit("SGwalrus", function(sg)
	local doattack = sg.events.doattack
	if doattack ~= nil and not doattack._roge_walrus_squad_patched then
	doattack._roge_walrus_squad_patched = true
	local old_fn = doattack.fn
	doattack.fn = function(inst, data)
		if inst._roge_walrus_squad_member and inst.prefab == "little_walrus" then
			if not inst._roge_walrus_squad_attack_turn then
				return
			end
			if inst.components.health:IsDead() or inst.sg:HasStateTag("electrocute") then
				inst._roge_walrus_squad_attack_turn = false
				return
			end
			local t = inst.components.combat ~= nil and inst.components.combat.target or nil
			if t == nil or not t:IsValid() then
				inst._roge_walrus_squad_attack_turn = false
				return
			end
			if inst:IsNear(t, TUNING.WALRUS_MELEE_RANGE) then
				inst._roge_walrus_squad_attack_turn = false
				inst.sg:GoToState("attack")
			else
				inst.sg:GoToState("blowdart")
			end
			return
		end
		return old_fn(inst, data)
	end
	end

	local blowdart = sg.states.blowdart
	if blowdart ~= nil and not blowdart._roge_walrus_squad_patched then
		blowdart._roge_walrus_squad_patched = true
		local old_onenter = blowdart.onenter
		blowdart.onenter = function(inst, ...)
			if old_onenter ~= nil then
				old_onenter(inst, ...)
			end
			if inst._roge_walrus_squad_member and inst.prefab == "little_walrus" then
				inst._roge_walrus_squad_attack_turn = false
			end
		end
	end
end)

-- 宝石鹿：每 5 秒蓄力一次，下次攻击必定施法；海象小队鹿在大海象存活时不掉宝石
AddStategraphPostInit("deer", function(sg)
	local doattack = sg.events.doattack
	if doattack ~= nil and not doattack._roge_gem_attack_patched then
		doattack._roge_gem_attack_patched = true
		local old_fn = doattack.fn
		doattack.fn = function(inst, data)
			if inst.gem ~= nil
				and not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
				local target = data ~= nil and data.target or nil
				if inst._roge_walrus_squad_gem_deer then
					target = RogeWalrusSquadGetGemDeerCombatTarget(inst) or target
					if target == nil then
						return
					end
					if RogeGemDeerTryCastSpell(inst, target) then
						return
					end
					return
				end
				if target == nil and inst.components.combat ~= nil then
					target = inst.components.combat.target
				end
				if RogeGemDeerTryCastSpell(inst, target) then
					return
				end
				inst.sg:GoToState("attack", target)
				return
			end
			return old_fn(inst, data)
		end
	end

	local deercast = sg.events.deercast
	if deercast ~= nil and not deercast._roge_gem_cast_patched then
		deercast._roge_gem_cast_patched = true
		deercast.fn = function(inst)
			if inst.gem == nil or inst.components.health:IsDead() then
				return
			end
			if inst._roge_gem_deer_combat_hooked then
				if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("casting") then
					inst.sg.mem.wantstocast = true
					return
				end
				local target = inst.components.combat ~= nil and inst.components.combat.target or nil
				if inst._roge_walrus_squad_gem_deer then
					target = RogeWalrusSquadGetGemDeerCombatTarget(inst) or target
				end
				RogeGemDeerTryCastSpell(inst, target)
				return
			end
			if not inst.sg:HasStateTag("busy") then
				local targets = inst:FindCastTargets()
				if targets ~= nil and not inst.components.timer:TimerExists("deercast_cd") then
					inst.sg:GoToState("magic_pre", targets)
				end
			else
				inst.sg.mem.wantstocast = true
			end
		end
	end

	local idle = sg.states.idle
	if idle ~= nil and not idle._roge_gem_idle_cast_patched then
		idle._roge_gem_idle_cast_patched = true
		local old_onenter = idle.onenter
		idle.onenter = function(inst, playanim)
			if inst.gem ~= nil and not inst._roge_allow_unshackle then
				inst.sg.mem.wantstounshackle = nil
			end
			if inst.sg.mem.wantstocast and inst.gem ~= nil and inst._roge_gem_deer_combat_hooked then
				inst.sg.mem.wantstocast = nil
				if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("casting") then
					local target = inst.components.combat ~= nil and inst.components.combat.target or nil
					if inst._roge_walrus_squad_gem_deer then
						target = RogeWalrusSquadGetGemDeerCombatTarget(inst) or target
					end
					if RogeGemDeerTryCastSpell(inst, target) then
						return
					end
				end
			end
			if old_onenter ~= nil then
				return old_onenter(inst, playanim)
			end
		end
	end

	local unshackle = sg.events.unshackle
	if unshackle ~= nil and not unshackle._roge_walrus_squad_patched then
		unshackle._roge_walrus_squad_patched = true
		local old_fn = unshackle.fn
		unshackle.fn = function(inst)
			if inst.gem ~= nil and not inst._roge_allow_unshackle then
				inst.sg.mem.wantstounshackle = nil
				return
			end
			if inst._roge_walrus_squad_gem_locked and RogeWalrusSquadKeeperAlive(inst) then
				inst.sg.mem.wantstounshackle = nil
				return
			end
			return old_fn(inst)
		end
	end

	local death = sg.states.death
	if death ~= nil and death.timeline ~= nil and not death._roge_walrus_squad_patched then
		death._roge_walrus_squad_patched = true
		for _, te in ipairs(death.timeline) do
			if te.time == 23 * FRAMES and te.fn ~= nil then
				local old_fn = te.fn
				te.fn = function(inst)
					if inst._roge_walrus_squad_gem_locked and RogeWalrusSquadKeeperAlive(inst) then
						return
					end
					old_fn(inst)
				end
				break
			end
		end
	end
end)

local _roge_special_attacks = rawget(GLOBAL, "SPECIAL_ATTACKS_CONFIG") or {}
_roge_special_attacks["deer_red"] = { event = "doattack" }
_roge_special_attacks["deer_blue"] = { event = "doattack" }
rawset(GLOBAL, "SPECIAL_ATTACKS_CONFIG", _roge_special_attacks)

local function RogeGemDeerPerformPossessAttack(deer, target)
	if deer == nil or not deer:IsValid() or deer.gem == nil then
		return false
	end
	if deer.components.health ~= nil and deer.components.health:IsDead() then
		return false
	end
	if deer.sg == nil then
		return false
	end
	if deer.sg:HasStateTag("busy") then
		return true
	end
	if target == nil or not target:IsValid() then
		if deer.components.combat ~= nil then
			target = deer.components.combat.target
		end
	end
	if target == nil or not target:IsValid() or RogeWalrusSquadIsAlly(target) then
		return false
	end
	if deer.components.combat ~= nil then
		deer.components.combat:SetTarget(target)
		if deer.components.combat:InCooldown() then
			deer.components.combat:ResetCooldown()
		end
	end
	deer:FacePoint(target.Transform:GetWorldPosition())
	if RogeGemDeerTryCastSpell(deer, target) then
		return true
	end
	deer:PushEvent("doattack", { target = target })
	return true
end

local function RogeTryPossessedGemDeerAttack(player, target)
	if player == nil or player.Poss2 == nil or player.Poss2.Possessing == nil then
		return false
	end
	local possessed = player.Poss2.Possessing
	if possessed.prefab ~= "deer_red" and possessed.prefab ~= "deer_blue" then
		return false
	end
	return RogeGemDeerPerformPossessAttack(possessed, target)
end

local function RogeInstallGemDeerPossessAttackHooks()
	AddComponentPostInit("playercontroller", function(self)
		if self._roge_gem_deer_poss_attack_patched then
			return
		end
		self._roge_gem_deer_poss_attack_patched = true

		local _OnRemoteControllerAttackButton = self.OnRemoteControllerAttackButton
		self.OnRemoteControllerAttackButton = function(pc, attack_target, isreleased, noforce)
			if RogeTryPossessedGemDeerAttack(pc.inst, attack_target) then
				return
			end
			return _OnRemoteControllerAttackButton(pc, attack_target, isreleased, noforce)
		end

		local _DoAttackButton = self.DoAttackButton
		self.DoAttackButton = function(pc, retarget, isleftmouse)
			local target = pc:GetAttackTarget(
				TheInput:IsControlPressed(CONTROL_FORCE_ATTACK),
				retarget,
				retarget ~= pc:GetCombatTarget())
			if RogeTryPossessedGemDeerAttack(pc.inst, target) then
				return
			end
			return _DoAttackButton(pc, retarget, isleftmouse)
		end

		local _OnRemoteAttackButton = self.OnRemoteAttackButton
		self.OnRemoteAttackButton = function(pc, target, force_attack, noforce, isleftmouse, isreleased)
			if RogeTryPossessedGemDeerAttack(pc.inst, target) then
				return
			end
			return _OnRemoteAttackButton(pc, target, force_attack, noforce, isleftmouse, isreleased)
		end
	end)
end

RogeInstallGemDeerPossessAttackHooks()

AddBrainPostInit("deergemmedbrain", function(self)
	local old_onstart = self.OnStart
	self.OnStart = function(brain)
		local inst = brain.inst
		if inst._roge_walrus_squad_gem_deer then
			local function ShouldDefendLeader()
				return RogeWalrusSquadGetGemDeerCombatTarget(inst) ~= nil
			end
			local function ShouldReturnToLeader()
				if ShouldDefendLeader() then
					return false
				end
				local pos = RogeWalrusSquadGetGemDeerLeashPos(inst)
				return pos ~= nil and inst:GetDistanceSqToPoint(pos) > 49
			end
			local root = PriorityNode({
				WhileNode(function() return ShouldDefendLeader() end, "SquadGemDeerDefend",
					ActionNode(function() RogeWalrusSquadGemDeerDefend(brain.inst) end, 0.25)),
				WhileNode(function() return ShouldReturnToLeader() end, "SquadGemDeerReturn",
					Leash(brain.inst, RogeWalrusSquadGetGemDeerLeashPos, 2, 2, true)),
				Leash(brain.inst, RogeWalrusSquadGetGemDeerLeashPos, 0.5, 0.5, false),
				StandStill(brain.inst),
			}, .5)
			brain.bt = BT(inst, root)
			return
		end
		return old_onstart(brain)
	end
end)

local function RogeSetupGemDeerPostInit(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function(d)
		if d ~= nil and d:IsValid() then
			RogeHookGemDeerCombat(d)
		end
	end)
end

AddPrefabPostInit("deer_red", RogeSetupGemDeerPostInit)
AddPrefabPostInit("deer_blue", RogeSetupGemDeerPostInit)

RogeInstallWalrusSquadSafeHighlight()
