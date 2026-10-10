import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFf9f9ff),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('FleetTrack depot', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
            Text('Fleet Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black87), onPressed: () {}),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black87), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFF00355f),
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          )
        ],
      ),
      body: dashboardDataAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Good morning, Rajesh Sharma', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Shift Lead Engineer • 10 vehicles monitored', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => ref.refresh(dashboardDataProvider),
                    icon: const Icon(Icons.sync, color: Color(0xFF0f4c81)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Overdue', value: data.overdueCount.toString(), icon: Icons.warning, color: Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Due 14d', value: data.dueSoonCount.toString(), icon: Icons.schedule, color: Colors.black87)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Bay Busy', value: data.workshopCount.toString(), icon: Icons.home_repair_service, color: const Color(0xFF00355f))),
                ],
              ),
              const SizedBox(height: 24),

              // To do
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('To do', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF0f4c81), borderRadius: BorderRadius.circular(12)),
                        child: Text('${data.todos.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  TextButton(onPressed: () {}, child: const Text('View all >')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: data.todos.map((todo) => ListTile(
                    leading: Checkbox(value: false, onChanged: (v) {}),
                    title: Text(todo.taskName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${todo.vehicleId} • ${todo.details}', style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: todo.status.contains('Overdue') ? Colors.red.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(todo.status, style: TextStyle(
                        color: todo.status.contains('Overdue') ? Colors.red : Colors.black87,
                        fontSize: 11, fontWeight: FontWeight.bold
                      )),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF00355f),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Repairs'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Audit'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Spares'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Logs'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
