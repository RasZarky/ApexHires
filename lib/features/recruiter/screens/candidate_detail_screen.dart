import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';
import 'package:apex_hires/features/chat/screens/chat_detail_screen.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateDetailScreen extends StatefulWidget {
  final ApplicationModel application;
  final JobModel job;

  const CandidateDetailScreen({
    super.key,
    required this.application,
    required this.job,
  });

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  late TextEditingController _notesController;
  UserModel? _seekerProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.application.internalNotes,
    );
    _loadSeekerProfile();
    _markAsRead();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    if (!widget.application.isRead) {
      await context.read<ApplicationProvider>().markAsRead(widget.application.applicationId);
    }
  }

  Future<void> _loadSeekerProfile() async {
    final profile =
        await FirestoreService().getUserById(widget.application.seekerId);
    if (mounted) {
      setState(() {
        _seekerProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Candidate'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              await context
                  .read<ApplicationProvider>()
                  .updateStatus(app.applicationId, value);
              if (mounted) Navigator.pop(context);
            },
            itemBuilder: (context) {
              return AppConstants.applicationStatuses.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Move to ${AppColors.getStatusLabel(status)}'),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Candidate Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ProfileAvatar(
                    url: app.seekerAvatar,
                    radius: 40,
                    initials: app.seekerName.isNotEmpty
                        ? app.seekerName.substring(0, 1).toUpperCase()
                        : 'S',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.seekerName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (app.seekerHeadline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      app.seekerHeadline,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  StatusBadge(status: app.status),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Message button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final chatId = await context
                              .read<ChatProvider>()
                              .getOrCreateChat(
                                applicationId: app.applicationId,
                                jobId: app.jobId,
                                seekerId: app.seekerId,
                                recruiterId: app.recruiterId,
                              );
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatId: chatId,
                                  otherUserId: app.seekerId,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                      const SizedBox(width: 12),
                      if (app.resumeUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(app.resumeUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open resume')),
                              );
                            }
                          },
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('View Resume'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Screening Answers
            if (app.screeningAnswers.isNotEmpty) ...[
              _SectionCard(
                title: 'Screening Answers',
                child: Column(
                  children: app.screeningAnswers.map((answer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            answer.questionText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            answer.answerText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Seeker Profile (if loaded)
            if (_isLoadingProfile)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_seekerProfile?.seekerProfile != null) ...[
              _SectionCard(
                title: 'About',
                child: Text(
                  _seekerProfile!.seekerProfile!.bio.isNotEmpty
                      ? _seekerProfile!.seekerProfile!.bio
                      : 'No bio provided',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_seekerProfile!.seekerProfile!.skills.isNotEmpty)
                _SectionCard(
                  title: 'Skills',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _seekerProfile!.seekerProfile!.skills
                        .map((skill) => SkillChip(skill: skill))
                        .toList(),
                  ),
                ),

              if (_seekerProfile!.seekerProfile!.experience.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Experience',
                  child: Column(
                    children: _seekerProfile!.seekerProfile!.experience
                        .map((exp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.work_outline,
                                      size: 20,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exp.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${exp.company} • ${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Internal Notes
            _SectionCard(
              title: 'Internal Notes',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this candidate...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context
                            .read<ApplicationProvider>()
                            .updateNotes(
                              app.applicationId,
                              _notesController.text,
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notes saved'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Notes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
