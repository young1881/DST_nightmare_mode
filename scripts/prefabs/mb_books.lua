local easing = require("easing")

local assets_fx =
{
    Asset("ANIM", "anim/fx_books.zip"),
}

local preuse_text = "本人对知识是一窍不通啊。"
local ATTACK_MUST_NOT_HAVE_TAGS = { "INLIMBO", "NOCLICK", "player", "playerghost" }


STRINGS.NAMES.MB_BOOK_MEDUSA = "美杜莎之眼"
STRINGS.RECIPE_DESC.MB_BOOK_MEDUSA = "这本书有美杜莎的魔力"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MB_BOOK_MEDUSA = "这是被美杜莎诅咒过，还是把美杜莎封印在里面了？"

STRINGS.NAMES.MB_BOOK_BCGM = "本草纲目"
STRINGS.RECIPE_DESC.MB_BOOK_BCGM = "让所有人都能吃上一罐彩虹糖豆"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MB_BOOK_BCGM = "太美味了。"

TUNING.MB_RECOVERABLE = true
TUNING.MB_NUM_USES = 3
TUNING.MB_NEED_TECH = true


-- 各阶段石化树数据
local STAGE_PETRIFY_DATA =
{
    normal = {
        {                                         --小树
            prefab = "rock_petrified_tree_short", --对应的石化树
            fx = "petrified_tree_fx_short",       --对应的石化特效
        },
        {                                         --中树
            prefab = "rock_petrified_tree_med",
            fx = "petrified_tree_fx_normal",
        },
        { --大树
            prefab = "rock_petrified_tree_tall",
            fx = "petrified_tree_fx_tall",
        },
        { --枯树
            prefab = "rock_petrified_tree_old",
            fx = "petrified_tree_fx_old",
        },
    },
    --大理石树
    marble = {
        {                                   --小树
            prefab = "marbleshrub_short",   --对应的石化树
            fx = "petrified_tree_fx_short", --对应的石化特效
        },
        {                                   --中树
            prefab = "marbleshrub_normal",
            fx = "petrified_tree_fx_normal",
        },
        { --大树
            prefab = "marbleshrub_tall",
            fx = "petrified_tree_fx_tall",
        },
    },
}

TUNING.JELLYBEAN_TICK_RATE = 1
TUNING.JELLYBEAN_TICK_VALUE = 2.5

local book_defs =
{
    -- 美杜莎之眼
    {
        name = "mb_book_medusa",
        fx_under = "roots",
        layer_sound = { frame = 17, sound = "wickerbottom_rework/book_spells/silviculture" },
        range = 20,
        can_upgrade = true,
        fn = function(inst, reader)
            local x,y,z = reader.Transform:GetWorldPosition()
            local must_have_one_of_tags  = {"petrifiable", "deciduoustree"}  -- 必须包含其中之一的标签
            if inst:HasTag("upgraded") then
                for i, v in ipairs(ATTACK_MUST_HAVE_ONE_OF_TAGS) do
                    table.insert(must_have_one_of_tags, v)
                end
            end
            local ents = TheSim:FindEntities(x, y, z, 20 , nil, ATTACK_MUST_NOT_HAVE_TAGS, must_have_one_of_tags)

            local cant_use = true  -- 条件不足以石化
            if #ents>0 then
                for i, target in ipairs(ents) do
                    if (target:HasTag("petrifiable") or target:HasTag("deciduoustree")) and target.components.growable ~= nil and not target:HasTag("stump") then
                        local stage = target.components.growable.stage or 1  -- 树的级别
                        local petrify_loot = target:HasTag("deciduoustree") and STAGE_PETRIFY_DATA.marble or STAGE_PETRIFY_DATA.normal--石化树信息表

                        local rock = SpawnPrefab(petrify_loot[stage].prefab)
                        if rock then
                            local r, g, b = target.AnimState:GetMultColour()
                            rock.AnimState:SetMultColour(r, g, b, 1)
                            rock.Transform:SetPosition(target.Transform:GetWorldPosition())
                            local fx = SpawnPrefab(petrify_loot[stage].fx)
                            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
                            fx:InheritColour(r, g, b)
                            target:Remove()

                            cant_use = false
                        end
                    end
                end
            end

            if cant_use then
                return false, "NOSILVICULTURE"
            end

            return true
        end,
        perusefn = function(inst,reader)
            if reader.peruse_medusa then
                reader.peruse_medusa(reader)
            end
            reader.components.talker:Say(preuse_text)
            return true
        end,
    },
    -- 本草纲目
    {
        name = "mb_book_bcgm",
        range = 20,
        uses = 5,
        can_upgrade = true,
        fn = function(inst, reader)
            local cant_use = true

            local x, y, z = reader.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, { "player" },
                { "playerghost" })
            if #ents > 0 then
                for i, player in ipairs(ents) do
                    if not player:HasTag("playerghost") then
                        player:AddDebuff("healthregenbuff", "healthregenbuff")
                        cant_use = false
                    end
                end
            end

            if cant_use then
                return false, "NOFRIENDS"
            end
            return true
        end
        ,
        perusefn = function(inst, reader)
            if reader.peruse_bcgm then
                reader.peruse_bcgm(reader)
            end
            reader.components.talker:Say(preuse_text)
            return true
        end
    }
}

