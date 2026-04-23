# 新增商户操作手册

> 一套代码，多商户打包。每次新增商户按以下清单操作，通常 **30 分钟内** 即可完成。

---

## 目录

1. [整体架构说明](#1-整体架构说明)
2. [开发环境配置（必读）](#2-开发环境配置必读)
3. [第一步：新增商户配置文件](#3-第一步新增商户配置文件)
4. [第二步：Android — 新增 Flavor](#4-第二步android--新增-flavor)
5. [第三步：iOS — 证书与 Bundle ID](#5-第三步ios--证书与-bundle-id)
6. [第四步：App 图标替换](#6-第四步app-图标替换)
7. [第五步：后端数据库新增商户记录](#7-第五步后端数据库新增商户记录)
8. [第六步：打包验证](#8-第六步打包验证)
9. [配置字段说明](#9-配置字段说明)

---

## 1. 整体架构说明

```
                  ┌─────────────────────────────────────┐
                  │        一套 Flutter 源代码            │
                  └──────────────┬──────────────────────┘
                                 │ --dart-define + flavor
              ┌──────────────────┼──────────────────────┐
              │                  │                       │
       CamBook Partner    SpaVibe Partner         商户 C Partner
       包名: com.cambook   包名: com.spavibe       包名: com.xxx
       merchantId: 1       merchantId: 2           merchantId: N
              │                  │                       │
       cambook.json        spavibe.json            xxx.json
```

- **业务配置**（merchantId、API、主题色、Banner）→ `merchants/xxx.json` + `--dart-define`
- **包名/Bundle ID**（Android `applicationId`）→ `build.gradle.kts` `productFlavors`
- **iOS Bundle ID** → 打包脚本构建前自动注入，构建后还原
- **App 图标** → 各商户独立图标资源目录

---

## 2. 开发环境配置（必读）

### 为什么必须配置？

`AppConfig` 中所有字段均使用 `dart-define` **编译期常量**：

```dart
static const merchantId = int.fromEnvironment('MERCHANT_ID', defaultValue: 1);
```

- **不传参数直接运行** → 使用 `defaultValue`（merchantId=1，不是真实商户）
- **传入 `--dart-define-from-file`** → 从 JSON 文件读取真实商户配置

> ⚠️ 修改 JSON 文件后，必须重新运行/重新编译才会生效，热重载（Hot Reload）**无效**。

---

### 方式一：IntelliJ IDEA（推荐）

1. 顶部菜单 → **Run** → **Edit Configurations...**

2. 左侧选中 Flutter 运行配置（通常名为 `main.dart`）

3. 找到 **Additional run args** 输入框，填入：

   ```
   --dart-define-from-file=merchants/cambook.json
   ```

4. 点击 **OK** 保存

5. 以后直接点击 ▶ 运行按钮即可，配置永久生效

**截图参考：**
```
┌─ Run/Debug Configurations ──────────────────────────────────────────┐
│  Flutter                                                            │
│  ├── Name:              main.dart                                   │
│  ├── Dart entrypoint:   lib/main.dart                              │
│  ├── Additional run args: --dart-define-from-file=merchants/cambook.json  │
│  └── ...                                                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 方式二：Cursor / VS Code（已预配置）

项目已内置 `.vscode/launch.json`，无需额外操作：

1. 点击左侧 **Run and Debug** 图标（或按 `Ctrl+Shift+D` / `Cmd+Shift+D`）
2. 顶部下拉选择 **cambook (开发)**
3. 点击 ▶ 启动即可

如需切换商户，修改 `.vscode/launch.json` 中的文件名：

```jsonc
"args": ["--dart-define-from-file=merchants/cambook.json"]
//                                                ↑ 改为对应商户的 JSON 文件名
```

---

### 方式三：命令行

```bash
# 开发调试运行（连接手机/模拟器）
flutter run --dart-define-from-file=merchants/cambook.json

# 指定设备
flutter run -d <device_id> --dart-define-from-file=merchants/cambook.json

# Profile 模式（性能测试）
flutter run --profile --dart-define-from-file=merchants/cambook.json
```

---

### 多商户切换

| 操作 | 说明 |
|------|------|
| 修改 IDEA run args | 将文件名改为目标商户 JSON |
| 修改 launch.json | 将文件名改为目标商户 JSON |
| 命令行 | 改 `--dart-define-from-file` 的文件路径 |

> 每次切换商户后需要**完整重新启动**（Stop → Run），不能热重载。

---

## 3. 第一步：新增商户配置文件

在 `merchants/` 目录下复制并修改：

```bash
cp merchants/cambook.json merchants/xxx.json
```

编辑 `merchants/xxx.json`，填写所有字段：

```jsonc
{
  "MERCHANT_ID":    3,                          // 数据库 cb_merchant.id（必须与后端一致）
  "MERCHANT_KEY":   "xxx",                      // 英文唯一标识，全小写，与文件名相同
  "MERCHANT_NAME":  "XXX 商户名",
  "APP_NAME":       "XXX Partner",              // App 显示名称（手机桌面图标下方）
  "API_BASE_URL":   "https://api.xxx.com",      // 后端接口根地址
  "THEME_COLOR":    "E53E3E",                   // 主题主色（6位十六进制，不含 #）
  "BANNER_URL":     "https://cdn.xxx.com/banner.jpg",  // 首页 Banner（留空使用默认渐变）
  "LOGO_URL":       "https://cdn.xxx.com/logo.png",    // 商户 Logo（留空使用默认图标）
  "SUPPORT_PHONE":  "+8613812345678",           // 客服电话
  "ANDROID_APP_ID": "com.xxx.partner",          // Android 包名（全球唯一，建议反向域名）
  "IOS_BUNDLE_ID":  "com.xxx.partner",          // iOS Bundle ID（需与证书一致）
  "VERSION_NAME":   "1.0.0",
  "VERSION_CODE":   1
}
```

---

## 4. 第二步：Android — 新增 Flavor

编辑 `android/app/build.gradle.kts`，在 `productFlavors` 块中追加：

```kotlin
create("xxx") {
    dimension     = "merchant"
    applicationId = "com.xxx.partner"           // 与 JSON 中 ANDROID_APP_ID 一致
    resValue("string", "app_name", "XXX Partner")
}
```

> **仅需添加这 4 行**，其余代码不需要改动。

---

## 5. 第三步：iOS — 证书与 Bundle ID

iOS 需要为每个 Bundle ID 单独申请证书，分以下几步：

### 4.1 在 Apple Developer Portal 创建 App ID

1. 登录 [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → **Identifiers** → **+**
3. 选择 **App IDs** → 填写 Bundle ID：`com.xxx.partner`
4. 开启需要的 Capabilities（Push Notifications 等）→ 注册

### 4.2 创建 Provisioning Profile

1. **Profiles** → **+** → 选择类型：
   - 开发测试 → Development
   - 企业分发 → In House
   - App Store → App Store
2. 选择刚创建的 App ID，选择设备/证书 → 下载 `.mobileprovision`
3. 双击安装到 Mac

### 4.3 Xcode 绑定（仅首次）

```
Xcode → Runner → Signing & Capabilities
→ Team: 选择对应开发者账号
→ Bundle Identifier: com.xxx.partner（打包脚本会自动注入，此处保持默认即可）
```

> **打包脚本（`build_merchant.sh`）会在构建前自动修改 Bundle ID，构建完成后自动还原**，
> 无需手动每次修改 Xcode 工程文件。

---

## 6. 第四步：App 图标替换

### Android

将商户 App 图标放入对应 Flavor 资源目录（按分辨率）：

```
android/app/src/xxx/res/
├── mipmap-hdpi/    ic_launcher.png   (72×72)
├── mipmap-mdpi/    ic_launcher.png   (48×48)
├── mipmap-xhdpi/   ic_launcher.png   (96×96)
├── mipmap-xxhdpi/  ic_launcher.png   (144×144)
└── mipmap-xxxhdpi/ ic_launcher.png   (192×192)
```

> 若该目录不存在，从 `android/app/src/main/res/` 复制目录结构后替换图片即可。
> Flavor 目录中的资源会自动覆盖 `main/res` 中的同名文件。

推荐使用 [appicon.co](https://www.appicon.co/) 或 `flutter_launcher_icons` 包一键生成。

### iOS

将商户 `AppIcon.appiconset` 放入 iOS 对应 Assets 目录，然后在 Xcode 中为该商户创建独立的 Asset Catalog（可选，简单方案：共用同一套图标）。

---

## 7. 第五步：后端数据库新增商户记录

在后端数据库 `cb_merchant` 表中插入一条新记录：

```sql
INSERT INTO cb_merchant (
  merchant_no,    -- 商户编号（注册时技师填写）
  merchant_name,  -- 商户名称
  status,         -- 1=正常
  audit_status,   -- 1=审核通过
  deleted         -- 0=未删除
) VALUES (
  'XXX001',
  'XXX 商户名',
  1, 1, 0
);
-- 记录插入后的 id，填入 merchants/xxx.json 的 MERCHANT_ID
```

> **`MERCHANT_ID` 必须与数据库 `cb_merchant.id` 一致**，否则技师登录时租户隔离校验会失败。

---

## 8. 第六步：打包验证

```bash
# 进入 Flutter 项目目录
cd cambook_partner

# 构建指定商户（APK + IPA）
./scripts/build_merchant.sh xxx

# 仅构建 Android APK
./scripts/build_merchant.sh xxx apk

# 仅构建 iOS IPA（development 证书）
./scripts/build_merchant.sh xxx ipa development

# 构建 App Store 版本
./scripts/build_merchant.sh xxx ipa app-store

# 批量构建所有商户
./scripts/build_all_merchants.sh
```

打包输出文件位于：`cambook_partner/build/merchant_output/`

---

## 9. 配置字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `MERCHANT_ID` | int | ✅ | 数据库 `cb_merchant.id`，租户隔离关键字段 |
| `MERCHANT_KEY` | string | ✅ | 英文唯一标识，与文件名保持一致 |
| `MERCHANT_NAME` | string | ✅ | 商户显示名称（UI 展示） |
| `APP_NAME` | string | ✅ | 手机桌面 App 名称 |
| `API_BASE_URL` | string | ✅ | 后端接口根地址（不含尾斜杠） |
| `THEME_COLOR` | string | ✅ | 主题主色，6位十六进制，不含 `#` |
| `BANNER_URL` | string | | 首页 Banner 图片 URL，留空使用默认渐变 |
| `LOGO_URL` | string | | 商户 Logo URL，留空使用默认图标 |
| `SUPPORT_PHONE` | string | | 客服电话（含国家区号） |
| `ANDROID_APP_ID` | string | ✅ | Android 包名，需与 `build.gradle.kts` 中 flavor 一致 |
| `IOS_BUNDLE_ID` | string | ✅ | iOS Bundle ID，需与 Apple Developer Portal 中的 App ID 一致 |
| `VERSION_NAME` | string | ✅ | 版本号，如 `1.0.0` |
| `VERSION_CODE` | int | ✅ | 构建号，每次发版递增 |

---

## 新增商户检查清单

```
□ 1. 创建 merchants/xxx.json，填写所有字段
□ 2. build.gradle.kts productFlavors 中追加 create("xxx") { ... }
□ 3. Apple Developer Portal 创建 Bundle ID + Provisioning Profile
□ 4. 准备并放置 Android/iOS App 图标资源
□ 5. 后端 cb_merchant 表插入记录，记录数字 ID 填入 JSON
□ 6. 执行 ./scripts/build_merchant.sh xxx 验证打包成功
□ 7. 在真机上安装测试，用该商户的技师账号登录验证租户隔离
```
