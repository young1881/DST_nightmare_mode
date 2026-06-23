# Wiki 与代码不一致清单

> **用途**：记录 `docs/wiki.md`（及语雀同步正文）与当前仓库代码之间的数值/机制差异。  
> **权威来源**：以代码为准；修 wiki 或改代码前请先核对本表。  
> **核对时间**：2026-06-14  
> **代码版本参考**：mod 约 v6.8.5（wiki 文档头标注 v6.5.8 / 2026-6-9，已滞后）

---

## 使用说明

| 列 | 含义 |
|----|------|
| Wiki | `docs/wiki.md` 静态正文或更新日志中的描述 |
| 代码 | 当前实现（文件/常量） |
| 状态 | `待修 wiki` = 建议改文档；`待修代码` = 建议改实现；`待确认` = 设计意图不明 |

---

## 一、Boss / 怪物

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 遗迹守卫（扫描者召唤） | 血量 **1400** | **`spider_robot`** 血量 **1500**，攻击 **200** | `scripts/prefabs/ancient_robots.lua`；扫描逻辑 `scripts/prefabs/ancient_scanner.lua` | 待修 wiki |
| 远古织影者二阶段阈值 | **68000** 起进入二阶段 | **75000**（`STALKER_ATRIUM_PHASE2_HEALTH`） | `postinit/jiaqiang.lua` | 待修 wiki |
| 织影者吃编制暗影回血 | 单个恢复 **4000** | **5000**（`STALKER_FEAST_HEALING`） | `postinit/jiaqiang.lua` | 待修 wiki |
| 编制暗影（`stalker_minion`）血量 | **25** | **15** | `postinit/stalker.lua` | 待修 wiki |
| 天体寄生亮茄血量 | **1500** | **1800** | `postinit/alterguardian.lua` | 待修 wiki |
| 蜘蛛女皇生产高等蜘蛛 | 每攻击 **4** 次 | 每攻击 **5** 次（`SPIDER_QUEEN_SPAWN_EVERY_N_ATTACKS`） | `scripts/nightmare/spider_queen.lua` | 待修 wiki |
| 果蝇王出现天数 | 成熟 **9** 天 | **8** 天（`LORDFRUITFLY_INITIALSPAWN_TIME = 8 * 480`） | `postinit/jiaqiang.lua` | 待修 wiki |
| 附身铠甲 / 白云（`ironlord`） | wiki 未单独列出 | 血量 **15000** | `postinit/jiaqiang.lua` | 待补 wiki |

**已与代码一致（wiki 可保留）**：天体英雄 6w/8w/10w、恐惧之龙 2000 血/125 物理攻、远古守卫者 15000 血、梦魇疯猪 30000 血、眼球哨兵塔 1400 血、晶体巨鹿 50000 血、蜘蛛女皇 10000 血、大冰鲨 roge 5000/第 8 天 8000 等。

---

## 二、七宗罪诅咒

| 诅咒 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 嫉妒 | 每 **3** 秒吸取 15 血 | 每 **6** 秒（`ENVY_INTERVAL = 6`） | `postinit/curse.lua` | 待修 wiki |
| 暴怒 | 武器耐久加倍持续 **1 分钟** | 持续 **10 秒**（`WRATH_DURATION = 10`） | `postinit/curse.lua` | 待修 wiki |

**已与代码一致**：傲慢 +20% 伤害、色欲减伤 20%、贪婪偷 1~3 件、暴食扣 5% 饱食且吸收减半 20 秒等。

---

## 三、肉鸽 / 骰子模式

| 项目 | Wiki / rules.md | 代码 | 代码位置 | 状态 |
|------|-----------------|------|----------|------|
| 骰子 + 召唤共用 CD | 100 秒（wiki 6.11 changelog；`rules.md` 第 9 行） | **120 秒**（`ROGE_DICE_SHARED_COOLDOWN`） | `postinit/roge/roll.lua` | 待修 wiki / rules |
| 怪物池分级 CD | 120 / 200 / 400–600（wiki 6.6） | 仅见统一 **120s** 掷骰召唤 CD | `postinit/roge/roll.lua` | 待确认 |
| Shift+Y 控制型召唤 | **第七天** | **第 6 天起**（`ROGE_SHIFT_Y_SUMMON_MIN_DAY = 6`，提示文案「第6天起」） | `postinit/roge/roll.lua` | 待修 wiki |
| 鱿王 / 恐惧之龙附身 | **6.5 天**（6.11 changelog） | **第 6 天黄昏**（`cycles=5, time=0.5`） | `postinit/roge/ghost.lua` | 待修 wiki |
| 普通 Boss 附身 | 第四天（6.11） | **第 4 天起**（`ROGE_HAUNT_PREMIUM_MIN_CYCLES = 3`） | `postinit/roge/ghost.lua` | 与 changelog 一致 |
| 沃托克斯群体治疗 | 每造成 **400** 伤害，**4** 格半径各回 10 血 | 每 **500** 伤害，**3** 格半径（`3*4` 世界单位） | `postinit/wortox.lua` | 待修 wiki |
| 死亡扣最大生命 | 每次 **-30%** | 一致；有效血下限 **50%**（`MAXIMUM_HEALTH_PENALTY = 0.50`） | `postinit/roge/ghost.lua` | wiki 可补充下限 |
| 第 8 天 Boss 血量 | 1.5~2 倍 | roge 统一 **×1.5**（`ROGE_DAY8_HEALTH_MULT = 1.5`） | `postinit/roge/roll.lua` | 待修 wiki（上限 2 倍已不适用） |

