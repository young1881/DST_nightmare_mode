TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE = 25            --蒸馏复仇反伤伤害
TUNING.GHOSTLYELIXIR_SLOWREGEN_HEALING = 4.5            --亡者补药回复血量
TUNING.ABIGAIL_DMG_PERIOD = 1.5                         --阿比的攻速
TUNING.ABIGAIL_GESTALT_SPEED_MULT = 1.2                 --虚影（月灵）阿比盖尔移速 = 原版 × 1.2（+20%）
TUNING.ABIGAIL_VEX_GHOSTLYFRIEND_DAMAGE_MOD = 2.6       --温蒂受易伤buff的加成
TUNING.ABIGAIL_VEX_DURATION = 6                         --易伤效果持续时间

TUNING.WENDYSKILL_COMMAND_COOLDOWN = 2                  --轮盘技能总cd
TUNING.WENDYSKILL_GESTALT_ATTACKAT_COMMAND_COOLDOWN = 5 --冲刺技能cd
TUNING.WENDYSKILL_ESCAPE_TIME = 3.5                     --逃离技能持续时间
TUNING.WENDYSKILL_DASHATTACK_VELOCITY = 15.0            --冲刺速度
TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MIN_MULT = 0.3  --冲刺连击对同一目标伤害最低保留 30%
-- TUNING.WENDYSKILL_DASHATTACK_HITRATE = 0.5        --冲刺时攻速？

TUNING.WENDYSKILL_SMALLGHOST_EXTRACHANCE = 0.95               --小惊吓的概率
TUNING.ABIGAIL_GESTALT_DAMAGE.day = 120                       -- 月阿比白天的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.dusk = 160                      -- 月阿比黄昏的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.night = 280                     -- 月夜晚的伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS_GESTALT = 150 -- 光之怒：月阿比盖尔位面伤害加成
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS = 150         -- 光之怒：阿比盖尔位面伤害加成
TUNING.SKILLS.WENDY.LUNARELIXIR_DURATION = 2000000            -- 光之怒的持续时间
TUNING.SKILLS.WENDY.SHADOWELIXIR_DURATION = 8 * TUNING.SEG_TIME -- 诅咒之苦：4 分钟

--光之怒
Recipe2("ghostlyelixir_lunar",
	{ Ingredient("thulecite_pieces", 6), Ingredient("purebrilliance", 2), Ingredient("ghostflower", 3) }, TECH.NONE_TWO,
	{ builder_tag = "ghostlyfriend" }, { "CHARACTER" })

--哀悼荣耀"
AddRecipe2("ghostflower", { Ingredient("moon_cap", 1), Ingredient("moonglass", 1) }, TECH.NONE_TWO,
	{ builder_tag = "ghostlyfriend" }, { "CHARACTER" })

--诅咒之苦：1 铥矿徽章 + 1 纯粹恐惧 + 2 哀悼荣耀
AddRecipePostInit("ghostlyelixir_shadow", function(recipe)
	recipe.ingredients = {
		Ingredient("nightmare_timepiece", 1),
		Ingredient("horrorfuel", 1),
		Ingredient("ghostflower", 2),
	}
end)

----------------------------------------------------------------------
-- 暗影阵营 I（wendy_shadow_1）：恐惧→嘲讽；5% 吸血；伤害 -1/3；生命上限 800
-- 诅咒之苦（ghostlyelixir_shadow）期间吸血提升至 15%
----------------------------------------------------------------------
local WENDY_SHADOW_ALLEGIANCE_1 = "wendy_shadow_1"
local NM_ABIGAIL_SHADOW_LIFESTEAL = 0.05
local NM_ABIGAIL_SHADOW_LIFESTEAL_ELIXIR = 0.15
local NM_ABIGAIL_SHADOW_DAMAGE_MULT = 2 / 3
local NM_ABIGAIL_SHADOW_MAX_HEALTH = 800

----------------------------------------------------------------------
-- 诅咒之苦（ghostlyelixir_shadow）：温蒂/阿比盖尔击杀各 +1.5s 三级暗影加强（上限 60s）；解锁承伤时的护盾反击
----------------------------------------------------------------------
local NM_SHADOW_ELIXIR_MURDER_STACK = 1.5
local NM_SHADOW_ELIXIR_MURDER_MAX = 60

----------------------------------------------------------------------
-- 阿比盖尔承伤：Shift+R 开关；各承担 50% 伤害（护盾反击需诅咒之苦）
----------------------------------------------------------------------
local NM_ABIGAIL_DAMAGE_SHARE_MULT = 0.5
local NM_ABIGAIL_DAMAGE_SHARE_RPC = "wendy_toggle_abigail_damage_share"
local NM_SHADOW_ELIXIR_SHIELD_CD = 5
local NM_SHADOW_ELIXIR_SHIELD_RADIUS = 3
local NM_SHADOW_ELIXIR_SHIELD_RADIUS_SQ = NM_SHADOW_ELIXIR_SHIELD_RADIUS * NM_SHADOW_ELIXIR_SHIELD_RADIUS
local NM_SHADOW_ELIXIR_SHIELD_FX_SCALE = 2.2
local NM_SHADOW_ELIXIR_SHIELD_SOUND_VOLUME = 2
local NM_SHADOW_ELIXIR_SHIELD_REPEL_SPEED = 45
local NM_SHADOW_ELIXIR_SHIELD_REPEL_ACCEL = 3.5
local NM_SHADOW_ELIXIR_SHIELD_REPEL_ACCEL_GROW = 0.4
local NM_SHADOW_ELIXIR_SHIELD_REPEL_DURATION = 18 * FRAMES
local NM_SHADOW_ELIXIR_SHIELD_PHYS_DAMAGE = 50
local NM_SHADOW_ELIXIR_SHIELD_PLANAR_DAMAGE = 25
local NM_SHADOW_ELIXIR_SHIELD_REPEL_MUST_TAGS = { "locomotor" }
local NM_SHADOW_ELIXIR_SHIELD_REPEL_CANT_TAGS = { "fossil", "shadow", "playerghost", "INLIMBO", "companion" }

