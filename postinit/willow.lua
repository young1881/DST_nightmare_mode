TUNING.WILLOW_EMBER_LUNAR = 3                  --月火费用
TUNING.WILLOW_FIREFRENZY_MULT = 1.75           --燃烧斗士伤害提高
TUNING.WILLOW_LUNAR_FIRE_BONUS = 1.25          --月火增伤百分之25
TUNING.WILLOW_LUNAR_FIRE_TIME = 3.5            --月火持续时间
TUNING.WILLOW_LUNAR_FIRE_DAMAGE = 38.5            --月火的伤害
TUNING.WILLOW_LUNAR_FIRE_PLANAR_DAMAGE =28.5     --月火的位面伤害
TUNING.WILLOW_LUNAR_FIRE_COOLDOWN = 4.5        --月火cd
TUNING.CHANNELCAST_SPEED_MOD = 90 / 100        --放月火时的移速
TUNING.WILLOW_BERNIE_HEALTH_REGEN_PERIOD = 1.5 --伯尼回血判定时间
TUNING.WILLOW_BERNIE_HEALTH_REGEN_1 = 400      --伯尼一级回血每秒回4
TUNING.WILLOW_BERNIE_HEALTH_REGEN_2 = 800      --伯尼二级回血每秒回8
TUNING.WILLOW_FIREFRENZY_DURATION = 50--神秘狂热焚烧持续时间
TUNING.WILLOW_EMBER_FRENZY = 5                        --神秘狂热焚烧的费用

local WILLOW_EMBER_MAX_STACK = 80

local function RogeSetWillowEmberMaxStack(inst)
	if not TheWorld.ismastersim or inst.components.stackable == nil then
		return
	end
	local stackable = inst.components.stackable
	local priv = rawget(stackable, "_")
	if priv ~= nil then
		priv.maxsize[1] = WILLOW_EMBER_MAX_STACK
	end
	-- 80 不在 stackable_replica 编码表内，直接赋值会崩溃；服务端写内部字段，replica 用合法档位占位
	if inst.replica ~= nil and inst.replica.stackable ~= nil then
		inst.replica.stackable:SetMaxSize(TUNING.STACK_SIZE_PELLET)
	end
end


--余烬
AddRecipe2("willow_ember",
    { Ingredient("lighter", 0), Ingredient("ash", 3), Ingredient("willow_ember", 1) },
    TECH.SCIENCE_ONE,
    {
        numtogive = 6,
        builder_tag = "bernieowner",
    }, { "CHARACTER" })

