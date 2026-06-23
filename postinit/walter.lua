-- Author: lumos

local STRINGS = GLOBAL.STRINGS
local UPGRADETYPES = GLOBAL.UPGRADETYPES
local GetString = GLOBAL.GetString

GLOBAL.setmetatable(
    env,
    {
        __index = function(t, k)
            return GLOBAL.rawget(GLOBAL, k)
        end
    }
)

-- 重调三维
TUNING.WALTER_HUNGER = 113 -- 原版110
TUNING.WALTER_HEALTH = 113 -- 原版130
TUNING.WALTER_SANITY = 113 -- 原版200

-- 受到伤害时的san惩罚倍率
TUNING.WALTER_SANITY_DAMAGE_RATE = 2.5
-- 持续性伤害（冻伤、酸雨）的惩罚倍率
TUNING.WALTER_SANITY_DAMAGE_OVERTIME_RATE = 2
-- 低血的san惩罚
TUNING.WALTER_SANITY_HEALTH_DRAIN = 2.5

-- 大沃比的移速
TUNING.WOBY_BIG_SPEED.FAST = 13
TUNING.WOBY_BIG_SPEED.MEDIUM = 12
TUNING.WOBY_BIG_SPEED.SLOW = 10
-- 挨打了过后多少秒能重新上沃比单位秒 原版5
TUNING.WALTER_WOBYBUCK_DECAY_TIME = 2
-- 受到多大的攻击会被摔下来
TUNING.WALTER_WOBYBUCK_DAMAGE_MAX = 30

-- 帐篷便宜一点
Recipe2("portabletent_item",
    { Ingredient("bedroll_straw", 1), Ingredient("twigs", 10) },
    TECH.SCIENCE_ONE,
    { builder_tag = "pinetreepioneer" })

-- 加强讲故事的回san
-- SANITYAURA_TINY = 100/(seg_time*32),       -- 50    per day.
-- SANITYAURA_SMALL_TINY = 100/(seg_time*20), -- 80    per day.
-- SANITYAURA_SMALL = 100/(seg_time*8),       -- 200   per day.
-- SANITYAURA_MED = 100/(seg_time*5),         -- 320   per day.
-- SANITYAURA_LARGE = 100/(seg_time*2),       -- 800   per day.
-- SANITYAURA_HUGE = 100/(seg_time*.5),       -- 3,200 per day.
-- SANITYAURA_SUPERHUGE = 100/(seg_time*.25), -- 6,400 per day.
AddPrefabPostInit("walter_campfire_story_proxy", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.sanityaura.aura = TUNING.SANITYAURA_HUGE
end)


------------  位面弹弓  ----------

