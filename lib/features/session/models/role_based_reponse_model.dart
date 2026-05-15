// lib/models/role_based_response_model.dart

class RoleBasedResponseModel {
  final bool success;
  final String token;
  final int expiresAt;
  final String channelName;

  RoleBasedResponseModel({
    required this.success,
    required this.token,
    required this.expiresAt,
    required this.channelName,
  });

  factory RoleBasedResponseModel.fromJson(Map<String, dynamic> json) {
    return RoleBasedResponseModel(
      success: json['success'] ?? false,
      token: json['token'] ?? '',
      expiresAt: json['expiresAt'] ?? 0,
      channelName: json['channelName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "token": token,
      "expiresAt": expiresAt,
      "channelName": channelName,
    };
  }
}