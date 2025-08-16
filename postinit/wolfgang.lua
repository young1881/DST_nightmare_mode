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
TUNING.MIGHTINESS_DRAIN_MULT_SLOW = 0 --保持高饥饿时不掉肌肉值
TUNING.MIGHTINESS_DRAIN_MULT_NORMAL = 0
TUNING.DUMBBELL_DAMAGE_BLUEGEM = 68.5 --蓝宝石哑铃的伤害倍率

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
AddRecipe2("dumbbell_bluegem", { Ingredient("dumbbell_redgem", 1), Ingredient("bluegem", 1), Ingredient("thulecite", 2) },
    TECH.NONE,
    { builder_skill = "wolfgang_dumbbell_crafting" }, { "CHARACTER" })

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
        print("inst.components.combat.damagemultiplier: ", inst.components.combat.externaldamagemultipliers)
    end)


    inst:DoPeriodicTask(1, function()    --理智＜20%显著提高失去理智速度
        if not inst:HasTag("playerghost") and inst.components.sanity and inst.components.sanity:GetPercent() < 0.2 and inst.components.areaaware and not inst.components.areaaware:CurrentlyInTag("lunacyarea") then
            if not inst.yongqi_gang then --勇气哨BUFF会阻止这个额外光环
                inst.components.sanity:DoDelta(-0.75, true)
            end
        end
        if inst.components.sanity:GetRealPercent() == 0 then
            inst.components.mightiness:DoDelta(-1.5)
        end
    end)


    inst:ListenForEvent("oneat", oneatpotato) --吃土豆回20San
    inst:ListenForEvent("attacked", fat_gang) --监控肌肉
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
            --队友及自己回San
            for k, v in pairs(TheSim:FindEntities(x, y, z, 20, { "player" })) do
                if v.components.sanity then
                    v.components.sanity:DoDelta(20)
                    SpawnPrefab("emote_fx").entity:SetParent(v.entity) --激励特效
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
