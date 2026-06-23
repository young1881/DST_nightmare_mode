--create placerpostinotprefab for palcer and create custom deployer canplace check
local assets =
{
	Asset("ANIM", "anim/winona_teleport_pad.zip"),
	Asset("ANIM", "anim/teleport_pad.zip"),
	Asset("ANIM", "anim/teleport_pad_beacon.zip"),

	Asset("ATLAS", "images/inventoryimages/winona_moving_box_item.xml"),
	Asset("IMAGE", "images/inventoryimages/winona_moving_box_item.tex"),
}

local assets_item =
{
	Asset("ANIM", "anim/winona_teleport_pad.zip"),
	Asset("ATLAS", "images/inventoryimages/winona_moving_box_item.xml"),
	Asset("IMAGE", "images/inventoryimages/winona_moving_box_item.tex"),
}

local prefabs =
{
	"collapse_small",
}
local prefabs_item =
{
	"winona_teleport_pad",
}

local deploy_state = ""

local function OnSave(inst, data)
	data.contents_rel_x = {}
	data.contents_rel_z = {}
	if inst.components.autobase_packer.contents_rel_x ~= nil and inst.components.autobase_packer.contents_rel_z ~= nil then
			data.contents_rel_x = inst.components.autobase_packer.contents_rel_x
			data.contents_rel_z = inst.components.autobase_packer.contents_rel_z
			data.deployspacing = inst.components.deployable.spacing
	end
end

local function OnLoad(inst, data)
	if data.contents_rel_x ~= nil and data.contents_rel_z ~= nil  then
--		TheNet:SystemMessage("load contents found", false)
			inst.components.autobase_packer.contents_rel_x = data.contents_rel_x
			inst.components.autobase_packer.contents_rel_z = data.contents_rel_z
			if data.deployspacing ~= nil then
				inst.components.deployable.spacing = data.deployspacing
			end
	end
end

local function OnCollapse2(item)
	item._collapsetask:Cancel()
	item._collapsetask = nil
	item.components.inventoryitem:SetOnPutInInventoryFn(nil)
	item.Transform:SetNoFaced()
	item.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
	item.AnimState:SetLayer(LAYER_WORLD)
	item.AnimState:SetSortOrder(0)
	item.AnimState:PlayAnimation("pad_collapse_pst")
	item.AnimState:PushAnimation("idle_ground", false)
end

local function ChangeToItem(inst)
	local item = SpawnPrefab("winona_moving_box_item")
	item.Transform:SetPosition(inst.Transform:GetWorldPosition())
	item.Transform:SetRotation(inst.Transform:GetRotation())
	item.Transform:SetEightFaced()
	item.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	item.AnimState:SetLayer(LAYER_BACKGROUND)
	item.AnimState:SetSortOrder(2)
	item.AnimState:PlayAnimation("pad_collapse")
	item._collapsetask = item:DoTaskInTime(6 * FRAMES, OnCollapse2) --anim actually has 8 frames, acting as a mini-lag anim for clients
	item.components.inventoryitem:SetOnPutInInventoryFn(OnCollapse2)
	for k = 1, inst.components.inventory.maxslots do
		local item2 = inst.components.inventory.itemslots[k]
		if item2 ~= nil and not item.components.inventory:IsFull() then
			local it = inst.components.inventory:RemoveItem(item2)
			-- item.replica.autobase_packer.contents_name[k] = item2.prefab.name
			item.components.inventory:GiveItem(item2)
			item.components.autobase_packer.contents_rel_x[k] = inst.components.autobase_packer.contents_rel_x[k]
			item.components.autobase_packer.contents_rel_z[k] = inst.components.autobase_packer.contents_rel_z[k]
			-- item.replica.autobase_packer.contents_rel_x[k] = inst.components.autobase_packer.contents_rel_x[k]
			-- item.replica.autobase_packer.contents_rel_z[k] = inst.components.autobase_packer.contents_rel_z[k]
		end
	end
	--TheNet:SystemMessage(item.GUID, false)
	if next(item.components.autobase_packer.contents_rel_x) ~= nil and next(item.components.autobase_packer.contents_rel_z) ~= nil then
		--deploy_state = "foo"
		item:AddTag("filled")
		item.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
	else
		--deploy_state = "fee"
		item:RemoveTag("filled")
		item.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
	end
	item.SoundEmitter:PlaySound("meta4/winona_teleumbrella/telepad_collapse")
