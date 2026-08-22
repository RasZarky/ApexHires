import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String jobId;
  final String recruiterId;
  final String companyName;
  final String companyLogoUrl;
  final String title;
  final String description;
  final String location;
  final String jobType; // Full-time, Part-time, Contract, Remote, Hybrid
  final String experienceLevel; // Entry, Mid, Senior, Lead
  final SalaryRange salaryRange;
  final List<String> skillsRequired;
  final List<ScreeningQuestion> screeningQuestions;
  final String status; // active, paused, closed
  final int applicationsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobModel({
    required this.jobId,
    required this.recruiterId,
    required this.companyName,
    this.companyLogoUrl = '',
    required this.title,
    required this.description,
    required this.location,
    required this.jobType,
    required this.experienceLevel,
    required this.salaryRange,
    this.skillsRequired = const [],
    this.screeningQuestions = const [],
    this.status = 'active',
    this.applicationsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      jobId: map['job_id'] ?? '',
      recruiterId: map['recruiter_id'] ?? '',
      companyName: map['company_name'] ?? '',
      companyLogoUrl: map['company_logo_url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      jobType: map['job_type'] ?? 'Full-time',
      experienceLevel: map['experience_level'] ?? 'Mid',
      salaryRange: map['salary_range'] != null
          ? SalaryRange.fromMap(map['salary_range'])
          : SalaryRange(),
      skillsRequired: List<String>.from(map['skills_required'] ?? []),
      screeningQuestions: (map['screening_questions'] as List<dynamic>?)
              ?.map((e) => ScreeningQuestion.fromMap(e))
              .toList() ??
          [],
      status: map['status'] ?? 'active',
      applicationsCount: map['applications_count'] ?? 0,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'recruiter_id': recruiterId,
      'company_name': companyName,
      'company_logo_url': companyLogoUrl,
      'title': title,
      'description': description,
      'location': location,
      'job_type': jobType,
      'experience_level': experienceLevel,
      'salary_range': salaryRange.toMap(),
      'skills_required': skillsRequired,
      'screening_questions': screeningQuestions.map((e) => e.toMap()).toList(),
      'status': status,
      'applications_count': applicationsCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  JobModel copyWith({
    String? title,
    String? description,
    String? location,
    String? jobType,
    String? experienceLevel,
    SalaryRange? salaryRange,
    List<String>? skillsRequired,
    List<ScreeningQuestion>? screeningQuestions,
    String? status,
    int? applicationsCount,
  }) {
    return JobModel(
      jobId: jobId,
      recruiterId: recruiterId,
      companyName: companyName,
      companyLogoUrl: companyLogoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      salaryRange: salaryRange ?? this.salaryRange,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      screeningQuestions: screeningQuestions ?? this.screeningQuestions,
      status: status ?? this.status,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get salaryDisplay =>
      '${salaryRange.currency} ${salaryRange.min.toStringAsFixed(0)} - ${salaryRange.max.toStringAsFixed(0)}';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class SalaryRange {
  final double min;
  final double max;
  final String currency;

  SalaryRange({
    this.min = 0,
    this.max = 0,
    this.currency = 'USD',
  });

  factory SalaryRange.fromMap(Map<String, dynamic> map) {
    return SalaryRange(
      min: (map['min'] ?? 0).toDouble(),
      max: (map['max'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
    };
  }
}

class ScreeningQuestion {
  final String questionId;
  final String questionText;
  final bool isRequired;

  ScreeningQuestion({
    required this.questionId,
    required this.questionText,
    this.isRequired = true,
  });

  factory ScreeningQuestion.fromMap(Map<String, dynamic> map) {
    return ScreeningQuestion(
      questionId: map['question_id'] ?? '',
      questionText: map['question_text'] ?? '',
      isRequired: map['is_required'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'is_required': isRequired,
    };
  }
}
