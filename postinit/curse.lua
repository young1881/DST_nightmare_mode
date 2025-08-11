local boss_list               = {
    "deerclops",
    "alterguardian_phase1",
    "alterguardian_phase2",
    "alterguardian_phase3",
    "stalker_atrium",
}

local SLOTH_GROGGINESS        = 1
local SLOTH_DURATION          = 3

local PRIDE_DAMAGE_MULT       = 1.2

local ENVY_INTERVAL           = 3
local ENVY_HEALTH_DRAIN       = 10
local ENVY_SANITY_DRAIN       = 10
local ENVY_RADIUS             = 12
local ENVY_SANITY_EXCLUDE_TAG = "lunar_aligned"

local WRATH_WEAR_MULT         = 1.5
local WRATH_DURATION          = 20

local GREED_STEAL_MIN         = 2
local GREED_STEAL_MAX         = 3

local GLUTTONY_HUNGER_DRAIN   = 10
local GLUTTONY_ABSORB_MULT    = 0.5
local GLUTTONY_DURATION       = 20

local LUST_DAMAGE_REDUCE      = 0.8

CURSES                        = {
    ["怠惰"] = {
        name_prefix = "怠惰",
        desc = "这让你感到疲惫不堪",
        get_details = function()
            return string.format("每一次攻击时附加 %d 发催眠吹箭",
                SLOTH_GROGGINESS)
        end,
        apply = function(inst)
            inst:ListenForEvent("onhitother", function(inst, data)
                local target = data.target
                if target and target:HasTag("curse_immune") then return end
                if target and target.components.grogginess then
                    target.components.grogginess:AddGrogginess(SLOTH_GROGGINESS, SLOTH_DURATION)
                end
            end)
        end,
    },

    ["傲慢"] = {
        name_prefix = "傲慢",
        desc = "造成的基础伤害提高了",
        get_details = function()
            return string.format("基础伤害提升 %.0f%%", (PRIDE_DAMAGE_MULT - 1) * 100)
        end,
        apply = function(inst)
            local old = inst.components.combat.CalcDamage or
                function(_, target, weapon, multiplier) return inst.components.combat.defaultdamage end
            inst.components.combat.CalcDamage = function(self, target, weapon, multiplier)
                return PRIDE_DAMAGE_MULT * old(self, target, weapon, multiplier)
            end
        end,
    },

    ["嫉妒"] = {
        name_prefix = "嫉妒",
        desc = "会不断吸取周围宝贵的生命",
        get_details = function()
            return string.format("每 %d 秒对半径 %d 格内玩家造成 %d 生命伤害，并为自己回复等量生命",
                ENVY_INTERVAL, ENVY_RADIUS, ENVY_HEALTH_DRAIN, ENVY_SANITY_DRAIN)
        end,
        apply = function(inst)
            inst:DoPeriodicTask(ENVY_INTERVAL, function()
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, ENVY_RADIUS, { "player" })
                local total_heal = 0

                for _, ent in ipairs(ents) do
                    if ent.components.health and not ent.components.health:IsDead() then
                        ent.components.health:DoDelta(-ENVY_HEALTH_DRAIN, false, inst.prefab)
                        total_heal = total_heal + ENVY_HEALTH_DRAIN
                    end
                    if not inst:HasTag(ENVY_SANITY_EXCLUDE_TAG) and ent.components.sanity then
                        ent.components.sanity:DoDelta(-ENVY_SANITY_DRAIN)
                    end
                end

                if total_heal > 0 and inst.components.health then
                    inst.components.health:DoDelta(total_heal)
                end
            end)
        end,
    },

    ["愤怒"] = {
        name_prefix = "愤怒",
        desc = "冲昏了你的头脑，让你更加损耗自己的武器",
        get_details = function()
            return string.format("被击中后武器耐久消耗加倍（x%.1f），持续 %d 秒", WRATH_WEAR_MULT, WRATH_DURATION)
        end,
        apply = function(inst)
            inst:ListenForEvent("onhitother", function(inst, data)
                local target = data.target
                if not (target and target:IsValid()) or target:HasTag("curse_immune") then return end
                if not target.components.inventory then return end

                if target._rage_curse_timer then
                    target._rage_curse_timer:Cancel()
                    target._rage_curse_timer = nil
                end
                if target._rage_on_equip then
                    target:RemoveEventCallback("equip", target._rage_on_equip)
                    target._rage_on_equip = nil
                end

                local function ApplyModifierToHandsWeapon()
                    local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip and equip.components.weapon and equip.components.finiteuses then
                        equip.components.weapon.attackwearmultipliers:SetModifier(inst, WRATH_WEAR_MULT)
                        target._rage_cursed_weapon = equip
                    end
                end

                local function RemoveModifier()
                    if target._rage_cursed_weapon and target._rage_cursed_weapon:IsValid()
                        and target._rage_cursed_weapon.components.weapon
                        and target._rage_cursed_weapon.components.finiteuses then
                        target._rage_cursed_weapon.components.weapon.attackwearmultipliers:RemoveModifier(inst)
                    end
                    target._rage_cursed_weapon = nil
                    if target._rage_on_equip then
                        target:RemoveEventCallback("equip", target._rage_on_equip)
                        target._rage_on_equip = nil
                    end
                    if target.components.talker then
                        target.components.talker:Say("我已摆脱愤怒的诅咒")
                    end
                    target._rage_curse_timer = nil
                end

                target._rage_on_equip = function(_, data)
                    if data.eslot == EQUIPSLOTS.HANDS then
                        ApplyModifierToHandsWeapon()
                    end
                end

                target:ListenForEvent("equip", target._rage_on_equip)
                ApplyModifierToHandsWeapon()

                target._rage_curse_timer = target:DoTaskInTime(WRATH_DURATION, RemoveModifier)
            end)
        end,
    },

    ["贪婪"] = {
        name_prefix = "贪婪",
        desc = "会不断偷取你身上的物品",
        get_details = function()
            return string.format("攻击命中时偷取 %d~%d 个物品", GREED_STEAL_MIN, GREED_STEAL_MAX)
        end,
        apply = function(inst)
            if not inst.components.thief then
                inst:AddComponent("thief")
            end
            inst:ListenForEvent("onhitother", function(inst, data)
                local target = data.target
                if target and target:HasTag("curse_immune") then return end
                if target and target.components.inventory then
                    local num_items = math.random(GREED_STEAL_MIN, GREED_STEAL_MAX)
                    for i = 1, num_items do
                        inst.components.thief:StealItem(target)
                    end
                end
            end)
        end,
    },

    ["暴食"] = {
        name_prefix = "暴食",
        desc = "会不断偷取你胃中的饱食度，灵魂和食物的恢复效果减弱了",
        get_details = function()
            return string.format("命中时减少 %d 饱食度，并使灵魂和食物恢复效果降低 %.0f%%，持续 %d 秒",
                GLUTTONY_HUNGER_DRAIN, (1 - GLUTTONY_ABSORB_MULT) * 100, GLUTTONY_DURATION)
        end,
        apply = function(inst)
            inst:ListenForEvent("onhitother", function(inst, data)
                local target = data.target
                if not (target and target:IsValid()) then return end
                if target:HasTag("curse_immune") then return end

                if target.components.hunger then
                    target.components.hunger:DoDelta(-GLUTTONY_HUNGER_DRAIN)
                end

                if target.gluttony_curse_task then
                    target.gluttony_curse_task:Cancel()
                    target.gluttony_curse_task = nil
                end

                if target.components.eater then
                    target._base_absorption = {
                        hunger = 1,
                        health = 1,
                        sanity = 1,
                    }
                    target.components.eater:SetAbsorptionModifiers(
                        target._base_absorption.hunger * GLUTTONY_ABSORB_MULT,
                        target._base_absorption.health * GLUTTONY_ABSORB_MULT,
                        target._base_absorption.sanity * GLUTTONY_ABSORB_MULT
                    )
                end

                target.gluttony_curse_task = target:DoTaskInTime(GLUTTONY_DURATION, function()
                    if target.components.eater and target._base_absorption then
                        target.components.eater:SetAbsorptionModifiers(
                            target._base_absorption.hunger,
                            target._base_absorption.health,
                            target._base_absorption.sanity
                        )
                        target._base_absorption = nil
                    end
                    if target.components.talker then
                        target.components.talker:Say("我已摆脱暴食的诅咒")
                    end
                    target.gluttony_curse_task = nil
                end)
            end)
        end,
    },

    ["色欲"] = {
        name_prefix = "色欲",
        desc = "这让你感到萎靡不振",
        get_details = function()
            return string.format("受到的伤害减少 %d %", (1 - LUST_DAMAGE_REDUCE) * 100)
        end,
        apply = function(inst)
            local oldDoDelta = inst.components.health.DoDelta
            inst.components.health.DoDelta = function(self, delta, ...)
                if delta < 0 then
                    delta = delta * LUST_DAMAGE_REDUCE
                end
                return oldDoDelta(self, delta, ...)
            end
        end,
    }

}

