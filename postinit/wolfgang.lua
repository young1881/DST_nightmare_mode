--UpvalueHacker前置
local UpvalueHacker = {}

local function GetUpvalueHelper(fn, name)
    local i = 1
    while debug.getupvalue(fn, i) and debug.getupvalue(fn, i) ~= name do
        i = i + 1
    end
    local name, value = debug.getupvalue(fn, i)
    return value, i
end

function UpvalueHacker.GetUpvalue(fn, ...)
    local prv, i, prv_var = nil, nil, "(the starting point)"
    for j, var in ipairs({ ... }) do
        assert(type(fn) == "function", "We were looking for " .. var .. ", but the value before it, "
            .. prv_var .. ", wasn't a function (it was a " .. type(fn)
            .. "). Here's the full chain: " .. table.concat({ "(the starting point)", ... }, ", "))
        prv = fn
        prv_var = var
        fn, i = GetUpvalueHelper(fn, var)
    end
    return fn, i, prv
end

function UpvalueHacker.SetUpvalue(start_fn, new_fn, ...)
    local _fn, _fn_i, scope_fn = UpvalueHacker.GetUpvalue(start_fn, ...)
    debug.setupvalue(scope_fn, _fn_i, new_fn)
end

--三维重调
TUNING.WOLFGANG_SANITY = 150
TUNING.WOLFGANG_HUNGER = 300
TUNING.WOLFGANG_HEALTH_NORMAL = 200
TUNING.WOLFGANG_HEALTH = 200
TUNING.MIGHTINESS_DRAIN_MULT_SLOW = 0     --保持高饥饿时不掉肌肉值
TUNING.MIGHTINESS_DRAIN_MULT_NORMAL = 0

local ZERO_SANITY_MIGHTINESS_DRAIN = -0.5 --理智为0时每秒掉的肌肉值

--开局6个土豆
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")
table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WOLFGANG, "potato")

--口哨配方改动
AllRecipes.wolfgang_whistle.ingredients = { Ingredient("nightmare_timepiece", 1), Ingredient("potato", 1) }

--冰哑铃
AddRecipe2("dumbbell_bluegem",
    { Ingredient("dumbbell_redgem", 1), Ingredient("bluegem", 1), Ingredient("orangeamulet", 1) },
    TECH.NONE,
    { builder_skill = "wolfgang_dumbbell_crafting" }, { "CHARACTER" })

AddPrefabPostInit("dumbbell_bluegem", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.finiteuses:SetMaxUses(TUNING.DUMBBELL_HEAT_MAX_USES)
    inst.components.finiteuses:SetUses(TUNING.DUMBBELL_HEAT_MAX_USES)
end)


AddSimPostInit(function()
    STRINGS.NAMES.WOLFGANG_WHISTLE = "勇气口哨"
    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.WOLFGANG_WHISTLE = "能让沃尔夫冈变得勇敢！"
    STRINGS.RECIPE_DESC.WOLFGANG_WHISTLE = "土豆精不会害怕！"
end)

--体型变化
local function fat_gang(inst, data)
    local mig = 0
    if inst.components.mightiness and inst.components.mightiness.current > 100 then --记录突破了多少肌肉值
        mig = inst.components.mightiness.current - 100
    end
    if not inst:HasTag("GangYi") then --刚毅效果标签
        inst:DoTaskInTime(0, function()
            inst:AddTag("GangYi")
            inst.components.health:SetAbsorptionAmount(0.2 + (mig * 0.005)) --肌肉值150时最高45%减伤
        end)
        inst:DoTaskInTime(0.75 + (mig * 0.025), function()                  --肌肉值150时最高2秒霸体
            inst:RemoveTag("GangYi")
            inst.components.health:SetAbsorptionAmount(0)
        end)
    end

    if inst.components.mightiness then
        if inst.components.mightiness.current >= 75 then
            if not inst:HasTag("heavybody") then
                inst:AddTag("heavybody")
                inst:AddTag("stronggrip")
            end
        else
            if inst:HasTag("heavybody") and not inst:HasTag("GarlicHit") and not inst:HasTag("dungeyx") then
                inst:RemoveTag("heavybody")
                inst:RemoveTag("stronggrip")
            end
        end
    end
