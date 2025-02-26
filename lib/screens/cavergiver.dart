import 'package:flutter/material.dart';

void main() {
  runApp(DementiaFormApp());
}

class DementiaFormApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DementiaFormScreen(),
    );
  }
}

class DementiaFormScreen extends StatefulWidget {
  @override
  _DementiaFormScreenState createState() => _DementiaFormScreenState();
}

class _DementiaFormScreenState extends State<DementiaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController relationController = TextEditingController();
  final TextEditingController otherSymptomsController = TextEditingController();
  final TextEditingController otherNeedsController = TextEditingController();

  String? selectedGender;
  List<String> genderOptions = ["Male", "Female", "Other"];

  bool forgetfulness = false;
  bool aggressiveness = false;
  bool disorientation = false;
  bool empathy = false;
  bool personalityChanges = false;

  bool physicalStimulation = false;
  bool socialStimulation = false;
  bool dailyRoutine = false;
  bool personalCare = false;
  bool cognitiveStimulation = false;

  @override
  void initState() {
    super.initState();
    birthDateController.text = "MM/DD/YYYY"; // Default placeholder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("Personal Information", [
                  _buildLabel("First Name"),
                  _buildTextField(firstNameController, "Enter first name"),
                  _buildLabel("Last Name"),
                  _buildTextField(lastNameController, "Enter last name"),
                ]),
                _buildSection("Additional Details", [
                  _buildLabel("Gender"),
                  _buildDropdownField(),
                  _buildLabel("Date of Birth"),
                  _buildDatePickerField(),
                  _buildLabel("Relation to Caregiver"),
                  _buildTextField(relationController, "e.g. Father, Mother"),
                ]),
                _buildSection("Symptoms", [
                  _buildCheckbox("Forgetfulness", forgetfulness,
                      (val) => setState(() => forgetfulness = val)),
                  _buildCheckbox("Aggressiveness", aggressiveness,
                      (val) => setState(() => aggressiveness = val)),
                  _buildCheckbox("Disorientation", disorientation,
                      (val) => setState(() => disorientation = val)),
                  _buildCheckbox("Empathy", empathy,
                      (val) => setState(() => empathy = val)),
                  _buildCheckbox("Personality Changes", personalityChanges,
                      (val) => setState(() => personalityChanges = val)),
                  _buildLabel("Other"),
                  _buildTextField(
                      otherSymptomsController, "Specify other symptoms"),
                ]),
                _buildSection("Patient Needs", [
                  _buildCheckbox("Physical Stimulation", physicalStimulation,
                      (val) => setState(() => physicalStimulation = val)),
                  _buildCheckbox("Social Stimulation", socialStimulation,
                      (val) => setState(() => socialStimulation = val)),
                  _buildCheckbox("Daily Routine", dailyRoutine,
                      (val) => setState(() => dailyRoutine = val)),
                  _buildCheckbox("Personal Care", personalCare,
                      (val) => setState(() => personalCare = val)),
                  _buildCheckbox("Cognitive Stimulation", cognitiveStimulation,
                      (val) => setState(() => cognitiveStimulation = val)),
                  _buildLabel("Other"),
                  _buildTextField(otherNeedsController, "Specify other needs"),
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
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Form Submitted Successfully!")),
                        );
                      }
                    },
                    child: Text("CONFIRM",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      validator: (value) =>
          value == null || value.isEmpty ? 'This field is required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      validator: (value) => value == null ? "Please select a gender" : null,
      onChanged: (value) => setState(() => selectedGender = value),
      items: genderOptions.map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return TextFormField(
      controller: birthDateController,
      validator: (value) =>
          value == "MM/DD/YYYY" ? "Please pick a valid date" : null,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            birthDateController.text =
                "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
          });
        }
      },
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      value: value,
      activeColor: Colors.purple,
      checkColor: Colors.white,
      onChanged: (val) => onChanged(val ?? false),
    );
  }
}
