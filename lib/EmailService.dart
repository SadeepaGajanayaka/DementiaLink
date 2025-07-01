import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class EmailService {
  // Replace this with YOUR actual Formspree URL after creating your form
  static const String _formspreeUrl = 'https://formspree.io/f/xyzjokan';

  static Future<bool> sendFeedback({
    required String userType,
    required String userEmail,
    required String feedbackText,
    required int usefulnessRating,
    required int easeOfUseRating,
    required List<String> selectedFeatures,
  }) async {
    try {
      print('📧 FORMSPREE: Sending feedback...');

      // Check if URL is still placeholder
      if (_formspreeUrl.contains('YOUR_FORM_ID_HERE')) {
        print('❌ FORMSPREE: Please replace YOUR_FORM_ID_HERE with your actual Formspree URL');
        return false;
      }

      final response = await http.post(
        Uri.parse(_formspreeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          // Email subject and reply-to
          '_subject': 'New Feedback - Dementia Support App',
          '_replyto': userEmail.isNotEmpty ? userEmail : 'noreply@example.com',

          // Form data
          'user_type': userType,
          'user_email': userEmail.isEmpty ? 'Not provided' : userEmail,
          'usefulness_rating': '$usefulnessRating out of 5 stars',
          'ease_of_use_rating': '$easeOfUseRating out of 5 stars',
          'selected_features': selectedFeatures.isEmpty ? 'No features selected' : selectedFeatures.join(', '),
          'additional_feedback': feedbackText.isEmpty ? 'No additional feedback provided' : feedbackText,
          'submission_date': DateTime.now().toString().split('.')[0],
          'app_name': 'Dementia Support App',
        }),
      );

      print('📧 FORMSPREE: Response status: ${response.statusCode}');
      print('📧 FORMSPREE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ FORMSPREE: Email sent successfully!');
        return true;
      } else {
        print('❌ FORMSPREE Failed with status ${response.statusCode} ');
        return false;
      }
    } catch (e) {
      print('💥 FORMSPREE: Error occurred: $e');
      return false;
    }
  }
}