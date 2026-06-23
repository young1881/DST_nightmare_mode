-- 技能树 UI 读取 SKILLTREE_DEFS 内缓存的 title/desc，仅改 STRINGS 无效。
local LUNAR_BERNIE_SKILL_TITLE = "火龙之魂"
local LUNAR_BERNIE_SKILL_DESC =
    "薇洛获得了来自另一时空的火龙之力，现在可以使用余烬来使得火焰光环剧烈燃烧"

local function PatchWillowLunarBernieSkillStrings()
    local skilltreedefs = require("prefabs/skilltree_defs")
    local defs = skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.willow
    if defs == nil then
        return
    end

    if defs.willow_allegiance_lunar_bernie ~= nil then
        defs.willow_allegiance_lunar_bernie.title = LUNAR_BERNIE_SKILL_TITLE
        defs.willow_allegiance_lunar_bernie.desc = LUNAR_BERNIE_SKILL_DESC
    end

    STRINGS.SKILLTREE.WILLOW = STRINGS.SKILLTREE.WILLOW or {}
    STRINGS.SKILLTREE.WILLOW.WILLOW_ALLEGIANCE_LUNAR_2_TITLE = LUNAR_BERNIE_SKILL_TITLE
    STRINGS.SKILLTREE.WILLOW.WILLOW_ALLEGIANCE_LUNAR_2_DESC = LUNAR_BERNIE_SKILL_DESC
end

PatchWillowLunarBernieSkillStrings()
AddSimPostInit(PatchWillowLunarBernieSkillStrings)
