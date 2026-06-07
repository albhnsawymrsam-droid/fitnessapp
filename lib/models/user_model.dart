class UserModel {
  final int userId;
  final String fullname;
  final String email;
  final String role;
  final bool banned;
  final String? createdAt;
  final String? token;

  UserModel({
    required this.userId,
    required this.fullname,
    required this.email,
    required this.role,
    required this.banned,
    this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      banned: json['banned'] ?? false,
      createdAt: json['created_at'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'fullname': fullname,
        'email': email,
        'role': role,
        'banned': banned,
        if (createdAt != null) 'created_at': createdAt,
        if (token != null) 'token': token,
      };
}
