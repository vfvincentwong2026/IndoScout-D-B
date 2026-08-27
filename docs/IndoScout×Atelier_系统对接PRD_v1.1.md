# IndoScout × Nusantara-Atelier 系统对接 PRD

> 版本：**v1.1**（替代 v1.0《IndoScout×Nusantara-Villa 系统对接PRD》，后者作废）
> 变更摘要：① 宿主由 Villa D1 改为 **Atelier D1（nusantara-db）**；② 移除 Villa 全部分流逻辑，线索统一落 Atelier；③ 新增 **KG-MCP 可插拔集成契约**；④ 风格枚举对齐 Atelier cases.json 实际 8 风格；⑤ Telegram 推送建在 Atelier api-worker
> 范围：仅对接层——统一线索模型、API 契约、状态机、归因链路、数据回流

---

## 1. 背景与目标

Atelier（已上线的主线前台）有转化机器但缺主动获客；IndoScout（规划中的 B 端获客引擎）能找到线索但没有归宿。本 PRD 定义两者对接，使：

| 目标 | 衡量指标 |
| :--- | :--- |
| 一个漏斗：B 端线索从评分到成交全链路可追踪 | 任一 lead 可回放完整时间线 |
| 无缝体验：WA 破冰 → Atelier 落地页一步到位 | 破冰消息 → 落地页访问点击率 ≥ 25% |
| 零冲突：同一客户不被重复触达 | `phone_wa` 去重拦截率 100% |
| 双向校准：Atelier 转化数据回流优化评分 | 第 6 个月产出评分-成交相关性报告 |

**非目标**：不改 Atelier 估价/BOM/DXF 内部逻辑；不做完整 CRM；不做多租户。

---

## 2. 系统角色与边界

```text
┌─────────────────┐   写入线索    ┌────────────────────────────────┐
│   IndoScout     │ ────────────▶ │  Atelier D1 (nusantara-db)     │
│  (B端, 幕后工具) │               │  唯一事实源                     │
│  找客户/评分     │ ◀──────────── │  + api-worker 扩展路由          │
└─────────────────┘   回流校准     └────────────────────────────────┘
        ▲ 可插拔供能                    ▲   │              │
        │                               │   │ 实时推送      │ 落地页+行为回写
┌───────┴──────────┐          ┌─────────┘   ▼              ▼
│ KG-MCP-Server     │          │        ┌──────────┐   ┌─────────────┐
│ (知识中台, P1/P2起)│          │        │ Telegram │   │ Atelier 前端 │
│ quick_estimate 等 │          │        │ → PM手机  │   │ /upload等   │
└──────────────────┘          │        └──────────┘   └─────────────┘
                              │ 现有：/health /cases /quote /booking /design /parse-dxf /materials
```

- **Atelier**：唯一对客户可见品牌；D1 为唯一事实源；api-worker 承载全部对接路由与 Telegram 推送。
- **IndoScout**：纯内部工具，对客户不可见；作为 api-worker 的写入方；本地仅存抓取原始快照，lead 状态以 D1 为准。
- **KG-MCP**：P1/P2 起通过**可插拔接口**为 IndoScout 提供估价与工艺话术供能（见第 7 节）；IndoScout MVP 不依赖它。

---

## 3. 数据模型（Atelier D1 扩展）

在 `schema.sql` 追加两张表（现有 cases/materials/quotes/bookings 不动）。

### 3.1 `leads` 表

