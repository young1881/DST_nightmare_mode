GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

GLOBAL.MOD_VERSION = "7.1.5.3"

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
	"shadowdragon", --恐惧之龙
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
	"bishop_spawner", --完整发条主教遗迹刷新点
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
	"circleplacer",
	"winona_moving_box",
	"lunar_torch",
	"lunar_torchfire",
	"lunar_torch_projectile",

	-- 天体相关
	"lava_sinkhole",
	"firerain_cs",
	"twin_flame",

	-- 尼个加强相关
	"newammo",
	"newfx",
	"lunarplantfx",
}
--暗影突袭
if TUNING.THE_FORGE_ITEM_PACK == nil then
	TUNING.THE_FORGE_ITEM_PACK = {}
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS = {
		MAX_SHADOW_SPAWN = 6,
		HITS_REQUIRED = 4,
		DAMAGE_MULT = 1.0,
		PLANAR_DAMAGE_MULT = 1.5,
		JOURNAL_FUEL_COST_PERCENT = 0.2,
		JOURNAL_FAIL_ANNOUNCE = "我的暗影力量正在流失...",
		LUNGE_SPEED = 30,
		ENABLED = 0,
	}
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS.HITS_REQUIRED == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS.HITS_REQUIRED = 4
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS.DAMAGE_MULT == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS.DAMAGE_MULT = 1.0
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS.PLANAR_DAMAGE_MULT == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS.PLANAR_DAMAGE_MULT = 1.5
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT = 0.2
end
if TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FAIL_ANNOUNCE == nil then
	TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FAIL_ANNOUNCE = "我的暗影力量正在流失..."
end



