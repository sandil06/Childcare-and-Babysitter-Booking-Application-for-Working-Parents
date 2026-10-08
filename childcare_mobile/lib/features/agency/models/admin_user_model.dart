class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String accountStatus;
  final bool isActive;
  final String? suspensionReason;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final String avatar;
  final int totalBookings;
  final int openReports;
  final double averageRating;
  final String verificationStatus;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.accountStatus = 'active',
    this.isActive = true,
    this.suspensionReason,
    this.isEmailVerified = true,
    this.createdAt,
    this.avatar = '',
    this.totalBookings = 0,
    this.openReports = 0,
    this.averageRating = 5.0,
    this.verificationStatus = 'pending',
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'parent',
      accountStatus: json['accountStatus']?.toString() ??
          (json['isActive'] == false ? 'suspended' : 'active'),
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['accountStatus'] != 'suspended' && json['accountStatus'] != 'disabled'),
      suspensionReason: json['suspensionReason']?.toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      avatar: json['avatar']?.toString() ?? json['profileImage']?.toString() ?? '',
      totalBookings: int.tryParse(json['totalBookings']?.toString() ?? '0') ?? 0,
      openReports: int.tryParse(json['openReports']?.toString() ?? '0') ?? 0,
      averageRating: double.tryParse(json['averageRating']?.toString() ?? '5.0') ?? 5.0,
      verificationStatus: json['verificationStatus']?.toString() ??
          (json['babysitterProfile'] is Map
              ? json['babysitterProfile']['verificationStatus']?.toString()
              : (json['isVerified'] == true ? 'verified' : 'pending')) ??
          'pending',
    );
  }

  bool get isSuspended => accountStatus == 'suspended' || !isActive;
  bool get isVerified => verificationStatus == 'verified';
  bool get isParent => role.toLowerCase() == 'parent';
  bool get isBabysitter => role.toLowerCase() == 'babysitter';
  bool get isAgency => role.toLowerCase() == 'agency' || role.toLowerCase() == 'admin';

  String get displayRole {
    switch (role.toLowerCase()) {
      case 'parent':
        return 'Parent';
      case 'babysitter':
        return 'Babysitter';
      case 'agency':
        return 'Agency Admin';
      case 'admin':
        return 'Super Admin';
      default:
        return role;
    }
  }
}
