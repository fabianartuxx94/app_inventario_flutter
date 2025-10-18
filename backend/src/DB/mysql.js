const mysql = require("mysql");
const config = require("../config");

const dbconfig = {
  host: config.mysql.host,
  user: config.mysql.user,
  password: config.mysql.password,
  database: config.mysql.database,
};

let conexion;

function conmysql() {
  conexion = mysql.createConnection(dbconfig);

  conexion.connect((err) => {
    if (err) {
      console.log("Error de conexión a MySQL:", err);
      setTimeout(conmysql, 1000);
    } else {
      console.log("Conexión a MySQL establecida");
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

function todos(tabla) {
  return new Promise((resolve, reject) => {
    conexion.query(`SELECT * FROM ${tabla}`, (error, results) => {
      return error ? reject(error) : resolve(results);
    });
  });
}

function uno(tabla, id) {
  return new Promise((resolve, reject) => {
    conexion.query(
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
    conexion.query(
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
    conexion.query(
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
    conexion.query(
      `SELECT * FROM ${tabla} WHERE id = ?`,
      [consulta],
      (error, results) => {
        return error ? reject(error) : resolve(results[0]);
      }
    );
  });
}

// 🔍 Nueva función para buscar por campo específico (para login)
function buscar(tabla, campo, valor) {
  return new Promise((resolve, reject) => {
    conexion.query(
      `SELECT * FROM ${tabla} WHERE ${campo} = ? LIMIT 1`,
      [valor],
      (error, results) => {
        return error ? reject(error) : resolve(results[0]);
      }
    );
  });
}

function getConnection() {
  const conn = mysql.createConnection({
    host: config.mysql.host,
    user: config.mysql.user,
    password: config.mysql.password,
    database: config.mysql.database,
    multipleStatements: false,
  });

  // envolver en Promise para conexión asincrónica si lo prefieres
  return {
    conn,
    beginTransaction: () =>
      new Promise((resolve, reject) => conn.beginTransaction((err) => (err ? reject(err) : resolve()))),
    commit: () =>
      new Promise((resolve, reject) => conn.commit((err) => (err ? reject(err) : resolve()))),
    rollback: () =>
      new Promise((resolve) => conn.rollback(() => resolve())),
    query: (sql, params) =>
      new Promise((resolve, reject) => conn.query(sql, params, (err, results) => (err ? reject(err) : resolve(results)))),
    release: () => conn.end(),
  };
}

module.exports.getConnection = getConnection;

// Para consultas personalizadas (como joins)
function consultaDirecta(sql, params = []) {
  return new Promise((resolve, reject) => {
    conexion.query(sql, params, (error, results) => {
      return error ? reject(error) : resolve(results);
    });
  });
}

module.exports = {
  todos,
  uno,
  agregar,
  eliminar,
  query,
  buscar,
  getConnection,
  consultaDirecta,};

