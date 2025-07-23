export function parseInput(rawInput = "") {
  const trimmed = rawInput.trim()
  if (!trimmed) {
    return {
      agent: "system",
      command: "",
      original: rawInput,
      mcp: null
    }
  }

  // MCP Communication Patterns
  const mcpPatterns = [
    // Send message to another terminal (multiple formats)
    {
      pattern: /^@(terminal[123]|gemini[12]|system)\s+(.+)$/i,
      type: "message",
      parse: (match) => ({
        target: match[1],
        message: match[2],
        type: "message"
      })
    },
    // Alternative message format: "send to terminal2: message"
    {
      pattern: /^send\s+to\s+(terminal[123]|gemini[12]|system)[:\s]+(.+)$/i,
      type: "message",
      parse: (match) => ({
        target: match[1],
        message: match[2],
        type: "message"
      })
    },
    // Route command to another terminal
    {
      pattern: /^>>(terminal[123]|gemini[12]|system)\s+(.+)$/i,
      type: "route",
      parse: (match) => ({
        target: match[1],
        command: match[2],
        type: "route"
      })
    },
    // Alternative route format: "run in terminal2: command"
    {
      pattern: /^run\s+in\s+(terminal[123]|gemini[12]|system)[:\s]+(.+)$/i,
      type: "route",
      parse: (match) => ({
        target: match[1],
        command: match[2],
        type: "route"
      })
    },
    // MCP function call
    {
      pattern: /^mcp\s+(\w+)\s+(.+)$/i,
      type: "function",
      parse: (match) => ({
        function: match[1],
        args: match[2],
        type: "function"
      })
    },
    // Cross-terminal collaboration
    {
      pattern: /^collab\s+(terminal[123]|gemini[12]|system)\s+(.+)$/i,
      type: "collaboration",
      parse: (match) => ({
        partner: match[1],
        task: match[2],
        type: "collaboration"
      })
    },
    // Alternative collaboration format: "work with terminal2 on task"
    {
      pattern: /^work\s+with\s+(terminal[123]|gemini[12]|system)\s+on\s+(.+)$/i,
      type: "collaboration",
      parse: (match) => ({
        partner: match[1],
        task: match[2],
        type: "collaboration"
      })
    },
    // Broadcast to all terminals
    {
      pattern: /^broadcast\s+(.+)$/i,
      type: "broadcast",
      parse: (match) => ({
        message: match[1],
        type: "broadcast"
      })
    },
    // Share data between terminals
    {
      pattern: /^share\s+(.+)$/i,
      type: "share",
      parse: (match) => ({
        data: match[1],
        type: "share"
      })
    },
    // Get shared data
    {
      pattern: /^get\s+shared\s+data$/i,
      type: "get_shared",
      parse: () => ({
        type: "get_shared"
      })
    }
  ]

  // Check for MCP patterns first
  for (const { pattern, type, parse } of mcpPatterns) {
    const match = trimmed.match(pattern)
    if (match) {
      return {
        agent: "mcp",
        command: trimmed,
        original: rawInput,
        mcp: parse(match)
      }
    }
  }

  // Very basic heuristic parsing – first keyword indicates agent
  const agentKeywords = [
    { key: "gemini", agent: "gemini" },
    { key: "system", agent: "system" }
  ]

  const lower = trimmed.toLowerCase()
  let detectedAgent = "system"
  let commandWithoutAgent = trimmed

  for (const { key, agent } of agentKeywords) {
    if (lower.startsWith(key)) {
      detectedAgent = agent
      commandWithoutAgent = trimmed.slice(key.length).trim()
      break
    }
  }

  // Optional verbs like "run", "ask", etc.
  const verbPattern = /^(run|ask|exec(ute)?|generate)\s+/i
  commandWithoutAgent = commandWithoutAgent.replace(verbPattern, "").trim()

  // Normalize common system commands
  if (detectedAgent === "system") {
    const normalized = commandWithoutAgent.toLowerCase()
    if (normalized === "ls") {
      commandWithoutAgent = "dir" // Use Windows dir command
    } else if (normalized === "dir") {
      commandWithoutAgent = "dir" // Keep as is
    }
  }

  return {
    agent: detectedAgent,
    command: commandWithoutAgent,
    original: rawInput,
    mcp: null
  }
} 