-- ========= 公告 =========
local ANNOUNCE_CURSE_TEMPLATE = "󰀀 {boss_name} 激活了诅咒【{curse_name}】：{curse_desc}！"
local ANNOUNCE_CURSE_DETAILS  = "󰀀 诅咒效果详情：{curse_details}"

local function AnnounceCurse(inst, curse)
    local msg_main = subfmt(ANNOUNCE_CURSE_TEMPLATE, {
        boss_name = inst:GetDisplayName(),
        curse_name = curse.name_prefix,
        curse_desc = curse.desc or "未知效果",
    })
    local msg_details = subfmt(ANNOUNCE_CURSE_DETAILS, {
        curse_details = curse.get_details and curse.get_details() or "无具体数值说明",
    })

    if TheNet and TheNet.Announce then
        TheNet:Announce(msg_main)
        TheNet:Announce(msg_details)
    else
        for _, player in ipairs(AllPlayers) do
            if player.HUD then
                player.components.talker:Say(msg_main, 4)
                player:DoTaskInTime(4.5, function()
                    player.components.talker:Say(msg_details, 4)
                end)
            end
        end
    end
end


local function ApplyRandomCurse(inst)
    if inst._applied_curses == nil then
        inst._applied_curses = {}
    end

    local available = {}
    for k, curse in pairs(CURSES) do
        if not inst._applied_curses[k] then
            table.insert(available, { key = k, data = curse })
        end
    end

    if #available == 0 then return end -- 所有诅咒都用完了

    local choice = available[math.random(#available)]
    local curse = choice.data

    if inst.components.named then
        local old_name = inst:GetDisplayName() or inst.name or inst.prefab
        inst.components.named:SetName(curse.name_prefix .. "·" .. old_name)
    end

    inst._applied_curses[choice.key] = true

    AnnounceCurse(inst, curse)
    curse.apply(inst)
end

local FIRST_CURSE_THRESHOLD = 0.66
local SECOND_CURSE_THRESHOLD = 0.33

local function TryApplyCurses(inst)
    if inst._curse_stage == nil then inst._curse_stage = 0 end
    if inst._curse_triggered == nil then
        inst._curse_triggered = { first = false, second = false }
    end
    if inst.components.health == nil then return end

    local hp = inst.components.health:GetPercent()

    -- 第一阶段
    if not inst._curse_triggered.first and hp <= FIRST_CURSE_THRESHOLD then
        ApplyRandomCurse(inst)
        inst._curse_stage = math.max(inst._curse_stage, 1)
        inst._curse_triggered.first = true
    end

    -- 第二阶段
    if not inst._curse_triggered.second and hp <= SECOND_CURSE_THRESHOLD then
        ApplyRandomCurse(inst)
        inst._curse_stage = math.max(inst._curse_stage, 2)
        inst._curse_triggered.second = true
    end
end


for _, boss_prefab in ipairs(boss_list) do
    AddPrefabPostInit(boss_prefab, function(inst)
        if not TheWorld.ismastersim then return end

        inst:AddComponent("named")
        inst:ListenForEvent("healthdelta", TryApplyCurses)

        inst.OnSave = function(inst, data)
            data._curse_stage = inst._curse_stage
            data._curse_triggered = inst._curse_triggered
        end

        inst.OnLoad = function(inst, data)
            if data then
                inst._curse_stage = data._curse_stage or 0
                inst._curse_triggered = data._curse_triggered or { first = false, second = false }
            end
        end
    end)
end
