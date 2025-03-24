import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AssistMe extends StatefulWidget {
  final String userName;
  
  const AssistMe({super.key, required this.userName});

  @override
  State<AssistMe> createState() => _AssistMeState();
}

class _AssistMeState extends State<AssistMe> {
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isSubmitting = false;
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  
  // New controllers for additional fields
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  final _diagnosingDoctorController = TextEditingController();
  final _otherMedicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _routineController = TextEditingController();
  final _caregiverNameController = TextEditingController();
  final _caregiverContactController = TextEditingController();
  
  // Dropdown selections
  String _selectedGender = 'Male';
  String _selectedRelation = 'Father';
  String _selectedDementiaStage = 'Early';
  String _selectedLanguage = 'English';
  String _selectedAppComfort = 'Somewhat comfortable';
  
  // Yes/No selections
  bool _hasOtherMedicalConditions = false;
  bool _hasMedications = false;
  bool _hasAllergies = false;
  bool _hasDifficultyRemembering = false;
  bool _needsAssistance = false;
  bool _hasRoutine = false;
  bool _hasPrimaryCaregiver = false;

  // Collect form data to save to Firebase
  Map<String, dynamic> _collectFormData() {
    return {
      'basic_information': {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'gender': _selectedGender,
        'date_of_birth': _dateController.text,
        'contact_number': _contactNumberController.text,
        'address': _addressController.text,
        'emergency_contact': {
          'name': _emergencyNameController.text,
          'phone': _emergencyNumberController.text,
        },
      },
      'medical_information': {
        'dementia_stage': _selectedDementiaStage,
        'diagnosing_doctor': _diagnosingDoctorController.text,
        'other_medical_conditions': {
          'has_conditions': _hasOtherMedicalConditions,
          'conditions': _otherMedicalConditionsController.text,
        },
        'medications': {
          'taking_medications': _hasMedications,
          'medications_list': _medicationsController.text,
        },
        'allergies': {
          'has_allergies': _hasAllergies,
          'allergies_list': _allergiesController.text,
        },
        'preferred_language': _selectedLanguage,
      },
      'cognitive_daily_activity': {
        'difficulty_remembering': _hasDifficultyRemembering,
        'needs_assistance': _needsAssistance,
        'preferred_routine': {
          'has_routine': _hasRoutine,
          'routine_description': _routineController.text,
        },
        'app_comfort': _selectedAppComfort,
      },
      'caregiver': {
        'has_primary_caregiver': _hasPrimaryCaregiver,
        'caregiver_name': _caregiverNameController.text,
        'caregiver_contact': _caregiverContactController.text,
        'relation': _selectedRelation,
      },
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF77588D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF503663),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF77588D),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF77588D),
              Color(0xFF503663),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Patient Registration Form',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'lib/assets/patient_profile.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // BASIC INFORMATION SECTION
                        _buildSectionHeader('Basic Information'),

                        // Name Section
                        _buildQuestionBox(
                          'Full Name',
                          Column(
                            children: [
                              _buildTextInput('First Name', controller: _firstNameController),
                              const SizedBox(height: 12),
                              _buildTextInput('Last Name', controller: _lastNameController),
                            ],
                          ),
                        ),

                        // Date of Birth Section
                        _buildQuestionBox(
                          'Date of Birth',
                          _buildTextInput(
                            'MM/DD/YYYY',
                            controller: _dateController,
                            onTap: () => _selectDate(context),
                            readOnly: true,
                            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF77588D)),
                          ),
                        ),

                        // Gender Section
                        _buildQuestionBox(
                          'Gender',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedGender,
                                style: const TextStyle(
                                  color: Color(0xFF503663),
                                  fontSize: 16,
                                ),
                                items: ['Male', 'Female', 'Other']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedGender = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Contact Number
                        _buildQuestionBox(
                          'Contact Number (optional if caregiver is managing)',
                          _buildTextInput('Phone Number', controller: _contactNumberController),
                        ),
                        
                        // Address
                        _buildQuestionBox(
                          'Address',
                          _buildTextInput('Full Address', controller: _addressController),
                        ),
                        
                        // Emergency Contact
                        _buildQuestionBox(
                          'Emergency Contact',
                          Column(
                            children: [
                              _buildTextInput('Name', controller: _emergencyNameController),
                              const SizedBox(height: 12),
                              _buildTextInput('Phone Number', controller: _emergencyNumberController),
                            ],
                          ),
                        ),
                        
                        // MEDICAL INFORMATION SECTION
                        _buildSectionHeader('Medical Information'),
                        
                        // Dementia Diagnosis Stage
                        _buildQuestionBox(
                          'Dementia Diagnosis Stage',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDementiaStage,
                                style: const TextStyle(
                                  color: Color(0xFF503663),
                                  fontSize: 16,
                                ),
                                items: ['Early', 'Moderate', 'Severe']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedDementiaStage = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Diagnosing Doctor/Hospital
                        _buildQuestionBox(
                          'Diagnosing Doctor/Hospital (optional)',
                          _buildTextInput('Doctor or Hospital Name', controller: _diagnosingDoctorController),
                        ),
                        
                        // Other Medical Conditions
                        _buildQuestionBox(
                          'Any other medical conditions?',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildYesNoSelection(
                                value: _hasOtherMedicalConditions,
                                onChanged: (value) {
                                  setState(() {
                                    _hasOtherMedicalConditions = value;
                                  });
                                },
                              ),
                              if (_hasOtherMedicalConditions) ...[
                                const SizedBox(height: 12),
                                _buildTextInput(
                                  'Specify medical conditions',
                                  controller: _otherMedicalConditionsController,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Medications
                        _buildQuestionBox(
                          'Medications currently taking',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildYesNoSelection(
                                value: _hasMedications,
                                onChanged: (value) {
                                  setState(() {
                                    _hasMedications = value;
                                  });
                                },
                              ),
                              if (_hasMedications) ...[
                                const SizedBox(height: 12),
                                _buildTextInput(
                                  'List medications',
                                  controller: _medicationsController,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Allergies
                        _buildQuestionBox(
                          'Allergies',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildYesNoSelection(
                                value: _hasAllergies,
                                onChanged: (value) {
                                  setState(() {
                                    _hasAllergies = value;
                                  });
                                },
                              ),
                              if (_hasAllergies) ...[
                                const SizedBox(height: 12),
                                _buildTextInput(
                                  'Specify allergies',
                                  controller: _allergiesController,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Preferred Language
                        _buildQuestionBox(
                          'Preferred Language',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedLanguage,
                                style: const TextStyle(
                                  color: Color(0xFF503663),
                                  fontSize: 16,
                                ),
                                items: ['English', 'Spanish', 'French', 'Mandarin', 'Arabic', 'Other']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLanguage = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        // COGNITIVE & DAILY ACTIVITY SECTION
                        _buildSectionHeader('Cognitive & Daily Activity Information'),
                        
                        // Difficulty Remembering
                        _buildQuestionBox(
                          'Do you experience difficulty in remembering daily tasks?',
                          _buildYesNoSelection(
                            value: _hasDifficultyRemembering,
                            onChanged: (value) {
                              setState(() {
                                _hasDifficultyRemembering = value;
                              });
                            },
                          ),
                        ),
                        
                        // Need Assistance
                        _buildQuestionBox(
                          'Do you need assistance with daily activities?',
                          _buildYesNoSelection(
                            value: _needsAssistance,
                            onChanged: (value) {
                              setState(() {
                                _needsAssistance = value;
                              });
                            },
                          ),
                        ),
                        
                        // Preferred Routine
                        _buildQuestionBox(
                          'Do you have a preferred routine for daily activities?',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildYesNoSelection(
                                value: _hasRoutine,
                                onChanged: (value) {
                                  setState(() {
                                    _hasRoutine = value;
                                  });
                                },
                              ),
                              if (_hasRoutine) ...[
                                const SizedBox(height: 12),
                                _buildTextInput(
                                  'Describe your routine briefly',
                                  controller: _routineController,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // App Comfort
                        _buildQuestionBox(
                          'How comfortable are you with using mobile applications?',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedAppComfort,
                                style: const TextStyle(
                                  color: Color(0xFF503663),
                                  fontSize: 16,
                                ),
                                items: ['Not comfortable', 'Somewhat comfortable', 'Very comfortable']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedAppComfort = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // CAREGIVER ASSIGNMENT SECTION
                        _buildSectionHeader('Caregiver Assignment'),
                        
                        // Primary Caregiver
                        _buildQuestionBox(
                          'Do you have a primary caregiver?',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildYesNoSelection(
                                value: _hasPrimaryCaregiver,
                                onChanged: (value) {
                                  setState(() {
                                    _hasPrimaryCaregiver = value;
                                  });
                                },
                              ),
                              if (_hasPrimaryCaregiver) ...[
                                const SizedBox(height: 12),
                                _buildTextInput('Caregiver\'s Name', controller: _caregiverNameController),
                                const SizedBox(height: 12),
                                _buildTextInput('Caregiver\'s Contact', controller: _caregiverContactController),
                              ],
                            ],
                          ),
                        ),
                        
                        // Relation Section
                        _buildQuestionBox(
                          'Relation to care giver',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedRelation,
                                style: const TextStyle(
                                  color: Color(0xFF503663),
                                  fontSize: 16,
                                ),
                                items: ['Father', 'Mother', 'Spouse', 'Other']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedRelation = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () async {
                              // Validate required fields
                              if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill out required fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              setState(() {
                                _isSubmitting = true;
                              });
                              
                              try {
                                final userId = _authService.currentUser?.uid;
                                if (userId != null) {
                                  // Collect data from form
                                  final formData = _collectFormData();
                                  
                                  // Save to Firebase
                                  final patientId = await _databaseService.savePatientData(
                                    userId: userId,
                                    formType: 'self',  // This is for "Assist Me"
                                    patientData: formData,
                                  );
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Information saved successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } else {
                                  throw Exception('User not authenticated');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF77588D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF77588D),
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'SUBMIT',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestionBox(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildTextInput(String hint, {
    TextEditingController? controller,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(
          color: Color(0xFF503663),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildYesNoSelection({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        // Yes option
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
                fillColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Colors.white
                      : Colors.white,
                ),
                checkColor: const Color(0xFF77588D),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Yes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(width: 32),
        // No option
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: !value,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    onChanged(!newValue);
                  }
                },
                fillColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Colors.white
                      : Colors.white,
                ),
                checkColor: const Color(0xFF77588D),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'No',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}