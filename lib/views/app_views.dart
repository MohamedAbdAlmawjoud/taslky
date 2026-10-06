import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.register, this.forgot = false});
  final bool register, forgot;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      final auth = context.read<AuthProvider>();
      if (widget.forgot) {
        await auth.resetPassword(email.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent.')),
          );
        }
      } else if (widget.register) {
        await auth.register(name.text, email.text, password.text);
      } else {
        await auth.login(email.text, password.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AuthProvider>().error ?? e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.forgot
        ? 'Reset your password'
        : widget.register
        ? 'Create your account'
        : 'Welcome back';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'taskly',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 38),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.forgot
                          ? 'We’ll send a reset link to your email.'
                          : widget.register
                          ? 'Make a little room for what matters.'
                          : 'Pick up where you left off.',
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 28),
                    if (widget.register) ...[
                      CustomTextField(
                        controller: name,
                        label: 'Name',
                        validator: requiredText,
                      ),
                      const SizedBox(height: 15),
                    ],
                    CustomTextField(
                      controller: email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    if (!widget.forgot) ...[
                      const SizedBox(height: 15),
                      CustomTextField(
                        controller: password,
                        label: 'Password',
                        obscure: true,
                        validator: (v) => (v?.length ?? 0) < 6
                            ? 'Use at least 6 characters'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 22),
                    CustomButton(
                      label: widget.forgot
                          ? 'Send reset link'
                          : widget.register
                          ? 'Create account'
                          : 'Sign in',
                      busy: busy,
                      onPressed: submit,
                    ),
                    if (!widget.register && !widget.forgot)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot'),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(
                          widget.register ? '/login' : '/register',
                        ),
                        child: Text(
                          widget.register
                              ? 'Already have an account? Sign in'
                              : 'New to Taskly? Create an account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;
  @override
  Widget build(BuildContext context) {
    final index = location.startsWith('/tasks')
        ? 1
        : location.startsWith('/calendar')
        ? 2
        : location.startsWith('/profile')
        ? 3
        : 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            context.go(['/today', '/tasks', '/calendar', '/profile'][i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final today = DateTime.now();
    final todayTasks = p.tasks.where(
      (t) => t.dueDate != null && DateUtils.isSameDay(t.dueDate, today),
    );
    final upcoming = p.tasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isAfter(
                DateTime(today.year, today.month, today.day),
              ) &&
              !DateUtils.isSameDay(t.dueDate, today) &&
              !t.isCompleted,
        )
        .take(3);
    final complete = p.tasks.where((t) => t.isCompleted).length;
    return RefreshIndicator(
      onRefresh: () async {
        final id = context.read<AuthProvider>().currentUser?.uid;
        if (id != null) await p.loadTasks(id);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(today),
            style: const TextStyle(color: AppColors.secondary),
          ),
          const SizedBox(height: 15),
          Text(
            'Things to get done',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$complete of ${p.tasks.length} tasks completed',
            style: const TextStyle(color: AppColors.secondary),
          ),
          const SizedBox(height: 18),
          if (p.tasks.isNotEmpty)
            LinearProgressIndicator(
              value: complete / p.tasks.length,
              color: AppColors.accent,
              backgroundColor: AppColors.border,
              minHeight: 5,
            ),
          const SizedBox(height: 30),
          _section(context, 'Today', todayTasks.toList()),
          const SizedBox(height: 24),
          _section(context, 'Coming up', upcoming.toList()),
          if (p.loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (p.error != null)
            Text(
              'Could not load tasks: ${p.error}',
              style: const TextStyle(color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}

Widget _section(BuildContext context, String title, List<TaskModel> tasks) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              title == 'Today'
                  ? 'Nothing planned for today.'
                  : 'Your upcoming tasks will show here.',
              style: const TextStyle(color: AppColors.secondary),
            ),
          ),
        ...tasks.map(
          (t) => TaskCard(
            task: t,
            onTap: () => context.push('/task/${t.id}'),
            onToggle: () => context.read<TaskProvider>().toggleTask(t),
          ),
        ),
      ],
    );

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    const filters = ['All', 'Today', 'Upcoming', 'Completed'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
      children: [
        Text(
          'Tasks',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          onChanged: p.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search tasks',
            filled: true,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: p.filter == f,
                      onSelected: (_) => p.selectFilter(f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: p.categoryFilter,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...AppStrings.categories.map(
                    (x) => DropdownMenuItem(value: x, child: Text(x)),
                  ),
                ],
                onChanged: p.selectCategory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: p.priorityFilter,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All priorities'),
                  ),
                  ...AppStrings.priorities.map(
                    (x) => DropdownMenuItem(value: x, child: Text(x)),
                  ),
                ],
                onChanged: p.selectPriority,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.loading)
          const Center(child: CircularProgressIndicator())
        else if (p.error != null)
          Text(
            'Unable to load tasks: ${p.error}',
            style: const TextStyle(color: AppColors.accent),
          )
        else if (p.filteredTasks.isEmpty)
          const EmptyState(
            title: 'No tasks found',
            message: 'Try another filter or add a task to get started.',
          )
        else
          ...p.filteredTasks.map(
            (t) => TaskCard(
              task: t,
              onTap: () => context.push('/task/${t.id}'),
              onToggle: () => p.toggleTask(t),
            ),
          ),
      ],
    );
  }
}

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task});
  final TaskModel? task;
  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title ?? ''),
      description = TextEditingController(text: widget.task?.description ?? '');
  late String category = widget.task?.category ?? AppStrings.categories.first,
      priority = widget.task?.priority ?? 'Medium';
  DateTime? date;
  TimeOfDay? time;
  bool reminder = false, busy = false;
  @override
  void initState() {
    super.initState();
    date = widget.task?.dueDate;
    reminder = widget.task?.reminder ?? false;
    if (widget.task?.dueTime != null) {
      final p = widget.task!.dueTime!.split(':');
      time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (reminder && (date == null || time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a due date and time to schedule a reminder.'),
        ),
      );
      return;
    }
    if (reminder && date != null && time != null) {
      final reminderAt = DateTime(
        date!.year,
        date!.month,
        date!.day,
        time!.hour,
        time!.minute,
      );
      if (!reminderAt.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose a future time for the reminder.'),
          ),
        );
        return;
      }
    }
    setState(() => busy = true);
    try {
      final task = TaskModel(
        id: widget.task?.id ?? '',
        title: title.text,
        description: description.text,
        category: category,
        priority: priority,
        isCompleted: widget.task?.isCompleted ?? false,
        dueDate: date,
        dueTime: time == null
            ? null
            : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
        reminder: reminder,
      );
      final p = context.read<TaskProvider>();
      final messenger = ScaffoldMessenger.of(context);
      if (widget.task == null) {
        await p.createTask(task);
      } else {
        await p.updateTask(task);
      }
      final reminderError = p.reminderError;
      if (mounted) {
        context.pop();
        if (reminderError != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Task saved, but reminder could not be scheduled: $reminderError',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save task: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.task == null ? 'New task' : 'Edit task')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          CustomTextField(
            controller: title,
            label: 'Title',
            validator: requiredText,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: description,
            label: 'Description',
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: AppStrings.categories
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: AppStrings.priorities
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (v) => setState(() => priority = v!),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              date == null
                  ? 'Due date'
                  : 'Due ${DateFormat.yMMMd().format(date!)}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => date = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              time == null ? 'Due time' : 'Due ${time!.format(context)}',
            ),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final d = await showTimePicker(
                context: context,
                initialTime: time ?? TimeOfDay.now(),
              );
              if (d != null) setState(() => time = d);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder'),
            value: reminder,
            subtitle: const Text('Get a notification at the task’s due time.'),
            onChanged: (v) async {
              if (!v) {
                setState(() => reminder = false);
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final granted = await context
                  .read<TaskProvider>()
                  .requestReminderPermission();
              if (!mounted) return;
              if (granted) {
                setState(() => reminder = true);
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications are disabled. Allow them in device settings to use reminders.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: widget.task == null ? 'Save task' : 'Save changes',
            busy: busy,
            onPressed: save,
          ),
        ],
      ),
    ),
  );
}

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    TaskModel? task;
    for (final x in p.tasks) {
      if (x.id == id) task = x;
    }
    if (task == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Task unavailable',
          message: 'This task may have been deleted.',
        ),
      );
    }
    final t = task;
    final overdue =
        !t.isCompleted &&
        t.dueDate != null &&
        t.dueDate!.isBefore(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          IconButton(
            onPressed: () => context.push('/edit/${t.id}', extra: t),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete task?'),
                  content: const Text('This task will be permanently removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<TaskProvider>().deleteTask(t.id);
                if (context.mounted) context.pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (overdue)
            const Text(
              'OVERDUE',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            t.title,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            t.description.isEmpty ? 'No description' : t.description,
            style: const TextStyle(height: 1.6, color: AppColors.secondary),
          ),
          const Divider(height: 36),
          _detail('Category', t.category),
          _detail('Priority', t.priority),
          _detail(
            'Due date',
            t.dueDate == null
                ? 'Not set'
                : DateFormat.yMMMMd().format(t.dueDate!),
          ),
          _detail('Due time', t.dueTime ?? 'Not set'),
          _detail('Reminder', t.reminder ? 'On' : 'Off'),
          _detail('Status', t.isCompleted ? 'Completed' : 'To do'),
          const SizedBox(height: 24),
          CustomButton(
            label: t.isCompleted ? 'Mark as to do' : 'Mark complete',
            onPressed: () => context.read<TaskProvider>().toggleTask(t),
          ),
        ],
      ),
    );
  }
}

