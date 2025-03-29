// // import 'package:flutter/material.dart';
// // import '../models/task_model.dart';
// // import 'package:intl/intl.dart';
// //
// // class AddTaskOverlay extends StatefulWidget {
// //   final Function(Task) onTaskCreated;
// //   final Task? task;
// //
// //   const AddTaskOverlay({
// //     Key? key,
// //     required this.onTaskCreated,
// //     this.task,
// //   }) : super(key: key);
// //
// //   @override
// //   _AddTaskOverlayState createState() => _AddTaskOverlayState();
// // }
// //
// // class _AddTaskOverlayState extends State<AddTaskOverlay> {
// //   late TextEditingController _titleController;
// //   late TextEditingController _descriptionController;
// //   late DateTime _selectedDate;
// //   late TimeOfDay _startTime;
// //   late TimeOfDay _endTime;
// //   late String _selectedReminder;
// //   late String _selectedRepeat;
// //   late Priority _selectedPriority;
// //
// //   final List<String> _reminderOptions = ['5 minutes early', '10 minutes early', '15 minutes early', '30 minutes early'];
// //   final List<String> _repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly'];
// //   final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     // Initialize with provided task or defaults
// //     _titleController = TextEditingController(text: widget.task?.title ?? '');
// //     _descriptionController = TextEditingController(text: widget.task?.description ?? '');
// //     _selectedDate = widget.task?.date ?? DateTime.now();
// //     _startTime = widget.task?.startTime ?? TimeOfDay(hour: 9, minute: 0);
// //     _endTime = widget.task?.endTime ?? TimeOfDay(hour: 10, minute: 0);
// //     _selectedReminder = widget.task?.remindBefore ?? _reminderOptions[0];
// //     _selectedRepeat = widget.task?.repeat ?? _repeatOptions[0];
// //     _selectedPriority = widget.task?.priority ?? Priority.medium;
// //   }
// //
// //   @override
// //   void dispose() {
// //     _titleController.dispose();
// //     _descriptionController.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> _selectDate(BuildContext context) async {
// //     final DateTime? picked = await showDatePicker(
// //       context: context,
// //       initialDate: _selectedDate,
// //       firstDate: DateTime.now(),
// //       lastDate: DateTime(2100),
// //       builder: (context, child) {
// //         return Theme(
// //           data: ThemeData.light().copyWith(
// //             colorScheme: ColorScheme.light(
// //               primary: const Color(0xFF503663),
// //               onPrimary: Colors.white,
// //             ),
// //           ),
// //           child: child!,
// //         );
// //       },
// //     );
// //     if (picked != null && picked != _selectedDate) {
// //       setState(() {
// //         _selectedDate = picked;
// //       });
// //     }
// //   }
// //
// //   Future<void> _selectStartTime(BuildContext context) async {
// //     final TimeOfDay? picked = await showTimePicker(
// //       context: context,
// //       initialTime: _startTime,
// //       builder: (context, child) {
// //         return Theme(
// //           data: ThemeData.light().copyWith(
// //             colorScheme: ColorScheme.light(
// //               primary: const Color(0xFF503663),
// //               onPrimary: Colors.white,
// //             ),
// //           ),
// //           child: child!,
// //         );
// //       },
// //     );
// //     if (picked != null && picked != _startTime) {
// //       setState(() {
// //         _startTime = picked;
// //         // If end time is before start time, adjust it
// //         if (_timeOfDayToDouble(_endTime) < _timeOfDayToDouble(_startTime)) {
// //           _endTime = TimeOfDay(
// //             hour: _startTime.hour + 1,
// //             minute: _startTime.minute,
// //           );
// //         }
// //       });
// //     }
// //   }
// //
// //   Future<void> _selectEndTime(BuildContext context) async {
// //     final TimeOfDay? picked = await showTimePicker(
// //       context: context,
// //       initialTime: _endTime,
// //       builder: (context, child) {
// //         return Theme(
// //           data: ThemeData.light().copyWith(
// //             colorScheme: ColorScheme.light(
// //               primary: const Color(0xFF503663),
// //               onPrimary: Colors.white,
// //             ),
// //           ),
// //           child: child!,
// //         );
// //       },
// //     );
// //     if (picked != null && picked != _endTime) {
// //       setState(() {
// //         _endTime = picked;
// //       });
// //     }
// //   }
// //
// //   double _timeOfDayToDouble(TimeOfDay time) {
// //     return time.hour + time.minute / 60.0;
// //   }
// //
// //   void _createTask() {
// //     if (_titleController.text.trim().isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Please enter a title')),
// //       );
// //       return;
// //     }
// //
// //     final newTask = Task(
// //       title: _titleController.text,
// //       description: _descriptionController.text,
// //       date: _selectedDate,
// //       startTime: _startTime,
// //       endTime: _endTime,
// //       priority: _selectedPriority,
// //       remindBefore: _selectedReminder,
// //       repeat: _selectedRepeat,
// //     );
// //
// //     widget.onTaskCreated(newTask);
// //     Navigator.pop(context);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Container(
// //         padding: EdgeInsets.all(20),
// //         child: SingleChildScrollView(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(
// //                     'Add Task',
// //                     style: TextStyle(
// //                       fontSize: 24,
// //                       fontWeight: FontWeight.bold,
// //                       color: const Color(0xFF503663),
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: Icon(Icons.close, color: Colors.black),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                 ],
// //               ),
// //               SizedBox(height: 20),
// //               _buildTextField(
// //                 label: 'Title',
// //                 controller: _titleController,
// //               ),
// //               SizedBox(height: 16),
// //               _buildTextField(
// //                 label: 'Description',
// //                 controller: _descriptionController,
// //               ),
// //               SizedBox(height: 16),
// //               _buildDateSelector(),
// //               SizedBox(height: 16),
// //               Row(
// //                 children: [
// //                   Expanded(child: _buildTimeSelector('Start Time', _startTime, _selectStartTime)),
// //                   SizedBox(width: 16),
// //                   Expanded(child: _buildTimeSelector('End Time', _endTime, _selectEndTime)),
// //                 ],
// //               ),
// //               SizedBox(height: 16),
// //               _buildDropdown('Remind', _selectedReminder, _reminderOptions, (value) {
// //                 setState(() {
// //                   _selectedReminder = value!;
// //                 });
// //               }),
// //               SizedBox(height: 16),
// //               _buildDropdown('Repeat', _selectedRepeat, _repeatOptions, (value) {
// //                 setState(() {
// //                   _selectedRepeat = value!;
// //                 });
// //               }),
// //               SizedBox(height: 16),
// //               _buildDropdown('Priority', _getPriorityString(_selectedPriority), _priorityOptions, (value) {
// //                 setState(() {
// //                   _selectedPriority = _getPriorityFromString(value!);
// //                 });
// //               }),
// //               SizedBox(height: 24),
// //               SizedBox(
// //                 width: double.infinity,
// //                 height: 50,
// //                 child: ElevatedButton(
// //                   onPressed: _createTask,
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: const Color(0xFF77588D),
// //                     foregroundColor: Colors.white,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                   ),
// //                   child: Text(
// //                     widget.task != null ? 'Update Task' : 'Create Task',
// //                     style: TextStyle(fontSize: 16),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField({
// //     required String label,
// //     required TextEditingController controller,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 16,
// //             fontWeight: FontWeight.w500,
// //             color: Colors.black87,
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         Container(
// //           decoration: BoxDecoration(
// //             border: Border.all(color: Colors.grey.shade300),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: TextField(
// //             controller: controller,
// //             decoration: InputDecoration(
// //               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
// //               border: InputBorder.none,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildDateSelector() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Set Date',
// //           style: TextStyle(
// //             fontSize: 16,
// //             fontWeight: FontWeight.w500,
// //             color: Colors.black87,
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         GestureDetector(
// //           onTap: () => _selectDate(context),
// //           child: Container(
// //             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF77588D),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   DateFormat('dd/MM/yyyy').format(_selectedDate),
// //                   style: TextStyle(color: Colors.white),
// //                 ),
// //                 Icon(
// //                   Icons.calendar_today,
// //                   color: Colors.white,
// //                   size: 18,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildTimeSelector(String label, TimeOfDay time, Function(BuildContext) onTap) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 16,
// //             fontWeight: FontWeight.w500,
// //             color: Colors.black87,
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         GestureDetector(
// //           onTap: () => onTap(context),
// //           child: Container(
// //             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF77588D),
// //               borderRadius: BorderRadius.circular(24),
// //             ),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   _formatTimeOfDay(time),
// //                   style: TextStyle(color: Colors.white),
// //                 ),
// //                 Icon(
// //                   Icons.access_time,
// //                   color: Colors.white,
// //                   size: 18,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildDropdown(
// //       String label,
// //       String selectedValue,
// //       List<String> options,
// //       void Function(String?) onChanged,
// //       ) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 16,
// //             fontWeight: FontWeight.w500,
// //             color: Colors.black87,
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         Container(
// //           padding: EdgeInsets.symmetric(horizontal: 12),
// //           decoration: BoxDecoration(
// //             border: Border.all(color: Colors.grey.shade300),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: DropdownButtonHideUnderline(
// //             child: DropdownButton<String>(
// //               value: selectedValue,
// //               isExpanded: true,
// //               icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF77588D)),
// //               items: options.map((String value) {
// //                 return DropdownMenuItem<String>(
// //                   value: value,
// //                   child: Text(value),
// //                 );
// //               }).toList(),
// //               onChanged: onChanged,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   String _formatTimeOfDay(TimeOfDay timeOfDay) {
// //     final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
// //     final minute = timeOfDay.minute.toString().padLeft(2, '0');
// //     final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
// //     return '$hour.$minute$period';
// //   }
// //
// //   String _getPriorityString(Priority priority) {
// //     switch (priority) {
// //       case Priority.low:
// //         return 'Low';
// //       case Priority.medium:
// //         return 'Medium';
// //       case Priority.high:
// //         return 'High';
// //     }
// //   }
// //
// //   Priority _getPriorityFromString(String priorityString) {
// //     switch (priorityString) {
// //       case 'Low':
// //         return Priority.low;
// //       case 'Medium':
// //         return Priority.medium;
// //       case 'High':
// //         return Priority.high;
// //       default:
// //         return Priority.medium;
// //     }
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import '../models/task_model.dart';
// import 'package:intl/intl.dart';
// import '../utils/formatters.dart';
//
// class AddTaskOverlay extends StatefulWidget {
//   final Function(Task) onTaskCreated;
//   final Task? task;
//   final DateTime? initialDate;
//
//   const AddTaskOverlay({
//     Key? key,
//     required this.onTaskCreated,
//     this.task,
//     this.initialDate,
//   }) : super(key: key);
//
//   @override
//   _AddTaskOverlayState createState() => _AddTaskOverlayState();
// }
//
// class _AddTaskOverlayState extends State<AddTaskOverlay> {
//   late TextEditingController _titleController;
//   late TextEditingController _descriptionController;
//   late DateTime _selectedDate;
//   late TimeOfDay _startTime;
//   late TimeOfDay _endTime;
//   late String _selectedReminder;
//   late String _selectedRepeat;
//   late Priority _selectedPriority;
//
//   final List<String> _reminderOptions = ['5 minutes early', '10 minutes early', '15 minutes early', '30 minutes early'];
//   final List<String> _repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly'];
//   final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize with provided task or defaults
//     _titleController = TextEditingController(text: widget.task?.title ?? '');
//     _descriptionController = TextEditingController(text: widget.task?.description ?? '');
//
//     // Use initialDate if provided, otherwise fallback to the task date or today
//     _selectedDate = widget.task?.date ?? widget.initialDate ?? DateTime.now();
//
//     _startTime = widget.task?.startTime ?? TimeOfDay(hour: 9, minute: 0);
//     _endTime = widget.task?.endTime ?? TimeOfDay(hour: 10, minute: 0);
//     _selectedReminder = widget.task?.remindBefore ?? _reminderOptions[0];
//     _selectedRepeat = widget.task?.repeat ?? _repeatOptions[0];
//     _selectedPriority = widget.task?.priority ?? Priority.medium;
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now().subtract(Duration(days: 365)), // Allow past dates for flexibility
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: const Color(0xFF503663),
//               onPrimary: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime,
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: const Color(0xFF503663),
//               onPrimary: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _startTime) {
//       setState(() {
//         _startTime = picked;
//         // If end time is before start time, adjust it
//         if (_timeOfDayToDouble(_endTime) < _timeOfDayToDouble(_startTime)) {
//           _endTime = TimeOfDay(
//             hour: _startTime.hour + 1,
//             minute: _startTime.minute,
//           );
//         }
//       });
//     }
//   }
//
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime,
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: const Color(0xFF503663),
//               onPrimary: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _endTime) {
//       setState(() {
//         _endTime = picked;
//       });
//     }
//   }
//
//   double _timeOfDayToDouble(TimeOfDay time) {
//     return time.hour + time.minute / 60.0;
//   }
//
//   void _createTask() {
//     if (_titleController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter a title')),
//       );
//       return;
//     }
//
//     final newTask = Task(
//       title: _titleController.text,
//       description: _descriptionController.text,
//       date: _selectedDate,
//       startTime: _startTime,
//       endTime: _endTime,
//       priority: _selectedPriority,
//       remindBefore: _selectedReminder,
//       repeat: _selectedRepeat,
//       isCompleted: widget.task?.isCompleted ?? false,
//     );
//
//     widget.onTaskCreated(newTask);
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         padding: EdgeInsets.all(20),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     widget.task != null ? 'Edit Task' : 'Add Task',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF503663),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.close, color: Colors.black),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//               _buildTextField(
//                 label: 'Title',
//                 controller: _titleController,
//               ),
//               SizedBox(height: 16),
//               _buildTextField(
//                 label: 'Description',
//                 controller: _descriptionController,
//               ),
//               SizedBox(height: 16),
//               _buildDateSelector(),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(child: _buildTimeSelector('Start Time', _startTime, _selectStartTime)),
//                   SizedBox(width: 16),
//                   Expanded(child: _buildTimeSelector('End Time', _endTime, _selectEndTime)),
//                 ],
//               ),
//               SizedBox(height: 16),
//               _buildDropdown('Remind', _selectedReminder, _reminderOptions, (value) {
//                 setState(() {
//                   _selectedReminder = value!;
//                 });
//               }),
//               SizedBox(height: 16),
//               _buildDropdown('Repeat', _selectedRepeat, _repeatOptions, (value) {
//                 setState(() {
//                   _selectedRepeat = value!;
//                 });
//               }),
//               SizedBox(height: 16),
//               _buildDropdown('Priority', _getPriorityString(_selectedPriority), _priorityOptions, (value) {
//                 setState(() {
//                   _selectedPriority = _getPriorityFromString(value!);
//                 });
//               }),
//               SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _createTask,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF77588D),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     widget.task != null ? 'Update Task' : 'Create Task',
//                     style: TextStyle(fontSize: 16),
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
//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDateSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Set Date',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: 8),
//         GestureDetector(
//           onTap: () => _selectDate(context),
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//             decoration: BoxDecoration(
//               color: const Color(0xFF77588D),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   Formatters.formatDate(_selectedDate),
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 Icon(
//                   Icons.calendar_today,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTimeSelector(String label, TimeOfDay time, Function(BuildContext) onTap) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: 8),
//         GestureDetector(
//           onTap: () => onTap(context),
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//             decoration: BoxDecoration(
//               color: const Color(0xFF77588D),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   Formatters.formatTimeOfDay(time),
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 Icon(
//                   Icons.access_time,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDropdown(
//       String label,
//       String selectedValue,
//       List<String> options,
//       void Function(String?) onChanged,
//       ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: 8),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedValue,
//               isExpanded: true,
//               icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF77588D)),
//               items: options.map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: onChanged,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _getPriorityString(Priority priority) {
//     switch (priority) {
//       case Priority.low:
//         return 'Low';
//       case Priority.medium:
//         return 'Medium';
//       case Priority.high:
//         return 'High';
//     }
//   }
//
//   Priority _getPriorityFromString(String priorityString) {
//     switch (priorityString) {
//       case 'Low':
//         return Priority.low;
//       case 'Medium':
//         return Priority.medium;
//       case 'High':
//         return Priority.high;
//       default:
//         return Priority.medium;
//     }
//   }
// }

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';
import '../utils/formatters.dart';

class AddTaskOverlay extends StatefulWidget {
  final Function(Task) onTaskCreated;
  final Task? task;
  final DateTime? initialDate;
  final String? voiceInputDetails;

  const AddTaskOverlay({
    Key? key,
    required this.onTaskCreated,
    this.task,
    this.initialDate,
    this.voiceInputDetails,
  }) : super(key: key);

  @override
  _AddTaskOverlayState createState() => _AddTaskOverlayState();
}

class _AddTaskOverlayState extends State<AddTaskOverlay> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedReminder;
  late String _selectedRepeat;
  late Priority _selectedPriority;

  final List<String> _reminderOptions = ['5 minutes early', '10 minutes early', '15 minutes early', '30 minutes early'];
  final List<String> _repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly'];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();

    // Initialize with provided task or defaults
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');

    // Use initialDate if provided, otherwise fallback to the task date or today
    _selectedDate = widget.task?.date ?? widget.initialDate ?? DateTime.now();

    _startTime = widget.task?.startTime ?? TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.task?.endTime ?? TimeOfDay(hour: 10, minute: 0);
    _selectedReminder = widget.task?.remindBefore ?? _reminderOptions[0];
    _selectedRepeat = widget.task?.repeat ?? _repeatOptions[0];
    _selectedPriority = widget.task?.priority ?? Priority.medium;

    // Parse voice input if provided
    if (widget.voiceInputDetails != null) {
      _parseVoiceInput(widget.voiceInputDetails!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _parseVoiceInput(String voiceInput) {
    // Convert to lowercase for easier parsing
    final lowerInput = voiceInput.toLowerCase();

    // Try to extract title
    _titleController.text = _extractTitle(lowerInput);

    // Try to extract description
    _descriptionController.text = _extractDescription(lowerInput);

    // Try to extract priority
    final priority = _extractPriority(lowerInput);
    if (priority != null) {
      _selectedPriority = priority;
    }

    // Try to extract time
    final extractedTimes = _extractTimes(lowerInput);
    if (extractedTimes != null) {
      _startTime = extractedTimes['start'] ?? _startTime;
      _endTime = extractedTimes['end'] ?? _endTime;
    }
  }

  String _extractTitle(String input) {
    // List of words to ignore when extracting title
    final ignoredWords = [
      'create', 'add', 'new', 'task', 'make', 'with', 'a', 'an', 'the',
      'at', 'on', 'today', 'tomorrow', 'high', 'medium', 'low', 'priority'
    ];

    // Split input into words
    // Split input into words
    final words = input.split(' ');

    // Remove ignored words
    final titleWords = words.where((word) =>
    !ignoredWords.contains(word.toLowerCase())).toList();

    return titleWords.isNotEmpty ? titleWords.join(' ') : 'New Task';
  }

  String _extractDescription(String input) {
    // This is a simple implementation. You might want to enhance this.
    return ''; // Could extract more context if needed
  }

  Priority? _extractPriority(String input) {
    if (input.contains('high priority')) {
      return Priority.high;
    } else if (input.contains('medium priority')) {
      return Priority.medium;
    } else if (input.contains('low priority')) {
      return Priority.low;
    }
    return null;
  }

  Map<String, TimeOfDay>? _extractTimes(String input) {
    // Basic time extraction using regex patterns
    final timeRegex = RegExp(r'(\d{1,2}(?::\d{2})?\s*(?:am|pm))', caseSensitive: false);
    final matches = timeRegex.allMatches(input);

    if (matches.length >= 2) {
      try {
        final startMatch = matches.elementAt(0).group(0)!;
        final endMatch = matches.elementAt(1).group(0)!;

        return {
          'start': _parseTimeString(startMatch),
          'end': _parseTimeString(endMatch),
        };
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Remove whitespace and convert to lowercase
    timeStr = timeStr.trim().toLowerCase();

    // Determine AM or PM
    final isPM = timeStr.contains('pm');
    final isAM = timeStr.contains('am');

    // Remove am/pm
    timeStr = timeStr.replaceAll(RegExp(r'am|pm'), '').trim();

    // Split hours and minutes
    final parts = timeStr.split(':');
    int hour = int.parse(parts[0]);
    int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    // Adjust hour for PM
    if (isPM && hour != 12) {
      hour += 12;
    }
    // Adjust hour for AM
    if (isAM && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)), // Allow past dates for flexibility
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF503663),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF503663),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // If end time is before start time, adjust it
        if (_timeOfDayToDouble(_endTime) < _timeOfDayToDouble(_startTime)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF503663),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final newTask = Task(
      title: _titleController.text,
      description: _descriptionController.text,
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      priority: _selectedPriority,
      remindBefore: _selectedReminder,
      repeat: _selectedRepeat,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    widget.onTaskCreated(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task != null ? 'Edit Task' : 'Add Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF503663),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildTextField(
                label: 'Title',
                controller: _titleController,
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: 'Description',
                controller: _descriptionController,
              ),
              SizedBox(height: 16),
              _buildDateSelector(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimeSelector('Start Time', _startTime, _selectStartTime)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTimeSelector('End Time', _endTime, _selectEndTime)),
                ],
              ),
              SizedBox(height: 16),
              _buildDropdown('Remind', _selectedReminder, _reminderOptions, (value) {
                setState(() {
                  _selectedReminder = value!;
                });
              }),
              SizedBox(height: 16),
              _buildDropdown('Repeat', _selectedRepeat, _repeatOptions, (value) {
                setState(() {
                  _selectedRepeat = value!;
                });
              }),
              SizedBox(height: 16),
              _buildDropdown('Priority', _getPriorityString(_selectedPriority), _priorityOptions, (value) {
                setState(() {
                  _selectedPriority = _getPriorityFromString(value!);
                });
              }),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF77588D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.task != null ? 'Update Task' : 'Create Task',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF77588D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDate(_selectedDate),
                  style: TextStyle(color: Colors.white),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, Function(BuildContext) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => onTap(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF77588D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatTimeOfDay(time),
                  style: TextStyle(color: Colors.white),
                ),
                Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      String selectedValue,
      List<String> options,
      void Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF77588D)),
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _getPriorityString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  Priority _getPriorityFromString(String priorityString) {
    switch (priorityString) {
      case 'Low':
        return Priority.low;
      case 'Medium':
        return Priority.medium;
      case 'High':
        return Priority.high;
      default:
        return Priority.medium;
    }
  }
}