---

## 四、人物 — 麦斯威尔

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 暗影突袭触发 | 攻击 **6** 次 | **4** 次（`HITS_REQUIRED = 4`） | `modmain.lua`、`postinit/waxwell.lua` | 待修 wiki |
| 秘典耐久消耗 | **30%** | **20%**（`JOURNAL_FUEL_COST_PERCENT = 0.2`） | `modmain.lua` | 待修 wiki |
| 暗影突袭伤害 | 固定 **300**（6×30+6×20） | 武器物理 ×**1.0** + 位面 ×**1.5**（按当前装备动态计算） | `modmain.lua`、`scripts/nightmare/passive_shadow_fx.lua` | 待修 wiki |
| 暗影牢笼 | 初始 5 秒，受击后 1/5，每证明 +1.5 秒 | 一致 | `postinit/roge/ghost.lua` | — |

---

## 五、人物 — 沃尔特

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 三维 | 113 / 113 / 113 | 一致 | `postinit/walter.lua` | — |
| 摔下沃比伤害阈值 | **20** | **30**（`WALTER_WOBYBUCK_DAMAGE_MAX`） | `postinit/walter.lua` | 待修 wiki |
| 弹弓位面防御 | **5** | **10** | `postinit/walter.lua` | 待修 wiki |
| 松树先锋队帽防御 | 80% + 5 位面防 | 80% + **5** 位面防（一致） | `postinit/walter.lua` | — |
| 便携式帐篷次数 | **5** 次 | 一致（`TUNING.PORTABLE_TENT_USES = 5`） | `postinit/sleep.lua` | — |
| 石头弹单次制作数量 | **20** | **30** | `postinit/walter.lua` | 待修 wiki |
| 黄金弹 | 20 | **40** | 同上 | 待修 wiki |
| 大理石弹 | 30 | **50** | 同上 | 待修 wiki |
| 冰弹 | 10 | **25** | 同上 | 待修 wiki |
| 减速弹 | 15 | **30** | 同上 | 待修 wiki |
| 铥弹 | 15 | **30** | 同上 | 待修 wiki |
| 子弹伤害（石头/金/大理石/铥） | 34/51/59.5/68 等 | 一致 | `postinit/walter.lua` | — |
| 玻璃 / 亮茄 / 虚空弹 | 68；34+34 位面；34 位面+动态物理 | 一致 | `scripts/prefabs/newammo.lua` | — |

---

## 六、人物 — 旺达

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 开局额外时间碎片 | **+1** | **+5**（循环插入 5 次 `pocketwatch_parts`） | `postinit/wanda.lua` | 待修 wiki |
| 恐惧表（纯粹恐惧升级警告表）位面伤害 | **20** | **35** | `postinit/wanda.lua` `MakeHorrorClock` | 待修 wiki |
| 恐惧表位面防御 | **15** | **20** | 同上 | 待修 wiki |
| 恐惧表移速 | **20%** | **25%**（`walkspeedmult = 1.25`） | 同上 | 待修 wiki |
| 时停表消耗年龄 | **12** 岁 | `POCKETWATCH_HEAL_HEALING * 1.5`（通常等价 12） | `scripts/prefabs/pocketwatch_cherrift.lua` | 基本一致 |
| 充能倒走表随机传送 | 6.4：消耗 **12** 岁 | **12** 岁（`ROGE_BACKTREK_RANDOM_AGE_COST`） | `postinit/wanda.lua` | changelog 一致，静态 wiki 未写 |
| 岁月表 CD | 不老表一半 | 由 `postinit/announce.lua` 引用 `POCKETWATCH_HEAL_COOLDOWN / 2` | 待核对原版 TUNING | 待确认 |

---

## 七、人物 — 薇洛

