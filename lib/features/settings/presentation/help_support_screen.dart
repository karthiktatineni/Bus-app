import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.support_agent,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Depot Support Desk',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('24/7 Operations Helpline',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Email: support@fleetpulse.internal',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Toll Free: 1800 425 2222',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Radio Frequency: Depot Channel 04',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _faqItem('How do I log a service without a physical bill?',
                      'You can proceed to step 4 in Add Service and skip the OCR scan. The record will be marked pending invoice verification.'),
                  const Divider(height: 12),
                  _faqItem('How are reminder due dates calculated?',
                      'Upcoming tasks are dynamically calculated from vehicle odometer readings and scheduled service intervals (e.g. every 10,000 km or 6 months).'),
                  const Divider(height: 12),
                  _faqItem('Who can add new vehicles?',
                      'Only users with the Administrator role have permissions to add and edit vehicle assets.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(answer,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
