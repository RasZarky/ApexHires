import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Basic Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedJobType = 'Full-time';
  String _selectedExperience = 'Mid';

  // Step 2: Requirements
  final _skillsController = TextEditingController();
  List<String> _skills = [];
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  String _selectedCurrency = 'USD';

  // Step 3: Screening Questions
  List<_ScreeningQuestionEntry> _screeningQuestions = [];

  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _addScreeningQuestion() {
    setState(() {
      _screeningQuestions.add(_ScreeningQuestionEntry(
        id: _uuid.v4(),
        textController: TextEditingController(),
        isRequired: true,
      ));
    });
  }

  void _removeScreeningQuestion(int index) {
    setState(() {
      _screeningQuestions[index].textController.dispose();
      _screeningQuestions.removeAt(index);
    });
  }

  Future<void> _publishJob() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the job title and description'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isPublishing = true);

    final job = JobModel(
      jobId: '',
      recruiterId: user.uid,
      companyName: user.recruiterProfile?.companyName ?? '',
      companyLogoUrl: user.recruiterProfile?.companyLogoUrl ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      jobType: _selectedJobType,
      experienceLevel: _selectedExperience,
      salaryRange: SalaryRange(
        min: double.tryParse(_salaryMinController.text) ?? 0,
        max: double.tryParse(_salaryMaxController.text) ?? 0,
        currency: _selectedCurrency,
      ),
      skillsRequired: _skills,
      screeningQuestions: _screeningQuestions
          .where((q) => q.textController.text.isNotEmpty)
          .map((q) => ScreeningQuestion(
                questionId: q.id,
                questionText: q.textController.text.trim(),
                isRequired: q.isRequired,
              ))
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final jobId = await context.read<JobProvider>().createJob(job);

    if (mounted) {
      setState(() => _isPublishing = false);

      if (jobId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job published successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish job. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Step labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepLabel(
                    label: 'Basic Info', isActive: _currentStep >= 0),
                _StepLabel(
                    label: 'Requirements', isActive: _currentStep >= 1),
                _StepLabel(
                    label: 'Questions', isActive: _currentStep >= 2),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildRequirementsStep(),
                _buildScreeningStep(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep--);
                      },
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPublishing
                        ? null
                        : _currentStep == 2
                            ? _publishJob
                            : () {
                                _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentStep++);
                              },
                    child: _isPublishing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Publish Job' : 'Next',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Describe the position you want to fill',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Job Title',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Job Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Job Type
          Text('Job Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.jobTypes.map((type) {
              return FilterChip(
                label: Text(type),
                selected: _selectedJobType == type,
                onSelected: (_) => setState(() => _selectedJobType = type),
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Experience Level
          Text('Experience Level',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.experienceLevels.map((level) {
              return FilterChip(
                label: Text(level),
                selected: _selectedExperience == level,
                onSelected: (_) =>
                    setState(() => _selectedExperience = level),
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requirements',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('What skills and compensation are you offering?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // Skills
          Text('Skills Required',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillsController,
                  decoration: const InputDecoration(hintText: 'Add a skill'),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addSkill,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _skills.remove(skill)),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Salary Range
          Text('Salary Range',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _salaryMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Min'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—', style: TextStyle(color: AppColors.lightText)),
              ),
              Expanded(
                child: TextField(
                  controller: _salaryMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Max'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedCurrency,
                items: AppConstants.currencies.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCurrency = v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Screening Questions',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Add questions to pre-screen candidates',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          if (_screeningQuestions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.help_outline,
                      size: 48, color: AppColors.lightText),
                  const SizedBox(height: 12),
                  const Text(
                    'No screening questions yet',
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add questions to learn more about candidates',
                    style:
                        TextStyle(color: AppColors.lightText, fontSize: 12),
                  ),
                ],
              ),
            ),

          ...List.generate(_screeningQuestions.length, (index) {
            final q = _screeningQuestions[index];
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
                        'Q${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('Required',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.secondaryText)),
                          Switch(
                            value: q.isRequired,
                            onChanged: (v) {
                              setState(() => q.isRequired = v);
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _removeScreeningQuestion(index),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: q.textController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your question...',
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addScreeningQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StepLabel({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isActive ? AppColors.primary : AppColors.lightText,
      ),
    );
  }
}

class _ScreeningQuestionEntry {
  final String id;
  final TextEditingController textController;
  bool isRequired;

  _ScreeningQuestionEntry({
    required this.id,
    required this.textController,
    this.isRequired = true,
  });
}
