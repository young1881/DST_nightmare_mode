local containers = require("containers")
local cooking = require("cooking")

local params = {}
local containers_widgetsetup_base = containers.widgetsetup

function containers.widgetsetup(container, prefab, data, ...)
	local t = params[prefab or container.inst.prefab]
	if t ~= nil then
		for k, v in pairs(t) do
			container[k] = v
		end
		container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
	else
		containers_widgetsetup_base(container, prefab, data, ...)
	end
end

--[[ 通用 ]] ---------------------------------------------------------------------------------

local lan = {
	chs = true,
	cht = true,
	zh = true,
	zht = true,
}

local chs = lan[LanguageTranslator.defaultlang]

local offset = -17

local function give_back_all_item(inst, doer)
	local items = inst.components.container:RemoveAllItems()

	for k, v in pairs(items) do
		v.prevslot = nil
		v.prevcontainer = nil

		if doer ~= nil and doer.components.inventory ~= nil then
			doer.components.inventory:GiveItem(v, nil, inst:GetPosition())
		else
			LaunchAt(v, inst, nil, 1, 1)
		end
	end
end

local function cookpot_itemtestfn(container, item, slot)
	if container.inst.iai_cookpot_widget ~= nil and container.inst.iai_cookpot_widget.itemtestfn ~= nil then
		return container.inst.iai_cookpot_widget.itemtestfn(container, item, slot)
	else
		return cooking.IsCookingIngredient(item.prefab) and not container.inst:HasTag("burnt")
	end
end

local function cookpot_buttonfn(inst, doer)
	if inst.iai_cookpot_widget ~= nil and inst.iai_cookpot_widget.widget ~= nil and inst.iai_cookpot_widget.widget.buttoninfo ~= nil and inst.iai_cookpot_widget.widget.buttoninfo.fn ~= nil then
		inst.iai_cookpot_widget.widget.buttoninfo.fn(inst, doer)
	else
		if inst.components.container ~= nil then
			BufferedAction(doer, inst, ACTIONS.COOK):Do()
		elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
			SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.COOK.code, inst, ACTIONS.COOK.mod_name)
		end
	end
end

local function cookpot_validfn(inst)
	if inst.iai_cookpot_widget ~= nil and inst.iai_cookpot_widget.widget ~= nil and inst.iai_cookpot_widget.widget.buttoninfo ~= nil and inst.iai_cookpot_widget.widget.buttoninfo.validfn ~= nil then
		return inst.iai_cookpot_widget.widget.buttoninfo.validfn(inst)
	else
		return inst.replica.container ~= nil and inst.replica.container:IsFull()
	end
end

local function spicer_itemtestfn(container, item, slot)
	if container.inst.iai_cookpot_widget ~= nil and container.inst.iai_cookpot_widget.itemtestfn ~= nil then
		return container.inst.iai_cookpot_widget.itemtestfn(container, item, slot)
	else
		return item.prefab ~= "wetgoop"
			and ((slot == 1 and item:HasTag("preparedfood") and not item:HasTag("spicedfood")) or
				(slot == 2 and item:HasTag("spice")) or
				(slot == nil and (item:HasTag("spice") or (item:HasTag("preparedfood") and not item:HasTag("spicedfood"))))
			)
			and not container.inst:HasTag("burnt")
	end
end

local spicer_buttonfn = cookpot_buttonfn

local spicer_validfn = cookpot_validfn

--[[ 单倍锅（批量按钮） ]] ---------------------------------------------------------------------------------

local iai_cookpot = {
	widget = {
		slotpos = {
			Vector3(0, 64 + 32 + 8 + 4 + offset, 0),
			Vector3(0, 32 + 4 + offset, 0),
			Vector3(0, -(32 + 4) + offset, 0),
			Vector3(0, -(64 + 32 + 8 + 4) + offset, 0),
		},
		animbank = "ui_cookpot_1x4",
		animbuild = "ui_cookpot_1x4",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo = {
			text = STRINGS.ACTIONS.COOK,
			position = Vector3(0, -165 + offset, 0),
		},
		buttoninfo_iai_cookstackfood = {
			text = "切换批量" or "Batch",
			position = Vector3(0, 165 + offset, 0),
		},
	},
	acceptsstacks = false,
	type = "cooker",
}

params.iai_cookpot = iai_cookpot
params.iai_cookpot.itemtestfn = cookpot_itemtestfn
params.iai_cookpot.widget.buttoninfo.fn = cookpot_buttonfn
params.iai_cookpot.widget.buttoninfo.validfn = cookpot_validfn

local function iai_cookpot_bfn(doer, inst)
	if inst.components.container ~= nil then
		give_back_all_item(inst, doer)

		inst.components.container:Close()
		inst.components.container:WidgetSetup("iai_cookpot_stack")

		if inst.iai_cookpot_type ~= nil then
			inst.iai_cookpot_type:set(true)
		end
	end
end

AddModRPCHandler("iai_cookpot", "iai_change_to_stackcook", iai_cookpot_bfn)

function params.iai_cookpot.widget.buttoninfo_iai_cookstackfood.fn(inst, doer)
	if TheWorld.ismastersim then
		iai_cookpot_bfn(doer, inst)
	else
		SendModRPCToServer(MOD_RPC["iai_cookpot"]["iai_change_to_stackcook"], inst)
	end
end

--[[ 批量锅（单倍按钮） ]] ---------------------------------------------------------------------------------