AddRecipe2("willow_ember_ruby",
    { Ingredient("redgem", 5), Ingredient("willow_ember", 10) },
    TECH.SCIENCE_ONE,
    {
        product = "willow_ember",
        numtogive = 60,
        builder_tag = "bernieowner",
    }, { "CHARACTER" })


    local LUNAR_BERNIE_SKILL = "willow_allegiance_lunar_bernie"
    local BURNING_SELF_DURATION = 60 -- 烈焰加身（亮茄爆炸技能）持续 1 分钟
    local BURN_SELF_EMBER_COST = 10
    local BURN_SELF_EMBER_MSG = "火焰！我需要更多的火焰！"
    local BURN_SELF_RPC_DEBOUNCE = 0.35
    local WILLOW_SELF_FIRE_SCALE = 0.62
    local WILLOW_SELF_FIRE_LIGHT_RADIUS = 1.15
    local WILLOW_SELF_FRENZY_SCALE = 1.25
    local WILLOW_SELF_FIRE_MULT_COLOUR = { 1, 0.7, 0, 0.3 }
    local WILLOW_SELF_FIRE_LIGHT_COLOUR = { 1, 0.55, 0.15 }
    local WILLOW_SELF_FRENZY_MULT_COLOUR = { 1, 0.75, 0.25, 0.35 }
    -- 亮茄炸弹爆炸：范围与贴图在原版基础上放大 0.5 倍（×1.5）
    local WILLOW_SELF_EXPLODE_SCALE_MULT = 1.5
    local BURN_SELF_EXPLODE_RANGE = TUNING.BOMB_LUNARPLANT_RANGE * WILLOW_SELF_EXPLODE_SCALE_MULT
    local BURN_SELF_COUNTER_MIN = 30
    local BURN_SELF_COUNTER_MAX = 50
    local BURN_SELF_EXPLODE_HITS = 5
    local BURN_SELF_EXPLODE_DURATION_PENALTY = 3
    local BURN_SELF_EXPLODE_PHYSICAL_MIN = 150
    local BURN_SELF_EXPLODE_PHYSICAL_MAX = 250
    local BURN_SELF_EXPLODE_PLANAR_MIN = 150
    local BURN_SELF_EXPLODE_PLANAR_MAX = 200
    local BURN_SELF_FX_EXTRA = 1
    local BURN_SELF_LUNAR_SHARD_COUNT = 8
    local EXPLODE_MUST_TAGS = { "_combat" }
    local EXPLODE_CANT_TAGS = { "INLIMBO", "notarget", "player", "companion", "wall", "structure" }
    local EXPLODE_CANT_TAGS_PVP = { "INLIMBO", "notarget", "wall", "structure" }

    local WillowEndBurningSelf
    local WillowReduceBurningSelfDuration
    local WillowOnAttackedWhileBurning

    local function HasLunarBernieSkill(player)
        if player == nil then
            return false
        end
        if player.components.skilltreeupdater ~= nil then
            return player.components.skilltreeupdater:IsActivated(LUNAR_BERNIE_SKILL)
        end
        if player.replica ~= nil and player.replica.skilltreeupdater ~= nil then
            return player.replica.skilltreeupdater:IsActivated(LUNAR_BERNIE_SKILL)
        end
        return false
    end

    local function CountEmbers(doer)
        if doer == nil or doer.components.inventory == nil then
            return 0
        end

        local inventory = doer.components.inventory
        local count = 0
        for i = 1, inventory:GetNumSlots() do
            local item = inventory:GetItemInSlot(i)
            if item ~= nil and item.prefab == "willow_ember" and item.components.stackable ~= nil then
                count = count + item.components.stackable:StackSize()
            end
        end

        local active_item = inventory:GetActiveItem()
        if active_item ~= nil and active_item.prefab == "willow_ember" and active_item.components.stackable ~= nil then
            count = count + active_item.components.stackable:StackSize()
        end

        return count
    end

    local function HasEnoughEmbers(player, amount)
        if player == nil then
            return false
        end
        if player.replica ~= nil and player.replica.inventory ~= nil then
            return player.replica.inventory:Has("willow_ember", amount)
        end
        return CountEmbers(player) >= amount
    end

    local function ConsumeEmbersFromInventory(doer, amount)
        if amount <= 0 or doer == nil or doer.components.inventory == nil then
            return
        end

        local inventory = doer.components.inventory
        for i = 1, inventory:GetNumSlots() do
            if amount <= 0 then
                break
            end
            local item = inventory:GetItemInSlot(i)
            if item ~= nil and item.prefab == "willow_ember" and item.components.stackable ~= nil then
                local stacksize = item.components.stackable:StackSize()
                if stacksize > amount then
                    item.components.stackable:SetStackSize(stacksize - amount)
                    amount = 0
                else
                    amount = amount - stacksize
                    inventory:RemoveItem(item, true):Remove()
                end
            end
        end

        if amount > 0 then
            local active_item = inventory:GetActiveItem()
            if active_item ~= nil and active_item.prefab == "willow_ember" and active_item.components.stackable ~= nil then
                local stacksize = active_item.components.stackable:StackSize()
                if stacksize > amount then
                    active_item.components.stackable:SetStackSize(stacksize - amount)
                else
                    inventory:RemoveItem(active_item, true):Remove()
                end
            end
        end
    end

    local function SayNotEnoughEmbers(inst)
        if inst ~= nil and inst.components.talker ~= nil then
            inst.components.talker:Say(BURN_SELF_EMBER_MSG)
        end
    end

    local function SpawnWillowSelfBurnGroundPuff(x, y, z)
        for i = 1, 2 do
            local puff = SpawnPrefab("lunarflame_puff_tiny")
            if puff ~= nil then
                local radius = math.random() * 0.8
                local theta = math.random() * TWOPI
                puff.Transform:SetPosition(x + math.cos(theta) * radius, y, z - math.sin(theta) * radius)
                puff.Transform:SetRotation(math.random(360))
            end
        end
    end

    local function ExtendWillowSelfBurnFxLifetime(fx)
        if fx == nil or not fx:IsValid() then
            return
        end
        fx:RemoveEventCallback("animover", fx.Remove)
        fx:ListenForEvent("animover", function(inst)
            if inst:IsValid() then
                if inst.AnimState ~= nil then
                    inst.AnimState:Pause()
                end
                inst:DoTaskInTime(BURN_SELF_FX_EXTRA, inst.Remove)
            end
        end)
    end

    local function ScaleWillowSelfBurnFx(fx)
        if fx ~= nil and fx:IsValid() and fx.Transform ~= nil then
            fx.Transform:SetScale(
                WILLOW_SELF_EXPLODE_SCALE_MULT,
                WILLOW_SELF_EXPLODE_SCALE_MULT,
                WILLOW_SELF_EXPLODE_SCALE_MULT)
        end
    end

    local function SpawnWillowSelfBurnLunarShardAt(x, y, z, radius)
        local shard = SpawnPrefab("lunarflame_puff_tiny")
        if shard ~= nil then
            local theta = math.random() * TWOPI
            shard.Transform:SetPosition(x + math.cos(theta) * radius, y, z - math.sin(theta) * radius)
            shard.Transform:SetRotation(math.random(360))
            ScaleWillowSelfBurnFx(shard)
            ExtendWillowSelfBurnFxLifetime(shard)
        end
    end

    local function ExtendWillowSelfBurnExplodeFx(explode_fx)
        ScaleWillowSelfBurnFx(explode_fx)
        ExtendWillowSelfBurnFxLifetime(explode_fx)
    end

    local function SpawnWillowSelfBurnLunarShards(x, y, z)
        for i = 1, BURN_SELF_LUNAR_SHARD_COUNT do
            SpawnWillowSelfBurnLunarShardAt(x, y, z, math.random() * BURN_SELF_EXPLODE_RANGE)
        end

        for i = 1, 4 do
            SpawnWillowSelfBurnLunarShardAt(x, y, z, math.random() * BURN_SELF_EXPLODE_RANGE * 0.6)
        end
    end

    WillowEndBurningSelf = function(inst)
        if inst._willow_frenzy_fx ~= nil and inst._willow_frenzy_fx:IsValid() then
            if inst._willow_frenzy_fx.Kill ~= nil then
                inst._willow_frenzy_fx:Kill()
            else
                inst._willow_frenzy_fx:Remove()
            end
            inst._willow_frenzy_fx = nil
        end
        if inst._willow_fire_fx ~= nil then
            if inst._willow_fire_fx.EndBernieFire ~= nil then
                inst._willow_fire_fx:EndBernieFire()
            else
                inst._willow_fire_fx:Remove()
            end
            inst._willow_fire_fx = nil
        end
        if inst._willow_fire_thorns_task ~= nil then
            inst._willow_fire_thorns_task:Cancel()
            inst._willow_fire_thorns_task = nil
        end
        inst._willow_burn_end_time = nil
        inst._willow_burn_hit_count = 0
        inst:RemoveEventCallback("attacked", WillowOnAttackedWhileBurning)
    end

    WillowReduceBurningSelfDuration = function(inst, amount)
        if inst._willow_fire_thorns_task == nil then
            return
        end

        inst._willow_fire_thorns_task:Cancel()
        inst._willow_fire_thorns_task = nil

        local remaining = (inst._willow_burn_end_time or GetTime()) - GetTime()
        remaining = remaining - amount
        if remaining <= 0 then
            WillowEndBurningSelf(inst)
        else
            inst._willow_burn_end_time = GetTime() + remaining
            inst._willow_fire_thorns_task = inst:DoTaskInTime(remaining, WillowEndBurningSelf)
        end
    end

    local function DoWillowSelfBurnExplosion(inst, attacker)
        local x, y, z = inst.Transform:GetWorldPosition()

        local explode_fx = SpawnPrefab("bomb_lunarplant_explode_fx")
        if explode_fx ~= nil then
            explode_fx.Transform:SetPosition(x, y, z)
            ExtendWillowSelfBurnExplodeFx(explode_fx)
        end

        SpawnWillowSelfBurnLunarShards(x, y, z)

        local cant_tags = TheNet:GetPVPEnabled() and EXPLODE_CANT_TAGS_PVP or EXPLODE_CANT_TAGS
        local ents = TheSim:FindEntities(x, y, z, BURN_SELF_EXPLODE_RANGE, EXPLODE_MUST_TAGS, cant_tags)
        local physical = math.random(BURN_SELF_EXPLODE_PHYSICAL_MIN, BURN_SELF_EXPLODE_PHYSICAL_MAX)
        local planar = math.random(BURN_SELF_EXPLODE_PLANAR_MIN, BURN_SELF_EXPLODE_PLANAR_MAX)
        local spdmg = { planar = planar }

        for _, v in ipairs(ents) do
            if v ~= inst and v:IsValid() and not v:IsInLimbo()
                and v.components.combat ~= nil and v.components.combat:CanBeAttacked()
                and not (v.components.health ~= nil and v.components.health:IsDead())
                and inst.components.combat:CanTarget(v)
            then
                v.components.combat:GetAttacked(inst, physical, nil, nil, spdmg)
                if attacker ~= nil and attacker:IsValid() and v.components.combat ~= nil
                    and not (v.components.health ~= nil and v.components.health:IsDead()) then
                    v.components.combat:SuggestTarget(attacker)
                end
            end
        end

        WillowReduceBurningSelfDuration(inst, BURN_SELF_EXPLODE_DURATION_PENALTY)
    end

    WillowOnAttackedWhileBurning = function(inst, data)
        if inst._willow_fire_thorns_task == nil then
            return
        end

        local attacker = data ~= nil and data.attacker or nil
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnWillowSelfBurnGroundPuff(x, y, z)

        if attacker ~= nil and attacker:IsValid()
            and attacker.components.combat ~= nil and attacker.components.combat:CanBeAttacked()
            and not (attacker.components.health ~= nil and attacker.components.health:IsDead())
        then
            attacker.components.combat:GetAttacked(inst, math.random(BURN_SELF_COUNTER_MIN, BURN_SELF_COUNTER_MAX))
        end

        inst._willow_burn_hit_count = (inst._willow_burn_hit_count or 0) + 1
        if inst._willow_burn_hit_count >= BURN_SELF_EXPLODE_HITS then
            inst._willow_burn_hit_count = 0
            DoWillowSelfBurnExplosion(inst, attacker)
        end
    end

    local function ConfigureWillowSelfFireFx(fx)
        if fx == nil then
            return
        end
        fx.Transform:SetScale(WILLOW_SELF_FIRE_SCALE, WILLOW_SELF_FIRE_SCALE, WILLOW_SELF_FIRE_SCALE)
        if fx.AnimState ~= nil then
            fx.AnimState:SetBuild("bernie_fire_fx")
            fx.AnimState:SetMultColour(
                WILLOW_SELF_FIRE_MULT_COLOUR[1],
                WILLOW_SELF_FIRE_MULT_COLOUR[2],
                WILLOW_SELF_FIRE_MULT_COLOUR[3],
                WILLOW_SELF_FIRE_MULT_COLOUR[4]
            )
        end
        if fx.Light ~= nil then
            fx.Light:SetRadius(WILLOW_SELF_FIRE_LIGHT_RADIUS)
            fx.Light:SetIntensity(0.55)
            fx.Light:SetColour(
                WILLOW_SELF_FIRE_LIGHT_COLOUR[1],
                WILLOW_SELF_FIRE_LIGHT_COLOUR[2],
                WILLOW_SELF_FIRE_LIGHT_COLOUR[3]
            )
        end
    end

    local function ConfigureWillowSelfFrenzyFx(fx)
        if fx == nil then
            return
        end
        fx.Transform:SetScale(WILLOW_SELF_FRENZY_SCALE, WILLOW_SELF_FRENZY_SCALE, WILLOW_SELF_FRENZY_SCALE)
        fx:AddTag("willow_self_burn_fx")
    end

    local function WillowApplyBurningSelf(inst)
        if inst._willow_fire_thorns_task ~= nil then
            inst._willow_fire_thorns_task:Cancel()
            inst._willow_fire_thorns_task = nil
        else
            inst._willow_fire_fx = SpawnPrefab("bernie_big_fire")
            if inst._willow_fire_fx ~= nil then
                inst._willow_fire_fx.entity:SetParent(inst.entity)
                inst._willow_fire_fx.AnimState:SetFinalOffset(-3)
                ConfigureWillowSelfFireFx(inst._willow_fire_fx)
            end

            inst._willow_frenzy_fx = SpawnPrefab("willow_frenzy")
            if inst._willow_frenzy_fx ~= nil then
                inst._willow_frenzy_fx.entity:SetParent(inst.entity)
                ConfigureWillowSelfFrenzyFx(inst._willow_frenzy_fx)
            end

            inst._willow_burn_hit_count = 0
            inst:ListenForEvent("attacked", WillowOnAttackedWhileBurning)
        end

        inst._willow_burn_end_time = GetTime() + BURNING_SELF_DURATION
        inst._willow_fire_thorns_task = inst:DoTaskInTime(BURNING_SELF_DURATION, WillowEndBurningSelf)
    end

    local WILLOW_BURN_SELF = Action({ mount_valid = true })
    WILLOW_BURN_SELF.id = "WILLOW_BURN_SELF"
    WILLOW_BURN_SELF.str = "烈焰加身"
    WILLOW_BURN_SELF.fn = function(act)
        local doer = act.doer
        if doer == nil or doer.prefab ~= "willow" or not HasLunarBernieSkill(doer) then
            return false
        end
        if doer.components.health ~= nil and doer.components.health:IsDead() then
            return false
        end
        if CountEmbers(doer) < BURN_SELF_EMBER_COST then
            SayNotEnoughEmbers(doer)
            return false
        end
        ConsumeEmbersFromInventory(doer, BURN_SELF_EMBER_COST)
        WillowApplyBurningSelf(doer)
        return true
    end
    AddAction(WILLOW_BURN_SELF)
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WILLOW_BURN_SELF, "castspellmind"))
    AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WILLOW_BURN_SELF, "castspellmind"))

    AddPrefabPostInit("willow_frenzy", function(inst)
        local old_init = inst.FrenzyDoOnClientInit
        if old_init == nil then
            return
        end
        inst.FrenzyDoOnClientInit = function(self)
            old_init(self)
            if self:HasTag("willow_self_burn_fx") and self.fx ~= nil and self.fx.AnimState ~= nil then
                self.fx.AnimState:SetMultColour(
                    WILLOW_SELF_FRENZY_MULT_COLOUR[1],
                    WILLOW_SELF_FRENZY_MULT_COLOUR[2],
                    WILLOW_SELF_FRENZY_MULT_COLOUR[3],
                    WILLOW_SELF_FRENZY_MULT_COLOUR[4]
                )
            end
        end
    end)

    local function ServerWillowBurnSelf(inst)
        if inst == nil or not inst:IsValid() or inst.prefab ~= "willow" then
            return
        end
        if not HasLunarBernieSkill(inst) then
            return
        end
        if inst.components.health ~= nil and inst.components.health:IsDead() then
            return
        end
        if inst.components.locomotor == nil then
            return
        end
        if inst.sg ~= nil and inst.sg:HasStateTag("busy") then
            return
        end
        if CountEmbers(inst) < BURN_SELF_EMBER_COST then
            SayNotEnoughEmbers(inst)
            return
        end

        local act = BufferedAction(inst, inst, ACTIONS.WILLOW_BURN_SELF)
        inst.components.locomotor:PushAction(act, true)
    end

    AddModRPCHandler("my_mod", "willow_burn_self", function(inst)
        if inst ~= nil and inst:IsValid() and inst.prefab == "willow" then
            inst:PushEvent("custom_willow_burn_self")
        end
    end)

    function GLOBAL.NM_WillowHandleShiftR()
        local player = GLOBAL.ThePlayer
        if player == nil or player.prefab ~= "willow" then
            return
        end
        if GLOBAL.TheInput == nil or not GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
            return
        end
        if player:HasTag("playerghost") or not HasLunarBernieSkill(player) then
            return
        end
        if not HasEnoughEmbers(player, BURN_SELF_EMBER_COST) then
            SayNotEnoughEmbers(player)
            return
        end

        local t = GetTime()
        if player._willow_burn_self_rpc_sent ~= nil and t - player._willow_burn_self_rpc_sent < BURN_SELF_RPC_DEBOUNCE then
            return
        end
        player._willow_burn_self_rpc_sent = t
        SendModRPCToServer(MOD_RPC["my_mod"]["willow_burn_self"])
    end

    if TheInput ~= nil then
        TheInput:AddKeyDownHandler(KEY_R, function()
            if GLOBAL.NM_WillowHandleShiftR ~= nil then
                GLOBAL.NM_WillowHandleShiftR()
            end
        end)
    end

    AddPrefabPostInit("willow", function(inst)
        if not TheWorld.ismastersim then return inst end
    
        local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
            if target.components.burnable and target.components.burnable:IsBurning() and inst:HasTag("firefrenzy") then
                return 1.4 
            elseif inst:HasTag("firefrenzy") then
                return 1.4 
            end
        end
        inst.components.combat.customdamagemultfn = CustomCombatDamage

        inst:ListenForEvent("custom_willow_burn_self", ServerWillowBurnSelf)
        inst:ListenForEvent("ondeactivateskill_server", function(_, data)
            if data ~= nil and data.skill == LUNAR_BERNIE_SKILL then
                WillowEndBurningSelf(inst)
            end
        end)
        inst:ListenForEvent("ms_becameghost", WillowEndBurningSelf)
        inst:ListenForEvent("death", WillowEndBurningSelf)
    end)

    AddClassPostConstruct("components/weapon", function(self)
        local old_OnAttack = self.OnAttack
        function self:OnAttack(attacker, target, projectile)
            if attacker:HasTag("firefrenzy") then
                if target ~= nil and target:IsValid() and target.components.burnable ~= nil then
                    target.components.burnable:Ignite(nil, target, attacker)
                end
                if old_OnAttack ~= nil then
                    old_OnAttack(self, attacker, target, projectile)
                end
            else
                if old_OnAttack ~= nil then
                    old_OnAttack(self, attacker, target, projectile)
                end
            end
        end
    end)


