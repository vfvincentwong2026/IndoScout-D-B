# Google Places API 开通指引（给 IndoScout S1 验证用）

> **2026-08 更新：CLI 半自动路径已就绪** —— gcloud 便携版已装在 `tools/google-cloud-sdk/`，一键脚本在 `scripts/gcloud_setup_indoscout.sh`。
> **你只剩 2 件 CLI 做不了的事**：① 运行 `gcloud auth login` 浏览器授权；② 控制台绑信用卡创建计费账号（谷歌强制网页操作）。其余建项目/启用 API/创建并限制 Key/写 .env 全部由脚本完成。

> 面向：无 Google Cloud 使用经验的产品/业务同学
> 目标：拿到一把可用的 API Key，交给 IndoScout 跑 P0-S1 线索可得性验证
> 全程约 20-30 分钟

---

## 0. 开始前准备

| 需要 | 说明 |
| :--- | :--- |
| 一个 Google 账号 | Gmail 即可，建议用工作账号 |
| **科学上网环境** | console.cloud.google.com 在大陆不可直连，全程需挂代理 |
| **一张外币信用卡** | Visa/Mastercard。开通计费必须绑卡，但**免费额度内不会扣费**（下文有防超额保险设置）。国内单币银联卡一般不行，双币卡可以 |

> 💡 关于费用（2025 年 3 月新政后）：不再有每月 $200 通用额度，改为**每个 SKU 独立免费额度**。我们要用的 Text Search（New）属于 Pro 档：**每月 5,000 次免费**，超出后 $32/千次。新账号另有**一次性 $300 试用金**（90 天有效）。
>
> **S1 验证用量估算**：15 条词 × 每词翻页 1-3 次 ≈ 30-50 次调用，翻页返回里直接带电话和官网字段，无需额外付费的 Details 调用。**总用量不到免费额度的 1%，实际花费 $0。**

---

## 1. 创建项目（2 分钟）

1. 打开 <https://console.cloud.google.com/>
2. 左上角点项目下拉框（写着 "Select a project" 或你已有的项目名）→ **New Project**
3. 项目名填 `indoscout` → **Create**（Organization 栏留空即可）
4. 等右上角通知铃铛提示创建完成，再次从下拉框**选中 indoscout 项目**（这步很关键，后面所有操作都要确认在这个项目下）

## 2. 开通计费账号（5 分钟）

1. 左侧菜单 ☰ → **Billing**（结算）
2. 点 **Link a billing account** → **Create billing account**
3. 国家/地区选**与卡片一致的真实地区**，填姓名、地址、卡号
4. 同意条款提交。此时会激活 **$300 试用金 / 90 天**（页面会显示 "Free trial" 状态）
5. ⚠️ 可能扣一笔 $1 左右的**验证预授权**，几天内自动退回，不是真实扣费

## 3. 启用 Places API（新版）（2 分钟）

1. 左侧菜单 ☰ → **APIs & Services** → **Library**（库）
2. 搜索框输入 `Places API`
3. ⚠️ 注意甄别：结果里会有两个——
   - **Places API (New)** ← ✅ 选这个
   - Places API（旧版，已标记 Legacy）← ❌ 不要选
4. 点进 **Places API (New)** → 点 **Enable**（启用）

## 4. 创建 API Key（2 分钟）

1. **APIs & Services** → **Credentials**（凭据）
2. 顶部 **+ Create Credentials** → **API key**
3. 弹窗里出现一串 `AIza...` 开头的字符串——**这就是 Key，先复制保存到本地**
4. 先别关弹窗，点 **Restrict key**（限制密钥），进入第 5 步

## 5. 给 Key 上锁（重要，防盗用）

API Key 泄露会被人盗刷额度，必须限制：

1. 在 key 编辑页，**API restrictions** 选 **Restrict key**
2. 下拉列表只勾选 **Places API (New)** 一项
3. **Application restrictions** 可暂选 None（本地脚本用）；如固定 IP 可选 IP addresses 填自家出口 IP
4. **Save**

## 6. 上保险：预算告警（3 分钟，强烈建议）

防止任何意外产生账单：

1. 左侧菜单 ☰ → **Billing** → **Budgets & alerts**（预算和提醒）
2. **Create budget**：
   - 名称 `safety-cap`
   - Amount 填 `5`（美元）
   - Alerts 保持默认 50% / 90% / 100%，填自己的邮箱
3. **Save**。超额时会邮件提醒（告警不自动断服务，但 $5 以内无感知风险）

> 更彻底的做法：S1 验证跑完后，回到 Billing 把项目与计费账号**解除关联**，服务立即停、永不产生费用。

## 7. 把 Key 交给我

两种方式任选：

- **方式 A（推荐）**：在工作区创建 `.env` 文件（不会进 git），内容一行：
  ```
  GOOGLE_PLACES_API_KEY=AIza...你的key
  ```
- **方式 B**：直接在对话里发给我，我写入 `.env`（Key 属敏感信息，发完建议你之后在 console 里可随时 regenerate）

---

## 验证清单

- [ ] 项目 `indoscout` 已创建并选中
- [ ] 计费账号已绑卡，$300 试用金显示激活
- [ ] 启用的是 **Places API (New)** 而非旧版
- [ ] API Key 已限制为仅 Places API (New)
- [ ] $5 预算告警已设置
- [ ] Key 已写入工作区 `.env`

全部打勾后告诉我，我就开跑 S1：S 级词库 × 巴厘岛三区，抓 100 条线索，验证官网可得率 ≥50% 与 WA 命中率 ≥30% 两条红线。
