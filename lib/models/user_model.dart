import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'job_seeker', 'recruiter', 'admin'
  final String fullName;
  final String phoneNumber;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBlocked;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String deletedReason;
  final SeekerProfile? seekerProfile;
  final RecruiterProfile? recruiterProfile;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    this.phoneNumber = '',
    this.avatarUrl = '',
    this.isBlocked = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedReason = '',
    required this.createdAt,
    required this.updatedAt,
    this.seekerProfile,
    this.recruiterProfile,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'job_seeker',
      fullName: map['full_name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      isBlocked: map['is_blocked'] ?? false,
      isDeleted: map['is_deleted'] ?? false,
      deletedAt: (map['deleted_at'] as Timestamp?)?.toDate(),
      deletedReason: map['deleted_reason'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seekerProfile: map['seeker_profile'] != null
          ? SeekerProfile.fromMap(map['seeker_profile'])
          : null,
      recruiterProfile: map['recruiter_profile'] != null
          ? RecruiterProfile.fromMap(map['recruiter_profile'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deleted_reason': deletedReason,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'seeker_profile': seekerProfile?.toMap(),
      'recruiter_profile': recruiterProfile?.toMap(),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    bool? isBlocked,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedReason,
    SeekerProfile? seekerProfile,
    RecruiterProfile? recruiterProfile,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedReason: deletedReason ?? this.deletedReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      seekerProfile: seekerProfile ?? this.seekerProfile,
      recruiterProfile: recruiterProfile ?? this.recruiterProfile,
    );
  }
}

class SeekerProfile {
  final String headline;
  final String bio;
  final String location;
  final String resumeUrl;
  final String resumeName;
  final List<String> skills;
  final List<Experience> experience;
  final List<Education> education;

  SeekerProfile({
    this.headline = '',
    this.bio = '',
    this.location = '',
    this.resumeUrl = '',
    this.resumeName = '',
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
  });

  factory SeekerProfile.fromMap(Map<String, dynamic> map) {
    return SeekerProfile(
      headline: map['headline'] ?? '',
      bio: map['bio'] ?? '',
      location: map['location'] ?? '',
      resumeUrl: map['resume_url'] ?? '',
      resumeName: map['resume_name'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      experience: (map['experience'] as List<dynamic>?)
              ?.map((e) => Experience.fromMap(e))
              .toList() ??
          [],
      education: (map['education'] as List<dynamic>?)
              ?.map((e) => Education.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'headline': headline,
      'bio': bio,
      'location': location,
      'resume_url': resumeUrl,
      'resume_name': resumeName,
      'skills': skills,
      'experience': experience.map((e) => e.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
    };
  }

  SeekerProfile copyWith({
    String? headline,
    String? bio,
    String? location,
    String? resumeUrl,
    String? resumeName,
    List<String>? skills,
    List<Experience>? experience,
    List<Education>? education,
  }) {
    return SeekerProfile(
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeName: resumeName ?? this.resumeName,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
    );
  }
}

class Experience {
  final String title;
  final String company;
  final String startDate;
  final String endDate;
  final String description;
  final bool isCurrent;

  Experience({
    this.title = '',
    this.company = '',
    this.startDate = '',
    this.endDate = '',
    this.description = '',
    this.isCurrent = false,
  });

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'] ?? '',
      description: map['description'] ?? '',
      isCurrent: map['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'is_current': isCurrent,
    };
  }
}

class Education {
  final String degree;
  final String institution;
  final String startYear;
  final String endYear;

  Education({
    this.degree = '',
    this.institution = '',
    this.startYear = '',
    this.endYear = '',
  });

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      degree: map['degree'] ?? '',
      institution: map['institution'] ?? '',
      startYear: map['start_year'] ?? '',
      endYear: map['end_year'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'degree': degree,
      'institution': institution,
      'start_year': startYear,
      'end_year': endYear,
    };
  }
}

class RecruiterProfile {
  final String companyName;
  final String companyWebsite;
  final String companyLogoUrl;
  final String designation;
  final bool isVerified;

  RecruiterProfile({
    this.companyName = '',
    this.companyWebsite = '',
    this.companyLogoUrl = '',
    this.designation = '',
    this.isVerified = false,
  });

  factory RecruiterProfile.fromMap(Map<String, dynamic> map) {
    return RecruiterProfile(
      companyName: map['company_name'] ?? '',
      companyWebsite: map['company_website'] ?? '',
      companyLogoUrl: map['company_logo_url'] ?? '',
      designation: map['designation'] ?? '',
      isVerified: map['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'company_website': companyWebsite,
      'company_logo_url': companyLogoUrl,
      'designation': designation,
      'is_verified': isVerified,
    };
  }

  RecruiterProfile copyWith({
    String? companyName,
    String? companyWebsite,
    String? companyLogoUrl,
    String? designation,
    bool? isVerified,
  }) {
    return RecruiterProfile(
      companyName: companyName ?? this.companyName,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      designation: designation ?? this.designation,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
