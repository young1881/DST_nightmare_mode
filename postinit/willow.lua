TUNING.WILLOW_EMBER_LUNAR = 3                  --月火费用
TUNING.WILLOW_FIREFRENZY_MULT = 1.75           --燃烧斗士伤害提高百分之二十五
TUNING.WILLOW_LUNAR_FIRE_BONUS = 1.25          --月火增伤百分之25
TUNING.WILLOW_LUNAR_FIRE_TIME = 5.0            --月火持续时间
TUNING.WILLOW_LUNAR_FIRE_DAMAGE = 8            --月火的伤害
TUNING.WILLOW_LUNAR_FIRE_PLANAR_DAMAGE = 48    --月火的位面伤害
TUNING.WILLOW_LUNAR_FIRE_COOLDOWN = 5.0        --月火cd
TUNING.CHANNELCAST_SPEED_MOD = 90 / 100        --放月火时的移速
TUNING.WILLOW_BERNIE_HEALTH_REGEN_PERIOD = 1.5 --伯尼回血判定时间
TUNING.WILLOW_BERNIE_HEALTH_REGEN_1 = 400      --伯尼一级回血每秒回4
TUNING.WILLOW_BERNIE_HEALTH_REGEN_2 = 800      --伯尼二级回血每秒回8


--余烬
AddRecipe2("willow_ember",
    { Ingredient("lighter", 0), Ingredient("ash", 5), Ingredient("willow_ember", 1) },
    TECH.SCIENCE_ONE,
    {
        numtogive = 6,
        builder_tag = "bernieowner",
    }, { "CHARACTER" })