Assets = {
	Asset("SCRIPT", "scripts/stategraphs/SGbishop.lua"),
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
	Asset("ANIM", "anim/circleplacer.zip"),
	Asset("ATLAS", "images/inventoryimages/winona_moving_box_item.xml"),
	Asset("IMAGE", "images/inventoryimages/winona_moving_box_item.tex"),
	Asset("IMAGE", "images/inventoryimages/lunar_torch.tex"),
	Asset("ATLAS", "images/inventoryimages/lunar_torch.xml"),
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
modimport("postinit/roge_portal_pull_immunity.lua") --裂缝表吸入不可打断
modimport("postinit/announce.lua")
load_if_enabled("roge", "postinit/roge/init.lua") -- 骰子肉鸽（mod 设置默认开启）
modimport("postinit/ancient_altar_protect.lua") -- 远古科技塔不可摧毁
modimport("scripts/nightmare/passive_shadow_fx.lua")
modimport("scripts/nightmare/king_squid.lua")
modimport("scripts/nightmare/shadow_bishop.lua")
modimport("scripts/nightmare/spider_queen.lua")
modimport("scripts/nightmare/spider_healer.lua")
modimport("postinit/spat.lua")
modimport("postinit/spider_robot_possess.lua")
modimport("postinit/bishop.lua") -- 主教武器：bishop 旧版 / bishop_nightmare 新版；完好主教每两攻一战吼
modimport("postinit/lobby_changes.lua")

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
modimport("postinit/daywalker2_laser_splash.lua")
RogeDaywalker2LaserSplashCapture()

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
RogeDaywalker2LaserSplashRestore()

-- 人物相关
modimport("postinit/wortox.lua")
load_if_enabled('wanda', "postinit/wanda.lua")
load_if_enabled('wendy', "postinit/wendy.lua")
load_if_enabled('wolfgang', "postinit/wolfgang.lua")
-- 3350 噩梦模式默认启用女武神加强（技能树 / 狂暴 / 冲天刺）
modimport("postinit/wigfrid_skilltree_strings.lua")
modimport("postinit/wigfrid.lua")
modimport("postinit/wigfrid_sky_pierce.lua")
modimport("postinit/wigfrid_perfect_parry.lua")
load_if_enabled('wormwood', "postinit/wormwood.lua")
load_if_enabled('waxwell', "postinit/waxwell.lua")
load_if_enabled('wickerbottom', "postinit/wickerbottom.lua")
load_if_enabled("roge", "postinit/roge/wickerbottom_books.lua") -- 须在 wickerbottom 之后：ROGE 书本改动
load_if_enabled('walter', "postinit/walter.lua")
load_if_enabled('warly', "postinit/warly.lua")
load_if_enabled('woodie', "postinit/woodie.lua")
load_if_enabled('wes', "postinit/wes.lua")
load_if_enabled('wx78', "postinit/wx78.lua")
load_if_enabled('wilson', "postinit/wilson.lua")
modimport("postinit/willow_skilltree_strings.lua")
load_if_enabled('willow', "postinit/willow.lua")
load_if_enabled('winona', "postinit/winona.lua")
-- 配置各类蜘蛛/鱼人的雇佣上限
-- 鱼人类型上限配置
local MERM_FOLLOWER_LIMITS = {
    merm = 10,                -- 普通鱼人
    mermguard = 5,            -- 鱼人守卫
    merm_shadow = 10,         -- 暗影鱼人
    mermguard_shadow = 5,     -- 暗影鱼人守卫
    merm_lunar = 10,          -- 月灵鱼人
    mermguard_lunar = 5,      -- 月灵鱼人守卫
}

-- 蜘蛛类型上限配置
local SPIDER_FOLLOWER_LIMITS = {
    spider = 10,              -- 普通蜘蛛
    spider_warrior = 5,       -- 战士蜘蛛
    spider_hider = 8,         -- 洞穴蜘蛛
    spider_spitter = 8,       -- 喷吐蜘蛛
    spider_dropper = 8,       -- 白蜘蛛
    spider_moon = 10,         -- 月亮蜘蛛
    spider_healer = 5,        -- 蜘蛛护士
    spider_water = 10,        -- 水蜘蛛
}

local function CountFollowersByPrefab(self, prefab)
    local count = 0
    for follower, _ in pairs(self.followers) do
        if follower.prefab == prefab then
            count = count + 1
        end
    end
    return count
end

AddComponentPostInit("leader", function(self)
    local old_AddFollower = self.AddFollower
    
    function self:AddFollower(follower)
        if self.inst:HasTag("player") and follower ~= nil and follower.components.follower ~= nil then
            -- 如果已经是follower，直接调用原函数
            if self.followers[follower] ~= nil then
                return old_AddFollower(self, follower)
            end
            
            local prefab = follower.prefab
            
            -- 检查鱼人类型上限
            if follower:HasTag("merm") and prefab and MERM_FOLLOWER_LIMITS[prefab] then
                local current_count = CountFollowersByPrefab(self, prefab)
                if current_count >= MERM_FOLLOWER_LIMITS[prefab] then
                    -- 达到该类型上限，不添加
                    return
                end
            end
            
            -- 检查蜘蛛类型上限
            if follower:HasTag("spider") and prefab and SPIDER_FOLLOWER_LIMITS[prefab] then
                local current_count = CountFollowersByPrefab(self, prefab)
                if current_count >= SPIDER_FOLLOWER_LIMITS[prefab] then
                    -- 达到该类型上限，不添加
                    return
                end
            end
        end
        
        -- 未达到上限或不是玩家，调用原函数
        return old_AddFollower(self, follower)
    end
end)

-- 生活质量
load_if_enabled('raterate', "postinit/raterate.lua")
load_if_enabled('alterguardianhat', "postinit/alterguardianhat.lua")
load_if_enabled('zuowu', "postinit/zuowu.lua")
load_if_enabled('ruins_equip', "postinit/ruins_equip.lua")
modimport("postinit/dreadsword_revival.lua") -- 绝望剑模组联动：勇者证明→注能-绝望石剑；彩红宝石→君王之剑
load_if_enabled('stage', "postinit/stage.lua")
load_if_enabled('cookpot', "postinit/cookpot.lua")
load_if_enabled('sleep', "postinit/sleep.lua")
if GetModConfigData("shadow_container") then
	modimport("scripts/api.lua")
	modimport("scripts/extensions/shadow_container.lua")
end

load_if_enabled("wardrobe", "postinit/wardrobe.lua")


if GetModConfigData("drownable") then
	AddComponentPostInit("drownable", function(self)
		function self:ShouldFallInVoid()
			return false
		end
	end)
end

-- 眼球塔 SG 补丁必须在 modmain：Prefab 脚本里无 AddStategraphPostInit（strict 会崩）
-- 原版约在第 22 帧出伤；将时间轴拉到约 1.6 秒（48 帧 @30fps），动画用倍率对齐出伤时刻
local EYETURRET_ATTACK_WINDUP_FRAMES = 48
local EYETURRET_ATTACK_ANIM_SYNC = 22 / EYETURRET_ATTACK_WINDUP_FRAMES

local function EyeturretUpdateBishopReticle(inst)
	if not TheWorld.ismastersim then
		return
	end
	local fx = inst._eyeturret_targetingfx
	if fx == nil or not fx:IsValid() then
		return
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target == nil or not target:IsValid() then
		return
	end
	local tx, _, tz = target.Transform:GetWorldPosition()
	local ix, _, iz = inst.Transform:GetWorldPosition()
	local dx, dz = tx - ix, tz - iz
	local dir = (dx == 0 and dz == 0) and inst.Transform:GetRotation() or math.atan2(-dz, dx) * RADIANS
	fx.Transform:SetPosition(tx, 0, tz)
	fx.Transform:SetRotation(dir)
	if fx.SetDistFromBishop ~= nil then
		fx:SetDistFromBishop(math.sqrt(inst:GetDistanceSqToPoint(tx, 0, tz)))
	end
end

AddStategraphPostInit("eyeturret", function(sg)
	local attack = sg.states ~= nil and sg.states.attack or nil
	if attack == nil then
		return
	end

	if attack.timeline ~= nil then
		for _, ev in ipairs(attack.timeline) do
			if type(ev) == "table" and ev.time ~= nil and ev.fn ~= nil then
				ev.time = EYETURRET_ATTACK_WINDUP_FRAMES * FRAMES
				local oldfn = ev.fn
				ev.fn = function(inst)
					if TheWorld.ismastersim and inst._eyeturret_targetingfx ~= nil then
						inst._eyeturret_targetingfx:KillFx()
						inst._eyeturret_targetingfx = nil
					end
					oldfn(inst)
				end
			end
		end
	end

	local old_onenter = attack.onenter
	attack.onenter = function(inst)
		if old_onenter ~= nil then
			old_onenter(inst)
		end
		inst.AnimState:SetDeltaTimeMultiplier(EYETURRET_ATTACK_ANIM_SYNC)
		if inst.base ~= nil and inst.base.AnimState ~= nil then
			inst.base.AnimState:SetDeltaTimeMultiplier(EYETURRET_ATTACK_ANIM_SYNC)
		end
		if TheWorld.ismastersim then
			if inst._eyeturret_targetingfx ~= nil then
				inst._eyeturret_targetingfx:Remove()
				inst._eyeturret_targetingfx = nil
			end
			local fx = SpawnPrefab("bishop_targeting_fx")
			inst._eyeturret_targetingfx = fx
			EyeturretUpdateBishopReticle(inst)
		end
	end

	local old_onupdate = attack.onupdate
	attack.onupdate = function(inst, dt)
		EyeturretUpdateBishopReticle(inst)
		if old_onupdate ~= nil then
			old_onupdate(inst, dt)
		end
	end

	local old_onexit = attack.onexit
	attack.onexit = function(inst)
		inst.AnimState:SetDeltaTimeMultiplier(1)
		if inst.base ~= nil and inst.base.AnimState ~= nil then
			inst.base.AnimState:SetDeltaTimeMultiplier(1)
		end
		if TheWorld.ismastersim and inst._eyeturret_targetingfx ~= nil then
			inst._eyeturret_targetingfx:Remove()
			inst._eyeturret_targetingfx = nil
		end
		if old_onexit ~= nil then
			old_onexit(inst)
		end
	end
end)

-- 梦魇疯猪血量：最后加载，Hook SetMaxHealth 盖过其他 mod
modimport("postinit/daywalker.lua")

