local assets =
{
    Asset("ANIM", "anim/ui_icepack_2x3.zip"),
    Asset("ANIM", "anim/battlesong_container.zip"),
    Asset("ATLAS", "images/inventoryimages/clock_container.xml"),
}

local prefabs =
{
    "ash",
}


local function OnUse(inst)
    local owner = inst.components.inventoryitem.owner
    if owner then
        local container = inst.components.container
        if container:IsOpen() then
            container:Close(owner)
        else
            container:Open(owner)
        end
    end
    return false 
end

local function OnDropped(inst)
    if inst.components.container ~= nil then
        inst.components.container:Close()
        inst.components.container.skipautoclose = false
    end
end

local function SetAutoOpenContainer(inst)
    if inst.components.container then
        inst.components.container.stay_open_on_hide = true
     
    end

    if inst.components.inventoryitem then
        inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
            inst.AnimState:PlayAnimation("closed", false)
            
            if inst.components.container then
                inst.components.container.skipautoclose = true

                inst:DoTaskInTime(0, function()
                    if inst:IsValid() and inst.components.container and
                       owner:IsValid() and owner:HasTag("player") then
                        if not inst.components.container:IsOpen() then
                            inst.components.container:Open(owner)
                        end
                    end
                end)
            end
        end)
    end
end

-----------------------------------------------------------------------------------------------

local SOUNDS =
{
    open  = "meta3/wigfrid/battlesong_container_open",
    close = "meta3/wigfrid/battlesong_container_close",
}

-----------------------------------------------------------------------------------------------

local function OnOpen(inst)
    if inst:HasTag("burnt") then return end

    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("open")
    end
    inst.SoundEmitter:PlaySound(inst._sounds.open)
end

local function OnClose(inst)
    if inst:HasTag("burnt") then return end

    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("closed", false)
    end
    inst.SoundEmitter:PlaySound(inst._sounds.close)
end

-----------------------------------------------------------------------------------------------

local function OnBurnt(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end
    DefaultBurntFn(inst)
end

-----------------------------------------------------------------------------------------------

local function OnSave(inst, data)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

-----------------------------------------------------------------------------------------------

local floatable_swap_data = { bank = "battlesong_container", anim = "closed" }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("battlesong_container.png")

    inst.AnimState:SetBank("battlesong_container")
    inst.AnimState:SetBuild("battlesong_container")
    inst.AnimState:PlayAnimation("closed")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.3, { 0.8, 1, 0.8 }, nil, nil, floatable_swap_data)

    inst.entity:SetPristine()
    
    inst:AddTag("pocketwatch") 

    if not TheWorld.ismastersim then
        return inst
    end

    inst._sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("clock_container")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/clock_container.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    
    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(OnUse)

    MakeSmallBurnable(inst)
    MakeMediumPropagator(inst)

    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    SetAutoOpenContainer(inst)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("clock_container", fn, assets, prefabs)