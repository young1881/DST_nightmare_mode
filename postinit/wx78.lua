local wx78_moduledefs = require("wx78_moduledefs")
local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
AddCreatureScanDataDefinition("bunnyman", "movespeed", 2)
AddCreatureScanDataDefinition("worm", "nightvision", 4)
AddCreatureScanDataDefinition("spider_dropper", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_hider", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_spitter", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_warrior", "maxhealth2", 4)
AddCreatureScanDataDefinition("otter", "music", 4)

AddRecipe2("wx78module_nightvision",
    { Ingredient("scandata", 4), Ingredient("wormlight", 2), Ingredient("mole", 1) },
    TECH.ROBOTMODULECRAFT_ONE, { builder_tag = "upgrademoduleowner" })

AddRecipe2("wx78module_music",
    { Ingredient("scandata", 4), Ingredient("slurtle_shellpieces", 2) },
    TECH.ROBOTMODULECRAFT_ONE, { builder_tag = "upgrademoduleowner" })


local function nightvision_onworldstateupdate(wx)
    wx:SetForcedNightVision(TheWorld.state.isnight and not TheWorld.state.isfullmoon)
end

local function nightvision_activate(inst, wx)
    wx._nightvision_modcount = (wx._nightvision_modcount or 0) + 1

    if wx._nightvision_modcount == 1 and TheWorld ~= nil and wx.SetForcedNightVision ~= nil then
        if TheWorld:HasTag("cave") then
            wx:SetForcedNightVision(true)
        else
            wx:WatchWorldState("isnight", nightvision_onworldstateupdate)
            wx:WatchWorldState("isfullmoon", nightvision_onworldstateupdate)
            nightvision_onworldstateupdate(wx)
        end
        wx:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
    end
end

local function nightvision_deactivate(inst, wx)
    wx._nightvision_modcount = math.max(0, wx._nightvision_modcount - 1)

    if wx._nightvision_modcount == 0 and TheWorld ~= nil and wx.SetForcedNightVision ~= nil then
        if TheWorld:HasTag("cave") then
            wx:SetForcedNightVision(false)
        else
            wx:StopWatchingWorldState("isnight", nightvision_onworldstateupdate)
            wx:StopWatchingWorldState("isfullmoon", nightvision_onworldstateupdate)
            wx:SetForcedNightVision(false)
        end
        wx:RemoveCameraExtraDistance(inst)
    end
end

AddPrefabPostInit("wx78module_nightvision", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    if inst.components.upgrademodule == nil then
        inst:AddComponent("upgrademodule")
    end
    inst.components.upgrademodule.onactivatedfn = nightvision_activate
    inst.components.upgrademodule.ondeactivatedfn = nightvision_deactivate
end)

local function music_sanityaura_fn(wx, observer)
    local num_modules = wx._music_modules or 1
    return TUNING.WX78_MUSIC_SANITYAURA * num_modules
end

local function music_sanityfalloff_fn(inst, observer, distsq)
    return 1
end

local MUSIC_PLAYLIST = {
    { path = "lumos/group1/jjsnw", handle = "wxmusic", duration = 217 },
    { path = "lumos/group1/tmg",   handle = "wxmusic", duration = 254 },
    { path = "lumos/group1/jjb",   handle = "wxmusic", duration = 78 },
    { path = "lumos/group1/zxmzf", handle = "wxmusic", duration = 288 },
    { path = "lumos/group1/ddb",   handle = "wxmusic", duration = 246 },
    { path = "lumos/group1/jbrs",  handle = "wxmusic", duration = 199 },
}

local MUSIC_TENDINGTAGS_MUST = { "farm_plant" }
local function music_update_fn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.WX78_MUSIC_TENDRANGE, MUSIC_TENDINGTAGS_MUST)
    for _, v in ipairs(ents) do
        if v.components.farmplanttendable ~= nil then
            v.components.farmplanttendable:TendTo(inst)
        end
    end

    SpawnPrefab("wx78_musicbox_fx").Transform:SetPosition(x, y, z)
end

