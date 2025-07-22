# Developer Instructions: Tubby AI UX/UI Buildout (ux-ui-buildout branch)

## 1. Introduction

This document provides comprehensive developer instructions for the UX/UI buildout of the Tubby AI application, specifically focusing on the `ux-ui-buildout` branch. The primary goal is to integrate various AI coding assistants (Google Code Assist, Gemini CLI, Claude Code, and OpenCode) into a unified terminal interface, while maintaining Model Context Protocol (MCP) communication and ensuring a robust, user-friendly experience with numbered terminals.

## 2. Current Application Architecture Overview

The Tubby AI application is structured as a full-stack application with a Python Flask backend and a React-based frontend. It leverages Docker for containerization and includes existing integrations for authentication (Google OAuth) and payment processing (Stripe). The application also incorporates a custom Model Context Protocol (MCP) implementation for inter-agent communication.

### 2.1 Repository Structure

The `ux-ui-buildout` branch of the Tubby AI repository has the following key directories and files:

- `.github/workflows`: Contains GitHub Actions workflows for CI/CD.
- `backend/`: Houses the Python Flask backend application, including services and API endpoints.
- `components/`: Stores reusable React components for the frontend.
- `containers/`: Contains Docker configurations for various services, including `gemini-cli` and `mcp-router`.
- `database/`: Includes database schema and migration scripts.
- `public/`: Contains static assets for the frontend.
- `scripts/`: Holds utility scripts for development and deployment.
- `src/`: The main source directory for the React frontend application.
- `utils/`: Contains utility functions, notably `smartParser.js` for MCP communication.
- `.env.example`: A template for environment variables.
- `API_SETUP_GUIDE.md`, `AUTH_BUG_FIX_SUMMARY.md`, `AUTH_SETUP_GUIDE.md`: Documentation related to API and authentication setup.

### 2.2 Technology Stack

The application is built using a diverse technology stack:

- **Backend**: Python (Flask)
- **Frontend**: JavaScript (React)
- **Database**: PLpgSQL
- **Containerization**: Docker
- **Communication Protocol**: Model Context Protocol (MCP)

### 2.3 Existing Features

- **Authentication**: Implemented with Google OAuth.
- **Payment Processing**: Integrated with Stripe.
- **MCP Communication**: Facilitates communication between AI agents.
- **Containerized Environment**: Utilizes Docker for consistent development and deployment.

## 3. Integration of AI Coding Assistants

The core of this buildout involves integrating Google Code Assist, Gemini CLI, Claude Code, and OpenCode into the Tubby AI terminal interface. The terminals must remain agnostic until a specific program is chosen, and then dynamically load the chosen program's environment and commands.

### 3.1 Google Code Assist

Google Code Assist is an AI-powered coding assistant that provides intelligent code suggestions, completions, and refactoring capabilities. It is closely related to the Gemini CLI.

**Integration Points:**
- **UI**: The UI should provide a clear option to select Google Code Assist for a given terminal.
- **Backend**: The backend might need to handle API calls to Google Code Assist services, potentially through the Gemini CLI.
- **Terminal Interaction**: Commands and responses from Google Code Assist should be displayed and managed within the designated terminal.

### 3.2 Google Gemini CLI

The Gemini CLI is an open-source command-line AI workflow tool that connects to various tools and understands code. It allows direct interaction with Gemini models from the terminal.

**Installation (as per screenshot):**
```bash
npm install -g @google/gemini-cli
```

**Integration Points:**
- **Containerization**: The existing `containers/gemini-cli/` directory suggests that a Docker container is already set up for Gemini CLI. Ensure this container is functional and can be dynamically launched/managed.
- **Terminal Agnosticism**: When a user selects Gemini CLI for a terminal, the system should load the Gemini CLI environment. This involves ensuring the `gemini-cli` executable is available within the terminal's context.
- **Command Execution**: The UI should allow users to input commands that are then executed by the Gemini CLI instance associated with that terminal. The output should be displayed back in the terminal.
- **MCP Communication**: Gemini CLI should be able to participate in MCP communication, sending and receiving messages to other terminals and agents.

### 3.3 Anthropic Claude Code

Claude Code is an agentic coding tool that integrates with the terminal, understands codebases, and assists with coding tasks. It is installed via npm.

**Installation (as per user request):**
```bash
npm install -g @anthropic-ai/claude-code
```

**Integration Points:**
- **Terminal Agnosticism**: Similar to Gemini CLI, the system needs to dynamically load the Claude Code environment when selected. This will likely involve ensuring the `claude-code` executable is accessible.
- **Command Execution**: The UI should facilitate sending commands to the Claude Code instance and displaying its responses.
- **MCP Communication**: Claude Code instances should also be able to communicate via the MCP protocol.

### 3.4 OpenCode AI

OpenCode is an open-source AI coding agent built for the terminal, offering a native Terminal User Interface (TUI) and support for various LLM providers.

**Installation (as per user request):**
```bash
npm install -g opencode-ai
```

**Integration Points:**
- **Terminal Agnosticism**: The system must support loading the OpenCode environment dynamically.
- **Command Execution**: The UI should allow command input and display output from OpenCode.
- **MCP Communication**: OpenCode instances should integrate with the MCP protocol for inter-agent communication.