local iai_cookpot_stack = {
	widget = {
		slotpos = {
			Vector3(0, 64 + 32 + 8 + 4 + offset, 0),
			Vector3(0, 32 + 4 + offset, 0),
			Vector3(0, -(32 + 4) + offset, 0),
			Vector3(0, -(64 + 32 + 8 + 4) + offset, 0),
		},
		animbank = "ui_cookpot_1x4",
		animbuild = "ui_cookpot_1x4",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo = {
			text = STRINGS.ACTIONS.COOK,
			position = Vector3(0, -165 + offset, 0),
		},
		buttoninfo_iai_cookstackfood = {
			text = "切换单倍" or "Default",
			position = Vector3(0, 165 + offset, 0),
		},
	},
	acceptsstacks = true,
	type = "cooker",
}

params.iai_cookpot_stack = iai_cookpot_stack
params.iai_cookpot_stack.itemtestfn = cookpot_itemtestfn
params.iai_cookpot_stack.widget.buttoninfo.fn = cookpot_buttonfn
params.iai_cookpot_stack.widget.buttoninfo.validfn = cookpot_validfn

local function iai_cookpot_stack_bfn(doer, inst)
	if inst.components.container ~= nil then
		give_back_all_item(inst, doer)

		inst.components.container:Close()
		inst.components.container:WidgetSetup("iai_cookpot")

		if inst.iai_cookpot_type ~= nil then
			inst.iai_cookpot_type:set(false)
		end
	end
end

AddModRPCHandler("iai_cookpot", "iai_change_to_normalcook", iai_cookpot_stack_bfn)

function params.iai_cookpot_stack.widget.buttoninfo_iai_cookstackfood.fn(inst, doer)
	if TheWorld.ismastersim then
		iai_cookpot_stack_bfn(doer, inst)
	else
		SendModRPCToServer(MOD_RPC["iai_cookpot"]["iai_change_to_normalcook"], inst)
	end
end

--[[ 单倍调味站（批量按钮） ]] ---------------------------------------------------------------------------------

local iai_portablespicer = {
	widget = {
		slotpos = {
			Vector3(0, 32 + 4 + offset, 0),
			Vector3(0, -(32 + 4) + offset, 0),
		},
		slotbg = {
			{ image = "cook_slot_food.tex" },
			{ image = "cook_slot_spice.tex" },
		},
		animbank = "ui_cookpot_1x2",
		animbuild = "ui_cookpot_1x2",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo = {
			text = STRINGS.ACTIONS.SPICE,
			position = Vector3(0, -93 + offset, 0),
		},
		buttoninfo_iai_cookstackfood = {
			text = "切换批量" or "Batch",
			position = Vector3(0, 93 + offset, 0),
		},
	},
	acceptsstacks = false,
	usespecificslotsforitems = true,
	type = "cooker",
}

params.iai_portablespicer = iai_portablespicer
params.iai_portablespicer.itemtestfn = spicer_itemtestfn
params.iai_portablespicer.widget.buttoninfo.fn = spicer_buttonfn
params.iai_portablespicer.widget.buttoninfo.validfn = spicer_validfn

local function iai_portablespicer_bfn(doer, inst)
	if inst.components.container ~= nil then
		give_back_all_item(inst, doer)

		inst.components.container:Close()
		inst.components.container:WidgetSetup("iai_portablespicer_stack")

		if inst.iai_cookpot_type ~= nil then
			inst.iai_cookpot_type:set(true)
		end
	end
end

AddModRPCHandler("iai_portablespicer", "iai_change_to_stackcook", iai_portablespicer_bfn)

function params.iai_portablespicer.widget.buttoninfo_iai_cookstackfood.fn(inst, doer)
	if TheWorld.ismastersim then
		iai_portablespicer_bfn(doer, inst)
	else
		SendModRPCToServer(MOD_RPC["iai_portablespicer"]["iai_change_to_stackcook"], inst)
	end
end

--[[ 批量调味站（单倍按钮） ]] ---------------------------------------------------------------------------------

local iai_portablespicer_stack = {
	widget = {
		slotpos = {
			Vector3(0, 32 + 4 + offset, 0),
			Vector3(0, -(32 + 4) + offset, 0),
		},
		slotbg = {
			{ image = "cook_slot_food.tex" },
			{ image = "cook_slot_spice.tex" },
		},
		animbank = "ui_cookpot_1x2",
		animbuild = "ui_cookpot_1x2",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo = {
			text = STRINGS.ACTIONS.SPICE,
			position = Vector3(0, -93 + offset, 0),
		},
		buttoninfo_iai_cookstackfood = {
			text = "切换单倍" or "Default",
			position = Vector3(0, 93 + offset, 0),
		},
	},
	acceptsstacks = true,
	usespecificslotsforitems = true,
	type = "cooker",
}

params.iai_portablespicer_stack = iai_portablespicer_stack
params.iai_portablespicer_stack.itemtestfn = spicer_itemtestfn
params.iai_portablespicer_stack.widget.buttoninfo.fn = spicer_buttonfn
params.iai_portablespicer_stack.widget.buttoninfo.validfn = spicer_validfn

local function iai_portablespicer_stack_bfn(doer, inst)
	if inst.components.container ~= nil then
		give_back_all_item(inst, doer)

		inst.components.container:Close()
		inst.components.container:WidgetSetup("iai_portablespicer")

		if inst.iai_cookpot_type ~= nil then
			inst.iai_cookpot_type:set(true)
		end
	end
end

AddModRPCHandler("iai_portablespicer", "iai_change_to_normalcook", iai_portablespicer_stack_bfn)

function params.iai_portablespicer_stack.widget.buttoninfo_iai_cookstackfood.fn(inst, doer)
	if TheWorld.ismastersim then
		iai_portablespicer_stack_bfn(doer, inst)
	else
		SendModRPCToServer(MOD_RPC["iai_portablespicer"]["iai_change_to_normalcook"], inst)
	end
end

-----------------------------------------------------------------------------------

for k, v in pairs(params) do
	containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end