| 项目 | Wiki / 更新日志 | 代码 | 代码位置 | 状态 |
|------|----------------|------|----------|------|
| 火龙之魂余烬消耗 | **15** | **10**（`BURN_SELF_EMBER_COST`） | `postinit/willow.lua` | 待修 wiki |
| 光环持续时间 | **40s** | **60s**（`BURNING_SELF_DURATION`） | 同上 | 待修 wiki |
| 受击反伤 | 30~50 | **30~50** | 同上 | — |
| 剧烈燃烧物伤 / 位面伤 | 100~200 / 100~150 | **150~250** / **150~200** | 同上 | 待修 wiki |
| 剧烈燃烧减持续时间 | **5s** | **3s**（`BURN_SELF_EXPLODE_DURATION_PENALTY`） | 同上 | 待修 wiki |
| 余烬堆叠上限 | **80** | **80** | 同上 | — |
| 月火（参考） | 更新日志 6.11 降 12 点伤害等 | 物理 **38.5**、位面 **28.5**、持续 **3.5s**、CD **4.5s** | `postinit/willow.lua` | 静态 wiki 未同步 |

---

## 八、人物 — 沃姆伍德

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 光合作用 | 每恢复 **5** 血消耗 **15** 饱食 | 每 **10** 秒 +**3** 血、-**5** 饱食（需技能点 + 亮光） | `postinit/wormwood.lua` | 待修 wiki |
| 全局生命恢复 +25% | 5.22 更新日志 | **代码中未找到对应实现** | — | 待确认（可能已移除） |
| 荆棘茄甲耐久 | **935** | **1250** | `postinit/wormwood.lua` | 待修 wiki |
| 荆棘茄甲位面防御 | **15** | **20** | 同上 | 待修 wiki |
| 荆棘茄甲位面反伤 | **35** | **40**（`ARMORBRAMBLE_DMG_PLANAR_UPGRADE`） | 同上 | 待修 wiki |
| 荆棘专家触发次数 | 正文写「两次攻击」，后文写一次 | **1** 次攻击（`WORMWOOD_ARMOR_BRAMBLE_RELEASE_SPIKES_HITCOUNT = 1`） | 同上 | 待修 wiki |
| 物理反伤 | 35 | **35** | 同上 | — |
| 鸟嘴壶浇水 | 效率提高 | `PREMIUMWATERINGCAN_WATER_AMOUNT = 45` | `postinit/jiaqiang.lua` | wiki 未写具体数值 |

---

## 九、人物 — 沃尔夫冈

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 恶魔形态每日加成 | 每天 +0.1，最高 20 天 | 20 天线性满额 +**2.0** 额外倍率（`DAY_TO_MAX=20`, `MAX_BONUS=2`） | `postinit/wolfgang.lua` | 语义一致 |
| 斋戒加成 | 文档笔误「**0.**伤害」（应为 0.2） | **0.2** 伤害 + **0.2** 减伤，**60** 秒无回血触发 | 同上 | 待修 wiki 笔误 |
| 低理智掉肌肉 | 每秒 **1** 点（1.14 更新） | 理智为 0 时每秒 **0.5**（`ZERO_SANITY_MIGHTINESS_DRAIN`） | 同上 | 待修 wiki 或代码 |
| 口哨队友回理智 | 每名队友沃尔夫冈额外 **+15** | 一致 | `postinit/wolfgang.lua` | — |
| 破击（Shift+R） | 6.10 新增，6.13 **已移除** | 代码中无 `破击` 实现 | — | wiki 应标注已移除 |

---

## 十、人物 — 女武神

| 项目 | Wiki | 代码 | 代码位置 | 状态 |
|------|------|------|----------|------|
| 雷霆打击 | **62** 战意，+100 位面伤（5.30 静态正文） | 已改为 **冲天刺**：**51** 战意、**8s** CD、**180** 位面、**2.5×** 伤害倍率 | `postinit/wigfrid_sky_pierce.lua` | 待修 wiki |
| 冲天刺耐久恢复 | 6.11：每击中目标武器 **+15** | **15**（`SKY_PIERCE_HIT_REPAIR`） | 同上 | changelog 一致，静态未写 |
| 战斗号子罐羽毛 | **3 红毛 + 5 黑毛** | **2** `feather_crow`（黑）+ **5** `feather_robin`（红） | `postinit/wigfrid.lua` | 待修 wiki |
| 阿比盖尔等级血量 | 250 / 500 / 1000 | 一致 | `postinit/wendy.lua` | — |
| 虚影阿比冲刺最低伤害保留 | **30%** | **30%**（`ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MIN_MULT`） | `postinit/wendy.lua` | — |

---

## 十一、人物 — 其他

| 角色 | 项目 | Wiki | 代码 | 状态 |
|------|------|------|------|------|
| 温蒂 | 阿比盖尔位面伤害 +5 | 有描述 | 通过光之怒等配置，等级血量一致 | 基本一致 |
| 麦斯威尔 | 工作仆人砍树挖矿 ×2 | 有描述 | `postinit/waxwell.lua` 等 | 待专项核对 |
| 维斯 | 复活恢复全部生命上限 | 有描述 | 待专项核对 | 待确认 |
| 沃利 | 特殊料理 buff ×2 | 有描述 | `postinit/warly.lua` | 待专项核对 |

