import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class CustomActionButton extends StatelessWidget {
  const CustomActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
  }) : super(key: key);

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      icon: Icon(icon),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  TextEditingController taskNameController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedPriority = 'High';
  bool sortHighToLow = false;

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Tasks'),
          actions: [
            Center(
              child: CustomActionButton(
                label: "Filter High to Low",
                icon: Icons.sort,
                onPressed: () {
                  setState(() {
                    sortHighToLow = true;
                  });
                  Navigator.of(context).pop();
                },
                backgroundColor: Colors.red,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: CustomActionButton(
                label: "Sort by Low to High",
                onPressed: () {
                  setState(() {
                    sortHighToLow = false;
                  });
                  Navigator.of(context).pop();
                },
                backgroundColor: Colors.blue,
                icon: Icons.sort,
              ),
            ),
          ],
        );
      },
    );
  }

  void _sortTasks(List<Map> tasks) {
    tasks.sort((a, b) {
      int priorityComparison =
          _priorityValue(a['priority']) - _priorityValue(b['priority']);
      return sortHighToLow ? -priorityComparison : priorityComparison;
    });
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 2;
      case 'Medium':
        return 1;
      case 'Low':
        return 0;
      default:
        return 0;
    }
  }

  void _showEditDialog(BuildContext context, Map task, int index) {
    taskNameController.text = task['name'];
    selectedDate = task['date'];
    selectedPriority = task['priority'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: SizedBox(
              width: 500,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: taskNameController,
                    decoration: const InputDecoration(labelText: 'Task Name'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );

                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'High',
                        groupValue: selectedPriority,
                        onChanged: (String? value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('High'),
                      Radio<String>(
                        value: 'Medium',
                        groupValue: selectedPriority,
                        onChanged: (String? value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('Medium'),
                      Radio<String>(
                        value: 'Low',
                        groupValue: selectedPriority,
                        onChanged: (String? value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('Low'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final taskBox = await Hive.openBox('tasks');
                  final updatedTask = {
                    'name': taskNameController.text,
                    'date': selectedDate,
                    'priority': selectedPriority,
                  };
                  taskBox.putAt(index, updatedTask);
                  print('Task updated in Hive: $updatedTask');
                  Navigator.of(context).pop();
                },
                child: const Text('Update Task'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteAlert(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final taskBox = Hive.box('tasks');
                taskBox.deleteAt(index);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomActionButton(
            backgroundColor: Colors.green,
            icon: Icons.add,
            label: "Add Task",
            onPressed: () {
              setState(() {
                taskNameController.clear();
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Add Task'),
                      content: SizedBox(
                        width: 500,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            TextField(
                              controller: taskNameController,
                              decoration:
                                  const InputDecoration(labelText: 'Task Name'),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );

                                    if (picked != null &&
                                        picked != selectedDate) {
                                      setState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: const Text('Select Date'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'High',
                                  groupValue: selectedPriority,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedPriority = value!;
                                    });
                                  },
                                ),
                                const Text('High'),
                                Radio<String>(
                                  value: 'Medium',
                                  groupValue: selectedPriority,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedPriority = value!;
                                    });
                                  },
                                ),
                                const Text('Medium'),
                                Radio<String>(
                                  value: 'Low',
                                  groupValue: selectedPriority,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedPriority = value!;
                                    });
                                  },
                                ),
                                const Text('Low'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final taskBox = await Hive.openBox('tasks');
                            final task = {
                              'name': taskNameController.text,
                              'date': selectedDate,
                              'priority': selectedPriority,
                            };
                            taskBox.add(task);
                            print('Task added to Hive: $task');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Add Task'),
                        ),
                      ],
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(
            width: 10,
          ),
          CustomActionButton(
            backgroundColor: Colors.blue,
            icon: Icons.list_outlined,
            label: "Filter Task",
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ValueListenableBuilder(
          valueListenable: Hive.box('tasks').listenable(),
          builder: (context, Box tasksBox, _) {
            List<Map> tasks = List<Map>.from(tasksBox.values);

            _sortTasks(tasks);

            return tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks available.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (BuildContext context, int index) {
                            final task = tasks[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Task: ${task['name']}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const Divider(),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date: ${DateFormat('yyyy-MM-dd').format(task['date'])}",
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          color: task['priority'] == 'High'
                                              ? Colors.red
                                              : Colors.green,
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10, left: 10),
                                              child: Text(
                                                " ${task['priority']}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.clip,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: task['completed'] ?? false,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              task['completed'] = value;
                                            });
                                          },
                                        ),
                                        const Text('Mark as Completed'),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        _showEditDialog(context, task, index);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _showDeleteAlert(context, index);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 70,
                      )
                    ],
                  );
          },
        ),
      ),
    );
  }
}
