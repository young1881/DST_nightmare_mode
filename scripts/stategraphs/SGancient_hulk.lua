require("stategraphs/commonstates")

local SHAKE_DIST = 40
local BEAMRAD = 8
local function onattackedfn(inst, data)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy") and not inst._is_shielding then
            inst.sg:GoToState("hit")
    end
end

local function checkmine(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,10,{"ancient_hulk_mine"})
    if #ents < 12 then
        return true
    end
    return false
end



local function onattackfn(inst,data)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
            and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit"))
            and (data.target ~= nil and data.target:IsValid()) then
        local dsq_to_target = inst:GetDistanceSqToInst(data.target)
        if inst.canbarrier and not inst.components.timer:TimerExists("destroyer_cd")
                and dsq_to_target < 36 then
            inst.sg:GoToState("destroyer",data.target)
        elseif inst.angry and not inst.components.timer:TimerExists("spin_cd") and dsq_to_target < 36 then
            inst.sg:GoToState("spin", data.target)
        elseif not inst.components.timer:TimerExists("teleport_cd") then
            inst.sg:GoToState("teleportout_pre", data.target)
        else
            local attack_state = "atk_stab"
            if not inst.components.timer:TimerExists("bomb_cd")
                    and checkmine(inst) then
                attack_state = "bomb_pre"
            elseif dsq_to_target > 5.5*5.5 then
                --inst.sg.mem.lob_count=3
                attack_state = "lob"
            else
                attack_state = "attack"
            end
            inst.sg:GoToState(attack_state, data.target)
        end
    end
end

local function teleport(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local target=inst.components.combat.target
    if target~=nil then
        pt = Vector3(target.Transform:GetWorldPosition())
    end

    local theta = math.random() * 2 * PI

    local offset
    if target~=nil and inst:GetDistanceSqToPoint(pt:Get())>256 then
        offset = FindWalkableOffset(pt, theta, 3 + math.random()*2, 10, true)
    else
        offset = FindWalkableOffset(pt, theta, 10 + math.random()*4, 12, true)
    end
        --[[while not offset do
            offset = FindWalkableOffset(pt, theta, 12 + math.random()*5, 12, true) --12
        end]]
    local x1,y1,z1=inst.components.knownlocations:GetLocation("home"):Get()
    if offset and not inst.sg.mem.teleporthome then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    else
        pt.x=x1
        pt.z=z1
    end

    inst.Physics:SetActive(true)
    inst.Transform:SetPosition(pt.x,0,pt.z)
    --inst.sg:GoToState("telportin")
end


local function teleportcharge(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    local theta = inst.Transform:GetRotation() * DEGREES

    local offset=FindWalkableOffset(pt, theta, 4 + math.random()*4, 8, true)


        --[[while not offset do
            offset = FindWalkableOffset(pt, theta, 12 + math.random()*5, 12, true) --12
        end]]
    local x1,y1,z1=inst.components.knownlocations:GetLocation("home"):Get()
    if offset and not inst.sg.mem.teleporthome then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    else
        pt.x=x1
        pt.z=z1
    end
    inst.Physics:SetActive(true)
    inst.Transform:SetPosition(pt.x,0,pt.z)
    --inst.sg:GoToState("telportin")
end

local function launchprojectile(inst, dir)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    local theta = dir - (PI/6) + (PI/3*math.random())

    local offset = nil

        offset = FindWalkableOffset(pt, theta, 4 + math.random()*4, 10, true) --12

    if offset then
        pt.x = pt.x + offset.x
        pt.y=0
        pt.z = pt.z + offset.z
        inst:LaunchProjectile(pt)
    end
end

local function spawnburns(inst,rad,startangle,endangle,num)
    startangle = startangle *DEGREES
    endangle = endangle *DEGREES
    local pt = Vector3(inst.Transform:GetWorldPosition()) 
    --local down = TheCamera:GetDownVec()
    local angle = 0

    angle = angle + startangle
    local angdiff = (endangle-startangle)/num
    for i=1,num do
        local offset = Vector3(rad * math.cos( angle ), 0, rad * math.sin( angle ))
        local newpt = pt + offset      
        local fx = SpawnPrefab("laser")
        fx.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        local burn =  SpawnPrefab("laserscorch")
        burn.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        angle = angle + angdiff           
    end    
end

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "teleportout_pre"),
}

