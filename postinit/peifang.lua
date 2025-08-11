--额外装备
env.STRINGS = GLOBAL.STRINGS
env.TECH = GLOBAL.TECH

-- 物品分类
-- CHARACTER   人物物品
-- TOOLS       工具
-- LIGHT       照明
-- PROTOTYPERS 原型（一本二本这些）
-- REFINE      精炼物品
-- WEAPONS     武器
-- ARMOUR      防具
-- CLOTHING    衣物
-- RESTORATION 恢复生命
-- MAGIC       魔法物品
-- DECOR       装饰
-- STRUCTURES  建筑
-- CONTAINERS  容器
-- COOKING     烹饪
-- GARDENING   园艺
-- FISHING     钓鱼
-- SEAFARING   航海
-- RIDING      骑牛
-- WINTER      冬天
-- SUMMER      夏天
-- RAIN        雨具


--暗影回旋镖
AddRecipePostInit("voidcloth_boomerang", function(self)
    table.insert(self.ingredients, Ingredient("shadowheart", 1))
end)

--纯粹恐惧"
AddRecipe2("horrorfuel", { Ingredient("nightmarefuel", 5) }, TECH.NONE_TWO, nil, { "REFINE" })

--暗影碎布"
AddRecipe2("voidcloth", { Ingredient("horrorfuel", 3) }, TECH.NONE_TWO, nil, { "REFINE" })

--纯粹辉煌
AddRecipe2("purebrilliance", { Ingredient("moonglass", 2), Ingredient("moonrocknugget", 2) }, TECH.NONE_TWO, nil,
    { "REFINE" })

--钢丝毛
AddRecipe2("steelwool", { Ingredient("manrabbit_tail", 3), Ingredient("beefalowool", 3) }, TECH.NONE_TWO, nil,
    { "REFINE" })

--鹿角
AddRecipe2("deer_antler1", { Ingredient("lightninggoathorn", 1), Ingredient("moonrocknugget", 2) }, TECH.NONE_TWO, nil,
    { "REFINE" })

--种子包
AddRecipe2("yotc_seedpacket", { Ingredient("cutgrass", 5), Ingredient("twigs", 5) }, TECH.NONE_TWO, nil,
    { product = "yotc_seedpacket" }, { "GARDENING" })

-- --高级种子包
-- AddRecipe2("yotc_seedpacket_rare", { Ingredient("flint", 5), Ingredient("nitre", 3) }, TECH.NONE_TWO, nil,
--     { product = "yotc_seedpacket" }, { "GARDENING" })

--珍珠
AddRecipe2("hermit_pearl",
    { Ingredient("coin_1", 7), Ingredient("security_pulse_cage_full", 1), Ingredient("orangegem", 5), Ingredient(
        "moonrocknugget", 10) },
    TECH.NONE_TWO, {}, { "NONE" })
STRINGS.RECIPE_DESC.HERMIT_PEARL = "勇者的证明"

--启迪碎片
AddRecipe2("alterguardianhatshard",
    { Ingredient("pickaxe_lunarplant", 0), Ingredient("purebrilliance", 2), Ingredient("lunarplant_husk", 2) },
    TECH.NONE_TWO, nil, { "NONE" })

--活性黑心
AddRecipe2("shadowheart_infused",
    { Ingredient("voidcloth_scythe", 0), Ingredient("reviver", 5), Ingredient("coin_1", 1), Ingredient("horrorfuel", 10) },
    TECH.NONE_TWO, nil, { "NONE" })

--启迪头
AddRecipe2("alterguardianhat",
    { Ingredient("lunarplanthat", 1), Ingredient("coin_1", 1), Ingredient("opalpreciousgem", 1) },
    TECH.NONE_TWO, nil, { "ARMOUR" })

--自动修理机
AddRecipe2("wagpunkbits_kit", { Ingredient("wagpunk_bits", 2), Ingredient("transistor", 2) }, TECH.NONE_TWO, nil,
    { "NONE" })

--收获时刻
AddRecipe2("book_harvest",
    { Ingredient("livinglog", 3), Ingredient("papyrus", 3), Ingredient("nightmarefuel", 5), Ingredient("coin_1", 1) },
    TECH.NONE_TWO,
    { atlas = "images/inventoryimages/book_harvest.xml", images = "book_harvest.tex", builder_tag = "bookbuilder" },
    { "CHARACTER" })
STRINGS.NAMES.BOOK_HARVEST = "收获的时刻"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_HARVEST = "解放双手的魔法"
STRINGS.RECIPE_DESC.BOOK_HARVEST = "作物都自己跑到身上来"

--骨甲
local armorskeleton_ingredients = { Ingredient("coin_1", 1), Ingredient("armor_sanity", 1), Ingredient("voidcloth", 3) }
AddRecipe2("armorskeleton", armorskeleton_ingredients, TECH.LOST, { nounlock = false }, { "ARMOUR" })

