import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class EasyApplyScreen extends StatefulWidget {
  final JobModel job;

  const EasyApplyScreen({super.key, required this.job});

  @override
  State<EasyApplyScreen> createState() => _EasyApplyScreenState();
}

class _EasyApplyScreenState extends State<EasyApplyScreen> {
  late Map<String, TextEditingController> _answerControllers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _answerControllers = {};
    for (final q in widget.job.screeningQuestions) {
      _answerControllers[q.questionId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitApplication() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Validate required questions
    for (final q in widget.job.screeningQuestions) {
      if (q.isRequired &&
          _answerControllers[q.questionId]?.text.trim().isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please answer: ${q.questionText}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final answers = widget.job.screeningQuestions.map((q) {
      return ScreeningAnswer(
        questionText: q.questionText,
        answerText: _answerControllers[q.questionId]?.text ?? '',
      );
    }).toList();

    final application = ApplicationModel(
      applicationId: '',
      jobId: widget.job.jobId,
      jobTitle: widget.job.title,
      recruiterId: widget.job.recruiterId,
      seekerId: user.uid,
      seekerName: user.fullName,
      seekerAvatar: user.avatarUrl,
      seekerHeadline: user.seekerProfile?.headline ?? '',
      resumeUrl: user.seekerProfile?.resumeUrl ?? '',
      screeningAnswers: answers,
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result =
        await context.read<ApplicationProvider>().submitApplication(application);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result != null) {
        // Show success and go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit application. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final job = widget.job;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apply'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    url: job.companyLogoUrl,
                    radius: 24,
                    initials: job.companyName.substring(0, 1).toUpperCase(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          job.companyName,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Review Section
            Text(
              'Your Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'This information will be shared with the recruiter',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _ProfileRow(
                    label: 'Name',
                    value: user?.fullName ?? '',
                  ),
                  const Divider(),
                  _ProfileRow(
                    label: 'Email',
                    value: user?.email ?? '',
                  ),
                  const Divider(),
                  _ProfileRow(
                    label: 'Headline',
                    value: user?.seekerProfile?.headline ?? 'Not set',
                  ),
                  const Divider(),
                  _ProfileRow(
                    label: 'Resume',
                    value: user?.seekerProfile?.resumeName ??
                        'No resume uploaded',
                    valueColor: user?.seekerProfile?.resumeUrl != null &&
                            user!.seekerProfile!.resumeUrl.isNotEmpty
                        ? AppColors.primary
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Screening Questions
            if (job.screeningQuestions.isNotEmpty) ...[
              Text(
                'Screening Questions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Answer the following questions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              ...job.screeningQuestions.asMap().entries.map((entry) {
                final q = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Q${entry.key + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (q.isRequired) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q.questionText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _answerControllers[q.questionId],
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Your answer...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightText,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.darkText,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
