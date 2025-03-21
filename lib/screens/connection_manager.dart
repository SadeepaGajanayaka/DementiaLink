import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';

class ConnectionManagerScreen extends StatefulWidget {
  const ConnectionManagerScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionManagerScreen> createState() => _ConnectionManagerScreenState();
}

class _ConnectionManagerScreenState extends State<ConnectionManagerScreen> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();

  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDisconnect(String caregiverId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _locationService.revokeCaregiverAccess(caregiverId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caregiver disconnected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to disconnect caregiver'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDisconnectPatient(String patientId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _locationService.disconnectFromPatient(patientId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnected from patient successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to disconnect from patient'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connection Manager',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF503663),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Caregivers'),
            Tab(text: 'Patients'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Caregivers tab
          _buildCaregiversTab(),

          // Patients tab
          _buildPatientsTab(),
        ],
      ),
    );
  }

  Widget _buildCaregiversTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _locationService.getConnectedCaregivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final caregivers = snapshot.data?.docs ?? [];

        if (caregivers.isEmpty) {
          return const Center(
            child: Text('No connected caregivers'),
          );
        }

        return ListView.builder(
          itemCount: caregivers.length,
          itemBuilder: (context, index) {
            final caregiver = caregivers[index].data() as Map<String, dynamic>;
            final caregiverId = caregivers[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: caregiver['status'] == 'active'
                            ? const Color(0xFFE6DFF1)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: caregiver['status'] == 'active'
                              ? const Color(0xFF503663)
                              : Colors.grey[600],
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caregiver['caregiverName'] ?? 'Unknown Caregiver',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caregiver['caregiverEmail'] ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: caregiver['status'] == 'active'
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                caregiver['status'] == 'active'
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: caregiver['status'] == 'active'
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (caregiver['status'] == 'active')
                      IconButton(
                        icon: const Icon(Icons.link_off),
                        color: Colors.red,
                        tooltip: 'Disconnect',
                        onPressed: _isLoading
                            ? null
                            : () => _handleDisconnect(caregiverId),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _locationService.getConnectedPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final patients = snapshot.data?.docs ?? [];

        if (patients.isEmpty) {
          return const Center(
            child: Text('No connected patients'),
          );
        }

        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index].data() as Map<String, dynamic>;
            final patientId = patients[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: patient['status'] == 'active'
                            ? const Color(0xFFE6DFF1)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: patient['status'] == 'active'
                              ? const Color(0xFF503663)
                              : Colors.grey[600],
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['patientName'] ?? 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient['patientEmail'] ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: patient['status'] == 'active'
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                patient['status'] == 'active'
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: patient['status'] == 'active'
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (patient['status'] == 'active')
                      IconButton(
                        icon: const Icon(Icons.link_off),
                        color: Colors.red,
                        tooltip: 'Disconnect',
                        onPressed: _isLoading
                            ? null
                            : () => _handleDisconnectPatient(patientId),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}