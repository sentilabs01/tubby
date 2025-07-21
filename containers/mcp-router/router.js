const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.ROUTER_PORT || 8080;

app.use(express.json());

// Health endpoint
app.get('/health', (req, res) => res.json({ status: 'healthy', service: 'mcp-router' }));

// Forward MCP message to target agent
app.post('/forward', async (req, res) => {
  const { target, command } = req.body;
  if (!target || !command) {
    return res.status(400).json({ error: 'target and command required' });
  }

  // Build target URL assumption: target corresponds to container hostname on same network
  const targetMap = {
    'gemini-1': 'http://gemini-cli-container-1:8001/execute',
    'gemini-2': 'http://gemini-cli-container-2:8002/execute',
    'gemini-3': 'http://gemini-cli-container-3:8003/execute'
  };

  const url = targetMap[target];
  if (!url) {
    return res.status(400).json({ error: `No mapping for target ${target}` });
  }

  try {
    const response = await axios.post(url, { command }, { timeout: 60000 });
    return res.json(response.data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => console.log(`MCP Router listening on ${port}`)); 