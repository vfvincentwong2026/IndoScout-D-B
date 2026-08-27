# Nusantara 生态全景与 IndoScout 定位修正

> 版本：v1.1（按 Owner 指示移除 Nusantara-Villa，生态收敛为三项目主线）
> 性质：对《IndoScout-V2_产品评估与修改意见》《系统对接PRD》的修正与升级
> 依据：通读 Nusantara-Atelier（README + schema.sql）与 Nusantara-KG-MCP-Server（README + ARCHITECTURE + DATA_MODEL + 数据录入指引）

---

## 一、生态全景：三项目版图

```text
                ┌─────────────────────────────────────────┐
                │   Nusantara-KG-MCP-Server（知识中台）     │
                │   「高端交付的决策大脑」                  │
                │   工艺/工时/人工/材料 知识图谱            │
                │   状态：P0 数据建设期（23 工艺已录入）     │
                └─────────────────┬───────────────────────┘
                                  │ P1/P2 起供能：估价 / 工艺 / 工期 / 破冰话术
              ┌───────────────────┴───────────────────┐
              ▼                                       ▼
┌──────────────────────────┐          ┌──────────────────────────┐
│   Nusantara-Atelier ⭐主线 │          │   IndoScout-D-B（幕后）    │
│   客户前台 · 已上线 ✅      │ ◀─ 线索 ─│   B端获客引擎              │
│   25案例/231图/51 SKU     │          │   找客户/评分/WA破冰        │
│   三语站+估价+BOM+预约     │          │   状态：README 规划期       │
└──────────────────────────┘          └──────────────────────────┘
```

| 项目 | 角色 | 状态 | 关键资产 |
| :--- | :--- | :--- | :--- |
| **Nusantara-Atelier** | **主线前台**：设计+施工一体化品牌，唯一对客户可见 | ✅ **已上线**（nusantara-atelier.pages.dev，Phase 1/2 完成，Phase 3 进行中；Phase 4 = 与 IndoScout 打通，规划中） | 25 案例 / 231 实景图 / 51 印尼材料 SKU / 自研估价+BOM 引擎 / DXF 解析 / 三语 / D1 + Workers API（8 路由） |
| **Nusantara-KG-MCP-Server** | **知识中台**：高端交付 know-how 结构化 | 🚧 P0 数据建设期（服务代码未开工） | 23 个工艺节点（待 Owner 校对 ⚠️ 数字）/ 4 套 AI 生成模板 / 完整数据契约（DATA_MODEL v2） |
| **IndoScout-D-B** | B 端获客引擎，**为主线供线索** | 📋 仅 README | 规划中的词库/评分/WA 破冰 |

**核心认知：IndoScout 的存在意义 = 给 Atelier 这台已上线运转的转化机器输送优质线索；KG-MCP 是让线索转化和交付报价更聪明的共享大脑。**

---

## 二、KG-MCP 深入学习要点（直接影响 IndoScout 设计）

### 2.1 它的数据纪律值得 IndoScout 全盘继承

- **status 三态**：`draft`（AI 初稿）→ `published`（已入库）→ `verified`（Owner 校对过全部 ⚠️ 数字）；
- **⚠️ 纪律**："数字不信 AI"——AI 生成的描述可用，工时/日薪/价格必须真实经验校对，**这是知识库的护城河**；
- 关系词表已定型（`recommends_labor`、`has_workhour`、`mandatory_material`、`alternative_of` 等 14 种边），悬空链接允许、后续补齐。

→ IndoScout 的 LLM 评分应复刻同一纪律：**分数附证据 + 置信度 + 人工复核队列 = 我们的 `verified` 态**。两个项目"AI 产出、人校数字"的方法论完全同构。

### 2.2 数据现状与时间线约束

| 数据层 | 现状 | 对 IndoScout 的意义 |
| :--- | :--- | :--- |
| 工艺 23 篇 | ✅ 已录入，待 ⚠️ 校对 | 破冰话术的工艺弹药**已有原料**，但数字校对前不可直接引用报价 |
| 人工档案 ×3（印尼普工/技工/中国技工） | 📋 下一批 | 话术差异化卖点（"中国技工做微水泥"）依赖此批 |
| 工时定额 | 📋 第 3 批 | 工期类话术依赖 |
| 材料节点 | 📋 第 4 批，与 Atelier 51 SKU 映射 | 估价对齐依赖 |
| `quick_estimate` / `precise_estimate` | P1 才落地（库/内部 API 形态） | IndoScout 评分"项目体量"维度的准确数据源 |
| 独立 Worker 服务 | P2 | IndoScout 正式调用点 |

### 2.3 关键设计结论：IndoScout 不能被 KG-MCP 阻塞

KG-MCP 的 P1（估价能力）要等 P0 数据校对完，节奏不可控。因此：