local function get_random_track(wx)
    local last_index = wx._last_music_index
    local index

    if #MUSIC_PLAYLIST == 1 then
        index = 1
    else
        repeat
            index = math.random(#MUSIC_PLAYLIST)
        until index ~= last_index
    end

    wx._last_music_index = index
    return MUSIC_PLAYLIST[index]
end

local function play_random_music(wx)
    if not wx:IsValid() then
        return
    end

    wx.SoundEmitter:KillSound("wxmusic")

    local track = get_random_track(wx)
    wx.SoundEmitter:PlaySound(track.path, track.handle)

    if wx._music_task ~= nil then
        wx._music_task:Cancel()
    end
    wx._music_task = wx:DoTaskInTime(track.duration, function()
        play_random_music(wx)
    end)
end

local function music_activate(inst, wx)
    wx._music_modules = (wx._music_modules or 0) + 1
    wx.components.sanity.dapperness = wx.components.sanity.dapperness + TUNING.WX78_MUSIC_DAPPERNESS

    if wx._music_modules == 1 then
        if wx.components.sanityaura == nil then
            wx:AddComponent("sanityaura")
            wx.components.sanityaura.aurafn = music_sanityaura_fn
            wx.components.sanityaura.fallofffn = music_sanityfalloff_fn
            wx.components.sanityaura.max_distsq = TUNING.WX78_MUSIC_AURADSQ
        end

        if wx._tending_update == nil then
            wx._tending_update = wx:DoPeriodicTask(TUNING.WX78_MUSIC_UPDATERATE, music_update_fn, 1)
        end

        play_random_music(wx)
    elseif wx._music_modules == 2 then
        wx.SoundEmitter:SetParameter("wxmusic", "wathgrithr_intensity", 1)
    end
end

local function music_deactivate(inst, wx)
    wx._music_modules = math.max(0, wx._music_modules - 1)
    wx.components.sanity.dapperness = wx.components.sanity.dapperness - TUNING.WX78_MUSIC_DAPPERNESS

    wx.components.sanityaura.max_distsq = (wx._music_modules * TUNING.WX78_MUSIC_TENDRANGE) *
        (wx._music_modules * TUNING.WX78_MUSIC_TENDRANGE)

    if wx._music_modules == 0 then
        wx:RemoveComponent("sanityaura")

        if wx._tending_update ~= nil then
            wx._tending_update:Cancel()
            wx._tending_update = nil
        end

        wx.SoundEmitter:KillSound("wxmusic")
        if wx._music_task ~= nil then
            wx._music_task:Cancel()
            wx._music_task = nil
        end
    elseif wx._music_modules == 1 then
        wx.SoundEmitter:SetParameter("wxmusic", "wathgrithr_intensity", 0)
    end
end


AddPrefabPostInit("wx78module_music", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    if inst.components.upgrademodule == nil then
        inst:AddComponent("upgrademodule")
    end
    inst.components.upgrademodule.onactivatedfn = music_activate
    inst.components.upgrademodule.ondeactivatedfn = music_deactivate
end)


AddRecipe2("living_artifact",
    { Ingredient("gears", 2), Ingredient("transistor", 1), Ingredient("trinket_6", 3), Ingredient("bluegem", 2) },
    TECH.ANCIENT_FOUR,
    {
        atlas = "images/inventoryimages/living_artifact.xml",
        images = "living_artifact.tex",
        description = "living_artifact",
        builder_tag = "upgrademoduleowner"
    },
    { "CHARACTER" })

STRINGS.RECIPE_DESC.LIVING_ARTIFACT = "内核加速，恢复你的所有能量！"
TUNING.WX78_CHARGING_FOODS = {
    voltgoatjelly = 1,
    voltgoatjelly_spice_chili = 1,
    voltgoatjelly_spice_garlic = 1,
    voltgoatjelly_spice_sugar = 1,
    voltgoatjelly_spice_salt = 1,
    goatmilk = 1,
    living_artifact = 3
}

TUNING.WX78_SCANNER_MODULETARGETSCANTIME = 5
TUNING.WX78_SCANNER_MODULETARGETSCANTIME_EPIC = 10

local function ApplyElectricAttackBuff(inst)
    if not inst.components.debuffable then
        return
    end

    if inst.components.debuffable:HasDebuff("wx78_electricattack") then
        inst.components.debuffable:AddDebuff("wx78_electricattack", "wx78_electricattack")
    else
        inst.components.debuffable:AddDebuff("wx78_electricattack", "wx78_electricattack")
    end
end

local function OnInspirationRelease(inst)
    if inst.prefab == "wx78" and inst.components.upgrademoduleowner then
        if inst.components.upgrademoduleowner:IsChargeEmpty() then
            inst.components.talker:Say("能量已耗尽，无法启动！")
        else
            inst.components.upgrademoduleowner:AddCharge(-1)

            ApplyElectricAttackBuff(inst)
        end
    end
end

AddModRPCHandler("my_mod", "inspiration_release", function(inst)
    inst:PushEvent("custom_inspiration_release")

    if inst._music_modules ~= nil and inst._music_modules > 0 then
        play_random_music(inst)
    end
end)

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
    if GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.prefab == "wx78" and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
        SendModRPCToServer(MOD_RPC["my_mod"]["inspiration_release"])
    end
end)

local function CountItems(inst, prefab_name)
    if not inst.components.inventory then return 0 end
    local count = 0
    for k, v in pairs(inst.components.inventory.itemslots) do
        if v.prefab == prefab_name then
            count = count + (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1)
        end
    end
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.prefab == prefab_name then
            count = count + (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1)
        end
    end
    return count
