class VerificationDocumentModel {
  const VerificationDocumentModel({
    this.id,
    required this.type,
    required this.name,
    this.label,
    this.documentNumber,
    this.url,
    this.fileUrl,
    this.status = 'pending',
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.uploadedAt,
    this.updatedAt,
  });

  final String? id;
  final String type; // 'id', 'police_check', 'qualification', 'photo', 'certificate', 'other'
  final String name;
  final String? label;
  final String? documentNumber;
  final String? url;
  final String? fileUrl;
  final String status; // 'pending', 'under_review', 'verified', 'rejected', 'changes_requested'
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? uploadedAt;
  final DateTime? updatedAt;

  String get displayName => (label != null && label!.trim().isNotEmpty) ? label! : (name.isNotEmpty ? name : 'Document');
  String get effectiveUrl => (fileUrl != null && fileUrl!.trim().isNotEmpty) ? fileUrl! : (url ?? '');
  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get hasChangesRequested => status.toLowerCase() == 'changes_requested';

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    return VerificationDocumentModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? json['label']?.toString() ?? '',
      label: json['label']?.toString(),
      documentNumber: json['documentNumber']?.toString(),
      url: json['url']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      reviewNotes: json['reviewNotes']?.toString() ?? json['rejectionReason']?.toString(),
      reviewedBy: json['reviewedBy']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'type': type,
        'name': name,
        if (label != null) 'label': label,
        if (documentNumber != null) 'documentNumber': documentNumber,
        'url': effectiveUrl,
        if (fileUrl != null) 'fileUrl': fileUrl,
        'status': status,
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
        'uploadedAt': uploadedAt?.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  VerificationDocumentModel copyWith({
    String? id,
    String? type,
    String? name,
    String? label,
    String? documentNumber,
    String? url,
    String? fileUrl,
    String? status,
    String? reviewNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? uploadedAt,
    DateTime? updatedAt,
  }) {
    return VerificationDocumentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      label: label ?? this.label,
      documentNumber: documentNumber ?? this.documentNumber,
      url: url ?? this.url,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QualificationItemModel {
  const QualificationItemModel({
    required this.id,
    required this.title,
    this.institution,
    this.certificateUrl,
    this.status = 'pending',
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String title;
  final String? institution;
  final String? certificateUrl;
  final String status; // 'pending', 'under_review', 'verified', 'rejected', 'changes_requested'
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get hasChangesRequested => status.toLowerCase() == 'changes_requested';

  factory QualificationItemModel.fromJson(dynamic data) {
    if (data is String) {
      return QualificationItemModel(
        id: data,
        title: data,
        status: 'pending',
      );
    }
    if (data is Map) {
      return QualificationItemModel(
        id: data['_id']?.toString() ?? data['id']?.toString() ?? data['title']?.toString() ?? '',
        title: data['title']?.toString() ?? data['name']?.toString() ?? '',
        institution: data['institution']?.toString(),
        certificateUrl: data['certificateUrl']?.toString() ?? data['url']?.toString(),
        status: data['status']?.toString() ?? 'pending',
        reviewNotes: data['reviewNotes']?.toString() ?? data['rejectionReason']?.toString(),
        reviewedBy: data['reviewedBy']?.toString(),
        reviewedAt: data['reviewedAt'] != null
            ? DateTime.tryParse(data['reviewedAt'].toString())
            : null,
      );
    }
    return QualificationItemModel(id: '', title: data.toString());
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'title': title,
        if (institution != null) 'institution': institution,
        if (certificateUrl != null) 'certificateUrl': certificateUrl,
        'status': status,
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      };
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
    this.experienceYears = 0,
    this.skills = const [],
    this.languages = const ['English'],
    this.qualifications = const [],
    this.qualificationItems = const [],
    this.documents = const [],
    this.verificationStatus = 'pending',
    this.verificationNotes = '',
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalCompletedBookings = 0,
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
  final List<QualificationItemModel> qualificationItems;
  final List<VerificationDocumentModel> documents;
  final String verificationStatus; // 'pending', 'under_review', 'verified', 'rejected', 'changes_requested'
  final String verificationNotes;
  final double averageRating;
  final int totalReviews;
  final int totalCompletedBookings;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending' || verificationStatus == 'under_review';
  bool get hasChangesRequested => verificationStatus == 'changes_requested';
  bool get isRejected => verificationStatus == 'rejected';

  factory BabysitterModel.fromJson(Map<String, dynamic> json) {
    var rawDocs = json['documents'];
    List<VerificationDocumentModel> docsList = [];
    if (rawDocs is List) {
      for (final item in rawDocs) {
        if (item is Map) {
          docsList.add(
            VerificationDocumentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    var rawQuals = json['qualifications'];
    List<QualificationItemModel> qualItemList = [];
    List<String> qualNamesList = [];
    if (rawQuals is List) {
      for (final item in rawQuals) {
        if (item is Map) {
          final q = QualificationItemModel.fromJson(Map<String, dynamic>.from(item));
          qualItemList.add(q);
          qualNamesList.add(q.title.isNotEmpty ? q.title : 'Qualification');
        } else if (item != null) {
          final str = item.toString();
          qualItemList.add(QualificationItemModel(id: str, title: str));
          qualNamesList.add(str);
        }
      }
    }

    return BabysitterModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user'] is Map
          ? (json['user']['_id']?.toString() ?? '')
          : (json['user']?.toString() ?? json['userId']?.toString() ?? ''),
      name: json['user'] is Map && json['user']['name'] != null
          ? json['user']['name'].toString()
          : (json['name']?.toString() ?? ''),
      email: json['user'] is Map && json['user']['email'] != null
          ? json['user']['email'].toString()
          : (json['email']?.toString() ?? ''),
      phone: (json['phone'] != null && json['phone'].toString().isNotEmpty)
          ? json['phone'].toString()
          : (json['user'] is Map && json['user']['phone'] != null
              ? json['user']['phone'].toString()
              : ''),
      profileImage: json['profileImage']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 25.0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
          const ['English'],
      qualifications: qualNamesList,
      qualificationItems: qualItemList,
      documents: docsList,
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      verificationNotes: json['verificationNotes']?.toString() ??
          json['reviewNotes']?.toString() ??
          '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      totalCompletedBookings:
          (json['totalCompletedBookings'] as num?)?.toInt() ?? 0,
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
        'qualifications': qualificationItems.isNotEmpty
            ? qualificationItems.map((e) => e.toJson()).toList()
            : qualifications,
        'documents': documents.map((e) => e.toJson()).toList(),
        'verificationStatus': verificationStatus,
        'verificationNotes': verificationNotes,
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
    List<QualificationItemModel>? qualificationItems,
    List<VerificationDocumentModel>? documents,
    String? verificationStatus,
    String? verificationNotes,
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
      qualificationItems: qualificationItems ?? this.qualificationItems,
      documents: documents ?? this.documents,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNotes: verificationNotes ?? this.verificationNotes,
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
