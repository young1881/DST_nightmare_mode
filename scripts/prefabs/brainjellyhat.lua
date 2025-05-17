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

STRINGS.CHARACTERS.GENERIC.DESCRIBE.BRAINJELLYHAT = "许多难以置信的设计蓝图现在出现在了我的脑海中！"
STRINGS.CHARACTERS.WARLY.DESCRIBE.BRAINJELLYHAT = "我可以感觉到灵感向我涌来！等等，那是脑汁。"
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.BRAINJELLYHAT = "我的脑袋和我的剑一样强大！"
STRINGS.CHARACTERS.WX78.DESCRIBE.BRAINJELLYHAT = "提供可下载内容"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.BRAINJELLYHAT = "聪明的头戴物"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.BRAINJELLYHAT = "戴上这个之后，我感觉自己像个智者。"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.BRAINJELLYHAT = "啊！它让沃尔夫冈思考！"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.BRAINJELLYHAT = "我感觉更聪明了，但也觉得更恶心了..."
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BRAINJELLYHAT = "创意和想法改变未来！"
STRINGS.CHARACTERS.WANDA.DESCRIBE.BRAINJELLYHAT = "如果我戴上它变得更聪明了，我应该能搞清楚它的工作原理。"
STRINGS.CHARACTERS.WENDY.DESCRIBE.BRAINJELLYHAT = "这会让我的脑袋看上去很大吗？"
STRINGS.CHARACTERS.WEBBER.DESCRIBE.BRAINJELLYHAT = "我觉得我们的脑袋变聪明了，而且头上黏糊糊的。"
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BRAINJELLYHAT = "我觉得受到了启发。"
STRINGS.CHARACTERS.WALTER.DESCRIBE.BRAINJELLYHAT = "用相当于十本，不，二十本松树先锋手册填满你的脑袋！"
STRINGS.CHARACTERS.WURT.DESCRIBE.BRAINJELLYHAT = "再也不用书了，浮浪特。"
STRINGS.NAMES.BRAINJELLYHAT = "智慧帽"

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