AddComponentPostInit("inventoryitem", function(self)
	local _OnPutInInventory = self.OnPutInInventory
	function self:OnPutInInventory(owner, ...)
		if self.inst ~= nil and self.inst.prefab == "willow_ember"
			and owner ~= nil and owner:IsValid()
			and owner.components.skilltreeupdater == nil then
			self.isnew = false
			self.inst.persists = true
			self.inst._owner = owner
			if self.inst._removetask ~= nil then
				self.inst._removetask:Cancel()
				self.inst._removetask = nil
			end
			if self.inst.components.spellbook ~= nil then
				self.inst.components.spellbook:SetItems({})
			end
			return
		end
		return _OnPutInInventory(self, owner, ...)
	end
end)

AddPrefabPostInit("willow_ember", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	RogeSetWillowEmberMaxStack(inst)
	if inst._onskillrefresh_server ~= nil then
		local _onskillrefresh_server = inst._onskillrefresh_server
		inst._onskillrefresh_server = function()
			local owner = inst._owner
			if owner == nil and inst.components.inventoryitem ~= nil then
				owner = inst.components.inventoryitem.owner
			end
			if owner ~= nil and owner:IsValid() and owner.components.skilltreeupdater == nil then
				return
			end
			_onskillrefresh_server(owner)
		end
	end
end)
