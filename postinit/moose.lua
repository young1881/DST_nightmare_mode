--春鹅不逃跑
GLOBAL.setval = function(fn, path, new)
    local val = fn
    local prev = nil
    local i
    for entry in path:gmatch("[^%.]+") do
        i = 1
        prev = val
        while true do
            local name, value = GLOBAL.debug.getupvalue(val, i)
            -- print("参数", name or "nil")
            if name == entry then
                val = value
                break
            elseif name == nil then
                return
            end
            i = i + 1
        end
    end

    GLOBAL.debug.setupvalue(prev, i, new) -- 这个函数将 new 设为函数 prev 的第 i 个上值。 如果函数没有那个上值，返回 nil 否则，返回该上值的名字。
end
local old_DoRetrofitting = require("map/retrofit_savedata").DoRetrofitting
require("map/retrofit_savedata").DoRetrofitting = function(savedata, map)
    if GLOBAL.Prefabs["moose"] then
        setval(GLOBAL.Prefabs["moose"].fn, "OnSpringChange", function() end)
    end
    if GLOBAL.Prefabs["mossling"] then
        setval(GLOBAL.Prefabs["mossling"].fn, "OnSpringChange", function() end)
    end


    old_DoRetrofitting(savedata, map)
end


SetSharedLootTable('mossling',
    {
        { 'meat',          1.00 },
        { 'drumstick',     1.00 },
        { 'goose_feather', 0.5 },
    })

local function LaunchItem(inst, target, item)
    if item.Physics ~= nil and item.Physics:IsActive() then
        local x, y, z = item.Transform:GetWorldPosition()
        item.Physics:Teleport(x, .1, z)

        x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = math.atan2(z1 - z, x1 - x) + (math.random() * 20 - 10) * DEGREES
        local speed = 5 + math.random() * 2
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end

local function OnHitOther(inst, data)
    if data.redirected then
        return
    end
    if data.target ~= nil and data.target.components.inventory ~= nil and not data.target:HasTag("stronggrip") then
        local item = data.target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item ~= nil and not item:HasTag("nosteal") then
            data.target.components.inventory:DropItem(item)
            LaunchItem(inst, data.target, item)
        end
    end
    if data.target ~= nil and data.target:IsValid() then
        data.target:PushEvent("knockback", {
            knocker = inst,
            radius = 3,
            strengthmult = 1.5,
            propsmashed = true
        })
    end
end

local function AddDisarmEffectToMoose(inst)
    inst:ListenForEvent("onhitother", OnHitOther)
end

AddPrefabPostInit("moose", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    local complexprojectile = inst:AddComponent("complexprojectile")
    AddDisarmEffectToMoose(inst)
    inst.components.lootdropper:AddChanceLoot('goose_feather', 1)
    inst.components.lootdropper:AddChanceLoot('goose_feather', 1)
    inst.components.lootdropper:AddChanceLoot('goose_feather', 1)
end)

AddPrefabPostInit("mossling", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.lootdropper:SetChanceLootTable('mossling')
end)

AddPrefabPostInit("mooseegg", function(inst)
    if inst:HasTag("lightningrod") then
        inst:RemoveTag("lightningrod")
    end
end)

AddPrefabPostInit("moose_nesting_ground", function(inst)
    if inst:HasTag("lightningrod") then
        inst:RemoveTag("lightningrod")
    end
end)