end

local function UpdateChargeRegenTime(inst)
    if inst.prefab == "wx78" and inst.components.inventory ~= nil then
        local count = math.min(CountItems(inst, "trinket_6"), 40)

        local original_time = TUNING.WX78_CHARGE_REGENTIME
        inst.charge_regentime = original_time * (1 - (count / 40) * 0.6)
    end
end
local CHARGEREGEN_TIMERNAME = "chargeregenupdate"

local function OnUpgradeModuleChargeChanged(inst, data)
    -- The regen timer gets reset every time the energy level changes, whether it was by the regen timer or not.
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, inst.charge_regentime)

        -- If we just got put to 0 from a non-0 value, tell the player.
        if data.old_level ~= 0 and data.new_level == 0 then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_DISCHARGE"))
        end
    else
        -- If our charge is maxed (this is a post-assignment callback), and our previous charge was not,
        -- we just hit the max, so tell the player.
        if data.old_level ~= inst.components.upgrademoduleowner.max_charge then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE"))
        end
    end
end

local function OnBecameRobot(inst)
    --Override with overcharge light values
    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetIntensity(.9)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, inst.charge_regentime)
    end
end

local function OnFrozen(inst)
    if inst.components.freezable == nil or not inst.components.freezable:IsFrozen() then
        SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

        if not inst.components.upgrademoduleowner:IsChargeEmpty() then
            inst.components.upgrademoduleowner:AddCharge(-TUNING.WX78_FROZEN_CHARGELOSS)
        end
    end
end

local function StartMoistureImmunity(inst)
    if inst._moisture_task then
        inst._moisture_task:Cancel()
    end

    if inst._moisture_immunity_remover then
        inst:RemoveEventCallback("moisturedelta", inst._moisture_immunity_remover)
    end

    inst._moisture_immunity_remover = function()
        if inst._is_setting_moisture then return end

        inst._is_setting_moisture = true
        if inst.components.moisture then
            inst.components.moisture:SetMoistureLevel(0)
        end
        inst._is_setting_moisture = false
    end

    inst._moisture_immunity_remover()
    inst:ListenForEvent("moisturedelta", inst._moisture_immunity_remover)
    if inst.components.freezable ~= nil then
        inst.components.freezable.onfreezefn = nil
    end

    inst._moisture_task = inst:DoPeriodicTask(10, function()
        if inst._is_setting_moisture then return end

        inst._is_setting_moisture = true
        if inst.components.moisture then
            inst.components.moisture:SetMoistureLevel(0)
        end
        inst._is_setting_moisture = false
    end)

    inst:DoTaskInTime(300, function()
        if inst._moisture_task then
            inst._moisture_task:Cancel()
            inst._moisture_task = nil
        end
        if inst._moisture_immunity_remover then
            inst:RemoveEventCallback("moisturedelta", inst._moisture_immunity_remover)
            inst._moisture_immunity_remover = nil
        end
        inst._is_setting_moisture = nil

        if inst.components.freezable ~= nil then
            inst.components.freezable.onfreezefn = OnFrozen
        end

        inst.components.talker:Say("潮湿缓冲结束")
    end)

    inst.components.talker:Say("潮湿缓冲激活")
end


local function OnEatLivingArtifact(inst, data)
    if data and data.food and data.food.prefab == "living_artifact" then
        if inst.components.moisture then
            inst.components.moisture:SetMoistureLevel(0)
        end
        StartMoistureImmunity(inst)
    end
end

local function ChessDamageMultiplier(inst, target)
    if target and target:HasTag("chess") and not target:HasTag("laser_immune") then
        return 2.1
    end
    return 1
end

local function get_plugged_module_indexes(inst)
    local upgrademodule_defindexes = {}
    for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
        table.insert(upgrademodule_defindexes, module._netid)
    end

    -- Fill out the rest of the table with 0s
    while #upgrademodule_defindexes < TUNING.WX78_MAXELECTRICCHARGE do
        table.insert(upgrademodule_defindexes, 0)
    end

    return upgrademodule_defindexes
end

local function OnUpgradeModuleAdded(inst, moduleent)
    local slots_for_module = moduleent.components.upgrademodule.slots
    inst._chip_inuse = inst._chip_inuse + slots_for_module

    local upgrademodule_defindexes = get_plugged_module_indexes(inst)

    inst:PushEvent("upgrademodulesdirty", upgrademodule_defindexes)
    if inst.player_classified ~= nil then
        local newmodule_index = inst.components.upgrademoduleowner:NumModules()
        inst.player_classified.upgrademodules[newmodule_index]:set(moduleent._netid or 0)
    end
end

