TUNING.WES_REVIVE_COOLDOWN = 15
TUNING.WES_REVIVE_INCRE = 15
TUNING.WES_TIME_TO_DODGE = 3
TUNING.BALLOON_SPEED_DURATION = 480 * 0.5


local function CanRevive(haunter)
    if not haunter or not haunter.components.health then
        return false
    end

    local time_left = TUNING.WES_REVIVE_COOLDOWN - (GLOBAL.GetTime() - (haunter.last_revive_time or 0))
    if time_left > 0 then
        if haunter.components.talker then
            haunter.components.talker:Say(string.format("复活冷却中：%.1f 秒", time_left))
        end
        return false
    end
    return true
end

local function PerformRevive(inst, haunter)
    if not CanRevive(haunter) then
        return false
    end

    TUNING.WES_REVIVE_COOLDOWN = TUNING.WES_REVIVE_COOLDOWN + TUNING.WES_REVIVE_INCRE
    -- haunter.components.health:Respawn(TUNING.WES_REVIVE_HEALTH)
    haunter.last_revive_time = GLOBAL.GetTime()
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/resurrect")
    end
    local fx = SpawnPrefab("resurrect_fx")
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst:Remove()
    return true
end

local function onhaunted(inst, haunter)
    if haunter:HasTag("playerghost") and haunter.prefab == "wes" then
        return PerformRevive(inst, haunter)
    end
    return false
end

local function AddBalloonReviveLogic(inst)
    if not TheWorld.ismastersim then
        return
    end
    if not inst.components.hauntable then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    inst.components.hauntable:SetOnHauntFn(onhaunted)
end

AddPrefabPostInit("balloon", AddBalloonReviveLogic)
AddPrefabPostInit("balloonparty", AddBalloonReviveLogic)
AddPrefabPostInit("balloonspeed", AddBalloonReviveLogic)

local function AddWesCooldownLogic(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst.last_revive_time = inst.last_revive_time or 0
end

AddPlayerPostInit(AddWesCooldownLogic)

local function OnDeath(inst)
    if inst.components.inventory then
        inst.components.inventory.DropEverything = function(inv)
            for k, v in pairs(inv:FindItems(function(item) return item:HasTag("irreplaceable") end)) do
                inv:DropItem(v, true, true)
            end
        end
    end

    if inst.components.equippable then
        inst.components.equippable.unequippedfn = function() end
    end

    if inst.components.health then
        inst.components.health.penalty = 0
    end
end

AddPrefabPostInit("wes", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("death", OnDeath)
end)




local weslimit = true
local dodgesound = true

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and GetTime() - inst.last_dodge_time > inst.dodge_cooldown then
        local rider = inst.replica.rider
        if rider == nil or not rider:IsRiding() then
            return { ACTIONS.DODGE }
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if
        inst.components.playeractionpicker ~= nil and
        not (weslimit and inst.components.playeractionpicker.pointspecialactionsfn)
    then
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

AddPlayerPostInit(
    function(inst)
        if weslimit == true and inst.prefab ~= "wes" then
            return
        end
        inst.dodgetime = net_bool(inst.GUID, "player.dodgetime", "dodgetimedirty")
        inst:ListenForEvent(
            "dodgetimedirty",
            function()
                inst.last_dodge_time = GetTime()
            end
        )
        inst:ListenForEvent("setowner", OnSetOwner)
        inst.last_dodge_time = GetTime()
        inst.dodge_cooldown = TUNING.WES_TIME_TO_DODGE
    end
)

AddAction(
    "DODGE",
    "Dodge",
    function(act, data)
        act.doer:PushEvent(
            "redirect_locomote",
            { pos = act.pos or GLOBAL.Vector3(act.target.Transform:GetWorldPosition()) }
        )
        return true
    end
)

ACTIONS.DODGE.distance = math.huge
ACTIONS.DODGE.instant = true

local lang_id = LOC:GetLanguage()
if lang_id == LANGUAGE.CHINESE_T or lang_id == LANGUAGE.CHINESE_S or lang_id == LANGUAGE.CHINESE_S_RAIL then
    STRINGS.ACTIONS.DODGE = { GENERIC = "滑铲" }
end

AddStategraphEvent(
    "wilson",
    EventHandler(
        "redirect_locomote",
        function(inst, data)
            inst.sg:GoToState("dodge", data)
        end
    )
)

AddStategraphState(
    "wilson",
    State {
        name = "dodge",
        tags = { "busy", "evade", "no_stun", "canrotate" },
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            if data and data.pos then
                local pos = data.pos:GetPosition()
                inst:ForceFacePoint(pos.x, 0, pos.z)
            end

            inst.sg:SetTimeout(0.25)
            -- inst.AnimState:PlayAnimation("slide_pre")
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag")
            -- inst.AnimState:PushAnimation("slide_loop")
            if dodgesound then
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out")
            else
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .35)
            end
            inst.Physics:SetMotorVelOverride(20, 0, 0)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.was_invincible = inst.components.health.invincible
            inst.components.health:SetInvincible(true)

            inst.last_dodge_time = GLOBAL.GetTime()
            inst.dodgetime:set(inst.dodgetime:value() == false and true or false)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst.sg:SetTimeout(0.25)
        end,
        ontimeout = function(inst)
            -- inst.sg:GoToState("dodge_pst")
            inst.sg:GoToState("idle")
        end,
        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()

            inst.components.locomotor:SetBufferedAction(nil)
            if not inst.was_invincible then
                inst.components.health:SetInvincible(false)
            end

            inst.was_invincible = nil
        end
    }
)

AddStategraphState(
    "wilson_client",
    State {
        name = "dodge",
        tags = { "busy", "evade", "no_stun", "canrotate" },
        onenter = function(inst, data)
            inst.entity:SetIsPredictingMovement(false)
            if data and data.pos then
                local pos = data.pos:GetPosition()
                inst:ForceFacePoint(pos.x, 0, pos.z)
            end

            inst.components.locomotor:Stop()
            -- inst.AnimState:PlayAnimation("slide_pre")
            -- inst.AnimState:PushAnimation("slide_loop", false)
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)

            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.last_dodge_time = GLOBAL.GetTime()
            inst.dodgetime:set(inst.dodgetime:value() == false and true or false)
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(2)
        end,
        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,
        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end
    }
)
