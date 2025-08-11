--1阶段
TUNING.ALTERGUARDIAN_PHASE1_HEALTH = 60000       --血量
TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD = 3.0  --攻击间隔
TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN = 3.5   --翻滚CD
TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN = 5   --召唤CD
TUNING.ALTERGUARDIAN_PHASE1_SHIELDTRIGGER = 8000 --盾触发
TUNING.ALTERGUARDIAN_PHASE1_SHIELDABSORB = 0.95  --盾吸收
TUNING.ALTERGUARDIAN_PHASE1_ROLLDAMAGE = 350     --翻滚攻击力
TUNING.ALTERGUARDIAN_PHASE1_AOEDAMAGE = 360      --AOE攻击力
TUNING.ALTERGUARDIAN_PHASE1_TARGET_DIST = 56     --仇恨范围

--2阶段
TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH = 80000 --血量
TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD = 2.5 --攻击间隔
TUNING.ALTERGUARDIAN_PHASE2_SPINCD = 11.5       --旋转CD
TUNING.ALTERGUARDIAN_PHASE2_DAMAGE = 360        --攻击力
TUNING.ALTERGUARDIAN_PHASE2_SPIKEDAMAGE = 160   --尖刺攻击力
TUNING.ALTERGUARDIAN_PHASE2_TARGET_DIST = 58    --仇恨范围
TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE = 56
TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE = 50

--3阶段
TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH = 100000     --血量
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD = 2.5      --攻击间隔
TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD = 15             --陷阱CD
TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN = 25      --召唤CD
TUNING.ALTERGUARDIAN_PHASE3_DAMAGE = 320             --攻击力
TUNING.ALTERGUARDIAN_PHASE3_LASERDAMAGE = 520        --激光攻击力
TUNING.ALTERGUARDIAN_PHASE3_TRAP_LANDEDDAMAGE = 80   --陷阱攻击力
TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST = 42         --仇恨范围
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE = 42        --攻击范围
TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED = 18.0        --移速
TUNING.ALTERGUARDIAN_PHASE3_RUNAWAY_BLOCK_TIME = 0.1 --可以阻挡天体移动的时间
TUNING.ALTERGUARDIAN_PHASE3_SUMMONMAXLOOPS = 180     --天体大虚影总数
TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ = 1000         --蓝圈大小，20为1格
TUNING.ALTERGUARDIAN_PHASE3_MAX_STUN_LOCKS = 0.5     --天体可僵直次数


TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT = 8
local SupremeEpic_planar_dmg = 20 --天体织影位面伤害


--TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN = 24.25
TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN           = 9   --地刺cd
TUNING.ALTERGUARDIAN_PHASE2_LIGHTNINGCOOLDOWN       = 35  --旋风劈cd
TUNING.ALTERGUARDIAN_PHASE2_LIGHTNING_DAMAGE        = 380 --旋风劈伤害

--TUNING.ALTERGUARDIAN_PHASE2_SPINCD = 14.25
TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED              = 10 --大风车速度
TUNING.ALTERGUARDIAN_PHASE2_SPIN2CD                 = 20 --某个大风车的cd
TUNING.ALTERGUARDIAN_PHASE2_DEADSPIN_SPEED          = 16 --旋风劈移速

TUNING.ALTERGUARDIAN_PHASE3_TRAP_MAXRANGE           = 5  --召唤陷阱的范围
TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT                 = 40 --陷阱持续时间
TUNING.ALTERGUARDIAN_PHASE3_ERASERCOOLDOWN          = 60 --秒杀cd

