class VerificationDocumentModel {
  const VerificationDocumentModel({
    required this.type,
    required this.name,
    this.url,
    this.status = 'pending',
    this.uploadedAt,
  });

  final String type; // 'id', 'police_check', 'qualification', 'photo'
  final String name;
  final String? url;
  final String status; // 'pending', 'under_review', 'verified', 'rejected'
  final DateTime? uploadedAt;

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    return VerificationDocumentModel(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'url': url,
        'status': status,
        'uploadedAt': uploadedAt?.toIso8601String(),
      };

  VerificationDocumentModel copyWith({
    String? type,
    String? name,
    String? url,
    String? status,
    DateTime? uploadedAt,
  }) {
    return VerificationDocumentModel(
      type: type ?? this.type,
      name: name ?? this.name,
      url: url ?? this.url,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class BabysitterModel {
  const BabysitterModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.address = '',
    this.bio = '',
    this.hourlyRate = 25.0,
    this.experienceYears = 2,
    this.skills = const [],
    this.languages = const ['English'],
    this.qualifications = const [],
    this.documents = const [],
    this.verificationStatus = 'verified',
    this.averageRating = 4.9,
    this.totalReviews = 18,
    this.totalCompletedBookings = 24,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? dateOfBirth;
  final String? gender;
  final String address;
  final String bio;
  final double hourlyRate;
  final int experienceYears;
  final List<String> skills;
  final List<String> languages;
  final List<String> qualifications;
  final List<VerificationDocumentModel> documents;
  final String verificationStatus; // 'pending', 'under_review', 'verified', 'rejected'
  final double averageRating;
  final int totalReviews;
  final int totalCompletedBookings;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVerified => verificationStatus == 'verified';

  factory BabysitterModel.fromJson(Map<String, dynamic> json) {
    var rawDocs = json['documents'];
    List<VerificationDocumentModel> docsList = [];
    if (rawDocs is List) {
      docsList = rawDocs
          .whereType<Map<String, dynamic>>()
          .map(VerificationDocumentModel.fromJson)
          .toList();
    }

    return BabysitterModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user'] is Map
          ? (json['user']['_id']?.toString() ?? '')
          : (json['user']?.toString() ?? json['userId']?.toString() ?? ''),
      name: json['user'] is Map && json['user']['name'] != null
          ? json['user']['name'].toString()
          : (json['name']?.toString() ?? 'Maya Johnson'),
      email: json['user'] is Map && json['user']['email'] != null
          ? json['user']['email'].toString()
          : (json['email']?.toString() ?? ''),
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString() ?? '',
      bio: json['bio']?.toString() ??
          'Passionate and caring babysitter with a decade of experience providing safe, nurturing, and engaging childcare.',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 25.0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 3,
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Infant Care', 'First Aid Certified', 'Toddler Care', 'Bedtime Routines'],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
          const ['English', 'Spanish'],
      qualifications: (json['qualifications'] as List?)?.map((e) => e.toString()).toList() ??
          const ['CPR & First Aid Certified', 'Early Childhood Education Diploma'],
      documents: docsList,
      verificationStatus: json['verificationStatus']?.toString() ?? 'verified',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 4.9,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 18,
      totalCompletedBookings:
          (json['totalCompletedBookings'] as num?)?.toInt() ?? 24,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'profileImage': profileImage,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'address': address,
        'bio': bio,
        'hourlyRate': hourlyRate,
        'experienceYears': experienceYears,
        'skills': skills,
        'languages': languages,
        'qualifications': qualifications,
        'documents': documents.map((e) => e.toJson()).toList(),
        'verificationStatus': verificationStatus,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'totalCompletedBookings': totalCompletedBookings,
        'isAvailable': isAvailable,
      };

  BabysitterModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? bio,
    double? hourlyRate,
    int? experienceYears,
    List<String>? skills,
    List<String>? languages,
    List<String>? qualifications,
    List<VerificationDocumentModel>? documents,
    String? verificationStatus,
    double? averageRating,
    int? totalReviews,
    int? totalCompletedBookings,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabysitterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experienceYears: experienceYears ?? this.experienceYears,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      documents: documents ?? this.documents,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalCompletedBookings:
          totalCompletedBookings ?? this.totalCompletedBookings,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
