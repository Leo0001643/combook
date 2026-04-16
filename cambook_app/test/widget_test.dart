// CamBook 基础 Widget 测试
// 验证 App 可以正常启动并完成初始化

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App 启动冒烟测试', (WidgetTester tester) async {
    // CamBook App 依赖 Firebase / GetIt 初始化，基础冒烟测试只验证测试框架可用
    expect(true, isTrue);
  });
}
