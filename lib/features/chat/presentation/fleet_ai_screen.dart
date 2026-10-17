import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_drawer.dart';

class FleetAiScreen extends ConsumerStatefulWidget {
  const FleetAiScreen({super.key});

  @override
  ConsumerState<FleetAiScreen> createState() => _FleetAiScreenState();
}

class _FleetAiScreenState extends ConsumerState<FleetAiScreen> {
  static const _storage = FlutterSecureStorage();
  static const _backendUrl = String.fromEnvironment(
    'FLEET_BACKEND_URL',
    defaultValue: String.fromEnvironment(
      'OCR_SERVICE_URL',
      defaultValue: 'https://fleetpulse-ocr.onrender.com',
    ),
  );
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<({String text, bool user, List<String> sources})> _messages = [];
  bool _sending = false;
  bool _historyLoaded = false;
  String? _historyUserId;
  static const _suggestions = [
    'Which buses are overdue for service?',
    'Which fitness certificates expire in 30 days?',
    'How much did we spend in the last 30 days?',
  ];

  @override
  void initState() {
    super.initState();
    _restoreHistory();
  }

  Future<void> _restoreHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _historyLoaded = true);
      return;
    }
    _historyUserId = userId;
    try {
      final saved = await _storage.read(key: 'fleet_ai_history_$userId');
      if (!mounted || saved == null) return;
      final rows = jsonDecode(saved);
      if (rows is! List) return;
      final restored = <({String text, bool user, List<String> sources})>[];
      for (final row in rows.take(50)) {
        if (row is! Map || row['text'] is! String || row['user'] is! bool) {
          continue;
        }
        restored.add((
          text: (row['text'] as String).substring(
              0, (row['text'] as String).length.clamp(0, 4000).toInt()),
          user: row['user'] as bool,
          sources: (row['sources'] is List ? row['sources'] as List : const [])
              .whereType<String>()
              .take(8)
              .toList(),
        ));
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Chat still works when secure storage is unavailable on a platform.
    } finally {
      if (mounted) setState(() => _historyLoaded = true);
    }
  }

  Future<void> _saveHistory() async {
    final userId =
        _historyUserId ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _historyUserId = userId;
    try {
      final rows = _messages.length <= 50
          ? _messages
          : _messages.sublist(_messages.length - 50);
      await _storage.write(
        key: 'fleet_ai_history_$userId',
        value: jsonEncode(rows
            .map((message) => {
                  'text': message.text,
                  'user': message.user,
                  'sources': message.sources,
                })
            .toList()),
      );
    } catch (_) {
      // Do not fail a chat request because local persistence failed.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _sending || !_historyLoaded) return;
    _controller.clear();
    final history = _messages
        .where((message) =>
            !message.text.startsWith('Fleet AI took too long') &&
            !message.text.startsWith('Fleet AI could not connect') &&
            !message.text.startsWith('Fleet AI backend error') &&
            !message.text.startsWith('Fleet AI request failed'))
        .toList(growable: false);
    setState(() {
      _messages.add((text: text, user: true, sources: const []));
      _sending = true;
    });
    await _saveHistory();
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
            body: jsonEncode({
              'message': text,
              'history': history
                  .skip(history.length > 12 ? history.length - 12 : 0)
                  .take(12)
                  .map((message) => {
                        'role': message.user ? 'user' : 'assistant',
                        'content': message.text,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _safeBackendDetail(response.body);
        throw _FleetAssistantException(
          _httpErrorMessage(response.statusCode, detail),
        );
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
      await _saveHistory();
    } on _FleetAssistantException catch (error) {
      setState(() => _messages.add((
            text: error.message,
            user: false,
            sources: const [],
          )));
      await _saveHistory();
    } on TimeoutException {
      setState(() => _messages.add((
            text:
                'Fleet AI took too long to respond. Please retry in a moment.',
            user: false,
            sources: const [],
          )));
      await _saveHistory();
    } on SocketException {
      setState(() => _messages.add((
            text:
                'Fleet AI could not connect to the Render service. Check your internet connection and retry.',
            user: false,
            sources: const [],
          )));
      await _saveHistory();
    } on FormatException {
      setState(() => _messages.add((
            text:
                'Fleet AI returned an unreadable response. Please retry; if it continues, the backend response needs investigation.',
            user: false,
            sources: const [],
          )));
      await _saveHistory();
    } catch (_) {
      setState(() => _messages.add((
            text:
                'Fleet AI request failed before a usable answer arrived. Please retry.',
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

  String _safeBackendDetail(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic> && payload['detail'] is String) {
        return (payload['detail'] as String).trim();
      }
    } catch (_) {
      // Do not put unstructured backend response bodies into the chat.
    }
    return '';
  }

  String _httpErrorMessage(int status, String detail) {
    if (status == 401) {
      return 'Your sign-in session was rejected by Fleet AI. Sign out and sign in again, then retry.';
    }
    if (status == 403) {
      return detail.isNotEmpty
          ? detail
          : 'Your fleet profile is not active for Fleet AI. Ask the company admin to check your account.';
    }
    if (status == 503) {
      return detail.isNotEmpty
          ? detail
          : 'Fleet AI is temporarily unavailable because a backend integration is not configured.';
    }
    if (status == 502 || status >= 500) {
      if (detail.isNotEmpty && detail != 'Internal Server Error') {
        return 'Fleet AI backend error (HTTP $status): $detail';
      }
      return 'Fleet AI reached the backend, but a database or AI provider request failed (HTTP $status). Please retry.';
    }
    return detail.isNotEmpty
        ? detail
        : 'Fleet AI rejected the request (HTTP $status). Please check the message and retry.';
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
                      onPressed:
                          _sending || !_historyLoaded ? null : () => _send(),
                      icon: const Icon(Icons.send))
                ]))),
      ]));
}

class _FleetAssistantException implements Exception {
  final String message;

  const _FleetAssistantException(this.message);
}
