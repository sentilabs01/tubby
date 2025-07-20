const express = require('express');
const { spawn } = require('child_process');
const app = express();
const port = process.env.MCP_PORT || 8001;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'claude-code' });
});

// Execute Claude Code commands
app.post('/execute', (req, res) => {
  const { command } = req.body;
  
  if (!command) {
    return res.status(400).json({ error: 'Command is required' });
  }

  let responseSent = false;
  let claudeProcess = null;

  // Set a timeout for the command execution
  const timeout = setTimeout(() => {
    if (!responseSent) {
      responseSent = true;
      if (claudeProcess) {
        claudeProcess.kill('SIGTERM');
      }
      res.status(408).json({
        error: 'Command execution timed out',
        output: '',
        exitCode: -1
      });
    }
  }, 120000); // 2 minute timeout for Claude Code

  try {
    // Parse command properly to handle quoted arguments
    let commandToParse = command;
    
    if (commandToParse.startsWith('claude ')) {
      commandToParse = commandToParse.substring(7); // Remove 'claude ' prefix
    }
    
    // Parse command properly
    let args = [];
    
    // Add --print flag for non-interactive output
    if (!commandToParse.includes('--help') && !commandToParse.includes('-h')) {
      args.push('--print');
    }
    
    // Extract the quoted content
    const quoteMatch = commandToParse.match(/"([^"]*)"/);
    if (quoteMatch) {
      args.push(quoteMatch[1]);
    } else {
      // Fallback to space splitting
      args = args.concat(commandToParse.split(/\s+/).filter(arg => arg.length > 0));
    }
    
    console.log('Executing claude with args:', args);

    claudeProcess = spawn('claude', args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      cwd: '/app'
    });

  let output = '';
  let error = '';

  claudeProcess.stdout.on('data', (data) => {
    output += data.toString();
  });

  claudeProcess.stderr.on('data', (data) => {
    error += data.toString();
  });

  claudeProcess.on('close', (code) => {
    clearTimeout(timeout);
    if (!responseSent) {
      responseSent = true;
      console.log(`Claude process closed with code: ${code}`);
      console.log(`Output: ${output}`);
      console.log(`Error: ${error}`);
      res.json({
        output,
        error,
        exitCode: code
      });
    }
  });

  claudeProcess.on('error', (err) => {
    clearTimeout(timeout);
    if (!responseSent) {
      responseSent = true;
      res.status(500).json({
        error: err.message,
        output: '',
        exitCode: -1
      });
    }
  });
  } catch (err) {
    clearTimeout(timeout);
    if (!responseSent) {
      responseSent = true;
      res.status(500).json({
        error: `Failed to execute command: ${err.message}`,
        output: '',
        exitCode: -1
      });
    }
  }
});

app.listen(port, () => {
  console.log(`Claude Code MCP server running on port ${port}`);
}); 