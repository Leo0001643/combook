import '../config/app_config.dart';
import '../i18n/l10n_ext.dart';
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
    // Backend `/tech/auth/me` returns `techId`; local cache (`toJson`) uses `id`.
    // Accept both so warm-start (cache) and login response both populate id.
    id:              JsonUtil.intFrom(j['techId'] ?? j['id']),
    nickname:        JsonUtil.strFrom(j['nickname']),
    techNo:          JsonUtil.strFrom(j['techNo']),
    phone:           JsonUtil.strFrom(j['phone']),
    avatar:          j['avatar']?.toString(),
    level:           TechLevel.values.firstWhere(
                       (e) => e.name == j['level'],
                       orElse: () => TechLevel.normal),
    rating:          JsonUtil.dblFrom(j['rating']),
    completedOrders: JsonUtil.intFrom(j['completedOrders']),
    balance:         JsonUtil.dblFrom(j['balance']),
    skills:          (j['skills'] as List?)
                         ?.map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
                         .toList() ?? [],
    memberSince:     JsonUtil.strFrom(j['memberSince']),
    // merchantId 后端可能返回 int 或 String，统一安全转换
    merchantId:      j['merchantId'] != null
                         ? j['merchantId'].toString()
                         : 'cambook',
    merchantName:    JsonUtil.strFrom(j['merchantName']),
    telegram:        j['telegram']?.toString(),
    facebook:        j['facebook']?.toString(),
    email:           j['email']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id':              id,
    'nickname':        nickname,
    'techNo':          techNo,
    'phone':           phone,
    if (avatar      != null) 'avatar':      avatar,
    'level':           level.name,
    'rating':          rating,
    'completedOrders': completedOrders,
    'balance':         balance,
    'skills':          skills.map((s) => s.toJson()).toList(),
    'memberSince':     memberSince,
    'merchantId':      merchantId,
    'merchantName':    merchantName,
    if (telegram    != null) 'telegram':    telegram,
    if (facebook    != null) 'facebook':    facebook,
    if (email       != null) 'email':       email,
  };

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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'enabled': enabled};
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
// IM 通讯录联系人（运营 / 营销人员）
// ─────────────────────────────────────────────────────────────────────────────
class ImContactModel {
  final String  id;
  final String  name;
  final String? avatar;
  final String  role;   // e.g. "customer_service" / "marketing"
  final String? userType;
  const ImContactModel({
    required this.id, required this.name, this.avatar,
    required this.role, this.userType,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 消息 / 聊天模型
// ─────────────────────────────────────────────────────────────────────────────
enum ConversationType { system, customer, order }
// msgType 1=文本 2=图片 3=语音 4=视频
enum MessageType { text, image, voice, video, location, system }

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
  // 后端字段（peerType 用于发送消息时指定 receiverType）
  final String?          peerType;
  final int?             peerId;

  const ConversationModel({
    required this.id, required this.type, required this.name, this.avatar,
    required this.lastMessage, required this.lastTime,
    required this.unread, this.customerId, this.phone,
    this.peerType, this.peerId,
  });

  factory ConversationModel.fromImJson(Map<String, dynamic> j) {
    // Null-safe name: peer nickname → group name → localised fallback
    final peerName = (j['peerNickname'] as String?)
        ?? (j['groupName']   as String?)
        ?? _safeName();

    final rawTime = j['lastMsgTime'];
    return ConversationModel(
      id:          '${j['conversationId']}',
      type:        ConversationType.customer,
      name:        peerName,
      avatar:      (j['peerAvatar'] as String?) ?? (j['groupAvatar'] as String?),
      lastMessage: j['lastMsgPreview'] as String? ?? '',
      lastTime:    rawTime != null
          ? DateTime.fromMillisecondsSinceEpoch(JsonUtil.intFrom(rawTime) * 1000)
          : DateTime.now(),
      unread:      JsonUtil.intFrom(j['unreadCount']),
      peerType:    j['peerType']  as String?,
      peerId:      j['peerId']    != null ? JsonUtil.intFrom(j['peerId']) : null,
    );
  }

  static String _safeName() {
    try { return gL10n.imUnknownUser; } catch (_) { return 'Unknown'; }
  }

  ConversationModel copyWith({
    int?      unread,
    String?   lastMessage,
    DateTime? lastTime,
  }) => ConversationModel(
    id: id, type: type, name: name, avatar: avatar,
    lastMessage: lastMessage ?? this.lastMessage,
    lastTime:    lastTime    ?? this.lastTime,
    unread:      unread      ?? this.unread,
    customerId:  customerId, phone: phone,
    peerType:    peerType, peerId: peerId,
  );

  // kept for callers that haven't migrated yet
  ConversationModel copyWithUnread(int u) => copyWith(unread: u);
  ConversationModel copyWithLastMsg(String msg, DateTime t) =>
      copyWith(lastMessage: msg, lastTime: t);
}

class ChatMessageModel {
  final String      id;
  final String      conversationId;
  final bool        isMe;
  final String      content;   // 文本内容 / 图片URL / 语音"url|秒数" / 系统通知
  final MessageType type;
  final DateTime    time;
  final int         status;    // 1=已发 2=已送达 3=已读
  // 语音专用
  final int?        voiceDurSec;
  final String?     voiceUrl;

  const ChatMessageModel({
    required this.id, required this.conversationId, required this.isMe,
    required this.content, required this.type, required this.time,
    this.status = 1, this.voiceDurSec, this.voiceUrl,
  });

  factory ChatMessageModel.fromImJson(Map<String, dynamic> j, {
    required String myType, required int myId,
  }) {
    final senderType = j['senderType'] as String? ?? '';
    // senderId may arrive as int or String from different serialisers
    final senderId   = JsonUtil.intFrom(j['senderId'] ?? 0);
    final isMe       = senderType == myType && senderId == myId;
    final msgType    = j['msgType'] as int? ?? 1;
    final content    = j['content'] as String? ?? '';
    final convId     = '${j['conversationId']}';

    String? voiceUrl; int? voiceDur;
    if (msgType == 3 && content.contains('|')) {
      final parts = content.split('|');
      voiceUrl = _fixMediaUrl(parts[0]);
      voiceDur = int.tryParse(parts[1]);
    }

    // Rewrite localhost URLs in image content so they load on real devices
    final fixedContent = (msgType == 2) ? _fixMediaUrl(content) : content;

    return ChatMessageModel(
      // Null/missing msgId falls back to a timestamp-based local ID
      id:             j['msgId'] != null ? '${j['msgId']}' : '${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      isMe:           isMe,
      content:        fixedContent,
      type:           _mapType(msgType),
      time:           DateTime.fromMillisecondsSinceEpoch(
                          JsonUtil.intFrom(j['createTime']) * 1000),
      status:         JsonUtil.intFrom(j['status'] ?? 1),
      voiceUrl:       voiceUrl,
      voiceDurSec:    voiceDur,
    );
  }

  /// Rewrites media URLs stored as `http://localhost:port/…` to use the
  /// actual API server host so they are reachable from real devices on LAN.
  static String _fixMediaUrl(String url) {
    if (!url.startsWith('http://localhost') &&
        !url.startsWith('http://127.0.0.1')) return url;
    try {
      final server  = Uri.parse(AppConfig.apiBaseUrl);
      final media   = Uri.parse(url);
      return media
          .replace(scheme: server.scheme, host: server.host, port: server.port)
          .toString();
    } catch (_) {
      return url;
    }
  }

  static MessageType _mapType(int t) => switch (t) {
    2 => MessageType.image,
    3 => MessageType.voice,
    4 => MessageType.video,
    5 => MessageType.location,
    6 => MessageType.system,
    _ => MessageType.text,
  };

  /// Localized preview text. Falls back to English tags when context unavailable.
  String get preview {
    try {
      final l = gL10n;
      return switch (type) {
        MessageType.image    => l.imImagePreview,
        MessageType.voice    => l.imVoicePreview,
        MessageType.video    => l.imVideoPreview,
        MessageType.location => l.imLocationPreview,
        MessageType.system   => l.imSystemPreview,
        _                    => content,
      };
    } catch (_) {
      return switch (type) {
        MessageType.image    => '[Image]',
        MessageType.voice    => '[Voice]',
        MessageType.video    => '[Video]',
          MessageType.location => '[📍 Location]',
        MessageType.system   => '[Notice]',
        _                    => content,
      };
    }
  }
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
