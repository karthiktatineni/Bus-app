import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers.dart';

class ServiceHistoryScreen extends ConsumerStatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  ConsumerState<ServiceHistoryScreen> createState() =>
      _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends ConsumerState<ServiceHistoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final serviceRepo = ref.watch(serviceRepositoryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Service History & Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            tooltip: 'Add Service',
            onPressed: () => context.go('/services/add'),
          ),
        ],
      ),
      body: FutureBuilder<List<ServiceRecord>>(
        future: serviceRepo.listAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snapshot.data ?? [];
          var records = allRecords;

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            records = records
                .where((r) =>
                    r.type.label.toLowerCase().contains(q) ||
                    r.workshop.toLowerCase().contains(q) ||
                    r.mechanic.toLowerCase().contains(q) ||
                    r.vehicleId.toLowerCase().contains(q))
                .toList();
          }

          if (_selectedCategory != 'All') {
            records = records
                .where((r) => r.type.label
                    .toLowerCase()
                    .contains(_selectedCategory.toLowerCase()))
                .toList();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search input
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search service type, mechanic, workshop...',
                  hintStyle:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['All', 'Routine', 'Oil', 'Brake', 'Engine'].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        showCheckmark: false,
                        onSelected: (val) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              if (records.isEmpty)
                const EmptyState(
                    message: 'No service records found',
                    icon: Icons.build_circle_outlined)
              else
                ...records.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/services/${r.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.type.label,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,###').format(r.total)}',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(r.date),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('•',
                                      style: TextStyle(color: AppTheme.border)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${NumberFormat('#,###').format(r.odometerKm)} km',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${r.workshop} (${r.mechanic})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Text('Details',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor)),
                                      Icon(Icons.chevron_right,
                                          size: 14,
                                          color: AppTheme.primaryColor),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
