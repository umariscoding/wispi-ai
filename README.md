# Wispi AI

A stealth macOS AI assistant that runs as a floating panel, powered by GPT-4o.

## Features

- Floating, click-through panel that stays on top of all windows
- Text chat with GPT-4o
- Screenshot capture and analysis (vision)
- Audio recording and transcription via Whisper
- Global hotkey support

## Setup

1. Clone the repo
2. Copy the env template and add your key:
   ```bash
   cp .env.example .env
   # edit .env and set your OPENAI_API_KEY
   ```
3. Build and run:
   ```bash
   ./run.sh
   ```

## Configuration

Edit `config.sh` to change the app name, bundle ID, or display name:

```bash
APP_NAME="safari"        # binary/bundle name
BUNDLE_ID="local.safari.app"
DISPLAY_NAME="safari"    # shown in the window title
```

## Requirements

- macOS 12+
- Swift (comes with Xcode or Xcode Command Line Tools)
- An OpenAI API key

## Project Structure

```
Sources/
├── Config/       # App constants and theme
├── Controllers/  # Chat logic
├── Core/         # App delegate, hotkeys, panel window
├── Models/       # Data models
├── Services/     # OpenAI client, audio recorder, screen capture
└── Views/        # UI components
build.sh          # Compiles and bundles the app
run.sh            # Builds (if needed) and launches with env vars
config.sh         # App name / bundle ID config
```

## Environment Variables

| Variable | Description |
|---|---|
| `OPENAI_API_KEY` | Your OpenAI API key (required) |
