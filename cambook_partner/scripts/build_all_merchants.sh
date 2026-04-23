#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 批量打包所有商户脚本
#
# 用法:
#   ./scripts/build_all_merchants.sh [platform] [export-method]
#
# 示例:
#   ./scripts/build_all_merchants.sh           # 构建所有商户的 APK + IPA
#   ./scripts/build_all_merchants.sh ipa       # 仅构建 IPA
#   ./scripts/build_all_merchants.sh apk       # 仅构建 APK
# ────────────────────────────────────────────────────────────────
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MERCHANTS_DIR="$(cd "$SCRIPT_DIR/../merchants" && pwd)"
PLATFORM="${1:-both}"
EXPORT_METHOD="${2:-development}"

CONFIGS=("$MERCHANTS_DIR"/*.json)
if [[ ${#CONFIGS[@]} -eq 0 ]]; then
  echo "❌  merchants/ 目录下没有商户配置文件"
  exit 1
fi

echo ""
echo "📦  即将构建 ${#CONFIGS[@]} 个商户的包..."
echo ""

FAILED=()
for cfg in "${CONFIGS[@]}"; do
  key=$(basename "$cfg" .json)
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▶  商户: $key"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if "$SCRIPT_DIR/build_merchant.sh" "$key" "$PLATFORM" "$EXPORT_METHOD"; then
    echo "✅  $key 构建成功"
  else
    echo "❌  $key 构建失败"
    FAILED+=("$key")
  fi
  echo ""
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "⚠️   以下商户构建失败: ${FAILED[*]}"
  exit 1
else
  echo "🎉  全部商户构建完成！"
fi