Widget _detail(String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(k, style: const TextStyle(color: AppColors.secondary)),
      ),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  ),
);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now(), focused = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final day = p.tasks
        .where(
          (t) => t.dueDate != null && DateUtils.isSameDay(t.dueDate, selected),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
      children: [
        Text(
          'Calendar',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        CalendarDatePicker(
          initialDate: selected,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          currentDate: DateTime.now(),
          onDateChanged: (d) => setState(() => selected = d),
        ),
        const Divider(),
        Text(
          DateFormat('EEEE, MMMM d').format(selected),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (day.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 28),
            child: EmptyState(
              title: 'A clear day',
              message: 'No tasks are scheduled for this date.',
            ),
          )
        else
          ...day.map(
            (t) => TaskCard(
              task: t,
              onTap: () => context.push('/task/${t.id}'),
              onToggle: () => p.toggleTask(t),
            ),
          ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>(),
        p = context.watch<TaskProvider>();
    final total = p.tasks.length,
        done = p.tasks.where((t) => t.isCompleted).length,
        ratio = total == 0 ? 0 : done / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.soft,
          child: Icon(Icons.person_outline, size: 32, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            auth.profile?.name ??
                auth.currentUser?.displayName ??
                'Taskly user',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            auth.currentUser?.email ?? '',
            style: const TextStyle(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('$done', 'Completed'),
            _stat('$total', 'Total'),
            _stat('${(ratio * 100).round()}%', 'Progress'),
          ],
        ),
        const Divider(height: 40),
        const ListTile(
          leading: Icon(Icons.notifications_none),
          title: Text('Reminders'),
          subtitle: Text('Task reminders are saved with each task'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About Taskly'),
          subtitle: Text('Make room for what matters.'),
        ),
        const SizedBox(height: 18),
        CustomButton(
          label: 'Log out',
          outlined: true,
          onPressed: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}

Widget _stat(String n, String label) => Column(
  children: [
    Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: AppColors.secondary)),
  ],
);
