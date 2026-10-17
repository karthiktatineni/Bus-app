import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final Set<String> _dismissedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final serviceRepo = ref.watch(serviceRepositoryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Maintenance Reminders'),
      ),
      body: FutureBuilder<List<MaintenanceTask>>(
        future: serviceRepo.upcomingTasks(withinDays: 60),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks = snapshot.data ?? [];
          final tasks = allTasks
              .where((t) => !t.isDone && !_dismissedTaskIds.contains(t.id))
              .toList();

          if (tasks.isEmpty) {
            return const EmptyState(
              message: 'All tasks completed! No pending reminders.',
              icon: Icons.check_circle_outline,
            );
          }

          final now = DateTime.now();
          final overdue = tasks.where((t) => t.isOverdue).toList();
          final thisWeek = tasks.where((t) {
            if (t.isOverdue || t.dueDate == null) return false;
            final diff = t.dueDate!.difference(now).inDays;
            return diff >= 0 && diff <= 7;
          }).toList();
          final nextWeek = tasks.where((t) {
            if (t.dueDate == null) return false;
            final diff = t.dueDate!.difference(now).inDays;
            return diff > 7 && diff <= 14;
          }).toList();
          final later = tasks.where((t) {
            if (t.dueDate == null) return true;
            return t.dueDate!.difference(now).inDays > 14;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdue.isNotEmpty) ...[
                _buildSectionHeader('OVERDUE ACTION REQUIRED', AppTheme.danger,
                    Icons.warning_amber_rounded),
                const SizedBox(height: 8),
                ...overdue.map((t) => _buildReminderCard(t, isOverdue: true)),
                const SizedBox(height: 16),
              ],
              if (thisWeek.isNotEmpty) ...[
                _buildSectionHeader(
                    'DUE THIS WEEK', AppTheme.warning, Icons.schedule),
                const SizedBox(height: 8),
                ...thisWeek.map((t) => _buildReminderCard(t)),
                const SizedBox(height: 16),
              ],
              if (nextWeek.isNotEmpty) ...[
                _buildSectionHeader('DUE NEXT WEEK', AppTheme.primaryColor,
                    Icons.calendar_today_outlined),
                const SizedBox(height: 8),
                ...nextWeek.map((t) => _buildReminderCard(t)),
                const SizedBox(height: 16),
              ],
              if (later.isNotEmpty) ...[
                _buildSectionHeader(
                    'UPCOMING LATER', AppTheme.textSecondary, Icons.event_note),
                const SizedBox(height: 8),
                ...later.map((t) => _buildReminderCard(t)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(MaintenanceTask task, {bool isOverdue = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.danger.withValues(alpha: 0.12)
                          : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOverdue ? 'OVERDUE' : 'SCHEDULED',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? AppTheme.danger
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Due: ${task.dueDate != null ? DateFormat('dd MMM yyyy').format(task.dueDate!) : 'Scheduled'}',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color:
                          isOverdue ? AppTheme.danger : AppTheme.textSecondary,
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: AppTheme.border)),
                  const SizedBox(width: 8),
                  Text(
                    'Target: ${task.dueKm != null ? NumberFormat('#,###').format(task.dueKm!) : '--'} km',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _dismissedTaskIds.add(task.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Marked "${task.title}" done'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              setState(() => _dismissedTaskIds.remove(task.id));
                            },
                          ),
                        ),
                      );
                    },
                    child:
                        const Text('Mark Done', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => context.go('/services/add'),
                    child: const Text('Log Service',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
