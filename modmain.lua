GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
PrefabFiles = {
	"globalposition_classified",
	"globalmapicon_noproxy", --GPS
	"coin_1",             --证明
	"ancient_robots",
	"ancient_hulk",       --铁巨人
	"book_harvest",       --收获之书
	"laser_spark",
	"laser_ring",
	"laser",        --几个技能特效
	"alterguardian_laser",
	"freeze_blast", --冰
	"shadowflame",  --暗影火
	"shadowdragon", --恐惧志龙
	"shadowwave",   --浪
	"ancient_scanner", --暗影侦察者
	"scanner_spawn", --暗影侦察者生成
	"wormwood_seeds", --识别的种子
	"leechterror",  --附身暗影
	"ironlord",     --附身铠甲
	"ancient_robots", --遗迹守卫
	"alter_light",
	"sword_ancient", --永恒之锋图像
	"constant_proj",
	"constant_star",
	"clock_container", --钟表盒
	"wd_projectilefx", --吴迪的特效
	"klaus_soul",
	"ruinseyeturret", --眼球哨兵
	"mandrakeman",
	"dragonfurnace_projectile",
	"fireover",
	"pocketwatch_cherrift",
	"range_widget",
	"brainjellyhat",
	"mb_books",
	"brain_coral",
	"wx78_electricattack",
	"living_artifact",
	"wx78_scanner",
	"wx78_modules",
	"wx78",
	"hitsparks_fx",
	"mandrakehouse",
	"dumbbells",
	"lunarthrall_plant",
	"wortox_soul_heal_fx",
	"wortox_soul_in_fx",
	"wortox_soul_spawn",
	"wortox_soul",

	-- 天体相关
	"lava_sinkhole",
	"firerain_cs",
	"twin_flame",

	-- 尼个加强相关
	"newammo",
	"newfx",
	"lunarplantfx",
}

local require = GLOBAL.require

GLOBAL.ISP = {
	ENV      = ENV,
	MODNAME  = modname,
	RPC_NAME = modname .. "_rpc",
}

ISP = GLOBAL.ISP

-- 语言包替换
LoadPOFile("language/pigman.po", "ch")

Assets = {
	Asset("SCRIPT", "scripts/wx78_moduledefs.lua"),
	Asset("IMAGE", "images/status_bg.tex"),
	Asset("ATLAS", "images/status_bg.xml"),
	Asset("ATLAS", "images/coin_1.xml"),
	Asset("IMAGE", "images/coin_1.tex"),
	Asset("ANIM", "anim/coin_1.zip"),
	Asset("ANIM", "anim/sword_buster.zip"),
	Asset("ANIM", "anim/swap_sword_buster.zip"),
	Asset("IMAGE", "images/inventoryimages/wormwood_seeds.tex"),
	Asset("ATLAS", "images/inventoryimages/wormwood_seeds.xml"),
	Asset("ATLAS_BUILD", "images/inventoryimages/wormwood_seeds.xml", 256),
	Asset("IMAGE", "images/inventoryimages/clock_container.tex"),
	Asset("ATLAS", "images/inventoryimages/clock_container.xml"),
	Asset("IMAGE", "images/inventoryimages/brainjellyhat.tex"),
	Asset("ATLAS", "images/inventoryimages/brainjellyhat.xml"),
	Asset("ANIM", "anim/brain_coral.zip"),
	Asset("IMAGE", "images/inventoryimages/brain_coral.tex"),
	Asset("ATLAS", "images/inventoryimages/brain_coral.xml"),
	Asset("ANIM", "anim/player_actions_roll.zip"), --附身铠甲动画
}


--禁用蜘蛛人
local ban_character_list = {
	"webber",
	"wurt",
}

STRINGS = GLOBAL.STRINGS

for i, v in ipairs(ban_character_list) do
	RemoveDefaultCharacter(v)
end