---

## 十二、配方与掉落

| 项目 | Wiki | 代码 | 状态 |
|------|------|------|------|
| 赛博珍珠 | 10 月岩 + 7 证明 + 1 火花柜 + 5 橙宝石 | 一致 | — |
| 枕头 | 8 萝卜 + 10 兔绒 + 2 钢丝绒 | **1 排箫 + 4 兔子**（兔王兑换） | 待修 wiki |
| 以太余烬 | 0 打火机 + 3 灰烬 + 1 余烬 | 一致；一次给 **6** 个 | — |
| 树果酱 | 1 玻璃 + 2 金子 + 2 腐烂 | **仓库内未找到 mod 配方** | 待确认 |
| 海象象牙 | 25%/50% 得 2/1 个等细分概率 | `walrus_tusk` 额外掉落 chance **0.8**；小海象 **0.6** | 待修 wiki（简化表） |
| 伏特羊羊角 | 额外 5% | **20%**（`lightninggoathorn` 0.2） | 待修 wiki |
| 龙蝇羊角 | 必定 1 个 | **100%** chance loot | — |
| 克劳斯坎普斯包 | 必定 + 小概率额外 | 一致 | — |
| 曼德拉长老活木 | 2~4 个 | 掉落表 1.0×2 + 0.5 + 0.25 等，期望约 2~4 | 基本一致 |

---

## 十三、wiki 结构 / 内容滞后（非单一数值）

1. **更新日志 vs 静态正文脱节**：如骰子 CD、冲天刺 51 灵感、附身天数等已在 changelog 更新，但「人物修改」「怪物调整」章节仍是旧版。
2. **已移除内容仍出现在正文**：海象猎杀小队（6.9 暂时移除）、沃尔夫冈破击（6.13 移除）、大虚影等。
3. **生物名称易混淆**：
   - 「遗迹守卫」= 扫描者召唤的 **`spider_robot`**（1500 血），不是 `ruinsnightmare`（潜伏梦魇）。
   - 「眼球哨兵守卫」= **`shadoweyeturret` / `ruinseyeturret`**（1400 血）。
   - 「附身铠甲 / 白云」= **`ironlord`**（15000 血）。
4. **`docs/rules.md` 与代码**：第 9 行骰子 CD 写 **100 秒**，代码为 **120 秒**；附身/天数规则与 `postinit/roge/` 部分表述不一致，需与 roge 模块一并修订。

---

## 十四、建议修 wiki 的优先级

| 优先级 | 条目 |
|--------|------|
| P0 | 麦斯威尔暗影突袭；肉鸽骰子 CD 120s；附身/召唤天数；遗迹守卫 1500 血与 prefab 名称 |
| P1 | 旺达开局碎片 + 恐惧表；薇洛火龙之魂；沃姆伍德光合作用 + 荆棘茄甲；七宗罪嫉妒/暴怒 |
| P2 | 沃尔特弹药数量与摔落阈值；女武神冲天刺替代雷霆打击；织影者/编制暗影数值 |
| P3 | 配方细节（枕头、树果酱）；象牙掉落概率表述；移除已下线玩法说明 |

---

## 附录：主要配置文件索引

| 文件 | 内容 |
|------|------|
| `postinit/jiaqiang.lua` | 全局 Boss TUNING（天体、织影者、蜂后、春鹅等） |
| `postinit/roge/roll.lua` | 骰子天数、CD、第 8 天血量倍率 |
| `postinit/roge/ghost.lua` | 附身天数、死亡惩罚、牢笼、韦伯鬼魂 |
| `postinit/roge/boss_pool.lua` | 怪物池、召唤物血量 |
| `postinit/curse.lua` | 七宗罪诅咒数值 |
| `postinit/walter.lua` | 沃尔特三维、弹药 |
| `postinit/wanda.lua` | 旺达年龄、恐惧表、倒走表 |
| `postinit/willow.lua` | 薇洛月火、火龙之魂、余烬 |
| `postinit/wormwood.lua` | 植物人光合作用、荆棘茄甲 |
| `postinit/wolfgang.lua` | 沃尔夫冈恶魔形态、斋戒 |
| `postinit/wigfrid_sky_pierce.lua` | 冲天刺 |
| `postinit/wortox.lua` | 沃托克斯灵魂治疗 |
| `scripts/nightmare/spider_queen.lua` | 蜘蛛女皇 |
| `scripts/prefabs/ancient_robots.lua` | 遗迹守卫 spider_robot |
| `modmain.lua` | 暗影突袭默认常量 |

---

*本文件随代码或 wiki 变更需人工更新；建议在发版前 diff 一次 `postinit/jiaqiang.lua` 与 `postinit/roge/`。*
