import 'package:flutter/material.dart';
import 'verification_screen.dart';

class ForgotPasswordDialog extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  ForgotPasswordDialog({super.key, required Null Function(dynamic submittedEmail) onSubmit});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(24, 1, 24, 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3EBF8), // Light purple background
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Forgot your password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF503663),
                        height: 1.2,
                        shadows: [
                          for (double i = 1; i < 5; i++)
                            Shadow(
                              color: Colors.black.withOpacity(0.15 / i),
                              offset: Offset(0, i / 2),
                            ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Enter email address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF503663),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF503663),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF503663),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'REQUEST RESET LINK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back To Login',
                      style: TextStyle(
                        color: Color(0xFF503663),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button positioned outside the white container
          Positioned(
            right: 16,
            top: 16,
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF503663),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}                  