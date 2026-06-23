TUNING.BOOK_BEES_AMOUNT = 2            --养蜂笔记每次蜜蜂数量
TUNING.BOOK_BEES_MAX_ATTACK_RANGE = 1.3 --养蜂笔记蜜蜂的最大攻击范围
TUNING.BOOK_MAX_GRUMBLE_BEES = 8      --养蜂笔记最大蜜蜂数量

-- 为book_summoned_bee设置智能索敌系统的函数（必须在前面定义，因为会在后面被调用）
function SetSmartBeeAI(bee)
    if not bee or not bee:IsValid() or not bee.components.combat then
        return
    end
    
    -- 改进的RetargetFn：更智能的索敌
    local function SmartRetargetFn(inst)
        -- 如果当前有有效的focus target，优先保持
        if inst._focustarget ~= nil and inst._focustarget:IsValid() and 
           not (inst._focustarget.components.health and inst._focustarget.components.health:IsDead()) then
            return inst._focustarget
        end
        
        -- 获取主人（玩家）
        local owner = inst.components.commander and inst.components.commander.commander or nil
        if not owner or not owner:IsValid() then
            return nil
        end
        
        local x, y, z = inst.Transform:GetWorldPosition()
        
        -- 优先选择主人正在攻击的目标（集火攻击）
        if owner.components.combat and owner.components.combat.target then
            local owner_target = owner.components.combat.target
            if owner_target:IsValid() and not (owner_target.components.health and owner_target.components.health:IsDead()) then
                local dist_sq = inst:GetDistanceSqToInst(owner_target)
                if dist_sq < 50 * 50 then -- 50单位范围内
                    -- 让所有蜜蜂集火主人的目标
                    return owner_target
                end
            end
        end
        
        -- 检查是否有其他蜜蜂已经选择了目标，如果有则集火同一个目标
        if owner.components.commander then
            local all_bees = owner.components.commander:GetAllSoldiers("beeguard")
            for _, other_bee in ipairs(all_bees) do
                if other_bee ~= inst and other_bee:IsValid() and other_bee.components.combat and other_bee.components.combat.target then
                    local shared_target = other_bee.components.combat.target
                    if shared_target:IsValid() and not (shared_target.components.health and shared_target.components.health:IsDead()) then
                        local dist_sq = inst:GetDistanceSqToInst(shared_target)
                        if dist_sq < 5 * 5 then -- 50单位范围内
                            return shared_target
                        end
                    end
                end
            end
        end
        
        -- 搜索附近的敌人（更大的搜索范围，智能筛选）
        local search_range = 1 -- 搜索范围增加到40
        local ents = TheSim:FindEntities(
            x, y, z, search_range,
            { "_combat", "_health" },
            { "INLIMBO", "player", "bee", "notarget", "invisible", "flight", "companion" }
        )
        
        -- 过滤有效目标并按优先级排序
        local valid_targets = {}
        for _, ent in ipairs(ents) do
            if ent:IsValid() and 
               not (ent.components.health and ent.components.health:IsDead()) and
               ent.components.combat ~= nil then
                -- 检查是否在攻击主人或主人的其他蜜蜂
                local is_threat = false
                if ent.components.combat.target == owner then
                    is_threat = true
                elseif owner.components.commander then
                    local all_bees = owner.components.commander:GetAllSoldiers("beeguard")
                    for _, other_bee in ipairs(all_bees) do
                        if ent.components.combat.target == other_bee then
                            is_threat = true
                            break
                        end
                    end
                end
                
                table.insert(valid_targets, {
                    ent = ent,
                    dist_sq = inst:GetDistanceSqToInst(ent),
                    is_threat = is_threat,
                    -- 优先攻击威胁主人的敌人
                    priority = is_threat and 0 or 1
                })
            end
        end
        
        if #valid_targets == 0 then
            return nil
        end
        
        -- 按优先级和距离排序
        table.sort(valid_targets, function(a, b)
            if a.priority ~= b.priority then
                return a.priority < b.priority
            end
            return a.dist_sq < b.dist_sq
        end)
        
        -- 集火攻击：选择优先级最高且距离最近的目标（所有蜜蜂会选择同一个）
        local top_priority = valid_targets[1].priority
        local best_target = nil
        local best_dist_sq = math.huge
        
        -- 在优先级最高的目标中选择最近的
        for _, v in ipairs(valid_targets) do
            if v.priority == top_priority and v.dist_sq < best_dist_sq then
                best_target = v.ent
                best_dist_sq = v.dist_sq
            elseif v.priority ~= top_priority then
                break
            end
        end
        
        return best_target
    end
    
    -- 改进的KeepTargetFn：更智能的保持目标
    local function SmartKeepTargetFn(inst, target)
        if not target or not target:IsValid() then
            return false
        end
        
        if target.components.health and target.components.health:IsDead() then
            return false
        end
        
        -- 如果有focus target，保持它
        if inst._focustarget == target then
            return true
        end
        
        -- 检查距离（保持目标的范围更大）
        local keep_range = 50 -- 增加到50单位
        if not inst:IsNear(target, keep_range) then
            return false
        end
        
        -- 如果目标正在攻击主人，优先保持
        local owner = inst.components.commander and inst.components.commander.commander or nil
        if owner and owner:IsValid() and target.components.combat and target.components.combat.target == owner then
            return true
        end
        
        -- 如果目标在攻击范围内，保持
        if inst.components.combat:CanTarget(target) then
            return true
        end
        
        return false
    end
    
    -- 应用新的函数
    if bee:IsValid() and bee.components.combat then
        bee.components.combat:SetRetargetFunction(1, SmartRetargetFn)
        bee.components.combat:SetKeepTargetFunction(SmartKeepTargetFn)
    end