end

local function oneatpotato(inst, data)
    local food = data.food
    if food and food.components.edible then
        if food.prefab == "potato_cooked" then
            inst.components.sanity:DoDelta(20)
        end
    end
end

local function mightiness_change(inst)
    if inst:HasTag("mightiness_mighty") and not inst:HasTag("stronggrip") then
        inst:AddTag("stronggrip")
    else
        if inst:HasTag("stronggrip") then
            inst:RemoveTag("stronggrip")
        end
    end
end



--刚毅霸体
AddStategraphPostInit("wilson", function(sg)
    local old_onattacked = sg.events['attacked'].fn
    sg.events['attacked'] = EventHandler('attacked', function(inst, data, ...)
        if inst.prefab == "wolfgang" and inst.components.mightiness:GetState() == "mighty" and inst:HasTag("GangYi") then --大力士刚毅效果
            if not inst.sg:HasStateTag('frozen') and not inst.sg:HasStateTag('sleeping') then
                inst.SoundEmitter:PlaySound("dontstarve/characters/wolfgang/hurt")
                return
            end
        end
        return old_onattacked(inst, data, ...)
    end)
end)


local DAY_TO_MAX_MULTIPLIER = 20 -- 达到最大倍率的天数（第20天）
local MAX_BONUS_MULTIPLIER = 2 -- 额外增加的倍率（从2倍增加到4倍，即额外2倍）
local DEATH_PENALTY_TIME = 480 -- 1天的时间（现实时间8分钟 = 480秒）
local MAX_DEATH_COUNT = 2 -- 触发重置的最大死亡次数
local NO_HEAL_BONUS_TIME = 60 -- 不回复生命值获得加成的默认时间（秒）
local NO_HEAL_DAMAGE_BONUS = 0.2 -- 不回复生命值时的额外伤害加成倍率
local NO_HEAL_DAMAGE_REDUCTION = 0.2 -- 不回复生命值时的伤害减免倍率（受击伤害减少比例）

-- 新增：标记是否已说过不回血加成的台词（避免重复触发，按玩家实例存储）

local function CalculateDayBonusMultiplier(inst)
    local effective_days = inst._effective_survival_days or 0
    if effective_days <= 0 then
        return 0
    end
    
    local progress = math.min(effective_days / DAY_TO_MAX_MULTIPLIER, 1.0)
    return progress * MAX_BONUS_MULTIPLIER
end

local function UpdateEffectiveSurvivalDays(inst)
    if not inst.components.age then
        return
    end
    
    local current_days = inst.components.age:GetAgeInDays()
    local reset_day = inst._growth_reset_day or 0
    
    inst._effective_survival_days = math.max(0, current_days - reset_day)
end

local function UpdateMightyDamageMultiplier(inst)
    if not inst.components.mightiness or inst.components.mightiness:GetState() ~= "mighty" then
        return
    end
    
    local base_multiplier = 2
    local day_bonus = CalculateDayBonusMultiplier(inst)
    local no_heal_damage_bonus = inst._no_heal_damage_bonus or NO_HEAL_DAMAGE_BONUS
    local no_heal_bonus = (inst._no_heal_bonus_active and no_heal_damage_bonus) or 0
    
    -- 总倍率 = 基础2倍 + 天数加成 + 不回复生命加成
    local total_multiplier = base_multiplier + day_bonus + no_heal_bonus
    
    -- 覆盖原版伤害倍率
    inst.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    inst.components.combat.externaldamagemultipliers:SetModifier(inst, total_multiplier)
end

--检查是否应该重置成长（死亡或换人）
local function ShouldResetGrowth(inst)
    if inst._death_times and #inst._death_times >= MAX_DEATH_COUNT then
        local recent_deaths = 0
        local current_time = GetTime()
        for _, death_time in ipairs(inst._death_times) do
            if current_time - death_time < DEATH_PENALTY_TIME then
                recent_deaths = recent_deaths + 1
            end
        end
        if recent_deaths >= MAX_DEATH_COUNT then
            return true
        end
    end
    return false
end

