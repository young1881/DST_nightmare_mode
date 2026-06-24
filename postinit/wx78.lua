local wx78_moduledefs = require("wx78_moduledefs")
local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
local GetCreatureScanDataDefinition = wx78_moduledefs.GetCreatureScanDataDefinition

AddCreatureScanDataDefinition("bunnyman", "movespeed", 2)
AddCreatureScanDataDefinition("worm", "nightvision", 4)
AddCreatureScanDataDefinition("spider_dropper", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_hider", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_spitter", "maxhealth2", 4)
AddCreatureScanDataDefinition("spider_warrior", "maxhealth2", 4)
AddCreatureScanDataDefinition("otter", "music", 4)

-- Spin-Cycle circuit: scan mushgnome instead of mossling
AddCreatureScanDataDefinition("mushgnome", "spin", 6)
for _, prefab in ipairs({ "mossling", "mosling" }) do
    local scan = GetCreatureScanDataDefinition(prefab)
    if scan ~= nil and scan.module == "spin" then
        AddCreatureScanDataDefinition(prefab, "spin", 0)
    end
end

-- 电气化电路：扫描远古蜈蚣壳解锁（替代伏特羊）
AddCreatureScanDataDefinition("archive_centipede_husk", "taser", 5)
AddCreatureScanDataDefinition("lightninggoat", "taser", 0)

AddRecipePostInit("wx78module_taser", function(recipe)
    recipe.ingredients = {
        Ingredient("scandata", 5),
        Ingredient("purebrilliance", 1),
    }
end)

AddRecipePostInit("wx78module_spin", function(recipe)
    recipe.ingredients = {
        Ingredient("scandata", 5),
        Ingredient("livinglog", 2),
    }
end)

-- WX-78 专属：12 壳碎片 + 1 花环 + 24 铥矿碎片 → 尖壳头盔（用于格挡电路等材料）
AddCharacterRecipe("slurtlehat_wx78",
    { Ingredient("slurtle_shellpieces", 12), Ingredient("flowerhat", 1), Ingredient("thulecite_pieces", 24) },
    TECH.SCIENCE_TWO,
    {
        product = "slurtlehat",
        builder_tag = "upgrademoduleowner",
    },
    { "ARMOUR" })

AddPrefabPostInit("archive_centipede_husk", function(inst)
    if not inst:HasTag("largecreature") then
        inst:AddTag("largecreature")
    end
end)

AddRecipe2("wx78module_nightvision",
    { Ingredient("scandata", 4), Ingredient("wormlight", 2), Ingredient("mole", 1) },
    TECH.ROBOTMODULECRAFT_ONE, { builder_tag = "upgrademoduleowner" })

AddRecipe2("wx78module_music",
    { Ingredient("scandata", 4), Ingredient("slurtle_shellpieces", 2) },
    TECH.ROBOTMODULECRAFT_ONE, { builder_tag = "upgrademoduleowner" })


local function nightvision_onworldstateupdate(wx)
    local playervision = wx.components ~= nil and wx.components.playervision or nil
    if playervision == nil then
        return
    end

    local enabled = TheWorld ~= nil
        and (TheWorld:HasTag("cave") or (TheWorld.state.isnight and not TheWorld.state.isfullmoon))

    if enabled then
        playervision:PushForcedNightVision(wx, 0)
        playervision.islegitnightvision = true
    else
        playervision:PopForcedNightVision(wx)
    end
end

local function nightvision_activate(inst, wx)
    wx._nightvision_modcount = (wx._nightvision_modcount or 0) + 1

    if wx._nightvision_modcount == 1 and TheWorld ~= nil then
        wx:WatchWorldState("isnight", nightvision_onworldstateupdate)
        wx:WatchWorldState("isfullmoon", nightvision_onworldstateupdate)
        nightvision_onworldstateupdate(wx)
        wx:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
    end
end

