import 'package:prism_ai/prism_ai.dart';

/// Configures and manages the AI provider connection.
class AiService {
  OpenAiStreamClient? _client;

  String _baseUrl = 'http://localhost:11434/v1';
  String _apiKey = '';
  String _model = 'llama3';

  String get baseUrl => _baseUrl;
  String get model => _model;
  String get apiKey => _apiKey;

  void configure({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _model = model;
    _client = OpenAiStreamClient(
      baseUrl: baseUrl,
      apiKey: apiKey.isEmpty ? null : apiKey,
    );
  }

  void ensureInitialized() {
    _client ??= OpenAiStreamClient(baseUrl: _baseUrl);
  }

  Stream<Object> stream(String prompt) {
    ensureInitialized();
    return _client!.streamChat(
      [AiChatMessage.user(prompt)],
      model: _model,
    );
  }
}
