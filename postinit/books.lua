local assets =
{
    Asset("ANIM", "anim/books.zip"),
    Asset("FX", "fx_book_bees"),
}

local prefabs =
{
    "beeguard",
    "bee_poof_big",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("books")
    inst.AnimState:SetBuild("books")
    inst.AnimState:PlayAnimation("book_bees")

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    inst:AddTag("book")
    inst:AddTag("bookcabinet_item")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("book")
    inst.components.book:SetOnRead(OnUseBook)
    inst.components.book:SetReadSanity(-TUNING.SANITY_LARGE)
    inst.components.book:SetFx("fx_book_bees")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.BOOK_USES_BEES)
    inst.components.finiteuses:SetUses(TUNING.BOOK_USES_BEES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunch(inst)

    return inst
end

local function OnUseBook(inst, reader)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    end

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
            local pos_x, pos_y, pos_z = x + radius * math.cos((i-1) * delta_theta), 0, z + radius * math.sin((i-1) * delta_theta)

            reader:DoTaskInTime(0.1 * i, function() 
                local fx = SpawnPrefab("fx_book_bees")
                fx.Transform:SetPosition(pos_x,pos_y,pos_z)
            end)
            
            reader:DoTaskInTime(0.15 * i, function()
                local queen = TheSim:FindEntities(x, y, z, 16, BEES_MUST_TAGS)[1] or nil

                local bee = SpawnPrefab("beeguard")
                bee.Transform:SetPosition(pos_x, pos_y, pos_z)
                bee:AddToArmy(queen or reader)
                SpawnPrefab("bee_poof_big").Transform:SetPosition(pos_x, pos_y, pos_z)
            end)
        end)
    end

    inst.components.fueled:DoDelta(-TUNING.BOOK_BEES_FUEL_COST, reader)
    return true
end

return Prefab("book_bees", fn, assets, prefabs)