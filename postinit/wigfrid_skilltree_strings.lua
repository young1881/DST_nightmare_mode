-- 技能树 UI 读取 SKILLTREE_DEFS 内缓存的 title/desc，仅改 STRINGS 无效。
local WIGFRID_LUNAR_SKILL_TITLE = "月之护卫"
local WIGFRID_LUNAR_SKILL_DESC =
    "神秘小白菜会馈赠你众神的雷霆之力。\n" ..
    "在战斗中使用雷霆打击来对敌人进行全方位攻击。"
local WIGFRID_SHADOW_SKILL_TITLE = "暗影女猎手"
local WIGFRID_SHADOW_SKILL_DESC =
    "鱼啦啦会馈赠你黑暗侵蚀的战士之魂。\n" ..
    "在不断的激战中唤醒战士之魂，提高自身战斗技艺与嗜血技能。"
local WIGFRID_SHIELD_SKILL_TITLE = "复仇战士"
local WIGFRID_SHIELD_SKILL_DESC =
    "蕴含过去持盾勇者战斗记忆的遗物。\n" ..
    "在永恒领域中可以将勇者的战斗技巧铭刻到灵魂上。"

local function PatchWigfridAllegianceSkillStrings()
    local skilltreedefs = require("prefabs/skilltree_defs")
    local defs = skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.wathgrithr
    if defs == nil then
        return
    end

    if defs.wathgrithr_allegiance_lunar ~= nil then
        defs.wathgrithr_allegiance_lunar.title = WIGFRID_LUNAR_SKILL_TITLE
        defs.wathgrithr_allegiance_lunar.desc = WIGFRID_LUNAR_SKILL_DESC
    end
    if defs.wathgrithr_allegiance_shadow ~= nil then
        defs.wathgrithr_allegiance_shadow.title = WIGFRID_SHADOW_SKILL_TITLE
        defs.wathgrithr_allegiance_shadow.desc = WIGFRID_SHADOW_SKILL_DESC
    end
    if defs.wathgrithr_arsenal_shield_1 ~= nil then
        defs.wathgrithr_arsenal_shield_1.title = WIGFRID_SHIELD_SKILL_TITLE
        defs.wathgrithr_arsenal_shield_1.desc = WIGFRID_SHIELD_SKILL_DESC
    end

    STRINGS.SKILLTREE.WATHGRITHR = STRINGS.SKILLTREE.WATHGRITHR or {}
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_LUNAR_TITLE = WIGFRID_LUNAR_SKILL_TITLE
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_LUNAR_DESC = WIGFRID_LUNAR_SKILL_DESC
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_SHADOW_TITLE = WIGFRID_SHADOW_SKILL_TITLE
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_SHADOW_DESC = WIGFRID_SHADOW_SKILL_DESC
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_1_TITLE = WIGFRID_SHIELD_SKILL_TITLE
    STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_1_DESC = WIGFRID_SHIELD_SKILL_DESC
end

PatchWigfridAllegianceSkillStrings()
AddSimPostInit(PatchWigfridAllegianceSkillStrings)
