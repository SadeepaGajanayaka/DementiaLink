import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AssistLoved extends StatefulWidget {
  final String userName;
  
  const AssistLoved({super.key, required this.userName});

  @override
  State<AssistLoved> createState() => _AssistLovedState();
}

class _AssistLovedState extends State<AssistLoved> {
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isSubmitting = false;
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _otherSymptomsController = TextEditingController();
  final _otherNeedsController = TextEditingController();
  
  // Dropdown selections
  String _selectedGender = 'Male';
  String _selectedRelation = 'Father';

  // Symptoms checklist
  Map<String, bool> symptoms = {
    'Forgetfulness': false,
    'Aggressiveness': false,
    'Disorientation': false,
    'Empathy': false,
    'Personality Changes': false,
  };

  // Needs checklist
  Map<String, bool> needs = {
    'Physical stimulation': false,
    'Social stimulation': false,
    'Daily routine': false,
    'Personal care': false,
    'Cognitive stimulation': false,
    'Personality Changes': false,
  };

  bool _otherSymptomsChecked = false;
  bool _otherNeedsChecked = false;

  // Collect form data to save to Firebase
  Map<String, dynamic> _collectFormData() {
    // Get selected symptoms
    List<String> selectedSymptoms = [];
    symptoms.forEach((key, value) {
      if (value) {
        selectedSymptoms.add(key);
      }
    });
    
    // Get selected needs
    List<String> selectedNeeds = [];
    needs.forEach((key, value) {
      if (value) {
        selectedNeeds.add(key);
      }
    });
    
    return {
      'basic_information': {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'gender': _selectedGender,
        'date_of_birth': _dateController.text,
      },
      'relationship': {
        'relation_to_caregiver': _selectedRelation,
      },
      'symptoms': {
        'selected_symptoms': selectedSymptoms,
        'other_symptoms': _otherSymptomsChecked ? _otherSymptomsController.text : '',
      },
      'needs': {
        'selected_needs': selectedNeeds,
        'other_needs': _otherNeedsChecked ? _otherNeedsController.text : '',
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
                        'Loved One Registration',
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

                        // Name Section
                        _buildQuestionBox(
                          'What is your loved one\'s name?',
                          Column(
                            children: [
                              _buildTextInput('First Name', controller: _firstNameController),
                              const SizedBox(height: 12),
                              _buildTextInput('Last Name', controller: _lastNameController),
                            ],
                          ),
                        ),

                        // Gender Section
                        _buildQuestionBox(
                          'What is their gender?',
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

                        // Date of Birth Section
                        _buildQuestionBox(
                          'What is their date of birth?',
                          _buildTextInput(
                            'MM/DD/YYYY',
                            controller: _dateController,
                            onTap: () => _selectDate(context),
                            readOnly: true,
                            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF77588D)),
                          ),
                        ),

                        // Relation Section
                        _buildQuestionBox(
                          'What is your relation to them?',
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
                                items: ['Father', 'Mother', 'Spouse', 'Son', 'Daughter', 'Other']
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

                        // Symptoms Section
                        _buildQuestionBox(
                          'What symptoms does your loved one have?',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: symptoms.keys.map((String key) {
                                  return SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: symptoms[key],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                symptoms[key] = value ?? false;
                                              });
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
                                        Expanded(
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _otherSymptomsChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _otherSymptomsChecked = value ?? false;
                                        });
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
                                    'Other: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _otherSymptomsController,
                                      enabled: _otherSymptomsChecked,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white, width: 2),
                                        ),
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Needs Section
                        _buildQuestionBox(
                          'What are the main needs of your loved one?',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: needs.keys.map((String key) {
                                  return SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: needs[key],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                needs[key] = value ?? false;
                                              });
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
                                        Expanded(
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _otherNeedsChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _otherNeedsChecked = value ?? false;
                                        });
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
                                    'Other: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _otherNeedsController,
                                      enabled: _otherNeedsChecked,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white, width: 2),
                                        ),
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                                    formType: 'loved_one',  // This is for "Assist Loved One"
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
}