local events=
{
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", onattackfn),
    EventHandler("attacked", onattackedfn),
    EventHandler("activate", function(inst) inst.sg:GoToState("activate") end),
    EventHandler("stunned", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst:EnterShield()
        end
    end),
    EventHandler("stun_finished", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst:ExitShield()
        end
    end),
}

local function ShakeIfClose(inst)
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    --[[if player then
        player.components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, 3, SHAKE_DIST)
    end]]
    ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
end

local function ShakeIfClose_Footstep(inst)
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    --[[if player then
        player.components.playercontroller:ShakeCamera(inst, "FULL", 0.35, 0.02, 1.25, SHAKE_DIST)
    end]]
    ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
end



local states=
{

    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
            --[[local target=inst.components.combat.target
            if inst.wantstobarrier then
                inst.wantstobarrier = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("barrier")
                end
            elseif inst.wantstospin then
                inst.wantstospin = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("spin")
                end            
            elseif inst.wantstolob then
                inst.wantstolob = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("lob",target)
                end                
            elseif inst.wantstoteleport then
                inst.wantstoteleport = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("telportout_pre")
                end            
            elseif inst.wantstomine then
                inst.wantstomine = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("bomb_pre")
                end       
            end]]

        end,

        timeline=
        {
    ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )
            end),
            TimeEvent(46*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .5 )
            end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

    },

-------------------ACTIVATE--------------

    State{
        name = "activate",
        tags = {"busy"},

        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("activate")
            --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/gears_LP","gears")
        end,

        timeline=
        {
            ----start---
            TimeEvent(46*FRAMES, function(inst)  end),
            -----------gears loop--------------------
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.2 )
            end),
            TimeEvent(25*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.3 )
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.4 )
            end),
            TimeEvent(75*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 1 )
            end),

            TimeEvent(100*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .7 )
            end),

            ---------------electric--------------------
            TimeEvent(1*FRAMES, function(inst)  end),
            TimeEvent(4*FRAMES, function(inst)  end),
            TimeEvent(24*FRAMES, function(inst)  end),
            TimeEvent(27*FRAMES, function(inst)  end),
            TimeEvent(36*FRAMES, function(inst)  end),
            TimeEvent(39*FRAMES, function(inst)  end),
            TimeEvent(42*FRAMES, function(inst)  end),
            TimeEvent(65*FRAMES, function(inst)  end),
            TimeEvent(83*FRAMES, function(inst)  end),
            TimeEvent(86*FRAMES, function(inst)  end),
            TimeEvent(103*FRAMES, function(inst)  end),
            TimeEvent(106*FRAMES, function(inst)  end),
            TimeEvent(113*FRAMES, function(inst)  end),
        ---------------green lights--------------------
            TimeEvent(6*FRAMES, function(inst)  end),
            TimeEvent(10*FRAMES, function(inst)  end),
            TimeEvent(12*FRAMES, function(inst)  end),
            TimeEvent(20*FRAMES, function(inst)  end),
            TimeEvent(40*FRAMES, function(inst)  end),
            TimeEvent(44*FRAMES, function(inst)  end),
            TimeEvent(54*FRAMES, function(inst)  end),
            TimeEvent(56*FRAMES, function(inst)  end),
            TimeEvent(58*FRAMES, function(inst)  end),
            TimeEvent(60*FRAMES, function(inst)  end),
        -------------step---------------
            TimeEvent(37*FRAMES, function(inst)  end),
            TimeEvent(101*FRAMES, function(inst)  end),
        -------------servo---------------
            TimeEvent(28*FRAMES, function(inst)
                
            end),
            TimeEvent(46*FRAMES, function(inst)
                
            end),
            TimeEvent(64*FRAMES, function(inst)
                
            end),
            TimeEvent(84*FRAMES, function(inst)
                
            end),
            TimeEvent(128*FRAMES, function(inst)
                
            end),
    -------------tanut---------------
            TimeEvent(106*FRAMES, function(inst)  end),

        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