end

local function BroadcastCircuitChanged(inst)  -- USE ONLY FOR update winona's machine
    local function NotifyCircuitChanged(inst, node)
        node:PushEvent("engineeringcircuitchanged")
    end
    local function UpdateCircuitPower(inst)
        inst._circuittask = nil
        if inst.components.fueled ~= nil then
            if inst.components.fueled.consuming then
                local load = 0
                inst.components.circuitnode:ForEachNode(function(inst, node)
                    local batteries = 0
                    node.components.circuitnode:ForEachNode(function(node, battery)
                        if battery.components.fueled ~= nil and battery.components.fueled.consuming then
                            batteries = batteries + 1
                        end
                    end)
                    load = load + 1 / batteries
                end)
                inst.components.fueled.rate = math.max(load, TUNING.WINONA_BATTERY_MIN_LOAD) * TUNING.WINONA_BATTERY_LOW_FUEL_RATE_MULT
            else
                inst.components.fueled.rate = 0
            end
        end
    end
    --Notify other connected nodes, so that they can notify their connected batteries
    inst.components.circuitnode:ForEachNode(NotifyCircuitChanged)
    if inst._circuittask ~= nil then
        inst._circuittask:Cancel()
    end
    UpdateCircuitPower(inst)
end




local function ForEachEngineering(inst)
	local pos_x,pos_y,pos_z = inst.Transform:GetWorldPosition()
	--NOTE: FindEntities is <= max range test
	local AUTOBASE_TAGS = { "structure", "engineering" }
	local AUTOBASE_NO_TAGS = { "burnt" }
	for i, v in ipairs(TheSim:FindEntities(pos_x, 0, pos_z, 4, AUTOBASE_TAGS, AUTOBASE_NO_TAGS)) do
        if v.prefab == "winona_battery_low" or v.prefab == "winona_battery_high" or 
               v.prefab == "winona_catapult" or v.prefab == "winona_spotlight" then -- then same as OnBurnt
            if v._inittask ~= nil then
                v._inittask:Cancel()
                v._inittask = nil
            end
            v.components.circuitnode:Disconnect()  -- disconnect will do everything properly
        end
		SpawnPrefab("die_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
		v.components.portablestructure:Dismantle(v)
	end
	--collects all items after dismantling
	local AUTOBASE_TAGS2 = { "portableitem" }
	local AUTOBASE_NO_TAGS2 = { "burnt", "INLIMBO" }
	for i, v in ipairs(TheSim:FindEntities(pos_x, 0, pos_z, 4, AUTOBASE_TAGS2, AUTOBASE_NO_TAGS2)) do
		local ent_x,ent_y,ent_z = v.Transform:GetWorldPosition()
        if v.components.deployable.restrictedtag == "handyperson" and v.prefab ~= "winona_moving_box_item" and v.components.inventoryitem.canbepickedup then
			inst.components.inventory:GiveItem(v,i)
			inst.components.autobase_packer.contents_rel_x[i] = ent_x-pos_x 
			inst.components.autobase_packer.contents_rel_z[i] = ent_z-pos_z 
		end
	end
end

local function OnDismantle(inst)--, doer)
	ForEachEngineering(inst)
	ChangeToItem(inst)
	

	
	if inst:IsAsleep() then
		inst:Remove()
		return
	end

	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end
	inst.components.workable:SetWorkable(false)
	inst:AddTag("NOCLICK")
	if inst.components.burnable then
		if inst.components.burnable:IsBurning() then
			inst.components.burnable:Extinguish()
		end
		inst.components.burnable.canlight = false
	end
	inst.persists = false

	inst.OnEntitySleep = inst.Remove
	inst:Remove()
--	inst.AnimState:PlayAnimation("pad_collapse_empty")

end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
end

local function onbuilt(inst, sound)

	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound(sound)
end

local function onremove(inst)
end



local function base()

