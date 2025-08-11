local allowedplants = {
    carrot = true,
    potato = true,
    tomato = true,
}

local function AbleToAcceptTest(inst, item, giver, count)
    if inst.iscollapsed:value() then
        return false
    end

    if not allowedplants[item.prefab] then
        return false
    end

    if not giver:HasTag("player") then
        return false
    end

    local rabbitkingmanager = TheWorld.components.rabbitkingmanager
    if rabbitkingmanager == nil or not rabbitkingmanager:CanFeedCarrot(giver) then
        return false
    end

    return true
end

local function OnItemAccepted(inst, giver, item, count)
    if allowedplants[item.prefab] then
        local rabbitkingmanager = TheWorld.components.rabbitkingmanager
        if rabbitkingmanager then
            rabbitkingmanager:AddCarrotFromPlayer(giver, inst)
        end
    end
end

AddPrefabPostInit("rabbithole", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local trader = inst:AddComponent("trader")
    trader:SetAbleToAcceptTest(AbleToAcceptTest)
    trader:SetOnAccept(OnItemAccepted)
end)
