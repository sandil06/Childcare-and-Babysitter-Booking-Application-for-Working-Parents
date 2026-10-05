import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/babysitter_model.dart';
import '../providers/babysitter_provider.dart';

class EditSitterProfileScreen extends StatefulWidget {
  const EditSitterProfileScreen({super.key, required this.profile});

  final BabysitterModel profile;

  @override
  State<EditSitterProfileScreen> createState() =>
      _EditSitterProfileScreenState();
}

class _EditSitterProfileScreenState extends State<EditSitterProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bioController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _experienceController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final _qualificationInputController = TextEditingController();

  late Set<String> _selectedSkills;
  late Set<String> _selectedLanguages;
  late List<String> _qualifications;
  late List<VerificationDocumentModel> _documents;
  final _docNameController = TextEditingController();
  String _selectedDocType = 'id';
  final Map<String, String> _docTypeLabels = {
    'id': 'National ID / NIC',
    'police_check': 'Police Background Check',
    'qualification': 'Childcare Certificate / Degree',
    'certificate': 'First Aid / CPR Certification',
    'other': 'Other Document',
  };

  final List<String> _allSkills = [
    'Infant Care',
    'Toddler Care',
    'First Aid & CPR',
    'Meal Preparation',
    'Homework Help',
    'Special Needs Care',
    'Bedtime Routines',
    'Child Activities',
    'Creative Arts',
    'Potty Training',
  ];

  final List<String> _allLanguages = [
    'Sinhala',
    'English',
    'Tamil',
    'French',
    'German',
    'Mandarin',
    'Arabic',
    'Sign Language',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.profile.bio);
    _hourlyRateController =
        TextEditingController(text: widget.profile.hourlyRate.toStringAsFixed(0));
    _experienceController =
        TextEditingController(text: widget.profile.experienceYears.toString());
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);

    _selectedSkills = Set.from(widget.profile.skills);
    _selectedLanguages = Set.from(widget.profile.languages);
    _qualifications = List.from(widget.profile.qualifications);
    _documents = List.from(widget.profile.documents);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _qualificationInputController.dispose();
    _docNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final pendingQual = _qualificationInputController.text.trim();
    if (pendingQual.isNotEmpty && !_qualifications.contains(pendingQual)) {
      _qualifications.add(pendingQual);
      _qualificationInputController.clear();
    }

    final pendingDoc = _docNameController.text.trim();
    if (pendingDoc.isNotEmpty) {
      _documents.add(
        VerificationDocumentModel(
          type: _selectedDocType,
          name: pendingDoc,
          status: 'pending',
          uploadedAt: DateTime.now(),
        ),
      );
      _docNameController.clear();
    }

    final updateData = {
      'bio': _bioController.text.trim(),
      'hourlyRate': double.tryParse(_hourlyRateController.text) ?? widget.profile.hourlyRate,
      'experienceYears': int.tryParse(_experienceController.text) ?? widget.profile.experienceYears,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'skills': _selectedSkills.toList(),
      'languages': _selectedLanguages.isEmpty ? ['English'] : _selectedLanguages.toList(),
      'qualifications': _qualifications,
      'documents': _documents.map((d) => d.toJson()).toList(),
    };

    final success = await BabysitterProvider.instance.updateProfile(updateData);

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.teal,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BabysitterProvider.instance.errorMessage ??
                'Failed to update profile'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
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
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            children: [
              // System managed info note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.teal, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verification status, ratings, and total reviews are verified by admin and cannot be edited manually.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hourly Rate & Experience
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _hourlyRateController,
                      label: 'Hourly Rate (Rs./hr)',
                      hint: '1500',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.currency_rupee_rounded,
                          color: AppColors.teal, size: 20),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildInput(
                      controller: _experienceController,
                      label: 'Experience (Yrs)',
                      hint: '4',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.work_outline_rounded,
                          color: AppColors.teal, size: 20),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bio
              _buildInput(
                controller: _bioController,
                label: 'Biography / About Me',
                hint: 'Describe your experience, approach, and care style...',
                maxLines: 4,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && v.trim().length < 5) {
                    return 'Please enter at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact fields
              _buildInput(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+94 77 123 4567',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.teal, size: 20),
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _addressController,
                label: 'Street Address & City',
                hint: 'No. 45, Galle Road, Colombo 03',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.teal, size: 20),
              ),
              const SizedBox(height: 24),

              // Skills Selection
              const Text(
                'Skills & Care Capabilities',
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
                children: _allSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(skill),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
              const SizedBox(height: 24),

              // Languages
              const Text(
                'Languages',
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
                children: _allLanguages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(lang),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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

              // Qualifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Qualifications & Certificates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${_qualifications.length} items',
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._qualifications.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sand),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 18, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _qualificationInputController,
                      label: 'Add Certificate',
                      hint: 'e.g. Infant CPR Certified',
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
                        final val = _qualificationInputController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            _qualifications.add(val);
                            _qualificationInputController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verification Documents
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verification Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${_documents.length} items',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_documents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sand),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.muted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No documents added yet. Add your NIC, Police Clearance, or CPR certificate below.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ..._documents.asMap().entries.map((entry) {
                final doc = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sand),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined,
                          size: 20, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              _docTypeLabels[doc.type] ?? doc.type,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: doc.status == 'verified'
                              ? AppColors.mint
                              : AppColors.sand.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doc.status == 'verified' ? 'Verified' : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: doc.status == 'verified'
                                ? AppColors.teal
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.muted),
                        onPressed: () =>
                            setState(() => _documents.removeAt(entry.key)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              // Document Type Selector & Add Document Form
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sand),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Verification Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDocType,
                      decoration: InputDecoration(
                        labelText: 'Document Type',
                        labelStyle:
                            const TextStyle(color: AppColors.muted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _docTypeLabels.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDocType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _docNameController,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.ink),
                            decoration: InputDecoration(
                              labelText: 'Document Title / Details',
                              hintText: 'e.g. NIC 200184501234',
                              labelStyle: const TextStyle(
                                  color: AppColors.muted, fontSize: 13),
                              hintStyle: TextStyle(
                                  color: AppColors.muted.withValues(alpha: 0.6),
                                  fontSize: 13),
                              filled: true,
                              fillColor: AppColors.cream,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () {
                            final name = _docNameController.text.trim();
                            if (name.isNotEmpty) {
                              setState(() {
                                _documents.add(
                                  VerificationDocumentModel(
                                    type: _selectedDocType,
                                    name: name,
                                    status: 'pending',
                                    uploadedAt: DateTime.now(),
                                  ),
                                );
                                _docNameController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
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
}
