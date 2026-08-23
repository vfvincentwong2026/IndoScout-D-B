# 🏗️ IndoScout V2

> **面向印尼高端豪宅/别墅"设计+施工一体化（Design & Build）"行业的 AI 获客与智能评分系统。**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Status: v2.0](https://img.shields.io/badge/Status-v2.0-green.svg)]()

**IndoScout V2 是一个面向印尼高端 Design & Build 市场的 AI 获客工具。输入关键词，自动抓取潜在客户，AI 评分排序，一键 WhatsApp 破冰。**

> **当前状态**：MVP 开发中，预计 2026年10月 可用。

---

## 这个系统解决什么问题？

印尼巴厘岛、雅加达等地的别墅/豪宅设计施工市场快速增长，但中资与国际化设计施工团队普遍面临三大痛点：

| 痛点 | 传统方式 | IndoScout V2 的做法 |
| :--- | :--- | :--- |
| **获客难** | 盲目扫街、等人介绍、跑展会 | **自动化多源数据抓取**：Google Maps + 官网深度爬取 |
| **客单价低** | 找到的是竞品承包商或小业主 | **多模态 AI 评分**：直接定位买地投资人、豪宅开发商、高净值业主 |
| **线索质量差** | 有电话但不知道对方真实需求 | **LLM 深度分析**：识别审美风格、项目体量、交钥匙工程痛点 |

**一句话总结：IndoScout V2 帮你在印尼精准找到愿意为"设计与施工一体化"付费的顶级客户，并用 AI 帮你打分排序、一键破冰。**

---

## 🌟 V2 核心升级

| 维度 | V1（传统施工获客） | V2（设计+施工一体化获客） |
| :--- | :--- | :--- |
| **目标客户** | 施工承包商（易搜到竞品同行） | **直接定位 C 端业主、开发商、买地投资客** |
| **介入节点** | 图纸已出的中后期（低价竞争） | **极前期（刚买地/刚准备规划时）** |
| **评分维度** | 只看评论数与商业活跃度 | **多模态 AI 识别审美风格 + 项目体量 + 全案痛点** |
| **交付形态** | 静态 CSV 表格 | **内置 WhatsApp 破冰链接 + 轻量 Web Dashboard** |

---

## 🎯 核心功能

### 1. 场景化多词库检索

预置分级词库，一键切换目标客群：

| 等级 | 目标客群 | 搜索词示例（印尼语） |
| :--- | :--- | :--- |
| **S 级** | 投资人、土地开发商、豪宅开发商 | `investor tanah villa Bali`, `pengembang properti mewah Jakarta` |
| **A 级** | 高端托管公司、商业业主、精品酒店 | `manajemen properti Bali`, `investor hotel butik` |
| **B 级** | 海外建筑师、设计师事务所（可合作/转化） | `arsitek internasional Bali`, `desainer tropis` |

### 2. 多模态 AI 评分引擎

基于 GPT-4o-mini / Claude，分析目标官网/Instagram 的：

- **审美风格**：Modern Tropical、Wabi-Sabi、Minimalist Luxury 等
- **项目体量**：用地面积、房间数、预估预算
- **全案痛点**：是否包含 Design & Build、Turnkey 需求
- **决策人识别**：是否是最终决策者

### 3. WhatsApp 破冰链接生成

自动根据线索特征拼接印尼语/英语专属破冰招呼语，实现**一键调起 WhatsApp 对话**。

### 4. 多管道输出

| 输出方式 | 用途 |
| :--- | :--- |
| CSV / Excel | 销售团队手动跟进 |
| Airtable / 飞书多维表格 | 实时同步，团队协作 |
| Streamlit Web Dashboard | 可视化查看、一键点击联系 |

---

## 📊 评分模型

最终得分由以下权重公式自动计算：

```
Final Score = Style × 30% + Scale × 25% + Pain × 20% + Contact × 15% + Location × 10%
```

| 维度 | 权重 | 说明 |
| :--- | :--- | :--- |
| **风格匹配** | 30% | LLM 解析网页，识别 Modern Tropical、Luxury Villa 等风格标签 |
| **项目体量** | 25% | 识别用地面积（如 >500sqm）或房间数 |
| **全案痛点** | 20% | 识别 Design & Build、Turnkey 等交钥匙需求 |
| **直连触达** | 15% | 是否抓取到决策人个人 WhatsApp / 直连电话 |
| **核心区域** | 10% | 巴厘岛 Canggu/Uluwatu/Pererenan 或雅加达富人区 |

### 分数等级与行动建议

| 分数区间 | 等级 | 行动建议 |
| :--- | :--- | :--- |
| 80-100 | 🔴 **热线索** | 立即 WhatsApp 联系，优先安排 |
| 60-79 | 🟡 **温线索** | 本周内联系 |
| 40-59 | 🟢 **普通** | 列入培育名单，定期跟进 |
| < 40 | ⚪ **冷线索** | 暂缓，有精力再处理 |

---

## 🚀 快速开始

### 前置条件

- Python 3.10+
- Playwright 运行环境
- OpenAI API Key（用于 AI 评分）

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/vfvincentwong2026/IndoScout-D-B.git
cd IndoScout-D-B

# 2. 安装依赖
pip install -r requirements.txt
playwright install chromium --with-deps

# 3. 配置环境变量
cp .env.example .env
# 配置 OPENAI_API_KEY 与代理 IP

# 4. 执行全案模式抓取与评分
python src/main.py --mode design_build --query-level S --max 50

# 5. 启动可视化 Web 界面
streamlit run web/app.py
```

### Docker 一键部署（推荐生产环境）

```bash
docker build -t indoscout:latest .
docker run -d --name indoscout \
  -v $PWD/data:/app/data \
  -p 8501:8501 \
  --env-file .env \
  indoscout:latest
```

---

## 📂 项目结构

```
indoscout/
├── config/
│   ├── settings.yaml              # 全局配置（API Key、代理池）
│   └── search_queries.json        # 分级搜索词库（S/A/B级）
├── src/
│   ├── scrapers/                  # 数据抓取模块
│   │   ├── google_maps.py         # Google Maps（Playwright）
│   │   └── instagram.py           # Instagram 元数据
│   ├── enrichment/                # 数据清洗与富化
│   │   ├── site_parser.py         # 官网深度解析
│   │   └── contact_extractor.py   # WA/邮箱/决策人提取
│   ├── scorer/                    # AI 评分引擎
│   │   ├── llm_evaluator.py       # LLM 审美/客单价评估
│   │   └── rules.py               # 权重与硬规则打分
│   └── exporters/                 # 导出与流转
│       ├── wa_link_builder.py     # WhatsApp 破冰链接
│       └── airtable_sync.py       # Airtable 同步
├── web/
│   └── app.py                     # Streamlit Dashboard
├── docs/
│   ├── TECH_STACK_AND_ARCHITECTURE.md
│   └── IMPLEMENTATION_PLAN.md
├── requirements.txt
├── Dockerfile
└── README.md
```

> 注：部分文件为规划结构，实际开发中会逐步创建。

---

## 📄 许可证

MIT License — 可自由使用、修改、商用。

---

**Made for 印尼高端 Design & Build 市场**
