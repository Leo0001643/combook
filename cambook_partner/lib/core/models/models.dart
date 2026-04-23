import '../utils/date_util.dart';

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
    id: j['id'], nickname: j['nickname'], techNo: j['techNo'],
    phone: j['phone'], avatar: j['avatar'],
    level: TechLevel.values.firstWhere((e) => e.name == j['level'], orElse: () => TechLevel.normal),
    rating: (j['rating'] as num).toDouble(),
    completedOrders: j['completedOrders'],
    balance: (j['balance'] as num).toDouble(),
    skills: (j['skills'] as List).map((e) => SkillModel.fromJson(e)).toList(),
    memberSince: j['memberSince'],
    merchantId:   j['merchantId']   ?? 'cambook',
    merchantName: j['merchantName'] ?? 'CamBook',
    telegram:     j['telegram'],
    facebook:     j['facebook'],
    email:        j['email'],
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
    this.distance, this.remark, this.startTime, this.endTime,
  });

  /// 从后端 JSON 构建，时间字段均为 UTC 秒级时间戳。
  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:           j['id'] as int,
    orderNo:      j['orderNo'] as String,
    status:       _parseStatus(j['status'] as int? ?? 0),
    serviceMode:  (j['serviceMode'] as int?) == 2 ? ServiceMode.store : ServiceMode.home,
    customer:     j['member'] != null
                    ? CustomerModel.fromJson(j['member'] as Map<String, dynamic>)
                    : CustomerModel(id: 0, nickname: j['memberNickname'] ?? '', phone: ''),
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

  static OrderStatus _parseStatus(int s) => switch (s) {
    1     => OrderStatus.pending,
    2 || 3 => OrderStatus.accepted,
    4 || 5 => OrderStatus.inService,
    6     => OrderStatus.completed,
    _     => OrderStatus.cancelled,
  };

  int get totalDuration => services.fold(0, (s, e) => s + e.duration);

  OrderModel copyWith({OrderStatus? status, DateTime? startTime, DateTime? endTime}) =>
      OrderModel(
        id: id, orderNo: orderNo, status: status ?? this.status,
        serviceMode: serviceMode, customer: customer, services: services,
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
    type:    IncomeType.order,
    note:    j['note'] as String?,
  );
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