local function NM_AbigailHasShadowElixirBuff(abigail)
	if abigail == nil or not abigail:IsValid() then
		return false
	end
	local debuff = abigail:GetDebuff("super_elixir_buff")
	return debuff ~= nil and debuff.prefab == "ghostlyelixir_shadow_buff"
end

local function NM_StackShadowMurderBuff(abigail)
	if not NM_AbigailHasShadowElixirBuff(abigail) then
		return
	end
	if abigail.components.health == nil or abigail.components.health:IsDead() then
		return
	end

	local x, y, z = abigail.Transform:GetWorldPosition()
	SpawnPrefab("abigail_attack_shadow_fx").Transform:SetPosition(x, y, z)
	local fx = SpawnPrefab("abigail_shadow_buff_fx")
	abigail:AddChild(fx)

	if not abigail:HasDebuff("abigail_murder_buff") then
		abigail:AddDebuff("abigail_murder_buff", "abigail_murder_buff")
	end

	local murder_buff = abigail:GetDebuff("abigail_murder_buff")
	if murder_buff == nil or murder_buff.murder_buff_OnExtended == nil then
		return
	end

	local time = murder_buff.decaytimer ~= nil and GetTaskRemaining(murder_buff.decaytimer) or 0
	murder_buff:murder_buff_OnExtended(math.min(time + NM_SHADOW_ELIXIR_MURDER_STACK, NM_SHADOW_ELIXIR_MURDER_MAX))
end

local function NM_GetAbigailForShadowElixirKill(killer)
	if killer == nil or not killer:IsValid() then
		return nil
	end
	if killer.prefab == "abigail" then
		return killer
	end
	if killer.prefab == "wendy" and killer.components.ghostlybond ~= nil then
		return killer.components.ghostlybond.ghost
	end
	return nil
end

local function NM_OnShadowElixirKill(killer, data)
	local victim = data ~= nil and data.victim or nil
	if victim == nil or victim.components.health == nil then
		return
	end
	local abigail = NM_GetAbigailForShadowElixirKill(killer)
	if abigail ~= nil then
		NM_StackShadowMurderBuff(abigail)
	end
end

local function NM_WendyHasAbigailDamageShareEnabled(wendy)
	return wendy ~= nil and wendy:IsValid() and wendy._nm_abigail_damage_share == true
end

local function NM_WendyHasAbigailAvailable(wendy)
	if wendy == nil or not wendy:IsValid() or wendy.components.ghostlybond == nil then
		return false
	end
	local abigail = wendy.components.ghostlybond.ghost
	if abigail == nil or abigail:IsInLimbo() then
		return false
	end
	if abigail.components.health == nil or abigail.components.health:IsDead() then
		return false
	end
	return true
end

local function NM_WendyShouldShareAbigailDamage(wendy)
	if not NM_WendyHasAbigailDamageShareEnabled(wendy) then
		return false
	end
	return NM_WendyHasAbigailAvailable(wendy)
end

