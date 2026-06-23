local assets =
{
    Asset("ANIM", "anim/lotus_book.zip"),
    Asset( "ATLAS", "images/inventoryimages/book_harvest.xml" ),
	Asset( "ATLAS_BUILD", "images/inventoryimages/book_harvest.xml", 256 ),
}
local reader

local book_defs =
{
	    {
        name = "book_harvest",
        uses = 6,
        read_sanity = -50,
        fn = function(inst, reader)
            reader.components.sanity:DoDelta(-50)
		local function tryharvest(inst) 
			local objc = inst.components 
			if objc.crop ~= nil 
				then objc.crop:Harvest(reader) 
			elseif objc.harvestable ~= nil 
				then objc.harvestable:Harvest(reader) 
			elseif objc.stewer ~= nil 
				then objc.stewer:Harvest(reader) 
			elseif objc.dryer ~= nil 
				then objc.dryer:Harvest(reader) 
			elseif objc.occupiable ~= nil and objc.occupiable:IsOccupied() 
				then local item = objc.occupiable:Harvest(reader) 
				if item ~= nil 
					then reader.components.inventory:GiveItem(item) 
				end 
			elseif objc.pickable ~= nil and objc.pickable:CanBePicked() 
				then objc.pickable:Pick(reader) 
			elseif objc.shelf ~= nil 
				then objc.shelf:TakeItem(reader)
			end
		end

		local x,y,z = reader.Transform:GetWorldPosition()
		
		local ents = TheSim:FindEntities(x,y,z, 30)
			for k, obj in pairs(ents) do
				if not obj:HasTag("reader") and not obj:HasTag("flower") and not obj:HasTag("mushroom_farm") and not obj:HasTag("trap") and not obj:HasTag("mine") and not obj:HasTag("cage") and obj ~= TheWorld and obj.AnimState and obj.components and obj.prefab and not string.find(obj.prefab, "mandrake") and not string.find(obj.prefab, "moonbase") and not string.find(obj.prefab,"gemsocket") then 
				tryharvest(obj)
				end
				if obj:HasTag("flower") and obj:HasTag("bush") then tryharvest(obj) end
				if obj:HasTag("lureplant_bait") then tryharvest(obj) end
			end
            return true
        end,
    },
}
local function MakeBook(def)
    --[[local morphlist = {}
    for i, v in ipairs(book_defs) do
        if v ~= def then
            table.insert(morphlist, v.name)
        end
    end]]

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("lotus_book")
		inst.AnimState:SetBuild("lotus_book")
		inst.AnimState:PlayAnimation("idle")
        inst:AddTag("book")
        inst:AddTag("bookcabinet_item")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------

        inst:AddComponent("inspectable")
        inst:AddComponent("book")
        inst.components.book.onread = def.fn

        inst:AddComponent("inventoryitem")

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(6)
        inst.components.finiteuses:SetUses(6)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/book_harvest.xml"

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.MED_FUEL

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)

        --MakeHauntableLaunchOrChangePrefab(inst, TUNING.HAUNT_CHANCE_OFTEN, TUNING.HAUNT_CHANCE_OCCASIONAL, nil, nil, morphlist)
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab( "common/inventory/book_harvest",fn, assets)
end

local books = {}
for i, v in ipairs(book_defs) do
    table.insert(books, MakeBook(v))
end
book_defs = nil
return unpack(books)