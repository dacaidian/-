# War Card

War Card 是一个基于 Godot 4.6 的桌面卡牌战棋游戏。项目以“种族机制 + 棋盘战术 + 数据驱动卡牌”为核心：玩家从主菜单进入种族与英雄选择，再进入 7x7 棋盘对局，通过翻牌、部署、移动、攻击、施法、装备、升级和种族技能形成完整战斗闭环。

## 当前玩法

- **完整应用流程**：主菜单提供开始游戏、牌局历史、卡牌图鉴和退出入口；图鉴支持完整卡牌浏览、组合筛选、搜索、排序和详情查看，牌局历史保留独立页面骨架。种族选择可返回主菜单，对局可确认投降，资源胜利和投降共用结算与返回流程。
- **卡牌图鉴**：按种族归档普通牌与衍生牌，明确区分常规牌池、默认入手、衍生牌和状态展示；支持英雄专属关系、阶级、类型、来源、中文关键字搜索和分页卡墙。
- **种族与英雄选择**：不同种族拥有独立机制、英雄、默认升级、衍生牌和配套法术。
- **7x7 分层棋盘**：规则层始终保留完整 7x7 棋盘；默认视图放大中央 5x5，玩家可通过“完整战场”开关查看飞行外环。飞行单位可进入空中层并可与地面单位同格存在，切换视图不会重建槽位或改变格子能力。
- **等级牌池**：卡牌按 1-3 阶推进，低阶牌池耗尽后进入更高阶。
- **手牌系统**：支持法术、随从放置、升级牌、装备牌、英雄复活冷却牌和衍生牌。
- **行动系统**：移动、攻击、施法是主行动组；副动作、骑乘攻击、固定方向移动、瞬移、飞行、移动攻击等由通用行动资源系统处理。
- **状态系统**：支持圣盾、毒、火焰伤害、定身、隐身、魅惑、复生、护甲、生命上限修正、变身等可扩展状态。
- **地图/中立设计储备**：当前中立牌池是未来地图系统原型；长期方向是不同地图拥有不同中立牌包和环境规则。
- **表现层**：包含卡牌动画、全战场触发特效、跟随单位的持续区域 VFX、持续状态覆盖、数值图标、战场种族 logo、统一位图 UI 皮肤、右侧战斗 HUD、装备面板、种族面板、暗夜时间面板、背景音乐和音效门面。主菜单、图鉴、手牌抽屉和 HUD 共用木质、黑铁、古铜与深蓝皮革视觉语言，按钮具备普通、悬浮、按下和禁用四态；主菜单使用独立 `WARCARD` 艺术标题，图鉴使用透明徽记强化页面识别。

## 已接入种族