local PLACER_SCALE = 2.1
	return function()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddMiniMapEntity():SetPriority(5)
		inst.MiniMapEntity:SetIcon("winona_moving_box_item.tex")
		inst:SetPhysicsRadiusOverride(4)
		inst:AddTag("structure")
		inst:AddTag("NOBLOCK")
		inst:AddTag("walkableperipheral")


		inst.AnimState:SetBank("teleport_pad")
		inst.AnimState:SetBuild("teleport_pad")
		inst.AnimState:PlayAnimation("idle")
		inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(3)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end
	
		inst:AddComponent("inspectable")
		inst:AddComponent("autobase_packer")

		inst.Transform:SetRotation(0)

		inst:AddComponent("lootdropper")
		inst:AddComponent("inventory")
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(4)
		inst.components.workable:SetOnFinishCallback(onhammered)
		
		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
		inst.components.pickable:SetUp("winona_moving_box_item", 10)
		inst.components.pickable.quickpick = true
		inst.components.pickable.remove_when_picked = true
		
		inst:AddComponent("portablestructure")
		inst.components.portablestructure:SetOnDismantleFn(OnDismantle)
		local sound_name = "hamletcharactersound/characters/wagstaff/telipad/telipad_1"

		inst:ListenForEvent("onbuilt", function () onbuilt(inst, sound_name) end)




		return inst
	end
end

local function OnBuilt2(inst, doer)
	inst:RemoveTag("NOCLICK")
end

-- local BOAT_MUST_TAGS = {"boat"}
-- local function CanDeployAtAutopackerCustom(inst, pt, mouseover, deployer, rot)
	-- -- if mouseover ~= nil and mouseover then
		-- -- if mouseover:HasTag("boat") then
			-- -- local boat = (mouseover ~= nil and mouseover:HasTag("boat") and mouseover) or nil
				-- -- if boat then
					-- -- local snap_point = boat:GetPosition()
					-- -- return true
				-- -- end
		-- -- end
	-- -- end
	
	
    -- local boat = (mouseover ~= nil and mouseover:HasTag("boat") and mouseover) or nil
    -- if not boat then
        -- boat = TheWorld.Map:GetPlatformAtPoint(pt.x,pt.z)

        -- -- If we're not standing on a boat, try to get the closest boat position via FindEntities()
        -- if not boat or not boat:HasTag("boat") then
            -- local boats = TheSim:FindEntities(pt.x, 0, pt.z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS, BOAT_MUST_TAGS)
            -- if #boats <= 0 then
                -- return false
            -- end
            -- boat = GetClosest(inst, boats)
        -- end
    -- end

    -- if not boat then return false end

    -- -- Check the outside rim to see if no objects are there
    -- local boatpos = boat:GetPosition()
    -- local boatangle = boat.Transform:GetRotation()

    -- -- Need to look a little outside of the boat edge here
    -- local boatringdata = boat.components.boatringdata
    -- local radius = (boatringdata and boatringdata:GetRadius() + 0.25) or 0
    -- local boatsegments = (boatringdata and boatringdata:GetNumSegments()) or 1

    -- local snap_point = GetCircleEdgeSnapTransform(boatsegments, radius, boatpos, pt, boatangle)
    -- return TheWorld.Map:CanDeployWalkablePeripheralAtPoint(snap_point, inst)
-- end

local function DoBuiltOrDeployed(inst, doer)
	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end
	inst:AddTag("NOCLICK")

	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound("meta4/winona_teleumbrella/telepad_deploy")
	inst:DoTaskInTime(8 * FRAMES, OnBuilt2, doer)

end

local function makefn(bankname, buildname, animname)
	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		inst:AddTag("DECOR")

		inst.AnimState:SetBank(bankname)
		inst.AnimState:SetBuild(buildname)
		inst.AnimState:PlayAnimation(animname)

		inst.placesound = "hamletcharactersound/characters/wagstaff/telipad/telipad_2"

		return inst
	end
	return fn
end

local function OnDeploy(inst, pt, deployer, rot)
	local obj = SpawnPrefab("winona_moving_box")
	if obj then
	    local boat = TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z)
        if boat == nil then
			obj.Transform:SetPosition(pt.x, 0, pt.z)
			obj.Transform:SetRotation(rot)
			DoBuiltOrDeployed(obj, deployer)
		else
			local boat_pos = boat:GetPosition()
			obj.Transform:SetPosition(boat_pos.x, 0, boat_pos.z)
			obj.Transform:SetRotation(rot)
			DoBuiltOrDeployed(obj, deployer)
        end

	end
	if inst.components.autobase_packer.contents_rel_x ~= nil and inst.components.autobase_packer.contents_rel_z ~= nil then
		for k = 1, inst.components.inventory.maxslots do
		local item = inst.components.inventory.itemslots[k]
			if item ~= nil then
				local pos2 = obj:GetPosition()
				pos2.x = pos2.x + inst.components.autobase_packer.contents_rel_x[k]
				pos2.z = pos2.z + inst.components.autobase_packer.contents_rel_z[k]
				item.components.deployable.mode = DEPLOYMODE.DEFAULT
				if item.components.deployable:CanDeploy(pos2, nil, deployer, rot) then
					--print("tried deploy success")
					item.components.deployable:Deploy(pos2, deployer, rot)
				else
					--print("tried deploy fail")
					local pos3 = obj:GetPosition()
					inst.components.inventory:DropItem(item, nil, false, pos3)
				end
			end
		end
	end
	inst:Remove()
