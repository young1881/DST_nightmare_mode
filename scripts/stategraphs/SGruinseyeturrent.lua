require("stategraphs/commonstates")

-- 与 ruinseyeturret.lua 里 SHADOWEYETURRET_ATTACK_CYCLE_SEC 保持一致（约每 1.5 秒一次完整攻击）
local SHADOWEYETURRET_ATTACK_CYCLE_SEC = 1.5
-- 蓄力段帧数与 modmain AddStategraphPostInit("eyeturret") 一致，配合 ANIM_SYNC 在出弹前显示主教瞄准线
local SHADOWEYETURRET_ATTACK_WINDUP_FRAMES = 33
local SHADOWEYETURRET_ATTACK_ANIM_SYNC = 22 / SHADOWEYETURRET_ATTACK_WINDUP_FRAMES

local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst)
		if inst.components.health:IsDead() then
			return
		end
		-- 附身会高频 doattack；已在攻击状态中则忽略（攻击状态固定约 SHADOWEYETURRET_ATTACK_CYCLE_SEC 秒）
		if inst.sg:HasStateTag("attack") then
			return
		end
		if (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) or not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("attack")
		end
    end),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
    --CommonHandlers.OnAttacked(),
	EventHandler("attacked", function(inst, data)
		if not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif not inst.sg:HasAnyStateTag("attack", "electrocute") then
				inst.sg:GoToState("hit")
			end
        end
	end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst:syncanim("idle_loop", true)
            --inst.AnimState:PlayAnimation("idle_loop", true)
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst:syncanim("death")

            inst.components.lootdropper:DropLoot()

            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/pop") end)
        },
    },

    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst) inst:syncanim("hit") end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "canrotate"},
        onenter = function(inst)
            inst:triggerlight()
            inst:syncanim("atk")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/charge")
            inst.AnimState:SetDeltaTimeMultiplier(SHADOWEYETURRET_ATTACK_ANIM_SYNC)
            if inst.base ~= nil and inst.base.AnimState ~= nil then
                inst.base.AnimState:SetDeltaTimeMultiplier(SHADOWEYETURRET_ATTACK_ANIM_SYNC)
            end
            if TheWorld.ismastersim then
                if inst.ShadowEyeClearBishopReticle ~= nil then
                    inst:ShadowEyeClearBishopReticle()
                end
                local fx = SpawnPrefab("bishop_targeting_fx")
                inst._eyeturret_targetingfx = fx
                if inst.ShadowEyeUpdateBishopReticle ~= nil then
                    inst:ShadowEyeUpdateBishopReticle()
                end
            end
            inst.sg:SetTimeout(SHADOWEYETURRET_ATTACK_CYCLE_SEC)
        end,
        onupdate = function(inst, dt)
            if inst.ShadowEyeUpdateBishopReticle ~= nil then
                inst:ShadowEyeUpdateBishopReticle()
            end
        end,
        timeline=
        {
            TimeEvent(SHADOWEYETURRET_ATTACK_WINDUP_FRAMES * FRAMES, function(inst)
                if inst.sg:HasStateTag("attack") then
                    if TheWorld.ismastersim and inst._eyeturret_targetingfx ~= nil then
                        if inst._eyeturret_targetingfx.KillFx ~= nil then
                            inst._eyeturret_targetingfx:KillFx()
                        else
                            inst._eyeturret_targetingfx:Remove()
                        end
                        inst._eyeturret_targetingfx = nil
                    end
                    inst.components.combat:StartAttack()
                    inst.components.combat:DoAttack()
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/shoot")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        onexit = function(inst)
            inst.AnimState:SetDeltaTimeMultiplier(1)
            if inst.base ~= nil and inst.base.AnimState ~= nil then
                inst.base.AnimState:SetDeltaTimeMultiplier(1)
            end
            if TheWorld.ismastersim and inst.ShadowEyeClearBishopReticle ~= nil then
                inst:ShadowEyeClearBishopReticle()
            end
        end,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.sg:HasStateTag("attack") then
                    inst:syncanim("idle_loop", true)
                end
            end),
        },
    },
}
CommonStates.AddFrozenStates(states)
CommonStates.AddElectrocuteStates(states)

return StateGraph("ruinseyeturrent", states, events, "idle")