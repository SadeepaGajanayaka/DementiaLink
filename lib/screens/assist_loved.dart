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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _placesLivedController = TextEditingController();
  
  // Dropdown selections
  String _selectedGender = 'Female';
  String _selectedRelation = 'Father';

  // Collect form data to save to Firebase
  Map<String, dynamic> _collectFormData() {
    return {
      'basic_information': {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'gender': _selectedGender,
        'date_of_birth': _dateController.text,
        'places_lived': _placesLivedController.text,
      },
      'relationship': {
        'relation_to_caregiver': _selectedRelation,
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF77588D),
              Color(0xFF503663),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name Section
                  _buildQuestionBox(
                    'What is your name ?',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'First Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextInput('', controller: _firstNameController),
                        const SizedBox(height: 12),
                        const Text(
                          'Last Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextInput('', controller: _lastNameController),
                      ],
                    ),
                  ),

                  // Email Section
                  _buildQuestionBox(
                    'What is your email ?',
                    _buildTextInput('', controller: _emailController),
                  ),

                  // Phone Section
                  _buildQuestionBox(
                    'What is your phone number ?',
                    _buildTextInput('', controller: _phoneController),
                  ),

                  // Gender Section
                  _buildQuestionBox(
                    'What is your gender?',
                    Container(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            isExpanded: true,
                            value: _selectedGender,
                            style: const TextStyle(
                              color: Color(0xFF503663),
                              fontSize: 14,
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
                  ),

                  // Date of Birth Section
                  _buildQuestionBox(
                    'What is your date of birth ?',
                    Container(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Text(
                            _dateController.text.isEmpty ? 'MM/DD/YYYY' : _dateController.text,
                            style: TextStyle(
                              color: _dateController.text.isEmpty ? Colors.grey[400] : const Color(0xFF503663),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Places Lived Section
                  _buildQuestionBox(
                    'Places Lived',
                    _buildTextInput('', controller: _placesLivedController),
                  ),

                  // Relation Section
                  _buildQuestionBox(
                    'Relation to care giver ?',
                    Container(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            isExpanded: true,
                            value: _selectedRelation,
                            style: const TextStyle(
                              color: Color(0xFF503663),
                              fontSize: 14,
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
                  ),

                  const SizedBox(height: 24),
                  // Confirm Button
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
                            await _databaseService.savePatientData(
                              userId: userId,
                              formType: 'profile',
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
                              'CONFIRM',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBox(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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