end

-- 警告表双配方
AddRecipe2("pocketwatch_weapon2",
    { Ingredient("tentaclespike", 1), Ingredient("nightsword", 3), Ingredient("purplegem", 3), Ingredient(
        "waxwelljournal", 0), Ingredient("horrorfuel", 7) }, TECH.SCIENCE_ONE,
    {
        product = "pocketwatch_weapon",
        image = "pocketwatch_weapon.tex",
        description =
        "pocketwatch_weapon2",
        builder_tag = "reader"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.POCKETWATCH_WEAPON2 = "暗影秘典的力量成功复制了这件完美的艺术品"

-- 养蜂笔记
AddRecipe2("book_bees2",
    { Ingredient("papyrus", 2), Ingredient(	"beeswax", 4), Ingredient(	"fossil_piece", 2), Ingredient(
        "horrorfuel", 3) }, TECH.NONE_TWO,
    {
        product = "book_bees",
        image = "book_bees.tex",
        description =
        "book_bees2",
        builder_tag = "bookbuilder"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.BOOK_BEES2 = "使用古老的遗物来召唤先古蜂群"

-- 蛛网秘典：读书时在玩家周围召唤蛛网（布置圆半径 16；减速范围沿用原版 book_web_ground）
local BOOK_WEB_RING_COUNT = 5
local BOOK_WEB_PLACEMENT_RADIUS = 16

local PI2 = 2 * math.pi

-- 蛛形纲（book_web）：魔法二级科技解锁
AddRecipePostInit("book_web", function(recipe)
    recipe.level = TECH.MAGIC_TWO
end)

AddPrefabPostInit("book_web", function(inst)
    if not TheWorld.ismastersim or inst.components.book == nil then
        return
    end

    local function SpawnBookWebAt(x, y, z)
        local ground_web = SpawnPrefab("book_web_ground")
        if ground_web ~= nil then
            ground_web.Transform:SetPosition(x, y, z)
        end
    end

    inst.components.book:SetOnRead(function(book_inst, reader)
        if reader == nil or not reader:IsValid() then
            return false
        end

        local x, y, z = reader.Transform:GetWorldPosition()

        -- 读书位置中心一块
        SpawnBookWebAt(x, y, z)

        -- 四周五块
        local delta_theta = PI2 / BOOK_WEB_RING_COUNT
        for i = 1, BOOK_WEB_RING_COUNT do
            local angle = (i - 1) * delta_theta
            local px = x + BOOK_WEB_PLACEMENT_RADIUS * math.cos(angle)
            local pz = z + BOOK_WEB_PLACEMENT_RADIUS * math.sin(angle)
            SpawnBookWebAt(px, y, pz)
        end

        return true
    end)
end)

local SCIENCE_RADIUS = 3

local function CheckNearbyPlayers(inst)
    if not inst:IsValid() or inst.components.health:IsDead() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x, y, z, SCIENCE_RADIUS, { "player" }, { "playerghost" })

    for _, player in ipairs(players) do
        if player.components.builder then
            if not player._wickerbottom_science_bonus then
                player.components.builder.science_bonus = player.components.builder.science_bonus + 1
                player._wickerbottom_science_bonus = true
            end
        end
    end

    for _, player in ipairs(AllPlayers) do
        if player._wickerbottom_science_bonus and not table.contains(players, player) then
            if player.components.builder then
                player.components.builder.science_bonus = math.max(player.components.builder.science_bonus - 1, 0)
                player._wickerbottom_science_bonus = false
            end
        end
    end
end

AddPrefabPostInit("wickerbottom", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("darkmagic")
    inst:AddTag("writer")
    inst.components.builder.science_bonus = 2
    inst:DoPeriodicTask(0.5, function() CheckNearbyPlayers(inst) end)
end)

local books = {
    {
        -- 美杜莎之眼
        name = "mb_book_medusa",
        makings = { Ingredient("papyrus", 2), Ingredient("ice", 2), Ingredient("saltrock", 10) }
    },
    {
        -- 本草纲目（魔法二级科技解锁）
        name = "mb_book_bcgm",
        makings = { Ingredient("papyrus", 2), Ingredient("royal_jelly", 2), Ingredient("coin_1", 1) },
        tech = TECH.MAGIC_TWO,
    },
}

for _, v in ipairs(books) do
    local tech = v.tech or TECH.BOOKCRAFT_ONE
    local config = {
        builder_tag = "bookbuilder",
        atlas = "images/inventoryimages/" .. (v.resname or v.name) .. ".xml",
        image = (v.resname or v.name) ..
            ".tex",
    }
    for ck, cv in pairs(v.config or {}) do
        config[ck] = cv
    end
    AddRecipe2(v.name, v.makings, tech, config, { "CHARACTER" })
end

AddPrefabPostInit("beeguard", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("crazy") -- 打影怪的标签
    inst:AddTag("curse_immune") -- 免疫诅咒「怠惰」等附加催眠
    if inst.components.sleeper ~= nil then
        inst:RemoveComponent("sleeper")
    end

    local function GetBeeguardOwner(inst)
        if inst.GetQueen ~= nil then
            local queen = inst:GetQueen()
            if queen ~= nil and queen:IsValid() then
                return queen
            end
        end
        if inst.components.follower ~= nil then
            local leader = inst.components.follower.leader
            if leader ~= nil and leader:IsValid() then
                return leader
            end
        end
        if inst._friendref ~= nil and inst._friendref:IsValid() then
            return inst._friendref
        end
        return nil
    end

    local BEE_SHADOW_KILL_SANITY_RADIUS = 20

    local function OnKillShadow(inst, data)
        local victim = data.victim
        if victim and (victim:HasTag("shadow") or victim.prefab == "dreadeye") then
            local owner = GetBeeguardOwner(inst)
            if owner and owner:IsValid() and owner.prefab == "wickerbottom"
                and (victim.sanityreward or victim.prefab == "dreadeye") then
                local sanity_delta = victim.prefab == "dreadeye" and 20 or 10
                local x, y, z = inst.Transform:GetWorldPosition()
                local players = TheSim:FindEntities(x, y, z, BEE_SHADOW_KILL_SANITY_RADIUS, { "player" }, { "playerghost", "INLIMBO" })
                for _, player in ipairs(players) do
                    if player:IsValid() and player.components.sanity ~= nil then
                        player.components.sanity:DoDelta(sanity_delta)
                    end
                end
            end
        end
    end
    inst:ListenForEvent("killed", OnKillShadow)
end)

local BEES_MUST_TAGS = { "beeguard" }

AddPrefabPostInit("book_bees", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not inst.SoundEmitter then
        inst.entity:AddSoundEmitter()
    end

    if inst.components.finiteuses then
        inst:RemoveComponent("finiteuses")
    end

    if not inst.components.fueled then
        inst:AddComponent("fueled")
    end

    local fueled = inst.components.fueled
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(TUNING.LARGE_FUEL * 4)

    fueled:SetDepletedFn(function(inst)
        inst.AnimState:SetMultColour(0.4, 0.4, 0.4, 1)
    end)

    fueled:SetTakeFuelFn(function(inst)
        inst.AnimState:SetMultColour(1, 1, 1, 1)
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
        end
    end)

    local function book_bees_fn(inst, reader)
        reader:MakeGenericCommander()

        local beescount = TUNING.BOOK_BEES_AMOUNT

        if reader.components.commander:GetNumSoldiers("beeguard") + beescount > TUNING.BOOK_MAX_GRUMBLE_BEES then
            return false, "TOOMANYBEES"
        end

        local x, y, z = reader.Transform:GetWorldPosition()
        local radius = TUNING.BEEGUARD_GUARD_RANGE * 0.5
        local delta_theta = PI2 / beescount

        for i = 1, beescount do
            reader:DoTaskInTime(i * 0.075, function()
                local pos_x, pos_y, pos_z = x + radius * math.cos((i - 1) * delta_theta), 0,
                    z + radius * math.sin((i - 1) * delta_theta)

                reader:DoTaskInTime(0.1 * i, function()
                    local fx = SpawnPrefab("fx_book_bees")
                    fx.Transform:SetPosition(pos_x, pos_y, pos_z)
                end)

                reader:DoTaskInTime(0.15 * i, function()
                    local queen = TheSim:FindEntities(x, y, z, 16, BEES_MUST_TAGS)[1] or nil


                    local bee = SpawnPrefab("beeguard")
                    bee.Transform:SetPosition(pos_x, pos_y, pos_z)
                    bee:AddToArmy(queen or reader)
                    bee.summoned_by_book = true 
                    bee:AddTag("book_summoned_bee")
                    
                    -- 为book_summoned_bee设置智能索敌系统
                    bee:DoTaskInTime(0.1, function()
                        if bee:IsValid() and bee.components.combat then
                            SetSmartBeeAI(bee)
                        end
                    end) 

               
                    if not bee.components.health then
                        bee:AddComponent("health")
                        bee.components.health:SetMaxHealth(280)
                        bee.components.health:SetCurrentHealth(280)
                    else
                        bee.components.health:SetMaxHealth(280)
                        bee.components.health:SetCurrentHealth(280)
                    end

                  
                    if bee.components.combat then
                        bee.components.combat:SetDefaultDamage(35) 
                        bee.components.planardamage:SetBaseDamage(10)
                        bee.components.combat:SetAttackPeriod(0.9) 
                        bee.components.combat:SetRange(TUNING.BOOK_BEES_MAX_ATTACK_RANGE) 
                    end

                    if bee.components.damagetyperesist == nil then
                        bee:AddComponent("damagetyperesist")
                    end
                    bee.components.damagetyperesist:AddResist("shadow_aligned", bee, 0.4) -- 对暗影伤害40%抗性

                    bee.persists = false 
                    bee:AddTag("electricdamageimmune") 

                    SpawnPrefab("bee_poof_big").Transform:SetPosition(pos_x, pos_y, pos_z)
                end)
            end)
        end

        return true
    end

    local function onread_wrapper(inst, reader)
        if fueled:IsEmpty() then
            if reader.components.talker then
                reader.components.talker:Say("这本饥饿的书需要噩梦的滋养！")
            end
            return false, "NOFUEL"
        end

        fueled:DoDelta(-TUNING.LARGE_FUEL)
        return book_bees_fn(inst, reader)
    end

    if inst.components.book then
        inst.components.book:SetOnRead(onread_wrapper)
    end

    if inst.components.finiteuses and inst.components.finiteuses.SetOnFinished then
        inst.components.finiteuses:SetOnFinished(nil)
    end
end)

AddPrefabPostInit("beeguard", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("death", function(beeguard_inst)
        local lootdropper = beeguard_inst.components.lootdropper
        if lootdropper then
            lootdropper:SetLoot({})
            if beeguard_inst.summoned_by_book then
                lootdropper:AddChanceLoot("royal_jelly", 0.10) -- 书本召唤的蜜蜂10%掉落蜂王浆
            else
                lootdropper:AddChanceLoot("royal_jelly", 0.01) -- 原版蜜蜂1%掉落蜂王浆
            end
        end
    end)
end)

-- 蜜蜂冲刺功能
local BEE_DASH_COOLDOWN = 3 -- 集火冷却（秒）
local BEE_DASH_DURATION = 15 -- 冲刺持续时间（秒）
local BEE_GUARD_DEFEND_PERIOD = 2 -- 防御环：拉回身边间隔
local BEE_GUARD_DEFEND_MAX_DIST_SQ = 12 * 12 -- 超过此距离则走向玩家附近
local BEE_GUARD_MAX_CHASE_DIST_SQ = 25 * 25 -- 敌人离玩家过远则放弃追击（持续防御）

local function WickerBottomCollectBookBees(inst)
    if inst.components.commander == nil then
        return {}
    end
    local out = {}
    for _, bee in ipairs(inst.components.commander:GetAllSoldiers("beeguard")) do
        if bee:IsValid() and bee:HasTag("book_summoned_bee") then
            table.insert(out, bee)
        end
    end
    return out
end

local function WickerBottomClearBeeDashAll(inst)
    if inst.components.commander == nil then
        return
    end
    for _, bee in ipairs(inst.components.commander:GetAllSoldiers("beeguard")) do
        if bee:IsValid() and bee:HasTag("book_summoned_bee") then
            if bee.FocusTarget ~= nil then
                bee:FocusTarget(nil)
            end
            bee:RemoveTag("notaunt")
            bee._focustarget = nil
            if bee.components.combat ~= nil then
                bee.components.combat:SetTarget(nil)
            end
        end
    end
end

local function WickerBottomStopBeeGuardDefend(inst)
    if inst._bee_guard_defend_task ~= nil then
        inst._bee_guard_defend_task:Cancel()
        inst._bee_guard_defend_task = nil
    end
end

local function WickerBeeGoOrbitNearOwner(bee, owner)
    if bee == nil or not bee:IsValid() or owner == nil or not owner:IsValid() then
        return
    end
    if bee.components.locomotor == nil then
        return
    end
    local ox, oy, oz = owner.Transform:GetWorldPosition()
    local ang = math.random() * PI2
    local rad = 3 + math.random() * 4
    local dx = ox + math.cos(ang) * rad
    local dz = oz + math.sin(ang) * rad
    local pt = GLOBAL.Vector3 ~= nil and GLOBAL.Vector3(dx, 0, dz) or Point(dx, 0, dz)
    bee.components.locomotor:GoToPoint(pt, nil, true)
end

-- 冲刺结束后 / 手动撤退：保持蜂在玩家附近，并放弃追击过远的敌人（持续防御）
local function WickerBottomBeeGuardDefendTick(inst)
    if not inst:IsValid() or inst.components.commander == nil then
        WickerBottomStopBeeGuardDefend(inst)
        return
    end
    for _, bee in ipairs(WickerBottomCollectBookBees(inst)) do
        if bee:IsValid() then
            if inst:GetDistanceSqToInst(bee) > BEE_GUARD_DEFEND_MAX_DIST_SQ then
                WickerBeeGoOrbitNearOwner(bee, inst)
            end
            local ct = bee.components.combat ~= nil and bee.components.combat.target or nil
            if ct ~= nil and ct:IsValid() and inst:GetDistanceSqToInst(ct) > BEE_GUARD_MAX_CHASE_DIST_SQ then
                bee.components.combat:SetTarget(nil)
            end
        end
    end
end

local function WickerBottomStartBeeGuardDefend(inst)
    WickerBottomStopBeeGuardDefend(inst)
    inst._bee_guard_defend_task = inst:DoPeriodicTask(BEE_GUARD_DEFEND_PERIOD, function()
        WickerBottomBeeGuardDefendTick(inst)
    end)
end

local function WickerBottomIsValidBeeDashMouseTarget(player, ent, sample_bee)
    if ent == nil or not ent:IsValid() or player == nil then
        return false
    end
    if ent == player then
        return false
    end
    if ent:HasTag("INLIMBO") or ent:HasTag("FX") or ent:HasTag("NOCLICK") then
        return false
    end
    if ent.components.health == nil or ent.components.health:IsDead() then
        return false
    end
    if ent:HasTag("player") and not TheNet:GetPVPEnabled() then
        return false
    end
    if sample_bee ~= nil and sample_bee.components.combat ~= nil and not sample_bee.components.combat:CanTarget(ent) then
        return false
    end
    return true
end

local function WickerBottomResolveBeeDashTarget(inst, mouse_ent, sample_bee)
    if WickerBottomIsValidBeeDashMouseTarget(inst, mouse_ent, sample_bee) then
        return mouse_ent
    end
    if inst.components.combat and inst.components.combat.target then
        local t = inst.components.combat.target
        if t:IsValid() and not (t.components.health and t.components.health:IsDead()) then
            return t
        end
    end
    local available_targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, { "_combat", "_health" }, { "INLIMBO", "player", "bee", "notarget", "invisible", "flight" })
    for _, ent in ipairs(ents) do
        if WickerBottomIsValidBeeDashMouseTarget(inst, ent, sample_bee) then
            table.insert(available_targets, ent)
        end
    end
    table.sort(available_targets, function(a, b)
        return inst:GetDistanceSqToInst(a) < inst:GetDistanceSqToInst(b)
    end)
    return available_targets[1]
end

AddModRPCHandler("my_mod", "bee_dash_command", function(inst, mouse_ent)
    if not TheWorld.ismastersim then
        return
    end

    if inst == nil or not inst:IsValid() or not inst:HasTag("player") then
        return
    end

    if not inst.components.commander then
        return
    end

    local bees = WickerBottomCollectBookBees(inst)

    if #bees == 0 then
        if inst.components.talker then
            inst.components.talker:Say("我们已经无兵可用！")
        end
        return
    end

    local current_time = GetTime()
    local is_on_cooldown = inst._bee_dash_last_use and (current_time - inst._bee_dash_last_use) < BEE_DASH_COOLDOWN

    local has_dashing = false
    for _, bee in ipairs(bees) do
        if bee:IsValid() and bee._focustarget ~= nil then
            has_dashing = true
            break
        end
    end

    -- CD 未过但在冲刺：立刻取消冲刺，清仇恨，回玩家身边并进入持续防御（环形守御）
    if is_on_cooldown and has_dashing then
        if inst._bee_dash_clear_task then
            inst._bee_dash_clear_task:Cancel()
            inst._bee_dash_clear_task = nil
        end
        WickerBottomClearBeeDashAll(inst)
        for _, bee in ipairs(bees) do
            if bee:IsValid() then
                WickerBeeGoOrbitNearOwner(bee, inst)
            end
        end
        WickerBottomStartBeeGuardDefend(inst)
        if inst.components.talker then
            inst.components.talker:Say("嗡嗡守卫，撤回守御！")
        end
        return
    end

    if is_on_cooldown then
        local remaining = BEE_DASH_COOLDOWN - (current_time - inst._bee_dash_last_use)
        if inst.components.talker then
            inst.components.talker:Say(string.format("守卫们需要休整 (%.1f秒)", remaining))
        end
        return
    end

    local sample_bee = bees[1]
    local attack_target = WickerBottomResolveBeeDashTarget(inst, mouse_ent, sample_bee)

    if attack_target == nil then
        if inst.components.talker then
            inst.components.talker:Say("看来附近没有威胁！")
        end
        return
    end

    WickerBottomStopBeeGuardDefend(inst)

    if has_dashing and inst._bee_dash_clear_task then
        inst._bee_dash_clear_task:Cancel()
        inst._bee_dash_clear_task = nil
    end

    for _, bee in ipairs(bees) do
        if bee:IsValid() and bee.FocusTarget ~= nil then
            bee:FocusTarget(attack_target)
        end
    end

    inst._bee_dash_last_use = GetTime()

    inst._bee_dash_clear_task = inst:DoTaskInTime(BEE_DASH_DURATION, function()
        if not inst:IsValid() then
            return
        end
        inst._bee_dash_clear_task = nil
        local clear_bees = WickerBottomCollectBookBees(inst)
        WickerBottomClearBeeDashAll(inst)
        for _, bee in ipairs(clear_bees) do
            if bee:IsValid() then
                WickerBeeGoOrbitNearOwner(bee, inst)
            end
        end
        WickerBottomStartBeeGuardDefend(inst)
        if inst.components.talker then
            inst.components.talker:Say("嗡嗡守卫，列阵守御！")
        end
    end)

    if inst.components.talker then
        if has_dashing then
            inst.components.talker:Say("嗡嗡守卫，转移火力！")
        else
            inst.components.talker:Say("嗡嗡守卫，集中攻击！")
        end
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/taunt")
    end
end)

-- 客户端按键监听：把鼠标下的实体发给服务端作为集火目标
if GLOBAL.TheInput then
    GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
        if GLOBAL.ThePlayer ~= nil and
            GLOBAL.ThePlayer.prefab == "wickerbottom" and
            GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
            local under = nil
            if GLOBAL.TheInput.GetWorldEntityUnderMouse ~= nil then
                under = GLOBAL.TheInput:GetWorldEntityUnderMouse()
            end
            SendModRPCToServer(MOD_RPC["my_mod"]["bee_dash_command"], under)
        end
    end)
end