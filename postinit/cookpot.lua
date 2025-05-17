if TUNING.IAI_COOKSTACKFOOD then
    return
end

TUNING.IAI_COOKSTACKFOOD = true

modimport("scripts/extensions/iai_cookstackfood_secondbutton.lua")
modimport("scripts/extensions/iai_cookstackfood_containers.lua")

if TheNet:GetIsServer() then
    local cooking = require("cooking")

    AddComponentPostInit("stewer", function(self)
        local old = self.StartCooking
        self.StartCooking = function(self, doer, ...)
            -- 堆叠数计算
            local stack = 9999

            for k, v in pairs(self.inst.components.container.slots) do
                if v.components.stackable then
                    stack = math.min(v.components.stackable:StackSize(), stack)
                else
                    stack = 1

                    break
                end
            end

            -- 强制掉落多余的食材
            for k, v in pairs(self.inst.components.container.slots) do
                if v.components.stackable then
                    local v_stack = v.components.stackable:StackSize()

                    if v_stack > stack then
                        -- 这里生成一个新的，因为烹饪锅会摧毁内部物品，即使被容器丢出来
                        local food = SpawnPrefab(v.prefab)

                        food.components.stackable:SetStackSize(v_stack - stack)

                        if food.components.perishable then
                            food.components.perishable:SetPercent(v.components.perishable:GetPercent())
                        end

                        if doer ~= nil and doer.components.inventory ~= nil then
                            doer.components.inventory:GiveItem(food, nil, self.inst:GetPosition())
                        else
                            LaunchAt(food, self.inst, nil, 1, 1)
                        end
                    end
                end
            end

            self.foodstack = stack
            stack = nil

            return old(self, doer, ...)
        end

        local old = self.Harvest
        self.Harvest = function(self, harvester, ...)
            -- 未完成烹饪禁止收获
            if not self.done then
                return
            end

            local product, stack, spoilage = self.product, self.foodstack, self.product_spoilage

            if not (stack ~= nil and stack > 1) then
                stack = 1
            end

            -- 额外人物多收接口
            local player_mult = harvester ~= nil and
                harvester:HasTag("multiplefoodharvester") and
                harvester.components.multiplefoodharvester ~= nil and
                harvester.components.multiplefoodharvester.mult ~= nil and
                (type(harvester.components.multiplefoodharvester.mult) == "function" and
                    harvester.components.multiplefoodharvester.mult(self.inst.prefab) or
                    harvester.components.multiplefoodharvester.mult) or 1

            if type(player_mult) ~= "number" then
                player_mult = 1
            end

            player_mult = math.max(1, math.floor(player_mult))

            -- 在收获的时候，补上整组烹饪的数量
            if stack > 1 or player_mult > 1 then
                if product then
                    local recipe = cooking.GetRecipe(self.inst.prefab, product)
                    local stacksize = recipe and recipe.stacksize or 1
                    local totalamount = stacksize * (stack * player_mult - 1)
                    local full = math.floor(totalamount / stack)
                    local rest = totalamount % stack

                    local function give(num)
                        local food = product ~= "spoiledfood" and SpawnPrefab(product) or SpawnPrefab("spoiled_food")

                        if food then
                            if food.components.stackable then
                                food.components.stackable:SetStackSize(num)
                            end

                            if food.components.perishable then
                                food.components.perishable:SetPercent(spoilage)
                            end

                            if harvester ~= nil and harvester.components.inventory ~= nil then
                                harvester.components.inventory:GiveItem(food, nil, self.inst:GetPosition())
                            else
                                LaunchAt(food, self.inst, nil, 1, 1)
                            end
                        end
                    end

                    -- 分次单独给，防止堆叠数量超出上限
                    for i = 1, full do
                        give(stack)
                    end

                    if rest > 0 then
                        give(rest)
                    end
                end
            end

            product, stack, spoilage, player_mult = nil, nil, nil, nil

            return old(self, harvester, ...)
        end

        local old = self.OnSave
        self.OnSave = function(self, ...)
            local data = old(self, ...)

            if data and self.foodstack then
                data.foodstack = self.foodstack
            end

            return data
        end

        local old = self.OnLoad
        self.OnLoad = function(self, data, ...)
            local old_return = old(self, data, ...)

            if data.foodstack then
                self.foodstack = data.foodstack
            end

            return old_return
        end
    end)
end

local function getwidget(inst, stack)
    if inst:HasTag("spicer") then
        return stack and "iai_portablespicer_stack" or "iai_portablespicer"
    else
        return stack and "iai_cookpot_stack" or "iai_cookpot"
    end
end

local function getnumslots(inst)
    return inst:HasTag("spicer") and 2 or 4
end

-- AddPrefabPostInit("cookpot", function(inst)
--     if not TheWorld.ismastersim then
--         return inst
--     end

--     inst:AddTag("no_stack_cook")
-- end)

-- AddPrefabPostInit("archive_cookpot", function(inst)
--     if not TheWorld.ismastersim then
--         return inst
--     end

--     inst:AddTag("no_stack_cook")
-- end)

AddPrefabPostInitAny(function(inst)
    if (inst:HasTag("stewer") and inst:HasTag("mastercookware") or inst:HasTag("stack_cook")) and not inst:HasTag("no_stack_cook") then
        inst.iai_cookpot_type = net_bool(inst.GUID, "iai_cookpot_type", "iai_cookpot_type_dirty")

        inst:DoTaskInTime(0, function(inst)
            if inst.components.container and inst.components.container:GetNumSlots() <= getnumslots(inst) then
                if inst.iai_cookpot_widget == nil then
                    inst.iai_cookpot_widget = {
                        widget = inst.components.container:GetWidget(),
                        itemtestfn = inst.components.container.itemtestfn,
                    }
                end

                inst.components.container:WidgetSetup(getwidget(inst))
            elseif inst.replica.container and inst.replica.container:GetNumSlots() <= getnumslots(inst) then
                if inst.iai_cookpot_widget == nil then
                    inst.iai_cookpot_widget = {
                        widget = inst.replica.container:GetWidget(),
                        itemtestfn = inst.replica.container.itemtestfn,
                    }
                end

                inst:ListenForEvent("iai_cookpot_type_dirty", function(inst)
                    inst.replica.container:WidgetSetup(getwidget(inst,
                        inst.iai_cookpot_type ~= nil and inst.iai_cookpot_type:value()))
                end)

                inst.replica.container:WidgetSetup(getwidget(inst,
                    inst.iai_cookpot_type ~= nil and inst.iai_cookpot_type:value()))
            end
        end)
    end
end)