--鸟嘴壶"
AddRecipe2("premiumwateringcan",
    { Ingredient("livinglog", 2), Ingredient("rope", 4), Ingredient("boneshard", 4), Ingredient("bluegem", 1) },
    TECH.NONE_TWO, nil, { "GARDENING" })

--荆棘茄甲
AddRecipe2("armor_lunarplant_husk",
    { Ingredient("armor_bramble", 1), Ingredient("moonglass", 8), Ingredient("purebrilliance", 2) }, TECH.NONE_TWO,
    { builder_tag = "plantkin", builder_skill = "wormwood_allegiance_lunar_plant_gear_1" },
    { "CHARACTER" })

-- 远古粑粑包
AddRecipe2("transmute_compostwrap", { Ingredient("cave_banana",
        3), Ingredient("cutlichen", 2), Ingredient("thulecite_pieces", 2) }, TECH.ANCIENT_FOUR,
    { product = "compostwrap", image = "compostwrap.tex", description = "transmute_compostwarp", builder_tag = "plantkin", nounlock = true },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.TRANSMUTE_COMPOSTWRAP = "远古秘制老八，九九八十一天发酵"

-- 小飞虫血量调整
AddRecipe2("wormwood_lightflier", { Ingredient(CHARACTER_INGREDIENT.HEALTH, 5), Ingredient("lightbulb", 1) }, TECH.NONE,
    {
        builder_skill = "wormwood_allegiance_lunar_mutations_2",
        product = "wormwood_mutantproxy_lightflier",
        sg_state =
        "spawn_mutated_creature",
        actionstr = "TRANSFORM",
        no_deconstruction = true,
        dropitem = true,
        nameoverride =
        "lightflier",
        description = "wormwood_lightflier",
        canbuild = function(inst, builder)
            return
                (builder.components.petleash and not builder.components.petleash:IsFullForPrefab("wormwood_lightflier")),
                "HASPET"
        end
    }, { "CHARACTER" })

-- 批量莎草纸
GLOBAL.TUNING.STQKACT = true

AddRecipe2("papyrus_bunch", { Ingredient("cutreeds", 40) }, TECH.CARPENTRY_THREE,
    {
        nounlock = true,
        sg_state = "give",
        product = "papyrus",
        image = "papyrus.tex",
        description = "papyrus_bunch",
        numtogive = 10,
        no_deconstruction = true,
        station_tag = "carpentry_station",
        canbuild = function(recipe, builder, pt, rotation, station)
            return station == nil
                or (GLOBAL.TUNING.STQKACT == false and not station.AnimState:IsCurrentAnimation("use"))
                or GLOBAL.TUNING.STQKACT,
                "BUSY_STATION"
        end
    })
STRINGS.RECIPE_DESC.PAPYRUS_BUNCH = "一打纸"


-- 批量腐烂物
AddRecipe2("spoiled_food_bunch",
    { Ingredient("twigs", 20), Ingredient("cutgrass", 20), Ingredient("rock_avocado_fruit_ripe", 15) },
    TECH.CARPENTRY_TWO,
    {
        nounlock = true,
        sg_state = "give",
        product = "spoiled_food",
        image = "spoiled_food.tex",
        description = "spoiled_food_bunch",
        numtogive = 30,
        no_deconstruction = true,
        station_tag = "carpentry_station",
        canbuild = function(recipe, builder, pt, rotation, station)
            return station == nil
                or (GLOBAL.TUNING.STQKACT == false and not station.AnimState:IsCurrentAnimation("use"))
                or GLOBAL.TUNING.STQKACT,
                "BUSY_STATION"
        end
    })
STRINGS.RECIPE_DESC.SPOILED_FOOD_BUNCH = "人人都可以是腐烂仙人！"

-- 晾肉架配方调整
-- Recipe2("meatrack", { Ingredient("twigs", 5), Ingredient("charcoal", 3), Ingredient("rope", 1) }, TECH.SCIENCE_ONE,
--     { placer = "meatrack_placer" }, { "COOKING" })

--铥棒修改
AddRecipePostInit("ruins_bat", function(self)
    self.image = "lavaarena_heavyblade.tex"
    self.ingredients[2].amount = 5
end)

-- 枕头
AddRecipe2("handpillow_steelwool",
    { Ingredient("panflute", 1), Ingredient("rabbit", 4) },
    TECH.RABBITKINGSHOP_TWO, { nounlock = true, sg_state = "give", product = "handpillow_steelwool" })

--附身铠甲召唤
CONSTRUCTION_PLANS["ironlord_death"] = { Ingredient("thurible", 1) }


-- AddRecipe2("armor_sanity_butch",
--     { Ingredient("nightmarefuel", 40), Ingredient("papyrus", 24) },
--     TECH.LOST,
--     {
--         product = "armor_sanity",
--         image = "armor_sanity.tex",
--         description = "armor_sanity_bunch",
--         numtogive = 8,
--     })
-- STRINGS.NAMES.ARMOR_SANITY_BUTCH = "批量影甲，懂吗"
-- STRINGS.RECIPE_DESC.ARMOR_SANITY_BUTCH = "成为伟大的影甲仙人吧！"

AddRecipe2("brainjellyhat",
    { Ingredient("brain_coral", 1), Ingredient("voidcloth", 5) },
    TECH.LOST,
    {
        atlas = "images/inventoryimages/brainjellyhat.xml",
        images = "brainjellyhat.tex",
        description = "brainjellyhat",
    })
STRINGS.RECIPE_DESC.BRAINJELLYHAT = "戴上它能够让你更加聪明！"

-- 羽毛笔双配方
AddRecipe2("featherpencil2",
    { Ingredient("twigs", 1), Ingredient("charcoal", 1), Ingredient("feather_robin", 1) }, TECH.SCIENCE_ONE,
    {
        product = "featherpencil",
        image = "featherpencil.tex",
        description =
        "featherpencil2",
        builder_tag = "writer"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.BATTLESONG_FIRERESISTANCE2 = "或许还有另一种笔的配方"

--空间压缩道具
AddRecipe2("chestupgrade_stacksize",
    { Ingredient("wagpunk_bits", 5), Ingredient("transistor", 4), Ingredient("goldnugget", 8) },
    TECH.NONE_TWO, nil, { "NONE" })

--哀悼荣耀"
AddRecipe2("ghostflower", { Ingredient("moon_cap", 1), Ingredient("moonglass", 1) }, TECH.NONE_TWO, nil, { "REFINE" })

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

-- --养蜂笔记
-- AddRecipe2("book_bees",
--     { Ingredient("papyrus", 2), Ingredient("slurper_pelt", 4), Ingredient("fossil_piece", 2), Ingredient(
--         "slurtle_shellpieces", 3) }, nil,
--     { builder_tag = "bookbuilder" }, { "CHARACTER" })

-- 养蜂笔记修复
AddRecipe2("book_bees2",
    { Ingredient("papyrus", 2), Ingredient("slurper_pelt", 4), Ingredient("fossil_piece", 2), Ingredient(
        "slurtle_shellpieces", 3) }, TECH.NONE_TWO,
    {
        product = "book_bees",
        image = "book_bees.tex",
        description =
        "book_bees2",
        builder_tag = "bookbuilder"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.BOOK_BEES2 = "使用噩梦燃料来滋补这些饥饿的蜂群"

--余烬
AddRecipe2("willow_ember",
    { Ingredient("lighter", 0), Ingredient("ash", 5), Ingredient("willow_ember", 1) },
    TECH.SCIENCE_ONE,
    {
        numtogive = 6,

    })
--统帅头
Recipe2("wathgrithr_improvedhat",
    { Ingredient("thulecite_pieces", 6), Ingredient("wathgrithrhat", 1), Ingredient("rocks", 4) }, TECH.NONE_TWO,
    { builder_tag = "valkyrie" }, { "CHARACTER" })
--冰哑铃
AddRecipe2("dumbbell_bluegem", { Ingredient("dumbbell_redgem", 1), Ingredient("bluegem", 1), Ingredient("thulecite", 2) },
    TECH.NONE,
    { builder_skill = "wolfgang_dumbbell_crafting" }, { "CHARACTER" })
--月晷
AddRecipe2("moondial",
    { Ingredient("abigail_flower", 1), Ingredient("reskin_tool", 1) }, TECH.NONE_TWO,
    {
        product = "moondial",
        image = "moondial.tex",
        description =
        "moondial2",
        builder_tag = "ghostlyfriend"
    },
    { "CHARACTER" })
STRINGS.RECIPE_DESC.MOONDIAL2 = "给下地温玩月亮阿比的"

--光之怒
Recipe2("ghostlyelixir_lunar",
    { Ingredient("thulecite_pieces", 6), Ingredient("purebrilliance", 2), Ingredient("ghostflower", 5) }, TECH.NONE_TWO,
    { builder_tag = "ghostlyfriend" }, { "CHARACTER" })


local function livinglog_numtogive(recipe, doer)
    local total = 1
    if math.random() < 0.4 then
        total = total + 1
    end
    if math.random() < 0.1 then
        total = total + 1
    end
    if total > 2 then
        doer.SoundEmitter:PlaySound("meta5/wendy/elixir_bonus_2")
        doer.components.talker:Say("更多的朋友给更好的朋友！")
    elseif total > 1 then
        doer.SoundEmitter:PlaySound("meta5/wendy/elixir_bonus_1")
        doer.components.talker:Say("更多的朋友给更好的朋友！")
    end
    return total
end

Recipe2("livinglog",
    { Ingredient(CHARACTER_INGREDIENT.HEALTH, 20) },
    TECH.NONE,
    {
        builder_tag = "plantkin",
        sg_state = "form_log",
        actionstr = "GROW",
        allowautopick = true,
        no_deconstruction = true,
        override_numtogive_fn = livinglog_numtogive
    }
)
