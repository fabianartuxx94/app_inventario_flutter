const app = require('./app');

const checkPort = (port) => {
  return new Promise((resolve) => {
    const net = require('net');
    const tester = net.createServer();
    
    tester.once('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`❌ Puerto ${port} ocupado por otra instancia`);
        resolve(false);
      }
    });
    
    tester.once('listening', () => {
      tester.close(() => {
        resolve(true);
      });
    });
    
    tester.listen(port);
  });
};

const startServer = async () => {
  const desiredPort = app.get('port') || 5000;
  
  // Verificar si hay otra instancia
  const portAvailable = await checkPort(desiredPort);
  
  if (!portAvailable) {
    console.log('🛑 CERRANDO - Ya hay una instancia ejecutándose');
    console.log('💡 Ejecuta: taskkill /f /im node.exe');
    process.exit(1);
  }
  
  app.listen(desiredPort, () => {
    console.log('='.repeat(50));
    console.log(`🚀 SERVIDOR INVENTARIO INICIADO`);
    console.log('='.repeat(50));
    console.log(`📍 Puerto: ${desiredPort}`);
    console.log(`🏥 Health: http://localhost:${desiredPort}/health`);
    console.log(`📊 Métricas: http://localhost:${desiredPort}/metrics`);
    console.log('='.repeat(50));
  });
};

startServer();