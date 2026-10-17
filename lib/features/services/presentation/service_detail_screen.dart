import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/media_service.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceRepo = ref.watch(serviceRepositoryProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

    return FutureBuilder<ServiceRecord?>(
      future: serviceRepo.get(serviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Service...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final record = snapshot.data;
        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Service Detail')),
            body: const Center(child: Text('Service record not found')),
          );
        }
        final partsTotal =
            record.parts.fold<double>(0, (sum, part) => sum + part.totalCost);

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Service #${record.id.substring(0, record.id.length > 8 ? 8 : record.id.length)}'),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Edit service record',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/services/${record.id}/edit'),
                ),
              if (isAdmin)
                IconButton(
                  tooltip: 'Delete service record',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteService(context, ref, record),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Hero Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SERVICE RECORD',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(record.date),
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        record.type.label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Workshop: ${record.workshop} • Mechanic: ${record.mechanic}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ODOMETER',
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 9,
                                        color: AppTheme.textSecondary)),
                                Text(
                                    '${NumberFormat('#,###').format(record.odometerKm)} km',
                                    style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('TOTAL COST',
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 9,
                                        color: AppTheme.textSecondary)),
                                Text(
                                    '₹${NumberFormat('#,###').format(record.total)}',
                                    style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cost Breakdown Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost Breakdown',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _costRow('Labour Charges',
                          '₹${NumberFormat('#,##0.00').format(record.labourCost)}'),
                      _costRow('Parts & Consumables',
                          '₹${NumberFormat('#,##0.00').format(partsTotal)}'),
                      if (record.tax > 0)
                        _costRow('Tax',
                            '₹${NumberFormat('#,##0.00').format(record.tax)}'),
                      const Divider(height: 16),
                      _costRow(
                        'Bill total',
                        '₹${NumberFormat('#,##0.00').format(record.total)}',
                        isBold: true,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Replacement Parts Table Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Replaced Parts & Spares',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (record.parts.isEmpty)
                        const Text('No replaced parts recorded.')
                      else
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                              ),
                              children: [
                                _tableCell('Part Name', isHeader: true),
                                _tableCell('Qty', isHeader: true),
                                _tableCell('Cost',
                                    isHeader: true, align: TextAlign.right),
                              ],
                            ),
                            for (final part in record.parts)
                              TableRow(
                                children: [
                                  _tableCell(part.name),
                                  _tableCell(part.quantity.toString()),
                                  _tableCell(
                                    '₹${NumberFormat('#,##0.00').format(part.totalCost)}',
                                    align: TextAlign.right,
                                  ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Before & After Photos Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Service Inspection Photos',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            tooltip: 'Add service photo',
                            icon: const Icon(Icons.add_a_photo_outlined),
                            onPressed: () =>
                                _addServicePhoto(context, ref, record),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (record.photos.isEmpty)
                        const Text('No service photos attached.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary))
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth =
                                (constraints.maxWidth - 10).clamp(96.0, 160.0);
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final photo in record.photos)
                                  SizedBox(
                                    width: itemWidth,
                                    height: 104,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: _servicePhotoImage(photo.url),
                                        ),
                                        Positioned(
                                          left: 4,
                                          bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              photo.caption ??
                                                  photo.type.name.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9),
                                            ),
                                          ),
                                        ),
                                        if (isAdmin)
                                          Positioned(
                                            right: 2,
                                            top: 2,
                                            child: Material(
                                              color: Colors.black54,
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                constraints:
                                                    const BoxConstraints
                                                        .tightFor(
                                                        width: 36, height: 36),
                                                tooltip: 'Delete service photo',
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: Colors.white),
                                                onPressed: () => _deletePhoto(
                                                    context,
                                                    ref,
                                                    record,
                                                    photo),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attached Invoice Button
              if (record.billId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Attached Invoice / Bill'),
                    onPressed: () => context.go('/bills/${record.billId}'),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _costRow(String title, String amount,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text,
      {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontFamily: isHeader ? null : 'JetBrainsMono',
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _servicePhotoImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: AppTheme.surfaceMuted,
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return const ColoredBox(
      color: AppTheme.surfaceMuted,
      child: Icon(Icons.broken_image_outlined),
    );
  }

  Future<void> _addServicePhoto(
      BuildContext context, WidgetRef ref, ServiceRecord record) async {
    final type = await showModalBottomSheet<PhotoType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in [
              PhotoType.before,
              PhotoType.after,
              PhotoType.part
            ])
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text('Add ${value.name} service photo'),
                onTap: () => Navigator.pop(sheetContext, value),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    try {
      final media = ref.read(mediaServiceProvider);
      final path = await media.pickImageFromCamera() ??
          await media.pickImageFromGallery();
      if (path == null || !context.mounted) return;
      final compressed = await media.compressImage(path);
      await ref
          .read(serviceRepositoryProvider)
          .addPhoto(record.id, compressed, type);
      ref.invalidate(serviceRepositoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service photo added.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add this service photo.')),
      );
    }
  }

  Future<void> _deleteService(
      BuildContext context, WidgetRef ref, ServiceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service record?'),
        content: const Text(
            'The service entry, its parts and service photos will be deleted. Attached bills remain but will be unlinked. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete record'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(serviceRepositoryProvider).delete(record.id);
      if (!context.mounted) return;
      context.go('/services');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service record deleted.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this service record.')),
      );
    }
  }

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref,
      ServiceRecord record, ServicePhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service photo?'),
        content: const Text('This photo will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete photo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(serviceRepositoryProvider)
          .deletePhoto(record.id, photo.id);
      ref.invalidate(serviceRepositoryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this service photo.')),
      );
    }
  }
}
