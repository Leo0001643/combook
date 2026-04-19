import '../models/models.dart';

/// 全局 Mock 数据 —— 后期对接真实 API 时仅需替换 HttpUtil 调用即可
abstract class MockData {
  static final _now = DateTime.now();
  static DateTime _later(int h) => _now.add(Duration(hours: h));
  static DateTime _ago(int h) => _now.subtract(Duration(hours: h));
  static DateTime _dAgo(int d) => _now.subtract(Duration(days: d));

  // ── 当前技师 ────────────────────────────────────────────────────
  static final TechnicianModel technician = TechnicianModel(
    id: 1, nickname: 'Alex Zhang', techNo: 'T001234',
    phone: '+855 12 345 678', level: TechLevel.gold,
    rating: 4.9, completedOrders: 328, balance: 1860.50,
    memberSince: '2023-06-15',
    merchantId:   'cambook',
    merchantName: 'CamBook',
    telegram:  '@alexzhang_tech',
    facebook:  'facebook.com/alexzhang.tech',
    email:     'alex@example.com',
    skills: [
      SkillModel(id: 1, name: 'Swedish Massage', enabled: true),
      SkillModel(id: 2, name: 'Deep Tissue Massage', enabled: true),
      SkillModel(id: 3, name: 'Hot Stone Massage', enabled: true),
      SkillModel(id: 4, name: 'Foot Reflexology', enabled: true),
      SkillModel(id: 5, name: 'Aromatherapy', enabled: false),
      SkillModel(id: 6, name: 'Thai Massage', enabled: true),
    ],
  );

  // ── 客户 ────────────────────────────────────────────────────────
  static const _c1 = CustomerModel(id:1, nickname:'Sarah K.',   phone:'+855 17 111 222', address:'23 Norodom Blvd, Phnom Penh');
  static const _c2 = CustomerModel(id:2, nickname:'Mr. Park',   phone:'+82 10 9876 5432', address:'12 Riverside Rd, Room 305');
  static const _c3 = CustomerModel(id:3, nickname:'Nguyen Van A', phone:'+84 903 456 789', address:'45 Monivong Blvd, Suite 8');
  static const _c4 = CustomerModel(id:4, nickname:'Tanaka Y.',  phone:'+81 90 1234 5678', address:'Sofitel Hotel, Room 1204');
  static const _c5 = CustomerModel(id:5, nickname:'Kim Ji-hye', phone:'+82 10 5678 9012', address:'88 Russian Federation Blvd');

  // ── 服务项目 ─────────────────────────────────────────────────────
  static const _s1 = ServiceItemModel(id:1, name:'Swedish Massage',  duration:60, price:80);
  static const _s2 = ServiceItemModel(id:2, name:'Deep Tissue',      duration:90, price:120);
  static const _s3 = ServiceItemModel(id:3, name:'Foot Reflexology', duration:45, price:60);
  static const _s4 = ServiceItemModel(id:4, name:'Hot Stone',        duration:75, price:100);
  static const _s5 = ServiceItemModel(id:5, name:'Aromatherapy',     duration:60, price:90);

  // ── 订单 ─────────────────────────────────────────────────────────
  static List<OrderModel> get orders => [
    OrderModel(id:1, orderNo:'ORD202501001', status:OrderStatus.pending,
        serviceMode:ServiceMode.home, customer:_c1, services:[_s1],
        totalAmount:80, distance:1.8, appointTime:_later(1), createTime:_ago(1),
        remark:'Please bring extra towels'),
    OrderModel(id:2, orderNo:'ORD202501002', status:OrderStatus.pending,
        serviceMode:ServiceMode.store, customer:_c2, services:[_s2,_s3],
        totalAmount:180, appointTime:_later(2), createTime:_ago(0)),
    OrderModel(id:3, orderNo:'ORD202501003', status:OrderStatus.accepted,
        serviceMode:ServiceMode.home, customer:_c3, services:[_s4],
        totalAmount:100, distance:3.2, appointTime:_later(3), createTime:_ago(0)),
    OrderModel(id:4, orderNo:'ORD202501004', status:OrderStatus.accepted,
        serviceMode:ServiceMode.store, customer:_c4, services:[_s1,_s5],
        totalAmount:170, appointTime:_later(4), createTime:_ago(0)),
    OrderModel(id:5, orderNo:'ORD202501005', status:OrderStatus.inService,
        serviceMode:ServiceMode.home, customer:_c5, services:[_s2],
        totalAmount:120, distance:0.9, appointTime:_ago(1),
        createTime:_ago(2), startTime:_ago(1)),
    OrderModel(id:6, orderNo:'ORD202501006', status:OrderStatus.completed,
        serviceMode:ServiceMode.store, customer:_c1, services:[_s3],
        totalAmount:60, appointTime:_dAgo(1), createTime:_dAgo(1),
        startTime:_dAgo(1), endTime:_dAgo(1)),
    OrderModel(id:7, orderNo:'ORD202501007', status:OrderStatus.completed,
        serviceMode:ServiceMode.home, customer:_c2, services:[_s1,_s4],
        totalAmount:180, distance:2.1, appointTime:_dAgo(2), createTime:_dAgo(2),
        startTime:_dAgo(2), endTime:_dAgo(2)),
    OrderModel(id:8, orderNo:'ORD202501008', status:OrderStatus.cancelled,
        serviceMode:ServiceMode.store, customer:_c3, services:[_s2],
        totalAmount:120, appointTime:_dAgo(3), createTime:_dAgo(3)),
  ];

