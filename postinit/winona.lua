TUNING.WINONA_CATAPULT_MEGA_PLANAR_DAMAGE = 75 --启迪投石机位面袭击的伤害
-- TUNING.WINONA_CATAPULT_HEALTH = 250            --投石机的血量

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local ACTIONS = GLOBAL.ACTIONS

STRINGS.NAMES.WINONA_MOVING_BOX        = "薇诺娜的便携基地"
STRINGS.NAMES.WINONA_MOVING_BOX_ITEM   = "薇诺娜的便携基地"

STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_MOVING_BOX      = "哈！终于不用再搬东西了"
STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_MOVING_BOX_ITEM = "塞得比沙丁鱼罐头还紧！"

STRINGS.RECIPE_DESC.WINONA_MOVING_BOX_ITEM = "可收纳你发明的可部署平台"

RegisterInventoryItemAtlas("images/inventoryimages/winona_moving_box_item.xml", "winona_moving_box_item.tex")
AddCharacterRecipe("winona_moving_box_item",
{
    Ingredient("sewing_tape", 3),
    Ingredient("wagpunk_bits", 4),
    Ingredient("cutstone", 5),
},
TECH.NONE,
{
    product = "winona_moving_box_item",
    builder_tag = "portableengineer",
    numtogive = 1,
},
{"CHARACTER"})

local AUTOBASE_DEPLOY = AddAction("AUTOBASE_DEPLOY", "放置在结构下", function(act)
    local item = act.doer.components.inventory:RemoveItem(act.invobject)
    if item then
        item.components.deployable:Deploy(act.target:GetPosition(), act.doer, act.doer.Transform:GetRotation())
        return true
    end
end)
ACTIONS.AUTOBASE_DEPLOY.priority = 10

if TheSim:GetGameID() == "DST" then
    AddReplicableComponent("autobase_packer")
end

local function GetItemComponents(player)
    if player and player.components.inventory then
        local active_item = player.components.inventory:GetActiveItem()
        if active_item and active_item.components.autobase_packer and active_item.components.inventory then
            local x_pos_list = active_item.components.autobase_packer.contents_rel_x
            local z_pos_list = active_item.components.autobase_packer.contents_rel_z
            local item_inv   = active_item.components.inventory
            for k = 1, item_inv.maxslots do
                local item = item_inv.itemslots[k]
                if item then
                    SendModRPCToClient(GetClientModRPC("winonaboxRPC", "ReturnItemComponents"),
                        player.userid, k, item.prefab, x_pos_list[k], z_pos_list[k], false)
                end
                if k == item_inv.maxslots then
                    SendModRPCToClient(GetClientModRPC("winonaboxRPC", "ItemComponentsDone"), player.userid)
                end
            end
        end
    end
end
AddModRPCHandler("winonaboxRPC", "GetItemComponents", GetItemComponents)

local dist_mult = 1 / 1.45

local function ReturnItemComponents(list_index, item_name, x_rel, z_rel)
    if ThePlayer and ThePlayer.replica.inventory then
        local active_item = ThePlayer.replica.inventory:GetActiveItem()
        if active_item and active_item.replica.autobase_packer then
            local packer = active_item.replica.autobase_packer
            packer.contents_name[list_index]   = item_name
            packer.contents_rel_x[list_index]  = x_rel * dist_mult
            packer.contents_rel_z[list_index]  = z_rel * dist_mult
        end
    end
end
AddClientModRPCHandler("winonaboxRPC", "ReturnItemComponents", ReturnItemComponents)

local function ItemComponentsDone()
    if ThePlayer and ThePlayer.replica.inventory then
        local active_item = ThePlayer.replica.inventory:GetActiveItem()
        if active_item and active_item.replica.autobase_packer then
            active_item:PushEvent("actitem_datadone")
        end
    end
end
AddClientModRPCHandler("winonaboxRPC", "ItemComponentsDone", ItemComponentsDone)

AddComponentAction("USEITEM", "autobase_packer", function(inst, doer, target, actions)
    if target:HasTag("engineering") and target:HasTag("structure") and (not inst or not inst:HasTag("filled")) then
        table.insert(actions, ACTIONS.AUTOBASE_DEPLOY)
    end
end)
AddStategraphActionHandler("wilson", ActionHandler(AUTOBASE_DEPLOY, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(AUTOBASE_DEPLOY, "doshortaction"))
