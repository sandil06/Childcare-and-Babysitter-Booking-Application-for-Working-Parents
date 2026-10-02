import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/babysitter_provider.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/verification_badge.dart';

class SitterRegistrationScreen extends StatefulWidget {
  const SitterRegistrationScreen({super.key});

  @override
  State<SitterRegistrationScreen> createState() =>
      _SitterRegistrationScreenState();
}

class _SitterRegistrationScreenState extends State<SitterRegistrationScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Document Upload States
  final Map<String, DocumentUploadStatus> _docStatuses = {
    'id': DocumentUploadStatus.notUploaded,
    'police': DocumentUploadStatus.notUploaded,
    'cpr': DocumentUploadStatus.notUploaded,
    'photo': DocumentUploadStatus.notUploaded,
  };

  final Map<String, String?> _docFiles = {
    'id': null,
    'police': null,
    'cpr': null,
    'photo': null,
  };

  // Form Keys
  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();
  final _skillsFormKey = GlobalKey<FormState>();

  // Personal Info Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDob;
  String _selectedGender = 'Female';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Professional Info Controllers
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController(text: '3');
  final _hourlyRateController = TextEditingController(text: '25');

  // Languages & Skills
  final List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Mandarin',
    'Arabic',
    'Sign Language'
  ];
  final Set<String> _selectedLanguages = {'English'};

  final List<String> _availableSkills = [
    'Infant care',
    'Toddler care',
    'First aid & CPR',
    'Meal preparation',
    'Homework help',
    'Special needs care',
    'Bedtime routines',
    'Child activities',
    'Creative arts',
    'Potty training',
  ];
  final Set<String> _selectedSkills = {'Infant care', 'First aid & CPR'};

  final List<String> _availableAgeGroups = [
    'Infants (0-1 yr)',
    'Toddlers (1-3 yrs)',
    'Preschoolers (3-5 yrs)',
    'School-age (5+ yrs)'
  ];
  final Set<String> _selectedAgeGroups = {'Infants (0-1 yr)', 'Toddlers (1-3 yrs)'};

  // Qualifications
  final List<String> _qualifications = [
    'CPR & Pediatric First Aid (Red Cross)',
    'Early Childhood Education Associate',
  ];
  final _qualificationInputController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDob = DateTime(1998, 6, 15);
  }

  void _fillSampleData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    setState(() {
      _firstNameController.text = 'Maya';
      _lastNameController.text = 'Johnson';
      _emailController.text = 'maya.johnson$timestamp@example.com';
      _phoneController.text = '+1 (555) 234-8901';
      _passwordController.text = 'Password123!';
      _confirmPasswordController.text = 'Password123!';
      _addressController.text = '142 Park Avenue, Brooklyn, NY';
      _selectedDob = DateTime(1996, 5, 14);
      _selectedGender = 'Female';
      _bioController.text =
          'Certified early childhood educator with 4 years of babysitting experience.';
      _experienceController.text = '4';
      _hourlyRateController.text = '28';
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _qualificationInputController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) return;
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (!_professionalFormKey.currentState!.validate()) return;
      if (_selectedLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one language')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one skill')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      if (_docStatuses['id'] == DocumentUploadStatus.notUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload at least your Government ID before submitting.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
      }
      _submitRegistration();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);

    final registrationData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'dateOfBirth': _selectedDob?.toIso8601String().split('T').first,
      'gender': _selectedGender,
      'address': _addressController.text.trim(),
      'bio': _bioController.text.trim(),
      'experienceYears': int.tryParse(_experienceController.text) ?? 2,
      'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 25.0,
      'languages': _selectedLanguages.toList(),
      'skills': _selectedSkills.toList(),
      'ageGroups': _selectedAgeGroups.toList(),
      'qualifications': _qualifications,
    };

    final success =
        await BabysitterProvider.instance.registerSitter(registrationData);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BabysitterProvider.instance.errorMessage ??
                'Registration failed. Please try again.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.teal,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your babysitter registration was received. Our verification team will review your credentials within 24-48 hours.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.sitterDashboard);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Sitter Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: _onBack,
        ),
        title: const Text(
          'Babysitter Registration',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar & Step Indicators
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps: ${_stepTitle(_currentStep)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      minHeight: 6,
                      backgroundColor: AppColors.sand,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.teal),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.sand),

            // Step Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  if (_currentStep == 0) _buildPersonalDetailsStep(),
                  if (_currentStep == 1) _buildProfessionalDetailsStep(),
                  if (_currentStep == 2) _buildSkillsAndQualificationsStep(),
                  if (_currentStep == 3) _buildDocumentsStep(),
                ],
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _onBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.ink),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Submit Application'
                                  : 'Continue',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Professional Info';
      case 2:
        return 'Skills & Qualifications';
      case 3:
        return 'Verification Documents';
      default:
        return '';
    }
  }

  void _simulateUpload(String docKey, String defaultFileName) async {
    setState(() {
      _docStatuses[docKey] = DocumentUploadStatus.uploading;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _docStatuses[docKey] = DocumentUploadStatus.uploaded;
        _docFiles[docKey] = defaultFileName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$defaultFileName uploaded successfully!'),
          backgroundColor: AppColors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Verification Documents',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            VerificationBadge(status: 'pending', compact: true),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Please submit official verification files. Verified sitters receive up to 4x more booking requests.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        DocumentUploadCard(
          title: 'National ID / Passport',
          description: 'Official government-issued photo ID (front and back).',
          icon: Icons.badge_outlined,
          status: _docStatuses['id']!,
          fileName: _docFiles['id'],
          onUpload: () => _simulateUpload('id', 'national_id_card.pdf'),
          onRemove: () => setState(() {
            _docStatuses['id'] = DocumentUploadStatus.notUploaded;
            _docFiles['id'] = null;
          }),
        ),
        DocumentUploadCard(
          title: 'Police Clearance / Background Check',
          description:
              'Official criminal record check issued within the last 12 months.',
          icon: Icons.security_rounded,
          status: _docStatuses['police']!,
          fileName: _docFiles['police'],
          onUpload: () =>
              _simulateUpload('police', 'police_clearance_certificate.pdf'),
          onRemove: () => setState(() {
            _docStatuses['police'] = DocumentUploadStatus.notUploaded;
            _docFiles['police'] = null;
          }),
        ),
        DocumentUploadCard(
          title: 'CPR & First Aid Certificate',
          description:
              'Valid pediatric CPR & First Aid certificate from an accredited provider.',
          icon: Icons.medical_services_outlined,
          status: _docStatuses['cpr']!,
          fileName: _docFiles['cpr'],
          onUpload: () => _simulateUpload('cpr', 'cpr_redcross_cert.pdf'),
          onRemove: () => setState(() {
            _docStatuses['cpr'] = DocumentUploadStatus.notUploaded;
            _docFiles['cpr'] = null;
          }),
        ),
        DocumentUploadCard(
          title: 'Profile Photograph',
          description:
              'Clear, high-resolution front-facing photo with a neutral background.',
          icon: Icons.camera_alt_outlined,
          status: _docStatuses['photo']!,
          fileName: _docFiles['photo'],
          onUpload: () =>
              _simulateUpload('photo', 'profile_photo_headshot.jpg'),
          onRemove: () => setState(() {
            _docStatuses['photo'] = DocumentUploadStatus.notUploaded;
            _docFiles['photo'] = null;
          }),
        ),
      ],
    );
  }

  // STEP 1: Personal Details
  Widget _buildPersonalDetailsStep() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              TextButton.icon(
                onPressed: _fillSampleData,
                icon: const Icon(Icons.auto_fix_high_rounded,
                    size: 16, color: AppColors.teal),
                label: const Text(
                  'Auto-fill',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Provide your legal contact and identity details to help parents feel safe.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // First & Last Name
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Maya',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Johnson',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'maya@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+1 (555) 019-2834',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Phone number is required' : null,
          ),
          const SizedBox(height: 16),

          // Passwords
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.muted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: '••••••••',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.muted,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth & Gender
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDob == null
                              ? 'Date of Birth'
                              : '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _selectedDob == null
                                ? AppColors.muted
                                : AppColors.ink,
                            fontSize: 15,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.teal),
                      items: const [
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address
          _buildTextField(
            controller: _addressController,
            label: 'Street Address',
            hint: '24 Elm Street, Brooklyn, NY',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Address is required' : null,
          ),
        ],
      ),
    );
  }

  // STEP 2: Professional Details
  Widget _buildProfessionalDetailsStep() {
    return Form(
      key: _professionalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell parents about your childcare background, experience, and hourly pricing.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Bio
          _buildTextField(
            controller: _bioController,
            label: 'Biography / About Me',
            hint:
                'Describe your passion for childcare, routine handling, philosophy, and background...',
            maxLines: 4,
            validator: (v) {
              if (v == null || v.trim().length < 20) {
                return 'Please write at least 20 characters for your bio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Years Experience & Hourly Rate
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _experienceController,
                  label: 'Experience (Years)',
                  hint: '3',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.work_outline_rounded,
                      size: 20, color: AppColors.teal),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Invalid years';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField(
                  controller: _hourlyRateController,
                  label: 'Hourly Rate (\$ / hr)',
                  hint: '25',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      size: 20, color: AppColors.teal),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Languages Spoken
          const Text(
            'Languages Spoken',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return FilterChip(
                selected: isSelected,
                label: Text(lang),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                selectedColor: AppColors.teal,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.teal : AppColors.sand,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(lang);
                    } else {
                      _selectedLanguages.remove(lang);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Age Groups Cared For
          const Text(
            'Age Groups Cared For',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAgeGroups.map((age) {
              final isSelected = _selectedAgeGroups.contains(age);
              return FilterChip(
                selected: isSelected,
                label: Text(age),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                selectedColor: AppColors.ink,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.ink : AppColors.sand,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAgeGroups.add(age);
                    } else {
                      _selectedAgeGroups.remove(age);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 3: Skills & Qualifications
  Widget _buildSkillsAndQualificationsStep() {
    return Form(
      key: _skillsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Certifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Highlight your specializations and verified qualifications to attract verified families.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Skills Chips
          const Text(
            'Core Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                selected: isSelected,
                label: Text(skill),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                selectedColor: AppColors.teal,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.teal : AppColors.sand,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Qualifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Qualifications & Certifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${_qualifications.length} added',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Qualification List
          ..._qualifications.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mint),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.teal, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.muted),
                    onPressed: () =>
                        setState(() => _qualifications.removeAt(entry.key)),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          // Add Qualification Field
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _qualificationInputController,
                  label: 'Add Certificate / Diploma',
                  hint: 'e.g. Pediatric First Aid',
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: () {
                    final text = _qualificationInputController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _qualifications.add(text);
                        _qualificationInputController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      enableInteractiveSelection: true,
      enabled: true,
      autocorrect: false,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.2),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 22)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }
}
