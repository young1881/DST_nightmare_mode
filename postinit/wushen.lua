local inspiration_duration = 90           --暴怒状态的时间
local weakness_duration = 40              --暴怒结束后，虚弱的持续时间
local sleepy_duraiton = 1                 --进入虚弱相当于吃几发吹箭
local best_cd = 0.35                      --满灵感进入暴怒的时候，奔雷矛冲刺的cd
local worst_cd = 2.25                     --虚弱状态的奔雷矛cd
local planar_bonus = 20                   --暴怒状态额外的位面伤害

TUNING.INSPIRATION_DRAIN_RATE = -1        -- 脱离战斗后每秒掉灵感 原版-2
TUNING.INSPIRATION_DRAIN_BUFFER_TIME = 25 -- 多久算脱离战斗 原版7.5

--获取灵感值
local function GetInspiration(inst)
    if inst.components.singinginspiration ~= nil then
        return inst.components.singinginspiration:GetPercent()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentinspiration:value() / TUNING.INSPIRATION_MAX
    else
        return 0
    end
end

local function CheckValidAttackData(attacker, data)
    if data then
        if data.projectile and data.projectile.components.projectile and data.projectile.components.projectile:IsBounced() then
            --bounced projectiles don't count
            return false
        elseif data.weapon and data.weapon.components.inventoryitem == nil then
            --fake "weapons" used for detached aoe dmg don't count (e.g. flamethrower_fx)
            return false
        end
    end
    return true
end

local function AddEnemyDebuffFx(fx, target)
    target:DoTaskInTime(math.random() * 0.25, function()
        local x, y, z = target.Transform:GetWorldPosition()
        local fx = SpawnPrefab(fx)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end

        return fx
    end)
end

local function SetInspireLight(inst, enable)
    if enable then
        if inst.Light == nil then
            inst.entity:AddLight()
        end
        inst.Light:SetRadius(1.0)
        inst.Light:SetFalloff(0.5)
        inst.Light:SetIntensity(0.4)
        inst.Light:SetColour(1.0, 0, 0) -- 红色光
        inst.Light:Enable(true)
    else
        if inst.Light ~= nil then
            inst.Light:Enable(false)
        end
    end
end

local function SetWeaknessLight(inst, enable)
    if enable then
        if inst.Light == nil then
            inst.entity:AddLight()
        end
        inst.Light:SetRadius(1.0)
        inst.Light:SetFalloff(0.5)
        inst.Light:SetIntensity(0.4)
        inst.Light:SetColour(0, 0, 1.0) -- 蓝色光
        inst.Light:Enable(true)
    else
        if inst.Light ~= nil then
            inst.Light:Enable(false)
        end
    end
end

local function CheckEquipment(inst)
    local equippedItem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equippedItem ~= nil and equippedItem:HasTag("rechargeable") and equippedItem._cooldown ~= nil then
        if inst.inspired_percent ~= nil and inst:HasTag("inspired") then
            equippedItem._cooldown = 1.5 - inst.inspired_percent * (1.5 - best_cd)
        elseif inst:HasTag("inspired") then
            equippedItem._cooldown = worst_cd
        else
            equippedItem._cooldown = TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LUNGE_COOLDOWN
        end
    end
end