| 字段 | 类型 | 说明 |
| :--- | :--- | :--- |
| `lead_id` | TEXT PK | UUID v4 |
| `phone_wa` | TEXT UNIQUE | E.164（`+62...`），**去重主键** |
| `source` | TEXT | `indoscout` \| `atelier_web` |
| `name` / `company` | TEXT | |
| `role` | TEXT | `decision_maker` \| `agent` \| `staff` \| `unknown` |
| `grade` | TEXT | IndoScout 客群等级 `S`/`A`/`B`；站内线索为空 |
| `quality_score` | INTEGER | 0-100（风格30+体量25+痛点20+时机15+区位10） |
| `reach_score` | INTEGER | 0-100（直连WA=100/总机=60/仅表单=30/无=0） |
| `style_tags` | TEXT(JSON) | **闭枚举，对齐 cases.json**：`现代`/`法式`/`法式轻奢`/`现代小法`/`现代奶油`/`侘寂`/`意式极简`/`tropical_resort`（印尼市场新增第 8 风格，需先回写案例库再启用） |
| `estimated_area_sqm` | INTEGER | |
| `estimated_budget_idr` | INTEGER | 规则估算（见 7.1）或 KG 供能 |
| `timing_signals` | TEXT(JSON) | `land_purchase`/`pbg_permit`/`pt_newly_registered`/`hiring_architect` 等 |
| `status` | TEXT | 状态机，见第 5 节 |
| `assignee` / `next_follow_at` | TEXT | |
| `pdp_consent_at` | TEXT | PDP 合规：获触达同意时间 |
| `created_at` / `updated_at` | TEXT | |

索引：`(status)`、`(quality_score DESC)`、`(next_follow_at)`。

### 3.2 `lead_events` 表（时间线，只增不改）

`event_id` / `lead_id` FK / `event_type` / `actor` / `payload`(JSON) / `created_at`。

`event_type`：`scraped, scored, outreach_sent, outreach_replied, site_visited, quote_requested, booking_submitted, meeting_booked, proposal_sent, won, lost, nurture, suppressed, note`

**规则：任何写状态的接口必须同事务写事件。**

### 3.3 与现有表的关联

- `quotes.lead_id`（已预留）→ `leads.lead_id`：站内估价记录挂到线索；
- `bookings.whatsapp` ↔ `leads.phone_wa`：预约提交时按号码归并（见 4.1 规则）；
- `opt_out(phone_wa TEXT PK, created_at)`：PDP 退订黑名单，全系统生效。

---

## 4. API 契约（Atelier api-worker 扩展）

沿用现有 Worker 风格；新增 IndoScout 调用需 `X-Ingest-Key` 头（现有 8 路由 MVP 免鉴权不变，但**新增写路由必须带鉴权**，避免线索库被公网写入）。

### 4.1 `POST /api/leads` —— 线索写入（Upsert）

```json
{
  "source": "indoscout",
  "phone_wa": "+6281234567890",
  "name": "Made Wirawan", "company": "Wirawan Land Group",
  "role": "decision_maker", "grade": "S",
  "quality_score": 87, "reach_score": 100,
  "style_tags": ["现代"],
  "estimated_area_sqm": 600, "estimated_budget_idr": 6600000000,
  "timing_signals": ["land_purchase"],
  "evidence": { "style": "官网原话摘录...", "confidence": 0.82 },
  "outreach_draft": "Selamat pagi Bapak Made, ..."
}
```

响应：`{ "lead_id", "action": "created|merged|suppressed", "status" }`

**服务端规则：**

1. `phone_wa` 已存在 → **merge**：保留原 lead_id，补缺字段，`quality_score` 取高者，写 `scraped` 事件；不覆盖 `status`/`assignee`；
2. 已存在且 `status` ∈ {`meeting`,`proposal`,`won`} → **suppressed**：不写业务字段，仅写事件，告知 IndoScout 停止触达；
3. `phone_wa` 命中 `opt_out` → `suppressed` + 不写事件外的任何数据；
4. 新建且 `quality_score ≥ 80` → 触发 Telegram 推送（4.4）；
5. 站内 `/booking` 提交：先查 `leads` 按 `phone_wa` 归并（写 `booking_submitted` 事件），无则照常只写 `bookings` 表——**不强制建 lead**，站内线索进入 leads 由 `booking_submitted` 归并触发。

### 4.2 `GET /api/leads` —— 查询（IndoScout Streamlit 只读视图）

参数：`status`/`min_quality`/`source`/`assignee`/`since`/分页。返回 leads + 各自最近一条事件摘要。

### 4.3 `GET /api/leads/{lead_id}/timeline` —— 时间线

### 4.4 `POST /api/leads/{lead_id}/events` —— 事件写入

```json
{ "event_type": "outreach_replied", "actor": "user:andri", "payload": {"note": "约下周视频"} }
```

非法状态跃迁返回 `409`。状态联动见第 5 节。

