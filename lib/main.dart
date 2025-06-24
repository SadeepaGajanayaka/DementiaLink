import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeedbackScreen(),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  @override
  FeedbackScreenState createState() => FeedbackScreenState();
}

class FeedbackScreenState extends State<FeedbackScreen> {
  String? selectedUserType;
  String emailText = '';
  int usefulnessRating = 0;
  int easeOfUseRating = 0;

  TextEditingController emailController = TextEditingController();

  final List<String> userTypeOptions = [
    'Person with dementia',
    'Family caregiver',
    'Professional caregiver',
    'Healthcare provider',
    'Family member/friend',
  ];

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(25),
              margin: EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4CAF50), // Green
                    Color(0xFF45a049), // Darker green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '🧠 Dementia Support App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Help us improve with your feedback',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "We value your feedback! 💬",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      _buildSectionHeader('👤 About You'),
                      SizedBox(height: 20),

                      _buildLabel('I am a: *'),
                      SizedBox(height: 8),
                      _buildDropdown(),
                      SizedBox(height: 20),

                      // Show selected value
                      if (selectedUserType != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            '✅ You selected: $selectedUserType',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),

                      _buildLabel('Email (optional):'),
                      SizedBox(height: 8),
                      _buildEmailField(),
                      SizedBox(height: 20),

                      // Email validation helper
                      if (emailText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isValidEmail(emailText) ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isValidEmail(emailText) ? Colors.green.shade300 : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isValidEmail(emailText) ? Icons.check_circle : Icons.error,
                                color: _isValidEmail(emailText) ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isValidEmail(emailText)
                                    ? 'Email format looks good!'
                                    : 'Please enter a valid email format',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isValidEmail(emailText) ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 30),

                      _buildSectionHeader('⭐ Rate the App'),
                      SizedBox(height: 20),

                      // Usefulness Rating
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How useful would this app be for you?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildStarRating(
                              currentRating: usefulnessRating,
                              onRatingChanged: (rating) {
                                setState(() {
                                  usefulnessRating = rating;
                                });
                                print('Usefulness rating: $rating stars');
                              },
                            ),
                            SizedBox(height: 10),
                            if (usefulnessRating > 0)
                              Text(
                                'You rated: $usefulnessRating star${usefulnessRating == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Ease of Use Rating
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How easy is the app to use?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildStarRating(
                              currentRating: easeOfUseRating,
                              onRatingChanged: (rating) {
                                setState(() {
                                  easeOfUseRating = rating;
                                });
                                print('Ease of use rating: $rating stars');
                              },
                            ),
                            SizedBox(height: 10),
                            if (easeOfUseRating > 0)
                              Text(
                                'You rated: $easeOfUseRating star${easeOfUseRating == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // Current Form Data Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📝 Current Form Data:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'User Type: ${selectedUserType ?? "Not selected"}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple.shade600,
                              ),
                            ),
                            Text(
                              'Email: ${emailText.isEmpty ? "Not entered" : emailText}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple.shade600,
                              ),
                            ),
                            Text(
                              'Usefulness: ${usefulnessRating == 0 ? "Not rated" : "$usefulnessRating stars"}',
                              style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
                            ),
                            Text(
                              'Ease of Use: ${easeOfUseRating == 0 ? "Not rated" : "$easeOfUseRating stars"}',
                              style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      Center(
                        child: Text(
                          'Your input helps us create better tools for dementia care and support.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedUserType,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        hintText: 'Please select your role...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      items: userTypeOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedUserType = newValue;
        });
        print('User selected: $newValue');
      },
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        hintText: 'your.email@example.com',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.grey.shade500,
        ),
      ),
      onChanged: (String value) {
        setState(() {
          emailText = value;
        });
        print('Email typed: $emailText');
      },
    );
  }

  Widget _buildStarRating({
    required int currentRating,
    required Function(int) onRatingChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        int starNumber = index + 1;
        bool isSelected = starNumber <= currentRating;

        return GestureDetector(
          onTap: () {
            onRatingChanged(starNumber);
          },
          child: Container(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.star,
              size: 40,
              color: isSelected ? Colors.amber : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}