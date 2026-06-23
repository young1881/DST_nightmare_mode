

TUNING.SPEAR_LIGHTNING_PRO_MAX_REPAIRS_PER_LUNGE = TUNING.SPEAR_LIGHTNING_PRO_MAX_REPAIRS_PER_LUNGE or 4
TUNING.SPEAR_LIGHTNING_PRO_LUNGE_REPAIR_AMOUNT = TUNING.SPEAR_LIGHTNING_PRO_LUNGE_REPAIR_AMOUNT or 4

local SPEAR_PREFAB_CHARGED = "spear_wathgrithr_lightning_charged"
local SPEAR_PREFAB_LIGHTNING = "spear_wathgrithr_lightning"
local LIGHTNING_SPEAR_PREFABS = {
    [SPEAR_PREFAB_CHARGED] = true,
    [SPEAR_PREFAB_LIGHTNING] = true,
}
local TURF_SIZE = 4 -- 一格地皮边长
local SKY_PIERCE_RANGE = 12 * TURF_SIZE -- 施法范围
local SKY_PIERCE_AOE_RADIUS = 0.7 * TURF_SIZE -- 落地攻击范围
local SKY_PIERCE_LUNGE_AOE_DEFAULT = 2.5
local SKY_PIERCE_DAMAGE_MULT = 2.5
local SKY_PIERCE_PLANAR_DAMAGE = 180
local SKY_PIERCE_INSPIRATION_COST = 51
local SKY_PIERCE_COOLDOWN = 8
local SKY_PIERCE_HIT_REPAIR = 15
local SKY_PIERCE_RPC_DEBOUNCE = 0.4
local SKY_PIERCE_CD_SAY_INTERVAL = 1.5
local WIGFRID_SKILL_LUNAR = "wathgrithr_allegiance_lunar"   -- 月曲歌唱家
local WIGFRID_SKILL_SHADOW = "wathgrithr_allegiance_shadow" -- 暗影女猎手
local SKY_PIERCE_LAND_ARMOR_TIME = 0.5
local SKY_PIERCE_LOCK_TIMEOUT = 4
local SKY_PIERCE_BATTLE_CRY_SOUND = "dontstarve/common/lava_arena/spell/battle_cry"
local SKY_PIERCE_BATTLE_CRY_VOLUME = 1.6
local SKY_PIERCE_LINES = {
    inspiration = "意犹未尽，与我一战！",
    spear_missing = "我需要我的战矛",
    spear_recharge = "休息片刻即可再战",
    skill = "需要月之护卫技能",
    fail = "冲锋失败，请稍后再试",
}

local function GetItemPrefab(inst)
    if inst == nil then
        return nil
    end
    if inst.prefab ~= nil then
        return inst.prefab
    end
    if inst.inst ~= nil and inst.inst.prefab ~= nil then
        return inst.inst.prefab
    end
    return nil
end

local function IsLightningSpearWeapon(inst)
    local prefab = GetItemPrefab(inst)
    return prefab ~= nil and LIGHTNING_SPEAR_PREFABS[prefab] == true
end

local function IsSpearCharged(weapon)
    if weapon == nil then
        return false
    end
    local prefab = GetItemPrefab(weapon)
    if prefab == SPEAR_PREFAB_CHARGED then
        if weapon.replica ~= nil and weapon.replica.rechargeable ~= nil then
            return weapon.replica.rechargeable:IsCharged()
        end
        if weapon.components.rechargeable ~= nil then
            return weapon.components.rechargeable:IsCharged()
        end
        -- 充能版奔雷矛：客户端 replica 未同步时仍允许尝试，由服务端最终校验
        return true
    end
    if prefab == SPEAR_PREFAB_LIGHTNING then
        if weapon.replica ~= nil and weapon.replica.rechargeable ~= nil then
            return weapon.replica.rechargeable:IsCharged()
        end
        if weapon.components.rechargeable ~= nil then
            return weapon.components.rechargeable:IsCharged()
        end
    end
    return false
end

local function GetEquippedLightningSpear(player)
    if player == nil then
        return nil
    end
    if player.replica ~= nil and player.replica.inventory ~= nil then
        local weapon = player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if IsLightningSpearWeapon(weapon) then
            return weapon
        end
    end
    if player.components.inventory ~= nil then
        local weapon = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if IsLightningSpearWeapon(weapon) then
            return weapon
        end
    end
    return nil
end

local function GetEquippedHandItem(player)
    if player == nil then
        return nil
    end
    if player.replica ~= nil and player.replica.inventory ~= nil then
        return player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    end
    if player.components.inventory ~= nil then
        return player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    end
    return nil
end

local function GetEquippedSpear(player)
    local weapon = GetEquippedLightningSpear(player)
    if weapon ~= nil and IsSpearCharged(weapon) then
        return weapon
    end
    return nil
end

local function HasWigfridSkill(player, skillid)
    if player == nil or skillid == nil then
        return false
    end
    if player.components.skilltreeupdater ~= nil then
        return player.components.skilltreeupdater:IsActivated(skillid)
    end
    if player.replica ~= nil and player.replica.skilltreeupdater ~= nil then
        return player.replica.skilltreeupdater:IsActivated(skillid)
    end
    return false
end

local function IsWigfridLunarAllegiance(owner)
    if owner == nil or owner.prefab ~= "wathgrithr" then
        return false
    end
    if owner:HasTag("player_lunar_aligned") then
        return true
    end
    return HasWigfridSkill(owner, WIGFRID_SKILL_LUNAR)
end

local function GetInspirationPoints(inst)
    if inst == nil then
        return 0
    end
    if inst.player_classified ~= nil and inst.player_classified.currentinspiration ~= nil then
        return inst.player_classified.currentinspiration:value() or 0
    end
    if inst.components.singinginspiration ~= nil then
        if inst.components.singinginspiration.current ~= nil then
            return inst.components.singinginspiration.current
        end
        return inst.components.singinginspiration:GetPercent() * TUNING.INSPIRATION_MAX
    end
    return 0
end

local function GetSkyPierceFallbackPos(player, maxrange)
    if player == nil then
        return nil
    end
    local px, py, pz = player.Transform:GetWorldPosition()
    local dist = maxrange * 0.6
    local rad = player.Transform:GetRotation() * DEGREES
    return Vector3(px + math.cos(rad) * dist, py, pz - math.sin(rad) * dist)
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
    if pos == nil then
        return GetSkyPierceFallbackPos(player, maxrange)
    end

    local px, py, pz = player.Transform:GetWorldPosition()
    local dx, dz = pos.x - px, pos.z - pz
    local distsq = dx * dx + dz * dz
    local maxsq = maxrange * maxrange
    if distsq > maxsq and distsq > 0 then
        local scale = maxrange / math.sqrt(distsq)
        pos = Vector3(px + dx * scale, pos.y or py, pz + dz * scale)
    end

    -- 客户端无 Map:GetHeightAtPoint，高度由服务端 ServerCastSkyPierceAt 校正
    if pos.y == nil then
        pos.y = py
    end
    return pos