local function slingshot(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if not inst.components.equippable then
        inst:AddComponent("equippable")
    end

    -- 限制只有尼个能佩戴
    inst.components.equippable.restrictedtag = "storyteller"

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(10)
end

AddPrefabPostInit("slingshot", slingshot)


----------  位面帽子  ----------

local function walterhat(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if not inst.components.equippable then
        inst:AddComponent("equippable")
    end

    -- 限制只有尼个能佩戴
    inst.components.equippable.restrictedtag = "storyteller"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(525, 0.8)

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(5)
end

AddPrefabPostInit("walterhat", walterhat)

----------  取消弹弓前摇  ----------
--神射手哪需要瞄准
AddStategraphPostInit("wilson", function(sg)
    sg.states["slingshot_shoot"].onenter = function(inst)
        if inst.components.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        if target == nil then
            if buffaction ~= nil and inst.components.playercontroller ~= nil and inst.components.playercontroller.isclientcontrollerattached then
                inst.sg.statemem.air_attack = true
            end
        elseif target:IsValid() then
            inst:ForceFacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
            inst.sg.statemem.retarget = target
        end

        -- inst.AnimState:PlayAnimation("slingshot_pre")
        -- inst.AnimState:PushAnimation("slingshot", false)
        inst.AnimState:PlayAnimation("slingshot", false)

        if inst.sg.laststate == inst.sg.currentstate then
            inst.sg.statemem.chained = true
            inst.AnimState:SetFrame(3)
        end

        inst.components.combat:StartAttack()
        inst.components.combat:SetTarget(target)
        inst.components.locomotor:Stop()

        local timeout = inst.sg.statemem.chained and 25 or 28
        local playercontroller = inst.components.playercontroller
        if playercontroller ~= nil and playercontroller.remote_authority and playercontroller.remote_predicting then
            timeout = timeout - 1
        end
        inst.sg:SetTimeout(timeout * FRAMES)
    end

    sg.states["slingshot_shoot"].timeline = {
        TimeEvent(2 * FRAMES, function(inst)
            if inst.sg.statemem.chained and not inst.sg.statemem.air_attack then
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if not (target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target)) then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                end
            end
        end),
        TimeEvent(10 * FRAMES, function(inst)                -- 播放瞄准动画
            inst.AnimState:PlayAnimation("slingshot_pre")    -- 播放瞄准动画
            inst.AnimState:PushAnimation("slingshot", false) -- 播放射击动画
        end),
        TimeEvent(2 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                if inst.sg.statemem.air_attack then
                    inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                else
                    local buffaction = inst:GetBufferedAction()
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                        local target = buffaction ~= nil and buffaction.target or nil
                        if target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target) then
                            inst:PerformBufferedAction()
                            inst.sg:RemoveStateTag("abouttoattack")
                            inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
                        else
                            inst:ClearBufferedAction()
                            inst.sg:GoToState("idle")
                        end
                    else -- out of ammo
                        inst:ClearBufferedAction()
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_SLINGHSOT_OUT_OF_AMMO"))
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                        inst.sg:GoToState("idle")
                    end
                end
            end
        end),
        TimeEvent(2 * FRAMES, function(inst)
            if not inst.sg.statemem.chained and not inst.sg.statemem.air_attack then
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if not (target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target)) then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                end
            end
        end),
        TimeEvent(10 * FRAMES, function(inst)                -- 播放瞄准动画
            inst.AnimState:PlayAnimation("slingshot_pre")    -- 播放瞄准动画
            inst.AnimState:PushAnimation("slingshot", false) -- 播放射击动画
        end),
        TimeEvent(2 * FRAMES, function(inst)
            if not inst.sg.statemem.chained then
                if inst.sg.statemem.air_attack then
                    inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                else
                    local buffaction = inst:GetBufferedAction()
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                        local target = buffaction ~= nil and buffaction.target or nil
                        if target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target) then
                            inst:PerformBufferedAction()
                            inst.sg:RemoveStateTag("abouttoattack")
                            inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
                        else
                            inst:ClearBufferedAction()
                            inst.sg:GoToState("idle")
                        end
                    else -- out of ammo
                        inst:ClearBufferedAction()
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_SLINGHSOT_OUT_OF_AMMO"))
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                        inst.sg:GoToState("idle")
                    end
                end
            end
        end),
    }
end)



-- ----------  子弹加强  ----------

-- 子弹伤害增加
TUNING.SLINGSHOT_AMMO_DAMAGE_ROCKS = 34      -- 17
TUNING.SLINGSHOT_AMMO_DAMAGE_GOLD = 51       -- 34
TUNING.SLINGSHOT_AMMO_DAMAGE_MARBLE = 59.5   -- 51
TUNING.SLINGSHOT_AMMO_DAMAGE_THULECITE = 68  -- 51
TUNING.SLINGSHOT_AMMO_DAMAGE_SLOW = 34       -- 17
TUNING.SLINGSHOT_AMMO_DAMAGE_TRINKET_1 = 250 --弹珠的伤害

-- 子弹射程
TUNING.SLINGSHOT_DISTANCE = 8     -- 10
-- 最远要多远按f可以走过去
TUNING.SLINGSHOT_DISTANCE_MAX = 12 -- 14

--减速弹药（现在的效果和奶奶的蜘蛛书是一样的）
TUNING.SLINGSHOT_AMMO_MOVESPEED_MULT = 2 / 3 -- 2/3
--------------------
--冰冻效果
TUNING.SLINGSHOT_AMMO_FREEZE_COLDNESS = 3 -- 2

-- 诅咒子弹解锁后可永久解锁
-- numtogive就可以修改制作的时候给多少子弹
Recipe2("slingshotammo_rock", { Ingredient("rocks", 1) }, TECH.NONE,
    { builder_tag = "pebblemaker", numtogive = 30, no_deconstruction = true, })
Recipe2("slingshotammo_gold", { Ingredient("goldnugget", 1) }, TECH.SCIENCE_ONE,
    { builder_tag = "pebblemaker", numtogive = 40, no_deconstruction = true, })
Recipe2("slingshotammo_marble", { Ingredient("marble", 1) }, TECH.SCIENCE_ONE,
    { builder_tag = "pebblemaker", numtogive = 50, no_deconstruction = true, })
