# Contributing to Tubby AI

Thank you for your interest in contributing to Tubby AI! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### 1. **Fork the Repository**
Click the "Fork" button on the GitHub repository page to create your own copy.

### 2. **Clone Your Fork**
```bash
git clone https://github.com/YOUR_USERNAME/tubby.git
cd tubby
```

### 3. **Set Up Development Environment**
```bash
# Install Python dependencies
pip install -r backend/requirements.txt

# Install Node.js dependencies
npm install

# Start development servers
python backend/app.py  # Terminal 1
npm run dev           # Terminal 2
```

### 4. **Create a Feature Branch**
```bash
git checkout -b feature/amazing-feature
```

### 5. **Make Your Changes**
- Follow the coding standards below
- Add tests for new features
- Update documentation as needed

### 6. **Test Your Changes**
```bash
# Test MCP communication
@terminal2 Hello from development!

# Test command routing
>>terminal3 dir

# Test MCP functions
mcp broadcast "Testing new feature"
```

### 7. **Commit Your Changes**
```bash
git add .
git commit -m "feat: add amazing new feature"
```

### 8. **Push to Your Fork**
```bash
git push origin feature/amazing-feature
```

### 9. **Create a Pull Request**
Go to your fork on GitHub and click "New Pull Request".

## 📋 Development Guidelines

### **Code Style**

**Python (Backend)**
- Follow PEP 8 style guide
- Use type hints where appropriate
- Add docstrings to functions and classes
- Maximum line length: 88 characters (Black formatter)

**JavaScript/React (Frontend)**
- Use ES6+ features
- Follow React best practices
- Use functional components with hooks
- Use Prettier for formatting

### **MCP Communication Patterns**

When adding new MCP features:

1. **Update `utils/smartParser.js`** with new patterns
2. **Add handlers in `App.jsx`** for new MCP types
3. **Update backend in `backend/app.py`** for server-side logic
4. **Add tests** for new functionality
5. **Update documentation** in README.md and mcp_test_commands.md

### **Testing**

**Frontend Tests**
```bash
npm test
npm run test:coverage
```

**Backend Tests**
```bash
cd backend
python -m pytest
```

**Integration Tests**
```bash
# Test MCP communication
@terminal2 Test message
>>terminal3 dir
mcp broadcast "Integration test"
```

### **Documentation**

- Update README.md for user-facing changes
- Update mcp_test_commands.md for new MCP features
- Add inline comments for complex logic
- Update API documentation if endpoints change

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment**: OS, Python version, Node.js version
2. **Steps to reproduce**: Clear, step-by-step instructions
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happens
5. **Screenshots**: If applicable
6. **Console logs**: Any error messages

## 💡 Feature Requests

When suggesting features:

1. **Clear description**: What the feature should do
2. **Use case**: Why this feature is needed
3. **Implementation ideas**: How it might be implemented
4. **Priority**: High/Medium/Low

## 🏗️ Project Structure

```
tubby/
├── App.jsx                 # Main React application
├── backend/                # Flask backend
├── components/             # React components
├── containers/             # Docker configurations
├── utils/                  # Utility functions
├── .github/workflows/      # CI/CD pipelines
└── docs/                   # Documentation
```

## 🔧 Development Setup

### **Prerequisites**
- Python 3.11+
- Node.js 18+
- Docker and Docker Compose
- Git

### **Environment Variables**
Create a `.env` file:
```bash
ANTHROPIC_API_KEY=your_key_here
GOOGLE_API_KEY=your_key_here
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
```

### **Running Locally**
```bash
# Backend (Terminal 1)
python backend/app.py

# Frontend (Terminal 2)
npm run dev

# Docker (Optional)
docker-compose up --build
```

## 📝 Commit Message Convention

Use conventional commit messages:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

Example:
```bash
git commit -m "feat: add voice-to-voice communication between agents"
```

## 🎯 Areas for Contribution

### **High Priority**
- [ ] User authentication system
- [ ] Persistent conversation storage
- [ ] Advanced MCP function library
- [ ] Mobile app development

### **Medium Priority**
- [ ] Plugin system
- [ ] Advanced analytics
- [ ] Voice-to-voice communication
- [ ] AI agent marketplace

### **Low Priority**
- [ ] Additional UI themes
- [ ] Keyboard shortcuts
- [ ] Export/import functionality
- [ ] Performance optimizations

## 🚀 Getting Help

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check README.md and mcp_test_commands.md

## 📄 License

By contributing to Tubby, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Tubby AI! 🧠** 