end

local function SetSkyPierceCooldown(inst, duration)
    if inst == nil then
        return
    end
    duration = duration or SKY_PIERCE_COOLDOWN
    inst._nm_sky_pierce_cd_until = GetTime() + duration
end

local function ClearSkyPierceCooldown(inst)
    if inst ~= nil then
        inst._nm_sky_pierce_cd_until = nil
    end
end

local function GetSkyPierceCdRemaining(inst)
    if inst == nil or inst._nm_sky_pierce_cd_until == nil then
        return 0
    end
    local remaining = inst._nm_sky_pierce_cd_until - GetTime()
    if remaining <= 0 then
        return 0
    end
    -- 防止误写入绝对时间戳或狂暴计时，冲天刺 CD 最多 8 秒
    return math.min(SKY_PIERCE_COOLDOWN, remaining)
end

local function IsSkyPierceOnCooldown(inst)
    return GetSkyPierceCdRemaining(inst) > 0
end

local function SaySkyPierceCdLine(inst)
    if inst == nil or inst.components.talker == nil then
        return
    end
    local t = GetTime()
    if inst._nm_sky_pierce_cd_say_at ~= nil and t - inst._nm_sky_pierce_cd_say_at < SKY_PIERCE_CD_SAY_INTERVAL then
        return
    end
    inst._nm_sky_pierce_cd_say_at = t
    local remaining = math.ceil(GetSkyPierceCdRemaining(inst))
    if remaining > 0 then
        inst.components.talker:Say(string.format("休息片刻即可再战（还需 %d 秒）", remaining))
    else
        inst.components.talker:Say("休息片刻即可再战")
    end
end

local function CanUseSkyPierce(inst)
    if IsSkyPierceOnCooldown(inst) then
        return false, "cd"
    end
    if GetInspirationPoints(inst) < SKY_PIERCE_INSPIRATION_COST then
        return false, "inspiration"
    end
    return true
end

local function SaySkyPierceLine(inst, reason)
    if inst == nil then
        return
    end
    if reason == "cd" then
        SaySkyPierceCdLine(inst)
        return
    end
    local line = SKY_PIERCE_LINES[reason]
    if line ~= nil and inst.components.talker ~= nil then
        inst.components.talker:Say(line)
    end
end

local function NotifySkyPierceCastFailClient(inst)
    if inst ~= nil and inst.userid ~= nil then
        SendModRPCToClient(GetClientModRPC("my_mod", "sky_pierce_cast_fail"), inst.userid)
    end
end

local function NotifySkyPierceFail(inst, reason)
    if inst == nil or reason == nil then
        return
    end
    if reason == "cd" then
        local remaining = GetSkyPierceCdRemaining(inst)
        if inst.userid ~= nil and remaining > 0 then
            SendModRPCToClient(GetClientModRPC("my_mod", "sky_pierce_cd_sync"), inst.userid, remaining)
        end
    else
        NotifySkyPierceCastFailClient(inst)
    end
    SaySkyPierceLine(inst, reason)
end

local function NotifySkyPierceSuccess(inst)
    SetSkyPierceCooldown(inst, SKY_PIERCE_COOLDOWN)
    if inst.userid ~= nil then
        -- 只同步「剩余秒数」，不同步服务端绝对时间（否则客户端会显示成上百秒）
        SendModRPCToClient(GetClientModRPC("my_mod", "sky_pierce_cast_ok"), inst.userid, SKY_PIERCE_COOLDOWN)
    end
end

local function ConsumeSkyPierceCost(inst)
    if inst.components.singinginspiration ~= nil then
        inst.components.singinginspiration:DoDelta(-SKY_PIERCE_INSPIRATION_COST)
    end
end

local function RefundSkyPierceCost(inst)
    if inst.components.singinginspiration ~= nil then
        inst.components.singinginspiration:DoDelta(SKY_PIERCE_INSPIRATION_COST)
    end
end

local function IsSkyPierceNoInterrupt(inst)
    return inst ~= nil and (
        inst:HasTag("nm_sky_pierce_locked")
        or inst:HasTag("light_pro_nointerrupt")
        or inst:HasTag("nm_sky_pierce_land_nointerrupt")
    )
end

local function EndSkyPierceLock(doer, refund)
    if doer == nil or not doer:IsValid() then
        return
    end
    doer:RemoveTag("nm_sky_pierce_locked")
    doer:RemoveTag("busy")
    doer:RemoveTag("light_pro_nointerrupt")
    if doer._nm_sky_pierce_lock_task ~= nil then
        doer._nm_sky_pierce_lock_task:Cancel()
        doer._nm_sky_pierce_lock_task = nil
    end
    if refund and doer._nm_sky_pierce_cost_pending then
        RefundSkyPierceCost(doer)
        ClearSkyPierceCooldown(doer)
        if doer.userid ~= nil then
            SendModRPCToClient(GetClientModRPC("my_mod", "sky_pierce_cast_fail"), doer.userid)
        end
    end
    doer._nm_sky_pierce_cost_pending = nil
end

local function BeginSkyPierceLock(doer)
    if doer == nil or not doer:IsValid() then
        return
    end
    doer:AddTag("nm_sky_pierce_locked")
    doer:AddTag("busy")
    doer:AddTag("light_pro_nointerrupt")
    if doer.components.grogginess ~= nil then
        doer.components.grogginess:ResetGrogginess()
    end
    if doer._nm_sky_pierce_lock_task ~= nil then
        doer._nm_sky_pierce_lock_task:Cancel()
    end
    doer._nm_sky_pierce_lock_task = doer:DoTaskInTime(SKY_PIERCE_LOCK_TIMEOUT, function(mover)
        if mover:IsValid() and mover:HasTag("nm_sky_pierce_locked") then
            EndSkyPierceLock(mover, mover._nm_sky_pierce_cost_pending == true)
        end
    end)
end

local function CommitSkyPierceCost(doer)
    if doer == nil or not doer:IsValid() or not doer._nm_sky_pierce_cost_pending then
        return
    end
    doer._nm_sky_pierce_cost_pending = nil
    ConsumeSkyPierceCost(doer)
    NotifySkyPierceSuccess(doer)
end

