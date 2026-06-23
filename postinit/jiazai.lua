-- 勿把 OTHER 权重拉得过高；加载阶段会把提示文本送进 BitmapFont，过长会触发 text_len < MAX_NUM_CHARS 崩溃
SetLoadingTipCategoryWeights(LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_START, { OTHER = 80, CONTROLS = 10, SURVIVAL = 10 })
SetLoadingTipCategoryWeights(LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_END, { OTHER = 80, CONTROLS = 10, SURVIVAL = 10 })

local LOADING_TIPS = {
    -- TIP_1 = "按alt+F4什么也不会发生（除了关掉当前应用外.",
    -- TIP_2 = "如果击杀了过多的洞穴蠕虫或许会出现巨大蠕虫！但巨大蠕虫奖励十分丰富，人称小犀牛！",
    -- TIP_3 = "记得击杀小海象，也有小概率会爆象牙。（我才不会告诉你大海象有概率掉2象牙呢）",
    -- TIP_4 = "本mod在俱乐部困禁基础上略有改动",
    -- TIP_5 = "天体在本版本有巨大加强，请多加注意小心",
    -- TIP_6 = "击杀龙蝇可以获得大量宝石和一个伏特羊角，但请不要试着单挑，因为它为了守护自己的宝物或许会一直暴怒...",
    -- TIP_7 = "真正的欧皇会发现打一次克劳斯可以不靠坎普斯掉3个小偷包",
    -- TIP_8 = "󰀣其实我也是蜻蜓队长󰀍",
    -- TIP_9 = "󰀜温蒂现在能召唤具有位面抗性的阿比盖尔󰀜",
    -- TIP_10 = "󰀕封印的暗影之魂已被释放....󰀕",
    -- TIP_11 = "先锋队帽现在拥有防御！沃尔特能制作三种不同效果的子弹！弹弓现在可以走A切A！",
    -- -- TIP_12 = "潜伏梦魇依然是原版，那么远古的什么被加强了呢？",
    -- TIP_13 = "󰀤听说沃尔特是远古大头的好伙伴󰀤",
    -- TIP_14 = "󰀏玻璃锯马和龙蝇火炉可以解放你的双手！（锯马批量制作纸和腐烂物，火炉批量烤土豆）󰀏",
    -- TIP_15 = "󰀏好的晾肉架不比烹饪锅差（现在晾肉更快收益更高）󰀏",
    -- TIP_16 = "植物人可以通过加强的荆棘茄甲和远古肥料包实现开局远古流",
    -- TIP_17 = "听说C键解控加回来了？？！",
    -- TIP_18 = "做珍珠时遇到鲨鱼和独角鲸不要慌，血量被砍了而且击杀给瓶子和鱼食",
    -- TIP_19 = "现已加入铥棒格挡与犀牛加强！同时，铥矿甲能够帮助法师提升血量上限",
    -- TIP_20 = "开局可以制作种子包和鸟嘴壶实现亩产一千八，鸟嘴壶具有更高的灌溉效率",
    -- TIP_21 = "在秋天，所有作物都可以适应季节生长，那么原本春天才能见到的某个生物或许能够提前见到....",
    -- TIP_22 = "你听说过有个强得可怕的boss吗？对对对，就是叫鱼啦啦",
    -- TIP_23 = "旺达作为老奶奶自带一次魔法科技应该很合理吧？󰀩 60岁还不退休当老年人有点说不过去了",
    -- TIP_24 = "多一些配合与理解，少一些责备与压力󰀐",
    -- TIP_25 = "长痛不如短痛，坐牢了忍一下就好󰀐",
    -- TIP_26 = "见贤思齐焉，见不贤而内自省也󰀐",
    -- TIP_27 = "旺达的第二次机会表只是在护盾期间受到的伤害为0，但不能帮你免除硬直，但是对于旺达的持续变老，或许指针在护盾消失后就会疯狂旋转...",
    -- TIP_28 = "月亮鹿人冲刺有具有cd的无敌立场、更高的血量上限和重击的破坏属性；暗影鹿人重击有概率恐惧敌人、更快的恢复速度和更高的重击伤害",
    -- TIP_29 = "󰀀克劳斯作为恶魔一族的大族长，能够使用吸取灵魂和灵魂跳跃的技能，同时其使用魔法鹿的能力也得到了加强󰀀",
    -- TIP_30 = "󰀟蜂后能更快进入后续的阶段，并会掉落蜂后帽蓝图，蜂后帽的属性也得到了很大的提升󰀟",
    -- TIP_31 = "麋鹿鹅的普通攻击会造成缴械和击退，被激怒的鹅妈妈或许会使用一些烦人的AOE技能",
    -- TIP_32 = "旺达能够制作一个时停表制造一个时停空间，将本该由其他生物流逝的时间，由自己承担...",
    -- TIP_33 = "击败铁巨人能够得到一个智慧帽，戴上它能够让你随时制作远古的稀有装备，当然也包括魔法科技和航海科技",
    -- TIP_34 = "旺达给予奶奶和牢麦的最好礼物——送钟（熟悉暗影魔法的薇克巴顿和麦斯威尔能够使用警告表，但是或许对钟表武器的陌生不能使其发挥所有的能力）",
    -- TIP_35 = "薇克巴顿出版社有了两本新书，一本能够量产硝石大理石，另一本使得她变成了“奶奶”",
    -- TIP_36 = "在女武神处于高灵感时，按下【shift+R】可以大幅提升其战斗和恢复能力，但是之后会陷入一段时间的虚弱",
    -- TIP_37 = "麦斯威尔右击自己可以一键召回所有的小人，减少/dance的麻烦。同时地上与地下的暗影空间互通了，那么谁是最大的受益者呢？",
    -- TIP_38 = "威尔逊在长期科研的努力下，获得了快速制作物品的能力",
    -- TIP_39 = "维斯具有全饥荒最强的生存能力——作祟气球能够随时复活，同时滑铲的无敌帧也给了他很好的表现",
    -- TIP_40 = "被小飞机扫描出来遗迹守卫听说会社死，是真的吗？",
    -- TIP_41 = "【多用斧镐】经过锤子的锻造升级成了【多用斧镐+】，这使得其拥有锤子的能力",
    TIP_42 = "WX-78可用 Shift+R 释放电球/冰球，电路与核能电池模块也更易上手",
    TIP_43 = "我上次玩逛街闲着没事去舞台表演，那里居然出现了野生的唤星者魔杖！",
    TIP_44 = "蜂群王后薇克巴顿已经苏醒！",
    TIP_45 = "麦斯威尔的工作仆人得到了加强，拥有原来双倍的工作效率！",
    TIP_46 = "天体英雄与远古织影者会随机携带七宗罪诅咒，战斗更像肉鸽。",
    TIP_47 = "沃姆伍德愿意为永恒领域的朋友们更多的牺牲自己身上的朋友们（植物人砍活木有概率砍出2-3个）",
    TIP_48 = "带电的攻击似乎并不能把Boss打出僵直，同时也不会使得植物类生物着火，这下可以安心种田了。",
    TIP_49 = "可以用排箫和兔子和兔王交换钢丝棉枕头，兔王现在除了胡萝卜，也愿意接受土豆和番茄的上供。",
    TIP_50 = "插上合唱盒电路，现在的WX-78就是场上最靓的仔",
    TIP_51 = "海狸拥有和鹿人一样的防御能力，在清理一些烦人的东西的时候或许有大帮助",
    TIP_52 = "WX-78掌握了【扩容】的能力，在自身积攒了一定数量的齿轮后，对模块芯片的使用将更加自如",
    TIP_53 = "忘记点猴尾草了？忘记点月火了？打完天体不想换月亮大头？那么可以在衣柜重置你的技能点！",
    TIP_54 = "薇洛娜可以制作一个便携基地，用于批量收纳自己的实验装置",

    LOVE_1 = "你知道你和星星的区别吗？星星在天上，你在我心里。",
    LOVE_2 = "我最近有点忙，忙着喜欢你。",
    LOVE_3 = "你有打火机吗？没有？那你是怎么点燃我的心的？",
    LOVE_4 = "我发现你不适合谈恋爱，适合结婚。",
    LOVE_5 = "你闻到什么味道了吗？没有？那为什么你一出现，空气都是甜的？",
    LOVE_6 = "你知道我想喝什么吗？我想呵护你。",
    LOVE_7 = "我们来玩个游戏吧，一二三木头人，不许动！糟糕，我心动了。",
    LOVE_8 = "我有一个超能力，超喜欢你。",
    LOVE_10 = "你是什么血型？A型？不对，你是我的理想型。",
    LOVE_11 = "莫文蔚的阴天，孙燕姿的雨天，都不如你和我的聊天。",
    LOVE_12 = "你知道现在几点了吗？是我们幸福的起点。",
    LOVE_14 = "你有地图吗？我在你的眼神里迷路了。",
    LOVE_15 = "猜猜我的心在哪边？左边？错，在你那边。",
    LOVE_17 = "你累不累？你都在我脑子里跑了一整天了。",
    LOVE_18 = "我想买一块地。什么地？你的死心塌地。",
    LOVE_19 = "你知道牛肉怎么吃才最好吃吗？我喂你吃。",
    LOVE_20 = "我觉得你今天有点怪。哪里怪？怪可爱的。"
}

