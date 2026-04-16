# CamBook — 上门按摩SPA平台

> 专业的东南亚上门按摩SPA预约平台，面向柬埔寨、越南及中国市场

---

## 📁 项目结构

```
cambook/
├── cambook-server/          # Spring Boot 后端服务
│   ├── cambook-common/      # 公共模块（工具类/枚举/异常处理）
│   ├── cambook-dao/         # 数据访问层（实体/Mapper）
│   ├── cambook-service/     # 业务逻辑层
│   ├── cambook-api/         # API接口层（Controller/过滤器）
│   └── sql/                 # 数据库脚本
├── cambook-admin/           # React 后台管理系统
└── cambook_app/             # Flutter 多端应用
```

---

## 🚀 技术栈

### 后端 (cambook-server)
| 技术 | 版本 | 用途 |
|------|------|------|
| JDK | 17 | 运行环境 |
| Spring Boot | 3.2.4 | Web框架 |
| MyBatis-Plus | 3.5.7 | ORM框架 |
| MySQL | 8.0 | 主数据库 |
| Redis | 7.x | 缓存/Session/分布式锁 |
| WebSocket | - | IM实时通讯/技师位置 |
| Firebase Admin | 9.2.0 | FCM推送 |
| Twilio | 10.x | 短信服务（支持柬埔寨+855） |
| JWT | 0.12.5 | 双Token认证 |
| Knife4j | 4.4.0 | API文档 |

### 管理前端 (cambook-admin)
| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18 | UI框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Ant Design | 5.x | UI组件库 |
| Zustand | 5.x | 状态管理 |
| React Router | 6.x | 路由 |

### 移动端 (cambook_app)
| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.x | 跨平台框架 |
| Dart | 3.3+ | 编程语言 |
| flutter_bloc | 8.x | 状态管理 |
| go_router | 13.x | 声明式路由 |
| google_maps_flutter | 2.6 | 地图/定位 |
| firebase_messaging | 15.x | 推送通知 |

---

## 🌍 多语言支持

| 语言 | 代码 | 区域 |
|------|------|------|
| 中文简体 | zh-CN | 中国大陆 |
| English | en | 国际 |
| Tiếng Việt | vi | 越南 |
| ភាសាខ្មែរ | km | 柬埔寨 |

---

## 💳 支付方式

| 方式 | 说明 | 适用场景 |
|------|------|----------|
| USDT | TRC20/ERC20加密货币 | 国际用户 |
| ABA Bank | 柬埔寨ABA网银转账 | 柬埔寨用户 |
| 余额 | 平台钱包余额 | 所有用户 |

---

## 📱 支持平台

- ✅ Android
- ✅ iOS  
- ✅ Web (H5)
- ✅ iPad

---

## 🗺️ 地图功能

- 用户实时定位（Google Maps Geolocation）
- 附近技师显示（Redis GEO + Haversine算法）
- 技师实时位置追踪（WebSocket上报）
- 导航到服务地址（Google Maps Navigation）

---

## 🛡️ 安全特性

- JWT 双Token机制（AccessToken 2小时 + RefreshToken 7天）
- Token黑名单（退出登录即时失效）
- 接口幂等性保护（防重复提交）
- BCrypt 密码加密
- 乐观锁（钱包余额并发安全）
- 分布式锁（Redisson）

---

## ⚙️ 快速启动

### 后端服务

```bash
# 1. 创建数据库
mysql -u root -p < cambook-server/sql/cambook_schema.sql

# 2. 修改配置
vim cambook-server/cambook-api/src/main/resources/application.yml

# 3. 编译运行
cd cambook-server
mvn clean package -DskipTests
java -jar cambook-api/target/cambook-api-1.0.0.jar
```

### 管理后台

```bash
cd cambook-admin
npm install
npm run dev
# 访问: http://localhost:3000
```

### Flutter App

```bash
cd cambook_app
flutter pub get
flutter run

# 指定平台
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
```

---

## 📊 功能模块概览

### 会员端 (57个页面)
- 🏠 首页（技师推荐/附近技师/新人特惠）
- 🔍 技师列表（列表/地图双视图）
- 👤 技师详情（评价/相册/预约日历）
- 🛒 下单预约（套餐选择/时间选择/地址选择）
- 💳 支付（USDT/ABA/余额）
- 📦 订单管理（实时追踪/评价）
- 💬 IM聊天（与技师沟通）
- 👛 钱包（充值/提现）
- 🎟️ 优惠券（领取/使用）

### 技师端 (30个页面)
- 🏠 工作台（今日收入/接单数据）
- 📋 接单管理（实时推送/一键接单）
- 🗺️ 导航（Google Maps至客户位置）
- 🗓️ 排班管理（可用时段设置）
- 💰 收入管理（提现到USDT/ABA）

### 商户端 (20个页面)
- 🏢 数据看板
- 👥 技师管理
- 📊 财务报表
- 📢 营销管理

### 管理后台
- 用户管理 / 技师审核 / 商户管理
- 订单管理 / 退款处理
- 财务管理 / 提现审核
- 营销管理 / 优惠券
- 系统配置 / Banner管理

---

## 🏗️ 设计模式应用

| 模式 | 应用场景 |
|------|----------|
| 策略模式 | 支付方式（USDT/ABA/余额各独立策略） |
| 模板方法 | 订单创建流程、认证流程 |
| 工厂模式 | PaymentStrategyFactory |
| 观察者模式 | WebSocket位置更新、订单状态推送 |
| 状态机 | 订单状态流转 |
| BLoC模式 | Flutter端状态管理 |

---

## 📝 API文档

启动后访问：http://localhost:8080/doc.html

---

*CamBook © 2026. All rights reserved.*
