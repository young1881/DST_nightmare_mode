UPGRADETYPES.TORCH = "torch"
UPGRADETYPES.LUNAR_TORCH = "lunar_torch"

AddPrefabPostInit("wilson", function(inst)
    inst:AddTag("fastbuilder")
    inst:AddTag("nm_wilson_exclusive")
    -- inst:AddTag("hungrybuilder")

    inst:AddTag(UPGRADETYPES.TORCH .. "_upgradeuser")
    inst:AddTag(UPGRADETYPES.LUNAR_TORCH .. "_upgradeuser")
    inst:AddTag(SPELLTYPES.WURT_LUNAR .. "_spelluser") ----官方写死了纯粹辉煌只能是小鱼人tag使用
end)


STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HUNGRY_FASTBUILD = {
    "科学研究催生的成果。",
    "科研过后，胃口大增。",
    "干活干的有点想吃培根煎蛋。",
    "照这么下去我得在天黑前找点吃的了。"
}

-- modmain.lua

local SPECIAL_KILL_TAG = "wilson_kill_remove"

AddPrefabPostInit("archive_centipede", function(inst)
    if not TheWorld.ismastersim then return end

    inst._should_removedirectly = false
    -- 监听被杀死
    inst:ListenForEvent("death", function(inst, data)
        local killer = data and data.afflicter or data.attack or data.attacker or nil
        if killer and killer.prefab == "wilson" then
            inst._should_removedirectly = true
        end
    end)
end)


AddStategraphPostInit("centipede", function(sg)
    local old_death_onenter = sg.states["death"].onenter

    sg.states["death"].onenter = function(inst, ...)
        if inst._should_removedirectly then
            if inst.components.lootdropper then
                inst.components.lootdropper:SpawnLootPrefab("opalpreciousgem")
            end

            inst.SoundEmitter:PlaySound("grotto/creatures/centipede/death")
            inst:DoTaskInTime(0.5, function()
                inst:Remove()
            end)

            if inst.beginfade and inst.light_params and inst._endlight then
                inst.copyparams(inst._endlight, inst.light_params.off)
                inst.beginfade(inst)
            end

            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:KillSound("alive")
            return
        end

        if old_death_onenter then
            old_death_onenter(inst, ...)
        end
    end
end)


local ACTIONS = GLOBAL.ACTIONS
local ActionHandler = GLOBAL.ActionHandler

local TorchFuelConsumption = 2.0 -- 时长
local TorchRadius = 0.7         -- 半径
local TorchToss = 1.5            -- 投掷距离


---- 火把消耗
TUNING.SKILLS.WILSON_TORCH_1 = 0.84 / TorchFuelConsumption
TUNING.SKILLS.WILSON_TORCH_2 = 0.68 / TorchFuelConsumption
TUNING.SKILLS.WILSON_TORCH_3 = 0.50 / TorchFuelConsumption

---- 火把范围
TUNING.TORCH_RADIUS = {
    2,
    3 * TorchRadius,
    4 * TorchRadius,
    5 * TorchRadius,
    6 * TorchRadius, -- lunar
    7 * TorchRadius,
    8 * TorchRadius,
    9 * TorchRadius,
}

TUNING.TORCH_FALLOFF = {
    0.5,
    0.6,
    0.075,
    0.9,
    0.5, -- lunar
    0.6,
    0.7,
    0.8,
}