----------------------COMBAT------------------------


    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
          --  inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/hit")
            inst.AnimState:PlayAnimation("hit")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "canrotate"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_chomp")
        end,

        timeline=
        {
            TimeEvent(8*FRAMES, function(inst)  end),
            TimeEvent(22*FRAMES, function(inst)  end),
            TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("death_explode")
            RemovePhysicsColliders(inst)
        end,

        timeline=
        {
                    -------------green_explotion---------------
            TimeEvent(2*FRAMES, function(inst)
                -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .2})
            end),
            TimeEvent(6*FRAMES, function(inst)
                -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .3})
            end),
            TimeEvent(23*FRAMES, function(inst)
                -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .4})
            end),
            TimeEvent(26*FRAMES, function(inst)
               --  inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .6})
            end),
            TimeEvent(33*FRAMES, function(inst)
               --  inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .8})
            end),
            TimeEvent(36*FRAMES, function(inst)
                -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 1})
            end),
            ----gears loop_---
            TimeEvent(17*FRAMES, function (inst) inst.SoundEmitter:KillSound("gears") end),
            ----death voice----
            TimeEvent(17*FRAMES, function(inst)  end),
            TimeEvent(20*FRAMES, function(inst)  end),
            ---- explode---
            TimeEvent(61*FRAMES, function(inst)  end),
            TimeEvent(67*FRAMES, function(inst)  end),
            TimeEvent(77*FRAMES, function(inst) end),
            TimeEvent(79*FRAMES, function(inst) end),
            TimeEvent(82*FRAMES, function(inst)  end),

            TimeEvent(81*FRAMES, function(inst)
                    --[[local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
                    if player then
                        player.components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, 2, SHAKE_DIST)
                    end]]
                    local x,y,z = inst.Transform:GetWorldPosition()
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x+1, 0, z-1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x-1, 0, z+1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x+1, 0, z)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z+1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z-1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x-1, 0, z)

                    --GetWorld():DoTaskInTime(2,function()
                            --local head = SpawnPrefab("ancient_robot_head")
                            --head.spawntask:Cancel()
                            --head.spawntask = nil
                            --head.spawned = true
                            --head:AddTag("dormant")
                            --head.Transform:SetPosition(x,y+8,z)
                            --head.sg:GoToState("fall")
                        --end)
                    inst.DoDamage(inst, 6)
                    inst.components.lootdropper:DropLoot()
                    --inst.dropparts(inst,x,z)
                end),
        },
    },

    ------------- TELEPORT ----------------------------

    State{
        name = "teleportout_pre",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out_pre")
            inst.sg.statemem.target=inst.components.combat.target
        end,
        onupdate = function(inst)
			if inst.sg.statemem.target ~= nil then
				if inst.sg.statemem.target:IsValid() then
					inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				else
					inst.sg.statemem.target = nil
				end
			end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.cancharge and not inst.sg.mem.teleporthome then
                    inst.sg:GoToState("teleport_attack")
                else
                    inst.sg.mem.teleporthome=nil
                    inst.sg:GoToState("teleportout")
                end
            end),
        },

        timeline=
        {
                        ---teleport---
            TimeEvent(18*FRAMES, function(inst)  end),
                    -------------step---------------
            TimeEvent(9*FRAMES, function(inst)  end),
            TimeEvent(20*FRAMES, function(inst)  end),
        },
    },

    State{
        name = "teleportout",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out")
        end,

        timeline=
        {
                        -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                
            end),
            ----steps---
            TimeEvent(15*FRAMES, function(inst)  end),
            TimeEvent(16*FRAMES, function(inst)  end),
            TimeEvent(18*FRAMES, function(inst)  end),
            TimeEvent(39*FRAMES, function(inst)  end),
            ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )
            end),
            TimeEvent(5*FRAMES, function(inst)
                inst:DoDamage(5)
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.Physics:SetActive(false)
                inst.DynamicShadow:Enable(false)
                --inst.Physics:ClearCollisionMask()        
                inst:DoDamage(6)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst:DoDamage(8)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst:DoDamage(8)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst:Hide()
                teleport(inst)
                inst.sg:GoToState("teleportin")
                --inst:DoTaskInTime(0.5,function() teleport(inst)  end)
            end ),
        },
    },

    State{
        name = "teleportin",
        tags = {"busy"},

        onenter = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_in",true)

        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("teleport_cd",24)

                inst.sg:GoToState("idle")
            end ),
        },

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst)  end),
            -----------step---------------
            TimeEvent(15*FRAMES, function(inst)  end),
            TimeEvent(19*FRAMES, function(inst)  end),
            TimeEvent(16*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
            end),
            TimeEvent(17*FRAMES, function(inst)
                --GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, 2, 40)
                --ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
                inst.components.groundpounder:GroundPound()
            end),
            TimeEvent(19*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),
        },
    },
    State{
        name = "teleport_attack",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out")
            inst.sg:SetTimeout(1.2)
        end,


        timeline=
        {
                        -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                
            end),
            ----steps---
            TimeEvent(15*FRAMES, function(inst)
                
                teleportcharge(inst)
                inst:DoDamage(7)
            end),
            TimeEvent(16*FRAMES, function(inst)  end),
            TimeEvent(39*FRAMES, function(inst)
                
                teleportcharge(inst)
                inst:DoDamage(7)
            end),
            ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )
                teleportcharge(inst)
                inst:DoDamage(7)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.Physics:SetActive(false)
                inst.DynamicShadow:Enable(false)
                --inst.Physics:ClearCollisionMask()
                teleportcharge(inst)
                inst:DoDamage(6)
            end),
        },
        ontimeout=function(inst)
            inst:Hide()
            inst.sg:GoToState("teleportin")
        end,
    },
    --------------------- BOMBS -------------------------------

    State{
        name = "bomb_pre",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb")
            end ),
        },
        timeline=
        {
            -----rust----
            TimeEvent(16*FRAMES, function(inst)  end),
            TimeEvent(18*FRAMES, function(inst)  end),
            TimeEvent(20*FRAMES, function(inst)  end),
            TimeEvent(22*FRAMES, function(inst)  end),
            -----bomb ting----
            TimeEvent(18*FRAMES, function(inst)  end),
            TimeEvent(20*FRAMES, function(inst)  end),
            TimeEvent(22*FRAMES, function(inst)  end),
            TimeEvent(24*FRAMES, function(inst)  end),
            ----electro-----
            TimeEvent(12*FRAMES, function(inst)  end),
            TimeEvent(15*FRAMES, function(inst)  end),
            TimeEvent(19*FRAMES, function(inst)  end),
            TimeEvent(23*FRAMES, function(inst)  end),
        },
    },

    State{
        name = "bomb",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_loop")
        end,

        timeline=
        {   ---mine shoot---
            TimeEvent(4*FRAMES, function(inst)  end),
            TimeEvent(8*FRAMES, function(inst)  end),
            TimeEvent(12*FRAMES, function(inst)  end),
            TimeEvent(18*FRAMES, function(inst)  end),


            TimeEvent(1*FRAMES, function(inst)
                launchprojectile(inst, 0)
                launchprojectile(inst, PI*0.25)
            end),
            TimeEvent(6*FRAMES, function(inst)
                launchprojectile(inst, PI*0.5)
                launchprojectile(inst, PI*0.75)
            end),
            TimeEvent(11*FRAMES, function(inst)
                launchprojectile(inst, PI)
                launchprojectile(inst, PI*1.25)
            end),
            TimeEvent(16*FRAMES, function(inst)
                launchprojectile(inst, PI*1.5)
                launchprojectile(inst, PI*1.75)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb_pst")
            end ),
        },
    },

    State{
        name = "bomb_pst",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("bomb_cd",20)
                inst.sg:GoToState("idle")
            end ),
        },

        timeline=
        {
            -----rust----
            TimeEvent(6*FRAMES, function(inst)  end),
            TimeEvent(9*FRAMES, function(inst)  end),
            TimeEvent(11*FRAMES, function(inst)  end),
            TimeEvent(17*FRAMES, function(inst)  end),
            -----bomb ting----
            TimeEvent(8*FRAMES, function(inst)  end),
            TimeEvent(11*FRAMES, function(inst)  end),
            TimeEvent(13*FRAMES, function(inst)  end),
            TimeEvent(19*FRAMES, function(inst)  end),
             -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                 end),
        },
    },

