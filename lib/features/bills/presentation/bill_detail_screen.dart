import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class BillDetailScreen extends ConsumerWidget {
  final String billId;

  const BillDetailScreen({
    super.key,
    required this.billId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billRepo = ref.watch(billRepositoryProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

    return FutureBuilder<Bill?>(
      future: billRepo.get(billId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Invoice...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final bill = snapshot.data;
        if (bill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Detail')),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Invoice #${bill.billNo}'),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Delete bill',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteBill(context, ref, bill),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bill.vendor,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bill.ocrConfidence != null
                                  ? 'OCR ${(bill.ocrConfidence! * 100).toInt()}%'
                                  : 'MANUAL',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(bill.billDate)}',
                        style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (GST 18%):',
                              style: TextStyle(fontSize: 12)),
                          Text('₹${NumberFormat('#,###').format(bill.tax)}',
                              style: const TextStyle(
                                  fontFamily: 'JetBrainsMono', fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${NumberFormat('#,###').format(bill.total)}',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice preview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Scanned Invoice Document',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          if (isAdmin && bill.imageUrl != null)
                            IconButton(
                              tooltip: 'Delete invoice image',
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.danger),
                              onPressed: () =>
                                  _deleteBillImage(context, ref, bill),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: bill.imageUrl == null
                            ? const Center(
                                child: Text('No invoice image attached'),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  bill.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('Invoice image unavailable'),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteBill(
      BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text(
          'Delete invoice ${bill.billNo.isEmpty ? bill.vendor : bill.billNo} and its attached image? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete bill'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(billRepositoryProvider).delete(bill.id);
      if (!context.mounted) return;
      context.go('/bills');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill deleted.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this bill. Try again.')),
      );
    }
  }

  Future<void> _deleteBillImage(
      BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice image?'),
        content: const Text(
            'The bill record and its item details will remain. The image will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete image'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(billRepositoryProvider).deleteImage(bill.id);
      ref.invalidate(billRepositoryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the invoice image.')),
      );
    }
  }
}