- IndoScout MVP 的"体量/预算预估"先用**规则估算**（面积 × Atelier 公开单方造价带——`cases.json` 里有真实 `hard_cost_per_sqm` 数据，今天就能用）；
- KG-MCP 集成点设计成**可插拔接口**：`estimator = rule_based | kg_quick_estimate`，P2 服务就绪后一行配置切换；
- 破冰话术同理：v1 用人工模板 + LLM 填空，KG 就绪后升级为工艺级个性化。

---

## 三、对已有文档的修正清单（Villa 移除后的定稿）

### 修正 1：统一线索库 = **Atelier 的 D1**（定案）

- Atelier 的 D1（`nusantara-db`）已在跑，已有 `bookings`（预约线索）、`quotes`（报价，**已预留 `lead_id` 字段**）；
- 做法：在 `schema.sql` 上扩展 `leads` 表 + `lead_events` 时间线表（沿用对接 PRD 3.1/3.2 的模型），在现有 api-worker 上扩展写入/事件接口；
- 对接成本比预期低：原作者本就设计好了线索-报价贯通的钩子。

### 修正 2：破冰落地页 —— 全部落 Atelier（定案）

| 线索类型 | 落地页 | 预填参数 |
| :--- | :--- | :--- |
| 默认 | Atelier 首页（25 案例画廊 + 透明造价带，冷启动可信度最高） | `ref` |
| 有明确风格/面积信号 | `/upload` 即时估价 或 `/booking` 预约设计师 | `style` / `area` / `ref` |

- WA 话术首条只带一个链接；参数命名用 `ref`，不出现内部系统字样（品牌边界）。

### 修正 3：风格枚举单一事实源 = **Atelier cases.json 的 8 风格**（定案）

- 不是 IndoScout README 的 3 种西式风格；Atelier 的 25 案例、估价引擎、AI 设计建议、KG-MCP 的 Style 节点全部基于这套 8 风格；
- IndoScout 的 LLM 评分 prompt 输出必须收敛到同一枚举。

### 修正 4：KG-MCP 是评分与话术的上游大脑，但**可插拔接入**

- 评分"项目体量"维度：v1 规则估算（用 Atelier 单方造价）→ P2 切 `quick_estimate`；
- 破冰话术：v1 模板化 → KG 人工/工艺数据 verified 后引用工艺级卖点（"微水泥四遍批刮，中国技工 4 天"这种话竞品说不出）；
- 排期对齐：KG-MCP 的第 2/3 批数据（人工+工时）应视为 IndoScout 话术 v2 的前置依赖，建议 Owner 校对优先做这两批。

### 修正 5：Telegram 推送建在 **Atelier api-worker** 上（定案）

- 排查确认 Atelier 无推送（booking 仅 WA 拉起 + 落库）；在 api-worker 新增推送路由，热线索（quality≥80）与预约线索同通道推项目经理手机。

### 修正 6：校准不必等 IndoScout 上线（最大的免费午餐）

- Atelier 现有的 `quotes`/`bookings` 数据（什么风格/面积档被询价最多、哪些转化为预约）**今天就能分析**，反推 IndoScout 词库优先级——先抓市场上 already 在询价的客群画像。

---

## 四、修正后的路线图（三项目协同）

| 阶段 | 内容 | 依赖 |
| :--- | :--- | :--- |
| **Now** | Atelier Phase 3 收尾；KG-MCP：Owner 校对 23 篇工艺 ⚠️ 数字（按施工顺序：防水→找平→贴砖→吊顶） | — |
| **P1'** | ① 分析 Atelier quotes/bookings 存量数据 → 定 IndoScout 词库优先级；② KG-MCP 第 2 批 3 份人工档案；③ IndoScout 技术验证（Places API → 官网解析 → LLM 评分，8 风格枚举，规则估算体量） | ① 现在就能做 |
| **P2'** | IndoScout MVP：leads 表落 Atelier D1、Telegram 推送、WA 破冰带 `ref` 链接落 Atelier、Streamlit 跟单台 | P1' ③ |
| **P3'** | KG-MCP 第 3/4 批数据 + P1 估价能力 → IndoScout 切换 `kg_quick_estimate`、话术 v2 工艺个性化 | KG-MCP P0 校对完成 |
| **P4'** | 转化回流校准月报（quotes/bookings → 评分权重回归）；KG-MCP P2 独立 Worker 正式化 | P2' 积累 2-3 个月数据 |

---

## 五、不变的原则（继承原评估，仍成立）

1. IndoScout 永远幕后，对客户可见品牌只有 **Nusantara Atelier**；
2. 质量分 × 触达分双分制 + Timing（时机）维度；
3. 合规红线：Places API 替代 Maps 抓取、WA Business API、PDP 退订机制；
4. "AI 产出、人校数字"——与 KG-MCP 同一纪律，评分附证据 + 置信度 + 人工复核；
5. `ref` 归因参数贯通：破冰 → 落地页 → 估价/预约 → 时间线全链路可回放。

---

*下一步：将本修正合并进《系统对接PRD》出 v1.1 修订版（宿主改 Atelier D1、落地页全落 Atelier、KG-MCP 可插拔依赖、8 风格枚举对齐）。*
