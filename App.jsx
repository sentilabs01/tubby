import { useState, useEffect, useRef } from 'react'
import { Button } from './components/ui/button.jsx'
import { Input } from './components/ui/input.jsx'
import { Card, CardContent, CardHeader, CardTitle } from './components/ui/card.jsx'
import { Badge } from './components/ui/badge.jsx'
import { Terminal, Play, Square, Cpu, Settings, User, Crown } from 'lucide-react'
import io from 'socket.io-client'
import { parseInput } from './utils/smartParser.js'
import SettingsPanel from './components/SettingsPanel.jsx'
import html2canvas from 'html2canvas'
import { AuthProvider, useAuth } from './src/components/AuthManager.jsx'
import AuthContainer from './src/components/AuthContainer.jsx'
import UserProfile from './src/components/UserProfile.jsx'
import SubscriptionPlans from './src/components/SubscriptionPlans.jsx'

function App() {
  const { currentUser, isAuthenticated, loading } = useAuth()
  const [socket, setSocket] = useState(null)
  const [connected, setConnected] = useState(false)
  const [containerStatus, setContainerStatus] = useState({})
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [showSubscription, setShowSubscription] = useState(false)
  const [terminalLayouts, setTerminalLayouts] = useState({
    terminal1: { x: 0, y: 0, width: 400, height: 400, isDragging: false, isResizing: false },
    terminal2: { x: 420, y: 0, width: 400, height: 400, isDragging: false, isResizing: false },
    terminal3: { x: 840, y: 0, width: 400, height: 400, isDragging: false, isResizing: false }
  })
  const [terminals, setTerminals] = useState({
    terminal1: { history: [], input: '', commandHistory: [], historyIndex: -1 }, // Gemini CLI Terminal 1
    terminal2: { history: [], input: '', commandHistory: [], historyIndex: -1 }, // Gemini CLI Terminal 2
    terminal3: { history: [], input: '', commandHistory: [], historyIndex: -1 }  // System Terminal
  })
  
  const [sharedClipboard, setSharedClipboard] = useState('')
  const [terminalMessages, setTerminalMessages] = useState([])
  
  const terminalRefs = {
    terminal1: useRef(null),
    terminal2: useRef(null),
    terminal3: useRef(null)
  }

  useEffect(() => {
    // Initialize socket connection
    const newSocket = io('http://localhost:5004', {
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
        return <Cpu className="w-4 h-4" />
      case 'terminal2':
        return <Cpu className="w-4 h-4" />
      case 'terminal3':
        return <Terminal className="w-4 h-4" />
      default:
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
      'system': 'terminal3'
    }
    return mapping[target.toLowerCase()]
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
          const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5004'
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
              
              {/* User Avatar and Info */}
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
                  <div className="hidden md:block">
                    <div className="text-sm font-medium text-white">{currentUser.name}</div>
                    <div className="text-xs text-gray-400">{currentUser.email}</div>
                  </div>
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
                  <div className="flex items-center gap-2">
                    <Button
                      onClick={() => handleCopy(terminalId)}
                      size="sm"
                      variant="ghost"
                      className="text-gray-400 hover:text-white"
                    >
                      📋
                    </Button>
                    <Button
                      onClick={() => handlePaste(terminalId)}
                      size="sm"
                      variant="ghost"
                      className="text-gray-400 hover:text-white"
                    >
                      📄
                    </Button>
                    <Button
                      onClick={() => handleScreenshot(terminalId)}
                      size="sm"
                      variant="ghost"
                      className="text-gray-400 hover:text-white"
                    >
                      📸
                    </Button>
                    <Button
                      onClick={() => handleVoiceInput(terminalId)}
                      size="sm"
                      variant="ghost"
                      className="text-gray-400 hover:text-white"
                    >
                      🎤
                    </Button>
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
                      Terminal ready. Type commands below.
                      {terminalId === 'terminal1' && (
                        <div className="mt-2 text-xs">
                          Try: <span className="text-blue-400">gemini --help</span>
                        </div>
                      )}
                      {terminalId === 'terminal2' && (
                        <div className="mt-2 text-xs">
                          Try: <span className="text-blue-400">gemini --prompt "Hello"</span>
                        </div>
                      )}
                      {terminalId === 'terminal3' && (
                        <div className="mt-2 text-xs">
                          Try: <span className="text-blue-400">ls -la</span>
                        </div>
                      )}
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
                <div className="flex gap-2">
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
                      }
                    }}
                    placeholder={connected ? "Enter command..." : "Connecting to server..."}
                    className={`bg-gray-800 border-gray-600 text-white ${!connected ? 'opacity-50 cursor-not-allowed' : ''}`}
                    disabled={!connected}
                  />
                  <Button
                    onClick={() => executeCommand(terminalId)}
                    disabled={!connected || !terminals[terminalId].input.trim()}
                    size="sm"
                    className={!connected ? 'opacity-50' : ''}
                  >
                    <Play className="w-4 h-4" />
                  </Button>
                </div>
                
                {/* Resize Handle */}
                <div
                  className="absolute bottom-0 right-0 w-4 h-4 cursor-se-resize bg-gray-600 rounded-tl"
                  onMouseDown={(e) => handleMouseDown(e, terminalId, 'resize')}
                />
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
            <p>📋 <strong>Copy/Paste:</strong> Use Ctrl+C/Ctrl+V or click buttons</p>
            <p>📸 <strong>Screenshot:</strong> Click 📸 to save terminal as image</p>
            <p>🎤 <strong>Voice:</strong> Click 🎤 to record voice commands</p>
          </div>
          
          <div className="mt-4 text-xs">
            <p><strong>🔗 MCP Inter-Terminal Communication:</strong></p>
            <p>📤 <strong>@terminal2 Hello there</strong> - Send message to another terminal</p>
            <p>🔄 <strong>{'>>'}terminal3 ls -la</strong> - Route command to another terminal</p>
            <p>🔧 <strong>mcp broadcast "Important update"</strong> - Broadcast to all terminals</p>
            <p>🤝 <strong>collab terminal1 "Help me debug this code"</strong> - Request collaboration</p>
            <p>💾 <strong>mcp set_shared_data {"{'key': 'value'}"}</strong> - Share data between terminals</p>
            <p>📖 <strong>mcp get_shared_data</strong> - Retrieve shared data</p>
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

export default App