local function PlaySkyPierceBattleCry(inst)
    if inst == nil or not inst:IsValid() then
        return
    end
    if inst.SoundEmitter == nil then
        inst.entity:AddSoundEmitter()
    end
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound(SKY_PIERCE_BATTLE_CRY_SOUND, nil, SKY_PIERCE_BATTLE_CRY_VOLUME)
    end
end

local function ClearSkyPierceLandingArmor(doer)
    if doer == nil or not doer:IsValid() then
        return
    end
    if doer._nm_sky_pierce_land_task ~= nil then
        doer._nm_sky_pierce_land_task:Cancel()
        doer._nm_sky_pierce_land_task = nil
    end
    doer:RemoveTag("nm_sky_pierce_land_nointerrupt")
end

local function ApplySkyPierceLandingArmor(doer)
    if doer == nil or not doer:IsValid() then
        return
    end
    doer:AddTag("nm_sky_pierce_land_nointerrupt")
    if doer.components.grogginess ~= nil then
        doer.components.grogginess:ResetGrogginess()
    end
    if doer._nm_sky_pierce_land_task ~= nil then
        doer._nm_sky_pierce_land_task:Cancel()
    end
    doer._nm_sky_pierce_land_task = doer:DoTaskInTime(SKY_PIERCE_LAND_ARMOR_TIME, function(mover)
        if mover:IsValid() then
            mover:RemoveTag("nm_sky_pierce_land_nointerrupt")
        end
        mover._nm_sky_pierce_land_task = nil
    end)
end

local function SkyPierce_SpellFn(weapon, doer, pos)
    doer:PushEvent("combat_superjump", { targetpos = pos, weapon = weapon })
end

local function GetSkyPiercePhysicalDamage(weapon, doer)
    if weapon ~= nil and weapon.components.weapon ~= nil then
        local damage = weapon.components.weapon:GetDamage(doer, nil)
        if damage ~= nil then
            return damage * SKY_PIERCE_DAMAGE_MULT
        end
    end
    if doer ~= nil and doer.components.combat ~= nil then
        return doer.components.combat.defaultdamage * doer.components.combat.damagemultiplier * SKY_PIERCE_DAMAGE_MULT
    end
    return 0
end

local function Lightning_ResetElectric(inst)
    inst._electric_lunge_task = nil
end

-- 与原版奔雷矛冲刺 Lightning_OnPreLunge 一致：短暂开启强制电击判定
local function EnableSkyPierceElectric(inst)
    if inst._electric_lunge_task ~= nil then
        inst._electric_lunge_task:Cancel()
    end
    inst._electric_lunge_task = inst:DoTaskInTime(2 * FRAMES, Lightning_ResetElectric)
end

local function ApplySkyPierceDamage(weapon, doer)
    if weapon == nil or weapon.components.aoeweapon_leap == nil then
        return
    end

    weapon.components.aoeweapon_leap:SetDamage(GetSkyPiercePhysicalDamage(weapon, doer))

    if weapon.components.planardamage ~= nil then
        weapon._nm_old_planar = weapon.components.planardamage:GetBaseDamage()
        weapon.components.planardamage:SetBaseDamage(SKY_PIERCE_PLANAR_DAMAGE)
    else
        weapon:AddComponent("planardamage")
        weapon._nm_added_planar = true
        weapon.components.planardamage:SetBaseDamage(SKY_PIERCE_PLANAR_DAMAGE)
    end
end

local function RestoreSkyPierceDamage(weapon)
    if weapon == nil or not weapon:IsValid() then
        return
    end
    if weapon._nm_added_planar then
        weapon:RemoveComponent("planardamage")
        weapon._nm_added_planar = nil
    elseif weapon._nm_old_planar ~= nil and weapon.components.planardamage ~= nil then
        weapon.components.planardamage:SetBaseDamage(weapon._nm_old_planar)
        weapon._nm_old_planar = nil
    end
end

local function Lighting_OnLeapPre(inst, doer, startpos, endpos)
    ApplySkyPierceDamage(inst, doer)
    EnableSkyPierceElectric(inst)

    inst:RemoveTag("scarytoprey")
    inst:AddTag("notarget")

    doer.components.health.externalabsorbmodifiers:SetModifier(doer, 0.6, "wathgrithr_spear_leap")
    doer:AddTag("light_pro_nointerrupt")
    local colorf = .2
    doer.components.colouradder:PushColour("wathgrithr_spear_leap", colorf, colorf, colorf, 0)
    doer:DoTaskInTime(2, function(mover)
        if not mover:IsValid() then
            return
        end
        mover.components.health.externalabsorbmodifiers:RemoveModifier(mover, "wathgrithr_spear_leap")
        mover.components.colouradder:PopColour("wathgrithr_spear_leap")
        mover:RemoveTag("light_pro_nointerrupt")
    end)

    for _, v in pairs(TheSim:FindEntities(endpos.x, endpos.y, endpos.z, 2)) do
        if v.components and v.components.rideable and v.components.rideable.saddle and not v.components.rideable.rider then
            doer.components.rider:Mount(v, true)
            return
        end
    end
end

-- 原版充能奔雷矛 Lightning_OnLungedHit（耐久回复）
local function Lightning_OnLungedHit(inst, doer, target)
    inst._lunge_hit_count = inst._lunge_hit_count or 0
    if inst._lunge_hit_count < TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_MAX_REPAIRS_PER_LUNGE
        and inst.components.upgradeable == nil
        and doer.IsValidVictim ~= nil and doer.IsValidVictim(target) then
        inst.components.finiteuses:Repair(TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LUNGE_REPAIR_AMOUNT)
        inst._lunge_hit_count = inst._lunge_hit_count + 1
    end
end

-- 无法进入电击僵直时，强制播放受击 hit 动画
local function ForceSkyPierceHitState(target)
    if target == nil or not target:IsValid() or target.sg == nil then
        return
    end
    if target.components.health ~= nil and target.components.health:IsDead() then
        return
    end
    if target.sg:HasStateTag("electrocute") or target.sg:HasStateTag("dead") then
        return
    end

    if target.components.freezable ~= nil and target.components.freezable:IsFrozen() then
        target.components.freezable:Unfreeze()
    end
    if target.components.sleeper ~= nil then
        target.components.sleeper:WakeUp()
    end

    if target.sg:HasState("hit_stunlock") then
        target.sg:GoToState("hit_stunlock")
    elseif target.sg:HasState("hit") then
        target.sg:GoToState("hit")
    end
end