---- 火把投掷 Ultra
-- 定义科学投掷动作方法
local TOSS_SCIENCE = Action({ priority = 1, rmb = true, distance = 8 * TorchToss, mount_valid = true })
TOSS_SCIENCE.id = "TOSS_SCIENCE"
TOSS_SCIENCE.str = STRINGS.ACTIONS.TOSS_SCIENCE
TOSS_SCIENCE.fn = function(act) --回调函数, 动作的操作函数，也就是我们想要控制执行的函数
    --这里固定只有act一个参数，它是BufferedAction类(这个类可以在bufferedaction.lua里看到具体定义)的一个实体，根据组件动作处理器的不同，act的数据会有变化。
    --总的来说常用于函数操作的有4个数据doer,target,invobject,pos
    --doer就是动作的执行方，target就是动作的目标，
    --invobject就是动作执行时对应的物品，比如说EAT这个动作，invobject就是要吃的东西
    --pos就是动作执行的地点，对地面执行的动作会用到这个数据。
    if not act.doer then
        return nil
    end

    local doer_inventory = act.doer.components.inventory
    if not doer_inventory then
        return nil
    end

    local projectile = act.invobject ---获取动作中的投掷物（invobject）
    if not projectile then
        --for Special action TOSS, we can also use equipped item.
        projectile = doer_inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if projectile ~= nil and not projectile:HasTag("special_action_toss") then
            projectile = nil
        end
    end
    if not projectile then
        return nil
    end

    local equippable = projectile.components.equippable
    if not projectile.components.complexprojectile or
        (equippable ~= nil and (equippable:IsRestricted(act.doer) or equippable:ShouldPreventUnequipping())) then
        return nil
    end

    if projectile.components.itemmimic and
        projectile.components.itemmimic.fail_as_invobject then
        return false, "ITEMMIMIC"
    end

    projectile = doer_inventory:DropItem(projectile, false)
    if projectile then
        local pos
        if act.target then
            pos = act.target:GetPosition() --获取目标的位置
            projectile.components.complexprojectile.targetoffset = { x = 0, y = 1.5, z = 0 }
        else
            pos = act:GetActionPoint() --获取鼠标的位置
        end

        projectile.components.complexprojectile:Launch(pos, act.doer)

        return true --如果没有返回true，会说“我做不到”
    end
end
AddAction(TOSS_SCIENCE) --定义完成

-- 定义动作选择器
-- 第三个则是一个函数，在playeractionpicker中会被执行，用于判断是否添加，以及添加什么动作。
AddComponentAction("POINT", "complexprojectile", function(inst, doer, pos, actions, right, target)
    if right and (not TheWorld.Map:IsGroundTargetBlocked(pos) or (inst:HasTag("complexprojectile_showoceanaction") and TheWorld.Map:IsOceanAtPoint(pos.x, 0, pos.z))) and not doer:HasTag("steeringboat") and not doer:HasTag("rotatingboat")
        and (inst.CanTossInWorld == nil or inst:CanTossInWorld(doer, pos))
        and not (inst.replica.equippable ~= nil and (inst.replica.equippable:IsRestricted(doer) or inst.replica.equippable:ShouldPreventUnequipping()))
        and not (inst:HasTag("special_action_toss") or inst:HasTag("deployable")) then
        table.insert(actions, ACTIONS.TOSS_SCIENCE)
    end
end)

local state = function(inst, action) -- 设定要绑定的state
    local projectile = action.invobject
    if projectile == nil then
        --for Special action TOSS, we can also use equipped item.
        projectile = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if projectile ~= nil and not projectile:HasTag("special_action_toss") then
            projectile = nil
        end
    end
    return projectile ~= nil and projectile:HasTag("keep_equip_toss") and "throw_keep_equip" or
        "throw" -- 返回"throw_keep_equip" 或者 "throw"
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TOSS_SCIENCE, state))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TOSS_SCIENCE, state))

-- 修改投掷属性
local function ModifyTorch(inst)
    -- 添加 complexprojectile 组件
    if not inst.components.complexprojectile then
        inst:AddComponent("complexprojectile")
    else
        -- print("Component 'complexprojectile' already exists.")
    end

    -- 设置火把的投掷属性
    inst.components.complexprojectile:SetHorizontalSpeed(15 * TorchToss)  -- 水平速度
    inst.components.complexprojectile:SetGravity(-35 * TorchToss / 1.2)   -- 重力值
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0)) -- 发射偏移
end
AddPrefabPostInit("torch", ModifyTorch)

