// 📝 LOGGING SIMPLIFICADO (sin winston)
class AppLogger {
  constructor(module = 'app') {
    this.module = module;
    this.levels = {
      error: 0,
      warn: 1,
      info: 2,
      debug: 3
    };
    this.currentLevel = process.env.LOG_LEVEL || 'info';
  }

  #shouldLog(level) {
    return this.levels[level] <= this.levels[this.currentLevel];
  }

  #formatMessage(level, message, meta = {}) {
    const timestamp = new Date().toISOString();
    const metaStr = Object.keys(meta).length > 0 
      ? ` ${JSON.stringify(meta)}` 
      : '';
    
    return `${timestamp} [${level.toUpperCase()}] ${this.module}: ${message}${metaStr}`;
  }

  #log(level, message, meta = {}) {
    if (!this.#shouldLog(level)) return;

    const logMessage = this.#formatMessage(level, message, meta);
    
    switch(level) {
      case 'error':
        console.error(logMessage);
        break;
      case 'warn':
        console.warn(logMessage);
        break;
      case 'info':
        console.info(logMessage);
        break;
      case 'debug':
        console.debug(logMessage);
        break;
      default:
        console.log(logMessage);
    }
  }

  info(message, meta = {}) {
    this.#log('info', message, meta);
  }

  error(message, meta = {}) {
    this.#log('error', message, meta);
  }

  warn(message, meta = {}) {
    this.#log('warn', message, meta);
  }

  debug(message, meta = {}) {
    this.#log('debug', message, meta);
  }

  database(query, duration, params = {}) {
    this.debug('Consulta DB ejecutada', {
      type: 'database',
      query: query.substring(0, 200),
      duration: `${duration}ms`,
      ...params
    });
  }

  cache(action, key, hit = null) {
    this.debug(`Cache ${action}`, {
      type: 'cache',
      key,
      hit
    });
  }

  request(method, url, statusCode, duration, user = null) {
    this.info(`${method} ${url}`, {
      type: 'request',
      method,
      url,
      statusCode,
      duration: `${duration}ms`,
      userId: user?.id
    });
  }

  business(operation, entity, id, user = null) {
    this.info(`Operación de negocio: ${operation}`, {
      type: 'business',
      operation,
      entity,
      entityId: id,
      userId: user?.id
    });
  }
}

// 📊 MÉTRICAS SIMPLIFICADAS
let logMetrics = {
  totalLogs: 0,
  byLevel: {},
  byModule: {}
};

function getLogMetrics() {
  return {
    ...logMetrics,
    timestamp: new Date().toISOString()
  };
}

function resetMetrics() {
  logMetrics = {
    totalLogs: 0,
    byLevel: {},
    byModule: {}
  };
}

module.exports = {
  AppLogger,
  getLogMetrics,
  resetMetrics,
  logger: new AppLogger()
};