const express = require('express');
const { spawn } = require('child_process');
const app = express();
const port = process.env.MCP_PORT || 8002;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'gemini-cli' });
});

// Execute Gemini CLI commands
app.post('/execute', (req, res) => {
  const { command } = req.body;
  
  if (!command) {
    return res.status(400).json({ error: 'Command is required' });
  }

  let responseSent = false;
  let geminiProcess = null;

  // Set a timeout for the command execution
  const timeout = setTimeout(() => {
    if (!responseSent) {
      responseSent = true;
      if (geminiProcess) {
        geminiProcess.kill('SIGTERM');
      }
      res.status(408).json({
        error: 'Command execution timed out',
        output: '',
        exitCode: -1
      });
    }
  }, 45000); // 45 second timeout

  try {
    // Parse command properly to handle quoted arguments
    let args = [];
    let commandToParse = command;
    
    if (commandToParse.startsWith('gemini ')) {
      commandToParse = commandToParse.substring(7); // Remove 'gemini ' prefix
    }
    
    // Handle --prompt commands specifically
    if (commandToParse.startsWith('--prompt ')) {
      const promptMatch = commandToParse.match(/--prompt\s+"([^"]*)"\s*$/);
      if (promptMatch) {
        args = ['--prompt', promptMatch[1]];
      } else {
        // Fallback to regex parsing
        const regex = /"([^"]*)"|'([^']*)'|(\S+)/g;
        let match;
        while ((match = regex.exec(commandToParse)) !== null) {
          args.push(match[1] || match[2] || match[3]);
        }
      }
    } else {
      // Simple argument parsing to handle quoted strings
      const regex = /"([^"]*)"|'([^']*)'|(\S+)/g;
      let match;
      while ((match = regex.exec(commandToParse)) !== null) {
        args.push(match[1] || match[2] || match[3]);
      }
    }

    console.log('Executing gemini with args:', args);

    geminiProcess = spawn('gemini', args, {
      stdio: ['pipe', 'pipe', 'pipe']
    });

  let output = '';
  let error = '';

  geminiProcess.stdout.on('data', (data) => {
    output += data.toString();
  });

  geminiProcess.stderr.on('data', (data) => {
    error += data.toString();
  });

  geminiProcess.on('close', (code) => {
    clearTimeout(timeout);
    if (!responseSent) {
      responseSent = true;
      console.log(`Gemini process closed with code: ${code}`);
      console.log(`Output: ${output}`);
      console.log(`Error: ${error}`);
      res.json({
        output,
        error,
        exitCode: code
      });
    }
  });

  geminiProcess.on('error', (err) => {
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
  console.log(`Gemini CLI MCP server running on port ${port}`);
}); 