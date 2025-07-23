# Tubby AI - MCP Inter-Terminal Communication Test Commands

## 🚀 Quick Start - Test These Commands!

### 1. **Send Messages Between Terminals**
```bash
# In Terminal 1, send a message to Terminal 2
@terminal2 Hello from Terminal 1!

# In Terminal 2, send a message to Terminal 3  
@terminal3 Can you help me with a system command?

# In Terminal 3, send a message to Terminal 1
@terminal1 I'm ready to help with system tasks!
```

### 2. **Route Commands Between Terminals**
```bash
# In Terminal 1, route a command to Terminal 3 (System)
>>terminal3 dir

# In Terminal 2, route a Gemini command to Terminal 1
>>terminal1 gemini --help

# In Terminal 3, route a command to Terminal 2
>>terminal2 gemini --prompt "What is AI?"
```

### 3. **MCP Function Calls**
```bash
# Broadcast a message to all terminals
mcp broadcast "Important: System maintenance in 5 minutes"

# Share data between terminals
mcp set_shared_data {"project": "tubby", "status": "active"}

# Retrieve shared data
mcp get_shared_data
```

### 4. **Collaboration Requests**
```bash
# Request collaboration from another terminal
collab terminal2 "Can you help me write a Python function?"

# Request system help
collab terminal3 "I need to check disk space usage"

# Request AI assistance
collab terminal1 "Help me understand machine learning concepts"
```

## 🎯 **Test Scenarios**

### **Scenario 1: Multi-Terminal Workflow**
1. **Terminal 1**: `@terminal2 Starting our collaboration project`
2. **Terminal 2**: `@terminal1 Ready to help! What should we build?`
3. **Terminal 1**: `>>terminal3 mkdir myproject`
4. **Terminal 3**: `cd myproject && dir`
5. **Terminal 1**: `mcp set_shared_data {"project": "myproject", "status": "created"}`
6. **Terminal 2**: `mcp get_shared_data`

### **Scenario 2: AI + System Collaboration**
1. **Terminal 1**: `gemini --prompt "Write a Python script to list files"`
2. **Terminal 1**: `>>terminal3 python script.py`
3. **Terminal 3**: `dir`
4. **Terminal 1**: `@terminal2 The script worked perfectly!`

### **Scenario 3: Broadcast Communication**
1. **Terminal 1**: `mcp broadcast "Starting development session"`
2. **Terminal 2**: `@terminal1 I'm ready for AI tasks`
3. **Terminal 3**: `@terminal1 System terminal ready for commands`
4. **Terminal 1**: `mcp broadcast "All terminals confirmed - let's begin!"`

## 🔧 **Advanced MCP Features**

### **Shared Data Management**
```bash
# Set complex data
mcp set_shared_data {"users": ["alice", "bob"], "tasks": ["debug", "test"], "priority": "high"}

# Get and use shared data
mcp get_shared_data
```

### **Cross-Terminal Command Chaining**
```bash
# Terminal 1: Generate code
gemini --prompt "Create a simple web server"

# Terminal 1: Route to system for execution
>>terminal3 python server.py

# Terminal 1: Notify other terminals
@terminal2 Server code generated and running!
```

## 🎉 **What You Can Do Now**

✅ **Real-time messaging** between terminals  
✅ **Command routing** to specific terminals  
✅ **Data sharing** across all terminals  
✅ **Broadcast notifications** to all terminals  
✅ **Collaboration requests** between terminals  
✅ **MCP function calls** for advanced features  

## 💡 **Pro Tips**

1. **Use @ for quick messages** - Perfect for status updates
2. **Use >> for command routing** - Great for delegating tasks
3. **Use mcp broadcast** - Ideal for important announcements
4. **Use collab for teamwork** - Perfect for requesting help
5. **Use shared data** - Great for maintaining state across terminals

Try these commands and see the magic of MCP inter-terminal communication! 🚀 