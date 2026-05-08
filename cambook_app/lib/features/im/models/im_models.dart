// IM 数据模型
// 与后端 ImConversationVO / ImMessageVO 字段一一对应。

// ── 会话 ───────────────────────────────────────────────────────────────────

class ImConversation {
  final int    conversationId;
  final int    convType;          // 1=单聊 2=群聊
  final String? peerType;
  final int?    peerId;
  final String? peerName;
  final String? peerAvatar;
  final String? lastMsgPreview;
  final int?    lastMsgTime;      // Unix 秒
  final int     unreadCount;

  const ImConversation({
    required this.conversationId,
    required this.convType,
    this.peerType,
    this.peerId,
    this.peerName,
    this.peerAvatar,
    this.lastMsgPreview,
    this.lastMsgTime,
    this.unreadCount = 0,
  });

  factory ImConversation.fromJson(Map<String, dynamic> j) => ImConversation(
    conversationId: j['conversationId'] as int,
    convType:       j['convType']       as int? ?? 1,
    peerType:       j['peerType']       as String?,
    peerId:         j['peerId']         as int?,
    peerName:       j['peerName']       as String?,
    peerAvatar:     j['peerAvatar']     as String?,
    lastMsgPreview: j['lastMsgPreview'] as String?,
    lastMsgTime:    j['lastMsgTime']    as int?,
    unreadCount:    j['unreadCount']    as int? ?? 0,
  );

  ImConversation copyWith({
    String? lastMsgPreview,
    int?    lastMsgTime,
    int?    unreadCount,
    String? peerName,
  }) => ImConversation(
    conversationId: conversationId,
    convType:       convType,
    peerType:       peerType,
    peerId:         peerId,
    peerName:       peerName   ?? this.peerName,
    peerAvatar:     peerAvatar,
    lastMsgPreview: lastMsgPreview ?? this.lastMsgPreview,
    lastMsgTime:    lastMsgTime    ?? this.lastMsgTime,
    unreadCount:    unreadCount    ?? this.unreadCount,
  );
}

// ── 消息 ───────────────────────────────────────────────────────────────────

class ImMessage {
  final int    msgId;
  final int    conversationId;
  final String senderType;
  final int    senderId;
  final int    isGroup;
  final int?   groupId;
  final int    msgType;   // 1=文本 2=图片 3=语音 4=视频 5=文件 6=系统
  final String content;
  final int    status;    // 1=已发 2=已送达 3=已读
  final int    createTime;// Unix 秒

  // 客户端临时字段（乐观更新用）
  final bool   isOptimistic;

  const ImMessage({
    required this.msgId,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.isGroup,
    this.groupId,
    required this.msgType,
    required this.content,
    required this.status,
    required this.createTime,
    this.isOptimistic = false,
  });

  factory ImMessage.fromJson(Map<String, dynamic> j) => ImMessage(
    msgId:          j['msgId']          as int,
    conversationId: j['conversationId'] as int,
    senderType:     j['senderType']     as String,
    senderId:       j['senderId']       as int,
    isGroup:        j['isGroup']        as int? ?? 0,
    groupId:        j['groupId']        as int?,
    msgType:        j['msgType']        as int? ?? 1,
    content:        j['content']        as String? ?? '',
    status:         j['status']         as int? ?? 1,
    createTime:     j['createTime']     as int,
  );

  ImMessage copyWith({int? status}) => ImMessage(
    msgId:          msgId,
    conversationId: conversationId,
    senderType:     senderType,
    senderId:       senderId,
    isGroup:        isGroup,
    groupId:        groupId,
    msgType:        msgType,
    content:        content,
    status:         status ?? this.status,
    createTime:     createTime,
    isOptimistic:   isOptimistic,
  );

  bool get isImage => msgType == 2;
  bool get isVoice => msgType == 3;
  bool get isVideo => msgType == 4;
  bool get isSystem => msgType == 6;

  /// 语音消息 content 格式："url|duration" 或纯 url
  String get voiceUrl   => isVoice && content.contains('|') ? content.split('|')[0] : content;
  int    get voiceDurSec => isVoice && content.contains('|') ? int.tryParse(content.split('|')[1]) ?? 0 : 0;
}

// ── 通话状态 ────────────────────────────────────────────────────────────────

enum CallState { idle, calling, incoming, connecting, active, ended }

class CallSignal {
  final String callId;
  final String targetType;
  final int    targetId;
  final String fromType;
  final int    fromId;
  final String? fromName;
  final String? sdp;
  final String? sdpType;    // 'offer' | 'answer'
  final String? candidate;  // JSON ICE candidate

  const CallSignal({
    required this.callId,
    required this.targetType,
    required this.targetId,
    required this.fromType,
    required this.fromId,
    this.fromName,
    this.sdp,
    this.sdpType,
    this.candidate,
  });

  factory CallSignal.fromJson(Map<String, dynamic> j) => CallSignal(
    callId:     j['callId']     as String,
    targetType: j['targetType'] as String,
    targetId:   j['targetId']   as int,
    fromType:   j['fromType']   as String,
    fromId:     j['fromId']     as int,
    fromName:   j['fromName']   as String?,
    sdp:        j['sdp']        as String?,
    sdpType:    j['sdpType']    as String?,
    candidate:  j['candidate']  as String?,
  );

  Map<String, dynamic> toJson() => {
    'callId':     callId,
    'targetType': targetType,
    'targetId':   targetId,
    'fromType':   fromType,
    'fromId':     fromId,
    if (fromName  != null) 'fromName':  fromName,
    if (sdp       != null) 'sdp':       sdp,
    if (sdpType   != null) 'sdpType':   sdpType,
    if (candidate != null) 'candidate': candidate,
  };
}