## 4. Terminal Management and UI Requirements

The UI/UX for the terminals is critical for a seamless developer experience. The screenshots provided illustrate key requirements:

### 4.1 Numbered Terminals

Terminals must be clearly numbered (e.g., "Gemini CLI Terminal 1", "Gemini CLI Terminal 2") to facilitate tracking and communication across different AI providers and instances. This numbering should be dynamic and reflect the active terminals.

### 4.2 Agnostic Terminal State

Initially, terminals should be generic. The specific AI coding assistant (Gemini CLI, Claude Code, OpenCode) should only be activated and its environment loaded once the user explicitly chooses it for that terminal. This implies a mechanism for dynamically switching the terminal's underlying environment or context.

### 4.3 MCP Protocol Communication

The Model Context Protocol (MCP) is central to inter-terminal and inter-agent communication. The UI explicitly shows `mcp broadcast message` commands, indicating that the system must support:

- **Sending MCP Messages**: Ability to send messages from one terminal to another, or broadcast messages to all active terminals.
- **Receiving MCP Messages**: Displaying incoming MCP messages within the relevant terminals.
- **Routing Commands**: The `>>terminalX command` syntax suggests a routing mechanism for commands between terminals.
- **Collaborative Tasks**: The `collab terminalX task` syntax indicates support for collaborative workflows involving multiple AI agents.

### 4.4 Quick Actions and Prompt Examples

The "Quick Actions" and "Prompt Examples" sections are crucial for usability. Developers should be able to:

- **Send Messages/Commands**: Easily send messages or route commands to other terminals.
- **Collaborate**: Initiate collaborative tasks with other AI agents.
- **Share/Get Data**: Mechanisms for sharing and retrieving data between terminals/agents.
- **Access Prompt Examples**: Quickly access and use pre-defined prompts for various AI coding assistants.

### 4.5 Connection Status Indicators

Clear visual indicators for connection status ("Connected", "Cross-Terminal Active") and the status of individual AI CLI instances ("Gemini CLI 1 Unknown", "Gemini CLI 2 Unknown") are essential for user feedback.

## 5. Developer Implementation Guidelines

### 5.1 Frontend (React)

- **Terminal Component**: Develop a reusable React component for each terminal instance. This component should manage its own state, input, output, and display of quick actions.
- **Dynamic Loading**: Implement a mechanism to dynamically load the specific AI coding assistant's environment/commands based on user selection. This might involve conditional rendering or dynamic imports.
- **State Management**: Use a robust state management solution (e.g., Redux, React Context) to manage the state of multiple terminals, their active AI assistants, and inter-terminal communication.
- **UI for MCP**: Design UI elements that clearly represent MCP communication, including message routing, broadcasting, and collaborative task initiation.
- **Input Handling**: Implement intelligent input handling that can differentiate between regular commands, cross-terminal commands, and MCP commands.

### 5.2 Backend (Python Flask)

- **API Endpoints**: Create API endpoints to handle requests from the frontend for:
    - Launching/managing AI coding assistant instances (e.g., starting a Gemini CLI process).
    - Executing commands within specific AI assistant environments.
    - Handling MCP message routing and broadcasting.
- **Process Management**: Implement robust process management for each AI coding assistant. This might involve using Python's `subprocess` module to run CLI commands and capture their output.
- **MCP Protocol Implementation**: Ensure the backend's MCP implementation (`utils/smartParser.js` and related Python code) is capable of handling the required communication patterns (point-to-point, broadcast, collaborative).
- **Security**: Implement proper security measures for executing external commands and handling inter-process communication.

### 5.3 Docker and Containerization

- **AI Assistant Containers**: Ensure that Docker containers for Gemini CLI, Claude Code, and OpenCode are properly configured and can be dynamically started and stopped by the backend.
- **Environment Variables**: Manage environment variables (e.g., API keys for AI services) securely within the Docker environment.
- **Networking**: Configure Docker networking to allow seamless communication between the backend, frontend, and the AI assistant containers.

## 6. Testing

Thorough testing is crucial for this buildout:

- **Unit Tests**: Write unit tests for individual React components, backend API endpoints, and utility functions.
- **Integration Tests**: Test the integration between the frontend and backend, and between the backend and the AI coding assistant containers.
- **End-to-End Tests**: Develop end-to-end tests to simulate user interactions with the terminals, including selecting AI assistants, executing commands, and verifying MCP communication.
- **Performance Testing**: Assess the performance of the system, especially when multiple AI assistants are active and communicating.

## 7. Future Considerations

- **Extensibility**: Design the system to easily integrate new AI coding assistants in the future.
- **Customization**: Allow users to customize terminal appearance, quick actions, and prompt examples.
- **Persistent Sessions**: Implement functionality to save and restore terminal sessions.
- **Error Handling and Logging**: Enhance error handling and logging for better debugging and user feedback.

## 8. References

- [1] Google Code Assist: https://codeassist.google/
- [2] Google Gemini CLI GitHub: https://github.com/google-gemini/gemini-cli
- [3] Anthropic Claude Code: https://www.anthropic.com/claude-code
- [4] OpenCode AI: https://opencode.ai/
- [5] Model Context Protocol: https://modelcontextprotocol.io/


