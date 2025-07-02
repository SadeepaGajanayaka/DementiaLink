// Import required packages for Flutter widgets, system services, JSON handling, and HTTP requests
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests

// Service class to handle email functionality using Formspree
class EmailService {
  // Static constant for Formspree URL - replace with actual form ID from Formspree dashboard
  static const String _formspreeUrl = 'https://formspree.io/f/xyzjokan';

  // Static method to send feedback data via HTTP POST request
  // Returns Future<bool> - true if successful, false if failed
  static Future<bool> sendFeedback({
    required String name, // User's name (required parameter)
    required String userType, // Type of user (caregiver, patient, etc.)
    required String userEmail, // User's email address
    required String feedbackText, // Additional feedback text
    required int usefulnessRating, // Rating for app usefulness (1-5)
    required int easeOfUseRating, // Rating for app ease of use (1-5)
    required List<String> selectedFeatures, // List of features user wants
  }) async {
    try {
      // Print debug message to console for development
      print('📧 FORMSPREE: Sending feedback...');

      // Check if developer has replaced placeholder URL with actual Formspree URL
      if (_formspreeUrl.contains('YOUR_FORM_ID_HERE')) {
        print('❌ FORMSPREE: Please replace YOUR_FORM_ID_HERE with your actual Formspree URL');
        return false; // Return failure if URL not configured
      }

      // Make HTTP POST request to Formspree
      final response = await http.post(
        Uri.parse(_formspreeUrl), // Convert string URL to Uri object
        headers: {
          'Content-Type': 'application/json', // Tell server we're sending JSON
          'Accept': 'application/json', // Tell server we accept JSON response
        },
        body: json.encode({ // Convert Dart map to JSON string
          // Formspree special fields (start with underscore)
          '_subject': 'New Feedback - Dementia Support App', // Email subject line
          '_replyto': userEmail.isNotEmpty ? userEmail : 'noreply@example.com', // Reply-to address

          // Custom form data fields
          'user_name': name.isEmpty ? 'Not provided' : name, // Handle empty name
          'user_type': userType, // User role/type
          'user_email': userEmail.isEmpty ? 'Not provided' : userEmail, // Handle empty email
          'usefulness_rating': '$usefulnessRating out of 5 stars', // Format rating as text
          'ease_of_use_rating': '$easeOfUseRating out of 5 stars', // Format rating as text
          'selected_features': selectedFeatures.isEmpty ? 'No features selected' : selectedFeatures.join(', '), // Join list into comma-separated string
          'additional_feedback': feedbackText.isEmpty ? 'No additional feedback provided' : feedbackText, // Handle empty feedback
          'submission_date': DateTime.now().toString().split('.')[0], // Current timestamp without milliseconds
          'app_name': 'Dementia Support App', // Static app identifier
        }),
      );

      // Print HTTP response details for debugging
      print('📧 FORMSPREE: Response status: ${response.statusCode}');
      print('📧 FORMSPREE: Response body: ${response.body}');

      // Check if request was successful (HTTP 200 OK)
      if (response.statusCode == 200) {
        print('✅ FORMSPREE: Email sent successfully!');
        return true; // Success
      } else {
        print('❌ FORMSPREE Failed with status ${response.statusCode} ');
        return false; // Failure
      }
    } catch (e) {
      // Handle any errors during HTTP request (network issues, etc.)
      print('💥 FORMSPREE: Error occurred: $e');
      return false; // Return failure on exception
    }
  }
}