---------------------------LOB---------------

    State{
        name = "lob",
        tags = {"busy","canrotate"},

        onenter = function(inst,target)

            inst.AnimState:PlayAnimation("atk_lob")
            if target~=nil and target:IsValid() then
                inst.sg.statemem.target = target
            end

            inst.components.locomotor:Stop()
        end,

        timeline =
        {
            TimeEvent(30*FRAMES, function(inst)
                if inst.sg.statemem.target~=nil and inst.sg.statemem.target:IsValid() then
                    inst.sg.statemem.targetpos=inst.sg.statemem.target:GetPosition()
                else
                    local angle = inst.Transform:GetRotation() * DEGREES
                    local offset = Vector3(15 * math.cos( angle ), 0, -15 * math.sin( angle ))
                    local pt = Vector3(inst.Transform:GetWorldPosition())
                    inst.sg.statemem.targetpos = Vector3(pt.x + offset.x,pt.y + offset.y,pt.z + offset.z)
                end
                inst:ShootProjectile(inst.sg.statemem.targetpos)
                if inst.angry then
                    local angle = inst.Transform:GetRotation() * DEGREES
                    local offset1 = Vector3(6 * math.cos( angle ), 0, -6 * math.sin( angle ))
                    local offset2 = Vector3(6 * math.cos( angle+PI/2 ), 0, -6 * math.sin( angle+PI/2 ))
                    local offset3 = Vector3(6 * math.cos( angle+PI ), 0, -6 * math.sin( angle+PI ))
                    local offset4 = Vector3(6 * math.cos( angle-PI/2 ), 0, -6 * math.sin( angle-PI/2 ))
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset1)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset2)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset3)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset4)
                end
                end),

            TimeEvent(0*FRAMES, function(inst)  end),
            TimeEvent(30*FRAMES, function(inst)
               -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity=math.random()})
            end),
        },

        onupdate = function(inst)
            if inst.sg.statemem.target~=nil and inst.sg.statemem.target:IsValid() then
                inst:ForceFacePoint(Vector3(inst.sg.statemem.target.Transform:GetWorldPosition()))
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                --[[if inst.sg.mem.lob_count ~= nil and inst.sg.mem.lob_count > 0 then
                    inst.sg.mem.lob_count=inst.sg.mem.lob_count-1
                    inst.sg:GoToState("lob",inst.sg.statemem.target)
                end]]
                inst.sg:GoToState("idle")
            end ),
        },
    },