Recipe2("slingshotammo_poop", { Ingredient("poop", 1) }, TECH.SCIENCE_ONE,
    { builder_tag = "pebblemaker", numtogive = 40, no_deconstruction = true, })
Recipe2("slingshotammo_freeze", { Ingredient("nightmarefuel", 1), Ingredient("bluegem", 1) }, TECH.SCIENCE_TWO,
    { builder_tag = "pebblemaker", numtogive = 25, no_deconstruction = true, })
Recipe2("slingshotammo_slow", { Ingredient("nightmarefuel", 1), Ingredient("purplegem", 1) }, TECH.SCIENCE_TWO,
    { builder_tag = "pebblemaker", numtogive = 30, no_deconstruction = true, })
Recipe2("slingshotammo_thulecite", { Ingredient("thulecite_pieces", 1), Ingredient("nightmarefuel", 1) },
    TECH.ANCIENT_TWO, { builder_tag = "pebblemaker", numtogive = 30, no_deconstruction = true })

-- 弹弓不可燃
AddPrefabPostInit("slingshot", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:RemoveComponent("burnable")
end)


-- -- ----------  新的子弹来了！！！！----------

STRINGS.NAMES.SLINGSHOTAMMO_GLASS = '玻璃弹药'
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SLINGSHOTAMMO_GLASS = '玻璃渣做的军火'
STRINGS.RECIPE_DESC.SLINGSHOTAMMO_GLASS = "好的玻璃弹药不比诅咒弹药差"

STRINGS.NAMES.SLINGSHOTAMMO_LUNARPLANT = '亮茄弹药'
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SLINGSHOTAMMO_LUNARPLANT = '这个弹药能够召唤亮茄的力量！'
STRINGS.RECIPE_DESC.SLINGSHOTAMMO_LUNARPLANT = '这个弹药能够召唤亮茄的力量！'

STRINGS.NAMES.SLINGSHOTAMMO_VOIDCLOTH = '虚空弹药'
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SLINGSHOTAMMO_VOIDCLOTH = '对皮糙肉厚的敌人施以痛击！'
STRINGS.RECIPE_DESC.SLINGSHOTAMMO_VOIDCLOTH = '对皮糙肉厚的敌人施以痛击！'

AddRecipe2("slingshotammo_glass", { Ingredient("moonglass", 1), Ingredient("moon_tree_blossom", 1) },
    TECH.CELESTIAL_THREE,
    {
        builder_tag = "pebblemaker",
        numtogive = 15,
        no_deconstruction = true,
        image = "glass.tex",
        atlas =
        "images/inventoryimages/glass.xml"
    }, { "CHARACTER" })
AddRecipe2("slingshotammo_lunarplant", { Ingredient("purebrilliance", 1), Ingredient("lunarplant_husk", 1) },
    TECH.LUNARFORGING_TWO,
    {
        builder_tag = "pebblemaker",
        numtogive = 10,
        no_deconstruction = true,
        image = "lunarplant.tex",
        atlas =
        "images/inventoryimages/lunarplant.xml"
    }, { "CHARACTER" })
AddRecipe2("slingshotammo_voidcloth", { Ingredient("horrorfuel", 1), Ingredient("voidcloth", 1) },
    TECH.SHADOWFORGING_TWO,
    {
        builder_tag = "pebblemaker",
        numtogive = 10,
        no_deconstruction = true,
        image = "voidcloth.tex",
        atlas =
        "images/inventoryimages/voidcloth.xml"
    }, { "CHARACTER" })

table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WALTER, "portabletent_item") --尼哥开局送帐篷

AddPrefabPostInit("wobybig", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
end)
AddPrefabPostInit("wobysmall", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
end) --沃比吃肉

-- 击杀血量高于 300 的生物：随机掉落 1-3 种弹弓弹药，每种 1-5 发
local WALTER_KILL_AMMO_HP_MIN = 300
local WALTER_KILL_AMMO_TYPES_MIN = 1
local WALTER_KILL_AMMO_TYPES_MAX = 3
local WALTER_KILL_AMMO_COUNT_MIN = 1
local WALTER_KILL_AMMO_COUNT_MAX = 5
local WALTER_KILL_AMMO_BOSS_COUNT_MULT = 2

