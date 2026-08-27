# IndoScout V2 产品评估与修改意见

> 评审人：高级产品经理视角
> 评审对象：IndoScout-D-B（B 端获客引擎）README v2.0
> 关联项目：Nusantara-Villa（C 端转化平台）
> 核心议题：**B 端获客与 C 端转化如何形成同一个增长闭环**

---

## 一、总体判断

**定位成立，组合拳思路清晰，但当前设计是"两个产品"，还不是"一个系统"。**

- IndoScout 负责"找到对的人"，Nusantara-Villa 负责"把对的人转化"，方向互补、客群一致（印尼高端别墅 Design & Build）。
- 但 README 中两者仅以"姐妹项目"一句话关联，**数据不互通、流程不衔接、品牌边界没划清**。按现状各自开发，上线后会出现：线索重复触达、转化数据无法回流、破冰话术与落地页体验割裂。
- 结论：**值得做，但必须先补"协同层"设计，再动工写代码。**

---

## 二、分维度评估

### 2.1 战略与定位 ✅ 通过

- "极前期介入（刚买地/刚规划）"是本产品最有价值的洞察，避开了图纸已出后的低价红海。
- 分级词库（S/A/B 级）体现了对客群的真实理解，不是泛泛的"抓数据"。
- ⚠️ 但注意：**"刚买地"这个核心卖点在评分公式里完全没有体现**（见 2.4），定位与产品设计脱节。

### 2.2 目标用户与场景 ⚠️ 需澄清

README 没有回答三个基础问题，建议补进 PRD：

1. **谁来用？** 销售负责人本人，还是 SDR 团队？决定 Dashboard 的复杂度。
2. **自用还是卖货？** 先作为内部工具武装自己的销售团队，还是 SaaS 卖给同行？建议**先内部工具**（自产自用、快速验证），SaaS 化是 V3 的事。
3. **频率多高？** 每周跑一次批量，还是常驻监控新地块/新公司注册？这决定架构是脚本还是服务。

### 2.3 功能范围 ⚠️ MVP 过大

当前 MVP 范围：Google Maps 抓取 + Instagram 抓取 + 官网解析 + LLM 评分 + CSV + Airtable + 飞书 + Streamlit + Docker —— **这是 V2.5 的体量，不是 MVP**。

建议 MVP 收敛为一条最短闭环：

```
Google Places API（官方） → 官网解析 → LLM 评分 → Streamlit 列表 → WA 破冰链接
```

- **砍掉**：Instagram 抓取（风控最严、命中率最低、合规风险最高）、飞书同步（与 Airtable 二选一即可）。
- **延后**：Docker 部署（内部工具阶段本地跑足够）。
- **限定地域**：只做巴厘岛 Canggu / Uluwatu / Pererenan 三个区，雅加达延后。

### 2.4 评分模型 ❌ 需重做（本评估最重要的修改意见）

**问题 1：把"客户质量"和"能不能联系上"混在一个分数里。**

`直连触达 15%` 是数据可得性维度，不是客户价值维度。一个完美客户不该因为没留电话就降档。建议拆成两个分数：

```
质量分 Quality = 风格30 + 体量25 + 痛点20 + 时机15 + 区位10   （值不值得跟）
触达分 Reach   = 直连WA / 公司总机 / 仅表单 / 无联系方式          （好不好跟）
优先级 Priority = Quality × Reach 系数
```

**问题 2：核心洞察"刚买地"没有对应维度。**

新增 **时机（Timing）** 维度，信号源：土地交易记录、PBG/IMB 建筑许可公示、新注册 PT 公司、招聘帖（招建筑师/项目经理）。这是真正的差异化壁垒。

**问题 3：LLM 打分无防幻觉机制。**

要求每个维度打分必须**附证据引文**（网页原文摘录）+ 置信度；60-79 分区间的线索进人工复核队列。没有这条，分数不可信，销售很快就会弃用。

**问题 4：权重是拍脑袋的静态值。**

权重应可配置（settings.yaml），并且**从 Nusantara-Villa 的转化数据回流校准**（见第三节）。

### 2.5 合规风险 ❌ README 完全未提，必须前置

| 风险 | 说明 | 修改建议 |
| :--- | :--- | :--- |
| 印尼 PDP 法（UU No.27/2022） | 抓取、存储、使用个人电话/邮箱受监管 | 只收集**商业公开联系信息**；数据库加来源与采集时间字段；提供删除机制 |
| Google Maps ToS | Playwright 抓 Maps 违反条款，易封 | 改用 **Google Places API**（官方付费接口，成本可控） |
| Instagram | 抓 IG 是 Meta 重点打击对象 | MVP 砍掉；后期用官方 Graph API 或第三方合规数据源 |
| WhatsApp 封号 | 个人号群发冷启动消息极易被封 | 用 **WhatsApp Business API + 消息模板**；破冰话术首条必须克制（一条个性化消息，不带链接轰炸）；控制日发送量 |

> 合规不是法务装饰：WA 主号被封 = 销售通道直接瘫痪，这是本产品的生死线。

### 2.6 商业模式 ⚠️ 空白

- 建议 V2 定位为**内部销售武器**，KPI 不是营收而是"每周合格对话数"。
- 验证 3-6 个月后，再评估 SaaS 化（卖给其他 D&B 团队、建材供应商、家具商）。

---

## 三、与 Nusantara-Villa 的协同设计（重点）

目标：**一个漏斗、一套数据、双向校准。**

### 3.1 统一线索数据模型（最高优先级）