--只因
TUNING.STALKER_ATRIUM_HEALTH                        = 60000 --血量
TUNING.STALKER_ATRIUM_PHASE2_HEALTH                 = 40000 --二阶段
TUNING.STALKER_CHANNELERS_CD                        = 6.0   --苦笑暗影CD
TUNING.STALKER_CHANNELERS_COUNT                     = 5     --苦笑暗影数量
TUNING.STALKER_MINIONS_COUNT                        = 120   --奴隶数量
TUNING.STALKER_MINIONS_CD                           = 3.0   --奴隶CD
TUNING.STALKER_FEAST_HEALING                        = 3000  --回血
TUNING.STALKER_MINDCONTROL_CD                       = 12    --精神控制CD
TUNING.STALKER_MINDCONTROL_RANGE                    = 14    --精神控制范围
TUNING.STALKER_MINDCONTROL_DURATION                 = 4.5   --精神控制时长
TUNING.FOSSIL_SPIKE_DAMAGE                          = 380   --钉子伤害
TUNING.STALKER_SPIKES_CD                            = 4     --钉子CD
TUNING.STALKER_ATTACK_RANGE                         = 5.8   --攻击范围
TUNING.STALKER_HIT_RANGE                            = 5.5   --攻击范围
TUNING.STALKER_AOE_RANGE                            = 5.4   --AOE范围
TUNING.STALKER_DAMAGE                               = 360   --攻击力
TUNING.STALKER_SPEED                                = 5.5   --只因者移速

TUNING.IRONLORD_HEALTH                              = 15000 --白云血量

--猴尾草加强
TUNING.MONKEYTAIL_CYCLES                            = 12

-- 鸟嘴壶效率提高
TUNING.PREMIUMWATERINGCAN_WATER_AMOUNT              = 45

--春鹅加强
TUNING.MOOSE_HEALTH                                 = 10000 -- 血量
TUNING.MOOSE_DAMAGE                                 = 150   -- 伤害
TUNING.MOOSE_ATTACK_PERIOD                          = 3     -- 攻击间隔
TUNING.MOSSLING_HEALTH                              = 1000  -- 小鸭子血量
TUNING.MOSSLING_DAMAGE                              = 100   -- 小鸭子伤害

-- 蜂后
TUNING.BEEQUEEN_HEALTH                              = 22500            -- 总血量
TUNING.BEEQUEEN_DAMAGE                              = 120              -- 伤害
TUNING.BEEQUEEN_ATTACK_PERIOD                       = 2                -- 攻击间隔
TUNING.BEEQUEEN_HIT_RANGE                           = 6                -- 攻击范围
TUNING.BEEQUEEN_MIN_GUARDS_PER_SPAWN                = 8                -- 单次能叫小蜜蜂下限
TUNING.BEEQUEEN_MAX_GUARDS_PER_SPAWN                = 10               -- 单次能叫小蜜蜂上限
TUNING.BEEQUEEN_TOTAL_GUARDS                        = 15               -- 小蜜蜂总量上限
TUNING.BEEQUEEN_DODGE_SPEED                         = 6                -- 移速
TUNING.BEEQUEEN_HONEYTRAIL_SPEED_PENALTY            = 0.4              -- 地上蜂蜜的减速
TUNING.BEEQUEEN_SPAWNGUARDS_CD                      = { 18, 8, 5, 9 }  -- 四个阶段召唤小蜜蜂的cd
TUNING.BEEQUEEN_FOCUSTARGET_CD                      = { 0, 0, 10, 12 } -- 四个阶段叫小蜜蜂冲刺的cd

-- 小蜜蜂
TUNING.BEEGUARD_HEALTH                              = 240 -- 血量
TUNING.BEEGUARD_DAMAGE                              = 40  -- 伤害
TUNING.BEEGUARD_SPEED                               = 4   -- 移速
TUNING.BEEGUARD_DASH_SPEED                          = 8   -- 狂暴的移速
TUNING.BEEGUARD_PUFFY_DAMAGE                        = 60  -- 狂暴的伤害

--蚁狮加强
local total_day_time                                = 480
TUNING.ANTLION_HEALTH                               = 12000
TUNING.ANTLION_RAGE_TIME_INITIAL                    = 10.2 * total_day_time --愤怒最初时间
TUNING.ANTLION_RAGE_TIME_MIN                        = 6 * total_day_time
TUNING.ANTLION_RAGE_TIME_MAX                        = 12 * total_day_time
TUNING.ANTLION_TRIBUTE_TO_RAGE_TIME                 = 1 * total_day_time