--清理死亡记录
local function CleanDeathRecords(inst)
    if not inst._death_times then
        return
    end
    
    local current_time = GetTime()
    local valid_times = {}
    for _, death_time in ipairs(inst._death_times) do
        if current_time - death_time < DEATH_PENALTY_TIME then
            table.insert(valid_times, death_time)
        end
    end
    inst._death_times = valid_times
end

--重置成长
local function ResetGrowth(inst)
    if inst.components.age then
        inst._growth_reset_day = inst.components.age:GetAgeInDays()
    else
        inst._growth_reset_day = 0
    end
    inst._effective_survival_days = 0
    UpdateMightyDamageMultiplier(inst)
end

--死亡处理
local function OnDeath(inst, data)
    if not inst._death_times then
        inst._death_times = {}
    end
    table.insert(inst._death_times, GetTime())
    CleanDeathRecords(inst)
    
    if ShouldResetGrowth(inst) then
        ResetGrowth(inst)
    end
    -- 死亡时重置台词标记
    inst._roge_no_heal_bonus_said = false
end

--角色切换处理
local function OnCharacterSwap(inst)
    inst._last_character_swap_time = GetTime()
    inst._death_times = {}
    if inst.prefab == "wolfgang" then
        ResetGrowth(inst)
    end
    -- 切换角色时重置台词标记
    inst._roge_no_heal_bonus_said = false
end

--初始化或重置成长相关变量
local function InitOrResetGrowth(inst)
    if inst.components.age then
        inst._growth_reset_day = inst.components.age:GetAgeInDays()
        inst._effective_survival_days = 0
    else
        inst._growth_reset_day = 0
        inst._effective_survival_days = 0
    end
end

