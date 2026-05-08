import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/im_models.dart';

/// IM HTTP API — 所有接口调用集中于此，业务层不直接使用 Dio
class ImApi {
  ImApi._();

  static Dio get _dio => ApiClient.instance;

  // ── 会话 ──────────────────────────────────────────────────────────────────

  static Future<List<ImConversation>> conversations() async {
    final r = await _dio.get('/chat/conversations');
    final list = _data(r) as List? ?? [];
    return list.map((e) => ImConversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── 消息 ──────────────────────────────────────────────────────────────────

  static Future<List<ImMessage>> history(int convId, {int? beforeMsgId, int limit = 30}) async {
    final r = await _dio.get('/chat/messages', queryParameters: {
      'conversationId': convId,
      if (beforeMsgId != null) 'beforeMsgId': beforeMsgId,
      'limit': limit,
    });
    final list = _data(r) as List? ?? [];
    // 后端返回倒序，翻转为正序
    return list.reversed.map((e) => ImMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 发送消息，返回服务端 msgId
  static Future<int> sendMessage({
    required String receiverType,
    required int    receiverId,
    required int    msgType,
    required String content,
    String? clientMsgId,
  }) async {
    final r = await _dio.post('/chat/messages', data: {
      'receiverType': receiverType,
      'receiverId':   receiverId,
      'msgType':      msgType,
      'content':      content,
      if (clientMsgId != null) 'clientMsgId': clientMsgId,
    });
    return (_data(r) as num).toInt();
  }

  // ── 媒体上传 ──────────────────────────────────────────────────────────────

  static Future<String> uploadImage(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    final r = await _dio.post('/chat/media/image', data: form);
    return (_data(r) as Map)['fileUrl'] as String;
  }

  static Future<String> uploadVoice(String filePath, {String filename = 'voice.aac'}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final r = await _dio.post('/chat/media/voice', data: form);
    return (_data(r) as Map)['fileUrl'] as String;
  }

  static Future<String> uploadVideo(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    final r = await _dio.post('/chat/media/video', data: form);
    return (_data(r) as Map)['fileUrl'] as String;
  }

  // ── 私有 ──────────────────────────────────────────────────────────────────

  static dynamic _data(Response r) {
    final body = r.data;
    if (body is Map) return body['data'];
    return null;
  }
}