-- 落地命中：电击僵直（electrocute）或强制 hit
local function ApplySkyPierceHitReact(inst, doer, target)
    if target == nil or not target:IsValid() or doer == nil or not doer:IsValid() then
        return
    end
    if target.components.combat == nil or target.components.health == nil or target.components.health:IsDead() then
        return
    end
    if target:HasTag("electricdamageimmune") or target.sg == nil then
        ForceSkyPierceHitState(target)
        return
    end

    local attackdata = {
        attacker = doer,
        weapon = inst,
        stimuli = "electric",
    }

    local weapon_cmp = inst.components.weapon
    local old_stimuli, old_override
    if weapon_cmp ~= nil then
        old_stimuli = weapon_cmp.stimuli
        old_override = weapon_cmp.overridestimulifn
        weapon_cmp.stimuli = "electric"
        weapon_cmp.overridestimulifn = nil
    end

    local electrocuted = false
    if CommonHandlers ~= nil and CommonHandlers.TryElectrocuteOnAttacked ~= nil then
        electrocuted = CommonHandlers.TryElectrocuteOnAttacked(target, attackdata) == true
    end

    if weapon_cmp ~= nil then
        weapon_cmp.stimuli = old_stimuli
        weapon_cmp.overridestimulifn = old_override
    end

    if not electrocuted then
        ForceSkyPierceHitState(target)
    end
end

-- 原版 Lightning_OnAttack：命中火花 + 电击僵直 / 强制 hit
local function SkyPierce_OnHitRepair(inst, doer, target)
    if inst.components.finiteuses == nil then
        return
    end
    if doer == nil or doer.IsValidVictim == nil or not doer:IsValidVictim(target) then
        return
    end
    inst.components.finiteuses:Repair(SKY_PIERCE_HIT_REPAIR)
end

local function SkyPierce_OnHit(inst, doer, target)
    if target ~= nil and target:IsValid() and doer ~= nil and doer:IsValid() then
        local sparks = SpawnPrefab("electrichitsparks")
        if sparks ~= nil then
            sparks:AlignToTarget(target, doer, true)
        end
        ApplySkyPierceHitReact(inst, doer, target)
    end
    if inst._nm_sky_pierce_mode then
        SkyPierce_OnHitRepair(inst, doer, target)
    else
        Lightning_OnLungedHit(inst, doer, target)
    end
end

local function Lightning_OnLeap(inst, doer, startingpos, targetpos)
    SpawnPrefab("superjump_fx"):SetTarget(inst)
    inst.components.rechargeable:Discharge(inst._cooldown)

    local new = SpawnPrefab("lightning")
    new.Transform:SetPosition(targetpos:Get())

    ApplySkyPierceLandingArmor(doer)

    Lightning_ResetElectric(inst)
    RestoreSkyPierceDamage(inst)

    inst._lunge_hit_count = nil
    inst:AddTag("scarytoprey")
    inst:RemoveTag("notarget")
end

------------------------------------------------------------------------------------------------------------------------
-- 服务端：临时切 leap 模式，走原版 superjump 状态机

local function EnterSkyPierceWeaponMode(weapon)
    if weapon._nm_sky_pierce_mode then
        return
    end
    if weapon.components.aoespell == nil then
        weapon:AddComponent("aoespell")
    end
    weapon._nm_sky_pierce_mode = true
    weapon:RemoveTag("aoeweapon_lunge")
    weapon:AddTag("superjump")
    if weapon.components.aoespell ~= nil then
        weapon._nm_old_spellfn = weapon.components.aoespell.spellfn
        weapon.components.aoespell:SetSpellFn(SkyPierce_SpellFn)
    end
    if weapon.components.aoetargeting ~= nil then
        weapon._nm_old_aoetargeting_range = weapon.components.aoetargeting:GetRange()
        weapon.components.aoetargeting:SetRange(SKY_PIERCE_RANGE)
        weapon._nm_sky_pierce_aoetargeting_was_enabled = weapon.components.aoetargeting:IsEnabled()
        weapon.components.aoetargeting:SetEnabled(true)
    end
    if weapon.components.aoeweapon_leap ~= nil then
        weapon.components.aoeweapon_leap:SetAOERadius(SKY_PIERCE_AOE_RADIUS)
    end
end

local function RestoreLungeWeaponMode(weapon)
    if weapon == nil or not weapon:IsValid() or not weapon._nm_sky_pierce_mode then
        return
    end
    weapon._nm_sky_pierce_mode = nil
    weapon:RemoveTag("superjump")
    weapon:AddTag("aoeweapon_lunge")
    if weapon.components.aoespell ~= nil and weapon._nm_old_spellfn ~= nil then
        weapon.components.aoespell:SetSpellFn(weapon._nm_old_spellfn)
        weapon._nm_old_spellfn = nil
    end
    if weapon.components.aoetargeting ~= nil and weapon._nm_old_aoetargeting_range ~= nil then
        weapon.components.aoetargeting:SetRange(weapon._nm_old_aoetargeting_range)
        weapon._nm_old_aoetargeting_range = nil
    end
    if weapon.components.aoetargeting ~= nil and weapon._nm_sky_pierce_aoetargeting_was_enabled ~= nil then
        weapon.components.aoetargeting:SetEnabled(weapon._nm_sky_pierce_aoetargeting_was_enabled)
        weapon._nm_sky_pierce_aoetargeting_was_enabled = nil
    end
    if weapon.components.aoeweapon_leap ~= nil then
        weapon.components.aoeweapon_leap:SetAOERadius(SKY_PIERCE_LUNGE_AOE_DEFAULT)
    end
end

