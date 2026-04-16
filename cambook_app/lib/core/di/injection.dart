/// 依赖注入
///
/// GetX 内置 IoC 容器，无需第三方 get_it。
/// 所有控制器均在 main.dart 的 Get.put(..., permanent: true) 中注册。
///
/// 按需注册示例（懒加载）：
///   Get.lazyPut<SomeController>(() => SomeController());
///
/// 服务示例：
///   Get.putAsync<ApiService>(() async => ApiService.create());
///
/// 本文件保留作为注入层文档说明；实际注册逻辑见 lib/main.dart。
library;
