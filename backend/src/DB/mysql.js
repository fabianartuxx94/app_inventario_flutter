const mysql = require("mysql");
const config = require("../config");

const dbconfig = {
  host: config.mysql.host,
  user: config.mysql.user,
  password: config.mysql.password,
  database: config.mysql.database,
  charset: 'utf8mb4',
  timezone: 'local'
};

// 🚀 POOL DE CONEXIONES OPTIMIZADO
const pool = mysql.createPool({
  ...dbconfig,
  connectionLimit: 20,
  acquireTimeout: 60000,
  timeout: 60000,
  queueLimit: 0,
  reconnect: true
});

// 📊 MÉTRICAS DEL POOL
let poolMetrics = {
  totalQueries: 0,
  failedQueries: 0,
  queryTimes: []
};

// 🔧 CONEXIÓN PRINCIPAL (para compatibilidad)
let conexion;

function conmysql() {
  conexion = mysql.createConnection(dbconfig);

  conexion.connect((err) => {
    if (err) {
      console.log("Error de conexión a MySQL:", err);
      setTimeout(conmysql, 1000);
    } else {
      console.log("✅ Conexión a MySQL establecida");
    }
  });

  conexion.on("error", (err) => {
    console.log("Error en la conexión a MySQL:", err);
    if (err.code === "PROTOCOL_CONNECTION_LOST") {
      setTimeout(conmysql, 1000);
    }
  });
}

conmysql();

// 🚀 FUNCIONES OPTIMIZADAS CON POOL
function todos(tabla) {
  return new Promise((resolve, reject) => {
    pool.query(`SELECT * FROM ${tabla}`, (error, results) => {
      return error ? reject(error) : resolve(results);
    });
  });
}

function uno(tabla, id) {
  return new Promise((resolve, reject) => {
    pool.query(
      `SELECT * FROM ${tabla} WHERE id = ?`,
      [id],
      (error, results) => {
        return error ? reject(error) : resolve(results[0]);
      }
    );
  });
}

function agregar(tabla, data) {
  return new Promise((resolve, reject) => {
    pool.query(
      `INSERT INTO ${tabla} SET ? ON DUPLICATE KEY UPDATE ?`,
      [data, data],
      (error, results) => {
        return error ? reject(error) : resolve(results);
      }
    );
  });
}

function eliminar(tabla, data) {
  return new Promise((resolve, reject) => {
    pool.query(
      `DELETE FROM ${tabla} WHERE id = ?`,
      [data.id],
      (error, results) => {
        return error ? reject(error) : resolve(results);
      }
    );
  });
}

function query(tabla, consulta) {
  return new Promise((resolve, reject) => {
    pool.query(
      `SELECT * FROM ${tabla} WHERE id = ?`,
      [consulta],
      (error, results) => {
        return error ? reject(error) : resolve(results[0]);
      }
    );
  });
}

// 🔍 Función para buscar por campo específico
function buscar(tabla, campo, valor) {
  return new Promise((resolve, reject) => {
    pool.query(
      `SELECT * FROM ${tabla} WHERE ${campo} = ? LIMIT 1`,
      [valor],
      (error, results) => {
        return error ? reject(error) : resolve(results[0]);
      }
    );
  });
}

// 🚀 CONSULTAS DIRECTAS CON MÉTRICAS
function consultaDirecta(sql, params = []) {
  const startTime = Date.now();
  poolMetrics.totalQueries++;
  
  return new Promise((resolve, reject) => {
    pool.query(sql, params, (error, results) => {
      const queryTime = Date.now() - startTime;
      poolMetrics.queryTimes.push(queryTime);
      
      // Mantener solo las últimas 1000 mediciones
      if (poolMetrics.queryTimes.length > 1000) {
        poolMetrics.queryTimes = poolMetrics.queryTimes.slice(-1000);
      }
      
      if (error) {
        poolMetrics.failedQueries++;
        console.error('❌ Error en consulta SQL:', {
          sql: sql.substring(0, 200),
          params: params,
          error: error.message
        });
        return reject(error);
      }
      
      if (queryTime > 1000) { // Log queries lentas
        console.warn(`🐌 Query lenta (${queryTime}ms):`, sql.substring(0, 300));
      }
      
      resolve(results);
    });
  });
}

// 📊 OBTENER MÉTRICAS DEL POOL
function getPoolMetrics() {
  const avgTime = poolMetrics.queryTimes.length > 0 
    ? poolMetrics.queryTimes.reduce((a, b) => a + b, 0) / poolMetrics.queryTimes.length 
    : 0;
    
  return {
    ...poolMetrics,
    avgQueryTime: Math.round(avgTime),
    successRate: poolMetrics.totalQueries > 0 
      ? ((poolMetrics.totalQueries - poolMetrics.failedQueries) / poolMetrics.totalQueries * 100).toFixed(2)
      : 100,
    poolStatus: {
      allConnections: pool._allConnections ? pool._allConnections.length : 0,
      freeConnections: pool._freeConnections ? pool._freeConnections.length : 0,
      queue: pool._connectionQueue ? pool._connectionQueue.length : 0
    }
  };
}

// 🔄 TRANSACCIONES MEJORADAS
function getConnection() {
  return new Promise((resolve, reject) => {
    pool.getConnection((err, connection) => {
      if (err) {
        return reject(err);
      }
      
      const connWrapper = {
        conn: connection,
        beginTransaction: () => 
          new Promise((resolve, reject) => 
            connection.beginTransaction(err => err ? reject(err) : resolve())
          ),
        commit: () => 
          new Promise((resolve, reject) => 
            connection.commit(err => err ? reject(err) : resolve())
          ),
        rollback: () => 
          new Promise((resolve) => 
            connection.rollback(() => resolve())
          ),
        query: (sql, params) => 
          new Promise((resolve, reject) => 
            connection.query(sql, params, (err, results) => 
              err ? reject(err) : resolve(results)
            )
          ),
        release: () => connection.release()
      };
      
      resolve(connWrapper);
    });
  });
}

// 🛑 CERRAR POOL AL APAGAR
process.on('SIGINT', () => {
  console.log('🛑 Cerrando pool de MySQL...');
  pool.end((err) => {
    if (err) {
      console.error('Error cerrando pool:', err);
      process.exit(1);
    }
    console.log('✅ Pool de MySQL cerrado');
    process.exit(0);
  });
});

module.exports = {
  todos,
  uno,
  agregar,
  eliminar,
  query,
  buscar,
  getConnection,
  consultaDirecta,
  getPoolMetrics,
  pool // Exportar pool para monitoreo directo
};