--墨荒血量翻倍
TUNING.SHADOWTHRALL_HORNS_HEALTH                    = 2400
TUNING.SHADOWTHRALL_WINGS_HEALTH                    = 2200
TUNING.SHADOWTHRALL_HANDS_HEALTH                    = 2000
TUNING.SHADOWTHRALL_MOUTH_HEALTH                    = 2000

-- 果蝇王加强
TUNING.LORDFRUITFLY_INITIALSPAWN_TIME               = total_day_time * 8 --提前出现
TUNING.LORDFRUITFLY_HEALTH                          = 2000               --血量翻倍
TUNING.LORDFRUITFLY_DAMAGE                          = 50                 --基础伤害翻倍

-- 夜莓削弱
ANCIENTTREE_NIGHTVISION_FRUIT_BUFF_DURATION         = total_day_time / 4

--独角鲸与鲨鱼血量削弱
TUNING.GNARWAIL.HEALTH                              = 500
TUNING.SHARK.HEALTH                                 = 500

TUNING.SHAODWDRAGON_FIRECD                          = 20
TUNING.SHAODWDRAGON_WAVECD                          = 16
TUNING.RUINSNIGHTMARE_SPAWN_CHANCE                  = .35
TUNING.RUINSNIGHTMARE_SPAWN_CHANCE_RIFTS            = .7

-- 晶体巨鹿用来结档
-- TUNING.MUTATED_DEERCLOPS_HEALTH               = 50000 -- 血量
-- TUNING.MUTATED_DEERCLOPS_DAMAGE               = 1000  -- 物理伤害
-- TUNING.MUTATED_DEERCLOPS_PLANAR_DAMAGE        = 80    -- 位面伤害
-- TUNING.MUTATED_DEERCLOPS_ATTACK_RANGE         = 36    -- 攻击距离
-- TUNING.MUTATED_DEERCLOPS_ATTACK_PERIOD        = 1     -- 攻击间隔
-- TUNING.MUTATED_DEERCLOPS_ICELANCE_DAMAGE      = 1500  -- 冰柱伤害
-- TUNING.MUTATED_DEERCLOPS_FRENZY_HP            = 0.1   -- 狂暴状态结束需要打的血量百分比
-- TUNING.MUTATED_DEERCLOPS_STAGGER_TIME         = 1     -- 虚弱的秒数，原版6
-- TUNING.MUTATED_DEERCLOPS_ICELANCE_RANGE.max   = 16    -- 触发冰柱攻击的最近距离 原版12

--天体后裔BOSS
TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_HEALTH        = 99999
TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_PERIOD = { 2.5, 2 } --攻击间隔
--TUNING.ALTERGUARDIAN_LUNAR_FISSURE_LUNAR_BURN_DPS = 25*2   --裂隙灼烧
TUNING.ALTERGUARDIAN_LUNAR_SUPERNOVA_PLANAR_DAMAGE  = 999        --超星位面伤害
TUNING.ALTERGUARDIAN_LUNAR_SUPERNOVA_LUNAR_BURN_DPS = 999        --叠加伤害
TUNING.ALTERGUARDIAN_PHASE4_SUPERNOVA_CD            = 60         --超星冷却


