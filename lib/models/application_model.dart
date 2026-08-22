import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String recruiterId;
  final String seekerId;
  final String seekerName;
  final String seekerAvatar;
  final String seekerHeadline;
  final String resumeUrl;
  final String status; // applied, shortlisted, interviewing, hired, rejected
  final List<ScreeningAnswer> screeningAnswers;
  final String internalNotes;
  final bool isRead;
  final DateTime appliedAt;
  final DateTime updatedAt;

  ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.recruiterId,
    required this.seekerId,
    required this.seekerName,
    this.seekerAvatar = '',
    this.seekerHeadline = '',
    this.resumeUrl = '',
    this.status = 'applied',
    this.screeningAnswers = const [],
    this.internalNotes = '',
    this.isRead = false,
    required this.appliedAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      applicationId: map['application_id'] ?? '',
      jobId: map['job_id'] ?? '',
      jobTitle: map['job_title'] ?? '',
      recruiterId: map['recruiter_id'] ?? '',
      seekerId: map['seeker_id'] ?? '',
      seekerName: map['seeker_name'] ?? '',
      seekerAvatar: map['seeker_avatar'] ?? '',
      seekerHeadline: map['seeker_headline'] ?? '',
      resumeUrl: map['resume_url'] ?? '',
      status: map['status'] ?? 'applied',
      screeningAnswers: (map['screening_answers'] as List<dynamic>?)
              ?.map((e) => ScreeningAnswer.fromMap(e))
              .toList() ??
          [],
      internalNotes: map['internal_notes'] ?? '',
      isRead: map['is_read'] ?? false,
      appliedAt: (map['applied_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'application_id': applicationId,
      'job_id': jobId,
      'job_title': jobTitle,
      'recruiter_id': recruiterId,
      'seeker_id': seekerId,
      'seeker_name': seekerName,
      'seeker_avatar': seekerAvatar,
      'seeker_headline': seekerHeadline,
      'resume_url': resumeUrl,
      'status': status,
      'screening_answers': screeningAnswers.map((e) => e.toMap()).toList(),
      'internal_notes': internalNotes,
      'is_read': isRead,
      'applied_at': Timestamp.fromDate(appliedAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  ApplicationModel copyWith({
    String? status,
    String? internalNotes,
    List<ScreeningAnswer>? screeningAnswers,
    bool? isRead,
  }) {
    return ApplicationModel(
      applicationId: applicationId,
      jobId: jobId,
      jobTitle: jobTitle,
      recruiterId: recruiterId,
      seekerId: seekerId,
      seekerName: seekerName,
      seekerAvatar: seekerAvatar,
      seekerHeadline: seekerHeadline,
      resumeUrl: resumeUrl,
      status: status ?? this.status,
      screeningAnswers: screeningAnswers ?? this.screeningAnswers,
      internalNotes: internalNotes ?? this.internalNotes,
      isRead: isRead ?? this.isRead,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
    );
  }
}

class ScreeningAnswer {
  final String questionText;
  final String answerText;

  ScreeningAnswer({
    required this.questionText,
    required this.answerText,
  });

  factory ScreeningAnswer.fromMap(Map<String, dynamic> map) {
    return ScreeningAnswer(
      questionText: map['question_text'] ?? '',
      answerText: map['answer_text'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_text': questionText,
      'answer_text': answerText,
    };
  }
}
