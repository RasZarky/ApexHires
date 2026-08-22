import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class EditJobScreen extends StatefulWidget {
  final JobModel job;

  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late String _selectedJobType;
  late String _selectedExperience;

  late final TextEditingController _skillsController;
  late List<String> _skills;
  late final TextEditingController _salaryMinController;
  late final TextEditingController _salaryMaxController;
  late String _selectedCurrency;

  late List<_ScreeningQuestionEntry> _screeningQuestions;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final job = widget.job;

    _titleController = TextEditingController(text: job.title);
    _descriptionController = TextEditingController(text: job.description);
    _locationController = TextEditingController(text: job.location);
    _selectedJobType = job.jobType;
    _selectedExperience = job.experienceLevel;

    _skillsController = TextEditingController();
    _skills = List<String>.from(job.skillsRequired);
    _salaryMinController =
        TextEditingController(text: job.salaryRange.min.toStringAsFixed(0));
    _salaryMaxController =
        TextEditingController(text: job.salaryRange.max.toStringAsFixed(0));
    _selectedCurrency = job.salaryRange.currency;

    _screeningQuestions = job.screeningQuestions
        .map((q) => _ScreeningQuestionEntry(
              id: q.questionId.isNotEmpty ? q.questionId : _uuid.v4(),
              textController: TextEditingController(text: q.questionText),
              isRequired: q.isRequired,
            ))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _pageController.dispose();
    for (final q in _screeningQuestions) {
      q.textController.dispose();
    }
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

  Future<void> _saveJob() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the job title and description'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedJob = widget.job.copyWith(
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
    );

    final success = await context.read<JobProvider>().updateJob(updatedJob);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update job. Try again.'),
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
      appBar: AppBar(title: const Text('Edit Job')),
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
                    onPressed: _isSaving
                        ? null
                        : _currentStep == 2
                            ? _saveJob
                            : () {
                                _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentStep++);
                              },
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Save Changes' : 'Next',
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
          Text('Describe the position',
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
          Text('Skills and compensation',
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
                child: Text('—',
                    style: TextStyle(color: AppColors.lightText)),
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
          Text('Pre-screen candidates',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          if (_screeningQuestions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Icon(Icons.help_outline,
                      size: 48, color: AppColors.lightText),
                  const SizedBox(height: 12),
                  const Text(
                    'No screening questions',
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14),
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
                                  fontSize: 12,
                                  color: AppColors.secondaryText)),
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
                        onPressed: () =>
                            _removeScreeningQuestion(index),
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
