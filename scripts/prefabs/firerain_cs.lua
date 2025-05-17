local assets =
{
	Asset("ANIM", "anim/ia_meteor.zip"),
	Asset("ANIM", "anim/ia_meteor_shadow.zip")
}

local prefabs =
{
	"lavapool_cs",
    "groundpound_fx",
    "firerainshadow_cs",
    "burntground"
}

local easing = require("easing")

local VOLCANO_FIRERAIN_WARNING = 2
local SMASHABLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local SMASHABLE_TAGS = { "_combat", "_inventoryitem", "NPC_workable" }
for k, v in pairs(SMASHABLE_WORK_ACTIONS) do
    table.insert(SMASHABLE_TAGS, k.."_workable")
end
local NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "meteor_protection","FX" }

local function onexplode(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/meteor_impact")

    local x, y, z = inst.Transform:GetWorldPosition()

	local ents = TheSim:FindEntities(x, y, z, 4, nil, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
	for i, v in ipairs(ents) do
		--V2C: things "could" go invalid if something earlier in the list
		--     removes something later in the list.
		--     another problem is containers, occupiables, traps, etc.
		--     inconsistent behaviour with what happens to their contents
		--     also, make sure stuff in backpacks won't just get removed
		--     also, don't dig up spawners
		if v:IsValid() and not v:IsInLimbo() then
			if v.components.workable ~= nil then
				if v.components.workable:CanBeWorked() and not (v.sg ~= nil and v.sg:HasStateTag("busy")) then
					local work_action = v.components.workable:GetWorkAction()
					--V2C: nil action for NPC_workable (e.g. campfires)
					if (    (work_action == nil and v:HasTag("NPC_workable")) or
							(work_action ~= nil and SMASHABLE_WORK_ACTIONS[work_action.id]) ) and
						(work_action ~= ACTIONS.DIG
						or (v.components.spawner == nil and
							v.components.childspawner == nil)) then
						v.components.workable:WorkedBy(inst, inst.workdone or 20)
					end
				end
			elseif v.components.combat ~= nil then
				v.components.combat:GetAttacked(inst, 50)
			end
        end
	end
	if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 150)
    end
	SpawnPrefab("groundpound_fx").Transform:SetPosition(x, 0, z)
	inst:Remove()
end		



local function DoStep(inst)
	local _map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local pos = Vector3(x,y,z)

	if _map:IsVisualGroundAtPoint(x,0,z) then
		inst.SoundEmitter:PlaySound("ia/common/volcano/rock_smash")
		SpawnPrefab("lava_sinkhole").Transform:SetPosition(x, 0, z)
	else
		local platform = inst:GetCurrentPlatform()
		if platform ~= nil and platform:IsValid() and platform:HasTag("boat") then
			platform.components.health:DoDelta(-150)
			platform:PushEvent("spawnnewboatleak", {pt = pos, leak_size = "med_leak", playsoundfx = true})
		end
		SpawnAttackWaves(pos, 0, 2, 8,360)
        
	end
	onexplode(inst)
end

local function spawnshadow(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local shadow = SpawnPrefab("firerainshadow_cs")
	shadow.Transform:SetPosition(x,y,z)
	shadow.Transform:SetRotation(math.random(360))
end

local function StartStep(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	spawnshadow(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")

	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (7*FRAMES), DoStep)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (17*FRAMES), 
	function(inst)
		inst:Show()
		if TheWorld.Map:IsVisualGroundAtPoint(x,y,z) then
			inst.AnimState:PlayAnimation("egg_crash_pre")
		else
			inst.AnimState:PlayAnimation("idle")
		end
	end)
end

local function firerainfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()
	anim:SetBank("meteor")
	anim:SetBuild("ia_meteor")

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end
	inst:AddComponent("groundpounder")
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(200)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()

	return inst
end

local StartingScale = 2
local timetoimpact = 2

local function LerpIn(inst)
	local s = easing.inExpo(inst:GetTimeAlive(), 1, 1 - StartingScale, timetoimpact)

	inst.Transform:SetScale(s,s,s)
	if s >= StartingScale then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function OnRemove(inst)
	if inst.sizeTask~=nil then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end


local function shadowfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	local anim = inst.entity:AddAnimState()
	anim:SetBank("meteor_shadow")
	anim:SetBuild("ia_meteor_shadow")
	anim:PlayAnimation("idle")
	anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	anim:SetLayer(LAYER_BACKGROUND)
	anim:SetSortOrder(3)
	anim:SetScale(2,2,2)

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false
	
	
	
	inst:AddComponent("colourtweener")
	inst.AnimState:SetMultColour(0,0,0,0)
	inst.components.colourtweener:StartTween({0,0,0,1}, timetoimpact, inst.Remove)

	inst.OnRemoveEntity = OnRemove

	inst.sizeTask = inst:DoPeriodicTask(0.1, LerpIn)

	return inst
end


return Prefab("firerain_cs", firerainfn, assets, prefabs),
		Prefab("firerainshadow_cs", shadowfn, assets, prefabs)