local WALTER_SLINGSHOT_AMMO_PREFABS = {
    "slingshotammo_rock",
    "slingshotammo_gold",
    "slingshotammo_marble",
    "slingshotammo_thulecite",
    "slingshotammo_honey",
    "slingshotammo_freeze",
    "slingshotammo_slow",
    "slingshotammo_poop",
    "slingshotammo_stinger",
    "slingshotammo_moonglass",
    "slingshotammo_dreadstone",
    "slingshotammo_gunpowder",
    "slingshotammo_lunarplanthusk",
    "slingshotammo_purebrilliance",
    "slingshotammo_horrorfuel",
    "slingshotammo_gelblob",
    "slingshotammo_scrapfeather",
    "slingshotammo_glass",
    "slingshotammo_lunarplant",
    "slingshotammo_voidcloth",
    "slingshotammo_newammo",
}

local WALTER_VALID_AMMO_PREFABS

local function BuildWalterValidAmmoPrefabs()
    if WALTER_VALID_AMMO_PREFABS ~= nil then
        return WALTER_VALID_AMMO_PREFABS
    end
    WALTER_VALID_AMMO_PREFABS = {}
    for _, prefab in ipairs(WALTER_SLINGSHOT_AMMO_PREFABS) do
        if PrefabExists(prefab) then
            table.insert(WALTER_VALID_AMMO_PREFABS, prefab)
        end
    end
    return WALTER_VALID_AMMO_PREFABS
end

local function ResolveWalterKiller(inst, depth)
    if inst == nil or not inst:IsValid() then
        return nil
    end
    depth = depth or 0
    if depth > 8 then
        return nil
    end
    if inst.prefab == "walter" and inst:HasTag("player") then
        return inst
    end
    if inst._attacker ~= nil then
        local killer = ResolveWalterKiller(inst._attacker, depth + 1)
        if killer ~= nil then
            return killer
        end
    end
    if inst.owner ~= nil then
        local killer = ResolveWalterKiller(inst.owner, depth + 1)
        if killer ~= nil then
            return killer
        end
    end
    if inst.components.inventoryitem ~= nil then
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner ~= nil and owner:IsValid() then
            local killer = ResolveWalterKiller(owner, depth + 1)
            if killer ~= nil then
                return killer
            end
        end
    end
    if inst.components.projectile ~= nil and inst.components.projectile.owner ~= nil then
        local killer = ResolveWalterKiller(inst.components.projectile.owner, depth + 1)
        if killer ~= nil then
            return killer
        end
    end
    if inst.components.combat ~= nil and inst.components.combat.lastattacker ~= nil then
        return ResolveWalterKiller(inst.components.combat.lastattacker, depth + 1)
    end
    return nil
end

local function ResolveWalterKillerFromDeath(victim, afflicter)
    local killer = ResolveWalterKiller(afflicter)
    if killer ~= nil then
        return killer
    end
    if victim ~= nil and victim.components.health ~= nil then
        killer = ResolveWalterKiller(victim.components.health.causeofdeath)
        if killer ~= nil then
            return killer
        end
    end
    if victim ~= nil and victim.components.combat ~= nil then
        killer = ResolveWalterKiller(victim.components.combat.lastattacker)
        if killer ~= nil then
            return killer
        end
    end
    return nil
end

local function GetVictimMaxHealth(victim)
    if victim == nil or victim.components.health == nil then
        return 0
    end
    local health = victim.components.health
    local maxhp = health.maxhealth or 0
    if health.GetMaxWithPenalty ~= nil then
        maxhp = math.max(maxhp, health:GetMaxWithPenalty())
    end
    if victim._roge_max_health ~= nil then
        maxhp = math.max(maxhp, victim._roge_max_health)
    end
    return maxhp
end

local function IsWalterHighHpKillVictim(victim)
    if victim == nil or not victim:IsValid() then
        return false
    end
    if victim:HasTag("player") or victim:HasTag("playerghost") then
        return false
    end
    if victim:HasTag("FX") or victim:HasTag("INLIMBO") then
        return false
    end
    if victim.components.health == nil then
        return false
    end
    return GetVictimMaxHealth(victim) >= WALTER_KILL_AMMO_HP_MIN
end

local function IsWalterBossKillVictim(victim)
    return victim ~= nil and victim:IsValid() and victim:HasTag("epic")
end

