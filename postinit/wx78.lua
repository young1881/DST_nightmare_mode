-- STRINGS.RECIPE_DESC.WX78MODULE_MAXHEALTH = "扫描蜘蛛解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MAXHEALTH2 = "扫描蜘蛛战士、喷吐蜘蛛、穴居蜘蛛、洞穴蜘蛛解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MAXSANITY1 = "扫描蝴蝶或月娥解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MAXSANITY = "扫描各类影怪解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_BEE = "扫描蜂王解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MUSIC = "扫描水獭掠夺者、寄居蟹、帝王蟹解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MAXHUNGER1 = "扫描猎狗解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MAXHUNGER = "扫描熊獾、啜食者解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MOVESPEED = "扫描兔子、兔人解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_MOVESPEED2 = "扫描发条战车、损坏的发条战车或远古守护者解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_HEAT = "扫描红色猎犬、龙蝇解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_COLD = "扫描蓝色猎犬、独眼巨鹿解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_TASER = "扫描伏特羊解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_NIGHTVISION = "扫描鼹鼠、洞穴蠕虫解锁"
-- STRINGS.RECIPE_DESC.WX78MODULE_LIGHT = "扫描鱿鱼、球状光虫解锁"

AddRecipe2("wx78module_nightvision",
    { Ingredient("scandata", 4), Ingredient("wormlight", 2), Ingredient("lightbulb", 10) },
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
    inst:AddComponent("upgrademodule")
    inst.components.upgrademodule.onactivatedfn = nightvision_activate
    inst.components.upgrademodule.ondeactivatedfn = nightvision_deactivate
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

local function StartMoistureImmunity(inst)
    if inst._moisture_task then
        inst._moisture_task:Cancel()
    end

    if inst._moisture_immunity_remover then
        inst:RemoveEventCallback("moisturedelta", inst._moisture_immunity_remover)
    end

    inst._moisture_immunity_remover = function()
        if inst._is_setting_moisture then return end -- 防止递归调用

        inst._is_setting_moisture = true
        if inst.components.moisture then
            inst.components.moisture:SetMoistureLevel(0)
        end
        inst._is_setting_moisture = false
    end

    -- 初始清除一次湿度
    inst._moisture_immunity_remover()
    inst:ListenForEvent("moisturedelta", inst._moisture_immunity_remover)

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

local function WX78Init(inst)
    if inst.prefab ~= "wx78" then return end

    inst:AddComponent("timer")
    inst:AddComponent("upgrademoduleowner")
    inst.components.upgrademoduleowner:SetChargeLevel(0)
    inst.charge_regentime = TUNING.WX78_CHARGE_REGENTIME
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