local function ServerCastSkyPierceAt(inst, x, z)
    if inst == nil or not inst:IsValid() or inst.prefab ~= "wathgrithr" then
        return false
    end
    if inst.components.health ~= nil and inst.components.health:IsDead() then
        NotifySkyPierceFail(inst, "fail")
        return false
    end
    if inst.components.locomotor == nil or inst.components.inventory == nil then
        NotifySkyPierceFail(inst, "fail")
        return false
    end

    if not HasWigfridSkill(inst, WIGFRID_SKILL_LUNAR) then
        NotifySkyPierceFail(inst, "skill")
        return false
    end

    local can_use, reason = CanUseSkyPierce(inst)
    if not can_use then
        NotifySkyPierceFail(inst, reason)
        return false
    end

    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon == nil or not IsLightningSpearWeapon(weapon) then
        NotifySkyPierceFail(inst, "spear_missing")
        return false
    end
    if weapon.components.rechargeable == nil or not weapon.components.rechargeable:IsCharged() then
        NotifySkyPierceFail(inst, "spear_recharge")
        return false
    end
    if weapon.components.aoeweapon_leap == nil then
        weapon:AddComponent("aoeweapon_leap")
        weapon.components.aoeweapon_leap:SetAOERadius(SKY_PIERCE_AOE_RADIUS)
        weapon.components.aoeweapon_leap:SetStimuli("electric")
        weapon.components.aoeweapon_leap:SetOnLeaptFn(Lightning_OnLeap)
        weapon.components.aoeweapon_leap:SetOnPreLeapFn(Lighting_OnLeapPre)
        weapon.components.aoeweapon_leap:SetOnHitFn(SkyPierce_OnHit)
        weapon.components.aoeweapon_leap:SetTags("_combat")
        weapon.components.aoeweapon_leap:SetNoTags("FX", "DECOR", "INLIMBO", "moonstorm_static", "wall")
        weapon.components.aoeweapon_leap:SetWorkActions(ACTIONS.CHOP, ACTIONS.MINE)
    end

    local pos = Vector3(x, 0, z)
    if TheWorld.Map ~= nil and TheWorld.Map.GetHeightAtPoint ~= nil then
        pos.y = TheWorld.Map:GetHeightAtPoint(pos.x, pos.z) or inst:GetPosition().y
    else
        pos.y = inst:GetPosition().y
    end

    local startpos = inst:GetPosition()
    local dx, dz = pos.x - startpos.x, pos.z - startpos.z
    local distsq = dx * dx + dz * dz
    local maxsq = SKY_PIERCE_RANGE * SKY_PIERCE_RANGE
    if distsq > maxsq and distsq > 0 then
        local scale = SKY_PIERCE_RANGE / math.sqrt(distsq)
        pos = Vector3(startpos.x + dx * scale, pos.y, startpos.z + dz * scale)
    end

    EnterSkyPierceWeaponMode(weapon)

    local act = BufferedAction(inst, nil, ACTIONS.CASTAOE, weapon, pos, nil, SKY_PIERCE_RANGE)
    local can_start, _ = act:TestForStart()
    if not can_start then
        RestoreLungeWeaponMode(weapon)
        NotifySkyPierceFail(inst, "fail")
        return false
    end

    inst._nm_sky_pierce_cost_pending = true
    BeginSkyPierceLock(inst)
    PlaySkyPierceBattleCry(inst)
    inst.components.locomotor:PushAction(act, true)

    weapon:DoTaskInTime(3, function(w)
        RestoreLungeWeaponMode(w)
    end)
    return true
end

AddPrefabPostInit("wathgrithr", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("custom_sky_pierce_cast", function(owner, data)
        if data ~= nil and data.x ~= nil and data.z ~= nil then
            ServerCastSkyPierceAt(owner, data.x, data.z)
        end
    end)
end)

-- 与 wigfrid_inspiration_release 相同：RPC 只 PushEvent，服务端再施放
AddModRPCHandler("my_mod", "wigfrid_sky_pierce_cast", function(inst, x, z)
    if inst ~= nil and inst:IsValid() and inst.prefab == "wathgrithr" then
        inst:PushEvent("custom_sky_pierce_cast", { x = x, z = z })
    end
end)

AddClientModRPCHandler("my_mod", "sky_pierce_cast_ok", function(cd_seconds)
    if ThePlayer ~= nil then
        local duration = tonumber(cd_seconds) or SKY_PIERCE_COOLDOWN
        if duration > SKY_PIERCE_COOLDOWN then
            duration = SKY_PIERCE_COOLDOWN
        end
        ThePlayer._nm_sky_pierce_pending = nil
        if ThePlayer._nm_sky_pierce_pending_task ~= nil then
            ThePlayer._nm_sky_pierce_pending_task:Cancel()
            ThePlayer._nm_sky_pierce_pending_task = nil
        end
        if not ThePlayer:HasTag("nm_sky_pierce_locked") then
            ThePlayer:RemoveTag("busy")
        end
        SetSkyPierceCooldown(ThePlayer, duration)
    end
end)

AddClientModRPCHandler("my_mod", "sky_pierce_cast_fail", function()
    if ThePlayer ~= nil then
        ThePlayer._nm_sky_pierce_pending = nil
        if ThePlayer._nm_sky_pierce_pending_task ~= nil then
            ThePlayer._nm_sky_pierce_pending_task:Cancel()
            ThePlayer._nm_sky_pierce_pending_task = nil
        end
        ThePlayer:RemoveTag("busy")
        ClearSkyPierceCooldown(ThePlayer)
    end
end)

AddClientModRPCHandler("my_mod", "sky_pierce_cd_sync", function(remaining)
    if ThePlayer ~= nil then
        local duration = tonumber(remaining) or 0
        if duration > SKY_PIERCE_COOLDOWN then
            duration = SKY_PIERCE_COOLDOWN
        end
        if duration > 0 then
            ThePlayer._nm_sky_pierce_pending = nil
            SetSkyPierceCooldown(ThePlayer, duration)
        end
    end
end)

------------------------------------------------------------------------------------------------------------------------
-- Shift+R：已点月之护卫则走冲天刺（客户端先台词/校验）；否则与狂暴同款 RPC

local function TryMoonSkyPierceOnShiftR(player)
    if player == nil or player.prefab ~= "wathgrithr" then
        return false
    end
    if not HasWigfridSkill(player, WIGFRID_SKILL_LUNAR) then
        return false
    end

    if IsSkyPierceOnCooldown(player) then
        SaySkyPierceCdLine(player)
        return true
    end

    if player._nm_sky_pierce_pending then
        return true
    end

    local t = GetTime()
    if player._nm_sky_pierce_rpc_sent ~= nil and t - player._nm_sky_pierce_rpc_sent < SKY_PIERCE_RPC_DEBOUNCE then
        return true
    end

    local can_use, reason = CanUseSkyPierce(player)
    if not can_use then
        SaySkyPierceLine(player, reason)
        return true
    end

    local weapon = GetEquippedLightningSpear(player)
    if weapon == nil then
        SaySkyPierceLine(player, "spear_missing")
        return true
    end
    if not IsSpearCharged(weapon) then
        SaySkyPierceLine(player, "spear_recharge")
        return true
    end

    local pos = GetMouseGroundPos(player, SKY_PIERCE_RANGE)
    if pos == nil then
        pos = GetSkyPierceFallbackPos(player, SKY_PIERCE_RANGE)
    end
    if pos == nil then
        SaySkyPierceLine(player, "fail")
        return true
    end

    player._nm_sky_pierce_pending = true
    player._nm_sky_pierce_rpc_sent = t
    player:AddTag("busy")
    if player._nm_sky_pierce_pending_task ~= nil then
        player._nm_sky_pierce_pending_task:Cancel()
    end
    player._nm_sky_pierce_pending_task = player:DoTaskInTime(3, function(p)
        p._nm_sky_pierce_pending = nil
        p._nm_sky_pierce_pending_task = nil
        if not p:HasTag("nm_sky_pierce_locked") then
            p:RemoveTag("busy")
        end
    end)
    SendModRPCToServer(MOD_RPC["my_mod"]["wigfrid_sky_pierce_cast"], pos.x, pos.z)
    return true