local function MakeBook(def)
    local assets =
    {
        Asset("ANIM", "anim/mb_books.zip"),
        --Asset("SOUND", "sound/common.fsb"),
        Asset("IMAGE", "images/inventoryimages/" .. (def.resname or def.name) .. ".tex"),
        Asset("ATLAS", "images/inventoryimages/" .. (def.resname or def.name) .. ".xml"),
        Asset("ATLAS_BUILD", "images/inventoryimages/" .. (def.resname or def.name) .. ".xml", 256),
    }
    local prefabs
    if def.deps ~= nil then
        prefabs = {}
        for i, v in ipairs(def.deps) do
            table.insert(prefabs, v)
        end
    end
    if def.fx ~= nil then
        prefabs = prefabs or {}
        table.insert(prefabs, def.fx)
    end
    if def.fxmount ~= nil then
        prefabs = prefabs or {}
        table.insert(prefabs, def.fxmount)
    end
    if def.fx_over ~= nil then
        prefabs = prefabs or {}
        local fx_over_prefab = "fx_" .. def.fx_over .. "_over_book"
        table.insert(prefabs, fx_over_prefab)
        table.insert(prefabs, fx_over_prefab .. "_mount")
    end
    if def.fx_under ~= nil then
        prefabs = prefabs or {}
        local fx_under_prefab = "fx_" .. def.fx_under .. "_under_book"
        table.insert(prefabs, fx_under_prefab)
        table.insert(prefabs, fx_under_prefab .. "_mount")
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("books")
        inst.AnimState:SetBuild("mb_books")
        inst.AnimState:PlayAnimation(def.resname or def.name)

        MakeInventoryFloatable(inst, "med", nil, 0.75)

        if def.range then
            inst.cast_scope = def.range
        end

        if TUNING.MB_RECOVERABLE then
            inst:AddTag("book") -- 有这个TAG才能恢复耐久，去除就不能恢复耐久
        end
        inst:AddTag("bookcabinet_item")

        -- 标记为可升级
        if def.can_upgrade then
            inst:AddTag("canupgrade")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------

        inst.def = def
        inst.swap_build = "swap_books"
        inst.swap_prefix = def.resname or def.name

        inst:AddComponent("inspectable")
        inst:AddComponent("book")
        inst.components.book:SetOnRead(def.fn)
        inst.components.book:SetOnPeruse(def.perusefn)
        inst.components.book:SetReadSanity(def.read_sanity or -TUNING.SANITY_HUGE)
        inst.components.book:SetPeruseSanity(def.peruse_sanity or (-TUNING.SANITY_HUGE - TUNING.SANITY_MEDLARGE))
        inst.components.book:SetFx(def.fx, def.fxmount)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. (def.resname or def.name) .. ".xml"

        if (type(def.uses) == "number" and def.uses > 0) or type(def.uses) == "nil" then
            inst:AddComponent("finiteuses")
            inst.components.finiteuses:SetMaxUses(def.uses or TUNING.MB_NUM_USES)
            inst.components.finiteuses:SetUses(def.uses or TUNING.MB_NUM_USES)
            inst.components.finiteuses:SetOnFinished(inst.Remove)
        end

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.MED_FUEL

        inst:AddComponent("named")

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)

        if def.onhaunt then
            inst:AddComponent("hauntable")
            inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_MEDIUM
            inst.components.hauntable:SetOnHauntFn(def.onhaunt)
        else
            MakeHauntableLaunch(inst)
        end

        return inst
    end

    return Prefab(def.name, fn, assets, prefabs)
end

local function MakeFX(name, anim, ismount)
    if ismount then
        name = name .. "_mount"
        anim = anim .. "_mount"
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddFollower()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        if ismount then
            inst.Transform:SetSixFaced()  --match mounted player
        else
            inst.Transform:SetFourFaced() --match player
        end

        inst.AnimState:SetBank("fx_books")
        inst.AnimState:SetBuild("fx_books")
        inst.AnimState:PlayAnimation(anim)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:ListenForEvent("animover", inst.Remove)
        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets_fx)
end

local ret = {}
for i, v in ipairs(book_defs) do
    table.insert(ret, MakeBook(v))
    if v.fx_over ~= nil then
        v.fx_over_prefab = "fx_" .. v.fx_over .. "_over_book"
        table.insert(ret, MakeFX(v.fx_over_prefab, v.fx_over, false))
        table.insert(ret, MakeFX(v.fx_over_prefab, v.fx_over, true))
    end
    if v.fx_under ~= nil then
        v.fx_under_prefab = "fx_" .. v.fx_under .. "_under_book"
        table.insert(ret, MakeFX(v.fx_under_prefab, v.fx_under, false))
        table.insert(ret, MakeFX(v.fx_under_prefab, v.fx_under, true))
    end
end
book_defs = nil
return unpack(ret)
