# 🧠 OwnAI

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue?style=flat&logo=apple" alt="Platform: macOS"/>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat&logo=swift" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/SwiftUI-3.0-blue?style=flat&logo=swift" alt="SwiftUI 3.0"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"/>
</p>

<p align="center">
  <i>A native macOS interface for your local Ollama instance. Run AI models on your hardware with a beautiful, native interface.</i>
</p>

<p align="center">
  <img src="https://user-images.githubusercontent.com/TODO_YOUR_GITHUB_USERNAME/OwnAI/main/screenshots/app_preview.png" width="720" alt="OwnAI Preview"/>
</p>

## ✨ Features

OwnAI brings a clean, native macOS interface to [Ollama](https://ollama.ai) instances running on your machine or local network:

- 🔌 **Local Connection Management**: Connect to any Ollama instance (local or on your network)
- 🤖 **Model Selection**: Choose from your installed Ollama models
- 💬 **Chat Interface**: Natural conversation UI with streaming responses
- 📊 **Stats Monitoring**: Track generation speed and token usage in verbose mode
- 📝 **Formatting Support**: Code snippets, terminal output, and more
- 💾 **Session Management**: Save and load conversations

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- [Ollama](https://ollama.ai) installed and running on your Mac or accessible on your network
- Xcode 15+ (for building from source)

### Installation

#### Option 1: Download Release
1. Download the latest release from the [Releases](https://github.com/arvindjuneja/OwnAI/releases) page
2. Move OwnAI to your Applications folder
3. Launch and enjoy!

#### Option 2: Build from Source
1. Clone this repository
   ```bash
   git clone https://github.com/arvindjuneja/OwnAI.git
   cd OwnAI
   ```
2. Open the project in Xcode
   ```bash
   open ownai/ownai.xcodeproj
   ```
3. Build the project (⌘+B) and run (⌘+R)

## 🔧 Usage

1. **Start Ollama**: Ensure your Ollama server is running (default: `http://localhost:11434`)
2. **Launch OwnAI**: Open the app
3. **Configure Connection**: Click the settings icon and enter your Ollama server details
4. **Select a Model**: Choose from your available models
5. **Start Chatting**: Begin your conversation with the selected model

## 🛣️ Roadmap

OwnAI is under active development. Upcoming features include:

- [ ] Local network scanning for Ollama instances
- [ ] System prompt customization
- [ ] Model management (pull/remove models directly from UI)
- [ ] Conversation search and organization
- [ ] Advanced formatting options for responses
- [ ] Global keyboard shortcuts

View our complete [development roadmap](roadmap.md) for more details on planned features and progress.

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests

Please check our [contribution guidelines](CONTRIBUTING.md) before getting started.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai) for making local LLMs accessible
- All contributors and supporters of the project

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/arvindjuneja">Arvind Juneja</a>
</p> 