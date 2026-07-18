# War Card

War Card 是一个基于 Godot 4.6 的桌面卡牌战棋游戏。项目以“种族机制 + 棋盘战术 + 数据驱动卡牌”为核心：玩家先选择种族和英雄，再进入 7x7 棋盘对局，通过翻牌、部署、移动、攻击、施法、装备、升级和种族技能形成完整战斗闭环。

## 当前玩法

- **种族与英雄选择**：不同种族拥有独立机制、英雄、默认升级、衍生牌和配套法术。
- **7x7 分层棋盘**：内圈 5x5 是常规战场，外圈为边缘区域；飞行单位可进入空中层并可与地面单位同格存在。
- **等级牌池**：卡牌按 1-3 阶推进，低阶牌池耗尽后进入更高阶。
- **手牌系统**：支持法术、随从放置、升级牌、装备牌、英雄复活冷却牌和衍生牌。
- **行动系统**：移动、攻击、施法是主行动组；副动作、骑乘攻击、固定方向移动、瞬移、飞行、移动攻击等由通用行动资源系统处理。
- **状态系统**：支持圣盾、毒、火焰伤害、定身、隐身、魅惑、复生、护甲、生命上限修正、变身等可扩展状态。
- **地图/中立设计储备**：当前中立牌池是未来地图系统原型；长期方向是不同地图拥有不同中立牌包和环境规则。
- **表现层**：包含卡牌动画、全战场触发特效、持续状态覆盖、数值图标、战场种族 logo、装备面板、种族面板、暗夜时间面板、背景音乐和音效门面。

## 已接入种族

- **白银之手**：圣光、治疗、护盾、复活、装备和阵线保护。
- **达拉然议会**：法术工具箱、召唤、法术强度、奥术空间和法师体系。
- **苗疆族**：毒、蛊、毒虫、陷阱、吞噬和毒爆。
- **暗夜精灵哨兵**：月相时间、远程、夜晚奖励、飞行、骑乘和月刃。
- **狐妖仙**：尾数、献祭、魅惑、控制、复生、变身与狐火区域法术。
- **猴妖仙**：孙悟空神通、瞬移、透视、隐身、护甲、分身协攻、变身和猴族副动作。
- **野兽人**：同类斩杀进化、混沌腐蚀、兽径地形、兽王杀戮成长、鹰身女妖咆哮增益、萨满野性呼唤和万魔岩仪式。
- **东京喰种**：初始为高 RC 浓度；每次击杀敌方非英雄随从立即提升一级，无杀戮回合结束时降低一级，低浓度无杀戮会随机分食友方非英雄喰种。施法回合在该种族中表现为“赫子解放”，四类赫子通过持续至下个己方回合开始的能力快照，提供攻速、移动攻击与攻击/吸血、护甲/反伤或羽针副动作；尾赫在普通与高浓度下均为攻速 +1。金木研拥有尾赫法术和三种可主动恢复原形的覆盖形态；13区咖啡店可以提供治疗咖啡并缩短其复活冷却。芳村功善与高槻泉的枭形态同样可以主动结束。SSS 阶喰种情报可提供芳村功善、高槻泉、旧多二福与死堪，包含赫者化、全体恢复、RC 提升、正面五格攻击、双重免疫以及四赫子同时解放等能力。S 阶与 SSS 阶喰种情报作为两套独立的有限随从库持续提供稀有单位。
- **影月议会**：古尔丹、灵魂虹吸、邪能灌注、邪能狂乱、混乱兽人、地狱犬、术士、基尔加丹的低语、混乱狼骑兵、末日守卫、地狱火、黑暗之门、魅魔与古尔丹之杖；以邪能标签触发本回合疯狂状态，装备可升级施法动作并引发邪能过载，术士诅咒引入可复用的伤害加深状态，地狱火引入火焰伤害持续状态，黑暗之门使用通用周期触发持续提供恶魔兵源。

## 项目结构

