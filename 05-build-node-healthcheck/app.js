const http = require('http');

const hostname = '0.0.0.0';
const port = process.env.PORT || 3000;
const version =  process.env.VERSION || '1.0.0';

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(`Hello World\nVersion: ${version}\n`);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/ and version ${version}`);
});

process.on('SIGINT', () => {
  console.log('Received SIGINT. Shutting down gracefully...');
  server.close(() => {
    console.log('Server closed. Exiting process.');
    process.exit(0);
  });
});