--瓦器人BOSS
TUNING.WAGBOSS_ROBOT_HEALTH = 99999
TUNING.WAGBOSS_ROBOT_ATTACK_PERIOD = { 2.5, 2, 2, 1 } -- 不同威胁等级下的攻击间隔
TUNING.WAGBOSS_ROBOT_KICK_DAMAGE = 50 * 3             -- 踢击伤害
TUNING.WAGBOSS_ROBOT_KICK_PLANAR_DAMAGE = 10 * 3      -- 踢击平面伤害
TUNING.WAGBOSS_MISSILE_DAMAGE = 75 * 3                -- 单发导弹伤害
TUNING.WAGBOSS_MISSILE_PLANAR_DAMAGE = 10 * 3         -- 导弹平面伤害
TUNING.WAGBOSS_BEAM_PLANAR_DAMAGE = 999               -- 光束初始命中平面伤害
TUNING.WAGBOSS_BEAM_LUNAR_BURN_DPS = 999              -- 月光灼烧持续伤害（每秒）
TUNING.WAGBOSS_BEAM_BRIGHTMARE_HEAL = 5 * 6           -- 对光明梦魇单位的治疗量（每秒
TUNING.WAGBOSS_ROBOT_TANTRUM_CD = 7                   -- 暴怒技能冷却时间
TUNING.WAGBOSS_ROBOT_LEAP_CD = { 4, 8 }               -- 跳跃攻击冷却范围（随机值）
TUNING.WAGBOSS_ROBOT_MISSILES_CD = { 7, 14 }          -- 导弹冷却范围
TUNING.WAGBOSS_ROBOT_HACK_DRONES_CD = 20              -- 控制无人机冷却时间
TUNING.WAGBOSS_ROBOT_ORBITAL_STRIKE_CD = { 12, 15 }   -- 轨道打击冷却范围

AddPrefabPostInit("wagboss_robot", function(inst)
	inst:AddTag("notraptrigger")
	inst:AddComponent("truedamage")
	inst.components.truedamage:SetBaseDamage(20) --真实伤害
end)
AddPrefabPostInit("alterguardian_phase4_lunarrift", function(inst)
	inst:AddTag("notraptrigger")
	inst:AddComponent("truedamage")
	inst.components.truedamage:SetBaseDamage(20) --真实伤害
end)

---位面伤害
local bossplanardamage = 15
ListOfBoss2            = {
	"malbatross",  --邪天翁
	"minotaur",    --犀牛
	"dragonfly",   --龙蝇
	"beequeen",    --蜂后
	"twinofterror1",
	"twinofterror2", --双子
	"klaus",       --克劳斯
	"moose",       --春鹅
	"eyeofterror", --大眼
	"daywalker",   --疯猪
	"toadstool_dark", --大蛤蟆
	"antlion",     --蚁狮
	"toadstool",   --蛤蟆
	"shadowdragon", --恐惧之龙
	"ironlord",    --附身铠甲
	"worm_boss"
}
for k, v in pairs(ListOfBoss2) do
	AddPrefabPostInit(v, function(inst)
		if inst.components.planardamage == nil then
			inst:AddComponent("planardamage")
		end
		inst.components.planardamage:SetBaseDamage(bossplanardamage)
	end)
end


ListOfBBB = {
	"alterguardian_phase1",
	"alterguardian_phase2",
	"alterguardian_phase3",
	"stalker_atrium"
}
for k, v in ipairs(ListOfBBB) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("planarentity")

		if inst.components.planardamage == nil then
			inst:AddComponent("planardamage")
		end
		inst.components.planardamage:SetBaseDamage(SupremeEpic_planar_dmg)
	end)
end

-- 加了位面抗性和位面伤害5点的生物
ListOfBoss3 = {
	"beeguard",
	"mossling",
}
for k, v in ipairs(ListOfBoss3) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("planarentity")

		if inst.components.planardamage == nil then
			inst:AddComponent("planardamage")
		end
		inst.components.planardamage:SetBaseDamage(5)
	end)
end

TUNING.SLEEP_HEALTH_PER_TICK = 2  --帐篷回血增强，2是二倍
TUNING.SLEEP_HUNGER_PER_TICK = -2 --帐篷掉饱食度双倍
TUNING.SLEEP_SANITY_PER_TICK = 2  --帐篷回san双倍
TUNING.PORTABLE_TENT_USES = 5     --尼哥的帐篷五次耐久

--- 干燥时间 （480就是一天的长度）
TUNING.DRY_SUPERFAST = 0.12 * 480 -- 海带
TUNING.DRY_FAST = 0.25 * 480      -- 怪物肉
TUNING.DRY_MED = 0.5 * 480        -- 大肉