end

	
local function itemfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst:SetDeploySmartRadius(0)
	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("winona_teleport_pad")
	inst.AnimState:SetBuild("winona_teleport_pad")
	inst.AnimState:PlayAnimation("idle_ground")
	inst.scrapbook_anim = "idle_ground"

	inst:AddTag("portableitem")
	
	MakeInventoryFloatable(inst, "large", 0.37, { 0.56, 0.91, 1 })

    if not TheWorld.ismastersim then
		return inst
    end

	inst:AddComponent("autobase_packer")

	inst:AddComponent("inspectable")
	inst:AddComponent("inventory")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.cangoincontainer = true
	inst.components.inventoryitem.atlasname = "images/inventoryimages/winona_moving_box_item.xml"
	inst.components.inventoryitem.imagename = "winona_moving_box_item"

	inst:AddComponent("deployable")
--	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
	inst.components.deployable.ondeploy = OnDeploy
	inst.components.deployable.restrictedtag = "handyperson"
	inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
--	inst._custom_candeploy_fn = CanDeployAtAutopackerCustom

	
	inst.OnSave = OnSave
    inst.OnLoad = OnLoad

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HUANT_TINY)
	


	MakeMediumBurnable(inst)
	MakeMediumPropagator(inst)

	return inst
end

local function item(name, bankname, buildname, animname)
	return Prefab(name, makefn(bankname, buildname, animname), assets)
end
			
local function placer_postinit_fn(inst)
	local active_item = ThePlayer.replica.inventory:GetActiveItem()
	if active_item.replica.autobase_packer then
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
		-- act_item_packer.contents_name = {}
		-- act_item_packer.contents_rel_x = {}
		-- act_item_packer.contents_rel_z = {}

		local function therestofthefuckingowl()
			local act_item_packer = active_item.replica.autobase_packer
			local items_list = act_item_packer.contents_name
			local packer_rel_x = act_item_packer.contents_rel_x
			local packer_rel_z = act_item_packer.contents_rel_z
			
			--SendModRPCToServer(GetModRPC("winonaboxRPC", "GetItemComponents"))
				--print("items obtained")	
			
			for i = 1, #items_list do
				local placer_string = items_list[i].."_placer"
				--print(placer_string)
				if PrefabExists(placer_string) then
					-- print("placer found")
					local new_ent = SpawnPrefab(placer_string)
					new_ent.entity:SetParent(inst.entity)
					new_ent.entity:SetCanSleep(TheWorld.ismastersim)
					new_ent.persists = false
					for _, v in ipairs(new_ent.components.placer.linked) do
						inst.components.placer:LinkEntity(v)	
					end
					--new_ent.AnimState:SetMultColour(.2, .2, .2, 1)
					new_ent:AddTag("FX")

					--print(placer_string..":"..packer_rel_x[i]..","..packer_rel_z[i])
					new_ent.Transform:SetPosition(packer_rel_x[i], 0, packer_rel_z[i])
					new_ent.Transform:SetScale(1/1.45, 1/1.45, 1/1.45)
					inst.components.placer:LinkEntity(new_ent)

				
				end		
			end
		end
		
		SendModRPCToServer(GetModRPC("winonaboxRPC", "GetItemComponents"))
		active_item:ListenForEvent("actitem_datadone", therestofthefuckingowl)

	end			
end

return
Prefab("winona_moving_box", base(), assets, prefabs),
MakePlacer("winona_moving_box_item_placer", "teleport_pad", "teleport_pad", "idle", true, nil, nil, 1.45, nil, nil, placer_postinit_fn),
Prefab("winona_moving_box_item", itemfn, assets_item, prefabs_item)
	