```text
war-card/
├── data/
│   ├── cards.json              # 种族、英雄、卡牌、衍生牌
│   └── audio.json              # BGM/SFX 配置
├── docs/
│   ├── architecture.md         # 系统架构、规则边界、长期设计
│   ├── codex-working-map.md    # 开发任务快速索引
│   └── runtime-effect-lifecycle.md # 跨回合效果与状态时点约定
├── scenes/                     # Godot 场景
├── scripts/
│   ├── actions/                # 移动、攻击、施法、副动作等行动
│   ├── ai/                     # AI 候选生成、评估和执行
│   ├── audio/                  # 音频管理
│   ├── data/                   # CardData/CardState/PlayerState 等模型
│   ├── effects/                # JSON 驱动的通用效果
│   ├── game/                   # 对局编排、目标、死亡、触发、棋盘 resolver
│   └── ui/                     # 动画门面、主题 provider、面板、手牌、状态覆盖
├── assets/
│   ├── img/                    # 卡面、图标、UI 图片
│   └── music/                  # 背景音乐
├── tools/
│   └── validate_cards.py       # 卡牌数据校验
├── main.tscn
└── project.godot
```

## 架构原则

- **数据优先**：卡牌能力优先通过 `data/cards.json` 配置，规则代码提供通用能力。
- **规则与表现分离**：`scripts/effects/` 和 `scripts/actions/` 修改规则状态；动画、音效和 UI 由表现层 resolver 处理。
- **HUD 生命周期集中编排**：`GameHudCoordinator` 统一组织各对局面板的创建与刷新，panel controller 管内容，`RightSideHudLayoutController` 管位置，`GameManager` 仅保留稳定门面。
- **HUD 卡图统一预览**：种族状态牌与装备牌通过 `CardTexturePreviewController` 共享悬浮大图、视口内定位和显示生命周期。
- **自适应手牌抽屉**：法术、随从、升级、装备四区保留独立滚动，空区自动收缩，非空区按卡牌行数共享可用高度，焦点切换不会改变布局或重置滚动位置。
- **法术特效模块化**：`SpellAnimationRouter` 按目标单位、矩形、来源矩形、全战场、多格路径和范围区域六种表现上下文分派 animation key；普通施法回合由通用 provider 播放蓝金法阵，各种族 provider 独立维护主题视觉。
- **统一入口**：目标选择走 `SpellTargetResolver`，死亡走 `DeathResolver`，补牌走 `BoardSlotResolver`，棋盘层级走 `BoardLayerResolver`，行动资源走 `ActionResourceResolver`。
- **死亡可追溯**：所有击杀、范围伤害、亡语和直接摧毁都通过 `DeathResolver`，并携带击杀来源，确保矿脉资源分、复生、亡语和补牌稳定结算。
- **状态可驱散**：可被净化/驱散的属性变化应实现为状态，不直接永久改数值。
- **衍生牌可查不可入池**：衍生牌定义在种族 `tokens[]`，注册到全局卡牌表，但不进入常规牌池。
- **卡图按需加载**：数据库初始化只解析图片路径，卡面、战场图和卡背在具体 UI 首次使用时加载并缓存，避免启动时解码全部美术资源。
- **文档 UTF-8**：所有文档保持 UTF-8；若出现乱码，先修复编码再继续编辑。

## 快速开始

1. 安装 Godot 4.6+。
2. 克隆仓库。
3. 用 Godot 打开 `project.godot`。
4. 运行 `main.tscn`。

## 验证命令

```powershell
python tools/validate_cards.py
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_data_lazy_textures.gd -SuccessMarker CARD_DATA_LAZY_TEXTURES_TEST_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_tokyo_ghoul.gd -SuccessMarker TOKYO_GHOUL_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_rc_concentration.gd -SuccessMarker RC_CONCENTRATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_texture_preview.gd -SuccessMarker CARD_TEXTURE_PREVIEW_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_reserve.gd -SuccessMarker CARD_RESERVE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_status_attack_override.gd -SuccessMarker STATUS_ATTACK_OVERRIDE_TESTS_OK
```

修改 `data/cards.json` 后至少运行卡牌校验；修改动画路由/provider 后额外运行 `tools/test_animation_routing.gd`；修改脚本、场景、表现层或玩法流程后运行 Godot 检查。

Windows 下不要直接运行 `godot --headless --path . --check-only`：Godot 4.6 在项目模式下不会可靠退出，而 PowerShell 会提前返回，长期使用会累积隐藏的 `godot.exe` 并耗尽内存。统一使用 `tools/run_godot_validation.ps1`，它会等待真实退出、限制执行时间，并只清理本次启动的进程。

## 文档

- [架构说明](docs/architecture.md)：系统边界、规则设计、长期方向。
- [Codex 工作索引](docs/codex-working-map.md)：常见任务应该先读哪些文件。
- [运行时效果生命周期](docs/runtime-effect-lifecycle.md)：多入口效果、跨回合状态、快照与失效时点的统一约定。

## License

MIT