-- 强制落地逻辑
local function SetupComplexProjectileForceTimeout(inst)
    if inst.components.complexprojectile then
        -- 保存原始OnUpdate
        local old_onupdate = inst.components.complexprojectile.OnUpdate

        inst.components.complexprojectile.OnUpdate = function(self, dt)
            -- 原始onupdatefn逻辑（提前return）
            if self.onupdatefn ~= nil and self.onupdatefn(self.inst) then
                return
            end

            -- 设定当前速度
            self.inst.Physics:SetMotorVel(self.velocity:Get())
            self.velocity.y = self.velocity.y + (self.gravity * dt)

            -- 获取当前位置
            local x, y, z = self.inst.Transform:GetWorldPosition()

            -- 下降且高度低于阈值时落地
            if self.velocity.y < 0 and y <= 1 then
                self:Hit()
                return
            end

            -- 卡住判定：高度>=0且垂直速度极小，强制向下加速
            if y >= 0 and math.abs(self.velocity.y) <= 0.1 then
                print(string.format("[ComplexProjectile Debug] Potential stuck detected. y=%.3f, velocity.y=%.3f", y,
                    self.velocity.y))
                print(string.format("[ComplexProjectile Debug] Current position: (%.3f, %.3f, %.3f)", x, y, z))
                print("[ComplexProjectile Debug] Forcing downward velocity to unstick projectile.")
                self.velocity.y = -2 -- 赋予向下速度解除卡住
            end

            -- 位置停滞检测，防止悬空飘浮
            if self._last_y == nil then
                self._last_y = y
                self._stuck_frames = 0
                print(string.format("[ComplexProjectile Debug] Init stuck detection. y=%.3f", y))
            else
                local delta_y = math.abs(y - self._last_y)
                if delta_y < 0.01 then
                    self._stuck_frames = (self._stuck_frames or 0) + 1
                    print(string.format("[ComplexProjectile Debug] Stuck frame %d detected. y=%.3f, delta_y=%.5f",
                        self._stuck_frames, y, delta_y))
                else
                    if self._stuck_frames > 0 then
                        print(string.format(
                            "[ComplexProjectile Debug] Movement resumed after %d stuck frames. y=%.3f, delta_y=%.5f",
                            self._stuck_frames, y, delta_y))
                    end
                    self._stuck_frames = 0
                end
                self._last_y = y

                local STUCK_FRAME_LIMIT = 30 -- 30帧几乎不动判定卡住 (~0.5秒)

                if self._stuck_frames >= STUCK_FRAME_LIMIT then
                    print("[ComplexProjectile Debug] Position stuck detected, forcing Hit()")
                    self:Hit()
                    return
                end
            end
        end
    end
end
-- lunar_torch
AddPrefabPostInit("lunar_torch", SetupComplexProjectileForceTimeout)
-- 普通 torch
AddPrefabPostInit("torch", SetupComplexProjectileForceTimeout)


-- 用纯粹辉煌升级
AddPrefabPostInit("purebrilliance", function(inst)
    inst:AddTag(UPGRADETYPES.TORCH .. "_upgrader")
    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.TORCH

    ---- 用spell的方法来升级
    if inst.components.spellcaster then
        local old_spell = inst.components.spellcaster.spell or nil
        inst.components.spellcaster.spell = function(inst, target, pos, doer)
            if doer.prefab == "wilson" then
                local inventory = doer.components.inventory
                if inventory then
                    local torch = inventory:FindItem(function(item)
                        return item.prefab == "torch"
                    end)
                    if torch then
                        local x, y, z = torch.Transform:GetWorldPosition()
                        local slot = torch.components.inventoryitem:GetSlotNum()
                        local container = torch.components.inventoryitem:GetContainer()
                        torch:Remove()

                        local lunar_torch = SpawnPrefab("lunar_torch")
                        if container then
                            container:GiveItem(lunar_torch, slot)
                        else
                            lunar_torch.Transform:SetPosition(x, y, z)
                        end

                        if inst.components.stackable and inst.components.stackable:IsStack() then
                            inst.components.stackable:Get(1):Remove()
                        else
                            inst:Remove()
                        end
                    end
                end
            else
                if old_spell then
                    old_spell(inst, target, pos, doer)
                end
            end
        end
    end
end)
-- 火炬升级为月亮火炬
AddPrefabPostInit("torch", function(inst)
    inst:AddTag(UPGRADETYPES.TORCH .. "_upgradeable")
    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.TORCH
    inst.components.upgradeable:SetOnUpgradeFn(function(inst, item)
        local torch = SpawnPrefab("lunar_torch")
        local container = inst.components.inventoryitem:GetContainer()
        if container ~= nil then
            local slot = inst.components.inventoryitem:GetSlotNum()
            inst:Remove()
            container:GiveItem(torch, slot)
        else
            local x, y, z = inst.Transform:GetWorldPosition()
            inst:Remove()
            torch.Transform:SetPosition(x, y, z)
        end
    end)
    inst.components.upgradeable:SetCanUpgradeFn(function(inst, upgrader, item)
        return not inst.components.equippable:IsEquipped()
    end)
end)

