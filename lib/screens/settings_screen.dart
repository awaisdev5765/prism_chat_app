import 'package:flutter/material.dart';

import '../services/ai_service.dart';

enum Provider { ollama, openai, groq, deepseek }

extension ProviderInfo on Provider {
  String get label => switch (this) {
        Provider.ollama => 'Ollama (local)',
        Provider.openai => 'OpenAI',
        Provider.groq => 'Groq',
        Provider.deepseek => 'DeepSeek',
      };

  String get baseUrl => switch (this) {
        Provider.ollama => 'http://localhost:11434/v1',
        Provider.openai => 'https://api.openai.com/v1',
        Provider.groq => 'https://api.groq.com/openai/v1',
        Provider.deepseek => 'https://api.deepseek.com/v1',
      };

  String get defaultModel => switch (this) {
        Provider.ollama => 'llama3',
        Provider.openai => 'gpt-4o',
        Provider.groq => 'llama-3.3-70b-versatile',
        Provider.deepseek => 'deepseek-chat',
      };

  bool get needsApiKey => this != Provider.ollama;

  IconData get icon => switch (this) {
        Provider.ollama => Icons.computer,
        Provider.openai => Icons.open_in_new,
        Provider.groq => Icons.bolt,
        Provider.deepseek => Icons.search,
      };
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.service});
  final AiService service;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Provider _selected = Provider.ollama;
  late final _baseUrl = TextEditingController(text: widget.service.baseUrl);
  late final _apiKey = TextEditingController(text: widget.service.apiKey);
  late final _model = TextEditingController(text: widget.service.model);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Provider',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...Provider.values.map((p) {
            final selected = p == _selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _selected = p;
                  _baseUrl.text = p.baseUrl;
                  _model.text = p.defaultModel;
                }),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.06)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(p.icon,
                          size: 20,
                          color: selected
                              ? const Color(0xFF2563EB)
                              : theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        p.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle,
                            size: 20, color: const Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Configuration',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrl,
            decoration: InputDecoration(
              labelText: 'Base URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