end

local function SendWigfridInspirationRelease()
    SendModRPCToServer(MOD_RPC["my_mod"]["wigfrid_inspiration_release"])
end

function GLOBAL.NM_WigfridHandleShiftR()
    local player = GLOBAL.ThePlayer
    if player == nil or player.prefab ~= "wathgrithr" then
        return
    end
    if GLOBAL.TheInput == nil or not GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
        return
    end

    -- 已点月之护卫：Shift+R 只走冲天刺，绝不触发暗影狂暴（两者 CD 独立）
    if HasWigfridSkill(player, WIGFRID_SKILL_LUNAR) then
        TryMoonSkyPierceOnShiftR(player)
        return
    end

    if HasWigfridSkill(player, WIGFRID_SKILL_SHADOW) then
        SendWigfridInspirationRelease()
    end
end

-- 兼容旧调用名
function GLOBAL.NM_SkyPierceTryShiftR(player)
    return TryMoonSkyPierceOnShiftR(player)
end

STRINGS.RECIPE_DESC.SPEAR_WATHGRITHR_LIGHTNING_CHARGED = "头盔姐的闪电矛。解锁月之护卫后Shift+R释放冲天刺"
STRINGS.ACTIONS.CASTAOE.SPEAR_WATHGRITHR_LIGHTNING_CHARGED = "冲天刺"

------------------------------------------------------------------------------------------------------------------------
-- 充能奔雷矛：服务端追加 aoeweapon_leap

local function ShouldAllowLightningSpearLunge(owner)
    return true
end

local function IsWigfridLightningLungeBlocked(doer, weapon)
    return false
end

local function SetLightningSpearAoetargetingEnabled(spear, owner, enabled)
    local aoetargeting = spear ~= nil and spear.components.aoetargeting or nil
    if aoetargeting == nil then
        return
    end
    if TheWorld.ismastersim then
        if aoetargeting.enabled:value() ~= enabled then
            aoetargeting.enabled:set(enabled)
        end
        return
    end
    if owner == ThePlayer and owner ~= nil and owner:IsValid()
        and owner.components.playercontroller ~= nil then
        owner.components.playercontroller:RefreshReticule(enabled and spear or nil)
    end
end

local function UpdateLightningSpearLungeAccess(spear, owner)
    if spear == nil or not spear:IsValid() then
        return
    end
    if ShouldAllowLightningSpearLunge(owner) then
        if spear._nm_lunar_lunge_disabled then
            spear._nm_lunar_lunge_disabled = nil
            if not spear:HasTag("superjump") then
                spear:AddTag("aoeweapon_lunge")
            end
        end
        return
    end
    if spear:HasTag("aoeweapon_lunge") then
        spear:RemoveTag("aoeweapon_lunge")
        spear._nm_lunar_lunge_disabled = true
    end
    SetLightningSpearAoetargetingEnabled(spear, owner, false)
end

local function EnableNightmareSpearTargeting(spear, owner)
    if spear == nil or spear.components.aoetargeting == nil or owner == nil or owner.prefab ~= "wathgrithr" then
        return
    end
    if not ShouldAllowLightningSpearLunge(owner) then
        SetLightningSpearAoetargetingEnabled(spear, owner, false)
        return
    end
    if spear.components.rechargeable ~= nil and spear.components.rechargeable:IsCharged() then
        SetLightningSpearAoetargetingEnabled(spear, owner, true)
    end
end

local function RefreshEquippedLightningSpearLunge(owner)
    if owner == nil or not owner:IsValid() then
        return
    end
    local weapon = GetEquippedLightningSpear(owner)
    if weapon ~= nil then
        UpdateLightningSpearLungeAccess(weapon, owner)
        EnableNightmareSpearTargeting(weapon, owner)
    end
end

local function IsHandWeaponCharged(weapon)
    if weapon == nil then
        return false
    end
    if IsLightningSpearWeapon(weapon) then
        return IsSpearCharged(weapon)
    end
    if weapon.replica ~= nil and weapon.replica.rechargeable ~= nil then
        return weapon.replica.rechargeable:IsCharged()
    end
    if weapon.components.rechargeable ~= nil then
        return weapon.components.rechargeable:IsCharged()
    end
    return true
end

local function HandItemHasAoetargeting(item)
    if item == nil then
        return false
    end
    if item.components.aoetargeting ~= nil then
        return true
    end
    return item.replica ~= nil and item.replica.aoetargeting ~= nil
end

local function GetHandReticuleWeapon(owner)
    local spear = GetEquippedLightningSpear(owner)
    if spear ~= nil then
        return spear
    end
    local hand = GetEquippedHandItem(owner)
    if hand ~= nil and hand.prefab ~= "wathgrithr_shield" and HandItemHasAoetargeting(hand) then
        if IsHandWeaponCharged(hand) then
            return hand
        end
    end
    return nil
end

-- 背包格挡结束后恢复手上奔雷矛冲刺/冲天刺可用性（不触发 onequipfn）
function GLOBAL.NM_RefreshWigfridEquippedWeaponSkills(owner)
    if owner == nil or not owner:IsValid() then
        return
    end
    local weapon = GetEquippedLightningSpear(owner)
    if TheWorld.ismastersim then
        if weapon ~= nil then
            RestoreLungeWeaponMode(weapon)
            if not weapon._nm_sky_pierce_mode then
                weapon._nm_sky_pierce_aoetargeting_was_enabled = nil
                weapon._nm_old_aoetargeting_range = nil
                weapon._nm_old_spellfn = nil
                if weapon:HasTag("superjump") then
                    weapon:RemoveTag("superjump")
                    if not weapon:HasTag("aoeweapon_lunge") then
                        weapon:AddTag("aoeweapon_lunge")
                    end
                end
            end
        end
        RefreshEquippedLightningSpearLunge(owner)
        if owner.userid ~= nil then
            SendModRPCToClient(GetClientModRPC("my_mod", "wigfrid_weapon_skill_refresh"), owner.userid)
        end
    end
    local reticule_weapon = GetHandReticuleWeapon(owner)
    if owner.components.playercontroller ~= nil then
        owner.components.playercontroller:CancelAOETargeting()
        owner.components.playercontroller:RefreshReticule(reticule_weapon)
    end
