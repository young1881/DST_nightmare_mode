-- 裂缝表吸入不可打断（须在 postinit 中注册 SG，不可放在 prefab 脚本里）

local PORTAL_RIFT_RADIUS = 5

local ROG_PORTAL_PULL_PROTECTED_STATES =
{
    jumpin = true,
    pocketwatch_portal_land = true,
    pocketwatch_portal_fallout = true,
}

local function RogePortalWrapPlayerFreezable(player)
    if player.components.freezable == nil or player._roge_portal_freezable_wrapped then
        return
    end
    player._roge_portal_freezable_wrapped = true
    local freezable = player.components.freezable
    local old_freeze = freezable.Freeze
    freezable.Freeze = function(self, ...)
        if self.inst._roge_portal_pull ~= nil then
            return
        end
        return old_freeze(self, ...)
    end
    local old_addcoldness = freezable.AddColdness
    freezable.AddColdness = function(self, ...)
        if self.inst._roge_portal_pull ~= nil then
            return
        end
        return old_addcoldness(self, ...)
    end
end

local function RogePortalWrapPlayerSleeper(player)
    if player.components.sleeper == nil or player._roge_portal_sleeper_wrapped then
        return
    end
    player._roge_portal_sleeper_wrapped = true
    local sleeper = player.components.sleeper
    local old_gotosleep = sleeper.GoToSleep
    sleeper.GoToSleep = function(self, ...)
        if self.inst._roge_portal_pull ~= nil then
            return
        end
        return old_gotosleep(self, ...)
    end
end

local function RogePortalRefreshImmunityTags(player)
    if player.sg == nil or player.sg.currentstate == nil then
        return
    end
    if not ROG_PORTAL_PULL_PROTECTED_STATES[player.sg.currentstate.name] then
        return
    end
    player.sg:AddStateTag("nointerrupt")
    player.sg:AddStateTag("nosleep")
end

local function RogePortalEndPullImmunity(player)
    if player._roge_portal_pull == nil then
        return
    end

    player._roge_portal_pull = nil
    player:RemoveTag("roge_portal_pulling")

    if player._roge_portal_immunity_task ~= nil then
        player._roge_portal_immunity_task:Cancel()
        player._roge_portal_immunity_task = nil
    end

    if player._roge_portal_newstate_fn ~= nil then
        player:RemoveEventCallback("newstate", player._roge_portal_newstate_fn)
        player._roge_portal_newstate_fn = nil
    end

    if player._roge_portal_pull_invincible and player.components.health ~= nil then
        if not (player.sg ~= nil and player.sg.statemem ~= nil and player.sg.statemem.isteleporting) then
            player.components.health:SetInvincible(false)
        end
        player._roge_portal_pull_invincible = nil
    end

    if player.components.freezable ~= nil and player.components.freezable:IsFrozen() then
        player.components.freezable:Unfreeze()
    end
    if player.components.sleeper ~= nil and player.components.sleeper:IsAsleep() then
        player.components.sleeper:WakeUp()
    end
    if player.Physics ~= nil then
        player.Physics:Stop()
    end
end

local function RogePortalIsRiftCaster(rift, player)
    if rift._roge_caster ~= nil and player == rift._roge_caster then
        return true
    end
    if rift._roge_caster_userid ~= nil and player.userid == rift._roge_caster_userid then
        return true
    end
    return false
end

local function RogePortalIsPlayerFrozen(player)
    if player.components.freezable ~= nil and player.components.freezable:IsFrozen() then
        return true
    end
    if player.sg ~= nil then
        if player.sg:HasStateTag("frozen") then
            return true
        end
        local state = player.sg.currentstate ~= nil and player.sg.currentstate.name or nil
        if state == "frozen" then
            return true
        end
    end
    return false
end

local function RogePortalCanPullPlayer(rift, player)
    if player == nil or not player:IsValid() or player:HasTag("playerghost") then
        return false
    end
    if RogePortalIsRiftCaster(rift, player) then
        return false
    end
    if RogePortalIsPlayerFrozen(player) then
        return false
    end
    if player.sg == nil then
        return false
    end
    local teleporter = rift.components.teleporter
    if teleporter == nil or not teleporter:IsActive() or teleporter.teleportees[player] then
        return false
    end
    if player.sg:HasStateTag("jumping") then
        return false
    end
    local state = player.sg.currentstate.name
    if state == "jumpin" or state == "jumpin_pre" or state == "pocketwatch_portal_land" or state == "pocketwatch_portal_fallout" then
        return false
    end
    local px, _, pz = player.Transform:GetWorldPosition()
    local rx, _, rz = rift.Transform:GetWorldPosition()
    return distsq(px, pz, rx, rz) <= PORTAL_RIFT_RADIUS * PORTAL_RIFT_RADIUS
end

