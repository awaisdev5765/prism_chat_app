# Prism AI Chat

A beautiful, open-source AI chat app built entirely with the [Prism](https://pub.dev/packages/prism_markdown) package family.

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter) ![License](https://img.shields.io/badge/License-MIT-green)

Works with **Ollama** (free, local), **OpenAI**, **Groq**, **DeepSeek**, **Together** and any OpenAI-compatible endpoint.

## Packages used

| Package | Purpose |
|---|---|
| [prism_ai](https://pub.dev/packages/prism_ai) | Streaming LLM client with typed events |
| [prism_markdown](https://pub.dev/packages/prism_markdown) | Live markdown rendering for AI responses |
| [prism_code_view](https://pub.dev/packages/prism_code_view) | Syntax-highlighted code blocks |
| [prism_palette](https://pub.dev/packages/prism_palette) | Dynamic theming from profile colors |

## Features

- Streaming AI responses rendered as live markdown
- Works with Ollama locally (free, no API key)
- Material 3 design with dark mode
- Settings screen for provider configuration
- Typing indicator, auto-scroll

## Getting started

1. Install [Ollama](https://ollama.ai) and pull a model: `ollama pull llama3`
2. Run the app: `flutter run`
3. Start chatting — no API key needed for local models

For cloud providers, tap Settings and enter your base URL + API key.

## License

MIT
