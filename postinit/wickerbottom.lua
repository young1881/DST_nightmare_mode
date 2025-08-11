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
        -- 本草纲目
        name = "mb_book_bcgm",
        makings = { Ingredient("papyrus", 2), Ingredient("royal_jelly", 2), Ingredient("coin_1", 1) }
    },
}

for _, v in ipairs(books) do
    local tech = TECH.BOOKCRAFT_ONE
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
end)

local PI2 = 2 * math.pi
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
                    bee.summoned_by_book = true -- 标记召唤的bee

                    SpawnPrefab("bee_poof_big").Transform:SetPosition(pos_x, pos_y, pos_z)
                end)
            end)
        end

        return true
    end

    local function onread_wrapper(inst, reader)
        if fueled:IsEmpty() then
            if reader.components.talker then
                reader.components.talker:Say("这本书已经没有噩梦燃料了！")
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
                lootdropper:AddChanceLoot("royal_jelly", 0.10)
            else
                lootdropper:AddChanceLoot("royal_jelly", 0.01)
            end
        end
    end)
end)
