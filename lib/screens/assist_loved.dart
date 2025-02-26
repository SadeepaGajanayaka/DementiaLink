import 'package:flutter/material.dart';

void main() {
  runApp(DementiaFormApp());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D69),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("First Name", firstNameController),
              _buildTextField("Last Name", lastNameController),
              SizedBox(height: 10),
              _buildTextField("Gender", null, isDate: true),
              _buildTextField("Date of Birth", null, isDate: true),
              _buildTextField("Relation to Caregiver", null, initialValue: "Father"),
              SizedBox(height: 20),
              _buildCheckboxGroup("What symptoms does the patient have?", [
                _buildCheckbox("Forgetfulness", forgetfulness, (val) => setState(() => forgetfulness = val)),
                _buildCheckbox("Aggressiveness", aggressiveness, (val) => setState(() => aggressiveness = val)),
                _buildCheckbox("Disorientation", disorientation, (val) => setState(() => disorientation = val)),
                _buildCheckbox("Empathy", empathy, (val) => setState(() => empathy = val)),
                _buildCheckbox("Personality Changes", personalityChanges, (val) => setState(() => personalityChanges = val)),
                _buildTextField("Other", otherSymptomsController)
              ]),
              SizedBox(height: 20),
              _buildCheckboxGroup("What are the main needs of the patient?", [
                _buildCheckbox("Physical Stimulation", physicalStimulation, (val) => setState(() => physicalStimulation = val)),
                _buildCheckbox("Social Stimulation", socialStimulation, (val) => setState(() => socialStimulation = val)),
                _buildCheckbox("Daily Routine", dailyRoutine, (val) => setState(() => dailyRoutine = val)),
                _buildCheckbox("Personal Care", personalCare, (val) => setState(() => personalCare = val)),
                _buildCheckbox("Cognitive Stimulation", cognitiveStimulation, (val) => setState(() => cognitiveStimulation = val)),
                _buildTextField("Other", otherNeedsController)
              ]),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5A3D69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  onPressed: () {},
                  child: Text("CONFIRM", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller, {bool isDate = false, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        readOnly: isDate || initialValue != null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      value: value,
      activeColor: Colors.white,
      checkColor: Color(0xFF5A3D69),
      onChanged: (val) => onChanged(val ?? false),
    );
  }

  Widget _buildCheckboxGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ...children,
      ],
    );
  }
}
