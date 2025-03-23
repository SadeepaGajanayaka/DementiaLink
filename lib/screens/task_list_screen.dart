// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:intl/intl.dart';
// // // // // // import '../models/task_model.dart';
// // // // // // import '../widgets/add_task_overlay.dart';
// // // // // // import '../widgets/task_options_overalay.dart';
// // // // // //
// // // // // // class TaskListScreen extends StatefulWidget {
// // // // // //   @override
// // // // // //   _TaskListScreenState createState() => _TaskListScreenState();
// // // // // // }
// // // // // //
// // // // // // class _TaskListScreenState extends State<TaskListScreen> {
// // // // // //   List<Task> tasks = [
// // // // // //     Task(
// // // // // //       title: 'Take Medicines Daily',
// // // // // //       description: '2 Antibiotics per day',
// // // // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // // // //       date: DateTime.now(),
// // // // // //       priority: Priority.high,
// // // // // //       remindBefore: '5 minutes early',
// // // // // //       repeat: 'None',
// // // // // //     ),
// // // // // //     Task(
// // // // // //       title: 'Doctor Appointment',
// // // // // //       description: 'Dr.Sumanathilake - Check',
// // // // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // // // //       date: DateTime.now(),
// // // // // //       priority: Priority.low,
// // // // // //       remindBefore: '5 minutes early',
// // // // // //       repeat: 'None',
// // // // // //     ),
// // // // // //   ];
// // // // // //
// // // // // //   int selectedDateIndex = 0;
// // // // // //   late List<DateTime> weekDates;
// // // // // //
// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _generateWeekDates();
// // // // // //   }
// // // // // //
// // // // // //   void _generateWeekDates() {
// // // // // //     DateTime now = DateTime.now();
// // // // // //     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
// // // // // //     weekDates = List.generate(
// // // // // //       4,
// // // // // //           (index) => startOfWeek.add(Duration(days: index)),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   void _showAddTaskOverlay() {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierColor: Colors.black54,
// // // // // //       builder: (context) => AddTaskOverlay(
// // // // // //         onTaskCreated: (Task newTask) {
// // // // // //           setState(() {
// // // // // //             tasks.add(newTask);
// // // // // //           });
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   void _showTaskOptionsOverlay(Task task, int index) {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierColor: Colors.black54,
// // // // // //       builder: (context) => TaskOptionsOverlay(
// // // // // //         onEditTask: () {
// // // // // //           Navigator.pop(context);
// // // // // //           _editTask(task, index);
// // // // // //         },
// // // // // //         onTaskCompleted: () {
// // // // // //           setState(() {
// // // // // //             task.isCompleted = true;
// // // // // //           });
// // // // // //           Navigator.pop(context);
// // // // // //         },
// // // // // //         onDeleteTask: () {
// // // // // //           setState(() {
// // // // // //             tasks.removeAt(index);
// // // // // //           });
// // // // // //           Navigator.pop(context);
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   void _editTask(Task task, int index) {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierColor: Colors.black54,
// // // // // //       builder: (context) => AddTaskOverlay(
// // // // // //         task: task,
// // // // // //         onTaskCreated: (Task updatedTask) {
// // // // // //           setState(() {
// // // // // //             tasks[index] = updatedTask;
// // // // // //           });
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       body: SafeArea(
// // // // // //         child: Column(
// // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //           children: [
// // // // // //             _buildHeader(),
// // // // // //             _buildSearchBar(),
// // // // // //             _buildDateSelector(),
// // // // // //             Padding(
// // // // // //               padding: const EdgeInsets.all(16.0),
// // // // // //               child: Text(
// // // // // //                 'Today task',
// // // // // //                 style: TextStyle(
// // // // // //                   fontSize: 22,
// // // // // //                   fontWeight: FontWeight.bold,
// // // // // //                   color: Colors.white,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //             Expanded(
// // // // // //               child: _buildTaskList(),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //       floatingActionButton: FloatingActionButton(
// // // // // //         onPressed: _showAddTaskOverlay,
// // // // // //         backgroundColor: const Color(0xFF77588D),
// // // // // //         child: const Icon(Icons.add, color: Colors.white),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Widget _buildHeader() {
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.all(16.0),
// // // // // //       child: Row(
// // // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // //         children: [
// // // // // //           Row(
// // // // // //             children: [
// // // // // //               IconButton(
// // // // // //                 icon: const Icon(Icons.arrow_back, color: Colors.white),
// // // // // //                 onPressed: () {},
// // // // // //               ),
// // // // // //               const SizedBox(width: 8),
// // // // // //               const Text(
// // // // // //                 'You have 7 tasks to complete\ntoday',
// // // // // //                 style: TextStyle(
// // // // // //                   fontSize: 18,
// // // // // //                   fontWeight: FontWeight.bold,
// // // // // //                   color: Colors.white,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //           Container(
// // // // // //             decoration: BoxDecoration(
// // // // // //               color: Colors.white.withOpacity(0.3),
// // // // // //               shape: BoxShape.circle,
// // // // // //             ),
// // // // // //             child: IconButton(
// // // // // //               icon: const Icon(Icons.notifications_none, color: Colors.white),
// // // // // //               onPressed: () {},
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Widget _buildSearchBar() {
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // // //       child: Container(
// // // // // //         decoration: BoxDecoration(
// // // // // //           color: Colors.white.withOpacity(0.2),
// // // // // //           borderRadius: BorderRadius.circular(30),
// // // // // //         ),
// // // // // //         child: TextField(
// // // // // //           decoration: InputDecoration(
// // // // // //             hintText: 'Search Reminders........',
// // // // // //             hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
// // // // // //             prefixIcon: const Icon(Icons.search, color: Colors.white),
// // // // // //             suffixIcon: const Icon(Icons.mic, color: Colors.white),
// // // // // //             border: InputBorder.none,
// // // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 15),
// // // // // //           ),
// // // // // //           style: const TextStyle(color: Colors.white),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Widget _buildDateSelector() {
// // // // // //     return Container(
// // // // // //       height: 100,
// // // // // //       margin: const EdgeInsets.only(top: 16),
// // // // // //       child: ListView.builder(
// // // // // //         scrollDirection: Axis.horizontal,
// // // // // //         itemCount: weekDates.length,
// // // // // //         itemBuilder: (context, index) {
// // // // // //           final date = weekDates[index];
// // // // // //           final isSelected = index == selectedDateIndex;
// // // // // //
// // // // // //           return GestureDetector(
// // // // // //             onTap: () {
// // // // // //               setState(() {
// // // // // //                 selectedDateIndex = index;
// // // // // //               });
// // // // // //             },
// // // // // //             child: Container(
// // // // // //               width: 80,
// // // // // //               margin: const EdgeInsets.only(left: 16),
// // // // // //               decoration: BoxDecoration(
// // // // // //                 color: isSelected
// // // // // //                     ? Colors.white
// // // // // //                     : const Color(0xFF77588D).withOpacity(0.4),
// // // // // //                 borderRadius: BorderRadius.circular(10),
// // // // // //               ),
// // // // // //               child: Column(
// // // // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // // // //                 children: [
// // // // // //                   Text(
// // // // // //                     'SEP',
// // // // // //                     style: TextStyle(
// // // // // //                       fontSize: 14,
// // // // // //                       fontWeight: FontWeight.bold,
// // // // // //                       color: isSelected
// // // // // //                           ? const Color(0xFF503663)
// // // // // //                           : Colors.white,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 8),
// // // // // //                   Text(
// // // // // //                     date.day.toString(),
// // // // // //                     style: TextStyle(
// // // // // //                       fontSize: 24,
// // // // // //                       fontWeight: FontWeight.bold,
// // // // // //                       color: isSelected
// // // // // //                           ? const Color(0xFF503663)
// // // // // //                           : Colors.white,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 4),
// // // // // //                   Text(
// // // // // //                     DateFormat('EEE').format(date).toUpperCase(),
// // // // // //                     style: TextStyle(
// // // // // //                       fontSize: 12,
// // // // // //                       color: isSelected
// // // // // //                           ? const Color(0xFF503663)
// // // // // //                           : Colors.white,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //           );
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Widget _buildTaskList() {
// // // // // //     return ListView.builder(
// // // // // //       itemCount: tasks.length,
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // //       itemBuilder: (context, index) {
// // // // // //         final task = tasks[index];
// // // // // //         return Container(
// // // // // //           margin: const EdgeInsets.only(bottom: 16),
// // // // // //           decoration: BoxDecoration(
// // // // // //             color: Colors.white,
// // // // // //             borderRadius: BorderRadius.circular(12),
// // // // // //           ),
// // // // // //           child: ListTile(
// // // // // //             contentPadding: const EdgeInsets.all(16),
// // // // // //             title: Text(
// // // // // //               task.title,
// // // // // //               style: const TextStyle(
// // // // // //                 color: Colors.black,
// // // // // //                 fontWeight: FontWeight.bold,
// // // // // //                 fontSize: 18,
// // // // // //               ),
// // // // // //             ),
// // // // // //             subtitle: Column(
// // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //               children: [
// // // // // //                 Text(
// // // // // //                   task.description,
// // // // // //                   style: TextStyle(
// // // // // //                     color: Colors.grey[700],
// // // // // //                     fontSize: 14,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 Row(
// // // // // //                   children: [
// // // // // //                     Container(
// // // // // //                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // // //                       decoration: BoxDecoration(
// // // // // //                         color: const Color(0xFF77588D).withOpacity(0.2),
// // // // // //                         borderRadius: BorderRadius.circular(4),
// // // // // //                       ),
// // // // // //                       child: Row(
// // // // // //                         children: [
// // // // // //                           Icon(
// // // // // //                             Icons.calendar_today,
// // // // // //                             size: 14,
// // // // // //                             color: const Color(0xFF77588D),
// // // // // //                           ),
// // // // // //                           const SizedBox(width: 4),
// // // // // //                           Text(
// // // // // //                             'Today',
// // // // // //                             style: TextStyle(
// // // // // //                               color: const Color(0xFF77588D),
// // // // // //                               fontSize: 12,
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         ],
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 Row(
// // // // // //                   children: [
// // // // // //                     Icon(
// // // // // //                       Icons.access_time,
// // // // // //                       size: 16,
// // // // // //                       color: Colors.purple[900],
// // // // // //                     ),
// // // // // //                     const SizedBox(width: 4),
// // // // // //                     Text(
// // // // // //                       '${_formatTimeOfDay(task.startTime)} - ${_formatTimeOfDay(task.endTime)}',
// // // // // //                       style: TextStyle(
// // // // // //                         color: Colors.grey[700],
// // // // // //                         fontSize: 12,
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 Row(
// // // // // //                   children: [
// // // // // //                     Icon(
// // // // // //                       Icons.flag,
// // // // // //                       size: 16,
// // // // // //                       color: Colors.purple[900],
// // // // // //                     ),
// // // // // //                     const SizedBox(width: 4),
// // // // // //                     Text(
// // // // // //                       task.priority == Priority.high ? 'High Priority' : 'Low Priority',
// // // // // //                       style: TextStyle(
// // // // // //                         color: Colors.grey[700],
// // // // // //                         fontSize: 12,
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //             trailing: IconButton(
// // // // // //               icon: const Icon(Icons.more_vert),
// // // // // //               onPressed: () => _showTaskOptionsOverlay(task, index),
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   String _formatTimeOfDay(TimeOfDay timeOfDay) {
// // // // // //     final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
// // // // // //     final minute = timeOfDay.minute.toString().padLeft(2, '0');
// // // // // //     final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
// // // // // //     return '$hour.$minute$period';
// // // // // //   }
// // // // // // }
// // // // //
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:intl/intl.dart';
// // // // // import '../models/task_model.dart';
// // // // // import '../widgets/add_task_overlay.dart';
// // // // // import '../widgets/task_options_overalay.dart';
// // // // // import '../utils/formatters.dart';
// // // // //
// // // // // class TaskListScreen extends StatefulWidget {
// // // // //   @override
// // // // //   _TaskListScreenState createState() => _TaskListScreenState();
// // // // // }
// // // // //
// // // // // class _TaskListScreenState extends State<TaskListScreen> {
// // // // //   List<Task> tasks = [
// // // // //     Task(
// // // // //       title: 'Take Medicines Daily',
// // // // //       description: '2 Antibiotics per day',
// // // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // // //       date: DateTime.now(),
// // // // //       priority: Priority.high,
// // // // //       remindBefore: '5 minutes early',
// // // // //       repeat: 'None',
// // // // //     ),
// // // // //     Task(
// // // // //       title: 'Doctor Appointment',
// // // // //       description: 'Dr.Sumanathilake - Check',
// // // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // // //       date: DateTime.now(),
// // // // //       priority: Priority.low,
// // // // //       remindBefore: '5 minutes early',
// // // // //       repeat: 'None',
// // // // //     ),
// // // // //   ];
// // // // //
// // // // //   int selectedDateIndex = 0;
// // // // //   late List<DateTime> weekDates;
// // // // //
// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _generateWeekDates();
// // // // //   }
// // // // //
// // // // //   void _generateWeekDates() {
// // // // //     DateTime now = DateTime.now();
// // // // //     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
// // // // //     weekDates = List.generate(
// // // // //       4,
// // // // //           (index) => startOfWeek.add(Duration(days: index)),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   void _showAddTaskOverlay() {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierColor: Colors.black54,
// // // // //       builder: (context) => AddTaskOverlay(
// // // // //         onTaskCreated: (Task newTask) {
// // // // //           setState(() {
// // // // //             tasks.add(newTask);
// // // // //           });
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   void _showTaskOptionsOverlay(Task task, int index) {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierColor: Colors.black54,
// // // // //       builder: (context) => TaskOptionsOverlay(
// // // // //         onEditTask: () {
// // // // //           Navigator.pop(context);
// // // // //           _editTask(task, index);
// // // // //         },
// // // // //         onTaskCompleted: () {
// // // // //           setState(() {
// // // // //             task.isCompleted = true;
// // // // //           });
// // // // //           Navigator.pop(context);
// // // // //         },
// // // // //         onDeleteTask: () {
// // // // //           setState(() {
// // // // //             tasks.removeAt(index);
// // // // //           });
// // // // //           Navigator.pop(context);
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   void _editTask(Task task, int index) {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierColor: Colors.black54,
// // // // //       builder: (context) => AddTaskOverlay(
// // // // //         task: task,
// // // // //         onTaskCreated: (Task updatedTask) {
// // // // //           setState(() {
// // // // //             tasks[index] = updatedTask;
// // // // //           });
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Get tasks for the selected date
// // // // //   List<Task> _getTasksForSelectedDate() {
// // // // //     if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
// // // // //       return [];
// // // // //     }
// // // // //
// // // // //     DateTime selectedDate = weekDates[selectedDateIndex];
// // // // //     return tasks.where((task) {
// // // // //       return _isSameDay(task.date, selectedDate);
// // // // //     }).toList();
// // // // //   }
// // // // //
// // // // //   // Check if two dates are the same day
// // // // //   bool _isSameDay(DateTime date1, DateTime date2) {
// // // // //     return date1.year == date2.year &&
// // // // //         date1.month == date2.month &&
// // // // //         date1.day == date2.day;
// // // // //   }
// // // // //
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     // Get tasks for the selected date
// // // // //     List<Task> tasksForSelectedDate = _getTasksForSelectedDate();
// // // // //
// // // // //     return Scaffold(
// // // // //       body: SafeArea(
// // // // //         child: Column(
// // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // //           children: [
// // // // //             _buildHeader(),
// // // // //             _buildSearchBar(),
// // // // //             _buildDateSelector(),
// // // // //             Padding(
// // // // //               padding: const EdgeInsets.all(16.0),
// // // // //               child: Text(
// // // // //                 'Today task',
// // // // //                 style: TextStyle(
// // // // //                   fontSize: 22,
// // // // //                   fontWeight: FontWeight.bold,
// // // // //                   color: Colors.white,
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //             Expanded(
// // // // //               child: tasksForSelectedDate.isEmpty
// // // // //                   ? _buildEmptyState()
// // // // //                   : _buildTaskList(tasksForSelectedDate),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //       floatingActionButton: FloatingActionButton(
// // // // //         onPressed: _showAddTaskOverlay,
// // // // //         backgroundColor: const Color(0xFF77588D),
// // // // //         child: const Icon(Icons.add, color: Colors.white),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Widget _buildEmptyState() {
// // // // //     return Center(
// // // // //       child: Column(
// // // // //         mainAxisAlignment: MainAxisAlignment.center,
// // // // //         children: [
// // // // //           Icon(
// // // // //             Icons.event_note,
// // // // //             size: 80,
// // // // //             color: Colors.white.withOpacity(0.5),
// // // // //           ),
// // // // //           SizedBox(height: 16),
// // // // //           Text(
// // // // //             'No tasks for this day',
// // // // //             style: TextStyle(
// // // // //               fontSize: 18,
// // // // //               color: Colors.white.withOpacity(0.7),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 24),
// // // // //           ElevatedButton.icon(
// // // // //             onPressed: _showAddTaskOverlay,
// // // // //             icon: Icon(Icons.add),
// // // // //             label: Text('Add a Task'),
// // // // //             style: ElevatedButton.styleFrom(
// // // // //               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Widget _buildHeader() {
// // // // //     // Count active tasks for the selected date
// // // // //     final activeTasks = _getTasksForSelectedDate()
// // // // //         .where((task) => !task.isCompleted)
// // // // //         .length;
// // // // //
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.all(16.0),
// // // // //       child: Row(
// // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //         children: [
// // // // //           Row(
// // // // //             children: [
// // // // //               IconButton(
// // // // //                 icon: const Icon(Icons.arrow_back, color: Colors.white),
// // // // //                 onPressed: () {},
// // // // //               ),
// // // // //               const SizedBox(width: 8),
// // // // //               Text(
// // // // //                 'You have $activeTasks tasks to complete\ntoday',
// // // // //                 style: const TextStyle(
// // // // //                   fontSize: 18,
// // // // //                   fontWeight: FontWeight.bold,
// // // // //                   color: Colors.white,
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           Container(
// // // // //             decoration: BoxDecoration(
// // // // //               color: Colors.white.withOpacity(0.3),
// // // // //               shape: BoxShape.circle,
// // // // //             ),
// // // // //             child: IconButton(
// // // // //               icon: const Icon(Icons.notifications_none, color: Colors.white),
// // // // //               onPressed: () {},
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Widget _buildSearchBar() {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // //       child: Container(
// // // // //         decoration: BoxDecoration(
// // // // //           color: Colors.white.withOpacity(0.2),
// // // // //           borderRadius: BorderRadius.circular(30),
// // // // //         ),
// // // // //         child: TextField(
// // // // //           decoration: InputDecoration(
// // // // //             hintText: 'Search Reminders........',
// // // // //             hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
// // // // //             prefixIcon: const Icon(Icons.search, color: Colors.white),
// // // // //             suffixIcon: const Icon(Icons.mic, color: Colors.white),
// // // // //             border: InputBorder.none,
// // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 15),
// // // // //           ),
// // // // //           style: const TextStyle(color: Colors.white),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Widget _buildDateSelector() {
// // // // //     return Container(
// // // // //       height: 100,
// // // // //       margin: const EdgeInsets.only(top: 16),
// // // // //       child: ListView.builder(
// // // // //         scrollDirection: Axis.horizontal,
// // // // //         itemCount: weekDates.length,
// // // // //         itemBuilder: (context, index) {
// // // // //           final date = weekDates[index];
// // // // //           final isSelected = index == selectedDateIndex;
// // // // //
// // // // //           return GestureDetector(
// // // // //             onTap: () {
// // // // //               setState(() {
// // // // //                 selectedDateIndex = index;
// // // // //               });
// // // // //             },
// // // // //             child: Container(
// // // // //               width: 80,
// // // // //               margin: const EdgeInsets.only(left: 16),
// // // // //               decoration: BoxDecoration(
// // // // //                 color: isSelected
// // // // //                     ? Colors.white
// // // // //                     : const Color(0xFF77588D).withOpacity(0.4),
// // // // //                 borderRadius: BorderRadius.circular(10),
// // // // //               ),
// // // // //               child: Column(
// // // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // // //                 children: [
// // // // //                   Text(
// // // // //                     Formatters.getMonthAbbreviation(date),
// // // // //                     style: TextStyle(
// // // // //                       fontSize: 14,
// // // // //                       fontWeight: FontWeight.bold,
// // // // //                       color: isSelected
// // // // //                           ? const Color(0xFF503663)
// // // // //                           : Colors.white,
// // // // //                     ),
// // // // //                   ),
// // // // //                   const SizedBox(height: 8),
// // // // //                   Text(
// // // // //                     date.day.toString(),
// // // // //                     style: TextStyle(
// // // // //                       fontSize: 24,
// // // // //                       fontWeight: FontWeight.bold,
// // // // //                       color: isSelected
// // // // //                           ? const Color(0xFF503663)
// // // // //                           : Colors.white,
// // // // //                     ),
// // // // //                   ),
// // // // //                   const SizedBox(height: 4),
// // // // //                   Text(
// // // // //                     Formatters.getDayAbbreviation(date),
// // // // //                     style: TextStyle(
// // // // //                       fontSize: 12,
// // // // //                       color: isSelected
// // // // //                           ? const Color(0xFF503663)
// // // // //                           : Colors.white,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           );
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Widget _buildTaskList(List<Task> tasksToShow) {
// // // // //     return ListView.builder(
// // // // //       itemCount: tasksToShow.length,
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // //       itemBuilder: (context, index) {
// // // // //         final task = tasksToShow[index];
// // // // //         return Container(
// // // // //           margin: const EdgeInsets.only(bottom: 16),
// // // // //           decoration: BoxDecoration(
// // // // //             color: Colors.white,
// // // // //             borderRadius: BorderRadius.circular(12),
// // // // //           ),
// // // // //           child: ListTile(
// // // // //             contentPadding: const EdgeInsets.all(16),
// // // // //             title: Text(
// // // // //               task.title,
// // // // //               style: TextStyle(
// // // // //                 color: Colors.black,
// // // // //                 fontWeight: FontWeight.bold,
// // // // //                 fontSize: 18,
// // // // //                 decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // // // //               ),
// // // // //             ),
// // // // //             subtitle: Column(
// // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // //               children: [
// // // // //                 Text(
// // // // //                   task.description,
// // // // //                   style: TextStyle(
// // // // //                     color: Colors.grey[700],
// // // // //                     fontSize: 14,
// // // // //                     decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 Row(
// // // // //                   children: [
// // // // //                     Container(
// // // // //                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // //                       decoration: BoxDecoration(
// // // // //                         color: const Color(0xFF77588D).withOpacity(0.2),
// // // // //                         borderRadius: BorderRadius.circular(4),
// // // // //                       ),
// // // // //                       child: Row(
// // // // //                         children: [
// // // // //                           Icon(
// // // // //                             Icons.calendar_today,
// // // // //                             size: 14,
// // // // //                             color: const Color(0xFF77588D),
// // // // //                           ),
// // // // //                           const SizedBox(width: 4),
// // // // //                           Text(
// // // // //                             _isSameDay(task.date, DateTime.now())
// // // // //                                 ? 'Today'
// // // // //                                 : Formatters.formatDate(task.date),
// // // // //                             style: TextStyle(
// // // // //                               color: const Color(0xFF77588D),
// // // // //                               fontSize: 12,
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 Row(
// // // // //                   children: [
// // // // //                     Icon(
// // // // //                       Icons.access_time,
// // // // //                       size: 16,
// // // // //                       color: Colors.purple[900],
// // // // //                     ),
// // // // //                     const SizedBox(width: 4),
// // // // //                     Text(
// // // // //                       '${Formatters.formatTimeOfDay(task.startTime)} - ${Formatters.formatTimeOfDay(task.endTime)}',
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.grey[700],
// // // // //                         fontSize: 12,
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 Row(
// // // // //                   children: [
// // // // //                     Icon(
// // // // //                       Icons.flag,
// // // // //                       size: 16,
// // // // //                       color: _getPriorityColor(task.priority),
// // // // //                     ),
// // // // //                     const SizedBox(width: 4),
// // // // //                     Text(
// // // // //                       _getPriorityText(task.priority),
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.grey[700],
// // // // //                         fontSize: 12,
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //             trailing: IconButton(
// // // // //               icon: const Icon(Icons.more_vert),
// // // // //               onPressed: () => _showTaskOptionsOverlay(task, tasks.indexOf(task)),
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       },
// // // // //     );
// // // // //   }
// // // // //
// // // // //   String _getPriorityText(Priority priority) {
// // // // //     switch (priority) {
// // // // //       case Priority.high:
// // // // //         return 'High Priority';
// // // // //       case Priority.medium:
// // // // //         return 'Medium Priority';
// // // // //       case Priority.low:
// // // // //         return 'Low Priority';
// // // // //     }
// // // // //   }
// // // // //
// // // // //   Color _getPriorityColor(Priority priority) {
// // // // //     switch (priority) {
// // // // //       case Priority.high:
// // // // //         return Colors.red;
// // // // //       case Priority.medium:
// // // // //         return Colors.orange;
// // // // //       case Priority.low:
// // // // //         return Colors.green;
// // // // //     }
// // // // //   }
// // // // // }
// // // //
// // // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:intl/intl.dart';
// // // // import '../models/task_model.dart';
// // // // import '../widgets/add_task_overlay.dart';
// // // // import '../widgets/task_options_overalay.dart';
// // // // import '../utils/formatters.dart';
// // // //
// // // // class TaskListScreen extends StatefulWidget {
// // // //   @override
// // // //   _TaskListScreenState createState() => _TaskListScreenState();
// // // // }
// // // //
// // // // class _TaskListScreenState extends State<TaskListScreen> {
// // // //   List<Task> tasks = [
// // // //     Task(
// // // //       title: 'Take Medicines Daily',
// // // //       description: '2 Antibiotics per day',
// // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // //       date: DateTime.now(),
// // // //       priority: Priority.high,
// // // //       remindBefore: '5 minutes early',
// // // //       repeat: 'None',
// // // //     ),
// // // //     Task(
// // // //       title: 'Doctor Appointment',
// // // //       description: 'Dr.Sumanathilake - Check',
// // // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // // //       date: DateTime.now(),
// // // //       priority: Priority.low,
// // // //       remindBefore: '5 minutes early',
// // // //       repeat: 'None',
// // // //     ),
// // // //   ];
// // // //
// // // //   int selectedDateIndex = 0;
// // // //   late List<DateTime> weekDates;
// // // //   late ScrollController _dateScrollController;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _dateScrollController = ScrollController();
// // // //     _generateWeekDates();
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _dateScrollController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   void _generateWeekDates() {
// // // //     DateTime now = DateTime.now();
// // // //     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
// // // //     // Generate 30 days instead of just 4
// // // //     weekDates = List.generate(
// // // //       30,
// // // //           (index) => startOfWeek.add(Duration(days: index)),
// // // //     );
// // // //   }
// // // //
// // // //   void _showAddTaskOverlay() {
// // // //     // Pass the selected date to the overlay
// // // //     final selectedDate = weekDates[selectedDateIndex];
// // // //
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierColor: Colors.black54,
// // // //       builder: (context) => AddTaskOverlay(
// // // //         // Pass the selected date to initialize the task with
// // // //         initialDate: selectedDate,
// // // //         onTaskCreated: (Task newTask) {
// // // //           setState(() {
// // // //             tasks.add(newTask);
// // // //           });
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _showTaskOptionsOverlay(Task task, int index) {
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierColor: Colors.black54,
// // // //       builder: (context) => TaskOptionsOverlay(
// // // //         onEditTask: () {
// // // //           Navigator.pop(context);
// // // //           _editTask(task, index);
// // // //         },
// // // //         onTaskCompleted: () {
// // // //           setState(() {
// // // //             task.isCompleted = true;
// // // //           });
// // // //           Navigator.pop(context);
// // // //         },
// // // //         onDeleteTask: () {
// // // //           setState(() {
// // // //             tasks.removeAt(index);
// // // //           });
// // // //           Navigator.pop(context);
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _editTask(Task task, int index) {
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierColor: Colors.black54,
// // // //       builder: (context) => AddTaskOverlay(
// // // //         task: task,
// // // //         initialDate: task.date,
// // // //         onTaskCreated: (Task updatedTask) {
// // // //           setState(() {
// // // //             tasks[index] = updatedTask;
// // // //           });
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Get tasks for the selected date
// // // //   List<Task> _getTasksForSelectedDate() {
// // // //     if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
// // // //       return [];
// // // //     }
// // // //
// // // //     DateTime selectedDate = weekDates[selectedDateIndex];
// // // //     return tasks.where((task) {
// // // //       return _isSameDay(task.date, selectedDate);
// // // //     }).toList();
// // // //   }
// // // //
// // // //   // Check if two dates are the same day
// // // //   bool _isSameDay(DateTime date1, DateTime date2) {
// // // //     return date1.year == date2.year &&
// // // //         date1.month == date2.month &&
// // // //         date1.day == date2.day;
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     // Get tasks for the selected date
// // // //     List<Task> tasksForSelectedDate = _getTasksForSelectedDate();
// // // //
// // // //     return Scaffold(
// // // //       body: SafeArea(
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             _buildHeader(),
// // // //             _buildSearchBar(),
// // // //             _buildDateSelector(),
// // // //             Padding(
// // // //               padding: const EdgeInsets.all(16.0),
// // // //               child: Text(
// // // //                 'Today task',
// // // //                 style: TextStyle(
// // // //                   fontSize: 22,
// // // //                   fontWeight: FontWeight.bold,
// // // //                   color: Colors.white,
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             Expanded(
// // // //               child: tasksForSelectedDate.isEmpty
// // // //                   ? _buildEmptyState()
// // // //                   : _buildTaskList(tasksForSelectedDate),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       floatingActionButton: FloatingActionButton(
// // // //         onPressed: _showAddTaskOverlay,
// // // //         backgroundColor: const Color(0xFF77588D),
// // // //         child: const Icon(Icons.add, color: Colors.white),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildEmptyState() {
// // // //     return Center(
// // // //       child: Column(
// // // //         mainAxisAlignment: MainAxisAlignment.center,
// // // //         children: [
// // // //           Icon(
// // // //             Icons.event_note,
// // // //             size: 80,
// // // //             color: Colors.white.withOpacity(0.5),
// // // //           ),
// // // //           SizedBox(height: 16),
// // // //           Text(
// // // //             'No tasks for this day',
// // // //             style: TextStyle(
// // // //               fontSize: 18,
// // // //               color: Colors.white.withOpacity(0.7),
// // // //             ),
// // // //           ),
// // // //           SizedBox(height: 24),
// // // //           ElevatedButton.icon(
// // // //             onPressed: _showAddTaskOverlay,
// // // //             icon: Icon(Icons.add),
// // // //             label: Text('Add a Task'),
// // // //             style: ElevatedButton.styleFrom(
// // // //               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildHeader() {
// // // //     // Count active tasks for the selected date
// // // //     final activeTasks = _getTasksForSelectedDate()
// // // //         .where((task) => !task.isCompleted)
// // // //         .length;
// // // //
// // // //     final selectedDate = weekDates[selectedDateIndex];
// // // //     final isToday = _isSameDay(selectedDate, DateTime.now());
// // // //     final dateText = isToday ? 'today' : 'on ${Formatters.formatDate(selectedDate)}';
// // // //
// // // //     return Padding(
// // // //       padding: const EdgeInsets.all(16.0),
// // // //       child: Row(
// // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //         children: [
// // // //           Expanded(
// // // //             child: Row(
// // // //               children: [
// // // //                 IconButton(
// // // //                   icon: const Icon(Icons.arrow_back, color: Colors.white),
// // // //                   onPressed: () {},
// // // //                 ),
// // // //                 const SizedBox(width: 8),
// // // //                 Flexible(
// // // //                   child: Text(
// // // //                     'You have $activeTasks tasks to complete\n$dateText',
// // // //                     style: const TextStyle(
// // // //                       fontSize: 18,
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: Colors.white,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           Container(
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.3),
// // // //               shape: BoxShape.circle,
// // // //             ),
// // // //             child: IconButton(
// // // //               icon: const Icon(Icons.notifications_none, color: Colors.white),
// // // //               onPressed: () {},
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildSearchBar() {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //       child: Container(
// // // //         decoration: BoxDecoration(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           borderRadius: BorderRadius.circular(30),
// // // //         ),
// // // //         child: TextField(
// // // //           decoration: InputDecoration(
// // // //             hintText: 'Search Reminders........',
// // // //             hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
// // // //             prefixIcon: const Icon(Icons.search, color: Colors.white),
// // // //             suffixIcon: const Icon(Icons.mic, color: Colors.white),
// // // //             border: InputBorder.none,
// // // //             contentPadding: const EdgeInsets.symmetric(vertical: 15),
// // // //           ),
// // // //           style: const TextStyle(color: Colors.white),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildDateSelector() {
// // // //     return Container(
// // // //       height: 100,
// // // //       margin: const EdgeInsets.only(top: 16),
// // // //       child: ListView.builder(
// // // //         controller: _dateScrollController,
// // // //         scrollDirection: Axis.horizontal,
// // // //         itemCount: weekDates.length,
// // // //         itemBuilder: (context, index) {
// // // //           final date = weekDates[index];
// // // //           final isSelected = index == selectedDateIndex;
// // // //           final isToday = _isSameDay(date, DateTime.now());
// // // //
// // // //           return GestureDetector(
// // // //             onTap: () {
// // // //               setState(() {
// // // //                 selectedDateIndex = index;
// // // //               });
// // // //             },
// // // //             child: Container(
// // // //               width: 80,
// // // //               margin: const EdgeInsets.only(left: 16),
// // // //               decoration: BoxDecoration(
// // // //                 color: isSelected
// // // //                     ? Colors.white
// // // //                     : const Color(0xFF77588D).withOpacity(0.4),
// // // //                 borderRadius: BorderRadius.circular(10),
// // // //               ),
// // // //               child: Column(
// // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                 children: [
// // // //                   Text(
// // // //                     Formatters.getMonthAbbreviation(date),
// // // //                     style: TextStyle(
// // // //                       fontSize: 14,
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: isSelected
// // // //                           ? const Color(0xFF503663)
// // // //                           : Colors.white,
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(height: 8),
// // // //                   Stack(
// // // //                     alignment: Alignment.center,
// // // //                     children: [
// // // //                       Text(
// // // //                         date.day.toString(),
// // // //                         style: TextStyle(
// // // //                           fontSize: 24,
// // // //                           fontWeight: FontWeight.bold,
// // // //                           color: isSelected
// // // //                               ? const Color(0xFF503663)
// // // //                               : Colors.white,
// // // //                         ),
// // // //                       ),
// // // //                       if (isToday)
// // // //                         Positioned(
// // // //                           bottom: 0,
// // // //                           child: Container(
// // // //                             width: 5,
// // // //                             height: 5,
// // // //                             decoration: BoxDecoration(
// // // //                               color: isSelected ? const Color(0xFF503663) : Colors.white,
// // // //                               shape: BoxShape.circle,
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                     ],
// // // //                   ),
// // // //                   const SizedBox(height: 4),
// // // //                   Text(
// // // //                     Formatters.getDayAbbreviation(date),
// // // //                     style: TextStyle(
// // // //                       fontSize: 12,
// // // //                       color: isSelected
// // // //                           ? const Color(0xFF503663)
// // // //                           : Colors.white,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           );
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildTaskList(List<Task> tasksToShow) {
// // // //     return ListView.builder(
// // // //       itemCount: tasksToShow.length,
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //       itemBuilder: (context, index) {
// // // //         final task = tasksToShow[index];
// // // //         return Container(
// // // //           margin: const EdgeInsets.only(bottom: 16),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.white,
// // // //             borderRadius: BorderRadius.circular(12),
// // // //           ),
// // // //           child: ListTile(
// // // //             contentPadding: const EdgeInsets.all(16),
// // // //             title: Text(
// // // //               task.title,
// // // //               style: TextStyle(
// // // //                 color: Colors.black,
// // // //                 fontWeight: FontWeight.bold,
// // // //                 fontSize: 18,
// // // //                 decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // // //               ),
// // // //             ),
// // // //             subtitle: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   task.description,
// // // //                   style: TextStyle(
// // // //                     color: Colors.grey[700],
// // // //                     fontSize: 14,
// // // //                     decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 Row(
// // // //                   children: [
// // // //                     Container(
// // // //                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // //                       decoration: BoxDecoration(
// // // //                         color: const Color(0xFF77588D).withOpacity(0.2),
// // // //                         borderRadius: BorderRadius.circular(4),
// // // //                       ),
// // // //                       child: Row(
// // // //                         children: [
// // // //                           Icon(
// // // //                             Icons.calendar_today,
// // // //                             size: 14,
// // // //                             color: const Color(0xFF77588D),
// // // //                           ),
// // // //                           const SizedBox(width: 4),
// // // //                           Text(
// // // //                             _isSameDay(task.date, DateTime.now())
// // // //                                 ? 'Today'
// // // //                                 : Formatters.formatDate(task.date),
// // // //                             style: TextStyle(
// // // //                               color: const Color(0xFF77588D),
// // // //                               fontSize: 12,
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 Row(
// // // //                   children: [
// // // //                     Icon(
// // // //                       Icons.access_time,
// // // //                       size: 16,
// // // //                       color: Colors.purple[900],
// // // //                     ),
// // // //                     const SizedBox(width: 4),
// // // //                     Text(
// // // //                       '${Formatters.formatTimeOfDay(task.startTime)} - ${Formatters.formatTimeOfDay(task.endTime)}',
// // // //                       style: TextStyle(
// // // //                         color: Colors.grey[700],
// // // //                         fontSize: 12,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 Row(
// // // //                   children: [
// // // //                     Icon(
// // // //                       Icons.flag,
// // // //                       size: 16,
// // // //                       color: _getPriorityColor(task.priority),
// // // //                     ),
// // // //                     const SizedBox(width: 4),
// // // //                     Text(
// // // //                       _getPriorityText(task.priority),
// // // //                       style: TextStyle(
// // // //                         color: Colors.grey[700],
// // // //                         fontSize: 12,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             trailing: IconButton(
// // // //               icon: const Icon(Icons.more_vert),
// // // //               onPressed: () => _showTaskOptionsOverlay(task, tasks.indexOf(task)),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   String _getPriorityText(Priority priority) {
// // // //     switch (priority) {
// // // //       case Priority.high:
// // // //         return 'High Priority';
// // // //       case Priority.medium:
// // // //         return 'Medium Priority';
// // // //       case Priority.low:
// // // //         return 'Low Priority';
// // // //     }
// // // //   }
// // // //
// // // //   Color _getPriorityColor(Priority priority) {
// // // //     switch (priority) {
// // // //       case Priority.high:
// // // //         return Colors.red;
// // // //       case Priority.medium:
// // // //         return Colors.orange;
// // // //       case Priority.low:
// // // //         return Colors.green;
// // // //     }
// // // //   }
// // // // }
// // //
// // //
// // // import 'package:flutter/material.dart';
// // // import '../models/task_model.dart';
// // // import '../widgets/add_task_overlay.dart';
// // // import '../widgets/task_options_overalay.dart';
// // // import '../utils/formatters.dart';
// // // import '../services/speech_service.dart';
// // //
// // // class TaskListScreen extends StatefulWidget {
// // //   @override
// // //   _TaskListScreenState createState() => _TaskListScreenState();
// // // }
// // //
// // // class _TaskListScreenState extends State<TaskListScreen> {
// // //   List<Task> tasks = [
// // //     Task(
// // //       title: 'Take Medicines Daily',
// // //       description: '2 Antibiotics per day',
// // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // //       date: DateTime.now(),
// // //       priority: Priority.high,
// // //       remindBefore: '5 minutes early',
// // //       repeat: 'None',
// // //     ),
// // //     Task(
// // //       title: 'Doctor Appointment',
// // //       description: 'Dr.Sumanathilake - Check',
// // //       startTime: TimeOfDay(hour: 21, minute: 6),
// // //       endTime: TimeOfDay(hour: 21, minute: 30),
// // //       date: DateTime.now(),
// // //       priority: Priority.low,
// // //       remindBefore: '5 minutes early',
// // //       repeat: 'None',
// // //     ),
// // //   ];
// // //
// // //   int selectedDateIndex = 0;
// // //   late List<DateTime> weekDates;
// // //   late ScrollController _dateScrollController;
// // //
// // //   // Search and voice functionality
// // //   final TextEditingController _searchController = TextEditingController();
// // //   String _searchQuery = '';
// // //   final SpeechService _speechService = SpeechService();
// // //   bool _isSearching = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _dateScrollController = ScrollController();
// // //     _generateWeekDates();
// // //
// // //     // Initialize speech service
// // //     _speechService.initialize();
// // //
// // //     // Add listener to search controller
// // //     _searchController.addListener(() {
// // //       setState(() {
// // //         _searchQuery = _searchController.text;
// // //         _isSearching = _searchQuery.isNotEmpty;
// // //       });
// // //     });
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _dateScrollController.dispose();
// // //     _searchController.dispose();
// // //     _speechService.stopListening();
// // //     super.dispose();
// // //   }
// // //
// // //   void _generateWeekDates() {
// // //     DateTime now = DateTime.now();
// // //     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
// // //     // Generate 30 days instead of just 4
// // //     weekDates = List.generate(
// // //       30,
// // //           (index) => startOfWeek.add(Duration(days: index)),
// // //     );
// // //   }
// // //
// // //   void _showAddTaskOverlay() {
// // //     // Pass the selected date to the overlay
// // //     final selectedDate = weekDates[selectedDateIndex];
// // //
// // //     showDialog(
// // //       context: context,
// // //       barrierColor: Colors.black54,
// // //       builder: (context) => AddTaskOverlay(
// // //         // Pass the selected date to initialize the task with
// // //         initialDate: selectedDate,
// // //         onTaskCreated: (Task newTask) {
// // //           setState(() {
// // //             tasks.add(newTask);
// // //           });
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showTaskOptionsOverlay(Task task, int index) {
// // //     showDialog(
// // //       context: context,
// // //       barrierColor: Colors.black54,
// // //       builder: (context) => TaskOptionsOverlay(
// // //         onEditTask: () {
// // //           Navigator.pop(context);
// // //           _editTask(task, index);
// // //         },
// // //         onTaskCompleted: () {
// // //           setState(() {
// // //             task.isCompleted = true;
// // //           });
// // //           Navigator.pop(context);
// // //         },
// // //         onDeleteTask: () {
// // //           setState(() {
// // //             tasks.removeAt(index);
// // //           });
// // //           Navigator.pop(context);
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _editTask(Task task, int index) {
// // //     showDialog(
// // //       context: context,
// // //       barrierColor: Colors.black54,
// // //       builder: (context) => AddTaskOverlay(
// // //         task: task,
// // //         initialDate: task.date,
// // //         onTaskCreated: (Task updatedTask) {
// // //           setState(() {
// // //             tasks[index] = updatedTask;
// // //           });
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Get tasks for the selected date
// // //   List<Task> _getTasksForSelectedDate() {
// // //     if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
// // //       return [];
// // //     }
// // //
// // //     DateTime selectedDate = weekDates[selectedDateIndex];
// // //     return tasks.where((task) {
// // //       return _isSameDay(task.date, selectedDate);
// // //     }).toList();
// // //   }
// // //
// // //   // Filter tasks based on search query
// // //   List<Task> _getFilteredTasks() {
// // //     // If not searching, show tasks for selected date
// // //     if (!_isSearching) {
// // //       return _getTasksForSelectedDate();
// // //     }
// // //
// // //     // If searching, filter all tasks based on query
// // //     return tasks.where((task) {
// // //       final query = _searchQuery.toLowerCase();
// // //       final titleMatch = task.title.toLowerCase().contains(query);
// // //       final descriptionMatch = task.description.toLowerCase().contains(query);
// // //       final priorityMatch = _getPriorityString(task.priority).toLowerCase().contains(query);
// // //
// // //       return titleMatch || descriptionMatch || priorityMatch;
// // //     }).toList();
// // //   }
// // //
// // //   // Check if two dates are the same day
// // //   bool _isSameDay(DateTime date1, DateTime date2) {
// // //     return date1.year == date2.year &&
// // //         date1.month == date2.month &&
// // //         date1.day == date2.day;
// // //   }
// // //
// // //   // Handle voice search
// // //   void _startVoiceSearch() async {
// // //     if (_speechService.isListening) {
// // //       await _speechService.stopListening();
// // //       return;
// // //     }
// // //
// // //     // Show user that we're listening
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text('Listening... Speak now.'),
// // //         duration: Duration(seconds: 2),
// // //       ),
// // //     );
// // //
// // //     final success = await _speechService.startListening(
// // //       onResult: (String text) {
// // //         setState(() {
// // //           _searchController.text = text;
// // //           _searchQuery = text;
// // //           _isSearching = _searchQuery.isNotEmpty;
// // //         });
// // //       },
// // //     );
// // //
// // //     if (!success) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Could not start voice recognition'),
// // //           duration: Duration(seconds: 2),
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   void _clearSearch() {
// // //     setState(() {
// // //       _searchController.clear();
// // //       _searchQuery = '';
// // //       _isSearching = false;
// // //     });
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // Get filtered tasks
// // //     List<Task> filteredTasks = _getFilteredTasks();
// // //
// // //     return Scaffold(
// // //       body: SafeArea(
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             _buildHeader(),
// // //             _buildSearchBar(),
// // //             if (!_isSearching) _buildDateSelector(),
// // //             Padding(
// // //               padding: const EdgeInsets.all(16.0),
// // //               child: Text(
// // //                 _isSearching ? 'Search Results' : 'Today task',
// // //                 style: TextStyle(
// // //                   fontSize: 22,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: Colors.white,
// // //                 ),
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: filteredTasks.isEmpty
// // //                   ? _buildEmptyState()
// // //                   : _buildTaskList(filteredTasks),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //       floatingActionButton: FloatingActionButton(
// // //         onPressed: _showAddTaskOverlay,
// // //         backgroundColor: const Color(0xFF77588D),
// // //         child: const Icon(Icons.add, color: Colors.white),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildEmptyState() {
// // //     return Center(
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           Icon(
// // //             _isSearching ? Icons.search_off : Icons.event_note,
// // //             size: 80,
// // //             color: Colors.white.withOpacity(0.5),
// // //           ),
// // //           SizedBox(height: 16),
// // //           Text(
// // //             _isSearching
// // //                 ? 'No tasks match your search'
// // //                 : 'No tasks for this day',
// // //             style: TextStyle(
// // //               fontSize: 18,
// // //               color: Colors.white.withOpacity(0.7),
// // //             ),
// // //           ),
// // //           SizedBox(height: 24),
// // //           if (!_isSearching)
// // //             ElevatedButton.icon(
// // //               onPressed: _showAddTaskOverlay,
// // //               icon: Icon(Icons.add),
// // //               label: Text('Add a Task'),
// // //               style: ElevatedButton.styleFrom(
// // //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // //               ),
// // //             ),
// // //           if (_isSearching)
// // //             ElevatedButton.icon(
// // //               onPressed: _clearSearch,
// // //               icon: Icon(Icons.clear),
// // //               label: Text('Clear Search'),
// // //               style: ElevatedButton.styleFrom(
// // //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // //               ),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildHeader() {
// // //     // Count active tasks for the selected date
// // //     final activeTasks = _isSearching
// // //         ? _getFilteredTasks().where((task) => !task.isCompleted).length
// // //         : _getTasksForSelectedDate().where((task) => !task.isCompleted).length;
// // //
// // //     final selectedDate = weekDates[selectedDateIndex];
// // //     final isToday = _isSameDay(selectedDate, DateTime.now());
// // //     final dateText = _isSearching
// // //         ? 'matching your search'
// // //         : isToday
// // //         ? 'today'
// // //         : 'on ${Formatters.formatDate(selectedDate)}';
// // //
// // //     return Padding(
// // //       padding: const EdgeInsets.all(16.0),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           Expanded(
// // //             child: Row(
// // //               children: [
// // //                 IconButton(
// // //                   icon: const Icon(Icons.arrow_back, color: Colors.white),
// // //                   onPressed: () {},
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 Flexible(
// // //                   child: Text(
// // //                     'You have $activeTasks tasks to complete\n$dateText',
// // //                     style: const TextStyle(
// // //                       fontSize: 18,
// // //                       fontWeight: FontWeight.bold,
// // //                       color: Colors.white,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           Container(
// // //             decoration: BoxDecoration(
// // //               color: Colors.white.withOpacity(0.3),
// // //               shape: BoxShape.circle,
// // //             ),
// // //             child: IconButton(
// // //               icon: const Icon(Icons.notifications_none, color: Colors.white),
// // //               onPressed: () {},
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSearchBar() {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // //       child: Container(
// // //         decoration: BoxDecoration(
// // //           color: Colors.white.withOpacity(0.2),
// // //           borderRadius: BorderRadius.circular(30),
// // //         ),
// // //         child: Row(
// // //           children: [
// // //             Expanded(
// // //               child: TextField(
// // //                 controller: _searchController,
// // //                 decoration: InputDecoration(
// // //                   hintText: 'Search Reminders........',
// // //                   hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
// // //                   prefixIcon: const Icon(Icons.search, color: Colors.white),
// // //                   border: InputBorder.none,
// // //                   contentPadding: const EdgeInsets.symmetric(vertical: 15),
// // //                 ),
// // //                 style: const TextStyle(color: Colors.white),
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     _searchQuery = value;
// // //                     _isSearching = value.isNotEmpty;
// // //                   });
// // //                 },
// // //               ),
// // //             ),
// // //             IconButton(
// // //               icon: Icon(
// // //                 _speechService.isListening ? Icons.mic : Icons.mic_none,
// // //                 color: _speechService.isListening ? Colors.red : Colors.white,
// // //               ),
// // //               onPressed: _startVoiceSearch,
// // //             ),
// // //             if (_isSearching)
// // //               IconButton(
// // //                 icon: const Icon(Icons.clear, color: Colors.white),
// // //                 onPressed: _clearSearch,
// // //               ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildDateSelector() {
// // //     return Container(
// // //       height: 100,
// // //       margin: const EdgeInsets.only(top: 16),
// // //       child: ListView.builder(
// // //         controller: _dateScrollController,
// // //         scrollDirection: Axis.horizontal,
// // //         itemCount: weekDates.length,
// // //         itemBuilder: (context, index) {
// // //           final date = weekDates[index];
// // //           final isSelected = index == selectedDateIndex;
// // //           final isToday = _isSameDay(date, DateTime.now());
// // //
// // //           return GestureDetector(
// // //             onTap: () {
// // //               setState(() {
// // //                 selectedDateIndex = index;
// // //               });
// // //             },
// // //             child: Container(
// // //               width: 80,
// // //               margin: const EdgeInsets.only(left: 16),
// // //               decoration: BoxDecoration(
// // //                 color: isSelected
// // //                     ? Colors.white
// // //                     : const Color(0xFF77588D).withOpacity(0.4),
// // //                 borderRadius: BorderRadius.circular(10),
// // //               ),
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Text(
// // //                     Formatters.getMonthAbbreviation(date),
// // //                     style: TextStyle(
// // //                       fontSize: 14,
// // //                       fontWeight: FontWeight.bold,
// // //                       color: isSelected
// // //                           ? const Color(0xFF503663)
// // //                           : Colors.white,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   Stack(
// // //                     alignment: Alignment.center,
// // //                     children: [
// // //                       Text(
// // //                         date.day.toString(),
// // //                         style: TextStyle(
// // //                           fontSize: 24,
// // //                           fontWeight: FontWeight.bold,
// // //                           color: isSelected
// // //                               ? const Color(0xFF503663)
// // //                               : Colors.white,
// // //                         ),
// // //                       ),
// // //                       if (isToday)
// // //                         Positioned(
// // //                           bottom: 0,
// // //                           child: Container(
// // //                             width: 5,
// // //                             height: 5,
// // //                             decoration: BoxDecoration(
// // //                               color: isSelected ? const Color(0xFF503663) : Colors.white,
// // //                               shape: BoxShape.circle,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 4),
// // //                   Text(
// // //                     Formatters.getDayAbbreviation(date),
// // //                     style: TextStyle(
// // //                       fontSize: 12,
// // //                       color: isSelected
// // //                           ? const Color(0xFF503663)
// // //                           : Colors.white,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildTaskList(List<Task> tasksToShow) {
// // //     return ListView.builder(
// // //       itemCount: tasksToShow.length,
// // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // //       itemBuilder: (context, index) {
// // //         final task = tasksToShow[index];
// // //         return Container(
// // //           margin: const EdgeInsets.only(bottom: 16),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(12),
// // //           ),
// // //           child: ListTile(
// // //             contentPadding: const EdgeInsets.all(16),
// // //             title: Text(
// // //               task.title,
// // //               style: TextStyle(
// // //                 color: Colors.black,
// // //                 fontWeight: FontWeight.bold,
// // //                 fontSize: 18,
// // //                 decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // //               ),
// // //             ),
// // //             subtitle: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text(
// // //                   task.description,
// // //                   style: TextStyle(
// // //                     color: Colors.grey[700],
// // //                     fontSize: 14,
// // //                     decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Container(
// // //                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                       decoration: BoxDecoration(
// // //                         color: const Color(0xFF77588D).withOpacity(0.2),
// // //                         borderRadius: BorderRadius.circular(4),
// // //                       ),
// // //                       child: Row(
// // //                         children: [
// // //                           Icon(
// // //                             Icons.calendar_today,
// // //                             size: 14,
// // //                             color: const Color(0xFF77588D),
// // //                           ),
// // //                           const SizedBox(width: 4),
// // //                           Text(
// // //                             _isSameDay(task.date, DateTime.now())
// // //                                 ? 'Today'
// // //                                 : Formatters.formatDate(task.date),
// // //                             style: TextStyle(
// // //                               color: const Color(0xFF77588D),
// // //                               fontSize: 12,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Icon(
// // //                       Icons.access_time,
// // //                       size: 16,
// // //                       color: Colors.purple[900],
// // //                     ),
// // //                     const SizedBox(width: 4),
// // //                     Text(
// // //                       '${Formatters.formatTimeOfDay(task.startTime)} - ${Formatters.formatTimeOfDay(task.endTime)}',
// // //                       style: TextStyle(
// // //                         color: Colors.grey[700],
// // //                         fontSize: 12,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Icon(
// // //                       Icons.flag,
// // //                       size: 16,
// // //                       color: _getPriorityColor(task.priority),
// // //                     ),
// // //                     const SizedBox(width: 4),
// // //                     Text(
// // //                       _getPriorityString(task.priority),
// // //                       style: TextStyle(
// // //                         color: Colors.grey[700],
// // //                         fontSize: 12,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //             trailing: IconButton(
// // //               icon: const Icon(Icons.more_vert),
// // //               onPressed: () => _showTaskOptionsOverlay(task, tasks.indexOf(task)),
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   String _getPriorityString(Priority priority) {
// // //     switch (priority) {
// // //       case Priority.high:
// // //         return 'High Priority';
// // //       case Priority.medium:
// // //         return 'Medium Priority';
// // //       case Priority.low:
// // //         return 'Low Priority';
// // //     }
// // //   }
// // //
// // //   Color _getPriorityColor(Priority priority) {
// // //     switch (priority) {
// // //       case Priority.high:
// // //         return Colors.red;
// // //       case Priority.medium:
// // //         return Colors.orange;
// // //       case Priority.low:
// // //         return Colors.green;
// // //     }
// // //   }
// // // }
// //
// // import 'package:flutter/material.dart';
// // import '../models/task_model.dart';
// // import '../widgets/add_task_overlay.dart';
// // import '../widgets/task_options_overalay.dart';
// // import '../utils/formatters.dart';
// // import '../services/speech_service.dart';
// // import '../services/voice_command_processor.dart';
// //
// // class TaskListScreen extends StatefulWidget {
// //   @override
// //   _TaskListScreenState createState() => _TaskListScreenState();
// // }
// //
// // class _TaskListScreenState extends State<TaskListScreen> {
// //   List<Task> tasks = [
// //     Task(
// //       title: 'Take Medicines Daily',
// //       description: '2 Antibiotics per day',
// //       startTime: TimeOfDay(hour: 21, minute: 6),
// //       endTime: TimeOfDay(hour: 21, minute: 30),
// //       date: DateTime.now(),
// //       priority: Priority.high,
// //       remindBefore: '5 minutes early',
// //       repeat: 'None',
// //     ),
// //     Task(
// //       title: 'Doctor Appointment',
// //       description: 'Dr.Sumanathilake - Check',
// //       startTime: TimeOfDay(hour: 21, minute: 6),
// //       endTime: TimeOfDay(hour: 21, minute: 30),
// //       date: DateTime.now(),
// //       priority: Priority.low,
// //       remindBefore: '5 minutes early',
// //       repeat: 'None',
// //     ),
// //   ];
// //
// //   int selectedDateIndex = 0;
// //   late List<DateTime> weekDates;
// //   late ScrollController _dateScrollController;
// //
// //   // Search and voice functionality
// //   final TextEditingController _searchController = TextEditingController();
// //   String _searchQuery = '';
// //   final SpeechService _speechService = SpeechService();
// //   bool _isSearching = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _dateScrollController = ScrollController();
// //     _generateWeekDates();
// //
// //     // Initialize speech service
// //     _speechService.initialize();
// //
// //     // Add listener to search controller
// //     _searchController.addListener(() {
// //       setState(() {
// //         _searchQuery = _searchController.text;
// //         _isSearching = _searchQuery.isNotEmpty;
// //       });
// //     });
// //   }
// //
// //   @override
// //   void dispose() {
// //     _dateScrollController.dispose();
// //     _searchController.dispose();
// //     _speechService.stopListening();
// //     super.dispose();
// //   }
// //
// //   void _generateWeekDates() {
// //     DateTime now = DateTime.now();
// //     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
// //     // Generate 30 days instead of just 4
// //     weekDates = List.generate(
// //       30,
// //           (index) => startOfWeek.add(Duration(days: index)),
// //     );
// //   }
// //
// //   void _showAddTaskOverlay() {
// //     // Pass the selected date to the overlay
// //     final selectedDate = weekDates[selectedDateIndex];
// //
// //     showDialog(
// //       context: context,
// //       barrierColor: Colors.black54,
// //       builder: (context) => AddTaskOverlay(
// //         // Pass the selected date to initialize the task with
// //         initialDate: selectedDate,
// //         onTaskCreated: (Task newTask) {
// //           setState(() {
// //             tasks.add(newTask);
// //           });
// //         },
// //       ),
// //     );
// //   }
// //
// //   void _showTaskOptionsOverlay(Task task, int index) {
// //     showDialog(
// //       context: context,
// //       barrierColor: Colors.black54,
// //       builder: (context) => TaskOptionsOverlay(
// //         onEditTask: () {
// //           Navigator.pop(context);
// //           _editTask(task, index);
// //         },
// //         onTaskCompleted: () {
// //           setState(() {
// //             task.isCompleted = true;
// //           });
// //           Navigator.pop(context);
// //         },
// //         onDeleteTask: () {
// //           setState(() {
// //             tasks.removeAt(index);
// //           });
// //           Navigator.pop(context);
// //         },
// //       ),
// //     );
// //   }
// //
// //   void _editTask(Task task, int index) {
// //     showDialog(
// //       context: context,
// //       barrierColor: Colors.black54,
// //       builder: (context) => AddTaskOverlay(
// //         task: task,
// //         initialDate: task.date,
// //         onTaskCreated: (Task updatedTask) {
// //           setState(() {
// //             tasks[index] = updatedTask;
// //           });
// //         },
// //       ),
// //     );
// //   }
// //
// //   // Get tasks for the selected date
// //   List<Task> _getTasksForSelectedDate() {
// //     if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
// //       return [];
// //     }
// //
// //     DateTime selectedDate = weekDates[selectedDateIndex];
// //     return tasks.where((task) {
// //       return _isSameDay(task.date, selectedDate);
// //     }).toList();
// //   }
// //
// //   // Filter tasks based on search query
// //   List<Task> _getFilteredTasks() {
// //     // If not searching, show tasks for selected date
// //     if (!_isSearching) {
// //       return _getTasksForSelectedDate();
// //     }
// //
// //     // If searching, filter all tasks based on query
// //     return tasks.where((task) {
// //       final query = _searchQuery.toLowerCase();
// //       final titleMatch = task.title.toLowerCase().contains(query);
// //       final descriptionMatch = task.description.toLowerCase().contains(query);
// //       final priorityMatch = _getPriorityString(task.priority).toLowerCase().contains(query);
// //
// //       return titleMatch || descriptionMatch || priorityMatch;
// //     }).toList();
// //   }
// //
// //   // Check if two dates are the same day
// //   bool _isSameDay(DateTime date1, DateTime date2) {
// //     return date1.year == date2.year &&
// //         date1.month == date2.month &&
// //         date1.day == date2.day;
// //   }
// //
// //   // Handle voice commands
// //   void _startVoiceSearch() async {
// //     if (_speechService.isListening) {
// //       await _speechService.stopListening();
// //       return;
// //     }
// //
// //     // Show user that we're listening
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text('Listening... Speak now.'),
// //         duration: Duration(seconds: 2),
// //       ),
// //     );
// //
// //     final success = await _speechService.startListening(
// //       onResult: (String text) {
// //         if (text.isEmpty) return;
// //
// //         // Process the voice command
// //         final command = VoiceCommandProcessor.processCommand(text);
// //         _handleVoiceCommand(command, text);
// //       },
// //     );
// //
// //     if (!success) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Could not start voice recognition'),
// //           duration: Duration(seconds: 2),
// //         ),
// //       );
// //     }
// //   }
// //
// //   // Handle different types of voice commands
// //   void _handleVoiceCommand(VoiceCommand command, String originalText) {
// //     switch (command.type) {
// //       case CommandType.search:
// //         final query = command.parameters['query'] as String;
// //         setState(() {
// //           _searchController.text = query;
// //           _searchQuery = query;
// //           _isSearching = _searchQuery.isNotEmpty;
// //         });
// //         _speechService.speak('Searching for $query');
// //         break;
// //
// //       case CommandType.filter:
// //         if (command.parameters.containsKey('priority')) {
// //           final priority = command.parameters['priority'] as Priority;
// //           final priorityString = _getPriorityString(priority).split(' ')[0]; // Get just "High", "Medium", "Low"
// //           setState(() {
// //             _searchController.text = priorityString;
// //             _searchQuery = priorityString;
// //             _isSearching = true;
// //           });
// //           _speechService.speak('Showing $priorityString priority tasks');
// //         } else if (command.parameters.containsKey('date')) {
// //           final date = command.parameters['date'] as DateTime;
// //           // Find the index of the date in weekDates
// //           int dateIndex = -1;
// //           for (int i = 0; i < weekDates.length; i++) {
// //             if (_isSameDay(weekDates[i], date)) {
// //               dateIndex = i;
// //               break;
// //             }
// //           }
// //
// //           if (dateIndex != -1) {
// //             setState(() {
// //               selectedDateIndex = dateIndex;
// //               _clearSearch(); // Clear any existing search
// //             });
// //             final dateString = _isSameDay(date, DateTime.now()) ? 'today' : Formatters.formatDate(date);
// //             _speechService.speak('Showing tasks for $dateString');
// //           }
// //         }
// //         break;
// //
// //       case CommandType.create:
// //       // We'll just go to the add task screen and let the user fill in details
// //         _speechService.speak('Opening new task form');
// //         _showAddTaskOverlay();
// //         break;
// //
// //       case CommandType.complete:
// //         final taskName = command.parameters['taskName'] as String;
// //         final matchingTask = VoiceCommandProcessor.findMatchingTask(tasks, taskName);
// //
// //         if (matchingTask != null) {
// //           final index = tasks.indexOf(matchingTask);
// //           setState(() {
// //             tasks[index].isCompleted = true;
// //           });
// //           _speechService.speak('Marked ${matchingTask.title} as completed');
// //         } else {
// //           _speechService.speak('I couldn\'t find a task matching $taskName');
// //         }
// //         break;
// //
// //       case CommandType.unknown:
// //       default:
// //       // Default to search with the entire text
// //         setState(() {
// //           _searchController.text = originalText;
// //           _searchQuery = originalText;
// //           _isSearching = _searchQuery.isNotEmpty;
// //         });
// //         break;
// //     }
// //   }
// //
// //   void _clearSearch() {
// //     setState(() {
// //       _searchController.clear();
// //       _searchQuery = '';
// //       _isSearching = false;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // Get filtered tasks
// //     List<Task> filteredTasks = _getFilteredTasks();
// //
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             _buildHeader(),
// //             _buildSearchBar(),
// //             if (!_isSearching) _buildDateSelector(),
// //             Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: Text(
// //                 _isSearching ? 'Search Results' : 'Today task',
// //                 style: TextStyle(
// //                   fontSize: 22,
// //                   fontWeight: FontWeight.bold,
// //                   color: Colors.white,
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               child: filteredTasks.isEmpty
// //                   ? _buildEmptyState()
// //                   : _buildTaskList(filteredTasks),
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _showAddTaskOverlay,
// //         backgroundColor: const Color(0xFF77588D),
// //         child: const Icon(Icons.add, color: Colors.white),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             _isSearching ? Icons.search_off : Icons.event_note,
// //             size: 80,
// //             color: Colors.white.withOpacity(0.5),
// //           ),
// //           SizedBox(height: 16),
// //           Text(
// //             _isSearching
// //                 ? 'No tasks match your search'
// //                 : 'No tasks for this day',
// //             style: TextStyle(
// //               fontSize: 18,
// //               color: Colors.white.withOpacity(0.7),
// //             ),
// //           ),
// //           SizedBox(height: 24),
// //           if (!_isSearching)
// //             ElevatedButton.icon(
// //               onPressed: _showAddTaskOverlay,
// //               icon: Icon(Icons.add),
// //               label: Text('Add a Task'),
// //               style: ElevatedButton.styleFrom(
// //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //               ),
// //             ),
// //           if (_isSearching)
// //             ElevatedButton.icon(
// //               onPressed: _clearSearch,
// //               icon: Icon(Icons.clear),
// //               label: Text('Clear Search'),
// //               style: ElevatedButton.styleFrom(
// //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildHeader() {
// //     // Count active tasks for the selected date
// //     final activeTasks = _isSearching
// //         ? _getFilteredTasks().where((task) => !task.isCompleted).length
// //         : _getTasksForSelectedDate().where((task) => !task.isCompleted).length;
// //
// //     final selectedDate = weekDates[selectedDateIndex];
// //     final isToday = _isSameDay(selectedDate, DateTime.now());
// //     final dateText = _isSearching
// //         ? 'matching your search'
// //         : isToday
// //         ? 'today'
// //         : 'on ${Formatters.formatDate(selectedDate)}';
// //
// //     return Padding(
// //       padding: const EdgeInsets.all(16.0),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Expanded(
// //             child: Row(
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                   onPressed: () {},
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Flexible(
// //                   child: Text(
// //                     'You have $activeTasks tasks to complete\n$dateText',
// //                     style: const TextStyle(
// //                       fontSize: 18,
// //                       fontWeight: FontWeight.bold,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Container(
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               shape: BoxShape.circle,
// //             ),
// //             child: IconButton(
// //               icon: const Icon(Icons.notifications_none, color: Colors.white),
// //               onPressed: () {},
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSearchBar() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.white.withOpacity(0.2),
// //           borderRadius: BorderRadius.circular(30),
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: TextField(
// //                 controller: _searchController,
// //                 decoration: InputDecoration(
// //                   hintText: 'Search Reminders........',
// //                   hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
// //                   prefixIcon: const Icon(Icons.search, color: Colors.white),
// //                   border: InputBorder.none,
// //                   contentPadding: const EdgeInsets.symmetric(vertical: 15),
// //                 ),
// //                 style: const TextStyle(color: Colors.white),
// //                 onChanged: (value) {
// //                   setState(() {
// //                     _searchQuery = value;
// //                     _isSearching = value.isNotEmpty;
// //                   });
// //                 },
// //               ),
// //             ),
// //             IconButton(
// //               icon: Icon(
// //                 _speechService.isListening ? Icons.mic : Icons.mic_none,
// //                 color: _speechService.isListening ? Colors.red : Colors.white,
// //               ),
// //               onPressed: _startVoiceSearch,
// //             ),
// //             if (_isSearching)
// //               IconButton(
// //                 icon: const Icon(Icons.clear, color: Colors.white),
// //                 onPressed: _clearSearch,
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildDateSelector() {
// //     return Container(
// //       height: 100,
// //       margin: const EdgeInsets.only(top: 16),
// //       child: ListView.builder(
// //         controller: _dateScrollController,
// //         scrollDirection: Axis.horizontal,
// //         itemCount: weekDates.length,
// //         itemBuilder: (context, index) {
// //           final date = weekDates[index];
// //           final isSelected = index == selectedDateIndex;
// //           final isToday = _isSameDay(date, DateTime.now());
// //
// //           return GestureDetector(
// //             onTap: () {
// //               setState(() {
// //                 selectedDateIndex = index;
// //               });
// //             },
// //             child: Container(
// //               width: 80,
// //               margin: const EdgeInsets.only(left: 16),
// //               decoration: BoxDecoration(
// //                 color: isSelected
// //                     ? Colors.white
// //                     : const Color(0xFF77588D).withOpacity(0.4),
// //                 borderRadius: BorderRadius.circular(10),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Text(
// //                     Formatters.getMonthAbbreviation(date),
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.bold,
// //                       color: isSelected
// //                           ? const Color(0xFF503663)
// //                           : Colors.white,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Stack(
// //                     alignment: Alignment.center,
// //                     children: [
// //                       Text(
// //                         date.day.toString(),
// //                         style: TextStyle(
// //                           fontSize: 24,
// //                           fontWeight: FontWeight.bold,
// //                           color: isSelected
// //                               ? const Color(0xFF503663)
// //                               : Colors.white,
// //                         ),
// //                       ),
// //                       if (isToday)
// //                         Positioned(
// //                           bottom: 0,
// //                           child: Container(
// //                             width: 5,
// //                             height: 5,
// //                             decoration: BoxDecoration(
// //                               color: isSelected ? const Color(0xFF503663) : Colors.white,
// //                               shape: BoxShape.circle,
// //                             ),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(
// //                     Formatters.getDayAbbreviation(date),
// //                     style: TextStyle(
// //                       fontSize: 12,
// //                       color: isSelected
// //                           ? const Color(0xFF503663)
// //                           : Colors.white,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTaskList(List<Task> tasksToShow) {
// //     return ListView.builder(
// //       itemCount: tasksToShow.length,
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       itemBuilder: (context, index) {
// //         final task = tasksToShow[index];
// //         return Container(
// //           margin: const EdgeInsets.only(bottom: 16),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: ListTile(
// //             contentPadding: const EdgeInsets.all(16),
// //             title: Text(
// //               task.title,
// //               style: TextStyle(
// //                 color: Colors.black,
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 18,
// //                 decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// //               ),
// //             ),
// //             subtitle: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   task.description,
// //                   style: TextStyle(
// //                     color: Colors.grey[700],
// //                     fontSize: 14,
// //                     decoration: task.isCompleted ? TextDecoration.lineThrough : null,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                       decoration: BoxDecoration(
// //                         color: const Color(0xFF77588D).withOpacity(0.2),
// //                         borderRadius: BorderRadius.circular(4),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(
// //                             Icons.calendar_today,
// //                             size: 14,
// //                             color: const Color(0xFF77588D),
// //                           ),
// //                           const SizedBox(width: 4),
// //                           Text(
// //                             _isSameDay(task.date, DateTime.now())
// //                                 ? 'Today'
// //                                 : Formatters.formatDate(task.date),
// //                             style: TextStyle(
// //                               color: const Color(0xFF77588D),
// //                               fontSize: 12,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Icon(
// //                       Icons.access_time,
// //                       size: 16,
// //                       color: Colors.purple[900],
// //                     ),
// //                     const SizedBox(width: 4),
// //                     Text(
// //                       '${Formatters.formatTimeOfDay(task.startTime)} - ${Formatters.formatTimeOfDay(task.endTime)}',
// //                       style: TextStyle(
// //                         color: Colors.grey[700],
// //                         fontSize: 12,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Icon(
// //                       Icons.flag,
// //                       size: 16,
// //                       color: _getPriorityColor(task.priority),
// //                     ),
// //                     const SizedBox(width: 4),
// //                     Text(
// //                       _getPriorityString(task.priority),
// //                       style: TextStyle(
// //                         color: Colors.grey[700],
// //                         fontSize: 12,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //             trailing: IconButton(
// //               icon: const Icon(Icons.more_vert),
// //               onPressed: () => _showTaskOptionsOverlay(task, tasks.indexOf(task)),
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   String _getPriorityString(Priority priority) {
// //     switch (priority) {
// //       case Priority.high:
// //         return 'High Priority';
// //       case Priority.medium:
// //         return 'Medium Priority';
// //       case Priority.low:
// //         return 'Low Priority';
// //     }
// //   }
// //
// //   Color _getPriorityColor(Priority priority) {
// //     switch (priority) {
// //       case Priority.high:
// //         return Colors.red;
// //       case Priority.medium:
// //         return Colors.orange;
// //       case Priority.low:
// //         return Colors.green;
// //     }
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import '../models/task_model.dart';
// import '../widgets/add_task_overlay.dart';
// import '../widgets/task_options_overalay.dart';
// import '../utils/formatters.dart';
// import '../services/speech_service.dart';
// import '../services/voice_command_processor.dart';
//
// class TaskListScreen extends StatefulWidget {
//   @override
//   _TaskListScreenState createState() => _TaskListScreenState();
// }
//
// class _TaskListScreenState extends State<TaskListScreen> {
//   List<Task> tasks = [
//     Task(
//       title: 'Take Medicines Daily',
//       description: '2 Antibiotics per day',
//       startTime: TimeOfDay(hour: 21, minute: 6),
//       endTime: TimeOfDay(hour: 21, minute: 30),
//       date: DateTime.now(),
//       priority: Priority.high,
//       remindBefore: '5 minutes early',
//       repeat: 'None',
//     ),
//     Task(
//       title: 'Doctor Appointment',
//       description: 'Dr.Sumanathilake - Check',
//       startTime: TimeOfDay(hour: 21, minute: 6),
//       endTime: TimeOfDay(hour: 21, minute: 30),
//       date: DateTime.now(),
//       priority: Priority.low,
//       remindBefore: '5 minutes early',
//       repeat: 'None',
//     ),
//   ];
//
//   int selectedDateIndex = 0;
//   late List<DateTime> weekDates;
//   late ScrollController _dateScrollController;
//
//   // Search and voice functionality
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   final SpeechService _speechService = SpeechService();
//   bool _isSearching = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _dateScrollController = ScrollController();
//     _generateWeekDates();
//
//     // Initialize speech service
//     _speechService.initialize();
//
//     // Add listener to search controller
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//         _isSearching = _searchQuery.isNotEmpty;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _dateScrollController.dispose();
//     _searchController.dispose();
//     _speechService.stopListening();
//     super.dispose();
//   }
//
//   void _generateWeekDates() {
//     DateTime now = DateTime.now();
//     DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//     // Generate 30 days instead of just 4
//     weekDates = List.generate(
//       30,
//           (index) => startOfWeek.add(Duration(days: index)),
//     );
//   }
//
//   void _showAddTaskOverlay() {
//     // Pass the selected date to the overlay
//     final selectedDate = weekDates[selectedDateIndex];
//
//     showDialog(
//       context: context,
//       barrierColor: Colors.black54,
//       builder: (context) => AddTaskOverlay(
//         // Pass the selected date to initialize the task with
//         initialDate: selectedDate,
//         onTaskCreated: (Task newTask) {
//           setState(() {
//             tasks.add(newTask);
//           });
//         },
//       ),
//     );
//   }
//
//   void _showTaskOptionsOverlay(Task task, int index) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black54,
//       builder: (context) => TaskOptionsOverlay(
//         onEditTask: () {
//           Navigator.pop(context);
//           _editTask(task, index);
//         },
//         onTaskCompleted: () {
//           setState(() {
//             task.isCompleted = true;
//           });
//           Navigator.pop(context);
//         },
//         onDeleteTask: () {
//           setState(() {
//             tasks.removeAt(index);
//           });
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _editTask(Task task, int index) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black54,
//       builder: (context) => AddTaskOverlay(
//         task: task,
//         initialDate: task.date,
//         onTaskCreated: (Task updatedTask) {
//           setState(() {
//             tasks[index] = updatedTask;
//           });
//         },
//       ),
//     );
//   }
//
//   // Get tasks for the selected date
//   List<Task> _getTasksForSelectedDate() {
//     if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
//       return [];
//     }
//
//     DateTime selectedDate = weekDates[selectedDateIndex];
//     return tasks.where((task) {
//       return _isSameDay(task.date, selectedDate);
//     }).toList();
//   }
//
//   // Filter tasks based on search query
//   List<Task> _getFilteredTasks() {
//     // If not searching, show tasks for selected date
//     if (!_isSearching) {
//       return _getTasksForSelectedDate();
//     }
//
//     // If searching, filter all tasks based on query
//     return tasks.where((task) {
//       final query = _searchQuery.toLowerCase();
//       final titleMatch = task.title.toLowerCase().contains(query);
//       final descriptionMatch = task.description.toLowerCase().contains(query);
//       final priorityMatch = _getPriorityString(task.priority).toLowerCase().contains(query);
//
//       return titleMatch || descriptionMatch || priorityMatch;
//     }).toList();
//   }
//
//   // Check if two dates are the same day
//   bool _isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }
//
//   // Handle voice commands
//   void _startVoiceSearch() async {
//     if (_speechService.isListening) {
//       await _speechService.stopListening();
//       return;
//     }
//
//     // Show user that we're listening
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Listening... Speak now.'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//
//     final success = await _speechService.startListening(
//       onResult: (String text) {
//         if (text.isEmpty) return;
//
//         // Process the voice command
//         final command = VoiceCommandProcessor.processCommand(text);
//         _handleVoiceCommand(command, text);
//       },
//     );
//
//     if (!success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not start voice recognition'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   // Handle different types of voice commands
//   void _handleVoiceCommand(VoiceCommand command, String originalText) {
//     switch (command.type) {
//       case CommandType.search:
//         final query = command.parameters['query'] as String;
//         setState(() {
//           _searchController.text = query;
//           _searchQuery = query;
//           _isSearching = _searchQuery.isNotEmpty;
//         });
//         _speechService.speak('Searching for $query');
//         break;
//
//       case CommandType.filter:
//         if (command.parameters.containsKey('priority')) {
//           final priority = command.parameters['priority'] as Priority;
//           final priorityString = _getPriorityString(priority).split(' ')[0]; // Get just "High", "Medium", "Low"
//           setState(() {
//             _searchController.text = priorityString;
//             _searchQuery = priorityString;
//             _isSearching = true;
//           });
//           _speechService.speak('Showing $priorityString priority tasks');
//         } else if (command.parameters.containsKey('date')) {
//           final date = command.parameters['date'] as DateTime;
//           // Find the index of the date in weekDates
//           int dateIndex = -1;
//           for (int i = 0; i < weekDates.length; i++) {
//             if (_isSameDay(weekDates[i], date)) {
//               dateIndex = i;
//               break;
//             }
//           }
//
//           if (dateIndex != -1) {
//             setState(() {
//               selectedDateIndex = dateIndex;
//               _clearSearch(); // Clear any existing search
//             });
//             final dateString = _isSameDay(date, DateTime.now()) ? 'today' : Formatters.formatDate(date);
//             _speechService.speak('Showing tasks for $dateString');
//           }
//         }
//         break;
//
//       case CommandType.create:
//       // Parse task details from voice command
//         final taskDetails = command.parameters['taskDetails'] as String;
//         _showAddTaskOverlayWithVoiceInput(taskDetails);
//         break;
//
//       case CommandType.complete:
//         final taskName = command.parameters['taskName'] as String;
//         final matchingTask = VoiceCommandProcessor.findMatchingTask(tasks, taskName);
//
//         if (matchingTask != null) {
//           final index = tasks.indexOf(matchingTask);
//           setState(() {
//             tasks[index].isCompleted = true;
//           });
//           _speechService.speak('Marked ${matchingTask.title} as completed');
//         } else {
//           _speechService.speak('I couldn\'t find a task matching $taskName');
//         }
//         break;
//
//       case CommandType.unknown:
//       default:
//       // Default to search with the entire text
//         setState(() {
//           _searchController.text = originalText;
//           _searchQuery = originalText;
//           _isSearching = _searchQuery.isNotEmpty;
//         });
//         break;
//     }
//   }
//
//   // New method to show AddTaskOverlay with parsed voice input
//   void _showAddTaskOverlayWithVoiceInput(String taskDetails) {
//     // Try to extract key details from voice input
//     final selectedDate = weekDates[selectedDateIndex];
//
//     // Show the overlay and parse details when it's created
//     showDialog(
//       context: context,
//       barrierColor: Colors.black54,
//       builder: (context) => AddTaskOverlay(
//         initialDate: selectedDate,
//         voiceInputDetails: taskDetails,
//         onTaskCreated: (Task newTask) {
//           setState(() {
//             tasks.add(newTask);
//           });
//         },
//       ),
//     );
//   }
//
//   void _clearSearch() {
//     setState(() {
//       _searchController.clear();
//       _searchQuery = '';
//       _isSearching = false;
//     });
//   }
//
//   // Rest of the existing methods remain the same (build method, _buildHeader, etc.)
//   // ... (previous implementation of build method, _buildHeader, etc. remains unchanged)
//
//   String _getPriorityString(Priority priority) {
//     switch (priority) {
//       case Priority.high:
//         return 'High Priority';
//       case Priority.medium:
//         return 'Medium Priority';
//       case Priority.low:
//         return 'Low Priority';
//     }
//   }
//
//   Color _getPriorityColor(Priority priority) {
//     switch (priority) {
//       case Priority.high:
//         return Colors.red;
//       case Priority.medium:
//         return Colors.orange;
//       case Priority.low:
//         return Colors.green;
//     }
//   }
// }

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/add_task_overlay.dart';
import '../widgets/task_options_overalay.dart';
import '../utils/formatters.dart';
import '../services/speech_service.dart';
import '../services/voice_command_processor.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [
    Task(
      title: 'Take Medicines Daily',
      description: '2 Antibiotics per day',
      startTime: TimeOfDay(hour: 21, minute: 6),
      endTime: TimeOfDay(hour: 21, minute: 30),
      date: DateTime.now(),
      priority: Priority.high,
      remindBefore: '5 minutes early',
      repeat: 'None',
    ),
    Task(
      title: 'Doctor Appointment',
      description: 'Dr.Sumanathilake - Check',
      startTime: TimeOfDay(hour: 21, minute: 6),
      endTime: TimeOfDay(hour: 21, minute: 30),
      date: DateTime.now(),
      priority: Priority.low,
      remindBefore: '5 minutes early',
      repeat: 'None',
    ),
  ];

  int selectedDateIndex = 0;
  late List<DateTime> weekDates;
  late ScrollController _dateScrollController;

  // Search and voice functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final SpeechService _speechService = SpeechService();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
    _generateWeekDates();

    // Initialize speech service
    _speechService.initialize();

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _searchController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  void _generateWeekDates() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Generate 30 days instead of just 4
    weekDates = List.generate(
      30,
          (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  // Get tasks for the selected date
  List<Task> _getTasksForSelectedDate() {
    if (weekDates.isEmpty || selectedDateIndex >= weekDates.length) {
      return [];
    }

    DateTime selectedDate = weekDates[selectedDateIndex];
    return tasks.where((task) {
      return _isSameDay(task.date, selectedDate);
    }).toList();
  }

  // Filter tasks based on search query
  List<Task> _getFilteredTasks() {
    // If not searching, show tasks for selected date
    if (!_isSearching) {
      return _getTasksForSelectedDate();
    }

    // If searching, filter all tasks based on query
    return tasks.where((task) {
      final query = _searchQuery.toLowerCase();
      final titleMatch = task.title.toLowerCase().contains(query);
      final descriptionMatch = task.description.toLowerCase().contains(query);
      final priorityMatch = _getPriorityString(task.priority).toLowerCase().contains(query);

      return titleMatch || descriptionMatch || priorityMatch;
    }).toList();
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Handle voice commands
  void _startVoiceSearch() async {
    if (_speechService.isListening) {
      await _speechService.stopListening();
      return;
    }

    // Show user that we're listening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Listening... Speak now.'),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await _speechService.startListening(
      onResult: (String text) {
        if (text.isEmpty) return;

        // Process the voice command
        final command = VoiceCommandProcessor.processCommand(text);
        _handleVoiceCommand(command, text);
      },
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start voice recognition'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle different types of voice commands
  void _handleVoiceCommand(VoiceCommand command, String originalText) {
    switch (command.type) {
      case CommandType.search:
        final query = command.parameters['query'] as String;
        setState(() {
          _searchController.text = query;
          _searchQuery = query;
          _isSearching = _searchQuery.isNotEmpty;
        });
        _speechService.speak('Searching for $query');
        break;

      case CommandType.filter:
        if (command.parameters.containsKey('priority')) {
          final priority = command.parameters['priority'] as Priority;
          final priorityString = _getPriorityString(priority).split(' ')[0]; // Get just "High", "Medium", "Low"
          setState(() {
            _searchController.text = priorityString;
            _searchQuery = priorityString;
            _isSearching = true;
          });
          _speechService.speak('Showing $priorityString priority tasks');
        } else if (command.parameters.containsKey('date')) {
          final date = command.parameters['date'] as DateTime;
          // Find the index of the date in weekDates
          int dateIndex = -1;
          for (int i = 0; i < weekDates.length; i++) {
            if (_isSameDay(weekDates[i], date)) {
              dateIndex = i;
              break;
            }
          }

          if (dateIndex != -1) {
            setState(() {
              selectedDateIndex = dateIndex;
              _clearSearch(); // Clear any existing search
            });
            final dateString = _isSameDay(date, DateTime.now()) ? 'today' : Formatters.formatDate(date);
            _speechService.speak('Showing tasks for $dateString');
          }
        }
        break;

      case CommandType.create:
      // Parse task details from voice command
        final taskDetails = command.parameters['taskDetails'] as String;
        _showAddTaskOverlayWithVoiceInput(taskDetails);
        break;

      case CommandType.complete:
        final taskName = command.parameters['taskName'] as String;
        final matchingTask = VoiceCommandProcessor.findMatchingTask(tasks, taskName);

        if (matchingTask != null) {
          final index = tasks.indexOf(matchingTask);
          setState(() {
            tasks[index].isCompleted = true;
          });
          _speechService.speak('Marked ${matchingTask.title} as completed');
        } else {
          _speechService.speak('I couldn\'t find a task matching $taskName');
        }
        break;

      case CommandType.unknown:
      default:
      // Default to search with the entire text
        setState(() {
          _searchController.text = originalText;
          _searchQuery = originalText;
          _isSearching = _searchQuery.isNotEmpty;
        });
        break;
    }
  }

  // New method to show AddTaskOverlay with parsed voice input
  void _showAddTaskOverlayWithVoiceInput(String taskDetails) {
    // Try to extract key details from voice input
    final selectedDate = weekDates[selectedDateIndex];

    // Show the overlay and parse details when it's created
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AddTaskOverlay(
        initialDate: selectedDate,
        voiceInputDetails: taskDetails,
        onTaskCreated: (Task newTask) {
          setState(() {
            tasks.add(newTask);
          });
        },
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _showAddTaskOverlay() {
    // Pass the selected date to the overlay
    final selectedDate = weekDates[selectedDateIndex];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AddTaskOverlay(
        // Pass the selected date to initialize the task with
        initialDate: selectedDate,
        onTaskCreated: (Task newTask) {
          setState(() {
            tasks.add(newTask);
          });
        },
      ),
    );
  }

  void _showTaskOptionsOverlay(Task task, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => TaskOptionsOverlay(
        onEditTask: () {
          Navigator.pop(context);
          _editTask(task, index);
        },
        onTaskCompleted: () {
          setState(() {
            task.isCompleted = true;
          });
          Navigator.pop(context);
        },
        onDeleteTask: () {
          setState(() {
            tasks.removeAt(index);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editTask(Task task, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AddTaskOverlay(
        task: task,
        initialDate: task.date,
        onTaskCreated: (Task updatedTask) {
          setState(() {
            tasks[index] = updatedTask;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered tasks
    List<Task> filteredTasks = _getFilteredTasks();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (!_isSearching) _buildDateSelector(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _isSearching ? 'Search Results' : 'Today task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(filteredTasks),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskOverlay,
        backgroundColor: const Color(0xFF77588D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Build widgets
  Widget _buildHeader() {
    // Count active tasks for the selected date
    final activeTasks = _isSearching
        ? _getFilteredTasks().where((task) => !task.isCompleted).length
        : _getTasksForSelectedDate().where((task) => !task.isCompleted).length;

    final selectedDate = weekDates[selectedDateIndex];
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final dateText = _isSearching
        ? 'matching your search'
        : isToday
        ? 'today'
        : 'on ${Formatters.formatDate(selectedDate)}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'You have $activeTasks tasks to complete\n$dateText',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Reminders........',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
            ),
            IconButton(
              icon: Icon(
                _speechService.isListening ? Icons.mic : Icons.mic_none,
                color: _speechService.isListening ? Colors.red : Colors.white,
              ),
              onPressed: _startVoiceSearch,
            ),
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: _clearSearch,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: weekDates.length,
        itemBuilder: (context, index) {
          final date = weekDates[index];
          final isSelected = index == selectedDateIndex;
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDateIndex = index;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF77588D).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Formatters.getMonthAbbreviation(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF503663)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF503663)
                              : Colors.white,
                        ),
                      ),
                      if (isToday)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF503663) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.getDayAbbreviation(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? const Color(0xFF503663)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.event_note,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            _isSearching
                ? 'No tasks match your search'
                : 'No tasks for this day',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),
          if (!_isSearching)
            ElevatedButton.icon(
              onPressed: _showAddTaskOverlay,
              icon: Icon(Icons.add),
              label: Text('Add a Task'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          if (_isSearching)
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: Icon(Icons.clear),
              label: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasksToShow) {
    return ListView.builder(
      itemCount: tasksToShow.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final task = tasksToShow[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task.title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF77588D).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: const Color(0xFF77588D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isSameDay(task.date, DateTime.now())
                                ? 'Today'
                                : Formatters.formatDate(task.date),
                            style: TextStyle(
                              color: const Color(0xFF77588D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.purple[900],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${Formatters.formatTimeOfDay(task.startTime)} - ${Formatters.formatTimeOfDay(task.endTime)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: _getPriorityColor(task.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPriorityString(task.priority),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showTaskOptionsOverlay(task, tasks.indexOf(task)),
            ),
          ),
        );
      },
    );
  }

  String _getPriorityString(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'High Priority';
      case Priority.medium:
        return 'Medium Priority';
      case Priority.low:
        return 'Low Priority';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}
