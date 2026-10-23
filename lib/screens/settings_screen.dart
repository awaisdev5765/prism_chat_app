import 'package:flutter/material.dart';

import '../services/ai_service.dart';

/// Settings screen for configuring the AI provider.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.service});

  final AiService service;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _baseUrl = TextEditingController(text: widget.service.baseUrl);
  late final _apiKey = TextEditingController(text: widget.service.apiKey);
  late final _model = TextEditingController(text: widget.service.model);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'http://localhost:11434/v1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKey,
            decoration: const InputDecoration(
              labelText: 'API Key (optional)',
              hintText: 'Leave empty for Ollama',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'llama3, gpt-4o, claude-3-sonnet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              widget.service.configure(
                baseUrl: _baseUrl.text.trim(),
                apiKey: _apiKey.text.trim(),
                model: _model.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
