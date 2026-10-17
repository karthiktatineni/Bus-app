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
                  tooltip: 'Edit bill details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editBill(context, ref, bill),
                ),
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
                      if (isAdmin && bill.uploaderName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Uploaded by ${bill.uploaderName}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      if (bill.tax > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax amount:',
                                style: TextStyle(fontSize: 12)),
                            Text(
                                '₹${NumberFormat('#,###.##').format(bill.tax)}',
                                style: const TextStyle(
                                    fontFamily: 'JetBrainsMono', fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: bill.imageUrl == null
                              ? null
                              : () => _showInvoiceImage(context, bill),
                          child: Container(
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
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          bill.imageUrl!,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                            child: Text(
                                                'Invoice image unavailable'),
                                          ),
                                        ),
                                        const Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: Tooltip(
                                            message: 'Tap to open invoice',
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.black54,
                                              child: Icon(
                                                Icons.open_in_full,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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

  Future<void> _showInvoiceImage(BuildContext context, Bill bill) {
    final imageUrl = bill.imageUrl;
    if (imageUrl == null) return Future<void>.value();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Invoice image unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  tooltip: 'Close invoice preview',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editBill(BuildContext context, WidgetRef ref, Bill bill) async {
    final formKey = GlobalKey<FormState>();
    final vendor = TextEditingController(text: bill.vendor);
    final number = TextEditingController(text: bill.billNo);
    final total = TextEditingController(text: bill.total.toStringAsFixed(2));
    var billDate = bill.billDate;
    var saving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit bill details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: vendor,
                    decoration: const InputDecoration(labelText: 'Vendor *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the vendor.'
                        : null,
                  ),
                  TextFormField(
                    controller: number,
                    decoration: const InputDecoration(labelText: 'Bill number'),
                  ),
                  TextFormField(
                    controller: total,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total printed on bill *',
                      prefixText: '₹',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      return amount == null || amount <= 0
                          ? 'Enter the total printed on the bill.'
                          : null;
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bill date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(billDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: dialogContext,
                        initialDate: billDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setDialogState(() => billDate = selected);
                      }
                    },
                  ),
                  if (errorMessage != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(errorMessage!,
                          style: const TextStyle(color: AppTheme.danger)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        errorMessage = null;
                      });
                      try {
                        await ref.read(billRepositoryProvider).update(
                              bill.copyWith(
                                vendor: vendor.text.trim(),
                                billNo: number.text.trim(),
                                total: double.parse(total.text.trim()),
                                billDate: billDate,
                              ),
                            );
                        ref.invalidate(billRepositoryProvider);
                        ref.invalidate(billsListProvider);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        setDialogState(() {
                          saving = false;
                          errorMessage = 'Could not update this bill: $error';
                        });
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    vendor.dispose();
    number.dispose();
    total.dispose();
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
      ref.invalidate(billRepositoryProvider);
      ref.invalidate(billsListProvider);
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
      ref.invalidate(billsListProvider);
      ref.invalidate(billRepositoryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the invoice image.')),
      );
    }
  }
}
