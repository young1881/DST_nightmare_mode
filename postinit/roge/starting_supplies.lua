-- roge/starting_supplies.lua
local STARTING_SUPPLY_OPTIONS = {
    {
        prefab = "wortox",
        state_key = "imp_supplies_enabled",
        items = {
            { prefab = "panflute", count = 1, unique = true },
        },
    },
    {
        prefab = "willow",
        state_key = "willow_supplies_enabled",
        items = {
            { prefab = "willow_ember", count = 20 },
        },
    },
    {
        prefab = "wathgrithr",
        state_key = "wigfrid_supplies_enabled",
        items = {
            { prefab = "battlesong_healthgain", count = 1 },
            { prefab = "battlesong_instant_revive", count = 1 },
        },
    },
    {
        prefab = "woodie",
        state_key = "woodie_supplies_enabled",
        items = {
            { prefab = "wereitem_moose", count = 2 },
        },
    },
    {
        prefab = "wanda",
        state_key = "wanda_supplies_enabled",
        items = {
            { prefab = "pocketwatch_heal", count = 1 },
            { prefab = "pocketwatch_revive", count = 1 },
        },
    },
	{
        prefab = "wolfgang",
        state_key = "wolfgang_supplies_enabled",
        items = {
            { prefab = "wolfgang_whistle", count = 1 },
        },
    },
	{
        prefab = "wendy",
        state_key = "wendy_supplies_enabled",
        items = {
            { prefab = "ghostlyelixir_slowregen", count = 1 },
        },
    },
	{
        prefab = "wickerbottom",
        state_key = "wickerbottom_supplies_enabled",
        items = {
            { prefab = 	"papyrus", count = 4 },
        },
    },
	{
        prefab = "wormwood",
        state_key = "wormwood_supplies_enabled",
        items = {
            { prefab = "halloweenpotion_health_small", count = 4 },
        },
    },
    {
        prefab = "wx78",
        state_key = "wx78_supplies_enabled",
        items = {
            { prefab = "wx78module_movespeed", count = 1 },
        },
    },
}

function IsRogeSupplyEnabled(state_key)
    local lobby_options = rawget(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS")
    return lobby_options ~= nil and lobby_options[state_key] == true
end

function CopyArray(src)
    local dst = {}
    for i, v in ipairs(src or {}) do
        dst[i] = v
    end
    return dst
end

function AddStartingInventoryItem(inst, prefab, unique)
    if unique then
        for _, item in ipairs(inst.starting_inventory) do
            if item == prefab then
                return
            end
        end
    end

    table.insert(inst.starting_inventory, prefab)
end

function AddStartingInventoryItems(inst, item_defs)
    inst.starting_inventory = CopyArray(inst.starting_inventory)

    for _, item_def in ipairs(item_defs) do
        local count = item_def.count or 1
        for i = 1, count do
            AddStartingInventoryItem(inst, item_def.prefab, item_def.unique)
        end
    end
end

function SetupRogeStartingSupplies(inst, option)
    if TheWorld == nil or not TheWorld.ismastersim then
        return
    end
    if inst == nil or inst.prefab ~= option.prefab then
        return
    end
    if not IsRogeSupplyEnabled(option.state_key) then
        return
    end

    if option.random_items ~= nil and #option.random_items > 0 then
        local pick = option.random_items[math.random(#option.random_items)]
        AddStartingInventoryItems(inst, { { prefab = pick, count = 1, unique = true } })
    elseif option.items ~= nil then
        AddStartingInventoryItems(inst, option.items)
    end
end

for _, option_def in ipairs(STARTING_SUPPLY_OPTIONS) do
    local option = option_def
    AddPrefabPostInit(option.prefab, function(inst)
        SetupRogeStartingSupplies(inst, option)
    end)
end
