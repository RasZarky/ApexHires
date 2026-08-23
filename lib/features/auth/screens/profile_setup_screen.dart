import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Common fields
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  // Recruiter fields
  final _companyNameController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _designationController = TextEditingController();

  // Seeker specific
  List<String> _selectedSkills = [];
  File? _avatarFile;
  File? _resumeFile;

  String get _role => context.read<AuthProvider>().user?.role ?? 'job_seeker';
  bool get _isSeeker => _role == 'job_seeker';

  final List<String> _availableSkills = [
    'Flutter', 'Dart', 'React', 'Angular', 'Vue.js', 'Node.js',
    'Python', 'Java', 'Kotlin', 'Swift', 'TypeScript', 'JavaScript',
    'AWS', 'Docker', 'Kubernetes', 'Firebase', 'GraphQL', 'REST API',
    'PostgreSQL', 'MongoDB', 'Git', 'CI/CD', 'Agile', 'Scrum',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromExistingUser();
  }

  /// Pre-fill all fields from existing user data so nothing is repeated
  void _prefillFromExistingUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      setState(() {
        _nameController.text = user.fullName;
        _phoneController.text = user.phoneNumber;

        if (_isSeeker && user.seekerProfile != null) {
          final profile = user.seekerProfile!;
          _headlineController.text = profile.headline;
          _bioController.text = profile.bio;
          _locationController.text = profile.location;
          _selectedSkills = List<String>.from(profile.skills);
        }

        if (!_isSeeker && user.recruiterProfile != null) {
          final profile = user.recruiterProfile!;
          _companyNameController.text = profile.companyName;
          _companyWebsiteController.text = profile.companyWebsite;
          _designationController.text = profile.designation;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    _designationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _resumeFile = File(result.files.first.path!));
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();

    bool success;
    if (_isSeeker) {
      success = await authProvider.updateProfile(
        fullName: _nameController.text.isNotEmpty
            ? _nameController.text
            : authProvider.user?.fullName,
        phoneNumber: _phoneController.text,
        seekerProfile: SeekerProfile(
          headline: _headlineController.text,
          bio: _bioController.text,
          location: _locationController.text,
          skills: _selectedSkills,
        ),
        avatarFile: _avatarFile,
        resumeFile: _resumeFile,
      );
    } else {
      success = await authProvider.updateProfile(
        phoneNumber: _phoneController.text,
        recruiterProfile: RecruiterProfile(
          companyName: _companyNameController.text,
          companyWebsite: _companyWebsiteController.text,
          designation: _designationController.text,
        ),
        avatarFile: _avatarFile,
      );
    }

    if (success && mounted) {
      if (_isSeeker) {
        Navigator.of(context).pushNamedAndRemoveUntil('/seeker_home', (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/recruiter_home', (route) => false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _getTotalSteps() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  int _getTotalSteps() => _isSeeker ? 3 : 2;

  /// Check if profile is already complete enough to skip
  bool _isProfileComplete() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;
    if (user.fullName.isEmpty) return false;

    if (_isSeeker) {
      return user.seekerProfile != null &&
          (user.seekerProfile!.headline.isNotEmpty ||
              user.seekerProfile!.bio.isNotEmpty);
    } else {
      return user.recruiterProfile != null &&
          user.recruiterProfile!.companyName.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-skip if profile is already complete
    if (_isProfileComplete()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_isSeeker) {
            Navigator.of(context).pushNamedAndRemoveUntil('/seeker_home', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/recruiter_home', (route) => false);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        automaticallyImplyLeading: false,
        actions: [
          // Skip button in app bar
          TextButton(
            onPressed: () {
              if (_isSeeker) {
                Navigator.of(context).pushNamedAndRemoveUntil('/seeker_home', (route) => false);
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil('/recruiter_home', (route) => false);
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(_getTotalSteps(), (index) {
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
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _isSeeker
                  ? [
                      _buildBasicInfoStep(),
                      _buildSkillsStep(),
                      _buildResumeStep(),
                    ]
                  : [
                      _buildBasicInfoStep(),
                      _buildCompanyStep(),
                    ],
            ),
          ),
          // Next/Save Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _nextStep,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == _getTotalSteps() - 1
                                ? 'Complete Setup'
                                : 'Next',
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Info',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Avatar
          Center(
            child: GestureDetector(
              onTap: context.read<AuthProvider>().isStorageAvailable
                  ? _pickAvatar
                  : null,
              child: Stack(
                children: [
                  ProfileAvatar(
                    url: context.read<AuthProvider>().user?.avatarUrl ?? '',
                    radius: 48,
                    initials: (context.read<AuthProvider>().user?.fullName ??
                            'U')
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                  if (context.read<AuthProvider>().isStorageAvailable)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Name (pre-filled from signup)
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          // Headline
          TextField(
            controller: _headlineController,
            decoration: const InputDecoration(
              hintText: 'e.g. Senior Flutter Developer',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 16),
          // Bio
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write a short bio about yourself',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.info_outline),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          // Location
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Location (e.g. San Francisco, CA)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),
          // Phone
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    final customSkillController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setSkillsState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Select or type your key skills',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: ${_selectedSkills.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Custom skill input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customSkillController,
                      decoration: InputDecoration(
                        hintText: 'Add a custom skill...',
                        hintStyle: TextStyle(
                          color: AppColors.lightText.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onSubmitted: (value) {
                        final skill = value.trim();
                        if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
                          setSkillsState(() {
                            _selectedSkills.add(skill);
                          });
                          customSkillController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final skill = customSkillController.text.trim();
                      if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
                        setSkillsState(() {
                          _selectedSkills.add(skill);
                        });
                        customSkillController.clear();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Selected custom skills (not from predefined list)
              if (_selectedSkills
                  .where((s) => !_availableSkills.contains(s))
                  .isNotEmpty) ...[
                const Text(
                  'Your Skills',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills
                      .where((s) => !_availableSkills.contains(s))
                      .map((skill) => SkillChip(
                            skill: skill,
                            selected: true,
                            onTap: () {
                              setSkillsState(() {
                                _selectedSkills.remove(skill);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Predefined skills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSkills.map((skill) {
                  return SkillChip(
                    skill: skill,
                    selected: _selectedSkills.contains(skill),
                    onTap: () {
                      setSkillsState(() {
                        if (_selectedSkills.contains(skill)) {
                          _selectedSkills.remove(skill);
                        } else {
                          _selectedSkills.add(skill);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Upload your resume (PDF)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Upload area
          if (!context.read<AuthProvider>().isStorageAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.lightText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'File uploads require Supabase (not configured). Set SUPABASE_URL to enable.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (context.read<AuthProvider>().isStorageAvailable)
            GestureDetector(
              onTap: _pickResume,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _resumeFile != null
                        ? AppColors.primary
                        : AppColors.divider,
                    width: _resumeFile != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _resumeFile != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _resumeFile != null
                          ? AppColors.primary
                          : AppColors.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _resumeFile != null
                          ? _resumeFile!.path.split('/').last
                          : 'Tap to upload your resume',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF only, max 10MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Info tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your resume helps recruiters quickly review your qualifications. You can update it anytime.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Skip option
          Center(
            child: TextButton(
              onPressed: () {
                if (_isSeeker) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/seeker_home', (route) => false);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil('/recruiter_home', (route) => false);
                }
              },
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Info',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about your company',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              hintText: 'Company Name',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _companyWebsiteController,
            decoration: const InputDecoration(
              hintText: 'Company Website',
              prefixIcon: Icon(Icons.language_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _designationController,
            decoration: const InputDecoration(
              hintText: 'Your Designation',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 24),
          // Company Logo Upload
          if (!context.read<AuthProvider>().isStorageAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.lightText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logo upload requires Supabase (not configured).',
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (context.read<AuthProvider>().isStorageAvailable)
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _avatarFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child:
                              Image.file(_avatarFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.lightText,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload Logo',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
