GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

GLOBAL.MOD_VERSION = "4.6.3.1"

local require = GLOBAL.require

GLOBAL.ISP = {
	ENV      = ENV,
	MODNAME  = modname,
	RPC_NAME = modname .. "_rpc",
}

ISP = GLOBAL.ISP

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
	"hitsparks_fx",
	"mandrakehouse",
	"dumbbells",
	"lunarthrall_plant",
	"wortox_soul_heal_fx",
	"wortox_soul_in_fx",
	"wortox_soul_spawn",
	"wortox_soul",
	"pocketwatch_injure",

	-- 天体相关
	"lava_sinkhole",
	"firerain_cs",
	"twin_flame",

	-- 尼个加强相关
	"newammo",
	"newfx",
	"lunarplantfx",
}

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
	Asset("SOUND", "sound/lumos.fsb"),
	Asset("SOUNDPACKAGE", "sound/lumos.fev"),
}

modimport("strings.lua")

------------ 插入脚本 --------------
local function load_if_enabled(name, path)
	if GetModConfigData(name) then
		modimport(path)
	end
end

-- mod基础配置
modimport("postinit/gps.lua")                --全球定位
modimport("postinit/jinggao.lua")            --警告
modimport("postinit/console.lua")            --禁止控制台
modimport("postinit/jiazai.lua")             --加载提示
modimport("postinit/standardcomponents.lua") --前置功能

load_if_enabled('peifang', "postinit/peifang.lua")
load_if_enabled('diaoluo', "postinit/diaoluo.lua")
load_if_enabled('jiaqiang', "postinit/jiaqiang.lua")
load_if_enabled('electrocute', "postinit/electrocute.lua")
load_if_enabled('curse', "postinit/curse.lua")

if GetModConfigData("word") then
	LoadPOFile("language/pigman.po", "ch")
end

-- boss相关
modimport("postinit/truedamage_system.lua")
modimport("postinit/ironlord_spawner.lua") --附身铠甲

if GetModConfigData("boss") then
	modimport("postinit/alterguardian.lua") --天体加强
	modimport("postinit/moose.lua")      --春鹅
	modimport("postinit/beequeen.lua")   --蜂后
	modimport("postinit/dragonfly.lua")  --龙蝇
	modimport("postinit/yishi.lua")      --蚁狮刷新
	modimport("postinit/stalker.lua")    --织影者加强
	modimport("postinit/minotaur.lua")   --界犀牛
	modimport("postinit/klaus.lua")      --克老师
	modimport("postinit/deerclops.lua")  --巨鹿
	modimport("postinit/shadowmachine.lua") --远古发条怪加强
end

-- 人物相关
modimport("postinit/wortox.lua")
load_if_enabled('wanda', "postinit/wanda.lua")
load_if_enabled('wendy', "postinit/wendy.lua")
load_if_enabled('wolfgang', "postinit/wolfgang.lua")
load_if_enabled('wigfrid', "postinit/wigfrid.lua")
load_if_enabled('wormwood', "postinit/wormwood.lua")
load_if_enabled('waxwell', "postinit/waxwell.lua")
load_if_enabled('wickerbottom', "postinit/wickerbottom.lua")
load_if_enabled('walter', "postinit/walter.lua")
load_if_enabled('warly', "postinit/warly.lua")
load_if_enabled('woodie', "postinit/woodie.lua")
load_if_enabled('wes', "postinit/wes.lua")
load_if_enabled('wx78', "postinit/wx78.lua")
load_if_enabled('wilson', "postinit/wilson.lua")
load_if_enabled('willow', "postinit/willow.lua")
load_if_enabled('winona', "postinit/winona.lua")
if GetModConfigData("wurt") then
	RemoveDefaultCharacter("wurt")
end
if GetModConfigData("webber") then
	RemoveDefaultCharacter("webber")
end

-- 生活质量
load_if_enabled('raterate', "postinit/raterate.lua")
load_if_enabled('alterguardianhat', "postinit/alterguardianhat.lua")
load_if_enabled('zuowu', "postinit/zuowu.lua")
load_if_enabled('ruins_equip', "postinit/ruins_equip.lua")
load_if_enabled('stage', "postinit/stage.lua")
load_if_enabled('cookpot', "postinit/cookpot.lua")
load_if_enabled('sleep', "postinit/sleep.lua")
if GetModConfigData("shadow_container") then
	modimport("scripts/api.lua")
	modimport("scripts/extensions/shadow_container.lua")
end
