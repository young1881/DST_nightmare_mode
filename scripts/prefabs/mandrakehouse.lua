TUNING.MANDRAKEMAN_SPAWN_TIME = 480
TUNING.MANDRAKEMAN_ENABLED = true

STRINGS.CHARACTERS.GENERIC.DESCRIBE.MANDRAKEHOUSE = "这看起来...像什么东西在尖叫。"
-- STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MANDRAKEHOUSE = "有证据表明它是基于某种植物的类人生物。"
-- STRINGS.CHARACTERS.WALANI.DESCRIBE.MANDRAKEHOUSE = "我想知道它们是怎么睡觉的。"
STRINGS.CHARACTERS.WALTER.DESCRIBE.MANDRAKEHOUSE = "这就是魔法发生的地方吗？"
STRINGS.CHARACTERS.WANDA.DESCRIBE.MANDRAKEHOUSE = "看起来就很呐喊。"
STRINGS.CHARACTERS.WARLY.DESCRIBE.MANDRAKEHOUSE = "那些吵人的根用蔬菜住在这里面。"
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.MANDRAKEHOUSE = "它们被我逼的走投无路！"
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.MANDRAKEHOUSE = "啊。那是一个喧闹的家庭。"
STRINGS.CHARACTERS.WEBBER.DESCRIBE.MANDRAKEHOUSE = "我想那些吵闹的家伙住在那儿。"
STRINGS.CHARACTERS.WENDY.DESCRIBE.MANDRAKEHOUSE = "阿比盖尔也还活在土地里。"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.MANDRAKEHOUSE = "一个洞穴房子。"
-- STRINGS.CHARACTERS.WILBA.DESCRIBE.MANDRAKEHOUSE = "这些会动的蔬菜身上有臭味"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.MANDRAKEHOUSE = "恶心。"
STRINGS.CHARACTERS.WINONA.DESCRIBE.MANDRAKEHOUSE = "它被建造成尖叫脸的样子。"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MANDRAKEHOUSE = "植物人们的山丘。"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.MANDRAKEHOUSE = "这是那些植物伙计们住的地方。"
-- STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MANDRAKEHOUSE = "它们住的地方很矮。"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MANDRAKEHOUSE = "喂，有人吗？"
STRINGS.CHARACTERS.WORTOX.DESCRIBE.MANDRAKEHOUSE = "它们有自己的袋底洞。"
STRINGS.CHARACTERS.WURT.DESCRIBE.MANDRAKEHOUSE = "天花板还没有我高。"
STRINGS.CHARACTERS.WX78.DESCRIBE.MANDRAKEHOUSE = "侵略性可移动植物的大本营"
STRINGS.NAMES.MANDRAKEHOUSE = "曼德拉丘"



local assets =
{
    Asset("ANIM", "anim/elderdrake_house.zip"),
    Asset("MINIMAP_IMAGE", "elderdrake_house"),
}

local prefabs =
{
    "mandrakeman",
}

local function GetStatus(inst)
    if inst:HasTag("burnt") then -- missing quote!
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        return "FULL"
    end
end

local function OnVacate(inst, child)
    if not inst:HasTag("burnt") and child then
        if child.components.health then
            child.components.health:SetPercent(1)
        end
    end
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
    end

    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")
    inst:Remove()
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnBurntUp(inst, data)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
end

local function OnIgnite(inst, data)
    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
end

local function OnPhaseChange(inst, phase)
    if phase == "day" then
        return
    end

    if inst:HasTag("burnt") then
        return
    end

    if inst.components.spawner:IsOccupied() then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function() inst.components.spawner:ReleaseChild() end)
    end
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function OnPreLoad(inst, data)
    WorldSettings_Spawner_PreLoad(inst, data, TUNING.MANDRAKEMAN_SPAWN_TIME)
end

local function OnLoad(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("elderdrake_house")
    inst.AnimState:SetBuild("elderdrake_house")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

    inst.MiniMapEntity:SetIcon("elderdrake_house.tex")

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("structure")
    inst:AddTag("elderdrake_house")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("spawner")
    WorldSettings_Spawner_SpawnDelay(inst, TUNING.MANDRAKEMAN_SPAWN_TIME, TUNING.MANDRAKEMAN_ENABLED)
    inst.components.spawner:Configure("mandrakeman", TUNING.MANDRAKEMAN_SPAWN_TIME)
    inst.components.spawner.onvacate = OnVacate

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    MakeHauntable(inst)

    inst:ListenForEvent("burntup", OnBurntUp)
    inst:ListenForEvent("onignite", OnIgnite)

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad
    inst.OnLoad = OnLoad

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    return inst
end

return Prefab("mandrakehouse", fn, assets, prefabs)