local MOD_VERSION = GLOBAL.MOD_VERSION or "?"
-- 单条加载提示过长会导致 BitmapFontRenderer 断言崩溃（text_len < MAX_NUM_CHARS）
local MAX_LOADING_TIP_LEN = 118

-- DST mod 加载阶段没有全局 utf8，按字节截断并回退到合法 UTF-8 边界
local function TruncateLoadingTip(str, max_chars)
    if str == nil or str == "" or max_chars == nil then
        return str
    end
    local max_bytes = max_chars * 3
    if #str <= max_bytes then
        return str
    end
    local truncated = string.sub(str, 1, max_bytes)
    while #truncated > 0 do
        local b = string.byte(truncated, #truncated)
        if b < 0x80 or b >= 0xC0 then
            break
        end
        truncated = string.sub(truncated, 1, -2)
    end
    return truncated .. "…"
end

for i, v in pairs(LOADING_TIPS) do
    -- 情话条目不参与加载提示，减少注册数量与渲染压力
    if not string.match(i, "^LOVE_") then
        local tip_with_version = string.format("[%s] %s", MOD_VERSION, v)
        AddLoadingTip(
            GLOBAL.STRINGS.UI.LOADING_SCREEN_OTHER_TIPS,
            i,
            TruncateLoadingTip(tip_with_version, MAX_LOADING_TIP_LEN)
        )
    end
end

local death_messages_hunger = {
    "{NAME}撑死了",
    "{NAME}找不到食物",
    "{NAME}忘记吃东西了",
}

local death_messages_fire = {
    "三公里外都能闻到烤{NAME}的香味，凶手是{KILLER}",
    "{NAME}的满腔热血得不到释放，凶手是{KILLER}",
    "{NAME}无法把火扑灭，凶手是{KILLER}",
    "{NAME}被烧成了焦炭，凶手是{KILLER}",
    "{NAME}被烧得只剩渣了，凶手是{KILLER}",
    "{NAME}成了全熟牛排，凶手是{KILLER}",
}

local death_messages_hot = {
    "{NAME}把热水开关向右挪动了一毫米，凶手是{KILLER}",
    "{NAME}的脚趾头不小心踢到太阳了，凶手是{KILLER}",
    "{NAME}还在思考番茄酱怎么会发光，凶手是{KILLER}",
    "{NAME}没有找到空调遥控器，凶手是{KILLER}",
}

local death_messages = {
    "{NAME}的肠子被扯出来了，凶手是{KILLER}",
    "{NAME}的旅程结束了，凶手是{KILLER}",
    "{NAME}被浸渍了，凶手是{KILLER}",
    "{NAME}被放干了血，凶手是{KILLER}",
    "{NAME}被送到了骷髅区，凶手是{KILLER}",
    "{NAME}被自发切除了脑叶，凶手是{KILLER}",
    "{NAME}被压成了肉酱，凶手是{KILLER}",
    "{NAME}被碾成了肉泥，凶手是{KILLER}",
    "{NAME}的骨头被碾碎了，凶手是{KILLER}",
    "{NAME}成了怪物的食物，凶手是{KILLER}",
    "{NAME}的家被重塑了，凶手是{KILLER}",
    "{NAME}被迫自愿献血了，凶手是{KILLER}",
    "{NAME}被削顶了，凶手是{KILLER}",
    "{NAME}的顶髻被切掉了，凶手是{KILLER}",
    "{NAME}的零件放错了位置，凶手是{KILLER}",
    "{NAME}被混合成了爽口酱汁，凶手是{KILLER}",
    "{NAME}的脊椎被扯掉了，凶手是{KILLER}",
    "{NAME}的存活纪录被终结了，凶手是{KILLER}",
    "{NAME}接受了强制截肢，凶手是{KILLER}",
    "{NAME}的脖子被折断了，凶手是{KILLER}",
    "{NAME}被撕成了碎片，凶手是{KILLER}",
    "{NAME}死于致命伤，凶手是{KILLER}",
    "{NAME}被告知阳寿已尽，凶手是{KILLER}",
    "{NAME}的无能被展示了，凶手是{KILLER}",
    "{NAME}的灵魂被抽离了，凶手是{KILLER}",
    "{NAME}接受了慈悲的安乐死，凶手是{KILLER}",
    "{NAME}被自下而上地吃掉了，凶手是{KILLER}",
    "{NAME}被去骨了，凶手是{KILLER}",
    "{NAME}的两个肾脏都被偷了，凶手是{KILLER}",
    "{NAME}的堕落结束了，凶手是{KILLER}",
    "{NAME}的椎间盘突出了，凶手是{KILLER}",
    "{NAME}的遗体被捐赠给了科学，凶手是{KILLER}",
    "{NAME}的大脑变成了果酱，凶手是{KILLER}",
    "{NAME}变成了长猪，凶手是{KILLER}",
    "{NAME}被送到了农场，凶手是{KILLER}",
    "{NAME}咽下了最后一口气，凶手是{KILLER}",
    "{NAME}的心跳停止了，凶手是{KILLER}",
    "{NAME}被击中了头部，凶手是{KILLER}",
    "{NAME}被抹杀了，凶手是{KILLER}",
    "{NAME}受了脱套伤，凶手是{KILLER}",
    "{NAME}被剥了皮，凶手是{KILLER}",
    "{NAME}被围杀了，凶手是{KILLER}",
    "{NAME}被抽打了，凶手是{KILLER}",
    "{NAME}死翘翘了，凶手是{KILLER}",
    "{NAME}被谋杀了，凶手是{KILLER}",
    "{NAME}被放在玻璃棺材里了，凶手是{KILLER}",
    "{NAME}一命呜呼了，凶手是{KILLER}",
    "{NAME}很快就会被遗忘，凶手是{KILLER}",

    "{NAME}被杀死了，凶手是{KILLER}",
    "{NAME}被取出内脏了，凶手是{KILLER}",
    "{NAME}被谋杀了，凶手是{KILLER}",
    "{NAME}的脸被撕烂了，凶手是{KILLER}",
    "{NAME}的内脏被扯掉了，凶手是{KILLER}",
    "{NAME}被毁灭了，凶手是{KILLER}",
    "{NAME}的头骨被压碎了，凶手是{KILLER}",
    "{NAME}被屠杀了，凶手是{KILLER}",
    "{NAME}被刺穿了，凶手是{KILLER}",
    "{NAME}被撕成两半了，凶手是{KILLER}",
    "{NAME}被斩首了，凶手是{KILLER}",
    "{NAME}的胳膊断了，凶手是{KILLER}",
    "{NAME}看着自己的内脏变成了“外脏”，凶手是{KILLER}",
    "{NAME}被野蛮地解剖了，凶手是{KILLER}",
    "{NAME}被截肢了，凶手是{KILLER}",
    "{NAME}的身体血肉模糊了，凶手是{KILLER}",
    "{NAME}的重要器官毁了，凶手是{KILLER}",
    "{NAME}变成了一滩肉，凶手是{KILLER}",
    "{NAME}被踢出了世界，凶手是{KILLER}",
    "{NAME}被折成两半了，凶手是{KILLER}",
    "{NAME}的腰被斩断了，凶手是{KILLER}",
    "{NAME}被千刀万剐了，凶手是{KILLER}",
    "{NAME}求死的愿望实现了，凶手是{KILLER}",
    "{NAME}被削肉去骨了，凶手是{KILLER}",
    "{NAME}的挣扎终于停止了，凶手是{KILLER}",
    "{NAME}的脑袋搬家了，凶手是{KILLER}",

    "{NAME}在土豆里吃到了姜，凶手是{KILLER}",
    "{NAME}注定要死去，凶手是{KILLER}",
    "{NAME}打不过蝴蝶，凶手是{KILLER}",
    "{NAME}的战斗力甚至还没有种下的种子高，凶手是{KILLER}",
    "为了纪念{NAME}的这次死亡，我把死亡消息发了两次，凶手是{KILLER}",

    "{NAME}的饥荒将会在30分钟后从Steam库中移除，凶手是{KILLER}",
    "{NAME}，哦不，……{NAME}，凶手是{KILLER}",
    "{NAME}失败了，但这是你的安慰小礼品󰀒，凶手是{KILLER}",
    "{NAME}的饥荒试玩版到期了，凶手是{KILLER}",
    "{NAME}被送去见太奶了，凶手是{KILLER}",
    "{NAME}被送去见上帝了，凶手是{KILLER}",
    "{NAME}只是睡着了，凶手是{KILLER}",
    "{NAME}暴毙了（真的），凶手是{KILLER}",
    "{NAME}卡进洗衣机里了，凶手是{KILLER}",
    "一刻也没有为{NAME}的死亡哀悼，凶手是{KILLER}",
    "好像{NAME}正在举办派对，……不对，是暴毙了，凶手是{KILLER}",
    "{NAME}被送去拍《环太平间》了，凶手是{KILLER}",
    "{NAME}的饥荒是盗版，凶手是{KILLER}",
    "{NAME}踩到了乐高积木，凶手是{KILLER}",
    "{NAME}踩到棉花了，凶手是{KILLER}",
    "{NAME}不会背九九乘法表，凶手是{KILLER}",
    "……{NAME}……，凶手是{KILLER}",
    "{NAME}发现自己玩的是Terraria不是饥荒，凶手是{KILLER}",
    "{NAME}变成了麻辣烫里的两块肉饼，凶手是{KILLER}",
    "{NAME}的煤气炉忘关了，凶手是{KILLER}",
    "{NAME}呃啊了，凶手是{KILLER}",
    "{NAME}被吃掉了脑子，凶手是{KILLER}",
    "{NAME}的头盖骨被拿来当碗使了，凶手是{KILLER}",
    "{NAME}遇到了电车难题，凶手是{KILLER}",
    "{NAME}也许是没有做好准备，凶手是{KILLER}",
    "{NAME}从饥荒中被移除了，凶手是{KILLER}",
    "{NAME}怎么似了啊哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈，哈哈，哈，凶手是{KILLER}",
    "{NAME}闹肚子了，凶手是{KILLER}",
    "{NAME}赢了吗，没赢，凶手是{KILLER}",
    "{NAME}变成了死掉的{NAME}，凶手是{KILLER}",
    "{NAME}算不出1+1等于多少，凶手是{KILLER}",
    "{NAME}被管理员禁言了29天23小时59分钟，凶手是{KILLER}",
    "{NAME}石头剪刀布输了，凶手是{KILLER}",
    "{NAME}的项目没有保存，凶手是{KILLER}",
    "{NAME}的呼吸切换到了手动挡，凶手是{KILLER}",
    "{NAME}需要被加强了，凶手是{KILLER}",
    "{NAME}变成了大素，凶手是{KILLER}",
    "{NAME}去世了，而我要因为右边这个删不掉的句号去世了→，凶手是{KILLER}",
    "{NAME}被空气迎头痛击，凶手是{KILLER}",
    "{NAME}登不上创意工坊，凶手是{KILLER}",
    "{NAME}的眼睛进椰子了，凶手是{KILLER}",
    "{NAME}突然意识到225x2不是550，凶手是{KILLER}",
    "{NAME}释怀的似了，凶手是{KILLER}",
    "{NAME}变成了一只可怕的鬼魂，凶手是{KILLER}",
    "{NAME}感觉很健康，凶手是{KILLER}",
    "{NAME}被杀死了-1次，凶手是{KILLER}",
    "{NAME}有晕2.5D，凶手是{KILLER}",
    "{NAME}撞到空气墙了，凶手是{KILLER}",
    "{NAME}变成摩艾石像了，凶手是{KILLER}",
    "{NAME}已被打败，凶手是{KILLER}",
    "{NAME}没有晒够180天，凶手是{KILLER}",
    "{NAME}被扔进飞机发动机里了，凶手是{KILLER}",
    "{NAME}无了，凶手是{KILLER}",
    "旅商{NAME}已死去，凶手是{KILLER}",
    "{NAME}需要看广告才能复活，凶手是{KILLER}",
    "{NAME}被晾在了单杠上，凶手是{KILLER}",
    "{NAME}的完形填空没有出现在同一页，凶手是{KILLER}",
    "{NAME}出门忘记带头了，凶手是{KILLER}",
    "{NAME}被杀死了2147483647次，凶手是{KILLER}",
    "{NAME}被{NAME}谋杀了，凶手是{KILLER}",
    "{NAME}，后面忘了，凶手是{KILLER}",
    "有人死了，这次我不说是谁，凶手是{KILLER}",
}

AddSimPostInit(function()
    GLOBAL.GetNewDeathAnnouncementString = function(theDead, source, pkname, sourceispet)
        if not theDead or not source then return "" end
        local message = ""
        local killer
        --print("source is ", source)
        if source and not theDead:HasTag("playerghost") then
            if pkname ~= nil then
                local petname = sourceispet and STRINGS.NAMES[string.upper(source)] or nil
                if petname ~= nil then
                    killer = string.format(STRINGS.UI.HUD.DEATH_PET_NAME, pkname, petname)
                end
            elseif table.contains(GetActiveCharacterList(), source) then
                killer = FirstToUpper(source)
            end

            if not killer then
                source = string.upper(source)
                if source == "NIL" then
                    if theDead == "WAXWELL" then
                        source = "CHARLIE"
                    else
                        source = "DARKNESS"
                    end
                elseif source == "UNKNOWN" then
                    source = "SHENANIGANS"
                elseif source == "MOOSE" then
                    source = math.random() < .5 and "MOOSE1" or "MOOSE2"
                end
                killer = STRINGS.NAMES[source] or STRINGS.NAMES.SHENANIGANS
            end
            if source == "HUNGER" then
                local death_line = death_messages_hunger[math.random(#death_messages_hunger)]
                message = subfmt(death_line, { NAME = theDead:GetDisplayName() })
                return message
            end
            if source == "FIRE" then
                local death_line = death_messages_fire[math.random(#death_messages_fire)]
                message = subfmt(death_line, { NAME = theDead:GetDisplayName(), KILLER = killer })
                return message
            end
            if source == "HOT" then
                local death_line = death_messages_hot[math.random(#death_messages_hot)]
                message = subfmt(death_line, { NAME = theDead:GetDisplayName(), KILLER = killer })
                return message
            end
            local death_line = death_messages[math.random(#death_messages)]
            message = subfmt(death_line, { NAME = theDead:GetDisplayName(), KILLER = killer })
            if string.find(message, "发了两次") then
                TheNet:AnnounceDeath(message, theDead.entity)
            end
        else
            local gender = GetGenderStrings(theDead.prefab)
            if STRINGS.UI.HUD["GHOST_DEATH_ANNOUNCEMENT_" .. gender] then
                message = theDead:GetDisplayName() .. " " .. STRINGS.UI.HUD["GHOST_DEATH_ANNOUNCEMENT_" .. gender]
            else
                message = theDead:GetDisplayName() .. " " .. STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT
            end
        end

        return message
    end
end)
