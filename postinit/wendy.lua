TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE = 1000          --蒸馏复仇反伤伤害
TUNING.GHOSTLYELIXIR_SLOWREGEN_HEALING = 4.5            --亡者补药回复血量
TUNING.ABIGAIL_DMG_PERIOD = 1.5                         --阿比的攻速
TUNING.ABIGAIL_VEX_GHOSTLYFRIEND_DAMAGE_MOD = 2.4       --温蒂受易伤buff的加成
TUNING.ABIGAIL_VEX_DURATION = 8                         --易伤效果持续时间

TUNING.WENDYSKILL_COMMAND_COOLDOWN = 2                  --轮盘技能总cd
TUNING.WENDYSKILL_GESTALT_ATTACKAT_COMMAND_COOLDOWN = 5 --冲刺技能cd
TUNING.WENDYSKILL_ESCAPE_TIME = 3.5                     --逃离技能持续时间
TUNING.WENDYSKILL_DASHATTACK_VELOCITY = 15.0            --冲刺速度
-- TUNING.WENDYSKILL_DASHATTACK_HITRATE = 0.5        --冲刺时攻速？

TUNING.WENDYSKILL_SMALLGHOST_EXTRACHANCE = 0.95               --小惊吓的概率
TUNING.ABIGAIL_GESTALT_DAMAGE.day = 120                       -- 月阿比白天的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.dusk = 160                      -- 月阿比黄昏的伤害
TUNING.ABIGAIL_GESTALT_DAMAGE.night = 280                     -- 月夜晚的伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS_GESTALT = 12 * 10 -- abigail gestalt 的位面伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS = 12              -- abigail 的位面伤害
TUNING.SKILLS.WENDY.LUNARELIXIR_DURATION = 2000000            -- 光之怒的持续时间

--光之怒
Recipe2("ghostlyelixir_lunar",
	{ Ingredient("thulecite_pieces", 6), Ingredient("purebrilliance", 2), Ingredient("ghostflower", 5) }, TECH.NONE_TWO,
	{ builder_tag = "ghostlyfriend" }, { "CHARACTER" })

--哀悼荣耀"
AddRecipe2("ghostflower", { Ingredient("moon_cap", 1), Ingredient("moonglass", 1) }, TECH.NONE_TWO,
	{ builder_tag = "ghostlyfriend" }, { "CHARACTER" })

AddPrefabPostInit("abigail", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddTag("crazy")
	local function OnKill(inst, data)
		local victim = data.victim
		if victim and (victim:HasTag("shadow") or victim.prefab == "dreadeye") then
			if inst._playerlink and (victim.sanityreward or victim.prefab == "dreadeye") then
				inst._playerlink.components.sanity:DoDelta(10)
				if victim.prefab == "dreadeye" then
					inst._playerlink.components.sanity:DoDelta(10) --死亡之眼回20理智
				end
			end
			local x, y, z = inst.Transform:GetWorldPosition() --杀死任意影怪时吸引全场影怪仇恨
			local ents = TheSim:FindEntities(x, y, z, 40)
			for k, v in pairs(ents) do
				if v:HasTag("shadow") and v.components.combat then
					v.components.combat:SetTarget(inst)
				end
			end
		end
	end
	inst:AddComponent("sanityaura") --温蒂靠近阿比恢复理智
	inst.components.sanityaura.aurafn = function(inst, observer)
		if observer.prefab == "wendy" then
			return TUNING.SANITYAURA_SMALL
		end
		return 0
	end
	inst:ListenForEvent("killed", OnKill)
end)

TUNING.ABIGAIL_HEALTH = 1000
TUNING.ABIGAIL_HEALTH_LEVEL1 = 250
TUNING.ABIGAIL_HEALTH_LEVEL2 = 500
TUNING.ABIGAIL_HEALTH_LEVEL3 = 1000
TUNING.ABIGAIL_DAMAGE =
{
	day = 28,
	dusk = 36,
	night = 49,
}


--阿比盖尔的位面伤害和实体位面抗性
AddPrefabPostInit("abigail", function(inst)
	inst:AddComponent("planarentity")

	if inst.components.planardamage == nil then
		inst:AddComponent("planardamage")
	end
	inst.components.planardamage:SetBaseDamage(5)
end)

GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})

local containers = require("containers")
local params = containers.params

