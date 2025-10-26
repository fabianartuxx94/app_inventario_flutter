// 🚀 CACHE SIMPLIFICADO (sin dependencias externas)
class CacheManager {
  constructor() {
    this.caches = new Map();
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0
    };
    
    this.createCache('filtros', 300);
    this.createCache('consultas', 600);
    this.createCache('usuario', 1800);
    
    // Limpieza automática cada 5 minutos
    setInterval(() => this.cleanExpired(), 5 * 60 * 1000);
  }

  createCache(nombre, ttl = 300) {
    const cache = {
      data: new Map(),
      ttl,
      get: (key) => {
        const item = cache.data.get(key);
        if (!item) return undefined;
        
        if (Date.now() > item.expiry) {
          cache.data.delete(key);
          return undefined;
        }
        
        return item.value;
      },
      set: (key, value, customTtl = null) => {
        const ttlMs = (customTtl || ttl) * 1000;
        cache.data.set(key, {
          value,
          expiry: Date.now() + ttlMs
        });
        return true;
      },
      del: (key) => {
        return cache.data.delete(key);
      },
      flushAll: () => {
        const size = cache.data.size;
        cache.data.clear();
        return size;
      },
      keys: () => Array.from(cache.data.keys())
    };
    
    this.caches.set(nombre, cache);
    return cache;
  }

  getCache(nombre) {
    return this.caches.get(nombre);
  }

  async get(cacheName, key, fetchFunction, ttl = null) {
    const cache = this.getCache(cacheName);
    if (!cache) throw new Error(`Cache ${cacheName} no existe`);

    const cached = cache.get(key);
    if (cached !== undefined) {
      this.stats.hits++;
      return cached;
    }

    this.stats.misses++;
    const data = await fetchFunction();
    
    if (data !== undefined && data !== null) {
      cache.set(key, data, ttl);
    }
    
    return data;
  }

  set(cacheName, key, data, ttl = null) {
    const cache = this.getCache(cacheName);
    if (!cache) return false;
    this.stats.sets++;
    return cache.set(key, data, ttl);
  }

  del(cacheName, key) {
    const cache = this.getCache(cacheName);
    if (!cache) return 0;
    this.stats.deletes++;
    return cache.del(key) ? 1 : 0;
  }

  flush(cacheName = null) {
    if (cacheName) {
      const cache = this.getCache(cacheName);
      return cache ? cache.flushAll() : 0;
    }
    
    let total = 0;
    this.caches.forEach(cache => {
      total += cache.flushAll();
    });
    return total;
  }

  cleanExpired() {
    let cleaned = 0;
    this.caches.forEach(cache => {
      const keys = cache.keys();
      keys.forEach(key => {
        // Al intentar obtener, se limpian los expirados automáticamente
        cache.get(key);
      });
    });
    return cleaned;
  }

  getStats() {
    const cacheStats = {};
    let totalKeys = 0;
    
    this.caches.forEach((cache, name) => {
      const keys = cache.keys();
      cacheStats[name] = {
        keys: keys.length,
        hits: this.stats.hits,
        misses: this.stats.misses
      };
      totalKeys += keys.length;
    });

    return {
      ...this.stats,
      hitRate: this.stats.hits + this.stats.misses > 0 
        ? (this.stats.hits / (this.stats.hits + this.stats.misses) * 100).toFixed(2)
        : 0,
      totalKeys,
      caches: cacheStats
    };
  }

  findKeys(cacheName, pattern) {
    const cache = this.getCache(cacheName);
    if (!cache) return [];
    
    const keys = cache.keys();
    const regex = new RegExp(pattern);
    return keys.filter(key => regex.test(key));
  }
}

// 📦 INSTANCIA GLOBAL
const cacheManager = new CacheManager();

module.exports = cacheManager;