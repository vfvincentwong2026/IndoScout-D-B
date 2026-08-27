# IndoScout V2 · MVP 产品需求文档（PRD）

> 版本：v1.0
> 作者：IndoScout 产品经理
> 上游文档：《Nusantara生态全景与IndoScout定位修正 v1.1》《IndoScout×Atelier_系统对接PRD v1.1》
> 一句话：**为 Nusantara Atelier 这台已上线的转化机器，自动找到并排序"值得马上打电话"的印尼高端装修/整装线索。**

---

## 1. 背景与定位

- Atelier 已上线（25 案例/估价/BOM/预约），被动承接能力就绪，缺**主动获客**；
- IndoScout = 幕后获客引擎：多源抓取 → AI 评分 → 落库 Atelier D1 → WA 破冰带 `ref` 归因链接 → 全链路回流校准；
- 永不对客户可见；方法论与 KG-MCP 同构（AI 产出、人校数字）。

## 2. 用户与场景

| 用户 | 场景 |
| :--- | :--- |
| **销售负责人/SDR**（主要） | 每周一打开 Streamlit：本周新增 N 条线索，按优先级排序，点 WA 链接逐条触达，在跟单台更新状态 |
| **Owner/项目经理** | Telegram 收热线索推送；月末看《线索质量报告》 |
| **PM（本角色）** | 看漏斗指标，每月评审词库与评分权重 |

**使用频率**：周批处理为主（每周跑 1-2 次抓取评分），非常驻服务 → 架构为"脚本 + Streamlit"，不是 always-on 服务。

## 3. 指标体系

- **北极星**：每周合格对话数（`outreach_replied` 数 / 周）
- 漏斗：`scraped → 有官网 → scored ≥60 → outreach_sent → replied → meeting → won`
- 健康度：决策人联系方式命中率、LLM 评分人工一致率、垃圾线索率（竞品同行误判）

## 4. MVP 范围

### 4.1 In Scope（P1）

1. 分级词库检索（S/A/B 三级，Google Places API）
2. 官网解析与联系方式提取（WA/邮箱/决策人）
3. LLM 评分引擎（Quality × Reach 双分制 + Timing 维度 + 证据引文）
4. 规则估算器（体量/预算，基于 Atelier 单方造价带）
5. WA 破冰链接生成（含 `ref` 归因 + Atelier 落地页路由）
6. 落库 Atelier D1（调对接 PRD 4.1）
7. Streamlit 跟单台（列表/时间线/人工事件/复核队列）
8. 月度校准脚本骨架

### 4.2 Out of Scope（明确不做）

- ❌ Instagram 抓取（风控/合规，V3 再评估）
- ❌ 飞书/Airtable 同步（只落 Atelier D1 + CSV 导出按钮）
- ❌ Docker 化（本地跑）
- ❌ KG-MCP 集成（v2，接口预留）
- ❌ 雅加达以外的区域扩张（MVP 只做巴厘岛三区 + 雅加达富人区，见 5.1）

## 5. 功能需求

### 5.1 词库与检索

- 词库文件 `config/search_queries.json`（本 PRD 附 v1.0 初始版），三级客群：

| 级 | 客群 | 依据 |
| :--- | :--- | :--- |
| S | 买地投资人、土地/豪宅开发商、高净值业主 | Atelier 案例面积中位数 500㎡、最大 1200㎡ → 只追大体量 |
| A | 高端托管公司、精品酒店/民宿业主、商业业主 | 存量房改造 = 装修整装直接需求 |
| B | 国际建筑师/设计事务所 | 可合作转介，不直接成交 |

- 地理范围 v1：`Canggu / Uluwatu / Pererenan（巴厘岛）+ Menteng / Pondok Indah / PIK（雅加达）`
- 用 **Google Places API**（Text Search + Place Details），不爬 Maps 前端（ToS 红线）。

### 5.2 官网解析与联系方式提取（enrichment）

- 输入：Place Details 的 website URL；
- 提取：WA 号码（`wa.me` 链接、页脚电话）、邮箱、关于页/团队页决策人姓名与头衔、项目作品集页（体量信号）；
- 爬取礼仪：单域名 ≤5 页、robots.txt 遵守、1 req/2s；
- **只采集商业公开信息**，每条记录 `source_url`（PDP 合规）。

### 5.3 评分引擎（核心规格）

**Quality 质量分（值不值得跟）：**

