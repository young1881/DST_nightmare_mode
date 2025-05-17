local extra_spell_num = 3

local function SpawnSpell(inst, x, z)
    local spell = SpawnPrefab(inst.castfx)
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(inst.castduration, spell.KillFX)
    return spell
end

local function SpawnSpells(inst, targets)
    local spells = {}
    for i, v in ipairs(targets) do
        if v:IsValid() and v:IsNear(inst, TUNING.DEER_GEMMED_CAST_MAX_RANGE) then
            local x, y, z = v.Transform:GetWorldPosition()
            table.insert(spells, SpawnSpell(inst, x, z))
            local angle_step = 360 / extra_spell_num
            local random_angle = 2 * PI * math.random()
            for n = 1, extra_spell_num do
                local angle = (n - 1) * angle_step
                local radian = math.rad(angle) + random_angle
                table.insert(spells, SpawnSpell(inst, x + 6 * math.cos(radian), z - 6 * math.sin(radian)))
            end
        end
    end
    return #spells > 0 and spells or nil
end

local function DoCast(inst, targets)
    local spells = targets ~= nil and SpawnSpells(inst, targets) or nil
    inst.components.timer:StopTimer("deercast_cd")
    inst.components.timer:StartTimer("deercast_cd", spells ~= nil and inst.castcd or TUNING.DEER_GEMMED_FIRST_CAST_CD)
    return spells
end

AddPrefabPostInit("deer_red", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.DoCast = DoCast
end)

AddPrefabPostInit("deer_blue", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.DoCast = DoCast
end)


local function HasSoul(victim)
    return not victim:HasAnyTag(SOULLESS_TARGET_TAGS)
        and not (victim.components.inventory ~= nil and victim.components.inventory:EquipHasTag("soul_protect"))
        and ((victim.components.combat ~= nil and victim.components.health ~= nil)
            or victim.components.murderable ~= nil)
end

local function SoulHunter(inst, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
    if target:IsValid() and HasSoul(target) and damageredirecttarget == nil then
        local soul = SpawnPrefab("klaus_soul_spawn")
        soul.Transform:SetPosition(target.Transform:GetWorldPosition())
        if target.components.mightiness ~= nil then
            target.components.mightiness:DoDelta(-8)
        end
        if target.components.sanity ~= nil then
            target.components.sanity:DoDelta(-5)
        end
        if inst.enraged and target.components.grogginess ~= nil then
            target.components.grogginess:AddGrogginess(0.5, 1)
        end
    end
end

local function DoWortoxPortalTint(inst, val)
    if val > 0 then
        inst.components.colouradder:PushColour("portaltint", 154 / 255 * val, 23 / 255 * val, 19 / 255 * val, 0)
        val = 1 - val
        inst.AnimState:SetMultColour(val, val, val, 1)
    else
        inst.components.colouradder:PopColour("portaltint")
        inst.AnimState:SetMultColour(1, 1, 1, 1)
    end
end

AddStategraphState("SGklaus",
    State {
        name = "hip_in",
        tags = { "busy", "attack", "nosleep", "nofreeze" },

        onenter = function(inst, targetpos)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("taunt1")
            inst.components.timer:StartTimer("hip_cd", 10)
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("wortox_portal_jumpin_fx").Transform:SetPosition(x, y, z)
            inst.sg:SetTimeout(11 * FRAMES)

            if targetpos ~= nil then
                inst.sg.statemem.dest = targetpos
                inst:ForceFacePoint(targetpos:Get())
            else
                inst.sg.statemem.dest = Vector3(x, y, z)
            end
        end,

        onupdate = function(inst)
            if inst.sg.statemem.tints ~= nil then
                DoWortoxPortalTint(inst, table.remove(inst.sg.statemem.tints))
                if #inst.sg.statemem.tints <= 0 then
                    inst.sg.statemem.tints = nil
                end
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .7)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.sg.statemem.tints = { 1, .6, .3, .1 }
            end),
            TimeEvent(4 * FRAMES, function(inst)
                inst.components.health:SetInvincible(true)
                inst.DynamicShadow:Enable(false)
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.portaljumping = true
            inst.sg:GoToState("attack_hip", inst.sg.statemem.dest)
        end,

        onexit = function(inst)
            if not inst.sg.statemem.portaljumping then
                inst.components.health:SetInvincible(false)
                inst.DynamicShadow:Enable(true)
                DoWortoxPortalTint(inst, 0)
            end
        end,
    })

AddStategraphState("SGklaus",
    State {
        name = "attack_hip",
        tags = { "busy", "attack", "nosleep", "nofreeze" },

        onenter = function(inst, dest)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
            if dest ~= nil then
                local offset =
                    FindWalkableOffset(dest, PI2 * math.random(), 1, 8, true, false) or
                    FindWalkableOffset(dest, PI2 * math.random(), 2, 8, true, false) or nil
                if offset ~= nil then
                    dest = dest + offset
                end
                inst:ForceFacePoint(dest)
                inst.Physics:Teleport(dest:Get())
            else
                dest = inst:GetPosition()
            end
            SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(dest:Get())
            inst.DynamicShadow:Enable(false)
            inst.sg:SetTimeout(14 * FRAMES)
            DoWortoxPortalTint(inst, 1)
            inst.components.health:SetInvincible(true)
            inst.soulcount = inst.soulcount - 1
        end,

        onupdate = function(inst)
            if inst.sg.statemem.tints ~= nil then
                DoWortoxPortalTint(inst, table.remove(inst.sg.statemem.tints))
                if #inst.sg.statemem.tints <= 0 then
                    inst.sg.statemem.tints = nil
                end
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out") end),
            TimeEvent(5 * FRAMES, function(inst)
                inst.sg.statemem.tints = { 0, .4, .7, .9 }
            end),
            TimeEvent(7 * FRAMES, function(inst)
                inst.components.health:SetInvincible(false)
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
            TimeEvent(8 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("quickattack")
        end,

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.DynamicShadow:Enable(true)
            DoWortoxPortalTint(inst, 0)
        end }
)

AddStategraphEvent("SGklaus",
    EventHandler("soul_hip", function(inst, target)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead())
            and target ~= nil and target:IsValid() then
            inst.sg:GoToState("hip_in", target:GetPosition())
        end
    end))

AddPrefabPostInit("klaus", function(inst)
    inst:AddTag("noteleport")
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("colouradder")
    inst.soulcount = 0

    inst.components.combat.onhitotherfn = SoulHunter
end)

local function ShouldHip(inst)
    return inst.soulcount >= 5 and inst.components.combat:HasTarget()
        and not inst.components.timer:TimerExists("hip_cd")
end

AddBrainPostInit("klausbrain", function(self)
    table.insert(self.bt.root.children, 3,
        WhileNode(function() return ShouldHip(self.inst) end, "SoulHip",
            ActionNode(function() self.inst:PushEvent("soul_hip", self.inst.components.combat.target) end)))
end)
