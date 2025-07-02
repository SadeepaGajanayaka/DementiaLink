// Import required packages for email functionality, Flutter widgets, and system services
import 'package:dementialink/EmailService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Entry point of the Flutter application
main() {
  runApp(MyApp()); // Launches the app by calling MyApp widget
}

// Root widget of the application - extends StatelessWidget (doesn't change state)
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Returns MaterialApp which provides Material Design components and navigation
    return MaterialApp(
      title: 'Dementia Support Feedback', // App title shown in task switcher
      home: FeedbackScreen(), // Sets the initial screen to FeedbackScreen
    );
  }
}

// Main feedback screen - extends StatefulWidget (can change state/data)
class FeedbackScreen extends StatefulWidget {
  @override
  FeedbackScreenState createState() => FeedbackScreenState(); // Creates state object
}

// State class that manages the feedback screen's data and UI updates
class FeedbackScreenState extends State<FeedbackScreen> {
  // Variables to store user input and form state
  String? selectedUserType; // Nullable string for dropdown selection
  String nameText = ''; // Stores user's name input
  String emailText = ''; // Stores user's email input
  String feedbackText = ''; // Stores user's feedback text

  // Rating variables (0-5 stars)
  int usefulnessRating = 0; // How useful user finds the app
  int easeOfUseRating = 0; // How easy to use user finds the app

  // Boolean flags for form submission status
  bool isSubmitting = false; // True when form is being submitted
  bool hasSubmitted = false; // True after successful submission

  // Map to track which features user wants (feature name -> selected status)
  Map<String, bool> selectedFeatures = {
    'Memory exercises and games': false,
    'Medication reminders': false,
    'Daily routine planner': false,
    'GPS location tracking': false,
    'Large text and buttons': false,
  };

  // Text controllers to manage text field inputs
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController feedbackController = TextEditingController();

  // List of user type options for dropdown
  final List<String> userTypeOptions = [
    'Person with dementia',
    'Family caregiver',
    'Professional caregiver',
    'Healthcare provider',
    'Family member/friend',
  ];

