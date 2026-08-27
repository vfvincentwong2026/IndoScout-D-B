#!/usr/bin/env bash
# IndoScout · Google Places API 一键开通脚本
# 前置：① 已运行 gcloud auth login（用户本人浏览器授权）② 已在控制台创建计费账号并拿到 Billing Account ID
# 用法：bash scripts/gcloud_setup_indoscout.sh <BILLING_ACCOUNT_ID>
# 例：  bash scripts/gcloud_setup_indoscout.sh 0123AB-4567CD-89EF01

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd -W)"
export CLOUDSDK_PYTHON="$WORKSPACE\\tools\\google-cloud-sdk\\platform\\bundledpython\\python.exe"
GCLOUD="$WORKSPACE/tools/google-cloud-sdk/bin/gcloud"

BILLING_ACCOUNT="${1:-}"
if [ -z "$BILLING_ACCOUNT" ]; then
  echo "❌ 缺少 Billing Account ID 参数"; exit 1
fi

PROJECT_ID="indoscout-$(date +%y%m%d%H%M)"
echo "==> 项目 ID: $PROJECT_ID"

echo "==> [1/6] 检查登录状态"
"$GCLOUD" auth list --filter=status:ACTIVE --format="value(account)" | grep . >/dev/null \
  || { echo "❌ 未登录，请先运行: tools\\google-cloud-sdk\\bin\\gcloud auth login"; exit 1; }

echo "==> [2/6] 创建项目"
"$GCLOUD" projects create "$PROJECT_ID" --name="IndoScout" --quiet
"$GCLOUD" config set project "$PROJECT_ID" --quiet

echo "==> [3/6] 关联计费账号 $BILLING_ACCOUNT"
"$GCLOUD" billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT" --quiet

echo "==> [4/6] 启用 API（Places API New + API Keys 管理）"
"$GCLOUD" services enable places-backend.googleapis.com apikeys.googleapis.com --quiet

echo "==> [5/6] 创建并限制 API Key（仅允许 Places API New）"
KEY_NAME=$("$GCLOUD" alpha services api-keys create \
  --display-name="indoscout-s1" \
  --api-target=service=places-backend.googleapis.com \
  --format="value(name)" --quiet)
KEY_STRING=$("$GCLOUD" alpha services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" --quiet)

echo "==> [6/6] 写入 .env"
cd "$WORKSPACE"
touch .env
grep -q "GOOGLE_PLACES_API_KEY" .env 2>/dev/null && sed -i "/GOOGLE_PLACES_API_KEY/d" .env
echo "GOOGLE_PLACES_API_KEY=$KEY_STRING" >> .env
grep -q "^\.env$" .gitignore 2>/dev/null || echo ".env" >> .gitignore

echo ""
echo "✅ 完成！"
echo "   项目: $PROJECT_ID"
echo "   Key 已写入: $WORKSPACE\\.env（已加入 .gitignore）"
echo "   Key 前 12 位: ${KEY_STRING:0:12}..."
echo ""
echo "👉 请再去控制台补一个 \$5 预算告警（脚本做不了的部分）："
echo "   https://console.cloud.google.com/billing  → Budgets & alerts → Create budget"