----------------------SPIN--------------------

    State{
        name = "spin",
        tags = {"busy"},

        onenter = function(inst)
            --print("======= START ===============")
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_circle")
        end,

        timeline=
        {
            -------------step---------------
            TimeEvent(10*FRAMES, function(inst) end),
            TimeEvent(68*FRAMES, function(inst)  end),
            TimeEvent(70*FRAMES, function(inst)  end),
            TimeEvent(82*FRAMES, function(inst) end),
            TimeEvent(90*FRAMES, function(inst)  end),

            -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                
            end),
            TimeEvent(62*FRAMES, function(inst)
                
            end),
            ----electro-----
            TimeEvent(14*FRAMES, function(inst)
                
            end),
            TimeEvent(21*FRAMES, function(inst)
                
            end),
            TimeEvent(26*FRAMES, function(inst)
                
            end),
            ---------spin laser--------
            TimeEvent(30*FRAMES, function(inst)
                
            end),
            TimeEvent(30*FRAMES, function(inst)
               -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/burn_LP","laserburn")
            end),
            TimeEvent(49*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("laserburn")
            end),
            ---mix---
            TimeEvent(49*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),
             ---------spin laser ground--------
            TimeEvent(37*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,0,45)
                --inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0})
                spawnburns(inst,BEAMRAD,0,45,5)
            end),
            TimeEvent(39*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,45,90)
                spawnburns(inst,BEAMRAD,45,90,5)
            end),
            TimeEvent(40*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,90,135)
               -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .3})
                spawnburns(inst,BEAMRAD,90,135,5)
            end),
            TimeEvent(41*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,135,180)

                spawnburns(inst,BEAMRAD,135,180,5)
            end),
            TimeEvent(42*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,180,225)

              --  inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.5})
                spawnburns(inst,BEAMRAD,180,225,5)
            end),
            TimeEvent(45*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,225,270)

                spawnburns(inst,BEAMRAD,225,270,5)
            end),
            TimeEvent(47*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,270,315)
               -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.7})
                spawnburns(inst,BEAMRAD,270,315,5)
            end),
            TimeEvent(48*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,315,360)
                spawnburns(inst,BEAMRAD,315,360,5)
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,0,45)

               -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 1})
                spawnburns(inst,BEAMRAD,0,45,5)
            end),
            ---mix---
            TimeEvent(51*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),
        },


        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.components.timer:StartTimer("spin_cd",18)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },


----------------------DESTROYER--------------------

    State{
        name = "destroyer",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_barrier")
        end,            
        
        timeline=
        {        
            --step---
            TimeEvent(12*FRAMES, function(inst)  
            end),
            ---barrier attack---
            TimeEvent(19*FRAMES, function(inst)  
            end),

            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
            end),
            
            TimeEvent(67*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),

            TimeEvent(90*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),

            TimeEvent(64*FRAMES, function(inst)
                --GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, 2, 40)
                --ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
                inst.components.groundpounder:GroundPound()
                local pt = Vector3(inst.Transform:GetWorldPosition())
                inst:DoTaskInTime(0.6,function() inst.spawnbarrier(inst,pt) end)
                --local fx = SpawnPrefab("metal_hulk_ring_fx")
                --fx.Transform:SetPosition(pt.x,pt.y,pt.z)
                --fx.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
                --fx.AnimState:SetLayer( LAYER_BACKGROUND )
                --fx.AnimState:SetSortOrder( 2 )
            end),
        },

        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.barriertime = 10
        end, 

        events =
        {   
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("destroyer_cd",44)
                inst.sg:GoToState("idle")
            end ),        
        },
    },


---------------------------WALKING---------------

    State{
            name = "walk_start",
            tags = {"moving", "canrotate"},

            onenter = function(inst) 
                local anim = "walk_pre"
                inst.AnimState:PlayAnimation(anim)
            end,

            events =
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end ),        
            },
        },
        
    State{            
            name = "walk",
            tags = {"moving", "canrotate"},
            
            onenter = function(inst)
                local anim = "walk_loop"

                inst.AnimState:PlayAnimation(anim)

                inst.components.locomotor:WalkForward()
                if inst.components.combat and inst.components.combat.target and math.random() < .5 then
                    -- inst:DoTaskInTime(math.random(13)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/grrrr") end)
                end
            end,

            onupdate = function(inst)
                if inst.wantstolob then
                    inst.wantstolob = nil
                    if inst.components.combat.target then                                    
                        inst.sg:GoToState("lob")
                    end
                end
            end,

            events=
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end ),        
            },

            timeline=
            {
                TimeEvent(12*FRAMES, function(inst)
                    --DoFootstep(inst)
                end),
                TimeEvent(16*FRAMES, function(inst)
                    --DoFootstep(inst)
                end),
                TimeEvent(20*FRAMES, function(inst) 
                     end),
                TimeEvent(3*FRAMES, function(inst) 
                    end),
            
            },
        },        
    
    State{            
            name = "walk_stop",
            tags = {"canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                local anim = "walk_pst"
                --DoFootstep(inst)
                inst.AnimState:PlayAnimation(anim)
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        },

    State{
            name = "run_start",
            tags = {"moving", "running", "atk_pre", "canrotate"},

            onenter = function(inst) 
                inst.components.locomotor:RunForward()
                -- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt", "taunt")
                inst.AnimState:PlayAnimation("charge_pre")
            end,

            events =
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),        
            },
        },
        
    State{
            name = "run",
            tags = {"moving", "running", "canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:RunForward()
                -- if not inst.SoundEmitter:PlayingSound("taunt") then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt", "taunt") end
                inst.AnimState:PlayAnimation("charge_roar_loop")
            end,

            timeline=
            {
                -- TimeEvent(12*FRAMES, function(inst)
                --     DoFootstep(inst)
                --     destroystuff(inst)
                -- end),
                -- TimeEvent(16*FRAMES, function(inst)
                --     DoFootstep(inst)
                --     destroystuff(inst)
                -- end),
                -- TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/step") end),
            },   

            onupdate = function(inst)
                if inst.wantstolob then
                    inst.wantstolob = nil
                    if inst.components.combat.target then                                    
                        inst.sg:GoToState("lob")
                    end
                end
            end,

            events=
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),        
            },
        },        
    
    State{
            name = "run_stop",
            tags = {"canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                local should_softstop = false
                inst.AnimState:PlayAnimation("charge_pst")          
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        },

}

CommonStates.AddFrozenStates(states)
CommonStates.AddHitState(states)
return StateGraph("ancient_hulk", states, events, "idle")


