import 'package:flutter/material.dart';

class VerificationDocItem {
  final String? id;
  final String type;
  final String name;
  final String? label;
  final String? documentNumber;
  final String url;
  final String? fileUrl;
  final String status;
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? uploadedAt;

  const VerificationDocItem({
    this.id,
    required this.type,
    required this.name,
    this.label,
    this.documentNumber,
    required this.url,
    this.fileUrl,
    this.status = 'pending',
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.uploadedAt,
  });

  String get displayName => (label != null && label!.trim().isNotEmpty) ? label! : (name.isNotEmpty ? name : 'Document');
  String get effectiveUrl => (fileUrl != null && fileUrl!.trim().isNotEmpty) ? fileUrl! : url;
  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isChangesRequested => status.toLowerCase() == 'changes_requested';

  factory VerificationDocItem.fromJson(Map<String, dynamic> json) {
    final fileUrl = json['fileUrl']?.toString();
    final url = json['url']?.toString() ?? fileUrl ?? '';
    final label = json['label']?.toString();
    final name = json['name']?.toString() ?? label ?? 'Document';

    return VerificationDocItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      type: json['type']?.toString() ?? 'other',
      name: name,
      label: label,
      documentNumber: json['documentNumber']?.toString(),
      url: url,
      fileUrl: fileUrl,
      status: json['status']?.toString() ?? 'pending',
      reviewNotes: json['reviewNotes']?.toString() ?? json['rejectionReason']?.toString(),
      reviewedBy: json['reviewedBy']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
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
        if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      };

  IconData get iconData {
    switch (type.toLowerCase()) {
      case 'id':
        return Icons.badge_outlined;
      case 'police_check':
        return Icons.local_police_outlined;
      case 'qualification':
      case 'certificate':
        return Icons.school_outlined;
      case 'photo':
        return Icons.portrait_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String get displayType {
    switch (type.toLowerCase()) {
      case 'id':
        return 'National ID / Passport';
      case 'police_check':
        return 'Police Clearance Certificate';
      case 'qualification':
        return 'Childcare Qualification';
      case 'certificate':
        return 'First Aid / CPR Certificate';
      case 'photo':
        return 'Identity Photo';
      default:
        return 'Supporting Document';
    }
  }
}

class VerificationQualificationItem {
  final String id;
  final String title;
  final String? institution;
  final String? certificateUrl;
  final String status;
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const VerificationQualificationItem({
    required this.id,
    required this.title,
    this.institution,
    this.certificateUrl,
    this.status = 'pending',
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isChangesRequested => status.toLowerCase() == 'changes_requested';

  factory VerificationQualificationItem.fromJson(dynamic data) {
    if (data is String) {
      return VerificationQualificationItem(id: data, title: data);
    }
    if (data is Map) {
      return VerificationQualificationItem(
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
    return VerificationQualificationItem(id: '', title: data.toString());
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

class VerificationRequestModel {
  final String id;
  final String babysitterId;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final String address;
  final DateTime? dateOfBirth;
  final String gender;
  final String bio;
  final int experienceYears;
  final double hourlyRate;
  final List<String> skills;
  final List<String> languages;
  final List<String> qualifications;
  final List<VerificationQualificationItem> qualificationItems;
  final List<String> ageGroups;
  final List<VerificationDocItem> documents;
  final String status;
  final String reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? submittedAt;

  const VerificationRequestModel({
    required this.id,
    required this.babysitterId,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.address = 'Colombo, Sri Lanka',
    this.dateOfBirth,
    this.gender = 'Female',
    this.bio = '',
    this.experienceYears = 1,
    this.hourlyRate = 1500.0,
    this.skills = const [],
    this.languages = const ['English', 'Sinhala'],
    this.qualifications = const [],
    this.qualificationItems = const [],
    this.ageGroups = const ['Infants', 'Toddlers'],
    this.documents = const [],
    this.status = 'pending',
    this.reviewNotes = '',
    this.reviewedBy,
    this.reviewedAt,
    this.submittedAt,
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    // Sitter can be populated User object or profile
    final sitter = json['babysitter'] is Map ? json['babysitter'] as Map : null;
    final profile = json['babysitterProfile'] is Map
        ? json['babysitterProfile'] as Map
        : (json['profile'] is Map ? json['profile'] as Map : null);

    final sId = sitter?['_id']?.toString() ??
        sitter?['id']?.toString() ??
        json['babysitterId']?.toString() ??
        json['babysitter']?.toString() ??
        '';

    final sName = sitter?['name']?.toString() ??
        profile?['name']?.toString() ??
        json['name']?.toString() ??
        'Babysitter';

    final sEmail = sitter?['email']?.toString() ??
        json['email']?.toString() ??
        'sitter@littlehands.lk';

    final sPhone = sitter?['phone']?.toString() ??
        profile?['phone']?.toString() ??
        json['phone']?.toString() ??
        '';

    final sAvatar = profile?['profileImage']?.toString() ??
        profile?['avatar']?.toString() ??
        sitter?['avatar']?.toString() ??
        '';

    final rawDocs = (json['documents'] as List?) ?? (profile?['documents'] as List?);
    final docList = rawDocs != null
        ? rawDocs
            .map((d) => VerificationDocItem.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList()
        : <VerificationDocItem>[];

    return VerificationRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'req-${DateTime.now().millisecondsSinceEpoch}',
      babysitterId: sId,
      name: sName,
      email: sEmail,
      phone: sPhone,
      avatar: sAvatar,
      address: profile?['address']?.toString() ?? json['address']?.toString() ?? 'Colombo, Sri Lanka',
      dateOfBirth: profile?['dateOfBirth'] != null
          ? DateTime.tryParse(profile!['dateOfBirth'].toString())
          : null,
      gender: profile?['gender']?.toString() ?? 'Female',
      bio: profile?['bio']?.toString() ?? json['bio']?.toString() ?? '',
      experienceYears: int.tryParse(
              profile?['experienceYears']?.toString() ?? json['experienceYears']?.toString() ?? '1') ??
          1,
      hourlyRate: double.tryParse(
              profile?['hourlyRate']?.toString() ?? json['hourlyRate']?.toString() ?? '1500') ??
          1500.0,
      skills: (profile?['skills'] as List?)?.map((e) => e.toString()).toList() ??
          (json['skills'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      languages: (profile?['languages'] as List?)?.map((e) => e.toString()).toList() ??
          (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
          const ['English', 'Sinhala'],
      qualifications: ((profile?['qualifications'] as List?) ?? (json['qualifications'] as List?))
              ?.map((e) => e is Map ? (e['title']?.toString() ?? e['name']?.toString() ?? 'Qualification') : e.toString())
              .toList() ??
          const [],
      qualificationItems: ((profile?['qualifications'] as List?) ?? (json['qualifications'] as List?))
              ?.map((e) => VerificationQualificationItem.fromJson(e))
              .toList() ??
          const [],
      ageGroups: (profile?['ageGroups'] as List?)?.map((e) => e.toString()).toList() ??
          (json['ageGroups'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Toddlers (1-3 yrs)', 'Children (4-6 yrs)'],
      documents: docList,
      status: json['status']?.toString() ?? 'pending',
      reviewNotes: json['reviewNotes']?.toString() ?? '',
      reviewedBy: json['reviewedBy']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isChangesRequested => status.toLowerCase() == 'changes_requested';
}
