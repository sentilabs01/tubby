import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Terminal, Play, Square, Cpu, Bot } from 'lucide-react'
import io from 'socket.io-client'
import './App.css'

function App() {
  const [socket, setSocket] = useState(null)
  const [connected, setConnected] = useState(false)
  const [containerStatus, setContainerStatus] = useState({})
  const [terminals, setTerminals] = useState({
    terminal1: { history: [], input: '' },
    terminal2: { history: [], input: '' },
    terminal3: { history: [], input: '' }
  })
  
  const terminalRefs = {
    terminal1: useRef(null),
    terminal2: useRef(null),
    terminal3: useRef(null)
  }

  useEffect(() => {
    // Initialize socket connection
    const newSocket = io('http://localhost:5000')
    setSocket(newSocket)

    newSocket.on('connect', () => {
      setConnected(true)
      console.log('Connected to server')
    })

    newSocket.on('disconnect', () => {
      setConnected(false)
      console.log('Disconnected from server')
    })

    newSocket.on('status', (data) => {
      console.log('Status:', data.message)
    })

    newSocket.on('command_output', (data) => {
      setTerminals(prev => ({
        ...prev,
        [data.terminal_id]: {
          ...prev[data.terminal_id],
          history: [...prev[data.terminal_id].history, {
            command: data.command,
            output: data.output,
            type: data.type,
            timestamp: new Date().toLocaleTimeString()
          }]
        }
      }))
    })

    newSocket.on('container_status', (data) => {
      setContainerStatus(data)
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
    const command = terminals[terminalId].input.trim()
    if (!command || !socket) return

    socket.emit('execute_command', {
      terminal_id: terminalId,
      command: command
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
    }
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
        return <Bot className="w-4 h-4" />
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
        return 'Claude Code Terminal'
      case 'terminal2':
        return 'Gemini CLI Terminal'
      case 'terminal3':
        return 'System Terminal'
      default:
        return 'Terminal'
    }
  }

  return (
    <div className="min-h-screen bg-black text-white p-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-center mb-4">
            AI Agent Communication Platform
          </h1>
          <div className="flex justify-center items-center gap-4">
            <div className="flex items-center">
              <div className={`w-3 h-3 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'} mr-2`}></div>
              <span className="text-sm">
                {connected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            {containerStatus.claude && (
              <div className="flex items-center">
                <Bot className="w-4 h-4 mr-1" />
                <span className="text-sm">Claude Code</span>
                {getStatusBadge(containerStatus.claude.status)}
              </div>
            )}
            {containerStatus.gemini && (
              <div className="flex items-center">
                <Cpu className="w-4 h-4 mr-1" />
                <span className="text-sm">Gemini CLI</span>
                {getStatusBadge(containerStatus.gemini.status)}
              </div>
            )}
          </div>
        </div>

        {/* Terminal Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {Object.keys(terminals).map((terminalId) => (
            <Card key={terminalId} className="bg-gray-900 border-gray-700">
              <CardHeader className="pb-3">
                <CardTitle className="flex items-center text-lg">
                  {getTerminalIcon(terminalId)}
                  <span className="ml-2">{getTerminalTitle(terminalId)}</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                {/* Terminal Output */}
                <div 
                  ref={terminalRefs[terminalId]}
                  className="bg-black border border-gray-600 rounded p-3 h-96 overflow-y-auto font-mono text-sm mb-3"
                >
                  {terminals[terminalId].history.length === 0 ? (
                    <div className="text-gray-500">
                      Terminal ready. Type commands below.
                      {terminalId === 'terminal1' && (
                        <div className="mt-2 text-xs">
                          Try: <span className="text-blue-400">claude --help</span>
                        </div>
                      )}
                      {terminalId === 'terminal2' && (
                        <div className="mt-2 text-xs">
                          Try: <span className="text-blue-400">gemini --help</span>
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
                    placeholder="Enter command..."
                    className="bg-gray-800 border-gray-600 text-white"
                    disabled={!connected}
                  />
                  <Button
                    onClick={() => executeCommand(terminalId)}
                    disabled={!connected || !terminals[terminalId].input.trim()}
                    size="sm"
                  >
                    <Play className="w-4 h-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Instructions */}
        <div className="mt-6 text-center text-gray-400 text-sm">
          <p>Use the terminals above to interact with Claude Code, Gemini CLI, or run system commands.</p>
          <p className="mt-1">Commands starting with "claude" or "gemini" will be routed to their respective containers.</p>
        </div>
      </div>
    </div>
  )
}

export default App

