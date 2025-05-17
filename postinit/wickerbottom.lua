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
        makings = { Ingredient("papyrus", 2), Ingredient("jellybean", 6), Ingredient("coin_1", 1) }
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

-- local function postinitfn(inst)
-- 	if not TheWorld.ismastersim then
-- 		return inst
-- 	end

-- 	inst.swap_build = "book_bees"

-- 	inst:AddComponent("inspectable")
-- 	inst.components.inspectable.getstatus = GetStatus

-- 	inst:AddComponent("inventoryitem")

-- 	inst:AddComponent("fueled")  --耐久修复组件
-- 	inst.components.fueled.accepting = true
-- 	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
-- 	inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
-- 	inst.components.fueled:SetDepletedFn(OnFuelDepleted)
-- 	inst.components.fueled:InitializeFuelLevel(TUNING.LARGE_FUEL * 4)  

-- 	inst:AddComponent("fuel")
-- 	inst.components.fuel.fuelvalue = TUNING.MED_FUEL

-- 	inst:AddComponent("aoespell")

-- 	MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
-- 	MakeSmallPropagator(inst)

-- 	inst:AddComponent("hauntable")
-- 	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
-- 	inst.components.hauntable:SetOnHauntFn(OnHaunt)

-- 	inst._activetask = nil
-- 	inst._soundtasks = {}
-- 	inst:ListenForEvent("onputininventory", topocket)
-- 	inst:ListenForEvent("ondropped", toground)
-- 	inst.OnEntitySleep = OnEntitySleep
-- 	inst.OnEntityWake = OnEntityWake


-- end

-- AddPrefabPostInit("book_bees", postinitfn)