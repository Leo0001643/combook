/// 登录响应数据（对应后端 LoginVO）
class LoginVo {
  final int userId;
  final String? nickname;
  final String? avatar;
  final int userType;     // 1=会员 2=技师 3=商户
  final String? phone;
  final String? language;
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpire; // 秒

  const LoginVo({
    required this.userId,
    this.nickname,
    this.avatar,
    required this.userType,
    this.phone,
    this.language,
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpire = 7200,
  });

  factory LoginVo.fromJson(Map<String, dynamic> json) {
    return LoginVo(
      userId:            (json['userId'] as num).toInt(),
      nickname:          json['nickname'] as String?,
      avatar:            json['avatar'] as String?,
      userType:          (json['userType'] as num?)?.toInt() ?? 1,
      phone:             json['phone'] as String?,
      language:          json['language'] as String?,
      accessToken:       json['accessToken'] as String? ?? '',
      refreshToken:      json['refreshToken'] as String? ?? '',
      accessTokenExpire: (json['accessTokenExpire'] as num?)?.toInt() ?? 7200,
    );
  }
}