### 4.5 `GET /api/feedback/conversion` —— 回流统计（每月校准用）

参数 `period=2026-09`；按 `style_tags/grade/quality 分桶/timing_signals` 分组返回漏斗：

```json
{ "period": "2026-09",
  "cohorts": [{ "key": {"grade":"S","quality_bucket":"80-100"},
    "leads": 42, "replied": 11, "site_visited": 9, "booking": 5, "meeting": 4, "won": 1 }] }
```

### 4.6 约定

- 错误格式 `{ "error": {"code","message"} }`；`X-Ingest-Key` 错误 → 401；频控 60 req/min → 429；
- 自由文本字段 ≤2000 字符，服务端截断。

---

## 5. 线索状态机

```
 new → contacted → replied → meeting → proposal → won
            │         │                   │
            │         └──→ nurture ───────┘   lost ──→ nurture（6个月后）
            └──────────→ suppressed（深度跟进/退订，禁止触达）
```

| 状态 | 允许跃迁（触发事件） |
| :--- | :--- |
| `new` | →contacted(outreach_sent)、→suppressed(merge/opt_out) |
| `contacted` | →replied(outreach_replied)、→nurture(14天未回，系统任务) |
| `replied` | →meeting(meeting_booked)、→nurture |
| `meeting` | →proposal(proposal_sent)、→lost |
| `proposal` | →won / →lost |
| `nurture` | →contacted |
| `suppressed` | 仅系统规则进出 |

自动联动：`quote_requested`/`booking_submitted`（站内主动深度行为）→ `new/contacted` 自动升 `replied`。每次跃迁写事件，`payload.from/to` 记录前后态。

---

## 6. 归因链路：破冰 → Atelier 落地页 → 回流

### 6.1 破冰链接（IndoScout `wa_link_builder` 生成）

```
https://wa.me/{phone}?text={encodeURIComponent(话术 + "\n\n" + 链接)}
```

落地页按信号选择（全落 Atelier）：

| 线索信号 | 落地页 | URL |
| :--- | :--- | :--- |
| 有风格/面积信号 | 即时估价 | `https://nusantara-atelier.pages.dev/upload?style={style}&area={area}&ref={lead_id}` |
| 决策人明确、热线索 | 预约设计师 | `.../booking?style={style}&ref={lead_id}` |
| 默认 | 首页案例画廊 | `.../?ref={lead_id}` |

约束：首条消息只带一个链接；参数名只用 `ref`，不出现 `indoscout`/`lead`/`track`（品牌边界）。

### 6.2 Atelier 前端回写

1. `/upload`、`/booking`、首页读取 URL `ref`/`style`/`area` → `/upload` 预填风格与面积，`ref` 存入 sessionStorage 贯穿会话；
2. 行为埋点（调 4.4）：落地 `site_visited`、提交估价 `quote_requested`、提交预约 `booking_submitted`，均带 `ref=lead_id`；
3. `/quote`、`/booking` 现有路由接受可选 `ref` 字段 → 写 `quotes.lead_id` / 触发 4.1 规则 5 归并。

### 6.3 Telegram 推送（api-worker 新增）

| 触发 | 级别 | 内容 |
| :--- | :--- | :--- |
| `quality_score ≥ 80` 新建线索 | 🔴 | 公司/评分/风格/建议话术/WA 一键链接 |
| 站内 `booking_submitted` | 🔵 | 现有预约信息（含归并的 lead 评分，若有） |
| `quote_requested` 且 lead 为 S 级 | 🟠 | 客户正在自助估价，附时间线 |

推送为内部工具，可含内部字段；Token/Chat ID 走环境变量。

---

## 7. KG-MCP 可插拔集成契约

### 7.1 估价供能接口（IndoScout 侧抽象）

```python
# IndoScout enrichment/estimator.py 的抽象
def estimate_budget(style: str, area_sqm: int, location: str) -> EstimateResult:
    # v1: rule_based —— 用 Atelier 单方造价带
    #   硬装 Rp 10.0jt~12.5jt/㎡（cases.json 4500~5500 RMB/㎡ 折算，⚠️ 中国人工基准，待 KG 印尼人工数据校正）
    # v2: kg_quick_estimate —— HTTP 调 KG-MCP P1/P2 的 quick_estimate
```

