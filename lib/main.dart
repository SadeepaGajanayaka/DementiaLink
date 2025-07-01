import 'package:dementialink/EmailService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';





main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dementia Support Feedback',
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
  String feedbackText = '';

  int usefulnessRating = 0;
  int easeOfUseRating = 0;
  bool isSubmitting = false;
  bool hasSubmitted = false;

  Map<String, bool> selectedFeatures = {
    'Memory exercises and games': false,
    'Medication reminders': false,
    'Daily routine planner': false,
    'GPS location tracking': false,
    'Large text and buttons': false,
  };

  TextEditingController emailController = TextEditingController();
  TextEditingController feedbackController = TextEditingController();

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
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8B5FBF),
                    Color(0xFF6A4C93),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Dementia Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Share your feedback to help us improve',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSubmitted)
                      _buildSuccessMessage()
                    else ...[
                      _buildSectionCard(
                        '👤 About You',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('I am a: *'),
                            SizedBox(height: 12),
                            _buildDropdown(),
                            SizedBox(height: 20),
                            _buildLabel('Email (optional):'),
                            SizedBox(height: 12),
                            _buildEmailField(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      _buildSectionCard(
                        '⭐ Rate the App',
                        Column(
                          children: [
                            _buildRatingCard(
                              'How useful would this app be for you?',
                              usefulnessRating,
                              Color(0xFFFFF3E0),
                              Color(0xFFFF9800),
                                  (rating) {
                                setState(() {
                                  usefulnessRating = rating;
                                });
                              },
                            ),

                            SizedBox(height: 20),

                            _buildRatingCard(
                              'How easy is the app to use?',
                              easeOfUseRating,
                              Color(0xFFE3F2FD),
                              Color(0xFF2196F3),
                                  (rating) {
                                setState(() {
                                  easeOfUseRating = rating;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      _buildSectionCard(
                        '✅ Features You Want',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Which features would be most helpful?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF424242),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            ...selectedFeatures.keys.map((feature) =>
                                _buildFeatureCheckbox(feature)
                            ).toList(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      _buildSectionCard(
                        '💭 Your Feedback',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tell us more about your thoughts (optional):',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF424242),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildFeedbackTextField(),
                            SizedBox(height: 12),
                            Text(
                              'Share your suggestions and ideas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      _buildSubmitButton(),

                      SizedBox(height: 32),

                      // Bottom message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          '💜 Your input helps us create better tools for dementia care and support.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B5FBF),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5FBF).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF8B5FBF).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5FBF),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(String question, int rating, Color bgColor, Color accentColor, Function(int) onChanged) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 16),
          _buildStarRating(
            currentRating: rating,
            onRatingChanged: onChanged,
            starColor: accentColor,
          ),
          if (rating > 0)
            SizedBox(height: 12),
          if (rating > 0)
            Text(
              'You rated: $rating star${rating == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCheckbox(String feature) {
    bool isSelected = selectedFeatures[feature]!;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            selectedFeatures[feature] = !selectedFeatures[feature]!;
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF8B5FBF).withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Color(0xFF8B5FBF) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF8B5FBF) : Colors.white,
                  border: Border.all(
                    color: isSelected ? Color(0xFF8B5FBF) : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? Color(0xFF8B5FBF) : Color(0xFF424242),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
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
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedUserType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Please select your role...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        items: userTypeOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedUserType = newValue;
          });
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'your.email@example.com',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF8B5FBF)),
        ),
        onChanged: (String value) {
          setState(() {
            emailText = value;
          });
        },
      ),
    );
  }

  Widget _buildFeedbackTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: feedbackController,
        maxLines: 5,
        maxLength: 500,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: 'What features would you like to see? Any issues or suggestions? How could we make the app more helpful?',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            height: 1.4,
          ),
          counterText: '',
        ),
        onChanged: (String value) {
          setState(() {
            feedbackText = value;
          });
        },
      ),
    );
  }

  Widget _buildStarRating({
    required int currentRating,
    required Function(int) onRatingChanged,
    Color? starColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        int starNumber = index + 1;
        bool isSelected = starNumber <= currentRating;

        return GestureDetector(
          onTap: () => onRatingChanged(starNumber),
          child: Container(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.star_rounded,
              size: 36,
              color: isSelected ? (starColor ?? Colors.amber) : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton() {
    bool hasUserType = selectedUserType != null;
    bool hasValidEmail = emailText.isEmpty || _isValidEmail(emailText);
    bool canSubmit = hasUserType && hasValidEmail && !isSubmitting;

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitFeedback : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Color(0xFF8B5FBF) : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canSubmit ? 8 : 2,
        ),
        child: isSubmitting
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Sending...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 24),
            SizedBox(width: 12),
            Text(
              'Submit Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(0xFF8B5FBF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF8B5FBF).withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF8B5FBF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 50),
          ),
          SizedBox(height: 24),
          Text(
            'Thank You! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5FBF),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your feedback has been sent successfully!',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'We received your feedback and it has been automatically sent to our team. Thank you for helping us improve the Dementia Support App!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                hasSubmitted = false;
                selectedUserType = null;
                emailText = '';
                feedbackText = '';
                usefulnessRating = 0;
                easeOfUseRating = 0;
                selectedFeatures.updateAll((key, value) => false);
                emailController.clear();
                feedbackController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5FBF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Submit Another Feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    // Check if email is valid when not empty
    if (emailText.isNotEmpty && !_isValidEmail(emailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Get selected features list
    List<String> features = selectedFeatures.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Send feedback via Formspree
    bool emailSent = await EmailService.sendFeedback(
      userType: selectedUserType!,
      userEmail: emailText,
      feedbackText: feedbackText,
      usefulnessRating: usefulnessRating,
      easeOfUseRating: easeOfUseRating,
      selectedFeatures: features,
    );

    setState(() {
      isSubmitting = false;
    });

    if (emailSent) {
      // Success - email sent automatically
      setState(() {
        hasSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback sent successfully! Check your email for confirmation.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      // Failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send feedback. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }


}