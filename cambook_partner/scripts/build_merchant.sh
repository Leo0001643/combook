#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────────
# 单商户打包脚本  —— 支持包名/Bundle ID 动态注入
#
# 用法:
#   ./scripts/build_merchant.sh <商户Key> [platform] [export-method]
#
#   platform      : apk | ipa | both  (默认 both)
#   export-method : development | ad-hoc | app-store  (默认 development)
#
# 示例:
#   ./scripts/build_merchant.sh cambook
#   ./scripts/build_merchant.sh spavibe ipa app-store
#   ./scripts/build_merchant.sh cambook apk
# ────────────────────────────────────────────────────────────────────────────
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MERCHANTS_DIR="$PROJECT_DIR/merchants"
OUTPUT_DIR="$PROJECT_DIR/build/merchant_output"

MERCHANT_KEY="${1:-}"
PLATFORM="${2:-both}"
EXPORT_METHOD="${3:-development}"

# ── 参数校验 ─────────────────────────────────────────────────────────────────
if [[ -z "$MERCHANT_KEY" ]]; then
  echo "❌  用法: $0 <商户Key> [platform] [export-method]"
  echo "    可用商户: $(ls "$MERCHANTS_DIR"/*.json | xargs -I{} basename {} .json | tr '\n' ' ')"
  exit 1
fi

CONFIG_FILE="$MERCHANTS_DIR/$MERCHANT_KEY.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌  找不到商户配置文件: $CONFIG_FILE"
  exit 1
fi

# ── 读取配置 ─────────────────────────────────────────────────────────────────
cfg() { python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('$1',''))" ; }

MERCHANT_ID=$(cfg MERCHANT_ID)
MERCHANT_KEY_VAL=$(cfg MERCHANT_KEY)
MERCHANT_NAME=$(cfg MERCHANT_NAME)
APP_NAME=$(cfg APP_NAME)
API_BASE_URL=$(cfg API_BASE_URL)
THEME_VARIANT=$(cfg THEME_VARIANT)
THEME_COLOR=$(cfg THEME_COLOR)
BANNER_URL=$(cfg BANNER_URL)
LOGO_URL=$(cfg LOGO_URL)
SUPPORT_PHONE=$(cfg SUPPORT_PHONE)
ANDROID_APP_ID=$(cfg ANDROID_APP_ID)
IOS_BUNDLE_ID=$(cfg IOS_BUNDLE_ID)

# 显式校验必填字段（替代 set -u 的隐式检查，兼容 macOS bash 3.2）
[[ -z "$MERCHANT_ID"      ]] && echo "❌  MERCHANT_ID 未配置"      && exit 1
[[ -z "$MERCHANT_KEY_VAL" ]] && echo "❌  MERCHANT_KEY 未配置"      && exit 1
[[ -z "$ANDROID_APP_ID"   ]] && echo "❌  ANDROID_APP_ID 未配置"    && exit 1
[[ -z "$IOS_BUNDLE_ID"    ]] && echo "❌  IOS_BUNDLE_ID 未配置"     && exit 1

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           CamBook Partner — 多商户打包工具               ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  商户Key    : %-44s ║\n" "$MERCHANT_KEY_VAL"
printf "║  商户ID     : %-44s ║\n" "$MERCHANT_ID"
printf "║  Android包名: %-44s ║\n" "$ANDROID_APP_ID"
printf "║  iOS Bundle : %-44s ║\n" "$IOS_BUNDLE_ID"
printf "║  平台       : %-44s ║\n" "$PLATFORM"
printf "║  导出方式   : %-44s ║\n" "$EXPORT_METHOD"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── 公共 dart-define 参数（拼成单字符串，兼容 macOS bash 3.2 对数组的限制）──
DART_DEFINES_STR=""
DART_DEFINES_STR+=" --dart-define=MERCHANT_ID=$MERCHANT_ID"
DART_DEFINES_STR+=" --dart-define=MERCHANT_KEY=$MERCHANT_KEY_VAL"
DART_DEFINES_STR+=" --dart-define=MERCHANT_NAME=$MERCHANT_NAME"
DART_DEFINES_STR+=" --dart-define=APP_NAME=$APP_NAME"
DART_DEFINES_STR+=" --dart-define=API_BASE_URL=$API_BASE_URL"
DART_DEFINES_STR+=" --dart-define=THEME_VARIANT=$THEME_VARIANT"
DART_DEFINES_STR+=" --dart-define=THEME_COLOR=$THEME_COLOR"
DART_DEFINES_STR+=" --dart-define=BANNER_URL=$BANNER_URL"
DART_DEFINES_STR+=" --dart-define=LOGO_URL=$LOGO_URL"
DART_DEFINES_STR+=" --dart-define=SUPPORT_PHONE=$SUPPORT_PHONE"