local function nightvision_deactivate(inst, wx)
    wx._nightvision_modcount = math.max(0, wx._nightvision_modcount - 1)

    if wx._nightvision_modcount == 0 and TheWorld ~= nil then
        wx:StopWatchingWorldState("isnight", nightvision_onworldstateupdate)
        wx:StopWatchingWorldState("isfullmoon", nightvision_onworldstateupdate)
        if wx.components ~= nil and wx.components.playervision ~= nil then
            wx.components.playervision:PopForcedNightVision(wx)
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
        local umo = inst.components.upgrademoduleowner
        if umo ~= nil then
            umo:SetChargeLevel(umo.max_charge)
        end
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

    if not TheWorld.ismastersim then
        return inst
    end

    inst.charge_regentime = TUNING.WX78_CHARGE_REGENTIME

    inst:ListenForEvent("itemget", UpdateChargeRegenTime)
    inst:ListenForEvent("itemlose", UpdateChargeRegenTime)
    inst:ListenForEvent("custom_inspiration_release", OnInspirationRelease)
    inst:ListenForEvent("oneat", OnEatLivingArtifact)

    inst:DoTaskInTime(0, function()
        if inst.components.combat then
            inst.components.combat.customdamagemultfn = ChessDamageMultiplier
        end
    end)
end

AddPrefabPostInit("wx78", WX78Init)

--------------------------------------------------------------------------------
-- 旋转电路：手持任意近战武器也可旋转（移植自 better_wx78 / wx78_spin_rework.lua）
--------------------------------------------------------------------------------
require("components/dynamicmusic")

local WX78Common = require("prefabs/wx78_common")

local NM_WX_SPIN_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "decor", "intense", "companion", "flight", "invisible", "notarget", "noattack", "daywalker_pillar" }
local NM_WX_SPIN_ONEOF_TAGS = { "CHOP_workable", "MINE_workable", "LunarBuildup", "_combat", "plant", "lichen", "oceanvine", "kelp" }
local NM_WX_SPIN_PICKABLE_TAGS = { "plant", "lichen", "oceanvine", "kelp" }

local function NM_GetItemOwner(item)
    local inventoryitem = item ~= nil and item.components ~= nil and item.components.inventoryitem or nil
    if inventoryitem ~= nil and inventoryitem.owner ~= nil then
        return inventoryitem.owner
    end

    local replica_inventoryitem = item ~= nil and item.replica ~= nil and item.replica.inventoryitem or nil
    return replica_inventoryitem ~= nil
        and replica_inventoryitem.GetGrandOwner ~= nil
        and replica_inventoryitem:GetGrandOwner()
        or nil
end

local function NM_HasSpinAbility(inst)
    return inst ~= nil
        and inst.GetModuleTypeCount ~= nil
        and (inst:GetModuleTypeCount("spin") or 0) > 0
end

local function NM_IsSpinTool(item)
    if item == nil then
        return false
    end

    if TheWorld ~= nil and TheWorld.ismastersim then
        local tool = item.components ~= nil and item.components.tool or nil
        return tool ~= nil
            and (tool:CanDoAction(ACTIONS.CHOP) or tool:CanDoAction(ACTIONS.MINE))
    end

    return item:HasAnyTag("CHOP_tool", "MINE_tool")
end

local function NM_IsMeleeWeapon(item)
    if item == nil then
        return false
    end

    if TheWorld ~= nil and TheWorld.ismastersim then
        local components = item.components
        local weapon = components ~= nil and components.weapon or nil
        if weapon == nil then
            return false
        end

        return components.projectile == nil
            and weapon.projectile == nil
            and (components.complexprojectile == nil or components.complexprojectile.ismeleeweapon)
            and not item:HasAnyTag("projectile", "rangedweapon", "slingshot")
    end

    return item:HasTag("weapon")
        and not item:HasAnyTag("projectile", "rangedweapon", "slingshot")
end

