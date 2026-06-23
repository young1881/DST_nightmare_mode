-- 精英猪人举牌组：从 pigelitefighter1-4 中随机召唤 2 只
-- 自带猪王木牌武器 propsign，无限耐久

ROGE_PIGELITE_SQUAD_KEY = "roge_pigelite_squad"
ROGE_PIGELITE_SQUAD_COUNT = 2
ROGE_PIGELITE_SQUAD_RADIUS = 4
ROGE_PIGELITE_FIGHTER_HEALTH = 600
ROGE_PIGELITE_SIGN_DAMAGE = 1
ROGE_PIGELITE_NORMAL_ATTACKS_AFTER_SMASH = 2 -- 木牌击后需完成 2 次三连击才能再次举牌
ROGE_PIGELITE_SQUAD_PREFABS = {
	"pigelitefighter1",
	"pigelitefighter2",
	"pigelitefighter3",
	"pigelitefighter4",
}

local function RogePickPigeliteSquadPrefabs(count)
	count = math.min(count or ROGE_PIGELITE_SQUAD_COUNT, #ROGE_PIGELITE_SQUAD_PREFABS)
	if count <= 0 then
		return {}
	end
	local pool = {}
	for i, prefab in ipairs(ROGE_PIGELITE_SQUAD_PREFABS) do
		pool[i] = prefab
	end
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local picked = {}
	for i = 1, count do
		picked[i] = pool[i]
	end
	return picked
end

local function RogeMakePropsignIndestructible(sign)
	if sign == nil or not sign:IsValid() then
		return
	end
	sign._roge_indestructible = true
	sign.OnCancelMinigame = function() end
	if sign.components.burnable ~= nil then
		sign:RemoveComponent("burnable")
	end
	if sign.Remove ~= nil and sign._roge_vanilla_remove == nil then
		sign._roge_vanilla_remove = sign.Remove
		sign.Remove = function(self)
			if self._roge_indestructible then
				return
			end
			return self._roge_vanilla_remove(self)
		end
	end
	if not sign._roge_propsign_events_patched then
		sign._roge_propsign_events_patched = true
		sign:ListenForEvent("propsmashed", function() end)
		sign:ListenForEvent("knockbackdropped", function() end)
	end
end

local function RogeEquipPigelitePropsign(inst)
	if inst.components.inventory == nil then
		inst:AddComponent("inventory")
	end
	local inv = inst.components.inventory
	RogeStripNpcInventory(inv)
	local sign = SpawnPrefab("propsign")
	if sign == nil then
		return
	end
	RogeMakePropsignIndestructible(sign)
	RogeClearEquippableRestriction(sign)
	if sign.components.weapon ~= nil then
		sign.components.weapon:SetRange(0, 0)
	end
	inv:GiveItem(sign)
	inv:Equip(sign)
end

local function RogePigeliteEnsurePropsignEquipped(inst)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return
	end
	if inst.components.inventory == nil then
		return
	end
	local inv = inst.components.inventory
	local equipped = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
	if equipped ~= nil and equipped:IsValid() and equipped:HasTag("propweapon") then
		RogeMakePropsignIndestructible(equipped)
		if inst.AnimState ~= nil and (inst.sg == nil or not inst.sg:HasStateTag("attack")) then
			inst.AnimState:Show("ARM_carry")
			inst.AnimState:Hide("ARM_normal")
		end
		return
	end
	for _, item in pairs(inv.itemslots) do
		if item ~= nil and item:IsValid() and item:HasTag("propweapon") then
			RogeMakePropsignIndestructible(item)
			inv:Equip(item)
			if inst.AnimState ~= nil then
				inst.AnimState:Show("ARM_carry")
				inst.AnimState:Hide("ARM_normal")
			end
			return
		end
	end
	RogeEquipPigelitePropsign(inst)
end

local function RogePatchPigeliteInventory(inst)
	if inst == nil or not inst:IsValid() or inst._roge_pigelite_inv_patched then
		return
	end
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	inst._roge_pigelite_inv_patched = true
	local old_drop = inv.DropItem
	inv.DropItem = function(self, item, ...)
		if item ~= nil and item._roge_indestructible and item:HasTag("propweapon") then
			return nil
		end
		return old_drop(self, item, ...)
	end
	local old_unequip = inv.Unequip
	inv.Unequip = function(self, slot, ...)
		if slot == EQUIPSLOTS.HANDS and not inst._roge_pigelite_allow_sign_unequip then
			local item = self:GetEquippedItem(EQUIPSLOTS.HANDS)
			if item ~= nil and item._roge_indestructible and item:HasTag("propweapon") then
				return nil
			end
		end
		return old_unequip(self, slot, ...)
	end
end

local function RogePigeliteOnDropItem(inst, data)
	if data ~= nil and data.item ~= nil and data.item:HasTag("propweapon") then
		inst:DoTaskInTime(0, RogePigeliteEnsurePropsignEquipped)
	end
end

local function RogePigelitePossessEmergencyShutoff(inst)
	if not TheWorld.ismastersim or inst == nil or not inst:IsValid() or inst.Poss2 == nil then
		return
	end
	if inst.Poss2.EndFN == nil or inst.Poss2.Possessors == nil then
		return
	end
	local possessors = {}
	for _, possessor in pairs(inst.Poss2.Possessors) do
		if possessor ~= nil and possessor:IsValid() then
			table.insert(possessors, possessor)
		end
	end
	for _, possessor in ipairs(possessors) do
		inst.Poss2.EndFN(inst, possessor)
	end
end

local function RogePigeliteInstallPossessListeners(inst)
	if inst == nil or not inst:IsValid() or inst._roge_pigelite_possess_listeners then
		return
	end
	inst._roge_pigelite_possess_listeners = true
	inst:ListenForEvent("death", RogePigelitePossessEmergencyShutoff)
	inst:ListenForEvent("onremove", RogePigelitePossessEmergencyShutoff)
	inst:ListenForEvent("dropitem", RogePigeliteOnDropItem)
	inst:ListenForEvent("attacked", function()
		inst:DoTaskInTime(0, RogePigeliteEnsurePropsignEquipped)
	end)
end

ROGE_PIGELITE_HAUNT_SEAL_TICKS = 12
ROGE_PIGELITE_POSS2_TEMPLATE_PREFABS = { "pigman", "pigguard", "merm" }

local _roge_poss2_template = nil

local function RogeCapturePoss2Template(inst)
	if _roge_poss2_template ~= nil or inst == nil or not inst:IsValid() then
		return
	end
	local p2 = inst.Poss2
	if p2 == nil or p2.StartFN == nil or p2.EndFN == nil then
		return
	end
	_roge_poss2_template = {
		StartFN = p2.StartFN,
		EndFN = p2.EndFN,
		TickFN = p2.TickFN,
	}
end

local function RogeTryCapturePoss2TemplateFromWorld()
	if _roge_poss2_template ~= nil or TheWorld == nil then
		return _roge_poss2_template ~= nil
	end
	local ent = FindEntity(TheWorld, 99999, function(e)
		return e.Poss2 ~= nil and e.Poss2.StartFN ~= nil and e.Poss2.EndFN ~= nil
	end)
	if ent ~= nil then
		RogeCapturePoss2Template(ent)
	end
	return _roge_poss2_template ~= nil
end

local function RogeSpawnPoss2TemplateProbe()
	if _roge_poss2_template ~= nil or TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	for _, prefab in ipairs(ROGE_PIGELITE_POSS2_TEMPLATE_PREFABS) do
		local probe = SpawnPrefab(prefab)
		if probe ~= nil then
			probe:DoTaskInTime(2 * FRAMES, function(i)
				if i ~= nil and i:IsValid() then
					RogeCapturePoss2Template(i)
					i:Remove()
				end
			end)
			return
		end
	end
end

function RogeBootstrapPigelitePoss2(inst)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return false
	end
	local p2 = inst.Poss2
	if p2 ~= nil and p2.StartFN ~= nil and p2.EndFN ~= nil then
		p2.RestrictionLevel = math.max(p2.RestrictionLevel or 0, 99)
		if p2.Possessors == nil then
			p2.Possessors = {}
		end
		return true
	end
	if _roge_poss2_template == nil and not RogeTryCapturePoss2TemplateFromWorld() then
		RogeSpawnPoss2TemplateProbe()
		return false
	end
	local tpl = _roge_poss2_template
	if tpl == nil then
		return false
	end
	if p2 == nil then
		inst.Poss2 = {
			Possessors = {},
			Level = 0,
			RestrictionLevel = 99,
			TickFN = tpl.TickFN,
			StartFN = tpl.StartFN,
			EndFN = tpl.EndFN,
			Timer = { Cancel = function() end },
		}
	else
		p2.Possessors = p2.Possessors or {}
		p2.Level = p2.Level or 0
		p2.RestrictionLevel = 99
		p2.StartFN = p2.StartFN or tpl.StartFN
		p2.EndFN = p2.EndFN or tpl.EndFN
		p2.TickFN = p2.TickFN or tpl.TickFN
		p2.Timer = p2.Timer or { Cancel = function() end }
	end
	RogePigeliteInstallPossessListeners(inst)
	return inst.Poss2 ~= nil and inst.Poss2.StartFN ~= nil
end

local function RogePigeliteClearHaunted(inst)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return
	end
	local h = inst.components.hauntable
	if h ~= nil then
		h.haunted = false
		h.cooldowntimer = 0
		h.panic = false
		h.panictimer = 0
		if h.StopShaderFX ~= nil then
			h:StopShaderFX()
		end
	end
	inst:RemoveTag("haunted")
end

local function RogePigeliteOnHaunted(inst)
	inst:DoTaskInTime(0, RogePigeliteClearHaunted)
end

function RogePigeliteOnHaunt(inst, haunter)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return false
	end
	if haunter == nil or not haunter:IsValid() then
		return false
	end
	if not haunter:HasTag("player") and not haunter:HasTag("playerghost") then
		return false
	end
	if haunter.Poss2 == nil then
		return false
	end
	if haunter.Poss2.Possessing ~= nil and haunter.Poss2.Possessing ~= inst then
		return false
	end
	if inst.components.sleeper ~= nil then
		inst.components.sleeper:WakeUp()
	end
	RogeBootstrapPigelitePoss2(inst)
	RogePigeliteSealHauntable(inst)
	local p2 = inst.Poss2
	if p2 == nil or p2.StartFN == nil then
		return false
	end
	if p2.Possessors[haunter.GUID] ~= nil then
		return true
	end
	if inst.brain ~= nil then
		inst.brain:Stop()
	end
	p2.StartFN(inst, haunter)
	return p2.Possessors[haunter.GUID] ~= nil
end

function RogePigeliteSealHauntable(inst)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return
	end
	RogeBootstrapPigelitePoss2(inst)
	if inst.components.hauntable == nil then
		inst:AddComponent("hauntable")
	end
	local h = inst.components.hauntable
	h.panicable = false
	h.panic = false
	h.panictimer = 0
	h.cooldown = 0
	h.usefx = false
	h.cooldown_on_successful_haunt = false
	h:SetHauntValue(TUNING.HAUNT_MED)
	h.onhaunt = RogePigeliteOnHaunt
	inst:AddTag("hauntable")

	if not inst._roge_pigelite_haunted_listener then
		inst._roge_pigelite_haunted_listener = true
		inst:ListenForEvent("haunted", RogePigeliteOnHaunted)
	end
end

function RogePigelitePreHauntSeal(inst)
	RogePigeliteClearHaunted(inst)
	RogeBootstrapPigelitePoss2(inst)
	RogePigeliteSealHauntable(inst)
end

local function RogePigeliteStartHauntSeal(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	if inst._roge_pigelite_haunt_period ~= nil then
		inst._roge_pigelite_haunt_period:Cancel()
		inst._roge_pigelite_haunt_period = nil
	end
	RogePigeliteSealHauntable(inst)
	inst:DoTaskInTime(0, RogePigeliteSealHauntable)
	inst:DoTaskInTime(FRAMES, RogePigeliteSealHauntable)
	local ticks = 0
	inst._roge_pigelite_haunt_period = inst:DoPeriodicTask(0.5, function(i)
		RogePigeliteSealHauntable(i)
		ticks = ticks + 1
		if ticks >= ROGE_PIGELITE_HAUNT_SEAL_TICKS and i._roge_pigelite_haunt_period ~= nil then
			i._roge_pigelite_haunt_period:Cancel()
			i._roge_pigelite_haunt_period = nil
		end
	end)
end

local function RogeSetupPigeliteHauntable(inst)
	RogePigeliteStartHauntSeal(inst)
end

for _, prefab in ipairs(ROGE_PIGELITE_POSS2_TEMPLATE_PREFABS) do
	AddPrefabPostInit(prefab, function(inst)
		if TheWorld ~= nil and TheWorld.ismastersim then
			inst:DoTaskInTime(0, RogeCapturePoss2Template)
		end
	end)
end

AddSimPostInit(function()
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	TheWorld:DoTaskInTime(0, RogeSpawnPoss2TemplateProbe)
end)

local function RogeRestartPigeliteBrain(inst)
	if inst.brain ~= nil then
		inst.brain:Stop()
		inst.brain:Start()
	end
end

local function RogePigeliteHasPropsign(inst)
	return inst._roge_pigelite_squad
		and inst.components.inventory ~= nil
		and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil
end

local function RogePigeliteCanSmash(inst)
	return (inst._roge_pigelite_normals_remaining or 0) <= 0
end

local function RogePigeliteOnSmashUsed(inst)
	inst._roge_pigelite_normals_remaining = ROGE_PIGELITE_NORMAL_ATTACKS_AFTER_SMASH
end

local function RogePigeliteOnNormalAttackDone(inst)
	local remaining = inst._roge_pigelite_normals_remaining or 0
	if remaining > 0 then
		inst._roge_pigelite_normals_remaining = remaining - 1
	end
end

local function RogePigeliteSetFighterRange(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:SetRange(2)
	end
end

local function RogePigeliteSetSignRange(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:SetRange(.7, 2)
	end
end

local function RogePigeliteStashSignForCombo(inst)
	if inst.components.inventory == nil then
		return
	end
	local sign = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if sign == nil or not sign:HasTag("propweapon") then
		return
	end
	inst._roge_pigelite_allow_sign_unequip = true
	inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
	inst._roge_pigelite_allow_sign_unequip = false
	if inst.sg ~= nil then
		inst.sg.statemem._roge_stashed_sign = sign
	end
	if inst.AnimState ~= nil then
		inst.AnimState:Hide("ARM_carry")
		inst.AnimState:Show("ARM_normal")
	end
end

local function RogePigeliteRestoreSignAfterCombo(inst)
	local sign = inst.sg ~= nil and inst.sg.statemem ~= nil and inst.sg.statemem._roge_stashed_sign or nil
	if sign == nil or not sign:IsValid() or inst.components.inventory == nil then
		return
	end
	inst.sg.statemem._roge_stashed_sign = nil
	if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
		inst.components.inventory:Equip(sign)
	end
	if inst.AnimState ~= nil then
		inst.AnimState:Show("ARM_carry")
		inst.AnimState:Hide("HAT")
		inst.AnimState:Hide("ARM_normal")
	end
end

local DOAOEATTACK_TARGET_MUST_HAVE = { "_combat" }
local DOAOEATTACK_TARGET_CANT_HAVE = { "flying", "shadow", "ghost", "FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost" }

local function RogePigeliteCanAOEHit(inst, v)
	if v == nil or v == inst or not v:IsValid() or v:IsInLimbo() then
		return false
	end
	-- 避免同组猪人互相误伤
	if v._roge_pigelite_squad then
		return false
	end
	if v.components.health ~= nil and v.components.health:IsDead() then
		return false
	end
	if v.components.combat ~= nil then
		return v.components.combat:CanBeAttacked(inst)
	end
	return true
end

local function RogePigeliteApplyAOEHit(inst, v, combat, knockback_radius)
	local damage = ROGE_PIGELITE_SIGN_DAMAGE
	if v.isplayer then
		v:PushEvent("attacked", { attacker = inst, damage = 0, redirected = v })
		v:PushEventImmediate("knockback", {
			knocker = inst,
			radius = knockback_radius,
			propsmashed = true,
		})
		if damage > 0 and v.components.health ~= nil and not v.components.health:IsDead() then
			v.components.health:DoDelta(-damage, false, inst.prefab, nil, inst)
		end
		return true
	end
	if v.components.combat ~= nil then
		v.components.combat:GetAttacked(inst, damage)
		return true
	end
	if damage > 0 and v.components.health ~= nil and not v.components.health:IsDead() then
		v.components.health:DoDelta(-damage, false, inst.prefab, nil, inst)
		return true
	end
	return false
end

local function RogePigeliteDoAOEAttack(inst, dist, radius)
	local combat = inst.components.combat
	if combat == nil then
		return
	end
	local hit = false
	combat.ignorehitrange = true
	local x0, y0, z0 = inst.Transform:GetWorldPosition()
	local angle = (inst.Transform:GetRotation() + 90) * DEGREES
	local sinangle = math.sin(angle)
	local cosangle = math.cos(angle)
	local x = x0 + dist * sinangle
	local z = z0 + dist * cosangle
	local knockback_radius = radius + dist
	for i, v in ipairs(TheSim:FindEntities(x, y0, z, radius + 3, DOAOEATTACK_TARGET_MUST_HAVE, DOAOEATTACK_TARGET_CANT_HAVE)) do
		if RogePigeliteCanAOEHit(inst, v) then
			local range = radius + v:GetPhysicsRadius(.5)
			if v:GetDistanceSqToPoint(x, y0, z) < range * range
				and RogePigeliteApplyAOEHit(inst, v, combat, knockback_radius) then
				hit = true
			end
		end
	end
	combat.ignorehitrange = false
	if hit then
		dist = dist + radius - .5
		return { pos = Vector3(x0 + dist * sinangle, y0, z0 + dist * cosangle) }
	end
end

local function RogePigelitePlaySignSmashFx(pos)
	if pos == nil then
		return
	end
	local fx = SpawnPrefab("propsignshatterfx")
	if fx ~= nil then
		fx.Transform:SetPosition(pos:Get())
		if fx.SoundEmitter ~= nil then
			fx.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
		end
	end
end

local function RogePigeliteCancelSignAttackTasks(inst)
	if inst.sg == nil or inst.sg.statemem == nil then
		return
	end
	if inst.sg.statemem._roge_aoe_task ~= nil then
		inst.sg.statemem._roge_aoe_task:Cancel()
		inst.sg.statemem._roge_aoe_task = nil
	end
	if inst.sg.statemem._roge_fx_task ~= nil then
		inst.sg.statemem._roge_fx_task:Cancel()
		inst.sg.statemem._roge_fx_task = nil
	end
	if inst.sg.statemem._roge_end_task ~= nil then
		inst.sg.statemem._roge_end_task:Cancel()
		inst.sg.statemem._roge_end_task = nil
	end
end

local function RogePigeliteScheduleSignAttack(inst)
	RogePigeliteCancelSignAttackTasks(inst)
	inst.sg.statemem._roge_aoe_task = inst:DoTaskInTime(7 * FRAMES, function()
		if not inst:IsValid() or inst.sg == nil or not inst.sg:HasStateTag("attack") then
			return
		end
		inst.sg.statemem.smashed = RogePigeliteDoAOEAttack(inst, .8, 1.7)
		if inst.sg.statemem.smashed ~= nil then
			RogePigeliteOnSmashUsed(inst)
		end
	end)
	inst.sg.statemem._roge_fx_task = inst:DoTaskInTime(8 * FRAMES, function()
		if not inst:IsValid() or inst.sg == nil or inst.sg.statemem.smashed == nil then
			return
		end
		local smashed = inst.sg.statemem.smashed
		inst.sg.statemem.smashed = nil
		RogePigelitePlaySignSmashFx(smashed.pos)
		RogePigeliteEnsurePropsignEquipped(inst)
	end)
	inst.sg.statemem._roge_end_task = inst:DoTaskInTime(19 * FRAMES, function()
		if not inst:IsValid() or inst.sg == nil or not inst.sg:HasStateTag("attack") then
			return
		end
		inst.sg:RemoveStateTag("attack")
		inst.sg:RemoveStateTag("busy")
		inst.sg:RemoveStateTag("propattack")
		inst.sg:AddStateTag("idle")
	end)
end

local function RogePatchPigeliteSignLocomote(sg)
	local locomote = sg.events.locomote
	if locomote == nil or locomote._roge_sign_locomote_patched then
		return
	end
	locomote._roge_sign_locomote_patched = true
	local old_fn = locomote.fn
	locomote.fn = function(inst, ...)
		if RogePigeliteHasPropsign(inst) then
			local can_run = true
			local can_walk = false
			local is_moving = inst.sg:HasStateTag("moving")
			local is_running = inst.sg:HasStateTag("running")
			local is_idling = inst.sg:HasStateTag("idle")
			local should_move = inst.components.locomotor:WantsToMoveForward()
			local should_run = inst.components.locomotor:WantsToRun()
			if is_moving and not should_move then
				inst.sg:GoToState(is_running and "run_stop" or "walk_stop")
			elseif (is_idling and should_move)
				or (is_moving and should_move and is_running ~= should_run and can_run and can_walk) then
				if can_run and (should_run or not can_walk) then
					inst.sg:GoToState("run_start")
				elseif can_walk then
					inst.sg:GoToState("walk_start")
				end
			end
			return
		end
		return old_fn(inst, ...)
	end
end

local function RogePatchPigeliteSignRunState(state)
	if state == nil or state._roge_sign_run_patched then
		return
	end
	state._roge_sign_run_patched = true
	local old_onenter = state.onenter
	if state.name == "run_start" then
		state.onenter = function(inst, ...)
			if RogePigeliteHasPropsign(inst) then
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("run_object_pre")
				return
			end
			return old_onenter(inst, ...)
		end
	elseif state.name == "run" then
		local old_ontimeout = state.ontimeout
		state.onenter = function(inst, ...)
			if RogePigeliteHasPropsign(inst) then
				inst.components.locomotor:RunForward()
				if not inst.AnimState:IsCurrentAnimation("run_object_loop") then
					inst.AnimState:PlayAnimation("run_object_loop", true)
				end
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
				return
			end
			return old_onenter(inst, ...)
		end
		state.ontimeout = function(inst, ...)
			if RogePigeliteHasPropsign(inst) then
				inst.sg:GoToState("run")
				return
			end
			if old_ontimeout ~= nil then
				return old_ontimeout(inst, ...)
			end
		end
	elseif state.name == "run_stop" then
		state.onenter = function(inst, ...)
			if RogePigeliteHasPropsign(inst) then
				inst.components.locomotor:StopMoving()
				inst.AnimState:PlayAnimation("run_object_pst")
				return
			end
			return old_onenter(inst, ...)
		end
	end
end

local ROGE_PIGELITE_HIT_IMMUNE_TIME = 3

local function RogePigeliteIsHitImmune(inst)
	if inst == nil or not inst:IsValid() or not inst._roge_pigelite_squad then
		return false
	end
	local until_t = inst._roge_pigelite_hit_immune_until
	return until_t ~= nil and GetTime() < until_t
end

local function RogePigeliteMarkHitImmune(inst)
	if inst ~= nil and inst:IsValid() and inst._roge_pigelite_squad then
		inst._roge_pigelite_hit_immune_until = GetTime() + ROGE_PIGELITE_HIT_IMMUNE_TIME
	end
end

local function RogePatchPigeliteHitState(state)
	if state == nil or state._roge_pigelite_hit_immune_patched then
		return
	end
	state._roge_pigelite_hit_immune_patched = true
	local old_onenter = state.onenter
	state.onenter = function(inst, ...)
		RogePigeliteMarkHitImmune(inst)
		if old_onenter ~= nil then
			return old_onenter(inst, ...)
		end
	end
end

local function RogePatchPigeliteHitImmunity(sg)
	RogePatchPigeliteHitState(sg.states.hit)
	RogePatchPigeliteHitState(sg.states.hit_stunlock)

	local attacked = sg.events["attacked"]
	if attacked ~= nil and not attacked._roge_pigelite_hit_immune_patched then
		attacked._roge_pigelite_hit_immune_patched = true
		local old_fn = attacked.fn
		attacked.fn = function(inst, data)
			if RogePigeliteIsHitImmune(inst) then
				return
			end
			if old_fn ~= nil then
				return old_fn(inst, data)
			end
		end
	end
end

local function RogePatchPigeliteSignAttack(sg)
	local attack = sg.states.attack
	if attack == nil or attack._roge_sign_attack_patched then
		return
	end
	attack._roge_sign_attack_patched = true
	local old_onenter = attack.onenter
	local old_onexit = attack.onexit
	attack.onenter = function(inst, target)
		if RogePigeliteHasPropsign(inst) and RogePigeliteCanSmash(inst) then
			inst._roge_sign_attack = true
			RogePigeliteSetSignRange(inst)
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			inst.AnimState:PlayAnimation("atk_object")
			inst.sg:AddStateTag("propattack")
			local t = target
			if (t == nil or not t:IsValid()) and inst.components.combat ~= nil then
				t = inst.components.combat.target
			end
			if t ~= nil and t:IsValid() then
				inst:ForceFacePoint(t.Transform:GetWorldPosition())
				inst.sg.statemem.target = t
			end
			RogePigeliteScheduleSignAttack(inst)
			return
		end
		inst._roge_sign_attack = false
		if inst._roge_pigelite_squad then
			RogePigeliteStashSignForCombo(inst)
			RogePigeliteSetFighterRange(inst)
		end
		if old_onenter ~= nil then
			return old_onenter(inst, target)
		end
	end
	attack.onexit = function(inst)
		if inst._roge_pigelite_squad then
			RogePigeliteRestoreSignAfterCombo(inst)
			RogePigeliteSetFighterRange(inst)
			if not inst._roge_sign_attack then
				RogePigeliteOnNormalAttackDone(inst)
			end
		end
		if inst._roge_sign_attack and inst.sg.statemem.smashed ~= nil then
			local smashed = inst.sg.statemem.smashed
			inst.sg.statemem.smashed = nil
			RogePigelitePlaySignSmashFx(smashed.pos)
		end
		RogePigeliteCancelSignAttackTasks(inst)
		inst._roge_sign_attack = false
		RogePigeliteEnsurePropsignEquipped(inst)
		if old_onexit ~= nil then
			return old_onexit(inst)
		end
	end
	if attack.timeline ~= nil then
		for i, ev in ipairs(attack.timeline) do
			if ev ~= nil and ev.fn ~= nil then
				local old_fn = ev.fn
				ev.fn = function(inst)
					if inst._roge_sign_attack then
						return
					end
					return old_fn(inst)
				end
			end
		end
	end
end

function RogeSetupPigeliteFighterMember(inst)
	if inst == nil or not inst:IsValid() or inst._roge_pigelite_squad then
		return
	end
	if inst.prefab ~= "pigelitefighter1"
		and inst.prefab ~= "pigelitefighter2"
		and inst.prefab ~= "pigelitefighter3"
		and inst.prefab ~= "pigelitefighter4" then
		return
	end
	inst._roge_pigelite_squad = true
	inst._roge_pigelite_normals_remaining = 0
	inst._should_despawn = false
	inst.persists = false
	inst:AddTag("flare_summoned")

	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("despawn_timer")
	end
	inst:StopWatchingWorldState("isfullmoon")

	if inst.components.health ~= nil and not inst.components.health:IsDead() then
		RogeSetFixedMaxHealth(inst, ROGE_PIGELITE_FIGHTER_HEALTH)
	end

	RogeSetupPigeliteHauntable(inst)
	RogePatchPigeliteInventory(inst)
	RogePigeliteInstallPossessListeners(inst)
	RogeEquipPigelitePropsign(inst)
	if inst.components.combat ~= nil then
		RogePigeliteSetFighterRange(inst)
	end
	if inst.AnimState ~= nil then
		inst.AnimState:Show("ARM_carry")
		inst.AnimState:Hide("HAT")
	end
	RogeRestartPigeliteBrain(inst)
end

AddBrainPostInit("pigelitefighterbrain", function(self)
	local old_onstart = self.OnStart
	self.OnStart = function(brain)
		local inst = brain.inst
		if inst._roge_pigelite_squad then
			brain.bt = BT(inst, PriorityNode({
				WhileNode(function() return inst.sg:HasStateTag("jumping") end, "Standby",
					ActionNode(function() end)),
				ChaseAndAttack(inst),
			}, .5))
			return
		end
		return old_onstart(brain)
	end
end)

AddStategraphPostInit("pigelitefighter", function(sg)
	RogePatchPigeliteHitImmunity(sg)
	RogePatchPigeliteSignLocomote(sg)
	RogePatchPigeliteSignRunState(sg.states.run_start)
	RogePatchPigeliteSignRunState(sg.states.run)
	RogePatchPigeliteSignRunState(sg.states.run_stop)
	RogePatchPigeliteSignAttack(sg)

	local death = sg.states.death
	if death ~= nil and not death._roge_pigelite_death_possess_patched then
		death._roge_pigelite_death_possess_patched = true
		local old_death_onenter = death.onenter
		death.onenter = function(inst, ...)
			if old_death_onenter ~= nil then
				old_death_onenter(inst, ...)
			end
			if inst._roge_pigelite_squad then
				inst:DoTaskInTime(0, RogePigelitePossessEmergencyShutoff)
			end
		end
	end

	local despawn = sg.events.despawn
	if despawn ~= nil and not despawn._roge_pigelite_patched then
		despawn._roge_pigelite_patched = true
		local old_fn = despawn.fn
		despawn.fn = function(inst, data)
			if inst._roge_pigelite_squad then
				return
			end
			if old_fn ~= nil then
				return old_fn(inst, data)
			end
		end
	end

	local onsink = sg.events.onsink
	if onsink ~= nil and not onsink._roge_pigelite_patched then
		onsink._roge_pigelite_patched = true
		local old_fn = onsink.fn
		onsink.fn = function(inst, data)
			if inst._roge_pigelite_squad then
				return
			end
			if old_fn ~= nil then
				return old_fn(inst, data)
			end
		end
	end
end)

function RogeSpawnPigeliteSquadPack(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local spawn_radius = 5
	local cx = x + math.cos(angle) * spawn_radius
	local cz = z + math.sin(angle) * spawn_radius
	local target = player
	if player.components.combat ~= nil and player.components.combat.target ~= nil then
		target = player.components.combat.target
	end
	local first = nil
	local prefabs = RogePickPigeliteSquadPrefabs(ROGE_PIGELITE_SQUAD_COUNT)
	local count = #prefabs
	local base_angle = math.random() * 2 * PI
	for i, prefab in ipairs(prefabs) do
		local a = base_angle + (i - 1) * (2 * PI / count)
		local mob = SpawnPrefab(prefab)
		if mob ~= nil then
			mob.Transform:SetPosition(
				cx + math.cos(a) * ROGE_PIGELITE_SQUAD_RADIUS,
				y,
				cz + math.sin(a) * ROGE_PIGELITE_SQUAD_RADIUS
			)
			RogeSetupPigeliteFighterMember(mob)
			if first == nil then
				first = mob
			end
			if target ~= nil and target:IsValid() and mob.components.combat ~= nil then
				mob.components.combat:SetTarget(target)
			end
		end
	end
	return first
end
