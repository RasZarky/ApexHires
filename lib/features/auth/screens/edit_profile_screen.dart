import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyWebsiteController;
  late TextEditingController _designationController;

  List<String> _selectedSkills = [];
  bool _isSaving = false;
  File? _avatarFile;
  File? _resumeFile;
  final _customSkillController = TextEditingController();

  final List<String> _availableSkills = [
    'Flutter', 'Dart', 'React', 'Angular', 'Vue.js', 'Node.js',
    'Python', 'Java', 'Kotlin', 'Swift', 'TypeScript', 'JavaScript',
    'AWS', 'Docker', 'Kubernetes', 'Firebase', 'GraphQL', 'REST API',
    'PostgreSQL', 'MongoDB', 'Git', 'CI/CD', 'Agile', 'Scrum',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _headlineController =
        TextEditingController(text: user?.seekerProfile?.headline ?? '');
    _bioController =
        TextEditingController(text: user?.seekerProfile?.bio ?? '');
    _locationController =
        TextEditingController(text: user?.seekerProfile?.location ?? '');
    _phoneController =
        TextEditingController(text: user?.phoneNumber ?? '');
    _companyNameController =
        TextEditingController(text: user?.recruiterProfile?.companyName ?? '');
    _companyWebsiteController =
        TextEditingController(text: user?.recruiterProfile?.companyWebsite ?? '');
    _designationController =
        TextEditingController(text: user?.recruiterProfile?.designation ?? '');
    _selectedSkills = List<String>.from(user?.seekerProfile?.skills ?? []);
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
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isStorageAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploads require Supabase. Set SUPABASE_URL to enable.'),
          ),
        );
      }
      return;
    }
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
    final auth = context.read<AuthProvider>();
    if (!auth.isStorageAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploads require Supabase. Set SUPABASE_URL to enable.'),
          ),
        );
      }
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _resumeFile = File(result.files.first.path!));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    bool success = false;
    try {
      if (user.role == 'job_seeker') {
        success = await auth.updateProfile(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          seekerProfile: SeekerProfile(
            headline: _headlineController.text.trim(),
            bio: _bioController.text.trim(),
            location: _locationController.text.trim(),
            skills: _selectedSkills,
            resumeUrl: user.seekerProfile?.resumeUrl ?? '',
            resumeName: user.seekerProfile?.resumeName ?? '',
            experience: user.seekerProfile?.experience ?? [],
            education: user.seekerProfile?.education ?? [],
          ),
          avatarFile: _avatarFile,
          resumeFile: _resumeFile,
          resumeName: _resumeFile?.path.split('/').last,
        );
      } else {
        success = await auth.updateProfile(
          phoneNumber: _phoneController.text.trim(),
          recruiterProfile: RecruiterProfile(
            companyName: _companyNameController.text.trim(),
            companyWebsite: _companyWebsiteController.text.trim(),
            designation: _designationController.text.trim(),
            companyLogoUrl: user.recruiterProfile?.companyLogoUrl ?? '',
            isVerified: user.recruiterProfile?.isVerified ?? false,
          ),
          avatarFile: _avatarFile,
        );
      }
    } catch (e) {
      // Save failed
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isSeeker = user?.role == 'job_seeker';
    final canUpload = context.read<AuthProvider>().isStorageAvailable;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with tap to change
            Center(
              child: GestureDetector(
                onTap: canUpload ? _pickAvatar : null,
                child: Stack(
                  children: [
                    _avatarFile != null
                        ? CircleAvatar(
                            radius: 48,
                            backgroundImage: FileImage(_avatarFile!),
                          )
                        : ProfileAvatar(
                            url: user?.avatarUrl ?? '',
                            radius: 48,
                            initials: (user?.fullName ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                          ),
                    if (canUpload)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
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
            const SizedBox(height: 8),
            if (!canUpload)
              Center(
                child: Text(
                  'Image uploads require Supabase',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),

            // Name
            _FieldLabel('Full Name'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),

            if (isSeeker) ...[
              // Headline
              _FieldLabel('Headline'),
              TextField(
                controller: _headlineController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Senior Flutter Developer',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Bio
              _FieldLabel('Bio'),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell recruiters about yourself...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Location
              _FieldLabel('Location'),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. San Francisco, CA',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Skills
              _FieldLabel('Skills (${_selectedSkills.length} selected)'),
              // Custom skill input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSkillController,
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
                          setState(() {
                            _selectedSkills.add(skill);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final skill = _customSkillController.text.trim();
                      if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
                        setState(() {
                          _selectedSkills.add(skill);
                        });
                        _customSkillController.clear();
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
              const SizedBox(height: 12),
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
                              setState(() {
                                _selectedSkills.remove(skill);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
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
                      setState(() {
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
              const SizedBox(height: 20),

              // Resume
              _FieldLabel('Resume'),
              if (user?.seekerProfile?.resumeUrl.isNotEmpty == true &&
                  _resumeFile == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user!.seekerProfile!.resumeName.isNotEmpty
                              ? user.seekerProfile!.resumeName
                              : 'Resume uploaded',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canUpload)
                        TextButton(
                          onPressed: _pickResume,
                          child: const Text('Replace'),
                        ),
                    ],
                  ),
                )
              else if (_resumeFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _resumeFile!.path.split('/').last,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _resumeFile = null),
                      ),
                    ],
                  ),
                )
              else if (canUpload)
                GestureDetector(
                  onTap: _pickResume,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.divider,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            color: AppColors.lightText, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Tap to upload resume (PDF)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.lightText, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resume upload requires Supabase',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],

            if (!isSeeker) ...[
              // Company Name
              _FieldLabel('Company Name'),
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Company Website
              _FieldLabel('Company Website'),
              TextField(
                controller: _companyWebsiteController,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Designation
              _FieldLabel('Designation'),
              TextField(
                controller: _designationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. HR Manager',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Phone (both roles)
            _FieldLabel('Phone Number'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
