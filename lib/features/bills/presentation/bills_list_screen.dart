import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class BillsListScreen extends ConsumerWidget {
  const BillsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billRepo = ref.watch(billRepositoryProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Invoices & Bills'),
      ),
      body: FutureBuilder<List<Bill>>(
        future: billRepo.listAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bills = snapshot.data ?? [];
          if (bills.isEmpty) {
            return const EmptyState(
                message: 'No bills logged yet', icon: Icons.receipt_long);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go('/bills/${bill.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bill.vendor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '₹${NumberFormat('#,###').format(bill.total)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Invoice: ${bill.billNo}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•',
                                  style: TextStyle(color: AppTheme.border)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(bill.billDate),
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin && bill.uploaderName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Uploaded by ${bill.uploaderName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bill.ocrConfidence != null
                                      ? 'OCR CONFIDENCE ${(bill.ocrConfidence! * 100).toInt()}%'
                                      : 'MANUAL ENTRY',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                              const Row(
                                children: [
                                  Text('View Bill',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor)),
                                  Icon(Icons.chevron_right,
                                      size: 14, color: AppTheme.primaryColor),
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
            },
          );
        },
      ),
    );
  }
}
