# 🏗️ IndoScout V2

> **印尼高端 Design & Build 市场的 AI 获客引擎 —— 为 Nusantara Atelier 主线输送"值得马上打电话"的线索。**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Status: P0 验证期](https://img.shields.io/badge/Status-P0%20验证期-orange.svg)]()

**输入关键词，自动抓取印尼高端装修/整装潜在客户，AI 双维评分排序，一键 WhatsApp 破冰，全链路归因回流。**

---

## 📍 生态定位（先读这个）

IndoScout 是 **Nusantara 三项目生态的幕后获客端**，永不对客户可见：

```text
┌──────────────────────────────┐
│ Nusantara-KG-MCP-Server      │  知识中台（工艺/工时/人工图谱，P0 数据建设期）
│  └── P1/P2 起供能：估价·话术  │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐        线索         ┌──────────────────────┐
│ Nusantara-Atelier ⭐ 主线前台  │ ◀──────────────── │ IndoScout（本项目）   │
│ 已上线 · 25案例/231图/51 SKU  │   落库 Atelier D1   │ B端获客 · 幕后        │
│ nusantara-atelier.pages.dev  │ ────────────────▶  │ 找客户/评分/WA破冰    │
└──────────────────────────────┘   转化数据回流校准    └──────────────────────┘
```

| 项目 | 角色 | 状态 |
| :--- | :--- | :--- |
| [Nusantara-Atelier](https://github.com/vfvincentwong2026/Nusantara-Atelier) | 唯一对客户可见的品牌与转化前台 | ✅ 已上线 |
| [Nusantara-KG-MCP-Server](https://github.com/vfvincentwong2026/Nusantara-KG-MCP-Server) | 知识中台，P2 起为评分与话术供能 | 🚧 P0 数据期 |
| **IndoScout-D-B（本项目）** | B 端获客引擎 | 🟡 P0 验证期 |

---

## 这个系统解决什么问题？

印尼巴厘岛、雅加达等地的别墅/豪宅设计施工市场快速增长，但中资与国际化设计施工团队面临三大痛点：

| 痛点 | 传统方式 | IndoScout 的做法 |
| :--- | :--- | :--- |
| **获客难** | 盲目扫街、等人介绍、跑展会 | Google Places API 多源检索 + 官网深度解析 |
| **客单价低** | 找到的是竞品承包商或小业主 | 分级词库直击买地投资人/豪宅开发商/高净值业主 |
| **线索质量差** | 有电话但不知道真实需求 | LLM 双维评分：识别风格、体量、全案痛点、介入时机 |

---

## 📊 评分模型（Quality × Reach 双分制）

**质量分** —— 值不值得跟：

```
Quality = 风格匹配×30% + 项目体量×25% + 全案痛点×20% + 时机×15% + 核心区域×10%
```

**触达分** —— 好不好跟：直连 WA=100 / 公司总机=60 / 仅表单=30 / 无=0。
**优先级 = Quality × Reach 系数**

| 优先级 | 等级 | 行动 |
| :--- | :--- | :--- |
| ≥80 | 🔴 热线索 | 立即 WhatsApp，Telegram 实时推项目经理 |
| 60-79 | 🟡 温线索 | 人工复核队列，本周内联系 |
| 40-59 | 🟢 普通 | 培育名单 |
| <40 / 竞品同行 | ⚪ | 暂缓 / 直接淘汰（`is_competitor` 开关） |

**防幻觉纪律**（与 KG-MCP 同构）：每个维度打分必须附官网原文证据引文 + 置信度，无引文分数作废；风格标签收敛到 Atelier 8 风格闭枚举。

---

## 🔗 与 Atelier 的协同（对接要点）

- **统一线索库**：线索落 Atelier D1（`leads` + `lead_events` 时间线表），`phone_wa` 全局去重，深度跟进中的线索自动 suppressed 防重复触达；
- **破冰闭环**：WA 话术带 `ref` 归因链接落 Atelier 落地页（`/upload` 预填风格面积 / `/booking` / 首页案例画廊），行为全回写时间线；
- **KG-MCP 可插拔**：体量估算 v1 用规则（Atelier 单方造价带 Rp 10.0-12.5jt/㎡），P2 一行配置切 `quick_estimate`；
- **品牌边界**：客户可见的只有 Nusantara Atelier，IndoScout 永远幕后。

详见 [系统对接 PRD v1.1](docs/IndoScout×Atelier_系统对接PRD_v1.1.md)。

---

## 🚀 当前状态与路线图

| 阶段 | 内容 | 状态 |
| :--- | :--- | :--- |
| **P0** | 技术验证三 spike：S1 线索可得性（官网≥50%、WA 命中≥30%）/ S2 LLM 评分一致率≥70% / S3 单条成本≤$0.15 | 🟡 待 Google Places API Key（[开通指引](docs/Google-Places-API-开通指引.md)，CLI 一键脚本已备） |
| **M1** | 抓取+解析+评分跑通，CSV 输出（巴厘岛 Canggu/Uluwatu/Pererenan + 雅加达富人区） | 📋 待 P0 |
| **M2** | 落库 Atelier D1 + Streamlit 跟单台 + WA 链接 + ref 归因 | 📋 |
| **M3** | 周运营节奏 + 月度校准报告（北极星：合格对话 ≥5 条/周） | 📋 |

**明确不做（MVP）**：Instagram 抓取、飞书/Airtable、Docker、KG-MCP 集成（v2）。

## ⚖️ 合规红线

1. Google 数据只走官方 **Places API (New)**，不爬 Maps 前端；
2. WhatsApp 首条消息含退出选项，STOP → 全系统 opt_out；
3. 遵守印尼 PDP 法（UU No.27/2022）：只采商业公开信息，每条线索记录来源 URL，删除请求 48h 内执行；
4. 爬取礼仪：robots.txt、单域名 ≤5 页、1 req/2s。

---

## 📂 仓库结构

```text
IndoScout-D-B/
├── README.md
├── config/
│   └── search_queries.json          # 分级词库 v1.0（S/A/B 级，15 条印尼语/英语检索词）
├── docs/
│   ├── IndoScout-MVP-PRD.md         # ⭐ MVP 需求文档（评分规格 + P0 验证计划）
│   ├── IndoScout×Atelier_系统对接PRD_v1.1.md   # ⭐ 对接契约（D1 模型/API/状态机/归因）
│   ├── Nusantara生态全景与IndoScout定位修正.md   # 生态定位定案
│   ├── IndoScout-V2_产品评估与修改意见.md        # 早期评估（部分结论已被上面两份更新）
│   └── Google-Places-API-开通指引.md             # API Key 开通（含 CLI 半自动路径）
└── scripts/
    └── gcloud_setup_indoscout.sh    # Places API 一键开通脚本（项目/启用/Key/限制/.env）
```

> `src/`、`web/` 等代码目录将在 P0 验证通过后按 [MVP PRD](docs/IndoScout-MVP-PRD.md) 创建。

---

## 📄 许可证

MIT License — 可自由使用、修改、商用。

**Made for 印尼高端 Design & Build 市场 · 为 Nusantara Atelier 主线服务**
