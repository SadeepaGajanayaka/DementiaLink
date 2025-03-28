import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Hide system UI to ensure full coverage
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when dialog is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _emailController.dispose();
    super.dispose();
  }

  // Email validation function
  bool _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter an email address');
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return false;
    }

    setState(() => _emailError = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen dialog that covers everything including the navigation bar
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Restore system UI mode
        if (didPop) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      },
      child: Scaffold(
        // Make sure we have a transparent background so our overlay shows
        backgroundColor: Colors.transparent,
        // Use SafeArea.minimum to ensure we draw under the status bar and navigation bar
        body: Container(
          // Cover the entire screen including navigation and status bars
          width: MediaQuery.of(context).size.width,
          // Use double.infinity to ensure we go beyond safe areas
          height: double.infinity,
          // This is the semi-transparent background
          color: const Color(0xFF503663).withOpacity(0.95),
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Close button in top right corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF77588D)),
                        onPressed: () {
                          // Restore system UI before popping
                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Image and text centered
                      Center(
                        child: SizedBox(
                          height: 150,
                          child: Image.asset(
                            'lib/assets/image.jpeg',
                            // If you don't have this asset, replace with:
                            // Icon(Icons.person_outline, size: 150, color: Color(0xFF77588D))
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Enter Patient Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Input field - centered
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: TextField(
                            controller: _emailController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'example@email.com',
                              errorText: _emailError,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF77588D)),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons row
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Delete button on the left
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9D9D9),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFF77588D)),
                                onPressed: () {
                                  // Delete functionality - clear the text field
                                  _emailController.clear();
                                  setState(() {
                                    _emailError = null;
                                  });
                                },
                              ),
                            ),

                            // Send button on the right
                            ElevatedButton(
                              onPressed: () {
                                // Validate email before proceeding
                                if (_validateEmail()) {
                                  // Process email and navigate back
                                  final email = _emailController.text.trim();
                                  // Restore system UI before popping
                                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                  // Return to maps screen with the validated email
                                  Navigator.pop(context, email);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF77588D),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}