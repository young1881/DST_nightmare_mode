local fname = "hat_brainjelly"
local symname = "brainjellyhat"
local assets =
{
    Asset("ANIM", "anim/hat_brainjelly.zip"),
    Asset("IMAGE", "images/inventoryimages/brainjellyhat.tex"),
    Asset("ATLAS", "images/inventoryimages/brainjellyhat.xml"),
}


local prefabs =
{

}


local function _onequip(inst, owner, symbol_override)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, fname)
    else
        owner.AnimState:OverrideSymbol("swap_hat", fname, symbol_override or "swap_hat")
    end
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
end

local function _onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function simple_common(custom_init)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(symname)
    inst.AnimState:SetBuild(fname)
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    if custom_init ~= nil then
        custom_init(inst)
    end

    return inst
end
local function simple_onequip(inst, owner, from_ground)
    _onequip(inst, owner)
end

local function simple_onunequip(inst, owner, from_ground)
    _onunequip(inst, owner)
end

local function simple_onequiptomodel(inst, owner, from_ground)
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function simple_master(inst)
    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(simple_onequip)
    inst.components.equippable:SetOnUnequip(simple_onunequip)
    inst.components.equippable:SetOnEquipToModel(simple_onequiptomodel)
end

local function brainjelly_onequip(inst, owner)
    _onequip(inst, owner)
    if owner.components.builder then
        if owner.components.builder ~= nil then
            owner.components.builder.ancient_bonus = 4
            owner.components.builder.science_bonus = 4
            owner.components.builder.magic_bonus = 4
            owner.components.builder.seafaring_bonus = 4
        end

        inst.brainjelly_onbuild = function(owner, data)
            if data and (data.used_jellybrainhat == nil or data.used_jellybrainhat) then
                inst.components.finiteuses:Use(1)
            end
        end

        owner:ListenForEvent("builditem", inst.brainjelly_onbuild)
        owner:ListenForEvent("bufferbuild", inst.brainjelly_onbuild)
    end
end

local function brainjelly_onunequip(inst, owner)
    _onunequip(inst, owner)
    if owner.components.builder then
        if owner.components.builder ~= nil then
            owner.components.builder.ancient_bonus = 0
            owner.components.builder.science_bonus = 0
            owner.components.builder.magic_bonus = 0
            owner.components.builder.seafaring_bonus = 0
        end
        owner:RemoveEventCallback("builditem", inst.brainjelly_onbuild)
        owner:RemoveEventCallback("bufferbuild", inst.brainjelly_onbuild)
        inst.brainjelly_onbuild = nil
    end
end



local function brainjelly()
    local inst = simple_common()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    simple_master(inst)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(3)
    inst.components.finiteuses:SetPercent(1)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst.components.inventoryitem.atlasname = "images/inventoryimages/brainjellyhat.xml"

    inst.components.equippable:SetOnEquip(brainjelly_onequip)
    inst.components.equippable:SetOnUnequip(brainjelly_onunequip)

    return inst
end


return Prefab("brainjellyhat", brainjelly, assets, prefabs)
