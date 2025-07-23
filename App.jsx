import { useState, useEffect, useRef } from 'react'
import { Routes, Route } from 'react-router-dom'
import { Button } from './components/ui/button.jsx'
import { Input } from './components/ui/input.jsx'
import { Card, CardContent, CardHeader, CardTitle } from './components/ui/card.jsx'
import { Badge } from './components/ui/badge.jsx'
import { Terminal, Play, Square, Cpu, Settings, User, Crown, Paperclip } from 'lucide-react'
import io from 'socket.io-client'
import { parseInput } from './utils/smartParser.js'
import SettingsPanel from './components/SettingsPanel.jsx'
import html2canvas from 'html2canvas'
import { AuthProvider, useAuth } from './src/components/AuthManager.jsx'
import AuthContainer from './src/components/AuthContainer.jsx'
import UserProfile from './src/components/UserProfile.jsx'
import SubscriptionPlans from './src/components/SubscriptionPlans.jsx'
import AuthCallback from './src/components/AuthCallback.jsx'

function MainApp() {
  const { currentUser, isAuthenticated, loading } = useAuth()
  const [socket, setSocket] = useState(null)
  const [connected, setConnected] = useState(false)
  const [containerStatus, setContainerStatus] = useState({})
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [showSubscription, setShowSubscription] = useState(false)
  const [terminalLayouts, setTerminalLayouts] = useState({
    terminal1: { x: 0, y: 0, width: 400, height: 600, isDragging: false, isResizing: false },
    terminal2: { x: 420, y: 0, width: 400, height: 600, isDragging: false, isResizing: false },
    terminal3: { x: 840, y: 0, width: 400, height: 600, isDragging: false, isResizing: false }
  })
  const [terminals, setTerminals] = useState({
    terminal1: { history: [], input: '', commandHistory: [], historyIndex: -1 }, // Gemini CLI Terminal 1
    terminal2: { history: [], input: '', commandHistory: [], historyIndex: -1 }, // Gemini CLI Terminal 2
    terminal3: { history: [], input: '', commandHistory: [], historyIndex: -1 }  // System Terminal
  })
  
  const [dynamicTerminals, setDynamicTerminals] = useState({})
  const [nextTerminalId, setNextTerminalId] = useState(4)
  const [sharedClipboard, setSharedClipboard] = useState('')
  const [terminalMessages, setTerminalMessages] = useState([])
  const [attachmentMenus, setAttachmentMenus] = useState({
    terminal1: false,
    terminal2: false,
    terminal3: false
  })

  // Add prompt examples for each terminal
  const [promptExamples] = useState({
    terminal1: [
      { text: "Help me write a React component", command: 'gemini --prompt "Create a React component for a todo list"', category: "Development" },
      { text: "Debug this JavaScript code", command: 'gemini --prompt "Debug this code: function add(a,b) { return a + b }"', category: "Debugging" },
      { text: "Explain a concept", command: 'gemini --prompt "Explain async/await in JavaScript"', category: "Learning" },
      { text: "Send message to Terminal 2", command: '@terminal2 Hello from Terminal 1!', category: "Cross-Terminal" },
      { text: "Route command to System Terminal", command: '>>terminal3 ls -la', category: "Cross-Terminal" }
    ],
    terminal2: [
      { text: "Generate API documentation", command: 'gemini --prompt "Generate OpenAPI spec for a user management API"', category: "Documentation" },
      { text: "Optimize database query", command: 'gemini --prompt "Optimize this SQL query: SELECT * FROM users WHERE active = 1"', category: "Database" },
      { text: "Create test cases", command: 'gemini --prompt "Write unit tests for a login function"', category: "Testing" },
      { text: "Collaborate with Terminal 1", command: 'collab terminal1 "Help me review this code"', category: "Cross-Terminal" },
      { text: "Broadcast to all terminals", command: 'mcp broadcast "Starting deployment process"', category: "Cross-Terminal" }
    ],
    terminal3: [
      { text: "List files in current directory", command: 'dir', category: "File System" },
      { text: "Check system status", command: 'systeminfo', category: "System" },
      { text: "Run a Python script", command: 'python script.py', category: "Execution" },
      { text: "Send command to Gemini Terminal", command: '>>terminal1 gemini --prompt "What is the weather like?"', category: "Cross-Terminal" },
      { text: "Share data with other terminals", command: 'mcp set_shared_data {"status": "ready"}', category: "Cross-Terminal" }
    ]
  })

  // Add cross-terminal quick actions
  const [quickActions] = useState([
    { label: "📤 Send to Terminal 2", action: (terminalId) => `@terminal2 Message from ${terminalId}` },
    { label: "🔄 Route to System", action: (terminalId) => `>>terminal3 dir` },
    { label: "🤝 Collaborate", action: (terminalId) => `collab ${terminalId === 'terminal1' ? 'terminal2' : 'terminal1'} Let's work together` },
    { label: "📢 Broadcast", action: () => `broadcast "Important update from terminal"` },
    { label: "💾 Share Data", action: () => `share {"timestamp": "${new Date().toISOString()}"}` },
    { label: "📖 Get Shared Data", action: () => `get shared data` }
  ])
  
  const terminalRefs = {
    terminal1: useRef(null),
    terminal2: useRef(null),
    terminal3: useRef(null)
  }

  useEffect(() => {
    // Initialize socket connection
    const newSocket = io(import.meta.env.VITE_API_URL, {
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
      timeout: 20000,
      forceNew: false
    })
    setSocket(newSocket)

    newSocket.on('connect', () => {
      setConnected(true)
      console.log('Connected to server')
    })

    newSocket.on('disconnect', () => {
      setConnected(false)
      console.log('Disconnected from server')
    })

    newSocket.on('connect_error', (error) => {
      console.log('Connection error:', error)
      setConnected(false)
    })

    newSocket.on('reconnect', (attemptNumber) => {
      console.log('Reconnected after', attemptNumber, 'attempts')
      setConnected(true)
    })

    newSocket.on('reconnect_error', (error) => {
      console.log('Reconnection error:', error)
    })

    newSocket.on('reconnect_failed', () => {
      console.log('Reconnection failed')
      setConnected(false)
    })

    newSocket.on('status', (data) => {
      console.log('Status:', data.message)
    })

    newSocket.on('command_output', (data) => {
      console.log('Received command output:', data)
      
      // Handle both old and new data formats
      let terminalId = data.terminal_id || data.terminal || 'terminal1'
      
      // Map backend terminal names to frontend terminal IDs
      const terminalMapping = {
        'system': 'terminal3',
        'gemini-1': 'terminal1', 
        'gemini-2': 'terminal2',
      }
      
      // If it's a backend terminal name, map it to frontend ID
      if (terminalMapping[terminalId]) {
        terminalId = terminalMapping[terminalId]
      }
      
      console.log('Mapped terminal ID:', terminalId, 'from:', data.terminal)
      console.log('Command data:', {
        command: data.command,
        output: data.output,
        error: data.error,
        type: data.type
      })
    
      // Ensure the terminal exists in state
      if (!terminals[terminalId]) {
        console.warn(`Terminal ${terminalId} not found in state`)
        return
      }
      
      setTerminals(prev => ({
        ...prev,
        [terminalId]: {
          ...prev[terminalId],
          history: [...prev[terminalId].history, {
            command: data.command || terminals[terminalId].input,
            output: data.output,
            error: data.error,
            type: data.type,
            timestamp: new Date().toLocaleTimeString()
          }]
        }
      }))
    })

    newSocket.on('container_status', (data) => {
      setContainerStatus(data)
    })

    newSocket.on('mcp_function_result', (data) => {
      const { function: func, result, source_terminal } = data
      setTerminals(prev => ({
        ...prev,
        [source_terminal]: {
          ...prev[source_terminal],
          history: [...prev[source_terminal].history, {
            command: '',
            output: `🔧 MCP ${func}: ${result}`,
            type: 'mcp',
            timestamp: new Date().toLocaleTimeString()
          }]
        }
      }))
    })

    newSocket.on('mcp_broadcast', (data) => {
      const { message, source_terminal } = data
      // Add broadcast message to all terminals
      Object.keys(terminals).forEach(terminalId => {
        if (terminalId !== source_terminal) {
          setTerminals(prev => ({
            ...prev,
            [terminalId]: {
              ...prev[terminalId],
              history: [...prev[terminalId].history, {
                command: '',
                output: `📢 Broadcast from ${source_terminal}: ${message}`,
                type: 'mcp',
                timestamp: new Date().toLocaleTimeString()
              }]
            }
          }))
        }
      })
    })

    // Get initial container status
    newSocket.emit('get_container_status')

    return () => newSocket.close()
  }, [])

  useEffect(() => {
    // Auto-scroll terminals to bottom
    Object.keys(terminalRefs).forEach(terminalId => {
      if (terminalRefs[terminalId].current) {
        terminalRefs[terminalId].current.scrollTop = terminalRefs[terminalId].current.scrollHeight
      }
    })
  }, [terminals])

  useEffect(() => {
    // Handle clicking outside attachment menus
    const handleClickOutside = (event) => {
      const isAttachmentMenu = event.target.closest('.attachment-menu')
      const isPaperclipButton = event.target.closest('.paperclip-button')
      
      if (!isAttachmentMenu && !isPaperclipButton) {
        closeAllAttachmentMenus()
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  const executeCommand = (terminalId) => {

    const rawInput = terminals[terminalId].input
    const parsed = parseInput(rawInput)
    const { agent, command, mcp } = parsed

    if (!command && !mcp || !socket) return

    // Handle MCP communication
    if (mcp) {
      handleMCPCommunication(terminalId, mcp)
      setTerminals(prev => ({
        ...prev,
        [terminalId]: {
          ...prev[terminalId],
          input: ''
        }
      }))
      return
    }

    // Save command to history
    const newCommandHistory = [rawInput, ...terminals[terminalId].commandHistory.filter(cmd => cmd !== rawInput)].slice(0, 50)
    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        commandHistory: newCommandHistory,
        historyIndex: -1
      }
    }))

    // Map frontend terminal ID -> backend terminal string
    const frontendToBackend = {
      'terminal1': 'gemini-1', // Gemini CLI Terminal 1
      'terminal2': 'gemini-2', // Gemini CLI Terminal 2
      'terminal3': 'system'   // System terminal
    }

    // Use the terminal mapping, but allow smart parser to override
    let backendTerminal = frontendToBackend[terminalId]
    
    // If smart parser detected a specific agent, use that instead
    if (agent === 'gemini') {
      // Route to the appropriate Gemini terminal based on which one was used
      backendTerminal = terminalId === 'terminal1' ? 'gemini-1' : 'gemini-2'
    }

    socket.emit('execute_command', {
      terminal: backendTerminal,
      command: command,
      original_terminal_request: terminalId // keep context if needed on server
    })
    
    console.log('Sent command:', {
      terminal: backendTerminal,
      command: command,
      original_terminal: terminalId
    })

    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        input: ''
      }
    }))
  }

  const handleInputChange = (terminalId, value) => {
    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        input: value
      }
    }))
  }

  const handleKeyPress = (e, terminalId) => {
    if (e.key === 'Enter') {
      executeCommand(terminalId)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      navigateHistory(terminalId, 'up')
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      navigateHistory(terminalId, 'down')
    }
  }

  const navigateHistory = (terminalId, direction) => {
    const terminal = terminals[terminalId]
    const { commandHistory, historyIndex } = terminal
    
    if (commandHistory.length === 0) return
    
    let newIndex = historyIndex
    
    if (direction === 'up') {
      newIndex = Math.min(historyIndex + 1, commandHistory.length - 1)
    } else if (direction === 'down') {
      newIndex = Math.max(historyIndex - 1, -1)
    }
    
    const newInput = newIndex >= 0 ? commandHistory[newIndex] : ''
    
    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        input: newInput,
        historyIndex: newIndex
      }
    }))
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      running: { variant: 'default', color: 'bg-green-500', text: 'Running' },
      exited: { variant: 'destructive', color: 'bg-red-500', text: 'Stopped' },
      not_found: { variant: 'secondary', color: 'bg-gray-500', text: 'Not Found' }
    }
    
    const statusInfo = statusMap[status] || { variant: 'secondary', color: 'bg-gray-500', text: 'Unknown' }
    
    return (
      <Badge variant={statusInfo.variant} className="ml-2">
        <div className={`w-2 h-2 rounded-full ${statusInfo.color} mr-1`}></div>
        {statusInfo.text}
      </Badge>
    )
  }

  const getTerminalIcon = (terminalId) => {
    switch (terminalId) {
      case 'terminal1':
      case 'terminal2':
        return <Cpu className="w-4 h-4" />
      case 'terminal3':
        return <Terminal className="w-4 h-4" />
      default:
        // Handle dynamic terminals
        const dynamicTerminal = dynamicTerminals[terminalId]
        if (dynamicTerminal) {
          switch (dynamicTerminal.type) {
            case 'claude':
              return <Cpu className="w-4 h-4 text-orange-400" />
            case 'gemini':
              return <Cpu className="w-4 h-4 text-purple-400" />
            case 'opencode':
              return <Cpu className="w-4 h-4 text-blue-400" />
            case 'system':
              return <Terminal className="w-4 h-4" />
            default:
              return <Cpu className="w-4 h-4" />
          }
        }
        return <Terminal className="w-4 h-4" />
    }
  }

  const getTerminalTitle = (terminalId) => {
    switch (terminalId) {
      case 'terminal1':
        return 'Gemini CLI Terminal 1'
      case 'terminal2':
        return 'Gemini CLI Terminal 2'
      case 'terminal3':
        return 'System Terminal'
      default:
        // Handle dynamic terminals
        const dynamicTerminal = dynamicTerminals[terminalId]
        if (dynamicTerminal) {
          switch (dynamicTerminal.type) {
            case 'claude':
              return 'Claude Code Terminal'
            case 'gemini':
              return 'Gemini Code Terminal'
            case 'opencode':
              return 'Open Code Terminal'
            case 'system':
              return 'System Terminal'
            default:
              return 'AI Terminal'
          }
        }
        return 'Terminal'
    }
  }

  const handleMouseDown = (e, terminalId, action) => {
    e.preventDefault()
    const startX = e.clientX
    const startY = e.clientY
    const startLayout = terminalLayouts[terminalId]
    
    const handleMouseMove = (e) => {
      const deltaX = e.clientX - startX
      const deltaY = e.clientY - startY
      
      if (action === 'drag') {
        setTerminalLayouts(prev => ({
          ...prev,
          [terminalId]: {
            ...prev[terminalId],
            x: startLayout.x + deltaX,
            y: startLayout.y + deltaY
          }
        }))
      } else if (action === 'resize') {
        setTerminalLayouts(prev => ({
          ...prev,
          [terminalId]: {
            ...prev[terminalId],
            width: Math.max(300, startLayout.width + deltaX),
            height: Math.max(200, startLayout.height + deltaY)
          }
        }))
      }
    }
    
    const handleMouseUp = () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
    
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }

  const handleCopy = (terminalId) => {
    const terminal = terminals[terminalId]
    const textToCopy = terminal.history
      .map(entry => `$ ${entry.command}\n${entry.output || ''}${entry.error || ''}`)
      .join('\n')
    
    navigator.clipboard.writeText(textToCopy)
  }

  const handlePaste = async (terminalId) => {
    try {
      const text = await navigator.clipboard.readText()
      setTerminals(prev => ({
        ...prev,
        [terminalId]: {
          ...prev[terminalId],
          input: text
        }
      }))
    } catch (error) {
      console.error('Failed to paste:', error)
    }
  }

  const handleScreenshot = (terminalId) => {
    const terminalElement = terminalRefs[terminalId].current
    if (!terminalElement) return
    
    html2canvas(terminalElement).then(canvas => {
      const link = document.createElement('a')
      link.download = `terminal-${terminalId}-${Date.now()}.png`
      link.href = canvas.toDataURL()
      link.click()
    })
  }

  const handleMCPCommunication = (sourceTerminalId, mcp) => {
    const timestamp = new Date().toLocaleTimeString()
    
    switch (mcp.type) {
      case 'message':
        handleMCPMessage(sourceTerminalId, mcp.target, mcp.message, timestamp)
        break
      case 'route':
        handleMCPRoute(sourceTerminalId, mcp.target, mcp.command, timestamp)
        break
      case 'function':
        handleMCPFunction(sourceTerminalId, mcp.function, mcp.args, timestamp)
        break
      case 'collaboration':
        handleMCPCollaboration(sourceTerminalId, mcp.partner, mcp.task, timestamp)
        break
      case 'broadcast':
        handleMCPBroadcast(sourceTerminalId, mcp.message, timestamp)
        break
      case 'share':
        handleMCPShare(sourceTerminalId, mcp.data, timestamp)
        break
      case 'get_shared':
        handleMCPGetShared(sourceTerminalId, timestamp)
        break
      default:
        console.error('Unknown MCP type:', mcp.type)
    }
  }

  const handleMCPMessage = (sourceTerminalId, target, message, timestamp) => {
    const targetTerminalId = mapTargetToTerminalId(target)
    
    // Add message to source terminal
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `@${target} ${message}`,
          output: `📤 Message sent to ${target}`,
          type: 'mcp',
          timestamp
        }]
      }
    }))

    // Add message to target terminal
    if (targetTerminalId && targetTerminalId !== sourceTerminalId) {
      setTerminals(prev => ({
        ...prev,
        [targetTerminalId]: {
          ...prev[targetTerminalId],
          history: [...prev[targetTerminalId].history, {
            command: '',
            output: `📥 Message from ${sourceTerminalId}: ${message}`,
            type: 'mcp',
            timestamp
          }]
        }
      }))
    }
  }

  const handleMCPRoute = (sourceTerminalId, target, command, timestamp) => {
    const targetTerminalId = mapTargetToTerminalId(target)
    
    // Add routing info to source terminal
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `>>${target} ${command}`,
          output: `🔄 Command routed to ${target}`,
          type: 'mcp',
          timestamp
        }]
      }
    }))

    // Execute command in target terminal
    if (targetTerminalId && targetTerminalId !== sourceTerminalId) {
      const frontendToBackend = {
        'terminal1': 'gemini-1',
        'terminal2': 'gemini-2', 
        'terminal3': 'system'
      }
      
      socket.emit('execute_command', {
        terminal: frontendToBackend[targetTerminalId],
        command: command,
        original_terminal_request: targetTerminalId
      })
    }
  }

  const handleMCPFunction = (sourceTerminalId, func, args, timestamp) => {
    // Add function call to source terminal
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `mcp ${func} ${args}`,
          output: `🔧 MCP Function: ${func}(${args})`,
          type: 'mcp',
          timestamp
        }]
      }
    }))

    // Execute MCP function via backend
    socket.emit('mcp_function', {
      function: func,
      args: args,
      source_terminal: sourceTerminalId
    })
  }

  const handleMCPCollaboration = (sourceTerminalId, partner, task, timestamp) => {
    const partnerTerminalId = mapTargetToTerminalId(partner)
    
    // Add collaboration request to source terminal
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `collab ${partner} ${task}`,
          output: `🤝 Collaboration request sent to ${partner}`,
          type: 'mcp',
          timestamp
        }]
      }
    }))

    // Send collaboration request to partner terminal
    if (partnerTerminalId && partnerTerminalId !== sourceTerminalId) {
      setTerminals(prev => ({
        ...prev,
        [partnerTerminalId]: {
          ...prev[partnerTerminalId],
          history: [...prev[partnerTerminalId].history, {
            command: '',
            output: `🤝 Collaboration request from ${sourceTerminalId}: ${task}`,
            type: 'mcp',
            timestamp
          }]
        }
      }))
    }
  }

  const mapTargetToTerminalId = (target) => {
    const mapping = {
      'terminal1': 'terminal1',
      'terminal2': 'terminal2', 
      'terminal3': 'terminal3',
      'gemini1': 'terminal1',
      'gemini2': 'terminal2',
      'gemini-1': 'terminal1',
      'gemini-2': 'terminal2',
      'system': 'terminal3'
    }
    return mapping[target.toLowerCase()]
  }

  // Handle broadcast to all terminals
  const handleMCPBroadcast = (sourceTerminalId, message, timestamp) => {
    const allTerminals = ['terminal1', 'terminal2', 'terminal3']
    
    allTerminals.forEach(terminalId => {
      if (terminalId !== sourceTerminalId) {
        setTerminals(prev => ({
          ...prev,
          [terminalId]: {
            ...prev[terminalId],
            history: [...prev[terminalId].history, {
              command: '',
              output: `📢 Broadcast from ${sourceTerminalId}: ${message}`,
              type: 'mcp',
              timestamp
            }]
          }
        }))
      }
    })
    
    // Add confirmation to source terminal
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `broadcast ${message}`,
          output: `📢 Message broadcasted to all terminals`,
          type: 'mcp',
          timestamp
        }]
      }
    }))
  }

  // Handle sharing data between terminals
  const handleMCPShare = (sourceTerminalId, data, timestamp) => {
    setSharedClipboard(data)
    
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: `share ${data}`,
          output: `💾 Data shared: ${data}`,
          type: 'mcp',
          timestamp
        }]
      }
    }))
  }

  // Handle getting shared data
  const handleMCPGetShared = (sourceTerminalId, timestamp) => {
    setTerminals(prev => ({
      ...prev,
      [sourceTerminalId]: {
        ...prev[sourceTerminalId],
        history: [...prev[sourceTerminalId].history, {
          command: 'get shared data',
          output: sharedClipboard ? `📖 Shared data: ${sharedClipboard}` : '📖 No shared data available',
          type: 'mcp',
          timestamp
        }]
      }
    }))
  }

  const handleVoiceInput = async (terminalId) => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const mediaRecorder = new MediaRecorder(stream)
      const chunks = []
      
      mediaRecorder.ondataavailable = (e) => chunks.push(e.data)
      mediaRecorder.onstop = async () => {
        const blob = new Blob(chunks, { type: 'audio/wav' })
        const formData = new FormData()
        formData.append('audio', blob)
        
        try {
          const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || import.meta.env.VITE_API_URL
          const response = await fetch(`${BACKEND_URL}/api/whisper/transcribe`, {
            method: 'POST',
            credentials: 'include',
            body: formData
          })
          const data = await response.json()
          
          if (data.text) {
            setTerminals(prev => ({
              ...prev,
              [terminalId]: {
                ...prev[terminalId],
                input: data.text
              }
            }))
          }
        } catch (error) {
          console.error('Transcription failed:', error)
        }
      }
      
      mediaRecorder.start()
      setTimeout(() => mediaRecorder.stop(), 5000) // Record for 5 seconds
    } catch (error) {
      console.error('Voice input failed:', error)
    }
  }

  const toggleAttachmentMenu = (terminalId) => {
    setAttachmentMenus(prev => ({
      ...prev,
      [terminalId]: !prev[terminalId]
    }))
  }

  const closeAllAttachmentMenus = () => {
    setAttachmentMenus({
      terminal1: false,
      terminal2: false,
      terminal3: false
    })
  }

  // Handle quick action clicks
  const handleQuickAction = (terminalId, action) => {
    const command = action(terminalId)
    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        input: command
      }
    }))
  }

  // Handle prompt example clicks
  const handlePromptExample = (terminalId, example) => {
    setTerminals(prev => ({
      ...prev,
      [terminalId]: {
        ...prev[terminalId],
        input: example.command
      }
    }))
  }

  // Clear message history
  const clearMessageHistory = () => {
    setTerminalMessages([])
  }

  const spawnTerminal = (type) => {
    const terminalId = `terminal${nextTerminalId}`
    const newTerminal = {
      history: [],
      input: '',
      commandHistory: [],
      historyIndex: -1,
      type: type // 'claude', 'gemini', 'opencode', 'system'
    }
    
    const newLayout = {
      x: 100 + (nextTerminalId * 50),
      y: 100 + (nextTerminalId * 30),
      width: 400,
      height: 600,
      isDragging: false,
      isResizing: false
    }
    
    setDynamicTerminals(prev => ({
      ...prev,
      [terminalId]: newTerminal
    }))
    
    setTerminalLayouts(prev => ({
      ...prev,
      [terminalId]: newLayout
    }))
    
    setNextTerminalId(prev => prev + 1)
    
    // Send spawn request to backend
    if (socket) {
      socket.emit('spawn_terminal', { terminalId, type })
    }
  }

  const deleteTerminal = (terminalId) => {
    // Only allow deletion of dynamic terminals (not the default 3)
    if (terminalId === 'terminal1' || terminalId === 'terminal2' || terminalId === 'terminal3') {
      return
    }
    
    setDynamicTerminals(prev => {
      const newDynamicTerminals = { ...prev }
      delete newDynamicTerminals[terminalId]
      return newDynamicTerminals
    })
    
    setTerminalLayouts(prev => {
      const newLayouts = { ...prev }
      delete newLayouts[terminalId]
      return newLayouts
    })
    
    // Send delete request to backend
    if (socket) {
      socket.emit('delete_terminal', { terminalId })
    }
  }

  // Show login page if not authenticated
  if (loading) {
    return (
      <div className="min-h-screen bg-black text-white flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <img 
            src="https://tubbyai.s3.us-east-1.amazonaws.com/logo_option_2.png" 
            alt="Tubby AI Logo" 
            className="w-16 h-16 animate-pulse"
          />
          <div className="text-gray-400">Loading...</div>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <AuthContainer />
  }

  // Show subscription page if requested
  if (showSubscription) {
    return (
      <div className="min-h-screen bg-black text-white p-4">
        <div className="max-w-6xl mx-auto">
          <div className="mb-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <img src="https://tubbyai.s3.us-east-1.amazonaws.com/logo_option_2.png" alt="Tubby AI Logo" className="w-12 h-12" />
                <h1 className="text-3xl font-bold">Tubby AI</h1>
              </div>
              <Button
                onClick={() => setShowSubscription(false)}
                variant="ghost"
                className="text-gray-400 hover:text-white"
              >
                Back to Dashboard
              </Button>
            </div>
          </div>
          <SubscriptionPlans />
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black text-white p-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <img src="https://tubbyai.s3.us-east-1.amazonaws.com/logo_option_2.png" alt="Tubby AI Logo" className="w-12 h-12" />
              <h1 className="text-3xl font-bold">
                Tubby AI
              </h1>
            </div>
            <div className="flex items-center gap-2">
              <Button
                onClick={() => setShowSubscription(true)}
                variant="ghost"
                className="text-gray-400 hover:text-white"
              >
                <Crown className="w-5 h-5 mr-2" />
                Plans
              </Button>
              
              {/* Spawn Terminal Buttons */}
              <div className="flex items-center gap-1 ml-4">
                <details className="relative">
                  <summary className="cursor-pointer bg-gray-800 hover:bg-gray-700 px-3 py-2 rounded-md text-sm font-medium text-gray-300 border border-gray-600">
                    + Spawn Terminal
                  </summary>
                  <div className="absolute right-0 mt-2 w-48 bg-gray-800 border border-gray-600 rounded-md shadow-lg z-50">
                    <div className="py-1">
                      <button
                        onClick={() => spawnTerminal('claude')}
                        className="block w-full text-left px-4 py-2 text-sm text-orange-400 hover:bg-gray-700"
                      >
                        Claude Code
                      </button>
                      <button
                        onClick={() => spawnTerminal('gemini')}
                        className="block w-full text-left px-4 py-2 text-sm text-purple-400 hover:bg-gray-700"
                      >
                        Gemini Code
                      </button>
                      <button
                        onClick={() => spawnTerminal('opencode')}
                        className="block w-full text-left px-4 py-2 text-sm text-blue-400 hover:bg-gray-700"
                      >
                        Open Code
                      </button>
                      <button
                        onClick={() => spawnTerminal('system')}
                        className="block w-full text-left px-4 py-2 text-sm text-gray-400 hover:bg-gray-700"
                      >
                        System Terminal
                      </button>
                    </div>
                  </div>
                </details>
              </div>
              
              {/* User Avatar */}
              {currentUser && (
                <div className="flex items-center gap-2 mr-2">
                  {currentUser.picture ? (
                    <img
                      src={currentUser.picture}
                      alt="Profile"
                      className="w-8 h-8 rounded-full border-2 border-gray-600"
                    />
                  ) : (
                    <div className="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center border-2 border-gray-600">
                      <User className="w-4 h-4 text-gray-400" />
                    </div>
                  )}
                </div>
              )}
              
              <Button
                onClick={() => setSettingsOpen(true)}
                variant="ghost"
                className="text-gray-400 hover:text-white"
              >
                <Settings className="w-5 h-5" />
              </Button>
            </div>
          </div>
          <div className="flex justify-center items-center gap-4">
            <div className="flex items-center">
              <div className={`w-3 h-3 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'} mr-2`}></div>
              <span className="text-sm">
                {connected ? 'Connected' : 'Disconnected'}
              </span>
              {!connected && (
                <Button
                  onClick={() => {
                    if (socket) {
                      socket.connect()
                    }
                  }}
                  size="sm"
                  variant="outline"
                  className="ml-2 text-xs"
                >
                  Retry
                </Button>
              )}
            </div>
            
            {/* Cross-Terminal Communication Status */}
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-blue-500 mr-2 animate-pulse"></div>
              <span className="text-sm text-blue-400">Cross-Terminal Active</span>
            </div>
            
            {/* Recent Messages Counter */}
            {terminalMessages.length > 0 && (
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2"></div>
                <span className="text-sm text-yellow-400">
                  {terminalMessages.length} messages
                </span>
                <Button
                  onClick={clearMessageHistory}
                  size="sm"
                  variant="ghost"
                  className="ml-2 text-xs text-yellow-400 hover:text-yellow-300"
                >
                  Clear
                </Button>
              </div>
            )}
            
            {/* Shared Clipboard Status */}
            {sharedClipboard && (
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
                <span className="text-sm text-green-400">
                  Shared data available
                </span>
                <Button
                  onClick={() => setSharedClipboard('')}
                  size="sm"
                  variant="ghost"
                  className="ml-2 text-xs text-green-400 hover:text-green-300"
                >
                  Clear
                </Button>
              </div>
            )}
            {containerStatus.gemini && (
              <div className="flex items-center">
                <Cpu className="w-4 h-4 mr-1" />
                <span className="text-sm">Gemini CLI</span>
                {getStatusBadge(containerStatus.gemini.status)}
              </div>
            )}
            {containerStatus['gemini-1'] && (
              <div className="flex items-center">
                <Cpu className="w-4 h-4 mr-1" />
                <span className="text-sm">Gemini CLI 1</span>
                {getStatusBadge(containerStatus['gemini-1'])}
              </div>
            )}
            {containerStatus['gemini-2'] && (
              <div className="flex items-center">
                <Cpu className="w-4 h-4 mr-1" />
                <span className="text-sm">Gemini CLI 2</span>
                {getStatusBadge(containerStatus['gemini-2'])}
              </div>
            )}
          </div>
        </div>

        {/* Terminal Grid */}
        <div className="relative w-full h-screen">
          {Object.keys(terminals).map((terminalId) => (
            <Card 
              key={terminalId} 
              className="bg-black border-gray-800 absolute"
              style={{
                left: terminalLayouts[terminalId].x,
                top: terminalLayouts[terminalId].y,
                width: terminalLayouts[terminalId].width,
                height: terminalLayouts[terminalId].height,
                zIndex: terminalLayouts[terminalId].isDragging ? 1000 : 1
              }}
            >
              <CardHeader className="pb-3 cursor-move" onMouseDown={(e) => handleMouseDown(e, terminalId, 'drag')}>
                <CardTitle className="flex items-center justify-between text-lg">
                  <div className="flex items-center">
                    {getTerminalIcon(terminalId)}
                    <span className="ml-2">{getTerminalTitle(terminalId)}</span>
                  </div>

                </CardTitle>
              </CardHeader>
              <CardContent>
                {/* Terminal Output */}
                <div 
                  ref={terminalRefs[terminalId]}
                  className="bg-black border border-gray-600 rounded p-3 overflow-y-auto font-mono text-sm mb-3"
                  style={{ height: terminalLayouts[terminalId].height - 200 }}
                >
                  {!connected ? (
                    <div className="text-red-400 text-center py-8">
                      <div className="text-lg mb-2">⚠️ Connection Lost</div>
                      <div className="text-sm text-gray-400">
                        Unable to connect to the backend server.
                      </div>
                      <div className="text-xs text-gray-500 mt-2">
                        Please check if the backend server is running on port 5004
                      </div>
                    </div>
                  ) : terminals[terminalId].history.length === 0 ? (
                    <div className="text-gray-500">
                      {/* Add collapsed Quickstart workflows */}
                      <div className="mb-4">
                        <div className="text-sm font-semibold mb-2">🚀 Quickstart</div>
                        {terminalId === 'terminal1' && (
                          <details className="bg-gray-800 p-2 rounded mb-2">
                            <summary className="cursor-pointer text-xs font-medium">Quickstart 1: Collaborative Code Refactoring</summary>
                            <div className="text-xs ml-4 mt-2 space-y-1">
                              <div>gemini --prompt "Here's my Python function, please refactor it for clarity."</div>
                              <div className="text-gray-500">Then Terminal 2 will: collab terminal1 "Nice refactor! Now please add unit tests for edge cases."</div>
                              <div className="text-gray-500">Then Terminal 2 will: gemini --prompt "Write pytest tests for the refactored function."</div>
                              <div className="text-gray-500">Then System will: pytest -q</div>
                              <div className="text-gray-500">Then System will: collab terminal1 "✅ All tests passed"</div>
                            </div>
                          </details>
                        )}
                        {terminalId === 'terminal2' && (
                          <details className="bg-gray-800 p-2 rounded mb-2">
                            <summary className="cursor-pointer text-xs font-medium">Quickstart 2: Live API Doc + Smoke Test</summary>
                            <div className="text-xs ml-4 mt-2 space-y-1">
                              <div className="text-gray-500">Terminal 1 will: gemini --prompt "Generate OpenAPI spec for our /api/user CRUD endpoints."</div>
                              <div>collab terminal1 "Got the spec—please turn it into Markdown API docs."</div>
                              <div>gemini --prompt "Write a README.md section showing example requests/responses."</div>
                              <div className="text-gray-500">Then System will: curl {import.meta.env.VITE_API_URL || 'http://localhost:5004'}/api/user --show-status</div>
                              <div className="text-gray-500">Then System will: mcp broadcast "200 OK, endpoint live"</div>
                            </div>
                          </details>
                        )}
                        {terminalId === 'terminal3' && (
                          <details className="bg-gray-800 p-2 rounded mb-2">
                            <summary className="cursor-pointer text-xs font-medium">Quickstart 3: Rapid UI Scaffold & Preview</summary>
                            <div className="text-xs ml-4 mt-2 space-y-1">
                              <div className="text-gray-500">Terminal 1 will: gemini --prompt "Scaffold a React &lt;LoginForm&gt; component with Tailwind classes."</div>
                              <div className="text-gray-500">Terminal 2 will: collab terminal1 "Looks good—please make it accessible (ARIA labels, focus states)."</div>
                              <div className="text-gray-500">Terminal 2 will: gemini --prompt "Add keyboard-nav support and semantic HTML."</div>
                              <div>npm run dev</div>
                              <div>mcp broadcast "App running at http://localhost:3003 → check LoginForm"</div>
                            </div>
                          </details>
                        )}
                      </div>
                      
                      <div className="text-xs text-gray-600">
                        <div className="font-semibold mb-1">🔗 Cross-Terminal Commands:</div>
                        <div className="space-y-1">
                          <div><span className="text-blue-400">@terminal2</span> message - Send message</div>
                          <div><span className="text-blue-400">{'>>'}terminal3</span> command - Route command</div>
                          <div><span className="text-blue-400">collab terminal1</span> task - Collaborate</div>
                          <div><span className="text-blue-400">mcp broadcast</span> message - Broadcast to all</div>
                        </div>
                      </div>
                    </div>
                  ) : (
                    terminals[terminalId].history.map((entry, index) => (
                      <div key={index} className="mb-2">
                        <div className="text-green-400">
                          $ {entry.command}
                        </div>
                        <div className={`whitespace-pre-wrap ${
                          entry.type === 'error' ? 'text-red-400' : 
                          entry.type === 'claude' ? 'text-blue-400' :
                          entry.type === 'gemini' ? 'text-purple-400' :
                          entry.type === 'mcp' ? 'text-yellow-400 bg-yellow-900/20 p-2 rounded border-l-2 border-yellow-500' :
                          'text-gray-300'
                        }`}>
                          {entry.output}
                          {entry.error && (
                            <div className="text-red-400 mt-1">
                              {entry.error}
                            </div>
                          )}
                        </div>
                        <div className="text-xs text-gray-500 mt-1">
                          {entry.timestamp}
                        </div>
                      </div>
                    ))
                  )}
                </div>

                {/* Command Input */}
                <div className="flex gap-2 relative">
                  <div className="flex-1 relative">
                    <Input
                      value={terminals[terminalId].input}
                      onChange={(e) => handleInputChange(terminalId, e.target.value)}
                      onKeyPress={(e) => handleKeyPress(e, terminalId)}
                      onKeyDown={(e) => {
                        if (e.ctrlKey || e.metaKey) {
                          if (e.key === 'c') {
                            e.preventDefault()
                            handleCopy(terminalId)
                          } else if (e.key === 'v') {
                            e.preventDefault()
                            handlePaste(terminalId)
                          }
                        } else if (e.key === 'ArrowUp') {
                          e.preventDefault()
                          navigateHistory(terminalId, 'up')
                        } else if (e.key === 'ArrowDown') {
                          e.preventDefault()
                          navigateHistory(terminalId, 'down')
                        }
                      }}
                      placeholder="Enter command..."
                      className="bg-black border-gray-600 text-gray-300 placeholder-gray-500"
                    />
                  </div>
                  <Button
                    onClick={() => toggleAttachmentMenu(terminalId)}
                    size="sm"
                    variant="outline"
                    className="text-gray-400 hover:text-gray-300"
                  >
                    <Paperclip className="w-4 h-4" />
                  </Button>
                  <Button
                    onClick={() => executeCommand(terminalId)}
                    size="sm"
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Play className="w-4 h-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
          
          {/* Render dynamic terminals */}
          {Object.keys(dynamicTerminals).map((terminalId) => (
            <Card 
              key={terminalId} 
              className="bg-black border-gray-800 absolute"
              style={{
                left: terminalLayouts[terminalId].x,
                top: terminalLayouts[terminalId].y,
                width: terminalLayouts[terminalId].width,
                height: terminalLayouts[terminalId].height,
                zIndex: terminalLayouts[terminalId].isDragging ? 1000 : 1
              }}
            >
              <CardHeader className="pb-3 cursor-move" onMouseDown={(e) => handleMouseDown(e, terminalId, 'drag')}>
                <CardTitle className="flex items-center justify-between text-lg">
                  <div className="flex items-center">
                    {getTerminalIcon(terminalId)}
                    <span className="ml-2">{getTerminalTitle(terminalId)}</span>
                  </div>
                  {/* Delete button for dynamic terminals */}
                  <Button
                    onClick={(e) => {
                      e.stopPropagation()
                      deleteTerminal(terminalId)
                    }}
                    size="sm"
                    variant="ghost"
                    className="text-red-400 hover:text-red-300 hover:bg-red-900/20"
                  >
                    <Square className="w-4 h-4" />
                  </Button>
                </CardTitle>
              </CardHeader>
              <CardContent>
                {/* Terminal Output */}
                <div 
                  className="bg-black border border-gray-600 rounded p-3 overflow-y-auto font-mono text-sm mb-3"
                  style={{ height: terminalLayouts[terminalId].height - 200 }}
                >
                  <div className="text-gray-500">
                    <div className="text-sm font-semibold mb-2">🚀 New Terminal</div>
                    <div className="text-xs">
                      This is a new {dynamicTerminals[terminalId].type} terminal.
                      <br />
                      Start collaborating with other terminals!
                    </div>
                  </div>
                </div>

                {/* Command Input */}
                <div className="flex gap-2 relative">
                  <div className="flex-1 relative">
                    <Input
                      value={dynamicTerminals[terminalId].input}
                      onChange={(e) => {
                        setDynamicTerminals(prev => ({
                          ...prev,
                          [terminalId]: {
                            ...prev[terminalId],
                            input: e.target.value
                          }
                        }))
                      }}
                      onKeyPress={(e) => {
                        if (e.key === 'Enter') {
                          executeCommand(terminalId)
                        }
                      }}
                      placeholder="Enter command..."
                      className="bg-black border-gray-600 text-gray-300 placeholder-gray-500"
                    />
                  </div>
                  <Button
                    onClick={() => executeCommand(terminalId)}
                    size="sm"
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Play className="w-4 h-4" />
                  </Button>
                  <Button
                    onClick={() => deleteTerminal(terminalId)}
                    size="sm"
                    variant="outline"
                    className="text-red-400 border-red-400 hover:bg-red-400 hover:text-black"
                  >
                    <Square className="w-4 h-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Instructions */}
        <div className="mt-6 text-center text-gray-400 text-sm">
          <p>Use the terminals above to interact with Gemini CLI or run system commands. Commands starting with "gemini" will be routed to their respective containers.</p>
          <div className="mt-4 text-xs">
            <p><strong>Terminal Features:</strong></p>
            <p>🖱️ <strong>Drag:</strong> Click and drag terminal headers to move</p>
            <p>📏 <strong>Resize:</strong> Drag bottom-right corner to resize</p>
            <p>⬆️ <strong>History:</strong> Use ↑/↓ arrows to navigate command history</p>
            <p>📋 <strong>Copy/Paste:</strong> Use Ctrl+C/Ctrl+V for copy/paste</p>
            <p>📎 <strong>Attachments:</strong> Click 📎 in input field for screenshot and voice input</p>
          </div>
          

        </div>

        {/* Settings Panel */}
        <SettingsPanel 
          isOpen={settingsOpen} 
          onClose={() => setSettingsOpen(false)} 
        />
      </div>
    </div>
  )
}

function App() {
  return (
    <Routes>
      <Route path="/auth/callback" element={<AuthCallback />} />
      <Route path="/*" element={<MainApp />} />
    </Routes>
  )
}

export default App

