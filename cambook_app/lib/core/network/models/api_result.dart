/// 与后端 Result<T> 对应的响应包装模型
class ApiResult<T> {
  final int code;
  final String message;
  final T? data;
  final int? timestamp;

  const ApiResult({
    required this.code,
    required this.message,
    this.data,
    this.timestamp,
  });

  bool get isSuccess => code == 200;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResult<T>(
      code:      json['code'] as int? ?? -1,
      message:   json['message'] as String? ?? '',
      data:      json['data'] != null && fromJsonT != null
                     ? fromJsonT(json['data'])
                     : json['data'] as T?,
      timestamp: json['timestamp'] as int?,
    );
  }
}