mkdir -p "$OUTPUT_DIR"

# ── iOS Bundle ID 临时注入（构建前 patch，构建后还原）────────────────────────
PBXPROJ="$PROJECT_DIR/ios/Runner.xcodeproj/project.pbxproj"
PBXPROJ_BACKUP="$PBXPROJ.bak_build"

patch_ios_bundle_id() {
  echo "▶  注入 iOS Bundle ID: $IOS_BUNDLE_ID"
  cp "$PBXPROJ" "$PBXPROJ_BACKUP"
  # 替换 Runner 的 PRODUCT_BUNDLE_IDENTIFIER（不替换 RunnerTests）
  sed -i '' \
    "s/PRODUCT_BUNDLE_IDENTIFIER = com\.[^;]*cambookPartner;/PRODUCT_BUNDLE_IDENTIFIER = $IOS_BUNDLE_ID;/g" \
    "$PBXPROJ"
}

restore_ios_bundle_id() {
  if [[ -f "$PBXPROJ_BACKUP" ]]; then
    mv "$PBXPROJ_BACKUP" "$PBXPROJ"
    echo "▶  iOS Bundle ID 已还原"
  fi
}

# 注册 EXIT 钩子，确保异常时也还原
trap restore_ios_bundle_id EXIT

# ── 构建 Android APK ─────────────────────────────────────────────────────────
build_apk() {
  echo ""
  echo "▶  正在构建 Android APK (flavor=${MERCHANT_KEY})..."
  (
    cd "$PROJECT_DIR"
    eval flutter build apk \
      --release \
      --flavor "$MERCHANT_KEY" \
      -t lib/main.dart \
      "$DART_DEFINES_STR"
  )
  APK_SRC="$PROJECT_DIR/build/app/outputs/flutter-apk/app-${MERCHANT_KEY}-release.apk"
  APK_OUT="$OUTPUT_DIR/${MERCHANT_KEY}_$(date +%Y%m%d_%H%M%S).apk"
  cp "$APK_SRC" "$APK_OUT"
  echo "✅  APK → $APK_OUT"
}

# ── 构建 iOS IPA ─────────────────────────────────────────────────────────────
build_ipa() {
  echo ""
  echo "▶  正在构建 iOS IPA..."
  patch_ios_bundle_id
  (
    cd "$PROJECT_DIR"
    eval flutter build ipa \
      --release \
      --export-method="$EXPORT_METHOD" \
      "$DART_DEFINES_STR"
  )
  restore_ios_bundle_id
  trap - EXIT  # 取消 EXIT 钩子（已手动还原）

  IPA_SRC=$(find "$PROJECT_DIR/build/ios/ipa" -name "*.ipa" 2>/dev/null | head -1)
  if [[ -n "$IPA_SRC" ]]; then
    IPA_OUT="$OUTPUT_DIR/${MERCHANT_KEY}_$(date +%Y%m%d_%H%M%S).ipa"
    cp "$IPA_SRC" "$IPA_OUT"
    echo "✅  IPA  → $IPA_OUT"
  else
    echo "⚠️   未找到 .ipa 文件，请检查 Xcode 构建日志"
  fi
}

# ── 执行构建 ─────────────────────────────────────────────────────────────────
case "$PLATFORM" in
  apk)  build_apk; trap - EXIT ;;
  ipa)  build_ipa ;;
  both) build_apk; build_ipa; trap - EXIT 2>/dev/null || true ;;
  *)
    echo "❌  不支持的平台: $PLATFORM (apk | ipa | both)"
    exit 1
    ;;
esac

echo ""
echo "🎉  打包完成！输出目录: $OUTPUT_DIR"