params.abigail = {
	widget = {
		slotpos = {},
		animbank = "ui_elixir_container_3x3",
		animbuild = "ui_elixir_container_3x3",
		pos = Vector3(300, -70, 0) -- 容器显示的位置，经测试，(0,0)位置就是被添加对象的位置，比如这里是把这个容器添加到阿比盖尔身上，所以容器出现位置的原点就是阿比盖尔所在位置，左上为正，右下为负
	},
	type = "abigail",
	openlimit = 1,
	itemtestfn = function(inst, item, slot) -- 容器里可以装的物品的条件
		return not item:HasTag("_container") and not item:HasTag("bundle") and item.prefab ~= "abigail_flower"
	end
}
-- 循环小格子
for y = 2, 0, -1 do
	for x = 0, 2 do
		table.insert(params.abigail.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80))
		table.insert(params.abigail.widget.slotpos, elixir_container)
	end
end

local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
end

AddPrefabPostInit("abigail", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("container") --容器标签
	inst.components.container:WidgetSetup("abigail")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst:ListenForEvent("death", function(inst)
		if inst.components.container then
			inst.components.container:DropEverything()
		end
	end)
end)



local function getidleanim(inst) --月亮阿比相关
	if not inst.components.timer:TimerExists("flicker_cooldown") and
		TheWorld.components.sisturnregistry and
		TheWorld.components.sisturnregistry:IsBlossom() and
		math.random() < 0.2 and
		not inst.components.debuffable:HasDebuff("abigail_murder_buff") then
		inst.components.timer:StartTimer("flicker_cooldown", math.random() * 20 + 10)

		return "idle_abigail_flicker"
	end

	return (inst._is_transparent and "abigail_escape_loop")
		or (inst.components.aura.applying and "attack_loop")
		or (inst.is_defensive and math.random() < 0.1 and "idle_custom")
		or "idle"
end

AddStategraphPostInit("abigail", function(self)
	local oldgestalt_loop_attackonenter = self.states['gestalt_loop_attack'].onenter
	self.states['gestalt_loop_attack'].onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		inst:SetTransparentPhysics(true)
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:SetMotorVelOverride(15, 0, 0)

		inst.AnimState:PlayAnimation("gestalt_attack_loop", true)
		inst.sg:SetTimeout(3)

		inst.sg.statemem.oldattackdamage = inst.components.combat.defaultdamage

		local buff = inst:GetDebuff("right_elixir_buff") -----------
		local phase = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
		local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)

		inst.components.combat:SetDefaultDamage(damage)

		inst.components.combat:StartAttack()
		inst.sg.statemem.enable_attack = true
	end

	local oldgestalt_loop_homing_attackonenter = self.states['gestalt_loop_homing_attack'].onenter
	self.states['gestalt_loop_homing_attack'].onenter = function(inst, data)
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		inst:SetTransparentPhysics(true)
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:SetMotorVelOverride(TUNING.WENDYSKILL_DASHATTACK_VELOCITY, 0, 0)

		inst.AnimState:PlayAnimation("gestalt_attack_loop", true)
		inst.sg:SetTimeout(10)

		inst.sg.statemem.oldattackdamage = inst.components.combat.defaultdamage

		local buff                       = inst:GetDebuff("right_elixir_buff") -------------
		local phase                      = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or
			TheWorld.state.phase
		local damage                     = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)

		inst.components.combat:SetDefaultDamage(damage * TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE)

		inst.sg.statemem.final_pos = data.pos

		inst:ForceFacePoint(inst.sg.statemem.final_pos)

		local rotation = inst.Transform:GetRotation() -- Keep this after ForceFacePoint!
		inst.sg.statemem.fowardvector = Vector3(math.cos(-rotation / RADIANS), 0, math.sin(-rotation / RADIANS))

		inst.sg.statemem.ignoretargets = {}
	end

	local oldidle = self.states['idle'].onenter
	self.states['idle'].onenter = function(inst)
		inst.components.health:SetInvincible(false) -- 无敌帧 不启动
		if inst.sg.mem.queued_play_target then
			inst.sg.mem.lastplaytime = GetTime()
			inst.sg:GoToState("play", inst.sg.mem.queued_play_target)
			inst.sg.mem.queued_play_target = nil
		else
			local anim = getidleanim(inst)
			if anim ~= nil then
				inst.AnimState:PlayAnimation(anim)
			end
		end
	end

	local oldgestalt_attackonenter = self.states['gestalt_attack'].onenter
	self.states['gestalt_attack'].onenter = function(inst, pos)
		inst.components.locomotor:Stop()
		inst.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_pre")

		inst.components.health:SetInvincible(true) -- 无敌帧 启动

		inst.Physics:Stop()

		inst.AnimState:PlayAnimation("gestalt_attack_pre")

		if pos ~= nil then
			inst.sg.statemem.final_pos = pos
		end
	end

	local oldgestalt_pst_attackonenter = self.states['gestalt_pst_attack'].onenter
	self.states['gestalt_pst_attack'].onenter = function(inst)
		inst.AnimState:PlayAnimation("gestalt_attack_pst")
		inst.components.health:SetInvincible(true) -- 无敌帧 启动
	end
end)