  // Cleanup method called when widget is destroyed
  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    feedbackController.dispose();
    super.dispose(); // Call parent dispose method
  }

  // Main build method that creates the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Provides basic screen structure
      backgroundColor: Color(0xFFF8F7FC), // Light purple background
      body: SafeArea( // Ensures content doesn't overlap with system UI
        child: Column( // Vertical layout
          children: [
            // HEADER SECTION
            Container(
              width: double.infinity, // Full width
              padding: EdgeInsets.all(12), // Internal spacing
              decoration: BoxDecoration( // Styling for container
                gradient: LinearGradient( // Purple gradient background
                  colors: [
                    Color(0xFF8B5FBF), // Light purple
                    Color(0xFF6A4C93), // Dark purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only( // Rounded bottom corners
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column( // Vertical layout for header content
                children: [
                  SizedBox(height: 10), // Vertical spacing
                  // App logo container
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Semi-transparent white
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect( // Clips image to rounded corners
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                          'assets/Amitha.png', // App logo image
                          fit: BoxFit.cover, // Scales image to cover container
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback icon if image fails to load
                            return Icon(Icons.psychology, color: Colors.white, size: 35);
                          }
                      ),
                    ),
                  ),
                  SizedBox(height: 12), // Spacing between logo and title
                  // App title
                  Text(
                    'Dementia Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5, // Spacing between letters
                    ),
                  ),
                  SizedBox(height: 6), // Spacing between title and subtitle
                  // App subtitle
                  Text(
                    'Share your feedback to help us improve',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent white
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10), // Bottom padding
                ],
              ),
            ),

            // MAIN CONTENT AREA - Scrollable
            Expanded( // Takes remaining screen space
              child: SingleChildScrollView( // Enables scrolling
                padding: EdgeInsets.all(24), // Padding around content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align content
                  children: [
                    // Show success message if form submitted, otherwise show form
                    if (hasSubmitted)
                      _buildSuccessMessage() // Success screen
                    else ...[
                      // ABOUT YOU SECTION
                      _buildSectionCard(
                        '👤 About You', // Section title with emoji
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Name: *'), // Required field label
                            SizedBox(height: 12),
                            _buildNameField(), // Name input field
                            SizedBox(height: 20),
                            _buildLabel('I am a: *'), // User type label
                            SizedBox(height: 12),
                            _buildDropdown(), // User type dropdown
                            SizedBox(height: 20),
                            _buildLabel('Email (optional):'), // Optional email label
                            SizedBox(height: 12),
                            _buildEmailField(), // Email input field
                          ],
                        ),
                      ),

                      SizedBox(height: 24), // Section spacing

                      // RATING SECTION
                      _buildSectionCard(
                        '⭐ Rate the App',
                        Column(
                          children: [
                            // Usefulness rating
                            _buildRatingCard(
                              'How useful would this app be for you?',
                              usefulnessRating, // Current rating value
                              Color(0xFFFFF3E0), // Light orange background
                              Color(0xFFFF9800), // Orange accent color
                                  (rating) { // Callback when rating changes
                                setState(() {
                                  usefulnessRating = rating; // Update rating
                                });
                              },
                            ),

                            SizedBox(height: 20), // Spacing between ratings

                            // Ease of use rating
                            _buildRatingCard(
                              'How easy is the app to use?',
                              easeOfUseRating,
                              Color(0xFFE3F2FD), // Light blue background
                              Color(0xFF2196F3), // Blue accent color
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

                      // FEATURES SECTION
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
                            // Generate checkbox for each feature
                            ...selectedFeatures.keys.map((feature) =>
                                _buildFeatureCheckbox(feature) // Creates checkbox widget
                            ).toList(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // FEEDBACK SECTION
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
                            _buildFeedbackTextField(), // Multi-line text input
                            SizedBox(height: 12),
                            Text(
                              'Share your suggestions and ideas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                fontStyle: FontStyle.italic, // Italic helper text
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      _buildSubmitButton(), // Submit button

                      SizedBox(height: 32),

                      // BOTTOM MESSAGE
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE0E0E0)), // Light gray border
                        ),
                        child: Text(
                          '💜 Your input helps us create better tools for dementia care and support.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B5FBF), // Purple text
                            fontWeight: FontWeight.w500,
                            height: 1.5, // Line height
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

  // WIDGET BUILDING METHODS

  // Creates name input field widget
  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Light gray background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Gray border
      ),
      child: TextField(
        controller: nameController, // Links to controller for text management
        decoration: InputDecoration(
          border: InputBorder.none, // Removes default border
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Please enter your name *', // Placeholder text
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8B5FBF)), // Person icon
        ),
        onChanged: (String value) { // Called when text changes
          setState(() {
            nameText = value; // Update state variable
          });
        },
      ),
    );
  }

  // Creates reusable section card widget with title and content
  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ // Adds shadow effect
          BoxShadow(
            color: Color(0xFF8B5FBF).withOpacity(0.1), // Purple shadow
            spreadRadius: 0,
            blurRadius: 20, // Shadow blur amount
            offset: Offset(0, 4), // Shadow position
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF8B5FBF).withOpacity(0.1), // Light purple background
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
          // Section content
          Padding(
            padding: EdgeInsets.all(20),
            child: content, // Dynamic content passed as parameter
          ),
        ],
      ),
    );
  }

  // Creates rating card with stars for user feedback
  Widget _buildRatingCard(String question, int rating, Color bgColor, Color accentColor, Function(int) onChanged) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor, // Background color (varies by rating type)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)), // Colored border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating question
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 16),
          // Star rating component
          _buildStarRating(
            currentRating: rating,
            onRatingChanged: onChanged, // Callback function
            starColor: accentColor,
          ),
          // Show rating text if user has rated
          if (rating > 0)
            SizedBox(height: 12),
          if (rating > 0)
            Text(
              'You rated: $rating star${rating == 1 ? '' : 's'}', // Singular/plural handling
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

  // Creates checkbox widget for feature selection
  Widget _buildFeatureCheckbox(String feature) {
    bool isSelected = selectedFeatures[feature]!; // Get selection status
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell( // Provides tap interaction with ripple effect
        borderRadius: BorderRadius.circular(12),
        onTap: () { // Handle tap
          setState(() {
            selectedFeatures[feature] = !selectedFeatures[feature]!; // Toggle selection
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Change colors based on selection status
            color: isSelected ? Color(0xFF8B5FBF).withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Color(0xFF8B5FBF) : Colors.grey.shade300,
              width: isSelected ? 2 : 1, // Thicker border when selected
            ),
          ),
          child: Row(
            children: [
              // Custom checkbox
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
                    ? Icon(Icons.check, color: Colors.white, size: 16) // Checkmark icon
                    : null, // Empty when not selected
              ),
              SizedBox(width: 16),
              // Feature text
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

  // Creates label text widget
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

  // Creates dropdown widget for user type selection
  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedUserType, // Current selected value
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Please select your role...', // Placeholder text
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        // Create dropdown items from userTypeOptions list
        items: userTypeOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: (String? newValue) { // Called when selection changes
          setState(() {
            selectedUserType = newValue; // Update selected value
          });
        },
      ),
    );
  }

  // Creates email input field widget
  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress, // Shows email keyboard
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'your.email@example.com', // Example email format
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF8B5FBF)), // Email icon
        ),
        onChanged: (String value) {
          setState(() {
            emailText = value;
          });
        },
      ),
    );
  }

  // Creates multi-line feedback text field
  Widget _buildFeedbackTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: feedbackController,
        maxLines: 5, // Allows 5 lines of text
        maxLength: 500, // Character limit
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: 'What features would you like to see? Any issues or suggestions? How could we make the app more helpful?',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            height: 1.4, // Line height
          ),
          counterText: '', // Hides character counter
        ),
        onChanged: (String value) {
          setState(() {
            feedbackText = value;
          });
        },
      ),
    );
  }

  // Creates star rating widget (1-5 stars)
  Widget _buildStarRating({
    required int currentRating,
    required Function(int) onRatingChanged,
    Color? starColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) { // Generate 5 stars
        int starNumber = index + 1; // Star numbers 1-5
        bool isSelected = starNumber <= currentRating; // Check if star should be filled

        return GestureDetector(
          onTap: () => onRatingChanged(starNumber), // Handle star tap
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

  // Creates submit button with validation
  Widget _buildSubmitButton() {
    // Validation checks
    bool hasUserType = selectedUserType != null; // User type selected
    bool hasName = nameText.trim().isNotEmpty; // Name provided
    bool hasValidEmail = emailText.isEmpty || _isValidEmail(emailText); // Email valid or empty
    bool canSubmit = hasUserType && hasName && hasValidEmail && !isSubmitting; // All conditions met

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitFeedback : null, // Enable/disable button
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Color(0xFF8B5FBF) : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canSubmit ? 8 : 2, // Shadow depth
        ),
        child: isSubmitting
            ? Row( // Show loading state
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator( // Loading spinner
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
            : Row( // Show normal state
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

  // Creates success message widget shown after form submission
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
          // Success icon
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
          // Success title
          Text(
            'Thank You! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5FBF),
            ),
          ),
          SizedBox(height: 12),
          // Success message
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
          // Detailed success message
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
          // Reset button to submit another feedback
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Reset all form fields and state
                hasSubmitted = false;
                selectedUserType = null;
                nameText = '';
                emailText = '';
                feedbackText = '';
                usefulnessRating = 0;
                easeOfUseRating = 0;
                selectedFeatures.updateAll((key, value) => false); // Reset all features to false
                nameController.clear();
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

  // FORM SUBMISSION AND VALIDATION METHODS

  // Handles form submission
  Future<void> _submitFeedback() async {
    // Validate name field
    if (nameText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Exit if validation fails
    }

    // Validate email field (only if not empty)
    if (emailText.isNotEmpty && !_isValidEmail(emailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Exit if validation fails
    }

    // Set submitting state
    setState(() {
      isSubmitting = true;
    });

    // Extract selected features into a list
    List<String> features = selectedFeatures.entries
        .where((entry) => entry.value) // Filter only selected features
        .map((entry) => entry.key) // Get feature names
        .toList();

    // Call EmailService to send feedback
    bool emailSent = await EmailService.sendFeedback(
      name: nameText,
      userType: selectedUserType!,
      userEmail: emailText,
      feedbackText: feedbackText,
      usefulnessRating: usefulnessRating,
      easeOfUseRating: easeOfUseRating,
      selectedFeatures: features,
    );

    // Reset submitting state
    setState(() {
      isSubmitting = false;
    });

    // Handle submission result
    if (emailSent) {
      // Success case
      setState(() {
        hasSubmitted = true; // Show success message
      });

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback sent successfully! Check your email for confirmation.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      // Failure case
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send feedback. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Email validation method using regular expression
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}