- 切换方式：`settings.yaml` 的 `estimator: rule_based | kg_quick_estimate`；
- KG 未就绪不阻塞 MVP；KG 返回的 `confidence` 透传进 `evidence`。

### 7.2 话术供能（v2）

KG 的 `05_Processes`（工艺）+ `06_Labor`（人工）节点 verified 后，IndoScout 话术模板可引用工艺级卖点（如"微水泥四遍批刮、中国技工 4 天交付"）。**纪律与 KG 一致：⚠️ 未校对的数字禁止进话术。**

### 7.3 排期依赖

KG-MCP 第 2 批（3 份人工档案）→ IndoScout 话术 v2；KG P1 估价 → IndoScout 估算 v2。建议 Owner 校对优先级：人工档案 > 工时定额 > 材料。

---

## 8. 校准回流机制

1. 每月 1 日 IndoScout 侧脚本调 4.5 拉 cohort 统计 → 《月度线索质量报告》：各维度分数与回复率/成交率相关性 + 权重建议值 + 词库末位 20% 淘汰候选；
2. 权重改动走人工评审改 `settings.yaml`，不自动改（防小样本震荡）；单月 won < 10 只做定性复盘；
3. **冷启动加速**：MVP 上线前先分析 Atelier 存量 `quotes`/`bookings`（风格/面积档/地区分布），反推词库优先级。

---

## 9. 合规与安全

- **品牌边界**：客户可见的一切只有 Nusantara Atelier；`ref` 参数、D1、Telegram 推送为内部资产；
- **PDP（UU No.27/2022）**：只采商业公开联系信息；`scraped` 事件 `payload.source_url` 记录来源；WA 首条含退出选项，STOP → `opt_out` 全系统生效；删除请求 48h 内清除（保留匿名统计）；
- **密钥**：`X-Ingest-Key`、Telegram Token 环境变量化；D1 不公网直读直写。

---

## 10. 埋点清单

| 事件 | 产生方 | 方式 |
| :--- | :--- | :--- |
| `scraped`/`scored` | IndoScout | 随 4.1 |
| `outreach_sent` | IndoScout（销售点 WA 链接回传） | 4.4 |
| `outreach_replied`/`meeting_booked`/`proposal_sent`/`won`/`lost`/`note` | 销售人工（Streamlit） | 4.4 |
| `site_visited`/`quote_requested`/`booking_submitted` | Atelier 前端/Worker | 4.4 + 现有路由扩展 |
| `suppressed`/自动 `nurture` | 系统任务 | 服务端内部 |

---

## 11. 验收标准（DoD）

1. IndoScout 写入 50 条线索 → Atelier D1 可见，`quality ≥ 80` 触发 Telegram；
2. 同一 phone 两端写入 → merge，时间线含两条 `scraped`；
3. `status=proposal` 线索被 IndoScout 重复写入 → `suppressed`，零外发；
4. WA 链接点开 → `/upload` 风格/面积已预填 → 提交估价 → 时间线出现 `site_visited`+`quote_requested` 且 `quotes.lead_id` 已挂；
5. 任一线索可在 Streamlit 回放完整时间线；
6. STOP 退订端到端生效（opt_out 表 + 后续写入被 suppressed）；
7. 月末校准脚本产出 cohort JSON + 报告骨架；
8. 非法跃迁 409；未带 `X-Ingest-Key` 写新路由 401。

---

## 12. 开放问题

1. `opt_out` 是否需跨未来更多项目共享？（建议：是，独立小表）
2. Atelier 首页匿名访客行为是否落库？（建议：只落带 `ref` 的会话，纯匿名不追踪——合规省心）
3. 销售人工事件入口：Streamlit 按钮（MVP 建议）vs 后续 Telegram 内联按钮？
4. KG-MCP `quick_estimate` 的鉴权方式与 SLA（待其 P2 设计时对齐）。

---

*v1.1 定稿。开发拆分：Atelier 侧（D1 两张表 + 4 个新路由 + 前端 ref 预填/埋点 + Telegram）/ IndoScout 侧（sync 模块 + wa_link_builder + 校准脚本 + Streamlit 跟单台）。*
