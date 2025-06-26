// // STEP 7: Add Checkbox Features Selection
// // Now we add checkboxes for users to select multiple features they want
//
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(DementiaFeedbackApp());
// }
//
// class DementiaFeedbackApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dementia App Feedback',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: FeedbackScreen(),
//     );
//   }
// }
//
// class FeedbackScreen extends StatefulWidget {
//   @override
//   _FeedbackScreenState createState() => _FeedbackScreenState();
// }
//
// class _FeedbackScreenState extends State<FeedbackScreen> {
//
//   // VARIABLES to remember form data
//   String? selectedUserType;
//   String emailText = '';
//   int usefulnessRating = 0;
//   int easeOfUseRating = 0;
//
//   // NEW: Map to track which features are selected
//   Map<String, bool> selectedFeatures = {
//     'Memory exercises and games': false,
//     'Medication reminders': false,
//     'Daily routine planner': false,
//     'Emergency contacts': false,
//     'GPS location tracking': false,
//     'Voice commands': false,
//     'Large text and buttons': false,
//     'Family communication tools': false,
//   };
//
//   // Controller for email field
//   TextEditingController emailController = TextEditingController();
//
//   // List of dropdown options
//   final List<String> userTypeOptions = [
//     'Person with dementia',
//     'Family caregiver',
//     'Professional caregiver',
//     'Healthcare provider',
//     'Family member/friend',
//   ];
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//
//         // Background gradient
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF667eea),
//               Color(0xFF764ba2),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//
//         child: Column(
//           children: [
//
//             // HEADER SECTION (same as before)
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(25),
//               margin: EdgeInsets.only(top: 50),
//
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFF4CAF50),
//                     Color(0xFF45a049),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     spreadRadius: 2,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//
//               child: Column(
//                 children: [
//                   Text(
//                     '🧠 Dementia Support App',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Help us improve with your feedback',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.9),
//                       fontSize: 16,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//
//             // FORM CONTAINER SECTION
//             Expanded(
//               child: Container(
//                 margin: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       spreadRadius: 3,
//                       blurRadius: 15,
//                       offset: Offset(0, 8),
//                     ),
//                   ],
//                 ),
//
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.all(25),
//
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//
//                       // Welcome message
//                       Center(
//                         child: Text(
//                           'We value your feedback! 💬',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green.shade700,
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // ABOUT YOU SECTION
//                       _buildSectionHeader('👤 About You'),
//                       SizedBox(height: 20),
//
//                       // USER TYPE DROPDOWN
//                       _buildLabel('I am a: *'),
//                       SizedBox(height: 8),
//                       _buildDropdown(),
//                       SizedBox(height: 20),
//
//                       // EMAIL INPUT
//                       _buildLabel('Email (optional):'),
//                       SizedBox(height: 8),
//                       _buildEmailField(),
//                       SizedBox(height: 30),
//
//                       // RATING SECTION
//                       _buildSectionHeader('⭐ Rate the App'),
//                       SizedBox(height: 20),
//
//                       // USEFULNESS RATING
//                       _buildRatingContainer(
//                         question: 'How useful would this app be for you?',
//                         currentRating: usefulnessRating,
//                         backgroundColor: Colors.amber.shade50,
//                         borderColor: Colors.amber.shade200,
//                         textColor: Colors.amber.shade700,
//                         onRatingChanged: (rating) {
//                           setState(() {
//                             usefulnessRating = rating;
//                           });
//                           print('Usefulness rating: $rating stars');
//                         },
//                       ),
//
//                       SizedBox(height: 20),
//
//                       // EASE OF USE RATING
//                       _buildRatingContainer(
//                         question: 'How easy is the app to use?',
//                         currentRating: easeOfUseRating,
//                         backgroundColor: Colors.blue.shade50,
//                         borderColor: Colors.blue.shade200,
//                         textColor: Colors.blue.shade700,
//                         onRatingChanged: (rating) {
//                           setState(() {
//                             easeOfUseRating = rating;
//                           });
//                           print('Ease of use rating: $rating stars');
//                         },
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // FEATURES SECTION (NEW!)
//                       _buildSectionHeader('✅ Features You Want'),
//                       SizedBox(height: 20),
//
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.indigo.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.indigo.shade200),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Which features would be most helpful? (Select all that apply)',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey.shade700,
//                               ),
//                             ),
//                             SizedBox(height: 15),
//
//                             // BUILD ALL CHECKBOXES
//                             ...selectedFeatures.keys.map((feature) =>
//                               _buildCheckboxTile(feature)
//                             ).toList(),
//
//                             SizedBox(height: 15),
//
//                             // SHOW SELECTED COUNT
//                             Container(
//                               padding: EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.indigo.shade100,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.info_outline,
//                                     color: Colors.indigo.shade600,
//                                     size: 20,
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     'Selected: ${_getSelectedFeaturesCount()} features',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.indigo.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // FORM DATA DISPLAY (UPDATED!)
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           color: Colors.purple.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.purple.shade200),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '📝 Current Form Data:',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.purple.shade700,
//                               ),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               'User Type: ${selectedUserType ?? "Not selected"}',
//                               style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
//                             ),
//                             Text(
//                               'Email: ${emailText.isEmpty ? "Not entered" : emailText}',
//                               style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
//                             ),
//                             Text(
//                               'Usefulness: ${usefulnessRating == 0 ? "Not rated" : "$usefulnessRating stars"}',
//                               style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
//                             ),
//                             Text(
//                               'Ease of Use: ${easeOfUseRating == 0 ? "Not rated" : "$easeOfUseRating stars"}',
//                               style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
//                             ),
//                             Text(
//                               'Features: ${_getSelectedFeaturesList()}',
//                               style: TextStyle(fontSize: 14, color: Colors.purple.shade600),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       // Email validation (from previous step)
//                       if (emailText.isNotEmpty) ...[
//                         SizedBox(height: 20),
//                         Container(
//                           width: double.infinity,
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: _isValidEmail(emailText) ? Colors.green.shade50 : Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: _isValidEmail(emailText) ? Colors.green.shade300 : Colors.red.shade300,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 _isValidEmail(emailText) ? Icons.check_circle : Icons.error,
//                                 color: _isValidEmail(emailText) ? Colors.green : Colors.red,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _isValidEmail(emailText)
//                                     ? 'Email format looks good!'
//                                     : 'Please enter a valid email format',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: _isValidEmail(emailText) ? Colors.green.shade700 : Colors.red.shade700,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//
//                       SizedBox(height: 30),
//
//                       // Placeholder for next step
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: Colors.grey.shade300, width: 1),
//                         ),
//                         child: Center(
//                           child: Text(
//                             'Next step: Add submit button! 🚀',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey.shade500,
//                               fontStyle: FontStyle.italic,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // HELPER FUNCTION: Build section headers
//   Widget _buildSectionHeader(String title) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.green.shade200, width: 1),
//       ),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.green.shade800,
//         ),
//       ),
//     );
//   }
//
//   // HELPER FUNCTION: Build labels
//   Widget _buildLabel(String text) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey.shade700,
//       ),
//     );
//   }
//
//   // HELPER FUNCTION: Build dropdown
//   Widget _buildDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedUserType,
//       decoration: InputDecoration(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.green, width: 2),
//         ),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         hintText: 'Please select your role...',
//         hintStyle: TextStyle(color: Colors.grey.shade500),
//       ),
//       items: userTypeOptions.map<DropdownMenuItem<String>>((String value) {
//         return DropdownMenuItem<String>(
//           value: value,
//           child: Text(value, style: TextStyle(fontSize: 16)),
//         );
//       }).toList(),
//       onChanged: (String? newValue) {
//         setState(() {
//           selectedUserType = newValue;
//         });
//         print('User selected: $newValue');
//       },
//     );
//   }
//
//   // HELPER FUNCTION: Build email field
//   Widget _buildEmailField() {
//     return TextField(
//       controller: emailController,
//       keyboardType: TextInputType.emailAddress,
//       decoration: InputDecoration(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.blue, width: 2),
//         ),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         hintText: 'your.email@example.com',
//         hintStyle: TextStyle(color: Colors.grey.shade500),
//         prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade500),
//       ),
//       onChanged: (String value) {
//         setState(() {
//           emailText = value;
//         });
//         print('Email typed: $value');
//       },
//     );
//   }
//
//   // HELPER FUNCTION: Build rating container (updated from step 6)
//   Widget _buildRatingContainer({
//     required String question,
//     required int currentRating,
//     required Color backgroundColor,
//     required Color borderColor,
//     required Color textColor,
//     required Function(int) onRatingChanged,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             question,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           SizedBox(height: 15),
//
//           _buildStarRating(
//             currentRating: currentRating,
//             onRatingChanged: onRatingChanged,
//           ),
//
//           SizedBox(height: 10),
//           if (currentRating > 0)
//             Text(
//               'You rated: $currentRating star${currentRating == 1 ? '' : 's'}',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: textColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // HELPER FUNCTION: Build star rating widget
//   Widget _buildStarRating({
//     required int currentRating,
//     required Function(int) onRatingChanged,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(5, (index) {
//         int starNumber = index + 1;
//         bool isSelected = starNumber <= currentRating;
//
//         return GestureDetector(
//           onTap: () {
//             onRatingChanged(starNumber);
//           },
//           child: Container(
//             padding: EdgeInsets.all(4),
//             child: Icon(
//               Icons.star,
//               size: 40,
//               color: isSelected ? Colors.amber : Colors.grey.shade300,
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   // NEW HELPER FUNCTION: Build individual checkbox tile
//   Widget _buildCheckboxTile(String feature) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 8),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(8),
//         onTap: () {
//           setState(() {
//             selectedFeatures[feature] = !selectedFeatures[feature]!;
//           });
//           print('Feature "$feature" is now ${selectedFeatures[feature] ? "selected" : "unselected"}');
//         },
//         child: Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: selectedFeatures[feature]! ? Colors.indigo.shade100 : Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: selectedFeatures[feature]! ? Colors.indigo.shade300 : Colors.grey.shade300,
//               width: selectedFeatures[feature]! ? 2 : 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: selectedFeatures[feature]! ? Colors.indigo : Colors.white,
//                   border: Border.all(
//                     color: selectedFeatures[feature]! ? Colors.indigo : Colors.grey.shade400,
//                     width: 2,
//                   ),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: selectedFeatures[feature]!
//                   ? Icon(Icons.check, color: Colors.white, size: 16)
//                   : null,
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   feature,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: selectedFeatures[feature]! ? Colors.indigo.shade700 : Colors.grey.shade700,
//                     fontWeight: selectedFeatures[feature]! ? FontWeight.w600 : FontWeight.normal,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // NEW HELPER FUNCTION: Count selected features
//   int _getSelectedFeaturesCount() {
//     return selectedFeatures.values.where((isSelected) => isSelected).length;
//   }
//
//   // NEW HELPER FUNCTION: Get list of selected features
//   String _getSelectedFeaturesList() {
//     List<String> selected = selectedFeatures.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
//
//     if (selected.isEmpty) {
//       return "None selected";
//     }
//
//     if (selected.length <= 2) {
//       return selected.join(', ');
//     } else {
//       return '${selected.take(2).join(', ')} and ${selected.length - 2} more';
//     }
//   }
//
//   // Email validation function
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
//   }
// }