-- 月亮火炬升级为无限月亮火炬
AddPrefabPostInit("alterguardianhatshard", function(inst)
    inst:AddTag(UPGRADETYPES.LUNAR_TORCH .. "_upgrader")
    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.LUNAR_TORCH
end)
-- 月亮火炬升级为无限月亮火炬
AddPrefabPostInit("lunar_torch", function(inst)
    inst:AddTag(UPGRADETYPES.LUNAR_TORCH .. "_upgradeable")
    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.LUNAR_TORCH
    inst.components.upgradeable:SetOnUpgradeFn(function(inst, item)
        local infinite_lunar_torch = SpawnPrefab("lunar_torch")
        infinite_lunar_torch.infinite = true
        infinite_lunar_torch:UpgradeInfinite()
        local container = inst.components.inventoryitem:GetContainer()
        if container ~= nil then
            local slot = inst.components.inventoryitem:GetSlotNum()
            inst:Remove()
            container:GiveItem(infinite_lunar_torch, slot)
        else
            local x, y, z = inst.Transform:GetWorldPosition()
            inst:Remove()
            infinite_lunar_torch.Transform:SetPosition(x, y, z)
        end
    end)
    inst.components.upgradeable:SetCanUpgradeFn(function(inst, upgrader, item)
        return not inst.components.equippable:IsEquipped()
    end)
end)


local ACTIONS = GLOBAL.ACTIONS

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right then
        if useitem == nil then
            local inventory = inst.replica.inventory
            if inventory ~= nil then
                useitem = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            end
        end
        if useitem
            and useitem:HasTag("special_action_toss")
            and (useitem.prefab == "lunar_torch" or useitem.prefab == "torch")
        -- and ((useitem.prefab == "lunar_torch" and inst.components.skilltreeupdater:IsActivated("wilson_allegiance_lunar"))
        --     or useitem.prefab == "torch")
        then
            return { ACTIONS.TOSS_SCIENCE }
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    local TorchToss = wilsonvalueconfig.TorchToss --Toss range is 8
    for r = (6.5 * TorchToss), 1, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    pos.x, pos.y, pos.z = player.Transform:GetWorldPosition()
    return pos
end

function UpdateOverheatprotectionSpells(inst)
    if not inst.components.beard then
        inst:AddComponent("beard")
    end
    inst:StartUpdatingComponent(inst.components.beard) -- 每帧检测
end

AddPrefabPostInit("wilson", function(inst)
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst:ListenForEvent("setowner", OnSetOwner)

    local onskillrefresh_client = function(inst) UpdateOverheatprotectionSpells(inst) end
    local onskillrefresh_server = function(inst) UpdateOverheatprotectionSpells(inst) end
    inst:ListenForEvent("onactivateskill_server", onskillrefresh_server)
    inst:ListenForEvent("ondeactivateskill_server", onskillrefresh_server)
    inst:ListenForEvent("onactivateskill_client", onskillrefresh_client)
    inst:ListenForEvent("ondeactivateskill_client", onskillrefresh_client)

    -- inst.components.beard:EnableGrowth(false)
end)

-- 威尔逊专属：4 玻璃碎片 + 1 纯粹辉煌 → 启迪碎片
AddRecipe2("alterguardianhatshard_wilson",
	{ Ingredient("moonglass", 4), Ingredient("purebrilliance", 1) },
	TECH.NONE_TWO,
	{
		product = "alterguardianhatshard",
		builder_tag = "nm_wilson_exclusive",
	},
	{ "CHARACTER" })
STRINGS.RECIPE_DESC.ALTERGUARDIANHATSHARD_WILSON = "科学家专属的启迪炼制方式"
