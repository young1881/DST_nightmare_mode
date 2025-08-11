-- 移除电击带来的燃烧
local prefabs_to_patch = {
    "birchnutdrake",
    "butterfly",
    "carrat",
    "eyeplant",
    "fruitdragon",
    "lordfruitfly",
    "fruitfly",
    "friendlyfruitfly",
    "fruitflyfruit",
    "grassgator",
    "grassgekko",
    "hedgehound",
    "leif",
    "leif_sparse",
    "lightflier",
    "lunarthrall_plant",
    "lunarthrall_plant_vine",
    "lunarthrall_plant_vine_end",
    "lureplant",
    "mandrake_active",
    "moonbutterfly",
    "mushgnome",
    "waterplant",
    "wormwood_carrat",
    "wormwood_fruitdragon",
    "wormwood_lightflier",
}

for _, prefab in ipairs(prefabs_to_patch) do
    AddPrefabPostInit(prefab, function(inst)
        if inst.sg ~= nil and inst.sg.mem ~= nil then
            inst.sg.mem.burn_on_electrocute = false
        end
    end)
end

local function ClearStatusAilments(inst)
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
        inst.components.freezable:Unfreeze()
    end
    if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
        inst.components.pinnable:Unstick()
    end
end

local function ForceStopHeavyLifting(inst)
    if inst.components.inventory:IsHeavyLifting() then
        inst.components.inventory:DropItem(
            inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end
end

function GetCombatFxSize(ent)
    local r = ent.override_combat_fx_radius
    local sz = ent.override_combat_fx_size
    local ht = ent.override_combat_fx_height

    local r1 = r or ent:GetPhysicsRadius(0)
    if ent:HasTag("smallcreature") then
        r = r or math.min(0.5, r1)
        sz = sz or "tiny"
    elseif r1 >= 1.5 or ent:HasTag("epic") then
        r = r or math.max(1.5, r1)
        sz = sz or "large"
    elseif r1 >= 0.9 or ent:HasTag("largecreature") then
        r = r or math.max(1, r1)
        sz = sz or "med"
    else
        r = r or math.max(0.5, r1)
        sz = sz or "small"
    end

    if ht == nil then
        ht = (ent.components.amphibiouscreature and ent.components.amphibiouscreature.in_water and "low") or
            (ent:HasTag("flying") and "high") or
            (not (ent.sg and ent.sg:HasState("electrocute")) and "low") or --ground plants with no electrocute state
            nil
    elseif string.len(ht) == 0 then
        ht = nil
    end

    return r, sz, ht
end

local function StartFork(inst, target, x, y, z, r, data)
    if data.targets == nil then
        data.targets = { [target] = true }
    else
        data.targets[target] = true
    end
    inst:DoTaskInTime(TUNING.ELECTROCUTE_FORK_DELAY, DoFork, target, x, y, z, r, data)
end

function StartElectrocuteForkOnTarget(target, data)
    local x, y, z = target.Transform:GetWorldPosition()
    local r, _, _ = GetCombatFxSize(target)
    StartFork(target, target, x, y, z, r, data)
end

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound(
            (inst.talker_path_override or "dontstarve/characters/") .. (inst.soundsname or inst.prefab) .. "/hurt", nil,
            inst.hurtsoundvolume)
    end
end

AddStategraphPostInit("wilson", function(sg)
    local electrocute_state = sg.states["electrocute"]
    if electrocute_state then
        electrocute_state.onenter = function(inst, data)
            ClearStatusAilments(inst)
            if inst.components.grogginess then
                inst.components.grogginess:ResetGrogginess()
            end
            ForceStopHeavyLifting(inst)

            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.fx = SpawnPrefab(
                (not inst:HasTag("wereplayer") and "shock_fx") or
                (inst:HasTag("beaver") and "werebeaver_shock_fx") or
                (inst:HasTag("weremoose") and "weremoose_shock_fx") or
                "weregoose_shock_fx"
            )
            if inst.components.rider:IsRiding() then
                inst.fx.Transform:SetSixFaced()
            end
            inst.fx.entity:SetParent(inst.entity)
            inst.fx.entity:AddFollower()
            inst.fx.Follower:FollowSymbol(inst.GUID, "swap_shock_fx", 0, 0, 0)

            local isplant = inst:HasTag("plantkin")
            local isshort = isplant or
                (data ~= nil and data.duration ~= nil and data.duration <= TUNING.ELECTROCUTE_SHORT_DURATION)

            if not inst:HasTag("electricdamageimmune") then
                inst.components.bloomer:PushBloom("electrocute", "shaders/anim.ksh", -2)
                inst.Light:Enable(true)
                -- if isplant and not (data and data.noburn) then
                --     local attackdata = data and data.attackdata or data
                --     inst.components.burnable:Ignite(nil, attackdata and (attackdata.weapon or attackdata.attacker), attackdata and attackdata.attacker)
                -- end
            end

            if data then
                data =
                    data.attackdata and {
                        attackdata = data.attackdata,
                        targets = data.targets,
                        numforks = data.numforks and data.numforks - 1 or nil,
                    } or
                    data.stimuli == "electric" and {
                        attackdata = data,
                    } or
                    nil
                if data then
                    StartElectrocuteForkOnTarget(inst, data)
                end
            end

            inst.AnimState:PlayAnimation("shock")
            inst.AnimState:PushAnimation("shock_pst", false)
            if isshort then
                inst.AnimState:SetFrame(8)
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + (2 - 8) * FRAMES)
            else
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 4 * FRAMES)
            end

            DoHurtSound(inst)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end
    end
end)

-- 移除epic的电击僵直

local immune_prefabs = {
    shadoweyeturret = true,
    shadoweyeturret2 = true,
    malbatross = true,
    minotaur = true,
    dragonfly = true,
    beequeen = true,
    twinofterror1 = true,
    twinofterror2 = true,
    klaus = true,
    moose = true,
    eyeofterror = true,
    daywalker = true,
    daywalker2 = true,
    toadstool_dark = true,
    antlion = true,
    toadstool = true,
    bearger = true,
    leif = true,
    leif_sparse = true,
    spiderqueen = true,
    worm_boss = true,
    deerclops = true,
    mutateddeerclops = true,
    mutatedbearger = true,
    mutatedwarg = true,
}

local function AddNoElectrocute(inst)
    if inst.sg and inst.sg.mem then
        inst.sg.mem.noelectrocute = true
    end
    inst:AddTag("electricdamageimmune")
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.prefab and immune_prefabs[inst.prefab] then
        inst:DoTaskInTime(0, function()
            AddNoElectrocute(inst)
        end)
    end
end)

AddPrefabPostInit("daywalker", function(inst)
    if not TheWorld.ismastersim then return end

    AddNoElectrocute(inst)

    if inst.MakeChained then
        local oldMakeChained = inst.MakeChained
        inst.MakeChained = function(...)
            oldMakeChained(...)
            AddNoElectrocute(inst)
        end
    end

    if inst.MakeUnchained then
        local oldMakeUnchained = inst.MakeUnchained
        inst.MakeUnchained = function(...)
            oldMakeUnchained(...)
            AddNoElectrocute(inst)
        end
    end
end)
