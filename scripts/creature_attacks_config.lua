-- 生物特殊攻击配置文件
-- 此文件包含所有需要特殊攻击方式的生物配置
-- 配置格式: [生物prefab名] = {event = "事件名", state = "状态名", description = "描述"}

-- 使用全局变量方式，确保可以被 modmain.lua 访问
GLOBAL.SPECIAL_ATTACKS_CONFIG = {
	-- ========== 恐怖之眼系列（冲撞攻击） ==========
	["eyeofterror"] = {event = "charge", description = "恐怖之眼 - 冲撞攻击"},
	["eyeofterror_mini"] = {event = "charge", description = "小恐怖之眼 - 冲撞攻击"},
	["eyeofterror_mini_grounded"] = {event = "charge", description = "小恐怖之眼(地面) - 冲撞攻击"},
	["twinofterror1"] = {event = "charge", description = "恐怖双子1 - 冲撞攻击"},
	["twinofterror2"] = {event = "charge", description = "恐怖双子2 - 冲撞攻击"},
	
	-- ========== 鲨鱼系列 ==========
	["sharkboi"] = {event = "doattack", description = "鲨鱼王 - 特殊攻击"},
	["shark"] = {event = "doattack", state = "attack", description = "鲨鱼"},
	
	-- ========== 暗影仆从系列 ==========
	["shadowthrall_horns"] = {event = "doattack", description = "暗影仆从-角"},
	["shadowthrall_hands"] = {event = "doattack", description = "暗影仆从-手"},
	["shadowthrall_wings"] = {event = "doattack", description = "暗影仆从-翅膀（投掷物攻击）"},
	["shadowthrall_mouth"] = {event = "doattack", description = "暗影仆从-嘴"},
	["fused_shadeling"] = {event = "doattack", description = "融合暗影"},
	["fused_shadeling_bomb"] = {event = "doattack", description = "融合暗影炸弹"},
	["shadowprotector"] = {event = "doattack", description = "暗影保护者"},
	
	-- ========== 四季Boss ==========
	["bearger"] = {event = "doattack", state = "pound", description = "熊獾 - 砸地攻击"},
	["mutatedbearger"] = {event = "doattack", state = "pound", description = "变异熊獾 - 砸地攻击"},
	["deerclops"] = {event = "doattack", state = "attack", description = "独眼巨鹿"},
	["mutateddeerclops"] = {event = "doattack", state = "attack", description = "变异独眼巨鹿"},
	["moose"] = {event = "charge", state = "attack", description = "麋鹿鹅 - 冲撞攻击"},
	["dragonfly"] = {event = "doattack", state = "attack", description = "龙蝇"},
	
	-- ========== 洞穴Boss ==========
	["beequeen"] = {event = "doattack", state = "attack", description = "蜂王"},
	["klaus"] = {event = "doattack", state = "attack", description = "克劳斯"},
	["stalker"] = {event = "doattack", state = "attack", description = "远古织影者"},
	["stalker_atrium"] = {event = "doattack", state = "attack", description = "远古织影者(洞穴)"},
	["stalker_forest"] = {event = "doattack", state = "attack", description = "远古织影者(森林)"},
	["toadstool"] = {event = "doattack", state = "attack", description = "蘑菇蟾蜍"},
	["toadstool_dark"] = {event = "doattack", state = "attack", description = "悲惨蘑菇蟾蜍"},
	["minotaur"] = {event = "charge", state = "attack", description = "远古犀牛 - 冲撞攻击"},
	["ancient_hulk"] = {event = "doattack", state = "attack", description = "远古巨人"},
	["antlion"] = {event = "doattack", state = "attack", description = "蚁狮 - 召唤地刺攻击"},
	["wagboss_robot"] = {event = "doattack", state = "attack", description = "机器人WAG Boss"},
	
	-- ========== 海洋Boss ==========
	["malbatross"] = {event = "doattack", state = "attack", description = "海鸟"},
	["crabking"] = {event = "doattack", state = "attack", description = "蟹王"},
	["crabking_mob_knight"] = {event = "doattack", state = "attack", description = "蟹王骑士"},
	
	-- ========== 天体英雄 ==========
	["alterguardian_phase1"] = {event = "doattack", state = "attack", description = "天体英雄阶段1"},
	["alterguardian_phase1_lunarrift"] = {event = "doattack", state = "attack", description = "天体英雄阶段1(月裂)"},
	["alterguardian_phase2"] = {event = "doattack", state = "attack", description = "天体英雄阶段2"},
	["alterguardian_phase3"] = {event = "doattack", state = "attack", description = "天体英雄阶段3"},
	["alterguardian_phase4_lunarrift"] = {event = "doattack", state = "attack", description = "天体英雄阶段4(月裂)"},
	
	-- ========== 发条系列 ==========
	["knight"] = {event = "charge", state = "attack", description = "发条骑士 - 冲撞攻击"},
	["knight_nightmare"] = {event = "charge", state = "attack", description = "梦魇骑士 - 冲撞攻击"},
	["bishop"] = {event = "doattack", state = "shoot", description = "发条主教 - 激光攻击"},
	["bishop_nightmare"] = {event = "doattack", state = "shoot", description = "梦魇主教 - 激光攻击"},
	["rook"] = {event = "charge", state = "attack", description = "发条战车 - 冲撞攻击"},
	["rook_nightmare"] = {event = "charge", state = "attack", description = "梦魇战车 - 冲撞攻击"},
	
	-- ========== 暗影棋子 ==========
	["shadow_knight"] = {event = "charge", state = "attack", description = "暗影骑士 - 冲撞攻击"},
	["shadow_bishop"] = {event = "doattack", state = "shoot", description = "暗影主教 - 激光攻击"},
	["shadow_rook"] = {event = "doattack", state = "attack", description = "暗影战车 - 连续闪现啃咬"},
	
	-- ========== 座狼系列 ==========
	["warg"] = {event = "doattack", state = "howl", description = "座狼 - 召唤攻击"},
	["claywarg"] = {event = "doattack", state = "howl", description = "粘土座狼 - 召唤攻击"},
	["mutatedwarg"] = {event = "doattack", state = "howl", description = "变异座狼 - 召唤攻击"},
	["gingerbreadwarg"] = {event = "doattack", state = "howl", description = "姜饼座狼 - 召唤攻击"},
	["warglet"] = {event = "doattack", state = "attack", description = "小座狼"},
	
	-- ========== 树精守卫 ==========
	["leif"] = {event = "doattack", state = "attack", description = "树精守卫"},
	["leif_sparse"] = {event = "doattack", state = "attack", description = "树精守卫(稀疏)"},
	
	-- ========== 蜘蛛女王 ==========
	["spiderqueen"] = {event = "doattack", state = "attack", description = "蜘蛛女王"},
	
	-- ========== 钢羊 ==========
	["spat"] = {event = "spit", state = "attack", description = "钢羊 - 吐射攻击"},
	
	-- ========== 暴怒坎普斯（模组） ==========
	["medal_rage_krampus"] = {event = "doattack", state = "attack", description = "暴怒坎普斯"},
	
	-- ========== 神话书说（模组） ==========
	["myth_goldfrog"] = {event = "doattack", state = "attack", description = "金蟾"},
	["blackbear"] = {event = "doattack", state = "attack", description = "黑熊"},
	["rhino3_blue"] = {event = "charge", state = "attack", description = "蓝犀牛 - 冲撞攻击"},
	["rhino3_red"] = {event = "charge", state = "attack", description = "红犀牛 - 冲撞攻击"},
	["rhino3_yellow"] = {event = "charge", state = "attack", description = "黄犀牛 - 冲撞攻击"},
	
	-- ========== 暗影生物 ==========
	["crawlinghorror"] = {event = "doattack", state = "attack", description = "爬行恐惧"},
	["terrorbeak"] = {event = "doattack", state = "attack", description = "恐怖之喙"},
	
	-- ========== 日行者 ==========
	["daywalker"] = {event = "doattack", state = "attack", description = "日行者"},
	["daywalker2"] = {event = "doattack", state = "attack", description = "日行者2"},
	
	-- ========== 兔王 ==========
	["rabbitking_aggressive"] = {event = "doattack", state = "attack", description = "暴怒兔王"},
	
	-- ========== 果蝇领主 ==========
	["lordfruitfly"] = {event = "doattack", state = "attack", description = "果蝇领主"},
	
	-- ========== 洞穴蠕虫 ==========
	["worm"] = {event = "emerge", state = "attack", description = "洞穴蠕虫 - 钻出攻击"},
	["yots_worm"] = {event = "emerge", state = "attack", description = "年兽蠕虫 - 钻出攻击"},
	
	-- ========== 月岛生物 ==========
	["fruitdragon"] = {event = "doattack", state = "attack", description = "沙拉蝾螈"},
	["gestalt"] = {event = "doattack", state = "attack", description = "格斯特"},
	["gestalt_guard_evolved"] = {event = "doattack", state = "attack", description = "进化格斯特守卫"},
	
	-- ========== 一角鲸 ==========
	["gnarwail"] = {event = "charge", state = "attack", description = "一角鲸 - 冲撞攻击"},
	
	-- ========== 洞穴生物 ==========
	["bat"] = {event = "doattack", state = "attack", description = "蝙蝠"},
	["slurper"] = {event = "doattack", state = "attack", description = "啜食兽"},
	
	-- ========== 远古档案馆 ==========
	["archive_centipede"] = {event = "doattack", state = "attack", description = "远古蜈蚣"},
	
	-- ========== 月岛人鱼 ==========
	["merm_lunar"] = {event = "doattack", state = "attack", description = "月岛人鱼"},
	["mermguard_lunar"] = {event = "doattack", state = "attack", description = "月岛人鱼守卫"},
	["mermguard_shadow"] = {event = "doattack", state = "attack", description = "暗影人鱼守卫"},
	
	-- ========== 噩梦生物 ==========
	["ruinsnightmare"] = {event = "doattack", state = "attack", description = "遗迹噩梦"},
	
	-- ========== 草鳄 ==========
	["grassgator"] = {event = "doattack", state = "attack", description = "草鳄"},
	
	-- ========== 猴子海盗 ==========
	["powder_monkey"] = {event = "doattack", state = "attack", description = "火药猴"},
	["prime_mate"] = {event = "doattack", state = "attack", description = "大副猴"},
	
	-- ========== 其他特殊生物 ==========
	["mutatedbuzzard_gestalt"] = {event = "doattack", state = "attack", description = "变异秃鹫格斯特"},
	["cave_vent_mite"] = {event = "doattack", state = "attack", description = "洞穴通风口螨虫"},
	["ticoon"] = {event = "doattack", state = "attack", description = "浣熊"},
	["clayhound"] = {event = "doattack", state = "attack", description = "粘土猎犬"},

	-- ========== 噩梦模式自定义生物 ==========
	["shadowdragon"] = {event = "doattack", state = "attack", description = "恐惧之龙"},
	["shadoweyeturret"] = {event = "doattack", state = "attack", description = "眼球哨兵"},
	["shadoweyeturret2"] = {event = "doattack", state = "attack", description = "眼球哨兵（强化）"},
	["spider_robot"] = {event = "doattack", description = "遗迹守卫 - 激光"},
	["mandrakeman"] = {event = "doattack", state = "attack", description = "曼德拉战士"},
	["ironlord"] = {event = "doattack", state = "attack", description = "附身铠甲"},
	["king_squid"] = {event = "doattack", state = "attack", description = "鱿王"},
	["pigelitefighter1"] = {event = "doattack", state = "attack", description = "精英猪人举牌组"},
	["pigelitefighter2"] = {event = "doattack", state = "attack", description = "精英猪人举牌组"},
	["pigelitefighter3"] = {event = "doattack", state = "attack", description = "精英猪人举牌组"},
	["pigelitefighter4"] = {event = "doattack", state = "attack", description = "精英猪人举牌组"},
	["shadow_bishop"] = {event = "doattack", state = "shoot", description = "暗影主教（模组）"},
	
	-- 注意：以下生物使用普通攻击即可，不需要特殊配置
	-- pigman, spider_*, firehound, icehound, merm, slurtle, penguin, pigguard, 
	-- mutatedhound, koalefant_*, squid, molebat, beefalo, bunnyman, tallbird, 
	-- monkey, rocky, krampus, deer, snurtle, tentacle, mutated_penguin, 
	-- mushgnome, lightninggoat, mermguard, mossling, walrus, little_walrus,
	-- oceanfish_*, wobster_*, smallghost 等普通生物
}