local function ActivateInspirationBuff(inst, percent)
    if inst.inspirationbufftask ~= nil then
        inst.inspirationbufftask:Cancel()
    end
    inst:DoTaskInTime(0.8, function()
    if math.random() < 0.8 then
        -- inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/battle_cry")
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/characters/wathgrithr/song/durability")
    else
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/characters/wathgrithr/song/sanityaura")
    end
end)

    SetInspireLight(inst, true)

    inst.buff_end_time = GLOBAL.GetTime() + inspiration_duration
    inst.weakness_start_time = nil

    local max_health_gain = TUNING.BATTLESONG_HEALTHGAIN_DELTA_SINGER
    local health_gain = max_health_gain * percent

    local function OnAttackOther(inst, data)
        if CheckValidAttackData(inst, data) then
            if inst.components.health then
                inst.components.health:DoDelta(health_gain)
            end
        end
    end
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:AddTag("inspired")
    -- inst:AddTag("nolootinspiration")

    AddEnemyDebuffFx("battlesong_instant_panic_fx", inst)

    if inst.components.planardamage then
        inst.components.planardamage:SetBaseDamage(planar_bonus * percent)
    else
        inst:AddComponent("planardamage")
        inst.components.planardamage:SetBaseDamage(planar_bonus * percent)
    end

    -- inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD / (1 + percent))
    inst.inspirationbufftask = inst:DoTaskInTime(inspiration_duration, function()
        -- Buff 结束时进入虚弱
        inst.buff_end_time = nil

        inst:RemoveTag("inspired")
        inst.inspired_percent = nil
        -- inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)

        inst:RemoveEventCallback("onattackother", OnAttackOther)
        inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
        inst.components.health:SetAbsorptionAmount(0)

        if inst.components.grogginess then
            inst.components.grogginess:AddGrogginess(sleepy_duraiton, 10)
        end

        AddEnemyDebuffFx("battlesong_instant_panic_fx", inst)
        SetInspireLight(inst, false)
        SetWeaknessLight(inst, true)

        if inst.components.planardamage then
            inst.components.planardamage:SetBaseDamage(0)
        end

        inst:AddTag("nolootinspiration")
        inst.components.singinginspiration:SetPercent(0)
        inst.components.talker:Say("即使是最强的女武神也需要小憩一下")
        inst:DoTaskInTime(0.5, function()
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/characters/wathgrithr/fail")
        end)

        -- 虚弱状态结束后进入平常状态
        inst.weakness_start_time = GLOBAL.GetTime()
        inst:DoTaskInTime(weakness_duration, function()
            inst.weakness_start_time = nil
            inst:RemoveTag("nolootinspiration")
            inst.components.health:SetAbsorptionAmount(TUNING.WATHGRITHR_ABSORPTION)
            SetWeaknessLight(inst, false)
            inst.components.talker:Say("重新回到最佳状态，现在的我战无不胜！")
        end)
    end)
end

local function TriggerInspirationRelease(inst)
    local percent = GetInspiration(inst)

    -- 情况 1：如果激活期间再次触发，显示剩余时间
    if inst.buff_end_time ~= nil then
        local remaining_time = math.ceil(inst.buff_end_time - GLOBAL.GetTime())
        inst.components.talker:Say(string.format("我仍然保持炽热的战斗之心！（保持最佳状态 %d 秒）.", remaining_time))
        return
    end

    -- 情况 2：如果在虚弱状态中触发，显示剩余虚弱时间
    if inst.weakness_start_time ~= nil then
        local remaining_weakness = math.ceil(inst.weakness_start_time + weakness_duration - GLOBAL.GetTime())
        inst.components.talker:Say(string.format("强大的战士懂得如何快速休息来达到最佳状态（还需要休息 %d 秒）", remaining_weakness))
        return
    end

    -- 情况 3：正常激活逻辑
    if percent > 0.6 then
        inst.inspired_percent = percent
        if inst.components.singinginspiration ~= nil then
            inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT + 0.75 * percent
        elseif inst.player_classified ~= nil then
            inst.player_classified.currentinspiration:set(0)
        end

        if inst.components.talker ~= nil then
            inst.components.talker:Say(string.format("吾将亲手将你送至英灵神殿！（已激发 %.0f%% 的灵感潜能）", percent * 100))
        end
        ActivateInspirationBuff(inst, percent)
    else
        if inst.components.talker ~= nil then
            inst.components.talker:Say("一位真正的战士需要一场充满荣耀的战斗!")
        end
    end
end

local function OnGetItem(inst, data)
    local item = data ~= nil and data.item or nil

    if item ~= nil and item:HasTag("battlesong") then
        item.components.inventoryitem.keepondeath = item.prefab
        item.components.inventoryitem.keepondrown = true
        item:AddTag("nosteal")
    end
end

local function OnLoseItem(inst, data)
    local item = data ~= nil and (data.prev_item or data.item)
    if item and item:IsValid() and item:HasTag("battlesong") then
        item.components.inventoryitem.keepondeath = false
        item.components.inventoryitem.keepondrown = false
        item:RemoveTag("nosteal")
    end
end

--越战越勇
AddPrefabPostInit("wathgrithr", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("writer")
    inst.inspired_percent = nil

    inst:ListenForEvent("custom_inspiration_release", function(inst)
        TriggerInspirationRelease(inst)
    end)

    inst:ListenForEvent("itemget", OnGetItem)
    inst:ListenForEvent("equip", OnGetItem)
    inst:ListenForEvent("itemlose", OnLoseItem)
    inst:ListenForEvent("unequip", OnLoseItem)

    inst:DoPeriodicTask(0.5, function()
        CheckEquipment(inst)
        if inst:HasTag("nolootinspiration") then
            inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
        elseif inst:HasTag("inspired") then
            inst.components.combat.damagemultiplier = math.max(inst.components.combat.damagemultiplier,
                TUNING.WATHGRITHR_DAMAGE_MULT + 0.75 * GetInspiration(inst))
        else
            inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT + 0.5 * GetInspiration(inst)
        end
    end)
end)

