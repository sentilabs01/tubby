# 🚀 AI Agent Communication Platform MVP

A modern web-based platform that runs Claude Code and Gemini CLI in Docker containers with a real-time terminal interface. This project provides a unified environment for AI agent development and testing.

![Platform Preview](localhost_2025-07-20_03-44-56_5446.webp)

## ✨ Features

- **🔧 Multi-Terminal Interface**: Claude Code, Gemini CLI, and System terminals
- **⚡ Real-time Communication**: WebSocket-based command execution
- **📊 Container Monitoring**: Live status indicators for all containers
- **🎨 Modern UI**: Dark theme with responsive design
- **🐳 Docker Integration**: Containerized AI agents for easy deployment
- **🔒 Secure**: Environment-based API key management
- **📱 Responsive**: Works on desktop and mobile devices

## 🏗️ Architecture

The application consists of:

- **Main Application** (Port 3002): Flask backend with web interface
- **Claude Code Container** (Port 8001): Runs Claude Code CLI
- **Gemini CLI Container** (Port 8002): Runs Gemini CLI
- **Redis** (Port 6379): Session management and caching

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed on your system
2. **API Keys** for the AI services (optional for basic functionality)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sentilabs01/tubby.git
   cd tubby
   ```

2. **Set up Environment Variables (Optional)**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your API keys:
   - `ANTHROPIC_API_KEY` - For Claude Code functionality
   - `GOOGLE_API_KEY` - For Gemini CLI functionality
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY` - For database features
   - `OPENAI_API_KEY` - For OpenAI integration

3. **Run the Application**
   ```bash
   docker-compose up --build
   ```

4. **Access the Web Interface**
   
   Open your browser and navigate to: **http://localhost:3002**

## 🎯 Usage

### Terminal Commands

1. **Claude Code Terminal**: Execute Claude Code commands
   ```bash
   claude --help
   claude code "print('Hello World')"
   claude explain "What is Python?"
   ```

2. **Gemini CLI Terminal**: Execute Gemini CLI commands
   ```bash
   gemini --help
   gemini chat "Hello"
   gemini generate "Write a Python function"
   ```

3. **System Terminal**: Execute system commands (basic functionality)
   ```bash
   ls -la
   pwd
   whoami
   ```

### Container Status Indicators

The web interface shows real-time status indicators:
- 🟢 **Green**: Container is running and healthy
- 🔴 **Red**: Container is stopped or unhealthy
- 🟡 **Yellow**: Status unknown

## 🛠️ Development

### Project Structure
```
tubby/
├── backend/                 # Flask backend application
│   ├── app.py              # Main Flask application
│   ├── requirements.txt    # Python dependencies
│   └── templates/          # HTML templates
├── containers/             # Docker container configurations
│   ├── claude-code/        # Claude Code container
│   └── gemini-cli/         # Gemini CLI container
├── docker-compose.yml      # Docker Compose configuration
├── main.py                 # Entry point
├── terminal.py             # Terminal management
└── test_commands.py        # Test script
```

### Making Changes

1. **Backend**: Edit files in the `backend/` directory
2. **Frontend**: Edit `backend/templates/index.html`
3. **Containers**: Edit files in `containers/claude-code/` and `containers/gemini-cli/`

After making changes, rebuild the containers:
```bash
docker-compose down
docker-compose up --build
```

## 🧪 Testing

Run the included test script to verify everything is working:
```bash
python test_commands.py
```

## 🔧 Troubleshooting

### Common Issues

**Containers not starting**
```bash
# Check container logs
docker logs runmvpwithdockerandrequiredtools-ai-agent-platform-1
docker logs runmvpwithdockerandrequiredtools-claude-code-container-1
docker logs runmvpwithdockerandrequiredtools-gemini-cli-container-1
```

**Port conflicts**
If ports 3002, 8001, 8002, or 6379 are in use, modify the `docker-compose.yml` file to use different ports.

**Communication Timeout Issues**
If you see "Container communication error: Read timed out":
1. The containers have built-in timeout protection (45 seconds for CLI commands)
2. Complex AI commands may take longer to process
3. Try simpler commands first (e.g., `--help`, `--version`)
4. Check if the containers are healthy: `docker ps`

**API Key Issues**
If you don't have API keys, the containers will still run but CLI functionality may be limited.

## 🛑 Stopping the Application

```bash
docker-compose down
```

To remove all data (including Redis data):
```bash
docker-compose down -v
```

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

If you encounter any issues or have questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review the [GitHub issues](https://github.com/sentilabs01/tubby/issues)
3. Create a new issue with detailed information

## 🔮 Roadmap

- [ ] Add support for more AI agents
- [ ] Implement user authentication
- [ ] Add persistent storage for conversations
- [ ] Create mobile app
- [ ] Add plugin system for custom integrations
- [ ] Implement advanced monitoring and analytics

---

**Made with ❤️ by the Tubby Team** 