| 维度 | 权重 | 信号源 |
| :--- | :--- | :--- |
| 风格匹配 | 30 | LLM 解析官网/作品集 → 收敛到 Atelier 8 风格枚举（现代/法式/法式轻奢/现代小法/现代奶油/侘寂/意式极简/tropical_resort） |
| 项目体量 | 25 | 面积/房间数 → 规则估算器折 IDR 预算（硬装 Rp 10.0jt~12.5jt/㎡ 锚定，⚠️ 中国人工基准待 KG 校正）；>500㎡ 满分 |
| 全案痛点 | 20 | "design and build"/"turnkey"/"renovation" 等词频 + LLM 判断 |
| 时机 Timing | 15 | 土地交易/PBG 许可/新注册 PT/招聘建筑师等信号（MVP 先靠 LLM 从新闻/官网公告识别，信号源逐个接入） |
| 核心区域 | 10 | 命中 5.1 区域名单 |

**Reach 触达分（好不好跟）：** 直连 WA=100 / 公司总机=60 / 仅表单=30 / 无=0。

**优先级 = Quality × Reach 系数**；四档：≥80 🔴 立即联系 / 60-79 🟡 本周 / 40-59 🟢 培育 / <40 ⚪ 暂缓。

**LLM 输出契约（防幻觉，强制 JSON Schema）：**

```json
{
  "style_tags": ["现代"],
  "scale": {"score": 0, "evidence": "原话摘录", "area_sqm": null},
  "pain": {"score": 0, "evidence": "..."},
  "timing": {"score": 0, "evidence": "...", "signals": []},
  "confidence": 0.0,
  "is_competitor": false,
  "competitor_reason": "..."
}
```

- 每个维度必须附 `evidence` 引文，无引文分数作废置 0；
- `is_competitor=true`（同行承包商/竞对）直接淘汰——V1 的教训；
- `confidence < 0.6` 或总分落在 60-79 → **人工复核队列**（Streamlit 专页，对齐 KG-MCP `verified` 纪律）。

### 5.4 WA 破冰链接

- 模板：印尼语默认，英语备选；首条消息 ≤ 3 句 + 1 个链接；含 STOP 退出语；
- 链接路由按对接 PRD 6.1（默认首页，有风格面积信号落 `/upload`）；
- 发送走 **WhatsApp Business API 模板消息**（v1 可先用 wa.me 手动点击过渡，但日发送 ≤20 条防封）。

### 5.5 Streamlit 跟单台

四页：① 线索列表（分数/状态/筛选/CSV 导出）② 线索详情 + 时间线回放 ③ 人工复核队列 ④ 漏斗看板（本周新增/回复率/热力图）。人工事件按钮：`已发送/已回复/已约见/已出方案/成交/战败/备注` → 调对接 PRD 4.4。

## 6. 合规要求（验收红线）

1. Places API 官方接口；官网爬取遵守 robots.txt；
2. WA：首条含退出选项；STOP → opt_out 全系统生效；
3. 每条线索记录来源 URL 与采集时间；
4. `.env` 不进 git；LLM API Key、X-Ingest-Key 环境变量化。

## 7. P0 技术验证计划（先于 MVP 开发，2 周）

| Spike | 方法 | 通过标准 |
| :--- | :--- | :--- |
| S1 线索可得性 | Places API 按 S 级词库在巴厘岛抓 100 条，统计有官网比例、WA 直连命中率 | 有官网 ≥50%；**决策人/直连 WA 命中率 ≥30%** |
| S2 LLM 评分可信度 | 20 条样本人工盲评 vs GPT-4o-mini 评分 | **维度一致率 ≥70%**；is_competitor 误判率 ≤10% |
| S3 成本测算 | 单条线索全链路成本（API + LLM token） | ≤ $0.15/条有效线索 |

**S1 不达标 → 产品立论动摇，回评审会讨论转向（如改为行业协会/展会名录源）；S2 不达标 → 换模型或加 few-shot 重验。**

## 8. 里程碑

| 里程碑 | 内容 | 验收 |
| :--- | :--- | :--- |
| M0（2 周） | P0 三个 spike | 上表通过标准 |
| M1（4 周） | 抓取+解析+评分跑通，CSV 输出 | 单批 50 条，垃圾率 ≤30% |
| M2（3 周） | D1 落库 + Streamlit + WA 链接 + ref 归因 | 对接 PRD §11 DoD 全过 |
| M3（持续） | 周运营节奏 + 月度校准报告 | 北极星 ≥5 条/周 |

## 9. 开放问题

1. Timing 信号源逐个接入的优先级（PBG 许可公示可得性待查）；
2. WA Business API 申请主体与模板审核周期（建议 M0 期间并行启动申请）；
3. tropical_resort 是否正式成为第 8 风格（需 Atelier 案例库先补对应案例，否则评分映射落空）；
4. 雅加达是否挤进 MVP（建议：词库先配好，跑量看 S1 结果再定）。

---

*附：`config/search_queries.json` v1.0 初始词库已随本 PRD 一同产出。*