--- 肉干加强
local function modify_meat_dried(inst)
	if inst.components.edible ~= nil then
		inst.components.edible.healthvalue = 40
		inst.components.edible.hungervalue = 62.5
		inst.components.edible.sanityvalue = 20
	end
end

AddPrefabPostInit("meat_dried", modify_meat_dried)

--- 小肉干加强
local function modify_smallmeat_dried(inst)
	if inst.components.edible ~= nil then
		inst.components.edible.healthvalue = 20
		inst.components.edible.hungervalue = 25
		inst.components.edible.sanityvalue = 10
	end
end

AddPrefabPostInit("smallmeat_dried", modify_smallmeat_dried)


--- 怪物肉干加强
local function modify_monstermeat_dried(inst)
	if inst.components.edible ~= nil then
		inst.components.edible.healthvalue = -3
		inst.components.edible.hungervalue = 80
		inst.components.edible.sanityvalue = -5
	end
end

AddPrefabPostInit("monstermeat_dried", modify_monstermeat_dried)


--抗冰冻
AddComponentPostInit("freezable", function(self)
	if self.inst:HasTag("player") or self.inst:HasTag("crabking") or self.inst:HasTag("antlion") then return end
	local oldAddColdness = self.AddColdness
	self.AddColdness = function(self, ...)
		local inst = self.inst
		if inst:HasTag("epic") then return end
		return oldAddColdness(self, ...)
	end
	local oldFreeze = self.Freeze
	self.Freeze = function(self, ...)
		local inst = self.inst
		if inst:HasTag("epic") then
			self.coldness = 0
			self:UpdateTint()
			return
		end
		return oldFreeze(self, ...)
	end
end)

-- 加了位面防御的生物
ListOfBoss5 = {
	"abigail",
}
for k, v in ipairs(ListOfBoss5) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("planardefense")

		if inst.components.planardefense == nil then
			inst:AddComponent("planardefense")
		end
		inst.components.planardefense:SetBaseDefense(15)
	end)
end

TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE = 1000                --蒸馏复仇反伤伤害
TUNING.GHOSTLYELIXIR_SLOWREGEN_HEALING = 4.5                  --亡者补药回复血量
TUNING.ABIGAIL_DMG_PERIOD = 1.5                               --阿比的攻速
TUNING.ABIGAIL_VEX_GHOSTLYFRIEND_DAMAGE_MOD = 2.4             --温蒂受易伤buff的加成
TUNING.ABIGAIL_VEX_DURATION = 8                               --易伤效果持续时间
TUNING.WILLOW_EMBER_LUNAR = 3                                 --月火费用
TUNING.WILLOW_FIREFRENZY_MULT = 1.75                          --燃烧斗士伤害提高百分之二十五
TUNING.WILLOW_LUNAR_FIRE_BONUS = 1.25                         --月火增伤百分之25
TUNING.WILLOW_LUNAR_FIRE_TIME = 5.0                           --月火持续时间
TUNING.WILLOW_LUNAR_FIRE_DAMAGE = 8                           --月火的伤害
TUNING.WILLOW_LUNAR_FIRE_PLANAR_DAMAGE = 48                   --月火的位面伤害
TUNING.WILLOW_LUNAR_FIRE_COOLDOWN = 5.0                       --月火cd
TUNING.CHANNELCAST_SPEED_MOD = 90 / 100                       --放月火时的移速
TUNING.WILLOW_BERNIE_HEALTH_REGEN_PERIOD = 1.5                --伯尼回血判定时间
TUNING.WILLOW_BERNIE_HEALTH_REGEN_1 = 400                     --伯尼一级回血每秒回4
TUNING.WILLOW_BERNIE_HEALTH_REGEN_2 = 800                     --伯尼二级回血每秒回8
TUNING.WINONA_CATAPULT_MEGA_PLANAR_DAMAGE = 75                --启迪投石机位面袭击的伤害
TUNING.WINONA_CATAPULT_HEALTH = 250                           --投石机的血量
TUNING.AUTUMN_LENGTH = 16                                     --秋天的时间
TUNING.EYETURRET_DAMAGE = 175                                 --眼球塔伤害
TUNING.EYETURRET_HEALTH = 114514                              --眼球塔血量
TUNING.EYETURRET_ATTACK_PERIOD = 1.5                          --眼球塔攻速
TUNING.LUNARTHRALL_PLANT_DAMAGE = 185                         --亮茄的物理伤害
TUNING.SHADOWWAXWELL_SHADOWSTRIKE_DAMAGE_MULT = 2.6           --暗影角斗士冲刺伤害倍率
TUNING.WORM_BOSS_HEALTH = 6000                                --巨大蠕虫血量
TUNING.WORM_BOSS_DAMAGE = 24                                  --巨大蠕虫伤害
TUNING.BOOK_BEES_AMOUNT = 7                                   --养蜂笔记每次蜜蜂数量
TUNING.BOOK_BEES_MAX_ATTACK_RANGE = 22                        --养蜂笔记蜜蜂的最大攻击范围
TUNING.BOOK_MAX_GRUMBLE_BEES = 22                             --养蜂笔记最大蜜蜂数量
TUNING.WENDYSKILL_COMMAND_COOLDOWN = 2                        --轮盘技能总cd
TUNING.WENDYSKILL_GESTALT_ATTACKAT_COMMAND_COOLDOWN = 5       --冲刺技能cd
TUNING.WENDYSKILL_ESCAPE_TIME = 3.5                           --逃离技能持续时间
TUNING.WENDYSKILL_DASHATTACK_VELOCITY = 15.0                  --冲刺速度
-- TUNING.WENDYSKILL_DASHATTACK_HITRATE = 0.5        --冲刺时攻速？
TUNING.ARMOR_WATHGRITHR_IMPROVEDHAT_ABSORPTION = 0.80         --统帅头防御效果
TUNING.DUMBBELL_DAMAGE_BLUEGEM = 68.5                         --蓝宝石哑铃的伤害倍率
TUNING.WENDYSKILL_SMALLGHOST_EXTRACHANCE = 0.95               --小惊吓的概率
TUNING.ABIGAIL_GESTALT_DAMAGE.day = 120                       -- 月阿比白天的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.dusk = 160                      -- 月阿比黄昏的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.night = 280                     -- 月夜晚的伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS_GESTALT = 12 * 10 -- abigail gestalt 的位面伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS = 12              -- abigail 的位面伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DURATION = 2000000            -- 光之怒的持续时间
-- TUNING.LUNARTHRALL_PLANT_DAMAGE = 220                         --反击伤害
-- TUNING.LUNARTHRALL_PLANT_PLANAR_DAMAGE = 35                   --反击的位面

AddPrefabPostInit("sporecloud", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.AnimState:SetDeltaTimeMultiplier(0.75)

	if inst.components.aura then
		inst.components.aura:Enable(false)
	end

	if inst._spoiltask ~= nil then
		inst._spoiltask:Cancel()
		inst._spoiltask = nil
	end


	local delay = 1.5
	inst:DoTaskInTime(delay, function()
		inst.AnimState:SetDeltaTimeMultiplier(1)
		if inst.components.aura then
			inst.components.aura:Enable(true)
		end
		if inst._spoiltask == nil then
			local tick = inst.components.aura and inst.components.aura.tickperiod or 1
			inst._spoiltask = inst:DoPeriodicTask(tick, function()
				local x, y, z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil,
					{ "small_livestock" },
					{ "fresh", "stale", "spoiled" })
				for i, v in ipairs(ents) do
					if v.components.perishable then
						local item = v
						if item:IsInLimbo() then
							local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
							if owner == nil or
								(owner.components.container and not owner.components.container:IsOpen() and
									owner:HasOneOfTags({ "structure", "portablestorage" }))
							then
								return
							end
						end
						item.components.perishable:ReducePercent(TUNING.TOADSTOOL_SPORECLOUD_ROT)
					end
				end
			end, tick * 0.5)
		end
	end)
end)


