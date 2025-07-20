const http = require('http');

const options = {
  hostname: 'localhost',
  port: process.env.MCP_PORT || 8001,
  path: '/health',
  method: 'GET'
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => {
  process.exit(1);
});

req.end(); 