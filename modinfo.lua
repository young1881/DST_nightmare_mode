local function zh_en(zh, en)
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

-- 是否是测试服
local is_test = false -- 正式服
-- local is_test = true -- 测试服

if is_test then
    name = zh_en("小合集RR魔改的魔改(测试服)", "RR Collection Rework (Test)")
    icon = "modicon_test.tex"
    icon_atlas = "modicon_test.xml"
else
    name = zh_en("小合集RR魔改的魔改", "RR Collection Rework")
    icon = "modicon.tex"
    icon_atlas = "modicon.xml"
end

description = zh_en(
    "仅适用于萌新俱乐部快餐档噩梦模式",
    "Only for Newbie Club Fast Food Save - NightMare Mode"
)

author = "津酒昴&暗影大法师"
version = "4.6.3.2"
forumthread = ""

api_version = 10
priority = -99999

dst_compatible = true
all_clients_require_mod = true

configuration_options = {

    { name = 'a', label = zh_en('是否禁止夜视鹰眼', 'Disable Night Vision Eagle Eye'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },

    { name = 'peifang', label = zh_en('是否启用配方修改', 'Enable recipe modifications'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'diaoluo', label = zh_en('是否启用掉落加强', 'Enable enhanced loot drops'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'jiaqiang', label = zh_en('是否启用各类数值加强', 'Enable general stat enhancements'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },

    { name = 'electrocute', label = zh_en('是否删除boss电击僵直与植物电击点燃', 'Enable electrocute effect changes'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'curse', label = zh_en('是否启用boss诅咒系统', 'Enable curse system'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'boss', label = zh_en('是否启用生物与boss加强', 'Enable bosses and creature buffs'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'word', label = zh_en('是否启用猪人兔人语言包替换', 'Enable substitution of speech'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },


    { name = 'wilson', label = zh_en('是否修改威尔逊', 'Modify Wilson'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'willow', label = zh_en('是否修改薇洛', 'Modify Willow'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wolfgang', label = zh_en('是否修改沃尔夫冈', 'Modify Wolfgang'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wendy', label = zh_en('是否修改温蒂', 'Modify Wendy'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wx78', label = zh_en('是否修改WX-78', 'Modify WX-78'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wickerbottom', label = zh_en('是否修改薇克巴顿', 'Modify Wickerbottom'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'woodie', label = zh_en('是否修改伍迪', 'Modify Woodie'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wes', label = zh_en('是否修改维斯', 'Modify Wes'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'waxwell', label = zh_en('是否修改麦斯威尔', 'Modify Maxwell'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wigfrid', label = zh_en('是否修改薇格弗德', 'Modify Wigfrid'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'winona', label = zh_en('是否修改薇诺娜', 'Modify Winona'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'warly', label = zh_en('是否修改沃利', 'Modify Warly'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wormwood', label = zh_en('是否修改沃姆伍德', 'Modify Wormwood'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'walter', label = zh_en('是否修改沃尔特', 'Modify Walter'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wanda', label = zh_en('是否修改旺达', 'Modify Wanda'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'wurt', label = zh_en('是否删除沃特', 'Delete Wurt'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'webber', label = zh_en('是否删除韦伯', 'Delete Webber'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },

    { name = 'raterate', label = zh_en('是否启用快速训牛', 'Enable fast beefalo training'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'alterguardianhat', label = zh_en('是否启用加强的启迪冠', 'Enable Alter Guardian Hat'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'zuowu', label = zh_en('是否启用作物全季节', 'Enable all-season crops'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'ruins_equip', label = zh_en('是否启用加强的铥棒与铥甲', 'Enable Ruins equipment'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'stage', label = zh_en('是否启用舞台与唱片', 'Enable stage'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'shadow_container', label = zh_en('是否启用暗影空间同步', 'Enable Shadow Container'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'cookpot', label = zh_en('是否启动红锅批量', 'Modify Cookpot'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
    { name = 'sleep', label = zh_en('是否启用帐篷与晾肉架加强', 'Modify tent and meatrack'), options = { { description = 'Yes', data = true }, { description = 'No', data = false } }, default = true },
}
