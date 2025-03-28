import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/add_task_overlay.dart';
import '../widgets/task_options_overalay.dart';
import '../utils/formatters.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  bool isLoading = true;
  String errorMessage = '';

  int selectedDateIndex = 0;
  late List<DateTime> weekDates;
  late ScrollController _dateScrollController;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
    _generateWeekDates();

    // Initialize task service and load tasks
    _initializeTaskService();

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
  }

  Future<void> _initializeTaskService() async {
    try {
      await TaskService.initialize();
      _loadTasks();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to initialize task service: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final DateTime selectedDate = weekDates[selectedDateIndex];
      final loadedTasks = await TaskService.getTasksByDate(selectedDate);

      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load tasks: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _searchController.dispose();
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

  // New method to mark a task as completed via the API
  Future<void> _markTaskAsCompleted(Task task) async {
    if (task.id == null) return;

    try {
      final updatedTask = await TaskService.completeTask(task.id!);
      if (updatedTask != null) {
        setState(() {
          final index = tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            tasks[index] = updatedTask;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark task as completed: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
        onTaskCreated: (Task newTask) async {
          // Save the task to the backend
          final createdTask = await TaskService.createTask(newTask);
          if (createdTask != null) {
            setState(() {
              tasks.add(createdTask);
            });
          }
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
        onTaskCompleted: () async {
          Navigator.pop(context);
          if (task.id != null) {
            await _markTaskAsCompleted(task);
          }
        },
        onDeleteTask: () async {
          Navigator.pop(context);
          if (task.id != null) {
            final success = await TaskService.deleteTask(task.id!);
            if (success) {
              setState(() {
                tasks.removeAt(index);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete task'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
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
        onTaskCreated: (Task updatedTask) async {
          // Update the task in the backend
          final savedTask = await TaskService.updateTask(updatedTask);
          if (savedTask != null) {
            setState(() {
              final idx = tasks.indexWhere((t) => t.id == savedTask.id);
              if (idx != -1) {
                tasks[idx] = savedTask;
              }
            });
          }
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
              child: isLoading
                  ? _buildLoadingIndicator()
                  : errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : filteredTasks.isEmpty
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

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withOpacity(0.7),
          ),
          SizedBox(height: 16),
          Text(
            'Error loading tasks',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTasks,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
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
              _loadTasks(); // Load tasks for the selected date
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
              onPressed: () => _showTaskOptionsOverlay(task, index),
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