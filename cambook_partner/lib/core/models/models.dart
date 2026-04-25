import '../utils/date_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JSON 安全类型转换工具 —— 防止后端字段类型漂移导致运行时异常
// 全局统一使用，消除各 Model 内重复的 _int/_double/_str 私有方法
// ─────────────────────────────────────────────────────────────────────────────
abstract class JsonUtil {
  static int    intFrom(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static double dblFrom(dynamic v) =>
      v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0.0;
  static String strFrom(dynamic v) => v?.toString() ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// 技师 / 用户模型
// ─────────────────────────────────────────────────────────────────────────────
enum TechStatus { online, busy, rest }
enum TechLevel  { normal, senior, gold, top }

class TechnicianModel {
  final int    id;
  final String nickname;
  final String techNo;
  final String phone;
  final String? avatar;
  final TechLevel level;
  final double rating;
  final int    completedOrders;
  final double balance;
  final List<SkillModel> skills;
  final String memberSince;
  // ── 多商户 ──────────────────────────────────────────────────────
  final String  merchantId;
  final String  merchantName;
  // ── 社交账号 ────────────────────────────────────────────────────
  final String? telegram;
  final String? facebook;
  final String? email;

  const TechnicianModel({
    required this.id, required this.nickname, required this.techNo,
    required this.phone, this.avatar, required this.level,
    required this.rating, required this.completedOrders,
    required this.balance, required this.skills, required this.memberSince,
    this.merchantId = 'cambook', this.merchantName = 'CamBook',
    this.telegram, this.facebook, this.email,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> j) => TechnicianModel(
    id:             j['id'] as int?     ?? 0,
    nickname:       j['nickname'] as String? ?? '',
    techNo:         j['techNo']   as String? ?? '',
    phone:          j['phone']    as String? ?? '',
    avatar:         j['avatar']   as String?,
    level:          TechLevel.values.firstWhere(
                      (e) => e.name == j['level'],
                      orElse: () => TechLevel.normal),
    rating:         (j['rating']  as num?)?.toDouble() ?? 0.0,
    completedOrders:(j['completedOrders'] as num?)?.toInt() ?? 0,
    balance:        (j['balance'] as num?)?.toDouble() ?? 0.0,
    skills:         (j['skills'] as List?)
                        ?.map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
                        .toList() ?? [],
    memberSince:    j['memberSince'] as String? ?? '',
    merchantId:     j['merchantId']   as String? ?? 'cambook',
    merchantName:   j['merchantName'] as String? ?? 'CamBook',
    telegram:       j['telegram']  as String?,
    facebook:       j['facebook']  as String?,
    email:          j['email']     as String?,
  );

  TechnicianModel copyWith({
    int? id, String? nickname, String? techNo, String? phone,
    String? avatar, TechLevel? level, double? rating,
    int? completedOrders, double? balance,
    List<SkillModel>? skills, String? memberSince,
    String? merchantId, String? merchantName,
    String? telegram, String? facebook, String? email,
  }) => TechnicianModel(
    id:              id              ?? this.id,
    nickname:        nickname        ?? this.nickname,
    techNo:          techNo          ?? this.techNo,
    phone:           phone           ?? this.phone,
    avatar:          avatar          ?? this.avatar,
    level:           level           ?? this.level,
    rating:          rating          ?? this.rating,
    completedOrders: completedOrders ?? this.completedOrders,
    balance:         balance         ?? this.balance,
    skills:          skills          ?? this.skills,
    memberSince:     memberSince     ?? this.memberSince,
    merchantId:      merchantId      ?? this.merchantId,
    merchantName:    merchantName    ?? this.merchantName,
    telegram:        telegram        ?? this.telegram,
    facebook:        facebook        ?? this.facebook,
    email:           email           ?? this.email,
  );
}

class SkillModel {
  final int    id;
  final String name;
  bool enabled;

  SkillModel({required this.id, required this.name, required this.enabled});

  factory SkillModel.fromJson(Map<String, dynamic> j) =>
      SkillModel(id: j['id'], name: j['name'], enabled: j['enabled'] ?? true);
}

// ─────────────────────────────────────────────────────────────────────────────
// 订单模型
// ─────────────────────────────────────────────────────────────────────────────
enum OrderStatus { pending, accepted, inService, completed, cancelled }
enum ServiceMode { home, store }

class OrderModel {
  final int         id;
  final String      orderNo;
  final OrderStatus status;
  final ServiceMode serviceMode;
  /// 1 = 在线预约订单；2 = 门店散客订单（walkin session）
  final int         orderType;
  final CustomerModel customer;
  final List<ServiceItemModel> services;
  final double      totalAmount;
  final DateTime    appointTime;
  final DateTime    createTime;
  final double?     distance;
  final String?     remark;
  final DateTime?   startTime;
  final DateTime?   endTime;

  const OrderModel({
    required this.id, required this.orderNo, required this.status,
    required this.serviceMode, required this.customer, required this.services,
    required this.totalAmount, required this.appointTime, required this.createTime,
    this.orderType = 1, this.distance, this.remark, this.startTime, this.endTime,
  });

  bool get isWalkin => orderType == 2;

  /// 从后端 JSON 构建，时间字段均为 UTC 秒级时间戳。
  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:           j['id'] as int,
    orderNo:      j['orderNo'] as String? ?? '',
    status:       _parseStatus(j['status'] as int? ?? 0),
    serviceMode:  (j['serviceMode'] as int?) == 2 ? ServiceMode.store : ServiceMode.home,
    orderType:    j['orderType'] as int? ?? 1,
    customer:     j['member'] != null
                    ? CustomerModel.fromJson(j['member'] as Map<String, dynamic>)
                    : CustomerModel(id: 0, nickname: j['memberNickname'] as String? ?? '', phone: j['memberMobile'] as String? ?? ''),
    services:     j['orderItems'] != null
                    ? (j['orderItems'] as List).map((e) => ServiceItemModel.fromJson(e as Map<String, dynamic>)).toList()
                    : [],
    totalAmount:  (j['payAmount'] as num?)?.toDouble() ?? 0,
    appointTime:  DateUtil.fromEpochSec(j['appointTime']),
    createTime:   DateUtil.fromEpochSec(j['createTime']),
    distance:     (j['distance'] as num?)?.toDouble(),
    remark:       j['remark'] as String?,
    startTime:    DateUtil.fromEpochSecNullable(j['startTime']),
    endTime:      DateUtil.fromEpochSecNullable(j['endTime']),
  );

  /// 后端 10 态状态码 → 应用层枚举
  /// 0=待支付 1=待确认 2=已接单 3=前往中 4=已到达 5=服务中 6=已完成 7=已取消 8=退款中 9=已退款
  static OrderStatus _parseStatus(int s) => switch (s) {
    1              => OrderStatus.pending,
    2 || 3 || 4    => OrderStatus.accepted,   // 含"前往中"与"已到达"
    5              => OrderStatus.inService,
    6              => OrderStatus.completed,
    _              => OrderStatus.cancelled,  // 0, 7, 8, 9
  };

  int get totalDuration => services.fold(0, (s, e) => s + e.duration);

  OrderModel copyWith({OrderStatus? status, DateTime? startTime, DateTime? endTime}) =>
      OrderModel(
        id: id, orderNo: orderNo, status: status ?? this.status,
        serviceMode: serviceMode, orderType: orderType,
        customer: customer, services: services,
        totalAmount: totalAmount, appointTime: appointTime, createTime: createTime,
        distance: distance, remark: remark,
        startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
      );
}

class CustomerModel {
  final int    id;
  final String nickname;
  final String phone;
  final String? avatar;
  final String? address;

  const CustomerModel({
    required this.id, required this.nickname, required this.phone,
    this.avatar, this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
    id:       j['id'] as int? ?? 0,
    nickname: j['nickname'] as String? ?? '',
    phone:    j['mobile'] as String? ?? j['phone'] as String? ?? '',
    avatar:   j['avatar'] as String?,
    address:  j['addressDetail'] as String?,
  );
}

class ServiceItemModel {
  final int    id;
  final String name;
  final int    duration;
  final double price;

  const ServiceItemModel({
    required this.id, required this.name,
    required this.duration, required this.price,
  });

  factory ServiceItemModel.fromJson(Map<String, dynamic> j) => ServiceItemModel(
    id:       j['id'] as int? ?? j['serviceItemId'] as int? ?? 0,
    name:     j['serviceName'] as String? ?? j['name'] as String? ?? '',
    duration: j['serviceDuration'] as int? ?? j['duration'] as int? ?? 0,
    price:    (j['unitPrice'] as num?)?.toDouble() ?? (j['price'] as num?)?.toDouble() ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 收入模型
// ─────────────────────────────────────────────────────────────────────────────
enum IncomeType { order, bonus, deduction }

class IncomeRecordModel {
  final int       id;
  final String    orderNo;
  final double    amount;
  final DateTime  date;
  final IncomeType type;
  final String?   note;

  const IncomeRecordModel({
    required this.id, required this.orderNo, required this.amount,
    required this.date, required this.type, this.note,
  });

  factory IncomeRecordModel.fromJson(Map<String, dynamic> j) => IncomeRecordModel(
    id:      j['id'] as int? ?? 0,
    orderNo: j['orderNo'] as String? ?? '',
    amount:  (j['amount'] as num?)?.toDouble() ?? 0,
    date:    DateUtil.fromEpochSec(j['createTime'] ?? j['date']),
    type:    _parseType(j['type']),
    note:    j['note'] as String?,
  );

  static IncomeType _parseType(dynamic v) => switch (v?.toString()) {
    'bonus'     => IncomeType.bonus,
    'deduction' => IncomeType.deduction,
    _           => IncomeType.order,
  };
}

class IncomeTrendModel {
  final String label;
  final double amount;
  const IncomeTrendModel({required this.label, required this.amount});
}

// ─────────────────────────────────────────────────────────────────────────────
// 消息 / 聊天模型
// ─────────────────────────────────────────────────────────────────────────────
enum ConversationType { system, customer, order }
enum MessageType      { text, image, location, system }

class ConversationModel {
  final String           id;
  final ConversationType type;
  final String           name;
  final String?          avatar;
  final String           lastMessage;
  final DateTime         lastTime;
  final int              unread;
  final int?             customerId;
  final String?          phone;

  const ConversationModel({
    required this.id, required this.type, required this.name, this.avatar,
    required this.lastMessage, required this.lastTime,
    required this.unread, this.customerId, this.phone,
  });

  ConversationModel copyWithUnread(int u) => ConversationModel(
    id: id, type: type, name: name, avatar: avatar,
    lastMessage: lastMessage, lastTime: lastTime, unread: u,
    customerId: customerId, phone: phone,
  );
}

class ChatMessageModel {
  final String      id;
  final String      conversationId;
  final bool        isMe;
  final String      content;
  final MessageType type;
  final DateTime    time;
  final String?     imageUrl;

  const ChatMessageModel({
    required this.id, required this.conversationId, required this.isMe,
    required this.content, required this.type, required this.time, this.imageUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 排班 / 预约模型
// ─────────────────────────────────────────────────────────────────────────────
class AppointmentModel {
  final int          id;
  final String       orderNo;
  final String       customerName;
  final List<String> serviceNames;
  final DateTime     appointTime;
  final int          totalDuration;
  final String?      address;
  final ServiceMode  serviceMode;

  const AppointmentModel({
    required this.id, required this.orderNo, required this.customerName,
    required this.serviceNames, required this.appointTime,
    required this.totalDuration, this.address, required this.serviceMode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 评价模型
// ─────────────────────────────────────────────────────────────────────────────
class ReviewModel {
  final int          id;
  final String       customerName;
  final String?      customerAvatar;
  final double       rating;
  final String?      comment;
  final List<String> tags;
  final DateTime     date;

  const ReviewModel({
    required this.id, required this.customerName, this.customerAvatar,
    required this.rating, this.comment, required this.tags, required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id:             j['id'] as int? ?? 0,
    customerName:   j['memberNickname'] as String? ?? '',
    customerAvatar: j['memberAvatar'] as String?,
    rating:         (j['overallScore'] as num?)?.toDouble() ?? 0,
    comment:        j['comment'] as String?,
    tags:           (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    date:           DateUtil.fromEpochSec(j['createTime']),
  );
}
