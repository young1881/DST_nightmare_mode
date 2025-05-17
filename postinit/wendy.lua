GLOBAL.setmetatable(GLOBAL.getfenv(1), {
	__index = function(self, index)
		return GLOBAL.rawget(GLOBAL, index)
	end
})
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
	for x=0, 2 do
    table.insert(params.abigail.widget.slotpos, Vector3(80*x-80*2+80,80*y-80*2+80))
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
    inst:AddComponent("container")  --容器标签
    inst.components.container:WidgetSetup("abigail")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    inst:ListenForEvent("death", function(inst)
        if inst.components.container then
            inst.components.container:DropEverything()
        end
    end)
end)



local function getidleanim(inst)   --月亮阿比相关
 
	if not inst.components.timer:TimerExists("flicker_cooldown") and 
		TheWorld.components.sisturnregistry and 
		TheWorld.components.sisturnregistry:IsBlossom() and 
		math.random()<0.2 and
		not inst.components.debuffable:HasDebuff("abigail_murder_buff") then
			
		inst.components.timer:StartTimer("flicker_cooldown", math.random()*20  + 10 )

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

		local buff   = inst:GetDebuff("right_elixir_buff") -------------
		local phase  = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
		local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)

		inst.components.combat:SetDefaultDamage(damage * TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE)

		inst.sg.statemem.final_pos = data.pos

		inst:ForceFacePoint(inst.sg.statemem.final_pos)

		local rotation = inst.Transform:GetRotation() -- Keep this after ForceFacePoint!
		inst.sg.statemem.fowardvector = Vector3(math.cos(-rotation / RADIANS), 0, math.sin(-rotation / RADIANS))

		inst.sg.statemem.ignoretargets = {}
	end

	local oldidle = self.states['idle'].onenter
	self.states['idle'].onenter = function (inst)
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
	self.states['gestalt_attack'].onenter = function (inst, pos)
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
	self.states['gestalt_pst_attack'].onenter = function (inst)
		inst.AnimState:PlayAnimation("gestalt_attack_pst")
		inst.components.health:SetInvincible(true) -- 无敌帧 启动
	end
end)

local function domutatefn(inst,doer)
	local ghostlybond = doer.components.ghostlybond -- 获取执行者（doer）的 ghostlybond 组件，该组件可能与幽灵绑定相关

	if ghostlybond == nil or ghostlybond.ghost == nil or not ghostlybond.summoned then -- 检查 ghostlybond 是否存在，以及其绑定的幽灵（ghost）是否存在，同时检查是否已召唤（summoned）
		return false, "NOGHOST" -- 如果任一条件不满足，则返回 false 和错误信息 "NOGHOST"
	elseif ghostlybond.ghost:HasTag("gestalt") then -- 检查幽灵是否具有 "gestalt" 标签,
		ghostlybond.ghost:ChangeToGestalt(false) -- 如果有，则将其切换为 普通形态
	else
		ghostlybond.ghost:ChangeToGestalt(true)  -- 如果没有，则将其切换为 月亮形态
	end

	return true -- 返回 true，表示操作成功
end
 -- [[ moondial (月晷) 相关改动 ]]
AddPrefabPostInit("moondial", function (inst)
	if inst.components.ghostgestalter ~= nil then -- 检查 inst 是否有 ghostgestalter 组件,ghostgestalter 组件可能与幽灵形态变换相关
		inst.components.ghostgestalter.domutatefn = domutatefn
	end

	inst:AddTag("watersource")
	inst:AddComponent("watersource")
	inst.components.watersource.available = true
end)
