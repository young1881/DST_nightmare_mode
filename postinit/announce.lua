local MY_RECHARGEABLE_PREFABS = {
    pocketwatch_cherrift = TUNING.POCKETWATCH_CHERRIFT_COOLDOWN or 300,
    pocketwatch_injure = TUNING.POCKETWATCH_HEAL_COOLDOWN / 2
}

local function AnnounceRechargeTime(item)
    if not item or not item.prefab then return false end

    if not MY_RECHARGEABLE_PREFABS[item.prefab] then return false end

    if not item.replica or not item.replica.inventoryitem or not item.replica.inventoryitem.classified then return false end

    local cooldown_time = MY_RECHARGEABLE_PREFABS[item.prefab]
    local recharge_value = item.replica.inventoryitem.classified.recharge:value()

    local item_name = STRINGS.NAMES[string.upper(item.prefab)] or item.prefab

    local inventory = ThePlayer.replica.inventory
    local item_count = 0
    if inventory then
        for k, v in pairs(inventory:GetItems()) do
            if v and v.prefab == item.prefab then
                item_count = item_count + 1
            end
        end
    end

    local message
    if recharge_value >= 180 then
        message = string.format("我拥有 %d 个 %s，这个已充能完毕", item_count, item_name)
    else
        local seconds = (180 - recharge_value) / 180 * cooldown_time
        local minutes = math.floor(seconds / 60)
        local remaining_seconds = math.floor(seconds % 60)

        if minutes > 0 then
            message = string.format("我拥有 %d 个 %s，这个还需充能 %d 分 %d 秒", item_count, item_name, minutes, remaining_seconds)
        else
            message = string.format("我拥有 %d 个 %s，这个还需充能 %d 秒", item_count, item_name, remaining_seconds)
        end
    end

    local whisper = TheInput:IsKeyDown(KEY_LCTRL)

    TheNet:Say(STRINGS.LMB .. ' ' .. message, whisper)
    return true
end

local function OnItemClick(item)
    if not item then return end

    if TheInput:IsKeyDown(KEY_LSHIFT) then
        AnnounceRechargeTime(item)
    end
end

AddClassPostConstruct("widgets/invslot", function(self)
    local oldOnMouseButton = self.OnMouseButton
    function self:OnMouseButton(button, down, ...)
        if oldOnMouseButton then
            oldOnMouseButton(self, button, down, ...)
        end

        if button == MOUSEBUTTON_LEFT and down and self.tile and self.tile.item then
            OnItemClick(self.tile.item)
        end
    end
end)

AddClassPostConstruct("widgets/equipslot", function(self)
    local oldOnMouseButton = self.OnMouseButton
    function self:OnMouseButton(button, down, ...)
        if oldOnMouseButton then
            oldOnMouseButton(self, button, down, ...)
        end

        if button == MOUSEBUTTON_LEFT and down and self.tile and self.tile.item then
            OnItemClick(self.tile.item)
        end
    end
end)