--命名
STRINGS.NAMES.ANCIENT_HULK = "远古铁巨人"
STRINGS.NAMES.ANCIENT_SCANNER = "暗影侦察者"
STRINGS.NAMES.SHADOWDRAGON = "恐惧之龙"
STRINGS.NAMES.SHADOWEYETURRET = "残缺的远古眼球哨兵守卫"
STRINGS.NAMES.SHADOWEYETURRET2 = "完整的远古眼球哨兵守卫 "
STRINGS.NAMES.WORMWOOD_SEEDS = "野性种子"
STRINGS.ACTIONS.CASTAOE.RUINS_BAT = "格挡"
STRINGS.NAMES.IRONLORD = "白云"
STRINGS.NAMES.IRONLORD_DEATH = "残骸"
STRINGS.NAMES.SPIDER_ROBOT = "遗迹守卫"

--禁止传送
local function teleport_override_fn(inst)
	local ipos = inst:GetPosition()
	local offset = FindWalkableOffset(ipos, 2 * PI * math.random(), 10, 8, true, false)
		or FindWalkableOffset(ipos, 2 * PI * math.random(), 14, 8, true, false)

	return (offset ~= nil and ipos + offset) or ipos
end
ListOfBoss6 = {
	"klaus",     --克劳斯
	"ancient_hulk", --铁巨人
	"deerclops",
	"mutateddeerclops",
	"stalker_atrium",
	"ironlord"
}
for k, v in pairs(ListOfBoss6) do
	AddPrefabPostInit(v, function(inst)
		if inst.components.teleportedoverride == nil then
			inst:AddComponent("teleportedoverride")
		end
		inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)
	end)
end

------------ 插入脚本 --------------

-- mod基础配置
modimport("postinit/gps.lua")                --全球定位
modimport("postinit/jinggao.lua")            --警告
modimport("postinit/console.lua")            --禁止控制台
modimport("postinit/jiazai.lua")             --加载提示
modimport("postinit/standardcomponents.lua") --前置功能

modimport("postinit/peifang.lua")            --配方
modimport("postinit/diaoluo.lua")            --掉落加强
modimport("postinit/jiaqiang.lua")           --位面加强和相关数值
modimport("postinit/electrocute")            --电击相关改动
modimport("postinit/curse")

-- boss相关
modimport("postinit/truedamage_system.lua")
modimport("postinit/alterguardian.lua")    --天体加强
modimport("postinit/moose.lua")            --春鹅
modimport("postinit/beequeen.lua")         --蜂后
modimport("postinit/dragonfly.lua")        --龙蝇
modimport("postinit/yishi.lua")            --蚁狮刷新
modimport("postinit/stalker.lua")          --织影者加强
modimport("postinit/minotaur.lua")         --界犀牛
modimport("postinit/klaus.lua")            --克老师
modimport("postinit/deerclops.lua")        --巨鹿
modimport("postinit/shadowmachine.lua")    --远古发条怪加强
modimport("postinit/ironlord_spawner.lua") --附身铠甲

-- 人物相关
modimport("postinit/wanda.lua")        --旺达
modimport("postinit/wendy.lua")        --温蒂
modimport("postinit/wolfgang.lua")     --大头
modimport("postinit/wushen.lua")       --女武神
modimport("postinit/zhiwuren.lua")     --植物人
modimport("postinit/waxwell.lua")      --老麦
modimport("postinit/wickerbottom.lua") --奶奶
modimport("postinit/books.lua")        --书籍
modimport("postinit/walter.lua")       --尼个
modimport("postinit/warly.lua")        --厨师
modimport("postinit/woodie.lua")       --伍迪
modimport("postinit/wes.lua")          --维斯
modimport("postinit/wx78.lua")         --机器人
modimport("postinit/wilson.lua")       --vd
modimport("postinit/wortox.lua")

-- 其他
modimport("postinit/raterate.lua")                   --快速训牛
modimport("postinit/alterguardianhat.lua")           --启迪冠
modimport("postinit/zuowu.lua")                      --作物全季节
modimport("postinit/ruins_equip.lua")                --铥棒与铥甲
modimport("postinit/stage.lua")                      --舞台
modimport("scripts/api")
modimport("scripts/extensions/shadow_container.lua") --暗影空间
modimport("postinit/cookpot")                        --烹饪锅