--检查不回复生命值加成（核心修改：添加台词触发）
local function UpdateNoHealBonus(inst)
    if not inst.components.health or inst:HasTag("playerghost") then
        return
    end
    
    local current_time = GetTime()
    local last_heal_time = inst._last_heal_time or 0
    local no_heal_duration = inst._no_heal_bonus_duration or NO_HEAL_BONUS_TIME
    local time_since_heal = current_time - last_heal_time
    
    local should_have_bonus = time_since_heal >= no_heal_duration
    
    -- 当首次激活不回血加成时，触发台词
    if should_have_bonus and not inst._no_heal_bonus_active then
        inst._no_heal_bonus_active = true
        -- 添加伤害减免
        local no_heal_damage_reduction = inst._no_heal_damage_reduction or NO_HEAL_DAMAGE_REDUCTION
        local damage_reduction_mult = 1.0 - no_heal_damage_reduction
        inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, damage_reduction_mult, "wolfgang_no_heal_bonus")
        UpdateMightyDamageMultiplier(inst)

        if not inst._roge_no_heal_bonus_said and inst.components.talker then
            -- 可选多句随机台词，也可只保留一句
            local bonus_lines = {
                "浴血奋战，愈战愈勇！",
                "无惧疼痛，重振精神！",
                "跟紧我，是时候展示真正的力量了！",
                "如果连周围人都保护不了，那还怎么拯救土豆！"
            }
            inst.components.talker:Say(bonus_lines[math.random(#bonus_lines)])
            -- 标记已说过台词，避免重复触发
            inst._roge_no_heal_bonus_said = true
        end
        
    elseif not should_have_bonus and inst._no_heal_bonus_active then
        inst._no_heal_bonus_active = false
        -- 移除伤害减免
        inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "wolfgang_no_heal_bonus")
        UpdateMightyDamageMultiplier(inst)
        
        -- 新增：失去加成时重置台词标记（下次激活可再次触发）
        inst._roge_no_heal_bonus_said = false
    end
end

--生命值变化处理
local function OnHealthDelta(inst, data)
    if data and data.newpercent and data.oldpercent then
        if data.newpercent > data.oldpercent then
            inst._last_heal_time = GetTime()
            UpdateNoHealBonus(inst)
            -- 回血时重置台词标记
            inst._roge_no_heal_bonus_said = false
        end
    end
end

--刚子！
AddPrefabPostInit("wolfgang", function(inst)
    inst:AddTag("wolfgang_overbuff_1")
    inst:AddTag("wolfgang_overbuff_2")
    inst:AddTag("wolfgang_overbuff_3")
    inst:AddTag("wolfgang_overbuff_4")
    inst:AddTag("wolfgang_overbuff_5")

    if not TheWorld.ismastersim then
        return inst
    end
    inst.Gangweile = true
    inst.yongqi_gang = false
    
    -- 初始化变量
    inst._death_times = {}
    inst._last_heal_time = GetTime()
    inst._no_heal_bonus_active = false
    inst._no_heal_bonus_duration = NO_HEAL_BONUS_TIME -- 可自定义的时间
    inst._no_heal_damage_bonus = NO_HEAL_DAMAGE_BONUS -- 可自定义的伤害加成倍率
    inst._no_heal_damage_reduction = NO_HEAL_DAMAGE_REDUCTION -- 可自定义的伤害减免倍率
    
    -- 初始化成长相关变量
    -- 如果_growth_reset_day已经存在，说明之前是wolfgang，不需要重置
    -- 如果不存在，说明是第一次成为wolfgang或从其他角色切换过来，需要初始化
    if inst._growth_reset_day == nil then
        InitOrResetGrowth(inst)
    end

    inst:DoTaskInTime(0, function()
        inst.components.mightiness:SetOverMax(50)
    end)


    -- local function CustomSanityFn1(inst, dt) --理智越低扣理智光环越大
    --     local health_drain = (1 - inst.components.sanity:GetPercentWithPenalty()) * 0.1

    --     if not inst.yongqi_gang then --勇气哨BUFF会阻止这个额外光环
    --         return -health_drain
    --     else
    --         return 0
    --     end
    -- end

    -- inst.components.sanity.custom_rate_fn = CustomSanityFn1


    inst:DoPeriodicTask(6.4, function() --额外饥饿
        if not inst:HasTag("playerghost") and inst.components.hunger and inst.components.mightiness and inst.components.mightiness.current >= 75 then
            inst.components.hunger:DoDelta(-0.5, true)
            --健身突破后，多出来的肌肉值会造成额外消耗
            if inst.components.mightiness.current > 100 then
                inst.components.hunger:DoDelta(-((inst.components.mightiness.current - 100) * 0.01), true)
            end
        end
    end)


    inst:DoPeriodicTask(1, function()    --理智＜30%显著提高失去理智速度
        if not inst:HasTag("playerghost") and inst.components.sanity and inst.components.sanity:GetPercent() < 0.3 and inst.components.areaaware and not inst.components.areaaware:CurrentlyInTag("lunacyarea") then
            if not inst.yongqi_gang then --勇气哨BUFF会阻止这个额外光环
                inst.components.sanity:DoDelta(-0.75, true)
            end
        end
        if inst.components.sanity:GetRealPercent() == 0 then
            inst.components.mightiness:DoDelta(ZERO_SANITY_MIGHTINESS_DRAIN)
        end
        
        -- 更新不回复生命值加成
        UpdateNoHealBonus(inst)
    end)
    
    -- 定期更新伤害倍率（处理天数增长）
    inst:DoPeriodicTask(10, function()
        if inst.components.mightiness and inst.components.mightiness:GetState() == "mighty" then
            -- 更新有效生存天数
            UpdateEffectiveSurvivalDays(inst)
            UpdateMightyDamageMultiplier(inst)
        end
    end)

    -- 监听角色切换事件，在切换时重置成长
    -- 这个事件在角色切换时触发，无论是切换到wolfgang还是从wolfgang切换到其他角色
    inst:ListenForEvent("ms_playerseamlessswaped", function(inst)
        -- 切换后检查：如果当前是wolfgang，重置成长
        inst:DoTaskInTime(0, function()
            if inst.prefab == "wolfgang" then
                OnCharacterSwap(inst)
            end
        end)
    end)
    
    -- 监听新角色生成事件，确保第一次成为wolfgang时正确初始化
    inst:ListenForEvent("ms_newcharacterspawned", function(inst)
        if inst.prefab == "wolfgang" and inst._growth_reset_day == nil then
            InitOrResetGrowth(inst)
        end
    end)
    
    inst:ListenForEvent("oneat", oneatpotato) --吃土豆回20San
    inst:ListenForEvent("attacked", fat_gang) --监控肌肉
    inst:ListenForEvent("death", OnDeath) --监控死亡
    inst:ListenForEvent("healthdelta", OnHealthDelta) --监控生命值变化
    inst:ListenForEvent("mightiness_statechange", function(inst, data)
        -- 使用DoTaskInTime确保mightiness组件的BecomeState已经完成
        inst:DoTaskInTime(0, function()
            if inst.components.mightiness and inst.components.mightiness:GetState() == "mighty" then
                UpdateMightyDamageMultiplier(inst)
            else
                -- 非强壮状态时移除不回复生命值加成
                inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "wolfgang_no_heal_bonus")
                inst._no_heal_bonus_active = false
            end
        end)
    end) --监控状态变化
    -- inst:ListenForEvent("mightiness_statechange", mightiness_change) --强壮状态不被缴械
end)


--强大健身房重做
AddStategraphPostInit("wilson", function(sg)
    sg.states["mighty_gym_success_perfect"].onenter = function(inst, data)
        local gym = inst.components.strongman.gym
        local old = inst.components.mightiness:GetState()
        local oldpercent = inst.components.mightiness:GetPercent()

        if inst.components.hunger:GetPercent() > 0 then --不能是饿着的
            if inst.components.mightiness.current < 100 then
                inst.components.mightiness:DoDelta(gym.components.mightygym:CalculateMightiness(true), true, nil, true,
                    true)
            else
                if gym.components.mightygym:CalculateMightiness(true) >= 9 or inst.components.mightiness.current < 125 then
                    inst.components.mightiness:DoDelta(gym.components.mightygym:CalculateMightiness(true) / 5, true, nil,
                        true, true)
                end
                if inst.components.mightiness.current < 150 then
                    inst.components.hunger:DoDelta(-3, true)
                end
            end
            inst.components.sanity:DoDelta((gym.components.mightygym:CalculateMightiness(true)) / 2)
        end

        local newpercent = inst.components.mightiness:GetPercent()

        local change = ""
        if newpercent >= 1 then
            if newpercent == oldpercent then
                change = "_full"
            else
                change = "_full_pre"
            end
        end
        if inst.components.mightiness:GetState() ~= old then
            change = "_change"
        end
        inst.AnimState:PlayAnimation("lift_pre")
        inst.AnimState:PushAnimation("mighty_gym_success_big" .. change, false)

        inst.SoundEmitter:PlaySound("wolfgang2/common/gym/success")

        inst:PerformBufferedAction()
    end
    sg.states["mighty_gym_success_perfect"].events["animqueueover"].fn = function(inst)
        if inst.components.mightiness:GetPercent() == 1 then
            inst.sg.statemem.dontleavegym = true
            inst.sg:GoToState("mighty_gym_workout_loop")
        else
            inst.sg.statemem.dontleavegym = true
            inst.sg:GoToState("mighty_gym_workout_loop")
        end
    end
    sg.states["mighty_gym_success"].onenter = function(inst, data)
        local gym = inst.components.strongman.gym
        local old = inst.components.mightiness:GetState()
        local oldpercent = inst.components.mightiness:GetPercent()

        if inst.components.hunger:GetPercent() > 0 then --不能是饿着的
            if inst.components.mightiness.current < 100 then
                inst.components.mightiness:DoDelta(gym.components.mightygym:CalculateMightiness(false), true, nil, true,
                    true)
            else
                if inst.components.mightiness.current < 125 then
                    inst.components.mightiness:DoDelta(gym.components.mightygym:CalculateMightiness(false) / 5, true, nil,
                        true, true)
                end
                if inst.components.mightiness.current < 150 then
                    inst.components.hunger:DoDelta(-3, true)
                end
            end
            inst.components.sanity:DoDelta((gym.components.mightygym:CalculateMightiness(false)) / 2)
        end

        local newpercent = inst.components.mightiness:GetPercent()

        local change = ""
        if newpercent >= 1 then
            if newpercent == oldpercent then
                change = "_full"
            else
                change = "_full_pre"
            end
        end
        if inst.components.mightiness:GetState() ~= old then
            change = "_change"
        end
        inst.AnimState:PlayAnimation("lift_pre")
        inst.AnimState:PushAnimation("mighty_gym_success_normal" .. change, false)

        inst.SoundEmitter:PlaySound("wolfgang2/common/gym/success")

        inst:PerformBufferedAction()
    end
    sg.states["mighty_gym_success"].events["animqueueover"].fn = function(inst)
        if inst.components.mightiness:GetPercent() == 1 then
            inst.sg.statemem.dontleavegym = true
            inst.sg:GoToState("mighty_gym_workout_loop")
        else
            inst.sg.statemem.dontleavegym = true
            inst.sg:GoToState("mighty_gym_workout_loop")
        end
    end
end)


--变身硬直免疫
local specialstates = {
    "powerup",
    "powerdown"
}
AddStategraphPostInit(
    "wilson",
    function(sg)
        for i, specialstate in ipairs(specialstates) do
            local oldOnEnter = sg.states[specialstate].onenter
            sg.states[specialstate].onenter = function(inst)
                if inst.prefab == "wolfgang" then
                    inst.ismighty = inst:HasTag("ingym") or inst.sg.mem.lifting_dumbbell
                end
                oldOnEnter(inst)
                if not inst.ismighty then
                    inst.sg:SetTimeout(10 * FRAMES)
                end
            end
            sg.states[specialstate].ontimeout = function(inst)
                if
                    inst.sg.currentstate.name == specialstate and sg.states[specialstate].timeline and
                    sg.states[specialstate].timeline[1]
                then
                    sg.states[specialstate].timeline[1].fn(inst)
                    inst.ismighty = nil
                    inst.sg:GoToState("idle")
                end
            end
        end
    end)


--哨子重做
local function NewOnPlayed(inst, doer)
    local x, y, z = doer.Transform:GetWorldPosition()
    if doer.prefab == "wolfgang" then
        --交流土豆作物
        for k, v in pairs(TheSim:FindEntities(x, y, z, 10, { "tendable_farmplant" })) do
            if v.prefab == "farm_plant_potato" and v.components.farmplanttendable then
                v.components.farmplanttendable:TendTo(doer)
            end
        end
        if inst.CN and doer.yongqi_gang == false then
            inst.components.rechargeable:Discharge(240)
            doer.components.talker:Say("各位，振奋起来！")
            doer.yongqi_gang = true
            doer.components.sanity.neg_aura_mult = 0.25
            doer.components.eater:SetAbsorptionModifiers(1, 1, 0.5)
            doer:DoTaskInTime(90, function()
                doer.yongqi_gang = false
                if doer.components.sanity then
                    doer.components.sanity.neg_aura_mult = 1
                end

                if doer.components.eater ~= nil then
                    doer.components.eater:SetAbsorptionModifiers(1, 1, 1)
                end
            end)
            --队友及自己回San；每恢复一名玩家，沃尔夫冈额外获得 15 点理智
            for k, v in pairs(TheSim:FindEntities(x, y, z, 20, { "player" })) do
                if v.components.sanity then
                    v.components.sanity:DoDelta(20)
                    SpawnPrefab("emote_fx").entity:SetParent(v.entity) --激励特效
                    if doer.components.sanity then
                        doer.components.sanity:DoDelta(15, nil, "wolfgang_whistle")
                    end
                end
            end
        end
    else
        --交流土豆作物
        for k, v in pairs(TheSim:FindEntities(x, y, z, 10, { "tendable_farmplant" })) do
            if v.prefab == "farm_plant_potato" and v.components.farmplanttendable then
                v.components.farmplanttendable:TendTo(doer)
            end
        end
    end
end
AddPrefabPostInit("wolfgang_whistle", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:RemoveTag("coach_whistle")
    inst.components.instrument:SetOnPlayedFn(NewOnPlayed)

    inst.CN = true
    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst)
        inst.CN = false
    end)
    inst.components.rechargeable:SetOnChargedFn(function(inst)
        inst.CN = true
    end)
end)