end

AddClientModRPCHandler("my_mod", "wigfrid_weapon_skill_refresh", function()
    if ThePlayer ~= nil and GLOBAL.NM_RefreshWigfridEquippedWeaponSkills ~= nil then
        GLOBAL.NM_RefreshWigfridEquippedWeaponSkills(ThePlayer)
    end
end)

local function BindLightningSpearLungeControl(inst)
    if inst._nm_lunge_control_bound then
        return
    end
    inst._nm_lunge_control_bound = true

    if inst.components.equippable ~= nil then
        local old_onequip = inst.components.equippable.onequipfn
        local old_onunequip = inst.components.equippable.onunequipfn
        inst.components.equippable:SetOnEquip(function(equipped, owner)
            if old_onequip ~= nil then
                old_onequip(equipped, owner)
            end
            UpdateLightningSpearLungeAccess(equipped, owner)
            EnableNightmareSpearTargeting(equipped, owner)
        end)
        inst.components.equippable:SetOnUnequip(function(equipped, owner)
            if old_onunequip ~= nil then
                old_onunequip(equipped, owner)
            end
            SetLightningSpearAoetargetingEnabled(equipped, owner, false)
        end)
    end

    if inst.components.rechargeable ~= nil then
        local old_oncharged = inst.components.rechargeable.onchargedfn
        local old_ondischarged = inst.components.rechargeable.ondischargedfn
        inst.components.rechargeable:SetOnChargedFn(function(spear)
            if old_oncharged ~= nil then
                old_oncharged(spear)
            end
            local owner = spear.components.inventoryitem ~= nil and spear.components.inventoryitem:GetGrandOwner() or nil
            UpdateLightningSpearLungeAccess(spear, owner)
            EnableNightmareSpearTargeting(spear, owner)
        end)
        inst.components.rechargeable:SetOnDischargedFn(function(spear)
            if old_ondischarged ~= nil then
                old_ondischarged(spear)
            end
            if TheWorld.ismastersim then
                RestoreLungeWeaponMode(spear)
            end
            local owner = spear.components.inventoryitem ~= nil and spear.components.inventoryitem:GetGrandOwner() or nil
            SetLightningSpearAoetargetingEnabled(spear, owner, false)
        end)
    end
end