local function RogePortalOnPullNewState(player)
    if player._roge_portal_pull == nil then
        return
    end

    local state = player.sg ~= nil and player.sg.currentstate ~= nil and player.sg.currentstate.name or nil
    if state == nil then
        return
    end

    if state == "idle" or state == "jumpout" then
        RogePortalEndPullImmunity(player)
        return
    end

    if ROG_PORTAL_PULL_PROTECTED_STATES[state] then
        RogePortalRefreshImmunityTags(player)
        return
    end

    local rift = player._roge_portal_pull
    if rift ~= nil and rift:IsValid() and RogePortalCanPullPlayer(rift, player) then
        player:DoTaskInTime(0, function()
            if player:IsValid() and player._roge_portal_pull == rift then
                player.sg:GoToState("jumpin", { teleporter = rift })
                RogePortalRefreshImmunityTags(player)
            end
        end)
    else
        RogePortalEndPullImmunity(player)
    end
end

local function RogePortalBeginPullImmunity(player, rift)
    RogePortalWrapPlayerFreezable(player)
    RogePortalWrapPlayerSleeper(player)

    player._roge_portal_pull = rift
    player:AddTag("roge_portal_pulling")

    if player.components.freezable ~= nil and player.components.freezable:IsFrozen() then
        player.components.freezable:Unfreeze()
    end
    if player.components.sleeper ~= nil and player.components.sleeper:IsAsleep() then
        player.components.sleeper:WakeUp()
    end
    if player.components.health ~= nil then
        player.components.health:SetInvincible(true)
        player._roge_portal_pull_invincible = true
    end
    if player.Physics ~= nil then
        player.Physics:Stop()
    end

    if player._roge_portal_newstate_fn == nil then
        player._roge_portal_newstate_fn = function(inst) RogePortalOnPullNewState(inst) end
        player:ListenForEvent("newstate", player._roge_portal_newstate_fn)
    end

    if player._roge_portal_immunity_task == nil then
        player._roge_portal_immunity_task = player:DoPeriodicTask(0, RogePortalRefreshImmunityTags, nil, player)
    end
end

GLOBAL.ROGE_PORTAL_PULL_IMMUNITY =
{
    BeginPullImmunity = RogePortalBeginPullImmunity,
    EndPullImmunity = RogePortalEndPullImmunity,
    RefreshImmunityTags = RogePortalRefreshImmunityTags,
}

local function RogePortalWrapSgEvent(sg, eventname, block_fn)
    for _, v in ipairs(sg.events) do
        if v.name == eventname then
            local old_fn = v.fn
            v.fn = function(inst, data)
                if block_fn(inst) then
                    return
                end
                return old_fn(inst, data)
            end
            return
        end
    end
end

local function RogePortalIsRogeRiftTeleport(data)
    return data ~= nil and data.teleporter ~= nil and data.teleporter.prefab == "roge_portal_rift"
end

local function RogePortalGetWereformBank(inst)
    if inst:HasTag("beaver") then
        return "werebeaver"
    elseif inst:HasTag("weremoose") then
        return "weremoose"
    elseif inst:HasTag("weregoose") then
        return "weregoose"
    end
    return nil
end

-- 动物形态 bank 无 jumpportal2_out；坠落动画期间临时切回 wilson，结束后还原
local function RogePortalWereformBeginFalloutVisual(inst)
    inst._roge_portal_wereform_skinmode = inst.overrideskinmode
    if inst.components.skinner ~= nil then
        inst.components.skinner:SetSkinMode("normal_skin")
    else
        inst.AnimState:SetBank("wilson")
    end
end

local function RogePortalWereformEndFalloutVisual(inst)
    local skinmode = inst._roge_portal_wereform_skinmode
    inst._roge_portal_wereform_skinmode = nil
    if skinmode ~= nil and inst.components.skinner ~= nil then
        inst.components.skinner:SetSkinMode(skinmode)
    else
        local bank = RogePortalGetWereformBank(inst)
        if bank ~= nil then
            inst.AnimState:SetBank(bank)
        end
        if inst:HasTag("weregoose") then
            inst.Transform:SetEightFaced()
        else
            inst.Transform:SetFourFaced()
        end
    end
end

local function RogePortalFinishJumpIn(inst)
    if inst.sg == nil or inst.sg.currentstate == nil or inst.sg.currentstate.name ~= "jumpin" then
        return
    end
    local target = inst.sg.statemem.target
    if target == nil or not target:IsValid() or target.components.teleporter == nil then
        inst.sg:GoToState("idle")
        return
    end
    target.components.teleporter:UnregisterTeleportee(inst)
    if target.components.teleporter:Activate(inst) then
        inst.sg.statemem.isteleporting = true
        if inst.components.health ~= nil then
            inst.components.health:SetInvincible(true)
        end
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(false)
        end
        inst:Hide()
        if inst.DynamicShadow ~= nil then
            inst.DynamicShadow:Enable(false)
        end
    else
        inst.sg:GoToState("jumpout")
    end
end