local function NM_IsShadowElixirShieldTarget(wendy, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target == wendy or target.prefab == "abigail" or target.prefab == "wendy" then
		return false
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return false
	end
	return target.entity:IsVisible()
end

local function NM_UpdateShadowElixirShieldRepel(inst, x, z, creatures)
	for i = #creatures, 1, -1 do
		local v = creatures[i]
		if not (v.inst:IsValid() and v.inst.entity:IsVisible()) then
			table.remove(creatures, i)
		elseif v.speed == nil then
			local distsq = v.inst:GetDistanceSqToPoint(x, 0, z)
			if distsq < NM_SHADOW_ELIXIR_SHIELD_RADIUS_SQ then
				if distsq > 0 then
					v.inst:ForceFacePoint(x, 0, z)
				end
				local k = .5 * distsq / NM_SHADOW_ELIXIR_SHIELD_RADIUS_SQ - 1
				v.speed = NM_SHADOW_ELIXIR_SHIELD_REPEL_SPEED * k
				v.dspeed = NM_SHADOW_ELIXIR_SHIELD_REPEL_ACCEL
				v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
			end
		else
			v.speed = v.speed + v.dspeed
			if v.speed < 0 then
				local x1, _, z1 = v.inst.Transform:GetWorldPosition()
				if x1 ~= x or z1 ~= z then
					v.inst:ForceFacePoint(x, 0, z)
				end
				v.dspeed = v.dspeed + NM_SHADOW_ELIXIR_SHIELD_REPEL_ACCEL_GROW
				v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
			else
				v.inst.Physics:ClearMotorVelOverride()
				v.inst.Physics:Stop()
				table.remove(creatures, i)
			end
		end
	end
end

local function NM_TimeoutShadowElixirShieldRepel(inst, creatures, task)
	task:Cancel()
	for _, v in ipairs(creatures) do
		if v.speed ~= nil then
			v.inst.Physics:ClearMotorVelOverride()
			v.inst.Physics:Stop()
		end
	end
end

local function NM_SpawnStalkerShieldAura(parent, duration)
	if parent == nil or not parent:IsValid() then
		return
	end

	local shield_fx = SpawnPrefab("stalker_shield4")
	if shield_fx == nil then
		return
	end

	shield_fx:CancelAllPendingTasks()
	if shield_fx.SoundEmitter ~= nil then
		shield_fx.SoundEmitter:KillAllSounds()
	end
	local scale = NM_SHADOW_ELIXIR_SHIELD_FX_SCALE
	shield_fx.AnimState:SetScale(scale, scale, scale)
	shield_fx.entity:SetParent(parent.entity)
	parent:DoTaskInTime(duration or 1, function()
		if shield_fx:IsValid() then
			shield_fx:Remove()
		end
	end)
end

local function NM_DoShadowElixirShieldBurst(wendy)
	if wendy == nil or not wendy:IsValid() then
		return
	end

	NM_SpawnStalkerShieldAura(wendy, 1)

	if wendy.SoundEmitter ~= nil then
		wendy.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/shield", "nm_shadow_shield_burst")
		wendy.SoundEmitter:SetVolume("nm_shadow_shield_burst", NM_SHADOW_ELIXIR_SHIELD_SOUND_VOLUME)
	end

	local x, y, z = wendy.Transform:GetWorldPosition()
	local creatures = {}
	local spdamage = { planar = NM_SHADOW_ELIXIR_SHIELD_PLANAR_DAMAGE }
	for _, v in ipairs(TheSim:FindEntities(x, y, z, NM_SHADOW_ELIXIR_SHIELD_RADIUS,
		NM_SHADOW_ELIXIR_SHIELD_REPEL_MUST_TAGS, NM_SHADOW_ELIXIR_SHIELD_REPEL_CANT_TAGS)) do
		if NM_IsShadowElixirShieldTarget(wendy, v) then
			if v:HasTag("player") then
				v:PushEvent("repelled", { repeller = wendy, radius = NM_SHADOW_ELIXIR_SHIELD_RADIUS })
			elseif v.components.combat ~= nil then
				v.components.combat:GetAttacked(wendy, NM_SHADOW_ELIXIR_SHIELD_PHYS_DAMAGE, nil, nil, spdamage)
				if v.Physics ~= nil then
					table.insert(creatures, { inst = v })
				end
			end
		end
	end

	if #creatures > 0 then
		wendy:DoTaskInTime(NM_SHADOW_ELIXIR_SHIELD_REPEL_DURATION, NM_TimeoutShadowElixirShieldRepel, creatures,
			wendy:DoPeriodicTask(0, NM_UpdateShadowElixirShieldRepel, nil, x, z, creatures))
	end
end

local function NM_TryShadowElixirShieldBurst(wendy)
	if wendy == nil or not wendy:IsValid() or wendy.components.ghostlybond == nil then
		return
	end
	local abigail = wendy.components.ghostlybond.ghost
	if not NM_AbigailHasShadowElixirBuff(abigail) then
		return
	end
	local now = GetTime()
	if wendy._nm_shadow_elixir_shield_time ~= nil
		and now - wendy._nm_shadow_elixir_shield_time < NM_SHADOW_ELIXIR_SHIELD_CD then
		return
	end
	wendy._nm_shadow_elixir_shield_time = now
	NM_DoShadowElixirShieldBurst(wendy)
end

local function NM_ApplyAbigailDamageShare(wendy, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	if amount >= 0 or not NM_WendyShouldShareAbigailDamage(wendy) then
		return amount
	end

	local abigail = wendy.components.ghostlybond.ghost
	local shared = amount * NM_ABIGAIL_DAMAGE_SHARE_MULT
	abigail.components.health:DoDelta(shared, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	NM_TryShadowElixirShieldBurst(wendy)
	return shared
end

local function NM_PatchWendyAbigailDamageShare(wendy)
	if wendy._nm_abigail_damage_share_patched or wendy.components.health == nil then
		return
	end
	wendy._nm_abigail_damage_share_patched = true
	wendy._nm_abigail_damage_share = wendy._nm_abigail_damage_share == true

	local health = wendy.components.health
	local old_redirect = health.redirect
	health.redirect = function(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		if amount < 0 and NM_WendyShouldShareAbigailDamage(inst) then
			return false
		end
		return old_redirect ~= nil
			and old_redirect(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
			or false
	end

	local old_deltamodifier = health.deltamodifierfn
	health.deltamodifierfn = function(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		amount = NM_ApplyAbigailDamageShare(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		if old_deltamodifier ~= nil then
			amount = old_deltamodifier(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		end
		return amount
	end
end

local function NM_ToggleAbigailDamageShare(wendy)
	if wendy == nil or not wendy:IsValid() or wendy.prefab ~= "wendy" then
		return
	end

	local talker = wendy.components.talker
	local enabling = not NM_WendyHasAbigailDamageShareEnabled(wendy)

	if enabling then
		if not NM_WendyHasAbigailAvailable(wendy) then
			if talker ~= nil then
				talker:Say("对不起...应该让你休息一下的")
			end
			return
		end
		wendy._nm_abigail_damage_share = true
		if talker ~= nil then
			talker:Say("保护我，阿比盖尔")
		end
	else
		wendy._nm_abigail_damage_share = false
		if talker ~= nil then
			talker:Say("谢谢你阿比盖尔，该我来了")
		end
	end
end

AddModRPCHandler("my_mod", NM_ABIGAIL_DAMAGE_SHARE_RPC, function(wendy)
	if not TheWorld.ismastersim then
		return
	end
	NM_ToggleAbigailDamageShare(wendy)
end)

if GLOBAL.TheInput ~= nil then
	GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
		if GLOBAL.ThePlayer ~= nil
			and GLOBAL.ThePlayer.prefab == "wendy"
			and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
			SendModRPCToServer(MOD_RPC["my_mod"][NM_ABIGAIL_DAMAGE_SHARE_RPC])
		end
	end)
end
local NM_GHOST_TAUNT_LABEL = "嘲讽"
local NM_GHOST_SCARE_RADIUS = 4 * TILE_SCALE
local NM_GHOST_SCARE_MUST_TAGS = { "_combat", "_health" }
local NM_GHOST_SCARE_CANT_TAGS = { "balloon", "butterfly", "companion", "epic", "groundspike", "INLIMBO", "smashable", "structure", "wall" }

local function WendyHasShadowAllegiance1(wendy)
	if wendy == nil or not wendy:IsValid() then
		return false
	end
	local skilltree = wendy.components.skilltreeupdater
	return skilltree ~= nil and skilltree:IsActivated(WENDY_SHADOW_ALLEGIANCE_1)
end

local function AbigailWendyHasShadowAllegiance1(abigail)
	local wendy = abigail ~= nil and abigail._playerlink or nil
	return WendyHasShadowAllegiance1(wendy)
end

local function NM_IsFriendlyToWendy(wendy, target, pvp_enabled)
	if wendy == nil or target == nil then
		return true
	end
	if pvp_enabled == nil then
		pvp_enabled = TheNet:GetPVPEnabled()
	end
	local target_leader = target.components.follower ~= nil and target.components.follower.leader or nil
	if target_leader ~= nil and target_leader.components.inventoryitem ~= nil then
		target_leader = target_leader.components.inventoryitem:GetGrandOwner()
	end
	if target_leader == wendy then
		return true
	end
	if not pvp_enabled and target_leader ~= nil and target_leader.isplayer then
		return true
	end
	if not pvp_enabled and target.components.domesticatable ~= nil and target.components.domesticatable:IsDomesticated() then
		return true
	end
	if not pvp_enabled and target.components.saltlicker ~= nil and target.components.saltlicker.salted then
		return true
	end
	return false
end

local function DoGhostTaunt(abigail)
	if (abigail.sg and abigail.sg:HasStateTag("nocommand"))
		or (abigail.components.health and abigail.components.health:IsDead()) then
		return
	end

	local wendy = abigail._playerlink
	local pvp_enabled = TheNet:GetPVPEnabled()
	local x, y, z = abigail.Transform:GetWorldPosition()
	local targets_near_me = TheSim:FindEntities(x, y, z, NM_GHOST_SCARE_RADIUS, NM_GHOST_SCARE_MUST_TAGS, NM_GHOST_SCARE_CANT_TAGS)
	for _, target in ipairs(targets_near_me) do
		if abigail.components.combat:CanTarget(target)
			and not NM_IsFriendlyToWendy(wendy, target, pvp_enabled)
			and (not target:HasTag("prey") or target:HasTag("hostile"))
			and target.components.combat ~= nil
			and target.components.combat:CanTarget(abigail) then
			if target.components.hauntable ~= nil then
				target.components.hauntable.panic = false
				target.components.hauntable.panictimer = 0
			end
			target.components.combat:SetTarget(abigail)
		end
	end
end

local function NM_GetAbigailShadowLifestealRate(abigail)
	if NM_AbigailHasShadowElixirBuff(abigail) then
		return NM_ABIGAIL_SHADOW_LIFESTEAL_ELIXIR
	end
	return NM_ABIGAIL_SHADOW_LIFESTEAL
end

local function NM_GetAbigailShadowDamageDealt(data)
	if data == nil then
		return 0
	end
	local dealt = data.damageresolved
	if dealt ~= nil and type(dealt) == "number" and dealt > 0 then
		return dealt
	end
	dealt = data.damage
	if dealt ~= nil and type(dealt) == "number" and dealt > 0 then
		return dealt
	end
	return 0
end

local function AbigailShadowLifestealOnHit(abigail, data)
	if not AbigailWendyHasShadowAllegiance1(abigail) then
		return
	end
	if data == nil or data.redirected ~= nil then
		return
	end
	local dealt = NM_GetAbigailShadowDamageDealt(data)
	if dealt <= 0 then
		return
	end
	if abigail.components.health == nil then
		return
	end
	local heal = dealt * NM_GetAbigailShadowLifestealRate(abigail)
	if heal > 0 then
		abigail.components.health:DoDelta(heal, false, "nm_abigail_shadow_lifesteal")
	end
end

local function NM_GetAbigailBondMaxHealth(abigail)
	local wendy = abigail._playerlink
	local level = wendy ~= nil and wendy.components.ghostlybond ~= nil and wendy.components.ghostlybond.bondlevel or 1
	if level == 3 then
		return TUNING.ABIGAIL_HEALTH_LEVEL3
	elseif level == 2 then
		return TUNING.ABIGAIL_HEALTH_LEVEL2
	end
	return TUNING.ABIGAIL_HEALTH_LEVEL1
end

local function NM_RefreshShadowAbigailMaxHealth(abigail)
	if abigail.components.health == nil then
		return
	end

	if not AbigailWendyHasShadowAllegiance1(abigail) then
		return
	end

	local bond_max = NM_GetAbigailBondMaxHealth(abigail)
	local target_base = math.min(bond_max, NM_ABIGAIL_SHADOW_MAX_HEALTH)
	abigail.base_max_health = target_base

	local bonus = abigail.bonus_max_health or 0
	local max_total = target_base + bonus
	if max_total > NM_ABIGAIL_SHADOW_MAX_HEALTH then
		abigail.bonus_max_health = math.max(0, NM_ABIGAIL_SHADOW_MAX_HEALTH - target_base)
	end

	local health = abigail.components.health
	local pct = health:GetPercent()
	health:SetMaxHealth(abigail.base_max_health + abigail.bonus_max_health)
	health:SetPercent(pct, true)

	local wendy = abigail._playerlink
	if wendy ~= nil and wendy.components.pethealthbar ~= nil then
		wendy.components.pethealthbar:SetMaxHealth(health.maxhealth)
	end
end

local function NM_LinkAbigailShadowRefresh(abigail, wendy)
	if abigail._nm_shadow_refresh_linked or wendy == nil then
		return
	end
	abigail._nm_shadow_refresh_linked = true
	local refresh = function()
		if abigail:IsValid() then
			NM_RefreshShadowAbigailMaxHealth(abigail)
			if abigail.UpdateDamage ~= nil then
				abigail:UpdateDamage(TheWorld.state.phase)
			end
		end
	end
	abigail:ListenForEvent("onactivateskill_server", refresh, wendy)
	abigail:ListenForEvent("ondeactivateskill_server", refresh, wendy)
	abigail:ListenForEvent("ghostlybond_level_change", refresh, wendy)
	abigail:ListenForEvent("pethealthbar_bonuschange", refresh)
end

local function NM_PatchAbigailShadowStats(abigail)
	if abigail._nm_shadow_stats_patched then
		NM_LinkAbigailShadowRefresh(abigail, abigail._playerlink)
		NM_RefreshShadowAbigailMaxHealth(abigail)
		if abigail.UpdateDamage ~= nil then
			abigail:UpdateDamage(TheWorld.state.phase)
		end
		return
	end
	abigail._nm_shadow_stats_patched = true

	if abigail.UpdateDamage ~= nil then
		local old_update = abigail.UpdateDamage
		abigail.UpdateDamage = function(inst, phase)
			old_update(inst, phase)
			if AbigailWendyHasShadowAllegiance1(inst) and inst.components.combat ~= nil then
				inst.components.combat.defaultdamage = inst.components.combat.defaultdamage * NM_ABIGAIL_SHADOW_DAMAGE_MULT
			end
		end
	end

	NM_LinkAbigailShadowRefresh(abigail, abigail._playerlink)
	NM_RefreshShadowAbigailMaxHealth(abigail)
	if abigail.UpdateDamage ~= nil then
		abigail:UpdateDamage(TheWorld.state.phase)
	end
end

local function NM_WrapAbigailPushEvent(abigail)
	if abigail._nm_push_event_patched then
		return
	end
	abigail._nm_push_event_patched = true
	local old_push = abigail.PushEvent
	abigail.PushEvent = function(self, event, data)
		if event == "do_ghost_scare" and AbigailWendyHasShadowAllegiance1(self) then
			return old_push(self, "do_ghost_taunt", data)
		end
		return old_push(self, event, data)
	end
end

local function NM_CloneGhostCommand(cmd, label)
	if cmd == nil then
		return nil
	end
	local copy = shallowcopy(cmd)
	copy.label = label
	if copy.onselect ~= nil then
		local old_onselect = copy.onselect
		copy.onselect = function(inst)
			old_onselect(inst)
			if inst.components.spellbook ~= nil then
				inst.components.spellbook:SetSpellName(label)
			end
		end
	end
	return copy
end

local function PatchGhostCommandDefsForTaunt()
	local ok, defs = pcall(require, "prefabs/ghostcommand_defs")
	if not ok or defs == nil or defs._nm_taunt_patched then
		return
	end
	defs._nm_taunt_patched = true

	local old_get = defs.GetGhostCommandsFor
	defs.GetGhostCommandsFor = function(owner)
		local commands = old_get(owner)
		if not WendyHasShadowAllegiance1(owner) then
			return commands
		end

		local scare_label = STRINGS.GHOSTCOMMANDS ~= nil and STRINGS.GHOSTCOMMANDS.SCARE or nil
		for i, cmd in ipairs(commands) do
			if cmd.label == scare_label or (cmd.anims ~= nil and cmd.anims.idle ~= nil and cmd.anims.idle.anim == "scare") then
				commands[i] = NM_CloneGhostCommand(cmd, NM_GHOST_TAUNT_LABEL)
				break
			end
		end
		return commands
	end
end

AddSimPostInit(PatchGhostCommandDefsForTaunt)

----------------------------------------------------------------------
-- 虚影（月灵）阿比盖尔移速加成
----------------------------------------------------------------------
local function NightmareAbigailStoreBaseLocomotor(inst)
	local loc = inst.components.locomotor
	if loc == nil or inst._nm_abigail_base_walk ~= nil then
		return
	end
	inst._nm_abigail_base_walk = loc.walkspeed
	inst._nm_abigail_base_run = loc.runspeed
end

local function NightmareAbigailApplyGestaltStats(inst)
	if not inst:HasTag("gestalt") then
		return
	end
	NightmareAbigailStoreBaseLocomotor(inst)
	local loc = inst.components.locomotor
	if loc ~= nil then
		local sm = TUNING.ABIGAIL_GESTALT_SPEED_MULT or 1.2
		loc.walkspeed = inst._nm_abigail_base_walk * sm
		loc.runspeed = inst._nm_abigail_base_run * sm
	end
end

local function NightmareAbigailRestoreNormalStats(inst)
	if inst:HasTag("gestalt") then
		return
	end
	NightmareAbigailStoreBaseLocomotor(inst)
	local loc = inst.components.locomotor
	if loc ~= nil and inst._nm_abigail_base_walk ~= nil then
		loc.walkspeed = inst._nm_abigail_base_walk
		loc.runspeed = inst._nm_abigail_base_run
	end
end

local function NightmareAbigailPatchGestalt(inst)
	if inst._nm_gestalt_stats_patched then
		return
	end
	inst._nm_gestalt_stats_patched = true

	if inst.LinkToPlayer ~= nil then
		local old_link = inst.LinkToPlayer
		inst.LinkToPlayer = function(i, player, ...)
			old_link(i, player, ...)
			NM_LinkAbigailShadowRefresh(i, player)
			NM_RefreshShadowAbigailMaxHealth(i)
			if i.UpdateDamage ~= nil then
				i:UpdateDamage(TheWorld.state.phase)
			end
		end
	end
	if inst.ChangeToGestalt ~= nil then
		local old_change = inst.ChangeToGestalt
		inst.ChangeToGestalt = function(i, togestalt, ...)
			old_change(i, togestalt, ...)
			if togestalt then
				NightmareAbigailApplyGestaltStats(i)
			else
				NightmareAbigailRestoreNormalStats(i)
			end
		end
	end
	inst:ListenForEvent("gestalt_mutate", function(i, data)
		if data ~= nil and data.gestalt then
			NightmareAbigailApplyGestaltStats(i)
		else
			NightmareAbigailRestoreNormalStats(i)
		end
	end)
	inst:ListenForEvent("exitlimbo", function(i)
		if i:HasTag("gestalt") then
			NightmareAbigailApplyGestaltStats(i)
		end
	end)

	if inst:HasTag("gestalt") then
		NightmareAbigailApplyGestaltStats(inst)
	end
end

-- 虚影阿比盖尔：对有位面抗性（planardefense / planarentity）的目标额外造成位面伤害（参考鹿人形态位面拳思路）
local NM_GESTALT_EXTRA_PLANAR_VS_DEFENSE = 50

local function NightmareTargetHasPlanarResistance(target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target.components.planarentity ~= nil then
		return true
	end
	if target.components.planardefense ~= nil and target.components.planardefense:GetDefense() > 0 then
		return true
	end
	return false
end

local function NightmareAbigailPatchGestaltPlanarBonus(Combat)
	if Combat == nil or Combat._nm_gestalt_planar_CalcDamage then
		return
	end
	local _CalcDamage = Combat.CalcDamage
	Combat._nm_gestalt_planar_CalcDamage = true
	function Combat:CalcDamage(target, weapon, multiplier)
		local damage, spdamage = _CalcDamage(self, target, weapon, multiplier)
		local inst = self.inst
		if inst ~= nil and inst:IsValid() and inst.prefab == "abigail" and inst:HasTag("gestalt")
			and NightmareTargetHasPlanarResistance(target) then
			spdamage = spdamage or {}
			spdamage.planar = (spdamage.planar or 0) + NM_GESTALT_EXTRA_PLANAR_VS_DEFENSE
		end
		return damage, spdamage
	end
end

AddClassPostConstruct("components/combat", NightmareAbigailPatchGestaltPlanarBonus)

local function NightmareAbigailRefreshLunarElixirPlanarBonus(inst)
	if inst.components.debuffable == nil or inst.components.planardamage == nil then
		return
	end
	local buff = inst.components.debuffable:GetDebuff("super_elixir_buff")
	if buff == nil or buff.prefab ~= "ghostlyelixir_lunar_buff" then
		return
	end
	inst.components.planardamage:RemoveBonus(buff, "ghostlyelixir_lunarbonus")
	local bonus = inst:HasTag("gestalt")
		and TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS_GESTALT
		or TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS
	inst.components.planardamage:AddBonus(buff, bonus, "ghostlyelixir_lunarbonus")
end

-- 光之怒：对阿比盖尔使用即可转化为月亮阿比盖尔（不再依赖月晷与月相）
local function NightmareTryGestaltFromLunarElixir(abigail)
	if abigail == nil or not abigail:IsValid() or abigail.prefab ~= "abigail" then
		return
	end
	if abigail.ChangeToGestalt ~= nil and not abigail:HasTag("gestalt") then
		abigail:ChangeToGestalt(true)
	end
end

AddPrefabPostInit("ghostlyelixir_lunar", function(inst)
	if not TheWorld.ismastersim or inst.components.ghostlyelixir == nil then
		return
	end
	local elixir = inst.components.ghostlyelixir
	local old_apply = elixir.doapplyelixerfn
	if old_apply == nil then
		return
	end
	elixir.doapplyelixerfn = function(elixir_inst, giver, target)
		local result = old_apply(elixir_inst, giver, target)
		if result ~= nil and result ~= false and target ~= nil and target:IsValid() then
			NightmareTryGestaltFromLunarElixir(target)
			if target:IsValid() then
				target:DoTaskInTime(0, NightmareAbigailApplyGestaltStats)
			end
		end
		return result
	end
end)

AddPrefabPostInit("ghostlyelixir_shadow_buff", function(inst)
	if not TheWorld.ismastersim or inst.potion_tunings == nil then
		return
	end
	inst.potion_tunings.DURATION = TUNING.SKILLS.WENDY.SHADOWELIXIR_DURATION
	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("decay")
		inst.components.timer:StartTimer("decay", inst.potion_tunings.DURATION)
	end
end)

AddPrefabPostInit("abigail", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddTag("crazy")
	local function OnKill(inst, data)
		local victim = data.victim
		NM_OnShadowElixirKill(inst, data)
		if victim and (victim:HasTag("shadow") or victim.prefab == "dreadeye") then
			if inst._playerlink and (victim.sanityreward or victim.prefab == "dreadeye") then
				inst._playerlink.components.sanity:DoDelta(10)
				if victim.prefab == "dreadeye" then
					inst._playerlink.components.sanity:DoDelta(10) --死亡之眼回20理智
				end
			end
			local x, y, z = inst.Transform:GetWorldPosition() --杀死任意影怪时吸引全场影怪仇恨
			local ents = TheSim:FindEntities(x, y, z, 40)
			for k, v in pairs(ents) do
				if v:HasTag("shadow") and v.components.combat then
					v.components.combat:SetTarget(inst)
				end
			end
		end
	end
	inst:AddComponent("sanityaura") --温蒂靠近阿比恢复理智
	inst.components.sanityaura.aurafn = function(inst, observer)
		if observer.prefab == "wendy" then
			return TUNING.SANITYAURA_SMALL
		end
		return 0
	end
	inst:ListenForEvent("killed", OnKill)
	inst:ListenForEvent("do_ghost_taunt", DoGhostTaunt)
	inst:ListenForEvent("onhitother", AbigailShadowLifestealOnHit)
	NM_WrapAbigailPushEvent(inst)
	inst:DoTaskInTime(0, NM_PatchAbigailShadowStats)
	inst:DoTaskInTime(0, NightmareAbigailPatchGestalt)
end)

AddPrefabPostInit("wendy", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:DoTaskInTime(0, NM_PatchWendyAbigailDamageShare)
	inst:ListenForEvent("killed", NM_OnShadowElixirKill)
end)

TUNING.ABIGAIL_HEALTH = 1000
TUNING.ABIGAIL_HEALTH_LEVEL1 = 250
TUNING.ABIGAIL_HEALTH_LEVEL2 = 500
TUNING.ABIGAIL_HEALTH_LEVEL3 = 1000
TUNING.ABIGAIL_DAMAGE =
{
	day = 28,
	dusk = 36,
	night = 49,
}


--阿比盖尔的位面伤害和实体位面抗性
AddPrefabPostInit("abigail", function(inst)
	inst:AddComponent("planarentity")

	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
	end
	inst.components.planardamage:SetBaseDamage(5)
	if TheWorld.ismastersim then
		inst:DoTaskInTime(0, function(i)
			if i:IsValid() then
				NightmareAbigailRefreshLunarElixirPlanarBonus(i)
			end
		end)
	end
end)

GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})

local containers = require("containers")
local params = containers.params

params.abigail = {
	widget = {
		slotpos = {},
		animbank = "ui_elixir_container_3x3",
		animbuild = "ui_elixir_container_3x3",
		pos = Vector3(300, -70, 0) -- 容器显示的位置，经测试，(0,0)位置就是被添加对象的位置，比如这里是把这个容器添加到阿比盖尔身上，所以容器出现位置的原点就是阿比盖尔所在位置，左上为正，右下为负
	},
	type = "abigail",
	openlimit = 1,
	itemtestfn = function(inst, item, slot) -- 容器里可以装的物品的条件
		return not item:HasTag("_container") and not item:HasTag("bundle") and item.prefab ~= "abigail_flower"
	end
}
-- 循环小格子
for y = 2, 0, -1 do
	for x = 0, 2 do
		table.insert(params.abigail.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80))
		table.insert(params.abigail.widget.slotpos, elixir_container)
	end
end

local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
end

AddPrefabPostInit("abigail", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("container") --容器标签
	inst.components.container:WidgetSetup("abigail")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst:ListenForEvent("death", function(inst)
		if inst.components.container then
			inst.components.container:DropEverything()
		end
	end)
end)



local function getidleanim(inst) --月亮阿比相关
	if not inst.components.timer:TimerExists("flicker_cooldown") and
		TheWorld.components.sisturnregistry and
		TheWorld.components.sisturnregistry:IsBlossom() and
		math.random() < 0.2 and
		not inst.components.debuffable:HasDebuff("abigail_murder_buff") then
		inst.components.timer:StartTimer("flicker_cooldown", math.random() * 20 + 10)

		return "idle_abigail_flicker"
	end

	return (inst._is_transparent and "abigail_escape_loop")
		or (inst.components.aura.applying and "attack_loop")
		or (inst.is_defensive and math.random() < 0.1 and "idle_custom")
		or "idle"
end

-- 月光阿比盖尔冲刺连击：沿用原版递减，但单次伤害不低于初始值的 30%
local GESTALT_ATTACKAT_RADIUS_PADDING = 2
local GESTALT_DASH_ATTACK_MUST_TAGS = { "_combat", "_health" }
local NM_REGISTERED_GESTALT_DASH_ATTACK_TAGS = TheSim:RegisterFindTags(GESTALT_DASH_ATTACK_MUST_TAGS,
	{ "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "companion", "player", "wall" })
local NM_REGISTERED_GESTALT_DASH_ATTACK_TAGS_PVP = TheSim:RegisterFindTags(GESTALT_DASH_ATTACK_MUST_TAGS,
	{ "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" })

local function NmApplyGestaltAttackAtDamageMultRate(inst, tabula, key, value)
	if inst.sg.statemem.originalattackvalue == nil then
		inst.sg.statemem.originalattackvalue = {}
		inst.sg.statemem.lastattackvalue = {}
	end

	if inst.sg.statemem.originalattackvalue[key] == nil then
		inst.sg.statemem.originalattackvalue[key] = tabula[key]
	end

	if inst.sg.statemem.lastattackvalue[key] ~= nil and tabula[key] ~= inst.sg.statemem.lastattackvalue[key] then
		inst.sg.statemem.originalattackvalue[key] = tabula[key]
	end

	local new_value = (value or inst.sg.statemem.lastattackvalue[key] or tabula[key])
		* TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE
	local original = inst.sg.statemem.originalattackvalue[key]
	if original ~= nil then
		local min_value = original * TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MIN_MULT
		if new_value < min_value then
			new_value = min_value
		end
	end

	tabula[key] = new_value
	inst.sg.statemem.lastattackvalue[key] = tabula[key]
end

local function NmRemoveGestaltAttackAtDamageMultRate(inst, tabula, key)
	if inst.sg.statemem.originalattackvalue == nil then
		return
	end

	if inst.sg.statemem.lastattackvalue[key] ~= nil and tabula[key] ~= inst.sg.statemem.lastattackvalue[key] then
		return
	end

	if inst.sg.statemem.originalattackvalue[key] ~= nil then
		tabula[key] = inst.sg.statemem.originalattackvalue[key]
	end
end

local function NmIsValidGestaltDashTarget(inst, target)
	if inst.sg.statemem.ignoretargets ~= nil and inst.sg.statemem.ignoretargets[target] then
		return false
	end

	local owner_combat = inst._playerlink ~= nil and inst._playerlink.components.combat or nil

	return target:IsValid()
		and (target.components.health == nil or not target.components.health:IsDead())
		and owner_combat ~= nil
		and owner_combat:CanTarget(target)
		and target.components.combat:CanBeAttacked(inst)
		and not owner_combat:IsAlly(target)
end

local function NmGetGestaltDashTarget(inst)
	if inst._playerlink == nil or inst._playerlink.components.combat == nil then
		return
	end

	local pos = inst:GetPosition()
	local find_tags = TheNet:GetPVPEnabled() and NM_REGISTERED_GESTALT_DASH_ATTACK_TAGS_PVP
		or NM_REGISTERED_GESTALT_DASH_ATTACK_TAGS

	for i, v in ipairs(TheSim:FindEntities_Registered(pos.x, 0, pos.z,
		TUNING.ABIGAIL_GESTALT_ATTACKAT_RADIUS + GESTALT_ATTACKAT_RADIUS_PADDING, find_tags)) do
		if NmIsValidGestaltDashTarget(inst, v) then
			local range = TUNING.ABIGAIL_GESTALT_ATTACKAT_RADIUS + v:GetPhysicsRadius(0)
			local dist = inst:GetDistanceSqToInst(v)

			if dist <= range * range
				and IsWithinAngle(pos, inst.sg.statemem.fowardvector,
					TUNING.ABIGAIL_GESTALT_ATTACKAT_VALID_ANGLE / RADIANS, v:GetPosition()) then
				return v
			end
		end
	end
end

local function NmGestaltDashUpdateFlash(target, data, id, r, g, b)
	if data.flashstep < 4 then
		local flash_value = (data.flashstep > 2 and 4 - data.flashstep or data.flashstep) * 0.05
		if target.components.colouradder == nil then
			target:AddComponent("colouradder")
		end
		target.components.colouradder:PushColour(id, flash_value * r, flash_value * g, flash_value * b, 0)
		data.flashstep = data.flashstep + 1
	else
		target.components.colouradder:PopColour(id)
		data.task:Cancel()
	end
end

local function NmGestaltDashStartFlash(inst, target, r, g, b)
	local data = { flashstep = 1 }
	local id = inst.prefab .. "::" .. tostring(inst.GUID)
	data.task = target:DoPeriodicTask(0, NmGestaltDashUpdateFlash, nil, data, id, r, g, b)
	NmGestaltDashUpdateFlash(target, data, id, r, g, b)
end

AddStategraphPostInit("abigail", function(self)
	local oldgestalt_loop_attackonenter = self.states['gestalt_loop_attack'].onenter
	self.states['gestalt_loop_attack'].onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		inst:SetTransparentPhysics(true)
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:SetMotorVelOverride(15, 0, 0)

		inst.AnimState:PlayAnimation("gestalt_attack_loop", true)
		inst.sg:SetTimeout(3)

		inst.sg.statemem.oldattackdamage = inst.components.combat.defaultdamage

		local buff = inst:GetDebuff("right_elixir_buff") -----------
		local phase = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
		local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)

		inst.components.combat:SetDefaultDamage(damage)

		inst.components.combat:StartAttack()
		inst.sg.statemem.enable_attack = true
	end

	self.states['gestalt_loop_homing_attack'].onenter = function(inst, data)
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		inst:SetTransparentPhysics(true)
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:SetMotorVelOverride(TUNING.WENDYSKILL_DASHATTACK_VELOCITY, 0, 0)

		inst.AnimState:PlayAnimation("gestalt_attack_loop", true)
		inst.sg:SetTimeout(10)

		local buff = inst:GetDebuff("right_elixir_buff")
		local phase = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
		local damage = TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day

		NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.combat, "defaultdamage", damage)
		NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage, "basedamage")
		NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage.externalbonuses, "_modifier")

		inst.sg.statemem.final_pos = data.pos

		inst:ForceFacePoint(inst.sg.statemem.final_pos)

		local rotation = inst.Transform:GetRotation()
		inst.sg.statemem.fowardvector = Vector3(math.cos(-rotation / RADIANS), 0, math.sin(-rotation / RADIANS))

		inst.sg.statemem.ignoretargets = {}
	end

	self.states['gestalt_loop_homing_attack'].onupdate = function(inst, dt)
		local target_pos = inst.sg.statemem.final_pos
		local current_pos = inst:GetPosition()

		if distsq(target_pos.x, target_pos.z, current_pos.x, current_pos.z) <= 2 * 2 then
			inst.sg:GoToState("gestalt_pst_attack")
			return
		end

		if inst.sg.statemem.current_target == nil or not NmIsValidGestaltDashTarget(inst, inst.sg.statemem.current_target) then
			inst.sg.statemem.current_target = NmGetGestaltDashTarget(inst)
		end

		local target = inst.sg.statemem.current_target

		if target == nil then
			inst:ForceFacePoint(inst.sg.statemem.final_pos)
			return
		end

		inst:ForceFacePoint(target.Transform:GetWorldPosition())

		if inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= TUNING.GESTALT_ATTACK_HIT_RANGE_SQ then
			if target.components.combat ~= nil and target.components.combat.hiteffectsymbol ~= nil then
				target:SpawnChild("abigail_gestalt_hit_fx")
				NmGestaltDashStartFlash(inst, target, 1, 1, 1)
				inst.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_hit")
			end

			inst.components.combat:DoAttack(target)
			inst.components.combat:RestartCooldown()

			NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.combat, "defaultdamage")
			NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage, "basedamage")
			NmApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage.externalbonuses, "_modifier")

			inst:ApplyDebuff({ target = target })

			inst.sg.statemem.current_target = nil
			inst.sg.statemem.ignoretargets[target] = true
		end
	end

	self.states['gestalt_loop_homing_attack'].onexit = function(inst)
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		inst.Physics:ClearMotorVelOverride()
		inst.components.locomotor:Stop()

		NmRemoveGestaltAttackAtDamageMultRate(inst, inst.components.combat, "defaultdamage")
		NmRemoveGestaltAttackAtDamageMultRate(inst, inst.components.planardamage, "basedamage")
		NmRemoveGestaltAttackAtDamageMultRate(inst, inst.components.planardamage.externalbonuses, "_modifier")

		inst:SetTransparentPhysics(false)
	end

	local oldidle = self.states['idle'].onenter
	self.states['idle'].onenter = function(inst)
		inst.components.health:SetInvincible(false) -- 无敌帧 不启动
		if inst.sg.mem.queued_play_target then
			inst.sg.mem.lastplaytime = GetTime()
			inst.sg:GoToState("play", inst.sg.mem.queued_play_target)
			inst.sg.mem.queued_play_target = nil
		else
			local anim = getidleanim(inst)
			if anim ~= nil then
				inst.AnimState:PlayAnimation(anim)
			end
		end
	end

	local oldgestalt_attackonenter = self.states['gestalt_attack'].onenter
	self.states['gestalt_attack'].onenter = function(inst, pos)
		inst.components.locomotor:Stop()
		inst.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_pre")

		inst.components.health:SetInvincible(true) -- 无敌帧 启动

		inst.Physics:Stop()

		inst.AnimState:PlayAnimation("gestalt_attack_pre")

		if pos ~= nil then
			inst.sg.statemem.final_pos = pos
		end
	end

	local oldgestalt_pst_attackonenter = self.states['gestalt_pst_attack'].onenter
	self.states['gestalt_pst_attack'].onenter = function(inst)
		inst.AnimState:PlayAnimation("gestalt_attack_pst")
		inst.components.health:SetInvincible(true) -- 无敌帧 启动
	end
end)