- **白银之手**：圣光、治疗、护盾、复活、装备和阵线保护。
- **达拉然议会**：法术工具箱、召唤、法术强度、奥术空间、吉安娜方向法术、巨水元素、极寒风暴光环和法师体系；奥术、冰霜、火焰、水元素使用统一学院派视觉语言与独立技能节奏。
- **苗疆族**：毒、蛊、毒虫、陷阱、吞噬和毒爆；蛊术使用虫卵、菌丝、毒液、朱砂链接与草药烟气构成的统一有机视觉语言，并区分潜伏、成熟和结算阶段。
- **暗夜精灵哨兵**：月相时间、远程、夜晚奖励、飞行、骑乘和月刃；特效采用“稳定 Provider 门面、战斗/辅助/天象/时间语义模块、共享 Runtime、图元 Factory”分层，以实体银质新月、双层曲线轨迹、冷白月束、水流传输、物理爪痕、精准箭轨和连续坠落的月光流星构成统一的清冷视觉语言。
- **狐妖仙**：尾数、献祭、魅惑、控制、复生、变身与狐火区域法术；表现层以有镜面厚度的绯红妖气、狐眼、魂魄丝带、香雾薄膜、冷色立体狐火和九尾扇形为统一语言，尾数使用数值变化时播放过渡、稳定后停止重绘的独立九槽资源仪表，献祭、九尾复生、勾魄、永久/临时魅惑、2x2 狐火、天狐化、祸国与九尾之尾入场均有独立动态反馈。
- **猴妖仙**：孙悟空神通、瞬移、透视、隐身、护甲、分身协攻、变身和猴族副动作；表现层以带飞白高光的赤金毛笔气流、有内流明暗的玉白筋斗云、赤金扫描光幕、猴毛剪影、铜金护体、蟠桃仙气、定字封印、龙宫神器和法象巨影构成统一的中国神话妖仙语言，并为移动路径、反弹、协攻、装备与持续状态提供独立反馈。
- **野兽人**：同类斩杀进化、混沌腐蚀、兽径地形、兽王杀戮成长、鹰身女妖咆哮增益、萨满野性呼唤和万魔岩仪式；表现层使用骨角生长、干涸血痕、泥土裂隙、蹄印、战吼风压、兽群足迹和混沌脉络构成粗粝而清晰的原始战争语言，杀戮成长、进化、咆哮受益、荒野召唤、腐蚀爆发、兽径挖掘、万魔充能与废灭仪式均有独立动态反馈。
- **东京喰种**：初始为高 RC 浓度；每次击杀敌方非英雄随从立即提升一级，无杀戮回合结束时降低一级，低浓度无杀戮会随机分食友方非英雄喰种。施法回合在该种族中表现为“赫子解放”，四类赫子通过持续至下个己方回合开始的能力快照，提供攻速、移动攻击与攻击/吸血、护甲/反伤或羽针副动作；尾赫在普通与高浓度下均为攻速 +1。金木研拥有尾赫法术和三种可主动恢复原形的覆盖形态；13区咖啡店可以提供治疗咖啡并缩短其复活冷却。芳村功善与高槻泉的枭形态同样可以主动结束。SSS 阶喰种情报可提供芳村功善、高槻泉、旧多二福与死堪，包含赫者化、全体恢复、RC 提升、正面五格攻击、双重免疫以及四赫子同时解放等能力。S 阶与 SSS 阶喰种情报作为两套独立的有限随从库持续提供稀有单位。表现层以冷色雨夜、都市反光、体内 RC 脉冲和有机血肉兵器为统一语言；普通攻击会按四类赫子、复合赫子及覆盖形态自动替换为专属轨迹，RC 升降、低浓度分食、随从库补充、咖啡、全体恢复、赫者化、复原、吸血与反伤也拥有独立动态反馈。
- **影月议会**：古尔丹、灵魂虹吸、邪能灌注、邪能狂乱、混乱兽人、地狱犬、术士、基尔加丹的低语、混乱狼骑兵、末日守卫、地狱火、黑暗之门、魅魔与古尔丹之杖；每回合第一次成功释放邪能法术会让整个阵营进入本回合狂乱，后续邪能施法不会重复叠加，装备可升级施法动作并引发邪能过载，术士诅咒引入可复用的伤害加深状态，地狱火引入火焰伤害持续状态，黑暗之门使用通用周期触发持续提供恶魔兵源。表现层以黑紫空间膜、黏稠酸绿压力核心、灵魂紫流体、暗红诅咒和低矮疯狂压力前沿区分不同邪能语义。
- **共生体**：毒液和生物研究员可通过组织剥离使毒液攻击力永久 +1、受到2点伤害并获得“共生体组织”，每次剥离还会推进玩家级子代池。组织可以附着于共生神盾局探员、生物研究员或基因战士，将宿主永久进化为随机可用子代；基因战士还会把卡牌基础攻击与生命上限永久叠加给新子代。共生体战士放回池中，其余子代不放回。嚎叫死亡会解锁沉默，五种基础子代均死亡会解锁混种，累计五次剥离会解锁毒素、屠杀和眠者。毒液的“撕咬”提供可配置的下一击加伤与固定恢复，“恐怖尖啸”对相邻敌军造成伤害并施加恐惧；恐惧单位在回合开始时尝试背离源头移动，随后整回合无法行动。纳尔·囚禁只为带有共生体生物特征的友方单位提供攻击光环，不影响宿主人类、异噬体或纳尔自身；“法典”会在牌库、隐藏格、战场、手牌或坟场中唯一地找到并解放纳尔。解放形态提高光环数值，并把“共生体组织”的目标扩展为任意非英雄随从。表现层以湿润甲壳、半透明组织膜、肌理脉络和有方向的生物兵器为统一语言；剥离与附着、毒液英雄能力、普通攻击、暴乱、嚎叫、皮鞭、吞噬、子代出壳、子代池解锁、屠杀成长、沉默显现、眠者产猫以及纳尔光环均有独立动态反馈。

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
│   ├── application/            # 对局结果、图鉴目录等跨页面应用数据契约
│   ├── actions/                # 移动、攻击、施法、副动作等行动
│   ├── ai/                     # AI 候选生成、评估和执行
│   ├── audio/                  # 音频管理
│   ├── data/                   # CardData/CardState/PlayerState 等模型
│   ├── effects/                # JSON 驱动的通用效果
│   ├── game/                   # 对局编排、目标、死亡、触发、棋盘 resolver
│   └── ui/                     # 动画门面、主题 provider、面板、手牌、状态覆盖
├── assets/
│   ├── img/                    # 卡面、图标、UI 图片；ui_skin/ 为统一界面皮肤
│   └── music/                  # 背景音乐
├── tools/
│   ├── build_ui_skin_assets.py # 从母版构建 UI 九宫格与交互状态
│   └── validate_cards.py       # 卡牌数据校验
├── main.tscn
└── project.godot
```

## 架构原则

- **数据优先**：卡牌能力优先通过 `data/cards.json` 配置，规则代码提供通用能力。
- **随从分类受控**：英雄、普通随从和衍生形态都通过 `unit_traits` 显式声明可叠加的形态、族裔、构成与来源；分类用于规则过滤和图鉴检索，战斗能力仍由 `keywords` 表达。
- **应用外壳常驻**：`GameShell` 是唯一顶层场景宿主；主菜单、种族选择、功能页和对局只发出导航意图，不互相实例化或释放。
- **图鉴查询与 UI 分离**：`CardCollectionCatalog` 只构建只读目录并执行筛选排序，`CardCollectionScreen` 只维护页面交互；普通牌与衍生牌来源由 `CardDatabase` 的独立索引判定，不通过 `count` 猜测。
- **结算契约统一**：资源胜利和投降都生成 `MatchResult`，由同一结算页面展示；未来牌局历史只消费结果快照，不读取已销毁的 `GameManager`。
- **规则与表现分离**：`scripts/effects/` 和 `scripts/actions/` 修改规则状态；动画、音效和 UI 由表现层 resolver 处理。
- **HUD 生命周期集中编排**：`GameHudCoordinator` 统一组织各对局面板的创建与刷新，panel controller 管内容，`RightSideHudLayoutController` 管位置，`GameManager` 仅保留稳定门面。右侧 HUD 在窄视口保持 296px 紧凑宽度，在宽屏扩展到 340px；所有框体统一由内容自然撑高，不随剩余屏幕高度拉伸。
- **UI 皮肤集中管理**：`GameUiSkin` 只管理位图、九宫格边距、安全内容区和控件状态，并把框体分为 `MAIN`、`DRAWER`、`SIDEBAR`、`INSET`、`SECTION`、`HUD` 六档；`ApplicationUiStyle` 负责主菜单、图鉴、全局操作面板和结束回合等对局主命令，`RightSideHudStyle` 负责战斗 HUD。页面 controller 只选择语义变体，不自行复制外框，也不能把内容放进木框、金属角或内侧斜面覆盖范围。
- **HUD 卡图统一预览**：种族状态牌与装备牌通过 `CardTexturePreviewController` 共享悬浮大图、视口内定位和显示生命周期。
- **自适应手牌抽屉**：法术、随从、升级、装备四区保留独立纵向滚动，横向滚动被禁用；抽屉尺寸始终限制在可见视口内，空区自动收缩，非空区按目标可用宽度换行并按卡牌行数共享净可用高度；窗口实时缩放会保持收起开关可见、重排已有卡牌并保留各区滚动位置。
- **法术特效模块化**：`SpellAnimationRouter` 按目标单位、矩形、来源矩形、全战场、多格路径、范围区域和多目标矩形组七种表现上下文分派 animation key，并拒绝同一上下文的重复处理器；普通施法回合由通用 provider 播放蓝金法阵，各种族 provider 独立维护主题视觉，复杂 provider 再按语义编排、图元工厂和生命周期运行时分层。
- **程序化材质原语**：`VfxCanvasToolkit` 为代码型特效提供柔光体、雾膜、错相光点、分段安全的有机丝带和低成本分层描边；`ThrottledProgressVisual` 统一限制复杂程序化演出的几何重建频率。二者都不接触规则与路由，各种族仍独立定义配色、主体形状和动画节奏。
- **白银之手圣光体系**：白金核心、珍珠银盾面、誓约圣印和垂直圣光构成统一的军事圣光语言；群体信仰治疗同步结算，圣盾格挡有独立破碎反馈，真言术·盾按实际状态层数持续展示。
- **苗疆蛊术体系**：一次性蛊术、单位持续覆盖和单元格陷阱分层管理；毒持续阶段以总伤害数字为主，毒种结算、幼虫成熟、同命传导、薄葬断裂和吞噬继承拥有独立可读反馈。
- **持续区域特效数据驱动**：状态通过 `persistent_visuals` 声明范围与视觉 key，`BoardPersistentVisualController` 负责 renderer 注册、源单位跟随、区域布局和生命周期；卡面局部标识仍由 `CardStatusOverlay` 负责。
- **统一入口**：目标选择走 `SpellTargetResolver`，死亡走 `DeathResolver`，补牌走 `BoardSlotResolver`，棋盘层级走 `BoardLayerResolver`，行动资源走 `ActionResourceResolver`。
- **死亡可追溯**：所有击杀、范围伤害、亡语和直接摧毁都通过 `DeathResolver`，并携带击杀来源，确保矿脉资源分、复生、亡语和补牌稳定结算。
- **原格召唤有序**：复生、亡语原地召唤、击杀来源召唤和公共牌池补位由死亡格占位优先级统一裁决。
- **状态可驱散**：可被净化/驱散的属性变化应实现为状态，不直接永久改数值。
- **衍生牌可查不可入池**：衍生牌定义在种族 `tokens[]`，注册到全局卡牌表，但不进入常规牌池。
- **卡图按需加载**：数据库初始化只解析图片路径，卡面、战场图和卡背在具体 UI 首次使用时加载并缓存，避免启动时解码全部美术资源。
- **文档 UTF-8**：所有文档保持 UTF-8；若出现乱码，先修复编码再继续编辑。

## 快速开始

1. 安装 Godot 4.6+。
2. 克隆仓库。
3. 用 Godot 打开 `project.godot`。
4. 运行项目；入口场景为 `scenes/app/game_shell.tscn`。`main.tscn` 仅是战斗场景，不应作为正常应用入口。

## 验证命令

```powershell
python tools/validate_cards.py
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ImportAssets -TimeoutSeconds 180
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_unit_traits.gd -SuccessMarker UNIT_TRAITS_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_ui_skin.gd -SuccessMarker UI_SKIN_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_application_flow.gd -SuccessMarker APPLICATION_FLOW_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_collection.gd -SuccessMarker CARD_COLLECTION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_data_lazy_textures.gd -SuccessMarker CARD_DATA_LAZY_TEXTURES_TEST_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_tokyo_ghoul.gd -SuccessMarker TOKYO_GHOUL_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_tokyo_ghoul_animation_provider.gd -SuccessMarker TOKYO_GHOUL_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_combat_impact_animation.gd -SuccessMarker COMBAT_IMPACT_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_rc_concentration.gd -SuccessMarker RC_CONCENTRATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_texture_preview.gd -SuccessMarker CARD_TEXTURE_PREVIEW_TEST_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_card_reserve.gd -SuccessMarker CARD_RESERVE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_status_attack_override.gd -SuccessMarker STATUS_ATTACK_OVERRIDE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_direction_ray_selection.gd -SuccessMarker DIRECTION_RAY_SELECTION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_dalaran_council.gd -SuccessMarker DALARAN_COUNCIL_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_board_persistent_visuals.gd -SuccessMarker BOARD_PERSISTENT_VISUAL_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_right_side_hud.gd -SuccessMarker RIGHT_SIDE_HUD_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_animation_routing.gd -SuccessMarker "OK: animation provider routes are registered"
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_silver_hand_animation_provider.gd -SuccessMarker SILVER_HAND_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_dalaran_animation_provider.gd -SuccessMarker DALARAN_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_miao_animation_provider.gd -SuccessMarker MIAO_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_beastmen_animation_provider.gd -SuccessMarker BEASTMEN_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_fox_spirit_animation_provider.gd -SuccessMarker FOX_SPIRIT_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_vfx_canvas_toolkit.gd -SuccessMarker VFX_CANVAS_TOOLKIT_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_vfx_redraw_scheduling.gd -SuccessMarker VFX_REDRAW_SCHEDULING_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_shadowmoon_animation_provider.gd -SuccessMarker SHADOWMOON_ANIMATION_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_symbiote.gd -SuccessMarker SYMBIOTE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_symbiote_offspring_pool.gd -SuccessMarker SYMBIOTE_OFFSPRING_POOL_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_board_view_modes.gd -SuccessMarker BOARD_VIEW_MODE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_night_elf_vfx_modules.gd -SuccessMarker NIGHT_ELF_VFX_MODULE_TESTS_OK
powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1 -ScriptPath res://tools/test_night_elf_animation_provider.gd -SuccessMarker NIGHT_ELF_ANIMATION_TESTS_OK
```

修改 `data/cards.json` 后至少运行卡牌校验；修改随从 `unit_traits`、新增随从或新增分类时还要运行 `tools/test_unit_traits.gd`；新增或重建 `assets/img/ui_skin/` 的 PNG 后先使用 `-ImportAssets` 生成 Godot 导入元数据，再运行 UI 皮肤测试；修改动画路由/provider 后额外运行 `tools/test_animation_routing.gd`；修改共享 Canvas 材质原语或 Ribbon 路径算法后运行 `tools/test_vfx_canvas_toolkit.gd`，修改复杂 VFX 重绘生命周期时同时运行 `tools/test_vfx_redraw_scheduling.gd`；修改普通攻击的正面宽度、巨兽或固定溅射表现时运行 `tools/test_combat_impact_animation.gd`；修改东京喰种自绘特效或赫子状态快照后运行东京喰种规则与动画两项测试；修改野兽人杀戮、进化、仪式、兽径或持续资源表现后运行野兽人动画测试；修改狐妖仙目标、区域、仪式特效、魅惑状态或尾数仪表后运行狐妖仙动画测试与右侧 HUD 测试；修改影月议会邪能顺序、疯狂响应、恶魔仪式或持续状态表现后运行影月专项测试；修改共生体剥离、附着、子代能力、池解锁、成长事件或持续覆盖后运行共生体规则与动画两项测试；修改暗夜精灵语义模块或 VFX Runtime 后运行模块测试和完整 Provider 测试；修改脚本、场景、表现层或玩法流程后运行 Godot 检查。

`tools/build_ui_skin_assets.py` 依赖 Pillow，仅在使用新的美术母版重建皮肤资源时需要运行；日常启动游戏不依赖 Python 图像库。

Windows 下不要直接运行 `godot --headless --path . --check-only`：Godot 4.6 在项目模式下不会可靠退出，而 PowerShell 会提前返回，长期使用会累积隐藏的 `godot.exe` 并耗尽内存。统一使用 `tools/run_godot_validation.ps1`，它会等待真实退出、限制执行时间，并只清理本次启动的进程。

## 文档

- [架构说明](docs/architecture.md)：系统边界、规则设计、长期方向。
- [Codex 工作索引](docs/codex-working-map.md)：常见任务应该先读哪些文件。
- [运行时效果生命周期](docs/runtime-effect-lifecycle.md)：多入口效果、跨回合状态、快照与失效时点的统一约定。

## License

MIT