两个产品必须共用同一份 Lead 数据契约。建议字段：

```json
{
  "lead_id": "uuid，全局唯一",
  "source": "indoscout | nusantara_web",
  "phone_wa": "去重主键（E.164 格式）",
  "name": "", "company": "", "role": "decision_maker|agent|unknown",
  "grade": "S|A|B",
  "quality_score": 0, "reach_score": 0,
  "style_tags": ["modern_tropical"],
  "estimated_area_sqm": 0, "estimated_budget_usd": 0,
  "timing_signals": ["land_purchase_2025Q3"],
  "status": "new|contacted|replied|meeting|proposal|won|lost",
  "utm_ref": "追踪串"
}
```

- **落地建议**：以 Nusantara-Villa 已有的 Cloudflare D1 为统一线索库（它已有 `/api/lead` 接口），IndoScout 作为写入方调用同一接口，而不是各搞一套 Airtable/D1。
- 这样 Nusantara-Villa 的 Telegram 实时推送能力（`lib/telegram.ts`）可以直接复用：IndoScout 评出的 80+ 热线索，**毫秒级推到项目经理手机**，与 C 端线索同通道、同优先级队列。

### 3.2 破冰 → 落地页的无缝衔接（体验闭环）

当前设计里 WA 破冰是终点，这是浪费。建议：

1. WA 破冰话术中附带 **Nusantara-Villa 配置器个性化链接**：
   `https://nusantara-villa.pages.dev/configurator?style=modern_tropical&area=300&ref={lead_id}`
2. 链接参数**预填风格与面积**（来自 IndoScout 的 LLM 分析结果）——客户点开看到的不是通用首页，而是"为他准备好"的别墅方案，转化率天差地别。
3. `ref` 参数贯通归因：客户在配置器里看了什么、BOQ 配了什么价位，全部回写到该 lead 的时间线，销售跟进时手里有牌。

### 3.3 转化数据回流校准评分（智能闭环）

```
IndoScout 评分 → 触达 → Nusantara-Villa 承接 → 转化结果
        ↑                                            │
        └────────── 回流：哪类线索真的成交了 ──────────┘
```

- 每月跑一次复盘：按 style_tags / grade / 各维度分数分组，看回复率、方案书生成率、成交率。
- 用真实转化数据回归校准权重——第 6 个月时，评分模型从"专家拍脑袋"进化成"数据驱动"，这是竞品抄不走的东西。

### 3.4 去重与防冲突

- `phone_wa` 全局去重：同一个老板既被 IndoScout 挖到、又自己访问了 Nusantara-Villa，绝不能收到两套话术。
- 状态机以 D1 为准：C 端已进 `proposal` 的线索，B 端触达自动抑制。

### 3.5 品牌边界

- **Nusantara-Villa 是唯一对客户可见的品牌**。IndoScout 是内部工具，其存在、抓取行为、评分逻辑都不应泄露给客户（包括 WA 话术、链接参数命名不要用 `indoscout` 字样，用 `ref`）。
- 数据资产（词库、风格分类体系）双向共享：两个产品的风格标签（Modern Tropical / Wabi-Sabi / Minimalist Luxury）必须来自**同一份配置**，避免各说各话。

### 3.6 反向输血：C 端数据增强 B 端

- Nusantara-Villa 的 BOQ 造价引擎数据 → 帮 IndoScout 更准地预估"项目体量/预算"维度。
- Nusantara-Villa 的租金 ROI 大数据 → 写进 WA 破冰话术（"Canggu 同规格别墅日租 $XXX，年化 X%"），让冷启动消息第一句话就有价值感。

---

## 四、修改后的路线图建议

| 阶段 | 内容 | 验收标准 |
| :--- | :--- | :--- |
| **P0 技术验证（2 周）** | Places API 抓 100 条 → 官网解析 → LLM 评分跑通 | 决策人联系方式命中率 ≥30%；LLM 评分人工抽检一致率 ≥70% |
| **P1 MVP（4-6 周）** | 巴厘岛三区、S/A 级词库、质量分+触达分、Streamlit、WA 链接带 ref 参数 | 每周产出 20+ 条 60 分以上线索 |
| **P2 协同层（4 周）** | 统一 Lead 模型写入 D1、Telegram 推送复用、配置器预填链接、去重状态机 | B 端线索→配置器访问→方案书全链路可追踪 |
| **P3 校准迭代（持续）** | 转化数据回流、权重回归、WA Business API 迁移 | 回复率 ≥15%；评分-转化相关性可量化 |

> 对 README 中"2026 年 10 月可用"的时间线：按上述切片，P1 MVP 约 2 个月可见真东西，不必等到一个遥远的大版本。

---

## 五、对 README 的直接修改清单

1. 新增「与 Nusantara-Villa 协同」章节：统一 Lead 模型、ref 归因链路、品牌边界。
2. 评分公式改为 Quality × Reach 双分制，新增 Timing（时机）维度。
3. 合规章节：PDP 法、Places API 替代 Playwright 抓 Maps、WA Business API。
4. 技术栈中 Instagram 抓取标注为"V3 延后，合规审查后决定"。
5. 项目结构中 `exporters/airtable_sync.py` 改为 `sync/d1_lead_sync.py`（对齐统一线索库）。
6. 增加「北极星指标」：每周合格对话数（replied leads / week），以及漏斗指标定义。
7. "多管道输出"收敛为：MVP 只有 Streamlit + D1 同步，CSV 降级为导出按钮。

---

*本文档为产品评审意见，供项目决策参考。*