AddPrefabPostInit(SPEAR_PREFAB_CHARGED, function(inst)
    if inst.components.aoetargeting ~= nil then
        inst.components.aoetargeting:SetAllowRiding(true)
    end
    BindLightningSpearLungeControl(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("battlesong")

    if inst.components.aoespell == nil then
        inst:AddComponent("aoespell")
    end

    if inst.components.aoeweapon_leap == nil then
        inst:AddComponent("aoeweapon_leap")
    end
    inst.components.aoeweapon_leap:SetAOERadius(SKY_PIERCE_LUNGE_AOE_DEFAULT)
    inst.components.aoeweapon_leap:SetStimuli("electric")
    inst.components.aoeweapon_leap:SetOnLeaptFn(Lightning_OnLeap)
    inst.components.aoeweapon_leap:SetOnPreLeapFn(Lighting_OnLeapPre)
    inst.components.aoeweapon_leap:SetOnHitFn(SkyPierce_OnHit)
    inst.components.aoeweapon_leap:SetTags("_combat")
    inst.components.aoeweapon_leap:SetNoTags("FX", "DECOR", "INLIMBO", "moonstorm_static", "wall")
    inst.components.aoeweapon_leap:SetWorkActions(ACTIONS.CHOP, ACTIONS.MINE)

    inst._cooldown = inst._cooldown or TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LUNGE_COOLDOWN

    inst:ListenForEvent("superjumpstarted", function(spear, doer)
        if spear._nm_sky_pierce_mode and doer ~= nil and doer:IsValid() then
            CommitSkyPierceCost(doer)
        end
    end)

    inst:ListenForEvent("superjumpcancelled", function(spear, doer)
        Lightning_ResetElectric(inst)
        RestoreSkyPierceDamage(inst)
        RestoreLungeWeaponMode(inst)
        local owner = doer
        if owner == nil or not owner:IsValid() then
            owner = spear.components.inventoryitem ~= nil and spear.components.inventoryitem:GetGrandOwner() or nil
        end
        ClearSkyPierceLandingArmor(owner)
        if owner ~= nil and owner:IsValid() then
            EndSkyPierceLock(owner, owner._nm_sky_pierce_cost_pending == true)
        end
    end)
end)

AddPrefabPostInit(SPEAR_PREFAB_LIGHTNING, function(inst)
    BindLightningSpearLungeControl(inst)
end)

AddPrefabPostInit("wathgrithr", function(inst)
    local function OnWigfridAllegianceSkillChange(owner, data)
        if data == nil or data.skill == WIGFRID_SKILL_LUNAR or data.skill == WIGFRID_SKILL_SHADOW then
            RefreshEquippedLightningSpearLunge(owner)
        end
    end

    inst:ListenForEvent("onactivateskill_client", OnWigfridAllegianceSkillChange)
    inst:ListenForEvent("ondeactivateskill_client", OnWigfridAllegianceSkillChange)
    inst:ListenForEvent("onactivateskill_server", OnWigfridAllegianceSkillChange)
    inst:ListenForEvent("ondeactivateskill_server", OnWigfridAllegianceSkillChange)

    inst:ListenForEvent("equip", function(owner, data)
        if data == nil or data.eslot ~= EQUIPSLOTS.HANDS or data.item == nil then
            return
        end
        if not IsLightningSpearWeapon(data.item) then
            return
        end
        UpdateLightningSpearLungeAccess(data.item, owner)
        EnableNightmareSpearTargeting(data.item, owner)
    end)

    inst:DoTaskInTime(0, function()
        if inst:IsValid() then
            RefreshEquippedLightningSpearLunge(inst)
        end
    end)
end)

AddComponentPostInit("aoetargeting", function(self)
    local old_SetEnabled = self.SetEnabled
    self.SetEnabled = function(cmp, enabled)
        local weapon = cmp.inst
        if enabled and weapon ~= nil and IsLightningSpearWeapon(weapon) and not weapon._nm_sky_pierce_mode then
            local owner = weapon.components.inventoryitem ~= nil and weapon.components.inventoryitem:GetGrandOwner() or nil
            if not ShouldAllowLightningSpearLunge(owner) then
                enabled = false
            end
        end
        return old_SetEnabled(cmp, enabled)
    end
end)

AddComponentPostInit("aoespell", function(self)
    local old_CanCast = self.CanCast
    self.CanCast = function(cmp, doer, pos)
        if IsWigfridLightningLungeBlocked(doer, cmp.inst) then
            return false
        end
        return old_CanCast(cmp, doer, pos)
    end

    local old_CastSpell = self.CastSpell
    self.CastSpell = function(cmp, doer, pos)
        if IsWigfridLightningLungeBlocked(doer, cmp.inst) then
            return false
        end
        return old_CastSpell(cmp, doer, pos)
    end
end)

AddComponentPostInit("aoeweapon_lunge", function(self)
    local old_DoLunge = self.DoLunge
    self.DoLunge = function(cmp, doer, startingpos, targetpos)
        if IsWigfridLightningLungeBlocked(doer, cmp.inst) then
            return false
        end
        return old_DoLunge(cmp, doer, startingpos, targetpos)
    end
end)

AddSimPostInit(function()
    if ACTIONS ~= nil and ACTIONS.CASTAOE ~= nil and ACTIONS.CASTAOE.fn ~= nil
        and not ACTIONS.CASTAOE._nm_wigfrid_lunar_lunge_block then
        ACTIONS.CASTAOE._nm_wigfrid_lunar_lunge_block = true
        local old_castaoe_fn = ACTIONS.CASTAOE.fn
        ACTIONS.CASTAOE.fn = function(act)
            local weapon = act.invobject
            if weapon == nil and act.doer ~= nil and act.doer.components.inventory ~= nil then
                weapon = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            end
            if IsWigfridLightningLungeBlocked(act.doer, weapon) then
                return false
            end
            return old_castaoe_fn(act)
        end
    end

    local skilltreedefs = require("prefabs/skilltree_defs")
    local defs = skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.wathgrithr
    if defs ~= nil and defs.wathgrithr_allegiance_lunar ~= nil then
        local old_onactivate = defs.wathgrithr_allegiance_lunar.onactivate
        defs.wathgrithr_allegiance_lunar.onactivate = function(player, ...)
            if old_onactivate ~= nil then
                old_onactivate(player, ...)
            end
            RefreshEquippedLightningSpearLunge(player)
        end
        local old_ondeactivate = defs.wathgrithr_allegiance_lunar.ondeactivate
        defs.wathgrithr_allegiance_lunar.ondeactivate = function(player, ...)
            if old_ondeactivate ~= nil then
                old_ondeactivate(player, ...)
            end
            RefreshEquippedLightningSpearLunge(player)
        end
    end
end)


local function OnRemoveCleanupTargetFX(inst)
    if inst.sg.statemem.targetfx == nil then
        return
    end
    if inst.sg.statemem.targetfx.KillFX ~= nil then
        inst.sg.statemem.targetfx:RemoveEventCallback("onremove", OnRemoveCleanupTargetFX, inst)
        inst.sg.statemem.targetfx:KillFX()
    else
        inst.sg.statemem.targetfx:Remove()
    end
end

local function PatchSkyPierceInterruptEvent(sg, eventname)
    local event = sg.events[eventname]
    if event == nil or event._nm_sky_pierce_patch then
        return
    end
    local old_fn = event.fn
    event.fn = function(inst, data)
        if IsSkyPierceNoInterrupt(inst) or inst:HasTag("battlesong_nointerrupt") or inst:HasTag("playerghost") then
            return
        end
        if old_fn ~= nil then
            return old_fn(inst, data)
        end
    end
    event._nm_sky_pierce_patch = true
end

local function PatchSuperjumpStategraph(sg)
    if sg.events["attacked"] ~= nil and sg.events["attacked"]._nm_light_pro_patch == nil then
        local old_attacked_fn = sg.events["attacked"].fn
        sg.events["attacked"].fn = function(inst, data)
            if IsSkyPierceNoInterrupt(inst) or inst:HasTag("battlesong_nointerrupt") or inst:HasTag("playerghost") then
                return
            elseif old_attacked_fn ~= nil then
                return old_attacked_fn(inst, data)
            end
        end
        sg.events["attacked"]._nm_light_pro_patch = true
    end

    PatchSkyPierceInterruptEvent(sg, "knockback")
    PatchSkyPierceInterruptEvent(sg, "repelled")
    PatchSkyPierceInterruptEvent(sg, "startled")
    PatchSkyPierceInterruptEvent(sg, "wx78_spark")

    local superjump_start = sg.states["combat_superjump_start"]
    if superjump_start ~= nil and superjump_start._nm_light_pro_patch == nil then
        superjump_start.onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("sing_pre")
            else
                inst.AnimState:PlayAnimation("superjump_pre")
            end

            local weapon = GetEquippedHandItem(inst)
            if weapon ~= nil and weapon.components.aoetargeting ~= nil then
                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    inst.sg.statemem.targetfx = weapon.components.aoetargeting:SpawnTargetFXAt(buffaction:GetDynamicActionPoint())
                    if inst.sg.statemem.targetfx ~= nil then
                        inst.sg.statemem.targetfx:ListenForEvent("onremove", OnRemoveCleanupTargetFX, inst)
                    end
                end
            end
        end

        if superjump_start.events["animover"] ~= nil then
            superjump_start.events["animover"].fn = function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.AnimState:IsCurrentAnimation("superjump_pre") or inst.AnimState:IsCurrentAnimation("sing_pre") then
                        if inst.components.rider ~= nil then
                            inst.components.rider:ActualDismount()
                        end
                        inst.AnimState:PlayAnimation("superjump_lag")
                        inst:PerformBufferedAction()
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end
        end

        superjump_start._nm_light_pro_patch = true
    end

    local superjump_pst = sg.states["combat_superjump_pst"]
    if superjump_pst ~= nil and superjump_pst._nm_sky_pierce_patch == nil then
        local old_onexit = superjump_pst.onexit
        superjump_pst.onexit = function(inst)
            if old_onexit ~= nil then
                old_onexit(inst)
            end
            if inst.prefab == "wathgrithr" and inst:HasTag("nm_sky_pierce_locked") then
                EndSkyPierceLock(inst, false)
            end
        end
        superjump_pst._nm_sky_pierce_patch = true
    end
end

AddStategraphPostInit("wilson", PatchSuperjumpStategraph)
AddStategraphPostInit("wilson_client", PatchSuperjumpStategraph)

------------------------------------------------------------------------------------------------------------------------
-- Shift+R：充能闪电矛 + 月曲歌唱家 → 冲天刺；否则 → 暗影女猎手狂暴（独立于 wx78 模块）

if GLOBAL.TheInput ~= nil then
    GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
        if GLOBAL.NM_WigfridHandleShiftR ~= nil then
            GLOBAL.NM_WigfridHandleShiftR()
        end
    end)
end
