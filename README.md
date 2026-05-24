# War Card

基于 Godot 4.6 的卡牌策略对战游戏。

## 玩法概述

双方在棋盘上翻牌、布阵、施法，通过随从战斗与资源积累达成胜利目标。

### 核心机制

- **棋盘对战**：9×8 棋盘，单位可移动、攻击、施法
- **双种族**：白银之手（圣光系）vs 达拉然议会（奥术系）
- **英雄系统**：每位英雄携带专属配套卡牌
- **等级牌池**：卡牌按 1-3 级分池，低级牌先被抽取
- **手牌法术**：法术牌通过手牌系统使用，支持目标选择
- **升级牌**：手牌内持续生效的被动/光环效果
- **装备系统**：英雄可装备武器，触发攻击后效果
- **状态系统**：圣盾、光环等运行时状态，可叠加可倒计时
- **法术强度**：装备提供的法强加成伤害/治疗/护盾
- **坟场与复活**：阵亡单位进坟场，法术可复活
- **建筑系统**：中立建筑可被攻击摧毁，奖励资源分

## 项目结构

```
war-card/
├── data/
│   └── cards.json              # 所有卡牌静态数据
├── docs/
│   ├── architecture.md         # 详细架构文档
│   └── codex-working-map.md    # 任务快速索引
├── scenes/                     # 场景与节点脚本
│   ├── card/                   # 卡牌节点
│   ├── card_board/             # 棋盘节点
│   ├── debug/                  # 调试面板
│   └── start_menu/             # 开始菜单
├── scripts/
│   ├── actions/                # 行动系统（移动、攻击、施法）
│   ├── data/                   # 数据层（卡牌、玩家、状态、牌池）
│   ├── effects/                # 效果系统（治疗、伤害、护盾等）
│   ├── game/                   # 游戏规则（管理器、触发器、结算器）
│   └── ui/                     # 表现层（动画、菜单、状态覆盖）
├── assets/img/                 # 卡牌与 UI 图片资源
├── main.tscn                   # 主场景入口
└── project.godot               # Godot 项目配置
```

### 架构分层

| 层 | 职责 | 目录 |
|---|---|---|
| 数据定义 | JSON 配置、静态卡牌数据、运行时状态结构 | `data/`, `scripts/data/` |
| 效果执行 | 仅修改游戏状态，不操作 UI | `scripts/effects/` |
| 规则编排 | 触发、回合、死亡、目标、胜负 | `scripts/game/` |
| 行动系统 | 移动、攻击、施法的目标校验与执行 | `scripts/actions/` |
| UI 表现 | 动画、菜单、状态视觉、手牌展示 | `scripts/ui/`, `scenes/` |

## 技术栈

- **引擎**：Godot 4.6
- **语言**：GDScript
- **数据**：JSON（卡牌配置）
- **版本控制**：Git

## 快速开始

1. 安装 [Godot 4.6+](https://godotengine.org/)
2. 克隆仓库：`git clone https://github.com/dacaidian/-.git`
3. 用 Godot 打开 `project.godot`
4. 运行 `main.tscn`

### 验证命令

```bash
# 卡牌数据引用校验
python tools/validate_cards.py

# JSON 格式校验
python -m json.tool data/cards.json

# Godot 语法检查
godot --headless --path . --check-only
```

## 开发约定

- **数据驱动**：卡牌效果优先通过 JSON 配置，不硬编码
- **效果注册**：新增效果在 `EffectRegistry` 注册，不修改 `Card` 或 `CardState`
- **规则与 UI 分离**：效果层只改状态，动画由 `GameManager` 编排
- **上下文常量**：触发名和上下文 key 统一放 `EventContext` 和 `EffectData`
- **目标解析**：法术目标规则统一在 `SpellTargetResolver`，效果目标在 `CardEffect.get_target_states()`

## License

MIT
