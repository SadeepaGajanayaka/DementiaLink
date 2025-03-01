import 'package:flutter/material.dart';
import 'assist_me.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'assist_loved.dart';

class WelcomeScreen extends StatelessWidget {
  final String userName;

  const WelcomeScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF77588D), // Lighter purple at top
              Color(0xFF503663), // Darker purple at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // App Logo and Sign Out row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // For centering
                      Image.asset(
                        'lib/assets/brain_logo.png',
                        width: 60,
                        height: 60,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DementiaLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // White Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        // Profile Image
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF77588D).withOpacity(0.2),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(
                            'lib/assets/profile_setup.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Welcome Text
                        Text(
                          'Welcome $userName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF503663),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Support Question
                        const Text(
                          'Who would you like DementiaLink to help support?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Assist Me Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AssistMe(
                                    userName: '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF77588D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Assist Me',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Assist a Loved One Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AssistLoved(
                                    userName: '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF77588D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Assist a Loved One',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
