class ParentModel {
  const ParentModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.emergencyContact = '',
    this.children = const [],
    this.isNicVerified = false,
  });

  final String userId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String emergencyContact;
  final List<Map<String, dynamic>> children;
  final bool isNicVerified;

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    return ParentModel(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Parent',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      children: rawChildren is List
          ? rawChildren
                .whereType<Map>()
                .map((child) => Map<String, dynamic>.from(child))
                .toList()
          : const [],
      isNicVerified: json['isNicVerified'] == true,
    );
  }
}