local function RogePortalWrapRiftTeleporter(inst)
    if not TheWorld.ismastersim or inst._roge_rift_teleporter_wrapped then
        return
    end
    local teleporter = inst.components.teleporter
    if teleporter == nil then
        return
    end
    inst._roge_rift_teleporter_wrapped = true
    local old_Activate = teleporter.Activate
    teleporter.Activate = function(self, doer)
        if doer ~= nil and doer:HasTag("playerghost") then
            return false
        end
        return old_Activate(self, doer)
    end
end

AddPrefabPostInit("roge_portal_rift", RogePortalWrapRiftTeleporter)

AddSimPostInit(function()
    local A = GLOBAL.ACTIONS
    if A == nil or A.JUMPIN == nil or A.JUMPIN.fn == nil or A.JUMPIN._roge_ghost_block_wrapped then
        return
    end
    local old_jumpin = A.JUMPIN.fn
    A.JUMPIN._roge_ghost_block_wrapped = true
    A.JUMPIN.fn = function(act)
        if act.doer ~= nil and act.doer:HasTag("playerghost")
            and act.target ~= nil and act.target.prefab == "roge_portal_rift" then
            return false
        end
        return old_jumpin(act)
    end
end)

local function RogePortalIsPullingPlayer(inst)
    return inst._roge_portal_pull ~= nil
end

AddStategraphPostInit("wilson", function(sg)
    local function block(inst)
        return RogePortalIsPullingPlayer(inst)
    end

    RogePortalWrapSgEvent(sg, "knockback", block)
    RogePortalWrapSgEvent(sg, "freeze", block)
    RogePortalWrapSgEvent(sg, "yawn", block)
    RogePortalWrapSgEvent(sg, "knockedout", block)
    RogePortalWrapSgEvent(sg, "snared", block)
    RogePortalWrapSgEvent(sg, "startled", block)
    RogePortalWrapSgEvent(sg, "repelled", block)

    local attacked_event
    for _, v in ipairs(sg.events) do
        if v.name == "attacked" then
            attacked_event = v
            break
        end
    end
    if attacked_event ~= nil then
        local old_attacked = attacked_event.fn
        attacked_event.fn = function(inst, data)
            if RogePortalIsPullingPlayer(inst) then
                if inst.SoundEmitter ~= nil then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                end
                return
            end
            return old_attacked(inst, data)
        end
    end

    local jumpin = sg.states.jumpin
    if jumpin ~= nil then
        local old_onenter = jumpin.onenter
        jumpin.onenter = function(inst, data)
            if RogePortalIsRogeRiftTeleport(data) then
                RogePortalBeginPullImmunity(inst, data.teleporter)
            end
            if old_onenter ~= nil then
                old_onenter(inst, data)
            end
            RogePortalRefreshImmunityTags(inst)
            if inst:HasTag("wereplayer") and RogePortalIsRogeRiftTeleport(data) then
                inst:DoTaskInTime(0, RogePortalFinishJumpIn)
            end
        end

        local old_onexit = jumpin.onexit
        jumpin.onexit = function(inst)
            if old_onexit ~= nil then
                old_onexit(inst)
            end
            if inst._roge_portal_pull ~= nil and not inst.sg.statemem.isteleporting then
                RogePortalEndPullImmunity(inst)
            end
        end
    end

    local land = sg.states.pocketwatch_portal_land
    if land ~= nil then
        local old_land_onenter = land.onenter
        land.onenter = function(inst, data)
            if inst:HasTag("wereplayer") then
                inst.sg:GoToState("pocketwatch_portal_fallout", data)
                return
            end
            if old_land_onenter ~= nil then
                old_land_onenter(inst, data)
            end
            if inst._roge_portal_pull ~= nil then
                RogePortalRefreshImmunityTags(inst)
            end
        end

        local old_land_onexit = land.onexit
        land.onexit = function(inst)
            if old_land_onexit ~= nil then
                old_land_onexit(inst)
            end
            if inst._roge_portal_pull ~= nil then
                RogePortalEndPullImmunity(inst)
            end
        end
    end

    local fallout = sg.states.pocketwatch_portal_fallout
    if fallout ~= nil then
        local old_fallout_onenter = fallout.onenter
        fallout.onenter = function(inst, data)
            if inst:HasTag("wereplayer") then
                RogePortalWereformBeginFalloutVisual(inst)
            end
            if old_fallout_onenter ~= nil then
                old_fallout_onenter(inst, data)
            end
            if inst._roge_portal_pull ~= nil then
                RogePortalRefreshImmunityTags(inst)
            end
        end

        local old_fallout_onexit = fallout.onexit
        fallout.onexit = function(inst)
            if inst._roge_portal_wereform_skinmode ~= nil then
                RogePortalWereformEndFalloutVisual(inst)
            end
            if old_fallout_onexit ~= nil then
                old_fallout_onexit(inst)
            end
            if inst._roge_portal_pull ~= nil then
                RogePortalEndPullImmunity(inst)
            end
        end
    end
end)
