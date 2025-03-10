/*import 'package:dementialink/screens/assist_me.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'assist_loved.dart'; // Your existing patient form screen

class PatientManagementScreen extends StatefulWidget {
  final String userName;

  const PatientManagementScreen({super.key, required this.userName});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final patients = await _databaseService.getPatientsForUser(userId);
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient(String patientId) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await _databaseService.deletePatient(userId, patientId);
        _loadPatients(); // Reload the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3E5F5), // Light purple background
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Add New Patient Button at the top
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _patients.length < 5
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssistMe(
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                              _loadPatients(); // Reload the list after returning
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ADD NEW PATIENT',
                              style: TextStyle(
                                color: Color(0xFF77588D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0E0E0),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF77588D),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main content - patient list or empty state
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF77588D)))
                    : _patients.isEmpty
                        ? _buildEmptyState()
                        : _buildPatientList(),
              ),

              // Message if patient limit reached
              if (_patients.length >= 5)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Maximum limit of 5 patients reached',
                    style: TextStyle(
                      color: Color(0xFF77588D),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: const Color(0xFF77588D).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No patients yet',
              style: TextStyle(
                color: Color(0xFF77588D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Click "ADD NEW PATIENT" to get started',
              style: TextStyle(
                color: Color(0xFF77588D),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final basicInfo =
            patient['basic_information'] as Map<String, dynamic>? ?? {};
        final firstName = basicInfo['first_name'] as String? ?? '';
        final lastName = basicInfo['last_name'] as String? ?? '';
        final fullName = '$firstName $lastName';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF77588D).withOpacity(0.2),
              child: Text(
                firstName.isNotEmpty ? firstName[0] : '?',
                style: const TextStyle(
                  color: Color(0xFF503663),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF503663),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(patient);
              },
            ),
            onTap: () {
              // Navigate to patient details or edit screen
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> patient) {
    final basicInfo =
        patient['basic_information'] as Map<String, dynamic>? ?? {};
    final firstName = basicInfo['first_name'] as String? ?? '';
    final lastName = basicInfo['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
            'Are you sure you want to delete $fullName? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePatient(patient['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}*/