local function NM_CanSpinUsingItem(item)
    if item == nil then
        return false
    end

    if not NM_HasSpinAbility(NM_GetItemOwner(item)) then
        return false
    end

    return NM_IsSpinTool(item) or NM_IsMeleeWeapon(item)
end

local function NM_EnsureSpinComponents(wx)
    if wx == nil or TheWorld == nil or not TheWorld.ismastersim or wx.components == nil then
        return
    end

    if wx.components.efficientuser == nil then
        wx:AddComponent("efficientuser")
    end

    if wx.components.aoediminishingreturns == nil then
        wx:AddComponent("aoediminishingreturns")
    end
end

local function NM_GetLocalAnalogDir(inst)
    if inst.HUD ~= nil and inst.components.playercontroller ~= nil then
        local isenabled, ishudblocking = inst.components.playercontroller:IsEnabled()
        if isenabled or ishudblocking then
            local xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
            local ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
            local deadzone = TUNING.CONTROLLER_DEADZONE_RADIUS
            if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
                local dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
                return dir:Normalize()
            end
        end
    end
end

local function NM_WXSpinOnUpdate(inst, dt)
    if not NM_HasSpinAbility(inst) then
        if inst.components.combat ~= nil then
            inst.components.combat.ignorehitrange = false
        end
        if inst.sg.statemem.anim ~= nil then
            inst.AnimState:PlayAnimation(inst.sg.statemem.anim)
            inst.AnimState:SetFrame(1)
            inst.AnimState:PushAnimation("wx_spin_attack_pst", false)
        end
        inst.sg:GoToState("idle", true)
        return
    end

    if inst.sg.statemem.targets then
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local canchop, canmine
        if item ~= nil and item.components.tool ~= nil then
            canchop = item.components.tool:CanDoAction(ACTIONS.CHOP)
            canmine = item.components.tool:CanDoAction(ACTIONS.MINE)
        end

        local canwork = canchop or canmine
        local canattackonly = not canwork and NM_IsMeleeWeapon(item)
        if not (canwork or canattackonly) then
            inst.AnimState:PlayAnimation(inst.sg.statemem.anim)
            inst.AnimState:SetFrame(1)
            inst.AnimState:PushAnimation("wx_spin_attack_pst", false)
            inst.sg:GoToState("idle", true)
            return
        end

        local modulecount = inst.GetModuleTypeCount and inst:GetModuleTypeCount("spin") or 0
        local efficiency_decay = modulecount > 1 and TUNING.WX78_SPIN_EFFICIENCY_DECAY_2 or TUNING.WX78_SPIN_EFFICIENCY_DECAY
        local aoe_dim = TUNING.WX78_SPIN_AOE_DIMINISHING
        local moveangle = inst.sg.statemem.vx and math.atan2(-inst.sg.statemem.vz, inst.sg.statemem.vx)
        local minangle = math.huge

        inst.components.combat.ignorehitrange = true

        local harvestedcount = 0
        local didwork, didattack = false, false
        local recoiltarget
        local x, y, z = inst.Transform:GetWorldPosition()
        local base_radius = TUNING.WX78_SPIN_RADIUS
        local search_radius = base_radius
        for _, v in ipairs(TheSim:FindEntities(x, y, z, search_radius + 3, nil, NM_WX_SPIN_CANT_TAGS, NM_WX_SPIN_ONEOF_TAGS)) do
            if v ~= inst and not inst.sg.statemem.targets[v] and v:IsValid() and v.entity:IsVisible() then
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                local dx = x1 - x
                local dz = z1 - z
                local physics_radius = v:GetPhysicsRadius(0)
                local base_range = base_radius + physics_radius
                local dsq = dx * dx + dz * dz
                if dsq < base_range * base_range then
                    local hit
                    local in_work_range = dsq < base_range * base_range
                    local hasbuildup = in_work_range and canwork and v.components.lunarhailbuildup ~= nil and v.components.lunarhailbuildup:IsBuildupWorkable()

                    if canwork and in_work_range then
                        if hasbuildup and canmine then
                            PlayMiningFX(inst, v)
                            local eff = inst.sg.statemem.efficiency.MINE
                            if eff and inst.components.efficientuser then
                                inst.components.efficientuser:AddMultiplier(ACTIONS.MINE, eff, inst)
                            end
                            if BufferedAction(inst, v, ACTIONS.REMOVELUNARBUILDUP, item):Do() then
                                inst.sg.statemem.efficiency.MINE = (eff or efficiency_decay) * efficiency_decay
                                hit = true
                            end
                        elseif v.components.workable and v.components.workable:CanBeWorked() then
                            local workaction = v.components.workable:GetWorkAction()
                            if workaction == ACTIONS.CHOP then
                                if canchop then
                                    local eff = inst.sg.statemem.efficiency.CHOP
                                    if eff and inst.components.efficientuser then
                                        inst.components.efficientuser:AddMultiplier(ACTIONS.CHOP, eff, inst)
                                    end
                                    if BufferedAction(inst, v, ACTIONS.CHOP, item):Do() then
                                        inst.sg.statemem.efficiency.CHOP = (eff or efficiency_decay) * efficiency_decay
                                        hit = true
                                    end
                                else
                                    recoiltarget = v
                                end
                            elseif workaction == ACTIONS.MINE then
                                PlayMiningFX(inst, v)
                                if canmine then
                                    local eff = inst.sg.statemem.efficiency.MINE
                                    if eff and inst.components.efficientuser then
                                        inst.components.efficientuser:AddMultiplier(ACTIONS.MINE, eff, inst)
                                    end
                                    if BufferedAction(inst, v, ACTIONS.MINE, item):Do() then
                                        inst.sg.statemem.efficiency.MINE = (eff or efficiency_decay) * efficiency_decay
                                        hit = true
                                    end
                                else
                                    recoiltarget = v
                                end
                            end
                        end

                        if hit then
                            didwork = true
                        elseif hasbuildup then
                            recoiltarget = v
                        end

                        if recoiltarget then
                            if hasbuildup then
                                v.components.lunarhailbuildup:DoWorkToRemoveBuildup(0, inst)
                            else
                                v.components.workable:WorkedBy(inst, 0)
                            end
                            inst:ForceFacePoint(x1, y1, z1)
                            break
                        end
                    end

                    if not hit
                        and v.components.combat
                        and inst.components.combat:CanTarget(v)
                        and not v:HasTag("wall")
                        and not inst.components.combat:IsAlly(v)
                    then
                        local eff = inst.sg.statemem.efficiency.ATTACK
                        if inst.components.efficientuser then
                            inst.components.efficientuser:AddMultiplier(ACTIONS.ATTACK, eff, inst)
                        end
                        local dim = inst.sg.statemem.dim
                        if dim and inst.components.aoediminishingreturns then
                            inst.components.aoediminishingreturns.mult:SetModifier(inst, dim, "wx_spin")
                        end
                        inst.components.combat:DoAttack(v)
                        inst.sg.statemem.efficiency.ATTACK = (eff or efficiency_decay) * efficiency_decay
                        inst.sg.statemem.dim = (dim or 1) * aoe_dim
                        didattack = didattack or ShouldPlayDangerMusic(inst, v)
                        hit = true
                    end

                    if canwork
                        and in_work_range
                        and not hit
                        and v.components.pickable
                        and v.components.pickable.caninteractwith
                        and v.components.pickable:CanBePicked()
                        and not v.components.pickable:IsStuck()
                        and v:HasAnyTag(NM_WX_SPIN_PICKABLE_TAGS)
                    then
                        if v.components.pickable.picksound then
                            inst.SoundEmitter:PlaySound(v.components.pickable.picksound)
                        end
                        local success, loot = v.components.pickable:Pick(TheWorld)
                        if loot then
                            harvestedcount = harvestedcount + 1
                            for _, loot_item in ipairs(loot) do
                                Launch(loot_item, inst, 1.5)
                            end
                        end
                    end

                    if inst.sg.currentstate.name ~= "wx_spin" then
                        break
                    elseif hit then
                        inst.sg.statemem.targets[v] = true
                        if moveangle then
                            minangle = dx == 0 and dz == 0 and 0 or math.min(minangle, DiffAngleRad(math.atan2(-dz, dx), moveangle))
                        end
                    end
                end
            end
        end

        if harvestedcount > 0 then
            if not inst.sg.statemem.pickused and item ~= nil and item:IsValid() and item.components.finiteuses and item.components.finiteuses:GetUses() > 0 then
                inst.sg.statemem.pickused = true
                item.components.finiteuses:Use(TUNING.WX78_SPIN_PICK_EFFICIENCY)
            end
            inst:PushEvent("picksomethingfromaoe", { harvestedcount = harvestedcount })
        end

        inst.components.combat.ignorehitrange = false

        if inst.components.efficientuser then
            inst.components.efficientuser:RemoveMultiplier(ACTIONS.CHOP, inst)
            inst.components.efficientuser:RemoveMultiplier(ACTIONS.MINE, inst)
            inst.components.efficientuser:RemoveMultiplier(ACTIONS.ATTACK, inst)
        end

        if inst.components.aoediminishingreturns then
            inst.components.aoediminishingreturns.mult:RemoveModifier(inst, "wx_spin")
        end

        if didwork or didattack then
            inst:PushEvent("wx_performedspinaction", didattack)
        end

        if recoiltarget then
            inst.sg.statemem.targets = nil
            inst:PushEventImmediate("recoil_off", { target = recoiltarget })
        end

        if inst.sg.currentstate.name ~= "wx_spin" then
            return
        elseif minangle < math.pi and inst.sg.statemem.vx then
            minangle = minangle / math.pi
            minangle = minangle * minangle
            inst.sg.statemem.vx = inst.sg.statemem.vx * minangle
            inst.sg.statemem.vz = inst.sg.statemem.vz * minangle
        end
        if didwork or didattack then
            inst.sg.statemem.quickstart = nil
        end
    end

    if inst.components.playercontroller
        and inst.sg.statemem.canrelease
        and not inst.components.playercontroller:IsAnyOfControlsPressed(
            CONTROL_ACTION,
            CONTROL_CONTROLLER_ACTION,
            CONTROL_CONTROLLER_ALTACTION,
            CONTROL_ATTACK,
            CONTROL_CONTROLLER_ATTACK,
            CONTROL_PRIMARY,
            CONTROL_SECONDARY
        )
    then
        local frame = inst.AnimState:GetCurrentAnimationFrame()
        inst.AnimState:PlayAnimation(inst.sg.statemem.anim)
        inst.AnimState:SetFrame(frame + 1)
        inst.AnimState:PushAnimation("wx_spin_attack_pst", false)
        inst.sg:GoToState("idle", true)
        return
    end

    inst.sg.mem.wx_spin_buildup = (inst.sg.mem.wx_spin_buildup or 0) + dt

    if inst.StartDizzyFx then
        inst:StartDizzyFx()
    end

    local dizzytime = inst.CalcMaxDizzy and inst:CalcMaxDizzy() or TUNING.WX78_SPIN_TIME_TO_DIZZY
    if inst.sg.mem.wx_spin_buildup > dizzytime then
        inst.sg:GoToState("wx_spin_dizzy")
        return
    end

    inst.sg.mem.wx_spin_last = GetTime()

    local maxspeed = inst.components.locomotor:GetRunSpeed() * (TUNING.WX78_SPIN_RUNSPEED_MULT or 1)
    local accel = maxspeed / 15

    local dir = NM_GetLocalAnalogDir(inst)
    local theta = inst.sg.statemem.remotedir and inst.sg.statemem.remotedir * DEGREES
    if dir or theta then
        inst.sg.statemem.target = nil
        inst.sg.statemem.quickstart = nil
    else
        local target = inst.sg.statemem.target
        if target then
            if target:IsValid() then
                local x, y, z = inst.Transform:GetWorldPosition()
                local x1, y1, z1 = target.Transform:GetWorldPosition()
                local dx = x1 - x
                local dz = z1 - z
                local dsq = dx * dx + dz * dz
                if dsq >= 64 then
                    inst.sg.statemem.target = nil
                    inst.sg.statemem.quickstart = nil
                else
                    local physrad = target:GetPhysicsRadius(0)
                    local range = TUNING.WX78_SPIN_RADIUS - 0.5 + physrad
                    if dsq < range * range then
                        inst.sg.statemem.quickstart = nil
                    else
                        theta = math.atan2(-dz, dx)

                        if inst.sg.statemem.quickstart then
                            range = TUNING.WX78_SPIN_START_RANGE + physrad
                            if dsq > range * range then
                                inst.sg.statemem.quickstart = nil
                            end
                        end
                    end
                end
            else
                inst.sg.statemem.target = nil
                inst.sg.statemem.quickstart = nil
            end
        end
    end

    if inst.sg.statemem.quickstart then
        if dir or theta then
            maxspeed = maxspeed * inst.sg.statemem.quickstart
            accel = maxspeed
            if inst.sg.statemem.quickstart > 1 then
                inst.sg.statemem.quickstart = inst.sg.statemem.quickstart / 2
            else
                inst.sg.statemem.quickstart = nil
            end
        else
            inst.sg.statemem.quickstart = nil
        end
    end

    if dir or theta then
        local vx = inst.sg.statemem.vx
        local vz = inst.sg.statemem.vz
        if vx then
            theta = theta or math.atan2(-dir.z, dir.x)
            local diff = DiffAngleRad(theta, math.atan2(-vz, vx))
            local k = Remap(math.sin(diff) + diff / TWOPI, 0, 1.5, 1, 0.9)
            vx = vx * k
            vz = vz * k
        else
            vx, vz = 0, 0
        end
        if dir then
            vx = vx + dir.x * accel
            vz = vz + dir.z * accel
        else
            vx = vx + math.cos(theta) * accel
            vz = vz - math.sin(theta) * accel
        end
        local speed = math.sqrt(vx * vx + vz * vz)
        if speed > maxspeed then
            speed = maxspeed / speed
            inst.sg.statemem.vx = vx * speed
            inst.sg.statemem.vz = vz * speed
        else
            inst.sg.statemem.vx = vx
            inst.sg.statemem.vz = vz
        end
    elseif inst.sg.statemem.vx then
        local speed = math.sqrt(inst.sg.statemem.vx * inst.sg.statemem.vx + inst.sg.statemem.vz * inst.sg.statemem.vz)
        if speed > accel then
            speed = 1 - accel / speed
            inst.sg.statemem.vx = inst.sg.statemem.vx * speed
            inst.sg.statemem.vz = inst.sg.statemem.vz * speed
        else
            inst.sg.statemem.vx = nil
            inst.sg.statemem.vz = nil
            inst.Physics:Stop()
            inst.Physics:SetMotorVel(0, 0, 0)
        end
    end

    if inst.sg.statemem.vx then
        theta = inst.Transform:GetRotation() * DEGREES
        if inst.sg.statemem.theta ~= theta then
            inst.sg.statemem.theta = theta
            inst.sg.statemem.costheta = math.cos(theta)
            inst.sg.statemem.sintheta = math.sin(theta)
        end
        local vx = inst.sg.statemem.costheta * inst.sg.statemem.vx - inst.sg.statemem.sintheta * inst.sg.statemem.vz
        local vz = inst.sg.statemem.sintheta * inst.sg.statemem.vx + inst.sg.statemem.costheta * inst.sg.statemem.vz
        inst.Physics:SetMotorVel(vx, 0, vz)
    end