local function OnUpgradeModuleRemoved(inst, moduleent)
    inst._chip_inuse = inst._chip_inuse - moduleent.components.upgrademodule.slots

    -- If the module has 1 use left, it's about to be destroyed, so don't return it to the inventory.
    if moduleent.components.finiteuses == nil or moduleent.components.finiteuses:GetUses() > 1 then
        if moduleent.components.inventoryitem ~= nil and inst.components.inventory ~= nil then
            inst.components.inventory:GiveItem(moduleent, nil, inst:GetPosition())
        end
    end
end

local function OnOneUpgradeModulePopped(inst, moduleent)
    inst:PushEvent("upgrademodulesdirty", get_plugged_module_indexes(inst))
    if inst.player_classified ~= nil then
        -- This is a callback of the remove, so our current NumModules should be
        -- 1 lower than the index of the module that was just removed.
        local top_module_index = inst.components.upgrademoduleowner:NumModules() + 1
        inst.player_classified.upgrademodules[top_module_index]:set(0)
    end
end

local function OnAllUpgradeModulesRemoved(inst)
    SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

    inst:PushEvent("upgrademoduleowner_popallmodules")

    if inst.player_classified ~= nil then
        inst.player_classified.upgrademodules[1]:set(0)
        inst.player_classified.upgrademodules[2]:set(0)
        inst.player_classified.upgrademodules[3]:set(0)
        inst.player_classified.upgrademodules[4]:set(0)
        inst.player_classified.upgrademodules[5]:set(0)
        inst.player_classified.upgrademodules[6]:set(0)
    end
end

local function CanUseUpgradeModule(inst, moduleent)
    if (TUNING.WX78_MAXELECTRICCHARGE - inst._chip_inuse) < moduleent.components.upgrademodule.slots then
        return false, "NOTENOUGHSLOTS"
    else
        return true
    end
end

local WX78ModuleDefinitionFile = require("wx78_moduledefs")
local GetWX78ModuleByNetID = WX78ModuleDefinitionFile.GetModuleDefinitionFromNetID

local function CLIENT_CanUpgradeWithModule(inst, module_prefab)
    if module_prefab == nil then
        return false
    end

    local slots_inuse = (module_prefab._slots or 0)

    if inst.components.upgrademoduleowner ~= nil then
        for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
            local modslots = (module.components.upgrademodule ~= nil and module.components.upgrademodule.slots)
                or 0
            slots_inuse = slots_inuse + modslots
        end
    elseif inst.player_classified ~= nil then
        for _, module_netvar in ipairs(inst.player_classified.upgrademodules) do
            local module_definition = GetWX78ModuleByNetID(module_netvar:value())
            if module_definition ~= nil then
                slots_inuse = slots_inuse + module_definition.slots
            end
        end
    else
        return false
    end

    return (TUNING.WX78_MAXELECTRICCHARGE - slots_inuse) >= 0
end

local function CLIENT_CanRemoveModules(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner:NumModules() > 0
    elseif inst.player_classified ~= nil then
        -- Assume that, if the first module slot netvar is 0, we have no modules.
        return inst.player_classified.upgrademodules[1]:value() ~= 0
    else
        return false
    end
end

local function WX78Init(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    if inst.prefab ~= "wx78" then return end

    if inst.components.timer == nil then
        inst:AddComponent("timer")
    end
    if inst.components.upgrademoduleowner == nil then
        inst:AddComponent("upgrademoduleowner")
    end
    inst.components.upgrademoduleowner.onmoduleadded = OnUpgradeModuleAdded
    inst.components.upgrademoduleowner.onmoduleremoved = OnUpgradeModuleRemoved
    inst.components.upgrademoduleowner.ononemodulepopped = OnOneUpgradeModulePopped
    inst.components.upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
    inst.components.upgrademoduleowner.canupgradefn = CanUseUpgradeModule
    inst.components.upgrademoduleowner:SetChargeLevel(0)
    inst.charge_regentime = TUNING.WX78_CHARGE_REGENTIME

    inst.CanUpgradeWithModule = CLIENT_CanUpgradeWithModule
    inst.CanRemoveModules = CLIENT_CanRemoveModules

    inst:ListenForEvent("itemget", UpdateChargeRegenTime)
    inst:ListenForEvent("itemlose", UpdateChargeRegenTime)
    inst:ListenForEvent("custom_inspiration_release", OnInspirationRelease)
    inst:ListenForEvent("energylevelupdate", OnUpgradeModuleChargeChanged)
    inst:ListenForEvent("ms_respawnedfromghost", OnBecameRobot)
    OnBecameRobot(inst)

    inst:DoTaskInTime(0, function()
        if inst.components.combat then
            inst.components.combat.customdamagemultfn = ChessDamageMultiplier
        end
    end)

    inst:ListenForEvent("oneat", OnEatLivingArtifact)
end

AddPrefabPostInit("wx78", WX78Init)