AddModRPCHandler("my_mod", "inspiration_release", function(inst)
    inst:PushEvent("custom_inspiration_release")
end)

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
    if GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.prefab == "wathgrithr" and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
        SendModRPCToServer(MOD_RPC["my_mod"]["inspiration_release"])
    end
end)

-- 防火假声双配方
AddRecipe2("battlesong_fireresistance2",
    { Ingredient("papyrus", 1), Ingredient("featherpencil", 1), Ingredient("dragon_scales", 1) }, TECH.NONE_TWO,
    {
        product = "battlesong_fireresistance",
        image = "battlesong_fireresistance.tex",
        description =
        "battlesong_fireresistance2",
        builder_tag = "battlesinger"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.BATTLESONG_FIRERESISTANCE2 = "或许还有另一种防火的方法"

--闪电矛
AddRecipe2("spear_wathgrithr_lightning_charged",
    { Ingredient("spear_wathgrithr", 1), Ingredient("transistor", 3), Ingredient("purebrilliance", 3) }, TECH.NONE_TWO,
    { builder_tag = "valkyrie" }, { "CHARACTER" })
STRINGS.RECIPE_DESC.SPEAR_WATHGRITHR_LIGHTNING_CHARGED = "头盔姐的闪电矛"

AddPrefabPostInit("spear_wathgrithr_lightning_charged", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:AddTag("battlesong")
end)

-- 战斗号子罐
Recipe2("battlesong_container",
    { Ingredient("boards", 2), Ingredient("goldnugget", 3), Ingredient("feather_crow", 2), Ingredient("feather_robin", 5),
        Ingredient("beeswax", 2) }, TECH.NONE, { builder_skill = "wathgrithr_songs_container" })

-- 不可燃
AddPrefabPostInit("battlesong_container", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:RemoveComponent("burnable")
    inst:AddTag("battlesong")
end)


AddPrefabPostInit("battlesong_instant_revive", function(inst)
    inst.cast_scope = TUNING.BATTLESONG_ATTACH_RADIUS
end)

AddComponentPostInit("battleborn", function(self)
	self.OnAttack = function(self, data)
	
		local victim = data.target
		if not self.inst.components.health:IsDead() and (self.validvictimfn == nil or self.validvictimfn(victim)) then
			local total_health = victim.components.health:GetMaxWithPenalty()
			local damage = (data.weapon ~= nil and data.weapon.components.weapon:GetDamage(self.inst, victim))
						or self.inst.components.combat.defaultdamage
			if damage > 0 or self.allow_zero then
				local percent = (damage <= 0 and 0)
							or (total_health <= 0 and math.huge)
							or damage / total_health
	
				--math and clamp does account for 0 and infinite cases
				local delta = math.clamp(victim.components.combat.defaultdamage * self.battleborn_bonus * percent, self.clamp_min, self.clamp_max)
	
				--decay stored battleborn
				if self.battleborn > 0 then
					local dt = GetTime() - self.battleborn_time - self.battleborn_store_time
					if dt >= self.battleborn_decay_time then
						self.battleborn = 0
					elseif dt > 0 then
						local k = dt / self.battleborn_decay_time
						self.battleborn = Lerp(self.battleborn, 0, k * k)
					end
				end
	
				--store new battleborn
				self.battleborn = self.battleborn + delta
				self.battleborn_time = GetTime()
	
				--consume battleborn if enough has been stored
				if self.battleborn > self.battleborn_trigger_threshold then
					if self.health_enabled then
						if self.inst.components.health:IsHurt() then
							self.inst.components.health:DoDelta(self.battleborn, false, "battleborn")
	
						end
						if self.inst.components.inventory ~= nil then
							self.inst.components.inventory:ForEachEquipment(self.RepairEquipment, self.battleborn)
						end
					end
	
					if self.sanity_enabled then
						self.inst.components.sanity:DoDelta(self.battleborn)
					end
	
					if self.ontriggerfn ~= nil then
						self.ontriggerfn(self.inst, self.battleborn)
					end
	
					self.battleborn = 0
				end
			end
		end
	end
end)