end

local function NM_CallWithCanSpinUsingItem(can_spin_fn, fn, inst, action)
    local old_CanSpinUsingItem = WX78Common.CanSpinUsingItem
    WX78Common.CanSpinUsingItem = can_spin_fn

    local success, result = pcall(fn, inst, action)
    WX78Common.CanSpinUsingItem = old_CanSpinUsingItem
    if not success then
        error(result)
    end

    return result
end

local function NM_PatchSpinStateGraph(sg)
    local state = sg ~= nil and sg.states ~= nil and sg.states.wx_spin or nil
    if state ~= nil and not state._nm_melee_spin_onupdate_patched then
        state.onupdate = NM_WXSpinOnUpdate

        local old_onexit = state.onexit
        state.onexit = function(inst)
            if inst.components.combat ~= nil then
                inst.components.combat.ignorehitrange = false
            end
            if old_onexit ~= nil then
                old_onexit(inst)
            end
        end

        state._nm_melee_spin_onupdate_patched = true
    end
end

local function NM_PatchPickActionHandler(sg)
    local handler = sg ~= nil and sg.actionhandlers ~= nil and sg.actionhandlers[ACTIONS.PICK] or nil
    if handler ~= nil and not handler._nm_spin_pick_tool_only_patched then
        local old_deststate = handler.deststate
        handler.deststate = function(inst, action)
            if inst.prefab ~= "wx78" or not NM_HasSpinAbility(inst) then
                return old_deststate(inst, action)
            end
            return NM_CallWithCanSpinUsingItem(NM_CanSpinUsingItem, old_deststate, inst, action)
        end

        handler._nm_spin_pick_tool_only_patched = true
    end
