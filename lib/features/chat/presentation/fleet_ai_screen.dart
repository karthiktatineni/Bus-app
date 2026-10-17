import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_drawer.dart';

class FleetAiScreen extends ConsumerStatefulWidget {
  const FleetAiScreen({super.key});

  @override
  ConsumerState<FleetAiScreen> createState() => _FleetAiScreenState();
}

class _FleetAiScreenState extends ConsumerState<FleetAiScreen> {
  static const _backendUrl = String.fromEnvironment(
    'FLEET_BACKEND_URL',
    defaultValue: String.fromEnvironment('OCR_SERVICE_URL'),
  );
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<({String text, bool user, List<String> sources})> _messages = [];
  bool _sending = false;
  static const _suggestions = [
    'Which buses are overdue for service?',
    'Which fitness certificates expire in 30 days?',
    'How much did we spend in the last 30 days?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add((text: text, user: true, sources: const []));
      _sending = true;
    });
    try {
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (accessToken == null || _backendUrl.isEmpty) {
        throw StateError(
            'The signed-in session or backend URL is unavailable.');
      }
      final response = await http
          .post(
            Uri.parse(_backendUrl).resolve('/ai/fleet-assistant'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Fleet assistant request failed.');
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = payload['answer'] as String?;
      final sources = (payload['citations'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((citation) => '[${citation['id']}] ${citation['source']}')
          .toList();
      setState(() => _messages.add((
            text: answer ?? 'No answer was returned.',
            user: false,
            sources: sources,
          )));
    } catch (_) {
      setState(() => _messages.add((
            text:
                'I could not reach the fleet assistant. Check your connection and try again.',
            user: false,
            sources: const [],
          )));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Fleet AI')),
      body: Column(children: [
        Expanded(
            child: _messages.isEmpty
                ? ListView(padding: const EdgeInsets.all(20), children: [
                    const Icon(Icons.auto_awesome, size: 42),
                    const SizedBox(height: 12),
                    const Text('Ask about your fleet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    for (final suggestion in _suggestions)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ActionChip(
                              label: Text(suggestion),
                              onPressed: () => _send(suggestion))),
                  ])
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Padding(
                            padding: EdgeInsets.all(12),
                            child: LinearProgressIndicator());
                      }
                      final message = _messages[index];
                      return Align(
                          alignment: message.user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 680),
                              decoration: BoxDecoration(
                                  color: message.user
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14)),
                              child: message.user
                                  ? Text(message.text)
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MarkdownBody(data: message.text),
                                        if (message.sources.isNotEmpty) ...[
                                          const Divider(),
                                          Text(
                                            'Retrieved sources: ${message.sources.join(' · ')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ],
                                    )));
                    })),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                              hintText:
                                  'Ask about vehicles, service, documents or costs',
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: _sending ? null : () => _send(),
                      icon: const Icon(Icons.send))
                ]))),
      ]));
}