  // ── 收入记录 ─────────────────────────────────────────────────────
  static List<IncomeRecordModel> get incomeRecords {
    final amounts = [80.0,120.0,60.0,100.0,170.0,50.0,180.0,90.0];
    final types   = [IncomeType.order,IncomeType.order,IncomeType.order,IncomeType.bonus];
    return List.generate(20, (i) => IncomeRecordModel(
      id:i+1, orderNo:'ORD2025${(i+1).toString().padLeft(5,'0')}',
      amount:amounts[i % amounts.length], date:_dAgo(i ~/ 3),
      type:types[i % types.length],
    ));
  }

  // ── 收入趋势 ─────────────────────────────────────────────────────
  static List<IncomeTrendModel> get trend7 {
    final labels  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final amounts = [180.0,220.0,160.0,300.0,240.0,280.0,195.0];
    return List.generate(7, (i) => IncomeTrendModel(label:labels[i], amount:amounts[i]));
  }

  static List<IncomeTrendModel> get trend30 => List.generate(30, (i) =>
      IncomeTrendModel(label:'${i+1}', amount:150 + (i%7)*30.0 + (i%3)*20.0));

  // ── 会话列表 ─────────────────────────────────────────────────────
  static List<ConversationModel> get conversations => [
    ConversationModel(id:'sys_1', type:ConversationType.system, name:'System Notice',
        lastMessage:'Your account has been verified ✅', lastTime:_ago(2), unread:1),
    ConversationModel(id:'c_1', type:ConversationType.customer, name:'Sarah K.',
        lastMessage:'Are you on your way?', lastTime:_ago(0), unread:2, customerId:1, phone:'+855 12 345 678'),
    ConversationModel(id:'c_2', type:ConversationType.customer, name:'Mr. Park',
        lastMessage:'Thank you so much!', lastTime:_ago(3), unread:0, customerId:2, phone:'+82 10 1234 5678'),
    ConversationModel(id:'sys_2', type:ConversationType.order, name:'Order Reminder',
        lastMessage:'Order ORD202501003 starts in 1 hour', lastTime:_ago(1), unread:1),
    ConversationModel(id:'c_3', type:ConversationType.customer, name:'Nguyen Van A',
        lastMessage:'Can you arrive 10 min earlier?', lastTime:_now, unread:0, customerId:3, phone:'+84 98 765 4321'),
  ];

  // ── 聊天记录 ─────────────────────────────────────────────────────
  static Map<String, List<ChatMessageModel>> get chatMessages => {
    'c_1': [
      ChatMessageModel(id:'m1', conversationId:'c_1', isMe:false,
          content:'Hi, booking for tomorrow 2pm', type:MessageType.text, time:_ago(5)),
      ChatMessageModel(id:'m2', conversationId:'c_1', isMe:true,
          content:'Hello! I can see your booking, I will be there on time.',
          type:MessageType.text, time:_ago(5)),
      ChatMessageModel(id:'m3', conversationId:'c_1', isMe:false,
          content:'Great! Please bring extra towels.',
          type:MessageType.text, time:_ago(4)),
      ChatMessageModel(id:'m4', conversationId:'c_1', isMe:true,
          content:'No problem!', type:MessageType.text, time:_ago(4)),
      ChatMessageModel(id:'m5', conversationId:'c_1', isMe:false,
          content:'Are you on your way?', type:MessageType.text, time:_ago(0)),
    ],
    'c_2': [
      ChatMessageModel(id:'m1', conversationId:'c_2', isMe:false,
          content:'The deep tissue massage was amazing!', type:MessageType.text, time:_ago(4)),
      ChatMessageModel(id:'m2', conversationId:'c_2', isMe:true,
          content:'Glad you enjoyed it! See you next time.', type:MessageType.text, time:_ago(3)),
      ChatMessageModel(id:'m3', conversationId:'c_2', isMe:false,
          content:'Thank you so much!', type:MessageType.text, time:_ago(3)),
    ],
  };

  // ── 预约 ─────────────────────────────────────────────────────────
  static List<AppointmentModel> get appointments => [
    AppointmentModel(id:1, orderNo:'ORD202501003', customerName:'Nguyen Van A',
        serviceNames:['Hot Stone Massage'], appointTime:_later(3), totalDuration:75,
        address:'45 Monivong Blvd', serviceMode:ServiceMode.home),
    AppointmentModel(id:2, orderNo:'ORD202501004', customerName:'Tanaka Y.',
        serviceNames:['Swedish Massage','Aromatherapy'], appointTime:_later(6),
        totalDuration:120, serviceMode:ServiceMode.store),
    AppointmentModel(id:3, orderNo:'ORD202501009', customerName:'Kim Ji-hye',
        serviceNames:['Deep Tissue'], appointTime:_later(24), totalDuration:90,
        address:'88 Russian Blvd', serviceMode:ServiceMode.home),
  ];

  // ── 评价 ─────────────────────────────────────────────────────────
  static List<ReviewModel> get reviews => [
    ReviewModel(id:1, customerName:'Sarah K.', rating:5.0,
        comment:'Absolutely wonderful! Very professional.',
        tags:['Professional','Skilled','Punctual'], date:_dAgo(1)),
    ReviewModel(id:2, customerName:'Mr. Park', rating:4.5,
        comment:'Great deep tissue massage, will book again.',
        tags:['Skilled','Friendly'], date:_dAgo(3)),
    ReviewModel(id:3, customerName:'Nguyen Van A', rating:5.0,
        comment:'Best massage in Phnom Penh.',
        tags:['Best Technique','Professional'], date:_dAgo(7)),
    ReviewModel(id:4, customerName:'Tanaka Y.', rating:4.0,
        tags:['Friendly','On Time'], date:_dAgo(10)),
    ReviewModel(id:5, customerName:'Kim Ji-hye', rating:5.0,
        comment:'Extremely relaxing. Highly recommended!',
        tags:['Relaxing','Professional'], date:_dAgo(14)),
  ];
}
