# 100档噩梦模式

《饥荒联机版》（Don't Starve Together）模组，面向 **萌新俱乐部快餐档** 的 100 档噩梦玩法环境。在俱乐部「困难模式」基础上，对世界生成、Boss 强度、角色能力、配方与掉落等进行了大量调整，并可选启用 **骰子肉鸽（ROGE）** 对抗玩法。

| | |
|---|---|
| **当前版本** | `6.8.5`（见 [`modinfo.lua`](modinfo.lua)） |
| **作者** | 津酒昴 & 暗影大法师 |
| **适用环境** | 萌新俱乐部 100 档快餐档噩梦模式 |
| **GitHub** | [young1881/DST_nightmare_mode](https://github.com/young1881/DST_nightmare_mode) |

---

## Steam 创意工坊

| 版本 | 链接 |
|------|------|
| 正式服 | [100档噩梦模式（正式服）](https://steamcommunity.com/sharedfiles/filedetails/?id=3333664901) |
| 测试服 | [100档噩梦模式（测试服）](https://steamcommunity.com/sharedfiles/filedetails/?id=3350630427) |

> 本仓库为模组源码。玩家通常通过 Steam 创意工坊订阅；开发者可克隆本仓库进行本地调试或贡献代码。

---

## 模组简介

100 档噩梦模式是在饥荒萌新俱乐部「困难模式」基础上的深度魔改版本，主要特点包括：

- **100 档数值标准**：世界场景、角色属性、生物强度统一适配快餐档环境
- **Boss 全面强化**：天体英雄、远古织影者、铁巨人、恐惧之龙、眼球哨兵等均有机制与数值调整
- **全角色改动**：16 名可玩角色均有专属增强或重做（可在模组设置中逐项开关）
- **配方与掉落优化**：新增/调整大量配方，强化稀有材料获取与生活质量
- **七宗罪诅咒**：部分 Boss 在特定血量阶段随机获得诅咒 Buff
- **黎明杀饥模式（ROGE）**：可选的人类 vs 鬼方对抗玩法，韦伯附身生物对抗人类通关

> 建议先了解俱乐部「困难模式」基础玩法：[困难模式介绍](https://xiaochency.netlify.app/post/kunnan/)

---

## 安装

### 玩家（推荐）

1. 在 Steam 创意工坊订阅对应版本（正式服或测试服）
2. 创建/加入服务器时，在模组列表中启用 **100档噩梦模式**
3. 本模组要求 **所有客户端均安装**（`all_clients_require_mod = true`）
4. 按需在模组配置中开关各功能模块（见下方「模组配置」）

### 开发者（本地调试）

1. 克隆本仓库：

   ```bash
   git clone https://github.com/young1881/DST_nightmare_mode.git
   ```

2. 将文件夹放入 DST 模组目录：

   - Windows：`Documents/Klei/DoNotStarveTogether/mods/`
   - Linux：`~/.klei/DoNotStarveTogether/mods/`

3. 在游戏模组列表中启用，或通过 `modoverrides.lua` 指定加载

4. 发布到创意工坊前，在 [`modinfo.lua`](modinfo.lua) 中将 `is_test` 设为 `false`（正式服）或 `true`（测试服）

---

## 骰子肉鸽模式（ROGE）

在模组设置中开启 **「是否启用骰子肉鸽模式（roge 模块）」** 后，服务器可运行人类方 vs 鬼方的对抗规则。完整规则见 [`docs/rules.md`](docs/rules.md)。

| 阵营 | 人数 | 胜利条件 |
|------|------|----------|
| **人类方** | 最多 7 人（鬼方 3 倍） | 清空远古区域、击败铁巨人 |
| **鬼方** | 最多 4 人（固定韦伯） | 附身生物击杀全部人类，并保护铁巨人存活 |

**核心机制摘要：**

- 开局 Roll 点划分阵营，点数最小者为鬼方
- 鬼方鬼魂自带微光与加速；附身后按 **F** 攻击，鼠标调整朝向
- **Shift+T** 投掷骰子召唤生物（冷却 100 秒）；**Shift+Y / Shift+U** 在特定天数召唤控制型 / Boss 生物
- 人类每次复活永久损失 30% 最大生命值；可在暗影基座制作彩虹宝石兑换强心针
- 前若干天有巨型生物附身与召唤的时间限制（详见规则文档）

关闭 `roge` 配置项后，将不加载 `postinit/roge/` 下的骰子、附身限制、怪物池等逻辑；部分文件名含 roge 的模块仍会生效，详见 [`docs/与原100档版本对比.md`](docs/与原100档版本对比.md)。

---

## 模组配置

[`modinfo.lua`](modinfo.lua) 提供细粒度开关，主要模块如下：

| 配置项 | 说明 |
|--------|------|
| `roge` | 骰子肉鸽模式（ROGE 模块） |
| `boss` | 生物与 Boss 加强 |
| `jiaqiang` | 各类数值加强 |
| `peifang` / `diaoluo` | 配方修改 / 掉落加强 |
| `curse` | Boss 七宗罪诅咒系统 |
| `electrocute` | Boss 电击僵直与植物电击点燃调整 |
| `shadow_container` | 暗影空间同步（地上地下互通） |
| `wilson` … `wanda` | 各角色改动开关 |
| `webber` / `wurt` | 删除韦伯 / 沃特（非 ROGE 模式下） |
| `cookpot` / `sleep` / `zuowu` 等 | 红锅批量、帐篷加强、作物全季节等 QoL |

默认情况下上述选项均为 **开启**。

---

## 文档

| 文档 | 内容 |
|------|------|
| [`docs/wiki.md`](docs/wiki.md) | 完整玩法 Wiki：Boss 机制、角色改动、配方、掉落、更新日志 |
| [`docs/rules.md`](docs/rules.md) | 骰子肉鸽（黎明杀饥）对抗规则 |
| [`docs/与原100档版本对比.md`](docs/与原100档版本对比.md) | 相对原 100 档版本的差异与 `roge` 开关作用范围 |

---

## 项目结构

```
DST_nightmare_mode/
├── modmain.lua          # 模组入口，按配置加载各 postinit 模块
├── modinfo.lua          # 模组元信息与配置项
├── modworldgenmain.lua  # 世界生成
├── strings.lua          # 本地化字符串
├── postinit/            # 对原版逻辑的补丁（角色、Boss、ROGE 等）
├── scripts/             # Prefab、组件、AI、状态图等
├── images/              # UI 与物品栏贴图
└── docs/                # 玩法与规则文档
```

---

## 相关子 MOD

从 100 档中拆分出的独立模组（Steam 创意工坊）：

- [更好的女武神](https://steamcommunity.com/sharedfiles/filedetails/?id=3423908443)
- [更好的 WX-78](https://steamcommunity.com/sharedfiles/filedetails/?id=3507682816)
- [暗影空间同步](https://steamcommunity.com/sharedfiles/filedetails/?id=3375728448)
- [冰火哑铃与多用斧镐](https://steamcommunity.com/sharedfiles/filedetails/?id=3513692505)
- [移除电击特效](https://steamcommunity.com/sharedfiles/filedetails/?id=3548538134)

---

## 参与贡献

欢迎提交 Issue 与 Pull Request，包括但不限于：

- Bug 修复
- 平衡性调整
- 文档完善

开发前建议阅读 [`docs/与原100档版本对比.md`](docs/与原100档版本对比.md)，了解 `roge` 等配置项的实际加载范围。

---

## 免责声明

本模组为社区玩法定制，可能存在平衡性问题或未覆盖的边缘情况。若在俱乐部服务器上使用遇到问题，请联系对应管理员反馈。