end

local function NM_HammerDestState(inst)
    if inst:HasTag("beaver") then
        return not (inst.sg:HasStateTag("gnawing") or inst:HasTag("gnawing")) and "gnaw" or nil
    end

    return not (inst.sg:HasStateTag("prehammer") or inst:HasTag("prehammer"))
        and (inst.sg:HasStateTag("hammering") and "hammer" or "hammer_start")
        or nil
end

local function NM_PatchHammerActionHandler(sg)
    local handler = sg ~= nil and sg.actionhandlers ~= nil and sg.actionhandlers[ACTIONS.HAMMER] or nil
    if handler ~= nil and not handler._nm_spin_hammer_disabled then
        local old_deststate = handler.deststate
        handler.deststate = function(inst, action)
            if inst.prefab ~= "wx78" or not NM_HasSpinAbility(inst) then
                return old_deststate(inst, action)
            end
            return NM_HammerDestState(inst)
        end
        handler._nm_spin_hammer_disabled = true
    end
end

local function NM_PatchWXStateGraph(sg)
    NM_PatchSpinStateGraph(sg)
    NM_PatchPickActionHandler(sg)
    NM_PatchHammerActionHandler(sg)
end

local function NM_InitSpinMelee(wx)
    if wx == nil or wx.prefab ~= "wx78" then
        return
    end

    NM_EnsureSpinComponents(wx)
    wx:DoTaskInTime(0, NM_EnsureSpinComponents)
end

if WX78Common ~= nil then
    local vanilla_CanSpinUsingItem = WX78Common.CanSpinUsingItem
    WX78Common.CanSpinUsingItem = function(item)
        if NM_CanSpinUsingItem(item) then
            return true
        end
        return vanilla_CanSpinUsingItem ~= nil and vanilla_CanSpinUsingItem(item) or false
    end
end

AddPrefabPostInit("wx78", NM_InitSpinMelee)
AddStategraphPostInit("wilson", NM_PatchWXStateGraph)
AddStategraphPostInit("wilson_client", NM_PatchPickActionHandler)
AddStategraphPostInit("wilson_client", NM_PatchHammerActionHandler)