local function PickRandomSlingshotAmmoPrefabs(count)
    local pool = BuildWalterValidAmmoPrefabs()
    if #pool == 0 then
        return {}
    end
    local shuffled = {}
    for i, prefab in ipairs(pool) do
        shuffled[i] = prefab
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    local picked = {}
    for i = 1, math.min(count, #shuffled) do
        picked[i] = shuffled[i]
    end
    return picked
end

local function DropSlingshotAmmoStack(prefab, count, x, y, z, dropper)
    local pt = Vector3(x, y, z)
    if dropper ~= nil and dropper.components.lootdropper ~= nil then
        local loot = dropper.components.lootdropper:SpawnLootPrefab(prefab, pt)
        if loot ~= nil and loot:IsValid() then
            if loot.components.stackable ~= nil then
                local maxsize = loot.components.stackable.maxsize or count
                loot.components.stackable:SetStackSize(math.min(count, maxsize))
            end
            return true
        end
    end

    local loot = SpawnPrefab(prefab)
    if loot == nil or not loot:IsValid() then
        return false
    end
    if loot.components.stackable ~= nil then
        local maxsize = loot.components.stackable.maxsize or count
        loot.components.stackable:SetStackSize(math.min(count, maxsize))
    end
    loot.Transform:SetPosition(x, y, z)
    if loot.components.inventoryitem ~= nil then
        loot.components.inventoryitem:OnDropped(true)
    end
    if loot.Physics ~= nil then
        local angle = math.random() * TWOPI
        local speed = 2 + math.random() * 2
        loot.Physics:SetVel(math.cos(angle) * speed, 5 + math.random() * 2, math.sin(angle) * speed)
    end
    return true
end

local function DoWalterAmmoDropAt(killer, victim, x, y, z, boss_kill, dropper)
    local num_types = math.random(WALTER_KILL_AMMO_TYPES_MIN, WALTER_KILL_AMMO_TYPES_MAX)
    local prefabs = PickRandomSlingshotAmmoPrefabs(num_types)
    if #prefabs == 0 then
        if victim ~= nil then
            victim._roge_walter_ammo_dropped = nil
        end
        return
    end

    if dropper == nil or not dropper:IsValid() then
        dropper = victim
    end

    for _, prefab in ipairs(prefabs) do
        local count = math.random(WALTER_KILL_AMMO_COUNT_MIN, WALTER_KILL_AMMO_COUNT_MAX)
        if boss_kill then
            count = count * WALTER_KILL_AMMO_BOSS_COUNT_MULT
        end
        DropSlingshotAmmoStack(prefab, count, x, y, z, dropper)
    end
end

local function TryWalterAmmoDrop(killer, victim)
    if not TheWorld.ismastersim then
        return
    end
    if killer == nil or not killer:IsValid() or killer.prefab ~= "walter" then
        return
    end
    if victim == nil or not victim:IsValid() or victim._roge_walter_ammo_dropped then
        return
    end
    if not IsWalterHighHpKillVictim(victim) then
        return
    end
    victim._roge_walter_ammo_dropped = true

    local x, y, z = victim.Transform:GetWorldPosition()
    local boss_kill = IsWalterBossKillVictim(victim)
    local dropper = victim
    if dropper.components.lootdropper == nil and killer.components.lootdropper ~= nil then
        dropper = killer
    end
    DoWalterAmmoDropAt(killer, victim, x, y, z, boss_kill, dropper)
end

local function OnWalterKillHighHpCreature(inst, data)
    TryWalterAmmoDrop(inst, data ~= nil and data.victim or nil)
end

local function OnWorldEntityDeathForWalter(walter, src, data)
    if data == nil or data.inst == nil then
        return
    end
    local killer = ResolveWalterKillerFromDeath(data.inst, data.afflicter)
    if killer == walter then
        TryWalterAmmoDrop(walter, data.inst)
    end
end

local function OnWorldEntityDeath(src, data)
    if data == nil or data.inst == nil then
        return
    end
    local killer = ResolveWalterKillerFromDeath(data.inst, data.afflicter)
    TryWalterAmmoDrop(killer, data.inst)
end

local function SetupWalterAmmoDropListeners(inst)
    if not TheWorld.ismastersim or inst.prefab ~= "walter" then
        return
    end
    if inst._roge_walter_ammo_listeners then
        return
    end
    inst._roge_walter_ammo_listeners = true

    inst:ListenForEvent("killed", OnWalterKillHighHpCreature)
    if inst._roge_walter_entity_death_fn == nil then
        inst._roge_walter_entity_death_fn = function(src, data)
            OnWorldEntityDeathForWalter(inst, src, data)
        end
        inst:ListenForEvent("entity_death", inst._roge_walter_entity_death_fn, TheWorld)
    end
end

AddPlayerPostInit(SetupWalterAmmoDropListeners)
AddPrefabPostInit("walter", SetupWalterAmmoDropListeners)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("entity_death", OnWorldEntityDeath)
end)
